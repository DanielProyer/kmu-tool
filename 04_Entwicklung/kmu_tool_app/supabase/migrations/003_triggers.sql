-- ============================================================================
-- KMU Tool - Migration 003: Trigger Functions
-- - Automatische Aktualisierung von updated_at
-- - Automatische Saldo-Berechnung bei Buchungen
-- ============================================================================

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

-- Generische Trigger-Funktion fuer updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column()
  IS 'Setzt updated_at automatisch auf den aktuellen Zeitstempel bei jedem UPDATE';

-- Trigger auf alle Tabellen anwenden
CREATE TRIGGER trg_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_kunden_updated_at
  BEFORE UPDATE ON kunden
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_kunden_kontakte_updated_at
  BEFORE UPDATE ON kunden_kontakte
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_offerten_updated_at
  BEFORE UPDATE ON offerten
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_offert_positionen_updated_at
  BEFORE UPDATE ON offert_positionen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_auftraege_updated_at
  BEFORE UPDATE ON auftraege
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_zeiterfassungen_updated_at
  BEFORE UPDATE ON zeiterfassungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_rapporte_updated_at
  BEFORE UPDATE ON rapporte
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_rechnungen_updated_at
  BEFORE UPDATE ON rechnungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_rechnungs_positionen_updated_at
  BEFORE UPDATE ON rechnungs_positionen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_konten_updated_at
  BEFORE UPDATE ON konten
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_buchungen_updated_at
  BEFORE UPDATE ON buchungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_buchungs_vorlagen_updated_at
  BEFORE UPDATE ON buchungs_vorlagen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- KONTEN-SALDO TRIGGER
-- Aktualisiert den Saldo der betroffenen Konten bei jeder Buchung
--
-- Buchhaltungslogik (Schweizer Kontenrahmen):
--   Aktiv-Konten (Klasse 1):   Soll = + / Haben = -
--   Passiv-Konten (Klasse 2):  Soll = - / Haben = +
--   Ertrag-Konten (Klasse 3):  Soll = - / Haben = +
--   Aufwand-Konten (Klasse 4-8): Soll = + / Haben = -
-- ============================================================================

-- Hilfsfunktion: Berechnet die Auswirkung auf den Saldo basierend auf Kontotyp
-- und Buchungsseite (Soll oder Haben)
CREATE OR REPLACE FUNCTION get_saldo_delta(
  p_kontotyp TEXT,
  p_seite TEXT,     -- 'soll' oder 'haben'
  p_betrag NUMERIC
)
RETURNS NUMERIC AS $$
BEGIN
  -- Aktiv und Aufwand: Soll erhoeht, Haben vermindert
  -- Passiv und Ertrag: Haben erhoeht, Soll vermindert
  CASE
    WHEN p_kontotyp IN ('aktiv', 'aufwand') AND p_seite = 'soll' THEN
      RETURN p_betrag;
    WHEN p_kontotyp IN ('aktiv', 'aufwand') AND p_seite = 'haben' THEN
      RETURN -p_betrag;
    WHEN p_kontotyp IN ('passiv', 'ertrag') AND p_seite = 'haben' THEN
      RETURN p_betrag;
    WHEN p_kontotyp IN ('passiv', 'ertrag') AND p_seite = 'soll' THEN
      RETURN -p_betrag;
    ELSE
      RETURN 0;
  END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION get_saldo_delta(TEXT, TEXT, NUMERIC)
  IS 'Berechnet Saldo-Aenderung basierend auf Kontotyp und Buchungsseite (doppelte Buchhaltung)';

-- Hauptfunktion: Aktualisiert Saldo bei INSERT/UPDATE/DELETE auf buchungen
CREATE OR REPLACE FUNCTION update_konto_saldo()
RETURNS TRIGGER AS $$
DECLARE
  v_soll_typ TEXT;
  v_haben_typ TEXT;
BEGIN
  -- ================================================================
  -- Bei DELETE: Alte Buchung rueckgaengig machen
  -- ================================================================
  IF TG_OP = 'DELETE' THEN
    -- Typ des Soll-Kontos ermitteln
    SELECT typ INTO v_soll_typ
    FROM konten
    WHERE user_id = OLD.user_id AND kontonummer = OLD.soll_konto;

    -- Typ des Haben-Kontos ermitteln
    SELECT typ INTO v_haben_typ
    FROM konten
    WHERE user_id = OLD.user_id AND kontonummer = OLD.haben_konto;

    -- Soll-Konto: Buchung rueckgaengig machen
    IF v_soll_typ IS NOT NULL THEN
      UPDATE konten
      SET saldo = saldo - get_saldo_delta(v_soll_typ, 'soll', OLD.betrag)
      WHERE user_id = OLD.user_id AND kontonummer = OLD.soll_konto;
    END IF;

    -- Haben-Konto: Buchung rueckgaengig machen
    IF v_haben_typ IS NOT NULL THEN
      UPDATE konten
      SET saldo = saldo - get_saldo_delta(v_haben_typ, 'haben', OLD.betrag)
      WHERE user_id = OLD.user_id AND kontonummer = OLD.haben_konto;
    END IF;

    RETURN OLD;
  END IF;

  -- ================================================================
  -- Bei UPDATE: Alte Werte zuruecknehmen, dann neue anwenden
  -- ================================================================
  IF TG_OP = 'UPDATE' THEN
    -- Nur wenn sich buchungsrelevante Felder geaendert haben
    IF OLD.soll_konto != NEW.soll_konto
       OR OLD.haben_konto != NEW.haben_konto
       OR OLD.betrag != NEW.betrag
    THEN
      -- Alte Buchung rueckgaengig machen (Soll-Konto)
      SELECT typ INTO v_soll_typ
      FROM konten
      WHERE user_id = OLD.user_id AND kontonummer = OLD.soll_konto;

      IF v_soll_typ IS NOT NULL THEN
        UPDATE konten
        SET saldo = saldo - get_saldo_delta(v_soll_typ, 'soll', OLD.betrag)
        WHERE user_id = OLD.user_id AND kontonummer = OLD.soll_konto;
      END IF;

      -- Alte Buchung rueckgaengig machen (Haben-Konto)
      SELECT typ INTO v_haben_typ
      FROM konten
      WHERE user_id = OLD.user_id AND kontonummer = OLD.haben_konto;

      IF v_haben_typ IS NOT NULL THEN
        UPDATE konten
        SET saldo = saldo - get_saldo_delta(v_haben_typ, 'haben', OLD.betrag)
        WHERE user_id = OLD.user_id AND kontonummer = OLD.haben_konto;
      END IF;

      -- Neue Buchung anwenden (Soll-Konto)
      SELECT typ INTO v_soll_typ
      FROM konten
      WHERE user_id = NEW.user_id AND kontonummer = NEW.soll_konto;

      IF v_soll_typ IS NOT NULL THEN
        UPDATE konten
        SET saldo = saldo + get_saldo_delta(v_soll_typ, 'soll', NEW.betrag)
        WHERE user_id = NEW.user_id AND kontonummer = NEW.soll_konto;
      END IF;

      -- Neue Buchung anwenden (Haben-Konto)
      SELECT typ INTO v_haben_typ
      FROM konten
      WHERE user_id = NEW.user_id AND kontonummer = NEW.haben_konto;

      IF v_haben_typ IS NOT NULL THEN
        UPDATE konten
        SET saldo = saldo + get_saldo_delta(v_haben_typ, 'haben', NEW.betrag)
        WHERE user_id = NEW.user_id AND kontonummer = NEW.haben_konto;
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  -- ================================================================
  -- Bei INSERT: Neue Buchung anwenden
  -- ================================================================
  IF TG_OP = 'INSERT' THEN
    -- Typ des Soll-Kontos ermitteln
    SELECT typ INTO v_soll_typ
    FROM konten
    WHERE user_id = NEW.user_id AND kontonummer = NEW.soll_konto;

    -- Typ des Haben-Kontos ermitteln
    SELECT typ INTO v_haben_typ
    FROM konten
    WHERE user_id = NEW.user_id AND kontonummer = NEW.haben_konto;

    -- Soll-Konto aktualisieren
    IF v_soll_typ IS NOT NULL THEN
      UPDATE konten
      SET saldo = saldo + get_saldo_delta(v_soll_typ, 'soll', NEW.betrag)
      WHERE user_id = NEW.user_id AND kontonummer = NEW.soll_konto;
    END IF;

    -- Haben-Konto aktualisieren
    IF v_haben_typ IS NOT NULL THEN
      UPDATE konten
      SET saldo = saldo + get_saldo_delta(v_haben_typ, 'haben', NEW.betrag)
      WHERE user_id = NEW.user_id AND kontonummer = NEW.haben_konto;
    END IF;

    RETURN NEW;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_konto_saldo()
  IS 'Aktualisiert Kontensaldi automatisch bei Buchungsaenderungen (doppelte Buchhaltung)';

-- Trigger auf buchungen
CREATE TRIGGER trg_buchungen_saldo_update
  AFTER INSERT OR UPDATE OR DELETE ON buchungen
  FOR EACH ROW EXECUTE FUNCTION update_konto_saldo();

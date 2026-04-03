-- ============================================================================
-- KMU Tool - Migration 022b: Rollensystem (Betrieb-basierte RLS)
-- ============================================================================
-- Erweitert user_profiles um Rolle + Betrieb-Zuordnung.
-- Erstellt Hilfsfunktionen fuer betriebsweite RLS-Policies.
-- Erstellt betrieb_einladungen Tabelle.
-- Schreibt ALLE RLS-Policies um: auth.uid() -> get_betrieb_owner_id()
-- AUSNAHMEN: user_profiles, admin_*, auftrag_zugriffe, auftrag_notizen,
--            auftrag_dateien, subscription_plans (bleiben unveraendert)
-- ============================================================================

-- ============================================================================
-- TEIL 1: Schema-Erweiterungen
-- ============================================================================

-- 1.1 user_profiles erweitern
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS rolle TEXT NOT NULL DEFAULT 'geschaeftsfuehrer'
  CHECK (rolle IN ('geschaeftsfuehrer', 'vorarbeiter', 'mitarbeiter', 'kunde'));

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS betrieb_owner_id UUID REFERENCES auth.users(id);

COMMENT ON COLUMN user_profiles.rolle IS 'Rolle im Betrieb: geschaeftsfuehrer oder mitarbeiter';
COMMENT ON COLUMN user_profiles.betrieb_owner_id IS 'UUID des Betrieb-Owners (NULL = ist selbst der Owner)';

-- ============================================================================
-- TEIL 2: Hilfsfunktionen
-- ============================================================================

-- 2.1 get_betrieb_owner_id(): Gibt die Owner-UUID des aktuellen Users zurueck.
--     Wenn betrieb_owner_id gesetzt ist -> das ist der Owner.
--     Sonst -> der User selbst ist der Owner.
CREATE OR REPLACE FUNCTION get_betrieb_owner_id()
RETURNS UUID AS $$
BEGIN
  RETURN COALESCE(
    (SELECT betrieb_owner_id FROM user_profiles WHERE id = auth.uid()),
    auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2.2 is_same_betrieb(check_user_id): Prueft ob ein bestimmter User
--     zum selben Betrieb gehoert wie der aktuelle User.
CREATE OR REPLACE FUNCTION is_same_betrieb(check_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  my_owner UUID;
  their_owner UUID;
BEGIN
  my_owner := get_betrieb_owner_id();
  their_owner := COALESCE(
    (SELECT betrieb_owner_id FROM user_profiles WHERE id = check_user_id),
    check_user_id
  );
  RETURN my_owner = their_owner;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2.3 get_user_rolle(): Gibt die Rolle des aktuellen Users zurueck.
CREATE OR REPLACE FUNCTION get_user_rolle()
RETURNS TEXT AS $$
BEGIN
  RETURN COALESCE(
    (SELECT rolle FROM user_profiles WHERE id = auth.uid()),
    'geschaeftsfuehrer'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================================
-- TEIL 3: betrieb_einladungen Tabelle
-- ============================================================================

CREATE TABLE IF NOT EXISTS betrieb_einladungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  rolle TEXT NOT NULL DEFAULT 'mitarbeiter'
    CHECK (rolle IN ('geschaeftsfuehrer', 'mitarbeiter')),
  code TEXT NOT NULL UNIQUE,
  verwendet BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_betrieb_einladungen_owner ON betrieb_einladungen(owner_user_id);
CREATE INDEX IF NOT EXISTS idx_betrieb_einladungen_code ON betrieb_einladungen(code);

ALTER TABLE betrieb_einladungen ENABLE ROW LEVEL SECURITY;

-- Owner sieht und verwaltet seine Einladungen
CREATE POLICY "betrieb_einladungen_select" ON betrieb_einladungen
  FOR SELECT USING (owner_user_id = get_betrieb_owner_id());
CREATE POLICY "betrieb_einladungen_insert" ON betrieb_einladungen
  FOR INSERT WITH CHECK (owner_user_id = get_betrieb_owner_id());
CREATE POLICY "betrieb_einladungen_update" ON betrieb_einladungen
  FOR UPDATE USING (owner_user_id = get_betrieb_owner_id());
CREATE POLICY "betrieb_einladungen_delete" ON betrieb_einladungen
  FOR DELETE USING (owner_user_id = get_betrieb_owner_id());

-- ============================================================================
-- TEIL 4: RLS-Policies umschreiben -> get_betrieb_owner_id()
-- ============================================================================
-- Fuer jede Tabelle: Alle bestehenden Policies droppen, neue erstellen.
-- Pattern: user_id = get_betrieb_owner_id()
-- Child-Tabellen: EXISTS-Subquery auf Parent mit get_betrieb_owner_id()
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- KUNDEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "kunden_select_own" ON kunden;
DROP POLICY IF EXISTS "kunden_insert_own" ON kunden;
DROP POLICY IF EXISTS "kunden_update_own" ON kunden;
DROP POLICY IF EXISTS "kunden_delete_own" ON kunden;

CREATE POLICY "kunden_select" ON kunden
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "kunden_insert" ON kunden
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "kunden_update" ON kunden
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "kunden_delete" ON kunden
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- KUNDEN_KONTAKTE (Child von kunden)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "kunden_kontakte_select_own" ON kunden_kontakte;
DROP POLICY IF EXISTS "kunden_kontakte_insert_own" ON kunden_kontakte;
DROP POLICY IF EXISTS "kunden_kontakte_update_own" ON kunden_kontakte;
DROP POLICY IF EXISTS "kunden_kontakte_delete_own" ON kunden_kontakte;

CREATE POLICY "kunden_kontakte_select" ON kunden_kontakte
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "kunden_kontakte_insert" ON kunden_kontakte
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "kunden_kontakte_update" ON kunden_kontakte
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "kunden_kontakte_delete" ON kunden_kontakte
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- OFFERTEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "offerten_select_own" ON offerten;
DROP POLICY IF EXISTS "offerten_insert_own" ON offerten;
DROP POLICY IF EXISTS "offerten_update_own" ON offerten;
DROP POLICY IF EXISTS "offerten_delete_own" ON offerten;

CREATE POLICY "offerten_select" ON offerten
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "offerten_insert" ON offerten
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "offerten_update" ON offerten
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "offerten_delete" ON offerten
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- OFFERT_POSITIONEN (Child von offerten)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "offert_positionen_select_own" ON offert_positionen;
DROP POLICY IF EXISTS "offert_positionen_insert_own" ON offert_positionen;
DROP POLICY IF EXISTS "offert_positionen_update_own" ON offert_positionen;
DROP POLICY IF EXISTS "offert_positionen_delete_own" ON offert_positionen;

CREATE POLICY "offert_positionen_select" ON offert_positionen
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "offert_positionen_insert" ON offert_positionen
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "offert_positionen_update" ON offert_positionen
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "offert_positionen_delete" ON offert_positionen
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- AUFTRAEGE
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "auftraege_select_own" ON auftraege;
DROP POLICY IF EXISTS "auftraege_insert_own" ON auftraege;
DROP POLICY IF EXISTS "auftraege_update_own" ON auftraege;
DROP POLICY IF EXISTS "auftraege_delete_own" ON auftraege;

CREATE POLICY "auftraege_select" ON auftraege
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "auftraege_insert" ON auftraege
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "auftraege_update" ON auftraege
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "auftraege_delete" ON auftraege
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- ZEITERFASSUNGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "zeiterfassungen_select_own" ON zeiterfassungen;
DROP POLICY IF EXISTS "zeiterfassungen_insert_own" ON zeiterfassungen;
DROP POLICY IF EXISTS "zeiterfassungen_update_own" ON zeiterfassungen;
DROP POLICY IF EXISTS "zeiterfassungen_delete_own" ON zeiterfassungen;

CREATE POLICY "zeiterfassungen_select" ON zeiterfassungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "zeiterfassungen_insert" ON zeiterfassungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "zeiterfassungen_update" ON zeiterfassungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "zeiterfassungen_delete" ON zeiterfassungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- RAPPORTE
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "rapporte_select_own" ON rapporte;
DROP POLICY IF EXISTS "rapporte_insert_own" ON rapporte;
DROP POLICY IF EXISTS "rapporte_update_own" ON rapporte;
DROP POLICY IF EXISTS "rapporte_delete_own" ON rapporte;

CREATE POLICY "rapporte_select" ON rapporte
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "rapporte_insert" ON rapporte
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "rapporte_update" ON rapporte
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "rapporte_delete" ON rapporte
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- RECHNUNGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "rechnungen_select_own" ON rechnungen;
DROP POLICY IF EXISTS "rechnungen_insert_own" ON rechnungen;
DROP POLICY IF EXISTS "rechnungen_update_own" ON rechnungen;
DROP POLICY IF EXISTS "rechnungen_delete_own" ON rechnungen;

CREATE POLICY "rechnungen_select" ON rechnungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "rechnungen_insert" ON rechnungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "rechnungen_update" ON rechnungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "rechnungen_delete" ON rechnungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- RECHNUNGS_POSITIONEN (Child von rechnungen)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "rechnungs_positionen_select_own" ON rechnungs_positionen;
DROP POLICY IF EXISTS "rechnungs_positionen_insert_own" ON rechnungs_positionen;
DROP POLICY IF EXISTS "rechnungs_positionen_update_own" ON rechnungs_positionen;
DROP POLICY IF EXISTS "rechnungs_positionen_delete_own" ON rechnungs_positionen;

CREATE POLICY "rechnungs_positionen_select" ON rechnungs_positionen
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "rechnungs_positionen_insert" ON rechnungs_positionen
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "rechnungs_positionen_update" ON rechnungs_positionen
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "rechnungs_positionen_delete" ON rechnungs_positionen
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- KONTEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "konten_select_own" ON konten;
DROP POLICY IF EXISTS "konten_insert_own" ON konten;
DROP POLICY IF EXISTS "konten_update_own" ON konten;
DROP POLICY IF EXISTS "konten_delete_own" ON konten;

CREATE POLICY "konten_select" ON konten
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "konten_insert" ON konten
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "konten_update" ON konten
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "konten_delete" ON konten
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- BUCHUNGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "buchungen_select_own" ON buchungen;
DROP POLICY IF EXISTS "buchungen_insert_own" ON buchungen;
DROP POLICY IF EXISTS "buchungen_update_own" ON buchungen;
DROP POLICY IF EXISTS "buchungen_delete_own" ON buchungen;

CREATE POLICY "buchungen_select" ON buchungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungen_insert" ON buchungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungen_update" ON buchungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungen_delete" ON buchungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- BUCHUNGS_VORLAGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "buchungs_vorlagen_select_own" ON buchungs_vorlagen;
DROP POLICY IF EXISTS "buchungs_vorlagen_insert_own" ON buchungs_vorlagen;
DROP POLICY IF EXISTS "buchungs_vorlagen_update_own" ON buchungs_vorlagen;
DROP POLICY IF EXISTS "buchungs_vorlagen_delete_own" ON buchungs_vorlagen;

CREATE POLICY "buchungs_vorlagen_select" ON buchungs_vorlagen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_vorlagen_insert" ON buchungs_vorlagen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_vorlagen_update" ON buchungs_vorlagen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_vorlagen_delete" ON buchungs_vorlagen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- ARTIKEL
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "artikel_select" ON artikel;
DROP POLICY IF EXISTS "artikel_insert" ON artikel;
DROP POLICY IF EXISTS "artikel_update" ON artikel;
DROP POLICY IF EXISTS "artikel_delete" ON artikel;

CREATE POLICY "artikel_select" ON artikel
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "artikel_insert" ON artikel
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "artikel_update" ON artikel
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "artikel_delete" ON artikel
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- LIEFERANTEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "lieferanten_select" ON lieferanten;
DROP POLICY IF EXISTS "lieferanten_insert" ON lieferanten;
DROP POLICY IF EXISTS "lieferanten_update" ON lieferanten;
DROP POLICY IF EXISTS "lieferanten_delete" ON lieferanten;

CREATE POLICY "lieferanten_select" ON lieferanten
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lieferanten_insert" ON lieferanten
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "lieferanten_update" ON lieferanten
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lieferanten_delete" ON lieferanten
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- ARTIKEL_LIEFERANTEN (Child: user_id-basiert, aber logisch Child von artikel)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "artikel_lieferanten_select" ON artikel_lieferanten;
DROP POLICY IF EXISTS "artikel_lieferanten_insert" ON artikel_lieferanten;
DROP POLICY IF EXISTS "artikel_lieferanten_update" ON artikel_lieferanten;
DROP POLICY IF EXISTS "artikel_lieferanten_delete" ON artikel_lieferanten;

CREATE POLICY "artikel_lieferanten_select" ON artikel_lieferanten
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_lieferanten.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "artikel_lieferanten_insert" ON artikel_lieferanten
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_lieferanten.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "artikel_lieferanten_update" ON artikel_lieferanten
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_lieferanten.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "artikel_lieferanten_delete" ON artikel_lieferanten
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_lieferanten.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- ARTIKEL_FOTOS (Child von artikel)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "artikel_fotos_select" ON artikel_fotos;
DROP POLICY IF EXISTS "artikel_fotos_insert" ON artikel_fotos;
DROP POLICY IF EXISTS "artikel_fotos_delete" ON artikel_fotos;

CREATE POLICY "artikel_fotos_select" ON artikel_fotos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_fotos.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "artikel_fotos_insert" ON artikel_fotos
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_fotos.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "artikel_fotos_delete" ON artikel_fotos
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM artikel
      WHERE artikel.id = artikel_fotos.artikel_id
        AND artikel.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- LAGERORTE
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "lagerorte_select" ON lagerorte;
DROP POLICY IF EXISTS "lagerorte_insert" ON lagerorte;
DROP POLICY IF EXISTS "lagerorte_update" ON lagerorte;
DROP POLICY IF EXISTS "lagerorte_delete" ON lagerorte;

CREATE POLICY "lagerorte_select" ON lagerorte
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerorte_insert" ON lagerorte
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerorte_update" ON lagerorte
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerorte_delete" ON lagerorte
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- LAGERBESTAENDE
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "lagerbestaende_select" ON lagerbestaende;
DROP POLICY IF EXISTS "lagerbestaende_insert" ON lagerbestaende;
DROP POLICY IF EXISTS "lagerbestaende_update" ON lagerbestaende;

CREATE POLICY "lagerbestaende_select" ON lagerbestaende
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerbestaende_insert" ON lagerbestaende
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerbestaende_update" ON lagerbestaende
  FOR UPDATE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- LAGERBEWEGUNGEN (nur SELECT + INSERT, kein UPDATE/DELETE)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "lagerbewegungen_select" ON lagerbewegungen;
DROP POLICY IF EXISTS "lagerbewegungen_insert" ON lagerbewegungen;

CREATE POLICY "lagerbewegungen_select" ON lagerbewegungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lagerbewegungen_insert" ON lagerbewegungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- MWST_ABRECHNUNGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "mwst_abr_select" ON mwst_abrechnungen;
DROP POLICY IF EXISTS "mwst_abr_insert" ON mwst_abrechnungen;
DROP POLICY IF EXISTS "mwst_abr_update" ON mwst_abrechnungen;
DROP POLICY IF EXISTS "mwst_abr_delete" ON mwst_abrechnungen;

CREATE POLICY "mwst_abrechnungen_select" ON mwst_abrechnungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mwst_abrechnungen_insert" ON mwst_abrechnungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "mwst_abrechnungen_update" ON mwst_abrechnungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mwst_abrechnungen_delete" ON mwst_abrechnungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- BESTELLVORSCHLAEGE
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "bestellvorschlaege_select" ON bestellvorschlaege;
DROP POLICY IF EXISTS "bestellvorschlaege_insert" ON bestellvorschlaege;
DROP POLICY IF EXISTS "bestellvorschlaege_update" ON bestellvorschlaege;
DROP POLICY IF EXISTS "bestellvorschlaege_delete" ON bestellvorschlaege;

CREATE POLICY "bestellvorschlaege_select" ON bestellvorschlaege
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellvorschlaege_insert" ON bestellvorschlaege
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellvorschlaege_update" ON bestellvorschlaege
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellvorschlaege_delete" ON bestellvorschlaege
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- BESTELLUNGEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "bestellungen_select" ON bestellungen;
DROP POLICY IF EXISTS "bestellungen_insert" ON bestellungen;
DROP POLICY IF EXISTS "bestellungen_update" ON bestellungen;
DROP POLICY IF EXISTS "bestellungen_delete" ON bestellungen;

CREATE POLICY "bestellungen_select" ON bestellungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellungen_insert" ON bestellungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellungen_update" ON bestellungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellungen_delete" ON bestellungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- BESTELLPOSITIONEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "bestellpositionen_select" ON bestellpositionen;
DROP POLICY IF EXISTS "bestellpositionen_insert" ON bestellpositionen;
DROP POLICY IF EXISTS "bestellpositionen_update" ON bestellpositionen;
DROP POLICY IF EXISTS "bestellpositionen_delete" ON bestellpositionen;

CREATE POLICY "bestellpositionen_select" ON bestellpositionen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellpositionen_insert" ON bestellpositionen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellpositionen_update" ON bestellpositionen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bestellpositionen_delete" ON bestellpositionen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- INVENTUREN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "inventuren_select" ON inventuren;
DROP POLICY IF EXISTS "inventuren_insert" ON inventuren;
DROP POLICY IF EXISTS "inventuren_update" ON inventuren;
DROP POLICY IF EXISTS "inventuren_delete" ON inventuren;

CREATE POLICY "inventuren_select" ON inventuren
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "inventuren_insert" ON inventuren
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "inventuren_update" ON inventuren
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "inventuren_delete" ON inventuren
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- INVENTUR_POSITIONEN
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "inventur_positionen_select" ON inventur_positionen;
DROP POLICY IF EXISTS "inventur_positionen_insert" ON inventur_positionen;
DROP POLICY IF EXISTS "inventur_positionen_update" ON inventur_positionen;
DROP POLICY IF EXISTS "inventur_positionen_delete" ON inventur_positionen;

CREATE POLICY "inventur_positionen_select" ON inventur_positionen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "inventur_positionen_insert" ON inventur_positionen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "inventur_positionen_update" ON inventur_positionen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "inventur_positionen_delete" ON inventur_positionen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBSITE_CONFIGS
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "website_configs_select" ON website_configs;
DROP POLICY IF EXISTS "website_configs_insert" ON website_configs;
DROP POLICY IF EXISTS "website_configs_update" ON website_configs;
DROP POLICY IF EXISTS "website_configs_delete" ON website_configs;

CREATE POLICY "website_configs_select" ON website_configs
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "website_configs_insert" ON website_configs
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "website_configs_update" ON website_configs
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "website_configs_delete" ON website_configs
  FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBSITE_SECTIONS (Child von website_configs)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "website_sections_select" ON website_sections;
DROP POLICY IF EXISTS "website_sections_insert" ON website_sections;
DROP POLICY IF EXISTS "website_sections_update" ON website_sections;
DROP POLICY IF EXISTS "website_sections_delete" ON website_sections;

CREATE POLICY "website_sections_select" ON website_sections
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_sections.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_sections_insert" ON website_sections
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_sections.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_sections_update" ON website_sections
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_sections.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_sections_delete" ON website_sections
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_sections.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBSITE_GALLERY_IMAGES (Child von website_configs)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "website_gallery_select" ON website_gallery_images;
DROP POLICY IF EXISTS "website_gallery_insert" ON website_gallery_images;
DROP POLICY IF EXISTS "website_gallery_update" ON website_gallery_images;
DROP POLICY IF EXISTS "website_gallery_delete" ON website_gallery_images;

CREATE POLICY "website_gallery_select" ON website_gallery_images
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_gallery_images.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_gallery_insert" ON website_gallery_images
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_gallery_images.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_gallery_update" ON website_gallery_images
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_gallery_images.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_gallery_delete" ON website_gallery_images
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_gallery_images.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBSITE_ANFRAGEN (Child von website_configs)
-- SELECT/UPDATE/DELETE via parent, INSERT offen (Edge Function)
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "website_anfragen_select" ON website_anfragen;
DROP POLICY IF EXISTS "website_anfragen_update" ON website_anfragen;
DROP POLICY IF EXISTS "website_anfragen_delete" ON website_anfragen;

CREATE POLICY "website_anfragen_select" ON website_anfragen
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_anfragen.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_anfragen_update" ON website_anfragen
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_anfragen.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
CREATE POLICY "website_anfragen_delete" ON website_anfragen
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM website_configs
      WHERE website_configs.id = website_anfragen.config_id
        AND website_configs.user_id = get_betrieb_owner_id()
    )
  );
-- NOTE: Kein INSERT-Policy fuer website_anfragen - Edge Function nutzt service_role_key

-- ─────────────────────────────────────────────────────────────────────────────
-- USER_SUBSCRIPTIONS (eigene Zeile ODER Admin)
-- Alte Policies droppen, neue mit get_betrieb_owner_id() + is_admin()
-- ─────────────────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "user_subscriptions_select_own" ON user_subscriptions;
DROP POLICY IF EXISTS "user_subscriptions_insert_own" ON user_subscriptions;
DROP POLICY IF EXISTS "user_subscriptions_update_own" ON user_subscriptions;
DROP POLICY IF EXISTS "admin_user_subscriptions_select" ON user_subscriptions;
DROP POLICY IF EXISTS "admin_user_subscriptions_update" ON user_subscriptions;
DROP POLICY IF EXISTS "admin_user_subscriptions_insert" ON user_subscriptions;

CREATE POLICY "user_subscriptions_select" ON user_subscriptions
  FOR SELECT USING (user_id = get_betrieb_owner_id() OR is_admin());
CREATE POLICY "user_subscriptions_insert" ON user_subscriptions
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id() OR is_admin());
CREATE POLICY "user_subscriptions_update" ON user_subscriptions
  FOR UPDATE USING (user_id = get_betrieb_owner_id() OR is_admin());

-- ============================================================================
-- ENDE Migration 022b
-- ============================================================================
-- NICHT geaendert (Ausnahmen):
-- - user_profiles: Bleibt id = auth.uid()
-- - admin_users, admin_kundenprofile, admin_rechnungen, admin_datenmigrationen: Bleibt is_admin()
-- - auftrag_zugriffe: Bleibt bestehendes Sharing-System (owner_user_id + user_id)
-- - auftrag_notizen, auftrag_dateien: Bleibt zugriff-basierte Policies
-- - subscription_plans: Bleibt public read (true)
-- - mwst_codes: Bleibt public read (true)
-- - mwst_einstellungen: Bleibt auth.uid() = user_id (pro-User Einstellungen)
-- ============================================================================

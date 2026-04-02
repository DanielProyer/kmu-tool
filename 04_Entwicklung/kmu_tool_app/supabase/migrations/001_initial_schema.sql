-- ============================================================================
-- KMU Tool - Migration 001: Initial Schema
-- Datenbank-Schema fuer Schweizer Handwerksbetriebe (GmbH)
-- Doppelte Buchhaltung nach OR Art. 957
-- ============================================================================

-- ============================================================================
-- STAMMDATEN
-- ============================================================================

-- Benutzerprofil (1:1 zu auth.users)
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  firma_name TEXT NOT NULL,
  rechtsform TEXT NOT NULL DEFAULT 'GmbH',
  strasse TEXT,
  plz TEXT,
  ort TEXT,
  telefon TEXT,
  uid_nummer TEXT,           -- CHE-xxx.xxx.xxx (UID / MWST-Nummer)
  iban TEXT,
  bank_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE user_profiles IS 'Firmenprofil des Benutzers (GmbH)';
COMMENT ON COLUMN user_profiles.uid_nummer IS 'Unternehmens-Identifikationsnummer CHE-xxx.xxx.xxx';
COMMENT ON COLUMN user_profiles.rechtsform IS 'Immer GmbH - einzige unterstuetzte Rechtsform';

-- ============================================================================
-- KUNDENSTAMM
-- ============================================================================

-- Kunden
CREATE TABLE kunden (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  firma TEXT,
  vorname TEXT,
  nachname TEXT NOT NULL,
  strasse TEXT,
  plz TEXT,
  ort TEXT,
  telefon TEXT,
  email TEXT,
  notizen TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE kunden IS 'Kundenstamm - Privat- und Firmenkunden';

-- Zusaetzliche Ansprechpersonen pro Kunde
CREATE TABLE kunden_kontakte (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kunde_id UUID NOT NULL REFERENCES kunden(id) ON DELETE CASCADE,
  vorname TEXT NOT NULL,
  nachname TEXT NOT NULL,
  funktion TEXT,             -- z.B. 'Geschaeftsfuehrer', 'Bauleiter'
  telefon TEXT,
  email TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE kunden_kontakte IS 'Zusaetzliche Ansprechpersonen eines Kunden';

-- ============================================================================
-- AUFTRAGSWESEN
-- ============================================================================

-- Offerten
CREATE TABLE offerten (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kunde_id UUID NOT NULL REFERENCES kunden(id),
  offert_nr TEXT NOT NULL,
  datum DATE NOT NULL DEFAULT CURRENT_DATE,
  gueltig_bis DATE,
  status TEXT NOT NULL DEFAULT 'entwurf'
    CHECK (status IN ('entwurf', 'gesendet', 'angenommen', 'abgelehnt', 'abgelaufen')),
  total_netto NUMERIC(10,2) NOT NULL DEFAULT 0,
  mwst_satz NUMERIC(4,2) NOT NULL DEFAULT 8.10,
  mwst_betrag NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_brutto NUMERIC(10,2) NOT NULL DEFAULT 0,
  bemerkung TEXT,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE offerten IS 'Offerten / Kostenvoranschlaege';
COMMENT ON COLUMN offerten.mwst_satz IS 'Aktueller MWST-Normalsatz Schweiz (8.1% ab 2024)';

-- Offert-Positionen
CREATE TABLE offert_positionen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  offerte_id UUID NOT NULL REFERENCES offerten(id) ON DELETE CASCADE,
  position_nr INTEGER NOT NULL,
  bezeichnung TEXT NOT NULL,
  menge NUMERIC(10,3) NOT NULL DEFAULT 1,
  einheit TEXT NOT NULL DEFAULT 'Stk',
  einheitspreis NUMERIC(10,2) NOT NULL,
  betrag NUMERIC(10,2) GENERATED ALWAYS AS (menge * einheitspreis) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE offert_positionen IS 'Einzelpositionen einer Offerte';
COMMENT ON COLUMN offert_positionen.einheit IS 'Einheit: Stk, Std, m, m2, m3, kg, Pauschale';

-- Auftraege
CREATE TABLE auftraege (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kunde_id UUID NOT NULL REFERENCES kunden(id),
  offerte_id UUID REFERENCES offerten(id),
  auftrags_nr TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'offen'
    CHECK (status IN ('offen', 'in_arbeit', 'abgeschlossen', 'storniert')),
  beschreibung TEXT,
  geplant_von DATE,
  geplant_bis DATE,
  is_deleted BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE auftraege IS 'Auftraege - aus Offerten oder direkt erfasst';

-- Zeiterfassungen
CREATE TABLE zeiterfassungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  auftrag_id UUID NOT NULL REFERENCES auftraege(id) ON DELETE CASCADE,
  datum DATE NOT NULL DEFAULT CURRENT_DATE,
  start_zeit TIME,
  end_zeit TIME,
  pause_minuten INTEGER NOT NULL DEFAULT 0,
  dauer_minuten INTEGER GENERATED ALWAYS AS (
    CASE
      WHEN start_zeit IS NOT NULL AND end_zeit IS NOT NULL
        THEN EXTRACT(EPOCH FROM (end_zeit - start_zeit))::INTEGER / 60 - COALESCE(pause_minuten, 0)
      ELSE NULL
    END
  ) STORED,
  beschreibung TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE zeiterfassungen IS 'Stundenrapport pro Auftrag';

-- Rapporte (Arbeitsrapport / Tagesrapport)
CREATE TABLE rapporte (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auftrag_id UUID NOT NULL REFERENCES auftraege(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  datum DATE NOT NULL DEFAULT CURRENT_DATE,
  beschreibung TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'entwurf'
    CHECK (status IN ('entwurf', 'abgeschlossen')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE rapporte IS 'Arbeitsrapporte zu Auftraegen';

-- ============================================================================
-- RECHNUNGSWESEN
-- ============================================================================

-- Rechnungen
CREATE TABLE rechnungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kunde_id UUID NOT NULL REFERENCES kunden(id),
  auftrag_id UUID REFERENCES auftraege(id),
  rechnungs_nr TEXT NOT NULL,
  datum DATE NOT NULL DEFAULT CURRENT_DATE,
  faellig_am DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'entwurf'
    CHECK (status IN ('entwurf', 'gesendet', 'bezahlt', 'storniert', 'gemahnt')),
  total_netto NUMERIC(10,2) NOT NULL DEFAULT 0,
  mwst_satz NUMERIC(4,2) NOT NULL DEFAULT 8.10,
  mwst_betrag NUMERIC(10,2) NOT NULL DEFAULT 0,
  total_brutto NUMERIC(10,2) NOT NULL DEFAULT 0,
  qr_referenz TEXT,          -- Swiss QR-Rechnung Referenznummer
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE rechnungen IS 'Ausgangsrechnungen mit Swiss QR-Code Unterstuetzung';
COMMENT ON COLUMN rechnungen.qr_referenz IS 'QR-Referenznummer fuer Swiss QR-Rechnung (ISO 11649)';

-- Rechnungs-Positionen
CREATE TABLE rechnungs_positionen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rechnung_id UUID NOT NULL REFERENCES rechnungen(id) ON DELETE CASCADE,
  position_nr INTEGER NOT NULL,
  bezeichnung TEXT NOT NULL,
  menge NUMERIC(10,3) NOT NULL DEFAULT 1,
  einheit TEXT NOT NULL DEFAULT 'Stk',
  einheitspreis NUMERIC(10,2) NOT NULL,
  betrag NUMERIC(10,2) GENERATED ALWAYS AS (menge * einheitspreis) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE rechnungs_positionen IS 'Einzelpositionen einer Rechnung';

-- ============================================================================
-- BUCHHALTUNG (Doppelte Buchhaltung nach OR Art. 957)
-- ============================================================================

-- Kontenrahmen (Schweizer KMU Kontenrahmen)
CREATE TABLE konten (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  kontonummer INTEGER NOT NULL,
  bezeichnung TEXT NOT NULL,
  kontenklasse INTEGER GENERATED ALWAYS AS (kontonummer / 1000) STORED,
  typ TEXT NOT NULL CHECK (typ IN ('aktiv', 'passiv', 'aufwand', 'ertrag')),
  saldo NUMERIC(12,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, kontonummer)
);

COMMENT ON TABLE konten IS 'Kontenrahmen - Schweizer KMU Standard fuer Handwerksbetriebe';
COMMENT ON COLUMN konten.kontenklasse IS 'Automatisch: 1=Aktiven, 2=Passiven, 3=Ertrag, 4-6=Aufwand, 8=a.o.';
COMMENT ON COLUMN konten.saldo IS 'Aktueller Saldo, wird durch Trigger aktualisiert';

-- Journal / Buchungen (Hauptbuch)
CREATE TABLE buchungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  datum DATE NOT NULL DEFAULT CURRENT_DATE,
  soll_konto INTEGER NOT NULL,
  haben_konto INTEGER NOT NULL,
  betrag NUMERIC(12,2) NOT NULL CHECK (betrag > 0),
  beschreibung TEXT NOT NULL,
  beleg_nr TEXT,
  rechnung_id UUID REFERENCES rechnungen(id),
  monat INTEGER GENERATED ALWAYS AS (EXTRACT(MONTH FROM datum)::INTEGER) STORED,
  quartal INTEGER GENERATED ALWAYS AS (EXTRACT(QUARTER FROM datum)::INTEGER) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE buchungen IS 'Journal - Doppelte Buchhaltung (Soll an Haben)';
COMMENT ON COLUMN buchungen.soll_konto IS 'Soll-Kontonummer (Belastung)';
COMMENT ON COLUMN buchungen.haben_konto IS 'Haben-Kontonummer (Gutschrift)';
COMMENT ON COLUMN buchungen.betrag IS 'Buchungsbetrag in CHF (immer positiv)';

-- Buchungsvorlagen (fuer automatische Buchungen)
CREATE TABLE buchungs_vorlagen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  geschaeftsfall_id TEXT NOT NULL,
  bezeichnung TEXT NOT NULL,
  soll_konto INTEGER NOT NULL,
  haben_konto INTEGER NOT NULL,
  auto_trigger TEXT CHECK (auto_trigger IN (
    'rechnung_erstellt',
    'rechnung_bezahlt',
    'rechnung_storniert'
  )),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE buchungs_vorlagen IS 'Vorlagen fuer automatische Buchungen bei Geschaeftsvorfaellen';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Kunden
CREATE INDEX idx_kunden_user_id ON kunden(user_id);
CREATE INDEX idx_kunden_user_id_not_deleted ON kunden(user_id) WHERE is_deleted = false;
CREATE INDEX idx_kunden_nachname ON kunden(user_id, nachname);

-- Kunden-Kontakte
CREATE INDEX idx_kunden_kontakte_kunde_id ON kunden_kontakte(kunde_id);

-- Offerten
CREATE INDEX idx_offerten_user_id ON offerten(user_id);
CREATE INDEX idx_offerten_kunde_id ON offerten(kunde_id);
CREATE INDEX idx_offerten_status ON offerten(user_id, status);
CREATE INDEX idx_offerten_datum ON offerten(user_id, datum DESC);

-- Offert-Positionen
CREATE INDEX idx_offert_positionen_offerte_id ON offert_positionen(offerte_id);

-- Auftraege
CREATE INDEX idx_auftraege_user_id ON auftraege(user_id);
CREATE INDEX idx_auftraege_kunde_id ON auftraege(kunde_id);
CREATE INDEX idx_auftraege_offerte_id ON auftraege(offerte_id);
CREATE INDEX idx_auftraege_status ON auftraege(user_id, status);

-- Zeiterfassungen
CREATE INDEX idx_zeiterfassungen_user_id ON zeiterfassungen(user_id);
CREATE INDEX idx_zeiterfassungen_auftrag_id ON zeiterfassungen(auftrag_id);
CREATE INDEX idx_zeiterfassungen_datum ON zeiterfassungen(user_id, datum DESC);

-- Rapporte
CREATE INDEX idx_rapporte_auftrag_id ON rapporte(auftrag_id);
CREATE INDEX idx_rapporte_user_id ON rapporte(user_id);
CREATE INDEX idx_rapporte_datum ON rapporte(user_id, datum DESC);

-- Rechnungen
CREATE INDEX idx_rechnungen_user_id ON rechnungen(user_id);
CREATE INDEX idx_rechnungen_kunde_id ON rechnungen(kunde_id);
CREATE INDEX idx_rechnungen_auftrag_id ON rechnungen(auftrag_id);
CREATE INDEX idx_rechnungen_status ON rechnungen(user_id, status);
CREATE INDEX idx_rechnungen_datum ON rechnungen(user_id, datum DESC);
CREATE INDEX idx_rechnungen_faellig ON rechnungen(user_id, faellig_am) WHERE status IN ('gesendet', 'gemahnt');

-- Rechnungs-Positionen
CREATE INDEX idx_rechnungs_positionen_rechnung_id ON rechnungs_positionen(rechnung_id);

-- Konten
CREATE INDEX idx_konten_user_id ON konten(user_id);
CREATE INDEX idx_konten_user_kontonummer ON konten(user_id, kontonummer);

-- Buchungen
CREATE INDEX idx_buchungen_user_id ON buchungen(user_id);
CREATE INDEX idx_buchungen_datum ON buchungen(user_id, datum DESC);
CREATE INDEX idx_buchungen_soll_konto ON buchungen(user_id, soll_konto);
CREATE INDEX idx_buchungen_haben_konto ON buchungen(user_id, haben_konto);
CREATE INDEX idx_buchungen_rechnung_id ON buchungen(rechnung_id);
CREATE INDEX idx_buchungen_monat ON buchungen(user_id, monat);
CREATE INDEX idx_buchungen_quartal ON buchungen(user_id, quartal);

-- Buchungsvorlagen
CREATE INDEX idx_buchungs_vorlagen_user_id ON buchungs_vorlagen(user_id);
CREATE INDEX idx_buchungs_vorlagen_trigger ON buchungs_vorlagen(user_id, auto_trigger);

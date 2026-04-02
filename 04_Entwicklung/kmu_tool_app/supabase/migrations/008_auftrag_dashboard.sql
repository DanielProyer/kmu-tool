-- ============================================================
-- 008: Auftrag-Dashboard (Notizen, Dateien, Zugriffe)
-- Premium-Feature, Online-only
-- ============================================================

-- Auftrag-Notizen
CREATE TABLE IF NOT EXISTS auftrag_notizen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auftrag_id UUID NOT NULL REFERENCES auftraege(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  typ TEXT NOT NULL DEFAULT 'text' CHECK (typ IN ('text', 'foto', 'pdf')),
  inhalt TEXT,
  datei_pfad TEXT,
  datei_name TEXT,
  datei_groesse INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auftrag-Dateien
CREATE TABLE IF NOT EXISTS auftrag_dateien (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auftrag_id UUID NOT NULL REFERENCES auftraege(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  kategorie TEXT NOT NULL DEFAULT 'allgemein' CHECK (kategorie IN ('allgemein', 'plan', 'foto', 'vertrag', 'rechnung', 'sonstiges')),
  datei_pfad TEXT NOT NULL,
  datei_name TEXT NOT NULL,
  datei_typ TEXT,
  datei_groesse INTEGER,
  fuer_kunde_sichtbar BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Auftrag-Zugriffe (Rollen-basiert)
CREATE TABLE IF NOT EXISTS auftrag_zugriffe (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auftrag_id UUID NOT NULL REFERENCES auftraege(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  owner_user_id UUID NOT NULL REFERENCES auth.users(id),
  rolle TEXT NOT NULL DEFAULT 'standard' CHECK (rolle IN ('vollzugriff', 'standard', 'kunde')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT auftrag_zugriffe_unique UNIQUE (auftrag_id, user_id)
);

-- Indizes
CREATE INDEX IF NOT EXISTS idx_auftrag_notizen_auftrag ON auftrag_notizen(auftrag_id);
CREATE INDEX IF NOT EXISTS idx_auftrag_dateien_auftrag ON auftrag_dateien(auftrag_id);
CREATE INDEX IF NOT EXISTS idx_auftrag_zugriffe_auftrag ON auftrag_zugriffe(auftrag_id);
CREATE INDEX IF NOT EXISTS idx_auftrag_zugriffe_user ON auftrag_zugriffe(user_id);

-- Updated-at Triggers
CREATE OR REPLACE FUNCTION update_auftrag_notizen_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auftrag_notizen_updated_at
  BEFORE UPDATE ON auftrag_notizen
  FOR EACH ROW
  EXECUTE FUNCTION update_auftrag_notizen_updated_at();

CREATE OR REPLACE FUNCTION update_auftrag_dateien_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_auftrag_dateien_updated_at
  BEFORE UPDATE ON auftrag_dateien
  FOR EACH ROW
  EXECUTE FUNCTION update_auftrag_dateien_updated_at();

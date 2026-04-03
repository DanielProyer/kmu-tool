-- ============================================================================
-- KMU Tool - Migration 023: Mitarbeiter-Erweiterung + Fahrzeuge
-- ============================================================================
-- Part 1: Mitarbeiter-Tabelle erweitern (zusaetzliche Felder)
-- Part 2: Fahrzeuge-Tabelle erstellen
-- Part 3: Mitarbeiter RLS-Policies umschreiben -> get_betrieb_owner_id()
-- ============================================================================

-- ============================================================================
-- TEIL 1: Mitarbeiter-Tabelle erweitern
-- ============================================================================

ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS telefon TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS email TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS rolle TEXT DEFAULT 'mitarbeiter'
  CHECK (rolle IN ('geschaeftsfuehrer','vorarbeiter','geselle','lehrling','mitarbeiter','buero'));
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS strasse TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS hausnummer TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS plz TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS ort TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS notizen TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT false;

-- ============================================================================
-- TEIL 2: Fahrzeuge-Tabelle erstellen
-- ============================================================================

CREATE TABLE IF NOT EXISTS fahrzeuge (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  kennzeichen TEXT,
  marke TEXT,
  modell TEXT,
  jahrgang INT,
  naechste_service DATE,
  naechste_mfk DATE,
  km_stand INT,
  versicherung TEXT,
  notizen TEXT,
  aktiv BOOLEAN DEFAULT true,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS
ALTER TABLE fahrzeuge ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fahrzeuge_select" ON fahrzeuge FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "fahrzeuge_insert" ON fahrzeuge FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "fahrzeuge_update" ON fahrzeuge FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "fahrzeuge_delete" ON fahrzeuge FOR DELETE USING (user_id = get_betrieb_owner_id());

-- Trigger
CREATE TRIGGER update_fahrzeuge_updated_at
  BEFORE UPDATE ON fahrzeuge
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Index
CREATE INDEX IF NOT EXISTS idx_fahrzeuge_user_id ON fahrzeuge(user_id);

-- ============================================================================
-- TEIL 3: Mitarbeiter RLS-Policies umschreiben -> get_betrieb_owner_id()
-- ============================================================================
-- Bestehende Policy aus 011 war "mitarbeiter_own" mit auth.uid()
-- Wird jetzt auf separate Policies mit get_betrieb_owner_id() umgestellt

DROP POLICY IF EXISTS "mitarbeiter_own" ON mitarbeiter;
DROP POLICY IF EXISTS "mitarbeiter_select" ON mitarbeiter;
DROP POLICY IF EXISTS "mitarbeiter_insert" ON mitarbeiter;
DROP POLICY IF EXISTS "mitarbeiter_update" ON mitarbeiter;
DROP POLICY IF EXISTS "mitarbeiter_delete" ON mitarbeiter;
DROP POLICY IF EXISTS "Users can CRUD own mitarbeiter" ON mitarbeiter;

CREATE POLICY "mitarbeiter_select" ON mitarbeiter FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_insert" ON mitarbeiter FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_update" ON mitarbeiter FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_delete" ON mitarbeiter FOR DELETE USING (user_id = get_betrieb_owner_id());

-- ============================================================================
-- ENDE Migration 023
-- ============================================================================

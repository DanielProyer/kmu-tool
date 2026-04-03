-- Migration 020: Inventur (Jahresinventur)
-- ==========================================

-- 1. Inventuren
CREATE TABLE IF NOT EXISTS inventuren (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  stichtag DATE NOT NULL,
  lagerort_id UUID REFERENCES lagerorte(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'geplant' CHECK (status IN ('geplant', 'aktiv', 'abgeschlossen')),
  bemerkung TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventuren_user ON inventuren(user_id);
CREATE INDEX IF NOT EXISTS idx_inventuren_status ON inventuren(user_id, status);

ALTER TABLE inventuren ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventuren_select" ON inventuren
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "inventuren_insert" ON inventuren
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "inventuren_update" ON inventuren
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "inventuren_delete" ON inventuren
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER trg_inventuren_updated
  BEFORE UPDATE ON inventuren
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Inventur-Positionen
CREATE TABLE IF NOT EXISTS inventur_positionen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  inventur_id UUID NOT NULL REFERENCES inventuren(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE RESTRICT,
  lagerort_id UUID NOT NULL REFERENCES lagerorte(id) ON DELETE RESTRICT,
  soll_bestand DECIMAL(12,3) DEFAULT 0,
  ist_bestand DECIMAL(12,3),
  differenz DECIMAL(12,3) GENERATED ALWAYS AS (COALESCE(ist_bestand, 0) - soll_bestand) STORED,
  bewertungspreis DECIMAL(12,2) DEFAULT 0,
  gezaehlt BOOLEAN DEFAULT false,
  bemerkung TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventur_positionen_inventur ON inventur_positionen(inventur_id);
CREATE INDEX IF NOT EXISTS idx_inventur_positionen_artikel ON inventur_positionen(artikel_id);

ALTER TABLE inventur_positionen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "inventur_positionen_select" ON inventur_positionen
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "inventur_positionen_insert" ON inventur_positionen
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "inventur_positionen_update" ON inventur_positionen
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "inventur_positionen_delete" ON inventur_positionen
  FOR DELETE USING (auth.uid() = user_id);

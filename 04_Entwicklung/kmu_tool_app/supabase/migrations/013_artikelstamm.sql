-- Migration 013: Artikelstamm (Material catalog) + Offert-Positionen Typ
-- =====================================================================

-- Artikelstamm Tabelle
CREATE TABLE IF NOT EXISTS artikel (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  artikel_nr TEXT,
  bezeichnung TEXT NOT NULL,
  kategorie TEXT DEFAULT 'material' CHECK (kategorie IN ('material', 'werkzeug', 'verbrauch')),
  einheit TEXT DEFAULT 'Stk',
  einkaufspreis NUMERIC(10,2) DEFAULT 0,
  verkaufspreis NUMERIC(10,2) DEFAULT 0,
  lagerbestand NUMERIC(10,2) DEFAULT 0,
  mindestbestand NUMERIC(10,2),
  lieferant TEXT,
  notizen TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_artikel_user ON artikel(user_id);
CREATE INDEX IF NOT EXISTS idx_artikel_kategorie ON artikel(user_id, kategorie);

-- Offert-Positionen erweitern: Typ (arbeit/material) + Artikel-Verknuepfung
ALTER TABLE offert_positionen ADD COLUMN IF NOT EXISTS typ TEXT DEFAULT 'arbeit' CHECK (typ IN ('arbeit', 'material'));
ALTER TABLE offert_positionen ADD COLUMN IF NOT EXISTS artikel_id UUID REFERENCES artikel(id) ON DELETE SET NULL;

-- RLS
ALTER TABLE artikel ENABLE ROW LEVEL SECURITY;
CREATE POLICY "artikel_select" ON artikel FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "artikel_insert" ON artikel FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "artikel_update" ON artikel FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "artikel_delete" ON artikel FOR DELETE USING (auth.uid() = user_id);

-- Updated-At Trigger
CREATE TRIGGER update_artikel_updated_at
  BEFORE UPDATE ON artikel
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

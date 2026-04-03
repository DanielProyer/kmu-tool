-- Migration 015: Lagerorte + Artikel-Erweiterungen
-- ===================================================

-- 1. Lagerorte-Tabelle
CREATE TABLE IF NOT EXISTS lagerorte (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  typ TEXT DEFAULT 'lager' CHECK (typ IN ('lager', 'fahrzeug', 'baustelle')),
  ist_standard BOOLEAN DEFAULT false,
  sortierung INT DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lagerorte_user ON lagerorte(user_id);

-- RLS
ALTER TABLE lagerorte ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lagerorte_select" ON lagerorte
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "lagerorte_insert" ON lagerorte
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "lagerorte_update" ON lagerorte
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "lagerorte_delete" ON lagerorte
  FOR DELETE USING (auth.uid() = user_id);

-- Trigger
CREATE TRIGGER update_lagerorte_updated_at
  BEFORE UPDATE ON lagerorte
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Artikel-Tabelle erweitern
ALTER TABLE artikel ADD COLUMN IF NOT EXISTS material_typ TEXT DEFAULT 'material'
  CHECK (material_typ IN ('material', 'werkzeug', 'verbrauch', 'dienstleistung'));
ALTER TABLE artikel ADD COLUMN IF NOT EXISTS aufwandkonto INT;
ALTER TABLE artikel ADD COLUMN IF NOT EXISTS mwst_code VARCHAR(20);

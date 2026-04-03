-- Migration 016: Lieferanten + Artikel-Fotos
-- =============================================

-- 1. Lieferanten-Tabelle
CREATE TABLE IF NOT EXISTS lieferanten (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  firma TEXT NOT NULL,
  kontaktperson TEXT,
  strasse TEXT,
  plz TEXT,
  ort TEXT,
  telefon TEXT,
  email TEXT,
  website TEXT,
  zahlungsfrist_tage INT DEFAULT 30,
  notizen TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lieferanten_user ON lieferanten(user_id);

-- RLS
ALTER TABLE lieferanten ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lieferanten_select" ON lieferanten
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "lieferanten_insert" ON lieferanten
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "lieferanten_update" ON lieferanten
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "lieferanten_delete" ON lieferanten
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER update_lieferanten_updated_at
  BEFORE UPDATE ON lieferanten
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Artikel-Lieferanten (M:N Junction)
CREATE TABLE IF NOT EXISTS artikel_lieferanten (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE CASCADE,
  lieferant_id UUID NOT NULL REFERENCES lieferanten(id) ON DELETE CASCADE,
  einkaufspreis DECIMAL(12,2),
  lieferanten_artikel_nr TEXT,
  mindestbestellmenge DECIMAL(12,2) DEFAULT 1,
  lieferzeit_tage INT,
  ist_hauptlieferant BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(artikel_id, lieferant_id)
);

CREATE INDEX IF NOT EXISTS idx_artikel_lieferanten_artikel ON artikel_lieferanten(artikel_id);
CREATE INDEX IF NOT EXISTS idx_artikel_lieferanten_lieferant ON artikel_lieferanten(lieferant_id);

-- RLS
ALTER TABLE artikel_lieferanten ENABLE ROW LEVEL SECURITY;

CREATE POLICY "artikel_lieferanten_select" ON artikel_lieferanten
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "artikel_lieferanten_insert" ON artikel_lieferanten
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "artikel_lieferanten_update" ON artikel_lieferanten
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "artikel_lieferanten_delete" ON artikel_lieferanten
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER update_artikel_lieferanten_updated_at
  BEFORE UPDATE ON artikel_lieferanten
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Artikel-Fotos
CREATE TABLE IF NOT EXISTS artikel_fotos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  datei_name TEXT NOT NULL,
  sortierung INT DEFAULT 0,
  ist_hauptbild BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_artikel_fotos_artikel ON artikel_fotos(artikel_id);

-- RLS
ALTER TABLE artikel_fotos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "artikel_fotos_select" ON artikel_fotos
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "artikel_fotos_insert" ON artikel_fotos
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "artikel_fotos_delete" ON artikel_fotos
  FOR DELETE USING (auth.uid() = user_id);

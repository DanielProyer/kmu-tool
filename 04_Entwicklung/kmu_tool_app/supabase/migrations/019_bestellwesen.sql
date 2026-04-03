-- Migration 019: Bestellwesen (Vorschläge + Bestellungen)
-- =====================================================

-- 1. Bestellvorschläge
CREATE TABLE IF NOT EXISTS bestellvorschlaege (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE CASCADE,
  lieferant_id UUID REFERENCES lieferanten(id) ON DELETE SET NULL,
  vorgeschlagene_menge DECIMAL(12,3) NOT NULL,
  aktueller_bestand DECIMAL(12,3) DEFAULT 0,
  mindestbestand DECIMAL(12,3) DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'offen' CHECK (status IN ('offen', 'bestellt', 'ignoriert')),
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bestellvorschlaege_user ON bestellvorschlaege(user_id);
CREATE INDEX IF NOT EXISTS idx_bestellvorschlaege_status ON bestellvorschlaege(user_id, status);
CREATE INDEX IF NOT EXISTS idx_bestellvorschlaege_artikel ON bestellvorschlaege(artikel_id);

ALTER TABLE bestellvorschlaege ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bestellvorschlaege_select" ON bestellvorschlaege
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bestellvorschlaege_insert" ON bestellvorschlaege
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bestellvorschlaege_update" ON bestellvorschlaege
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "bestellvorschlaege_delete" ON bestellvorschlaege
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER trg_bestellvorschlaege_updated
  BEFORE UPDATE ON bestellvorschlaege
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Bestellungen
CREATE TABLE IF NOT EXISTS bestellungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  lieferant_id UUID NOT NULL REFERENCES lieferanten(id) ON DELETE RESTRICT,
  bestell_nr TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'entwurf' CHECK (status IN ('entwurf', 'bestellt', 'teilgeliefert', 'geliefert', 'storniert')),
  bestell_datum DATE,
  erwartetes_lieferdatum DATE,
  liefer_datum DATE,
  bemerkung TEXT,
  total_betrag DECIMAL(12,2) DEFAULT 0,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bestellungen_user ON bestellungen(user_id);
CREATE INDEX IF NOT EXISTS idx_bestellungen_status ON bestellungen(user_id, status);
CREATE INDEX IF NOT EXISTS idx_bestellungen_lieferant ON bestellungen(lieferant_id);
CREATE INDEX IF NOT EXISTS idx_bestellungen_nr ON bestellungen(user_id, bestell_nr);

ALTER TABLE bestellungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bestellungen_select" ON bestellungen
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bestellungen_insert" ON bestellungen
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bestellungen_update" ON bestellungen
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "bestellungen_delete" ON bestellungen
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER trg_bestellungen_updated
  BEFORE UPDATE ON bestellungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Bestellpositionen
CREATE TABLE IF NOT EXISTS bestellpositionen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bestellung_id UUID NOT NULL REFERENCES bestellungen(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE RESTRICT,
  menge DECIMAL(12,3) NOT NULL,
  einzelpreis DECIMAL(12,2) DEFAULT 0,
  gelieferte_menge DECIMAL(12,3) DEFAULT 0,
  bemerkung TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bestellpositionen_bestellung ON bestellpositionen(bestellung_id);
CREATE INDEX IF NOT EXISTS idx_bestellpositionen_artikel ON bestellpositionen(artikel_id);

ALTER TABLE bestellpositionen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bestellpositionen_select" ON bestellpositionen
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "bestellpositionen_insert" ON bestellpositionen
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "bestellpositionen_update" ON bestellpositionen
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "bestellpositionen_delete" ON bestellpositionen
  FOR DELETE USING (auth.uid() = user_id);

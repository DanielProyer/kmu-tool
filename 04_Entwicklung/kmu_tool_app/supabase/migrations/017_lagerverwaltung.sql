-- Migration 017: Lagerverwaltung (Bestände + Bewegungen)
-- ========================================================

-- 1. Lagerbestände pro Artikel + Lagerort
CREATE TABLE IF NOT EXISTS lagerbestaende (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE CASCADE,
  lagerort_id UUID NOT NULL REFERENCES lagerorte(id) ON DELETE CASCADE,
  menge DECIMAL(12,3) DEFAULT 0,
  reserviert DECIMAL(12,3) DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(artikel_id, lagerort_id)
);

CREATE INDEX IF NOT EXISTS idx_lagerbestaende_artikel ON lagerbestaende(artikel_id);
CREATE INDEX IF NOT EXISTS idx_lagerbestaende_lagerort ON lagerbestaende(lagerort_id);

-- RLS
ALTER TABLE lagerbestaende ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lagerbestaende_select" ON lagerbestaende
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "lagerbestaende_insert" ON lagerbestaende
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "lagerbestaende_update" ON lagerbestaende
  FOR UPDATE USING (auth.uid() = user_id);

-- 2. Lagerbewegungen (Audit-Trail)
CREATE TABLE IF NOT EXISTS lagerbewegungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  artikel_id UUID NOT NULL REFERENCES artikel(id) ON DELETE CASCADE,
  lagerort_id UUID NOT NULL REFERENCES lagerorte(id),
  ziel_lagerort_id UUID REFERENCES lagerorte(id),
  bewegungstyp TEXT NOT NULL CHECK (bewegungstyp IN ('eingang', 'ausgang', 'umlagerung', 'korrektur', 'inventur')),
  menge DECIMAL(12,3) NOT NULL,
  referenz_typ TEXT,
  referenz_id UUID,
  bemerkung TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lagerbewegungen_artikel ON lagerbewegungen(artikel_id);
CREATE INDEX IF NOT EXISTS idx_lagerbewegungen_lagerort ON lagerbewegungen(lagerort_id);
CREATE INDEX IF NOT EXISTS idx_lagerbewegungen_created ON lagerbewegungen(created_at DESC);

-- RLS
ALTER TABLE lagerbewegungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lagerbewegungen_select" ON lagerbewegungen
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "lagerbewegungen_insert" ON lagerbewegungen
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. View: Gesamtbestand pro Artikel
CREATE OR REPLACE VIEW v_artikel_gesamtbestand AS
SELECT
  artikel_id,
  user_id,
  SUM(menge) AS gesamtmenge,
  SUM(reserviert) AS gesamt_reserviert,
  SUM(menge) - SUM(reserviert) AS verfuegbar
FROM lagerbestaende
GROUP BY artikel_id, user_id;

-- 4. Trigger: Lagerbewegung -> Lagerbestand + artikel.lagerbestand aktualisieren
CREATE OR REPLACE FUNCTION update_lagerbestand_nach_bewegung()
RETURNS TRIGGER AS $$
BEGIN
  -- Quell-Lagerort: Bestand anpassen
  IF NEW.bewegungstyp IN ('ausgang', 'umlagerung') THEN
    INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
    VALUES (NEW.user_id, NEW.artikel_id, NEW.lagerort_id, -NEW.menge)
    ON CONFLICT (artikel_id, lagerort_id) DO UPDATE
    SET menge = lagerbestaende.menge - NEW.menge, updated_at = now();
  ELSIF NEW.bewegungstyp IN ('eingang', 'korrektur', 'inventur') THEN
    INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
    VALUES (NEW.user_id, NEW.artikel_id, NEW.lagerort_id, NEW.menge)
    ON CONFLICT (artikel_id, lagerort_id) DO UPDATE
    SET menge = lagerbestaende.menge + NEW.menge, updated_at = now();
  END IF;

  -- Ziel-Lagerort bei Umlagerung: Bestand erhöhen
  IF NEW.bewegungstyp = 'umlagerung' AND NEW.ziel_lagerort_id IS NOT NULL THEN
    INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
    VALUES (NEW.user_id, NEW.artikel_id, NEW.ziel_lagerort_id, NEW.menge)
    ON CONFLICT (artikel_id, lagerort_id) DO UPDATE
    SET menge = lagerbestaende.menge + NEW.menge, updated_at = now();
  END IF;

  -- Rückwärtskompatibilität: artikel.lagerbestand synchronisieren
  UPDATE artikel SET lagerbestand = COALESCE(
    (SELECT SUM(menge) FROM lagerbestaende WHERE artikel_id = NEW.artikel_id), 0
  ) WHERE id = NEW.artikel_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_lagerbewegung_bestand
  AFTER INSERT ON lagerbewegungen
  FOR EACH ROW EXECUTE FUNCTION update_lagerbestand_nach_bewegung();

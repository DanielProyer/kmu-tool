-- Migration 026: Betriebsverwaltung
-- Neue Tabellen: bankverbindungen, mitarbeiter_berechtigungen, sozialversicherungen, lohnabrechnungen
-- Erweitert: mitarbeiter (Lohn-Felder), user_profiles (Logo/Website)

-- ============================================================================
-- 1. BANKVERBINDUNGEN
-- ============================================================================
CREATE TABLE IF NOT EXISTS bankverbindungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  iban TEXT NOT NULL,
  bank_name TEXT,
  bic TEXT,
  ist_hauptkonto BOOLEAN DEFAULT false,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE bankverbindungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bankverbindungen_select" ON bankverbindungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bankverbindungen_insert" ON bankverbindungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "bankverbindungen_update" ON bankverbindungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "bankverbindungen_delete" ON bankverbindungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

CREATE TRIGGER update_bankverbindungen_updated_at
  BEFORE UPDATE ON bankverbindungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_bankverbindungen_user_id ON bankverbindungen(user_id);

-- ============================================================================
-- 2. MITARBEITER_BERECHTIGUNGEN
-- ============================================================================
CREATE TABLE IF NOT EXISTS mitarbeiter_berechtigungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mitarbeiter_id UUID NOT NULL REFERENCES mitarbeiter(id) ON DELETE CASCADE,
  modul TEXT NOT NULL,
  lesen BOOLEAN DEFAULT false,
  schreiben BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(mitarbeiter_id, modul)
);

ALTER TABLE mitarbeiter_berechtigungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mitarbeiter_berechtigungen_select" ON mitarbeiter_berechtigungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_berechtigungen_insert" ON mitarbeiter_berechtigungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_berechtigungen_update" ON mitarbeiter_berechtigungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "mitarbeiter_berechtigungen_delete" ON mitarbeiter_berechtigungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

CREATE TRIGGER update_mitarbeiter_berechtigungen_updated_at
  BEFORE UPDATE ON mitarbeiter_berechtigungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_mitarbeiter_berechtigungen_mitarbeiter ON mitarbeiter_berechtigungen(mitarbeiter_id);
CREATE INDEX IF NOT EXISTS idx_mitarbeiter_berechtigungen_user_id ON mitarbeiter_berechtigungen(user_id);

-- ============================================================================
-- 3. SOZIALVERSICHERUNGEN (1 Zeile pro Betrieb)
-- ============================================================================
CREATE TABLE IF NOT EXISTS sozialversicherungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- AHV/IV/EO
  ahv_satz_ag NUMERIC(5,3) DEFAULT 5.300,
  ahv_satz_an NUMERIC(5,3) DEFAULT 5.300,

  -- ALV
  alv_satz_ag NUMERIC(5,3) DEFAULT 1.100,
  alv_satz_an NUMERIC(5,3) DEFAULT 1.100,
  alv_grenze NUMERIC(12,2) DEFAULT 148200.00,
  alv2_satz NUMERIC(5,3) DEFAULT 1.000,

  -- UVG
  uvg_bu_satz NUMERIC(5,3) DEFAULT 0.000,
  uvg_nbu_satz NUMERIC(5,3) DEFAULT 0.000,
  uvg_max_verdienst NUMERIC(12,2) DEFAULT 148200.00,

  -- KTG
  ktg_satz_ag NUMERIC(5,3) DEFAULT 0.000,
  ktg_satz_an NUMERIC(5,3) DEFAULT 0.000,

  -- BVG
  bvg_anbieter TEXT,
  bvg_vertrag_nr TEXT,
  bvg_koordinationsabzug NUMERIC(12,2) DEFAULT 25725.00,
  bvg_eintrittsschwelle NUMERIC(12,2) DEFAULT 22050.00,
  bvg_max_versicherter_lohn NUMERIC(12,2) DEFAULT 88200.00,
  bvg_satz_25_34 NUMERIC(5,3) DEFAULT 7.000,
  bvg_satz_35_44 NUMERIC(5,3) DEFAULT 10.000,
  bvg_satz_45_54 NUMERIC(5,3) DEFAULT 15.000,
  bvg_satz_55_64 NUMERIC(5,3) DEFAULT 18.000,
  bvg_ag_anteil_prozent NUMERIC(5,2) DEFAULT 50.00,

  -- Kinderzulagen (FAK)
  kinderzulage_betrag NUMERIC(8,2) DEFAULT 200.00,
  ausbildungszulage_betrag NUMERIC(8,2) DEFAULT 250.00,

  -- Quellensteuer
  quellensteuer_aktiv BOOLEAN DEFAULT false,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE sozialversicherungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "sozialversicherungen_select" ON sozialversicherungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "sozialversicherungen_insert" ON sozialversicherungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "sozialversicherungen_update" ON sozialversicherungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "sozialversicherungen_delete" ON sozialversicherungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

CREATE TRIGGER update_sozialversicherungen_updated_at
  BEFORE UPDATE ON sozialversicherungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. LOHNABRECHNUNGEN
-- ============================================================================
CREATE TABLE IF NOT EXISTS lohnabrechnungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  mitarbeiter_id UUID NOT NULL REFERENCES mitarbeiter(id) ON DELETE CASCADE,
  monat INTEGER NOT NULL CHECK (monat BETWEEN 1 AND 12),
  jahr INTEGER NOT NULL CHECK (jahr BETWEEN 2020 AND 2100),

  -- Brutto
  bruttolohn NUMERIC(12,2) NOT NULL DEFAULT 0,
  pensum NUMERIC(5,3) DEFAULT 1.000,

  -- AN-Abzuege
  ahv_an NUMERIC(10,2) DEFAULT 0,
  alv_an NUMERIC(10,2) DEFAULT 0,
  uvg_nbu_an NUMERIC(10,2) DEFAULT 0,
  ktg_an NUMERIC(10,2) DEFAULT 0,
  bvg_an NUMERIC(10,2) DEFAULT 0,
  quellensteuer NUMERIC(10,2) DEFAULT 0,

  -- Zulagen
  kinderzulagen NUMERIC(10,2) DEFAULT 0,

  -- Netto
  nettolohn NUMERIC(12,2) DEFAULT 0,

  -- AG-Kosten
  ahv_ag NUMERIC(10,2) DEFAULT 0,
  alv_ag NUMERIC(10,2) DEFAULT 0,
  uvg_bu_ag NUMERIC(10,2) DEFAULT 0,
  ktg_ag NUMERIC(10,2) DEFAULT 0,
  bvg_ag NUMERIC(10,2) DEFAULT 0,
  fak_ag NUMERIC(10,2) DEFAULT 0,
  total_ag_kosten NUMERIC(12,2) DEFAULT 0,

  -- Status
  status TEXT DEFAULT 'entwurf' CHECK (status IN ('entwurf', 'freigegeben', 'ausbezahlt')),

  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(mitarbeiter_id, monat, jahr)
);

ALTER TABLE lohnabrechnungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lohnabrechnungen_select" ON lohnabrechnungen
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lohnabrechnungen_insert" ON lohnabrechnungen
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "lohnabrechnungen_update" ON lohnabrechnungen
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "lohnabrechnungen_delete" ON lohnabrechnungen
  FOR DELETE USING (user_id = get_betrieb_owner_id());

CREATE TRIGGER update_lohnabrechnungen_updated_at
  BEFORE UPDATE ON lohnabrechnungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_lohnabrechnungen_user_id ON lohnabrechnungen(user_id);
CREATE INDEX IF NOT EXISTS idx_lohnabrechnungen_mitarbeiter ON lohnabrechnungen(mitarbeiter_id);
CREATE INDEX IF NOT EXISTS idx_lohnabrechnungen_periode ON lohnabrechnungen(jahr, monat);

-- ============================================================================
-- 5. MITARBEITER erweitern (Lohn-Felder)
-- ============================================================================
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS bruttolohn_monat NUMERIC(12,2);
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS geburtsdatum DATE;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS eintrittsdatum DATE;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS austrittsdatum DATE;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS anzahl_kinder INTEGER DEFAULT 0;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS anzahl_kinder_ausbildung INTEGER DEFAULT 0;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS quellensteuer_code TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS quellensteuer_satz NUMERIC(5,3);
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS nationalitaet TEXT;
ALTER TABLE mitarbeiter ADD COLUMN IF NOT EXISTS bewilligungstyp TEXT;

-- ============================================================================
-- 6. USER_PROFILES erweitern (Logo/Website)
-- ============================================================================
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS website_url TEXT;

-- ============================================================================
-- 7. Datenmigration: Bestehende IBAN/Bank → bankverbindungen
-- ============================================================================
INSERT INTO bankverbindungen (user_id, bezeichnung, iban, bank_name, ist_hauptkonto)
SELECT id, 'Hauptkonto', iban, bank_name, true
FROM user_profiles
WHERE iban IS NOT NULL AND iban != ''
ON CONFLICT DO NOTHING;

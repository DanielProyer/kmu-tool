-- Migration 014: Vollstaendiges MWST-System
-- =============================================
-- Unterstuetzt: Effektive Methode + Saldosteuersatz-Methode
-- Basierend auf Recherche 07_MWST_Abrechnung_Schweiz.md

-- ─── 1. MWST-Codes (systemweit, nicht pro User) ───

CREATE TABLE IF NOT EXISTS mwst_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code VARCHAR(20) NOT NULL UNIQUE,
  bezeichnung VARCHAR(100) NOT NULL,
  satz DECIMAL(5,2) NOT NULL,
  typ VARCHAR(20) NOT NULL CHECK (typ IN ('umsatzsteuer', 'vorsteuer', 'bezugsteuer', 'ohne')),
  formular_ziffer_effektiv INT,
  formular_ziffer_sss INT,
  gueltig_ab DATE NOT NULL DEFAULT '2024-01-01',
  gueltig_bis DATE,
  ist_aktiv BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Seed MWST-Codes (Saetze ab 01.01.2024, gueltig 2025/2026)
INSERT INTO mwst_codes (code, bezeichnung, satz, typ, formular_ziffer_effektiv, formular_ziffer_sss, gueltig_ab) VALUES
('UST_NORM',     'Umsatzsteuer Normalsatz',           8.10, 'umsatzsteuer', 302, 322, '2024-01-01'),
('UST_RED',      'Umsatzsteuer reduziert',             2.60, 'umsatzsteuer', 312, NULL, '2024-01-01'),
('UST_BEH',      'Umsatzsteuer Beherbergung',          3.80, 'umsatzsteuer', 342, NULL, '2024-01-01'),
('UST_FREI',     'Steuerbefreit (Export)',              0.00, 'umsatzsteuer', 220, 220, '2024-01-01'),
('UST_AUSG',     'Von Steuer ausgenommen',              0.00, 'umsatzsteuer', 225, 225, '2024-01-01'),
('VST_MAT',      'Vorsteuer Material/DL',              8.10, 'vorsteuer',    400, NULL, '2024-01-01'),
('VST_MAT_RED',  'Vorsteuer Material reduziert',       2.60, 'vorsteuer',    400, NULL, '2024-01-01'),
('VST_INV',      'Vorsteuer Investitionen',            8.10, 'vorsteuer',    405, 405, '2024-01-01'),
('VST_INV_RED',  'Vorsteuer Investitionen reduziert',  2.60, 'vorsteuer',    405, 405, '2024-01-01'),
('BEZUG',        'Bezugsteuer (Ausland)',               8.10, 'bezugsteuer',  382, 382, '2024-01-01'),
('OHNE',         'Ohne MWST',                          0.00, 'ohne',         NULL, NULL, '2024-01-01')
ON CONFLICT (code) DO NOTHING;

-- ─── 2. MWST-Einstellungen pro Betrieb (User) ───

CREATE TABLE IF NOT EXISTS mwst_einstellungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  methode VARCHAR(20) NOT NULL DEFAULT 'effektiv' CHECK (methode IN ('effektiv', 'saldosteuersatz')),
  abrechnungsperiode VARCHAR(20) NOT NULL DEFAULT 'halbjaehrlich' CHECK (abrechnungsperiode IN ('quartalsweise', 'halbjaehrlich', 'jaehrlich')),
  saldosteuersatz_1 DECIMAL(5,2),
  saldosteuersatz_1_bez VARCHAR(100),
  saldosteuersatz_2 DECIMAL(5,2),
  saldosteuersatz_2_bez VARCHAR(100),
  mwst_nummer VARCHAR(30),
  mwst_pflichtig_seit DATE,
  vereinbartes_entgelt BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id)
);

-- ─── 3. MWST-Abrechnungen (generierte Reports) ───

CREATE TABLE IF NOT EXISTS mwst_abrechnungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Periode
  periode_start DATE NOT NULL,
  periode_end DATE NOT NULL,
  methode VARCHAR(20) NOT NULL,

  -- Teil I: Umsatz
  ziff_200 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_220 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_225 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_235 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_280 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_289 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_299 DECIMAL(12,2) NOT NULL DEFAULT 0,

  -- Teil II: Steuerberechnung
  ziff_302_umsatz DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_302_steuer DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_312_umsatz DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_312_steuer DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_342_umsatz DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_342_steuer DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_322_umsatz DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_322_steuer DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_332_umsatz DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_332_steuer DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_382 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_399 DECIMAL(12,2) NOT NULL DEFAULT 0,

  -- Teil III: Vorsteuer
  ziff_400 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_405 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_479 DECIMAL(12,2) NOT NULL DEFAULT 0,

  -- Teil IV: Zahllast
  ziff_500 DECIMAL(12,2) NOT NULL DEFAULT 0,
  ziff_510 DECIMAL(12,2) NOT NULL DEFAULT 0,

  -- Status
  status VARCHAR(20) NOT NULL DEFAULT 'entwurf' CHECK (status IN ('entwurf', 'eingereicht', 'bezahlt')),
  eingereicht_am TIMESTAMPTZ,
  bezahlt_am TIMESTAMPTZ,
  notizen TEXT,

  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_mwst_abrechnungen_user ON mwst_abrechnungen(user_id);
CREATE INDEX IF NOT EXISTS idx_mwst_abrechnungen_periode ON mwst_abrechnungen(user_id, periode_start, periode_end);

-- ─── 4. Buchungen-Tabelle erweitern ───

ALTER TABLE buchungen ADD COLUMN IF NOT EXISTS mwst_code VARCHAR(20);
ALTER TABLE buchungen ADD COLUMN IF NOT EXISTS mwst_satz DECIMAL(5,2);
ALTER TABLE buchungen ADD COLUMN IF NOT EXISTS mwst_betrag DECIMAL(12,2);

-- ─── 5. RLS Policies ───

ALTER TABLE mwst_codes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mwst_codes_select" ON mwst_codes FOR SELECT USING (true);

ALTER TABLE mwst_einstellungen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mwst_einst_select" ON mwst_einstellungen FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "mwst_einst_insert" ON mwst_einstellungen FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "mwst_einst_update" ON mwst_einstellungen FOR UPDATE USING (auth.uid() = user_id);

ALTER TABLE mwst_abrechnungen ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mwst_abr_select" ON mwst_abrechnungen FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "mwst_abr_insert" ON mwst_abrechnungen FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "mwst_abr_update" ON mwst_abrechnungen FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "mwst_abr_delete" ON mwst_abrechnungen FOR DELETE USING (auth.uid() = user_id);

-- Triggers
CREATE TRIGGER update_mwst_einstellungen_updated_at
  BEFORE UPDATE ON mwst_einstellungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_mwst_abrechnungen_updated_at
  BEFORE UPDATE ON mwst_abrechnungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

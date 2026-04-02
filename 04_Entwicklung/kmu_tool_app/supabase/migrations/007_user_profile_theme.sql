-- ============================================================
-- 007: User Profile Erweiterung (Theme + MWST)
-- ============================================================

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS theme_id TEXT DEFAULT 'blau_orange';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS mwst_pflichtig BOOLEAN DEFAULT false;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS mwst_methode TEXT DEFAULT 'effektiv';
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS mwst_saldosteuersatz NUMERIC(4,2);

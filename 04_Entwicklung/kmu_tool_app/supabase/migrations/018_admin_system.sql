-- Migration 018: Admin-Kundenverwaltung (SaaS-Administration)
-- ===========================================================
-- Admin-Panel für App-Owner zur Verwaltung aller SaaS-Kunden:
-- Kundenprofile, Plan/Feature-Steuerung, Rechnungskontrolle, Datenmigration

-- 1. Admin-Users (wer darf das Admin-Panel sehen)
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'admin' CHECK (role IN ('admin', 'superadmin')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Hilfsfunktion: Ist der aktuelle User ein Admin?
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- 2. Admin-Kundenprofile (erweiterte Infos pro SaaS-Kunde)
CREATE TABLE IF NOT EXISTS admin_kundenprofile (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  firma_name TEXT NOT NULL,
  kontaktperson TEXT,
  email TEXT,
  telefon TEXT,
  strasse TEXT,
  plz TEXT,
  ort TEXT,
  status TEXT DEFAULT 'aktiv' CHECK (status IN ('aktiv', 'inaktiv', 'gesperrt', 'test')),
  -- Voreinstellungen
  mwst_methode TEXT DEFAULT 'effektiv' CHECK (mwst_methode IN ('effektiv', 'saldosteuersatz')),
  anzahl_mitarbeiter INT DEFAULT 1,
  anzahl_fahrzeuge INT DEFAULT 0,
  branche TEXT,
  -- Plan-Steuerung (Referenz auf user_subscriptions)
  notizen TEXT,
  registriert_am TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_kundenprofile_user ON admin_kundenprofile(user_id);
CREATE INDEX IF NOT EXISTS idx_admin_kundenprofile_status ON admin_kundenprofile(status);

-- RLS: Nur Admins dürfen Admin-Kundenprofile sehen/bearbeiten
ALTER TABLE admin_kundenprofile ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_kundenprofile_select" ON admin_kundenprofile
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_kundenprofile_insert" ON admin_kundenprofile
  FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "admin_kundenprofile_update" ON admin_kundenprofile
  FOR UPDATE USING (is_admin());
CREATE POLICY "admin_kundenprofile_delete" ON admin_kundenprofile
  FOR DELETE USING (is_admin());

CREATE TRIGGER update_admin_kundenprofile_updated_at
  BEFORE UPDATE ON admin_kundenprofile
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Admin-Rechnungen (SaaS-Abrechnungen an Kunden)
CREATE TABLE IF NOT EXISTS admin_rechnungen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kunde_profil_id UUID NOT NULL REFERENCES admin_kundenprofile(id) ON DELETE CASCADE,
  rechnungs_nr TEXT NOT NULL,
  periode_von DATE,
  periode_bis DATE,
  plan_bezeichnung TEXT,
  betrag DECIMAL(12,2) NOT NULL DEFAULT 0,
  mwst_satz DECIMAL(5,2) DEFAULT 8.1,
  mwst_betrag DECIMAL(12,2) NOT NULL DEFAULT 0,
  total DECIMAL(12,2) NOT NULL DEFAULT 0,
  status TEXT DEFAULT 'offen' CHECK (status IN ('offen', 'bezahlt', 'storniert', 'gemahnt')),
  bezahlt_am TIMESTAMPTZ,
  faellig_am DATE,
  notizen TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_rechnungen_kunde ON admin_rechnungen(kunde_profil_id);
CREATE INDEX IF NOT EXISTS idx_admin_rechnungen_status ON admin_rechnungen(status);

ALTER TABLE admin_rechnungen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_rechnungen_select" ON admin_rechnungen
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_rechnungen_insert" ON admin_rechnungen
  FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "admin_rechnungen_update" ON admin_rechnungen
  FOR UPDATE USING (is_admin());
CREATE POLICY "admin_rechnungen_delete" ON admin_rechnungen
  FOR DELETE USING (is_admin());

CREATE TRIGGER update_admin_rechnungen_updated_at
  BEFORE UPDATE ON admin_rechnungen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 4. Datenmigrationen (Tracking pro Kunde)
CREATE TABLE IF NOT EXISTS admin_datenmigrationen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kunde_profil_id UUID NOT NULL REFERENCES admin_kundenprofile(id) ON DELETE CASCADE,
  typ TEXT NOT NULL CHECK (typ IN ('excel', 'papier', 'datenbank', 'andere')),
  quell_beschreibung TEXT,
  module TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'geplant' CHECK (status IN ('geplant', 'in_bearbeitung', 'abgeschlossen', 'fehler')),
  fortschritt INT DEFAULT 0 CHECK (fortschritt >= 0 AND fortschritt <= 100),
  ergebnis_zusammenfassung TEXT,
  notizen TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_datenmigrationen_kunde ON admin_datenmigrationen(kunde_profil_id);

ALTER TABLE admin_datenmigrationen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_datenmigrationen_select" ON admin_datenmigrationen
  FOR SELECT USING (is_admin());
CREATE POLICY "admin_datenmigrationen_insert" ON admin_datenmigrationen
  FOR INSERT WITH CHECK (is_admin());
CREATE POLICY "admin_datenmigrationen_update" ON admin_datenmigrationen
  FOR UPDATE USING (is_admin());
CREATE POLICY "admin_datenmigrationen_delete" ON admin_datenmigrationen
  FOR DELETE USING (is_admin());

CREATE TRIGGER update_admin_datenmigrationen_updated_at
  BEFORE UPDATE ON admin_datenmigrationen
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5. Admin-Users RLS (Admins können sich selbst sehen)
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_users_select" ON admin_users
  FOR SELECT USING (is_admin());

-- 6. Aggregations-Funktion: Nutzungsstatistiken pro Kunde
-- Gibt Kennzahlen für einen bestimmten User zurück
CREATE OR REPLACE FUNCTION get_kunde_stats(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT is_admin() THEN
    RETURN '{}'::JSON;
  END IF;

  SELECT json_build_object(
    'kunden_count', (SELECT COUNT(*) FROM kunden WHERE user_id = p_user_id AND is_deleted = false),
    'offerten_count', (SELECT COUNT(*) FROM offerten WHERE user_id = p_user_id AND is_deleted = false),
    'auftraege_count', (SELECT COUNT(*) FROM auftraege WHERE user_id = p_user_id AND is_deleted = false),
    'rechnungen_count', (SELECT COUNT(*) FROM rechnungen WHERE user_id = p_user_id),
    'artikel_count', (SELECT COUNT(*) FROM artikel WHERE user_id = p_user_id AND is_deleted = false),
    'buchungen_count', (SELECT COUNT(*) FROM buchungen WHERE user_id = p_user_id),
    'offene_offerten', (SELECT COUNT(*) FROM offerten WHERE user_id = p_user_id AND status = 'offen' AND is_deleted = false),
    'aktive_auftraege', (SELECT COUNT(*) FROM auftraege WHERE user_id = p_user_id AND status = 'in_bearbeitung' AND is_deleted = false),
    'offene_rechnungen_betrag', COALESCE((SELECT SUM(total_brutto) FROM rechnungen WHERE user_id = p_user_id AND status IN ('entwurf', 'gesendet', 'gemahnt')), 0)
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Dashboard-Aggregation: Gesamtübersicht
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  IF NOT is_admin() THEN
    RETURN '{}'::JSON;
  END IF;

  SELECT json_build_object(
    'total_kunden', (SELECT COUNT(*) FROM admin_kundenprofile),
    'aktive_kunden', (SELECT COUNT(*) FROM admin_kundenprofile WHERE status = 'aktiv'),
    'inaktive_kunden', (SELECT COUNT(*) FROM admin_kundenprofile WHERE status = 'inaktiv'),
    'gesperrte_kunden', (SELECT COUNT(*) FROM admin_kundenprofile WHERE status = 'gesperrt'),
    'test_kunden', (SELECT COUNT(*) FROM admin_kundenprofile WHERE status = 'test'),
    'offene_rechnungen_count', (SELECT COUNT(*) FROM admin_rechnungen WHERE status = 'offen'),
    'offene_rechnungen_betrag', COALESCE((SELECT SUM(total) FROM admin_rechnungen WHERE status = 'offen'), 0),
    'gemahnete_rechnungen_count', (SELECT COUNT(*) FROM admin_rechnungen WHERE status = 'gemahnt'),
    'bezahlte_rechnungen_monat', COALESCE((SELECT SUM(total) FROM admin_rechnungen WHERE status = 'bezahlt' AND bezahlt_am >= date_trunc('month', now())), 0),
    'migrationen_geplant', (SELECT COUNT(*) FROM admin_datenmigrationen WHERE status = 'geplant'),
    'migrationen_aktiv', (SELECT COUNT(*) FROM admin_datenmigrationen WHERE status = 'in_bearbeitung'),
    'plan_free', (SELECT COUNT(*) FROM user_subscriptions us JOIN admin_kundenprofile ak ON us.user_id = ak.user_id WHERE us.plan_id = 'free'),
    'plan_standard', (SELECT COUNT(*) FROM user_subscriptions us JOIN admin_kundenprofile ak ON us.user_id = ak.user_id WHERE us.plan_id = 'standard'),
    'plan_premium', (SELECT COUNT(*) FROM user_subscriptions us JOIN admin_kundenprofile ak ON us.user_id = ak.user_id WHERE us.plan_id = 'premium')
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Admin-Zugriff auf user_subscriptions erlauben (für Plan-Verwaltung)
-- Admins sollen user_subscriptions aller User lesen und ändern können
CREATE POLICY "admin_user_subscriptions_select" ON user_subscriptions
  FOR SELECT USING (auth.uid() = user_id OR is_admin());
CREATE POLICY "admin_user_subscriptions_update" ON user_subscriptions
  FOR UPDATE USING (is_admin());
CREATE POLICY "admin_user_subscriptions_insert" ON user_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id OR is_admin());

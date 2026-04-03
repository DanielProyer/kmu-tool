-- Migration 021: Auto-Website Modul
-- ==================================

-- 1. Website-Konfiguration (1 pro User)
CREATE TABLE IF NOT EXISTS website_configs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  slug TEXT NOT NULL,
  firmen_name TEXT NOT NULL,
  untertitel TEXT,
  logo_path TEXT,
  primaerfarbe TEXT DEFAULT '#2563EB',
  sekundaerfarbe TEXT DEFAULT '#1E40AF',
  schriftart TEXT DEFAULT 'Inter' CHECK (schriftart IN ('Inter','Merriweather','Nunito','Roboto Slab','Source Sans 3')),
  design_template TEXT DEFAULT 'modern' CHECK (design_template IN ('modern','klassisch','handwerk')),
  is_published BOOLEAN DEFAULT false,
  kontakt_email TEXT,
  kontakt_telefon TEXT,
  adresse_strasse TEXT,
  adresse_plz TEXT,
  adresse_ort TEXT,
  oeffnungszeiten TEXT,
  social_links JSONB DEFAULT '{}',
  seo_title TEXT,
  seo_description TEXT,
  impressum_uid TEXT,
  datenschutz_text TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(slug),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_website_configs_slug ON website_configs(slug);
CREATE INDEX IF NOT EXISTS idx_website_configs_user ON website_configs(user_id);

ALTER TABLE website_configs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "website_configs_select" ON website_configs
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "website_configs_insert" ON website_configs
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "website_configs_update" ON website_configs
  FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "website_configs_delete" ON website_configs
  FOR DELETE USING (auth.uid() = user_id);

CREATE TRIGGER trg_website_configs_updated
  BEFORE UPDATE ON website_configs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 2. Website-Sektionen
CREATE TABLE IF NOT EXISTS website_sections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID NOT NULL REFERENCES website_configs(id) ON DELETE CASCADE,
  typ TEXT NOT NULL CHECK (typ IN (
    'hero','beschreibung','leistungen','ueber_uns','team',
    'referenzen','kundenstimmen','galerie','faq','kontakt',
    'offertanfrage','notfalldienst'
  )),
  titel TEXT,
  content JSONB DEFAULT '{}',
  sortierung INT DEFAULT 0,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_website_sections_config ON website_sections(config_id, sortierung);

ALTER TABLE website_sections ENABLE ROW LEVEL SECURITY;

CREATE POLICY "website_sections_select" ON website_sections
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_sections_insert" ON website_sections
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_sections_update" ON website_sections
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_sections_delete" ON website_sections
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );

CREATE TRIGGER trg_website_sections_updated
  BEFORE UPDATE ON website_sections
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 3. Galerie-Bilder
CREATE TABLE IF NOT EXISTS website_gallery_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID NOT NULL REFERENCES website_configs(id) ON DELETE CASCADE,
  storage_path TEXT NOT NULL,
  datei_name TEXT,
  beschreibung TEXT,
  sortierung INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_website_gallery_config ON website_gallery_images(config_id, sortierung);

ALTER TABLE website_gallery_images ENABLE ROW LEVEL SECURITY;

CREATE POLICY "website_gallery_select" ON website_gallery_images
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_gallery_insert" ON website_gallery_images
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_gallery_update" ON website_gallery_images
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_gallery_delete" ON website_gallery_images
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );

-- 4. Eingehende Anfragen
CREATE TABLE IF NOT EXISTS website_anfragen (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  config_id UUID NOT NULL REFERENCES website_configs(id) ON DELETE CASCADE,
  typ TEXT DEFAULT 'kontakt' CHECK (typ IN ('kontakt','offerte')),
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  telefon TEXT,
  nachricht TEXT,
  details JSONB DEFAULT '{}',
  gelesen BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_website_anfragen_config ON website_anfragen(config_id, created_at DESC);

ALTER TABLE website_anfragen ENABLE ROW LEVEL SECURITY;

CREATE POLICY "website_anfragen_select" ON website_anfragen
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_anfragen_update" ON website_anfragen
  FOR UPDATE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );
CREATE POLICY "website_anfragen_delete" ON website_anfragen
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM website_configs WHERE id = config_id AND user_id = auth.uid())
  );

-- Kein INSERT-Policy fuer website_anfragen: Edge Function nutzt service_role_key

-- Migration 027: Buchungs-Belege (Spesen-Scanner)
-- Neue Tabelle: buchungs_belege (Beleg-Anhänge zu Buchungen)
-- Storage Bucket: buchungs-belege (privat, max 10MB, PDF/JPEG/PNG)

-- ============================================================================
-- 1. BUCHUNGS_BELEGE TABELLE
-- ============================================================================
CREATE TABLE IF NOT EXISTS buchungs_belege (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  buchung_id UUID NOT NULL REFERENCES buchungen(id) ON DELETE CASCADE,
  dateiname TEXT NOT NULL,
  dateityp TEXT NOT NULL CHECK (dateityp IN ('image/jpeg', 'image/png', 'application/pdf')),
  storage_pfad TEXT NOT NULL,
  beleg_quelle TEXT NOT NULL DEFAULT 'manuell' CHECK (beleg_quelle IN ('manuell', 'spesen_scan', 'rechnung')),
  beschreibung TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE buchungs_belege ENABLE ROW LEVEL SECURITY;

-- RLS: Betrieb-basiert (GF sieht alles, MA sieht eigene Betrieb-Daten)
CREATE POLICY "buchungs_belege_select" ON buchungs_belege
  FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_belege_insert" ON buchungs_belege
  FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_belege_update" ON buchungs_belege
  FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "buchungs_belege_delete" ON buchungs_belege
  FOR DELETE USING (user_id = get_betrieb_owner_id());

CREATE TRIGGER update_buchungs_belege_updated_at
  BEFORE UPDATE ON buchungs_belege
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE INDEX IF NOT EXISTS idx_buchungs_belege_user_id ON buchungs_belege(user_id);
CREATE INDEX IF NOT EXISTS idx_buchungs_belege_buchung_id ON buchungs_belege(buchung_id);

-- ============================================================================
-- 2. STORAGE BUCKET
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'buchungs-belege',
  'buchungs-belege',
  false,
  10485760, -- 10 MB
  ARRAY['image/jpeg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: Betrieb-Owner-basiert
-- Pfad-Format: {owner_user_id}/{buchung_id}/{timestamp}_{filename}
CREATE POLICY "buchungs_belege_storage_select" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'buchungs-belege'
    AND (storage.foldername(name))[1] = get_betrieb_owner_id()::text
  );

CREATE POLICY "buchungs_belege_storage_insert" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'buchungs-belege'
    AND (storage.foldername(name))[1] = get_betrieb_owner_id()::text
  );

CREATE POLICY "buchungs_belege_storage_delete" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'buchungs-belege'
    AND (storage.foldername(name))[1] = get_betrieb_owner_id()::text
  );

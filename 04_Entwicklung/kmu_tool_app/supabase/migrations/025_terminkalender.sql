-- Migration 025: Terminkalender
CREATE TABLE IF NOT EXISTS termine (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  titel TEXT NOT NULL,
  beschreibung TEXT,
  datum DATE NOT NULL,
  start_zeit TIME,
  end_zeit TIME,
  ganztaegig BOOLEAN DEFAULT false,
  ort TEXT,
  kunde_id UUID REFERENCES kunden(id) ON DELETE SET NULL,
  auftrag_id UUID REFERENCES auftraege(id) ON DELETE SET NULL,
  typ TEXT DEFAULT 'termin' CHECK (typ IN ('termin','auftrag','service','erinnerung')),
  status TEXT DEFAULT 'geplant' CHECK (status IN ('geplant','bestaetigt','erledigt','abgesagt')),
  farbe TEXT,
  is_deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- RLS (using get_betrieb_owner_id() for multi-user betrieb support)
ALTER TABLE termine ENABLE ROW LEVEL SECURITY;

CREATE POLICY "termine_select" ON termine FOR SELECT USING (user_id = get_betrieb_owner_id());
CREATE POLICY "termine_insert" ON termine FOR INSERT WITH CHECK (user_id = get_betrieb_owner_id());
CREATE POLICY "termine_update" ON termine FOR UPDATE USING (user_id = get_betrieb_owner_id());
CREATE POLICY "termine_delete" ON termine FOR DELETE USING (user_id = get_betrieb_owner_id());

-- Trigger for updated_at
CREATE TRIGGER update_termine_updated_at
  BEFORE UPDATE ON termine
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Indexes
CREATE INDEX IF NOT EXISTS idx_termine_user_id ON termine(user_id);
CREATE INDEX IF NOT EXISTS idx_termine_datum ON termine(datum);
CREATE INDEX IF NOT EXISTS idx_termine_kunde_id ON termine(kunde_id);
CREATE INDEX IF NOT EXISTS idx_termine_auftrag_id ON termine(auftrag_id);

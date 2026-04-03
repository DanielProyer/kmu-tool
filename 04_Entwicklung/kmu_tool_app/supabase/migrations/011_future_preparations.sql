-- ============================================================
-- 011: Vorbereitungen für Bank & Lohn (Tabellen-Skelette)
-- ============================================================

-- Bank-Konten (für camt-Import)
CREATE TABLE IF NOT EXISTS bank_konten (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  bezeichnung TEXT NOT NULL,
  iban TEXT,
  bank_name TEXT,
  konto_nummer INTEGER,  -- Kontonummer aus Kontenrahmen (kein FK wegen composite unique)
  aktiv BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Mitarbeiter (für Lohnbuchhaltung)
CREATE TABLE IF NOT EXISTS mitarbeiter (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vorname TEXT NOT NULL,
  nachname TEXT NOT NULL,
  ahv_nummer TEXT,
  geburtsdatum DATE,
  eintrittsdatum DATE,
  austrittsdatum DATE,
  pensum_prozent INTEGER DEFAULT 100,
  bruttolohn_monatlich NUMERIC(10,2),
  aktiv BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- RLS
ALTER TABLE bank_konten ENABLE ROW LEVEL SECURITY;
ALTER TABLE mitarbeiter ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bank_konten_own" ON bank_konten
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "mitarbeiter_own" ON mitarbeiter
  FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Updated-at Triggers
CREATE OR REPLACE FUNCTION update_bank_konten_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bank_konten_updated_at
  BEFORE UPDATE ON bank_konten
  FOR EACH ROW
  EXECUTE FUNCTION update_bank_konten_updated_at();

CREATE OR REPLACE FUNCTION update_mitarbeiter_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_mitarbeiter_updated_at
  BEFORE UPDATE ON mitarbeiter
  FOR EACH ROW
  EXECUTE FUNCTION update_mitarbeiter_updated_at();

-- Indizes
CREATE INDEX IF NOT EXISTS idx_bank_konten_user ON bank_konten(user_id);
CREATE INDEX IF NOT EXISTS idx_mitarbeiter_user ON mitarbeiter(user_id);

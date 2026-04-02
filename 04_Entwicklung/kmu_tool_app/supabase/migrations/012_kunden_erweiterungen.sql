-- ============================================================
-- 012: Kunden & Kontakte Erweiterungen
-- Rechnungsadresse, Rechnungsstellung, Kontakt-Anrede/Notiz/Rolle
-- ============================================================

-- ─── Kunden: Rechnungsadresse + Rechnungsstellung ───
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_abweichend BOOLEAN DEFAULT false;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_firma TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_vorname TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_nachname TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_strasse TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_plz TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_ort TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_email TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS rechnungsstellung TEXT DEFAULT 'email'
  CHECK (rechnungsstellung IN ('email', 'post', 'bar', 'abgabe_vor_ort'));

COMMENT ON COLUMN kunden.re_abweichend IS 'true wenn Rechnungsadresse von Hauptadresse abweicht';
COMMENT ON COLUMN kunden.rechnungsstellung IS 'Art der Rechnungsstellung: email, post, bar, abgabe_vor_ort';

-- ─── Kontakte: Anrede (Sie/Du), Rolle (Dropdown), Notiz ───
ALTER TABLE kunden_kontakte ADD COLUMN IF NOT EXISTS anrede TEXT DEFAULT 'sie'
  CHECK (anrede IN ('sie', 'du'));
ALTER TABLE kunden_kontakte ADD COLUMN IF NOT EXISTS rolle TEXT DEFAULT 'mitarbeiter'
  CHECK (rolle IN ('geschaeftsfuehrer', 'inhaber', 'bauleiter', 'projektleiter', 'buchhaltung', 'sekretariat', 'mitarbeiter', 'lehrling', 'sonstige'));
ALTER TABLE kunden_kontakte ADD COLUMN IF NOT EXISTS notizen TEXT;

COMMENT ON COLUMN kunden_kontakte.anrede IS 'Bevorzugte Anrede: sie oder du';
COMMENT ON COLUMN kunden_kontakte.rolle IS 'Rolle im Betrieb';

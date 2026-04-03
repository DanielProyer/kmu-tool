-- Migration 024: Periodische Aufträge
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS auftrag_typ TEXT DEFAULT 'einmalig'
  CHECK (auftrag_typ IN ('einmalig', 'periodisch'));
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS intervall TEXT
  CHECK (intervall IN ('woechentlich','monatlich','quartalsweise','halbjaehrlich','jaehrlich'));
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS naechste_ausfuehrung DATE;
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS vorlauf_tage INT DEFAULT 7;
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS periodisch_bezeichnung TEXT;
ALTER TABLE auftraege ADD COLUMN IF NOT EXISTS parent_auftrag_id UUID REFERENCES auftraege(id);

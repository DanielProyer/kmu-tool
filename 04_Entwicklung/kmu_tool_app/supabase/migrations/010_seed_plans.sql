-- ============================================================
-- 010: Seed Subscription Plans
-- ============================================================

INSERT INTO subscription_plans (id, bezeichnung, preis_monatlich, features, sort_order) VALUES
  ('free', 'Gratis', 0.00, '{
    "kunden": true,
    "offerten": true,
    "auftraege": true,
    "zeiterfassung": true,
    "rapporte": true,
    "rechnungen": false,
    "buchhaltung": false,
    "auftrag_dashboard": false,
    "auto_website": false,
    "max_kunden": 20,
    "max_offerten": 10
  }'::jsonb, 1),

  ('standard', 'Standard', 29.00, '{
    "kunden": true,
    "offerten": true,
    "auftraege": true,
    "zeiterfassung": true,
    "rapporte": true,
    "rechnungen": true,
    "buchhaltung": true,
    "auftrag_dashboard": false,
    "auto_website": false,
    "max_kunden": -1,
    "max_offerten": -1
  }'::jsonb, 2),

  ('premium', 'Premium', 49.00, '{
    "kunden": true,
    "offerten": true,
    "auftraege": true,
    "zeiterfassung": true,
    "rapporte": true,
    "rechnungen": true,
    "buchhaltung": true,
    "auftrag_dashboard": true,
    "auto_website": true,
    "max_kunden": -1,
    "max_offerten": -1
  }'::jsonb, 3)
ON CONFLICT (id) DO UPDATE SET
  bezeichnung = EXCLUDED.bezeichnung,
  preis_monatlich = EXCLUDED.preis_monatlich,
  features = EXCLUDED.features,
  sort_order = EXCLUDED.sort_order;

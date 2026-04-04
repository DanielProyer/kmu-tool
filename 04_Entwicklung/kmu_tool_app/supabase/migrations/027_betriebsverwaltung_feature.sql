-- Migration 027: betriebsverwaltung Feature zu allen Abo-Plaenen hinzufuegen
-- Damit die Betriebsverwaltung-Kachel auf dem Dashboard sichtbar ist

UPDATE subscription_plans
SET features = features || '{"betriebsverwaltung": true}'::jsonb
WHERE id IN ('free', 'standard', 'premium')
  AND NOT (features ? 'betriebsverwaltung');

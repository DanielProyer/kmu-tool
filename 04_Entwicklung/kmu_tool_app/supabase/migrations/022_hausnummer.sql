-- Migration 022: Hausnummer-Feld auf relevanten Tabellen
-- Trennung von Strasse und Hausnummer für korrekte Adressierung

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS hausnummer TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS hausnummer TEXT;
ALTER TABLE kunden ADD COLUMN IF NOT EXISTS re_hausnummer TEXT;
ALTER TABLE lieferanten ADD COLUMN IF NOT EXISTS hausnummer TEXT;
ALTER TABLE admin_kundenprofile ADD COLUMN IF NOT EXISTS hausnummer TEXT;
ALTER TABLE website_configs ADD COLUMN IF NOT EXISTS adresse_hausnummer TEXT;

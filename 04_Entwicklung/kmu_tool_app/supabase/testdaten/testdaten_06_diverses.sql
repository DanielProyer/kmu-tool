-- ============================================================================
-- KMU Tool - Testdaten 06: Diverses
-- Termine, Bestellungen, Inventuren, Website, Lagerbewegungen, Bankverbindungen
-- ============================================================================
-- Abhaengigkeit: testdaten_01-05 muessen zuerst ausgefuehrt werden
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_kunde_ids UUID[];
  v_auftrag_ids UUID[];
  v_lagerort_haupt UUID;
  v_lagerort_sf1 UUID;
  v_lagerort_sf2 UUID;
  v_lagerort_bau UUID;
  v_lieferant_ids UUID[];
  v_artikel_ids UUID[];
  v_website_config_id UUID;
  v_bestellung_id UUID;
  v_inventur_id UUID;
  v_datum DATE;
  i INTEGER;
  j INTEGER;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  -- IDs laden
  SELECT array_agg(id ORDER BY created_at) INTO v_kunde_ids FROM kunden WHERE user_id = v_user_id AND is_deleted = false;
  SELECT array_agg(id ORDER BY created_at) INTO v_auftrag_ids FROM auftraege WHERE user_id = v_user_id AND is_deleted = false;
  SELECT array_agg(id ORDER BY firma) INTO v_lieferant_ids FROM lieferanten WHERE user_id = v_user_id AND is_deleted = false;
  SELECT array_agg(id ORDER BY artikel_nr) INTO v_artikel_ids FROM artikel WHERE user_id = v_user_id AND is_deleted = false AND kategorie = 'material';

  SELECT id INTO v_lagerort_haupt FROM lagerorte WHERE user_id = v_user_id AND typ = 'lager' LIMIT 1;
  SELECT id INTO v_lagerort_sf1 FROM lagerorte WHERE user_id = v_user_id AND bezeichnung LIKE '%234 567%';
  SELECT id INTO v_lagerort_sf2 FROM lagerorte WHERE user_id = v_user_id AND bezeichnung LIKE '%345 678%';
  SELECT id INTO v_lagerort_bau FROM lagerorte WHERE user_id = v_user_id AND typ = 'baustelle' LIMIT 1;

  -- ========================================================================
  -- 1. BANKVERBINDUNGEN (2 Stueck)
  -- ========================================================================
  DELETE FROM bankverbindungen WHERE user_id = v_user_id;

  INSERT INTO bankverbindungen (user_id, bezeichnung, iban, bank_name, bic, ist_hauptkonto, is_deleted) VALUES
    (v_user_id, 'ZKB Geschaeftskonto', 'CH9300762011623852957', 'Zuercher Kantonalbank', 'ZKBKCHZZ80A', true, false),
    (v_user_id, 'PostFinance', 'CH2109000000250198877', 'PostFinance AG', 'POFICHBEXXX', false, false);

  -- ========================================================================
  -- 2. TERMINE (~80 Stueck)
  -- ========================================================================
  DELETE FROM termine WHERE user_id = v_user_id;

  -- 2024: ~25 Termine
  FOR i IN 1..25 LOOP
    v_datum := '2024-01-15'::date + (random() * 340)::int;
    INSERT INTO termine (user_id, titel, beschreibung, datum, start_zeit, end_zeit, ganztaegig, ort, kunde_id, auftrag_id, typ, status, is_deleted)
    VALUES (v_user_id,
      CASE (random() * 9)::int
        WHEN 0 THEN 'Besichtigung vor Ort'
        WHEN 1 THEN 'Kundenbesprechung'
        WHEN 2 THEN 'Offertbesprechung'
        WHEN 3 THEN 'Baustellenbegehung'
        WHEN 4 THEN 'Abnahme Sanitaeranlage'
        WHEN 5 THEN 'Material abholen'
        WHEN 6 THEN 'Wartungstermin'
        WHEN 7 THEN 'Planung Bad-Renovation'
        WHEN 8 THEN 'Notfall-Einsatz'
        ELSE 'Besprechung intern'
      END,
      'Automatisch generierter Testtermin',
      v_datum,
      (ARRAY['08:00','09:00','10:00','13:00','14:00'])[1 + (random() * 4)::int]::time,
      (ARRAY['10:00','11:00','12:00','15:00','17:00'])[1 + (random() * 4)::int]::time,
      false,
      CASE (random() * 4)::int WHEN 0 THEN 'Buero' WHEN 1 THEN 'Baustelle' WHEN 2 THEN 'Beim Kunden' ELSE NULL END,
      CASE WHEN random() < 0.7 THEN v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int] ELSE NULL END,
      CASE WHEN random() < 0.4 THEN v_auftrag_ids[1 + (random() * (array_length(v_auftrag_ids, 1) - 1))::int] ELSE NULL END,
      (ARRAY['termin','auftrag','service','erinnerung'])[1 + (random() * 3)::int],
      'erledigt',
      false);
  END LOOP;

  -- 2025: ~30 Termine
  FOR i IN 1..30 LOOP
    v_datum := '2025-01-10'::date + (random() * 345)::int;
    INSERT INTO termine (user_id, titel, beschreibung, datum, start_zeit, end_zeit, ganztaegig, ort, kunde_id, auftrag_id, typ, status, is_deleted)
    VALUES (v_user_id,
      CASE (random() * 9)::int
        WHEN 0 THEN 'Besichtigung vor Ort'
        WHEN 1 THEN 'Kundenbesprechung'
        WHEN 2 THEN 'Offertbesprechung'
        WHEN 3 THEN 'Baustellenbegehung'
        WHEN 4 THEN 'Abnahme Sanitaeranlage'
        WHEN 5 THEN 'Material abholen Tobler'
        WHEN 6 THEN 'Wartungstermin'
        WHEN 7 THEN 'Planung Heizungsersatz'
        WHEN 8 THEN 'SUVA Kontrolle'
        ELSE 'Teambesprechung'
      END,
      'Automatisch generierter Testtermin',
      v_datum,
      (ARRAY['07:30','08:00','09:00','10:00','13:00','14:00'])[1 + (random() * 5)::int]::time,
      (ARRAY['10:00','11:30','12:00','15:00','16:30','17:00'])[1 + (random() * 5)::int]::time,
      false,
      CASE (random() * 4)::int WHEN 0 THEN 'Buero' WHEN 1 THEN 'Baustelle' WHEN 2 THEN 'Beim Kunden' ELSE NULL END,
      CASE WHEN random() < 0.7 THEN v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int] ELSE NULL END,
      CASE WHEN random() < 0.4 THEN v_auftrag_ids[1 + (random() * (array_length(v_auftrag_ids, 1) - 1))::int] ELSE NULL END,
      (ARRAY['termin','auftrag','service','erinnerung'])[1 + (random() * 3)::int],
      CASE WHEN v_datum < CURRENT_DATE THEN 'erledigt' ELSE 'bestaetigt' END,
      false);
  END LOOP;

  -- 2026: ~25 Termine (bis April)
  FOR i IN 1..25 LOOP
    v_datum := '2026-01-05'::date + (random() * 90)::int;
    INSERT INTO termine (user_id, titel, beschreibung, datum, start_zeit, end_zeit, ganztaegig, ort, kunde_id, auftrag_id, typ, status, is_deleted)
    VALUES (v_user_id,
      CASE (random() * 11)::int
        WHEN 0 THEN 'Besichtigung vor Ort'
        WHEN 1 THEN 'Kundenbesprechung'
        WHEN 2 THEN 'Offertbesprechung'
        WHEN 3 THEN 'Baustellenbegehung'
        WHEN 4 THEN 'Abnahme Bad-Renovation'
        WHEN 5 THEN 'Material abholen Pestalozzi'
        WHEN 6 THEN 'Fahrzeug-Service VW'
        WHEN 7 THEN 'Planung Neubau Sanitaer'
        WHEN 8 THEN 'MWST-Abrechnung vorbereiten'
        WHEN 9 THEN 'Teammeeting Montag'
        WHEN 10 THEN 'Lieferantengespraech Geberit'
        ELSE 'Inventur vorbereiten'
      END,
      'Automatisch generierter Testtermin',
      v_datum,
      (ARRAY['07:30','08:00','09:00','10:00','13:00','14:00'])[1 + (random() * 5)::int]::time,
      (ARRAY['10:00','11:30','12:00','15:00','16:30','17:00'])[1 + (random() * 5)::int]::time,
      CASE WHEN random() < 0.1 THEN true ELSE false END,
      CASE (random() * 4)::int WHEN 0 THEN 'Buero' WHEN 1 THEN 'Baustelle' WHEN 2 THEN 'Beim Kunden' ELSE NULL END,
      CASE WHEN random() < 0.6 THEN v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int] ELSE NULL END,
      CASE WHEN random() < 0.3 THEN v_auftrag_ids[1 + (random() * (array_length(v_auftrag_ids, 1) - 1))::int] ELSE NULL END,
      (ARRAY['termin','auftrag','service','erinnerung'])[1 + (random() * 3)::int],
      CASE WHEN v_datum < CURRENT_DATE THEN 'erledigt' WHEN v_datum < CURRENT_DATE + 14 THEN 'bestaetigt' ELSE 'geplant' END,
      false);
  END LOOP;

  -- Spezielle Termine: Service-Erinnerungen
  INSERT INTO termine (user_id, titel, beschreibung, datum, ganztaegig, typ, status, is_deleted) VALUES
    (v_user_id, 'MWST H1/2026 vorbereiten', 'MWST-Abrechnung fuer 1. Halbjahr 2026 einreichen', '2026-07-15', true, 'erinnerung', 'geplant', false),
    (v_user_id, 'Fahrzeug-Service Lieferwagen', 'Renault Master, naechster Service faellig', '2026-05-01', true, 'service', 'geplant', false),
    (v_user_id, 'MFK VW Transporter', 'Servicefahrzeug 1, MFK faellig 15.09.2026', '2026-09-10', true, 'service', 'geplant', false),
    (v_user_id, 'Jahresabschluss 2025 Treuhand', 'Unterlagen fuer Jahresabschluss zusammenstellen', '2026-03-15', true, 'erinnerung', 'erledigt', false);

  RAISE NOTICE 'Termine angelegt: %', (SELECT COUNT(*) FROM termine WHERE user_id = v_user_id);

  -- ========================================================================
  -- 3. BESTELLUNGEN (~30 Stueck)
  -- ========================================================================
  DELETE FROM bestellpositionen WHERE bestellung_id IN (SELECT id FROM bestellungen WHERE user_id = v_user_id);
  DELETE FROM bestellungen WHERE user_id = v_user_id;

  FOR i IN 1..30 LOOP
    v_bestellung_id := gen_random_uuid();

    -- Datum und Status
    IF i <= 12 THEN
      v_datum := '2024-01-15'::date + (random() * 340)::int;
      INSERT INTO bestellungen (id, user_id, lieferant_id, bestell_nr, status, bestell_datum, erwartetes_lieferdatum, liefer_datum, total_betrag, is_deleted)
      VALUES (v_bestellung_id, v_user_id,
              v_lieferant_ids[1 + (random() * (array_length(v_lieferant_ids, 1) - 1))::int],
              'BST-' || (1000 + i), 'geliefert', v_datum, v_datum + 7, v_datum + (5 + random() * 5)::int, 0, false);
    ELSIF i <= 22 THEN
      v_datum := '2025-01-10'::date + (random() * 345)::int;
      INSERT INTO bestellungen (id, user_id, lieferant_id, bestell_nr, status, bestell_datum, erwartetes_lieferdatum, liefer_datum, total_betrag, is_deleted)
      VALUES (v_bestellung_id, v_user_id,
              v_lieferant_ids[1 + (random() * (array_length(v_lieferant_ids, 1) - 1))::int],
              'BST-' || (1000 + i),
              CASE WHEN random() < 0.7 THEN 'geliefert' WHEN random() < 0.9 THEN 'teilgeliefert' ELSE 'bestellt' END,
              v_datum, v_datum + 7,
              CASE WHEN random() < 0.7 THEN v_datum + (5 + random() * 5)::int ELSE NULL END,
              0, false);
    ELSE
      v_datum := '2026-01-05'::date + (random() * 85)::int;
      INSERT INTO bestellungen (id, user_id, lieferant_id, bestell_nr, status, bestell_datum, erwartetes_lieferdatum, total_betrag, is_deleted)
      VALUES (v_bestellung_id, v_user_id,
              v_lieferant_ids[1 + (random() * (array_length(v_lieferant_ids, 1) - 1))::int],
              'BST-' || (1000 + i),
              CASE WHEN random() < 0.3 THEN 'geliefert' WHEN random() < 0.6 THEN 'bestellt' ELSE 'entwurf' END,
              v_datum, v_datum + 7, 0, false);
    END IF;

    -- 2-5 Positionen pro Bestellung
    FOR j IN 1..(2 + (random() * 3)::int) LOOP
      DECLARE
        v_art_id UUID;
        v_menge NUMERIC(12,3);
        v_preis NUMERIC(12,2);
        v_gelief NUMERIC(12,3);
        v_bst_status TEXT;
      BEGIN
        v_art_id := v_artikel_ids[1 + (random() * (array_length(v_artikel_ids, 1) - 1))::int];
        v_menge := (5 + random() * 45)::numeric(12,0);
        v_preis := (SELECT einkaufspreis FROM artikel WHERE id = v_art_id);

        SELECT status INTO v_bst_status FROM bestellungen WHERE id = v_bestellung_id;
        IF v_bst_status = 'geliefert' THEN v_gelief := v_menge;
        ELSIF v_bst_status = 'teilgeliefert' THEN v_gelief := (v_menge * (0.3 + random() * 0.5))::numeric(12,0);
        ELSE v_gelief := 0;
        END IF;

        INSERT INTO bestellpositionen (user_id, bestellung_id, artikel_id, menge, einzelpreis, gelieferte_menge)
        VALUES (v_user_id, v_bestellung_id, v_art_id, v_menge, v_preis, v_gelief);
      END;
    END LOOP;

    -- Total aktualisieren
    UPDATE bestellungen SET total_betrag = (
      SELECT COALESCE(SUM(menge * einzelpreis), 0) FROM bestellpositionen WHERE bestellung_id = v_bestellung_id
    ) WHERE id = v_bestellung_id;
  END LOOP;

  RAISE NOTICE 'Bestellungen angelegt: %', (SELECT COUNT(*) FROM bestellungen WHERE user_id = v_user_id);

  -- ========================================================================
  -- 4. LAGERBEWEGUNGEN (~200 Stueck)
  -- ========================================================================
  DELETE FROM lagerbewegungen WHERE user_id = v_user_id;

  -- Wareneingaenge (aus Bestellungen) - ~80
  FOR i IN 1..80 LOOP
    v_datum := '2024-01-20'::date + (random() * 810)::int;
    IF v_datum > CURRENT_DATE THEN v_datum := CURRENT_DATE - (random() * 30)::int; END IF;

    INSERT INTO lagerbewegungen (user_id, artikel_id, lagerort_id, bewegungstyp, menge, referenz_typ, bemerkung, created_at)
    VALUES (v_user_id,
            v_artikel_ids[1 + (random() * (array_length(v_artikel_ids, 1) - 1))::int],
            v_lagerort_haupt,
            'eingang',
            (5 + random() * 30)::numeric(12,0),
            'bestellung',
            'Wareneingang Lieferant',
            v_datum::timestamptz);
  END LOOP;

  -- Materialausgaben (fuer Auftraege) - ~80
  FOR i IN 1..80 LOOP
    v_datum := '2024-02-01'::date + (random() * 800)::int;
    IF v_datum > CURRENT_DATE THEN v_datum := CURRENT_DATE - (random() * 30)::int; END IF;

    INSERT INTO lagerbewegungen (user_id, artikel_id, lagerort_id, bewegungstyp, menge, referenz_typ, bemerkung, created_at)
    VALUES (v_user_id,
            v_artikel_ids[1 + (random() * (array_length(v_artikel_ids, 1) - 1))::int],
            CASE WHEN random() < 0.6 THEN v_lagerort_haupt WHEN random() < 0.8 THEN v_lagerort_sf1 ELSE v_lagerort_sf2 END,
            'ausgang',
            (1 + random() * 10)::numeric(12,0),
            'auftrag',
            'Material fuer Auftrag',
            v_datum::timestamptz);
  END LOOP;

  -- Umlagerungen (Lager -> Fahrzeug) - ~30
  FOR i IN 1..30 LOOP
    v_datum := '2024-03-01'::date + (random() * 780)::int;
    IF v_datum > CURRENT_DATE THEN v_datum := CURRENT_DATE - (random() * 30)::int; END IF;

    INSERT INTO lagerbewegungen (user_id, artikel_id, lagerort_id, ziel_lagerort_id, bewegungstyp, menge, bemerkung, created_at)
    VALUES (v_user_id,
            v_artikel_ids[1 + (random() * (array_length(v_artikel_ids, 1) - 1))::int],
            v_lagerort_haupt,
            CASE WHEN random() < 0.5 THEN v_lagerort_sf1 ELSE v_lagerort_sf2 END,
            'umlagerung',
            (2 + random() * 8)::numeric(12,0),
            'Nachfuellung Servicefahrzeug',
            v_datum::timestamptz);
  END LOOP;

  -- Korrekturen - ~10
  FOR i IN 1..10 LOOP
    v_datum := '2024-06-01'::date + (random() * 600)::int;
    IF v_datum > CURRENT_DATE THEN v_datum := CURRENT_DATE - (random() * 30)::int; END IF;

    INSERT INTO lagerbewegungen (user_id, artikel_id, lagerort_id, bewegungstyp, menge, bemerkung, created_at)
    VALUES (v_user_id,
            v_artikel_ids[1 + (random() * (array_length(v_artikel_ids, 1) - 1))::int],
            v_lagerort_haupt,
            'korrektur',
            (-3 + random() * 6)::numeric(12,1),
            'Bestandskorrektur nach Zaehlung',
            v_datum::timestamptz);
  END LOOP;

  RAISE NOTICE 'Lagerbewegungen angelegt: %', (SELECT COUNT(*) FROM lagerbewegungen WHERE user_id = v_user_id);

  -- ========================================================================
  -- 5. INVENTUREN (2 Stueck)
  -- ========================================================================
  DELETE FROM inventur_positionen WHERE inventur_id IN (SELECT id FROM inventuren WHERE user_id = v_user_id);
  DELETE FROM inventuren WHERE user_id = v_user_id;

  -- Inventur 2024
  v_inventur_id := gen_random_uuid();
  INSERT INTO inventuren (id, user_id, bezeichnung, stichtag, lagerort_id, status, bemerkung, is_deleted)
  VALUES (v_inventur_id, v_user_id, 'Jahresinventur 2024', '2024-12-31', v_lagerort_haupt, 'abgeschlossen', 'Komplette Inventur Hauptlager', false);

  -- Positionen fuer Inventur 2024 (alle Material-Artikel im Hauptlager)
  INSERT INTO inventur_positionen (user_id, inventur_id, artikel_id, lagerort_id, soll_bestand, ist_bestand, bewertungspreis, gezaehlt)
  SELECT v_user_id, v_inventur_id, a.id, v_lagerort_haupt,
    COALESCE(lb.menge, 0),
    COALESCE(lb.menge, 0) + (-2 + random() * 4)::numeric(12,1), -- kleine Differenz
    a.einkaufspreis,
    true
  FROM artikel a
  LEFT JOIN lagerbestaende lb ON lb.artikel_id = a.id AND lb.lagerort_id = v_lagerort_haupt
  WHERE a.user_id = v_user_id AND a.kategorie = 'material'
  LIMIT 50;

  -- Inventur 2025
  v_inventur_id := gen_random_uuid();
  INSERT INTO inventuren (id, user_id, bezeichnung, stichtag, lagerort_id, status, bemerkung, is_deleted)
  VALUES (v_inventur_id, v_user_id, 'Jahresinventur 2025', '2025-12-31', v_lagerort_haupt, 'abgeschlossen', 'Komplette Inventur Hauptlager', false);

  INSERT INTO inventur_positionen (user_id, inventur_id, artikel_id, lagerort_id, soll_bestand, ist_bestand, bewertungspreis, gezaehlt)
  SELECT v_user_id, v_inventur_id, a.id, v_lagerort_haupt,
    COALESCE(lb.menge, 0),
    COALESCE(lb.menge, 0) + (-1 + random() * 2)::numeric(12,1),
    a.einkaufspreis,
    true
  FROM artikel a
  LEFT JOIN lagerbestaende lb ON lb.artikel_id = a.id AND lb.lagerort_id = v_lagerort_haupt
  WHERE a.user_id = v_user_id AND a.kategorie = 'material'
  LIMIT 60;

  RAISE NOTICE 'Inventuren angelegt: %', (SELECT COUNT(*) FROM inventuren WHERE user_id = v_user_id);

  -- ========================================================================
  -- 6. WEBSITE-CONFIG
  -- ========================================================================
  DELETE FROM website_sections WHERE config_id IN (SELECT id FROM website_configs WHERE user_id = v_user_id);
  DELETE FROM website_configs WHERE user_id = v_user_id;

  v_website_config_id := gen_random_uuid();
  INSERT INTO website_configs (id, user_id, slug, firmen_name, untertitel, primaerfarbe, sekundaerfarbe, schriftart, design_template, is_published,
    kontakt_email, kontakt_telefon, adresse_strasse, adresse_hausnummer, adresse_plz, adresse_ort,
    oeffnungszeiten, impressum_uid, seo_title, seo_description, is_deleted)
  VALUES (v_website_config_id, v_user_id, 'proyer-sanitaer', 'Proyer Sanitaer GmbH',
    'Ihr Sanitaer-Profi in Zuerich',
    '#1E40AF', '#2563EB', 'Nunito', 'handwerk', true,
    'info@proyer-sanitaer.ch', '+41 44 211 33 44',
    'Bahnhofstrasse', '12', '8001', 'Zuerich',
    'Mo-Fr: 07:00 - 17:00, Sa: 08:00 - 12:00',
    'CHE-123.456.789',
    'Proyer Sanitaer GmbH - Sanitaer Installationen Zuerich',
    'Ihr zuverlaessiger Partner fuer Sanitaer-Installationen, Bad-Renovationen und Heizung in Zuerich und Umgebung.',
    false);

  -- Website Sections
  INSERT INTO website_sections (config_id, typ, titel, content, sortierung, is_visible) VALUES
    (v_website_config_id, 'hero', NULL, '{"headline": "Proyer Sanitaer GmbH", "subline": "Ihr Sanitaer-Profi in Zuerich und Umgebung", "cta_text": "Jetzt Offerte anfragen", "cta_link": "#offertanfrage"}', 1, true),
    (v_website_config_id, 'beschreibung', 'Ueber uns', '{"text": "Seit ueber 10 Jahren sind wir Ihr zuverlaessiger Partner fuer alle Sanitaer-Arbeiten in Zuerich und Umgebung. Unser erfahrenes Team steht Ihnen von der Beratung bis zur Ausfuehrung kompetent zur Seite. Ob Neubau, Renovation oder Notfall - wir sind fuer Sie da."}', 2, true),
    (v_website_config_id, 'leistungen', 'Unsere Leistungen', '{"items": [{"titel": "Bad-Renovationen", "text": "Komplette Badezimmer-Sanierungen von der Planung bis zur Ausfuehrung"}, {"titel": "Sanitaer-Installationen", "text": "Neubau und Umbauten, Leitungssanierungen, Anschluesse"}, {"titel": "Heizung", "text": "Heizkoerper-Ersatz, Fussbodenheizung, Boiler-Service"}, {"titel": "Notfall-Service", "text": "24h Notdienst bei Rohrbruch, Verstopfung und Wasserschaeden"}, {"titel": "Wartung", "text": "Regelmaessige Wartung Ihrer Sanitaeranlagen und Heizung"}, {"titel": "Beratung", "text": "Kompetente Beratung bei Neubauten und Sanierungen"}]}', 3, true),
    (v_website_config_id, 'kontakt', 'Kontakt', '{"text": "Wir freuen uns auf Ihre Anfrage!"}', 4, true),
    (v_website_config_id, 'offertanfrage', 'Offerte anfragen', '{"text": "Beschreiben Sie Ihr Anliegen und wir erstellen Ihnen eine unverbindliche Offerte."}', 5, true);

  RAISE NOTICE 'Website-Config angelegt';

  RAISE NOTICE '=== Testdaten 06 Diverses FERTIG ===';
  RAISE NOTICE '=== ALLE TESTDATEN KOMPLETT ===';
END;
$$;

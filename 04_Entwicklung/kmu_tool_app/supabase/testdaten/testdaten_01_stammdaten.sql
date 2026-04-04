-- ============================================================================
-- KMU Tool - Testdaten 01: Stammdaten
-- Proyer Sanitaer GmbH - Fiktiver Sanitaerbetrieb Zuerich
-- ============================================================================
-- Inhalt: user_profiles, user_subscriptions, mitarbeiter, fahrzeuge,
--         100 kunden, 8 lieferanten
-- ============================================================================
-- AUSFUEHRUNG: supabase db query --linked -f supabase/testdaten/testdaten_01_stammdaten.sql
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
BEGIN
  -- ========================================================================
  -- User-ID ermitteln
  -- ========================================================================
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User dani.proyer@gmail.com nicht gefunden!';
  END IF;

  RAISE NOTICE 'User-ID: %', v_user_id;

  -- ========================================================================
  -- Kontenrahmen + Buchungsvorlagen seeden (falls noch nicht vorhanden)
  -- ========================================================================
  IF NOT EXISTS (SELECT 1 FROM konten WHERE user_id = v_user_id LIMIT 1) THEN
    PERFORM seed_kontenrahmen(v_user_id);
    RAISE NOTICE 'Kontenrahmen angelegt';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM buchungs_vorlagen WHERE user_id = v_user_id LIMIT 1) THEN
    PERFORM seed_buchungsvorlagen(v_user_id);
    RAISE NOTICE 'Buchungsvorlagen angelegt';
  END IF;

  -- ========================================================================
  -- 1. USER_PROFILES aktualisieren
  -- ========================================================================
  UPDATE user_profiles SET
    firma_name = 'Proyer Sanitaer GmbH',
    rechtsform = 'GmbH',
    strasse = 'Bahnhofstrasse',
    hausnummer = '12',
    plz = '8001',
    ort = 'Zuerich',
    telefon = '+41442113344',
    uid_nummer = 'CHE-123.456.789',
    mwst_pflichtig = true,
    mwst_methode = 'effektiv',
    rolle = 'geschaeftsfuehrer',
    updated_at = now()
  WHERE id = v_user_id;

  -- ========================================================================
  -- 2. SUBSCRIPTION: Premium-Abo
  -- ========================================================================
  DELETE FROM user_subscriptions WHERE user_id = v_user_id;
  INSERT INTO user_subscriptions (user_id, plan_id, status, gueltig_ab)
  VALUES (v_user_id, 'premium', 'active', '2024-01-01');

  -- ========================================================================
  -- 3. MWST-Einstellungen
  -- ========================================================================
  INSERT INTO mwst_einstellungen (user_id, methode, abrechnungsperiode, mwst_nummer, mwst_pflichtig_seit, vereinbartes_entgelt)
  VALUES (v_user_id, 'effektiv', 'halbjaehrlich', 'CHE-123.456.789 MWST', '2020-01-01', true)
  ON CONFLICT (user_id) DO UPDATE SET
    methode = 'effektiv',
    abrechnungsperiode = 'halbjaehrlich',
    mwst_nummer = 'CHE-123.456.789 MWST',
    mwst_pflichtig_seit = '2020-01-01',
    vereinbartes_entgelt = true;

  -- ========================================================================
  -- 4. MITARBEITER (3 Stueck)
  -- ========================================================================
  -- Bestehende loeschen
  DELETE FROM mitarbeiter WHERE user_id = v_user_id;

  INSERT INTO mitarbeiter (user_id, vorname, nachname, telefon, email, rolle, strasse, hausnummer, plz, ort, pensum_prozent, bruttolohn_monatlich, bruttolohn_monat, geburtsdatum, eintrittsdatum, anzahl_kinder, anzahl_kinder_ausbildung, is_deleted)
  VALUES
    (v_user_id, 'Marco', 'Brunner', '+41791234567', 'marco.brunner@proyer-sanitaer.ch', 'vorarbeiter', 'Langstrasse', '45', '8004', 'Zuerich', 100, 6200.00, 6200.00, '1985-03-15', '2022-03-01', 2, 0, false),
    (v_user_id, 'Luca', 'Steiner', '+41797654321', 'luca.steiner@proyer-sanitaer.ch', 'geselle', 'Rosengartenstrasse', '18', '8037', 'Zuerich', 100, 5400.00, 5400.00, '1992-07-22', '2023-08-01', 0, 0, false),
    (v_user_id, 'Anna', 'Keller', '+41764321098', 'anna.keller@proyer-sanitaer.ch', 'buero', 'Seestrasse', '112', '8002', 'Zuerich', 60, 4800.00, 4800.00, '1988-11-10', '2024-01-15', 1, 0, false);

  -- ========================================================================
  -- 5. FAHRZEUGE (3 Stueck)
  -- ========================================================================
  DELETE FROM fahrzeuge WHERE user_id = v_user_id;

  INSERT INTO fahrzeuge (user_id, bezeichnung, kennzeichen, marke, modell, jahrgang, naechste_mfk, naechste_service, km_stand, versicherung, aktiv, is_deleted)
  VALUES
    (v_user_id, 'Servicefahrzeug 1', 'ZH 234 567', 'VW', 'Transporter T6.1', 2021, '2026-09-15', '2026-06-01', 67500, 'Zurich Versicherung', true, false),
    (v_user_id, 'Servicefahrzeug 2', 'ZH 345 678', 'Mercedes', 'Vito', 2022, '2027-03-20', '2026-08-15', 42300, 'AXA Winterthur', true, false),
    (v_user_id, 'Lieferwagen', 'ZH 456 789', 'Renault', 'Master', 2019, '2026-11-10', '2026-05-01', 98200, 'Mobiliar', true, false);

  -- ========================================================================
  -- 6. KUNDEN (100 Stueck) - Mix Privat (~60) und Firma (~40)
  -- ========================================================================
  -- Bestehende loeschen
  DELETE FROM kunden WHERE user_id = v_user_id;

  -- Privatkunden (60)
  INSERT INTO kunden (user_id, vorname, nachname, strasse, hausnummer, plz, ort, telefon, email, rechnungsstellung, is_deleted) VALUES
    (v_user_id, 'Thomas', 'Mueller', 'Raemistrasse', '22', '8001', 'Zuerich', '+41443121100', 'thomas.mueller@bluewin.ch', 'email', false),
    (v_user_id, 'Sandra', 'Schmid', 'Weinbergstrasse', '14', '8006', 'Zuerich', '+41443122200', 'sandra.schmid@gmail.com', 'email', false),
    (v_user_id, 'Peter', 'Keller', 'Seefeldstrasse', '88', '8008', 'Zuerich', '+41443123300', 'p.keller@sunrise.ch', 'email', false),
    (v_user_id, 'Ursula', 'Weber', 'Hofwiesenstrasse', '7', '8057', 'Zuerich', '+41443124400', 'u.weber@bluewin.ch', 'post', false),
    (v_user_id, 'Hans', 'Meier', 'Schaffhauserstrasse', '120', '8057', 'Zuerich', '+41443125500', 'h.meier@gmx.ch', 'email', false),
    (v_user_id, 'Monika', 'Fischer', 'Limmatstrasse', '56', '8005', 'Zuerich', '+41443126600', 'm.fischer@bluewin.ch', 'email', false),
    (v_user_id, 'Beat', 'Huber', 'Badenerstrasse', '200', '8004', 'Zuerich', '+41443127700', 'beat.huber@gmail.com', 'email', false),
    (v_user_id, 'Ruth', 'Steiner', 'Birmensdorferstrasse', '44', '8003', 'Zuerich', '+41443128800', 'r.steiner@bluewin.ch', 'bar', false),
    (v_user_id, 'Daniel', 'Brunner', 'Feldstrasse', '33', '8004', 'Zuerich', '+41443129900', 'daniel.brunner@outlook.com', 'email', false),
    (v_user_id, 'Claudia', 'Gerber', 'Militaerstrasse', '71', '8004', 'Zuerich', '+41443130000', 'c.gerber@gmail.com', 'email', false),
    (v_user_id, 'Markus', 'Baumann', 'Waffenplatzstrasse', '15', '8002', 'Zuerich', '+41443131100', 'm.baumann@sunrise.ch', 'email', false),
    (v_user_id, 'Franziska', 'Graf', 'Toedistrasse', '48', '8002', 'Zuerich', '+41443132200', 'f.graf@bluewin.ch', 'post', false),
    (v_user_id, 'Werner', 'Frei', 'Albisriederstrasse', '99', '8047', 'Zuerich', '+41443133300', 'w.frei@gmx.ch', 'email', false),
    (v_user_id, 'Heidi', 'Zimmermann', 'Friesenbergstrasse', '66', '8045', 'Zuerich', '+41443134400', 'heidi.zimmermann@bluewin.ch', 'email', false),
    (v_user_id, 'Rolf', 'Widmer', 'Sihlfeldstrasse', '17', '8003', 'Zuerich', '+41443135500', 'r.widmer@sunrise.ch', 'email', false),
    (v_user_id, 'Andrea', 'Berger', 'Kronenstrasse', '25', '8006', 'Zuerich', '+41443136600', 'a.berger@gmail.com', 'email', false),
    (v_user_id, 'Christian', 'Wenger', 'Hallwylstrasse', '34', '8004', 'Zuerich', '+41443137700', 'c.wenger@bluewin.ch', 'email', false),
    (v_user_id, 'Barbara', 'Brunner', 'Lavaterstrasse', '40', '8002', 'Zuerich', '+41443138800', 'b.brunner@outlook.com', 'post', false),
    (v_user_id, 'Stefan', 'Leutenegger', 'Forchstrasse', '130', '8032', 'Zuerich', '+41443139900', 's.leutenegger@gmail.com', 'email', false),
    (v_user_id, 'Erika', 'Studer', 'Gloriastrasse', '30', '8006', 'Zuerich', '+41443140000', 'e.studer@bluewin.ch', 'email', false),
    (v_user_id, 'Martin', 'Bosshard', 'Spyristrasse', '8', '8044', 'Zuerich', '+41443141100', 'm.bosshard@gmx.ch', 'email', false),
    (v_user_id, 'Silvia', 'Meili', 'Hornbachstrasse', '21', '8008', 'Zuerich', '+41443142200', 's.meili@bluewin.ch', 'email', false),
    (v_user_id, 'Juerg', 'Roth', 'Thalwilerstrasse', '12', '8002', 'Zuerich', '+41443143300', 'j.roth@sunrise.ch', 'email', false),
    (v_user_id, 'Elisabeth', 'Kunz', 'Dufourstrasse', '50', '8008', 'Zuerich', '+41443144400', 'e.kunz@bluewin.ch', 'bar', false),
    (v_user_id, 'Kurt', 'Suter', 'Zeltweg', '19', '8032', 'Zuerich', '+41443145500', 'kurt.suter@gmail.com', 'email', false),
    (v_user_id, 'Regula', 'Kaufmann', 'Wehntalerstrasse', '55', '8057', 'Zuerich', '+41443146600', 'r.kaufmann@bluewin.ch', 'email', false),
    (v_user_id, 'Fritz', 'Schneider', 'Dubsstrasse', '10', '8003', 'Zuerich', '+41443147700', 'f.schneider@gmx.ch', 'email', false),
    (v_user_id, 'Margrit', 'Lehmann', 'Stampfenbachstrasse', '72', '8006', 'Zuerich', '+41443148800', 'm.lehmann@bluewin.ch', 'post', false),
    (v_user_id, 'Roland', 'Hess', 'Letzigraben', '89', '8047', 'Zuerich', '+41443149900', 'r.hess@sunrise.ch', 'email', false),
    (v_user_id, 'Doris', 'Alder', 'Ringstrasse', '4', '8057', 'Zuerich', '+41443150000', 'd.alder@bluewin.ch', 'email', false),
    -- Winterthur
    (v_user_id, 'Marcel', 'Eigenmann', 'Stadthausstrasse', '25', '8400', 'Winterthur', '+41522121100', 'm.eigenmann@bluewin.ch', 'email', false),
    (v_user_id, 'Christine', 'Lang', 'Technikumstrasse', '40', '8400', 'Winterthur', '+41522122200', 'c.lang@gmail.com', 'email', false),
    (v_user_id, 'Urs', 'Buehler', 'Marktgasse', '18', '8400', 'Winterthur', '+41522123300', 'u.buehler@bluewin.ch', 'email', false),
    (v_user_id, 'Anita', 'Schoch', 'St. Gallerstrasse', '99', '8400', 'Winterthur', '+41522124400', 'a.schoch@sunrise.ch', 'post', false),
    (v_user_id, 'Hanspeter', 'Vogt', 'Tosstalstrasse', '15', '8400', 'Winterthur', '+41522125500', 'hp.vogt@bluewin.ch', 'email', false),
    -- Baden / Brugg
    (v_user_id, 'Rene', 'Stocker', 'Bahnhofstrasse', '30', '5400', 'Baden', '+41562001100', 'r.stocker@gmail.com', 'email', false),
    (v_user_id, 'Verena', 'Bucher', 'Haselstrasse', '8', '5400', 'Baden', '+41562002200', 'v.bucher@bluewin.ch', 'email', false),
    (v_user_id, 'Otto', 'Zurbruegg', 'Bruggerstrasse', '55', '5400', 'Baden', '+41562003300', 'o.zurbruegg@gmx.ch', 'bar', false),
    (v_user_id, 'Irene', 'Haefliger', 'Mellingerstrasse', '12', '5400', 'Baden', '+41562004400', 'i.haefliger@bluewin.ch', 'email', false),
    (v_user_id, 'Paul', 'Kuhn', 'Bahnhofstrasse', '5', '5200', 'Brugg', '+41562005500', 'p.kuhn@sunrise.ch', 'email', false),
    -- Uster / Wetzikon
    (v_user_id, 'Bruno', 'Senn', 'Bankstrasse', '11', '8610', 'Uster', '+41449401100', 'b.senn@bluewin.ch', 'email', false),
    (v_user_id, 'Regine', 'Wild', 'Bahnhofstrasse', '44', '8610', 'Uster', '+41449402200', 'r.wild@gmail.com', 'email', false),
    (v_user_id, 'Anton', 'Koenig', 'Rapperswilerstrasse', '20', '8620', 'Wetzikon', '+41449403300', 'a.koenig@bluewin.ch', 'email', false),
    -- Dietikon / Schlieren
    (v_user_id, 'Therese', 'Furrer', 'Badenerstrasse', '75', '8953', 'Dietikon', '+41447401100', 't.furrer@bluewin.ch', 'email', false),
    (v_user_id, 'Walter', 'Ammann', 'Ueberlandstrasse', '22', '8952', 'Schlieren', '+41447402200', 'w.ammann@sunrise.ch', 'email', false),
    -- Horgen / Thalwil
    (v_user_id, 'Kathrin', 'Schaerer', 'Seestrasse', '160', '8810', 'Horgen', '+41447251100', 'k.schaerer@gmail.com', 'email', false),
    (v_user_id, 'Heinrich', 'Bolliger', 'Gotthardstrasse', '35', '8800', 'Thalwil', '+41447252200', 'h.bolliger@bluewin.ch', 'post', false),
    -- Buelach / Kloten
    (v_user_id, 'Esther', 'Kaelin', 'Schaffhauserstrasse', '20', '8180', 'Buelach', '+41448601100', 'e.kaelin@bluewin.ch', 'email', false),
    (v_user_id, 'Ruedi', 'Tobler', 'Marktgasse', '9', '8302', 'Kloten', '+41448602200', 'r.tobler@gmx.ch', 'email', false),
    -- Diverse Zuerich
    (v_user_id, 'Susanne', 'Kessler', 'Bergstrasse', '33', '8032', 'Zuerich', '+41443160100', 's.kessler@bluewin.ch', 'email', false),
    (v_user_id, 'Max', 'Eberle', 'Hohlstrasse', '200', '8004', 'Zuerich', '+41443160200', 'max.eberle@outlook.com', 'email', false),
    (v_user_id, 'Beatrice', 'Nef', 'Uetlibergstrasse', '5', '8045', 'Zuerich', '+41443160300', 'b.nef@bluewin.ch', 'email', false),
    (v_user_id, 'Hugo', 'Pfister', 'Mythenquai', '50', '8002', 'Zuerich', '+41443160400', 'h.pfister@gmail.com', 'email', false),
    (v_user_id, 'Maria', 'Lutz', 'Utoquai', '15', '8008', 'Zuerich', '+41443160500', 'm.lutz@bluewin.ch', 'email', false),
    (v_user_id, 'Robert', 'Knecht', 'Heinrichstrasse', '180', '8005', 'Zuerich', '+41443160600', 'r.knecht@sunrise.ch', 'email', false),
    (v_user_id, 'Brigitte', 'Ott', 'Regensbergstrasse', '60', '8050', 'Zuerich', '+41443160700', 'b.ott@bluewin.ch', 'email', false),
    (v_user_id, 'Alois', 'Schwab', 'Bucheggstrasse', '42', '8057', 'Zuerich', '+41443160800', 'a.schwab@gmx.ch', 'email', false),
    (v_user_id, 'Irma', 'Hauser', 'Nordstrasse', '12', '8006', 'Zuerich', '+41443160900', 'i.hauser@bluewin.ch', 'email', false),
    (v_user_id, 'Georg', 'Walder', 'Ackerstrasse', '28', '8005', 'Zuerich', '+41443161000', 'g.walder@gmail.com', 'email', false);

  -- Firmenkunden (40) - mit abweichender Rechnungsadresse (10%)
  INSERT INTO kunden (user_id, firma, vorname, nachname, strasse, hausnummer, plz, ort, telefon, email, rechnungsstellung, re_abweichend, re_firma, re_strasse, re_hausnummer, re_plz, re_ort, re_email, is_deleted) VALUES
    (v_user_id, 'Immobilien Zuerich AG', 'Markus', 'Wirth', 'Talstrasse', '62', '8001', 'Zuerich', '+41442011100', 'wirth@immo-zh.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Hausverwaltung Seefeld GmbH', 'Sabine', 'Reuter', 'Seefeldstrasse', '120', '8008', 'Zuerich', '+41442012200', 'reuter@hv-seefeld.ch', 'email', true, 'Treuhand Seefeld AG', 'Bellerivestrasse', '45', '8008', 'Zuerich', 'buchhaltung@treuhand-seefeld.ch', false),
    (v_user_id, 'Restaurant Seerose', 'Giuseppe', 'Conte', 'Seestrasse', '30', '8002', 'Zuerich', '+41442013300', 'info@seerose-zh.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Hotel Schweizerhof AG', 'Philippe', 'Dubois', 'Bahnhofplatz', '7', '8001', 'Zuerich', '+41442014400', 'technik@schweizerhof-zh.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Baugenossenschaft Zurlinden', 'Walter', 'Zurlinden', 'Badenerstrasse', '310', '8004', 'Zuerich', '+41442015500', 'verwaltung@bg-zurlinden.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Fitness World GmbH', 'Mike', 'Taylor', 'Hardturmstrasse', '66', '8005', 'Zuerich', '+41442016600', 'info@fitness-world.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Coiffure Elegance', 'Nathalie', 'Dupont', 'Langstrasse', '122', '8004', 'Zuerich', '+41442017700', 'info@coiffure-elegance.ch', 'bar', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Praxis Dr. med. Haller', 'Thomas', 'Haller', 'Gloriastrasse', '14', '8006', 'Zuerich', '+41442018800', 'praxis@dr-haller.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Zahnklinik Bellevue AG', 'Stefan', 'Burri', 'Theaterstrasse', '22', '8001', 'Zuerich', '+41442019900', 'info@zahnklinik-bellevue.ch', 'email', true, 'Zahnklinik Bellevue AG', 'Postfach', NULL, '8021', 'Zuerich', 'buchhaltung@zahnklinik-bellevue.ch', false),
    (v_user_id, 'Architekturburo Lenz + Partner', 'Florian', 'Lenz', 'Limmatquai', '78', '8001', 'Zuerich', '+41442020000', 'lenz@lenz-architekten.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Schreinerei Holzart GmbH', 'Beat', 'Holzer', 'Binzmuehlestrasse', '35', '8050', 'Zuerich', '+41442021100', 'holzer@holzart.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Baeckerei Kuhn AG', 'Fritz', 'Kuhn', 'Feldstrasse', '8', '8004', 'Zuerich', '+41442022200', 'f.kuhn@baeckerei-kuhn.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Gartenbau Gruenwald', 'Hans', 'Gruenwald', 'Seebahnstrasse', '44', '8003', 'Zuerich', '+41442023300', 'info@gruenwald-garten.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Elektro Blitz GmbH', 'Patrick', 'Blitz', 'Heinrichstrasse', '90', '8005', 'Zuerich', '+41442024400', 'info@elektro-blitz.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Maler Farbton AG', 'Roger', 'Farbton', 'Roentgenstrasse', '12', '8005', 'Zuerich', '+41442025500', 'info@farbton.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Verwaltung Hirslanden AG', 'Claudia', 'Meister', 'Forchstrasse', '200', '8032', 'Zuerich', '+41442026600', 'verwaltung@hirslanden-vw.ch', 'email', true, 'BDO AG', 'Schiffbaustrasse', '2', '8005', 'Zuerich', 'zh@bdo.ch', false),
    (v_user_id, 'Kita Sonnenschein', 'Laura', 'Hug', 'Mutschellenstrasse', '28', '8002', 'Zuerich', '+41442027700', 'info@kita-sonnenschein.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Metallbau Stark AG', 'Dieter', 'Stark', 'Hardstrasse', '214', '8005', 'Zuerich', '+41442028800', 'd.stark@metallbau-stark.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Autogarage Central', 'Sergio', 'Rossi', 'Sihlquai', '80', '8005', 'Zuerich', '+41442029900', 'info@garage-central.ch', 'bar', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Treuhand Wipkingen GmbH', 'Alexander', 'Brun', 'Rosengartenstrasse', '1', '8037', 'Zuerich', '+41442030000', 'brun@treuhand-wipkingen.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    -- Winterthur Firmen
    (v_user_id, 'Hausverwaltung Winterthur AG', 'Ernst', 'Walder', 'Marktgasse', '32', '8400', 'Winterthur', '+41522031100', 'walder@hv-winterthur.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Sport & Freizeit AG', 'Thomas', 'Riederer', 'Technikumstrasse', '6', '8400', 'Winterthur', '+41522032200', 'riederer@sport-freizeit.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Seniorenzentrum Eulachtal', 'Maria', 'Nussbaum', 'Wuelflingerstrasse', '100', '8400', 'Winterthur', '+41522033300', 'technik@sz-eulachtal.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Wohnbaugesellschaft Toess', 'Robert', 'Kessler', 'Schaffhauserstrasse', '60', '8400', 'Winterthur', '+41522034400', 'verwaltung@wbg-toess.ch', 'email', true, 'Wohnbaugesellschaft Toess', 'Postfach 222', NULL, '8401', 'Winterthur', 'rechnungen@wbg-toess.ch', false),
    (v_user_id, 'Gasthof Loewen', 'Peter', 'Spiess', 'Altstadt', '15', '8400', 'Winterthur', '+41522035500', 'info@loewen-winterthur.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    -- Baden Firmen
    (v_user_id, 'Therme Baden AG', 'Lisa', 'Brunner', 'Badestrasse', '40', '5400', 'Baden', '+41562036600', 'technik@therme-baden.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Gewerbehaus Baden GmbH', 'Marco', 'Dietrich', 'Cordulaplatz', '4', '5400', 'Baden', '+41562037700', 'info@gewerbehaus-baden.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Altersheim Kehl', 'Vreni', 'Maurer', 'Kehlstrasse', '22', '5400', 'Baden', '+41562038800', 'verwaltung@ah-kehl.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    -- Diverse Firmen
    (v_user_id, 'Migros Genossenschaft Zuerich', 'Andreas', 'Huber', 'Pfingstweidstrasse', '101', '8005', 'Zuerich', '+41442039900', 'facility@migros-zh.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Swiss Re Management AG', 'Caroline', 'Von Allmen', 'Mythenquai', '60', '8002', 'Zuerich', '+41442040000', 'facility@swissre.com', 'email', true, 'Swiss Re Shared Services', 'Postfach', NULL, '8022', 'Zuerich', 'invoices@swissre.com', false),
    (v_user_id, 'Schulhaus Neumünster', 'Brigitte', 'Zollinger', 'Freiestrasse', '60', '8032', 'Zuerich', '+41444131100', 'hauswart@schulhaus-neumuenster.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Kirchgemeinde Enge', 'Hans-Ulrich', 'Pfenninger', 'Bederstrasse', '33', '8002', 'Zuerich', '+41444132200', 'sekretariat@kirche-enge.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Apotheke am Paradeplatz', 'Christina', 'Mettler', 'Bahnhofstrasse', '92', '8001', 'Zuerich', '+41444133300', 'info@apo-paradeplatz.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'IT Solutions Zuerich GmbH', 'Kevin', 'Wirz', 'Manessestrasse', '50', '8003', 'Zuerich', '+41444134400', 'office@it-solutions-zh.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Pizzeria Roma', 'Marco', 'Bianchi', 'Langstrasse', '200', '8005', 'Zuerich', '+41444135500', 'info@pizzeria-roma-zh.ch', 'bar', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Hausverwaltung Oerlikon GmbH', 'Daniel', 'Buehler', 'Schaffhauserstrasse', '350', '8050', 'Zuerich', '+41444136600', 'buehler@hv-oerlikon.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Alterszentrum am Bach', 'Susanna', 'Egli', 'Bachstrasse', '12', '8610', 'Uster', '+41449407700', 'verwaltung@az-bach.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Velowerkstatt Spoke GmbH', 'Jan', 'Moser', 'Josefstrasse', '88', '8005', 'Zuerich', '+41444138800', 'jan@spoke.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Buchhandlung am Limmatplatz', 'Eva', 'Blum', 'Limmatstrasse', '2', '8005', 'Zuerich', '+41444139900', 'info@buchhandlung-limmatplatz.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false),
    (v_user_id, 'Reinigung ProClean AG', 'Ali', 'Yilmaz', 'Hardturmstrasse', '120', '8005', 'Zuerich', '+41444140000', 'info@proclean.ch', 'email', false, NULL, NULL, NULL, NULL, NULL, NULL, false);

  RAISE NOTICE 'Kunden angelegt: %', (SELECT COUNT(*) FROM kunden WHERE user_id = v_user_id);

  -- ========================================================================
  -- 7. LIEFERANTEN (8 Stueck)
  -- ========================================================================
  DELETE FROM lieferanten WHERE user_id = v_user_id;

  INSERT INTO lieferanten (user_id, firma, kontaktperson, strasse, hausnummer, plz, ort, telefon, email, website, zahlungsfrist_tage, notizen, is_deleted) VALUES
    (v_user_id, 'Geberit AG', 'Heinz Mueller', 'Schachenstrasse', '77', '8645', 'Rapperswil-Jona', '+41552216111', 'info@geberit.ch', 'www.geberit.ch', 30, 'Hauptlieferant Sanitaertechnik, Installationssysteme', false),
    (v_user_id, 'R. Nussbaum AG', 'Peter Zuercher', 'Kartenstrasse', '35', '4601', 'Olten', '+41622868111', 'info@nussbaum.ch', 'www.nussbaum.ch', 30, 'Armaturen, Ventile, Regulierventile', false),
    (v_user_id, 'Stiebel Eltron AG', 'Klaus Weber', 'Industrie Ost', '10', '5242', 'Lupfig', '+41562645111', 'info@stiebel-eltron.ch', 'www.stiebel-eltron.ch', 30, 'Warmwasser, Waermepumpen, Durchlauferhitzer', false),
    (v_user_id, 'Tobler Haustechnik AG', 'Franz Tobler', 'Steinackerstrasse', '10', '8902', 'Urdorf', '+41447357111', 'info@tobler.ch', 'www.tobler.ch', 30, 'Haustechnik Grosshandel, Heizung, Sanitaer', false),
    (v_user_id, 'Sanitas Troesch AG', 'Andrea Schmid', 'Roetelstrasse', '68', '8005', 'Zuerich', '+41443002111', 'info@sanitastroesch.ch', 'www.sanitastroesch.ch', 30, 'Badezimmerausstattung, Keramik, Design', false),
    (v_user_id, 'Pestalozzi + Co AG', 'Martin Hauser', 'Silbernstrasse', '22', '8953', 'Dietikon', '+41447455111', 'info@pestalozzi.com', 'www.pestalozzi.com', 30, 'Rohre, Fittings, Stahlhandel', false),
    (v_user_id, 'Debrunner Acifer AG', 'Stefan Roth', 'Giesshuebelstrasse', '45', '8045', 'Zuerich', '+41442777111', 'info@d-a.ch', 'www.debrunner-acifer.ch', 30, 'Stahl, Metall, Werkzeug, Befestigung', false),
    (v_user_id, 'Wuerth AG', 'Thomas Gerber', 'Dornwydenweg', '11', '4144', 'Arlesheim', '+41617066111', 'info@wuerth.ch', 'www.wuerth.ch', 30, 'Befestigungstechnik, Werkzeug, Chemie', false);

  RAISE NOTICE 'Lieferanten angelegt: %', (SELECT COUNT(*) FROM lieferanten WHERE user_id = v_user_id);
  RAISE NOTICE '=== Testdaten 01 Stammdaten FERTIG ===';
END;
$$;

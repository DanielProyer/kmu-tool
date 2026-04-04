-- ============================================================================
-- KMU Tool - Testdaten 02: Artikel, Lieferanten-Zuordnungen, Lagerorte
-- Proyer Sanitaer GmbH
-- ============================================================================
-- Abhaengigkeit: testdaten_01_stammdaten.sql muss zuerst ausgefuehrt werden
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_lagerort_haupt UUID;
  v_lagerort_sf1 UUID;
  v_lagerort_sf2 UUID;
  v_lagerort_bau UUID;
  v_lieferant_geberit UUID;
  v_lieferant_nussbaum UUID;
  v_lieferant_stiebel UUID;
  v_lieferant_tobler UUID;
  v_lieferant_sanitas UUID;
  v_lieferant_pestalozzi UUID;
  v_lieferant_debrunner UUID;
  v_lieferant_wuerth UUID;
  v_artikel_ids UUID[];
  v_art_id UUID;
  i INTEGER;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  -- Lieferanten-IDs holen
  SELECT id INTO v_lieferant_geberit FROM lieferanten WHERE user_id = v_user_id AND firma = 'Geberit AG';
  SELECT id INTO v_lieferant_nussbaum FROM lieferanten WHERE user_id = v_user_id AND firma = 'R. Nussbaum AG';
  SELECT id INTO v_lieferant_stiebel FROM lieferanten WHERE user_id = v_user_id AND firma = 'Stiebel Eltron AG';
  SELECT id INTO v_lieferant_tobler FROM lieferanten WHERE user_id = v_user_id AND firma = 'Tobler Haustechnik AG';
  SELECT id INTO v_lieferant_sanitas FROM lieferanten WHERE user_id = v_user_id AND firma = 'Sanitas Troesch AG';
  SELECT id INTO v_lieferant_pestalozzi FROM lieferanten WHERE user_id = v_user_id AND firma LIKE 'Pestalozzi%';
  SELECT id INTO v_lieferant_debrunner FROM lieferanten WHERE user_id = v_user_id AND firma = 'Debrunner Acifer AG';
  SELECT id INTO v_lieferant_wuerth FROM lieferanten WHERE user_id = v_user_id AND firma = 'Wuerth AG';

  -- ========================================================================
  -- LAGERORTE (4 Stueck)
  -- ========================================================================
  DELETE FROM lagerorte WHERE user_id = v_user_id;

  INSERT INTO lagerorte (id, user_id, bezeichnung, typ, ist_standard, sortierung, is_deleted) VALUES
    (gen_random_uuid(), v_user_id, 'Hauptlager Bahnhofstrasse', 'lager', true, 1, false),
    (gen_random_uuid(), v_user_id, 'Servicefahrzeug 1 (ZH 234 567)', 'fahrzeug', false, 2, false),
    (gen_random_uuid(), v_user_id, 'Servicefahrzeug 2 (ZH 345 678)', 'fahrzeug', false, 3, false),
    (gen_random_uuid(), v_user_id, 'Baustelle Muster', 'baustelle', false, 4, false);

  SELECT id INTO v_lagerort_haupt FROM lagerorte WHERE user_id = v_user_id AND typ = 'lager' LIMIT 1;
  SELECT id INTO v_lagerort_sf1 FROM lagerorte WHERE user_id = v_user_id AND bezeichnung LIKE '%234 567%';
  SELECT id INTO v_lagerort_sf2 FROM lagerorte WHERE user_id = v_user_id AND bezeichnung LIKE '%345 678%';
  SELECT id INTO v_lagerort_bau FROM lagerorte WHERE user_id = v_user_id AND typ = 'baustelle' LIMIT 1;

  -- ========================================================================
  -- ARTIKEL (200 Stueck) - Sanitaer-typisch
  -- ========================================================================
  DELETE FROM artikel WHERE user_id = v_user_id;

  -- === MATERIAL (~120 Stueck) ===

  -- Rohre (20)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'ROH-001', 'Kupferrohr 15mm x 5m', 'material', 'm', 8.50, 14.20, 50, 'material', false),
    (v_user_id, 'ROH-002', 'Kupferrohr 18mm x 5m', 'material', 'm', 10.20, 17.00, 50, 'material', false),
    (v_user_id, 'ROH-003', 'Kupferrohr 22mm x 5m', 'material', 'm', 13.80, 23.00, 40, 'material', false),
    (v_user_id, 'ROH-004', 'Kupferrohr 28mm x 5m', 'material', 'm', 18.50, 30.80, 30, 'material', false),
    (v_user_id, 'ROH-005', 'Kupferrohr 35mm x 5m', 'material', 'm', 24.00, 40.00, 20, 'material', false),
    (v_user_id, 'ROH-006', 'PE-Rohr 20mm x 25m', 'material', 'm', 2.80, 4.70, 100, 'material', false),
    (v_user_id, 'ROH-007', 'PE-Rohr 25mm x 25m', 'material', 'm', 3.50, 5.80, 100, 'material', false),
    (v_user_id, 'ROH-008', 'PE-Rohr 32mm x 25m', 'material', 'm', 4.90, 8.20, 50, 'material', false),
    (v_user_id, 'ROH-009', 'PVC Abflussrohr DN50 x 2m', 'material', 'Stk', 6.20, 10.30, 30, 'material', false),
    (v_user_id, 'ROH-010', 'PVC Abflussrohr DN75 x 2m', 'material', 'Stk', 8.50, 14.20, 20, 'material', false),
    (v_user_id, 'ROH-011', 'PVC Abflussrohr DN100 x 2m', 'material', 'Stk', 12.80, 21.30, 20, 'material', false),
    (v_user_id, 'ROH-012', 'PVC Abflussrohr DN110 x 2m', 'material', 'Stk', 14.50, 24.20, 15, 'material', false),
    (v_user_id, 'ROH-013', 'Geberit Mapress Rohr 15mm x 6m', 'material', 'm', 12.40, 20.70, 30, 'material', false),
    (v_user_id, 'ROH-014', 'Geberit Mapress Rohr 22mm x 6m', 'material', 'm', 18.60, 31.00, 20, 'material', false),
    (v_user_id, 'ROH-015', 'Geberit Mapress Rohr 28mm x 6m', 'material', 'm', 24.50, 40.80, 15, 'material', false),
    (v_user_id, 'ROH-016', 'Flexibles Anschlussrohr 3/8" x 50cm', 'material', 'Stk', 4.80, 8.00, 40, 'material', false),
    (v_user_id, 'ROH-017', 'Flexibles Anschlussrohr 1/2" x 50cm', 'material', 'Stk', 5.50, 9.20, 40, 'material', false),
    (v_user_id, 'ROH-018', 'Mehrschichtverbundrohr 16mm x 50m', 'material', 'm', 2.20, 3.70, 100, 'material', false),
    (v_user_id, 'ROH-019', 'Mehrschichtverbundrohr 20mm x 50m', 'material', 'm', 3.10, 5.20, 100, 'material', false),
    (v_user_id, 'ROH-020', 'Mehrschichtverbundrohr 26mm x 50m', 'material', 'm', 4.80, 8.00, 50, 'material', false);

  -- Fittings (25)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'FIT-001', 'Kupfer Loetfitting Bogen 90° 15mm', 'material', 'Stk', 1.20, 2.00, 100, 'material', false),
    (v_user_id, 'FIT-002', 'Kupfer Loetfitting Bogen 90° 18mm', 'material', 'Stk', 1.50, 2.50, 80, 'material', false),
    (v_user_id, 'FIT-003', 'Kupfer Loetfitting Bogen 90° 22mm', 'material', 'Stk', 2.10, 3.50, 60, 'material', false),
    (v_user_id, 'FIT-004', 'Kupfer Loetfitting T-Stueck 15mm', 'material', 'Stk', 1.80, 3.00, 80, 'material', false),
    (v_user_id, 'FIT-005', 'Kupfer Loetfitting T-Stueck 18mm', 'material', 'Stk', 2.20, 3.70, 60, 'material', false),
    (v_user_id, 'FIT-006', 'Kupfer Loetfitting T-Stueck 22mm', 'material', 'Stk', 3.10, 5.20, 40, 'material', false),
    (v_user_id, 'FIT-007', 'Kupfer Loetfitting Reduktion 22/15', 'material', 'Stk', 2.40, 4.00, 40, 'material', false),
    (v_user_id, 'FIT-008', 'Kupfer Loetfitting Muffe 15mm', 'material', 'Stk', 0.90, 1.50, 100, 'material', false),
    (v_user_id, 'FIT-009', 'Geberit Mapress Bogen 90° 15mm', 'material', 'Stk', 8.50, 14.20, 30, 'material', false),
    (v_user_id, 'FIT-010', 'Geberit Mapress Bogen 90° 22mm', 'material', 'Stk', 12.80, 21.30, 20, 'material', false),
    (v_user_id, 'FIT-011', 'Geberit Mapress T-Stueck 15mm', 'material', 'Stk', 14.50, 24.20, 20, 'material', false),
    (v_user_id, 'FIT-012', 'Geberit Mapress T-Stueck 22mm', 'material', 'Stk', 18.90, 31.50, 15, 'material', false),
    (v_user_id, 'FIT-013', 'PVC Bogen 45° DN50', 'material', 'Stk', 2.80, 4.70, 40, 'material', false),
    (v_user_id, 'FIT-014', 'PVC Bogen 90° DN50', 'material', 'Stk', 3.20, 5.30, 40, 'material', false),
    (v_user_id, 'FIT-015', 'PVC Bogen 90° DN100', 'material', 'Stk', 5.80, 9.70, 20, 'material', false),
    (v_user_id, 'FIT-016', 'PVC T-Stueck DN50', 'material', 'Stk', 4.50, 7.50, 30, 'material', false),
    (v_user_id, 'FIT-017', 'PVC T-Stueck DN100', 'material', 'Stk', 8.20, 13.70, 15, 'material', false),
    (v_user_id, 'FIT-018', 'PVC Reduktion DN100/50', 'material', 'Stk', 4.80, 8.00, 20, 'material', false),
    (v_user_id, 'FIT-019', 'PVC Siphon DN50', 'material', 'Stk', 6.50, 10.80, 20, 'material', false),
    (v_user_id, 'FIT-020', 'Uebergangsmuffe Cu/IG 15mm x 1/2"', 'material', 'Stk', 3.80, 6.30, 40, 'material', false),
    (v_user_id, 'FIT-021', 'Uebergangsmuffe Cu/AG 15mm x 1/2"', 'material', 'Stk', 3.50, 5.80, 40, 'material', false),
    (v_user_id, 'FIT-022', 'Kugelhahn 1/2" IG', 'material', 'Stk', 8.90, 14.80, 20, 'material', false),
    (v_user_id, 'FIT-023', 'Kugelhahn 3/4" IG', 'material', 'Stk', 12.50, 20.80, 15, 'material', false),
    (v_user_id, 'FIT-024', 'Kugelhahn 1" IG', 'material', 'Stk', 18.00, 30.00, 10, 'material', false),
    (v_user_id, 'FIT-025', 'Rueckflussverhinderer 1/2"', 'material', 'Stk', 14.50, 24.20, 10, 'material', false);

  -- Armaturen (15)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'ARM-001', 'Einhebelmischer Lavabo Standard', 'material', 'Stk', 85.00, 145.00, 5, 'material', false),
    (v_user_id, 'ARM-002', 'Einhebelmischer Lavabo Design', 'material', 'Stk', 180.00, 310.00, 3, 'material', false),
    (v_user_id, 'ARM-003', 'Thermostatmischer Dusche', 'material', 'Stk', 220.00, 380.00, 3, 'material', false),
    (v_user_id, 'ARM-004', 'Einhebelmischer Kueche', 'material', 'Stk', 120.00, 205.00, 5, 'material', false),
    (v_user_id, 'ARM-005', 'Kuechen-Armatur mit Brause', 'material', 'Stk', 250.00, 430.00, 2, 'material', false),
    (v_user_id, 'ARM-006', 'Brause-Set komplett', 'material', 'Stk', 95.00, 165.00, 5, 'material', false),
    (v_user_id, 'ARM-007', 'Regenbrause Kopf 200mm', 'material', 'Stk', 120.00, 205.00, 3, 'material', false),
    (v_user_id, 'ARM-008', 'Wannen-Armatur Aufputz', 'material', 'Stk', 145.00, 250.00, 3, 'material', false),
    (v_user_id, 'ARM-009', 'Wannen-Armatur Unterputz', 'material', 'Stk', 280.00, 480.00, 2, 'material', false),
    (v_user_id, 'ARM-010', 'Eckventil 1/2" x 3/8" Standard', 'material', 'Stk', 8.50, 14.20, 30, 'material', false),
    (v_user_id, 'ARM-011', 'Eckventil 1/2" x 3/8" Design', 'material', 'Stk', 22.00, 37.00, 10, 'material', false),
    (v_user_id, 'ARM-012', 'Waschtisch-Siphon DN32 chrom', 'material', 'Stk', 18.00, 30.00, 15, 'material', false),
    (v_user_id, 'ARM-013', 'Spueltisch-Siphon DN50', 'material', 'Stk', 15.00, 25.00, 10, 'material', false),
    (v_user_id, 'ARM-014', 'Thermostatventil Heizung', 'material', 'Stk', 28.00, 48.00, 20, 'material', false),
    (v_user_id, 'ARM-015', 'Sicherheitsventil 6 bar', 'material', 'Stk', 18.50, 31.00, 10, 'material', false);

  -- Sanitaer-Keramik / WC / Lavabo (15)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'SAN-001', 'WC-Kombination Stand komplett', 'material', 'Stk', 280.00, 480.00, 2, 'material', false),
    (v_user_id, 'SAN-002', 'WC Wand-haengend Geberit', 'material', 'Stk', 350.00, 600.00, 2, 'material', false),
    (v_user_id, 'SAN-003', 'Geberit Unterputzspuelkasten UP320', 'material', 'Stk', 180.00, 310.00, 3, 'material', false),
    (v_user_id, 'SAN-004', 'Geberit Betaetigungsplatte Sigma20', 'material', 'Stk', 95.00, 165.00, 5, 'material', false),
    (v_user_id, 'SAN-005', 'Geberit Duofix WC-Element 112cm', 'material', 'Stk', 320.00, 550.00, 2, 'material', false),
    (v_user_id, 'SAN-006', 'Lavabo 60cm Standard weiss', 'material', 'Stk', 120.00, 205.00, 3, 'material', false),
    (v_user_id, 'SAN-007', 'Lavabo 80cm Design', 'material', 'Stk', 280.00, 480.00, 2, 'material', false),
    (v_user_id, 'SAN-008', 'Doppellavabo 120cm', 'material', 'Stk', 450.00, 770.00, 1, 'material', false),
    (v_user_id, 'SAN-009', 'Badewanne Stahl 170x70cm', 'material', 'Stk', 320.00, 550.00, 1, 'material', false),
    (v_user_id, 'SAN-010', 'Badewanne Acryl 180x80cm', 'material', 'Stk', 480.00, 820.00, 1, 'material', false),
    (v_user_id, 'SAN-011', 'Duschkabine 90x90cm Eckeinstieg', 'material', 'Stk', 650.00, 1100.00, 1, 'material', false),
    (v_user_id, 'SAN-012', 'Duschwanne 90x90cm flach', 'material', 'Stk', 180.00, 310.00, 2, 'material', false),
    (v_user_id, 'SAN-013', 'WC-Sitz Softclose weiss', 'material', 'Stk', 45.00, 77.00, 5, 'material', false),
    (v_user_id, 'SAN-014', 'Bidet wandhaengend weiss', 'material', 'Stk', 220.00, 380.00, 1, 'material', false),
    (v_user_id, 'SAN-015', 'Urinal Geberit mit Deckel', 'material', 'Stk', 280.00, 480.00, 1, 'material', false);

  -- Boiler / Warmwasser (10)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'BOI-001', 'Elektroboiler 50 Liter', 'material', 'Stk', 420.00, 720.00, 1, 'material', false),
    (v_user_id, 'BOI-002', 'Elektroboiler 80 Liter', 'material', 'Stk', 580.00, 990.00, 1, 'material', false),
    (v_user_id, 'BOI-003', 'Elektroboiler 120 Liter', 'material', 'Stk', 720.00, 1230.00, 1, 'material', false),
    (v_user_id, 'BOI-004', 'Elektroboiler 150 Liter', 'material', 'Stk', 850.00, 1450.00, 1, 'material', false),
    (v_user_id, 'BOI-005', 'Elektroboiler 200 Liter', 'material', 'Stk', 980.00, 1680.00, 1, 'material', false),
    (v_user_id, 'BOI-006', 'Durchlauferhitzer 21kW', 'material', 'Stk', 480.00, 820.00, 1, 'material', false),
    (v_user_id, 'BOI-007', 'Warmwasserspeicher 300L Solar', 'material', 'Stk', 1800.00, 3100.00, 0, 'material', false),
    (v_user_id, 'BOI-008', 'Zirkulationspumpe Grundfos', 'material', 'Stk', 180.00, 310.00, 2, 'material', false),
    (v_user_id, 'BOI-009', 'Ausdehnungsgefaess 12L Heizung', 'material', 'Stk', 45.00, 77.00, 3, 'material', false),
    (v_user_id, 'BOI-010', 'Ausdehnungsgefaess 25L Heizung', 'material', 'Stk', 75.00, 130.00, 2, 'material', false);

  -- Dichtungen / Kleinteil (15)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'DIC-001', 'Flachdichtung 1/2" Set 10 Stk', 'material', 'Set', 3.50, 5.80, 20, 'material', false),
    (v_user_id, 'DIC-002', 'Flachdichtung 3/4" Set 10 Stk', 'material', 'Set', 4.00, 6.70, 20, 'material', false),
    (v_user_id, 'DIC-003', 'O-Ring Sortiment 200-tlg', 'material', 'Set', 18.00, 30.00, 5, 'material', false),
    (v_user_id, 'DIC-004', 'Gewindedichtband PTFE 12mm x 12m', 'material', 'Stk', 1.80, 3.00, 50, 'material', false),
    (v_user_id, 'DIC-005', 'Hanf Dichtfaser 200g', 'material', 'Stk', 5.50, 9.20, 10, 'material', false),
    (v_user_id, 'DIC-006', 'Neo-Fermit Dichtpaste 150g', 'material', 'Stk', 8.50, 14.20, 10, 'material', false),
    (v_user_id, 'DIC-007', 'WC-Dichtung Geberit', 'material', 'Stk', 4.20, 7.00, 10, 'material', false),
    (v_user_id, 'DIC-008', 'Manschetten-Set WC DN100', 'material', 'Stk', 6.80, 11.30, 10, 'material', false),
    (v_user_id, 'DIC-009', 'Abfluss-Dichtung DN50 Gummi', 'material', 'Stk', 2.50, 4.20, 30, 'material', false),
    (v_user_id, 'DIC-010', 'Abfluss-Dichtung DN100 Gummi', 'material', 'Stk', 3.80, 6.30, 20, 'material', false),
    (v_user_id, 'DIC-011', 'Rohrschelle 15mm mit Duebelset', 'material', 'Stk', 1.20, 2.00, 100, 'material', false),
    (v_user_id, 'DIC-012', 'Rohrschelle 22mm mit Duebelset', 'material', 'Stk', 1.50, 2.50, 80, 'material', false),
    (v_user_id, 'DIC-013', 'Rohrschelle DN50 mit Duebelset', 'material', 'Stk', 2.80, 4.70, 40, 'material', false),
    (v_user_id, 'DIC-014', 'Rohrschelle DN100 mit Duebelset', 'material', 'Stk', 4.50, 7.50, 30, 'material', false),
    (v_user_id, 'DIC-015', 'Rohrisolierung 15mm x 13mm x 1m', 'material', 'Stk', 2.20, 3.70, 50, 'material', false);

  -- Heizung (10)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'HEI-001', 'Heizkoerper Typ 22 600x1000mm', 'material', 'Stk', 180.00, 310.00, 2, 'material', false),
    (v_user_id, 'HEI-002', 'Heizkoerper Typ 22 600x1400mm', 'material', 'Stk', 240.00, 410.00, 1, 'material', false),
    (v_user_id, 'HEI-003', 'Heizkoerper Typ 33 600x1200mm', 'material', 'Stk', 320.00, 550.00, 1, 'material', false),
    (v_user_id, 'HEI-004', 'Handtuchheizkoerper 1200x500mm', 'material', 'Stk', 150.00, 260.00, 2, 'material', false),
    (v_user_id, 'HEI-005', 'Heizkoerper-Ventil DN15', 'material', 'Stk', 12.00, 20.00, 15, 'material', false),
    (v_user_id, 'HEI-006', 'Heizkoerper-Ruecklaufverschraubung DN15', 'material', 'Stk', 8.50, 14.20, 15, 'material', false),
    (v_user_id, 'HEI-007', 'Heizungsumwaelzpumpe Grundfos Alpha', 'material', 'Stk', 320.00, 550.00, 1, 'material', false),
    (v_user_id, 'HEI-008', 'Heizkessel-Sicherheitsgruppe', 'material', 'Stk', 85.00, 145.00, 2, 'material', false),
    (v_user_id, 'HEI-009', 'Mischventil 3-Weg DN25', 'material', 'Stk', 120.00, 205.00, 2, 'material', false),
    (v_user_id, 'HEI-010', 'Entluefter automatisch 1/2"', 'material', 'Stk', 8.50, 14.20, 20, 'material', false);

  -- Diverses Material (10)
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'DIV-001', 'Geberit Silent-db20 Abflussrohr DN56', 'material', 'Stk', 18.50, 31.00, 10, 'material', false),
    (v_user_id, 'DIV-002', 'Geberit Silent-db20 Abflussrohr DN90', 'material', 'Stk', 28.00, 48.00, 8, 'material', false),
    (v_user_id, 'DIV-003', 'Bodenablauf DN50 mit Rost', 'material', 'Stk', 35.00, 60.00, 5, 'material', false),
    (v_user_id, 'DIV-004', 'Duschrinne 700mm komplett', 'material', 'Stk', 180.00, 310.00, 2, 'material', false),
    (v_user_id, 'DIV-005', 'Waschmaschinenanschluss-Set', 'material', 'Stk', 22.00, 37.00, 5, 'material', false),
    (v_user_id, 'DIV-006', 'Geschirrspueler-Anschluss-Set', 'material', 'Stk', 18.00, 30.00, 5, 'material', false),
    (v_user_id, 'DIV-007', 'Wasserenthaertungsanlage BWT', 'material', 'Stk', 1200.00, 2050.00, 0, 'material', false),
    (v_user_id, 'DIV-008', 'Druckreduzierventil 1/2"', 'material', 'Stk', 45.00, 77.00, 3, 'material', false),
    (v_user_id, 'DIV-009', 'Wasserzaehler QN 2.5 kalt', 'material', 'Stk', 35.00, 60.00, 3, 'material', false),
    (v_user_id, 'DIV-010', 'Fussbodenheizung Tackersystem 10m2', 'material', 'Set', 280.00, 480.00, 0, 'material', false);

  -- === WERKZEUG (~40 Stueck) ===
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'WKZ-001', 'Rohrschneider Cu 3-35mm', 'werkzeug', 'Stk', 45.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-002', 'Rohrschneider Cu 3-22mm Mini', 'werkzeug', 'Stk', 28.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-003', 'Entgrater innen/aussen', 'werkzeug', 'Stk', 22.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-004', 'Loetkolben Set Propan', 'werkzeug', 'Stk', 85.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-005', 'Pressmaschine Geberit ACO203', 'werkzeug', 'Stk', 3200.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-006', 'Pressbacken-Set 15-35mm', 'werkzeug', 'Set', 480.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-007', 'Rohrzange 1" Knipex', 'werkzeug', 'Stk', 45.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-008', 'Rohrzange 1.5" Knipex', 'werkzeug', 'Stk', 55.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-009', 'Rohrzange 2" Knipex', 'werkzeug', 'Stk', 65.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-010', 'Wasserpumpenzange 250mm', 'werkzeug', 'Stk', 32.00, 0, 4, 'werkzeug', false),
    (v_user_id, 'WKZ-011', 'Wasserpumpenzange 300mm', 'werkzeug', 'Stk', 38.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-012', 'Gewindeschneider-Set 1/2"-1"', 'werkzeug', 'Set', 220.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-013', 'Biegefedern-Set Cu 12-22mm', 'werkzeug', 'Set', 45.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-014', 'Rohrbiegemaschine 15-22mm', 'werkzeug', 'Stk', 280.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-015', 'Aufweitzange 12-22mm', 'werkzeug', 'Stk', 65.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-016', 'Bohrmaschine Hilti TE30', 'werkzeug', 'Stk', 850.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-017', 'Akkuschrauber Hilti SF6', 'werkzeug', 'Stk', 420.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-018', 'Winkelschleifer 125mm Bosch', 'werkzeug', 'Stk', 180.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-019', 'Stichsaege Bosch', 'werkzeug', 'Stk', 220.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-020', 'Kernbohrmaschine Hilti DD150', 'werkzeug', 'Stk', 2400.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-021', 'Kernbohrkronen-Set 32-82mm', 'werkzeug', 'Set', 350.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-022', 'Abfluss-Spirale 8mm x 7.5m', 'werkzeug', 'Stk', 45.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-023', 'Abfluss-Spirale 10mm x 15m elektrisch', 'werkzeug', 'Stk', 380.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-024', 'Kamera-Endoskop USB', 'werkzeug', 'Stk', 120.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-025', 'Lecksuch-Set (Druckpruefung)', 'werkzeug', 'Set', 280.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-026', 'Manometer-Set 0-16bar', 'werkzeug', 'Set', 85.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-027', 'Infrarot-Thermometer', 'werkzeug', 'Stk', 65.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-028', 'Wasserwaage 60cm', 'werkzeug', 'Stk', 35.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-029', 'Wasserwaage 120cm', 'werkzeug', 'Stk', 55.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-030', 'Laser-Nivelliergeraet', 'werkzeug', 'Stk', 280.00, 0, 1, 'werkzeug', false),
    (v_user_id, 'WKZ-031', 'Bandmass 5m', 'werkzeug', 'Stk', 12.00, 0, 5, 'werkzeug', false),
    (v_user_id, 'WKZ-032', 'Bandmass 8m', 'werkzeug', 'Stk', 18.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-033', 'Stemmeisen-Set 3-tlg', 'werkzeug', 'Set', 35.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-034', 'Gummihammer 500g', 'werkzeug', 'Stk', 15.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-035', 'Schlosserhammer 500g', 'werkzeug', 'Stk', 18.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-036', 'Schraubenschluessel-Set 6-32mm', 'werkzeug', 'Set', 85.00, 0, 2, 'werkzeug', false),
    (v_user_id, 'WKZ-037', 'Inbus-Schluessel-Set', 'werkzeug', 'Set', 22.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-038', 'Spitzzange 200mm', 'werkzeug', 'Stk', 18.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-039', 'Seitenschneider 180mm', 'werkzeug', 'Stk', 22.00, 0, 3, 'werkzeug', false),
    (v_user_id, 'WKZ-040', 'Abisolierzange', 'werkzeug', 'Stk', 28.00, 0, 2, 'werkzeug', false);

  -- === VERBRAUCH (~40 Stueck) ===
  INSERT INTO artikel (user_id, artikel_nr, bezeichnung, kategorie, einheit, einkaufspreis, verkaufspreis, mindestbestand, material_typ, is_deleted) VALUES
    (v_user_id, 'VER-001', 'Loetzinn Sn97Cu3 250g', 'verbrauch', 'Stk', 32.00, 53.00, 10, 'verbrauch', false),
    (v_user_id, 'VER-002', 'Loetzinn Sn97Cu3 500g', 'verbrauch', 'Stk', 55.00, 92.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-003', 'Flussmittel Cu-Rosolux 250ml', 'verbrauch', 'Stk', 12.00, 20.00, 10, 'verbrauch', false),
    (v_user_id, 'VER-004', 'Propan Kartusche 450g', 'verbrauch', 'Stk', 8.50, 14.20, 20, 'verbrauch', false),
    (v_user_id, 'VER-005', 'Hanf Dichtfaser 100g', 'verbrauch', 'Stk', 3.20, 5.30, 20, 'verbrauch', false),
    (v_user_id, 'VER-006', 'PTFE-Band 12mm x 12m', 'verbrauch', 'Stk', 1.80, 3.00, 50, 'verbrauch', false),
    (v_user_id, 'VER-007', 'Silikon sanitaer weiss 310ml', 'verbrauch', 'Stk', 6.50, 10.80, 20, 'verbrauch', false),
    (v_user_id, 'VER-008', 'Silikon sanitaer transparent 310ml', 'verbrauch', 'Stk', 7.20, 12.00, 15, 'verbrauch', false),
    (v_user_id, 'VER-009', 'Acryl weiss 310ml', 'verbrauch', 'Stk', 4.50, 7.50, 15, 'verbrauch', false),
    (v_user_id, 'VER-010', 'PVC Kleber 500ml', 'verbrauch', 'Stk', 18.00, 30.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-011', 'PVC Reiniger 500ml', 'verbrauch', 'Stk', 12.00, 20.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-012', 'Rohrreiniger Drano 1L', 'verbrauch', 'Stk', 8.00, 13.30, 10, 'verbrauch', false),
    (v_user_id, 'VER-013', 'Kalkentferner 1L', 'verbrauch', 'Stk', 9.50, 15.80, 10, 'verbrauch', false),
    (v_user_id, 'VER-014', 'Schleifvlies rot fein', 'verbrauch', 'Stk', 2.80, 4.70, 20, 'verbrauch', false),
    (v_user_id, 'VER-015', 'Schleifpapier 120er Rolle', 'verbrauch', 'Stk', 5.50, 9.20, 10, 'verbrauch', false),
    (v_user_id, 'VER-016', 'Duebel 8mm x 40mm 100er Pack', 'verbrauch', 'Pk', 8.50, 14.20, 10, 'verbrauch', false),
    (v_user_id, 'VER-017', 'Duebel 10mm x 50mm 50er Pack', 'verbrauch', 'Pk', 7.00, 11.70, 10, 'verbrauch', false),
    (v_user_id, 'VER-018', 'Schrauben 5x50mm V2A 100er Pack', 'verbrauch', 'Pk', 12.00, 20.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-019', 'Schrauben 6x60mm V2A 100er Pack', 'verbrauch', 'Pk', 15.00, 25.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-020', 'Stockschrauben M8x80 25er Pack', 'verbrauch', 'Pk', 8.00, 13.30, 5, 'verbrauch', false),
    (v_user_id, 'VER-021', 'Bohrer-Set SDS 5-12mm', 'verbrauch', 'Set', 25.00, 42.00, 3, 'verbrauch', false),
    (v_user_id, 'VER-022', 'Bohrer-Set HSS 1-10mm', 'verbrauch', 'Set', 18.00, 30.00, 3, 'verbrauch', false),
    (v_user_id, 'VER-023', 'Trennscheibe Metall 125mm 10er Pack', 'verbrauch', 'Pk', 12.00, 20.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-024', 'Handschuhe Nitril L 100er Box', 'verbrauch', 'Box', 12.00, 20.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-025', 'Schutzbrille klar', 'verbrauch', 'Stk', 8.00, 13.30, 5, 'verbrauch', false),
    (v_user_id, 'VER-026', 'Gehoerschutz 3M Peltor', 'verbrauch', 'Stk', 28.00, 0, 3, 'verbrauch', false),
    (v_user_id, 'VER-027', 'Staubmaske FFP2 20er Pack', 'verbrauch', 'Pk', 18.00, 0, 3, 'verbrauch', false),
    (v_user_id, 'VER-028', 'Abdeckvlies 1x25m', 'verbrauch', 'Stk', 15.00, 25.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-029', 'Abdeckfolie 4x5m', 'verbrauch', 'Stk', 5.00, 8.30, 10, 'verbrauch', false),
    (v_user_id, 'VER-030', 'Malerklebeband 50mm x 50m', 'verbrauch', 'Stk', 4.50, 7.50, 10, 'verbrauch', false),
    (v_user_id, 'VER-031', 'Kabelbinder 200mm 100er Pack', 'verbrauch', 'Pk', 5.50, 9.20, 5, 'verbrauch', false),
    (v_user_id, 'VER-032', 'Isolierband schwarz 19mm', 'verbrauch', 'Stk', 2.50, 4.20, 10, 'verbrauch', false),
    (v_user_id, 'VER-033', 'Universalreiniger 5L', 'verbrauch', 'Stk', 12.00, 20.00, 3, 'verbrauch', false),
    (v_user_id, 'VER-034', 'Entfettungsmittel 1L', 'verbrauch', 'Stk', 8.50, 14.20, 5, 'verbrauch', false),
    (v_user_id, 'VER-035', 'Absperrband rot/weiss 80mm x 500m', 'verbrauch', 'Stk', 8.00, 13.30, 3, 'verbrauch', false),
    (v_user_id, 'VER-036', 'Montageschaum 750ml', 'verbrauch', 'Stk', 6.50, 10.80, 5, 'verbrauch', false),
    (v_user_id, 'VER-037', 'Brandschutzmoertel 5kg', 'verbrauch', 'Stk', 25.00, 42.00, 3, 'verbrauch', false),
    (v_user_id, 'VER-038', 'Korrosionsschutzband 50mm x 10m', 'verbrauch', 'Stk', 12.00, 20.00, 5, 'verbrauch', false),
    (v_user_id, 'VER-039', 'Gewindeschneidoel 1L', 'verbrauch', 'Stk', 18.00, 30.00, 3, 'verbrauch', false),
    (v_user_id, 'VER-040', 'Kupferspray 400ml', 'verbrauch', 'Stk', 12.00, 20.00, 5, 'verbrauch', false);

  RAISE NOTICE 'Artikel angelegt: %', (SELECT COUNT(*) FROM artikel WHERE user_id = v_user_id);

  -- ========================================================================
  -- ARTIKEL-LIEFERANTEN (~150 Zuordnungen)
  -- ========================================================================
  -- Rohre -> Pestalozzi (Hauptlieferant), teilweise Tobler
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_pestalozzi, a.einkaufspreis, 'PES-' || a.artikel_nr, 3, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'ROH-%';

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_tobler, a.einkaufspreis * 1.05, 'TOB-' || a.artikel_nr, 2, false
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr IN ('ROH-001','ROH-002','ROH-003','ROH-006','ROH-007','ROH-008');

  -- Fittings -> Pestalozzi + Geberit fuer Mapress
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_pestalozzi, a.einkaufspreis, 'PES-' || a.artikel_nr, 3, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'FIT-%' AND a.artikel_nr NOT LIKE 'FIT-009' AND a.artikel_nr NOT LIKE 'FIT-01_' AND a.artikel_nr NOT LIKE 'FIT-012';

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_geberit, a.einkaufspreis, 'GEB-' || a.artikel_nr, 5, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr IN ('FIT-009','FIT-010','FIT-011','FIT-012');

  -- Armaturen -> Nussbaum (Hauptlieferant)
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_nussbaum, a.einkaufspreis, 'NUS-' || a.artikel_nr, 4, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'ARM-%';

  -- Sanitaer-Keramik -> Sanitas Troesch (Hauptlieferant), Geberit fuer Geberit-Produkte
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_sanitas, a.einkaufspreis, 'SAN-' || a.artikel_nr, 5, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'SAN-%' AND a.bezeichnung NOT LIKE '%Geberit%';

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_geberit, a.einkaufspreis, 'GEB-' || a.artikel_nr, 5, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'SAN-%' AND a.bezeichnung LIKE '%Geberit%';

  -- Boiler -> Stiebel Eltron (Hauptlieferant)
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_stiebel, a.einkaufspreis, 'STI-' || a.artikel_nr, 7, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'BOI-%';

  -- Dichtungen -> Tobler (Hauptlieferant)
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_tobler, a.einkaufspreis, 'TOB-' || a.artikel_nr, 2, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'DIC-%';

  -- Heizung -> Tobler (Hauptlieferant)
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_tobler, a.einkaufspreis, 'TOB-' || a.artikel_nr, 5, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'HEI-%';

  -- Diverses Material -> Geberit + Tobler
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_geberit, a.einkaufspreis, 'GEB-' || a.artikel_nr, 5, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr IN ('DIV-001','DIV-002');

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_tobler, a.einkaufspreis, 'TOB-' || a.artikel_nr, 4, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'DIV-%' AND a.artikel_nr NOT IN ('DIV-001','DIV-002');

  -- Werkzeug -> Debrunner Acifer + Wuerth
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_debrunner, a.einkaufspreis, 'DA-' || a.artikel_nr, 3, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'WKZ-%' AND CAST(REPLACE(a.artikel_nr, 'WKZ-', '') AS INTEGER) <= 20;

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_wuerth, a.einkaufspreis, 'WUE-' || a.artikel_nr, 2, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'WKZ-%' AND CAST(REPLACE(a.artikel_nr, 'WKZ-', '') AS INTEGER) > 20;

  -- Verbrauch -> Wuerth (Hauptlieferant fuer Befestigung), Tobler fuer chemische Produkte
  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_wuerth, a.einkaufspreis, 'WUE-' || a.artikel_nr, 2, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'VER-%' AND CAST(REPLACE(a.artikel_nr, 'VER-', '') AS INTEGER) >= 16;

  INSERT INTO artikel_lieferanten (user_id, artikel_id, lieferant_id, einkaufspreis, lieferanten_artikel_nr, lieferzeit_tage, ist_hauptlieferant)
  SELECT v_user_id, a.id, v_lieferant_tobler, a.einkaufspreis, 'TOB-' || a.artikel_nr, 3, true
  FROM artikel a WHERE a.user_id = v_user_id AND a.artikel_nr LIKE 'VER-%' AND CAST(REPLACE(a.artikel_nr, 'VER-', '') AS INTEGER) < 16;

  RAISE NOTICE 'Artikel-Lieferanten angelegt: %', (SELECT COUNT(*) FROM artikel_lieferanten WHERE user_id = v_user_id);

  -- ========================================================================
  -- LAGERBESTAENDE (Material im Hauptlager, einiges im Fahrzeug)
  -- ========================================================================
  -- Hauptlager: alle Material-Artikel mit realistischem Bestand
  INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
  SELECT v_user_id, a.id, v_lagerort_haupt,
    CASE
      WHEN a.mindestbestand > 0 THEN a.mindestbestand * (1.2 + random() * 0.8)
      ELSE (1 + random() * 3)::int
    END
  FROM artikel a
  WHERE a.user_id = v_user_id AND a.kategorie = 'material';

  -- Servicefahrzeug 1: gaengige Teile
  INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
  SELECT v_user_id, a.id, v_lagerort_sf1, (2 + random() * 8)::int
  FROM artikel a
  WHERE a.user_id = v_user_id AND a.artikel_nr IN (
    'ROH-001','ROH-002','ROH-003','ROH-009','ROH-010','ROH-016','ROH-017',
    'FIT-001','FIT-002','FIT-003','FIT-004','FIT-005','FIT-008','FIT-020','FIT-021',
    'ARM-010','ARM-012','DIC-001','DIC-002','DIC-004','DIC-005','DIC-006',
    'VER-001','VER-003','VER-004','VER-006','VER-007'
  );

  -- Servicefahrzeug 2: gaengige Teile
  INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
  SELECT v_user_id, a.id, v_lagerort_sf2, (2 + random() * 8)::int
  FROM artikel a
  WHERE a.user_id = v_user_id AND a.artikel_nr IN (
    'ROH-001','ROH-002','ROH-003','ROH-009','ROH-010','ROH-016','ROH-017',
    'FIT-001','FIT-002','FIT-003','FIT-004','FIT-005','FIT-008','FIT-020','FIT-021',
    'ARM-010','ARM-012','DIC-001','DIC-002','DIC-004','DIC-005','DIC-006',
    'VER-001','VER-003','VER-004','VER-006','VER-007'
  );

  -- Werkzeug im Hauptlager (je 1-3 Stueck)
  INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
  SELECT v_user_id, a.id, v_lagerort_haupt, (1 + random() * 2)::int
  FROM artikel a WHERE a.user_id = v_user_id AND a.kategorie = 'werkzeug';

  -- Verbrauch im Hauptlager
  INSERT INTO lagerbestaende (user_id, artikel_id, lagerort_id, menge)
  SELECT v_user_id, a.id, v_lagerort_haupt,
    CASE WHEN a.mindestbestand > 0 THEN a.mindestbestand * (1.0 + random() * 1.5) ELSE (2 + random() * 5)::int END
  FROM artikel a WHERE a.user_id = v_user_id AND a.kategorie = 'verbrauch';

  -- Gesamt-Lagerbestand auf Artikel aktualisieren
  UPDATE artikel SET lagerbestand = (
    SELECT COALESCE(SUM(lb.menge), 0)
    FROM lagerbestaende lb WHERE lb.artikel_id = artikel.id
  )
  WHERE user_id = v_user_id;

  RAISE NOTICE 'Lagerbestaende angelegt: %', (SELECT COUNT(*) FROM lagerbestaende WHERE user_id = v_user_id);
  RAISE NOTICE '=== Testdaten 02 Artikel FERTIG ===';
END;
$$;

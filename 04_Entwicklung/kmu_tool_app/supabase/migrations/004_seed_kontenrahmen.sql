-- ============================================================================
-- KMU Tool - Migration 004: Seed Kontenrahmen
-- Schweizer KMU-Kontenrahmen angepasst fuer Handwerksbetriebe (GmbH)
-- Basiert auf dem Schweizer Kontenrahmen KMU (Kaefersche Methode)
-- ============================================================================

-- Funktion zum Anlegen des Kontenrahmens fuer einen neuen Benutzer
CREATE OR REPLACE FUNCTION seed_kontenrahmen(p_user_id UUID)
RETURNS void AS $$
BEGIN
  -- ======================================================================
  -- KLASSE 1: AKTIVEN (Vermoegen)
  -- ======================================================================

  -- Umlaufvermoegen
  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 1000, 'Kasse',                          'aktiv'),
    (p_user_id, 1020, 'Bank (Geschaeftskonto)',          'aktiv'),
    (p_user_id, 1040, 'Postfinance',                     'aktiv'),
    (p_user_id, 1100, 'Debitoren (Forderungen L+L)',     'aktiv'),
    (p_user_id, 1109, 'Delkredere (Wertberichtigung)',   'aktiv'),
    (p_user_id, 1170, 'Vorsteuer MWST',                  'aktiv'),
    (p_user_id, 1176, 'Verrechnungssteuer',               'aktiv'),
    (p_user_id, 1200, 'Materialvorrat',                   'aktiv'),
    (p_user_id, 1210, 'Angefangene Arbeiten',             'aktiv'),
    (p_user_id, 1300, 'Aktive Rechnungsabgrenzung',       'aktiv'),

  -- Anlagevermoegen
    (p_user_id, 1500, 'Maschinen und Geraete',            'aktiv'),
    (p_user_id, 1510, 'Werkzeuge',                         'aktiv'),
    (p_user_id, 1520, 'Fahrzeuge',                         'aktiv'),
    (p_user_id, 1530, 'Mobiliar und Einrichtungen',        'aktiv'),
    (p_user_id, 1540, 'EDV-Anlagen und Software',          'aktiv'),
    (p_user_id, 1600, 'Immobilien (Werkstatt/Buero)',      'aktiv');

  -- ======================================================================
  -- KLASSE 2: PASSIVEN (Schulden und Eigenkapital)
  -- ======================================================================

  -- Kurzfristiges Fremdkapital
  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 2000, 'Kreditoren (Verbindlichkeiten L+L)', 'passiv'),
    (p_user_id, 2030, 'Kontokorrent Kreditkarte',            'passiv'),
    (p_user_id, 2100, 'Bankverbindlichkeiten kurzfristig',   'passiv'),
    (p_user_id, 2200, 'MWST-Schuld (Umsatzsteuer)',          'passiv'),
    (p_user_id, 2206, 'Verrechnungssteuer-Schuld',           'passiv'),
    (p_user_id, 2210, 'Direkte Steuern (Gewinnsteuer)',      'passiv'),
    (p_user_id, 2270, 'Sozialversicherungen (AHV/IV/EO)',    'passiv'),
    (p_user_id, 2271, 'BVG-Verbindlichkeiten',               'passiv'),
    (p_user_id, 2279, 'Quellensteuer',                        'passiv'),
    (p_user_id, 2300, 'Passive Rechnungsabgrenzung',          'passiv'),

  -- Langfristiges Fremdkapital
    (p_user_id, 2400, 'Bankdarlehen langfristig',            'passiv'),
    (p_user_id, 2450, 'Gesellschafterdarlehen',               'passiv'),

  -- Eigenkapital (GmbH-spezifisch)
    (p_user_id, 2800, 'Stammkapital GmbH',                   'passiv'),
    (p_user_id, 2900, 'Gesetzliche Gewinnreserve',            'passiv'),
    (p_user_id, 2950, 'Gewinnvortrag / Verlustvortrag',       'passiv'),
    (p_user_id, 2979, 'Jahresgewinn / Jahresverlust',         'passiv');

  -- ======================================================================
  -- KLASSE 3: BETRIEBLICHER ERTRAG AUS L+L
  -- ======================================================================

  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 3000, 'Dienstleistungsertrag Handwerk',      'ertrag'),
    (p_user_id, 3200, 'Materialertrag (weiterverrechnet)',    'ertrag'),
    (p_user_id, 3400, 'Nebenertrag (Kleinarbeiten)',          'ertrag'),
    (p_user_id, 3600, 'Sonstige Ertraege',                    'ertrag'),
    (p_user_id, 3800, 'Erloesminderungen (Rabatte/Skonti)',   'ertrag'),
    (p_user_id, 3900, 'Bestandesaenderungen angefangene Arbeiten', 'ertrag');

  -- ======================================================================
  -- KLASSE 4: AUFWAND MATERIAL UND FREMDLEISTUNGEN
  -- ======================================================================

  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 4000, 'Materialaufwand',                      'aufwand'),
    (p_user_id, 4200, 'Fremdleistungen (Subunternehmer)',     'aufwand'),
    (p_user_id, 4400, 'Bestandesaenderung Material',          'aufwand'),
    (p_user_id, 4900, 'Skonti und Rabatte (Einkauf)',         'aufwand');

  -- ======================================================================
  -- KLASSE 5: PERSONALAUFWAND
  -- ======================================================================

  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 5000, 'Lohnaufwand',                          'aufwand'),
    (p_user_id, 5200, 'Lohnaufwand Inhaber/Geschaeftsfuehrung', 'aufwand'),
    (p_user_id, 5700, 'AHV/IV/EO/ALV (Arbeitgeberanteil)',    'aufwand'),
    (p_user_id, 5710, 'BVG (Arbeitgeberanteil)',               'aufwand'),
    (p_user_id, 5720, 'UVG/KTG (Unfallversicherung)',          'aufwand'),
    (p_user_id, 5730, 'FAK (Familienzulagen)',                  'aufwand'),
    (p_user_id, 5800, 'Spesen und Entschaedigungen',            'aufwand'),
    (p_user_id, 5900, 'Uebriger Personalaufwand',               'aufwand');

  -- ======================================================================
  -- KLASSE 6: SONSTIGER BETRIEBSAUFWAND
  -- ======================================================================

  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 6000, 'Raumaufwand (Miete Werkstatt/Buero)',  'aufwand'),
    (p_user_id, 6050, 'Nebenkosten (Strom/Wasser/Heizung)',   'aufwand'),
    (p_user_id, 6100, 'Unterhalt und Reparaturen',            'aufwand'),
    (p_user_id, 6105, 'Unterhalt Maschinen und Werkzeuge',    'aufwand'),
    (p_user_id, 6200, 'Fahrzeugaufwand',                       'aufwand'),
    (p_user_id, 6210, 'Treibstoff',                            'aufwand'),
    (p_user_id, 6220, 'Fahrzeugversicherungen',                'aufwand'),
    (p_user_id, 6300, 'Sachversicherungen',                    'aufwand'),
    (p_user_id, 6310, 'Berufshaftpflichtversicherung',         'aufwand'),
    (p_user_id, 6400, 'Energieaufwand Werkstatt',              'aufwand'),
    (p_user_id, 6500, 'Bueroaufwand (Material/Porto)',         'aufwand'),
    (p_user_id, 6510, 'Telefon und Internet',                  'aufwand'),
    (p_user_id, 6520, 'Software und Lizenzen',                 'aufwand'),
    (p_user_id, 6530, 'Buchfuehrung und Beratung',             'aufwand'),
    (p_user_id, 6600, 'Werbeaufwand',                           'aufwand'),
    (p_user_id, 6700, 'Sonstiger Betriebsaufwand',             'aufwand'),
    (p_user_id, 6800, 'Abschreibungen Sachanlagen',            'aufwand'),
    (p_user_id, 6810, 'Abschreibungen Fahrzeuge',              'aufwand'),
    (p_user_id, 6820, 'Abschreibungen Maschinen/Werkzeuge',    'aufwand'),
    (p_user_id, 6900, 'Finanzaufwand (Bankzinsen/Gebuehren)',  'aufwand'),
    (p_user_id, 6940, 'Kursverluste',                           'aufwand'),
    (p_user_id, 6950, 'Finanzertrag (Bankzinsen)',              'ertrag');

  -- ======================================================================
  -- KLASSE 8: AUSSERORDENTLICHER / BETRIEBSFREMDER ERFOLG
  -- ======================================================================

  INSERT INTO konten (user_id, kontonummer, bezeichnung, typ) VALUES
    (p_user_id, 8000, 'Ausserordentlicher Ertrag',            'ertrag'),
    (p_user_id, 8100, 'Betriebsfremder Ertrag',               'ertrag'),
    (p_user_id, 8500, 'Ausserordentlicher Aufwand',           'aufwand'),
    (p_user_id, 8510, 'Betriebsfremder Aufwand',              'aufwand'),
    (p_user_id, 8900, 'Direkte Steuern (Gewinnsteuer)',       'aufwand');

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION seed_kontenrahmen(UUID)
  IS 'Legt den vollstaendigen Schweizer KMU-Kontenrahmen fuer Handwerksbetriebe (GmbH) an';

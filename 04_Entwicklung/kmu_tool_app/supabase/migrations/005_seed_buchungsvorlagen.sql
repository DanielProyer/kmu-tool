-- ============================================================================
-- KMU Tool - Migration 005: Seed Buchungsvorlagen
-- Standard-Buchungsvorlagen fuer typische Geschaeftsvorfaelle
-- eines Schweizer Handwerksbetriebs (GmbH)
-- ============================================================================

-- Funktion zum Anlegen der Standard-Buchungsvorlagen fuer einen Benutzer
CREATE OR REPLACE FUNCTION seed_buchungsvorlagen(p_user_id UUID)
RETURNS void AS $$
BEGIN

  -- ======================================================================
  -- RECHNUNGS-AUTOMATIK (auto_trigger)
  -- Diese Vorlagen werden automatisch beim Statuswechsel einer Rechnung
  -- durch die Applikationslogik ausgeloest.
  -- ======================================================================

  -- Rechnung erstellt (Nettobetrag): Debitor belastet, Ertrag gutgeschrieben
  -- Buchungssatz: Debitoren an Dienstleistungsertrag
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'rechnung_erstellt',
    'Rechnung erstellt (Nettobetrag)',
    1100,   -- Soll: Debitoren
    3000,   -- Haben: Dienstleistungsertrag Handwerk
    'rechnung_erstellt'
  );

  -- Rechnung erstellt (MWST-Anteil): Debitor belastet, MWST-Schuld gutgeschrieben
  -- Buchungssatz: Debitoren an MWST-Schuld
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'rechnung_erstellt_mwst',
    'Rechnung erstellt (MWST-Anteil)',
    1100,   -- Soll: Debitoren
    2200,   -- Haben: MWST-Schuld
    'rechnung_erstellt'
  );

  -- Rechnung bezahlt: Bank-Eingang, Debitor ausgeglichen
  -- Buchungssatz: Bank an Debitoren
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'rechnung_bezahlt',
    'Zahlungseingang Rechnung',
    1020,   -- Soll: Bank
    1100,   -- Haben: Debitoren
    'rechnung_bezahlt'
  );

  -- Rechnung storniert (Nettobetrag): Umkehrbuchung der Erstellung
  -- Buchungssatz: Dienstleistungsertrag an Debitoren
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'rechnung_storniert',
    'Rechnung storniert (Nettobetrag)',
    3000,   -- Soll: Dienstleistungsertrag Handwerk
    1100,   -- Haben: Debitoren
    'rechnung_storniert'
  );

  -- Rechnung storniert (MWST-Anteil): Umkehrbuchung der MWST
  -- Buchungssatz: MWST-Schuld an Debitoren
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'rechnung_storniert_mwst',
    'Rechnung storniert (MWST-Anteil)',
    2200,   -- Soll: MWST-Schuld
    1100,   -- Haben: Debitoren
    'rechnung_storniert'
  );

  -- ======================================================================
  -- MANUELLE BUCHUNGSVORLAGEN (kein auto_trigger)
  -- Diese Vorlagen koennen vom Benutzer manuell ausgewaehlt werden,
  -- um haeufige Geschaeftsvorfaelle schnell zu buchen.
  -- ======================================================================

  -- Materialeinkauf bar
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'materialeinkauf_bar',
    'Materialeinkauf bar bezahlt',
    4000,   -- Soll: Materialaufwand
    1000,   -- Haben: Kasse
    NULL
  );

  -- Materialeinkauf auf Rechnung
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'materialeinkauf_rechnung',
    'Materialeinkauf auf Rechnung',
    4000,   -- Soll: Materialaufwand
    2000,   -- Haben: Kreditoren
    NULL
  );

  -- Vorsteuer auf Einkauf
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'vorsteuer_einkauf',
    'Vorsteuer auf Einkauf',
    1170,   -- Soll: Vorsteuer MWST
    2000,   -- Haben: Kreditoren
    NULL
  );

  -- Kreditor bezahlt (Lieferantenrechnung)
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'kreditor_bezahlt',
    'Lieferantenrechnung bezahlt',
    2000,   -- Soll: Kreditoren
    1020,   -- Haben: Bank
    NULL
  );

  -- Lohnzahlung
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'lohn_zahlung',
    'Lohnzahlung Mitarbeiter',
    5000,   -- Soll: Lohnaufwand
    1020,   -- Haben: Bank
    NULL
  );

  -- Sozialversicherungsbeitraege
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'sozialversicherung',
    'AHV/IV/EO Arbeitgeberanteil',
    5700,   -- Soll: Sozialversicherungen
    2270,   -- Haben: SV-Verbindlichkeiten
    NULL
  );

  -- Miete Werkstatt/Buero
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'miete_zahlung',
    'Miete Werkstatt / Buero',
    6000,   -- Soll: Raumaufwand
    1020,   -- Haben: Bank
    NULL
  );

  -- Fahrzeugkosten (Treibstoff)
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'treibstoff',
    'Treibstoff Firmenfahrzeug',
    6210,   -- Soll: Treibstoff
    1000,   -- Haben: Kasse
    NULL
  );

  -- Versicherungspraemie
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'versicherung',
    'Versicherungspraemie',
    6300,   -- Soll: Sachversicherungen
    1020,   -- Haben: Bank
    NULL
  );

  -- Telefonrechnung / Internet
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'telefon_internet',
    'Telefon / Internet',
    6510,   -- Soll: Telefon und Internet
    1020,   -- Haben: Bank
    NULL
  );

  -- Fremdleistung (Subunternehmer)
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'fremdleistung',
    'Fremdleistung / Subunternehmer',
    4200,   -- Soll: Fremdleistungen
    2000,   -- Haben: Kreditoren
    NULL
  );

  -- Bankgebuehren
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'bankgebuehren',
    'Bankgebuehren und Spesen',
    6900,   -- Soll: Finanzaufwand
    1020,   -- Haben: Bank
    NULL
  );

  -- MWST-Abrechnung (Zahlung ans Steueramt)
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'mwst_zahlung',
    'MWST-Zahlung ans Steueramt',
    2200,   -- Soll: MWST-Schuld
    1020,   -- Haben: Bank
    NULL
  );

  -- Privatentnahme Inhaber
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'inhaberlohn',
    'Lohn Geschaeftsfuehrer/Inhaber',
    5200,   -- Soll: Lohnaufwand Inhaber
    1020,   -- Haben: Bank
    NULL
  );

  -- Abschreibung Werkzeuge/Maschinen
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'abschreibung_maschinen',
    'Abschreibung Maschinen/Werkzeuge',
    6820,   -- Soll: Abschreibungen Maschinen
    1500,   -- Haben: Maschinen und Geraete
    NULL
  );

  -- Abschreibung Fahrzeuge
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'abschreibung_fahrzeuge',
    'Abschreibung Fahrzeuge',
    6810,   -- Soll: Abschreibungen Fahrzeuge
    1520,   -- Haben: Fahrzeuge
    NULL
  );

  -- Bareinzahlung auf Bank
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'bareinzahlung_bank',
    'Bareinzahlung auf Bank',
    1020,   -- Soll: Bank
    1000,   -- Haben: Kasse
    NULL
  );

  -- Barbezug von Bank
  INSERT INTO buchungs_vorlagen (
    user_id, geschaeftsfall_id, bezeichnung,
    soll_konto, haben_konto, auto_trigger
  ) VALUES (
    p_user_id,
    'barbezug',
    'Barbezug vom Bankkonto',
    1000,   -- Soll: Kasse
    1020,   -- Haben: Bank
    NULL
  );

END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION seed_buchungsvorlagen(UUID)
  IS 'Legt Standard-Buchungsvorlagen fuer typische Handwerker-Geschaeftsvorfaelle an';

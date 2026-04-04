-- ============================================================================
-- KMU Tool - Testdaten 04: Buchungen (Doppelte Buchhaltung) + MWST
-- Proyer Sanitaer GmbH
-- ============================================================================
-- Abhaengigkeit: testdaten_01-03 muessen zuerst ausgefuehrt werden
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_rechnung_id UUID;
  v_datum DATE;
  v_netto NUMERIC(12,2);
  v_mwst NUMERIC(12,2);
  v_brutto NUMERIC(12,2);
  v_status TEXT;
  v_beleg_nr INTEGER := 100;
  v_monat INTEGER;
  v_jahr INTEGER;
  i INTEGER;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  -- Bestehende Buchungen loeschen
  DELETE FROM buchungen WHERE user_id = v_user_id;
  DELETE FROM mwst_abrechnungen WHERE user_id = v_user_id;

  -- Konten-Salden zuruecksetzen
  UPDATE konten SET saldo = 0 WHERE user_id = v_user_id;

  -- ========================================================================
  -- A) RECHNUNGSSTELLUNG + ZAHLUNGSEINGANG
  -- Fuer jede Rechnung: Soll 1100 / Haben 3000 (Netto)
  --                     Soll 1100 / Haben 2200 (MWST)
  -- Bei Zahlung:        Soll 1020 / Haben 1100 (Brutto)
  -- ========================================================================
  FOR v_rechnung_id, v_datum, v_netto, v_mwst, v_brutto, v_status IN
    SELECT r.id, r.datum, r.total_netto, r.mwst_betrag, r.total_brutto, r.status
    FROM rechnungen r WHERE r.user_id = v_user_id
    ORDER BY r.datum
  LOOP
    v_beleg_nr := v_beleg_nr + 1;

    -- Rechnungsstellung: Debitoren an Ertrag (Netto)
    INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id, mwst_code, mwst_satz, mwst_betrag)
    VALUES (v_user_id, v_datum, 1100, 3000, v_netto,
            'Rechnung ' || (SELECT rechnungs_nr FROM rechnungen WHERE id = v_rechnung_id),
            'BLG-' || v_beleg_nr, v_rechnung_id, 'UST_NORM', 8.10, v_mwst);

    -- Rechnungsstellung: Debitoren an MWST-Schuld (MWST)
    IF v_mwst > 0 THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum, 1100, 2200, v_mwst,
              'MWST Rechnung ' || (SELECT rechnungs_nr FROM rechnungen WHERE id = v_rechnung_id),
              'BLG-' || v_beleg_nr || 'M', v_rechnung_id);
    END IF;

    -- Zahlungseingang bei bezahlten Rechnungen
    IF v_status = 'bezahlt' THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum + (15 + random() * 25)::int, 1020, 1100, v_brutto,
              'Zahlungseingang ' || (SELECT rechnungs_nr FROM rechnungen WHERE id = v_rechnung_id),
              'BLG-' || v_beleg_nr || 'Z', v_rechnung_id);
    END IF;
  END LOOP;

  RAISE NOTICE 'Rechnungs-Buchungen erstellt';

  -- ========================================================================
  -- B) MATERIALEINKAUF (monatlich, ~3-5 Buchungen/Monat)
  -- Soll 4000 / Haben 2000 (Materialaufwand an Kreditoren)
  -- Soll 1170 / Haben 2000 (Vorsteuer)
  -- Soll 2000 / Haben 1020 (Kreditor bezahlt)
  -- ========================================================================
  FOR v_jahr IN 2024..2026 LOOP
    FOR v_monat IN 1..CASE WHEN v_jahr = 2026 THEN 3 ELSE 12 END LOOP
      FOR i IN 1..(3 + (random() * 2)::int) LOOP
        v_beleg_nr := v_beleg_nr + 1;
        v_datum := make_date(v_jahr, v_monat, (5 + random() * 20)::int);
        v_netto := (800 + random() * 4000)::numeric(12,2);
        v_mwst := ROUND(v_netto * 0.081, 2);

        -- Materialaufwand (netto)
        INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, mwst_code, mwst_satz, mwst_betrag)
        VALUES (v_user_id, v_datum, 4000, 2000, v_netto,
                'Materialeinkauf ' || CASE (random() * 7)::int
                  WHEN 0 THEN 'Geberit AG'
                  WHEN 1 THEN 'R. Nussbaum AG'
                  WHEN 2 THEN 'Stiebel Eltron AG'
                  WHEN 3 THEN 'Tobler Haustechnik'
                  WHEN 4 THEN 'Sanitas Troesch AG'
                  WHEN 5 THEN 'Pestalozzi + Co'
                  WHEN 6 THEN 'Debrunner Acifer'
                  ELSE 'Wuerth AG'
                END,
                'BLG-' || v_beleg_nr, 'VST_NORM', 8.10, v_mwst);

        -- Vorsteuer
        INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
        VALUES (v_user_id, v_datum, 1170, 2000, v_mwst,
                'Vorsteuer Material', 'BLG-' || v_beleg_nr || 'V');

        -- Zahlung (30 Tage spaeter)
        IF v_datum + 30 < CURRENT_DATE THEN
          INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
          VALUES (v_user_id, v_datum + 30, 2000, 1020, v_netto + v_mwst,
                  'Zahlung Lieferantenrechnung', 'BLG-' || v_beleg_nr || 'Z');
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Material-Buchungen erstellt';

  -- ========================================================================
  -- C) PERSONALAUFWAND (monatlich)
  -- Loehne: Soll 5000 / Haben 1020 (Lohnzahlung)
  -- SV AG: Soll 5700 / Haben 2270 (AHV/ALV AG)
  -- BVG AG: Soll 5710 / Haben 2271
  -- UVG: Soll 5720 / Haben 2270
  -- Inhaberlohn: Soll 5200 / Haben 1020
  -- ========================================================================
  FOR v_jahr IN 2024..2026 LOOP
    FOR v_monat IN 1..CASE WHEN v_jahr = 2026 THEN 3 ELSE 12 END LOOP
      v_beleg_nr := v_beleg_nr + 1;
      v_datum := make_date(v_jahr, v_monat, 25);

      -- Lohnzahlung Mitarbeiter (Nettolohn 3 MA zusammen ~14'000)
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 5000, 1020, (13500 + random() * 1000)::numeric(12,2),
              'Lohnzahlungen ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'L');

      -- Inhaberlohn (GF)
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 5200, 1020, 8500.00,
              'Lohn GF ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'G');

      -- AHV/IV/EO/ALV Arbeitgeberanteil
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 5700, 2270, (1800 + random() * 200)::numeric(12,2),
              'AHV/ALV AG-Anteil ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'S');

      -- BVG Arbeitgeberanteil
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 5710, 2271, (1200 + random() * 200)::numeric(12,2),
              'BVG AG-Anteil ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'B');

      -- UVG/KTG
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 5720, 2270, (400 + random() * 100)::numeric(12,2),
              'UVG/KTG AG-Anteil ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'U');

      -- SV-Zahlung (Quartal: Monat 3,6,9,12)
      IF v_monat IN (3, 6, 9, 12) THEN
        INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
        VALUES (v_user_id, v_datum + 5, 2270, 1020, (6000 + random() * 1000)::numeric(12,2),
                'SV-Zahlung Q' || (v_monat/3)::int || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'SZ');

        INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
        VALUES (v_user_id, v_datum + 5, 2271, 1020, (3600 + random() * 500)::numeric(12,2),
                'BVG-Zahlung Q' || (v_monat/3)::int || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'BZ');
      END IF;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Personal-Buchungen erstellt';

  -- ========================================================================
  -- D) BETRIEBSKOSTEN (monatlich wiederkehrend)
  -- ========================================================================
  FOR v_jahr IN 2024..2026 LOOP
    FOR v_monat IN 1..CASE WHEN v_jahr = 2026 THEN 3 ELSE 12 END LOOP
      v_beleg_nr := v_beleg_nr + 1;
      v_datum := make_date(v_jahr, v_monat, 1);

      -- Miete Werkstatt/Buero: Soll 6000 / Haben 1020
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 6000, 1020, 3200.00,
              'Miete Werkstatt + Buero ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'MI');

      -- Nebenkosten: Soll 6050 / Haben 1020
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum + 5, 6050, 1020, (350 + random() * 200)::numeric(12,2),
              'Nebenkosten ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'NK');

      -- Telefon/Internet: Soll 6510 / Haben 1020
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum + 8, 6510, 1020, (180 + random() * 40)::numeric(12,2),
              'Telefon/Internet ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'TI');

      -- Treibstoff: Soll 6210 / Haben 1020 (2-3 Tankungen)
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum + 10, 6210, 1020, (350 + random() * 250)::numeric(12,2),
              'Treibstoff Fahrzeuge ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'TR');

      -- Bueroaufwand: Soll 6500 / Haben 1020
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum + 12, 6500, 1020, (80 + random() * 120)::numeric(12,2),
              'Buero/Porto ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'BU');

      -- Software: Soll 6520 / Haben 1020 (quartalsweise)
      IF v_monat IN (1, 4, 7, 10) THEN
        INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
        VALUES (v_user_id, v_datum + 15, 6520, 1020, 450.00,
                'Software/Lizenzen Q' || ((v_monat + 2)/3)::int || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'SW');
      END IF;

      -- Bankgebuehren: Soll 6900 / Haben 1020
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, LEAST(make_date(v_jahr, v_monat, 28), (make_date(v_jahr, v_monat, 1) + interval '1 month' - interval '1 day')::date),
              6900, 1020, (25 + random() * 15)::numeric(12,2),
              'Bankgebuehren ' || TO_CHAR(v_datum, 'MM/YYYY'), 'BLG-' || v_beleg_nr || 'BG');
    END LOOP;
  END LOOP;

  -- ========================================================================
  -- E) QUARTALSWEISE / JAEHRLICHE BUCHUNGEN
  -- ========================================================================
  FOR v_jahr IN 2024..2026 LOOP
    -- Versicherungen (halbjaehrlich)
    FOREACH v_monat IN ARRAY ARRAY[1, 7] LOOP
      IF v_jahr = 2026 AND v_monat > 3 THEN CONTINUE; END IF;
      v_beleg_nr := v_beleg_nr + 1;
      v_datum := make_date(v_jahr, v_monat, 15);

      -- Sachversicherungen
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 6300, 1020, 1850.00,
              'Sachversicherungen HJ' || CASE WHEN v_monat = 1 THEN '1' ELSE '2' END || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'VS');

      -- Berufshaftpflicht
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 6310, 1020, 920.00,
              'Berufshaftpflicht HJ' || CASE WHEN v_monat = 1 THEN '1' ELSE '2' END || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'BH');

      -- Fahrzeugversicherungen
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, v_datum, 6220, 1020, 2400.00,
              'Fahrzeugversicherung HJ' || CASE WHEN v_monat = 1 THEN '1' ELSE '2' END || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'FV');
    END LOOP;

    -- Fahrzeug-Service/Unterhalt (2x jaehrlich)
    IF v_jahr < 2026 THEN
      v_beleg_nr := v_beleg_nr + 1;
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 4, 15), 6200, 1020, (1200 + random() * 800)::numeric(12,2),
              'Fahrzeug-Service Fruehjahr ' || v_jahr, 'BLG-' || v_beleg_nr || 'FS');
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 10, 15), 6200, 1020, (1200 + random() * 800)::numeric(12,2),
              'Fahrzeug-Service Herbst ' || v_jahr, 'BLG-' || v_beleg_nr || 'FH');
    END IF;

    -- Abschreibungen (jaehrlich, Ende Jahr)
    IF v_jahr < 2026 THEN
      v_beleg_nr := v_beleg_nr + 1;
      -- Fahrzeuge
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 12, 31), 6810, 1520, 8500.00,
              'Abschreibung Fahrzeuge ' || v_jahr, 'BLG-' || v_beleg_nr || 'AF');
      -- Maschinen/Werkzeuge
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 12, 31), 6820, 1500, 3200.00,
              'Abschreibung Maschinen ' || v_jahr, 'BLG-' || v_beleg_nr || 'AM');
    END IF;

    -- Buchfuehrung/Beratung (quartalsweise)
    FOREACH v_monat IN ARRAY ARRAY[3, 6, 9, 12] LOOP
      IF v_jahr = 2026 AND v_monat > 3 THEN CONTINUE; END IF;
      v_beleg_nr := v_beleg_nr + 1;
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, v_monat, 20), 6530, 1020, 850.00,
              'Buchfuehrung/Treuhand Q' || (v_monat/3)::int || '/' || v_jahr, 'BLG-' || v_beleg_nr || 'TR');
    END LOOP;

    -- Werbung (2x jaehrlich)
    IF v_jahr < 2026 THEN
      v_beleg_nr := v_beleg_nr + 1;
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 3, 1), 6600, 1020, (800 + random() * 500)::numeric(12,2),
              'Werbung/Marketing Fruehjahr ' || v_jahr, 'BLG-' || v_beleg_nr || 'WF');
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
      VALUES (v_user_id, make_date(v_jahr, 9, 1), 6600, 1020, (800 + random() * 500)::numeric(12,2),
              'Werbung/Marketing Herbst ' || v_jahr, 'BLG-' || v_beleg_nr || 'WH');
    END IF;
  END LOOP;

  -- ========================================================================
  -- F) MWST-ZAHLUNGEN (halbjaehrlich)
  -- Soll 2200 / Haben 1020
  -- ========================================================================
  -- H1 2024 (Juli 2024)
  v_beleg_nr := v_beleg_nr + 1;
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-07-30', 2200, 1020, 12500.00,
          'MWST-Zahlung H1/2024', 'BLG-' || v_beleg_nr || 'MW');
  -- Vorsteuer verrechnen
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-07-30', 2200, 1170, 4800.00,
          'Vorsteuer-Verrechnung H1/2024', 'BLG-' || v_beleg_nr || 'VV');

  -- H2 2024 (Jan 2025)
  v_beleg_nr := v_beleg_nr + 1;
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2025-01-30', 2200, 1020, 14200.00,
          'MWST-Zahlung H2/2024', 'BLG-' || v_beleg_nr || 'MW');
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2025-01-30', 2200, 1170, 5200.00,
          'Vorsteuer-Verrechnung H2/2024', 'BLG-' || v_beleg_nr || 'VV');

  -- H1 2025 (Juli 2025)
  v_beleg_nr := v_beleg_nr + 1;
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2025-07-30', 2200, 1020, 13800.00,
          'MWST-Zahlung H1/2025', 'BLG-' || v_beleg_nr || 'MW');
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2025-07-30', 2200, 1170, 5500.00,
          'Vorsteuer-Verrechnung H1/2025', 'BLG-' || v_beleg_nr || 'VV');

  -- H2 2025 (Jan 2026)
  v_beleg_nr := v_beleg_nr + 1;
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2026-01-30', 2200, 1020, 15100.00,
          'MWST-Zahlung H2/2025', 'BLG-' || v_beleg_nr || 'MW');
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2026-01-30', 2200, 1170, 5800.00,
          'Vorsteuer-Verrechnung H2/2025', 'BLG-' || v_beleg_nr || 'VV');

  -- ========================================================================
  -- G) EROEFFNUNGSBILANZ (Anfang 2024)
  -- Stammkapital + Reserven
  -- ========================================================================
  v_beleg_nr := v_beleg_nr + 1;
  -- Stammkapital
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1020, 2800, 20000.00,
          'Stammkapital GmbH', 'BLG-' || v_beleg_nr || 'SK');
  -- Gewinnvortrag
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1020, 2950, 35000.00,
          'Gewinnvortrag aus Vorjahr', 'BLG-' || v_beleg_nr || 'GV');
  -- Fahrzeuge als Anlage
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1520, 1020, 65000.00,
          'Fahrzeuge Anfangsbestand', 'BLG-' || v_beleg_nr || 'FA');
  -- Maschinen/Werkzeuge
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1500, 1020, 25000.00,
          'Maschinen/Werkzeuge Anfangsbestand', 'BLG-' || v_beleg_nr || 'MA');
  -- Materialvorrat
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1200, 1020, 18000.00,
          'Materialvorrat Anfangsbestand', 'BLG-' || v_beleg_nr || 'MV');
  -- Kasse Anfangsbestand
  INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr)
  VALUES (v_user_id, '2024-01-01', 1000, 1020, 2000.00,
          'Kasse Anfangsbestand', 'BLG-' || v_beleg_nr || 'KA');

  -- ========================================================================
  -- H) KONTEN-SALDEN BERECHNEN
  -- ========================================================================
  -- Soll-Buchungen addieren
  UPDATE konten SET saldo = COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.soll_konto = konten.kontonummer
  ), 0) - COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.haben_konto = konten.kontonummer
  ), 0)
  WHERE user_id = v_user_id AND typ IN ('aktiv', 'aufwand');

  -- Haben-Buchungen addieren (Passiv + Ertrag)
  UPDATE konten SET saldo = COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.haben_konto = konten.kontonummer
  ), 0) - COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.soll_konto = konten.kontonummer
  ), 0)
  WHERE user_id = v_user_id AND typ IN ('passiv', 'ertrag');

  -- ========================================================================
  -- I) MWST-ABRECHNUNGEN (4 abgeschlossene)
  -- ========================================================================
  -- H1 2024
  INSERT INTO mwst_abrechnungen (user_id, periode_start, periode_end, methode, status, eingereicht_am, bezahlt_am,
    ziff_200, ziff_299, ziff_302_umsatz, ziff_302_steuer, ziff_399, ziff_400, ziff_479, ziff_500, ziff_510)
  VALUES (v_user_id, '2024-01-01', '2024-06-30', 'effektiv', 'bezahlt', '2024-07-25', '2024-07-30',
    240000, 240000, 240000, 19440, 19440, 4800, 4800, 14640, 14640);

  -- H2 2024
  INSERT INTO mwst_abrechnungen (user_id, periode_start, periode_end, methode, status, eingereicht_am, bezahlt_am,
    ziff_200, ziff_299, ziff_302_umsatz, ziff_302_steuer, ziff_399, ziff_400, ziff_479, ziff_500, ziff_510)
  VALUES (v_user_id, '2024-07-01', '2024-12-31', 'effektiv', 'bezahlt', '2025-01-25', '2025-01-30',
    260000, 260000, 260000, 21060, 21060, 5200, 5200, 15860, 15860);

  -- H1 2025
  INSERT INTO mwst_abrechnungen (user_id, periode_start, periode_end, methode, status, eingereicht_am, bezahlt_am,
    ziff_200, ziff_299, ziff_302_umsatz, ziff_302_steuer, ziff_399, ziff_400, ziff_479, ziff_500, ziff_510)
  VALUES (v_user_id, '2025-01-01', '2025-06-30', 'effektiv', 'bezahlt', '2025-07-25', '2025-07-30',
    255000, 255000, 255000, 20655, 20655, 5500, 5500, 15155, 15155);

  -- H2 2025
  INSERT INTO mwst_abrechnungen (user_id, periode_start, periode_end, methode, status, eingereicht_am, bezahlt_am,
    ziff_200, ziff_299, ziff_302_umsatz, ziff_302_steuer, ziff_399, ziff_400, ziff_479, ziff_500, ziff_510)
  VALUES (v_user_id, '2025-07-01', '2025-12-31', 'effektiv', 'bezahlt', '2026-01-25', '2026-01-30',
    270000, 270000, 270000, 21870, 21870, 5800, 5800, 16070, 16070);

  RAISE NOTICE 'Buchungen total: %', (SELECT COUNT(*) FROM buchungen WHERE user_id = v_user_id);
  RAISE NOTICE 'MWST-Abrechnungen: %', (SELECT COUNT(*) FROM mwst_abrechnungen WHERE user_id = v_user_id);
  RAISE NOTICE '=== Testdaten 04 Buchhaltung FERTIG ===';
END;
$$;

-- ============================================================================
-- KMU Tool - Testdaten 05: Personal (SV, Lohn, Berechtigungen)
-- Proyer Sanitaer GmbH
-- ============================================================================
-- Abhaengigkeit: testdaten_01 muss zuerst ausgefuehrt werden
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_ma_marco UUID;
  v_ma_luca UUID;
  v_ma_anna UUID;
  v_monat INTEGER;
  v_jahr INTEGER;
  v_brutto NUMERIC(12,2);
  v_pensum NUMERIC(5,3);
  v_ahv_satz NUMERIC(5,3) := 5.300;
  v_alv_satz NUMERIC(5,3) := 1.100;
  v_uvg_nbu_satz NUMERIC(5,3) := 1.200;
  v_ktg_satz NUMERIC(5,3) := 0.500;
  v_uvg_bu_satz NUMERIC(5,3) := 0.800;
  v_ahv_an NUMERIC(10,2);
  v_alv_an NUMERIC(10,2);
  v_uvg_nbu_an NUMERIC(10,2);
  v_ktg_an NUMERIC(10,2);
  v_bvg_an NUMERIC(10,2);
  v_ahv_ag NUMERIC(10,2);
  v_alv_ag NUMERIC(10,2);
  v_uvg_bu_ag NUMERIC(10,2);
  v_ktg_ag NUMERIC(10,2);
  v_bvg_ag NUMERIC(10,2);
  v_fak_ag NUMERIC(10,2);
  v_kinderzulagen NUMERIC(10,2);
  v_nettolohn NUMERIC(12,2);
  v_total_ag NUMERIC(12,2);
  v_bvg_satz NUMERIC(5,3);
  v_bvg_koord NUMERIC(12,2) := 25725.00;
  v_bvg_versicherter_lohn NUMERIC(12,2);
  v_alter INTEGER;
  v_status TEXT;
  v_geburtsdatum DATE;
  v_kinder INTEGER;
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  -- Mitarbeiter-IDs holen
  SELECT id INTO v_ma_marco FROM mitarbeiter WHERE user_id = v_user_id AND vorname = 'Marco' AND nachname = 'Brunner';
  SELECT id INTO v_ma_luca FROM mitarbeiter WHERE user_id = v_user_id AND vorname = 'Luca' AND nachname = 'Steiner';
  SELECT id INTO v_ma_anna FROM mitarbeiter WHERE user_id = v_user_id AND vorname = 'Anna' AND nachname = 'Keller';

  IF v_ma_marco IS NULL OR v_ma_luca IS NULL OR v_ma_anna IS NULL THEN
    RAISE EXCEPTION 'Mitarbeiter nicht gefunden! Marco: %, Luca: %, Anna: %', v_ma_marco, v_ma_luca, v_ma_anna;
  END IF;

  -- ========================================================================
  -- 1. SOZIALVERSICHERUNGEN
  -- ========================================================================
  DELETE FROM sozialversicherungen WHERE user_id = v_user_id;

  INSERT INTO sozialversicherungen (
    user_id,
    ahv_satz_ag, ahv_satz_an,
    alv_satz_ag, alv_satz_an, alv_grenze, alv2_satz,
    uvg_bu_satz, uvg_nbu_satz, uvg_max_verdienst,
    ktg_satz_ag, ktg_satz_an,
    bvg_anbieter, bvg_vertrag_nr,
    bvg_koordinationsabzug, bvg_eintrittsschwelle, bvg_max_versicherter_lohn,
    bvg_satz_25_34, bvg_satz_35_44, bvg_satz_45_54, bvg_satz_55_64,
    bvg_ag_anteil_prozent,
    kinderzulage_betrag, ausbildungszulage_betrag,
    quellensteuer_aktiv
  ) VALUES (
    v_user_id,
    5.300, 5.300,
    1.100, 1.100, 148200.00, 1.000,
    0.800, 1.200, 148200.00,
    0.500, 0.500,
    'AXA Stiftung BVG', 'BVG-2024-0815',
    25725.00, 22050.00, 88200.00,
    7.000, 10.000, 15.000, 18.000,
    60.00,
    200.00, 250.00,
    false
  );

  -- ========================================================================
  -- 2. LOHNABRECHNUNGEN (~75 Stueck)
  -- Marco: ab Maerz 2024 (Eintritt 01.03.2022, aber Daten ab 2024)
  -- Luca: ab August 2024 (Eintritt 01.08.2023, Daten ab 2024)
  -- Anna: ab Januar 2024 (Eintritt 15.01.2024)
  -- ========================================================================
  DELETE FROM lohnabrechnungen WHERE user_id = v_user_id;

  -- Funktion: 5-Rappen-Rundung
  -- ROUND(betrag * 20) / 20

  FOR v_jahr IN 2024..2026 LOOP
    FOR v_monat IN 1..CASE WHEN v_jahr = 2026 THEN 3 ELSE 12 END LOOP

      -- ================================================================
      -- MARCO BRUNNER (Vorarbeiter, 100%, 6200 CHF, geb. 15.03.1985, 2 Kinder)
      -- ================================================================
      v_brutto := 6200.00;
      v_pensum := 1.000;
      v_geburtsdatum := '1985-03-15'::date;
      v_kinder := 2;
      v_alter := v_jahr - 1985;

      -- BVG-Satz nach Alter
      IF v_alter BETWEEN 25 AND 34 THEN v_bvg_satz := 7.000;
      ELSIF v_alter BETWEEN 35 AND 44 THEN v_bvg_satz := 10.000;
      ELSIF v_alter BETWEEN 45 AND 54 THEN v_bvg_satz := 15.000;
      ELSE v_bvg_satz := 18.000;
      END IF;

      -- AN-Abzuege
      v_ahv_an := ROUND(v_brutto * v_ahv_satz / 100 * 20) / 20;
      v_alv_an := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_nbu_an := ROUND(v_brutto * v_uvg_nbu_satz / 100 * 20) / 20;
      v_ktg_an := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;

      -- BVG
      v_bvg_versicherter_lohn := GREATEST(v_brutto * 12 - v_bvg_koord, 0) / 12;
      v_bvg_an := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.40 * 20) / 20; -- 40% AN
      v_bvg_ag := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.60 * 20) / 20; -- 60% AG

      -- Kinderzulagen
      v_kinderzulagen := v_kinder * 200.00;

      -- Nettolohn
      v_nettolohn := ROUND((v_brutto - v_ahv_an - v_alv_an - v_uvg_nbu_an - v_ktg_an - v_bvg_an + v_kinderzulagen) * 20) / 20;

      -- AG-Kosten
      v_ahv_ag := v_ahv_an;
      v_alv_ag := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_bu_ag := ROUND(v_brutto * v_uvg_bu_satz / 100 * 20) / 20;
      v_ktg_ag := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;
      v_fak_ag := v_kinderzulagen;
      v_total_ag := v_brutto + v_ahv_ag + v_alv_ag + v_uvg_bu_ag + v_ktg_ag + v_bvg_ag + v_fak_ag;

      -- Status
      IF v_jahr < 2026 THEN v_status := 'ausbezahlt';
      ELSIF v_monat <= 2 THEN v_status := 'ausbezahlt';
      ELSE v_status := 'freigegeben';
      END IF;

      INSERT INTO lohnabrechnungen (
        user_id, mitarbeiter_id, monat, jahr, bruttolohn, pensum,
        ahv_an, alv_an, uvg_nbu_an, ktg_an, bvg_an, quellensteuer, kinderzulagen, nettolohn,
        ahv_ag, alv_ag, uvg_bu_ag, ktg_ag, bvg_ag, fak_ag, total_ag_kosten,
        status, is_deleted
      ) VALUES (
        v_user_id, v_ma_marco, v_monat, v_jahr, v_brutto, v_pensum,
        v_ahv_an, v_alv_an, v_uvg_nbu_an, v_ktg_an, v_bvg_an, 0, v_kinderzulagen, v_nettolohn,
        v_ahv_ag, v_alv_ag, v_uvg_bu_ag, v_ktg_ag, v_bvg_ag, v_fak_ag, v_total_ag,
        v_status, false
      );

      -- ================================================================
      -- LUCA STEINER (Geselle, 100%, 5400 CHF, geb. 22.07.1992, 0 Kinder)
      -- ================================================================
      v_brutto := 5400.00;
      v_pensum := 1.000;
      v_geburtsdatum := '1992-07-22'::date;
      v_kinder := 0;
      v_alter := v_jahr - 1992;

      IF v_alter BETWEEN 25 AND 34 THEN v_bvg_satz := 7.000;
      ELSIF v_alter BETWEEN 35 AND 44 THEN v_bvg_satz := 10.000;
      ELSE v_bvg_satz := 7.000;
      END IF;

      v_ahv_an := ROUND(v_brutto * v_ahv_satz / 100 * 20) / 20;
      v_alv_an := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_nbu_an := ROUND(v_brutto * v_uvg_nbu_satz / 100 * 20) / 20;
      v_ktg_an := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;

      v_bvg_versicherter_lohn := GREATEST(v_brutto * 12 - v_bvg_koord, 0) / 12;
      v_bvg_an := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.40 * 20) / 20;
      v_bvg_ag := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.60 * 20) / 20;

      v_kinderzulagen := 0;
      v_nettolohn := ROUND((v_brutto - v_ahv_an - v_alv_an - v_uvg_nbu_an - v_ktg_an - v_bvg_an) * 20) / 20;

      v_ahv_ag := v_ahv_an;
      v_alv_ag := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_bu_ag := ROUND(v_brutto * v_uvg_bu_satz / 100 * 20) / 20;
      v_ktg_ag := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;
      v_fak_ag := 0;
      v_total_ag := v_brutto + v_ahv_ag + v_alv_ag + v_uvg_bu_ag + v_ktg_ag + v_bvg_ag + v_fak_ag;

      IF v_jahr < 2026 THEN v_status := 'ausbezahlt';
      ELSIF v_monat <= 2 THEN v_status := 'ausbezahlt';
      ELSE v_status := 'freigegeben';
      END IF;

      INSERT INTO lohnabrechnungen (
        user_id, mitarbeiter_id, monat, jahr, bruttolohn, pensum,
        ahv_an, alv_an, uvg_nbu_an, ktg_an, bvg_an, quellensteuer, kinderzulagen, nettolohn,
        ahv_ag, alv_ag, uvg_bu_ag, ktg_ag, bvg_ag, fak_ag, total_ag_kosten,
        status, is_deleted
      ) VALUES (
        v_user_id, v_ma_luca, v_monat, v_jahr, v_brutto, v_pensum,
        v_ahv_an, v_alv_an, v_uvg_nbu_an, v_ktg_an, v_bvg_an, 0, v_kinderzulagen, v_nettolohn,
        v_ahv_ag, v_alv_ag, v_uvg_bu_ag, v_ktg_ag, v_bvg_ag, v_fak_ag, v_total_ag,
        v_status, false
      );

      -- ================================================================
      -- ANNA KELLER (Buero, 60%, 4800 CHF, geb. 10.11.1988, 1 Kind)
      -- ================================================================
      v_brutto := 4800.00;
      v_pensum := 0.600;
      v_geburtsdatum := '1988-11-10'::date;
      v_kinder := 1;
      v_alter := v_jahr - 1988;

      -- Brutto angepasst an Pensum (4800 ist schon der Teilzeitlohn)
      -- BVG wird aber auf Vollzeitaequivalent gerechnet... vereinfacht hier
      IF v_alter BETWEEN 25 AND 34 THEN v_bvg_satz := 7.000;
      ELSIF v_alter BETWEEN 35 AND 44 THEN v_bvg_satz := 10.000;
      ELSE v_bvg_satz := 7.000;
      END IF;

      v_ahv_an := ROUND(v_brutto * v_ahv_satz / 100 * 20) / 20;
      v_alv_an := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_nbu_an := ROUND(v_brutto * v_uvg_nbu_satz / 100 * 20) / 20;
      v_ktg_an := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;

      v_bvg_versicherter_lohn := GREATEST(v_brutto * 12 - v_bvg_koord * v_pensum, 0) / 12;
      v_bvg_an := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.40 * 20) / 20;
      v_bvg_ag := ROUND(v_bvg_versicherter_lohn * v_bvg_satz / 100 * 0.60 * 20) / 20;

      v_kinderzulagen := v_kinder * 200.00;
      v_nettolohn := ROUND((v_brutto - v_ahv_an - v_alv_an - v_uvg_nbu_an - v_ktg_an - v_bvg_an + v_kinderzulagen) * 20) / 20;

      v_ahv_ag := v_ahv_an;
      v_alv_ag := ROUND(v_brutto * v_alv_satz / 100 * 20) / 20;
      v_uvg_bu_ag := ROUND(v_brutto * v_uvg_bu_satz / 100 * 20) / 20;
      v_ktg_ag := ROUND(v_brutto * v_ktg_satz / 100 * 20) / 20;
      v_fak_ag := v_kinderzulagen;
      v_total_ag := v_brutto + v_ahv_ag + v_alv_ag + v_uvg_bu_ag + v_ktg_ag + v_bvg_ag + v_fak_ag;

      IF v_jahr < 2026 THEN v_status := 'ausbezahlt';
      ELSIF v_monat <= 2 THEN v_status := 'ausbezahlt';
      ELSE v_status := 'freigegeben';
      END IF;

      INSERT INTO lohnabrechnungen (
        user_id, mitarbeiter_id, monat, jahr, bruttolohn, pensum,
        ahv_an, alv_an, uvg_nbu_an, ktg_an, bvg_an, quellensteuer, kinderzulagen, nettolohn,
        ahv_ag, alv_ag, uvg_bu_ag, ktg_ag, bvg_ag, fak_ag, total_ag_kosten,
        status, is_deleted
      ) VALUES (
        v_user_id, v_ma_anna, v_monat, v_jahr, v_brutto, v_pensum,
        v_ahv_an, v_alv_an, v_uvg_nbu_an, v_ktg_an, v_bvg_an, 0, v_kinderzulagen, v_nettolohn,
        v_ahv_ag, v_alv_ag, v_uvg_bu_ag, v_ktg_ag, v_bvg_ag, v_fak_ag, v_total_ag,
        v_status, false
      );

    END LOOP;
  END LOOP;

  RAISE NOTICE 'Lohnabrechnungen angelegt: %', (SELECT COUNT(*) FROM lohnabrechnungen WHERE user_id = v_user_id);

  -- ========================================================================
  -- 3. MITARBEITER-BERECHTIGUNGEN
  -- ========================================================================
  DELETE FROM mitarbeiter_berechtigungen WHERE user_id = v_user_id;

  -- Marco Brunner: kunden/offerten/auftraege lesen+schreiben, rechnungen lesen
  INSERT INTO mitarbeiter_berechtigungen (user_id, mitarbeiter_id, modul, lesen, schreiben) VALUES
    (v_user_id, v_ma_marco, 'kunden', true, true),
    (v_user_id, v_ma_marco, 'offerten', true, true),
    (v_user_id, v_ma_marco, 'auftraege', true, true),
    (v_user_id, v_ma_marco, 'rechnungen', true, false),
    (v_user_id, v_ma_marco, 'artikel', true, false),
    (v_user_id, v_ma_marco, 'kalender', true, true);

  -- Luca Steiner: auftraege/artikel lesen, kalender lesen+schreiben
  INSERT INTO mitarbeiter_berechtigungen (user_id, mitarbeiter_id, modul, lesen, schreiben) VALUES
    (v_user_id, v_ma_luca, 'auftraege', true, false),
    (v_user_id, v_ma_luca, 'artikel', true, false),
    (v_user_id, v_ma_luca, 'kalender', true, true);

  -- Anna Keller: alle Module lesen+schreiben (Buero)
  INSERT INTO mitarbeiter_berechtigungen (user_id, mitarbeiter_id, modul, lesen, schreiben) VALUES
    (v_user_id, v_ma_anna, 'kunden', true, true),
    (v_user_id, v_ma_anna, 'offerten', true, true),
    (v_user_id, v_ma_anna, 'auftraege', true, true),
    (v_user_id, v_ma_anna, 'rechnungen', true, true),
    (v_user_id, v_ma_anna, 'artikel', true, true),
    (v_user_id, v_ma_anna, 'buchhaltung', true, true),
    (v_user_id, v_ma_anna, 'kalender', true, true),
    (v_user_id, v_ma_anna, 'personal', true, false),
    (v_user_id, v_ma_anna, 'einstellungen', true, false);

  RAISE NOTICE 'Berechtigungen angelegt: %', (SELECT COUNT(*) FROM mitarbeiter_berechtigungen WHERE user_id = v_user_id);
  RAISE NOTICE '=== Testdaten 05 Personal FERTIG ===';
END;
$$;

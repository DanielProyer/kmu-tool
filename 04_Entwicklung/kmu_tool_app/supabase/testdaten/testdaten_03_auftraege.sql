-- ============================================================================
-- KMU Tool - Testdaten 03: Offerten, Auftraege, Rechnungen
-- Proyer Sanitaer GmbH
-- ============================================================================
-- Abhaengigkeit: testdaten_01 + testdaten_02 muessen zuerst ausgefuehrt werden
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_kunde_ids UUID[];
  v_kunde_id UUID;
  v_offerte_id UUID;
  v_auftrag_id UUID;
  v_rechnung_id UUID;
  v_offert_nr INTEGER := 1000;
  v_auftrag_nr INTEGER := 2000;
  v_rechnungs_nr INTEGER := 3000;
  v_datum DATE;
  v_total_netto NUMERIC(10,2);
  v_mwst_betrag NUMERIC(10,2);
  v_total_brutto NUMERIC(10,2);
  v_status TEXT;
  v_rand NUMERIC;
  v_beschreibung TEXT;
  v_pos_nr INTEGER;
  i INTEGER;
  j INTEGER;
  v_beschreibungen TEXT[] := ARRAY[
    'Badezimmer-Renovation komplett',
    'WC-Anlage Ersatz',
    'Kueche: Spuele und Armaturen ersetzen',
    'Leitungssanierung Altbau',
    'Boilerersatz 200L',
    'Badewanne raus, Dusche rein',
    'Notfall: Rohrbruch Keller',
    'Heizkoerper-Ersatz Wohnzimmer',
    'Verstopfung Abfluss Kueche',
    'Lavabo-Montage Gaeste-WC',
    'Duschkabine Montage',
    'Badezimmer-Sanierung Altbau',
    'Leck Warmwasserleitung',
    'Neubau: Sanitaerinstallation EFH',
    'Neubau: Sanitaerinstallation MFH',
    'Umbau Nasszelle Studio',
    'Heizungsverteilung Sanierung',
    'Boiler-Entkalkung + Service',
    'WC Spuelkasten Reparatur',
    'Kuechen-Umbau Sanitaer',
    'Waschmaschinenanschluss verlegen',
    'Regenwasseranlage Installation',
    'Enthärtungsanlage Einbau',
    'Fussbodenheizung Nachruestung',
    'Brause + Armatur Ersatz',
    'Abflussreinigung Hauptleitung',
    'Zirkulationsleitung installieren',
    'Sicherheitsventil Ersatz Boiler',
    'Bad komplett Neubau',
    'Sanitaer Wartungsvertrag'
  ];
  v_arbeit_bezeichnungen TEXT[] := ARRAY[
    'Sanitaer-Installationsarbeit',
    'Demontage bestehende Anlage',
    'Montage und Anschluss',
    'Rohrleitungsarbeit',
    'Inbetriebnahme und Pruefung',
    'Anpassungsarbeit',
    'Abdichtungsarbeit',
    'Kernbohrung',
    'Wanddurchbruch und Verschluss',
    'Dichtigkeitspruefung',
    'Spuelarbeiten Leitungsnetz',
    'Isolierungsarbeiten'
  ];
  v_stundensatz NUMERIC[] := ARRAY[95.00, 105.00, 115.00, 125.00];
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  -- Alle Kunden-IDs laden
  SELECT array_agg(id ORDER BY created_at) INTO v_kunde_ids
  FROM kunden WHERE user_id = v_user_id AND is_deleted = false;

  -- Bestehende Daten loeschen (in Abhaengigkeitsreihenfolge)
  DELETE FROM zeiterfassungen WHERE user_id = v_user_id;
  DELETE FROM rapporte WHERE user_id = v_user_id;
  DELETE FROM rechnungs_positionen WHERE rechnung_id IN (SELECT id FROM rechnungen WHERE user_id = v_user_id);
  DELETE FROM rechnungen WHERE user_id = v_user_id;
  DELETE FROM auftraege WHERE user_id = v_user_id;
  DELETE FROM offert_positionen WHERE offerte_id IN (SELECT id FROM offerten WHERE user_id = v_user_id);
  DELETE FROM offerten WHERE user_id = v_user_id;

  -- ========================================================================
  -- OFFERTEN (120 Stueck, ~40/Jahr: 2024, 2025, 2026)
  -- ========================================================================
  FOR i IN 1..120 LOOP
    v_offert_nr := v_offert_nr + 1;
    v_kunde_id := v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int];
    v_beschreibung := v_beschreibungen[1 + (random() * (array_length(v_beschreibungen, 1) - 1))::int];

    -- Datum verteilen: 1-40 = 2024, 41-80 = 2025, 81-120 = 2026
    IF i <= 40 THEN
      v_datum := '2024-01-15'::date + (random() * 340)::int;
    ELSIF i <= 80 THEN
      v_datum := '2025-01-10'::date + (random() * 345)::int;
    ELSE
      v_datum := '2026-01-05'::date + (random() * 85)::int; -- bis ~April 2026
    END IF;

    -- Status-Mix: 30% angenommen, 20% gesendet, 15% abgelehnt, 25% entwurf, 10% abgelaufen
    v_rand := random();
    IF v_rand < 0.30 THEN v_status := 'angenommen';
    ELSIF v_rand < 0.50 THEN v_status := 'gesendet';
    ELSIF v_rand < 0.65 THEN v_status := 'abgelehnt';
    ELSIF v_rand < 0.90 THEN v_status := 'entwurf';
    ELSE v_status := 'abgelaufen';
    END IF;

    -- 2024: mehr angenommen/abgelehnt, weniger entwurf
    IF i <= 40 AND v_status = 'entwurf' THEN v_status := 'angenommen'; END IF;

    v_offerte_id := gen_random_uuid();
    INSERT INTO offerten (id, user_id, kunde_id, offert_nr, datum, gueltig_bis, status, total_netto, mwst_satz, mwst_betrag, total_brutto, bemerkung, is_deleted)
    VALUES (v_offerte_id, v_user_id, v_kunde_id, 'OFF-' || v_offert_nr, v_datum, v_datum + 30, v_status, 0, 8.10, 0, 0, v_beschreibung, false);

    -- 2-8 Positionen pro Offerte
    v_total_netto := 0;
    FOR j IN 1..(2 + (random() * 6)::int) LOOP
      DECLARE
        v_pos_betrag NUMERIC(10,2);
        v_pos_menge NUMERIC(10,3);
        v_pos_preis NUMERIC(10,2);
        v_pos_einheit TEXT;
        v_pos_bez TEXT;
        v_pos_typ TEXT;
      BEGIN
        IF random() < 0.4 THEN
          -- Arbeitsposition
          v_pos_typ := 'arbeit';
          v_pos_bez := v_arbeit_bezeichnungen[1 + (random() * (array_length(v_arbeit_bezeichnungen, 1) - 1))::int];
          v_pos_menge := (1 + random() * 15)::numeric(10,3);
          v_pos_preis := v_stundensatz[1 + (random() * 3)::int];
          v_pos_einheit := 'Std';
        ELSE
          -- Materialposition
          v_pos_typ := 'material';
          v_pos_bez := (SELECT bezeichnung FROM artikel WHERE user_id = v_user_id AND kategorie = 'material' ORDER BY random() LIMIT 1);
          v_pos_menge := (1 + random() * 10)::numeric(10,3);
          v_pos_preis := (20 + random() * 400)::numeric(10,2);
          v_pos_einheit := CASE WHEN random() < 0.5 THEN 'Stk' WHEN random() < 0.7 THEN 'm' ELSE 'Pauschale' END;
          IF v_pos_einheit = 'Pauschale' THEN v_pos_menge := 1; v_pos_preis := (100 + random() * 2000)::numeric(10,2); END IF;
        END IF;

        v_pos_betrag := v_pos_menge * v_pos_preis;
        v_total_netto := v_total_netto + v_pos_betrag;

        INSERT INTO offert_positionen (offerte_id, position_nr, bezeichnung, menge, einheit, einheitspreis, typ)
        VALUES (v_offerte_id, j, v_pos_bez, v_pos_menge, v_pos_einheit, v_pos_preis, v_pos_typ);
      END;
    END LOOP;

    -- Offerte-Totale aktualisieren
    v_mwst_betrag := ROUND(v_total_netto * 0.081, 2);
    v_total_brutto := v_total_netto + v_mwst_betrag;

    UPDATE offerten SET
      total_netto = v_total_netto,
      mwst_betrag = v_mwst_betrag,
      total_brutto = v_total_brutto
    WHERE id = v_offerte_id;
  END LOOP;

  RAISE NOTICE 'Offerten angelegt: %', (SELECT COUNT(*) FROM offerten WHERE user_id = v_user_id);

  -- ========================================================================
  -- AUFTRAEGE (90 Stueck, ~30/Jahr)
  -- Einige verknuepft mit angenommenen Offerten, einige Direktauftraege
  -- ========================================================================
  -- Auftraege aus angenommenen Offerten
  FOR v_offerte_id, v_kunde_id, v_datum, v_beschreibung IN
    SELECT o.id, o.kunde_id, o.datum, o.bemerkung
    FROM offerten o
    WHERE o.user_id = v_user_id AND o.status = 'angenommen'
    ORDER BY o.datum
  LOOP
    v_auftrag_nr := v_auftrag_nr + 1;

    -- Status basierend auf Jahr
    IF v_datum < '2025-01-01'::date THEN
      v_status := CASE WHEN random() < 0.85 THEN 'abgeschlossen' ELSE 'storniert' END;
    ELSIF v_datum < '2026-01-01'::date THEN
      v_rand := random();
      IF v_rand < 0.50 THEN v_status := 'abgeschlossen';
      ELSIF v_rand < 0.80 THEN v_status := 'in_arbeit';
      ELSE v_status := 'offen';
      END IF;
    ELSE
      v_rand := random();
      IF v_rand < 0.20 THEN v_status := 'abgeschlossen';
      ELSIF v_rand < 0.50 THEN v_status := 'in_arbeit';
      ELSE v_status := 'offen';
      END IF;
    END IF;

    v_auftrag_id := gen_random_uuid();
    INSERT INTO auftraege (id, user_id, kunde_id, offerte_id, auftrags_nr, status, beschreibung, geplant_von, geplant_bis, auftrag_typ, is_deleted)
    VALUES (v_auftrag_id, v_user_id, v_kunde_id, v_offerte_id, 'AUF-' || v_auftrag_nr, v_status, v_beschreibung,
            v_datum + (3 + random() * 10)::int, v_datum + (10 + random() * 30)::int, 'einmalig', false);
  END LOOP;

  -- Direktauftraege (auffuellen bis ~90 total)
  WHILE (SELECT COUNT(*) FROM auftraege WHERE user_id = v_user_id) < 90 LOOP
    v_auftrag_nr := v_auftrag_nr + 1;
    v_kunde_id := v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int];
    v_beschreibung := v_beschreibungen[1 + (random() * (array_length(v_beschreibungen, 1) - 1))::int];

    -- Datum verteilen
    v_rand := random();
    IF v_rand < 0.33 THEN
      v_datum := '2024-01-15'::date + (random() * 340)::int;
      v_status := CASE WHEN random() < 0.85 THEN 'abgeschlossen' ELSE 'storniert' END;
    ELSIF v_rand < 0.66 THEN
      v_datum := '2025-01-10'::date + (random() * 345)::int;
      v_status := CASE WHEN random() < 0.5 THEN 'abgeschlossen' WHEN random() < 0.8 THEN 'in_arbeit' ELSE 'offen' END;
    ELSE
      v_datum := '2026-01-05'::date + (random() * 85)::int;
      v_status := CASE WHEN random() < 0.2 THEN 'abgeschlossen' WHEN random() < 0.5 THEN 'in_arbeit' ELSE 'offen' END;
    END IF;

    v_auftrag_id := gen_random_uuid();
    INSERT INTO auftraege (id, user_id, kunde_id, auftrags_nr, status, beschreibung, geplant_von, geplant_bis, auftrag_typ, is_deleted)
    VALUES (v_auftrag_id, v_user_id, v_kunde_id, 'AUF-' || v_auftrag_nr, v_status, v_beschreibung,
            v_datum, v_datum + (5 + random() * 20)::int, 'einmalig', false);
  END LOOP;

  -- Einige periodische Auftraege (Wartungsvertraege)
  FOR i IN 1..5 LOOP
    v_auftrag_nr := v_auftrag_nr + 1;
    v_kunde_id := v_kunde_ids[60 + i]; -- Firmenkunden

    v_auftrag_id := gen_random_uuid();
    INSERT INTO auftraege (id, user_id, kunde_id, auftrags_nr, status, beschreibung, geplant_von, geplant_bis, auftrag_typ, intervall, naechste_ausfuehrung, vorlauf_tage, periodisch_bezeichnung, is_deleted)
    VALUES (v_auftrag_id, v_user_id, v_kunde_id, 'AUF-' || v_auftrag_nr, 'in_arbeit',
            'Wartungsvertrag Sanitaeranlagen',
            '2024-01-01', '2026-12-31',
            'periodisch',
            CASE WHEN random() < 0.5 THEN 'halbjaehrlich' ELSE 'jaehrlich' END,
            '2026-06-01',
            14,
            'Sanitaer-Wartung ' || CASE WHEN random() < 0.5 THEN 'Halbjahr' ELSE 'Jahr' END,
            false);
  END LOOP;

  RAISE NOTICE 'Auftraege angelegt: %', (SELECT COUNT(*) FROM auftraege WHERE user_id = v_user_id);

  -- ========================================================================
  -- RECHNUNGEN (~90 Stueck) - verknuepft mit abgeschlossenen/in_arbeit Auftraegen
  -- Jahresumsatz ~500k (2024: 480k, 2025: 520k, 2026: ~130k)
  -- ========================================================================
  FOR v_auftrag_id, v_kunde_id, v_datum, v_status IN
    SELECT a.id, a.kunde_id, a.geplant_von, a.status
    FROM auftraege a
    WHERE a.user_id = v_user_id AND a.status IN ('abgeschlossen', 'in_arbeit') AND a.auftrag_typ = 'einmalig'
    ORDER BY a.geplant_von
    LIMIT 90
  LOOP
    v_rechnungs_nr := v_rechnungs_nr + 1;
    v_rechnung_id := gen_random_uuid();

    -- Rechnungsdatum = Auftrags-Ende + paar Tage
    v_datum := v_datum + (5 + random() * 15)::int;

    -- Status basierend auf Rechnungsdatum
    IF v_datum < '2025-01-01'::date THEN
      v_rand := random();
      IF v_rand < 0.85 THEN
        v_status := 'bezahlt';
      ELSIF v_rand < 0.95 THEN
        v_status := 'gesendet';
      ELSE
        v_status := 'gemahnt';
      END IF;
    ELSIF v_datum < '2026-01-01'::date THEN
      v_rand := random();
      IF v_rand < 0.60 THEN v_status := 'bezahlt';
      ELSIF v_rand < 0.85 THEN v_status := 'gesendet';
      ELSIF v_rand < 0.95 THEN v_status := 'gemahnt';
      ELSE v_status := 'entwurf';
      END IF;
    ELSE
      v_rand := random();
      IF v_rand < 0.20 THEN v_status := 'bezahlt';
      ELSIF v_rand < 0.60 THEN v_status := 'gesendet';
      ELSE v_status := 'entwurf';
      END IF;
    END IF;

    INSERT INTO rechnungen (id, user_id, kunde_id, auftrag_id, rechnungs_nr, datum, faellig_am, status, total_netto, mwst_satz, mwst_betrag, total_brutto, qr_referenz)
    VALUES (v_rechnung_id, v_user_id, v_kunde_id, v_auftrag_id, 'RE-' || v_rechnungs_nr, v_datum, v_datum + 30, v_status, 0, 8.10, 0, 0,
            'RF' || LPAD(v_rechnungs_nr::text, 23, '0') || '0');

    -- 3-6 Positionen pro Rechnung
    v_total_netto := 0;
    FOR j IN 1..(3 + (random() * 3)::int) LOOP
      DECLARE
        v_pos_menge NUMERIC(10,3);
        v_pos_preis NUMERIC(10,2);
        v_pos_einheit TEXT;
        v_pos_bez TEXT;
      BEGIN
        IF j <= 2 THEN
          -- Arbeitsleistung
          v_pos_bez := v_arbeit_bezeichnungen[1 + (random() * (array_length(v_arbeit_bezeichnungen, 1) - 1))::int];
          v_pos_menge := (2 + random() * 14)::numeric(10,1);
          v_pos_preis := v_stundensatz[1 + (random() * 3)::int];
          v_pos_einheit := 'Std';
        ELSE
          -- Material
          v_pos_bez := (SELECT bezeichnung FROM artikel WHERE user_id = v_user_id AND kategorie = 'material' ORDER BY random() LIMIT 1);
          v_pos_menge := (1 + random() * 8)::numeric(10,1);
          v_pos_preis := (15 + random() * 350)::numeric(10,2);
          v_pos_einheit := CASE WHEN random() < 0.6 THEN 'Stk' WHEN random() < 0.8 THEN 'm' ELSE 'Pauschale' END;
          IF v_pos_einheit = 'Pauschale' THEN v_pos_menge := 1; v_pos_preis := (80 + random() * 1500)::numeric(10,2); END IF;
        END IF;

        v_total_netto := v_total_netto + (v_pos_menge * v_pos_preis);

        INSERT INTO rechnungs_positionen (rechnung_id, position_nr, bezeichnung, menge, einheit, einheitspreis)
        VALUES (v_rechnung_id, j, v_pos_bez, v_pos_menge, v_pos_einheit, v_pos_preis);
      END;
    END LOOP;

    v_mwst_betrag := ROUND(v_total_netto * 0.081, 2);
    v_total_brutto := v_total_netto + v_mwst_betrag;

    UPDATE rechnungen SET
      total_netto = v_total_netto,
      mwst_betrag = v_mwst_betrag,
      total_brutto = v_total_brutto
    WHERE id = v_rechnung_id;
  END LOOP;

  RAISE NOTICE 'Rechnungen angelegt: %', (SELECT COUNT(*) FROM rechnungen WHERE user_id = v_user_id);
  RAISE NOTICE 'Umsatz 2024: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2024);
  RAISE NOTICE 'Umsatz 2025: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2025);
  RAISE NOTICE 'Umsatz 2026: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2026);

  -- ========================================================================
  -- ZEITERFASSUNGEN (~300) - pro Auftrag 2-5 Eintraege
  -- ========================================================================
  FOR v_auftrag_id, v_datum IN
    SELECT a.id, a.geplant_von
    FROM auftraege a
    WHERE a.user_id = v_user_id AND a.status IN ('abgeschlossen', 'in_arbeit')
    ORDER BY a.geplant_von
    LIMIT 80
  LOOP
    FOR j IN 1..(2 + (random() * 3)::int) LOOP
      DECLARE
        v_start TIME;
        v_end TIME;
        v_pause INTEGER;
      BEGIN
        -- Realistische Arbeitszeiten
        IF random() < 0.5 THEN
          v_start := '07:30'::time;
          v_end := '12:00'::time;
          v_pause := 0;
        ELSIF random() < 0.7 THEN
          v_start := '07:30'::time;
          v_end := '17:00'::time;
          v_pause := 60;
        ELSIF random() < 0.9 THEN
          v_start := '08:00'::time;
          v_end := '16:30'::time;
          v_pause := 30;
        ELSE
          v_start := '13:00'::time;
          v_end := '17:00'::time;
          v_pause := 0;
        END IF;

        INSERT INTO zeiterfassungen (user_id, auftrag_id, datum, start_zeit, end_zeit, pause_minuten, beschreibung)
        VALUES (v_user_id, v_auftrag_id, v_datum + j - 1, v_start, v_end, v_pause,
                CASE (random() * 5)::int
                  WHEN 0 THEN 'Sanitaer-Installationsarbeiten'
                  WHEN 1 THEN 'Demontage und Entsorgung'
                  WHEN 2 THEN 'Rohrleitungen verlegt'
                  WHEN 3 THEN 'Armaturen montiert und angeschlossen'
                  WHEN 4 THEN 'Dichtigkeitspruefung und Inbetriebnahme'
                  ELSE 'Anpassungsarbeiten vor Ort'
                END);
      END;
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Zeiterfassungen angelegt: %', (SELECT COUNT(*) FROM zeiterfassungen WHERE user_id = v_user_id);

  -- ========================================================================
  -- RAPPORTE (~150) - pro Auftrag 1-3 Rapporte
  -- ========================================================================
  FOR v_auftrag_id, v_datum IN
    SELECT a.id, a.geplant_von
    FROM auftraege a
    WHERE a.user_id = v_user_id AND a.status IN ('abgeschlossen', 'in_arbeit')
    ORDER BY a.geplant_von
    LIMIT 80
  LOOP
    FOR j IN 1..(1 + (random() * 2)::int) LOOP
      INSERT INTO rapporte (auftrag_id, user_id, datum, beschreibung, status)
      VALUES (v_auftrag_id, v_user_id, v_datum + j - 1,
              CASE (random() * 7)::int
                WHEN 0 THEN 'Bestandesaufnahme vor Ort. Alte Installation inspiziert, Schaeden dokumentiert.'
                WHEN 1 THEN 'Demontage alter Installationen durchgefuehrt. Material entsorgt.'
                WHEN 2 THEN 'Neue Leitungen verlegt und angeschlossen. Dichtigkeitspruefung bestanden.'
                WHEN 3 THEN 'Armaturen und Sanitaerapparate montiert. Kunde instruiert.'
                WHEN 4 THEN 'Endreinigung und Abnahme mit Kunde. Keine Maengel festgestellt.'
                WHEN 5 THEN 'Reparatur ausgefuehrt. Defektes Teil ersetzt und getestet.'
                WHEN 6 THEN 'Wartungsarbeiten: Boiler entkalkt, Ventile geprueft, Dichtungen ersetzt.'
                ELSE 'Nachkontrolle: Alles in Ordnung, keine Beanstandungen.'
              END,
              CASE WHEN v_datum < CURRENT_DATE - 30 THEN 'abgeschlossen' ELSE 'entwurf' END);
    END LOOP;
  END LOOP;

  RAISE NOTICE 'Rapporte angelegt: %', (SELECT COUNT(*) FROM rapporte WHERE user_id = v_user_id);
  RAISE NOTICE '=== Testdaten 03 Auftraege FERTIG ===';
END;
$$;

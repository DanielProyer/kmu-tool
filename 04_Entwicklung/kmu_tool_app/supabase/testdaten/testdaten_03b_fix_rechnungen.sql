-- ============================================================================
-- Fix: Mehr Rechnungen + hoehere Betraege fuer realistischen Jahresumsatz ~500k
-- ============================================================================

DO $$
DECLARE
  v_user_id UUID;
  v_kunde_ids UUID[];
  v_kunde_id UUID;
  v_rechnung_id UUID;
  v_rechnungs_nr INTEGER;
  v_datum DATE;
  v_total_netto NUMERIC(10,2);
  v_mwst_betrag NUMERIC(10,2);
  v_total_brutto NUMERIC(10,2);
  v_status TEXT;
  v_rand NUMERIC;
  i INTEGER;
  j INTEGER;
  v_arbeit_bezeichnungen TEXT[] := ARRAY[
    'Sanitaer-Installationsarbeit',
    'Demontage bestehende Anlage',
    'Montage und Anschluss',
    'Rohrleitungsarbeit',
    'Inbetriebnahme und Pruefung',
    'Abdichtungsarbeit',
    'Kernbohrung',
    'Dichtigkeitspruefung',
    'Bad-Renovation Arbeitsleistung',
    'Heizungsmontage'
  ];
BEGIN
  SELECT id INTO v_user_id FROM auth.users WHERE email = 'dani.proyer@gmail.com';
  IF v_user_id IS NULL THEN RAISE EXCEPTION 'User nicht gefunden!'; END IF;

  SELECT array_agg(id ORDER BY created_at) INTO v_kunde_ids FROM kunden WHERE user_id = v_user_id AND is_deleted = false;

  -- Hoechste Rechnungsnummer ermitteln
  SELECT COALESCE(MAX(CAST(REPLACE(rechnungs_nr, 'RE-', '') AS INTEGER)), 3100) INTO v_rechnungs_nr
  FROM rechnungen WHERE user_id = v_user_id;

  -- Zusaetzliche Rechnungen mit hoeheren Betraegen generieren
  -- Ziel: Jahresumsatz 2024 ~480k, 2025 ~520k, 2026 ~130k

  -- 2024: ~25 zusaetzliche Rechnungen mit hoeheren Betraegen (480k - ~104k = ~376k noetig)
  FOR i IN 1..25 LOOP
    v_rechnungs_nr := v_rechnungs_nr + 1;
    v_rechnung_id := gen_random_uuid();
    v_kunde_id := v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int];
    v_datum := '2024-01-15'::date + (random() * 340)::int;

    v_rand := random();
    IF v_rand < 0.85 THEN v_status := 'bezahlt';
    ELSIF v_rand < 0.95 THEN v_status := 'gesendet';
    ELSE v_status := 'gemahnt';
    END IF;

    INSERT INTO rechnungen (id, user_id, kunde_id, rechnungs_nr, datum, faellig_am, status, total_netto, mwst_satz, mwst_betrag, total_brutto, qr_referenz)
    VALUES (v_rechnung_id, v_user_id, v_kunde_id, 'RE-' || v_rechnungs_nr, v_datum, v_datum + 30, v_status, 0, 8.10, 0, 0,
            'RF' || LPAD(v_rechnungs_nr::text, 23, '0') || '0');

    v_total_netto := 0;
    FOR j IN 1..(3 + (random() * 4)::int) LOOP
      DECLARE
        v_pos_menge NUMERIC(10,3);
        v_pos_preis NUMERIC(10,2);
        v_pos_einheit TEXT;
        v_pos_bez TEXT;
      BEGIN
        IF j <= 2 THEN
          v_pos_bez := v_arbeit_bezeichnungen[1 + (random() * (array_length(v_arbeit_bezeichnungen, 1) - 1))::int];
          v_pos_menge := (8 + random() * 30)::numeric(10,1);
          v_pos_preis := (105 + random() * 20)::numeric(10,2);
          v_pos_einheit := 'Std';
        ELSE
          v_pos_bez := (SELECT bezeichnung FROM artikel WHERE user_id = v_user_id AND kategorie = 'material' ORDER BY random() LIMIT 1);
          v_pos_menge := (1 + random() * 5)::numeric(10,1);
          v_pos_preis := (150 + random() * 800)::numeric(10,2);
          v_pos_einheit := CASE WHEN random() < 0.5 THEN 'Stk' ELSE 'Pauschale' END;
          IF v_pos_einheit = 'Pauschale' THEN v_pos_menge := 1; v_pos_preis := (500 + random() * 4000)::numeric(10,2); END IF;
        END IF;

        v_total_netto := v_total_netto + (v_pos_menge * v_pos_preis);

        INSERT INTO rechnungs_positionen (rechnung_id, position_nr, bezeichnung, menge, einheit, einheitspreis)
        VALUES (v_rechnung_id, j, v_pos_bez, v_pos_menge, v_pos_einheit, v_pos_preis);
      END;
    END LOOP;

    v_mwst_betrag := ROUND(v_total_netto * 0.081, 2);
    v_total_brutto := v_total_netto + v_mwst_betrag;

    UPDATE rechnungen SET total_netto = v_total_netto, mwst_betrag = v_mwst_betrag, total_brutto = v_total_brutto
    WHERE id = v_rechnung_id;

    -- Buchungen fuer diese Rechnung
    INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id, mwst_code, mwst_satz, mwst_betrag)
    VALUES (v_user_id, v_datum, 1100, 3000, v_total_netto, 'Rechnung RE-' || v_rechnungs_nr, 'BLG-F' || i || 'A', v_rechnung_id, 'UST_NORM', 8.10, v_mwst_betrag);

    IF v_mwst_betrag > 0 THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum, 1100, 2200, v_mwst_betrag, 'MWST RE-' || v_rechnungs_nr, 'BLG-F' || i || 'AM', v_rechnung_id);
    END IF;

    IF v_status = 'bezahlt' THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum + (15 + random() * 25)::int, 1020, 1100, v_total_brutto, 'Zahlung RE-' || v_rechnungs_nr, 'BLG-F' || i || 'AZ', v_rechnung_id);
    END IF;
  END LOOP;

  -- 2025: ~25 zusaetzliche Rechnungen (520k - ~109k = ~411k noetig)
  FOR i IN 1..25 LOOP
    v_rechnungs_nr := v_rechnungs_nr + 1;
    v_rechnung_id := gen_random_uuid();
    v_kunde_id := v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int];
    v_datum := '2025-01-10'::date + (random() * 345)::int;

    v_rand := random();
    IF v_rand < 0.60 THEN v_status := 'bezahlt';
    ELSIF v_rand < 0.85 THEN v_status := 'gesendet';
    ELSE v_status := 'gemahnt';
    END IF;

    INSERT INTO rechnungen (id, user_id, kunde_id, rechnungs_nr, datum, faellig_am, status, total_netto, mwst_satz, mwst_betrag, total_brutto, qr_referenz)
    VALUES (v_rechnung_id, v_user_id, v_kunde_id, 'RE-' || v_rechnungs_nr, v_datum, v_datum + 30, v_status, 0, 8.10, 0, 0,
            'RF' || LPAD(v_rechnungs_nr::text, 23, '0') || '0');

    v_total_netto := 0;
    FOR j IN 1..(3 + (random() * 4)::int) LOOP
      DECLARE
        v_pos_menge NUMERIC(10,3);
        v_pos_preis NUMERIC(10,2);
        v_pos_einheit TEXT;
        v_pos_bez TEXT;
      BEGIN
        IF j <= 2 THEN
          v_pos_bez := v_arbeit_bezeichnungen[1 + (random() * (array_length(v_arbeit_bezeichnungen, 1) - 1))::int];
          v_pos_menge := (10 + random() * 35)::numeric(10,1);
          v_pos_preis := (105 + random() * 20)::numeric(10,2);
          v_pos_einheit := 'Std';
        ELSE
          v_pos_bez := (SELECT bezeichnung FROM artikel WHERE user_id = v_user_id AND kategorie = 'material' ORDER BY random() LIMIT 1);
          v_pos_menge := (1 + random() * 5)::numeric(10,1);
          v_pos_preis := (200 + random() * 1000)::numeric(10,2);
          v_pos_einheit := CASE WHEN random() < 0.5 THEN 'Stk' ELSE 'Pauschale' END;
          IF v_pos_einheit = 'Pauschale' THEN v_pos_menge := 1; v_pos_preis := (800 + random() * 5000)::numeric(10,2); END IF;
        END IF;

        v_total_netto := v_total_netto + (v_pos_menge * v_pos_preis);

        INSERT INTO rechnungs_positionen (rechnung_id, position_nr, bezeichnung, menge, einheit, einheitspreis)
        VALUES (v_rechnung_id, j, v_pos_bez, v_pos_menge, v_pos_einheit, v_pos_preis);
      END;
    END LOOP;

    v_mwst_betrag := ROUND(v_total_netto * 0.081, 2);
    v_total_brutto := v_total_netto + v_mwst_betrag;

    UPDATE rechnungen SET total_netto = v_total_netto, mwst_betrag = v_mwst_betrag, total_brutto = v_total_brutto
    WHERE id = v_rechnung_id;

    INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id, mwst_code, mwst_satz, mwst_betrag)
    VALUES (v_user_id, v_datum, 1100, 3000, v_total_netto, 'Rechnung RE-' || v_rechnungs_nr, 'BLG-G' || i || 'A', v_rechnung_id, 'UST_NORM', 8.10, v_mwst_betrag);

    IF v_mwst_betrag > 0 THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum, 1100, 2200, v_mwst_betrag, 'MWST RE-' || v_rechnungs_nr, 'BLG-G' || i || 'AM', v_rechnung_id);
    END IF;

    IF v_status = 'bezahlt' THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum + (15 + random() * 25)::int, 1020, 1100, v_total_brutto, 'Zahlung RE-' || v_rechnungs_nr, 'BLG-G' || i || 'AZ', v_rechnung_id);
    END IF;
  END LOOP;

  -- 2026: ~8 zusaetzliche Rechnungen (130k - ~80k = ~50k noetig)
  FOR i IN 1..8 LOOP
    v_rechnungs_nr := v_rechnungs_nr + 1;
    v_rechnung_id := gen_random_uuid();
    v_kunde_id := v_kunde_ids[1 + (random() * (array_length(v_kunde_ids, 1) - 1))::int];
    v_datum := '2026-01-05'::date + (random() * 85)::int;

    v_rand := random();
    IF v_rand < 0.20 THEN v_status := 'bezahlt';
    ELSIF v_rand < 0.60 THEN v_status := 'gesendet';
    ELSE v_status := 'entwurf';
    END IF;

    INSERT INTO rechnungen (id, user_id, kunde_id, rechnungs_nr, datum, faellig_am, status, total_netto, mwst_satz, mwst_betrag, total_brutto, qr_referenz)
    VALUES (v_rechnung_id, v_user_id, v_kunde_id, 'RE-' || v_rechnungs_nr, v_datum, v_datum + 30, v_status, 0, 8.10, 0, 0,
            'RF' || LPAD(v_rechnungs_nr::text, 23, '0') || '0');

    v_total_netto := 0;
    FOR j IN 1..(3 + (random() * 3)::int) LOOP
      DECLARE
        v_pos_menge NUMERIC(10,3);
        v_pos_preis NUMERIC(10,2);
        v_pos_einheit TEXT;
        v_pos_bez TEXT;
      BEGIN
        IF j <= 2 THEN
          v_pos_bez := v_arbeit_bezeichnungen[1 + (random() * (array_length(v_arbeit_bezeichnungen, 1) - 1))::int];
          v_pos_menge := (8 + random() * 20)::numeric(10,1);
          v_pos_preis := (105 + random() * 20)::numeric(10,2);
          v_pos_einheit := 'Std';
        ELSE
          v_pos_bez := (SELECT bezeichnung FROM artikel WHERE user_id = v_user_id AND kategorie = 'material' ORDER BY random() LIMIT 1);
          v_pos_menge := (1 + random() * 4)::numeric(10,1);
          v_pos_preis := (150 + random() * 600)::numeric(10,2);
          v_pos_einheit := CASE WHEN random() < 0.5 THEN 'Stk' ELSE 'Pauschale' END;
          IF v_pos_einheit = 'Pauschale' THEN v_pos_menge := 1; v_pos_preis := (500 + random() * 3000)::numeric(10,2); END IF;
        END IF;

        v_total_netto := v_total_netto + (v_pos_menge * v_pos_preis);

        INSERT INTO rechnungs_positionen (rechnung_id, position_nr, bezeichnung, menge, einheit, einheitspreis)
        VALUES (v_rechnung_id, j, v_pos_bez, v_pos_menge, v_pos_einheit, v_pos_preis);
      END;
    END LOOP;

    v_mwst_betrag := ROUND(v_total_netto * 0.081, 2);
    v_total_brutto := v_total_netto + v_mwst_betrag;

    UPDATE rechnungen SET total_netto = v_total_netto, mwst_betrag = v_mwst_betrag, total_brutto = v_total_brutto
    WHERE id = v_rechnung_id;

    INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id, mwst_code, mwst_satz, mwst_betrag)
    VALUES (v_user_id, v_datum, 1100, 3000, v_total_netto, 'Rechnung RE-' || v_rechnungs_nr, 'BLG-H' || i || 'A', v_rechnung_id, 'UST_NORM', 8.10, v_mwst_betrag);

    IF v_mwst_betrag > 0 THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum, 1100, 2200, v_mwst_betrag, 'MWST RE-' || v_rechnungs_nr, 'BLG-H' || i || 'AM', v_rechnung_id);
    END IF;

    IF v_status = 'bezahlt' THEN
      INSERT INTO buchungen (user_id, datum, soll_konto, haben_konto, betrag, beschreibung, beleg_nr, rechnung_id)
      VALUES (v_user_id, v_datum + (15 + random() * 25)::int, 1020, 1100, v_total_brutto, 'Zahlung RE-' || v_rechnungs_nr, 'BLG-H' || i || 'AZ', v_rechnung_id);
    END IF;
  END LOOP;

  -- Konten-Salden neu berechnen
  UPDATE konten SET saldo = COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.soll_konto = konten.kontonummer
  ), 0) - COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.haben_konto = konten.kontonummer
  ), 0)
  WHERE user_id = v_user_id AND typ IN ('aktiv', 'aufwand');

  UPDATE konten SET saldo = COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.haben_konto = konten.kontonummer
  ), 0) - COALESCE((
    SELECT SUM(b.betrag) FROM buchungen b WHERE b.user_id = v_user_id AND b.soll_konto = konten.kontonummer
  ), 0)
  WHERE user_id = v_user_id AND typ IN ('passiv', 'ertrag');

  RAISE NOTICE 'Rechnungen total: %', (SELECT COUNT(*) FROM rechnungen WHERE user_id = v_user_id);
  RAISE NOTICE 'Umsatz 2024: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2024);
  RAISE NOTICE 'Umsatz 2025: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2025);
  RAISE NOTICE 'Umsatz 2026: %', (SELECT COALESCE(SUM(total_brutto), 0) FROM rechnungen WHERE user_id = v_user_id AND EXTRACT(YEAR FROM datum) = 2026);
END;
$$;

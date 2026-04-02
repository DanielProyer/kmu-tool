-- ============================================================================
-- KMU Tool - Migration 002: Row Level Security Policies
-- Jeder Benutzer sieht nur seine eigenen Daten
-- ============================================================================

-- ============================================================================
-- RLS AKTIVIEREN
-- ============================================================================

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kunden ENABLE ROW LEVEL SECURITY;
ALTER TABLE kunden_kontakte ENABLE ROW LEVEL SECURITY;
ALTER TABLE offerten ENABLE ROW LEVEL SECURITY;
ALTER TABLE offert_positionen ENABLE ROW LEVEL SECURITY;
ALTER TABLE auftraege ENABLE ROW LEVEL SECURITY;
ALTER TABLE zeiterfassungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE rapporte ENABLE ROW LEVEL SECURITY;
ALTER TABLE rechnungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE rechnungs_positionen ENABLE ROW LEVEL SECURITY;
ALTER TABLE konten ENABLE ROW LEVEL SECURITY;
ALTER TABLE buchungen ENABLE ROW LEVEL SECURITY;
ALTER TABLE buchungs_vorlagen ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USER_PROFILES: id = auth.uid()
-- ============================================================================

CREATE POLICY "user_profiles_select_own"
  ON user_profiles FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "user_profiles_insert_own"
  ON user_profiles FOR INSERT
  WITH CHECK (id = auth.uid());

CREATE POLICY "user_profiles_update_own"
  ON user_profiles FOR UPDATE
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

CREATE POLICY "user_profiles_delete_own"
  ON user_profiles FOR DELETE
  USING (id = auth.uid());

-- ============================================================================
-- KUNDEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "kunden_select_own"
  ON kunden FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "kunden_insert_own"
  ON kunden FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "kunden_update_own"
  ON kunden FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "kunden_delete_own"
  ON kunden FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- KUNDEN_KONTAKTE: Zugriff ueber Parent (kunden.user_id)
-- ============================================================================

CREATE POLICY "kunden_kontakte_select_own"
  ON kunden_kontakte FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = auth.uid()
    )
  );

CREATE POLICY "kunden_kontakte_insert_own"
  ON kunden_kontakte FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = auth.uid()
    )
  );

CREATE POLICY "kunden_kontakte_update_own"
  ON kunden_kontakte FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = auth.uid()
    )
  );

CREATE POLICY "kunden_kontakte_delete_own"
  ON kunden_kontakte FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM kunden
      WHERE kunden.id = kunden_kontakte.kunde_id
        AND kunden.user_id = auth.uid()
    )
  );

-- ============================================================================
-- OFFERTEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "offerten_select_own"
  ON offerten FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "offerten_insert_own"
  ON offerten FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "offerten_update_own"
  ON offerten FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "offerten_delete_own"
  ON offerten FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- OFFERT_POSITIONEN: Zugriff ueber Parent (offerten.user_id)
-- ============================================================================

CREATE POLICY "offert_positionen_select_own"
  ON offert_positionen FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = auth.uid()
    )
  );

CREATE POLICY "offert_positionen_insert_own"
  ON offert_positionen FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = auth.uid()
    )
  );

CREATE POLICY "offert_positionen_update_own"
  ON offert_positionen FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = auth.uid()
    )
  );

CREATE POLICY "offert_positionen_delete_own"
  ON offert_positionen FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM offerten
      WHERE offerten.id = offert_positionen.offerte_id
        AND offerten.user_id = auth.uid()
    )
  );

-- ============================================================================
-- AUFTRAEGE: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "auftraege_select_own"
  ON auftraege FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "auftraege_insert_own"
  ON auftraege FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "auftraege_update_own"
  ON auftraege FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "auftraege_delete_own"
  ON auftraege FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- ZEITERFASSUNGEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "zeiterfassungen_select_own"
  ON zeiterfassungen FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "zeiterfassungen_insert_own"
  ON zeiterfassungen FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "zeiterfassungen_update_own"
  ON zeiterfassungen FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "zeiterfassungen_delete_own"
  ON zeiterfassungen FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- RAPPORTE: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "rapporte_select_own"
  ON rapporte FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "rapporte_insert_own"
  ON rapporte FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rapporte_update_own"
  ON rapporte FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rapporte_delete_own"
  ON rapporte FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- RECHNUNGEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "rechnungen_select_own"
  ON rechnungen FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "rechnungen_insert_own"
  ON rechnungen FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rechnungen_update_own"
  ON rechnungen FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "rechnungen_delete_own"
  ON rechnungen FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- RECHNUNGS_POSITIONEN: Zugriff ueber Parent (rechnungen.user_id)
-- ============================================================================

CREATE POLICY "rechnungs_positionen_select_own"
  ON rechnungs_positionen FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = auth.uid()
    )
  );

CREATE POLICY "rechnungs_positionen_insert_own"
  ON rechnungs_positionen FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = auth.uid()
    )
  );

CREATE POLICY "rechnungs_positionen_update_own"
  ON rechnungs_positionen FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = auth.uid()
    )
  );

CREATE POLICY "rechnungs_positionen_delete_own"
  ON rechnungs_positionen FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM rechnungen
      WHERE rechnungen.id = rechnungs_positionen.rechnung_id
        AND rechnungen.user_id = auth.uid()
    )
  );

-- ============================================================================
-- KONTEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "konten_select_own"
  ON konten FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "konten_insert_own"
  ON konten FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "konten_update_own"
  ON konten FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "konten_delete_own"
  ON konten FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- BUCHUNGEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "buchungen_select_own"
  ON buchungen FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "buchungen_insert_own"
  ON buchungen FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "buchungen_update_own"
  ON buchungen FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "buchungen_delete_own"
  ON buchungen FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- BUCHUNGS_VORLAGEN: user_id = auth.uid()
-- ============================================================================

CREATE POLICY "buchungs_vorlagen_select_own"
  ON buchungs_vorlagen FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "buchungs_vorlagen_insert_own"
  ON buchungs_vorlagen FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "buchungs_vorlagen_update_own"
  ON buchungs_vorlagen FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "buchungs_vorlagen_delete_own"
  ON buchungs_vorlagen FOR DELETE
  USING (user_id = auth.uid());

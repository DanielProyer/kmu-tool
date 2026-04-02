-- ============================================================
-- 009: RLS Policies für neue Tabellen
-- ============================================================

-- ─── Subscription Plans (jeder Auth-User darf lesen) ───
ALTER TABLE subscription_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "subscription_plans_select" ON subscription_plans
  FOR SELECT TO authenticated
  USING (true);

-- ─── User Subscriptions (nur eigene Zeile) ───
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_subscriptions_select_own" ON user_subscriptions
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_subscriptions_insert_own" ON user_subscriptions
  FOR INSERT TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_subscriptions_update_own" ON user_subscriptions
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ─── Auftrag Notizen ───
ALTER TABLE auftrag_notizen ENABLE ROW LEVEL SECURITY;

-- Owner (Auftrag-Ersteller) hat vollen Zugriff
CREATE POLICY "auftrag_notizen_owner" ON auftrag_notizen
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auftraege a
      WHERE a.id = auftrag_notizen.auftrag_id
      AND a.user_id = auth.uid()
    )
  );

-- User mit Zugriff (vollzugriff/standard) können lesen + erstellen
CREATE POLICY "auftrag_notizen_zugriff_select" ON auftrag_notizen
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_notizen.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle IN ('vollzugriff', 'standard')
    )
  );

CREATE POLICY "auftrag_notizen_zugriff_insert" ON auftrag_notizen
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_notizen.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle IN ('vollzugriff', 'standard')
    )
  );

-- ─── Auftrag Dateien ───
ALTER TABLE auftrag_dateien ENABLE ROW LEVEL SECURITY;

-- Owner hat vollen Zugriff
CREATE POLICY "auftrag_dateien_owner" ON auftrag_dateien
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auftraege a
      WHERE a.id = auftrag_dateien.auftrag_id
      AND a.user_id = auth.uid()
    )
  );

-- User mit Zugriff (vollzugriff/standard) können lesen + erstellen
CREATE POLICY "auftrag_dateien_zugriff_select" ON auftrag_dateien
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_dateien.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle IN ('vollzugriff', 'standard')
    )
  );

CREATE POLICY "auftrag_dateien_zugriff_insert" ON auftrag_dateien
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_dateien.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle IN ('vollzugriff', 'standard')
    )
  );

-- Kunden sehen nur fuer_kunde_sichtbar Dateien
CREATE POLICY "auftrag_dateien_kunde_select" ON auftrag_dateien
  FOR SELECT TO authenticated
  USING (
    fuer_kunde_sichtbar = true
    AND EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_dateien.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle = 'kunde'
    )
  );

-- Kunden können Dateien hochladen
CREATE POLICY "auftrag_dateien_kunde_insert" ON auftrag_dateien
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM auftrag_zugriffe az
      WHERE az.auftrag_id = auftrag_dateien.auftrag_id
      AND az.user_id = auth.uid()
      AND az.rolle = 'kunde'
    )
  );

-- ─── Auftrag Zugriffe ───
ALTER TABLE auftrag_zugriffe ENABLE ROW LEVEL SECURITY;

-- Owner (Auftrag-Ersteller) verwaltet Zugriffe
CREATE POLICY "auftrag_zugriffe_owner" ON auftrag_zugriffe
  FOR ALL TO authenticated
  USING (owner_user_id = auth.uid());

-- User sieht eigene Zugriffe
CREATE POLICY "auftrag_zugriffe_user_select" ON auftrag_zugriffe
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

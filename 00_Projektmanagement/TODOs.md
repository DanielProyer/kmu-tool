# KMU Tool - Offene TODOs

## Build & Setup
- [ ] `flutter pub get` ausfuehren
- [ ] `build_runner` ausfuehren (Isar + Riverpod Codegen)
- [ ] Erster Kompilier-Test: `flutter build web`
- [ ] `flutter run -d chrome` Live-Test

## Code-Qualitaet
- [ ] AppColors-Refactor: `AppColors.primary` → `Theme.of(context).colorScheme` in allen Screens
- [ ] Back-Button zum Dashboard fehlt auf einigen Screens

## Buchhaltung
- [ ] Berichte-Screen: Periodenfilterung fuer Buchungen implementieren
- [ ] MWST `_autoSuggestMwstCode`: User-Einstellung lesen statt hardcoded `isEffektiv=true`
- [ ] Kontenplan-Screen: Konto-Bearbeitung ermoeglichen (aktuell read-only)

## Geplante Features (naechste Phase)
- [ ] Feature-Flag-System (Abo-Modell: Free/Standard/Premium)
- [ ] Flexibles Theme-System (4-5 waehlbare Designs)
- [ ] Auftrag-Dashboard (Notizen, Dateien, Zugriffsstufen - Premium-Feature)
- [ ] Einstellungen-Screen (Theme-Wahl, Plan-Info, MWST-Einstellungen)
- [ ] Auto-Website (automatisch generierte Mini-Website pro Betrieb)

## Datenbank-Vorbereitungen
- [ ] Migration: `bank_konten` Tabelle (fuer camt-Import)
- [ ] Migration: `mitarbeiter` Tabelle (fuer Lohnbuchhaltung)
- [ ] Migration: `subscription_plans` + `user_subscriptions` (Feature-Gating)

## Deployment
- [ ] Nach erfolgreichem Build: Push auf main → GitHub Pages Auto-Deploy
- [ ] Testen auf echtem Smartphone (Mobile-First Validierung)

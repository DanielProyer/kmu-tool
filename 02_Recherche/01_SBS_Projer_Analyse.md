# Analyse: SBS Projer - Learnings für KMU Tool

## Projektübersicht SBS Projer
- **Kunde**: SBS Projer GmbH (Daniel Projer), Heineken-Franchise-Partner in Graubünden
- **Zweck**: Digitalisierung eines Zapfanlagen-Service-Betriebs (~250 Kunden)
- **Ziel**: 80% Zeitersparnis bei Administration (20h/Woche → 3h/Woche)
- **Status**: Funktional zu ~95% fertig (Version 0.2.10+14)

## Tech-Stack
| Komponente | Technologie |
|---|---|
| Frontend | Flutter (Dart) |
| State Management | Riverpod 2.5 + GoRouter 14 |
| Lokale DB (Offline) | Isar 3.1 (NoSQL) |
| Backend | Supabase (PostgreSQL, Auth, Storage, Edge Functions) |
| PDF-Generierung | Dart `pdf` Package |
| OCR/KI | Claude Haiku 4.5 via Supabase Edge Function |
| Bankimport | camt.053 XML-Parser |

## Architektur-Highlights
- **Offline-First**: Lokale Isar-DB + Cloud-Sync mit Supabase
- **Clean Architecture**: data/models, data/repositories, presentation/screens, services
- **Push/Pull Sync**: Inkrementell via Timestamps, Last-Write-Wins
- **Multi-Plattform**: Web, Android, iOS, Windows

## Implementierte Module (relevant für KMU Tool)

### Direkt übertragbar
1. **Kundenverwaltung (Betriebe)** → Kundenstamm
   - CRUD, Kontakte, Rechnungsadressen, Regionen
2. **Materialverwaltung** → Materialverwaltung
   - Lager, Bestandstracking, Bestellliste
3. **Rechnungswesen** → Rechnungswesen
   - PDF mit Swiss QR-Einzahlungsschein, Mahnwesen (Stufen 0-3)
4. **Buchhaltung** → Buchhaltung
   - 61 Konten (KMU-Standard), Journal, Erfolgsrechnung, MwSt-Abrechnung
   - OCR Spesen-Scanner, camt.053 Bankimport
5. **Terminverwaltung** → Auftragswesen (teilweise)

### SBS-spezifisch (nicht übertragbar)
- Zapfanlagen-Management, Bierleitungen
- Heineken-spezifische Formulare und Preislisten
- Reinigungsprotokolle (17-Punkt-Checkliste)
- Pikett-Dienste

## Datenbank-Design Highlights
- **24+ Tabellen**, 24 RLS Policies, 20 Trigger/Functions
- **38 Migrationen** - gut strukturierte Datenbankentwicklung
- **Seed-Daten**: Kontenplan, Buchungsvorlagen, Materialstamm
- **Row Level Security** durchgehend implementiert

## Learnings für KMU Tool

### Was gut funktioniert hat
1. **Flutter + Supabase** als Tech-Stack (Score 56/60)
2. **Offline-First** Architektur für mobile Nutzung
3. **Clean Architecture** mit klarer Trennung
4. **Swiss QR-Rechnung** Integration
5. **KMU-Kontenrahmen** als Basis für Buchhaltung
6. **OCR-Scanner** für Belege (Claude Haiku)
7. **camt.053** Bankimport für Schweizer Banken

### Was verbessert werden sollte
1. **Generalisierung**: SBS Projer ist stark auf einen Kunden zugeschnitten
2. **Multi-Tenancy**: KMU Tool braucht echtes Multi-User/Multi-Firma Setup
3. **Branchen-Flexibilität**: Verschiedene Handwerksberufe unterstützen
4. **Skalierbarkeit**: Von 1 auf hunderte Betriebe skalieren
5. **Onboarding**: Einfacher Setup-Prozess für neue Kunden
6. **Conditional Exports** (Isar ↔ Web) sind komplex - evtl. einfachere Lösung

### Technische Überlegungen
- **Flutter vs. Web-Framework?**: Flutter bewährt sich, aber für reine WebApp evtl. React/Next.js?
- **Supabase** hat sich bewährt (23 CHF/Monat, robust)
- **Offline-Sync** ist komplex aber wichtig für Handwerker unterwegs
- **PDF-Generierung** am Client funktioniert gut

## Kostenbasis (SBS Projer)
- Supabase Pro: 23 CHF/Monat
- Entwicklungszeit: ~2 Monate (mit Claude)
- Betriebskosten: Sehr niedrig

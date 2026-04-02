# KMU Tool - Projektkontext

## Projektziel
WebTool für kleine Handwerksbetriebe (ausschliesslich GmbH) in der Schweiz mit 1-10 Angestellten.
Alle geschäftsrelevanten Aufgaben sollen über das Smartphone erledigt werden können.

## Rechtsform-Entscheid
- **Nur GmbH** - keine Einzelunternehmen, keine AG
- Doppelte Buchhaltung ist Pflicht (OR Art. 957)
- Immer vollständiger Kontenrahmen KMU
- Revisionsstelle: Opting-Out möglich (< 10 VZÄ)

## Kernbereiche
- Kundenstamm
- Auftragswesen
- Materialverwaltung
- Rechnungswesen
- Buchhaltung (doppelte Buchhaltung, Schweizer Kontenrahmen)
- Auto-Website (automatisch generierte Mini-Website mit Online-Offertanfrage & Terminbuchung)

## Verwandtes Projekt
- **SBS Projer** (`D:\01_SBS_Projer_GmbH\00_Entwicklung\SBS Projer DEV`)
- Flutter + Supabase, Offline-First, ähnliche Module
- Dieses KMU Tool ist die allgemeinere, vermarktbare Version

## Technische Entscheidungen
- **Frontend**: Flutter (Dart) - Web + App-Option offen
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Offline-DB**: Isar (lokale NoSQL-Datenbank)
- **State Management**: Riverpod + GoRouter
- **Offline-First**: Zwingend (Handwerker im Keller/Berggebiet)
- **Sync**: Push/Pull mit Supabase, Last-Write-Wins

## Phasen
1. Recherche (aktuell)
2. Planung
3. Umsetzung
4. Testphase
5. Roll Out
6. Marketing
7. Support

## Projektstruktur
```
00_Projektmanagement/  - Übersicht, Phasenplan, Notizen
01_Prompts/            - Prompts für Claude
02_Recherche/          - Recherche-Ergebnisse Phase 1
03_Planung/            - Architektur, Anforderungen, Datenmodell
04_Entwicklung/        - Source Code
05_Testing/            - Testpläne, Testprotokolle
06_Deployment/         - Deployment-Konfiguration
07_Marketing/          - Marketingmaterial
08_Support/            - Support-Dokumentation
```

## Konventionen
- Dokumentation: Deutsch (Schweiz)
- Markdown für alle Dokumente
- Währung: CHF
- Rechtsform: Fokus auf Schweizer GmbH

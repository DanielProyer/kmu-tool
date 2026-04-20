# KMU Tool — Roadmap

Stand: April 2026 | Branch: feature/angebots-generator-modul

---

## Vision

Mobile-First WebApp für Schweizer Handwerksbetriebe (GmbH, 1–10 MA). Alle Geschäftsprozesse auf dem Smartphone. KI-unterstützt, Offline-First, Schweiz-spezifisch.

---

## Phasen

### Phase 1 — Recherche ✅
- Marktanalyse (CH, Graubünden)
- Wettbewerbsanalyse (bexio, SORBA, KLARA)
- Compliance-Recherche (Buchhaltung, MwSt, Lohn, Bankanbindung)
- Tech-Stack-Entscheid (Flutter + Supabase + Isar)
- Architektur-Evaluation (April 2026)

### Phase 2 — Planung (aktuell)
- [ ] MVP-Scope definieren
- [ ] Datenmodell finalisieren
- [ ] Sync-Strategie Multi-User klären
- [ ] Isar-Entscheid: Abstractions-Layer ODER Migration zu Drift
- [ ] App Store vs. PWA entscheiden
- [ ] Pricing-Modell festlegen

### Phase 3 — MVP (Kern-Workflow)
Ziel: Offerte → Auftrag → Rapport → Rechnung — vollständig auf dem Smartphone.

### Phase 4 — Erweiterungen
Zusatzmodule nach MVP-Validierung.

### Phase 5 — Roll Out
Beta-Testing Graubünden, dann CH-weit.

### Phase 6 — Marketing & Support

---

## Module & Features

### Legende
| Symbol | Bedeutung |
|---|---|
| ✅ | Implementiert |
| 🔄 | In Arbeit |
| 📋 | Geplant (MVP) |
| 💡 | Geplant (Phase 4+) |
| ❓ | Evaluiert, Entscheid offen |
| ❌ | Bewusst ausgeschlossen |

---

### Modul 1 — Kundenstamm
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Kunden CRUD (Name, Adresse, Kontakte) | 📋 | MVP | |
| Kommunikationshistorie | 📋 | MVP | |
| Suche & Filter | 📋 | MVP | |
| Dokumente pro Kunde | 💡 | Phase 4 | |
| Kundenportal (Login für Kunden) | ❓ | Offen | Aufwand hoch |

---

### Modul 2 — Auftragswesen
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Offerten erstellen | 📋 | MVP | |
| KI-Angebots-Generator | 🔄 | MVP | Aus AutoMate, Branch: feature/angebots-generator-modul |
| Offerte → Auftrag umwandeln | 📋 | MVP | |
| Auftragsstatus-Tracking | 📋 | MVP | |
| Rapporte & Protokolle | 📋 | MVP | |
| Zeiterfassung (Einstempeln/Ausstempeln) | 📋 | MVP | |
| Aufgaben pro Auftrag | 📋 | MVP | |
| Fotos & Dokumente pro Auftrag | 📋 | MVP | |
| KI-Sprachprotokoll (Sprachnachricht → PDF) | 💡 | Phase 4 | Whisper API + Claude |
| Termin- & Routenoptimierer | 💡 | Phase 4 | Google Maps + Claude, relevant für GR |
| Kalender-Integration | 💡 | Phase 4 | |

---

### Modul 3 — Materialverwaltung
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Lager & Bestände | 📋 | MVP | |
| Lieferanten-Verwaltung | 📋 | MVP | |
| Bestellwesen | 📋 | Phase 4 | |
| Foto → Materialliste (OCR) | 💡 | Phase 4 | Lieferschein fotografieren, Claude Vision |

---

### Modul 4 — Rechnungswesen
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Rechnungen erstellen | 📋 | MVP | |
| Swiss QR-Rechnung | 📋 | MVP | QR-IBAN, Modulo-10-Prüfziffer |
| Mahnwesen (manuell) | 📋 | MVP | |
| Mahnwesen-Automatisierung | 💡 | Phase 4 | 3-stufig: freundlich → formal → ernst; aus AutoMate |
| Teilzahlungen | 💡 | Phase 4 | |
| Gutschriften | 💡 | Phase 4 | |
| camt.054 Bankimport | 💡 | Phase 4 | Automatischer Debitorenabgleich |

---

### Modul 5 — Buchhaltung
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Doppelte Buchhaltung (OR Art. 957) | 📋 | MVP | Pflicht für GmbH |
| Schweizer Kontenrahmen KMU (61 Konten) | 📋 | MVP | |
| Buchungsjournal | 📋 | MVP | |
| MwSt-Abrechnung (effektiv + Saldosteuersatz) | 📋 | MVP | |
| Jahresabschluss (Bilanz, ER) | 📋 | Phase 4 | |
| 10-Jahres-Archiv (GeBüV) | 📋 | MVP | Write-Once PDFs in Supabase Storage |
| OCR Belegscanner | 💡 | Phase 4 | Claude Vision für Speseneingabe |
| camt.053 Kontoauszug-Import | 💡 | Phase 4 | |
| ESTV eCH-0217 MwSt-Export | 💡 | Phase 4 | |

---

### Modul 6 — Lohnbuchhaltung ⚠️
> Nur als Light-Version. Kein ELM/swissdec. Pflicht-Disclaimer auf jeder Berechnung.

| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Brutto/Netto-Kalkulator | 💡 | Phase 4 | AHV/IV/EO/ALV, BVG, UVG |
| PDF-Lohnzettel | 💡 | Phase 4 | |
| Lohnausweis (Formular 11) | 💡 | Phase 4 | Bis 31. Jan. fällig |
| ELM/swissdec-Zertifizierung | ❌ | — | Zu teuer (CHF 5k–15k), zu komplex für MVP |
| Quellensteuer | ❓ | Offen | Kantonale Tarife komplex |

---

### Modul 7 — Auto-Website (USP)
| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| Automatisch generierte Mini-Website | ✅ | MVP | Supabase Edge Function SSR (Deno), kein Flutter Web |
| SEO (JSON-LD, Meta-Tags) | ✅ | MVP | Bereits implementiert |
| Online-Offertanfrage | 📋 | MVP | |
| Terminbuchung | 📋 | Phase 4 | |
| Custom Domain Mapping | 📋 | MVP | Cloudflare-Proxy nötig |
| robots.txt & Sitemap | 📋 | MVP | |
| Cache-Layer (Cloudflare CDN) | 💡 | Phase 4 | |
| Projekt-Portfolio (Fotos) | 💡 | Phase 4 | Aufträge → Auto-Galerie |
| Google-Bewertungs-Manager | 💡 | Phase 4 | Nach Auftragsabschluss Bewertungsanfrage; aus AutoMate |
| Digitale Visitenkarte (QR) | 💡 | Phase 4 | Erweiterung Auto-Website |

---

### Modul 8 — Kommunikation & KI-Assistenten
> Neue Kategorie, inspiriert durch AutoMate.

| Feature | Status | Priorität | Hinweis |
|---|---|---|---|
| WhatsApp-Sekretär | 💡 | Phase 4 | KI beantwortet Erstanfragen, WhatsApp Business API |
| Normen-Check Assistent | 💡 | Phase 4+ | NIV, SIA — branchenspezifisch, mit Disclaimer |
| Social-Media-Generator | 💡 | Phase 5 | Foto + Sprache → Instagram/Facebook-Post |
| KI-Recruiting & Stellenanzeigen | 💡 | Phase 5 | Nach Lohnbuchhaltung sinnvoll |
| Mitarbeiter-Onboarding | 💡 | Phase 5 | Für Betriebe mit Lernenden |

---

### Infrastruktur & Plattform
| Feature | Status | Hinweis |
|---|---|---|
| Flutter (iOS, Android, Web) | ✅ | Bewährt durch SBS Projer |
| Supabase (PostgreSQL, Auth, Storage, Edge Functions) | ✅ | |
| Offline-First (Isar / Drift) | ✅ | Isar 3.1 — Entscheid Abstractions-Layer vs. Drift Migration offen |
| Riverpod + GoRouter | ✅ | |
| Multi-Tenancy (RLS) | ✅ | 27+ Migrationen vorhanden |
| Sync Last-Write-Wins | ✅ | Conflict-Detection für Multi-User einplanen |
| Offline Conflict-Detection | 📋 | Vor Launch testen |
| Feature-Flags (Free/Standard/Premium) | 📋 | |
| Flexibles Theme-System | 💡 | |

---

## Offene strategische Entscheidungen

| Entscheidung | Optionen | Dringlichkeit |
|---|---|---|
| App Store (iOS/Android) vs. PWA | Native Distribution vs. Browser | Hoch — beeinflusst Deployment |
| Isar beibehalten vs. Drift Migration | Abstractions-Layer (1–2 Tage) vs. Migration (1 Woche) | Hoch — vor weiteren Offline-Modulen klären |
| MVP-Scope | Welche Module in Phase 3? | Hoch |
| Lohnbuchhaltung Disclaimer | Formulierung & rechtliche Abgrenzung | Mittel |
| Mahnwesen: automatisch ab Phase 3 oder 4? | Im MVP oder Erweiterung? | Mittel |

---

## Verwandte Projekte

| Projekt | Pfad | Relevanz |
|---|---|---|
| SBS Projer | `D:\01_SBS_Projer_GmbH\00_Entwicklung\SBS Projer DEV` | Gleicher Stack, ~95% fertig, Learnings direkt übertragbar |
| AutoMate | `C:\Users\teech\Antigravity\AutoMate` | Angebots-Generator wird Modul; weitere KI-Features als Inspiration |

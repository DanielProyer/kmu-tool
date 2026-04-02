# Analyse: Erste Überlegungen des Projektleiters

*Datum: 01.04.2026*
*Quelle: 01_Prompts/Erste Überlegungen*

---

## Überlegungen mit Einordnung und Kommentar

### 1. "Nur für GmbH / Fokussierung auf Einzelunternehmen und Mikrobetriebe"

**Einordnung**: Kernentscheidung zur Zielgruppe.

**Kommentar**: Das ist eine kluge Fokussierung. In der Schweiz gibt es zwei relevante Rechtsformen für unsere Zielgruppe:
- **Einzelunternehmen (Einzelfirma)**: Einfachste Form, unter CHF 500'000 Umsatz reicht Milchbüchleinrechnung
- **GmbH**: Ab einer gewissen Grösse/Risiko → doppelte Buchhaltung Pflicht

**Entscheid Projektleiter: Fokus ausschliesslich auf GmbH.**

**Impact auf Entwicklung**:
- Keine vereinfachte Buchhaltung nötig → immer doppelte Buchhaltung
- Vollständiger Schweizer Kontenrahmen KMU von Anfang an
- GmbH hat immer mindestens 1 Geschäftsführer → Lohnbuchhaltung immer relevant
- Stammkapital (min. CHF 20'000) in der Bilanz
- Revisionsstelle: Opting-Out bei < 10 VZÄ (= unsere ganze Zielgruppe)
- Klarere Zielgruppe = einfacheres Marketing

---

### 2. "Unterscheidung Geschäftsführer und Angestellte"

**Einordnung**: Benutzerrollen und Berechtigungen.

**Kommentar**: Essentiell für Multi-User. Bei SBS Projer war das ein Single-User-System. Jetzt brauchen wir:
- **Geschäftsführer/Chef**: Vollzugriff (Buchhaltung, Rechnungen, Löhne, Einstellungen)
- **Angestellte**: Eingeschränkt (Zeiterfassung, Rapporte, Materialentnahme, eigene Aufträge)

**Mögliche Rollenstruktur**:
| Rolle | Zugriff |
|-------|---------|
| **Admin/Chef** | Alles (Buchhaltung, Löhne, Rechnungen, Einstellungen) |
| **Vorarbeiter/Teamleiter** | Aufträge, Rapporte, Material, Team-Zeiterfassung |
| **Mitarbeiter** | Eigene Zeiterfassung, zugewiesene Aufträge, Rapporte |

---

### 3. "Geschäftsautos berücksichtigen"

**Einordnung**: Fuhrparkverwaltung / Buchhaltung.

**Kommentar**: Für Handwerker sehr relevant:
- **Fahrtenbuch**: Privat vs. geschäftlich (steuerlich relevant)
- **Kilometererfassung**: Pro Auftrag/Kunde
- **Fahrzeugkosten**: Leasing, Versicherung, Service, Treibstoff
- **Privatanteil**: MwSt-relevant (0.9% des Anschaffungswerts/Monat oder Fahrtenbuch)
- **Buchhaltung**: Konto 6200 (Fahrzeugaufwand)

**Empfehlung**: Einfache Fahrzeugverwaltung als Teil des Auftragsmoduls:
- Fahrzeug erfassen (Kennzeichen, Typ)
- Kilometerstand pro Auftrag (automatisch via GPS optional)
- Monatliche Kostenübersicht

---

### 4. "Kleines Lager am Betriebsstandort (Bestellungen)"

**Einordnung**: Materialverwaltung.

**Kommentar**: Genau wie bei SBS Projer bewährt. Handwerker haben:
- **Fahrzeuglager**: Material im Bus/Transporter
- **Betriebslager**: Kleines Lager am Standort
- **Bestellbedarf**: Wenn Mindestbestand unterschritten → Bestellliste

**Aus SBS Projer übertragbar**:
- Material-Kategorien, Bestandstracking
- Materialverbrauch pro Auftrag
- Bestellliste mit Export (Clipboard/E-Mail an Lieferant)

---

### 5. "Zeiterfassung integrieren"

**Einordnung**: Kernfunktion.

**Kommentar**: Absolut zentral für Handwerker:
- **Stempeluhr**: Kommen/Gehen (gesetzlich vorgeschrieben ab 2024 für alle MA)
- **Auftragsbezogene Zeit**: Welcher MA hat wie lange an welchem Auftrag gearbeitet
- **Pausenregelung**: Automatisch oder manuell
- **Überstunden**: Berechnung, Kompensation, Auszahlung
- **Fahrtzeit**: Zum Kunden und zurück
- **Rapport**: Zeiterfassung + Materialeinsatz + Beschreibung = Arbeitsrapport

**Verknüpfung mit anderen Modulen**:
- Zeiterfassung → Auftragskosten berechnen
- Zeiterfassung → Rechnungsstellung (Stundensatz × Stunden)
- Zeiterfassung → Lohnbuchhaltung (Monatsstunden)

---

### 6. "Tool soll sehr einfach und intuitiv zu bedienen sein, Ziel: keine Schulung"

**Einordnung**: UX/Design-Grundsatz #1.

**Kommentar**: Das ist DAS entscheidende Kriterium. Handwerker sind:
- Oft nicht tech-affin
- Arbeiten mit dreckigen/nassen Händen → grosse Buttons
- Haben wenig Zeit für Administration
- Frustriert von komplexer Software → wechseln schnell zurück zu Papier

**Design-Prinzipien**:
1. **Maximal 3 Klicks** für jede häufige Aktion
2. **Grosse Touch-Targets** (mindestens 48px)
3. **Kontextabhängige Funktionen**: Nur zeigen was gerade relevant ist
4. **Smart Defaults**: Möglichst viel vorausfüllen
5. **Wizard-Prinzip**: Komplexe Abläufe Schritt für Schritt
6. **Offline-fähig**: Kein Frust im Keller/Berggebiet
7. **Sprachlich einfach**: Keine Buchhaltungsfachbegriffe → "Einnahmen" statt "Erträge"

---

### 7. "Einfache Anpassung an verschiedene Handwerksbetriebe"

**Einordnung**: Konfigurierbarkeit / Multi-Branchen.

**Kommentar**: Verschiedene Branchen haben unterschiedliche Workflows:

| Branche | Besonderheiten |
|---------|---------------|
| **Elektriker** | Sicherheitsprüfungen, NIV-Formulare, Schemata |
| **Sanitär** | Notfall-Dienst, Heizungs-Wartung, Leitungspläne |
| **Maler/Gipser** | Farbmischungen, Flächen-Kalkulation |
| **Schreiner** | Werkstatt + Montage, Materiallisten, CAD-Anbindung |
| **Gärtner/Landschaftsbau** | Saisonarbeit, Wetter-Abhängigkeit |
| **Dachdecker** | Sicherheitsvorschriften, Gerüstplanung |

**Umsetzung**:
- **Branchenvorlagen** beim Onboarding wählbar
- **Konfigurierbare Felder**: Betrieb kann eigene Felder hinzufügen
- **Modulare Aktivierung**: Nicht jeder braucht jedes Modul
- **Kern-Workflow gleich**: Offerte → Auftrag → Rapport → Rechnung (branchenunabhängig)

---

### 8. "Offerterstellung berücksichtigen / genauer anschauen"

**Einordnung**: Offert-/Angebotswesen → **Noch zu recherchieren!**

**Was wir wissen**:
- Handwerker erstellen Offerten oft per Hand oder Word/Excel
- Offerte enthält: Positionen, Mengen, Einheitspreise, Total, MwSt
- Oft mit Pauschalpreisen oder Stundenansätzen
- Gültigkeitsdauer, Zahlungsbedingungen

**Noch zu klären (mit Handwerksbetrieben)**:
- Welche Offert-Formate sind üblich?
- Wie detailliert sind Offerten? (Pauschal vs. Einzelpositionen)
- Wird nachverhandelt? Wie oft werden Offerten angepasst?
- Branchenspezifische Unterschiede?
- NPK-Positionen (Normpositionen-Katalog) relevant?

**→ TODO: Interviews mit 3-5 Handwerksbetrieben planen**

---

### 9. "Auftragsbestätigung und Auftragsverwaltung"

**Einordnung**: Auftrags-Lifecycle.

**Kommentar**: Der vollständige Ablauf:
```
Anfrage → Offerte → [Anpassung] → Auftragsbestätigung → Planung → Ausführung → Rapport → Rechnung → Zahlung
```

Jeder Schritt muss im Tool abgebildet werden mit:
- **Status-Tracking**: Wo steht jeder Auftrag?
- **Dokumenten-Kette**: Offerte → AB → Rapport → Rechnung verknüpft
- **Nummerierung**: Durchgehende Nummernkreise (OFF-2026-001, AB-2026-001, RE-2026-001)

---

### 10. "Viele Betriebe machen das meiste noch mit Papier oder Excel"

**Einordnung**: Bestätigung der Marktlücke.

**Aus der Recherche bestätigt**:
- SBS Projer hatte **67 Excel-Workbooks** als "ERP"
- Digitalisierungsgrad im Handwerk am niedrigsten aller Branchen
- Hauptargument im Marketing: **"Tausche 5 Excel-Listen gegen 1 App"**

**Migrationshilfe**:
- Excel-Import für bestehende Kundenlisten
- Schritt-für-Schritt Onboarding
- Erste 30 Tage gratis testen

---

### 11. "Integration aller Pflichtversicherungen"

**Einordnung**: Lohnbuchhaltung / Compliance.

**Pflichtversicherungen für CH-Arbeitgeber**:
| Versicherung | Pflicht | Beitragssatz |
|-------------|---------|-------------|
| AHV/IV/EO | Ja | 10.6% (je 5.3%) |
| ALV | Ja | 2.2% (je 1.1%) bis CHF 148'200 |
| BVG (Pensionskasse) | Ja, ab CHF 22'680 | 7-18% altersabhängig |
| UVG Berufsunfall | Ja | Branchenabhängig (AG zahlt) |
| UVG Nichtberufsunfall | Ja, ab 8h/Woche | AN zahlt |
| Familienzulagen (FAK) | Ja | ~1-3% (AG zahlt) |
| Krankentaggeld (KTG) | Empfohlen | ~1-2% |

**Umsetzung im Tool**: Automatische Berechnung aller Abzüge bei der Lohnabrechnung.

---

### 12. "Wissensdatenbank integrieren"

**Einordnung**: Mehrwert-Feature.

**Kommentar**: Spannende Idee! Mögliche Inhalte:
- **Buchhaltungs-Basics**: "Was ist ein Kontenrahmen?" → einfach erklärt
- **MwSt-Guide**: Wann welcher Satz? Saldosteuersatz ja/nein?
- **Rechtliches**: Aufbewahrungspflichten, Versicherungspflichten
- **Branchentipps**: Best Practices pro Handwerk
- **FAQ**: Häufige Fragen direkt im Tool beantwortet
- **KI-Assistent**: "Frag den Assistenten" → kontextbezogene Hilfe

**Umsetzung**: Kontextsensitive Hilfe-Bubbles + durchsuchbarer Wissensbereich.

---

### 13. "Aufbewahrungspflicht berücksichtigen (Gesetz Schweiz)"

**Einordnung**: Compliance / Archivierung.

**Gesetzliche Grundlage (OR Art. 958f)**:
- **10 Jahre Aufbewahrungspflicht** für alle Geschäftsbücher und Belege
- Digital oder physisch (seit 2025 strengere Regeln für digitale Archivierung)
- Belege müssen jederzeit reproduzierbar sein

**Umsetzung im Tool**:
- Automatische Archivierung aller Dokumente (Offerten, ABs, Rechnungen, Rapporte)
- PDF-Export jederzeit möglich
- Keine Löschung von Geschäftsdokumenten (nur Stornierung)
- Backup-Strategie transparent kommunizieren
- **Verkaufsargument**: "Deine 10-Jahres-Aufbewahrungspflicht? Erledigt."

---

## Zusammenfassung: Priorisierung für MVP

### Must-Have (MVP Phase 1)
1. Kundenstamm (einfach)
2. Offerten erstellen
3. Auftragsbestätigung + Auftragsverwaltung
4. Zeiterfassung (einfach: Kommen/Gehen + Auftragsbezogen)
5. Arbeitsrapport
6. Rechnungsstellung (Swiss QR-Rechnung)
7. Einfache Buchhaltung
8. Rollen: Chef vs. Mitarbeiter

### Should-Have (MVP Phase 2)
9. Materialverwaltung (Lager + Bestellung)
10. Kalender / Auftragsplanung
11. Fahrzeugverwaltung
12. Auto-Website mit Online-Offertanfrage
13. MwSt-Abrechnung

### Nice-to-Have (Spätere Versionen)
14. Lohnbuchhaltung mit allen Versicherungen
15. Wissensdatenbank
16. Bankimport (camt.053)
17. OCR Belegscanner
18. Branchenspezifische Vorlagen
19. Multi-Team Planung

# Sozialversicherungen & Lohnabrechnung Schweiz

> Recherche-Dokument fuer das KMU Tool
> Zielgruppe: Kleine Handwerksbetriebe (GmbH, 1-10 Mitarbeiter) in der Schweiz
> Stand: April 2026 (Beitragssaetze 2025/2026)

---

## Inhaltsverzeichnis

1. [Sozialversicherungen Ueberblick](#1-sozialversicherungen-ueberblick)
2. [Lohnabrechnung](#2-lohnabrechnung)
3. [Lohnausweis Formular 11](#3-lohnausweis-formular-11)
4. [ELM / swissdec](#4-elm--swissdec)
5. [Quellensteuer](#5-quellensteuer)
6. [FAK / Familienzulagen](#6-fak--familienzulagen)
7. [Buchhaltung Lohn](#7-buchhaltung-lohn)
8. [Umsetzungsempfehlung](#8-umsetzungsempfehlung)

---

## 1. Sozialversicherungen Ueberblick

### 1.1 Drei-Saeulen-System

| Saeule | Zweck | Obligatorisch |
|--------|-------|---------------|
| 1. Saeule (AHV/IV/EO) | Existenzsicherung | Ja, fuer alle |
| 2. Saeule (BVG) | Lebensstandard-Sicherung | Ja, ab Eintrittsschwelle |
| 3. Saeule (3a/3b) | Individuelle Ergaenzung | Freiwillig |

### 1.2 Komplette Beitragssatztabelle 2025/2026

| Versicherung | Arbeitnehmer (AN) | Arbeitgeber (AG) | Total | Bemerkungen |
|---|---|---|---|---|
| **AHV** | 4.35% | 4.35% | 8.70% | Auf gesamtem Lohn |
| **IV** | 0.70% | 0.70% | 1.40% | Auf gesamtem Lohn |
| **EO** | 0.25% | 0.25% | 0.50% | Auf gesamtem Lohn |
| **AHV/IV/EO Total** | **5.30%** | **5.30%** | **10.60%** | Auf gesamtem Lohn, kein Plafond |
| **ALV** | 1.10% | 1.10% | 2.20% | Bis max. CHF 148'200/Jahr |
| **ALV Solidaritaet** | - | - | - | *Seit 01.01.2023 aufgehoben* |
| **UVG BU** | 0% | 100% | variabel | Handwerk: ca. 1-5% je Branche |
| **UVG NBU** | 100% | 0% | variabel | Durchschnitt ca. 1.0-1.8% |
| **BVG** | mind. 50% | mind. 50% | variabel | Nach Alter, s. Abschnitt 1.5 |
| **FAK** | 0% | 100% | variabel | Kantonal, ca. 1.0-3.0% |
| **KTG** (freiwillig) | max. 50% | mind. 50% | variabel | Falls Versicherung abgeschlossen |

**Wichtig**: AHV/IV/EO werden immer zusammen als ein Abzug ausgewiesen (5.30% AN / 5.30% AG).

### 1.3 AHV / IV / EO im Detail

**Gesetzliche Grundlage**: AHVG, IVG, EOG

- **Beitragssatz total**: 10.60% (je haelftig AN/AG)
- **Beitragspflicht**: Auf dem gesamten AHV-pflichtigen Lohn (kein Maximalbetrag)
- **AHV-pflichtig**: Loehne, Provisionen, Gratifikationen, 13. Monatslohn, Ferienentschaedigung
- **Nicht AHV-pflichtig**: Kinderzulagen (FAK), Taggelder UVG/KTG (werden separat abgerechnet)
- **Verwaltungskosten**: Zusaetzlich ca. 0.5-2.0% je nach Ausgleichskasse (AG-seitig)

Freibetrag fuer AHV-Rentner/innen, die weiterarbeiten: CHF 16'800/Jahr (ab 2024).

### 1.4 ALV (Arbeitslosenversicherung)

**Gesetzliche Grundlage**: AVIG

| Parameter | Wert 2025/2026 |
|---|---|
| Beitragssatz | 2.20% (je 1.10% AN/AG) |
| Hoechstversicherter Verdienst | CHF 148'200/Jahr (CHF 12'350/Monat) |
| Solidaritaetsbeitrag (> 148'200) | **Entfaellt seit 01.01.2023** |

**Praxisrelevanz fuer Handwerker**: Bei einem Monatslohn von CHF 5'500 brutto = CHF 66'000/Jahr ist der Maximalbetrag nie ein Thema. Relevant wird es nur bei Geschaeftsfuehrern mit hohen Loehnen.

### 1.5 BVG (Berufliche Vorsorge / 2. Saeule)

**Gesetzliche Grundlage**: BVG, BVV2

#### Kennzahlen 2025/2026

| Parameter | Wert |
|---|---|
| Eintrittsschwelle | CHF 22'680/Jahr |
| Koordinationsabzug | CHF 26'460/Jahr (7/8 der max. AHV-Rente) |
| Minimaler koordinierter Lohn | CHF 3'780/Jahr |
| Maximaler versicherter Lohn (obligatorisch) | CHF 90'720/Jahr |
| Maximaler koordinierter Lohn | CHF 64'260/Jahr |
| BVG-Mindestzins | 1.25% (seit 2024) |

#### Berechnung des versicherten Lohns

```
Versicherter Lohn (koordinierter Lohn) = AHV-Jahreslohn - Koordinationsabzug
Beispiel: CHF 66'000 - CHF 26'460 = CHF 39'540
```

#### Altersgutschriften (Mindest-Sparbeitraege BVG-Obligatorium)

| Alter | Altersgutschrift (% des koord. Lohns) | Anteil AG (mind.) | Anteil AN (mind.) |
|---|---|---|---|
| 25-34 | 7% | 3.5% | 3.5% |
| 35-44 | 10% | 5.0% | 5.0% |
| 45-54 | 15% | 7.5% | 7.5% |
| 55-64/65 | 18% | 9.0% | 9.0% |

**Hinweis**: Dies sind die **gesetzlichen Mindestsaetze**. Viele Pensionskassen versichern ueberobligatorisch mit hoeheren Saetzen. AG traegt mindestens 50%, kann aber freiwillig mehr uebernehmen.

#### Beispielrechnung Handwerker, Alter 38

```
Jahreslohn brutto:              CHF 66'000
- Koordinationsabzug:           CHF 26'460
= Koordinierter Lohn:           CHF 39'540
  Altersgutschrift (10%):       CHF  3'954/Jahr
  davon AG mind. 50%:           CHF  1'977
  davon AN mind. 50%:           CHF  1'977
  = AN-Abzug pro Monat:         CHF    165
```

#### Risikobeitraege

Zusaetzlich zu den Sparbeitraegen erheben Pensionskassen Risikobeitraege fuer:
- Invaliditaetsrente
- Todesfallleistungen (Witwen-/Waisenrente)
- Verwaltungskosten

Diese variieren je nach PK stark (ca. 1-3% des versicherten Lohns), werden ebenfalls paritaetisch getragen.

### 1.6 UVG (Unfallversicherung)

**Gesetzliche Grundlage**: UVG, UVV

#### Berufsunfall (BU) - 100% Arbeitgeber

| Branche | Praemie BU (ca.) | Versicherer |
|---|---|---|
| Bueroarbeit | 0.1-0.5% | SUVA oder Privatversicherer |
| Malerarbeiten | 1.5-2.5% | SUVA (obligatorisch) |
| Elektroinstallation | 1.5-3.0% | SUVA |
| Sanitaer/Heizung | 2.0-3.5% | SUVA |
| Schreiner/Zimmerer | 3.0-5.0% | SUVA |
| Dachdecker | 4.0-6.0% | SUVA |
| Bauhauptgewerbe | 4.0-7.0% | SUVA |

**SUVA-Pflicht**: Handwerksbetriebe sind in der Regel **zwingend bei der SUVA** versichert (gemaess UVV Art. 66).

#### Nichtberufsunfall (NBU) - 100% Arbeitnehmer

- **Pflicht**: Fuer Arbeitnehmer mit mind. 8 Stunden/Woche beim gleichen AG
- **Praemie**: Ca. 1.0-1.8% des versicherten Lohns (branchenabhaengig)
- **Maximaler versicherter Verdienst UVG**: CHF 148'200/Jahr (identisch mit ALV)

#### UVG-Leistungen

- 80% des versicherten Verdienstes als Taggeld (ab 3. Tag)
- Die ersten 2 Tage: AG zahlt 100% des Lohns
- Heilungskosten vollumfaenglich
- Integritaetsentschaedigung bei Dauerschaeden
- Invalidenrenten, Hinterlassenenrenten

### 1.7 KTG (Krankentaggeldversicherung)

**Gesetzliche Grundlage**: VVG (privatrechtlich, nicht obligatorisch) / OR Art. 324a

#### Lohnfortzahlungspflicht nach OR Art. 324a

Ohne KTG-Versicherung gilt die gesetzliche Lohnfortzahlungspflicht. Die Dauer richtet sich nach Dienstjahren und der anwendbaren Skala:

**Berner Skala** (Mehrheit der Kantone: AG, AI, AR, BE, FR, GE, GL, JU, LU, NE, NW, OW, SO, SZ, TI, UR, VD, VS, ZG):

| Dienstjahr | Dauer Lohnfortzahlung |
|---|---|
| 1. Jahr | 3 Wochen |
| 2. Jahr | 1 Monat |
| 3.-4. Jahr | 2 Monate |
| 5.-9. Jahr | 3 Monate |
| 10.-14. Jahr | 4 Monate |
| 15.-19. Jahr | 5 Monate |
| 20.-25. Jahr | 6 Monate |

**Zuercher Skala** (ZH, SH, TG, GR):

| Dienstjahr | Dauer Lohnfortzahlung |
|---|---|
| 1. Jahr | 3 Wochen |
| 2. Jahr | 8 Wochen |
| 3. Jahr | 9 Wochen |
| 4. Jahr | 10 Wochen |
| 5.-9. Jahr | +1 Woche pro Jahr |
| 10. Jahr | 17 Wochen |

**Basler Skala** (BS, BL):

| Dienstjahr | Dauer Lohnfortzahlung |
|---|---|
| 1. Jahr | 3 Wochen |
| 2.-3. Jahr | 2 Monate |
| 4.-10. Jahr | 3 Monate |
| 11.-15. Jahr | 4 Monate |
| 16.-20. Jahr | 5 Monate |
| ab 21. Jahr | 6 Monate |

#### KTG-Versicherung als Loesung

Eine KTG-Versicherung ist eine **aequivalente Loesung** gemaess OR Art. 324a Abs. 4 und ersetzt die gesetzliche Lohnfortzahlungspflicht, wenn:
- Wartefrist max. 30 Tage (meistens 30, 60 oder 90 Tage)
- 80% des versicherten Lohns waehrend 720 Tagen innerhalb von 900 aufeinanderfolgenden Tagen
- Praemie wird mindestens haelftig durch AG getragen

| Wartefrist | Praemie AN ca. | Praemie AG ca. | Total ca. |
|---|---|---|---|
| 30 Tage | 0.7-1.2% | 0.7-1.2% | 1.4-2.4% |
| 60 Tage | 0.5-0.9% | 0.5-0.9% | 1.0-1.8% |
| 90 Tage | 0.3-0.7% | 0.3-0.7% | 0.6-1.4% |

**Empfehlung fuer KMU**: KTG-Versicherung mit 30 Tagen Wartefrist abschliessen. Die 30 Karenztage traegt der AG (Lohnfortzahlung 100%), danach uebernimmt die Versicherung 80%.

---

## 2. Lohnabrechnung

### 2.1 Brutto-Netto-Beispiel (Handwerker, Monatslohn)

**Ausgangslage**: Sanitaerinstallateur, 35 Jahre, Kanton Zuerich, verheiratet, 1 Kind, Monatslohn CHF 5'500

#### Lohnabrechnung Beispiel

```
BRUTTOLOHN                                        CHF  5'500.00
+ 13. Monatslohn (anteilig 1/12)                  CHF    458.35
= Basis fuer Sozialversicherungen                 CHF  5'958.35

ABZUEGE ARBEITNEHMER:
- AHV/IV/EO           5.30%    von 5'958.35       CHF   -315.80
- ALV                  1.10%    von 5'958.35       CHF    -65.55
- UVG NBU              1.40%    von 5'958.35       CHF    -83.40
- BVG (Sparen+Risiko)  ca. 5.5% von 3'295.00*     CHF   -181.25
- KTG (falls versich.) 0.80%    von 5'958.35       CHF    -47.65
----------------------------------------------------------
Total Abzuege AN                                   CHF   -693.65

= NETTOLOHN                                       CHF  5'264.70

KOSTEN ARBEITGEBER (zusaetzlich zum Brutto):
+ AHV/IV/EO           5.30%                       CHF    315.80
+ ALV                  1.10%                       CHF     65.55
+ UVG BU              2.50%                        CHF    148.95
+ BVG AG-Anteil        ca. 5.5%                    CHF    181.25
+ KTG AG-Anteil        0.80%                       CHF     47.65
+ FAK                  1.50%                        CHF     89.40
+ AHV Verwaltung       0.40%                        CHF     23.85
----------------------------------------------------------
Total AG-Kosten zusaetzlich                        CHF    872.45

TOTALE LOHNKOSTEN ARBEITGEBER:                     CHF  6'830.80

*koordinierter Lohn: (5'958.35 x 12 - 26'460) / 12 = CHF 3'753.35
 BVG-Beitrag: Altersgutschrift 10% + Risiko 2% = ca. 12% / 2 AN-Anteil
```

**Faustregel**: AG-Kosten betragen ca. **115-120%** des Bruttolohns (inkl. 13. Monatslohn und Sozialversicherungen).

### 2.2 Stundenlohn-Besonderheiten

Fuer Handwerker im Stundenlohn gelten besondere Regeln:

#### Ferienentschaedigung im Stundenlohn

| Ferienanspruch | Zuschlag auf Stundenlohn |
|---|---|
| 4 Wochen (20 Tage) | 8.33% |
| 5 Wochen (25 Tage) | 10.64% |
| 6 Wochen (30 Tage) | 13.04% |

**Berechnung**: Zuschlag = Ferientage / (260 Arbeitstage - Ferientage)

| Ferienanspruch | Berechnung | Zuschlag |
|---|---|---|
| 4 Wochen | 20 / (260 - 20) = 20/240 | 8.33% |
| 5 Wochen | 25 / (260 - 25) = 25/235 | 10.64% |
| 6 Wochen | 30 / (260 - 30) = 30/230 | 13.04% |

**Wichtig**: Der Ferienanteil muss auf jeder Lohnabrechnung **separat ausgewiesen** werden (OR Art. 329d Abs. 2).

#### 13. Monatslohn bei Stundenlohn

- Zuschlag: 8.33% auf den Stundenlohn (1/12)
- Kann separat ausgewiesen oder im Stundenlohn integriert werden
- Muss im Arbeitsvertrag klar geregelt sein

#### Beispiel Stundenlohn-Abrechnung

```
Grundstundenlohn:                    CHF   35.00
+ Ferienentschaedigung 10.64%:       CHF    3.72
+ 13. Monatslohn 8.33%:              CHF    2.92
= Stundenlohn inkl. Zuschlaege:      CHF   41.64

Bei 180 Stunden/Monat:
Bruttolohn: 180 x CHF 41.64 =       CHF 7'495.20
```

### 2.3 13. Monatslohn

- **Kein gesetzlicher Anspruch** in der Schweiz (ausser GAV/NAV)
- In der Praxis ueblich und fuer Handwerks-GAVs oft vorgeschrieben
- Auszahlung: Ende Jahr oder anteilig pro Monat (1/12)
- **AHV-pflichtig**: Ja, in jedem Fall
- **BVG-relevant**: Ja, zaehlt zum Jahreslohn

### 2.4 Spesenregelung

| Spesenart | Effektiv | Pauschal (genehmigt) |
|---|---|---|
| Verpflegung auswarts (Mittag) | Beleg | CHF 17.50/Tag |
| Uebernachtung | Beleg | Je nach Ort |
| Fahrzeugentschaedigung (privates Auto) | - | CHF 0.70/km |
| Kleinspesen | - | CHF 20/Tag (kantonal) |
| Natel/Mobile | Beleg | Abonnement-Anteil |

**Spesenreglement**: Genehmigtes Spesenreglement durch die kantonale Steuerverwaltung vereinfacht die Handhabung. Pauschale Spesen mit genehmigtem Reglement muessen auf dem Lohnausweis unter Ziffer 13.1.1 deklariert werden, jedoch **nicht** bei Ziffer 1 (Lohn).

---

## 3. Lohnausweis Formular 11

### 3.1 Ueberblick

Der Lohnausweis (Formular 11) ist das offizielle Formular der Schweizerischen Steuerkonferenz (SSK) fuer die jaehrliche Deklaration des Lohns. Er muss bis **Ende Januar** des Folgejahres erstellt und dem Arbeitnehmer uebergeben werden.

### 3.2 Ziffern 1-15 im Detail

| Ziffer | Bezeichnung | Inhalt / Erklaerung |
|---|---|---|
| **1** | Lohn (inkl. Zulagen) | Bruttolohn, 13. Monatslohn, Provisionen, Gratifikationen, Ferienentschaedigung, Schicht-/Pikettzulagen. Ohne Kinderzulagen, ohne UVG/KTG-Taggelder |
| **2** | Gehaltsnebenleistungen | Privatanteil Geschaeftswagen (0.9% des Kaufpreises/Monat, mind. CHF 150/Monat), vergünstigte Mahlzeiten, Dienstwohnung, Aktien/Optionen |
| **2.1** | Verpflegung/Unterkunft | Unentgeltliche Mahlzeiten: CHF 17.50/Mittag, Unterkunft: CHF 11.50/Tag |
| **2.2** | Privatanteil Geschaeftswagen | 0.9% des Kaufpreises pro Monat (seit 2022), inkl. Arbeitsweg |
| **2.3** | Andere Gehaltsnebenleistungen | Weitere geldwerte Vorteile (z.B. vergünstigte Produkte) |
| **3** | Unregelmaessige Leistungen | Einmalige oder aperiodische Zahlungen: Abgangsentschaedigung, Dienstaltersgeschenke, Ueberbrueckungsrenten |
| **4** | Kapitalleistungen | Kapitalabfindungen bei Stellenverlust, Treueprämien in Kapitalform |
| **5** | Beteiligungsrechte | Mitarbeiteraktien, Optionen (Zuteilung und Ausuebung) |
| **6** | Verwaltungsratsentschaedigung | Mandate als VR-Mitglied (auch Tantiemen) |
| **7** | Andere Leistungen | Auffangposition fuer nicht zuordenbare Leistungen |
| **8** | Brutto total | Summe aus Ziffern 1-7 |
| **9** | AHV/IV/EO/ALV-Beitraege | Tatsaechlich abgezogene AN-Beitraege (5.30% + 1.10% = 6.40%) |
| **10** | BVG Ordentliche Beitraege | AN-Beitraege an die Pensionskasse (Sparen + Risiko) |
| **10.1** | BVG Einkauf | Freiwillige Einkauefe in die PK (steuerlich abzugsfaehig) |
| **10.2** | Beitraege 3a | Falls AG-seitig einbezahlt (selten) |
| **11** | Nettolohn | Ziffer 8 minus Ziffer 9 minus Ziffer 10 (= steuerbarer Lohn) |
| **12** | Quellensteuer | Abgezogene Quellensteuer (nur bei quellensteuerpflichtigen Personen) |
| **13** | Spesen | |
| **13.1** | Effektive Spesen | 13.1.1 Reise/Verpflegung/Uebernachtung, 13.1.2 Uebrige |
| **13.2** | Pauschale Spesen | 13.2.1 Repraesentation, 13.2.2 Auto, 13.2.3 Uebrige |
| **13.3** | Beitraege an Berufskosten | Aus-/Weiterbildung, Berufskleidung |
| **14** | Weitere Angaben | Bemerkungsfeld: KTG-Beitraege, SUVA-NBU-Beitraege etc. |
| **15** | Kreuzfelder | F: Unentgeltliche Befoerderung Wohn-/Arbeitsort, G: Kantinenverpflegung |

### 3.3 Typischer Lohnausweis Handwerker

Fuer einen typischen Handwerker sind relevant:
- **Ziffer 1**: Bruttolohn + 13. Monatslohn + Ferienentschaedigung
- **Ziffer 2.2**: Falls Firmenwagen vorhanden (Privatanteil)
- **Ziffer 9**: AHV/IV/EO/ALV-Abzuege
- **Ziffer 10**: BVG-Beitraege
- **Ziffer 13.1.1**: Effektive Reisespesen
- **Ziffer 14**: KTG-Beitraege, NBU-Beitraege
- **Ziffer 15 F**: Falls Firmenwagen / GA

---

## 4. ELM / swissdec

### 4.1 Was ist swissdec / ELM?

**ELM** = Einheitliches Lohnmeldeverfahren (Uniform Salary Reporting Procedure)

swissdec ist der Verein, der den Standard fuer die elektronische Uebermittlung von Lohndaten in der Schweiz verwaltet. Das Ziel: **eine einzige Deklaration** aus der Lohnsoftware, die automatisch an alle relevanten Empfaenger verteilt wird.

### 4.2 Technische Architektur

```
┌──────────────┐     SOAP/XML      ┌──────────────────┐
│  ERP / Lohn- │ ──────────────►   │   swissdec       │
│  software    │   TLS-verschl.    │   Distributor     │
│  (zertifiz.) │ ◄──────────────   │   (Drehscheibe)  │
└──────────────┘    Quittungen     └──────┬───────────┘
                                          │
                    ┌─────────────────────┤
                    │         │           │          │         │        │
                    ▼         ▼           ▼          ▼         ▼        ▼
                  AHV/FAK   UVG/UVGZ    KTG        BVG       QST     BFS
                  (Ausgl.-  (SUVA/      (Vers.-    (Pensions- (Steuer- (Bundes-
                   kassen)   Privat)     gesell.)    kassen)   aemter)  amt f.
                                                                       Statistik)
```

#### Protokoll und Datenformat

| Aspekt | Detail |
|---|---|
| Transportprotokoll | SOAP 1.1 ueber HTTPS |
| Datenformat | XML (Schema-definiert durch swissdec) |
| Verschluesselung | TLS 1.2+ (Transport), optional WS-Security |
| Authentifizierung | Zertifikatsbasiert (Client-Zertifikat) |
| Nachrichtenformat | XML gemaess swissdec Richtlinien (RL-LDV, RL-LDUE) |
| Versionen | Aktuell: ELM 5.0 (Pflicht ab 2026), ELM 5.3 (neueste Minor) |

### 4.3 Die 6 Domaenen

| Domaene | Empfaenger | Inhalt |
|---|---|---|
| **AHV/FAK** | Ausgleichskassen (z.B. SVA, AK) | Jahreslohnsummen, AHV-Beitraege, Familienzulagen |
| **UVG/UVGZ** | SUVA / Privatversicherer | Lohnsummen fuer BU/NBU, Unfallmeldungen |
| **KTG** | Krankentaggeld-Versicherer | Versicherte Lohnsummen, Mutationen |
| **BVG** | Pensionskassen | Ein-/Austritt, Lohnaenderungen, Zivilstandsaenderungen |
| **QST** | Kantonale Steuerverwaltungen | Quellensteuer-Abrechnungen (monatlich/jaehrlich) |
| **Statistik (BFS)** | Bundesamt fuer Statistik | Lohnstrukturerhebung (LSE), jaehrlich |

### 4.4 Meldungsarten

| Meldung | Frequenz | Domaenen |
|---|---|---|
| Jahresmeldung (Lohndeklaration) | Jaehrlich (Jan-Feb) | AHV, UVG, KTG, BVG, Statistik |
| Monatsmeldung QST | Monatlich | QST |
| Eintritts-/Austrittsmeldung | Ad-hoc | AHV, UVG, KTG, BVG |
| Lohnaenderungsmeldung | Ad-hoc | BVG |
| Adressaenderung | Ad-hoc | Alle |

### 4.5 Zertifizierungsanforderungen

Fuer eine vollstaendige swissdec-Zertifizierung muss eine Lohnsoftware:

1. **Fachliche Anforderungen erfuellen**: Korrekte Berechnung aller Sozialversicherungsbeitraege gemaess Richtlinien (RL-LDV)
2. **Technische Anforderungen erfuellen**: SOAP/XML korrekt implementieren (RL-LDUE)
3. **Testverfahren bestehen**: Validierung ueber swissdec Testsysteme
4. **Alle 6 Domaenen abdecken**: AHV, UVG, KTG, BVG, QST, Statistik
5. **Zertifizierungsgebuehr**: CHF 5'000-15'000+ (je nach Umfang)
6. **Laufende Pflege**: Jaehrliche Anpassungen an neue Saetze/Tarife

**ELM 5.3** (aktuellste Version): Erweitert um Grenzgaengermeldung Frankreich, Telearbeit-/Reiseanteile und Bescheinigungspflicht bei Austritten.

### 4.6 Zertifizierte ERP-Hersteller (Auswahl)

Aktuell sind ueber 40 Softwareloesungen fuer ELM 5.0+ zertifiziert, darunter:
- Abacus, Sage, SwissSalary, bexio, Infoniqa ONE, Run my Accounts, Crésus, PINUS

---

## 5. Quellensteuer

### 5.1 Wer ist quellensteuerpflichtig?

| Personengruppe | Quellensteuerpflichtig? |
|---|---|
| Schweizer Buerger mit Niederlassung | Nein (ordentliche Veranlagung) |
| Niedergelassene (Ausweis C) | Nein (ordentliche Veranlagung) |
| Aufenthalter (Ausweis B) | **Ja** |
| Kurzaufenthalter (Ausweis L) | **Ja** |
| Grenzgaenger (Ausweis G) | **Ja** (kantonsabhaengig, DBA) |
| Asylsuchende (Ausweis N/F) | **Ja** |

**Ausnahme**: Aufenthalter (B) mit einem Bruttojahreseinkommen ueber CHF 120'000 werden nachtraeglich ordentlich veranlagt (seit 2021), aber die Quellensteuer wird trotzdem monatlich erhoben und spaeter angerechnet.

### 5.2 Tarifcodes

| Tarif | Beschreibung |
|---|---|
| **A** | Alleinstehend (ledig, geschieden, getrennt, verwitwet) ohne Kinder |
| **B** | Verheiratet, Alleinverdiener |
| **C** | Verheiratet, Doppelverdiener |
| **D** | Nebenerwerb (Zweitverdienst bei anderem AG) |
| **E** | Im Abrechnungsverfahren (Ersatzeinkuenfte) |
| **F** | Grenzgaenger Italien (DBA-CH/IT) |
| **G** | Grenzgaenger allgemein (ersetzt alte Modelle) |
| **H** | Alleinstehend mit Kindern (Alleinerziehende) |

#### Tarifcode-Zusammensetzung

Der vollstaendige Code besteht aus:
```
[Buchstabe][Anzahl Kinder][Konfession]
Beispiel: B1N = Verheiratet, 1 Kind, ohne Kirchensteuer
          A0Y = Alleinstehend, 0 Kinder, mit Kirchensteuer
          C2N = Verheiratet Doppelverdiener, 2 Kinder, ohne Kirche
```

### 5.3 Kantonale Unterschiede

| Aspekt | Mehrheit der Kantone | GE, FR, VD, VS, TI |
|---|---|---|
| Abrechnungsperiode | Monatlich | Jaehrlich (Quartal-Meldung) |
| Tarife | Monatstarife | Jahrestarife |
| Kirchensteuer | Integriert (Y/N) | Integriert |

**Praxisrelevanz fuer Handwerker**: Ausweis-B-Inhaber kommen in der Baubranche haeufig vor (Portugiesen, Kosovaren, etc.). Die korrekte QST-Abrechnung ist daher fuer Handwerksbetriebe besonders wichtig.

### 5.4 Arbeitgeber-Pflichten

1. **Tarifcode bestimmen** (aufgrund Meldung des Arbeitnehmers / Bewilligung)
2. **Quellensteuer monatlich berechnen** und vom Lohn abziehen
3. **Abrechnung an kantonale Steuerverwaltung** (via ELM oder manuell)
4. **Bezugsprovision**: Der AG erhaelt eine Bezugsprovision von 1-2% der abgelieferten QST

---

## 6. FAK / Familienzulagen

### 6.1 Gesetzliche Grundlage

**FamZG** (Bundesgesetz ueber die Familienzulagen) + kantonale Gesetze

### 6.2 Mindestansaetze (bundesrechtlich, ab 2025)

| Zulage | Betrag pro Monat | Alter |
|---|---|---|
| **Kinderzulage** | mind. CHF 215 | Bis 16 Jahre |
| **Ausbildungszulage** | mind. CHF 268 | 16-25 Jahre (in Ausbildung) |
| Geburtszulage (kantonal) | CHF 0-2'000 | Einmalig bei Geburt |
| Adoptionszulage (kantonal) | CHF 0-2'000 | Einmalig bei Adoption |

### 6.3 Kantonale Ansaetze (Auswahl 2025/2026)

| Kanton | Kinderzulage | Ausbildungszulage | FAK-Beitrag AG (ca.) |
|---|---|---|---|
| **Zuerich (ZH)** | CHF 215 / 268* | CHF 268 | 1.2-2.5% |
| **Bern (BE)** | CHF 230 | CHF 290 | 1.5-2.8% |
| **Luzern (LU)** | CHF 215 | CHF 268 | 1.5-2.5% |
| **Graubuenden (GR)** | CHF 240 | CHF 290 | 1.3-2.2% |
| **St. Gallen (SG)** | CHF 230 | CHF 280 | 1.5-2.5% |
| **Aargau (AG)** | CHF 225 | CHF 278 | 1.5-2.5% |
| **Wallis (VS)** | CHF 305 | CHF 430 | 2.5-3.5% |
| **Waadt (VD)** | CHF 300 | CHF 400 | 2.5-3.3% |
| **Genf (GE)** | CHF 311 | CHF 415 | 2.3-3.0% |

*ZH: CHF 215 bis 12 Jahre, CHF 268 ab 12-16 Jahre (Abstufung)

**Hinweis**: Die FAK-Beitragssaetze haengen von der jeweiligen Ausgleichskasse und der Branche ab. Handwerksbetriebe mit vielen Mitarbeitern mit Kindern zahlen tendenziell hoehere Saetze.

### 6.4 Wichtige Regeln

- **Finanzierung**: 100% durch den Arbeitgeber (Beitrag an FAK)
- **Auszahlung**: Der AG zahlt die Kinderzulage mit dem Lohn aus und verrechnet sie mit der FAK
- **Anspruchskonkurrenz**: Bei Doppelverdiener-Eltern zahlt nur ein Elternteil (Erstanspruch des im Erwerbskanton wohnhaften Elternteils)
- **Differenzzahlung**: Der andere Elternteil erhaelt ggf. eine Differenzzahlung, wenn der eigene Kanton hoehere Ansaetze hat
- **Teilzeitbeschaeftigte**: Volle Kinderzulage auch bei Teilzeit (keine Kuerzung)
- **Nicht AHV-pflichtig**: Kinderzulagen unterliegen NICHT der AHV/ALV-Beitragspflicht

### 6.5 Buchhalterische Behandlung

Kinderzulagen sind fuer den AG ein **Durchlaufposten**:
- AG zahlt Beitraege an FAK (Aufwand)
- AG zahlt Kinderzulagen an MA aus (Durchlauf)
- AG verrechnet Kinderzulagen mit FAK (Gutschrift)
- Netto-Aufwand = FAK-Beitraege minus rueckerstattete Zulagen

---

## 7. Buchhaltung Lohn

### 7.1 Relevante Konten (Schweizer Kontenrahmen KMU)

#### Klasse 5 - Personalaufwand

| Konto | Bezeichnung | Verwendung |
|---|---|---|
| **5000** | Loehne | Bruttoloehne Produktion/Handwerk |
| **5200** | Loehne Verwaltung / Buero | Bruttoloehne Buero/Administration |
| **5700** | Sozialversicherungsaufwand | AHV/IV/EO/ALV/FAK AG-Anteil |
| **5710** | AHV/IV/EO/ALV (AG-Anteil) | Spezifisch AHV etc. |
| **5720** | FAK (AG-Beitraege) | Familienausgleichskasse |
| **5730** | BVG (AG-Anteil) | Pensionskasse Arbeitgeberanteil |
| **5740** | UVG BU (AG) | Berufsunfallversicherung |
| **5750** | KTG (AG-Anteil) | Krankentaggeld AG-Anteil |
| **5800** | Uebriger Personalaufwand | Personalsuche, Weiterbildung |
| **5810** | Aus- und Weiterbildung | Schulungen, Kurse |
| **5820** | Spesen | Effektive Spesen, Spesenverguetungen |
| **5830** | Berufskleidung | Arbeitskleidung, Schutzausruestung |
| **5900** | Leistungen Dritter | Temporaerarbeit, Subunternehmer |

#### Bilanzkonten

| Konto | Bezeichnung | Verwendung |
|---|---|---|
| **1020** | Bank | Lohnzahlung, SV-Zahlungen |
| **1091** | Transitorische Aktiven | Vorausbezahlte Loehne |
| **2270** | Verbindlichkeit AHV/IV/EO/ALV | Geschuldete Beitraege AN+AG |
| **2271** | Verbindlichkeit FAK | Geschuldete FAK-Beitraege minus Zulagen |
| **2272** | Verbindlichkeit BVG | Geschuldete PK-Beitraege AN+AG |
| **2273** | Verbindlichkeit UVG | Geschuldete UVG-Praemien |
| **2274** | Verbindlichkeit KTG | Geschuldete KTG-Praemien |
| **2279** | Verbindlichkeit Quellensteuer | Quellensteuer AN (treuh. Schuld) |
| **2300** | Transitorische Passiven | Rueckstellungen 13. ML, Ferien, Ueberzeit |

### 7.2 Buchungssaetze fuer den Lohnlauf

#### Schritt 1: Bruttolohn buchen

```
Soll 5000 Loehne                   5'500.00
    Haben 2270 Verb. AHV/IV/EO/ALV           315.80  (AN 5.30%)
    Haben 2270 Verb. AHV/IV/EO/ALV            65.55  (ALV AN 1.10%)
    Haben 2273 Verb. UVG                       83.40  (NBU AN)
    Haben 2272 Verb. BVG                      181.25  (PK AN)
    Haben 2274 Verb. KTG                       47.65  (KTG AN)
    Haben 1020 Bank                         4'806.35  (Nettolohn)
```

#### Schritt 2: AG-Anteile Sozialversicherungen buchen

```
Soll 5710 AHV/IV/EO/ALV AG         315.80
Soll 5710 AHV/IV/EO/ALV AG          65.55  (ALV AG)
Soll 5740 UVG BU                   148.95
Soll 5730 BVG AG                    181.25
Soll 5750 KTG AG                     47.65
Soll 5720 FAK                        89.40
    Haben 2270 Verb. AHV/IV/EO/ALV           381.35  (AG 5.30% + 1.10%)
    Haben 2273 Verb. UVG                      148.95
    Haben 2272 Verb. BVG                      181.25
    Haben 2274 Verb. KTG                       47.65
    Haben 2271 Verb. FAK                       89.40
```

#### Schritt 3: Kinderzulagen (falls Anspruch)

```
Soll 2271 Verb. FAK                215.00  (Verrechnung mit FAK)
    Haben 1020 Bank                           215.00  (Auszahlung an MA)
```

#### Schritt 4: Quellensteuer (falls quellensteuerpflichtig)

```
Soll 5000 Loehne wird NICHT belastet
(QST-Abzug erfolgt VOR der Netto-Auszahlung in Schritt 1)

Anpassung Schritt 1:
    Haben 2279 Verb. Quellensteuer            xxx.xx
    Haben 1020 Bank                   (Netto minus QST)
```

#### Schritt 5: Zahlung der Sozialversicherungsbeitraege

```
AHV/IV/EO/ALV quartalsweise:
Soll 2270 Verb. AHV/IV/EO/ALV    x'xxx.xx
    Haben 1020 Bank                         x'xxx.xx

BVG monatlich:
Soll 2272 Verb. BVG                 xxx.xx
    Haben 1020 Bank                           xxx.xx
```

### 7.3 Rueckstellungen

#### 13. Monatslohn

Monatlich 1/12 des Jahreslohns als Rueckstellung:
```
Soll 5000 Loehne                    458.35  (5'500 / 12)
    Haben 2300 Transitorische Passiven        458.35
```

Bei Auszahlung Ende Jahr:
```
Soll 2300 Transitorische Passiven 5'500.00
    Haben 1020 Bank                         5'500.00
```

#### Ferienanspruch

Nicht bezogene Ferientage per 31.12. muessen als Rueckstellung erfasst werden:
```
Tageslohn = CHF 5'500 / 21.75 Arbeitstage = CHF 252.87
Beispiel: 5 unbezogene Ferientage = CHF 1'264.35

Soll 5000 Loehne                  1'264.35
    Haben 2300 Transitorische Passiven      1'264.35
```

#### Ueberzeitguthaben

Analog zu Ferien muessen auch Ueberzeitguthaben per 31.12. zurueckgestellt werden.

---

## 8. Umsetzungsempfehlung

### 8.1 Strategische Optionen

| Option | Beschreibung | Aufwand | Risiko |
|---|---|---|---|
| **A: Keine Lohnabrechnung** | Nur Verweis auf externe Software (bexio, Abacus) | Minimal | Kein, aber USP fehlt |
| **B: Lohn-Light (MVP)** | Brutto/Netto-Berechnung, Lohnabrechnung PDF | Mittel | Gering |
| **C: Hybridansatz** | Eigene Berechnung + swissdec-Partner fuer ELM | Hoch | Mittel |
| **D: Volle Lohn-Suite** | Eigene swissdec-Zertifizierung | Sehr hoch | Hoch |

### 8.2 Empfehlung: Hybridansatz (Option C)

#### Phase 1 - MVP (Lohn-Light)

**Eigene Berechnung im KMU Tool**:
- Bruttolohn erfassen (Monats- oder Stundenlohn)
- Automatische Berechnung aller Abzuege (AHV, ALV, BVG, UVG-NBU, KTG)
- Nettolohn berechnen
- Lohnabrechnung als PDF generieren
- 13. Monatslohn und Ferienentschaedigung berechnen
- Spesenerfassung

**Nicht im MVP**:
- Keine ELM-Uebermittlung
- Keine Quellensteuer-Berechnung (zu komplex fuer MVP)
- Kein Lohnausweis-Formular 11

#### Phase 2 - Erweitert

**Zusaetzlich**:
- Quellensteuer-Berechnung (Import kantonaler Tarife von ESTV)
- Lohnausweis PDF (Formular 11)
- Rueckstellungen automatisch verbuchen
- Lohnjournal/Lohnliste
- Integration Zeiterfassung → Stundenlohn-Abrechnung

#### Phase 3 - ELM via Partner

**swissdec-Partner-Integration**:
- Anbindung an zertifizierten Distributor (z.B. via API)
- Export der Lohndaten im swissdec-XML-Format
- Partner uebernimmt die eigentliche ELM-Uebermittlung
- Alternative: bLink-Schnittstelle (Banken/Versicherungen)

### 8.3 Datenmodell-Hinweise

#### Mitarbeiter-Stammdaten (Erweiterung bestehend)

```dart
// Erweiterung des bestehenden Modells
class MitarbeiterLohn {
  String mitarbeiterId;

  // Lohnbasis
  LohnTyp lohnTyp;         // MONAT, STUNDE
  double bruttolohn;        // Monatslohn oder Stundenlohn
  int ferienAnspruch;       // Tage pro Jahr (20, 25, 30)
  bool hatMonatslohn13;     // 13. Monatslohn ja/nein
  double beschaeftigungsgrad; // 100, 80, 60...

  // Sozialversicherungen
  String ahvNummer;         // 756.xxxx.xxxx.xx
  bool bvgPflichtig;
  String pensionskasseId;
  bool ktgVersichert;
  bool uvgNbuPflichtig;     // >= 8h/Woche

  // Quellensteuer
  bool quellensteuerpflichtig;
  String? qstTarifcode;     // z.B. "B1N"
  String? qstKanton;        // Erwerbskanton

  // Familienzulagen
  int anzahlKinder;
  List<Kind> kinder;        // Name, Geburtsdatum, in Ausbildung

  // Bankverbindung
  String iban;
}
```

#### Lohnlauf

```dart
class Lohnlauf {
  String id;
  DateTime periode;         // Monat/Jahr
  LohnlaufStatus status;    // ENTWURF, BERECHNET, FREIGEGEBEN, AUSBEZAHLT
  List<LohnAbrechnung> abrechnungen;

  // Totale
  double totalBrutto;
  double totalNetto;
  double totalAgKosten;
}

class LohnAbrechnung {
  String lohnlaufId;
  String mitarbeiterId;

  // Brutto
  double grundlohn;
  double monatlohn13;       // Anteilig 1/12
  double ferienEntschaedigung; // Nur bei Stundenlohn
  double spesen;
  double ueberzeitZuschlag;
  double kinderzulagen;     // Durchlauf
  double brutto;

  // Abzuege AN
  double ahvIvEo;           // 5.30%
  double alv;               // 1.10%
  double uvgNbu;            // variabel
  double bvgAn;             // variabel
  double ktgAn;             // variabel
  double quellensteuer;     // variabel
  double totalAbzuege;

  // Nettolohn
  double netto;

  // AG-Kosten
  double ahvIvEoAg;
  double alvAg;
  double uvgBu;
  double bvgAg;
  double ktgAg;
  double fak;
  double verwaltungskosten;
  double totalAgKosten;
}
```

#### Sozialversicherungs-Parameter

```dart
class SvParameter {
  int jahr;

  // AHV/IV/EO
  double ahvIvEoSatz;       // 10.60% (total)

  // ALV
  double alvSatz;            // 2.20% (total)
  double alvMaxLohn;         // 148'200

  // BVG
  double bvgEintrittsschwelle; // 22'680
  double bvgKoordAbzug;       // 26'460
  double bvgMaxVersLohn;      // 90'720
  Map<String, double> bvgAltersgutschriften; // "25-34": 7.0, etc.

  // UVG
  double uvgMaxVersLohn;     // 148'200

  // Weitere betriebsspezifische Saetze
  double uvgBuSatz;          // z.B. 2.50% (betriebsindividuell)
  double uvgNbuSatz;         // z.B. 1.40%
  double ktgAnSatz;          // z.B. 0.80%
  double ktgAgSatz;          // z.B. 0.80%
  double fakSatz;            // z.B. 1.50%
  double bvgAgSatz;          // z.B. 6.00% (PK-abhaengig)
  double bvgAnSatz;          // z.B. 6.00%
  double verwaltungskostenSatz; // z.B. 0.40%
}
```

### 8.4 MVP vs. Full Feature-Matrix

| Feature | MVP | Phase 2 | Phase 3 |
|---|---|---|---|
| Brutto erfassen | x | x | x |
| SV-Abzuege berechnen | x | x | x |
| Nettolohn berechnen | x | x | x |
| Lohnabrechnung PDF | x | x | x |
| 13. Monatslohn | x | x | x |
| Ferienentschaedigung (Std.) | x | x | x |
| Spesen erfassen | x | x | x |
| Quellensteuer | - | x | x |
| Lohnausweis (Form. 11) PDF | - | x | x |
| Rueckstellungen auto-buchen | - | x | x |
| Lohnjournal/-liste | - | x | x |
| Zeiterfassung-Integration | - | x | x |
| ELM-Export (XML) | - | - | x |
| swissdec-Partner-Anbindung | - | - | x |
| BVG-Mutationsmeldungen | - | - | x |

### 8.5 Technische Empfehlungen

1. **SV-Saetze als Konfiguration**: Alle Sozialversicherungssaetze in einer jaehrlich aktualisierbaren Konfigurationstabelle speichern (nicht hart codiert)
2. **Betriebsspezifische Saetze**: UVG BU/NBU, KTG, FAK, BVG sind betriebsindividuell und muessen pro Betrieb konfigurierbar sein
3. **Kantonale Unterschiede**: Fuer QST und FAK muessen kantonale Parameter hinterlegt werden
4. **Rundungsregeln**: Schweizer Lohnabrechnung rundet auf 5 Rappen (0.05 CHF)
5. **Buchungsautomatik**: Lohnlauf soll automatisch die Buchungssaetze in der Finanzbuchhaltung erzeugen (Kopplung Modul Lohn ↔ Modul Buchhaltung)
6. **Revisionssicherheit**: Freigegebene Lohnabrechnungen duerfen nicht mehr geaendert werden (nur Korrekturlauf)
7. **Offline-Faehigkeit**: Lohnberechnung muss auch offline funktionieren (Isar-basiert), Sync bei naechster Verbindung

### 8.6 Abgrenzung: Was gehoert NICHT ins KMU Tool

- **Vollstaendige swissdec-Zertifizierung**: Zu aufwaendig und komplex (eigene Zertifizierung)
- **Pensionskassenverwaltung**: BVG-Berechnung reicht, PK-Verwaltung ist Sache der PK
- **Lohnfortzahlungsmanagement**: Tracking ja, aber keine Versicherungsabwicklung
- **GAV-spezifische Loehne**: Mindestloehne pro GAV waeren nice-to-have, aber nicht MVP
- **Grenzgaenger-Spezialfaelle**: DBA mit verschiedenen Laendern ist zu komplex

---

## Quellen und Referenzen

### Offizielle Quellen
- [BSV - Beitraege an die Sozialversicherungen](https://www.bsv.admin.ch/bsv/de/home/sozialversicherungen/ueberblick/beitraege.html)
- [AHV/IV Informationsstelle - Merkblaetter](https://www.ahv-iv.ch/de/Merkbl%C3%A4tter/Beitr%C3%A4ge-AHV-IV-EO-ALV)
- [ESTV - Lohnausweis/Rentenbescheinigung](https://www.estv.admin.ch/de/lohnausweis-rentenbescheinigung)
- [ESTV - Quellensteuer](https://www.estv.admin.ch/de/quellensteuer)
- [BSV - Familienzulagen Ansaetze](https://www.bsv.admin.ch/bsv/de/home/sozialversicherungen/famz/grundlagen-und-gesetze/ansaetze.html)
- [SUVA - Praemienbemessung](https://www.suva.ch/de-ch/versicherung/loehne-und-praemien/praemienbemessung-berufsunfall-nicht-berufsunfall)
- [swissdec - ELM Standard](https://swissdec.ch/elm)

### Sekundaerquellen
- [Swissmem - Sozialversicherungsbeitraege 2026](https://www.swissmem.ch/de/wissen/personalwesen/arbeitsrecht/sozialversicherungsbeitraege-2026.html)
- [Lenz Treuhand - Sozialversicherungen 2026](https://www.lenz-treuhand.ch/en/news-insights/sozialversicherungen-2026-ahv-bvg-eo-aenderungen-im-ueberblick/)
- [Goldblum - BVG Erklaerung](https://goldblum.ch/de/wissensdatenbank/bvg-berifliche-vorsorge)
- [bexio - Quellensteuer](https://www.bexio.com/de-CH/quellensteuer)
- [bexio - KTG-Beitrag](https://www.bexio.com/de-CH/blog/view/ktg-beitrag)
- [Allianz - UVG erklaert](https://www.allianz.ch/de/privatkunden/ratgeber/vorsorge/uvg-erklaert.html)
- [Nexova - Koordinationsabzug 2025](https://www.nexova.ch/de/steuern-recht/koordinationsabzug-2025-erklaerung/)

---

*Erstellt: April 2026 | Letzte Aktualisierung: April 2026*
*Hinweis: Beitragssaetze koennen sich jaehrlich aendern. Immer aktuelle Werte bei den offiziellen Quellen pruefen.*

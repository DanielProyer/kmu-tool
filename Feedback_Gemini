Das KMU Tool ist ein ambitioniertes Projekt mit einem soliden technologischen Fundament (basierend auf SBS Projer). Doch eine kritische Analyse offenbart mehrere strategische, technische und betriebliche Schwachstellen, die den Erfolg gefährden könnten.

Hier ist die "Advocatus Diaboli"-Analyse deines Projekts:

### 1. Strategische Schwachstellen & Marktrisiken

* **Fokus auf "Nur GmbH"**: Du schließt damit ca. 30–35 % des Handwerkermarktes (Einzelfirmen) aus. Zwar vereinfacht dies die Buchhaltung (immer doppelte Buchführung), aber die Akquisekosten könnten steigen, da die Zielgruppe künstlich verkleinert wird.
* **Vertrauensproblem vs. Etablierte**: Handwerker sind bei ihrer Kern-Software (Buchhaltung/Lohn) extrem konservativ. Warum sollten sie ihre sensiblen Steuerdaten einer "Ein-Personen-Lösung" anvertrauen, wenn Marktführer wie bexio (80.000+ Kunden) oder Abacus jahrzehntelange Erfahrung und Treuhänder-Netzwerke bieten?
* **Das "Support-Paradoxon"**: Dein Ziel ist "keine Schulung". In der Realität haben Handwerker oft geringe IT-Kompetenz. Ein Multi-Modul-System (Lager, Lohn, Buchhaltung) erzeugt zwangsläufig Support-Anfragen. Wie willst du diesen Support als Einzelperson/Klein-Team leisten, ohne dass die Entwicklung zum Stillstand kommt?
* **Vertriebskanal**: In Graubünden läuft viel über persönliche Kontakte und Mund-zu-Mund-Propaganda. Eine rein digitale Vermarktung könnte an der Mentalität der Zielgruppe scheitern.

### 2. Technische Schwachstellen

* **Flutter Web für die "Auto-Website"**: Der USP der automatisch generierten Webseite ist technisch heikel. Flutter Web ist hervorragend für App-Logik, aber schlecht für SEO (Suchmaschinenoptimierung) und Ladezeiten von öffentlichen Webseiten. Wenn die Kunden-Webseiten bei Google nicht gefunden werden, verliert das KMU Tool seinen größten Mehrwert gegenüber der Konkurrenz.
* **Offline-Sync-Konflikte**: In der "SBS Projer Analyse" wird "Last-Write-Wins" als Strategie genannt. In einem Multi-User-Szenario (Chef im Büro, zwei Mitarbeiter auf verschiedenen Baustellen editieren denselben Auftrag) führt das unweigerlich zu Datenverlust, wenn zwei Personen gleichzeitig offline Änderungen vornehmen.
* **Architektur-Sprung**: SBS Projer war ein Single-Tenant-System (ein Kunde). Der Umbau zu einem echten Multi-Tenancy-System auf Supabase (Daten-Isolation pro Firma via RLS) ist hochkomplex und ein Fehler hier kann zu fatalen Datenlecks führen (Firma A sieht Daten von Firma B).


### 3. Fachliche & Regulatorische Risiken (Compliance)

* **Komplexität der Lohnbuchhaltung**: Die Schweiz hat extrem spezifische Anforderungen (AHV/IV/EO, ALV, BVG-Abzüge nach Alter, UVG, kantonale Familienzulagen). Diese Logik selbst zu programmieren und jährlich aktuell zu halten (neue Grenzbeträge, Tarife), ist ein enormes Haftungsrisiko. Ein einziger Rundungsfehler bei der Quellensteuer kann rechtliche Konsequenzen haben.
* **Archivierungspflicht (GeBüV)**: Die 10-jährige Aufbewahrungspflicht erfordert nicht nur Speicherplatz, sondern eine revisionssichere Archivierung. Einfaches Speichern in Supabase Storage reicht rechtlich oft nicht aus, wenn Dokumente nachträglich veränderbar bleiben.
* **Banken-Schnittstellen**: Du planst camt.053 Importe. Viele Schweizer Banken schalten alte Formate Ende 2026 ab (Umstellung auf ISO 20022 v2019). Ohne eine offizielle Zertifizierung oder einen Aggregator (wie bLink oder KLARA) wirst du permanent mit sich ändernden Bank-Schnittstellen kämpfen.

### 4. Die "Feature-Falle" (Scope Creep)

Dein MVP-Plan umfasst bereits:
1.  Kundenstamm
2.  Offerten/Aufträge/Rapporte
3.  Zeiterfassung
4.  Lagerverwaltung
5.  Fahrzeugverwaltung
6.  Buchhaltung (Fibu)
7.  Auto-Website (Marketing)

**Kritik**: Jedes dieser Module für sich ist bei Konkurrenten ein eigenständiges Produkt. Die Gefahr ist groß, dass das KMU Tool in jedem Bereich "ein bisschen was kann", aber in keinem Bereich tief genug geht, um ein spezialisiertes Excel-Sheet eines Handwerkers wirklich zu ersetzen.

### Zusammenfassende Empfehlung zur Entschärfung:

1.  **Technik**: Generiere die "Auto-Websites" nicht mit Flutter, sondern als statische HTML-Seiten via Edge Functions (SSR), um SEO zu garantieren.
2.  **Fokus**: Streiche die Lohnbuchhaltung für den Start. Empfiehl stattdessen eine Integration zu einem Partner. Das Risiko-Nutzen-Verhältnis ist für einen MVP zu schlecht.
3.  **Vertrauen**: Suche dir frühzeitig einen "Pilot-Treuhänder", der das Buchhaltungsmodul zertifiziert oder zumindest prüft. Das ist dein wichtigstes Verkaufsargument für die GmbH-Chefs.
4.  **Nische in der Nische**: Statt "alle Handwerker", starte mit einer Branche, die du aus SBS Projer am besten kennst (z.B. Gebäudetechnik/Service), um die Branchenvorlagen perfekt zu machen.

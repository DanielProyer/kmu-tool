# 08 - Bankanbindung Schweiz

> Recherche für das KMU Tool – Fokus: kleine Handwerksbetriebe (GmbH, 1-10 MA)
> Stand: April 2026

---

## Inhaltsübersicht

1. [QR-Rechnung (Swiss QR Bill)](#1-qr-rechnung-swiss-qr-bill)
2. [camt-Dateien (Kontoauszüge & Gutschriften)](#2-camt-dateien)
3. [pain-Meldungen (Zahlungsaufträge)](#3-pain-meldungen)
4. [Open Banking / bLink](#4-open-banking--blink)
5. [eBill](#5-ebill)
6. [Technische Integration (Dart/Flutter)](#6-technische-integration)
7. [Phasenplan Bankanbindung](#7-phasenplan-bankanbindung)

---

## 1. QR-Rechnung (Swiss QR Bill)

### 1.1 Aktueller Standard

Die QR-Rechnung hat per 30.09.2022 den orangen Einzahlungsschein (ESR) und den roten
Einzahlungsschein vollständig abgelöst. Der massgebende Standard wird von SIX publiziert:

| Aspekt                  | Detail                                                    |
|-------------------------|-----------------------------------------------------------|
| Standard                | Swiss Payment Standards – Implementation Guidelines (IG)  |
| Aktuelle Version        | IG v2.3 (seit November 2022), v2.4 angekündigt            |
| Herausgeber             | SIX Interbank Clearing                                    |
| Zahlteil                | Swiss QR Code (QR-Code nach ISO 18004) + Empfangsschein   |
| QR-Code-Inhalt          | Strukturierte Zahlungsinformationen gemäss SPS            |
| Grösse QR-Code          | 46 × 46 mm (inkl. Schweizer Kreuz in der Mitte)          |
| Papierformat Zahlteil   | 210 × 105 mm (Zahlteil) + 62 × 105 mm (Empfangsschein)  |

### 1.2 QR-IBAN vs. normale IBAN

Für die QR-Rechnung gibt es zwei IBAN-Varianten, die bestimmen, welcher Referenztyp
verwendet werden darf:

| Merkmal              | QR-IBAN                          | Normale IBAN                    |
|----------------------|----------------------------------|---------------------------------|
| IID-Bereich          | 30000–31999                      | Alle anderen IID                |
| Erkennung            | Stellen 5–9 der IBAN = 3xxxx     | Stellen 5–9 ≠ 3xxxx            |
| Referenztyp          | QRR (QR-Referenz) – **Pflicht** | SCOR oder NON (ohne Referenz)   |
| Gutschrift-Konto     | Separates QR-Konto bei der Bank  | Normales Zahlungskonto          |
| Vorteil              | Automatischer Debitorenabgleich  | Kein zusätzliches Konto nötig   |
| Empfehlung KMU Tool  | **Bevorzugt** (Automatisierung)  | Fallback, wenn Bank kein QR-Konto bietet |

**Wichtig**: Eine QR-IBAN darf **nur** auf einer QR-Rechnung verwendet werden, niemals
als normales Zahlungskonto. Die Bank leitet Zahlungen intern auf das eigentliche Konto weiter.

**Erkennung im Code** (Stellen 5–9 der IBAN, 0-indexiert ab Position 4):

```dart
bool isQrIban(String iban) {
  final cleaned = iban.replaceAll(' ', '');
  if (cleaned.length != 21) return false;
  final iid = int.tryParse(cleaned.substring(4, 9)) ?? 0;
  return iid >= 30000 && iid <= 31999;
}
```

### 1.3 Referenztypen

#### QR-Referenz (QRR)

- 27-stellig numerisch (26 Nutzstellen + 1 Prüfziffer)
- Prüfziffer: **Modulo 10 rekursiv** (identisch mit bisherigem ESR)
- Nur in Kombination mit QR-IBAN zulässig
- Ermöglicht automatischen Abgleich: Rechnungsnummer → Referenz → Zahlung

**Aufbau**:
```
RRRRRRRRRRRRRRRRRRRRRRRRRRP
│                          │
│  26 Nutzstellen          Prüfziffer (Modulo 10 rekursiv)
│  (frei strukturierbar,
│   z.B. Kundennr + Rechnungsnr)
```

**Dart-Code – Prüfzifferberechnung (Modulo 10 rekursiv)**:

```dart
/// Berechnet die Prüfziffer nach dem Modulo-10-rekursiv-Verfahren.
/// Verwendet die offizielle Übertragstabelle gemäss SIX-Spezifikation.
int modulo10Recursive(String input) {
  const table = [0, 9, 4, 6, 8, 2, 7, 1, 3, 5];
  int carry = 0;
  for (int i = 0; i < input.length; i++) {
    final digit = int.parse(input[i]);
    carry = table[(carry + digit) % 10];
  }
  return (10 - carry) % 10;
}

/// Erstellt eine vollständige QR-Referenz aus 26 Nutzstellen.
/// Gibt einen 27-stelligen String zurück.
String createQrReference(String payload) {
  assert(payload.length == 26, 'Payload muss 26 Stellen haben');
  assert(RegExp(r'^\d+$').hasMatch(payload), 'Nur Ziffern erlaubt');
  final checkDigit = modulo10Recursive(payload);
  return '$payload$checkDigit';
}

/// Validiert eine 27-stellige QR-Referenz.
bool validateQrReference(String reference) {
  if (reference.length != 27) return false;
  if (!RegExp(r'^\d+$').hasMatch(reference)) return false;
  final payload = reference.substring(0, 26);
  final expected = modulo10Recursive(payload);
  return int.parse(reference[26]) == expected;
}
```

**Beispiel-Referenzstruktur für das KMU Tool**:

```
Stellen 1-6:   Kundennummer (z.B. 000142)
Stellen 7-16:  Rechnungsnummer (z.B. 0000002024 → Jahr + laufende Nr.)
Stellen 17-26: Frei / Reserviert (z.B. 0000000000)
Stelle 27:     Prüfziffer
```

#### SCOR-Referenz (Structured Creditor Reference)

- ISO 11649, max. 25 Zeichen alphanumerisch
- Format: `RF` + 2-stellige Prüfziffer (Modulo 97) + max. 21 Zeichen Referenz
- Nur mit normaler IBAN (nicht QR-IBAN) zulässig
- Internationaler Standard, weniger verbreitet in der Schweiz

```dart
/// Erstellt eine SCOR-Referenz (ISO 11649) aus einer frei wählbaren Referenz.
String createScorReference(String reference) {
  assert(reference.length <= 21, 'Referenz max. 21 Zeichen');
  assert(RegExp(r'^[A-Za-z0-9]+$').hasMatch(reference));

  // Referenz + 'RF00' → numerisch umwandeln → Modulo 97
  final numeric = _alphaToNumeric('${reference}RF00');
  final remainder = _bigModulo97(numeric);
  final checkDigits = (98 - remainder).toString().padLeft(2, '0');
  return 'RF$checkDigits$reference';
}

String _alphaToNumeric(String input) {
  final buffer = StringBuffer();
  for (final char in input.toUpperCase().codeUnits) {
    if (char >= 65 && char <= 90) {
      buffer.write(char - 55); // A=10, B=11, ...
    } else {
      buffer.writeCharCode(char);
    }
  }
  return buffer.toString();
}

int _bigModulo97(String number) {
  int remainder = 0;
  for (int i = 0; i < number.length; i++) {
    remainder = (remainder * 10 + int.parse(number[i])) % 97;
  }
  return remainder;
}
```

### 1.4 Automatischer Zuordnungskreislauf

Der wesentliche Vorteil der QR-Rechnung mit QR-Referenz (QRR) ist die **durchgängig
automatisierte Zuordnung** vom Rechnungsversand bis zur Verbuchung:

```
┌──────────────────────────────────────────────────────────────────┐
│                  AUTOMATISCHER KREISLAUF                         │
│                                                                  │
│  1. KMU Tool erstellt Rechnung                                   │
│     → Rechnungsnr. 2024-0042 an Kunde 000142                    │
│                                                                  │
│  2. QR-Referenz wird generiert                                   │
│     → Kundennr (000142) + Rechnungsnr (0000002024) + Reserve    │
│     → 00014200000020240000000000 + Prüfziffer                    │
│     → 000142000000202400000000003                                │
│                                                                  │
│  3. QR-Rechnung (PDF) wird erzeugt                               │
│     → QR-Code enthält QR-IBAN + QR-Referenz + Betrag             │
│                                                                  │
│  4. Kunde bezahlt (E-Banking, Mobile, Schalter)                  │
│     → Bank überträgt QR-Referenz 1:1                             │
│                                                                  │
│  5. Bank des Handwerkers erstellt camt.054                       │
│     → XML enthält die QR-Referenz im Feld <Ref>                 │
│                                                                  │
│  6. KMU Tool importiert camt.054                                 │
│     → Parst QR-Referenz → extrahiert Kundennr + Rechnungsnr     │
│     → Ordnet Zahlung automatisch der Rechnung zu                 │
│     → Erstellt Buchung: Bank an Debitoren                        │
│                                                                  │
│  7. Rechnung wird als «bezahlt» markiert                         │
│     → Offener-Posten-Liste aktualisiert                          │
└──────────────────────────────────────────────────────────────────┘
```

**Trefferquote**: Mit QR-Referenz liegt die automatische Zuordnungsrate bei nahezu
**100%**, da die Referenz bei der Zahlung unverändert durchgereicht wird. Ohne Referenz
(NON) muss manuell zugeordnet werden.

---

## 2. camt-Dateien

### 2.1 Übersicht der camt-Meldungstypen

| Typ       | Name               | Zweck                                    | Relevanz KMU Tool   |
|-----------|--------------------|------------------------------------------|----------------------|
| camt.052  | Bank-to-Customer Account Report | Intraday-Kontobewegungen     | Niedrig (Nice-to-have) |
| camt.053  | Bank-to-Customer Statement      | Tagesend-Kontoauszug         | Mittel (Kontoabstimmung) |
| camt.054  | Bank-to-Customer Debit/Credit Notification | Einzelne Gutschriften/Belastungen | **Hoch** (Debitorenabgleich) |

### 2.2 camt.054 – Gutschriftsanzeige (wichtigste Datei)

Die camt.054 ist für das KMU Tool die **zentrale Datei** für den automatischen
Debitorenabgleich. Sie wird von der Bank bereitgestellt, wenn Zahlungseingänge
(QR-Rechnungen) verbucht werden.

**SPS-Versionen**:

| Version      | Gültig ab   | Basis-ISO-Schema | Bemerkung                        |
|--------------|-------------|------------------|----------------------------------|
| SPS 2024     | Nov 2024    | camt.054.001.08  | Aktuelle Produktionsversion      |
| SPS 2025     | Nov 2025    | camt.054.001.11  | Neue Felder, Migration empfohlen |
| SPS 2026     | Nov 2026    | camt.054.001.12  | In Vorbereitung                  |

**Hinweis**: Schweizer Banken liefern camt-Dateien immer in der **Schweizer SPS-Variante**
(Swiss Payment Standards), die gegenüber dem ISO-Standard leichte Einschränkungen und
Erweiterungen enthält.

### 2.3 XML-Struktur camt.054 (vereinfacht)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:camt.054.001.08"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <BkToCstmrDbtCdtNtfctn>
    <GrpHdr>
      <MsgId>CAMT054-20260402-001</MsgId>
      <CreDtTm>2026-04-02T18:30:00+02:00</CreDtTm>
    </GrpHdr>
    <Ntfctn>
      <Id>NTFCTN-001</Id>
      <Acct>
        <Id><IBAN>CH93 0076 2011 6238 5295 7</IBAN></Id>
      </Acct>
      <!-- Eine oder mehrere Buchungen (Entries) -->
      <Ntry>
        <Amt Ccy="CHF">1250.00</Amt>
        <CdtDbtInd>CRDT</CdtDbtInd>              <!-- CRDT = Gutschrift -->
        <Sts><Cd>BOOK</Cd></Sts>                  <!-- BOOK = gebucht -->
        <BookgDt><Dt>2026-04-02</Dt></BookgDt>
        <ValDt><Dt>2026-04-02</Dt></ValDt>
        <BkTxCd>
          <Domn><Cd>PMNT</Cd>
            <Fmly><Cd>RCDT</Cd>                   <!-- Received Credit Transfer -->
              <SubFmlyCd>VCOM</SubFmlyCd>          <!-- QR-Rechnung -->
            </Fmly>
          </Domn>
        </BkTxCd>
        <NtryDtls>
          <TxDtls>
            <Refs>
              <EndToEndId>000142000000202400000000003</EndToEndId>
            </Refs>
            <RmtInf>
              <Strd>
                <CdtrRefInf>
                  <Tp>
                    <CdOrPrtry><Cd>QRR</Cd></CdOrPrtry>
                    <!-- QRR = QR-Referenz, SCOR = Structured Creditor Reference -->
                  </Tp>
                  <!-- ============================================ -->
                  <!-- PFAD ZUR QR-REFERENZ:                        -->
                  <!-- Ntfctn/Ntry/NtryDtls/TxDtls/RmtInf/         -->
                  <!--   Strd/CdtrRefInf/Ref                        -->
                  <!-- ============================================ -->
                  <Ref>000142000000202400000000003</Ref>
                </CdtrRefInf>
              </Strd>
            </RmtInf>
            <RltdPties>
              <Dbtr>
                <Nm>Müller Hans</Nm>
              </Dbtr>
            </RltdPties>
          </TxDtls>
        </NtryDtls>
      </Ntry>
    </Ntfctn>
  </BkToCstmrDbtCdtNtfctn>
</Document>
```

**XML-Pfad zur QR-Referenz**:
```
/Document
  /BkToCstmrDbtCdtNtfctn
    /Ntfctn
      /Ntry
        /NtryDtls
          /TxDtls
            /RmtInf
              /Strd
                /CdtrRefInf
                  /Ref          ← QR-Referenz (27-stellig)
                  /Tp/CdOrPrtry/Cd  ← "QRR" oder "SCOR"
```

### 2.4 camt.053 – Kontoauszug

Enthält den vollständigen Tagesauszug mit Anfangs- und Endsaldo. Nützlich für die
Kontoabstimmung in der Buchhaltung, aber weniger kritisch als camt.054 für den
Debitorenabgleich.

Zusätzliche Felder gegenüber camt.054:

```xml
<Stmt>
  <Bal>
    <Tp><CdOrPrtry><Cd>OPBD</Cd></CdOrPrtry></Tp>  <!-- Opening Balance -->
    <Amt Ccy="CHF">15420.50</Amt>
    <CdtDbtInd>CRDT</CdtDbtInd>
    <Dt><Dt>2026-04-02</Dt></Dt>
  </Bal>
  <Bal>
    <Tp><CdOrPrtry><Cd>CLBD</Cd></CdOrPrtry></Tp>  <!-- Closing Balance -->
    <Amt Ccy="CHF">16670.50</Amt>
    <CdtDbtInd>CRDT</CdtDbtInd>
    <Dt><Dt>2026-04-02</Dt></Dt>
  </Bal>
  <!-- Ntry-Elemente identisch wie bei camt.054 -->
</Stmt>
```

---

## 3. pain-Meldungen

### 3.1 Übersicht

| Typ       | Name                           | Zweck                          | Relevanz KMU Tool |
|-----------|--------------------------------|--------------------------------|--------------------|
| pain.001  | Customer Credit Transfer Initiation | Zahlungsauftrag an Bank   | **Hoch** (Kreditoren) |
| pain.002  | Customer Payment Status Report | Statusrückmeldung der Bank     | Mittel (Fehlerbehandlung) |
| pain.008  | Customer Direct Debit Initiation | Lastschrift-Auftrag         | Niedrig (nicht Standard für KMU) |

### 3.2 pain.001 – Zahlungsauftrag

Mit pain.001 kann das KMU Tool Zahlungen (Lieferantenrechnungen, Löhne) direkt als
Datei an die Bank übermitteln – ohne manuelles Eintippen im E-Banking.

**SPS-Versionen**:

| Version      | Basis-ISO-Schema       | Bemerkung                    |
|--------------|------------------------|------------------------------|
| SPS 2024     | pain.001.001.09        | Produktionsversion           |
| SPS 2025     | pain.001.001.11        | Migration empfohlen          |
| SPS 2026     | pain.001.001.12        | In Vorbereitung              |

**XML-Beispiel pain.001 (vereinfacht)**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.09"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CstmrCdtTrfInitn>
    <GrpHdr>
      <MsgId>PAIN001-20260402-001</MsgId>
      <CreDtTm>2026-04-02T10:00:00+02:00</CreDtTm>
      <NbOfTxs>2</NbOfTxs>
      <CtrlSum>3750.00</CtrlSum>
      <InitgPty>
        <Nm>Muster Sanitär GmbH</Nm>
      </InitgPty>
    </GrpHdr>

    <PmtInf>
      <PmtInfId>PMT-2026-001</PmtInfId>
      <PmtMtd>TRF</PmtMtd>                         <!-- Transfer -->
      <NbOfTxs>2</NbOfTxs>
      <CtrlSum>3750.00</CtrlSum>
      <ReqdExctnDt><Dt>2026-04-05</Dt></ReqdExctnDt> <!-- Ausführungsdatum -->
      <Dbtr>
        <Nm>Muster Sanitär GmbH</Nm>
        <PstlAdr>
          <Ctry>CH</Ctry>
          <AdrLine>Hauptstrasse 12</AdrLine>
          <AdrLine>7000 Chur</AdrLine>
        </PstlAdr>
      </Dbtr>
      <DbtrAcct>
        <Id><IBAN>CH93 0076 2011 6238 5295 7</IBAN></Id>
      </DbtrAcct>
      <DbtrAgt>
        <FinInstnId><BICFI>UBSWCHZH80A</BICFI></FinInstnId>
      </DbtrAgt>

      <!-- Zahlung 1: QR-Rechnung mit QRR -->
      <CdtTrfTxInf>
        <PmtId>
          <InstrId>INSTR-001</InstrId>
          <EndToEndId>2026-04-LF-001</EndToEndId>
        </PmtId>
        <Amt><InstdAmt Ccy="CHF">2500.00</InstdAmt></Amt>
        <CdtrAgt>
          <FinInstnId><BICFI>RAIFCH22XXX</BICFI></FinInstnId>
        </CdtrAgt>
        <Cdtr>
          <Nm>Lieferant Rohre AG</Nm>
          <PstlAdr>
            <Ctry>CH</Ctry>
            <AdrLine>Industrieweg 5</AdrLine>
            <AdrLine>8000 Zürich</AdrLine>
          </PstlAdr>
        </Cdtr>
        <CdtrAcct>
          <Id><IBAN>CH44 3199 9123 0008 8901 2</IBAN></Id>  <!-- QR-IBAN -->
        </CdtrAcct>
        <RmtInf>
          <Strd>
            <CdtrRefInf>
              <Tp><CdOrPrtry><Cd>QRR</Cd></CdOrPrtry></Tp>
              <Ref>210000000003139471430009017</Ref>
            </CdtrRefInf>
          </Strd>
        </RmtInf>
      </CdtTrfTxInf>

      <!-- Zahlung 2: IBAN mit SCOR-Referenz -->
      <CdtTrfTxInf>
        <PmtId>
          <InstrId>INSTR-002</InstrId>
          <EndToEndId>2026-04-LF-002</EndToEndId>
        </PmtId>
        <Amt><InstdAmt Ccy="CHF">1250.00</InstdAmt></Amt>
        <CdtrAgt>
          <FinInstnId><BICFI>POFICHBEXXX</BICFI></FinInstnId>
        </CdtrAgt>
        <Cdtr>
          <Nm>Elektro Müller GmbH</Nm>
          <PstlAdr>
            <Ctry>CH</Ctry>
            <AdrLine>Bahnhofstrasse 22</AdrLine>
            <AdrLine>3000 Bern</AdrLine>
          </PstlAdr>
        </Cdtr>
        <CdtrAcct>
          <Id><IBAN>CH58 0900 0000 1556 1234 9</IBAN></Id>  <!-- Normale IBAN -->
        </CdtrAcct>
        <RmtInf>
          <Strd>
            <CdtrRefInf>
              <Tp><CdOrPrtry><Cd>SCOR</Cd></CdOrPrtry></Tp>
              <Ref>RF18539007547034</Ref>
            </CdtrRefInf>
          </Strd>
        </RmtInf>
      </CdtTrfTxInf>
    </PmtInf>
  </CstmrCdtTrfInitn>
</Document>
```

### 3.3 pain.002 – Statusbericht

Die Bank sendet pain.002 als Antwort auf einen pain.001-Auftrag. Mögliche Status:

| Status-Code | Bedeutung                           | Aktion KMU Tool              |
|-------------|-------------------------------------|------------------------------|
| ACTC        | Accepted Technical Validation       | Auftrag technisch ok         |
| ACCP        | Accepted Customer Profile           | Kundenprofil geprüft         |
| ACSC        | Accepted Settlement Completed       | **Zahlung ausgeführt**       |
| RJCT        | Rejected                            | **Fehler → Benutzer informieren** |
| PART        | Partially Accepted                  | Teilweise akzeptiert         |

**XML-Beispiel pain.002 (Ablehnung)**:

```xml
<Document xmlns="urn:iso:std:iso:20022:tech:xsd:pain.002.001.10">
  <CstmrPmtStsRpt>
    <GrpHdr>
      <MsgId>PAIN002-20260402-001</MsgId>
      <CreDtTm>2026-04-02T10:05:00+02:00</CreDtTm>
    </GrpHdr>
    <OrgnlGrpInfAndSts>
      <OrgnlMsgId>PAIN001-20260402-001</OrgnlMsgId>
      <OrgnlMsgNmId>pain.001.001.09</OrgnlMsgNmId>
      <GrpSts>RJCT</GrpSts>
      <StsRsnInf>
        <Rsn><Cd>AC01</Cd></Rsn>   <!-- Incorrect Account Number -->
        <AddtlInf>IBAN ungültig</AddtlInf>
      </StsRsnInf>
    </OrgnlGrpInfAndSts>
  </CstmrPmtStsRpt>
</Document>
```

**Häufige Rejection-Codes**:

| Code | Bedeutung                    | Typische Ursache                    |
|------|------------------------------|-------------------------------------|
| AC01 | Incorrect Account Number     | IBAN falsch                         |
| AC04 | Closed Account Number        | Konto aufgelöst                     |
| AM05 | Duplicate                    | Doppelzahlung erkannt               |
| BE04 | Missing Creditor Address     | Adresse fehlt                       |
| DT01 | Invalid Date                 | Ausführungsdatum in Vergangenheit   |
| RC01 | Bank Identifier Incorrect    | BIC falsch                          |
| NARR | Narrative                    | Freitextgrund                       |

---

## 4. Open Banking / bLink

### 4.1 Was ist bLink?

**bLink** ist die Schweizer Open-Banking-Plattform von SIX. Sie ermöglicht es
Drittanbietern (wie dem KMU Tool), über standardisierte REST-APIs auf Bankdaten und
Zahlungsdienste zuzugreifen – mit Einwilligung des Kontoinhabers.

| Aspekt            | Detail                                                       |
|-------------------|--------------------------------------------------------------|
| Betreiber         | SIX BBS AG (Business Banking Services)                       |
| Technologie       | REST-API (JSON), OAuth 2.0, mTLS                             |
| Regulierung       | Keine gesetzliche Pflicht in CH (anders als PSD2 in der EU)  |
| Freiwilligkeit    | Banken und Drittanbieter nehmen freiwillig teil               |

### 4.2 API-Services

| Service | Name                            | Funktion                                  | Relevanz KMU Tool |
|---------|---------------------------------|-------------------------------------------|--------------------|
| AIS     | Account Information Service     | Kontostand und Transaktionen lesen        | **Hoch** (camt automatisch) |
| PSS     | Payment Submission Service      | Zahlungsaufträge einreichen (pain.001)    | **Hoch** (Kreditoren) |
| PCS     | Payment Confirmation Service    | Zahlungsbestätigungen empfangen           | Mittel             |
| FXS     | Foreign Exchange Service        | Wechselkurse abfragen                     | Niedrig            |

**AIS (Account Information Service)** – Wichtigste API:
- Kontoinformationen abrufen (Saldo, IBAN, Währung)
- Transaktionshistorie lesen (äquivalent zu camt.053/054 als JSON)
- Ersetzt manuellen camt-Datei-Import
- Polling oder Webhooks für neue Transaktionen

**PSS (Payment Submission Service)**:
- Zahlungsaufträge programmatisch einreichen
- Equivalent zu pain.001 als JSON
- Status-Tracking der eingereichten Zahlungen

### 4.3 Teilnehmende Banken (Stand April 2026)

| Bank                        | AIS  | PSS  | Status            |
|-----------------------------|------|------|-------------------|
| Zürcher Kantonalbank (ZKB)  | Ja   | Ja   | Aktiv             |
| Luzerner KB (LUKB)          | Ja   | Ja   | Aktiv             |
| Banque Cantonale Vaudoise   | Ja   | Ja   | Aktiv             |
| Aargauische KB (AKB)        | Ja   | Ja   | Aktiv             |
| Berner KB (BEKB)            | Ja   | Ja   | Aktiv             |
| PostFinance                 | Ja   | Ja   | Aktiv             |
| Raiffeisen Schweiz          | Ja   | –    | Onboarding / Teilweise |
| UBS                         | –    | –    | Evaluation         |
| Credit Suisse / UBS         | –    | –    | Nicht aktiv        |

**Lücke**: Die beiden Grossbanken (UBS, CS/UBS) sind bisher nicht aktiv auf bLink.
Für die Zielgruppe (Handwerker, oft bei Kantonalbanken oder Raiffeisen) ist die
Abdeckung aber bereits brauchbar.

### 4.4 Anbindungsprozess

```
1. Registrierung bei SIX als "Third Party Provider" (TPP)
   → Vertrag, Prüfung, Zertifizierung

2. Technisches Onboarding
   → Sandbox-Zugang, API-Keys, mTLS-Zertifikate
   → Entwicklung und Testing

3. Go-Live
   → Produktionszugang pro Bank (jede Bank einzeln)
   → OAuth 2.0 Consent Flow: Endbenutzer autorisiert Zugriff

4. Laufender Betrieb
   → API-Versionsmanagement, Monitoring, SLA
```

### 4.5 Kosten

| Kostenart                  | Grössenordnung               | Bemerkung                       |
|---------------------------|------------------------------|---------------------------------|
| Setup-Gebühr SIX          | CHF 5'000–15'000 (einmalig) | Abhängig von Services           |
| Jahresgebühr SIX          | CHF 5'000–20'000            | Plattformgebühr                 |
| Transaktionsgebühr        | CHF 0.05–0.50 pro Aufruf    | Volumenabhängig                 |
| Entwicklungsaufwand       | 200–400 Stunden             | Integration, Testing, Zertifiz. |

**Bewertung für KMU Tool**: Die Kosten sind für ein einzelnes KMU zu hoch. Aber als
**SaaS-Plattform** (KMU Tool mit vielen Endkunden) amortisiert sich die Investition
schnell. Wichtig: Erst ab Phase 2 einplanen, wenn genügend zahlende Kunden vorhanden.

### 4.6 Alternative: Aggregatoren

Statt direkte bLink-Anbindung können **Aggregatoren** wie Klarna Kosma, Tink (Visa)
oder nCino (ehemals Fintecsystems) als Zwischenschicht dienen. Vorteile:
- Kein eigener TPP-Vertrag nötig
- Breitere Bankabdeckung (inkl. Screen Scraping wo nötig)
- Schnellere Integration

Nachteil: Zusätzliche Abhängigkeit und Kosten pro Transaktion.

---

## 5. eBill

### 5.1 Allgemein

eBill ist die Schweizer Plattform für elektronische Rechnungen direkt im E-Banking
des Empfängers. Betrieben von SIX.

| Aspekt            | Detail                                           |
|-------------------|--------------------------------------------------|
| Verbreitung       | ~2.8 Mio. Privatkunden, ~90'000 Rechnungssteller |
| Reichweite        | Alle Schweizer Banken                            |
| Rechnungssteller  | Meist grosse Unternehmen (Telcos, Versicherungen)|

### 5.2 Bewertung für kleine Handwerker

**Nicht prioritär** für das KMU Tool MVP aus folgenden Gründen:

| Pro                              | Contra                                    |
|----------------------------------|-------------------------------------------|
| Professionelles Auftreten        | Onboarding-Aufwand für Rechnungssteller   |
| Kein Papierversand               | Kunden müssen eBill aktivieren            |
| Gute Zahlungsmoral (1-Click-Pay) | Wenige Privatkunden nutzen eBill aktiv    |
| Automatische Zuordnung           | QR-Rechnung per PDF/Mail reicht oft       |
|                                  | Kosten pro Rechnung (ca. CHF 0.30–0.50)  |
|                                  | Handwerkerkunden kennen eBill kaum        |

**Fazit**: eBill ist ein Nice-to-have für Phase 3. Die QR-Rechnung als PDF (per
E-Mail oder WhatsApp) deckt den Bedarf der Zielgruppe vollständig ab.

### 5.3 eBill Direct Debit (Nachfolger LSV+ / BDD)

| Aspekt                   | Detail                                        |
|--------------------------|-----------------------------------------------|
| Was                      | Lastschriftverfahren über eBill-Infrastruktur |
| Ersetzt                  | LSV+ (Lastschriftverfahren) und BDD (Business Direct Debit) |
| LSV+/BDD Einstellung     | **30.09.2028** – danach nur noch eBill DD     |
| Relevanz KMU Tool        | Gering: Lastschrift für Handwerker untypisch  |

LSV+ und BDD werden per **30. September 2028** abgeschaltet. Für wiederkehrende
Zahlungen (z.B. Wartungsverträge) wäre eBill Direct Debit der Nachfolger. Für das
KMU Tool aktuell nicht relevant, da Handwerker typischerweise Einzelrechnungen stellen.

---

## 6. Technische Integration

### 6.1 Dart-Packages

| Package         | Zweck                              | Pub.dev           | Bemerkung               |
|-----------------|------------------------------------|--------------------|--------------------------|
| `qr_flutter`    | QR-Code als Widget rendern         | qr_flutter 4.x    | Für Bildschirmanzeige    |
| `pdf`           | PDF-Erzeugung                      | pdf 3.x           | QR-Rechnung als PDF      |
| `printing`      | PDF drucken/teilen                 | printing 5.x      | Druck/Share auf Mobile   |
| `xml`            | XML parsen und erzeugen            | xml 6.x           | camt/pain-Dateien        |
| `file_picker`   | Datei vom Gerät wählen             | file_picker 8.x   | camt-Import              |
| `http` / `dio`  | HTTP-Requests                      | http / dio         | bLink-API (Phase 2)      |
| `intl`          | Zahlenformatierung (CHF)           | intl               | Bereits im Projekt       |

**Kein dediziertes `qr_bill` Package empfohlen**: Die bestehenden pub.dev-Packages
für Swiss QR Bill sind oft veraltet oder unvollständig. Besser: eigene Implementation
basierend auf `pdf` + `qr_flutter` gemäss SIX-Spezifikation. Das gibt volle Kontrolle
über Layout und Kompatibilität mit IG v2.3/v2.4.

### 6.2 QR-Rechnung erstellen (Dart-Code)

```dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Datenmodell für den QR-Zahlteil gemäss Swiss Payment Standards.
class QrBillData {
  final String creditorIban;      // QR-IBAN oder IBAN
  final String creditorName;
  final String creditorStreet;
  final String creditorCity;
  final String creditorCountry;   // "CH"
  final double? amount;           // null = offener Betrag
  final String currency;          // "CHF" oder "EUR"
  final String referenceType;     // "QRR", "SCOR" oder "NON"
  final String? reference;        // QR-Referenz oder SCOR-Referenz
  final String? debtorName;
  final String? debtorStreet;
  final String? debtorCity;
  final String? debtorCountry;
  final String? unstructuredMessage;

  QrBillData({
    required this.creditorIban,
    required this.creditorName,
    required this.creditorStreet,
    required this.creditorCity,
    this.creditorCountry = 'CH',
    this.amount,
    this.currency = 'CHF',
    required this.referenceType,
    this.reference,
    this.debtorName,
    this.debtorStreet,
    this.debtorCity,
    this.debtorCountry,
    this.unstructuredMessage,
  });

  /// Erzeugt den QR-Code-Payload gemäss SIX-Spezifikation (IG v2.3).
  /// Felder werden durch Newline (\n) getrennt.
  String toQrPayload() {
    final lines = <String>[
      'SPC',                                   // QR-Type
      '0200',                                  // Version
      '1',                                     // Coding Type (UTF-8)
      creditorIban.replaceAll(' ', ''),         // IBAN
      'S',                                     // Address Type: S = Structured
      creditorName,                            // Name
      creditorStreet,                          // Strasse + Nr.
      '',                                      // (reserviert)
      creditorCity.split(' ').last,            // PLZ (aus "7000 Chur" → "Chur")
      creditorCity.split(' ').first,           // Ort – Achtung: PLZ + Ort getrennt!
      creditorCountry,
      // Ultimate Creditor (leer lassen gemäss v2.3)
      '', '', '', '', '', '',
      // Betrag
      amount != null ? amount!.toStringAsFixed(2) : '',
      currency,
      // Debtor
      debtorName != null ? 'S' : '',
      debtorName ?? '',
      debtorStreet ?? '',
      '',
      debtorCity?.split(' ').last ?? '',
      debtorCity?.split(' ').first ?? '',
      debtorCountry ?? '',
      // Referenz
      referenceType,
      reference ?? '',
      unstructuredMessage ?? '',
      'EPD',                                    // Trailer
    ];
    return lines.join('\n');
  }
}
```

**Hinweis zur Adresse**: Bei Adress-Typ `S` (Structured) werden PLZ und Ort in
getrennten Feldern übermittelt. Die oben gezeigte Aufteilung via `split(' ')` ist
vereinfacht – in der Produktionsversion sollte ein dediziertes Feld für PLZ und Ort
verwendet werden.

### 6.3 camt.054 parsen (Dart-Code)

```dart
import 'package:xml/xml.dart';

/// Repräsentiert eine einzelne Gutschrift aus einer camt.054-Datei.
class CamtCreditEntry {
  final String reference;
  final String referenceType; // 'QRR' oder 'SCOR'
  final double amount;
  final String currency;
  final DateTime bookingDate;
  final String? debtorName;
  final String? endToEndId;

  CamtCreditEntry({
    required this.reference,
    required this.referenceType,
    required this.amount,
    required this.currency,
    required this.bookingDate,
    this.debtorName,
    this.endToEndId,
  });
}

/// Parst eine camt.054-XML-Datei und gibt alle Gutschriften zurück.
List<CamtCreditEntry> parseCamt054(String xmlContent) {
  final document = XmlDocument.parse(xmlContent);
  final entries = <CamtCreditEntry>[];

  // Namespace-unabhängig suchen (SPS-Versionen haben unterschiedliche Namespaces)
  final ntryElements = document.findAllElements('Ntry');

  for (final ntry in ntryElements) {
    // Nur Gutschriften (CRDT) verarbeiten
    final cdtDbtInd = ntry.findAllElements('CdtDbtInd').firstOrNull?.innerText;
    if (cdtDbtInd != 'CRDT') continue;

    final amount = double.tryParse(
      ntry.findAllElements('Amt').firstOrNull?.innerText ?? '0',
    ) ?? 0.0;

    final currency = ntry.findAllElements('Amt').firstOrNull
        ?.getAttribute('Ccy') ?? 'CHF';

    final bookingDateStr = ntry
        .findAllElements('BookgDt')
        .firstOrNull
        ?.findAllElements('Dt')
        .firstOrNull
        ?.innerText;

    final bookingDate = bookingDateStr != null
        ? DateTime.parse(bookingDateStr)
        : DateTime.now();

    // Transaktionsdetails durchgehen
    final txDtls = ntry.findAllElements('TxDtls');
    for (final tx in txDtls) {
      // QR-Referenz extrahieren
      final cdtrRefInf = tx.findAllElements('CdtrRefInf').firstOrNull;
      if (cdtrRefInf == null) continue;

      final refType = cdtrRefInf
          .findAllElements('Cd')
          .firstOrNull
          ?.innerText ?? 'NON';

      final ref = cdtrRefInf
          .findAllElements('Ref')
          .firstOrNull
          ?.innerText ?? '';

      if (ref.isEmpty) continue;

      final debtorName = tx
          .findAllElements('Dbtr')
          .firstOrNull
          ?.findAllElements('Nm')
          .firstOrNull
          ?.innerText;

      final endToEndId = tx
          .findAllElements('EndToEndId')
          .firstOrNull
          ?.innerText;

      entries.add(CamtCreditEntry(
        reference: ref,
        referenceType: refType,
        amount: amount,
        currency: currency,
        bookingDate: bookingDate,
        debtorName: debtorName,
        endToEndId: endToEndId,
      ));
    }
  }

  return entries;
}
```

### 6.4 pain.001 generieren (Dart-Code)

```dart
import 'package:xml/xml.dart';

/// Datenmodell für eine einzelne Zahlung.
class PaymentInstruction {
  final String instructionId;
  final String endToEndId;
  final double amount;
  final String currency;
  final String creditorName;
  final String creditorIban;
  final String creditorBic;
  final String creditorStreet;
  final String creditorCity;
  final String creditorCountry;
  final String? referenceType;  // 'QRR', 'SCOR', null
  final String? reference;

  PaymentInstruction({
    required this.instructionId,
    required this.endToEndId,
    required this.amount,
    this.currency = 'CHF',
    required this.creditorName,
    required this.creditorIban,
    required this.creditorBic,
    required this.creditorStreet,
    required this.creditorCity,
    this.creditorCountry = 'CH',
    this.referenceType,
    this.reference,
  });
}

/// Generiert eine pain.001-XML-Datei (SPS 2024, pain.001.001.09).
String generatePain001({
  required String messageId,
  required String debtorName,
  required String debtorIban,
  required String debtorBic,
  required String debtorStreet,
  required String debtorCity,
  required DateTime executionDate,
  required List<PaymentInstruction> payments,
}) {
  final totalAmount = payments.fold<double>(0, (sum, p) => sum + p.amount);

  final builder = XmlBuilder();
  builder.processing('xml', 'version="1.0" encoding="UTF-8"');

  builder.element('Document', nest: () {
    builder.attribute('xmlns',
        'urn:iso:std:iso:20022:tech:xsd:pain.001.001.09');
    builder.attribute('xmlns:xsi',
        'http://www.w3.org/2001/XMLSchema-instance');

    builder.element('CstmrCdtTrfInitn', nest: () {
      // Group Header
      builder.element('GrpHdr', nest: () {
        builder.element('MsgId', nest: messageId);
        builder.element('CreDtTm', nest: DateTime.now().toIso8601String());
        builder.element('NbOfTxs', nest: payments.length.toString());
        builder.element('CtrlSum', nest: totalAmount.toStringAsFixed(2));
        builder.element('InitgPty', nest: () {
          builder.element('Nm', nest: debtorName);
        });
      });

      // Payment Information
      builder.element('PmtInf', nest: () {
        builder.element('PmtInfId', nest: '$messageId-PMT');
        builder.element('PmtMtd', nest: 'TRF');
        builder.element('NbOfTxs', nest: payments.length.toString());
        builder.element('CtrlSum', nest: totalAmount.toStringAsFixed(2));
        builder.element('ReqdExctnDt', nest: () {
          builder.element('Dt', nest:
            executionDate.toIso8601String().substring(0, 10));
        });

        // Debtor
        builder.element('Dbtr', nest: () {
          builder.element('Nm', nest: debtorName);
          builder.element('PstlAdr', nest: () {
            builder.element('Ctry', nest: 'CH');
            builder.element('AdrLine', nest: debtorStreet);
            builder.element('AdrLine', nest: debtorCity);
          });
        });
        builder.element('DbtrAcct', nest: () {
          builder.element('Id', nest: () {
            builder.element('IBAN', nest: debtorIban.replaceAll(' ', ''));
          });
        });
        builder.element('DbtrAgt', nest: () {
          builder.element('FinInstnId', nest: () {
            builder.element('BICFI', nest: debtorBic);
          });
        });

        // Einzelne Zahlungen
        for (final payment in payments) {
          builder.element('CdtTrfTxInf', nest: () {
            builder.element('PmtId', nest: () {
              builder.element('InstrId', nest: payment.instructionId);
              builder.element('EndToEndId', nest: payment.endToEndId);
            });
            builder.element('Amt', nest: () {
              builder.element('InstdAmt', nest: () {
                builder.attribute('Ccy', payment.currency);
                builder.text(payment.amount.toStringAsFixed(2));
              });
            });
            builder.element('CdtrAgt', nest: () {
              builder.element('FinInstnId', nest: () {
                builder.element('BICFI', nest: payment.creditorBic);
              });
            });
            builder.element('Cdtr', nest: () {
              builder.element('Nm', nest: payment.creditorName);
              builder.element('PstlAdr', nest: () {
                builder.element('Ctry', nest: payment.creditorCountry);
                builder.element('AdrLine', nest: payment.creditorStreet);
                builder.element('AdrLine', nest: payment.creditorCity);
              });
            });
            builder.element('CdtrAcct', nest: () {
              builder.element('Id', nest: () {
                builder.element('IBAN',
                    nest: payment.creditorIban.replaceAll(' ', ''));
              });
            });

            // Referenz (falls vorhanden)
            if (payment.referenceType != null && payment.reference != null) {
              builder.element('RmtInf', nest: () {
                builder.element('Strd', nest: () {
                  builder.element('CdtrRefInf', nest: () {
                    builder.element('Tp', nest: () {
                      builder.element('CdOrPrtry', nest: () {
                        builder.element('Cd', nest: payment.referenceType!);
                      });
                    });
                    builder.element('Ref', nest: payment.reference!);
                  });
                });
              });
            }
          });
        }
      });
    });
  });

  return builder.buildDocument().toXmlString(pretty: true);
}
```

### 6.5 Banking Service Layer – Architektur

```
┌─────────────────────────────────────────────────────────────────┐
│                      Presentation Layer                         │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐│
│  │ Rechnungen   │ │ Buchhaltung  │ │ Zahlungen (Kreditoren)   ││
│  │ Screen       │ │ Screen       │ │ Screen                   ││
│  └──────┬───────┘ └──────┬───────┘ └───────────┬──────────────┘│
│         │                │                     │                │
│─────────┼────────────────┼─────────────────────┼────────────────│
│         ▼                ▼                     ▼                │
│                    Provider Layer (Riverpod)                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────────┐│
│  │ qrBillProv.  │ │ camtProv.    │ │ paymentProv.             ││
│  └──────┬───────┘ └──────┬───────┘ └───────────┬──────────────┘│
│         │                │                     │                │
│─────────┼────────────────┼─────────────────────┼────────────────│
│         ▼                ▼                     ▼                │
│                    Service Layer                                 │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                   BankingService                            ││
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────────┐  ││
│  │  │ QrBillService│ │ CamtService  │ │ PainService        │  ││
│  │  │              │ │              │ │                    │  ││
│  │  │ - generate() │ │ - parse054() │ │ - generate001()   │  ││
│  │  │ - validate() │ │ - parse053() │ │ - parse002()      │  ││
│  │  │ - toPdf()    │ │ - matchInv() │ │ - validateStatus()│  ││
│  │  └──────────────┘ └──────────────┘ └────────────────────┘  ││
│  └─────────────────────────────────────────────────────────────┘│
│                           │                                     │
│───────────────────────────┼─────────────────────────────────────│
│                           ▼                                     │
│                    Data Layer                                    │
│  ┌─────────────────────┐  ┌─────────────────────────────────┐  │
│  │ Local (Isar)        │  │ Remote (Supabase / bLink)       │  │
│  │ - Rechnungen        │  │ - Supabase Storage (PDF)        │  │
│  │ - Buchungen         │  │ - bLink AIS (Phase 2)           │  │
│  │ - Zahlungsstatus    │  │ - bLink PSS (Phase 2)           │  │
│  └─────────────────────┘  └─────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.6 Debitorenabgleich – Ablauf im Code

```dart
/// Automatischer Abgleich: camt.054-Gutschriften → offene Rechnungen.
class DebtorMatchingService {
  final RechnungRepository _rechnungRepo;
  final BuchungService _buchungService;

  DebtorMatchingService(this._rechnungRepo, this._buchungService);

  /// Verarbeitet importierte camt.054-Einträge.
  /// Gibt eine Liste von Match-Ergebnissen zurück.
  Future<List<MatchResult>> processEntries(
    List<CamtCreditEntry> entries,
  ) async {
    final results = <MatchResult>[];

    for (final entry in entries) {
      if (entry.referenceType == 'QRR') {
        // QR-Referenz → Kundennr + Rechnungsnr extrahieren
        final kundenNr = entry.reference.substring(0, 6);
        final rechnungNr = entry.reference.substring(6, 16);

        final rechnung = await _rechnungRepo.findByNummer(rechnungNr);

        if (rechnung != null && rechnung.offenerBetrag == entry.amount) {
          // Perfekter Match: Betrag stimmt
          await _rechnungRepo.markAsBezahlt(rechnung.id);
          await _buchungService.createZahlungseingang(
            rechnungId: rechnung.id,
            betrag: entry.amount,
            datum: entry.bookingDate,
            referenz: entry.reference,
          );
          results.add(MatchResult.matched(entry, rechnung));
        } else if (rechnung != null) {
          // Teilzahlung oder Überzahlung
          results.add(MatchResult.amountMismatch(
            entry, rechnung, rechnung.offenerBetrag,
          ));
        } else {
          // Keine Rechnung gefunden
          results.add(MatchResult.noMatch(entry));
        }
      } else {
        // SCOR oder NON: manuelle Zuordnung nötig
        results.add(MatchResult.manualRequired(entry));
      }
    }

    return results;
  }
}
```

---

## 7. Phasenplan Bankanbindung

### Phase 1 – MVP (aktuell)

| Feature                        | Aufwand  | Priorität | Status    |
|--------------------------------|----------|-----------|-----------|
| QR-Rechnung als PDF generieren | 3–5 Tage | **P0**    | Geplant   |
| QR-Referenz (Modulo 10) Berechnung | 1 Tag | **P0**    | Geplant   |
| QR-IBAN-Erkennung              | 0.5 Tage | **P0**    | Geplant   |
| SCOR-Referenz-Berechnung       | 0.5 Tage | P1        | Geplant   |
| Manueller camt.054-Import (Datei-Upload) | 2–3 Tage | **P0** | Geplant |
| Automatischer Debitorenabgleich (QRR) | 2–3 Tage | **P0** | Geplant |
| camt.053-Import (Kontoabstimmung) | 2 Tage | P1       | Geplant   |

**Workflow Phase 1**:
1. Handwerker erstellt Rechnung im KMU Tool
2. KMU Tool generiert QR-Rechnung als PDF (mit QR-Referenz)
3. PDF wird per E-Mail/WhatsApp an Kunden gesendet
4. Kunde bezahlt im E-Banking
5. Handwerker lädt camt.054-Datei aus E-Banking herunter
6. Handwerker importiert camt.054 ins KMU Tool (Datei-Upload)
7. KMU Tool ordnet Zahlungen automatisch zu

### Phase 2 – Automatisierung

| Feature                          | Aufwand    | Priorität | Voraussetzung       |
|----------------------------------|------------|-----------|---------------------|
| pain.001 generieren (Kreditoren) | 3–5 Tage   | P1        | –                   |
| pain.002 parsen (Statusberichte) | 2 Tage     | P1        | pain.001            |
| bLink-Integration (AIS)          | 20–40 Tage | P2        | TPP-Vertrag mit SIX |
| bLink-Integration (PSS)          | 10–20 Tage | P2        | TPP-Vertrag mit SIX |
| Automatischer camt-Abruf via API | 5 Tage     | P1        | bLink AIS           |

**Workflow Phase 2**:
- Kreditoren: Handwerker erfasst Lieferantenrechnungen → KMU Tool generiert
  pain.001 → Upload ins E-Banking oder direkt via bLink PSS
- Debitoren: camt.054 wird automatisch via bLink AIS abgerufen → kein manueller
  Download mehr nötig

### Phase 3 – Erweiterungen

| Feature                           | Aufwand    | Priorität | Bemerkung              |
|-----------------------------------|------------|-----------|------------------------|
| eBill (Rechnungssteller)          | 15–30 Tage | P3        | SIX-Onboarding nötig  |
| Multibanking (mehrere Bankkonten) | 5–10 Tage  | P2        | bLink-Basis vorhanden  |
| Automatische Mahnungen            | 3–5 Tage   | P2        | Aufbauend auf OP-Liste |
| Kontoabstimmung (Buchhaltung)     | 5 Tage     | P2        | camt.053 + Saldo       |
| Fremdwährungen (EUR)              | 3 Tage     | P3        | Grenznahe Betriebe     |

---

## Zusammenfassung & Empfehlung

| Thema          | MVP-Relevanz | Empfehlung                                          |
|----------------|--------------|------------------------------------------------------|
| QR-Rechnung    | **Kritisch** | Eigene Implementation (pdf + qr_flutter), QRR bevorzugt |
| camt.054       | **Kritisch** | Manueller Datei-Import, automatischer Debitorenabgleich |
| camt.053       | Mittel       | Für Kontoabstimmung, nach MVP                        |
| pain.001       | Mittel       | Phase 2, grosser Mehrwert für Kreditoren             |
| bLink          | Niedrig      | Phase 2–3, Kosten erst ab Skalierung tragbar         |
| eBill          | Niedrig      | Phase 3, QR-Rechnung reicht für Zielgruppe           |

**Kernaussage**: Für den MVP genügen **QR-Rechnung (PDF)** und **manueller camt.054-Import**
mit automatischem Debitorenabgleich. Diese beiden Features decken den wichtigsten
Pain Point ab: Rechnungen versenden und Zahlungseingänge automatisch zuordnen – ohne
dass der Handwerker etwas im E-Banking konfigurieren muss.

---

> Quellen: SIX Swiss Payment Standards (paymentstandards.ch), SIX bLink Dokumentation,
> Swiss QR Bill Implementation Guidelines v2.3, ISO 20022 Standards

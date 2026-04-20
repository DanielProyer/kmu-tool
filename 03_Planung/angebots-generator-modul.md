# Umsetzungsplan: Angebots-Generator Modul

## Kontext

Der Angebots-Generator aus AutoMate (React/Vite + Express + Claude API) wird als natives Modul ins KMU Tool integriert. Die React-Implementierung wird **nicht portiert**, sondern neu in Flutter + Supabase umgesetzt.

**Ziel:** Handwerker wählen ihre Branche, füllen ein dynamisches Formular aus, erhalten einen KI-generierten Angebotstext und exportieren diesen als Swiss-konforme PDF.

---

## Mapping AutoMate → KMU Tool

| AutoMate (alt) | KMU Tool (neu) |
|---|---|
| `branches/{slug}/config.json` | Supabase-Tabelle `angebot_vorlagen` |
| `branches/{slug}/leistungen.json` | Tabelle `leistungen` (relational) |
| `branches/{slug}/prompt.md` | Feld `system_prompt` in `angebot_vorlagen` |
| Express `POST /api/generate-angebot` | Supabase Edge Function `generate-angebot` |
| `@react-pdf/renderer` | Dart `pdf`-Package |
| React `Vorschau.jsx` | Flutter `AngebotVorschauPage` |

**Konzeptuell übernommen:**
- Branche-First-Auswahl
- Dynamisches Formular aus Leistungskatalog
- Pflicht-Banner "KI-Entwurf — vor dem Versand prüfen"
- Prompt Caching (Anthropic SDK, `cache_control: ephemeral`)
- Human-in-the-Loop vor PDF-Export

**Neu gegenüber AutoMate:**
- Offline-Fähigkeit: Angebots-Drafts lokal in Isar speicherbar
- Kundenstamm-Integration: Kunde direkt aus KMU-Tool-DB wählen
- Supabase Auth: kein separater Login nötig

---

## Datenbankschema (Supabase Migrationen)

### `angebot_vorlagen`
Branchenkonfiguration (entspricht `config.json` + `prompt.md`).

```sql
create table angebot_vorlagen (
  id uuid primary key default gen_random_uuid(),
  betrieb_id uuid references betriebe(id) on delete cascade,
  branche text not null,           -- 'elektriker', 'sanitaer', etc.
  branche_label text not null,     -- 'Elektriker', 'Sanitär', etc.
  stundensatz_default numeric(10,2) not null,
  mehrwertsteuer numeric(5,2) not null default 8.1,
  normen text[] default '{}',      -- ['SIA', 'NIV']
  system_prompt text not null,
  aktiv boolean not null default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- RLS: nur eigener Betrieb sichtbar
```

### `leistungen`
Leistungskatalog pro Vorlage (entspricht `leistungen.json`).

```sql
create table leistungen (
  id uuid primary key default gen_random_uuid(),
  vorlage_id uuid references angebot_vorlagen(id) on delete cascade,
  kategorie text not null,
  bezeichnung text not null,
  einheit text not null default 'Std.',
  preis_default numeric(10,2),
  sort_order int not null default 0
);
```

### `angebote`
Gespeicherte Angebote (Draft + Final).

```sql
create table angebote (
  id uuid primary key default gen_random_uuid(),
  betrieb_id uuid references betriebe(id) on delete cascade,
  kunde_id uuid references kunden(id) on delete set null,
  vorlage_id uuid references angebot_vorlagen(id) on delete set null,
  titel text not null,
  status text not null default 'entwurf', -- 'entwurf', 'versendet', 'akzeptiert', 'abgelehnt'
  positionen jsonb not null default '[]',
  ki_text text,                    -- Rohtext von Claude
  gesamtbetrag_netto numeric(12,2),
  mwst_betrag numeric(12,2),
  gesamtbetrag_brutto numeric(12,2),
  gueltig_bis date,
  pdf_url text,                    -- Supabase Storage URL (write-once)
  is_synced boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
-- RLS: nur eigener Betrieb
```

---

## Supabase Edge Function: `generate-angebot`

Datei: `supabase/functions/generate-angebot/index.ts`

```typescript
// POST { vorlage_id, positionen, kunde_info }
// → { ki_text, positionen_berechnet, gesamtbetrag_netto, mwst, brutto }

import Anthropic from "npm:@anthropic-ai/sdk";

const client = new Anthropic();

Deno.serve(async (req) => {
  const { system_prompt, positionen, kunde_info } = await req.json();

  const message = await client.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 2048,
    system: [
      {
        type: "text",
        text: system_prompt,
        cache_control: { type: "ephemeral" }, // Prompt Caching
      },
    ],
    messages: [
      {
        role: "user",
        content: JSON.stringify({ positionen, kunde_info }),
      },
    ],
  });

  // Claude gibt strukturiertes JSON zurück (Positionen + Texte)
  return new Response(message.content[0].text, {
    headers: { "Content-Type": "application/json" },
  });
});
```

---

## Flutter Module-Struktur

```
lib/
  features/
    angebote/
      data/
        models/
          angebot.dart
          leistung.dart
          angebot_vorlage.dart
        local/
          angebot_local.dart          # Isar-Schema (Offline-Draft)
          angebot_local_web.dart      # Web-Stub
        repositories/
          angebot_repository.dart
          angebot_vorlage_repository.dart
      services/
        angebot_ki_service.dart       # Ruft Edge Function auf
        angebot_pdf_service.dart      # Dart pdf-Package
      presentation/
        pages/
          branche_waehlen_page.dart   # Schritt 1: Branche
          angebot_formular_page.dart  # Schritt 2: Formular
          angebot_vorschau_page.dart  # Schritt 3: Vorschau + Banner
          angebote_liste_page.dart    # Übersicht aller Angebote
        widgets/
          ki_entwurf_banner.dart      # Roter Pflicht-Banner
          leistungs_position_tile.dart
          angebot_pdf_preview.dart
      providers/
        angebot_providers.dart
        angebot_vorlage_providers.dart
```

---

## Umsetzungsschritte

### Phase 1 — Datenbankschema & Seed-Daten
- [ ] Migration: `angebot_vorlagen`, `leistungen`, `angebote`
- [ ] RLS Policies für alle drei Tabellen
- [ ] Seed-Daten: 2 Branchen aus AutoMate portieren (Elektriker, Dachdecker)
- [ ] Supabase Edge Function `generate-angebot` erstellen

### Phase 2 — Dart-Datenmodell & Repositories
- [ ] `Angebot`, `Leistung`, `AngebotVorlage` Modelle + Mapper
- [ ] `AngebotLocal` (Isar) + Web-Stub
- [ ] `AngebotVorlageRepository` (Supabase Fetch, Caching)
- [ ] `AngebotRepository` (CRUD + Sync)

### Phase 3 — KI-Service & PDF
- [ ] `AngebotKiService` (Edge Function Aufruf)
- [ ] `AngebotPdfService` (Dart pdf, Swiss Layout, KI-Entwurf-Banner)

### Phase 4 — Flutter UI
- [ ] `BrancheWaehlenPage` (Grid mit Branchen-Cards)
- [ ] `AngebotFormularPage` (dynamisch aus `leistungen`-Tabelle)
- [ ] `AngebotVorschauPage` (Roter Banner, PDF-Vorschau, Senden-Button)
- [ ] `AngebotListePage` (Status-Filter: Entwurf / Versendet / Akzeptiert)
- [ ] GoRouter-Integration

### Phase 5 — Offline-Support & Sync
- [ ] Angebot als Draft lokal speichern (Isar)
- [ ] Sync-Service Erweiterung für `angebote`-Tabelle
- [ ] Konflikt-Strategie: Angebote sind append-mostly, LWW akzeptabel

### Phase 6 — Kundenstamm-Integration
- [ ] Kunde direkt in Formular aus `kunden`-Tabelle wählen
- [ ] Kundendaten in Angebot übernehmen (Name, Adresse, für QR-Rechnung)

---

## Qualitätssicherung

- [ ] Pflicht-Banner auf jeder Angebot-Vorschau (kein Bypass möglich)
- [ ] KI-Ausgabe immer als JSON validieren (Fallback wenn Claude Freitext liefert)
- [ ] PDF ist Write-Once: einmal generiert → Supabase Storage, URL gespeichert, kein Überschreiben
- [ ] Offline-Test: Angebot-Draft ohne Netz erstellen, nach Sync abschliessen

---

## Referenzen

- AutoMate Quellcode: `c:/Users/teech/Antigravity/AutoMate/angebots-generator/`
- AutoMate Businessplan: `AutoMate/docs/superpowers/specs/2026-04-17-ki-automatisierung-handwerk-design.md`
- KMU Tool Sync-Service: `04_Entwicklung/kmu_tool_app/lib/services/sync/sync_service.dart`
- Architektur-Evaluation: `.claude/plans/passt-die-architektur-und-parsed-widget.md`

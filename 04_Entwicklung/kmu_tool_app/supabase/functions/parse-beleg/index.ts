import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
    if (!apiKey) {
      throw new Error("ANTHROPIC_API_KEY nicht konfiguriert");
    }

    const { image_base64, mime_type } = await req.json();

    if (!image_base64 || !mime_type) {
      throw new Error("image_base64 und mime_type sind erforderlich");
    }

    const prompt = `Du bist ein Schweizer Beleg-Scanner. Analysiere diesen Kassenbon/Quittung und extrahiere die Daten.

WICHTIG - Schweizer MWST-Sätze:
- 8.1% Normalsatz (Standard für die meisten Waren/Dienstleistungen)
- 2.6% Reduzierter Satz (Lebensmittel, Medikamente, Bücher, Zeitungen)
- 3.8% Beherbergungssatz (Hotels, Ferienwohnungen)

KATEGORISIERUNG:
- "benzin": Tankstelle, Diesel, Benzin, Treibstoff, Autogas, AdBlue, Autowäsche
- "essen": Lebensmittel, Restaurant, Take-Away, Kaffee, Getränke, Bäckerei, Metzgerei, Catering

REGELN für Mischkäufe (verschiedene MWST-Sätze auf einem Beleg):
- Gruppiere Positionen nach MWST-Satz
- Beispiel: Tankstelle mit Shop → Benzin (8.1%) und Sandwich (2.6%) als separate Positionen
- Wenn nur ein MWST-Satz erkennbar: eine Position mit Gesamtbetrag

ZAHLUNGSMETHODE erkennen:
- "bar": Bargeld, CASH
- "karte": Karte, Maestro, Visa, Mastercard, Debit, Credit, EC
- "twint": TWINT
- Falls nicht erkennbar: "unbekannt"

KONFIDENZ-BEWERTUNG (0.0 bis 1.0):
- 0.95-1.0: Alle Werte klar lesbar, eindeutig
- 0.85-0.94: Gut lesbar, kleine Unsicherheiten
- 0.70-0.84: Teilweise lesbar, einige Werte geschätzt
- < 0.70: Schlecht lesbar, viele Werte unsicher

Antworte AUSSCHLIESSLICH mit einem JSON-Objekt (ohne Markdown-Codeblock):
{
  "geschaeft": "Name des Geschäfts",
  "datum": "YYYY-MM-DD",
  "positionen": [
    {
      "beschreibung": "Kurzbeschreibung der Position",
      "kategorie": "benzin" oder "essen",
      "betrag_brutto": 0.00,
      "mwst_satz": 8.1
    }
  ],
  "total_brutto": 0.00,
  "zahlungsmethode": "bar" oder "karte" oder "twint" oder "unbekannt",
  "konfidenz": 0.95
}`;

    // Claude API Aufruf mit Vision
    const response = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": apiKey,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-haiku-4-5-20251001",
        max_tokens: 1024,
        messages: [
          {
            role: "user",
            content: [
              {
                type: "image",
                source: {
                  type: "base64",
                  media_type: mime_type,
                  data: image_base64,
                },
              },
              {
                type: "text",
                text: prompt,
              },
            ],
          },
        ],
      }),
      signal: AbortSignal.timeout(50000),
    });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`Claude API Fehler: ${response.status} - ${errorText}`);
    }

    const result = await response.json();
    const textContent = result.content?.find(
      (c: { type: string }) => c.type === "text"
    );

    if (!textContent?.text) {
      throw new Error("Keine Antwort von Claude erhalten");
    }

    // JSON extrahieren (mit oder ohne Markdown-Codeblock)
    let jsonText = textContent.text.trim();
    const codeBlockMatch = jsonText.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (codeBlockMatch) {
      jsonText = codeBlockMatch[1].trim();
    }

    const parsedResult = JSON.parse(jsonText);

    return new Response(JSON.stringify(parsedResult), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Unbekannter Fehler";
    return new Response(JSON.stringify({ error: message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

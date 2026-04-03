import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { renderSection } from './_shared/render.ts';
import { generateImpressum, generateJsonLd, generateSeoMeta, escapeHtml } from './_shared/utils.ts';
import { modernCss } from './_templates/modern.ts';
import { klassischCss } from './_templates/klassisch.ts';
import { handwerkCss } from './_templates/handwerk.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  const url = new URL(req.url);
  // Path: /website/{slug} or /website/{slug}/anfrage
  const pathParts = url.pathname.split('/').filter(Boolean);
  // pathParts = ['website', slug] or ['website', slug, 'anfrage']
  // But Edge Functions strip the function name, so:
  // pathParts might be [slug] or [slug, 'anfrage']

  let slug: string;
  let isAnfrage = false;

  if (pathParts.length >= 2 && pathParts[pathParts.length - 1] === 'anfrage') {
    slug = pathParts[pathParts.length - 2];
    isAnfrage = true;
  } else if (pathParts.length >= 1) {
    slug = pathParts[pathParts.length - 1];
  } else {
    return new Response('Not Found', { status: 404, headers: corsHeaders });
  }

  // Slug-Validierung
  if (!/^[a-z0-9-]+$/.test(slug)) {
    return new Response('Not Found', { status: 404, headers: corsHeaders });
  }

  try {
    if (isAnfrage && req.method === 'POST') {
      return await handleAnfrage(req, slug);
    }

    if (req.method === 'GET') {
      return await handleGetWebsite(slug);
    }

    return new Response('Method Not Allowed', { status: 405, headers: corsHeaders });
  } catch (error) {
    console.error('Error:', error);
    return new Response('Internal Server Error', { status: 500, headers: corsHeaders });
  }
});

async function handleGetWebsite(slug: string): Promise<Response> {
  // Config laden
  const { data: config, error: configError } = await supabase
    .from('website_configs')
    .select('*')
    .eq('slug', slug)
    .eq('is_published', true)
    .eq('is_deleted', false)
    .single();

  if (configError || !config) {
    return new Response(render404(), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'text/html; charset=utf-8' },
    });
  }

  // Sektionen laden
  const { data: sections } = await supabase
    .from('website_sections')
    .select('*')
    .eq('config_id', config.id)
    .eq('is_visible', true)
    .order('sortierung');

  // Galerie-Bilder laden
  const { data: galleryImages } = await supabase
    .from('website_gallery_images')
    .select('*')
    .eq('config_id', config.id)
    .order('sortierung');

  const html = renderPage(config, sections || [], galleryImages || []);

  return new Response(html, {
    status: 200,
    headers: {
      ...corsHeaders,
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
    },
  });
}

async function handleAnfrage(req: Request, slug: string): Promise<Response> {
  // Config laden
  const { data: config } = await supabase
    .from('website_configs')
    .select('id')
    .eq('slug', slug)
    .eq('is_published', true)
    .eq('is_deleted', false)
    .single();

  if (!config) {
    return new Response(JSON.stringify({ error: 'Website nicht gefunden' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Ungültige Anfrage' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { name, email, telefon, nachricht, typ, details } = body;

  if (!name || !email) {
    return new Response(JSON.stringify({ error: 'Name und E-Mail sind Pflicht' }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  const { error } = await supabase.from('website_anfragen').insert({
    config_id: config.id,
    typ: typ || 'kontakt',
    name,
    email,
    telefon: telefon || null,
    nachricht: nachricht || null,
    details: details || {},
  });

  if (error) {
    console.error('Insert error:', error);
    return new Response(JSON.stringify({ error: 'Anfrage konnte nicht gespeichert werden' }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function renderPage(config: any, sections: any[], galleryImages: any[]): string {
  // Template CSS waehlen
  let css: string;
  switch (config.design_template) {
    case 'klassisch':
      css = klassischCss(config.primaerfarbe, config.sekundaerfarbe, config.schriftart);
      break;
    case 'handwerk':
      css = handwerkCss(config.primaerfarbe, config.sekundaerfarbe, config.schriftart);
      break;
    default:
      css = modernCss(config.primaerfarbe, config.sekundaerfarbe, config.schriftart);
  }

  // Sektionen rendern
  const sectionsHtml = sections
    .map(s => renderSection(s, config, galleryImages))
    .join('\n');

  // Logo URL
  const logoUrl = config.logo_path
    ? `${SUPABASE_URL}/storage/v1/object/public/website-assets/${config.logo_path}`
    : '';

  const logoHtml = logoUrl
    ? `<div style="position:fixed;top:1rem;left:1rem;z-index:100;"><img src="${logoUrl}" alt="${escapeHtml(config.firmen_name)}" style="height:50px;border-radius:8px;"></div>`
    : '';

  return `<!DOCTYPE html>
<html lang="de-CH">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  ${generateSeoMeta(config)}
  <style>${css}</style>
  <script type="application/ld+json">${generateJsonLd(config)}</script>
</head>
<body>
  ${logoHtml}
  ${sectionsHtml}
  <footer class="footer">
    ${generateImpressum(config)}
    <p style="margin-top:1rem;">&copy; ${new Date().getFullYear()} ${escapeHtml(config.firmen_name)}</p>
  </footer>
  <script>
    document.querySelectorAll('.anfrage-form').forEach(form => {
      form.addEventListener('submit', async (e) => {
        e.preventDefault();
        const status = form.querySelector('.form-status');
        const slug = form.dataset.slug;
        const typ = form.dataset.typ || 'kontakt';
        const data = {
          name: form.querySelector('[name=name]')?.value,
          email: form.querySelector('[name=email]')?.value,
          telefon: form.querySelector('[name=telefon]')?.value || null,
          nachricht: form.querySelector('[name=nachricht]')?.value || null,
          typ: typ,
          details: {}
        };
        const leistung = form.querySelector('[name=leistung]');
        if (leistung) data.details.leistung = leistung.value;
        const wunschtermin = form.querySelector('[name=wunschtermin]');
        if (wunschtermin) data.details.wunschtermin = wunschtermin.value;

        try {
          const res = await fetch(window.location.pathname + '/anfrage', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
          });
          if (res.ok) {
            status.textContent = 'Vielen Dank! Ihre Anfrage wurde gesendet.';
            status.style.display = 'block';
            status.style.color = 'green';
            form.reset();
          } else {
            throw new Error('Fehler');
          }
        } catch {
          status.textContent = 'Fehler beim Senden. Bitte versuchen Sie es erneut.';
          status.style.display = 'block';
          status.style.color = 'red';
        }
      });
    });
  </script>
</body>
</html>`;
}

function render404(): string {
  return `<!DOCTYPE html>
<html lang="de-CH">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Website nicht gefunden</title>
  <style>
    body { font-family: system-ui, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #f8f9fa; }
    .container { text-align: center; padding: 2rem; }
    h1 { font-size: 2rem; color: #333; }
    p { color: #666; margin-top: 0.5rem; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Website nicht gefunden</h1>
    <p>Diese Website existiert nicht oder ist nicht veröffentlicht.</p>
  </div>
</body>
</html>`;
}

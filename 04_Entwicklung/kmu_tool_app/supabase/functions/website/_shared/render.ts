import { escapeHtml } from './utils.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL') || '';

function getPublicUrl(storagePath: string): string {
  return `${SUPABASE_URL}/storage/v1/object/public/website-assets/${storagePath}`;
}

export function renderSection(section: any, config: any, galleryImages: any[]): string {
  const content = section.content || {};
  const titel = section.titel ? `<h2>${escapeHtml(section.titel)}</h2>` : '';

  switch (section.typ) {
    case 'hero':
      return renderHero(content, config);
    case 'beschreibung':
      return `<section class="section beschreibung">${titel}<p>${escapeHtml(content.text || '')}</p></section>`;
    case 'leistungen':
      return renderLeistungen(content, titel);
    case 'ueber_uns':
      return `<section class="section ueber-uns">${titel}<p>${escapeHtml(content.text || '')}</p></section>`;
    case 'team':
      return renderTeam(content, titel);
    case 'referenzen':
      return renderReferenzen(content, titel);
    case 'kundenstimmen':
      return renderKundenstimmen(content, titel);
    case 'galerie':
      return renderGalerie(galleryImages, titel);
    case 'faq':
      return renderFaq(content, titel);
    case 'kontakt':
      return renderKontakt(config, titel);
    case 'offertanfrage':
      return renderOffertanfrage(content, config, titel);
    case 'notfalldienst':
      return renderNotfalldienst(content, titel);
    default:
      return '';
  }
}

function renderHero(content: any, config: any): string {
  const bgStyle = content.hintergrundbild
    ? `background-image:url('${getPublicUrl(content.hintergrundbild)}');background-size:cover;background-position:center;`
    : `background:linear-gradient(135deg, ${config.primaerfarbe}, ${config.sekundaerfarbe});`;
  return `
    <section class="hero" style="${bgStyle}">
      <div class="hero-overlay">
        <h1>${escapeHtml(content.headline || config.firmen_name)}</h1>
        ${content.subline ? `<p class="hero-subline">${escapeHtml(content.subline)}</p>` : ''}
        ${content.cta_text ? `<a href="${content.cta_link || '#offertanfrage'}" class="btn-primary">${escapeHtml(content.cta_text)}</a>` : ''}
      </div>
    </section>`;
}

function renderLeistungen(content: any, titel: string): string {
  const items = (content.items || []) as any[];
  if (items.length === 0) return '';
  const list = items.map(i =>
    `<div class="leistung-card"><h3>${escapeHtml(i.titel || '')}</h3><p>${escapeHtml(i.beschreibung || '')}</p></div>`
  ).join('\n');
  return `<section class="section leistungen">${titel}<div class="leistungen-grid">${list}</div></section>`;
}

function renderTeam(content: any, titel: string): string {
  const mitglieder = (content.mitglieder || []) as any[];
  if (mitglieder.length === 0) return '';
  const list = mitglieder.map(m =>
    `<div class="team-member"><h3>${escapeHtml(m.name || '')}</h3><p>${escapeHtml(m.rolle || '')}</p></div>`
  ).join('\n');
  return `<section class="section team">${titel}<div class="team-grid">${list}</div></section>`;
}

function renderReferenzen(content: any, titel: string): string {
  const projekte = (content.projekte || []) as any[];
  if (projekte.length === 0) return '';
  const list = projekte.map(p =>
    `<div class="referenz-card"><h3>${escapeHtml(p.titel || '')}</h3><p>${escapeHtml(p.beschreibung || '')}</p></div>`
  ).join('\n');
  return `<section class="section referenzen">${titel}<div class="referenzen-grid">${list}</div></section>`;
}

function renderKundenstimmen(content: any, titel: string): string {
  const testimonials = (content.testimonials || []) as any[];
  if (testimonials.length === 0) return '';
  const list = testimonials.map(t => {
    const sterne = '★'.repeat(t.sterne || 5) + '☆'.repeat(5 - (t.sterne || 5));
    return `<div class="testimonial"><p class="testimonial-text">"${escapeHtml(t.text || '')}"</p><div class="testimonial-stars">${sterne}</div><p class="testimonial-name">— ${escapeHtml(t.name || '')}</p></div>`;
  }).join('\n');
  return `<section class="section kundenstimmen">${titel}<div class="testimonials-grid">${list}</div></section>`;
}

function renderGalerie(images: any[], titel: string): string {
  if (images.length === 0) return '';
  const list = images.map(img =>
    `<div class="galerie-item"><img src="${getPublicUrl(img.storage_path)}" alt="${escapeHtml(img.beschreibung || img.datei_name || '')}" loading="lazy"></div>`
  ).join('\n');
  return `<section class="section galerie">${titel}<div class="galerie-grid">${list}</div></section>`;
}

function renderFaq(content: any, titel: string): string {
  const fragen = (content.fragen || []) as any[];
  if (fragen.length === 0) return '';
  const list = fragen.map(f =>
    `<details class="faq-item"><summary>${escapeHtml(f.frage || '')}</summary><p>${escapeHtml(f.antwort || '')}</p></details>`
  ).join('\n');
  return `<section class="section faq">${titel}<div class="faq-list">${list}</div></section>`;
}

function renderKontakt(config: any, titel: string): string {
  const parts: string[] = [];
  if (config.adresse_strasse) parts.push(`<p>${escapeHtml(config.adresse_strasse)}</p>`);
  if (config.adresse_plz || config.adresse_ort) {
    parts.push(`<p>${escapeHtml(config.adresse_plz || '')} ${escapeHtml(config.adresse_ort || '')}</p>`);
  }
  if (config.kontakt_telefon) parts.push(`<p>Tel: <a href="tel:${config.kontakt_telefon}">${escapeHtml(config.kontakt_telefon)}</a></p>`);
  if (config.kontakt_email) parts.push(`<p>E-Mail: <a href="mailto:${config.kontakt_email}">${escapeHtml(config.kontakt_email)}</a></p>`);
  if (config.oeffnungszeiten) parts.push(`<p>Öffnungszeiten: ${escapeHtml(config.oeffnungszeiten)}</p>`);
  return `<section class="section kontakt" id="kontakt">${titel}<div class="kontakt-info">${parts.join('\n')}</div></section>`;
}

function renderOffertanfrage(content: any, config: any, titel: string): string {
  const leistungen = (content.leistungen || []) as string[];
  const zeigeWunschtermin = content.zeige_wunschtermin !== false;

  let leistungenSelect = '';
  if (leistungen.length > 0) {
    const options = leistungen.map(l => `<option value="${escapeHtml(l)}">${escapeHtml(l)}</option>`).join('\n');
    leistungenSelect = `
      <label for="leistung">Gewünschte Leistung</label>
      <select id="leistung" name="leistung">${options}</select>`;
  }

  return `
    <section class="section offertanfrage" id="offertanfrage">
      ${titel}
      <form class="anfrage-form" data-typ="offerte" data-slug="${escapeHtml(config.slug)}">
        <label for="name">Name *</label>
        <input type="text" id="name" name="name" required>
        <label for="email">E-Mail *</label>
        <input type="email" id="email" name="email" required>
        <label for="telefon">Telefon</label>
        <input type="tel" id="telefon" name="telefon">
        ${leistungenSelect}
        ${zeigeWunschtermin ? '<label for="wunschtermin">Wunschtermin</label><input type="date" id="wunschtermin" name="wunschtermin">' : ''}
        <label for="nachricht">Nachricht</label>
        <textarea id="nachricht" name="nachricht" rows="4"></textarea>
        <button type="submit" class="btn-primary">Offerte anfragen</button>
        <p class="form-status" style="display:none"></p>
      </form>
    </section>`;
}

function renderNotfalldienst(content: any, titel: string): string {
  return `
    <section class="section notfalldienst">
      ${titel}
      ${content.text ? `<p>${escapeHtml(content.text)}</p>` : ''}
      ${content.telefon ? `<a href="tel:${content.telefon}" class="notfall-tel">${escapeHtml(content.telefon)}</a>` : ''}
      ${content.zeiten ? `<p class="notfall-zeiten">${escapeHtml(content.zeiten)}</p>` : ''}
    </section>`;
}

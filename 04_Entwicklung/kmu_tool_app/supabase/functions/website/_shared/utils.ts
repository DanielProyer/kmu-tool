export function escapeHtml(text: string): string {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

export function generateImpressum(config: any): string {
  const parts: string[] = [];
  parts.push(`<h3>Impressum</h3>`);
  parts.push(`<p><strong>${escapeHtml(config.firmen_name)}</strong></p>`);
  if (config.adresse_strasse) parts.push(`<p>${escapeHtml(config.adresse_strasse)}</p>`);
  if (config.adresse_plz || config.adresse_ort) {
    parts.push(`<p>${escapeHtml(config.adresse_plz || '')} ${escapeHtml(config.adresse_ort || '')}</p>`);
  }
  if (config.kontakt_email) parts.push(`<p>E-Mail: ${escapeHtml(config.kontakt_email)}</p>`);
  if (config.kontakt_telefon) parts.push(`<p>Tel: ${escapeHtml(config.kontakt_telefon)}</p>`);
  if (config.impressum_uid) parts.push(`<p>UID: ${escapeHtml(config.impressum_uid)}</p>`);
  return parts.join('\n');
}

export function generateJsonLd(config: any): string {
  const data: any = {
    '@context': 'https://schema.org',
    '@type': 'LocalBusiness',
    'name': config.firmen_name,
  };
  if (config.kontakt_telefon) data.telephone = config.kontakt_telefon;
  if (config.kontakt_email) data.email = config.kontakt_email;
  if (config.adresse_strasse || config.adresse_plz || config.adresse_ort) {
    data.address = {
      '@type': 'PostalAddress',
      'streetAddress': config.adresse_strasse || '',
      'postalCode': config.adresse_plz || '',
      'addressLocality': config.adresse_ort || '',
      'addressCountry': 'CH',
    };
  }
  return JSON.stringify(data);
}

export function generateSeoMeta(config: any): string {
  const title = config.seo_title || config.firmen_name;
  const description = config.seo_description || `${config.firmen_name} - ${config.untertitel || 'Ihr Handwerksbetrieb'}`;
  return `
    <title>${escapeHtml(title)}</title>
    <meta name="description" content="${escapeHtml(description)}">
    <meta property="og:title" content="${escapeHtml(title)}">
    <meta property="og:description" content="${escapeHtml(description)}">
    <meta property="og:type" content="website">
    <meta name="robots" content="index, follow">
  `;
}

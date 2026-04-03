export function modernCss(primary: string, secondary: string, font: string): string {
  return `
    @import url('https://fonts.googleapis.com/css2?family=${font.replace(/ /g, '+')}:wght@400;600;700&display=swap');
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
      font-family: '${font}', system-ui, sans-serif;
      color: #1a1a2e;
      background: #ffffff;
      line-height: 1.6;
    }
    .hero {
      min-height: 60vh;
      display: flex;
      align-items: center;
      justify-content: center;
      text-align: center;
      color: white;
      position: relative;
    }
    .hero-overlay {
      padding: 2rem;
      z-index: 1;
    }
    .hero h1 {
      font-size: clamp(2rem, 5vw, 3.5rem);
      font-weight: 700;
      margin-bottom: 0.5rem;
    }
    .hero-subline {
      font-size: 1.2rem;
      opacity: 0.9;
      margin-bottom: 1.5rem;
    }
    .btn-primary {
      display: inline-block;
      background: white;
      color: ${primary};
      padding: 0.8rem 2rem;
      border-radius: 8px;
      text-decoration: none;
      font-weight: 600;
      border: none;
      cursor: pointer;
      font-size: 1rem;
      transition: transform 0.2s;
    }
    .btn-primary:hover { transform: translateY(-2px); }
    .section {
      padding: 4rem 1.5rem;
      max-width: 900px;
      margin: 0 auto;
    }
    .section h2 {
      font-size: 2rem;
      margin-bottom: 1.5rem;
      color: ${primary};
    }
    .leistungen-grid, .team-grid, .referenzen-grid, .testimonials-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
    }
    .leistung-card, .team-member, .referenz-card, .testimonial {
      background: #f8f9fa;
      padding: 1.5rem;
      border-radius: 12px;
    }
    .leistung-card h3, .team-member h3, .referenz-card h3 {
      color: ${primary};
      margin-bottom: 0.5rem;
    }
    .testimonial-text { font-style: italic; margin-bottom: 0.5rem; }
    .testimonial-stars { color: #f59e0b; margin-bottom: 0.25rem; }
    .testimonial-name { font-weight: 600; color: #666; }
    .galerie-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 1rem;
    }
    .galerie-item img {
      width: 100%;
      height: 200px;
      object-fit: cover;
      border-radius: 8px;
    }
    .faq-item {
      border: 1px solid #e5e7eb;
      border-radius: 8px;
      margin-bottom: 0.5rem;
      overflow: hidden;
    }
    .faq-item summary {
      padding: 1rem;
      cursor: pointer;
      font-weight: 600;
      background: #f8f9fa;
    }
    .faq-item p { padding: 1rem; }
    .kontakt-info p { margin-bottom: 0.5rem; }
    .kontakt-info a { color: ${primary}; }
    .anfrage-form {
      max-width: 500px;
    }
    .anfrage-form label {
      display: block;
      margin-top: 1rem;
      margin-bottom: 0.25rem;
      font-weight: 600;
      font-size: 0.9rem;
    }
    .anfrage-form input, .anfrage-form select, .anfrage-form textarea {
      width: 100%;
      padding: 0.7rem;
      border: 1px solid #d1d5db;
      border-radius: 8px;
      font-size: 1rem;
      font-family: inherit;
    }
    .anfrage-form .btn-primary {
      margin-top: 1.5rem;
      width: 100%;
      background: ${primary};
      color: white;
      padding: 0.9rem;
    }
    .notfalldienst {
      background: #fef2f2;
      text-align: center;
      padding: 3rem 1.5rem;
    }
    .notfall-tel {
      display: inline-block;
      font-size: 1.5rem;
      font-weight: 700;
      color: #dc2626;
      text-decoration: none;
      margin: 1rem 0;
    }
    .footer {
      background: #1a1a2e;
      color: #aaa;
      text-align: center;
      padding: 2rem;
      font-size: 0.9rem;
    }
    .footer a { color: #ddd; }
    @media (max-width: 640px) {
      .section { padding: 2.5rem 1rem; }
      .hero { min-height: 50vh; }
    }
  `;
}

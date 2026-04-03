export function klassischCss(primary: string, secondary: string, font: string): string {
  return `
    @import url('https://fonts.googleapis.com/css2?family=Merriweather:wght@400;700&family=${font.replace(/ /g, '+')}:wght@400;600;700&display=swap');
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
      font-family: '${font}', Georgia, serif;
      color: #2d2d2d;
      background: #faf9f7;
      line-height: 1.7;
    }
    .hero {
      min-height: 55vh;
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
      font-size: clamp(2rem, 5vw, 3rem);
      font-weight: 700;
      margin-bottom: 0.5rem;
      letter-spacing: -0.02em;
    }
    .hero-subline {
      font-size: 1.1rem;
      opacity: 0.9;
      margin-bottom: 1.5rem;
      font-style: italic;
    }
    .btn-primary {
      display: inline-block;
      background: ${primary};
      color: white;
      padding: 0.8rem 2rem;
      border-radius: 4px;
      text-decoration: none;
      font-weight: 600;
      border: 2px solid white;
      cursor: pointer;
      font-size: 1rem;
      letter-spacing: 0.02em;
    }
    .btn-primary:hover { opacity: 0.9; }
    .section {
      padding: 4rem 1.5rem;
      max-width: 800px;
      margin: 0 auto;
    }
    .section h2 {
      font-size: 1.8rem;
      margin-bottom: 1.5rem;
      color: ${primary};
      border-bottom: 2px solid ${primary};
      padding-bottom: 0.5rem;
    }
    .leistungen-grid, .team-grid, .referenzen-grid, .testimonials-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
    }
    .leistung-card, .team-member, .referenz-card, .testimonial {
      background: white;
      padding: 1.5rem;
      border: 1px solid #e8e6e1;
      border-radius: 4px;
    }
    .leistung-card h3, .team-member h3, .referenz-card h3 {
      color: ${primary};
      margin-bottom: 0.5rem;
    }
    .testimonial-text { font-style: italic; margin-bottom: 0.5rem; }
    .testimonial-stars { color: #d4a017; margin-bottom: 0.25rem; }
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
      border-radius: 4px;
      border: 1px solid #e8e6e1;
    }
    .faq-item {
      border-bottom: 1px solid #e8e6e1;
      margin-bottom: 0;
    }
    .faq-item summary {
      padding: 1rem 0;
      cursor: pointer;
      font-weight: 600;
    }
    .faq-item p { padding: 0 0 1rem; }
    .kontakt-info p { margin-bottom: 0.5rem; }
    .kontakt-info a { color: ${primary}; }
    .anfrage-form { max-width: 500px; }
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
      border: 1px solid #ccc;
      border-radius: 4px;
      font-size: 1rem;
      font-family: inherit;
    }
    .anfrage-form .btn-primary {
      margin-top: 1.5rem;
      width: 100%;
      border: none;
      padding: 0.9rem;
    }
    .notfalldienst {
      background: #fff5f5;
      text-align: center;
      padding: 3rem 1.5rem;
    }
    .notfall-tel {
      display: inline-block;
      font-size: 1.5rem;
      font-weight: 700;
      color: #b91c1c;
      text-decoration: none;
      margin: 1rem 0;
    }
    .footer {
      background: #2d2d2d;
      color: #aaa;
      text-align: center;
      padding: 2rem;
      font-size: 0.85rem;
    }
    .footer a { color: #ddd; }
    @media (max-width: 640px) {
      .section { padding: 2.5rem 1rem; }
      .hero { min-height: 45vh; }
    }
  `;
}

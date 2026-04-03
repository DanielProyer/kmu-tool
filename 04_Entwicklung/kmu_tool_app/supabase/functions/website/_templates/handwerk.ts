export function handwerkCss(primary: string, secondary: string, font: string): string {
  return `
    @import url('https://fonts.googleapis.com/css2?family=${font.replace(/ /g, '+')}:wght@400;600;700&display=swap');
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
      font-family: '${font}', system-ui, sans-serif;
      color: #3d3528;
      background: #fdfbf7;
      line-height: 1.6;
    }
    .hero {
      min-height: 65vh;
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
      background: rgba(0,0,0,0.3);
      border-radius: 12px;
    }
    .hero h1 {
      font-size: clamp(2rem, 5vw, 3.5rem);
      font-weight: 700;
      margin-bottom: 0.5rem;
      text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
    }
    .hero-subline {
      font-size: 1.2rem;
      opacity: 0.95;
      margin-bottom: 1.5rem;
    }
    .btn-primary {
      display: inline-block;
      background: ${primary};
      color: white;
      padding: 0.9rem 2.5rem;
      border-radius: 6px;
      text-decoration: none;
      font-weight: 700;
      border: none;
      cursor: pointer;
      font-size: 1.05rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
    .btn-primary:hover { filter: brightness(1.1); }
    .section {
      padding: 4rem 1.5rem;
      max-width: 900px;
      margin: 0 auto;
    }
    .section h2 {
      font-size: 1.8rem;
      margin-bottom: 1.5rem;
      color: ${primary};
      position: relative;
      padding-left: 1rem;
    }
    .section h2::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 4px;
      background: ${primary};
      border-radius: 2px;
    }
    .leistungen-grid, .team-grid, .referenzen-grid, .testimonials-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
      gap: 1.5rem;
    }
    .leistung-card, .team-member, .referenz-card, .testimonial {
      background: white;
      padding: 1.5rem;
      border-radius: 8px;
      border-left: 4px solid ${primary};
      box-shadow: 0 2px 8px rgba(0,0,0,0.06);
    }
    .leistung-card h3, .team-member h3, .referenz-card h3 {
      color: #3d3528;
      margin-bottom: 0.5rem;
    }
    .testimonial-text { font-style: italic; margin-bottom: 0.5rem; }
    .testimonial-stars { color: #d97706; margin-bottom: 0.25rem; }
    .testimonial-name { font-weight: 600; color: #7c6f5e; }
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
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    .faq-item {
      background: white;
      border-radius: 8px;
      margin-bottom: 0.5rem;
      box-shadow: 0 1px 4px rgba(0,0,0,0.05);
      overflow: hidden;
    }
    .faq-item summary {
      padding: 1rem;
      cursor: pointer;
      font-weight: 600;
    }
    .faq-item p { padding: 0 1rem 1rem; }
    .kontakt-info p { margin-bottom: 0.5rem; }
    .kontakt-info a { color: ${primary}; font-weight: 600; }
    .anfrage-form { max-width: 500px; }
    .anfrage-form label {
      display: block;
      margin-top: 1rem;
      margin-bottom: 0.25rem;
      font-weight: 600;
      font-size: 0.9rem;
      color: #5a5040;
    }
    .anfrage-form input, .anfrage-form select, .anfrage-form textarea {
      width: 100%;
      padding: 0.7rem;
      border: 2px solid #e5ddd0;
      border-radius: 6px;
      font-size: 1rem;
      font-family: inherit;
      background: white;
    }
    .anfrage-form input:focus, .anfrage-form select:focus, .anfrage-form textarea:focus {
      border-color: ${primary};
      outline: none;
    }
    .anfrage-form .btn-primary {
      margin-top: 1.5rem;
      width: 100%;
      padding: 0.9rem;
    }
    .notfalldienst {
      background: #fef2f2;
      text-align: center;
      padding: 3rem 1.5rem;
      border-top: 4px solid #dc2626;
    }
    .notfall-tel {
      display: inline-block;
      font-size: 1.8rem;
      font-weight: 700;
      color: #dc2626;
      text-decoration: none;
      margin: 1rem 0;
    }
    .footer {
      background: #3d3528;
      color: #b8a98c;
      text-align: center;
      padding: 2rem;
      font-size: 0.9rem;
    }
    .footer a { color: #d4c4a8; }
    @media (max-width: 640px) {
      .section { padding: 2.5rem 1rem; }
      .hero { min-height: 50vh; }
    }
  `;
}

#!/usr/bin/env python3
"""Generate CSS stylesheet from design-variables.json for cogni-website.

Usage:
    python3 generate-css.py <design-variables.json> <output-css-path>

Reads the design variables JSON and produces a complete CSS stylesheet with
custom properties, base styles, grid system, typography, and responsive breakpoints.
"""

import json
import sys
from pathlib import Path


def read_design_variables(path: str) -> dict:
    with open(path) as f:
        return json.load(f)


def generate_css(dv: dict) -> str:
    colors = dv.get("colors", {})
    fonts = dv.get("fonts", {})
    google_import = dv.get("google_fonts_import", "")
    radius = dv.get("radius", 8)
    shadows = dv.get("shadows", {})

    # Build CSS custom properties
    css_vars = []
    color_map = {
        "primary": colors.get("accent", "#2563EB"),
        "primary-dark": colors.get("accent_dark", "#1E40AF"),
        "background": colors.get("background", "#FFFFFF"),
        "background-alt": colors.get("surface", "#F9FAFB"),
        "surface-dark": colors.get("surface_dark", "#111827"),
        "text": colors.get("text", "#1A1A1A"),
        "text-muted": colors.get("text_muted", "#6B7280"),
        "text-light": colors.get("text_light", "#D1D5DB"),
        "accent": colors.get("accent", "#F59E0B"),
        "accent-muted": colors.get("accent_muted", colors.get("accent", "#F59E0B") + "80"),
        "border": colors.get("border", "#E5E7EB"),
        "surface-dark-text": "#FFFFFF",
        "surface-dark-muted": colors.get("text_light", "#D1D5DB"),
    }

    for name, value in color_map.items():
        css_vars.append(f"  --{name}: {value};")

    css_vars.append("")
    css_vars.append(f"  --font-primary: {fonts.get('headers', 'Inter, system-ui, sans-serif')};")
    css_vars.append(f"  --font-body: {fonts.get('body', 'Inter, system-ui, sans-serif')};")
    css_vars.append(f"  --font-mono: {fonts.get('mono', 'Consolas, monospace')};")
    css_vars.append("")
    css_vars.append(f"  --radius: {radius}px;")

    for size in ["sm", "md", "lg", "xl"]:
        if size in shadows:
            css_vars.append(f"  --shadow-{size}: {shadows[size]};")

    root_block = "\n".join(css_vars)

    css = f"""/* cogni-website — Generated from design-variables.json */
/* Do not edit manually — regenerate with generate-css.py or site-assembler agent */

{google_import}

:root {{
{root_block}
}}

/* === Reset === */
*, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}
html {{ scroll-behavior: smooth; }}
body {{
  font-family: var(--font-body);
  font-size: 16px;
  line-height: 1.6;
  color: var(--text);
  background: var(--background);
  -webkit-font-smoothing: antialiased;
}}
img {{ max-width: 100%; height: auto; display: block; }}
a {{ color: var(--primary); text-decoration: none; }}
a:hover {{ text-decoration: underline; }}

/* === Layout === */
.container {{
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1.5rem;
}}
.content-narrow {{
  max-width: 720px;
  margin: 0 auto;
}}

/* === Typography === */
h1, h2, h3, h4, h5, h6 {{
  font-family: var(--font-primary);
  font-weight: 700;
  line-height: 1.2;
  color: var(--text);
}}
h1 {{ font-size: 2.5rem; }}
h2 {{ font-size: 2rem; }}
h3 {{ font-size: 1.25rem; }}
.section-label {{
  font-family: var(--font-primary);
  font-size: 0.875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--primary);
}}

/* === Sections === */
.section {{
  padding: 5rem 0;
}}
.section--light {{ background: var(--background); }}
.section--light-alt {{ background: var(--background-alt); }}
.section--dark {{
  background: var(--surface-dark);
  color: var(--surface-dark-text);
}}
.section--dark h2, .section--dark h3 {{ color: var(--surface-dark-text); }}
.section--dark p {{ color: var(--surface-dark-muted); }}
.section--accent {{
  background: var(--primary);
  color: #fff;
}}
.section--accent h2 {{ color: #fff; }}
.section__headline {{
  font-size: 2.25rem;
  margin-bottom: 2rem;
}}

/* === Hero === */
.hero {{
  position: relative;
  padding: 8rem 0 6rem;
  overflow: hidden;
}}
.hero--dark {{
  background: var(--surface-dark);
  color: #fff;
}}
.hero--compact {{ padding: 5rem 0 4rem; }}
.hero--image {{
  background-size: cover;
  background-position: center;
}}
.hero__overlay {{
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  z-index: 1;
}}
.hero__content {{
  position: relative;
  z-index: 2;
  max-width: 800px;
}}
.hero__headline {{
  font-size: 3.5rem;
  font-weight: 700;
  line-height: 1.1;
  margin-bottom: 1.5rem;
  color: #fff;
}}
.hero__subline {{
  font-size: 1.25rem;
  line-height: 1.5;
  margin-bottom: 2rem;
  color: var(--surface-dark-muted);
  max-width: 600px;
}}

/* === Buttons === */
.btn {{
  display: inline-block;
  font-family: var(--font-primary);
  font-weight: 700;
  font-size: 1rem;
  padding: 0.75rem 1.5rem;
  border-radius: var(--radius);
  border: 2px solid transparent;
  cursor: pointer;
  text-decoration: none;
  transition: all 0.2s ease;
}}
.btn--primary {{
  background: var(--primary);
  color: #fff;
  border-color: var(--primary);
}}
.btn--primary:hover {{
  background: var(--primary-dark);
  border-color: var(--primary-dark);
  text-decoration: none;
}}
.btn--outline {{
  background: transparent;
  color: var(--primary);
  border-color: var(--primary);
}}
.btn--outline:hover {{
  background: var(--primary);
  color: #fff;
  text-decoration: none;
}}
.btn--white {{
  background: #fff;
  color: var(--primary);
  border-color: #fff;
}}
.btn--white:hover {{ opacity: 0.9; text-decoration: none; }}
.btn--outline-white {{
  background: transparent;
  color: #fff;
  border-color: #fff;
}}
.btn--outline-white:hover {{
  background: rgba(255,255,255,0.1);
  text-decoration: none;
}}
.btn--lg {{
  font-size: 1.125rem;
  padding: 1rem 2rem;
}}

/* === Card Grid === */
.card-grid {{
  display: grid;
  gap: 1.5rem;
}}
.card-grid--2 {{ grid-template-columns: repeat(2, 1fr); }}
.card-grid--3 {{ grid-template-columns: repeat(3, 1fr); }}
.card-grid--4 {{ grid-template-columns: repeat(4, 1fr); }}

/* === Cards === */
.card, .product-card, .feature-card, .solution-card, .post-card, .case-card, .pricing-card {{
  background: var(--background);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 2rem;
  transition: box-shadow 0.2s ease;
}}
.card:hover, .product-card:hover, .post-card:hover, .case-card:hover {{
  box-shadow: var(--shadow-md);
}}
.card__headline, .product-card__name, .feature-card__name, .solution-card__name {{
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.75rem;
}}
.card__body, .product-card__description, .feature-card__is, .solution-card__is {{
  font-size: 0.9375rem;
  color: var(--text-muted);
  line-height: 1.6;
}}
.product-card__positioning {{
  font-size: 0.875rem;
  color: var(--primary);
  margin-bottom: 0.5rem;
}}
.product-card__badge {{
  display: inline-block;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  padding: 0.25rem 0.75rem;
  border-radius: 100px;
  background: var(--accent-muted);
  color: var(--text);
  margin-bottom: 1rem;
}}
.product-card__image, .post-card__image, .case-card__image {{
  height: 200px;
  background: var(--background-alt);
  border-radius: var(--radius);
  margin-bottom: 1.5rem;
}}

/* === Stats === */
.stats-grid {{
  display: flex;
  justify-content: center;
  gap: 3rem;
  flex-wrap: wrap;
}}
.stat {{ text-align: center; }}
.stat__number {{
  display: block;
  font-family: var(--font-primary);
  font-size: 3rem;
  font-weight: 700;
  color: var(--accent);
  line-height: 1;
  margin-bottom: 0.5rem;
}}
.stat__label {{
  font-size: 1rem;
  color: var(--surface-dark-muted);
}}

/* === Benefits === */
.benefits-list {{ display: flex; flex-direction: column; gap: 2rem; }}
.benefit-row {{ padding: 1.5rem 0; border-bottom: 1px solid var(--border); }}
.benefit-row__does {{ font-size: 1rem; margin-bottom: 0.5rem; }}
.benefit-row__means {{ font-size: 0.9375rem; color: var(--text-muted); }}

/* === Pricing === */
.pricing-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
}}
.pricing-card {{
  text-align: center;
  padding: 2.5rem 2rem;
}}
.pricing-card__tier {{
  font-size: 1.25rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
}}
.pricing-card__price {{
  font-size: 2rem;
  font-weight: 700;
  color: var(--primary);
  margin-bottom: 1.5rem;
}}
.pricing-card__features {{
  list-style: none;
  padding: 0;
  margin-bottom: 2rem;
  text-align: left;
}}
.pricing-card__features li {{
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border);
  font-size: 0.9375rem;
}}

/* === Blog === */
.post-card--featured {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  align-items: center;
}}
.post-card--featured .post-card__image {{ height: 300px; }}
.post-card__category {{
  display: inline-block;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--primary);
  margin-bottom: 0.5rem;
}}
.post-card__title {{ margin-bottom: 0.75rem; }}
.post-card__title a {{ color: var(--text); }}
.post-card__title a:hover {{ color: var(--primary); text-decoration: none; }}
.post-card__excerpt {{
  font-size: 0.9375rem;
  color: var(--text-muted);
  margin-bottom: 0.75rem;
}}
.post-card__date {{
  font-size: 0.8125rem;
  color: var(--text-muted);
}}

/* === Article === */
.article__header {{ padding: 4rem 0 2rem; }}
.article__category {{
  display: inline-block;
  font-size: 0.75rem;
  font-weight: 700;
  text-transform: uppercase;
  color: var(--primary);
  margin-bottom: 1rem;
}}
.article__title {{ font-size: 2.5rem; margin-bottom: 1rem; }}
.article__meta {{
  font-size: 0.875rem;
  color: var(--text-muted);
  display: flex;
  gap: 1.5rem;
}}
.article__body {{ padding: 2rem 0 4rem; }}

/* === Prose (long-form content) === */
.prose p {{ margin-bottom: 1.25rem; }}
.prose h2 {{ margin-top: 2.5rem; margin-bottom: 1rem; }}
.prose h3 {{ margin-top: 2rem; margin-bottom: 0.75rem; }}
.prose ul, .prose ol {{ margin-bottom: 1.25rem; padding-left: 1.5rem; }}
.prose li {{ margin-bottom: 0.5rem; }}
.prose blockquote {{
  border-left: 4px solid var(--primary);
  padding: 1rem 1.5rem;
  margin: 1.5rem 0;
  background: var(--background-alt);
  border-radius: 0 var(--radius) var(--radius) 0;
}}

/* === Timeline === */
.timeline {{
  list-style: none;
  padding: 0;
  position: relative;
}}
.timeline::before {{
  content: "";
  position: absolute;
  left: 1.5rem;
  top: 0;
  bottom: 0;
  width: 2px;
  background: var(--border);
}}
.timeline__item {{
  position: relative;
  padding-left: 4rem;
  padding-bottom: 2rem;
}}
.timeline__year {{
  position: absolute;
  left: 0;
  width: 3rem;
  height: 3rem;
  background: var(--primary);
  color: #fff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.75rem;
  font-weight: 700;
}}

/* === Contact === */
.contact-grid {{
  display: grid;
  grid-template-columns: 1fr 1.5fr;
  gap: 3rem;
}}
.contact-info address {{
  font-style: normal;
  line-height: 2;
  color: var(--text-muted);
}}
.form__field {{ margin-bottom: 1.25rem; }}
.form__field label {{
  display: block;
  font-size: 0.875rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--text);
}}
.form__field input,
.form__field textarea {{
  width: 100%;
  padding: 0.75rem 1rem;
  border: 1px solid var(--border);
  border-radius: var(--radius);
  font-family: var(--font-body);
  font-size: 1rem;
  background: var(--background);
  color: var(--text);
}}
.form__field input:focus,
.form__field textarea:focus {{
  outline: none;
  border-color: var(--primary);
  box-shadow: 0 0 0 3px var(--accent-muted);
}}

/* === CTA Section === */
.cta-section {{ text-align: center; }}
.cta-section__headline {{
  font-size: 2.25rem;
  color: #fff;
  margin-bottom: 1rem;
}}
.cta-section__body {{
  font-size: 1.125rem;
  color: rgba(255,255,255,0.85);
  max-width: 600px;
  margin: 0 auto 2rem;
}}
.cta-section__buttons {{
  display: flex;
  gap: 1rem;
  justify-content: center;
  flex-wrap: wrap;
}}

/* === Mission Quote === */
.mission-quote {{
  text-align: center;
  max-width: 700px;
  margin: 0 auto;
  padding: 2rem;
}}
.mission-quote p {{
  font-size: 1.5rem;
  font-style: italic;
  line-height: 1.5;
  color: var(--text);
}}

/* === Page Header === */
.page-header {{
  padding: 3rem 0 2rem;
  border-bottom: 1px solid var(--border);
}}
.page-header h1 {{ margin-bottom: 0.5rem; }}
.page-header__subtitle {{
  font-size: 1.125rem;
  color: var(--text-muted);
}}

/* === Responsive === */
@media (max-width: 768px) {{
  .hero__headline {{ font-size: 2.25rem; }}
  .hero__subline {{ font-size: 1rem; }}
  .section__headline {{ font-size: 1.75rem; }}
  .card-grid--2, .card-grid--3, .card-grid--4 {{
    grid-template-columns: 1fr;
  }}
  .post-card--featured {{
    grid-template-columns: 1fr;
  }}
  .contact-grid {{
    grid-template-columns: 1fr;
  }}
  .stats-grid {{
    flex-direction: column;
    gap: 2rem;
  }}
  .section {{ padding: 3rem 0; }}
  .hero {{ padding: 5rem 0 3rem; }}
  h1 {{ font-size: 2rem; }}
  h2 {{ font-size: 1.5rem; }}
}}

@media (max-width: 480px) {{
  .container {{ padding: 0 1rem; }}
  .hero__headline {{ font-size: 1.75rem; }}
  .btn--lg {{ padding: 0.75rem 1.5rem; font-size: 1rem; }}
}}
"""
    return css


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <design-variables.json> <output-css-path>")
        sys.exit(1)

    dv_path = sys.argv[1]
    output_path = sys.argv[2]

    dv = read_design_variables(dv_path)
    css = generate_css(dv)

    output = Path(output_path)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(css, encoding="utf-8")

    size_kb = len(css.encode("utf-8")) / 1024
    print(f"Generated {output_path} ({size_kb:.1f} KB)")


if __name__ == "__main__":
    main()

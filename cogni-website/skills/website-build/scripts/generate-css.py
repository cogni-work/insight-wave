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

    # Pass through all theme colors as CSS custom properties.
    # Rename "primary" to "brand-primary" to avoid collision with the
    # website alias --primary (which maps to the accent/action color).
    renames = {"primary": "brand-primary"}
    css_vars = []
    for key, value in colors.items():
        css_name = renames.get(key, key).replace("_", "-")
        css_vars.append(f"  --{css_name}: {value};")

    # Website-specific aliases (semantic names used by CSS classes)
    css_vars.append("")
    css_vars.append("  /* Website aliases */")
    css_vars.append(f"  --primary: {colors.get('accent', '#2563EB')};")
    css_vars.append(f"  --primary-dark: {colors.get('accent_dark', '#1E40AF')};")
    css_vars.append(f"  --background-alt: {colors.get('surface', '#F9FAFB')};")
    css_vars.append(f"  --surface-dark-text: #FFFFFF;")
    css_vars.append(f"  --surface-dark-muted: {colors.get('text_light', '#D1D5DB')};")

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

/* === Section Block Library (narrative pages) === */
/* Blocks emitted by website-plan step 6a — see libraries/page-templates.md Appendix. */

.section__headline--light {{ color: var(--surface-dark-text); }}

/* problem-statement */
.problem-statement .section-label {{
  color: var(--primary);
  margin-bottom: 0.5rem;
}}
.problem-statement__stat {{
  margin: 1.5rem 0;
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--primary);
}}
.problem-statement__stat .stat__number {{
  font-size: inherit;
  color: inherit;
}}
.problem-statement__bullets {{
  list-style: none;
  padding: 0;
  margin: 1.5rem 0 0;
  display: grid;
  gap: 0.75rem;
}}
.problem-statement__bullets li {{
  padding-left: 1.5rem;
  position: relative;
  color: var(--text);
}}
.problem-statement__bullets li::before {{
  content: "—";
  position: absolute;
  left: 0;
  color: var(--primary);
  font-weight: 700;
}}

/* stat-row */
.stats-row {{ text-align: center; }}
.stats-row .stats-grid {{
  margin-top: 2.5rem;
}}

/* feature-alternating */
.feature-alternating__grid {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 3rem;
  align-items: center;
}}
.feature-alternating--right .feature-alternating__grid {{
  direction: rtl;
}}
.feature-alternating--right .feature-alternating__text,
.feature-alternating--right .feature-alternating__image {{
  direction: ltr;
}}
.feature-alternating__text .section-label {{
  color: var(--primary);
  margin-bottom: 0.5rem;
}}
.feature-alternating__image {{
  min-height: 320px;
  display: flex;
  align-items: stretch;
}}
.image-placeholder {{
  flex: 1;
  border-radius: var(--radius);
  background: linear-gradient(135deg, var(--background-alt) 0%, var(--accent-muted, var(--background-alt)) 100%);
  border: 1px dashed var(--border);
  min-height: 320px;
}}

/* feature-grid */
.feature-grid-section {{ /* reuses .card-grid--3 */ }}
.feature-grid-section .section__headline {{
  text-align: center;
  margin-bottom: 2.5rem;
}}

/* comparison */
.comparison__grid {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2rem;
  margin-top: 2rem;
}}
.comparison__column {{
  padding: 1.75rem;
  border-radius: var(--radius);
  background: var(--background);
  border: 1px solid var(--border);
}}
.comparison__column h3 {{
  font-size: 1.125rem;
  margin-bottom: 1rem;
  color: var(--text);
}}
.comparison__column ul {{
  list-style: none;
  padding: 0;
  margin: 0;
  display: grid;
  gap: 0.5rem;
}}
.comparison__column--before {{
  border-color: var(--border);
  opacity: 0.85;
}}
.comparison__column--before h3 {{ color: var(--text-muted); }}
.comparison__column--after {{
  border-color: var(--primary);
  box-shadow: var(--shadow-sm, 0 1px 3px rgba(0,0,0,0.08));
}}
.comparison__column--after h3 {{ color: var(--primary); }}

/* testimonial */
.testimonial {{ text-align: center; }}
.testimonial__quote {{
  margin: 0 auto;
  padding: 0;
  max-width: 720px;
}}
.testimonial__quote p {{
  font-size: 1.5rem;
  line-height: 1.5;
  font-style: italic;
  color: var(--surface-dark-text);
  margin-bottom: 1.5rem;
}}
.testimonial__attribution {{
  font-size: 0.95rem;
  font-style: normal;
  color: var(--surface-dark-muted);
}}

/* page-footnotes (citations carry-through) */
.page-footnotes {{
  max-width: 720px;
  margin: 4rem auto 2rem;
  padding: 2rem 1.5rem 0;
  border-top: 1px solid var(--border);
}}
.page-footnotes__headline {{
  font-size: 1rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text-muted);
  margin-bottom: 1rem;
}}
.page-footnotes__list {{
  font-size: 0.875rem;
  color: var(--text-muted);
  padding-left: 1.25rem;
  display: grid;
  gap: 0.5rem;
}}
.page-footnotes__list a {{
  color: var(--primary);
  word-break: break-word;
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
  .feature-alternating__grid,
  .comparison__grid {{
    grid-template-columns: 1fr;
  }}
  .feature-alternating--right .feature-alternating__grid {{ direction: ltr; }}
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

/* === Header Navigation === */
.site-header {{
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--background);
  border-bottom: 1px solid var(--border);
  padding: 0 1.5rem;
  height: 72px;
}}

.site-header__inner {{
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
}}

.site-header__logo-text {{
  font-family: var(--font-primary);
  font-weight: bold;
  font-size: 1.25rem;
  color: var(--text);
  text-decoration: none;
}}

.site-nav__list {{
  display: flex;
  gap: 2rem;
  list-style: none;
  margin: 0;
  padding: 0;
}}

.site-nav__link {{
  font-family: var(--font-body);
  font-size: 0.9375rem;
  color: var(--text-muted);
  text-decoration: none;
  transition: color 0.2s;
}}

.site-nav__link:hover,
.site-nav__link--active {{
  color: var(--accent);
}}

.site-nav__item--has-children {{
  position: relative;
}}

.site-nav__dropdown {{
  display: none;
  position: absolute;
  top: 100%;
  left: 0;
  background: var(--background);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 0.5rem 0;
  min-width: 200px;
  box-shadow: var(--shadow-md);
}}

.site-nav__item--has-children:hover .site-nav__dropdown {{
  display: block;
}}

.site-nav__dropdown-link {{
  display: block;
  padding: 0.5rem 1rem;
  color: var(--text-muted);
  text-decoration: none;
  font-size: 0.875rem;
}}

.site-nav__dropdown-link:hover {{
  color: var(--accent);
  background: var(--background-alt);
}}

.site-header__mobile-toggle {{
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0.5rem;
}}

.hamburger {{
  display: block;
  width: 24px;
  height: 2px;
  background: var(--text);
  position: relative;
}}

.hamburger::before,
.hamburger::after {{
  content: "";
  display: block;
  width: 24px;
  height: 2px;
  background: var(--text);
  position: absolute;
  left: 0;
}}

.hamburger::before {{ top: -7px; }}
.hamburger::after {{ top: 7px; }}

@media (max-width: 768px) {{
  .site-nav, .site-header__cta {{ display: none; }}
  .site-header__mobile-toggle {{ display: block; }}
  .site-nav--open {{
    display: flex;
    flex-direction: column;
    position: absolute;
    top: 72px;
    left: 0;
    right: 0;
    background: var(--background);
    border-bottom: 1px solid var(--border);
    padding: 1rem;
  }}
  .site-nav--open .site-nav__list {{
    flex-direction: column;
    gap: 0.5rem;
  }}
}}

/* === Footer === */
.site-footer {{
  background: var(--surface-dark);
  color: var(--surface-dark-text, #fff);
  padding: 4rem 0 2rem;
}}

.site-footer__grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}}

.site-footer__heading {{
  font-family: var(--font-primary);
  font-size: 1rem;
  font-weight: bold;
  margin-bottom: 1rem;
}}

.site-footer__links {{
  list-style: none;
  padding: 0;
  margin: 0;
}}

.site-footer__links a {{
  color: var(--surface-dark-muted, #ccc);
  text-decoration: none;
  font-size: 0.875rem;
  line-height: 2;
}}

.site-footer__links a:hover {{
  color: #fff;
}}

.site-footer__logo {{
  font-family: var(--font-primary);
  font-weight: bold;
  font-size: 1.125rem;
  display: block;
  margin-bottom: 0.5rem;
}}

.site-footer__tagline {{
  font-size: 0.875rem;
  color: var(--surface-dark-muted, #ccc);
}}

.site-footer__bottom {{
  border-top: 1px solid rgba(255,255,255,0.1);
  padding-top: 1.5rem;
  text-align: center;
}}

.site-footer__copyright {{
  font-size: 0.8125rem;
  color: var(--surface-dark-muted, #999);
}}

/* === Breadcrumbs === */
.breadcrumb__list {{
  display: flex;
  gap: 0.5rem;
  list-style: none;
  padding: 0;
  margin: 0 0 1rem;
  font-size: 0.875rem;
}}

.breadcrumb__item + .breadcrumb__item::before {{
  content: "\203A";
  margin-right: 0.5rem;
  color: var(--text-muted);
}}

.breadcrumb__item a {{
  color: var(--text-muted);
  text-decoration: none;
}}

.breadcrumb__item a:hover {{
  color: var(--accent);
}}

.breadcrumb__item--current {{
  color: var(--text);
}}

.breadcrumb--light .breadcrumb__item a,
.breadcrumb--light .breadcrumb__item::before {{
  color: var(--surface-dark-muted, #ccc);
}}

.breadcrumb--light .breadcrumb__item--current {{
  color: #fff;
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

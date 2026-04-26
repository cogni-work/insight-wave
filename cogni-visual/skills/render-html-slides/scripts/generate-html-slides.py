#!/usr/bin/env python3
"""Generate a self-contained themed HTML slide presentation from parsed slide data.

Usage:
    python3 generate-html-slides.py \
        --slide-data <slide-data.json> \
        --design-variables <design-variables.json> \
        --output <output.html> \
        --transition <fade|slide|none> \
        --aspect-ratio <16:9|4:3> \
        --language <en|de>

Input:  slide-data.json (parsed from presentation-brief.md by LLM)
Output: Self-contained HTML file with themed slides, navigation, speaker notes panel.
Returns JSON: {"status": "ok", "path": "<output-path>", "slides": N} or {"error": "..."}
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime


# ---------------------------------------------------------------------------
# Theme / Design Variables
# ---------------------------------------------------------------------------

DEFAULT_THEME = {
    "theme_name": "cogni-work",
    "colors": {
        "primary": "#111111", "secondary": "#333333",
        "accent": "#C8E62E", "accent_muted": "#A8C424", "accent_dark": "#8BA31E",
        "background": "#FAFAF8", "surface": "#F2F2EE", "surface2": "#E8E8E4",
        "surface_dark": "#111111", "border": "#E0E0DC",
        "text": "#111111", "text_light": "#FFFFFF", "text_muted": "#6B7280",
    },
    "status": {
        "success": "#2E7D32", "warning": "#E5A100",
        "danger": "#D32F2F", "info": "#1565C0",
    },
    "fonts": {
        "headers": "'Bricolage Grotesque', 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "body": "'Outfit', 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
        "mono": "'JetBrains Mono', 'Fira Code', Consolas, monospace",
    },
    "google_fonts_import": "@import url('https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&family=Outfit:wght@300;400;500;600;700&display=swap');",
    "radius": "12px",
    "shadows": {
        "sm": "0 1px 3px rgba(0,0,0,0.04), 0 1px 2px rgba(0,0,0,0.06)",
        "md": "0 4px 16px rgba(0,0,0,0.06), 0 1px 4px rgba(0,0,0,0.04)",
        "lg": "0 12px 40px rgba(0,0,0,0.1), 0 4px 12px rgba(0,0,0,0.05)",
        "xl": "0 24px 64px rgba(0,0,0,0.14), 0 8px 20px rgba(0,0,0,0.06)",
    },
}


def load_design_variables(path):
    """Load design-variables.json, falling back to DEFAULT_THEME."""
    if not path or not os.path.isfile(path):
        return DEFAULT_THEME.copy()
    with open(path) as f:
        dv = json.load(f)
    result = DEFAULT_THEME.copy()
    for section in ("colors", "status", "fonts", "shadows"):
        if section in dv:
            result[section] = {**result.get(section, {}), **dv[section]}
    for key in ("theme_name", "google_fonts_import", "radius"):
        if key in dv:
            result[key] = dv[key]
    return result


# ---------------------------------------------------------------------------
# Theme System v2 — Tier-aware resolution (Phase-2 pilot, RFC #124, #129)
# ---------------------------------------------------------------------------

def resolve_themes_dir(themes_dir_arg):
    """Resolve the workspace themes/ directory.

    Order: explicit ``--themes-dir`` argument; ``$COGNI_WORKSPACE_ROOT``;
    walk up from this script looking for a sibling ``cogni-workspace/themes``;
    return None if nothing is found.

    Tier-aware resolution is fully optional — every existing call site
    behaves exactly as before when this returns None or when --theme-slug
    is omitted.
    """
    if themes_dir_arg:
        p = os.path.abspath(os.path.expanduser(themes_dir_arg))
        return p if os.path.isdir(p) else None
    env = os.environ.get("COGNI_WORKSPACE_ROOT")
    if env:
        candidate = os.path.join(env, "themes")
        if os.path.isdir(candidate):
            return candidate
    here = os.path.dirname(os.path.abspath(__file__))
    for _ in range(6):
        candidate = os.path.join(here, "cogni-workspace", "themes")
        if os.path.isdir(candidate):
            return candidate
        parent = os.path.dirname(here)
        if parent == here:
            break
        here = parent
    return None


def resolve_tokens_css(themes_dir, theme_slug):
    """Return the absolute path to ``themes/<slug>/tokens/tokens.css``.

    Returns None when the theme is tier-0 (no manifest.json), when the
    manifest does not declare ``tiers.tokens``, or when the resolved file
    does not exist on disk. None is the documented "use the inline
    :root tokens block only" signal — every existing tier-0 caller flows
    through this path.
    """
    if not themes_dir or not theme_slug:
        return None
    theme_dir = os.path.join(themes_dir, theme_slug)
    manifest_path = os.path.join(theme_dir, "manifest.json")
    if not os.path.isfile(manifest_path):
        return None
    try:
        with open(manifest_path, "r", encoding="utf-8") as h:
            manifest = json.load(h)
    except (json.JSONDecodeError, OSError):
        return None
    tiers = manifest.get("tiers")
    if not isinstance(tiers, dict):
        return None
    tokens_rel = tiers.get("tokens")
    if not isinstance(tokens_rel, str) or not tokens_rel:
        return None
    tokens_css = os.path.join(theme_dir, tokens_rel.rstrip("/"), "tokens.css")
    return tokens_css if os.path.isfile(tokens_css) else None


# ---------------------------------------------------------------------------
# HTML Utilities
# ---------------------------------------------------------------------------

def escape_html(text):
    """Escape HTML special characters."""
    if not text:
        return ""
    return (str(text)
            .replace('&', '&amp;')
            .replace('<', '&lt;')
            .replace('>', '&gt;')
            .replace('"', '&quot;'))


def convert_inline(text):
    """Convert inline markdown (bold, italic, links, code, superscript citations) to HTML."""
    if not text:
        return ""
    text = str(text)
    # Superscript citations: <sup>[N](url)</sup>
    text = re.sub(
        r'<sup>\[(\d+)\]\(([^)]+)\)</sup>',
        r'<a href="\2" target="_blank" rel="noopener" class="citation"><sup>\1</sup></a>',
        text
    )
    # Regular links: [text](url)
    text = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        r'<a href="\2" target="_blank" rel="noopener">\1</a>',
        text
    )
    # Bold: **text**
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    # Italic: *text*
    text = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', text)
    # Inline code: `text`
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text


def render_bullets(bullets, css_class=""):
    """Render a list of bullet strings to an HTML <ul>."""
    if not bullets:
        return ""
    cls = f' class="{css_class}"' if css_class else ""
    items = "\n".join(f"        <li>{convert_inline(b)}</li>" for b in bullets)
    return f"      <ul{cls}>\n{items}\n      </ul>"


def render_bottom_banner(fields):
    """Render a bottom banner if present in slide fields."""
    banner = fields.get("Bottom-Banner")
    if not banner:
        return ""
    text = banner.get("Text", "") if isinstance(banner, dict) else str(banner)
    if not text:
        return ""
    return f'      <div class="bottom-banner">{convert_inline(text)}</div>'


# ---------------------------------------------------------------------------
# Speaker Notes Renderer
# ---------------------------------------------------------------------------

def render_speaker_notes(notes_text):
    """Parse speaker notes text into structured HTML.

    Format:
      >> SECTION HEADER
      [Tag]: "quoted text"
      - bullet point
    """
    if not notes_text:
        return ""
    lines = notes_text.strip().split("\n")
    html_parts = []
    in_list = False

    for line in lines:
        line = line.strip()
        if not line:
            if in_list:
                html_parts.append("</ul>")
                in_list = False
            continue

        # Section header: >> WAS SIE SAGEN / >> WHAT YOU SAY
        if line.startswith(">>"):
            if in_list:
                html_parts.append("</ul>")
                in_list = False
            header = line[2:].strip()
            html_parts.append(f'<h4 class="notes-section">{escape_html(header)}</h4>')
            continue

        # Tagged line: [Opening]: "text"
        tag_match = re.match(r'\[([^\]]+)\]:\s*(.*)', line)
        if tag_match:
            if in_list:
                html_parts.append("</ul>")
                in_list = False
            tag = tag_match.group(1)
            content = tag_match.group(2).strip('"').strip("'")
            html_parts.append(
                f'<p class="notes-tagged"><span class="notes-tag">{escape_html(tag)}</span> '
                f'{convert_inline(content)}</p>'
            )
            continue

        # Bullet line
        if line.startswith("- "):
            if not in_list:
                html_parts.append('<ul class="notes-bullets">')
                in_list = True
            html_parts.append(f"  <li>{convert_inline(line[2:])}</li>")
            continue

        # Regular text
        if in_list:
            html_parts.append("</ul>")
            in_list = False
        html_parts.append(f"<p>{convert_inline(line)}</p>")

    if in_list:
        html_parts.append("</ul>")

    return "\n".join(html_parts)


# ---------------------------------------------------------------------------
# Layout Renderers
# ---------------------------------------------------------------------------

def render_title_slide(slide, dv):
    """Layout: title-slide — Full dark background, centered hero title."""
    f = slide["fields"]
    title = escape_html(f.get("Title", ""))
    subtitle = escape_html(f.get("Subtitle", ""))
    metadata = escape_html(f.get("Metadata", ""))

    return f"""
      <div class="slide-inner layout-title-slide">
        <div class="title-content">
          <h1 class="title-main">{title}</h1>
          <div class="title-accent-line"></div>
          <p class="title-subtitle">{subtitle}</p>
          <p class="title-metadata">{metadata}</p>
        </div>
      </div>"""


def render_stat_card(slide, dv):
    """Layout: stat-card-with-context — Hero stat left, context bullets right."""
    f = slide["fields"]
    hero = f.get("Hero-Stat-Box", {})
    ctx = f.get("Context-Box", {})
    impact = f.get("Impact-Box", {})

    number = escape_html(hero.get("Number", ""))
    label = escape_html(hero.get("Label", ""))
    sublabel = escape_html(hero.get("Sublabel", ""))

    ctx_headline = escape_html(ctx.get("Headline", ""))
    ctx_bullets = ctx.get("Bullets", [])

    impact_html = ""
    if impact:
        impact_text = impact.get("Text", "") if isinstance(impact, dict) else str(impact)
        if impact_text:
            impact_html = f'<div class="impact-badge">{convert_inline(impact_text)}</div>'

    return f"""
      <div class="slide-inner layout-stat-card">
        <div class="stat-hero">
          <span class="stat-number">{number}</span>
          <span class="stat-label">{label}</span>
          <span class="stat-sublabel">{sublabel}</span>
          {impact_html}
        </div>
        <div class="stat-context">
          <h3>{ctx_headline}</h3>
          {render_bullets(ctx_bullets, "context-bullets")}
        </div>
      </div>"""


def render_four_quadrants(slide, dv):
    """Layout: four-quadrants — 2x2 grid of cards."""
    f = slide["fields"]
    quads = []
    for i in range(1, 5):
        key = f"Quadrant-{i}"
        q = f.get(key, {})
        if not q:
            continue
        number = escape_html(q.get("Number", ""))
        label = escape_html(q.get("Label", ""))
        bullets = q.get("Bullets", [])

        number_html = f'<span class="quad-number">{number}</span>' if number else ""
        label_html = f'<span class="quad-label">{label}</span>' if label else ""

        quads.append(f"""
          <div class="quad-card">
            {number_html}
            {label_html}
            {render_bullets(bullets, "quad-bullets")}
          </div>""")

    return f"""
      <div class="slide-inner layout-four-quadrants">
        <div class="quad-grid">
          {"".join(quads)}
        </div>
      </div>"""


def render_two_columns(slide, dv):
    """Layout: two-columns-equal — Side-by-side 50/50 columns."""
    f = slide["fields"]
    left = f.get("Left-Column", {})
    right = f.get("Right-Column", {})

    def render_col(col):
        headline = escape_html(col.get("Headline", ""))
        bullets = col.get("Bullets", [])
        return f"""
          <div class="col-panel">
            <h3>{headline}</h3>
            {render_bullets(bullets, "col-bullets")}
          </div>"""

    return f"""
      <div class="slide-inner layout-two-columns">
        {render_col(left)}
        <div class="col-divider"></div>
        {render_col(right)}
      </div>"""


def render_is_does_means(slide, dv, language="en"):
    """Layout: is-does-means — Three horizontal bands with localized badges."""
    f = slide["fields"]
    labels = {
        "en": ("IS", "DOES", "MEANS"),
        "de": ("IST", "MACHT", "BEDEUTET"),
    }
    is_l, does_l, means_l = labels.get(language, labels["en"])

    bands = []
    for key, badge in [("IS-Box", is_l), ("DOES-Box", does_l), ("MEANS-Box", means_l)]:
        box = f.get(key, {})
        text = convert_inline(box.get("Text", "")) if isinstance(box, dict) else convert_inline(str(box))
        bands.append(f"""
          <div class="idm-band">
            <span class="idm-badge">{badge}</span>
            <div class="idm-text">{text}</div>
          </div>""")

    return f"""
      <div class="slide-inner layout-is-does-means">
        {"".join(bands)}
      </div>"""


def render_three_options(slide, dv):
    """Layout: three-options — Three equal-width columns for pricing/alternatives."""
    f = slide["fields"]
    options = []
    for i in range(1, 4):
        key = f"Option-{i}"
        opt = f.get(key, {})
        if not opt:
            continue
        title = escape_html(opt.get("Title", opt.get("Label", f"Option {i}")))
        subtitle = escape_html(opt.get("Subtitle", ""))
        bullets = opt.get("Bullets", [])
        is_recommended = opt.get("Recommended", False)
        rec_class = " option-recommended" if is_recommended else ""
        rec_badge = '<span class="rec-badge">&#9733;</span>' if is_recommended else ""

        options.append(f"""
          <div class="option-card{rec_class}">
            {rec_badge}
            <h3 class="option-title">{title}</h3>
            <p class="option-subtitle">{subtitle}</p>
            {render_bullets(bullets, "option-bullets")}
          </div>""")

    return f"""
      <div class="slide-inner layout-three-options">
        <div class="options-grid">
          {"".join(options)}
        </div>
      </div>"""


def render_timeline_steps(slide, dv):
    """Layout: timeline-steps — Horizontal timeline with connected accent dots."""
    f = slide["fields"]
    steps = f.get("Steps", [])
    if not steps and f.get("Step-1"):
        # Alternative format: Step-1, Step-2, etc.
        steps = []
        for i in range(1, 10):
            s = f.get(f"Step-{i}")
            if s:
                steps.append(s)

    nodes = []
    for i, step in enumerate(steps):
        if isinstance(step, dict):
            title = escape_html(step.get("Title", step.get("Label", f"Step {i+1}")))
            detail = escape_html(step.get("Detail", step.get("Date", "")))
            bullets = step.get("Bullets", [])
        else:
            title = escape_html(str(step))
            detail = ""
            bullets = []

        bullets_html = render_bullets(bullets, "step-bullets") if bullets else ""

        nodes.append(f"""
          <div class="timeline-node">
            <div class="timeline-dot"></div>
            <div class="timeline-label">
              <strong>{title}</strong>
              <span class="timeline-detail">{detail}</span>
              {bullets_html}
            </div>
          </div>""")

    return f"""
      <div class="slide-inner layout-timeline">
        <div class="timeline-track">
          {"".join(nodes)}
        </div>
      </div>"""


def _extract_phase_labels(diagram_text):
    """Extract node labels from a Mermaid graph LR definition."""
    if not diagram_text:
        return []
    labels = []
    # Match patterns like P1["Job Landscape"] or A["Step 1"]
    for match in re.finditer(r'\w+\["([^"]+)"\]', diagram_text):
        labels.append(match.group(1))
    return labels


def render_process_flow(slide, dv):
    """Layout: process-flow — Unified pipeline with phase headers + detail bullets."""
    f = slide["fields"]
    diagram = f.get("Diagram", "")
    detail_grid = f.get("Detail-Grid", {})

    # When Detail-Grid exists, render as unified pipeline columns
    if detail_grid:
        phase_labels = _extract_phase_labels(diagram)
        columns = []
        for i, (key, bullets) in enumerate(detail_grid.items()):
            if not isinstance(bullets, list):
                continue
            # Use Mermaid label if available, otherwise use the key
            label = phase_labels[i] if i < len(phase_labels) else key
            items = "\n".join(f"<li>{convert_inline(b)}</li>" for b in bullets)
            arrow = '<div class="phase-arrow">&#8594;</div>' if i < len(detail_grid) - 1 else ""
            columns.append(f"""
              <div class="phase-column">
                <div class="phase-header">{escape_html(label)}</div>
                <div class="phase-body">
                  <ul>{items}</ul>
                </div>
              </div>{arrow}""")

        return f"""
      <div class="slide-inner layout-process-flow">
        <div class="phase-pipeline">
          {"".join(columns)}
        </div>
      </div>"""

    # Fallback: Mermaid-only (no Detail-Grid)
    diagram_html = ""
    if diagram:
        diagram_html = f'<pre class="mermaid">{escape_html(diagram.strip())}</pre>'

    return f"""
      <div class="slide-inner layout-process-flow">
        <div class="diagram-container">
          {diagram_html}
        </div>
      </div>"""


def render_closing_slide(slide, dv):
    """Layout: closing-slide — Full dark background with CTA headline."""
    f = slide["fields"]
    headline = escape_html(f.get("Headline", f.get("Title", "")))
    takeaway = convert_inline(f.get("Key-Takeaway", f.get("Takeaway", "")))
    cta = convert_inline(f.get("CTA", ""))

    cta_html = f'<p class="closing-cta">{cta}</p>' if cta else ""

    return f"""
      <div class="slide-inner layout-closing-slide">
        <div class="closing-content">
          <h1 class="closing-headline">{headline}</h1>
          <div class="closing-accent-line"></div>
          <p class="closing-takeaway">{takeaway}</p>
          {cta_html}
        </div>
      </div>"""


def render_references_slide(slide, dv):
    """Layout: references — Numbered citation list with clickable links."""
    f = slide["fields"]
    refs = f.get("References", f.get("Citations", []))

    if isinstance(refs, list):
        items = []
        for i, ref in enumerate(refs, 1):
            if isinstance(ref, dict):
                text = ref.get("Title", ref.get("Text", f"Source {i}"))
                url = ref.get("URL", ref.get("url", "#"))
                items.append(f'<li><a href="{escape_html(url)}" target="_blank" rel="noopener">{convert_inline(text)}</a></li>')
            else:
                items.append(f"<li>{convert_inline(str(ref))}</li>")
        refs_html = f'<ol class="references-list">{"".join(items)}</ol>'
    else:
        refs_html = f"<div class='references-text'>{convert_inline(str(refs))}</div>"

    return f"""
      <div class="slide-inner layout-references">
        <div class="references-content">
          {refs_html}
        </div>
      </div>"""


def render_generic_slide(slide, dv):
    """Fallback renderer for unrecognized layout types."""
    f = slide["fields"]
    content_parts = []
    for key, val in f.items():
        if key in ("Speaker-Notes", "Bottom-Banner"):
            continue
        if isinstance(val, dict):
            content_parts.append(f"<h3>{escape_html(key)}</h3>")
            for k2, v2 in val.items():
                if isinstance(v2, list):
                    content_parts.append(f"<h4>{escape_html(k2)}</h4>")
                    content_parts.append(render_bullets(v2))
                else:
                    content_parts.append(f"<p><strong>{escape_html(k2)}:</strong> {convert_inline(str(v2))}</p>")
        elif isinstance(val, list):
            content_parts.append(f"<h3>{escape_html(key)}</h3>")
            content_parts.append(render_bullets(val))
        else:
            content_parts.append(f"<p><strong>{escape_html(key)}:</strong> {convert_inline(str(val))}</p>")

    return f"""
      <div class="slide-inner layout-generic">
        {"".join(content_parts)}
      </div>"""


# Layout dispatcher
LAYOUT_RENDERERS = {
    "title-slide": render_title_slide,
    "stat-card-with-context": render_stat_card,
    "four-quadrants": render_four_quadrants,
    "two-columns-equal": render_two_columns,
    "is-does-means": render_is_does_means,
    "three-options": render_three_options,
    "timeline-steps": render_timeline_steps,
    "process-flow": render_process_flow,
    "layered-architecture": render_process_flow,  # same Mermaid rendering
    "gantt-chart": render_process_flow,            # same Mermaid rendering
    "closing-slide": render_closing_slide,
    "references": render_references_slide,
}


def render_slide(slide, dv, language="en"):
    """Dispatch to the appropriate layout renderer."""
    layout = slide.get("layout", "generic")
    renderer = LAYOUT_RENDERERS.get(layout, render_generic_slide)

    # Special case: is-does-means needs language
    if layout == "is-does-means":
        return renderer(slide, dv, language)
    return renderer(slide, dv)


# ---------------------------------------------------------------------------
# CSS Generation
# ---------------------------------------------------------------------------

def generate_css(dv, transition="fade", aspect_ratio="16:9"):
    """Generate the complete CSS for the slide presentation."""
    c = dv["colors"]
    fonts = dv["fonts"]
    shadows = dv["shadows"]
    radius = dv.get("radius", "12px")

    # Aspect ratio calculation
    if aspect_ratio == "4:3":
        ar_value = "4 / 3"
        ar_max_w = "133.33vh"
        ar_max_h = "75vw"
    else:
        ar_value = "16 / 9"
        ar_max_w = "177.78vh"
        ar_max_h = "56.25vw"

    # Transition CSS
    transition_css = ""
    if transition == "fade":
        transition_css = """
  .slide { opacity: 0; transition: opacity 0.5s cubic-bezier(0.4, 0, 0.2, 1); }
  .slide.active { opacity: 1; }"""
    elif transition == "slide":
        transition_css = """
  .slide { opacity: 0; transform: translateX(60px); transition: all 0.5s cubic-bezier(0.4, 0, 0.2, 1); }
  .slide.active { opacity: 1; transform: translateX(0); }
  .slide.exit-left { opacity: 0; transform: translateX(-60px); }"""
    else:
        transition_css = """
  .slide { opacity: 0; }
  .slide.active { opacity: 1; }"""

    return f"""
  /* ---- Design Tokens ---- */
  :root {{
    --primary: {c["primary"]};
    --secondary: {c["secondary"]};
    --accent: {c["accent"]};
    --accent-muted: {c.get("accent_muted", c["accent"])};
    --accent-dark: {c.get("accent_dark", c["accent"])};
    --bg: {c["background"]};
    --surface: {c["surface"]};
    --surface2: {c.get("surface2", c["surface"])};
    --surface-dark: {c.get("surface_dark", "#111111")};
    --border: {c.get("border", "#E0E0DC")};
    --text: {c["text"]};
    --text-light: {c.get("text_light", "#FFFFFF")};
    --text-muted: {c.get("text_muted", "#6B7280")};
    --font-headers: {fonts["headers"]};
    --font-body: {fonts["body"]};
    --font-mono: {fonts.get("mono", "monospace")};
    --radius: {radius};
    --shadow-sm: {shadows["sm"]};
    --shadow-md: {shadows["md"]};
    --shadow-lg: {shadows["lg"]};
  }}

  /* ---- Reset & Base ---- */
  *, *::before, *::after {{ box-sizing: border-box; margin: 0; padding: 0; }}
  html, body {{
    width: 100%; height: 100%; overflow: hidden;
    font-family: var(--font-body);
    background: var(--surface-dark);
    color: var(--text);
    -webkit-font-smoothing: antialiased;
  }}

  /* ---- Slide Deck Container ---- */
  .slide-deck {{
    width: 100vw; height: 100vh;
    position: relative; overflow: hidden;
  }}

  /* ---- Individual Slide ---- */
  .slide {{
    position: absolute; top: 0; left: 0;
    width: 100%; height: 100%;
    display: flex; align-items: center; justify-content: center;
    pointer-events: none; z-index: 0;
    background: var(--bg);
  }}
  .slide.active {{
    pointer-events: auto; z-index: 1;
  }}
  {transition_css}

  /* ---- Slide Content (Aspect Ratio Box) ---- */
  .slide-content {{
    width: min(100vw, {ar_max_w});
    height: min(100vh, {ar_max_h});
    aspect-ratio: {ar_value};
    position: relative;
    display: flex; flex-direction: column;
    padding: 5vh 5.5vw 3vh;
    overflow: hidden;
  }}

  /* ---- Slide Title ---- */
  .slide-title {{
    font-family: var(--font-headers);
    font-size: clamp(1.6rem, 2.8vw, 2.6rem);
    font-weight: 700;
    color: var(--primary);
    margin-bottom: 3vh;
    line-height: 1.15;
  }}

  /* ---- Slide Inner (Layout Area) ---- */
  .slide-inner {{
    flex: 1;
    display: flex;
    align-items: flex-start;
    justify-content: flex-start;
    gap: 3vw;
    min-height: 0;
    width: 100%;
  }}

  /* ---- Bottom Banner ---- */
  .bottom-banner {{
    position: absolute; bottom: 0; left: 0; right: 0;
    padding: 1.4vh 5vw;
    background: var(--surface-dark);
    color: var(--text-light);
    font-size: clamp(0.85rem, 1.2vw, 1.05rem);
    font-weight: 600;
    text-align: center;
    letter-spacing: 0.03em;
  }}

  /* ======== LAYOUT: Title Slide ======== */
  .layout-title-slide {{
    flex-direction: column;
    text-align: center;
    background: var(--surface-dark);
    border-radius: 0;
    padding: 8vh 6vw;
  }}
  .slide:has(.layout-title-slide) {{
    background: var(--surface-dark);
  }}
  .title-content {{ max-width: 80%; }}
  .title-main {{
    font-family: var(--font-headers);
    font-size: clamp(2.2rem, 4.5vw, 4rem);
    font-weight: 700;
    color: var(--text-light);
    line-height: 1.1;
    margin-bottom: 2vh;
  }}
  .title-accent-line {{
    width: 80px; height: 4px;
    background: var(--accent);
    margin: 2vh auto;
    border-radius: 2px;
  }}
  .title-subtitle {{
    font-size: clamp(1.1rem, 2vw, 1.6rem);
    color: var(--text-muted);
    font-weight: 300;
    margin-bottom: 3vh;
    line-height: 1.4;
  }}
  .title-metadata {{
    font-size: clamp(0.7rem, 1vw, 0.9rem);
    color: var(--text-muted);
    letter-spacing: 0.05em;
    text-transform: uppercase;
  }}

  /* ======== LAYOUT: Stat Card ======== */
  .layout-stat-card {{
    display: grid;
    grid-template-columns: 38% 1fr;
    gap: 4vw;
    align-items: center;
    align-content: center;
    width: 100%;
    height: 100%;
  }}
  .stat-hero {{
    display: flex; flex-direction: column;
    align-items: center; text-align: center;
    padding: 2vh 2vw 3vh;
  }}
  .stat-number {{
    font-family: var(--font-headers);
    font-size: clamp(3.5rem, 8vw, 7rem);
    font-weight: 700;
    color: var(--accent);
    line-height: 1;
    letter-spacing: -0.03em;
  }}
  .stat-label {{
    font-size: clamp(1rem, 1.6vw, 1.4rem);
    color: var(--text);
    font-weight: 600;
    margin-top: 1.2vh;
  }}
  .stat-sublabel {{
    font-size: clamp(0.85rem, 1.2vw, 1.05rem);
    color: var(--text-muted);
    margin-top: 0.5vh;
  }}
  .impact-badge {{
    margin-top: 2vh;
    padding: 0.5vh 1.5vw;
    background: var(--accent);
    color: var(--surface-dark);
    font-weight: 600;
    font-size: clamp(0.7rem, 1vw, 0.85rem);
    border-radius: var(--radius);
  }}
  .stat-context h3 {{
    font-family: var(--font-headers);
    font-size: clamp(1.15rem, 1.8vw, 1.6rem);
    font-weight: 600;
    margin-bottom: 2vh;
    color: var(--primary);
  }}
  .context-bullets {{ list-style: none; }}
  .context-bullets li {{
    padding: 0.9vh 0;
    padding-left: 1.5em;
    position: relative;
    font-size: clamp(0.95rem, 1.4vw, 1.15rem);
    line-height: 1.55;
    color: var(--text);
  }}
  .context-bullets li::before {{
    content: "";
    position: absolute; left: 0; top: 1.3vh;
    width: 8px; height: 8px;
    background: var(--accent);
    border-radius: 50%;
  }}

  /* ======== LAYOUT: Four Quadrants ======== */
  .layout-four-quadrants {{ flex-direction: column; width: 100%; justify-content: center; }}
  .quad-grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    grid-template-rows: 1fr 1fr;
    gap: 2vw;
    width: 100%;
    flex: 1;
  }}
  .quad-card {{
    background: var(--surface);
    border-radius: var(--radius);
    padding: 2.5vh 2vw;
    box-shadow: var(--shadow-sm);
    border-left: 4px solid var(--accent);
    display: flex;
    flex-direction: column;
    justify-content: center;
  }}
  .quad-number {{
    font-family: var(--font-headers);
    font-size: clamp(2rem, 3.5vw, 3rem);
    font-weight: 700;
    color: var(--accent);
    display: block;
    margin-bottom: 0.5vh;
  }}
  .quad-label {{
    font-size: clamp(1rem, 1.4vw, 1.2rem);
    font-weight: 600;
    color: var(--primary);
    display: block;
    margin-bottom: 1vh;
  }}
  .quad-bullets {{ list-style: none; }}
  .quad-bullets li {{
    font-size: clamp(0.85rem, 1.1vw, 1rem);
    color: var(--text-muted);
    padding: 0.4vh 0;
  }}

  /* ======== LAYOUT: Two Columns ======== */
  .layout-two-columns {{
    display: grid;
    grid-template-columns: 1fr auto 1fr;
    gap: 2vw;
    align-items: center;
    align-content: center;
    width: 100%;
    height: 100%;
  }}
  .col-panel h3 {{
    font-family: var(--font-headers);
    font-size: clamp(1.15rem, 1.7vw, 1.5rem);
    font-weight: 600;
    color: var(--primary);
    margin-bottom: 2vh;
  }}
  .col-divider {{
    width: 1px;
    height: 70%;
    align-self: center;
    background: var(--border);
  }}
  .col-bullets {{ list-style: none; }}
  .col-bullets li {{
    padding: 0.8vh 0;
    padding-left: 1.2em;
    position: relative;
    font-size: clamp(0.95rem, 1.4vw, 1.15rem);
    color: var(--text);
    line-height: 1.55;
  }}
  .col-bullets li::before {{
    content: "";
    position: absolute; left: 0; top: 1.1vh;
    width: 6px; height: 6px;
    background: var(--accent);
    border-radius: 50%;
  }}

  /* ======== LAYOUT: IS/DOES/MEANS ======== */
  .layout-is-does-means {{
    flex-direction: column;
    width: 100%;
    align-items: stretch;
    justify-content: center;
    gap: 2.5vh;
  }}
  .idm-band {{
    display: flex;
    align-items: flex-start;
    gap: 2.5vw;
    padding: 3.5vh 3vw;
    background: var(--surface);
    border-radius: var(--radius);
    border-left: 5px solid var(--accent);
    box-shadow: var(--shadow-sm);
  }}
  .idm-badge {{
    font-family: var(--font-headers);
    font-size: clamp(0.8rem, 1.1vw, 0.95rem);
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--accent-dark);
    background: var(--surface2);
    padding: 0.6vh 1.2vw;
    border-radius: 4px;
    min-width: 6em;
    text-align: center;
    flex-shrink: 0;
    margin-top: 0.2vh;
  }}
  .idm-text {{
    font-size: clamp(1rem, 1.5vw, 1.25rem);
    color: var(--text);
    line-height: 1.55;
  }}

  /* ======== LAYOUT: Three Options ======== */
  .layout-three-options {{ flex-direction: column; width: 100%; justify-content: center; }}
  .options-grid {{
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 2vw;
    width: 100%;
  }}
  .option-card {{
    background: var(--surface);
    border-radius: var(--radius);
    padding: 3vh 2vw;
    box-shadow: var(--shadow-sm);
    border-top: 3px solid var(--border);
    position: relative;
    text-align: center;
  }}
  .option-recommended {{
    border-top: 3px solid var(--accent);
    box-shadow: var(--shadow-md);
    transform: scale(1.03);
  }}
  .rec-badge {{
    position: absolute; top: -12px; right: 12px;
    background: var(--accent);
    color: var(--surface-dark);
    font-size: 0.7rem;
    padding: 2px 10px;
    border-radius: 10px;
    font-weight: 700;
  }}
  .option-title {{
    font-family: var(--font-headers);
    font-size: clamp(1.2rem, 1.8vw, 1.6rem);
    font-weight: 700;
    color: var(--primary);
    margin-bottom: 0.5vh;
  }}
  .option-subtitle {{
    font-size: clamp(0.9rem, 1.2vw, 1.05rem);
    color: var(--text-muted);
    margin-bottom: 2vh;
  }}
  .option-bullets {{ list-style: none; text-align: left; }}
  .option-bullets li {{
    padding: 0.6vh 0;
    padding-left: 1.2em;
    position: relative;
    font-size: clamp(0.9rem, 1.2vw, 1.05rem);
    color: var(--text);
  }}
  .option-bullets li::before {{
    content: "\\2713";
    position: absolute; left: 0;
    color: var(--accent);
    font-weight: 700;
  }}

  /* ======== LAYOUT: Timeline Steps ======== */
  .layout-timeline {{ flex-direction: column; width: 100%; justify-content: center; }}
  .timeline-track {{
    display: flex;
    align-items: flex-start;
    gap: 0;
    width: 100%;
    position: relative;
    padding-top: 20px;
  }}
  .timeline-track::before {{
    content: "";
    position: absolute;
    top: 26px;
    left: 5%;
    right: 5%;
    height: 3px;
    background: var(--border);
  }}
  .timeline-node {{
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    position: relative;
    z-index: 1;
  }}
  .timeline-dot {{
    width: 16px; height: 16px;
    border-radius: 50%;
    background: var(--accent);
    border: 3px solid var(--bg);
    box-shadow: 0 0 0 2px var(--accent);
    margin-bottom: 1.5vh;
    flex-shrink: 0;
  }}
  .timeline-label {{
    text-align: center;
    padding: 0 0.5vw;
  }}
  .timeline-label strong {{
    display: block;
    font-family: var(--font-headers);
    font-size: clamp(0.75rem, 1.1vw, 0.95rem);
    color: var(--primary);
    margin-bottom: 0.3vh;
  }}
  .timeline-detail {{
    font-size: clamp(0.65rem, 0.9vw, 0.8rem);
    color: var(--text-muted);
  }}
  .step-bullets {{ list-style: none; margin-top: 0.5vh; }}
  .step-bullets li {{
    font-size: clamp(0.6rem, 0.85vw, 0.75rem);
    color: var(--text-muted);
    padding: 0.2vh 0;
  }}

  /* ======== LAYOUT: Process Flow / Mermaid ======== */
  .layout-process-flow {{
    flex-direction: column;
    gap: 3vh;
    width: 100%;
    justify-content: center;
  }}

  /* Unified pipeline: phase headers + detail bullets as connected columns */
  .phase-pipeline {{
    display: flex;
    align-items: stretch;
    width: 100%;
    gap: 0;
  }}
  .phase-column {{
    flex: 1;
    display: flex;
    flex-direction: column;
    min-width: 0;
  }}
  .phase-header {{
    font-family: var(--font-headers);
    font-size: clamp(0.9rem, 1.3vw, 1.15rem);
    font-weight: 700;
    color: var(--text-light);
    background: var(--surface-dark);
    padding: 1.8vh 1.5vw;
    text-align: center;
    border-radius: var(--radius) var(--radius) 0 0;
  }}
  .phase-body {{
    flex: 1;
    background: var(--surface);
    padding: 2vh 1.5vw;
    border-radius: 0 0 var(--radius) var(--radius);
    border: 1px solid var(--border);
    border-top: 3px solid var(--accent);
  }}
  .phase-body ul {{ list-style: none; }}
  .phase-body li {{
    font-size: clamp(0.8rem, 1.1vw, 0.95rem);
    color: var(--text);
    padding: 0.5vh 0;
    line-height: 1.45;
  }}
  .phase-arrow {{
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: clamp(1.2rem, 2vw, 1.8rem);
    color: var(--accent);
    padding: 0 0.8vw;
    flex-shrink: 0;
    align-self: flex-start;
    margin-top: 2.2vh;
  }}

  /* Mermaid-only fallback (no Detail-Grid) */
  .diagram-container {{
    width: 100%;
    display: flex;
    justify-content: center;
    overflow: hidden;
    min-height: 8vh;
  }}
  .diagram-container .mermaid {{
    font-size: clamp(1rem, 1.4vw, 1.2rem);
    width: 100%;
  }}
  .diagram-container .mermaid svg {{
    max-width: 100%;
    height: auto;
    min-height: 60px;
  }}

  /* ======== LAYOUT: Closing Slide ======== */
  .layout-closing-slide {{
    flex-direction: column;
    text-align: center;
    padding: 8vh 6vw;
  }}
  .slide:has(.layout-closing-slide) {{
    background: var(--surface-dark);
  }}
  .closing-content {{ max-width: 75%; }}
  .closing-headline {{
    font-family: var(--font-headers);
    font-size: clamp(2rem, 4vw, 3.5rem);
    font-weight: 700;
    color: var(--text-light);
    line-height: 1.1;
    margin-bottom: 2vh;
  }}
  .closing-accent-line {{
    width: 80px; height: 4px;
    background: var(--accent);
    margin: 2vh auto;
    border-radius: 2px;
  }}
  .closing-takeaway {{
    font-size: clamp(1rem, 1.8vw, 1.4rem);
    color: var(--text-muted);
    font-weight: 300;
    line-height: 1.5;
  }}
  .closing-cta {{
    margin-top: 3vh;
    font-size: clamp(0.9rem, 1.4vw, 1.2rem);
    color: var(--accent);
    font-weight: 600;
  }}

  /* ======== LAYOUT: References ======== */
  .layout-references {{
    flex-direction: column;
    align-items: flex-start;
    overflow-y: auto;
  }}
  .references-content {{
    width: 100%;
    max-height: 70vh;
    overflow-y: auto;
  }}
  .references-list {{
    list-style: none;
    counter-reset: ref-counter;
  }}
  .references-list li {{
    counter-increment: ref-counter;
    padding: 0.8vh 0;
    padding-left: 2em;
    position: relative;
    font-size: clamp(0.7rem, 1vw, 0.85rem);
    color: var(--text);
    border-bottom: 1px solid var(--border);
  }}
  .references-list li::before {{
    content: "[" counter(ref-counter) "]";
    position: absolute; left: 0;
    font-weight: 700;
    color: var(--accent-dark);
    font-family: var(--font-mono);
    font-size: 0.85em;
  }}
  .references-list a {{
    color: var(--accent-dark);
    text-decoration: none;
  }}
  .references-list a:hover {{
    color: var(--accent);
    text-decoration: underline;
  }}

  /* ======== LAYOUT: Generic Fallback ======== */
  .layout-generic {{
    flex-direction: column;
    align-items: flex-start;
    gap: 1.5vh;
  }}
  .layout-generic h3 {{
    font-family: var(--font-headers);
    font-size: clamp(1rem, 1.4vw, 1.2rem);
    color: var(--primary);
  }}
  .layout-generic ul {{ list-style: disc; padding-left: 1.5em; }}
  .layout-generic li {{
    font-size: clamp(0.8rem, 1.1vw, 0.95rem);
    color: var(--text);
    padding: 0.3vh 0;
  }}

  /* ======== Navigation Controls ======== */
  .nav-controls {{
    position: fixed;
    bottom: 16px; right: 16px;
    display: flex;
    align-items: center;
    gap: 12px;
    z-index: 100;
    font-family: var(--font-body);
  }}
  .slide-counter {{
    font-size: 0.85rem;
    color: var(--text-muted);
    font-variant-numeric: tabular-nums;
    background: rgba(255,255,255,0.9);
    padding: 4px 12px;
    border-radius: 20px;
    box-shadow: var(--shadow-sm);
    backdrop-filter: blur(8px);
  }}
  .nav-btn {{
    width: 36px; height: 36px;
    border: none;
    border-radius: 50%;
    background: rgba(255,255,255,0.9);
    color: var(--text);
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: var(--shadow-sm);
    backdrop-filter: blur(8px);
    font-size: 1rem;
    transition: all 0.2s;
  }}
  .nav-btn:hover {{
    background: var(--accent);
    color: var(--surface-dark);
    transform: scale(1.1);
  }}

  /* ======== Progress Bar ======== */
  .progress-bar {{
    position: fixed;
    top: 0; left: 0;
    height: 3px;
    background: var(--accent);
    z-index: 200;
    transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }}

  /* ======== Speaker Notes Panel ======== */
  .notes-panel {{
    position: fixed;
    bottom: 0; left: 0; right: 0;
    max-height: 45vh;
    background: rgba(17, 17, 17, 0.97);
    color: var(--text-light);
    transform: translateY(100%);
    transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
    z-index: 150;
    overflow-y: auto;
    padding: 2vh 4vw 3vh;
    backdrop-filter: blur(16px);
    border-top: 2px solid var(--accent);
  }}
  .notes-panel.visible {{
    transform: translateY(0);
  }}
  .notes-close {{
    position: sticky;
    top: 0;
    float: right;
    background: rgba(255,255,255,0.1);
    border: 1px solid rgba(255,255,255,0.2);
    color: var(--text-light);
    font-size: 1.2rem;
    width: 32px;
    height: 32px;
    border-radius: 50%;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.2s;
    z-index: 10;
    margin-bottom: -32px;
  }}
  .notes-close:hover {{
    background: var(--accent);
    color: var(--primary);
    border-color: var(--accent);
  }}
  .notes-panel .notes-section {{
    font-family: var(--font-headers);
    font-size: 0.8rem;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: var(--accent);
    border-left: 3px solid var(--accent);
    padding-left: 12px;
    margin: 1.5vh 0 1vh;
  }}
  .notes-panel .notes-tagged {{
    font-size: 0.85rem;
    line-height: 1.6;
    margin: 0.5vh 0;
    padding-left: 12px;
  }}
  .notes-panel .notes-tag {{
    font-weight: 700;
    color: var(--accent-muted);
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-right: 8px;
  }}
  .notes-panel .notes-bullets {{
    list-style: none;
    padding-left: 12px;
  }}
  .notes-panel .notes-bullets li {{
    font-size: 0.82rem;
    color: rgba(255,255,255,0.8);
    padding: 0.3vh 0;
    padding-left: 1em;
    position: relative;
  }}
  .notes-panel .notes-bullets li::before {{
    content: "\\2022";
    position: absolute; left: 0;
    color: var(--accent-muted);
  }}
  .notes-panel p {{
    font-size: 0.85rem;
    line-height: 1.6;
    color: rgba(255,255,255,0.85);
    margin: 0.3vh 0;
    padding-left: 12px;
  }}
  .notes-panel a {{
    color: var(--accent);
    text-decoration: none;
  }}
  .notes-panel a:hover {{
    text-decoration: underline;
  }}

  /* ======== Slide Citation Links ======== */
  .citation sup {{
    font-size: 0.65em;
    color: var(--accent-dark);
    font-weight: 600;
  }}
  .citation:hover sup {{
    color: var(--accent);
  }}

  /* ======== Keyboard Help Overlay ======== */
  .help-overlay {{
    position: fixed;
    inset: 0;
    background: rgba(0,0,0,0.7);
    z-index: 300;
    display: none;
    align-items: center;
    justify-content: center;
    backdrop-filter: blur(4px);
  }}
  .help-overlay.visible {{ display: flex; }}
  .help-content {{
    background: var(--surface);
    border-radius: var(--radius);
    padding: 3vh 3vw;
    max-width: 500px;
    box-shadow: var(--shadow-xl);
  }}
  .help-content h3 {{
    font-family: var(--font-headers);
    margin-bottom: 1.5vh;
    color: var(--primary);
  }}
  .help-content table {{ width: 100%; border-collapse: collapse; }}
  .help-content td {{
    padding: 0.5vh 1vw;
    font-size: 0.85rem;
    border-bottom: 1px solid var(--border);
  }}
  .help-content kbd {{
    background: var(--surface2);
    padding: 2px 8px;
    border-radius: 4px;
    font-family: var(--font-mono);
    font-size: 0.8rem;
    border: 1px solid var(--border);
  }}

  /* ======== Print Styles ======== */
  @media print {{
    .slide-deck {{ position: static; overflow: visible; }}
    .slide {{
      position: static !important;
      opacity: 1 !important;
      transform: none !important;
      pointer-events: auto !important;
      page-break-after: always;
      height: auto;
      min-height: 100vh;
      display: flex !important;
    }}
    .slide-content {{ width: 100%; height: auto; }}
    .nav-controls, .progress-bar, .help-overlay, .notes-close {{ display: none !important; }}
    .notes-panel {{
      position: static !important;
      transform: none !important;
      max-height: none;
      background: #f5f5f5;
      color: #333;
      border-top: 2px solid #999;
      page-break-inside: avoid;
    }}
    .notes-panel .notes-section {{ color: #333; border-color: #999; }}
    .notes-panel .notes-tag {{ color: #555; }}
    .notes-panel .notes-bullets li {{ color: #333; }}
    .notes-panel .notes-bullets li::before {{ color: #999; }}
    .notes-panel p {{ color: #333; }}
  }}

  /* ======== Responsive Fallback ======== */
  @media (max-width: 768px) {{
    .slide-content {{ padding: 3vh 4vw; }}
    .layout-stat-card {{ grid-template-columns: 1fr; gap: 2vh; }}
    .quad-grid {{ grid-template-columns: 1fr; }}
    .layout-two-columns {{ grid-template-columns: 1fr; }}
    .col-divider {{ width: 100%; height: 1px; }}
    .options-grid {{ grid-template-columns: 1fr; }}
    .timeline-track {{ flex-direction: column; align-items: flex-start; }}
    .timeline-track::before {{ display: none; }}
  }}
"""


# ---------------------------------------------------------------------------
# JavaScript Generation
# ---------------------------------------------------------------------------

def generate_js(total_slides, has_mermaid=False):
    """Generate the JavaScript for navigation, transitions, and speaker notes."""
    mermaid_init = ""
    if has_mermaid:
        mermaid_init = """
    // Initialize Mermaid diagrams
    if (typeof mermaid !== 'undefined') {
      mermaid.initialize({
        startOnLoad: false,
        theme: 'neutral',
        fontFamily: getComputedStyle(document.documentElement).getPropertyValue('--font-body').trim() || 'sans-serif',
        flowchart: { curve: 'basis', padding: 20 },
        gantt: { barHeight: 24, fontSize: 12 }
      });
      mermaid.run();
    }
"""

    return f"""
  (function() {{
    'use strict';

    const TOTAL = {total_slides};
    let current = 0;
    let notesVisible = false;
    let helpVisible = false;

    const slides = document.querySelectorAll('.slide');
    const notesData = document.querySelectorAll('.slide-notes-data');
    const notesPanel = document.querySelector('.notes-panel');
    const notesContent = document.querySelector('.notes-content');
    const progressBar = document.querySelector('.progress-bar');
    const counter = document.querySelector('.slide-counter');
    const helpOverlay = document.querySelector('.help-overlay');

    function goTo(n) {{
      if (n < 0 || n >= TOTAL) return;
      slides[current].classList.remove('active');
      current = n;
      slides[current].classList.add('active');
      updateUI();
    }}

    function next() {{ goTo(current + 1); }}
    function prev() {{ goTo(current - 1); }}

    function updateUI() {{
      // Progress bar
      const pct = ((current + 1) / TOTAL) * 100;
      progressBar.style.width = pct + '%';
      // Counter
      counter.textContent = (current + 1) + ' / ' + TOTAL;
      // Speaker notes
      if (notesContent && notesData[current]) {{
        notesContent.innerHTML = notesData[current].innerHTML;
      }} else if (notesContent) {{
        notesContent.innerHTML = '<p style="color:rgba(255,255,255,0.4);font-style:italic;">No speaker notes for this slide.</p>';
      }}
    }}

    function toggleNotes() {{
      notesVisible = !notesVisible;
      notesPanel.classList.toggle('visible', notesVisible);
    }}

    function toggleHelp() {{
      helpVisible = !helpVisible;
      helpOverlay.classList.toggle('visible', helpVisible);
    }}

    function toggleFullscreen() {{
      if (!document.fullscreenElement) {{
        document.documentElement.requestFullscreen().catch(() => {{}});
      }} else {{
        document.exitFullscreen().catch(() => {{}});
      }}
    }}

    // Keyboard navigation
    document.addEventListener('keydown', function(e) {{
      if (helpVisible && e.key === 'Escape') {{ toggleHelp(); return; }}
      if (helpVisible) return;

      switch(e.key) {{
        case 'ArrowRight':
        case 'ArrowDown':
        case ' ':
        case 'PageDown':
          e.preventDefault(); next(); break;
        case 'ArrowLeft':
        case 'ArrowUp':
        case 'PageUp':
          e.preventDefault(); prev(); break;
        case 'Home': e.preventDefault(); goTo(0); break;
        case 'End': e.preventDefault(); goTo(TOTAL - 1); break;
        case 's': case 'S': toggleNotes(); break;
        case 'f': case 'F': toggleFullscreen(); break;
        case '?': case 'h': case 'H': toggleHelp(); break;
        case 'Escape':
          if (notesVisible) toggleNotes();
          break;
      }}
    }});

    // Click navigation (right half = next, left half = prev)
    document.querySelector('.slide-deck').addEventListener('click', function(e) {{
      // Don't navigate on link clicks, button clicks, or notes panel
      if (e.target.closest('a, button, .notes-panel, .nav-controls, .help-overlay')) return;
      const x = e.clientX / window.innerWidth;
      if (x > 0.5) next(); else prev();
    }});

    // Touch swipe support
    let touchStartX = 0;
    document.addEventListener('touchstart', function(e) {{
      touchStartX = e.touches[0].clientX;
    }}, {{ passive: true }});
    document.addEventListener('touchend', function(e) {{
      const dx = e.changedTouches[0].clientX - touchStartX;
      if (Math.abs(dx) > 50) {{
        if (dx < 0) next(); else prev();
      }}
    }}, {{ passive: true }});

    // Initialize
    slides[0].classList.add('active');
    updateUI();
    {mermaid_init}
  }})();
"""


# ---------------------------------------------------------------------------
# HTML Assembly
# ---------------------------------------------------------------------------

def assemble_html(slide_data, dv, transition="fade", aspect_ratio="16:9", language="en", tokens_css_path=None):
    """Assemble the complete HTML document.

    ``tokens_css_path`` is the optional absolute path to a Theme System v2
    ``tokens.css`` resolved by ``resolve_tokens_css`` (or None for tier-0 /
    legacy callers). When set, an ``@import url('file://...');`` line is
    injected ahead of the existing inline ``:root`` block so the manifest
    theme's CSS custom properties cascade in first; the inline DEFAULT_THEME-
    derived block then provides fallback values for any unmapped names. When
    None, the rendered HTML is byte-identical to pre-v0.16.21 output.
    """
    metadata = slide_data.get("metadata", {})
    slides = slide_data.get("slides", [])

    title = metadata.get("title", "Presentation")
    customer = metadata.get("customer", "")
    provider = metadata.get("provider", "")
    generated = metadata.get("generated", datetime.now().strftime("%Y-%m-%d"))
    theme_name = dv.get("theme_name", "cogni-work")

    # Check if any slide has a Mermaid diagram
    has_mermaid = any(
        s.get("diagram_mermaid") or
        (isinstance(s.get("fields", {}).get("Diagram"), str) and s["fields"]["Diagram"].strip())
        for s in slides
    )

    # Google Fonts import
    fonts_import = dv.get("google_fonts_import", "")

    # CDN links
    mermaid_cdn = ""
    if has_mermaid:
        mermaid_cdn = '  <script src="https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.min.js"></script>'

    # Build slide HTML
    slide_sections = []
    notes_data_blocks = []

    for slide in slides:
        num = slide.get("number", 0)
        headline = escape_html(slide.get("headline", ""))
        layout = slide.get("layout", "generic")
        notes = slide.get("speaker_notes", "")

        # Render slide content
        content_html = render_slide(slide, dv, language)
        banner_html = render_bottom_banner(slide.get("fields", {}))

        # Slide title (not shown on title-slide or closing-slide)
        title_html = ""
        if layout not in ("title-slide", "closing-slide", "references"):
            title_html = f'    <h2 class="slide-title">{headline}</h2>'

        slide_sections.append(f"""
  <section class="slide" data-slide="{num}" data-layout="{layout}">
    <div class="slide-content">
{title_html}
{content_html}
{banner_html}
    </div>
  </section>""")

        # Hidden notes data block
        notes_html = render_speaker_notes(notes) if notes else ""
        notes_data_blocks.append(
            f'  <template class="slide-notes-data">{notes_html}</template>'
        )

    total = len(slides)

    # Keyboard shortcuts table
    shortcuts = [
        ("&#8594; / &#8595; / Space", "Next slide"),
        ("&#8592; / &#8593;", "Previous slide"),
        ("Home / End", "First / Last slide"),
        ("S", "Toggle speaker notes"),
        ("F", "Toggle fullscreen"),
        ("? / H", "Show this help"),
        ("Esc", "Close notes / help"),
    ]
    shortcut_rows = "\n".join(
        f'      <tr><td><kbd>{k}</kbd></td><td>{v}</td></tr>'
        for k, v in shortcuts
    )

    css = generate_css(dv, transition, aspect_ratio)
    js = generate_js(total, has_mermaid)

    # Tier-1 tokens.css import (Theme System v2). Empty string when
    # tokens_css_path is None, which is the legacy tier-0 path — output
    # stays byte-equivalent to pre-v0.16.21 in that case.
    tokens_css_import = ""
    if tokens_css_path:
        tokens_css_import = "@import url('file://{}');".format(tokens_css_path)

    return f"""<!DOCTYPE html>
<html lang="{language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="generator" content="cogni-visual render-html-slides">
  <meta name="theme" content="{escape_html(theme_name)}">
  <title>{escape_html(title)}</title>
  <style>
  {tokens_css_import}
  {fonts_import}
  {css}
  </style>
{mermaid_cdn}
</head>
<body>

  <!-- Progress Bar -->
  <div class="progress-bar" style="width: 0%"></div>

  <!-- Slide Deck -->
  <div class="slide-deck">
{"".join(slide_sections)}
  </div>

  <!-- Hidden Speaker Notes Data -->
{"".join(notes_data_blocks)}

  <!-- Speaker Notes Panel -->
  <div class="notes-panel">
    <button class="notes-close" onclick="document.dispatchEvent(new KeyboardEvent('keydown',{{key:'s'}}))" title="Close notes (S / Esc)">&times;</button>
    <div class="notes-content"></div>
  </div>

  <!-- Navigation Controls -->
  <div class="nav-controls">
    <button class="nav-btn" onclick="document.dispatchEvent(new KeyboardEvent('keydown',{{key:'ArrowLeft'}}))" title="Previous">&#8592;</button>
    <span class="slide-counter">1 / {total}</span>
    <button class="nav-btn" onclick="document.dispatchEvent(new KeyboardEvent('keydown',{{key:'ArrowRight'}}))" title="Next">&#8594;</button>
    <button class="nav-btn" onclick="document.dispatchEvent(new KeyboardEvent('keydown',{{key:'s'}}))" title="Speaker Notes (S)">&#9776;</button>
    <button class="nav-btn" onclick="document.dispatchEvent(new KeyboardEvent('keydown',{{key:'?'}}))" title="Help (?)">?</button>
  </div>

  <!-- Keyboard Help Overlay -->
  <div class="help-overlay">
    <div class="help-content">
      <h3>Keyboard Shortcuts</h3>
      <table>
{shortcut_rows}
      </table>
      <p style="margin-top:1.5vh;font-size:0.8rem;color:var(--text-muted);">Click right half to advance, left half to go back. Swipe on touch devices.</p>
    </div>
  </div>

  <!-- Footer Metadata (hidden, for auditing) -->
  <div style="display:none" data-customer="{escape_html(customer)}" data-provider="{escape_html(provider)}" data-generated="{escape_html(generated)}" data-theme="{escape_html(theme_name)}"></div>

<script>
{js}
</script>

</body>
</html>"""


# ---------------------------------------------------------------------------
# CLI Entry Point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Generate HTML slide presentation from parsed slide data.")
    parser.add_argument("--slide-data", required=True, help="Path to slide-data.json")
    parser.add_argument("--design-variables", default="", help="Path to design-variables.json")
    parser.add_argument("--output", required=True, help="Output HTML file path")
    parser.add_argument("--transition", default="fade", choices=["fade", "slide", "none"])
    parser.add_argument("--aspect-ratio", default="16:9", choices=["16:9", "4:3"])
    parser.add_argument("--language", default="en", choices=["en", "de"])
    parser.add_argument("--theme-slug", default="",
                        help="Optional Theme System v2 theme slug. When set, "
                             "tokens.css is @imported from the resolved tiered "
                             "theme and the active theme name is taken from "
                             "the manifest. Tier-0 themes (no manifest.json) "
                             "and themes without tiers.tokens fall back "
                             "transparently to the legacy code path.")
    parser.add_argument("--themes-dir", default="",
                        help="Override the workspace themes/ directory used "
                             "for --theme-slug resolution. Default: "
                             "$COGNI_WORKSPACE_ROOT/themes or auto-discovery.")
    args = parser.parse_args()

    try:
        # Load inputs
        with open(args.slide_data) as f:
            slide_data = json.load(f)

        dv = load_design_variables(args.design_variables)

        # Theme System v2 — resolve tier-1 tokens.css if --theme-slug is set.
        # When the resolution misses (tier-0 theme, missing manifest, missing
        # tokens.css), tokens_css_path is None and assemble_html emits the
        # legacy byte-equivalent output.
        tokens_css_path = None
        if args.theme_slug:
            themes_dir = resolve_themes_dir(args.themes_dir)
            tokens_css_path = resolve_tokens_css(themes_dir, args.theme_slug)

        # Generate HTML
        html = assemble_html(
            slide_data, dv,
            transition=args.transition,
            aspect_ratio=args.aspect_ratio,
            language=args.language,
            tokens_css_path=tokens_css_path,
        )

        # Write output
        os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(html)

        # Report success
        total = len(slide_data.get("slides", []))
        size_kb = round(os.path.getsize(args.output) / 1024, 1)
        result = {
            "status": "ok",
            "path": os.path.abspath(args.output),
            "slides": total,
            "size_kb": size_kb,
            "theme": dv.get("theme_name", "unknown"),
            "theme_slug": args.theme_slug or None,
            "tokens_css_imported": bool(tokens_css_path),
            "has_mermaid": any(
                s.get("diagram_mermaid") or
                (isinstance(s.get("fields", {}).get("Diagram"), str) and s["fields"]["Diagram"].strip())
                for s in slide_data.get("slides", [])
            )
        }
        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({"error": str(e)}))
        sys.exit(1)


if __name__ == "__main__":
    main()

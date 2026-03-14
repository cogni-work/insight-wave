#!/usr/bin/env python3
"""
Export HTML Report Generator

Transforms deeper-research-3 output (research-hub.md + all entity files)
into a single self-contained HTML file with:
- Wikilinks [[entity]] converted to anchor links <a href="#entity-id">
- Theme support from user-provided theme (cogni-workplace/themes/)
- All entities included as navigable sections

Usage:
    python export_html_report.py --project /path/to/research --theme digital-x --output report.html
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Any, Optional, Tuple
import html as html_lib


# Entity directory configuration
# Based on entity-schema.json directory structure
ENTITY_DIRS = {
    'initial-questions': '00-initial-question',
    'dimensions': '01-research-dimensions',
    'questions': '02-refined-questions',
    'query-batches': '03-query-batches',
    'findings': '04-findings',
    'sources': '05-sources',
    'claims': '06-claims',
}

# Proper singular forms (rstrip('s') breaks 'query-batches' and 'synthesis')
TYPE_SINGULAR = {
    'initial-questions': 'initial-question',
    'dimensions': 'dimension',
    'questions': 'question',
    'query-batches': 'query-batch',
    'findings': 'finding',
    'sources': 'source',
    'claims': 'claim',
}

DATA_SUBDIR = 'data'

# README directory configuration
# Maps parent entity type to (directory, has_dimension_readmes)
# Based on entity-schema.json directory structure
README_DIRS = {
    'dimensions': ('01-research-dimensions', False),
    'questions': ('02-refined-questions', False),
    'query-batches': ('03-query-batches', False),
    'sources': ('05-sources', False),
    'claims': ('06-claims', False),
}

# Dimension color palette — algorithmically generated from CSS variables
# The first 8 colors map to --color-dim-1 through --color-dim-8 in report-layout.css.
# Projects with more than 8 dimensions cycle through the palette.
DIMENSION_PALETTE = [
    '#00b8d4',  # dim-1: cyan
    '#5b2c6f',  # dim-2: purple
    '#1e8449',  # dim-3: green
    '#ff6b4a',  # dim-4: coral
    '#3b82f6',  # dim-5: blue
    '#8b5cf6',  # dim-6: violet
    '#ec4899',  # dim-7: pink
    '#f59e0b',  # dim-8: amber
]
GENERAL_COLOR = '#6b7280'


def get_dimension_color(dimension_slug: str, dimension_index: int = -1) -> str:
    """Get color for a dimension by index, cycling through the palette.

    Args:
        dimension_slug: Dimension slug (used only for _general fallback)
        dimension_index: 0-based index of the dimension in the project

    Returns:
        Hex color string
    """
    if dimension_slug == '_general' or dimension_index < 0:
        return GENERAL_COLOR
    return DIMENSION_PALETTE[dimension_index % len(DIMENSION_PALETTE)]

# Centralized UI translations for EN/DE i18n
UI_TRANSLATIONS = {
    'en': {
        # HTML lang attribute
        'html_lang': 'en',
        # Nav tabs
        'tab_overview': 'Overview',
        'tab_dimensions': 'Dimensions',
        'tab_findings': 'Findings',
        'tab_claims': 'Claims',
        'tab_appendix': 'Appendix',
        'tab_questions': 'Questions',
        'tab_methodology': 'Methodology',
        'tab_sources': 'Sources',
        # Overview cards
        'card_findings': 'Findings',
        'card_findings_desc': 'Research evidence in the panel',
        'card_claims': 'Claims',
        'card_claims_desc': 'Verified assertions',
        # Right panel detail tabs
        'detail_findings': 'Findings',
        'detail_claims': 'Claims',
        'detail_sources': 'Sources',
        'detail_questions': 'Questions',
        'detail_methodology': 'Methodology',
        # Graph controls
        'graph_all_types': 'All Types',
        'graph_claim': 'Claim',
        'graph_finding': 'Finding',
        'graph_source': 'Source',
        'graph_dimension': 'Dimension',
        'graph_question': 'Question',
        'graph_query_batch': 'Query Batch',
        'graph_initial_question': 'Initial Question',
        'graph_search_placeholder': 'Search entities...',
        # Entity type labels (sections/TOC)
        'type_finding': 'Findings',
        'type_claim': 'Claims',
        'type_source': 'Sources',
        'type_dimension': 'Research Dimensions',
        'type_question': 'Research Questions',
        'type_initial_question': 'Initial Question',
        # Section nav (left sidebar)
        'dimension_nav_title': 'Dimensions',
        'nav_title_overview': 'Contents',
        'aria_section_nav': 'Section navigation',
        # TOC labels
        'toc_contents': 'Contents',
        'toc_overview': 'Overview',
        'toc_methodology_section': 'Research Metadata and Methodology',
        # Title suffix
        'title_suffix': 'Research Report',
        # Preview popup
        'preview_cta': 'Click to jump to section',
        # Aria labels
        'aria_toggle_menu': 'Toggle menu',
        'aria_research_panel': 'Research Panel',
        'aria_back_to_top': 'Back to top',
        'aria_close_panel': 'Close panel',
        'aria_filter_type': 'Filter by entity type',
        'aria_search': 'Search entities',
        'aria_dim_nav': 'Dimension navigation',
        'aria_report_nav': 'Report navigation',
        'aria_back_to_landing': 'Back to landing page',
        'entity_detail_placeholder': 'Pick an entity in the graph above to see details',
        'graph_empty_state': 'Scroll to an entity to see its connections',
        # Loading overlay
        'loading_report': 'Loading report\u2026',
        # Misc UI labels
        'words': 'words',
        'nav_other': 'Other',
        # JS-side labels (embedded for report.js consumption)
        'js_type_finding': 'Finding',
        'js_type_claim': 'Claim',
        'js_type_source': 'Source',
        'js_type_dimension': 'Dimension',
        'js_type_question': 'Question',
        'js_loading_entities': 'Loading {0} entities\u2026',
    },
    'de': {
        'html_lang': 'de',
        'tab_overview': 'Überblick',
        'tab_dimensions': 'Dimensionen',
        'tab_findings': 'Erkenntnisse',
        'tab_claims': 'Aussagen',
        'tab_appendix': 'Anhang',
        'tab_questions': 'Fragen',
        'tab_methodology': 'Methodik',
        'tab_sources': 'Quellen',
        'card_findings': 'Erkenntnisse',
        'card_findings_desc': 'Forschungsergebnisse im Panel',
        'card_claims': 'Aussagen',
        'card_claims_desc': 'Verifizierte Behauptungen',
        'detail_findings': 'Erkenntnisse',
        'detail_claims': 'Aussagen',
        'detail_sources': 'Quellen',
        'detail_questions': 'Fragen',
        'detail_methodology': 'Methodik',
        'graph_all_types': 'Alle Typen',
        'graph_claim': 'Aussage',
        'graph_finding': 'Erkenntnis',
        'graph_source': 'Quelle',
        'graph_dimension': 'Dimension',
        'graph_question': 'Frage',
        'graph_query_batch': 'Suchauftrag',
        'graph_initial_question': 'Ausgangsfrage',
        'graph_search_placeholder': 'Entitäten suchen...',
        'type_finding': 'Erkenntnisse',
        'type_claim': 'Aussagen',
        'type_source': 'Quellen',
        'type_dimension': 'Forschungsdimensionen',
        'type_question': 'Forschungsfragen',
        'type_initial_question': 'Ausgangsfrage',
        'dimension_nav_title': 'Dimensionen',
        'nav_title_overview': 'Inhalt',
        'aria_section_nav': 'Abschnittsnavigation',
        'toc_contents': 'Inhalt',
        'toc_overview': 'Überblick',
        'toc_methodology_section': 'Forschungsmetadaten und Methodik',
        'title_suffix': 'Forschungsbericht',
        'preview_cta': 'Klicken zum Navigieren',
        'aria_toggle_menu': 'Menü umschalten',
        'aria_research_panel': 'Forschungspanel',
        'aria_back_to_top': 'Nach oben',
        'aria_close_panel': 'Panel schließen',
        'aria_filter_type': 'Nach Entitätstyp filtern',
        'aria_search': 'Entitäten suchen',
        'aria_dim_nav': 'Dimensionsnavigation',
        'aria_report_nav': 'Berichtsnavigation',
        'aria_back_to_landing': 'Zurück zur Startseite',
        'entity_detail_placeholder': 'Entität im Graphen oben anklicken für Details',
        'graph_empty_state': 'Zu einer Entität scrollen, um Verbindungen zu sehen',
        'loading_report': 'Bericht wird geladen\u2026',
        'words': 'Wörter',
        'nav_other': 'Sonstige',
        'js_type_finding': 'Erkenntnis',
        'js_type_claim': 'Aussage',
        'js_type_source': 'Quelle',
        'js_type_dimension': 'Dimension',
        'js_type_question': 'Frage',
        'js_loading_entities': '{0} Entit\u00e4ten werden geladen\u2026',
    }
}


def get_ui_translations(lang: str) -> dict:
    """Get UI translations for a language code, with English fallback."""
    return UI_TRANSLATIONS.get(lang, UI_TRANSLATIONS['en'])


def parse_frontmatter(content: str) -> Tuple[Dict[str, Any], str]:
    """Parse YAML frontmatter from markdown content.

    Args:
        content: Full markdown file content

    Returns:
        Tuple of (metadata dict, body content)
    """
    if not content.startswith('---'):
        return {}, content

    parts = content.split('---', 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_text = parts[1]
    body = parts[2].strip()

    metadata = {}
    current_key = None
    list_values = []

    for line in frontmatter_text.split('\n'):
        line_stripped = line.strip()
        if not line_stripped:
            continue

        # Check for list continuation (indented with -)
        if line.startswith('  - ') or line.startswith('    - '):
            if current_key:
                value = line_stripped.lstrip('- ').strip()
                # Remove quotes
                if (value.startswith('"') and value.endswith('"')) or \
                   (value.startswith("'") and value.endswith("'")):
                    value = value[1:-1]
                list_values.append(value)
            continue

        # Save previous list if exists
        if current_key and list_values:
            metadata[current_key] = list_values
            list_values = []
            current_key = None

        if ': ' not in line_stripped:
            continue

        idx = line_stripped.index(': ')
        key = line_stripped[:idx].strip()
        value = line_stripped[idx+2:].strip()

        # Handle inline lists [a, b, c]
        if value.startswith('[') and value.endswith(']'):
            list_content = value[1:-1]
            if list_content:
                value = [v.strip().strip('"').strip("'") for v in list_content.split(',') if v.strip()]
            else:
                value = []
            metadata[key] = value
            continue

        # Handle empty value (list follows)
        if not value:
            current_key = key
            list_values = []
            continue

        # Clean quotes
        if (value.startswith('"') and value.endswith('"')) or \
           (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]

        metadata[key] = value

    # Don't forget trailing list
    if current_key and list_values:
        metadata[current_key] = list_values

    return metadata, body


def simple_markdown_to_html(text: str) -> str:
    """Convert markdown to HTML.

    Supports:
    - Headers (H1-H6)
    - Paragraphs
    - Unordered lists (- or *)
    - Ordered lists (1. 2. 3.)
    - Tables
    - Bold, italic, code
    - Links
    - Code blocks
    """
    if not text or not text.strip():
        return ''

    lines = text.split('\n')
    html_parts = []
    in_list = False
    list_type = None
    in_code_block = False
    code_block_content = []
    code_block_lang = None

    i = 0
    while i < len(lines):
        line = lines[i]

        # Code blocks
        if line.strip().startswith('```'):
            if in_code_block:
                if code_block_lang == 'mermaid':
                    # Mermaid blocks: use class for client-side rendering, no escaping
                    html_parts.append(f'<pre class="mermaid">{chr(10).join(code_block_content)}</pre>')
                else:
                    html_parts.append(f'<pre><code>{html_lib.escape(chr(10).join(code_block_content))}</code></pre>')
                code_block_content = []
                code_block_lang = None
                in_code_block = False
            else:
                in_code_block = True
                # Extract language identifier after ```
                lang_match = re.match(r'^```(\w+)?', line.strip())
                code_block_lang = lang_match.group(1) if lang_match else None
            i += 1
            continue

        if in_code_block:
            code_block_content.append(line)
            i += 1
            continue

        stripped = line.strip()

        # Empty line - close lists
        if not stripped:
            if in_list:
                html_parts.append(f'</{list_type}>')
                in_list = False
                list_type = None
            i += 1
            continue

        # Horizontal rule (---, ***, ___)
        if re.match(r'^[-*_]{3,}$', stripped):
            if in_list:
                html_parts.append(f'</{list_type}>')
                in_list = False
                list_type = None
            html_parts.append('<hr>')
            i += 1
            continue

        # Headers
        if stripped.startswith('#'):
            if in_list:
                html_parts.append(f'</{list_type}>')
                in_list = False
                list_type = None

            level = len(stripped) - len(stripped.lstrip('#'))
            level = min(level, 6)
            header_text = stripped[level:].strip()
            header_id = slugify(header_text)
            header_html = format_inline_markdown(header_text)
            html_parts.append(f'<h{level} id="{header_id}">{header_html}</h{level}>')
            i += 1
            continue

        # Table detection
        if stripped.startswith('|') and i + 1 < len(lines):
            next_line = lines[i + 1].strip() if i + 1 < len(lines) else ''
            if re.match(r'^[\|\-:\s]+$', next_line):
                if in_list:
                    html_parts.append(f'</{list_type}>')
                    in_list = False
                    list_type = None

                table_lines = []
                while i < len(lines) and lines[i].strip().startswith('|'):
                    table_lines.append(lines[i].strip())
                    i += 1
                html_parts.append(parse_markdown_table('\n'.join(table_lines)))
                continue

        # Unordered list
        if stripped.startswith('- ') or stripped.startswith('* '):
            if not in_list or list_type != 'ul':
                if in_list:
                    html_parts.append(f'</{list_type}>')
                html_parts.append('<ul>')
                in_list = True
                list_type = 'ul'

            item_text = stripped[2:].strip()
            item_html = format_inline_markdown(item_text)
            html_parts.append(f'<li>{item_html}</li>')
            i += 1
            continue

        # Ordered list
        if re.match(r'^\d+[.\)]\s+', stripped):
            if not in_list or list_type != 'ol':
                if in_list:
                    html_parts.append(f'</{list_type}>')
                html_parts.append('<ol>')
                in_list = True
                list_type = 'ol'

            item_text = re.sub(r'^\d+[.\)]\s+', '', stripped)
            item_html = format_inline_markdown(item_text)
            html_parts.append(f'<li>{item_html}</li>')
            i += 1
            continue

        # Regular paragraph
        if in_list:
            html_parts.append(f'</{list_type}>')
            in_list = False
            list_type = None

        # Pass through raw HTML blocks (like embedded SVGs)
        if stripped.startswith('<div') or stripped.startswith('<svg'):
            # Find the closing tag and collect all lines
            html_block_lines = [line]  # Keep original indentation
            i += 1
            # For self-contained single-line divs, no need to search for closing tag
            if '</div>' in stripped or '</svg>' in stripped:
                html_parts.append(stripped)
                continue
            # Multi-line HTML block - find closing tag
            while i < len(lines):
                html_block_lines.append(lines[i])
                if '</div>' in lines[i] or '</svg>' in lines[i]:
                    i += 1
                    break
                i += 1
            html_parts.append('\n'.join(html_block_lines))
            continue

        # Collect paragraph lines
        para_lines = [stripped]
        i += 1
        while i < len(lines):
            next_stripped = lines[i].strip()
            if not next_stripped or next_stripped.startswith('#') or \
               next_stripped.startswith('- ') or next_stripped.startswith('* ') or \
               re.match(r'^\d+[.\)]\s+', next_stripped) or next_stripped.startswith('|') or \
               next_stripped.startswith('```') or next_stripped.startswith('<div') or \
               re.match(r'^[-*_]{3,}$', next_stripped):
                break
            para_lines.append(next_stripped)
            i += 1

        para_text = ' '.join(para_lines)
        para_html = format_inline_markdown(para_text)
        html_parts.append(f'<p>{para_html}</p>')

    # Close any remaining list
    if in_list:
        html_parts.append(f'</{list_type}>')

    return '\n'.join(html_parts)


def format_inline_markdown(text: str) -> str:
    """Format inline markdown: bold, italic, code, links, and bare URLs."""
    # Links [text](url) - must be before bare URL detection
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
    # Bare URLs (not already in href or markdown link)
    # Match http/https URLs not preceded by href=" or ](
    text = re.sub(
        r'(?<!href=")(?<!\]\()(?<!["\'>])(https?://[^\s<>\"\'\)]+)',
        r'<a href="\1" target="_blank" rel="noopener">\1</a>',
        text
    )
    # Bold
    text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
    # Italic
    text = re.sub(r'\*([^*]+)\*', r'<em>\1</em>', text)
    # Code
    text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
    return text


def parse_markdown_table(text: str) -> str:
    """Convert markdown table to HTML table.

    Preserves escaped pipes in wikilinks: [[path\\|Display]] maintains
    the backslash to ensure proper rendering in Obsidian. The \\| sequence
    is wikilink syntax, not a table column separator, and must not be
    converted to plain pipe in cell content.

    Args:
        text: Markdown table text

    Returns:
        HTML table string
    """
    lines = [line.strip() for line in text.strip().split('\n') if line.strip()]
    if len(lines) < 2:
        return f'<p>{format_inline_markdown(text)}</p>'

    html = ['<table class="report-table">']
    header_done = False

    for line in lines:
        # Skip separator row
        if re.match(r'^[\|\-:\s]+$', line):
            continue

        # Split on unescaped pipes, preserving \| in wikilinks
        cells = split_table_cells(line)

        if not header_done:
            html.append('<thead><tr>')
            for cell in cells:
                cell_content = format_inline_markdown(cell)
                html.append(f'<th>{cell_content}</th>')
            html.append('</tr></thead>')
            html.append('<tbody>')
            header_done = True
        else:
            html.append('<tr>')
            for cell in cells:
                cell_content = format_inline_markdown(cell)
                html.append(f'<td>{cell_content}</td>')
            html.append('</tr>')

    html.append('</tbody></table>')
    return '\n'.join(html)


def strip_trend_landscape_table(text: str) -> str:
    """Remove trend landscape markdown table, keeping only the kanban-board placeholder.

    The interactive kanban board replaces the static table, so the table is redundant.
    This function strips the pattern:
      - Introduction paragraph (e.g., "Die folgende Tabelle zeigt...")
      - Markdown table with dimension/horizon columns
      - Legend line (e.g., "Legende: **M** = Megatrend...")
      - Preserves the <!-- kanban-board --> placeholder

    Args:
        text: Markdown content with potential trend landscape table

    Returns:
        Markdown with the table removed, kanban-board placeholder preserved
    """
    # Pattern matches:
    # 1. Introduction line ending with ":"
    # 2. Empty line
    # 3. Markdown table rows (| ... |)
    # 4. Optional empty line
    # 5. Legend line with "Legend:" or "Legende:"
    # 6. Empty line(s)
    # 7. <!-- kanban-board --> placeholder
    pattern = r'[^\n]*(?:Tabelle|table)[^\n]*:\s*\n\n(?:\|[^\n]+\|\n)+\n?[^\n]*(?:Legend|Legende)[^\n]*\n\n?(<!-- kanban-board -->)'

    # Keep only the kanban-board placeholder
    return re.sub(pattern, r'\1', text, flags=re.IGNORECASE)


def strip_stats_grid_from_body(text: str) -> str:
    """Remove the inline HTML stats grid from insight-summary body.

    The stats grid is rendered as styled cards by generate_overview_cards(),
    so the inline HTML grid would be a duplicate if left in the body HTML.

    Args:
        text: Markdown body content with potential inline HTML stats grid

    Returns:
        Markdown with the stats grid removed
    """
    # Match from <div class="stats-grid" ...> to the outermost </div>
    # which sits at column 0 (no indentation). Inner </div> tags are indented.
    pattern = r'\s*<div class="stats-grid"[^>]*>.*?^</div>'
    return re.sub(pattern, '', text, flags=re.DOTALL | re.MULTILINE)


def normalize_double_bracket_wikilinks(text: str) -> str:
    """Normalize malformed double-bracket wikilinks to standard format.

    Fixes LLM-generated wikilinks that wrap paths in extra brackets:
    - [[[[path/entity]]\|Display]] -> [[path/entity\|Display]]
    - [[[[path/entity]]]]          -> [[path/entity]]
    """
    # Pattern 1: [[[[path]]\\|Display]] -> [[path\\|Display]]
    text = re.sub(
        r'\[\[\[\[([^\]]+)\]\]\s*\\?\|([^\]]+)\]\]',
        r'[[\1\\|\2]]',
        text
    )
    # Pattern 2: [[[[path]]]] -> [[path]]
    text = re.sub(
        r'\[\[\[\[([^\]]+)\]\]\]\]',
        r'[[\1]]',
        text
    )
    return text


def strip_megatrends_from_table(text: str) -> str:
    """Remove megatrend entries from the dimension x horizon table, keeping only trends.

    Processes the markdown table in the trends README body:
    - Removes **M:** [[path|Title]] entries (with surrounding <br> separators)
    - Strips the **T:** prefix from remaining trend entries (no longer needed)
    - Cleans up leftover <br> artifacts at cell boundaries
    - Updates intro text: "Trends und Megatrends" / "Trends and Megatrends" → "Trends"
    - Simplifies legend line (megatrend legend no longer relevant)

    Args:
        text: Markdown content containing the dimension x horizon table

    Returns:
        Markdown with megatrend entries removed from table cells
    """
    # 1. Remove **M:** entries with their wikilinks and surrounding <br> separators
    #    Pattern: optional leading <br>, **M:** [[...]], optional trailing <br>
    text = re.sub(
        r'(?:<br>\s*)?'              # optional leading <br>
        r'\*\*M:\*\*\s*'            # **M:** prefix
        r'\[\[[^\]]+\]\]'           # wikilink [[...]]
        r'(?:\s*<br>)?',            # optional trailing <br>
        '',
        text
    )

    # 2. Strip **T:** prefix from remaining trend entries (no longer needed for disambiguation)
    text = re.sub(r'\*\*T:\*\*\s*', '', text)

    # 3. Clean up <br> artifacts at cell boundaries (leading/trailing <br> in cells)
    #    Remove <br> immediately after pipe-space or before space-pipe
    text = re.sub(r'(\|\s*)<br>\s*', r'\1', text)
    text = re.sub(r'\s*<br>\s*(\|)', r' \1', text)
    # Collapse multiple <br> into single
    text = re.sub(r'(<br>\s*){2,}', '<br>', text)

    # 4. Update intro text: remove "und Megatrends" / "and Megatrends"
    text = re.sub(r'Trends\s+und\s+Megatrends', 'Trends', text)
    text = re.sub(r'Trends\s+and\s+Megatrends', 'Trends', text)

    # 5. Remove megatrend legend entries
    #    Remove lines like "Legende: **M** = Megatrend, **T** = Trend" or simplify
    text = re.sub(
        r'[^\n]*(?:Legende|Legend)[^\n]*\*\*M\*\*\s*=\s*Megatrend[^\n]*\n?',
        '',
        text,
        flags=re.IGNORECASE
    )

    return text


def strip_megatrend_readme_extras(text: str) -> str:
    """Remove entity index table and provenance chain from megatrend README body.

    Keeps the narrative intro and the mermaid diagram section. Removes all
    subsequent ## sections (Entity Index, Provenance Chain, etc.).

    Args:
        text: Markdown content of a megatrend README body

    Returns:
        Markdown with only narrative intro and mermaid diagram section
    """
    # Split into sections by ## headings
    sections = re.split(r'(?=^## )', text, flags=re.MULTILINE)

    kept = []
    found_mermaid = False
    for section in sections:
        if not section.strip():
            continue
        # Always keep the intro (no ## heading)
        if not section.startswith('## '):
            kept.append(section)
            continue
        # Keep the section that contains the mermaid code block
        if '```mermaid' in section or '``` mermaid' in section:
            kept.append(section)
            found_mermaid = True
            continue
        # Once we've passed the mermaid section, drop everything else
        if found_mermaid:
            break
        # Keep sections before the mermaid section (narrative sections)
        kept.append(section)

    return '\n'.join(s.rstrip() for s in kept).strip() + '\n'


def strip_concept_readme_extras(text: str) -> str:
    """Remove entity index table and provenance chain from concept README body.

    Keeps the narrative intro and the mermaid diagram section. Removes all
    subsequent ## sections (Entity Index, Provenance Chain, etc.).

    Mirrors strip_megatrend_readme_extras() logic.

    Args:
        text: Markdown content of a concept README body

    Returns:
        Markdown with only narrative intro and mermaid diagram section
    """
    sections = re.split(r'(?=^## )', text, flags=re.MULTILINE)

    kept = []
    found_mermaid = False
    for section in sections:
        if not section.strip():
            continue
        # Always keep the intro (no ## heading)
        if not section.startswith('## '):
            kept.append(section)
            continue
        # Keep the section that contains the mermaid code block
        if '```mermaid' in section or '``` mermaid' in section:
            kept.append(section)
            found_mermaid = True
            continue
        # Once we've passed the mermaid section, drop everything else
        if found_mermaid:
            break
        # Keep sections before the mermaid section (narrative sections)
        kept.append(section)

    return '\n'.join(s.rstrip() for s in kept).strip() + '\n'


def split_table_cells(row: str) -> List[str]:
    """Split table row on unescaped pipes, preserving \\| in wikilinks.

    Handles edge case where wikilinks in table cells use escaped pipes
    for display text: [[path/entity\\|Display Text]].

    The backslash-pipe (\\|) is part of wikilink syntax and must be
    preserved to avoid breaking markdown rendering in Obsidian.

    Args:
        row: Table row string with potential escaped pipes

    Returns:
        List of cell contents with escaped pipes preserved

    Example:
        >>> split_table_cells('| [[path\\|Title]] | Value |')
        ['[[path\\|Title]]', 'Value']
    """
    # Use null byte as marker (guaranteed not in markdown)
    escaped_marker = '\x00ESCAPED_PIPE\x00'

    # Replace escaped pipes with marker
    temp = row.replace('\\|', escaped_marker)

    # Split on unescaped pipes (now the only ones remaining)
    cells = [c.strip() for c in temp.strip('|').split('|')]

    # Restore escaped pipes in cell content
    cells = [c.replace(escaped_marker, '\\|') for c in cells]

    return cells


def slugify(text: str) -> str:
    """Convert text to URL-safe slug."""
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_]+', '-', text)
    text = re.sub(r'-+', '-', text)
    return text.strip('-')


def extract_wikilinks(content: str) -> List[Dict[str, str]]:
    """Find all [[entity]] references in content.

    Returns:
        List of dicts with 'raw', 'entity_id', and 'display_text' keys
    """
    wikilinks = []

    # Pattern: [[path/entity|Display]] or [[path/entity\|Display]] (escaped for tables)
    pattern = r'\[\[([^\]\|\\]+)(?:\\?\|([^\]]+))?\]\]'

    for match in re.finditer(pattern, content):
        raw = match.group(0)
        path = match.group(1)
        display = match.group(2)

        # Handle escaped pipe in markdown tables: path ends with backslash
        # e.g., [[path\|Display]] in tables uses \| to avoid column split
        if path.endswith('\\'):
            path = path[:-1]

        # Extract entity ID from path
        # e.g., "04-findings/data/finding-abc" -> "finding-abc"
        entity_id = path.split('/')[-1] if '/' in path else path

        wikilinks.append({
            'raw': raw,
            'entity_id': entity_id,
            'display_text': display if display else entity_id
        })

    return wikilinks


def strip_wikilinks(text: str) -> str:
    """Remove wikilink syntax, keeping display text.

    Converts [[path/entity|Display]] to Display
    Converts [[entity-id]] to entity-id

    Args:
        text: Text that may contain wikilinks

    Returns:
        Text with wikilinks replaced by their display text
    """
    # Pattern: [[path/entity|Display]] or [[path/entity\|Display]] (escaped for tables)
    pattern = r'\[\[([^\]\|\\]+)(?:\\?\|([^\]]+))?\]\]'

    def replace_wikilink(match):
        path = match.group(1)
        display = match.group(2)
        if display:
            return display
        # Extract entity ID from path for display
        return path.split('/')[-1] if '/' in path else path

    return re.sub(pattern, replace_wikilink, text)


def extract_first_paragraph(text: str, max_chars: int = 200) -> str:
    """Extract first paragraph from markdown text, skipping headers.

    Args:
        text: Markdown text content
        max_chars: Maximum characters to return

    Returns:
        First paragraph text, truncated if needed
    """
    if not text:
        return ''

    lines = text.strip().split('\n')
    para_lines = []

    for line in lines:
        stripped = line.strip()
        if not stripped:
            if para_lines:
                break
            continue
        if stripped.startswith('#'):
            continue
        if stripped.startswith('>'):
            continue
        para_lines.append(stripped)

    para = ' '.join(para_lines)
    # Strip wikilinks for cleaner preview text
    para = strip_wikilinks(para)
    if len(para) > max_chars:
        # Truncate at word boundary
        truncated = para[:max_chars].rsplit(' ', 1)[0]
        return truncated + '...'
    return para


def extract_key_findings(body: str, max_items: int = 3) -> List[str]:
    """Extract bullet points from Key Findings/Trends section.

    Args:
        body: Markdown body content
        max_items: Maximum number of findings to extract

    Returns:
        List of finding strings
    """
    findings = []
    in_key_section = False

    for line in body.split('\n'):
        stripped = line.strip()

        # Look for Key Findings, Key Trends, or similar header
        if stripped.startswith('#') and ('Key' in stripped or 'Trend' in stripped or 'Finding' in stripped):
            in_key_section = True
            continue

        # Exit section on next header
        if stripped.startswith('#') and in_key_section:
            break

        # Extract bullet points
        if in_key_section and (stripped.startswith('- ') or stripped.startswith('* ')):
            finding = stripped[2:].strip()
            # Strip wikilinks for cleaner preview text
            finding = strip_wikilinks(finding)
            if len(finding) > 80:
                finding = finding[:80].rsplit(' ', 1)[0] + '...'
            findings.append(finding)
            if len(findings) >= max_items:
                break

    return findings


def extract_entity_id_from_wikilink(wikilink: str) -> Optional[str]:
    """Extract entity ID from wikilink like [[project/path/entity-id]] or [[entity-id]].

    Args:
        wikilink: Wikilink string, e.g. "[[project/11-trends/data/portfolio-xyz]]"

    Returns:
        Entity ID (last path component) or None if not parseable
    """
    match = re.search(r'\[\[(?:[^/\]]+/)*([^\]]+)\]\]', wikilink)
    return match.group(1) if match else None


def resolve_portfolio_refs(trend_entity: Dict, all_entities: Dict[str, Dict]) -> List[Dict]:
    """Resolve portfolio_refs wikilinks to portfolio metadata.

    Args:
        trend_entity: Trend entity with metadata containing portfolio_refs
        all_entities: All loaded entities for lookup

    Returns:
        List of portfolio info dicts with id, name, type, maturity, resolvable flag
    """
    portfolio_refs = trend_entity.get('metadata', {}).get('portfolio_refs', [])
    resolved = []

    for ref in portfolio_refs:
        # Extract portfolio ID from wikilink
        portfolio_id = extract_entity_id_from_wikilink(ref)

        if portfolio_id and portfolio_id in all_entities:
            portfolio = all_entities[portfolio_id]
            meta = portfolio.get('metadata', {})
            resolved.append({
                'id': portfolio_id,
                'name': meta.get('portfolio_name', meta.get('dc:title', portfolio_id)),
                'type': meta.get('portfolio_type', ''),
                'maturity': meta.get('maturity', ''),
                'resolvable': True
            })
        else:
            # Unresolvable cross-project reference - include placeholder
            resolved.append({
                'id': portfolio_id or ref,
                'name': portfolio_id or ref,
                'type': '',
                'maturity': '',
                'resolvable': False
            })

    return resolved


def generate_portfolio_section(portfolios: List[Dict], all_entities: Dict) -> str:
    """Generate HTML for portfolio references section.

    Args:
        portfolios: List of resolved portfolio dicts
        all_entities: All entities for generating links

    Returns:
        HTML string for portfolio section
    """
    if not portfolios:
        return ''

    html_parts = ['<div class="portfolio-refs">', '<h4>Related Portfolios</h4>', '<ul>']

    for p in portfolios:
        name = html_lib.escape(p['name'])
        ptype = p.get('type', '')
        maturity = p.get('maturity', '')

        if p.get('resolvable') and p['id'] in all_entities:
            html_parts.append(f'<li><a href="#{p["id"]}" class="wikilink">{name}</a>')
        else:
            html_parts.append(f'<li><span class="external-ref">{name}</span>')

        if ptype or maturity:
            meta_parts = []
            if ptype:
                meta_parts.append(ptype)
            if maturity:
                meta_parts.append(maturity)
            html_parts.append(f' <span class="portfolio-meta">({", ".join(meta_parts)})</span>')

        html_parts.append('</li>')

    html_parts.extend(['</ul>', '</div>'])
    return '\n'.join(html_parts)


def parse_horizon_mapping_from_table(report_body: str) -> Dict[str, str]:
    """Parse Trend Landscape table to extract entity-to-horizon mappings.

    The table in research-hub.md contains the authoritative mapping of
    trends and megatrends to planning horizons (Act/Plan/Observe).

    Table format:
    | Dimension | Act (0-6 months) | Plan (6-18 months) | Observe (18+ months) |
    |-----------|------------------|-------------------|----------------------|
    | **Name** | **M:** [[path/megatrend-x\\|Title]]<br>**T:** [[path/trend-y\\|Title]] | ... |

    Args:
        report_body: The markdown content of research-hub.md (after frontmatter)

    Returns:
        Dict mapping entity_id to horizon ('act', 'plan', 'observe')
        e.g., {'megatrend-x': 'act', 'trend-y': 'act', 'trend-z': 'plan'}
    """
    horizon_mapping = {}

    # Find table with Act/Plan/Observe headers
    table_pattern = r'(\|[^\n]*(?:Act|Plan|Observe)[^\n]*\|\n\|[\-:|\s]+\|\n(?:\|[^\n]+\|\n?)+)'
    table_match = re.search(table_pattern, report_body, re.IGNORECASE)
    if not table_match:
        return horizon_mapping

    lines = [line.strip() for line in table_match.group(1).split('\n') if line.strip()]
    if len(lines) < 3:
        return horizon_mapping

    # Use module-level split_table_cells() helper
    # Parse header to find horizon column indices
    header_cells = split_table_cells(lines[0])
    horizon_columns = {}
    for idx, cell in enumerate(header_cells):
        cell_lower = cell.lower()
        if 'act' in cell_lower:
            horizon_columns['act'] = idx
        elif 'plan' in cell_lower:
            horizon_columns['plan'] = idx
        elif 'observe' in cell_lower:
            horizon_columns['observe'] = idx

    # Parse data rows, extract wikilinks
    # Pattern handles escaped pipe in wikilinks: [[path/entity\|Title]]
    wikilink_pattern = r'\[\[([^\]\|\\]+)(?:\\?\|[^\]]+)?\]\]'
    for line in lines[2:]:
        if not line.startswith('|'):
            continue
        cells = split_table_cells(line)

        for horizon, col_idx in horizon_columns.items():
            if col_idx >= len(cells):
                continue
            for match in re.finditer(wikilink_pattern, cells[col_idx]):
                entity_id = match.group(1).split('/')[-1]
                horizon_mapping[entity_id] = horizon

    # Log distribution for debugging
    if horizon_mapping:
        act_count = sum(1 for h in horizon_mapping.values() if h == 'act')
        plan_count = sum(1 for h in horizon_mapping.values() if h == 'plan')
        observe_count = sum(1 for h in horizon_mapping.values() if h == 'observe')
        print(f"    Horizon distribution: act={act_count}, plan={plan_count}, observe={observe_count}")

    return horizon_mapping


def normalize_dimension_name(name: str) -> str:
    """Convert dimension display name to slug.

    Examples:
        'Competitive Positioning' -> 'competitive-positioning'
        'Digitale Wertetreiber' -> 'digitale-wertetreiber'
        'General' / 'Allgemein' -> '_general'

    Args:
        name: Dimension name from table cell (may include ** bold markers)

    Returns:
        Normalized dimension slug
    """
    # Clean up: remove bold markers, strip whitespace
    name = name.strip().replace('**', '').strip()

    # Handle empty name
    if not name:
        return '_general'

    # Handle special "General" row variants
    name_lower = name.lower()
    if name_lower in ('general', 'allgemein', 'sonstiges'):
        return '_general'

    # Convert to slug: lowercase, spaces/underscores to hyphens
    slug = re.sub(r'[\s_]+', '-', name_lower)
    # Remove any non-alphanumeric characters except hyphens
    slug = re.sub(r'[^a-z0-9\-]', '', slug)
    # Collapse multiple hyphens
    slug = re.sub(r'-+', '-', slug).strip('-')

    return slug or '_general'


def parse_cell_entries(cell_content: str) -> List[Dict]:
    """Parse megatrend/trend entries from a table cell.

    Handles formats:
    - **M:** [[path/megatrend-x\\|Title]] for megatrends
    - **T:** [[path/trend-y\\|Title]] for trends
    - Multiple entries separated by <br>

    Args:
        cell_content: Raw cell content from markdown table

    Returns:
        List of dicts with 'id', 'type', 'title', 'path' for each entry
    """
    entries = []

    # Pattern: **M:** or **T:** prefix followed by wikilink with escaped pipe
    # The wikilink format is [[path/entity-id\|Display Title]]
    entry_pattern = r'\*\*([MT]):\*\*\s*\[\[([^\]\|\\]+)(?:\\?\|([^\]]+))?\]\]'

    for match in re.finditer(entry_pattern, cell_content):
        type_marker = match.group(1)  # 'M' or 'T'
        path = match.group(2)  # e.g., '11-trends/data/trend-robot-native-analytics-d4e5f6'
        title = match.group(3)  # e.g., 'Robot-Native Analytics' (or None if no alias)

        # Extract entity_id from path (last segment)
        entity_id = path.split('/')[-1]

        # If no alias provided, create title from entity_id
        if not title:
            # Convert 'trend-robot-native-analytics-d4e5f6' to 'Robot Native Analytics'
            # Remove prefix and hash, then title case
            title_parts = entity_id.split('-')
            if title_parts[0] in ('trend', 'megatrend'):
                title_parts = title_parts[1:]
            # Remove trailing hash (typically 6-8 alphanumeric chars)
            if title_parts and len(title_parts[-1]) >= 6 and title_parts[-1].isalnum():
                title_parts = title_parts[:-1]
            title = ' '.join(word.capitalize() for word in title_parts)

        entity_type = 'megatrend' if type_marker == 'M' else 'trend'

        entries.append({
            'id': entity_id,
            'type': entity_type,
            'title': title,
            'path': path,
        })

    return entries


def get_lazy_preview(entity_id: str, entity_type: str, title: str,
                     entities: Optional[Dict[str, Dict]] = None) -> Dict[str, Any]:
    """Get preview data for entity, with graceful fallback.

    If entity is loaded, use full preview. Otherwise, return minimal
    structure that still works in the UI.

    Args:
        entity_id: Entity identifier
        entity_type: 'megatrend' or 'trend'
        title: Display title from wikilink
        entities: Optional loaded entities dict for enhanced preview

    Returns:
        Preview data dict for the entity
    """
    # If entity is loaded, use the full preview generator
    if entities and entity_id in entities:
        return generate_preview_data(entities[entity_id])

    # Minimal fallback preview that works in the UI
    return {
        'title': title,
        'type': entity_type,
    }


def parse_kanban_from_table(report_body: str, entities: Dict[str, Dict] = None) -> Dict[str, Any]:
    """Build kanban data directly from the Trend Landscape table structure.

    This function parses the markdown table cell by cell to build the kanban
    data, treating the table as the authoritative source. The interactive
    kanban will exactly mirror the source table.

    Table format expected:
    | Dimension | Act (0-6 months) | Plan (6-18 months) | Observe (18+ months) |
    |-----------|------------------|-------------------|----------------------|
    | **Dim Name** | **M:** [[path\\|Title]]<br>**T:** [[path\\|Title]] | ... | ... |

    Args:
        report_body: The markdown content of research-hub.md (after frontmatter)
        entities: Optional loaded entities dict for enhanced preview data

    Returns:
        Dict with 'dimensions', 'horizons', 'dataPoints' ready for RADAR_DATA
    """
    # Standard horizons with radii (matches generate_radar_data)
    horizons = [
        {'id': 'act', 'name': 'Act', 'radius': 80, 'description': '0-6 months'},
        {'id': 'plan', 'name': 'Plan', 'radius': 160, 'description': '6-18 months'},
        {'id': 'observe', 'name': 'Observe', 'radius': 240, 'description': '18+ months'},
    ]

    data_points = []
    dimension_order = []  # Track dimension order from table rows

    # Find table with Act/Plan/Observe headers (reuse existing pattern)
    table_pattern = r'(\|[^\n]*(?:Act|Plan|Observe)[^\n]*\|\n\|[\-:|\s]+\|\n(?:\|[^\n]+\|\n?)+)'
    table_match = re.search(table_pattern, report_body, re.IGNORECASE)

    if not table_match:
        # No table found - return empty structure (caller will fallback)
        return {'dimensions': [], 'horizons': horizons, 'dataPoints': []}

    lines = [line.strip() for line in table_match.group(1).split('\n') if line.strip()]
    if len(lines) < 3:
        return {'dimensions': [], 'horizons': horizons, 'dataPoints': []}

    # Use module-level split_table_cells() helper
    # Parse header to find horizon column indices
    header_cells = split_table_cells(lines[0])
    horizon_columns = {}  # horizon_name -> column_index
    for idx, cell in enumerate(header_cells):
        cell_lower = cell.lower()
        if 'act' in cell_lower:
            horizon_columns['act'] = idx
        elif 'plan' in cell_lower:
            horizon_columns['plan'] = idx
        elif 'observe' in cell_lower:
            horizon_columns['observe'] = idx

    # Skip if we didn't find all three horizon columns
    if len(horizon_columns) < 3:
        print(f"    Warning: Found only {len(horizon_columns)} horizon columns in table")

    # Parse data rows (skip header and separator)
    for line in lines[2:]:
        if not line.startswith('|'):
            continue

        cells = split_table_cells(line)
        if len(cells) < 2:
            continue

        # First cell is dimension name
        dim_raw = cells[0]
        dim_slug = normalize_dimension_name(dim_raw)
        dim_title = dim_raw.strip().replace('**', '').strip()

        # Track dimension order (first occurrence)
        if dim_slug not in dimension_order:
            dimension_order.append((dim_slug, dim_title))

        # Process each horizon column
        for horizon, col_idx in horizon_columns.items():
            if col_idx >= len(cells):
                continue

            cell_content = cells[col_idx]
            entries = parse_cell_entries(cell_content)

            for entry in entries:
                data_points.append({
                    'id': entry['id'],
                    'type': entry['type'],
                    'title': entry['title'],
                    'dimension': dim_slug,
                    'horizon': horizon,
                    'preview': get_lazy_preview(
                        entry['id'], entry['type'], entry['title'], entities
                    ),
                })

    # Build dimensions list from table row order
    dimensions = []
    sector_angle = 360 / max(len(dimension_order), 1)

    for i, (slug, title) in enumerate(dimension_order):
        # Use table-based title directly (already clean, no "Dimension:" prefix)
        color = get_dimension_color(slug, i)

        dimensions.append({
            'id': slug,
            'slug': slug,
            'title': title,
            'color': color,
            'startAngle': i * sector_angle,
            'endAngle': (i + 1) * sector_angle,
        })

    # Log distribution for debugging
    if data_points:
        act_count = sum(1 for p in data_points if p['horizon'] == 'act')
        plan_count = sum(1 for p in data_points if p['horizon'] == 'plan')
        observe_count = sum(1 for p in data_points if p['horizon'] == 'observe')
        print(f"    Table-based horizon distribution: act={act_count}, plan={plan_count}, observe={observe_count}")

    return {
        'dimensions': dimensions,
        'horizons': horizons,
        'dataPoints': data_points,
    }


def generate_preview_data(entity: Dict) -> Dict[str, Any]:
    """Generate type-specific preview data for an entity.

    Args:
        entity: Entity dict with 'type', 'title', 'metadata', 'body' keys

    Returns:
        Dict with preview fields appropriate for the entity type
    """
    entity_type = entity.get('type', 'unknown')
    metadata = entity.get('metadata', {})
    body = entity.get('body', '')

    preview = {
        'title': entity.get('title', entity.get('id', '')),
        'type': entity_type,
    }

    if entity_type == 'trend':
        preview['dimension'] = metadata.get('dimension', '')
        preview['horizon'] = metadata.get('planning_horizon', '')
        preview['excerpt'] = extract_first_paragraph(body, max_chars=200)
        # Add portfolio refs for preview
        portfolio_refs = metadata.get('portfolio_refs', [])
        preview['portfolio_count'] = len(portfolio_refs)
        preview['portfolio_refs'] = portfolio_refs[:5]  # Limit for preview

    elif entity_type == 'finding':
        preview['key_findings'] = extract_key_findings(body, max_items=3)
        # Fallback to first paragraph if no key findings found
        if not preview['key_findings']:
            preview['excerpt'] = extract_first_paragraph(body, max_chars=150)

    elif entity_type == 'claim':
        claim_text = metadata.get('claim_text', '')
        if not claim_text:
            # Try to extract from body
            claim_text = extract_first_paragraph(body, max_chars=200)
        preview['claim_text'] = claim_text[:200] if len(claim_text) > 200 else claim_text
        preview['confidence'] = metadata.get('confidence_score', 0)
        preview['status'] = metadata.get('verification_status', 'unverified')

    elif entity_type == 'source':
        preview['source_type'] = metadata.get('source_type', '')
        preview['tier'] = metadata.get('reliability_tier', '')
        preview['domain'] = metadata.get('domain', '')
        url = metadata.get('url', '')
        if url and not preview['domain']:
            # Extract domain from URL
            try:
                from urllib.parse import urlparse
                preview['domain'] = urlparse(url).netloc
            except Exception:
                pass

    elif entity_type == 'concept':
        definition = metadata.get('definition', '')
        preview['excerpt'] = definition if definition else extract_first_paragraph(body, max_chars=150)

    elif entity_type == 'megatrend':
        preview['megatrend_name'] = metadata.get('megatrend_name', '')
        preview['planning_horizon'] = metadata.get('planning_horizon', '')
        preview['evidence_strength'] = metadata.get('evidence_strength', '')
        preview['confidence'] = metadata.get('confidence_score', 0)
        preview['source_type'] = metadata.get('source_type', '')
        preview['finding_count'] = metadata.get('finding_count', 0)

        # Extract from strategic_narrative if TIPS structure
        strategic = metadata.get('strategic_narrative', {})
        if strategic and isinstance(strategic, dict):
            trend = strategic.get('trend', '')
            preview['trend'] = trend[:150] + '...' if len(trend) > 150 else trend
        else:
            preview['excerpt'] = extract_first_paragraph(body, max_chars=150)

    elif entity_type == 'citation':
        preview['quote'] = metadata.get('quote', '')[:150] if metadata.get('quote') else ''
        preview['source_ref'] = metadata.get('source_ref', '')

    elif entity_type == 'dimension':
        preview['excerpt'] = extract_first_paragraph(body, max_chars=150)

    elif entity_type == 'question':
        preview['excerpt'] = extract_first_paragraph(body, max_chars=150)

    elif entity_type == 'synthesis':
        preview['dimension'] = metadata.get('dimension', '')
        preview['trend_count'] = metadata.get('trend_count', '')
        preview['avg_confidence'] = metadata.get('avg_confidence', '')
        preview['word_count'] = metadata.get('word_count', '')
        preview['excerpt'] = extract_first_paragraph(body, max_chars=200)

    else:
        # Generic fallback
        preview['excerpt'] = extract_first_paragraph(body, max_chars=150)

    return preview


def normalize_horizon(horizon: str) -> str:
    """Normalize horizon value to act/plan/observe.

    Args:
        horizon: Raw horizon string from entity metadata

    Returns:
        Normalized horizon string: 'act', 'plan', or 'observe'
    """
    if not horizon:
        return 'plan'
    horizon_lower = horizon.lower().strip()
    if 'act' in horizon_lower:
        return 'act'
    elif 'observe' in horizon_lower:
        return 'observe'
    return 'plan'


def infer_megatrend_dimension(metadata: Dict, entities: Dict[str, Dict]) -> str:
    """Infer dimension for a megatrend using best-effort methods.

    Tries the following in order:
    1. dimension_affinity from metadata
    2. dimension/ tag prefix
    3. Majority vote from finding_refs

    Args:
        metadata: Megatrend entity metadata
        entities: All entities dict for finding lookup

    Returns:
        Dimension slug or empty string if not found
    """
    # Try 1: Direct dimension_affinity
    dimension = metadata.get('dimension_affinity', '')
    if dimension:
        return dimension

    # Try 2: Infer from tags (e.g., "dimension/technology-trends")
    tags = metadata.get('tags', [])
    for tag in tags:
        if isinstance(tag, str) and tag.startswith('dimension/'):
            return tag.replace('dimension/', '')

    # Try 3: Infer from finding_refs (majority vote)
    finding_refs = metadata.get('finding_refs', [])
    if finding_refs:
        dim_counts = {}
        for ref in finding_refs:
            # Extract finding ID from wikilink
            finding_id = ref.strip('[]').split('/')[-1].replace(']]', '')
            finding_entity = entities.get(finding_id, {})
            finding_dim = finding_entity.get('metadata', {}).get('dimension', '')
            if finding_dim:
                dim_counts[finding_dim] = dim_counts.get(finding_dim, 0) + 1
        if dim_counts:
            return max(dim_counts, key=dim_counts.get)

    return ''


def _resolve_wikilink_id(wikilink_str: str, all_entities: Dict[str, Dict]) -> Optional[Dict]:
    """Resolve a wikilink string to its entity dict.

    Args:
        wikilink_str: Wikilink like "[[02-refined-questions/data/question-001]]"
        all_entities: All loaded entities for lookup

    Returns:
        Entity dict if found, None otherwise
    """
    entity_id = extract_entity_id_from_wikilink(wikilink_str)
    if entity_id and entity_id in all_entities:
        return all_entities[entity_id]
    return None


def _resolve_question_dimension(
    q_meta: Dict, all_entities: Dict[str, Dict]
) -> Optional[str]:
    """Resolve dimension entity ID from a question's metadata.

    Tries two strategies:
    1. Plain 'dimension' slug field -> match against dimension entity slugs
    2. 'dimension_ref' wikilink -> resolve directly to dimension entity ID

    Returns:
        Dimension entity ID string, or None
    """
    # Strategy 1: plain slug
    dim_slug = q_meta.get('dimension', '')
    if dim_slug:
        for eid, e in all_entities.items():
            if e.get('type') == 'dimension':
                e_slug = e.get('metadata', {}).get('slug', '')
                if e_slug == dim_slug:
                    return eid

    # Strategy 2: dimension_ref wikilink
    dim_ref = q_meta.get('dimension_ref', '')
    if dim_ref:
        dim_entity = _resolve_wikilink_id(dim_ref, all_entities)
        if dim_entity:
            return dim_entity['id']

    return None


def _resolve_finding_dimension_question(
    finding_meta: Dict, all_entities: Dict[str, Dict]
) -> Tuple[Optional[str], Optional[str]]:
    """Resolve dimension and question IDs for a finding entity.

    Resolution chain:
    1. question_ref wikilink -> question entity -> its dimension field
    2. Fallback: batch_ref -> query-batch entity -> question_ref -> question -> dimension
    3. Fallback: dimension tag (dimension/{slug}) matched to dimension entities
    4. Fallback: dimension metadata field matched to dimension entities

    Args:
        finding_meta: Finding entity metadata dict
        all_entities: All loaded entities

    Returns:
        (dimension_id, question_id) tuple; either may be None
    """
    # Try 1: question_ref -> question entity -> dimension
    question_ref = finding_meta.get('question_ref', '')
    if question_ref:
        q_entity = _resolve_wikilink_id(question_ref, all_entities)
        if q_entity:
            q_id = q_entity['id']
            q_meta = q_entity.get('metadata', {})
            dim_id = _resolve_question_dimension(q_meta, all_entities)
            if dim_id:
                return (dim_id, q_id)
            return (None, q_id)

    # Try 2: batch_ref -> batch -> question_ref -> question -> dimension
    batch_ref = finding_meta.get('batch_ref', '')
    if batch_ref:
        batch_entity = _resolve_wikilink_id(batch_ref, all_entities)
        if batch_entity:
            batch_q_ref = batch_entity.get('metadata', {}).get('question_ref', '')
            if batch_q_ref:
                q_entity = _resolve_wikilink_id(batch_q_ref, all_entities)
                if q_entity:
                    q_id = q_entity['id']
                    q_meta = q_entity.get('metadata', {})
                    dim_id = _resolve_question_dimension(q_meta, all_entities)
                    if dim_id:
                        return (dim_id, q_id)
                    return (None, q_id)

    # Try 3: dimension tag (dimension/{slug})
    tags = finding_meta.get('tags', [])
    for tag in tags:
        if isinstance(tag, str) and tag.startswith('dimension/'):
            dim_slug = tag.replace('dimension/', '')
            for eid, e in all_entities.items():
                if e.get('type') == 'dimension':
                    e_slug = e.get('metadata', {}).get('slug', '')
                    if e_slug == dim_slug:
                        return (eid, None)

    # Try 4: dimension metadata field
    dim_field = finding_meta.get('dimension', '')
    if dim_field:
        for eid, e in all_entities.items():
            if e.get('type') == 'dimension':
                e_slug = e.get('metadata', {}).get('slug', '')
                if e_slug == dim_field:
                    return (eid, None)

    return (None, None)


def build_dimension_question_grouping(
    entities: List[Dict],
    all_entities: Dict[str, Dict],
    entity_type: str = 'finding'
) -> Tuple[Dict[str, Dict[str, List[Dict]]], Dict[str, Dict], Dict[str, Dict], List[Dict]]:
    """Group entities by dimension and question for structured rendering.

    Args:
        entities: List of entity dicts to group
        all_entities: All loaded entities for resolution
        entity_type: 'finding' or 'claim'

    Returns:
        (grouped, dim_info, question_info, ungrouped) where:
        - grouped: {dim_id: {question_id_or_'_none': [entities]}}
        - dim_info: {dim_id: entity_dict}
        - question_info: {question_id: entity_dict}
        - ungrouped: entities that couldn't be resolved
    """
    grouped: Dict[str, Dict[str, List[Dict]]] = {}
    dim_info: Dict[str, Dict] = {}
    question_info: Dict[str, Dict] = {}
    ungrouped: List[Dict] = []

    for entity in entities:
        meta = entity.get('metadata', {})
        dim_id = None
        q_id = None

        if entity_type == 'finding':
            dim_id, q_id = _resolve_finding_dimension_question(meta, all_entities)
        elif entity_type == 'claim':
            # Inherit dimension/question from first resolvable finding_ref
            finding_refs = meta.get('finding_refs', [])
            for ref in finding_refs:
                f_entity = _resolve_wikilink_id(ref, all_entities)
                if f_entity:
                    f_meta = f_entity.get('metadata', {})
                    dim_id, q_id = _resolve_finding_dimension_question(f_meta, all_entities)
                    if dim_id is not None:
                        break
            # Fallback: claim's own dimension field
            if dim_id is None:
                dim_field = meta.get('dimension', '')
                if dim_field:
                    for eid, e in all_entities.items():
                        if e.get('type') == 'dimension':
                            e_slug = e.get('metadata', {}).get('slug', '')
                            if e_slug == dim_field:
                                dim_id = eid
                                break

        if dim_id is None:
            ungrouped.append(entity)
            continue

        # Cache dimension info
        if dim_id not in dim_info and dim_id in all_entities:
            dim_info[dim_id] = all_entities[dim_id]

        # Cache question info
        q_key = q_id if q_id else '_none'
        if q_id and q_id not in question_info and q_id in all_entities:
            question_info[q_id] = all_entities[q_id]

        grouped.setdefault(dim_id, {}).setdefault(q_key, []).append(entity)

    # Sort dimensions by ID (natural ordering: dim-1, dim-2, etc.)
    sorted_grouped: Dict[str, Dict[str, List[Dict]]] = {}
    for dim_id in sorted(grouped.keys(),
                         key=lambda d: dim_info.get(d, {}).get('title', d).lower()):
        inner = grouped[dim_id]
        # Sort questions: real questions first (by ID), then _none
        sorted_inner: Dict[str, List[Dict]] = {}
        for q_key in sorted(inner.keys(),
                            key=lambda q: ('1' if q == '_none' else '0',
                                           question_info.get(q, {}).get('title', q).lower())):
            # Sort entities within each question by title
            sorted_inner[q_key] = sorted(inner[q_key],
                                         key=lambda e: e.get('title', e['id']).lower())
        sorted_grouped[dim_id] = sorted_inner

    return (sorted_grouped, dim_info, question_info, ungrouped)


def generate_radar_data(entities: Dict[str, Dict], horizon_mapping: Dict[str, str] = None) -> Dict[str, Any]:
    """Generate radar visualization data from Megatrends and Trends.

    Extracts Megatrends and Trends to plot on an interactive radar chart where:
    - Sectors = Research Dimensions (wedge-shaped sections)
    - Rings = Planning Horizons (act=inner, plan=middle, observe=outer)
    - Dots = Megatrends and Trends as uniform-size points

    Args:
        entities: Dict mapping entity_id to entity data
        horizon_mapping: Optional dict mapping entity_id to horizon from table

    Returns:
        Dict with 'dimensions', 'horizons', 'dataPoints' for radar rendering
    """
    # Extract unique dimensions from entities
    dimension_slugs = set()
    for entity_id, entity in entities.items():
        entity_type = entity.get('type', '')
        if entity_type == 'megatrend':
            metadata = entity.get('metadata', {})
            dim = infer_megatrend_dimension(metadata, entities)
            if dim:
                dimension_slugs.add(dim)
        elif entity_type == 'trend':
            metadata = entity.get('metadata', {})
            dim = metadata.get('dimension', '')
            if dim:
                dimension_slugs.add(dim)
        elif entity_type == 'dimension':
            metadata = entity.get('metadata', {})
            slug = metadata.get('slug', entity_id.replace('dim-', ''))
            if slug:
                dimension_slugs.add(slug)

    # Build dimension list with colors and angles
    dimensions = []
    sorted_dims = sorted(dimension_slugs)
    sector_angle = 360 / max(len(sorted_dims), 1)

    for i, dim_slug in enumerate(sorted_dims):
        # Find title from dimension entity if available
        dim_title = dim_slug.replace('-', ' ').title()
        for entity_id, entity in entities.items():
            if entity.get('type') == 'dimension':
                entity_slug = entity.get('metadata', {}).get('slug', entity_id.replace('dim-', ''))
                if entity_slug == dim_slug:
                    raw_title = entity.get('title', dim_title)
                    # Strip "Dimension:" prefix if present
                    if raw_title.lower().startswith('dimension:'):
                        dim_title = raw_title[10:].strip()
                    else:
                        dim_title = raw_title
                    break

        color = get_dimension_color(dim_slug, i)

        dimensions.append({
            'id': dim_slug,
            'slug': dim_slug,
            'title': dim_title,
            'color': color,
            'startAngle': i * sector_angle,
            'endAngle': (i + 1) * sector_angle,
        })

    # Standard horizons with radii
    horizons = [
        {'id': 'act', 'name': 'Act', 'radius': 80, 'description': '0-6 months'},
        {'id': 'plan', 'name': 'Plan', 'radius': 160, 'description': '6-18 months'},
        {'id': 'observe', 'name': 'Observe', 'radius': 240, 'description': '18+ months'},
    ]

    # Extract data points from Megatrends and Trends
    data_points = []
    for entity_id, entity in entities.items():
        entity_type = entity.get('type', '')

        if entity_type == 'megatrend':
            metadata = entity.get('metadata', {})
            dimension = infer_megatrend_dimension(metadata, entities)
            # Priority: 1) Table mapping, 2) Metadata, 3) Default 'plan'
            if horizon_mapping and entity_id in horizon_mapping:
                horizon = horizon_mapping[entity_id]
            else:
                horizon = normalize_horizon(metadata.get('planning_horizon', 'plan'))

            data_points.append({
                'id': entity_id,
                'type': 'megatrend',
                'title': entity.get('title', entity_id),
                'dimension': dimension,
                'horizon': horizon,
                'preview': generate_preview_data(entity),
            })

        elif entity_type == 'trend':
            metadata = entity.get('metadata', {})
            dimension = metadata.get('dimension', '')
            # Priority: 1) Table mapping, 2) Metadata, 3) Default 'plan'
            if horizon_mapping and entity_id in horizon_mapping:
                horizon = horizon_mapping[entity_id]
            else:
                horizon = normalize_horizon(
                    metadata.get('planning_horizon', metadata.get('horizon', 'plan'))
                )

            data_points.append({
                'id': entity_id,
                'type': 'trend',
                'title': entity.get('title', entity_id),
                'dimension': dimension,
                'horizon': horizon,
                'preview': generate_preview_data(entity),
            })

    return {
        'dimensions': dimensions,
        'horizons': horizons,
        'dataPoints': data_points,
    }


def generate_graph_data(entities: Dict[str, Dict]) -> Dict[str, Any]:
    """Generate entity relationship graph data for D3 force-directed visualization.

    Extracts nodes and directed edges from ALL wikilink references:
    1. All metadata fields containing wikilinks (singular and list)
    2. Body content wikilinks (inline [[entity]] references)

    Args:
        entities: Dict of entity_id -> entity data dicts

    Returns:
        Dict with 'nodes' and 'links' arrays for D3 force simulation
    """
    nodes = []
    links = []
    seen_links: set = set()
    wikilink_pattern = re.compile(r'\[\[([^\]\|\\]+)(?:\\?\|[^\]]+)?\]\]')

    def extract_target_id(ref_str: str) -> Optional[str]:
        """Extract entity ID from a wikilink string."""
        match = wikilink_pattern.search(ref_str)
        if match:
            path = match.group(1).rstrip('\\')
            return path.split('/')[-1] if '/' in path else path
        return None

    def add_link(source_id: str, target_id: str, link_type: str):
        """Add a directed edge, deduplicating by source->target."""
        if target_id and target_id in entities and target_id != source_id:
            link_key = f"{source_id}->{target_id}"
            if link_key not in seen_links:
                seen_links.add(link_key)
                links.append({
                    'source': source_id,
                    'target': target_id,
                    'type': link_type,
                })

    for entity_id, entity in entities.items():
        entity_type = entity.get('type', 'unknown')
        metadata = entity.get('metadata', {})

        nodes.append({
            'id': entity_id,
            'type': entity_type,
            'title': entity.get('title', entity_id),
            'dimension': metadata.get('dimension', ''),
            'horizon': metadata.get('planning_horizon', ''),
        })

        # Phase 1: Extract ALL metadata wikilink fields
        for field_name, value in metadata.items():
            if isinstance(value, list):
                for item in value:
                    if not isinstance(item, str):
                        continue
                    target_id = extract_target_id(item)
                    if target_id:
                        link_type = field_name.replace('_refs', '').replace('_ids', '').replace('related_', '')
                        add_link(entity_id, target_id, link_type)
            elif isinstance(value, str) and '[[' in value:
                target_id = extract_target_id(value)
                if target_id:
                    link_type = field_name.replace('_ref', '').replace('_id', '')
                    add_link(entity_id, target_id, link_type)

        # Phase 2: Extract body wikilinks
        body = entity.get('body', '')
        if body:
            for wl in extract_wikilinks(body):
                add_link(entity_id, wl['entity_id'], 'body-reference')

    return {'nodes': nodes, 'links': links}


def resolve_entity_file(project: Path, entity_id: str) -> Optional[Path]:
    """Locate entity file in appropriate directory.

    Args:
        project: Project root path
        entity_id: Entity identifier (e.g., "finding-abc")

    Returns:
        Path to entity file if found, None otherwise
    """
    # Determine entity type from ID prefix
    prefixes = {
        'dim-': 'dimensions',
        'question-': 'questions',
        'batch-': 'query-batches',
        'finding-': 'findings',
        'concept-': 'concepts',
        'megatrend-': 'megatrends',
        'source-': 'sources',
        'publisher-': 'publishers',
        'citation-': 'citations',
        'claim-': 'claims',
        'trend-': 'trends',
        'portfolio-': 'trends',
    }

    entity_type = None
    for prefix, etype in prefixes.items():
        if entity_id.startswith(prefix):
            entity_type = etype
            break

    if not entity_type:
        return None

    # Try both concepts directories
    dirs_to_try = [ENTITY_DIRS.get(entity_type)]
    if entity_type == 'concepts':
        dirs_to_try.append(ENTITY_DIRS.get('domain-concepts'))

    for entity_dir in dirs_to_try:
        if not entity_dir:
            continue
        file_path = project / entity_dir / DATA_SUBDIR / f"{entity_id}.md"
        if file_path.exists():
            return file_path

    return None


def convert_wikilinks_to_anchors(content: str, entities: Dict[str, Dict]) -> str:
    """Transform [[entity]] to <a href="#entity-id" data-preview="...">Title</a>.

    Also converts file-path links like <a href="11-trends/data/entity-id.md">
    to proper wikilinks with preview data.

    Args:
        content: Markdown content with wikilinks
        entities: Dict mapping entity_id to entity data with 'title' key

    Returns:
        Content with wikilinks converted to anchor links with preview data
    """
    # Protect mermaid blocks from wikilink conversion
    mermaid_blocks = []
    def save_mermaid(match):
        mermaid_blocks.append(match.group(0))
        return f'__MERMAID_BLOCK_{len(mermaid_blocks) - 1}__'

    content = re.sub(r'<pre class="mermaid">.*?</pre>', save_mermaid, content, flags=re.DOTALL)

    # First pass: Convert [[entity]] wikilinks
    wikilinks = extract_wikilinks(content)

    for wl in wikilinks:
        entity_id = wl['entity_id']
        display = wl['display_text']

        if entity_id in entities:
            entity = entities[entity_id]
            entity_type = entity.get('type', 'unknown')

            # Use explicit display text from pipe syntax (e.g. |C1), fall back to entity title
            if display != entity_id:
                link_text = display
            else:
                link_text = entity.get('title', display)

            # Generate preview data and encode as JSON
            preview_data = generate_preview_data(entity)
            preview_json = html_lib.escape(
                json.dumps(preview_data, ensure_ascii=False)
            )

            anchor = (
                f'<a href="#{entity_id}" '
                f'class="wikilink" '
                f'data-entity-type="{entity_type}" '
                f'data-preview="{preview_json}">'
                f'{html_lib.escape(link_text)}</a>'
            )
        else:
            # Broken link - no preview, just tooltip
            anchor = (
                f'<a href="#{entity_id}" '
                f'class="wikilink-broken" '
                f'title="Entity not found">'
                f'{html_lib.escape(display)}</a>'
            )

        content = content.replace(wl['raw'], anchor)

    # Second pass: Convert file-path links like <a href="11-trends/data/entity-id.md">text</a>
    # Pattern matches: <a href="NN-dirname/data/entity-id.md">link_text</a>
    # Also matches: <a href="NN-dirname/entity-id.md">link_text</a> (e.g., 12-synthesis/)
    file_link_pattern = re.compile(
        r'<a href="(\d{2}-[^/]+(?:/data)?/([^"]+)\.md)"[^>]*>([^<]+)</a>'
    )

    def replace_file_link(match: re.Match) -> str:
        full_path = match.group(1)  # e.g., "11-trends/data/trend-foo.md"
        entity_id = match.group(2)  # e.g., "trend-foo"
        link_text = match.group(3)  # e.g., "4" or display text

        # Look up entity
        entity = entities.get(entity_id)
        if not entity:
            # Return as broken link
            return (
                f'<a href="#{entity_id}" '
                f'class="wikilink-broken" '
                f'title="Entity not found: {full_path}">'
                f'{html_lib.escape(link_text)}</a>'
            )

        # Generate preview and anchor
        entity_type = entity.get('type', 'unknown')
        preview_data = generate_preview_data(entity)
        preview_json = html_lib.escape(
            json.dumps(preview_data, ensure_ascii=False)
        )

        return (
            f'<a href="#{entity_id}" '
            f'class="wikilink" '
            f'data-entity-type="{entity_type}" '
            f'data-preview="{preview_json}">'
            f'{html_lib.escape(link_text)}</a>'
        )

    content = file_link_pattern.sub(replace_file_link, content)

    # Restore mermaid blocks
    for i, block in enumerate(mermaid_blocks):
        content = content.replace(f'__MERMAID_BLOCK_{i}__', block)

    return content


def load_entities(project: Path) -> Dict[str, Dict]:
    """Load all entities from project directories.

    Returns:
        Dict mapping entity_id to entity data
    """
    entities = {}

    for entity_type, dir_name in ENTITY_DIRS.items():
        data_dir = project / dir_name / DATA_SUBDIR
        if not data_dir.exists():
            continue

        for file_path in data_dir.glob('*.md'):
            try:
                content = file_path.read_text(encoding='utf-8')
                metadata, body = parse_frontmatter(content)

                entity_id = file_path.stem
                title = metadata.get('dc:title', metadata.get('title', entity_id))

                entities[entity_id] = {
                    'id': entity_id,
                    'type': TYPE_SINGULAR.get(entity_type, entity_type),
                    'title': title,
                    'metadata': metadata,
                    'body': body,
                    'file_path': str(file_path),
                }
            except Exception as e:
                print(f"Warning: Failed to load {file_path}: {e}")

    # Load dimension synthesis files from 12-synthesis/ (new location)
    # These are rich narrative documents created by synthesis-dimension
    # With backward compatibility: also check 11-trends/synthesis-*.md for older projects
    synthesis_dirs = [
        project / '12-synthesis',       # New location (v2.3.0+)
        project / '11-trends',        # Legacy location (backward compatibility)
    ]

    for syntheses_dir in synthesis_dirs:
        if not syntheses_dir.exists():
            continue
        for file_path in syntheses_dir.glob('synthesis-*.md'):
            entity_id = file_path.stem

            # Skip synthesis-cross-dimensional.md (removed in v3.0)
            if entity_id == 'synthesis-cross-dimensional':
                continue

            try:
                content = file_path.read_text(encoding='utf-8')
                metadata, body = parse_frontmatter(content)

                # Skip if already loaded (prefer 12-synthesis/ over 11-trends/)
                if entity_id in entities:
                    continue

                title = metadata.get('title', metadata.get('dc:title', entity_id))

                entities[entity_id] = {
                    'id': entity_id,
                    'type': 'synthesis',
                    'title': title,
                    'metadata': metadata,
                    'body': body,
                    'file_path': str(file_path),
                }
            except Exception as e:
                print(f"Warning: Failed to load synthesis {file_path}: {e}")

    return entities


def load_readmes(project: Path) -> Dict[str, Dict]:
    """Load all README files from entity base directories.

    Scans entity base directories (not /data/) for README.md and
    README-{slug}.md files.

    Returns:
        Dict mapping readme_id to readme data with keys:
        - id: Unique identifier (e.g., 'readme-trends')
        - type: Always 'readme'
        - subtype: Parent entity type (e.g., 'trends')
        - title: From frontmatter or generated
        - is_dimension_scoped: Boolean
        - dimension: Dimension slug if dimension-scoped
        - metadata: Frontmatter dict
        - body: Markdown body
        - file_path: Absolute path string
    """
    readmes = {}

    for subtype, (dir_name, has_dimension_readmes) in README_DIRS.items():
        dir_path = project / dir_name
        if not dir_path.exists():
            continue

        # Load main README.md
        main_readme = dir_path / 'README.md'
        if main_readme.exists():
            try:
                content = main_readme.read_text(encoding='utf-8')
                metadata, body = parse_frontmatter(content)

                readme_id = f'readme-{subtype}'
                title = metadata.get('title', metadata.get('dc:title', f'{subtype.replace("-", " ").title()} Overview'))

                readmes[readme_id] = {
                    'id': readme_id,
                    'type': 'readme',
                    'subtype': subtype,
                    'title': title,
                    'is_dimension_scoped': False,
                    'dimension': None,
                    'metadata': metadata,
                    'body': body,
                    'file_path': str(main_readme),
                }
            except Exception as e:
                print(f"Warning: Failed to load README {main_readme}: {e}")

        # Load dimension-scoped READMEs if applicable
        if has_dimension_readmes:
            for readme_file in dir_path.glob('README-*.md'):
                try:
                    content = readme_file.read_text(encoding='utf-8')
                    metadata, body = parse_frontmatter(content)

                    # Extract dimension slug from filename
                    # e.g., README-infrastructure.md -> infrastructure
                    dim_slug = readme_file.stem.replace('README-', '')

                    readme_id = f'readme-{subtype}-{dim_slug}'
                    title = metadata.get('title', metadata.get('dc:title', dim_slug.replace('-', ' ').title()))

                    readmes[readme_id] = {
                        'id': readme_id,
                        'type': 'readme',
                        'subtype': subtype,
                        'title': title,
                        'is_dimension_scoped': True,
                        'dimension': metadata.get('dimension', dim_slug),
                        'metadata': metadata,
                        'body': body,
                        'file_path': str(readme_file),
                    }
                except Exception as e:
                    print(f"Warning: Failed to load dimension README {readme_file}: {e}")

    return readmes


def detect_hub_version(report_metadata: Dict) -> str:
    """Detect hub version from frontmatter.

    Returns 'v3.0' if hub_type contains 'navigation' or 'catalog',
    or if hub_version starts with '3', else 'v2.x'

    Args:
        report_metadata: Parsed frontmatter from research-hub.md

    Returns:
        Version string: 'v3.0' or 'v2.x'
    """
    hub_type = str(report_metadata.get('hub_type', '')).lower()
    hub_version = str(report_metadata.get('hub_version', ''))
    if 'catalog' in hub_type or 'navigation' in hub_type:
        return 'v3.0'
    if hub_version.startswith('3'):
        return 'v3.0'
    return 'v2.x'


def load_hub_supporting_files(project_path: Path) -> Dict[str, Dict]:
    """Load v3.0 hub supporting files.

    Loads supporting files that are part of the v3.0 hub ecosystem:
    - 00-research-scope.md (methodology) - consolidated at end
    - 00-pipeline-metrics.md (entity statistics) - consolidated at end
    - research-methodology.md (methodology documentation) - consolidated at end
    - executive-summary.md (optional executive narrative)
    - insight-summary.md (featured journalistic narrative)

    Files with order=99 are consolidated into "Research Metadata and Methodology" section.

    Args:
        project_path: Path to research project root

    Returns:
        Dict of file_id -> {id, title, body, type, order, metadata, file_path}
    """
    supporting_files = {}

    # Load 00-research-scope.md (part of consolidated methodology section)
    scope_path = project_path / '00-research-scope.md'
    if scope_path.exists():
        try:
            content = scope_path.read_text(encoding='utf-8')
            metadata, body = parse_frontmatter(content)
            supporting_files['00-research-scope'] = {
                'id': '00-research-scope',
                'title': metadata.get('title', 'Research Scope & Methodology'),
                'body': body,
                'type': 'hub-supporting',
                'order': 99,  # Render at end with consolidated section
                'metadata': metadata,
                'file_path': str(scope_path),
            }
        except Exception as e:
            print(f"Warning: Failed to load 00-research-scope.md: {e}")

    # Load 00-pipeline-metrics.md (part of consolidated methodology section)
    metrics_path = project_path / '00-pipeline-metrics.md'
    if metrics_path.exists():
        try:
            content = metrics_path.read_text(encoding='utf-8')
            metadata, body = parse_frontmatter(content)
            supporting_files['00-pipeline-metrics'] = {
                'id': '00-pipeline-metrics',
                'title': metadata.get('title', 'Pipeline Metrics & Statistics'),
                'body': body,
                'type': 'hub-supporting',
                'order': 99,  # Render at end with consolidated section
                'metadata': metadata,
                'file_path': str(metrics_path),
            }
        except Exception as e:
            print(f"Warning: Failed to load 00-pipeline-metrics.md: {e}")

    # Load research-methodology.md (Research Methodology Documentation)
    methodology_path = project_path / 'research-methodology.md'
    if methodology_path.exists():
        try:
            content = methodology_path.read_text(encoding='utf-8')
            metadata, body = parse_frontmatter(content)
            supporting_files['research-methodology'] = {
                'id': 'research-methodology',
                'title': metadata.get('title', 'Research Methodology'),
                'body': body,
                'type': 'hub-supporting',
                'order': 99,  # Render at end with consolidated section
                'metadata': metadata,
                'file_path': str(methodology_path),
            }
        except Exception as e:
            print(f"Warning: Failed to load research-methodology.md: {e}")

    # Cross-Dimensional Analysis REMOVED in v3.0 - no longer loaded

    # Load insight-summary.md (Featured Journalistic Narrative)
    insight_path = project_path / 'insight-summary.md'
    if insight_path.exists():
        try:
            content = insight_path.read_text(encoding='utf-8')
            metadata, body = parse_frontmatter(content)

            # Extract story arc, word count, and research type from metadata
            story_arc = metadata.get('story_arc', 'unknown')
            word_count = metadata.get('word_count', 0)
            research_type = metadata.get('research_type', 'General Research')

            supporting_files['insight-summary'] = {
                'id': 'insight-summary',
                'title': metadata.get('title', 'Insight Summary'),
                'body': body,
                'type': 'insight-summary',
                'order': -1,  # Render first (before executive-summary)
                'metadata': metadata,
                'story_arc': story_arc,
                'word_count': word_count,
                'research_type': research_type,
                'file_path': str(insight_path),
            }
        except Exception as e:
            print(f"Warning: Failed to load insight-summary.md: {e}")

    # Load executive-summary.md (Optional Executive Narrative)
    exec_path = project_path / 'executive-summary.md'
    if exec_path.exists():
        try:
            content = exec_path.read_text(encoding='utf-8')
            metadata, body = parse_frontmatter(content)

            # Extract story arc and word count from metadata
            story_arc = metadata.get('story_arc', 'unknown')
            word_count = metadata.get('word_count', 0)

            supporting_files['executive-summary'] = {
                'id': 'executive-summary',
                'title': metadata.get('title', 'Executive Summary'),
                'body': body,
                'type': 'executive-summary',
                'order': 0,  # Render first before research-report
                'metadata': metadata,
                'story_arc': story_arc,
                'word_count': word_count,
                'file_path': str(exec_path),
            }
        except Exception as e:
            print(f"Warning: Failed to load executive-summary.md: {e}")

    return supporting_files


def _render_entity_card(entity: Dict, entity_type: str,
                        all_entities: Dict = None, t: dict = None) -> str:
    """Render a single entity as an <article> HTML card.

    Args:
        entity: Entity data dict
        entity_type: Type of entity (e.g., 'trend', 'finding')
        all_entities: All entities for portfolio resolution
        t: UI translations dict

    Returns:
        HTML string for the entity article
    """
    if t is None:
        t = get_ui_translations('en')

    entity_id = entity['id']
    title = entity.get('title', entity_id)
    body_html = entity.get('body_html', simple_markdown_to_html(entity.get('body', '')))

    metadata = entity.get('metadata', {})
    badges_html = ''

    if entity_type == 'claim':
        confidence = metadata.get('confidence_score', '')
        status = metadata.get('verification_status', '')
        if confidence:
            try:
                conf_pct = int(float(confidence) * 100)
                badges_html += f'<span class="badge confidence">Confidence: {conf_pct}%</span>'
            except ValueError:
                pass
        if status:
            badges_html += f'<span class="badge status-{status}">{status}</span>'

    elif entity_type == 'finding':
        quality_score = metadata.get('quality_score', '')
        if quality_score:
            try:
                score_pct = int(float(quality_score) * 100)
                badge_class = 'quality-high' if score_pct >= 75 else ('quality-medium' if score_pct >= 50 else 'quality-low')
                badges_html += f'<span class="badge {badge_class}">Quality: {score_pct}%</span>'
            except (ValueError, TypeError):
                pass

        quality_status = metadata.get('quality_status', '')
        if quality_status:
            status_class = 'status-pass' if quality_status == 'PASS' else 'status-fail'
            badges_html += f'<span class="badge {status_class}">{quality_status}</span>'

        content_source = metadata.get('content_source', '')
        if content_source:
            badges_html += f'<span class="badge content-source">{content_source}</span>'

        dimension = metadata.get('dimension', '')
        if dimension:
            badges_html += f'<span class="badge dimension">{dimension}</span>'

    elif entity_type == 'trend':
        dimension = metadata.get('dimension', '')
        horizon = metadata.get('planning_horizon', '')
        if dimension:
            badges_html += f'<span class="badge dimension">{dimension}</span>'
        if horizon:
            badges_html += f'<span class="badge horizon">{horizon}</span>'
        portfolio_refs = metadata.get('portfolio_refs', [])
        if portfolio_refs:
            count = len(portfolio_refs)
            badges_html += f'<span class="badge portfolio">{count} portfolio{"s" if count != 1 else ""}</span>'

    elif entity_type == 'source':
        tier = metadata.get('reliability_tier', '')
        source_type = metadata.get('source_type', '')
        if tier:
            badges_html += f'<span class="badge tier">{tier}</span>'
        if source_type:
            badges_html += f'<span class="badge source-type">{source_type}</span>'

    elif entity_type == 'synthesis':
        tags = metadata.get('tags', [])
        synthesis_level = None
        for tag in tags:
            if isinstance(tag, str) and tag.startswith('synthesis-level/'):
                synthesis_level = tag.split('/')[-1]
                break
        if synthesis_level:
            badges_html += f'<span class="badge synthesis-level">{synthesis_level}</span>'

        dimension = metadata.get('dimension', '')
        trend_count = metadata.get('trend_count', '')
        avg_confidence = metadata.get('avg_confidence', '')
        word_count = metadata.get('word_count', '')
        if dimension:
            badges_html += f'<span class="badge dimension">{dimension}</span>'
        if trend_count:
            badges_html += f'<span class="badge trend-count">{trend_count} trends</span>'
        if avg_confidence:
            try:
                conf_pct = int(float(avg_confidence) * 100)
                badges_html += f'<span class="badge confidence">Avg: {conf_pct}%</span>'
            except (ValueError, TypeError):
                pass
        if word_count:
            badges_html += f'<span class="badge word-count">{word_count} {t["words"]}</span>'

    elif entity_type == 'megatrend':
        horizon = metadata.get('planning_horizon', '')
        evidence = metadata.get('evidence_strength', '')
        confidence = metadata.get('confidence_score', '')
        source_type = metadata.get('source_type', '')
        finding_count = metadata.get('finding_count', 0)

        if horizon:
            badges_html += f'<span class="badge horizon-{horizon}">{horizon}</span>'
        if evidence:
            badges_html += f'<span class="badge evidence-{evidence}">{evidence}</span>'
        if confidence:
            try:
                conf_pct = int(float(confidence) * 100)
                badges_html += f'<span class="badge confidence">{conf_pct}%</span>'
            except (ValueError, TypeError):
                pass
        if source_type:
            badges_html += f'<span class="badge source-type">{source_type}</span>'
        if finding_count:
            badges_html += f'<span class="badge finding-count">{finding_count} findings</span>'

    portfolio_section = ''
    if entity_type == 'trend':
        resolved_portfolios = entity.get('resolved_portfolios', [])
        if resolved_portfolios:
            portfolio_section = generate_portfolio_section(resolved_portfolios, all_entities)

    return f'''
        <article id="{entity_id}" class="entity-section {entity_type}">
            <header class="entity-header">
                <h3>{html_lib.escape(title)}</h3>
                <div class="entity-badges">{badges_html}</div>
            </header>
            <div class="entity-content">
                {body_html}
                {portfolio_section}
            </div>
        </article>
        '''


def _render_context_card(entity: Dict, entity_type: str,
                         all_entities: Dict = None, t: dict = None,
                         panel_prefix: str = 'ctx') -> str:
    """Render an entity card with a prefixed ID for inline context use.

    Used when dimension/question entities are rendered inline in findings/claims
    panels to avoid duplicate HTML IDs with the same entities in the Questions tab.

    Args:
        panel_prefix: ID prefix (e.g., 'f-ctx' for findings, 'c-ctx' for claims)
    """
    card_html = _render_entity_card(entity, entity_type, all_entities, t)
    original_id = entity['id']
    return card_html.replace(
        f'id="{original_id}"',
        f'id="{panel_prefix}-{original_id}"',
        1
    )


def generate_entity_section(entity_type: str, entities: List[Dict],
                           readmes: List[Dict] = None,
                           all_entities: Dict = None,
                           t: dict = None) -> str:
    """Create HTML section for entity group.

    Args:
        entity_type: Type of entity (e.g., 'trend', 'finding')
        entities: List of entity data dicts
        readmes: Optional list of README dicts for this entity type
        all_entities: All entities for wikilink resolution in READMEs
        t: UI translations dict

    Returns:
        HTML string for the entity group section
    """
    if not entities and not readmes:
        return ''

    if t is None:
        t = get_ui_translations('en')

    type_labels = {
        'trend': t['type_trend'],
        'synthesis': t['type_synthesis'],
        'finding': t['type_finding'],
        'claim': t['type_claim'],
        'source': t['type_source'],
        'concept': t['type_concept'],
        'megatrend': t['type_megatrend'],
        'citation': t['type_citation'],
        'dimension': t['type_dimension'],
        'question': t['type_question'],
        'initial-question': t['type_initial_question'],
    }

    section_title = type_labels.get(entity_type, entity_type.title() + 's')
    section_id = entity_type + 's'

    html_parts = [
        f'<section id="{section_id}" class="entity-group">',
        f'<h2>{section_title}</h2>',
    ]

    # Render READMEs first (if present)
    if readmes and all_entities:
        sorted_readmes = sorted(
            readmes,
            key=lambda r: (r.get('is_dimension_scoped', False), r.get('dimension', ''))
        )
        for readme in sorted_readmes:
            html_parts.append(generate_readme_section(readme, all_entities))

    for entity in entities:
        html_parts.append(_render_entity_card(entity, entity_type, all_entities, t))

    html_parts.append('</section>')
    return '\n'.join(html_parts)


def generate_grouped_entity_panel(entity_type: str, entities: List[Dict],
                                   all_entities: Dict,
                                   readmes: List[Dict] = None,
                                   t: dict = None,
                                   panel_prefix: str = 'ctx') -> str:
    """Create HTML section for entities grouped by dimension and question.

    Used for findings and claims tabs to provide structured navigation
    matching the sidebar grouping.

    Args:
        entity_type: 'finding' or 'claim'
        entities: List of entity dicts
        all_entities: All loaded entities for resolution
        readmes: Optional README dicts for this entity type
        t: UI translations dict
        panel_prefix: ID prefix for context cards ('f-ctx' or 'c-ctx')

    Returns:
        HTML string for the grouped entity section
    """
    if not entities and not readmes:
        return ''

    if t is None:
        t = get_ui_translations('en')

    type_labels = {
        'finding': t['type_finding'],
        'claim': t['type_claim'],
    }

    section_title = type_labels.get(entity_type, entity_type.title() + 's')
    section_id = entity_type + 's'

    html_parts = [
        f'<section id="{section_id}" class="entity-group">',
        f'<h2>{section_title}</h2>',
    ]

    # Render READMEs first
    if readmes and all_entities:
        sorted_readmes = sorted(
            readmes,
            key=lambda r: (r.get('is_dimension_scoped', False), r.get('dimension', ''))
        )
        for readme in sorted_readmes:
            html_parts.append(generate_readme_section(readme, all_entities))

    # Group by dimension and question
    grouped, dim_info, q_info, ungrouped = build_dimension_question_grouping(
        entities, all_entities, entity_type=entity_type
    )

    for dim_id, questions in grouped.items():
        dim_entity = dim_info.get(dim_id, {})
        dim_title = dim_entity.get('title', dim_id.replace('-', ' ').title())
        dim_slug = dim_entity.get('metadata', {}).get('slug', dim_id)

        # Render dimension as full entity card if available, fallback to plain heading
        if dim_entity and dim_entity.get('id'):
            html_parts.append(_render_context_card(
                dim_entity, 'dimension', all_entities, t, panel_prefix=panel_prefix))
        else:
            html_parts.append(
                f'<div class="dimension-divider" id="dim-{html_lib.escape(dim_slug)}">'
                f'<h3 class="dimension-heading">{html_lib.escape(dim_title)}</h3>'
                f'</div>'
            )

        for q_key, q_entities in questions.items():
            if q_key != '_none' and q_key in q_info:
                q_entity = q_info[q_key]
                # Render question as full entity card with panel-prefixed ID
                html_parts.append(_render_context_card(
                    q_entity, 'question', all_entities, t, panel_prefix=panel_prefix))

            for entity in q_entities:
                html_parts.append(_render_entity_card(entity, entity_type, all_entities, t))

    # Ungrouped entities at end
    if ungrouped:
        html_parts.append(
            f'<div class="dimension-divider">'
            f'<h3 class="dimension-heading">{html_lib.escape(t["nav_other"])}</h3>'
            f'</div>'
        )
        for entity in sorted(ungrouped, key=lambda e: e.get('title', e['id']).lower()):
            html_parts.append(_render_entity_card(entity, entity_type, all_entities, t))

    html_parts.append('</section>')
    return '\n'.join(html_parts)


def generate_readme_section(readme: Dict, all_entities: Dict) -> str:
    """Create HTML for a README document.

    Args:
        readme: README data dict
        all_entities: All entities for wikilink resolution

    Returns:
        HTML string for the README article
    """
    readme_id = readme['id']
    title = readme.get('title', readme_id)
    body = readme.get('body', '')
    is_dimension_scoped = readme.get('is_dimension_scoped', False)

    # Convert markdown to HTML
    body_html = simple_markdown_to_html(body)

    # Resolve wikilinks
    body_html = convert_wikilinks_to_anchors(body_html, all_entities)

    # Build CSS classes
    css_classes = 'entity-section readme'
    if is_dimension_scoped:
        css_classes += ' readme-dimension'

    # Build badges
    badges_html = ''
    if is_dimension_scoped:
        dimension = readme.get('dimension', '')
        if dimension:
            badges_html += f'<span class="badge dimension">{html_lib.escape(dimension)}</span>'

    metadata = readme.get('metadata', {})
    if 'finding_count' in metadata:
        badges_html += f'<span class="badge finding-count">{metadata["finding_count"]} findings</span>'
    if 'question_count' in metadata:
        badges_html += f'<span class="badge">{metadata["question_count"]} questions</span>'
    if 'source_count' in metadata:
        badges_html += f'<span class="badge">{metadata["source_count"]} sources</span>'
    if 'claim_count' in metadata:
        badges_html += f'<span class="badge">{metadata["claim_count"]} claims</span>'

    return f'''
    <article id="{readme_id}" class="{css_classes}">
        <header class="entity-header">
            <h3>{html_lib.escape(title)}</h3>
            <div class="entity-badges">{badges_html}</div>
        </header>
        <div class="entity-content">
            {body_html}
        </div>
    </article>
    '''


def clean_insight_headings(html: str) -> str:
    """Remove redundant H1 heading from insight body.

    The hero section already renders the title as H2, so the H1 in the
    markdown body is a duplicate and should be stripped.  H2 section
    headings are kept — they provide the visible content structure.

    Args:
        html: HTML content to clean

    Returns:
        Cleaned HTML with first H1 removed
    """
    # Remove first H1 heading (duplicates hero title)
    html = re.sub(r'<h1[^>]*>.*?</h1>\s*', '', html, count=1, flags=re.DOTALL)

    return html


def generate_insight_hero_section(insight_data: Dict, all_entities: Dict,
                                  cards_html: str = '') -> str:
    """Create hero-style HTML for insight-summary.md.

    Args:
        insight_data: Insight summary data dict with title, body, metadata
        all_entities: All entities for wikilink resolution
        cards_html: Pre-rendered stats grid HTML to insert between narrative and bridge

    Returns:
        HTML string for the insight hero section
    """
    title = insight_data.get('title', 'Insight Summary')
    body = insight_data.get('body', '')
    story_arc = insight_data.get('story_arc', 'unknown')
    word_count = insight_data.get('word_count', 0)
    research_type = insight_data.get('research_type', 'General Research')

    # Strip trailing references after last --- separator
    if '\n---\n' in body:
        candidate_body, trailing = body.rsplit('\n---\n', 1)
        trailing_stripped = trailing.strip()
        # Only strip if trailing content is a references section (has wikilinks,
        # doesn't start with ## heading). Narrative H2 sections must be kept.
        if trailing_stripped and not trailing_stripped.startswith('##') and \
           '[[' in trailing_stripped:
            main_body = candidate_body
        else:
            main_body = body
    elif body.rstrip().endswith('\n---'):
        main_body = body.rsplit('---', 1)[0]
    else:
        main_body = body

    # Strip stats grid (rendered as styled cards, not as inline HTML)
    main_body = strip_stats_grid_from_body(main_body)

    # Convert markdown to HTML
    body_html = simple_markdown_to_html(main_body)

    # Clean redundant headings from body
    body_html = clean_insight_headings(body_html)

    # Resolve wikilinks
    body_html = convert_wikilinks_to_anchors(body_html, all_entities)

    # Build bridge navigation (v3.0: removed Research Report link, points to entity catalog)
    bridge_html = '''
    <div class="insight-bridge">
        <p class="bridge-text">Explore the full research catalog with detailed findings, concepts, and analysis below.</p>
    </div>'''

    # Insert cards after opening paragraph(s), before first H2 section
    # Split at first <h2 to place cards between intro and arc sections
    h2_split = re.split(r'(?=<h2[ >])', body_html, maxsplit=1)
    if len(h2_split) == 2 and cards_html:
        body_with_cards = h2_split[0] + cards_html + h2_split[1]
    else:
        # No H2 found or no cards: append cards after body
        body_with_cards = body_html + cards_html

    # Build metadata badges (story arc, research type, word count)
    metadata_html = ''
    if story_arc and story_arc != 'unknown':
        metadata_html = f'''
        <div class="insight-metadata">
            <span class="insight-story-arc-badge">{html_lib.escape(str(story_arc))}</span>
            <span class="insight-research-type">{html_lib.escape(str(research_type))}</span>
            <span class="insight-word-count">{html_lib.escape(str(word_count))} words</span>
        </div>'''

    return f'''
    <section id="insight-summary" class="insight-hero">
        {metadata_html}
        <h2>{html_lib.escape(title)}</h2>
        <div class="insight-content">
            {body_with_cards}
        </div>
        {bridge_html}
    </section>
    '''


def load_theme_css(theme_path: Path) -> str:
    """Extract CSS variables from theme or generated variables.css.

    Checks generated/variables.css first (cogni-workplace theme pipeline),
    then falls back to parsing CSS block in theme.md, then hardcoded defaults.

    Args:
        theme_path: Path to theme.md file

    Returns:
        CSS string with :root variables
    """
    # Try generated/variables.css first (from cogni-workplace theme pipeline)
    theme_id = theme_path.parent.name
    for ancestor in [theme_path.parent.parent.parent, theme_path.parent.parent]:
        generated_css = ancestor / 'generated' / theme_id / 'variables.css'
        if generated_css.exists():
            try:
                return generated_css.read_text(encoding='utf-8')
            except Exception:
                pass

    # Fall back to CSS block in theme.md
    try:
        content = theme_path.read_text(encoding='utf-8')

        # Find CSS code block after "## CSS Variable Reference"
        pattern = r'## CSS Variable Reference.*?```css\n(.*?)```'
        match = re.search(pattern, content, re.DOTALL)

        if match:
            return match.group(1).strip()
    except Exception as e:
        print(f"Warning: Failed to load theme from {theme_path}: {e}")

    return get_fallback_css()


def get_fallback_css() -> str:
    """Return fallback CSS variables if theme not found."""
    return '''
:root {
    /* Primary Family */
    --color-primary: #0d3c55;
    --color-primary-dark: #091f2c;
    --color-primary-light: #1a5276;

    /* Accent Family */
    --color-accent: #00d7e9;
    --color-accent-light: #4de8f4;
    --color-accent-dark: #00b8d4;

    /* Background Family */
    --color-bg-primary: #ffffff;
    --color-bg-secondary: #f8fafb;
    --color-bg-tertiary: #e8f4f8;
    --color-bg-code: #f0f4f7;

    /* Text Family */
    --color-text-primary: #0d3c55;
    --color-text-secondary: #2c5364;
    --color-text-muted: #5a7a8a;
    --color-text-tertiary: #8a9fad;
    --color-text-light: #ffffff;

    /* Border Family */
    --color-border: #d4dfe5;
    --color-border-hover: #b8c9d4;
    --color-border-focus: #00d7e9;

    /* Status Colors */
    --color-success: #2E7D32;
    --color-success-light: #e8f5e9;
    --color-warning: #ED6C02;
    --color-info: #00d7e9;
    --color-info-bg: #e0f7fa;

    /* Semantic Aliases */
    --color-background: #ffffff;
    --color-background-alt: #f8fafb;
    --color-text: #0d3c55;

    /* Typography */
    --font-primary: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-heading: Georgia, 'Times New Roman', serif;
    --font-mono: 'SF Mono', 'Fira Code', Consolas, monospace;

    /* Spacing */
    --spacing-xs: 0.25rem;
    --spacing-sm: 0.5rem;
    --spacing-md: 1rem;
    --spacing-lg: 1.5rem;
    --spacing-xl: 2rem;
    --spacing-2xl: 3rem;

    /* Shadows */
    --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.04);
    --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 10px rgba(0, 0, 0, 0.06);

    /* Border Radius */
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;

    /* Badge Tinted Backgrounds */
    --color-badge-dimension: rgba(13, 60, 85, 0.09);
    --color-badge-horizon-act: rgba(46, 125, 50, 0.09);
    --color-badge-horizon-plan: rgba(237, 108, 2, 0.09);
    --color-badge-horizon-observe: rgba(90, 122, 138, 0.08);
    --color-badge-evidence-strong: rgba(46, 125, 50, 0.09);
    --color-badge-evidence-moderate: rgba(237, 108, 2, 0.09);
    --color-badge-evidence-weak: rgba(192, 57, 43, 0.09);
    --color-badge-confidence: rgba(0, 215, 233, 0.09);
    --color-badge-verified: rgba(46, 125, 50, 0.09);
    --color-badge-contradicted: rgba(192, 57, 43, 0.09);

    /* Dimension Palette */
    --color-dim-1: #00b8d4;
    --color-dim-2: #5b2c6f;
    --color-dim-3: #1e8449;
    --color-dim-4: #ff6b4a;
    --color-dim-5: #3b82f6;
    --color-dim-6: #8b5cf6;
    --color-dim-7: #ec4899;
    --color-dim-8: #f59e0b;
}
'''


def resolve_theme_path(theme_id: str, theme_root: str = None) -> Path:
    """Find theme.md file for given theme ID.

    Searches in order:
    1. Custom theme_root if provided (--theme-root CLI arg)
    2. $COGNI_WORKPLACE_ROOT/themes/{theme_id}/theme.md
    3. Relative to script
    4. Common installation paths

    Args:
        theme_id: Theme identifier (e.g., 'digital-x', 'telekom')
        theme_root: Optional custom theme root directory

    Returns:
        Path to theme.md

    Raises:
        FileNotFoundError: If theme not found, with list of available themes
    """
    possible_roots = []
    searched_paths = []

    # Custom theme root (highest priority)
    if theme_root:
        custom_root = Path(theme_root).resolve()
        if custom_root.exists():
            possible_roots.append(custom_root)

    # Environment variable (higher priority than script-relative)
    workplace_root = os.environ.get('COGNI_WORKPLACE_ROOT', '')
    if workplace_root:
        possible_roots.append(Path(workplace_root))

    # Relative to script (deterministic, workspace-agnostic)
    script_dir = Path(__file__).resolve().parent
    possible_roots.extend([
        script_dir.parent.parent.parent.parent / 'cogni-workplace',
        script_dir.parent.parent.parent / 'cogni-workplace',
    ])

    # Common paths (fallback only)
    possible_roots.extend([
        Path.home() / '.claude/plugins/marketplaces/cogni-workplace/cogni-workplace',
        Path.home() / 'GitHub/cogni-research/cogni-workplace',
    ])

    # Search all locations and collect available themes for error message
    available_themes = set()
    for root in possible_roots:
        if not root or not root.exists():
            continue

        themes_dir = root / 'themes'
        if not themes_dir.exists():
            continue

        theme_path = themes_dir / theme_id / 'theme.md'
        searched_paths.append(str(theme_path))

        if theme_path.exists():
            return theme_path

        # Collect available themes for error message
        try:
            for theme_dir in themes_dir.iterdir():
                if theme_dir.is_dir() and not theme_dir.name.startswith('_'):
                    theme_md = theme_dir / 'theme.md'
                    if theme_md.exists():
                        available_themes.add(theme_dir.name)
        except Exception:
            pass

    # Theme not found - provide helpful error with available themes
    error_msg = f"Theme '{theme_id}' not found."
    if available_themes:
        themes_list = ', '.join(sorted(available_themes))
        error_msg += f"\n\nAvailable themes: {themes_list}"
    error_msg += f"\n\nSearched paths:\n" + '\n'.join(f"  - {p}" for p in searched_paths)
    raise FileNotFoundError(error_msg)


def get_themes_root(theme_root: str = None) -> List[Path]:
    """Find all themes directory roots across all workspace locations.

    Returns list of all existing theme directories instead of just first match.
    This enables multi-workspace theme discovery.
    """
    possible_roots = []

    # Custom theme root (highest priority)
    if theme_root:
        custom_root = Path(theme_root).resolve()
        if custom_root.exists():
            # Check if this is a themes dir or parent
            if custom_root.name == 'themes':
                possible_roots.append(custom_root)
            else:
                themes_subdir = custom_root / 'themes'
                if themes_subdir.exists():
                    possible_roots.append(themes_subdir)
                else:
                    possible_roots.append(custom_root)

    # Environment variable
    workplace_root = os.environ.get('COGNI_WORKPLACE_ROOT', '')
    if workplace_root:
        themes_dir = Path(workplace_root) / 'themes'
        if themes_dir.exists():
            possible_roots.append(themes_dir)

    # Relative to script
    script_dir = Path(__file__).resolve().parent
    for rel_path in [
        script_dir.parent.parent.parent.parent / 'cogni-workplace' / 'themes',
        script_dir.parent.parent.parent / 'cogni-workplace' / 'themes',
    ]:
        if rel_path.exists() and rel_path not in possible_roots:
            possible_roots.append(rel_path)

    # Common paths
    common_paths = [
        Path.home() / '.claude/plugins/marketplaces/cogni-workplace/cogni-workplace/themes',
        Path.home() / 'GitHub/cogni-research/cogni-workplace/themes',
    ]
    for path in common_paths:
        if path.exists() and path not in possible_roots:
            possible_roots.append(path)

    return possible_roots


def parse_theme_frontmatter(content: str) -> Dict[str, str]:
    """Parse YAML frontmatter from theme.md content."""
    frontmatter = {}
    if content.startswith('---'):
        parts = content.split('---', 2)
        if len(parts) >= 3:
            yaml_content = parts[1].strip()
            for line in yaml_content.split('\n'):
                if ':' in line:
                    key, value = line.split(':', 1)
                    frontmatter[key.strip()] = value.strip()
    return frontmatter


def parse_overview_table(content: str) -> Dict[str, str]:
    """Extract key-value pairs from Overview table in theme.md."""
    overview = {}
    # Find ## Overview section and parse table
    overview_match = re.search(r'## Overview\s*\n\s*\|[^\n]+\n\s*\|[-|]+\n((?:\|[^\n]+\n?)+)', content)
    if overview_match:
        table_rows = overview_match.group(1).strip().split('\n')
        for row in table_rows:
            cells = [c.strip() for c in row.split('|')[1:-1]]
            if len(cells) >= 2:
                key = cells[0].strip()
                value = cells[1].strip()
                if key == 'Style':
                    overview['style'] = value
                elif key == 'Primary Color':
                    hex_match = re.search(r'#[0-9A-Fa-f]{6}', value)
                    overview['primary_color'] = hex_match.group(0) if hex_match else value
                elif 'Accent' in key and 'Color' in key:
                    hex_match = re.search(r'#[0-9A-Fa-f]{6}', value)
                    overview['accent_color'] = hex_match.group(0) if hex_match else value
                elif key == 'Font Family':
                    overview['font_family'] = value
    return overview


def discover_themes(theme_root: str = None) -> Dict[str, Any]:
    """Discover all available themes and extract metadata from all workspace locations.

    Scans ALL themes directories across workspaces and parses each theme.md file to extract:
    - theme_id, theme_name, customer from YAML frontmatter
    - style, primary_color, accent_color, font_family from Overview table
    - description from first paragraph after title
    - source location for debugging

    Deduplicates by theme_id (first found wins).
    Excludes directories starting with '_' (e.g., _template).
    """
    themes_dirs = get_themes_root(theme_root)

    if not themes_dirs:
        return {
            'themes': [],
            'searched_locations': [],
            'count': 0,
            'error': 'No themes directories found'
        }

    themes_by_id = {}  # Deduplicate by theme_id
    searched_locations = []

    # Search all theme directories
    for themes_dir in themes_dirs:
        searched_locations.append(str(themes_dir))

        for theme_dir in sorted(themes_dir.iterdir()):
            if not theme_dir.is_dir():
                continue
            if theme_dir.name.startswith('_'):
                continue  # Skip _template and other internal dirs

            theme_md = theme_dir / 'theme.md'
            if not theme_md.exists():
                continue

            try:
                content = theme_md.read_text(encoding='utf-8')
            except Exception:
                continue

            frontmatter = parse_theme_frontmatter(content)
            overview = parse_overview_table(content)

            # Extract description from first paragraph after title
            desc_match = re.search(r'^# .+\n\n(.+?)(?:\n\n|\n##)', content, re.MULTILINE)
            description = desc_match.group(1).strip() if desc_match else ''
            # Truncate long descriptions
            if len(description) > 150:
                description = description[:147] + '...'

            theme_id = frontmatter.get('theme_id', theme_dir.name)

            # Deduplicate - first found wins
            if theme_id not in themes_by_id:
                themes_by_id[theme_id] = {
                    'theme_id': theme_id,
                    'theme_name': frontmatter.get('theme_name', theme_dir.name.replace('-', ' ').title()),
                    'customer': frontmatter.get('customer', ''),
                    'description': description,
                    'style': overview.get('style', ''),
                    'primary_color': overview.get('primary_color', ''),
                    'accent_color': overview.get('accent_color', ''),
                    'font_family': overview.get('font_family', ''),
                    'source': str(themes_dir),
                    'path': str(theme_md)
                }

    themes = sorted(themes_by_id.values(), key=lambda t: t['theme_id'])

    return {
        'themes': themes,
        'searched_locations': searched_locations,
        'count': len(themes)
    }


def load_layout_css() -> str:
    """Load the layout CSS from assets directory."""
    script_dir = Path(__file__).resolve().parent
    css_path = script_dir.parent / 'assets' / 'report-layout.css'

    if css_path.exists():
        return css_path.read_text(encoding='utf-8')

    # Fallback - return minimal layout
    return '''
/* Minimal fallback layout */
body { font-family: var(--font-primary); margin: 0; }
.report-container { max-width: 1200px; margin: 0 auto; padding: var(--spacing-xl); }
'''


def load_navigation_js() -> str:
    """Load the navigation JavaScript from assets directory."""
    script_dir = Path(__file__).resolve().parent
    js_path = script_dir.parent / 'assets' / 'report.js'

    if js_path.exists():
        return js_path.read_text(encoding='utf-8')

    # Fallback - return minimal JS
    return '''
// Minimal fallback navigation
document.querySelectorAll('.report-toc a').forEach(a => {
    a.addEventListener('click', e => {
        e.preventDefault();
        const target = document.querySelector(a.getAttribute('href'));
        if (target) target.scrollIntoView({ behavior: 'smooth' });
    });
});
'''


def truncate_title(title: str, max_len: int = 40) -> str:
    """Truncate title for TOC display."""
    if len(title) <= max_len:
        return title
    return title[:max_len-3] + '...'


def generate_toc(report_headings: List[Dict], entity_types: List[str],
                 readmes_by_type: Dict[str, List[Dict]] = None,
                 entities_by_type: Dict[str, List[Dict]] = None,
                 supporting_files: Dict[str, Dict] = None,
                 t: dict = None) -> str:
    """Generate table of contents HTML with collapsible entity groups.

    Args:
        report_headings: List of dicts with 'id', 'text', 'level' from report
        entity_types: List of entity type strings that have content
        readmes_by_type: Dict mapping entity type to list of readme dicts
        entities_by_type: Dict mapping entity type to list of entity dicts
        supporting_files: Dict of supporting files (v3.0 hub ecosystem)
        t: UI translations dict

    Returns:
        HTML string for TOC navigation
    """
    if readmes_by_type is None:
        readmes_by_type = {}
    if entities_by_type is None:
        entities_by_type = {}
    if supporting_files is None:
        supporting_files = {}
    if t is None:
        t = get_ui_translations('en')

    # Entity types that have dimension grouping
    dimension_grouped_types = {'trend', 'synthesis', 'claim'}

    html_parts = [
        '<nav class="report-toc">',
        f'<h2>{t["toc_contents"]}</h2>',
        '<ul>',
    ]

    # Supporting files (v3.0) - render before entities
    if supporting_files:
        # Sort by order field (insight-summary first with order=-1, then executive-summary with order=0)
        sorted_supporting = sorted(supporting_files.items(), key=lambda x: x[1].get('order', 99))

        # Track if we've added consolidated section TOC entry
        added_consolidated_toc = False

        for file_id, file_data in sorted_supporting:
            # Skip order=99 files (will be grouped into consolidated section)
            if file_data.get('order') == 99:
                if not added_consolidated_toc:
                    html_parts.append(f'<li><a href="#research-metadata-methodology">{t["toc_methodology_section"]}</a></li>')
                    added_consolidated_toc = True
                continue

            title = file_data.get('title', file_id)
            file_type = file_data.get('type', 'hub-supporting')

            # Add special styling for insight-summary and executive-summary
            if file_type == 'insight-summary':
                css_class = ' class="toc-insight-summary"'
            elif file_type == 'executive-summary':
                css_class = ' class="executive-summary-link"'
            else:
                css_class = ''
            html_parts.append(f'<li{css_class}><a href="#{file_id}">{html_lib.escape(title)}</a></li>')

    # Research Report section REMOVED in v3.0 - no longer in TOC or content

    # Entity sections
    type_labels = {
        'trend': t['type_trend'],
        'synthesis': t['type_synthesis'],
        'finding': t['type_finding'],
        'claim': t['type_claim'],
        'source': t['type_source'],
        'concept': t['type_concept'],
        'megatrend': t['type_megatrend'],
        'citation': t['type_citation'],
        'dimension': t['type_dimension'],
        'question': t['type_question'],
        'initial-question': t['type_initial_question'],
    }

    for entity_type in entity_types:
        label = type_labels.get(entity_type, entity_type.title() + 's')
        section_id = entity_type + 's'
        type_readmes = readmes_by_type.get(entity_type, [])
        type_entities = entities_by_type.get(entity_type, [])

        # Check if we have sub-items (readmes or entities)
        has_sub_items = bool(type_readmes) or bool(type_entities)

        if has_sub_items:
            # Collapsible group
            group_id = f'toc-{entity_type}-entities'
            html_parts.append(f'<li class="toc-group">')
            html_parts.append(f'<span class="toc-toggle" data-target="{group_id}">&#9654;</span>')
            html_parts.append(f'<a href="#{section_id}">{label}</a>')
            html_parts.append(f'<ul id="{group_id}" class="toc-collapsible collapsed">')

            # Sort readmes: main README first, then dimension READMEs alphabetically
            sorted_readmes = sorted(
                type_readmes,
                key=lambda r: (r.get('is_dimension_scoped', False), r.get('dimension', ''))
            )

            # Group entities by dimension for dimension-grouped types (trend, claim)
            # Note: synthesis entities are dimension-level documents themselves, list them directly
            if entity_type in dimension_grouped_types and entity_type != 'synthesis':
                entities_by_dimension = {}
                ungrouped_entities = []
                for entity in type_entities:
                    dim = entity.get('metadata', {}).get('dimension', '')
                    if dim:
                        if dim not in entities_by_dimension:
                            entities_by_dimension[dim] = []
                        entities_by_dimension[dim].append(entity)
                    else:
                        ungrouped_entities.append(entity)

                # Add main README (Overview) first if present
                for readme in sorted_readmes:
                    if not readme.get('is_dimension_scoped'):
                        readme_id = readme['id']
                        html_parts.append(
                            f'<li><a href="#{readme_id}">{t["toc_overview"]}</a></li>'
                        )

                # Add dimension-scoped READMEs with their entities
                for readme in sorted_readmes:
                    if readme.get('is_dimension_scoped'):
                        readme_id = readme['id']
                        dim_slug = readme.get('dimension', '')
                        display_title = dim_slug or readme.get('title', 'Dimension')

                        # Check if there are entities for this dimension
                        dim_entities = entities_by_dimension.get(dim_slug, [])

                        if dim_entities:
                            # Collapsible dimension group
                            dim_group_id = f'toc-{entity_type}-dim-{dim_slug}'
                            html_parts.append(f'<li class="toc-dimension-group">')
                            html_parts.append(f'<span class="toc-toggle" data-target="{dim_group_id}">&#9654;</span>')
                            html_parts.append(f'<a href="#{readme_id}">{html_lib.escape(display_title)}</a>')
                            html_parts.append(f'<ul id="{dim_group_id}" class="toc-collapsible collapsed">')

                            # Add entities for this dimension
                            for entity in sorted(dim_entities, key=lambda e: e.get('title', e['id'])):
                                entity_id = entity['id']
                                entity_title = truncate_title(entity.get('title', entity_id))
                                html_parts.append(
                                    f'<li class="toc-entity-item"><a href="#{entity_id}" class="toc-entity-link" title="{html_lib.escape(entity.get("title", entity_id))}">{html_lib.escape(entity_title)}</a></li>'
                                )

                            html_parts.append('</ul>')
                            html_parts.append('</li>')
                        else:
                            # No entities, just the README link
                            html_parts.append(
                                f'<li><a href="#{readme_id}">{html_lib.escape(display_title)}</a></li>'
                            )

                # Add ungrouped entities at the end
                if ungrouped_entities:
                    for entity in sorted(ungrouped_entities, key=lambda e: e.get('title', e['id'])):
                        entity_id = entity['id']
                        entity_title = truncate_title(entity.get('title', entity_id))
                        html_parts.append(
                            f'<li class="toc-entity-item"><a href="#{entity_id}" class="toc-entity-link" title="{html_lib.escape(entity.get("title", entity_id))}">{html_lib.escape(entity_title)}</a></li>'
                        )

            else:
                # Non-dimension-grouped types: list READMEs then all entities directly
                for readme in sorted_readmes:
                    readme_id = readme['id']
                    if readme.get('is_dimension_scoped'):
                        display_title = readme.get('dimension', readme.get('title', t['toc_overview']))
                    else:
                        display_title = t['toc_overview']
                    html_parts.append(
                        f'<li><a href="#{readme_id}">{html_lib.escape(display_title)}</a></li>'
                    )

                # Add all entities directly
                for entity in sorted(type_entities, key=lambda e: e.get('title', e['id'])):
                    entity_id = entity['id']
                    entity_title = truncate_title(entity.get('title', entity_id))
                    html_parts.append(
                        f'<li class="toc-entity-item"><a href="#{entity_id}" class="toc-entity-link" title="{html_lib.escape(entity.get("title", entity_id))}">{html_lib.escape(entity_title)}</a></li>'
                    )

            html_parts.append('</ul>')
            html_parts.append('</li>')
        else:
            # No sub-items, just a link
            html_parts.append(f'<li><a href="#{section_id}">{label}</a></li>')

    html_parts.extend([
        '</ul>',
        '</nav>',
    ])

    return '\n'.join(html_parts)


def generate_section_nav(entities_by_type: Dict[str, List[Dict]],
                         supporting_files: Dict[str, Dict] = None,
                         t: dict = None,
                         all_entities: Dict = None) -> str:
    """Generate persistent left sidebar with per-tab navigation groups.

    Each .section-nav-items[data-tab] block holds anchor links for that tab.
    JavaScript controls which group is visible based on the active tab.

    Args:
        entities_by_type: Dict mapping entity type to list of entity dicts
        supporting_files: Dict of supporting file data (insight-summary, exec summary, etc.)
        t: UI translations dict

    Returns:
        HTML string for the full <nav class="section-nav"> element
    """
    if t is None:
        t = get_ui_translations('en')
    if supporting_files is None:
        supporting_files = {}

    def make_link(href_id: str, title: str, max_len: int = 36) -> str:
        short = truncate_title(title, max_len)
        return (f'<a class="section-nav-link" href="#{href_id}" '
                f'title="{html_lib.escape(title)}">{html_lib.escape(short)}</a>')

    # --- Overview nav items ---
    overview_items = []
    if 'insight-summary' in supporting_files:
        insight_title = supporting_files['insight-summary'].get('title', 'Summary')
        overview_items.append(make_link('insight-summary', insight_title))
        # Extract h2 sub-sections from rendered insight-summary body
        body_html = supporting_files['insight-summary'].get('body_html', '')
        for h2_match in re.finditer(r'<h2\s+id="([^"]+)"[^>]*>(.*?)</h2>', body_html):
            h2_id = h2_match.group(1)
            h2_text = re.sub(r'<[^>]+>', '', h2_match.group(2)).strip()
            if h2_text:
                overview_items.append(make_link(h2_id, h2_text))
    for file_id, file_data in sorted(supporting_files.items(),
                                      key=lambda x: x[1].get('order', 99)):
        if file_id == 'insight-summary':
            continue
        if file_data.get('order') == 99:
            continue
        overview_items.append(make_link(file_id, file_data.get('title', file_id)))

    # --- Synthesis (Dimensions) nav items ---
    synthesis_items = []
    for entity in entities_by_type.get('synthesis', []):
        entity_id = entity['id']
        title = entity.get('title', entity_id)
        short_title = title
        for prefix in ('Dimension Synthesis: ', 'Dimensionssynthese: ', 'Synthesis: '):
            if short_title.startswith(prefix):
                short_title = short_title[len(prefix):]
                break
        synthesis_items.append(make_link(entity_id, short_title))

    # --- Megatrends nav items ---
    megatrend_items = []
    for entity in entities_by_type.get('megatrend', []):
        megatrend_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Trends nav items (grouped by dimension, sorted by horizon) ---
    horizon_order = {'act': 0, 'plan': 1, 'observe': 2}
    dim_trends: Dict[str, list] = {}
    for entity in entities_by_type.get('trend', []):
        meta = entity.get('metadata', {})
        dim_slug = meta.get('dimension', '') or ''
        # Strip hash suffix for display (e.g. "digitales-fundament-d19d6cf8" -> "digitales-fundament")
        dim_label = re.sub(r'-[0-9a-f]{6,}$', '', dim_slug) if dim_slug else ''
        horizon = normalize_horizon(meta.get('planning_horizon', ''))
        dim_trends.setdefault(dim_label, []).append((horizon, entity))
    # Sort dimensions alphabetically, trends within each by horizon
    trend_items = []
    for dim_label in sorted(dim_trends.keys()):
        if dim_label:
            display_label = dim_label.replace('-', ' ').title()
            trend_items.append(
                f'<div class="section-nav-dimension">{html_lib.escape(display_label)}</div>'
            )
        entries = sorted(dim_trends[dim_label], key=lambda x: horizon_order.get(x[0], 1))
        for horizon, entity in entries:
            title = truncate_title(entity.get('title', entity['id']), 30)
            tag = f'<span class="nav-horizon-tag">{horizon}</span> '
            trend_items.append(
                f'<a class="section-nav-link" href="#{entity["id"]}" '
                f'title="{html_lib.escape(entity.get("title", entity["id"]))}">'
                f'{tag}{html_lib.escape(title)}</a>'
            )

    # --- Findings nav items (grouped by dimension → question, collapsible) ---
    finding_items = []
    if all_entities and entities_by_type.get('finding'):
        grouped, dim_info, q_info, ungrouped = build_dimension_question_grouping(
            entities_by_type['finding'], all_entities, entity_type='finding'
        )
        for dim_id, questions in grouped.items():
            dim_entity = dim_info.get(dim_id, {})
            dim_title = dim_entity.get('title', dim_id.replace('-', ' ').title())
            finding_items.append('<div class="nav-dim-group">')
            # Dimension header with clickable link to context card + toggle icon
            if dim_entity.get('id'):
                finding_items.append(
                    f'<div class="section-nav-dimension">'
                    f'<span class="nav-toggle-icon"></span>'
                    f'<a class="section-nav-link dim-link" href="#f-ctx-{html_lib.escape(dim_entity["id"])}"'
                    f' title="{html_lib.escape(dim_title)}">{html_lib.escape(dim_title)}</a></div>'
                )
            else:
                finding_items.append(
                    f'<div class="section-nav-dimension">'
                    f'<span class="nav-toggle-icon"></span>{html_lib.escape(dim_title)}</div>'
                )
            finding_items.append('<div class="nav-dim-children">')
            for q_key, q_entities in questions.items():
                if q_key != '_none' and q_key in q_info:
                    q_entity = q_info[q_key]
                    q_title = q_entity.get('title', q_key)
                    q_short = truncate_title(q_title, 34)
                    finding_items.append('<div class="nav-q-group">')
                    # Question header with clickable link to context card + toggle icon
                    if q_entity.get('id'):
                        finding_items.append(
                            f'<div class="section-nav-question" title="{html_lib.escape(q_title)}">'
                            f'<span class="nav-toggle-icon"></span>'
                            f'<a class="section-nav-link q-link" href="#f-ctx-{html_lib.escape(q_entity["id"])}"'
                            f' title="{html_lib.escape(q_title)}">{html_lib.escape(q_short)}</a></div>'
                        )
                    else:
                        finding_items.append(
                            f'<div class="section-nav-question" title="{html_lib.escape(q_title)}">'
                            f'<span class="nav-toggle-icon"></span>{html_lib.escape(q_short)}</div>'
                        )
                    finding_items.append('<div class="nav-q-children">')
                    for entity in q_entities:
                        finding_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
                    finding_items.append('</div></div>')  # close nav-q-children + nav-q-group
                else:
                    # _none question: links go directly into dim-children
                    for entity in q_entities:
                        finding_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
            finding_items.append('</div></div>')  # close nav-dim-children + nav-dim-group
        if ungrouped:
            finding_items.append('<div class="nav-dim-group">')
            finding_items.append(
                f'<div class="section-nav-dimension">'
                f'<span class="nav-toggle-icon"></span>{html_lib.escape(t["nav_other"])}</div>'
            )
            finding_items.append('<div class="nav-dim-children">')
            for entity in sorted(ungrouped, key=lambda e: e.get('title', e['id']).lower()):
                finding_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
            finding_items.append('</div></div>')  # close nav-dim-children + nav-dim-group
    else:
        for entity in entities_by_type.get('finding', []):
            finding_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Claims nav items (grouped by dimension → question, collapsible) ---
    claim_items = []
    if all_entities and entities_by_type.get('claim'):
        grouped, dim_info, q_info, ungrouped = build_dimension_question_grouping(
            entities_by_type['claim'], all_entities, entity_type='claim'
        )
        for dim_id, questions in grouped.items():
            dim_entity = dim_info.get(dim_id, {})
            dim_title = dim_entity.get('title', dim_id.replace('-', ' ').title())
            claim_items.append('<div class="nav-dim-group">')
            # Dimension header with clickable link to context card + toggle icon
            if dim_entity.get('id'):
                claim_items.append(
                    f'<div class="section-nav-dimension">'
                    f'<span class="nav-toggle-icon"></span>'
                    f'<a class="section-nav-link dim-link" href="#c-ctx-{html_lib.escape(dim_entity["id"])}"'
                    f' title="{html_lib.escape(dim_title)}">{html_lib.escape(dim_title)}</a></div>'
                )
            else:
                claim_items.append(
                    f'<div class="section-nav-dimension">'
                    f'<span class="nav-toggle-icon"></span>{html_lib.escape(dim_title)}</div>'
                )
            claim_items.append('<div class="nav-dim-children">')
            for q_key, q_entities in questions.items():
                if q_key != '_none' and q_key in q_info:
                    q_entity = q_info[q_key]
                    q_title = q_entity.get('title', q_key)
                    q_short = truncate_title(q_title, 34)
                    claim_items.append('<div class="nav-q-group">')
                    # Question header with clickable link to context card + toggle icon
                    if q_entity.get('id'):
                        claim_items.append(
                            f'<div class="section-nav-question" title="{html_lib.escape(q_title)}">'
                            f'<span class="nav-toggle-icon"></span>'
                            f'<a class="section-nav-link q-link" href="#c-ctx-{html_lib.escape(q_entity["id"])}"'
                            f' title="{html_lib.escape(q_title)}">{html_lib.escape(q_short)}</a></div>'
                        )
                    else:
                        claim_items.append(
                            f'<div class="section-nav-question" title="{html_lib.escape(q_title)}">'
                            f'<span class="nav-toggle-icon"></span>{html_lib.escape(q_short)}</div>'
                        )
                    claim_items.append('<div class="nav-q-children">')
                    for entity in q_entities:
                        claim_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
                    claim_items.append('</div></div>')  # close nav-q-children + nav-q-group
                else:
                    # _none question: links go directly into dim-children
                    for entity in q_entities:
                        claim_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
            claim_items.append('</div></div>')  # close nav-dim-children + nav-dim-group
        if ungrouped:
            claim_items.append('<div class="nav-dim-group">')
            claim_items.append(
                f'<div class="section-nav-dimension">'
                f'<span class="nav-toggle-icon"></span>{html_lib.escape(t["nav_other"])}</div>'
            )
            claim_items.append('<div class="nav-dim-children">')
            for entity in sorted(ungrouped, key=lambda e: e.get('title', e['id']).lower()):
                claim_items.append(make_link(entity['id'], entity.get('title', entity['id'])))
            claim_items.append('</div></div>')  # close nav-dim-children + nav-dim-group
    else:
        for entity in entities_by_type.get('claim', []):
            claim_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Concepts nav items (grouped by category, sorted alphabetically) ---
    cat_concepts: Dict[str, list] = {}
    for entity in entities_by_type.get('concept', []):
        cat = entity.get('metadata', {}).get('category', '') or ''
        cat_concepts.setdefault(cat, []).append(entity)
    concept_items = []
    for cat_label in sorted(cat_concepts.keys(), key=str.lower):
        if cat_label:
            concept_items.append(
                f'<div class="section-nav-dimension">{html_lib.escape(cat_label)}</div>'
            )
        for entity in sorted(cat_concepts[cat_label],
                              key=lambda e: e.get('title', e['id']).lower()):
            concept_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Questions nav items ---
    question_items = []
    for et in ['question', 'dimension', 'initial-question']:
        for entity in entities_by_type.get(et, []):
            question_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Citations nav items ---
    citation_items = []
    for entity in entities_by_type.get('citation', []):
        citation_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    # --- Sources nav items ---
    source_items = []
    for entity in entities_by_type.get('source', []):
        source_items.append(make_link(entity['id'], entity.get('title', entity['id'])))

    def nav_group(tab_id: str, label: str, items: list) -> str:
        items_html = ''.join(items) if items else ''
        return (f'<div class="section-nav-items" data-tab="{tab_id}">'
                f'<div class="section-nav-title">{html_lib.escape(label)}</div>'
                f'{items_html}</div>')

    groups_html = (
        nav_group('overview', t['nav_title_overview'], overview_items) +
        nav_group('synthesis', t['nav_title_synthesis'], synthesis_items) +
        nav_group('megatrends', t['nav_title_megatrends'], megatrend_items) +
        nav_group('trends', t['nav_title_trends'], trend_items) +
        nav_group('concepts', t['detail_concepts'], concept_items) +
        nav_group('findings', t['detail_findings'], finding_items) +
        nav_group('claims', t['detail_claims'], claim_items) +
        nav_group('questions', t['detail_questions'], question_items) +
        nav_group('methodology', t['detail_methodology'], []) +
        nav_group('citations', t['detail_citations'], citation_items) +
        nav_group('sources', t['detail_sources'], source_items)
    )

    return f'''
    <nav class="section-nav" aria-label="{t['aria_section_nav']}">
        {groups_html}
    </nav>'''


def generate_navbar(project_title: str, entities_by_type: Dict[str, List[Dict]],
                    supporting_files: Dict[str, Dict] = None,
                    t: dict = None,
                    has_landing: bool = False) -> str:
    """Generate horizontal navbar with tab buttons including entity tabs and Anhang dropdown.

    Args:
        project_title: Report title for brand area
        entities_by_type: Dict mapping entity type to list of entity dicts (for counts)
        supporting_files: Supporting files dict (for methodology count)
        t: UI translations dict
        has_landing: Whether a landing page exists (enables brand as home button)

    Returns:
        HTML string for the navbar
    """
    if t is None:
        t = get_ui_translations('en')

    def count_html(count):
        return f'<span class="tab-count">{count}</span>' if count else ''

    synthesis_count = len(entities_by_type.get('synthesis', []))
    megatrend_count = len(entities_by_type.get('megatrend', []))
    trend_count = len(entities_by_type.get('trend', []))
    finding_count = len(entities_by_type.get('finding', []))
    claim_count = len(entities_by_type.get('claim', []))
    concept_count = len(entities_by_type.get('concept', []))
    question_count = sum(len(entities_by_type.get(et, []))
                         for et in ['question', 'dimension', 'initial-question'])
    methodology_count = len([f for f in (supporting_files or {}).values()
                             if f.get('order') == 99])
    citation_count = len(entities_by_type.get('citation', []))
    source_count = len(entities_by_type.get('source', []))

    # Main tabs (always visible in navbar)
    tabs = [
        ('overview',   t['tab_overview'],   ''),
        ('synthesis',  t['tab_dimensions'], count_html(synthesis_count)),
        ('megatrends', t['tab_megatrends'], count_html(megatrend_count)),
        ('trends',     t['tab_trends'],     count_html(trend_count)),
        ('concepts',   t['tab_concepts'],   count_html(concept_count)),
        ('findings',   t['tab_findings'],   count_html(finding_count)),
        ('claims',     t['tab_claims'],     count_html(claim_count)),
    ]

    tab_buttons = []
    for tab_id, label, cnt_html in tabs:
        selected = 'true' if tab_id == 'overview' else 'false'
        tab_buttons.append(
            f'<button class="navbar-tab" role="tab" data-tab="{tab_id}" '
            f'aria-selected="{selected}">{html_lib.escape(label)}{cnt_html}</button>'
        )

    # Anhang dropdown items
    appendix_items = [
        ('questions',    t['tab_questions'],    count_html(question_count)),
        ('methodology',  t['tab_methodology'],  count_html(methodology_count)),
        ('citations',    t['tab_citations'],    count_html(citation_count)),
        ('sources',      t['tab_sources'],      count_html(source_count)),
    ]

    dropdown_items_html = ''
    for item_id, item_label, item_cnt in appendix_items:
        dropdown_items_html += (
            f'<button class="navbar-dropdown-item" data-tab="{item_id}">'
            f'{html_lib.escape(item_label)}{item_cnt}</button>'
        )

    brand_class = 'navbar-brand has-landing' if has_landing else 'navbar-brand'
    brand_attrs = (f' role="button" tabindex="0" aria-label="{t["aria_back_to_landing"]}"'
                   if has_landing else '')

    return f'''
    <nav class="report-navbar" role="navigation" aria-label="{t['aria_report_nav']}">
        <div class="{brand_class}" title="{html_lib.escape(project_title)}"{brand_attrs}>{html_lib.escape(project_title)}</div>
        <button class="navbar-hamburger" aria-label="{t['aria_toggle_menu']}">&#9776;</button>
        <div class="navbar-tabs" role="tablist">
            {''.join(tab_buttons)}
            <div class="navbar-dropdown">
                <button class="navbar-tab navbar-dropdown-trigger" role="tab" aria-selected="false" aria-haspopup="true" aria-expanded="false">
                    {html_lib.escape(t['tab_appendix'])} &#9662;
                </button>
                <div class="navbar-dropdown-menu" role="menu">
                    {dropdown_items_html}
                </div>
            </div>
        </div>
    </nav>'''


def generate_overview_cards(entities_by_type: Dict[str, List[Dict]],
                            insight_metadata: Dict = None,
                            t: dict = None) -> str:
    """Generate the stats navigation cards grid.

    Args:
        entities_by_type: Entity counts for navigation cards
        insight_metadata: Optional insight-summary frontmatter with stats_* fields
        t: UI translations dict

    Returns:
        HTML string for the overview cards grid
    """
    if t is None:
        t = get_ui_translations('en')

    # Prefer stats from insight-summary frontmatter (single source of truth)
    if insight_metadata and insight_metadata.get('stats_syntheses') is not None:
        synthesis_count = int(insight_metadata.get('stats_syntheses', 0))
        megatrend_count = int(insight_metadata.get('stats_megatrends', 0))
        trend_count = int(insight_metadata.get('stats_trends', 0))
        concept_count = int(insight_metadata.get('stats_concepts', 0))
        finding_count = int(insight_metadata.get('stats_findings', 0))
        claim_count = int(insight_metadata.get('stats_claims', 0))
    else:
        # Fallback: count from entity lists (backward compatibility)
        synthesis_count = len(entities_by_type.get('synthesis', []))
        megatrend_count = len(entities_by_type.get('megatrend', []))
        trend_count = len(entities_by_type.get('trend', []))
        concept_count = len(entities_by_type.get('concept', []))
        finding_count = len(entities_by_type.get('finding', []))
        claim_count = len(entities_by_type.get('claim', []))

    return f'''
        <div class="overview-grid">
            <div class="overview-card" data-navigate="synthesis">
                <div class="card-stat">{synthesis_count}</div>
                <h3>{t['card_syntheses']}</h3>
            </div>
            <div class="overview-card" data-navigate="megatrends">
                <div class="card-stat">{megatrend_count}</div>
                <h3>{t['card_megatrends']}</h3>
            </div>
            <div class="overview-card" data-navigate="trends">
                <div class="card-stat">{trend_count}</div>
                <h3>{t['card_trends']}</h3>
            </div>
            <div class="overview-card" data-navigate="concepts">
                <div class="card-stat">{concept_count}</div>
                <h3>{t['card_concepts']}</h3>
            </div>
            <div class="overview-card" data-navigate="findings">
                <div class="card-stat">{finding_count}</div>
                <h3>{t['card_findings']}</h3>
            </div>
            <div class="overview-card" data-navigate="claims">
                <div class="card-stat">{claim_count}</div>
                <h3>{t['card_claims']}</h3>
            </div>
        </div>'''


def generate_overview_panel(insight_hero_html: str, supporting_sections_html: str,
                            cards_html: str = '',
                            t: dict = None) -> str:
    """Generate the Overview tab panel content.

    Args:
        insight_hero_html: Pre-rendered insight hero HTML
        supporting_sections_html: Pre-rendered supporting sections (exec summary, etc.)
        cards_html: Pre-rendered cards HTML (used as fallback when no insight hero)
        t: UI translations dict

    Returns:
        HTML string for the overview tab panel
    """
    if t is None:
        t = get_ui_translations('en')

    # Only show cards at bottom as fallback when no insight hero exists
    fallback_cards = cards_html if not insight_hero_html else ''

    return f'''
    <div id="panel-overview" class="tab-panel active" data-panel-title="{t['tab_overview']}" role="tabpanel">
        <div class="report-container">
            {insight_hero_html}
            {supporting_sections_html}
            {fallback_cards}
        </div>
    </div>'''


def generate_right_panel(t: dict = None) -> str:
    """Generate the always-visible right panel with graph zone and entity detail pane.

    The right panel is permanently visible. It contains:
    - Graph zone (top): D3 force-directed entity graph with controls
    - Entity detail zone (bottom): Shows detail of the graph node clicked

    Args:
        t: UI translations dict

    Returns:
        HTML string for the right panel
    """
    if t is None:
        t = get_ui_translations('en')

    graph_controls = f'''
        <div class="graph-controls">
            <div class="graph-filter-toggles" id="graph-filter-toggles" aria-label="{t['aria_filter_type']}"></div>
        </div>'''

    return f'''
    <aside class="right-panel" aria-label="{t['aria_research_panel']}">
        <button class="panel-toggle-btn" id="panel-toggle" aria-label="Toggle research panel" title="Toggle research panel">&#9776;</button>
        <div class="panel-rail" aria-hidden="true">
            <button class="panel-rail-icon" title="Graph" data-rail-action="graph">&#9673;</button>
            <button class="panel-rail-icon" title="Details" data-rail-action="detail">&#9776;</button>
        </div>
        <div class="graph-zone" id="graph-container">
            {graph_controls}
        </div>
        <div class="graph-resize-handle" aria-hidden="true"></div>
        <div class="entity-detail-zone" id="entity-detail">
            <div class="entity-detail-placeholder">{html_lib.escape(t['entity_detail_placeholder'])}</div>
        </div>
    </aside>'''


def generate_entity_tab_panels(entities_by_type: Dict[str, List[Dict]],
                                readmes_by_type: Dict[str, List[Dict]],
                                all_entities: Dict,
                                supporting_files: Dict[str, Dict] = None,
                                t: dict = None) -> str:
    """Generate main content tab panels for entity types (findings, claims, concepts, etc.).

    These panels are rendered as top-level tab panels in the main content area,
    alongside the existing overview/synthesis/megatrends/trends panels.

    Args:
        entities_by_type: Entity groups by type
        readmes_by_type: README groups by type
        all_entities: All linkable entities for wikilink resolution
        supporting_files: Supporting files for methodology tab
        t: UI translations dict

    Returns:
        HTML string with all entity tab panels
    """
    if t is None:
        t = get_ui_translations('en')

    # Entity tab definitions: (tab_id, entity_types_list)
    entity_tabs = [
        ('concepts',    ['concept']),
        ('findings',    ['finding']),
        ('claims',      ['claim']),
        ('questions',   ['question', 'dimension', 'initial-question']),
        ('citations',   ['citation']),
        ('sources',     ['source']),
    ]

    panels_html = ''

    for tab_id, entity_types_list in entity_tabs:
        entities_html = ''
        for entity_type in entity_types_list:
            type_entities = entities_by_type.get(entity_type, [])
            # Sort concepts by category then title to match sidebar nav order
            if entity_type == 'concept':
                type_entities = sorted(
                    type_entities,
                    key=lambda e: (
                        (e.get('metadata', {}).get('category', '') or '').lower(),
                        e.get('title', e['id']).lower()
                    )
                )
            type_readmes = readmes_by_type.get(entity_type, [])
            if type_entities or type_readmes:
                # Use grouped panel for findings and claims
                if entity_type in ('finding', 'claim'):
                    ctx_prefix = 'f-ctx' if entity_type == 'finding' else 'c-ctx'
                    entities_html += generate_grouped_entity_panel(
                        entity_type, type_entities,
                        all_entities=all_entities,
                        readmes=type_readmes, t=t,
                        panel_prefix=ctx_prefix
                    )
                else:
                    entities_html += generate_entity_section(
                        entity_type, type_entities,
                        readmes=type_readmes, all_entities=all_entities,
                        t=t
                    )
        panels_html += f'''
    <div id="panel-{tab_id}" class="tab-panel" data-panel-title="{tab_id.title()}" role="tabpanel">
        <div class="report-container">
            {entities_html}
        </div>
    </div>'''

    # Methodology tab (from supporting files)
    methodology_html = ''
    if supporting_files:
        for file_id, file_data in supporting_files.items():
            if file_data.get('order') == 99:
                methodology_html += file_data.get('body_html', '')
    panels_html += f'''
    <div id="panel-methodology" class="tab-panel" data-panel-title="Methodology" role="tabpanel">
        <div class="report-container">
            <div class="entity-content">{methodology_html}</div>
        </div>
    </div>'''

    return panels_html


def extract_headings(content: str) -> List[Dict]:
    """Extract headings from markdown for TOC generation."""
    headings = []
    for match in re.finditer(r'^(#{1,6})\s+(.+)$', content, re.MULTILINE):
        level = len(match.group(1))
        text = match.group(2).strip()
        heading_id = slugify(text)
        headings.append({
            'level': level,
            'text': text,
            'id': heading_id,
        })
    return headings


def generate_kanban_html(project_language: str = 'en', t: dict = None) -> str:
    """Generate the kanban board HTML structure.

    Args:
        project_language: Language code ('en' or 'de')
        t: UI translations dict (for corner label)

    Returns:
        HTML string for the kanban board
    """
    if t is None:
        t = get_ui_translations(project_language)

    # Localized headers and legend
    kanban_strings = {
        'en': {
            'act': 'Act',
            'act_desc': '0-6 months',
            'plan': 'Plan',
            'plan_desc': '6-18 months',
            'observe': 'Observe',
            'observe_desc': '18+ months',
            'megatrend': 'Megatrend',
            'trend': 'Trend',
            'general': 'General',
        },
        'de': {
            'act': 'Act',
            'act_desc': '0-6 Mon.',
            'plan': 'Plan',
            'plan_desc': '6-18 Mon.',
            'observe': 'Observe',
            'observe_desc': '18+ Mon.',
            'megatrend': 'Megatrend',
            'trend': 'Trend',
            'general': 'Allgemein',
        }
    }
    k = kanban_strings.get(project_language, kanban_strings['en'])

    return f'''<div class="kanban-board">
    <div class="kanban-header">
        <div class="kanban-corner">{t['kanban_corner']}</div>
        <div class="kanban-col-header act">{k['act']}<span class="horizon-desc">{k['act_desc']}</span></div>
        <div class="kanban-col-header plan">{k['plan']}<span class="horizon-desc">{k['plan_desc']}</span></div>
        <div class="kanban-col-header observe">{k['observe']}<span class="horizon-desc">{k['observe_desc']}</span></div>
    </div>
    <div class="kanban-body" id="kanban-body">
        <!-- Rows generated by JavaScript -->
    </div>
</div>
<div class="kanban-legend">
    <span class="legend-item"><span class="legend-dot megatrend"></span>{k['megatrend']}</span>
    <span class="legend-item"><span class="legend-dot trend"></span>{k['trend']}</span>
</div>'''


def load_landing_page(project_path: Path) -> str:
    """Load landing page HTML fragment from web-render/ if it exists.

    Rewrites relative image paths from ./images/ to ./web-render/images/
    since the HTML will be embedded at the project root level.

    Returns HTML string or empty string if not found.
    """
    landing_path = project_path / 'web-render' / 'landing-page.html'
    if not landing_path.exists():
        return ''
    try:
        content = landing_path.read_text(encoding='utf-8')
        if not content.strip():
            return ''
        # Rewrite image paths: the landing page uses ./images/ relative to web-render/,
        # but the report HTML lives at the project root level
        content = re.sub(r"""(?<=['\"(])\.\/images\/""", './web-render/images/', content)
        print(f"  Landing page loaded: {landing_path} ({len(content)} bytes)")
        return content
    except Exception as e:
        print(f"  WARNING: Failed to load landing page: {e}")
        return ''


def generate_html_report(project_path: Path, theme_id: str, output_path: Path,
                         theme_root: str = None, theme_css_file: str = None) -> Dict:
    """Main entry point: generate complete HTML report.

    Args:
        project_path: Path to research project root
        theme_id: Theme identifier
        output_path: Path for output HTML file
        theme_root: Optional custom theme root directory
        theme_css_file: Path to pre-generated CSS file, or '-' for stdin

    Returns:
        Dict with generation results
    """
    print(f"\n=== Export HTML Report ===\n")
    print(f"Project: {project_path}")
    print(f"Theme: {theme_id}")
    print(f"Output: {output_path}\n")

    result = {
        'success': False,
        'output_path': str(output_path),
        'entities_count': {},
        'warnings': [],
    }

    # 1. Validate project
    if not project_path.exists():
        result['error'] = f"Project path does not exist: {project_path}"
        return result

    # v3.0: Load research-hub.md (renamed from research-report.md)
    # Note: Content is no longer rendered in HTML, but metadata is still used
    report_path = project_path / 'research-hub.md'
    if not report_path.exists():
        # Fallback to old name for backward compatibility
        report_path = project_path / 'research-report.md'
        if not report_path.exists():
            result['error'] = f"research-hub.md (or research-report.md) not found in {project_path}"
            return result

    # 2. Load research report
    print("Loading research report...")
    report_content = report_path.read_text(encoding='utf-8')
    report_metadata, report_body = parse_frontmatter(report_content)
    report_headings = extract_headings(report_body)

    project_title = report_metadata.get('dc:title', report_metadata.get('title', project_path.name))
    project_language = report_metadata.get('project_language', 'en')
    t = get_ui_translations(project_language)
    print(f"  Title: {project_title}")
    print(f"  Language: {project_language}")
    print(f"  Headings: {len(report_headings)}")

    # 2b. Detect hub version and load supporting files for v3.0
    hub_version = detect_hub_version(report_metadata)
    print(f"  Hub version: {hub_version}")

    supporting_files = {}
    if hub_version == 'v3.0':
        print("\nLoading v3.0 hub supporting files...")
        supporting_files = load_hub_supporting_files(project_path)
        print(f"  Loaded {len(supporting_files)} supporting files:")
        for file_id, file_data in sorted(supporting_files.items(), key=lambda x: x[1].get('order', 99)):
            print(f"    - {file_data['title']} ({file_id})")

    # 3. Load entities
    print("\nLoading entities...")
    entities = load_entities(project_path)
    print(f"  Total entities: {len(entities)}")

    # Group entities by type
    entities_by_type = {}
    for entity_id, entity_data in entities.items():
        entity_type = entity_data['type']
        if entity_type not in entities_by_type:
            entities_by_type[entity_type] = []
        entities_by_type[entity_type].append(entity_data)

    for entity_type, entity_list in entities_by_type.items():
        print(f"    {entity_type}: {len(entity_list)}")
        result['entities_count'][entity_type] = len(entity_list)

    # 3b. Load READMEs
    print("\nLoading READMEs...")
    readmes = load_readmes(project_path)
    print(f"  Total READMEs: {len(readmes)}")

    # Group READMEs by parent entity type (for rendering with entity groups)
    readmes_by_type = {}
    for readme_id, readme_data in readmes.items():
        subtype = readme_data['subtype']
        # Map subtype to singular entity type used in entities_by_type
        # e.g., 'sources' -> 'source', 'trends' -> 'trend'
        type_key = subtype.rstrip('s') if subtype not in ('synthesis',) else subtype
        if type_key not in readmes_by_type:
            readmes_by_type[type_key] = []
        readmes_by_type[type_key].append(readme_data)

    for subtype, readme_list in readmes_by_type.items():
        print(f"    {subtype}: {len(readme_list)} READMEs")
        result['entities_count'][f'readme-{subtype}'] = len(readme_list)

    # 3c. Generate radar visualization data (table-first approach)
    print("\nGenerating radar data...")
    print("  Parsing kanban data directly from trend landscape table...")

    # For v3.0 hubs, look in trends README; for v2.x, look in research-report
    report_body = normalize_double_bracket_wikilinks(report_body)
    kanban_source_body = report_body
    if hub_version == 'v3.0':
        # Try to get trend landscape from 11-trends/README.md
        trends_readme = readmes.get('readme-trends')
        if trends_readme:
            print("  v3.0 hub detected: using trend landscape from 11-trends/README.md")
            kanban_source_body = normalize_double_bracket_wikilinks(trends_readme['body'])
        else:
            print("  Warning: v3.0 hub detected but 11-trends/README.md not found, using hub")

    radar_data = parse_kanban_from_table(kanban_source_body, entities)

    if not radar_data['dataPoints']:
        # Fallback to entity-based approach if table not found or empty
        print("  No table found or empty, falling back to entity-based generation...")
        horizon_mapping = parse_horizon_mapping_from_table(kanban_source_body)
        print(f"  Found {len(horizon_mapping)} entity-to-horizon mappings")
        radar_data = generate_radar_data(entities, horizon_mapping)

    print(f"  Dimensions: {len(radar_data['dimensions'])}")
    print(f"  Data points: {len(radar_data['dataPoints'])}")

    # Add translations for kanban board labels
    kanban_translations = {
        'en': {'megatrend': 'Megatrend', 'trend': 'Trend', 'general': 'General'},
        'de': {'megatrend': 'Megatrend', 'trend': 'Trend', 'general': 'Allgemein'}
    }
    radar_data['translations'] = kanban_translations.get(project_language, kanban_translations['en'])

    radar_data_json = json.dumps(radar_data, ensure_ascii=False)

    # 4. Process README bodies and filter megatrends from trends table
    for readme_id, readme_data in readmes.items():
        readme_data['body'] = normalize_double_bracket_wikilinks(readme_data['body'])
        if readme_data.get('subtype') == 'trends' and not readme_data.get('is_dimension_scoped'):
            readme_data['body'] = strip_megatrends_from_table(readme_data['body'])
        if readme_data.get('subtype') == 'megatrends':
            readme_data['body'] = strip_megatrend_readme_extras(readme_data['body'])
        if readme_data.get('subtype') == 'concepts':
            readme_data['body'] = strip_concept_readme_extras(readme_data['body'])

    # 4b. Merge entities with readmes for cross-referencing
    all_linkable = {**entities, **readmes}

    # 5. Convert wikilinks in all entities
    for entity_id, entity_data in entities.items():
        body = entity_data.get('body', '')
        body_html = simple_markdown_to_html(body)
        body_html = convert_wikilinks_to_anchors(body_html, all_linkable)
        entity_data['body_html'] = body_html

    # 5b. Resolve portfolio references for trends
    print("Resolving portfolio references for trends...")
    for entity_id, entity_data in entities.items():
        if entity_data.get('type') == 'trend':
            entity_data['resolved_portfolios'] = resolve_portfolio_refs(entity_data, entities)

    # 5c. Convert markdown and wikilinks in supporting files
    if supporting_files:
        print("Processing supporting files...")
        # Need to merge supporting files into linkable entities for cross-referencing
        all_linkable_with_supporting = {**all_linkable, **supporting_files}

        for file_id, file_data in supporting_files.items():
            body = file_data.get('body', '')
            # Convert to HTML and resolve wikilinks
            body_html = simple_markdown_to_html(body)
            body_html = convert_wikilinks_to_anchors(body_html, all_linkable_with_supporting)
            file_data['body_html'] = body_html

    # 6. Load theme CSS
    print(f"\nLoading theme '{theme_id}'...")
    if theme_css_file == '-':
        print("  Theme CSS: stdin (piped)")
        theme_css = sys.stdin.read()
    elif theme_css_file and Path(theme_css_file).is_file():
        print(f"  Theme CSS: {theme_css_file} (pre-generated)")
        theme_css = Path(theme_css_file).read_text(encoding='utf-8')
    else:
        try:
            theme_path = resolve_theme_path(theme_id, theme_root)
            print(f"  Found: {theme_path}")
            theme_css = load_theme_css(theme_path)
        except FileNotFoundError as e:
            print(f"  Warning: {e}")
            result['warnings'].append(str(e))
            theme_css = get_fallback_css()

    # 7. Load layout CSS and JS
    layout_css = load_layout_css()
    nav_js = load_navigation_js()

    # 7b. Load optional landing page
    print("\nChecking for landing page...")
    landing_page_html = load_landing_page(project_path)
    has_landing = bool(landing_page_html)

    # 8. Generate main tab entity sections (synthesis, megatrend, trend)
    print("\nGenerating entity sections...")
    main_tab_types = {
        'synthesis': ['synthesis'],
        'megatrends': ['megatrend'],
        'trends': ['trend'],
    }

    main_tab_sections = {}
    for tab_id, entity_types_list in main_tab_types.items():
        tab_html = ''
        for entity_type in entity_types_list:
            type_entities = entities_by_type.get(entity_type, [])
            type_readmes = readmes_by_type.get(entity_type, [])
            if tab_id == 'trends':
                # Keep the main trend table README, remove dimension exhibit READMEs
                type_readmes = [r for r in type_readmes if not r.get('is_dimension_scoped')]
            if type_entities or type_readmes:
                tab_html += generate_entity_section(
                    entity_type, type_entities,
                    readmes=type_readmes, all_entities=all_linkable,
                    t=t
                )
        main_tab_sections[tab_id] = tab_html

    # 8b. Generate graph data
    print("\nGenerating graph data...")
    graph_data = generate_graph_data(all_linkable)
    graph_data_json = json.dumps(graph_data, ensure_ascii=False)
    graph_type_labels = {
        'synthesis': t.get('graph_synthesis', 'Synthesis'),
        'megatrend': t.get('graph_megatrend', 'Megatrend'),
        'trend': t.get('graph_trend', 'Trend'),
        'concept': t.get('graph_concept', 'Concept'),
        'claim': t.get('graph_claim', 'Claim'),
        'finding': t.get('graph_finding', 'Finding'),
        'source': t.get('graph_source', 'Source'),
        'citation': t.get('graph_citation', 'Citation'),
        'dimension': t.get('graph_dimension', 'Dimension'),
        'question': t.get('graph_question', 'Question'),
        'publisher': t.get('graph_publisher', 'Publisher'),
        'query-batch': t.get('graph_query_batch', 'Query Batch'),
        'initial-question': t.get('graph_initial_question', 'Initial Question'),
    }
    graph_type_labels_json = json.dumps(graph_type_labels, ensure_ascii=False)
    print(f"  Nodes: {len(graph_data['nodes'])}, Links: {len(graph_data['links'])}")

    # 9. Generate navbar
    navbar_html = generate_navbar(project_title, entities_by_type,
                                   supporting_files=supporting_files, t=t,
                                   has_landing=has_landing)

    # 10. Assemble HTML
    print("\nAssembling HTML document...")
    export_date = datetime.now().strftime('%Y-%m-%d')

    # Build overview cards first so they can be passed into insight hero
    insight_metadata = None
    if supporting_files and 'insight-summary' in supporting_files:
        insight_metadata = supporting_files['insight-summary'].get('metadata', {})
    cards_html = generate_overview_cards(entities_by_type, insight_metadata=insight_metadata, t=t)

    # Generate insight-summary hero section (v3.0) with cards embedded
    insight_hero_html = ''
    if supporting_files and 'insight-summary' in supporting_files:
        insight_data = supporting_files['insight-summary']
        insight_hero_html = generate_insight_hero_section(
            insight_data, all_linkable_with_supporting, cards_html=cards_html
        )

    # Generate supporting files HTML sections (v3.0)
    supporting_sections_html = ''
    if supporting_files:
        sorted_supporting = sorted(supporting_files.items(), key=lambda x: x[1].get('order', 99))
        regular_files = []
        for file_id, file_data in sorted_supporting:
            if file_id == 'insight-summary':
                continue
            if file_data.get('order') != 99:
                regular_files.append((file_id, file_data))

        for file_id, file_data in regular_files:
            file_type = file_data.get('type', 'hub-supporting')
            section_class = 'executive-summary' if file_type == 'executive-summary' else 'supporting-file'
            story_arc_html = ''
            if file_type == 'executive-summary':
                story_arc = file_data.get('story_arc', 'unknown')
                word_count = file_data.get('word_count', 0)
                story_arc_html = f'''
                <div class="executive-metadata">
                    <span class="story-arc-badge">{html_lib.escape(story_arc)}</span>
                    <span class="word-count">{word_count} {t['words']}</span>
                </div>'''
            supporting_sections_html += f'''
        <section id="{file_id}" class="{section_class}">
            <h2>{html_lib.escape(file_data['title'])}</h2>
            {story_arc_html}
            <div class="content">
                {file_data.get('body_html', '')}
            </div>
        </section>
'''

    # Generate overview panel (insight hero + exec summary; cards as fallback if no hero)
    overview_panel_html = generate_overview_panel(
        insight_hero_html, supporting_sections_html, cards_html=cards_html, t=t
    )

    # Generate global section nav (persistent left sidebar for all tabs)
    section_nav_html = generate_section_nav(entities_by_type, supporting_files, t=t,
                                               all_entities=all_linkable)

    # Generate main content tab panels
    main_panels_html = ''
    for tab_id, tab_html in main_tab_sections.items():
        main_panels_html += f'''
    <div id="panel-{tab_id}" class="tab-panel" data-panel-title="{tab_id.title()}" role="tabpanel">
        <div class="report-container">
            {tab_html}
        </div>
    </div>'''

    # Generate entity tab panels (findings, claims, concepts, questions, methodology, citations, sources)
    entity_panels_html = generate_entity_tab_panels(
        entities_by_type, readmes_by_type, all_linkable, supporting_files, t=t
    )

    # Generate right panel (graph + entity detail zone, always visible)
    right_panel_html = generate_right_panel(t=t)

    # Build JS translations for embedding
    js_translations = {k[3:]: v for k, v in t.items() if k.startswith('js_')}
    # Add non-js_ prefixed keys needed by report.js
    js_translations['graph_empty_state'] = t.get('graph_empty_state', 'Scroll to an entity to see its connections')
    js_translations_json = json.dumps(js_translations, ensure_ascii=False)

    landing_section = f'<div class="landing-page">{landing_page_html}</div>' if has_landing else ''
    body_class_attr = ' class="landing-mode"' if has_landing else ''

    html = f'''<!DOCTYPE html>
<html lang="{t['html_lang']}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{html_lib.escape(project_title)} - {t['title_suffix']}</title>
    <style>
{theme_css}

{layout_css}
    </style>
</head>
<body{body_class_attr}>
    <div id="report-loading-overlay" role="status" aria-live="polite" style="position:fixed;top:0;left:0;right:0;bottom:0;z-index:9999;background-color:var(--color-bg-primary,#fff);display:flex;align-items:center;justify-content:center;transition:opacity .4s">
        <div style="text-align:center;max-width:320px;width:100%">
            <div style="width:28px;height:28px;border:2px solid var(--color-border,#ddd);border-top-color:var(--color-text-primary,#333);border-radius:50%;margin:0 auto 16px;animation:_lspin .8s linear infinite"></div>
            <div class="loading-status" style="font-family:var(--font-primary,system-ui,sans-serif);font-size:.95rem;color:var(--color-text-primary,#333);margin-bottom:16px">{t['loading_report']}</div>
            <div style="width:100%;height:3px;background:var(--color-border,#ddd);margin-bottom:8px">
                <div id="loading-bar" style="height:100%;width:0;background:var(--color-text-primary,#333);transition:width .3s"></div>
            </div>
            <div id="loading-detail" style="font-family:var(--font-primary,system-ui,sans-serif);font-size:.75rem;color:var(--color-text-muted,#999);min-height:1.2em"></div>
        </div>
    </div>
    <style>@keyframes _lspin{{to{{transform:rotate(360deg)}}}}</style>
    <noscript><style>#report-loading-overlay{{display:none!important}}</style></noscript>

    {landing_section}

    {navbar_html}

    <main class="report-main">
{section_nav_html}
        <div class="section-content">
{overview_panel_html}
{main_panels_html}
{entity_panels_html}
        </div>
    </main>

    {right_panel_html}

    <button id="back-to-top" class="back-to-top" aria-label="{t['aria_back_to_top']}">&#8679;</button>

    <!-- Wikilink Preview Popup -->
    <div id="wikilink-popup" class="preview-popup wikilink-preview hidden">
        <div class="preview-header">
            <span class="entity-type-badge"></span>
            <span class="preview-title"></span>
        </div>
        <div class="preview-badges"></div>
        <div class="preview-content">
            <p class="preview-excerpt"></p>
            <p class="preview-meta"></p>
        </div>
        <div class="preview-footer">
            <span class="preview-cta">{t['preview_cta']}</span>
        </div>
    </div>

    <script>
// Visualization Data
const RADAR_DATA = {radar_data_json};
const GRAPH_DATA = {graph_data_json};
const GRAPH_TYPE_LABELS = {graph_type_labels_json};
const UI_TRANSLATIONS = {js_translations_json};

{nav_js}
    </script>

    <!-- Mermaid Diagram Rendering -->
    <script type="module">
        (async function() {{
            try {{
                const mermaid = await import('https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs');
                mermaid.default.initialize({{
                    startOnLoad: false,
                    theme: 'default'
                }});

                // Render mermaid blocks in visible panels only
                async function renderVisibleMermaid() {{
                    var unrendered = document.querySelectorAll('.tab-panel.active pre.mermaid:not([data-processed])');
                    if (unrendered.length > 0) {{
                        await mermaid.default.run({{ nodes: unrendered }});
                    }}
                }}

                // Initial render for the active tab
                await renderVisibleMermaid();

                // Re-render when tabs switch (hidden panels can't compute SVG dimensions)
                document.addEventListener('tabactivated', function() {{
                    renderVisibleMermaid();
                }});
            }} catch (e) {{
                console.error('Mermaid loading failed:', e);
                document.querySelectorAll('pre.mermaid').forEach(pre => {{
                    pre.style.background = 'var(--color-bg-secondary)';
                    pre.style.padding = 'var(--spacing-md)';
                    pre.style.border = '1px dashed var(--color-border)';
                    pre.style.whiteSpace = 'pre-wrap';
                    pre.style.fontFamily = 'monospace';
                    pre.style.fontSize = '0.875rem';
                    const notice = document.createElement('p');
                    notice.className = 'mermaid-fallback';
                    notice.innerHTML = '<em>Diagram (requires internet connection to render)</em>';
                    notice.style.color = 'var(--color-text-muted)';
                    notice.style.marginBottom = 'var(--spacing-sm)';
                    pre.parentNode.insertBefore(notice, pre);
                }});
            }}
        }})();
    </script>
</body>
</html>'''

    # 11. Write output
    print(f"\nWriting output to {output_path}...")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html, encoding='utf-8')

    result['success'] = True
    print("\n=== Export Complete ===")
    print(f"Output: {output_path}")
    print(f"Size: {output_path.stat().st_size / 1024:.1f} KB")

    return result


def main():
    """Main entry point for CLI."""
    parser = argparse.ArgumentParser(
        description='Export deeper-research-3 output to self-contained HTML'
    )
    parser.add_argument(
        '--project', '-p',
        help='Path to research project root (required unless --list-themes)'
    )
    parser.add_argument(
        '--theme', '-t',
        default='digital-x',
        help='Theme ID from cogni-workplace/themes/ (default: digital-x)'
    )
    parser.add_argument(
        '--output', '-o',
        help='Output HTML file path (default: {project}/research-hub.html)'
    )
    parser.add_argument(
        '--theme-root',
        help='Custom theme root directory (overrides COGNI_WORKPLACE_ROOT)'
    )
    parser.add_argument(
        '--theme-css-file',
        help='Path to pre-generated CSS file, or "-" to read from stdin (overrides theme.md CSS extraction)'
    )
    parser.add_argument(
        '--list-themes',
        action='store_true',
        help='List available themes with metadata and exit (JSON output)'
    )

    args = parser.parse_args()

    # Handle --list-themes before requiring --project
    if args.list_themes:
        result = discover_themes(args.theme_root)
        print(json.dumps(result, indent=2))
        sys.exit(0)

    # Validate --project is provided for normal operation
    if not args.project:
        parser.error('--project is required unless --list-themes is specified')

    project_path = Path(args.project).resolve()
    theme_id = args.theme

    if args.output:
        output_path = Path(args.output).resolve()
    else:
        output_path = project_path / 'research-hub.html'

    # Get theme_root from args (argparse converts --theme-root to theme_root)
    theme_root = getattr(args, 'theme_root', None)
    result = generate_html_report(project_path, theme_id, output_path, theme_root,
                                  theme_css_file=args.theme_css_file)

    if result['success']:
        print(json.dumps(result, indent=2))
        return 0
    else:
        print(f"Error: {result.get('error', 'Unknown error')}")
        return 1


if __name__ == '__main__':
    sys.exit(main())

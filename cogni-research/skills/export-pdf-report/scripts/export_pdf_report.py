#!/usr/bin/env python3
"""Export PDF Report - Content Assembly Script.

Loads research project entities and assembles a structured JSON manifest
for PDF generation. The manifest is consumed by the pdf-report-writer agent
which delegates to document-skills:pdf for ReportLab rendering.

Usage:
    python export_pdf_report.py --project /path/to/project [--theme digital-x] [--output report.pdf] [--dry-run]

Output:
    - Writes {project}/.metadata/pdf-content.json
    - Prints JSON result to stdout
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from datetime import datetime


# ---------------------------------------------------------------------------
# Entity directory mapping (same as export-html-report)
# ---------------------------------------------------------------------------
ENTITY_DIRS = {
    'dimensions':  '01-research-dimensions',
    'synthesis':   '12-synthesis',
    'megatrends':  '06-megatrends',
    'trends':      '11-trends',
    'concepts':    '05-domain-concepts',
    'sources':     '07-sources',
    'publishers':  '08-publishers',
    'citations':   '09-citations',
}

# Entities excluded from PDF report
EXCLUDED_DIRS = {
    'initial_question': '00-initial-question',
    'questions':        '02-refined-questions',
    'query_batches':    '03-query-batches',
    'findings':         '04-findings',
    'claims':           '10-claims',
}

# Dimension color palette (cycled for N dimensions)
DIMENSION_PALETTE = [
    '#00b8d4', '#5b2c6f', '#1e8449', '#ff6b4a',
    '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b',
]

# Labels for cover page number play boxes (matching HTML report translations)
NUMBER_PLAY_LABELS = {
    'en': {
        'syntheses': 'Dimensions', 'megatrends': 'Megatrends', 'trends': 'Trends',
        'concepts': 'Concepts', 'findings': 'Findings', 'claims': 'Claims',
    },
    'de': {
        'syntheses': 'Dimensionen', 'megatrends': 'Megatrends', 'trends': 'Trends',
        'concepts': 'Konzepte', 'findings': 'Erkenntnisse', 'claims': 'Aussagen',
    },
}

FALLBACK_COLORS = {
    'color-primary': '#0d3c55',
    'color-primary-dark': '#091f2c',
    'color-primary-light': '#1a5276',
    'color-accent': '#00d7e9',
    'color-accent-light': '#4de8f4',
    'color-bg-primary': '#ffffff',
    'color-bg-secondary': '#f8fafb',
    'color-bg-tertiary': '#e8f4f8',
    'color-text-primary': '#0d3c55',
    'color-text-secondary': '#2c5364',
    'color-text-muted': '#5a7a8a',
    'color-border': '#d4dfe5',
}


# ---------------------------------------------------------------------------
# Frontmatter parser (stdlib-only, no pyyaml dependency)
# ---------------------------------------------------------------------------
def parse_frontmatter(content):
    """Parse YAML frontmatter from markdown content.

    Returns (metadata_dict, body_text).
    """
    if not content.startswith('---'):
        return {}, content

    end = content.find('\n---', 3)
    if end == -1:
        return {}, content

    fm_text = content[4:end].strip()
    body = content[end + 4:].strip()
    meta = {}

    for line in fm_text.split('\n'):
        line = line.strip()
        if not line or line.startswith('#'):
            continue

        # Prefer ': ' to avoid splitting on namespace prefixes like dc:title
        colon_space_idx = line.find(': ')
        if colon_space_idx != -1:
            colon_idx = colon_space_idx
        else:
            # Bare key with no value (e.g., "finding_refs:")
            colon_idx = line.find(':')
            if colon_idx == -1:
                continue

        key = line[:colon_idx].strip()
        val = line[colon_idx + 1:].strip()

        # Remove surrounding quotes
        if (val.startswith('"') and val.endswith('"')) or \
           (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]

        # Inline list [a, b, c]
        if val.startswith('[') and val.endswith(']'):
            items = val[1:-1].split(',')
            val = [item.strip().strip('"').strip("'") for item in items if item.strip()]

        # Boolean
        elif val.lower() in ('true', 'false'):
            val = val.lower() == 'true'

        # Numeric
        elif val.replace('.', '', 1).replace('-', '', 1).isdigit():
            val = float(val) if '.' in val else int(val)

        meta[key] = val

    return meta, body


# ---------------------------------------------------------------------------
# Entity loading
# ---------------------------------------------------------------------------
def load_entities(project, entity_type):
    """Load all entities of a given type from the project directory.

    Returns list of dicts with 'metadata', 'body', 'filename'.
    """
    dir_name = ENTITY_DIRS.get(entity_type)
    if not dir_name:
        return []

    base_dir = project / dir_name

    # Synthesis entities live directly in 12-synthesis/ (not data/ subdir)
    # per entity-schema.json: data_subdir=null for synthesis
    if entity_type == 'synthesis':
        if not base_dir.is_dir():
            return []
        glob_pattern = 'synthesis-*.md'
        data_dir = base_dir
    else:
        data_dir = base_dir / 'data'
        if not data_dir.is_dir():
            data_dir = base_dir
            if not data_dir.is_dir():
                return []
        glob_pattern = '*.md'

    entities = []
    for md_file in sorted(data_dir.glob(glob_pattern)):
        if md_file.name.startswith('README'):
            continue
        # Skip cross-dimensional synthesis (duplicates dimension chapters)
        if md_file.stem == 'synthesis-cross-dimensional':
            continue
        try:
            content = md_file.read_text(encoding='utf-8')
            meta, body = parse_frontmatter(content)
            entities.append({
                'metadata': meta,
                'body': body,
                'filename': md_file.name,
                'path': str(md_file.relative_to(project)),
            })
        except Exception as e:
            print(f"WARNING: Failed to load {md_file}: {e}", file=sys.stderr)
    return entities


def load_supporting_file(project, filename):
    """Load a supporting file from the project root.

    Returns (metadata, body) or (None, None) if not found.
    """
    filepath = project / filename
    if not filepath.is_file():
        return None, None

    content = filepath.read_text(encoding='utf-8')
    return parse_frontmatter(content)


def count_entity_files(project, dir_name):
    """Count .md entity files in a directory (without loading full content)."""
    data_dir = project / dir_name / 'data'
    if not data_dir.is_dir():
        data_dir = project / dir_name
        if not data_dir.is_dir():
            return 0
    return sum(1 for f in data_dir.glob('*.md') if not f.name.startswith('README'))


def load_sprint_log(project):
    """Load sprint-log.json from .metadata directory."""
    path = project / '.metadata' / 'sprint-log.json'
    if not path.is_file():
        return {}
    try:
        return json.loads(path.read_text(encoding='utf-8'))
    except Exception:
        return {}


# ---------------------------------------------------------------------------
# Theme loading
# ---------------------------------------------------------------------------
def discover_theme_root():
    """Find the cogni-workplace themes directory."""
    # Check environment variable first
    workplace_root = os.environ.get('COGNI_WORKPLACE_ROOT', '')
    if workplace_root:
        theme_dir = Path(workplace_root) / 'themes'
        if theme_dir.is_dir():
            return theme_dir

    # Check common locations
    candidates = [
        Path.home() / 'GitHub' / 'cogni-workplace' / 'cogni-workplace' / 'themes',
        Path.home() / 'GitHub' / 'dev' / 'cogni-workplace' / 'cogni-workplace' / 'themes',
    ]
    for c in candidates:
        if c.is_dir():
            return c

    return None


def load_theme_colors(theme_id, theme_root=None):
    """Extract CSS variables from theme.md into a color dict."""
    if theme_root:
        theme_dir = Path(theme_root)
    else:
        theme_dir = discover_theme_root()

    if not theme_dir:
        return FALLBACK_COLORS.copy()

    theme_file = theme_dir / theme_id / 'theme.md'
    if not theme_file.is_file():
        return FALLBACK_COLORS.copy()

    content = theme_file.read_text(encoding='utf-8')
    pattern = r'## CSS Variable Reference.*?```css\n(.*?)```'
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        return FALLBACK_COLORS.copy()

    colors = {}
    for line in match.group(1).split('\n'):
        m = re.match(r'\s*--([\w-]+):\s*(.+?);', line)
        if m:
            colors[m.group(1)] = m.group(2).strip()

    # Ensure fallbacks for required keys
    for key, val in FALLBACK_COLORS.items():
        colors.setdefault(key, val)

    return colors


# ---------------------------------------------------------------------------
# Source index builder
# ---------------------------------------------------------------------------
def build_source_index(sources, publishers, citations):
    """Build a numbered source index from source entities.

    Returns list of source index entries with sequential numbers.
    Citations are used to compute citation_count per source.
    """
    # Sort sources: tier-1 first, then by title
    tier_order = {'tier-1': 0, 'tier-2': 1, 'tier-3': 2, 'tier-4': 3}

    def sort_key(s):
        meta = s['metadata']
        tier = meta.get('reliability_tier', 'tier-4')
        title = meta.get('dc:title', '')
        return (tier_order.get(tier, 9), title.lower())

    sorted_sources = sorted(sources, key=sort_key)

    # Build publisher lookup
    pub_lookup = {}
    for p in publishers:
        pid = p['metadata'].get('dc:identifier', '')
        pub_lookup[pid] = p['metadata']

    # Build citation count per source
    citation_counts = {}
    for c in citations:
        cmeta = c['metadata']
        src_id = cmeta.get('source_entity', '') or cmeta.get('source_id', '')
        # Normalize: extract entity ID from path if needed
        if '/' in src_id:
            src_id = src_id.split('/')[-1]
        if src_id:
            citation_counts[src_id] = citation_counts.get(src_id, 0) + 1

    entries = []
    for idx, src in enumerate(sorted_sources, 1):
        meta = src['metadata']
        entity_id = meta.get('dc:identifier', '')
        entry = {
            'number': idx,
            'entity_id': entity_id,
            'title': meta.get('dc:title', 'Untitled'),
            'source_type': meta.get('source_type', 'unknown'),
            'url': meta.get('url', ''),
            'domain': meta.get('domain', ''),
            'access_date': meta.get('access_date', ''),
            'tier': meta.get('reliability_tier', ''),
            'credibility_score': meta.get('credibility_score', ''),
            'doi': meta.get('doi', ''),
            'citation_count': citation_counts.get(entity_id, 0),
        }

        # Authors
        authors = meta.get('authors', [])
        if isinstance(authors, list):
            entry['authors'] = ', '.join(authors)
        else:
            entry['authors'] = str(authors) if authors else ''

        # Publication info
        entry['publication'] = meta.get('journal', '') or meta.get('publisher', '')
        entry['date'] = meta.get('publication_date', '')

        entries.append(entry)

    return entries


# ---------------------------------------------------------------------------
# Wikilink resolution for source references
# ---------------------------------------------------------------------------
def resolve_wikilinks_to_source_refs(text, source_index):
    """Replace wikilinks to sources with [N] numbered references.

    Other wikilinks (concepts, megatrends, trends) are replaced with
    plain text references.
    """
    if not text:
        return text

    # Build lookup: entity_id -> source number
    source_lookup = {}
    for entry in source_index:
        eid = entry['entity_id']
        source_lookup[eid] = entry['number']
        # Also map the full path form
        source_lookup[f"07-sources/data/{eid}"] = entry['number']

    def replace_wikilink(match):
        full = match.group(1)
        display = None
        if '|' in full:
            full, display = full.split('|', 1)
        full = full.strip()

        # Extract entity ID from path
        entity_id = full.split('/')[-1] if '/' in full else full

        # Check if it's a source reference
        num = source_lookup.get(full) or source_lookup.get(entity_id)
        if num:
            if display:
                return f'{display} [{num}]'
            return f'[{num}]'

        # Non-source wikilinks: render as plain text
        if display:
            return display
        return entity_id.replace('-', ' ').title()

    return re.sub(r'\[\[(.+?)\]\]', replace_wikilink, text)


# ---------------------------------------------------------------------------
# Section builders
# ---------------------------------------------------------------------------
def build_executive_summary(project):
    """Build executive summary section from insight-summary.md or executive-summary.md."""
    for filename in ['insight-summary.md', 'executive-summary.md']:
        meta, body = load_supporting_file(project, filename)
        if meta is not None and body:
            return {
                'type': 'executive_summary',
                'title': meta.get('title', 'Executive Summary'),
                'body_md': body,
                'metadata': {
                    'arc_id': meta.get('arc_id', ''),
                    'source_file': filename,
                },
            }
    return None


def build_research_scope(project, dimensions):
    """Build research scope section."""
    meta, body = load_supporting_file(project, '00-research-scope.md')
    if meta is None:
        return None

    dim_table = []
    for d in dimensions:
        dm = d['metadata']
        dim_table.append({
            'name': dm.get('dc:title', ''),
            'slug': dm.get('slug', ''),
            'question_count': dm.get('question_count', 0),
        })

    return {
        'type': 'research_scope',
        'title': meta.get('title', 'Research Scope'),
        'body_md': body,
        'dimensions_table': dim_table,
    }


def build_dimension_chapters(synthesis_entities, dimensions):
    """Build one chapter section per dimension synthesis."""
    # Build dimension order lookup
    dim_order = {}
    for idx, d in enumerate(dimensions):
        slug = d['metadata'].get('slug', '')
        dim_order[slug] = idx

    chapters = []
    for s in synthesis_entities:
        meta = s['metadata']
        dim_slug = meta.get('dimension', '')
        chapters.append({
            'type': 'dimension_chapter',
            'title': meta.get('title', f'Dimension: {dim_slug}'),
            'dimension_slug': dim_slug,
            'dimension_index': dim_order.get(dim_slug, 99),
            'body_md': strip_appendix_section(s['body']),
            'trend_count': meta.get('trend_count', 0),
            'avg_confidence': meta.get('avg_confidence', 0),
            'citation_count': meta.get('citation_count', 0),
            'word_count': meta.get('word_count', 0),
        })

    # Sort by dimension order
    chapters.sort(key=lambda c: c['dimension_index'])
    return chapters


def strip_evidence_section(body_md):
    """Remove ## Evidenzbasis section and everything after it from body text."""
    pattern = r'\n## Evidenzbasis\b.*'
    return re.sub(pattern, '', body_md, flags=re.DOTALL).rstrip()


def strip_appendix_section(body_md):
    """Remove ## Appendix / ## Anhang section and everything after it from body text."""
    pattern = r'\n## (?:Appendix|Anhang)\b.*'
    return re.sub(pattern, '', body_md, flags=re.DOTALL).rstrip()


def build_megatrends_section(megatrend_entities):
    """Build megatrends section."""
    if not megatrend_entities:
        return None

    entries = []
    for mt in megatrend_entities:
        meta = mt['metadata']
        entries.append({
            'name': meta.get('dc:title', '') or meta.get('megatrend_name', ''),
            'horizon': meta.get('planning_horizon', ''),
            'evidence_strength': meta.get('evidence_strength', ''),
            'confidence_score': meta.get('confidence_score', 0),
            'dimension': meta.get('dimension_affinity', ''),
            'structure': meta.get('megatrend_structure', 'generic'),
            'finding_count': meta.get('finding_count', 0),
            'body_md': strip_evidence_section(mt['body']),
        })

    # Sort by confidence descending
    horizon_order = {'act': 0, 'plan': 1, 'observe': 2}
    entries.sort(key=lambda e: (
        -float(e.get('confidence_score', 0)),
        horizon_order.get(e.get('horizon', ''), 9),
    ))

    return {
        'type': 'megatrends',
        'title': 'Megatrends',
        'entries': entries,
    }


def build_trend_landscape(trend_entities, dimensions):
    """Build trend landscape section with overview table only."""
    if not trend_entities:
        return None

    # Build dimension lookup for ordering
    dim_order = {}
    for idx, d in enumerate(dimensions):
        slug = d['metadata'].get('slug', '')
        dim_order[slug] = idx

    horizon_order = {'act': 0, 'plan': 1, 'observe': 2}

    # Build overview table
    overview = []
    for t in trend_entities:
        meta = t['metadata']
        dim = meta.get('dimension', '')
        title = meta.get('dc:title', '')
        if not title:
            # Fallback: extract from body H1
            h1_match = re.match(r'^#\s+(.+)', t['body'])
            if h1_match:
                title = h1_match.group(1).strip()
        overview.append({
            'title': title,
            'dimension': dim,
            'horizon': meta.get('planning_horizon', ''),
            'confidence': meta.get('trend_confidence', meta.get('confidence', '')),
        })

    # Sort: by dimension order, then horizon (act first)
    overview.sort(key=lambda e: (
        dim_order.get(e.get('dimension', ''), 99),
        horizon_order.get(e.get('horizon', ''), 9),
    ))

    return {
        'type': 'trend_landscape',
        'title': 'Trend Landscape',
        'overview_table': overview,
    }


def extract_concept_definition(body):
    """Extract the full 'Was es ist' / 'What it is' section from concept body.

    Returns the complete section text (without heading).
    Falls back to first paragraph of body if section not found.
    """
    pattern = r'##\s+(?:Was es ist|What it is)\s*\n+(.*?)(?=\n##|\Z)'
    match = re.search(pattern, body, re.DOTALL)
    if match:
        text = match.group(1).strip()
    else:
        # Fallback: skip H1 header and get first paragraph
        lines = body.strip().split('\n')
        text_lines = []
        past_header = False
        for line in lines:
            if line.startswith('#'):
                if past_header:
                    break
                past_header = True
                continue
            if past_header and line.strip():
                text_lines.append(line.strip())
            elif past_header and text_lines:
                break
        text = ' '.join(text_lines)

    if not text:
        return body[:300].replace('\n', ' ').strip()

    # Strip wikilinks → plain text
    text = re.sub(r'\[\[.*?\|?(.*?)\]\]', r'\1', text)

    return text


def build_domain_concepts(concept_entities):
    """Build domain concepts glossary section."""
    if not concept_entities:
        return None

    entries = []
    for c in concept_entities:
        meta = c['metadata']
        related = meta.get('related_concepts', [])
        if isinstance(related, str):
            related = [related]
        name = meta.get('dc:title', '')
        if not name:
            # Fallback: extract from body H1
            h1_match = re.match(r'^#\s+(.+)', c['body'])
            if h1_match:
                name = h1_match.group(1).strip()
        entries.append({
            'name': name,
            'definition': meta.get('definition', '') or extract_concept_definition(c['body']),
            'related': related,
            'domain': meta.get('domain', ''),
        })

    # Sort alphabetically
    entries.sort(key=lambda e: e['name'].lower())

    return {
        'type': 'domain_concepts',
        'title': 'Domain Concepts',
        'entries': entries,
    }


# ---------------------------------------------------------------------------
# Main assembly
# ---------------------------------------------------------------------------
def assemble_content(project, theme_id, theme_root=None, language_override=None):
    """Assemble the complete content manifest for PDF generation."""
    project = Path(project).resolve()

    # Validate project
    hub_file = project / 'research-hub.md'
    if not hub_file.is_file():
        return {'error': f'research-hub.md not found in {project}'}

    # Load hub metadata
    hub_meta, hub_body = parse_frontmatter(hub_file.read_text(encoding='utf-8'))

    # Load sprint log
    sprint_log = load_sprint_log(project)

    # Load theme
    colors = load_theme_colors(theme_id, theme_root)

    # Add dimension palette colors
    for i in range(8):
        key = f'color-dim-{i + 1}'
        colors.setdefault(key, DIMENSION_PALETTE[i])

    # Load entities
    # Note: cross-dimensional synthesis (synthesis-cross-dimensional.md) and
    # pipeline metrics (00-pipeline-metrics.md) are intentionally excluded.
    # Cross-dimensional content duplicates dimension chapters; pipeline metrics
    # are operational metadata not suited for the formal report reader.
    dimensions = load_entities(project, 'dimensions')
    synthesis = load_entities(project, 'synthesis')
    megatrends = load_entities(project, 'megatrends')
    trends = load_entities(project, 'trends')
    concepts = load_entities(project, 'concepts')
    sources = load_entities(project, 'sources')
    publishers = load_entities(project, 'publishers')
    citations = load_entities(project, 'citations')

    # Build source index
    source_index = build_source_index(sources, publishers, citations)

    # Detect language (CLI override takes precedence)
    language = language_override or sprint_log.get('language', hub_meta.get('language', 'en'))

    # Build metadata
    metadata = {
        'title': hub_meta.get('title', sprint_log.get('title', 'Research Report')),
        'research_type': sprint_log.get('research_type', hub_meta.get('research_type', '')),
        'date': sprint_log.get('created_at', datetime.now().strftime('%Y-%m-%d')),
        'language': language,
        'dimension_count': len(dimensions),
        'trend_count': len(trends),
        'megatrend_count': len(megatrends),
        'concept_count': len(concepts),
        'source_count': len(sources),
        'synthesis_count': len(synthesis),
    }

    # Build number play boxes (sorted ascending by value, localized labels)
    # Prefer insight-summary stats; fallback to entity counts
    insight_meta, _ = load_supporting_file(project, 'insight-summary.md')
    if insight_meta and insight_meta.get('stats_syntheses') is not None:
        np_counts = [
            ('syntheses', int(insight_meta.get('stats_syntheses', 0))),
            ('megatrends', int(insight_meta.get('stats_megatrends', 0))),
            ('trends', int(insight_meta.get('stats_trends', 0))),
            ('concepts', int(insight_meta.get('stats_concepts', 0))),
            ('findings', int(insight_meta.get('stats_findings', 0))),
            ('claims', int(insight_meta.get('stats_claims', 0))),
        ]
    else:
        finding_count = count_entity_files(project, '04-findings')
        claim_count = count_entity_files(project, '10-claims')
        np_counts = [
            ('syntheses', len(synthesis)),
            ('megatrends', len(megatrends)),
            ('trends', len(trends)),
            ('concepts', len(concepts)),
            ('findings', finding_count),
            ('claims', claim_count),
        ]

    labels = NUMBER_PLAY_LABELS.get(language, NUMBER_PLAY_LABELS['en'])
    number_play = [{'label': labels[key], 'value': val} for key, val in np_counts if val > 0]
    number_play.sort(key=lambda e: e['value'])
    metadata['number_play'] = number_play

    # Build sections
    sections = []

    # Executive summary
    exec_summary = build_executive_summary(project)
    if exec_summary:
        exec_summary['body_md'] = resolve_wikilinks_to_source_refs(
            exec_summary['body_md'], source_index)
        sections.append(exec_summary)

    # Dimension chapters
    chapters = build_dimension_chapters(synthesis, dimensions)
    for ch in chapters:
        ch['body_md'] = resolve_wikilinks_to_source_refs(
            ch['body_md'], source_index)
        sections.append(ch)

    # Megatrends
    mega_section = build_megatrends_section(megatrends)
    if mega_section:
        for entry in mega_section['entries']:
            entry['body_md'] = resolve_wikilinks_to_source_refs(
                entry['body_md'], source_index)
        sections.append(mega_section)

    # Trend landscape (overview table only)
    trend_section = build_trend_landscape(trends, dimensions)
    if trend_section:
        sections.append(trend_section)

    # Domain concepts
    concept_section = build_domain_concepts(concepts)
    if concept_section:
        sections.append(concept_section)

    # Appendix: Research scope
    scope = build_research_scope(project, dimensions)
    if scope:
        scope['type'] = 'appendix_scope'
        appendix_prefix = 'Anhang' if language == 'de' else 'Appendix'
        scope['title'] = f"{appendix_prefix}: {scope['title']}"
        scope['body_md'] = resolve_wikilinks_to_source_refs(
            scope['body_md'], source_index)
        sections.append(scope)

    # Source index (always last)
    sections.append({
        'type': 'source_index',
        'title': 'Source Index',
        'entries': source_index,
    })

    return {
        'metadata': metadata,
        'theme': {
            'theme_id': theme_id,
            'colors': colors,
        },
        'sections': sections,
    }


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
def list_themes(theme_root=None):
    """List available themes as JSON."""
    if theme_root:
        theme_dir = Path(theme_root)
    else:
        theme_dir = discover_theme_root()

    if not theme_dir or not theme_dir.is_dir():
        return {'themes': [], 'theme_root': None, 'error': 'No theme directory found'}

    themes = []
    for entry in sorted(theme_dir.iterdir()):
        if entry.is_dir() and (entry / 'theme.md').is_file():
            themes.append({
                'id': entry.name,
                'path': str(entry / 'theme.md'),
            })

    return {'themes': themes, 'theme_root': str(theme_dir)}


def main():
    parser = argparse.ArgumentParser(description='Export PDF Report - Content Assembly')
    parser.add_argument('--project', default=None, help='Research project root path')
    parser.add_argument('--theme', default='digital-x', help='Theme ID')
    parser.add_argument('--theme-root', default=None, help='Custom theme root directory')
    parser.add_argument('--output', default=None, help='Output PDF path')
    parser.add_argument('--language', default=None, help='ISO 639-1 language code')
    parser.add_argument('--dry-run', action='store_true', help='Output manifest without writing')
    parser.add_argument('--list-themes', action='store_true', help='List available themes as JSON')
    args = parser.parse_args()

    # Handle --list-themes (no project required)
    if args.list_themes:
        result = list_themes(args.theme_root)
        print(json.dumps(result, indent=2))
        sys.exit(0)

    if not args.project:
        print(json.dumps({'error': '--project is required (unless using --list-themes)'}), file=sys.stderr)
        sys.exit(1)

    project = Path(args.project).resolve()

    # Assemble content (pass language override so labels are localized correctly)
    content = assemble_content(project, args.theme, args.theme_root, args.language)

    if 'error' in content:
        print(json.dumps(content, indent=2))
        sys.exit(1)

    # Determine output path
    output_path = args.output or str(project / 'research-report.pdf')
    content['output_path'] = output_path

    # Write manifest
    metadata_dir = project / '.metadata'
    metadata_dir.mkdir(exist_ok=True)
    manifest_path = metadata_dir / 'pdf-content.json'
    manifest_path.write_text(json.dumps(content, indent=2, ensure_ascii=False), encoding='utf-8')

    # Result
    result = {
        'success': True,
        'manifest_path': str(manifest_path),
        'output_path': output_path,
        'sections': len(content['sections']),
        'entities': {
            'dimensions': content['metadata']['dimension_count'],
            'trends': content['metadata']['trend_count'],
            'megatrends': content['metadata']['megatrend_count'],
            'concepts': content['metadata']['concept_count'],
            'sources': content['metadata']['source_count'],
            'synthesis': content['metadata']['synthesis_count'],
        },
        'theme': args.theme,
    }

    if args.dry_run:
        result['dry_run'] = True
        print(json.dumps(result, indent=2))
    else:
        print(json.dumps(result, indent=2))


if __name__ == '__main__':
    main()

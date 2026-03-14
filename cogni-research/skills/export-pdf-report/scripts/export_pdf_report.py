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
    'sources':     '05-sources',
    'claims':      '06-claims',
}

# Entities excluded from PDF report (loaded via ENTITY_DIRS only when needed)
EXCLUDED_DIRS = {
    'initial_question': '00-initial-question',
    'questions':        '02-refined-questions',
    'query_batches':    '03-query-batches',
    'findings':         '04-findings',
}

# Dimension color palette (cycled for N dimensions)
DIMENSION_PALETTE = [
    '#00b8d4', '#5b2c6f', '#1e8449', '#ff6b4a',
    '#3b82f6', '#8b5cf6', '#ec4899', '#f59e0b',
]

# Labels for cover page number play boxes (matching HTML report translations)
NUMBER_PLAY_LABELS = {
    'en': {
        'dimensions': 'Dimensions', 'findings': 'Findings',
        'sources': 'Sources', 'claims': 'Claims',
    },
    'de': {
        'dimensions': 'Dimensionen', 'findings': 'Erkenntnisse',
        'sources': 'Quellen', 'claims': 'Aussagen',
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
def build_source_index(sources):
    """Build a numbered source index from source entities.

    Returns list of source index entries with sequential numbers.
    """
    # Sort sources: tier-1 first, then by title
    tier_order = {'tier-1': 0, 'tier-2': 1, 'tier-3': 2, 'tier-4': 3}

    def sort_key(s):
        meta = s['metadata']
        tier = meta.get('reliability_tier', 'tier-4')
        title = meta.get('dc:title', '')
        return (tier_order.get(tier, 9), title.lower())

    sorted_sources = sorted(sources, key=sort_key)

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
        }

        # Authors
        authors = meta.get('authors', [])
        if isinstance(authors, list):
            entry['authors'] = ', '.join(authors)
        else:
            entry['authors'] = str(authors) if authors else ''

        # Publication info
        entry['publication'] = meta.get('journal', '') or meta.get('publication', '')
        entry['date'] = meta.get('publication_date', '')

        entries.append(entry)

    return entries


# ---------------------------------------------------------------------------
# Wikilink resolution for source references
# ---------------------------------------------------------------------------
def resolve_wikilinks_to_source_refs(text, source_index):
    """Replace wikilinks to sources with [N] numbered references.

    Non-source wikilinks are replaced with plain text references.
    """
    if not text:
        return text

    # Build lookup: entity_id -> source number
    source_lookup = {}
    for entry in source_index:
        eid = entry['entity_id']
        source_lookup[eid] = entry['number']
        # Also map the full path form
        source_lookup[f"05-sources/data/{eid}"] = entry['number']

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
    dimensions = load_entities(project, 'dimensions')
    sources = load_entities(project, 'sources')
    claims = load_entities(project, 'claims')

    # Build source index
    source_index = build_source_index(sources)

    # Detect language (CLI override takes precedence)
    language = language_override or sprint_log.get('language', hub_meta.get('language', 'en'))

    # Build metadata
    metadata = {
        'title': hub_meta.get('title', sprint_log.get('title', 'Research Report')),
        'research_type': sprint_log.get('research_type', hub_meta.get('research_type', '')),
        'date': sprint_log.get('created_at', datetime.now().strftime('%Y-%m-%d')),
        'language': language,
        'dimension_count': len(dimensions),
        'source_count': len(sources),
        'claim_count': len(claims),
    }

    # Build number play boxes (sorted ascending by value, localized labels)
    finding_count = count_entity_files(project, '04-findings')
    claim_count = count_entity_files(project, '06-claims')
    np_counts = [
        ('dimensions', len(dimensions)),
        ('findings', finding_count),
        ('sources', len(sources)),
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
            'sources': content['metadata']['source_count'],
            'claims': content['metadata']['claim_count'],
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

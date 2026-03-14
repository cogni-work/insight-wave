#!/usr/bin/env python3
"""
Export research project entities to flat markdown files for Claude Projects RAG.

Converts deeper-research project entities into RAG-optimized format:
- Flat file structure (no nested directories)
- Named files for better retrieval
- Consolidated content with metadata headers
- Cross-references resolved to inline text

Usage:
    python export_rag.py <project_path> [output_dir] [--entity-types TYPE1,TYPE2...]

Arguments:
    project_path    Path to the research project (contains 04-findings, 10-claims, etc.)
    output_dir      Destination directory for exported files (default: ./<project-slug>)

Options:
    --entity-types  Comma-separated list of entity types to export
                    Default: all entity types
    --include-report Include research-hub.md in export
    --max-file-size Maximum file size in KB (default: 200)
"""

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

# Add scripts/lib to path for entity_config
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent.parent / "scripts" / "lib"))

try:
    from entity_config import get_entity_dirs, get_data_subdir
    # Build ENTITY_DIRS from centralized config (key -> directory mapping)
    ENTITY_DIRS = get_entity_dirs()
    DATA_SUBDIR = get_data_subdir()
except ImportError as e:
    print(f"ERROR: entity_config.py required but not found: {e}", file=sys.stderr)
    sys.exit(1)


def _load_null_data_subdir_types() -> set:
    """Derive entity types with null data_subdir from entity-schema.json."""
    try:
        config_path = Path(__file__).resolve().parent.parent.parent.parent / "config" / "entity-schema.json"
        with open(config_path, "r", encoding="utf-8") as f:
            config = json.load(f)
        return {et["key"] for et in config["entity_types"] if et.get("data_subdir") is None}
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        return set()  # Safe fallback


# Entity types with null data_subdir (files live directly in entity dir)
_NULL_DATA_SUBDIR_TYPES = _load_null_data_subdir_types()


def get_entity_source_dir(project_path: Path, entity_key: str) -> Optional[Path]:
    """Get the source directory for an entity type, handling null data_subdir."""
    entity_dir = ENTITY_DIRS.get(entity_key)
    if not entity_dir:
        return None
    # Some entity types have null data_subdir — files live directly in entity dir
    if entity_key in _NULL_DATA_SUBDIR_TYPES:
        return project_path / entity_dir
    return project_path / entity_dir / DATA_SUBDIR

# Aliases mapping short user-facing names to schema keys from entity-schema.json
TYPE_ALIASES = {
    "dimensions": "research-dimensions",
    "questions": "refined-questions",
    "batches": "query-batches",
}


def resolve_type_key(name: str) -> str:
    """Resolve a short alias or schema key to the canonical schema key."""
    return TYPE_ALIASES.get(name, name)


# Priority order for RAG relevance (higher = more relevant)
# Keys here use short aliases for backward compat; resolved at lookup time
ENTITY_PRIORITY = {
    "findings": 80,
    "claims": 60,
    "sources": 40,
    "research-dimensions": 50,
    "refined-questions": 40,
    "initial-question": 30,
    "query-batches": 20,
}

# Frontmatter fields that contain entity references (values = canonical schema keys)
# Note: "dimension" (plain slug) deliberately excluded — dimension_ref (wikilink) handles it
RELATIONSHIP_FIELDS = {
    "source_refs": "sources",
    "source_id": "sources",
    "source_ref": "sources",
    "finding_refs": "findings",
    "supporting_findings": "findings",
    "claim_refs": "claims",
    "dimension_ref": "research-dimensions",
    "dimension_id": "research-dimensions",
    "question_ref": "refined-questions",
    "initial_question_ref": "initial-question",
    "addresses_questions": "refined-questions",
    "batch_id": "query-batches",
    "batch_ref": "query-batches",
    "query_batch_refs": "query-batches",
    "question_id": "refined-questions",
    "source_references": "sources",
}

# Inverse relationship names for bidirectional references (keys = canonical schema keys)
INVERSE_RELATIONSHIPS = {
    "sources": "cited_by",
    "findings": "supports",
    "claims": "cited_by",
    "research-dimensions": "contains",
    "refined-questions": "answers",
    "initial-question": "answers",
    "query-batches": "generated",
    "parent": "children",
    "children": "parent",
    "mentions": "mentioned_by",
}

# Wikilink pattern for extraction
WIKILINK_PATTERN = re.compile(r"\[\[([^\]|]+)(?:\|([^\]]+))?\]\]")


@dataclass
class EntityRef:
    """Reference to another entity."""
    entity_id: str          # Canonical ID (e.g., "source-market-report-a7f3b2c1")
    entity_type: str        # Entity type (e.g., "sources")
    display_name: str = ""  # Human-readable title


@dataclass
class Entity:
    """Research entity with its relationships."""
    canonical_id: str                                    # Unique ID
    entity_type: str                                     # Type (findings, sources, etc.)
    title: str                                           # Display title
    file_path: str                                       # Original file path
    frontmatter: Dict = field(default_factory=dict)      # Parsed frontmatter
    outgoing: Dict[str, List[EntityRef]] = field(default_factory=dict)  # This entity references
    incoming: Dict[str, List[EntityRef]] = field(default_factory=dict)  # References this entity


@dataclass
class RelationshipGraph:
    """Graph of all entity relationships."""
    entities: Dict[str, Entity] = field(default_factory=dict)  # canonical_id -> Entity
    by_type: Dict[str, Set[str]] = field(default_factory=dict)  # type -> set of IDs
    filename_index: Dict[str, str] = field(default_factory=dict)  # filename stem -> canonical_id


def _parse_yaml_value(raw: str) -> object:
    """Parse a scalar YAML value into its Python type."""
    if not raw:
        return ""
    # Inline array: [a, b, c] — but NOT wikilinks [[...]]
    if raw.startswith("[") and not raw.startswith("[[") and raw.endswith("]"):
        inner = raw[1:-1]
        if not inner.strip():
            return []
        return [_parse_yaml_value(item.strip()) for item in inner.split(",")]
    # Booleans
    if raw.lower() in ("true", "yes"):
        return True
    if raw.lower() in ("false", "no"):
        return False
    # Numbers (int then float)
    try:
        return int(raw)
    except ValueError:
        pass
    try:
        return float(raw)
    except ValueError:
        pass
    # Null
    if raw.lower() in ("null", "~"):
        return None
    return raw


def parse_frontmatter(content: str) -> Tuple[Dict, str]:
    """Parse YAML frontmatter from markdown content.

    Handles: top-level key:value, nested objects (one level), list items
    (``- value``), inline arrays (``[a, b]``), booleans, and numbers.
    """
    if not content.startswith("---"):
        return {}, content

    try:
        end_idx = content.index("---", 3)
        frontmatter_str = content[3:end_idx].strip()
        body = content[end_idx + 3:].strip()

        frontmatter: Dict = {}
        # current_key/current_list track the top-level key awaiting list items
        current_key: Optional[str] = None
        current_list: Optional[list] = None
        # nested_key/nested_dict track a one-level nested object block
        nested_key: Optional[str] = None
        nested_dict: Optional[Dict] = None

        def _flush():
            """Flush pending nested dict or list to frontmatter."""
            nonlocal nested_key, nested_dict, current_key, current_list
            if nested_key is not None and nested_dict is not None:
                if nested_dict:
                    # Nested object had sub-keys — store as dict
                    frontmatter[nested_key] = nested_dict
                elif current_list:
                    # No sub-keys but list items were collected — store as list
                    frontmatter[nested_key] = current_list if len(current_list) != 1 else current_list[0]
                else:
                    frontmatter[nested_key] = ""
                nested_key = None
                nested_dict = None
                current_key = None
                current_list = None
            elif current_key is not None and current_list is not None:
                frontmatter[current_key] = current_list if len(current_list) != 1 else current_list[0]
                current_key = None
                current_list = None

        for line in frontmatter_str.split("\n"):
            stripped = line.rstrip()

            # Blank line — close any open state
            if not stripped:
                _flush()
                continue

            # Indented line — part of a list or nested object
            if stripped.startswith("  "):
                indent_content = stripped[2:]  # Remove exactly 2 leading spaces

                # Inside a nested object block
                if nested_key is not None and nested_dict is not None:
                    # List item under nested key: "  - value"
                    if indent_content.lstrip().startswith("- "):
                        item = indent_content.lstrip()[2:].strip().strip('"').strip("'")
                        # This means the parent key is actually a list, not a nested dict
                        # Convert: clear nested_dict and switch to list mode
                        if not nested_dict:
                            # No sub-keys seen yet — this is a plain list
                            nested_key = None
                            nested_dict = None
                            if current_list is None:
                                current_list = []
                            current_list.append(_parse_yaml_value(item))
                        continue
                    # Sub-key: "  sub_key: value"
                    if ":" in indent_content:
                        sub_key, _, sub_val = indent_content.partition(":")
                        sub_key = sub_key.strip()
                        sub_val = sub_val.strip().strip('"').strip("'")
                        nested_dict[sub_key] = _parse_yaml_value(sub_val) if sub_val else ""
                        continue
                    continue

                # List item: "  - value"
                if indent_content.lstrip().startswith("- "):
                    item = indent_content.lstrip()[2:].strip().strip('"').strip("'")
                    if current_key is not None:
                        if current_list is None:
                            current_list = []
                        current_list.append(_parse_yaml_value(item))
                    continue

                # Plain continuation
                if current_key is not None and current_list is not None:
                    current_list.append(_parse_yaml_value(indent_content.strip().strip('"').strip("'")))
                continue

            # Top-level line — flush any pending state
            _flush()

            # Top-level list item (no key context — rare, skip)
            if stripped.startswith("- "):
                continue

            # Top-level key: value
            # Prefer ': ' to avoid splitting on namespace prefixes like dc:title
            if ": " in stripped:
                key, _, value = stripped.partition(": ")
                key = key.strip()
                value = value.strip().strip('"').strip("'")
            elif ":" in stripped:
                key, _, value = stripped.partition(":")
                key = key.strip()
                value = value.strip().strip('"').strip("'")
            else:
                continue

            if value:
                # Immediate value — store directly
                frontmatter[key] = _parse_yaml_value(value)
                current_key = key
                current_list = None
            else:
                # No value — could be start of nested object or list
                current_key = key
                current_list = []
                nested_key = key
                nested_dict = {}

        # Flush remaining state
        _flush()

        return frontmatter, body

    except ValueError:
        return {}, content


def resolve_wikilinks(content: str, entity_type: str, graph: Optional[RelationshipGraph] = None) -> str:
    """Convert [[wikilinks]] to text with preserved entity IDs for RAG retrieval."""
    def replace_link(match):
        link = match.group(1)
        if "|" in link:
            path, display = link.split("|", 1)
        else:
            path = link
            display = None

        # Extract entity ID from path
        entity_id = Path(path).stem

        # Try to resolve to canonical ID and get title
        resolved_id = entity_id
        resolved_title = None
        if graph and graph.entities:
            canonical = resolve_entity_id(entity_id, graph.entities, graph.filename_index or None)
            if canonical:
                resolved_id = canonical
                resolved_title = graph.entities[canonical].title

        # Use display text, resolved title, or cleaned ID
        if display:
            text = display.strip()
        elif resolved_title:
            text = resolved_title
        else:
            text = entity_id.replace("-", " ").title()

        # Include canonical ID for RAG searchability
        return f"{text} (ID: `{resolved_id}`)"

    return re.sub(r"\[\[([^\]]+)\]\]", replace_link, content)


def clean_markdown_for_rag(content: str) -> str:
    """Clean markdown content for optimal RAG retrieval."""
    # Remove excessive whitespace
    content = re.sub(r"\n{3,}", "\n\n", content)

    # Remove HTML comments
    content = re.sub(r"<!--.*?-->", "", content, flags=re.DOTALL)

    # Convert inline wikilink citations to preserve entity IDs
    # Input: <sup>[[04-findings/data/finding-skills-gap|1]]</sup>
    # Output: [1: finding-skills-gap]
    def replace_citation(match):
        path = match.group(1)
        number = match.group(2)
        # Extract entity ID from path (last segment of path)
        entity_id = path.split('/')[-1] if '/' in path else path
        return f"[{number}: `{entity_id}`]"

    content = re.sub(
        r"<sup>\[\[([^\]|]+)\|([^\]]+)\]\]</sup>",
        replace_citation,
        content
    )

    return content.strip()


def extract_title(frontmatter: Dict, body: str, filename: str) -> str:
    """Extract a meaningful title from entity."""
    # Try frontmatter fields
    for field in ["dc:title", "title", "dc:identifier"]:
        if field in frontmatter:
            title = frontmatter[field]
            if isinstance(title, list):
                title = title[0]
            # Clean up title
            title = re.sub(r"^(Finding|Claim|Source):\s*", "", title)
            return title

    # Try first heading
    heading_match = re.search(r"^#\s+(.+)$", body, re.MULTILINE)
    if heading_match:
        return heading_match.group(1)

    # Fall back to filename
    return filename.replace("-", " ").replace("_", " ").title()


def generate_canonical_id(entity_type: str, filename: str, frontmatter: Dict) -> str:
    """Generate a consistent canonical ID for an entity."""
    # Try dc:identifier first (most authoritative)
    if "dc:identifier" in frontmatter:
        return frontmatter["dc:identifier"]

    # Fallback: use filename stem (already includes type prefix)
    return Path(filename).stem


def parse_wikilink(wikilink_content: str) -> Tuple[Optional[str], Optional[str], Optional[str]]:
    """Parse wikilink content into (directory, entity_id, display_text)."""
    if "|" in wikilink_content:
        path, display = wikilink_content.split("|", 1)
    else:
        path = wikilink_content
        display = None

    path = path.strip()
    if "/" in path:
        directory, entity_id = path.rsplit("/", 1)
    else:
        directory = None
        entity_id = path

    return directory, entity_id, display


def resolve_entity_id(target_id: str, entities: Dict[str, Entity],
                      filename_index: Optional[Dict[str, str]] = None) -> Optional[str]:
    """Resolve a target reference to a canonical entity ID."""
    # Direct match
    if target_id in entities:
        return target_id

    # Strip directory prefix (e.g. "04-findings/data/finding-abc123" -> "finding-abc123")
    clean_id = target_id.split("/")[-1] if "/" in target_id else target_id
    if clean_id != target_id and clean_id in entities:
        return clean_id

    # Filename-stem match (handles UUID filenames with semantic dc:identifier)
    if filename_index:
        if clean_id in filename_index:
            return filename_index[clean_id]

    # Suffix match — constrained to same entity-type prefix to avoid false positives
    target_type = infer_entity_type_from_id(clean_id)
    if len(clean_id) >= 8:
        for canonical_id in entities:
            if canonical_id.endswith(clean_id[-8:]):
                if target_type == "unknown" or infer_entity_type_from_id(canonical_id) == target_type:
                    return canonical_id

    return None


def infer_entity_type_from_id(entity_id: str) -> str:
    """Infer entity type from entity ID prefix. Returns canonical schema keys."""
    # Longer prefixes first to avoid "synthesis-" matching "source-" etc.
    prefix_map = {
        "query-batch-": "query-batches",
        "source-": "sources",
        "finding-": "findings",
        "claim-": "claims",
        "dimension-": "research-dimensions",
        "question-": "refined-questions",
        "batch-": "query-batches",
    }
    for prefix, etype in prefix_map.items():
        if entity_id.startswith(prefix):
            return etype
    return "unknown"


def discover_all_entities(project_path: Path) -> Tuple[Dict[str, Entity], Dict[str, str]]:
    """First pass: discover all entities and build initial registry.

    Returns:
        (entities, filename_index) where filename_index maps filename stems
        to canonical IDs for entities where they differ (e.g. UUID filenames).
    """
    entities = {}

    for entity_type in ENTITY_DIRS:
        source_dir = get_entity_source_dir(project_path, entity_type)
        if not source_dir or not source_dir.exists():
            continue

        for md_file in source_dir.glob("*.md"):

            try:
                content = md_file.read_text(encoding="utf-8")
                frontmatter, body = parse_frontmatter(content)

                # Skip empty content
                if len(body.strip()) < 50:
                    continue

                canonical_id = generate_canonical_id(entity_type, md_file.name, frontmatter)
                title = extract_title(frontmatter, body, md_file.stem)

                entity = Entity(
                    canonical_id=canonical_id,
                    entity_type=entity_type,
                    title=title,
                    file_path=str(md_file),
                    frontmatter=frontmatter,
                )
                entities[canonical_id] = entity

            except Exception as e:
                print(f"Warning: Error reading {md_file}: {e}", file=sys.stderr)

    # Build filename-stem -> canonical_id index for UUID-filename resolution
    filename_index = {}
    for entity in entities.values():
        stem = Path(entity.file_path).stem
        if stem != entity.canonical_id:
            filename_index[stem] = entity.canonical_id

    return entities, filename_index


def extract_relationships(entity: Entity, body: str, all_entities: Dict[str, Entity],
                          filename_index: Optional[Dict[str, str]] = None) -> None:
    """Extract relationships from frontmatter and body wikilinks."""
    frontmatter = entity.frontmatter

    # Extract from frontmatter fields
    for field_name, rel_type in RELATIONSHIP_FIELDS.items():
        if field_name not in frontmatter:
            continue

        value = frontmatter[field_name]
        values = [value] if isinstance(value, str) else (value if isinstance(value, list) else [])

        for v in values:
            if not v:
                continue

            # Handle wikilink format or plain ID
            if "[[" in str(v):
                match = WIKILINK_PATTERN.search(str(v))
                if match:
                    _, target_id, display = parse_wikilink(match.group(1))
                else:
                    continue
            else:
                target_id = str(v).split("/")[-1] if "/" in str(v) else str(v)
                display = None

            if not target_id:
                continue

            # Resolve to canonical ID
            resolved_id = resolve_entity_id(target_id, all_entities, filename_index)
            if not resolved_id:
                # Store unresolved reference anyway for completeness
                resolved_id = target_id

            target_type = infer_entity_type_from_id(resolved_id)
            target_title = ""
            if resolved_id in all_entities:
                target_title = all_entities[resolved_id].title

            ref = EntityRef(
                entity_id=resolved_id,
                entity_type=target_type,
                display_name=display or target_title,
            )

            if rel_type not in entity.outgoing:
                entity.outgoing[rel_type] = []

            # Avoid duplicates
            if not any(r.entity_id == ref.entity_id for r in entity.outgoing[rel_type]):
                entity.outgoing[rel_type].append(ref)

    # Extract from body wikilinks
    for match in WIKILINK_PATTERN.finditer(body):
        directory, target_id, display = parse_wikilink(match.group(1))
        if not target_id:
            continue

        resolved_id = resolve_entity_id(target_id, all_entities, filename_index)
        if not resolved_id:
            resolved_id = target_id

        target_type = infer_entity_type_from_id(resolved_id)
        target_title = ""
        if resolved_id in all_entities:
            target_title = all_entities[resolved_id].title

        ref = EntityRef(
            entity_id=resolved_id,
            entity_type=target_type,
            display_name=display or target_title,
        )

        rel_type = "mentions"  # Generic relationship for body references
        if rel_type not in entity.outgoing:
            entity.outgoing[rel_type] = []

        if not any(r.entity_id == ref.entity_id for r in entity.outgoing[rel_type]):
            entity.outgoing[rel_type].append(ref)


def build_relationship_graph(entities: Dict[str, Entity],
                             filename_index: Optional[Dict[str, str]] = None) -> RelationshipGraph:
    """Build complete relationship graph with bidirectional references."""
    graph = RelationshipGraph(entities=entities, filename_index=filename_index or {})

    # Index by type
    for entity_id, entity in entities.items():
        if entity.entity_type not in graph.by_type:
            graph.by_type[entity.entity_type] = set()
        graph.by_type[entity.entity_type].add(entity_id)

    # First pass: extract all outgoing relationships
    for entity in entities.values():
        try:
            content = Path(entity.file_path).read_text(encoding="utf-8")
            _, body = parse_frontmatter(content)
            extract_relationships(entity, body, entities, filename_index)
        except Exception as e:
            print(f"Warning: Error extracting relationships from {entity.file_path}: {e}", file=sys.stderr)

    # Second pass: build incoming (inverse) relationships
    for source_id, source_entity in entities.items():
        for rel_type, refs in source_entity.outgoing.items():
            inverse_type = INVERSE_RELATIONSHIPS.get(rel_type, "referenced_by")

            for ref in refs:
                target_id = ref.entity_id
                if target_id not in entities:
                    continue

                target_entity = entities[target_id]

                # Create inverse reference
                inverse_ref = EntityRef(
                    entity_id=source_id,
                    entity_type=source_entity.entity_type,
                    display_name=source_entity.title,
                )

                if inverse_type not in target_entity.incoming:
                    target_entity.incoming[inverse_type] = []

                # Avoid duplicates
                if not any(r.entity_id == inverse_ref.entity_id for r in target_entity.incoming[inverse_type]):
                    target_entity.incoming[inverse_type].append(inverse_ref)

    return graph


def format_relationship_section(
    entity: Entity,
    graph: RelationshipGraph,
    compact: bool = False
) -> str:
    """Generate the relationship metadata section for an exported file."""
    if not entity.outgoing and not entity.incoming:
        return ""

    lines = [
        "",
        "---",
        "",
        "## Related Entities",
        "",
        f"**ID**: `{entity.canonical_id}`",
        "",
    ]

    # Outgoing relationships
    if entity.outgoing:
        lines.append("### References")
        for rel_type, refs in sorted(entity.outgoing.items()):
            if not refs:
                continue

            label = rel_type.replace("_", " ").title()
            if compact:
                ids = ", ".join(f"`{r.entity_id}`" for r in refs[:3])
                extra = f" +{len(refs)-3}" if len(refs) > 3 else ""
                lines.append(f"- **{label}** ({len(refs)}): {ids}{extra}")
            else:
                lines.append(f"- **{label}** ({len(refs)}):")
                for ref in refs[:5]:
                    if ref.display_name:
                        lines.append(f"  - `{ref.entity_id}`: \"{ref.display_name}\"")
                    else:
                        lines.append(f"  - `{ref.entity_id}`")
                if len(refs) > 5:
                    lines.append(f"  - ... and {len(refs) - 5} more")
        lines.append("")

    # Incoming relationships
    if entity.incoming:
        lines.append("### Referenced By")
        for rel_type, refs in sorted(entity.incoming.items()):
            if not refs:
                continue

            label = rel_type.replace("_", " ").title()
            if compact:
                ids = ", ".join(f"`{r.entity_id}`" for r in refs[:3])
                extra = f" +{len(refs)-3}" if len(refs) > 3 else ""
                lines.append(f"- **{label}** ({len(refs)}): {ids}{extra}")
            else:
                lines.append(f"- **{label}** ({len(refs)}):")
                for ref in refs[:5]:
                    if ref.display_name:
                        lines.append(f"  - `{ref.entity_id}`: \"{ref.display_name}\"")
                    else:
                        lines.append(f"  - `{ref.entity_id}`")
                if len(refs) > 5:
                    lines.append(f"  - ... and {len(refs) - 5} more")
        lines.append("")

    # Generate search keywords
    keywords = [entity.entity_type, entity.canonical_id.split("-")[0]]
    for rel_type, refs in entity.outgoing.items():
        if refs:
            keywords.append(f"{rel_type}:{len(refs)}")
    for rel_type, refs in entity.incoming.items():
        if refs:
            keywords.append(f"has-{rel_type}:{len(refs)}")

    lines.extend([
        "---",
        f"**Keywords**: {', '.join(keywords[:10])}",
    ])

    return "\n".join(lines)


def create_rag_document(
    entity_type: str,
    filename: str,
    frontmatter: Dict,
    body: str,
    project_name: str,
    entity: Optional[Entity] = None,
    graph: Optional[RelationshipGraph] = None,
    relationship_format: str = "full"
) -> str:
    """Create a RAG-optimized document from entity content with relationships."""
    title = extract_title(frontmatter, body, filename)

    # Get canonical ID if available
    canonical_id = entity.canonical_id if entity else generate_canonical_id(entity_type, filename, frontmatter)

    # Build metadata header
    lines = [
        f"# {title}",
        "",
        f"**Type**: {entity_type.title()}",
        f"**ID**: `{canonical_id}`",
        f"**Project**: {project_name}",
    ]

    # Add key metadata
    if "dc:created" in frontmatter:
        lines.append(f"**Created**: {frontmatter['dc:created']}")

    # Confidence: check type-specific field names
    for conf_field in ["confidence_score", "evidence_confidence"]:
        if conf_field in frontmatter:
            lines.append(f"**Confidence**: {frontmatter[conf_field]}")
            break
    else:
        if "quality_score" in frontmatter:
            lines.append(f"**Quality Score**: {frontmatter['quality_score']}")

    # Dimension reference
    dim = frontmatter.get("dimension")
    if dim:
        if isinstance(dim, list):
            dim = ", ".join(str(d) for d in dim)
        lines.append(f"**Dimension**: {dim}")

    # Entity-type-specific metadata
    if entity_type == "sources":
        if "url" in frontmatter:
            lines.append(f"**URL**: {frontmatter['url']}")
        if "domain" in frontmatter:
            lines.append(f"**Domain**: {frontmatter['domain']}")
        if "reliability_tier" in frontmatter:
            lines.append(f"**Reliability**: {frontmatter['reliability_tier']}")

    if entity_type == "claims":
        if "verification_status" in frontmatter:
            lines.append(f"**Verification**: {frontmatter['verification_status']}")

    if entity_type == "findings":
        if "confidence_level" in frontmatter:
            lines.append(f"**Confidence Level**: {frontmatter['confidence_level']}")
        if "finding_type" in frontmatter:
            lines.append(f"**Finding Type**: {frontmatter['finding_type']}")

    if "tags" in frontmatter:
        tags = frontmatter["tags"]
        if isinstance(tags, list):
            tags = ", ".join(str(t) for t in tags)
        elif isinstance(tags, str) and tags.startswith("["):
            # Fallback for unparsed inline arrays
            tags = tags[1:-1].replace(",", ", ")
        lines.append(f"**Tags**: {tags}")

    lines.append("")
    lines.append("---")
    lines.append("")

    # Clean and add body with preserved entity IDs
    body = resolve_wikilinks(body, entity_type, graph)
    body = clean_markdown_for_rag(body)

    # Remove duplicate title heading if present
    body = re.sub(r"^#\s+" + re.escape(title) + r"\s*\n+", "", body)

    lines.append(body)

    # Add relationship section if entity and graph are provided
    if entity and graph and relationship_format != "none":
        compact = relationship_format == "compact"
        rel_section = format_relationship_section(entity, graph, compact=compact)
        if rel_section:
            lines.append(rel_section)

    return "\n".join(lines)


def generate_output_filename(entity_type: str, original_name: str, idx: int) -> str:
    """Generate a descriptive filename for RAG export."""
    # Clean up the name
    name = original_name.replace(".md", "")

    # Remove entity type prefix if present
    for prefix in [
        "query-batch-", "dimension-", "question-", "finding-", "source-",
        "claim-", "batch-",
    ]:
        if name.startswith(prefix):
            name = name[len(prefix):]
            break

    # Truncate long names
    if len(name) > 60:
        name = name[:60]

    # Create descriptive filename (uses schema keys)
    prefix_map = {
        "findings": "finding",
        "claims": "claim",
        "sources": "source",
        "research-dimensions": "dimension",
        "refined-questions": "question",
        "initial-question": "question",
        "query-batches": "batch",
    }

    prefix = prefix_map.get(entity_type, entity_type)
    return f"{prefix}-{name}.md"


def export_entity_type(
    project_path: Path,
    output_dir: Path,
    entity_type: str,
    project_name: str,
    graph: Optional[RelationshipGraph] = None,
    max_file_size_kb: int = 200,
    relationship_format: str = "full"
) -> List[str]:
    """Export all entities of a given type with relationship information."""
    source_dir = get_entity_source_dir(project_path, entity_type)
    if not source_dir:
        print(f"Warning: Unknown entity type '{entity_type}'", file=sys.stderr)
        return []

    if not source_dir.exists():
        print(f"Info: Directory {source_dir} not found, skipping", file=sys.stderr)
        return []

    exported = []
    idx = 0

    for md_file in sorted(source_dir.glob("*.md")):

        try:
            content = md_file.read_text(encoding="utf-8")
            frontmatter, body = parse_frontmatter(content)

            # Skip empty or minimal content
            if len(body.strip()) < 50:
                continue

            # Get entity from graph if available
            canonical_id = generate_canonical_id(entity_type, md_file.name, frontmatter)
            entity = graph.entities.get(canonical_id) if graph else None

            # Create RAG document with relationships
            rag_content = create_rag_document(
                entity_type,
                md_file.stem,
                frontmatter,
                body,
                project_name,
                entity=entity,
                graph=graph,
                relationship_format=relationship_format
            )

            # Check file size - use compact format if too large
            size_kb = len(rag_content.encode("utf-8")) / 1024
            if size_kb > max_file_size_kb and relationship_format == "full":
                # Retry with compact format
                rag_content = create_rag_document(
                    entity_type,
                    md_file.stem,
                    frontmatter,
                    body,
                    project_name,
                    entity=entity,
                    graph=graph,
                    relationship_format="compact"
                )
                size_kb = len(rag_content.encode("utf-8")) / 1024

            if size_kb > max_file_size_kb:
                print(f"Warning: {md_file.name} exceeds {max_file_size_kb}KB ({size_kb:.1f}KB)", file=sys.stderr)

            # Generate output filename
            output_name = generate_output_filename(entity_type, md_file.stem, idx)
            output_path = output_dir / output_name

            # Handle duplicates
            counter = 1
            while output_path.exists():
                base = output_name.rsplit(".", 1)[0]
                output_path = output_dir / f"{base}-{counter}.md"
                counter += 1

            output_path.write_text(rag_content, encoding="utf-8")
            exported.append(output_name)
            idx += 1

        except Exception as e:
            print(f"Error processing {md_file}: {e}", file=sys.stderr)

    return exported


def export_research_hub(
    project_path: Path,
    output_dir: Path,
    project_name: str,
    graph: Optional[RelationshipGraph] = None
) -> Optional[str]:
    """Export the main research hub."""
    report_path = project_path / "research-hub.md"
    if not report_path.exists():
        report_path = project_path / ".research-hub.md"

    if not report_path.exists():
        return None

    try:
        content = report_path.read_text(encoding="utf-8")
        frontmatter, body = parse_frontmatter(content)

        # Clean for RAG with entity IDs preserved
        body = resolve_wikilinks(body, "report", graph)
        body = clean_markdown_for_rag(body)

        # Add metadata header
        header = f"""# Research Report: {project_name}

**Type**: Research Report
**Project**: {project_name}
**Generated**: {datetime.now().isoformat()}

---

"""
        output_content = header + body

        output_name = "00-research-hub.md"
        output_path = output_dir / output_name
        output_path.write_text(output_content, encoding="utf-8")

        return output_name

    except Exception as e:
        print(f"Error exporting research report: {e}", file=sys.stderr)
        return None


def create_index_file(
    output_dir: Path,
    project_name: str,
    exported_files: Dict[str, List[str]],
    report_file: Optional[str]
) -> str:
    """Create an index file listing all exported content."""
    lines = [
        f"# RAG Export Index: {project_name}",
        "",
        f"**Export Date**: {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"**Total Files**: {sum(len(f) for f in exported_files.values()) + (1 if report_file else 0)}",
        "",
        "---",
        "",
        "## Contents",
        "",
    ]

    if report_file:
        lines.extend([
            "### Research Report",
            f"- [{report_file}]({report_file})",
            "",
        ])

    for entity_type, files in exported_files.items():
        if files:
            lines.append(f"### {entity_type.title()} ({len(files)} files)")
            for f in sorted(files)[:10]:  # Show first 10
                lines.append(f"- [{f}]({f})")
            if len(files) > 10:
                lines.append(f"- ... and {len(files) - 10} more")
            lines.append("")

    content = "\n".join(lines)
    index_path = output_dir / "00-index.md"
    index_path.write_text(content, encoding="utf-8")

    return "00-index.md"


def main():
    parser = argparse.ArgumentParser(
        description="Export research project entities for Claude Projects RAG"
    )
    parser.add_argument("project_path", help="Path to the research project")
    parser.add_argument("output_dir", nargs="?", default=None,
                        help="Destination directory (default: ./<project-slug>)")
    parser.add_argument(
        "--entity-types",
        default=None,
        help="Comma-separated list of entity types to export (default: all)"
    )
    parser.add_argument(
        "--include-report",
        action="store_true",
        help="Include research-hub.md in export"
    )
    parser.add_argument(
        "--max-file-size",
        type=int,
        default=200,
        help="Maximum file size in KB (default: 200)"
    )
    parser.add_argument(
        "--relationship-format",
        choices=["full", "compact", "none"],
        default="full",
        help="Relationship section format: full (detailed), compact (IDs only), none (disabled)"
    )

    args = parser.parse_args()

    project_path = Path(args.project_path).resolve()
    if args.entity_types is None:
        entity_types = list(ENTITY_DIRS.keys())
    else:
        entity_types = [resolve_type_key(t.strip()) for t in args.entity_types.split(",")]

    # Validate project path
    if not project_path.exists():
        print(f"Error: Project path does not exist: {project_path}", file=sys.stderr)
        sys.exit(1)

    # Resolve output directory (default: <project>/export-rag)
    if args.output_dir:
        output_dir = Path(args.output_dir).resolve()
    else:
        output_dir = project_path / 'export-rag'

    # Create output directory
    output_dir.mkdir(parents=True, exist_ok=True)

    # Extract project name
    project_name = project_path.name

    print(f"Exporting project: {project_name}")
    print(f"Entity types: {', '.join(entity_types)}")
    print(f"Relationship format: {args.relationship_format}")
    print(f"Output directory: {output_dir}")
    print()

    # Phase 1: Discover all entities
    graph = None
    if args.relationship_format != "none":
        print("Phase 1: Discovering entities...")
        all_entities, filename_index = discover_all_entities(project_path)
        print(f"  Found {len(all_entities)} entities")
        if filename_index:
            print(f"  {len(filename_index)} filename-to-canonical mappings (UUID filenames)")

        # Phase 2: Build relationship graph
        print("Phase 2: Building relationship graph...")
        graph = build_relationship_graph(all_entities, filename_index)
        total_rels = sum(len(refs) for e in graph.entities.values() for refs in e.outgoing.values())
        total_incoming = sum(len(refs) for e in graph.entities.values() for refs in e.incoming.values())
        print(f"  {total_rels} outgoing relationships")
        print(f"  {total_incoming} incoming (bidirectional) references")
        print()

    # Phase 3: Export entities with relationships
    print("Phase 3: Exporting entities...")
    exported_files = {}
    for entity_type in entity_types:
        files = export_entity_type(
            project_path,
            output_dir,
            entity_type,
            project_name,
            graph=graph,
            max_file_size_kb=args.max_file_size,
            relationship_format=args.relationship_format
        )
        exported_files[entity_type] = files
        print(f"  {entity_type}: {len(files)} files exported")

    # Export research hub if requested
    report_file = None
    if args.include_report:
        report_file = export_research_hub(project_path, output_dir, project_name, graph)
        if report_file:
            print(f"  research hub: exported")

    # Create index
    index_file = create_index_file(output_dir, project_name, exported_files, report_file)

    total = sum(len(f) for f in exported_files.values()) + (1 if report_file else 0) + 1
    print()
    print(f"Export complete: {total} files written to {output_dir}")

    # Output summary as JSON for script integration
    summary = {
        "project_name": project_name,
        "output_dir": str(output_dir),
        "total_files": total,
        "entity_counts": {k: len(v) for k, v in exported_files.items()},
        "has_report": report_file is not None,
        "index_file": index_file,
        "relationship_format": args.relationship_format,
        "total_entities_discovered": len(graph.entities) if graph else 0,
    }

    print()
    print("Summary (JSON):")
    print(json.dumps(summary, indent=2))


if __name__ == "__main__":
    main()

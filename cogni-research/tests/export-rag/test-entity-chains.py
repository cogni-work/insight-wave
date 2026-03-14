#!/usr/bin/env python3
"""
Test entity chain integrity in export-rag.

Validates that entity relationships are correctly preserved so the full chain
(synthesis -> trend -> claim -> finding -> source -> publisher) remains navigable.

Usage:
    python test-entity-chains.py [project_path]

If no project_path is given, runs unit tests against synthetic data only.
"""

import os
import re
import sys
import tempfile
from pathlib import Path

# Add export-rag scripts to path
SCRIPT_DIR = Path(__file__).resolve().parent.parent.parent / "skills" / "export-rag" / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

# Add scripts/lib to path for entity_config
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent / "scripts" / "lib"))

from export_rag import (
    RELATIONSHIP_FIELDS,
    Entity,
    RelationshipGraph,
    build_relationship_graph,
    discover_all_entities,
    infer_entity_type_from_id,
    resolve_entity_id,
)

# ANSI colors
GREEN = "\033[32m"
RED = "\033[31m"
YELLOW = "\033[33m"
RESET = "\033[0m"

passed = 0
failed = 0
warnings = 0


def ok(msg):
    global passed
    passed += 1
    print(f"  {GREEN}✓{RESET} {msg}")


def fail(msg):
    global failed
    failed += 1
    print(f"  {RED}✗{RESET} {msg}")


def warn(msg):
    global warnings
    warnings += 1
    print(f"  {YELLOW}⚠{RESET} {msg}")


# ── Test 1: RELATIONSHIP_FIELDS coverage ──

def test_relationship_fields_coverage():
    """Verify known frontmatter relationship fields have mappings."""
    print("\nTest 1: RELATIONSHIP_FIELDS coverage")
    print("=" * 50)

    known_fields = {
        # These are all fields observed in real entity frontmatter that contain entity references
        "source_refs", "source_id", "source_ref",
        "finding_refs", "supporting_findings",
        "claim_refs", "citation_refs",
        "megatrend_refs", "related_megatrends", "megatrend_ids",
        "concept_refs", "related_concepts",
        "dimension_ref", "dimension_id",
        "question_ref", "question_id",
        "initial_question_ref",
        "addresses_questions",
        "publisher_id", "publisher_ref",
        "batch_id", "batch_ref", "query_batch_refs",
        "related_trends",
        "parent_megatrend_ref", "submegatrend_refs",
        "source_references",
    }

    missing = known_fields - set(RELATIONSHIP_FIELDS.keys())
    if missing:
        for f in sorted(missing):
            fail(f"Missing RELATIONSHIP_FIELDS entry: '{f}'")
    else:
        ok(f"All {len(known_fields)} known relationship fields are mapped")


# ── Test 2: resolve_entity_id — direct match ──

def test_direct_match():
    """Every entity should resolve to itself by canonical ID."""
    print("\nTest 2: Direct match resolution")
    print("=" * 50)

    entities = {
        "finding-abc-12345678": Entity("finding-abc-12345678", "findings", "Test", "/dev/null"),
        "source-xyz-87654321": Entity("source-xyz-87654321", "sources", "Test", "/dev/null"),
        "trend-foo-aabbccdd": Entity("trend-foo-aabbccdd", "trends", "Test", "/dev/null"),
    }

    all_pass = True
    for eid in entities:
        result = resolve_entity_id(eid, entities)
        if result != eid:
            fail(f"Direct match failed for '{eid}': got '{result}'")
            all_pass = False

    if all_pass:
        ok(f"All {len(entities)} entities resolve to themselves")


# ── Test 3: resolve_entity_id — filename index ──

def test_filename_index_resolution():
    """UUID filenames should resolve via filename_index."""
    print("\nTest 3: Filename index (UUID) resolution")
    print("=" * 50)

    # Simulate: file is "finding-006f4003-3333-47ec-abcd.md" but dc:identifier is "finding-ai-analytics-revenue-l2m3n4o5"
    semantic_id = "finding-ai-analytics-revenue-l2m3n4o5"
    uuid_stem = "finding-006f4003-3333-47ec-abcd"

    entities = {
        semantic_id: Entity(semantic_id, "findings", "AI Analytics Revenue", f"/fake/{uuid_stem}.md"),
    }
    filename_index = {uuid_stem: semantic_id}

    # Direct reference to UUID filename should resolve
    result = resolve_entity_id(uuid_stem, entities, filename_index)
    if result == semantic_id:
        ok(f"UUID stem '{uuid_stem}' resolved to '{semantic_id}'")
    else:
        fail(f"UUID stem '{uuid_stem}' resolved to '{result}' (expected '{semantic_id}')")

    # Path-prefixed UUID should also resolve
    path_ref = f"04-findings/data/{uuid_stem}"
    result = resolve_entity_id(path_ref, entities, filename_index)
    if result == semantic_id:
        ok(f"Path-prefixed UUID resolved correctly")
    else:
        fail(f"Path-prefixed UUID resolved to '{result}' (expected '{semantic_id}')")


# ── Test 4: resolve_entity_id — suffix match hardened ──

def test_suffix_match_type_constraint():
    """Suffix match should not cross entity types."""
    print("\nTest 4: Suffix match type constraint")
    print("=" * 50)

    entities = {
        "finding-abc-12345678": Entity("finding-abc-12345678", "findings", "A Finding", "/dev/null"),
        "source-xyz-12345678": Entity("source-xyz-12345678", "sources", "A Source", "/dev/null"),
    }

    # A finding reference should match the finding, not the source
    result = resolve_entity_id("finding-qqq-12345678", entities)
    if result == "finding-abc-12345678":
        ok("Suffix match constrained to same entity type (finding -> finding)")
    elif result == "source-xyz-12345678":
        fail("Suffix match crossed entity types (finding -> source)")
    else:
        fail(f"Suffix match returned unexpected: '{result}'")

    # An unknown-type reference should still match (backwards compat)
    result = resolve_entity_id("12345678", entities)
    if result is not None:
        ok(f"Unknown-type suffix still matches (got '{result}')")
    else:
        warn("Unknown-type suffix returned None (may be acceptable)")


# ── Test 5: discover_all_entities returns filename_index ──

def test_discover_returns_filename_index():
    """discover_all_entities should return (entities, filename_index) tuple."""
    print("\nTest 5: discover_all_entities return type")
    print("=" * 50)

    import inspect
    sig = inspect.signature(discover_all_entities)
    # Check return annotation mentions Tuple
    ret = sig.return_annotation
    if ret != inspect.Parameter.empty and "Tuple" in str(ret):
        ok("discover_all_entities has Tuple return annotation")
    else:
        warn(f"Return annotation: {ret}")

    # Verify it returns a 2-tuple when called with nonexistent path
    result = discover_all_entities(Path("/nonexistent/path"))
    if isinstance(result, tuple) and len(result) == 2:
        entities, filename_index = result
        if isinstance(entities, dict) and isinstance(filename_index, dict):
            ok("Returns (dict, dict) tuple")
        else:
            fail(f"Tuple elements have wrong types: ({type(entities)}, {type(filename_index)})")
    else:
        fail(f"Expected 2-tuple, got {type(result)}")


# ── Test 6: RelationshipGraph has filename_index field ──

def test_graph_has_filename_index():
    """RelationshipGraph should store filename_index."""
    print("\nTest 6: RelationshipGraph.filename_index field")
    print("=" * 50)

    g = RelationshipGraph()
    if hasattr(g, "filename_index"):
        ok("RelationshipGraph has filename_index attribute")
        if isinstance(g.filename_index, dict):
            ok("filename_index defaults to empty dict")
        else:
            fail(f"filename_index has wrong type: {type(g.filename_index)}")
    else:
        fail("RelationshipGraph missing filename_index attribute")


# ── Test 7: Integration — build graph with UUID entities ──

def test_integration_uuid_graph():
    """Build a minimal graph with UUID-filename entities and verify resolution."""
    print("\nTest 7: Integration — graph with UUID filenames")
    print("=" * 50)

    # Create temp project structure with a UUID-filename finding
    with tempfile.TemporaryDirectory() as tmpdir:
        proj = Path(tmpdir)

        # Create a finding with UUID filename but semantic dc:identifier
        findings_dir = proj / "04-findings" / "data"
        findings_dir.mkdir(parents=True)

        uuid_filename = "finding-006f4003-3333-47ec-abcd-123456789012"
        semantic_id = "finding-ai-analytics-revenue-l2m3n4o5"

        finding_content = f"""---
dc:identifier: {semantic_id}
dc:title: AI Analytics Revenue Growth
dc:created: 2025-01-15
dimension: technology
---

# AI Analytics Revenue Growth

This finding explores how AI analytics tools are driving revenue growth across enterprises.
The market for AI-powered analytics has grown significantly, with projections showing
continued expansion through 2030. Key drivers include automation of data processing
and improved decision-making capabilities.
"""
        (findings_dir / f"{uuid_filename}.md").write_text(finding_content)

        # Create a trend that references the finding by UUID
        trends_dir = proj / "11-trends" / "data"
        trends_dir.mkdir(parents=True)

        trend_content = f"""---
dc:identifier: trend-ai-analytics-growth-a1b2c3d4
dc:title: AI Analytics Market Expansion
dc:created: 2025-01-20
planning_horizon: plan
finding_refs:
  - {uuid_filename}
---

# AI Analytics Market Expansion

This trend tracks the growth of AI analytics. Key findings include
[[04-findings/data/{uuid_filename}|AI Analytics Revenue Growth]].
"""
        (trends_dir / "trend-ai-analytics-growth-a1b2c3d4.md").write_text(trend_content)

        # Run discovery
        entities, filename_index = discover_all_entities(proj)

        if semantic_id in entities:
            ok(f"Finding registered under semantic ID '{semantic_id}'")
        else:
            fail(f"Finding not found under semantic ID (keys: {list(entities.keys())})")
            return

        if uuid_filename in filename_index:
            ok(f"UUID filename indexed -> '{filename_index[uuid_filename]}'")
        else:
            fail(f"UUID filename not in filename_index (index: {filename_index})")
            return

        # Build graph
        graph = build_relationship_graph(entities, filename_index)

        trend_id = "trend-ai-analytics-growth-a1b2c3d4"
        if trend_id in graph.entities:
            trend = graph.entities[trend_id]
            # Check outgoing references to findings
            finding_refs = trend.outgoing.get("findings", [])
            mention_refs = trend.outgoing.get("mentions", [])
            all_finding_refs = [r for r in finding_refs + mention_refs if r.entity_id == semantic_id]

            if all_finding_refs:
                ok(f"Trend -> Finding chain resolved (via {'frontmatter' if finding_refs else 'body wikilink'})")
            else:
                all_out = {k: [r.entity_id for r in v] for k, v in trend.outgoing.items()}
                fail(f"Trend has no reference to finding. Outgoing: {all_out}")

            # Check inverse
            finding = graph.entities[semantic_id]
            has_incoming = any(
                r.entity_id == trend_id
                for refs in finding.incoming.values()
                for r in refs
            )
            if has_incoming:
                ok("Inverse reference: Finding <- Trend present")
            else:
                fail(f"No inverse reference. Finding incoming: {dict(finding.incoming)}")
        else:
            fail(f"Trend not found in graph (keys: {list(graph.entities.keys())})")


# ── Test 8: Live project validation (optional) ──

def test_live_project(project_path: Path):
    """Run validation against a real research project."""
    print(f"\nTest 8: Live project validation ({project_path.name})")
    print("=" * 50)

    if not project_path.exists():
        warn(f"Project path does not exist: {project_path}")
        return

    entities, filename_index = discover_all_entities(project_path)
    if not entities:
        warn("No entities found in project")
        return

    ok(f"Discovered {len(entities)} entities, {len(filename_index)} filename mappings")

    # 8a: Scan all frontmatter for unmapped relationship fields
    print("\n  8a: Frontmatter field coverage")
    unmapped = set()
    ref_pattern = re.compile(r"^(.+_(?:refs?|ids?|references))$")
    for entity in entities.values():
        for key in entity.frontmatter:
            if ref_pattern.match(key) and key not in RELATIONSHIP_FIELDS:
                if key not in ("source_references_count",):  # known non-reference fields
                    unmapped.add(key)

    if unmapped:
        for f in sorted(unmapped):
            warn(f"Unmapped relationship-like field: '{f}'")
    else:
        ok("All *_ref/*_refs/*_id/*_ids fields are mapped")

    # 8b: Build graph and count resolution failures
    print("\n  8b: Relationship resolution")
    graph = build_relationship_graph(entities, filename_index)

    total_outgoing = 0
    resolved_outgoing = 0
    for entity in graph.entities.values():
        for refs in entity.outgoing.values():
            for ref in refs:
                total_outgoing += 1
                if ref.entity_id in graph.entities:
                    resolved_outgoing += 1

    total_incoming = sum(len(refs) for e in graph.entities.values() for refs in e.incoming.values())

    if total_outgoing > 0:
        pct = 100.0 * resolved_outgoing / total_outgoing
        if pct >= 95:
            ok(f"Resolution rate: {resolved_outgoing}/{total_outgoing} ({pct:.1f}%)")
        elif pct >= 80:
            warn(f"Resolution rate: {resolved_outgoing}/{total_outgoing} ({pct:.1f}%) — some broken links")
        else:
            fail(f"Resolution rate: {resolved_outgoing}/{total_outgoing} ({pct:.1f}%) — many broken links")
    else:
        warn("No outgoing relationships found")

    ok(f"Bidirectional references: {total_incoming} incoming links")

    # 8c: Inverse symmetry check
    print("\n  8c: Inverse symmetry")
    asymmetric = 0
    for source_id, source_entity in graph.entities.items():
        for rel_type, refs in source_entity.outgoing.items():
            for ref in refs:
                if ref.entity_id not in graph.entities:
                    continue
                target = graph.entities[ref.entity_id]
                has_inverse = any(
                    r.entity_id == source_id
                    for inv_refs in target.incoming.values()
                    for r in inv_refs
                )
                if not has_inverse:
                    asymmetric += 1

    if asymmetric == 0:
        ok("All resolved outgoing relationships have inverse references")
    else:
        fail(f"{asymmetric} outgoing relationships missing inverse references")

    # 8d: End-to-end chain trace (pick up to 3 trends)
    print("\n  8d: End-to-end chain trace")
    trend_ids = list(graph.by_type.get("trends", set()))[:3]
    if not trend_ids:
        warn("No trends to trace")
    else:
        for trend_id in trend_ids:
            trend = graph.entities[trend_id]
            chain = [f"trend:{trend_id}"]

            # Trend -> findings
            finding_refs = trend.outgoing.get("findings", []) + trend.outgoing.get("mentions", [])
            finding_ids = [r.entity_id for r in finding_refs if r.entity_id in graph.entities and r.entity_type == "findings"]
            if finding_ids:
                chain.append(f"findings:{len(finding_ids)}")

            # Finding -> source (use first finding)
            source_ids = []
            for fid in finding_ids[:1]:
                f_entity = graph.entities[fid]
                s_refs = f_entity.outgoing.get("sources", []) + f_entity.outgoing.get("mentions", [])
                source_ids = [r.entity_id for r in s_refs if r.entity_id in graph.entities and r.entity_type == "sources"]
                if source_ids:
                    chain.append(f"sources:{len(source_ids)}")

            # Source -> publisher (use first source)
            for sid in source_ids[:1]:
                s_entity = graph.entities[sid]
                p_refs = s_entity.outgoing.get("publishers", [])
                pub_ids = [r.entity_id for r in p_refs if r.entity_id in graph.entities]
                if pub_ids:
                    chain.append(f"publishers:{len(pub_ids)}")

            depth = len(chain)
            chain_str = " -> ".join(chain)
            if depth >= 3:
                ok(f"Chain depth {depth}: {chain_str}")
            elif depth >= 2:
                warn(f"Chain depth {depth}: {chain_str}")
            else:
                warn(f"Chain depth {depth}: {chain_str} (no downstream links)")

    # 8e: Export and cross-reference check
    print("\n  8e: Exported file cross-reference")
    with tempfile.TemporaryDirectory() as tmpdir:
        from export_rag import export_entity_type

        output_dir = Path(tmpdir)
        project_name = project_path.name

        all_exported = []
        for etype in graph.by_type:
            files = export_entity_type(
                project_path, output_dir, etype, project_name,
                graph=graph, max_file_size_kb=200, relationship_format="full"
            )
            all_exported.extend(files)

        if all_exported:
            ok(f"Exported {len(all_exported)} files")

            # Read exported files and check that referenced IDs exist as exported files
            exported_ids = set()
            for f in all_exported:
                content = Path(f).read_text()
                id_match = re.search(r"\*\*ID\*\*: `([^`]+)`", content)
                if id_match:
                    exported_ids.add(id_match.group(1))

            # Check references in Related Entities sections
            dangling = 0
            total_refs = 0
            for f in all_exported:
                content = Path(f).read_text()
                for ref_match in re.finditer(r"`([a-z]+-[a-z0-9-]+)`", content):
                    ref_id = ref_match.group(1)
                    if infer_entity_type_from_id(ref_id) != "unknown":
                        total_refs += 1
                        if ref_id not in exported_ids and ref_id not in entities:
                            dangling += 1

            if dangling == 0:
                ok(f"All {total_refs} entity references in exported files are valid")
            else:
                warn(f"{dangling}/{total_refs} references point to non-exported entities")
        else:
            warn("No files exported")


# ── Main ──

def main():
    global passed, failed, warnings

    print("Export-RAG Entity Chain Tests")
    print("=" * 50)

    # Unit tests (always run)
    test_relationship_fields_coverage()
    test_direct_match()
    test_filename_index_resolution()
    test_suffix_match_type_constraint()
    test_discover_returns_filename_index()
    test_graph_has_filename_index()
    test_integration_uuid_graph()

    # Live project test (optional)
    if len(sys.argv) > 1:
        project_path = Path(sys.argv[1])
        test_live_project(project_path)
    else:
        # Try default dtag2036 location
        default_paths = [
            Path.home() / "obsidian" / "dtag2036",
            Path.home() / "GitHub" / "dtag2036",
        ]
        for p in default_paths:
            if p.exists():
                test_live_project(p)
                break
        else:
            print(f"\n  {YELLOW}⚠{RESET} No live project found. Pass a project path as argument for live tests.")

    # Summary
    print("\n" + "=" * 50)
    total = passed + failed
    if failed == 0:
        print(f"{GREEN}All {total} tests passed{RESET}", end="")
    else:
        print(f"{RED}{failed} of {total} tests failed{RESET}", end="")
    if warnings:
        print(f" ({YELLOW}{warnings} warnings{RESET})")
    else:
        print()

    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()

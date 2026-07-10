#!/usr/bin/env python3
"""Deliverable dependency-graph engine for a cogni-consult engagement.

Usage:
  python3 deliverable-graph.py <engagement-dir> validate
  python3 deliverable-graph.py <engagement-dir> trace <action_field>/<deliverable>
  python3 deliverable-graph.py <engagement-dir> impact <action_field>/<deliverable> \
      [--include-inferred]
  python3 deliverable-graph.py <engagement-dir> refresh-order
  python3 deliverable-graph.py <engagement-dir> schedule
  python3 deliverable-graph.py <engagement-dir> cascade-stale <action_field>/<deliverable> \
      --trigger deliverable_update|claims_correction|assumption_update [--include-inferred]
  python3 deliverable-graph.py <engagement-dir> cascade-stale --assumption <id> \
      --trigger assumption_update

Returns JSON on stdout: {"success": bool, "data": {...}, "error": "string"}

Inferred edges: `validate` also surfaces *unrecorded* dependencies — edges a
deliverable's artifact sources[] (frontmatter lineage triple) imply by referencing
another deliverable's artifact, but which were never declared in depends_on[]. These
are advisory (validate stays success:true; they never feed cycle/dangling detection
and never mutate field.json). Pass --include-inferred to impact / cascade-stale to
fold them into the blast radius, closing the silent-zero-dependents gap.

Stale diagnostic gate: `validate` also surfaces solution-field depends_on[] edges
that target a `diagnostic-as-is` deliverable which is no longer the positional
terminal of field-0's deliverables[] (field-0 was re-planned after the gate was
wired). Advisory only (validate stays success:true via `stale_diagnostic_gate_edges`
+ a `warnings[]` entry; never a hard error, never mutates field.json — the lint
detects the drift, it does not auto-repair).

Data model (references/data-model.md, references/dependency-model.md):
  Each action-fields/<slug>/field.json carries deliverables[]. A deliverable may
  declare depends_on[] — an array of {action_field, deliverable} WBS-coordinate
  objects, declared on the DEPENDENT. blocks[] is NOT stored; it is derived here
  at read time by inverting depends_on across every field.json (State-Ownership
  principle). lineage_status IS stored on the deliverable
  (null | {status:"stale", reason, flagged_at, trigger}); cascade-stale writes it
  via read-modify-write preserving sibling fields, and is idempotent. The engine
  surfaces refresh candidates — it never rewrites a deliverable's state or artifact
  (flag-not-rewrite contract; mirrors cogni-knowledge knowledge-refresh).

Edges run dependent -> dependency (D -> U when D depends_on U); upstream = follow
depends_on, downstream = follow the inverted (blocks) relation. Stdlib only.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone

VALID_TRIGGERS = ("deliverable_update", "claims_correction", "assumption_update")


def node_key(action_field, deliverable):
    """Canonical WBS-coordinate key for a deliverable node."""
    return f"{action_field}/{deliverable}"


def parse_coordinate(raw):
    """Parse the CLI '<action_field>/<deliverable>' slash shorthand into a pair.

    Raises ValueError on a malformed coordinate. The stored edge schema is the
    object form {action_field, deliverable}; this is only the CLI shorthand.
    """
    if raw is None or "/" not in raw:
        raise ValueError(
            f"coordinate must be '<action_field>/<deliverable>', got: {raw!r}"
        )
    action_field, _, deliverable = raw.partition("/")
    action_field, deliverable = action_field.strip(), deliverable.strip()
    if not action_field or not deliverable:
        raise ValueError(
            f"coordinate must be '<action_field>/<deliverable>', got: {raw!r}"
        )
    return action_field, deliverable


def _strip_md_suffix(value):
    return value[:-3] if value.endswith(".md") else value


def _coord_from_path(raw):
    """Extract an (action_field, deliverable) pair from an entity_ref / file path.

    Recognizes any path carrying an `action-fields/<af>/<deliverable>` segment
    (a `file://` scheme, deeper sub-paths, and a trailing `.md` are all tolerated).
    Returns None when no such segment is present — the caller treats that as "this
    source does not reference a sibling deliverable" (e.g. an external https URL).
    """
    if not isinstance(raw, str) or not raw:
        return None
    path = raw[len("file://"):] if raw.startswith("file://") else raw
    parts = [p for p in path.replace("\\", "/").split("/") if p]
    if "action-fields" not in parts:
        return None
    i = parts.index("action-fields")
    if len(parts) < i + 3:
        return None
    action_field = parts[i + 1].strip()
    deliverable = _strip_md_suffix(parts[i + 2].strip())
    if not action_field or not deliverable:
        return None
    return action_field, deliverable


def _maybe_kv(target, fragment):
    """Record a 'source_url:'/'entity_ref:' fragment into target (others ignored)."""
    for key in ("source_url", "entity_ref"):
        prefix = key + ":"
        if fragment.startswith(prefix):
            val = fragment[len(prefix):].strip().strip('"').strip("'")
            if val:
                target[key] = val
            return


def _extract_frontmatter_sources(md_path):
    """Best-effort stdlib parse of a deliverable artifact's frontmatter sources[].

    Returns a list of {source_url?, entity_ref?} dicts. Degrades to [] on any
    missing file, absent/unterminated frontmatter, or missing sources block —
    edge inference is advisory and must never raise. The parser handles only the
    constrained frontmatter shape documented in references/data-model.md (a
    top-level `sources:` list of mappings); anything more exotic yields [].
    """
    try:
        with open(md_path, encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return []
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return []
    frontmatter = []
    closed = False
    for line in lines[1:]:
        if line.strip() == "---":
            closed = True
            break
        frontmatter.append(line)
    if not closed:
        return []  # unterminated frontmatter fence — not valid YAML frontmatter

    sources = []
    in_sources = False
    sources_indent = 0
    current = None
    for line in frontmatter:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        indent = len(line) - len(line.lstrip())
        stripped = line.strip()
        if not in_sources:
            if indent == 0 and stripped.rstrip() == "sources:":
                in_sources = True
                sources_indent = indent
            continue
        # Inside the sources block. A dedent to a non-list-item line ends it.
        if indent <= sources_indent and not stripped.startswith("- "):
            break
        if stripped.startswith("- "):
            if current is not None:
                sources.append(current)
            current = {}
            _maybe_kv(current, stripped[2:].strip())
        elif current is not None:
            _maybe_kv(current, stripped)
    if current is not None:
        sources.append(current)
    return [s for s in sources if s]


def _infer_source_edges(nodes, depends_on):
    """Infer unrecorded dependency edges from each deliverable's sources[].

    For every node, read its artifact markdown frontmatter sources[]; resolve each
    entry to a sibling deliverable coordinate (via entity_ref or a file:// source_url
    that carries an `action-fields/<af>/<deliverable>` segment). An edge is *inferred*
    only when the resolved target is a real, distinct node NOT already declared in the
    dependent's depends_on[]. Returns (inferred_edges, inferred_blocks):
      inferred_edges: [{from, to}, ...]   (dependent -> dependency, like depends_on)
      inferred_blocks: {key -> [downstream_key, ...]}  (inverse, for impact/cascade)
    Pure read; never mutates field.json. A self-referential entity_ref (the lineage
    triple naming the deliverable's own coordinate, as for an external source) resolves
    to the node itself and is skipped, so an external https source raises no edge.
    """
    declared = {k: set(v) for k, v in depends_on.items()}
    inferred_edges = []
    inferred_blocks = {key: [] for key in nodes}
    seen = set()
    for key, node in nodes.items():
        field_dir = os.path.dirname(node["field_path"])
        md_path = os.path.join(field_dir, node["deliverable"] + ".md")
        for entry in _extract_frontmatter_sources(md_path):
            # Resolve both fields; pick the first that names a real, non-self node.
            target = None
            for field in ("entity_ref", "source_url"):
                coord = _coord_from_path(entry.get(field))
                if not coord:
                    continue
                cand = node_key(*coord)
                if cand != key and cand in nodes:
                    target = cand
                    break
            if target is None or target in declared.get(key, set()):
                continue
            edge_id = (key, target)
            if edge_id in seen:
                continue
            seen.add(edge_id)
            inferred_edges.append({"from": key, "to": target})
            inferred_blocks[target].append(key)
    return inferred_edges, inferred_blocks


def _merge_adjacency(primary, extra):
    """Union two adjacency maps, preserving order and de-duplicating per key."""
    merged = {}
    for key in set(primary) | set(extra):
        seen = set()
        combined = []
        for nbr in list(primary.get(key, [])) + list(extra.get(key, [])):
            if nbr not in seen:
                seen.add(nbr)
                combined.append(nbr)
        merged[key] = combined
    return merged


def load_graph(engagement_dir):
    """Build the deliverable graph from consult-project.json + every field.json.

    Returns a dict with:
      nodes: {key -> {action_field, deliverable, state, lineage_status,
                      depends_on(list of keys), field_path, field_slug}}
      depends_on: {key -> [upstream_key, ...]}   (dependent -> dependencies)
      blocks: {key -> [downstream_key, ...]}      (derived inverse)
      dangling: [{from, to}, ...]                 (depends_on refs to missing nodes)
      inferred_edges: [{from, to}, ...]           (unrecorded deps from sources[])
      inferred_blocks: {key -> [downstream_key, ...]}  (inverse of inferred_edges)
    Raises ValueError with a user-facing message on an unreadable/malformed root.
    """
    proj_path = os.path.join(engagement_dir, "consult-project.json")
    try:
        with open(proj_path) as f:
            project = json.load(f)
    except (json.JSONDecodeError, OSError) as exc:
        raise ValueError(f"unreadable engagement file {proj_path}: {exc}")

    field_slugs = project.get("action_fields") or []
    if not isinstance(field_slugs, list) or not all(
        isinstance(s, str) for s in field_slugs
    ):
        raise ValueError(
            "malformed engagement file: action_fields must be a list of strings"
        )

    nodes = {}
    # First pass: collect every node so depends_on refs can be checked for danglers.
    for slug in field_slugs:
        fpath = os.path.join(engagement_dir, "action-fields", slug, "field.json")
        try:
            with open(fpath) as f:
                fjson = json.load(f)
        except FileNotFoundError:
            continue
        except (json.JSONDecodeError, OSError) as exc:
            raise ValueError(f"unreadable field file {fpath}: {exc}")

        for deliv in fjson.get("deliverables") or []:
            dslug = deliv.get("slug")
            if not dslug:
                continue
            key = node_key(slug, dslug)
            raw_depends = deliv.get("depends_on") or []
            depends_keys = []
            for ref in raw_depends:
                if not isinstance(ref, dict):
                    raise ValueError(
                        f"{key}: depends_on entries must be "
                        f"{{action_field, deliverable}} objects, got: {ref!r}"
                    )
                up_af = ref.get("action_field")
                up_d = ref.get("deliverable")
                if not up_af or not up_d:
                    raise ValueError(
                        f"{key}: depends_on entry missing action_field/deliverable: {ref!r}"
                    )
                depends_keys.append(node_key(up_af, up_d))
            nodes[key] = {
                "action_field": slug,
                "deliverable": dslug,
                "state": deliv.get("state", "pending"),
                "lineage_status": deliv.get("lineage_status"),
                "duration": deliv.get("duration"),
                "depends_on": depends_keys,
                "field_path": fpath,
                "field_slug": slug,
            }

    # Second pass: build edge maps + collect dangling refs.
    depends_on = {}
    blocks = {key: [] for key in nodes}
    dangling = []
    for key, node in nodes.items():
        valid_ups = []
        for up_key in node["depends_on"]:
            if up_key in nodes:
                valid_ups.append(up_key)
                blocks[up_key].append(key)
            else:
                dangling.append({"from": key, "to": up_key})
        depends_on[key] = valid_ups

    # Third pass: infer unrecorded dependency edges from artifact sources[].
    # Advisory only — never feeds cycle/dangling detection, never mutates state.
    inferred_edges, inferred_blocks = _infer_source_edges(nodes, depends_on)

    # Fourth pass: load the assumption registry (tolerate absence/malformed) and
    # invert each entry's used_by[] citer edges into an assumption -> deliverable
    # adjacency — the assumption-edge analogue of the depends_on -> blocks
    # inversion above. Absent registry ⇒ empty maps (the deliverable cascade path
    # stays fully functional without an assumptions.json).
    assumption_ids, assumption_blocks = _load_assumption_edges(engagement_dir, nodes)

    return {
        "nodes": nodes,
        "depends_on": depends_on,
        "blocks": blocks,
        "dangling": dangling,
        "inferred_edges": inferred_edges,
        "inferred_blocks": inferred_blocks,
        "assumptions": assumption_ids,
        "assumption_blocks": assumption_blocks,
    }


def _load_assumption_edges(engagement_dir, nodes):
    """Return (assumption_ids, assumption_blocks) from the engagement-root registry.

    assumption_ids is the set of every id declared in assumptions.json;
    assumption_blocks maps each assumption id to the deliverable node keys that
    cite it, resolved by running each used_by[].file citer path through the
    existing _coord_from_path helper (the same path->coordinate mapping the
    inferred-edge pass uses) and keeping only coordinates that are real nodes.

    A missing registry (FileNotFoundError) or a hand-corrupted one
    (JSONDecodeError/OSError) yields empty maps rather than raising: the cascade
    deliverable path must stay functional without an assumptions.json, and
    resolve-assumptions.py is the loud validator for that file.
    """
    path = os.path.join(engagement_dir, "assumptions.json")
    try:
        with open(path, encoding="utf-8") as f:
            raw = json.load(f)
    except FileNotFoundError:
        return set(), {}
    except (json.JSONDecodeError, OSError):
        return set(), {}

    assumption_ids = set()
    assumption_blocks = {}
    entries = raw.get("assumptions", []) if isinstance(raw, dict) else []
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        asm_id = entry.get("id")
        if not asm_id:
            continue
        assumption_ids.add(asm_id)
        citer_keys = []
        for ref in entry.get("used_by") or []:
            if not isinstance(ref, dict):
                continue
            coord = _coord_from_path(ref.get("file"))
            if coord is None:
                continue
            ckey = node_key(*coord)
            if ckey in nodes and ckey not in citer_keys:
                citer_keys.append(ckey)
        if citer_keys:
            assumption_blocks[asm_id] = citer_keys
    return assumption_ids, assumption_blocks


def find_cycles(depends_on):
    """Return a list of cycles (each a list of node keys) in the dependent->dependency graph."""
    WHITE, GREY, BLACK = 0, 1, 2
    color = {k: WHITE for k in depends_on}
    cycles = []
    stack = []

    def visit(key):
        color[key] = GREY
        stack.append(key)
        for up in depends_on.get(key, []):
            if color.get(up, WHITE) == GREY:
                # Back-edge: extract the cycle from the current stack.
                idx = stack.index(up)
                cycles.append(stack[idx:] + [up])
            elif color.get(up, WHITE) == WHITE:
                visit(up)
        stack.pop()
        color[key] = BLACK

    for key in depends_on:
        if color[key] == WHITE:
            visit(key)
    return cycles


def transitive(seed_key, adjacency):
    """Return the ordered transitive closure reachable from seed_key (excludes seed)."""
    seen = []
    seen_set = set()
    frontier = list(adjacency.get(seed_key, []))
    while frontier:
        cur = frontier.pop(0)
        if cur in seen_set:
            continue
        seen_set.add(cur)
        seen.append(cur)
        frontier.extend(adjacency.get(cur, []))
    return seen


DIAGNOSTIC_FIELD_SLUG = "diagnostic-as-is"


def _stale_diagnostic_gate_edges(graph):
    """Solution-field depends_on[] edges that target a diagnostic-as-is deliverable
    which is no longer the positional terminal of the diagnostic field's
    deliverables[] — i.e. field-0 was re-planned (a new deliverable appended) after
    the gate was wired, so the edge still names a real diagnostic deliverable but no
    longer its conclusion.

    Advisory only — never a hard error, never mutates field.json. Returns a list of
    {"from": key, "to": key} edges (empty when there is no diagnostic field, or no
    drift). The terminal is derived by re-reading the diagnostic field's field.json
    (load_graph already proved it readable) and taking the last slug-bearing
    deliverable — mirroring the positional-terminal contract consult-action-fields
    wires to. Skips silently on any read/parse miss so the advisory never degrades
    the hard-error path.
    """
    nodes = graph["nodes"]
    diag_node = next(
        (n for n in nodes.values() if n["action_field"] == DIAGNOSTIC_FIELD_SLUG),
        None,
    )
    if diag_node is None:
        return []
    try:
        with open(diag_node["field_path"]) as f:
            fjson = json.load(f)
    except (json.JSONDecodeError, OSError):
        return []
    terminal_slug = None
    for deliv in fjson.get("deliverables") or []:
        dslug = deliv.get("slug")
        if dslug:
            terminal_slug = dslug
    if terminal_slug is None:
        return []
    terminal_key = node_key(DIAGNOSTIC_FIELD_SLUG, terminal_slug)
    stale = []
    for from_key, ups in graph["depends_on"].items():
        from_node = nodes.get(from_key)
        if from_node is None or from_node["action_field"] == DIAGNOSTIC_FIELD_SLUG:
            continue
        for up_key in ups:
            up_node = nodes.get(up_key)
            if (
                up_node is not None
                and up_node["action_field"] == DIAGNOSTIC_FIELD_SLUG
                and up_key != terminal_key
            ):
                stale.append({"from": from_key, "to": up_key})
    return stale


def cmd_validate(graph):
    """Detect cycles + dangling depends_on refs across all field.json (hard errors)."""
    cycles = find_cycles(graph["depends_on"])
    dangling = graph["dangling"]
    if cycles or dangling:
        parts = []
        if cycles:
            parts.append(
                "cycle(s): " + "; ".join(" -> ".join(c) for c in cycles)
            )
        if dangling:
            parts.append(
                "dangling depends_on ref(s): "
                + ", ".join(f"{d['from']} -> {d['to']}" for d in dangling)
            )
        return {
            "success": False,
            "data": {
                "node_count": len(graph["nodes"]),
                "cycles": cycles,
                "dangling": dangling,
            },
            "error": "; ".join(parts),
        }
    edge_count = sum(len(v) for v in graph["depends_on"].values())
    inferred = graph.get("inferred_edges", [])
    warnings = []
    if inferred:
        warnings.append(
            f"{len(inferred)} unrecorded dependency(ies) inferred from sources[] "
            "not declared in depends_on[]: "
            + ", ".join(f"{e['from']} -> {e['to']}" for e in inferred)
            + ". Declare them in depends_on[] to make the edge authoritative, or pass "
            "--include-inferred to impact/cascade-stale to fold them into the blast "
            "radius (the graph never rewrites field.json on its own)."
        )
    stale_gate = _stale_diagnostic_gate_edges(graph)
    if stale_gate:
        warnings.append(
            f"{len(stale_gate)} solution-field edge(s) target a non-terminal diagnostic "
            "deliverable (the diagnostic field-0 was re-planned after the gate was wired): "
            + ", ".join(f"{e['from']} -> {e['to']}" for e in stale_gate)
            + ". The gate no longer points at the diagnostic's conclusion; re-point it "
            "at the current terminal if the dependency should follow the conclusion."
        )
    return {
        "success": True,
        "data": {
            "node_count": len(graph["nodes"]),
            "edge_count": edge_count,
            "cycles": [],
            "dangling": [],
            "inferred_edges": inferred,
            "inferred_edge_count": len(inferred),
            "stale_diagnostic_gate_edges": stale_gate,
            "stale_diagnostic_gate_edge_count": len(stale_gate),
            "warnings": warnings,
        },
        "error": "",
    }


def _require_node(graph, key):
    if key not in graph["nodes"]:
        raise ValueError(f"deliverable not found: {key}")


def cmd_trace(graph, key):
    """Upstream lineage — the transitive set this deliverable depends on."""
    _require_node(graph, key)
    upstream = transitive(key, graph["depends_on"])
    return {
        "success": True,
        "data": {
            "target": key,
            "direct_depends_on": graph["depends_on"].get(key, []),
            "upstream": upstream,
            "upstream_count": len(upstream),
        },
        "error": "",
    }


def cmd_impact(graph, key, include_inferred=False):
    """Downstream blast radius — the transitive set that depends on this deliverable.

    With include_inferred=True the inferred (sources[]-derived) edges are folded into
    the blocks adjacency so unrecorded dependents are counted; default is the declared
    graph only, so existing callers see byte-identical behavior.
    """
    _require_node(graph, key)
    blocks = graph["blocks"]
    if include_inferred:
        blocks = _merge_adjacency(graph["blocks"], graph.get("inferred_blocks", {}))
    downstream = transitive(key, blocks)
    return {
        "success": True,
        "data": {
            "target": key,
            "direct_blocks": blocks.get(key, []),
            "downstream": downstream,
            "downstream_count": len(downstream),
            "include_inferred": include_inferred,
        },
        "error": "",
    }


def _is_stale(node):
    ls = node.get("lineage_status")
    return isinstance(ls, dict) and ls.get("status") == "stale"


def cmd_refresh_order(graph):
    """Topologically layer the currently-stale deliverables (upstream first).

    A stale node's layer is 1 + max(layer of its stale dependencies), or 0 when it
    has no stale dependency. Refreshing layer by layer guarantees an upstream stale
    deliverable is reworked before its stale dependents.
    """
    stale_keys = [k for k, n in graph["nodes"].items() if _is_stale(n)]
    stale_set = set(stale_keys)
    # Edges restricted to the stale sub-graph.
    stale_depends = {
        k: [u for u in graph["depends_on"].get(k, []) if u in stale_set]
        for k in stale_keys
    }

    # If the stale sub-graph has a cycle, layering is undefined — surface it.
    cycles = find_cycles(stale_depends)
    if cycles:
        return {
            "success": False,
            "data": {"stale": stale_keys, "cycles": cycles},
            "error": "cycle(s) among stale deliverables: "
            + "; ".join(" -> ".join(c) for c in cycles),
        }

    layer = {}

    def compute(k, trail):
        if k in layer:
            return layer[k]
        ups = stale_depends.get(k, [])
        layer[k] = 0 if not ups else 1 + max(compute(u, trail + [k]) for u in ups)
        return layer[k]

    for k in stale_keys:
        compute(k, [])

    max_layer = max(layer.values()) if layer else -1
    layers = [
        sorted(k for k in stale_keys if layer[k] == i) for i in range(max_layer + 1)
    ]
    order = [k for lyr in layers for k in lyr]
    return {
        "success": True,
        "data": {
            "stale_count": len(stale_keys),
            "layers": layers,
            "order": order,
        },
        "error": "",
    }


def cmd_schedule(graph):
    """Duration-weighted forward schedule + critical path over the deliverable graph.

    Reuses the same `depends_on[]` graph as refresh-order — no new graph is built.
    A memoized forward pass sets each deliverable's earliest_start to the maximum
    earliest_finish of its dependencies (0 when it has none) and its earliest_finish
    to earliest_start + effective duration. A deliverable's effective duration is its
    `duration` field (effort-days); a deliverable with no authored `duration` is
    treated as zero-duration and surfaced under `unscheduled[]` (never crashes the
    pass). The critical path is the longest duration-weighted chain — it ends at the
    node with the maximum earliest_finish and is backtracked through the binding
    predecessor (the dependency whose finish equals the node's earliest_start); its
    total duration equals the project earliest-finish. Schedule over a cyclic graph
    is undefined, so a cycle short-circuits with success:false, mirroring
    refresh-order.
    """
    nodes = graph["nodes"]
    depends_on = graph["depends_on"]

    cycles = find_cycles(depends_on)
    if cycles:
        return {
            "success": False,
            "data": {"cycles": cycles},
            "error": "cycle(s) in the deliverable graph; schedule undefined: "
            + "; ".join(" -> ".join(c) for c in cycles),
        }

    def is_scheduled(k):
        # A deliverable is scheduled iff it carries a valid non-negative authored
        # duration (a non-bool int/float >= 0). Absent (None), negative, or
        # non-numeric durations are "unscheduled" — treated as zero-duration and
        # surfaced under unscheduled[]. An authored `duration: 0` stays scheduled.
        d = nodes[k].get("duration")
        return isinstance(d, (int, float)) and not isinstance(d, bool) and d >= 0

    def duration_of(k):
        # Scheduled deliverables contribute their authored effort-days; everything
        # unscheduled contributes zero (never crashes the forward pass).
        return nodes[k]["duration"] if is_scheduled(k) else 0

    earliest_start = {}
    earliest_finish = {}

    def finish(k, trail):
        if k in earliest_finish:
            return earliest_finish[k]
        ups = depends_on.get(k, [])
        es = max((finish(u, trail + [k]) for u in ups), default=0)
        earliest_start[k] = es
        earliest_finish[k] = es + duration_of(k)
        return earliest_finish[k]

    for k in nodes:
        finish(k, [])

    unscheduled = sorted(k for k in nodes if not is_scheduled(k))

    schedule = [
        {
            "key": k,
            "action_field": nodes[k]["action_field"],
            "deliverable": nodes[k]["deliverable"],
            "duration": nodes[k].get("duration"),
            "earliest_start": earliest_start[k],
            "earliest_finish": earliest_finish[k],
            "unscheduled": not is_scheduled(k),
        }
        for k in sorted(nodes)
    ]

    project_earliest_finish = max((earliest_finish[k] for k in nodes), default=0)

    # Critical path: end at the max-finish node (deterministic key tie-break), then
    # walk back through the binding predecessor whose finish set this node's start.
    critical_path = []
    end = min(
        (k for k in nodes if earliest_finish[k] == project_earliest_finish),
        default=None,
    )
    cur = end
    while cur is not None:
        critical_path.append(cur)
        preds = [
            u for u in depends_on.get(cur, [])
            if earliest_finish[u] == earliest_start[cur]
        ]
        cur = min(preds) if preds else None
    critical_path.reverse()

    return {
        "success": True,
        "data": {
            "schedule": schedule,
            "critical_path": critical_path,
            "project_earliest_finish": project_earliest_finish,
            "unscheduled": unscheduled,
        },
        "error": "",
    }


def cmd_cascade_stale(graph, key, trigger, include_inferred=False):
    """Flag the transitive downstream set of `key` as stale via idempotent RMW.

    The updated deliverable (`key`) itself is NOT flagged — it is fresh; its
    dependents are. Writes lineage_status={status:"stale", reason, flagged_at,
    trigger} to each downstream deliverable's field.json, preserving every sibling
    field. Idempotent: a deliverable already carrying status:"stale" is left
    untouched (its original flagged_at survives), so re-running yields no new write.

    With include_inferred=True, dependents reachable only through inferred
    (sources[]-derived) edges are included in the blast radius — closing the
    silent-zero-dependents gap when a real dependency was never declared in
    depends_on[]. Default is the declared graph only (unchanged behavior).
    """
    _require_node(graph, key)
    if trigger not in VALID_TRIGGERS:
        raise ValueError(
            f"--trigger must be one of {VALID_TRIGGERS}, got: {trigger!r}"
        )

    blocks = graph["blocks"]
    if include_inferred:
        blocks = _merge_adjacency(graph["blocks"], graph.get("inferred_blocks", {}))
    downstream = transitive(key, blocks)
    reason = f"upstream deliverable {key} changed (trigger: {trigger})"
    return _flag_downstream_stale(
        graph, downstream, reason, trigger, key, include_inferred
    )


def cmd_cascade_stale_assumption(graph, asm_id, trigger):
    """Flag the deliverables that cite assumption `asm_id` — plus their transitive
    downstream — as stale via the same idempotent flag-not-rewrite RMW.

    The assumption-edge analogue of `cmd_cascade_stale`: the assumption plays the
    role of the changed upstream node, its used_by[] citers are its direct
    dependents (resolved into `assumption_blocks` at load time), and staleness
    then cascades through the ordinary deliverable `blocks` graph exactly as a
    deliverable edit would. Editing an assumption value therefore flags every
    dependent stale (AC1) without ever rewriting an artifact (flag-not-rewrite),
    and re-running is a no-op on already-stale entries (AC3).
    """
    if trigger not in VALID_TRIGGERS:
        raise ValueError(
            f"--trigger must be one of {VALID_TRIGGERS}, got: {trigger!r}"
        )
    if asm_id not in graph.get("assumptions", set()):
        raise ValueError(
            f"unknown assumption id: {asm_id!r} — no matching entry in the "
            f"engagement-root assumptions.json registry"
        )
    blocks = graph["blocks"]
    downstream = set()
    for citer_key in graph.get("assumption_blocks", {}).get(asm_id, []):
        downstream.add(citer_key)
        downstream.update(transitive(citer_key, blocks))
    reason = f"upstream assumption {asm_id} changed (trigger: {trigger})"
    return _flag_downstream_stale(
        graph, sorted(downstream), reason, trigger, asm_id, include_inferred=False
    )


def _flag_downstream_stale(graph, downstream, reason, trigger, trigger_id,
                           include_inferred):
    """Shared idempotent by_file RMW: flag every deliverable key in `downstream`
    with lineage_status={status:"stale", reason, flagged_at, trigger}.

    The single write path for both the deliverable (`cmd_cascade_stale`) and the
    assumption (`cmd_cascade_stale_assumption`) cascades — it is generic over
    "a set of downstream deliverable keys to flag", so neither caller duplicates
    the read-modify-write, sibling-preservation, or idempotency logic. Preserves
    every sibling field; a deliverable already carrying status:"stale" is left
    untouched (its original flagged_at survives). `trigger_id` is the changed
    upstream identity (a deliverable key or an assumption id) echoed as
    data.trigger.
    """
    flagged_at = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Group target downstream keys by the field.json file that holds them, so each
    # field file is read-modified-written exactly once.
    by_file = {}
    for dkey in downstream:
        node = graph["nodes"][dkey]
        by_file.setdefault(node["field_path"], []).append(node["deliverable"])

    newly_flagged = []
    already_stale = []
    for fpath, deliv_slugs in by_file.items():
        with open(fpath) as f:
            fjson = json.load(f)
        targets = set(deliv_slugs)
        changed = False
        for deliv in fjson.get("deliverables") or []:
            if deliv.get("slug") not in targets:
                continue
            dkey = node_key(fjson.get("slug") or "", deliv.get("slug"))
            existing = deliv.get("lineage_status")
            if isinstance(existing, dict) and existing.get("status") == "stale":
                already_stale.append(dkey)
                continue
            deliv["lineage_status"] = {
                "status": "stale",
                "reason": reason,
                "flagged_at": flagged_at,
                "trigger": trigger,
            }
            newly_flagged.append(dkey)
            changed = True
        if changed:
            with open(fpath, "w") as f:
                json.dump(fjson, f, indent=2, ensure_ascii=False)
                f.write("\n")

    return {
        "success": True,
        "data": {
            "trigger": trigger_id,
            "trigger_event": trigger,
            "downstream_count": len(downstream),
            "newly_flagged": sorted(newly_flagged),
            "already_stale": sorted(already_stale),
            "flagged_at": flagged_at,
            "include_inferred": include_inferred,
        },
        "error": "",
    }


def main():
    ap = argparse.ArgumentParser(
        description="Deliverable dependency-graph engine for a cogni-consult engagement."
    )
    ap.add_argument("engagement_dir")
    sub = ap.add_subparsers(dest="command", required=True)
    sub.add_parser("validate")
    p_trace = sub.add_parser("trace")
    p_trace.add_argument("coordinate")
    p_impact = sub.add_parser("impact")
    p_impact.add_argument("coordinate")
    p_impact.add_argument(
        "--include-inferred",
        action="store_true",
        help="fold sources[]-inferred (unrecorded) edges into the blast radius",
    )
    sub.add_parser("refresh-order")
    sub.add_parser("schedule")
    p_cascade = sub.add_parser("cascade-stale")
    p_cascade.add_argument("coordinate", nargs="?", default=None)
    p_cascade.add_argument(
        "--assumption",
        metavar="ID",
        default=None,
        help="cascade from an assumptions.json id via its used_by[] edges "
        "instead of an <action_field>/<deliverable> coordinate",
    )
    p_cascade.add_argument(
        "--trigger", required=True, choices=list(VALID_TRIGGERS)
    )
    p_cascade.add_argument(
        "--include-inferred",
        action="store_true",
        help="also flag dependents reachable only through sources[]-inferred edges",
    )
    args = ap.parse_args()

    engagement_dir = os.path.abspath(args.engagement_dir)
    try:
        if not os.path.isdir(engagement_dir):
            raise ValueError(f"engagement directory not found: {engagement_dir}")
        graph = load_graph(engagement_dir)

        if args.command == "validate":
            result = cmd_validate(graph)
        elif args.command == "trace":
            af, d = parse_coordinate(args.coordinate)
            result = cmd_trace(graph, node_key(af, d))
        elif args.command == "impact":
            af, d = parse_coordinate(args.coordinate)
            result = cmd_impact(graph, node_key(af, d), args.include_inferred)
        elif args.command == "refresh-order":
            result = cmd_refresh_order(graph)
        elif args.command == "schedule":
            result = cmd_schedule(graph)
        elif args.command == "cascade-stale":
            if (args.coordinate is None) == (args.assumption is None):
                raise ValueError(
                    "cascade-stale requires exactly one of "
                    "<action_field>/<deliverable> or --assumption <id>"
                )
            if args.assumption is not None:
                result = cmd_cascade_stale_assumption(
                    graph, args.assumption, args.trigger
                )
            else:
                af, d = parse_coordinate(args.coordinate)
                result = cmd_cascade_stale(
                    graph, node_key(af, d), args.trigger, args.include_inferred
                )
        else:  # pragma: no cover — argparse already enforces the choice set
            raise ValueError(f"unknown command: {args.command}")
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}, ensure_ascii=False))
        return 0

    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

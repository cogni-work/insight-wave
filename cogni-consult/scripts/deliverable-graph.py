#!/usr/bin/env python3
"""Deliverable dependency-graph engine for a cogni-consult engagement.

Usage:
  python3 deliverable-graph.py <engagement-dir> validate
  python3 deliverable-graph.py <engagement-dir> trace <action_field>/<deliverable>
  python3 deliverable-graph.py <engagement-dir> impact <action_field>/<deliverable>
  python3 deliverable-graph.py <engagement-dir> refresh-order
  python3 deliverable-graph.py <engagement-dir> cascade-stale <action_field>/<deliverable> \
      --trigger deliverable_update|claims_correction

Returns JSON on stdout: {"success": bool, "data": {...}, "error": "string"}

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

VALID_TRIGGERS = ("deliverable_update", "claims_correction")


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


def load_graph(engagement_dir):
    """Build the deliverable graph from consult-project.json + every field.json.

    Returns a dict with:
      nodes: {key -> {action_field, deliverable, state, lineage_status,
                      depends_on(list of keys), field_path, field_slug}}
      depends_on: {key -> [upstream_key, ...]}   (dependent -> dependencies)
      blocks: {key -> [downstream_key, ...]}      (derived inverse)
      dangling: [{from, to}, ...]                 (depends_on refs to missing nodes)
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

    return {
        "nodes": nodes,
        "depends_on": depends_on,
        "blocks": blocks,
        "dangling": dangling,
    }


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
    return {
        "success": True,
        "data": {
            "node_count": len(graph["nodes"]),
            "edge_count": edge_count,
            "cycles": [],
            "dangling": [],
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


def cmd_impact(graph, key):
    """Downstream blast radius — the transitive set that depends on this deliverable."""
    _require_node(graph, key)
    downstream = transitive(key, graph["blocks"])
    return {
        "success": True,
        "data": {
            "target": key,
            "direct_blocks": graph["blocks"].get(key, []),
            "downstream": downstream,
            "downstream_count": len(downstream),
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


def cmd_cascade_stale(graph, key, trigger):
    """Flag the transitive downstream set of `key` as stale via idempotent RMW.

    The updated deliverable (`key`) itself is NOT flagged — it is fresh; its
    dependents are. Writes lineage_status={status:"stale", reason, flagged_at,
    trigger} to each downstream deliverable's field.json, preserving every sibling
    field. Idempotent: a deliverable already carrying status:"stale" is left
    untouched (its original flagged_at survives), so re-running yields no new write.
    """
    _require_node(graph, key)
    if trigger not in VALID_TRIGGERS:
        raise ValueError(
            f"--trigger must be one of {VALID_TRIGGERS}, got: {trigger!r}"
        )

    downstream = transitive(key, graph["blocks"])
    reason = f"upstream deliverable {key} changed (trigger: {trigger})"
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
            "trigger": key,
            "trigger_event": trigger,
            "downstream_count": len(downstream),
            "newly_flagged": sorted(newly_flagged),
            "already_stale": sorted(already_stale),
            "flagged_at": flagged_at,
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
    sub.add_parser("refresh-order")
    p_cascade = sub.add_parser("cascade-stale")
    p_cascade.add_argument("coordinate")
    p_cascade.add_argument(
        "--trigger", required=True, choices=list(VALID_TRIGGERS)
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
            result = cmd_impact(graph, node_key(af, d))
        elif args.command == "refresh-order":
            result = cmd_refresh_order(graph)
        elif args.command == "cascade-stale":
            af, d = parse_coordinate(args.coordinate)
            result = cmd_cascade_stale(graph, node_key(af, d), args.trigger)
        else:  # pragma: no cover — argparse already enforces the choice set
            raise ValueError(f"unknown command: {args.command}")
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}, ensure_ascii=False))
        return 0

    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

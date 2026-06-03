#!/usr/bin/env python3
"""
knowledge-binding.py — read/write .cogni-knowledge/binding.json

Six actions:
  init           create a new binding manifest
  append-project record a deposited cogni-research project
  read           emit the current binding manifest as JSON
  upsert-themes  merge question-node theme-lineage records into
                 topic_lineage.covered_themes[] (#409; the single writer of
                 that block — question-store.py only reads it)
  themes         read-side partition of the seed-theme backlog: split
                 topic_lineage.open_themes[] into still-open vs
                 already-researched (open MINUS covered, matched by
                 theme_norm_key) for the resume/dashboard display, plus a
                 render-ready covered[] list — never mutates the binding
  set-charter    in-place charter re-frame on an existing base (#451; the
                 second writer of the charter block — init is the first) —
                 partial field update + union-merge into open_themes[]

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import theme_norm_key  # noqa: E402

# Schema bumps mirror the data shape, not the plugin tag. v0.0.3 was the
# additive bump that added curator_defaults on top of v0.0.2's project_path.
# The bump to 0.1.0 landed at v0.1.0 M12 alongside plugin.json so the two
# version surfaces re-align there (no field change — a deliberate milestone
# re-alignment per references/absorption-roadmap.md M12). 0.1.1 added
# research_defaults (knowledge-base-level market + output_language inherited by
# knowledge-plan; #309 P1.2-rest). 0.1.2 widened research_defaults with the four
# writer-quality knobs (prose_density, tone, citation_format, target_words;
# #309 P2). Pre-0.1.2 bindings have only the two P1.2 keys (or no block at all);
# consumers MUST read the block with .get("research_defaults",
# DEFAULT_RESEARCH_DEFAULTS) and each key with a per-key .get(..., DEFAULT) so an
# older block falls straight through. 0.1.3 is the next additive bump — it
# DEFINES the topic_lineage.covered_themes[] entry shape (#409): the question-node
# theme-lineage records {theme_key, question_slug, labels[], first_seen, last_seen}
# written by the new `upsert-themes` subcommand so a recurring theme maps to one
# persistent question node across runs. Pre-0.1.3 bindings carry covered_themes:
# [] (init's default), so consumers reading
# .get("topic_lineage", {}).get("covered_themes", []) fall straight through.
# 0.1.4 is the next additive bump — it adds a `charter` block (the base-level
# steering captured at knowledge-setup Step 2.5: {domain, audience, scope,
# framed_at}). All four fields default to "" so a flag-only / non-interactive
# init still writes a complete, schema-valid block; `framed_at` is set to today
# only when any of domain/audience/scope is non-empty. The seed-theme backlog
# lands in the EXISTING topic_lineage.open_themes[] (a plain string list, was
# out of scope for #409). Pre-0.1.4 bindings have no `charter` key, so consumers
# MUST read it with .get("charter", {}).get(key, "") to fall straight through.
# The charter block has TWO writers, both at schema 0.1.4: `init` (first frame, at
# knowledge-setup) and `set-charter` (#451; in-place re-frame on an existing base).
# `set-charter` writes the SAME 0.1.4 shape `init` already does — it is a new
# action, not a new field, so it does NOT bump SCHEMA_VERSION (the precedent
# append-project / upsert-themes set: neither touches schema_version). On a
# pre-0.1.4 binding it setdefault()s a complete all-"" charter block before
# applying updates and leaves schema_version untouched (consumers already read
# the charter via the .get(...) chain above).
SCHEMA_VERSION = "0.1.4"
BINDING_DIRNAME = ".cogni-knowledge"
BINDING_FILENAME = "binding.json"
FETCH_CACHE_DIRNAME = "fetch-cache"
WIKI_DIRNAME = ".cogni-wiki"
WIKI_CONFIG_FILENAME = "config.json"
VALID_REPORT_SOURCES = {"web", "local", "wiki", "hybrid"}
DEFAULT_CURATOR_DEFAULTS = {
    "max_candidates_per_sq": 12,
    "score_threshold": 0.5,
    "fetch_cache_max_age_days": 30,
}
# research_defaults records the knowledge base's default output config so every
# knowledge-plan run inherits it instead of re-deriving (or silently defaulting
# English / standard-density on a German base). An output concern, not a curator
# one — kept as a sibling block. knowledge-plan's resolution precedence for each
# key: explicit flag > this block > (market's registry default_output_language
# for language) > the hard default below.
#   schema 0.1.1 (#309 P1.2-rest): market + output_language.
#   schema 0.1.2 (#309 P2): the four writer-quality knobs below —
#     prose_density (standard|executive), tone (writing-tones.md), citation_format
#     (ieee|chicago wired; apa/mla/harvard staged), target_words (soft floor/ceiling).
DEFAULT_RESEARCH_DEFAULTS = {
    "market": "dach",
    "output_language": "en",
    "prose_density": "standard",
    "tone": "objective",
    "citation_format": "ieee",
    "target_words": 4000,
}
# The charter key-set + empty defaults (schema 0.1.4), in one place so both
# writers — `init` (first frame) and `set-charter` (in-place re-frame) — derive
# the shape from a single source. framed_at defaults to "" (stamped only when the
# base is actually steered); init overrides the three steering fields + framed_at.
DEFAULT_CHARTER = {
    "domain": "",
    "audience": "",
    "scope": "",
    "framed_at": "",
}


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _binding_path(knowledge_root: Path) -> Path:
    return knowledge_root / BINDING_DIRNAME / BINDING_FILENAME


def _today() -> str:
    return _dt.date.today().isoformat()


def _read_binding(knowledge_root: Path) -> dict:
    bp = _binding_path(knowledge_root)
    if not bp.is_file():
        raise FileNotFoundError(f"binding not found at {bp}")
    with bp.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def _write_binding(knowledge_root: Path, payload: dict) -> Path:
    # Mirrors cogni-wiki/_wikilib.atomic_write semantics — tempfile.mkstemp
    # so concurrent writers cannot collide on a predictable `.tmp` suffix,
    # and the temp file is unlinked on exception.
    bp = _binding_path(knowledge_root)
    bp.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=f".{bp.name}.", suffix=".tmp", dir=str(bp.parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(payload, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        os.replace(tmp, bp)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise
    return bp


def cmd_init(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    wiki_path = Path(args.wiki_path).resolve()

    if not knowledge_root.is_dir():
        return _emit(False, error=f"knowledge_root does not exist: {knowledge_root}")
    if not wiki_path.is_dir():
        return _emit(False, error=f"wiki_path does not exist: {wiki_path}")

    bp = _binding_path(knowledge_root)
    if bp.is_file():
        existing = json.loads(bp.read_text(encoding="utf-8"))
        return _emit(
            False,
            data={"existing": existing, "path": str(bp)},
            error="binding already exists at the target; refusing to overwrite",
        )

    wiki_config = wiki_path / WIKI_DIRNAME / WIKI_CONFIG_FILENAME
    if not wiki_config.is_file():
        return _emit(
            False,
            error=(
                f"wiki_path is not a cogni-wiki (missing {wiki_config}). "
                "Run cogni-wiki:wiki-setup first or fix the path."
            ),
        )

    # wiki_slug is the live truth — resolved from .cogni-wiki/config.json
    # at every consumer, never cached here. Single source of truth lives
    # upstream; caching would drift if the user renames the wiki.
    #
    # The fetch-cache lives at <knowledge_root>/.cogni-knowledge/fetch-cache/
    # by convention (documented in references/fetch-cache-design.md). The path
    # is fully derivable from knowledge_root so it is not echoed into the
    # binding — consumers compute it the same way fetch-cache.py does.
    (knowledge_root / BINDING_DIRNAME / FETCH_CACHE_DIRNAME).mkdir(parents=True, exist_ok=True)
    # The charter is the base-level steering captured at knowledge-setup Step 2.5
    # (domain / audience / scope). All fields fall through to "" so a flag-only
    # or non-interactive init still writes a complete schema-0.1.4 block.
    charter_domain = args.charter_domain or ""
    charter_audience = args.charter_audience or ""
    charter_scope = args.charter_scope or ""
    # --open-themes is a pipe-separated seed-theme backlog → the EXISTING
    # topic_lineage.open_themes[] plain string list (default []).
    open_themes = [t.strip() for t in (args.open_themes or "").split("|") if t.strip()]
    today = _today()
    payload = {
        "knowledge_slug": args.knowledge_slug,
        "knowledge_title": args.knowledge_title,
        "wiki_path": str(wiki_path),
        "research_projects": [],
        "topic_lineage": {"covered_themes": [], "open_themes": open_themes},
        "charter": {
            **DEFAULT_CHARTER,
            "domain": charter_domain,
            "audience": charter_audience,
            "scope": charter_scope,
            # stamped only when the base was actually steered (any field set),
            # so a default-skeleton charter stays distinguishable from a real one
            "framed_at": today if (charter_domain or charter_audience or charter_scope) else "",
        },
        "curator_defaults": dict(DEFAULT_CURATOR_DEFAULTS),
        "research_defaults": {
            "market": args.market or DEFAULT_RESEARCH_DEFAULTS["market"],
            "output_language": (
                args.output_language or DEFAULT_RESEARCH_DEFAULTS["output_language"]
            ),
            "prose_density": args.prose_density or DEFAULT_RESEARCH_DEFAULTS["prose_density"],
            "tone": args.tone or DEFAULT_RESEARCH_DEFAULTS["tone"],
            "citation_format": (
                args.citation_format or DEFAULT_RESEARCH_DEFAULTS["citation_format"]
            ),
            # --target-words defaults to 0 (unset sentinel) so a positive int wins
            # and 0/omitted falls through to the 4000 default.
            "target_words": args.target_words or DEFAULT_RESEARCH_DEFAULTS["target_words"],
        },
        "created": today,
        "schema_version": SCHEMA_VERSION,
    }
    written = _write_binding(knowledge_root, payload)
    return _emit(True, data={"path": str(written), "binding": payload})


def cmd_append_project(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()

    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")

    if args.knowledge_slug and binding.get("knowledge_slug") != args.knowledge_slug:
        return _emit(
            False,
            data={"binding_slug": binding.get("knowledge_slug")},
            error=(
                f"knowledge_slug mismatch: binding has '{binding.get('knowledge_slug')}', "
                f"caller passed '{args.knowledge_slug}'"
            ),
        )

    if args.report_source not in VALID_REPORT_SOURCES:
        return _emit(
            False,
            error=(
                f"invalid --report-source '{args.report_source}'; "
                f"must be one of {sorted(VALID_REPORT_SOURCES)}"
            ),
        )

    projects = binding.setdefault("research_projects", [])
    existing_idx = next(
        (i for i, p in enumerate(projects) if p.get("slug") == args.research_slug),
        None,
    )

    entry = {
        "slug": args.research_slug,
        "deposited_at": args.deposited_at or _today(),
        "report_path": str(Path(args.report_path).resolve()) if args.report_path else "",
        "report_source": args.report_source,
        "project_path": str(Path(args.project_path).resolve()) if args.project_path else "",
    }

    if existing_idx is not None:
        if not args.allow_update:
            return _emit(
                False,
                data={"existing_slug": args.research_slug},
                error="research_slug already recorded in this binding; refusing to duplicate",
            )
        # In-place update so the array's ordering is preserved (downstream
        # readers like knowledge-dashboard surface projects by index order).
        previous = projects[existing_idx]
        projects[existing_idx] = entry
        written = _write_binding(knowledge_root, binding)
        return _emit(
            True,
            data={
                "path": str(written),
                "updated": entry,
                "previous": previous,
                "research_projects_count": len(projects),
            },
        )

    projects.append(entry)
    written = _write_binding(knowledge_root, binding)
    return _emit(
        True,
        data={
            "path": str(written),
            "appended": entry,
            "research_projects_count": len(projects),
        },
    )


def _load_theme_bindings(raw: str) -> list[dict]:
    """Parse the question-store.py theme_bindings payload. Liberal in what it
    accepts (the orchestrator may pipe the bare array, the `{theme_bindings: []}`
    object, or question-store's full `{success, data: {theme_bindings: []}}`
    envelope) so a small serialization choice upstream never silently drops the
    records. Returns the list of `{theme_key, question_slug, theme_label}` dicts."""
    doc = json.loads(raw)
    if isinstance(doc, list):
        return doc
    if isinstance(doc, dict):
        tbs = doc.get("theme_bindings")
        if not isinstance(tbs, list):
            tbs = (doc.get("data") or {}).get("theme_bindings")
        if isinstance(tbs, list):
            return tbs
    return []


def cmd_upsert_themes(args: argparse.Namespace) -> int:
    """Merge question-node theme-lineage records into
    topic_lineage.covered_themes[] (#409). The SOLE writer of that block —
    question-store.py only reads it to route a recurring theme to its existing
    node. Per record: find the covered_themes entry by theme_key; if present,
    union theme_label into labels[] + bump last_seen (+ refresh question_slug);
    else append a fresh {theme_key, question_slug, labels, first_seen, last_seen}.
    first_seen is frozen on the original append."""
    knowledge_root = Path(args.knowledge_root).resolve()

    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")

    try:
        raw = sys.stdin.read() if args.records == "-" else Path(args.records).read_text(encoding="utf-8")
    except OSError as exc:
        return _emit(False, error=f"could not read --records: {exc}")
    try:
        records = _load_theme_bindings(raw)
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"--records is not valid JSON: {exc}")

    today = _today()
    lineage = binding.setdefault("topic_lineage", {})
    covered = lineage.setdefault("covered_themes", [])
    by_key = {e.get("theme_key"): e for e in covered if isinstance(e, dict) and e.get("theme_key")}

    themes_added = 0
    themes_updated = 0
    for rec in records:
        if not isinstance(rec, dict):
            continue
        tkey = rec.get("theme_key")
        qslug = rec.get("question_slug")
        label = rec.get("theme_label", "")
        if not tkey or not qslug:
            continue  # malformed record — skip rather than corrupt the block
        entry = by_key.get(tkey)
        if entry is None:
            entry = {
                "theme_key": tkey,
                "question_slug": qslug,
                "labels": [label] if label else [],
                "first_seen": today,
                "last_seen": today,
            }
            covered.append(entry)
            by_key[tkey] = entry
            themes_added += 1
        else:
            entry["question_slug"] = qslug
            labels = entry.setdefault("labels", [])
            if label and label not in labels:
                labels.append(label)
            entry["last_seen"] = today
            themes_updated += 1

    written = _write_binding(knowledge_root, binding)
    return _emit(
        True,
        data={
            "path": str(written),
            "themes_added": themes_added,
            "themes_updated": themes_updated,
            "covered_themes_count": len(covered),
        },
    )


def cmd_set_charter(args: argparse.Namespace) -> int:
    """In-place charter re-frame on an existing base (#451). The second writer of
    the charter block (init is the first); writes the SAME schema-0.1.4 shape, so
    it does NOT bump schema_version. Partial update: a flag left unset (None)
    leaves the existing value untouched; a supplied flag (including "") overwrites
    that field — so the domain can sharpen without clearing audience/scope.
    --open-themes UNION-merges into topic_lineage.open_themes[] (append the new,
    preserve order, never clobber the backlog). framed_at is re-stamped only when a
    charter field (domain/audience/scope) actually changes. Fail-soft on a
    pre-0.1.4 binding: setdefault() a complete all-"" charter + an open_themes[]
    before applying updates."""
    knowledge_root = Path(args.knowledge_root).resolve()

    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")

    if args.knowledge_slug and binding.get("knowledge_slug") != args.knowledge_slug:
        return _emit(
            False,
            data={"binding_slug": binding.get("knowledge_slug")},
            error=(
                f"knowledge_slug mismatch: binding has '{binding.get('knowledge_slug')}', "
                f"caller passed '{args.knowledge_slug}'"
            ),
        )

    # Require at least one substantive flag — never a silent no-op write.
    charter_fields_passed = any(
        v is not None
        for v in (args.charter_domain, args.charter_audience, args.charter_scope)
    )
    if not charter_fields_passed and args.open_themes is None:
        return _emit(
            False,
            error=(
                "nothing to update — pass at least one of --charter-domain / "
                "--charter-audience / --charter-scope / --open-themes"
            ),
        )

    # Fail-soft: a base created before the charter existed gains a complete block.
    charter = binding.setdefault("charter", dict(DEFAULT_CHARTER))

    # Partial update — only overwrite a field whose flag was supplied (None = leave).
    changed_charter = False
    for field, value in (
        ("domain", args.charter_domain),
        ("audience", args.charter_audience),
        ("scope", args.charter_scope),
    ):
        if value is not None:
            charter[field] = value
            changed_charter = True

    # Union-merge the seed-theme backlog: append not-already-present, preserve order.
    themes_added = 0
    if args.open_themes is not None:
        lineage = binding.setdefault("topic_lineage", {})
        open_themes = lineage.setdefault("open_themes", [])
        incoming = [t.strip() for t in args.open_themes.split("|") if t.strip()]
        for theme in incoming:
            if theme not in open_themes:
                open_themes.append(theme)
                themes_added += 1

    # Re-stamp framed_at only when the base was actually re-steered (a
    # domain/audience/scope change); an open-themes-only update is not a re-frame.
    if changed_charter:
        charter["framed_at"] = _today()

    written = _write_binding(knowledge_root, binding)
    return _emit(
        True,
        data={
            "path": str(written),
            "charter": charter,
            "open_themes_added": themes_added,
            "open_themes_count": len(binding.get("topic_lineage", {}).get("open_themes", [])),
        },
    )


def cmd_read(args: argparse.Namespace) -> int:
    knowledge_root = Path(args.knowledge_root).resolve()
    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")
    return _emit(True, data={"binding": binding, "path": str(_binding_path(knowledge_root))})


def cmd_themes(args: argparse.Namespace) -> int:
    """Read-side partition of the seed-theme backlog for the resume/dashboard
    display (#450). open_themes[] is seeded once at knowledge-setup and never
    pruned, while covered_themes[] is written independently by upsert-themes as
    themes get researched — so a researched seed keeps rendering as "open".

    This computes open MINUS covered at READ time (never mutates the binding):
    a seed theme is hidden only when its theme_norm_key matches a covered
    theme_key (the same normalized token-set key covered_themes was built from,
    so a variant phrasing still matches). Keep-on-doubt — an empty key or no
    match leaves the theme visible (the safe direction). Also emits a
    render-ready covered[] list (labels[0] with a question_slug fallback),
    centralizing the rule the resume skill previously spelled out inline.

    Fail-soft on a structurally-wrong binding (mirrors question-store.py's
    posture): a non-dict topic_lineage / non-list theme arrays degrade to empty
    partitions with success: true rather than erroring."""
    knowledge_root = Path(args.knowledge_root).resolve()
    try:
        binding = _read_binding(knowledge_root)
    except FileNotFoundError as exc:
        return _emit(False, error=str(exc))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"binding.json is not valid JSON: {exc}")

    tl = binding.get("topic_lineage", {})
    if not isinstance(tl, dict):
        tl = {}

    raw_covered = tl.get("covered_themes", [])
    if not isinstance(raw_covered, list):
        raw_covered = []
    # Only non-empty keys gate a hide — an empty theme_key never matches.
    covered_keys = {
        e["theme_key"]
        for e in raw_covered
        if isinstance(e, dict) and e.get("theme_key")
    }

    raw_open = tl.get("open_themes", [])
    if not isinstance(raw_open, list):
        raw_open = []
    open_active: list[str] = []
    open_covered: list[str] = []
    for t in raw_open:
        if not isinstance(t, str):
            continue  # open_themes is a plain string list — skip non-strings
        k = theme_norm_key(t)
        # An empty key never hides (it would otherwise match every empty label).
        if k and k in covered_keys:
            open_covered.append(t)
        else:
            open_active.append(t)

    # Render-ready covered list: one {label, question_slug} per entry, label
    # falling back to question_slug when labels[] is empty (defensive —
    # upsert-themes always unions a non-empty label).
    covered: list[dict] = []
    for e in raw_covered:
        if not isinstance(e, dict):
            continue
        labels = e.get("labels") or []
        qslug = e.get("question_slug", "")
        label = labels[0] if labels else qslug
        covered.append({"label": label, "question_slug": qslug})

    return _emit(
        True,
        data={
            "open_active": open_active,
            "open_covered": open_covered,
            "covered": covered,
            "open_total": len(raw_open),
            "covered_total": len(raw_covered),
        },
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Read/write .cogni-knowledge/binding.json",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_init = sub.add_parser("init", help="Create a new binding manifest")
    p_init.add_argument("--knowledge-root", required=True)
    p_init.add_argument("--knowledge-slug", required=True)
    p_init.add_argument("--knowledge-title", required=True)
    p_init.add_argument("--wiki-path", required=True)
    p_init.add_argument(
        "--market",
        required=False,
        default="",
        help="Default market for this knowledge base (research_defaults.market). "
             "Falls back to 'dach' when omitted.",
    )
    p_init.add_argument(
        "--output-language",
        required=False,
        default="",
        help="Default output language for this knowledge base "
             "(research_defaults.output_language). Falls back to 'en' when omitted.",
    )
    # The four writer-quality knobs (schema 0.1.2, #309 P2). Each persists into
    # research_defaults and is inherited by every knowledge-plan run (overridable
    # per run via knowledge-plan's matching flag). All have a safe default, so a
    # plain `init` writes a complete block.
    p_init.add_argument(
        "--prose-density",
        required=False,
        default="",
        help="Default prose density: 'standard' (target_words is a floor) or "
             "'executive' (BLUF + Pyramid, target_words is a ceiling). "
             "Falls back to 'standard' when omitted.",
    )
    p_init.add_argument(
        "--tone",
        required=False,
        default="",
        help="Default writing tone (see references/writing-tones.md). "
             "Falls back to 'objective' when omitted.",
    )
    p_init.add_argument(
        "--citation-format",
        required=False,
        default="",
        help="Default citation format. 'ieee' / 'chicago' render end-to-end "
             "(both numbered superscripts); 'apa'/'mla'/'harvard' are staged. "
             "Falls back to 'ieee' when omitted.",
    )
    p_init.add_argument(
        "--target-words",
        required=False,
        type=int,
        default=0,
        help="Default soft target word count (floor under standard density, "
             "ceiling under executive). Positive int; falls back to 4000 when "
             "omitted or 0.",
    )
    # Charter fields (schema 0.1.4) — the base-level steering captured at
    # knowledge-setup Step 2.5. Each falls through to "" so a plain init still
    # writes a complete charter block.
    p_init.add_argument(
        "--charter-domain",
        required=False,
        default="",
        help="One sentence: what this knowledge base is about "
             "(charter.domain). Empty when omitted.",
    )
    p_init.add_argument(
        "--charter-audience",
        required=False,
        default="",
        help="Primary reader of syntheses from this base (charter.audience). "
             "Empty when omitted.",
    )
    p_init.add_argument(
        "--charter-scope",
        required=False,
        default="",
        help="In/out boundaries — geography / segment / horizon, one line "
             "(charter.scope). Empty when omitted.",
    )
    p_init.add_argument(
        "--open-themes",
        required=False,
        default="",
        help="Pipe-separated seed-theme backlog → topic_lineage.open_themes[] "
             "(e.g. 'high-risk systems|conformity assessment|GPAI'). Empty list "
             "when omitted.",
    )
    p_init.set_defaults(func=cmd_init)

    p_append = sub.add_parser("append-project", help="Record a deposited research project")
    p_append.add_argument("--knowledge-root", required=True)
    p_append.add_argument("--knowledge-slug", required=False, default="")
    p_append.add_argument("--research-slug", required=True)
    p_append.add_argument("--report-path", required=False, default="")
    p_append.add_argument(
        "--project-path",
        required=False,
        default="",
        help=(
            "Absolute path to the cogni-research project root (the dir "
            "that contains .metadata/project-config.json). Optional but "
            "recommended — cycle-guard prefers it over deriving the project "
            "dir from report_path.parent.parent."
        ),
    )
    p_append.add_argument("--report-source", required=True, choices=sorted(VALID_REPORT_SOURCES))
    p_append.add_argument("--deposited-at", required=False, default="")
    p_append.add_argument(
        "--allow-update",
        action="store_true",
        help=(
            "On duplicate research_slug, update the existing entry in place "
            "instead of refusing. Used by knowledge-finalize --overwrite to "
            "keep the binding's report_path / deposited_at fresh when "
            "re-depositing a refined draft."
        ),
    )
    p_append.set_defaults(func=cmd_append_project)

    p_upsert = sub.add_parser(
        "upsert-themes",
        help="Merge question-node theme-lineage records into topic_lineage.covered_themes[] (#409)",
    )
    p_upsert.add_argument("--knowledge-root", required=True)
    p_upsert.add_argument(
        "--records",
        required=True,
        help="JSON file of question-store.py theme_bindings[] ('-' for stdin). "
             "Accepts the bare array, {theme_bindings: []}, or the full "
             "{success, data: {theme_bindings: []}} envelope.",
    )
    p_upsert.set_defaults(func=cmd_upsert_themes)

    p_setchar = sub.add_parser(
        "set-charter",
        help="In-place charter re-frame on an existing base (#451; partial field "
             "update + union-merge into open_themes[])",
    )
    p_setchar.add_argument("--knowledge-root", required=True)
    p_setchar.add_argument(
        "--knowledge-slug",
        required=False,
        default="",
        help="Optional guard — refuse if the binding's knowledge_slug differs. "
             "Empty (default) = no guard.",
    )
    # default=None (NOT init's "") so an unset flag is distinguishable from a
    # supplied empty string: None leaves the field untouched, "" overwrites it.
    p_setchar.add_argument(
        "--charter-domain",
        required=False,
        default=None,
        help="New charter.domain (one sentence: what this base is about). "
             "Omitted = leave the existing value untouched.",
    )
    p_setchar.add_argument(
        "--charter-audience",
        required=False,
        default=None,
        help="New charter.audience (primary reader of syntheses). "
             "Omitted = leave the existing value untouched.",
    )
    p_setchar.add_argument(
        "--charter-scope",
        required=False,
        default=None,
        help="New charter.scope (geography / segment / horizon, one line). "
             "Omitted = leave the existing value untouched.",
    )
    p_setchar.add_argument(
        "--open-themes",
        required=False,
        default=None,
        help="Pipe-separated seed themes to ADD to topic_lineage.open_themes[] "
             "(union-merge — appends the new, never clobbers the backlog). "
             "Omitted = leave the backlog untouched.",
    )
    p_setchar.set_defaults(func=cmd_set_charter)

    p_read = sub.add_parser("read", help="Emit the binding manifest")
    p_read.add_argument("--knowledge-root", required=True)
    p_read.set_defaults(func=cmd_read)

    p_themes = sub.add_parser(
        "themes",
        help="Partition the seed-theme backlog into still-open vs already-researched "
             "(open MINUS covered) for the resume/dashboard display; read-only",
    )
    p_themes.add_argument("--knowledge-root", required=True)
    p_themes.set_defaults(func=cmd_themes)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

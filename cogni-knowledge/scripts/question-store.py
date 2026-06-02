#!/usr/bin/env python3
"""question-store.py — emit per-sub-question `type: question` wiki nodes.

v0.1.0 inverted pipeline, Phase 4 (`knowledge-ingest` Step 4.5, #407). The
deterministic engine that promotes each `plan.sub_questions[]` entry into a
first-class research-question node at `wiki/questions/<slug>.md` whose body
`[[links]]` the source findings that answer it. The reverse `source→question`
backlink, the `wiki/index.md` row, and the `entries_count` bump are applied by
the orchestrator via cogni-wiki's own locked helpers (`backlink_audit.py`,
`wiki_index_update.py`, `config_bump.py`) — this script owns only the page
write, which is unique-by-construction per slug (no lock needed, same posture
as the Step 3 source pages).

Subcommand:
  emit   Join plan.json + candidates.json + ingest-manifest.json, build each
         sub-question's finding set, derive a globally-unique slug, write or
         merge `wiki/questions/<slug>.md`, and return the per-question plan the
         orchestrator consumes for backlink / index / count steps.

Cross-run theme accumulation (#409): an optional `--binding` arg reads
`topic_lineage.covered_themes[]` to map a theme's `_knowledge_lib.theme_norm_key`
to its recorded `question_slug`, so a recurring theme phrased differently across
runs (variant `theme_label`) routes to the SAME question node instead of forking
a second one. Read-only — the script emits `data.theme_bindings[]` and the
orchestrator persists them via `knowledge-binding.py upsert-themes` (the single
binding writer). Without `--binding`, behaviour is byte-identical to the pre-#409
slug-only accumulation.

`--wiki-scripts-dir` points at cogni-wiki's `wiki-ingest/scripts/` (resolved by
the orchestrator, same `resolve_wiki_scripts` helper knowledge-ingest uses) so
we import `PAGE_TYPE_DIRS` + `split_frontmatter` from the single source of
truth rather than re-deriving the per-type layout. Slug derivation +
atomic write reuse `_knowledge_lib.slugify` / `atomic_write_text`.

Returns the insight-wave `{"success", "data", "error"}` envelope. Stdlib only.
"""

from __future__ import annotations

import argparse
import datetime
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _ANSWER_CLAIMS_KEY_RE,
    _FRONTMATTER_RE,
    atomic_write_text,
    claim_similarity,
    norm_key,
    normalize_url,
    parse_answer_records,
    slugify,
    theme_norm_key,
)

# --- answer-claim dedup/render engine (#432) ---------------------------------
# Ported field-for-field from concept-store.py's distilled-claim engine (the proven
# create-or-merge + claim-dedup + provenance-union + round-trip-self-check core), with
# `dcl-` → `acl-` (answer-claim ids) the only semantic change. answer-merge owns the
# WHOLE machinery here rather than re-using `_knowledge_lib.parse_answer_claims_with_id`
# (which captures only claim_id+text for verify-store's keying) because the merge READ
# must round-trip every persisted field — norm_key / backlinks / source_claim_refs /
# dates — or a re-merge would silently drop provenance. Same "we own both reader and
# writer, so round-trip losslessly without a YAML lib" discipline as concept-store.

# Symmetric weighted-Jaccard threshold for the NEAR-match half of the dedup predicate
# (identical calibration + fail-safe-keep-both bias as concept-store.SIMILARITY_THRESHOLD).
SIMILARITY_THRESHOLD = 0.85
_ACL_ID_RE = re.compile(r"^acl-(\d+)$")
# Frontmatter `updated:` scalar, anchored at column 0 so it never matches the indented
# per-claim `    updated:` lines inside the answer_claims: block.
_FM_UPDATED_RE = re.compile(r"(?m)^updated:[ \t]*.+$")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": bool(success), "data": data or {}, "error": error or ""}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def _json_scalar(value: str) -> str:
    """A YAML-valid double-quoted scalar via json.dumps — escaping owned by Python,
    never hand-rolled (the #325 discipline; mirrors concept-store._json_scalar)."""
    return json.dumps(value if value is not None else "", ensure_ascii=False)


def _decode_scalar(raw: str):
    """Decode a single-line value we wrote: a JSON string/array round-trips via
    json.loads; a bare scalar (dates, acl ids) returns stripped."""
    raw = raw.strip()
    if raw and raw[0] in '"[':
        try:
            return json.loads(raw)
        except ValueError:
            pass
    return raw


def _absorb_answer_claim_field(item: dict, kv: str) -> None:
    if ":" not in kv:
        return
    key, _, value = kv.partition(":")
    key = key.strip()
    if key in ("claim_id", "created", "updated"):
        item[key] = value.strip()
    elif key in ("text", "norm_key"):
        item[key] = _decode_scalar(value)
    elif key in ("backlinks", "source_claim_refs"):
        decoded = _decode_scalar(value)
        item[key] = decoded if isinstance(decoded, list) else []


def _parse_answer_claims(page_text: str) -> list[dict]:
    """Read back the FULL `answer_claims:` block we wrote — every persisted field, not
    just claim_id+text. Mirrors concept-store._parse_distilled_claims exactly (the lib's
    parse_answer_claims_with_id deliberately captures only claim_id+text for verify-store
    keying, which would lose provenance on a re-merge). Tolerant of indent."""
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return []
    lines = m.group(1).splitlines()
    start = None
    for i, line in enumerate(lines):
        if _ANSWER_CLAIMS_KEY_RE.match(line):
            start = i + 1
            break
    if start is None:
        return []
    claims: list[dict] = []
    current: dict | None = None
    for line in lines[start:]:
        stripped = line.strip()
        # Block ends at the next top-level (column-0, non-bullet) key.
        if stripped and line[:1] not in (" ", "\t") and not stripped.startswith("- "):
            break
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("- "):
            if current is not None:
                claims.append(current)
            current = {}
            rest = stripped[2:].strip()
            if rest:
                _absorb_answer_claim_field(current, rest)
        elif current is not None:
            _absorb_answer_claim_field(current, stripped)
    if current is not None:
        claims.append(current)
    return claims


def _next_acl_id(claims: list[dict]) -> int:
    hi = 0
    for c in claims:
        m = _ACL_ID_RE.match(str(c.get("claim_id", "")))
        if m:
            hi = max(hi, int(m.group(1)))
    return hi + 1


def _merge_answer_claims(existing: list[dict], incoming: list[dict], today: str) -> tuple:
    """Merge the distiller's proposed answer claims into the existing answer_claims[]
    list. Ported field-for-field from concept-store._merge_claims (acl ids; same dedup
    predicate + fail-safe keep-both + provenance-union). Returns (merged, stats) where
    stats = {in, new, deduped, noop, rejected}."""
    merged = [dict(c) for c in existing]
    next_id = _next_acl_id(merged)
    stats = {"in": 0, "new": 0, "deduped": 0, "noop": 0, "rejected": 0}

    for inc in incoming:
        src_slug = (inc.get("source_slug") or "").strip()
        cid = (inc.get("source_claim_id") or "").strip()
        text = (inc.get("text") or "").strip()
        if not src_slug or not cid or not text:
            stats["rejected"] += 1
            continue
        stats["in"] += 1
        ref = f"{src_slug}#{cid}"
        nk = norm_key(text)

        # NOOP: this exact source-claim is already deposited (re-run idempotency).
        if any(ref in c.get("source_claim_refs", []) for c in merged):
            stats["noop"] += 1
            continue

        match = None
        if nk:  # exact norm_key (skip empty keys — distinct all-boilerplate must not merge)
            for c in merged:
                if c.get("norm_key") and c["norm_key"] == nk:
                    match = c
                    break
        if match is None:  # near: symmetric weighted-Jaccard
            for c in merged:
                if claim_similarity(text, c.get("text", "")) >= SIMILARITY_THRESHOLD:
                    match = c
                    break

        if match is not None:
            if src_slug not in match.setdefault("backlinks", []):
                match["backlinks"].append(src_slug)
            if ref not in match.setdefault("source_claim_refs", []):
                match["source_claim_refs"].append(ref)
            match["updated"] = today
            stats["deduped"] += 1
        else:
            merged.append({
                "claim_id": f"acl-{next_id:03d}",
                "text": text,
                "norm_key": nk,
                "backlinks": [src_slug],
                "source_claim_refs": [ref],
                "created": today,
                "updated": today,
            })
            next_id += 1
            stats["new"] += 1

    return merged, stats


def _render_answer_claims(claims: list[dict]) -> str:
    """Render the `answer_claims:` frontmatter block — mirrors
    concept-store._render_distilled_claims (same field order, two-space indent, json
    scalars) so verify-store's `parse_answer_claims_with_id` reads it back identically."""
    if not claims:
        return "answer_claims: []\n"
    lines = ["answer_claims:"]
    for c in claims:
        lines.append(f"  - claim_id: {c['claim_id']}")
        lines.append(f"    text: {_json_scalar(c.get('text', ''))}")
        lines.append(f"    norm_key: {_json_scalar(c.get('norm_key', ''))}")
        lines.append(f"    backlinks: {json.dumps(c.get('backlinks', []), ensure_ascii=False)}")
        lines.append(
            f"    source_claim_refs: {json.dumps(c.get('source_claim_refs', []), ensure_ascii=False)}"
        )
        lines.append(f"    created: {c.get('created', '')}")
        lines.append(f"    updated: {c.get('updated', '')}")
    return "\n".join(lines) + "\n"


def _claims_fingerprint(claims: list[dict]) -> list[tuple]:
    """A tuple per claim covering EVERY persisted field, for the pre-write round-trip
    self-check (port of concept-store._claims_fingerprint)."""
    return [(
        c.get("claim_id", ""), c.get("text", ""), c.get("norm_key", ""),
        tuple(c.get("backlinks", [])), tuple(c.get("source_claim_refs", [])),
        c.get("created", ""), c.get("updated", ""),
    ) for c in claims]


def _splice_answer_claims(page_text: str, merged_claims: list[dict], today: str) -> tuple:
    """Splice the rendered `answer_claims:` block into the page's frontmatter, replacing
    an existing block in place or appending it before the FM close — preserving the
    `---` markers, every OTHER frontmatter key, and the entire body (`## Findings` +
    `## Notes`) BYTE-FOR-BYTE. Returns (new_text, changed). Renders first with the
    existing `updated:` (idempotency); only bumps it to today on a real change.

    The block-boundary rule (key line + run of blank / indented / bullet lines up to the
    next top-level key) matches `_knowledge_lib._parse_claim_block`, so a re-splice lands
    on exactly the span a prior answer-merge wrote."""
    m = _FRONTMATTER_RE.match(page_text)
    if not m:
        return page_text, False  # caller guards type==question on a parseable FM
    inner_start, inner_end = m.start(1), m.end(1)
    prefix = page_text[:inner_start]
    suffix = page_text[inner_end:]  # the `\n---…` close + the whole body, byte-exact
    inner_lines = page_text[inner_start:inner_end].split("\n")
    block_lines = _render_answer_claims(merged_claims).rstrip("\n").split("\n")

    start = None
    for i, line in enumerate(inner_lines):
        if _ANSWER_CLAIMS_KEY_RE.match(line):
            start = i
            break
    if start is not None:
        end = start + 1
        while end < len(inner_lines):
            line = inner_lines[end]
            stripped = line.strip()
            if stripped == "" or line[:1] in (" ", "\t") or stripped == "-" or stripped.startswith("- "):
                end += 1
            else:
                break
        new_inner_lines = inner_lines[:start] + block_lines + inner_lines[end:]
    else:
        new_inner_lines = inner_lines + block_lines

    candidate = prefix + "\n".join(new_inner_lines) + suffix
    if candidate == page_text:
        return page_text, False
    bumped = _FM_UPDATED_RE.sub(f"updated: {today}", "\n".join(new_inner_lines), count=1)
    return prefix + bumped + suffix, True


def _answer_result(slug: str, action: str, *, reason: str = "",
                   stats: dict | None = None) -> dict:
    """Per-question result — the UNIFORM key set the distill Step-6.9 summary consumes
    (`{slug, action, reason, claims_new, claims_deduped, claims_rejected}`). Every action
    carries the three claim counts so `cmd_answer_merge` can sum across all results
    (incl. skipped/write_failed) without a KeyError. The merge engine's other internal
    stats (`in`/`noop`) and the page path are not surfaced — nothing downstream reads
    them (answer-merge writes no manifest, unlike concept-store)."""
    stats = stats or {}
    return {
        "slug": slug, "action": action, "reason": reason,
        "claims_new": stats.get("new", 0),
        "claims_deduped": stats.get("deduped", 0),
        "claims_rejected": stats.get("rejected", 0),
    }


def _answer_merge_one(record: dict, wiki_root: Path, today: str,
                      parse_frontmatter, is_foundation_page) -> dict:
    """Merge one question record's answer claims into its `wiki/questions/<slug>.md`
    page under the caller's lock. Returns a per-slug result dict."""
    slug = (record.get("slug") or "").strip()
    if not slug:
        return _answer_result("", "skipped", reason="empty_slug")
    page_path = wiki_root / "wiki" / "questions" / f"{slug}.md"
    if not page_path.is_file():
        return _answer_result(slug, "skipped", reason="page_not_found")
    text = page_path.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    if is_foundation_page(fm):
        return _answer_result(slug, "skipped", reason="foundation_collision")
    # The discriminator for "our page" is type==question — NOT a MACHINE-OWNED sentinel
    # check (question pages have none by design; a sentinel guard would refuse them all).
    if str(fm.get("type", "")).strip().strip('"\'') != "question":
        return _answer_result(slug, "skipped", reason="not_a_question_page")

    existing = _parse_answer_claims(text)
    had_block = "answer_claims:" in text  # whether the page already carried the key
    merged, stats = _merge_answer_claims(existing, record.get("claims", []), today)
    new_text, changed = _splice_answer_claims(text, merged, today)

    if not changed:
        return _answer_result(slug, "unchanged", stats=stats)

    # Pre-write round-trip self-check: every persisted claim field must parse back from
    # the text we are about to write (data loss across runs is unrecoverable).
    if _claims_fingerprint(_parse_answer_claims(new_text)) != _claims_fingerprint(merged):
        return _answer_result(slug, "write_failed", reason="claims_round_trip_mismatch",
                              stats=stats)

    atomic_write_text(page_path, new_text)
    return _answer_result(slug, "updated" if had_block else "created_block", stats=stats)


def cmd_answer_merge(args: argparse.Namespace) -> int:
    """Merge the answer-distiller's raw-text records into each question node's
    `answer_claims:` frontmatter block — the citable answer surface (#432). Shared-state
    read-modify-write of an existing page, so it runs under cogni-wiki's `_wiki_lock`
    (imported from _wikilib via --wiki-scripts-dir, same posture as concept-store.py)."""
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock, is_foundation_page, parse_frontmatter  # noqa: E402
    except ImportError as exc:
        return _emit(False, error=f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")
    records_path = Path(args.records).resolve()
    try:
        records_text = records_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return _emit(False, data={"path": str(records_path)}, error="records_not_found")
    except OSError as exc:
        return _emit(False, error=f"records file is not readable: {exc}")

    records = parse_answer_records(records_text)
    today = datetime.date.today().isoformat()
    results: list[dict] = []
    # One lock for the whole batch: each _answer_merge_one re-reads its page from disk.
    with _wiki_lock(wiki_root):
        for record in records:
            try:
                results.append(_answer_merge_one(
                    record, wiki_root, today, parse_frontmatter, is_foundation_page))
            except Exception as exc:  # noqa: BLE001 — one bad record must not abort the batch
                results.append(_answer_result((record.get("slug") or ""), "write_failed",
                                              reason=f"exception: {exc}"))

    attached_total = sum(r["claims_new"] + r["claims_deduped"] for r in results)
    deduped_total = sum(r["claims_deduped"] for r in results)
    rejected_total = sum(r["claims_rejected"] for r in results)
    return _emit(True, data={
        "questions": results,
        "claims_attached_total": attached_total,
        "claims_deduped_total": deduped_total,
        "claims_rejected_total": rejected_total,
        "n_questions": len(results),
    })


def cmd_emit(args: argparse.Namespace) -> int:
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import PAGE_TYPE_DIRS, split_frontmatter  # noqa: E402
    except Exception as exc:  # pragma: no cover - import guard
        return _emit(False, error=f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")

    try:
        plan = _load_json(Path(args.plan))
        cands = _load_json(Path(args.candidates))
        manifest = _load_json(Path(args.ingest_manifest))
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(False, error=f"could not read inputs: {exc}")

    # Lineage map (#409): theme_norm_key -> recorded question_slug, from the
    # binding's topic_lineage.covered_themes[]. Read-only here — this script
    # NEVER writes binding.json; the orchestrator persists new/updated themes
    # via `knowledge-binding.py upsert-themes` (the single writer). The map is
    # empty when --binding is absent (byte-identical to the pre-#409 path), the
    # binding is older / has no covered_themes (fail-soft .get chain), the
    # binding is corrupt / transiently unreadable (#426 fail-soft read degrade),
    # or the binding parses as valid JSON but is structurally wrong for the
    # lineage read (#428 fail-soft shape degrade below). In every degrade case
    # the reason is surfaced as data.binding_skipped and emit never aborts.
    lineage: dict[str, str] = {}
    binding_skipped = ""
    if args.binding:
        try:
            binding = _load_json(Path(args.binding))
        except (OSError, json.JSONDecodeError) as exc:
            # Lineage is an enhancement layer — a corrupt / transiently
            # unreadable binding degrades to slug-only accumulation, never
            # blocks question-node creation. Reason surfaced for observability.
            binding_skipped = f"could not read --binding: {exc}"
        else:
            # #428: a binding that parses as valid JSON but is the wrong shape
            # (a JSON array/scalar, or a present-but-null / non-dict
            # topic_lineage — the {} default only fires on an ABSENT key) must
            # degrade the same way, not raise an AttributeError past the
            # read-error catch into the top-level guard. An explicit shape guard
            # keeps the binding_skipped reason accurate (vs widening the except)
            # and the happy path byte-stable.
            if not isinstance(binding, dict):
                binding_skipped = (
                    f"--binding is not a JSON object "
                    f"(got {type(binding).__name__}); ignoring lineage"
                )
            else:
                tl = binding.get("topic_lineage", {})
                if not isinstance(tl, dict):
                    binding_skipped = (
                        "--binding topic_lineage is not an object; ignoring lineage"
                    )
                    tl = {}
                for e in tl.get("covered_themes", []) or []:
                    if not isinstance(e, dict):
                        continue
                    tk = e.get("theme_key")
                    qs = e.get("question_slug")
                    if tk and qs:
                        lineage[tk] = qs

    today = datetime.date.today().isoformat()
    questions_dir = wiki_root / "wiki" / "questions"

    # URL(normalized) -> source slug, from this project's ingested findings.
    url_to_slug = {
        normalize_url(e["url"]): e["slug"]
        for e in manifest.get("ingested", []) or []
        if e.get("url") and e.get("slug")
    }
    # URL(normalized) -> sub_question_refs[], from candidates.json.
    url_to_refs = {
        normalize_url(c["url"]): (c.get("sub_question_refs") or [])
        for c in cands.get("candidates", []) or []
        if c.get("url")
    }

    # sub_question_id -> ordered, de-duped list of answering source slugs.
    # A source whose ingested URL matches no candidate sub_question_ref (e.g. a
    # redirect / PDF canonicalization diverged the ingested URL from the
    # candidate URL) maps to no question node and is recorded in
    # `sources_unmapped` rather than dropping silently (observability).
    sq_findings: dict[str, list[str]] = {}
    sources_unmapped: list[str] = []
    for nurl, slug in url_to_slug.items():
        refs = url_to_refs.get(nurl, [])
        if not refs:
            sources_unmapped.append(slug)
            continue
        for ref in refs:
            bucket = sq_findings.setdefault(ref, [])
            if slug not in bucket:
                bucket.append(slug)

    def slug_exists_as(slug: str):
        """Return the existing page type for `slug`, or None. Wiki slugs are
        global, so a question node must not collide with any other type."""
        for ptype, dirname in PAGE_TYPE_DIRS.items():
            if (wiki_root / "wiki" / dirname / f"{slug}.md").is_file():
                return ptype
        return None

    emitted_slugs: dict[str, str] = {}  # slug -> sub_question_id written this run

    def resolve_slug(base: str):
        """Free slug, or an existing QUESTION page from a PRIOR run -> reuse
        (merge). Disambiguate with -q / -q-N when the base slug collides with a
        different page type OR with a question page already written *this run*
        for a different sub-question — two distinct sub-questions whose
        theme_label slugifies identically must not conflate into one node, while
        the cross-run enrich-on-collision merge stays intact."""
        cand = base
        n = 2
        while True:
            if cand in emitted_slugs:
                # Already written this run (different sub-question; each id is
                # processed once) -> never a merge target, disambiguate.
                cand = f"{base}-q" if n == 2 else f"{base}-q-{n}"
                n += 1
                continue
            existing = slug_exists_as(cand)
            if existing in (None, "question"):
                return cand, existing == "question"
            cand = f"{base}-q" if n == 2 else f"{base}-q-{n}"
            n += 1

    questions_out: list[dict] = []
    skipped_no_findings: list[str] = []
    theme_bindings: list[dict] = []
    seen_tkeys: set[str] = set()  # first-writer-wins per theme_key within a run

    for sq in plan.get("sub_questions", []) or []:
        sqid = sq.get("id", "")
        findings = list(sq_findings.get(sqid, []))
        if not findings:
            skipped_no_findings.append(sqid)
            continue

        theme = (sq.get("theme_label") or "").strip()
        # Slug-base precedence (#409): a lineage match on the theme_norm_key
        # reuses the recorded question_slug, so a variant theme_label routes to
        # the existing prior-run node (resolve_slug then returns is_merge=True
        # and the union path fires). Otherwise the pre-#409 base derivation.
        tkey = theme_norm_key(theme)
        lineage_hit = bool(tkey) and tkey in lineage
        if lineage_hit:
            base = lineage[tkey]
        else:
            base = slugify(theme) or (slugify(sqid) or sqid)  # legacy plans -> sq-NN
        slug, is_merge = resolve_slug(base)
        path = questions_dir / f"{slug}.md"

        created = today
        notes_block = "## Notes\n"
        if is_merge and path.is_file():
            prior_text = path.read_text(encoding="utf-8")
            pfm, pbody = split_frontmatter(prior_text)
            created = pfm.get("created") or today
            # Union prior answering sources (idempotent enrich-on-collision).
            # split_frontmatter returns inline lists already parsed as lists.
            for s in (pfm.get("sources_answering") or []):
                if s not in findings:
                    findings.append(s)
            # Preserve the human-owned ## Notes tail verbatim.
            marker = "\n## Notes"
            idx = pbody.find(marker)
            if idx != -1:
                notes_block = pbody[idx + 1:].rstrip() + "\n"

        domains = sq.get("candidate_domains") or []
        fm_lines = [
            "---",
            f"id: {slug}",
            f"title: {json.dumps(sq.get('query', ''), ensure_ascii=False)}",
            "type: question",
            "tags: [question]",
            f"created: {created}",
            f"updated: {today}",
            f"theme_label: {json.dumps(theme, ensure_ascii=False)}",
            f"sub_question_id: {sqid}",
            f"search_guidance: {json.dumps(sq.get('search_guidance', ''), ensure_ascii=False)}",
            f"candidate_domains: [{', '.join(json.dumps(str(d), ensure_ascii=False) for d in domains)}]",
            f"sources_answering: [{', '.join(findings)}]",
            "---",
        ]
        body_lines = ["", "## Findings", ""]
        body_lines += [f"- [[{s}]]" for s in findings]
        body_lines += ["", notes_block.rstrip() + "\n"]
        page = "\n".join(fm_lines) + "\n" + "\n".join(body_lines).rstrip() + "\n"

        atomic_write_text(path, page)
        emitted_slugs[slug] = sqid
        questions_out.append({
            "slug": slug,
            "sub_question_id": sqid,
            "query": sq.get("query", ""),
            "sources_answering": findings,
            "action": "merged" if is_merge else "created",
        })

        # Theme-lineage binding (#409): one record per written question whose
        # theme_label has a non-empty norm key, first-writer-wins per theme_key
        # (a second same-run sub-question that -q-disambiguates to a distinct
        # node must NOT steal the canonical node's theme_key). An empty tkey
        # (legacy / stopword-only theme_label) records nothing — that node
        # accumulates by slug only, as before. The orchestrator feeds these to
        # `knowledge-binding.py upsert-themes` (the single binding writer).
        if tkey and tkey not in seen_tkeys:
            seen_tkeys.add(tkey)
            theme_bindings.append({
                "theme_key": tkey,
                "question_slug": slug,
                "theme_label": theme,
                "action": "lineage_reused" if lineage_hit else "new_theme",
            })

    data = {
        "questions": questions_out,
        "theme_bindings": theme_bindings,
        "skipped_no_findings": skipped_no_findings,
        "sources_unmapped": sources_unmapped,
        "questions_written": len(questions_out),
    }
    if binding_skipped:
        data["binding_skipped"] = binding_skipped
    return _emit(True, data=data)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    p_emit = sub.add_parser("emit", help="Write per-sub-question type:question nodes")
    p_emit.add_argument("--wiki-root", required=True)
    p_emit.add_argument("--wiki-scripts-dir", required=True,
                        help="cogni-wiki wiki-ingest/scripts/ dir (for PAGE_TYPE_DIRS + split_frontmatter)")
    p_emit.add_argument("--plan", required=True, help="<project>/.metadata/plan.json")
    p_emit.add_argument("--candidates", required=True, help="<project>/.metadata/candidates.json")
    p_emit.add_argument("--ingest-manifest", required=True, help="<project>/.metadata/ingest-manifest.json")
    p_emit.add_argument(
        "--binding",
        required=False,
        default="",
        help="Optional .cogni-knowledge/binding.json. When given, "
             "topic_lineage.covered_themes[] supplies a theme_norm_key -> "
             "question_slug map so a recurring theme (variant theme_label) "
             "routes to its existing question node (#409). Read-only; the "
             "orchestrator persists new/updated themes via knowledge-binding.py "
             "upsert-themes. Absent -> byte-identical to the pre-#409 path.",
    )
    p_emit.set_defaults(func=cmd_emit)

    p_am = sub.add_parser(
        "answer-merge",
        help="Merge answer-distiller records into each question node's answer_claims: block (#432)",
    )
    p_am.add_argument("--records", required=True,
                      help="Path to the answer-distiller's raw-text records file")
    p_am.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_am.add_argument("--wiki-scripts-dir", required=True,
                      help="cogni-wiki wiki-ingest/scripts/ dir (for _wiki_lock / is_foundation_page / parse_frontmatter)")
    p_am.set_defaults(func=cmd_answer_merge)

    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except Exception as exc:  # pragma: no cover - top-level guard
        return _emit(False, error=f"{type(exc).__name__}: {exc}")


if __name__ == "__main__":
    sys.exit(main())

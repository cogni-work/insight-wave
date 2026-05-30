#!/usr/bin/env python3
"""
concept-store.py — the locked create-or-merge engine behind Phase 4.5
(`knowledge-distill`). Turns the `concept-distiller` agent's raw-text proposals
into `wiki/concepts/<slug>.md` / `wiki/entities/<slug>.md` pages that *compound*
across runs, and performs the **claim-level dedup** the differentiation thesis
promises (Finding H, #336).

Why a script (not the agent) owns this — the #325 lesson, twice over:
  1. **Serialization.** The agent has no Bash and must never hand-build YAML/JSON
     (a `"` in a German claim breaks a hand-typed structure). It writes raw-text
     records; this script `json.dumps`-quotes every scalar and round-trips the
     page it wrote before trusting it.
  2. **"Same fact?" is deterministic, never the LLM.** The agent proposes WHICH
     claims attach to a concept; this script decides whether two claims are the
     same fact via `_knowledge_lib.norm_key` (exact) then `claim_similarity`
     (symmetric weighted-Jaccard >= threshold). Fail-safe = keep both when
     uncertain (a wrong merge silently destroys a distinct fact and is
     unrecoverable; a missed merge is a visible, measurable duplicate).

Concept/entity pages are **shared-state read-modify-write** (a prior run may have
created them; two same-run proposals may collide), unlike source pages which are
unique-by-construction. So the page RMW runs under cogni-wiki's canonical
`_wiki_lock` on `<wiki-root>/.cogni-wiki/.lock` — interlocking with
`wiki_index_update.py` / `backlink_audit.py` / `config_bump.py` and any
concurrent `wiki-ingest` from another session. The created-vs-updated decision is
made UNDER the lock by on-disk slug existence (never by the manifest), so a crash
between page-write and manifest-write cannot double-create.

Subcommands:
  init            Create an empty distill-manifest.json (schema 0.1.1). Idempotent.
  merge           Parse the distiller's --records file, merge each proposal into
                  its distilled page (concept/entity/summary/learning) under the
                  lock (slug derived here via
                  _knowledge_lib.slugify — orchestrator-owns-slug discipline), and
                  rewrite <project>/.metadata/distill-manifest.json reflecting
                  this run. Returns per-slug actions + the dedup totals.
  renarrate       Parse the concept-summary-narrator's --records file and, under
                  the lock, replace ONLY the SUMMARY machine block of each named
                  page (every other block + the human ## Notes tail stay
                  byte-identical; updated: bumped iff the prose changed). #341 —
                  makes the wiki compound NARRATIVELY (summary integrates new
                  evidence), not just structurally (claim lists accrete).
  xlingual-candidates
                  Scan the run's touched pages' distilled_claims[] and emit the
                  cross-lingual (DE↔EN) merge CANDIDATE pairs (#345): two claims
                  on one page that share an article-number digit anchor but did
                  NOT auto-merge (low overlap). Read-only. The cross-lingual-
                  claim-merger agent may only CONFIRM a pair this command flags.
  crossmerge      Parse the cross-lingual-claim-merger's --records file and, under
                  the lock, UNION each confirmed twin's provenance onto its
                  survivor claim (#345). Re-validates the candidate gate
                  server-side so the LLM can never widen scope; never drops a
                  source_claim_ref or backlink — only the duplicate dcl-id goes.
  read            Emit the current distill-manifest.json content.

`--wiki-scripts-dir` points at cogni-wiki's `wiki-ingest/scripts/` (resolved by
the orchestrator, same `resolve_wiki_scripts` helper knowledge-ingest uses) so we
import `_wiki_lock` / `is_foundation_page` / `parse_frontmatter` from `_wikilib`
rather than re-inlining them (cogni-wiki's stated contract for new shared-state
writers + the insight-wave "no logic that exists upstream" rule).

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies. fcntl.flock — posix only.

See `references/inverted-pipeline.md` Phase 4.5 contract for the page layout +
manifest shape this script enforces.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    _DISTILLED_KEY_RE,
    _FRONTMATTER_RE,
    _unquote_scalar,
    atomic_write,
    atomic_write_text,
    claim_similarity,
    digit_anchor_tokens,
    extract_machine_block,
    norm_key,
    parse_concept_records,
    parse_crossmerge_records,
    parse_renarrate_records,
    slugify,
    token_weight,
    tokenize,
)

SCHEMA_VERSION = "0.1.1"
MANIFEST_FILENAME = "distill-manifest.json"
METADATA_DIRNAME = ".metadata"

# Symmetric weighted-Jaccard threshold for the NEAR-match half of the dedup
# predicate. High on purpose (0.85): the exact `norm_key` path already catches
# reworded-but-identical fact statements, so the near path only needs to absorb
# minor phrasing variants. Calibrated with the fail-safe bias — when in doubt,
# keep both. Raising it under-merges (more visible duplicates, recoverable);
# lowering it risks an unrecoverable over-merge.
SIMILARITY_THRESHOLD = 0.85

# #340 observable tripwire — a NEW concept whose title scores >= this against
# any existing concept/entity title is flagged in `near_existing_slug`. Lower
# than SIMILARITY_THRESHOLD because titles are short (2-3 tokens). Pure
# observability; tuning is cheap and reversible.
NEAR_TITLE_SIMILARITY_THRESHOLD = 0.65

# #345 cross-lingual candidate gate — the non-digit-token Jaccard CEILING above
# which a digit-anchor-sharing pair is rejected as a candidate. A genuine DE↔EN
# twin shares ~nothing but the article number (German and English tokens never
# string-match), so its non-digit Jaccard is ~0. Two *different* facts about the
# same article (Art. 99 §1 vs §5) share wording → high non-digit Jaccard → kept
# OUT of the candidate set. Low on purpose (fail-safe bias: a narrower candidate
# set means fewer pairs the LLM could wrongly confirm). Reversible.
XLINGUAL_NONDIGIT_JACCARD_CEILING = 0.30

# concept type -> wiki subdirectory. Mirrors cogni-wiki PAGE_TYPE_DIRS for the
# four types the distiller emits: concept + entity (#336) and the cross-source
# `summary` + run-level `learning` types added at #342. Every type-iterating
# helper below derives from this dict — it is the single source of truth.
_TYPE_DIRS = {
    "concept": "concepts",
    "entity": "entities",
    "summary": "summaries",
    "learning": "learnings",
}

# Machine-owned body regions. Each is regenerated on every run; anything AFTER
# the last END sentinel (the `## Notes` human region) is spliced back verbatim.
_SENTINEL_END_RE = re.compile(r"<!--\s*MACHINE-OWNED:[A-Z]+:END\s*-->")
_HUMAN_NOTES_PLACEHOLDER = (
    "## Notes\n\n"
    "_Notes below this line are human-owned and preserved across distill runs._\n"
)
_DCL_ID_RE = re.compile(r"^dcl-(\d+)$")
# The frontmatter `updated:` scalar, anchored at column 0 so it never matches the
# indented per-claim `    updated:` lines inside the `distilled_claims:` block.
# `renarrate` bumps this in place (no full re-render) when a summary changes.
_FM_UPDATED_RE = re.compile(r"(?m)^updated:[ \t]*.+$")


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _today() -> str:
    return _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%d")


def _metadata_dir(project_path: Path) -> Path:
    return project_path / METADATA_DIRNAME


def _manifest_path(project_path: Path) -> Path:
    return _metadata_dir(project_path) / MANIFEST_FILENAME


def _empty_manifest() -> dict:
    return {
        "schema_version": SCHEMA_VERSION,
        "concepts": [],
        "claims_attached_total": 0,
        "claims_deduped_total": 0,
        "claims_rejected_total": 0,
        "near_existing_total": 0,
        "near_existing_slugs": [],
    }


# --- frontmatter / body parsing for the page we own --------------------------
# We own both the writer and the reader, so we can round-trip losslessly without
# a general YAML library: every claim scalar is single-line `json.dumps`, every
# list field is a single-line JSON array. A mandatory pre-write round-trip
# self-check (parse the text we are about to write, assert the claim set matches)
# refuses to ship a page whose claims would not parse back — so a parse-fragility
# bug surfaces loudly instead of silently losing a fact across runs.

# The frontmatter-block regex AND the `distilled_claims:` key regex are the single
# source of truth in `_knowledge_lib` (both imported above), not re-declared here —
# a future tweak (BOM tolerance, …) must apply everywhere at once. The coverage
# scorer's `parse_distilled_claims` reads the same block via the same `_DISTILLED_KEY_RE`.


def _json_scalar(value: str) -> str:
    """A YAML-valid double-quoted scalar via json.dumps — escaping owned by
    Python, never hand-rolled (the #325 discipline)."""
    return json.dumps(value if value is not None else "", ensure_ascii=False)


def _decode_scalar(raw: str):
    """Decode a single-line value we wrote: a JSON string/array round-trips via
    json.loads; a bare scalar (dates, dcl ids) returns stripped."""
    raw = raw.strip()
    if raw and raw[0] in '"[':
        try:
            return json.loads(raw)
        except ValueError:
            pass
    return raw


def _parse_distilled_claims(page_text: str) -> list[dict]:
    """Read back the `distilled_claims:` block we wrote. Returns a list of full
    claim dicts. Tolerant of indent; only reads the fields we emit."""
    m = _FRONTMATTER_RE.match(page_text or "")
    if not m:
        return []
    lines = m.group(1).splitlines()
    start = None
    for i, line in enumerate(lines):
        if _DISTILLED_KEY_RE.match(line):
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
                _absorb_claim_field(current, rest)
        elif current is not None:
            _absorb_claim_field(current, stripped)
    if current is not None:
        claims.append(current)
    return claims


def _absorb_claim_field(item: dict, kv: str) -> None:
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


def _extract_machine_block(body: str, name: str) -> str | None:
    """Inner text between `<!-- MACHINE-OWNED:NAME:START -->` and `:END -->`.
    Delegates to `_knowledge_lib.extract_machine_block` — the single source of
    truth, also read by knowledge-distill's Step-6.7 bundle builder (#341)."""
    return extract_machine_block(body, name)


def _replace_machine_block(body: str, name: str, new_inner: str) -> str:
    """Return `body` with the named MACHINE-OWNED block's inner replaced by
    `new_inner`, leaving every other byte untouched. Used by `renarrate` to swap
    ONLY the SUMMARY block without re-rendering the page. The match mirrors
    `extract_machine_block` so it is symmetric with the reader; the START/END
    sentinels and surrounding bytes are preserved verbatim."""
    pat = re.compile(
        r"(<!--\s*MACHINE-OWNED:" + re.escape(name) + r":START\s*-->\r?\n)(.*?)"
        r"(\r?\n?<!--\s*MACHINE-OWNED:" + re.escape(name) + r":END\s*-->)",
        re.DOTALL,
    )
    return pat.sub(lambda m: m.group(1) + new_inner + m.group(3), body, count=1)


def _human_tail(body: str) -> str:
    """Everything after the LAST machine-owned END sentinel — the human region,
    spliced back verbatim on update. Empty when no sentinel is present."""
    last = None
    for m in _SENTINEL_END_RE.finditer(body or ""):
        last = m
    if last is None:
        return ""
    return body[last.end():]


# --- claim merge (the dedup core) --------------------------------------------


def _next_dcl_id(claims: list[dict]) -> int:
    hi = 0
    for c in claims:
        m = _DCL_ID_RE.match(str(c.get("claim_id", "")))
        if m:
            hi = max(hi, int(m.group(1)))
    return hi + 1


def _merge_claims(existing: list[dict], incoming: list[dict], today: str) -> tuple:
    """Merge the distiller's proposed claims into the existing claim list.

    Returns (merged_claims, stats) where stats = {in, new, deduped, noop, rejected}.
    Per incoming claim, in order:
      - missing source_slug / source_claim_id / text -> REJECTED (counted, visible)
      - ref already on a claim's source_claim_refs  -> NOOP (idempotent re-run)
      - same non-empty norm_key                     -> DEDUP (union backlinks/ref)
      - claim_similarity >= threshold               -> DEDUP (union backlinks/ref)
      - otherwise                                    -> NEW dcl claim
    Incoming claims are matched against the GROWING list (existing + already-added
    this run), so two incoming dupes collapse to one line. Fail-safe: an
    all-boilerplate claim (empty norm_key, 0 similarity) never matches -> kept."""
    merged = [dict(c) for c in existing]
    next_id = _next_dcl_id(merged)
    stats = {"in": 0, "new": 0, "deduped": 0, "noop": 0, "rejected": 0}

    for inc in incoming:
        src_slug = (inc.get("source_slug") or "").strip()
        cid = (inc.get("source_claim_id") or "").strip()
        text = (inc.get("text") or "").strip()
        if not src_slug or not cid or not text:
            # Malformed proposal line (e.g. the distiller emitted a claim missing
            # its provenance) — COUNT it so a systematic format drop is visible in
            # the manifest rather than masquerading as a claimless run.
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
        # Exact norm_key (skip empty keys — distinct all-boilerplate must not merge).
        if nk:
            for c in merged:
                if c.get("norm_key") and c["norm_key"] == nk:
                    match = c
                    break
        # Near: symmetric weighted-Jaccard. A score >= threshold inherently
        # requires a shared discriminative token (the "shared content token" gate).
        if match is None:
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
                "claim_id": f"dcl-{next_id:03d}",
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


# --- #345 cross-lingual candidate gate (deterministic, one source of truth) --
# The Phase-1 dedup deliberately under-merges across languages: the only DE↔EN
# bridge is the article-number digit anchor (×3.0), so a German claim and its
# English twin survive as two `distilled_claims[]` entries (the SAFE direction —
# a wrong cross-language merge silently destroys a fact). This gate flags the
# pairs an LLM is ALLOWED to judge; `crossmerge` re-checks the SAME predicate
# before unioning, so the agent can only confirm a pair the script already chose.


def _nondigit_weighted_tokens(text: str) -> set:
    """The discriminative (weight > 0) NON-digit tokens of a claim — the
    language-bearing signal. Two genuine DE↔EN twins share ~none of these (German
    vs English wording never string-matches); two different facts about the same
    article share many."""
    return {t for t in tokenize(text) if token_weight(t) > 0.0 and not t.isdigit()}


def _xlingual_candidate(a_text: str, b_text: str) -> list | None:
    """Return the sorted shared digit-anchor list if (a_text, b_text) is a
    cross-lingual merge candidate, else None. The single predicate both
    `xlingual-candidates` (generation) and `crossmerge` (server-side
    re-validation) call, so the gate is computed identically in one place.

    Candidate iff ALL hold:
      1. they share >= 1 article-number digit anchor (the DE↔EN bridge);
      2. they did NOT already auto-merge — `claim_similarity` < SIMILARITY_THRESHOLD
         (a >= match would have collapsed them in `_merge_claims` already);
      3. their non-digit discriminative tokens are near-disjoint
         (Jaccard < XLINGUAL_NONDIGIT_JACCARD_CEILING) — the precision floor that
         keeps two different facts about the same article out of the set."""
    shared = digit_anchor_tokens(a_text) & digit_anchor_tokens(b_text)
    if not shared:
        return None
    if claim_similarity(a_text, b_text) >= SIMILARITY_THRESHOLD:
        return None
    ta = _nondigit_weighted_tokens(a_text)
    tb = _nondigit_weighted_tokens(b_text)
    if ta and tb:
        union = len(ta | tb)
        if union and (len(ta & tb) / union) >= XLINGUAL_NONDIGIT_JACCARD_CEILING:
            return None
    return sorted(shared)


# --- page rendering ----------------------------------------------------------


def _render_yaml_list(key: str, items: list[str]) -> str:
    if not items:
        return f"{key}: []\n"
    out = [f"{key}:"]
    for it in items:
        out.append(f"  - {it}")
    return "\n".join(out) + "\n"


def _render_distilled_claims(claims: list[dict]) -> str:
    if not claims:
        return "distilled_claims: []\n"
    lines = ["distilled_claims:"]
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


def _machine_block(name: str, inner: str) -> str:
    return (
        f"<!-- MACHINE-OWNED:{name}:START -->\n{inner}\n"
        f"<!-- MACHINE-OWNED:{name}:END -->\n"
    )


def _render_page(
    slug: str,
    title: str,
    ptype: str,
    tags: list[str],
    created: str,
    today: str,
    sources: list[str],
    related: list[str],
    distilled_from: list[str],
    claims: list[dict],
    summary_block_inner: str,
    human_tail: str,
    wiki_root: Path,
) -> str:
    fm = ["---"]
    fm.append(f"id: {slug}")
    fm.append(f"title: {_json_scalar(title)}")
    fm.append(f"type: {ptype}")
    fm.append("tags: [" + ", ".join(tags) + "]")
    fm.append(f"created: {created}")
    fm.append(f"updated: {today}")
    fm.append(_render_yaml_list("sources", [f"wiki://{s}" for s in sources]).rstrip("\n"))
    fm.append(_render_yaml_list("related", related).rstrip("\n"))
    fm.append("status: distilled")
    fm.append(_render_yaml_list("distilled_from_research", distilled_from).rstrip("\n"))
    fm.append(_render_distilled_claims(claims).rstrip("\n"))
    fm.append("---")
    frontmatter = "\n".join(fm) + "\n"

    # Body machine blocks.
    summary = _machine_block("SUMMARY", summary_block_inner)
    claims_lines = []
    for c in claims:
        bl = " ".join(f"[[{b}]]" for b in c.get("backlinks", []))
        claims_lines.append(f"- {c.get('text', '')}" + (f" — {bl}" if bl else ""))
    claims_inner = "## Claims\n\n" + ("\n".join(claims_lines) if claims_lines else "_No claims yet._")
    # Body `## Related` emits a bare `[[<slug>]]` ONLY for a related page that
    # exists on disk — a link to a non-existent slug would be a `broken_wikilink`
    # health error, and `related:` holds slugs (frontmatter), so an unresolved one
    # is kept in frontmatter (health does not validate it) but omitted from the body.
    related_body = [r for r in related if _page_exists(wiki_root, r)]
    related_inner = "## Related\n\n" + (
        "\n".join(f"- [[{r}]]" for r in related_body) if related_body else "_No related pages yet._"
    )
    sources_inner = "## Sources\n\n" + (
        "\n".join(f"- [[{s}]]" for s in sources) if sources else "_No sources yet._"
    )
    body_machine = (
        summary
        + "\n" + _machine_block("CLAIMS", claims_inner)
        + "\n" + _machine_block("RELATED", related_inner)
        + "\n" + _machine_block("SOURCES", sources_inner)
    )

    # Normalize the gap so re-runs are byte-stable: strip leading newlines off the
    # human region (its content is fixed; only the separator varies) and re-join
    # with a single blank line. Without this the separator grows one newline per run.
    human_content = human_tail.lstrip("\n")
    tail_content = human_content if human_content.strip() else _HUMAN_NOTES_PLACEHOLDER
    return frontmatter + "\n" + f"# {title}\n\n" + body_machine.rstrip("\n") + "\n\n" + tail_content


def _dedup_keep_order(seq) -> list:
    out: list = []
    seen: set = set()
    for x in seq:
        if x and x not in seen:
            seen.add(x)
            out.append(x)
    return out


def _page_exists(wiki_root: Path, slug: str) -> bool:
    """True if `slug` already addresses a distilled page (concept / entity /
    summary / learning) on disk — checks every `_TYPE_DIRS` subdir."""
    for sub in _TYPE_DIRS.values():
        if (wiki_root / "wiki" / sub / f"{slug}.md").is_file():
            return True
    return False


def _result(slug: str, ptype: str, action: str, *, reason: str = "",
            page_path: str = "", summary: str = "", claims_total: int = 0,
            stats: dict | None = None, near_existing_slug: dict | None = None) -> dict:
    """Build a per-concept result dict with a UNIFORM key set, so every result —
    created / updated / unchanged / skipped / write_failed / exception — carries
    the same fields and no downstream reader hits a KeyError on a missing key.
    `near_existing_slug` (#340 tripwire) is `{}` everywhere except a created
    concept that crossed NEAR_TITLE_SIMILARITY_THRESHOLD."""
    stats = stats or {}
    return {
        "slug": slug, "type": ptype, "action": action, "reason": reason,
        "page_path": page_path, "summary": summary, "claims_total": claims_total,
        "claims_in": stats.get("in", 0), "claims_new": stats.get("new", 0),
        "claims_deduped": stats.get("deduped", 0), "claims_noop": stats.get("noop", 0),
        "claims_rejected": stats.get("rejected", 0),
        "near_existing_slug": near_existing_slug or {},
    }


def _claims_fingerprint(claims: list[dict]) -> list[tuple]:
    """A tuple per claim covering EVERY persisted field, for the pre-write
    round-trip self-check — so a corruption of text / norm_key / backlinks /
    refs / timestamps (not just the id set) is caught before the page ships."""
    return [(
        c.get("claim_id", ""), c.get("text", ""), c.get("norm_key", ""),
        tuple(c.get("backlinks", [])), tuple(c.get("source_claim_refs", [])),
        c.get("created", ""), c.get("updated", ""),
    ) for c in claims]


# --- #340 observable tripwire — title-index + near-match scan ---------------

_TITLE_KEY_RE = re.compile(r"^title[ \t]*:[ \t]*(.+?)[ \t]*$")


def _read_page_title(page_path: Path) -> str:
    """First frontmatter `title:` scalar, or `""` if unreadable. A missing
    title yields 0.0 similarity downstream — the page is silently excluded
    from the tripwire rather than matched against its slug."""
    try:
        text = page_path.read_text(encoding="utf-8")
    except OSError:
        return ""
    m = _FRONTMATTER_RE.match(text)
    if not m:
        return ""
    for line in m.group(1).splitlines():
        tm = _TITLE_KEY_RE.match(line)
        if tm:
            return _unquote_scalar(tm.group(1).strip())
    return ""


def _build_title_index(wiki_root: Path) -> list[tuple]:
    """Snapshot every existing distilled page as (slug, title, type) across all
    `_TYPE_DIRS` (concept/entity/summary/learning). Called once under the wiki
    lock so the view is consistent with disk."""
    out: list[tuple] = []
    for ptype, sub in _TYPE_DIRS.items():
        d = wiki_root / "wiki" / sub
        if not d.is_dir():
            continue
        for p in sorted(d.glob("*.md")):
            out.append((p.stem, _read_page_title(p), ptype))
    return out


def _find_near_existing(title: str, title_index: list[tuple]) -> dict:
    """Highest claim_similarity match >= NEAR_TITLE_SIMILARITY_THRESHOLD as
    `{slug, title, type, score}`, or `{}` when none crosses the bar."""
    if not title or not title_index:
        return {}
    best_score = 0.0
    best: tuple | None = None
    for entry in title_index:
        score = claim_similarity(title, entry[1])
        if score > best_score:
            best_score = score
            best = entry
    if best is None or best_score < NEAR_TITLE_SIMILARITY_THRESHOLD:
        return {}
    return {"slug": best[0], "title": best[1], "type": best[2],
            "score": round(best_score, 3)}


# --- merge command -----------------------------------------------------------


def _merge_one(
    record: dict,
    wiki_root: Path,
    project_slug: str,
    today: str,
    parse_frontmatter,
    is_foundation_page,
    title_index: list[tuple],
) -> dict:
    """Merge a single concept/entity proposal into its page. Returns a result
    dict (the per-slug manifest entry). Caller holds the wiki lock."""
    title = (record.get("title") or "").strip()
    ptype = (record.get("type") or "concept").strip().lower()
    if ptype not in _TYPE_DIRS:
        ptype = "concept"
    slug = slugify(title)
    if not slug:
        return _result("", ptype, "skipped", reason="empty_slug")

    page_path = wiki_root / "wiki" / _TYPE_DIRS[ptype] / f"{slug}.md"
    incoming_claims = record.get("claims", [])
    near_existing: dict = {}

    # Slug-type collision: the same slug already addresses a page in ANY OTHER
    # type dir (e.g. a `concept` slug that a prior — or same-run — `entity` /
    # `summary` / `learning` proposal already created). cogni-wiki slugs are
    # GLOBALLY unique, so refuse to write a second page at the same slug under a
    # different type. Sequential writes under the lock mean a same-run sibling is
    # already on disk here.
    for other_type, other_sub in _TYPE_DIRS.items():
        if other_type == ptype:
            continue
        if (wiki_root / "wiki" / other_sub / f"{slug}.md").is_file():
            return _result(slug, ptype, "skipped", reason="slug_type_collision")

    if page_path.is_file():
        existing_text = page_path.read_text(encoding="utf-8")
        fm = parse_frontmatter(existing_text)
        if is_foundation_page(fm):
            return _result(slug, ptype, "skipped", reason="foundation_collision")
        if "MACHINE-OWNED" not in existing_text:
            # A page at our slug we did NOT author (hand-curated / cogni-wiki).
            # Never touch it — skip rather than risk clobbering human frontmatter
            # or body. Conservative refinement of the plan's "additive frontmatter".
            return _result(slug, ptype, "skipped", reason="no_sentinels_human_page")
        existing_claims = _parse_distilled_claims(existing_text)
        created = _scalar_str(fm.get("created")) or today
        existing_updated = _scalar_str(fm.get("updated"))
        tags = _existing_tags(fm) or [ptype, "distilled"]
        existing_related = _as_list(fm.get("related"))
        existing_from = _as_list(fm.get("distilled_from_research"))
        summary_inner = _extract_machine_block(existing_text, "SUMMARY") \
            or _default_summary(record)
        human_tail = _human_tail(existing_text)
        action = "updated"
    else:
        existing_claims = []
        existing_text = None
        existing_updated = ""
        created = today
        tags = [ptype, "distilled"]
        existing_related = existing_from = []
        summary_inner = _default_summary(record)
        human_tail = ""
        action = "created"
        # #340 observable tripwire — only the `created` path can silently fork a
        # near-duplicate page; `updated` lands on an exact-slug match by definition.
        near_existing = _find_near_existing(title, title_index)

    merged_claims, stats = _merge_claims(existing_claims, incoming_claims, today)
    # `sources:` = exactly the sources whose claims are actually on the page (the
    # union of the merged claims' backlinks). Deriving it from the raw incoming
    # claims would resurrect a skipped/malformed claim's source_slug as an orphan
    # `wiki://` entry + a broken `[[slug]]` body link.
    sources = _dedup_keep_order(b for c in merged_claims for b in c.get("backlinks", []))
    # Related are slugs (the agent proposes titles → slugify here; prior-run values
    # are already slugs). Frontmatter keeps all; the body links only existing ones.
    related = _dedup_keep_order(
        list(existing_related) + [slugify(r) for r in record.get("related", [])]
    )
    distilled_from = _dedup_keep_order(list(existing_from) + [project_slug])

    def render(updated: str) -> str:
        return _render_page(
            slug=slug, title=title, ptype=ptype, tags=tags, created=created, today=updated,
            sources=sources, related=related, distilled_from=distilled_from,
            claims=merged_claims, summary_block_inner=summary_inner, human_tail=human_tail,
            wiki_root=wiki_root,
        )

    # Render first with the EXISTING `updated:` (today on create). If that is
    # byte-identical to what's on disk, nothing changed → no write, no date bump
    # (idempotency layer 3, robust to ANY field — title, related-existence, claims).
    base_updated = today if action == "created" else (existing_updated or today)
    page_text = render(base_updated)
    if existing_text is not None and page_text == existing_text:
        return _result(slug, ptype, "unchanged", page_path=str(page_path),
                       summary=(_summary_line(summary_inner) or title),
                       claims_total=len(merged_claims), stats=stats)

    # A genuine change → bump `updated:` to today (re-render only the date scalar).
    if base_updated != today:
        page_text = render(today)

    # Pre-write round-trip self-check on the FINAL text: every persisted claim
    # field (not just the id set) must parse back. Refuse to ship a page whose
    # claims would not survive the round-trip (data loss across runs is
    # unrecoverable) — never write on a miss.
    reparsed = _parse_distilled_claims(page_text)
    if _claims_fingerprint(reparsed) != _claims_fingerprint(merged_claims):
        return _result(slug, ptype, "write_failed",
                       reason="claims_round_trip_mismatch", stats=stats)

    atomic_write_text(page_path, page_text)
    return _result(slug, ptype, action, page_path=str(page_path),
                   summary=(_summary_line(summary_inner) or title),
                   claims_total=len(merged_claims), stats=stats,
                   near_existing_slug=near_existing)


def _scalar_str(v) -> str:
    return v.strip() if isinstance(v, str) else ""


def _as_list(v) -> list:
    if isinstance(v, list):
        return [str(x).strip() for x in v if str(x).strip()]
    if isinstance(v, str) and v.strip():
        return [v.strip()]
    return []


def _existing_tags(fm: dict) -> list[str]:
    t = fm.get("tags")
    if isinstance(t, list):
        return [str(x).strip() for x in t if str(x).strip()]
    return []


def _default_summary(record: dict) -> str:
    summary = (record.get("summary") or "").strip()
    return "## Summary\n\n" + (summary if summary else "_No summary yet._")


def _summary_line(summary_inner: str) -> str:
    """First non-heading prose line of a SUMMARY block — the one-liner the
    orchestrator passes to wiki_index_update.py --summary."""
    for ln in (summary_inner or "").splitlines():
        s = ln.strip()
        if s and not s.startswith("#") and s != "_No summary yet._":
            return s
    return ""


def cmd_init(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    try:
        _metadata_dir(project_path).mkdir(parents=True, exist_ok=True)
    except (FileNotFoundError, NotADirectoryError) as exc:
        return _emit(False, error=f"project_path is not a usable directory: {exc}")
    target = _manifest_path(project_path)
    if target.is_file():
        return _emit(True, data={"path": str(target), "created": False})
    atomic_write(target, _empty_manifest())
    return _emit(True, data={"path": str(target), "created": True})


def cmd_merge(args: argparse.Namespace) -> int:
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
    project_path = Path(args.project_path).resolve()
    records_path = Path(args.records).resolve()
    project_slug = args.project_slug

    try:
        records_text = records_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return _emit(False, data={"path": str(records_path)}, error="records_not_found")
    except OSError as exc:
        return _emit(False, error=f"records file is not readable: {exc}")

    records = parse_concept_records(records_text)
    today = _today()
    results: list[dict] = []

    # One lock for the whole batch: each _merge_one re-reads its page from disk,
    # so two same-run proposals colliding on a slug see each other's write.
    with _wiki_lock(wiki_root):
        # #340 tripwire snapshot — taken under the lock; same-run later proposals
        # don't see earlier same-run additions (cross-run drift is the target).
        title_index = _build_title_index(wiki_root)
        for record in records:
            try:
                results.append(_merge_one(
                    record, wiki_root, project_slug, today,
                    parse_frontmatter, is_foundation_page, title_index,
                ))
            except Exception as exc:  # noqa: BLE001 — one bad proposal must not abort the run
                results.append(_result(slugify(record.get("title", "")),
                                       (record.get("type") or "concept"),
                                       "write_failed", reason=f"exception: {exc}"))

    attached_total = sum(r["claims_new"] + r["claims_deduped"] for r in results)
    deduped_total = sum(r["claims_deduped"] for r in results)
    rejected_total = sum(r.get("claims_rejected", 0) for r in results)
    # created_slugs / updated_slugs MUST be disjoint: a slug created and then
    # re-touched in the SAME run (two proposals → one slug) is net-created, so it
    # belongs only to created_slugs. Without this it lands in both lists and the
    # orchestrator's per-slug loop double-indexes / double-bumps entries_count.
    created_slugs = _dedup_keep_order(r["slug"] for r in results if r["action"] == "created" and r["slug"])
    created_set = set(created_slugs)
    updated_slugs = [s for s in _dedup_keep_order(
        r["slug"] for r in results if r["action"] == "updated" and r["slug"]
    ) if s not in created_set]

    # #340 tripwire — aggregate the per-concept warnings (sorted by score desc to
    # match the SKILL Step-9 contract; the orchestrator prints them as-is).
    near_existing_slugs = sorted(
        (
            {"slug": r["slug"],
             "near_slug": r["near_existing_slug"].get("slug", ""),
             "near_title": r["near_existing_slug"].get("title", ""),
             "near_type": r["near_existing_slug"].get("type", ""),
             "score": r["near_existing_slug"].get("score", 0.0)}
            for r in results if r.get("near_existing_slug")
        ),
        key=lambda x: x["score"], reverse=True,
    )
    near_existing_total = len(near_existing_slugs)

    manifest = {
        "schema_version": SCHEMA_VERSION,
        "project_slug": project_slug,
        "generated_at": _dt.datetime.now(_dt.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "concepts": results,
        "claims_attached_total": attached_total,
        "claims_deduped_total": deduped_total,
        "claims_rejected_total": rejected_total,
        "near_existing_total": near_existing_total,
        "near_existing_slugs": near_existing_slugs,
    }
    # The script is the single writer of the manifest, so it also owns the
    # bundle_hash the orchestrator's resume check reads back (no fragile
    # second-process patch). Optional — absent when the caller doesn't pass it.
    if args.bundle_hash:
        manifest["bundle_hash"] = args.bundle_hash
    try:
        atomic_write(_manifest_path(project_path), manifest)
    except OSError as exc:
        return _emit(False, error=f"manifest write failed: {exc}")

    return _emit(True, data={
        "path": str(_manifest_path(project_path)),
        "concepts": results,
        "created_slugs": created_slugs,
        "updated_slugs": updated_slugs,
        "n_created": len(created_slugs),
        "n_updated": len(updated_slugs),
        "claims_attached_total": attached_total,
        "claims_deduped_total": deduped_total,
        "claims_rejected_total": rejected_total,
        "near_existing_total": near_existing_total,
        "near_existing_slugs": near_existing_slugs,
    })


def _renarrate_one(
    slug: str,
    new_prose: str,
    wiki_root: Path,
    today: str,
) -> dict:
    """Replace ONLY the SUMMARY machine block of a concept/entity page with a
    fresh narration. Caller holds the wiki lock. Returns a compact per-slug
    result `{slug, action, reason, page_path}` (action ∈ renarrated / unchanged /
    skipped)."""
    # Resolve the page across both type dirs (the slug is globally unique).
    page_path = None
    for sub in _TYPE_DIRS.values():
        cand = wiki_root / "wiki" / sub / f"{slug}.md"
        if cand.is_file():
            page_path = cand
            break
    if page_path is None:
        return {"slug": slug, "action": "skipped", "reason": "page_not_found", "page_path": ""}

    text = page_path.read_text(encoding="utf-8")
    old_inner = _extract_machine_block(text, "SUMMARY")
    if old_inner is None:
        # No machine-owned SUMMARY block — a hand-authored / foundation page we
        # must never touch (same conservative guard as `_merge_one`).
        return {"slug": slug, "action": "skipped", "reason": "no_summary_sentinel",
                "page_path": str(page_path)}

    # Canonical inner shape mirrors `_default_summary`: a `## Summary` heading,
    # a blank line, then the prose. The narrator emits prose only — the heading +
    # sentinels are the script's to own.
    new_inner = "## Summary\n\n" + new_prose.strip("\n")
    if new_inner == old_inner:
        return {"slug": slug, "action": "unchanged", "reason": "", "page_path": str(page_path)}

    updated = _replace_machine_block(text, "SUMMARY", new_inner)
    if updated == text:  # defensive — sub matched nothing
        return {"slug": slug, "action": "skipped", "reason": "summary_replace_noop",
                "page_path": str(page_path)}
    # Bump the frontmatter `updated:` to today (a genuine content change).
    updated = _FM_UPDATED_RE.sub(f"updated: {today}", updated, count=1)
    atomic_write_text(page_path, updated)
    return {"slug": slug, "action": "renarrated", "reason": "", "page_path": str(page_path)}


def cmd_renarrate(args: argparse.Namespace) -> int:
    """Re-narrate the `## Summary` block of already-merged concept/entity pages
    from the concept-summary-narrator's raw-text records (#341). Summary-only:
    every other machine block + the human `## Notes` tail stay byte-identical;
    the page write runs under cogni-wiki's `_wiki_lock`, same as `merge`."""
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock  # noqa: E402
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

    proposals = parse_renarrate_records(records_text)
    today = _today()
    renarrated: list[str] = []
    unchanged: list[str] = []
    skipped: list[dict] = []

    with _wiki_lock(wiki_root):
        for slug, prose in proposals.items():
            try:
                res = _renarrate_one(slug, prose, wiki_root, today)
            except Exception as exc:  # noqa: BLE001 — one bad page must not abort the batch
                skipped.append({"slug": slug, "reason": f"exception: {exc}"})
                continue
            if res["action"] == "renarrated":
                renarrated.append(res["slug"])
            elif res["action"] == "unchanged":
                unchanged.append(res["slug"])
            else:
                skipped.append({"slug": res["slug"], "reason": res["reason"]})

    return _emit(True, data={
        "renarrated": renarrated,
        "unchanged": unchanged,
        "skipped": skipped,
        "n_renarrated": len(renarrated),
        "n_unchanged": len(unchanged),
        "n_skipped": len(skipped),
    })


# --- #345 cross-lingual candidate generation + crossmerge --------------------


def _resolve_distilled_page(wiki_root: Path, slug: str):
    """Resolve a distilled slug to `(page_path, ptype)` across the four type
    dirs (slugs are globally unique), or `(None, None)` if absent."""
    for ptype, sub in _TYPE_DIRS.items():
        cand = wiki_root / "wiki" / sub / f"{slug}.md"
        if cand.is_file():
            return cand, ptype
    return None, None


def cmd_xlingual_candidates(args: argparse.Namespace) -> int:
    """Emit the cross-lingual (DE↔EN) merge candidate pairs across the run's
    touched pages (#345). Read-only — the LLM may only confirm a pair flagged
    here. Held under the wiki lock so the scan is consistent with concurrent
    ingest/merge writes (same posture as `merge`/`renarrate`)."""
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock  # noqa: E402
    except ImportError as exc:
        return _emit(False, error=f"could not import cogni-wiki _wikilib from {wiki_scripts}: {exc}")

    wiki_root = Path(args.wiki_root).resolve()
    if not (wiki_root / "wiki").is_dir():
        return _emit(False, error=f"wiki_root has no wiki/ dir: {wiki_root}")
    slugs = _dedup_keep_order(s.strip() for s in (args.slugs or "").split(",") if s.strip())

    candidates: list[dict] = []
    with _wiki_lock(wiki_root):
        for slug in slugs:
            page_path, _ = _resolve_distilled_page(wiki_root, slug)
            if page_path is None:
                continue
            claims = _parse_distilled_claims(page_path.read_text(encoding="utf-8"))
            for i in range(len(claims)):
                for j in range(i + 1, len(claims)):
                    a, b = claims[i], claims[j]
                    shared = _xlingual_candidate(a.get("text", ""), b.get("text", ""))
                    if shared is None:
                        continue
                    candidates.append({
                        "slug": slug,
                        "a_id": a.get("claim_id", ""), "a_text": a.get("text", ""),
                        "b_id": b.get("claim_id", ""), "b_text": b.get("text", ""),
                        "shared_anchors": shared,
                    })

    return _emit(True, data={"candidates": candidates, "n_candidates": len(candidates)})


def _crossmerge_one(record: dict, wiki_root: Path, today: str, parse_frontmatter) -> dict:
    """Apply one confirmed cross-lingual union under the lock. UNION-only: the
    absorbed claim's backlinks + source_claim_refs fold onto the survivor, and the
    absorbed dcl entry is removed — NO provenance is ever dropped. Re-validates the
    candidate gate server-side, so the LLM can never widen scope. Returns a compact
    per-record result `{slug, action, reason, survivor_id, absorbed_id}` (action ∈
    merged / skipped / write_failed)."""
    slug = (record.get("slug") or "").strip()
    survivor_id = (record.get("survivor_id") or "").strip()
    absorbed_id = (record.get("absorbed_id") or "").strip()
    res = {"slug": slug, "action": "skipped", "reason": "", "page_path": "",
           "survivor_id": survivor_id, "absorbed_id": absorbed_id}

    page_path, ptype = _resolve_distilled_page(wiki_root, slug)
    if page_path is None:
        res["reason"] = "page_not_found"
        return res
    res["page_path"] = str(page_path)
    text = page_path.read_text(encoding="utf-8")
    if "MACHINE-OWNED" not in text:
        # A page we did NOT author — never touch it (same guard as _merge_one).
        res["reason"] = "no_sentinels_human_page"
        return res

    claims = _parse_distilled_claims(text)
    by_id = {c.get("claim_id"): c for c in claims}
    if survivor_id == absorbed_id or survivor_id not in by_id or absorbed_id not in by_id:
        res["reason"] = "claim_not_found"
        return res
    surv, absb = by_id[survivor_id], by_id[absorbed_id]

    # Server-side re-validation — the load-bearing fail-safe. The records file is
    # LLM-authored; if the pair no longer satisfies the deterministic candidate
    # gate, refuse the union rather than trust the agent to have stayed in scope.
    if _xlingual_candidate(surv.get("text", ""), absb.get("text", "")) is None:
        res["reason"] = "not_a_candidate"
        return res

    # UNION absorbed → survivor. Order-preserving dedup; never drop a ref/backlink.
    for b in absb.get("backlinks", []):
        if b not in surv.setdefault("backlinks", []):
            surv["backlinks"].append(b)
    for r in absb.get("source_claim_refs", []):
        if r not in surv.setdefault("source_claim_refs", []):
            surv["source_claim_refs"].append(r)
    surv["updated"] = today
    merged_claims = [c for c in claims if c.get("claim_id") != absorbed_id]

    # Re-render from the existing page's frontmatter + body (same reconstruction
    # `_merge_one`'s update path uses), swapping in the post-union claim list.
    fm = parse_frontmatter(text)
    title = _read_page_title(page_path) or slug
    created = _scalar_str(fm.get("created")) or today
    tags = _existing_tags(fm) or [ptype, "distilled"]
    related = _as_list(fm.get("related"))
    distilled_from = _as_list(fm.get("distilled_from_research"))
    summary_inner = _extract_machine_block(text, "SUMMARY") or _default_summary(record)
    human_tail = _human_tail(text)
    sources = _dedup_keep_order(b for c in merged_claims for b in c.get("backlinks", []))

    page_text = _render_page(
        slug=slug, title=title, ptype=ptype, tags=tags, created=created, today=today,
        sources=sources, related=related, distilled_from=distilled_from,
        claims=merged_claims, summary_block_inner=summary_inner, human_tail=human_tail,
        wiki_root=wiki_root,
    )

    reparsed = _parse_distilled_claims(page_text)
    if _claims_fingerprint(reparsed) != _claims_fingerprint(merged_claims):
        res["action"] = "write_failed"
        res["reason"] = "claims_round_trip_mismatch"
        return res

    atomic_write_text(page_path, page_text)
    res["action"] = "merged"
    return res


def cmd_crossmerge(args: argparse.Namespace) -> int:
    """Apply the cross-lingual-claim-merger's confirmed unions (#345). Under the
    SAME `_wiki_lock` as `merge`, UNIONs each twin's provenance onto its survivor
    claim — re-validating the candidate gate server-side so the LLM can never
    widen scope, and never dropping a source_claim_ref or backlink."""
    wiki_scripts = Path(args.wiki_scripts_dir).resolve()
    if not wiki_scripts.is_dir():
        return _emit(False, error=f"--wiki-scripts-dir does not exist: {wiki_scripts}")
    sys.path.insert(0, str(wiki_scripts))
    try:
        from _wikilib import _wiki_lock, parse_frontmatter  # noqa: E402
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

    records = parse_crossmerge_records(records_text)
    today = _today()
    merged: list[dict] = []
    skipped: list[dict] = []

    with _wiki_lock(wiki_root):
        for record in records:
            try:
                res = _crossmerge_one(record, wiki_root, today, parse_frontmatter)
            except Exception as exc:  # noqa: BLE001 — one bad record must not abort the batch
                skipped.append({"slug": record.get("slug", ""), "reason": f"exception: {exc}"})
                continue
            if res["action"] == "merged":
                merged.append({"slug": res["slug"], "survivor_id": res["survivor_id"],
                               "absorbed_id": res["absorbed_id"]})
            else:
                skipped.append({"slug": res["slug"], "reason": res["reason"]})

    merged_slugs = _dedup_keep_order(m["slug"] for m in merged)
    return _emit(True, data={
        "merged": merged,
        "merged_slugs": merged_slugs,
        "skipped": skipped,
        "n_merged": len(merged),
        "n_skipped": len(skipped),
        "claims_crossmerged_total": len(merged),
    })


def cmd_read(args: argparse.Namespace) -> int:
    project_path = Path(args.project_path).resolve()
    target = _manifest_path(project_path)
    if not target.is_file():
        return _emit(False, data={"path": str(target)}, error="distill-manifest.json does not exist")
    try:
        payload = json.loads(target.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return _emit(False, error=f"distill-manifest.json is not valid JSON: {exc}")
    return _emit(True, data=payload)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Locked create-or-merge engine for distilled pages — concept/entity/summary/learning (Phase 4.5).",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_init = sub.add_parser("init", help="Create an empty distill-manifest.json (idempotent)")
    p_init.add_argument("--project-path", required=True)
    p_init.set_defaults(func=cmd_init)

    p_merge = sub.add_parser("merge", help="Merge the distiller's records into concept/entity pages under the lock")
    p_merge.add_argument("--records", required=True, help="Path to the concept-distiller's raw-text records file")
    p_merge.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_merge.add_argument("--project-path", required=True, help="Absolute path to the project directory")
    p_merge.add_argument("--project-slug", required=True, help="Research project slug (for distilled_from_research)")
    p_merge.add_argument("--wiki-scripts-dir", required=True,
                         help="Path to cogni-wiki wiki-ingest/scripts (for _wiki_lock / is_foundation_page / parse_frontmatter)")
    p_merge.add_argument("--bundle-hash", default="",
                         help="Stable sha256 of the source-claim bundle; written into the manifest for the orchestrator's resume no-op check")
    p_merge.set_defaults(func=cmd_merge)

    p_renarrate = sub.add_parser(
        "renarrate",
        help="Re-narrate the ## Summary block of merged concept/entity pages from the narrator's records (#341)",
    )
    p_renarrate.add_argument("--records", required=True,
                             help="Path to the concept-summary-narrator's raw-text records file")
    p_renarrate.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_renarrate.add_argument("--project-path", required=False, default="",
                             help="Absolute path to the project directory (accepted for call-site symmetry; unused)")
    p_renarrate.add_argument("--project-slug", required=False, default="",
                             help="Research project slug (accepted for call-site symmetry; unused)")
    p_renarrate.add_argument("--wiki-scripts-dir", required=True,
                             help="Path to cogni-wiki wiki-ingest/scripts (for _wiki_lock)")
    p_renarrate.set_defaults(func=cmd_renarrate)

    p_xlc = sub.add_parser(
        "xlingual-candidates",
        help="Emit cross-lingual (DE↔EN) merge candidate pairs across the run's touched pages (#345)",
    )
    p_xlc.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_xlc.add_argument("--slugs", required=True,
                       help="Comma-separated distilled slugs to scan (the run's created+updated slugs)")
    p_xlc.add_argument("--wiki-scripts-dir", required=True,
                       help="Path to cogni-wiki wiki-ingest/scripts (for _wiki_lock)")
    p_xlc.set_defaults(func=cmd_xlingual_candidates)

    p_xm = sub.add_parser(
        "crossmerge",
        help="Apply the cross-lingual-claim-merger's confirmed unions under the lock (#345)",
    )
    p_xm.add_argument("--records", required=True,
                      help="Path to the cross-lingual-claim-merger's raw-text records file")
    p_xm.add_argument("--wiki-root", required=True, help="Absolute path to the bound wiki root")
    p_xm.add_argument("--project-path", required=False, default="",
                      help="Absolute path to the project directory (accepted for call-site symmetry; unused)")
    p_xm.add_argument("--project-slug", required=False, default="",
                      help="Research project slug (accepted for call-site symmetry; unused)")
    p_xm.add_argument("--wiki-scripts-dir", required=True,
                      help="Path to cogni-wiki wiki-ingest/scripts (for _wiki_lock / parse_frontmatter)")
    p_xm.set_defaults(func=cmd_crossmerge)

    p_read = sub.add_parser("read", help="Emit distill-manifest.json content")
    p_read.add_argument("--project-path", required=True)
    p_read.set_defaults(func=cmd_read)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

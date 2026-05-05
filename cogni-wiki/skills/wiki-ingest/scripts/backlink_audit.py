#!/usr/bin/env python3
"""
backlink_audit.py — find candidate backlinks for a newly ingested wiki page,
and (optionally) apply a curated plan of backlink writes atomically.

Two modes, sharing one script so the audit + write cycle stays a single
skill-invocation unit:

    Audit mode (default)
        backlink_audit.py --wiki-root <path> --new-page <slug>

        Scans existing pages for textual references that could justify a
        `[[new-page]]` backlink. Returns a ranked candidate list. No writes.

    Apply mode
        backlink_audit.py --wiki-root <path> --new-page <slug> \\
                          --apply-plan <path-or-dash>

        Reads a curated plan JSON and, for each target, inserts the caller's
        backlink sentence and bumps the target page's `updated:` frontmatter
        field to today — as a single atomic write per page. The plan is
        authored by the orchestrator after reviewing the audit's candidates;
        the script never auto-selects targets, preserving the
        "never invent backlinks" discipline from SKILL.md.

Output contract (audit mode):
    {
      "success": true,
      "data": {
        "candidates": [...],
        "search_terms": [...],
        "total_pages_scanned": <int>
      },
      "error": ""
    }

Output contract (apply mode) — extends audit output with write-result fields:
    {
      "success": true,
      "data": {
        "candidates": [...],
        "search_terms": [...],
        "total_pages_scanned": <int>,
        "applied": [ {"slug": "...", "updated": "YYYY-MM-DD"}, ... ],
        "skipped_existing_backlink": ["slug", ...],
        "failed": [ {"slug": "...", "error": "..."}, ... ]
      },
      "error": ""
    }

Candidate object:
    {
      "page": "<slug>",
      "matched_terms": ["term1", "term2"],
      "matched_score": 1.73,            # IDF-weighted sum of matched terms
      "confidence": "low" | "medium" | "high",
      "existing_backlink": true | false,
      "rule_id": "R1_bidirectional_wikilink"  # SCHEMA.md forward→reverse rule
    }

Rule IDs map every candidate to a row in the wiki's SCHEMA.md "Forward → reverse
link contract" table. Today every audit candidate is `R1_bidirectional_wikilink`
(forward `[[B]]` from A implies reverse `[[A]]` in B). Future per-type rules
(e.g. `R4_paper_concept_keypaper`) will set different ids without changing this
script's interface.

Plan schema (consumed by --apply-plan):
    {
      "targets": [
        {
          "slug": "target-page-slug",         # required; must exist under wiki/pages/
          "sentence": "... [[new-page]] ...", # required; MUST contain [[new-slug]]
          "insert_after_heading": "## Foo"    # optional; exact heading line to insert after
        },
        ...
      ]
    }

    If `insert_after_heading` is present and matches a heading line in the target
    page body, the sentence is inserted as the first paragraph under that heading.
    If absent (or the heading is not found), the sentence is appended at the end
    of the body. In every case the frontmatter `updated:` field is rewritten to
    today's ISO date in the same atomic write.

Flags:
    --top <K>             Audit mode: compact output — keep only the top K
                          candidates AND add summary counters (total_candidates,
                          by_confidence). Preferred for bulk-rebuild callers
                          that want a lean payload. Use --verbose to also
                          include the full candidate list.
    --verbose             Audit mode: when paired with --top, emit the full
                          candidate list alongside the summary counters. Useful
                          for debugging an auto-backlinks run.
    --top-n <N>           Audit mode: legacy pre-filter — keep only the top N
                          candidates with no summary counters. New callers
                          should prefer --top.
    --min-confidence X    Audit mode: drop candidates below X (low|medium|high).
    --apply-plan <path>   Apply mode: path to plan JSON, or `-` for stdin.

Summary counters (only emitted when --top is set):
    total_candidates: <int>
        Count of candidates that passed --min-confidence, *before* the --top
        truncation. Lets the caller see how many were dropped by the cap.
    by_confidence: {"high": <int>, "medium": <int>, "low": <int>}
        Distribution across the full matched-candidate corpus (pre
        --min-confidence, pre --top). Shows the shape the caller would have
        seen at the relaxed setting.

Ranking is stable: candidates are sorted by confidence bucket (high > medium >
low), then by matched_score descending, then by page slug alphabetically. Terms
derived from the page title always have weight 1.0; tag-derived terms are
weighted by inverse document frequency across wiki/pages/ so common tags like
`agent` (present on most pages) contribute near-zero signal while rare tags
like `claim-verification` dominate the score.

stdlib-only. Python 3.8+.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import fcntl
import json
import os
import re
import sys
import tempfile
from contextlib import contextmanager
from pathlib import Path


@contextmanager
def _wiki_lock(wiki_root: Path):
    """Serialise shared-state writes across concurrent batch-mode workers.

    Issue #84: two batch-mode workers can both apply-plan into the same target
    page (e.g., the popular `plugin-cogni-*` pages), each read-modify-writing
    without knowing about the other. The later `os.replace` silently
    overwrites the earlier backlink insert. This lock serialises apply_plan
    across workers sharing a wiki root; separate wikis do not block each other.
    """
    lock_dir = wiki_root / ".cogni-wiki"
    lock_dir.mkdir(parents=True, exist_ok=True)
    lock_path = lock_dir / ".lock"
    fd = os.open(str(lock_path), os.O_CREAT | os.O_RDWR, 0o644)
    try:
        fcntl.flock(fd, fcntl.LOCK_EX)
        yield
    finally:
        try:
            fcntl.flock(fd, fcntl.LOCK_UN)
        finally:
            os.close(fd)


FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)
WIKILINK_RE = re.compile(r"\[\[([a-z0-9][a-z0-9\-]*)\]\]")
UPDATED_FIELD_RE = re.compile(r"^(updated:\s*).*$", re.MULTILINE)


def fail(msg: str) -> None:
    print(json.dumps({"success": False, "data": {}, "error": msg}))
    sys.exit(1)


def ok(data: dict) -> None:
    print(json.dumps({"success": True, "data": data, "error": ""}))
    sys.exit(0)


def parse_frontmatter(text: str) -> dict:
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}
    out: dict = {}
    current_key = None
    for line in m.group(1).splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and current_key:
            out.setdefault(current_key, []).append(line[4:].strip())
            continue
        if ":" in line:
            k, _, v = line.partition(":")
            k = k.strip()
            v = v.strip()
            current_key = k
            if v.startswith("[") and v.endswith("]"):
                out[k] = [x.strip() for x in v[1:-1].split(",") if x.strip()]
            elif v:
                out[k] = v
            else:
                out[k] = []
    return out


def extract_terms(page_text: str, fm: dict) -> tuple:
    """Build title-derived and tag-derived search term sets from a page.

    Returns (title_terms, tag_terms) so callers can weight them independently:
    title terms are inherently specific; tag terms need IDF weighting because
    common tags like `agent` blow up false-positive candidate counts.
    """
    title_terms: set = set()
    title = fm.get("title", "")
    if isinstance(title, str) and title:
        title_terms.add(title.strip().lower())
        for word in re.findall(r"[a-zA-Z][a-zA-Z0-9\-]{3,}", title):
            title_terms.add(word.lower())
    tag_terms: set = set()
    tags = fm.get("tags", [])
    if isinstance(tags, list):
        for t in tags:
            if isinstance(t, str):
                tag_terms.add(t.strip().lower())
    title_terms = {t for t in title_terms if len(t) >= 4}
    tag_terms = {t for t in tag_terms if len(t) >= 4}
    return title_terms, tag_terms


def compute_tag_document_frequency(pages_dir: Path) -> tuple:
    """Scan all wiki pages to count how many pages carry each tag.

    Returns (tag_df, total_pages). Callers turn this into an inverse-document-
    frequency weight: weight(tag) = 1 - (tag_df[tag] / total_pages), clamped to
    a small floor so a tag present on literally every page still contributes a
    sliver of signal (otherwise the algorithm loses its ability to fall back
    on tag matches when the title has no hits).
    """
    tag_df: dict = {}
    total = 0
    for page in pages_dir.glob("*.md"):
        if page.name.startswith("lint-"):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        fm = parse_frontmatter(text)
        _title, tags = extract_terms(text, fm)
        if not tags:
            # Tagless pages are intentionally counted toward total_pages to
            # reflect true corpus size; this keeps the IDF denominator honest
            # so rare tags don't get artificially inflated weights.
            total += 1
            continue
        total += 1
        for tag in tags:
            tag_df[tag] = tag_df.get(tag, 0) + 1
    return tag_df, total


def tag_weight(tag: str, tag_df: dict, total_pages: int) -> float:
    """Return the IDF-style weight for a tag: rare tags score high, common low."""
    if total_pages <= 0:
        return 0.5
    df = tag_df.get(tag, 0)
    # Clamp to [0.05, 1.0] — a tag on every page still contributes a sliver so
    # pure-tag matches aren't silently dropped to zero score.
    raw = 1.0 - (df / total_pages)
    return max(0.05, min(1.0, raw))


def score_match(matched_score: float, match_count: int, body_len: int) -> str:
    """Bucket the weighted score into confidence tiers.

    The thresholds are chosen empirically against the pilot: a single title-
    derived term hit (weight 1.0) on a page longer than 200 chars is `medium`;
    two title hits, or one title hit plus high-weight tag hits summing past
    1.5, is `high`; everything else (thin tag-only matches) is `low`.
    """
    if matched_score >= 1.5 or match_count >= 3:
        return "high"
    if matched_score >= 0.9 or match_count == 2:
        return "medium"
    if match_count >= 1 and body_len > 200:
        return "low"
    return "low"


def _load_apply_plan(path: str) -> dict:
    """Load the apply-plan JSON. `-` reads from stdin."""
    if path == "-":
        raw = sys.stdin.read()
    else:
        plan_path = Path(path).expanduser().resolve()
        if not plan_path.is_file():
            fail(f"apply plan not found: {plan_path}")
        raw = plan_path.read_text(encoding="utf-8")
    try:
        plan = json.loads(raw)
    except json.JSONDecodeError as e:
        fail(f"apply plan is not valid JSON: {e}")
        return {}
    if not isinstance(plan, dict) or not isinstance(plan.get("targets"), list):
        fail("apply plan must be an object with a 'targets' list")
    return plan


def _validate_target(target: dict, new_slug: str) -> str:
    """Return an error string on invalid target, empty string on valid."""
    if not isinstance(target, dict):
        return "target is not an object"
    slug = target.get("slug")
    if not isinstance(slug, str) or not slug.strip():
        return "target missing 'slug'"
    sentence = target.get("sentence")
    if not isinstance(sentence, str) or not sentence.strip():
        return f"target {slug!r} missing 'sentence'"
    wikilink = f"[[{new_slug}]]"
    if wikilink not in sentence:
        return f"target {slug!r} sentence does not contain {wikilink}"
    heading = target.get("insert_after_heading")
    # Absence (None) or empty string is fine — both mean "append at end of body".
    # Only reject truly non-string values (numbers, lists, objects).
    if heading is not None and not isinstance(heading, str):
        return f"target {slug!r} has a non-string 'insert_after_heading'"
    return ""


def _bump_updated_frontmatter(text: str, today: str) -> str:
    """Rewrite the frontmatter `updated:` field to today's date.

    Only touches the first frontmatter block. Preserves surrounding content
    byte-for-byte. If no frontmatter or no `updated:` field is present, returns
    the text unchanged — an atomic write still happens, just without the bump.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return text
    fm_block = m.group(0)
    # Use a lambda substitution so we don't hit Python's \1 + "2026..." ambiguity
    # where the leading digit gets parsed into the backreference (\12 would mean
    # group 12) and corrupts the output.
    new_fm, count = UPDATED_FIELD_RE.subn(
        lambda mm: mm.group(1) + today, fm_block, count=1
    )
    if count == 0:
        return text
    return new_fm + text[len(fm_block):]


def _split_frontmatter_body(text: str) -> tuple:
    """Return (frontmatter_including_trailing_newline, body)."""
    m = FRONTMATTER_RE.match(text)
    if not m:
        return "", text
    return m.group(0), text[len(m.group(0)):]


def _insert_sentence(body: str, sentence: str, heading: str) -> str:
    """Insert `sentence` at the right place in `body`.

    If `heading` is truthy and matches a line exactly, insert `sentence` as a
    new paragraph immediately after that heading (with a blank-line separator).
    Otherwise append at the end of the body, preceded by a blank line.
    """
    stripped_sentence = sentence.strip()
    if heading:
        heading_line = heading.rstrip("\n")
        # Split lines but keep track so we can rebuild faithfully.
        lines = body.split("\n")
        for i, line in enumerate(lines):
            if line.rstrip() == heading_line:
                # Insert a blank line then the sentence after the heading.
                # If the next line is already blank, keep it; then drop our
                # own separator so we don't produce three-blank-lines.
                rest_start = i + 1
                insert_lines = ["", stripped_sentence, ""]
                new_lines = lines[:rest_start] + insert_lines + lines[rest_start:]
                return "\n".join(new_lines)
    if not body.endswith("\n"):
        body = body + "\n"
    return body + "\n" + stripped_sentence + "\n"


def _atomic_write(path: Path, content: str) -> None:
    """Write `content` to `path` atomically (write to temp file then os.replace)."""
    parent = path.parent
    fd, tmp = tempfile.mkstemp(prefix=".backlink-", dir=str(parent))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
        os.replace(tmp, path)
    except Exception:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def apply_plan(plan: dict, pages_dir: Path, new_slug: str) -> tuple:
    """Execute an apply-plan over `pages_dir`.

    Returns (applied, skipped_existing, failed) lists for the output JSON.
    Each list entry is a small dict the caller embeds under data.*.

    Semantics:
      - If `[[new_slug]]` already appears in the target body, skip the write
        entirely (no sentence insert, no `updated:` bump). This keeps re-runs
        idempotent so the orchestrator can safely re-apply a plan after fixing
        a typo in one target.
      - Otherwise, perform one atomic write that both inserts the sentence and
        rewrites `updated:` to today.
      - Any per-target failure is captured in `failed[]` without aborting the
        whole run — partial success is better than no success at scale.
    """
    today = _dt.date.today().isoformat()
    applied: list = []
    skipped: list = []
    failed: list = []
    wikilink_marker = f"[[{new_slug}]]"

    for target in plan.get("targets", []):
        err = _validate_target(target, new_slug)
        slug = target.get("slug") if isinstance(target, dict) else None
        if err:
            failed.append({"slug": slug, "error": err})
            continue
        target_path = pages_dir / f"{slug}.md"
        if not target_path.is_file():
            failed.append({"slug": slug, "error": f"target page not found: {target_path.name}"})
            continue
        try:
            text = target_path.read_text(encoding="utf-8")
        except OSError as e:
            failed.append({"slug": slug, "error": f"could not read target: {e}"})
            continue
        if wikilink_marker in text:
            skipped.append(slug)
            continue
        fm, body = _split_frontmatter_body(text)
        new_body = _insert_sentence(body, target["sentence"], target.get("insert_after_heading", ""))
        # Bump `updated:` in the frontmatter block only, so we don't touch any
        # other `updated:` string that might appear in the body.
        new_fm = _bump_updated_frontmatter(fm, today) if fm else fm
        new_text = new_fm + new_body
        try:
            _atomic_write(target_path, new_text)
        except OSError as e:
            failed.append({"slug": slug, "error": f"atomic write failed: {e}"})
            continue
        applied.append({"slug": slug, "updated": today})

    return applied, skipped, failed


def main() -> None:
    parser = argparse.ArgumentParser(description="Find candidate backlinks for a new wiki page")
    parser.add_argument("--wiki-root", required=True, help="Absolute path to the wiki root")
    parser.add_argument("--new-page", required=True, help="Slug of the newly ingested page")
    parser.add_argument("--top", type=int, default=0, dest="top",
                        help="After ranking, keep only the top K candidates AND emit summary "
                             "counters (total_candidates, by_confidence). 0 = disabled. "
                             "Preferred for bulk-rebuild callers; use --verbose to include the "
                             "full candidate list alongside the counters.")
    parser.add_argument("--verbose", action="store_true",
                        help="With --top: keep the full candidate list in output alongside the "
                             "summary counters. No effect without --top.")
    parser.add_argument("--top-n", type=int, default=0,
                        help="Legacy: keep only the top N candidates, no summary counters "
                             "(0 = no limit). New callers should prefer --top.")
    parser.add_argument("--min-confidence", choices=["low", "medium", "high"],
                        default="low",
                        help="Drop candidates below this confidence tier")
    parser.add_argument("--apply-plan", default=None,
                        help="Path to a plan JSON (or '-' for stdin). When set, apply the "
                             "plan's backlink writes atomically after running the audit.")
    args = parser.parse_args()

    wiki_root = Path(args.wiki_root).expanduser().resolve()
    pages_dir = wiki_root / "wiki" / "pages"
    new_slug = args.new_page.strip().lower()

    if not pages_dir.is_dir():
        fail(f"wiki/pages/ not found under {wiki_root}")

    new_page_path = pages_dir / f"{new_slug}.md"
    if not new_page_path.is_file():
        fail(f"new page not found: {new_page_path}")

    try:
        new_text = new_page_path.read_text(encoding="utf-8")
    except OSError as e:
        fail(f"could not read new page: {e}")
        return

    new_fm = parse_frontmatter(new_text)
    title_terms, tag_terms = extract_terms(new_text, new_fm)
    if not title_terms and not tag_terms:
        out_empty = {"candidates": [], "note": "new page has no extractable search terms"}
        if args.apply_plan:
            plan = _load_apply_plan(args.apply_plan)
            with _wiki_lock(wiki_root):
                applied, skipped, failed = apply_plan(plan, pages_dir, new_slug)
            out_empty["applied"] = applied
            out_empty["skipped_existing_backlink"] = skipped
            out_empty["failed"] = failed
        ok(out_empty)

    # Always include the slug itself and the title lowercased as title-weighted terms.
    title_terms.add(new_slug)
    title_terms.add(new_slug.replace("-", " "))

    # Compute tag-IDF once across the whole wiki so common tags like `agent`
    # contribute near-zero weight and rare tags like `claim-verification` dominate.
    tag_df, total_pages = compute_tag_document_frequency(pages_dir)

    # Any term that also appears as a tag in the corpus gets IDF-weighted —
    # even if it came from the title. This catches the failure mode where a
    # title word like "agent" in "Claim Verifier Agent" would otherwise get
    # weight 1.0 and drown out the rare tag matches that actually matter.
    term_weights: dict = {}
    for t in title_terms | tag_terms:
        if t in tag_df:
            term_weights[t] = tag_weight(t, tag_df, total_pages)
        else:
            term_weights[t] = 1.0

    candidates = []
    for page in sorted(pages_dir.glob("*.md")):
        if page.name == f"{new_slug}.md":
            continue
        if page.name.startswith("lint-"):
            continue
        try:
            text = page.read_text(encoding="utf-8")
        except OSError:
            continue
        body_lower = text.lower()
        body_len = len(text)
        matched = sorted({term for term in term_weights if term in body_lower})
        if not matched:
            continue
        matched_score = sum(term_weights[term] for term in matched)
        existing_backlink = f"[[{new_slug}]]" in body_lower
        candidates.append(
            {
                "page": page.stem,
                "matched_terms": matched,
                "matched_score": round(matched_score, 3),
                "confidence": score_match(matched_score, len(matched), body_len),
                "existing_backlink": existing_backlink,
                "rule_id": "R1_bidirectional_wikilink",
            }
        )

    # Rank by confidence bucket, then by weighted score (desc), then by slug.
    order = {"high": 0, "medium": 1, "low": 2}
    candidates.sort(
        key=lambda c: (order[c["confidence"]], -c["matched_score"], c["page"])
    )

    # Snapshot the full-corpus distribution *before* --min-confidence and --top
    # prune it. This is what we emit as `by_confidence` so the caller sees the
    # shape they'd get at the relaxed setting.
    by_confidence_pre_filter = {"high": 0, "medium": 0, "low": 0}
    for c in candidates:
        by_confidence_pre_filter[c["confidence"]] += 1

    # Apply --min-confidence filter, then --top / --top-n cap.
    if args.min_confidence != "low":
        cutoff = order[args.min_confidence]
        candidates = [c for c in candidates if order[c["confidence"]] <= cutoff]

    # `total_candidates` reflects the post-filter, pre-truncation count — i.e.
    # "how many would you have seen without --top/--top-n?".
    total_after_filter = len(candidates)

    # --top wins over --top-n when both are set; they're redundant by design.
    top_k = args.top if args.top > 0 else args.top_n
    if top_k > 0:
        candidates_truncated = candidates[:top_k]
    else:
        candidates_truncated = candidates

    # In compact mode (--top set, no --verbose), emit only the top-K plus
    # summary counters. In verbose mode, emit the full post-filter list AND
    # the summary counters. Without --top, legacy behaviour (no counters).
    if args.top > 0 and args.verbose:
        emitted_candidates = candidates
    else:
        emitted_candidates = candidates_truncated

    out = {
        "candidates": emitted_candidates,
        "search_terms": sorted(term_weights.keys()),
        "total_pages_scanned": total_pages,
    }
    if args.top > 0:
        out["total_candidates"] = total_after_filter
        out["by_confidence"] = by_confidence_pre_filter

    if args.apply_plan:
        plan = _load_apply_plan(args.apply_plan)
        with _wiki_lock(wiki_root):
            applied, skipped, failed = apply_plan(plan, pages_dir, new_slug)
        out["applied"] = applied
        out["skipped_existing_backlink"] = skipped
        out["failed"] = failed

    ok(out)


if __name__ == "__main__":
    main()

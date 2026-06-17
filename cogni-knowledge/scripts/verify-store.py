#!/usr/bin/env python3
"""
verify-store.py — shard a citation manifest for parallel verification and
merge the per-shard `wiki-verifier` fragments back into the canonical
`verify-vN.json`.

The Phase 6 (`knowledge-verify`) skill verifies citations in parallel: each
citation's verdict is independent (one cited page's claims vs one
`draft_sentence`), so verification is embarrassingly parallel. This script
is the fan-out plumbing — the LLM judgment stays in the `wiki-verifier`
agent; this script only partitions and recombines.

  shard     Split a citation-manifest's `citations[]` into ⌈len/size⌉ shard
            files under `verify-shards/`, each a valid citation-manifest
            scoped to a subset. Returns a dispatch plan (one row per shard:
            the manifest path to hand the verifier as CITATIONS_PATH and the
            fragment path to hand it as VERIFY_OUT_PATH). `--only-ids` restricts
            the split to a subset (the incremental re-verify delta, #305).
  prefilter Deterministic substring pre-filter (#305): for each citation, if the
            manifest's `draft_sentence` contains the cited page's claim
            `excerpt_quote` (fallback `text`) as an exact substring, classify it
            `verbatim` without an LLM call. Resolves all three claim-bearing
            families — source/synthesis pages (`pre_extracted_claims:`), the four
            distilled kinds (`distilled_claims:`, `text`-only needle; #362), and
            `type: question` nodes (`answer_claims:`, `text`-only needle; #432) —
            mirroring the `wiki-verifier` Phase-0 page-kind resolution. Writes a
            `verify-shard-prefilter` fragment and returns {matched_ids,
            remaining_ids}. Fail-safe — a page it cannot parse simply leaves its
            citations in `remaining_ids`.
  merge     Concatenate the per-shard `verify-shard-*-v{N}.json` fragments
            into the canonical `verify-vN.json`, recompute `counts`, and
            enforce `counts.total == len(verified) + len(deviations)`.
            `--manifest` switches conservation to the manifest id-set;
            `--carry-forward-from` folds untouched verdicts from a prior round so
            the canonical file stays complete while the shards shrink to the delta.

Why no file lock (unlike `candidate-store.py`): shards are
partition-disjoint — each `wiki-verifier` writes its OWN fragment file, and
`merge` runs once after all shards complete. There is no shared-write
contention to guard, so `fcntl.flock` would be cargo-cult here. Writes go
through `_knowledge_lib.atomic_write` for crash-safety all the same.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.

See `references/inverted-pipeline.md` Phase 6 contract for the verify-vN.json
shape this script enforces.
"""

from __future__ import annotations

import argparse
import json
import sys
import unicodedata
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _knowledge_lib import (  # noqa: E402
    atomic_write,
    parse_answer_claims_with_id,
    parse_distilled_claims_with_id,
    parse_pre_extracted_claims,
    strip_inline_citation_markers,
)

# Wiki sub-dirs whose pages carry first-class claim evidence the prefilter can
# fast-path. `pre_extracted_claims:` on source/synthesis/interview pages (keyed
# `id`) — interview notes are source-class evidence (same `pre_extracted_claims:`
# frontmatter), so they share the source parser and must be scanned here too, in
# lockstep with `wiki-verifier` Phase-0 (omitting them fast-paths nothing for a
# cited interview page, so it always pays an avoidable LLM round-trip);
# `distilled_claims:` on the four distilled page kinds (keyed `claim_id`, no
# `excerpt_quote`) — citable + scored since #344, fast-pathed since #362;
# `answer_claims:` on `type: question` nodes (keyed `claim_id` = `acl-NNN`, no
# `excerpt_quote`) — the 4th evidence family, citable since #432. Order mirrors
# `wiki-verifier` Phase-0: sources/interviews/syntheses first, then distilled, then questions.
_SOURCE_SUBDIRS = ("sources", "interviews", "syntheses")
_DISTILLED_SUBDIRS = ("concepts", "entities")
_QUESTION_SUBDIRS = ("questions",)

SCHEMA_VERSION = "0.1.0"
# Citation-manifest schema versions this store reads (shard / prefilter / merge).
# Distinct from SCHEMA_VERSION, which is the schema of the verify-vN.json / shard
# files this store WRITES (unchanged). #395 added an additive per-citation `url`
# field and bumped the citation-manifest to 0.1.1; the entries this store needs
# (`id`, `draft_sentence`, `wiki_slug`, `claim_id`) are untouched, so both
# versions are read transparently. The shard copy mirrors its source manifest's
# own schema_version so a 0.1.1 manifest's `url` fields ride through to the verifier.
ACCEPTED_MANIFEST_SCHEMAS = ("0.1.0", "0.1.1")
SHARD_DIRNAME = "verify-shards"
VERDICTS = ("verbatim", "paraphrase", "synthesis", "unsupported")
# Minimum needle length for the deterministic prefilter to assert `verbatim`. A
# real excerpt_quote is a full clause; anything shorter substring-matches by
# coincidence, so below this floor the citation is left for the LLM verifier.
MIN_PREFILTER_NEEDLE_LEN = 24
# The needle must cover ~the whole (marker-stripped) draft sentence for `verbatim`
# — "is the quote", not merely "contains the quote". A sentence that embeds the
# excerpt but adds an unsupported qualifier/negation ("…only after 2027",
# "Contrary to…") drops below this and falls through to the LLM verifier.
PREFILTER_COVERAGE_RATIO = 0.9


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _load_manifest(path: Path, expected_version: int) -> tuple[dict | None, str]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None, f"manifest does not exist: {path}"
    except json.JSONDecodeError as exc:
        return None, f"manifest is not valid JSON: {exc}"
    if not isinstance(manifest, dict):
        return None, f"manifest top-level must be a JSON object, got {type(manifest).__name__}"
    schema = manifest.get("schema_version")
    if schema not in ACCEPTED_MANIFEST_SCHEMAS:
        return None, (
            f"manifest schema_version must be one of {ACCEPTED_MANIFEST_SCHEMAS!r}, "
            f"got {schema!r}"
        )
    draft_v = manifest.get("draft_version")
    if draft_v != expected_version:
        return None, (
            f"manifest draft_version={draft_v!r} but --draft-version={expected_version}"
        )
    citations = manifest.get("citations")
    if not isinstance(citations, list):
        return None, "manifest 'citations' must be a list"
    # F22 (v0.0.28) made `id` + `draft_sentence` required per entry but kept the
    # additive schema_version 0.1.0 — so a pre-0.0.28 manifest passes the schema
    # check above yet would mass-drop every citation as `sentence_not_in_draft`
    # (no draft_sentence to substring-check) and collapse missing ids to None in
    # merge's dup check. Fail loud here instead. See #291.
    for idx, entry in enumerate(citations):
        if not isinstance(entry, dict):
            return None, f"citation {idx} is not a JSON object"
        if "id" not in entry or "draft_sentence" not in entry:
            return None, (
                f"citation {idx} is missing id/draft_sentence — citation-manifest "
                "predates v0.0.28; re-run knowledge-compose"
            )
    return manifest, ""


def _shard_paths(out_dir: Path, draft_version: int, index: int) -> tuple[Path, Path]:
    suffix = f"{index:02d}-v{draft_version}.json"
    return out_dir / f"shard-{suffix}", out_dir / f"verify-shard-{suffix}"


def cmd_shard(args: argparse.Namespace) -> int:
    if args.shard_size < 1:
        return _emit(False, error="--shard-size must be >= 1")
    manifest_path = Path(args.manifest).resolve()
    out_dir = Path(args.out_dir).resolve()
    draft_version = int(args.draft_version)

    manifest, err = _load_manifest(manifest_path, draft_version)
    if manifest is None:
        return _emit(False, error=err)

    citations = manifest["citations"]
    if args.only_ids is not None:
        # Incremental re-verify (#305): shard only the touched-citation delta.
        wanted = {tok for tok in (t.strip() for t in args.only_ids.split(",")) if tok}
        citations = [c for c in citations if c.get("id") in wanted]
    out_dir.mkdir(parents=True, exist_ok=True)
    # Idempotent re-shard: clear prior shard inputs AND the NUMBERED verifier
    # fragments for THIS draft version so a re-run (or a stale crashed round at
    # the same N) cannot leak old entries into the merge. The glob is scoped to
    # `verify-shard-[0-9]*` (numbered fragments only) so a `verify-shard-prefilter`
    # fragment written earlier in the same round (#305) survives the reshard —
    # prefilter runs before shard and must not be clobbered.
    for stale in out_dir.glob(f"shard-*-v{draft_version}.json"):
        stale.unlink()
    for stale in out_dir.glob(f"verify-shard-[0-9]*-v{draft_version}.json"):
        stale.unlink()

    shards: list[dict] = []
    for index, start in enumerate(range(0, len(citations), args.shard_size)):
        chunk = citations[start : start + args.shard_size]
        citations_path, verify_out_path = _shard_paths(out_dir, draft_version, index)
        atomic_write(
            citations_path,
            {
                # Mirror the source manifest's schema (#395): a shard is a slice of
                # the same citation-manifest, so it must declare the same version —
                # not this store's verify-output SCHEMA_VERSION.
                "schema_version": manifest.get("schema_version", SCHEMA_VERSION),
                "draft_version": draft_version,
                "shard_index": index,
                "citations": chunk,
            },
        )
        shards.append(
            {
                "index": index,
                "citations_path": str(citations_path),
                "verify_out_path": str(verify_out_path),
                "citation_count": len(chunk),
            }
        )

    return _emit(
        True,
        data={
            "shard_dir": str(out_dir),
            "shard_count": len(shards),
            "citation_count": len(citations),
            "shard_size": args.shard_size,
            "shards": shards,
        },
    )


def _nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s) if s else s


def cmd_prefilter(args: argparse.Namespace) -> int:
    manifest_path = Path(args.manifest).resolve()
    wiki_root = Path(args.wiki_root).resolve()
    out_dir = Path(args.out_dir).resolve()
    draft_version = int(args.draft_version)

    manifest, err = _load_manifest(manifest_path, draft_version)
    if manifest is None:
        return _emit(False, error=err)

    citations = manifest["citations"]
    if args.only_ids is not None:
        wanted = {tok for tok in (t.strip() for t in args.only_ids.split(",")) if tok}
        citations = [c for c in citations if c.get("id") in wanted]

    # Executive-density bypass. The substring prefilter only ever marks a
    # citation `verbatim` on a near-exact draft↔claim match; executive prose
    # paraphrases sources by design (BLUF + Pyramid), so the prefilter measures
    # a 0% hit rate on executive drafts — it still scans every citation, reads
    # every cited wiki page, and routes 100% of citations to the LLM verifier,
    # pure latency for zero shard reduction. Skip the scan: emit the same zeroed
    # fragment the no-match path produces below and route every citation to
    # `remaining_ids`. Fail-safe — the standard path would have produced the
    # identical empty match set, just slower.
    if args.prose_density == "executive":
        all_ids = [c.get("id") for c in citations]
        frag_path = out_dir / f"verify-shard-prefilter-v{draft_version}.json"
        atomic_write(
            frag_path,
            {
                "schema_version": SCHEMA_VERSION,
                "draft_version": draft_version,
                "revision_round": int(args.revision_round),
                "verified": [],
                "deviations": [],
                "counts": {"verbatim": 0, "paraphrase": 0, "synthesis": 0,
                           "unsupported": 0, "total": 0},
            },
        )
        return _emit(
            True,
            data={
                "fragment": str(frag_path),
                "matched_ids": [],
                "remaining_ids": all_ids,
                "matched_count": 0,
                "remaining_count": len(all_ids),
                "skipped": "executive-density",
            },
        )

    # Read the current draft (NFC-normalized) so we can confirm the manifest's
    # draft_sentence is ACTUALLY in the draft before classifying — the same
    # staleness guard the wiki-verifier applies (`sentence_not_in_draft`). The
    # prefilter never trusts a stale manifest sentence. Path: explicit --draft,
    # else derived from the manifest's project layout (<project>/output/).
    if args.draft:
        draft_path = Path(args.draft).resolve()
    else:
        draft_path = manifest_path.parent.parent / "output" / f"draft-v{draft_version}.md"
    try:
        draft_text = _nfc(draft_path.read_text(encoding="utf-8")) if draft_path.is_file() else ""
    except OSError:
        draft_text = ""

    claims_cache: dict[str, dict] = {}

    def claims_for(slug: str) -> dict:
        if slug in claims_cache:
            return claims_cache[slug]
        # Resolve the page across both evidence families: source/synthesis pages
        # (`pre_extracted_claims:`, keyed `id`) and the four distilled kinds
        # (`distilled_claims:`, keyed `claim_id`, no `excerpt_quote`) — citable +
        # scored since #344, fast-pathed here since #362. A slug is meant to be
        # unique across all of these dirs. Rather than leave that invariant
        # undefended with a first-wins pick (a collision would silently resolve to
        # whichever family is scanned first and score against the wrong claim
        # block), we DETECT a cross-dir collision and treat it as ambiguous — the
        # same posture as the duplicate-claim-id guard below. An ambiguous (or
        # absent) slug yields no claims, so its citation falls through to the LLM
        # verifier (which owns the authoritative first-wins resolution), never a
        # wrong `verbatim`.
        hits: list[tuple[str, str]] = []  # (subdir, family) per existing page
        for sub in _SOURCE_SUBDIRS:
            if (wiki_root / "wiki" / sub / f"{slug}.md").is_file():
                hits.append((sub, "source"))
        for sub in _DISTILLED_SUBDIRS:
            if (wiki_root / "wiki" / sub / f"{slug}.md").is_file():
                hits.append((sub, "distilled"))
        for sub in _QUESTION_SUBDIRS:
            if (wiki_root / "wiki" / sub / f"{slug}.md").is_file():
                hits.append((sub, "question"))
        if len(hits) != 1:
            # 0 hits (page absent) or >1 (cross-dir collision) → no claims.
            claims_cache[slug] = {}
            return {}
        sub, family = hits[0]
        try:
            text = (wiki_root / "wiki" / sub / f"{slug}.md").read_text(encoding="utf-8")
        except OSError:
            text = ""
        if family == "distilled":
            parser, id_key = parse_distilled_claims_with_id, "claim_id"
        elif family == "question":
            # Question nodes carry `answer_claims:` (acl-NNN, no excerpt_quote) — keyed
            # on claim_id exactly like distilled; the `excerpt_quote or text` needle
            # below resolves to text cleanly (#432).
            parser, id_key = parse_answer_claims_with_id, "claim_id"
        else:
            parser, id_key = parse_pre_extracted_claims, "id"
        # A duplicate claim id on one page is ambiguous — the citation could mean
        # either claim, so we cannot safely pick one. Drop ambiguous ids so the
        # citation falls through to the LLM rather than being scored against an
        # arbitrary (parse-order) claim.
        by_id: dict = {}
        ambiguous: set = set()
        for c in parser(text):
            cid2 = c.get(id_key)
            if not cid2 or cid2 in ambiguous:
                continue
            if cid2 in by_id:
                ambiguous.add(cid2)
                by_id.pop(cid2, None)
                continue
            by_id[cid2] = c
        claims_cache[slug] = by_id
        return by_id

    matched: list[dict] = []
    matched_ids: list = []
    remaining_ids: list = []
    for cit in citations:
        cid = cit.get("id")
        slug = cit.get("wiki_slug")
        claim_id = cit.get("claim_id")
        draft_sentence = _nfc(cit.get("draft_sentence") or "")
        hit = False
        # Staleness: the sentence must actually appear in the current draft (else
        # the wiki-verifier would flag sentence_not_in_draft — never auto-pass it).
        if cid and slug and claim_id and draft_sentence and draft_sentence in draft_text:
            claim = claims_for(slug).get(claim_id)
            if claim:
                # Source/synthesis claims prefer `excerpt_quote`; distilled claims
                # (#362) carry only `text`, so the `or` falls back to it cleanly.
                needle = _nfc(claim.get("excerpt_quote") or claim.get("text") or "").strip()
                # `verbatim` must mean the sentence IS the quote, not merely
                # CONTAINS it: a sentence embedding the excerpt but adding an
                # unsupported qualifier/negation is at most paraphrase/unsupported
                # and must go to the LLM. So require the needle to be (a)
                # SUBSTANTIAL (a short "AI"/">"/comment fragment matches by
                # coincidence) and (b) to COVER ~the whole marker-stripped sentence.
                # Below either bar the citation falls through to the LLM (safe miss,
                # never a wrong verdict). Cross-language self-gates on top of this.
                core = strip_inline_citation_markers(draft_sentence).strip().rstrip(" \t.;:,!?")
                if (
                    len(needle) >= MIN_PREFILTER_NEEDLE_LEN
                    and needle in core
                    and len(needle) >= PREFILTER_COVERAGE_RATIO * len(core)
                ):
                    hit = True
        if hit:
            matched.append(
                {
                    "id": cid,
                    "draft_position": cit.get("draft_position"),
                    "wiki_slug": slug,
                    "claim_id": claim_id,
                    "verdict": "verbatim",
                    "method": "prefilter-substring",
                }
            )
            matched_ids.append(cid)
        else:
            remaining_ids.append(cid)

    frag_path = out_dir / f"verify-shard-prefilter-v{draft_version}.json"
    atomic_write(
        frag_path,
        {
            "schema_version": SCHEMA_VERSION,
            "draft_version": draft_version,
            "revision_round": int(args.revision_round),
            "verified": matched,
            "deviations": [],
            "counts": {"verbatim": len(matched), "paraphrase": 0, "synthesis": 0,
                       "unsupported": 0, "total": len(matched)},
        },
    )

    return _emit(
        True,
        data={
            "fragment": str(frag_path),
            "matched_ids": matched_ids,
            "remaining_ids": remaining_ids,
            "matched_count": len(matched_ids),
            "remaining_count": len(remaining_ids),
        },
    )


def cmd_merge(args: argparse.Namespace) -> int:
    shard_dir = Path(args.shard_dir).resolve()
    out_path = Path(args.out).resolve()
    draft_version = int(args.draft_version)
    revision_round = int(args.revision_round)

    if not shard_dir.is_dir():
        return _emit(False, error=f"shard-dir does not exist: {shard_dir}")

    if args.carry_forward_from and not args.manifest:
        return _emit(False, error="--carry-forward-from requires --manifest")

    # Conservation source (#305). With `--manifest`, the recombined id-set must
    # equal the CURRENT manifest id-set — the unified mode that both carry-forward
    # (verdicts from outside this round's fragments) and the prefilter need. The
    # round-≥1 shards cover only the delta, so the shard-input set is intentionally
    # a subset and must NOT gate conservation. Without `--manifest` we fall back to
    # the shard-input set (the original single-pass contract).
    manifest_ids: list | None = None
    if args.manifest:
        cm, merr = _load_manifest(Path(args.manifest).resolve(), draft_version)
        if cm is None:
            return _emit(False, error=merr)
        manifest_ids = [c.get("id") for c in cm["citations"]]
        # Conservation is an id-SET comparison, so a null or duplicate manifest id
        # makes len(expected_ids) != len(set) — yielding a self-contradictory
        # "verified N of M ... missing: []; unexpected: []" error that can never
        # reconcile. Reject up front with a clear message.
        if any(i is None for i in manifest_ids):
            return _emit(False, error="manifest has a citation with a null/missing id")
        mdupes = sorted({i for i, n in Counter(manifest_ids).items() if n > 1})
        if mdupes:
            return _emit(False, error=f"manifest has duplicate citation id(s): {mdupes}")

    expected_ids: list = []
    if manifest_ids is not None:
        expected_ids = manifest_ids
        have_expected = True
    else:
        # End-to-end completeness signal: the citation ids that were sharded for
        # THIS draft version. `shard` leaves its inputs in place, so when merge
        # runs after shard (the pipeline flow) we can verify the recombined set
        # equals the partitioned set — catching a missing/under-populated/duplicate
        # fragment, which the internal counts.total tally cannot. When the inputs
        # are absent (a bare standalone merge), fall back to internal consistency.
        input_shards = sorted(shard_dir.glob(f"shard-*-v{draft_version}.json"))
        have_expected = bool(input_shards)
        for sp in input_shards:
            try:
                sm = json.loads(sp.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                return _emit(False, error=f"shard input {sp.name} is not valid JSON: {exc}")
            if not isinstance(sm, dict) or not isinstance(sm.get("citations"), list):
                return _emit(False, error=f"shard input {sp.name} is malformed (no citations list)")
            expected_ids.extend(c.get("id") for c in sm["citations"] if isinstance(c, dict))

    fragments = sorted(shard_dir.glob(f"verify-shard-*-v{draft_version}.json"))
    if not fragments:
        return _emit(
            False,
            error=f"no verify-shard-*-v{draft_version}.json fragments found in {shard_dir}",
        )

    verified: list[dict] = []
    deviations: list[dict] = []
    for frag_path in fragments:
        try:
            frag = json.loads(frag_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            return _emit(False, error=f"fragment {frag_path.name} is not valid JSON: {exc}")
        if not isinstance(frag, dict):
            return _emit(False, error=f"fragment {frag_path.name} top-level must be a JSON object")
        frag_verified = frag.get("verified")
        frag_deviations = frag.get("deviations")
        if not isinstance(frag_verified, list) or not isinstance(frag_deviations, list):
            return _emit(
                False,
                error=f"fragment {frag_path.name} missing list 'verified'/'deviations'",
            )
        if not all(isinstance(e, dict) for e in frag_verified + frag_deviations):
            return _emit(
                False,
                error=f"fragment {frag_path.name} has a non-object entry in verified/deviations",
            )
        verified.extend(frag_verified)
        deviations.extend(frag_deviations)

    # Carry-forward (#305): fold prior verdicts for manifest ids that are NOT in
    # this round's fresh fragments (untouched + not-dropped). Patch-in-place
    # guarantees those sentences are byte-identical across draft versions, so the
    # verdict is guaranteed-identical — re-scoring them would be wasted LLM calls.
    if args.carry_forward_from:
        prev_path = Path(args.carry_forward_from).resolve()
        try:
            prev = json.loads(prev_path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return _emit(False, error=f"carry-forward source does not exist: {prev_path}")
        except json.JSONDecodeError as exc:
            return _emit(False, error=f"carry-forward source is not valid JSON: {exc}")
        if not isinstance(prev, dict):
            return _emit(False, error=f"carry-forward source is not a JSON object: {prev_path}")
        prev_entries = [
            e for e in (prev.get("verified") or []) + (prev.get("deviations") or [])
            if isinstance(e, dict) and e.get("id") is not None
        ]
        # A duplicate id in the prior file would silently collapse last-write-wins
        # and carry an arbitrary (file-order) verdict — reject rather than guess.
        prev_dupes = sorted({i for i, n in Counter(e["id"] for e in prev_entries).items() if n > 1})
        if prev_dupes:
            return _emit(False, error=f"carry-forward source has duplicate citation id(s): {prev_dupes}")
        prev_by_id: dict = {e["id"]: e for e in prev_entries}
        fresh_ids = {e.get("id") for e in verified + deviations}
        missing_prev: list = []
        for mid in manifest_ids:  # manifest_ids is set whenever carry-forward is used
            if mid in fresh_ids:
                continue
            entry = prev_by_id.get(mid)
            if entry is None:
                missing_prev.append(mid)
                continue
            # Re-place by verdict so `unsupported` lands in deviations[] (the
            # revisor's trigger) regardless of where the prior file kept it.
            if entry.get("verdict") == "unsupported":
                deviations.append(entry)
            else:
                verified.append(entry)
        if missing_prev:
            return _emit(
                False,
                error=(
                    f"carry-forward: {len(missing_prev)} manifest id(s) have no prior "
                    f"verdict in {prev_path.name} (delete it to force a full re-shard): "
                    f"{sorted(missing_prev, key=lambda x: (x is None, x))}"
                ),
            )

    # Verdict placement: `unsupported` MUST live in deviations[] — the revisor
    # only triages deviations[], so an `unsupported` mis-filed into verified[]
    # would silently escape correction (the internal tally below can't see it).
    misfiled = [e.get("id") for e in verified if e.get("verdict") == "unsupported"]
    if misfiled:
        return _emit(
            False,
            error=(
                f"unsupported verdict mis-filed in verified[] (ids: {misfiled}) — "
                "the revisor only reads deviations[]"
            ),
        )

    counts = {v: 0 for v in VERDICTS}
    for entry in verified + deviations:
        verdict = entry.get("verdict")
        if verdict in counts:
            counts[verdict] += 1
    counts["total"] = len(verified) + len(deviations)
    tallied = sum(counts[v] for v in VERDICTS)
    if tallied != counts["total"]:
        return _emit(
            False,
            error=(
                f"verdict tally {tallied} != verified+deviations {counts['total']} — "
                "a fragment carried an unrecognized verdict"
            ),
        )

    # Duplicate ids (an overlapping/double-written fragment) inflate counts and
    # emit two verdicts for one citation — reject rather than silently merge.
    merged_ids = [e.get("id") for e in verified + deviations]
    dupes = sorted({i for i, n in Counter(merged_ids).items() if n > 1}, key=lambda x: (x is None, x))
    if dupes:
        return _emit(False, error=f"duplicate citation id(s) across fragments: {dupes}")

    # Conservation: the recombined id-set must equal the sharded id-set — no
    # dropped shard, no extra/stale fragment, no under-populated shard.
    if have_expected:
        merged_set, expected_set = set(merged_ids), set(expected_ids)
        if counts["total"] != len(expected_ids) or merged_set != expected_set:
            missing = sorted(expected_set - merged_set, key=lambda x: (x is None, x))
            extra = sorted(merged_set - expected_set, key=lambda x: (x is None, x))
            return _emit(
                False,
                error=(
                    f"verified {counts['total']} of {len(expected_ids)} sharded citations — "
                    f"a fragment is missing or under-populated (missing ids: {missing}; "
                    f"unexpected ids: {extra})"
                ),
            )

    atomic_write(
        out_path,
        {
            "schema_version": SCHEMA_VERSION,
            "draft_version": draft_version,
            "revision_round": revision_round,
            "verified": verified,
            "deviations": deviations,
            "counts": counts,
        },
    )

    return _emit(
        True,
        data={
            "path": str(out_path),
            "shards_merged": len(fragments),
            "counts": counts,
        },
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Shard a citation manifest for parallel verification and merge the fragments.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_shard = sub.add_parser("shard", help="Split citations[] into per-shard manifests")
    p_shard.add_argument("--manifest", required=True, help="Path to citation-manifest.json")
    p_shard.add_argument("--draft-version", required=True, type=int)
    p_shard.add_argument("--shard-size", type=int, default=40, help="Citations per shard (default 40)")
    p_shard.add_argument(
        "--only-ids",
        default=None,
        help="CSV of citation ids to restrict the split to (incremental re-verify delta, #305)",
    )
    p_shard.add_argument(
        "--out-dir",
        required=True,
        help="Directory for shard files (e.g. <project>/.metadata/verify-shards/)",
    )
    p_shard.set_defaults(func=cmd_shard)

    p_pre = sub.add_parser(
        "prefilter",
        help="Deterministic substring pre-filter: mark trivially-verbatim citations without an LLM call",
    )
    p_pre.add_argument("--manifest", required=True, help="Path to citation-manifest.json")
    p_pre.add_argument("--wiki-root", required=True, help="Bound wiki root (dir containing wiki/)")
    p_pre.add_argument("--draft-version", required=True, type=int)
    p_pre.add_argument("--out-dir", required=True, help="Directory for the prefilter fragment (verify-shards/)")
    p_pre.add_argument(
        "--draft",
        default=None,
        help="Path to the current draft-vN.md (staleness check; default: derived from --manifest layout)",
    )
    p_pre.add_argument("--only-ids", default=None, help="CSV of citation ids to restrict the scan to")
    p_pre.add_argument("--revision-round", type=int, default=0, help="Cosmetic; merge sets the canonical round")
    p_pre.add_argument(
        "--prose-density",
        default="standard",
        choices=["standard", "executive"],
        help="When 'executive', skip the substring scan entirely (paraphrase-by-design, 0%% hit rate) "
             "and route every citation to the LLM verifier — emits a zeroed fragment. Default 'standard'.",
    )
    p_pre.set_defaults(func=cmd_prefilter)

    p_merge = sub.add_parser("merge", help="Merge per-shard verify fragments into verify-vN.json")
    p_merge.add_argument("--shard-dir", required=True)
    p_merge.add_argument("--draft-version", required=True, type=int)
    p_merge.add_argument("--revision-round", required=True, type=int)
    p_merge.add_argument("--out", required=True, help="Path to the canonical verify-vN.json")
    p_merge.add_argument(
        "--manifest",
        default=None,
        help="citation-manifest.json — switch conservation to the manifest id-set (#305)",
    )
    p_merge.add_argument(
        "--carry-forward-from",
        default=None,
        help="Prior verify-vN.json to carry untouched verdicts from (requires --manifest, #305)",
    )
    p_merge.set_defaults(func=cmd_merge)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

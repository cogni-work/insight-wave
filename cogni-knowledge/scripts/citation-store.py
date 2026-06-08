#!/usr/bin/env python3
"""
citation-store.py — assemble `<project>/.metadata/citation-manifest.json` from
the wiki-composer's raw citation-records file, serializing with `json.dumps` so
the escaping is owned by Python and never hand-typed by the LLM (#325).

Background: `wiki-composer` has no `Bash` and cannot run a serializer, so in the
v0.1.x pipeline it hand-typed the manifest JSON into the `Write` tool's content.
A `draft_sentence` containing a straight `"` — routine in German/FR/IT/ES/PL
prose, and in English with any quoted term — then broke `json.loads` downstream
and the whole verify→revise→finalize tail died (#325, surfaced live in the #311
German bake-in: `„Profiling natürlicher Personen"` closed with an ASCII quote).

The fix takes JSON construction off the LLM entirely. The composer writes
citation RECORDS as raw text through the byte-safe `Write` channel (one labeled
`- id:` block per citation, the sentence verbatim and unescaped); the
`knowledge-compose` orchestrator — which has `Bash` — runs this script to parse
those records and `json.dump` the manifest, then self-checks it.

  build   Parse --records via `_knowledge_lib.parse_citation_records`, assert
          every draft_sentence is an NFC substring of --draft (the verbatim
          alignment surface the verifier scores against), optionally (when
          --ingest-manifest is given) assert every inline citation URL is a known
          ingested-source URL (the #383 slug-derived-URL gate) AND assert the
          per-citation slug→URL binding (#395) — each record's structured `url`
          field must agree with both its own inline marker and the cited slug's
          ingested `sources:` URL, catching a real-but-mis-attributed URL the
          set-membership gate can't. Then `json.dump` the manifest to --out
          (`ensure_ascii=False`) and round-trip it (re-read + `json.loads` + count
          assert — the read-back the composer's old Step 3 never actually parsed).
          Any failure → `success:false` so the orchestrator stops rather than
          shipping a broken manifest.

All output uses the insight-wave script envelope:
  {"success": bool, "data": {...}, "error": "..."}

Stdlib only. No pip dependencies.

See `references/inverted-pipeline.md` Phase 5 contract for the
citation-manifest.json shape this script enforces.
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
    classify_claim_kind,
    extract_inline_citation_urls,
    normalize_url,
    parse_citation_records,
)

SCHEMA_VERSION = "0.1.1"


def _emit(success: bool, data: dict | None = None, error: str = "") -> int:
    payload = {"success": success, "data": data or {}, "error": error}
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0 if success else 1


def _nfc(s: str) -> str:
    return unicodedata.normalize("NFC", s) if s else s


def cmd_build(args: argparse.Namespace) -> int:
    records_path = Path(args.records).resolve()
    draft_path = Path(args.draft).resolve()
    out_path = Path(args.out).resolve()
    draft_version = int(args.draft_version)

    try:
        records_text = records_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return _emit(False, data={"path": str(records_path)}, error="records_not_found")
    except OSError as exc:
        return _emit(False, error=f"records file is not readable: {exc}")

    records = parse_citation_records(records_text)

    try:
        draft_text = draft_path.read_text(encoding="utf-8")
    except FileNotFoundError:
        return _emit(False, data={"path": str(draft_path)}, error="draft_not_found")
    except OSError as exc:
        return _emit(False, error=f"draft file is not readable: {exc}")

    # Parse the ingest manifest once, up-front, into the two indices the URL gates
    # need: `known` (every ingested URL, for the #383 set-membership gate) and
    # `slug_url` (slug -> its ingested `sources:` URL, the third leg of the #395
    # binding gate). Both stay empty on degenerate input (missing / unreadable /
    # malformed manifest, or one yielding no usable entries), and the except resets
    # them so a TypeError part-way through the loop can't leave a half-built index —
    # every gate below then fail-soft / skips. Parsed here (not lazily inside the
    # later `if args.ingest_manifest` block) so the draft-body URL gate immediately
    # below can pre-empt the `sentence_not_in_draft` check.
    known: set[str] = set()
    slug_url: dict[str, str] = {}
    if args.ingest_manifest:
        try:
            manifest = json.loads(Path(args.ingest_manifest).read_text(encoding="utf-8"))
            if isinstance(manifest, dict):
                for e in manifest.get("ingested", []):
                    if isinstance(e, dict) and e.get("url"):
                        nu = normalize_url(e["url"])
                        known.add(nu)
                        if e.get("slug"):
                            slug_url[e["slug"]] = nu
        except (OSError, json.JSONDecodeError, TypeError):
            known = set()
            slug_url = {}

    # Draft-BODY inline-URL gate (#586): the record-side #383 gate further down
    # scans each record's `draft_sentence`, but in the stacked-citation case the
    # composer can slug-derive ONE marker's URL in the DRAFT BODY while the matching
    # record keeps the correct `sources:` URL. Body and record then disagree, so the
    # substring check immediately below trips `sentence_not_in_draft` first — masking
    # the real defect (a fabricated URL in the body) behind a generic "sentence
    # drifted" signal. Scanning the draft body's inline `<sup>[N](url)</sup>` URLs
    # here, BEFORE the substring check, surfaces the divergence as
    # `url_not_in_sources` with the offending marker URL. Bare `<sup>[N]</sup>`
    # synthesis/distilled markers carry no URL and contribute nothing, so they never
    # false-positive. Fail-soft: skipped when `known` is empty (no/degenerate manifest).
    if known:
        body_urls = dict.fromkeys(extract_inline_citation_urls(draft_text))
        body_bad = [u for u in body_urls if normalize_url(u) not in known]
        if body_bad:
            return _emit(
                False,
                data={"failed_check": "url_not_in_sources", "urls": body_bad, "source": "draft_body"},
                error="write_failed",
            )

    # Substring self-check BEFORE writing: every draft_sentence must appear
    # verbatim in the current draft (NFC-normalized for comparison only — the
    # stored sentence stays byte-exact). A miss is the composer/draft drift the
    # downstream verifier flags as `sentence_not_in_draft`; catch it here so the
    # orchestrator never ships a manifest whose alignment surface is stale.
    nfc_draft = _nfc(draft_text)
    missing = [
        r.get("id")
        for r in records
        # An empty/whitespace draft_sentence has no alignment surface, and
        # `"" in anything` is always True — guard it explicitly so a record whose
        # `sentence:` line was omitted can't slip through the substring check.
        if not (r.get("draft_sentence") or "").strip()
        or _nfc(r.get("draft_sentence") or "") not in nfc_draft
    ]
    if missing:
        return _emit(
            False,
            data={"failed_check": "sentence_not_in_draft", "ids": missing},
            error="write_failed",
        )

    citations = [
        {
            "id": r.get("id", ""),
            "draft_position": r.get("draft_position", ""),
            "draft_sentence": r.get("draft_sentence", ""),
            "wiki_slug": r.get("wiki_slug", ""),
            "claim_id": r.get("claim_id"),
            "url": r.get("url", ""),
        }
        for r in records
    ]

    # `id` is the join key the verifier / revisor / `verify-store.py merge
    # --manifest` rely on (merge itself rejects null/duplicate ids). Catch an
    # empty or duplicated id at this build gate — the layer that owns manifest
    # validity — rather than several phases downstream.
    ids = [c["id"] for c in citations]
    if any(not i for i in ids):
        return _emit(False, data={"failed_check": "empty_id"}, error="write_failed")
    dup_ids = sorted({i for i, n in Counter(ids).items() if n > 1})
    if dup_ids:
        return _emit(False, data={"failed_check": "duplicate_id", "ids": dup_ids}, error="write_failed")

    # Inline-URL gate (#383): when --ingest-manifest is given, assert every inline
    # citation URL in the records is a known ingested-source URL. The composer must
    # copy the cited page's real `sources:` value verbatim; when it instead
    # reconstructs the URL from the (title-derived, transliterated) slug, the path
    # tail diverges and a broken link ships. The substring check above can't catch
    # a CONSISTENTLY-wrong URL (record and draft agree on the slug-derived value),
    # so this cross-checks the inline URLs against `ingest-manifest.json::ingested[]`.
    # Fail-soft on degenerate input: a missing / unreadable / malformed manifest, or
    # one yielding zero source URLs, skips the check (this is hardening, not a new
    # hard-fail mode on edge manifests). normalize_url is applied symmetrically to
    # both sides, so trailing-slash / host-case differences never false-positive.
    if args.ingest_manifest:
        # `known` / `slug_url` were already parsed up-front (above the
        # `sentence_not_in_draft` check, so the #586 draft-body gate could pre-empt
        # it). Reuse them here for the record-side #383 set-membership gate and the
        # #395 per-citation slug->URL binding gate; both stay empty on degenerate
        # input, so the gates below fail-soft / skip exactly as before.

        # Extract each record's inline citation URLs once — both gates below consume
        # them, so the regex parse of `draft_sentence` runs a single time per record.
        record_inlines = [
            extract_inline_citation_urls(r.get("draft_sentence") or "") for r in records
        ]

        if known:
            # Dedup the raw inline URLs first (order-preserving) so each distinct
            # URL is normalized + checked once — a draft re-cites the same source
            # many times. `bad` reports each offending URL once, in first-seen order.
            inline_urls = dict.fromkeys(u for urls in record_inlines for u in urls)
            bad = [u for u in inline_urls if normalize_url(u) not in known]
            if bad:
                return _emit(
                    False,
                    data={"failed_check": "url_not_in_sources", "urls": bad},
                    error="write_failed",
                )

        # Per-citation slug→URL binding gate (#395): the set-membership check above
        # kills a fabricated / slug-derived URL, but a REAL-but-mis-attributed URL
        # (cite source A's claim, link source B's genuinely-ingested URL) passes it —
        # both URLs are in the ingested set. The structured per-record `url` field
        # (copied by the composer from the cited page's `sources:`) lets us assert
        # the three-way agreement the issue specifies, per citation:
        #
        #   record.url == url_in(record.draft_sentence) == sources:(record.wiki_slug)
        #
        # The third leg, `sources:(wiki_slug)`, is resolved from the ingest manifest:
        # each `ingested[]` entry already carries both `slug` and its `sources:`-derived
        # `url`, so no page-file I/O is needed. The gate is additive + fail-soft per
        # record: it only fires when `record.url` is non-empty (legacy records and
        # synthesis/distilled citations have no external URL and are skipped), and the
        # slug leg is skipped when the cited slug is not in the ingest manifest (e.g. a
        # synthesis-page citation, or a slug ingested in a prior run) — nothing to bind
        # against, so absence is not a mismatch.
        mismatches = []
        for r, raw_inlines in zip(records, record_inlines):
            rec_url = (r.get("url") or "").strip()
            if not rec_url:
                continue  # no structured URL on this record → nothing to bind
            rec_n = normalize_url(rec_url)
            inline = {normalize_url(u) for u in raw_inlines}
            page_n = slug_url.get(r.get("wiki_slug", ""))
            # Prose leg: the record's `url` must appear among its own sentence's
            # marker(s). Membership (not equality) because one sentence can carry two
            # adjacent markers for two different slugs — each record's `url` must be one
            # of them. A record whose sentence carries no external-URL marker (a plain
            # `<sup>[N]</sup>` synthesis marker) has nothing to bind on the prose side.
            prose_bad = bool(inline) and rec_n not in inline
            # Slug leg: the record's `url` must equal the cited page's ingested
            # `sources:` URL. Skipped when the slug is not in the ingest manifest.
            slug_bad = page_n is not None and rec_n != page_n
            if prose_bad or slug_bad:
                mismatches.append(
                    {
                        "id": r.get("id", ""),
                        "wiki_slug": r.get("wiki_slug", ""),
                        "url": rec_url,
                        "expected": page_n,
                    }
                )
        if mismatches:
            return _emit(
                False,
                data={"failed_check": "url_slug_mismatch", "mismatches": mismatches},
                error="write_failed",
            )

    try:
        atomic_write(
            out_path,
            {
                "schema_version": SCHEMA_VERSION,
                "draft_version": draft_version,
                "citations": citations,
            },
        )
    except OSError as exc:
        # Disk full, unwritable parent, --out under a non-directory, etc. Return
        # the envelope the orchestrator parses, not a bare traceback.
        return _emit(False, data={"detail": f"manifest write failed: {exc}"}, error="write_failed")

    # Round-trip self-check: re-read what we just wrote and `json.loads` it (the
    # gap the composer's old "Read it back to confirm persistence" never closed —
    # it never parsed), then assert no citation was lost parse→serialize→read.
    try:
        reloaded = json.loads(out_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return _emit(
            False,
            data={"detail": f"manifest did not round-trip: {exc}"},
            error="write_failed",
        )
    reloaded_cites = reloaded.get("citations") if isinstance(reloaded, dict) else None
    if not isinstance(reloaded_cites, list) or len(reloaded_cites) != len(records):
        return _emit(
            False,
            data={
                "detail": "citation count drifted in round-trip",
                "records": len(records),
                "citations": len(reloaded_cites) if isinstance(reloaded_cites, list) else None,
            },
            error="write_failed",
        )

    # Per-kind citation breakdown (#385) — purely a measurement on the return
    # envelope (the manifest JSON + its schema are unchanged). Classify each
    # citation by its `claim_id` prefix so `knowledge-compose` can surface the
    # `dcl-` rate every run: a distilled-page citation (`dcl-NNN`) is the
    # cross-source-convergence evidence #344 made citable, and 0 distilled
    # citations on a base with converging distilled pages is the #385 symptom.
    breakdown = Counter(classify_claim_kind(c["claim_id"]) for c in citations)

    return _emit(
        True,
        data={
            "path": str(out_path),
            "citations_count": len(citations),
            "claim_kinds": breakdown,
        },
    )


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Assemble citation-manifest.json from the composer's raw citation-records file.",
        allow_abbrev=False,
    )
    sub = parser.add_subparsers(dest="action", required=True)

    p_build = sub.add_parser(
        "build",
        help="Parse the records file, json.dump the manifest, and self-check it (round-trip + substring).",
    )
    p_build.add_argument("--records", required=True, help="Path to the composer's citation-records file")
    p_build.add_argument("--draft", required=True, help="Path to the just-written draft-vN.md (substring check)")
    p_build.add_argument("--out", required=True, help="Path to write citation-manifest.json")
    p_build.add_argument("--draft-version", required=True, type=int)
    p_build.add_argument(
        "--ingest-manifest",
        required=False,
        default=None,
        help="Optional path to ingest-manifest.json; when given, every inline "
        "citation URL must be a known ingested-source URL (#383 slug-derived-URL gate).",
    )
    p_build.set_defaults(func=cmd_build)

    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

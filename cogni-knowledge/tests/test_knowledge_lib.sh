#!/usr/bin/env bash
# test_knowledge_lib.sh — contract test for the shared _knowledge_lib.py.
#
# Asserts:
#   1. Three-way `is`-identity: candidate-store.normalize_url,
#      fetch-cache.normalize_url, and _knowledge_lib.normalize_url are the
#      same function object. Same for atomic_write. This is the structural
#      guarantee that the dedup-key contract between the curator-side merge
#      (candidates.json) and the fetcher-side cache lookup (fetch-cache)
#      cannot drift — it isn't a convention, it's the same function.
#   2. Behavioural canonicalization: a representative URL exercising every
#      transformation (mixed-case scheme/host, trailing slash, utm_/ref
#      stripping, fragment removal) yields the same canonical form across
#      all three callers.
#   3. atomic_write round-trip: a payload writes, reads back equal, and
#      leaves no `.tmp` debris in the parent directory on success.
#
# Script names contain hyphens (candidate-store, fetch-cache), which means
# plain `import candidate-store` is invalid Python. Tests load the modules
# by path via importlib.util.spec_from_file_location.
#
# bash 3.2 + stdlib python3 only.

set -eu

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS_DIR="$PLUGIN_ROOT/scripts"

. "$(dirname "$0")/fixtures/test_helpers.sh"

for f in _knowledge_lib.py candidate-store.py fetch-cache.py; do
  if [ ! -f "$SCRIPTS_DIR/$f" ]; then
    red "FAIL: $f not found at $SCRIPTS_DIR/$f"
    exit 1
  fi
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# Run all three assertions in one python3 subprocess; emit a tagged status
# line per assertion so bash can grade each independently. Splitting into
# three subprocesses would re-import the same three modules each time.
OUT=$(python3 - "$SCRIPTS_DIR" "$WORK" <<'PY'
import importlib.util
import json
import sys
from pathlib import Path

scripts = Path(sys.argv[1])
work = Path(sys.argv[2])


def load(name, fname):
    spec = importlib.util.spec_from_file_location(name, scripts / fname)
    mod = importlib.util.module_from_spec(spec)
    sys.modules[name] = mod
    spec.loader.exec_module(mod)
    return mod


def check(tag, fn):
    try:
        fn()
        print(f"{tag}: OK")
    except AssertionError as exc:
        print(f"{tag}: FAIL {exc}")


kl = load("_knowledge_lib", "_knowledge_lib.py")
cs = load("candidate_store", "candidate-store.py")
fc = load("fetch_cache", "fetch-cache.py")


def assert_identity():
    assert cs.normalize_url is fc.normalize_url is kl.normalize_url, (
        f"normalize_url identities diverge: cs={cs.normalize_url!r} "
        f"fc={fc.normalize_url!r} kl={kl.normalize_url!r}"
    )
    assert cs.atomic_write is fc.atomic_write is kl.atomic_write, (
        f"atomic_write identities diverge: cs={cs.atomic_write!r} "
        f"fc={fc.atomic_write!r} kl={kl.atomic_write!r}"
    )


def assert_canonicalization():
    url = "https://EXAMPLE.org/Foo/?utm_source=x&ref=y&keep=1#frag"
    expected = "https://example.org/Foo?keep=1"
    for tag, mod in (("_knowledge_lib", kl), ("candidate-store", cs), ("fetch-cache", fc)):
        got = mod.normalize_url(url)
        assert got == expected, f"{tag}: got={got!r} expected={expected!r}"


def assert_atomic_write_roundtrip():
    target = work / "out" / "payload.json"
    payload = {"schema_version": "0.1.0", "candidates": [{"url": "https://example.org/a", "score": 0.42}]}
    returned = kl.atomic_write(target, payload)
    assert returned == target, (returned, target)
    assert target.is_file(), target
    readback = json.loads(target.read_text(encoding="utf-8"))
    assert readback == payload, (readback, payload)
    leftover = [
        p.name for p in target.parent.iterdir()
        if p.name.startswith(".payload.json.") and p.name.endswith(".tmp")
    ]
    assert leftover == [], leftover


def assert_control_paths():
    # Curated-layout control-file resolver (canonical meta): prefer
    # wiki/meta/<file> when it exists; an EXISTING legacy flat wiki/<file>
    # still resolves; a file absent from BOTH layouts defaults to wiki/meta/.
    base = work / "ctrl"
    legacy = base / "legacy"
    (legacy / "wiki").mkdir(parents=True)
    (legacy / "wiki" / "log.md").write_text("legacy", encoding="utf-8")
    (legacy / "wiki" / "context_brief.md").write_text("legacy", encoding="utf-8")
    # Legacy-flat fixture: files that EXIST flat keep resolving flat.
    assert kl.log_path(legacy) == legacy / "wiki" / "log.md", kl.log_path(legacy)
    assert kl.context_brief_path(legacy) == legacy / "wiki" / "context_brief.md", \
        kl.context_brief_path(legacy)
    # meta_dir is unconditional (the canonical dir).
    assert kl.meta_dir(legacy) == legacy / "wiki" / "meta", kl.meta_dir(legacy)
    # A file absent from BOTH layouts resolves to wiki/meta/ — the canonical
    # write target now that _CANONICAL_META is flipped.
    assert kl.open_questions_path(legacy) == legacy / "wiki" / "meta" / "open_questions.md", \
        kl.open_questions_path(legacy)

    # meta-present fixture: a control file that already lives in wiki/meta/
    # resolves there; one that does not still falls back to legacy.
    meta = base / "meta"
    (meta / "wiki" / "meta").mkdir(parents=True)
    (meta / "wiki" / "log.md").write_text("legacy", encoding="utf-8")
    (meta / "wiki" / "meta" / "log.md").write_text("meta", encoding="utf-8")
    assert kl.log_path(meta) == meta / "wiki" / "meta" / "log.md", kl.log_path(meta)
    # context_brief.md present only in legacy → legacy wins (per-file fallback).
    (meta / "wiki" / "context_brief.md").write_text("legacy", encoding="utf-8")
    assert kl.context_brief_path(meta) == meta / "wiki" / "context_brief.md", \
        kl.context_brief_path(meta)
    # Unknown control-file name raises (guards a typo'd CLI subcommand).
    try:
        kl._resolve_control_path(legacy, "bogus")
        assert False, "expected ValueError for unknown control file"
    except ValueError:
        pass


def assert_slugify():
    # #303: German umlauts transliterate by convention (ä→ae …) BEFORE the
    # keep-regex strip, so `für` → `fuer` (not `f-r`); remaining Latin scripts
    # de-accent via NFKD. The empty/non-alnum → "" contract is preserved.
    cases = {
        "Lean Canvas für Insight-Wave": "lean-canvas-fuer-insight-wave",
        "für insight-wave": "fuer-insight-wave",
        "Geschäftsidee": "geschaeftsidee",
        "Über": "ueber",
        "Öl": "oel",
        "Maß": "mass",
        "Café": "cafe",
        "El Niño": "el-nino",
        # Polish ł has no NFKD decomposition and is not auto-de-accented; the
        # manual map (ł→l) keeps the supported PL market legible (#303 review).
        "Wrocław": "wroclaw",
        "łódź": "lodz",
        "": "",
        "   ": "",
        "!!!": "",
    }
    for inp, exp in cases.items():
        got = kl.slugify(inp)
        assert got == exp, f"slugify({inp!r})={got!r} expected {exp!r}"
    # NFD-form input (decomposed umlaut) must slugify identically to NFC — the
    # transliteration runs after an NFC compose, so macOS/web-sourced decomposed
    # text does not silently fall back to bare-vowel de-accenting (#303 review).
    import unicodedata
    assert kl.slugify(unicodedata.normalize("NFD", "für")) == "fuer", "NFD für -> fuer"
    assert kl.slugify(unicodedata.normalize("NFD", "Geschäftsidee")) == "geschaeftsidee", "NFD Geschäftsidee"
    # NFKD compatibility decomposition can emit UPPERCASE ASCII; the final
    # lowercase pass folds it instead of the keep-regex dropping it (#303 review).
    assert kl.slugify("№5") == "no5", f"NFKD-uppercase: got {kl.slugify('№5')!r}"
    # max-len truncation preserved (default 80), with no trailing dash.
    long = kl.slugify("a" * 100)
    assert len(long) == 80, f"max-len not enforced: len={len(long)}"
    trimmed = kl.slugify("a" * 79 + " b")
    assert not trimmed.endswith("-"), f"trailing dash after truncation: {trimmed!r}"


def assert_ref_heading():
    # #301/#300: localized reference heading, default/unknown → English.
    assert kl.ref_heading("de") == "Referenzen", kl.ref_heading("de")
    assert kl.ref_heading("DE") == "Referenzen", "case-insensitive"
    assert kl.ref_heading("en") == "References", kl.ref_heading("en")
    assert kl.ref_heading("xx") == "References", "unknown code → English"
    assert kl.ref_heading(None) == "References", "None → English"
    # A non-str language (malformed plan.json) must default to English, not
    # crash on .lower() (#301 review).
    assert kl.ref_heading(5) == "References", "non-str (int) → English, no crash"
    assert kl.ref_heading(True) == "References", "non-str (bool) → English, no crash"


def assert_first_url():
    # JSON inline-list shape (source-ingester) → first http(s) URL.
    assert kl.first_url('["https://example.org/a"]') == "https://example.org/a"
    # Non-JSON fallback: a leaked list-closer is stripped once...
    assert kl.first_url("[https://x.com/a]") == "https://x.com/a"
    # ...but a URL legitimately ending in `]` keeps it (the old charset-rstrip
    # would have eaten it). json path handles this cleanly.
    assert kl.first_url('["https://x.com/p?q=[1]"]') == "https://x.com/p?q=[1]"
    # Block-style / empty / non-URL → "".
    assert kl.first_url("") == ""
    assert kl.first_url("wiki://src-a") == ""
    # file:// is first-class (a local source ingested via --file is stored as
    # file://<abspath>); first_url must return it, not "".
    assert kl.first_url('["file:///abs/path/report.pdf"]') == \
        "file:///abs/path/report.pdf", kl.first_url('["file:///abs/path/report.pdf"]')
    # A file:// path with a literal space is captured WHOLE — not truncated at
    # the space the way a `\\S+` match would (defect 2 of the local-file path).
    got = kl.first_url('["file:///abs/V8_MI_Data_ Sovereign_.pdf"]')
    assert got == "file:///abs/V8_MI_Data_ Sovereign_.pdf", got
    # Non-JSON fallback for a file:// value with a space: rest-of-value match,
    # trailing whitespace/quote stripped, space inside the path preserved.
    got_fb = kl.first_url('file:///abs/V8 Data.pdf')
    assert got_fb == "file:///abs/V8 Data.pdf", got_fb


def assert_extract_inline_citation_urls():
    # http(s) markers extract in appearance order (the established behavior).
    text = 'A<sup>[1](https://a.org/x)</sup>. B<sup>[2](https://b.org/y)</sup>.'
    assert kl.extract_inline_citation_urls(text) == \
        ["https://a.org/x", "https://b.org/y"]
    # file:// is first-class: a local-source citation is extracted, not dropped.
    f = 'C<sup>[3](file:///abs/p.pdf)</sup>.'
    assert kl.extract_inline_citation_urls(f) == ["file:///abs/p.pdf"], \
        kl.extract_inline_citation_urls(f)
    # A file:// URL with a literal space is captured whole (unbracketed branch
    # matches on [^)], so the space does not truncate it).
    fs = 'D<sup>[4](file:///abs/V8 Data.pdf)</sup>.'
    assert kl.extract_inline_citation_urls(fs) == ["file:///abs/V8 Data.pdf"], \
        kl.extract_inline_citation_urls(fs)
    # Angle-bracketed file:// form (md_link_dest brackets a dest with a space).
    fb = 'E<sup>[5](<file:///abs/V8 Data.pdf>)</sup>.'
    assert kl.extract_inline_citation_urls(fb) == ["file:///abs/V8 Data.pdf"], \
        kl.extract_inline_citation_urls(fb)
    # A sentence mixing a file:// and an http citation yields BOTH, in order
    # (the regression that broke citation-store build with url_slug_mismatch).
    mixed = 'F<sup>[6](file:///abs/p.pdf)</sup> and<sup>[7](https://w.org/z)</sup>.'
    assert kl.extract_inline_citation_urls(mixed) == \
        ["file:///abs/p.pdf", "https://w.org/z"], \
        kl.extract_inline_citation_urls(mixed)
    # A bare marker (no URL) and empty text contribute nothing.
    assert kl.extract_inline_citation_urls('G<sup>[8]</sup>.') == []
    assert kl.extract_inline_citation_urls("") == []


def assert_md_link_dest():
    # Paren / space → angle-bracketed so renderers don't truncate the dest at ')'.
    assert kl.md_link_dest("https://en.wikipedia.org/wiki/AI_(disambiguation)") == \
        "<https://en.wikipedia.org/wiki/AI_(disambiguation)>"
    assert kl.md_link_dest("https://x.com/a b") == "<https://x.com/a b>"
    # Plain URL unchanged.
    assert kl.md_link_dest("https://x.com/a") == "https://x.com/a"


def assert_strip_reference_section():
    # Localized (de) heading stripped from a normal body.
    body = "Intro<sup>[1](u)</sup>.\n\n## Referenzen\n\n**[1]** X — [[sources/x]]\n"
    assert "Referenzen" not in kl.strip_reference_section(body, "Referenzen")
    # English heading stripped even when the localized heading is German
    # (mixed-state draft): strip_words contains both.
    body_en = "Intro.\n\n## References\n\n**[1]** X — [[sources/x]]\n"
    assert "References" not in kl.strip_reference_section(body_en, "Referenzen")
    # #301 non-recurrence: heading as the FIRST line (no leading newline) is
    # still matched and stripped.
    body_first = "## Referenzen\n\n**[1]** X — [[sources/x]]\n"
    assert "Referenzen" not in kl.strip_reference_section(body_first, "Referenzen")
    # Safety net: an unrecognized synonym heading whose tail is a PURE reference
    # list is stripped.
    body_syn = 'Intro.\n\n## Quellen\n\n**[1]** X, "T". [u](u) — [[sources/x]]\n'
    assert "Quellen" not in kl.strip_reference_section(body_syn, "Referenzen")
    # Content-preserving: a trailing Recommendations BULLET section is NOT a
    # reference list and MUST survive (no reference heading matched).
    body_rec = "Intro.\n\n## Empfehlungen\n\n- Erstens handeln\n- Zweitens messen\n"
    assert kl.strip_reference_section(body_rec, "Referenzen") == body_rec
    # No reference section at all → unchanged.
    assert kl.strip_reference_section("Just prose.\n", "References") == "Just prose.\n"


def assert_body_word_count():
    # Body words EXCLUDE the reference list — the surface both the compose Step 5.5
    # actuator and the wiki-reviewer Word-Count Gate measure (#456).
    body = "one two three four five"  # 5 body words
    refs = "\n\n## References\n\n**[1]** A — [[sources/a]]\n**[2]** B — [[sources/b]]\n"
    draft = body + refs
    # Total split() would count the reference entries; body_word_count must not.
    assert len(draft.split()) > 5, "fixture must have ref words to exclude"
    assert kl.body_word_count(draft, "en") == 5, kl.body_word_count(draft, "en")
    # Language-aware: a German `## Referenzen` list is stripped just the same.
    draft_de = body + "\n\n## Referenzen\n\n**[1]** A — [[sources/a]]\n"
    assert kl.body_word_count(draft_de, "de") == 5, kl.body_word_count(draft_de, "de")
    # No reference section → counts the whole draft. None lang → English default.
    assert kl.body_word_count("alpha beta gamma\n", None) == 3


def assert_coverage_report():
    # The coverage signal behind knowledge-compose Step 5.5's coverage-gated
    # expansion: per sub-question, which ingested SOURCE slugs are available /
    # cited / uncited, plus the deficit set (sqs with ≥1 uncited available source).
    plan = {"sub_questions": [{"id": "sq-01"}, {"id": "sq-02"}, {"id": "sq-03"}]}
    ingest = {"ingested": [
        {"slug": "src-a", "sub_question_refs": ["sq-01"]},
        {"slug": "src-b", "sub_question_refs": ["sq-01", "sq-02"]},
        {"slug": "src-c", "sub_question_refs": ["sq-03"]},
    ]}
    # sq-01: src-a cited, src-b uncited → deficit; sq-02: src-b uncited & zero-cited;
    # sq-03: src-c uncited & zero-cited. A distilled-slug citation does not count as a
    # source cite (conservative under-count — never a false "cited").
    cite = {"citations": [{"wiki_slug": "src-a"}, {"wiki_slug": "a-concept"}]}
    rep = kl.coverage_report(plan, ingest, cite)
    per = rep["per_sq"]
    assert per["sq-01"] == {"available": ["src-a", "src-b"], "cited": ["src-a"],
                            "uncited": ["src-b"]}, per["sq-01"]
    assert per["sq-02"]["cited"] == [] and per["sq-02"]["uncited"] == ["src-b"], per["sq-02"]
    assert per["sq-03"]["cited"] == [] and per["sq-03"]["uncited"] == ["src-c"], per["sq-03"]
    assert rep["uncited_evidence_sq_ids"] == ["sq-01", "sq-02", "sq-03"], rep["uncited_evidence_sq_ids"]
    # Fully-cited sq → NOT in the deficit set (no expansion).
    full = kl.coverage_report({"sub_questions": [{"id": "sq-01"}]},
                              {"ingested": [{"slug": "src-a", "sub_question_refs": ["sq-01"]}]},
                              {"citations": [{"wiki_slug": "src-a"}]})
    assert full["per_sq"]["sq-01"]["uncited"] == [], full
    assert full["uncited_evidence_sq_ids"] == [], full
    # A sub-question with NO ingested evidence is not a deficit (nothing to cite).
    none_ev = kl.coverage_report({"sub_questions": [{"id": "sq-09"}]},
                                 {"ingested": []}, {"citations": []})
    assert none_ev["per_sq"]["sq-09"] == {"available": [], "cited": [], "uncited": []}, none_ev
    assert none_ev["uncited_evidence_sq_ids"] == [], none_ev
    # Fail-soft: empty / None inputs → no deficit, never raises.
    assert kl.coverage_report({}, {}, {}) == {"per_sq": {}, "uncited_evidence_sq_ids": []}
    assert kl.coverage_report(None, None, None) == {"per_sq": {}, "uncited_evidence_sq_ids": []}
    # A null citation wiki_slug is discarded (never matches an available source).
    nullslug = kl.coverage_report({"sub_questions": [{"id": "sq-01"}]},
                                  {"ingested": [{"slug": "src-a", "sub_question_refs": ["sq-01"]}]},
                                  {"citations": [{"wiki_slug": None}]})
    assert nullslug["uncited_evidence_sq_ids"] == ["sq-01"], nullslug


def assert_renumber_inline_citations():
    import re as _re
    # Full-source-drop gap: body [1][3] → [1][2] matching the re-derived list.
    body = "A<sup>[1](u1)</sup>. B<sup>[3](u3)</sup>, again A<sup>[1](u1)</sup>."
    out = kl.renumber_inline_citations(body)
    assert sorted(set(_re.findall(r"<sup>\[(\d+)\]", out))) == ["1", "2"], out
    assert out.count("<sup>[1]") == 2 and out.count("<sup>[2]") == 1, out
    # Already contiguous → unchanged (no-op).
    contig = "A<sup>[1](u1)</sup>. B<sup>[2](u2)</sup>."
    assert kl.renumber_inline_citations(contig) == contig
    # A plain synthesis marker (no URL) is remapped too: [1][4] → [1][2].
    syn = "A<sup>[1](u1)</sup>. S<sup>[4]</sup>."
    assert "<sup>[2]</sup>" in kl.renumber_inline_citations(syn)


def assert_parse_pre_extracted_claims():
    # Happy path: block-list of dicts; a colon inside the `text` value must NOT
    # break the key:value split (partition on first colon only).
    page = (
        "---\n"
        "type: source\n"
        "pre_extracted_claims:\n"
        "  - id: clm-001\n"
        '    text: "Article 6: high-risk classification rule"\n'
        '    excerpt_quote: "shall be considered high-risk"\n'
        "    excerpt_position: 12\n"
        "    sub_question_refs: [sq-01]\n"
        "  - id: clm-002\n"
        "    text: plain unquoted value\n"
        '    excerpt_quote: "another quote"\n'
        "---\n\n# body\n"
    )
    claims = kl.parse_pre_extracted_claims(page)
    assert len(claims) == 2, claims
    assert claims[0]["id"] == "clm-001", claims[0]
    assert claims[0]["text"] == "Article 6: high-risk classification rule", claims[0]
    assert claims[0]["excerpt_quote"] == "shall be considered high-risk", claims[0]
    assert claims[1]["id"] == "clm-002" and claims[1]["text"] == "plain unquoted value", claims[1]
    # Fail-safe: a page with no closing frontmatter fence yields [] (never raises).
    broken = "---\ntype: source\npre_extracted_claims:\n  - id: clm-009\n\n# no close\n"
    assert kl.parse_pre_extracted_claims(broken) == [], "malformed frontmatter must fail safe to []"
    # No claims key at all → [].
    assert kl.parse_pre_extracted_claims("---\ntype: source\n---\n# body\n") == []
    # Empty / non-frontmatter input → [].
    assert kl.parse_pre_extracted_claims("") == []
    assert kl.parse_pre_extracted_claims("# just a body, no frontmatter\n") == []
    # #305 review: a YAML block-scalar value ('>' / '|') must NOT be captured as
    # the bare indicator (that 1-char needle would false-match). The field is
    # dropped so the claim simply lacks excerpt_quote.
    block = (
        "---\npre_extracted_claims:\n"
        "  - id: clm-bs\n"
        "    excerpt_quote: >\n"
        "      Annex III systems shall be considered high-risk.\n"
        "---\n"
    )
    bsc = kl.parse_pre_extracted_claims(block)
    assert len(bsc) == 1 and bsc[0].get("id") == "clm-bs", bsc
    assert "excerpt_quote" not in bsc[0], "block-scalar indicator must not be captured as a value: " + repr(bsc[0])
    for pipe in ("|", "|-", ">-", ">2"):
        one = kl.parse_pre_extracted_claims("---\npre_extracted_claims:\n  - id: c\n    text: " + pipe + "\n---\n")
        assert "text" not in one[0], "block-scalar " + pipe + " leaked: " + repr(one)
    # Inline YAML comment on an UNQUOTED plain scalar is stripped (a comment needs
    # leading whitespace before '#'); a quoted value keeps '#' verbatim.
    com = kl.parse_pre_extracted_claims(
        "---\npre_extracted_claims:\n  - id: c1\n    text: real value # trailing note\n"
        '    excerpt_quote: "kept # inside quotes"\n---\n'
    )
    assert com[0]["text"] == "real value", com[0]
    assert com[0]["excerpt_quote"] == "kept # inside quotes", com[0]
    # Column-0 block-sequence bullets (legal YAML at the parent key's indent).
    col0 = kl.parse_pre_extracted_claims(
        "---\npre_extracted_claims:\n- id: clm-c0\n  excerpt_quote: \"a contiguous quote\"\ntags: [x]\n---\n"
    )
    assert len(col0) == 1 and col0[0]["id"] == "clm-c0", col0
    assert col0[0]["excerpt_quote"] == "a contiguous quote", col0


def assert_parse_distilled_claims():
    # Canonical concept-store emission shape (claim_id / text / norm_key /
    # backlinks / source_claim_refs / created / updated). Only `text` is absorbed;
    # the writer-side metadata is concept-store-private and must be ignored. A
    # colon inside `text` must NOT break the key:value split (#343).
    page = (
        "---\n"
        "type: concept\n"
        "distilled_claims:\n"
        "  - claim_id: dcl-001\n"
        '    text: "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen."\n'
        '    norm_key: "k1"\n'
        '    backlinks: ["src-a","src-b"]\n'
        '    source_claim_refs: ["src-a#c1"]\n'
        "    created: 2026-05-29\n"
        "    updated: 2026-05-29\n"
        "  - claim_id: dcl-002\n"
        '    text: "Zweite distillierte Aussage."\n'
        "---\n\n# body\n"
    )
    claims = kl.parse_distilled_claims(page)
    assert len(claims) == 2, claims
    assert claims[0] == {"text": "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen."}, claims[0]
    assert set(claims[0]) == {"text"}, "writer-side metadata must be ignored: " + repr(claims[0])
    assert claims[1] == {"text": "Zweite distillierte Aussage."}, claims[1]
    # Inline `distilled_claims: []` (concept-store's empty form) → []. _DISTILLED_KEY_RE
    # anchors on '$' so the key-with-inline-value line deliberately does not match.
    assert kl.parse_distilled_claims("---\ntype: concept\ndistilled_claims: []\n---\n# body\n") == []
    # The key on its own line but with no bullets → [].
    assert kl.parse_distilled_claims("---\ndistilled_claims:\ntype: concept\n---\n") == []
    # No claims key at all / empty / no-frontmatter → [] (fail-safe).
    assert kl.parse_distilled_claims("---\ntype: concept\n---\n# body\n") == []
    assert kl.parse_distilled_claims("") == []
    assert kl.parse_distilled_claims("# just a body\n") == []
    # Malformed (no closing fence) → [] (never raises).
    assert kl.parse_distilled_claims("---\ndistilled_claims:\n  - claim_id: dcl-x\n\n# no close\n") == []
    # Block-scalar `text: |` must NOT leak the bare 1-char indicator (same #305
    # guarantee as the pre_extracted parser — both share _parse_claim_block).
    for pipe in ("|", "|-", ">-", ">2"):
        one = kl.parse_distilled_claims("---\ndistilled_claims:\n  - claim_id: c\n    text: " + pipe + "\n---\n")
        assert "text" not in one[0], "block-scalar " + pipe + " leaked: " + repr(one)


def assert_parse_distilled_claims_with_id():
    # verify-store.py's prefilter (#362) keys a distilled citation by claim_id, so
    # this variant absorbs `claim_id` AND `text` (distilled claims have no
    # `excerpt_quote`); the rest of the writer-side metadata stays ignored.
    page = (
        "---\n"
        "type: concept\n"
        "distilled_claims:\n"
        "  - claim_id: dcl-001\n"
        '    text: "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen."\n'
        '    norm_key: "k1"\n'
        '    backlinks: ["src-a","src-b"]\n'
        '    source_claim_refs: ["src-a#c1"]\n'
        "    created: 2026-05-29\n"
        "    updated: 2026-05-29\n"
        "  - claim_id: dcl-002\n"
        '    text: "Zweite distillierte Aussage."\n'
        "---\n\n# body\n"
    )
    claims = kl.parse_distilled_claims_with_id(page)
    assert len(claims) == 2, claims
    assert claims[0] == {"claim_id": "dcl-001",
                         "text": "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen."}, claims[0]
    assert set(claims[0]) == {"claim_id", "text"}, "only claim_id+text wanted: " + repr(claims[0])
    assert claims[1] == {"claim_id": "dcl-002", "text": "Zweite distillierte Aussage."}, claims[1]
    # Same fail-safe contract as the text-only sibling: inline [] / no bullets /
    # no key / empty / no-frontmatter / unterminated → [] (never raises).
    assert kl.parse_distilled_claims_with_id("---\ntype: concept\ndistilled_claims: []\n---\n# body\n") == []
    assert kl.parse_distilled_claims_with_id("---\ndistilled_claims:\ntype: concept\n---\n") == []
    assert kl.parse_distilled_claims_with_id("---\ntype: concept\n---\n# body\n") == []
    assert kl.parse_distilled_claims_with_id("") == []
    assert kl.parse_distilled_claims_with_id("---\ndistilled_claims:\n  - claim_id: dcl-x\n\n# no close\n") == []


def assert_parse_answer_claims_with_id():
    # #432: question nodes carry `answer_claims:` — same per-claim shape as
    # distilled_claims (acl-NNN ids, no excerpt_quote). verify-store keys an answer
    # citation by claim_id, so this absorbs claim_id + text only (writer-side metadata
    # ignored), byte-symmetric with parse_distilled_claims_with_id.
    page = (
        "---\n"
        "id: q-high-risk\n"
        "type: question\n"
        "answer_claims:\n"
        "  - claim_id: acl-001\n"
        '    text: "Annex III lists eight categories of high-risk AI systems."\n'
        '    norm_key: "k1"\n'
        '    backlinks: ["src-a","src-b"]\n'
        '    source_claim_refs: ["src-a#clm-003"]\n'
        "    created: 2026-06-02\n"
        "    updated: 2026-06-02\n"
        "  - claim_id: acl-002\n"
        '    text: "High-risk systems must be registered in the EU database."\n'
        "sources_answering: [src-a, src-b]\n"
        "---\n\n## Findings\n\n- [[src-a]]\n"
    )
    claims = kl.parse_answer_claims_with_id(page)
    assert len(claims) == 2, claims
    assert claims[0] == {"claim_id": "acl-001",
                         "text": "Annex III lists eight categories of high-risk AI systems."}, claims[0]
    assert set(claims[0]) == {"claim_id", "text"}, "only claim_id+text wanted: " + repr(claims[0])
    assert claims[1] == {"claim_id": "acl-002",
                         "text": "High-risk systems must be registered in the EU database."}, claims[1]
    # Same fail-safe contract as the distilled sibling: inline [] / no key / empty /
    # unterminated → [] (never raises).
    assert kl.parse_answer_claims_with_id("---\ntype: question\nanswer_claims: []\n---\n# body\n") == []
    assert kl.parse_answer_claims_with_id("---\ntype: question\n---\n# body\n") == []
    assert kl.parse_answer_claims_with_id("") == []
    assert kl.parse_answer_claims_with_id("---\nanswer_claims:\n  - claim_id: acl-x\n\n# no close\n") == []
    # The acl- prefix classifies as the `answer` kind (forward-ready, #432).
    assert kl.classify_claim_kind("acl-007") == "answer", kl.classify_claim_kind("acl-007")
    assert kl.classify_claim_kind("dcl-1") == "distilled" and kl.classify_claim_kind("clm-1") == "source"


def assert_parse_answer_records():
    # #432: the answer-distiller writes `- question: <slug>` blocks with repeatable
    # `answer_claim:` lines (same 3-part `<slug> | <id> | <text>` as concept records).
    text = (
        "- question: q-high-risk\n"
        "  answer_claim: src-a | clm-003 | Annex III lists eight categories.\n"
        "  answer_claim: src-b | clm-001 | Eight categories are enumerated.\n"
        "- question: q-gpai\n"
        "  answer_claim: gpai-code | clm-002 | GPAI duties begin 12 months after entry.\n"
    )
    recs = kl.parse_answer_records(text)
    assert len(recs) == 2, recs
    assert recs[0]["slug"] == "q-high-risk" and len(recs[0]["claims"]) == 2, recs[0]
    assert recs[0]["claims"][0] == {"source_slug": "src-a", "source_claim_id": "clm-003",
                                    "text": "Annex III lists eight categories."}, recs[0]["claims"][0]
    assert recs[1]["slug"] == "q-gpai" and len(recs[1]["claims"]) == 1, recs[1]
    # 3-part form: a claim text containing a pipe keeps everything after the 2nd ' | '.
    pipe = kl.parse_answer_records("- question: q\n  answer_claim: s | c | a | b | c\n")
    assert pipe[0]["claims"][0]["text"] == "a | b | c", pipe[0]["claims"][0]
    # Tolerated 2-part ref form `<slug>#<id> | <text>` whose text contains ` | `.
    rp = kl.parse_answer_records("- question: q\n  answer_claim: src-a#clm-001 | Article 6 | paragraph 2\n")
    assert rp[0]["claims"][0] == {"source_slug": "src-a", "source_claim_id": "clm-001",
                                  "text": "Article 6 | paragraph 2"}, rp[0]["claims"][0]
    # `question:` may sit inline after the bullet.
    inline = kl.parse_answer_records("- question: q-inline\n")
    assert inline[0]["slug"] == "q-inline" and inline[0]["claims"] == [], inline
    # A record missing its question: is emitted with an empty slug (NOT dropped).
    noq = kl.parse_answer_records("- answer_claim: s | c | t\n")
    assert noq[0]["slug"] == "" and len(noq[0]["claims"]) == 1, noq
    # CRLF tolerance + empty input → [].
    crlf = kl.parse_answer_records("- question: z\r\n  answer_claim: s | c | t\r\n")
    assert crlf[0]["slug"] == "z", crlf
    assert kl.parse_answer_records("") == []


def assert_strip_inline_citation_markers():
    # Strips the whole marker (with or without a URL), leaving the prose; the
    # verify prefilter uses this to compare a sentence's text against a claim.
    assert kl.strip_inline_citation_markers(
        "AI systems are high-risk<sup>[3](https://x.eu/c)</sup>.") == "AI systems are high-risk."
    assert kl.strip_inline_citation_markers("A synthesis claim<sup>[2]</sup>.") == "A synthesis claim."
    # Multiple markers in one sentence.
    assert kl.strip_inline_citation_markers(
        "A<sup>[1](u1)</sup> and B<sup>[2](u2)</sup>.") == "A and B."
    # No markers → unchanged.
    assert kl.strip_inline_citation_markers("plain text") == "plain text"


def assert_tokenization_primitives():
    # #336: the tokenization primitives lifted from wiki-coverage.py now live
    # here. Spot-check the contract the lift must preserve.
    # Folding: German umlaut survives the [^a-z0-9]+ split (geschaeftsidee, one token).
    assert "geschaeftsidee" in kl.tokenize("Geschäftsidee"), kl.tokenize("Geschäftsidee")
    # Stopwords + <3 drop, digits kept at any length (article-number anchors).
    toks = kl.tokenize("Article 6 and the high-risk system")
    assert "6" in toks, toks            # digit anchor kept
    assert "the" not in toks and "and" not in toks, toks  # stopwords dropped
    # token_weight: denylist → 0.0 (checked first); digit → x3.0; longer → higher.
    assert kl.token_weight("system") == 0.0, "denylisted token must be 0"
    assert kl.token_weight("2025") == 0.0, "denylisted year must be 0 (no digit boost)"
    assert kl.token_weight("6") == 0.4 * 3.0, kl.token_weight("6")  # short digit, clamped base x3
    assert kl.token_weight("classification") == 1.0, kl.token_weight("classification")
    # compound_match: German compound by prefix; symmetric; rejects boilerplate stem.
    assert kl.compound_match("bussgelder", "bussgeldsystem"), "compound prefix match"
    assert kl.compound_match("bussgeldsystem", "bussgelder"), "compound match is symmetric"
    assert not kl.compound_match("system", "systemverwaltung"), "denylisted token never matches"
    assert not kl.compound_match("art", "artikel"), "too-short prefix rejected"


def assert_norm_key():
    # Same fact differing ONLY in stopwords/denylist (the, AI, system, is, of) →
    # same key (those carry no discriminative signal and are dropped).
    a = "the AI system classification is high-risk"
    b = "high-risk classification of the system"
    assert kl.norm_key(a) == kl.norm_key(b), (kl.norm_key(a), kl.norm_key(b))
    # Deterministic + sorted.
    assert kl.norm_key("risk high 6") == kl.norm_key("6 high risk")
    # All-boilerplate / empty → "" (caller must treat as "no exact match").
    assert kl.norm_key("the system and the AI") == "", repr(kl.norm_key("the system and the AI"))
    assert kl.norm_key("") == ""


def assert_theme_norm_key():
    # Order- and stopword-independent token-set equality (#409): a recurring
    # theme phrased differently across runs maps to ONE key → one question node.
    assert kl.theme_norm_key("Records of Processing Scope") == \
        kl.theme_norm_key("Scope of Processing Records"), \
        (kl.theme_norm_key("Records of Processing Scope"),
         kl.theme_norm_key("Scope of Processing Records"))
    # DE transliteration + folding: "für" folds to a stopword, order ignored.
    assert kl.theme_norm_key("Pflichten für Risikoklassen") == \
        kl.theme_norm_key("Risikoklassen Pflichten"), \
        repr(kl.theme_norm_key("Pflichten für Risikoklassen"))
    # KEEP-SEPARATE guard — the whole reason it is NOT norm_key: the denylisted
    # boilerplate tokens (act/system) are the discriminator between two distinct
    # themes, so they MUST be kept. norm_key would collapse both to "scope".
    assert kl.theme_norm_key("AI Act Scope") != kl.theme_norm_key("AI System Scope"), \
        repr(kl.theme_norm_key("AI Act Scope"))
    assert kl.norm_key("AI Act Scope") == kl.norm_key("AI System Scope"), \
        "regression sentinel: norm_key DOES false-merge these (why theme uses tokenize)"
    # Empty / stopword-only → "" so the caller falls back to slugify and never
    # records an empty key that would match every empty-theme label.
    assert kl.theme_norm_key("of the") == "", repr(kl.theme_norm_key("of the"))
    assert kl.theme_norm_key("") == ""


def assert_claim_similarity():
    # Identical discriminative content → 1.0.
    assert kl.claim_similarity("high-risk classification scope",
                               "high-risk classification scope") == 1.0
    # Reworded same fact clears the 0.85 dedup bar.
    s = kl.claim_similarity(
        "Annex III lists eight categories of high-risk AI systems.",
        "Annex III lists the eight high-risk AI system categories.")
    assert s >= 0.85, f"reworded-same should merge, got {s}"
    # Genuinely different facts stay well below the bar (fail-safe under-merge).
    s2 = kl.claim_similarity(
        "Member states must designate a supervisory authority.",
        "The penalty ceiling is thirty five million euros.")
    assert s2 < 0.85, f"distinct facts must not merge, got {s2}"
    # All-boilerplate / empty side → 0.0 (keep both).
    assert kl.claim_similarity("the system and the AI", "the system and the AI") == 0.0
    assert kl.claim_similarity("", "anything at all here") == 0.0
    # Symmetric.
    x, y = "high-risk classification rules", "rules for high-risk classification"
    assert kl.claim_similarity(x, y) == kl.claim_similarity(y, x), "similarity must be symmetric"


def assert_parse_concept_records():
    text = (
        "- title: Annex III Categories\n"
        "  type: concept\n"
        "  summary: Categories of high-risk AI systems: the core list.\n"
        "  related: conformity-assessment, gpai-obligations\n"
        "  claim: src-a | clm-003 | Annex III lists eight categories.\n"
        "  claim: src-b | clm-001 | Annex III enumerates the categories.\n"
        "- title: European Commission\n"
        "  type: entity\n"
        "  claim: src-b | clm-002 | The Commission issued the Code.\n"
    )
    recs = kl.parse_concept_records(text)
    assert len(recs) == 2, recs
    r0 = recs[0]
    assert r0["title"] == "Annex III Categories" and r0["type"] == "concept", r0
    # A colon inside the summary must survive (partition on first colon only).
    assert r0["summary"] == "Categories of high-risk AI systems: the core list.", r0["summary"]
    assert r0["related"] == ["conformity-assessment", "gpai-obligations"], r0["related"]
    assert len(r0["claims"]) == 2, r0["claims"]
    assert r0["claims"][0] == {"source_slug": "src-a", "source_claim_id": "clm-003",
                               "text": "Annex III lists eight categories."}, r0["claims"][0]
    # entity record with a single claim.
    assert recs[1]["type"] == "entity" and len(recs[1]["claims"]) == 1, recs[1]
    # 3-part form: a claim text containing a pipe keeps everything after the 2nd ' | '.
    pipe = kl.parse_concept_records("- title: T\n  claim: s | c | a | b | c\n")
    assert pipe[0]["claims"][0]["text"] == "a | b | c", pipe[0]["claims"][0]
    # Tolerated 2-part ref form `<slug>#<id> | <text>`.
    ref = kl.parse_concept_records("- title: T\n  claim: src-x#clm-009 | A claim.\n")
    assert ref[0]["claims"][0] == {"source_slug": "src-x", "source_claim_id": "clm-009",
                                   "text": "A claim."}, ref[0]["claims"][0]
    # 2-part ref form whose TEXT contains ` | ` must keep the whole text (disambiguate
    # on the `#` in the first segment, not on pipe count). Regression for the
    # split("|", 2) mis-split that fabricated claim_id='Article 6'.
    rp = kl.parse_concept_records("- title: T\n  claim: src-a#clm-001 | Article 6 | paragraph 2\n")
    assert rp[0]["claims"][0] == {"source_slug": "src-a", "source_claim_id": "clm-001",
                                  "text": "Article 6 | paragraph 2"}, rp[0]["claims"][0]
    # A no-`#` line with only ONE pipe (3-part form missing its text field) →
    # empty text, so concept-store's guard rejects it (the reject-driver is the
    # empty text, regardless of how the single field is bucketed).
    bad = kl.parse_concept_records("- title: T\n  claim: src-a | just text no id\n")
    assert bad[0]["claims"][0]["text"] == "", bad[0]["claims"][0]
    # Empty input → [].
    assert kl.parse_concept_records("") == []


def assert_parse_citation_records():
    # #395: the optional `url:` line parses into a structured per-citation field;
    # a record without it (legacy / synthesis) defaults url to "".
    text = (
        "- id: cit-001\n"
        "  pos: 02:03\n"
        "  slug: source-a\n"
        "  claim: clm-001\n"
        "  url: https://a.eu/page\n"
        "  sentence: Fact from A<sup>[1](https://a.eu/page)</sup>.\n"
        "- id: cit-002\n"
        "  pos: 02:05\n"
        "  slug: a-synthesis\n"
        "  claim: null\n"
        "  sentence: A synthesis draw<sup>[2]</sup>.\n"
    )
    recs = kl.parse_citation_records(text)
    assert len(recs) == 2, recs
    r0 = recs[0]
    assert r0["id"] == "cit-001" and r0["wiki_slug"] == "source-a", r0
    assert r0["claim_id"] == "clm-001" and r0["draft_position"] == "02:03", r0
    # The url: line is captured; the `://` survives the first-colon partition.
    assert r0["url"] == "https://a.eu/page", r0["url"]
    assert r0["draft_sentence"] == "Fact from A<sup>[1](https://a.eu/page)</sup>.", r0["draft_sentence"]
    # Synthesis record: claim null → None, and the absent url: line defaults to "".
    assert recs[1]["claim_id"] is None and recs[1]["url"] == "", recs[1]
    # Empty input → [].
    assert kl.parse_citation_records("") == []


def assert_extract_machine_block():
    page = ("x\n<!-- MACHINE-OWNED:SUMMARY:START -->\n## Summary\n\nHello.\n"
            "<!-- MACHINE-OWNED:SUMMARY:END -->\ntail\n")
    # Inner is returned verbatim INCLUDING its own `## Heading`.
    assert kl.extract_machine_block(page, "SUMMARY") == "## Summary\n\nHello.", \
        repr(kl.extract_machine_block(page, "SUMMARY"))
    # Absent block → None (not "").
    assert kl.extract_machine_block(page, "CLAIMS") is None
    # CRLF tolerance — matches the _FRONTMATTER_RE convention.
    crlf = "<!-- MACHINE-OWNED:SUMMARY:START -->\r\nA.\r\n<!-- MACHINE-OWNED:SUMMARY:END -->\r\n"
    assert kl.extract_machine_block(crlf, "SUMMARY") == "A.", repr(kl.extract_machine_block(crlf, "SUMMARY"))
    # Parity with concept-store.py's private delegate (single source of truth).
    cstore = load("concept_store", "concept-store.py")
    assert cstore._extract_machine_block(page, "SUMMARY") == kl.extract_machine_block(page, "SUMMARY")


def assert_replace_machine_block():
    page = ("# T\n<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->\nold\n"
            "<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:END -->\n\n## Recent syntheses\n- a\n")
    r = kl.replace_machine_block(page, "OVERVIEW-NARRATIVE", "new prose")
    assert kl.extract_machine_block(r, "OVERVIEW-NARRATIVE") == "new prose", repr(r)
    assert "old" not in r and "## Recent syntheses" in r and "- a" in r, repr(r)
    # Absent block → input returned unchanged (no insert — that's upsert's job).
    assert kl.replace_machine_block("# T\nbody\n", "OVERVIEW-NARRATIVE", "x") == "# T\nbody\n"
    # Parity with concept-store.py's private delegate (single source of truth, #491).
    cstore = load("concept_store", "concept-store.py")
    assert cstore._replace_machine_block(page, "OVERVIEW-NARRATIVE", "z") == \
        kl.replace_machine_block(page, "OVERVIEW-NARRATIVE", "z")


def assert_upsert_machine_block():
    # Insert-when-absent: lands after the H1, above existing content.
    page = "# Overview\n\n## Recent syntheses\n- a\n"
    u = kl.upsert_machine_block(page, "OVERVIEW-NARRATIVE", "fresh")
    assert kl.extract_machine_block(u, "OVERVIEW-NARRATIVE") == "fresh", repr(u)
    assert u.index("OVERVIEW-NARRATIVE") < u.index("Recent syntheses"), repr(u)
    assert u.startswith("# Overview\n"), repr(u[:40])
    assert "## Recent syntheses" in u and "- a" in u
    # Replace-when-present: only the inner changes; Recent syntheses preserved.
    u2 = kl.upsert_machine_block(u, "OVERVIEW-NARRATIVE", "fresher")
    assert kl.extract_machine_block(u2, "OVERVIEW-NARRATIVE") == "fresher"
    assert "fresh\n" not in u2.replace("fresher", "") and "## Recent syntheses" in u2
    # Idempotent: identical inner → byte-identical text.
    assert kl.upsert_machine_block(u2, "OVERVIEW-NARRATIVE", "fresher") == u2
    # No H1 → block prepended.
    np = kl.upsert_machine_block("body only\n", "OVERVIEW-NARRATIVE", "x")
    assert np.startswith("<!-- MACHINE-OWNED:OVERVIEW-NARRATIVE:START -->"), repr(np[:60])
    assert kl.extract_machine_block(np, "OVERVIEW-NARRATIVE") == "x"


def assert_parse_portal_records():
    text = (
        "- theme: Syntheses\n"
        "  <<<LEADIN\n"
        "  Why syntheses matter.\n"
        "  Read the latest first.\n"
        "  LEADIN\n"
        "- theme: Questions\n"
        "  <<<LEADIN\n"
        "  The open questions.\n"
        "  LEADIN\n"
        "- overview:\n"
        "  <<<NARRATIVE\n"
        "  State of the wiki across runs.\n"
        "  NARRATIVE\n"
    )
    p = kl.parse_portal_records(text)
    assert p["theme_leadins"]["Syntheses"] == "Why syntheses matter.\nRead the latest first.", p
    assert p["theme_leadins"]["Questions"] == "The open questions.", p
    assert p["overview"] == "State of the wiki across runs.", p
    # Empty block dropped; empty overview → None.
    p2 = kl.parse_portal_records("- theme: Empty\n  <<<LEADIN\n  LEADIN\n")
    assert p2["theme_leadins"] == {} and p2["overview"] is None, p2
    # Last block for a theme wins; '' → empty.
    p3 = kl.parse_portal_records(
        "- theme: T\n  <<<LEADIN\n  first\n  LEADIN\n- theme: T\n  <<<LEADIN\n  second\n  LEADIN\n"
    )
    assert p3["theme_leadins"]["T"] == "second", p3
    assert kl.parse_portal_records("") == {"theme_leadins": {}, "overview": None}
    # CRLF tolerance.
    crlf = "- theme: X\r\n  <<<LEADIN\r\n  prose\r\n  LEADIN\r\n"
    assert kl.parse_portal_records(crlf)["theme_leadins"]["X"] == "prose"


def assert_parse_renarrate_records():
    text = (
        "- slug: high-risk-classification\n"
        "  <<<SUMMARY\n"
        "  Annex III lists eight categories.\n"
        "  A system is high-risk when a safety component.\n"
        "  SUMMARY\n"
        "- slug: european-commission\n"
        "  <<<SUMMARY\n"
        "  The Commission issued the GPAI Code in 2025.\n"
        "  SUMMARY\n"
        "- slug: empty-one\n"
        "  <<<SUMMARY\n"
        "  SUMMARY\n"
    )
    r = kl.parse_renarrate_records(text)
    # Multi-line prose preserved; common 2-space margin dedented.
    assert r["high-risk-classification"] == (
        "Annex III lists eight categories.\n"
        "A system is high-risk when a safety component."), repr(r["high-risk-classification"])
    assert r["european-commission"] == "The Commission issued the GPAI Code in 2025."
    # A slug with empty prose is OMITTED (the script then leaves the page untouched).
    assert "empty-one" not in r, r
    # A later block for the same slug wins.
    dup = kl.parse_renarrate_records(
        "- slug: x\n  <<<SUMMARY\n  first\n  SUMMARY\n- slug: x\n  <<<SUMMARY\n  second\n  SUMMARY\n")
    assert dup["x"] == "second", dup
    # Unterminated trailing block (no closing SUMMARY) still captures to EOF.
    eof = kl.parse_renarrate_records("- slug: y\n  <<<SUMMARY\n  tail line\n")
    assert eof["y"] == "tail line", eof
    # CRLF tolerance.
    crlf = kl.parse_renarrate_records("- slug: z\r\n  <<<SUMMARY\r\n  zee\r\n  SUMMARY\r\n")
    assert crlf["z"] == "zee", crlf
    # Empty input → {}.
    assert kl.parse_renarrate_records("") == {}


def assert_digit_anchor_tokens():
    # Article numbers are the cross-lingual anchors; "Artikel 99" and "Article 99"
    # both yield {"99"} — the only deterministic DE↔EN bridge (#345).
    assert kl.digit_anchor_tokens("Verstöße gegen Artikel 99 ...") == {"99"}
    assert kl.digit_anchor_tokens("Infringements under Article 99 ...") == {"99"}
    # Multiple anchors are all kept.
    assert kl.digit_anchor_tokens("Artikel 6 und Anhang 99 zusammen") == {"6", "99"}
    # GENERIC_DENYLIST years are NOT anchors (token_weight zeroes them before the
    # digit ×3.0 boost) — guards against a year masquerading as an article number.
    assert kl.digit_anchor_tokens("In 2025 the rule applies") == set(), \
        kl.digit_anchor_tokens("In 2025 the rule applies")
    # No digits → empty.
    assert kl.digit_anchor_tokens("Die nationale Aufsichtsbehörde überwacht.") == set()
    assert kl.digit_anchor_tokens("") == set()


def assert_parse_crossmerge_records():
    text = (
        "# a comment line is ignored\n"
        "merge: sanctions-regime | dcl-001 | dcl-002\n"
        "\n"
        "merge:  high-risk  |  dcl-003  |  dcl-009 \n"   # surrounding whitespace stripped
        "merge: bad | only-two-fields\n"                  # wrong arity → dropped
        "merge: empty | dcl-1 | \n"                       # empty field → dropped
        "not-a-merge-line\n"                              # no `merge:` → dropped
    )
    r = kl.parse_crossmerge_records(text)
    assert r == [
        {"slug": "sanctions-regime", "survivor_id": "dcl-001", "absorbed_id": "dcl-002"},
        {"slug": "high-risk", "survivor_id": "dcl-003", "absorbed_id": "dcl-009"},
    ], r
    # CRLF tolerance.
    crlf = kl.parse_crossmerge_records("merge: z | dcl-1 | dcl-2\r\n")
    assert crlf == [{"slug": "z", "survivor_id": "dcl-1", "absorbed_id": "dcl-2"}], crlf
    # Empty input → [].
    assert kl.parse_crossmerge_records("") == []


def assert_writer_quality_normalizers():
    # #309 P2: the four resolution helpers used by knowledge-plan Step 0.5 to keep
    # the precedence chain robust to a malformed binding default or a typo'd flag.
    # tone: valid passes (case-insensitive); unknown/empty → objective.
    assert kl.normalize_tone("analytical") == "analytical"
    assert kl.normalize_tone("EXECUTIVE") == "executive", "case-insensitive"
    assert kl.normalize_tone("nonsense") == "objective", "unknown → objective"
    assert kl.normalize_tone("") == "objective" and kl.normalize_tone(None) == "objective"
    # prose_density: standard|executive; unknown/empty → executive.
    assert kl.normalize_prose_density("executive") == "executive"
    assert kl.normalize_prose_density("Standard") == "standard"
    assert kl.normalize_prose_density("dense") == "executive" and kl.normalize_prose_density(None) == "executive"
    # citation_format: ieee/chicago/apa/mla/harvard valid; wikilink→ieee; unknown→ieee.
    assert kl.normalize_citation_format("chicago") == "chicago"
    assert kl.normalize_citation_format("APA") == "apa"
    assert kl.normalize_citation_format("wikilink") == "ieee", "deprecated alias → ieee"
    assert kl.normalize_citation_format("bibtex") == "ieee" and kl.normalize_citation_format("") == "ieee"
    # CITATION_FAMILY: numbered (ieee/chicago) vs author_date (apa/mla/harvard).
    assert kl.CITATION_FAMILY["ieee"] == "numbered" and kl.CITATION_FAMILY["chicago"] == "numbered"
    assert kl.CITATION_FAMILY["apa"] == "author_date"
    # target_words: positive int; non-positive/unparseable → default 2000 (or given default).
    assert kl.normalize_target_words(4000) == 4000
    assert kl.normalize_target_words("8000") == 8000, "string coerces"
    assert kl.normalize_target_words(0) == 2000 and kl.normalize_target_words(-3) == 2000
    assert kl.normalize_target_words("abc") == 2000 and kl.normalize_target_words(None) == 2000
    assert kl.normalize_target_words(0, default=3000) == 3000, "custom default honoured"


def assert_extract_page_frontmatter():
    # The two shared parsers behind the ingest integrity check (sweep + the
    # source-ingester Phase 3 guard read through the SAME functions so they
    # cannot drift). extract_page_id_and_url: id (unquoted, kebab) + first
    # sources URL from the JSON-list shape.
    page = (
        '---\n'
        'id: my-source\n'
        'type: source\n'
        'sources: ["https://europa.eu/doc?utm_source=x"]\n'
        'content_hash: "sha256:abc123"\n'
        '---\n'
        '# My Source\n\nbody\n'
    )
    obs_id, obs_url = kl.extract_page_id_and_url(page)
    assert obs_id == "my-source", obs_id
    assert obs_url == "https://europa.eu/doc?utm_source=x", obs_url
    # extract_page_content_hash: quoted value unquoted via _unquote_scalar.
    assert kl.extract_page_content_hash(page) == "sha256:abc123", kl.extract_page_content_hash(page)
    # Unquoted value + a trailing YAML inline comment is stripped (unquoted only).
    unq = '---\nid: x\ncontent_hash: sha256:bare # provenance\n---\nbody\n'
    assert kl.extract_page_content_hash(unq) == "sha256:bare", kl.extract_page_content_hash(unq)
    # Absent key → "" (fail-safe: the leg skips rather than false-flagging).
    absent = '---\nid: x\nsources: ["https://e.org/a"]\n---\nbody\n'
    assert kl.extract_page_content_hash(absent) == "", kl.extract_page_content_hash(absent)
    # No frontmatter at all → "".
    assert kl.extract_page_content_hash("# just a body\n") == ""


def assert_resolve_wiki_scripts():
    # The single Python definition of the wiki-scripts resolve probe (#488),
    # shared by the standalone migrate-question-index.py driver so it is no
    # longer a second independent copy of the bash ranking rule.
    # Negative case (hermetic, always on): an unknown skill matches neither the
    # sibling checkout nor any versioned-cache dir → FileNotFoundError, and the
    # message carries the skill name + the --wiki-scripts-dir escape hatch.
    try:
        kl.resolve_wiki_scripts("__nonexistent_skill__")
        assert False, "expected FileNotFoundError for an unknown skill"
    except FileNotFoundError as exc:
        assert "__nonexistent_skill__" in str(exc), str(exc)
        assert "--wiki-scripts-dir" in str(exc), str(exc)
    # Real-layout case: vendored-first (Phase 7). In-tree, cogni-knowledge ships
    # a byte-identical copy of the engine under scripts/vendor/, which the
    # production (base_dir=None) probe returns BEFORE the external cogni-wiki
    # sibling. Assert the vendored dir when present; fall back to the sibling
    # only on a partial checkout that lacks the vendored copy.
    repo_root = scripts.parent.parent  # scripts/ -> cogni-knowledge/ -> repo-root
    vendored = scripts / "vendor" / "cogni-wiki" / "skills" / "wiki-ingest" / "scripts"
    sib = repo_root / "cogni-wiki" / "skills" / "wiki-ingest" / "scripts"
    if vendored.is_dir():
        got = kl.resolve_wiki_scripts("wiki-ingest")
        assert got.resolve() == vendored.resolve(), f"got={got!r} expected vendored={vendored!r}"
    elif sib.is_dir():
        got = kl.resolve_wiki_scripts("wiki-ingest")
        assert got.resolve() == sib.resolve(), f"got={got!r} expected sibling={sib!r}"
    # Versioned-cache ranking branch (hermetic, via the base_dir test seam):
    # no sibling checkout under <base> forces fall-through to branch 2, where
    # the NEWEST numeric version dir must win and a non-numeric `main` checkout
    # must be excluded by _NUMERIC_VERSION_RE — the branch the real-layout case
    # above can never reach (the live sibling short-circuits branch 1).
    base = work / "wiki-version-fixture" / "insight-wave"  # synthetic <repo-root>
    cache = base.parent / "cogni-wiki"  # <repo-root>.parent/cogni-wiki/*/skills/...
    for ver in ("0.0.9", "0.0.16", "0.1.2", "main"):
        (cache / ver / "skills" / "wiki-ingest" / "scripts").mkdir(parents=True, exist_ok=True)
    # No <base>/cogni-wiki/skills/wiki-ingest/scripts → branch 1 misses.
    assert not (base / "cogni-wiki" / "skills" / "wiki-ingest" / "scripts").exists()
    got = kl.resolve_wiki_scripts("wiki-ingest", base_dir=base)
    expected = cache / "0.1.2" / "skills" / "wiki-ingest" / "scripts"
    assert got.resolve() == expected.resolve(), f"version ranking: got={got!r} expected={expected!r}"
    assert got.parents[2].name == "0.1.2", f"non-numeric 'main' must not win: {got!r}"
    # #536 entry-point existence: with expected_script set, a cache dir that
    # lacks the script is skipped — so a partial cache falls through to the
    # newest version that DOES carry it. The newest (0.1.2) has no script here;
    # only 0.0.16 gets one, so it must win despite being older.
    (cache / "0.0.16" / "skills" / "wiki-ingest" / "scripts" / "wiki_index_update.py").write_text("# stub\n")
    got_ep = kl.resolve_wiki_scripts("wiki-ingest", base_dir=base, expected_script="wiki_index_update.py")
    expected_ep = cache / "0.0.16" / "skills" / "wiki-ingest" / "scripts"
    assert got_ep.resolve() == expected_ep.resolve(), f"entry-point skip: got={got_ep!r} expected={expected_ep!r}"
    # expected_script=None preserves the historic dir-only behaviour: 0.1.2 wins.
    got_none = kl.resolve_wiki_scripts("wiki-ingest", base_dir=base, expected_script=None)
    assert got_none.parents[2].name == "0.1.2", f"dir-only (None) must still pick 0.1.2: {got_none!r}"
    # No cache dir carries the named entry-point -> FileNotFoundError (the
    # partial vendor no longer masks the missing script).
    try:
        kl.resolve_wiki_scripts("wiki-ingest", base_dir=base, expected_script="__no_such_script__.py")
        assert False, "expected FileNotFoundError when no cache dir carries the entry-point"
    except FileNotFoundError as exc:
        assert "wiki-ingest" in str(exc), str(exc)


def assert_parse_synthesis_sources():
    # Bare wiki://<slug> block list (the shape knowledge-finalize writes).
    page = (
        "---\n"
        "id: syn-a\n"
        "type: synthesis\n"
        "sources:\n"
        "  - wiki://src-a\n"
        "  - wiki://src-b\n"
        "derived_from_research: proj-1\n"
        "---\n"
        "body\n"
    )
    assert kl.parse_synthesis_sources(page) == ["src-a", "src-b"], kl.parse_synthesis_sources(page)
    # Legacy composite wiki://<wiki>/<slug> → last path segment.
    legacy = "---\nsources:\n  - wiki://eu-ai-act/src-c\n  - wiki://src-d\n---\n"
    assert kl.parse_synthesis_sources(legacy) == ["src-c", "src-d"], kl.parse_synthesis_sources(legacy)
    # Comment line inside the block is skipped; block ends at the next top-level key.
    commented = "---\nsources:\n  # a comment\n  - wiki://src-e\ntags: [synthesis]\n---\n"
    assert kl.parse_synthesis_sources(commented) == ["src-e"], kl.parse_synthesis_sources(commented)
    # An INLINE source-page `sources: ["<URL>"]` is NOT a block list → [].
    inline = '---\nid: src-x\ntype: source\nsources: ["https://example.com/a"]\n---\n'
    assert kl.parse_synthesis_sources(inline) == [], kl.parse_synthesis_sources(inline)
    # Inline empty form + no-frontmatter + no sources key all fail safe to [].
    assert kl.parse_synthesis_sources("---\nsources: []\n---\n") == []
    assert kl.parse_synthesis_sources("no frontmatter here") == []
    assert kl.parse_synthesis_sources("---\nid: p\n---\n") == []
    assert kl.parse_synthesis_sources("") == []


def assert_frontmatter_scalar():
    page = (
        "---\n"
        "id: my-page\n"
        'title: "A Title: With Colon"\n'
        "created: 2026-06-08\n"
        "updated: 2026-01-01 # last touched\n"
        "---\n"
        "body\n"
    )
    assert kl.frontmatter_scalar(page, "created") == "2026-06-08", kl.frontmatter_scalar(page, "created")
    # Quoted scalar is unquoted (colon preserved inside quotes).
    assert kl.frontmatter_scalar(page, "title") == "A Title: With Colon", kl.frontmatter_scalar(page, "title")
    # Inline comment stripped from an UNQUOTED scalar.
    assert kl.frontmatter_scalar(page, "updated") == "2026-01-01", kl.frontmatter_scalar(page, "updated")
    # Missing key / no frontmatter / empty value → "".
    assert kl.frontmatter_scalar(page, "nope") == ""
    assert kl.frontmatter_scalar("no fm", "created") == ""
    assert kl.frontmatter_scalar("---\ncreated:\n---\n", "created") == ""
    # An indented (nested) key never matches the column-0 anchor.
    nested = "---\npre_extracted_claims:\n  - created: deep\nid: top\n---\n"
    assert kl.frontmatter_scalar(nested, "created") == "", kl.frontmatter_scalar(nested, "created")


def assert_load_pypdf():
    # Contract: never raises; returns None (dep absent) or the pypdf module
    # (present). pypdf is OPTIONAL, so both outcomes are valid — this locks the
    # fail-soft guarantee the source-curator's poppler-less fallback relies on,
    # host-independently (CI may not have pypdf installed) (#583).
    mod = kl.load_pypdf()
    assert mod is None or hasattr(mod, "PdfReader"), repr(mod)
    # Stable across calls (same availability verdict).
    assert (kl.load_pypdf() is None) == (mod is None)


def assert_extract_pdf_text():
    # The poppler-less PDF text-layer fallback (#583). extract_pdf_text()
    # delegates to load_pypdf(); we inject a FAKE pypdf module so the reason
    # vocabulary the source-curator branches on (ok / pypdf_unavailable /
    # no_text_layer / extract_failed) is locked even where real pypdf is not
    # installed — the test does not depend on the host having pypdf.
    import types

    orig = kl.load_pypdf

    class _FakePage:
        def __init__(self, text, raises=False):
            self._text, self._raises = text, raises

        def extract_text(self):
            if self._raises:
                raise RuntimeError("page boom")
            return self._text

    def _fake(pages=None, reader_raises=False):
        class _Reader:
            def __init__(self, _path):
                if reader_raises:
                    raise ValueError("not a pdf")
                self.pages = pages or []

        return types.SimpleNamespace(PdfReader=_Reader)

    try:
        # 1. pypdf absent → pypdf_unavailable; text + pages both None.
        kl.load_pypdf = lambda: None
        r = kl.extract_pdf_text("/whatever.pdf")
        assert r.reason == "pypdf_unavailable", r.reason
        assert r.text is None and r.pages is None, r

        # 2. text layer clears the gate → ok (joined text + page count set).
        kl.load_pypdf = lambda: _fake([_FakePage("x" * 120), _FakePage("y" * 120)])
        r = kl.extract_pdf_text("/a.pdf", min_chars=200)
        assert r.reason == "ok" and r.pages == 2, r
        assert r.text is not None and len(r.text) >= 200, r

        # 3. below the gate → no_text_layer; pages reported, text withheld.
        kl.load_pypdf = lambda: _fake([_FakePage("short")])
        r = kl.extract_pdf_text("/img.pdf", min_chars=200)
        assert r.reason == "no_text_layer" and r.pages == 1 and r.text is None, r

        # 3b. min_chars boundary: exactly the gate passes, one below fails.
        kl.load_pypdf = lambda: _fake([_FakePage("a" * 10)])
        assert kl.extract_pdf_text("/b.pdf", min_chars=10).reason == "ok"
        kl.load_pypdf = lambda: _fake([_FakePage("a" * 9)])
        assert kl.extract_pdf_text("/b.pdf", min_chars=10).reason == "no_text_layer"

        # 4. PdfReader raises → extract_failed, with a human-readable detail.
        kl.load_pypdf = lambda: _fake(reader_raises=True)
        r = kl.extract_pdf_text("/c.pdf")
        assert r.reason == "extract_failed" and r.error, r

        # 5. a single page that raises is skipped; the rest still count.
        kl.load_pypdf = lambda: _fake([_FakePage("", raises=True), _FakePage("z" * 250)])
        r = kl.extract_pdf_text("/d.pdf", min_chars=200)
        assert r.reason == "ok" and r.pages == 2, r
    finally:
        kl.load_pypdf = orig


check("parse_synthesis_sources", assert_parse_synthesis_sources)
check("frontmatter_scalar", assert_frontmatter_scalar)
check("tokenization_primitives", assert_tokenization_primitives)
check("norm_key", assert_norm_key)
check("theme_norm_key", assert_theme_norm_key)
check("claim_similarity", assert_claim_similarity)
check("parse_concept_records", assert_parse_concept_records)
check("parse_citation_records", assert_parse_citation_records)
check("extract_machine_block", assert_extract_machine_block)
check("replace_machine_block", assert_replace_machine_block)
check("upsert_machine_block", assert_upsert_machine_block)
check("parse_portal_records", assert_parse_portal_records)
check("parse_renarrate_records", assert_parse_renarrate_records)
check("digit_anchor_tokens", assert_digit_anchor_tokens)
check("parse_crossmerge_records", assert_parse_crossmerge_records)
check("strip_inline_citation_markers", assert_strip_inline_citation_markers)
check("identity", assert_identity)
check("canonicalization", assert_canonicalization)
check("atomic_write_roundtrip", assert_atomic_write_roundtrip)
check("control_paths", assert_control_paths)
check("slugify", assert_slugify)
check("ref_heading", assert_ref_heading)
check("first_url", assert_first_url)
check("extract_inline_citation_urls", assert_extract_inline_citation_urls)
check("md_link_dest", assert_md_link_dest)
check("strip_reference_section", assert_strip_reference_section)
check("body_word_count", assert_body_word_count)
check("coverage_report", assert_coverage_report)
check("renumber_inline_citations", assert_renumber_inline_citations)
check("parse_pre_extracted_claims", assert_parse_pre_extracted_claims)
check("parse_distilled_claims", assert_parse_distilled_claims)
check("parse_distilled_claims_with_id", assert_parse_distilled_claims_with_id)
check("parse_answer_claims_with_id", assert_parse_answer_claims_with_id)
check("parse_answer_records", assert_parse_answer_records)
check("writer_quality_normalizers", assert_writer_quality_normalizers)
check("extract_page_frontmatter", assert_extract_page_frontmatter)
check("resolve_wiki_scripts", assert_resolve_wiki_scripts)
check("load_pypdf", assert_load_pypdf)
check("extract_pdf_text", assert_extract_pdf_text)
PY
)

errors=0

grade() {
  local tag="$1" description="$2"
  local line
  line=$(printf '%s\n' "$OUT" | grep "^${tag}:" || true)
  case "$line" in
    "${tag}: OK")     green "PASS: $description" ;;
    "${tag}: FAIL "*) red   "FAIL: $description"; red "  ${line#${tag}: FAIL }"; errors=$((errors + 1)) ;;
    *)                red   "FAIL: $description (no result line for '$tag' — python subprocess crashed?)"
                      red   "  output: $OUT"; errors=$((errors + 1)) ;;
  esac
}

grade identity                "three-way identity — normalize_url and atomic_write are the same objects in candidate-store, fetch-cache, _knowledge_lib"
grade canonicalization        "canonicalization — scheme/host lowercased, trailing slash stripped, utm_+ref dropped, fragment removed, path case preserved"
grade atomic_write_roundtrip  "atomic_write round-trips payload and leaves no .tmp debris"
grade control_paths           "control-file resolver (0.0.8) — log/context_brief/open_questions prefer wiki/meta/ when present, else legacy wiki/; meta_dir unconditional; unknown name→ValueError"
grade slugify                 "slugify — German umlaut transliteration (für→fuer), NFKD de-accent, empty/non-alnum→'' contract, max-len truncation"
grade ref_heading             "ref_heading — localized reference heading (de→Referenzen), default/unknown→References"
grade first_url               "first_url — JSON-list + non-JSON fallback URL extraction, no charset over-strip, file:// first-class incl. space-in-path (#572)"
grade extract_inline_citation_urls "extract_inline_citation_urls — http(s) + file:// markers (bracketed/unbracketed), space-in-file:// captured whole, mixed file+http in one sentence yields both, bare/empty→[] (#572)"
grade md_link_dest            "md_link_dest — angle-brackets a destination containing parens/space (paren-URL citation links)"
grade strip_reference_section "strip_reference_section — language-independent strip, #301 first-line match, synonym safety-net, preserves a non-reference bullet section"
grade body_word_count         "body_word_count — body words excl. reference list (EN + DE), no-ref-section counts whole draft, None lang→English (canonical surface for compose Step 7 over-ceiling + wiki-reviewer)"
grade coverage_report         "coverage_report — per-sq available/cited/uncited source slugs + uncited_evidence_sq_ids deficit set; fully-cited & no-evidence sqs excluded; null wiki_slug discarded; empty/None fail-soft (coverage-gated Step 5.5)"
grade renumber_inline_citations "renumber_inline_citations — full-source-drop gap [1][3]→[1][2], no-op when contiguous, synthesis markers remapped"
grade parse_synthesis_sources "parse_synthesis_sources — bare wiki://slug block list, legacy wiki://wiki/slug composite→last segment, comment-line skip, inline sources:[]/source-page inline→[], no-frontmatter→[]"
grade frontmatter_scalar      "frontmatter_scalar — created/updated read, quoted unquote (colon kept), inline-comment strip on unquoted, missing/empty/no-fm→'', column-0 anchor ignores nested keys"
grade parse_pre_extracted_claims "parse_pre_extracted_claims — block-list dicts incl. colon-in-value; malformed/empty frontmatter fails safe to [] (#305)"
grade parse_distilled_claims  "parse_distilled_claims — text-only extraction, writer metadata ignored, inline []/no-bullets/malformed→[], block-scalar no-leak (#343)"
grade parse_distilled_claims_with_id "parse_distilled_claims_with_id — claim_id+text extraction for the prefilter key, rest of metadata ignored, same fail-safe→[] contract (#362)"
grade parse_answer_claims_with_id "parse_answer_claims_with_id — answer_claims: claim_id+text (acl-NNN, no excerpt_quote), classify_claim_kind acl→answer, same fail-safe→[] (#432)"
grade parse_answer_records    "parse_answer_records — question:/answer_claim: blocks, 3-part + 2-part-ref pipe-in-text split, inline question:, missing-question→empty-slug, CRLF, ''→[] (#432)"
grade strip_inline_citation_markers "strip_inline_citation_markers — removes <sup>[N](url)</sup> / <sup>[N]</sup>, multiple markers, no-op when absent (#305 review)"
grade tokenization_primitives "tokenization primitives (#336 lift) — fold/tokenize/token_weight/compound_match preserved from wiki-coverage.py"
grade norm_key                "norm_key — same-fact-different-boilerplate collapse, sorted/deterministic, all-boilerplate→'' (#336)"
grade theme_norm_key          "theme_norm_key — order/stopword-independent token-set, DE transliteration, KEEP-SEPARATE on denylist tokens (vs norm_key false-merge), empty→'' (#409)"
grade claim_similarity        "claim_similarity — symmetric weighted-Jaccard, reworded-same≥0.85, distinct<0.85, all-boilerplate→0.0 (#336)"
grade parse_concept_records   "parse_concept_records — concept/entity records, repeatable claim: lines, colon-in-summary, first-pipe split (#336)"
grade parse_citation_records  "parse_citation_records — url: line parsed (#395, :// survives first-colon partition), absent url:→'', claim null→None"
grade extract_machine_block   "extract_machine_block — verbatim inner incl. heading, absent→None, CRLF, concept-store delegate parity (#341)"
grade replace_machine_block   "replace_machine_block — inner swap preserves sentinels + surrounding bytes, absent→unchanged, concept-store delegate parity (#491)"
grade upsert_machine_block    "upsert_machine_block — insert-after-H1 when absent, replace-when-present, idempotent, no-H1→prepend, Recent-syntheses preserved (#491)"
grade parse_portal_records    "parse_portal_records — theme LEADIN + overview NARRATIVE blocks, empty-dropped, last-wins, CRLF, ''→empty (#491)"
grade parse_renarrate_records "parse_renarrate_records — multi-line dedented prose, empty-prose omitted, last-slug-wins, unterminated-to-EOF, CRLF (#341)"
grade digit_anchor_tokens     "digit_anchor_tokens — Artikel/Article 99 → {99}, multi-anchor, GENERIC_DENYLIST years excluded, no-digit→∅ (#345)"
grade parse_crossmerge_records "parse_crossmerge_records — merge: slug|survivor|absorbed, whitespace strip, wrong-arity/empty-field dropped, comments, CRLF, ''→[] (#345)"
grade writer_quality_normalizers "writer-quality normalizers (#309 P2) — normalize_tone/prose_density/citation_format/target_words + CITATION_FAMILY, valid passthrough, unknown→safe default, wikilink→ieee"
grade extract_page_frontmatter "ingest-integrity frontmatter parsers (#413/#421) — extract_page_id_and_url id+sources, extract_page_content_hash quoted/unquoted-comment/absent/no-frontmatter→'' (shared by sweep + Phase-3 guard)"
grade resolve_wiki_scripts    "resolve_wiki_scripts (#488) — single Python SSOT for the wiki-scripts probe (sibling checkout, else newest numeric version dir); unknown skill→FileNotFoundError naming the skill + --wiki-scripts-dir; real sibling layout resolves to the in-repo dir"
grade load_pypdf              "load_pypdf (#583) — fail-soft optional import: returns None (absent) or a module with PdfReader (present), never raises, stable verdict across calls"
grade extract_pdf_text        "extract_pdf_text (#583) — reason vocabulary (ok/pypdf_unavailable/no_text_layer/extract_failed) via injected fake pypdf, min_chars gate boundary, per-page exception skip, page count reported"

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All _knowledge_lib.py cases pass."

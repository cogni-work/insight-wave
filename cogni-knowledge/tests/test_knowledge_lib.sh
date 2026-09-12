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

# Missing-script text for klib-01. The loop accumulates; the case is emitted
# once, after it closes, under a fixed id. Initialized here because `set -u` is
# on and the post-loop arms read it whether or not the loop ever appended to it.
missing_scripts=""

for f in _knowledge_lib.py candidate-store.py fetch-cache.py; do
  if [ ! -f "$SCRIPTS_DIR/$f" ]; then
    missing_scripts="$missing_scripts$f not found at $SCRIPTS_DIR/$f
"
  fi
done

# klib-01 is emitted here, once, rather than per file inside the loop. In the
# loop the id had to carry a per-file case_slug discriminator to stay unique per
# emitted line, and the arm was fail-only with no else — so the id could never
# print a green line, and a harness aimed at it read a clean run as
# case_not_found instead of a verdict. A fixed id only becomes safe once the
# emission leaves the loop, which is why this is a relocation and not a suffix
# strip. The id stays the second whitespace-separated token, never colon-abutted.
#
# grade() below is the mechanism every other case in this file uses, and is
# deliberately NOT reused here: it grades a tagged line out of $OUT from the
# python subprocess this precondition must run BEFORE (that subprocess imports
# the very scripts checked here), it folds into `errors`, which is not
# initialized until just above it, and it is non-fatal — where this check must
# abort. The exit stays fatal; it now reports every missing script rather than
# only the first.
if [ -z "$missing_scripts" ]; then
  green "PASS: klib-01 all three library scripts present under $SCRIPTS_DIR"
else
  red "FAIL: klib-01 library script(s) missing under $SCRIPTS_DIR:"
  printf '%s' "$missing_scripts" | sed 's/^/  /'
  exit 1
fi

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


def assert_excerpt_present():
    # #960: normalized excerpt matcher tolerates the mechanical PDF-vs-HTML drift
    # (ligature codepoints, smart quotes, column-wrap newlines between words)
    # without loosening on short coincidental fragments.
    ep = kl.excerpt_present
    body = ("The classiﬁcation of “high-risk” AI\n"
            "systems is deﬁned in the Regulation.")
    ndl = 'The classification of "high-risk" AI systems is defined in the Regulation.'
    assert ep(ndl, body) is True, "normalized (ligature+smart-quote+newline) match"
    # raw exact still fast-paths (clean HTML body behavior unchanged)
    assert ep("Regulation.", "ends with Regulation.") is True, "raw substring fast-path"
    # genuinely absent → False even after normalization
    assert ep("a phrase that is nowhere in the body at all", body) is False, "genuine absence"
    # sub-floor needle: raw miss + below MIN_EXCERPT_NEEDLE_LEN → no normalized loosening
    assert ep("AI\nsystems", "the AI systems work") is False, "short fragment not loosened"
    # empty inputs → False
    assert ep("", body) is False and ep(ndl, "") is False, "empty needle/haystack"
    assert kl.MIN_EXCERPT_NEEDLE_LEN == 24, kl.MIN_EXCERPT_NEEDLE_LEN


def assert_leadin_placeholder():
    # Localized sub-index theme lead-in fallback, default/unknown → English.
    L = kl.leadin_placeholder
    # English is the identity case and MUST stay byte-stable with the legacy
    # deterministic fallback (sub_index render with no --lang renders English).
    for t in ("concepts", "entities", "people", "sources", "questions", "syntheses"):
        assert L(t, None) == f"_This theme groups the {t} below._", L(t, None)
        assert L(t, "en") == f"_This theme groups the {t} below._", L(t, "en")
    # Non-English renders a fully-coherent localized sentence + noun (article
    # carried where the language needs agreement) — never a mixed-language string.
    assert L("concepts", "de") == "_Dieses Thema gruppiert die Konzepte weiter unten._", L("concepts", "de")
    assert L("entities", "nl") == "_Dit thema groepeert de entiteiten hieronder._", L("entities", "nl")
    assert L("sources", "fr") == "_Ce thème regroupe les sources ci-dessous._", L("sources", "fr")
    assert L("people", "it") == "_Questo tema raggruppa le persone qui sotto._", L("people", "it")
    assert L("questions", "es") == "_Este tema agrupa las preguntas a continuación._", L("questions", "es")
    assert L("syntheses", "pl") == "_Ten temat grupuje syntezy poniżej._", L("syntheses", "pl")
    assert L("concepts", "DE").startswith("_Dieses Thema"), "lang is case-insensitive"
    # Default-to-safe posture (mirrors ref_heading): unknown lang → English
    # template, unmapped type → raw type noun, non-str args never crash.
    assert L("concepts", "xx") == "_This theme groups the concepts below._", "unknown lang → English"
    assert L("widgets", "de") == "_Dieses Thema gruppiert widgets weiter unten._", "unmapped type → raw noun"
    assert L("concepts", 5) == "_This theme groups the concepts below._", "non-str lang → English, no crash"
    assert L(None, None) == "_This theme groups the  below._", "None type → empty noun, no crash"


def assert_page_type_line():
    # #931: deterministic reader-facing `Type: <Display> · <stage>` header line.
    # Display name + stage word are properties of the type (not the page instance).
    sep = "·"  # U+00B7 MIDDLE DOT — never an ASCII substitute.
    assert kl.page_type_line("concept") == f"Type: Concept {sep} distilled", kl.page_type_line("concept")
    assert kl.page_type_line("entity") == f"Type: Entity {sep} distilled", kl.page_type_line("entity")
    assert kl.page_type_line("person") == f"Type: Person {sep} distilled", kl.page_type_line("person")
    assert kl.page_type_line("question") == f"Type: Question {sep} raw", kl.page_type_line("question")
    assert kl.page_type_line("source") == f"Type: Source {sep} raw", kl.page_type_line("source")
    assert kl.page_type_line("interview") == f"Type: Interview {sep} raw", kl.page_type_line("interview")
    assert kl.page_type_line("synthesis") == f"Type: Synthesis {sep} distilled", kl.page_type_line("synthesis")
    # Case-insensitive on the key.
    assert kl.page_type_line("CONCEPT") == f"Type: Concept {sep} distilled", "case-insensitive key"
    # The exact separator is the middle dot, not an ASCII bullet/hyphen.
    assert sep in kl.page_type_line("source") and "*" not in kl.page_type_line("source"), "U+00B7 separator"
    # Unknown / non-str / empty → safe title-cased display + raw, never a crash.
    assert kl.page_type_line("widget") == f"Type: Widget {sep} raw", "unknown type → title-cased + raw"
    assert kl.page_type_line(None) == f"Type: Unknown {sep} raw", "None → Unknown + raw, no crash"
    assert kl.page_type_line("") == f"Type: Unknown {sep} raw", "empty → Unknown + raw"
    assert kl.page_type_line(5) == f"Type: 5 {sep} raw", "non-str (int) coerced, no crash"


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


def assert_parse_distilled_claims_with_backlinks():
    # #885: the dual-level retrieval join needs each distilled claim's backlinks
    # source slugs, which the with_id sibling drops by design. This reader absorbs
    # claim_id + text + the inline-list backlinks (concept-store renders it via
    # json.dumps, with or without a space after the comma).
    page = (
        "---\n"
        "type: concept\n"
        "distilled_claims:\n"
        "  - claim_id: dcl-001\n"
        '    text: "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen."\n'
        '    norm_key: "k1"\n'
        '    backlinks: ["src-a", "src-b"]\n'
        '    source_claim_refs: ["src-a#c1"]\n'
        "    created: 2026-05-29\n"
        "  - claim_id: dcl-002\n"
        '    text: "Zweite distillierte Aussage."\n'
        '    backlinks: ["src-c","src-a"]\n'
        "---\n\n# body\n"
    )
    claims = kl.parse_distilled_claims_with_backlinks(page)
    assert len(claims) == 2, claims
    assert claims[0] == {"claim_id": "dcl-001",
                         "text": "Artikel 6: Hochrisiko-Einstufung kombiniert mehrere Quellen.",
                         "backlinks": ["src-a", "src-b"]}, claims[0]
    assert set(claims[0]) == {"claim_id", "text", "backlinks"}, \
        "only claim_id+text+backlinks wanted: " + repr(claims[0])
    assert claims[1]["backlinks"] == ["src-c", "src-a"], claims[1]
    # A claim with no / empty inline-list backlinks normalizes to backlinks=[] —
    # every returned claim carries the key as a list (uniform join shape).
    nob = kl.parse_distilled_claims_with_backlinks(
        "---\ndistilled_claims:\n  - claim_id: dcl-x\n    text: t\n    backlinks: []\n---\n")
    assert nob == [{"claim_id": "dcl-x", "text": "t", "backlinks": []}], nob
    miss = kl.parse_distilled_claims_with_backlinks(
        "---\ndistilled_claims:\n  - claim_id: dcl-y\n    text: t\n---\n")
    assert miss == [{"claim_id": "dcl-y", "text": "t", "backlinks": []}], miss
    # The with_id sibling stays byte-identical (no backlinks key) — proves additive.
    wid = kl.parse_distilled_claims_with_id(page)
    assert set(wid[0]) == {"claim_id", "text"}, "with_id unaffected: " + repr(wid[0])
    # Same fail-safe contract: inline [] / no key / empty / no-frontmatter → [].
    assert kl.parse_distilled_claims_with_backlinks("---\ntype: concept\ndistilled_claims: []\n---\n# body\n") == []
    assert kl.parse_distilled_claims_with_backlinks("") == []
    assert kl.parse_distilled_claims_with_backlinks("---\ntype: concept\n---\n# body\n") == []


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


def assert_resolve_author_year():
    explicit = (
        "---\n"
        "id: p\n"
        'author: "J. Doe"\n'
        'published_date: "2019-04-01"\n'
        'publisher: "europa.eu"\n'
        'fetched_at: "2024-03-15T10:00:00Z"\n'
        "---\n"
        "# body\n"
    )
    # Explicit frontmatter beats the surrogate on BOTH legs (publisher/fetched_at
    # deliberately disagree with the explicit values).
    assert kl.resolve_author_year(explicit) == ("J. Doe", "2019")

    legacy = (
        "---\n"
        "id: p\n"
        'publisher: "europa.eu"\n'
        'fetched_at: "2024-03-15T10:00:00Z"\n'
        "---\n"
        "# body\n"
    )
    # A page ingested before either key existed still resolves non-empty on both
    # legs — the no-migration guarantee. Removing the publisher surrogate leg
    # reddens exactly here.
    got = kl.resolve_author_year(legacy)
    assert got == ("europa.eu", "2024"), got
    assert got[0] and got[1], "legacy page must resolve non-empty on both legs"

    mixed = (
        "---\n"
        "id: p\n"
        'author: "J. Doe"\n'
        'publisher: "europa.eu"\n'
        'fetched_at: "2024-03-15T10:00:00Z"\n'
        "---\n"
        "# body\n"
    )
    assert kl.resolve_author_year(mixed) == ("J. Doe", "2024")

    assert kl.resolve_author_year("---\nid: p\n---\n# body\n") == ("", "")
    assert kl.resolve_author_year("# just a body\n") == ("", "")

    # check() catches only AssertionError, so an unguarded raise here would kill
    # the shared python subprocess and blank every klib case at once.
    for degenerate in (None, "", 42):
        try:
            probe = kl.resolve_author_year(degenerate)
        except Exception as exc:
            raise AssertionError(
                f"resolve_author_year raised on {degenerate!r}: {exc!r}"
            )
        assert probe == ("", ""), probe


def assert_resolve_wiki_scripts():
    # The single Python definition of the wiki-scripts resolve probe, shared by
    # the standalone operator drivers so they are not a second independent copy
    # of the bash rule. Resolution is VENDORED-ONLY: cogni-wiki is retired, so
    # the former sibling-checkout and versioned-cache branches (and the base_dir
    # seam that existed solely to exercise the cache-ranking branch) are gone.
    # Negative case (hermetic, always on): an unknown skill has no vendored dir
    # -> FileNotFoundError naming the skill + the --wiki-scripts-dir escape hatch.
    try:
        kl.resolve_wiki_scripts("__nonexistent_skill__")
        assert False, "expected FileNotFoundError for an unknown skill"
    except FileNotFoundError as exc:
        assert "__nonexistent_skill__" in str(exc), str(exc)
        assert "--wiki-scripts-dir" in str(exc), str(exc)
        # The message must not offer an external cogni-wiki as a remedy.
        assert "install cogni-wiki" not in str(exc).lower(), str(exc)

    # Real-layout case: the vendored dir, and nothing else, resolves.
    vendored = scripts / "vendor" / "cogni-wiki" / "skills" / "wiki-ingest" / "scripts"
    assert vendored.is_dir(), f"vendored engine missing on disk: {vendored!r}"
    got = kl.resolve_wiki_scripts("wiki-ingest")
    assert got.resolve() == vendored.resolve(), f"got={got!r} expected vendored={vendored!r}"

    # The base_dir seam is GONE — passing it must be a TypeError, not a silently
    # accepted no-op. This is the anti-regression guard: were the seam (and the
    # external branches it existed for) reintroduced, this call would succeed.
    try:
        kl.resolve_wiki_scripts("wiki-ingest", base_dir=work)  # type: ignore[call-arg]
        assert False, "base_dir seam must not exist (external probe branches removed)"
    except TypeError:
        pass

    # No external-layout FIXTURE is built here, deliberately. The resolver keys
    # on Path(__file__), so a fixture under `work` is unreachable by any code
    # path — a restored sibling branch would probe the REAL repo root and never
    # look at it, making such an assertion vacuous (it would pass whether or not
    # the branch came back). The reachable, discriminating checks are the
    # base_dir TypeError above and the source-level scan in
    # test_knowledge_wiki_probe.sh case 12, which parses this function and
    # asserts no sibling/cache branch is present in its executable code.

    # expected_script is the VENDOR INTEGRITY guard and is now the only probe
    # hardening left: a real entry point resolves, a missing one raises rather
    # than returning a dir whose script would blow up later.
    got_ep = kl.resolve_wiki_scripts("wiki-ingest", expected_script="_wikilib.py")
    assert got_ep.resolve() == vendored.resolve(), f"entry-point present: got={got_ep!r}"
    try:
        kl.resolve_wiki_scripts("wiki-ingest", expected_script="__no_such_script__.py")
        assert False, "expected FileNotFoundError when the vendored dir lacks the entry-point"
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


def assert_citation_family_dispatch():
    # The numbered family.
    assert kl.citation_family("ieee") == "numbered"
    assert kl.citation_family("chicago") == "numbered"
    # The author-date family.
    assert kl.citation_family("apa") == "author_date"
    assert kl.citation_family("mla") == "author_date"
    assert kl.citation_family("harvard") == "author_date"
    # Normalization is inherited from normalize_citation_format, so case and
    # surrounding whitespace do not change the family.
    assert kl.citation_family("APA") == "author_date"
    assert kl.citation_family("  Harvard  ") == "author_date"
    # The deprecated `wikilink` alias routes to ieee, hence numbered.
    assert kl.citation_family("wikilink") == "numbered"
    # TOTAL: every value the format field can carry degrades to the family the
    # pipeline actually renders, rather than raising at a call site. A bare
    # CITATION_FAMILY[fmt] subscript would KeyError on each of these.
    for degenerate in ("bibtex", "", None):
        assert kl.citation_family(degenerate) == "numbered", degenerate


def assert_strip_author_date_citation_markers():
    # All three author-date shapes strip with NO residue — asserted by full-string
    # equality, so a stray paren or a surviving year would fail.
    apa = "AI is regulated ([Doe, 2024](https://x.eu/c)). Next."
    assert kl.strip_author_date_citation_markers(apa) == "AI is regulated . Next.", \
        kl.strip_author_date_citation_markers(apa)
    mla = "AI is regulated ([Doe](https://x.eu/c))."
    assert kl.strip_author_date_citation_markers(mla) == "AI is regulated ."
    harvard = "AI is regulated ([Doe 2024](https://x.eu/c))."
    assert kl.strip_author_date_citation_markers(harvard) == "AI is regulated ."
    # Multiple markers in one sentence.
    two = "A ([Doe, 2024](https://a.org/x)) and B ([Roe, 2023](https://b.org/y))."
    assert kl.strip_author_date_citation_markers(two) == "A  and B ."
    # No-op when absent.
    assert kl.strip_author_date_citation_markers("plain text") == "plain text"
    assert kl.strip_author_date_citation_markers("") == ""
    # Scheme-anchored: an ordinary parenthesized markdown link is prose, not a
    # citation, and must survive untouched.
    prose = "As noted (see [the annex](#section-3)) the rule applies."
    assert kl.strip_author_date_citation_markers(prose) == prose, \
        kl.strip_author_date_citation_markers(prose)
    # The [[N]] wikilink anti-pattern can never match (label class excludes []).
    wl = "A ([[2]](https://a.org/x))."
    assert kl.strip_author_date_citation_markers(wl) == wl, \
        kl.strip_author_date_citation_markers(wl)
    # The family-aware dispatcher BRANCHES rather than applying both patterns:
    # under a numbered format an author-date marker SURVIVES, and the result is
    # byte-identical to the existing numbered strip.
    assert kl.strip_citation_markers(apa, "ieee") == kl.strip_inline_citation_markers(apa)
    assert "([Doe, 2024](https://x.eu/c))" in kl.strip_citation_markers(apa, "ieee")
    assert kl.strip_citation_markers(apa, "apa") == "AI is regulated . Next."
    # ... and conversely a numbered marker survives under an author-date format.
    numbered = "AI is regulated<sup>[3](https://x.eu/c)</sup>."
    assert kl.strip_citation_markers(numbered, "ieee") == "AI is regulated."
    assert kl.strip_citation_markers(numbered, "apa") == numbered


def assert_extract_author_date_citation_urls():
    # Appearance order across two http markers.
    text = "A ([Doe, 2024](https://a.org/x)). B ([Roe, 2023](https://b.org/y))."
    assert kl.extract_author_date_citation_urls(text) == \
        ["https://a.org/x", "https://b.org/y"], kl.extract_author_date_citation_urls(text)
    # file:// is first-class.
    f = "C ([Doe, 2024](file:///abs/p.pdf))."
    assert kl.extract_author_date_citation_urls(f) == ["file:///abs/p.pdf"], \
        kl.extract_author_date_citation_urls(f)
    # An UNBRACKETED file:// path with a literal space is captured whole, not
    # truncated at the space ([^)] rather than \S).
    fs = "D ([Doe, 2024](file:///abs/V8 Data.pdf))."
    assert kl.extract_author_date_citation_urls(fs) == ["file:///abs/V8 Data.pdf"], \
        kl.extract_author_date_citation_urls(fs)
    # The angle-bracketed destination form.
    fb = "E ([Doe, 2024](<file:///abs/V8 Data.pdf>))."
    assert kl.extract_author_date_citation_urls(fb) == ["file:///abs/V8 Data.pdf"], \
        kl.extract_author_date_citation_urls(fb)
    # Mixed file + http in one sentence yields BOTH, in order.
    mixed = "F ([Doe, 2024](file:///abs/p.pdf)) and ([Roe, 2023](https://w.org/z))."
    assert kl.extract_author_date_citation_urls(mixed) == \
        ["file:///abs/p.pdf", "https://w.org/z"], kl.extract_author_date_citation_urls(mixed)
    # A marker carrying no URL, and empty text, contribute nothing.
    assert kl.extract_author_date_citation_urls("G ([Doe, 2024]).") == []
    assert kl.extract_author_date_citation_urls("") == []
    # Scheme-anchored: an ordinary parenthesized markdown link yields no URL.
    assert kl.extract_author_date_citation_urls("(see [the annex](#section-3))") == []
    # The family-aware dispatcher branches.
    assert kl.extract_citation_urls(text, "apa") == ["https://a.org/x", "https://b.org/y"]
    assert kl.extract_citation_urls(text, "ieee") == []
    numbered = "A<sup>[1](https://a.org/x)</sup>."
    assert kl.extract_citation_urls(numbered, "ieee") == \
        kl.extract_inline_citation_urls(numbered) == ["https://a.org/x"]
    assert kl.extract_citation_urls(numbered, "apa") == []


def assert_strip_author_date_destination_less():
    # #1755: a source with no external URL (synthesis / distilled dcl-NNN /
    # question-node acl-NNN) now renders the DESTINATION-LESS author-date marker
    # under apa/mla/harvard instead of the numbered family's plain <sup>[N]</sup>.
    # Strip must remove it with NO residue, in all three per-format shapes —
    # full-string equality, so a stray bracket or a surviving year would fail.
    apa = "AI is regulated ([Doe, 2024]). Next."
    assert kl.strip_author_date_citation_markers(apa) == "AI is regulated . Next.", \
        kl.strip_author_date_citation_markers(apa)
    mla = "AI is regulated ([Doe])."
    assert kl.strip_author_date_citation_markers(mla) == "AI is regulated ."
    harvard = "AI is regulated ([Doe 2024])."
    assert kl.strip_author_date_citation_markers(harvard) == "AI is regulated ."
    # ... and through the family dispatcher for each of the three formats, so the
    # fix is reachable the way verify-store.py's prefilter actually calls it.
    for fmt, text in (("apa", apa), ("mla", mla), ("harvard", harvard)):
        assert "[" not in kl.strip_citation_markers(text, fmt), \
            (fmt, kl.strip_citation_markers(text, fmt))
    # Two destination-less markers in one sentence.
    two = "A ([Doe, 2024]) and B ([Roe, 2023])."
    assert kl.strip_author_date_citation_markers(two) == "A  and B ."
    # The DESTINATION-BEARING form is still consumed WHOLE by the URL arm — the
    # new arm must not chip a linked marker into an orphan "(...)" residue.
    linked = "AI is regulated ([Doe, 2024](https://x.eu/c)). Next."
    assert kl.strip_author_date_citation_markers(linked) == "AI is regulated . Next.", \
        kl.strip_author_date_citation_markers(linked)
    # NEGATIVES, asserted byte-for-byte: the new arm is shape-anchored, never a
    # heuristic over parenthesized prose.
    for survivor in (
        # unbracketed prose carries no bracketed label
        "As noted (see Smith, 2020) the rule applies.",
        # "(" is not immediately followed by "["
        "As noted (see [the annex](#section-3)) the rule applies.",
        # "]" is followed by "(", not ")", and the destination is not a scheme
        "A ([Doe, 2024](#section-3)).",
        # the label class excludes [ and ], so the [[N]] anti-pattern cannot match
        "A ([[2]](https://a.org/x)).",
    ):
        assert kl.strip_author_date_citation_markers(survivor) == survivor, \
            kl.strip_author_date_citation_markers(survivor)
        assert kl.strip_citation_markers(survivor, "apa") == survivor, \
            kl.strip_citation_markers(survivor, "apa")
    # CROSS-FAMILY, both directions: the dispatcher still BRANCHES on the new form.
    assert kl.strip_citation_markers(apa, "ieee") == apa
    numbered = "AI is regulated<sup>[3](https://x.eu/c)</sup>."
    assert kl.strip_citation_markers(numbered, "apa") == numbered
    assert kl.strip_citation_markers(numbered, "ieee") == "AI is regulated."


def assert_extract_author_date_destination_less():
    # #1755: widening STRIP must not leak a phantom URL into EXTRACT. The
    # destination-less form is precisely the shape extract is defined to yield
    # nothing for, and the two patterns must stay disagreed on exactly that shape.
    for text in ("G ([Doe, 2024]).", "G ([Doe]).", "G ([Doe 2024])."):
        assert kl.extract_author_date_citation_urls(text) == [], \
            kl.extract_author_date_citation_urls(text)
        assert kl.extract_citation_urls(text, "apa") == [], \
            kl.extract_citation_urls(text, "apa")
    # A non-http(s)/file destination is not a citation URL either.
    anchor = "H ([Doe, 2024](#section-3))."
    assert kl.extract_author_date_citation_urls(anchor) == []
    assert kl.extract_citation_urls(anchor, "apa") == []
    # A real destination in the SAME string still extracts, in appearance order,
    # with the destination-less marker contributing nothing.
    mixed = "A ([Doe, 2024](https://a.org/x)) then B ([Roe]) then C ([Poe, 2022](file:///abs/p.pdf))."
    assert kl.extract_author_date_citation_urls(mixed) == \
        ["https://a.org/x", "file:///abs/p.pdf"], kl.extract_author_date_citation_urls(mixed)
    assert kl.extract_citation_urls(mixed, "harvard") == \
        ["https://a.org/x", "file:///abs/p.pdf"]
    # The extract pattern itself is untouched and still scheme-anchored.
    assert "https?|file" in kl._AUTHOR_DATE_CITATION_URL_RE.pattern


def assert_build_author_date_reference_list():
    # Insertion order deliberately differs from alphabetical order, and `roe` is
    # cited twice under two different renderings of the SAME source — so a dedup
    # keyed on the rendered string (rather than source identity) would keep both.
    entries = [
        {"slug": "roe", "author": "Roe, Jane", "rendered": "Roe, Jane (2023). Later."},
        {"slug": "doe", "author": "J. Doe", "rendered": "Doe, J. (2019). Earlier."},
        {"slug": "roe", "author": "Roe, Jane", "rendered": "Roe, Jane (2023). DUPLICATE."},
        {"slug": "acme", "author": "Acme Corp", "rendered": "Acme Corp (2020). Mid."},
    ]
    out = kl.build_author_date_reference_list(entries)
    # Exactly one entry per distinct source, in surname order (Corp < Doe < Roe),
    # asserted by full-list equality — not membership, not length.
    assert out == [
        "Acme Corp (2020). Mid.",
        "Doe, J. (2019). Earlier.",
        "Roe, Jane (2023). Later.",
    ], out
    # Un-numbered: no **[N]** prefix and no [[N]] wikilink shape.
    for line in out:
        assert "**[" not in line and "[[" not in line, line

    # Degenerate authors: the ("", "") resolve_author_year returns for a page it
    # cannot read, and a surname-less `publisher:` surrogate. Neither may raise,
    # and empty sorts LAST as a block rather than leading the list.
    degenerate = [
        {"slug": "blank", "author": "", "rendered": "BLANK"},
        {"slug": "surrogate", "author": "europa.eu", "rendered": "SURROGATE"},
        {"slug": "doe", "author": "J. Doe", "rendered": "DOE"},
    ]
    assert kl.build_author_date_reference_list(degenerate) == \
        ["DOE", "SURROGATE", "BLANK"], kl.build_author_date_reference_list(degenerate)
    # Deterministic when two sources share one author (slug tiebreak).
    tied = [
        {"slug": "z", "author": "Doe, J", "rendered": "Z"},
        {"slug": "a", "author": "Doe, J", "rendered": "A"},
    ]
    assert kl.build_author_date_reference_list(tied) == ["A", "Z"]
    # Empty input.
    assert kl.build_author_date_reference_list([]) == []
    assert kl.build_author_date_reference_list(None) == []
    # The sort key itself is total and non-raising over every degenerate form.
    for bad in ("", None, "   ", "europa.eu"):
        kl.author_surname_sort_key(bad)


def assert_author_date_reference_entry():
    # The three author-date formats must render three DISTINCT bibliography
    # strings. A shared string would satisfy "not numbered" while leaving mla and
    # harvard unimplemented, so every arm is pinned by full-string equality, and
    # the three are asserted pairwise distinct on top — an assertion set that
    # would still pass if all three arms were collapsed onto one would prove
    # nothing about the property this case exists for.
    e = kl.author_date_reference_entry
    url = "https://ipa.fraunhofer.de/pm"
    link = "[" + url + "](" + url + ")"
    apa = e("apa", "Fraunhofer IPA", "2024", "Titel", "Fraunhofer", url)
    mla = e("mla", "Fraunhofer IPA", "2024", "Titel", "Fraunhofer", url)
    harvard = e("harvard", "Fraunhofer IPA", "2024", "Titel", "Fraunhofer", url)
    assert apa == 'Fraunhofer IPA. (2024). "Titel". Fraunhofer. ' + link, apa
    assert mla == 'Fraunhofer IPA. "Titel." Fraunhofer, 2024. ' + link, mla
    assert harvard == 'Fraunhofer IPA (2024) "Titel". Fraunhofer. Available at: ' + link, harvard
    assert len({apa, mla, harvard}) == 3, "three formats must not collapse onto one shape"
    # MLA is the only one that puts the sentence period INSIDE the closing quote.
    assert '"Titel."' in mla and '"Titel"' in apa and '"Titel."' not in apa

    # Un-numbered by construction: no **[N]** prefix, and no [[ ]] shape that the
    # wiki-reviewer's high-severity [[N]] detector would have to adjudicate.
    for line in (apa, mla, harvard):
        assert "**[" not in line and "[[" not in line, line

    # A NUMBERED format renders nothing rather than guessing an author-date shape
    # — finalize builds those entries in its own **[N]** arm.
    assert e("ieee", "A", "2024", "T", "P", url) == ""
    assert e("chicago", "A", "2024", "T", "P", url) == ""
    # The deprecated wikilink alias resolves to ieee, so it is numbered too, and
    # an unknown/empty/None format falls back to ieee rather than raising.
    for numbered in ("wikilink", "bibtex", "", None):
        assert e(numbered, "A", "2024", "T", "P", url) == ""

    # Degradations. Each returns a well-formed entry; none raises.
    # No year -> n.d. in that format's own slot, and NEVER a doubled period.
    # mla is the only format whose year sits at the end of a segment, so it is
    # the only one where `n.d.` can collide with the sentence period — assert the
    # correct shape AND the absence of the doubled one, so the fix is pinned in
    # both directions and cannot silently regress back into the expected value.
    assert '. (n.d.). ' in e("apa", "A", "", "T", "P", url)
    mla_nd = e("mla", "A", None, "T", "P", url)
    assert 'P, n.d. ' in mla_nd and 'n.d..' not in mla_nd, mla_nd
    assert 'A (n.d.) ' in e("harvard", "A", "   ", "T", "P", url)
    # The same collision with no publisher, where the tail IS the bare year.
    mla_nd_nopub = e("mla", "A", "", "T", "", url)
    assert 'A. "T." n.d. ' in mla_nd_nopub and 'n.d..' not in mla_nd_nopub, mla_nd_nopub
    # No format may double the period on a year-less entry.
    for fmt in ("apa", "mla", "harvard"):
        assert "n.d.." not in e(fmt, "", "", "T", "P", ""), fmt
    # No author -> the entry LEADS with the title, in each format's own order.
    assert e("apa", "", "2024", "T", "P", url).startswith('"T". (2024).')
    assert e("mla", None, "2024", "T", "P", url).startswith('"T." P, 2024.')
    assert e("harvard", "", "2024", "T", "P", url).startswith('"T" (2024).')
    # No publisher -> the segment is dropped; mla folds to the bare year.
    assert e("mla", "A", "2024", "T", "", url) == 'A. "T." 2024. ' + link
    assert e("apa", "A", "2024", "T", None, url) == 'A. (2024). "T". ' + link
    # A publisher EQUAL to the author drops the same way (case-insensitively):
    # on a legacy page resolve_author_year falls back to the publisher: surrogate
    # for the author, so keeping both prints the publisher twice in one entry.
    assert e("apa", "acme.de", "2019", "T", "acme.de", url) == 'acme.de. (2019). "T". ' + link
    assert e("harvard", "ACME.DE", "2019", "T", "acme.de", url) == 'ACME.DE (2019) "T". Available at: ' + link
    # A genuinely different publisher is still kept.
    assert 'Zeta Institute.' in e("apa", "Zimmermann, Ada", "2024", "T", "Zeta Institute", url)
    # No url -> the link goes, and harvard's "Available at:" lead-in goes with it.
    assert e("harvard", "A", "2024", "T", "P", "") == 'A (2024) "T". P.'
    assert "Available at" not in e("harvard", "A", "2024", "T", "P", None)
    # Everything degenerate at once still returns a string rather than raising.
    for fmt in ("apa", "mla", "harvard"):
        assert isinstance(e(fmt, None, None, None, None, None), str)

    # A paren-bearing URL is angle-bracketed through md_link_dest, exactly as the
    # numbered reference row does — otherwise the link truncates at the inner ')'.
    paren = "https://x.eu/a_(b)"
    assert "](<" + paren + ">)" in e("apa", "A", "2024", "T", "P", paren)


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
check("excerpt_present", assert_excerpt_present)
check("leadin_placeholder", assert_leadin_placeholder)
check("page_type_line", assert_page_type_line)
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
check("parse_distilled_claims_with_backlinks", assert_parse_distilled_claims_with_backlinks)
check("parse_answer_claims_with_id", assert_parse_answer_claims_with_id)
check("parse_answer_records", assert_parse_answer_records)
check("writer_quality_normalizers", assert_writer_quality_normalizers)
check("extract_page_frontmatter", assert_extract_page_frontmatter)
check("resolve_wiki_scripts", assert_resolve_wiki_scripts)
check("load_pypdf", assert_load_pypdf)
check("extract_pdf_text", assert_extract_pdf_text)
check("resolve_author_year", assert_resolve_author_year)
check("citation_family_dispatch", assert_citation_family_dispatch)
check("strip_author_date_citation_markers", assert_strip_author_date_citation_markers)
check("extract_author_date_citation_urls", assert_extract_author_date_citation_urls)
check("build_author_date_reference_list", assert_build_author_date_reference_list)
check("author_date_reference_entry", assert_author_date_reference_entry)
check("strip_author_date_destination_less", assert_strip_author_date_destination_less)
check("extract_author_date_destination_less", assert_extract_author_date_destination_less)
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

grade identity                "klib-02 three-way identity — normalize_url and atomic_write are the same objects in candidate-store, fetch-cache, _knowledge_lib"
grade canonicalization        "klib-03 canonicalization — scheme/host lowercased, trailing slash stripped, utm_+ref dropped, fragment removed, path case preserved"
grade atomic_write_roundtrip  "klib-04 atomic_write round-trips payload and leaves no .tmp debris"
grade control_paths           "klib-05 control-file resolver (0.0.8) — log/context_brief/open_questions prefer wiki/meta/ when present, else legacy wiki/; meta_dir unconditional; unknown name→ValueError"
grade slugify                 "klib-06 slugify — German umlaut transliteration (für→fuer), NFKD de-accent, empty/non-alnum→'' contract, max-len truncation"
grade ref_heading             "klib-07 ref_heading — localized reference heading (de→Referenzen), default/unknown→References"
grade excerpt_present         "klib-08 excerpt_present (#960) — normalized PDF-vs-HTML drift match (ligature/smart-quote/column-wrap newline), raw fast-path, genuine-absence→False, sub-floor fragment not loosened, empty→False, MIN_EXCERPT_NEEDLE_LEN=24"
grade leadin_placeholder      "klib-09 leadin_placeholder — localized sub-index lead-in fallback (de→coherent sentence+noun), EN byte-stable, unknown lang/type & non-str→safe (#940)"
grade first_url               "klib-10 first_url — JSON-list + non-JSON fallback URL extraction, no charset over-strip, file:// first-class incl. space-in-path (#572)"
grade extract_inline_citation_urls "klib-11 extract_inline_citation_urls — http(s) + file:// markers (bracketed/unbracketed), space-in-file:// captured whole, mixed file+http in one sentence yields both, bare/empty→[] (#572)"
grade md_link_dest            "klib-12 md_link_dest — angle-brackets a destination containing parens/space (paren-URL citation links)"
grade strip_reference_section "klib-13 strip_reference_section — language-independent strip, #301 first-line match, synonym safety-net, preserves a non-reference bullet section"
grade body_word_count         "klib-14 body_word_count — body words excl. reference list (EN + DE), no-ref-section counts whole draft, None lang→English (canonical surface for compose Step 7 over-ceiling + wiki-reviewer)"
grade coverage_report         "klib-15 coverage_report — per-sq available/cited/uncited source slugs + uncited_evidence_sq_ids deficit set; fully-cited & no-evidence sqs excluded; null wiki_slug discarded; empty/None fail-soft (coverage-gated Step 5.5)"
grade renumber_inline_citations "klib-16 renumber_inline_citations — full-source-drop gap [1][3]→[1][2], no-op when contiguous, synthesis markers remapped"
grade parse_synthesis_sources "klib-17 parse_synthesis_sources — bare wiki://slug block list, legacy wiki://wiki/slug composite→last segment, comment-line skip, inline sources:[]/source-page inline→[], no-frontmatter→[]"
grade frontmatter_scalar      "klib-18 frontmatter_scalar — created/updated read, quoted unquote (colon kept), inline-comment strip on unquoted, missing/empty/no-fm→'', column-0 anchor ignores nested keys"
grade parse_pre_extracted_claims "klib-19 parse_pre_extracted_claims — block-list dicts incl. colon-in-value; malformed/empty frontmatter fails safe to [] (#305)"
grade parse_distilled_claims  "klib-20 parse_distilled_claims — text-only extraction, writer metadata ignored, inline []/no-bullets/malformed→[], block-scalar no-leak (#343)"
grade parse_distilled_claims_with_id "klib-21 parse_distilled_claims_with_id — claim_id+text extraction for the prefilter key, rest of metadata ignored, same fail-safe→[] contract (#362)"
grade parse_answer_claims_with_id "klib-22 parse_answer_claims_with_id — answer_claims: claim_id+text (acl-NNN, no excerpt_quote), classify_claim_kind acl→answer, same fail-safe→[] (#432)"
grade parse_answer_records    "klib-23 parse_answer_records — question:/answer_claim: blocks, 3-part + 2-part-ref pipe-in-text split, inline question:, missing-question→empty-slug, CRLF, ''→[] (#432)"
grade strip_inline_citation_markers "klib-24 strip_inline_citation_markers — removes <sup>[N](url)</sup> / <sup>[N]</sup>, multiple markers, no-op when absent (#305 review)"
grade tokenization_primitives "klib-25 tokenization primitives (#336 lift) — fold/tokenize/token_weight/compound_match preserved from wiki-coverage.py"
grade norm_key                "klib-26 norm_key — same-fact-different-boilerplate collapse, sorted/deterministic, all-boilerplate→'' (#336)"
grade theme_norm_key          "klib-27 theme_norm_key — order/stopword-independent token-set, DE transliteration, KEEP-SEPARATE on denylist tokens (vs norm_key false-merge), empty→'' (#409)"
grade claim_similarity        "klib-28 claim_similarity — symmetric weighted-Jaccard, reworded-same≥0.85, distinct<0.85, all-boilerplate→0.0 (#336)"
grade parse_concept_records   "klib-29 parse_concept_records — concept/entity records, repeatable claim: lines, colon-in-summary, first-pipe split (#336)"
grade parse_citation_records  "klib-30 parse_citation_records — url: line parsed (#395, :// survives first-colon partition), absent url:→'', claim null→None"
grade extract_machine_block   "klib-31 extract_machine_block — verbatim inner incl. heading, absent→None, CRLF, concept-store delegate parity (#341)"
grade replace_machine_block   "klib-32 replace_machine_block — inner swap preserves sentinels + surrounding bytes, absent→unchanged, concept-store delegate parity (#491)"
grade upsert_machine_block    "klib-33 upsert_machine_block — insert-after-H1 when absent, replace-when-present, idempotent, no-H1→prepend, Recent-syntheses preserved (#491)"
grade parse_portal_records    "klib-34 parse_portal_records — theme LEADIN + overview NARRATIVE blocks, empty-dropped, last-wins, CRLF, ''→empty (#491)"
grade parse_renarrate_records "klib-35 parse_renarrate_records — multi-line dedented prose, empty-prose omitted, last-slug-wins, unterminated-to-EOF, CRLF (#341)"
grade digit_anchor_tokens     "klib-36 digit_anchor_tokens — Artikel/Article 99 → {99}, multi-anchor, GENERIC_DENYLIST years excluded, no-digit→∅ (#345)"
grade parse_crossmerge_records "klib-37 parse_crossmerge_records — merge: slug|survivor|absorbed, whitespace strip, wrong-arity/empty-field dropped, comments, CRLF, ''→[] (#345)"
grade writer_quality_normalizers "klib-38 writer-quality normalizers (#309 P2) — normalize_tone/prose_density/citation_format/target_words + CITATION_FAMILY, valid passthrough, unknown→safe default, wikilink→ieee"
grade extract_page_frontmatter "klib-39 ingest-integrity frontmatter parsers (#413/#421) — extract_page_id_and_url id+sources, extract_page_content_hash quoted/unquoted-comment/absent/no-frontmatter→'' (shared by sweep + Phase-3 guard)"
grade resolve_wiki_scripts    "klib-40 resolve_wiki_scripts — single Python SSOT for the wiki-scripts probe, VENDORED-ONLY (cogni-wiki retired): the in-tree vendored dir resolves; an external sibling/versioned-cache layout never does; the base_dir seam is gone (TypeError); expected_script is the surviving vendor-integrity guard; unknown skill→FileNotFoundError naming the skill + --wiki-scripts-dir and offering no cogni-wiki remedy"
grade load_pypdf              "klib-41 load_pypdf (#583) — fail-soft optional import: returns None (absent) or a module with PdfReader (present), never raises, stable verdict across calls"
grade extract_pdf_text        "klib-42 extract_pdf_text (#583) — reason vocabulary (ok/pypdf_unavailable/no_text_layer/extract_failed) via injected fake pypdf, min_chars gate boundary, per-page exception skip, page count reported"
grade resolve_author_year     "klib-43 resolve_author_year — explicit author:/published_date: beat the publisher:/fetched_at: surrogates; a legacy page carrying only the surrogates still resolves non-empty on both legs; neither/no-frontmatter/degenerate -> ('',''), never raises"
grade citation_family_dispatch "klib-44 citation_family (#1748) — the first functional reader of CITATION_FAMILY: ieee/chicago→numbered, apa/mla/harvard→author_date, case/whitespace-insensitive, wikilink alias→numbered, and unknown/''/None→numbered rather than KeyError"
grade strip_author_date_citation_markers "klib-45 strip_author_date_citation_markers (#1748) — APA/MLA/Harvard markers removed with no residue, multiple per sentence, no-op when absent; scheme-anchored so ordinary parenthesized prose links and the [[N]] anti-pattern survive; strip_citation_markers BRANCHES (author-date marker survives under ieee, numbered marker survives under apa)"
grade extract_author_date_citation_urls "klib-46 extract_author_date_citation_urls (#1748) — the edge set klib-11 pins, transposed: appearance order, file:// first-class, unbracketed file:// with a literal space captured whole, angle-bracketed form, mixed file+http both in order, URL-less marker and ''→[]; scheme-anchored; extract_citation_urls dispatches per family"
grade build_author_date_reference_list "klib-47 build_author_date_reference_list (#1748) — dedup by SOURCE identity not rendered string, alphabetical by surname across 'Last, First' and 'First Last', un-numbered (no **[N]**/[[N]]), ('','')+surname-less publisher surrogate sort last without raising, slug tiebreak, empty/None→[]"
grade page_type_line "klib-48 page_type_line (#931) — the reader-facing Type: <Display> · <stage> header: per-type display name and stage word for all seven types, U+00B7 middle dot as the separator and never an ASCII substitute, case-insensitive key, and the fail-safe arms (unknown -> title-cased + raw, None/empty -> Unknown + raw, non-str int coerced) that must never raise"
grade author_date_reference_entry "klib-51 author_date_reference_entry — the three author-date bibliography strings, pinned per format by full-string equality AND asserted pairwise distinct so a collapse onto one shared shape cannot pass; mla's period inside the closing quote; un-numbered (no **[N]**/[[N]]); a numbered format (incl. the wikilink alias and unknown/''/None) renders '' rather than guessing an author-date shape; and the four degradations — no year -> n.d., no author -> title-first per format, no publisher dropped (mla folds to the bare year), no url dropped with harvard's 'Available at:' — plus md_link_dest angle-bracketing a paren-bearing URL, none of which may raise"
grade parse_distilled_claims_with_backlinks "klib-49 parse_distilled_claims_with_backlinks (#885) — the dual-level retrieval join reader: claim_id + text + backlinks and nothing else, inline list parsed with or without a space after the comma, order preserved, missing/empty backlinks normalized to [] so every claim carries the key, the with_id sibling left byte-identical (additive), and inline []/no key/empty/no-frontmatter -> []"
grade strip_author_date_destination_less "klib-52 strip_author_date_citation_markers, destination-less arm (#1755) — the DESTINATION-LESS ([Author, Year]) / ([Author]) / ([Author Year]) form a URL-less source now renders under apa/mla/harvard is stripped with no residue, direct and through strip_citation_markers; a destination-bearing marker is still consumed WHOLE by the URL arm (no orphan-paren residue); the negatives survive byte-for-byte ((see Smith, 2020) unbracketed prose, (see [the annex](#section-3)), a non-http(s)/file destination, and the [[N]] anti-pattern); and the dispatcher still BRANCHES both ways (destination-less marker survives under ieee, numbered marker survives under apa)"
grade extract_author_date_destination_less "klib-53 extract_author_date_citation_urls vs the destination-less form (#1755) — widening STRIP leaks no phantom URL into EXTRACT: all three destination-less shapes and a non-http(s)/file destination yield [] both directly and via extract_citation_urls, a real http/file destination in the SAME string still extracts in appearance order, and _AUTHOR_DATE_CITATION_URL_RE stays scheme-anchored"

# --- klib-50: check/grade census -------------------------------------------
# The census computation lives in fixtures/test_helpers.sh as
# check_grade_census; that function's header carries the full rationale — why
# it is bash-only, why every extraction is `|| true`-guarded under `set -eu`,
# why it owns its own scratch dir and installs no EXIT trap, and which two
# anchors must not be simplified. #1753 found two orphans in this file; this
# case is what keeps a third from hiding. NON-FATAL — it folds into $errors so
# the rest of the report still prints.
census_verdict=$(check_grade_census "$0")

census_desc="check/grade census - every registered tag has exactly one grade line and every grade line exactly one registration; duplicates on either side and an empty extraction are rejected too, so a third orphan cannot hide"
if [ "$census_verdict" = "PASS" ]; then
  green "PASS: klib-50 $census_desc"
else
  red "FAIL: klib-50 $census_desc ($census_verdict)"
  errors=$((errors + 1))
fi


if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All _knowledge_lib.py cases pass."

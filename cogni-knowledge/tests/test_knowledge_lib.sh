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


check("strip_inline_citation_markers", assert_strip_inline_citation_markers)
check("identity", assert_identity)
check("canonicalization", assert_canonicalization)
check("atomic_write_roundtrip", assert_atomic_write_roundtrip)
check("slugify", assert_slugify)
check("ref_heading", assert_ref_heading)
check("first_url", assert_first_url)
check("md_link_dest", assert_md_link_dest)
check("strip_reference_section", assert_strip_reference_section)
check("renumber_inline_citations", assert_renumber_inline_citations)
check("parse_pre_extracted_claims", assert_parse_pre_extracted_claims)
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
grade slugify                 "slugify — German umlaut transliteration (für→fuer), NFKD de-accent, empty/non-alnum→'' contract, max-len truncation"
grade ref_heading             "ref_heading — localized reference heading (de→Referenzen), default/unknown→References"
grade first_url               "first_url — JSON-list + non-JSON fallback URL extraction, no charset over-strip"
grade md_link_dest            "md_link_dest — angle-brackets a destination containing parens/space (paren-URL citation links)"
grade strip_reference_section "strip_reference_section — language-independent strip, #301 first-line match, synonym safety-net, preserves a non-reference bullet section"
grade renumber_inline_citations "renumber_inline_citations — full-source-drop gap [1][3]→[1][2], no-op when contiguous, synthesis markers remapped"
grade parse_pre_extracted_claims "parse_pre_extracted_claims — block-list dicts incl. colon-in-value; malformed/empty frontmatter fails safe to [] (#305)"
grade strip_inline_citation_markers "strip_inline_citation_markers — removes <sup>[N](url)</sup> / <sup>[N]</sup>, multiple markers, no-op when absent (#305 review)"

if [ $errors -gt 0 ]; then
  red "$errors case(s) failed."
  exit 1
fi

green ""
green "All _knowledge_lib.py cases pass."

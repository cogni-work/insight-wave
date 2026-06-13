# knowledge-finalize — Step 5/6 compose + atomic-write subprocess

Reference-grade detail for `skills/knowledge-finalize/SKILL.md` Step 5/6 ("Compose +
Atomic write"). This is the **verbatim** Python subprocess the orchestrator runs to
compose the synthesis page in memory and write it atomically — extracted here for
progressive disclosure so the SKILL.md body stays lean. The body keeps the imperative
step, the env-input list, and the output contract; this file holds the exact code to run.

**Behavior is unchanged** — the orchestrator runs this block exactly as before; only its
storage location moved (body → reference). `tests/test_finalize_contract.sh` greps this
file for the per-string contract assertions that previously targeted the body block.

## Contract

**Env inputs** (set on the `python3 -c` invocation, the same line prefix shown below):
`KNOWLEDGE_SCRIPTS` (the plugin `scripts/` dir, prepended to `sys.path`), `WIKI_ROOT`,
`PROJECT_PATH`, `PROJECT_SLUG`, `SYNTHESIS_SLUG`, `DRAFT_VERSION`, `REVISION_ROUND`,
`VERIFY_VERBATIM` / `VERIFY_PARAPHRASE` / `VERIFY_SYNTHESIS` / `VERIFY_UNSUPPORTED` (the
Step-2 verify counts, written into the synthesis `verification_ratio:` frontmatter), and
`QUESTION_SLUGS_CSV` (the Step 4.7 forward-link slugs, or empty).

**Output:** the subprocess **atomically writes** `<WIKI_ROOT>/wiki/syntheses/<SYNTHESIS_SLUG>.md`
(via `_knowledge_lib.atomic_write_text`) and emits **one trailing JSON line** on stdout
carrying `{"output_language": ..., "cited_source_slugs": [...]}`. The orchestrator captures
that line into `COMPOSE_JSON` (heredoc-quoted) immediately after the call — see the SKILL.md
body for the capture step and how `COMPOSE_JSON` is reused (Step 9 refresh-candidate clear,
Step 10.6 contradictor).

Steps 5 and 6 are bundled into this single subprocess to keep compose + write atomic
relative to retry — a re-run sees the same wiki state.

## Subprocess (run verbatim)

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<wiki_root>" \
PROJECT_PATH="<project_path>" \
PROJECT_SLUG="<project-slug>" \
SYNTHESIS_SLUG="<synthesis-slug>" \
DRAFT_VERSION=<N> \
REVISION_ROUND=<round> \
VERIFY_VERBATIM=<verbatim count from Step 2> \
VERIFY_PARAPHRASE=<paraphrase count from Step 2> \
VERIFY_SYNTHESIS=<synthesis count from Step 2> \
VERIFY_UNSUPPORTED=<unsupported count from Step 2> \
QUESTION_SLUGS_CSV="$QUESTION_SLUGS_CSV" \
python3 -c '
import datetime as _dt
import json, os, re, sys
from pathlib import Path
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from _knowledge_lib import (
    atomic_write_text, ref_heading, first_url, md_link_dest,
    strip_reference_section, renumber_inline_citations,
    normalize_citation_format,
)

wiki_root = Path(os.environ["WIKI_ROOT"])
project = Path(os.environ["PROJECT_PATH"])
project_slug = os.environ["PROJECT_SLUG"]
synthesis_slug = os.environ["SYNTHESIS_SLUG"]
n = int(os.environ["DRAFT_VERSION"])
revision_round = int(os.environ["REVISION_ROUND"])
# the four verdict counts already captured at Step 2
# (verify-vN.json::counts) are threaded in so the synthesis-page frontmatter
# carries a machine-readable record of WHAT verification ran. These describe a
# citation-consistent (zero-network) check — see verification: key below.
v_verbatim = int(os.environ.get("VERIFY_VERBATIM", "0"))
v_paraphrase = int(os.environ.get("VERIFY_PARAPHRASE", "0"))
v_synthesis = int(os.environ.get("VERIFY_SYNTHESIS", "0"))
v_unsupported = int(os.environ.get("VERIFY_UNSUPPORTED", "0"))
verification_ratio = f"verbatim={v_verbatim} paraphrase={v_paraphrase} synthesis={v_synthesis} unsupported={v_unsupported}"

draft = (project / "output" / ("draft-v" + str(n) + ".md")).read_text(encoding="utf-8")
manifest = json.loads((project / ".metadata" / "citation-manifest.json").read_text(encoding="utf-8"))
plan = json.loads((project / ".metadata" / "plan.json").read_text(encoding="utf-8"))

topic = plan.get("topic", "").strip() or synthesis_slug
# Reference-section heading localizes off the projects output_language (the
# same value knowledge-compose threads to wiki-composer). Default en. Used for
# BOTH the language-independent strip of the composers tail and the heading we
# re-emit, so the deposited page never carries two reference sections.
output_language = (plan.get("output_language") or "en")
heading = ref_heading(output_language)
# Citation-format reference-string selection (#309 P2). ieee + chicago BOTH render
# the numbered <sup>[N]</sup> inline shape, so the renumber pass + scans below are
# unchanged across them — only the bibliography STRING differs (ieee:
# `Publisher, "Title"`; chicago: `Publisher. "Title."`). apa/mla/harvard are the
# staged author-date follow-up: the composer renders them as numbered, so they
# fall through to the ieee string here too (no author-date reference rows until
# the format-aware finalize rework lands). Validation (lowercase, wikilink→ieee,
# unknown→ieee) lives once in _knowledge_lib.normalize_citation_format — the
# single source of truth the composer/plan also resolve through.
citation_format = normalize_citation_format(plan.get("citation_format"))
# UTC date so frontmatter created/updated align with Step 10s `date -u +%F` log
# stamp. Mixed local/UTC across midnight produced cross-artifact date skew.
today = _dt.datetime.now(_dt.timezone.utc).date().isoformat()

# Dedupe cited page slugs preserving first-seen order. claim_id is allowed to
# be null (synthesis-page citations per agents/wiki-composer.md), so we key
# only on wiki_slug.
cited_slugs = []
seen = set()
for c in manifest.get("citations", []) or []:
    s = (c or {}).get("wiki_slug")
    if isinstance(s, str) and s and s not in seen:
        seen.add(s)
        cited_slugs.append(s)

# Lookup each cited pages kind + title + publisher. Try wiki/sources/ first
# (the common case — Phase-4 source ingest); fall back to wiki/syntheses/
# (wiki-composer cites prior syntheses with claim_id: null), then the two
# distilled dirs (concepts/entities — the composer cites
# them with a dcl-NNN claim_id, no external URL), then wiki/questions/ (a
# type:question node cited with an acl-NNN claim_id, no external URL — the 4th
# evidence family; INERT until the composer is taught to cite one).
# page_kind gates whether the reference row gets a bare [[<slug>]] backlink
# below: a page that exists (source / synthesis / distilled / question) does;
# a missing page (page_kind None) does not.
def _parse_top_level_kv(fm_block):
    out = {}
    for line in fm_block.splitlines():
        # Skip indented lines so nested keys under pre_extracted_claims: dont
        # overwrite top-level title/publisher.
        if not line or line[0] in (" ", "\t") or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        k = key.strip()
        # Strip surrounding quote pair (ASCII single/double + curly variants).
        v = val.strip()
        if len(v) >= 2 and v[0] == v[-1] and v[0] in ("\"", "'", "“", "‘"):
            v = v[1:-1]
        # Also strip a paired curly closing if it sneaked through.
        v = v.strip("“”‘’")
        out[k] = v
    return out

# Reference list, numbered in citation-manifest first-appearance order so the
# deposited [N] match the composers inline [N] markers (which finalize leaves
# in the body verbatim — see the strip note below). N = index + 1. The URL
# extraction, link-destination escaping, reference-section strip, and inline
# renumber all live in _knowledge_lib (unit-tested) — see first_url /
# md_link_dest / strip_reference_section / renumber_inline_citations.
refs = []
page_kind_by_slug = {}
for idx, slug in enumerate(cited_slugs):
    n = idx + 1
    page_path = None
    page_kind = None
    for kind, dirname in (
        ("source", "sources"),
        ("synthesis", "syntheses"),
        ("concept", "concepts"),
        ("entity", "entities"),
        ("question", "questions"),  # 4th evidence family — answer_claims:
    ):
        candidate = wiki_root / "wiki" / dirname / (slug + ".md")
        if candidate.is_file():
            page_path = candidate
            page_kind = kind
            break
    page_kind_by_slug[slug] = page_kind  # None if cited page is missing on disk
    title = slug
    publisher = ""
    url = ""
    if page_path is not None:
        text = page_path.read_text(encoding="utf-8")
        if text.startswith("---"):
            # Tolerant frontmatter close: optional trailing newline.
            m = re.match(r"^---[ \t]*\r?\n(.*?)\r?\n---[ \t]*(?:\r?\n|\Z)", text, re.DOTALL)
            if m:
                fm = _parse_top_level_kv(m.group(1))
                if fm.get("title"):
                    title = fm["title"]
                if fm.get("publisher"):
                    publisher = fm["publisher"]
                if page_kind == "source":
                    url = first_url(fm.get("sources", ""))
    # Bare `[[<slug>]]` backlink so the synthesis->source forward edge actually
    # registers in cogni-wiki's link graph. WIKILINK_RE only matches a BARE slug
    # (cogni-wiki/skills/wiki-ingest/scripts/_wikilib.py), so a path-prefixed
    # `[[sources/<slug>]]` matches the slash-free grammar nowhere — it is
    # invisible: neither an inbound link (every cited source counts as an orphan
    # -> the literal 100% orphan rate) nor a broken link. Slugs are globally
    # unique across the per-type dirs, so the bare slug addresses the page with
    # no path. The reverse (source->synthesis) edge is backfilled by the Step
    # 10.5 `lint_wiki.py --fix=reverse_link_missing` gate, de-orphaning both ends.
    #
    # Emit the backlink ONLY when the cited page exists on disk (page_kind is not
    # None). A missing page would make bare `[[<slug>]]` a broken_wikilink that
    # health.py flags as an error and fails the Step 10.5 gate — so a missing
    # cited page gets a reference row with NO wikilink (the graceful-degradation
    # edge that the old invisible `[[sources/<slug>]]` form silently tolerated).
    backlink = ("[[" + slug + "]]") if page_kind is not None else ""
    if citation_format == "chicago":
        # Chicago bibliography string: publisher/author-first, period-separated.
        bib = (publisher + '. "' + title + '."') if publisher else ('"' + title + '."')
    else:
        # IEEE (default; also the staged apa/mla/harvard numbered fallback).
        bib = (publisher + ', "' + title + '"') if publisher else ('"' + title + '"')
    # Numbered entry (ieee/chicago). Clickable [URL](URL) when the source page
    # carries an http(s) URL (angle-bracketed via md_link_dest when it contains
    # parens). The trailing " — [[<slug>]]" backlink is appended only for a cited
    # page that exists on disk.
    entry = "**[" + str(n) + "]** " + bib
    if url:
        entry += ". [" + url + "](" + md_link_dest(url) + ")"
    if backlink:
        entry += " — " + backlink
    refs.append(entry)

# `wiki://<slug>` is the bare-slug shape cogni-wiki health.py expects
# (cogni-wiki/skills/wiki-health/scripts/health.py:206 splits on the prefix
# and looks the bare slug up in slug_index). A `wiki://<wiki_slug>/<slug>`
# composite would trip `broken_wiki_source` on every cited entry.
#
# Emit a `wiki://` source ONLY for a cited page that exists on disk — the same
# page_kind gate the body backlink uses. health.py's `broken_wiki_source` flags
# any `wiki://<slug>` whose target is not in the slug index as an ERROR, so a
# cited page that went missing between ingest and finalize would otherwise fail
# the Step 10.5 health gate even though its body backlink was suppressed. The
# missing slug is still surfaced via the Step 11 "Missing pages" warning.
sourced_slugs = [s for s in cited_slugs if page_kind_by_slug.get(s) is not None]
if sourced_slugs:
    sources_block = "sources:\n" + "\n".join("  - wiki://" + slug for slug in sourced_slugs)
else:
    # Empty list emits inline (matches `tags: []` shape) instead of the
    # block-style `sources:\n  []` continuation, which strict YAML parsers
    # mis-read as the literal string "[]".
    sources_block = "sources: []"

frontmatter = (
    "---\n"
    "id: " + synthesis_slug + "\n"
    # Quote the title via json.dumps (NOT a hand-wrapped "..."): a topic with a
    # colon-space ("X: Y" — routine for regulatory/subtitled topics like
    # "NIS2-Richtlinie (NIS2UmsuCG): Anwendungsbereich …") parses as a nested
    # YAML mapping when unquoted ("mapping values are not allowed here"), breaking
    # Obsidian / yaml.safe_load / yq even though cogni-wiki's lenient first-colon
    # parser tolerates it. json.dumps handles colons, embedded quotes, and unicode
    # in one shot — the same serializer source-ingester + concept-store already
    # use. A hand-wrapped "..." would re-break on a topic that itself contains a ".
    "title: " + json.dumps(topic, ensure_ascii=False) + "\n"
    "type: synthesis\n"
    "tags: [synthesis]\n"
    "created: " + today + "\n"
    "updated: " + today + "\n"
    + sources_block + "\n"
    "derived_from_research: " + project_slug + "\n"
    "draft_revision_round: " + str(revision_round) + "\n"
    # declare WHAT "verified" means on the durable artefact. verification
    # is a fixed enum — the Phase 6 verifier scored each citation's draft_sentence
    # against the cited page's ingest-time pre_extracted_claims:, zero-network, no
    # live-source re-fetch. verification_ratio is the same verify-vN.json::counts
    # the dashboard surfaces, kept as ONE double-quoted flat string scalar (NOT a
    # nested `verification_counts: {verbatim: 4, ...}` map) on purpose: it matches
    # cogni-wiki's existing flat-frontmatter convention (same shape as
    # draft_revision_round) so _wikilib.parse_frontmatter reads it without YAML-map
    # support, and it stays an additive, tolerated key. If a future consumer needs
    # structured access, switching to a nested map is the right moment to do it
    # (a breaking frontmatter change). For live-source re-verification: knowledge-refresh --resweep.
    "verification: citation_consistent_zero_network\n"
    'verification_ratio: "' + verification_ratio + '"\n'
    "---\n"
)

# Strip a leading H1 from the draft body (we set our own title via frontmatter).
body = draft.lstrip()
if body.startswith("# "):
    nl = body.find("\n")
    body = body[nl + 1 :].lstrip() if nl >= 0 else ""

# Strip the composer's own reference section (it re-emits below) so the page
# never carries two; LANGUAGE-INDEPENDENT (localized heading + English, anchored
# so a heading on the first/last body line still matches) with a
# content-preserving safety net. Then renumber the body's inline `<sup>[N]`
# markers to a contiguous 1..K matching the re-derived reference list (closes a
# gap left by a revisor full-source-drop). Both transforms are unit-tested in
# _knowledge_lib (strip_reference_section / renumber_inline_citations).
body = strip_reference_section(body, heading)
body = renumber_inline_citations(body)

page_text = (
    frontmatter
    + "\n"
    + "# " + topic + "\n\n"
    + body.rstrip() + "\n\n"
    + "## " + heading + "\n\n"
    + ("\n".join(refs) if refs else "_No external citations recorded in citation-manifest.json._")
    + "\n"
)

# Append the synthesis->question forward links AFTER the reference block. Each
# is a BARE `[[<slug>]]` (the only form cogni-wiki WIKILINK_RE matches — same as
# the reference-row backlinks above), so the edge registers in the link graph
# and the Step 10.5 `lint --fix=reverse_link_missing` gate backfills the reverse
# `[[<synthesis-slug>]]` into each question page's `## See also`. Emit a link
# ONLY for a question page that exists on disk (the same is_file() existence
# gate the reference-row backlinks use) so a page deleted between ingest and
# finalize never becomes a `broken_wikilink` that fails the Step 10.5 health
# gate. These links live in the BODY, never in `sources:` and never in the
# citation manifest, so cycle-guard (which walks only those two) cannot see them.
question_slugs_csv = os.environ.get("QUESTION_SLUGS_CSV", "")
question_links = []
seen_questions = set()  # dedupe (same idiom as cited_slugs above) — defensive
for qslug in (s.strip() for s in question_slugs_csv.split(",")):
    if not qslug or qslug in seen_questions:
        continue
    seen_questions.add(qslug)
    if (wiki_root / "wiki" / "questions" / (qslug + ".md")).is_file():
        question_links.append(qslug)
if question_links:
    page_text += (
        "\n## Research questions\n\n"
        + "\n".join("- [[" + s + "]]" for s in question_links)
        + "\n"
    )

out_path = wiki_root / "wiki" / "syntheses" / (synthesis_slug + ".md")
out_path.parent.mkdir(parents=True, exist_ok=True)
atomic_write_text(out_path, page_text)

# Surface counts the orchestrator needs for Steps 7-11.
n_missing = sum(1 for k in page_kind_by_slug.values() if k is None)
# Step 10.6 (contradiction tripwire) reuses the page_kind resolution
# this subprocess already did — passing the filtered claim-bearing slug
# list through avoids a second pass over the citation manifest in the
# orchestrator and keeps the page-kind decision in one place. The
# contradictor compares against any page with a claim block:
# pre_extracted_claims: (sources), distilled_claims: (the two distilled
# kinds — concept/entity), or answer_claims: (question
# nodes). Synthesis-page citations are excluded (synthesis pages
# carry no claim block); missing pages (page_kind None) are excluded here
# and reported via missing_pages[]. Var name kept (CITED_SOURCE_SLUGS) for
# input-contract stability; the semantics cover source + distilled +
# question slugs. INERT for now — the composer cites no question node yet,
# so `question` never appears in cited_source_slugs until composer activation.
_CLAIM_BEARING_KINDS = {"source", "concept", "entity", "question"}
cited_source_slugs = [s for s in cited_slugs if page_kind_by_slug.get(s) in _CLAIM_BEARING_KINDS]
print(json.dumps({
    "synthesis_path": str(out_path.relative_to(wiki_root).as_posix()),
    "n_sources": len(cited_slugs),
    "n_synthesis_citations": sum(1 for k in page_kind_by_slug.values() if k == "synthesis"),
    "n_missing_pages": n_missing,
    "n_question_links": len(question_links),
    "topic": topic,
    "output_language": output_language,
    "cited_source_slugs": cited_source_slugs,
}))
'
```

# knowledge-distill — bundle-builder subprocesses

Reference-grade detail for `skills/knowledge-distill/SKILL.md`. These are the
**verbatim** `python3 -c` bundle-builder subprocesses the orchestrator runs at
Steps 1, 2, 4.5, 6.6a, and 6.7a — extracted here for progressive disclosure so
the SKILL.md body stays lean. The body keeps the imperative step, the env-input
list, and the "capture the printed count" instruction for each; this file holds
the exact code to run.

**Behavior is unchanged** — the orchestrator runs each block exactly as before;
only its storage location moved (body → reference). `tests/test_distill_contract.sh`
greps this file for the one moved-only string (`extract_machine_block`, §4); every
other per-string assertion still targets the SKILL.md body, which retains the prose
naming each primitive.

Each subprocess prints a single count on stdout (source / page / candidate / slug
/ question count) that the orchestrator captures per the SKILL.md body step.

## 1. Claim bundle (Step 1)

**Env inputs:** `KNOWLEDGE_SCRIPTS` (plugin `scripts/`, prepended to `sys.path`), `WIKI_ROOT`, `MANIFEST_PATH` (the ingest manifest), `BUNDLE_PATH` (output `distill-bundle.txt`). Prints the count of sources carrying claims.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
MANIFEST_PATH="<project_path>/.metadata/ingest-manifest.json" \
BUNDLE_PATH="<project_path>/.metadata/distill-bundle.txt" \
python3 -c '
import json, os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import parse_pre_extracted_claims
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki" / "sources"
man = json.loads(Path(os.environ["MANIFEST_PATH"]).read_text(encoding="utf-8"))
lines = []
for e in man.get("ingested", []):
    slug = e.get("slug", "")
    page = wiki / (slug + ".md")
    if not slug or not page.is_file():
        continue
    title = e.get("title", "") or slug
    claims = parse_pre_extracted_claims(page.read_text(encoding="utf-8"))
    if not claims:
        continue
    lines.append("## source: " + slug + " | " + title)
    for c in claims:
        cid = c.get("id", "")
        text = " ".join(str(c.get("text", "")).split())
        if cid and text:
            # Emit the FULL 3-part provenance per claim line (`<slug> | <id> | <text>`)
            # so the distiller copies the triple VERBATIM into its records — no
            # per-line slug reconstruction from the `## source:` header (a verbatim
            # copy of a 2-part line would parse to an empty claim_id and be dropped).
            lines.append(slug + " | " + cid + " | " + text)
    lines.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(lines) + "\n", encoding="utf-8")
print(len([l for l in lines if l.startswith("## source:")]))
'
```

## 2. Existing concept/entity slug index (Step 2)

**Env inputs:** `KNOWLEDGE_SCRIPTS`, `WIKI_ROOT`, `INDEX_PATH` (output `distill-slug-index.txt`). Prints the existing distilled-page count.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
INDEX_PATH="<project_path>/.metadata/distill-slug-index.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import _FRONTMATTER_RE, _unquote_scalar
import re
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
title_re = re.compile(r"^title[ \t]*:[ \t]*(.+?)[ \t]*$")
out = []
# keep in sync with concept-store.py::_TYPE_DIRS (concept/entity/person)
for ptype, sub in (("concept", "concepts"), ("entity", "entities"), ("person", "people")):
    d = wiki / sub
    if not d.is_dir():
        continue
    for p in sorted(d.glob("*.md")):
        m = _FRONTMATTER_RE.match(p.read_text(encoding="utf-8"))
        title = p.stem
        if m:
            for line in m.group(1).splitlines():
                tm = title_re.match(line)
                if tm:
                    title = _unquote_scalar(tm.group(1).strip()); break
        out.append(p.stem + " | " + ptype + " | " + title)
Path(os.environ["INDEX_PATH"]).write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
print(len(out))
'
```

## 3. Cross-lingual candidate bundle (Step 6.6a)

**Env inputs:** `CAND_JSON` (the `xlingual-candidates` envelope), `BUNDLE_PATH` (output `xlingual-candidates.txt`). Prints the candidate-pair count.

```
CAND_JSON="<project_path>/.metadata/xlingual-candidates.json" \
BUNDLE_PATH="<project_path>/.metadata/xlingual-candidates.txt" \
python3 -c '
import json, os
from pathlib import Path
d = json.loads(Path(os.environ["CAND_JSON"]).read_text(encoding="utf-8"))
cands = d.get("data", {}).get("candidates", []) if d.get("success") else []
out = []
for c in cands:
    out.append("## candidate: " + c.get("slug", ""))
    out.append("a_id: " + c.get("a_id", ""))
    out.append("a_text: " + " ".join(str(c.get("a_text", "")).split()))
    out.append("b_id: " + c.get("b_id", ""))
    out.append("b_text: " + " ".join(str(c.get("b_text", "")).split()))
    out.append("shared_anchors: " + ", ".join(c.get("shared_anchors", [])))
    out.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(out) + ("\n" if out else ""), encoding="utf-8")
print(len(cands))
'
```

## 4. Re-narrate bundle (Step 6.7a)

**Env inputs:** `KNOWLEDGE_SCRIPTS`, `WIKI_ROOT`, `UPDATED_SLUGS` (space-separated, from Step 6), `BUNDLE_PATH` (output `renarrate-bundle.txt`). Prints the slug count.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_ROOT="<WIKI_ROOT>" \
UPDATED_SLUGS="<space-separated updated_slugs from Step 6>" \
BUNDLE_PATH="<project_path>/.metadata/renarrate-bundle.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import extract_machine_block, parse_distilled_claims
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
out = []
for slug in os.environ["UPDATED_SLUGS"].split():
    page = None
    # keep in sync with concept-store.py::_TYPE_DIRS (concept/entity/person)
    for sub in ("concepts", "entities", "people"):
        cand = wiki / sub / (slug + ".md")
        if cand.is_file():
            page = cand; break
    if page is None:
        continue
    text = page.read_text(encoding="utf-8")
    inner = extract_machine_block(text, "SUMMARY") or ""
    # Drop the leading `## Summary` heading + blank line — the bundle wants prose only.
    prose_lines = [ln for ln in inner.splitlines() if ln.strip() != "## Summary"]
    while prose_lines and not prose_lines[0].strip():
        prose_lines.pop(0)
    claims = parse_distilled_claims(text)
    out.append("## slug: " + slug)
    out.append("### current-summary")
    out.append("\n".join(prose_lines) if prose_lines else "_No summary yet._")
    out.append("### claims")
    for c in claims:
        t = " ".join(str(c.get("text", "")).split())
        if t:
            out.append("- " + t)
    out.append("")
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(out) + "\n", encoding="utf-8")
print(len([l for l in out if l.startswith("## slug:")]))
'
```

## 5. Answer bundle (Step 4.5)

**Env inputs:** `KNOWLEDGE_SCRIPTS`, `WIKI_SCRIPTS` (`$WIKI_INGEST_SCRIPTS`, for `_wikilib.split_frontmatter`), `WIKI_ROOT`, `BUNDLE_PATH` (output `answer-bundle.txt`). Prints the answerable-question count.

```
KNOWLEDGE_SCRIPTS="${CLAUDE_PLUGIN_ROOT}/scripts" \
WIKI_SCRIPTS="$WIKI_INGEST_SCRIPTS" \
WIKI_ROOT="<WIKI_ROOT>" \
BUNDLE_PATH="<project_path>/.metadata/answer-bundle.txt" \
python3 -c '
import os, sys
sys.path.insert(0, os.environ["KNOWLEDGE_SCRIPTS"])
sys.path.insert(0, os.environ["WIKI_SCRIPTS"])
from pathlib import Path
from _knowledge_lib import parse_pre_extracted_claims
from _wikilib import split_frontmatter
wiki = Path(os.environ["WIKI_ROOT"]) / "wiki"
qdir = wiki / "questions"
lines = []
n_q = 0
for page in sorted(qdir.glob("*.md")) if qdir.is_dir() else []:
    fm, _body = split_frontmatter(page.read_text(encoding="utf-8"))
    answering = fm.get("sources_answering") or []
    if not answering:
        continue
    title = fm.get("title", "") or page.stem
    block = ["## question: " + page.stem + " | " + str(title)]
    for src in answering:
        sp = wiki / "sources" / (str(src) + ".md")
        if not sp.is_file():
            continue
        for c in parse_pre_extracted_claims(sp.read_text(encoding="utf-8")):
            cid = c.get("id", "")
            text = " ".join(str(c.get("text", "")).split())
            if cid and text:
                # FULL 3-part provenance per line — the distiller copies it verbatim.
                block.append(str(src) + " | " + cid + " | " + text)
    if len(block) > 1:  # the question has at least one answering claim
        lines.extend(block); lines.append(""); n_q += 1
Path(os.environ["BUNDLE_PATH"]).write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
print(n_q)
'
```

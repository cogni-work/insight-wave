"""Parser for the schema-4.1 presentation-brief slide grammar.

Written for test-slide-grammar.sh. Deliberately standalone rather than routed
through scripts/parse-brief.py: two of the three bound surfaces are template
fragments (no frontmatter, {placeholder} headlines, and slide numbers written
N / N+1 / N+2) that parse-brief.py's
SLIDE_HEADING_RE = ^##\\s+Slide\\s+(\\d+)\\s*: rejects by construction, and whose
strict 1..N numbering its full-brief checklist rejects by design. Loosening that
checker to admit them would weaken it for real briefs, which is the worse trade.

Two ops:

    <check-name> <role>=<path> ...   grade one check; exit 1 on findings
    locate <role>=<path> <selector>  print a 0-based line index (mutation targets)

Exit codes are the harness's whole discriminator, so they are a contract --
the same 0/1/2 split check-brief.py draws with its CheckError and
brief-render-qa.py with its QAError, so this fixture reads like its neighbours:

    0  the check ran and found nothing
    1  the check ran and found something -- the ONLY code that means a finding
    2  the tool was misused or could not run (unknown check, unreadable
       surface, malformed argv, bad selector). Never a grammar finding.

Before that split, an unknown check name and a missing file both raised and
exited 1, indistinguishable from a real finding: every red arm accepted any
non-zero, so nine cases could assert nothing and still report PASS. Anything
that widens exit 1 to cover a crash reopens that hole.
"""
import json
import re
import sys
import traceback

EXIT_USAGE = 2


class UsageError(Exception):
    """The tool was misused or could not run. Exits EXIT_USAGE, never 1."""


HEADING_RE = re.compile(r"^##\s+Slide\s+(\S+)\s*:")
ANY_H2_RE = re.compile(r"^##\s+")
# Deliberately looser than HEADING_RE, and never derived from it: this is the
# independent recount heading-counts cross-checks the graded set against, so a
# narrowing of HEADING_RE has to leave it untouched to be detectable.
LOOSE_SLIDE_RE = re.compile(r"^##\s+Slide\b")
FENCE_RE = re.compile(r"^```(\S*)\s*$")
TOPLEVEL_KEY_RE = re.compile(r"^([A-Za-z][A-Za-z0-9_-]*):")
# The colour scan's own key regex, deliberately NOT shared with TOPLEVEL_KEY_RE.
# Matches at any indentation and tolerates space before the colon, mirroring
# check-brief.py's check_no_color_fields, which walks _keys() recursively and
# flags `Background : x` too. CASE, not indentation, is what separates the
# permitted nested `role:` from the forbidden `Role:` (check-brief.py:81-82).
# TOPLEVEL_KEY_RE cannot simply be widened to match: two structural callers
# (subkey_counts, _locate) read its None-on-an-indented-line as "nested under
# the last key seen", so an `^\s*` there would zero the intent.role /
# visual.kind counts and turn sg08 red.
#
# Precision boundary, so the next author widening COLOUR_FIELDS knows it: this
# is a line regex, not a yaml parse, so it cannot tell a nested key from a line
# inside a `|` block scalar -- and the graded bodies do carry them
# (Speaker-Notes:, Diagram:). check-brief.py is structurally immune because it
# walks parsed yaml. The corpus is clean today (the newly-visible keys are all
# genuine nested ones), but Role, Mood and Intensity are ordinary English words,
# so a Speaker-Notes line opening `Mood: confident` would false-positive. If
# that ever bites, the fix is to route the fence body through
# parse-brief.py's parse_yaml_subset rather than to narrow this back.
ANY_DEPTH_KEY_RE = re.compile(r"^\s*([A-Za-z][A-Za-z0-9_-]*)\s*:")
SLIDE_KIND_ENUM = {"content", "internal-prep", "references"}

# presentation-brief-template.md:185 — "Three top-level keys are new in 4.1 and appear on
# every slide: Slide-Kind, intent and visual." Slide-Kind is graded on its own
# (it carries an enum); these two are the nested sub-keys of the other two.
REQUIRED_SUBKEYS = {"intent": "role", "visual": "kind"}

# Must equal check-brief.py's COLOR_KEYS_SLIDES. Pinned by a case rather than
# imported, so this fixture stays standalone while a divergence still goes red:
# check-brief.py derives every other profile's colour set from that tuple, so it
# is edited under pressure from briefs this suite never grades, and a silently
# stale copy here would narrow this suite's own coverage.
COLOUR_FIELDS = {"Background", "Text-Color", "Icon-Color", "Role", "Intensity", "Mood"}


def toplevel_key(line):
    """The line's top-level (unindented) yaml key, or None.

    Serves the STRUCTURAL checks -- Slide-Kind extraction, sub-key parenting in
    subkey_counts, and mutation targeting in _locate -- all of which read the
    None on an indented line as "this is nested under the last key seen". The
    colour scan deliberately does not use this: see any_depth_key.
    """
    m = TOPLEVEL_KEY_RE.match(line)
    return m.group(1) if m else None


def any_depth_key(line):
    """The line's yaml key at any indentation, or None. See ANY_DEPTH_KEY_RE."""
    m = ANY_DEPTH_KEY_RE.match(line)
    return m.group(1) if m else None


def _fence_map(lines):
    """Per-line "is inside a fenced block" flags, plus the state at EOF.

    Fence markers themselves are flagged False, so a heading can never be
    mistaken for a delimiter.
    """
    inside = []
    state = False
    for line in lines:
        if FENCE_RE.match(line):
            inside.append(False)
            state = not state
        else:
            inside.append(state)
    return inside, state


def parse(role, path):
    """Parse one surface into a graded document record.

    A slide's region runs from its heading to the next H2 -- any H2, not just the
    next slide heading. Anchoring on the next H2 is what keeps a trailing
    non-slide block, EXAMPLE_BRIEF.md's `## CTA Summary` fence, from being
    counted against the last slide.
    """
    lines = open(path, encoding="utf-8").read().split("\n")
    inside, open_at_eof = _fence_map(lines)

    heads = []
    loose = 0
    h2s = []
    for i, line in enumerate(lines):
        if inside[i]:
            continue
        if ANY_H2_RE.match(line):
            h2s.append(i)
        if LOOSE_SLIDE_RE.match(line):
            loose += 1
        m = HEADING_RE.match(line)
        if m:
            heads.append((i, m.group(1)))

    slides = []
    for start, label in heads:
        later = [h for h in h2s if h > start]
        end = later[0] if later else len(lines)
        region = range(start + 1, end)

        opens = []
        state = False
        for i in region:
            m = FENCE_RE.match(lines[i])
            if m:
                if not state:
                    opens.append((i, m.group(1)))
                state = not state

        first_content = next((i for i in region if lines[i].strip()), None)
        fence_open = opens[0][0] if opens else None
        fence_close = None
        body = []
        body_start = None
        if fence_open is not None:
            j = fence_open + 1
            body_start = j
            while j < len(lines) and not FENCE_RE.match(lines[j]):
                body.append(lines[j])
                j += 1
            fence_close = j if j < len(lines) else None

        slides.append(
            {
                "label": label,
                "line": start + 1,
                "heading_index": start,
                "fence_count": len(opens),
                "fence_tag": opens[0][1] if opens else None,
                "fence_is_first": fence_open is not None and first_content == fence_open,
                "fence_open": fence_open,
                "fence_close": fence_close,
                "body_start": body_start,
                "body": body,
            }
        )
    return {"role": role, "path": path, "slides": slides,
            "open_at_eof": open_at_eof, "loose_slide_count": loose}


def slide_kinds(slide):
    out = []
    for i, line in enumerate(slide["body"]):
        if toplevel_key(line) == "Slide-Kind":
            out.append((slide["body_start"] + i, line.split(":", 1)[1].strip()))
    return out


def colour_hits(slide):
    """Colour keys at any depth inside the slide's yaml body.

    Scoped to fenced body content, never whole-document text: EXAMPLE_BRIEF.md
    and presentation-brief-template.md both NAME these fields in prose, documenting that
    they are forbidden, so a whole-file grep goes red on a correct tree.
    Depth and spacing tolerance come from any_depth_key.
    """
    return [k for k in map(any_depth_key, slide["body"]) if k in COLOUR_FIELDS]


def subkey_counts(slide):
    """Count each required 4.1 parent key's nested sub-key (intent.role, visual.kind)."""
    counts = {p: 0 for p in REQUIRED_SUBKEYS}
    parent = None
    for line in slide["body"]:
        key = toplevel_key(line)
        if key is not None:
            parent = key if key in REQUIRED_SUBKEYS else None
            continue
        if parent and re.match(r"^\s+%s:" % REQUIRED_SUBKEYS[parent], line):
            counts[parent] += 1
    return counts


CHECKS = {}


def check(name):
    def deco(fn):
        CHECKS[name] = fn
        return fn
    return deco


def require(docs, role):
    """Documents carrying `role`, or an error that makes the check go RED.

    Roles are supplied by the caller rather than sniffed from the filename. A
    filename-scoped check grades nothing when a surface is renamed -- it
    self-skips and still reports green, which is the exact failure this suite
    exists to catch. Returning an error instead is what makes that skip visible.
    """
    hits = [d for d in docs if d["role"] == role]
    if not hits:
        return None, ["no document supplied for role %r -- check graded nothing" % role]
    return hits, []


def _per_slide(docs, grade):
    """Run `grade` over every slide, prefixing each message with its location."""
    return ["%s:%d slide %s %s" % (d["path"], s["line"], s["label"], m)
            for d in docs for s in d["slides"] for m in grade(s)]


@check("fences-balanced")
def _fences_balanced(docs):
    return ["%s has an unclosed fence at EOF" % d["path"] for d in docs if d["open_at_eof"]]


@check("one-yaml-fence-per-slide")
def _one_fence(docs):
    def grade(s):
        if s["fence_count"] != 1 or s["fence_tag"] != "yaml" or not s["fence_is_first"]:
            return ["(fences=%d tag=%s first=%s)"
                    % (s["fence_count"], s["fence_tag"], s["fence_is_first"])]
        return []
    return _per_slide(docs, grade)


@check("heading-counts")
def _heading_counts(docs):
    """Pin how many slides each surface contributes, and cross-check the pin.

    Two independent statements, because they fail differently. The per-role
    totals catch a narrowing of HEADING_RE -- a digits-only form grades 5 of 8
    in the template and 0 of 1 in the reference slide, then reports green. The
    graded-vs-loose comparison catches the same undercount without depending on
    the absolute numbers, so it still fires on a corpus that legitimately gained
    a slide (`## Slide 4a:` dropping out of the graded set reads as a count
    change to the pin, but as a mismatch here).
    """
    expected = {"brief": 13, "template": 8, "refslide": 1}
    bad = []
    for role, want in expected.items():
        hits, err = require(docs, role)
        if err:
            bad.extend(err)
            continue
        got = sum(len(d["slides"]) for d in hits)
        if got != want:
            bad.append("role %s graded %d slides, expected %d" % (role, got, want))
    for d in docs:
        if len(d["slides"]) != d["loose_slide_count"]:
            bad.append("%s graded %d slides but %d headings look like slides"
                       % (d["path"], len(d["slides"]), d["loose_slide_count"]))
    return bad


@check("slide-kind-single")
def _kind_single(docs):
    def grade(s):
        kinds = slide_kinds(s)
        return [] if len(kinds) == 1 else ["has %d Slide-Kind keys" % len(kinds)]
    return _per_slide(docs, grade)


@check("slide-kind-enum")
def _kind_enum(docs):
    def grade(s):
        return ["Slide-Kind=%r" % v for _, v in slide_kinds(s) if v not in SLIDE_KIND_ENUM]
    return _per_slide(docs, grade)


@check("references-slide-last")
def _refs_last(docs):
    hits, err = require(docs, "brief")
    if err:
        return err
    bad = []
    for d in hits:
        kinds = [slide_kinds(s)[0][1] for s in d["slides"] if slide_kinds(s)]
        if not kinds or kinds[-1] != "references":
            bad.append("%s last slide kind=%r" % (d["path"], kinds[-1] if kinds else None))
        elif kinds.count("references") != 1:
            bad.append("%s has %d references slides" % (d["path"], kinds.count("references")))
    return bad


@check("references-slide-kind")
def _refs_kind(docs):
    """The refslide surface's single slide must carry Slide-Kind: references.

    references-slide-last is require(docs, "brief")-scoped, so it never reads
    references-slide.md at all. Without this check the one file whose entire
    purpose is to document the references slide contributes only "one slide,
    well-formed" to the binding, and demoting its Slide-Kind to `content` leaves
    the whole suite green.
    """
    hits, err = require(docs, "refslide")
    if err:
        return err
    bad = []
    for d in hits:
        for s in d["slides"]:
            kinds = [v for _, v in slide_kinds(s)]
            if kinds != ["references"]:
                bad.append("%s:%d slide %s kind=%r, expected ['references']"
                           % (d["path"], s["line"], s["label"], kinds))
    return bad


@check("no-colour-fields")
def _no_colour(docs):
    return _per_slide(docs, lambda s: ["colour field %s" % k for k in colour_hits(s)])


@check("required-4.1-subkeys")
def _required_subkeys(docs):
    """Every slide carries intent.role and visual.kind, each exactly once.

    presentation-brief-template.md:185 names Slide-Kind, intent and visual as the three
    top-level keys new in 4.1 that appear on every slide. Slide-Kind is graded
    by slide-kind-single/-enum; this is the other two. Grading all three is what
    keeps the required-key set a grammar rule rather than a single carve-out.
    """
    def grade(s):
        return ["%s.%s count=%d" % (parent, REQUIRED_SUBKEYS[parent], n)
                for parent, n in sorted(subkey_counts(s).items()) if n != 1]
    return _per_slide(docs, grade)


@check("non-numeric-slide-labels-graded")
def _non_numeric(docs):
    """The N / N+1 / N+2 headings are actually in the graded set.

    The membership half of heading-counts' arithmetic. A heading regex borrowed
    from parse-brief.py -- which requires (\\d+) -- drops these three silently.
    """
    hits, err = require(docs, "template")
    if err:
        return err
    for d in hits:
        missing = {"N", "N+1", "N+2"} - {s["label"] for s in d["slides"]}
        if missing:
            return ["%s did not grade slide labels %s" % (d["path"], ",".join(sorted(missing)))]
    return []


def _locate(docs, selector):
    """Resolve a structural mutation target to a 0-based line index.

    Mutants address their target through the parser rather than by an absolute
    line number. A hardcoded index silently re-aims whenever anything above it
    in the corpus is edited, and at least one direction then passes for the
    wrong reason: a mutant landing on a neighbouring key still turns its check
    red, so the case reports PASS having corrupted something else entirely.
    """
    kind, _, which = selector.partition(":")
    slides = docs[0]["slides"]

    if kind == "subkey":
        parent, _, nth = which.partition("/")
        s = slides[-1] if nth == "last" else slides[int(nth) - 1]
        seen = None
        for i, line in enumerate(s["body"]):
            key = toplevel_key(line)
            if key is not None:
                seen = key
                continue
            if seen == parent and re.match(r"^\s+%s:" % REQUIRED_SUBKEYS[parent], line):
                return s["body_start"] + i
        raise UsageError("no %s sub-key on slide %s" % (parent, nth))

    s = slides[-1] if which == "last" else slides[int(which) - 1]
    if kind == "fence-open":
        return s["fence_open"]
    if kind == "fence-close":
        return s["fence_close"]
    if kind == "body-top":
        return s["body_start"]
    if kind == "kind-line":
        return slide_kinds(s)[0][0]
    raise UsageError("unknown selector %r" % selector)


def main():
    if len(sys.argv) < 2:
        print("usage: slide_grammar.py <check-name|locate|dump-colour-fields> <role>=<path> ...")
        return EXIT_USAGE
    op = sys.argv[1]
    args = sys.argv[2:]
    # Validate the op before reading a single file: the name is the cheapest
    # thing to check, and a mis-typed check should report itself rather than
    # whatever the corpus happens to say.
    if op not in CHECKS and op not in ("locate", "dump-colour-fields"):
        print("unknown check %r (known: %s)" % (op, ", ".join(sorted(CHECKS))))
        return EXIT_USAGE
    if op == "locate":
        if not args:
            print("locate needs a selector")
            return EXIT_USAGE
        selector = args.pop()
    docs = []
    for arg in args:
        role, sep, path = arg.partition("=")
        if not sep:
            print("argument %r is not role=path" % arg)
            return EXIT_USAGE
        try:
            docs.append(parse(role, path))
        except OSError as e:
            print("cannot read %s: %s" % (path, e))
            return EXIT_USAGE
    if op == "locate":
        try:
            print(_locate(docs, selector))
        except UsageError as e:
            print(e)
            return EXIT_USAGE
        return 0
    if op == "dump-colour-fields":
        print(json.dumps(sorted(COLOUR_FIELDS)))
        return 0
    bad = CHECKS[op](docs)
    for b in bad:
        print(b)
    return 1 if bad else 0


if __name__ == "__main__":
    # The backstop that makes the exit-code contract TRUE rather than merely
    # enumerated. The named arms inside main() are better diagnostics and stay,
    # but they can only cover the failures someone thought of: a binary surface
    # (UnicodeDecodeError, not an OSError), an out-of-range locate index and a
    # locate with no document all used to crash out as exit 1, wearing the
    # finding code. Exit 1 is produced only by `return 1 if bad` below, never by
    # an exception, so nothing legitimate passes through here.
    try:
        rc = main()
    except Exception:
        traceback.print_exc()
        rc = EXIT_USAGE
    sys.exit(rc)

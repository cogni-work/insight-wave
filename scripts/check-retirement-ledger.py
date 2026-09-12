#!/usr/bin/env python3
"""Retirement-ledger gate — a skill's trigger phrases must survive it leaving.

WHAT THIS ASSERTS. Two diff shapes, one accounting rule. When a branch deletes a
`cogni-workspace/skills/<name>/SKILL.md`, or when it edits a SURVIVING one's
frontmatter `description:` so that it no longer advertises a phrase, every
trigger phrase that file advertised **at the merge base** must still be accounted
for at HEAD, in one of exactly two ways: a surviving live skill yields the same
phrase (it was re-claimed, so nothing was lost), or
`cogni-workspace/references/retired-trigger-phrases.tsv` carries a row for it with
a non-empty `reason` (the retirement was recorded). A phrase in neither is a
violation.

SCOPE IS DELIBERATELY COGNI-WORKSPACE-ONLY. Other plugin skill trees are out
of scope because every skill retirement observed in this repository has so far
occurred in cogni-workspace. Per-plugin ledgers would add empty records before
those plugins have retirement events to account for; one shared repo-wide
ledger would instead break the current co-location and the consumers bound to
the workspace ledger's path. Either expansion would add machinery for a
hypothetical second case and dilute this guard's useful hard clean zero. Revisit
the boundary when a plugin outside cogni-workspace first retires a skill or
drops a trigger phrase; that concrete second case can then determine whether
per-plugin ledgers or a shared ledger is the better generalization.

WHY THIS IS A SEPARATE GUARD AND NOT ANOTHER ARM OF C10. Case C10 in
`cogni-workspace/tests/test-skill-trigger-phrases.sh` cross-checks the ledger
against the live tree in both directions: `comm -23` finds a phrase recorded
`claimed` that no live skill yields (an orphan), and `comm -12` finds a phrase
recorded `retired` that a live skill does yield (a stale record). Both directions
operate over sets that a silently-dropped phrase is absent from. Delete a skill
and write no row, and the phrase is neither claimed nor retired nor live — it
leaves both sides of the comparison at once, the two sides still agree, and C10
stays green on a claim surface that just shrank. C10 is tree-only by design (its
suite takes no git ref), so the omission is not detectable there at all: seeing it
requires the base side. That is this guard's whole subject.

MERGE BASE, NEVER THE BASE-REF TIP. The deleted-file set and the base-side blob
are both resolved fork-point relative — `git diff <base>...HEAD` and
`git show $(git merge-base <base> HEAD):<path>`. Anchoring on the base-ref tip
would false-flag a branch forked before `main` advanced: `main`'s own later
deletions would read as this branch's. Since `main` here advances on every merge,
that would misfire on most real PRs. This is the same anchoring decision, for the
same reason, as `scripts/check-version-bump.py`.

THE LEDGER IS READ FROM THE HEAD SIDE. Deliberately, and it is load-bearing: the
row that satisfies this guard is the one the author adds **on the branch**. Read
the ledger from the base side and that row is invisible, so the documented remedy
would never satisfy the check — the guard would be unfixable rather than merely
wrong. The live-skill set is read from HEAD for the same reason: a re-claim lands
on the branch too.

TWO SUBJECTS, ONE GUARD. A phrase leaves the claim surface by two routes: the
file that advertised it is deleted, or it survives and its `description:` stops
advertising the phrase. Those are different diff shapes but the same omission
class, and they are arms of one gate rather than two gates because everything the
second needs the first already establishes — the base-ref resolvability check, the
merge base, the `degrade()` arm that makes an unresolvable baseline exit 0, and an
`accounted` set that was always subject-agnostic (it asks who claims a phrase now,
never how it stopped being claimed).

A sibling guard was the alternative and it was rejected on cost. It would have
needed a second CI job replicating the `status: degraded` re-grade — the one thing
standing between a dropped `fetch-depth: 0` and a vacuous pass — a second
full-history checkout, a second registry bullet in `CLAUDE.md`, and a THIRD copy
of the phrase extractor. Case C11 pins exactly one copy against the suite's
`emit_phrases`; an unpinned third would drift, extract fewer phrases, demand fewer
rows, and fail OPEN in precisely the direction this guard exists to close.

NO HEAD-SIDE READ ON THE MODIFIED ARM. The modified file is itself a surviving
skill, so `live_phrase_keys` over the working tree already carries whatever its
description still advertises. A phrase the edit kept is therefore inside
`accounted` by construction, and `key not in accounted` is the whole test — a
`git show HEAD:<path>` read would re-derive a subset of what the live set already
holds, at the cost of a second notion of HEAD sitting beside the working-tree
reads that `live_phrase_keys` and `ledger_phrase_keys` both take.

That also settles the file that is UNPARSEABLE AT HEAD: it contributes nothing to
the live set, so everything it advertised at the merge base is demanded. The
guard asks for more, never less — the safe direction — and whether a live file
parses at all stays `check-frontmatter`'s subject, not this one's.

DEGRADATION IS DELIBERATE. An unresolvable base ref (shallow clone, offline
runner, unfetched remote) yields `status: "degraded"` and exit 0. A guard that
hard-failed when it cannot see the baseline would block every PR on a constrained
runner. The cost of that choice is that a dropped `fetch-depth: 0` turns this
guard into a vacuous pass, which is why its CI job re-grades the SAME invocation's
JSON and fails the build when the status is `degraded`.

REJECTED ALTERNATIVE — a checked-in baseline snapshot of the phrase set, compared
against the current tree. It needs no git history, but it reintroduces exactly the
stale-record class the ledger already carries: the snapshot becomes a second thing
to keep in step, and a retirement that forgets the ledger would equally forget the
snapshot.

EXTRACTOR PARITY. The phrase extraction below reproduces `emit_phrases` in
`cogni-workspace/tests/test-skill-trigger-phrases.sh` exactly — same frontmatter
match, same column-0 description terminator, same YAML scalar unwrap performed
BEFORE quote-hunting, same double-quoted-spans-only rule, same
`" ".join(phrase.split()).lower()` key. No shared extractor exists to import, so
this is a second implementation, and a loose one would produce false greens in
precisely the direction this guard exists to close. Case C11 in that suite pins the
two together by diffing this script's `--emit-phrases` output against
`emit_phrases` over the real tree.

UNPARSEABLE IS NOT EMPTY. `phrases_from_skill_text` returns the `UNPARSEABLE`
sentinel for its keys when it could not parse the file at all — no frontmatter
block, or a block with no `description:` key — and a list, possibly empty, only
when it parsed. Collapsing the two is the invisibility class this guard exists
to close: an empty answer from a failed parse is indistinguishable from a
genuine empty, and every caller reading it as "nothing to check" goes green on
the failure. Each call site states its own decision inline; this paragraph
deliberately does not enumerate them, so it cannot drift out of step with one.
The sentinel is a truthy object rather than `None` on purpose — see its
definition.

AN UNPARSEABLE BASE BLOB IS AN OBSERVATION, NOT A VIOLATION, AND DELIBERATELY NOT
THE SIBLING OF THE UNREADABLE ONE. The two look alike and are different facts. A
blob `git show` cannot READ is an environment fault whose consequence is unknown,
so it stays a script error, exit 2. A blob we can read but cannot PARSE is
determinate: a `SKILL.md` with no frontmatter `description:` block is not
loadable as a skill at all, so it advertised no trigger phrase and its deletion
removes no claim surface. There is nothing to account for.

Nor could a demand be discharged if one were made. The base-side blob is history:
nothing a branch commits changes its own merge base, so no edit on the branch
under review can make an unparseable blob parse. A remedy would have to land on
`main` first and be inherited by a later fork — which is not a fix for the PR in
front of the author. That is the "unfixable rather than merely wrong" failure THE
LEDGER IS READ FROM THE HEAD SIDE rules out, and it is why this arm carries no
`FIX_HINTS`: an observation asks nothing, so it needs no remedy.

What the observation DOES fix is the honesty of the clean path. The gate used to
print "every trigger phrase accounted for" over files it had never parsed. That
claim, not a missing obligation, was the real defect. The exit-0 summary now
partitions its counts, so it is exactly as strong as the evidence behind it.

Same channel discipline as `scripts/check-mcp-tool-grant.py`, for the same
reason: a finding the subject cannot act on is surfaced without moving the exit
code, because a gate that cannot be satisfied is worse than no gate.

Usage: check-retirement-ledger.py [--root PATH] [--base-ref REF]
       check-retirement-ledger.py --emit-phrases SKILLS_DIR

  RETIREMENT_LEDGER_BASE_REF  overrides --base-ref (default: origin/main).

Envelope on stdout, human summary on stderr. `violations[]` gates the exit code;
`observations[]` never does.
Exit 0 clean or degraded, 1 violations, 2 script error.

Stdlib only; runs under any python3.
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

DEFAULT_BASE_REF = "origin/main"
SKILLS_REL = "cogni-workspace/skills"
LEDGER_REL = "cogni-workspace/references/retired-trigger-phrases.tsv"
METRIC_VERSION = "1"

# Only a one-level `<skills>/<name>/SKILL.md` is a skill, matching the extractor's
# own non-recursive listdir. A deeper path is not a skill and must not be demanded.
SKILL_PATH_RE = re.compile(r"^" + re.escape(SKILLS_REL) + r"/[^/]+/SKILL\.md$")


# Returned in place of a key list when a SKILL.md could not be parsed at all.
# Deliberately TRUTHY, unlike `None`: the one silent way back into the class this
# guard closes is a new consumer writing `if keys:` before iterating. Against a
# falsy sentinel that reads as "nothing to check" and skips; against this one it
# falls through to iteration and raises TypeError at once.
UNPARSEABLE = object()


def git(repo_root, *args):
    """Run a git command in repo_root. Returns (exit_code, stdout, stderr)."""
    proc = subprocess.run(
        ("git",) + args, cwd=str(repo_root),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    return proc.returncode, proc.stdout, proc.stderr


def phrases_from_skill_text(text, fallback_name):
    """Phrases + skill name from one SKILL.md's text.

    Returns `(keys, name)`. `keys` is a list when the file parsed — possibly
    the empty list, meaning it parsed and advertised no quoted phrase — and the
    `UNPARSEABLE` sentinel when it could not be parsed at all: no frontmatter
    block, or a block carrying no `description:` key. Callers must distinguish
    the two; see UNPARSEABLE IS NOT EMPTY in the module docstring.

    Byte-for-byte the normal form of `emit_phrases`. Every step here is load
    bearing; see EXTRACTOR PARITY in the module docstring.
    """
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return UNPARSEABLE, fallback_name
    fm = m.group(1)
    nm = re.search(r"^name:[ \t]*(\S+)", fm, re.M)
    name = nm.group(1) if nm else fallback_name
    # description: through the next TOP-LEVEL key (column 0), or end of block.
    dm = re.search(r"^description:.*?(?=^[A-Za-z_][A-Za-z0-9_-]*:|\Z)", fm, re.M | re.S)
    if not dm:
        return UNPARSEABLE, name
    body = re.sub(r"^description:[ \t]*", "", dm.group(0), count=1)
    # Unwrap the YAML scalar BEFORE hunting for quoted phrases: on a
    # double-quoted scalar the outer quotes are syntax, not a trigger phrase.
    stripped = body.strip()
    if stripped[:1] in (">", "|"):
        stripped = stripped.split("\n", 1)[1] if "\n" in stripped else ""
    elif stripped[:1] == "\"" and stripped[-1:] == "\"":
        stripped = stripped[1:-1].replace("\\\"", "\"")
    elif stripped[:1] == chr(39) and stripped[-1:] == chr(39):
        stripped = stripped[1:-1].replace(chr(39) * 2, chr(39))
    keys, seen = [], set()
    for phrase in re.findall(r"\"([^\"]+)\"", stripped):
        key = " ".join(phrase.split()).lower()
        if not key or key in seen:
            continue
        seen.add(key)
        keys.append(key)
    return keys, name


def iter_skills(skills_dir):
    """Yield `(keys, name)` per live `<skills_dir>/<entry>/SKILL.md`, in name order.

    ONE traversal, shared by both callers on purpose. `emit_phrases` is the copy
    case C11 pins against the suite's own extractor; `live_phrase_keys` builds
    the accounting set the whole comparison rests on. Were those separate walks,
    C11 would grade only the first, and a later change to "what counts as a live
    skill" could land in the pinned copy alone — the unpinned one would then
    under-collect live phrases, the guard would demand rows for phrases a
    surviving skill still claims, and C11 would stay green throughout. Routing
    both through here makes the pin cover the live side transitively.

    Raises OSError if `skills_dir` is not listable; callers decide what that means.
    """
    for entry in sorted(os.listdir(skills_dir)):
        path = os.path.join(skills_dir, entry, "SKILL.md")
        if not os.path.isfile(path):
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        yield phrases_from_skill_text(text, entry)


def emit_phrases(skills_dir):
    """Parity mode. Prints `<key>\\t<name>`; exit 3 unlistable dir, 4 no SKILL.md."""
    try:
        found_any = False
        for keys, name in iter_skills(skills_dir):
            found_any = True
            if keys is UNPARSEABLE:
                # The suite copy counts the file as found and then `continue`s
                # past an unparseable one. Mirror that exactly: parity mode's
                # whole job is to be byte-identical to it.
                continue
            for key in keys:
                print("%s\t%s" % (key, name))
    except OSError:
        return 3
    return 0 if found_any else 4


def live_phrase_keys(skills_dir):
    """Every phrase key a live skill yields at HEAD.

    An unparseable live skill contributes nothing. That is the safe direction:
    this set is what EXCUSES a retired phrase, so omitting a file can only make
    the guard demand more, never less.
    """
    try:
        return {key for keys, _name in iter_skills(skills_dir)
                if keys is not UNPARSEABLE for key in keys}
    except OSError:
        return set()


def ledger_phrase_keys(ledger_path):
    """Keys the HEAD-side ledger accounts for.

    A row accounts for its phrase only when it is well formed AND carries a
    non-empty reason — the documented remedy is recording the retirement WITH a
    justification, so an empty-reason row must not discharge the obligation.
    Row hygiene beyond that (owner attribution, key normalization) stays C10's.
    """
    keys = set()
    with open(ledger_path, encoding="utf-8") as fh:
        for line in fh:
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            fields = line.rstrip("\n").split("\t")
            if len(fields) != 4:
                continue
            key, status, _owner, reason = fields
            if status not in ("claimed", "retired") or not reason.strip():
                continue
            if key:
                keys.add(key)
    return keys


def render(data, error=None):
    """Emit the envelope. `clean` and `count` are DERIVED here, never stored.

    They are pure functions of `violations`, and the sibling guard
    (`scripts/check-version-bump.py`) derives them at render time for the same
    reason: hand-maintaining them at each exit is three sites that must agree,
    and the one that disagrees reports a count its own violation list refutes.
    """
    if data is not None:
        violations = data.get("violations") or []
        data["count"] = len(violations)
        data["clean"] = not violations
    print(json.dumps({"success": error is None, "data": data, "error": error}))


def main():
    parser = argparse.ArgumentParser(add_help=True)
    parser.add_argument("--root", default=None,
                        help="repository root (default: this script's repo)")
    parser.add_argument("--base-ref", default=None,
                        help="base ref to anchor on (default: origin/main)")
    parser.add_argument("--emit-phrases", default=None, metavar="SKILLS_DIR",
                        help="parity mode: print <key>TAB<name> and exit")
    args = parser.parse_args()

    # Parity mode short-circuits BEFORE any git call, on purpose. C11 invokes it
    # from a suite that runs in the deliberately shallow plugin-test-suites job,
    # where no base ref and no merge base resolve; a git call ordered ahead of
    # this dispatch would redden that job.
    if args.emit_phrases is not None:
        return emit_phrases(args.emit_phrases)

    repo_root = Path(args.root).resolve() if args.root \
        else Path(__file__).resolve().parent.parent
    base_ref = (args.base_ref or os.environ.get("RETIREMENT_LEDGER_BASE_REF")
                or DEFAULT_BASE_REF)

    data = {
        "status": "ok", "violations": [], "observations": [],
        "base_ref": base_ref, "merge_base": None, "deleted_skills": [],
        "modified_skills": [],
        "metric_version": METRIC_VERSION,
    }

    def degrade(reason):
        data["status"] = "degraded"
        data["degraded_reason"] = reason
        render(data)
        sys.stderr.write("retirement-ledger gate DEGRADED: %s\n" % reason)
        return 0

    rc, _, _ = git(repo_root, "rev-parse", "--verify", "--quiet",
                   "{}^{{commit}}".format(base_ref))
    if rc != 0:
        return degrade("base ref '{}' not available (offline, shallow clone, "
                       "or unfetched)".format(base_ref))

    rc, mb_out, _ = git(repo_root, "merge-base", base_ref, "HEAD")
    if rc != 0 or not mb_out.strip():
        return degrade("no merge base between '{}' and HEAD".format(base_ref))
    merge_base = mb_out.strip()
    data["merge_base"] = merge_base

    # Both subjects in ONE query, fork-point relative. The `--diff-filter`
    # token must stay one unsplit token in this argument list — it is what
    # scopes the guard, and its M half is what makes the status split below
    # exhaustive, so the else-arm is exactly M and needs no third branch.
    #
    # `--no-renames` is equally load-bearing, and for a reason the D filter alone
    # does not cover: rename detection has been on by default since git 2.9, so a
    # retirement carried out by MOVING a SKILL.md out of `skills/` — archiving it
    # rather than removing it, an ordinary workflow — is paired as R and never
    # reported as a D at all. The guard then finds no deletion, reports "nothing
    # to account for" and exits 0 while the phrases left the live set and the
    # record together. That is the same fail-open this guard exists to close,
    # reached by a different route, so the flag is part of the subject definition
    # rather than a tuning knob. Turning it off does not narrow the guard; it
    # blinds it.
    rc, diff_out, diff_err = git(repo_root, "diff", "--name-status",
                                 "--no-renames", "--diff-filter=DM",
                                 "{}...HEAD".format(base_ref))
    if rc != 0:
        render(data, "could not diff against '{}': {}".format(
            base_ref, (diff_err or "").strip()[:200]))
        return 2

    # `--name-status` yields exactly two tab-separated fields per line for
    # these two filters: a status letter and a path. Only R and C carry a
    # similarity score suffix, and `--no-renames` plus the filter exclude both,
    # so partitioning on the first tab is total. Every path goes through the
    # UNCHANGED SKILL_PATH_RE: the ledger TSV is itself a modified file on many
    # branches, and a deleted ledger is a D row, so without this filter both
    # would enter the accounting as if they were skills.
    deleted = []
    modified = []
    for line in diff_out.splitlines():
        status, _, path = line.partition("\t")
        if not SKILL_PATH_RE.match(path):
            continue
        (deleted if status[:1] == "D" else modified).append(path)
    if not deleted and not modified:
        render(data)
        sys.stderr.write("retirement-ledger gate: no skill deletion and no "
                         "skill-description change in this branch; nothing to "
                         "account for.\n")
        return 0

    ledger_path = repo_root / LEDGER_REL
    # Gated on `deleted`, not on the ledger alone. A deletion has exactly ONE
    # remedy and it is a ledger row, so a deleting branch with no ledger cannot
    # discharge anything and is told so here. A MODIFICATION has two remedies
    # that need no ledger at all — restore the phrase in that same description,
    # or re-claim it in a sibling — so a modification-only branch falls through
    # to the per-phrase finding instead of firing a violation whose own detail
    # text ("branch deletes a skill...") would be false.
    if deleted and not ledger_path.is_file():
        # Same element shape as the main path below — one key, one schema.
        # `phrases` is null rather than 0: with no ledger there is nothing to
        # compare against, so the count was never computed, which is a
        # different fact from "this skill advertised none".
        data["deleted_skills"] = [{"path": p, "skill": p.split("/")[-2],
                                   "phrases": None} for p in deleted]
        data["violations"] = [{"check": "ledger-missing", "path": LEDGER_REL,
                               "detail": "branch deletes a skill but the "
                                         "retirement ledger is missing or "
                                         "unreadable at HEAD"}]
        render(data)
        sys.stderr.write("FIX_HINTS: restore %s and record the retired "
                         "phrases in it.\n" % LEDGER_REL)
        return 1

    # The ledger may legitimately be absent here now that the arm above is
    # gated on `deleted`: a modification-only branch that removes it reaches
    # this line. Reading it unconditionally would raise into the top-level
    # handler and exit 2 — a script error standing in for a determinate verdict.
    accounted = live_phrase_keys(str(repo_root / SKILLS_REL))
    if ledger_path.is_file():
        accounted = accounted | ledger_phrase_keys(str(ledger_path))

    violations = []
    observations = []
    for path in deleted:
        rc, blob, blob_err = git(repo_root, "show",
                                 "{}:{}".format(merge_base, path))
        if rc != 0:
            # Never a silent skip: a blob we cannot read is a phrase set we
            # cannot check, which is the invisibility class this guard closes.
            render(data, "could not read '{}' at the merge base: {}".format(
                path, (blob_err or "").strip()[:200]))
            return 2
        keys, name = phrases_from_skill_text(blob, path.split("/")[-2])
        # `phrases` is null when the blob did not parse, for the same reason the
        # ledger-missing arm uses null: never computed is a different fact from
        # "this skill advertised none".
        data["deleted_skills"].append(
            {"path": path, "skill": name,
             "phrases": None if keys is UNPARSEABLE else len(keys)})
        if keys is UNPARSEABLE:
            # An OBSERVATION, never a violation — and deliberately not treated
            # like the unreadable-blob arm above it. Those two are different
            # facts. A blob we could not READ is an environment fault of unknown
            # consequence. A blob we could not PARSE is determinate: no
            # frontmatter description block means the file was never loadable as
            # a skill, so it advertised no trigger phrase and its deletion loses
            # no claim surface. There is nothing for the author to account for,
            # and no edit that could discharge it either — the merge-base blob
            # is history, so a demand here would be unsatisfiable rather than
            # merely strict. Recording it keeps the exit-0 summary honest, which
            # was the real defect: the gate used to claim full accounting for a
            # file it never parsed.
            observations.append({"check": "base-blob-unparseable",
                                 "skill": name, "path": path,
                                 "detail": "no parseable frontmatter description "
                                           "block at the merge base, so no "
                                           "trigger-phrase set was derived; a "
                                           "file in this shape was not a "
                                           "loadable skill and advertised none"})
            continue
        for key in keys:
            if key not in accounted:
                violations.append({"check": "retirement-row-missing",
                                   "skill": name, "path": path, "phrase": key,
                                   "detail": "trigger phrase \"%s\" is claimed "
                                             "by no surviving skill and carried "
                                             "by no ledger row" % key})

    # The modification subject. Same merge-base blob read, same extractor and
    # the same `key not in accounted` predicate as the deletion loop above —
    # one accounting rule, reached by a second diff shape. See that loop for
    # the null-means-never-computed rule this one also follows.
    #
    # There is deliberately NO per-file head-side read here. The modified file
    # is itself a SURVIVING skill, so `live_phrase_keys` over the working tree
    # already carries whatever its description still advertises: a phrase the
    # edit kept is in `accounted` by construction, and a `git show HEAD:<path>`
    # read could only re-derive that at the cost of a second notion of HEAD
    # beside the working-tree reads `live_phrase_keys` and `ledger_phrase_keys`
    # both take.
    #
    # A file UNPARSEABLE AT HEAD therefore needs no arm of its own: it
    # contributes nothing to the live set, so every phrase it advertised at the
    # merge base is demanded. That is the safe direction — the guard asks for
    # more, never less — and it keeps this gate out of `check-frontmatter`'s
    # subject, which owns whether a live file parses.
    for path in modified:
        rc, blob, blob_err = git(repo_root, "show",
                                 "{}:{}".format(merge_base, path))
        if rc != 0:
            render(data, "could not read '{}' at the merge base: {}".format(
                path, (blob_err or "").strip()[:200]))
            return 2
        keys, name = phrases_from_skill_text(blob, path.split("/")[-2])
        data["modified_skills"].append(
            {"path": path, "skill": name,
             "base_phrases": None if keys is UNPARSEABLE else len(keys)})
        if keys is UNPARSEABLE:
            # The modified-side mirror of `base-blob-unparseable`, and an
            # OBSERVATION for the same two reasons: a file that advertised no
            # parseable phrase set at the merge base had nothing to lose, and
            # the merge base is history, so no edit on this branch could
            # discharge a demand made against it.
            observations.append(
                {"check": "modified-base-unparseable", "skill": name,
                 "path": path,
                 "detail": "no frontmatter description at the merge base, so "
                           "no phrase set was derived; nothing could have been "
                           "dropped"})
            continue
        for key in keys:
            if key not in accounted:
                violations.append({"check": "description-phrase-dropped",
                                   "skill": name, "path": path, "phrase": key,
                                   "detail": "trigger phrase \"%s\" was "
                                             "advertised at the merge base, is "
                                             "claimed by no surviving skill and "
                                             "is carried by no ledger row" % key})

    data["violations"] = violations
    data["observations"] = observations
    render(data)

    # Observations print on BOTH the failing and the clean path, before the
    # verdict line either way, so the unparseable count is never absent from the
    # summary a reader acts on.
    for o in observations:
        sys.stderr.write("  note  %s: %s\n" % (o["skill"], o["detail"]))

    if violations:
        # Every violation carries `detail`, and `skill` is read through .get so
        # this pass never branches on which keys a given check happens to have
        # — `ledger-missing` carries no `skill`. Only the remedies differ, below.
        checks = {v["check"] for v in violations}
        sys.stderr.write(
            "retirement-ledger gate: %d violation(s) from %d deleted "
            "skill(s) and %d modified skill(s).\n"
            % (len(violations), len(deleted), len(modified)))
        for v in violations:
            sys.stderr.write("  %s: %s\n"
                             % (v.get("skill") or v["path"], v["detail"]))
        if "retirement-row-missing" in checks:
            sys.stderr.write(
                "FIX_HINTS: for each unaccounted phrase above, either re-claim "
                "it in a surviving skill's frontmatter description, or add a "
                "row to %s as\n"
                "  <phrase_key>\\tretired\\t-\\t<non-empty reason>\n"
                "The key is the extractor's normal form: trimmed, internal "
                "whitespace collapsed to single spaces, lowercased.\n"
                % LEDGER_REL)
        if "description-phrase-dropped" in checks:
            sys.stderr.write(
                "FIX_HINTS: for each dropped phrase above, either restore it in "
                "that skill's own frontmatter description, or re-claim it in a "
                "surviving skill's frontmatter description, or add a row to %s "
                "as\n"
                "  <phrase_key>\\tretired\\t-\\t<non-empty reason>\n"
                "The key is the extractor's normal form: trimmed, internal "
                "whitespace collapsed to single spaces, lowercased.\n"
                % LEDGER_REL)
        # No FIX_HINTS arm for `base-blob-unparseable` or its modified-side
        # mirror `modified-base-unparseable`, deliberately: neither is a
        # violation, so neither can ever be in `checks` here. There was
        # never an executable remedy to name — nothing a branch commits changes
        # its own merge base — and three review cycles were spent re-wording one
        # that did not exist. An observation asks nothing of the author, so it
        # needs no hint.
        return 1

    # NEVER "every trigger phrase accounted for" unconditionally. That line was
    # the original defect: it asserted full accounting over files the gate had
    # not parsed. The counts below are partitioned, so the claim is exactly as
    # strong as the evidence.
    # Each subject subtracts only ITS OWN unparseable class. Subtracting the
    # whole observation list, as this line did while one class existed, silently
    # under-reports the checked count the moment a second class contributes one.
    unparseable_deleted = len([o for o in observations
                               if o["check"] == "base-blob-unparseable"])
    unparseable_modified = len([o for o in observations
                                if o["check"] == "modified-base-unparseable"])
    checked = len(deleted) - unparseable_deleted
    checked_modified = len(modified) - unparseable_modified
    if observations:
        sys.stderr.write(
            "retirement-ledger gate: %d deleted skill(s) — %d with every "
            "trigger phrase accounted for, %d unparseable at the merge base; "
            "%d modified skill(s) — %d checked, %d unparseable at the merge "
            "base (no phrase set derived; nothing was advertised to lose).\n"
            % (len(deleted), checked, unparseable_deleted,
               len(modified), checked_modified, unparseable_modified))
    else:
        sys.stderr.write("retirement-ledger gate: %d deleted skill(s) and %d "
                         "modified skill(s), every trigger phrase accounted "
                         "for.\n" % (len(deleted), len(modified)))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as exc:  # noqa: BLE001 - envelope every failure
        render(None, "unhandled error: %s" % exc)
        sys.exit(2)

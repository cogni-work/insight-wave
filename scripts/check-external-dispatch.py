#!/usr/bin/env python3
"""check-external-dispatch.py — deterministic external-dispatch guard.

Asserts that **no live-dispatch surface** dispatches a retired engine anywhere in
the repo. This is the machine proof behind the archival decision: once a plugin is
archived (source kept, not installable) or absorbed into another, a live caller
dispatching it would break at runtime. The guard makes that absence objective and
regression-proof.

The retired set is **data, not source** — it lives in `scripts/retired-plugins.json`
(override with `--registry`), so retiring another plugin is a one-line edit to that
file rather than a regex edit here:

    {"retired_prefixes": ["cogni-wiki", "cogni-research"]}

Entries are BARE prefixes with no trailing colon and no surrounding whitespace — this
script appends the colon that makes the token dispatch-shaped, and rejects both a
colon-bearing entry (`cogni-wiki::`) and a padded one (`re.escape("  cogni-wiki  ")`)
rather than compiling a pattern that would silently match nothing.

The registry is **mandatory config, not an optional ratchet**: absent, unreadable,
malformed, wrongly-typed or empty all exit 2. A guard that quietly loaded nothing and
reported a clean zero would be worse than no guard, because CI would stay green while
the invariant went unprotected.

Two scoping choices, stated because the sibling guard next door made the opposite one:

  - **Enumerated, not derived.** `check-plugin-inventory.py` deliberately avoids a
    hand-maintained list of retired names, preferring a bijection that works without
    being told any. That is the right shape *there*, where the live set is the datum.
    Here the live set is not enough: `\bcogni-[a-z0-9-]+:` minus the installed plugins
    would also flag every prose mention of a plugin that simply is not installed in
    the reader's workspace, so the guard would fire on trees it should not. The cost
    of enumerating is a registry that can go **stale** — a plugin retired without an
    entry here is silently unguarded — and nothing detects that today. The retiring
    change is expected to add its own entry; that expectation is the control.
  - **Plugin-granular.** An entry is a whole plugin prefix, and this script appends
    the colon. A retired *skill* on a live plugin (`cogni-x:some-skill`) therefore
    cannot be expressed, and the loader rejects the colon-bearing entry a maintainer
    would reach for rather than silently compiling `cogni-x::`, which would match
    nothing. That case is now covered by the SECOND arm below rather than by
    widening this registry.

TWO ARMS. Every violation carries an `arm` key naming which one produced it, and
each arm prints its own remediation — the retired arm's advice is nonsense for a
live-plugin dangling slug, and vice versa.

  1. **retired-prefix** — the registry-driven arm above. Unchanged.
  2. **unresolved-target** — reports a `<live-plugin>:<slug>` token whose slug
     names no `skills/<slug>/SKILL.md` and no `agents/<slug>.md` under the
     plugin its own prefix names. The live-plugin set is derived at run time from
     that tree's `.claude-plugin/marketplace.json` `plugins[]`, never hardcoded,
     so adding a plugin needs no edit here. Resolution binds the PAIR, not the
     slug alone: a slug that resolves under one listed plugin does NOT thereby
     resolve for every prefix, so a token naming a real slug owned by a DIFFERENT
     listed plugin is reported as a cross-plugin miswire. The `commands/`
     namespace is deliberately NOT part of the predicate — a command is a
     user-facing entry point, not a dispatch target — so a token resolving only
     to `*/commands/<slug>.md` is reported.

     Absent manifest DEGRADES (the arm does not run, and the JSON says so via
     `data.scanned`); a manifest that is present but unreadable or malformed is a
     hard exit 2. Absence is a tree that never had the arm's input; corruption is
     a broken input, and quietly treating the two alike is how a guard reports a
     clean zero over nothing.

Scope — the surfaces a running session actually dispatches FROM:

  - */skills/*/SKILL.md   (skill bodies + their YAML description)
  - */agents/*.md         (agent prompts)
  - */commands/*.md       (slash-command definitions)
  - */hooks/**            (lifecycle hooks: *.sh / *.py / *.json)
  - */scripts/*.sh        (plugin- and skill-owned shell scripts)
  - */scripts/*.py        (plugin- and skill-owned python scripts)

Excluded, by design (NOT live-dispatch surfaces):

  - any OTHER file type under */scripts/
                                    the scripts surface is enumerated by
                                    executable extension, so a README or a data
                                    file beside a script is out of scope. Note
                                    this is NOT a general file-type rule: a
                                    hooks *.json IS a dispatch surface, which is
                                    why */hooks/** stays type-agnostic above.
                                    The distinction is config-that-dispatches
                                    versus data, not extension.

  - cogni-knowledge/                its delegation-contract / references
                                    legitimately NAME the retired plugins as
                                    history, and it carries the vendored wiki
                                    engine under scripts/vendor/cogni-wiki/; it
                                    dispatches neither retired plugin (FMO
                                    vendored the engine), and the runtime-path
                                    guard for that lives in its own
                                    test_skill_contracts.
                                    (The cogni-research/ and cogni-wiki/ source
                                    trees were removed from the repo entirely
                                    once archived, so they need no exclude.)
  - */wiki/ , top-level wiki/       generated page dumps (a wiki mirror may
                                    quote a retired dispatch as page content)
  - docs/                           the doc mirror (prose, not a dispatch)

`references/` directories are out of scope on purpose: a reference doc is
loaded on demand as documentation, not the surface a session dispatches from, so
a lineage mention there ("modeled on the cogni-research verify-report skill") is
not a caller.

Unlike the breadcrumb guard, this guard targets a HARD clean-zero — there is no
legitimate live dispatch of a registered retired prefix, so the ratchet/baseline
model is the wrong tool. The single escape hatch is a per-line marker for a genuine
NON-dispatch prose mention that must keep the literal token (rare); state the
rationale on the same line:

    ... see cogni-research:verify-report for the lineage  # external-dispatch-guard:allow

The fix when the guard trips is to REMOVE the dispatch (cut the caller over to
the vendored cogni-knowledge surface) or, for a true prose mention, reword it
semantically to drop the `plugin:skill` token (drop the colon) — exactly the
discipline the Maintainer-breadcrumb guard uses.

Decode policy — a tracked file this guard cannot decode is a hard exit 2, BY
DESIGN, on every discovered surface. `*/hooks/**` is included, and is the surface
where it actually bites, since those globs stay type-agnostic on purpose (above).
`scan_file()` opens each discovered file as strict UTF-8 and re-raises the
resulting UnicodeDecodeError as a RuntimeError, which `main()` renders as the
exit-2 envelope.

Why this guard and not its siblings. Several sibling guards decode with
`errors="replace"` over a comparably broad `git ls-files` sweep, and asserting a
hard clean-zero does NOT tell this guard apart from them — they assert one too.
The property that does: this is the only one whose declared surface set
deliberately admits non-text file types (a hooks `*.json`, and with it whatever
else a hooks tree carries), and its predicate is a LITERAL token match. Replacing
undecodable bytes here would not merely garble a display string — it substitutes
U+FFFD for the bytes it could not decode, so a real `plugin:skill` token living
in a UTF-16 or otherwise non-UTF-8 hook can be broken apart and then simply not
matched. The guard would scan that file and report it clean. That is the specific
failure this guard exists to prevent, and it is why the sibling convention does
not transfer.

The marketplace-manifest ruling above is the closest precedent but NOT the same
case, and it is worth being exact rather than borrowing its authority. That
manifest is an INPUT to the unresolved-target predicate: corrupt it and no file
can be judged, so aborting is the only non-vacuous answer. An undecodable file is
instead a SUBJECT of the scan, one of N, and the other N-1 verdicts are
computable — so on its face this case resembles that rule's FIRST tier (degrade,
and say so in `data.scanned`). Aborting still wins, for a reason particular to
it: a per-file degrade record would let a run that could not read a dispatch
surface still exit 0, and this guard has no non-vacuous verdict to attach to that
surface. A red run naming the file is not a silent failure; a green one carrying
a footnote is.

A third shape was available and is also declined: report the undecodable file as
a violation, or as an unauditable entry in `data.scanned`, and keep scanning. It
changes what a violation MEANS here — every other one is a claim about a token in
readable content — and turns an exit 2 into an exit 1, which is a change to the
CI contract rather than a decode-policy decision.

The remedy is to untrack the artifact: a compiled or binary blob under a dispatch
surface is not itself a dispatch surface. `collect()` builds its file list from
either the explicit-file argument or from discovery and then runs ONE shared scan
loop, so both invocation paths behave identically here — an explicit-file
invocation naming an undecodable path exits 2 for the same reason, not a separate
one.

Settled in #1771; pinned by ed42/ed43 in tests/test_check_external_dispatch.sh.

stdlib only; runs under any python3. Exit 0 = clean (zero dispatches),
1 = dispatch(es) found in either arm, 2 = script error.
"""

import argparse
import json
import os
import re
import subprocess
import sys

# git ls-files pathspec globs for the live-dispatch surfaces.
#
# The scripts surface is enumerated by executable extension rather than as a bare
# */scripts/* glob. The primary reason is scope: an executable script is a caller,
# while a README or a data file sitting beside it is not.
#
# It also sidesteps a decode hazard on this surface, though only on this one. A
# git pathspec * crosses /, so */scripts/* would also match any undecodable file
# sitting beside a script, and scan_file() re-raises the resulting
# UnicodeDecodeError as a RuntimeError that main() renders as exit 2 — one such
# file would take the whole run down on a decode error instead of reporting a
# dispatch finding. The canonical shape is compiled bytecode under a
# scripts/__pycache__/ tree: two such files were tracked under
# cogni-portfolio-evals/scripts/__pycache__/ when this enumeration was written,
# and have since been removed from the index — which retires that instance, not
# the hazard. Do NOT read that as a property this enumeration establishes
# guard-wide: */hooks/* and */hooks/*/* are already type-agnostic and already
# carry the identical exposure, verified by observation. That exposure was
# assessed in #1771 and deliberately KEPT: the stance, and the reasoning for it,
# are in the docstring's `Decode policy` paragraph above, and ed42/ed43 pin it.
# It is a settled decision, not a deferral.
#
# The extension scoping above is a SCOPE decision, not a decode remedy: it narrows
# what is discovered — a README beside a script is not a caller — and changes
# nothing about what happens once an undecodable file IS discovered, as one under
# */hooks/** can be.
#
# Mutation-recipe invariant: the two extension entries in the list below are each
# anchored by a recorded recipe in tests/test_check_external_dispatch.sh, and
# mutation-check.sh substitutes the FIRST match only. Do not repeat either entry's
# text anywhere else in this file — a second occurrence is mutated instead of the
# glob, and the recipe then reports a live assertion as decorative. State the
# invariant positionally, as this comment does; never spell an entry's text.
DEFAULT_GLOBS = [
    "*/skills/*/SKILL.md",
    "*/agents/*.md",
    "*/commands/*.md",
    "*/hooks/*",
    "*/hooks/*/*",
    "*/scripts/*.sh",
    "*/scripts/*.py",
]

# Path-prefix excludes (own trees + the history-bearing FMO plugin).
EXCLUDE_PREFIXES = ("cogni-knowledge/",)

# Path-segment excludes (generated wiki mirrors + the doc mirror). A surface
# under any of these is content, not a caller.
EXCLUDE_SEGMENTS = ("/wiki/", "/docs/")
EXCLUDE_TOPLEVEL = ("wiki/", "docs/")

# Default registry location, resolved next to THIS script (never under --root, so
# scanning a foreign tree still reads our own retired set). Override: --registry.
REGISTRY_BASENAME = "retired-plugins.json"

# Per-line escape hatch for a genuine non-dispatch prose mention. It suppresses
# the whole line, and therefore BOTH arms.
ALLOW_MARKER = "external-dispatch-guard:allow"

# Marketplace manifest, resolved UNDER --root — unlike REGISTRY_BASENAME above,
# which is anchored on this script. The retired arm asks "what have WE retired";
# the unresolved-target arm asks "what does THIS tree ship", so it must read the
# tree under test.
MARKETPLACE_REL = os.path.join(".claude-plugin", "marketplace.json")

# Arm labels, carried on every violation so a finding is attributable.
ARM_RETIRED = "retired-prefix"
ARM_UNRESOLVED = "unresolved-target"


def load_registry(path):
    """Return the list of bare retired prefixes from the registry at `path`.

    Every degenerate input raises RuntimeError, which main() renders as the exit-2
    envelope — there is deliberately no empty-list fallback and no hardcoded default
    set (see the module docstring for why).
    """
    if not os.path.exists(path):
        raise RuntimeError("retired-plugin registry not found: {}".format(path))
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        raise RuntimeError("bad retired-plugin registry {}: {}".format(path, exc))

    prefixes = data.get("retired_prefixes") if isinstance(data, dict) else None

    # Mutation-recipe invariant: keep the next line exactly as written, on ONE
    # physical line, and do not repeat its text anywhere else in this file — the
    # recorded recipe rewrites the FIRST match only (perl -0pi, no /g), so a second
    # occurrence would mutate the wrong site and report the guard as decorative.
    if not isinstance(prefixes, list) or not prefixes:
        raise RuntimeError(
            "retired-plugin registry {} must carry a non-empty "
            "'retired_prefixes' list".format(path))

    for entry in prefixes:
        if not isinstance(entry, str) or not entry.strip():
            raise RuntimeError(
                "retired-plugin registry {}: every prefix must be a non-empty "
                "string, got {!r}".format(path, entry))
        if entry != entry.strip():
            raise RuntimeError(
                "retired-plugin registry {}: prefix {!r} must not carry surrounding "
                "whitespace — re.escape would compile it into a pattern that never "
                "matches".format(path, entry))
        if ":" in entry:
            raise RuntimeError(
                "retired-plugin registry {}: prefix {!r} must not carry a colon — "
                "this guard appends it".format(path, entry))
    return prefixes


def compile_dispatch_re(prefixes):
    r"""Compile `\b(?:prefix|…):` — the `plugin:` half of a dispatch reference.

    The trailing colon is MANDATORY, so a bare "cogni-research" is a plain noun and
    is NOT matched, and a hit's `match` is the full "cogni-research:".
    """
    return re.compile(
        r"\b(?:" + "|".join(re.escape(p) for p in prefixes) + r"):")


def load_live_plugins(root):
    """Return (entries, degraded_reason) for the marketplace under `root`.

    `entries` is a list of (name, dir_rel). An ABSENT manifest degrades — the
    caller reports the degrade in `data.scanned` and skips the arm — because a
    tree with no marketplace (every synthetic fixture, any foreign checkout) is
    not a tree with a broken marketplace. A manifest that IS present but cannot
    be read or is the wrong shape raises RuntimeError, i.e. exit 2, mirroring the
    anti-vacuity stance `load_registry` takes: a corrupt input must never read as
    a clean pass.
    """
    path = os.path.join(root, MARKETPLACE_REL)
    if not os.path.isfile(path):
        return [], "no-marketplace-manifest"
    try:
        with open(path, "r", encoding="utf-8") as fh:
            data = json.load(fh)
    except (OSError, ValueError) as exc:
        raise RuntimeError("marketplace manifest {} is unreadable or not valid "
                           "JSON: {}".format(path, exc))
    if not isinstance(data, dict):
        raise RuntimeError(
            "marketplace manifest {} must be a JSON object".format(path))
    plugins = data.get("plugins")
    if not isinstance(plugins, list):
        raise RuntimeError("marketplace manifest {} must carry a 'plugins' "
                           "list".format(path))
    entries = []
    for item in plugins:
        if not isinstance(item, dict):
            continue
        name = item.get("name")
        if not isinstance(name, str) or not name.strip():
            continue
        source = item.get("source")
        if isinstance(source, str) and source.strip():
            rel = source.strip()
            if rel.startswith("./"):
                rel = rel[2:]
        else:
            rel = name
        entries.append((name, rel))
    if not entries:
        return [], "no-named-plugins-in-manifest"
    return entries, ""


def build_target_index(root, plugin_entries):
    """Return {plugin name: set of slugs that plugin owns}.

    Keyed on the marketplace `name` and populated from that entry's own `source`
    dir, so the arm can resolve a token's plugin and slug as a PAIR. Two entries
    sharing a name union rather than clobber.

    Deliberately plain filesystem calls rather than `git ls-files`: the synthetic
    fixture trees are not git repos, and a git-backed index would come back empty
    there and make every assertion over them vacuously green.
    """
    owned = {}
    for name, rel in plugin_entries:
        slugs = owned.setdefault(name, set())
        skills_dir = os.path.join(root, rel, "skills")
        if os.path.isdir(skills_dir):
            for entry in os.listdir(skills_dir):
                if os.path.isfile(os.path.join(skills_dir, entry, "SKILL.md")):
                    slugs.add(entry)
        agents_dir = os.path.join(root, rel, "agents")
        if os.path.isdir(agents_dir):
            for entry in os.listdir(agents_dir):
                if entry.endswith(".md") and os.path.isfile(
                        os.path.join(agents_dir, entry)):
                    slugs.add(entry[:-3])
    return owned


def compile_target_re(live_names):
    r"""Compile `(name|…):(slug)` over the live plugin names, or None.

    Group 1 is the plugin the token names and group 2 its slug: the arm resolves
    the two as a pair, so the matched prefix has to survive the match rather than
    being discarded by a non-capturing group.

    Names are alternated LONGEST-FIRST so a listed name that is a prefix of
    another cannot shadow it. At least one slug character is required, so a bare
    `plugin:` in prose is not a target hit — that shape belongs to the retired
    arm, which matches the colon alone.
    """
    if not live_names:
        return None
    ordered = sorted(live_names, key=lambda n: (-len(n), n))
    return re.compile(
        r"\b(" + "|".join(re.escape(n) for n in ordered) + r"):([a-z][a-z0-9-]*)")


def discover_files(root):
    """Tracked live-dispatch surfaces, relative to root, via git ls-files."""
    try:
        out = subprocess.check_output(
            ["git", "-C", root, "ls-files", "-z"] + DEFAULT_GLOBS,
            stderr=subprocess.DEVNULL,
        )
    except (subprocess.CalledProcessError, OSError) as exc:
        raise RuntimeError("git ls-files failed: {}".format(exc))
    files = []
    for rel in out.decode("utf-8").split("\x00"):
        if not rel:
            continue
        if rel.startswith(EXCLUDE_PREFIXES):
            continue
        if rel.startswith(EXCLUDE_TOPLEVEL):
            continue
        if any(seg in ("/" + rel) for seg in EXCLUDE_SEGMENTS):
            continue
        files.append(rel)
    return files


def scan_file(abs_path, rel_path, dispatch_re, target_re, resolvable):
    """Return (violations, tokens_examined) for one file.

    Returns a list rather than yielding: the caller has to sum `tokens_examined`
    across files, and a generator makes that count meaningless until drained.
    """
    # Mutation-recipe invariant: keep the open() call in the try below exactly as
    # written, on ONE physical line, and do not repeat that call's text anywhere
    # else in this file — the recorded ed42 recipe rewrites the FIRST match only
    # (perl -0pi, no /g), so a second occurrence would mutate the wrong site and
    # report the decode stance as decorative. The recipe anchors on the whole call,
    # not on its bare encoding argument: that argument's text occurs twice earlier
    # in this file, in the two JSON loaders.
    try:
        with open(abs_path, "r", encoding="utf-8") as fh:
            lines = fh.readlines()
    except (OSError, UnicodeDecodeError) as exc:
        raise RuntimeError("cannot read {}: {}".format(rel_path, exc))
    found = []
    tokens_examined = 0
    for lineno, raw in enumerate(lines, start=1):
        line = raw.rstrip("\n")
        if ALLOW_MARKER in line:
            continue
        for m in dispatch_re.finditer(line):
            found.append({
                "file": rel_path,
                "line": lineno,
                "match": m.group(0),
                "arm": ARM_RETIRED,
                "context": line.strip()[:140],
            })
        if target_re is None:
            continue
        for m in target_re.finditer(line):
            tokens_examined += 1
            plugin = m.group(1)
            slug = m.group(2)
            # Mutation-recipe invariant: keep the next line exactly as written, on
            # ONE physical line, and do not repeat its text anywhere else in this
            # file — the recorded recipe rewrites the FIRST match only (perl -0pi,
            # no /g), so a second occurrence would mutate the wrong site and report
            # this arm as decorative.
            if slug in resolvable.get(plugin, ()):
                continue
            found.append({
                "file": rel_path,
                "line": lineno,
                "match": m.group(0),
                "target": slug,
                "arm": ARM_UNRESOLVED,
                "context": line.strip()[:140],
            })
    return found, tokens_examined


def collect(root, explicit_files, dispatch_re, target_re, resolvable):
    occ = []
    files_scanned = 0
    tokens_examined = 0
    if explicit_files:
        pairs = []
        for f in explicit_files:
            abs_path = f if os.path.isabs(f) else os.path.join(root, f)
            rel = os.path.relpath(abs_path, root)
            if rel == os.pardir or rel.startswith(os.pardir + os.sep):
                raise RuntimeError(
                    "file {!r} is outside --root {!r}".format(f, root))
            pairs.append((abs_path, rel))
    else:
        pairs = [(os.path.join(root, rel), rel) for rel in discover_files(root)]
    for abs_path, rel in pairs:
        found, seen = scan_file(abs_path, rel, dispatch_re, target_re, resolvable)
        occ.extend(found)
        files_scanned += 1
        tokens_examined += seen
    return occ, files_scanned, tokens_examined


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("files", nargs="*",
                    help="explicit files to scan (default: git ls-files globs)")
    ap.add_argument("--root", default=None,
                    help="repo root for discovery + relative paths "
                         "(default: parent of scripts/)")
    ap.add_argument("--registry", default=None,
                    help="retired-prefix registry JSON (default: {} next to this "
                         "script). REPLACES the default file — it is not merged "
                         "with it.".format(REGISTRY_BASENAME))
    args = ap.parse_args(argv)

    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(args.root) if args.root else os.path.dirname(script_dir)
    # Anchored on the script, never on --root: scanning a foreign tree must still
    # read OUR retired set, not whatever that tree happens to ship.
    registry_path = args.registry or os.path.join(script_dir, REGISTRY_BASENAME)

    try:
        retired = load_registry(registry_path)
        live_entries, degraded_reason = load_live_plugins(root)
        # Subtract the retired set from the live set so the two arms partition the
        # token space: a name that is somehow both listed and retired is judged by
        # the retired arm alone and can never be reported twice.
        retired_set = set(retired)
        live_entries = [(n, d) for (n, d) in live_entries if n not in retired_set]
        resolvable = build_target_index(root, live_entries)
        target_re = compile_target_re([n for (n, _) in live_entries])
        violations, files_scanned, tokens_examined = collect(
            root, args.files, compile_dispatch_re(retired), target_re, resolvable)
    except RuntimeError as exc:
        print(json.dumps({"success": False, "data": {}, "error": str(exc)}))
        return 2

    by_plugin = {}
    for o in violations:
        plugin = o["file"].split("/", 1)[0]
        by_plugin[plugin] = by_plugin.get(plugin, 0) + 1

    # Distinct slugs across every plugin's set. `resolvable` is keyed by plugin
    # now, so a bare len() on it would silently degenerate into a plugin count.
    resolvable_target_count = len({s for slugs in resolvable.values() for s in slugs})

    result = {
        "success": not violations,
        "data": {
            "violations": violations,
            "summary": {
                "total": len(violations),
                "by_plugin": by_plugin,
                "files_affected": len(sorted({o["file"] for o in violations})),
            },
            "scanned": {
                "files": files_scanned,
                "tokens": tokens_examined,
                "live_plugins": len(live_entries),
                "resolvable_targets": resolvable_target_count,
                "unresolved_target_arm": target_re is not None,
                "degraded_reason": degraded_reason,
            },
        },
        "error": "",
    }
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if degraded_reason:
        print("\nNOTE: unresolved-target arm did not run ({}) — resolved 0 live "
              "plugins from {}".format(
                  degraded_reason, os.path.join(root, MARKETPLACE_REL)),
              file=sys.stderr)

    retired_hits = [o for o in violations if o["arm"] == ARM_RETIRED]
    unresolved_hits = [o for o in violations if o["arm"] == ARM_UNRESOLVED]

    # Each arm prints its own block. Sharing one would hand an operator the other
    # arm's remedy — "cut over to the vendored cogni-knowledge surface" says
    # nothing useful about a live plugin naming a skill that does not exist.
    if retired_hits:
        print("\nFAIL: {} live {} dispatch(es) found "
              "in live-dispatch surfaces:".format(
                  len(retired_hits), "/".join(p + ":" for p in retired)),
              file=sys.stderr)
        for o in retired_hits:
            print("  {}:{}: {}  ->  {}".format(
                o["file"], o["line"], o["match"], o["context"]), file=sys.stderr)
        print("\nFix: cut the caller over to the vendored cogni-knowledge "
              "surface, OR — for a genuine non-dispatch prose mention — reword "
              "it to drop the `plugin:skill` token (drop the colon), or mark the "
              "line with `# external-dispatch-guard:allow` and a rationale.",
              file=sys.stderr)

    if unresolved_hits:
        print("\nFAIL: {} unresolved-target dispatch(es) found — a live plugin "
              "prefix naming a skill or agent that plugin does not own:".format(
                  len(unresolved_hits)), file=sys.stderr)
        for o in unresolved_hits:
            owners = sorted(
                n for n, slugs in resolvable.items() if o["target"] in slugs)
            note = "  [owned by: {}]".format(", ".join(owners)) if owners else ""
            print("  {}:{}: {}  ->  {}{}".format(
                o["file"], o["line"], o["match"], o["context"], note),
                file=sys.stderr)
        print("\nFix: where a hit is annotated `[owned by: ...]` the slug is real "
              "but the PREFIX names the wrong plugin — repoint the prefix at that "
              "owner. Otherwise the slug names nothing anywhere: repoint it at a "
              "target this plugin owns — the directory name under its skills/ or "
              "the file basename under its agents/. If the line is prose about a "
              "target that is genuinely gone, drop the colon so it stops being "
              "dispatch-shaped, or mark the line with "
              "`# external-dispatch-guard:allow` and a rationale.",
              file=sys.stderr)

    if violations:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

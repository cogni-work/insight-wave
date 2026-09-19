#!/usr/bin/env bash
# test-derive-theme-tokens.sh — tier-0 token derivation and the bundled themes it makes renderable.
#
# scripts/derive-theme-tokens.py turns a tier-0 theme.md into tokens/{colors,typography,spacing}.json
# plus the compiler's tokens.css. The four archetype presets ship that output, so this suite proves
# three separate things, each per theme:
#
#   1. the committed tokens ARE the derivation — re-derived from the committed theme.md into a scratch
#      directory they are byte-identical (dtt-03), twice over (dtt-04), so nothing was hand-edited;
#   2. what was derived is faithful — every literal sits verbatim in the section it came from
#      (dtt-06), the Border role is the row's own hex or absent (dtt-07), each font stack keeps the
#      theme.md order and ends in its generic (dtt-11), and the renderer's roles are all present
#      (dtt-05);
#   3. shared theme/font resolution succeeds for
#      cogni-work and the four presets (dtt-09) and records every font token in provenance (dtt-10),
#      while a theme missing a role fails naming that role (dtt-13).
#
# The oracles below read theme.md with their own section slicer and never call the derivation's
# parser, so a parser defect cannot certify itself. Every negative works on a scratch copy; no tracked
# file is mutated. No network, browser runtime or artifact writer.
#
# CASE IDS. `dtt-NN-<discriminator>`, allocated once and never renumbered. A per-theme case
# interpolates the theme slug, so every emitted line carries a unique first token, and each fail arm
# has a same-id green twin.
#
# MUTATION RECIPE (run from the repository root; the harness is the installed managed-service
# cogni-service plugin, and --expr is evaluated by perl -0pi). It renames the role key the renderer
# reads the page ground from, which must fail the re-derive comparison for boardroom:
# bash "$HOME/.claude/plugins/marketplaces/managed-service/cogni-service/scripts/mutation-check.sh" --root . --file cogni-publishing/scripts/derive-theme-tokens.py --expr 's/"Background": "bg"/"Background": "background"/' --test 'bash cogni-publishing/tests/test-derive-theme-tokens.sh' --case dtt-03-rederive-boardroom

set -u

PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVE="$PLUGIN_ROOT/scripts/derive-theme-tokens.py"
RENDER="$PLUGIN_ROOT/scripts/design-render.py"
VALIDATE="$PLUGIN_ROOT/scripts/validate-theme-manifest.py"
THEMES_DIR="$PLUGIN_ROOT/themes"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
BRIEF="$FIXTURES/narrative-slides-v1.expected.json"
COMPOSITION="$FIXTURES/composition-narrative-v2.json"
NO_MUTED="$FIXTURES/derive/tier0-no-text-muted/theme.md"

# Listed rather than globbed, so a theme that vanished is a red line rather than a shorter loop.
# _template is not a bundled theme: discover-themes skips it, and its rows are placeholders.
PRESETS="boardroom clean-slate editorial signal"
BUNDLED="cogni-work $PRESETS"
DERIVED_FILES="colors.json typography.json spacing.json tokens.css"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
failures=0

pass() { printf '%s\n' "PASS: $1"; }
fail() { printf '%s\n' "FAIL: $1"; failures=$((failures + 1)); }

cat > "$WORK/probe.py" <<'PY'
import ast, hashlib, importlib.util, json, re, sys
from pathlib import Path

SCRIPTS = Path(sys.argv[1])


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def section(text, heading, stop_at_h3=False):
    """The lines under `heading` up to the next heading of the same or higher level (an H3 too when
    stop_at_h3), fenced blocks dropped. An oracle of its own, independent of the derivation."""
    level = heading.split(" ")[0]
    out, inside, fenced = [], False, False
    for line in text.splitlines():
        if line.strip().startswith("```"):
            fenced = not fenced
            continue
        if fenced:
            continue
        if line.strip() == heading:
            inside = True
            continue
        if inside and re.match(r"^#{1,%d} " % len(level), line):
            break
        if inside and stop_at_h3 and line.startswith("### "):
            break
        if inside:
            out.append(line)
    return "\n".join(out)


def resolved(tokens_dir):
    compiler = load("tokens_compiler", "generate-tokens-css.py")
    return compiler.render_resolved(compiler.compile_dir(tokens_dir))["tokens"]


def main():
    op, args = sys.argv[2], sys.argv[3:]
    if op == "stdlib-imports":
        allowed = getattr(sys, "stdlib_module_names", None) or {
            "argparse", "importlib", "json", "re", "sys", "pathlib", "os", "hashlib", "math"}
        bad = []
        for node in ast.walk(ast.parse(Path(args[0]).read_text(encoding="utf-8"))):
            names = [a.name for a in node.names] if isinstance(node, ast.Import) else \
                [node.module or ""] if isinstance(node, ast.ImportFrom) else []
            bad += [n for n in names if n.split(".")[0] not in allowed]
        print("OK" if not bad else "NON-STDLIB:" + ",".join(bad))
    elif op == "envelope":  # <stdout-file> <expect: true|false> [<code>]
        lines = Path(args[0]).read_text(encoding="utf-8").splitlines()
        if len(lines) != 1:
            print(f"LINES:{len(lines)}"); return
        d = json.loads(lines[0])
        if set(d) != {"success", "data", "error"}:
            print("KEYS:" + ",".join(sorted(d))); return
        if d["success"] is not (args[1] == "true"):
            print(f"SUCCESS:{d['success']}:{d['error']}"); return
        if len(args) > 2 and d["data"].get("code") != args[2]:
            print(f"CODE:{d['data'].get('code')}"); return
        print("OK")
    elif op == "roles":  # <tokens-dir>
        core = load("render_core", "render_core.py")
        tokens = resolved(args[0])
        need = list(core.REQUIRED_TOKENS) + [("spacing", str(n)) for n in range(10)]
        missing = [f"{s}.{k}" for s, k in need if k not in tokens.get(s, {})]
        print("OK" if not missing else "MISSING:" + ",".join(missing))
    elif op == "verbatim":  # <tokens-dir> <theme.md>
        text = Path(args[1]).read_text(encoding="utf-8")
        core = load("render_core", "render_core.py")
        blocks = {"colors": section(text, "## Color Palette"),
                  "fonts": section(text, "## Typography", stop_at_h3=True),
                  "scale": section(text, "### Type Scale"),
                  "spacing": section(text, "## Spacing Scale")}
        bad = []
        for stem, values in resolved(args[0]).items():
            for key, value in values.items():
                if stem == "typography" and key.startswith("font-"):
                    bad += [f"{key}={f}" for f in core.split_stack(value) if f not in blocks["fonts"]]
                    continue
                block = blocks["colors" if stem == "colors" else "spacing" if stem == "spacing" else "scale"]
                if not re.search(r"(?<![0-9A-Za-z.#-])" + re.escape(str(value)) + r"(?![0-9A-Za-z.])", block):
                    bad.append(f"{stem}.{key}={value}")
        print("OK" if not bad else "NOT-IN-THEME-MD:" + ",".join(bad))
    elif op == "border":  # <tokens-dir> <theme.md>
        rows = re.findall(r"^- \*\*Border\*\*:\s*`(#[0-9A-Fa-f]{6})`",
                          section(Path(args[1]).read_text(encoding="utf-8"), "## Color Palette"), re.M)
        border = json.loads((Path(args[0]) / "colors.json").read_text(encoding="utf-8")).get("border")
        if rows:
            print("OK" if border == rows[0] else f"BORDER:{border}!={rows[0]}")
        else:
            print("OK" if border is None else f"UNSOURCED-BORDER:{border}")
    elif op == "font-order":  # <tokens-dir> <theme.md>
        core = load("render_core", "render_core.py")
        generics = set(core.load_fallbacks()["generic_families"])
        typography = json.loads((Path(args[0]) / "typography.json").read_text(encoding="utf-8"))
        roles = {"Headers": "font-heading", "Body": "font-sans", "Mono": "font-mono"}
        bad = []
        for label, value in re.findall(r"^- \*\*(\w+)\*\*:\s*(.+)$",
                                       section(Path(args[1]).read_text(encoding="utf-8"), "## Typography",
                                               stop_at_h3=True), re.M):
            first, _, rest = value.partition("/ fallback:")
            expected = [f.strip() for f in [first] + rest.split(",") if f.strip()]
            got = core.split_stack(typography.get(roles[label], ""))
            if got != expected or got[-1].lower() not in generics:
                bad.append(f"{label}:{got}")
        print("OK" if not bad else "ORDER:" + ";".join(bad))
    elif op == "resolve":  # shared verifier theme/font contract, no renderer needed
        core = load("render_core", "render_core.py")
        try:
            theme = core.resolve_theme(args[0], {"name": Path(args[0]).name})
            fonts, _ = core.resolve_fonts(theme)
            out = Path(args[1]); out.mkdir(parents=True, exist_ok=True)
            (out / "provenance.json").write_text(json.dumps({"fonts": [core.font_record(f) for f in fonts]}))
            print(json.dumps({"success": True, "data": {}, "error": None}))
        except core.RenderError as exc:
            print(json.dumps({"success": False, "data": exc.finding, "error": str(exc)}))
    elif op == "render":  # <stdout-file>  → OK | MISSING:<role> | FAIL:...
        core = load("render_core", "render_core.py")
        d = json.loads(Path(args[0]).read_text(encoding="utf-8"))
        roles = {f"{s}.{k}" for s, k in core.REQUIRED_TOKENS}
        finding = d.get("data") or {}
        if d.get("success"):
            print("OK")
        elif finding.get("code") == "invalid-theme" and finding.get("check") == "theme-token-missing" \
                and finding.get("reference") in roles:
            print("MISSING:" + finding["reference"])
        else:
            print(f"FAIL:{finding.get('code')}/{finding.get('check')}/{finding.get('reference')}")
    elif op == "font-records":  # <provenance.json> <tokens-dir>
        prov = json.loads(Path(args[0]).read_text(encoding="utf-8"))
        want = {f"typography.{k}" for k in resolved(args[1])["typography"] if k.startswith("font-")}
        got = {f["token"] for f in prov.get("fonts", [])}
        unrecorded = [f["token"] for f in prov.get("fonts", []) if f["resolved_face"] != f["requested_family"]
                      and not f["substituted"]]
        print("OK" if got == want and not unrecorded else f"FONTS:{sorted(got)}!={sorted(want)};{unrecorded}")
    elif op == "literals":  # <script>
        text = Path(args[0]).read_text(encoding="utf-8")
        header = load("tokens_compiler", "generate-tokens-css.py").HEADER.strip()
        bad = [label for label, hit in (("hex", re.search(r"#[0-9A-Fa-f]{6}", text)), (":root", ":root {" in text),
                                        ("header", header in text)) if hit]
        print("OK" if not bad else "LITERALS:" + ",".join(bad))
    elif op == "required-intact":
        core = load("render_core", "render_core.py")
        ok = len(core.REQUIRED_TOKENS) == 22 and ("colors", "border") in core.REQUIRED_TOKENS
        print("OK" if ok else f"REQUIRED:{len(core.REQUIRED_TOKENS)}")
    elif op == "tree":  # <dir>  → name:sha256 per file, sorted
        root = Path(args[0])
        for path in sorted(p for p in root.rglob("*") if p.is_file()):
            print(f"{path.relative_to(root)}:{hashlib.sha256(path.read_bytes()).hexdigest()}")
    elif op == "compose-as":  # <composition> <name> <out>
        c = json.loads(Path(args[0]).read_text(encoding="utf-8"))
        c["design_system"]["name"] = args[1]
        Path(args[2]).write_text(json.dumps(c, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


main()
PY

probe() { python3 "$WORK/probe.py" "$PLUGIN_ROOT/scripts" "$@"; }

# derive <out-stem> <args...>: runs the derivation, stdout to <out-stem>.json, stderr to <out-stem>.err,
# and leaves its exit status in $rc.
derive() {
  local stem="$1"
  shift
  python3 "$DERIVE" "$@" > "$stem.json" 2> "$stem.err"
  rc=$?
}

same_files() {  # same_files <dir-a> <dir-b>: the derived files are byte-identical and nothing else is there
  local f
  for f in $DERIVED_FILES; do cmp -s "$1/$f" "$2/$f" || return 1; done
  [ "$(cd "$1" && ls | sort | tr '\n' ' ')" = "$(cd "$2" && ls | sort | tr '\n' ' ')" ]
}

# --------------------------------------------------------------------------------------------------
# dtt-01 / dtt-02 — the script's contract
# --------------------------------------------------------------------------------------------------

derive "$WORK/usage"
verdict="$(probe envelope "$WORK/usage.json" false usage-error)"
if [ "$rc" -eq 2 ] && [ "$verdict" = OK ] && [ ! -s "$WORK/usage.err" ]; then
  pass "dtt-01-envelope-usage a missing theme argument exits 2 with one envelope and nothing on stderr"
else
  fail "dtt-01-envelope-usage a missing theme argument gave exit $rc, envelope $verdict"
fi

verdict="$(probe stdlib-imports "$DERIVE")"
if [ "$verdict" = OK ]; then
  pass "dtt-02-stdlib-imports derive-theme-tokens.py imports the standard library only"
else
  fail "dtt-02-stdlib-imports derive-theme-tokens.py imports outside the standard library: $verdict"
fi

# --------------------------------------------------------------------------------------------------
# dtt-03 .. dtt-08, dtt-11 — per preset: the committed tokens are the faithful derivation
# --------------------------------------------------------------------------------------------------

presets_derived=0
for theme in $PRESETS; do
  dir="$THEMES_DIR/$theme"
  first="$WORK/derived/$theme-1"
  second="$WORK/derived/$theme-2"
  mkdir -p "$WORK/derived"

  derive "$first" "$dir" --tokens-dir "$first"
  verdict="$(probe envelope "$first.json" true)"
  if [ "$rc" -eq 0 ] && [ "$verdict" = OK ] && [ ! -s "$first.err" ] && same_files "$first" "$dir/tokens"; then
    pass "dtt-03-rederive-$theme re-deriving themes/$theme/theme.md reproduces its committed tokens byte for byte"
    presets_derived=$((presets_derived + 1))
  else
    fail "dtt-03-rederive-$theme re-deriving themes/$theme/theme.md does not reproduce its committed tokens (exit $rc, envelope $verdict)"
  fi

  derive "$second" "$dir" --tokens-dir "$second"
  if [ "$rc" -eq 0 ] && same_files "$first" "$second"; then
    pass "dtt-04-idempotent-$theme a second derivation of themes/$theme is byte-identical to the first"
  else
    fail "dtt-04-idempotent-$theme a second derivation of themes/$theme differs from the first (exit $rc)"
  fi

  verdict="$(probe roles "$dir/tokens")"
  if [ "$verdict" = OK ]; then
    pass "dtt-05-roles-$theme themes/$theme carries every role design-render requires, plus spacing 0-9"
  else
    fail "dtt-05-roles-$theme themes/$theme lacks renderer roles: $verdict"
  fi

  verdict="$(probe verbatim "$dir/tokens" "$dir/theme.md")"
  if [ "$verdict" = OK ]; then
    pass "dtt-06-verbatim-$theme every token literal of themes/$theme sits verbatim in the theme.md section it came from"
  else
    fail "dtt-06-verbatim-$theme themes/$theme carries literals its theme.md does not state: $verdict"
  fi

  verdict="$(probe border "$dir/tokens" "$dir/theme.md")"
  if [ "$verdict" = OK ]; then
    pass "dtt-07-border-$theme themes/$theme colors.border is its theme.md Border row, or absent without one"
  else
    fail "dtt-07-border-$theme themes/$theme colors.border is not sourced from its theme.md: $verdict"
  fi

  manifest_tier="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("tiers", {}).get("tokens"))' "$dir/manifest.json" 2>/dev/null)"
  if [ "$manifest_tier" = "tokens/" ] && python3 "$VALIDATE" "$dir" > /dev/null 2>&1; then
    pass "dtt-08-manifest-$theme themes/$theme declares tiers.tokens and passes validate-theme-manifest"
  else
    fail "dtt-08-manifest-$theme themes/$theme tiers.tokens is '$manifest_tier' or validate-theme-manifest rejects it"
  fi

  verdict="$(probe font-order "$dir/tokens" "$dir/theme.md")"
  if [ "$verdict" = OK ]; then
    pass "dtt-11-font-order-$theme themes/$theme font stacks keep the theme.md family order and end in a generic"
  else
    fail "dtt-11-font-order-$theme themes/$theme font stacks drift from theme.md: $verdict"
  fi
done

# --------------------------------------------------------------------------------------------------
# dtt-09 / dtt-10 — every bundled theme renders through design-render
# --------------------------------------------------------------------------------------------------

renders=0
for theme in $BUNDLED; do
  out="$WORK/render/$theme"
  mkdir -p "$WORK/render"
  probe compose-as "$COMPOSITION" "$theme" "$WORK/render/composition-$theme.json"
  probe resolve "$THEMES_DIR/$theme" "$out" > "$out.json" 2> "$out.err"
  verdict="$(probe render "$out.json")"
  case "$verdict" in
    OK|MISSING:*)
      pass "dtt-09-render-$theme the verifier resolves themes/$theme, or names the role it lacks ($verdict)"
      renders=$((renders + 1)) ;;
    *) fail "dtt-09-render-$theme the verifier rejects themes/$theme without naming a required role: $verdict" ;;
  esac

  if [ "$verdict" = OK ] && [ "$(probe font-records "$out/provenance.json" "$THEMES_DIR/$theme/tokens")" = OK ]; then
    pass "dtt-10-fonts-$theme the themes/$theme resolution records every font token, and every substitution, in provenance"
  else
    fail "dtt-10-fonts-$theme the themes/$theme resolution did not succeed or its provenance omits a font token"
  fi
done

# --------------------------------------------------------------------------------------------------
# dtt-12 / dtt-13 — a missing role stays missing, and the renderer names it
# --------------------------------------------------------------------------------------------------

muted="$WORK/no-muted/tier0-no-text-muted"
mkdir -p "$muted"
cp "$NO_MUTED" "$muted/theme.md"
derive "$WORK/no-muted/derive" "$muted"
has_muted="$(python3 -c 'import json,sys; print("text-muted" in json.load(open(sys.argv[1])))' "$muted/tokens/colors.json" 2>/dev/null)"
if [ "$rc" -eq 0 ] && [ "$has_muted" = False ]; then
  pass "dtt-12-missing-text-muted-derive a theme.md with no Text Muted row derives no colors.text-muted"
else
  fail "dtt-12-missing-text-muted-derive the Text Muted fixture gave exit $rc and text-muted present=$has_muted"
fi

probe compose-as "$COMPOSITION" tier0-no-text-muted "$WORK/no-muted/composition.json"
probe resolve "$muted" "$WORK/no-muted/out" > "$WORK/no-muted/render.json"
verdict="$(probe render "$WORK/no-muted/render.json")"
if [ "$verdict" = "MISSING:colors.text-muted" ]; then
  pass "dtt-13-missing-text-muted-render the verifier fails invalid-theme / theme-token-missing naming colors.text-muted"
else
  fail "dtt-13-missing-text-muted-render the Text Muted fixture rendered as $verdict, not a colors.text-muted finding"
fi

# --------------------------------------------------------------------------------------------------
# dtt-14 / dtt-15 — existing tokens are never overwritten without the explicit opt-in
# --------------------------------------------------------------------------------------------------

mkdir -p "$WORK/clobber"
cp -R "$THEMES_DIR/cogni-work" "$WORK/clobber/cogni-work"
before="$(probe tree "$WORK/clobber/cogni-work")"
derive "$WORK/clobber/derive" "$WORK/clobber/cogni-work"
verdict="$(probe envelope "$WORK/clobber/derive.json" false tokens-exist)"
after="$(probe tree "$WORK/clobber/cogni-work")"
if [ "$rc" -eq 1 ] && [ "$verdict" = OK ] && [ -n "$before" ] && [ "$before" = "$after" ]; then
  pass "dtt-14-no-clobber a theme that already ships tokens is refused as tokens-exist and left byte-identical"
else
  fail "dtt-14-no-clobber deriving over cogni-work's tokens gave exit $rc, envelope $verdict, or changed a file"
fi

mkdir -p "$WORK/overwrite"
cp -R "$THEMES_DIR/boardroom" "$WORK/overwrite/boardroom"
printf '{"bg": "stale"}\n' > "$WORK/overwrite/boardroom/tokens/colors.json"
derive "$WORK/overwrite/refused" "$WORK/overwrite/boardroom"
refused=$rc
derive "$WORK/overwrite/forced" "$WORK/overwrite/boardroom" --overwrite
if [ "$refused" -eq 1 ] && [ "$rc" -eq 0 ] && same_files "$WORK/overwrite/boardroom/tokens" "$THEMES_DIR/boardroom/tokens"; then
  pass "dtt-15-overwrite-opt-in only --overwrite replaces existing tokens, and then with the full derivation"
else
  fail "dtt-15-overwrite-opt-in without --overwrite exit $refused, with it exit $rc, or the result is not the derivation"
fi

# --------------------------------------------------------------------------------------------------
# dtt-16 .. dtt-18 — a bad row is refused, and only the read sections are read
# --------------------------------------------------------------------------------------------------

mkdir -p "$WORK/malformed/malformed"
sed 's/^- \*\*Primary\*\*: `#[0-9A-Fa-f]*`/- **Primary**: `#HEXHEX`/' "$THEMES_DIR/boardroom/theme.md" > "$WORK/malformed/malformed/theme.md"
derive "$WORK/malformed/derive" "$WORK/malformed/malformed"
verdict="$(probe envelope "$WORK/malformed/derive.json" false malformed-row)"
if [ "$rc" -eq 1 ] && [ "$verdict" = OK ] && grep -q 'Primary' "$WORK/malformed/derive.json" && [ ! -e "$WORK/malformed/malformed/tokens" ]; then
  pass "dtt-16-malformed-row a palette row without a hex is refused, named, and nothing is written"
else
  fail "dtt-16-malformed-row a placeholder palette row gave exit $rc, envelope $verdict, or wrote tokens"
fi

mkdir -p "$WORK/duplicate/duplicate"
awk '{print} /^- \*\*Surface\*\*:/ {print}' "$THEMES_DIR/boardroom/theme.md" > "$WORK/duplicate/duplicate/theme.md"
derive "$WORK/duplicate/derive" "$WORK/duplicate/duplicate"
verdict="$(probe envelope "$WORK/duplicate/derive.json" false duplicate-row)"
if [ "$rc" -eq 1 ] && [ "$verdict" = OK ] && grep -q 'Surface' "$WORK/duplicate/derive.json" && [ ! -e "$WORK/duplicate/duplicate/tokens" ]; then
  pass "dtt-17-duplicate-row a repeated palette row is refused, named, and nothing is written"
else
  fail "dtt-17-duplicate-row a repeated Surface row gave exit $rc, envelope $verdict, or wrote tokens"
fi

# A palette-shaped row inside the Web Embedding fence, and another under ## Radii, must change nothing.
mkdir -p "$WORK/scope/boardroom"
awk '{print} /^```css$/ {print "- **Background**: `#000000` - inside a fence"} /^## Radii$/ {print ""; print "- **Text**: `#000000` - outside every read section"}' \
  "$THEMES_DIR/boardroom/theme.md" > "$WORK/scope/boardroom/theme.md"
derive "$WORK/scope/derive" "$WORK/scope/boardroom" --tokens-dir "$WORK/scope/tokens"
injected="$(grep -c '#000000' "$WORK/scope/boardroom/theme.md")"
if [ "$rc" -eq 0 ] && [ "$injected" -eq 2 ] && same_files "$WORK/scope/tokens" "$THEMES_DIR/boardroom/tokens"; then
  pass "dtt-18-heading-scope rows inside a fence or outside the read sections change no token"
else
  fail "dtt-18-heading-scope injected rows ($injected placed) changed the derivation (exit $rc)"
fi

# --------------------------------------------------------------------------------------------------
# dtt-19 / dtt-20 — the derivation invents nothing, and the renderer's bar is unlowered
# --------------------------------------------------------------------------------------------------

verdict="$(probe literals "$DERIVE")"
if [ "$verdict" = OK ]; then
  pass "dtt-19-script-literals the derivation carries no hex literal, no :root block and no copy of the compiler header"
else
  fail "dtt-19-script-literals the derivation carries a literal it must not: $verdict"
fi

verdict="$(probe required-intact)"
if [ "$verdict" = OK ] \
    && ! grep -q -e 'Color Palette' -e 'derive-theme-tokens' "$PLUGIN_ROOT/scripts/render_core.py"; then
  pass "dtt-20-renderer-contract REQUIRED_TOKENS keeps 22 roles including colors.border, and the renderer parses no theme.md prose"
else
  fail "dtt-20-renderer-contract the renderer's required roles shrank ($verdict) or it now reads theme.md prose"
fi

# --------------------------------------------------------------------------------------------------
# dtt-21 — anti-vacuity floor
# --------------------------------------------------------------------------------------------------

if [ "$presets_derived" -ge 4 ] && [ "$renders" -ge 5 ]; then
  pass "dtt-21-floor $presets_derived presets re-derived and $renders bundled themes rendered"
else
  fail "dtt-21-floor only $presets_derived preset(s) re-derived and $renders bundled theme(s) rendered; expected 4 and 5"
fi

if [ "$failures" -gt 0 ]; then
  printf '%s\n' "$failures derive-theme-tokens check(s) failed."
  exit 1
fi
printf '%s\n' "All derive-theme-tokens checks passed."
exit 0

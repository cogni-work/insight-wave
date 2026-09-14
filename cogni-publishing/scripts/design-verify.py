#!/usr/bin/env python3
"""design-verify: verify rendered design-render output against its frozen inputs, and render with a
bounded repair loop.

Stdlib only. Every invocation prints exactly one JSON envelope, {"success", "data", "error"}, on stdout
and nothing on stderr; exit 0 on success, 1 on a finding, 2 on a usage or runtime problem.

Commands:
  preserve         copy, dataset values, source URLs, evidence status, notes and unit order of a page or
                   deck against the frozen brief, family by family (a family the brief lacks is not-carried)
  editability      a deck's copy is native text, its charts native charts with embedded data, and a picture
                   only a declared fallback; plus deterministic text and chart edit witnesses
  accessibility    reading order, text alternatives, contrast and non-colour cues, graded against the
                   target's declared capabilities (passed, failed or unsupported)
  geometry         the critical classes: clipping, overlap, missing glyphs and misleading encodings
  verify           the full report for one output; its verdict fails on any open finding
  check-review     a persisted visual review record covers every unit, target and brand of a proof
  check-specimens  a specimen index resolves every pattern a proof uses on both targets
  check-proof      a proof manifest's recorded hashes, reports, review and specimens all hold
  render-verified  render, verify, and on failure try the other variants of the failing unit's pattern
                   within a finite budget; frozen content never changes

Every input is a path the caller supplies. Nothing here reads the environment or the home directory,
probes another plugin, calls a model or touches the network. references/design-verify.md is the
normative description.
"""

import argparse
import copy
import json
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).absolute().parent))

import render_core as core  # noqa: E402
import verify_checks as checks  # noqa: E402

design_render = core.load_script("cogni_publishing_design_render", "design-render.py")

TARGETS = ("html", "pptx")
ARTIFACTS = {"html": "index.html", "pptx": "deck.pptx"}
DEFAULT_CAPABILITIES = core.REFERENCES / "verify-capabilities.json"
# The repair budget is the number of repaired compositions render-verified may try after the first
# render: a finite integer, 3 unless the caller passes --budget, and never more than MAX_REPAIR_BUDGET.
DEFAULT_REPAIR_BUDGET = 3
MAX_REPAIR_BUDGET = 10
PROOF_OUTPUTS = 4
SAFE_FIXED_TIME = re.compile(r"^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$")


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise core.RenderError("usage-error", message, "usage", status=2)


def envelope(success, data, error):
    return {"success": success, "data": data, "error": error}


def dump(value):
    return (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode("utf-8")


def read_bytes(path, artifact):
    try:
        return Path(path).read_bytes()
    except OSError as exc:
        raise core.RenderError("runtime-error", f"cannot read {path}: {exc}", "input", str(path), artifact=artifact,
                               status=2)


def load_inputs(args):
    brief = core.read_json(args.brief, "normalized_brief")
    composition = core.read_json(args.composition, "semantic_composition")
    library, _ = core.validate_inputs(brief, composition)
    return brief, composition, library


def resolve_theme(args, composition, target):
    theme = core.resolve_theme(args.theme, composition["design_system"])
    _, font = core.resolve_fonts(theme, embed_faces=target == "html")
    return theme, font


def check_target(target):
    if target not in TARGETS:
        raise core.RenderError("unsupported-target", f"design-verify verifies {', '.join(TARGETS)}; {target!r} is not "
                               "a design-render target", "target", target)


def declaration(args):
    try:
        return checks.load_capabilities(args.capabilities)
    except (OSError, ValueError) as exc:
        raise core.RenderError("runtime-error", f"cannot read the capability declaration: {exc}", "capabilities",
                               str(args.capabilities), status=2)


def failed(code, check, data, message):
    error = core.RenderError(code, message, check)
    error.finding.update(data)
    return error


# --- the single-check commands ---------------------------------------------------------------------

def cmd_preserve(args):
    check_target(args.target)
    brief, composition, _ = load_inputs(args)
    families = checks.preserve(args.target, read_bytes(args.artifact, "artifact"), brief, composition)
    data = {"target": args.target, "families": families}
    if any(result["status"] == "failed" for result in families.values()):
        raise failed("content-differs", "preservation", data, "the artifact does not carry the frozen content")
    return data


def cmd_editability(args):
    brief, composition, library = load_inputs(args)
    data_bytes = read_bytes(args.pptx, "pptx")
    result = checks.editability(data_bytes, brief, composition, library)
    witnesses = checks.edit_witnesses(data_bytes, brief, composition)
    findings = result["findings"] + [checks.finding("witness-failed", "editability", w.get("object"),
                                                    f"the {w['kind']} edit witness failed")
                                     for w in witnesses if w["status"] != "passed"]
    data = {"objects": result["objects"], "witnesses": witnesses, "findings": findings}
    if findings:
        raise failed("not-editable", "editability", data, "the deck is not natively editable where it promises to be")
    return data


def cmd_accessibility(args):
    check_target(args.target)
    brief, composition, library = load_inputs(args)
    theme, _ = resolve_theme(args, composition, args.target)
    result = checks.accessibility(args.target, read_bytes(args.artifact, "artifact"), brief, composition, library,
                                  theme, declaration(args))
    data = {"target": args.target, "requirements": result["requirements"], "findings": result["findings"]}
    if result["findings"]:
        raise failed("accessibility-failed", "accessibility", data, "a required accessibility capability failed")
    return data


def browser_report(args):
    if not getattr(args, "browser_report", None):
        return None
    try:
        return json.loads(Path(args.browser_report).read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        raise core.RenderError("runtime-error", f"cannot read the browser report: {exc}", "browser-report",
                               str(args.browser_report), status=2)


def cmd_geometry(args):
    check_target(args.target)
    brief, composition, _ = load_inputs(args)
    _, font = resolve_theme(args, composition, args.target)
    result = checks.geometry(args.target, read_bytes(args.artifact, "artifact"), brief, composition, font,
                             browser_report(args))
    data = {"target": args.target, "coverage": result["coverage"], "findings": result["findings"]}
    if result["findings"]:
        raise failed("geometry-failed", "geometry", data, "the artifact carries a critical geometry finding")
    return data


def verify_output(args, target, artifact_path, manifest_path=None, review=None, composition_path=None):
    """The full report for one output. `composition_path` names the composition the output was rendered
    from when it is not the caller's --composition — a repaired attempt's."""
    brief = core.read_json(args.brief, "normalized_brief")
    composition = core.read_json(composition_path or args.composition, "semantic_composition")
    library, _ = core.validate_inputs(brief, composition)
    theme, font = resolve_theme(args, composition, target)
    manifest = None
    if manifest_path:
        manifest = core.read_json(manifest_path, "pptx_manifest")
    data = read_bytes(artifact_path, "artifact")
    return checks.build_report(target, theme.slug, ARTIFACTS[target], data, brief, composition, theme, font, library,
                               declaration(args), manifest, review, browser_report(args))


def cmd_verify(args):
    check_target(args.target)
    review = core.read_json(args.review, "review_record") if args.review else None
    report = verify_output(args, args.target, args.artifact, args.manifest, review)
    if args.out:
        out = Path(args.out).absolute()
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(dump(report))
    data = {"verdict": report["verdict"], "findings": report["findings"], "report": str(Path(args.out).absolute())
            if args.out else None, "checks": report["checks"]}
    if report["verdict"] != "pass":
        raise failed("verification-failed", "verify", data, f"{len(report['findings'])} open finding(s) fail the "
                     "verification")
    return data


# --- the persisted records --------------------------------------------------------------------------

def proof_root(manifest_path, manifest):
    base = Path(manifest_path).absolute().parent
    return (base / manifest.get("root", ".")).resolve()


def proof_outputs(manifest, root):
    """[(brand, target, artifact sha256, unit ids)] for the review check, from the proof's compositions."""
    outputs = []
    for output in manifest.get("outputs", []):
        composition = json.loads(checks.resolve_inside(root, output["composition"]["path"]).read_text(encoding="utf-8"))
        outputs.append((output["brand"], output["target"], output["artifact"]["sha256"],
                        [unit["id"] for unit in composition["units"]]))
    return outputs


def used_patterns(manifest, root):
    used = set()
    for output in manifest.get("outputs", []):
        composition = json.loads(checks.resolve_inside(root, output["composition"]["path"]).read_text(encoding="utf-8"))
        used |= {(unit["pattern"], unit["variant"]) for unit in composition["units"]}
    return used


def cmd_check_review(args):
    manifest = core.read_json(args.proof, "proof_manifest")
    root = proof_root(args.proof, manifest)
    record = core.read_json(args.record, "review_record")
    problems = checks.check_review(record, proof_outputs(manifest, root))
    data = {"valid": not problems, "entries": len(record.get("entries", [])) if isinstance(record, dict) else 0,
            "overviews": len(record.get("overviews", [])) if isinstance(record, dict) else 0, "findings": problems}
    if problems:
        raise failed("review-invalid", "review", data, "the review record is incomplete or states an unqualified verdict")
    return data


def cmd_check_specimens(args):
    manifest = core.read_json(args.proof, "proof_manifest")
    root = proof_root(args.proof, manifest)
    index = core.read_json(args.index, "specimen_index")
    problems = checks.check_specimens(index, Path(args.index).absolute().parent, used_patterns(manifest, root))
    data = {"valid": not problems, "patterns": len(index.get("patterns", [])) if isinstance(index, dict) else 0,
            "findings": problems}
    if problems:
        raise failed("specimens-invalid", "specimens", data, "the specimen index does not resolve every proof pattern")
    return data


def recorded(root, entry, what, problems):
    """Recompute one {path, sha256} record; a mismatch or a missing file is a finding."""
    if not isinstance(entry, dict) or not entry.get("path"):
        problems.append(checks.finding("proof-malformed", "proof", what, f"{what} records no path"))
        return None
    try:
        path = checks.resolve_inside(root, entry["path"])
        data = path.read_bytes()
    except (ValueError, OSError) as exc:
        problems.append(checks.finding("proof-unresolved", "proof", what, f"{what}: {exc}"))
        return None
    if checks.sha256(data) != entry.get("sha256"):
        problems.append(checks.finding("proof-hash-mismatch", "proof", what, f"{entry['path']} does not match its "
                                       "recorded sha256"))
    return data


def check_output(root, output, problems):
    where = f"{output.get('brand')}/{output.get('target')}"
    for key in ("composition", "plan", "artifact", "provenance", "verification"):
        recorded(root, output.get(key), f"{where}:{key}", problems)
    if output.get("target") == "pptx":
        recorded(root, output.get("manifest"), f"{where}:manifest", problems)
    theme = output.get("theme") or {}
    brand = output.get("brand")
    if theme.get("path") != f"themes/{brand}":
        problems.append(checks.finding("proof-brand", "proof", where, "the brand is not a bundled theme of this plugin"))
    else:
        directory = checks.resolve_inside(root, theme["path"])
        want = sorted(["theme.md"] + [f"tokens/{p.name}" for p in (directory / "tokens").glob("*.json")])
        files = theme.get("files") or {}
        if sorted(files) != want:
            problems.append(checks.finding("proof-brand", "proof", where, f"the brand files recorded {sorted(files)} "
                                           f"are not the theme's authoritative files {want}"))
        for name, digest in files.items():
            recorded(root, {"path": f"{theme['path']}/{name}", "sha256": digest}, f"{where}:theme:{name}", problems)
    renderer = output.get("renderer") or {}
    if renderer.get("name") != core.RENDERER_NAME or not checks.EXACT_VERSION.match(str(renderer.get("version"))):
        problems.append(checks.finding("proof-renderer", "proof", where, "the output records no exact renderer version"))
    command = output.get("command")
    if not isinstance(command, str) or f"--target {output.get('target')}" not in command \
            or f"--theme {theme.get('path')}" not in command:
        problems.append(checks.finding("proof-command", "proof", where, "the output records no producing command"))
    try:
        report = json.loads(checks.resolve_inside(root, output["verification"]["path"]).read_text(encoding="utf-8"))
        provenance = json.loads(checks.resolve_inside(root, output["provenance"]["path"]).read_text(encoding="utf-8"))
    except (KeyError, TypeError, ValueError, OSError) as exc:
        problems.append(checks.finding("proof-unresolved", "proof", where, f"cannot read the report or provenance: {exc}"))
        return
    if report.get("verdict") != "pass" or report.get("artifact", {}).get("sha256") != output["artifact"].get("sha256"):
        problems.append(checks.finding("proof-unverified", "proof", where, "the output's verification report does not "
                                       "pass for this artifact"))
    if provenance.get("outputs", {}).get("artifact", {}).get("sha256") != output["artifact"].get("sha256") \
            or provenance.get("renderer", {}).get("version") != renderer.get("version"):
        problems.append(checks.finding("proof-provenance", "proof", where, "the provenance records another artifact or "
                                       "renderer"))


def cmd_check_proof(args):
    manifest = core.read_json(args.manifest, "proof_manifest")
    root = proof_root(args.manifest, manifest)
    problems = []
    for key in ("brief", "normalized_brief"):
        recorded(root, manifest.get(key), key, problems)
    outputs = manifest.get("outputs") if isinstance(manifest.get("outputs"), list) else []
    pairs = [(o.get("brand"), o.get("target")) for o in outputs if isinstance(o, dict)]
    brands = sorted({brand for brand, _ in pairs})
    if len(outputs) != PROOF_OUTPUTS or len(brands) != 2 or \
            sorted(pairs) != sorted((brand, target) for brand in brands for target in TARGETS):
        problems.append(checks.finding("proof-outputs", "proof", None, f"the proof records {pairs}, not html and pptx "
                                       "for each of two distinct brands"))
    for output in outputs:
        if isinstance(output, dict):
            check_output(root, output, problems)
    for key in ("review", "specimens", "repair", "isolated_render"):
        recorded(root, manifest.get(key), key, problems)
    if not problems:
        review = json.loads(checks.resolve_inside(root, manifest["review"]["path"]).read_text(encoding="utf-8"))
        problems += checks.check_review(review, proof_outputs(manifest, root))
        index_path = checks.resolve_inside(root, manifest["specimens"]["path"])
        index = json.loads(index_path.read_text(encoding="utf-8"))
        problems += checks.check_specimens(index, index_path.parent, used_patterns(manifest, root))
    data = {"valid": not problems, "outputs": len(outputs), "brands": brands, "findings": problems}
    if problems:
        raise failed("proof-invalid", "proof", data, "the proof manifest does not hold")
    return data


# --- render-verified: the bounded repair loop -------------------------------------------------------

def budget_left(used, budget):
    return used < budget


def attempt(args, composition, directory):
    """Render one composition into `directory` through design-render itself, then verify the result.
    Returns (verdict, findings, report)."""
    comp_path = directory / "composition.json"
    comp_path.write_bytes(dump(composition))
    render_args = argparse.Namespace(command="render", target=args.target, brief=args.brief, composition=str(comp_path),
                                     theme=args.theme, out=str(directory / "out"), language=args.language, measure=False,
                                     runtime_root=str(core.RUNTIME_DIR), generated_at=args.generated_at,
                                     run_id=args.run_id)
    try:
        design_render.cmd_render(render_args)
    except core.RenderError as exc:
        rendered = dict(exc.finding)
        klass = checks.FIDELITY_CLASSES.get(rendered.get("code"))
        found = [checks.finding(rendered.get("code"), "render", rendered.get("reference"), str(exc), klass)]
        for item in rendered.get("findings", []):
            found.append(checks.finding(item.get("code"), "render", item.get("reference"), item.get("message", ""),
                                        checks.FIDELITY_CLASSES.get(item.get("code"))))
        return "fail", found, None
    manifest = str(directory / "out" / "pptx-manifest.json") if args.target == "pptx" else None
    report = verify_output(args, args.target, directory / "out" / ARTIFACTS[args.target], manifest,
                           composition_path=comp_path)
    return report["verdict"], report["findings"], report


def failing_unit(findings, composition):
    units = [unit["id"] for unit in composition["units"]]
    for item in findings:
        if item.get("unit") in units:
            return item["unit"]
    return None


def candidates(composition, unit_id, library, tried):
    """The other variants of the failing unit's pattern, in library order: the only presentation choices a
    repair may change without new entities or relationships."""
    unit = next(u for u in composition["units"] if u["id"] == unit_id)
    pattern = next(p for p in library["patterns"] if p["id"] == unit["pattern"])
    for variant in pattern["variants"]:
        if variant["id"] != unit["variant"] and (unit_id, variant["id"]) not in tried:
            yield variant["id"]


def summary(findings):
    return [{"code": f["code"], "class": f["class"], "unit": f["unit"]} for f in findings]


def cmd_render_verified(args):
    check_target(args.target)
    if not isinstance(args.budget, int) or args.budget < 0 or args.budget > MAX_REPAIR_BUDGET:
        raise core.RenderError("usage-error", f"--budget is a whole number from 0 to {MAX_REPAIR_BUDGET}", "usage",
                               "--budget", status=2)
    if not args.generated_at or not SAFE_FIXED_TIME.match(args.generated_at) or not args.run_id:
        raise core.RenderError("usage-error", "render-verified needs a fixed --generated-at (YYYY-MM-DDTHH:MM:SSZ) and "
                               "--run-id, so every attempt is reproducible", "usage", "--generated-at", status=2)
    brief, original, library = load_inputs(args)
    fingerprint = core.validator.content_fingerprint(brief)
    unit_ids = [unit["id"] for unit in original["units"]]
    out = Path(args.out).absolute()
    out.parent.mkdir(parents=True, exist_ok=True)
    work = Path(tempfile.mkdtemp(prefix=f".{out.name}.verify.", dir=out.parent))
    # A unit's own variant already failed or is still in use, so it is never offered back as a repair.
    history, tried, used = [], {(unit["id"], unit["variant"]) for unit in original["units"]}, 0
    current = original
    try:
        while True:
            directory = work / f"attempt-{len(history)}"
            directory.mkdir()
            verdict, findings, report = attempt(args, current, directory)
            history.append({"attempt": len(history), "changes": changes_of(original, current),
                            "composition_sha256": checks.sha256(dump(current)), "verdict": verdict,
                            "findings": summary(findings)})
            if verdict == "pass":
                return finish(out, directory, current, report, history, used, fingerprint, unit_ids, args)
            unit_id = failing_unit(findings, current)
            stop = None
            while stop is None:
                if unit_id is None:
                    stop = "no-repairable-unit"
                    break
                if not budget_left(used, args.budget):
                    stop = "budget-exhausted"
                    break
                variant = next(candidates(current, unit_id, library, tried), None)
                if variant is None:
                    stop = "no-eligible-repair"
                    break
                tried.add((unit_id, variant))
                used += 1
                repaired = copy.deepcopy(current)
                for unit in repaired["units"]:
                    if unit["id"] == unit_id:
                        unit["variant"] = variant
                try:
                    core.validator.check_repair(brief, original, repaired, library)
                except core.validator.ContractError as exc:
                    history.append({"attempt": len(history), "changes": changes_of(original, repaired),
                                    "composition_sha256": checks.sha256(dump(repaired)), "verdict": "refused",
                                    "findings": [{"code": exc.finding.get("code"), "class": None, "unit": unit_id}]})
                    continue
                current = repaired
                break
            if stop is not None:
                data = {"target": args.target, "budget": args.budget, "repairs_used": used, "stopped": stop,
                        "content_fingerprint": {"frozen": fingerprint, "before": fingerprint,
                                                "after": current["normalized_brief_ref"]["content_fingerprint"]},
                        "units": {"before": unit_ids, "after": [unit["id"] for unit in current["units"]]},
                        "findings": findings, "history": history}
                raise failed("repair-exhausted", "repair", data, f"verification still fails after {used} repair(s): "
                             f"{stop}")
    finally:
        shutil.rmtree(work, ignore_errors=True)


def changes_of(original, current):
    return [{"unit": old["id"], "before": f"{old['pattern']}/{old['variant']}", "after": f"{new['pattern']}/{new['variant']}"}
            for old, new in zip(original["units"], current["units"])
            if (old["pattern"], old["variant"]) != (new["pattern"], new["variant"])]


def finish(out, directory, composition, report, history, used, fingerprint, unit_ids, args):
    """Move the passing attempt's outputs into place, with the composition it rendered, its report and the
    repair history, and only then report success."""
    files = sorted(os.listdir(directory / "out"))
    out.mkdir(exist_ok=True)
    for name in files:
        os.replace(directory / "out" / name, out / name)
    os.replace(directory / "composition.json", out / "composition.json")
    (out / "verification.json").write_bytes(dump(report))
    record = {"budget": args.budget, "repairs_used": used, "history": history,
              "content_fingerprint": {"frozen": fingerprint,
                                      "after": composition["normalized_brief_ref"]["content_fingerprint"]},
              "units": {"before": unit_ids, "after": [unit["id"] for unit in composition["units"]]}}
    (out / "repair-history.json").write_bytes(dump(record))
    return {"target": args.target, "out": str(out), "verdict": "pass", "artifact": str(out / ARTIFACTS[args.target]),
            "composition": str(out / "composition.json"), "verification": str(out / "verification.json"),
            "repair_history": str(out / "repair-history.json"), "budget": args.budget,
            "repairs_used": record["repairs_used"], "changes": history[-1]["changes"],
            "content_fingerprint": record["content_fingerprint"]}


# --- the parser ---------------------------------------------------------------------------------------

def inputs(parser, target=True, theme=False, artifact=True):
    if target:
        parser.add_argument("--target", required=True)
    parser.add_argument("--brief", required=True)
    parser.add_argument("--composition", required=True)
    if artifact:
        parser.add_argument("--artifact", required=True, help="the rendered index.html or deck.pptx")
    if theme:
        parser.add_argument("--theme", required=True, help="the theme directory the output was rendered with")


def build_parser():
    top = Parser(prog="design-verify.py", description=__doc__.splitlines()[0])
    commands = top.add_subparsers(dest="command", required=True)
    inputs(commands.add_parser("preserve", help="compare every content family with the frozen brief"))
    edit = commands.add_parser("editability", help="object-level editability and edit witnesses of a deck")
    inputs(edit, target=False, artifact=False)
    edit.add_argument("--pptx", required=True)
    access = commands.add_parser("accessibility", help="grade the target's declared accessibility capabilities")
    inputs(access, theme=True)
    access.add_argument("--capabilities", default=str(DEFAULT_CAPABILITIES))
    geo = commands.add_parser("geometry", help="clipping, overlap, missing glyphs and misleading encodings")
    inputs(geo, theme=True)
    geo.add_argument("--browser-report")
    verify = commands.add_parser("verify", help="the full verification report for one output")
    inputs(verify, theme=True)
    verify.add_argument("--manifest", help="the deck's pptx-manifest.json")
    verify.add_argument("--review", help="a visual review record to fold in")
    verify.add_argument("--browser-report", help="a design-render measure report to fold in")
    verify.add_argument("--capabilities", default=str(DEFAULT_CAPABILITIES))
    verify.add_argument("--out", help="write the report here")
    review = commands.add_parser("check-review", help="check a visual review record against a proof")
    review.add_argument("--record", required=True)
    review.add_argument("--proof", required=True)
    spec = commands.add_parser("check-specimens", help="check a specimen index against a proof")
    spec.add_argument("--index", required=True)
    spec.add_argument("--proof", required=True)
    proof = commands.add_parser("check-proof", help="recompute and check a proof manifest")
    proof.add_argument("--manifest", required=True)
    loop = commands.add_parser("render-verified", help="render, verify, and repair within a finite budget")
    inputs(loop, theme=True, artifact=False)
    loop.add_argument("--out", required=True)
    loop.add_argument("--budget", type=int, default=DEFAULT_REPAIR_BUDGET)
    loop.add_argument("--language")
    loop.add_argument("--generated-at")
    loop.add_argument("--run-id")
    loop.add_argument("--capabilities", default=str(DEFAULT_CAPABILITIES))
    return top


COMMANDS = {"preserve": cmd_preserve, "editability": cmd_editability, "accessibility": cmd_accessibility,
            "geometry": cmd_geometry, "verify": cmd_verify, "check-review": cmd_check_review,
            "check-specimens": cmd_check_specimens, "check-proof": cmd_check_proof,
            "render-verified": cmd_render_verified}


def main(argv=None):
    try:
        args = build_parser().parse_args(argv)
        data = COMMANDS[args.command](args)
    except core.RenderError as exc:
        print(json.dumps(envelope(False, exc.finding, str(exc)), ensure_ascii=False))
        return exc.status
    except Exception as exc:  # a runtime fault still answers with one envelope, never a traceback
        print(json.dumps(envelope(False, {"code": "runtime-error"}, f"{type(exc).__name__}: {exc}"), ensure_ascii=False))
        return 2
    print(json.dumps(envelope(True, data, None), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""design-render: lay a validated semantic-composition@2 out for a target and render it.

Stdlib only. Every invocation prints exactly one JSON envelope, {"success", "data", "error"}, on stdout
and nothing on stderr; exit 0 on success, 1 on a contract or fidelity finding, 2 on a usage or runtime
problem. A rejection writes nothing.

Commands:
  render --target html   brief + composition + theme -> target-plan.json, index.html, provenance.json
                         (--measure adds browser-report.json from the pinned measurement runtime)
  render --target pptx   brief + composition + theme -> target-plan.json, deck.pptx, pptx-manifest.json,
                         provenance.json (an editable deck written straight from the plan, never via HTML)
  check-html             the fidelity checks over a rendered page
  check-pptx             the package and fidelity checks over a rendered deck
  check-provenance       font, fingerprint, pin and output-digest checks over a provenance record
  compare                two plans (or measurement reports), ignoring only the declared volatile fields
  check-runtime-lock     the runtime manifest and lockfile pin every package exactly
  measure                an offline browser load of a rendered page through the pinned runtime

Rendering either target needs no Node, browser, network, model API or cogni-workspace. The measurement
runtime is resolved only from its provisioned record under --runtime-root (default: runtime/ beside
this plugin's scripts), never from PATH, and is provisioned only by runtime/provision.sh — this
wrapper never installs anything. references/design-render.md is the normative description.
"""

import argparse
import datetime
import json
import os
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).absolute().parent))

import html_adapter  # noqa: E402
import pptx_adapter  # noqa: E402
import pptx_checks  # noqa: E402
import render_checks  # noqa: E402
import render_core as core  # noqa: E402

TARGETS = ("html", "pptx")
OUTPUTS = {"html": ("target-plan.json", "index.html", "provenance.json"),
           "pptx": ("target-plan.json", pptx_adapter.ARTIFACT, pptx_adapter.MANIFEST, "provenance.json")}
PROVISION = core.RUNTIME_DIR / "provision.sh"


class Parser(argparse.ArgumentParser):
    def error(self, message):
        raise core.RenderError("usage-error", message, "usage", status=2)


def envelope(success, data, error):
    return {"success": success, "data": data, "error": error}


def dump(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def findings_error(findings, check):
    first = findings[0]
    error = core.RenderError(first["code"], first["message"], first["check"], first["reference"])
    error.finding = {"code": first["code"], "check": first["check"], "reference": first["reference"],
                     "findings": findings}
    return error


# --- the measurement runtime --------------------------------------------------------------------------

def runtime_missing(root, reason):
    pin = core.runtime_pin()["dependencies"]
    pins = ", ".join(f"{name}@{version}" for name, version in pin.items())
    return core.RenderError(
        "runtime-missing",
        f"the pinned HTML measurement runtime is not available at {root}: {reason}. Provision it once, outside "
        f"any render, with `bash {PROVISION}` — it installs {pins} from runtime/package-lock.json and the "
        "Chromium build that version pins. Rendering without --measure needs no runtime.",
        "runtime", str(root), status=2)


def locate_runtime(root):
    """The provisioned runtime, verified against the committed pin, or an actionable failure."""
    root = Path(root).absolute()
    record_path = root / ".provisioned.json"
    if not record_path.is_file():
        raise runtime_missing(root, "no provisioning record")
    try:
        record = json.loads(record_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise runtime_missing(root, f"the provisioning record is unreadable ({exc})") from exc
    pin = core.runtime_pin()
    if record.get("lock_sha256") != pin["lock_sha256"]:
        raise core.RenderError("runtime-unpinned", f"the runtime at {root} was provisioned from a different lockfile; "
                               f"re-run `bash {PROVISION}`", "runtime-pin", str(root), status=2)
    node = Path(str(record.get("node_path", "")))
    browsers = root / "browsers"
    package = root / "node_modules" / "playwright-core" / "package.json"
    if not node.is_absolute() or not node.is_file() or not browsers.is_dir() or not package.is_file():
        raise runtime_missing(root, "the provisioned interpreter, package or browser build is gone")
    installed = json.loads(package.read_text(encoding="utf-8")).get("version")
    if installed != pin["dependencies"].get("playwright-core"):
        raise core.RenderError("runtime-unpinned", f"playwright-core {installed} is installed, the pin is "
                               f"{pin['dependencies'].get('playwright-core')}; re-run `bash {PROVISION}`",
                               "runtime-pin", str(root), status=2)
    probe = subprocess.run([str(node), "--version"], capture_output=True, text=True, env={}, timeout=30)
    if probe.returncode != 0 or probe.stdout.strip() != record.get("node_version"):
        raise core.RenderError("runtime-unpinned", f"the provisioned interpreter now reports "
                               f"{probe.stdout.strip() or 'nothing'}, not {record.get('node_version')}; re-run "
                               f"`bash {PROVISION}`", "runtime-pin", str(root), status=2)
    return {"root": root, "node": node, "browsers": browsers, "node_version": record["node_version"],
            "playwright_core": installed}


def run_measure(runtime, html_path):
    with tempfile.TemporaryDirectory() as home:
        proc = subprocess.run(
            [str(runtime["node"]), str(core.RUNTIME_DIR / "measure.mjs"), str(runtime["root"]), str(html_path),
             str(core.CANVAS["width"]), str(core.CANVAS["height"])],
            capture_output=True, text=True, timeout=300,
            env={"PLAYWRIGHT_BROWSERS_PATH": str(runtime["browsers"]), "HOME": home})
    if proc.returncode != 0:
        raise core.RenderError("measure-failed", f"the measurement runtime exited {proc.returncode}: "
                               f"{proc.stderr.strip()[-400:]}", "measure", str(html_path), status=2)
    try:
        report = json.loads(proc.stdout)
    except json.JSONDecodeError as exc:
        raise core.RenderError("measure-failed", f"the measurement runtime printed no report: {exc}", "measure",
                               str(html_path), status=2) from exc
    report["runtime"] = {"node_version": runtime["node_version"], "playwright_core": runtime["playwright_core"]}
    return report


def measurement_summary(report):
    return {"requests_blocked": report["requests"]["blocked"], "requests_failed": report["requests"]["failed"],
            "clipped": report["clipped"], "platform_fonts": report["platform_fonts"],
            "browser_version": report["browser_version"], "report": "browser-report.json"}


# --- commands ---------------------------------------------------------------------------------------

def cmd_render(args):
    if args.target not in TARGETS:
        raise core.RenderError("unsupported-target", f"design-render renders {', '.join(TARGETS)}; {args.target!r} is "
                               "not a target this renderer owns", "target", args.target)
    if args.target == "pptx" and args.measure:
        raise core.RenderError("usage-error", "--measure loads a page in the browser runtime and applies to the html "
                               "target only; a deck is graded by check-pptx", "usage", "--measure", status=2)
    brief = core.read_json(args.brief, "normalized_brief")
    composition = core.read_json(args.composition, "semantic_composition")
    library, _ = core.validate_inputs(brief, composition)
    if args.target not in composition["targets"]:
        raise core.RenderError("unsupported-capability", f"the composition does not request the {args.target} target",
                               "target", args.target, artifact="semantic_composition")
    families = {pattern["id"]: pattern["family"] for pattern in library["patterns"]}
    registers = [i for i, unit in enumerate(composition["units"]) if families[unit["pattern"]] == "register"]
    if registers and registers[-1] != len(composition["units"]) - 1:
        raise core.RenderError("register-not-last", "the source register must be the last unit in reading order",
                               "register-order", composition["units"][registers[-1]]["id"],
                               artifact="semantic_composition")
    theme = core.resolve_theme(args.theme, composition["design_system"])
    # Only a page embeds a face the theme ships; a deck embeds no font, so there it is skipped and recorded.
    fonts, copy_font = core.resolve_fonts(theme, embed_faces=args.target == "html")
    runtime = locate_runtime(args.runtime_root) if args.measure else None
    language = core.language_of(brief, args.language)
    generated_at = args.generated_at or datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    run_id = args.run_id or uuid.uuid4().hex

    plan = core.build_plan(brief, composition, library, theme, copy_font, generated_at, run_id, args.target)
    core.check_plan(brief, composition, plan, library)
    if args.target == "pptx":
        return render_pptx(args, brief, composition, library, theme, fonts, copy_font, language, plan,
                           generated_at, run_id)
    page = html_adapter.render(brief, composition, plan, theme, copy_font, language,
                               core.embedded_faces(theme, copy_font))
    problems = render_checks.check_html(page, brief, composition, theme)
    if problems:
        raise findings_error(problems, "fidelity")

    out = Path(args.out).absolute()
    out.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=f".{out.name}.", dir=out.parent))
    try:
        plan_bytes, page_bytes = dump(plan), page.encode("utf-8")
        (staging / "target-plan.json").write_bytes(plan_bytes)
        (staging / "index.html").write_bytes(page_bytes)
        measurement = None
        if runtime is not None:
            report = run_measure(runtime, staging / "index.html")
            (staging / "browser-report.json").write_bytes(dump(report))
            measurement = measurement_summary(report)
        provenance = core.build_provenance(brief, composition, library, theme, fonts, plan_bytes, page_bytes,
                                           language, generated_at, run_id, measurement, args.target)
        (staging / "provenance.json").write_bytes(dump(provenance))
        out.mkdir(exist_ok=True)
        for name in sorted(os.listdir(staging)):
            os.replace(staging / name, out / name)
    finally:
        shutil.rmtree(staging, ignore_errors=True)
    missing = [name for name in OUTPUTS["html"] if not (out / name).is_file()]
    if missing:
        raise core.RenderError("render-incomplete", f"the render did not leave {', '.join(missing)} in {out}",
                               "outputs", missing[0], status=2)
    data = {"target": args.target, "out": str(out),
            "target_plan": str(out / "target-plan.json"), "artifact": str(out / "index.html"),
            "provenance": str(out / "provenance.json"), "units": len(plan["units"]),
            "content_fingerprint": plan["normalized_brief_ref"]["content_fingerprint"],
            "fonts": [core.font_record(font) for font in fonts], "layout_face": copy_font["resolved_face"],
            "fidelity": "passed"}
    if runtime is not None:
        data["browser_report"] = str(out / "browser-report.json")
        data["measurement"] = measurement
    return data


def write_outputs(out, files):
    """Stage every output beside the destination and move them in only once all are written."""
    out.parent.mkdir(parents=True, exist_ok=True)
    staging = Path(tempfile.mkdtemp(prefix=f".{out.name}.", dir=out.parent))
    try:
        for name, payload in files:
            (staging / name).write_bytes(payload)
        out.mkdir(exist_ok=True)
        for name in sorted(os.listdir(staging)):
            os.replace(staging / name, out / name)
    finally:
        shutil.rmtree(staging, ignore_errors=True)


def render_pptx(args, brief, composition, library, theme, fonts, copy_font, language, plan, generated_at, run_id):
    """The PPTX branch: fit and content guards, the OOXML writer, the independent package checks on its
    own output, and only then the write. It never calls the HTML adapter and never produces HTML."""
    pptx_adapter.check_content(brief, composition)
    pptx_adapter.check_fit(brief, composition, plan, theme, copy_font, library)
    deck, manifest = pptx_adapter.render(brief, composition, plan, theme, copy_font, fonts, language, library,
                                         generated_at, run_id)
    problems = pptx_checks.check_pptx(deck, brief, composition, theme, manifest)
    if problems:
        raise findings_error(problems, "fidelity")
    out = Path(args.out).absolute()
    plan_bytes, manifest_bytes = dump(plan), dump(manifest)
    provenance = core.build_provenance(brief, composition, library, theme, fonts, plan_bytes, deck, language,
                                       generated_at, run_id, None, "pptx", artifact_name=pptx_adapter.ARTIFACT,
                                       extra_outputs={"manifest": (pptx_adapter.MANIFEST, manifest_bytes)})
    write_outputs(out, [("target-plan.json", plan_bytes), (pptx_adapter.ARTIFACT, deck),
                        (pptx_adapter.MANIFEST, manifest_bytes), ("provenance.json", dump(provenance))])
    missing = [name for name in OUTPUTS["pptx"] if not (out / name).is_file()]
    if missing:
        raise core.RenderError("render-incomplete", f"the render did not leave {', '.join(missing)} in {out}",
                               "outputs", missing[0], status=2)
    objects = [item for slide in manifest["slides"] for item in slide["objects"]]
    return {"target": "pptx", "out": str(out),
            "target_plan": str(out / "target-plan.json"), "artifact": str(out / pptx_adapter.ARTIFACT),
            "manifest": str(out / pptx_adapter.MANIFEST), "provenance": str(out / "provenance.json"),
            "units": len(plan["units"]), "slides": len(manifest["slides"]),
            "content_fingerprint": plan["normalized_brief_ref"]["content_fingerprint"],
            "fonts": manifest["fonts"], "layout_face": copy_font["resolved_face"],
            "objects": len(objects), "editable_objects": sum(1 for item in objects if item["editable"]),
            "fallbacks": len(manifest["fallbacks"]), "package_sha256": manifest["package"]["sha256"],
            "fidelity": "passed"}


def cmd_check_pptx(args):
    brief = core.read_json(args.brief, "normalized_brief")
    composition = core.read_json(args.composition, "semantic_composition")
    core.validate_inputs(brief, composition)
    theme = core.resolve_theme(args.theme, composition["design_system"]) if args.theme else None
    manifest = core.read_json(args.manifest, "pptx_manifest") if args.manifest else None
    try:
        deck = Path(args.pptx).read_bytes()
    except OSError as exc:
        raise core.RenderError("runtime-error", f"cannot read {args.pptx}: {exc}", "input", status=2) from exc
    problems = pptx_checks.check_pptx(deck, brief, composition, theme, manifest)
    if problems:
        raise findings_error(problems, "check-pptx")
    return {"valid": True, "slides": pptx_checks.slide_count(deck), "manifest_checked": manifest is not None,
            "tokens_checked": theme is not None}


def cmd_check_html(args):
    brief = core.read_json(args.brief, "normalized_brief")
    composition = core.read_json(args.composition, "semantic_composition")
    core.validate_inputs(brief, composition)
    theme = core.resolve_theme(args.theme, composition["design_system"]) if args.theme else None
    try:
        page = Path(args.html).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise core.RenderError("runtime-error", f"cannot read {args.html}: {exc}", "input", status=2) from exc
    problems = render_checks.check_html(page, brief, composition, theme)
    if problems:
        raise findings_error(problems, "check-html")
    return {"valid": True, "copy_keys": len(render_checks.expected_copy(brief, composition)),
            "tokens_checked": theme is not None}


def cmd_check_provenance(args):
    provenance = core.read_json(args.provenance, "provenance")
    composition = core.read_json(args.composition, "semantic_composition") if args.composition else None
    plan = core.read_json(args.plan, "target_plan") if args.plan else None
    problems = render_checks.check_provenance(provenance, composition, plan, args.out_dir)
    manifest_output = (provenance.get("outputs") or {}).get("manifest") if isinstance(provenance, dict) else None
    if args.out_dir is not None and isinstance(manifest_output, dict):
        manifest_path = Path(args.out_dir) / str(manifest_output.get("path", ""))
        if manifest_path.is_file():
            manifest = core.read_json(manifest_path, "pptx_manifest")
            problems += pptx_checks.check_manifest_identity(manifest, provenance)
    if problems:
        raise findings_error(problems, "check-provenance")
    return {"valid": True, "fonts": len(provenance["fonts"]), "layout_face": provenance["layout_face"]}


def cmd_compare(args):
    expected = core.read_json(args.expected, "expected")
    actual = core.read_json(args.actual, "actual")
    differences = render_checks.compare(expected, actual, args.tolerance)
    if args.expected_html and args.actual_html:
        a = render_checks.copy_sequence(Path(args.expected_html).read_text(encoding="utf-8"))
        b = render_checks.copy_sequence(Path(args.actual_html).read_text(encoding="utf-8"))
        if a != b:
            differences.append({"path": "html:data-copy", "expected": len(a), "actual": len(b)})
    if differences:
        error = core.RenderError("plan-drift", f"{len(differences)} material difference(s), first at "
                                 f"{differences[0]['path']}", "compare", differences[0]["path"])
        error.finding["differences"] = differences
        raise error
    return {"equal": True, "tolerance_px": args.tolerance, "ignored": list(core.VOLATILE_FIELDS)}


def cmd_check_runtime_lock(args):
    problems = render_checks.check_runtime_lock(args.runtime_dir)
    if problems:
        raise findings_error(problems, "check-runtime-lock")
    return {"valid": True, "pin": core.runtime_pin()["dependencies"]}


def cmd_measure(args):
    runtime = locate_runtime(args.runtime_root)
    html_path = Path(args.html).absolute()
    if not html_path.is_file():
        raise core.RenderError("runtime-error", f"no page at {html_path}", "input", status=2)
    report = run_measure(runtime, html_path)
    Path(args.out).write_bytes(dump(report))
    return dict(measurement_summary(report), report=str(Path(args.out).absolute()))


def build_parser():
    top = Parser(prog="design-render.py", description=__doc__.splitlines()[0])
    commands = top.add_subparsers(dest="command", required=True)
    render = commands.add_parser("render", help="render a composition for a target")
    render.add_argument("--target", required=True)
    render.add_argument("--brief", required=True)
    render.add_argument("--composition", required=True)
    render.add_argument("--theme", required=True, help="a theme directory or its theme.md")
    render.add_argument("--out", required=True)
    render.add_argument("--language")
    render.add_argument("--measure", action="store_true")
    render.add_argument("--runtime-root", default=str(core.RUNTIME_DIR))
    render.add_argument("--generated-at")
    render.add_argument("--run-id")
    html = commands.add_parser("check-html", help="run the fidelity checks over a rendered page")
    html.add_argument("--brief", required=True)
    html.add_argument("--composition", required=True)
    html.add_argument("--html", required=True)
    html.add_argument("--theme")
    pptx = commands.add_parser("check-pptx", help="run the package and fidelity checks over a rendered deck")
    pptx.add_argument("--brief", required=True)
    pptx.add_argument("--composition", required=True)
    pptx.add_argument("--pptx", required=True)
    pptx.add_argument("--manifest")
    pptx.add_argument("--theme")
    prov = commands.add_parser("check-provenance", help="check a render provenance record")
    prov.add_argument("--provenance", required=True)
    prov.add_argument("--composition")
    prov.add_argument("--plan")
    prov.add_argument("--out-dir")
    comp = commands.add_parser("compare", help="compare two plans or measurement reports")
    comp.add_argument("--expected", required=True)
    comp.add_argument("--actual", required=True)
    comp.add_argument("--tolerance", type=float, default=render_checks.DEFAULT_TOLERANCE)
    comp.add_argument("--expected-html")
    comp.add_argument("--actual-html")
    lock = commands.add_parser("check-runtime-lock", help="check the runtime manifest and lockfile")
    lock.add_argument("--runtime-dir", default=str(core.RUNTIME_DIR))
    measure = commands.add_parser("measure", help="measure a rendered page in the pinned runtime")
    measure.add_argument("--html", required=True)
    measure.add_argument("--out", required=True)
    measure.add_argument("--runtime-root", default=str(core.RUNTIME_DIR))
    return top


COMMANDS = {"render": cmd_render, "check-html": cmd_check_html, "check-pptx": cmd_check_pptx,
            "check-provenance": cmd_check_provenance,
            "compare": cmd_compare, "check-runtime-lock": cmd_check_runtime_lock, "measure": cmd_measure}


def main(argv=None):
    try:
        args = build_parser().parse_args(argv)
        data = COMMANDS[args.command](args)
    except core.RenderError as exc:
        print(json.dumps(envelope(False, exc.finding, str(exc)), ensure_ascii=False))
        return exc.status
    except subprocess.TimeoutExpired as exc:
        print(json.dumps(envelope(False, {"code": "runtime-error"}, f"the runtime timed out: {exc}"), ensure_ascii=False))
        return 2
    except Exception as exc:  # a runtime fault still answers with one envelope, never a traceback
        print(json.dumps(envelope(False, {"code": "runtime-error"}, f"{type(exc).__name__}: {exc}"), ensure_ascii=False))
        return 2
    print(json.dumps(envelope(True, data, None), ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())

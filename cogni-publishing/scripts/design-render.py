#!/usr/bin/env python3
"""design-render: host presentation bridge, independent admission and pinned browser measurement.

Rendering requires an explicitly supplied host bridge. Without one, return
platform_renderer_unavailable and write nothing. Validation and verification
remain Python standard-library operations. No renderer is installed or selected by this CLI.
"""

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).absolute().parent))

import render_core as core  # noqa: E402

TARGETS = ("html", "pptx")
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
        "Chromium build that version pins. Platform rendering does not use this measurement runtime.",
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


def cmd_check_provenance(args):
    provenance = core.read_json(args.provenance, "provenance")
    composition = core.read_json(args.composition, "semantic_composition") if args.composition else None
    renderer = provenance.get("renderer") if isinstance(provenance, dict) else None
    if isinstance(renderer, dict) and renderer.get("kind") == "platform":
        problems = []
        digest = re.compile(r"^sha256:[0-9a-f]{64}$")
        base = Path(args.out_dir) if args.out_dir else Path(args.provenance).parent

        def issue(code, name, message):
            problems.append({"code": code, "check": "provenance", "artifact": name, "reference": name, "message": message})

        def nonempty(value):
            return isinstance(value, str) and bool(value.strip())

        def file_record(value, name):
            if (not isinstance(value, dict) or not nonempty(value.get("path"))
                    or not digest.fullmatch(str(value.get("sha256", "")))):
                issue("platform-evidence-missing", name, "file evidence needs a path and sha256 digest")
                return None
            path = base / value["path"]
            if args.out_dir is not None:
                if not path.is_file() or core.sha256_file(path) != value["sha256"]:
                    issue("output-digest", name, "evidence file does not match its recorded digest")
                    return None
            return path

        if (provenance.get("artifact_type") != "render-provenance" or provenance.get("artifact_version") != "1"
                or not nonempty(provenance.get("artifact_id"))):
            issue("invalid-artifact", "artifact_type", "not an identified render-provenance@1 record")
        if (not all(nonempty(renderer.get(k)) for k in ("name", "host"))
                or not any(nonempty(renderer.get(k)) for k in ("version", "marketplace_commit"))
                or renderer.get("target") not in TARGETS):
            issue("renderer-unrecorded", "renderer", "renderer needs host, name, version-or-marketplace-commit and target")
        live = provenance.get("live_proof")
        if not isinstance(live, bool):
            issue("platform-evidence-missing", "live_proof", "record whether this is live execution or offline admission")
        if renderer.get("name") == "test-platform-stub" and live is not False:
            issue("stub-labelled-live", "renderer", "the deterministic platform stub can never be live proof")
        if provenance.get("reproducible") is not False:
            issue("reproducibility-unrecorded", "reproducible", "platform renders record reproducible=false")
        fingerprint = provenance.get("content_fingerprint")
        if not digest.fullmatch(str(fingerprint or "")):
            issue("fingerprint-mismatch", "content_fingerprint", "platform provenance needs a sha256 fingerprint")
        design = provenance.get("design_system")
        if not isinstance(design, dict) or not all(nonempty(design.get(k)) for k in ("name", "version")):
            issue("design-system", "design_system", "design system needs its name and version")
        outputs = provenance.get("outputs")
        if not isinstance(outputs, dict) or "artifact" not in outputs:
            issue("output-digest", "outputs", "platform provenance needs its artifact output")
        else:
            for name, output in outputs.items():
                file_record(output, "outputs." + name)
        inputs = provenance.get("inputs")
        input_paths = {}
        if not isinstance(inputs, dict) or not all(k in inputs for k in ("brief", "composition", "theme")):
            issue("platform-evidence-missing", "inputs", "inputs need brief, composition and theme file evidence")
        if isinstance(inputs, dict):
            input_paths = {key: file_record(value, "inputs." + key) for key, value in inputs.items()}
        run = provenance.get("run")
        if (not isinstance(run, dict) or not nonempty(run.get("id"))
                or run.get("host") != renderer.get("host") or run.get("skill") != renderer.get("name")
                or not isinstance(run.get("live"), bool) or run.get("live") is not live):
            issue("platform-evidence-missing", "run", "run identity must match renderer host, skill and live-proof status")
        if isinstance(run, dict):
            execution_path = file_record(run.get("evidence"), "run.evidence")
            if args.out_dir is not None and execution_path is not None:
                try:
                    execution = json.loads(execution_path.read_text(encoding="utf-8"))
                except (OSError, UnicodeError, ValueError):
                    execution = None
                if (not isinstance(execution, dict)
                        or execution.get("host") != run.get("host")
                        or execution.get("skill") != run.get("skill")
                        or not isinstance(execution.get("live"), bool)
                        or execution.get("live") is not run.get("live")):
                    issue("host-evidence-mismatch", "run.evidence",
                          "execution evidence must corroborate the recorded host, skill and live status")
        expected_units = None
        if args.out_dir is not None:
            frozen = input_paths.get("composition")
            if frozen is not None:
                recorded_composition = core.read_json(frozen, "semantic_composition")
                if composition is not None and recorded_composition != composition:
                    issue("input-differs", "inputs.composition", "frozen composition differs from the supplied composition")
                composition = recorded_composition
            brief_path = input_paths.get("brief")
            if brief_path is not None and composition is not None:
                brief = core.read_json(brief_path, "normalized_brief")
                core.validate_inputs(brief, composition)
        if composition is not None:
            expected_units = [unit["id"] for unit in composition["units"]]
            if fingerprint != composition["normalized_brief_ref"]["content_fingerprint"]:
                issue("fingerprint-mismatch", "content_fingerprint", "fingerprint differs from the frozen composition")
            if design != composition["design_system"]:
                issue("design-system", "design_system", "design system differs from the composition pin")
        attempts = provenance.get("attempts")
        if not isinstance(attempts, list) or not attempts:
            issue("platform-evidence-missing", "attempts", "record every attempt and its findings")
        else:
            for index, attempt in enumerate(attempts, 1):
                name = "attempts[{}]".format(index)
                if not isinstance(attempt, dict):
                    issue("platform-evidence-missing", name, "an attempt must be an object")
                    continue
                units = attempt.get("unit_ids_before")
                preserve = attempt.get("preserve")
                if (not isinstance(attempt.get("attempt"), int) or isinstance(attempt.get("attempt"), bool) or attempt["attempt"] != index
                        or not isinstance(attempt.get("findings"), list)
                        or not isinstance(preserve, dict) or not isinstance(preserve.get("differences"), list)):
                    issue("platform-evidence-missing", name, "attempts need consecutive numbers, findings and preserve differences")
                if (attempt.get("content_fingerprint_before") != fingerprint
                        or attempt.get("content_fingerprint_after") != fingerprint
                        or not isinstance(units, list) or not units or not all(nonempty(x) for x in units)
                        or attempt.get("unit_ids_after") != units
                        or (expected_units is not None and units != expected_units)):
                    issue("preservation-drift", name, "frozen fingerprints and ordered unit ids must stay unchanged")
            final = attempts[-1]
            if isinstance(final, dict):
                if final.get("findings") != []:
                    issue("open-findings", "attempts[-1]", "the admitted final attempt must have no open finding")
                if not isinstance(final.get("preserve"), dict) or final["preserve"].get("differences") != []:
                    issue("preservation-drift", "attempts[-1]", "the admitted final attempt needs an empty preserve diff")
        review = provenance.get("review")
        if not isinstance(review, dict):
            issue("review-incomplete", "review", "persist the visual review record")
        else:
            file_record(review, "review")
            coverage = review.get("coverage")
            if (review.get("open_findings") != [] or not isinstance(coverage, dict)
                    or not all(coverage.get(k) is True for k in ("all_units", "all_slides", "overview"))):
                issue("review-incomplete", "review", "review needs complete unit, slide and overview coverage with no finding")
        applicability = provenance.get("applicability")
        for key in ("theme", "fonts", "runtime"):
            record = applicability.get(key) if isinstance(applicability, dict) else None
            if (not isinstance(record, dict) or not isinstance(record.get("applicable"), bool)
                    or not nonempty(record.get("reason")) or not isinstance(record.get("evidence"), list)
                    or (record.get("applicable") and not record["evidence"])):
                issue("platform-evidence-missing", "applicability." + key, "state applicability, reason and applicable evidence")
                continue
            for index, evidence in enumerate(record["evidence"]):
                file_record(evidence, "applicability.{}[{}]".format(key, index))
        if problems:
            raise findings_error(problems, "check-provenance")
        return {"valid": True, "renderer_kind": "platform", "renderer": renderer["name"],
                "reproducible": False, "manifest_required": False, "live_proof": live}
    raise core.RenderError("renderer-retired", "only platform provenance is admitted", "provenance")


def runtime_finding(code, check, reference, message):
    return {"code": code, "check": check, "reference": reference, "message": message}


def check_runtime_lock(runtime_dir):
    """Every required package is pinned to an exact version and locked with a registry URL and a
    sha512 integrity hash; no install hook runs; the install directories stay ignored."""
    runtime_dir = Path(runtime_dir)
    out = []
    try:
        manifest = json.loads((runtime_dir / "package.json").read_text(encoding="utf-8"))
        lock = json.loads((runtime_dir / "package-lock.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        return [runtime_finding("lock-missing", "runtime-lock", str(runtime_dir), f"manifest or lockfile unreadable: {exc}")]
    deps = {}
    for key in ("dependencies", "optionalDependencies", "devDependencies", "peerDependencies"):
        deps.update(manifest.get(key) or {})
    if not deps:
        out.append(runtime_finding("lock-missing", "runtime-lock", "dependencies", "the manifest declares no dependency"))
    for name, version in deps.items():
        if not isinstance(version, str) or not re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$").match(version):
            out.append(runtime_finding("range-pin", "runtime-lock", name, f"{name} is pinned as {version!r}, not an exact x.y.z"))
    for hook in ("preinstall", "install", "postinstall", "prepare"):
        if hook in (manifest.get("scripts") or {}):
            out.append(runtime_finding("install-script", "runtime-lock", hook, f"the manifest runs a {hook} script"))
    packages = lock.get("packages")
    if not isinstance(lock.get("lockfileVersion"), int) or lock["lockfileVersion"] < 2 or not isinstance(packages, dict):
        return out + [runtime_finding("lock-missing", "runtime-lock", "package-lock.json", "the lockfile has no packages map")]
    root_deps = (packages.get("") or {}).get("dependencies") or {}
    if root_deps != (manifest.get("dependencies") or {}):
        out.append(runtime_finding("lock-mismatch", "runtime-lock", "dependencies", "the lockfile root does not mirror the manifest"))
    for name, version in deps.items():
        entry = packages.get(f"node_modules/{name}")
        if entry is None:
            out.append(runtime_finding("lock-missing", "runtime-lock", name, f"{name} is missing from the lockfile"))
        elif entry.get("version") != version:
            out.append(runtime_finding("lock-mismatch", "runtime-lock", name, f"{name} locks {entry.get('version')}, not {version}"))
    for path, entry in packages.items():
        if not path:
            continue
        if not str(entry.get("resolved", "")).startswith("https://registry.npmjs.org/") or not str(entry.get("integrity", "")).startswith("sha512-") \
                or not re.compile(r"^[0-9]+\.[0-9]+\.[0-9]+$").match(str(entry.get("version", ""))):
            out.append(runtime_finding("lock-unhashed", "runtime-lock", path,
                               f"{path} is not an exact, registry-resolved, sha512-hashed entry"))
    ignored = (runtime_dir / ".gitignore").read_text(encoding="utf-8").split() if (runtime_dir / ".gitignore").is_file() else []
    for pattern in ("node_modules/", "browsers/", ".provisioned.json"):
        if pattern not in ignored:
            out.append(runtime_finding("install-tracked", "runtime-lock", pattern, f"runtime/.gitignore does not ignore {pattern}"))
    return out


def cmd_check_runtime_lock(args):
    problems = check_runtime_lock(args.runtime_dir)
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


def cmd_render(args):
    """Invoke an explicit host bridge; this plugin has no built-in artifact writer."""
    raw = getattr(args, 'platform_command', None)
    if not raw:
        raise core.RenderError('platform_renderer_unavailable', 'platform_renderer_unavailable', 'render')
    try:
        command = json.loads(raw)
    except (TypeError, ValueError) as exc:
        raise core.RenderError('usage-error', '--platform-command must be a JSON argv array', 'usage', status=2) from exc
    if not isinstance(command, list) or not command or not all(isinstance(x, str) and x for x in command):
        raise core.RenderError('usage-error', '--platform-command must be a nonempty JSON argv array', 'usage', status=2)
    if args.target not in TARGETS:
        raise core.RenderError('unsupported-target', 'unsupported target', 'target', args.target)
    brief = core.read_json(args.brief, 'normalized_brief')
    composition = core.read_json(args.composition, 'semantic_composition')
    core.validate_inputs(brief, composition)
    core.resolve_theme(args.theme, composition['design_system'])
    destination = Path(args.out).absolute()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.platform-', dir=destination.parent) as scratch:
        output = Path(scratch) / 'output'
        invocation = command + ['--target', args.target, '--brief', str(Path(args.brief).absolute()),
                                '--composition', str(Path(args.composition).absolute()),
                                '--theme', str(Path(args.theme).absolute()), '--out', str(output),
                                '--attempt', str(getattr(args, 'attempt', 1))]
        findings_file = getattr(args, 'findings_file', None)
        if findings_file:
            invocation += ['--findings-file', str(Path(findings_file).absolute())]
        proc = subprocess.run(invocation, capture_output=True, text=True, timeout=300)
        try:
            reply = json.loads(proc.stdout)
        except ValueError as exc:
            raise core.RenderError('platform-render-failed', 'host bridge printed no JSON envelope', 'render') from exc
        if proc.returncode or not isinstance(reply, dict) or reply.get('success') is not True:
            error = core.RenderError('platform-render-failed', 'host bridge did not produce an admitted artifact', 'render')
            error.finding['findings'] = (reply.get('data') or {}).get('findings', []) if isinstance(reply, dict) else []
            raise error
        artifact = output / ('index.html' if args.target == 'html' else 'deck.pptx')
        if not artifact.is_file() or not (output / 'provenance.json').is_file():
            raise core.RenderError('platform-render-failed', 'host bridge omitted artifact or provenance', 'render')
        cmd_check_provenance(argparse.Namespace(provenance=str(output / 'provenance.json'),
                                               composition=args.composition, out_dir=str(output)))
        provenance = core.read_json(output / 'provenance.json', 'provenance')
        if (provenance['renderer']['target'] != args.target
                or (output / provenance['outputs']['artifact']['path']).resolve() != artifact.resolve()):
            raise core.RenderError('platform-render-failed', 'provenance names another target or artifact', 'render')
        verifier = core.load_script('cogni_publishing_independent_verify', 'design-verify.py')
        review_path = None
        if provenance.get('live_proof'):
            review_path = output / provenance['review']['path']
            review = core.read_json(review_path, 'review')
            review_findings = verifier.checks.check_review(review, [(composition['design_system']['name'], args.target,
                core.sha256_file(artifact), verifier.checks.review_units(args.target, artifact.read_bytes()))], review_path.parent)
            if review_findings:
                raise verifier.failed('review-incomplete', 'review', {'findings': review_findings}, 'host review is incomplete')
        verify_args = argparse.Namespace(target=args.target, brief=args.brief, composition=args.composition,
                                         theme=args.theme, artifact=str(artifact), manifest=None,
                                         capabilities=str(core.REFERENCES / 'verify-capabilities.json'),
                                         review=str(review_path) if review_path else None, browser_report=None, out=str(output / 'verification.json'))
        verifier.cmd_verify(verify_args)
        cmd_check_provenance(argparse.Namespace(provenance=str(output / 'provenance.json'),
                                               composition=args.composition, out_dir=str(output)))
        if (output / 'composition.json').exists() and core.read_json(output / 'composition.json', 'composition') != composition:
            raise core.RenderError('input-differs', 'reserved composition output differs from the frozen input', 'render')
        if destination.exists() and (not destination.is_dir() or any(destination.iterdir())):
            raise core.RenderError('output-exists', 'refusing to replace a nonempty output directory', 'output')
        destination.mkdir(exist_ok=True)
        for item in output.iterdir():
            shutil.move(str(item), str(destination / item.name))
    return {'target': args.target, 'artifact': str(destination / artifact.name),
            'provenance': str(destination / 'provenance.json'), 'verification': str(destination / 'verification.json')}


def build_parser():
    top = Parser(prog='design-render.py', description=__doc__.splitlines()[0])
    commands = top.add_subparsers(dest='command', required=True)
    render = commands.add_parser('render', help='invoke the explicitly supplied host rendering bridge')
    for key in ('target', 'brief', 'composition', 'theme', 'out'):
        render.add_argument('--' + key, required=True)
    render.add_argument('--platform-command', help='JSON argv array for the host bridge; no automatic fallback')
    render.add_argument('--attempt', type=int, default=1)
    render.add_argument('--findings-file')
    render.add_argument('--language')
    render.add_argument('--generated-at')
    render.add_argument('--run-id')
    prov = commands.add_parser('check-provenance', help='validate platform provenance and evidence digests')
    prov.add_argument('--provenance', required=True)
    prov.add_argument('--composition')
    prov.add_argument('--out-dir')
    lock = commands.add_parser('check-runtime-lock', help='validate the browser measurement runtime pin')
    lock.add_argument('--runtime-dir', default=str(core.RUNTIME_DIR))
    measure = commands.add_parser('measure', help='measure an artifact in the provisioned pinned browser')
    measure.add_argument('--html', required=True)
    measure.add_argument('--out', required=True)
    measure.add_argument('--runtime-root', default=str(core.RUNTIME_DIR))
    return top


COMMANDS = {"render": cmd_render, "check-provenance": cmd_check_provenance,
            "check-runtime-lock": cmd_check_runtime_lock, "measure": cmd_measure}


def main(argv=None):
    try:
        args = build_parser().parse_args(argv)
        data = COMMANDS[args.command](args)
    except core.RenderError as exc:
        if exc.finding.get("code") == "platform_renderer_unavailable":
            print(json.dumps({"success": False, "error": "platform_renderer_unavailable"}))
        else:
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

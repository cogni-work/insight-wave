#!/usr/bin/env python3
"""Promote portfolio-scan shadow candidates into the authoritative features/ set.

Two subcommands, shared JSON service envelope: {success, data, error}.

- `list --project-dir PATH`
    Walk research/scan-candidates/{COMPANY_SLUG}/*.json and return a compact
    pick-list payload grouped by company. Skips files that don't look like
    shadow candidates (missing _shadow_candidate: true).

- `promote --candidate PATH --features-dir PATH [--archive]`
    Read a candidate JSON, strip the diagnostic fields
    (`_shadow_candidate`, `_source_offering`), write the cleaned object to
    features/{slug}.json, and either delete the source (default) or move it
    to a sibling .archive/ directory when --archive is passed.

Stdlib only. Bash 3.2-safe from the caller's perspective (no shell-specific
flags are emitted).
"""

import argparse
import json
import os
import shutil
import sys


DIAGNOSTIC_FIELDS = ("_shadow_candidate", "_source_offering")


def _respond(success, data=None, error=None, exit_code=None):
    """Emit the JSON service envelope on stdout and exit."""
    payload = {"success": bool(success)}
    if data is not None:
        payload["data"] = data
    if error is not None:
        payload["error"] = error
    sys.stdout.write(json.dumps(payload))
    sys.stdout.write("\n")
    if exit_code is None:
        exit_code = 0 if success else 1
    sys.exit(exit_code)


def _load_json(path):
    """Best-effort JSON load. Returns (data, error_message)."""
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return json.load(fh), None
    except FileNotFoundError:
        return None, "file not found"
    except json.JSONDecodeError as exc:
        return None, f"malformed JSON: {exc}"
    except OSError as exc:
        return None, f"read error: {exc}"


def cmd_list(args):
    """List shadow candidates grouped by company.

    Skips files that don't declare _shadow_candidate: true — dropping a
    non-shadow JSON into features/ untouched would be unsafe, and the
    workflow depends on the marker to distinguish candidates from other
    JSON noise in research/.
    """
    root = os.path.join(args.project_dir, "research", "scan-candidates")
    if not os.path.isdir(root):
        _respond(True, {"candidates_by_company": {}, "total": 0})

    by_company = {}
    total = 0
    skipped_non_shadow = []
    skipped_malformed = []

    try:
        companies = sorted(os.listdir(root))
    except OSError as exc:
        _respond(False, error=f"listdir failed: {exc}")

    for company_slug in companies:
        company_path = os.path.join(root, company_slug)
        if not os.path.isdir(company_path):
            continue
        # Skip .archive/ — those are already-promoted candidates, not
        # pending ones.
        if company_slug.startswith("."):
            continue

        candidates = []
        try:
            entries = sorted(os.listdir(company_path))
        except OSError:
            continue

        for fname in entries:
            if not fname.endswith(".json"):
                continue
            source_path = os.path.join(company_path, fname)
            raw, err = _load_json(source_path)
            if err:
                skipped_malformed.append({"path": source_path, "error": err})
                continue
            if not isinstance(raw, dict):
                skipped_malformed.append(
                    {"path": source_path, "error": "top-level is not an object"}
                )
                continue
            if raw.get("_shadow_candidate") is not True:
                skipped_non_shadow.append(source_path)
                continue

            candidates.append({
                "slug": raw.get("slug") or fname[:-5],
                "product_slug": raw.get("product_slug", ""),
                "name": raw.get("name", ""),
                "taxonomy_mapping": raw.get("taxonomy_mapping") or {},
                "source_path": source_path,
            })

        if candidates:
            by_company[company_slug] = candidates
            total += len(candidates)

    data = {"candidates_by_company": by_company, "total": total}
    if skipped_non_shadow:
        data["skipped_non_shadow"] = skipped_non_shadow
    if skipped_malformed:
        data["skipped_malformed"] = skipped_malformed
    _respond(True, data)


def cmd_promote(args):
    """Strip diagnostic fields, write to features/, remove or archive source."""
    raw, err = _load_json(args.candidate)
    if err:
        _respond(False, error=f"candidate JSON: {err}")
    if not isinstance(raw, dict):
        _respond(False, error="candidate JSON top-level is not an object")
    if raw.get("_shadow_candidate") is not True:
        _respond(
            False,
            error="candidate missing `_shadow_candidate: true` marker — refusing to promote",
        )

    slug = args.slug or raw.get("slug")
    if not slug:
        _respond(False, error="candidate has no `slug` and --slug was not provided")

    # Strip diagnostic fields — never touch the original file in memory beyond
    # this point, so the promote step is purely additive to features/.
    cleaned = {k: v for k, v in raw.items() if k not in DIAGNOSTIC_FIELDS}

    features_dir = args.features_dir
    try:
        os.makedirs(features_dir, exist_ok=True)
    except OSError as exc:
        _respond(False, error=f"cannot create features dir: {exc}")

    target_path = os.path.join(features_dir, f"{slug}.json")
    if os.path.exists(target_path) and not args.overwrite:
        _respond(
            False,
            error=f"target already exists: {target_path} (pass --overwrite to replace)",
        )

    try:
        with open(target_path, "w", encoding="utf-8") as fh:
            json.dump(cleaned, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
    except OSError as exc:
        _respond(False, error=f"write to features failed: {exc}")

    archived_to = None
    try:
        if args.archive:
            archive_dir = os.path.join(os.path.dirname(args.candidate), ".archive")
            os.makedirs(archive_dir, exist_ok=True)
            archived_to = os.path.join(archive_dir, os.path.basename(args.candidate))
            shutil.move(args.candidate, archived_to)
        else:
            os.remove(args.candidate)
    except OSError as exc:
        _respond(
            False,
            data={
                "feature_path": target_path,
                "archived_to": archived_to,
                "partial_success": True,
            },
            error=f"feature written but source cleanup failed: {exc}",
        )

    _respond(True, {
        "feature_path": target_path,
        "archived_to": archived_to,
        "slug": slug,
        "stripped_fields": list(DIAGNOSTIC_FIELDS),
    })


def build_parser():
    parser = argparse.ArgumentParser(
        description="Promote portfolio-scan shadow candidates into features/."
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("list", help="List shadow candidates grouped by company.")
    p_list.add_argument("--project-dir", required=True, help="Portfolio project root.")
    p_list.set_defaults(func=cmd_list)

    p_promote = sub.add_parser(
        "promote",
        help="Strip diagnostic fields, write to features/, remove or archive source.",
    )
    p_promote.add_argument("--candidate", required=True, help="Path to candidate JSON.")
    p_promote.add_argument(
        "--features-dir", required=True, help="Target features/ directory."
    )
    p_promote.add_argument(
        "--slug", default=None, help="Override slug (defaults to candidate's `slug`)."
    )
    p_promote.add_argument(
        "--archive",
        action="store_true",
        help="Move source to sibling .archive/ instead of deleting.",
    )
    p_promote.add_argument(
        "--overwrite",
        action="store_true",
        help="Allow overwriting an existing features/{slug}.json (default: error on collision).",
    )
    p_promote.set_defaults(func=cmd_promote)

    return parser


def main():
    args = build_parser().parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

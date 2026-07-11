#!/usr/bin/env python3
"""Render-time resolver for {{asm:id}} assumption placeholders.

Usage:
  python3 resolve-assumptions.py <engagement-dir> resolve <file> [--in-place]
      [--claims-file <path>]

Reads the engagement's assumptions.json registry (the single source of truth
for assumption values — see references/data-model.md) and replaces every
`{{asm:<suffix>}}` placeholder in the target file with the `value` of the
registry entry whose id is `asm-<suffix>`. Without --in-place the resolved
text is returned in the envelope (a dry-run); with it, the file is rewritten
atomically (temp file + rename) and each resolved assumption's `used_by[]`
in assumptions.json gains a reference edge for the citing file (derive-at-
write, deduped on the citer's engagement-relative path, so repeated renders
never duplicate an edge and an unchanged registry is never rewritten).
A dry-run stays fully read-only toward the registry and field.json. When a
cited claim-type assumption carries status "verified", the resolver also
READS (never writes) the workspace cogni-claims registry to check the
verified-evidence gate — see validate_provenance; --claims-file overrides
the default engagement-relative location ../../cogni-claims/claims.json.

Fail-loud contract: an unknown placeholder id, a malformed placeholder (an
{{...asm...}} token that does not match the strict form), a placeholder still
present after substitution (e.g. a registry value that itself embeds one), a
defective registry entry (missing/invalid id, missing/null value, duplicate
id), or a missing registry when placeholders exist all return success:false
with a data.failed_check discriminator and exit 1 — a placeholder is never
silently left in, and never silently dropped. All offenders are listed at
once so a consultant can fix every defect in one pass.

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
Stdlib-only.
"""

import argparse
import datetime
import json
import os
import re
import sys
import tempfile

PLACEHOLDER_RE = re.compile(r"\{\{asm:([a-z0-9][a-z0-9-]*)\}\}")
# Anything brace-wrapped that mentions "asm" but is not a strict match — a
# typo'd id (uppercase, underscore, spaces) must fail loud, never ship.
LOOSE_ASM_RE = re.compile(r"\{\{[^{}]*asm[^{}]*\}\}", re.IGNORECASE)
ID_RE = re.compile(r"^asm-[a-z0-9][a-z0-9-]*$")
ID_PREFIX = "asm-"

# Provenance typing (the trust model): a value's provenance_type bounds the
# verification status it may hold, so a guess never renders with the confidence
# of a sourced fact. The status ladder is ordered weakest-to-strongest.
PROVENANCE_TYPES = ("given", "estimate", "claim")
STATUS_LADDER = ("stated", "reviewed", "verified")
# Highest status each type may carry. `verified` (the top of the ladder) is
# reachable only by a claim-type assumption, and only through the cogni-claims
# verify path: the cap admits claim/verified structurally, but the
# verified-evidence gate in validate_provenance then requires citation.claim_id
# to resolve to a ClaimRecord whose own status is "verified" — so a hand-set
# verified without genuine claims evidence still fails loud. given/estimate
# remain hand-capped below verified unconditionally.
TYPE_STATUS_CAP = {"given": "stated", "estimate": "reviewed", "claim": "verified"}


def _emit(success, data, error):
    # ASCII-safe by default (ensure_ascii=True): the stdout envelope is machine
    # JSON, and a non-UTF-8 stdout (C locale / PYTHONIOENCODING=ascii on a CI
    # runner) would raise UnicodeEncodeError on a raw non-ASCII character. The
    # \uXXXX escapes round-trip losslessly for the consumer; readability of the
    # persisted files is handled separately (they are written UTF-8).
    print(json.dumps({"success": success, "data": data, "error": error}))
    sys.exit(0 if success else 1)


def _render_value(entry):
    """The substituted text for one assumption: its value plus, when the entry
    is provenance-typed, a per-number confidence marker.

    The marker is a parenthetical (never a `[...]` span), so it cannot form a
    spurious Markdown inline link when a template places `(` right after the
    placeholder, and it is brace-free so it can never re-form a `{{asm:…}}`
    placeholder and re-trigger the post-substitution leftover check. Untyped
    (legacy) entries render bare, so pre-provenance registries are unaffected.
    The marker wording is settled: the raw ``(prov: type/status)`` parenthetical
    is the finalized form — compact, link-safe, brace-free, and format-agnostic,
    so it renders identically inline and when a number is promoted to a hero
    figure. A promoted hero number carries this marker with it rather than
    dropping it, so provenance is never lost when a figure becomes a stat block.
    """
    value = str(entry["value"])
    ptype = entry.get("provenance_type")
    if not ptype:
        return value
    # status is guaranteed present + valid: a provenance-typed entry that
    # reached render already cleared the cap checks in _validate_provenance.
    return "%s (prov: %s/%s)" % (value, ptype, entry["status"])


def load_registry(engagement_dir):
    """Return {id: entry} from assumptions.json, failing loudly on any defect."""
    path = os.path.join(engagement_dir, "assumptions.json")
    if not os.path.isfile(path):
        _emit(False, {"failed_check": "registry_missing", "path": path},
              "assumptions.json not found at engagement root — placeholders exist "
              "but there is no registry to resolve them against (re-run "
              "engagement-init.sh to backfill an empty registry)")
    try:
        with open(path, encoding="utf-8") as f:
            raw = json.load(f)
    except (json.JSONDecodeError, OSError, UnicodeError) as exc:
        _emit(False, {"failed_check": "registry_unreadable", "path": path},
              "assumptions.json could not be read/parsed: %s" % exc)

    registry = {}
    bad_ids, missing_values, duplicates = [], [], []
    for entry in raw.get("assumptions", []):
        asm_id = entry.get("id")
        if not isinstance(asm_id, str) or not ID_RE.match(asm_id):
            bad_ids.append(repr(asm_id))
            continue
        if asm_id in registry:
            duplicates.append(asm_id)
        if entry.get("value") is None:
            missing_values.append(asm_id)
        registry[asm_id] = entry
    if bad_ids:
        _emit(False, {"failed_check": "invalid_assumption_id", "ids": sorted(set(bad_ids))},
              "registry entries with missing or malformed id (expected asm- + "
              "kebab-case slug): %s" % ", ".join(sorted(set(bad_ids))))
    if missing_values:
        _emit(False, {"failed_check": "missing_assumption_value", "ids": sorted(set(missing_values))},
              "registry entries missing a value (or value is null): %s"
              % ", ".join(sorted(set(missing_values))))
    if duplicates:
        _emit(False, {"failed_check": "duplicate_assumption_id", "ids": sorted(set(duplicates))},
              "duplicate assumption id(s) in registry — the single-source contract "
              "requires exactly one entry per id")
    return registry


def validate_provenance(registry, cited_ids, claims_file):
    """Fail loud if any *cited* assumption's provenance fields are inconsistent.

    Scoped to the ids the brief actually resolves — provenance typing is opt-in
    and per-value, so a mis-typed *uncited* assumption must never block a brief
    that does not render it (unlike the registry-integrity checks in
    load_registry, which fail on any malformed entry). Each check names every
    offending cited id.

    Verified-evidence gate: a cited claim-type entry at status "verified" is
    additionally required to carry a citation.claim_id that resolves to a
    ClaimRecord in the cogni-claims registry whose own status is "verified".
    The claims registry is loaded lazily (read-only) and only when at least one
    cited entry needs the gate, so briefs without verified claims never touch
    it and a dry-run stays read-only.
    """
    prov_defects = {}  # check-name -> [ids]
    to_resolve = []    # (asm_id, claim_id) pairs that need the claims registry
    for asm_id in cited_ids:
        entry = registry[asm_id]
        defect = _classify_provenance(entry)
        if defect:
            prov_defects.setdefault(defect, []).append(asm_id)
        elif (entry.get("provenance_type") == "claim"
                and entry.get("status") == "verified"):
            claim_id = (entry.get("citation") or {}).get("claim_id")
            if not claim_id:
                # Decidable without the registry — the most specific defect.
                prov_defects.setdefault("verified_claim_id_missing", []).append(asm_id)
            else:
                to_resolve.append((asm_id, claim_id))
    if to_resolve:
        claims = _load_claims(claims_file)
        for asm_id, claim_id in to_resolve:
            if claim_id not in claims:
                prov_defects.setdefault("claim_id_dangling", []).append(asm_id)
            elif claims[claim_id].get("status") != "verified":
                prov_defects.setdefault("claim_not_verified", []).append(asm_id)

    prov_messages = {
        "incomplete_provenance":
            "provenance requires both provenance_type and status together (or "
            "neither, for an untyped entry)",
        "invalid_provenance_type":
            "provenance_type must be one of %s" % ", ".join(PROVENANCE_TYPES),
        "invalid_status":
            "status must be one of %s" % ", ".join(STATUS_LADDER),
        "status_cap_exceeded":
            "status exceeds the provenance_type cap — a value must never carry "
            "more confidence than its provenance earns (given caps at 'stated', "
            "estimate at 'reviewed'; only a claim may reach 'verified', and "
            "only through the cogni-claims verify path)",
        "verified_claim_id_missing":
            "status 'verified' requires citation.claim_id — the cogni-claims "
            "back-reference the verify path writes; a verified status without "
            "it is hand-authored and rejected",
        "claim_id_dangling":
            "citation.claim_id does not resolve to any ClaimRecord in the "
            "cogni-claims registry (%s) — the back-reference is dangling"
            % claims_file,
        "claim_not_verified":
            "the referenced ClaimRecord is not itself 'verified' in the "
            "cogni-claims registry — an unverified/deviated/unavailable claim "
            "cannot back a verified assumption",
    }
    for check, message in prov_messages.items():
        ids = prov_defects.get(check)
        if ids:
            _emit(False, {"failed_check": check, "ids": sorted(set(ids))},
                  "%s: %s" % (message, ", ".join(sorted(set(ids)))))


def _load_claims(claims_file):
    """Return {claim_id: record} from the cogni-claims registry, read-only.

    A missing or unreadable registry fails loud: the gate exists precisely so a
    verified marker cannot render without checkable evidence, and an absent
    registry is absent evidence, not a pass.
    """
    try:
        with open(claims_file, encoding="utf-8") as f:
            raw = json.load(f)
    except (json.JSONDecodeError, OSError, UnicodeError) as exc:
        _emit(False, {"failed_check": "claims_registry_unreadable",
                      "path": claims_file},
              "a cited claim-type assumption carries status 'verified' but the "
              "cogni-claims registry could not be read (%s) — the "
              "verified-evidence gate cannot pass without it (override the "
              "location with --claims-file)" % exc)
    return {c.get("id"): c for c in raw.get("claims", [])
            if isinstance(c, dict) and c.get("id")}


def _classify_provenance(entry):
    """Return the provenance defect for an entry, or None when it is clean.

    Untyped entries (neither provenance_type nor status) are clean — the trust
    model is opt-in and backward compatible. When present, the two fields must
    both appear, be in vocabulary, and satisfy the type→status cap.
    """
    ptype = entry.get("provenance_type")
    status = entry.get("status")
    if ptype is None and status is None:
        return None
    if ptype is None or status is None:
        return "incomplete_provenance"
    if ptype not in PROVENANCE_TYPES:
        return "invalid_provenance_type"
    if status not in STATUS_LADDER:
        return "invalid_status"
    if STATUS_LADDER.index(status) > STATUS_LADDER.index(TYPE_STATUS_CAP[ptype]):
        return "status_cap_exceeded"
    return None


def _atomic_write(path, text):
    """Write text to path via temp file + rename — never truncates the original.

    Always writes UTF-8 regardless of locale, and preserves an existing
    file's permission bits (mkstemp defaults to owner-only 0600, which would
    lock out shared checkouts and vault sync). Raises OSError or UnicodeError
    on failure (the temp file is cleaned up first).
    """
    fd, tmp_path = tempfile.mkstemp(
        dir=os.path.dirname(os.path.abspath(path)), suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        if os.path.exists(path):
            os.chmod(tmp_path, os.stat(path).st_mode & 0o7777)
        os.replace(tmp_path, path)
    except (OSError, UnicodeError):
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


def record_used_by(engagement_dir, unique_ids, citer_file):
    """Record the citer into each resolved assumption's used_by[] (derive-at-write).

    A citation is a past fact, so the edge is stored on the assumption record
    rather than derived at read time. Deduped on the citer's engagement-relative
    path: an already-recorded citer is skipped, and when nothing new was cited
    the registry file is not rewritten at all. Returns the number of edges added.
    Raises OSError/UnicodeError on a failed write and ValueError on a
    hand-corrupted used_by field (the caller decides how loud to fail).
    """
    path = os.path.join(engagement_dir, "assumptions.json")
    with open(path, encoding="utf-8") as f:
        raw = json.load(f)
    citer = os.path.relpath(os.path.abspath(citer_file),
                            os.path.abspath(engagement_dir))
    wanted = set(unique_ids)
    stamp = (datetime.datetime.now(datetime.timezone.utc)
             .isoformat(timespec="seconds"))
    added = 0
    for entry in raw.get("assumptions", []):
        if entry.get("id") not in wanted:
            continue
        used_by = entry.setdefault("used_by", [])
        if not isinstance(used_by, list):
            raise ValueError(
                "used_by on %s is not a list — the field is resolver-owned "
                "(derive-at-write); restore it to a JSON array"
                % entry.get("id"))
        if any(isinstance(ref, dict) and ref.get("file") == citer
               for ref in used_by):
            continue
        used_by.append({"file": citer, "resolved_at": stamp})
        added += 1
    if added:
        _atomic_write(path, json.dumps(raw, ensure_ascii=False, indent=2) + "\n")
    return added


def cmd_resolve(args):
    try:
        with open(args.file, encoding="utf-8") as f:
            text = f.read()
    except (OSError, UnicodeError) as exc:
        _emit(False, {"failed_check": "file_unreadable", "path": args.file},
              "target file could not be read: %s" % exc)

    strict_tokens = set(PLACEHOLDER_RE.findall(text))
    malformed = sorted(t for t in set(LOOSE_ASM_RE.findall(text))
                       if not PLACEHOLDER_RE.fullmatch(t))
    if malformed:
        _emit(False, {"failed_check": "malformed_placeholder", "tokens": malformed},
              "placeholder-like token(s) that do not match {{asm:<kebab-slug>}}: "
              "%s — fix the placeholder(s); nothing was resolved" % ", ".join(malformed))
    if not strict_tokens:
        # Nothing to resolve — a registry-less or placeholder-free brief passes.
        _emit(True, {"file": args.file, "placeholders_found": 0, "output": None}, "")

    unique_ids = sorted(ID_PREFIX + s for s in strict_tokens)
    registry = load_registry(args.engagement_dir)
    missing = [i for i in unique_ids if i not in registry]
    if missing:
        _emit(False, {"failed_check": "unknown_assumption_id", "ids": missing},
              "unknown assumption id(s): %s — define them in assumptions.json "
              "or fix the placeholder(s)" % ", ".join(missing))

    # Provenance caps are checked only for the ids this brief actually cites, so
    # a mis-typed unrelated assumption never blocks an unrelated publish, and
    # the brief's own unknown-id error (above) surfaces first.
    claims_file = args.claims_file or os.path.join(
        args.engagement_dir, "..", "..", "cogni-claims", "claims.json")
    validate_provenance(registry, unique_ids, claims_file)

    resolved, count = PLACEHOLDER_RE.subn(
        lambda m: _render_value(registry[ID_PREFIX + m.group(1)]), text)

    # A registry value may itself contain (or re-form) a placeholder; shipping
    # it verbatim would break the never-silently-left-in contract.
    leftovers = sorted(set(LOOSE_ASM_RE.findall(resolved)))
    if leftovers:
        _emit(False, {"failed_check": "unresolved_after_substitution", "tokens": leftovers},
              "placeholder-like token(s) remain after substitution (a registry "
              "value embeds one?): %s — nothing was written" % ", ".join(leftovers))

    data = {
        "file": args.file,
        "placeholders_found": count,
        "unique_ids": unique_ids,
        "output": args.file if args.in_place else None,
    }
    if args.in_place:
        # Reference-edge emission FIRST: if the edge cannot be recorded, the
        # target file still holds its placeholders and a retry resolves it
        # again. Writing the file first would leave it placeholder-free on an
        # edge failure, so the retry no-ops at placeholders_found:0 and the
        # edge becomes permanently unrecordable. Skip-if-present keeps
        # repeated publish / design-thinking renders idempotent. The broad
        # except honors the fail-loud contract — a defective hand-edited
        # used_by or corrupt registry must yield an envelope, not a traceback.
        try:
            data["used_by_added"] = record_used_by(
                args.engagement_dir, unique_ids, args.file)
        except Exception as exc:
            _emit(False, {"failed_check": "used_by_write_failed",
                          "path": os.path.join(args.engagement_dir, "assumptions.json")},
                  "used_by[] reference edge could not be recorded in "
                  "assumptions.json (target file untouched — safe to retry): %s" % exc)
        # Atomic replace: never truncate the only copy of the built brief.
        try:
            _atomic_write(args.file, resolved)
        except (OSError, UnicodeError) as exc:
            _emit(False, {"failed_check": "write_failed", "path": args.file},
                  "resolved text could not be written (original file untouched; "
                  "the recorded used_by[] edge is idempotent on retry): %s" % exc)
    else:
        data["resolved_text"] = resolved
    _emit(True, data, "")


def main():
    parser = argparse.ArgumentParser(
        description="Resolve {{asm:id}} placeholders against the engagement's assumptions.json")
    parser.add_argument("engagement_dir", help="engagement root (directory holding consult-project.json)")
    sub = parser.add_subparsers(dest="action", required=True)

    p_resolve = sub.add_parser("resolve", help="resolve placeholders in a file")
    p_resolve.add_argument("file", help="file containing {{asm:id}} placeholders")
    p_resolve.add_argument("--in-place", action="store_true",
                           help="write resolved text back to the file (omit for a dry-run envelope)")
    p_resolve.add_argument("--claims-file", default=None,
                           help="cogni-claims registry the verified-evidence gate reads "
                                "(default: <engagement-dir>/../../cogni-claims/claims.json; "
                                "only consulted when a cited claim-type assumption is 'verified')")
    p_resolve.set_defaults(func=cmd_resolve)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

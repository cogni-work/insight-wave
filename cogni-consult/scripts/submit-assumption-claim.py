#!/usr/bin/env python3
"""Submit/propagate adapter wiring claim-type assumptions to cogni-claims.

Usage:
  python3 submit-assumption-claim.py <engagement-dir> submit <asm-id>
      [--project-dir <dir>]
  python3 submit-assumption-claim.py <engagement-dir> propagate <asm-id>
      [--claim-id <id>] [--project-dir <dir>]
  python3 submit-assumption-claim.py <engagement-dir> resolve-propagate <asm-id>
      [--corrected-value <value>] [--claim-id <id>] [--project-dir <dir>]

`submit` builds a ClaimRecord for one claim-type assumption and appends it
(status "unverified") to the workspace cogni-claims registry, under the same
mkdir-based lock discipline the ecosystem's claim appenders use. The record's
entity_ref is the adapted object form of the cross-plugin contract —
{"type": "assumption", "file": <project-relative assumptions.json path>,
"field_path": 'assumptions[?id=="<asm-id>"].value'} — mapping cogni-consult's
flat-string citation.entity_ref coordinate onto the object locator cogni-claims
consumers destructure. No cogni-claims schema change is involved. Submit is
idempotent: an existing ClaimRecord with the same adapted entity_ref (or one
already referenced by the assumption's citation.claim_id) is reused, never
duplicated, so a resumed pipeline maps one assumption to exactly one record.

`propagate` completes the round-trip after cogni-claims verification: it
requires the referenced ClaimRecord to exist with status "verified" (fail loud
otherwise) and then atomically writes status "verified" plus the
citation.claim_id back-reference onto the assumption record — the evidence the
render-time resolver's verified gate checks. Writing "verified" is a fixed
point, so repeated propagates are no-ops.

`resolve-propagate` completes the deviated->resolved leg for the three
value-affecting resolution actions (mirroring cogni-portfolio's verify Step 8):
after a verified ClaimRecord is disputed and resolved in cogni-claims, it
requires the referenced ClaimRecord to be status "resolved" with a propagable
resolution.action (fail loud otherwise), then atomically writes the resolution
back onto the assumption and stamps citation.propagated_at:
  - "corrected": writes the corrected value onto the assumption — the explicit
    --corrected-value, or when that flag is omitted the resolved ClaimRecord's
    resolution.corrected_statement used verbatim (a full sentence, not a scalar
    extracted from it — this stdlib script does no semantic parsing). Fails loud
    only when neither is present.
  - "alternative_source": writes resolution.alternative_source_url (and the
    optional alternative_source_title) onto the citation, leaving the value
    unchanged — the value stood, only its source moved.
  - "discarded": unbinds citation.claim_id, leaving the value in place as a
    last-known figure (the {{asm:}} placeholder still needs a value to resolve,
    so unlike an entity field it cannot be deleted).
All three demote status "verified" -> "reviewed" (the ClaimRecord is now
"resolved", not "verified", so the render-time resolver's verified gate must
stop passing it). The non-propagable actions "disputed" and "accepted_override"
keep the original value and are refused. Every write is guarded so a resumed
pipeline re-run over an already-propagated assumption is a true no-op.

Fail-loud contract: unknown assumption id, a non-claim provenance_type, a
missing citation.source_url on submit, an unreadable registry on either side,
a dangling claim reference, a not-verified ClaimRecord on propagate, or (on
resolve-propagate) a ClaimRecord that is not status "resolved", whose
resolution.action is not propagable, a "corrected" resolution carrying no
corrected value at all (neither --corrected-value nor a non-empty
resolution.corrected_statement to fall back on), or an "alternative_source"
resolution with no alternative_source_url all return success:false with a
data.failed_check discriminator and exit 1.

Output: single-line JSON envelope {"success": bool, "data": {...}, "error": str}.
Stdlib-only.
"""

import argparse
import datetime
import json
import os
import sys
import tempfile
import time
import uuid

LOCK_MAX_WAIT_S = 3.0
LOCK_STALE_S = 60.0


def _emit(success, data, error):
    print(json.dumps({"success": success, "data": data, "error": error}))
    sys.exit(0 if success else 1)


def _now_utc():
    # Z-suffixed form, matching the ClaimRecord schema examples and what the
    # ecosystem's other appenders write — keeps claims.json timestamps uniform.
    return (datetime.datetime.now(datetime.timezone.utc)
            .strftime("%Y-%m-%dT%H:%M:%SZ"))


def _load_json(path, failed_check, what):
    if not os.path.isfile(path):
        _emit(False, {"failed_check": failed_check, "path": path},
              "%s not found at %s" % (what, path))
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, OSError, UnicodeError) as exc:
        _emit(False, {"failed_check": failed_check, "path": path},
              "%s could not be read/parsed: %s" % (what, exc))


def _atomic_write(path, payload):
    """Temp file + rename, UTF-8, preserving existing permission bits."""
    fd, tmp_path = tempfile.mkstemp(
        dir=os.path.dirname(os.path.abspath(path)), suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")
        if os.path.exists(path):
            os.chmod(tmp_path, os.stat(path).st_mode & 0o7777)
        os.replace(tmp_path, path)
    except (OSError, UnicodeError):
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


class _ClaimsLock(object):
    """mkdir-based lock on the claims registry (portable, stale-safe)."""

    def __init__(self, claims_dir):
        self.lock_dir = os.path.join(claims_dir, ".claims.lock")

    def __enter__(self):
        deadline = time.time() + LOCK_MAX_WAIT_S
        while True:
            try:
                os.mkdir(self.lock_dir)
                return self
            except FileExistsError:
                # A mkdir lock's mtime is set once and never refreshed, so a
                # stale lock is reclaimable immediately — no live holder is
                # protected by waiting out the deadline first.
                try:
                    age = time.time() - os.stat(self.lock_dir).st_mtime
                except OSError:
                    continue  # lock vanished — retry immediately
                if age > LOCK_STALE_S:
                    try:
                        os.rmdir(self.lock_dir)
                    except OSError:
                        pass
                    continue
                if time.time() >= deadline:
                    _emit(False, {"failed_check": "claims_lock_timeout",
                                  "path": self.lock_dir},
                          "could not acquire the claims registry lock after "
                          "%.0fs — another submitter may be running" % LOCK_MAX_WAIT_S)
                time.sleep(0.1)

    def __exit__(self, *exc):
        try:
            os.rmdir(self.lock_dir)
        except OSError:
            pass
        return False


def _load_assumption(engagement_dir, asm_id):
    """Return (registry_path, raw_registry, entry) for one assumption id."""
    path = os.path.join(engagement_dir, "assumptions.json")
    raw = _load_json(path, "registry_unreadable", "assumptions.json")
    # isinstance guards keep a hand-corrupted registry (top-level list,
    # non-dict entry) on the fail-loud envelope path, not a raw AttributeError.
    entries = raw.get("assumptions", []) if isinstance(raw, dict) else []
    for entry in entries:
        if isinstance(entry, dict) and entry.get("id") == asm_id:
            return path, raw, entry
    _emit(False, {"failed_check": "unknown_assumption_id", "ids": [asm_id]},
          "no assumption with id %s in %s" % (asm_id, path))


def _require_claim_type(entry, asm_id):
    if entry.get("provenance_type") != "claim":
        _emit(False, {"failed_check": "not_claim_type", "ids": [asm_id]},
              "only a claim-type assumption is eligible for the cogni-claims "
              "verify path; %s has provenance_type %r"
              % (asm_id, entry.get("provenance_type")))


def _adapted_entity_ref(registry_path, project_dir, asm_id):
    """Fork-1 adapter: consult coordinates -> the cogni-claims EntityRef object."""
    rel_file = os.path.relpath(os.path.abspath(registry_path),
                               os.path.abspath(project_dir))
    return {
        "type": "assumption",
        "file": rel_file,
        "field_path": 'assumptions[?id=="%s"].value' % asm_id,
    }


def _claims_paths(project_dir):
    claims_dir = os.path.join(project_dir, "cogni-claims")
    return claims_dir, os.path.join(claims_dir, "claims.json")


def _ref_matches(claim, entity_ref):
    """One identity predicate for "the ClaimRecord belonging to this assumption".

    Field-wise on the three adapted keys (not whole-dict equality), so a
    consumer annotating an extra key onto a stored entity_ref never splits the
    submit and propagate legs' notion of which record is the one.
    """
    existing = claim.get("entity_ref") or {}
    return all(existing.get(k) == entity_ref[k]
               for k in ("type", "file", "field_path"))


def cmd_submit(args):
    registry_path, _raw, entry = _load_assumption(args.engagement_dir, args.asm_id)
    _require_claim_type(entry, args.asm_id)
    citation = entry.get("citation") or {}
    source_url = citation.get("source_url")
    if not source_url:
        _emit(False, {"failed_check": "citation_source_url_missing",
                      "ids": [args.asm_id]},
              "submit requires citation.source_url — a claim without a source "
              "URL has nothing for cogni-claims to verify against")

    entity_ref = _adapted_entity_ref(registry_path, args.project_dir, args.asm_id)
    claims_dir, claims_file = _claims_paths(args.project_dir)
    os.makedirs(claims_dir, exist_ok=True)

    with _ClaimsLock(claims_dir):
        if os.path.isfile(claims_file):
            data = _load_json(claims_file, "claims_registry_unreadable",
                              "cogni-claims registry")
        else:
            data = {"claims": []}
        # Idempotent re-submit: one assumption maps to exactly one ClaimRecord.
        # The claim_id leg needs a non-null id on BOTH sides — None == None
        # would falsely reuse a malformed id-less record.
        cited_id = citation.get("claim_id")
        for claim in data.get("claims", []):
            if not isinstance(claim, dict):
                continue
            if ((cited_id is not None and claim.get("id") == cited_id)
                    or _ref_matches(claim, entity_ref)):
                _emit(True, {"claim_id": claim.get("id"), "reused": True,
                             "status": claim.get("status"),
                             "claims_file": claims_file}, "")
        record = {
            "id": "claim-%s" % uuid.uuid4(),
            "statement": "%s: %s" % (entry.get("name", args.asm_id),
                                     entry.get("value")),
            "source_url": source_url,
            "source_title": citation.get("source_title") or entry.get("name")
                            or args.asm_id,
            "submitted_by": "cogni-consult",
            "submitted_at": _now_utc(),
            "status": "unverified",
            "verified_at": None,
            "deviations": [],
            "resolution": None,
            "source_excerpt": None,
            "verification_notes": None,
            "entity_ref": entity_ref,
            "propagated_at": None,
        }
        data.setdefault("claims", []).append(record)
        try:
            _atomic_write(claims_file, data)
        except (OSError, UnicodeError) as exc:
            _emit(False, {"failed_check": "claims_write_failed",
                          "path": claims_file},
                  "ClaimRecord could not be appended: %s" % exc)
    _emit(True, {"claim_id": record["id"], "reused": False,
                 "status": "unverified", "entity_ref": entity_ref,
                 "claims_file": claims_file}, "")


def cmd_propagate(args):
    registry_path, raw, entry = _load_assumption(args.engagement_dir, args.asm_id)
    _require_claim_type(entry, args.asm_id)
    citation = entry.get("citation") or {}
    _claims_dir, claims_file = _claims_paths(args.project_dir)
    data = _load_json(claims_file, "claims_registry_unreadable",
                      "cogni-claims registry")
    claims = {c.get("id"): c for c in data.get("claims", [])
              if isinstance(c, dict) and c.get("id")}

    claim_id = args.claim_id or citation.get("claim_id")
    if not claim_id:
        # Fall back to the adapted entity_ref this adapter's submit leg wrote.
        entity_ref = _adapted_entity_ref(registry_path, args.project_dir,
                                         args.asm_id)
        matches = [c for c in claims.values() if _ref_matches(c, entity_ref)]
        if not matches:
            _emit(False, {"failed_check": "verified_claim_id_missing",
                          "ids": [args.asm_id]},
                  "no --claim-id given, no citation.claim_id on the "
                  "assumption, and no ClaimRecord carries its adapted "
                  "entity_ref — submit first")
        claim_id = matches[0].get("id")

    record = claims.get(claim_id)
    if record is None:
        _emit(False, {"failed_check": "claim_id_dangling",
                      "claim_id": claim_id, "ids": [args.asm_id]},
              "claim %s does not resolve to any ClaimRecord in %s"
              % (claim_id, claims_file))
    if record.get("status") != "verified":
        _emit(False, {"failed_check": "claim_not_verified",
                      "claim_id": claim_id, "status": record.get("status"),
                      "ids": [args.asm_id]},
              "claim %s has status %r — only a verified ClaimRecord may "
              "promote an assumption to 'verified'"
              % (claim_id, record.get("status")))

    changed = (entry.get("status") != "verified"
               or citation.get("claim_id") != claim_id)
    if changed:
        # Write-side mirror of the read path's `entry.get("citation") or {}`
        # guard: setdefault hands back an explicit null/non-dict citation
        # untouched and the item assignment would crash unenveloped.
        if not isinstance(entry.get("citation"), dict):
            entry["citation"] = {}
        entry["citation"]["claim_id"] = claim_id
        entry["status"] = "verified"
        entry["updated"] = datetime.date.today().isoformat()
        try:
            _atomic_write(registry_path, raw)
        except (OSError, UnicodeError) as exc:
            _emit(False, {"failed_check": "registry_write_failed",
                          "path": registry_path},
                  "verified status could not be written back onto the "
                  "assumption record: %s" % exc)
    _emit(True, {"asm_id": args.asm_id, "claim_id": claim_id,
                 "status": "verified", "changed": changed}, "")


def _resolve_claim_id(args, registry_path, claims, citation):
    """Same claim-id resolution the propagate leg uses: explicit flag, else the
    assumption's citation.claim_id, else the record carrying its adapted
    entity_ref. Fails loud when none of the three resolve."""
    claim_id = args.claim_id or citation.get("claim_id")
    if claim_id:
        return claim_id
    entity_ref = _adapted_entity_ref(registry_path, args.project_dir, args.asm_id)
    matches = [c for c in claims.values() if _ref_matches(c, entity_ref)]
    if not matches:
        _emit(False, {"failed_check": "resolved_claim_id_missing",
                      "ids": [args.asm_id]},
              "no --claim-id given, no citation.claim_id on the assumption, and "
              "no ClaimRecord carries its adapted entity_ref — submit first")
    return matches[0].get("id")


def cmd_resolve_propagate(args):
    registry_path, raw, entry = _load_assumption(args.engagement_dir, args.asm_id)
    _require_claim_type(entry, args.asm_id)
    citation = entry.get("citation") or {}
    _claims_dir, claims_file = _claims_paths(args.project_dir)
    data = _load_json(claims_file, "claims_registry_unreadable",
                      "cogni-claims registry")
    claims = {c.get("id"): c for c in data.get("claims", [])
              if isinstance(c, dict) and c.get("id")}

    claim_id = _resolve_claim_id(args, registry_path, claims, citation)
    record = claims.get(claim_id)
    if record is None:
        _emit(False, {"failed_check": "claim_id_dangling",
                      "claim_id": claim_id, "ids": [args.asm_id]},
              "claim %s does not resolve to any ClaimRecord in %s"
              % (claim_id, claims_file))
    if record.get("status") != "resolved":
        _emit(False, {"failed_check": "claim_not_resolved",
                      "claim_id": claim_id, "status": record.get("status"),
                      "ids": [args.asm_id]},
              "claim %s has status %r — only a resolved ClaimRecord may "
              "propagate a corrected value onto an assumption"
              % (claim_id, record.get("status")))
    resolution = record.get("resolution")
    action = resolution.get("action") if isinstance(resolution, dict) else None
    # Three actions carry a value-affecting resolution back onto the assumption
    # (mirroring cogni-portfolio verify Step 8). 'disputed' and
    # 'accepted_override' keep the original value, so they are refused here.
    if action not in ("corrected", "alternative_source", "discarded"):
        _emit(False, {"failed_check": "resolution_action_not_propagable",
                      "claim_id": claim_id, "action": action,
                      "ids": [args.asm_id]},
              "claim %s resolution.action is %r — only 'corrected', "
              "'alternative_source', or 'discarded' propagate onto an assumption "
              "('disputed' and 'accepted_override' keep the original value)"
              % (claim_id, action))

    old_value = entry.get("value")
    # A resolved ClaimRecord is no longer 'verified' evidence, so a still-
    # 'verified' assumption must be capped back to 'reviewed'; other (lower)
    # statuses already satisfy the render gate and are left alone.
    demote = entry.get("status") == "verified"

    # Per-action write plan. Each action decides which fields it mutates; the
    # shared block below applies them under the idempotency (`changed`) guard.
    new_value = old_value
    value_changed = False
    set_source_url = None
    set_source_title = None
    set_claim_id = None
    clear_claim_id = False

    if action == "corrected":
        # The corrected value is the explicit --corrected-value, else the
        # resolved ClaimRecord's resolution.corrected_statement used verbatim (a
        # full sentence, not a scalar — this stdlib script does no semantic
        # extraction, so a caller needing a bare value passes --corrected-value).
        new_value = args.corrected_value
        if new_value is None:
            new_value = resolution.get("corrected_statement")
        if not new_value:
            _emit(False, {"failed_check": "corrected_value_missing",
                          "claim_id": claim_id, "ids": [args.asm_id]},
                  "claim %s resolution.action is 'corrected' but no "
                  "--corrected-value was supplied and the resolved claim carries "
                  "no resolution.corrected_statement to fall back on — supply "
                  "--corrected-value explicitly" % claim_id)
        value_changed = old_value != new_value
        # Keep the claim back-reference current (as the original leg did).
        set_claim_id = claim_id
    elif action == "alternative_source":
        set_source_url = resolution.get("alternative_source_url")
        if not set_source_url:
            _emit(False, {"failed_check": "alternative_source_url_missing",
                          "claim_id": claim_id, "action": action,
                          "ids": [args.asm_id]},
                  "claim %s resolution.action is 'alternative_source' but carries "
                  "no alternative_source_url" % claim_id)
        # Optional; only written when present. The value is unchanged — the
        # figure stood, only its source moved.
        set_source_title = resolution.get("alternative_source_title")
        set_claim_id = claim_id
    elif action == "discarded":
        # The claim is unsupported: unbind it. The value stays in place as a
        # last-known figure — {{asm:}} rendering requires a value, so unlike a
        # portfolio entity field the data point cannot be deleted.
        clear_claim_id = True

    source_url_changed = (set_source_url is not None
                          and citation.get("source_url") != set_source_url)
    source_title_changed = (set_source_title is not None
                            and citation.get("source_title") != set_source_title)
    claim_id_set_changed = (set_claim_id is not None
                            and citation.get("claim_id") != set_claim_id)
    claim_id_cleared = clear_claim_id and citation.get("claim_id") is not None
    changed = (value_changed or demote or source_url_changed
               or source_title_changed or claim_id_set_changed
               or claim_id_cleared)
    if changed:
        # Write-side mirror of the read path's `entry.get("citation") or {}`
        # guard: an explicit null/non-dict citation would crash on item-assign.
        if not isinstance(entry.get("citation"), dict):
            entry["citation"] = {}
        cit = entry["citation"]
        if value_changed:
            entry["value"] = new_value
        if demote:
            entry["status"] = "reviewed"
        if set_source_url is not None:
            cit["source_url"] = set_source_url
        if set_source_title is not None:
            cit["source_title"] = set_source_title
        if set_claim_id is not None:
            cit["claim_id"] = set_claim_id
        if clear_claim_id:
            cit.pop("claim_id", None)
        cit["propagated_at"] = _now_utc()
        entry["updated"] = datetime.date.today().isoformat()
        try:
            _atomic_write(registry_path, raw)
        except (OSError, UnicodeError) as exc:
            _emit(False, {"failed_check": "registry_write_failed",
                          "path": registry_path},
                  "resolution could not be written back onto the "
                  "assumption record: %s" % exc)
    _emit(True, {"asm_id": args.asm_id, "claim_id": claim_id, "action": action,
                 "status": entry.get("status"), "value_changed": value_changed,
                 "old_value": old_value, "new_value": entry.get("value"),
                 "changed": changed}, "")


def main():
    parser = argparse.ArgumentParser(
        description="Submit a claim-type assumption to cogni-claims, propagate "
                    "its verified verdict, or propagate a resolved correction "
                    "back onto the assumption record")
    parser.add_argument("engagement_dir",
                        help="engagement root (directory holding assumptions.json)")
    sub = parser.add_subparsers(dest="action", required=True)

    p_submit = sub.add_parser(
        "submit", help="append an unverified ClaimRecord for one assumption")
    p_submit.add_argument("asm_id", help="assumption id (asm-<slug>)")
    p_submit.set_defaults(func=cmd_submit)

    p_prop = sub.add_parser(
        "propagate",
        help="write status=verified + citation.claim_id onto the assumption "
             "(requires the ClaimRecord to be verified)")
    p_prop.add_argument("asm_id", help="assumption id (asm-<slug>)")
    p_prop.add_argument("--claim-id", default=None,
                        help="ClaimRecord id (default: the assumption's "
                             "citation.claim_id, else the record matching its "
                             "adapted entity_ref)")
    p_prop.set_defaults(func=cmd_propagate)

    p_resolve = sub.add_parser(
        "resolve-propagate",
        help="propagate a resolved claim onto the assumption and demote status "
             "verified->reviewed (requires the ClaimRecord to be resolved with a "
             "propagable resolution.action: corrected | alternative_source | "
             "discarded)")
    p_resolve.add_argument("asm_id", help="assumption id (asm-<slug>)")
    p_resolve.add_argument("--corrected-value", default=None,
                           help="the corrected value to write onto the "
                                "assumption for the 'corrected' action (default: "
                                "the resolved ClaimRecord's "
                                "resolution.corrected_statement used verbatim — a "
                                "full sentence, not a scalar extracted from it; "
                                "supply this flag when a bare value is needed, "
                                "else the script fails loud when no "
                                "corrected_statement is present either). The "
                                "alternative_source and discarded actions ignore "
                                "it — their fields are read off the ClaimRecord's "
                                "resolution")
    p_resolve.add_argument("--claim-id", default=None,
                           help="ClaimRecord id (default: the assumption's "
                                "citation.claim_id, else the record matching its "
                                "adapted entity_ref)")
    p_resolve.set_defaults(func=cmd_resolve_propagate)

    for p in (p_submit, p_prop, p_resolve):
        p.add_argument("--project-dir", default=None,
                       help="project root holding cogni-claims/ "
                            "(default: <engagement-dir>/../..)")

    args = parser.parse_args()
    if args.project_dir is None:
        args.project_dir = os.path.join(args.engagement_dir, "..", "..")
    args.func(args)


if __name__ == "__main__":
    main()

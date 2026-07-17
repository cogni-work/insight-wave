#!/usr/bin/env python3
"""Rank candidate consultants for each open project role in a cogni-projects portfolio.

The Phase 2 staffing engine. For every project that carries `open_roles`, this
script scores each consultant in the portfolio on three visible per-factor
sub-scores and a combined score, then returns a ranked shortlist per open role:

- **availability** — how well the consultant's `available_from`/`available_until`
  window overlaps the project's `start_date`/`end_date` window, weighted by the
  consultant's free capacity (`allocation_pct` headroom). A consultant whose
  window does not overlap the project window at all is **excluded** from that
  project's ranking (never scored, never listed).
- **profile fit** — how well the consultant's `skills` match the open role label,
  blended with a small seniority prior.
- **strategic impact** — the project's `strategic_impact` (1..5) normalized to
  [0,1], so staffing optimizes firm strategy, not just utilization.

The three sub-scores and the combined score are all in [0,1] and shown
separately (AC1). Consultants with no availability overlap are excluded (AC2).
Output is deterministic for identical inputs — scores are rounded to a fixed
precision, ties break on the consultant slug, and no wall-clock value enters the
result (AC3).

Reads entity frontmatter with the same stdlib parser the validator uses
(`validate-entities.py:parse_frontmatter`, loaded by file location as
`register-entity.py` does) — no duplicated parser, no PyYAML.

Usage:
  python3 staffing-score.py <portfolio-dir>

<portfolio-dir> is a cogni-projects/<portfolio-slug>/ directory rooted by a
projects-portfolio.json manifest.

Output: a single JSON line following the repo contract
  {"success": bool, "data": {...}, "error": str}
Exit: 0 ok / 1 domain failure (bad portfolio / unreadable manifest) / 2 usage.
"""

import importlib.util
import json
import os
import sys

# --- Scoring weights (defensible MVP defaults; tunable is a follow-up concern) ---
# Combined score blends the three sub-factors. Availability leads (a perfect
# profile is worthless if the person cannot take the work), strategic impact is
# the lightest weight (it tilts ties toward firm-defining projects without
# letting a tactical-but-perfect match lose to a strategic-but-poor one).
W_AVAILABILITY = 0.40
W_PROFILE_FIT = 0.35
W_STRATEGIC_IMPACT = 0.25

# Availability sub-score itself blends temporal overlap with free capacity.
W_OVERLAP = 0.60
W_HEADROOM = 0.40

# Profile-fit sub-score blends role-skill match with a seniority prior.
W_SKILL_MATCH = 0.75
W_SENIORITY = 0.25

# Seniority normalized to [0,1] — the seniority prior in profile fit.
SENIORITY_NORM = {
    "junior": 0.2,
    "consultant": 0.4,
    "senior": 0.6,
    "principal": 0.8,
    "partner": 1.0,
}

SCORE_PRECISION = 3  # decimal places — fixes output for byte-identical re-runs.


def _fail(message, code):
    """Emit the failure envelope and return the exit code."""
    print(json.dumps(
        {"success": False, "data": {}, "error": message}, ensure_ascii=False
    ))
    return code


def _load_parse_frontmatter():
    """Load parse_frontmatter from the sibling validate-entities.py by file path.

    validate-entities.py is not an importable module name (hyphens), so — exactly
    as register-entity.py does — load it by location to reuse the one canonical
    frontmatter parser rather than duplicating the schema-shaped parsing rules.
    Returns the callable, or None if the validator module cannot be loaded.
    """
    v_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)), "validate-entities.py"
    )
    spec = importlib.util.spec_from_file_location("validate_entities", v_path)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return getattr(module, "parse_frontmatter", None)


def _read_frontmatter(parse_frontmatter, path):
    """Return the parsed frontmatter dict for an entity file, or {} on any miss."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return {}
    fm = parse_frontmatter(text)
    return fm if isinstance(fm, dict) else {}


def _overlap_fraction(cf, cu, ps, pe):
    """Fraction of the project window the consultant's availability covers.

    Windows are ISO date strings; a `None`/empty bound is open (unbounded) on
    that side. Returns a float in [0,1]: the overlap length divided by the
    project-window length. When the project window is a single day or unbounded,
    any non-empty overlap yields 1.0. Returns 0.0 when the windows do not
    overlap at all — the exclusion signal AC2 keys on.

    ISO-8601 date strings order and subtract correctly as `datetime.date`.
    """
    import datetime

    def _d(value):
        if isinstance(value, str) and value:
            try:
                return datetime.date.fromisoformat(value)
            except ValueError:
                return None
        return None

    cf_d, cu_d, ps_d, pe_d = _d(cf), _d(cu), _d(ps), _d(pe)

    # Effective overlap window: intersect [cf,cu] with [ps,pe], treating a
    # missing bound as unbounded on that side.
    lo_candidates = [d for d in (cf_d, ps_d) if d is not None]
    hi_candidates = [d for d in (cu_d, pe_d) if d is not None]
    lo = max(lo_candidates) if lo_candidates else None
    hi = min(hi_candidates) if hi_candidates else None

    if lo is not None and hi is not None and lo > hi:
        return 0.0  # disjoint windows — no overlap.

    # Project-window length, in days, as the denominator.
    if ps_d is not None and pe_d is not None:
        proj_days = (pe_d - ps_d).days + 1
        if proj_days <= 0:
            return 1.0
    else:
        # Unbounded project window: any overlap counts fully.
        return 1.0

    if lo is None:
        lo = ps_d
    if hi is None:
        hi = pe_d
    overlap_days = (hi - lo).days + 1
    if overlap_days <= 0:
        return 0.0
    frac = overlap_days / proj_days
    return 1.0 if frac > 1.0 else (0.0 if frac < 0.0 else frac)


def _availability_score(consultant, project):
    """Availability sub-score, or None when the consultant must be excluded.

    Returns None when there is zero temporal overlap between the consultant's
    availability window and the project window (AC2 exclusion). Otherwise blends
    the overlap fraction with the consultant's free-capacity headroom.
    """
    overlap = _overlap_fraction(
        consultant.get("available_from"), consultant.get("available_until"),
        project.get("start_date"), project.get("end_date"),
    )
    if overlap <= 0.0:
        return None
    alloc = consultant.get("allocation_pct")
    headroom = 1.0 if not isinstance(alloc, int) else max(0.0, (100 - alloc) / 100.0)
    return W_OVERLAP * overlap + W_HEADROOM * headroom


def _tokenize(value):
    """Lowercase hyphen/space/underscore tokens from a string or list of strings."""
    tokens = set()
    items = value if isinstance(value, list) else [value]
    for item in items:
        if not isinstance(item, str):
            continue
        for tok in item.lower().replace("_", "-").replace(" ", "-").split("-"):
            if tok:
                tokens.add(tok)
    return tokens


def _profile_fit_score(consultant, role):
    """Profile-fit sub-score: role-skill match blended with a seniority prior."""
    role_tokens = _tokenize(role)
    skill_tokens = _tokenize(consultant.get("skills", []))
    if role_tokens:
        matched = len(role_tokens & skill_tokens)
        skill_match = matched / len(role_tokens)
    else:
        skill_match = 0.0
    seniority = SENIORITY_NORM.get(consultant.get("seniority"), 0.0)
    return W_SKILL_MATCH * skill_match + W_SENIORITY * seniority


def _strategic_impact_norm(project):
    """Project strategic_impact (1..5) normalized to [0,1]; 0.0 when absent/bad."""
    impact = project.get("strategic_impact")
    if not isinstance(impact, int):
        return 0.0
    impact = max(1, min(5, impact))
    return (impact - 1) / 4.0


def _round(x):
    return round(x, SCORE_PRECISION)


def _load_entities(parse_frontmatter, portfolio_dir, manifest, kind, subdir):
    """Read every entity of one kind into a list of frontmatter dicts.

    Prefers the manifest's summary refs (the index later skills scan) for the
    file list, falling back to scanning the entity subdirectory so a
    hand-authored file the manifest has not yet indexed is still considered.
    """
    files = []
    seen = set()
    for ref in manifest.get(kind, []) or []:
        rel = ref.get("file") if isinstance(ref, dict) else None
        if rel:
            path = os.path.join(portfolio_dir, rel)
            files.append(path)
            seen.add(os.path.abspath(path))
    dir_path = os.path.join(portfolio_dir, subdir)
    if os.path.isdir(dir_path):
        for name in sorted(os.listdir(dir_path)):
            if name.endswith(".md"):
                path = os.path.join(dir_path, name)
                if os.path.abspath(path) not in seen:
                    files.append(path)
    entities = []
    for path in files:
        fm = _read_frontmatter(parse_frontmatter, path)
        if fm:
            entities.append(fm)
    return entities


def score_portfolio(portfolio_dir, parse_frontmatter):
    """Build the ranked-shortlist data structure for a portfolio directory."""
    manifest_path = os.path.join(portfolio_dir, "projects-portfolio.json")
    try:
        with open(manifest_path, "r", encoding="utf-8") as f:
            manifest = json.load(f)
    except (OSError, ValueError) as exc:
        raise RuntimeError("cannot read portfolio manifest %s: %s"
                           % (manifest_path, exc))

    consultants = _load_entities(
        parse_frontmatter, portfolio_dir, manifest, "consultants", "consultants"
    )
    projects = _load_entities(
        parse_frontmatter, portfolio_dir, manifest, "projects", "projects"
    )

    # Deterministic project order — by slug.
    projects.sort(key=lambda p: str(p.get("slug", "")))

    project_results = []
    total_ranked = 0
    for project in projects:
        open_roles = project.get("open_roles") or []
        if not isinstance(open_roles, list):
            open_roles = []
        strat = _round(_strategic_impact_norm(project))
        role_results = []
        for role in open_roles:
            candidates = []
            excluded = 0
            for consultant in consultants:
                availability = _availability_score(consultant, project)
                if availability is None:
                    excluded += 1
                    continue
                profile_fit = _profile_fit_score(consultant, role)
                combined = (
                    W_AVAILABILITY * availability
                    + W_PROFILE_FIT * profile_fit
                    + W_STRATEGIC_IMPACT * _strategic_impact_norm(project)
                )
                candidates.append({
                    "consultant": consultant.get("slug"),
                    "name": consultant.get("name"),
                    "scores": {
                        "availability": _round(availability),
                        "profile_fit": _round(profile_fit),
                        "strategic_impact": strat,
                        "combined": _round(combined),
                    },
                })
            # Rank by combined score desc, deterministic slug tiebreak asc.
            candidates.sort(
                key=lambda c: (-c["scores"]["combined"], str(c["consultant"]))
            )
            total_ranked += len(candidates)
            role_results.append({
                "role": role,
                "candidates": candidates,
                "excluded_count": excluded,
            })
        project_results.append({
            "project": project.get("slug"),
            "name": project.get("name"),
            "strategic_impact": project.get("strategic_impact"),
            "strategic_impact_norm": strat,
            "open_roles": role_results,
        })

    return {
        "portfolio": manifest.get("slug") or os.path.basename(
            os.path.normpath(portfolio_dir)
        ),
        "weights": {
            "availability": W_AVAILABILITY,
            "profile_fit": W_PROFILE_FIT,
            "strategic_impact": W_STRATEGIC_IMPACT,
        },
        "consultant_count": len(consultants),
        "project_count": len(projects),
        "ranked_candidate_count": total_ranked,
        "projects": project_results,
    }


def main(argv):
    if len(argv) != 1:
        return _fail("usage: staffing-score.py <portfolio-dir>", 2)
    portfolio_dir = argv[0]
    if not os.path.isdir(portfolio_dir):
        return _fail("portfolio directory not found: %s" % portfolio_dir, 1)
    if not os.path.isfile(os.path.join(portfolio_dir, "projects-portfolio.json")):
        return _fail(
            "not a portfolio directory (no projects-portfolio.json): %s "
            "(run /cogni-projects:projects-setup first)" % portfolio_dir, 1
        )

    parse_frontmatter = _load_parse_frontmatter()
    if parse_frontmatter is None:
        return _fail(
            "cannot load validate-entities.py:parse_frontmatter (expected sibling "
            "of this script)", 2
        )

    try:
        data = score_portfolio(portfolio_dir, parse_frontmatter)
    except RuntimeError as exc:
        return _fail(str(exc), 1)

    print(json.dumps(
        {"success": True, "data": data, "error": ""}, ensure_ascii=False
    ))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))

#!/usr/bin/env python3
"""Grade competitive analysis through a closed CSO/Analyst review loop with auto-rewrite.

This script orchestrates the review loop for compete entities — it reads pre-generated
reviewer JSON files and competitor JSONs, scores them, and produces grading.json
compatible with the eval viewer.

The actual agent invocations (CSO reviewer, market-industry-analyst reviewer,
competitor-researcher revision) are handled by the eval runner (subagent) that calls
this script between iterations. This script focuses on scoring, convergence detection,
and feedback synthesis.

Usage:
    # Score a single iteration's reviews
    python grade_compete_review_loop.py score <run_dir>
        --cso-review <cso-review.json>
        --analyst-review <analyst-review.json>
        --threshold-avg 4.0
        --threshold-min-dim 3

    # Synthesize rewrite instructions for failing competitor files
    python grade_compete_review_loop.py synthesize <run_dir>
        --cso-review <cso-review.json>
        --analyst-review <analyst-review.json>
        --threshold-avg 4.0
        --threshold-min-dim 3

    # Check convergence across iterations
    python grade_compete_review_loop.py converge <run_dir>
        --iterations-dir <reviews_dir>
        --max-iterations 3

    # Full grading (structural + review-loop assertions)
    python grade_compete_review_loop.py grade <run_dir>
        --cso-review <cso-review.json>
        --analyst-review <analyst-review.json>
"""

import json
import sys
from pathlib import Path


# --- Dimension lists ---

CSO_DIMENSIONS = [
    "quota_impact", "pipeline_acceleration", "objection_handling",
    "competitive_win_ability", "account_team_usability", "deal_qualification_signal",
]

ANALYST_DIMENSIONS = [
    "market_landscape_accuracy", "positioning_validity", "strength_weakness_balance",
    "differentiation_defensibility", "trap_question_sophistication", "segment_relevance",
]

# --- Feedback synthesis: map reviewer dimensions to compete entity fields ---

CSO_TO_COMPETE = {
    "competitive_win_ability": [("competitors", "differentiation")],
    "objection_handling": [("trap_questions", "sophistication")],
    "quota_impact": [("competitors", "positioning")],
    "pipeline_acceleration": [("trap_questions", "urgency")],
    "account_team_usability": [("competitors", "strengths"), ("competitors", "weaknesses")],
    "deal_qualification_signal": [("competitors", "positioning")],
}

ANALYST_TO_COMPETE = {
    "market_landscape_accuracy": [("competitors", "selection")],
    "positioning_validity": [("competitors", "positioning")],
    "strength_weakness_balance": [("competitors", "strengths"), ("competitors", "weaknesses")],
    "differentiation_defensibility": [("competitors", "differentiation")],
    "trap_question_sophistication": [("trap_questions", "quality")],
    "segment_relevance": [("competitors", "selection"), ("competitors", "positioning")],
}


def load_json(path: Path) -> dict:
    with open(path) as f:
        return json.load(f)


def save_json(path: Path, data: dict):
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def score_compete(cso_review: dict, analyst_review: dict) -> dict:
    """Score a compete entity based on both reviewer outputs."""
    cso_scores = cso_review.get("dimension_scores", {})
    analyst_scores = analyst_review.get("dimension_scores", {})

    cso_vals = [cso_scores[d]["score"] for d in CSO_DIMENSIONS if d in cso_scores]
    analyst_vals = [
        analyst_scores[d]["score"]
        for d in ANALYST_DIMENSIONS
        if d in analyst_scores and analyst_scores[d]["score"] is not None
    ]

    cso_avg = sum(cso_vals) / len(cso_vals) if cso_vals else 0
    analyst_avg = sum(analyst_vals) / len(analyst_vals) if analyst_vals else 0
    combined_avg = (cso_avg + analyst_avg) / 2

    all_scores = cso_vals + analyst_vals
    min_dim = min(all_scores) if all_scores else 0

    return {
        "cso_avg": round(cso_avg, 2),
        "analyst_avg": round(analyst_avg, 2),
        "combined_avg": round(combined_avg, 2),
        "min_dim": min_dim,
        "cso_scores": {d: cso_scores[d]["score"] for d in CSO_DIMENSIONS if d in cso_scores},
        "analyst_scores": {
            d: analyst_scores[d]["score"]
            for d in ANALYST_DIMENSIONS
            if d in analyst_scores and analyst_scores[d]["score"] is not None
        },
        "would_use_in_pitch_deck": cso_review.get("would_use_in_pitch_deck", False),
        "would_use_in_advisory_report": analyst_review.get("would_use_in_advisory_report", False),
    }


def compete_passes(scores: dict, threshold_avg: float, threshold_min_dim: int) -> bool:
    """Check if a compete entity meets all thresholds."""
    return (
        scores["cso_avg"] >= threshold_avg
        and scores["analyst_avg"] >= threshold_avg
        and scores["min_dim"] >= threshold_min_dim
        and scores["would_use_in_pitch_deck"]
        and scores["would_use_in_advisory_report"]
    )


def synthesize_feedback(
    slug: str, cso_review: dict, analyst_review: dict, scores: dict, threshold_min_dim: int
) -> dict:
    """Synthesize CSO + Analyst feedback into competitor-researcher rewrite format.

    Returns a compete-specific assessment dict with rewrite instructions per field.
    """
    cso_scores_data = cso_review.get("dimension_scores", {})
    analyst_scores_data = analyst_review.get("dimension_scores", {})

    # Collect issues from both reviewers
    cso_issues = [
        i for i in cso_review.get("top_issues", []) if i.get("entity_slug") == slug
    ]
    analyst_issues = [
        i for i in analyst_review.get("top_issues", []) if i.get("entity_slug") == slug
    ]

    # Build compete-specific rewrite instructions
    competitor_issues = []
    trap_question_issues = []
    missing_competitors = []

    def score_to_severity(score_val: int, threshold: int) -> str:
        if score_val >= 4:
            return "ok"
        elif score_val >= threshold:
            return "warn"
        else:
            return "fail"

    # Map CSO failing dimensions to compete fields
    for cso_dim, mappings in CSO_TO_COMPETE.items():
        if cso_dim not in cso_scores_data:
            continue
        raw_score = cso_scores_data[cso_dim]["score"]
        severity = score_to_severity(raw_score, threshold_min_dim)
        if severity == "ok":
            continue
        rationale = cso_scores_data[cso_dim].get("rationale", "")

        for target_entity, target_field in mappings:
            issue = {
                "source": f"CSO.{cso_dim}",
                "score": raw_score,
                "severity": severity,
                "rationale": rationale,
                "target_field": target_field,
            }
            if target_entity == "trap_questions":
                trap_question_issues.append(issue)
            else:
                competitor_issues.append(issue)

    # Map Analyst failing dimensions to compete fields
    for analyst_dim, mappings in ANALYST_TO_COMPETE.items():
        if analyst_dim not in analyst_scores_data:
            continue
        raw_score = analyst_scores_data[analyst_dim]["score"]
        severity = score_to_severity(raw_score, threshold_min_dim)
        if severity == "ok":
            continue
        rationale = analyst_scores_data[analyst_dim].get("rationale", "")

        for target_entity, target_field in mappings:
            issue = {
                "source": f"Analyst.{analyst_dim}",
                "score": raw_score,
                "severity": severity,
                "rationale": rationale,
                "target_field": target_field,
            }
            if target_entity == "trap_questions":
                trap_question_issues.append(issue)
            else:
                competitor_issues.append(issue)

    # Extract missing competitor suggestions from analyst issues
    for issue in analyst_issues:
        if "missing" in issue.get("issue", "").lower() or issue.get("root_cause_hint", "") == "competitor-researcher search scope":
            missing_competitors.append(issue.get("suggested_fix", issue.get("issue", "")))

    # Collect specific issues with suggested fixes
    specific_issues = []
    for issue in cso_issues + analyst_issues:
        specific_issues.append({
            "source": "CSO" if issue in cso_issues else "Analyst",
            "issue": issue.get("issue", ""),
            "severity": issue.get("severity", "medium"),
            "suggested_fix": issue.get("suggested_fix", ""),
            "root_cause_hint": issue.get("root_cause_hint", ""),
        })

    return {
        "slug": slug,
        "competitor_issues": competitor_issues,
        "trap_question_issues": trap_question_issues,
        "missing_competitors": missing_competitors,
        "specific_issues": specific_issues,
        "scores": scores,
    }


def cmd_score(run_dir: Path, cso_path: Path, analyst_path: Path, threshold_avg: float, threshold_min_dim: int):
    """Score compete entities and write results."""
    cso = load_json(cso_path)
    analyst = load_json(analyst_path)

    scores = score_compete(cso, analyst)
    passes = compete_passes(scores, threshold_avg, threshold_min_dim)

    result = {
        "scores": scores,
        "passes": passes,
        "threshold_avg": threshold_avg,
        "threshold_min_dim": threshold_min_dim,
    }

    out_path = run_dir / "review-scores.json"
    save_json(out_path, result)
    print(f"CSO avg: {scores['cso_avg']}, Analyst avg: {scores['analyst_avg']}, combined: {scores['combined_avg']}")
    print(f"Min dimension: {scores['min_dim']}")
    print(f"Would use in pitch deck: {scores['would_use_in_pitch_deck']}")
    print(f"Would use in advisory report: {scores['would_use_in_advisory_report']}")
    print(f"Overall: {'PASS' if passes else 'FAIL'}")
    return result


def cmd_synthesize(run_dir: Path, cso_path: Path, analyst_path: Path, threshold_avg: float, threshold_min_dim: int):
    """Synthesize rewrite instructions for failing compete entities."""
    cso = load_json(cso_path)
    analyst = load_json(analyst_path)

    scores = score_compete(cso, analyst)
    passes = compete_passes(scores, threshold_avg, threshold_min_dim)

    if passes:
        print("All compete entities pass — no rewrites needed.")
        return []

    # Collect slugs that need work from top_issues
    failing_slugs = set()
    for issue in cso.get("top_issues", []) + analyst.get("top_issues", []):
        if issue.get("severity") in ("high", "critical"):
            slug = issue.get("entity_slug", "")
            if slug:
                failing_slugs.add(slug)

    # If no specific slugs found but overall fails, use a generic slug
    if not failing_slugs:
        failing_slugs.add("all")

    rewrite_instructions = []
    for slug in failing_slugs:
        feedback = synthesize_feedback(slug, cso, analyst, scores, threshold_min_dim)
        rewrite_instructions.append(feedback)

    out_path = run_dir / "rewrite-instructions.json"
    save_json(out_path, rewrite_instructions)
    print(f"Generated rewrite instructions for {len(rewrite_instructions)} compete entities: {list(failing_slugs)}")
    return rewrite_instructions


def cmd_converge(run_dir: Path, iterations_dir: Path, max_iterations: int):
    """Check convergence across iterations."""
    iteration_scores = []
    for i in range(max_iterations):
        scores_path = iterations_dir / f"iteration-{i}" / "review-scores.json"
        if scores_path.exists():
            data = load_json(scores_path)
            iteration_scores.append({
                "iteration": i,
                "combined_avg": data["scores"]["combined_avg"],
                "cso_avg": data["scores"]["cso_avg"],
                "analyst_avg": data["scores"]["analyst_avg"],
                "min_dim": data["scores"]["min_dim"],
                "passes": data["passes"],
            })

    if len(iteration_scores) < 2:
        print("Not enough iterations to check convergence.")
        return {"converged": False, "reason": "insufficient_iterations", "iterations": iteration_scores}

    latest = iteration_scores[-1]
    previous = iteration_scores[-2]

    converged = latest["passes"]
    stalled = latest["combined_avg"] <= previous["combined_avg"] and not converged

    result = {
        "converged": converged,
        "stalled": stalled,
        "reason": "passed" if converged else ("stalled" if stalled else "in_progress"),
        "iterations": iteration_scores,
    }

    out_path = run_dir / "convergence.json"
    save_json(out_path, result)

    if converged:
        print(f"Converged at iteration {latest['iteration']} (combined avg: {latest['combined_avg']})")
    elif stalled:
        print(f"Stalled at iteration {latest['iteration']} — no improvement ({latest['combined_avg']} <= {previous['combined_avg']})")
    else:
        delta = latest["combined_avg"] - previous["combined_avg"]
        print(f"Iteration {latest['iteration']}: combined_avg={latest['combined_avg']} (delta: {delta:+.2f})")

    return result


def cmd_grade(run_dir: Path, cso_path: Path, analyst_path: Path, threshold_avg: float = 4.0, threshold_min_dim: int = 3):
    """Generate grading.json with compete review-loop assertions (RL-C* format)."""
    cso = load_json(cso_path)
    analyst = load_json(analyst_path)

    scores = score_compete(cso, analyst)
    expectations = []

    # RL-C01: CSO combined avg >= threshold
    expectations.append({
        "text": f"CSO combined avg >= {threshold_avg} (actual: {scores['cso_avg']})",
        "passed": scores["cso_avg"] >= threshold_avg,
        "evidence": f"CSO avg: {scores['cso_avg']}, dims: {scores['cso_scores']}",
    })

    # RL-C02: Analyst combined avg >= threshold
    expectations.append({
        "text": f"Analyst combined avg >= {threshold_avg} (actual: {scores['analyst_avg']})",
        "passed": scores["analyst_avg"] >= threshold_avg,
        "evidence": f"Analyst avg: {scores['analyst_avg']}, dims: {scores['analyst_scores']}",
    })

    # RL-C03: No dimension below threshold_min_dim
    low_dims = []
    for dim, val in scores["cso_scores"].items():
        if val < threshold_min_dim:
            low_dims.append(f"CSO.{dim}={val}")
    for dim, val in scores["analyst_scores"].items():
        if val < threshold_min_dim:
            low_dims.append(f"Analyst.{dim}={val}")
    expectations.append({
        "text": f"No dimension below {threshold_min_dim} from either reviewer",
        "passed": len(low_dims) == 0,
        "evidence": f"Low dims: {low_dims}" if low_dims else "All dimensions >= threshold",
    })

    # RL-C04: CSO would_use_in_pitch_deck
    expectations.append({
        "text": "CSO would_use_in_pitch_deck is true",
        "passed": scores["would_use_in_pitch_deck"],
        "evidence": f"would_use_in_pitch_deck: {scores['would_use_in_pitch_deck']}",
    })

    # RL-C05: Analyst would_use_in_advisory_report
    expectations.append({
        "text": "Analyst would_use_in_advisory_report is true",
        "passed": scores["would_use_in_advisory_report"],
        "evidence": f"would_use_in_advisory_report: {scores['would_use_in_advisory_report']}",
    })

    # Check for convergence data
    convergence_path = run_dir / "convergence.json"
    if convergence_path.exists():
        conv = load_json(convergence_path)
        # Handle multiple convergence.json formats:
        # Format 1 (grading script): {"converged": true, "reason": "passed", "iterations": [...]}
        # Format 2 (agent-generated): {"iterations": [...], "convergence_path": "...", "total_iterations_used": N}
        if "converged" in conv:
            converged = conv["converged"]
            reason = conv.get("reason", "unknown")
            iters = conv.get("iterations", [])
        else:
            # Agent format: check if last iteration has converged=true
            iters = conv.get("iterations", [])
            converged = any(it.get("converged", False) for it in iters) if iters else False
            if not converged and conv.get("all_thresholds_met"):
                converged = True
            reason = "passed" if converged else "in_progress"
        expectations.append({
            "text": "Loop converged within max_iterations",
            "passed": converged,
            "evidence": f"Reason: {reason}, iterations: {len(iters)}",
        })

    # Check if any rewrite happened (look for iteration-2+ dirs or rewrite-instructions.json)
    rewrite_path = run_dir / "rewrite-instructions.json"
    iteration_2_dir = run_dir / "iteration-2"
    if rewrite_path.exists() or iteration_2_dir.exists():
        if rewrite_path.exists():
            rewrites = load_json(rewrite_path)
            rewrite_count = len(rewrites)
        else:
            # Count iteration directories beyond iteration-1
            rewrite_count = sum(1 for d in run_dir.iterdir() if d.is_dir() and d.name.startswith("iteration-") and d.name != "iteration-1")
        expectations.append({
            "text": "At least one competitor file was rewritten (loop exercised)",
            "passed": rewrite_count > 0,
            "evidence": f"{rewrite_count} rewrite iteration(s) detected",
        })

    total = len(expectations)
    passed = sum(1 for e in expectations if e["passed"])

    grading = {
        "total_checks": total,
        "passed": passed,
        "failed": total - passed,
        "pass_rate": round(passed / total, 3) if total > 0 else 0,
        "expectations": expectations,
        "review_scores": scores,
    }

    grading_path = run_dir / "grading-review-loop.json"
    save_json(grading_path, grading)
    print(f"Compete review loop grading: {passed}/{total} passed ({grading['pass_rate']:.1%})")

    failures = [e for e in expectations if not e["passed"]]
    if failures:
        print(f"\nFailures ({len(failures)}):")
        for f in failures:
            print(f"  {f['text']}: {f['evidence']}")

    return grading


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    command = sys.argv[1]
    run_dir = Path(sys.argv[2])

    # Parse optional args
    args = {}
    i = 3
    while i < len(sys.argv):
        if sys.argv[i].startswith("--"):
            key = sys.argv[i].lstrip("-").replace("-", "_")
            if i + 1 < len(sys.argv) and not sys.argv[i + 1].startswith("--"):
                args[key] = sys.argv[i + 1]
                i += 2
            else:
                args[key] = True
                i += 1
        else:
            i += 1

    cso_path = Path(args.get("cso_review", "")) if "cso_review" in args else None
    analyst_path = Path(args.get("analyst_review", "")) if "analyst_review" in args else None
    threshold_avg = float(args.get("threshold_avg", 4.0))
    threshold_min_dim = int(args.get("threshold_min_dim", 3))

    if command == "score":
        if not cso_path or not analyst_path:
            print("score requires --cso-review and --analyst-review")
            sys.exit(1)
        cmd_score(run_dir, cso_path, analyst_path, threshold_avg, threshold_min_dim)

    elif command == "synthesize":
        if not cso_path or not analyst_path:
            print("synthesize requires --cso-review and --analyst-review")
            sys.exit(1)
        cmd_synthesize(run_dir, cso_path, analyst_path, threshold_avg, threshold_min_dim)

    elif command == "converge":
        iterations_dir = Path(args.get("iterations_dir", str(run_dir / "reviews")))
        max_iterations = int(args.get("max_iterations", 3))
        cmd_converge(run_dir, iterations_dir, max_iterations)

    elif command == "grade":
        if not cso_path or not analyst_path:
            print("grade requires --cso-review and --analyst-review")
            sys.exit(1)
        cmd_grade(run_dir, cso_path, analyst_path, threshold_avg, threshold_min_dim)

    else:
        print(f"Unknown command: {command}")
        print("Available: score, synthesize, converge, grade")
        sys.exit(1)


if __name__ == "__main__":
    main()

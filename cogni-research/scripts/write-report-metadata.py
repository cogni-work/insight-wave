#!/usr/bin/env python3
"""
write-report-metadata.py - Write deterministic Report-Metadaten footer.

Replaces any existing free-form metadata footer in output/report.md with a
deterministic block sourced from the revisor agent's YAML `model:` field,
the project's execution-log iteration count, and system time.

Usage:
    write-report-metadata.py --project-path PATH --target-file PATH [--revisor-agent-path PATH]

All output is JSON on stdout: {"success": bool, "data": {...}, "error": "..."}
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import sys
from pathlib import Path

MODEL_DISPLAY = {
    "sonnet": "Claude Sonnet 4.5",
    "opus": "Claude Opus 4.6",
    "haiku": "Claude Haiku 4.5",
    "inherit": "Claude (inherited from caller)",
}

GERMAN_MONTHS = [
    "Januar", "Februar", "März", "April", "Mai", "Juni",
    "Juli", "August", "September", "Oktober", "November", "Dezember",
]

ENGLISH_MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]

FOOTER_PATTERN = re.compile(
    r"\n*\*\*(?:Report-Metadaten|Report Metadata)\*\*:.*?(?=\n\n|\Z)",
    re.DOTALL,
)


def parse_yaml_model(agent_path: Path) -> str:
    """Extract the `model:` field from a YAML frontmatter block. Returns the short name."""
    text = agent_path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        raise ValueError(f"{agent_path} has no YAML frontmatter")
    end = text.find("\n---", 3)
    if end < 0:
        raise ValueError(f"{agent_path} frontmatter is not terminated")
    frontmatter = text[3:end]
    for line in frontmatter.splitlines():
        line = line.strip()
        if line.startswith("model:"):
            return line.split(":", 1)[1].strip()
    raise ValueError(f"{agent_path} frontmatter has no model: field")


def read_iteration_count(project_path: Path) -> int:
    """Read phase_5_review.iteration_count from execution-log.json. Default 1."""
    log_path = project_path / ".metadata" / "execution-log.json"
    if not log_path.exists():
        return 1
    try:
        log = json.loads(log_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return 1
    phases = log.get("phases", {})
    phase_5 = phases.get("phase_5_review", {})
    count = phase_5.get("iteration_count")
    if isinstance(count, int) and count >= 1:
        return count
    return 1


def read_output_language(project_path: Path) -> str:
    """Read output_language from project-config.json. Default 'en'."""
    config_path = project_path / "project-config.json"
    if not config_path.exists():
        return "en"
    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return "en"
    return str(config.get("output_language") or "en").lower()


def format_date(lang: str) -> str:
    today = datetime.date.today()
    if lang.startswith("de"):
        return f"{today.day}. {GERMAN_MONTHS[today.month - 1]} {today.year}"
    if lang.startswith("en"):
        return f"{ENGLISH_MONTHS[today.month - 1]} {today.day}, {today.year}"
    return today.isoformat()


def compose_footer(model_display: str, iteration: int, date_str: str, lang: str) -> str:
    if lang.startswith("de"):
        return (
            "\n\n**Report-Metadaten**:\n"
            f"- Verfasser: {model_display} (cogni-research Revisor Agent)\n"
            f"- Berichtsdatum: {date_str}\n"
            f"- Revisions-Iteration: {iteration}\n"
        )
    return (
        "\n\n**Report Metadata**:\n"
        f"- Author: {model_display} (cogni-research Revisor Agent)\n"
        f"- Report Date: {date_str}\n"
        f"- Revision Iteration: {iteration}\n"
    )


def strip_existing_footer(text: str) -> str:
    stripped = FOOTER_PATTERN.sub("", text)
    return stripped.rstrip() + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Write deterministic Report-Metadaten footer to a research report.",
    )
    parser.add_argument("--project-path", required=True, help="Absolute path to research project directory")
    parser.add_argument("--target-file", required=True, help="Markdown file to update (typically output/report.md)")
    parser.add_argument(
        "--revisor-agent-path",
        default=None,
        help="Path to revisor.md (default: $CLAUDE_PLUGIN_ROOT/agents/revisor.md)",
    )
    args = parser.parse_args()

    try:
        project_path = Path(args.project_path).resolve()
        target_file = Path(args.target_file).resolve()

        if args.revisor_agent_path:
            revisor_path = Path(args.revisor_agent_path).resolve()
        else:
            plugin_root = os.environ.get("CLAUDE_PLUGIN_ROOT")
            if not plugin_root:
                script_dir = Path(__file__).resolve().parent
                plugin_root = str(script_dir.parent)
            revisor_path = Path(plugin_root) / "agents" / "revisor.md"

        if not target_file.exists():
            raise FileNotFoundError(f"target file not found: {target_file}")
        if not revisor_path.exists():
            raise FileNotFoundError(f"revisor agent not found: {revisor_path}")

        model_short = parse_yaml_model(revisor_path)
        model_display = MODEL_DISPLAY.get(model_short.lower(), f"Claude {model_short.capitalize()}")
        iteration = read_iteration_count(project_path)
        lang = read_output_language(project_path)
        date_str = format_date(lang)
        footer = compose_footer(model_display, iteration, date_str, lang)

        original = target_file.read_text(encoding="utf-8")
        stripped = strip_existing_footer(original)
        updated = stripped + footer
        target_file.write_text(updated, encoding="utf-8")

        print(json.dumps({
            "success": True,
            "data": {
                "model_short": model_short,
                "model_display": model_display,
                "iteration": iteration,
                "date": date_str,
                "language": lang,
                "target_file": str(target_file),
                "footer_replaced": stripped != original.rstrip() + "\n",
            },
            "error": None,
        }))
        return 0
    except Exception as exc:  # noqa: BLE001
        print(json.dumps({
            "success": False,
            "data": None,
            "error": f"{type(exc).__name__}: {exc}",
        }), file=sys.stdout)
        return 1


if __name__ == "__main__":
    sys.exit(main())

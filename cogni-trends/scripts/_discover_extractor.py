"""Per-project field extractor for cogni-trends discover-projects.sh.

Loaded by cogni-workspace/scripts/discover-plugin-projects.sh. Must define
``extract(project_dir: str) -> dict`` returning the per-project JSON envelope.
"""

import json
import os


def extract(d: str) -> dict:
    project = {"path": d, "slug": os.path.basename(d)}

    pf = os.path.join(d, "tips-project.json")
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            project["slug"] = data.get("slug", project["slug"])
            project["language"] = data.get("language", "en")
            ind = data.get("industry", {})
            project["industry"] = ind.get("primary_en") or ind.get("primary") or ""
            project["subsector"] = ind.get("subsector_en") or ind.get("subsector") or ""
            project["research_topic"] = data.get("research_topic") or ""
            project["updated"] = data.get("updated", data.get("created", ""))
        except Exception:
            pass

    sf = os.path.join(d, ".metadata", "trend-scout-output.json")
    if os.path.exists(sf):
        try:
            data = json.load(open(sf))
            exe = data.get("execution", {})
            project["workflow_state"] = exe.get("workflow_state", "unknown")
            project["candidates_total"] = data.get("tips_candidates", {}).get("total", 0)
            if not project.get("industry"):
                ind = data.get("config", {}).get("industry", {})
                project["industry"] = ind.get("primary_en") or ind.get("primary") or ""
                project["subsector"] = ind.get("subsector_en") or ind.get("subsector") or ""
            if not project.get("research_topic"):
                project["research_topic"] = data.get("config", {}).get("research_topic") or ""
            if not project.get("language"):
                project["language"] = data.get("project_language", "en")
        except Exception:
            project.setdefault("workflow_state", "unknown")
            project.setdefault("candidates_total", 0)

    # has_report is the canonical TIPS report (tips-trend-report.md, owned by
    # trend-synthesis); has_research and has_booklet are siblings introduced
    # in cogni-trends 0.6.0.
    project["has_research"] = os.path.exists(os.path.join(d, ".metadata", "trend-research-output.json"))
    project["has_report"] = os.path.exists(os.path.join(d, "tips-trend-report.md"))
    project["has_booklet"] = os.path.exists(os.path.join(d, "tips-trend-booklet.md"))

    return project

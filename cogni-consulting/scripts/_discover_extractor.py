"""Per-engagement field extractor for cogni-consulting discover-projects.sh.

Loaded by cogni-workspace/scripts/discover-plugin-projects.sh. Must define
``extract(project_dir: str) -> dict`` returning the per-engagement JSON envelope.
"""

import json
import os

PHASES = ("discover", "define", "develop", "deliver")


def extract(d: str) -> dict:
    project = {"path": d, "slug": os.path.basename(d)}

    pf = os.path.join(d, "consulting-project.json")
    if os.path.exists(pf):
        try:
            data = json.load(open(pf))
            eng = data.get("engagement", {}) or {}
            project["slug"] = eng.get("slug", project["slug"])
            project["name"] = eng.get("name", "")
            project["client"] = eng.get("client", "")
            project["vision_class"] = eng.get("vision_class", "")
            project["industry"] = eng.get("industry", "")
            project["language"] = eng.get("language", "en")
            project["current_phase"] = data.get("current_phase", "")
            phases = data.get("phases", {}) or {}
            project["phase_status"] = {
                ph: (phases.get(ph, {}) or {}).get("status", "pending")
                for ph in PHASES
            }
            project["updated"] = data.get("updated_at", data.get("created_at", ""))
        except Exception:
            pass

    return project

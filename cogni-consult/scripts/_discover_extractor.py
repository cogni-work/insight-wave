"""Per-engagement field extractor for cogni-consult discover-projects.sh.

Loaded by cogni-workspace/scripts/discover-plugin-projects.sh. Must define
``extract(project_dir: str) -> dict`` returning the per-engagement JSON envelope.

cogni-consult's consult-project.json is FLAT (slug/name/language/key_question/
workflow_state/plugin_refs/updated at top level) — unlike a legacy
nested engagement{}/phases{} schema. There are no phases here: the engagement's
shape is its action fields, so the envelope carries the scope state and the
ordered action-field list instead of a phase map.
"""

import json
import os


def extract(d: str) -> dict:
    project = {"path": d, "slug": os.path.basename(d)}

    pf = os.path.join(d, "consult-project.json")
    if os.path.exists(pf):
        try:
            with open(pf) as f:
                data = json.load(f)
            project["slug"] = data.get("slug", project["slug"])
            project["name"] = data.get("name", "")
            project["language"] = data.get("language", "en")
            project["key_question"] = data.get("key_question", "")
            project["action_fields"] = data.get("action_fields", [])
            project["scope_state"] = (data.get("workflow_state") or {}).get(
                "scope", "pending"
            )
            project["plugin_refs"] = data.get("plugin_refs", {})
            project["updated"] = data.get("updated", data.get("created", ""))
        except Exception:
            pass

    return project

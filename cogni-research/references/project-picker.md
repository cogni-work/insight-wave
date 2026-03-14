# Project Picker Pattern

Shared reference for interactive project selection in deeper-research-1/2/3 skills.

**Parameters:**
- `prerequisite_flag` — sprint-log key that must be `true` (e.g., `planning_complete`, `discovery_complete`, `enrichment_complete`)
- `prerequisite_skill` — skill name to recommend if no eligible projects found (e.g., `deeper-research-0`)

---

## Step 1: Check for Explicit Project Path

If the user provided `--project-path` as an argument, use it directly and skip to the entry gate:

```bash
if [ -n "${PROJECT_PATH:-}" ]; then
  project_path="${PROJECT_PATH}"
  echo "Using provided project path: ${project_path}"
  # Skip to entry gate
fi
```

If `--project-path` was NOT provided, continue to Step 2.

---

## Step 2: Discover All Projects

Run the project discovery script to enumerate all research projects:

```bash
discovery_json=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/discover-projects.sh" --json)

# Check discovery succeeded
if [ "$(echo "$discovery_json" | jq -r '.success')" != "true" ]; then
  echo "ERROR: Project discovery failed: $(echo "$discovery_json" | jq -r '.error')" >&2
  exit 1
fi

project_count=$(echo "$discovery_json" | jq '.projects | length')
echo "Discovered ${project_count} project(s)"
```

---

## Step 3: Filter by Prerequisite Flag

Filter discovered projects to only those where the required prerequisite flag is `true` in their sprint-log.json:

```bash
eligible_projects="[]"

for row in $(echo "$discovery_json" | jq -c '.projects[]'); do
  path=$(echo "$row" | jq -r '.path')
  sprint_log="${path}/.metadata/sprint-log.json"

  if [ -f "$sprint_log" ]; then
    flag_value=$(jq -r ".${prerequisite_flag} // false" "$sprint_log")
    if [ "$flag_value" = "true" ]; then
      eligible_projects=$(echo "$eligible_projects" | jq --argjson proj "$row" '. + [$proj]')
    fi
  fi
done

eligible_count=$(echo "$eligible_projects" | jq 'length')
```

---

## Step 4: Branch on Eligible Count

### 4a: Zero Eligible Projects

```
ERROR: No projects found with ${prerequisite_flag}=true.
Run ${prerequisite_skill} first to prepare a project for this phase.
```

**STOP execution.** Do not proceed to the entry gate.

### 4b: Exactly One Eligible Project

Auto-select the single eligible project. Inform the user which project was selected:

```bash
project_path=$(echo "$eligible_projects" | jq -r '.[0].path')
project_name=$(echo "$eligible_projects" | jq -r '.[0].name')
echo "Auto-selected project: ${project_name} (${project_path})"
```

Proceed to entry gate.

### 4c: Two or More Eligible Projects

Present options to the user via `AskUserQuestion`:

- **Question:** "Multiple research projects are ready. Which project should be used?"
- **Header:** "Project"
- **Options:** For each eligible project, build an option with:
  - **Label:** `{project_name}`
  - **Description:** `Type: {research_type} | Language: {project_language} | Path: {path}`

Set `project_path` to the selected project's path and proceed to entry gate.

---

## Output

After project selection completes, the `project_path` variable is set and validated. The calling skill then proceeds to its entry gate checks using this path.

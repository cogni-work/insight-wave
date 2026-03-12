---
name: copy-json
version: 1.0
description: Adapter skill that polishes text fields inside JSON files by extracting them, delegating to the copywriter skill for polishing, and writing the polished text back. Use when the user wants to polish, improve, or copywrite text inside a JSON file — plugin descriptions, IS/DOES/MEANS propositions, category names, claim statements, or any string fields in structured JSON data. Triggers include "polish JSON", "copywrite marketplace.json", "improve descriptions in plugin.json", "polish fields in JSON", or any /copywrite invocation targeting a .json file with --fields.
allowed-tools: Read, Write, Edit, Bash, Skill
---

# Copy-JSON Skill

Adapter that bridges JSON files to the copywriter skill. Extracts text fields from JSON, builds a temporary markdown file with field delimiters, delegates polishing to the copywriter skill, parses polished text back, and updates the JSON file.

## Parameters

| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| `FILE_PATH` | yes | — | Absolute path to `.json` file |
| `FIELDS` | yes | — | Dot-path field selector (e.g. `plugins[*].description`) |
| `SCOPE` | no | `tone` | Passed to copywriter (`tone` is the right default for short JSON text) |
| `MODE` | no | `standard` | `sales` for IS/DOES/MEANS fields |
| `DRY_RUN` | no | `false` | Show before/after without writing |

## FIELDS Selector Syntax

Simple dot-path with `[*]` for arrays:
- `description` — single root field
- `plugins[*].description` — description of every plugin in array
- `[*].dimension_name` — field in root-level array
- `plugins[*].description,plugins[*].keywords` — comma-separated multi-field

## Workflow

### Step 1: Parse & Extract

1. Validate FILE_PATH exists and has `.json` extension
2. Read JSON file and parse it
3. Parse FIELDS selector — split on commas, then resolve each dot-path:
   - Split path on `.` into segments
   - For segments containing `[*]`, iterate over all array elements
   - Collect each matching value with its concrete JSON path (e.g. `plugins[0].description`)
4. Skip non-string values silently
5. Skip strings shorter than 10 characters (nothing meaningful to polish)
6. If zero fields match after filtering, report error:
   ```
   ERROR: No matching string fields found for selector "{FIELDS}" in {FILE_PATH}

   Possible causes:
   - Field path does not exist in the JSON structure
   - All matching values are non-strings or shorter than 10 characters

   Tip: Use a JSON viewer to inspect the file structure, then retry with corrected --fields
   ```

### Step 2: Build Temp MD & Invoke Copywriter

1. Assemble extracted texts into a single temporary markdown file with field delimiters:
   ```markdown
   <!-- COPY-JSON SOURCE: {FILE_PATH} -->
   <!-- FIELDS: {FIELDS} -->

   <!-- FIELD: plugins[0].description -->
   Claim verification and management system. Verifies sourced claims against primary documents...

   <!-- FIELD: plugins[1].description -->
   Obsidian integration for Claude Code workplaces. Syncs vault structure...
   ```

2. Write to `{dir}/.{basename}.copywrite-tmp.md` where `{dir}` is the directory of FILE_PATH and `{basename}` is the JSON filename without extension

3. Invoke the copywriter skill:
   ```
   Skill: cogni-copywriting:copywriter

   FILE_PATH = {path to temp MD}
   SCOPE = {SCOPE parameter, default: tone}
   ```

   Additional instructions to copywriter:
   - Preserve all `<!-- FIELD: ... -->` comment delimiters exactly as-is
   - Each field is an independent text snippet — do not merge or reorder them
   - These are JSON string values — do NOT add markdown formatting (no `**bold**`, `# headings`, `- lists`)
   - Keep each field as a single paragraph unless the original has line breaks
   - If MODE=sales: apply IS/DOES/MEANS sales messaging techniques (Power Positions, FAB)

4. Wait for copywriter skill completion

### Step 3: Parse Back & Validate

1. Read the polished temp MD file
2. Split content by `<!-- FIELD: ... -->` delimiters to recover per-field text
3. For each extracted field, trim whitespace and validate:
   - **German chars preserved**: ä, ö, ü, ß and uppercase forms still present if they were in original
   - **No markdown injection**: reject if polished text contains `**`, `__`, `# `, `- ` list markers, or `| table |` syntax (these don't belong in JSON string values)
   - **Length guard**: polished text must not exceed 2x length of original (prevents prose expansion)
   - **Citations preserved**: if original contained `[P1-1]` or similar citation markers, they must still be present
4. If any validation fails, keep original text for that field and log a warning
5. Delete the temp MD file

### Step 4: Write & Report

1. **Backup**: Copy FILE_PATH to `{dir}/.{basename}.pre-copy-json.json`
2. Read the original JSON file fresh (to avoid stale data)
3. For each validated polished field, update the value at its concrete JSON path
4. Write the updated JSON back to FILE_PATH, preserving original indentation (detect indent from file: typically 2 or 4 spaces)
5. If `DRY_RUN=true`: show the before/after diff for each field WITHOUT writing to the JSON file, then skip the backup and write steps

6. Return summary:
   ```
   **JSON Copywriting Complete**: {basename}.json

   **Fields polished**: {count} of {total_matched}

   | Field | Before (truncated) | After (truncated) |
   |-------|--------------------|-------------------|
   | plugins[0].description | Original text here... | Polished text here... |
   | plugins[1].description | Original text here... | Polished text here... |

   **Backup**: .{basename}.pre-copy-json.json

   **Next step**: Review the changes with `git diff {basename}.json`
   ```

## Error Handling

### File Not Found
```
ERROR: File not found: {FILE_PATH}

Usage: /copywrite <file.json> --fields="<selector>"
Example: /copywrite marketplace.json --fields="plugins[*].description"
```

### Not a JSON File
```
ERROR: copy-json skill requires a .json file, got: {extension}

For markdown files, use the copywriter skill directly:
  /copywrite document.md
```

### Missing FIELDS Parameter
```
ERROR: --fields parameter is required for JSON files

Usage: /copywrite <file.json> --fields="<selector>"

Examples:
  --fields="description"                    Single field
  --fields="plugins[*].description"         Array field
  --fields="*.IS,*.DOES,*.MEANS"           Multiple fields
```

### Invalid JSON
```
ERROR: Failed to parse {FILE_PATH} as valid JSON

Details: {parse_error}

Ensure the file contains valid JSON before running copy-json.
```

### Copywriter Skill Failure
```
ERROR: Copywriter skill failed during polishing

Details: {error}

The original JSON file has not been modified.
Troubleshooting:
1. Check that cogni-copywriting plugin is installed
2. Verify the temp MD file was created at {tmp_path}
3. Try polishing the temp MD manually: /copywrite {tmp_path}
```

## JSON Path Resolution

### Algorithm for resolving `plugins[*].description`:

```
FUNCTION resolve(json, path_segments, current_path=""):
  IF path_segments is empty:
    IF json is string AND length >= 10:
      RETURN [(current_path, json)]
    ELSE:
      RETURN []

  segment = path_segments[0]
  remaining = path_segments[1:]

  IF segment contains "[*]":
    key = segment before "[*]"
    array = json[key] if key else json
    results = []
    FOR i, item IN enumerate(array):
      concrete = current_path + key + "[" + i + "]"
      results += resolve(item, remaining, concrete + ".")
    RETURN results
  ELSE:
    RETURN resolve(json[segment], remaining, current_path + segment + ".")
```

### Algorithm for writing back:

```
FUNCTION write_back(json, concrete_path, value):
  segments = parse_concrete_path(concrete_path)
  # e.g. "plugins[0].description" → ["plugins", 0, "description"]

  target = json
  FOR segment IN segments[:-1]:
    target = target[segment]
  target[segments[-1]] = value
```

## Integration

**Skills Used:**
- **copywriter** — Handles all text polishing (tone, structure, messaging frameworks). Copy-json never polishes text itself — it only handles JSON↔MD format conversion.

**Delegation Pattern:**
1. copy-json extracts text from JSON → builds temp MD
2. copywriter polishes the temp MD using its full pipeline
3. copy-json parses polished MD → writes back to JSON

This adapter pattern means copy-json benefits from all future copywriter improvements without changes.

# Phase 3: Megatrend Clustering

Perform cross-dimension semantic analysis to identify megatrend clusters across all findings.

---

## ⛔ Entry Gate

```bash
# Verify Phase 2 completed
if [ ! -f "${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt" ]; then
  echo "Setup incomplete" >&2
  exit 1
fi
```

---

## Step 0.1: Load Project Language and Research Type

Read project language and research type to determine megatrend structure.

**⚠️ ZSH COMPATIBILITY:** Command substitution with jq should work inline, but wrap for consistency.

```bash
cat > /tmp/km-phase3-lang.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null || echo "en")
RESEARCH_TYPE=$(jq -r '.research_type // "generic"' "${PROJECT_PATH}/.metadata/sprint-log.json" 2>/dev/null || echo "generic")

# Determine megatrend structure based on research type
if [ "$RESEARCH_TYPE" = "smarter-service" ]; then
  MEGATREND_STRUCTURE="tips"
else
  MEGATREND_STRUCTURE="generic"
fi

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Project language: ${PROJECT_LANGUAGE}" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Research type: ${RESEARCH_TYPE} -> megatrend_structure: ${MEGATREND_STRUCTURE}" >> "$LOG_FILE"
echo "PROJECT_LANGUAGE=${PROJECT_LANGUAGE}"
echo "RESEARCH_TYPE=${RESEARCH_TYPE}"
echo "MEGATREND_STRUCTURE=${MEGATREND_STRUCTURE}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-lang.sh && bash /tmp/km-phase3-lang.sh "${PROJECT_PATH}"
```

**Megatrend Structure Routing:**

| research_type | megatrend_structure | Content Structure |
|---------------|-----------------|-------------------|
| `smarter-service` | `tips` | TIPS narrative (Trend/Implication/Possibility/Solution, 600-900 words) |
| All others | `generic` | Domain-based (What it is/does/means, 400-600 words) |

### Megatrend Header Translation Map

Use this map to translate megatrend section headings to the project language:

| English (en) | German (de) |
|--------------|-------------|
| Overview | Übersicht |
| Key Themes | Kernthemen |
| Related Findings | Zugehörige Ergebnisse |

**CRITICAL:** All megatrend content (headings, descriptions, overview text, theme descriptions) MUST be generated in `PROJECT_LANGUAGE`. Only filenames, YAML keys, and wikilink paths remain in English/ASCII.

---

## Step 0.2: Load Seed Megatrends (TIPS only)

**Entry Condition:** Only execute if `MEGATREND_STRUCTURE="tips"` (smarter-service research type).

Load seed megatrends to ensure all seeds result in megatrends, with proper finding linkage where mappings exist.

**⚠️ ZSH COMPATIBILITY:** Bash arrays require temp script pattern.

```bash
cat > /tmp/km-phase3-seeds.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
MEGATREND_STRUCTURE="$2"

# Validate PROJECT_PATH to prevent empty path errors
if [[ -z "$PROJECT_PATH" ]]; then
  echo "ERROR: PROJECT_PATH not provided" >&2
  exit 1
fi

LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

# Only load seeds for TIPS research type
if [ "$MEGATREND_STRUCTURE" != "tips" ]; then
  echo "SEEDS_LOADED=false"
  echo "SEED_COUNT=0"
  exit 0
fi

SEED_FILE="${PROJECT_PATH}/.metadata/seed-megatrends.yaml"

if [ ! -f "$SEED_FILE" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] No seed-megatrends.yaml found - using bottom-up only" >> "$LOG_FILE"
  echo "SEEDS_LOADED=false"
  echo "SEED_COUNT=0"
  exit 0
fi

# Check if seeding was skipped by user
skip_seeding=$(grep -E "^skip_megatrend_seeding:" "$SEED_FILE" 2>/dev/null | grep -q "true" && echo "true" || echo "false")
if [ "$skip_seeding" = "true" ]; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Megatrend seeding skipped by user - using bottom-up only" >> "$LOG_FILE"
  echo "SEEDS_LOADED=false"
  echo "SEED_COUNT=0"
  exit 0
fi

# Count Tier 1 seeds (lines with "tier: 1" after a "name:" line)
seed_count=$(grep -c "^  - name:" "$SEED_FILE" 2>/dev/null || echo 0)

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Loaded $seed_count seed megatrends from $SEED_FILE" >> "$LOG_FILE"
echo "SEEDS_LOADED=true"
echo "SEED_COUNT=${seed_count}"

# Initialize tracking files
> /tmp/km-claimed-findings.txt
> /tmp/km-seed-megatrends-created.txt
SCRIPT_EOF
chmod +x /tmp/km-phase3-seeds.sh && bash /tmp/km-phase3-seeds.sh "${PROJECT_PATH}" "${MEGATREND_STRUCTURE}"
```

**Output Variables:**

- `SEEDS_LOADED`: true/false - whether seeds are available
- `SEED_COUNT`: number of Tier 1 seeds loaded

**Tracking Files Initialized:**

- `/tmp/km-claimed-findings.txt`: Finding UUIDs already assigned to seed megatrends
- `/tmp/km-seed-megatrends-created.txt`: Seeds that have been processed into megatrends

**IF `SEEDS_LOADED=false`:** Skip to Step 1 (pure bottom-up clustering).

**IF `SEEDS_LOADED=true`:** Continue to Step 0.3 for seed-first megatrend creation.

---

## Step 0.3: Parse Seed Megatrends (LLM Task)

**Entry Condition:** Only execute if `SEEDS_LOADED=true`.

Read `.metadata/seed-megatrends.yaml` and parse into structured data for processing.

**LLM Execution:** Read the seed file and extract:

```yaml
# For each seed megatrend, extract:
seeds:
  - name: "{Seed Name}"
    keywords: ["{keyword1}", "{keyword2}", ...]
    dimension_affinity: "{dimension-slug}"
    planning_horizon_hint: "{act|plan|observe}"
    validation_mode: "{ensure_covered|must_match|informational}"
```

**Store parsed seeds in memory for Step 0.4 processing.**

---

## Step 0.4: Seed-First Megatrend Creation (TIPS only)

**Entry Condition:** Only execute if `SEEDS_LOADED=true`.

**⛔ CRITICAL:** ALL seeds MUST result in a megatrend - this is the core requirement.

For EACH seed megatrend:

### 0.4.1 Find Matching Findings

Search all findings for keyword matches:

```bash
cat > /tmp/km-phase3-seed-match.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
shift
keywords=("$@")

# Read findings list
findings_list=()
while IFS= read -r line; do
  [ -n "$line" ] && findings_list+=("$line")
done < /tmp/km-findings-list.txt

matched_uuids=""
for finding_file in "${findings_list[@]}"; do
  [ -f "$finding_file" ] || continue

  # Read finding content for keyword matching
  content=$(cat "$finding_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')

  for keyword in "${keywords[@]}"; do
    keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
    if echo "$content" | grep -q "$keyword_lower"; then
      # Extract UUID from filename
      uuid=$(basename "$finding_file" .md | sed 's/^finding-//')
      # Check if not already claimed
      if ! grep -q "^${uuid}$" /tmp/km-claimed-findings.txt 2>/dev/null; then
        matched_uuids+="${uuid}\n"
      fi
      break
    fi
  done
done

# Output unique matched UUIDs
echo -e "$matched_uuids" | sort -u | grep -v '^$'
SCRIPT_EOF
chmod +x /tmp/km-phase3-seed-match.sh
```

### 0.4.2 Determine Source Type and Evidence Strength

| Finding Matches | source_type | evidence_strength |
|-----------------|-------------|-------------------|
| 5+ findings | hybrid | strong |
| 3-4 findings | hybrid | moderate |
| 1-2 findings | hybrid | weak |
| 0 findings | seeded | hypothesis |

### 0.4.3 Create Seed Megatrend Entity

**⛔ MANDATORY:** Create megatrend for EVERY seed, even with 0 finding matches.

Use the TIPS Megatrend Template (3.5b) with these modifications for seed megatrends:

```yaml
---
megatrend_id: "megatrend-{slug}-{hash}"
megatrend_name: "{Seed Name}"
megatrend_structure: "tips"
dc:creator: knowledge-merger
dc:title: "{2-4 word heading from seed name}"
finding_count: {N}  # May be 0 for hypothesis megatrends
finding_refs:
  # ⛔ PASTE matched finding wikilinks here. Every line must start with exactly "  - " (2 spaces + dash + space).
  - "[[04-findings/data/finding-{uuid}]]"
  # OR for hypothesis megatrends with 0 findings:
  # finding_refs: []
created_at: "{ISO 8601 UTC}"
language: "{PROJECT_LANGUAGE}"
tags: [megatrend, seed, dimension/{dimension-slug}, {derived-tag}]
source_type: "{hybrid|seeded}"
seed_name: "{Original Seed Name}"
seed_validated: true
evidence_strength: "{strong|moderate|weak|hypothesis}"
planning_horizon: "{act|plan|observe}"  # From seed planning_horizon_hint
dimension_affinity: "{dimension-slug}"  # From seed
strategic_narrative:
  trend: "{Observable pattern - synthesize from findings OR from seed rationale}"
  implication: "{Strategic significance}"
  possibility:
    overview: "{Opportunity framing}"
    chance: "{Value of acting}"
    risk: "{Cost of not acting}"
  solution: "{Recommended action}"
---
```

**For hypothesis megatrends (0 findings):**

- Generate strategic narrative from seed name, keywords, and LLM knowledge about the megatrend
- Mark clearly as hypothesis in Evidence Base section
- Content should be shorter (300-400 words) with placeholder guidance

### 0.4.4 Track Claimed Findings

After creating each seed megatrend, mark matched findings as claimed:

```bash
# Append matched UUIDs to claimed findings file
echo "${matched_uuid}" >> /tmp/km-claimed-findings.txt

# Track seed as processed
echo "${seed_name}" >> /tmp/km-seed-megatrends-created.txt
```

### 0.4.5 Repeat for All Seeds

**⛔ VERIFICATION:** After processing all seeds:

```bash
cat > /tmp/km-phase3-seed-verify.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
SEED_COUNT="$2"

megatrends_from_seeds=$(wc -l < /tmp/km-seed-megatrends-created.txt 2>/dev/null | tr -d ' ')

if [ "$megatrends_from_seeds" -ne "$SEED_COUNT" ]; then
  echo "ERROR: Created $megatrends_from_seeds megatrends but expected $SEED_COUNT seeds" >&2
  exit 1
fi

echo "seed_megatrends_created=${megatrends_from_seeds}"
echo "claimed_findings=$(wc -l < /tmp/km-claimed-findings.txt 2>/dev/null | tr -d ' ')"
SCRIPT_EOF
chmod +x /tmp/km-phase3-seed-verify.sh && bash /tmp/km-phase3-seed-verify.sh "${PROJECT_PATH}" "${SEED_COUNT}"
```

**⛔ All seeds MUST have created megatrends before proceeding to Step 1.**

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 3.0: Load seeds and create seed megatrends (TIPS only) [in_progress if SEEDS_LOADED]
- Phase 3.1: Load all findings [in_progress]
- Phase 3.2: Bottom-up clustering (unclaimed findings) [pending]
- Phase 3.3: Seed-cluster deduplication [pending]
- Phase 3.4: Create megatrend entities [pending]
```

---

## Step 1: Load All Findings

Load the full corpus of findings (not filtered by dimension).

**⚠️ ZSH COMPATIBILITY:** Bash arrays require temp script pattern.

```bash
cat > /tmp/km-phase3-step1.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 3: Megatrend Clustering: start" >> "$LOG_FILE"

findings_list=()
for f in "${PROJECT_PATH}"/04-findings/data/*.md; do
  [ -f "$f" ] && findings_list+=("$f")
done
findings_count=${#findings_list[@]}

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Loaded $findings_count findings for cross-dimension megatrend clustering" >> "$LOG_FILE"

# Export findings list for subsequent steps
printf '%s\n' "${findings_list[@]}" > /tmp/km-findings-list.txt

# Initialize dimension mapping arrays
> /tmp/km-finding-dim-keys.txt
> /tmp/km-finding-dim-values.txt

echo "findings_count=${findings_count}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-step1.sh && bash /tmp/km-phase3-step1.sh "${PROJECT_PATH}"
```

**Mark 3.1 complete.**

---

## Step 2: Semantic Megatrend Discovery (Bottom-Up Clustering)

Analyze **unclaimed** finding summaries to identify thematic clusters.

**⛔ IMPORTANT (TIPS only):** If `SEEDS_LOADED=true`, exclude findings already claimed by seed megatrends.

**LLM Execution:** This is the core reasoning task.

### 2.0 Filter Unclaimed Findings (TIPS only)

**Entry Condition:** Only execute filtering if `SEEDS_LOADED=true`.

```bash
cat > /tmp/km-phase3-filter-unclaimed.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
SEEDS_LOADED="$2"

if [ "$SEEDS_LOADED" != "true" ]; then
  # No filtering needed - use all findings
  cp /tmp/km-findings-list.txt /tmp/km-unclaimed-findings.txt
  echo "unclaimed_count=$(wc -l < /tmp/km-unclaimed-findings.txt | tr -d ' ')"
  exit 0
fi

# Filter out claimed findings
> /tmp/km-unclaimed-findings.txt
while IFS= read -r finding_file; do
  [ -n "$finding_file" ] || continue
  uuid=$(basename "$finding_file" .md | sed 's/^finding-//')
  if ! grep -q "^${uuid}$" /tmp/km-claimed-findings.txt 2>/dev/null; then
    echo "$finding_file" >> /tmp/km-unclaimed-findings.txt
  fi
done < /tmp/km-findings-list.txt

unclaimed=$(wc -l < /tmp/km-unclaimed-findings.txt | tr -d ' ')
claimed=$(wc -l < /tmp/km-claimed-findings.txt 2>/dev/null | tr -d ' ')
echo "unclaimed_count=${unclaimed}"
echo "claimed_count=${claimed}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-filter-unclaimed.sh && bash /tmp/km-phase3-filter-unclaimed.sh "${PROJECT_PATH}" "${SEEDS_LOADED:-false}"
```

**Use `/tmp/km-unclaimed-findings.txt` for all subsequent clustering operations.**

### 2.1 Load Finding Summaries

For each **unclaimed** finding, extract:

- Title (from H1 or frontmatter)
- Summary/abstract (first paragraph or `dc:description`)
- Tags (from frontmatter)

### 2.2 Identify Megatrend Clusters

**Reasoning Task:** Group findings by thematic similarity, not keyword matching.

**⛔ LANGUAGE REQUIREMENT:** When `PROJECT_LANGUAGE="de"`:

- Use proper German umlauts in ALL text content: ä, ö, ü, ß
- NEVER use ASCII fallbacks (ae, oe, ue, ss) in body text
- Only use ASCII transliteration for filenames/slugs (handled separately in Step 3.3)
- Examples: "für" NOT "fuer", "Übersicht" NOT "Uebersicht", "Maßnahmen" NOT "Massnahmen"

| Criterion | Description |
|-----------|-------------|
| **Semantic Relatedness** | Findings discuss the same concept, even with different terminology |
| **Minimum Cluster Size** | 3+ findings required to form a megatrend |
| **Distinct Themes** | Each cluster represents a coherent, non-overlapping theme |
| **Cross-Terminology** | Group "ML", "machine learning", "AI algorithms" together |
| **Cross-Dimension** | Megatrends can span multiple dimensions |

**Output Format:**

```yaml
megatrend_clusters:
  - megatrend_name: "Descriptive Megatrend Name"
    dc_title: "2-4 Word Heading"
    member_findings:
      - uuid: "{finding-uuid-1}"
        relevance: "Brief explanation of why this finding belongs"
      - uuid: "{finding-uuid-2}"
        relevance: "Brief explanation"
    overview: |
      [150-200 words comprehensive synthesis including:
      - Definition of what this megatrend encompasses
      - Why this megatrend emerged from the research
      - Key patterns observed across member findings
      - Significance for the research question]
    key_themes:
      - theme: "Theme 1 Name"
        description: "Brief description of sub-theme"
      - theme: "Theme 2 Name"
        description: "Brief description of sub-theme"
      - theme: "Theme 3 Name"
        description: "Brief description of sub-theme"
```

### 2.3 Apply Threshold and Validate

- **Discard clusters with < 3 members**
- **Verify no finding appears in multiple clusters** (assign to best-fit only)
- **Check for existing megatrends** in `${PROJECT_PATH}/06-megatrends/data/` to avoid duplicates

**Early Exit:** If 0 valid clusters identified, set `megatrends_created=0` and proceed to Phase 4.

**Mark 3.2 complete.**

---

### 2.4 Seed-Cluster Deduplication (TIPS only)

**Entry Condition:** Only execute if `SEEDS_LOADED=true` AND valid bottom-up clusters exist.

**⛔ CRITICAL:** Prevent duplicate megatrends by checking if bottom-up clusters semantically overlap with seed megatrends.

**LLM Reasoning Task:** For each bottom-up cluster:

1. **Extract cluster keywords** from member finding content
2. **Compare against each seed megatrend** already created in Step 0.4:
   - Load seed megatrend's `seed_name` and keywords
   - Calculate semantic overlap (keyword matching + thematic similarity)
3. **Decision logic:**

| Overlap | Action |
|---------|--------|
| >80% keyword overlap | Merge: Add cluster findings to seed megatrend, skip cluster |
| 50-80% overlap | Review: LLM decides if merge or keep separate |
| <50% overlap | Keep: Create as separate clustered megatrend |

**Merge Process:**

When merging a cluster into a seed megatrend:

```bash
cat > /tmp/km-phase3-merge-cluster.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
SEED_MEGATREND_FILE="$2"
shift 2
new_uuids=("$@")

# Validate inputs to prevent empty path errors in sed/grep operations
if [[ -z "$PROJECT_PATH" ]]; then
  echo "ERROR: PROJECT_PATH not provided" >&2
  exit 1
fi

if [[ -z "$SEED_MEGATREND_FILE" ]]; then
  echo "ERROR: SEED_MEGATREND_FILE not provided" >&2
  exit 1
fi

if [[ ! -f "$SEED_MEGATREND_FILE" ]]; then
  echo "ERROR: SEED_MEGATREND_FILE does not exist: ${SEED_MEGATREND_FILE}" >&2
  exit 1
fi

# Read current finding_refs count
current_count=$(grep "^finding_count:" "$SEED_MEGATREND_FILE" | head -1 | sed 's/[^0-9]//g')

# Add new finding refs to the megatrend file (append after last existing ref)
for uuid in "${new_uuids[@]}"; do
  # Check if already in file
  if ! grep -q "finding-${uuid}" "$SEED_MEGATREND_FILE"; then
    # Find the last finding_ref line number, or the finding_refs: key line
    last_ref_line=$(grep -n '^\s*- "\[\[04-findings/data/finding-' "$SEED_MEGATREND_FILE" | tail -1 | cut -d: -f1)
    if [ -z "$last_ref_line" ]; then
      last_ref_line=$(grep -n '^finding_refs:' "$SEED_MEGATREND_FILE" | head -1 | cut -d: -f1)
    fi
    sed -i '' "${last_ref_line}a\\
  - \"[[04-findings/data/finding-${uuid}]]\"" "$SEED_MEGATREND_FILE"
  fi
done

# Update finding_count
new_count=$((current_count + ${#new_uuids[@]}))
sed -i '' "s/^finding_count:.*/finding_count: ${new_count}/" "$SEED_MEGATREND_FILE"

# Update evidence_strength if improved
if [ "$new_count" -ge 5 ]; then
  sed -i '' 's/evidence_strength:.*/evidence_strength: "strong"/' "$SEED_MEGATREND_FILE"
elif [ "$new_count" -ge 3 ]; then
  sed -i '' 's/evidence_strength:.*/evidence_strength: "moderate"/' "$SEED_MEGATREND_FILE"
fi

# If was hypothesis, upgrade to hybrid
sed -i '' 's/source_type: "seeded"/source_type: "hybrid"/' "$SEED_MEGATREND_FILE"

echo "merged_count=${#new_uuids[@]}"
echo "new_total=${new_count}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-merge-cluster.sh
```

**Track merged clusters:**

```bash
# Record which clusters were merged (not created as separate megatrends)
echo "${cluster_name}" >> /tmp/km-merged-clusters.txt
```

**Output:**

- List of clusters to create as new megatrends (not merged)
- Count of clusters merged into seed megatrends
- Updated seed megatrend files with additional findings

**Mark 3.3 complete.**

---

## Step 3: Create Megatrend Entities

For each valid cluster, create a megatrend entity.

### 3.1 Check Existing Megatrends

**⚠️ ZSH COMPATIBILITY:** Bash arrays and loops require temp script pattern.

```bash
cat > /tmp/km-phase3-check-megatrends.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"

megatrend_exists=false
for existing in "${PROJECT_PATH}"/06-megatrends/data/megatrend-*.md; do
  [ -f "$existing" ] || continue
  existing_name=$(grep "^megatrend_name:" "$existing" | head -1 | cut -d'"' -f2)
  # Semantic check: is this cluster's theme already covered?
  echo "existing_megatrend=${existing_name}"
done
SCRIPT_EOF
chmod +x /tmp/km-phase3-check-megatrends.sh && bash /tmp/km-phase3-check-megatrends.sh "${PROJECT_PATH}"
```

### 3.2 Determine Dimension (Majority Vote)

**⚠️ ZSH COMPATIBILITY:** Bash arrays and helper functions require temp script pattern.

```bash
cat > /tmp/km-phase3-dim-vote.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
shift
member_uuids=("$@")

# Read findings list from Step 1
findings_list=()
while IFS= read -r line; do
  findings_list+=("$line")
done < /tmp/km-findings-list.txt

# Bash 3.2 compatible - use parallel indexed arrays for counting
DIM_COUNT_KEYS=()
DIM_COUNT_VALUES=()

get_or_add_dim_count() {
  local dim="$1"
  local i=0
  for key in "${DIM_COUNT_KEYS[@]}"; do
    if [ "$key" = "$dim" ]; then
      echo "$i"
      return 0
    fi
    i=$((i + 1))
  done
  DIM_COUNT_KEYS+=("$dim")
  DIM_COUNT_VALUES+=(0)
  echo "$i"
}

lookup_finding_dimension() {
  local file="$1"
  # Extract dimension from finding's batch reference
  grep "^batch_ref:" "$file" 2>/dev/null | head -1 | sed 's/.*dimension-\([^/]*\).*/\1/' || echo ""
}

for uuid in "${member_uuids[@]}"; do
  for finding_file in "${findings_list[@]}"; do
    case "$finding_file" in
      *"$uuid"*)
        dim=$(lookup_finding_dimension "$finding_file")
        if [ -n "$dim" ]; then
          idx=$(get_or_add_dim_count "$dim")
          DIM_COUNT_VALUES[$idx]=$((DIM_COUNT_VALUES[$idx] + 1))
        fi
        break
        ;;
    esac
  done
done

# Majority vote
best_dimension=""
max=0
for i in "${!DIM_COUNT_KEYS[@]}"; do
  if [ "${DIM_COUNT_VALUES[$i]}" -gt "$max" ]; then
    best_dimension="${DIM_COUNT_KEYS[$i]}"
    max="${DIM_COUNT_VALUES[$i]}"
  fi
done

echo "best_dimension=${best_dimension}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-dim-vote.sh && bash /tmp/km-phase3-dim-vote.sh "${PROJECT_PATH}" "${member_uuids[@]}"
```

### 3.3 Generate Filename

**⚠️ ZSH COMPATIBILITY:** Command substitution chains work inline but wrap for consistency.

```bash
cat > /tmp/km-phase3-filename.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
megatrend_name="$1"

slug=$(echo "$megatrend_name" | tr '[:upper:]' '[:lower:]' | \
  sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | \
  sed 's/^-//' | sed 's/-$//' | cut -c1-50)
hash=$(echo -n "$megatrend_name" | shasum -a 256 | cut -c1-8)
filename="megatrend-${slug}-${hash}.md"

echo "slug=${slug}"
echo "hash=${hash}"
echo "filename=${filename}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-filename.sh && bash /tmp/km-phase3-filename.sh "${megatrend_name}"
```

### 3.4 Build Finding References

**⛔ MANDATORY:** The `finding_refs` array MUST be populated from this step's output and included in the entity file. Megatrends without `finding_refs` are invalid.

**⚠️ ZSH COMPATIBILITY:** Bash arrays require temp script pattern.

```bash
cat > /tmp/km-phase3-refs.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
shift
member_uuids=("$@")

# Read findings list from Step 1
findings_list=()
while IFS= read -r line; do
  findings_list+=("$line")
done < /tmp/km-findings-list.txt

finding_refs=""
for uuid in "${member_uuids[@]}"; do
  for finding_file in "${findings_list[@]}"; do
    case "$finding_file" in
      *"$uuid"*)
        finding_basename=$(basename "$finding_file" .md)
        finding_refs+="  - \"[[04-findings/data/${finding_basename}]]\"\n"
        break
        ;;
    esac
  done
done

echo -e "$finding_refs"
SCRIPT_EOF
chmod +x /tmp/km-phase3-refs.sh && bash /tmp/km-phase3-refs.sh "${PROJECT_PATH}" "${member_uuids[@]}"
```

**⛔ CRITICAL:** Store the output of this script. You MUST use it in Step 3.5 to populate the `finding_refs` array in the YAML frontmatter.

### 3.5 Write Entity File

**⛔ MANDATORY FIELDS:** The `finding_refs` array MUST be included and populated with ALL member finding wikilinks from Step 3.4.

**⛔ MEGATREND STRUCTURE ROUTING:** Content structure depends on `MEGATREND_STRUCTURE` from Step 0.1:

| MEGATREND_STRUCTURE | Word Count | Content Structure |
|-----------------|------------|-------------------|
| `generic` | 400-600 | Was es ist / Was es tut / Was es bedeutet |
| `tips` | 600-900 | Trend / Implication / Possibility / Solution |

**⛔ LANGUAGE REQUIREMENT:**
- Use proper German umlauts (ä, ö, ü, ß) in ALL German text content - NEVER ASCII fallbacks (ae, oe, ue, ss)
- Use language-appropriate headers from the tables below

Write to `${PROJECT_PATH}/06-megatrends/data/${filename}`:

---

#### 3.5a Generic Megatrend Template (400-600 words)

**When `MEGATREND_STRUCTURE="generic"`** (all research types except smarter-service):

**Header Translation Map (Generic):**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_WHAT_IT_IS` | What it is | Was es ist |
| `HEADER_WHAT_IT_DOES` | What it does | Was es tut |
| `HEADER_WHAT_IT_MEANS` | What it means | Was es bedeutet |
| `HEADER_QUALITATIVE_IMPACT` | Qualitative Impact | Qualitative Auswirkungen |
| `HEADER_QUANTITATIVE_INDICATORS` | Quantitative Indicators | Quantitative Indikatoren |
| `HEADER_RELATED_FINDINGS` | Related Findings | Zugehörige Ergebnisse |
| `TH_METRIC` | Metric | Kennzahl |
| `TH_VALUE_RANGE` | Value/Range | Wert/Bereich |
| `TH_SOURCE` | Source | Quelle |

```yaml
---
megatrend_id: "megatrend-{slug}-{hash}"
megatrend_name: "{Megatrend Name}"
megatrend_structure: "generic"
dc:creator: knowledge-merger
dc:title: "{2-4 word heading}"
finding_count: {member count}
finding_refs:
  # ⛔ PASTE Step 3.4 output VERBATIM here. Every line must start with exactly "  - " (2 spaces + dash + space).
  - "[[04-findings/data/finding-example-a1b2c3d4]]"
  - "[[04-findings/data/finding-example-e5f6g7h8]]"
# ⛔ YAML CRITICAL: Ensure blank line above. The created_at field MUST start on its own line.
created_at: "{ISO 8601 UTC}"
language: "{PROJECT_LANGUAGE}"
tags: [megatrend, dimension/{best_dimension}, {derived-tag}]
dimension_affinity: "{best_dimension}"  # From majority vote (Step 3.2)
---

> **⛔ YAML INDENTATION RULE for finding_refs:**
> ALL items MUST be at exactly 2-space indentation. Copy Step 3.4 output verbatim.
> **WRONG:** `finding_refs:\n- "[[first]]"\n  - "[[second]]"` (first item at indent 0)
> **CORRECT:** `finding_refs:\n  - "[[first]]"\n  - "[[second]]"` (all items at indent 2)

# {Megatrend Name}

## {HEADER_WHAT_IT_IS}
<!-- en: What it is | de: Was es ist -->

{150-200 words - Primer on the subject:
- Definition of what this megatrend encompasses
- Core concepts and terminology from the research
- Scope and boundaries within the research context
- Key characteristics synthesized from member findings

Synthesize ONLY from member finding content. No external knowledge.}

## {HEADER_WHAT_IT_DOES}
<!-- en: What it does | de: Was es tut -->

{100-150 words - Use Cases:
- Practical applications relevant to research stakeholders
- How this megatrend manifests in the research domain
- Key activities or processes involved
- Real-world examples derived from member findings}

## {HEADER_WHAT_IT_MEANS}
<!-- en: What it means | de: Was es bedeutet -->

**{HEADER_QUALITATIVE_IMPACT}:**
<!-- en: Qualitative Impact | de: Qualitative Auswirkungen -->

{100-150 words narrative describing strategic significance, stakeholder effects,
and broader implications for the research context}

**{HEADER_QUANTITATIVE_INDICATORS}:**
<!-- en: Quantitative Indicators | de: Quantitative Indikatoren -->

| {TH_METRIC} | {TH_VALUE_RANGE} | {TH_SOURCE} |
|-------------|------------------|-------------|
| {Metric 1} | {Value} | [[04-findings/data/finding-ref]] |
| {Metric 2} | {Value} | [[04-findings/data/finding-ref]] |

{Note: Include table ONLY if quantitative data available in member findings.
Omit table entirely if no metrics found - do not estimate or fabricate.}

## {HEADER_RELATED_FINDINGS}
<!-- en: Related Findings | de: Zugehörige Ergebnisse -->

⛔ **MANDATORY:** List ALL finding_refs as display-name wikilinks below. For each finding in the finding_refs frontmatter array, create a bullet with the finding's title:

- [[04-findings/data/{finding-id}|{dc:title from finding file}]]

Read each referenced finding file to extract its `dc:title` for the display name. If a finding file cannot be read, use the finding ID slug as fallback.
```

**Word Count Target (Generic):** 400-600 words total

| Section | Target |
|---------|--------|
| What it is | 150-200 words |
| What it does | 100-150 words |
| What it means | 150-200 words |
| **Total** | **400-600 words** |

---

#### 3.5b TIPS Megatrend Template (600-900 words)

**When `MEGATREND_STRUCTURE="tips"`** (smarter-service research type only):

**⚠️ NOTE:** This template is used for **bottom-up clustered megatrends only**. Seed megatrends are created in Step 0.4 with a slightly different template that supports hypothesis megatrends.

**Header Translation Map (TIPS):**

| Variable | English (en) | German (de) |
|----------|--------------|-------------|
| `HEADER_TREND` | Trend | Trend |
| `HEADER_IMPLICATION` | Implication | Implikation |
| `HEADER_POSSIBILITY` | Possibility | Möglichkeit |
| `HEADER_SOLUTION` | Solution | Lösung |
| `HEADER_EVIDENCE_BASE` | Evidence Base | Evidenzbasis |
| `HEADER_KEY_FINDINGS` | Key Findings | Kernerkenntnisse |
| `HEADER_HYPOTHESIS_NOTE` | Hypothesis Note | Hypothesen-Hinweis |

```yaml
---
megatrend_id: "megatrend-{slug}-{hash}"
megatrend_name: "{Megatrend Name}"
megatrend_structure: "tips"
dc:creator: knowledge-merger
dc:title: "{2-4 word heading}"
finding_count: {member count}  # May be 0 for hypothesis megatrends (source_type="seeded")
finding_refs:
  # ⛔ PASTE Step 3.4 output VERBATIM here. Every line must start with exactly "  - " (2 spaces + dash + space).
  - "[[04-findings/data/finding-example-a1b2c3d4]]"
  - "[[04-findings/data/finding-example-e5f6g7h8]]"
  # For hypothesis megatrends (source_type="seeded"): empty array is valid
  # finding_refs: []
# ⛔ YAML CRITICAL: Ensure blank line above. The created_at field MUST start on its own line.
created_at: "{ISO 8601 UTC}"
language: "{PROJECT_LANGUAGE}"
tags: [megatrend, dimension/{best_dimension}, {derived-tag}]
source_type: "{clustered|hybrid|seeded}"  # seeded = hypothesis megatrend from seed with no findings
seed_name: "{Original Seed Name}"  # Only for seed-derived megatrends (hybrid/seeded)
seed_validated: {true|false}  # Only for seed-derived megatrends
evidence_strength: "{strong|moderate|weak|hypothesis}"  # hypothesis = 0 findings
planning_horizon: "{act|plan|observe}"
dimension_affinity: "{best_dimension}"  # From majority vote (Step 3.2) or seed config
strategic_narrative:
  trend: "{Observable pattern summary}"
  implication: "{Strategic significance}"
  possibility:
    overview: "{Opportunity framing}"
    chance: "{Value of acting}"
    risk: "{Cost of not acting}"
  solution: "{Recommended action}"
---

> **⛔ YAML INDENTATION RULE for finding_refs:**
> ALL items MUST be at exactly 2-space indentation. Copy Step 3.4 output verbatim.
> **WRONG:** `finding_refs:\n- "[[first]]"\n  - "[[second]]"` (first item at indent 0)
> **CORRECT:** `finding_refs:\n  - "[[first]]"\n  - "[[second]]"` (all items at indent 2)

# {Megatrend Name}

## {HEADER_TREND}
<!-- en: Trend | de: Trend -->

{150-200 words - Observable pattern description:
- What is happening (evidence-based from findings)
- Scale and velocity of change
- Key drivers and catalysts
- Geographic/industry scope

Synthesize ONLY from member finding content. No external knowledge.}

## {HEADER_IMPLICATION}
<!-- en: Implication | de: Implikation -->

{150-200 words - Strategic significance:
- Impact on industry/organization
- Stakeholder effects (customers, employees, partners)
- Competitive dynamics
- Risk/opportunity landscape}

## {HEADER_POSSIBILITY}
<!-- en: Possibility | de: Möglichkeit -->

{100-150 words - Opportunity framing:
- **Chance:** Value gained by acting on this megatrend
- **Risk:** Cost of not acting on this megatrend}

## {HEADER_SOLUTION}
<!-- en: Solution | de: Lösung -->

{100-150 words - Recommended action:
- Concrete next steps
- Resource considerations
- Success indicators
- Quick wins vs. strategic investments}

## {HEADER_EVIDENCE_BASE}
<!-- en: Evidence Base | de: Evidenzbasis -->

**Source:** {clustered|hybrid|seeded}
**Evidence Strength:** {strong|moderate|weak|hypothesis}
**Planning Horizon:** {act|plan|observe}
**Finding Coverage:** {N} findings

{IF source_type="seeded" (hypothesis megatrend):}

### {HEADER_HYPOTHESIS_NOTE}
<!-- en: Hypothesis Note | de: Hypothesen-Hinweis -->

⚠️ **This is a hypothesis megatrend.** This megatrend was identified as strategically relevant based on seed configuration, but no supporting findings were discovered during research. Consider:
- Additional research queries targeting this megatrend
- Validation through expert interviews
- Monitoring for emerging evidence

{ENDIF}

### {HEADER_KEY_FINDINGS}
<!-- en: Key Findings | de: Kernerkenntnisse -->

⛔ **MANDATORY:** List ALL finding_refs as display-name wikilinks below. For each finding in the finding_refs frontmatter array, create a bullet with the finding's title:

- [[04-findings/data/{finding-id}|{dc:title from finding file}]]

Read each referenced finding file to extract its `dc:title` for the display name. If a finding file cannot be read, use the finding ID slug as fallback.

{IF finding_count=0: "No findings currently linked to this megatrend."}
```

**Word Count Target (TIPS):** 600-900 words total

| Section | Target |
|---------|--------|
| Trend | 150-200 words |
| Implication | 150-200 words |
| Possibility | 100-150 words |
| Solution | 100-150 words |
| Evidence Base | 50-100 words |
| **Total** | **600-900 words** |

### 3.5.5 Detect and Populate Cross-References (NEW)

**After creating each megatrend entity, populate cross-reference fields.**

For each megatrend, identify related entities using the logic below:

#### 3.5.5.1 Detect Related Concepts

```bash
cat > /tmp/km-phase3-related-concepts.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
MEGATREND_NAME="$2"
shift 2
keywords=("$@")

related_concepts=""
for concept_file in "${PROJECT_PATH}"/05-domain-concepts/data/concept-*.md; do
  [ -f "$concept_file" ] || continue

  concept_content=$(cat "$concept_file" 2>/dev/null | tr '[:upper:]' '[:lower:]')
  concept_name=$(grep "^concept:" "$concept_file" | head -1 | cut -d'"' -f2)

  # Check for keyword overlap
  match_count=0
  for keyword in "${keywords[@]}"; do
    keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
    if echo "$concept_content" | grep -q "$keyword_lower"; then
      match_count=$((match_count + 1))
    fi
  done

  # Include if 2+ keywords match
  if [ "$match_count" -ge 2 ]; then
    concept_basename=$(basename "$concept_file" .md)
    related_concepts+="  - \"[[05-domain-concepts/data/${concept_basename}]]\"\n"
  fi
done

echo -e "$related_concepts" | head -5  # Limit to 5 related concepts
SCRIPT_EOF
chmod +x /tmp/km-phase3-related-concepts.sh
```

**LLM Task:** For each related concept found, add a brief relationship description when populating the "Related Entities" section.

#### 3.5.5.2 Detect Related Trends

```bash
cat > /tmp/km-phase3-related-trends.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
DIMENSION_SLUG="$2"
MEGATREND_NAME="$3"

related_trends=""
for trend_file in "${PROJECT_PATH}"/11-trends/data/trend-*.md; do
  [ -f "$trend_file" ] || continue

  # Check if trend matches dimension
  trend_dimension=$(grep "^dimension:" "$trend_file" | head -1 | cut -d'"' -f2)

  if [ "$trend_dimension" = "$DIMENSION_SLUG" ]; then
    trend_basename=$(basename "$trend_file" .md)
    related_trends+="  - \"[[11-trends/data/${trend_basename}]]\"\n"
  fi
done

echo -e "$related_trends" | head -4  # Limit to 4 related trends
SCRIPT_EOF
chmod +x /tmp/km-phase3-related-trends.sh
```

#### 3.5.5.3 Detect Related Megatrends

**LLM Reasoning Task:** For each megatrend, identify 1-3 related megatrends based on:

| Relationship Type | Criteria | Description in Entity |
| ----------------- | -------- | --------------------- |
| **Synergy** | Shared findings (>20% overlap) OR complementary themes | "Synergy: [brief description of how they reinforce each other]" |
| **Tension** | Competing for resources or representing trade-offs | "Tension: [brief description of the trade-off]" |
| **Enabler** | One megatrend enables or unlocks the other | "Enabler: [brief description of dependency]" |

```yaml
# Example related_megatrends detection output
related_megatrends:
  - ref: "[[06-megatrends/data/megatrend-abc]]"
    relationship: "synergy"
    description: "Both address digital transformation enablers"
  - ref: "[[06-megatrends/data/megatrend-def]]"
    relationship: "tension"
    description: "Competes for implementation resources"
```

#### 3.5.5.4 Update Megatrend Entity with Cross-References

**After detecting related entities, update the megatrend frontmatter:**

```bash
cat > /tmp/km-phase3-update-crossrefs.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
MEGATREND_FILE="$1"
RELATED_CONCEPTS_FILE="$2"
RELATED_TRENDS_FILE="$3"
RELATED_MEGATRENDS_FILE="$4"

# Read related entities from temp files
related_concepts=$(cat "$RELATED_CONCEPTS_FILE" 2>/dev/null || echo "")
related_trends=$(cat "$RELATED_TRENDS_FILE" 2>/dev/null || echo "")
related_megatrends=$(cat "$RELATED_MEGATRENDS_FILE" 2>/dev/null || echo "")

# Add related_concepts if not empty
if [ -n "$related_concepts" ]; then
  # Find end of frontmatter and insert before closing ---
  sed -i '' "/^---$/,/^---$/ {
    /^---$/ {
      N
      /\n---$/!b
      i\\
related_concepts:\\
$related_concepts
    }
  }" "$MEGATREND_FILE"
fi

# Similar for related_trends and related_megatrends
# (pattern continues)

echo "crossrefs_updated=true"
SCRIPT_EOF
chmod +x /tmp/km-phase3-update-crossrefs.sh
```

**⛔ IMPORTANT:** Cross-references are optional but strongly recommended. If no related entities are found, the arrays can remain empty.

#### 3.5.5.5 Populate "Related Entities" Content Section

**LLM Task:** After identifying cross-references, generate the "Related Entities" section content:

```markdown
## Related Entities

### Related Concepts
- [[05-domain-concepts/data/concept-xyz|Concept Name]] - {How this concept relates to the megatrend}
- [[05-domain-concepts/data/concept-abc|Another Concept]] - {Relationship description}

### Related Megatrends
- [[06-megatrends/data/megatrend-abc|Megatrend Name]] - Synergy: {description}
- [[06-megatrends/data/megatrend-def|Another Megatrend]] - Tension: {description}

### Related Trends
- [[11-trends/data/trend-xyz|Trend Name]] - {How this trend manifests the megatrend}
- [[11-trends/data/trend-abc|Another Trend]] - {Relationship description}
```

**Word Count Target:** 50-100 words for Related Entities section.

---

### 3.6 Track for Backlinks

**⚠️ ZSH COMPATIBILITY:** Bash arrays require temp script pattern.

```bash
cat > /tmp/km-phase3-track.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
best_dimension="$1"
filename="$2"
megatrends_created="$3"

if [ -n "$best_dimension" ]; then
  dim_file=$(basename "$best_dimension")
  # Append to megatrends-by-dimension tracking file
  echo "${dim_file}:[[06-megatrends/data/${filename%.md}]]" >> /tmp/km-megatrends-by-dim.txt
fi

megatrends_created=$((megatrends_created + 1))
echo "megatrends_created=${megatrends_created}"
SCRIPT_EOF
chmod +x /tmp/km-phase3-track.sh && bash /tmp/km-phase3-track.sh "${best_dimension}" "${filename}" "${megatrends_created:-0}"
```

**Mark 3.3 complete.**

---

## Phase 3 Verification

| Check | Status |
| ----- | ------ |
| All findings loaded | |
| Seeds loaded (TIPS only) | |
| All seeds created megatrends (TIPS only) | |
| Semantic clustering performed | |
| Seed-cluster deduplication applied (TIPS only) | |
| Megatrend entities created in 06-megatrends/data/ | |
| **⛔ finding_refs populated OR empty for hypothesis** | |
| finding_refs count matches finding_count | |
| **⛔ megatrend_structure matches content structure** | |
| **⛔ Word count within target range** (generic: 400-600, tips: 700-1100, hypothesis: 300-400) | |
| **Executive summary populated** (TIPS only) | |
| **Key Findings section contains 3-5 finding summaries** (not placeholder) | |
| **Inline citations present in Trend/Implication** (3+ per megatrend) | |
| **Cross-references detected** (related_concepts, related_trends, related_megatrends) | |
| **Related Entities section populated** | |
| MEGATRENDS_DIM_KEYS/VALUES populated | |
| All step todos completed | |

**Note:** Hypothesis megatrends (source_type="seeded") may have `finding_refs: []` and `finding_count: 0`. This is valid.

⛔ **All checks must pass before Phase 4.**

### 3.7 Validate finding_refs (Post-Creation Check)

**⚠️ ZSH COMPATIBILITY:** Bash loops require temp script pattern.

```bash
cat > /tmp/km-phase3-validate-refs.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"

validation_passed=true
hypothesis_count=0
hybrid_count=0
clustered_count=0

for megatrend_file in "${PROJECT_PATH}"/06-megatrends/data/megatrend-*.md; do
  [ -f "$megatrend_file" ] || continue

  # Extract finding_count from frontmatter
  finding_count=$(grep "^finding_count:" "$megatrend_file" | head -1 | sed 's/[^0-9]//g')

  # Extract source_type
  source_type=$(grep "^source_type:" "$megatrend_file" | head -1 | sed 's/.*"\([^"]*\)".*/\1/')

  # Count actual finding_refs entries
  refs_count=$(grep -c '^\s*- "\[\[04-findings/data/finding-' "$megatrend_file" 2>/dev/null || echo 0)

  # Track megatrend types
  case "$source_type" in
    seeded) hypothesis_count=$((hypothesis_count + 1)) ;;
    hybrid) hybrid_count=$((hybrid_count + 1)) ;;
    clustered) clustered_count=$((clustered_count + 1)) ;;
  esac

  # Hypothesis megatrends (source_type="seeded") are allowed to have 0 findings
  if [ "$source_type" = "seeded" ]; then
    if [ "$finding_count" -gt 0 ] && [ "$refs_count" -eq 0 ]; then
      echo "ERROR: $(basename "$megatrend_file") is seeded but has finding_count=$finding_count without refs" >&2
      validation_passed=false
    fi
    # finding_count=0 with refs_count=0 is valid for hypothesis
    continue
  fi

  # Non-hypothesis megatrends must have matching finding_refs
  if [ "$finding_count" -gt 0 ] && [ "$refs_count" -eq 0 ]; then
    echo "ERROR: $(basename "$megatrend_file") has finding_count=$finding_count but no finding_refs" >&2
    validation_passed=false
  fi

  # Check for malformed YAML: missing newline between finding_refs and created_at
  if grep -q ']]"created_at:' "$megatrend_file" 2>/dev/null; then
    echo "ERROR: $(basename "$megatrend_file") has malformed YAML - missing newline after finding_refs" >&2
    validation_passed=false
  fi

  # Check for finding_refs at indent 0 (the known bug pattern)
  if grep -q '^- "\[\[04-findings/data/finding-' "$megatrend_file"; then
    echo "ERROR: $(basename "$megatrend_file") has finding_ref at indent 0 — fix indentation" >&2
    validation_passed=false
  fi
done

echo "hypothesis_megatrends=${hypothesis_count}"
echo "hybrid_megatrends=${hybrid_count}"
echo "clustered_megatrends=${clustered_count}"

if [ "$validation_passed" = true ]; then
  echo "validation=PASSED"
else
  echo "validation=FAILED"
  exit 1
fi
SCRIPT_EOF
chmod +x /tmp/km-phase3-validate-refs.sh && bash /tmp/km-phase3-validate-refs.sh "${PROJECT_PATH}"
```

**⛔ If validation fails:** Review Step 3.4 output and ensure all finding_refs are included in the megatrend file.

**Note:** Hypothesis megatrends (source_type="seeded") with `finding_count: 0` and empty `finding_refs` will pass validation.

---

## Phase 3 Output

```text
✅ Phase 3 Complete

Findings analyzed: {findings_count}
Clusters identified: {cluster_count}
Megatrends created: {megatrends_created}
  - From seeds (hybrid): {hybrid_count}
  - From seeds (hypothesis): {hypothesis_count}
  - From clustering: {clustered_count}

→ Phase 4: Backlink Update
```

**Mark Phase 3 complete in TodoWrite.**

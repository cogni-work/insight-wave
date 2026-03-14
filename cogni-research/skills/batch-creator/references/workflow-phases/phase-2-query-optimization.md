---
reference: phase-2-query-optimization
version: 1.0.0
checksum: phase-2-query-optimization-v1.0.0-batch-creator
dependencies: [phase-1-load-questions]
phase: 2
---

# Phase 2: Query Optimization (Per Question)

**Checksum:** `phase-2-query-optimization-v1.0.0-batch-creator`

---

## Purpose

For EACH refined question, generate 4-7 optimized WebSearch configurations using PICOT facet decomposition and bilingual strategy.

**Execution:** This phase runs in a loop for each question from Phase 1.

---

## Step 2.1: Analyze PICOT Facets

Extract searchable facets from PICOT dimensions:

| PICOT Dimension | Facet Type | Example Keywords |
|-----------------|------------|------------------|
| Population | Audience | "Mittelstand", "IT-Leitung" |
| Intervention | Technology/Action | "Cloud-Strategien", "KI-Anwendungen" |
| Comparison | Alternatives | "Public vs. Private", "vs. On-Premise" |
| Outcome | Metrics | "TCO-Einsparungen", "Effizienzgewinne" |
| Timeframe | Temporal | "2024", "2025", "current" |

**Count facets:**

```text
FACET_COUNT = distinct_facets(PICOT)
```

---

## Step 2.2: Classify Complexity

| Facet Count | Complexity | Query Strategy |
|-------------|------------|----------------|
| 1-2 | Simple | Verbatim question + keyword variant |
| 3-4 | Moderate | Keyword-optimized + 2-3 sub-queries |
| 5+ | Complex | Full facet decomposition (5-7 sub-queries) |

---

## Step 2.3: Select Search Profiles

Choose 4-7 profiles based on question characteristics:

| Profile | Use When | Domain Strategy |
|---------|----------|-----------------|
| `general` | Always | blocked_domains (social media) |
| `localized` | Non-English or region-specific | user_location object |
| `industry` | Business/market questions | allowed_domains (news sites) |
| `academic` | Technical/research questions | allowed_domains (scholar sites) |
| `trade` | Industry-specific | allowed_domains (trade pubs) |
| `population` | Distinct audience in PICOT.P | audience-specific domains |
| `outcome` | Measurable results in PICOT.O | consulting/business domains |

---

## Step 2.4: Generate Optimized Queries

**Per profile, build query:**

```text
Query = [facet_keywords] + [temporal_modifier] + [domain_context]
```

### ⛔ PROHIBITED: Full Question Text as Query

**NEVER use the verbatim question as a search query.** Full questions are too long for effective web search and waste the query character budget.

**WRONG** (full question text):

```text
"What is the anatomical organization of the bone marrow microenvironment in mice and humans, including the spatial distribution of distinct niche compartments (endosteal, sinusoidal, periarteriolar) and their relative contributions to HSC maintenance?"
```

**RIGHT** (optimized facet keywords):

```text
"bone marrow niche compartments endosteal periarteriolar HSC maintenance"
```

**Query length targets:**

| Query Type | Target Length | Max |
|------------|---------------|-----|
| Keyword-optimized | 20-50 chars | 100 |
| Short natural language | 50-100 chars | 150 |
| Full question (Tier 1 only) | 100-200 chars | 300 |

**NOTE**: Even "Full question (Tier 1 only)" does NOT mean the verbatim question text. It means a longer natural language query that covers multiple facets - still optimized, still under 300 chars.

---

## Step 2.5: Apply Bilingual Strategy

For non-English questions (detected from PROJECT_LANGUAGE):

| Query Set | Language | Purpose |
|-----------|----------|---------|
| Set A (2-3) | Original | Regional sources, trade pubs |
| Set B (2-4) | English | Academic, consulting, international |

**Translation rules:**

- Keep domain-specific terms verbatim: "Datensouveränität", "Mittelstand"
- Translate generic terms: "Cloud-Strategien" → "cloud strategies"

---

## Step 2.6: PICOT-Query Alignment Verification

**Gate check before proceeding:**

| Check | Requirement | Failure Action |
|-------|-------------|----------------|
| Intervention coverage | ≥1 query has ≥2 Intervention keywords | Regenerate configs |
| Population coverage | ≥1 query has ≥1 Population keyword | Regenerate configs |

---

## Step 2.7: Entity-Specific Handling

If question targets a named entity (company, product):

- Set `ENTITY_SPECIFIC=true`
- Extract `PRIMARY_ENTITY` name
- Ensure PRIMARY_ENTITY appears in ALL queries

---

## Output: SEARCH_CONFIGS Array

```json
[
  {
    "config_id": "config-{uuid}",
    "profile": "general",
    "tier": 1,
    "query_text": "KI-Anwendungen Maschinenbau 2024 2025",
    "websearch_params": {
      "query": "KI-Anwendungen Maschinenbau generative KI 2024 2025",
      "blocked_domains": ["pinterest.com", "facebook.com"]
    },
    "picot_source": "intervention"
  }
]
```

**Minimum 4 configs required. Maximum 7.**

---

## ⛔ Step 2.8: Phase 2 → Phase 3 Gate Check (MANDATORY)

**Before proceeding to Phase 3, verify Phase 2 outputs are valid:**

```bash
# Gate 1: Minimum config count
if [ ${#SEARCH_CONFIGS[@]} -lt 4 ]; then
    echo "ERROR: Phase 2 produced ${#SEARCH_CONFIGS[@]} configs (minimum 4 required)" >&2
    exit 121
fi

cat > /tmp/bc-p2-validate-config-ids.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Gate 2: Verify config_id prefix matches question_id
for config in "${SEARCH_CONFIGS[@]}"; do
    config_id=$(echo "$config" | jq -r '.config_id')
    if [[ ! "$config_id" =~ ^config-${QUESTION_ID}- ]]; then
        echo "ERROR: Context contamination detected - config_id '$config_id' does not match question '$QUESTION_ID'" >&2
        exit 121
    fi
done
SCRIPT_EOF
chmod +x /tmp/bc-p2-validate-config-ids.sh && bash /tmp/bc-p2-validate-config-ids.sh

# Gate 3: Verify all configs have non-empty query
for config in "${SEARCH_CONFIGS[@]}"; do
    query=$(echo "$config" | jq -r '.websearch_params.query')
    if [ -z "$query" || "$query" == "null" ]; then
        echo "ERROR: Config has empty query" >&2
        exit 121
    fi
done

echo "Phase 2 gate check PASSED: ${#SEARCH_CONFIGS[@]} valid configs generated" >&2
```

**Gate Failure Actions:**

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 121 | Config validation failed | Do not proceed to Phase 3. Log error and skip this question. |

---

## Shell Compatibility Requirements

Claude Code executes bash via the user's default shell (often zsh). To avoid parse errors:

**PROHIBITED in inline bash:**

- Multi-line if/then/else/fi blocks
- Bash array assignments: `ARRAY=($(...))`
- Newlines between statements

**REQUIRED patterns:**

- Single-line conditionals: `[ -d "$DIR" ] && echo "exists" || echo "missing"`
- Chain with &&: `mkdir -p "$DIR" && cd "$DIR" && pwd`
- For complex logic: Write to temp script file, then execute with `bash script.sh`

---

## Next Step

After generating SEARCH_CONFIGS for current question AND passing gate check, proceed to [phase-3-batch-creation.md](phase-3-batch-creation.md).

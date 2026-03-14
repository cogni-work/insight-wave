---
name: findings-creator-llm
description: Create research findings using LLM knowledge with anti-hallucination protocols. Use for well-documented topics where web search adds less value than synthesized conceptual analysis.
---

# LLM Findings Creator

## Purpose

Create research findings from refined questions using the LLM's internal training knowledge rather than web search. Apply rigorous anti-hallucination protocols to ensure responses stay within the model's knowledge boundaries while maintaining research quality standards.

**Use this skill when:**
- Research questions benefit from synthesized conceptual knowledge (frameworks, best practices, established theories)
- LLM's training corpus provides valuable trends on the topic
- Web search would be redundant for well-documented concepts
- Rapid findings generation from model knowledge is preferred over web research

**Do NOT use when:**
- Current data or recent events are required (beyond knowledge cutoff)
- Specific statistics or proprietary information needed
- Primary source citations from academic/industry publications required
- Real-time market data or breaking news essential

## Entity Creation Reference

> **Shared reference:** See [references/findings-creator-shared/entity-creation-contract.md](../../references/findings-creator-shared/entity-creation-contract.md) for full parameter contract, heredoc pattern, dc:identifier prefix conventions (`finding-llm-` for this variant), and variant-specific frontmatter fields.

## Core Workflow

Execute these 6 phases sequentially with verification checkpoints at each boundary.

### Phase 0: Environment Resolution & Logging (Anti-Silent-Failure)

> **Shared pattern:** See [references/findings-creator-shared/environment-resolution.md](../../references/findings-creator-shared/environment-resolution.md) for the canonical environment resolution steps shared across all findings-creator variants.

**⛔ CRITICAL:** Resolve plugin root and initialize logging BEFORE any other operations.

**Step 0.0a: Resolve CLAUDE_PLUGIN_ROOT (MANDATORY FIRST)**

```bash
# Validate CLAUDE_PLUGIN_ROOT has expected structure
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ ! -d "${CLAUDE_PLUGIN_ROOT}/scripts" ]; then
  echo "[ERROR] CLAUDE_PLUGIN_ROOT does not contain scripts/ directory: ${CLAUDE_PLUGIN_ROOT}" >&2
  exit 1
fi

# MANDATORY: Source centralized plugin root resolver
RESOLVER_PATH=""
if [ -f "${CLAUDE_PLUGIN_ROOT:-}/scripts/utils/resolve-plugin-root.sh" ]; then
  RESOLVER_PATH="${CLAUDE_PLUGIN_ROOT}/scripts/utils/resolve-plugin-root.sh"
fi

if [ -n "$RESOLVER_PATH" ]; then
  source "$RESOLVER_PATH"
  CLAUDE_PLUGIN_ROOT=$(resolve_plugin_root)
  export CLAUDE_PLUGIN_ROOT
  echo "INFO: Resolved CLAUDE_PLUGIN_ROOT=${CLAUDE_PLUGIN_ROOT}" >&2
fi
```

**Step 0.0b: Resolve Entity Directories**

```bash
# Resolve entity directory names (CRITICAL for correct output paths)
ENTITY_CONFIG=""
if [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh" ]; then
  ENTITY_CONFIG="${CLAUDE_PLUGIN_ROOT}/scripts/lib/entity-config.sh"
fi

if [ -n "$ENTITY_CONFIG" ]; then
  source "$ENTITY_CONFIG"
  REFINED_QUESTIONS_DIR=$(get_directory_by_key "refined-questions")
  FINDINGS_DIR=$(get_directory_by_key "findings")
else
  REFINED_QUESTIONS_DIR="02-refined-questions"
  FINDINGS_DIR="04-findings"
fi
export REFINED_QUESTIONS_DIR FINDINGS_DIR
```

**Step 0.0c: Initialize Logging**

```bash
# Source enhanced logging utilities (with fallback)
if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] && [ -f "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh" ]; then
  source "${CLAUDE_PLUGIN_ROOT}/scripts/utils/enhanced-logging.sh"
else
  log_conditional() { echo "[$1] $2" >&2; }
  log_phase() { echo "[PHASE] ========== $1 [$2] ==========" >&2; }
  log_metric() { echo "[METRIC] $1=$2 unit=$3" >&2; }
fi

# Initialize execution log immediately
LOG_FILE="${PROJECT_PATH:-.}/.logs/findings-creator-llm/findings-creator-llm-execution-log.txt"
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

# Write log header
echo "================================================================================" >> "$LOG_FILE"
echo "LLM Findings Creator Execution Log" >> "$LOG_FILE"
echo "================================================================================" >> "$LOG_FILE"
echo "Execution Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG_FILE"
echo "Project Path: ${PROJECT_PATH:-NOT_SET}" >> "$LOG_FILE"

# Set up EXIT trap to catch crashes
trap 'echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [CRASHED] Unexpected exit" >> "${LOG_FILE:-/dev/null}"' EXIT

log_phase "findings-creator-llm" "start"
```

---

### Phase 1: Load Refined Questions

**Objective:** Load refined question entities with complete content using anti-hallucination Pattern 1 (Complete Entity Loading). Supports optional filtering via `QUESTION_PATHS` for dimension-based batching.

**Steps:**

1. Verify project path and check tool dependencies:

   ```bash
   # Validate environment
   if [ -z "${PROJECT_PATH:-}" ]; then echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [ERROR] PROJECT_PATH not set" >> "$LOG_FILE" ; echo '{"success": false, "error": "PROJECT_PATH not set"}' >&2 ; exit 111 ; fi

   # Check for yq (required for schema validation)
   if ! command -v yq &> /dev/null; then log_conditional WARN "yq not found. Install: brew install yq (required for schema validation)" ; fi

   # Check for jq (required for JSON processing)
   if ! command -v jq &> /dev/null; then echo '{"success": false, "error": "jq not found. Install: brew install jq"}' >&2 ; exit 111 ; fi
   ```

2. **Determine question source (filtered vs all):**

   ```bash
   # Check if QUESTION_PATHS is set (comma-separated list of paths)
   if [ -n "${QUESTION_PATHS:-}" ]; then log_conditional INFO "Filtered mode: Processing specific questions from QUESTION_PATHS" ; IFS=',' read -ra QUESTION_FILES <<< "${QUESTION_PATHS}" ; for path in "${QUESTION_FILES[@]}"; do if [ ! -f "$path" ]; then echo '{"success": false, "error": "Question file not found: '"$path"'"}' >&2 ; exit 112 ; fi ; done ; expected_count=${#QUESTION_FILES[@]} ; log_conditional INFO "Filtered mode: ${expected_count} questions to process" ; else log_conditional INFO "Default mode: Processing all questions in ${REFINED_QUESTIONS_DIR}/data/" ; QUESTION_FILES=(${PROJECT_PATH}/${REFINED_QUESTIONS_DIR}/data/*.md) ; expected_count=${#QUESTION_FILES[@]} ; log_conditional INFO "Default mode: ${expected_count} questions found" ; fi
   ```

3. Load questions completely (no truncation) into QUESTIONS_ARRAY
4. Verify count matching: loaded entities == expected count (anti-hallucination checkpoint)
5. Log verification status and complete phase

**Mode Summary:**

| Mode | Trigger | Questions Loaded |
|------|---------|------------------|
| Default | `QUESTION_PATHS` not set | ALL questions in `${REFINED_QUESTIONS_DIR}/data/` |
| Filtered | `QUESTION_PATHS` set | ONLY specified question files |

**Use Case:** Filtered mode enables dimension-based batching in deeper-research-1 Phase 3, where findings-creator-llm is invoked per dimension with only that dimension's questions.

**Checkpoint:** All questions loaded? Count verified? → Continue to Phase 1.5

---

### Phase 1.5: Detect Model and Resolve System Card URL

**Objective:** Detect the actual LLM model executing this skill and resolve its system card PDF URL from a known lookup table. No web search required.

**Steps:**

1. **Detect current model from execution context** (CRITICAL - do not hardcode):
   - Read model identifier from Claude Code execution environment
   - Common model IDs: `claude-haiku-4-5-20251001`, `claude-sonnet-4-6-20260220`, `claude-opus-4-6-20260219`
   - Store detected model in `LLM_MODEL_ID` variable (e.g., `claude-opus-4-6-20260219`)
   - Derive display name from ID (e.g., `Claude Haiku 4.5`, `Claude Sonnet 4.6`, `Claude Opus 4.6`)
   - Store display name in `LLM_MODEL_NAME` variable
   - Derive knowledge cutoff from model ID year-month (e.g., `2025-10` for haiku, `2025-05` for sonnet/opus 4.6)
   - Store in `LLM_KNOWLEDGE_CUTOFF` variable

2. **Resolve system card URL from lookup table** (no WebSearch needed):

   Match `LLM_MODEL_ID` against the known system card URL table below. Use prefix matching on the model family (ignore date suffix):

   | Model Family Prefix | Display Name | System Card URL |
   |---------------------|-------------|-----------------|
   | `claude-3-5-haiku` | Claude 3.5 Haiku | `https://assets.anthropic.com/m/1cd9b8fc0a5c4f10/original/Claude-3-5-Haiku-Model-Card.pdf` |
   | `claude-3-5-sonnet` | Claude 3.5 Sonnet | `https://assets.anthropic.com/m/61e7d27f8c8f5919/original/Claude-3-5-Sonnet-Model-Card.pdf` |
   | `claude-haiku-4-5` | Claude 4.5 Haiku | `https://assets.anthropic.com/m/1cd9b8fc0a5c4f10/original/Claude-3-5-Haiku-Model-Card.pdf` |
   | `claude-sonnet-4-5` | Claude 4.5 Sonnet | `https://assets.anthropic.com/m/12f214efcc2f457a/original/Claude-Sonnet-4-5-System-Card.pdf` |
   | `claude-opus-4-5` | Claude 4.5 Opus | `https://assets.anthropic.com/m/12f214efcc2f457a/original/Claude-Sonnet-4-5-System-Card.pdf` |
   | `claude-sonnet-4-6` | Claude 4.6 Sonnet | `https://assets.anthropic.com/m/12f214efcc2f457a/original/Claude-Sonnet-4-5-System-Card.pdf` |
   | `claude-opus-4-6` | Claude 4.6 Opus | `https://assets.anthropic.com/m/12f214efcc2f457a/original/Claude-Sonnet-4-5-System-Card.pdf` |

   **Matching logic:** Strip the date suffix (last `-YYYYMMDD`) from `LLM_MODEL_ID`, then match against the "Model Family Prefix" column. Use longest prefix match.

   **Fallback:** If no prefix matches, set `SYSTEM_CARD_URL` to `https://docs.anthropic.com/en/docs/about-claude/models` and log a warning.

3. Store resolved URL in `SYSTEM_CARD_URL` variable for use in Phase 4

4. Log model detection and system card URL resolution:
   - Log: "Detected model: {LLM_MODEL_ID} ({LLM_MODEL_NAME})"
   - Log: "Knowledge cutoff: {LLM_KNOWLEDGE_CUTOFF}"
   - Log: "System card URL: {SYSTEM_CARD_URL}"

**Checkpoint:** Model detected? System card URL resolved? All variables populated (LLM_MODEL_ID, LLM_MODEL_NAME, LLM_KNOWLEDGE_CUTOFF, SYSTEM_CARD_URL)? → Continue to Phase 2

---

### Phase 2: Generate LLM Responses

**Objective:** Generate LLM responses for ALL refined questions loaded in Phase 1. Use extended thinking to generate substantive responses from LLM's training knowledge while respecting knowledge boundaries. **All content must be generated in the target language specified by CONTENT_LANGUAGE.**

**Steps:**

1. Initialize response storage and iteration tracking:
   - Set `RESPONSES_ARRAY` to empty array
   - Set `question_counter` to 0
   - Set `total_questions` to length of `QUESTIONS_ARRAY` (from Phase 1)
   - Log: "Phase 2: Starting response generation for {total_questions} questions"

2. **FOR EACH question in QUESTIONS_ARRAY:**

   a. Increment counter: `question_counter++`

   b. Read question entity:
      - Extract: question text, dc:identifier (full entity ID including `question-` prefix), dimension_ref, dc:title from question file
      - CRITICAL: The dc:identifier value (e.g., `question-digital-workplace-implementation-4a2b3c4d`) must be stored for wikilink generation - it matches the filename exactly
      - Verify: question entity loaded completely (anti-hallucination checkpoint)

   c. Detect target language:
      - Read CONTENT_LANGUAGE environment variable
      - Default to "en" if not set
      - Store in response metadata as content_language

   d. Apply extended thinking to assess knowledge availability and formulate response **in the target language**:

      **Step 1: Entity-Specific Knowledge Assessment (MANDATORY)**

      Before generating ANY content, explicitly answer these questions:

      1. Does this question ask about a SPECIFIC NAMED ENTITY's capabilities/services/products?
         - Pattern: "What [services/features/products] does [Entity] offer/provide/have?"
         - Example entities: Companies (DB Systel, T-Systems, Amazon AWS), Products, Organizations

      2. IF the question targets a specific entity:
         - Ask yourself: "Do I have CONCRETE, SPECIFIC training knowledge about [Entity]'s [Capability]?"
         - Examples of SPECIFIC knowledge: "AWS offers S3 storage with 99.999999999% durability"
         - Examples of NO specific knowledge: "I don't know what specific Zero Trust services DB Systel offers"

      3. **Honest Assessment Outcomes:**

         **A) I HAVE specific entity knowledge** (e.g., Amazon AWS, Microsoft Azure, well-documented companies):
         - Proceed with standard finding generation
         - Include specific entity facts from training data
         - Example: "AWS bietet mit AWS Zero Trust Architecture folgende Services..."
         - Set `entity_knowledge_gap: false`

         **B) I DO NOT HAVE specific entity knowledge** (e.g., DB Systel, regional companies):
         - **MUST explicitly acknowledge** at the TOP of the Content section (see Entity Knowledge Gap Templates below)
         - Then provide general background knowledge (clearly labeled as general)
         - Set `entity_knowledge_gap: true`
         - Quality score impact: Topical Relevance capped at 0.55 (see Phase 3)

      **Step 2: Standard Knowledge Assessment**
      - Assess LLM internal knowledge availability for conceptual/framework aspects
      - Consider: training data coverage, knowledge depth, potential gaps
      - Formulate response strategy based on knowledge confidence

   e. Generate 5-section finding content **in the target language**:
      - **Content:** 150-300 words from LLM training knowledge with disclaimers when incomplete
      - **Key Trends:** 3-6 specific, actionable bullets (frameworks, best practices, patterns)
      - **Methodology:** Language-aware disclaimer using detected model (see examples below)
      - **Relevance Assessment:** Placeholder (populated in Phase 3)
      - **Source:** Model `{LLM_MODEL_ID}`, cutoff `{LLM_KNOWLEDGE_CUTOFF}`, type `llm_internal_knowledge`

   f. Store response in RESPONSES_ARRAY with metadata:
      - Include: dc:identifier (full entity ID for wikilink, e.g., `question-digital-workplace-implementation-4a2b3c4d`), content_language, all 5 sections
      - Include: source_metadata (model, knowledge_cutoff, system_card_url from Phase 1.5)
      - Set quality_scores to null (will be calculated in Phase 3)

   g. Log iteration progress: "Phase 2: Processed question {question_counter} of {total_questions}: {question_id}"

3. **Verify ALL questions processed** (anti-hallucination gate check):
   - IF `RESPONSES_ARRAY.length < QUESTIONS_ARRAY.length`:
     - Log ERROR: "Phase 2 incomplete: {RESPONSES_ARRAY.length} responses generated vs {QUESTIONS_ARRAY.length} questions loaded"
     - Log missing question IDs
     - HALT execution (do not proceed to Phase 3)
   - ELSE:
     - Log SUCCESS: "Phase 2 complete: All {total_questions} questions processed"

4. Complete phase and proceed to Phase 3

**Language-Aware Methodology Disclaimers:**

Use detected model variables (`{LLM_MODEL_NAME}`, `{LLM_KNOWLEDGE_CUTOFF}`) in disclaimers:

- **English (en):** "Information source: {LLM_MODEL_NAME} internal training knowledge (cutoff {LLM_KNOWLEDGE_CUTOFF}). Trends synthesized from training corpus. Consider as conceptual guidance rather than empirical research data."

- **German (de):** "Informationsquelle: {LLM_MODEL_NAME} internes Trainingswissen (Stand {LLM_KNOWLEDGE_CUTOFF}). Erkenntnisse aus dem Trainingskorpus synthetisiert. Als konzeptionelle Orientierung betrachten, nicht als empirische Forschungsdaten."

- **French (fr):** "Source d'information: connaissances de formation internes de {LLM_MODEL_NAME} (limite {LLM_KNOWLEDGE_CUTOFF}). Informations synthétisées à partir du corpus de formation. À considérer comme orientation conceptuelle plutôt que données de recherche empiriques."

- **Spanish (es):** "Fuente de información: conocimiento de entrenamiento interno de {LLM_MODEL_NAME} (límite {LLM_KNOWLEDGE_CUTOFF}). Perspectivas sintetizadas del corpus de entrenamiento. Considerar como orientación conceptual en lugar de datos de investigación empíricos."

- **Other languages:** Translate the English template to the target language using detected model variables

**Entity-Specific Knowledge Gap Templates:**

When `entity_knowledge_gap == true` (question asks about specific entity's capabilities but LLM lacks specific knowledge), use these templates at the TOP of the Content section:

- **German (de):** "**Hinweis:** Es liegen keine spezifischen Trainingsdaten zu {Entity}s {Capability}-Angeboten vor. Die folgenden Informationen beschreiben {Topic} allgemein und können nicht bestätigen, ob {Entity} diese Services tatsächlich anbietet."

- **English (en):** "**Note:** No specific training data available about {Entity}'s {Capability} offerings. The following information describes {Topic} in general and cannot confirm whether {Entity} actually offers these services."

- **French (fr):** "**Note:** Aucune donnée d'entraînement spécifique disponible concernant les offres de {Capability} de {Entity}. Les informations suivantes décrivent {Topic} en général et ne peuvent pas confirmer si {Entity} propose effectivement ces services."

- **Spanish (es):** "**Nota:** No hay datos de entrenamiento específicos disponibles sobre las ofertas de {Capability} de {Entity}. La siguiente información describe {Topic} en general y no puede confirmar si {Entity} realmente ofrece estos servicios."

**Content Structure with Entity Knowledge Gap:**

```markdown
## {HEADER_CONTENT}

**Hinweis:** Es liegen keine spezifischen Trainingsdaten zu {Entity}s {Capability}-Angeboten vor.
Die folgenden Informationen beschreiben {Topic} allgemein und können nicht bestätigen,
ob {Entity} diese Services tatsächlich anbietet.

---

{General background knowledge about the topic - clearly presented as general context,
not as information about the specific entity. 150-300 words.}
```

**Checkpoint:** Responses generated for all questions in target language? → Continue to Phase 3

---

### ⛔ PHASE 2 → PHASE 3 GATE CHECK

**Before proceeding to Phase 3, verify Phase 2 completeness:**

**Verification Steps:**

1. Check response count matches question count:
   - Expected: `RESPONSES_ARRAY.length == QUESTIONS_ARRAY.length`
   - If mismatch detected, log error with specific counts

2. Identify any missing questions:
   - Compare question_ids in QUESTIONS_ARRAY vs RESPONSES_ARRAY
   - Log any question_ids that were loaded but not processed

3. Gate decision:
   - **IF verification FAILS:**
     - Log ERROR: "Phase 2 incomplete - cannot proceed to quality assessment"
     - Display: Questions loaded, Responses generated, Missing count
     - HALT execution (do not proceed to Phase 3)
   - **IF verification PASSES:**
     - Log SUCCESS: "Phase 2 gate check passed - all {count} questions processed"
     - Proceed to Phase 3

**Why this gate:** Prevents partial execution from proceeding undetected. Ensures quality assessment (Phase 3) has complete dataset to evaluate. Critical for maintaining research integrity.

---

### Phase 3: Apply Quality Assessment

> **Shared framework:** See [references/findings-creator-shared/quality-assessment.md](../../references/findings-creator-shared/quality-assessment.md) for dimension definitions, weight tables, and threshold logic shared across all variants. This variant uses LLM weights (40/30/20/10) with entity knowledge gap adjustment.

**Objective:** Calculate 4-dimension quality scores for each response using finding-quality-standards.md framework.

For EACH generated response, calculate scores using extended thinking:

1. **Topical Relevance (40% weight):** Assess question-response alignment (0.9+ direct, 0.7-0.89 high, 0.5-0.69 moderate, <0.5 weak)

2. **Content Completeness (30% weight):** Evaluate substantiveness via word count, trends count, methodology presence, framework specificity. Formula: `(word_score × 0.40) + (trends_score × 0.30) + (methodology_score × 0.20) + (data_score × 0.10)`

3. **Source Reliability (20% weight):** Fixed at **0.50** for LLM knowledge (Tier 3 - conceptual synthesis)

4. **Evidentiary Value (10% weight):** Assess research utility (0.9+ specific frameworks, 0.7-0.89 clear concepts, 0.5-0.69 general trends, <0.5 vague)

5. **Entity Knowledge Gap Adjustment (CRITICAL):**

   When `entity_knowledge_gap == true` (question targets specific entity but LLM lacks entity-specific knowledge):

   - **Topical Relevance Cap:** Maximum 0.55 (general content cannot directly answer entity-specific question)
     - Score 0.55 if general content is highly relevant as background
     - Score 0.40-0.50 if general content is moderately relevant
     - Score <0.40 if general content provides minimal useful context

   - **Rationale in Relevance Assessment:** Include note: "Entity-specific knowledge gap acknowledged - general background provided for {Topic}, not {Entity}'s specific offerings"

   - **Composite Impact:** Typically results in scores around 0.50-0.58
     - May still PASS threshold (0.50) if other dimensions are strong
     - Finding is created but clearly labeled as general knowledge

   - **Auto-FAIL Trigger:** If Topical Relevance falls below 0.40 (general content not useful as background), set `quality_status: "FAIL"` with `rejection_reason: "entity_knowledge_gap_insufficient_background"`

6. **Compute Composite Score:** `(rel × 0.40) + (comp × 0.30) + (0.50 × 0.20) + (evid × 0.10)`

7. **Apply Threshold:** `composite_score >= 0.50` → PASS, else FAIL

8. Update Relevance Assessment section with scores and rationales

9. Log assessment results and complete phase

**Checkpoint:** All responses assessed? Scores calculated? → Continue to Phase 4

---

### Phase 4: Create Finding Entities

**Objective:** Create finding entities for PASS responses and log rejections for FAIL responses.

**⛔ GATE CHECK:** Before starting, verify Phase 3 outputs exist (all responses assessed with quality scores).

**Schema Reference (Pattern 3 from INTEGRATION.md):** Before entity creation, understand required fields:

- READ: ../../schemas/finding-entity.schema.json
- EXTRACT: Required fields (question_ref for Path B), field patterns, linking constraints
- NOTE: Findings created via findings-creator-llm use Path B (question_ref links to refined question entity, no query batch)
- VALIDATION: Schema validation occurs automatically after entity write (Step 7, warning mode)

For EACH PASS response:

1. Generate finding UUID: `finding-llm-{uuid}` (8-character hex)

2. Construct complete finding entity with YAML frontmatter **matching finding-entity.schema.json**:

   **Dublin Core Metadata (REQUIRED - must match schema field names):**
   - `dc:title: "Finding: {semantic-title}"` - Human-readable finding title
   - `dc:identifier: "finding-llm-{semantic-slug}-{8-char-hash}"` - **REQUIRED** unique identifier matching filename (pattern: `^finding-[a-z0-9-]+-[a-f0-9]{8}$`)
   - `dc:created: "{ISO 8601 timestamp}"` - **REQUIRED** creation timestamp (e.g., `2025-11-26T07:44:00Z`)
   - `dc:type: "finding"` - Entity type constant
   - `dc:creator: "findings-creator-llm"` - Skill that created entity

   **Entity Type (REQUIRED):**
   - `entity_type: "finding"` - **REQUIRED** entity type identifier

   **Finding Content (REQUIRED):**
   - `finding_text: "{synthesized trend}"` - **REQUIRED** main finding content (1-2 sentence summary)

   **Research Linkage (REQUIRED with wikilinks - upstream-only pattern):**
   - `question_ref: "[[${REFINED_QUESTIONS_DIR}/data/{dc:identifier}]]"` - Wikilink to parent question using full entity identifier from dc:identifier field (e.g., `question-digital-workplace-implementation-4a2b3c4d`). CRITICAL: Use the complete dc:identifier value which includes the `question-` prefix and matches the filename exactly. Pattern: `^\\[\\[${REFINED_QUESTIONS_DIR}/data/question-[a-z0-9-]+-[a-f0-9]{8}\\]\\]$`

   **LLM-Specific Metadata (REQUIRED - use detected model variables from Phase 1.5):**
   - `source_type: "llm_internal_knowledge"`
   - `source_url: "{SYSTEM_CARD_URL}"` - URL to model's official system card PDF (retrieved in Phase 1.5)
   - `llm_model: "{LLM_MODEL_ID}"` - **DETECTED** model ID (e.g., `claude-haiku-4-5-20251001`, `claude-opus-4-6-20260219`)
   - `llm_knowledge_cutoff: "{LLM_KNOWLEDGE_CUTOFF}"` - **DETECTED** cutoff date (e.g., `2025-10`, `2025-05`)
   - `content_source: "llm_internal"`
   - `content_language: "{CONTENT_LANGUAGE}"` - ISO 639-1 language code (e.g., "en", "de", "fr", "es")
   - `webfetch_success: false`
   - `enhanced_content_retrieved: false`

   **Quality Assessment Metadata (REQUIRED):**
   - `quality_score: {0.00-1.00}` - Composite score from Phase 3
   - `quality_status: "{PASS|FAIL}"` - Status based on ≥0.50 threshold
   - `confidence_level: "{high|medium|low}"` - Maps from quality_score: ≥0.75=high, ≥0.60=medium, <0.60=low
   - `finding_type: "qualitative"` - LLM findings are qualitative (no quantitative data)
   - `quality_dimensions:` - 4-dimension scores
     - `topical_relevance: {0.00-1.00}`
     - `content_completeness: {0.00-1.00}`
     - `source_reliability: 0.50` - Fixed for LLM knowledge (Tier 3)
     - `evidentiary_value: {0.00-1.00}`

   **Schema Version:**
   - `schema_version: "3.0"`

   **Source Linkage (initially empty):**
   - `source_id: ""` - Will be populated by source-creator if needed

   **Tags (REQUIRED):**
   - `tags: [finding, source/llm, dimension/{dimension-slug}]`

3. Include markdown body with **5-section structure matching findings-creator format**:

   **Language Template Reference:** Use section headers from `references/language-templates.md` section `04-findings` based on CONTENT_LANGUAGE. For German (de), headers are automatically localized (e.g., "Content" → "Inhalt", "Key Trends" → "Kernerkenntnisse").

   ```markdown
   # {Finding Title}

   ## {HEADER_CONTENT}

   {150-300 words substantive content from LLM training knowledge}

   ## {HEADER_KEY_TRENDS}

   - {Trend 1: specific, actionable}
   - {Trend 2: specific, actionable}
   - {Trend 3: specific, actionable}
   {3-6 bullets total}

   ## {HEADER_METHODOLOGY}

   {LLM disclaimer in target language using detected model}
   Example: "Information source: {LLM_MODEL_NAME} internal training knowledge (cutoff {LLM_KNOWLEDGE_CUTOFF}). Trends synthesized from training corpus. Consider as conceptual guidance rather than empirical research data."

   ## {HEADER_RELEVANCE_ASSESSMENT}

   **Composite Score**: {quality_score} | **Threshold**: 0.50 | **Status**: {PASS|FAIL}

   **Dimension Scores:**
   - Topical Relevance (40%): {score} - {rationale}
   - Content Completeness (30%): {score} - {rationale}
   - Source Reliability (20%): 0.50 - LLM internal knowledge (Tier 3)
   - Evidentiary Value (10%): {score} - {rationale}

   **Overall Rationale**: {assessment summary}

   ## {HEADER_SOURCE}

   **Model**: {LLM_MODEL_NAME} ({LLM_MODEL_ID})
   **Knowledge Cutoff**: {LLM_KNOWLEDGE_CUTOFF}
   **System Card**: {SYSTEM_CARD_URL}
   **Source Entity**: Will be created in 07-sources/data/ by source-creator
   ```

   **Header Variable Mapping (04-findings):**

   | Variable | English (en) | German (de) |
   |----------|--------------|-------------|
   | `HEADER_CONTENT` | Content | Inhalt |
   | `HEADER_KEY_TRENDS` | Key Trends | Kernerkenntnisse |
   | `HEADER_METHODOLOGY` | Methodology & Data Points | Methodik & Datenpunkte |
   | `HEADER_RELEVANCE_ASSESSMENT` | Relevance Assessment | Relevanz-Bewertung |
   | `HEADER_SOURCE` | Source | Quelle |

4. Validate 5-section compliance (all sections present, word/bullet counts met)

5. Validate YAML frontmatter against finding-entity.schema.json:
   - **REQUIRED fields present**: tags, dc:creator, dc:title, dc:identifier, dc:created, entity_type, finding_text, question_ref
   - **dc:identifier pattern**: `^finding-[a-z0-9-]+-[a-f0-9]{8}$` (must match filename)
   - **question_ref pattern**: `^\\[\\[${REFINED_QUESTIONS_DIR}/data/question-[a-z0-9-]+-[a-f0-9]{8}\\]\\]$`
   - ISO 8601 timestamps valid (dc:created)
   - LLM metadata uses detected model (not hardcoded)

6. Write to `${FINDINGS_DIR}/data/finding-llm-{uuid}.md`

7. **Schema Validation (Pattern 1 from INTEGRATION.md):** Validate entity against finding-entity.schema.json:

   ```bash
   # After entity file write
   validation_result=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-entity-schema.sh" \
     --entity-type "finding" \
     --entity-file "${PROJECT_PATH}/${FINDINGS_DIR}/data/finding-llm-${uuid}.md" \
     --schema-path "${CLAUDE_PLUGIN_ROOT}/schemas/finding-entity.schema.json" \
     --json)

   validation_status=$(echo "${validation_result}" | jq -r '.data.status')

   if [ "${validation_status}" != "success" ]; then log_conditional WARN "Schema validation warning for: finding-llm-${uuid}.md" ; echo "${validation_result}" | jq '.data.validation_errors' >&2 ; else log_conditional INFO "Schema validation passed for: finding-llm-${uuid}.md" ; fi
   ```

8. Verify file creation and increment counter

For EACH FAIL response:

9. Log rejection to `.rejected-llm-findings.json` with scores, rationale, content preview
10. Increment rejection counter

Complete phase with summary logging

**Checkpoint:** All PASS findings created? All FAIL responses logged? YAML frontmatter complete? → Continue to Phase 5

---

### Phase 5: Verify Completion

**Objective:** Validate workflow completion and return execution summary.

1. Count created findings and verify against internal counter
2. Calculate average quality score from PASS findings
3. Generate execution summary with: processed count, created/rejected counts, average quality score, success rate, quality distribution (dimension averages), output locations
4. Log completion and return summary
5. Clear EXIT trap and log successful completion:

   ```bash
   # Clear the crash detection trap (skill completed successfully)
   trap - EXIT

   # Log successful completion
   echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [COMPLETE] findings-creator-llm finished successfully" >> "$LOG_FILE"
   echo "================================================================================" >> "$LOG_FILE"
   echo "END OF EXECUTION LOG" >> "$LOG_FILE"
   echo "================================================================================" >> "$LOG_FILE"
   ```

**Final Checkpoint:** Execution summary generated? All phases completed? → SUCCESS

---

## Input Requirements

**Required:**

- `PROJECT_PATH` - Absolute path to research project workspace
- Refined question entities in `${PROJECT_PATH}/${REFINED_QUESTIONS_DIR}/data/`

**Optional:**

- `DEBUG_MODE` - Set to `true` for verbose logging (default: `false`)
- `CONTENT_LANGUAGE` - Two-letter ISO 639-1 language code (e.g., "en", "de", "fr", "es"). Default: "en". Affects all generated content including findings, key trends, and methodology disclaimers.
- `QUESTION_PATHS` - Comma-separated list of absolute paths to specific question files to process. When set, only these questions are processed (filtered mode). When not set, all questions in `${REFINED_QUESTIONS_DIR}/data/` are processed (default mode). Use case: dimension-based batching in deeper-research-1 Phase 3.

**Environment:**

- `CLAUDE_PLUGIN_ROOT` - Must be set for script sourcing

**Invocation Example:**
```bash
# Via skill interface
Skill: "findings-creator-llm"
Context: Project path = /Users/username/research-project
```

---

## Output Format

**Created Findings:**

- **Location:** `${PROJECT_PATH}/${FINDINGS_DIR}/data/finding-llm-{semantic-slug}-{8-char-hash}.md`
- **Schema Version:** 3.0 (5-section comprehensive structure matching findings-creator)
- **Source Type:** `llm_internal_knowledge`
- **Model Reference:** Detected at runtime (e.g., Claude Haiku 4.5, Claude Sonnet 4.6, Claude Opus 4.6)

**Rejected Findings:**
- **Location:** `${PROJECT_PATH}/.rejected-llm-findings.json`
- **Format:** JSON array with rejection metadata

**Execution Log:**
- **Location:** `${PROJECT_PATH}/.logs/findings-creator-llm/findings-creator-llm-execution-log.txt`
- **Format:** Enhanced logging format with timestamps, phases, metrics

**LLM Source URL Format:**

- Pattern: `https://assets.anthropic.com/m/{hash}/original/{model-name}-System-Card.pdf`
- Example: `https://assets.anthropic.com/m/12f214efcc2f457a/original/Claude-Sonnet-4-5-System-Card.pdf`
- Purpose: Links to official model system card PDF for transparency and source verification
- Note: URL resolved from known lookup table in Phase 1.5 (no web search needed)

**Source Entity Chain:**

- All LLM findings from same model → ONE source entity: `source-llm-{LLM_MODEL_ID}` (e.g., `source-llm-claude-opus-4-6-20260219`)
- Source entity → ONE publisher entity: `publisher-anthropic-claude`
- Extreme deduplication: First LLM finding creates entities, rest reuse

---

## Anti-Hallucination Safeguards

This skill implements all 5 anti-hallucination patterns from [anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md):

### Pattern 1: Complete Entity Loading
- Load ALL refined questions before processing (no truncation)
- Verify count matching: loaded entities == expected count
- Halt on mismatch (never proceed with incomplete data)

### Pattern 2: Verification Checkpoints
- Mandatory checkpoint at each of 6 phase boundaries
- Validate outputs before proceeding to next phase
- Log verification status at every checkpoint

### Pattern 3: Evidence-Based Processing
- All responses grounded in LLM's actual training knowledge
- No fabrication beyond knowledge boundaries
- Use disclaimers when knowledge is incomplete or uncertain

### Pattern 4: No Fabrication Rule
- Never invent statistics, data, or sources
- Use explicit disclaimer template for methodology section
- Apply lower quality scores for knowledge gaps (honest assessment)
- Flag limitations transparently in finding content

### Pattern 5: Provenance Integrity

- Reference model explicitly using detected `{LLM_MODEL_ID}` (not hardcoded)
- Include knowledge cutoff date from detected `{LLM_KNOWLEDGE_CUTOFF}`
- Validated wikilinks to refined questions (pattern: `question-*-{8-char-hash}`)
- Complete audit trail with quality metadata

**Knowledge Boundary Constraint:**
"Only use information from LLM's training knowledge. When knowledge is limited or uncertain, use explicit disclaimers. Never fabricate data, statistics, or sources to compensate for knowledge gaps."

---

## Quality Standards

### 4-Dimension Scoring Framework

Per [finding-quality-standards.md](../../references/finding-quality-standards.md):

**Dimension 1: Topical Relevance (40% weight)**
- 0.90-1.00: Direct answer to refined question
- 0.70-0.89: High conceptual alignment
- 0.50-0.69: Moderate relevance
- <0.50: Tangential or off-topic

**Dimension 2: Content Completeness (30% weight)**
- 0.90-1.00: Comprehensive (250+ words, 5+ trends)
- 0.70-0.89: Substantive (200-249 words, 4 trends)
- 0.50-0.69: Adequate (150-199 words, 3 trends)
- <0.50: Sparse or minimal

**Dimension 3: Source Reliability (20% weight)**
- **Fixed at 0.50** for LLM internal knowledge (Tier 3)
- Rationale: Conceptual synthesis without primary source attribution

**Dimension 4: Evidentiary Value (10% weight)**
- 0.90-1.00: Specific frameworks, methodologies, documented patterns
- 0.70-0.89: Clear concepts with some specificity
- 0.50-0.69: General trends, limited specificity
- <0.50: Vague claims, no concrete frameworks

### Composite Score Threshold

**Minimum:** 0.50 (balanced precision-recall trade-off)

**Decision Logic:**
- `composite_score >= 0.50` → PASS (create finding)
- `composite_score < 0.50` → FAIL (reject, log to .rejected-llm-findings.json)

### Expected Performance

**Typical Rejection Rate:** 10-30% (LLM knowledge generally substantive)
**Average Quality Score:** 0.60-0.75 (moderate to good quality)
**Primary Rejection Reason:** Content completeness <0.40 (insufficient depth)

---

## Debugging

This skill implements three-layer debugging architecture. See [debugging-guide.md](../../references/debugging-guide.md) for complete navigation.

### Layer 1: Behavioral Anchors

**Phase transitions:**
```bash
log_phase "Load Refined Questions" "start"
log_phase "Load Refined Questions" "complete"
```

**Progress logging:**
```bash
log_conditional INFO "Processing question ${i} of ${QUESTION_COUNT}"
log_conditional INFO "Quality score: ${COMPOSITE_SCORE} (${QUALITY_STATUS})"
```

**Metrics tracking:**
```bash
log_metric "findings_created" ${FINDINGS_CREATED} "count"
log_metric "average_quality_score" ${AVG_QUALITY_SCORE} "score"
```

### Layer 2: Enhanced Logging

Enable verbose logging:
```bash
export DEBUG_MODE=true
# Skill execution with detailed logs
```

Log locations:
- Execution log: `${PROJECT_PATH}/.logs/findings-creator-llm/findings-creator-llm-execution-log.txt`
- Rejection log: `${PROJECT_PATH}/.rejected-llm-findings.json`

### Layer 3: Validation Checkpoints

**Phase boundaries:** Verify outputs before proceeding
**Count matching:** Loaded entities == expected count
**System card URL:** Verify URL retrieved successfully in Phase 1.5
**Quality thresholds:** Composite score >= 0.50
**Section compliance:** All 5 sections present in findings

---

## Related References

- [anti-hallucination-foundations.md](../../references/anti-hallucination-foundations.md) - Core prevention patterns
- [entity-structure-guide.md](../../references/entity-structure-guide.md) - Finding entity format
- [finding-quality-standards.md](../../references/finding-quality-standards.md) - 4-dimension scoring framework
- [findings-creator/SKILL.md](../findings-creator/SKILL.md) - Web-based findings creation (comparison)

---

## Version History

**v1.4.0** (2026-02-26)

- **Bug fix**: Agent definition missing `Bash` and `Read` tools — only had `Skill`, causing all 6 phases to fail silently (0 findings produced)
- **Enhancement**: Phase 1.5 now uses a hardcoded system card URL lookup table instead of WebSearch, eliminating tool dependency on WebSearch
- Updated model ID examples throughout to current Claude 4.5/4.6 family (was referencing deprecated 3.5/4.5 IDs)
- Knowledge cutoff examples updated to `2025-05`/`2025-10`

**v1.3.1** (2026-01-02)

- **Bug fix**: Added missing directory resolution code block (Step 0.0b) to Phase 0
- Sources `entity-config.sh` to resolve `REFINED_QUESTIONS_DIR` and `FINDINGS_DIR` correctly
- Fallback values use correct directories (`02-refined-questions`, `04-findings`)
- Replaced all `04-findings` and `02-refined-questions` template placeholders with resolved `${FINDINGS_DIR}` and `${REFINED_QUESTIONS_DIR}` variables
- Fixes issue where findings were written to wrong directory (e.g., `03-findings` instead of `04-findings`)

**v1.3.0** (2025-12-11)

- **Enhancement**: Added mandatory entity-specific knowledge self-assessment in Phase 2 extended thinking
- Clear guidance to distinguish "I have specific entity knowledge" (e.g., AWS) vs "I don't have specific entity knowledge" (e.g., DB Systel)
- Language-aware entity knowledge gap disclaimer templates (prominently placed at TOP of Content section)
- Quality score adjustment: Topical Relevance capped at 0.55 when entity knowledge is lacking
- New rejection reason: `entity_knowledge_gap_insufficient_background` for auto-FAIL when general content not useful
- Findings with entity knowledge gaps still created but clearly labeled as "general knowledge only"

**v1.2.0** (2025-12-08)

- **Feature**: Added `QUESTION_PATHS` parameter for filtered question processing
- Supports dimension-based batching in deeper-research-1 Phase 3
- Default mode (no `QUESTION_PATHS`): Process all questions (backward compatible)
- Filtered mode (`QUESTION_PATHS` set): Process only specified questions
- Updated Phase 1 to detect mode and validate filtered paths

**v1.1.0** (2025-11-28)

- **Bug fix A**: Finding entity schema compliance - added required fields (dc:identifier, dc:created, entity_type, finding_text) matching finding-entity.schema.json
- **Bug fix B**: Dynamic model detection - replaced hardcoded `claude-sonnet-4-5-20250929` with runtime detection of actual executing model (LLM_MODEL_ID, LLM_MODEL_NAME, LLM_KNOWLEDGE_CUTOFF)
- **Bug fix C**: Wikilink format - question_ref now uses full dc:identifier with `question-` prefix
- Markdown body structure aligned with findings-creator (5 sections: Content, Key Trends, Methodology & Data Points, Relevance Assessment, Source)
- Added confidence_level and finding_type fields for schema compliance

**v1.0.0** (2025-11-26)

- Initial implementation: 6-phase workflow with LLM knowledge generation
- Phase 1.5: Dynamic system card URL retrieval via web search
- Anti-hallucination protocols: Complete loading, verification checkpoints, evidence-based processing
- Quality assessment: 4-dimension scoring with 0.50 threshold
- Model citation: Claude Sonnet 4.5 reference with knowledge cutoff and system card link
- Enhanced logging: Phase transitions, progress updates, metrics tracking

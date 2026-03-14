# Phase 3: Term Analysis

Analyze findings to extract recurring technical terms appearing in 2+ findings.

---

## ⛔ Entry Gate

```bash
cat > /tmp/ke-phase3-gate.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Check if findings exist from Phase 2
findings_count=$(find "${PROJECT_PATH}/04-findings/data" -maxdepth 1 -name "finding-*.md" -type f 2>/dev/null | wc -l | tr -d ' ')

if [ "$findings_count" -lt 2 ]; then
  echo "Phase 2 incomplete: insufficient findings (need 2+, found $findings_count)" >&2
  exit 1
fi

# Verify dimension mappings were created
if [ ! -f "${PROJECT_PATH}/.metadata/knowledge-extractor-dimension-mapping.txt" ] || \
   [ ! -s "${PROJECT_PATH}/.metadata/knowledge-extractor-dimension-mapping.txt" ]; then
  echo "Phase 2 incomplete: dimension mapping not found" >&2
  exit 1
fi
SCRIPT_EOF
chmod +x /tmp/ke-phase3-gate.sh && bash /tmp/ke-phase3-gate.sh
```

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 3.1: Extract terms from findings [in_progress]
- Phase 3.2: Filter recurring terms (2+) [pending]
- Phase 3.3: Apply prioritization rules [pending]
```

---

## Step 1: Extract Terms from Findings

```bash
log_phase "Phase 3: Term Analysis" "start"

# Bash 3.2 compatible - use parallel indexed arrays for term tracking
TERM_KEYS=()          # term names
TERM_FREQUENCIES=()   # term → count
TERM_FINDING_LISTS=() # term → space-separated finding filenames
```

**LLM Execution:** For each finding in `findings_list`:

1. Read finding content
2. Extract technical terms using semantic analysis:
   - **Capitalized phrases:** Multi-word terms (e.g., "Machine Learning", "API Gateway")
   - **Acronyms:** 2-5 uppercase letters (e.g., "RAG", "LLM", "REST")
   - **Hyphenated terms:** Technical compounds (e.g., "fine-tuning", "cross-validation")
   - **Domain terminology:** Frameworks, metrics, techniques, tools, methods, standards
3. Normalize terms: lowercase for comparison, preserve original for display
4. Update term frequency and append to findings list using parallel arrays

**Output structure (conceptual):**

```json
TERM_KEYS = ["machine learning", "fine-tuning", "RAG"]
TERM_FREQUENCIES = [5, 3, 2]
TERM_FINDING_LISTS = [
  "finding-a.md finding-b.md finding-c.md ...",
  "finding-a.md finding-d.md finding-e.md",
  "finding-b.md finding-f.md"
]
```

**Mark 3.1 complete.**

---

## Step 2: Filter Recurring Terms

```bash
RECURRING_TERMS=()

for i in "${!TERM_KEYS[@]}"; do
  [ ${TERM_FREQUENCIES[$i]} -ge 2 ] && RECURRING_TERMS+=("${TERM_KEYS[$i]}")
done

recurring_count=${#RECURRING_TERMS[@]}
log_conditional INFO "Found $recurring_count recurring terms (2+ findings)"
```

**Early exit handling:**

```bash
if [ $recurring_count -eq 0 ]; then
  log_conditional INFO "No recurring terms - continuing to Phase 5 (megatrend clustering)"
  # Skip Phase 4, proceed to Phase 5
fi
```

**Mark 3.2 complete.**

---

## Step 3: Apply Prioritization Rules

**LLM Execution:** Categorize and filter `RECURRING_TERMS`:

**Include (High Priority):**

| Category | Examples |
|----------|----------|
| Frameworks | RAG Framework, Transformer Architecture |
| Metrics | F1 Score, BLEU Score, Perplexity |
| Techniques | Tokenization, Fine-Tuning, Data Augmentation |
| Tools | PyTorch, TensorFlow, Hugging Face |
| Methods | Cross-Validation, Ablation Study |
| Standards | ISO 27001, REST API |

**Exclude:**

| Category | Examples |
|----------|----------|
| Proper nouns | OpenAI, Google, GPT-4, Claude |
| Generic terms | research, study, results, effective, important |
| Opinions | "best practice", "recommended approach" |

**Log:**

```bash
log_conditional INFO "After filtering: ${#RECURRING_TERMS[@]} terms"
log_phase "Phase 3: Term Analysis" "complete"
```

**Mark 3.3 complete.**

---

## Phase 3 Verification

| Check | Status |
|-------|--------|
| TERM_FREQUENCY built from all findings | |
| TERM_FINDINGS tracks finding sources | |
| RECURRING_TERMS filtered to 2+ | |
| Prioritization rules applied | |
| All step todos completed | |

⛔ **All checks must pass before Phase 4.**

---

## Phase 3 Output

```text
✅ Phase 3 Complete

Terms: {unique count} unique → {recurring_count} recurring (2+) → {final count} after rules

Data structures ready:
- TERM_FREQUENCY{}
- TERM_FINDINGS{}
- RECURRING_TERMS[]

→ Phase 4: Concept Creation
```

**Mark Phase 3 complete in TodoWrite.**

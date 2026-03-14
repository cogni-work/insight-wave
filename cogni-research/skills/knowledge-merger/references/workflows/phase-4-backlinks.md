# Phase 4: Backlink Update

Update dimension frontmatter with concept_ids and megatrend_ids arrays.

---

## ⛔ Entry Gate

```bash
test -d "${PROJECT_PATH}/$DIR_CONCEPTS" || { echo "Concepts directory missing"; exit 1; }
test -d "${PROJECT_PATH}/$DIR_MEGATRENDS" || mkdir -p "${PROJECT_PATH}/$DIR_MEGATRENDS"
```

---

## Step 0.5: TodoWrite Expansion

```markdown
ADD to TodoWrite:
- Phase 4.1: Build CONCEPTS_BY_DIMENSION [in_progress]
- Phase 4.2: Build MEGATRENDS_BY_DIMENSION [pending]
- Phase 4.3: Update dimension frontmatter [pending]
```

---

## Step 1: Build CONCEPTS_BY_DIMENSION

Scan all concept files to build mapping of dimensions to their concepts.

**⚠️ ZSH COMPATIBILITY:** Bash arrays and helper functions require temp script pattern.

```bash
cat > /tmp/km-phase4-step1.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 4: Backlink Update: start" >> "$LOG_FILE"

# Bash 3.2 compatible - use parallel indexed arrays
CONCEPTS_DIM_KEYS=()    # dimension files
CONCEPTS_DIM_VALUES=()  # concept wikilinks (space-separated)

get_or_add_concept_dim() {
  local dim="$1"
  local i=0
  for key in "${CONCEPTS_DIM_KEYS[@]}"; do
    if [ "$key" = "$dim" ]; then
      echo "$i"
      return 0
    fi
    i=$((i + 1))
  done
  CONCEPTS_DIM_KEYS+=("$dim")
  CONCEPTS_DIM_VALUES+=("")
  echo "$i"
}

for concept_file in "${PROJECT_PATH}"/05-domain-concepts/data/concept-*.md; do
  [ -f "$concept_file" ] || continue

  # Extract dimension from concept (via finding_refs → finding → batch → question → dimension)
  # Or directly from tags if dimension tag exists
  dim_tag=$(grep "^tags:" "$concept_file" | grep -o "dimension/[^,\]]*" | head -1)

  if [ -n "$dim_tag" ]; then
    dim_slug="${dim_tag#dimension/}"
    dim_file="dimension-${dim_slug}.md"
    concept_basename=$(basename "$concept_file" .md)
    idx=$(get_or_add_concept_dim "$dim_file")
    CONCEPTS_DIM_VALUES[$idx]="${CONCEPTS_DIM_VALUES[$idx]}[[05-domain-concepts/data/${concept_basename}]] "
  fi
done

concepts_linked=0
for i in "${!CONCEPTS_DIM_KEYS[@]}"; do
  count=$(echo "${CONCEPTS_DIM_VALUES[$i]}" | wc -w | tr -d ' ')
  concepts_linked=$((concepts_linked + count))
done

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Built concept backlinks: $concepts_linked concepts across ${#CONCEPTS_DIM_KEYS[@]} dimensions" >> "$LOG_FILE"

# Export for Step 3
printf '%s\n' "${CONCEPTS_DIM_KEYS[@]}" > /tmp/km-concepts-dim-keys.txt
printf '%s\n' "${CONCEPTS_DIM_VALUES[@]}" > /tmp/km-concepts-dim-values.txt
echo "concepts_linked=${concepts_linked}"
SCRIPT_EOF
chmod +x /tmp/km-phase4-step1.sh && bash /tmp/km-phase4-step1.sh "${PROJECT_PATH}"
```

**Mark 4.1 complete.**

---

## Step 2: Build MEGATRENDS_BY_DIMENSION

Scan all megatrend files to build mapping of dimensions to their megatrends.

**⚠️ ZSH COMPATIBILITY:** Bash arrays and helper functions require temp script pattern.

```bash
cat > /tmp/km-phase4-step2.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

# Bash 3.2 compatible - use parallel indexed arrays
MEGATRENDS_DIM_KEYS=()    # dimension files
MEGATRENDS_DIM_VALUES=()  # megatrend wikilinks (space-separated)

get_or_add_megatrend_dim() {
  local dim="$1"
  local i=0
  for key in "${MEGATRENDS_DIM_KEYS[@]}"; do
    if [ "$key" = "$dim" ]; then
      echo "$i"
      return 0
    fi
    i=$((i + 1))
  done
  MEGATRENDS_DIM_KEYS+=("$dim")
  MEGATRENDS_DIM_VALUES+=("")
  echo "$i"
}

for megatrend_file in "${PROJECT_PATH}"/06-megatrends/data/megatrend-*.md; do
  [ -f "$megatrend_file" ] || continue

  # Extract dimension via majority vote from finding_refs
  # (LLM: Read megatrend, get finding_refs, map to dimensions, majority vote)
  dim_file="dimension-{determined-slug}.md"
  megatrend_basename=$(basename "$megatrend_file" .md)
  idx=$(get_or_add_megatrend_dim "$dim_file")
  MEGATRENDS_DIM_VALUES[$idx]="${MEGATRENDS_DIM_VALUES[$idx]}[[06-megatrends/data/${megatrend_basename}]] "
done

megatrends_linked=0
for i in "${!MEGATRENDS_DIM_KEYS[@]}"; do
  count=$(echo "${MEGATRENDS_DIM_VALUES[$i]}" | wc -w | tr -d ' ')
  megatrends_linked=$((megatrends_linked + count))
done

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Built megatrend backlinks: $megatrends_linked megatrends across ${#MEGATRENDS_DIM_KEYS[@]} dimensions" >> "$LOG_FILE"

# Export for Step 3
printf '%s\n' "${MEGATRENDS_DIM_KEYS[@]}" > /tmp/km-megatrends-dim-keys.txt
printf '%s\n' "${MEGATRENDS_DIM_VALUES[@]}" > /tmp/km-megatrends-dim-values.txt
echo "megatrends_linked=${megatrends_linked}"
SCRIPT_EOF
chmod +x /tmp/km-phase4-step2.sh && bash /tmp/km-phase4-step2.sh "${PROJECT_PATH}"
```

**Mark 4.2 complete.**

---

## Step 3: Update Dimension Frontmatter

For each dimension with concepts or megatrends, update its frontmatter.

**LLM Execution:** For each dimension file:

1. Read current frontmatter
2. Add or update `concept_ids` array with concept wikilinks
3. Add or update `megatrend_ids` array with megatrend wikilinks
4. Preserve all other frontmatter fields
5. Write updated file

**⚠️ ZSH COMPATIBILITY:** Bash arrays and loops require temp script pattern.

```bash
cat > /tmp/km-phase4-step3.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail
PROJECT_PATH="$1"
LOG_FILE="${PROJECT_PATH}/.metadata/knowledge-merger-execution-log.txt"

# Read arrays from Steps 1 and 2
CONCEPTS_DIM_KEYS=()
while IFS= read -r line; do
  CONCEPTS_DIM_KEYS+=("$line")
done < /tmp/km-concepts-dim-keys.txt

CONCEPTS_DIM_VALUES=()
while IFS= read -r line; do
  CONCEPTS_DIM_VALUES+=("$line")
done < /tmp/km-concepts-dim-values.txt

MEGATRENDS_DIM_KEYS=()
while IFS= read -r line; do
  MEGATRENDS_DIM_KEYS+=("$line")
done < /tmp/km-megatrends-dim-keys.txt

MEGATRENDS_DIM_VALUES=()
while IFS= read -r line; do
  MEGATRENDS_DIM_VALUES+=("$line")
done < /tmp/km-megatrends-dim-values.txt

backlinks_added=0
dimensions_updated=0

# Get all unique dimensions from both maps (Bash 3.2 compatible)
all_dims=()
for dim in "${CONCEPTS_DIM_KEYS[@]}"; do
  [ -z "$dim" ] && continue
  case " ${all_dims[*]} " in
    *" ${dim} "*) ;;
    *) all_dims+=("$dim") ;;
  esac
done
for dim in "${MEGATRENDS_DIM_KEYS[@]}"; do
  [ -z "$dim" ] && continue
  case " ${all_dims[*]} " in
    *" ${dim} "*) ;;
    *) all_dims+=("$dim") ;;
  esac
done

for dim_file in "${all_dims[@]}"; do
  [ -z "$dim_file" ] && continue
  dim_path="${PROJECT_PATH}/01-research-dimensions/data/${dim_file}"

  if [ ! -f "$dim_path" ]; then
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [WARN] Dimension file not found: $dim_path" >> "$LOG_FILE"
    continue
  fi

  # Build concept_ids array (lookup in parallel arrays)
  concept_links=""
  for i in "${!CONCEPTS_DIM_KEYS[@]}"; do
    if [ "${CONCEPTS_DIM_KEYS[$i]}" = "$dim_file" ]; then
      concept_links="${CONCEPTS_DIM_VALUES[$i]}"
      break
    fi
  done
  concept_count=$(echo "$concept_links" | wc -w | tr -d ' ')

  # Build megatrend_ids array (lookup in parallel arrays)
  megatrend_links=""
  for i in "${!MEGATRENDS_DIM_KEYS[@]}"; do
    if [ "${MEGATRENDS_DIM_KEYS[$i]}" = "$dim_file" ]; then
      megatrend_links="${MEGATRENDS_DIM_VALUES[$i]}"
      break
    fi
  done
  megatrend_count=$(echo "$megatrend_links" | wc -w | tr -d ' ')

  # Update frontmatter (LLM: Read file, add/update arrays, write back)
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Updating $dim_file: $concept_count concepts, $megatrend_count megatrends" >> "$LOG_FILE"

  backlinks_added=$((backlinks_added + concept_count + megatrend_count))
  dimensions_updated=$((dimensions_updated + 1))
done

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO] Added $backlinks_added backlinks across $dimensions_updated dimensions" >> "$LOG_FILE"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Phase 4: Backlink Update: complete" >> "$LOG_FILE"

echo "backlinks_added=${backlinks_added}"
echo "dimensions_updated=${dimensions_updated}"
SCRIPT_EOF
chmod +x /tmp/km-phase4-step3.sh && bash /tmp/km-phase4-step3.sh "${PROJECT_PATH}"
```

**Mark 4.3 complete.**

---

## Phase 4 Verification

| Check | Status |
|-------|--------|
| CONCEPTS_DIM_KEYS/VALUES built | |
| MEGATRENDS_DIM_KEYS/VALUES built | |
| Dimension frontmatter updated | |
| All step todos completed | |

⛔ **All checks must pass before Phase 5.**

---

## Phase 4 Output

```text
✅ Phase 4 Complete

Concepts linked: {concepts_linked}
Megatrends linked: {megatrends_linked}
Dimensions updated: {dimensions_updated}
Total backlinks added: {backlinks_added}

→ Phase 5: README Generation
```

**Mark Phase 4 complete in TodoWrite.**

# Publisher Skill Troubleshooting

## Common Issues and Solutions

### Issue 1: "Project directory not found"

**Symptom:**
```
ERROR: Project directory not found: /path/to/project
```

**Cause:** Invalid or non-existent project path provided

**Solution:**
1. Verify project path exists: `ls -la /path/to/project`
2. Check for typos in path
3. Ensure using absolute path (not relative)
4. Verify project is valid deeper-research project (has 00-11 directories)

**Prevention:**
- Always use absolute paths
- Verify project exists before invoking skill
- Use tab completion to avoid typos

---

### Issue 2: "No sources found in 07-sources/data/"

**Symptom:**
```
ERROR: No source files found in project
```

**Cause:** Sources directory empty or not created yet

**Solution:**
1. Check if `07-sources/data/` exists: `ls -la /path/to/project/07-sources/data/`
2. Verify deeper-research Phase 6.1 (source creation) completed
3. If empty, run deeper-research skill first to create sources

**Prevention:**
- Run publisher-generator skill AFTER deeper-research Phase 6.1 completes
- Verify sources exist before running publisher-generator skill

---

### Issue 3: "CLAUDE_PLUGIN_ROOT environment variable not set"

**Symptom:**
```json
{"success": false, "error": "CLAUDE_PLUGIN_ROOT environment variable not set"}
```

**Cause:** Environment variable not configured in settings.local.json

**Solution:**
1. Add to `.claude/settings.local.json`:
   ```json
   {
     "env": {
       "CLAUDE_PLUGIN_ROOT": "/absolute/path/to/cogni-research"
     }
   }
   ```
2. Restart Claude Code
3. Verify: `echo $CLAUDE_PLUGIN_ROOT`

**Prevention:**
- Configure environment variables during plugin setup
- Use `.claude/settings.local.json` for persistent configuration

---

### Issue 4: Publisher agents return non-JSON responses

**Symptom:**
```
✗ Phase 1 Failed: Could not parse agent response
```

**Cause:** Agent returned verbose text instead of pure JSON

**Solution:**
1. Check agent output in reports directory: `/path/to/project/reports/`
2. Verify agents are using correct versions (check `cogni-research/agents/`)
3. If agents are modified, restore from backup
4. Report issue if agents are unmodified

**Prevention:**
- Do not modify publisher agents directly
- Use version control to track agent changes
- Test agents with sample projects before production use

---

### Issue 5: Low publisher creation rate

**Symptom:**
```
✓ Phase 1: Created 5 publishers (0 reused, 15 failed) from 20 sources
```

**Cause:** Sources missing required metadata (domain field)

**Solution:**
1. Inspect failed publishers in error messages
2. Check source entity frontmatter for missing fields
3. Validate sources have `domain` field: `grep "^domain:" /path/to/project/07-sources/data/*.md`
4. If many sources missing domain, re-run deeper-research source creation

**Expected Behavior:**
- 80-90% of sources should successfully create publishers
- Failures typically due to malformed source metadata

**Prevention:**
- Validate source entities have required fields before running publisher-generator skill
- Use source validation script if available

---

### Issue 6: Web search failures during enrichment

**Symptom:**
```
✓ Phase 2: Enriched 10 of 24 publishers (14 failed)
```

**Cause:** Web search API issues, rate limiting, or network problems

**Solution:**
1. Check network connectivity
2. Verify web search capabilities enabled in Claude Code
3. Wait 5-10 minutes and retry (rate limiting)
4. Check failed publishers list for patterns (all private entities?)

**Expected Behavior:**
- 85-95% success rate expected
- Failures for private/obscure entities are normal
- Publishers marked with `enrichment_status: "failed"` and failure reason

**Re-run Strategy:**
- Publisher enricher skips already-enriched publishers (idempotent)
- Safe to re-run Phase 2 multiple times
- Each run attempts only unenriched publishers

---

### Issue 7: Duplicate publishers created

**Symptom:**
Multiple publisher entities for same publisher with different IDs

**Cause:** Deduplication logic failed or inconsistent naming

**Solution:**
1. Identify duplicates: `find /path/to/project/08-publishers/data/ -name "publisher-*.md" | sort`
2. Check for name variations (e.g., "Dr. Jane Smith" vs "Jane Smith")
3. Verify glob pattern matching: `ls /path/to/project/08-publishers/data/publisher-dr-jane-smith-*.md`
4. Manually merge duplicates if needed
5. Update source references to point to canonical publisher

**Glob Pattern Verification:**
```bash
# Check if deduplication glob pattern finds existing publishers
slug="dr-jane-smith"
existing=$(ls /path/to/project/08-publishers/data/publisher-$slug-*.md 2>/dev/null | head -1)
echo "Found: $existing"
```

**Prevention:**
- Deduplication handled automatically via glob pattern checks
- Duplicates usually indicate race condition during parallel creation (rare)
- Glob pattern searches by slug prefix (publisher-{slug}-*.md)
- Standardize author names in sources before running publisher-generator skill

---

### Issue 8: Publisher enrichment takes too long

**Symptom:**
Phase 2 runs for 30+ minutes with slow progress

**Cause:** Too few parallel agents or slow web searches

**Solution:**
1. Increase parallelization: Skill auto-calculates agents based on publisher count
2. Check for stuck web searches (timeouts not working)
3. Monitor agent progress in execution logs
4. If stuck, cancel and retry (idempotent - will skip completed publishers)

**Expected Performance:**
- 5-10 seconds per publisher (including web search)
- 10 publishers: ~1-2 minutes with parallel execution
- 50 publishers: ~5-8 minutes with 5 agents

**Optimization:**
- Parallel execution is automatic (no tuning needed)
- More agents = faster completion (up to 10 agents max)

---

### Issue 9: Missing Context sections after enrichment

**Symptom:**
Publishers marked `enriched: true` but no Context section in entity file

**Cause:** Search failures resulted in minimal context or write errors

**Solution:**
1. Check publisher entity file manually
2. Look for "Limited public information available" message
3. Check `enrichment_status` field: `"success"` or `"failed"`
4. If missing entirely, check write permissions on `08-publishers/data/` directory
5. Re-run enrichment for specific publishers by setting `enriched: false` in frontmatter

**Verification:**
```bash
# Check for publishers with enriched: true but no Context section
for file in /path/to/project/08-publishers/data/*.md; do
  if grep -q "enriched: true" "$file" && ! grep -q "### Context" "$file"; then
    echo "Missing context: $(basename $file)"
  fi
done

# Check enrichment_status distribution
grep -h "enrichment_status:" /path/to/project/08-publishers/data/*.md | sort | uniq -c
```

---

### Issue 10: Citation generation fails after publisher-generator skill

**Symptom:**
deeper-research Phase 6.2 (citation generation) fails with missing publishers

**Cause:** Citation generator expects publishers but they don't exist or are malformed

**Solution:**
1. Verify publishers created: `find /path/to/project/08-publishers/data -maxdepth 1 -type f | wc -l`
2. Check publisher entity frontmatter is valid YAML
3. Ensure `publisher_type` field present in all publishers
4. Re-run publisher-generator skill if needed (idempotent)

**Prevention:**
- Always run publisher-generator skill before citation generation
- Validate publisher entities before continuing with deeper-research

---

### Issue 11: Metrics mismatch error (Bug #8 Fix)

**Symptom:**
```json
{
  "failed_items": [
    {"source": "metrics-reconciliation", "stage": "validation", "reason": "Metrics mismatch detected: expected 5 failures but found 3 tracked items"}
  ]
}
```

**Cause:** Inconsistency between failure counters and failed_items array length

**Root Cause Analysis:**
- `creation_failed + enrichment_failed` should equal `failed_items.length`
- Mismatch indicates tracking error during processing
- Possible causes:
  * Failed to add entry to failed_items when incrementing counter
  * Counter incremented but failed_items append failed
  * Duplicate failed_items entries

**Solution:**
1. **Review Processing Logs:** Check which failures occurred
2. **Count Actual Failures:**
   ```bash
   # Count failed sources
   grep "stage.*creation" /path/to/project/reports/*.log | wc -l

   # Count failed enrichments
   grep "stage.*enrichment" /path/to/project/reports/*.log | wc -l
   ```
3. **Validate failed_items:**
   ```bash
   # Check for duplicate entries
   jq '.failed_items | group_by(.source, .publisher) | map(select(length > 1))' metrics.json
   ```
4. **Re-run Skill:** Metrics invariant enforced in updated implementation

**Prevention:**
- Updated skill validates invariant before returning: `assert failed_items.length === creation_failed + enrichment_failed`
- Each failure adds exactly one entry to failed_items
- Metrics reconciliation entry added if mismatch detected

---

### Issue 12: enrichment_status field confusion

**Symptom:**
Publisher has `enriched: true` but `enrichment_status: "pending"`

**Cause:** Incomplete frontmatter update during enrichment process

**Field Values:**
- `enrichment_status: "pending"` - Publisher created but not yet enriched
- `enrichment_status: "success"` - Enrichment completed successfully
- `enrichment_status: "failed"` - Enrichment attempted but failed (web search issues)

**Validation:**
```bash
# Check for inconsistent states
for file in /path/to/project/08-publishers/data/*.md; do
  enriched=$(grep "^enriched:" "$file" | awk '{print $2}')
  enrich_status=$(grep "^enrichment_status:" "$file" | awk '{print $2}' | tr -d '"')

  if [ "$enriched" = "true" && "$enrich_status" == "pending" ]; then
    echo "Inconsistent state: $(basename $file)"
  fi
done
```

**Expected States:**
- `enriched: false, enrichment_status: "pending"` → Not yet enriched
- `enriched: true, enrichment_status: "success"` → Successfully enriched
- `enriched: true, enrichment_status: "failed"` → Enrichment attempted but failed

**Solution:**
1. Identify publishers with inconsistent states
2. Set `enriched: false` to retry enrichment
3. Re-run publisher-generator skill (will attempt enrichment)

**Prevention:**
- Updated skill uses Edit tool to atomically update both fields
- Enrichment process updates `enriched` and `enrichment_status` together

---

### Issue 13: Glob pattern deduplication not finding existing publishers

**Symptom:**
Multiple publishers created with same name but different hashes

**Cause:** Glob pattern not matching existing files or slug generation inconsistency

**Debugging:**
```bash
# Test glob pattern for specific publisher name
name="Dr. Jane Smith"
slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
echo "Slug: $slug"

# Check for existing files
ls /path/to/project/08-publishers/data/publisher-$slug-*.md 2>/dev/null

# If no match, check for similar names
ls /path/to/project/08-publishers/data/ | grep -i "jane-smith"
```

**Common Issues:**
1. **Special characters in name:** Non-ASCII characters not removed properly
   - Solution: Verify slug generation removes all non-alphanumeric except hyphens

2. **Case sensitivity:** Slug should be lowercase
   - Solution: Verify `tr '[:upper:]' '[:lower:]'` applied

3. **Hash mismatch:** Different hash generated for same name
   - Solution: Verify hash generation uses same input (check whitespace)

**Verification Script:**
```bash
# Check for potential duplicates by name similarity
cd /path/to/project/08-publishers
for file in publisher-*.md; do
  name=$(grep "^name:" "$file" | cut -d' ' -f2-)
  echo "$name|$file"
done | sort | uniq -d -w30
```

**Solution:**
1. Identify duplicate publishers (same name, different hash)
2. Choose canonical publisher (usually oldest by created_date)
3. Merge source_references from duplicates into canonical
4. Delete duplicate publisher files
5. Update source entities to reference canonical publisher

**Prevention:**
- Glob pattern now searches by slug prefix: `publisher-{slug}-*.md`
- Deterministic hash generation from normalized name
- Edit tool used for atomic source reference appends

---

### Issue 14: Orphaned/Incomplete Publishers (All Pending Enrichment)

**Symptom:**
All publishers have `enriched: false` and `enrichment_status: "pending"`:
```bash
$ grep -l 'enrichment_status: "pending"' /path/to/project/08-publishers/data/*.md | wc -l
110   # All 110 publishers are unenriched!
```

Additionally, publishers have:

- Empty `source_references: []` (no wikilinks to sources)
- Some have empty `name: ""` (created from empty domains)

**Cause:** The atomic pipeline was broken - publishers were batch-created but enrichment step was never executed. This violates the critical pipelined execution requirement:

```text
Create Publisher A → Enrich A → Create Publisher B → Enrich B → ...
```

Instead, the execution was:
```text
Create Publisher A → Create Publisher B → ... → (enrichment never happened)
```

**Root Cause Analysis:**

1. **Enrichment step skipped entirely:** The LLM executing the skill batched creation without immediately enriching each publisher
2. **Empty org_name allowed:** Sources with empty domains created publishers like `publisher--68b329da.md`
3. **source_references never populated:** Wikilinks to sources not written during creation

**Detection:**
```bash
# Count publishers with pending enrichment
grep -l 'enrichment_status: "pending"' /path/to/project/08-publishers/data/*.md | wc -l

# Find publishers with empty names
grep -l 'name: ""' /path/to/project/08-publishers/data/*.md

# Find publishers with empty source_references
for f in /path/to/project/08-publishers/data/*.md; do
  refs=$(grep -A 5 "^source_references:" "$f" | grep -c "^\s*-" || echo "0")
  if [ "$refs" -eq 0 ]; then
    echo "Empty refs: $(basename $f)"
  fi
done
```

**Solution:**

1. **Delete orphaned publishers:** Remove all unenriched publishers

   ```bash
   for f in /path/to/project/08-publishers/data/*.md; do
     enrich_status=$(grep "enrichment_status:" "$f" | grep -o '"[^"]*"' | tr -d '"')
     if [ "$enrich_status" = "pending" ]; then
       rm "$f"
     fi
   done
   ```

2. **Delete empty-name publishers:**
   ```bash
   rm /path/to/project/08-publishers/data/publisher--*.md
   ```

3. **Re-run publisher-generator skill:** The updated skill now has enforcement gates that prevent this issue

**Prevention (Implemented Fix):**

The skill now has **three enforcement gates** in phase-2-processing.md:

1. **Pre-Loop Gate:** Validates `org_name` is non-empty before publisher loop
2. **Post-Creation Gate:** Verifies publisher file exists and `source_references` populated
3. **Post-Enrichment Gate:** Confirms `enriched=true` and `enrichment_status` is success/failed

Each gate **MUST pass** before proceeding. Violations are logged and tracked in `failed_items`.

**Updated Self-Verification (in SKILL.md):**

- Did each publisher pass the Post-Enrichment Gate (enriched=true)?
- Are there ZERO publishers with enrichment_status="pending" at end?

---

## Diagnostic Commands

**Check project structure:**
```bash
ls -la /path/to/project/{00..11}*
```

**Count sources:**
```bash
find /path/to/project/07-sources -name "source-*.md" | wc -l
```

**Count publishers:**
```bash
find /path/to/project/08-publishers -name "publisher-*.md" | wc -l
```

**Check enrichment status distribution:**
```bash
grep -h "enrichment_status:" /path/to/project/08-publishers/data/*.md | sort | uniq -c
```

**Check enriched flag distribution:**
```bash
grep -h "^enriched:" /path/to/project/08-publishers/data/*.md | sort | uniq -c
```

**Validate source metadata:**
```bash
for file in /path/to/project/07-sources/data/*.md; do
  if ! grep -q "^domain:" "$file"; then
    echo "Missing domain: $(basename $file)"
  fi
done
```

**Check for duplicate publisher names:**
```bash
cd /path/to/project/08-publishers
grep -h "^name:" *.md | sort | uniq -c | awk '$1 > 1 {print}'
```

**Check execution logs:**
```bash
cat /path/to/project/reports/publisher-generator-execution-log.txt
cat /path/to/project/reports/publisher-enricher-execution-log.txt
```

**Verify metrics invariant:**
```bash
# Extract metrics from JSON response
creation_failed=$(jq '.creation_failed' metrics.json)
enrichment_failed=$(jq '.enrichment_failed' metrics.json)
failed_items_count=$(jq '.failed_items | length' metrics.json)
expected=$((creation_failed + enrichment_failed))

if [ "$failed_items_count" -ne "$expected" ]; then
  echo "Metrics mismatch: expected $expected, found $failed_items_count"
else
  echo "Metrics consistent"
fi
```

---

## Getting Help

If issues persist after troubleshooting:

1. **Check Documentation:**
   - [workflow-overview.md](./workflow-overview.md)
   - [pipeline-architecture.md](./pipeline-architecture.md)
   - [parallelization-strategy.md](./parallelization-strategy.md)

2. **Verify Environment:**
   - `CLAUDE_PLUGIN_ROOT` set correctly
   - Project structure valid
   - Sources exist and are well-formed

3. **Review Logs:**
   - Execution logs in `/path/to/project/reports/`
   - Agent output for specific error messages
   - Statistics for success/failure rates

4. **Test with Sample Project:**
   - Create minimal test project
   - Run publisher-generator skill with small dataset
   - Verify basic functionality works

5. **Report Issue:**
   - Include error messages
   - Provide project structure (without sensitive data)
   - Include agent versions and configuration
   - Describe steps to reproduce

---

## Edge Cases and Unusual Scenarios

### Edge Case 1: Source with 50+ Authors

**Scenario:** Single source has 50+ individual authors listed

**Behavior:**
- Creates 50+ individual publisher entities (one per author)
- Each author gets separate entity and enrichment
- Can significantly increase processing time for this source

**Impact:**
- Normal processing, but slower for this source
- May trigger rate limiting on web searches
- Results in many publisher entities from single source

**Solution:**
- This is expected behavior (each author deserves individual entity)
- If authors list is excessive, consider checking source metadata quality
- For anthologies/compilations, organization publisher may be more relevant

**Prevention:**
- Review sources with unusually high author counts
- Consider whether all authors should be individual publishers
- For edited volumes, editor may be more relevant than all contributors

---

### Edge Case 2: Malformed Domain Field

**Scenario:** Source has invalid domain (e.g., "not-a-domain", "example", "N/A")

**Behavior:**
- Organization name extraction attempts pattern matching
- May create publisher with odd name like "Not A Domain" or "Example"
- Organization type classification defaults to "private_company"

**Impact:**
- Creates publisher with low-quality name
- Enrichment likely to fail (no web results for nonsense name)
- Publisher entity exists but has minimal value

**Solution:**
1. Identify malformed domains in sources:
   ```bash
   grep "^domain:" /path/to/project/07-sources/data/*.md | grep -v "\." | head -20
   ```
2. Fix source entities to have valid domains
3. Delete bad publisher entities
4. Re-run publisher-generator skill

**Prevention:**
- Validate source metadata before running publisher-generator
- Check that domains are well-formed (contain at least one ".")
- Ensure sources have legitimate publisher domains

---

### Edge Case 3: Organization Name Extraction Fails

**Scenario:** Domain exists but doesn't map to known organization (e.g., "obscure-journal-xyz.com")

**Behavior:**
- Pattern-based extraction attempts to derive name from domain
- Removes TLD, converts to title case, adds common suffixes
- Result: "Obscure Journal Xyz" or "Obscure Journal Xyz Initiative"

**Impact:**
- Organization name may not match actual organization name
- Enrichment may succeed if web search finds correct entity
- Organization type classification may be inaccurate

**Acceptable:**
- Best-effort name extraction is acceptable
- Web enrichment will provide accurate name if available
- Users can manually correct if needed

**Improvement:**
- Add domain to known mappings in creation-logic.md if frequently encountered
- Extend pattern-based extraction for new domain types

---

### Edge Case 4: Parallel Creation Race Condition

**Scenario:** Two skill instances process different sources with same publisher simultaneously

**Example:**
- Source A (instance 1): Dr. Jane Smith
- Source B (instance 2): Dr. Jane Smith
- Both instances check for existing publisher at same time
- Both create new publisher entities with different hashes (rare)

**Likelihood:** Very rare due to deterministic hash generation

**Behavior:**
- Two publisher entities created: `publisher-dr-jane-smith-abc123.md` and `publisher-dr-jane-smith-def456.md`
- Both have same name, different IDs
- Source references split between duplicates

**Impact:**
- Duplicates detected during quality checks
- Citation generation may reference either duplicate
- Not a critical error but reduces data quality

**Detection:**
```bash
# Find publishers with same name
cd /path/to/project/08-publishers
grep -h "^name:" *.md | sort | uniq -c | awk '$1 > 1'
```

**Solution:**
1. Identify canonical publisher (earliest `created_date`)
2. Merge `source_references` from all duplicates
3. Delete duplicate publishers
4. Update sources to reference canonical publisher

**Prevention:**
- Already minimized by deterministic hash (same name → same hash)
- Race window is very small (milliseconds)
- Post-processing deduplication recommended for large projects

---

### Edge Case 5: Publisher Name with Special Characters

**Scenario:** Author name contains non-ASCII characters (e.g., "José García", "Müller")

**Behavior:**
- Slug generation removes non-ASCII characters
- "José García" → "jos-garca" (accents removed)
- Hash generated from full original name (preserves uniqueness)

**Impact:**
- Slug may lose readability
- Deduplication still works (hash-based)
- Publisher entity has correct name in frontmatter

**Acceptable:**
- File naming limitation (ASCII-safe slugs)
- Entity content preserves original name
- Functionality not impaired

**Alternative:**
- Could transliterate (José → Jose) but adds complexity
- Current approach is simple and reliable

---

### Edge Case 6: Empty or Whitespace-Only Author Names

**Scenario:** Source has authors field like `authors: "Jane Smith, , John Doe"`

**Behavior:**
- Split produces: ["Jane Smith", "", "John Doe"]
- Empty string normalized → still empty
- Generic name check: empty string doesn't match patterns
- Attempts to create publisher with empty name

**Impact:**
- Could create invalid publisher entity
- Slug generation fails (empty slug)
- File write may fail

**Fix Required:** Add null/empty validation before processing each author
- Skip authors with empty or whitespace-only names
- Log as informational (not error)

**Current Status:** Potential bug - should be caught by null checks added in Bug #8 fix

---

### Edge Case 7: Extremely Long Publisher Names

**Scenario:** Organization name is very long (e.g., "The International Association for the Study of Climate Change and Environmental Policy Research Institute Foundation")

**Behavior:**
- Full name used in frontmatter (no truncation)
- Slug generation may produce very long slug
- Hash provides uniqueness regardless of slug length

**Impact:**
- File name may be very long but valid
- Most filesystems support 255 character filenames
- Functionality not impaired

**Acceptable:**
- Long names preserved accurately
- No artificial truncation needed
- File system limits not typically exceeded

---

## Summary of Edge Case Handling

**Well-Handled:**
- Multiple authors per source (creates many individual publishers)
- Unknown domains (pattern-based extraction)
- Race conditions (rare, detectable, mergeable)
- Special characters in names (slug lossy, entity preserves)

**Needs Attention:**
- Malformed domains (creates low-quality publishers)
- Empty author names (potential bug, fixed in Bug #8)

**Recommended Practices:**
- Validate source metadata quality before running skill
- Run post-processing deduplication check for large projects
- Review publishers with enrichment failures (may indicate bad source data)
- Use diagnostic commands to detect edge cases early

---

## Batch Mode Issues (v4.0 Two-Phase Architecture)

### Issue 15: Phase A script (create-publishers-batch.py) failure

**Symptom:**

```text
ERROR: Phase A failed: create-publishers-batch.py returned non-zero exit code
```

**Cause:** Python script failed during atomic skeleton creation

**Solution:**

1. Check Python 3 is available: `python3 --version`
2. Verify shared_utils module accessible: `ls $CLAUDE_PLUGIN_ROOT/scripts/shared_utils/`
3. Check entity-index.json is writable
4. Review script output for specific error
5. If lock contention, wait and retry

**Prevention:**

- Ensure single Phase A process runs at a time
- Verify project permissions before batch mode

---

### Issue 16: Phase B enrichment agents timeout in batch mode

**Symptom:**

```text
✗ Phase B Failed: Enrichment agent timed out after processing 15 of 25 publishers
```

**Cause:** Individual enrichment agent took too long, possibly due to slow web searches

**Solution:**

1. Check which publishers were enriched: `grep -l 'enriched: true' 08-publishers/data/*.md | wc -l`
2. Re-run with `--enrich-only --files` pointing to remaining unenriched publishers
3. Reduce batch size if consistent timeouts

**Expected Behavior:**

- Each enrichment agent processes ~25 publishers
- Typical runtime: 3-4 minutes per agent
- Timeouts are rare and recoverable

---

### Issue 17: Choosing between --batch-mode and --all

**Symptom:**
Unsure which mode to use for project

**Guidance:**

| Source Count | Recommended Mode | Rationale                        |
| ------------ | ---------------- | -------------------------------- |
| Under 100    | `--all` (legacy) | Simpler, no Python dependency    |
| 100+         | `--batch-mode`   | 7x faster, avoids race conditions |

**When to use --batch-mode:**

- Large research projects (100+ sources)
- Projects experiencing exit code 144 timeouts
- When parallel enrichment is desired

**When to use --all:**

- Small projects (under 100 sources)
- Quick iterations during development
- When Python 3 not available

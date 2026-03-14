# Evidence Synthesizer Examples

## Example 1: Successful Evidence Catalog Generation

**Invocation:**
```
evidence-synthesizer --project-path /Users/name/research/climate-adaptation --language en
```

**Process:**
1. Validate parameters and environment
2. Load action-oriented-radar template from metadata
3. Load 138 sources completely (anti-hallucination)
4. Load 147 citations completely
5. Load 84 institutions completely
6. Extract metadata: Tier 1=54, Tier 2=62, Tier 3=22
7. Calculate distribution: 39%, 45%, 16%
8. Map authority: 32 academic, 18 multilateral, 21 government, 13 industry
9. Generate catalog following template structure
10. Write to 09-citations/README.md
11. Return statistics

**Expected Return:**
```
✅ Evidence catalog generation complete.
- Sources cataloged: 138 (T1: 54, T2: 62, T3: 22)
- Citations formatted: 147
- Institutions mapped: 84 (32 academic, 18 multilateral, 21 government, 13 industry)
- Output: 09-citations/README.md (passed)
```

**JSON Statistics:**
```json
{
  "success": true,
  "file": "09-citations/README.md",
  "sources_cataloged": 138,
  "citations_formatted": 147,
  "institutions_mapped": 84,
  "tier1_sources": 54,
  "tier2_sources": 62,
  "tier3_sources": 22,
  "research_type": "action-oriented-radar",
  "template_validation": "passed"
}
```

## Example 2: Empty Project (Graceful Handling)

**Process:**
1. Validate environment (passes)
2. Load generic template (no metadata file)
3. Sources directory empty: 0 sources
4. Citations directory empty: 0 citations
5. No institutions directory
6. Generate minimal catalog with zero counts
7. Return success

**Expected Return:**
```
✅ Evidence catalog generation complete.
- Sources cataloged: 0 (T1: 0, T2: 0, T3: 0)
- Citations formatted: 0
- Institutions mapped: 0 (0 academic, 0 multilateral, 0 government, 0 industry)
- Output: 09-citations/README.md (generic_template)
```

**Key Point:** Empty input is valid (project initialization state)

## Example 3: Anti-Hallucination Verification

**Wrong Approach:**
```bash
# ❌ WRONG - Truncated loading
head -20 "07-sources/data/source-abc.md"  # Only frontmatter
```

**Problem:** May fabricate content section, infer relationships, assume domain characteristics.

**Correct Approach:**
```markdown
**Read:** `{{PROJECT_PATH}}/07-sources/data/source-abc.md` (complete file)
```

**Verification:** Every catalog entry must trace to specific loaded entity content. No inferences allowed.

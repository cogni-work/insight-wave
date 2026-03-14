# Publisher Generator Skill

Enrich existing deeper-research projects with comprehensive publisher information through automated creation and web-based enrichment.

## Overview

The publisher-generator skill extracts publisher metadata from source entities and enriches them with contextual information via web research. It operates on existing deeper-research projects, creating and enriching publisher entities in the `08-publishers/data/` directory.

**Key Features:**
- Automatic publisher extraction from source metadata
- Type detection (individual authors vs organizational publishers)
- Web-based enrichment with professional background and expertise
- **Two-phase architecture for large batches (v4.0)** - 7x speedup
- Idempotent operation (safe to re-run)
- Anti-hallucination protocols for factual accuracy

## Two-Phase Architecture (v4.0)

For large projects (100+ sources), the skill uses a two-phase architecture that eliminates entity-index.json race conditions and provides significant performance improvements.

### Why Two Phases?

When processing 200+ sources in parallel, multiple agents writing to `entity-index.json` simultaneously caused race conditions and timeouts. The two-phase architecture separates entity creation from enrichment:

- **Phase A (Atomic Creation):** Single process creates all publisher skeletons with one atomic write to entity-index.json
- **Phase B (Parallel Enrichment):** Multiple agents safely enrich publishers in parallel (no index writes)

### Operating Modes

| Mode | Flag | When to Use | Performance |
|------|------|-------------|-------------|
| **Batch Mode** | `--batch-mode` | 100+ sources (recommended) | ~4 min for 200+ publishers |
| **Legacy Mode** | `--all` | Under 100 sources | ~8 sec per publisher |
| **Enrich-Only** | `--enrich-only --files` | Phase B only (internal) | Parallel safe |

### Batch Mode Workflow

```text
Phase A (Single Process):
  create-publishers-batch.py
    → Glob all sources
    → Extract unique domains
    → Create skeleton publishers atomically
    → Single batch write to entity-index.json
    → Return list of publishers to enrich

Phase B (Parallel Agents):
  Multiple enrichment agents (25 publishers each)
    → WebSearch for context
    → Update publisher files
    → No entity-index.json writes (safe)
```

## Prerequisites

### Required

1. **Existing Research Project:** Valid deeper-research project directory
2. **Source Entities:** Sources must exist in `07-sources/data/` (created by deeper-research Phase 6.1)
3. **Project Structure:** Standard 00-11 directory structure
4. **Environment:** `CLAUDE_PLUGIN_ROOT` environment variable configured

### Recommended

- **Web Search:** Enabled for publisher enrichment (Phase 2)
- **Source Metadata:** Sources should have `domain` and optionally `authors` fields

## Quick Start

### Batch Mode (Recommended for Large Projects)

```text
Process publishers at /path/to/project --batch-mode
```

Use `--batch-mode` for projects with 100+ sources. This enables the two-phase architecture for optimal performance (~4 minutes for 200+ publishers).

### Legacy Mode (Small Projects)

```text
Process publishers at /path/to/project --all
```

Use `--all` for projects under 100 sources. Simpler workflow, acceptable performance.

### Basic Usage

```text
Use the publisher-generator skill on my research project at /path/to/project
```

The skill will:

1. Extract publishers from sources (Phase A)
2. Enrich publishers with web research (Phase B)
3. Report statistics and completion status

## Workflow

### Phase 1: Publisher Creation

**Input:** Source entities in `07-sources/data/`

**Process:**
- Extracts publisher information from source metadata
- Detects type: individual (authors) vs organization (domain-based)
- Creates publisher entities in `08-publishers/data/`
- Automatic deduplication

**Output:** Publisher entities with basic metadata

**Typical Duration:** 2-3 seconds per source (parallel execution)

### Phase 2: Publisher Enrichment

**Input:** Publisher entities from Phase 1

**Process:**
- Executes web searches for publisher information
- Extracts contextual information (background, expertise, credibility)
- Writes Context sections to publisher files
- Updates frontmatter with enrichment metadata

**Output:** Fully enriched publisher entities

**Typical Duration:** 5-10 seconds per publisher (parallel execution with web search)

## Output

### Final Report

```
✓ Phase 1: Created 24 publishers (5 reused, 1 failed) from 45 sources
✓ Phase 2: Enriched 23 of 24 publishers (1 failed)

Project: green-bonds-climate-finance
Publishers Directory: /path/to/project/08-publishers/data/
Total Publishers: 24
Success Rate: 95.8%
```

### Publisher Entities

**Individual Publisher:**
```yaml
---
entity_type: publisher
publisher_type: individual
name: Dr. Jane Smith
enriched: true
enrichment_date: 2025-11-07T09:30:00Z
enrichment_sources:
  - https://profiles.stanford.edu/jane-smith
  - https://scholar.google.com/citations?user=abc123
source_references:
  - source-climate-bonds-report-abc123
tags: [publisher, publisher-type/individual]
---

## Publisher: Dr. Jane Smith

**Type**: Individual

### Context

**Professional Background**: Associate Professor at Oxford since 2015...

**Expertise & Role**: Focuses on green finance...

**Key Positions**: Advocates mandatory climate disclosure...

**Credibility Assessment**: Very High - Oxford/LSE credentials...
```

**Organization Publisher:**
```yaml
---
entity_type: publisher
publisher_type: organization
organization_type: government_agency
name: European Commission
enriched: true
enrichment_date: 2025-11-07T09:30:00Z
enrichment_sources:
  - https://ec.europa.eu/info/about
website: ec.europa.eu
tags: [publisher, publisher-type/organization, organization-type/government_agency]
---

## Publisher: European Commission

**Type**: Organization (government_agency)

### Context

**Mission & Mandate**: The European Commission is the executive branch...

**Establishment & Headquarters**: Established in 1958, headquartered in Brussels...

**Domain Expertise**: Specializes in EU policy development...

**Credibility Assessment**: Very High - Official EU body...
```

## Integration with deeper-research

### Workflow Integration

**Recommended Workflow:**

1. Run deeper-research skill (creates sources in Phase 6.1)
2. **Run publisher-generator skill** (creates and enriches publishers)
3. Continue with citation generation (deeper-research Phase 6.2)

### Citation Dependency

Citation generation (deeper-research Phase 6.2) benefits from publisher information:
- With publishers: Full APA citations with author names
- Without publishers: Domain-based fallback attribution

## Performance

### Batch Mode (v4.0) - Recommended for Large Projects

**Performance for 200+ publishers:**

- Phase A (Skeleton Creation): ~15 seconds (single atomic process)
- Phase B (Parallel Enrichment): ~3-4 minutes (10 agents, 25 publishers each)
- **Total: ~4 minutes** (7x faster than sequential)

**Parallelization Strategy:**

- Phase A: Single process (atomic entity-index.json write)
- Phase B: Up to 10 parallel agents (25 publishers per agent)
- Round-robin distribution for load balancing

### Legacy Mode - Small Projects

**Typical Performance (50 sources → 25 publishers):**

- Phase 1 (Creation): 2-3 minutes with 3 parallel agents
- Phase 2 (Enrichment): 5-8 minutes with 3 parallel agents
- **Total:** 7-11 minutes

**Parallelization:**

- Phase 1: Up to 10 agents (20 sources per agent)
- Phase 2: Up to 10 agents (10 publishers per agent)
- Automatic load balancing with round-robin distribution

## Error Handling

### Common Issues

**Missing Sources:**
```
ERROR: No source files found in project
```
→ Run deeper-research Phase 6.1 first to create sources

**Invalid Project:**
```
ERROR: Project directory not found
```
→ Verify project path and ensure it's a valid deeper-research project

**Low Success Rate:**
```
✓ Phase 1: Created 5 publishers (0 reused, 15 failed) from 20 sources
```
→ Sources missing required `domain` field - check source metadata

### Recovery

The publisher-generator skill is **idempotent**:
- Safe to re-run multiple times
- Deduplication prevents duplicate entities
- Enrichment skips already-enriched publishers
- Partial completion preserved

## Publisher Types

### Individual Publishers

**Detected When:**
- Source has `authors` field with author names
- Multiple authors split automatically

**Enrichment Includes:**
- Professional background (education, positions)
- Expertise and research focus
- Key positions and stances
- Credibility assessment

### Organization Publishers

**Detected When:**
- Source lacks `authors` field or has generic authors
- Domain-based attribution

**Organization Types:**
- `multilateral_development_bank`
- `government_agency`
- `ngo`
- `industry_association`
- `academic_institution`
- `financial_institution`
- `news_organization`
- `international_organization`
- `think_tank`
- `private_company` (default)

**Enrichment Includes:**
- Mission and mandate
- Establishment and headquarters
- Domain expertise
- Credibility assessment

## Quality Standards

### Anti-Hallucination

- **Evidence-only extraction:** Only facts explicitly stated in search results
- **Source citation:** All enrichment sources stored in frontmatter
- **Missing info defaults:** Use "Not publicly available" for gaps
- **Verification required:** Re-read search excerpts before writing

### Factual Accuracy

- All statements verifiable from `enrichment_sources`
- Professional tone, no marketing language
- Uncertainty preserved ("Reportedly...", "According to...")
- No fabrication or speculation

## Documentation

### References

- [phase-workflows/](./references/phase-workflows/) - Phase-by-phase implementation workflows
- [phase-workflows/phase-1-initialization.md](./references/phase-workflows/phase-1-initialization.md) - Environment validation and setup
- [phase-workflows/phase-2-processing.md](./references/phase-workflows/phase-2-processing.md) - Atomic create-and-enrich pipeline
- [troubleshooting.md](./references/troubleshooting.md) - Common issues and solutions

### Related Skills

- **deeper-research:** Main research orchestration skill

## Examples

### Example 1: Basic Usage

```
User: Enrich publishers for /Users/me/research/green-bonds

Output:
✓ Phase 1: Created 18 publishers (3 reused, 0 failed) from 32 sources
  - Individual publishers: 10
  - Organization publishers: 11

✓ Phase 2: Enriched 18 of 18 publishers (0 failed)
  - Web searches successful: 18
  - Average enrichment sources: 3.2 per publisher

Project: green-bonds
Publishers Directory: /Users/me/research/green-bonds/08-publishers/data/
Total Publishers: 18
Success Rate: 100%
```

### Example 2: Partial Success

```
User: Run publisher-generator skill on /research/private-equity

Output:
✓ Phase 1: Created 12 publishers (2 reused, 1 failed) from 15 sources
  - Individual publishers: 7
  - Organization publishers: 7
  - Failed: source-missing-domain.md

✓ Phase 2: Enriched 12 of 13 publishers (1 failed)
  - Web searches successful: 12
  - Failed: Private Investment Firm (no public information)

Project: private-equity
Publishers Directory: /research/private-equity/08-publishers/data/
Total Publishers: 13
Success Rate: 92.3%
```

## Support

### Troubleshooting

See [references/troubleshooting.md](./references/troubleshooting.md) for detailed troubleshooting guide.

### Getting Help

1. Check [troubleshooting guide](./references/troubleshooting.md)
2. Review [phase workflow documentation](./references/phase-workflows/)
3. Inspect execution logs in project `/reports/` directory

## Version

**Current Version:** 4.0.0 (January 2026)

**v4.0.0 Changes:**

- Two-phase architecture for large batches (100+ sources)
- Phase A: `create-publishers-batch.py` for atomic skeleton creation
- Phase B: Parallel enrichment agents (no entity-index.json race conditions)
- New `--batch-mode` flag for two-phase workflow
- New `--enrich-only --files` mode for Phase B enrichment
- 7x performance improvement for large projects

**v1.0.0 (Initial Release):**

- Extracted from deeper-research Phase 5 into standalone skill
- Maintains same agent logic and data structures
- Adds independent invocation capability
- Makes publisher enrichment optional/on-demand

## License

Part of deeper-research plugin ecosystem.

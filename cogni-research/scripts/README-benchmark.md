# Dimension-Planner Benchmark Script

## Overview

`benchmark-dimension-planner.sh` is a manual benchmark utility for measuring dimension-planner execution time and validating output quality.

## Usage

```bash
./benchmark-dimension-planner.sh \
  --test-question <path-to-question.md> \
  --project-path <output-directory> \
  [--report-file <report.md>]
```

## Workflow

1. **Start the benchmark script:**
   ```bash
   ./benchmark-dimension-planner.sh \
     --test-question test-question.md \
     --project-path ./test-output
   ```

2. **Record start time:** Press Enter when prompted

3. **Run dimension-planner:** Manually invoke the dimension-planner agent via Claude Code

4. **Record end time:** Press Enter when complete

5. **Review report:** The script generates a comprehensive markdown report

## Example Session

```bash
# Start benchmark
./benchmark-dimension-planner.sh \
  --test-question questions/ai-governance.md \
  --project-path ./benchmarks/run-001

# Output:
# === Dimension-Planner Benchmark ===
# Workflow: Record start → Run dimension-planner → Record end
#
# Press Enter to record START time...
```

Press Enter, then run dimension-planner in Claude Code:

```
@dimension-planner questions/ai-governance.md ./benchmarks/run-001
```

When complete, return to benchmark script and press Enter for end time.

## Report Format

The script generates a markdown report with:

### 1. Execution Metrics
- Total execution time (seconds and human-readable)
- File counts (dimensions, questions, total)
- Performance metrics (time per file, dimensions per minute)

### 2. Validation Checks
- **Frontmatter:** Verifies all entity files have valid YAML frontmatter (---...---)
- **Wikilinks:** Checks for presence of [[wiki-style]] links in entities

### 3. Summary
- Overall validation status
- Performance assessment against targets:
  - ✅ <1.5 minutes (target met)
  - ⚠️  1.5-6 minutes (acceptable)
  - ❌ >6 minutes (needs optimization)

## Sample Report

```markdown
# Dimension-Planner Benchmark Report

**Test Question:** ai-governance.md
**Project Path:** ./benchmarks/run-001
**Execution Time:** 87 seconds (1m 27s)

## Files Created
- Dimensions: 5 files
- Questions: 20 files
- Total: 25 files

## Performance Metrics
- Time per file: 3.48 seconds
- Dimensions/minute: 3.4

## Validation

### Frontmatter Checks
- ✅ Dimension files with frontmatter: 5/5
- ✅ Question files with frontmatter: 20/20

### Wikilink Checks
- ✅ Dimension files with wikilinks: 5/5
- ✅ Question files with wikilinks: 20/20

## Summary
✅ All entity files have valid frontmatter
✅ All entity files contain wikilinks
✅ Execution time meets performance target (<1.5 minutes)
```

## Exit Codes

- `0` - Success, all validations passed
- `1` - Validation warnings (report still generated)
- `2` - Usage error (missing arguments, invalid flags)
- `3` - File or directory not found

## Performance Targets

The benchmark compares results against optimization goals:

- **Target execution time:** 1.5 minutes (90 seconds)
- **Previous baseline:** 6 minutes (360 seconds)
- **Target improvement:** 75% reduction

## Tips

1. **Consistent test questions:** Use the same test question for comparable results
2. **Clean output directories:** Start with empty or new directories to avoid counting old files
3. **Save reports:** Use `--report-file` to keep historical benchmark data
4. **Multiple runs:** Run benchmarks multiple times and average results for accuracy

## Troubleshooting

**"Project path not found"**
- Ensure the output directory exists before running the benchmark
- Create with: `mkdir -p ./benchmarks/run-001`

**"No files found"**
- Verify dimension-planner completed successfully
- Check that entities were written to the correct output path
- Ensure directory structure includes `/dimensions` and `/questions` subdirectories

**"Missing frontmatter warnings"**
- Review entity template to ensure frontmatter is included
- Check for file write errors during dimension-planner execution

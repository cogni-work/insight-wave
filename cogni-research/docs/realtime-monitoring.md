# Realtime Monitoring for Parallel Agent Execution

## Overview

The realtime monitoring system provides live visibility into parallel agent execution through standardized partition-aware logging and an interactive dashboard utility.

**Key features:**
- Monitor multiple partition logs simultaneously
- Real-time phase progress tracking
- Automatic error detection and highlighting
- Visual dashboard with color-coded status indicators
- Auto-exit when all partitions complete

**Delivered in:** Sprint 176 (2025-11-09)

## Architecture

The monitoring system consists of two layers:

### Layer 1: Partition-Aware Logging (Agent-Side)

Three parallel agents now support partition-aware log file naming:

1. **source-creator** - Processes findings in parallel partitions
2. **publisher-generator** - Creates publishers in parallel partitions
3. **fact-checker** - Verifies claims with partition-based distribution

**Log naming pattern:**
- **With partition:** `{agent}-partition{N}-execution-log.txt`
- **Without partition:** `{agent}-execution-log.txt`

**Example:**
```bash
# When invoked with partition parameter
--partition 3
→ Creates: source-creator-partition3-execution-log.txt

# When invoked without partition
→ Creates: source-creator-execution-log.txt
```

### Layer 2: Monitor Utility (Aggregation)

The `monitor-parallel-execution.sh` script:
- Discovers partition logs automatically via glob
- Polls logs every second (configurable)
- Parses phase markers and error patterns
- Displays unified real-time dashboard
- Exits when all partitions reach terminal state

## Quick Start

### Basic Usage

```bash
# Monitor source-creator partitions in current project
bash cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/

# Monitor with 2-second refresh interval
bash cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/ \
  --interval 2

# Get JSON summary on completion
bash cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/ \
  --json

# Disable colors (for logging to file)
bash cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/ \
  --no-color > monitoring.log
```

### Dashboard Interpretation

```
┌──────────────────────────────────────────────────────┐
│  Parallel Execution Monitor                          │
│  Log Directory: .logs/                             │
│  Started: 2025-11-09 19:30:00                        │
└──────────────────────────────────────────────────────┘

Partition 1: [Phase 3] ████████░░ 80% (8/10)
Partition 2: [Phase 3] ███████░░░ 70% (7/10)
Partition 3: [Complete] ██████████ 100%
Partition 4: [Phase 2] ███░░░░░░░ 30% (3/10)
Partition 5: [Failed] ERROR: JSON parsing failed
Partition 6: [Phase 1] ██░░░░░░░░ 20% (2/10)

Overall: 6 partitions
  - Completed: 1
  - Failed: 1
  - Running: 4

Errors detected: 1
Elapsed: 00:02:34
```

**Status colors:**
- 🟢 **GREEN** - Partition completed successfully
- 🔴 **RED** - Partition failed with error
- 🔵 **CYAN** - Partition running (current phase shown)
- ⚪ **GRAY** - Partition waiting/not started

**Progress bars:**
- `█` - Completed progress
- `░` - Remaining progress
- Width: 10 characters

## Integration with deeper-research Workflow

### Automatic Integration (Recommended)

Use the `--monitor` flag to enable realtime monitoring automatically:

```bash
# Enable monitoring with single flag
deeper-research --project-path /path/to/project --monitor

# Output shows activation message:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Realtime Monitoring Active
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  View dashboard: tail -f /path/to/project/.logs/monitor-output.log

  Monitor PID: 12345
  Auto-exits when all partitions complete

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# In new terminal, view dashboard
cd /path/to/project
tail -f .logs/monitor-output.log
```

**Features:**

- Monitor launches automatically during Phases 5.2 and 7
- Background process doesn't block workflow
- Auto-exits when all partitions complete
- No separate terminal or manual commands needed

**Monitored Phases:**

- **Phase 5.2 (Source Creation):** Tracks source-creator partition logs
- **Phase 7 (Fact Verification):** Tracks fact-checker partition logs

### Manual Launch (Advanced)

For advanced use cases or standalone monitoring:

```bash
# Manual launch if --monitor flag not used
cd /path/to/project
bash /path/to/cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/
```

**When to use:**

- Monitoring existing partition logs post-execution
- Debugging specific partition failures
- Custom monitoring intervals or output modes

### Multiple Monitor Instances

The skill may launch monitors in multiple phases:

1. **Phase 5.2:** Monitors source-creator partitions
2. **Phase 7:** Monitors fact-checker partitions

Each monitor:

- Tracks its own set of partition logs
- Auto-exits when its partitions complete
- Writes to `monitor-output.log` (may overwrite previous monitor output)

**Current behavior:** Second monitor may overwrite first monitor's output. Each monitor auto-exits after its partitions complete, so this is typically not an issue.

## Supported Agents

### source-creator

**Parameters:**
```bash
--partition {N}         # Optional: Partition number for parallel execution
--partition-num {N}     # Alternative parameter name (same effect)
--partition-id {N}      # Alternative parameter name (same effect)
```

**Log output:**
- With partition: `source-creator-partition2-execution-log.txt`
- Without: `source-creator-execution-log.txt`

**Usage in parallel execution:**
```bash
# Agent invocation with partition
Task(
  subagent_type="cogni-research:source-creator",
  prompt="Process findings at {project-path} --partition 2"
)
```

### publisher-generator

**Parameters:**
```bash
--partition {N}         # Optional: Partition number for parallel execution
```

**Log output:**
- With partition: `publisher-generator-partition1-execution-log.txt`
- Without: `publisher-generator-execution-log.txt`

### fact-checker

**Parameters:**
```bash
--partition-id {N}      # Partition index (zero-based)
--total-partitions {M}  # Total number of partitions
```

**Log output:**
- With partition: `fact-checker-partition0-execution-log.txt`
- Without: `fact-checker-execution-log.txt`

**Note:** fact-checker uses `--partition-id` (not `--partition`) per established patterns from Phase 7 parallelization.

## Monitor Utility Reference

### Command-Line Options

```bash
monitor-parallel-execution.sh [OPTIONS]

Required:
  --log-dir PATH        Directory containing partition logs (usually '.logs/')

Optional:
  --interval SECONDS    Refresh interval in seconds (default: 1)
  --no-color            Disable ANSI color output
  --json                Output JSON summary on completion (suppresses dashboard)
  --help                Show help message

Exit Codes:
  0  All partitions completed successfully
  1  One or more partitions failed
  2  Invalid arguments or log directory not found
```

### JSON Output Format

When using `--json` flag:

```json
{
  "success": true,
  "partitions_total": 6,
  "partitions_completed": 5,
  "partitions_failed": 1,
  "total_duration_sec": 154,
  "errors": [
    {
      "partition": 5,
      "error": "Script execution or JSON parsing failed",
      "phase": "Phase 3"
    }
  ],
  "partitions": [
    {
      "id": 1,
      "status": "completed",
      "phase": "Phase 4",
      "progress_pct": 100
    },
    {
      "id": 2,
      "status": "failed",
      "phase": "Phase 3",
      "error": "JSON parsing failed",
      "error_count": 10
    }
  ]
}
```

## Error Detection

The monitor automatically detects and highlights these error patterns:

### From Sprint 175 Experience

1. **`[ERROR]`** - Log level marker
2. **`ERROR:`** - Script error prefix
3. **"Script execution or JSON parsing failed"** - Stderr contamination (Sprint 175 Bug #4)
4. **"Finding file not found"** - Path resolution issues (Sprint 175 Bug #5)
5. **"Failed to acquire lock"** - Entity lock contention
6. **"validation failed"** - Metadata validation errors
7. **"Entity creation failed"** - General entity creation failures

### Error Display

Errors are highlighted in RED and shown with context:

```
Partition 5: [Failed] ERROR: Script execution or JSON parsing failed
  Last error: [2025-11-09T19:23:45Z] [ERROR] Entity creation failed
```

## Troubleshooting

### Monitor Shows No Partitions

**Symptom:** Dashboard shows "No partition logs found"

**Causes:**
1. Agents haven't started yet (logs not created)
2. Wrong `--log-dir` path
3. Agents invoked without partition parameters

**Solutions:**
- Wait a few seconds for agents to initialize
- Verify log directory: `ls .logs/`
- Check agent invocations include partition parameters

### Dashboard Not Updating

**Symptom:** Status stuck, no progress shown

**Causes:**
1. Agents hung or crashed
2. Log files stopped growing
3. Terminal doesn't support ANSI codes

**Solutions:**
- Check agent processes are running: `ps aux | grep source-creator`
- Verify log files growing: `ls -lh .logs/*.txt`
- Try `--no-color` flag for plain text output

### Partitions Show as Failed Incorrectly

**Symptom:** Monitor shows failure but agents completed successfully

**Causes:**
1. Error pattern false positive
2. Warning messages mistaken for errors
3. Log file format unexpected

**Solutions:**
- Check actual log file: `tail -n 50 .logs/source-creator-partition2-execution-log.txt`
- Look for phase completion markers: `grep "\[PHASE\].*complete" .logs/*.txt`
- Report false positive patterns for future enhancement

### Monitor Exits Too Early

**Symptom:** Monitor exits before all partitions complete

**Causes:**
1. Some partition logs missing (agents failed to start)
2. Completion detection triggered prematurely

**Solutions:**
- Count expected vs found logs: `find .logs -maxdepth 1 -name "*-partition*.txt" -type f | wc -l`
- Check for early ERROR markers in logs
- Manually verify completion: `grep "Phase 4.*complete" .logs/*.txt`

## Performance Considerations

### Polling Interval

**Default:** 1 second
- Good balance between responsiveness and CPU usage
- Suitable for 1-20 partitions

**Recommended adjustments:**
- **High partition count (>20):** Increase to 2-3 seconds
- **Fast completion (<30s):** Keep at 1 second
- **Long-running (>5 min):** Can increase to 5 seconds

### Terminal Performance

Dashboard uses `clear` + reprint for updates:
- Works on all terminals
- Minimal CPU overhead
- May cause flicker on slow connections

For continuous logging without interactivity, use `--json` mode and parse output.

## Examples

### Example 1: Monitor source-creator with 6 Partitions

```bash
# In your project directory
cd /Users/you/project/mobilfunkvertraege-smartphone-raten-telekom

# Launch monitor
bash /path/to/cogni-research/scripts/monitor-parallel-execution.sh \
  --log-dir .logs/

# Output shows:
Partition 1: [Phase 3] ████████░░ 80%
Partition 2: [Phase 3] ███████░░░ 70%
...
```

### Example 2: Monitor with JSON Output for Automation

```bash
# Run monitor and capture JSON summary
bash monitor-parallel-execution.sh \
  --log-dir .logs/ \
  --json > monitoring-summary.json

# Parse results
cat monitoring-summary.json | jq '.partitions_failed'
# Output: 1 (indicating 1 partition failed)
```

### Example 3: Monitor fact-checker with Custom Interval

```bash
# Slower polling for long-running fact-checking
bash monitor-parallel-execution.sh \
  --log-dir .logs/ \
  --interval 3
```

## Best Practices

### During Development

1. **Always monitor during parallel execution** - Catches integration issues immediately
2. **Keep monitor in separate terminal** - See real-time status while workflow runs
3. **Use `--json` for automated testing** - Parse results programmatically
4. **Check error patterns** - Report false positives for improvement

### In Production

1. **Set appropriate refresh interval** - Balance responsiveness vs CPU
2. **Log monitoring output** - Use `--no-color > monitor.log` for audit trail
3. **Alert on failures** - Parse JSON output, notify on `partitions_failed > 0`
4. **Archive logs** - Keep partition logs for debugging failed runs

## Related Documentation

- **Sprint 176 Plan:** `.sprints/sprint-176-realtime-monitoring-system/plan.md`
- **Sprint 176 Build Report:** `.sprints/sprint-176-realtime-monitoring-system/build-report.md`
- **Sprint 175 Lessons:** `.sprints/sprint-175-fix-source-creator-deduplication-failures-and-orph/build-report.md` (realtime monitoring experience)
- **Parallelization Strategies:** `cogni-research/skills/deeper-research-1/references/parallelization-strategies.md`
- **Agent Invocation Patterns:** `cogni-research/skills/deeper-synthesis/references/agent-invocation-patterns.md`

## Future Enhancements

Planned for future sprints:

1. ✅ **Automatic integration** - `--monitor` flag in deeper-research skill (Implemented in Sprint 177)
2. **Performance metrics** - Extract phase durations, throughput from logs
3. **Timestamped monitor logs** - Separate monitor-output files for Phase 5.2 and 7
4. **Web dashboard** - Browser-based monitoring with WebSocket updates
5. **Notifications** - Slack/email alerts on completion or failure
6. **Log search** - Query across all partition logs for patterns
7. **Historical comparison** - Compare execution metrics across runs

## Support

For issues or questions:
1. Check troubleshooting section above
2. Review Sprint 176 build report for known limitations
3. Examine partition log files directly for detailed diagnostics
4. Report bugs with log samples and monitor output

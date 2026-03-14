# Pre-Commit Hook: Auto-Contract-Regeneration

## Overview

The `pre-commit` hook automatically regenerates YAML contracts for bash scripts when their interface headers change. This ensures contracts stay synchronized with script definitions, preventing version drift.

## Location

`.git/hooks/pre-commit`

## How It Works

1. **Detects Changes**: Monitors staged `.sh` files in `cogni-research/scripts/` and `cogni-research/skills/*/scripts/`
2. **Checks Headers**: Identifies if script headers (Version, Usage, Arguments, Output, Exit codes) changed
3. **Regenerates Contracts**: Automatically runs `generate-script-contract.sh` for modified scripts
4. **Stages Contracts**: Adds regenerated contracts to the commit
5. **Reports Results**: Shows summary of regenerated contracts

## Requirements

- **CLAUDE_PLUGIN_ROOT** environment variable must be set
- `generate-script-contract.sh` from [dev-work](https://github.com/cogni-work/dev-work) repository must be available
- Script headers must follow Script Interface Specification v1.0.0

## Behavior

### Success Case

```bash
$ git commit -m "Update create-entity.sh parameters"
🔍 Checking for script header changes...
📝 Regenerating contract for: create-entity
   ✅ Contract regenerated and staged: cogni-research/contracts/create-entity.yml

✨ Contract regeneration complete:
   - Regenerated: 1

[main abc1234] Update create-entity.sh parameters
 2 files changed, 15 insertions(+), 3 deletions(-)
```

### No Changes Case

```bash
$ git commit -m "Update README"
# Hook runs silently, no output (no scripts modified)
[main abc1234] Update README
 1 file changed, 5 insertions(+)
```

### Failure Case

```bash
$ git commit -m "Add new script with invalid header"
🔍 Checking for script header changes...
📝 Regenerating contract for: new-script
   ❌ Failed to regenerate contract for: new-script
   Run manually: bash generate-script-contract.sh --script-path scripts/new-script.sh --output-path contracts/new-script.yml

❌ Some contracts failed to regenerate. Please fix and retry commit.
```

## What Gets Processed

**Included:**
- Production scripts in `cogni-research/scripts/*.sh`
- Skill scripts in `cogni-research/skills/*/scripts/*.sh`
- Scripts with header changes (Version, Usage, Arguments, Output, Exit codes)

**Excluded:**
- Test scripts in `*/tests/*`
- Deleted scripts
- Scripts without header changes
- Scripts in other plugins

## Troubleshooting

### Hook Not Running

**Check if hook is executable:**
```bash
ls -l .git/hooks/pre-commit
# Should show: -rwxr-xr-x
```

**Make it executable:**
```bash
chmod +x .git/hooks/pre-commit
```

### CLAUDE_PLUGIN_ROOT Not Set

**Error:**
```
ERROR: CLAUDE_PLUGIN_ROOT environment variable not set
```

**Solution:**
```bash
export CLAUDE_PLUGIN_ROOT="/Users/yourusername/.claude/plugins/marketplaces/cogni-research"
```

Add to your shell profile (`.bashrc`, `.zshrc`) to make permanent.

### Contract Generator Not Found

**Error:**
```
ERROR: Contract generator not found at: /path/to/generate-script-contract.sh
```

**Solution:**
Ensure the dev-work repository is cloned and the script path is configured:
```bash
# Clone dev-work if needed
git clone https://github.com/cogni-work/dev-work.git
ls -l "dev-work/scripts/generate-script-contract.sh"
```

### Manual Contract Regeneration

If hook fails, regenerate contracts manually:

```bash
# Single script (using dev-work repository)
bash "path/to/dev-work/scripts/generate-script-contract.sh" \
  --script-path "cogni-research/scripts/your-script.sh" \
  --output-path "cogni-research/contracts/your-script.yml"

# All scripts in plugin
for script in $(find cogni-research/scripts cogni-research/skills -name "*.sh" | grep -v "/tests/"); do
  script_name=$(basename "$script" .sh)
  bash "path/to/dev-work/scripts/generate-script-contract.sh" \
    --script-path "$script" \
    --output-path "cogni-research/contracts/${script_name}.yml"
done
```

## Bypassing the Hook

**Not recommended**, but possible for emergency fixes:

```bash
git commit --no-verify -m "Emergency fix"
```

**Warning:** This skips contract regeneration. Manually regenerate contracts afterward to maintain compliance.

## Testing the Hook

**Test without committing:**
```bash
# Stage a script change
git add cogni-research/scripts/some-script.sh

# Run hook manually
.git/hooks/pre-commit

# Check results
git status
```

## Maintenance

### Updating the Hook

1. Edit `.git/hooks/pre-commit`
2. Test with `bash .git/hooks/pre-commit`
3. Verify contract regeneration works

### Disabling the Hook

**Temporarily:**
```bash
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
```

**Permanently:**
```bash
rm .git/hooks/pre-commit
```

## Benefits

1. **Prevents Version Drift**: Contracts always match script headers
2. **Reduces Manual Work**: No need to remember to regenerate contracts
3. **Maintains Compliance**: Ensures 100% contract currency
4. **Audit-Ready**: Every commit has synchronized contracts
5. **Catches Errors Early**: Contract generation failures block commits

## Integration with Audit System

The pre-commit hook complements the interface-validator audit system:

| System | Timing | Purpose |
|--------|--------|---------|
| **Pre-commit Hook** | Every commit | Prevent drift (prevention) |
| **Interface-validator** | On-demand/scheduled | Detect existing issues (remediation) |

Together, they ensure continuous interface compliance.

## Version History

- **v1.0.0** (2025-11-13): Initial implementation
  - Auto-detects header changes
  - Regenerates contracts for modified scripts
  - Stages regenerated contracts
  - Reports results to user

## References

- [Script Interface Specification v1.0.0](https://github.com/cogni-work/dev-work/blob/main/docs/script-interface-guide.md)
- [generate-script-contract.sh](https://github.com/cogni-work/dev-work/blob/main/scripts/generate-script-contract.sh)
- [Interface Validator Skill](https://github.com/cogni-work/dev-work/blob/main/skills/interface-validator/SKILL.md)
- [Audit Report](../.audit/audit-report-2025-11-13.md)

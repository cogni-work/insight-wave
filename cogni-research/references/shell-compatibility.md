---
reference: shell-compatibility
version: 1.0.0
purpose: Patterns for zsh/bash compatibility in inline Claude Code bash execution
---

# Shell Compatibility Patterns

## The Problem

Claude Code executes bash commands through the user's default shell, often zsh on macOS.
zsh interprets certain bash constructs differently, causing parse errors.

## Common Error

```text
(eval):1: parse error near `('
```

This occurs when zsh tries to parse bash-specific syntax inline.

## PROHIBITED in Inline Bash

| Pattern | Why It Fails |
|---------|--------------|
| `A=$(cmd) B=$(cmd)` | Multiple assignments with `$()` on one line |
| `if/then/else/fi` blocks | Multi-line constructs in inline execution |
| `ARRAY=($(cmd))` | Bash array syntax with command substitution |
| `declare -a` | Bash-specific array declaration |
| Unquoted `$()` in complex expressions | zsh interprets parentheses differently |
| `$(( a < b ? c : d ))` | Ternary operators in arithmetic - use `[ $a -lt $b ] && a=$c` instead |

## REQUIRED Patterns

### Chain Operations with &&

```bash
# CORRECT - Chain with && separators
A=$(cmd) && B=$(cmd) && echo "$A $B"

# WRONG - Multiple assignments without separators
A=$(cmd) B=$(cmd) echo "$A $B"
```

### Single-Line Conditionals

```bash
# CORRECT - Inline conditional
[ -d "$DIR" ] && echo "exists" || echo "missing"

# WRONG - Multi-line block (fails in inline execution)
if [ -d "$DIR" ]; then
  echo "exists"
fi
```

### Temp Script Pattern for Complex Logic

For arrays, loops, and multi-line conditionals, write to a temp script then execute:

```bash
# Use Bash tool with heredoc (NOT Write tool)
cat > /tmp/batch-processor.sh << 'SCRIPT_EOF'
#!/usr/bin/env bash
set -eo pipefail

# Arrays, loops, multi-line conditionals all allowed here
ARRAY=($(find . -name "*.md" -type f))
for f in "${ARRAY[@]}"; do
  echo "Processing: $f"
done

SCRIPT_EOF
chmod +x /tmp/batch-processor.sh && bash /tmp/batch-processor.sh
```

**Why this works:**

- Temp scripts can contain ANY bash syntax
- Only the `cat >` heredoc line is executed inline (zsh-compatible)
- Complex logic is isolated in the bash script file
- Avoids all zsh parsing issues

### Safe Variable Assignment Patterns

```bash
# CORRECT - Single assignment per command
project_path="/path/to/project"
questions_count=$(find "${project_path}" -name "*.md" | wc -l | tr -d ' ')
echo "Found ${questions_count} questions"

# CORRECT - Chain with && for multiple
PROJECT_PATH="/path" && \
  QUESTIONS=$(find "${PROJECT_PATH}" -name "question-*.md" | wc -l) && \
  echo "Questions: $QUESTIONS"

# WRONG - Multiple assignments with $() on same line
PROJECT_PATH="/path" QUESTIONS=$(find ...) echo "..."
```

## BSD sed vs GNU sed

macOS uses BSD sed which has different syntax from GNU sed:

```bash
# CORRECT - Use -E for extended regex (works on both)
sed -E 's/pattern/replace/' file.txt

# CORRECT - Use awk as alternative (POSIX-compatible)
awk '/pattern/{print $1}' file.txt

# AVOID - GNU-specific options
sed -r 's/pattern/replace/' file.txt  # -r is GNU only
```

## Frontmatter Extraction

```bash
# CORRECT - awk-based extraction (POSIX-compatible)
awk '/^---$/{if(++n==1)next; if(n==2)exit} n==1{print}' file.md

# AVOID - sed -n with complex ranges (BSD/GNU differences)
sed -n '1{/^---$/!q};/^---$/,/^---$/p' file.md
```

## Key Takeaways

1. **One command substitution per line** - Never `A=$(x) B=$(y)` on same line
2. **Use && to chain** - Separate operations with `&&` or `;`
3. **Complex logic = temp script** - Write to file, then execute with `bash`
4. **Use -E for sed** - Extended regex works on both BSD and GNU
5. **Prefer awk** - More portable than complex sed patterns

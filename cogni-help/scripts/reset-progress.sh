#!/bin/bash
# Reset cogni-help course progress.
# Usage: reset-progress.sh [project-dir] [course-id|--all]
# With course-id: resets that course to not-started.
# With --all: removes the entire progress file.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-.}"
TARGET="${2:---all}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid directory required. Usage: reset-progress.sh [project-dir] [course-id|--all]"}' >&2
  exit 1
fi

PROGRESS_FILE="$PROJECT_DIR/.claude/cogni-help.local.md"

ALL_COURSES="tour-research-to-report tour-trends-to-solutions tour-portfolio-to-pitch tour-portfolio-to-website tour-consulting-engagement tour-content-pipeline tour-install-to-infographic"

if [ "$TARGET" = "--all" ]; then
  if [ -f "$PROGRESS_FILE" ]; then
    rm "$PROGRESS_FILE"
  fi
  echo '{"status": "reset_all"}'
  exit 0
fi

# Validate course-id
VALID=false
for c in $ALL_COURSES; do
  if [ "$c" = "$TARGET" ]; then
    VALID=true
    break
  fi
done

if [ "$VALID" = "false" ]; then
  echo "{\"error\": \"Unknown course: $TARGET. Valid courses: $ALL_COURSES\"}" >&2
  exit 1
fi

if [ ! -f "$PROGRESS_FILE" ]; then
  echo "{\"status\": \"reset\", \"course\": \"$TARGET\", \"note\": \"no progress file exists\"}"
  exit 0
fi

# Reset specific course in the YAML frontmatter
python3 -c "
import json, re, sys, datetime

course = sys.argv[1]
progress_file = sys.argv[2]

with open(progress_file) as f:
    content = f.read()

# Find the course block and replace its status
# Match the course ID followed by its indented block
pattern = rf'({re.escape(course)}:\s*\n)((?:    .*\n)*)'
match = re.search(pattern, content)

if match:
    replacement = f'{course}:\n    status: not-started\n'
    content = content[:match.start()] + replacement + content[match.end():]

    # Update last_session
    today = datetime.date.today().isoformat()
    content = re.sub(r'last_session:.*', f'last_session: {today}', content)

    with open(progress_file, 'w') as f:
        f.write(content)

print(json.dumps({'status': 'reset', 'course': course}))
" "$TARGET" "$PROGRESS_FILE"

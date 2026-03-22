#!/bin/bash
# Show cogni-help course progress for a project directory.
# Usage: course-status.sh [project-dir]
# Reads .claude/cogni-help.local.md and outputs JSON with per-course status.
# Exit codes: 0 = success, 1 = error
set -euo pipefail

PROJECT_DIR="${1:-.}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo '{"error": "Valid directory required. Usage: course-status.sh [project-dir]"}' >&2
  exit 1
fi

PROGRESS_FILE="$PROJECT_DIR/.claude/cogni-help.local.md"

ALL_COURSES='["cowork-fundamentals","workspace-obsidian","basic-tools","trends-scouting","trends-reporting","portfolio","visual","research","marketing","sales"]'

if [ ! -f "$PROGRESS_FILE" ]; then
  # No progress file — all courses not started
  python3 -c "
import json
courses = json.loads('$ALL_COURSES')
result = {
    'student': None,
    'courses': {c: {'status': 'not-started'} for c in courses},
    'completed': 0,
    'in_progress': 0,
    'total': len(courses),
    'pct': 0
}
print(json.dumps(result, indent=2))
"
  exit 0
fi

# Parse YAML frontmatter from progress file
python3 -c "
import json, re, sys

all_courses = json.loads('$ALL_COURSES')

# Read the progress file
with open('$PROGRESS_FILE') as f:
    content = f.read()

# Extract YAML frontmatter between --- markers
match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
if not match:
    # No valid frontmatter
    result = {
        'student': None,
        'courses': {c: {'status': 'not-started'} for c in all_courses},
        'completed': 0,
        'in_progress': 0,
        'total': len(all_courses),
        'pct': 0
    }
    print(json.dumps(result, indent=2))
    sys.exit(0)

# Simple YAML parsing for the expected structure
yaml_text = match.group(1)
student = None
courses_data = {}

# Extract student
for line in yaml_text.split('\n'):
    line = line.strip()
    if line.startswith('student:'):
        val = line.split(':', 1)[1].strip()
        if val and val != '(name if provided)':
            student = val

# Extract course data using regex for each course
for course in all_courses:
    pattern = rf'{re.escape(course)}:\s*\n((?:    .*\n)*)'
    m = re.search(pattern, yaml_text)
    if m:
        block = m.group(1)
        status = 'not-started'
        current_module = None
        completed_modules = []

        for bline in block.split('\n'):
            bline = bline.strip()
            if bline.startswith('status:'):
                status = bline.split(':', 1)[1].strip()
            elif bline.startswith('current_module:'):
                try:
                    current_module = int(bline.split(':', 1)[1].strip())
                except ValueError:
                    pass
            elif bline.startswith('completed_modules:'):
                arr = bline.split(':', 1)[1].strip()
                try:
                    completed_modules = json.loads(arr)
                except (json.JSONDecodeError, ValueError):
                    pass

        entry = {'status': status}
        if current_module is not None:
            entry['current_module'] = current_module
        if completed_modules:
            entry['completed_modules'] = completed_modules
        courses_data[course] = entry
    else:
        courses_data[course] = {'status': 'not-started'}

completed = sum(1 for c in courses_data.values() if c['status'] == 'completed')
in_progress = sum(1 for c in courses_data.values() if c['status'] == 'in-progress')
total = len(all_courses)
pct = int(completed * 100 / total) if total > 0 else 0

result = {
    'student': student,
    'courses': courses_data,
    'completed': completed,
    'in_progress': in_progress,
    'total': total,
    'pct': pct
}
print(json.dumps(result, indent=2))
"

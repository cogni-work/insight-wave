#!/bin/bash
# gh-issues-helper.sh — gh CLI wrapper for cogni-issues
# Usage: bash gh-issues-helper.sh <command> [args...]
#
# Commands:
#   check                                                       Verify gh availability + auth status (JSON)
#   create <repo> --title T --body-file F [--labels L1,L2]      Create issue atomically. Body from file, labels CSV.
#   list <repo> [--state open|closed|all] [--limit N] [--label L] [--search Q]
#                                                               List issues as JSON
#   view <repo> <number>                                        Read full issue as JSON
#   search <repo> <query> [--state open|closed|all] [--limit N] Search issues for duplicate detection
#   browse-url <repo> <number>                                  Print canonical issue URL (no network call)
#
# All output is JSON on stdout. Errors go to stderr.
# Requires: gh CLI authenticated (gh auth login).
# Compatible with bash 3.2 (macOS default).
#
# This wrapper is intentionally a parallel sibling of cogni-service's
# scripts/gh-issues.sh — cogni-help should not depend on cogni-service for a
# helper script, but the JSON service contract and bash idioms match so that
# any future consolidation is mechanical.

set -euo pipefail

COMMAND="${1:-}"

# NOTE: The canonical command list lives in the `gh CLI commands` table in
# ../SKILL.md. Update both together when adding or renaming a subcommand.
usage() {
  echo "Usage: bash $0 <command> [args...]" >&2
  echo "Commands: check, create, list, view, search, browse-url" >&2
  exit 1
}

# Emit a JSON error to stderr with optional structured fields.
# Args: message, key1, val1, key2, val2, ...
emit_error() {
  local MSG="$1"; shift
  python3 -c "
import json, sys
msg = sys.argv[1]
pairs = sys.argv[2:]
out = {'error': msg}
for i in range(0, len(pairs), 2):
    out[pairs[i]] = pairs[i+1]
print(json.dumps(out))
" "$MSG" "$@" >&2
}

# Detect platform for setup hints.
detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

# Hint message for installing gh, by platform.
install_hint_for() {
  case "$1" in
    macos) echo "brew install gh" ;;
    linux) echo "See https://github.com/cli/cli/blob/trunk/docs/install_linux.md" ;;
    *)     echo "https://cli.github.com/" ;;
  esac
}

# Check gh CLI is available and authenticated. Used as a guard before any
# network operation; emits a structured JSON error and exits non-zero on
# either failure so the SKILL setup mode can branch on exit code.
check_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    emit_error "gh CLI not found" install_hint "$(install_hint_for "$(detect_platform)")"
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    emit_error "gh CLI not authenticated" login_hint "gh auth login"
    exit 1
  fi
}

case "$COMMAND" in
  check)
    # Probe gh + auth without exiting on failure — return a single JSON object
    # describing the readiness state so the SKILL setup mode can branch
    # cleanly. This is the only command that does not call check_gh; the whole
    # point is to report what check_gh would have asserted.
    PLATFORM="$(detect_platform)"
    GH_INSTALLED="false"
    AUTHENTICATED="false"
    GH_VERSION=""
    GH_USER=""
    if command -v gh >/dev/null 2>&1; then
      GH_INSTALLED="true"
      GH_VERSION="$(gh --version 2>/dev/null | head -1 | awk '{print $3}' || echo '')"
      if gh auth status >/dev/null 2>&1; then
        AUTHENTICATED="true"
        GH_USER="$(gh api user --jq .login 2>/dev/null || echo '')"
      fi
    fi
    INSTALL_HINT="$(install_hint_for "$PLATFORM")"
    python3 -c "
import json, sys
print(json.dumps({
  'platform': sys.argv[1],
  'gh_installed': sys.argv[2] == 'true',
  'gh_version': sys.argv[3] or None,
  'authenticated': sys.argv[4] == 'true',
  'gh_user': sys.argv[5] or None,
  'install_hint': sys.argv[6],
  'login_hint': 'gh auth login',
}))
" "$PLATFORM" "$GH_INSTALLED" "$GH_VERSION" "$AUTHENTICATED" "$GH_USER" "$INSTALL_HINT"
    ;;

  create)
    # Atomic issue creation. Labels are validated against the repo's existing
    # label set up-front so we fail fast instead of half-creating an issue
    # without its type label — that's the core reliability win over the prior
    # browser-automation path, which silently dropped failed label clicks.
    check_gh
    REPO="${2:-}"
    [ -z "$REPO" ] && usage
    shift 2
    TITLE=""
    BODY_FILE=""
    LABELS_CSV=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --title) TITLE="${2:-}"; shift 2 ;;
        --body-file) BODY_FILE="${2:-}"; shift 2 ;;
        --labels) LABELS_CSV="${2:-}"; shift 2 ;;
        *) emit_error "create: unknown flag" flag "$1"; exit 1 ;;
      esac
    done
    [ -z "$TITLE" ] && { emit_error "create: --title is required"; exit 1; }
    [ -z "$BODY_FILE" ] && { emit_error "create: --body-file is required"; exit 1; }
    [ ! -f "$BODY_FILE" ] && { emit_error "create: body file not found" path "$BODY_FILE"; exit 1; }
    if [ -n "$LABELS_CSV" ]; then
      EXISTING_LABELS=$(gh label list --repo "$REPO" --json name --jq '.[].name' 2>/dev/null || true)
      MISSING=""
      IFS=',' read -r -a LABEL_ARR <<< "$LABELS_CSV"
      for LBL in "${LABEL_ARR[@]}"; do
        LBL_TRIM=$(echo "$LBL" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$LBL_TRIM" ] && continue
        if ! echo "$EXISTING_LABELS" | grep -qx "$LBL_TRIM"; then
          MISSING="${MISSING}${LBL_TRIM},"
        fi
      done
      if [ -n "$MISSING" ]; then
        MISSING="${MISSING%,}"
        emit_error "create: label(s) missing from repo" repo "$REPO" missing_labels "$MISSING" hint "Create the label on GitHub or omit it from --labels"
        exit 1
      fi
    fi
    GH_ARGS=(--repo "$REPO" --title "$TITLE" --body-file "$BODY_FILE")
    if [ -n "$LABELS_CSV" ]; then
      IFS=',' read -r -a LABEL_ARR <<< "$LABELS_CSV"
      for LBL in "${LABEL_ARR[@]}"; do
        LBL_TRIM=$(echo "$LBL" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$LBL_TRIM" ] && continue
        GH_ARGS+=(--label "$LBL_TRIM")
      done
    fi
    if ! URL_OUT=$(gh issue create "${GH_ARGS[@]}" 2>&1); then
      emit_error "create: gh issue create failed" repo "$REPO" title "$TITLE" detail "$URL_OUT"
      exit 1
    fi
    URL=$(echo "$URL_OUT" | grep -oE 'https://[^ ]+/issues/[0-9]+' | tail -1)
    if [ -z "$URL" ]; then
      emit_error "create: could not parse issue URL from gh output" detail "$URL_OUT"
      exit 1
    fi
    NUMBER=$(echo "$URL" | grep -oE '[0-9]+$')
    python3 -c "
import json, sys
print(json.dumps({
  'status': 'created',
  'number': int(sys.argv[1]),
  'url': sys.argv[2],
  'title': sys.argv[3],
  'labels': sys.argv[4].split(',') if sys.argv[4] else [],
}))
" "$NUMBER" "$URL" "$TITLE" "$LABELS_CSV"
    ;;

  list)
    check_gh
    REPO="${2:-}"
    [ -z "$REPO" ] && usage
    shift 2
    STATE="open"
    LIMIT="50"
    LABEL=""
    SEARCH=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --state) STATE="${2:-open}"; shift 2 ;;
        --limit) LIMIT="${2:-50}"; shift 2 ;;
        --label) LABEL="${2:-}"; shift 2 ;;
        --search) SEARCH="${2:-}"; shift 2 ;;
        *) emit_error "list: unknown flag" flag "$1"; exit 1 ;;
      esac
    done
    GH_ARGS=(--repo "$REPO" --state "$STATE" --limit "$LIMIT" --json number,title,labels,state,createdAt,updatedAt,author,url)
    [ -n "$LABEL" ] && GH_ARGS+=(--label "$LABEL")
    [ -n "$SEARCH" ] && GH_ARGS+=(--search "$SEARCH")
    gh issue list "${GH_ARGS[@]}"
    ;;

  view)
    check_gh
    REPO="${2:-}"
    NUMBER="${3:-}"
    if [ -z "$REPO" ] || [ -z "$NUMBER" ]; then
      usage
    fi
    gh issue view "$NUMBER" --repo "$REPO" --json number,title,body,labels,state,comments,createdAt,updatedAt,author,assignees,url
    ;;

  search)
    # Convenience wrapper for duplicate detection during create flow. Uses
    # `gh issue list --search` rather than `gh search issues` so results are
    # already scoped to one repo and JSON-shaped identically to `list`.
    check_gh
    REPO="${2:-}"
    QUERY="${3:-}"
    if [ -z "$REPO" ] || [ -z "$QUERY" ]; then
      usage
    fi
    shift 3
    STATE="open"
    LIMIT="20"
    while [ $# -gt 0 ]; do
      case "$1" in
        --state) STATE="${2:-open}"; shift 2 ;;
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        *) emit_error "search: unknown flag" flag "$1"; exit 1 ;;
      esac
    done
    gh issue list --repo "$REPO" --state "$STATE" --limit "$LIMIT" --search "$QUERY" \
      --json number,title,labels,state,createdAt,updatedAt,author,url
    ;;

  browse-url)
    # Pure-string operation; no network call, no gh dependency. Useful for the
    # SKILL's browse mode, which prints a URL the user can click or open with
    # `open <url>` / `xdg-open <url>`.
    REPO="${2:-}"
    NUMBER="${3:-}"
    if [ -z "$REPO" ] || [ -z "$NUMBER" ]; then
      usage
    fi
    if ! echo "$REPO" | grep -qE '^[^/]+/[^/]+$'; then
      emit_error "browse-url: repo must be in owner/name form" repo "$REPO"
      exit 1
    fi
    if ! echo "$NUMBER" | grep -qE '^[0-9]+$'; then
      emit_error "browse-url: number must be a positive integer" number "$NUMBER"
      exit 1
    fi
    URL="https://github.com/${REPO}/issues/${NUMBER}"
    echo "{\"url\":\"$URL\",\"repo\":\"$REPO\",\"number\":$NUMBER}"
    ;;

  *)
    usage
    ;;
esac

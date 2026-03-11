#!/usr/bin/env bash
set -euo pipefail
# portability-utils.sh
# Version: 1.0.0
# Purpose: Cross-platform wrapper functions for bash scripts
#
# This file provides portable wrapper functions that handle platform
# differences between macOS, Linux, and Git Bash on Windows.
#
# Usage:
#   source "${CLAUDE_PLUGIN_ROOT}/bash/portability-utils.sh"
#
#   # Use portable functions instead of direct commands
#   size=$(portable_file_size "/path/to/file")
#   portable_sed_i 's/old/new/g' "/path/to/file"
#
# Functions provided:
#   portable_file_size      - Get file size in bytes
#   portable_file_mtime     - Get file modification time (Unix timestamp)
#   portable_sed_i          - In-place sed replacement
#   portable_mktemp         - Create temp file
#   portable_mktemp_d       - Create temp directory
#   portable_realpath       - Get absolute path (resolving symlinks)
#   portable_date_iso       - Get current date in ISO 8601 UTC format
#   portable_date_ymd       - Get current date in YYYY-MM-DD format
#   portable_base64_encode  - Base64 encode a string
#   portable_md5            - Get MD5 hash of a string
#   portable_sha256         - Get SHA-256 hash of a string
#   portable_grep_p         - Grep with Perl regex support
#   portable_lock_acquire   - Acquire a file lock with timeout
#   portable_lock_release   - Release a file lock
#   portable_wsl_path       - Convert Windows path to WSL /mnt/ format
#   is_macos                - Check if running on macOS
#   is_linux                - Check if running on Linux
#   is_windows              - Check if running on Windows (Git Bash/MSYS/Cygwin)
#   is_wsl                  - Check if running on WSL
#   has_command              - Check if a command is available
#
# Platform detection:
#   PORTABLE_PLATFORM - "darwin", "linux", or "windows"
# Detect platform
if [[ "$(uname)" == "Darwin" ]]; then
    readonly PORTABLE_PLATFORM="darwin"
elif [[ "$(uname)" == "Linux" ]]; then
    readonly PORTABLE_PLATFORM="linux"
# Use separate tests to avoid pipe character issues in eval contexts
elif [[ "$(uname)" =~ MINGW ]] || [[ "$(uname)" =~ MSYS ]] || [[ "$(uname)" =~ CYGWIN ]]; then
    readonly PORTABLE_PLATFORM="windows"
else
    readonly PORTABLE_PLATFORM="unknown"
fi

# Export for child scripts
export PORTABLE_PLATFORM

# ============================================================================
# FILE SIZE
# ============================================================================
# macOS: stat -f%z
# Linux: stat -c%s
# Git Bash: stat -c%s (uses GNU stat)

portable_file_size() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi

    case "$PORTABLE_PLATFORM" in
        darwin)
            stat -f%z "$file"
            ;;
        linux|windows)
            stat -c%s "$file"
            ;;
        *)
            # Fallback: try both
            stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
            ;;
    esac
}

# ============================================================================
# FILE MODIFICATION TIME
# ============================================================================
# macOS: stat -f%m
# Linux: stat -c%Y
# Returns Unix timestamp

portable_file_mtime() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        echo "0"
        return 1
    fi

    case "$PORTABLE_PLATFORM" in
        darwin)
            stat -f%m "$file"
            ;;
        linux|windows)
            stat -c%Y "$file"
            ;;
        *)
            stat -f%m "$file" 2>/dev/null || stat -c%Y "$file" 2>/dev/null || echo "0"
            ;;
    esac
}

# ============================================================================
# IN-PLACE SED
# ============================================================================
# macOS: sed -i '' 'pattern' file
# Linux: sed -i 'pattern' file
# Git Bash: sed -i 'pattern' file (uses GNU sed)

portable_sed_i() {
    local pattern="$1"
    local file="$2"

    case "$PORTABLE_PLATFORM" in
        darwin)
            sed -i '' "$pattern" "$file"
            ;;
        linux|windows)
            sed -i "$pattern" "$file"
            ;;
        *)
            # Try GNU sed first (more common), then BSD
            if sed -i "$pattern" "$file" 2>/dev/null; then
                :
            else
                sed -i '' "$pattern" "$file"
            fi
            ;;
    esac
}

# ============================================================================
# TEMP FILE/DIRECTORY
# ============================================================================
# mktemp behavior is mostly consistent, but template syntax varies

portable_mktemp() {
    local template="${1:-tmp.XXXXXX}"
    mktemp -t "$template" 2>/dev/null || mktemp
}

portable_mktemp_d() {
    local template="${1:-tmp.XXXXXX}"
    mktemp -d -t "$template" 2>/dev/null || mktemp -d
}

# ============================================================================
# REALPATH / READLINK
# ============================================================================
# macOS: readlink doesn't have -f, need to use Python or manual resolution
# Linux: readlink -f
# Git Bash: readlink -f (GNU version)

portable_realpath() {
    local path="$1"

    case "$PORTABLE_PLATFORM" in
        darwin)
            # macOS: Use Python for reliable resolution (path passed via sys.argv to avoid injection)
            python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$path"
            ;;
        linux|windows)
            readlink -f "$path"
            ;;
        *)
            # Fallback: try readlink -f, then Python
            readlink -f "$path" 2>/dev/null || \
                python3 -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$path" 2>/dev/null || \
                echo "$path"
            ;;
    esac
}

# ============================================================================
# DATE FORMATTING
# ============================================================================
# ISO 8601 date format

portable_date_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

portable_date_ymd() {
    date -u +"%Y-%m-%d"
}

# ============================================================================
# BASE64 ENCODING
# ============================================================================
# macOS: base64 (no -w option)
# Linux: base64 -w 0 (disable line wrapping)

portable_base64_encode() {
    local input="$1"

    case "$PORTABLE_PLATFORM" in
        darwin)
            echo -n "$input" | base64
            ;;
        linux|windows)
            echo -n "$input" | base64 -w 0
            ;;
        *)
            echo -n "$input" | base64 -w 0 2>/dev/null || echo -n "$input" | base64
            ;;
    esac
}

# ============================================================================
# MD5 HASH
# ============================================================================
# macOS: md5 -q
# Linux: md5sum | cut -d' ' -f1

portable_md5() {
    local input="$1"

    case "$PORTABLE_PLATFORM" in
        darwin)
            echo -n "$input" | md5
            ;;
        linux|windows)
            echo -n "$input" | md5sum | cut -d' ' -f1
            ;;
        *)
            echo -n "$input" | md5sum 2>/dev/null | cut -d' ' -f1 || \
                echo -n "$input" | md5 2>/dev/null
            ;;
    esac
}

# ============================================================================
# SHA256 HASH
# ============================================================================
# macOS: shasum -a 256 | cut -d' ' -f1
# Linux: sha256sum | cut -d' ' -f1

portable_sha256() {
    local input="$1"

    case "$PORTABLE_PLATFORM" in
        darwin)
            echo -n "$input" | shasum -a 256 | cut -d' ' -f1
            ;;
        linux|windows)
            echo -n "$input" | sha256sum | cut -d' ' -f1
            ;;
        *)
            echo -n "$input" | sha256sum 2>/dev/null | cut -d' ' -f1 || \
                echo -n "$input" | shasum -a 256 | cut -d' ' -f1
            ;;
    esac
}

# ============================================================================
# GREP WITH PERL REGEX
# ============================================================================
# macOS grep doesn't support -P, use -E or perl
# Linux: grep -P

portable_grep_p() {
    local pattern="$1"
    shift
    local files=("$@")

    case "$PORTABLE_PLATFORM" in
        darwin)
            # Use perl for macOS (more reliable than grep -E for complex patterns)
            perl -ne "print if /$pattern/" "${files[@]}"
            ;;
        linux|windows)
            grep -P "$pattern" "${files[@]}"
            ;;
        *)
            grep -P "$pattern" "${files[@]}" 2>/dev/null || \
                perl -ne "print if /$pattern/" "${files[@]}"
            ;;
    esac
}

# ============================================================================
# FILE LOCKING
# ============================================================================
# Uses flock on Linux/Git Bash, or a PID-file approach on macOS

portable_lock_acquire() {
    local lockfile="$1"
    local timeout="${2:-30}"

    # Create lock directory if needed
    mkdir -p "$(dirname "$lockfile")"

    case "$PORTABLE_PLATFORM" in
        darwin)
            # macOS: Use PID file approach
            local start_time
            start_time="$(date +%s)"
            while true; do
                if (set -o noclobber; echo $$ > "$lockfile") 2>/dev/null; then
                    return 0
                fi
                local elapsed=$(( $(date +%s) - start_time ))
                if [[ $elapsed -ge $timeout ]]; then
                    return 1
                fi
                sleep 0.1
            done
            ;;
        linux|windows)
            # Linux/Git Bash: Use flock
            exec 200>"$lockfile"
            flock -w "$timeout" 200
            ;;
        *)
            # Fallback to PID file
            if (set -o noclobber; echo $$ > "$lockfile") 2>/dev/null; then
                return 0
            fi
            return 1
            ;;
    esac
}

portable_lock_release() {
    local lockfile="$1"

    case "$PORTABLE_PLATFORM" in
        darwin)
            rm -f "$lockfile"
            ;;
        linux|windows)
            flock -u 200 2>/dev/null || true
            rm -f "$lockfile"
            ;;
        *)
            rm -f "$lockfile"
            ;;
    esac
}

# ============================================================================
# WSL PATH CONVERSION
# ============================================================================
# Convert a Windows path to WSL /mnt/ format
# e.g. C:\Users\foo → /mnt/c/Users/foo, C:/Users/foo → /mnt/c/Users/foo
# Handles: Windows absolute, Git Bash /c/..., and already-converted /mnt/...

portable_wsl_path() {
    local win_path="$1"

    # Already in WSL /mnt/ format - return as-is (prevents double conversion)
    if [[ "$win_path" == /mnt/* ]]; then
        echo "$win_path"
        return
    fi

    # Handle Git Bash /c/Users/... format -> /mnt/c/Users/...
    if [[ "$win_path" =~ ^/([a-zA-Z])/ ]]; then
        local drive_letter
        drive_letter="$(echo "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
        echo "/mnt/${drive_letter}${win_path:2}"
        return
    fi

    # Use wslpath if available (running in WSL)
    if command -v wslpath &>/dev/null; then
        wslpath -u "$win_path"
    else
        # Manual conversion fallback (running from Git Bash or native Windows)
        echo "$win_path" | sed -e 's|\\|/|g' -e 's|^\([A-Za-z]\):|/mnt/\L\1|'
    fi
}

# ============================================================================
# UTILITY: Check if running on specific platform
# ============================================================================

is_macos() {
    [[ "$PORTABLE_PLATFORM" == "darwin" ]]
}

is_linux() {
    [[ "$PORTABLE_PLATFORM" == "linux" ]]
}

is_windows() {
    [[ "$PORTABLE_PLATFORM" == "windows" ]]
}

is_wsl() {
    [[ "$PORTABLE_PLATFORM" == "linux" ]] && grep -qi microsoft /proc/version 2>/dev/null
}

# ============================================================================
# UTILITY: Check for command availability
# ============================================================================

has_command() {
    command -v "$1" &>/dev/null
}

# ============================================================================
# Export all functions for use in subshells
# ============================================================================

export -f portable_file_size
export -f portable_file_mtime
export -f portable_sed_i
export -f portable_mktemp
export -f portable_mktemp_d
export -f portable_realpath
export -f portable_date_iso
export -f portable_date_ymd
export -f portable_base64_encode
export -f portable_md5
export -f portable_sha256
export -f portable_grep_p
export -f portable_lock_acquire
export -f portable_lock_release
export -f portable_wsl_path
export -f is_macos
export -f is_linux
export -f is_windows
export -f is_wsl
export -f has_command

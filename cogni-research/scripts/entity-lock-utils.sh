#!/usr/bin/env bash
set -euo pipefail
# entity-lock-utils.sh
# Version: 1.2.0
# Purpose: Provide mkdir-based advisory locks for atomic entity creation operations
# Category: utilities
#
# Changelog:
# - v1.2.0 (2025-11-18, Sprint 318): Add QUIET_MODE environment variable to suppress logging
#   when scripts need pure JSON output. Fixes jq parse errors in source-creator batch processing.
# - v1.1.0: Add stale lock cleanup after timeout
# - v1.0.0: Initial release
#
# Usage: Source this file to access lock management functions
#
# Environment Variables:
#   QUIET_MODE - Set to "true" to suppress all logging output (default: false)
#                Used when calling scripts expect pure JSON responses
#
# Functions:
#   acquire_entity_lock <entity_type> <project_path>
#     - Acquires lock with 30s timeout
#     - Returns 0 on success, 1 on timeout
#
#   release_entity_lock <entity_type> <project_path>
#     - Releases lock safely
#     - Returns 0 (safe even if lock doesn't exist)
#
#   acquire_lock <lock_path>
#     - Acquires generic path-based lock with 30s timeout
#     - Returns 0 on success, 1 on timeout
#
#   release_lock <lock_path>
#     - Releases generic path-based lock safely
#     - Returns 0 (safe even if lock doesn't exist)
#
#   cleanup_stale_locks <project_path>
#     - Removes locks older than 5 minutes
#     - Returns 0 on success, 1 on errors
#
# Exit codes:
#   0 - Success
#   1 - Failure (timeout, validation error)
#
# Example (Entity-type based locking):
#   # Source the utilities
#   source entity-lock-utils.sh
#
#   # Acquire lock
#   if acquire_entity_lock "07-sources" "/path/to/project"; then
#     # Critical section
#     release_entity_lock "07-sources" "/path/to/project"
#   fi
#
# Example (Path-based locking):
#   # Source the utilities
#   source entity-lock-utils.sh
#
#   # Acquire lock for arbitrary resource
#   lock_path="$PROJECT_PATH/.locks/entity-index-global"
#   if acquire_lock "$lock_path"; then
#     # Critical section - update global index
#     release_lock "$lock_path"
#   fi

# Bash 3.2 compatible

# acquire_entity_lock: Acquire advisory lock for entity type with timeout
# Arguments:
#   $1 - entity_type: String identifier for entity (e.g., "researcher", "analyst")
#   $2 - project_path: Absolute path to project root
# Returns:
#   0 - Lock acquired successfully
#   1 - Timeout or validation error
acquire_entity_lock() {
    local entity_type="${1:-}"
    local project_path="${2:-}"

    # Validate arguments
    if [[ -z "$entity_type" ]]; then
        echo "ERROR: entity_type required" >&2
        return 1
    fi

    if [[ -z "$project_path" ]]; then
        echo "ERROR: project_path required" >&2
        return 1
    fi

    if [[ ! -d "$project_path" ]]; then
        echo "ERROR: project_path does not exist: $project_path" >&2
        return 1
    fi

    # Create locks directory structure if missing
    local locks_base="$project_path/.metadata/locks"
    if [[ ! -d "$locks_base" ]]; then
        mkdir -p "$locks_base" 2>/dev/null || {
            echo "ERROR: Cannot create locks directory: $locks_base" >&2
            return 1
        }
    fi

    local lock_path="$locks_base/$entity_type"
    local max_wait=30

    # Only output logs if not in quiet mode (used when caller expects JSON output)
    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Attempting to acquire lock for entity type: $entity_type" >&2

    # BUG-043 FIX: Improved timing precision using epoch seconds instead of tenths
    # Try to acquire lock with timeout
    local start_time="$(date +%s)"
    while true; do
        # mkdir is atomic - either succeeds or fails
        if mkdir "$lock_path" 2>/dev/null; then
            local current_time="$(date +%s)"
            local elapsed=$((current_time - start_time))
            ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Lock acquired for entity type: $entity_type (elapsed: ${elapsed}s)" >&2
            return 0
        fi

        # Check timeout using epoch time for precision
        local current_time="$(date +%s)"
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $max_wait ]; then
            break
        fi

        # Lock exists, wait and retry
        sleep 0.1
    done

    # ============================================================================
    # BUG-010 FIX: STALE LOCK CLEANUP AFTER TIMEOUT
    # ============================================================================
    # Timeout reached - check if lock is stale before failing
    # A lock is stale if it's older than timeout + grace period (1 minute)
    #
    # This prevents permanent deadlocks caused by:
    # - Process crashes while holding lock
    # - System shutdowns
    # - Unhandled exceptions in cleanup trap
    #
    # Safety: Grace period ensures we don't remove locks from active processes
    # ============================================================================
    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "WARN: Lock acquisition timeout for entity type: $entity_type (waited: ${max_wait}s)" >&2

    if [[ -d "$lock_path" ]]; then
        # Check if lock is stale (older than 1 minute = 60 seconds)
        # Using find with -mmin for macOS/Linux compatibility
        local stale_locks
        stale_locks="$(find "$lock_path" -type d -mmin +1 2>/dev/null | wc -l | tr -d ' ')"

        if [[ "$stale_locks" -gt 0 ]]; then
            ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "WARN: Detected stale lock (>1 minute old), attempting emergency cleanup: $lock_path" >&2

            # Emergency cleanup of stale lock
            if rmdir "$lock_path" 2>/dev/null; then
                ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Successfully cleaned up stale lock: $entity_type" >&2

                # Retry acquisition once after cleanup
                if mkdir "$lock_path" 2>/dev/null; then
                    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Lock acquired after stale lock cleanup: $entity_type" >&2
                    return 0
                else
                    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to acquire lock even after stale lock cleanup: $entity_type" >&2
                fi
            else
                ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to remove stale lock (may contain files): $lock_path" >&2
            fi
        fi
    fi

    # Final failure after timeout and stale lock check
    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to acquire lock after ${max_wait}s timeout: $entity_type" >&2
    return 1
}

# release_entity_lock: Release advisory lock for entity type
# Arguments:
#   $1 - entity_type: String identifier for entity
#   $2 - project_path: Absolute path to project root
# Returns:
#   0 - Always (safe even if lock doesn't exist)
release_entity_lock() {
    local entity_type="${1:-}"
    local project_path="${2:-}"

    # Validate arguments (silent failure for release is acceptable)
    if [[ -z "$entity_type" ]] || [[ -z "$project_path" ]]; then
        return 0
    fi

    local lock_path="$project_path/.metadata/locks/$entity_type"

    # Remove lock directory (rmdir only succeeds if empty, which is what we want)
    # Use || true to make this safe even if lock doesn't exist
    rmdir "$lock_path" 2>/dev/null || true

    return 0
}

# acquire_lock: Acquire advisory lock for arbitrary resource path with timeout
# Arguments:
#   $1 - lock_path: Absolute path to lock directory (e.g., /path/.locks/resource-name)
# Returns:
#   0 - Lock acquired successfully
#   1 - Timeout or validation error
#
# Notes:
#   - Parent directory of lock_path must exist
#   - Lock is created as empty directory using atomic mkdir
#   - Includes stale lock cleanup (locks older than 1 minute)
#   - 30 second timeout with 0.1s polling interval
#
# Example:
#   lock_path="$PROJECT_PATH/.locks/entity-index-global"
#   if acquire_lock "$lock_path"; then
#     # Critical section
#     release_lock "$lock_path"
#   fi
acquire_lock() {
    local lock_path="${1:-}"

    # Validate arguments
    if [[ -z "$lock_path" ]]; then
        echo "ERROR: lock_path required" >&2
        return 1
    fi

    # Validate that parent directory exists
    local lock_parent
    lock_parent="$(dirname "$lock_path")"
    if [[ ! -d "$lock_parent" ]]; then
        echo "ERROR: lock parent directory does not exist: $lock_parent" >&2
        return 1
    fi

    local max_wait=30
    local lock_name
    lock_name="$(basename "$lock_path")"

    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Attempting to acquire lock: $lock_name" >&2

    # Try to acquire lock with timeout
    local start_time="$(date +%s)"
    while true; do
        # mkdir is atomic - either succeeds or fails
        if mkdir "$lock_path" 2>/dev/null; then
            local current_time="$(date +%s)"
            local elapsed=$((current_time - start_time))
            ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Lock acquired: $lock_name (elapsed: ${elapsed}s)" >&2
            return 0
        fi

        # Check timeout using epoch time for precision
        local current_time="$(date +%s)"
        local elapsed=$((current_time - start_time))

        if [ $elapsed -ge $max_wait ]; then
            break
        fi

        # Lock exists, wait and retry
        sleep 0.1
    done

    # Timeout reached - check if lock is stale before failing
    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "WARN: Lock acquisition timeout: $lock_name (waited: ${max_wait}s)" >&2

    if [[ -d "$lock_path" ]]; then
        # Check if lock is stale (older than 1 minute = 60 seconds)
        # Using find with -mmin for macOS/Linux compatibility
        local stale_locks
        stale_locks="$(find "$lock_path" -type d -mmin +1 2>/dev/null | wc -l | tr -d ' ')"

        if [[ "$stale_locks" -gt 0 ]]; then
            ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "WARN: Detected stale lock (>1 minute old), attempting emergency cleanup: $lock_path" >&2

            # Emergency cleanup of stale lock
            if rmdir "$lock_path" 2>/dev/null; then
                ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Successfully cleaned up stale lock: $lock_name" >&2

                # Retry acquisition once after cleanup
                if mkdir "$lock_path" 2>/dev/null; then
                    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "INFO: Lock acquired after stale lock cleanup: $lock_name" >&2
                    return 0
                else
                    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to acquire lock even after stale lock cleanup: $lock_name" >&2
                fi
            else
                ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to remove stale lock (may contain files): $lock_path" >&2
            fi
        fi
    fi

    # Final failure after timeout and stale lock check
    ! [[ "${QUIET_MODE:-false}" == "true" ]] && echo "ERROR: Failed to acquire lock after ${max_wait}s timeout: $lock_name" >&2
    return 1
}

# release_lock: Release advisory lock for arbitrary resource path
# Arguments:
#   $1 - lock_path: Absolute path to lock directory
# Returns:
#   0 - Always (safe even if lock doesn't exist)
#
# Notes:
#   - Silent operation (no logging)
#   - Safe to call even if lock doesn't exist
#   - Uses rmdir for atomic cleanup
#
# Example:
#   release_lock "$PROJECT_PATH/.locks/entity-index-global"
release_lock() {
    local lock_path="${1:-}"

    # Validate arguments (silent failure for release is acceptable)
    if [[ -z "$lock_path" ]]; then
        return 0
    fi

    # Remove lock directory (rmdir only succeeds if empty, which is what we want)
    # Use || true to make this safe even if lock doesn't exist
    rmdir "$lock_path" 2>/dev/null || true

    return 0
}

# cleanup_stale_locks: Remove locks older than 5 minutes
# Arguments:
#   $1 - project_path: Absolute path to project root
# Returns:
#   0 - Success (or no locks to clean)
#   1 - Validation error
cleanup_stale_locks() {
    local project_path="${1:-}"

    # Validate arguments
    if [[ -z "$project_path" ]]; then
        echo "ERROR: project_path required" >&2
        return 1
    fi

    if [[ ! -d "$project_path" ]]; then
        echo "ERROR: project_path does not exist: $project_path" >&2
        return 1
    fi

    local locks_base="$project_path/.metadata/locks"

    # If locks directory doesn't exist, nothing to clean
    if [[ ! -d "$locks_base" ]]; then
        return 0
    fi

    local current_time
    current_time="$(date +%s)"
    local stale_threshold=300  # 5 minutes in seconds
    local cleaned_count=0

    # Find all lock directories
    # Bash 3.2 compatible: avoid globstar, use find
    while IFS= read -r lock_dir; do
        # Skip if not a directory
        [[ -d "$lock_dir" ]] || continue

        # Get lock modification time (macOS compatible stat)
        local lock_mtime
        lock_mtime="$(stat -f %m "$lock_dir" 2>/dev/null)" || continue

        # Calculate age
        local lock_age=$((current_time - lock_mtime))

        # Remove if stale
        if [[ $lock_age -gt $stale_threshold ]]; then
            local entity_type
            entity_type="$(basename "$lock_dir")"

            if rmdir "$lock_dir" 2>/dev/null; then
                echo "INFO: Cleaned stale lock: $entity_type (age: ${lock_age}s)" >&2
                cleaned_count=$((cleaned_count + 1))
            else
                echo "WARN: Could not remove stale lock: $lock_dir" >&2
            fi
        fi
    done < <(find "$locks_base" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

    if [[ $cleaned_count -gt 0 ]]; then
        echo "INFO: Cleaned $cleaned_count stale lock(s)" >&2
    fi

    return 0
}

# If executed directly (not sourced), show usage
if [[ "${BASH_SOURCE[0]}" = "${0}" ]]; then
    cat >&2 <<'EOF'
entity-lock-utils.sh - Advisory lock utilities for entity operations

This script provides functions for managing advisory locks using mkdir.
It should be SOURCED, not executed directly.

Usage:
    source entity-lock-utils.sh

Functions:
    acquire_entity_lock <entity_type> <project_path>
        Acquire entity-type based lock with 30s timeout
        Returns: 0 on success, 1 on timeout

    release_entity_lock <entity_type> <project_path>
        Release entity-type based lock (safe if doesn't exist)
        Returns: 0 always

    acquire_lock <lock_path>
        Acquire generic path-based lock with 30s timeout
        Returns: 0 on success, 1 on timeout

    release_lock <lock_path>
        Release generic path-based lock (safe if doesn't exist)
        Returns: 0 always

    cleanup_stale_locks <project_path>
        Remove locks older than 5 minutes
        Returns: 0 on success, 1 on error

Example (Entity-type based locking):
    source entity-lock-utils.sh

    if acquire_entity_lock "researcher" "/path/to/project"; then
        # Critical section - create entity
        echo "Creating entity..."

        # Always release lock
        release_entity_lock "researcher" "/path/to/project"
    else
        echo "Failed to acquire lock" >&2
        exit 1
    fi

Example (Path-based locking):
    source entity-lock-utils.sh

    lock_path="$PROJECT_PATH/.locks/entity-index-global"
    if acquire_lock "$lock_path"; then
        # Critical section - update global index
        echo "Updating global index..."

        # Always release lock
        release_lock "$lock_path"
    else
        echo "Failed to acquire lock" >&2
        exit 1
    fi

    # Periodic cleanup
    cleanup_stale_locks "/path/to/project"

EOF
    exit 1
fi

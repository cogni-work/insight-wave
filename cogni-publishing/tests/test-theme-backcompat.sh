#!/usr/bin/env bash
# CI seam for scripts/verify-theme-backcompat.sh — the theme back-compat harness.
#
# scripts/run-plugin-tests.py discovers suites with two non-recursive globs,
# `tests/*.sh` and `*/tests/*.sh`. The harness lives one directory over, under
# `scripts/`, so nothing discovers it and it has never run in CI however loudly it
# fails. This file sits where the runner already looks and hands its exit status
# straight back.
#
# This is a per-harness wrapper, not a settled pattern to copy. The underlying gap
# is in discovery: every `*/scripts/verify-*.sh` harness is invisible to CI for the
# same reason, and cogni-publishing/scripts/verify-claude-design-importer.sh is in
# the identical blind spot today. Widening the runner's globs would fix the class
# in one line; that belongs in its own change against run-plugin-tests.py and its
# suite, not here. Prefer it to a second wrapper.
#
# Contract: no arguments, no network, no cwd assumptions, and the harness's exit
# status reaches the runner unchanged — a wrapper that swallowed a failure would
# reproduce exactly the vacuous-pass class this suite exists to prevent.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "$0")" && pwd)"

# exec replaces this shell with the harness, so its exit status IS this suite's
# status — no capture, and no branch that could drop a non-zero code on the floor.
exec bash "$TESTS_DIR/../scripts/verify-theme-backcompat.sh"

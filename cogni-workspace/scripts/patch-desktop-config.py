#!/usr/bin/env python3
"""
patch-desktop-config.py — Merge git-installed MCP servers into a user's MCP config.

Reads mcp-git-registry.json for server definitions, resolves the installed wrapper
path from ~/.claude/mcp-servers/<name>/start.sh, and merges each entry into the
selected target's config. Creates a timestamped backup before any modification.

Two targets, selected with --target:
  desktop  Claude Desktop's claude_desktop_config.json (platform-specific path)
  cli      Claude Code's user-scope config, ~/.claude.json, top-level "mcpServers"
  both     Write each in turn, reporting per-target actions

The default is `desktop`, so callers that predate --target keep their exact
behaviour. The two entry shapes differ only in that a CLI entry carries an
explicit "type": "stdio"; both are keyed by the registry's desktop_config_key,
because that key is the server name MCP tool names are derived from
(mcp__<key>__*) and renaming it silently breaks every hook matcher.

The file name is kept despite the widened remit: it is referenced by call sites
and by the installed marketplace cache, and a rename buys a better noun at the
cost of that stability.

Usage:
  python3 patch-desktop-config.py --registry <path>
      [--target desktop|cli|both] [--server <name>]... [--dry-run] [--force]
      [--config-path <path>] [--cli-config-path <path>]

Output: JSON {success, data, error}.
"""

# Load-bearing, not boilerplate: the `X | None` annotations below are evaluated
# at import time on Python 3.9, which stock macOS still ships, and raise
# TypeError before main() ever runs. Removing this line makes the script
# unrunnable there.
from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import sys
from datetime import datetime, timezone
from pathlib import Path


def get_desktop_config_path() -> Path:
    """Return the platform-specific path to claude_desktop_config.json."""
    system = platform.system()
    if system == "Darwin":
        return Path.home() / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"
    elif system == "Linux":
        # XDG_CONFIG_HOME or ~/.config
        config_home = os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))
        return Path(config_home) / "Claude" / "claude_desktop_config.json"
    elif system == "Windows":
        appdata = os.environ.get("APPDATA", str(Path.home() / "AppData" / "Roaming"))
        return Path(appdata) / "Claude" / "claude_desktop_config.json"
    else:
        # Fallback — try macOS path
        return Path.home() / "Library" / "Application Support" / "Claude" / "claude_desktop_config.json"


def get_cli_config_path() -> Path:
    """Return the path to Claude Code's user-scope config.

    User scope is the top-level "mcpServers" object in ~/.claude.json. The
    per-project "projects.<abs-path>.mcpServers" objects in the same file are
    local scope and must never be written here — a user-scope server is the
    only shape that survives changing directory.
    """
    return Path.home() / ".claude.json"


def resolve_wrapper_path(server_name: str) -> str | None:
    """Find the installed wrapper script for a git-based MCP server.

    `or`, not a bare default: a bare default fires only on an UNSET override, so an
    empty one resolves to a cwd-relative wrapper that never exists -- and the caller
    below turns an unresolvable wrapper into a git server silently omitted from the
    written config. No trimming, so a whitespace-only override is honoured verbatim.
    The override rule itself is stated canonically in
    skills/workspace-status/references/mcp-registry.md.
    """
    mcp_base = os.environ.get("CLAUDE_MCP_DIR") or str(Path.home() / ".claude" / "mcp-servers")
    wrapper = Path(mcp_base) / server_name / "start.sh"
    if wrapper.exists():
        return str(wrapper)
    return None


def get_platform_key() -> str:
    """Map platform.system() to registry platform keys."""
    return {"Darwin": "darwin", "Linux": "linux", "Windows": "win32"}.get(
        platform.system(), "darwin"
    )


def build_mcp_entry(server: dict, target: str) -> dict | None:
    """Build an mcpServers entry from registry data.

    Returns None if the server type can't be resolved (e.g. git server not installed,
    native server platform not supported).

    The `cli` target adds an explicit "type": "stdio" — that is the only shape
    difference between the two targets, which is why both share this builder
    rather than drifting apart in two writers.
    """
    server_type = server.get("type", "git")

    if server_type == "git":
        wrapper_path = resolve_wrapper_path(server["name"])
        if not wrapper_path:
            return None
        entry = {
            "command": "bash",
            "args": [wrapper_path],
        }
    elif server_type == "native":
        plat = get_platform_key()
        platform_config = server.get("platforms", {}).get(plat)
        if not platform_config:
            return None
        command = platform_config["command"]
        # Skip if the binary doesn't exist at the expected path
        if os.path.isabs(command) and not os.path.exists(command):
            return None
        entry = {
            "command": command,
            "args": platform_config.get("args", []),
        }
    else:
        return None

    entry["env"] = dict(server.get("env", {}))
    if target == "cli":
        # Claude Code records the transport explicitly; Desktop infers it.
        return {"type": "stdio", **entry}
    return entry


def result_json(success: bool, **data) -> str:
    """Emit the repo-standard {success, data, error} envelope.

    `error` is lifted out of the keyword data to the top level, matching the
    other seven .py scripts in this directory and the repo CLAUDE.md contract.
    """
    error = data.pop("error", "")
    return json.dumps({"success": success, "data": data, "error": error}, indent=2)


def patch_target(target: str, config_path: Path, servers: dict, *,
                 force: bool, dry_run: bool) -> dict:
    """Merge `servers` into one target's config, returning a per-target result.

    Read-modify-write: only mcpServers[<config_key>] is touched and every other
    key in the file is preserved verbatim. That matters most for the cli target
    — ~/.claude.json holds unrelated user state (project history, onboarding
    flags), so rebuilding it from scratch would destroy data the user owns.

    Raises ValueError if the target's config file is present but unparseable.
    """
    if config_path.exists():
        try:
            with open(config_path) as f:
                config = json.load(f)
        except json.JSONDecodeError:
            raise ValueError(f"Invalid JSON in {config_path}")
    else:
        config = {}

    if "mcpServers" not in config:
        config["mcpServers"] = {}

    existing_servers = config["mcpServers"]
    actions = []

    for name, server in servers.items():
        config_key = server.get("desktop_config_key", name)

        already_exists = config_key in existing_servers
        if already_exists and not force:
            actions.append({"server": name, "action": "skipped", "reason": "already configured"})
            continue

        entry = build_mcp_entry(server, target)
        if entry is None:
            server_type = server.get("type", "git")
            reason = "not installed" if server_type == "git" else "binary not found on this platform"
            actions.append({"server": name, "action": "skipped", "reason": reason})
            continue

        existing_servers[config_key] = entry
        action_verb = "updated" if already_exists else "added"
        actions.append({"server": name, "action": action_verb, "config_key": config_key})

    # Check if anything changed
    additions = [a for a in actions if a["action"] in ("added", "updated")]
    if not additions:
        return {"action": "noop", "actions": actions,
                "message": "No changes needed", "config_path": str(config_path)}

    if dry_run:
        return {"action": "dry_run", "actions": actions,
                "config_path": str(config_path), "preview": config["mcpServers"]}

    # Create backup before writing
    if config_path.exists():
        backup_path = config_path.with_suffix(
            f".backup-{datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')}.json"
        )
        shutil.copy2(config_path, backup_path)
        backup_str = str(backup_path)
    else:
        config_path.parent.mkdir(parents=True, exist_ok=True)
        backup_str = None

    # Write updated config
    with open(config_path, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")

    return {"action": "patched", "actions": actions,
            "config_path": str(config_path), "backup": backup_str}


def main():
    parser = argparse.ArgumentParser(description="Patch a user's MCP config with git-installed MCP servers")
    parser.add_argument("--registry", required=True, help="Path to mcp-git-registry.json")
    parser.add_argument("--target", choices=("desktop", "cli", "both"), default="desktop",
                        help="Which config to write: Claude Desktop, the Claude Code CLI user config, or both")
    parser.add_argument("--server", action="append", dest="server_filter", metavar="NAME",
                        help="Only write this registry server (repeatable); default is every server")
    parser.add_argument("--dry-run", action="store_true", help="Show what would change without writing")
    parser.add_argument("--force", action="store_true", help="Overwrite existing entries")
    parser.add_argument("--config-path", help="Override auto-detected Desktop config path (for testing)")
    parser.add_argument("--cli-config-path", help="Override auto-detected CLI config path (for testing)")
    args = parser.parse_args()

    # Load registry
    try:
        with open(args.registry) as f:
            registry = json.load(f)
    except (FileNotFoundError, json.JSONDecodeError) as e:
        print(result_json(False, error=f"Cannot read registry: {e}"))
        sys.exit(1)

    servers = registry.get("servers", {})
    if not servers:
        print(result_json(True, action="noop", message="No servers in registry"))
        return

    if args.server_filter:
        unknown = [n for n in args.server_filter if n not in servers]
        if unknown:
            print(result_json(False, error=f"Unknown server(s) in registry: {', '.join(unknown)}"))
            sys.exit(1)
        servers = {n: servers[n] for n in args.server_filter}

    targets = ("desktop", "cli") if args.target == "both" else (args.target,)
    results = []
    for target in targets:
        if target == "desktop":
            path = Path(args.config_path) if args.config_path else get_desktop_config_path()
        else:
            path = Path(args.cli_config_path) if args.cli_config_path else get_cli_config_path()
        try:
            results.append(patch_target(target, path, servers,
                                        force=args.force, dry_run=args.dry_run))
        except ValueError as e:
            print(result_json(False, error=str(e), target=target))
            sys.exit(1)

    if args.target != "both":
        # Single-target runs keep the flat pre---target envelope so existing
        # callers parse the same fields.
        print(result_json(True, **results[0]))
    else:
        # No top-level `action` here: it could only ever restate or contradict
        # the per-target ones (a --dry-run both would read "patched").
        print(result_json(True, targets=[{"target": t, **r}
                                         for t, r in zip(targets, results)]))


if __name__ == "__main__":
    main()

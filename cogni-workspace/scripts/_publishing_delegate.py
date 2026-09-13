#!/usr/bin/env python3
"""_publishing_delegate.py — the one resolver behind cogni-workspace's theme routes.

The theme lifecycle belongs to cogni-publishing. The handful of script paths
that callers outside the move still reach under ``cogni-workspace/scripts/``
are compatibility entry points only; each one calls ``delegate()`` here and
carries no theme logic of its own.

The publishing plugin root is resolved by the ladder the rest of the repo uses
for sibling plugins, testing for the TARGET FILE rather than trusting a
variable, so a half-installed or version-scoped stale directory never wins:

  1. ``$COGNI_PUBLISHING_PLUGIN`` (written by the workspace settings generator)
  2. the monorepo sibling ``<this plugin>/../cogni-publishing``
  3. the newest-installed ``~/.claude/plugins/cache/insight-wave/cogni-publishing/<version>/``

The sibling is tried before the cache so a checkout always exercises its own
code rather than whichever release happens to be installed.

``delegate(name, namespace, script)``:
  * run as a program (``name == "__main__"``) — exec the publishing script with
    the same argv and environment, so its output and exit status are the caller's;
  * imported by path — load the publishing module and copy its public names into
    the caller's namespace, so an ``importlib`` consumer sees the real functions.

When cogni-publishing cannot be found, a program call prints one standard
envelope naming the missing plugin and exits 2; an import raises ImportError.

CLI: ``_publishing_delegate.py --print-root [--sentinel <relative path>]`` prints
the resolved root (exit 0) or the missing-plugin envelope (exit 2).
"""

import importlib.util
import json
import os
import sys


PLUGIN = "cogni-publishing"
ENV_VAR = "COGNI_PUBLISHING_PLUGIN"
INSTALL_HINT = (
    "cogni-publishing is not installed. The theme lifecycle moved there from "
    "cogni-workspace; install cogni-publishing from the insight-wave marketplace "
    "and retry. Existing user themes stay where they are."
)


def resolve_root(sentinel):
    """Return the cogni-publishing root that holds ``sentinel``, or None."""
    explicit = os.environ.get(ENV_VAR, "")
    if explicit and os.path.isfile(os.path.join(explicit, sentinel)):
        return explicit

    here = os.path.dirname(os.path.abspath(__file__))
    sibling = os.path.join(os.path.dirname(os.path.dirname(here)), PLUGIN)
    if os.path.isfile(os.path.join(sibling, sentinel)):
        return sibling

    cache = os.path.join(os.path.expanduser("~"), ".claude", "plugins", "cache", "insight-wave", PLUGIN)
    try:
        versions = [os.path.join(cache, v) for v in os.listdir(cache)]
    except OSError:
        versions = []
    # Newest install first: mtime, not name — a lexical sort ranks 0.0.9 above 0.0.10.
    for cand in sorted(versions, key=lambda p: os.stat(p).st_mtime, reverse=True):
        if os.path.isfile(os.path.join(cand, sentinel)):
            return cand
    return None


def _missing(script):
    print(json.dumps({"success": False,
                      "data": {"missing_plugin": PLUGIN, "script": script},
                      "error": INSTALL_HINT}))
    sys.exit(2)


def delegate(name, namespace, script):
    """Hand one theme entry point over to its cogni-publishing implementation."""
    sentinel = os.path.join("scripts", script)
    root = resolve_root(sentinel)
    if root is None:
        if name == "__main__":
            _missing(script)
        raise ImportError(INSTALL_HINT)
    target = os.path.join(root, sentinel)
    if name == "__main__":
        os.execv(sys.executable, [sys.executable, target] + sys.argv[1:])
    spec = importlib.util.spec_from_file_location("_publishing_" + script.replace("-", "_")[:-3], target)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for key, value in vars(module).items():
        if not key.startswith("__"):
            namespace[key] = value


if __name__ == "__main__":
    args = sys.argv[1:]
    if not args or args[0] != "--print-root":
        print("usage: _publishing_delegate.py --print-root [--sentinel <relative path>]", file=sys.stderr)
        sys.exit(2)
    rel = args[2] if len(args) >= 3 and args[1] == "--sentinel" else os.path.join("scripts", "discover-themes.py")
    found = resolve_root(rel)
    if found is None:
        _missing(rel)
    print(found)

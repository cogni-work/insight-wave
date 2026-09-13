#!/usr/bin/env python3
"""Compatibility route — the implementation is cogni-publishing/scripts/discover-themes.py.

The theme lifecycle belongs to cogni-publishing. This entry point only keeps an
existing caller's path working; _publishing_delegate.py resolves the plugin and
hands the call over unchanged. Add no logic here.
"""
import importlib.util
import os

_spec = importlib.util.spec_from_file_location(
    "_publishing_delegate", os.path.join(os.path.dirname(os.path.abspath(__file__)), "_publishing_delegate.py"))
_delegate = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_delegate)
_delegate.delegate(__name__, globals(), "discover-themes.py")

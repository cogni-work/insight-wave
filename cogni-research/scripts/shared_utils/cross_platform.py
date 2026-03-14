#!/usr/bin/env python3
"""
cross_platform.py
Version: 1.0.0
Purpose: Cross-platform utilities for Claude Code plugin scripts

This module provides miscellaneous utilities that work identically across
macOS, Linux, and Windows without platform-specific code.

Includes:
    - UUID generation (deterministic and random)
    - URL normalization
    - YAML frontmatter handling
    - Environment variable access
    - Process utilities
    - String utilities

Usage:
    from cross_platform import generate_uuid, normalize_url, parse_frontmatter
"""

import hashlib
import os
import re
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple, Union
from urllib.parse import urlparse, urlunparse


def generate_uuid(deterministic_content: Optional[str] = None) -> str:
    """
    Generate a UUID.

    Args:
        deterministic_content: If provided, generates UUID from content hash
                               (same content = same UUID). If None, generates
                               random UUID.

    Returns:
        UUID string (lowercase, without dashes for consistency)

    Example:
        # Random UUID
        uid = generate_uuid()  # e.g., "a1b2c3d4e5f6..."

        # Deterministic UUID (same input = same output)
        uid = generate_uuid("my content")  # Always same result
    """
    if deterministic_content is not None:
        # Create deterministic UUID from content hash
        content_hash = hashlib.sha256(deterministic_content.encode("utf-8")).hexdigest()
        return content_hash[:32]  # Use first 32 hex chars as UUID
    else:
        # Random UUID
        return uuid.uuid4().hex


def normalize_url(url: str) -> str:
    """
    Normalize URL for deduplication.

    Normalizations applied:
        - Lowercase scheme and host
        - Remove trailing slashes
        - Remove common tracking parameters (utm_*, fbclid, etc.)
        - Remove fragment identifiers (#...)
        - Sort query parameters for consistency

    Args:
        url: URL to normalize

    Returns:
        Normalized URL string

    Example:
        normalize_url("HTTPS://Example.COM/path/?utm_source=x&b=2&a=1")
        # Returns: "https://example.com/path?a=1&b=2"
    """
    if not url:
        return ""

    # Parse URL
    parsed = urlparse(url.strip())

    # Lowercase scheme and host
    scheme = parsed.scheme.lower()
    netloc = parsed.netloc.lower()

    # Remove trailing slash from path (unless it's just "/")
    path = parsed.path.rstrip("/") if parsed.path != "/" else parsed.path

    # Parse and filter query parameters
    tracking_params = {
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content",
        "fbclid", "gclid", "msclkid", "ref", "source", "mc_cid", "mc_eid"
    }

    if parsed.query:
        params = []
        for param in parsed.query.split("&"):
            if "=" in param:
                key, value = param.split("=", 1)
                if key.lower() not in tracking_params:
                    params.append((key, value))
            else:
                params.append((param, ""))

        # Sort parameters for consistency
        params.sort(key=lambda x: x[0].lower())
        query = "&".join(f"{k}={v}" if v else k for k, v in params)
    else:
        query = ""

    # Reconstruct URL (without fragment)
    return urlunparse((scheme, netloc, path, "", query, ""))


def extract_domain(url: str) -> str:
    """
    Extract domain from URL.

    Args:
        url: URL to extract domain from

    Returns:
        Domain string (e.g., "example.com")

    Example:
        extract_domain("https://www.example.com/path")
        # Returns: "www.example.com"
    """
    if not url:
        return ""

    parsed = urlparse(url.strip())
    return parsed.netloc.lower()


def now_iso() -> str:
    """
    Get current timestamp as ISO 8601 string in UTC.

    Returns:
        ISO 8601 timestamp (e.g., "2024-01-15T10:30:00Z")
    """
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def now_date() -> str:
    """
    Get current date as ISO string.

    Returns:
        Date string (e.g., "2024-01-15")
    """
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


def parse_frontmatter(content: str) -> Tuple[Dict[str, Any], str]:
    """
    Parse YAML frontmatter from markdown content.

    Args:
        content: Markdown content with optional frontmatter

    Returns:
        Tuple of (frontmatter_dict, body_content)

    Example:
        fm, body = parse_frontmatter('''---
        title: Hello
        ---
        # Content here
        ''')
        # fm = {"title": "Hello"}
        # body = "# Content here"
    """
    import json

    content = content.strip()

    if not content.startswith("---"):
        return {}, content

    # Find closing ---
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_text = parts[1].strip()
    body = parts[2].strip()

    # Parse YAML (simple key: value parsing without external deps)
    frontmatter: Dict[str, Any] = {}
    for line in frontmatter_text.split("\n"):
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if ":" in line:
            key, value = line.split(":", 1)
            key = key.strip()
            value = value.strip()

            # Handle quoted strings
            if (value.startswith('"') and value.endswith('"')) or \
               (value.startswith("'") and value.endswith("'")):
                value = value[1:-1]

            # Handle wikilinks
            elif value.startswith("[[") and value.endswith("]]"):
                pass  # Keep as-is

            # Handle booleans
            elif value.lower() in ("true", "yes"):
                value = True
            elif value.lower() in ("false", "no"):
                value = False

            # Handle numbers
            elif value.isdigit():
                value = int(value)
            elif re.match(r"^-?\d+\.\d+$", value):
                value = float(value)

            # Handle null
            elif value.lower() in ("null", "~", ""):
                value = None

            frontmatter[key] = value

    return frontmatter, body


def format_frontmatter(data: Dict[str, Any]) -> str:
    """
    Format dictionary as YAML frontmatter.

    Handles special cases:
        - Strings with colons are quoted
        - Wikilinks are preserved
        - Booleans lowercase
        - None becomes empty

    Args:
        data: Dictionary to format

    Returns:
        YAML frontmatter string (without --- delimiters)
    """
    lines = []

    for key, value in data.items():
        if value is None:
            lines.append(f"{key}:")
        elif isinstance(value, bool):
            lines.append(f"{key}: {str(value).lower()}")
        elif isinstance(value, (int, float)):
            lines.append(f"{key}: {value}")
        elif isinstance(value, str):
            # Quote strings containing special characters
            needs_quote = (
                ":" in value or
                value.startswith("[") or
                value.startswith("{") or
                value.startswith("'") or
                value.startswith('"') or
                value.startswith("&") or
                value.startswith("*") or
                value.startswith("!") or
                value.startswith("|") or
                value.startswith(">") or
                value.startswith("%") or
                value.startswith("@") or
                value.startswith("`") or
                "\n" in value
            )
            # Exception: don't quote wikilinks
            if value.startswith("[[") and value.endswith("]]"):
                needs_quote = False

            if needs_quote:
                # Escape quotes in value and wrap
                escaped = value.replace('"', '\\"')
                lines.append(f'{key}: "{escaped}"')
            else:
                lines.append(f"{key}: {value}")
        elif isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                lines.append(f"  - {item}")
        elif isinstance(value, dict):
            lines.append(f"{key}:")
            for k, v in value.items():
                lines.append(f"  {k}: {v}")

    return "\n".join(lines)


def env_get(name: str, default: Optional[str] = None) -> Optional[str]:
    """
    Get environment variable value.

    Args:
        name: Variable name
        default: Default value if not set

    Returns:
        Variable value or default
    """
    return os.environ.get(name, default)


def env_bool(name: str, default: bool = False) -> bool:
    """
    Get environment variable as boolean.

    Treats "true", "1", "yes" (case-insensitive) as True.

    Args:
        name: Variable name
        default: Default value if not set

    Returns:
        Boolean value
    """
    value = os.environ.get(name, "").lower()
    if not value:
        return default
    return value in ("true", "1", "yes", "on")


def slugify(text: str, max_length: int = 50) -> str:
    """
    Convert text to URL-safe slug.

    Args:
        text: Text to slugify
        max_length: Maximum length of result

    Returns:
        Slugified string

    Example:
        slugify("Hello World! This is a Test")
        # Returns: "hello-world-this-is-a-test"
    """
    # Lowercase
    slug = text.lower()

    # Replace non-alphanumeric with hyphens
    slug = re.sub(r"[^a-z0-9]+", "-", slug)

    # Remove leading/trailing hyphens
    slug = slug.strip("-")

    # Collapse multiple hyphens
    slug = re.sub(r"-+", "-", slug)

    # Truncate
    if len(slug) > max_length:
        slug = slug[:max_length].rstrip("-")

    return slug


def truncate(text: str, max_length: int, suffix: str = "...") -> str:
    """
    Truncate text to max length with suffix.

    Args:
        text: Text to truncate
        max_length: Maximum length including suffix
        suffix: Suffix to add when truncated

    Returns:
        Truncated string
    """
    if len(text) <= max_length:
        return text
    return text[: max_length - len(suffix)] + suffix


def plugin_root() -> Optional[Path]:
    """
    Get CLAUDE_PLUGIN_ROOT as Path.

    Returns:
        Path to plugin root, or None if not set
    """
    root = os.environ.get("CLAUDE_PLUGIN_ROOT")
    return Path(root) if root else None


def cogni_research_root() -> Optional[Path]:
    """
    Get COGNI_RESEARCH_ROOT as Path.

    Returns:
        Path to cogni-research root, or None if not set
    """
    root = os.environ.get("COGNI_RESEARCH_ROOT")
    return Path(root) if root else None


def parse_yaml_nested(yaml_text: str) -> Dict[str, Any]:
    """
    Parse YAML text into a dictionary, supporting nested structures.

    This parser handles:
        - Key: value pairs
        - Nested objects (indented keys)
        - Lists (- item syntax)
        - Quoted strings
        - Booleans, numbers, null
        - Multi-line strings (basic support)

    Args:
        yaml_text: YAML text to parse

    Returns:
        Parsed dictionary

    Raises:
        ValueError: If YAML is malformed

    Example:
        data = parse_yaml_nested('''
        name: test
        content:
          summary: "A summary"
          items:
            - first
            - second
        ''')
    """
    # Try PyYAML first if available (more robust)
    try:
        import yaml
        return yaml.safe_load(yaml_text) or {}
    except ImportError:
        pass  # Fall back to custom parser

    def parse_value(val: str) -> Any:
        """Parse a YAML scalar value."""
        val = val.strip()

        # Empty value
        if not val:
            return None

        # Quoted string
        if (val.startswith('"') and val.endswith('"')) or \
           (val.startswith("'") and val.endswith("'")):
            return val[1:-1]

        # Boolean
        if val.lower() in ("true", "yes", "on"):
            return True
        if val.lower() in ("false", "no", "off"):
            return False

        # Null
        if val.lower() in ("null", "~"):
            return None

        # Number
        try:
            if "." in val:
                return float(val)
            return int(val)
        except ValueError:
            pass

        # Inline list [a, b, c]
        if val.startswith("[") and val.endswith("]"):
            inner = val[1:-1].strip()
            if not inner:
                return []
            # Simple comma-separated parsing (handles quoted strings)
            items = []
            current = ""
            in_quotes = False
            quote_char = None
            for char in inner:
                if char in ('"', "'") and not in_quotes:
                    in_quotes = True
                    quote_char = char
                    current += char
                elif char == quote_char and in_quotes:
                    in_quotes = False
                    quote_char = None
                    current += char
                elif char == "," and not in_quotes:
                    items.append(parse_value(current.strip()))
                    current = ""
                else:
                    current += char
            if current.strip():
                items.append(parse_value(current.strip()))
            return items

        # Inline dict {a: 1, b: 2}
        if val.startswith("{") and val.endswith("}"):
            inner = val[1:-1].strip()
            if not inner:
                return {}
            obj: Dict[str, Any] = {}
            for pair in inner.split(","):
                if ":" in pair:
                    k, v = pair.split(":", 1)
                    obj[k.strip()] = parse_value(v.strip())
            return obj

        # Regular string
        return val

    def get_indent(line: str) -> int:
        """Get indentation level (number of leading spaces)."""
        return len(line) - len(line.lstrip())

    lines = yaml_text.split("\n")
    result: Dict[str, Any] = {}

    # Stack: list of (indent_level, container, current_key_for_list)
    # container is either a dict or list
    # indent_level is the indent at which this container's children appear
    stack: List[Tuple[int, Any, Optional[str]]] = [(-1, result, None)]

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        # Skip empty lines and comments
        if not stripped or stripped.startswith("#"):
            i += 1
            continue

        indent = get_indent(line)

        # Pop stack to find correct parent for this indent level
        # Pop if current indent is less than the indent level where children would be
        while len(stack) > 1 and indent < stack[-1][0]:
            stack.pop()

        _, container, list_key = stack[-1]

        # Handle list item
        if stripped.startswith("- "):
            item_value = stripped[2:].strip()

            # Determine which list to add to
            if isinstance(container, list):
                target_list = container
            elif list_key and list_key in container and isinstance(container[list_key], list):
                target_list = container[list_key]
            else:
                # This shouldn't happen with well-formed YAML
                i += 1
                continue

            # Check if this is "- key: value" (dict item) or simple "- value"
            if ":" in item_value and not item_value.startswith('"'):
                # Could be "- key: value" or start of nested object
                key, val = item_value.split(":", 1)
                key = key.strip()
                val = val.strip()

                if val:
                    # Simple "- key: value"
                    target_list.append({key: parse_value(val)})
                else:
                    # "- key:" - starts a nested structure
                    # Peek ahead to see what follows
                    next_i = i + 1
                    while next_i < len(lines) and not lines[next_i].strip():
                        next_i += 1

                    if next_i < len(lines):
                        next_indent = get_indent(lines[next_i])
                        next_stripped = lines[next_i].strip()
                        if next_stripped.startswith("- "):
                            new_list: List[Any] = []
                            target_list.append({key: new_list})
                            stack.append((next_indent, new_list, None))
                        else:
                            new_dict: Dict[str, Any] = {}
                            target_list.append({key: new_dict})
                            stack.append((next_indent, new_dict, None))
                    else:
                        target_list.append({key: None})
            else:
                # Simple list item "- value"
                target_list.append(parse_value(item_value))

        # Handle key: value
        elif ":" in stripped:
            if not isinstance(container, dict):
                i += 1
                continue

            key, val = stripped.split(":", 1)
            key = key.strip()
            val = val.strip()

            if val:
                # Key with immediate value
                container[key] = parse_value(val)
            else:
                # Key with nested content (dict or list)
                # Peek at next non-empty line to determine type and indent
                next_i = i + 1
                while next_i < len(lines) and not lines[next_i].strip():
                    next_i += 1

                if next_i < len(lines):
                    next_indent = get_indent(lines[next_i])
                    next_stripped = lines[next_i].strip()
                    if next_stripped.startswith("- "):
                        container[key] = []
                        # For lists, the list items appear at next_indent
                        stack.append((next_indent, container, key))
                    else:
                        container[key] = {}
                        # Children of this dict appear at next_indent
                        stack.append((next_indent, container[key], None))
                else:
                    container[key] = None

        i += 1

    return result


def fix_json_braces(raw_data: str) -> tuple:
    """
    Attempt to fix common JSON brace mismatches.

    Handles the common LLM error of adding extra closing braces at the end
    of JSON structures, e.g., {"key": "value"}} instead of {"key": "value"}.

    Args:
        raw_data: Raw JSON string that may have brace mismatches

    Returns:
        Tuple of (potentially_fixed_data, was_fixed)

    Example:
        fixed, was_fixed = fix_json_braces('{"key": "value"}}')
        # fixed = '{"key": "value"}', was_fixed = True
    """
    # Count opening and closing braces
    open_braces = raw_data.count("{")
    close_braces = raw_data.count("}")

    if open_braces == close_braces:
        return raw_data, False

    # More closing than opening - try to fix by removing trailing excess
    if close_braces > open_braces:
        excess = close_braces - open_braces
        # Remove trailing excess braces (common LLM error)
        fixed = raw_data.rstrip()
        while excess > 0 and fixed.endswith("}"):
            # Check if removing this brace would balance the structure
            test = fixed[:-1]
            if test.count("{") == test.count("}"):
                fixed = test
                excess -= 1
            else:
                break
        if fixed != raw_data:
            return fixed, True

    return raw_data, False


def parse_data_auto(raw_data: str) -> Dict[str, Any]:
    """
    Auto-detect format (JSON or YAML) and parse data.

    Tries JSON first (fast path), then falls back to YAML.
    Includes auto-repair for common JSON issues like extra closing braces.

    Args:
        raw_data: Raw data string (JSON or YAML)

    Returns:
        Parsed dictionary

    Raises:
        ValueError: If data cannot be parsed as JSON or YAML

    Example:
        # Works with JSON
        data = parse_data_auto('{"key": "value"}')

        # Works with YAML
        data = parse_data_auto('key: value')

        # Auto-fixes common LLM errors
        data = parse_data_auto('{"key": "value"}}')  # extra brace is fixed
    """
    import json
    import sys

    raw_data = raw_data.strip()

    if not raw_data:
        raise ValueError("Empty data")

    json_error = None

    # Try JSON first (fast path)
    try:
        return json.loads(raw_data)
    except json.JSONDecodeError as je:
        json_error = f"line {je.lineno}, col {je.colno}: {je.msg}"

        # Attempt auto-fix for brace mismatch (common LLM error)
        fixed_data, was_fixed = fix_json_braces(raw_data)
        if was_fixed:
            try:
                result = json.loads(fixed_data)
                # Log that we auto-fixed (helps debugging)
                print("[WARN] Auto-fixed JSON brace mismatch", file=sys.stderr)
                return result
            except json.JSONDecodeError:
                pass  # Auto-fix didn't help, continue to YAML

    # Try YAML
    try:
        return parse_yaml_nested(raw_data)
    except Exception as e:
        # Provide detailed error with JSON error info
        raise ValueError(
            f"Failed to parse as JSON or YAML. JSON error at {json_error}. YAML error: {e}"
        ) from e

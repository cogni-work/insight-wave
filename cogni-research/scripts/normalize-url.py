#!/usr/bin/env python3
"""
normalize-url.py
Version: 2.0.0 (Python migration)
Purpose: Normalize URLs to canonical form for robust deduplication in deeper-research pipeline
Category: utilities

Usage:
    normalize-url.py --url <string> [--strip-query] [--json]

Arguments:
    --url <string>       URL to normalize (required)
    --strip-query        Remove query parameters (optional, default: false)
    --json               Return JSON response (optional, default: text mode)

Output (JSON mode):
    {
        "success": boolean,
        "data": {
            "original_url": "input URL",
            "normalized_url": "canonical form",
            "transformations_applied": ["transformation1", "transformation2"]
        },
        "error": "error message" (if success=false)
    }

Output (text mode):
    https://example.com/path

Normalization Rules:
    1. Strip www. prefix (www.example.com -> example.com)
    2. Convert to lowercase (EXAMPLE.COM -> example.com)
    3. Remove trailing slashes (url/ -> url)
    4. Standardize protocol (http:// -> https://)
    5. Remove fragments (#anchors)
    6. Optionally remove query parameters if --strip-query provided

Exit codes:
    0 - Success
    2 - Invalid arguments or URL format

Example:
    normalize-url.py --url "https://WWW.Example.com/Path/?query=1#anchor" --strip-query --json
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import List, Tuple
from urllib.parse import urlparse, urlunparse

# Add shared utils to path - prefer bundled version for plugin cache compatibility
SCRIPT_DIR = Path(__file__).resolve().parent
BUNDLED_UTILS = SCRIPT_DIR / "shared_utils"
if BUNDLED_UTILS.is_dir():
    # Use bundled shared_utils (works in plugin cache)
    sys.path.insert(0, str(BUNDLED_UTILS))
else:
    # Fall back to monorepo location (development mode)
    REPO_ROOT = SCRIPT_DIR.parent.parent
    SHARED_UTILS = REPO_ROOT / "cogni-workplace" / "python"
    sys.path.insert(0, str(SHARED_UTILS))


def error_json(message: str, code: int = 1) -> None:
    """Output error in JSON format and exit."""
    result = {"success": False, "error": message, "error_code": code}
    print(json.dumps(result), file=sys.stderr)
    sys.exit(code)


def normalize_url_with_tracking(
    url: str,
    strip_query: bool = False
) -> Tuple[str, List[str]]:
    """Normalize URL and track transformations applied.

    Args:
        url: URL to normalize
        strip_query: Remove query parameters

    Returns:
        Tuple of (normalized_url, list of transformations applied)
    """
    transformations = []
    original_url = url

    # Step 1: Add https:// if no protocol present
    if not re.match(r"^https?://", url, re.IGNORECASE):
        url = f"https://{url}"
        transformations.append("added_protocol")

    # Step 2: Standardize protocol (http -> https)
    if url.lower().startswith("http://"):
        url = "https://" + url[7:]
        transformations.append("standardized_protocol")

    # Parse URL
    parsed = urlparse(url)

    # Step 3: Extract components
    scheme = "https"
    netloc = parsed.netloc
    path = parsed.path
    query = parsed.query

    # Step 4: Remove fragment (#anchor)
    if parsed.fragment:
        transformations.append("removed_fragment")

    # Step 5: Optionally remove query parameters
    if strip_query and query:
        query = ""
        transformations.append("removed_query")

    # Step 6: Convert to lowercase
    netloc_lower = netloc.lower()
    if netloc_lower != netloc:
        transformations.append("lowercase")
    netloc = netloc_lower

    # Step 7: Strip www. prefix
    if netloc.startswith("www."):
        netloc = netloc[4:]
        transformations.append("removed_www")

    # Step 8: Remove trailing slash (but not for path-only or root)
    if path.endswith("/") and len(path) > 1:
        path = path.rstrip("/")
        transformations.append("removed_trailing_slash")

    # Reconstruct URL
    normalized = urlunparse((scheme, netloc, path, "", query, ""))

    return normalized, transformations


def parse_args() -> argparse.Namespace:
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Normalize URLs to canonical form",
        add_help=False,
    )
    parser.add_argument("--url", required=True, help="URL to normalize")
    parser.add_argument(
        "--strip-query",
        action="store_true",
        help="Remove query parameters",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output JSON format",
    )

    # Handle unknown arguments gracefully
    args, _ = parser.parse_known_args()
    return args


def main() -> None:
    """Main entry point."""
    args = parse_args()

    # Validate URL
    if not args.url:
        error_json("Usage: normalize-url.py --url <string> [--strip-query] [--json]", 2)

    # Basic URL format validation
    url_pattern = r"^https?://|^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}"
    if not re.match(url_pattern, args.url, re.IGNORECASE):
        error_json(f"Invalid URL format: {args.url}", 2)

    # Normalize URL
    normalized, transformations = normalize_url_with_tracking(
        args.url,
        args.strip_query,
    )

    # Output based on mode
    if args.json:
        result = {
            "success": True,
            "data": {
                "original_url": args.url,
                "normalized_url": normalized,
                "transformations_applied": transformations,
            },
        }
        print(json.dumps(result))
    else:
        # Text mode - just output normalized URL
        print(normalized)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Rasterize an SVG file to PNG for embedding in a Pencil MCP canvas.

Used by the render-infographic-pencil agent (Step 2.5) to convert the
one-color line-art SVG produced by the editorial-sketch agent into a
crisp PNG that Pencil can place as a file-backed image in a frame.

Detects the first available rasterizer binary on PATH in this order:
  1. rsvg-convert  (from librsvg — fastest, cleanest output)
  2. cairosvg      (Python CLI — installed via `pip install cairosvg`)
  3. inkscape      (fallback — heavier but always reliable)

If none are available, returns a graceful JSON error with an install
hint so the caller can fall back to a text-block without crashing the
render. This is deliberate — editorial infographics must always ship
a page, even when the sketch pipeline is degraded.

CLI:
  rasterize-sketch.py --svg PATH --out PATH --width N [--dpi N]

Output (always single-line JSON on stdout):
  success: {"ok":true,"png_path":"/abs/out.png","width":600,"height":450,"rasterizer":"rsvg-convert"}
  error:   {"ok":false,"e":"reason","install_hint":"brew install librsvg"}

Exit code: 0 for success, 1 for error. The JSON is authoritative — the
exit code is a convenience for shell pipelines.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path


# Ordered preference — first one found on PATH wins.
RASTERIZER_CANDIDATES = ("rsvg-convert", "cairosvg", "inkscape")

INSTALL_HINTS = {
    "rsvg-convert": "brew install librsvg   # macOS (preferred, ~1MB, fastest)",
    "cairosvg": "pip install cairosvg      # Python (portable)",
    "inkscape": "brew install --cask inkscape   # macOS GUI (heavier fallback)",
}


def emit(payload: dict, exit_code: int = 0) -> None:
    """Print a single-line JSON result and exit with the given code."""
    sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
    sys.stdout.flush()
    sys.exit(exit_code)


def find_rasterizer() -> str | None:
    """Return the name of the first rasterizer binary found on PATH, or None."""
    for name in RASTERIZER_CANDIDATES:
        if shutil.which(name):
            return name
    return None


def run_rsvg_convert(svg: Path, out: Path, width: int, dpi: int) -> subprocess.CompletedProcess:
    """Invoke rsvg-convert. Preserves aspect ratio by supplying width only."""
    cmd = [
        "rsvg-convert",
        "--width", str(width),
        "--keep-aspect-ratio",
        "--dpi-x", str(dpi),
        "--dpi-y", str(dpi),
        "--format", "png",
        "--output", str(out),
        str(svg),
    ]
    return subprocess.run(cmd, capture_output=True, text=True)


def run_cairosvg(svg: Path, out: Path, width: int, dpi: int) -> subprocess.CompletedProcess:
    """Invoke the cairosvg CLI. Installed via `pip install cairosvg`."""
    cmd = [
        "cairosvg",
        str(svg),
        "-o", str(out),
        "--output-width", str(width),
        "--dpi", str(dpi),
    ]
    return subprocess.run(cmd, capture_output=True, text=True)


def run_inkscape(svg: Path, out: Path, width: int, dpi: int) -> subprocess.CompletedProcess:
    """Invoke Inkscape in headless export mode. Inkscape 1.0+ syntax."""
    cmd = [
        "inkscape",
        str(svg),
        "--export-type=png",
        f"--export-filename={out}",
        f"--export-width={width}",
        f"--export-dpi={dpi}",
    ]
    return subprocess.run(cmd, capture_output=True, text=True)


DISPATCH = {
    "rsvg-convert": run_rsvg_convert,
    "cairosvg": run_cairosvg,
    "inkscape": run_inkscape,
}


def png_dimensions(path: Path) -> tuple[int, int] | None:
    """Read PNG width/height from the IHDR chunk without external deps.

    PNG header layout: 8-byte signature, then a 25-byte IHDR chunk whose
    data segment starts at byte 16 with big-endian uint32 width, height.
    """
    try:
        with path.open("rb") as fh:
            header = fh.read(24)
        if len(header) < 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
            return None
        width = int.from_bytes(header[16:20], "big")
        height = int.from_bytes(header[20:24], "big")
        return width, height
    except OSError:
        return None


def main() -> None:
    parser = argparse.ArgumentParser(description="Rasterize an SVG to PNG for Pencil MCP embedding.")
    parser.add_argument("--svg", required=True, help="Absolute path to the source SVG file")
    parser.add_argument("--out", required=True, help="Absolute path to the destination PNG file")
    parser.add_argument("--width", type=int, default=600, help="Target width in px (default 600)")
    parser.add_argument("--dpi", type=int, default=144, help="DPI (default 144, crisp at editorial density)")
    args = parser.parse_args()

    svg_path = Path(args.svg)
    out_path = Path(args.out)

    if not svg_path.is_file():
        emit({"ok": False, "e": f"svg_not_found: {svg_path}"}, 1)

    if args.width <= 0 or args.width > 4000:
        emit({"ok": False, "e": f"width_out_of_range: {args.width} (expected 1..4000)"}, 1)

    rasterizer = find_rasterizer()
    if rasterizer is None:
        # Graceful degradation — the caller should fall back to text-block
        # and record a warning, not crash the render.
        emit(
            {
                "ok": False,
                "e": "no_svg_rasterizer",
                "install_hint": INSTALL_HINTS["rsvg-convert"],
                "alternatives": [
                    INSTALL_HINTS["cairosvg"],
                    INSTALL_HINTS["inkscape"],
                ],
            },
            1,
        )

    # Ensure the output directory exists — the caller may pass a brand-new path.
    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        emit({"ok": False, "e": f"output_dir_not_writable: {exc}"}, 1)

    try:
        result = DISPATCH[rasterizer](svg_path, out_path, args.width, args.dpi)
    except FileNotFoundError as exc:
        # Rare: PATH changed between find_rasterizer() and subprocess.run().
        emit({"ok": False, "e": f"rasterizer_vanished: {exc}"}, 1)

    if result.returncode != 0:
        emit(
            {
                "ok": False,
                "e": f"rasterizer_failed: {rasterizer}",
                "stderr": (result.stderr or "").strip()[:500],
                "returncode": result.returncode,
            },
            1,
        )

    if not out_path.is_file() or out_path.stat().st_size == 0:
        emit({"ok": False, "e": "png_not_written"}, 1)

    dims = png_dimensions(out_path)
    width, height = dims if dims else (args.width, 0)

    emit(
        {
            "ok": True,
            "png_path": str(out_path.resolve()),
            "width": width,
            "height": height,
            "rasterizer": rasterizer,
            "size_bytes": out_path.stat().st_size,
        }
    )


if __name__ == "__main__":
    main()

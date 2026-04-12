#!/usr/bin/env python3
"""Render an accurate country-outline SVG for the editorial-sketch agent.

Loads the bundled Natural Earth 1:110M country outlines (public domain),
selects one or more countries by ISO3 code, projects them with latitude-
corrected equirectangular projection, and emits a one-color outline SVG
that obeys the editorial data-ink discipline:

  - fill="none" on every path
  - stroke uses a single resolved hex color (no second accent)
  - no gradients, no shadows, no rounded flourishes
  - optional city dot markers at real lat/lng positions
  - no text labels inside the SVG (labels live in adjacent Pencil text nodes)

Why this exists: LLMs cannot reliably draw country shapes from prose
descriptions. Iteration-1 proved that with an unusable DACH outline. The
editorial-sketch agent's cartographic path now calls this script first
and only falls back to hand-crafted SVG when the subject is abstract or
invented (e.g., "a stylized territory marker for our five European hubs").

CLI:
  cartographic-outline.py
    --data  /abs/path/to/countries.geo.json
    --out   /abs/path/to/output.svg
    --countries  DEU,AUT,CHE       # one or more ISO3 codes, comma-separated
    --stroke     "#C00000"          # resolved hex (must match --accent-primary)
    --width      480                # target viewBox width in px
    --stroke-width 2.0              # px (1.5..2.5 per editorial discipline)
    --markers    "Munich:11.576,48.137;Berlin:13.405,52.520"
                                    # optional; labels are ignored (markers only)
    --marker-radius 4               # radius of each city dot in px

Output (single-line JSON on stdout):
  success: {"ok":true,"svg_path":"/abs/out.svg","width":480,"height":320,
            "countries":["DEU","AUT","CHE"],"bounds":{"lon_min":..,"lon_max":..,
            "lat_min":..,"lat_max":..},"points_total":142,"markers":2}
  error:   {"ok":false,"e":"reason"}

Exit code: 0 on success, 1 on error. JSON is authoritative.
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path


def emit(payload: dict, exit_code: int = 0) -> None:
    sys.stdout.write(json.dumps(payload, separators=(",", ":")) + "\n")
    sys.stdout.flush()
    sys.exit(exit_code)


def load_features(data_path: Path) -> dict:
    """Return {iso3: feature} index from the bundled GeoJSON FeatureCollection."""
    try:
        with data_path.open() as fh:
            doc = json.load(fh)
    except FileNotFoundError:
        emit({"ok": False, "e": f"data_not_found: {data_path}"}, 1)
    except json.JSONDecodeError as exc:
        emit({"ok": False, "e": f"data_parse_error: {exc}"}, 1)
    if doc.get("type") != "FeatureCollection":
        emit({"ok": False, "e": "data_not_feature_collection"}, 1)
    return {feat["id"]: feat for feat in doc["features"] if "id" in feat}


def iter_rings(geometry: dict):
    """Yield (lon, lat) rings for Polygon and MultiPolygon geometries."""
    kind = geometry.get("type")
    coords = geometry.get("coordinates", [])
    if kind == "Polygon":
        for ring in coords:
            yield ring
    elif kind == "MultiPolygon":
        for polygon in coords:
            for ring in polygon:
                yield ring


def compute_bounds(rings: list[list[list[float]]]) -> tuple[float, float, float, float]:
    lon_min = min(pt[0] for ring in rings for pt in ring)
    lon_max = max(pt[0] for ring in rings for pt in ring)
    lat_min = min(pt[1] for ring in rings for pt in ring)
    lat_max = max(pt[1] for ring in rings for pt in ring)
    return lon_min, lon_max, lat_min, lat_max


def project_and_scale(
    rings: list[list[list[float]]],
    bounds: tuple[float, float, float, float],
    target_width: float,
    padding: float,
) -> tuple[list[list[tuple[float, float]]], float, float]:
    """Equirectangular projection with latitude-cosine correction.

    At mid-latitudes (the target audience for editorial infographics — DACH,
    Europe, USA), the plate carrée projection stretches horizontally. We
    apply cos(central_lat) to the x axis so the outlines read at the right
    proportion without introducing a heavier projection dependency.
    """
    lon_min, lon_max, lat_min, lat_max = bounds
    central_lat = (lat_min + lat_max) / 2.0
    cos_lat = math.cos(math.radians(central_lat))

    # Raw projected extents (before scale).
    x_min = lon_min * cos_lat
    x_max = lon_max * cos_lat
    # SVG y grows downward — invert latitude.
    y_min = -lat_max
    y_max = -lat_min

    raw_w = x_max - x_min
    raw_h = y_max - y_min
    if raw_w <= 0 or raw_h <= 0:
        emit({"ok": False, "e": "degenerate_bounds"}, 1)

    usable_w = target_width - 2 * padding
    scale = usable_w / raw_w
    target_height = raw_h * scale + 2 * padding

    def to_svg(pt):
        lon, lat = pt
        x = (lon * cos_lat - x_min) * scale + padding
        y = (-lat - y_min) * scale + padding
        return round(x, 2), round(y, 2)

    projected = [[to_svg(pt) for pt in ring] for ring in rings]
    return projected, target_width, target_height


def project_marker(
    lon: float,
    lat: float,
    bounds: tuple[float, float, float, float],
    target_width: float,
    target_height: float,
    padding: float,
) -> tuple[float, float]:
    """Project a single marker using the same math as project_and_scale."""
    lon_min, lon_max, lat_min, lat_max = bounds
    central_lat = (lat_min + lat_max) / 2.0
    cos_lat = math.cos(math.radians(central_lat))
    x_min = lon_min * cos_lat
    y_min = -lat_max
    raw_w = lon_max * cos_lat - x_min
    scale = (target_width - 2 * padding) / raw_w
    x = (lon * cos_lat - x_min) * scale + padding
    y = (-lat - y_min) * scale + padding
    return round(x, 2), round(y, 2)


def ring_to_path(ring: list[tuple[float, float]]) -> str:
    """Convert a projected ring to an SVG path string (M..L..Z)."""
    if not ring:
        return ""
    head = f"M {ring[0][0]} {ring[0][1]}"
    tail = " ".join(f"L {x} {y}" for x, y in ring[1:])
    return f"{head} {tail} Z".strip()


def parse_markers(raw: str | None) -> list[tuple[str, float, float]]:
    """Parse "label:lon,lat;label2:lon2,lat2" into [(label, lon, lat), ...]."""
    if not raw:
        return []
    out = []
    for chunk in raw.split(";"):
        chunk = chunk.strip()
        if not chunk:
            continue
        label, _, coords = chunk.partition(":")
        if not coords:
            emit({"ok": False, "e": f"marker_missing_coords: {chunk}"}, 1)
        try:
            lon_str, lat_str = coords.split(",")
            lon = float(lon_str)
            lat = float(lat_str)
        except ValueError:
            emit({"ok": False, "e": f"marker_parse_error: {chunk}"}, 1)
        out.append((label.strip(), lon, lat))
    return out


def build_svg(
    projected_rings: list[list[tuple[float, float]]],
    width: float,
    height: float,
    stroke: str,
    stroke_width: float,
    marker_points: list[tuple[float, float]],
    marker_radius: float,
    country_groups: dict[str, list[int]],
) -> str:
    """Compose the SVG string. Ring indices inside country_groups let us
    emit a <g id="iso3"> per country so the file is inspectable."""
    lines: list[str] = []
    lines.append(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {width} {height:.0f}" '
        f'width="{width:.0f}" height="{height:.0f}">'
    )
    for iso3, ring_indices in country_groups.items():
        lines.append(f'  <g id="{iso3}" fill="none" stroke="{stroke}" stroke-width="{stroke_width}" stroke-linejoin="round" stroke-linecap="round">')
        for idx in ring_indices:
            ring = projected_rings[idx]
            if not ring:
                continue
            lines.append(f'    <path d="{ring_to_path(ring)}" />')
        lines.append("  </g>")
    if marker_points:
        lines.append(
            f'  <g id="markers" fill="{stroke}" stroke="{stroke}" stroke-width="{stroke_width}">'
        )
        for mx, my in marker_points:
            lines.append(f'    <circle cx="{mx}" cy="{my}" r="{marker_radius}" />')
        lines.append("  </g>")
    lines.append("</svg>")
    return "\n".join(lines) + "\n"


def main() -> None:
    parser = argparse.ArgumentParser(description="Render an accurate country-outline SVG.")
    parser.add_argument("--data", required=True, help="Absolute path to countries.geo.json")
    parser.add_argument("--out", required=True, help="Absolute path to destination SVG")
    parser.add_argument("--countries", required=True, help="Comma-separated ISO3 codes (DEU,AUT,CHE)")
    parser.add_argument("--stroke", default="#C00000", help="Resolved stroke hex (default Economist red)")
    parser.add_argument("--width", type=float, default=480, help="Target viewBox width in px")
    parser.add_argument("--stroke-width", type=float, default=2.0, help="Stroke width 1.5..2.5")
    parser.add_argument("--padding", type=float, default=16.0, help="Inner padding in px")
    parser.add_argument("--markers", default="", help="label:lon,lat;label2:lon2,lat2")
    parser.add_argument("--marker-radius", type=float, default=4.0, help="Marker dot radius in px")
    args = parser.parse_args()

    if not (1.0 <= args.stroke_width <= 3.0):
        emit({"ok": False, "e": f"stroke_width_out_of_range: {args.stroke_width}"}, 1)
    if args.width <= 0 or args.width > 4000:
        emit({"ok": False, "e": f"width_out_of_range: {args.width}"}, 1)

    iso_codes = [c.strip().upper() for c in args.countries.split(",") if c.strip()]
    if not iso_codes:
        emit({"ok": False, "e": "no_countries_given"}, 1)

    features = load_features(Path(args.data))

    missing = [c for c in iso_codes if c not in features]
    if missing:
        emit({"ok": False, "e": f"unknown_countries: {','.join(missing)}"}, 1)

    # Flatten all selected countries' rings and remember which ring belongs to which country.
    all_rings: list[list[list[float]]] = []
    country_groups: dict[str, list[int]] = {}
    for iso in iso_codes:
        indices: list[int] = []
        for ring in iter_rings(features[iso]["geometry"]):
            indices.append(len(all_rings))
            all_rings.append(ring)
        country_groups[iso] = indices

    if not all_rings:
        emit({"ok": False, "e": "no_rings_in_selection"}, 1)

    bounds = compute_bounds(all_rings)
    projected, target_w, target_h = project_and_scale(
        all_rings, bounds, args.width, args.padding
    )

    marker_specs = parse_markers(args.markers)
    marker_points = [
        project_marker(lon, lat, bounds, target_w, target_h, args.padding)
        for _, lon, lat in marker_specs
    ]

    svg = build_svg(
        projected,
        target_w,
        target_h,
        args.stroke,
        args.stroke_width,
        marker_points,
        args.marker_radius,
        country_groups,
    )

    out_path = Path(args.out)
    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(svg)
    except OSError as exc:
        emit({"ok": False, "e": f"write_failed: {exc}"}, 1)

    points_total = sum(len(r) for r in projected)
    emit(
        {
            "ok": True,
            "svg_path": str(out_path.resolve()),
            "width": int(target_w),
            "height": int(round(target_h)),
            "countries": iso_codes,
            "bounds": {
                "lon_min": bounds[0],
                "lon_max": bounds[1],
                "lat_min": bounds[2],
                "lat_max": bounds[3],
            },
            "points_total": points_total,
            "markers": len(marker_points),
        }
    )


if __name__ == "__main__":
    main()

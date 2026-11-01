#!/usr/bin/env python3
"""Generate an OpenSCAD board preset library from boards/*.json."""

import argparse
import json
import re
from pathlib import Path


def number(value):
    return f"{float(value):g}"


def ident(value):
    return re.sub(r"[^a-zA-Z0-9_]", "_", value)


def port_cutout(port, board_start, board_z_expr, board_height, inner_x, inner_y, wall, case_height):
    edge = port.get("face", port.get("edge", "front"))
    offset = float(port.get("offset", port.get("x", 0)))
    clearance = float(port.get("clearance", 0))
    width = float(port.get("width", 10)) + clearance * 2
    height = float(port.get("height", port.get("length", 5))) + clearance * 2
    radius = min(float(port.get("radius", 0)) + clearance, width / 2, height / 2)
    
    if "y" in port or "offset_y" in port:
        y_val = float(port.get("y", port.get("offset_y", 0)))
        z_expr = f"{board_z_expr} + {number(y_val - clearance)}"
    else:
        orig_height = float(port.get("height", port.get("length", 5)))
        z_expr = f"{board_z_expr} + {number(board_height - orig_height - clearance)}"

    x_expr = f"{board_start} + {number(offset - clearance)}"

    if edge == "front":
        if radius > 0:
            return f"translate([{x_expr}, wall + 1, {z_expr}]) rotate([90, 0, 0]) rounded_rect_cutout({number(width)}, {number(height)}, {number(radius)}, wall + 2);"
        return f"translate([{x_expr}, -1, {z_expr}]) cube([{number(width)}, wall + 2, {number(height)}]);"
    if edge == "back":
        return f"translate([{x_expr}, inner_y + wall - 1, {z_expr}]) cube([{number(width)}, wall + 2, {number(height)}]);"
    if edge == "left":
        return f"translate([-1, wall + {number(offset - clearance)}, {z_expr}]) cube([wall + 2, {number(width)}, {number(height)}]);"
    if edge == "right":
        return f"translate([inner_x + wall - 1, wall + {number(offset - clearance)}, {z_expr}]) cube([wall + 2, {number(width)}, {number(height)}]);"
    raise ValueError(f"Unsupported port edge: {edge}")


def front_cutout(item, board_start, board_z_expr, wall):
    clearance = float(item.get("clearance", 0))
    shape = item.get("shape", "rectangle")
    if shape == "polygon":
        points = item.get("points", [])
        if len(points) < 3:
            raise ValueError(f"Polygon {item.get('id', '')} has fewer than 3 points")
        coords = ", ".join(
            f"[{board_start} + {number(px)}, {board_z_expr} + {number(pz)}]" for px, pz in points
        )
        if clearance > 0:
            return f"translate([0, wall + 1, 0]) rotate([90, 0, 0]) linear_extrude(height=wall + 2) offset(delta = {number(clearance)}) polygon(points=[{coords}]);"
        return f"translate([0, wall + 1, 0]) rotate([90, 0, 0]) linear_extrude(height=wall + 2) polygon(points=[{coords}]);"
    if "diameter" in item:
        diameter = float(item["diameter"]) + clearance * 2
        x = f"{board_start} + {number(item.get('x', 0))}"
        z = f"{board_z_expr} + {number(item.get('y', item.get('z', 0)))}"
        return f"translate([{x}, wall + 1, {z}]) rotate([90, 0, 0]) cylinder(d={number(diameter)}, h=wall + 2, $fn=32);"
    width = float(item.get("width", 10)) + clearance * 2
    height = float(item.get("height", item.get("length", 10))) + clearance * 2
    x = f"{board_start} + {number(item.get('x', item.get('offset', 0)))}"
    z = f"{board_z_expr} + {number(item.get('y', item.get('z', 0)))}"
    radius = min(float(item.get("radius", 0)) + clearance, width / 2, height / 2)
    if radius > 0:
        return f"translate([{x} - {number(clearance)}, wall + 1, {z} - {number(clearance)}]) rotate([90, 0, 0]) rounded_rect_cutout({number(width)}, {number(height)}, {number(radius)}, wall + 2);"
    return f"translate([{x} - {number(clearance)}, -1, {z} - {number(clearance)}]) cube([{number(width)}, wall + 2, {number(height)}]);"


def top_cutout(item, board_start, wall, case_height):
    x = f"{board_start} + {number(item.get('x', 0))}"
    y = f"wall + {number(item.get('y', 0))}"
    clearance = float(item.get("clearance", 0))
    depth = "case_height + 2"
    shape = item.get("shape", "rectangle")
    if shape == "polygon":
        points = item.get("points", [])
        if len(points) < 3:
            raise ValueError(f"Polygon {item.get('id', '')} has fewer than 3 points")
        coords = ", ".join(
            f"[{board_start} + {number(px)}, wall + {number(py)}]" for px, py in points
        )
        if clearance > 0:
            return f"translate([0, 0, -1]) linear_extrude(height={depth}) offset(delta = {number(clearance)}) polygon(points=[{coords}]);"
        return f"translate([0, 0, -1]) linear_extrude(height={depth}) polygon(points=[{coords}]);"
    if "diameter" in item:
        diameter = float(item["diameter"]) + clearance * 2
        return f"translate([{x}, {y}, -1]) cylinder(d={number(diameter)}, h={depth}, $fn=32);"
    width = float(item.get("width", 10)) + clearance * 2
    length = float(item.get("length", item.get("height", 10))) + clearance * 2
    radius = min(float(item.get("radius", 0)) + clearance, width / 2, length / 2)
    if radius > 0:
        return f"translate([{x} - {number(clearance)}, {y} - {number(clearance)}, -1]) rounded_rect_cutout({number(width)}, {number(length)}, {number(radius)}, {depth});"
    return f"translate([{x} - {number(clearance)}, {y} - {number(clearance)}, -1]) cube([{number(width)}, {number(length)}, {depth}]);"


def render(profile):
    board = profile["board"]
    board_start = "wall + (inner_x - board_width) / 2"
    board_height = float(board["height"])
    board_z_expr = f"(board_z >= 0 ? board_z : case_height - wall - {number(board_height)})"
    board_id = ident(profile["id"])
    lines = [f"// Generated from {profile['id']}.json; do not edit by hand."]
    lines.append(f"// {profile.get('name', profile['id'])}")
    lines.append(f"function board_params_{board_id}() = [{number(board['width'])}, {number(board['length'])}, {number(board['height'])}];")
    
    # Front / edge cutouts
    lines.append(f"module cutouts_front_{board_id}(board_width, wall, inner_x, inner_y, case_height, board_z=-1) {{")
    for port in profile.get("ports", []):
        face = port.get("face", port.get("edge", "front"))
        if face in ("front", "back", "left", "right"):
            lines.append("    " + port_cutout(port, board_start, board_z_expr, board_height, "inner_x", "inner_y", "wall", "case_height"))
    for collection in ("displays", "buttons", "indicators", "holes"):
        for item in profile.get(collection, []):
            if item.get("face") == "front":
                lines.append("    " + front_cutout(item, board_start, board_z_expr, "wall"))
    lines.append("}")

    # Top cutouts
    lines.append(f"module cutouts_top_{board_id}(board_width, wall, inner_x, inner_y, case_height) {{")
    for port in profile.get("ports", []):
        if port.get("face") == "top":
            lines.append("    " + top_cutout(port, board_start, "wall", "case_height"))
    for collection in ("displays", "buttons", "indicators"):
        for item in profile.get(collection, []):
            if item.get("face", "top") == "top":
                lines.append("    " + top_cutout(item, board_start, "wall", "case_height"))
    for hole in profile.get("holes", []):
        if hole.get("face", "top") == "top":
            lines.append("    " + top_cutout(hole, board_start, "wall", "case_height"))
    for hole in profile.get("mounting_holes", []):
        item = {"x": hole["x"], "y": hole["y"], "diameter": hole.get("diameter", 3), "clearance": hole.get("clearance", 0.3), "face": hole.get("face", "top")}
        if item.get("face") == "top":
            lines.append("    " + top_cutout(item, board_start, "wall", "case_height"))
    lines.append("}")

    # Combined cutouts
    lines.append(f"module cutouts_{board_id}(board_width, wall, inner_x, inner_y, case_height, board_z=-1) {{")
    lines.append(f"    cutouts_front_{board_id}(board_width, wall, inner_x, inner_y, case_height, board_z);")
    lines.append(f"    cutouts_top_{board_id}(board_width, wall, inner_x, inner_y, case_height);")
    lines.append("}")

    return "\n".join(lines)


def render_dispatchers(profiles):
    lines = ["// --- Global Dispatcher Functions ---", ""]
    
    # get_board_params
    lines.append("function get_board_params(board_type) =")
    for p in profiles:
        b_id = ident(p["id"])
        lines.append(f'    board_type == "{p["id"]}" ? board_params_{b_id}() :')
    lines.append("    [50, 50, 12];")
    lines.append("")

    # draw_board_front_cutouts
    lines.append("module draw_board_front_cutouts(board_type, board_width, board_length, wall_thick, inner_x, inner_y, case_height, board_z=-1) {")
    first = True
    for p in profiles:
        b_id = ident(p["id"])
        prefix = "if" if first else "else if"
        lines.append(f'    {prefix} (board_type == "{p["id"]}") {{')
        lines.append(f"        cutouts_front_{b_id}(board_width, wall_thick, inner_x, inner_y, case_height, board_z);")
        lines.append("    }")
        first = False
    lines.append("}")
    lines.append("")

    # draw_board_top_cutouts
    lines.append("module draw_board_top_cutouts(board_type, board_width, board_length, wall_thick, inner_x, inner_y, case_height) {")
    first = True
    for p in profiles:
        b_id = ident(p["id"])
        prefix = "if" if first else "else if"
        lines.append(f'    {prefix} (board_type == "{p["id"]}") {{')
        lines.append(f"        cutouts_top_{b_id}(board_width, wall_thick, inner_x, inner_y, case_height);")
        lines.append("    }")
        first = False
    lines.append("}")
    lines.append("")

    # draw_board_cutouts (backwards compatible)
    lines.append("module draw_board_cutouts(board_type, board_width, board_length, wall_thick, inner_x, inner_y, case_height, board_z=-1) {")
    lines.append("    draw_board_front_cutouts(board_type, board_width, board_length, wall_thick, inner_x, inner_y, case_height, board_z);")
    lines.append("    draw_board_top_cutouts(board_type, board_width, board_length, wall_thick, inner_x, inner_y, case_height);")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("boards"))
    parser.add_argument("--output", type=Path, default=Path("generated_board_presets.scad"))
    args = parser.parse_args()
    profiles = [json.loads(path.read_text(encoding="utf-8")) for path in sorted(args.input.glob("*.json"))]
    if not profiles:
        raise SystemExit(f"No JSON profiles found in {args.input}")
    output = ["// Generated board library. Include presets_boards.scad or use directly.", "",
              "module rounded_rect_cutout(width, length, radius, height) {",
              "    hull() for (corner = [[radius, radius], [width - radius, radius], [width - radius, length - radius], [radius, length - radius]])",
              "        translate([corner[0], corner[1], 0]) cylinder(r=radius, h=height, $fn=32);",
              "}", ""]
    output.extend(render(profile) + "\n" for profile in profiles)
    output.append(render_dispatchers(profiles))
    args.output.write_text("\n".join(output), encoding="utf-8")
    print(f"Generated {args.output} from {len(profiles)} profiles")


if __name__ == "__main__":
    main()

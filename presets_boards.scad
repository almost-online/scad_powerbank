// Powerbank control board library.
// All parameters and cutout modules are auto-generated from boards/*.json.
// To update, run: python3 tools/generate_board_presets.py

include <generated_board_presets.scad>

// Helper modules for backward compatibility with custom models
module top_rectangle(x, y, width, length, z, depth, clearance=0) {
    translate([x - clearance, y - clearance, z])
        cube([width + clearance * 2, length + clearance * 2, depth]);
}

module top_polygon(points, z, depth) {
    translate([0, 0, z])
        linear_extrude(height=depth)
            polygon(points=points);
}

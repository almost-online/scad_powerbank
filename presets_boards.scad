// Бібліотека плат керування павербанком.
// Усі параметри та модулі вирізів генеруються автоматично з boards/*.json.
// Для оновлення виконайте: python3 tools/generate_board_presets.py

include <generated_board_presets.scad>

// Допоміжні модулі для зворотної сумісності з користувацькими моделями
module top_rectangle(x, y, width, length, z, depth, clearance=0) {
    translate([x - clearance, y - clearance, z])
        cube([width + clearance * 2, length + clearance * 2, depth]);
}

module top_polygon(points, z, depth) {
    translate([0, 0, z])
        linear_extrude(height=depth)
            polygon(points=points);
}

// Battery preset library.
// Dimensions in millimeters: [width, length, height, geometry type].

function get_battery_params(battery_type) =
    battery_type == "18650" ? [18.5, 65, 18.5, "cylindrical"] :
    battery_type == "lifepo4_pouch" ? [50, 70, 8, "pouch"] :
    battery_type == "liion_pouch_60x110x12" ? [60, 110, 12, "pouch"] :
    battery_type == "lifepo4_prismatic" ? [32, 70, 7, "prismatic"] :
    [50, 70, 10, "pouch"];

function get_battery_spacing(battery_type) =
    battery_type == "18650" ? 1.2 : 1.0;

function get_pack_grid(battery_type, pack_series, pack_parallel) =
    let(geom = get_battery_params(battery_type)[3])
    geom == "cylindrical" ? [pack_parallel, pack_series, 1] :
    [pack_parallel, 1, pack_series];

module draw_battery_preview(battery_type, battery_width, battery_length,
                            battery_height, cells_x, cells_y, cells_z=1, spacing=1.0) {
    if (battery_type == "18650") {
        for (ix = [0 : cells_x - 1])
            for (iy = [0 : cells_y - 1])
                for (iz = [0 : cells_z - 1])
                    translate([ix * (battery_width + spacing) + battery_width / 2,
                               iy * (battery_length + spacing),
                               iz * (battery_height + spacing) + battery_height / 2])
                        rotate([-90, 0, 0])
                            cylinder(d=battery_width, h=battery_length, $fn=48);
    } else {
        for (ix = [0 : cells_x - 1])
            for (iy = [0 : cells_y - 1])
                for (iz = [0 : cells_z - 1])
                    translate([ix * (battery_width + spacing),
                               iy * (battery_length + spacing),
                               iz * (battery_height + spacing)])
                        cube([battery_width, battery_length, battery_height]);
    }
}
include <presets_batteries.scad>
include <presets_boards.scad>

// ==========================================
// MAIN MODEL SETTINGS
// Change parameters only in this block.
// All dimensions are in millimeters.
// ==========================================

// Battery type:
// "18650"
// "liion_pouch_60x110x12"
// "lifepo4_pouch"
// "lifepo4_prismatic"
battery_type = "liion_pouch_60x110x12";

// Board type:
// "abkn_pd45w_3s" (or "UFCS_PD45W")
board_type = "abkn_pd45w_3s";

// Battery block configuration:
// For 18650: pack_series is laid out along Y (length), pack_parallel — along X (width).
// For pouch / prismatic packs: pack_series is stacked along height Z (with spacing gap for ventilation),
// pack_parallel — along width X.
// Examples: 1S1P = 1 and 1, 3S1P = 3 and 1, 4S2P = 4 and 2.
pack_series = 3;
pack_parallel = 1;

// Wall thickness and general assembly clearance.
wall_thick = 3.0;
tolerance = 0.6;

// Distance between adjacent battery cells (gap for air flow and cooling).
// For -1, the value from the battery preset is used.
spacing_override = -1;

// Extra margin around batteries and board in the XY plane.
// Increase if wires, BMS, strips, or connectors are needed.
inner_xy_margin = 4;

// Extra vertical space above the board/batteries.
inner_z_margin = 4;

// Radius for rounding vertical edges of the case (0 for sharp corners).
case_corner_radius = 4.0;

// Extra longitudinal space in the board pocket for wire soldering (40-60 mm).
wire_soldering_space = 20.0;

// PCB side holder parameters (built into the case):
// Fix the board at the edges of the compartment, with a slot for the PCB.
enable_board_holders = true;        // true = built-in holders at the edges of the board compartment
board_thickness = 1.1;             // PCB thickness (mm)
board_holder_thick = 1.2;          // Holder thickness (mm)
board_holder_width = wire_soldering_space; // Holder length along Y (mm)
board_holder_slot_depth = 1.5;    // Slot depth for the PCB (mm)
board_holder_slot_offset = 6.0;   // Distance from the front panel to the start of the slot (mm)

// Internal partition parameters (board pocket).
enable_partition = true;
enable_modular_partition = true;   // true = removable partition in U-shaped grooves; false = monolithic wall
partition_thick = 2.4;             // Removable partition thickness (mm)
partition_groove_depth = 1.2;      // Depth of guide U-grooves in walls and bottom of the case (mm)
partition_wire_hole_d = 3.5;       // Diameter of holes for power wires
partition_nickel_slot_w = 8.0;     // Width of slots for nickel strips
partition_nickel_slot_h = 1.5;     // Height of slots for nickel strips
show_partition = true;             // Show partition when part = "all"

// Ventilation grille parameters (passive convective cooling).
enable_ventilation = true;
vent_type = "hex"; // "slots" (longitudinal cuts) or "hex" (honeycomb/hexagons)
vent_slot_w = 2.0;
vent_slot_spacing = 2.5;
vent_hex_radius = 2.2;
vent_hex_wall = 1.2;
vent_placement = "sides"; // "sides" (side walls), "bottom" (bottom), "both" (sides + bottom)

// Lid lock parameters (reliable mechanical Snap-fit fixation).
enable_snap_fit = true;
snap_ridge_depth = 0.5;
snap_ridge_height = 1.2;
snap_ridge_len = 12.0;

// Modular removable front panel parameters (Faceplate / Bezel):
enable_modular_front_panel = true; // true = removable front panel in grooves; false = monolithic case
front_panel_thick = wall_thick;    // Removable front panel thickness
front_panel_groove_depth = 1.2;    // Depth of guide grooves in case walls (mm)
show_front_panel = true;           // Show removable panel when part = "all"
panel_gap = 8;                     // Gap between parts on the print bed (mm)

// Export and visualization part selector:
// "all" - body, lid, front panel, and partition on the print bed
// "body" - only the main body
// "lid" - only the lid
// "front_panel" - only the flat front panel
// "partition" - only the flat partition
// "assembly" - assembly of body, front panel, partition, and closed lid
part = "all";

// Lid and preview parameters.
show_lid = true;
show_battery = false;
lid_gap = 8;
lid_thick = wall_thick;
lid_lip_depth = 2.5;

// Internal variables. Do not change manually.
grid = get_pack_grid(battery_type, pack_series, pack_parallel);
cells_x = grid[0];
cells_y = grid[1];
cells_z = grid[2];
spacing = spacing_override < 0 ? get_battery_spacing(battery_type) : spacing_override;

battery = get_battery_params(battery_type);
board = get_board_params(board_type);
battery_width = battery[0];
battery_length = battery[1];
battery_height = battery[2];
board_width = board[0];
board_length = board[1];
board_height = board[2];

board_pocket_length = wire_soldering_space + tolerance * 2;

part_thick = enable_partition ? partition_thick : 0;

pack_width = cells_x * battery_width + max(cells_x - 1, 0) * spacing;
pack_length = cells_y * battery_length + max(cells_y - 1, 0) * spacing;
pack_height = cells_z * battery_height + max(cells_z - 1, 0) * spacing;

inner_x = max(pack_width, board_width) + tolerance * 2 + inner_xy_margin;
inner_y = board_pocket_length + part_thick + pack_length + inner_xy_margin;
inner_z = max(pack_height, board_height) + inner_z_margin;

outer_x = inner_x + wall_thick * 2;
outer_y = inner_y + wall_thick * 2;
outer_z = inner_z + wall_thick;

partition_y_start = wall_thick + board_pocket_length;
battery_y_start = partition_y_start + part_thick;
board_z_start = wall_thick + max(0, (inner_z - board_height) / 2);

// Calculated parameters for the modular front panel and grooves
groove_d = enable_modular_front_panel ? min(wall_thick / 2, front_panel_groove_depth) : 0;
panel_w = inner_x + 2 * groove_d - 2 * tolerance;
panel_h = inner_z + groove_d - lid_lip_depth - tolerance;
panel_x_start = wall_thick - groove_d + tolerance;
panel_z_start = wall_thick - groove_d + tolerance;

// Calculated parameters for the modular removable partition and U-grooves
part_groove_d = (enable_partition && enable_modular_partition) ? min(wall_thick / 2, partition_groove_depth) : 0;
part_panel_w = inner_x + 2 * part_groove_d - 2 * tolerance;
part_panel_h = inner_z + part_groove_d - lid_lip_depth - tolerance;
part_panel_x_start = wall_thick - part_groove_d + tolerance;
part_panel_z_start = wall_thick - part_groove_d + tolerance;

module rounded_rect_2d(w, l, r) {
    rad = min(r, w / 2, l / 2);
    if (rad <= 0) {
        square([w, l]);
    } else {
        hull() {
            translate([rad, rad]) circle(r=rad, $fn=32);
            translate([w - rad, rad]) circle(r=rad, $fn=32);
            translate([w - rad, l - rad]) circle(r=rad, $fn=32);
            translate([rad, l - rad]) circle(r=rad, $fn=32);
        }
    }
}

module vent_pattern_2d(w, h, type="slots") {
    if (w > 6 && h > 6) {
        if (type == "hex") {
            cell_r = vent_hex_radius;
            wall_t = vent_hex_wall;
            dx = sqrt(3) * cell_r + wall_t;
            dy = 1.5 * cell_r + wall_t * sqrt(3) / 2;
            cols = max(1, floor(w / dx));
            rows = max(1, floor(h / dy));
            intersection() {
                square([w, h]);
                for (r = [0 : rows]) {
                    for (c = [0 : cols]) {
                        ox = (r % 2 == 1) ? dx / 2 : 0;
                        translate([c * dx + ox, r * dy])
                            circle(r=cell_r, $fn=6);
                    }
                }
            }
        } else {
            slot_w = vent_slot_w;
            spacing = vent_slot_spacing;
            pitch = slot_w + spacing;
            count = max(1, floor((w - spacing) / pitch));
            start_x = (w - (count * pitch - spacing)) / 2;
            for (i = [0 : count - 1]) {
                translate([start_x + i * pitch, 0])
                    hull() {
                        translate([slot_w / 2, slot_w / 2]) circle(d=slot_w, $fn=16);
                        translate([slot_w / 2, h - slot_w / 2]) circle(d=slot_w, $fn=16);
                    }
            }
        }
    }
}

module board_holder(side) {
    // Side PCB holder with a slot for the textolite board
    // side: "left" or "right"
    holder_len = board_holder_width + tolerance/2;
    holder_x = (side == "left")
        ? wall_thick
        : wall_thick + (inner_x - board_width) / 2 + board_width;
    holder_y = front_panel_thick + tolerance;
    holder_z = wall_thick;
    holder_width = (inner_x - board_width) / 2;
    holder_height = part_panel_h;

    difference() {
        // Main holder block extending from the bottom up the full height
        translate([holder_x, holder_y, holder_z])
            cube([holder_width, holder_len, holder_height]);
        
        // PCB slot cut into the holder to depth board_holder_slot_depth
        // from the inner edge toward the wall, centered vertically
        slot_w = board_holder_thick;  // Slot width 1.2mm
        slot_center_z = holder_z + inner_z / 2;
        slot_start_z = slot_center_z - slot_w / 2;

        // Slot depth from the inner edge of the holder to the wall
        if (side == "left") {
            // Left holder: slot goes from inner edge (holder_x + board_holder_thick)
            // leftward by board_holder_slot_depth
            translate([holder_x + board_holder_thick,
                       board_holder_slot_offset + holder_y - 0.05,
                       holder_z])
                cube([board_holder_slot_depth + 0.1, slot_w + 0.1, holder_height]);
        } else {
            // Right holder: slot goes from inner edge (holder_x)
            // rightward by board_holder_slot_depth
            translate([holder_x - 0.05,
                       board_holder_slot_offset + holder_y - 0.05,
                       holder_z])
                cube([board_holder_slot_depth + 0.1, slot_w + 0.1, holder_height]);
        }
    }
}

module powerbank_body() {
    union() {
        difference() {
            linear_extrude(outer_z)
                rounded_rect_2d(outer_x, outer_y, case_corner_radius);
        
        if (enable_partition && !enable_modular_partition) {
            // Monolithic mode: separate pockets with a monolithic wall between them
            translate([wall_thick, wall_thick, wall_thick])
                cube([inner_x, board_pocket_length, inner_z + 1]);
                
            translate([wall_thick, battery_y_start, wall_thick])
                cube([inner_x, pack_length + inner_xy_margin, inner_z + 1]);
                
            // Technical holes in the monolithic partition (for wires and nickel strips)
            if (part_thick > 0) {
                for (hx = [wall_thick + 12, wall_thick + inner_x / 2, wall_thick + inner_x - 12]) {
                    translate([hx, partition_y_start - 0.5, wall_thick + inner_z / 2])
                        rotate([-90, 0, 0])
                            cylinder(d=partition_wire_hole_d, h=part_thick + 1, $fn=24);
                }
                translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + 3])
                    cube([partition_nickel_slot_w, part_thick + 1, partition_nickel_slot_h]);
                translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + 3])
                    cube([partition_nickel_slot_w, part_thick + 1, partition_nickel_slot_h]);
                    
                translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
                    cube([partition_nickel_slot_w, part_thick + 1, partition_nickel_slot_h]);
                translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
                    cube([partition_nickel_slot_w, part_thick + 1, partition_nickel_slot_h]);

                // Top slot in the partition for the lid lip
                translate([wall_thick + tolerance, partition_y_start - 0.1, outer_z - lid_lip_depth])
                    cube([inner_x - 2 * tolerance, part_thick + 0.2, lid_lip_depth + 1]);
            }
        } else {
            // Modular mode or case without partition: shared internal cavity
            translate([wall_thick, wall_thick, wall_thick])
                cube([inner_x, inner_y, inner_z + 1]);
                
            // U-shaped guide grooves for the removable partition
            if (enable_partition && enable_modular_partition) {
                part_slot_thick = partition_thick + tolerance;
                
                // Left vertical guide groove (open from above)
                translate([wall_thick - part_groove_d, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([part_groove_d + 0.1, part_slot_thick, inner_z + part_groove_d + 1]);
                    
                // Right vertical guide groove (open from above)
                translate([wall_thick + inner_x - 0.1, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([part_groove_d + 0.1, part_slot_thick, inner_z + part_groove_d + 1]);
                    
                // Bottom fixing groove
                translate([wall_thick - part_groove_d, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([inner_x + 2 * part_groove_d, part_slot_thick, part_groove_d + 0.1]);
            }
        }
        
        // Ventilation grilles (side and/or bottom)
        if (enable_ventilation) {
            vent_h = max(0, inner_z - lid_lip_depth - 8);
            
            // Board compartment ventilation (Y-range)
            pocket_vent_len = max(0, board_pocket_length - 14);
            pocket_vent_y = wall_thick + 7;
            
            // Battery compartment ventilation (Y-range)
            bat_vent_len = max(0, pack_length + inner_xy_margin - 14);
            bat_vent_y = battery_y_start + 7;
            
            if ((vent_placement == "sides" || vent_placement == "both") && vent_h >= 6) {
                // Side ventilation holes on left and right walls (board compartment)
                if (pocket_vent_len >= 8) {
                    translate([-1, pocket_vent_y, wall_thick + 4])
                        rotate([90, 0, 90])
                            linear_extrude(wall_thick + 2)
                                vent_pattern_2d(pocket_vent_len, vent_h, vent_type);
                    translate([outer_x - wall_thick - 1, pocket_vent_y, wall_thick + 4])
                        rotate([90, 0, 90])
                            linear_extrude(wall_thick + 2)
                                vent_pattern_2d(pocket_vent_len, vent_h, vent_type);
                }
                
                // Side ventilation holes on left and right walls (battery compartment)
                if (bat_vent_len >= 8) {
                    translate([-1, bat_vent_y, wall_thick + 4])
                        rotate([90, 0, 90])
                            linear_extrude(wall_thick + 2)
                                vent_pattern_2d(bat_vent_len, vent_h, vent_type);
                    translate([outer_x - wall_thick - 1, bat_vent_y, wall_thick + 4])
                        rotate([90, 0, 90])
                            linear_extrude(wall_thick + 2)
                                vent_pattern_2d(bat_vent_len, vent_h, vent_type);
                }
            }
            
            if ((vent_placement == "bottom" || vent_placement == "both") && inner_x >= 16) {
                // Bottom ventilation
                bottom_w = inner_x - 12;
                if (pocket_vent_len >= 8) {
                    translate([wall_thick + 6, pocket_vent_y, -1])
                        linear_extrude(wall_thick + 2)
                            vent_pattern_2d(bottom_w, pocket_vent_len, vent_type);
                }
                if (bat_vent_len >= 8) {
                    translate([wall_thick + 6, bat_vent_y, -1])
                        linear_extrude(wall_thick + 2)
                            vent_pattern_2d(bottom_w, bat_vent_len, vent_type);
                }
            }
        }
        
        // Lid lock grooves (Snap-fit detents)
        if (enable_snap_fit) {
            snap_z = outer_z - lid_lip_depth / 2 - snap_ridge_height / 2;
            for (sy = [wall_thick + inner_y * 0.3, wall_thick + inner_y * 0.7]) {
                translate([wall_thick - snap_ridge_depth, sy - snap_ridge_len / 2, snap_z])
                    cube([snap_ridge_depth + 0.1, snap_ridge_len, snap_ridge_height]);
                translate([outer_x - wall_thick - 0.1, sy - snap_ridge_len / 2, snap_z])
                    cube([snap_ridge_depth + 0.1, snap_ridge_len, snap_ridge_height]);
            }
        }
        
        // Front wall: grooves for the modular removable front panel or monolithic cutouts
        if (enable_modular_front_panel) {
            groove_slot_thick = front_panel_thick + tolerance;
            
            // Central front window
            translate([wall_thick, -1, wall_thick])
                cube([inner_x, wall_thick + 2, inner_z + 1]);
                
            // Left vertical guide groove (open from above)
            translate([wall_thick - groove_d, -0.5, wall_thick - groove_d])
                cube([groove_d + 0.1, groove_slot_thick + 0.5, inner_z + groove_d + 1]);
                
            // Right vertical guide groove (open from above)
            translate([wall_thick + inner_x - 0.1, -0.5, wall_thick - groove_d])
                cube([groove_d + 0.1, groove_slot_thick + 0.5, inner_z + groove_d + 1]);
                
            // Bottom fixing groove
            translate([wall_thick - groove_d, -0.5, wall_thick - groove_d])
                cube([inner_x + 2 * groove_d, groove_slot_thick + 0.5, groove_d + 0.1]);
        } else {
            // Monolithic front wall with direct cutouts
            draw_board_front_cutouts(board_type, board_width, board_length,
                                     wall_thick, inner_x, inner_y, outer_z, board_z_start);
        }
        }
        
        // Side PCB holders (built into the case)
        if (enable_board_holders) {
            board_holder("left");
            board_holder("right");
        }
    }
}

module front_panel_upright() {
    difference() {
        translate([panel_x_start, 0, panel_z_start])
            cube([panel_w, front_panel_thick, panel_h]);
            
        draw_board_front_cutouts(board_type, board_width, board_length,
                                 front_panel_thick, inner_x, inner_y, outer_z, board_z_start);
    }
}

module front_panel() {
    // Flat part on the print bed in the XY plane (Z = 0 .. front_panel_thick)
    // for flat printing without supports with perfect hole quality
    translate([-panel_x_start, panel_z_start + panel_h, 0])
        rotate([90, 0, 0])
            front_panel_upright();
}

module partition_panel_upright() {
    difference() {
        translate([part_panel_x_start, partition_y_start, part_panel_z_start])
            cube([part_panel_w, partition_thick, part_panel_h]);
            
        // Holes for power wires
        for (hx = [wall_thick + 12, wall_thick + inner_x / 2, wall_thick + inner_x - 12]) {
            translate([hx, partition_y_start - 0.5, wall_thick + inner_z / 2])
                rotate([-90, 0, 0])
                    cylinder(d=partition_wire_hole_d, h=partition_thick + 1, $fn=24);
        }
        
        // Bottom slots for nickel strips
        translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + 3])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
        translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + 3])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
            
        // Top slots for nickel strips
        translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
        translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
    }
}

module partition_panel() {
    // Flat part on the print bed in the XY plane (Z = 0 .. partition_thick)
    // for flat printing without supports with perfect hole quality
    translate([-part_panel_x_start, part_panel_z_start + part_panel_h, -partition_y_start])
        rotate([90, 0, 0])
            partition_panel_upright();
}

module lid() {
    difference() {
        union() {
            // Flat lid with corresponding rounding of vertical corners
            linear_extrude(lid_thick)
                rounded_rect_2d(outer_x, outer_y, case_corner_radius);
                
            // Inner centering lip (pin) with tolerance clearance
            translate([wall_thick + tolerance, wall_thick + tolerance, lid_thick])
                difference() {
                    cube([inner_x - 2 * tolerance, inner_y - 2 * tolerance, lid_lip_depth]);
                    translate([wall_thick, wall_thick, -0.1])
                        cube([max(0, inner_x - 2 * tolerance - 2 * wall_thick),
                              max(0, inner_y - 2 * tolerance - 2 * wall_thick),
                              lid_lip_depth + 0.2]);
                }
                
            // Front fixing lip of the lid for pressing the removable front panel
            if (enable_modular_front_panel) {
                translate([panel_x_start, tolerance, lid_thick])
                    cube([panel_w, wall_thick, lid_lip_depth]);
            }
            
            // Transverse fixing lip of the lid for pressing the removable partition
            if (enable_partition && enable_modular_partition) {
                translate([part_panel_x_start, partition_y_start - tolerance / 2, lid_thick])
                    cube([part_panel_w, partition_thick + tolerance, lid_lip_depth]);
            }
                
            // Snap-fit ridges on the lid lip
            if (enable_snap_fit) {
                ridge_z = lid_thick + lid_lip_depth / 2 - snap_ridge_height / 2;
                for (sy = [wall_thick + inner_y * 0.3, wall_thick + inner_y * 0.7]) {
                    // Left protrusion
                    translate([wall_thick + tolerance - snap_ridge_depth, sy - snap_ridge_len / 2, ridge_z])
                        cube([snap_ridge_depth, snap_ridge_len, snap_ridge_height]);
                    // Right protrusion
                    translate([outer_x - wall_thick - tolerance, sy - snap_ridge_len / 2, ridge_z])
                        cube([snap_ridge_depth, snap_ridge_len, snap_ridge_height]);
                }
            }
        }
        draw_board_top_cutouts(board_type, board_width, board_length,
                               wall_thick, inner_x, inner_y, lid_thick + lid_lip_depth + 2);
    }
}

if (part == "all") {
    powerbank_body();
    
    if (show_lid)
        translate([outer_x + lid_gap, 0, 0]) lid();
        
    if (enable_modular_front_panel && show_front_panel)
        translate([0, outer_y + panel_gap, 0]) front_panel();

    if (enable_partition && enable_modular_partition && show_partition)
        translate([outer_x + lid_gap, outer_y + panel_gap, 0]) partition_panel();

    if (show_battery) {
        %translate([wall_thick + (inner_x - pack_width) / 2,
                    battery_y_start + (pack_length + inner_xy_margin - pack_length) / 2,
                    wall_thick + (inner_z - pack_height) / 2])
            draw_battery_preview(battery_type, battery_width, battery_length,
                                 battery_height, cells_x, cells_y, cells_z, spacing);
    }
}
else if (part == "body") {
    powerbank_body();
}
else if (part == "lid") {
    lid();
}
else if (part == "front_panel") {
    if (enable_modular_front_panel) {
        front_panel();
    }
}
else if (part == "partition") {
    if (enable_partition && enable_modular_partition) {
        partition_panel();
    }
}
else if (part == "assembly") {
    powerbank_body();
    
    if (enable_modular_front_panel) {
        front_panel_upright();
    }
    
    if (enable_partition && enable_modular_partition) {
        partition_panel_upright();
    }
    
    // Visualization of the closed lid on the body
    translate([0, outer_y, outer_z + lid_thick])
        rotate([180, 0, 0])
            lid();

    if (show_battery) {
        %translate([wall_thick + (inner_x - pack_width) / 2,
                    battery_y_start + (pack_length + inner_xy_margin - pack_length) / 2,
                    wall_thick + (inner_z - pack_height) / 2])
            draw_battery_preview(battery_type, battery_width, battery_length,
                                 battery_height, cells_x, cells_y, cells_z, spacing);
    }
}

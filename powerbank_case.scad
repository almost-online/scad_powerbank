include <presets_batteries.scad>
include <presets_boards.scad>

// ==========================================
// ОСНОВНІ НАЛАШТУВАННЯ МОДЕЛІ
// Змінюйте параметри тільки в цьому блоці.
// Усі розміри задані в міліметрах.
// ==========================================

// Тип батареї:
// "18650"
// "liion_pouch_60x110x12"
// "lifepo4_pouch"
// "lifepo4_prismatic"
battery_type = "liion_pouch_60x110x12";

// Тип плати:
// "abkn_pd45w_3s" (або "UFCS_PD45W")
board_type = "abkn_pd45w_3s";

// Конфігурація акумуляторного блоку:
// Для 18650: pack_series розкладається вздовж Y (довжина), pack_parallel — вздовж X (ширина).
// Для pouch / prismatic пакетів: pack_series складається по висоті Z (стопкою із зазором spacing для вентиляції),
// pack_parallel — по ширині X.
// Приклади: 1S1P = 1 і 1, 3S1P = 3 і 1, 4S2P = 4 і 2.
pack_series = 3;
pack_parallel = 1;

// Товщина стінок корпуса та загальний монтажний зазор.
wall_thick = 2.0;
tolerance = 0.6;

// Відстань між сусідніми елементами батареї (зазор для проходження повітря та охолодження).
// Для -1 використовується значення з пресету батареї.
spacing_override = -1;

// Додатковий запас навколо батарей і плати в площині XY.
// Збільшіть, якщо потрібні дроти, BMS, стрічка або роз'єми.
inner_xy_margin = 4;

// Додатковий вертикальний простір над платою/батареями.
inner_z_margin = 4;

// Радіус заокруглення вертикальних країв корпусу (0 для гострих кутів).
case_corner_radius = 4.0;

// Додатковий поздовжній простір у кишеньці плати для паяння дротів (40-60 мм).
wire_soldering_space = 20.0;

// Параметри бічних тримачів плати (вбудовані в корпус):
// Два блоки-тримачі з вертикальним пазом (вздовж Z) для фіксації плати.
// Плата разом з передньою панеллю та перегородкою заходить вздовж осі Z.
enable_board_holders = true;        // true = вбудовані тримачі по краях відсіку плати
board_thickness = 1.1;             // Товщина плати PCB (мм)
board_holder_thick = 1.2;          // Товщина тримача (мм)
board_holder_width = 4.0;          // Ширина тримача вздовж Y (мм)
board_holder_slot_depth = 1.5;    // Глибина вертикального пазу (мм)
board_holder_slot_offset = 6.0;   // Відстань від передньої стінки до пазу (мм)

// Параметри внутрішньої перегородки (кишеньки плати).
enable_partition = true;
enable_modular_partition = true;   // true = знімна перегородка у П-подібних пазах; false = монолітна стінка
partition_thick = 2.4;             // Товщина знімної перегородки (мм)
partition_groove_depth = 1.2;      // Глибина напрямних П-пазів у стінках і дні корпусу (мм)
partition_wire_hole_d = 3.5;       // Діаметр отворів під силові дроти
partition_nickel_slot_w = 8.0;     // Ширина пазів під нікелеві стрічки
partition_nickel_slot_h = 1.5;     // Висота пазів під нікелеві стрічки
show_partition = true;             // Відображати перегородку при part = "all"

// Параметри вентиляційних решіток (пасивне конвекційне охолодження).
enable_ventilation = true;
vent_type = "slots"; // "slots" (поздовжні прорізи) або "hex" (стільники/гексагони)
vent_slot_w = 2.0;
vent_slot_spacing = 2.5;
vent_hex_radius = 2.2;
vent_hex_wall = 1.2;
vent_placement = "sides"; // "sides" (бічні стінки), "bottom" (дно), "both" (боки + дно)

// Параметри замка кришки (надійна механічна фіксація Snap-fit).
enable_snap_fit = true;
snap_ridge_depth = 0.5;
snap_ridge_height = 1.2;
snap_ridge_len = 12.0;

// Параметри модульної знімної передньої панелі (Faceplate / Bezel):
enable_modular_front_panel = true; // true = знімна передня панель у пазах; false = монолітний корпус
front_panel_thick = wall_thick;    // Товщина знімної лицьової панелі
front_panel_groove_depth = 1.2;    // Глибина напрямних пазів у стінках корпусу (мм)
show_front_panel = true;           // Відображати знімну панель при part = "all"
panel_gap = 8;                     // Відступ деталей на столі друку (мм)

// Селектор експорту та візуалізації деталей:
// "all" - корпус, кришка, передня панель та перегородка на столі друку
// "body" - тільки основний корпус
// "lid" - тільки кришка
// "front_panel" - тільки пласка передня панель
// "partition" - тільки пласка перегородка
// "assembly" - збірка корпусу, передньої панелі, перегородки та закритої кришки
part = "all";

// Параметри кришки та прев'ю.
show_lid = true;
show_battery = false;
lid_gap = 8;
lid_thick = wall_thick;
lid_lip_depth = 2.5;

// Внутрішні змінні. Їх не потрібно змінювати вручну.
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

board_pocket_length = board_length + wire_soldering_space + tolerance * 2;

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

// Розрахункові параметри модульної передньої панелі та пазів
groove_d = enable_modular_front_panel ? min(wall_thick / 2, front_panel_groove_depth) : 0;
panel_w = inner_x + 2 * groove_d - 2 * tolerance;
panel_h = inner_z + groove_d - lid_lip_depth - tolerance;
panel_x_start = wall_thick - groove_d + tolerance;
panel_z_start = wall_thick - groove_d + tolerance;

// Розрахункові параметри модульної знімної перегородки та П-пазів
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
    // Бічний тримач плати з вертикальним пазом (вздовж Z)
    // side: "left" або "right"
    // Паз розташований на відстані board_holder_slot_offset від передньої стінки
    holder_len = board_holder_width;
    holder_x = (side == "left") 
        ? wall_thick + (inner_x - board_width) / 2 - board_holder_thick 
        : wall_thick + (inner_x - board_width) / 2 + board_width;
    holder_y = wall_thick + board_holder_slot_offset;
    holder_z = wall_thick;
    
    difference() {
        // Основний блок тримача, що йде від дна вгору на всю висоту
        translate([holder_x, holder_y, holder_z])
            cube([board_holder_thick, holder_len, inner_z]);
        
        // Вертикальний паз (вздовж Z) для вільного входження плати
        slot_w = board_thickness + tolerance;
        translate([holder_x - 0.05, holder_y, holder_z + inner_z / 2 - slot_w / 2])
            cube([board_holder_thick + 0.1, holder_len + 0.1, slot_w]);
    }
}

module powerbank_body() {
    union() {
        difference() {
            linear_extrude(outer_z)
                rounded_rect_2d(outer_x, outer_y, case_corner_radius);
        
        if (enable_partition && !enable_modular_partition) {
            // Монолітний режим: окремі кишеньки з монолітною стінкою між ними
            translate([wall_thick, wall_thick, wall_thick])
                cube([inner_x, board_pocket_length, inner_z + 1]);
                
            translate([wall_thick, battery_y_start, wall_thick])
                cube([inner_x, pack_length + inner_xy_margin, inner_z + 1]);
                
            // Технологічні отвори в монолітній перегородці (під дроти та нікелеві стрічки)
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

                // Верхній паз у перегородці під бортик кришки
                translate([wall_thick + tolerance, partition_y_start - 0.1, outer_z - lid_lip_depth])
                    cube([inner_x - 2 * tolerance, part_thick + 0.2, lid_lip_depth + 1]);
            }
        } else {
            // Модульний режим або корпус без перегородки: спільна внутрішня порожнина
            translate([wall_thick, wall_thick, wall_thick])
                cube([inner_x, inner_y, inner_z + 1]);
                
            // П-подібні напрямні пази під знімну перегородку
            if (enable_partition && enable_modular_partition) {
                part_slot_thick = partition_thick + tolerance;
                
                // Лівий вертикальний напрямний паз (відкритий зверху)
                translate([wall_thick - part_groove_d, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([part_groove_d + 0.1, part_slot_thick, inner_z + part_groove_d + 1]);
                    
                // Правий вертикальний напрямний паз (відкритий зверху)
                translate([wall_thick + inner_x - 0.1, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([part_groove_d + 0.1, part_slot_thick, inner_z + part_groove_d + 1]);
                    
                // Нижній фіксуючий паз
                translate([wall_thick - part_groove_d, partition_y_start - tolerance / 2, wall_thick - part_groove_d])
                    cube([inner_x + 2 * part_groove_d, part_slot_thick, part_groove_d + 0.1]);
            }
        }
        
        // Вентиляційні решітки (бічні та/або нижні)
        if (enable_ventilation) {
            vent_h = max(0, inner_z - lid_lip_depth - 8);
            
            // Вентиляція відсіку плати (Y-діапазон)
            pocket_vent_len = max(0, board_pocket_length - 14);
            pocket_vent_y = wall_thick + 7;
            
            // Вентиляція батарейного відсіку (Y-діапазон)
            bat_vent_len = max(0, pack_length + inner_xy_margin - 14);
            bat_vent_y = battery_y_start + 7;
            
            if ((vent_placement == "sides" || vent_placement == "both") && vent_h >= 6) {
                // Бічні вентиляційні отвори на лівій та правій стінках (відсік плати)
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
                
                // Бічні вентиляційні отвори на лівій та правій стінках (батарейний відсік)
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
                // Нижня вентиляція дна
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
        
        // Пази фіксатора кришки (Snap-fit detents)
        if (enable_snap_fit) {
            snap_z = outer_z - lid_lip_depth / 2 - snap_ridge_height / 2;
            for (sy = [wall_thick + inner_y * 0.3, wall_thick + inner_y * 0.7]) {
                translate([wall_thick - snap_ridge_depth, sy - snap_ridge_len / 2, snap_z])
                    cube([snap_ridge_depth + 0.1, snap_ridge_len, snap_ridge_height]);
                translate([outer_x - wall_thick - 0.1, sy - snap_ridge_len / 2, snap_z])
                    cube([snap_ridge_depth + 0.1, snap_ridge_len, snap_ridge_height]);
            }
        }
        
        // Передня стінка: пази для модульної знімної передньої панелі або монолітні вирізи
        if (enable_modular_front_panel) {
            groove_slot_thick = front_panel_thick + tolerance;
            
            // Центральне переднє вікно
            translate([wall_thick, -1, wall_thick])
                cube([inner_x, wall_thick + 2, inner_z + 1]);
                
            // Лівий вертикальний напрямний паз (відкритий зверху)
            translate([wall_thick - groove_d, -0.5, wall_thick - groove_d])
                cube([groove_d + 0.1, groove_slot_thick + 0.5, inner_z + groove_d + 1]);
                
            // Правий вертикальний напрямний паз (відкритий зверху)
            translate([wall_thick + inner_x - 0.1, -0.5, wall_thick - groove_d])
                cube([groove_d + 0.1, groove_slot_thick + 0.5, inner_z + groove_d + 1]);
                
            // Нижній фіксуючий паз
            translate([wall_thick - groove_d, -0.5, wall_thick - groove_d])
                cube([inner_x + 2 * groove_d, groove_slot_thick + 0.5, groove_d + 0.1]);
        } else {
            // Монолітна передня стінка з прямими вирізами
            draw_board_front_cutouts(board_type, board_width, board_length,
                                     wall_thick, inner_x, inner_y, outer_z, board_z_start);
        }
        }
        
        // Бічні тримачі плати з вертикальним пазом (вбудовані в корпус)
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
    // Пласка деталь на столі друку в площині XY (Z = 0 .. front_panel_thick)
    // для друку плазом без підтримок з ідеальною якістю отворів
    translate([-panel_x_start, panel_z_start + panel_h, 0])
        rotate([90, 0, 0])
            front_panel_upright();
}

module partition_panel_upright() {
    difference() {
        translate([part_panel_x_start, partition_y_start, part_panel_z_start])
            cube([part_panel_w, partition_thick, part_panel_h]);
            
        // Отвори під силові дроти
        for (hx = [wall_thick + 12, wall_thick + inner_x / 2, wall_thick + inner_x - 12]) {
            translate([hx, partition_y_start - 0.5, wall_thick + inner_z / 2])
                rotate([-90, 0, 0])
                    cylinder(d=partition_wire_hole_d, h=partition_thick + 1, $fn=24);
        }
        
        // Нижні пази під нікелеві стрічки
        translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + 3])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
        translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + 3])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
            
        // Верхні пази під нікелеві стрічки
        translate([wall_thick + 3, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
        translate([wall_thick + inner_x - 3 - partition_nickel_slot_w, partition_y_start - 0.5, wall_thick + inner_z - 3 - partition_nickel_slot_h])
            cube([partition_nickel_slot_w, partition_thick + 1, partition_nickel_slot_h]);
    }
}

module partition_panel() {
    // Пласка деталь на столі друку в площині XY (Z = 0 .. partition_thick)
    // для друку плазом без підтримок з ідеальною якістю отворів
    translate([-part_panel_x_start, part_panel_z_start + part_panel_h, -partition_y_start])
        rotate([90, 0, 0])
            partition_panel_upright();
}

module lid() {
    difference() {
        union() {
            // Пласка кришка з відповідним заокругленням вертикальних кутів
            linear_extrude(lid_thick)
                rounded_rect_2d(outer_x, outer_y, case_corner_radius);
                
            // Внутрішній центруючий бортик (шип) із зазором tolerance
            translate([wall_thick + tolerance, wall_thick + tolerance, lid_thick])
                difference() {
                    cube([inner_x - 2 * tolerance, inner_y - 2 * tolerance, lid_lip_depth]);
                    translate([wall_thick, wall_thick, -0.1])
                        cube([max(0, inner_x - 2 * tolerance - 2 * wall_thick),
                              max(0, inner_y - 2 * tolerance - 2 * wall_thick),
                              lid_lip_depth + 0.2]);
                }
                
            // Передній фіксуючий бортик кришки для притискання знімної передньої панелі
            if (enable_modular_front_panel) {
                translate([panel_x_start, tolerance, lid_thick])
                    cube([panel_w, wall_thick, lid_lip_depth]);
            }
            
            // Поперечний фіксуючий бортик кришки для притискання знімної перегородки
            if (enable_partition && enable_modular_partition) {
                translate([part_panel_x_start, partition_y_start - tolerance / 2, lid_thick])
                    cube([part_panel_w, partition_thick + tolerance, lid_lip_depth]);
            }
                
            // Защіпки (Snap-fit ridges) на бортику кришки
            if (enable_snap_fit) {
                ridge_z = lid_thick + lid_lip_depth / 2 - snap_ridge_height / 2;
                for (sy = [wall_thick + inner_y * 0.3, wall_thick + inner_y * 0.7]) {
                    // Лівий виступ
                    translate([wall_thick + tolerance - snap_ridge_depth, sy - snap_ridge_len / 2, ridge_z])
                        cube([snap_ridge_depth, snap_ridge_len, snap_ridge_height]);
                    // Правий виступ
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
    
    // Візуалізація закритої кришки на корпусі
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

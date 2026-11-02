# Parametric Powerbank Enclosure in OpenSCAD

Parametric 3D model of a powerbank enclosure for OpenSCAD that automatically calculates the body and lid dimensions based on the selected battery type and quantity ($S \times P$), as well as the control board (charge controller) dimensions and cutouts.

---

## 📁 Project Structure

* `powerbank_case.scad` — main model file: dimension calculations, body (`powerbank_body`) and lid (`lid`) generation.
* `presets_batteries.scad` — library of battery cell sizes and battery block preview.
* `presets_boards.scad` — dispatcher and library of cutouts for supported control boards.
* `generated_board_presets.scad` — generated OpenSCAD code based on board JSON profiles (separate front port and top interface cutouts).
* `boards/*.json` — board configuration files with exact coordinates of ports, displays, buttons, and mounts:
  * `abkn_pd45w_3s.json` — ABKN PD45W 3S fast charging module.
  * `UFCS_PD45W.json` — UFCS PD45W module (calibrated Type-C/Type-A and display tolerances).
* `boards/images/` — original board photos for precise visual layout and calibration.
* `tools/server.py` — FastAPI/Uvicorn backend for loading, editing, saving boards and auto-generating SCAD presets.
* `tools/board_sketcher.html` — interactive visual board layout editor using photos with server catalog support, clearance (`clearance`) settings, and direct server save.
* `tools/generate_board_presets.py` — Python OpenSCAD code generator from JSON profiles with `offset(delta = clearance)` support for polygonal cutouts.
* `requirements.txt` — Python dependencies for the local server (`fastapi`, `uvicorn`, `python-multipart`).

---

## 🚀 Quick Start

1. Open `powerbank_case.scad` in [OpenSCAD](https://openscad.org/).
2. In the **"MAIN MODEL SETTINGS"** block, select the battery type, board, and block configuration:

```scad
battery_type = "18650";          // "18650", "liion_pouch_60x110x12", "lifepo4_pouch", "lifepo4_prismatic"
board_type   = "abkn_pd45w_3s";  // "abkn_pd45w_3s", "UFCS_PD45W"
pack_series   = 2;               // Number of series cells S (for 18650 — along Y; for pouch/prismatic — stack along Z)
pack_parallel = 2;               // Number of parallel cells P along X (width)
```

3. Press **F5** for preview or **F6** for final rendering (CSG combination).
4. Export the model to STL for 3D printing (**F7**).

---

## ⚙️ Model Parameters

All key parameters are set at the top of `powerbank_case.scad`:

| Parameter | Default | Description |
| :--- | :--- | :--- |
| `battery_type` | `"18650"` | Battery type (`18650`, `liion_pouch_60x110x12`, `lifepo4_pouch`, `lifepo4_prismatic`) |
| `board_type` | `"abkn_pd45w_3s"` | Board type (`abkn_pd45w_3s`, `UFCS_PD45W`) |
| `pack_series` | `2` | Number of series cells S (for 18650 — along $Y$; for pouch/prismatic — stack along $Z$) |
| `pack_parallel` | `2` | Number of parallel cells P (along $X$, width) |
| `wall_thick` | `2.0` mm | Wall and bottom thickness of the case |
| `tolerance` | `0.6` mm | Base assembly clearance per side for component fit and lid lock |
| `spacing_override` | `-1` | Gap between batteries for ventilation (-1: use standard preset) |
| `inner_xy_margin` | `4` mm | Extra margin along $XY$ (for wires, strips, insulation, BMS board) |
| `inner_z_margin` | `4` mm | Vertical clearance above the board and batteries |
| `case_corner_radius` | `4.0` mm | Radius for rounding vertical edges of the case (0 for sharp corners) |
| `wire_soldering_space` | `45.0` mm | Extra space in the board pocket for convenient wire soldering (40-60 mm) |
| `enable_board_holders` | `true` | Built-in side PCB holders with textolite slot |
| `board_holder_thick` | `1.2` mm | Holder thickness |
| `board_holder_width` | `4.0` mm | Holder width along Y |
| `board_holder_slot_depth` | `1.5` mm | Slot depth for the PCB |
| `board_holder_slot_start` | `5.0` mm | Distance from the front panel to the start of the slot |
| `enable_partition` | `true` | Enable isolating partition between the board pocket and battery block |
| `enable_modular_partition` | `true` | Modular removable partition in U-shaped grooves (`false` — monolithic wall) |
| `partition_thick` | `2.4` mm | Thickness of the protective vertical partition |
| `partition_groove_depth` | `1.2` mm | Depth of guide U-grooves in side walls and bottom of the case |
| `partition_wire_hole_d` | `3.5` mm | Diameter of holes in the partition for power wires |
| `partition_nickel_slot_w` | `8.0` mm | Width of slots for nickel strips |
| `partition_nickel_slot_h` | `1.5` mm | Height/thickness of slots for nickel strips |
| `show_partition` | `true` | Show partition when `part = "all"` |
| `enable_ventilation` | `true` | Enable passive convective cooling (grilles) |
| `vent_type` | `"slots"` | Ventilation shape: `"slots"` (longitudinal cuts) or `"hex"` (honeycomb) |
| `vent_slot_w` | `2.0` mm | Width of linear grille slots |
| `vent_slot_spacing` | `2.5` mm | Pitch/bridge between ventilation slots |
| `vent_hex_radius` | `2.2` mm | Radius of the hexagonal honeycomb cell |
| `vent_placement` | `"sides"` | Grille placement: `"sides"`, `"bottom"`, `"both"` |
| `enable_snap_fit` | `true` | Enable reliable mechanical snap-fits for the lid |
| `snap_ridge_depth` | `0.5` mm | Depth of the snap-fit protrusion for tool-free closure |
| `enable_modular_front_panel` | `true` | Modular removable front panel in grooves (`false` — monolithic case) |
| `front_panel_thick` | `wall_thick` | Thickness of the removable front panel (bezel) |
| `front_panel_groove_depth` | `1.2` mm | Depth of guide U-grooves in walls and bottom of the case |
| `show_front_panel` | `true` | Show removable panel when `part = "all"` |
| `panel_gap` | `8` mm | Gap between parts on the print bed |
| `part` | `"all"` | Part selector for STL export: `"all"`, `"body"`, `"lid"`, `"front_panel"`, `"partition"`, `"assembly"` |
| `show_lid` | `true` | Show the lid next to the body (set `false` to export separately) |
| `show_battery` | `false` | Show semi-transparent battery block preview inside the case |
| `lid_gap` | `8` mm | Distance between the body and lid on the view bed |
| `lid_thick` | `wall_thick` | Thickness of the top lid wall (lid remains flat) |
| `lid_lip_depth`| `2.5` mm | Depth of the inner centering lip of the lid for fixation in the case |

---

## 📐 Geometric Logic and Layout

The model uses front-to-back sequential stacking:
1. **Control board pocket (front, along $Y$):**
   * Placed directly next to the front panel of the case ($Y \in [0 \dots \text{board\\_pocket\\_length}]$).
   * Pocket length: $\text{board\\_pocket\\_length} = \text{board\\_length} + \text{wire\\_soldering\\_space} + 2 \times \text{tolerance}$.
   * Provides $40\dots 60$ mm of free space before the partition for convenient laying and soldering of power and signal wires.
2. **Protective vertical partition (Partition Wall):**
   * In `enable_modular_partition = true` mode, the partition is formed as a separate flat plate `partition_panel()` that slides vertically into internal U-shaped grooves of the case (depth `partition_groove_depth = 1.2` mm).
   * Ensures easy flat 3D printing on the bed without supports with perfect accuracy of holes for power wires ($\varnothing 3.5$ mm) and nickel strips ($8.0 \times 1.5$ mm).
   * **Lid fixation:** the transverse protrusion on the inner side of the lid presses the top edge of the partition when closed, preventing rattling or displacement.
   * With `enable_modular_partition = false`, a monolithic wall `partition_thick` is generated.
3. **Battery compartment (behind the partition, along $Y$):**
   * **18650 (cylindrical):** arranged in the $XY$ plane ($X = \text{pack\_parallel}$, $Y = \text{pack\_series}$, $Z = 1$). Cylinders are precisely centered at positive coordinates ($+X/2, +Z/2, \text{rotate}([-90,0,0])$).
   * **Pouch / Prismatic (flat packs):** series-connected packs $\text{pack\_series}$ are stacked vertically along $Z$ with `spacing` gaps for air circulation and cooling, while parallel $\text{pack\_parallel}$ are placed along the width $X$.
   * **Battery block dimensions:**
     * $X$ (width): $\text{cells\_x} \times \text{battery\_width} + \max(\text{cells\_x} - 1, 0) \times \text{spacing}$
     * $Y$ (length): $\text{cells\_y} \times \text{battery\_length} + \max(\text{cells\_y} - 1, 0) \times \text{spacing}$
     * $Z$ (height): $\text{cells\_z} \times \text{battery\_height} + \max(\text{cells\_z} - 1, 0) \times \text{spacing}$
4. **Total internal space:**
   * $\text{inner\_x} = \max(\text{pack\_width}, \text{board\_width}) + 2 \times \text{tolerance} + \text{inner\_xy\_margin}$
   * $\text{inner\_y} = \text{board\_pocket\_length} + \text{part\_thick} + \text{pack\_length} + \text{inner\_xy\_margin}$
   * $\text{inner\_z} = \max(\text{pack\_height}, \text{board\_height}) + \text{inner\_z\_margin}$
5. **Removable front panel in guide grooves (Modular Slide-in Bezel):**
   * In `enable_modular_front_panel = true` mode, the front wall of the case has a window with U-shaped guide grooves (depth `front_panel_groove_depth = 1.2` mm).
   * The top edge of the grooves remains open, allowing the panel to slide vertically from top to bottom.
   * The panel (`front_panel`) prints separately flat on the print bed ($XY$-plane), ensuring smooth port contours, perfect bridges, and no supports.
   * **Lid lock:** the inner front protrusion of the lid extends into the case directly above the top edge of the panel, rigidly fixing it against falling out or play when connecting cables.
6. **Case rounding and flat lid:**
   * Vertical edges of the case have parametric rounding `case_corner_radius = 4.0` mm for comfortable hand holding.
   * The lid prints as a flat plate with the case contour and an inner pin for fixation in the case.
7. **Multi-projection cutouts (Front vs Top):**
   * Elements with `"face": "front"` (ports, and also display/button for board `abkn_pd45w_3s`) are cut into the removable front panel (`front_panel`) or the monolithic front wall of the case (`powerbank_body`).
   * Elements with `"face": "top"` (displays/buttons for classic boards) are cut into the lid (`lid`).
   * For boards like `abkn_pd45w_3s`, the lid remains completely solid, protecting the board compartment from dust and moisture.

---

## 🖨️ Part Export for 3D Printing (`part`)

Variable `part` allows selecting the required rendering mode for step-by-step export to separate STL files:
* `part = "all"` — places the body, lid, front panel, and partition on the view bed.
* `part = "body"` — renders only the main body for export to `body.stl`.
* `part = "lid"` — renders only the top lid for export to `lid.stl`.
* `part = "front_panel"` — renders the flat front panel on the $Z=0$ plane for export to `front_panel.stl`.
* `part = "partition"` — renders the flat partition on the $Z=0$ plane for export to `partition.stl`.
* `part = "assembly"` — visualizes the fully assembled powerbank (body + installed panel + partition + closed lid) to check fit and clearances.

---

## 🛠️ Working with Boards and the Visual Editor (Board Sketcher)

### Method 1: Via Web Server and Board Sketcher (Recommended)
1. Install dependencies and start the backend server:
   ```bash
   pip install -r requirements.txt
   uvicorn tools.server:app --port 8000 --reload
   ```
2. Open your browser at [http://localhost:8000/](http://localhost:8000/).
3. Select the required board (e.g., `abkn_pd45w_3s` or `UFCS_PD45W`) from the dropdown at the top — the board photo, scale, port contours, and display will load automatically.
4. Adjust coordinates, sizes, or individual clearances (`clearance`) for each port in the properties panel on the right:
   * **USB Type-C:** recommended clearance `0.5 mm` for smooth plug insertion.
   * **USB Type-A:** recommended clearance `0.35 mm`.
   * **Displays and polygons:** automatic extended offset `offset(delta = clearance)` (0.2–0.4 mm).
5. Click **"💾 Save to Server"** — the server will update `boards/<id>.json`, save the photo to `boards/images/`, and automatically regenerate `generated_board_presets.scad`.

### Method 2: Local Offline Mode and Manual OpenSCAD Generation
1. Open `tools/board_sketcher.html` directly in your browser.
2. Upload a photo, calibrate the scale, and create contours.
3. Export the `boards/<id>.json` file.
4. Generate OpenSCAD code manually:
   ```bash
   python3 tools/generate_board_presets.py
   ```

The script will update `generated_board_presets.scad` with ready-made functions `board_params_<id>`, `cutouts_front_<id>`, `cutouts_top_<id>` and updated dispatchers.

---

## 💡 Tips for 3D Printing and Assembly

* **Materials:** Recommended to print with **PETG**, **ABS**, or **ASA** due to their increased heat resistance and mechanical strength compared to PLA.
* **Print orientation:** The body and lid print flat-side down to the bed ($Z=0$), without the need for supports.
* **Clearance calibration:** Before final printing, print a test slice or the first 5 mm of the lid to check `tolerance` for your printer and filament.
* **Electrical safety:**
  * Always provide insulation between battery cells and the board (Kapton tape, textolite, or insulating gaskets).
  * Increase `inner_xy_margin` and `inner_z_margin` if using thick silicone cable or an external BMS board.

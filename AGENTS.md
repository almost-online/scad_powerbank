# AGENTS.md — Instructions for AI Assistants and Developers

This document contains architecture rules, codebase description, geometric conventions, and instructions for AI agents and developers working with this repository.

---

## 🧭 Project Overview

The project is a parametric powerbank enclosure generator for **OpenSCAD**. It allows flexible generation of 3D models for the body and lid under any battery combinations ($S \times P$) and control boards.

### Tech Stack
* **OpenSCAD** — 3D CAD modeling via CSG (Constructive Solid Geometry).
* **Python 3 / FastAPI / Uvicorn** — REST API backend (`tools/server.py`) for board catalog, photos, and persistence.
* **JSON** — declarative description of board geometry and components (`boards/*.json`).
* **HTML5 Canvas / Vanilla JS** — interactive visual board layout editor using photos (`tools/board_sketcher.html`).

---

## 🗺️ Codebase Map and Dependencies

```
PowerBank/
├── powerbank_case.scad          # Main file (parameters, powerbank_body, lid)
├── presets_batteries.scad       # Battery library: sizes, margins, draw_battery_preview
├── presets_boards.scad          # Board library: delegates to generated_board_presets.scad
├── generated_board_presets.scad # Auto-generated SCAD code from boards/*.json (front/top cutouts)
├── boards/                      # Source of truth for control boards (JSON)
│   ├── abkn_pd45w_3s.json
│   ├── UFCS_PD45W.json
│   └── images/                  # Board photos for visual layout (e.g. abkn_pd45w_3s.png)
├── skills/                      # Modular skills for AI agents (Agent Skills)
│   ├── openscad-enclosure-design/SKILL.md # CSG modeling, ventilation, snap-fit rules
│   └── web3d-preview/SKILL.md             # Interactive 3D visualization WebGL/Three.js
├── requirements.txt             # Backend server dependencies (fastapi, uvicorn, python-multipart)
└── tools/
    ├── server.py                 # FastAPI backend for load/save and auto-generation
    ├── generate_board_presets.py # JSON parser -> generated_board_presets.scad
    └── board_sketcher.html       # Interactive board layout tool using photos
```

---

## 📐 Geometric Logic and Modeling Rules

### 1. Base Coordinate System
* Right-handed Cartesian system is used:
  * $+X$ — width (to the right)
  * $+Y$ — length / depth (backwards, from the front panel)
  * $+Z$ — height (upwards)
* Origin $(0,0,0)$ for the main body is located at the left-bottom-front outer corner.

### 2. Front-to-Back Stacking, Partition, and Battery Orientation
* **Front ($Y \in [0 \dots \text{board\_pocket\_length}]$):** Control board pocket:
  * Pocket length: $\text{board\_pocket\_length} = \text{board\_length} + \text{wire\_soldering\_space} + 2 \times \text{tolerance}$, where $\text{wire\_soldering\_space} = 40\dots 60$ mm is allocated for convenient assembly and power wire soldering.
* **Partition ($Y \in [\text{board\_pocket\_length} \dots \text{board\_pocket\_length} + \text{part\_thick}]$):**
  * In modular mode (`enable_modular_partition = true`) the partition is a removable plate (`partition_panel`) that slides into U-shaped guide grooves on the left, right walls and bottom of the body.
  * The partition panel prints flat on the print bed ($XY$-plane), contains round through-holes for wires ($\varnothing 3.5$ mm) and corner slots for nickel strips ($8.0 \times 1.5$ mm), and is pressed from above by the transverse lip of the lid.
* **Back ($Y \in [\text{board\_pocket\_length} + \text{part\_thick} \dots \text{inner\_y}]$):** Battery block:
  * **18650 (cylindrical):** arranged in the $XY$ plane ($X = \text{pack\_parallel}$, $Y = \text{pack\_series}$, $Z = 1$). Cylinders are centered at positive coordinates ($+W/2$ along $X$, $+H/2$ along $Z$, axis along $+Y$).
  * **Pouch / Prismatic (flat packs):** series-connected elements $\text{pack\_series}$ are stacked vertically along the $Z$ axis ($Z = \text{pack\_series}$, $X = \text{pack\_parallel}$, $Y = 1$) with `spacing` gaps for ventilation and air circulation.
* **Case rounding and lid:**
  * Vertical edges of the case have parametric rounding `case_corner_radius = 4.0` mm for ergonomics and quality 3D printing.
  * The lid is modeled as a flat plate that preserves the contour shape of the case.
* **Space formulas:**
  * $\text{pack\_width} = \text{cells\_x} \times \text{battery\_width} + \max(\text{cells\_x} - 1, 0) \times \text{spacing}$
  * $\text{pack\_length} = \text{cells\_y} \times \text{battery\_length} + \max(\text{cells\_y} - 1, 0) \times \text{spacing}$
  * $\text{pack\_height} = \text{cells\_z} \times \text{battery\_height} + \max(\text{cells\_z} - 1, 0) \times \text{spacing}$
  * $\text{inner\_x} = \max(\text{pack\_width}, \text{board\_width}) + 2 \times \text{tolerance} + \text{inner\_xy\_margin}$
  * $\text{inner\_y} = \text{board\_pocket\_length} + \text{part\_thick} + \text{pack\_length} + \text{inner\_xy\_margin}$
  * $\text{inner\_z} = \max(\text{pack\_height}, \text{board\_height}) + \text{inner\_z\_margin}$

### 3. PCB Side Holders
* **Purpose:** Reliable fixation of the control board inside the pocket, preventing vertical displacement and vibration.
* **Parameters:**
  * `enable_board_holders = true` — enable built-in holders.
  * `board_holder_thick = 1.2` mm — holder thickness.
  * `board_holder_width = 4.0` mm — holder width along Y.
  * `board_holder_slot_depth = 1.5` mm — slot depth for the PCB.
  * `board_holder_slot_start = 5.0` mm — distance from the front panel to the start of the slot.
  * `board_holder_slot_gap = 0.2` mm — additional slot clearance over the board thickness.
* **Geometry:** Two side holders (left and right) installed from the bottom of the pocket upwards to `inner_z`. The slot is centered vertically for smooth insertion of a ~1.1 mm thick PCB.
* **Integration:** Holders are added to the body via `union()` in the `powerbank_body()` module, forming a monolithic structure without extra parts.

### 4. Multi-Projection Cutout Modules (Front vs Top vs Side)
* **Front/side cutouts (`draw_board_front_cutouts`):** subtracted from `powerbank_body`. Include ports and elements with `"face": "front"` (e.g., display and button for `abkn_pd45w_3s`).
* **Top interface cutouts (`draw_board_top_cutouts`):** subtracted from `lid` only if they have `"face": "top"`.
* This ensures a clean CSG tree, a solid lid for end-mount boards (`abkn_pd45w_3s`), and eliminates parasitic cuts.

### 5. Avoiding Collisions and Z-Fighting in CSG
* During `difference()` operations, cutouts **must always** extend beyond the body by at least $1$–$2$ mm (e.g., `translate([..., -1, ...])` with $+2$ mm added to length). This prevents zero-surfaces and rendering artifacts (Z-fighting / non-manifold geometry).

### 6. Passive Heat Dissipation (Ventilation Lattice)
* For high-power boards (PD 45W+) and lithium assemblies, parametric ventilation lattices are provided (`enable_ventilation = true`).
* Two lattice types are supported:
  * `vent_type = "slots"` — longitudinal slots with rounded ends (`vent_slot_w`, `vent_slot_spacing`).
  * `vent_type = "hex"` — honeycomb hexagonal structures (`vent_hex_radius`, `vent_hex_wall`).
* Lattice placement (`vent_placement = "sides" | "bottom" | "both"`) automatically accounts for board pocket and battery block dimensions with offsets from power corners.

### 7. Snap-Fit Mechanical Fixation
* Lid fixation can be reinforced with parametric snap-fits (`enable_snap_fit = true`).
* Consists of wedge-shaped protrusions `snap_ridge_depth = 0.5` mm on the lid lip and corresponding internal grooves in the case walls, ensuring reliable closure without screws or glue.

### 8. Modular Removable Elements (Bezel and Partition) in U-Grooves
* **U-shaped guide grooves in the body (`enable_modular_front_panel = true`, `enable_modular_partition = true`):**
  * Side and bottom grooves are recessed into walls by `min(wall_thick / 2, groove_depth)` (default 1.0–1.2 mm).
  * Groove width along $Y$ equals the part thickness plus `tolerance`.
  * The top edge of the grooves is open across the full height, eliminating overhangs and bridges when printing the main body.
* **Part geometry and orientation (`front_panel`, `partition_panel`):**
  * Width: $W = \text{inner\_x} + 2 \times \text{groove\_d} - 2 \times \text{tolerance}$.
  * Height: $H = \text{inner\_z} + \text{groove\_d} - \text{lid\_lip\_depth} - \text{tolerance}$.
  * For printing, parts are placed flat in the $XY$ plane ($Z \in [0 \dots \text{thick}]$) for flawless hole quality without supports.
* **Lid locking (`lid`):**
  * The inner front and transverse lips of the lid extend directly over the top edges of the front panel and partition, completely preventing their vertical movement or play during use.
* **Export selector (`part`):**
  * `part = "all" | "body" | "lid" | "front_panel" | "partition" | "assembly"`.

---

## 📋 Board Preset Rules

1. **Single source of truth — `boards/*.json`:**
   * Do not hardcode cutout coordinates directly in `presets_boards.scad`.
   * When adding a new board or changing sizes/ports, always edit or create the corresponding `boards/<id>.json`.

2. **Board JSON profile format:**
   ```json
   {
     "id": "unique_board_id",
     "name": "Human Readable Name",
     "units": "mm",
     "board": { "width": 55, "length": 65, "height": 16 },
     "ports": [
       { "id": "usb_a", "type": "usb_a", "edge": "front", "offset": 8, "width": 14, "height": 7 }
     ],
     "displays": [
       { "id": "lcd", "face": "top", "x": 15, "y": 10, "width": 25, "length": 12, "clearance": 0.4 }
     ],
     "buttons": [
       { "id": "power", "face": "top", "x": 27.5, "y": 28, "diameter": 6, "clearance": 0.4 }
     ],
     "indicators": []
   }
   ```

3. **Web server and OpenSCAD code generation:**
   - For interactive layout, start the backend:
     ```bash
     uvicorn tools.server:app --port 8000 --reload
     ```
   - When saving a board from `board_sketcher.html`, the server automatically writes `boards/<id>.json`, saves the photo to `boards/images/`, and runs the generator `tools/generate_board_presets.py`.
   - For manual generation without the server, run:
     ```bash
     python3 tools/generate_board_presets.py
     ```
   - The script regenerates `generated_board_presets.scad` with `offset(delta = clearance)` support for polygons.

---

## 🔍 AI Agent Change Validation Checklist

Before completing a task, always verify:
- [ ] **Physical validity of board dimensions:** The sum of port widths and margins on an edge must not exceed the board width (`board.width`).
- [ ] **No port collisions:** Coordinates and sizes of adjacent connectors must not overlap (unless it is a combined/dual-layer connector).
- [ ] **OpenSCAD syntax correctness:** No missing semicolons, matching opening and closing braces `{}`, `[]`, `()`.
- [ ] **Preset synchronization:** All board types in `powerbank_case.scad` are supported in `presets_boards.scad` and `generated_board_presets.scad`.
- [ ] **Print tolerances (`tolerance`):** Ensure all connections (lid, lock `lid_lip_depth`, ports) have parameterized clearances.

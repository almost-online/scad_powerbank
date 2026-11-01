# OpenSCAD Enclosure Design & Mechanical Engineering Skill

## 🎯 Purpose & Scope
This skill provides architectural guidelines, mathematical formulas, and design patterns for engineering high-reliability 3D-printable electronic enclosures using OpenSCAD (Constructive Solid Geometry). It focuses on parametric fit, thermal management (passive convection and lattices), multi-projection face cutouts, and mechanical interlocking (snap-fit joints, alignment ribs, and screw bosses).

---

## 📐 1. FDM Tolerancing & Clearances Matrix

| Material & Feature Type | Standard Clearance (`tolerance`) | Tight Fit / Snap | Loose / Wire Channel |
| :--- | :--- | :--- | :--- |
| **PLA / PETG (0.4mm nozzle)** | `0.40 - 0.60 mm` | `0.20 - 0.30 mm` | `0.80 - 1.50 mm` |
| **ABS / ASA (Shrinkage ~0.8%)** | `0.50 - 0.70 mm` | `0.25 - 0.35 mm` | `1.00 - 1.80 mm` |
| **TPU (Flexible gaskets)** | `0.10 - 0.20 mm` | Interference fit | `0.40 - 0.60 mm` |

### Core Rules for Tolerance Modeling:
1. **Always parameterize tolerances:** Never hardcode nominal dimensions directly into cutout subtractions.
2. **Symmetrical vs Asymmetrical offsets:** For slot/hole widths, apply `+ 2 * tolerance`. For outer rim lip locks, subtract `tolerance` on each side (`width - 2 * tolerance`).
3. **Z-Fighting Prevention:** Always extend subtractive boolean shapes by $+1\dots 2\text{ mm}$ beyond boundary surfaces (e.g., `translate([..., -1, ...]) cube([..., length + 2, ...])`).

---

## 🌬️ 2. Thermal Management & Procedural Ventilation

High-power charging boards (e.g. 45W–100W PD) and high-current battery packs (18650, LiFePO4, Li-ion pouch) require continuous convective airflow.

### A. Linear Slot Grille Pattern
```scad
module vent_slots_2d(width, length, slot_w=2.0, slot_spacing=3.0, corner_r=1.0) {
    pitch = slot_w + slot_spacing;
    count = floor((width - slot_spacing) / pitch);
    start_x = (width - (count * pitch - slot_spacing)) / 2;
    for (i = [0 : count - 1]) {
        translate([start_x + i * pitch, 0])
            hull() {
                translate([slot_w / 2, slot_w / 2]) circle(r=min(corner_r, slot_w/2), $fn=16);
                translate([slot_w / 2, length - slot_w / 2]) circle(r=min(corner_r, slot_w/2), $fn=16);
            }
    }
}
```

### B. Hexagonal Honeycomb Lattice Pattern
Optimal strength-to-weight ratio and maximum open area (>65% airflow permeability):
```scad
module hex_honeycomb_2d(area_w, area_l, cell_r=3.0, wall_t=1.2) {
    dx = sqrt(3) * cell_r + wall_t;
    dy = 1.5 * cell_r + wall_t * sqrt(3) / 2;
    cols = floor(area_w / dx);
    rows = floor(area_l / dy);
    
    intersection() {
        square([area_w, area_l]);
        for (r = [0 : rows]) {
            for (c = [0 : cols]) {
                offset_x = (r % 2 == 1) ? dx / 2 : 0;
                translate([c * dx + offset_x, r * dy])
                    circle(r=cell_r, $fn=6);
            }
        }
    }
}
```

---

## 🔒 3. Mechanical Interlocks & Snap-Fit Joints

Cantilever and annular snap-fit joints allow toolless, secure enclosure assembly:

### Design Formula for Cantilever / Ridge Snaps:
* **Ridge Depth ($y$):** $0.4\dots 0.8\text{ mm}$ (typically $0.5\text{ mm}$ for PLA/PETG).
* **Lead-in Angle ($\alpha$):** $30^\circ\dots 45^\circ$ for smooth push-to-close assembly.
* **Retention Angle ($\beta$):** $75^\circ\dots 90^\circ$ for secure hold against accidental opening.
* **Fillet Radius ($r$):** Add at the root of any flexure tab to reduce stress concentration factor ($K_t < 1.5$).

---

## 📦 4. Multi-Face CSG Projection Pattern

For electronic enclosures where cutouts span multiple orthogonal planes:
1. **Front Face ($XZ$):** Translates relative to front wall $Y=0$, with $Z$ baseline anchored to partition/pocket floor.
2. **Top Face ($XY$):** Applied strictly to lid or top surface with vertical punch-through.
3. **Side Faces ($YZ$):** Applied to left/right walls with outward clearance.

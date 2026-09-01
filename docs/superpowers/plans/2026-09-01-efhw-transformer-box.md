# EFHW Transformer Box Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One OpenSCAD file that produces a PETG-printable base and lid for an EFHW unun on a single FT 240-43, matching [the spec](../specs/2026-09-01-efhw-transformer-box-design.md).

**Architecture:** A single parametric `efhw_box.scad`. The inner cavity is sized for a wound FT 240-43 (1.25 mm wire, clearance for 1.5 mm). The outer language copies the smaller prototype (chamfered SO-239 end, clover tail, four corner screws). `part` selects `base`, `lid`, or `preview`. Walls stay 2.8 mm; a 7 mm top rim is added so a 4 mm sealant trough fits. Python `tests/test_efhw_box.py` checks required tokens and, when `openscad` is on PATH, that CSG/STL export succeeds.

**Tech Stack:** OpenSCAD (no libraries), Python 3 stdlib `unittest`, OpenSCAD CLI for optional render checks.

## Global Constraints

- One model file: `efhw_box.scad`. No external OpenSCAD libraries.
- `part = "base" | "lid" | "preview"`; default `preview`.
- `ratio = 64` or `49`; default `64`. Lid text is two recessed lines: `1:<ratio>` and `250W SSB PEP`.
- Inner cavity: `inner_x = 108`, `inner_y = 85`, `inner_z = 28` mm. Floor/lid/wall: `2.8` mm.
- FDM clearance: `fit_clearance = 0.25` mm on holes.
- Hang orientation: tail up, SO-239 down. M4 on a long side, nearer the tail. Two Ø3 mm drains in the floor at the SO-239 end.
- No toroid clips, no O-ring, no second M4, no heat-set inserts.
- Coordinate system: origin at the XY centre of the cavity; +X toward SO-239; −X toward the tail; +Z up (lid). Z = 0 is the outer bottom of the floor.

---

## File map

| Path | Role |
| --- | --- |
| `efhw_box.scad` | Entire parametric model |
| `tests/test_efhw_box.py` | Token checks + optional OpenSCAD export |
| `README.md` | Print orientation, PETG notes, assembly from the spec |

---

### Task 1: Scaffold parameters, part switch, and tests

**Files:**
- Create: `efhw_box.scad`
- Create: `tests/test_efhw_box.py`

**Interfaces:**
- Consumes: nothing
- Produces: `efhw_box.scad` with all named parameters from the spec; modules `base()`, `lid()`, `preview_assembly()` as empty placeholders; `part` dispatch at the bottom of the file

- [ ] **Step 1: Write the failing test**

Create `tests/test_efhw_box.py`:

```python
#!/usr/bin/env python3
import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCAD = ROOT / "efhw_box.scad"

REQUIRED_PARAMS = [
    "part",
    "ratio",
    "inner_x",
    "inner_y",
    "inner_z",
    "wall",
    "floor_t",
    "lid_t",
    "rim_w",
    "trough_w",
    "trough_d",
    "corner_r",
    "chamfer",
    "fit_clearance",
    "boss_d",
    "boss_pilot_d",
    "tab_len",
    "drain_d",
    "so_flange",
    "so_hole_spacing",
    "so_barrel_d",
    "m4_d",
    "label_depth",
]

REQUIRED_MODULES = [
    "base",
    "lid",
    "preview_assembly",
    "body_outline",
    "cavity",
    "screw_bosses",
    "sealant_trough",
    "mounting_tab",
    "drain_holes",
    "so239_cutout",
    "m4_cutout",
    "lid_label",
]


class TestEfhwBox(unittest.TestCase):
    def test_scad_exists(self):
        self.assertTrue(SCAD.is_file(), f"missing {SCAD}")

    def test_required_params_present(self):
        text = SCAD.read_text(encoding="utf-8")
        missing = [name for name in REQUIRED_PARAMS if name not in text]
        self.assertEqual(missing, [], f"missing params: {missing}")

    def test_default_ratio_is_64(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"ratio\s*=\s*64")

    def test_inner_cavity_matches_spec(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"inner_x\s*=\s*108")
        self.assertRegex(text, r"inner_y\s*=\s*85")
        self.assertRegex(text, r"inner_z\s*=\s*28")
        self.assertRegex(text, r"wall\s*=\s*2\.8")

    def test_required_modules_present(self):
        text = SCAD.read_text(encoding="utf-8")
        missing = [m for m in REQUIRED_MODULES if f"module {m}" not in text]
        self.assertEqual(missing, [], f"missing modules: {missing}")

    def test_part_dispatch_present(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertIn('part == "base"', text)
        self.assertIn('part == "lid"', text)
        self.assertIn('part == "preview"', text)

    def _openscad(self, args):
        exe = shutil.which("openscad")
        if not exe:
            self.skipTest("openscad not on PATH")
        return subprocess.run(
            [exe, *args],
            cwd=ROOT,
            capture_output=True,
            text=True,
            check=False,
        )

    def test_openscad_csg_base(self):
        with tempfile.TemporaryDirectory() as td:
            out = Path(td) / "base.csg"
            r = self._openscad(
                ["-o", str(out), "-D", 'part="base"', str(SCAD)]
            )
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertGreater(out.stat().st_size, 100)


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python3 tests/test_efhw_box.py`

Expected: FAIL on `test_scad_exists` (file not found).

- [ ] **Step 3: Write the scaffold**

Create `efhw_box.scad`. Later tasks fill the placeholder modules; names must already exist so the module test can stay red until those tasks land. For this task only, implement empty modules and the parameter block so `test_scad_exists`, `test_required_params_present`, `test_default_ratio_is_64`, `test_inner_cavity_matches_spec`, and `test_part_dispatch_present` pass. Leave `test_required_modules_present` failing until Task 2 adds the geometry module names — **no:** the test already lists all modules. Add **empty** module stubs now so the token test passes; geometry comes later.

```openscad
// EFHW unun box for FT 240-43 — PETG FDM
// Spec: docs/superpowers/specs/2026-09-01-efhw-transformer-box-design.md

part = "preview"; // "base" | "lid" | "preview"
ratio = 64;       // 64 or 49

inner_x = 108;
inner_y = 85;
inner_z = 28;
wall = 2.8;
floor_t = 2.8;
lid_t = 2.8;

// Top mating face must be wider than wall so a 4 mm trough fits.
rim_w = 7;
flange_out = rim_w - wall; // 4.2 mm outward lip
trough_w = 4;
trough_d = 1;

corner_r = 8;
chamfer = 14;
fit_clearance = 0.25;

boss_d = 9;
boss_pilot_d = 2.5;
boss_pilot_depth = 10;
lid_screw_d = 3.2;
lid_csink_d = 6.5;
lid_csink_h = 1.6;
skirt_h = 5;
skirt_t = 1.6;
skirt_gap = 0.3;

tab_len = 28;
tab_t = wall;
tab_center_hole_d = 8;
tab_side_hole_d = 5;

drain_d = 3;
drain_from_inner_end = 9;
drain_y_off = 18;

so_flange = 25.4;
so_hole_spacing = 18.2;
so_barrel_d = 16.3;
so_screw_d = 3.2;
so_pad_t = 2.5;

m4_d = 4.0;
m4_head_af = 7.0;
m4_head_h = 2.8;
m4_from_tail_inner = 18;

label_depth = 0.6;
label_size_ratio = 12;
label_size_power = 6;

$fn = 48;

function outer_x() = inner_x + 2 * wall + 2 * flange_out;
function outer_y() = inner_y + 2 * wall + 2 * flange_out;
function base_h() = floor_t + inner_z;
function flange_h() = 3.0;

module body_outline(h) {}
module cavity() {}
module screw_bosses() {}
module sealant_trough() {}
module mounting_tab() {}
module drain_holes() {}
module so239_cutout() {}
module m4_cutout() {}
module lid_label() {}

module base() {
    cube([0.1, 0.1, 0.1]);
}

module lid() {
    cube([0.1, 0.1, 0.1]);
}

module preview_assembly() {
    base();
    translate([0, 0, base_h() + 0.2]) lid();
}

if (part == "base") {
    base();
} else if (part == "lid") {
    lid();
} else {
    preview_assembly();
}
```

- [ ] **Step 4: Run tests that should now pass**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_scad_exists TestEfhwBox.test_required_params_present TestEfhwBox.test_default_ratio_is_64 TestEfhwBox.test_inner_cavity_matches_spec TestEfhwBox.test_part_dispatch_present TestEfhwBox.test_required_modules_present`

Expected: all PASS. `test_openscad_csg_base` PASS if OpenSCAD is installed (tiny cube exports), otherwise skipped.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py
git commit -m "$(cat <<'EOF'
Add EFHW box OpenSCAD scaffold and parameter tests.

EOF
)"
```

If `.git` does not exist, run `git init` first. Do not change git config.

---

### Task 2: Body, cavity, chamfered SO-239 end, bosses, trough

**Files:**
- Modify: `efhw_box.scad`
- Modify: `tests/test_efhw_box.py`

**Interfaces:**
- Consumes: parameters from Task 1 (`inner_*`, `wall`, `rim_w`, `flange_out`, `corner_r`, `chamfer`, `boss_*`, `trough_*`)
- Produces: `body_outline(h)` 2D-rounded extruded solid of the outer plan (chamfered +X); `cavity()` subtractive volume; `screw_bosses()` four corner posts inside the trough loop; `sealant_trough()` 4 × 1 mm groove in the top rim; `base()` as those combined

- [ ] **Step 1: Extend the test**

Add to `TestEfhwBox` in `tests/test_efhw_box.py`:

```python
    def test_trough_and_boss_params(self):
        text = SCAD.read_text(encoding="utf-8")
        self.assertRegex(text, r"trough_w\s*=\s*4")
        self.assertRegex(text, r"trough_d\s*=\s*1")
        self.assertRegex(text, r"boss_pilot_d\s*=\s*2\.5")

    def test_body_outline_is_not_empty(self):
        text = SCAD.read_text(encoding="utf-8")
        start = text.index("module body_outline")
        chunk = text[start : start + 800]
        self.assertIn("polygon", chunk)
        self.assertIn("offset", chunk)
```

- [ ] **Step 2: Run the new tests, expect fail**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_body_outline_is_not_empty`

Expected: FAIL (`polygon` not in empty stub).

- [ ] **Step 3: Replace the geometry stubs for body, cavity, bosses, trough, and `base()`**

Replace `module body_outline` through `module base` (keep other stubs) with:

```openscad
module body_outline(h) {
    linear_extrude(height = h)
        offset(r = corner_r)
            offset(delta = -corner_r)
                polygon([
                    [-outer_x() / 2, -outer_y() / 2],
                    [ outer_x() / 2 - chamfer, -outer_y() / 2],
                    [ outer_x() / 2, -outer_y() / 2 + chamfer],
                    [ outer_x() / 2,  outer_y() / 2 - chamfer],
                    [ outer_x() / 2 - chamfer,  outer_y() / 2],
                    [-outer_x() / 2,  outer_y() / 2]
                ]);
}

module inner_outline(h) {
    linear_extrude(height = h)
        offset(r = max(0.1, corner_r - wall))
            offset(delta = -(max(0.1, corner_r - wall)))
                square([inner_x, inner_y], center = true);
}

module cavity() {
    translate([0, 0, floor_t])
        inner_outline(inner_z + 1);
}

module screw_bosses() {
    inset = boss_d / 2 + 1.5;
    positions = [
        [ inner_x / 2 - inset,  inner_y / 2 - inset],
        [ inner_x / 2 - inset, -inner_y / 2 + inset],
        [-inner_x / 2 + inset,  inner_y / 2 - inset],
        [-inner_x / 2 + inset, -inner_y / 2 + inset]
    ];
    for (p = positions) {
        translate([p[0], p[1], floor_t])
            difference() {
                cylinder(d = boss_d, h = inner_z - trough_d);
                translate([0, 0, inner_z - trough_d - boss_pilot_depth])
                    cylinder(d = boss_pilot_d, h = boss_pilot_depth + 0.2);
            }
    }
}

module sealant_trough() {
    ox = outer_x();
    oy = outer_y();
    land = (rim_w - trough_w) / 2;
    translate([0, 0, base_h() - trough_d])
        difference() {
            linear_extrude(height = trough_d + 0.2)
                offset(r = corner_r - land)
                    offset(delta = -(corner_r - land))
                        square([ox - 2 * land, oy - 2 * land], center = true);
            linear_extrude(height = trough_d + 0.4)
                offset(r = max(0.1, corner_r - land - trough_w))
                    offset(delta = -(max(0.1, corner_r - land - trough_w)))
                        square(
                            [ox - 2 * land - 2 * trough_w,
                             oy - 2 * land - 2 * trough_w],
                            center = true
                        );
        }
}

module base() {
    difference() {
        union() {
            difference() {
                body_outline(base_h());
                cavity();
            }
            // Outward flange at the rim so trough_w=4 fits on a 2.8 mm wall.
            translate([0, 0, base_h() - flange_h()])
                difference() {
                    body_outline(flange_h());
                    inner_outline(flange_h() + 0.2);
                }
            screw_bosses();
        }
        sealant_trough();
        drain_holes();
        so239_cutout();
        m4_cutout();
    }
    mounting_tab();
}
```

Note: `drain_holes`, `so239_cutout`, `m4_cutout`, `mounting_tab` stay empty until Tasks 3–4, so they do nothing.

- [ ] **Step 4: Run tests**

Run: `python3 tests/test_efhw_box.py`

Expected: PASS (OpenSCAD CSG of `part="base"` still succeeds; body is now a real shell).

Manually in OpenSCAD: open the file, set `part = "base"`, confirm a hollow rounded box with chamfered +X end, four inner corner bosses, and a groove in the top rim. Confirm bosses sit inward of the groove.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py
git commit -m "$(cat <<'EOF'
Model the box body, cavity, bosses, and sealant trough.

EOF
)"
```

---

### Task 3: Clover mounting tab and drain holes

**Files:**
- Modify: `efhw_box.scad`
- Modify: `tests/test_efhw_box.py`

**Interfaces:**
- Consumes: `tab_*`, `drain_*`, `body_outline` / `outer_x()` from Task 2
- Produces: `mounting_tab()` solid unioned onto −X; `drain_holes()` two Ø3 mm through-holes in the floor at the +X end, ±`drain_y_off` from centre, `drain_from_inner_end` from the inner +X face

- [ ] **Step 1: Write failing checks**

Add:

```python
    def test_tab_and_drain_geometry_keywords(self):
        text = SCAD.read_text(encoding="utf-8")
        tab = text[text.index("module mounting_tab") : text.index("module drain_holes")]
        drain = text[text.index("module drain_holes") : text.index("module so239_cutout")]
        self.assertIn("hull", tab)
        self.assertIn("tab_center_hole_d", tab)
        self.assertIn("drain_d", drain)
        self.assertIn("drain_y_off", drain)
```

- [ ] **Step 2: Run the new test, expect fail**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_tab_and_drain_geometry_keywords`

Expected: FAIL (`hull` not in empty `mounting_tab`).

- [ ] **Step 3: Implement tab and drains**

Replace `module mounting_tab` and `module drain_holes`:

```openscad
module mounting_tab() {
    // Tab grows from the −X outer face. Thickness = tab_t, Z from 0.
    y_spread = 11;
    x_root = -outer_x() / 2;
    x_tip = x_root - tab_len;
    difference() {
        hull() {
            translate([x_root + 1, 0, 0])
                cylinder(d = 22, h = tab_t);
            translate([x_tip + 7, 0, 0])
                cylinder(d = 16, h = tab_t);
            translate([x_tip + 10, y_spread, 0])
                cylinder(d = 12, h = tab_t);
            translate([x_tip + 10, -y_spread, 0])
                cylinder(d = 12, h = tab_t);
        }
        translate([x_tip + 8, 0, -0.1])
            cylinder(d = tab_center_hole_d, h = tab_t + 0.2);
        translate([x_tip + 12, y_spread, -0.1])
            cylinder(d = tab_side_hole_d, h = tab_t + 0.2);
        translate([x_tip + 12, -y_spread, -0.1])
            cylinder(d = tab_side_hole_d, h = tab_t + 0.2);
    }
}

module drain_holes() {
    x = inner_x / 2 - drain_from_inner_end;
    for (s = [-1, 1]) {
        translate([x, s * drain_y_off, -0.1])
            cylinder(d = drain_d + 2 * fit_clearance, h = floor_t + 0.2);
        // Outer chamfer so a drop releases.
        translate([x, s * drain_y_off, -0.01])
            cylinder(d1 = drain_d + 2 + 2 * fit_clearance, d2 = drain_d, h = 1.2);
    }
}
```

`base()` already calls these from Task 2.

- [ ] **Step 4: Run tests and visual check**

Run: `python3 tests/test_efhw_box.py`

Expected: PASS.

In OpenSCAD F5: tail on −X with three holes (centre larger); two floor holes near +X, left and right of centre, not under the future connector axis.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py
git commit -m "$(cat <<'EOF'
Add clover hanging tab and SO-239-end drain holes.

EOF
)"
```

---

### Task 4: SO-239 flange seat and M4 anti-rotation pocket

**Files:**
- Modify: `efhw_box.scad`
- Modify: `tests/test_efhw_box.py`

**Interfaces:**
- Consumes: `so_*`, `m4_*`, `fit_clearance`, `inner_z`, `floor_t`
- Produces: `so239_cutout()` barrel + 4 clearance holes + recess for 25.4 mm flange on the +X wall, flange centred on the end; `m4_cutout()` through-hole in the +Y wall, nearer −X, hex pocket inside for the bolt head

- [ ] **Step 1: Write failing checks**

```python
    def test_so239_and_m4_keywords(self):
        text = SCAD.read_text(encoding="utf-8")
        so = text[text.index("module so239_cutout") : text.index("module m4_cutout")]
        m4 = text[text.index("module m4_cutout") : text.index("module lid_label")]
        self.assertIn("so_flange", so)
        self.assertIn("so_hole_spacing", so)
        self.assertIn("m4_head_af", m4)
        self.assertIn("cylinder", so)
```

- [ ] **Step 2: Run, expect fail**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_so239_and_m4_keywords`

Expected: FAIL.

- [ ] **Step 3: Implement cutouts**

Replace `module so239_cutout` and `module m4_cutout`:

```openscad
module so239_cutout() {
    zc = floor_t + inner_z / 2;
    x_wall = inner_x / 2;
    barrel = so_barrel_d + 2 * fit_clearance;
    screw = so_screw_d + 2 * fit_clearance;
    hs = so_hole_spacing / 2;
    // Barrel through the +X wall and outward flange.
    translate([x_wall - 1, 0, zc])
        rotate([0, 90, 0])
            cylinder(d = barrel, h = wall + flange_out + 2);
    // Four flange screws (clearance in PETG, not tapped).
    for (a = [-1, 1], b = [-1, 1]) {
        translate([x_wall - 1, a * hs, zc + b * hs])
            rotate([0, 90, 0])
                cylinder(d = screw, h = wall + flange_out + 2);
    }
    // Pocket so the 25.4 mm flange sits on a pad, not on 2.8 mm wall edge.
    translate([x_wall - so_pad_t, 0, zc])
        cube([so_pad_t + 0.2, so_flange + 0.4, so_flange + 0.4], center = true);
}

module m4_cutout() {
    zc = floor_t + inner_z / 2;
    x = -inner_x / 2 + m4_from_tail_inner;
    y_wall = inner_y / 2;
    shank = m4_d + 2 * fit_clearance;
    translate([x, y_wall + wall + flange_out + 0.1, zc])
        rotate([90, 0, 0])
            cylinder(d = shank, h = wall + flange_out + so_pad_t + 2);
    // Hex pocket inside, against +Y inner wall, so the head cannot spin.
    translate([x, y_wall - m4_head_h / 2 + 0.01, zc])
        rotate([90, 0, 0])
            cylinder(d = m4_head_af / cos(30) + 2 * fit_clearance, h = m4_head_h, $fn = 6);
}
```

The hex uses `$fn = 6` and diameter = across-corners (`AF / cos(30)`).

- [ ] **Step 4: Run tests and visual check**

Run: `python3 tests/test_efhw_box.py`

Expected: PASS.

In OpenSCAD: +X face has a round barrel and four screw holes around it; flange pocket visible from inside. +Y wall has one M4 hole closer to the tail, hex seat inside. Confirm `inner_z = 28` clears a 25.4 mm flange centred on the wall. Confirm a Ø79 × 22 mm cylinder at the origin (Z from `floor_t`) does not hit bosses — use a temporary `color("red") cylinder(d=79, h=22);` at `translate([0,0,floor_t+3])` then delete it.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py
git commit -m "$(cat <<'EOF'
Cut SO-239 flange seat and inside-out M4 terminal.

EOF
)"
```

---

### Task 5: Lid with outer skirt, aligned screw holes, countersink

**Files:**
- Modify: `efhw_box.scad`
- Modify: `tests/test_efhw_box.py`

**Interfaces:**
- Consumes: `lid_t`, `skirt_*`, `lid_screw_d`, `lid_csink_*`, `boss_d` positions (must match `screw_bosses()` inset formula `inner_* / 2 - (boss_d/2 + 1.5)`), `body_outline`, `outer_x()`, `outer_y()`, `base_h()`
- Produces: `lid()` as a printable solid. When `part == "lid"`, the inner face lies on Z = 0 (print inner-down). When used from `preview_assembly()`, the lid sits on the base rim. The skirt covers the outward flange, not the tail. No lid over the tab.

- [ ] **Step 1: Write failing checks**

```python
    def test_lid_has_skirt_and_countersink(self):
        text = SCAD.read_text(encoding="utf-8")
        lid = text[text.index("module lid_shell") : text.index("module preview_assembly")]
        self.assertIn("skirt_h", lid)
        self.assertIn("lid_csink_d", lid)
        self.assertIn("body_outline", lid)
```

- [ ] **Step 2: Run, expect fail**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_lid_has_skirt_and_countersink`

Expected: FAIL (`lid()` is still a tiny cube).

- [ ] **Step 3: Implement `lid()` and keep `part == "lid"` print orientation**

Replace `module lid` and `module preview_assembly` and the bottom `if` chain:

```openscad
module lid_screw_holes() {
    inset = boss_d / 2 + 1.5;
    positions = [
        [ inner_x / 2 - inset,  inner_y / 2 - inset],
        [ inner_x / 2 - inset, -inner_y / 2 + inset],
        [-inner_x / 2 + inset,  inner_y / 2 - inset],
        [-inner_x / 2 + inset, -inner_y / 2 + inset]
    ];
    for (p = positions) {
        translate([p[0], p[1], -0.1])
            cylinder(d = lid_screw_d + 2 * fit_clearance, h = lid_t + 0.2);
        translate([p[0], p[1], lid_t - lid_csink_h])
            cylinder(d1 = lid_screw_d, d2 = lid_csink_d, h = lid_csink_h + 0.05);
    }
}

module lid_shell() {
    difference() {
        union() {
            body_outline(lid_t);
            // Skirt hangs down in assembled space (−Z from lid inner face).
            translate([0, 0, -skirt_h])
                difference() {
                    linear_extrude(height = skirt_h)
                        offset(delta = skirt_t + skirt_gap)
                            projection() body_outline(1);
                    linear_extrude(height = skirt_h + 0.2)
                        offset(delta = skirt_gap)
                            projection() body_outline(1);
                }
        }
        lid_screw_holes();
        translate([0, 0, lid_t - label_depth])
            lid_label();
    }
}

module lid() {
    // Print / export: inner face on Z=0, skirt in −Z. Slicer: rotate if needed
    // so the inner face is on the bed (skirt points up after a 180° flip).
    // Spec: print inner-face down. Place inner face at Z=0 facing −Z skirt
    // then rotate for bed:
    rotate([180, 0, 0])
        translate([0, 0, -lid_t])
            lid_shell();
}

module preview_assembly() {
    color("DimGray") base();
    color("Gray")
        translate([0, 0, base_h() + 0.15])
            lid_shell();
}

if (part == "base") {
    base();
} else if (part == "lid") {
    lid();
} else {
    preview_assembly();
}
```

`lid_label()` is still empty, so the label subtract does nothing until Task 6.

Print orientation note: `lid()` rotates so the **outer** face is on the bed if we `rotate([180])` with inner at +Z... Spec: inner face down on the bed, skirt grows up. Then:

- Inner face = first layers = Z=0 in the STL
- Skirt extends +Z
- Outer face (with future label) is the last layers at Z = lid_t

Correct `lid()` for print:

```openscad
module lid() {
    translate([0, 0, lid_t])
        rotate([180, 0, 0])
            lid_shell();
}
```

If `lid_shell()` has plate at Z=0…`lid_t` and skirt at Z=−`skirt_h`…0, then `rotate([180])` then `translate([0,0,lid_t])` puts the inner face (originally Z=0) at Z=`lid_t` after rotation... Let's compute:

`lid_shell`: inner/top plate Z=0 to lid_t (outer at lid_t), skirt Z=−skirt_h to 0.

We want inner face on bed (Z=0) and outer (with label) at +lid_t as last layers, skirt +Z.

Inner face of shell is Z=0 (bottom of plate). Outer is Z=lid_t. Skirt is negative Z — bad for bed.

For print inner-down: put inner at Z=0, skirt going +Z (up). That means the plate's inner face is down, outer face is up. So plate at Z=0 (inner) to Z=lid_t (outer), skirt from Z=0 to Z=skirt_h around the outside. Then `lid_shell` should be rebuilt:

```openscad
module lid_shell() {
    difference() {
        union() {
            body_outline(lid_t);
            translate([0, 0, 0])
                difference() {
                    linear_extrude(height = skirt_h)
                        offset(delta = skirt_t + skirt_gap)
                            projection() body_outline(1);
                    linear_extrude(height = skirt_h + 0.2)
                        offset(delta = skirt_gap)
                            projection() body_outline(1);
                }
        }
        lid_screw_holes(); // countersink on OUTER face: Z = lid_t
        translate([0, 0, lid_t - label_depth])
            lid_label();
    }
}
```

Skirt and plate both in +Z: the skirt overlaps the plate thickness (union). Countersink at outer Z=lid_t. For **preview**, this lid_shell is upside-down relative to the box (skirt should hang down). So:

- `part == "lid"`: `lid_shell()` as-is (print pose: inner at Z=0, outer up, skirt up — wait, if both plate and skirt are +Z, inner is Z=0, skirt also starts at 0 and goes up, sitting beside the plate. That's print-inner-down with skirt as walls going up. Good.
- `preview_assembly`: rotate lid_shell 180° about X and place inner face on `base_h()`.

```openscad
module lid() {
    lid_shell(); // print orientation
}

module preview_assembly() {
    color("DimGray") base();
    color("Gray")
        translate([0, 0, base_h() + lid_t + 0.15])
            rotate([180, 0, 0])
                lid_shell();
}
```

Use this orientation, not the first `lid()` draft. Countersink: `lid_screw_holes` must cut from the outer face (`Z = lid_t`), which is the top during print.

- [ ] **Step 4: Run tests and visual check**

Run: `python3 tests/test_efhw_box.py`

Expected: PASS.

OpenSCAD: `part = "preview"` — lid sits on the rim, four holes line up with bosses, skirt wraps the flange, tab is not covered. `part = "lid"` — inner face on XY, skirt upward, countersinks on the top (outer) face.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py
git commit -m "$(cat <<'EOF'
Add lid with rain skirt and countersunk screw holes.

EOF
)"
```

---

### Task 6: Lid label, README, render both parts

**Files:**
- Modify: `efhw_box.scad`
- Modify: `tests/test_efhw_box.py`
- Create: `README.md`

**Interfaces:**
- Consumes: `ratio`, `label_depth`, `label_size_ratio`, `label_size_power`
- Produces: `lid_label()` two-line recessed text, readable with tail (−X) at the top; `README.md` print and assembly notes; tests for both ratio strings and STL export of base and lid

- [ ] **Step 1: Write failing checks**

```python
    def test_label_uses_ratio_and_power_line(self):
        text = SCAD.read_text(encoding="utf-8")
        lab = text[text.index("module lid_label") : text.index("module lid_screw_holes")]
        self.assertIn("250W SSB PEP", lab)
        self.assertIn("str(\"1:\"", lab)
        self.assertIn("text", lab)

    def test_openscad_stl_base_and_lid(self):
        with tempfile.TemporaryDirectory() as td:
            for p, name in [("base", "base.stl"), ("lid", "lid.stl")]:
                out = Path(td) / name
                r = self._openscad(
                    ["-o", str(out), "-D", f'part="{p}"', str(SCAD)]
                )
                self.assertEqual(r.returncode, 0, r.stderr)
                self.assertGreater(out.stat().st_size, 10_000, name)
```

If `module lid_screw_holes` is defined before `lid_label`, slice from `module lid_label` to `module lid_shell` instead. After Task 5 the order in the file should be: `lid_label` (stub), then `lid_screw_holes`, `lid_shell`, `lid`, `preview_assembly`. Keep `lid_label` **above** `lid_shell` and slice the test to `module lid_screw_holes` only if that order is true. Implement `lid_label` in place of the stub; do not reorder in a way that breaks Task 5's `lid()` slice (`module lid()` to `module preview_assembly`).

- [ ] **Step 2: Run, expect fail**

Run: `python3 tests/test_efhw_box.py TestEfhwBox.test_label_uses_ratio_and_power_line`

Expected: FAIL (`text` not in stub).

- [ ] **Step 3: Implement label and README**

Replace `module lid_label`:

```openscad
module lid_label() {
    // Recessed into the outer face. Readable when tail (−X) is up:
    // rotate 90° so the baseline runs across the short axis, top of glyphs
    // toward −X.
    linear_extrude(height = label_depth + 0.1) {
        rotate([0, 0, 90]) {
            translate([0, 4, 0])
                text(
                    str("1:", ratio),
                    size = label_size_ratio,
                    font = "Liberation Sans:style=Bold",
                    halign = "center",
                    valign = "center"
                );
            translate([0, -8, 0])
                text(
                    "250W SSB PEP",
                    size = label_size_power,
                    font = "Liberation Sans:style=Bold",
                    halign = "center",
                    valign = "center"
                );
        }
    }
}
```

If Liberation Sans is missing on the build machine, switch `font` to `"Liberation Sans"` without style, then to the OpenSCAD default by omitting `font`. Do not introduce a second `.scad` file.

Create `README.md`:

```markdown
# EFHW transformer box (FT 240-43)

OpenSCAD enclosure for a 1:49 or 1:64 EFHW unun on one FT 240-43. Print in PETG.

## Open the model

- `part = "preview"` — assembled view
- `part = "base"` — export the box
- `part = "lid"` — export the lid (inner face on the bed, skirt up)
- `ratio = 64` (default) or `49` — lid text `1:64` / `1:49` plus `250W SSB PEP`

File: `efhw_box.scad`. No libraries.

## Print (PETG)

- Layer 0.2 mm, at least 3 perimeters (walls are 2.8 mm).
- Base: cavity up. Trough, bosses, and tab need no supports.
- Lid: inner face on the bed. Skirt grows up. Label recesses in the last layers.
- Do not drill holes after printing.

## Fit

Cavity 85 × 108 × 28 mm is sized for ПЭТВ-2 1.25 mm on FT 240-43, with room for 1.5 mm. A Ø79 × 22 mm wound-core envelope must clear the corner bosses.

## Assembly

1. Fit SO-239, four M3 through the flange (clearance holes in PETG).
2. Fit M4 from inside; washer and nut outside after soldering the radiator.
3. Seat the toroid; optional silicone in the centre hole. No clips.
4. Solder: centre pin, flange ground, M4 tap.
5. Neutral-cure silicone bead in the rim trough.
6. Lid, four ~M3×10–12 mm self-tappers into the bosses (pilot 2.5 mm).
7. Leave the two drain holes at the SO-239 end open.

Hang from the tab; SO-239 points down.

## Tests

`python3 tests/test_efhw_box.py`

OpenSCAD CLI is optional; without it, render checks are skipped.
```

- [ ] **Step 4: Run all tests**

Run: `python3 tests/test_efhw_box.py -v`

Expected: all PASS. With OpenSCAD: both STLs > 10 KB. In the GUI, `ratio = 49` changes the first line; text does not hit screw countersinks; glyphs are upright with the tab at the top of the screen if −X is up.

- [ ] **Step 5: Commit**

```bash
git add efhw_box.scad tests/test_efhw_box.py README.md
git commit -m "$(cat <<'EOF'
Add lid ratio label, print notes, and STL export checks.

EOF
)"
```

---

## Self-review (plan vs spec)

| Spec item | Task |
| --- | --- |
| Single `efhw_box.scad`, no libraries | 1–6 |
| `part` base/lid/preview | 1, 5 |
| `ratio` 64 default / 49 | 1, 6 |
| Cavity 85 × 108 × 28, wall 2.8 | 1–2 |
| Chamfered SO-239 end, rounded corners | 2 |
| Bosses inside trough, pilot 2.5 mm, not through floor | 2 |
| Sealant trough 4 × 1 mm, no O-ring | 2 |
| Clover tab, three holes | 3 |
| Two Ø3 drains at SO-239 end with chamfer | 3 |
| SO-239 25.4 / 18.2 / 16.3, M3 clearance | 4 |
| One M4 from inside, hex pocket, nearer tail | 4 |
| Lid skirt outside flange, not over tab | 5 |
| Recessed two-line label 0.6 mm | 6 |
| Print poses PETG | 6 README |
| Ø79 × 22 mm core clearance | 4 visual + 6 README |
| Assembly steps | 6 README |

No second core, no clips, no heat-set inserts, no O-ring — not in any task.

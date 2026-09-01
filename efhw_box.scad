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
function wall_x() = inner_x + 2 * wall;
function wall_y() = inner_y + 2 * wall;
function base_h() = floor_t + inner_z;
function flange_h() = 3.0;

module body_outline(h) {
    linear_extrude(height = h)
        offset(delta = wall + flange_out)
            chamfered_profile();
}

// Every mating perimeter is a true offset of this inner cavity profile.
module chamfered_profile() {
    inner_corner_r = max(0.1, corner_r - wall);
    offset(r = inner_corner_r)
        offset(delta = -inner_corner_r)
            polygon([
                [-inner_x / 2, -inner_y / 2],
                [ inner_x / 2 - chamfer, -inner_y / 2],
                [ inner_x / 2, -inner_y / 2 + chamfer],
                [ inner_x / 2,  inner_y / 2 - chamfer],
                [ inner_x / 2 - chamfer,  inner_y / 2],
                [-inner_x / 2,  inner_y / 2]
            ]);
}

module wall_outline(h) {
    linear_extrude(height = h)
        offset(delta = wall)
            chamfered_profile();
}

module inner_outline(h) {
    linear_extrude(height = h)
        chamfered_profile();
}

module cavity() {
    translate([0, 0, floor_t])
        inner_outline(inner_z + 1);
}

module screw_bosses() {
    inset = boss_d / 2 + 1.5;
    chamfer_inset = chamfer / 2;
    positions = [
        [ inner_x / 2 - inset - chamfer_inset,
          inner_y / 2 - inset - chamfer_inset],
        [ inner_x / 2 - inset - chamfer_inset,
         -inner_y / 2 + inset + chamfer_inset],
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
    land = (rim_w - trough_w) / 2;
    translate([0, 0, base_h() - trough_d])
        difference() {
            linear_extrude(height = trough_d + 0.2)
                offset(delta = wall + flange_out - land)
                    chamfered_profile();
            linear_extrude(height = trough_d + 0.4)
                offset(delta = wall + flange_out - land - trough_w)
                    chamfered_profile();
        }
}

module mounting_tab() {
    // Tab grows from the −X wall face. Thickness = tab_t, Z from 0.
    y_spread = 11;
    x_root = -wall_x() / 2;
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
module so239_cutout() {
    zc = floor_t + inner_z / 2;
    x_wall = inner_x / 2;
    barrel = so_barrel_d + 2 * fit_clearance;
    screw = so_screw_d + 2 * fit_clearance;
    hs = so_hole_spacing / 2;
    through_h = wall + 2;
    pocket_d = wall - so_pad_t;

    // Barrel through the 2.8 mm +X wall, with clean-cut overlap.
    translate([x_wall - 1, 0, zc])
        rotate([0, 90, 0])
            cylinder(d = barrel, h = through_h);
    // Four M3 clearance holes matching the square SO-239 flange.
    for (a = [-1, 1], b = [-1, 1]) {
        translate([x_wall - 1, a * hs, zc + b * hs])
            rotate([0, 90, 0])
                cylinder(d = screw, h = through_h);
    }
    // Shallow flange pocket leaves so_pad_t of plastic as the seat.
    translate([
        x_wall + so_pad_t,
        -(so_flange + 0.4) / 2,
        zc - (so_flange + 0.4) / 2
    ])
        cube([pocket_d + 0.2, so_flange + 0.4, so_flange + 0.4]);
}

module m4_cutout() {
    zc = floor_t + inner_z / 2;
    x = -inner_x / 2 + m4_from_tail_inner;
    y_wall = inner_y / 2;
    shank = m4_d + 2 * fit_clearance;

    // Round shank through the 2.8 mm +Y wall only.
    translate([x, y_wall + wall + 1, zc])
        rotate([90, 0, 0])
            cylinder(d = shank, h = wall + 2);
    // Hex recess opens inward and captures the inside bolt head.
    translate([x, y_wall + m4_head_h - 0.01, zc])
        rotate([90, 0, 0])
            cylinder(
                d = m4_head_af / cos(30) + 2 * fit_clearance,
                h = m4_head_h,
                $fn = 6
            );
}
module lid_label() {}

module base() {
    difference() {
        union() {
            difference() {
                wall_outline(base_h());
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
} else if (part == "preview") {
    preview_assembly();
}

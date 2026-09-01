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
} else if (part == "preview") {
    preview_assembly();
}

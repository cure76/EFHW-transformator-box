// Retrofit FR4 standoffs for a box printed without floor pads.
// Print 4 spacers; drill the floor with the jig; M3 through-bolts.
// Same XY as fr4_bosses() in the enclosure files.

part = "standoffs"; // "standoffs" | "jig"

inner_x = 108;
inner_y = 85;
chamfer = 14;
corner_r = 8;
wall = 2.8;
boss_d = 12;

fr4_boss_d = 16;
fr4_boss_h = 6;
fr4_boss_y = 16;
fr4_tail_drop = 10;
m3_clear_d = 3.2;          // through-hole for M3×12 (floor + spacer + FR4)
jig_t = 1.2;

$fn = 48;

function boss_inset() = boss_d / 2 + 1.5;

function so239_boss_xy(sy) =
    let (
        inset = boss_inset(),
        cy = sy * (inner_y / 2 - inset),
        cx = inner_x / 2 + inner_y / 2 - chamfer
            - abs(cy) - inset * sqrt(2)
    ) [cx, cy];

function tail_boss_xy(sy) =
    [-inner_x / 2 + boss_inset(), sy * (inner_y / 2 - boss_inset())];

function fr4_pad_xy(sx, sy) = [
    sx > 0 ? so239_boss_xy(1)[0] : tail_boss_xy(1)[0] + fr4_tail_drop,
    sy * fr4_boss_y
];

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

module fr4_standoff() {
    difference() {
        cylinder(d = fr4_boss_d, h = fr4_boss_h);
        translate([0, 0, -0.1])
            cylinder(d = m3_clear_d, h = fr4_boss_h + 0.2);
    }
}

module standoffs_print() {
    pitch = fr4_boss_d + 4;
    for (i = [0:1], j = [0:1])
        translate([i * pitch, j * pitch, 0])
            fr4_standoff();
}

module drill_jig() {
    difference() {
        linear_extrude(height = jig_t)
            chamfered_profile();
        for (sx = [-1, 1], sy = [-1, 1]) {
            p = fr4_pad_xy(sx, sy);
            translate([p[0], p[1], -0.1])
                cylinder(d = m3_clear_d, h = jig_t + 0.2);
        }
        // Finger hole to lift the jig out of the cavity.
        cylinder(d = 18, h = jig_t + 0.2, center = true);
    }
}

if (part == "jig") {
    drill_jig();
} else if (part == "standoffs") {
    standoffs_print();
}

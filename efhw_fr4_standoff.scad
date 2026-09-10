// Retrofit FR4 standoffs for a box printed without floor pads.
// Print 4 spacers; drill the floor with the jig; M3 through-bolts.
// Same XY as fr4_bosses() in the enclosure files.

part = "standoffs"; // "standoffs" | "jig"

fr4_boss_d = 16;
fr4_boss_h = 6;
m3_clear_d = 3.2;          // through-hole for M3×12 (floor + spacer + FR4)
jig_x = 80;
jig_y = 55;
jig_t = 1.2;
jig_finger_d = 8;
jig_edge = 6;              // hole centre to every plate edge
fr4_boss_x = jig_x / 2 - jig_edge;
fr4_boss_y = jig_y / 2 - jig_edge;

$fn = 48;

function fr4_pad_xy(sx, sy) = [sx * fr4_boss_x, sy * fr4_boss_y];

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
        translate([-jig_x / 2, -jig_y / 2, 0])
            cube([jig_x, jig_y, jig_t]);
        for (sx = [-1, 1], sy = [-1, 1]) {
            p = fr4_pad_xy(sx, sy);
            translate([p[0], p[1], -0.1])
                cylinder(d = m3_clear_d, h = jig_t + 0.2);
        }
        translate([0, 0, -0.1])
            cylinder(d = jig_finger_d, h = jig_t + 0.2);
    }
}

if (part == "jig") {
    drill_jig();
} else if (part == "standoffs") {
    standoffs_print();
}

// Picopresso Shot Splitter v2 - open-top pool splitter
//
// One open basin standing on four legs across two cups. Whatever lands in
// the basin runs down into a level trough. Two identical outlet holes sit
// at the ends of the trough, one above each cup. The trough fills into a
// small pool whose surface is level, so both holes see the same pressure
// and pass the same flow, regardless of where the coffee was poured.
//
// Single part, no enclosed cavities, prints upright without supports.
//
// Coordinates: z = 0 is the underside (the cup-rim plane).
// The outlets sit on the X axis, so the cups stand along X.

/* [Render] */
part = "splitter"; // [splitter, preview]
show_cups = true;  // ghost cups in the preview

/* [Basin] */
mouth_d  = 60;   // inner diameter of the basin mouth
top_z    = 34;   // rim height above the cup rims
wall     = 1.8;
outlet_x = 14;   // outlet distance from centre (one per cup)
outlet_d = 2.0;  // outlet bore; drill both to the same size after printing
trough_r = 5;    // radius of the level trough joining the outlets
floor_z  = 3.6;  // trough bottom height above the cup rims
foot_r   = 6;    // half-width of the flat foot under the trough

/* [Drip tips] */
tip_wall = 1.2;
recess_r = 4.4;  // drip-break recess radius at the underside (45 degree cone)

/* [Legs] */
leg_angle  = 50; // from the cup axis
leg_len    = 60; // centre to tip
leg_root_w = 8;
leg_tip_w  = 6;
leg_root_h = 6;
leg_tip_h  = 3;

/* [Ghost cups (preview only)] */
cup_d = 70;
cup_h = 75;

/* [Hidden] */
$fa = 2;
$fs = 0.3;
eps = 0.01;

mouth_r  = mouth_d / 2;
trough_z = floor_z + trough_r;           // trough axis height
tip_ro   = outlet_d / 2 + tip_wall;
lip_r    = wall * 0.7;

assert(recess_r < foot_r - 1, "drip recess breaks through the foot");
assert(floor_z > recess_r - tip_ro + 1.2, "floor too thin above the drip recess");

// ---------------------------------------------------------------- parts

module trough_spheres(r) {
    for (s = [-1, 1])
        translate([s * outlet_x, 0, trough_z]) sphere(r = r);
}

module basin_cavity() {
    hull() {
        translate([0, 0, top_z]) cylinder(r = mouth_r, h = 5);
        trough_spheres(trough_r);
    }
}

module basin_body() {
    // bowl shell with a rounded rim
    hull() {
        translate([0, 0, top_z - lip_r])
            rotate_extrude() translate([mouth_r + lip_r, 0]) circle(r = lip_r);
        trough_spheres(trough_r + wall);
    }
    // foot under the trough
    hull() {
        for (s = [-1, 1]) translate([s * outlet_x, 0, 0]) cylinder(r = foot_r, h = eps);
        trough_spheres(trough_r + wall);
    }
}

module legs() {
    for (a = [leg_angle, -leg_angle, 180 - leg_angle, 180 + leg_angle])
        rotate(a)
            hull() {
                cylinder(d = leg_root_w, h = leg_root_h);
                translate([leg_len, 0, 0]) cylinder(d = leg_tip_w, h = leg_tip_h);
            }
}

module outlets() {
    for (s = [-1, 1])
        translate([s * outlet_x, 0, 0]) {
            translate([0, 0, -1]) cylinder(d = outlet_d, h = floor_z + 2);
            // drip break: 45 degree recess leaves a free-standing tip
            difference() {
                translate([0, 0, -eps])
                    cylinder(h = recess_r - tip_ro + eps, r1 = recess_r + eps, r2 = tip_ro);
                translate([0, 0, -1]) cylinder(r = tip_ro, h = recess_r + 1);
            }
        }
}

module splitter() {
    difference() {
        union() {
            basin_body();
            legs();
        }
        basin_cavity();
        outlets();
    }
}

module ghost_cups() {
    for (s = [-1, 1])
        translate([s * cup_d / 2, 0, -cup_h])
            difference() {
                cylinder(d = cup_d, h = cup_h);
                translate([0, 0, 6]) cylinder(d = cup_d - 6, h = cup_h);
            }
}

// ---------------------------------------------------------------- output

if (part == "preview") {
    color("#2f3b3a") splitter();
    if (show_cups) %ghost_cups();
} else {
    splitter();
}

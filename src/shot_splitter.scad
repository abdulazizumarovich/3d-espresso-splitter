// Picopresso Shot Splitter v3 - "culvert" level-pool splitter
//
// No ball, no insert, no moving parts. A flat ring rests on the rims of two
// cups standing side by side. Coffee poured anywhere into the funnel
// collects in a pool at its bottom, and the pool drains through two
// identical 1.6 mm bores that sit side by side on the cup axis. Both bores
// have the same depth of coffee above them, so they pass the same flow.
//
// - A small roof over the bores sheds a direct stream. The pool reaches the
//   bores only through the two open ends of a short culvert, and both ends
//   lie on the mirror plane between the cups.
// - The bores are printed undersize and reamed together with one drill in
//   one pass, so they come out the same size.
// - Each bore empties onto its own open chute, which ends in a drip lip
//   over its cup. The two sides share no wetted surface after the split.
//
// One part, printed upright without supports (one short flat bridge under
// the keel).
//
// Coordinates: z = 0 is the underside (the cup-rim plane). The cups stand
// along X and touch at x = 0.

/* [Render] */
part = "splitter"; // [splitter, preview, cavity]
show_cups = true;  // ghost cups in the preview

/* [Funnel] */
mouth_d    = 76;   // inner diameter of the funnel mouth
wall_angle = 46;   // shallowest funnel wall, degrees from horizontal
shell      = 1.2;  // funnel wall thickness

/* [Culvert and bores] */
keel_top  = 13.3;  // funnel bottom
keel_x    = 5;     // keel half width; the bore exits are on its outer faces
keel_y    = 9;     // keel half length
culvert_x = 2;     // culvert inner half width
roof_y    = 5.7;   // the culvert is roofed for |y| <= roof_y
apron_y   = 7.7;   // open inlet aprons for roof_y < |y| <= apron_y
floor_z   = 8;     // culvert floor
floor_t   = 1.6;
vent_rise = 0.4;   // culvert ceiling rises toward both ends to let air out
bore_d    = 1.6;   // final bore, reamed after printing
pilot_d   = 1.2;   // printed pilot

/* [Chutes] */
chute_y   = 7;     // chute half width
land      = 1;     // level land below each bore exit
lip_x     = 12.5;  // drip lip edge
lip_edge  = 0.6;   // height of the drip edge above the 45 degree undercut
foot      = 1.2;   // flat bed contact under each lip

/* [Ring holder] */
ring_r      = 46;  // centreline radius
ring_w      = 4;
ring_h      = 2.4;
strut_w     = 3;
strut_t     = 3.5;
strut_top_r = 20;  // the struts merge into the funnel near this radius
mark_d      = 0.6; // depth of the engraved arrows over the bore axis

/* [Ghost cups (preview only)] */
cup_d = 70;
cup_h = 75;

/* [Hidden] */
$fa = 2;
$fs = 0.3;
e = 0.01;

mouth_r = mouth_d / 2;
top_z   = keel_top + (mouth_r - keel_x) * tan(wall_angle);
shell_h = shell / sin(wall_angle);   // horizontal offset of the outer wall
shell_v = shell / cos(wall_angle);   // vertical offset of the outer wall
bore_z  = floor_z + bore_d / 2;      // reamed bore bottom is flush with the floor
land_z  = floor_z - 0.1;             // chute land just below the bore exit
keel_z0 = floor_z - floor_t;         // flat bridged underside of the keel

assert(pilot_d < bore_d, "pilot must be smaller than the reamed bore");
assert(keel_z0 > land_z - 2.2, "keel bridge must sit on the chute heads");

// ---------------------------------------------------------------- helpers

module slab(x0, x1, y0, y1, z0, z1)
    translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);

// prism along Y with a 45 degree gable: base half-width hw at z0, length +-y
module gable(hw, z0, y0, y1)
    hull() {
        slab(-hw, hw, y0, y1, z0 - e, z0);
        slab(-e, e, y0, y1, z0, z0 + hw);
    }

// ---------------------------------------------------------------- funnel

module funnel_cavity()
    hull() {
        translate([0, 0, top_z]) cylinder(r = mouth_r, h = 5);
        slab(-keel_x, keel_x, -apron_y, apron_y, keel_top, keel_top + e);
    }

module funnel_outer()
    hull() {
        translate([0, 0, top_z - e]) cylinder(r = mouth_r + shell_h, h = e);
        slab(-keel_x, keel_x, -keel_y, keel_y, keel_top - shell_v, keel_top - shell_v + e);
    }

// ---------------------------------------------------------------- keel

module keel() {
    hull() {   // flat bridged underside over the chutes, 45 degree chamfer beyond
        slab(-keel_x, keel_x, -chute_y, chute_y, keel_z0, keel_top);
        slab(-keel_x, keel_x, -keel_y, keel_y, keel_z0 + (keel_y - chute_y), keel_top);
    }
    gable(keel_x, keel_top, -roof_y, roof_y);   // roof that sheds a direct stream
}

// culvert cross-section at y: level floor, vertical walls, 45 degree gable
module culvert_section(y, wall_top) {
    slab(-culvert_x, culvert_x, y - e, y + e, floor_z, wall_top);
    gable(culvert_x, wall_top, y - e, y + e);
}

module culvert_cavity() {
    // the ceiling rises toward both open ends so air and foam can escape
    for (s = [-1, 1])
        hull() {
            culvert_section(0, 11);
            culvert_section(s * apron_y, 11 + vent_rise);
        }
    // open inlet aprons with 45 degree chamfers down from the funnel bottom
    for (s = [-1, 1]) {
        y0 = s > 0 ? roof_y : -apron_y;
        y1 = s > 0 ? apron_y : -roof_y;
        hull() {
            slab(-culvert_x, culvert_x, y0, y1, keel_top - (keel_x - culvert_x), 30);
            slab(-keel_x - e, keel_x + e, y0, y1, keel_top, 30);
        }
        slab(-culvert_x, culvert_x, y0, y1, floor_z, 30);
    }
}

// pilot for both bores on one axis, teardrop-topped so it prints without
// sagging and stays inside the reamed diameter
module bores()
    translate([0, 0, bore_z]) rotate([90, 0, 90])
        linear_extrude(height = 2 * keel_x + 1, center = true)
            intersection() {
                circle(d = bore_d - 0.05, $fn = 32);
                hull() {
                    circle(d = pilot_d, $fn = 32);
                    translate([0, pilot_d / 2 * sqrt(2)]) square(0.01, center = true);
                }
            }

// ---------------------------------------------------------------- chutes

function arc_pts(c, r, a0, a1, n) = [for (i = [0 : n]) c + r * [cos(a0 + (a1 - a0) * i / n), sin(a0 + (a1 - a0) * i / n)]];

module chute_profile() {
    arc_c = [keel_x + land, land_z - 2];
    a45   = arc_c + 2 * [cos(45), sin(45)];
    top_at_lip = a45[1] - (lip_x - a45[0]);
    foot_x = lip_x - lip_edge - foot;
    polygon(concat(
        [[keel_x - e, land_z]],
        arc_pts(arc_c, 2, 90, 45, 6),                 // level land, then a convex R2 blend
        [[lip_x, top_at_lip],                         // 45 degree run to the lip
         [lip_x, lip_edge],                           // drip edge
         [lip_x - lip_edge, 0],                       // 45 degree undercut
         [foot_x, 0],                                 // bed contact
         [keel_x - e, foot_x - keel_x + e]]           // 45 degree underside back to the keel
    ));
}

module chutes()
    for (s = [0, 1]) mirror([s, 0, 0])
        rotate([90, 0, 0]) linear_extrude(height = 2 * chute_y, center = true) chute_profile();

// ---------------------------------------------------------------- ring holder

module ring()
    difference() {
        cylinder(r = ring_r + ring_w / 2, h = ring_h);
        translate([0, 0, -1]) cylinder(r = ring_r - ring_w / 2, h = ring_h + 2);
        // V-notches on the line where the cups touch
        for (a = [90, 270])
            rotate(a) translate([ring_r, 0, ring_h]) rotate([45, 0, 0]) cube([ring_w + 1, 1.2, 1.2], center = true);
        // engraved arrows over the bore axis (kept flat so the pin vise clears
        // them); line them up with the cup centres
        for (a = [0, 180])
            rotate(a) translate([ring_r, 0, ring_h - mark_d])
                linear_extrude(mark_d + 1) polygon([[-1.4, -1.4], [-1.4, 1.4], [1.4, 0]]);
    }

module struts()
    for (a = [45, 135, 225, 315]) rotate(a)
        hull() {
            translate([ring_r - strut_w / 2, -strut_t / 2, 0]) cube([strut_w, strut_t, ring_h]);
            translate([strut_top_r - strut_w / 2, -strut_t / 2, ring_r - strut_top_r]) cube([strut_w, strut_t, 3]);
        }

// ---------------------------------------------------------------- assembly

module splitter()
    difference() {
        union() {
            difference() {
                union() { funnel_outer(); struts(); }
                funnel_cavity();
            }
            keel();
            chutes();
            ring();
        }
        culvert_cavity();
        bores();
        translate([0, 0, top_z]) cylinder(r = ring_r + 10, h = 40);
    }

module ghost_cups()
    for (s = [-1, 1])
        translate([s * cup_d / 2, 0, -cup_h])
            difference() {
                cylinder(d = cup_d, h = cup_h);
                translate([0, 0, 6]) cylinder(d = cup_d - 6, h = cup_h);
            }

if (part == "cavity") {
    intersection() {
        union() { funnel_cavity(); culvert_cavity(); }
        translate([0, 0, floor_z]) cylinder(r = mouth_r + 1, h = top_z - floor_z);
    }
} else if (part == "preview") {
    color("#3b3f45") splitter();
    if (show_cups) %ghost_cups();
} else {
    splitter();
}

echo(str("Rim height above cup rims: ", top_z, " mm"));

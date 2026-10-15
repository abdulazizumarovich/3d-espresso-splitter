// Picopresso Shot Splitter v3 - "culvert" level-pool splitter
//
// No ball, no insert, no moving parts. A flat ring rests on the rims of two
// cups standing side by side. Coffee poured anywhere into the funnel
// collects in a pool at its bottom, and the pool drains through two
// identical 1.6 mm bores that sit side by side on the cup axis. Both bores
// have the same depth of coffee above them, so they pass the same flow.
//
// - A lid over the bores sheds a direct stream. The pool reaches the bores
//   only through two inlet slots at the ends of a short culvert. Both slots
//   lie on the mirror plane between the cups and face sideways under a
//   45 degree hood, so no straight-down stream can reach the culvert (only
//   small chamfer corners at the slot entrances can be seen from above).
// - The culvert floor falls toward the bores and its ceiling rises toward
//   the slots, so it drains and vents.
// - The bores are printed undersize and each is reamed from its own outer
//   face with the same drill, so both come out the same size with the same
//   inlet edge.
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
keel_top   = 13.3; // funnel bottom
keel_x     = 5;    // keel half width; the bore exits are on its outer faces
keel_y     = 9;    // keel half length
culvert_x  = 2;    // culvert inner half width
roof_y     = 5.7;  // the culvert is roofed for |y| <= roof_y
apron_y    = 7.7;  // inlet slots for roof_y < |y| <= apron_y
floor_z    = 8;    // culvert floor at the bores (lowest point)
floor_fall = 0.8;  // the floor rises this much from the bores to the slots
floor_t    = 2.2;
vent       = 1.0;  // the ceiling rises this much from the bores to the slots
hood_lift  = 0;    // raise the hoods (e.g. 1) for an easier brush path; more of the slot corners then show from above
bore_d     = 1.6;  // final bore, reamed after printing
pilot_d    = 1.4;  // printed pilot

/* [Chutes] */
chute_y    = 8;    // chute half width
land       = 1;    // level land below each bore exit
lip_x      = 12.5; // drip edge
foot       = 1.8;  // flat bed contact under each lip

/* [Ring holder] */
ring_r      = 46;  // centreline radius
ring_w      = 4;
ring_h      = 2.4;
strut_angle = 35;  // struts sit this far from the cup axis, so the part only looks right one way round
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
land_z  = floor_z - 0.2;             // chute land one layer below the bore exit
keel_z0 = floor_z - floor_t;         // flat bridged underside of the keel
foot_x  = lip_x - foot;              // inner end of the bed contact
wall0   = keel_top - culvert_x - vent;   // culvert wall top at the bores

flat_y  = bore_d / 2;                // floor stays level under the bore inlets

function floor_at(y) = floor_z + floor_fall * max(0, abs(y) - flat_y) / (apron_y - flat_y);
function wall_at(y)  = wall0 + vent * min(abs(y), roof_y) / roof_y;

assert(pilot_d < bore_d, "pilot must be smaller than the reamed bore");
assert(wall0 > bore_z + bore_d / 2, "culvert ceiling must clear the bores");
assert(keel_z0 >= foot_x - keel_x && keel_z0 < land_z, "keel bridge must be anchored on the chute heads");

// ---------------------------------------------------------------- helpers

module slab(x0, x1, y0, y1, z0, z1)
    translate([x0, y0, z0]) cube([x1 - x0, y1 - y0, z1 - z0]);

// prism along Y with a 45 degree gable: base half-width hw at z0
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

// ---------------------------------------------------------------- keel, culvert and lid

module keel_block()
    hull() {   // flat bridged underside over the chutes, 45 degree chamfer beyond
        slab(-keel_x, keel_x, -chute_y, chute_y, keel_z0, keel_top);
        slab(-keel_x, keel_x, -keel_y, keel_y, keel_z0 + (keel_y - chute_y), keel_top);
    }

// culvert cross-section at y: floor, vertical walls up to wall_top, 45 degree gable
module culvert_section(y, wall_top) {
    slab(-culvert_x, culvert_x, y - e, y + e, floor_at(y), wall_top);
    gable(culvert_x, wall_top, y - e, y + e);
}

module culvert_cavity() {
    // roofed part: the ridge climbs from the bores to keel_top at the slots
    for (s = [-1, 1])
        hull() {
            culvert_section(0, wall_at(0));
            culvert_section(s * flat_y, wall_at(flat_y));
            culvert_section(s * roof_y, wall_at(roof_y));
        }
    // inlet slots: open up to the funnel bottom, with 45 degree chamfers
    for (s = [-1, 1]) {
        y0 = s > 0 ? roof_y : -apron_y;
        y1 = s > 0 ? apron_y : -roof_y;
        hull() {
            slab(-culvert_x, culvert_x, s * roof_y - e, s * roof_y + e, floor_at(roof_y), keel_top + e);
            slab(-culvert_x, culvert_x, s * apron_y - e, s * apron_y + e, floor_at(apron_y), keel_top + e);
        }
        hull() {
            slab(-culvert_x, culvert_x, y0, y1, keel_top - (keel_x - culvert_x), keel_top + e);
            slab(-keel_x - e, keel_x + e, y0, y1, keel_top, keel_top + e);
        }
    }
}

// lid over the culvert: a 45 degree gable along the funnel bottom whose
// underside lifts at 45 degrees over the slots, so they face sideways
module lid()
    intersection() {
        gable(keel_x, keel_top, -apron_y, apron_y);
        union() {
            slab(-keel_x, keel_x, -roof_y, roof_y, keel_top, keel_top + keel_x + 1);
            for (s = [-1, 1])
                hull() {
                    slab(-keel_x, keel_x, s * roof_y - e, s * roof_y + e, keel_top + hood_lift, keel_top + keel_x + 1);
                    slab(-keel_x, keel_x, s * apron_y - e, s * apron_y + e, keel_top + hood_lift + apron_y - roof_y, keel_top + keel_x + 1);
                }
        }
    }

// teardrop-topped pilots for both bores on one axis; they print without
// sagging and stay inside the reamed diameter
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
    polygon(concat(
        [[keel_x - e, land_z]],
        arc_pts(arc_c, 2, 90, 45, 6),                 // level land, then a convex R2 blend
        [[lip_x, a45[1] - (lip_x - a45[0])],          // 45 degree run to the lip
         [lip_x, 0],                                  // vertical drip face, square drip edge on the bed
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
        // engraved arrows on the bore axis (flat, so a pin vise clears
        // them); point them along the line through both cup centres
        for (a = [0, 180])
            rotate(a) translate([ring_r, 0, ring_h - mark_d])
                linear_extrude(mark_d + 1) polygon([[-1, -1], [-1, 1], [1, 0]]);
    }

module struts()
    for (a = [strut_angle, 180 - strut_angle, 180 + strut_angle, -strut_angle]) rotate(a)
        hull() {
            translate([ring_r - strut_w / 2, -strut_t / 2, 0]) cube([strut_w, strut_t, ring_h]);
            translate([strut_top_r - strut_w / 2, -strut_t / 2, ring_r - strut_top_r]) cube([strut_w, strut_t, 3]);
        }

// ---------------------------------------------------------------- assembly

module splitter()
    union() {
        difference() {
            union() {
                difference() {
                    union() { funnel_outer(); struts(); }
                    funnel_cavity();
                }
                keel_block();
                chutes();
                ring();
            }
            culvert_cavity();
            bores();
            translate([0, 0, top_z]) cylinder(r = ring_r + 10, h = 40);
        }
        lid();
    }

module ghost_cups()
    for (s = [-1, 1])
        translate([s * cup_d / 2, 0, -cup_h])
            difference() {
                cylinder(d = cup_d, h = cup_h);
                translate([0, 0, 6]) cylinder(d = cup_d - 6, h = cup_h);
            }

if (part == "cavity") {
    difference() {
        intersection() {
            union() { funnel_cavity(); culvert_cavity(); }
            translate([0, 0, floor_z]) cylinder(r = mouth_r + 1, h = top_z - floor_z);
        }
        lid();
    }
} else if (part == "preview") {
    color("#3b3f45") splitter();
    if (show_cups) %ghost_cups();
} else {
    splitter();
}

echo(str("Rim height above cup rims: ", top_z, " mm"));

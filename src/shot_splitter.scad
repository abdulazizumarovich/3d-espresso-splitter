// Picopresso Shot Splitter
// Splits one espresso shot from a Wacaco Picopresso (or any naked
// portafilter) into two cups standing side by side.
//
// Two parts, both print flat without supports:
//   base   - round holder that rests on both cup rims; holds the splitter
//            bowl with a centre ridge and two drip nozzles (one per cup)
//   funnel - catch funnel that drops into the base bowl; narrows the shot
//            into one stream that falls onto the ridge
//
// Coordinates: z = 0 is the underside of the holder (the cup-rim plane).
// The nozzles sit on the X axis, so the cups stand along X.

/* [Render] */
part = "assembly"; // [assembly, base, funnel, funnel_print]
show_cups = false;  // ghost cups in the assembly view

/* [Holder disc] */
disc_d       = 100;  // overall diameter
disc_t       = 4;    // thickness
hub_r        = 28;   // solid centre radius
slot1_rc     = 32;   // inner slot ring: centre radius
slot1_w      = 7;    // inner slot ring: width
spoke1_w     = 6;
spoke1_start = 90;   // angle of the first inner spoke
slot2_rc     = 43;   // outer slot ring: centre radius
slot2_w      = 5;    // outer slot ring: width
spoke2_w     = 5;
spoke2_start = 30;
spokes       = 3;    // spokes per ring
edge_chamfer = 0.6;
mark_depth   = 0.8;  // cup-direction arrows on the top face

/* [Splitter bowl] */
bowl_ro     = 25;    // outer radius
bowl_wall   = 3;
bowl_h      = 18;    // rim height above the cup rims
outlet_x    = 18;    // nozzle distance from centre (one per cup)
outlet_d    = 5;     // nozzle bore
nozzle_wall = 1.5;
moat_w      = 2.5;   // drip-break gap around each nozzle tip
moat_h      = 2.6;
floor_z     = 5;     // floor height at the nozzles
floor_slope = 0.25;  // floor rise per mm away from a nozzle

/* [Funnel] */
fit_clearance = 0.3; // radial gap between spigot and bowl
spigot_h      = 3;
spigot_wall   = 1.5;
mouth_d       = 60;  // inner diameter of the funnel mouth
rim_ro        = 34;  // outer radius of the funnel rim
throat_d      = 5.5;
throat_len    = 2;
throat_wall   = 1.2;
throat_drop   = 4;   // gap between throat tip and splitter ridge
funnel_wall   = 2.2; // measured square to the 45 degree cone

/* [Ghost cups (preview only)] */
cup_d = 70;
cup_h = 75;

/* [Hidden] */
$fa = 2;
$fs = 0.4;
eps = 0.01;

disc_r    = disc_d / 2;
bowl_ri   = bowl_ro - bowl_wall;
nozzle_ro = outlet_d / 2 + nozzle_wall;
ridge_z   = floor_z + floor_slope * outlet_x;

throat_r  = throat_d / 2;
throat_ro = throat_r + throat_wall;
throat_z  = ridge_z + throat_drop;              // throat tip
apex_z    = throat_z + throat_len;              // inner cone meets throat
cone_off  = funnel_wall * sqrt(2);              // vertical inner-to-outer offset
mouth_r   = mouth_d / 2;
top_z     = apex_z + (mouth_r - throat_r);      // 45 degree inner cone
flare_z   = top_z - (rim_ro - bowl_ro);         // 45 degree outer flare
spigot_ro = bowl_ri - fit_clearance;
spigot_ri = spigot_ro - spigot_wall;

function under_z(r) = r + apex_z - throat_r - cone_off;  // cone underside

assert(spigot_ri > throat_ro, "funnel spigot collides with the throat");
assert(under_z(spigot_ri) < flare_z, "funnel wall too thick for the flare");
assert(outlet_x + nozzle_ro + moat_w < hub_r, "drip moat cuts into the slots");
assert(floor_z > moat_h + 1.2, "floor too thin above the drip moat");

// ---------------------------------------------------------------- base

module arc_slot(rc, w, a1, a2) {
    n = max(2, ceil(abs(a2 - a1) * PI / 180 * rc / 2));
    for (i = [0 : n - 1]) {
        b1 = a1 + (a2 - a1) * i / n;
        b2 = a1 + (a2 - a1) * (i + 1) / n;
        hull() {
            translate(rc * [cos(b1), sin(b1)]) circle(d = w);
            translate(rc * [cos(b2), sin(b2)]) circle(d = w);
        }
    }
}

module slot_ring(rc, w, spoke_w, start) {
    gap = (spoke_w + w) / 2 / rc * 180 / PI;
    pitch = 360 / spokes;
    for (k = [0 : spokes - 1])
        arc_slot(rc, w, start + k * pitch + gap, start + (k + 1) * pitch - gap);
}

module disc() {
    c = edge_chamfer;
    difference() {
        rotate_extrude()
            polygon([[0, 0], [disc_r - c, 0], [disc_r, c],
                     [disc_r, disc_t - c], [disc_r - c, disc_t], [0, disc_t]]);
        translate([0, 0, -1])
            linear_extrude(disc_t + 2) {
                slot_ring(slot1_rc, slot1_w, spoke1_w, spoke1_start);
                slot_ring(slot2_rc, slot2_w, spoke2_w, spoke2_start);
            }
        // arrows on the outer ring pointing at each cup
        for (a = [0, 180])
            rotate(a)
                translate([0, 0, disc_t - mark_depth])
                    linear_extrude(mark_depth + 1)
                        polygon([[46.4, -2.2], [46.4, 2.2], [49.2, 0]]);
    }
}

module bowl_cavity() {
    cone_h = bowl_h + 2;
    intersection() {
        translate([0, 0, -1]) cylinder(r = bowl_ri, h = bowl_h + 2);
        union()
            for (s = [-1, 1])
                intersection() {
                    // each half drains to its own nozzle; the halves meet in a ridge
                    translate([s > 0 ? -eps : -bowl_ri - 1, -bowl_ri - 1, -1])
                        cube([bowl_ri + 1 + eps, 2 * bowl_ri + 2, bowl_h + 3]);
                    translate([s * outlet_x, 0, floor_z])
                        cylinder(h = cone_h, r1 = 0, r2 = cone_h / floor_slope);
                }
    }
}

module base() {
    difference() {
        union() {
            disc();
            cylinder(r = bowl_ro, h = bowl_h);
            // fillet between bowl and disc
            rotate_extrude()
                polygon([[bowl_ro - eps, disc_t - eps], [bowl_ro + 3, disc_t - eps],
                         [bowl_ro - eps, disc_t + 3]]);
        }
        bowl_cavity();
        for (s = [-1, 1])
            translate([s * outlet_x, 0, -1]) {
                cylinder(d = outlet_d, h = floor_z + 2);
                // drip break: ring-shaped recess leaves a free-standing nozzle tip
                difference() {
                    cylinder(r = nozzle_ro + moat_w, h = moat_h + 1);
                    translate([0, 0, -1]) cylinder(r = nozzle_ro, h = moat_h + 3);
                }
            }
    }
}

// -------------------------------------------------------------- funnel

module funnel() {
    rotate_extrude()
        polygon([
            [throat_r,  throat_z],
            [throat_ro, throat_z],
            [throat_ro, max(throat_z, under_z(throat_ro))],
            [spigot_ri, under_z(spigot_ri)],
            [spigot_ri, bowl_h - spigot_h],
            [spigot_ro, bowl_h - spigot_h],
            [spigot_ro, bowl_h],
            [bowl_ro,   bowl_h],
            [bowl_ro,   flare_z],
            [rim_ro,    top_z],
            [mouth_r,   top_z],
            [throat_r,  apex_z],
        ]);
}

// ------------------------------------------------------------- output

module ghost_cups() {
    for (s = [-1, 1])
        translate([s * cup_d / 2, 0, -cup_h])
            difference() {
                cylinder(d = cup_d, h = cup_h);
                translate([0, 0, 6]) cylinder(d = cup_d - 6, h = cup_h);
            }
}

if (part == "base") {
    base();
} else if (part == "funnel") {
    funnel();
} else if (part == "funnel_print") {
    // mouth down on the bed
    translate([0, 0, top_z]) rotate([180, 0, 0]) funnel();
} else {
    color("#2b2b2b") base();
    color("#3d3d3d") funnel();
    if (show_cups) %ghost_cups();
}

echo(str("Assembled height above cup rims: ", top_z, " mm"));

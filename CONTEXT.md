# Project context (for resuming work)

Last updated: 2026-10-15

## Goal

A 3D-printable espresso splitter for a **Wacaco Picopresso**. It stands on **two cups** side by side and divides one shot **equally, no matter where the shot is poured**. It is not attached to the Picopresso: the user holds it above the splitter.

## What was asked, in order

1. **v1:** create a repo and a model from the owner's reference renders. The renders showed a round disc with ring slots resting on two cups, a funnel cup on top, and two outlet holes underneath.
2. **v2:** make it lighter with fewer parts, use a different look from the reference author's, give it a smooth interior, avoid enclosed spaces (open top), and split equally wherever the coffee is poured.
3. **v3 brief:**
   - Use the "Meticulous Shot Splitter" flow design, with a 35 mm metal ball "for an even split".
   - Use a **ring holder** for the first trial.
   - Watch the weight and use little material.
   - No spaces that are hard to clean.
4. The owner asked whether glass could replace the ball. Then they asked where to buy a ball in Cairo.
5. Then the owner said: **design it without a ball** ("a big advantage to the community"), research for a better design, and the split must be equal wherever the shot is poured.

## Research findings (from search-result summaries only; the network blocks most page fetches)

- **Meticulous Shot Splitter:** an accessory for the Meticulous machine. It mounts magnetically on the machine, not on cups, and has a self-levelling "eccentric bearing". Its **35 mm steel ball is for the Hugh Kelly extract-chilling technique** (WBC 2021), not for splitting. No STL, licence, internal geometry or measured accuracy is published.
- **Physics of a ball:** a ball passes the pour position straight through, because coffee runs down the side it lands on. A full film around a 35 mm ball needs about 6–20 g/s, while espresso flows at 1–2 g/s, so the coffee breaks into random rivulets. A solid 35 mm steel ball is about 178 g and cools the shot.
- **Even splitting:** the reliable passive principle is a **calm, level pool feeding identical outlets**. A **riffle** splitter needs a spread-out feed; **time division** needs moving parts; **weirs** under 5 mm of head are dominated by surface tension.
- Barista Hustle: ordinary double spouts can be several grams apart between cups.
- **Cairo ball sourcing (unverified):** the Downtown bearing district (Champollion St., Sheikh Maarouf St., Souk El Tawfiqeya), e.g. El Qawmeya Co. For Bearing, 31 Champollion St. Lab-supply streets near Kasr El Aini for borosilicate. AliExpress or Ubuy for 304/316 stainless. Avoid 52100 chrome steel, "crystal" decor balls and hollow ice balls. **No longer needed for v3.**

## Current design: v3 "Culvert"

Source: `src/shot_splitter.scad`. Output: `stl/splitter.stl`. Coordinates: z = 0 is the cup-rim plane and the print bed; cups stand along X and touch at x = 0.

The design came from a multi-agent study: four concepts, scored by two independent judges who both picked this one. An adversarial review then found and fixed 10 issues.

- **Ring holder:** R46 centreline (OD 96), 4 × 2.4 mm. Four 3 × 3.5 mm struts at **±35° from the cup axis**, rising at 45°.
- **Funnel:** Ø76 mouth, walls 46° or steeper, 1.2 mm shell, top at z = 47.5. Capacity 64 ml.
- **Keel and lid:** funnel bottom at z = 13.3 (x ±5, y ±7.7). A 45° gable lid covers it.
  - Its underside lifts at 45° over the two **inlet slots** (|y| 5.7–7.7), so the slots face sideways.
  - No straight-down ray reaches the culvert. Only 8 mm² of chamfer corners below the funnel bottom are visible from above.
- **Culvert:** 4 mm wide (x ±2), roofed for |y| ≤ 5.7.
  - Floor at z = 8.0, level under the bores (|y| ≤ 0.8), rising 0.8 mm toward the slots.
  - Ceiling ridge rises 1.0 mm from the bores (12.3) to the slots (13.3), for venting.
- **Bores:** two horizontal bores on one X axis (y = 0, z = 8.8), through the culvert walls (|x| 2–5).
  - Printed as Ø1.4 teardrop pilots, **reamed to Ø1.6 from each outer face separately** (same bit).
- **Chutes:** one per side, 16 mm wide (|y| ≤ 8). A level land 0.2 mm below the bore exit, then an R2 blend into a 45° run.
  - A vertical drip face at x = ±12.5 meets the bed, with a 1.8 mm foot.
  - Keel bridge underside at z = 5.8, anchored on the chute heads.
- **Marks:** V-notches at ±Y (the line where the cups touch). Engraved arrows at ±X, which a 12 mm pin vise clears.

| Metric (check_mesh.py) | Value |
|---|---|
| Mass (PETG) | 21.4 g |
| Mesh | watertight, 1 body, mirror-symmetric in X and Y |
| Overhangs | none beyond 45° apart from the 160 mm² keel bridge (10 mm span) and sub-mm pilot/ridge facets |
| Bed contact | 1213 mm² (ring plus two feet) |
| Drill line | cuts only the bore walls; a 12 mm pin vise clears |
| Pool | 0.15 ml at 2 mm above the bore centre, 1.2 ml at 9 mm, 2.7 ml at 12 mm |

**Estimated performance** (models, not measured):

- Level and pre-wetted: about 50.7/49.3.
- A 1 mm cup-height difference (0.7–1.1°): 0.3 points or less at 1.2 ml/s and up; 1–2 points at 0.5 ml/s.
- Front-to-back tilt: about 0.
- Bore diameter mismatch: 0.34 points per 0.01 mm.
- Exit wetting mismatch: about 0.3 points per 0.1 mm of head.
- Fast shots store 6–20 ml in the funnel, which drains 5–15 s after the pump stops.

## Decisions and rejected options

- **Ball:** rejected. It is for chilling, it maps the pour position onto the split, and it adds weight and cooling.
- **Meticulous-style ring crest with a fin across the cups:** rejected. It is tilt-sensitive (about 55% at 1°), and its weirs work at less than 5 mm of head.
- **"Crown" (notched crest with a hood):** scored lower. Its metering heads are too low and it needs two parts.
- **"Comb"** (B-A-A-B notches, exact cup-axis tilt cancellation): **runner-up**. Kept as a fallback (see next steps).
- **Twin rocker / tipping bucket:** rejected. Moving parts, about 37 g, and it needs micron-level symmetry.
- **The culvert roof is kept on purpose.** It is the only feature that stops a stream from plunging next to a bore. This is the one deviation from "fully open top": a 4 × ~5 mm channel, see-through end to end and cleaned with a pipe cleaner.
- **Reaming:** the earlier single-pass coaxial plan was replaced by per-side reaming, because a single pass leaves a burr on only one inlet, where it can't be reached.

## Verification done

- `tools/check_mesh.py` covers: watertight/bodies, mass, bridges and overhangs, bed contact, mirror symmetry, drill line, pin-vise clearance, straight-down line of sight, and pool volume vs height.
- Independent review (3 reviewers plus 3 skeptics): the issues fixed were PM-1 feet, PM-2/F4/U2 reaming, F2 aprons visible from above, F3 culvert floor and vent, F5 thin floor, F8 drip edge, PM-4 end walls, PM-5 layer alignment, PM-6 arrow sliver, PM-7 vise, and U4 4-fold look.
- **Not printed or water-tested yet.**

## Repo state

- GitHub: `abdulazizumarovich/3d-espresso-splitter`.
- `main` holds only v1 (`f66277e`).
- Branch **`claude/ball-free-splitter-v3`** holds v2, these notes and v3.
- The owner hasn't yet decided whether to merge into `main` or open a pull request.
- The session's `GH_TOKEN` is invalid (the `gh` CLI fails). Git push works through the session's repo attachment.

## How to rebuild and check

```sh
apt-get install -y openscad xvfb          # OpenSCAD 2021.01
pip install trimesh networkx shapely mapbox-earcut manifold3d rtree
openscad -o stl/splitter.stl src/shot_splitter.scad
python3 tools/check_mesh.py
xvfb-run -a openscad -D 'part="preview"' --camera=0,-260,170,0,0,5 --viewall --autocenter \
  --colorscheme=Tomorrow --imgsize=1400,1000 -o images/assembly.png src/shot_splitter.scad
```

## Open items and next steps

1. Print in PETG, ream per side, then run the README water test. Pass: 49–51% everywhere; 180° swap bias ≤ 0.7 points; a 1 mm shim ≤ 0.5 points.
2. If the low-flow test (0.3–0.5 ml/s poured off to one side) shows more than 1–2% bias, try `bore_d = 1.4` (keep `pilot_d` smaller).
3. If cup-height tilt dominates: **v4 fallback**.
   - Turn the bore axis to Y so both bores sit at x = 0, with open chutes turning to each cup. Cup-axis tilt then cancels exactly, and front-to-back tilt becomes first order.
   - Or use the Comb's B-A-A-B layout.
4. Optional: a lighter `mouth_d = 68` (18.9 g, 46.5 ml, 43.3 mm tall).
5. Merge the branch into `main` once the owner approves.

## Owner preferences

- Ask clarifying questions instead of assuming.
- Keep answers short and to the point.
- Don't implement anything without full context.
- Search for information the owner can't provide.

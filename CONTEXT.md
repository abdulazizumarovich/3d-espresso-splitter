# Project context (for resuming work)

Last updated: 2026-10-15

## Goal

A 3D-printable espresso splitter for a **Wacaco Picopresso**. It stands on **two cups** side by side and divides one shot evenly between them. It is not attached to the Picopresso: you hold the Picopresso above it, so the Picopresso's exact dimensions don't matter.

## What was asked, in order

1. **v1:** create a GitHub repo and a model from the owner's reference renders. The renders showed a flat round disc with concentric ring slots and spokes resting on two cups, a funnel cup on top, and two outlet holes underneath. Refinements were allowed and I chose the name.
2. **v2:** the owner then asked for these changes:
   - lighter, with unnecessary parts removed
   - a **different outer style**, so it doesn't copy the reference author's look
   - smooth interior with no corners where coffee residue collects
   - **no isolated or enclosed spaces**, and an **open-top** structure
   - **an equal split wherever the liquid is poured**

## Current design (v2)

Source: `src/shot_splitter.scad`. Output: `stl/splitter.stl`.

- One part: an open oval basin on four flat legs in an X shape.
- **How the split works:** the basin walls run down into a **level trough**, a capsule shape 10 mm wide with its axis horizontal along X. There is one **Ø2.0 mm outlet hole** at each end, at x = ±14 mm, sitting at the trough's lowest points.
  - The small holes make about 1 ml of coffee pool in the trough.
  - The pool surface is level, so both holes have the same depth of coffee above them and pass the same flow, whatever the pour position.
- **Drip tips:** under each hole there is a 45° conical recess around a free-standing tip, so drops fall cleanly. The recess is printable without supports.
- **Legs:** four legs at ±50° from the cup axis, 60 mm from centre to tip, 6 mm tall at the root tapering to 3 mm at the tip. They rest on both cup rims for rim diameters of about 45–90 mm.
- **Coordinates:** z = 0 is the cup-rim plane and the print bed. The cups stand along X.

| Metric | Value |
|---|---|
| Mass (PETG) | 26.6 g (v1 was 71 g) |
| Basin capacity to the rim | 41.3 ml |
| Pool volume at 4 mm depth | 1.06 ml |
| Height above the cup rims | 34 mm |
| Footprint | 83 × 98 mm |
| Overhangs steeper than 45° | none (0.1 mm² of slicer noise) |

The orifice-flow estimates below are calculations, not measurements. They assume a discharge coefficient (Cd) of about 0.75 and ignore surface tension.

| Hole size | Flow | Pool depth | Split with the splitter tilted 1° |
|---|---|---|---|
| Ø2.0 | 1.0 ml/s | 2.3 mm | 52.7 / 47.3 |
| Ø2.0 | 1.5 ml/s | 5.2 mm | 51.2 / 48.8 |
| Ø2.0 | 2.5 ml/s | 14.3 mm | 50.4 / 49.6 |
| Ø2.5 | 1.5 ml/s | 2.1 mm | 52.9 / 47.1 |

## Decisions and rejected options

- **Knife-edge ridge under a funnel throat (v1):** rejected. At espresso flow rates the coffee runs as a film down one side of the throat, so the split depends on where it was poured.
- **Overflow weirs:** rejected because they leave coffee behind in the basin and are unreliable at this small scale.
- **Tipping bucket:** rejected as too complex mechanically.
- **Nozzles or locating pegs below the rim plane:** rejected because they would need supports. The device rests flat on the rims, and the outlets at ±14 mm tolerate several millimetres of sliding.
- **Outlet spacing:** ±14 mm is a compromise between staying inside cups with thick rims and keeping tilt sensitivity low.
- **Material:** PETG or PCTG, not PLA, because PLA softens around 60 °C and espresso is hotter.

## Verification done

- The STL is watertight, one body, and sits flat on the bed (z min = 0).
- There are no overhangs steeper than 45°. The trough is level from x = -14.4 to x = +14.4.
- Renders are in `images/`.
- **Not tested physically.** The split is unverified until it's printed and checked with water. The README explains the method: weigh both cups, then turn the splitter 180° and repeat to tell whether a difference comes from the holes or from the table not being level.

## Repo and session state

- GitHub: `abdulazizumarovich/3d-espresso-splitter`, branch `main`.
- On GitHub: commit `f66277e` (v1, the two-part ring design).
- **Local only, not pushed yet:** `6b35d04` (the v2 redesign) and the commit adding this file. The owner hasn't yet confirmed pushing v2 to `main`.
- The session's `GH_TOKEN` is invalid, so `gh` CLI commands fail. Git push to this repo works through the session's repo attachment.

## How to rebuild and check

```sh
apt-get install -y openscad xvfb          # OpenSCAD 2021.01 on Ubuntu
pip install trimesh networkx shapely mapbox-earcut
openscad -o stl/splitter.stl src/shot_splitter.scad
python3 tools/check_mesh.py               # watertight, mass, overhangs, capacity, trough level
xvfb-run -a openscad -D 'part="preview"' --camera=0,-250,150,0,0,0 --viewall --autocenter \
  --colorscheme=Tomorrow --imgsize=1400,1000 -o images/assembly.png src/shot_splitter.scad
```

Rendering the STL takes about 1.5 minutes. If you change `top_z` or `floor_z` in the `.scad`, change them in `tools/check_mesh.py` too.

## Open items and next steps

1. Push v2 to `main` once the owner confirms.
2. Print it, drill both outlets to 2.0 mm, and run the water test from several pour positions.
3. Possible tuning after the test:
   - `outlet_d`: smaller gives a deeper pool and a more even split, but drains more slowly.
   - `outlet_x`: increase it for cups with thick rims.
   - `leg_angle` / `leg_len`: adjust them if the owner's cups are outside 45–90 mm.
4. The owner's actual cup sizes are unknown. Ask for them if a cup-specific fit is needed.

## Owner preferences

- Ask clarifying questions instead of assuming.
- Keep answers short and to the point.
- Don't implement anything without full context.
- Search for information the owner can't provide.

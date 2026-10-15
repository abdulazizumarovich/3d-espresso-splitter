"""Print-readiness and flow-geometry checks for the v3 splitter.

Usage (from the repo root; needs openscad and
`pip install trimesh networkx shapely mapbox-earcut manifold3d rtree`):
    python3 tools/check_mesh.py
"""
import os
import re
import subprocess
import tempfile

import numpy as np
import trimesh

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAD = os.path.join(ROOT, "src", "shot_splitter.scad")
STL = os.path.join(ROOT, "stl", "splitter.stl")


def param(name):
    m = re.search(rf"^{name}\s*=\s*([0-9.]+)", open(SCAD).read(), re.M)
    return float(m.group(1))


FLOOR_Z, BORE_D, KEEL_X, CULVERT_X = param("floor_z"), param("bore_d"), param("keel_x"), param("culvert_x")
BORE_Z = FLOOR_Z + BORE_D / 2

m = trimesh.load(STL)
print("watertight", m.is_watertight, "| bodies", len(m.split(only_watertight=False)))
print("bbox mm", m.bounds.round(2).tolist())
print("volume %.2f cm3 | PETG mass %.1f g" % (m.volume / 1000, m.volume / 1000 * 1.27))

# Overhangs: downward faces steeper than 45 deg from vertical, not on the bed.
n, c, a = m.face_normals, m.triangles_center, m.area_faces
off_bed = c[:, 2] > 0.05
flat_down = off_bed & (n[:, 2] < -0.99)
steep = off_bed & (n[:, 2] < -np.sin(np.radians(45)) - 1e-3) & ~flat_down
print("flat downward faces (bridges): %.1f mm2" % a[flat_down].sum())
for z in np.unique(c[flat_down, 2].round(1)):
    sel = flat_down & (np.abs(c[:, 2] - z) < 0.06)
    lo, hi = c[sel, :2].min(0), c[sel, :2].max(0)
    print(f"   z={z:5.1f}: {a[sel].sum():6.1f} mm2, x {lo[0]:.1f}..{hi[0]:.1f}, y {lo[1]:.1f}..{hi[1]:.1f}")
print("sloped overhang > 45 deg: %.1f mm2" % a[steep].sum(),
      "" if not steep.any() else f"(z {c[steep, 2].min():.1f}-{c[steep, 2].max():.1f})")
bed = (c[:, 2] < 0.05) & (n[:, 2] < -0.99)
print("bed contact area %.0f mm2" % a[bed].sum())

# Symmetry: the part must be identical after mirroring X (swaps the cups) and Y.
for axis, name in ((0, "X"), (1, "Y")):
    mir = m.copy()
    S = np.eye(4)
    S[axis, axis] = -1
    mir.apply_transform(S)  # trimesh fixes the winding of a mirrored mesh
    diff = m.difference(mir, engine="manifold")
    print(f"mirror-{name} asymmetry volume: {diff.volume:.4f} mm3")

# Drill line: the reamed bore must only cut the two bore walls, and a pin vise
# (up to 12 mm across) must reach the bore from outside along X.
rng = np.random.default_rng(0)
ang = rng.uniform(0, 2 * np.pi, 4000)
rad = BORE_D / 2 * np.sqrt(rng.uniform(0, 1, 4000))
x = rng.uniform(-60, 60, 4000)
pts = np.c_[x, rad * np.cos(ang), BORE_Z + rad * np.sin(ang)]
inside = m.contains(pts)
xs = np.abs(pts[inside, 0])
print("material inside the 1.6 mm drill line: |x| %.2f..%.2f (bore walls span %.1f..%.1f)"
      % (xs.min(), xs.max(), CULVERT_X, KEEL_X))
ang = rng.uniform(0, 2 * np.pi, 6000)
rad = 6 * np.sqrt(rng.uniform(0, 1, 6000))
pts = np.c_[rng.choice([-1, 1], 6000) * rng.uniform(14, 60, 6000), rad * np.cos(ang), BORE_Z + rad * np.sin(ang)]
print("pin vise (12 mm) clash points for |x| >= 14:", int(m.contains(pts).sum()))

# Pool and capacity from the cavity solid.
with tempfile.TemporaryDirectory() as tmp:
    out = os.path.join(tmp, "cavity.stl")
    subprocess.run(["openscad", "-D", 'part="cavity"', "-o", out, SCAD], check=True, capture_output=True)
    cav = trimesh.load(out)
print("capacity from bore to rim %.1f ml" % (cav.volume / 1000))
for h in (2, 4, 6, 9, 12, 15):
    z = BORE_Z + h
    sec = cav.section([0, 0, 1], [0, 0, z])
    area = sec.to_2D()[0].area if sec is not None else 0
    below = trimesh.intersections.slice_mesh_plane(cav, [0, 0, -1], [0, 0, z], cap=True).volume / 1000
    print(f"   pool {h:2d} mm above bore centre: surface {area:6.0f} mm2, volume {below:.2f} ml")

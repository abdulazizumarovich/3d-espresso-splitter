"""Print-readiness and basin checks for the splitter.

Usage (from the repo root, needs openscad and `pip install trimesh networkx shapely mapbox-earcut`):
    python3 tools/check_mesh.py
"""
import os
import subprocess
import tempfile

import numpy as np
import trimesh

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCAD = os.path.join(ROOT, "src", "shot_splitter.scad")
STL = os.path.join(ROOT, "stl", "splitter.stl")
TOP_Z = 34       # keep in sync with top_z in the .scad
FLOOR_Z = 3.6    # keep in sync with floor_z in the .scad

m = trimesh.load(STL)
print("watertight", m.is_watertight, "| bodies", len(m.split(only_watertight=False)))
print("bbox mm", m.bounds.round(2).tolist())
print("volume %.2f cm3 | PETG mass %.1f g" % (m.volume / 1000, m.volume / 1000 * 1.27))

# Overhangs: downward faces steeper than the limit, ignoring the bed face.
n, c, a = m.face_normals, m.triangles_center, m.area_faces
off_bed = c[:, 2] > 0.05
for lim in (45, 50):
    mask = off_bed & (n[:, 2] < -np.sin(np.radians(lim)) - 1e-3)
    print(f"overhang > {lim} deg from vertical: {a[mask].sum():.1f} mm2")

# Basin capacity, pool volume and trough level from the cavity solid.
with tempfile.TemporaryDirectory() as tmp:
    scad = os.path.join(tmp, "cavity.scad")
    out = os.path.join(tmp, "cavity.stl")
    with open(scad, "w") as f:
        f.write(f"use <{SCAD}>\n$fa=2; $fs=0.3;\n"
                f"intersection() {{ basin_cavity(); translate([-50,-50,-1]) cube([100,100,{TOP_Z}+1]); }}\n")
    subprocess.run(["openscad", "-o", out, scad], check=True, capture_output=True)
    cav = trimesh.load(out)

print("basin capacity to rim %.1f ml" % (cav.volume / 1000))
pool = trimesh.intersections.slice_mesh_plane(cav, [0, 0, -1], [0, 0, FLOOR_Z + 4], cap=True)
print("pool volume at 4 mm head %.2f ml" % (pool.volume / 1000))
zmin = cav.vertices[:, 2].min()
low = cav.vertices[cav.vertices[:, 2] < zmin + 0.02]
print("trough bottom z %.3f, level from x=%.1f to x=%.1f" % (zmin, low[:, 0].min(), low[:, 0].max()))

"""Build an open ceramic mug, export GLB, and render asset / holding previews.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_standard_mug.py
Only this mug's assets and previews are overwritten; existing sources are read-only.
"""

import json
import math
from pathlib import Path

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Dishes"
DOCS = ROOT / "Docs"
ASSETS.mkdir(parents=True, exist_ok=True)
SEGMENTS = 96
PIVOT_Z = .0525
# Follow the material boundary from the inside floor, up and around the lip,
# down the exterior, around the foot, and back to the underside centre.
PROFILE = [(0, .010), (.028, .010), (.034, .0107), (.037, .013),
           (.0385, .017), (.039, .025), (.0395, .055), (.0405, .085),
           (.0413, .099), (.0415, .10325)]
for step in range(1, 7):
    angle = math.pi - math.pi * step / 6
    PROFILE.append((.04325 + .00175 * math.cos(angle), .10325 + .00175 * math.sin(angle)))
PROFILE += [(.0449, .099), (.04475, .094), (.0445, .082), (.044, .060),
            (.043, .032), (.0425, .018), (.042, .010), (.0413, .006),
            (.0398, .0035), (.0375, .0018), (.035, .0013),
            (.034, .0004), (.0333, 0), (.030, 0), (.029, .0005),
            (.0285, .0015), (.028, .0030), (.026, .004), (.018, .004), (0, .004)]
FLOOR_END, LIP_TOP, BASE_START = 4, 12, 26

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for group in list(bpy.data.collections):
    bpy.data.collections.remove(group)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def collection(name):
    group = bpy.data.collections.new(name)
    scene.collection.children.link(group)
    return group


asset = collection("01_Mug_Asset")
studio = collection("90_Preview_Studio")


def material(name, color, roughness):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_backface_culling = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    return mat


glaze = material("Mug_Warm_Ivory_Glaze", (.82, .785, .70), .23)
foot_mat = material("Mug_Unglazed_Foot", (.64, .58, .47), .72)


def marker(name, position, parent=None, normal=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = position
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .012
    if normal:
        obj.rotation_euler = Vector(normal).to_track_quat("Z", "Y").to_euler()
    return obj


root = marker("Mug_Standard", (0, 0, 0))
root["body_diameter_m"] = .09
root["height_m"] = .105
root["mouth_inner_diameter_m"] = .083
root["pivot"] = "Cup body axis at half height; handle does not offset rotation centre"
root["scope"] = "Open geometry, UVs and dirt markers; no gameplay or collision body"


def mesh_object(name, vertices, faces):
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    asset.objects.link(obj)
    obj.parent = root
    mesh.materials.append(glaze)
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


vertices, rings, vertex_ring, faces, bands = [], [], [], [], []
for ring_index, (radius, z) in enumerate(PROFILE):
    ring = []
    for index in range(1 if radius == 0 else SEGMENTS):
        angle = math.tau * index / SEGMENTS
        ring.append(len(vertices))
        vertex_ring.append(ring_index)
        vertices.append((radius * math.cos(angle), radius * math.sin(angle), z - PIVOT_Z))
    rings.append(ring)
for band, (inner, outer) in enumerate(zip(rings[:-1], rings[1:])):
    for i in range(SEGMENTS):
        nxt = (i+1) % SEGMENTS
        face = ((inner[0], outer[i], outer[nxt]) if len(inner) == 1 else
                (inner[i], outer[0], inner[nxt]) if len(outer) == 1 else
                (inner[i], outer[i], outer[nxt], inner[nxt]))
        faces.append(face)
        bands.append(band)
body = mesh_object("Mug_Body", vertices, faces)
body.data.materials.append(foot_mat)
for poly, band in zip(body.data.polygons, bands):
    poly.material_index = 1 if 27 <= band <= 30 else 0

# Four disjoint UV islands: inner floor / underside disks and inner / outer strips.
arc = [0]
for a, b in zip(PROFILE[:-1], PROFILE[1:]):
    arc.append(arc[-1] + math.dist(a, b))
uv = body.data.uv_layers.new(name="UV_Cleaning")
for poly, band in zip(body.data.polygons, bands):
    sector = poly.index % SEGMENTS
    for loop_index in poly.loop_indices:
        vertex_index = body.data.loops[loop_index].vertex_index
        ring = vertex_ring[vertex_index]
        x, y, _ = vertices[vertex_index]
        angle = math.atan2(y, x)
        if band < FLOOR_END or band >= BASE_START:
            fraction = (arc[ring] / arc[FLOOR_END] if band < FLOOR_END else
                        (arc[-1]-arc[ring]) / (arc[-1]-arc[BASE_START]))
            centre = (.22, .18) if band < FLOOR_END else (.65, .18)
            coordinate = (centre[0]+.15*fraction*math.cos(angle), centre[1]+.15*fraction*math.sin(angle))
        else:
            # Resolve seam vertices per face, so the last sector ends at U=.98.
            sector_index = (vertex_index - rings[ring][0])
            u = sector_index / SEGMENTS
            if sector == SEGMENTS-1 and sector_index == 0:
                u = 1
            start, end, v_start = ((FLOOR_END, LIP_TOP, .70) if band < LIP_TOP
                                   else (LIP_TOP, BASE_START, .38))
            v = (arc[ring]-arc[start]) / (arc[end]-arc[start])
            coordinate = (.02 + .96*u, v_start + .28*v)
        uv.data[loop_index].uv = coordinate
for name, predicate in (("Clean_Interior", lambda i: i <= LIP_TOP),
                         ("Clean_Exterior", lambda i: LIP_TOP <= i <= BASE_START),
                         ("Clean_Underside", lambda i: i >= BASE_START)):
    group = body.vertex_groups.new(name=name)
    group.add([i for i, ring in enumerate(vertex_ring) if predicate(ring)], 1, "REPLACE")

# A closed curved ceramic handle with both end caps embedded in the outer wall.
# It is a separate editable solid, so its opening is never filled by a boolean cap.
handle_vertices, handle_faces = [], []
STEPS, SIDES = 56, 16
handle_marker = None
for i in range(STEPS+1):
    angle = math.pi/2 - math.pi*i/STEPS
    centre = Vector((.04125 + .00075*math.sin(angle) + .038*math.cos(angle),
                     0, .054 + .028*math.sin(angle) - PIVOT_Z))
    tangent = Vector((-.00075*math.cos(angle)+.038*math.sin(angle), 0, -.028*math.cos(angle))).normalized()
    outward = Vector((-tangent.z, 0, tangent.x))
    for j in range(SIDES):
        around = math.tau*j/SIDES
        point = centre + outward*(.0065*math.cos(around)) + Vector((0, .0075*math.sin(around), 0))
        handle_vertices.append(tuple(point))
        if i == STEPS//2 and j == 0:
            handle_marker = (point, outward)
for i in range(STEPS):
    for j in range(SIDES):
        nxt = (j+1) % SIDES
        handle_faces.append((i*SIDES+j, i*SIDES+nxt, (i+1)*SIDES+nxt, (i+1)*SIDES+j))
handle_faces += [tuple(reversed(range(SIDES))), tuple(range(STEPS*SIDES, (STEPS+1)*SIDES))]
handle = mesh_object("Mug_Handle", handle_vertices, handle_faces)
bm = bmesh.new()
bm.from_mesh(handle.data)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(handle.data)
bm.free()
uv = handle.data.uv_layers.new(name="UV_Handle")
for poly in handle.data.polygons:
    for loop_index in poly.loop_indices:
        vertex = handle.data.loops[loop_index].vertex_index
        i, j = divmod(vertex, SIDES)
        if poly.index < STEPS*SIDES:
            around = j/SIDES
            if poly.index % SIDES == SIDES-1 and j == 0:
                around = 1
            coordinate = (.02+.96*i/STEPS, .30+.68*around)
        else:
            centre_x = .25 if i == 0 else .75
            coordinate = (centre_x+.10*math.cos(math.tau*j/SIDES), .14+.10*math.sin(math.tau*j/SIDES))
        uv.data[loop_index].uv = coordinate

marker("Placement_Base", (0, 0, -.0525), root)
marker("Mouth_Center", (0, 0, .0525), root, (0, 0, 1))
for name, position, normal, radius in (
    ("Dirt_Inner_Bottom", (0, 0, -.0425), (0, 0, 1), .012),
    ("Dirt_Inner_Wall", (0, .0395, .0025), (0, -1, .017), .009),
    ("Dirt_Outer_Wall", (0, -.044, .0075), (0, -1, -.025), .012),
    ("Dirt_Underside", (.016, 0, -.0485), (0, 0, -1), .009),
    ("Dirt_Handle", handle_marker[0], handle_marker[1], .004),
):
    point = marker(name, position, root, normal)
    point["test_radius_m"] = radius
    point["purpose"] = "Surface attachment reference; cleaning uses actual hit normals"

# Actual mesh checks: closed material boundary, open mouth, inner floor and handle aperture.
bpy.context.view_layer.update()
for obj in (body, handle):
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(edge.is_manifold for edge in bm.edges)
    assert all(face.calc_area() > 1e-12 for face in bm.faces)
    assert bm.calc_volume(signed=True) > 0
    bm.free()
    assert all(-1e-6 <= c <= 1.000001 for item in obj.data.uv_layers.active.data for c in item.uv)
    obj.data.calc_loop_triangles()
assert all(abs(a-b) < 1e-6 for a, b in zip(body.dimensions, (.09, .09, .105)))
for origin, direction, expected_z, normal_z in (
    ((0, 0, .2), (0, 0, -1), -.0425, 1),
    ((0, 0, -.2), (0, 0, 1), -.0485, -1),
):
    hit, location, normal, _ = body.ray_cast(Vector(origin), Vector(direction))
    assert hit and abs(location.z-expected_z) < 1e-6 and normal.z*normal_z > .99
hit, location, normal, _ = body.ray_cast(Vector((0, 0, 0)), Vector((0, 1, 0)))
assert hit and .039 < location.y < .040 and normal.y < -.99
for obj in (body, handle):
    assert not obj.ray_cast(Vector((.060, -.1, 0)), Vector((0, 1, 0)))[0], "Handle aperture is blocked"
print("MUG_GEOMETRY_OK", sum(len(o.data.vertices) for o in (body, handle)), "vertices",
      sum(len(o.data.loop_triangles) for o in (body, handle)), "triangles", flush=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "mug-standard.glb"), export_format="GLB",
                          use_selection=True, export_extras=True)


def camera(name, location, target, size):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.type = "ORTHO"
    data.ortho_scale = size
    data.clip_start = .002
    return obj


def render(cam, filename):
    scene.camera = cam
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


for name, location, energy, size in (("Preview_Key", (-.25, -.25, .40), 8, .20),
                                     ("Preview_Fill", (.25, .15, .35), 4, .25)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (-obj.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.0001))
floor = bpy.context.object
floor.name = "Preview_Ground"
for group in list(floor.users_collection):
    group.objects.unlink(floor)
studio.objects.link(floor)
floor.data.materials.append(material("Preview_Sage_Ground", (.16, .22, .215), .9))
copies = []
for index, (position, rotation) in enumerate((((-.075, 0, .0525), (0, 0, -.18)),
                                            ((.085, .015, .07), (math.radians(55), 0, .15)))):
    holder = bpy.data.objects.new("Preview_Mug_" + str(index), None)
    studio.objects.link(holder)
    holder.location, holder.rotation_euler = position, rotation
    for original in (body, handle):
        obj = original.copy()
        studio.objects.link(obj)
        obj.parent = holder
        copies.append(obj)
body.hide_render = handle.hide_render = True
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "AgX"
scene.world.color = (.22, .22, .22)
hero = camera("Preview_Mug_Exterior_Interior", (.02, -.40, .30), (.02, 0, .0525), .36)
render(hero, "mug-standard-overview.png")
for obj in copies:
    obj.hide_render = True
body.hide_render = handle.hide_render = False
floor.location.z = -.0526
studio.hide_viewport = True
scene.camera = camera("Preview_Single_Mug", (.17, -.25, .18), (0, 0, 0), .18)
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_distance = .26
        area.spaces.active.region_3d.view_location = (0, 0, 0)
        area.spaces.active.region_3d.view_rotation = scene.camera.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "mug-standard.blend"))

# Actual holding anchors from the greybox, without saving changes to that source.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for path, name in ((ASSETS / "mug-standard.blend", "01_Mug_Asset"),
                   (ROOT / "Assets" / "Tools" / "sponge-standard.blend", "01_Sponge_Asset")):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [name]
    scene.collection.children.link(target.collections[0])
root = bpy.data.objects["Mug_Standard"]
body = bpy.data.objects["Mug_Body"]
handle = bpy.data.objects["Mug_Handle"]
sponge_root = bpy.data.objects["Sponge_Standard"]
foam = bpy.data.objects["Sponge_Foam"]
pad = bpy.data.objects["Sponge_Scrub_Pad"]
foam.hide_render = pad.hide_render = True
bpy.data.objects["QA_Held_Plate_250mm"].hide_render = True
bpy.data.objects["Proxy_Dirty_Cup_90mm"].hide_render = True
for original in (body, handle):
    obj = bpy.data.objects.new("Preview_Tray_" + original.name, original.data)
    scene.collection.objects.link(obj)
    obj.location = (-.72, .065, .982)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 32
player_cam = bpy.data.objects["Player_Camera"]
bounds = {}
for anchor, rotation, filename in (
    ("Carry_Anchor", (math.radians(48), 0, -.12), "mug-standard-carry.png"),
    ("Clean_Anchor", (math.radians(22), 0, -.12), "mug-standard-clean.png"),
    ("Clean_Anchor", (math.radians(165), 0, -.12), "mug-standard-bottom.png"),
):
    root.parent = bpy.data.objects[anchor]
    root.location = (0, 0, 0)
    root.rotation_euler = rotation
    bpy.context.view_layer.update()
    points = [world_to_camera_view(scene, player_cam, obj.matrix_world @ v.co)
              for obj in (body, handle) for v in obj.data.vertices]
    limits = [min(p.x for p in points), max(p.x for p in points), min(p.y for p in points), max(p.y for p in points)]
    assert all(.01 < value < .99 for value in limits)
    assert min(p.z for p in points) > player_cam.data.clip_start
    bounds[filename] = limits
    render(player_cam, filename)

# Side-insertion check. Sponge's 110 mm axis runs along the cup axis; the
# 70 x 32 mm section is centred inside the mouth, rather than the pad-origin.
root.rotation_euler = (math.radians(22), 0, -.12)
sponge_root.parent = root
sponge_root.rotation_euler = (0, math.pi/2, 0)
sponge_root.location = (-.016, 0, .0675)
foam.hide_render = pad.hide_render = False
bpy.context.view_layer.update()
minimum_clearance = float("inf")
for obj in (foam, pad):
    for vertex in obj.data.vertices:
        p = root.matrix_world.inverted() @ obj.matrix_world @ vertex.co
        if p.z <= .0525:
            height = p.z + PIVOT_Z
            # Interpolate the inner-wall profile at this vertex height.
            for a, b in zip(PROFILE[:9], PROFILE[1:10]):
                if a[1] <= height <= b[1] and b[1] > a[1]:
                    inner_radius = a[0] + (b[0]-a[0])*(height-a[1])/(b[1]-a[1])
                    minimum_clearance = min(minimum_clearance, inner_radius-math.hypot(p.x, p.y))
                    break
assert minimum_clearance > .001, "Sponge intersects the mug wall during entry preview"
render(player_cam, "mug-standard-sponge-entry.png")
print("MUG_HOLD_VIEWS_OK", json.dumps(bounds), flush=True)
print("SPONGE_ENTRY_CLEARANCE_M", minimum_clearance, flush=True)
print("MUG_COMPLETE", ASSETS, flush=True)

"""Build a six-slot wooden rack and an open dirty-dish tray with placement poses.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_rack_and_tray.py
The two GLBs are independent. The editable .blend shows both at workstation positions.
"""
import json
import math
from pathlib import Path

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Kitchen"
DOCS = ROOT / "Docs" / "assets" / "rack-and-tray"
ASSETS.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)
RACK_MOUNT = Vector((.88, .035, .90))
TRAY_MOUNT = Vector((-.89, -.025, .90))
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


rack_group = collection("01_Dish_Rack_Asset")
tray_group = collection("02_Dirty_Tray_Asset")
studio = collection("90_Preview_Studio")


def material(name, color, roughness, metallic=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_backface_culling = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    return mat


wood = material("Rack_Honey_Wood", (.39, .19, .065), .40)
wood_light = material("Rack_Light_Wood", (.49, .27, .105), .43)
rubber = material("Rack_And_Tray_Feet", (.055, .063, .052), .85)
enamel = material("Tray_Warm_Enamel", (.76, .70, .57), .27)
rim_mat = material("Tray_Olive_Rim", (.21, .28, .20), .34)


def marker(name, position, group, parent=None, rotation=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    group.objects.link(obj)
    obj.parent = parent
    obj.location, obj.rotation_euler = position, rotation
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .025
    return obj


rack = marker("Dish_Rack", (0, 0, 0), rack_group)
tray = marker("Dirty_Tray", (0, 0, 0), tray_group)
rack["mount_blender_world"] = list(RACK_MOUNT)
tray["mount_blender_world"] = list(TRAY_MOUNT)
rack["scope"] = "Six plate poses and two inverted-mug poses; no physics, occupancy or snap logic"
tray["scope"] = "Open tray with two plate poses and one mug pose; no stacking or pickup logic"
marker("Rack_Base_Contact", (0, 0, 0), rack_group, rack)
marker("Tray_Base_Contact", (0, 0, 0), tray_group, tray)


def box(name, location, size, radius, mat, parent, group):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for linked in list(obj.users_collection):
        linked.objects.unlink(obj)
    group.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Rounded_Edges", "BEVEL")
    bevel.width, bevel.segments = radius, 3
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for face in obj.data.polygons:
        face.use_smooth = True
    normal = obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    bpy.ops.object.modifier_apply(modifier=normal.name)
    return obj


# The centre slat supports each plate at its lowest rim point.
for side in (-1, 1):
    box(f"Rack_Lower_Rail_{side}", (0, side*.185, .020), (.54, .030, .032), .003, wood, rack, rack_group)
    box(f"Rack_Upper_Rail_{side}", (0, side*.185, .185), (.52, .022, .026), .003, wood, rack, rack_group)
    for end in (-1, 1):
        box(f"Rack_Post_{end}_{side}", (end*.25, side*.185, .105), (.026, .026, .19), .003, wood, rack, rack_group)
        box(f"Rack_Foot_{end}_{side}", (end*.245, side*.185, .002), (.035, .030, .004), .001, rubber, rack, rack_group)
for i in range(7):
    box(f"Rack_Drain_Slat_{i+1:02d}", (0, -.15+i*.05, .028), (.51, .024, .016), .002, wood_light, rack, rack_group)
    x = -.219+i*.073
    for side in (-1, 1):
        box(f"Rack_Divider_{i+1:02d}_{side}", (x, side*.095, .108), (.014, .018, .144), .003, wood, rack, rack_group)
    # A slight overhang avoids coplanar faces where the bridge joins the uprights.
    box(f"Rack_Divider_Bridge_{i+1:02d}", (x, 0, .176), (.016, .212, .016), .003, wood, rack, rack_group)
for i in range(6):
    pose = marker(f"Rack_Slot_{i+1:02d}", (-.1825+i*.073, 0, .1615), rack_group, rack, (0, math.pi/2, 0))
    pose["accepts"] = "Plate_Standard diameter .250 m; copy the complete root transform"
    pose["pitch_m"] = .073

# Separate slatted module in front of the main rack, replacing the old cup pad.
cup_area = marker("Cup_Drain_Area", (.04, -.305, 0), rack_group, rack)
for side in (-1, 1):
    box(f"Cup_Mat_Support_{side}", (side*.145, 0, .010), (.024, .14, .020), .002, wood, cup_area, rack_group)
    for end in (-1, 1):
        box(f"Cup_Mat_Foot_{side}_{end}", (side*.145, end*.055, .0015), (.024, .025, .003), .0008, rubber, cup_area, rack_group)
for i in range(3):
    box(f"Cup_Mat_Slat_{i+1:02d}", (0, -.045+i*.045, .022), (.34, .026, .011), .002, wood_light, cup_area, rack_group)
for i, x in enumerate((-.045, .12), 1):
    pose = marker(f"Rack_Cup_Slot_{i:02d}", (x, -.305, .0805), rack_group, rack, (math.pi, 0, 0))
    pose["accepts"] = "Mug_Standard inverted, handle +X; root pose, not a surface point"
marker("Rack_Interaction", (0, -.20, .11), rack_group, rack)


def rounded_loop(hx, hy, radius, z, steps=12):
    points = []
    for cx, cy, start in ((hx-radius, hy-radius, 0), (-hx+radius, hy-radius, 90),
                           (-hx+radius, -hy+radius, 180), (hx-radius, -hy+radius, 270)):
        for i in range(steps+1):
            angle = math.radians(start+90*i/steps)
            points.append((cx+radius*math.cos(angle), cy+radius*math.sin(angle), z))
    return points


def tray_mesh():
    # Exterior bottom -> flared wall -> rolled rim -> interior wall -> flat floor.
    profiles = [(.287, .227, .032, .004), (.295, .235, .038, .007),
                (.299, .239, .042, .014), (.305, .245, .047, .041),
                (.305, .245, .047, .045), (.302, .242, .044, .048),
                (.298, .238, .040, .047), (.295, .235, .038, .043),
                (.288, .228, .035, .019), (.283, .223, .032, .012)]
    rings = [rounded_loop(*profile) for profile in profiles]
    n = len(rings[0])
    vertices = [v for ring in rings for v in ring]
    faces = [tuple(reversed(range(n)))]
    bands = [-1]
    for band in range(len(rings)-1):
        for i in range(n):
            nxt = (i+1) % n
            faces.append((band*n+i, band*n+nxt, (band+1)*n+nxt, (band+1)*n+i))
            bands.append(band)
    faces.append(tuple(range((len(rings)-1)*n, len(rings)*n)))
    bands.append(-1)
    mesh = bpy.data.meshes.new("Tray_Shell_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new("Tray_Shell", mesh)
    tray_group.objects.link(obj)
    obj.parent = tray
    mesh.materials.append(enamel)
    mesh.materials.append(rim_mat)
    for poly, band in zip(mesh.polygons, bands):
        poly.use_smooth = band != -1
        poly.material_index = int(3 <= band <= 6)
    return obj


shell = tray_mesh()
for x in (-.25, .25):
    for y in (-.19, .19):
        box(f"Tray_Foot_{x}_{y}", (x, y, .003), (.035, .035, .006), .0015, rubber, tray, tray_group)
for i, x in enumerate((-.137, .137), 1):
    pose = marker(f"Dirty_Plate_{i:02d}", (x, -.06, .0245), tray_group, tray)
    pose["accepts"] = "Plate_Standard flat, full root transform"
marker("Dirty_Mug_01", (0, .14, .065), tray_group, tray)["accepts"] = "Mug_Standard upright, handle +X"
marker("Tray_Interior_Surface", (0, 0, .012), tray_group, tray)
marker("Dirty_Pickup", (0, -.06, .11), tray_group, tray)

# Merge repeated wooden pieces by function, keeping editable mesh islands.
def join_parts(group, prefix, name):
    parts = [obj for obj in group.objects if obj.type == "MESH" and obj.name.startswith(prefix)]
    bpy.ops.object.select_all(action="DESELECT")
    for obj in parts:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = parts[0]
    bpy.ops.object.join()
    parts[0].name = name
    return parts[0]


join_parts(rack_group, "Rack_Lower_Rail_", "Rack_Lower_Frame")
join_parts(rack_group, "Rack_Upper_Rail_", "Rack_Upper_Frame")
join_parts(rack_group, "Rack_Post_", "Rack_Corner_Posts")
join_parts(rack_group, "Rack_Foot_", "Rack_Feet")
join_parts(rack_group, "Rack_Drain_Slat_", "Rack_Drain_Slats")
join_parts(rack_group, "Rack_Divider_", "Rack_Plate_Dividers")
join_parts(rack_group, "Cup_Mat_Support_", "Cup_Mat_Supports")
join_parts(rack_group, "Cup_Mat_Foot_", "Cup_Mat_Feet")
join_parts(rack_group, "Cup_Mat_Slat_", "Cup_Mat_Slats")
join_parts(tray_group, "Tray_Foot_", "Tray_Feet")

stats = {}
for group, filename in ((rack_group, "dish-rack"), (tray_group, "dirty-tray")):
    meshes = [obj for obj in group.objects if obj.type == "MESH"]
    for obj in meshes:
        bpy.ops.object.select_all(action="DESELECT")
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(65), island_margin=.02)
        bpy.ops.object.mode_set(mode="OBJECT")
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        assert all(edge.is_manifold for edge in bm.edges), obj.name
        assert all(face.calc_area() > 1e-13 for face in bm.faces), obj.name
        assert bm.calc_volume(signed=True) > 0, obj.name
        bm.free()
        obj.data.calc_loop_triangles()
    stats[filename] = dict(vertices=sum(len(o.data.vertices) for o in meshes),
                           triangles=sum(len(o.data.loop_triangles) for o in meshes),
                           meshes=len(meshes), nodes=len(group.objects))
    bpy.ops.object.select_all(action="DESELECT")
    for obj in group.objects:
        obj.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ASSETS / (filename+".glb")), export_format="GLB",
                              use_selection=True, export_extras=True)
print("RACK_TRAY_GEOMETRY_OK", json.dumps(stats), flush=True)
assert abs(shell.ray_cast(Vector((0, 0, .2)), Vector((0, 0, -1)))[1].z-.012) < 1e-6

# Actual dish fixtures, used only in the studio and integration checks.
for path, names in ((ROOT / "Assets" / "Dishes" / "plate-standard.blend", ["Plate_Surface"]),
                    (ROOT / "Assets" / "Dishes" / "mug-standard.blend", ["Mug_Body", "Mug_Handle"])):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.objects = names
plate_source = bpy.data.objects["Plate_Surface"]
mug_sources = [bpy.data.objects["Mug_Body"], bpy.data.objects["Mug_Handle"]]
rack.location, tray.location = RACK_MOUNT, TRAY_MOUNT
bpy.context.view_layer.update()
fixtures = []


def fixture(pose, sources):
    objects = []
    for source in sources:
        obj = bpy.data.objects.new("Preview_"+pose.name+"_"+source.name, source.data)
        studio.objects.link(obj)
        obj.matrix_world = pose.matrix_world @ source.matrix_local
        objects.append(obj)
        fixtures.append(obj)
    return objects


groups = []
for parent, prefix, sources in ((rack, "Rack_Slot_", [plate_source]), (rack, "Rack_Cup_Slot_", mug_sources),
                                (tray, "Dirty_Plate_", [plate_source]), (tray, "Dirty_Mug_", mug_sources)):
    for pose in sorted((child for child in parent.children if child.name.startswith(prefix)), key=lambda o: o.name):
        groups.append((pose.name, fixture(pose, sources)))
bpy.context.view_layer.update()


def bvh(obj):
    return BVHTree.FromPolygons([obj.matrix_world @ v.co for v in obj.data.vertices],
                               [tuple(p.vertices) for p in obj.data.polygons])


static = [obj for group in (rack_group, tray_group) for obj in group.objects if obj.type == "MESH"]
static_trees = [(obj, bvh(obj)) for obj in static]
fixture_trees = {obj.name: bvh(obj) for obj in fixtures}
for name, objects in groups:
    for obj in objects:
        for support, tree in static_trees:
            assert not fixture_trees[obj.name].overlap(tree), f"{name} intersects {support.name}"
    points = [obj.matrix_world @ v.co for obj in objects for v in obj.data.vertices]
    bottom = min(p.z for p in points)
    supported = False
    for point in (p for p in points if p.z < bottom+.0001):
        for support, tree in static_trees:
            location, normal, face, distance = tree.ray_cast(point, Vector((0, 0, -1)), .001)
            if location is not None and .0003 < distance < .0008:
                supported = True
                break
        if supported:
            break
    assert supported, name+" has no support within the 0.5mm display gap"
for i, (name_a, objects_a) in enumerate(groups):
    for name_b, objects_b in groups[i+1:]:
        for a in objects_a:
            for b in objects_b:
                assert not fixture_trees[a.name].overlap(fixture_trees[b.name]), f"{name_a} intersects {name_b}"
print("RACK_TRAY_PLACEMENT_OK", len(groups), "occupied poses; mesh intersections and support checked", flush=True)


def camera(name, location, target, scale):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.type, data.ortho_scale, data.clip_start = "ORTHO", scale, .001
    return obj


def render(cam, filename):
    scene.camera = cam
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


for name, location, energy, size in (("Preview_Key", (-1, -1.5, 2.5), 200, 1.8),
                                     ("Preview_Fill", (2, -.3, 2.0), 100, 1.5),
                                     ("Preview_Rim", (0, 1.0, 2.1), 130, 1.0)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, .95))-obj.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, .8999))
floor = bpy.context.object
floor.name = "Preview_Ground"
for group in list(floor.users_collection):
    group.objects.unlink(floor)
studio.objects.link(floor)
floor.data.materials.append(material("Preview_Sage_Ground", (.16, .22, .215), .9))
scene.render.engine = "CYCLES"
scene.cycles.samples = 40
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.22, .22, .22)
scene.view_settings.view_transform = "AgX"
rack_cam = camera("Preview_Rack", RACK_MOUNT+Vector((.65, -.9, .62)), RACK_MOUNT+Vector((0, -.07, .105)), .94)
tray_cam = camera("Preview_Tray", TRAY_MOUNT+Vector((.60, -.85, .75)), TRAY_MOUNT+Vector((0, 0, .025)), .84)
for obj in fixtures:
    obj.hide_render = True
render(rack_cam, "dish-rack-overview.png")
render(tray_cam, "dirty-tray-overview.png")
for obj in fixtures:
    obj.hide_render = False
render(rack_cam, "dish-rack-loaded.png")
render(tray_cam, "dirty-tray-loaded.png")
detail = camera("Preview_Slot_Clearance", RACK_MOUNT+Vector((.68, -.48, .39)), RACK_MOUNT+Vector((.10, 0, .12)), .48)
render(detail, "rack-tray-slot-detail.png")
for obj in fixtures:
    obj.hide_render = True
    obj.hide_set(True)
scene.camera = camera("Preview_Asset_Pair", (1.0, -2.8, 2.65), (0, -.03, 1.00), 2.65)
studio.hide_viewport = True
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        region = area.spaces.active.region_3d
        region.view_distance = 2.5
        region.view_location = (0, -.03, 1.00)
        region.view_rotation = scene.camera.rotation_euler.to_quaternion()
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "dish-rack-and-tray.blend"))

# Assemble an in-memory preview, preserving the original greybox and all assets.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for obj in list(scene.objects):
    if (obj.name.startswith(("Dirty_Tray_", "Rack_Peg_", "Proxy_Dirty_", "Proxy_Clean_"))
            or obj.name in ("Clean_Rack_Base", "Cup_Return_Pad", "Counter_Left", "Counter_Right", "Counter_Front", "Counter_Back", "Sink_Open_Shell",
                            "Drain_Placeholder", "Faucet_Proxy", "Faucet_Base", "Spray_Head_Proxy", "Sponge_Proxy", "QA_Held_Plate_250mm",
                            "Soap_Bottle_Proxy", "Soap_Pump_Proxy", "Soap_Nozzle_Proxy")
            or obj.name.startswith("Faucet_Switch_") and obj.type == "MESH"):
        obj.hide_render = True
for path, names in ((ASSETS / "dish-rack-and-tray.blend", ["01_Dish_Rack_Asset", "02_Dirty_Tray_Asset"]),
                    (ASSETS / "sink-countertop.blend", ["01_Sink_Countertop_Asset"]),
                    (ASSETS / "faucet-pullout.blend", ["01_Faucet_Asset"]),
                    (ROOT / "Assets" / "Tools" / "soap-dispenser.blend", ["01_Soap_Dispenser_Asset"]),
                    (ROOT / "Assets" / "Tools" / "sponge-standard.blend", ["01_Sponge_Asset"])):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = names
    for group in target.collections:
        scene.collection.children.link(group)
bpy.data.objects["Sink_Countertop"].location.z = .90
bpy.data.objects["Faucet_Assembly"].location = (.16, .32, .90)
bpy.data.objects["Soap_Dispenser"].location = (.535, .26, .90)
bpy.data.objects["Sponge_Standard"].location = (-.30, .17, .9285)
with bpy.data.libraries.load(str(ASSETS / "dish-rack-and-tray.blend"), link=False) as (source, target):
    target.objects = [name for name in source.objects if name.startswith(("Preview_Rack_Slot_", "Preview_Rack_Cup_Slot_", "Preview_Dirty_Plate_", "Preview_Dirty_Mug_"))]
for obj in target.objects:
    scene.collection.objects.link(obj)
    obj.hide_render = False
    obj.hide_set(False)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 40
scene.cycles.transparent_max_bounces = 12
render(bpy.data.objects["Player_Camera"], "rack-tray-player.png")
player = bpy.data.objects["Player_Camera"]
eye = player.matrix_world.translation.copy()
for name, mount, offset, prefixes in (
    ("rack-player-look-right.png", RACK_MOUNT, (0, -.06, .13), ("Preview_Rack_Slot_", "Preview_Rack_Cup_Slot_")),
    ("tray-player-look-left.png", TRAY_MOUNT, (0, 0, .04), ("Preview_Dirty_Plate_", "Preview_Dirty_Mug_")),
):
    view = player.copy()
    view.data = player.data.copy()
    scene.collection.objects.link(view)
    view.parent = None
    view.location = eye
    view.rotation_euler = (mount+Vector(offset)-eye).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    witnesses = [o for o in scene.objects if o.type == "MESH" and o.name.startswith(prefixes)]
    points = [world_to_camera_view(scene, view, obj.matrix_world @ vertex.co)
              for obj in witnesses for vertex in obj.data.vertices]
    assert points and all(.02 < p.x < .98 and .02 < p.y < .98 and p.z > view.data.clip_start for p in points), name+" clips dishes"
    print("RACK_TRAY_LOOK_VIEW_OK", name, flush=True)
    render(view, name)
print("RACK_TRAY_COMPLETE", ASSETS, flush=True)

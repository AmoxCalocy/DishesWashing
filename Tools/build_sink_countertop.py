"""Build the fitted sink, perforated drain and counter aperture with Blender CLI.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_sink_countertop.py
The asset origin is the countertop surface centre; place it at world Z=.90 m.
"""
import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Kitchen"
DOCS = ROOT / "Docs" / "assets" / "sink-countertop"
ASSETS.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)
N = 192
CY = -.02
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


asset = collection("01_Sink_Countertop_Asset")
studio = collection("90_Preview_Studio")


def material(name, color, metallic=0, roughness=.5):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_backface_culling = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat


steel = material("Sink_Satin_Stainless", (.52, .56, .59), 1, .30)
polished = material("Drain_Polished_Stainless", (.62, .65, .67), 1, .22)
wood = material("Counter_Warm_Wood_Base", (.38, .20, .085), 0, .48)


def marker(name, location, parent=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = location
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .045
    return obj


root = marker("Sink_Countertop", (0, 0, 0))
root["placement"] = "Origin = counter surface centre; Blender world Z / Godot world Y = .90 m"
root["counter_m"] = [2.60, .80, .04]
root["cutout_m"] = [.92, .54]
root["scope"] = "Independent fitted asset; input, water and physics are implemented in Godot"


def rounded_loop(hx, hy, radius, z, cy=CY):
    """Uniform angular rays intersect a rounded rectangle; circle loops align."""
    points = []
    for i in range(N):
        angle = math.tau*i/N
        dx, dy = math.cos(angle), math.sin(angle)
        t = min(hx/max(abs(dx), 1e-12), hy/max(abs(dy), 1e-12))
        if abs(t*dx) > hx-radius and abs(t*dy) > hy-radius:
            cx = math.copysign(hx-radius, dx)
            c_y = math.copysign(hy-radius, dy)
            dot = dx*cx + dy*c_y
            t = dot + math.sqrt(max(0, dot*dot - cx*cx - c_y*c_y + radius*radius))
        points.append((t*dx, t*dy+cy, z))
    return points


def circle(radius, z):
    return [(radius*math.cos(math.tau*i/N), CY+radius*math.sin(math.tau*i/N), z) for i in range(N)]


def mesh_from_loops(name, loops, mat, parent=root, smooth=True):
    vertices = [v for ring in loops for v in ring]
    faces = []
    for band in range(len(loops)):
        following = (band+1) % len(loops)
        for i in range(N):
            nxt = (i+1) % N
            faces.append((band*N+i, band*N+nxt, following*N+nxt, following*N+i))
    mesh = bpy.data.meshes.new(name+"_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    asset.objects.link(obj)
    obj.parent = parent
    mesh.materials.append(mat)
    for polygon in mesh.polygons:
        polygon.use_smooth = smooth
    return obj


# One closed slab with a real rounded aperture and 2 mm edge chamfers.
counter = mesh_from_loops("Countertop_Cutout", [
    rounded_loop(1.298, .398, .010, 0, 0),
    rounded_loop(.462, .272, .067, 0),
    rounded_loop(.460, .270, .065, -.002),
    rounded_loop(.460, .270, .065, -.038),
    rounded_loop(.462, .272, .067, -.040),
    rounded_loop(1.298, .398, .010, -.040, 0),
    rounded_loop(1.300, .400, .012, -.038, 0),
    rounded_loop(1.300, .400, .012, -.002, 0),
], wood, smooth=False)

# The shell has an open mouth and a through-hole at the drain. Following the
# inside, hole wall and underside produces a single closed material boundary.
inside = [(.478, .288, .070, .0000), (.480, .290, .072, .0045),
          (.4795, .2895, .0715, .006), (.476, .286, .069, .007),
          (.443, .263, .070, .007), (.435, .255, .066, .006),
          (.430, .250, .064, .002), (.426, .246, .063, -.006),
          (.424, .244, .063, -.014), (.416, .236, .065, -.060),
          (.404, .224, .067, -.150), (.397, .217, .070, -.204),
          (.391, .211, .072, -.222), (.382, .202, .075, -.235),
          (.370, .190, .075, -.242), (.350, .170, .078, -.244)]
outside = [(.350, .170, .078, -.247), (.372, .192, .077, -.245),
           (.385, .205, .078, -.238), (.394, .214, .075, -.225),
           (.400, .220, .073, -.207), (.407, .227, .070, -.150),
           (.419, .239, .068, -.060), (.427, .247, .066, -.014),
           (.432, .252, .067, -.004), (.445, .265, .070, .0000)]
basin = mesh_from_loops("Sink_Basin", [rounded_loop(*p) for p in inside] +
                        [circle(.090, -.248), circle(.045, -.250),
                         circle(.045, -.253), circle(.090, -.251)] +
                        [rounded_loop(*p) for p in outside], steel)

drain_root = marker("Drain_Assembly", (0, 0, 0), root)
drain = mesh_from_loops("Drain_Flange_And_Outlet", [circle(r, z) for r, z in (
    (.058, -.2478), (.054, -.2478), (.047, -.2515), (.0425, -.2535),
    (.041, -.256), (.036, -.256), (.032, -.267), (.030, -.271),
    (.030, -.325), (.033, -.325), (.033, -.270), (.0445, -.256),
    (.049, -.254), (.058, -.2505),
)], polished, drain_root)


def assign(obj, name, parent, mat=None):
    obj.name = name
    for group in list(obj.users_collection):
        group.objects.unlink(obj)
    asset.objects.link(obj)
    obj.parent = parent
    if mat:
        obj.data.materials.append(mat)
    return obj


# Perforate an actual steel disk with twelve rounded radial slots.
bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=.040, depth=.002, location=(0, CY, -.255))
strainer = assign(bpy.context.object, "Drain_Strainer", drain_root, polished)
for i in range(12):
    angle = math.tau*i/12
    bpy.ops.mesh.primitive_cube_add(size=1, location=(.024*math.cos(angle), CY+.024*math.sin(angle), -.255))
    cutter = bpy.context.object
    cutter.dimensions = (.021, .0035, .012)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    bevel = cutter.modifiers.new("Round_Slot", "BEVEL")
    bevel.width, bevel.segments = .0015, 3
    bpy.context.view_layer.objects.active = cutter
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    cutter.rotation_euler.z = angle
    boolean = strainer.modifiers.new("Slot", "BOOLEAN")
    boolean.operation, boolean.solver, boolean.object = "DIFFERENCE", "EXACT", cutter
    bpy.context.view_layer.objects.active = strainer
    bpy.ops.object.modifier_apply(modifier=boolean.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
for polygon in strainer.data.polygons:
    polygon.use_smooth = abs(polygon.normal.z) < .5

for name, position in (
    ("Countertop_Surface", (0, 0, 0)), ("Cutout_Center", (0, CY, 0)),
    ("Drain_Center", (0, CY, -.254)), ("Drain_Outlet", (0, CY, -.325)),
    ("Faucet_Mount", (.16, .320, 0)), ("Faucet_Switch_Mount", (.305, .320, 0)),
    ("Sponge_Rest_Surface", (-.30, .17, .0285)),
):
    marker(name, position, root)

meshes = (counter, basin, drain, strainer)
for obj in meshes:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=.02)
    bpy.ops.object.mode_set(mode="OBJECT")
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    assert all(edge.is_manifold for edge in bm.edges), obj.name+" is not closed"
    assert all(face.calc_area() > 1e-12 for face in bm.faces), obj.name+" has degenerate faces"
    assert bm.calc_volume(signed=True) > 0, obj.name+" has inward normals"
    bm.free()
    obj.data.calc_loop_triangles()


def ray(obj, origin, direction=(0, 0, -1)):
    inverse = obj.matrix_world.inverted()
    hit, point, normal, face = obj.ray_cast(inverse @ Vector(origin), inverse.to_3x3() @ Vector(direction))
    return hit, obj.matrix_world @ point, normal, face


bpy.context.view_layer.update()
assert not ray(counter, (0, CY, .1))[0], "Counter aperture is capped"
assert ray(counter, (.80, 0, .1))[0]
assert not ray(basin, (0, CY, .1))[0], "Drain hole is capped"
assert not ray(drain, (0, CY, .1))[0], "Outlet is capped"
assert not ray(strainer, (.024, CY, -.20))[0], "Strainer slot is capped"
assert ray(strainer, (0, CY, -.20))[0], "Strainer hub is missing"
hit, point, normal, _ = ray(basin, (.47, CY, -.01), (0, 0, 1))
assert hit and abs(point.z) < 1e-6 and normal.z < -.99, "Rim underside must sit on counter Z=0"
for name, x, y in (("Plate_Return_Surface", -.23, .045), ("Mug_Return_Surface", .23, .10)):
    hit, point, normal, _ = ray(basin, (x, y, .1))
    assert hit and -.25 < point.z < -.24 and normal.z > .99
    target = marker(name, point, root)
    target["purpose"] = "Surface point only; placement must consider dish footprint and local floor slope"
    target["normal_blender"] = list(normal)
    print("SINK_RETURN_SURFACE", name, tuple(point), flush=True)
print("SINK_GEOMETRY_OK", sum(len(o.data.vertices) for o in meshes), "vertices",
      sum(len(o.data.loop_triangles) for o in meshes), "triangles", flush=True)

bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "sink-countertop.glb"), export_format="GLB",
                          use_selection=True, export_extras=True)


def camera(name, location, target, ortho):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.type, data.ortho_scale, data.clip_start = "ORTHO", ortho, .001
    return obj


def render(cam, filename):
    scene.camera = cam
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


for name, position, energy, size in (("Preview_Key", (-1.4, -.9, 2), 220, 1.4),
                                     ("Preview_Fill", (1.6, .8, 1.6), 160, 1.2),
                                     ("Preview_Rim_Light", (0, 1.2, .8), 80, .7)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = position
    obj.rotation_euler = (-obj.location).to_track_quat("-Z", "Y").to_euler()
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.18, .22, .25)
scene.view_settings.view_transform = "AgX"
hero = camera("Preview_Sink_Overview", (1.1, -1.9, 1.65), (0, -.02, -.05), 2.90)
render(hero, "sink-countertop-overview.png")
detail = camera("Preview_Drain_Detail", (.16, -.27, .14), (0, CY, -.255), .22)
render(detail, "sink-drain-detail.png")
for obj in (basin, drain, strainer):
    obj.hide_render = True
aperture = camera("Preview_True_Cutout", (.65, -1.7, 1.8), (0, CY, -.03), 1.30)
render(aperture, "sink-countertop-cutout.png")
for obj in (basin, drain, strainer):
    obj.hide_render = False
studio.hide_viewport = True
scene.camera = hero
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_location = (0, 0, -.1)
        area.spaces.active.region_3d.view_distance = 3.3
        area.spaces.active.region_3d.view_rotation = hero.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
basin.select_set(True)
bpy.context.view_layer.objects.active = basin
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "sink-countertop.blend"))

# Replace only the corresponding placeholders in memory for integration previews.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for path, name in ((ASSETS / "sink-countertop.blend", "01_Sink_Countertop_Asset"),
                   (ROOT / "Assets" / "Dishes" / "plate-standard.blend", "01_Plate_Asset"),
                   (ROOT / "Assets" / "Dishes" / "mug-standard.blend", "01_Mug_Asset")):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [name]
    scene.collection.children.link(target.collections[0])
root = bpy.data.objects["Sink_Countertop"]
root.location.z = .90
basin = bpy.data.objects["Sink_Basin"]
for name in ("Counter_Left", "Counter_Right", "Counter_Front", "Counter_Back", "Sink_Open_Shell",
             "Drain_Placeholder", "QA_Held_Plate_250mm"):
    bpy.data.objects[name].hide_render = True
# Match the reviewed mounting surfaces; these edits affect previews only.
for name in ("Faucet_Proxy", "Faucet_Base", "Spray_Head_Proxy"):
    bpy.data.objects[name].location += Vector((0, .015, -.0095))
for name in ("Faucet_Switch_Base", "Faucet_Switch_Body", "Faucet_Switch_Hinge", "Faucet_Switch_Pivot"):
    bpy.data.objects[name].location += Vector((0, .030, -.001))
plate_root = bpy.data.objects["Plate_Standard"]
mug_root = bpy.data.objects["Mug_Standard"]
bpy.context.view_layer.update()
for obj, marker_name, offset in ((plate_root, "Plate_Return_Surface", .012),
                                  (mug_root, "Mug_Return_Surface", .0525)):
    point = bpy.data.objects[marker_name].matrix_world.translation
    obj.location = point + Vector((0, 0, offset+.001))
    bpy.context.view_layer.update()
    clearance = float("inf")
    for child in obj.children:
        if child.type == "MESH":
            for vertex in child.data.vertices:
                p = child.matrix_world @ vertex.co
                hit, floor_point, _, _ = ray(basin, (p.x, p.y, 1.2))
                assert hit, "Dish footprint leaves the basin"
                clearance = min(clearance, p.z-floor_point.z)
    obj.location.z += .0005-clearance
    print("DISH_PLACEMENT_OK", obj.name, tuple(obj.location), "minimum_clearance_m=.0005", flush=True)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 40
render(bpy.data.objects["Player_Camera"], "sink-countertop-player.png")
scene.render.resolution_y = 1000
render(bpy.data.objects["Preview_Overview"], "sink-countertop-workstation.png")
print("SINK_COMPLETE", ASSETS, flush=True)

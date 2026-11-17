"""Build the wall clipboard and replaceable paper, then render workstation previews.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_order_clipboard.py
Order progress, interaction and collision are implemented separately in Godot.
"""
import json
import math
import subprocess
from pathlib import Path

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Kitchen"
DOCS = ROOT / "Docs" / "assets" / "order-clipboard"
TEXTURES = ASSETS / "Textures"
MOUNT = Vector((1.2205, .398, 1.24))
DOCS.mkdir(parents=True, exist_ok=True)
subprocess.run(["powershell.exe", "-NoProfile", "-ExecutionPolicy", "RemoteSigned", "-File",
                str(ROOT / "Tools" / "build_order_paper_textures.ps1")], check=True)
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


asset = collection("01_Order_Clipboard_Asset")
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


wood = material("Clipboard_Honey_Wood", (.36, .17, .065), .43)
brass = material("Clipboard_Brushed_Brass", (.57, .36, .12), .32, .78)
rubber = material("Clipboard_Back_Pads", (.075, .064, .05), .85)
paper_back = material("Order_Paper_Back", (.92, .86, .73), .90)
paper_front = material("Order_Paper_Print", (1, 1, 1), .90)
print_image = bpy.data.images.load(str(TEXTURES / "order-paper-breakfast.png"))
blank_image = bpy.data.images.load(str(TEXTURES / "order-paper-blank.png"))
for img in (print_image, blank_image):
    img.pack()
texture = paper_front.node_tree.nodes.new("ShaderNodeTexImage")
texture.name = "Replace_Order_Texture"
texture.image = print_image
paper_front.node_tree.links.new(texture.outputs["Color"], paper_front.node_tree.nodes["Principled BSDF"].inputs["Base Color"])


def marker(name, position, parent=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = position
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .018
    return obj


root = marker("Order_Clipboard", (0, 0, 0))
root["mount_blender_world"] = list(MOUNT)
root["front_axis"] = "Blender -Y / Godot +Z; upright +Z / +Y"
root["scope"] = "Wall prop with independent paper and replaceable albedo; no order logic or collision"
marker("Board_Wall_Contact", (0, 0, 0), root)
interaction = marker("Order_Interaction", (0, -.021, -.012), root)
surface = marker("Paper_Surface", (0, -.0158, -.012), root)
surface.rotation_euler.x = math.pi / 2
surface["paper_size_m"] = [.198, .280]
surface["axes"] = "Marker +X right, +Y up, +Z forward in Blender; use mesh UV for texture replacement"
clip = marker("Clip_Assembly", (0, 0, 0), root)


def move_to_asset(obj, name, parent, mat):
    obj.name = name
    for group in list(obj.users_collection):
        group.objects.unlink(obj)
    asset.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    return obj


def finish(obj, bevel=0):
    bpy.context.view_layer.objects.active = obj
    if bevel:
        mod = obj.modifiers.new("Soft_Edges", "BEVEL")
        mod.width, mod.segments = bevel, 3
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for face in obj.data.polygons:
        face.use_smooth = True
    mod = obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj


def box(name, location, size, bevel, mat, parent=root):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    move_to_asset(obj, name, parent, mat)
    return finish(obj, bevel)


def mesh_object(name, vertices, faces, mat, parent):
    mesh = bpy.data.meshes.new(name + "_Mesh")
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
    return obj


def extrude_outline(name, points, front, back, mat, parent=root):
    n = len(points)
    vertices = [(x, y, z) for y in (front, back) for x, z in points]
    faces = [tuple(range(n)), tuple(reversed(range(n, n*2)))]
    faces += [(i, (i+1) % n, (i+1) % n+n, i+n) for i in range(n)]
    return mesh_object(name, vertices, faces, mat, parent)


def rounded_outline(width, height, radius):
    points = []
    hx, hz = width/2, height/2
    for x, z, start in ((hx-radius, hz-radius, 0), (-hx+radius, hz-radius, 90),
                        (-hx+radius, -hz+radius, 180), (hx-radius, -hz+radius, 270)):
        for i in range(9):
            angle = math.radians(start + 90*i/8)
            points.append((x+radius*math.cos(angle), z+radius*math.sin(angle)))
    return points


board = finish(extrude_outline("Board_Body", rounded_outline(.230, .330, .012), -.015, -.003, wood), .001)
# Four shallow pads define a wall contact plane without embedding the board in the wall.
pads = []
for x in (-.087, .087):
    for z in (-.135, .135):
        pads.append(box("Back_Pad", (x, -.0015, z), (.018, .003, .020), .001, rubber))
bpy.ops.object.select_all(action="DESELECT")
for obj in pads:
    obj.select_set(True)
bpy.context.view_layer.objects.active = pads[0]
bpy.ops.object.join()
pads[0].name = "Board_Back_Pads"

# A fixed riveted base, hinge barrel, pressed metal jaw and actual hanging eye.
box("Clip_Base", (0, -.0166, .124), (.083, .0024, .027), .001, brass, clip)
outline = [(-.041, .103), (.041, .103), (.041, .116), (.026, .120),
           (.014, .131), (.011, .156), (.008, .164), (0, .168),
           (-.008, .164), (-.011, .156), (-.014, .131), (-.026, .120), (-.041, .116)]
jaw = extrude_outline("Clip_Jaw", outline, -.025, -.0222, brass, clip)
bpy.ops.mesh.primitive_cylinder_add(vertices=40, radius=.0042, depth=.03, location=(0, -.0236, .155), rotation=(math.pi/2, 0, 0))
cutter = bpy.context.object
bpy.context.view_layer.objects.active = jaw
mod = jaw.modifiers.new("True_Hanging_Eye", "BOOLEAN")
mod.operation, mod.object = "DIFFERENCE", cutter
bpy.ops.object.modifier_apply(modifier=mod.name)
bpy.data.objects.remove(cutter, do_unlink=True)
finish(jaw, .00065)
box("Clip_Paper_Lip", (0, -.0201, .1037), (.081, .0084, .005), .0014, brass, clip)
bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=.0033, depth=.064, location=(0, -.0202, .131), rotation=(0, math.pi/2, 0))
pin = move_to_asset(bpy.context.object, "Clip_Hinge_Pin", clip, brass)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
finish(pin, .0004)
rivets = []
for x in (-.033, .033):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=10, radius=1, location=(x, -.0184, .130))
    obj = move_to_asset(bpy.context.object, "Clip_Rivet", clip, brass)
    obj.scale = (.003, .0014, .003)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    rivets.append(obj)
bpy.ops.object.select_all(action="DESELECT")
for obj in rivets:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rivets[0]
bpy.ops.object.join()
rivets[0].name = "Clip_Rivets"

# One thin, closed sheet. Only the last 28 mm of the lower-right corner curls.
nx, nz = 12, 20
vertices, faces = [], []
for back in (False, True):
    for j in range(nz+1):
        z = -.152 + .280*j/nz
        for i in range(nx+1):
            x = -.099 + .198*i/nx
            corner = max(0, 1 - math.hypot((.099-x)/.028, (z+.152)/.028))
            y = -.0158 - .003*corner*corner + (.00045 if back else 0)
            vertices.append((x, y, z))
count = (nx+1)*(nz+1)
for back in (False, True):
    offset = count if back else 0
    for j in range(nz):
        for i in range(nx):
            a = offset+j*(nx+1)+i
            face = (a, a+1, a+nx+2, a+nx+1)
            faces.append(tuple(reversed(face)) if back else face)
front_faces = nx*nz
boundary = list(range(nx+1))
boundary += [j*(nx+1)+nx for j in range(1, nz+1)]
boundary += [nz*(nx+1)+i for i in range(nx-1, -1, -1)]
boundary += [j*(nx+1) for j in range(nz-1, 0, -1)]
for a, b in zip(boundary, boundary[1:]+boundary[:1]):
    faces.append((a, b, b+count, a+count))
paper = mesh_object("Order_Paper", vertices, faces, paper_front, root)
paper.data.materials.append(paper_back)
paper["replaceable_surface"] = "Material slot 0 only: Order_Paper_Print, full 0-1 front UV, upright"
paper["paper_thickness_m"] = .00045
uv = paper.data.uv_layers.new(name="UVMap")
for poly in paper.data.polygons:
    poly.material_index = 0 if poly.index < front_faces else 1
    for loop in poly.loop_indices:
        co = paper.data.vertices[paper.data.loops[loop].vertex_index].co
        uv.data[loop].uv = ((co.x+.099)/.198, (co.z+.152)/.280)

meshes = [obj for obj in asset.objects if obj.type == "MESH"]
for obj in meshes:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    if obj != paper:
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
# The jaw eye is a real through-hole; paper print sits above the board without z-fighting.
assert not jaw.ray_cast(Vector((0, -.05, .155)), Vector((0, 1, 0)))[0]
assert paper.ray_cast(Vector((0, -.05, 0)), Vector((0, 1, 0)))[0]
assert min(v.co.y for v in paper.data.vertices[:count]) < -.0158
stats = dict(vertices=sum(len(o.data.vertices) for o in meshes),
             triangles=sum(len(o.data.loop_triangles) for o in meshes), meshes=len(meshes),
             nodes=len(asset.objects), materials=5)
print("CLIPBOARD_GEOMETRY_OK", json.dumps(stats), flush=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "order-clipboard.glb"), export_format="GLB",
                          use_selection=True, export_extras=True)


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


for name, pos, energy, size in (("Preview_Key", (-.4, -.6, .6), 28, .65),
                                 ("Preview_Fill", (.5, -.4, .1), 12, .45)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = (-obj.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, .004, 0), rotation=(math.pi/2, 0, 0))
backdrop = bpy.context.object
backdrop.name = "Preview_Backdrop"
for group in list(backdrop.users_collection):
    group.objects.unlink(backdrop)
studio.objects.link(backdrop)
backdrop.data.materials.append(material("Preview_Sage", (.16, .22, .205), .9))
scene.render.engine = "CYCLES"
scene.cycles.samples = 40
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1400, 1200
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.20, .20, .20)
scene.view_settings.view_transform = "AgX"
hero = camera("Preview_Clipboard", (.30, -.85, .18), (0, -.012, 0), .46)
render(hero, "order-clipboard-overview.png")
detail = camera("Preview_Clip_Detail", (.14, -.32, .20), (0, -.017, .129), .15)
render(detail, "order-clipboard-clip-detail.png")
texture.image = blank_image
render(hero, "order-clipboard-blank.png")
texture.image = print_image
scene.camera = hero
studio.hide_viewport = True
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        region = area.spaces.active.region_3d
        region.view_distance = .5
        region.view_location = (0, -.01, 0)
        region.view_rotation = hero.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
board.select_set(True)
bpy.context.view_layer.objects.active = board
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "order-clipboard.blend"))

# Workstation integration exists only in memory; all previous deliverables stay unchanged.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for obj in list(scene.objects):
    if (obj.name.startswith(("Dirty_Tray_", "Rack_Peg_", "Proxy_Dirty_", "Proxy_Clean_"))
            or obj.name in ("Clean_Rack_Base", "Cup_Return_Pad", "Counter_Left", "Counter_Right", "Counter_Front", "Counter_Back", "Sink_Open_Shell",
                            "Drain_Placeholder", "Faucet_Proxy", "Faucet_Base", "Spray_Head_Proxy", "Sponge_Proxy", "QA_Held_Plate_250mm",
                            "Soap_Bottle_Proxy", "Soap_Pump_Proxy", "Soap_Nozzle_Proxy", "Order_Board_Proxy", "Order_Paper_Proxy")
            or obj.name.startswith("Faucet_Switch_") and obj.type == "MESH"):
        obj.hide_render = True
        obj.hide_set(True)
for path, names in ((ASSETS / "order-clipboard.blend", ["01_Order_Clipboard_Asset"]),
                    (ASSETS / "dish-rack-and-tray.blend", ["01_Dish_Rack_Asset", "02_Dirty_Tray_Asset"]),
                    (ASSETS / "sink-countertop.blend", ["01_Sink_Countertop_Asset"]),
                    (ASSETS / "faucet-pullout.blend", ["01_Faucet_Asset"]),
                    (ROOT / "Assets" / "Tools" / "soap-dispenser.blend", ["01_Soap_Dispenser_Asset"]),
                    (ROOT / "Assets" / "Tools" / "sponge-standard.blend", ["01_Sponge_Asset"]),
                    (ROOT / "Assets" / "Dishes" / "plate-standard.blend", ["01_Plate_Asset"])):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = names
    for group in target.collections:
        scene.collection.children.link(group)
bpy.data.objects["Sink_Countertop"].location.z = .90
bpy.data.objects["Faucet_Assembly"].location = (.16, .32, .90)
bpy.data.objects["Soap_Dispenser"].location = (.535, .26, .90)
bpy.data.objects["Sponge_Standard"].location = (-.30, .17, .9285)
root = bpy.data.objects["Order_Clipboard"]
root.location = MOUNT
paper = bpy.data.objects["Order_Paper"]
with bpy.data.libraries.load(str(ASSETS / "dish-rack-and-tray.blend"), link=False) as (source, target):
    target.objects = [name for name in source.objects if name.startswith(("Preview_Rack_Slot_", "Preview_Rack_Cup_Slot_", "Preview_Dirty_Plate_", "Preview_Dirty_Mug_"))]
for obj in target.objects:
    scene.collection.objects.link(obj)
    obj.hide_render = False
    obj.hide_set(False)
plate = bpy.data.objects["Plate_Surface"]
plate.hide_render = True
plate.hide_set(True)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 40
scene.cycles.transparent_max_bounces = 12
player = bpy.data.objects["Player_Camera"]
bpy.context.view_layer.update()
points = [world_to_camera_view(scene, player, o.matrix_world @ v.co)
          for o in bpy.data.collections["01_Order_Clipboard_Asset"].objects if o.type == "MESH" for v in o.data.vertices]
assert all(.003 < p.x < .997 and .003 < p.y < .997 and p.z > player.data.clip_start for p in points), "Default camera crops the clipboard"
print("CLIPBOARD_FRAMING_OK", [min(p.x for p in points), max(p.x for p in points), min(p.y for p in points), max(p.y for p in points)], flush=True)
render(player, "order-clipboard-player.png")
plate_root = bpy.data.objects["Plate_Standard"]
plate_root.parent = bpy.data.objects["Carry_Anchor"]
plate_root.location = (0, 0, 0)
plate.hide_render = False
plate.hide_set(False)
bpy.context.view_layer.update()
# Rays to the printed area check actual line of sight with a carried plate and fully loaded rack.
depsgraph = bpy.context.evaluated_depsgraph_get()
eye = player.matrix_world.translation.copy()
for x in (-.095, -.09, -.07, 0, .07, .09, .095):
    for z in (-.145, -.12, -.085, -.075, -.065, -.045, 0, .055):
        target = root.matrix_world @ Vector((x, -.0158, z))
        hit, location, normal, index, obj, matrix = scene.ray_cast(depsgraph, eye, (target-eye).normalized(), distance=(target-eye).length+.01)
        assert hit and obj.name == "Order_Paper", f"Order paper occluded by {obj.name if obj else 'nothing'} at {x,z}"
print("CLIPBOARD_VISIBILITY_OK 56 paper targets with carried plate and loaded rack", flush=True)
render(player, "order-clipboard-carry.png")
view = player.copy()
view.data = player.data.copy()
scene.collection.objects.link(view)
view.parent = None
view.location = eye
view.rotation_euler = (MOUNT+Vector((0, -.016, -.012))-eye).to_track_quat("-Z", "Y").to_euler()
plate_root.parent = view
plate_root.location = (0, -.22, -.78)
bpy.context.view_layer.update()
render(view, "order-clipboard-look-right.png")
print("CLIPBOARD_COMPLETE", ASSETS / "order-clipboard.glb", flush=True)

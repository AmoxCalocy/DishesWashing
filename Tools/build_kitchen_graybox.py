"""Build the wash-station blockout with Blender's background CLI.

Run from any directory:
    blender --background --factory-startup --python build_kitchen_graybox.py
Outputs are relative to this script's project, in Assets/Graybox and Docs.
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Graybox"
DOCS = ROOT / "Docs"
ASSETS.mkdir(parents=True, exist_ok=True)

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)

scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
scene.render.engine = "CYCLES"
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (0.25, 0.25, 0.25)
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.66, 0.72, 0.78, 1)
scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35
scene.view_settings.view_transform = "AgX"
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


structure = collection("01_Structure")
sink = collection("02_Open_Sink")
dirty = collection("03_Dirty_Area")
clean = collection("04_Clean_Area")
tools = collection("05_Tool_Placeholders")
backdrop = collection("06_Backdrop")
markers = collection("07_Interaction_Markers")
preview = collection("90_Preview_Lighting")
proxies = collection("91_Hold_Size_Check")


def material(name, color, metallic=0.0, roughness=0.65):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    result.use_nodes = True
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return result


chalk = material("GB_Chalk", (0.63, 0.65, 0.63))
counter_mat = material("GB_Counter", (0.44, 0.45, 0.43))
recess_mat = material("GB_Recess", (0.22, 0.25, 0.26))
floor_mat = material("GB_Floor", (0.36, 0.38, 0.37))
wall_mat = material("GB_Wall", (0.53, 0.59, 0.58))
sink_mat = material("GB_Sink", (0.38, 0.46, 0.49), 0.25, 0.42)
dirty_mat = material("GB_Dirty_Zone", (0.55, 0.43, 0.32))
clean_mat = material("GB_Clean_Zone", (0.32, 0.49, 0.45))
tool_mat = material("GB_Tool", (0.63, 0.53, 0.32))
dish_mat = material("GB_Dish_Proxy", (0.79, 0.79, 0.74))
window_mat = material("GB_Window", (0.67, 0.77, 0.80))


def assign(obj, name, group, mat=None):
    obj.name = name
    for linked in list(obj.users_collection):
        linked.objects.unlink(obj)
    group.objects.link(obj)
    if mat is not None:
        obj.data.materials.append(mat)
    return obj


def bevel(obj, width=0.008):
    modifier = obj.modifiers.new("Edge_Softening", "BEVEL")
    modifier.width = width
    modifier.segments = 3
    modifier = obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    modifier.keep_sharp = True


def box(name, location, size, group, mat, edge=0.008):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = assign(bpy.context.object, name, group, mat)
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if edge:
        bevel(obj, edge)
    return obj


def cylinder(name, location, radius, depth, group, mat, rotation=(0, 0, 0)):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth,
                                      location=location, rotation=rotation)
    obj = assign(bpy.context.object, name, group, mat)
    bevel(obj, 0.003)
    return obj


def marker(name, location, parent=None):
    obj = bpy.data.objects.new(name, None)
    markers.objects.link(obj)
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = 0.06
    obj.parent = parent
    obj.location = location
    return obj


def camera(name, location, target, lens, group):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    group.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    data.lens = lens
    data.sensor_width = 36
    data.sensor_fit = "HORIZONTAL"
    data.clip_start = 0.03
    data.clip_end = 100
    return obj


# The countertop is four separate pieces, leaving an actual open aperture.
box("Counter_Left", (-0.88, 0, 0.88), (0.84, 0.80, 0.04), structure, counter_mat)
box("Counter_Right", (0.88, 0, 0.88), (0.84, 0.80, 0.04), structure, counter_mat)
box("Counter_Front", (0, -0.345, 0.88), (0.92, 0.11, 0.04), structure, counter_mat)
box("Counter_Back", (0, 0.325, 0.88), (0.92, 0.15, 0.04), structure, counter_mat)

# Cabinet clearance below the basin is maintained with separate walls and doors.
box("Cabinet_Back", (0, 0.35, 0.47), (2.52, 0.04, 0.78), structure, chalk)
box("Cabinet_Base", (0, 0.0, 0.13), (2.52, 0.70, 0.08), structure, chalk)
box("Toe_Recess", (0, 0.01, 0.055), (2.36, 0.56, 0.11), structure, recess_mat)
for index, x in enumerate((-1.26, -0.48, 0.48, 1.26)):
    box(f"Cabinet_Side_{index}", (x, 0, 0.49), (0.035, 0.70, 0.74), structure, chalk)
for index, (x, width) in enumerate(((-0.87, 0.73), (-0.24, 0.45), (0.24, 0.45), (0.87, 0.73))):
    box(f"Cabinet_Front_{index}", (x, -0.355, 0.49), (width, 0.025, 0.70), structure, chalk)


def rounded_loop(half_x, half_y, radius, z):
    points = []
    for cx, cy, start in ((half_x-radius, half_y-radius, 0),
                          (-half_x+radius, half_y-radius, 90),
                          (-half_x+radius, -half_y+radius, 180),
                          (half_x-radius, -half_y+radius, 270)):
        for step in range(9):
            angle = math.radians(start + step * 90 / 8)
            points.append((cx + radius*math.cos(angle), cy + radius*math.sin(angle)-0.02, z))
    return points


# A continuous shell with an open mouth, sloped inner walls, and a solid floor.
loops = [rounded_loop(0.48, 0.29, 0.07, 0.908),
         rounded_loop(0.43, 0.25, 0.065, 0.908),
         rounded_loop(0.415, 0.235, 0.065, 0.865),
         rounded_loop(0.37, 0.195, 0.065, 0.655),
         rounded_loop(0.385, 0.21, 0.065, 0.64),
         rounded_loop(0.445, 0.265, 0.07, 0.88)]
count = len(loops[0])
vertices = [point for loop in loops for point in loop]
faces = []
for first, second in ((0, 1), (1, 2), (2, 3), (4, 5), (5, 0)):
    for index in range(count):
        next_index = (index + 1) % count
        faces.append((first*count+index, first*count+next_index,
                      second*count+next_index, second*count+index))
faces.append(tuple(range(3*count, 4*count)))
faces.append(tuple(reversed(range(4*count, 5*count))))
mesh = bpy.data.meshes.new("Sink_Open_Shell_Mesh")
mesh.from_pydata(vertices, [], faces)
mesh.update()
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh)
bm.free()
basin = bpy.data.objects.new("Sink_Open_Shell", mesh)
sink.objects.link(basin)
basin.data.materials.append(sink_mat)
bevel(basin, 0.003)
cylinder("Drain_Placeholder", (0, -0.02, 0.658), 0.045, 0.004, sink, recess_mat)

# Left tray and right rack preserve the reference's left-to-right workflow.
box("Dirty_Tray_Base", (-0.89, -0.025, 0.917), (0.61, 0.49, 0.025), dirty, dirty_mat)
for side in (-1, 1):
    box(f"Dirty_Tray_Side_{side}", (-0.89+side*0.295, -0.025, 0.943),
        (0.02, 0.49, 0.045), dirty, dirty_mat)
    box(f"Dirty_Tray_Edge_{side}", (-0.89, -0.025+side*0.235, 0.943),
        (0.57, 0.02, 0.045), dirty, dirty_mat)
cylinder("Proxy_Dirty_Plate_250mm", (-0.99, -0.075, 0.938), 0.125, 0.014, dirty, dish_mat)
cylinder("Proxy_Dirty_Cup_90mm", (-0.72, 0.065, 0.983), 0.045, 0.105, dirty, dish_mat)
box("Clean_Rack_Base", (0.88, 0.035, 0.917), (0.54, 0.43, 0.025), clean, clean_mat)
for index in range(7):
    for side in (-1, 1):
        box(f"Rack_Peg_{index}_{side}", (0.65+index*0.073, 0.035+side*0.13, 1.005),
            (0.018, 0.025, 0.15), clean, clean_mat)
for index in range(6):
    marker(f"Rack_Slot_{index+1:02d}", (0.6865+index*0.073, 0.035, 1.055))
cylinder("Proxy_Clean_Plate_250mm", (0.7595, 0.035, 1.055), 0.125, 0.014,
         clean, dish_mat, (0, math.pi/2, 0))
box("Cup_Return_Pad", (0.94, -0.295, 0.907), (0.26, 0.15, 0.012), clean, clean_mat, 0.003)

# Tool silhouettes remain deliberately simple for this blockout.
curve = bpy.data.curves.new("Faucet_Path", "CURVE")
curve.dimensions = "3D"
curve.bevel_depth = 0.018
curve.bevel_resolution = 2
path = [(0.16, 0.305, 0.91), (0.16, 0.305, 1.23)]
for step in range(17):
    angle = math.pi * step / 16
    path.append((0.02+0.14*math.cos(angle), 0.305-0.27*step/16,
                 1.23+0.15*math.sin(angle)))
path.append((-0.12, 0.035, 1.17))
spline = curve.splines.new("POLY")
spline.points.add(len(path)-1)
for point, coordinate in zip(spline.points, path):
    point.co = (*coordinate, 1)
obj = bpy.data.objects.new("Faucet_Proxy", curve)
tools.objects.link(obj)
obj.data.materials.append(sink_mat)
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
for other in bpy.context.selected_objects:
    if other != obj:
        other.select_set(False)
bpy.ops.object.convert(target="MESH")
cylinder("Spray_Head_Proxy", (-0.12, 0.035, 1.175), 0.028, 0.075, tools, sink_mat)
cylinder("Faucet_Base", (0.16, 0.305, 0.922), 0.043, 0.025, tools, sink_mat)

# Separate deck-mounted lever, matching the switch beside the reference faucet.
cylinder("Faucet_Switch_Base", (0.305, 0.29, 0.915), 0.035, 0.028, tools, sink_mat)
cylinder("Faucet_Switch_Body", (0.305, 0.29, 0.949), 0.023, 0.04, tools, sink_mat)
cylinder("Faucet_Switch_Hinge", (0.305, 0.29, 0.978), 0.023, 0.052,
         tools, sink_mat, (0, math.pi/2, 0))
switch_pivot = marker("Faucet_Switch_Pivot", (0.305, 0.29, 0.978))
switch_pivot.rotation_euler.x = math.radians(10)
switch_pivot["rotation_axis"] = "local X"
switch_pivot["closed_angle_degrees"] = 10.0
switch_pivot["open_angle_degrees"] = 45.0
lever = cylinder("Faucet_Switch_Lever", (0, 0, 0), 0.009, 0.124, tools, sink_mat)
lever.parent = switch_pivot
lever.location = (0, 0, 0.062)
grip = cylinder("Faucet_Switch_Grip", (0, 0, 0), 0.012, 0.032, tools, recess_mat)
grip.parent = switch_pivot
grip.location = (0, 0, 0.124)
switch_target = marker("Faucet_Switch_Interaction", (0, 0, 0.11), switch_pivot)
switch_target["purpose"] = "Target for faucet on/off interaction"

box("Sponge_Rest", (-0.30, 0.17, 0.916), (0.15, 0.10, 0.025), tools, recess_mat)
for x in (-0.35, -0.25):
    box(f"Sponge_Bracket_{x}", (x, 0.235, 0.916), (0.018, 0.16, 0.018), tools, recess_mat, 0.003)
box("Sponge_Proxy", (-0.30, 0.17, 0.946), (0.115, 0.075, 0.035), tools, tool_mat)
box("Soap_Bottle_Proxy", (0.52, 0.26, 1.003), (0.075, 0.075, 0.20), tools, tool_mat, 0.015)
cylinder("Soap_Pump_Proxy", (0.52, 0.26, 1.128), 0.014, 0.05, tools, chalk)
box("Soap_Nozzle_Proxy", (0.50, 0.26, 1.154), (0.065, 0.018, 0.014), tools, chalk, 0.003)
box("Order_Board_Proxy", (1.23, 0.375, 1.43), (0.25, 0.025, 0.36), tools, dirty_mat)
box("Order_Paper_Proxy", (1.23, 0.359, 1.43), (0.21, 0.005, 0.31), tools, dish_mat, 0.002)

# Large architectural planes frame the station without decorative assets.
box("Floor", (0, -0.55, -0.035), (3.1, 2.5, 0.07), backdrop, floor_mat)
box("Backsplash", (0, 0.435, 0.59), (2.8, 0.07, 1.18), backdrop, wall_mat)
box("Wall_Left", (-1.22, 0.435, 1.64), (0.36, 0.07, 0.92), backdrop, wall_mat)
box("Wall_Right", (1.22, 0.435, 1.64), (0.36, 0.07, 0.92), backdrop, wall_mat)
box("Wall_Above_Window", (0, 0.435, 2.07), (2.12, 0.07, 0.10), backdrop, wall_mat)
box("Window_Background", (0, 0.475, 1.59), (2.08, 0.015, 0.88), backdrop, window_mat)
box("Window_Sill", (0, 0.435, 1.18), (2.17, 0.18, 0.045), backdrop, counter_mat)
for x in (-1.06, 0, 1.06):
    box(f"Window_Vertical_{x}", (x, 0.41, 1.61), (0.045, 0.08, 0.87), backdrop, chalk)
for z in (1.19, 1.61, 2.03):
    box(f"Window_Horizontal_{z}", (0, 0.41, z), (2.14, 0.08, 0.045), backdrop, chalk)

player = marker("Player_Origin", (0, -1.18, 0))
player_camera = camera("Player_Camera", (0, -1.18, 1.62), (0, 0.03, 1.02), 20, markers)
player_camera.parent = player
player_camera.location = (0, 0, 1.62)
carry = marker("Carry_Anchor", (0, -0.22, -0.78), player_camera)
close = marker("Clean_Anchor", (0, -0.015, -0.45), player_camera)
carry["purpose"] = "Normal carry: placement and free look"
close["purpose"] = "Close cleaning: lock camera, move tool cursor"
marker("Dirty_Pickup", (-0.99, -0.075, 0.947))
marker("Sink_Return", (0, -0.02, 0.67))
marker("Cup_Return", (0.94, -0.295, 0.967))
marker("Sponge_Rest_Point", (-0.30, 0.17, 0.946))
marker("Spray_Nozzle_Point", (-0.12, 0.035, 1.1375))
marker("Soap_Interaction", (0.52, 0.26, 1.10))
marker("Order_Interaction", (1.23, 0.35, 1.43))

overview = camera("Preview_Overview", (0.20, -4.8, 2.65), (0, 0, 1.05), 42, preview)


def area_light(name, location, target, energy, size, color):
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    preview.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()


area_light("Key_Softbox", (-2.3, -1.0, 4.2), (0, 0, 0.8), 450, 3.0, (1.0, 0.92, 0.82))
area_light("Fill_Softbox", (2.5, -2.0, 2.8), (0, 0, 1.0), 180, 2.5, (0.83, 0.91, 1.0))

# One disk is a scale witness for both holding states, excluded from GLB export.
hold_proxy = cylinder("QA_Held_Plate_250mm", (0, 0, 0), 0.125, 0.014, proxies, dish_mat)
hold_proxy.parent = carry
hold_proxy.location = (0, 0, 0)
hold_proxy.hide_render = True
hold_proxy.hide_set(True)

scene.camera = overview
scene["reference"] = "Docs/kitchen-scene-reference.png"
scene["graybox_dimensions_m"] = "counter 2.60 x 0.80; surface z=0.90; eye z=1.62"
scene["scope"] = "Blockout geometry, markers and camera; gameplay and collision setup belong in Godot"
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_perspective = "CAMERA"

# Export only game geometry, the proposed player camera, and named markers.
scene.render.resolution_y = 900
bpy.ops.object.select_all(action="DESELECT")
for group in (structure, sink, dirty, clean, tools, backdrop, markers):
    for obj in group.objects:
        obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "kitchen-workstation.glb"),
                          export_format="GLB", use_selection=True,
                          export_apply=True, export_cameras=True, export_extras=True)
bpy.ops.object.select_all(action="DESELECT")
scene.render.resolution_y = 1000
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "kitchen-workstation.blend"))


def render(camera_obj, filename):
    scene.camera = camera_obj
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


render(overview, "kitchen-graybox-overview.png")
scene.render.resolution_y = 900
hold_proxy.hide_render = False
render(player_camera, "kitchen-graybox-carry.png")
hold_proxy.parent = close
hold_proxy.location = (0, 0, 0)
render(player_camera, "kitchen-graybox-clean.png")
hold_proxy.hide_render = True
hold_proxy.parent = carry
hold_proxy.location = (0, 0, 0)
scene.camera = overview
scene.render.resolution_y = 1000
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "kitchen-workstation.blend"))
print("GRAYBOX_COMPLETE", ASSETS)

"""Assemble existing assets into an editable kitchen and export the room shell.

Run with Blender background CLI. Existing source assets are read-only inputs.
Godot uses the exported room plus separate original GLBs in kitchen-demo.tscn.
"""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Assets" / "Scenes"
DOCS = ROOT / "Docs" / "scenes" / "kitchen-demo"
OUT.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"

# Keep only architectural meshes and the temporary sponge support from the blockout.
room_names = {obj.name for obj in bpy.data.collections["06_Backdrop"].objects}
room_names.update(obj.name for obj in bpy.data.collections["01_Structure"].objects if not obj.name.startswith("Counter_"))
room_names.update(obj.name for obj in bpy.data.collections["05_Tool_Placeholders"].objects if obj.name.startswith(("Sponge_Rest", "Sponge_Bracket_")))
keep = room_names | {"Player_Origin", "Player_Camera", "Carry_Anchor", "Clean_Anchor"}
for obj in list(scene.objects):
    if obj.name not in keep:
        bpy.data.objects.remove(obj, do_unlink=True)
room = bpy.data.collections.new("00_Room_Blockout")
scene.collection.children.link(room)
for name in room_names:
    obj = bpy.data.objects[name]
    for group in list(obj.users_collection):
        group.objects.unlink(obj)
    room.objects.link(obj)
for group in list(bpy.data.collections):
    if not group.objects and not group.children and group != room:
        bpy.data.collections.remove(group)


def material(name, color, roughness=.65):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    node = mat.node_tree.nodes["Principled BSDF"]
    node.inputs["Base Color"].default_value = (*color, 1)
    node.inputs["Roughness"].default_value = roughness
    return mat


cabinet = material("Scene_Cabinet_Cream", (.65, .62, .52))
wall = material("Scene_Wall_Sage", (.24, .36, .30))
wood = material("Scene_Window_Wood", (.31, .15, .065), .45)
floor = material("Scene_Floor_Stone", (.30, .33, .30), .85)
sky = material("Scene_Window_Blue", (.46, .67, .75), .95)
sky.node_tree.nodes["Principled BSDF"].inputs["Emission Color"].default_value = (.33, .52, .65, 1)
sky.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = .25
for obj in room.objects:
    mat = (cabinet if obj.name.startswith("Cabinet_") else
           wood if obj.name.startswith("Window_") and obj.name != "Window_Background" else
           sky if obj.name == "Window_Background" else
           floor if obj.name == "Floor" else
           wall if obj.name.startswith("Wall_") or obj.name == "Backsplash" else None)
    if mat:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
# Extend existing large planes so the side views have a continuous background.
bpy.data.objects["Floor"].dimensions = (5, 5, .07)
bpy.data.objects["Backsplash"].dimensions.x = 4.8
for name, x in (("Wall_Left", -1.72), ("Wall_Right", 1.72)):
    obj = bpy.data.objects[name]
    obj.location = (x, .435, 1.99)
    obj.dimensions = (1.36, .07, 1.62)
obj = bpy.data.objects["Wall_Above_Window"]
obj.location.z = 2.41
obj.dimensions = (2.12, .07, .78)
for obj in room.objects:
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in room.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT / "kitchen-room-shell.glb"), export_format="GLB",
                          use_selection=True, export_apply=True, export_extras=True)
print("KITCHEN_ROOM_READY", len(room.objects), flush=True)


def append_collection(path, name):
    with bpy.data.libraries.load(str(ROOT / path), link=False) as (source, target):
        target.collections = [name]
    group = target.collections[0]
    scene.collection.children.link(group)
    return group


assets = [
    ("Assets/Kitchen/sink-countertop.blend", "01_Sink_Countertop_Asset", "Sink_Countertop", (0, 0, .90)),
    ("Assets/Kitchen/faucet-pullout.blend", "01_Faucet_Asset", "Faucet_Assembly", (.16, .32, .90)),
    ("Assets/Tools/soap-dispenser.blend", "01_Soap_Dispenser_Asset", "Soap_Dispenser", (.535, .26, .90)),
    ("Assets/Tools/sponge-standard.blend", "01_Sponge_Asset", "Sponge_Standard", (-.30, .17, .9285)),
    ("Assets/Kitchen/dish-rack-and-tray.blend", "01_Dish_Rack_Asset", "Dish_Rack", (.88, .035, .90)),
    ("Assets/Kitchen/dish-rack-and-tray.blend", "02_Dirty_Tray_Asset", "Dirty_Tray", (-.89, -.025, .90)),
    ("Assets/Kitchen/order-clipboard.blend", "01_Order_Clipboard_Asset", "Order_Clipboard", (1.2205, .398, 1.24)),
]
for path, group_name, root_name, position in assets:
    append_collection(path, group_name)
    bpy.data.objects[root_name].location = position
scene.frame_set(1)
bpy.context.view_layer.update()

# Use complete original hierarchies for every dish; copies share mesh and material data.
plate_group = append_collection("Assets/Dishes/plate-standard.blend", "01_Plate_Asset")
mug_group = append_collection("Assets/Dishes/mug-standard.blend", "01_Mug_Asset")
dishes = bpy.data.collections.new("20_Placed_Dishes")
scene.collection.children.link(dishes)


def place(group, source_root_name, slot, name):
    originals = list(group.objects)
    copies = {}
    for original in originals:
        obj = original.copy()
        obj.name = name if original.name == source_root_name else name + "_" + original.name
        dishes.objects.link(obj)
        obj.hide_render = False
        obj.hide_set(False)
        copies[original] = obj
    for original, obj in copies.items():
        obj.parent = copies.get(original.parent)
    root = copies[bpy.data.objects[source_root_name]]
    root.matrix_world = slot.matrix_world.copy()
    root["placement_slot"] = slot.name
    return root


placements = []
for slot, name in (("Dirty_Plate_01", "Tray_Plate_A"), ("Dirty_Plate_02", "Tray_Plate_B"),
                   ("Rack_Slot_01", "Rack_Plate_A"), ("Rack_Slot_03", "Rack_Plate_B"), ("Rack_Slot_05", "Rack_Plate_C")):
    placements.append(place(plate_group, "Plate_Standard", bpy.data.objects[slot], name))
for slot, name in (("Dirty_Mug_01", "Tray_Mug"), ("Rack_Cup_Slot_01", "Rack_Mug")):
    placements.append(place(mug_group, "Mug_Standard", bpy.data.objects[slot], name))
for group in (plate_group, mug_group):
    for obj in list(group.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(group)
bpy.context.view_layer.update()
assert len(placements) == 7
assert not any("Proxy" in obj.name or obj.name.startswith("Preview_Rack_") for obj in scene.objects)
for root in placements:
    expected = bpy.data.objects[root["placement_slot"]].matrix_world
    assert max(abs(root.matrix_world[i][j]-expected[i][j]) for i in range(4) for j in range(4)) < 1e-6, root.name

lighting = bpy.data.collections.new("90_Scene_Lighting")
scene.collection.children.link(lighting)


def camera(name, location, target, lens):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    lighting.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.lens, data.clip_start = lens, .05
    return obj


for name, loc, target, power, size, color in (
    ("Scene_Key", (-2, -1.4, 3.4), (0, 0, .9), 290, 2.6, (1, .91, .78)),
    ("Scene_Fill", (2, -1.5, 2.5), (0, 0, 1), 140, 2.5, (.82, .91, 1)),
    ("Scene_Window_Light", (0, .34, 1.86), (0, -.4, .8), 65, 1.5, (.86, .94, 1))):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size, data.color = power, size, color
    obj = bpy.data.objects.new(name, data)
    lighting.objects.link(obj)
    obj.location = loc
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
player = bpy.data.objects["Player_Camera"]
overview = camera("Scene_Overview", (.22, -3.5, 2.35), (0, 0, 1.05), 36)
left = camera("Scene_Look_Left", (0, -1.18, 1.62), (-.89, -.025, .94), 20)
right = camera("Scene_Look_Right", (0, -1.18, 1.62), (.88, -.025, 1.03), 20)
scene.camera = player
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 48
scene.cycles.transparent_max_bounces = 12
scene.world.node_tree.nodes["Background"].inputs["Strength"].default_value = .25
scene["scope"] = "Assembled existing assets and recolored architectural blockout; no washing gameplay"
scene["godot_scene"] = "Scenes/kitchen-demo.tscn"
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_perspective = "CAMERA"
bpy.ops.object.select_all(action="DESELECT")
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT / "kitchen-demo.blend"))
print("KITCHEN_ASSEMBLY_OK", json.dumps({"installed_assets": len(assets), "placed_dishes": len(placements), "room_meshes": len(room.objects)}), flush=True)
for cam, filename in ((player, "kitchen-demo-player.png"), (overview, "kitchen-demo-overview.png"),
                      (left, "kitchen-demo-left.png"), (right, "kitchen-demo-right.png")):
    scene.camera = cam
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)
print("KITCHEN_SCENE_COMPLETE", flush=True)

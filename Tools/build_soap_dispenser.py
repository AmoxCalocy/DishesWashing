"""Build the soap dispenser, pump press animation, and workstation previews.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_soap_dispenser.py
The liquid is a fixed mesh; dispensing and input belong in Godot.
"""
import json
import math
from pathlib import Path

import bmesh
import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Tools"
DOCS = ROOT / "Docs" / "assets" / "soap-dispenser"
ASSETS.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)
MOUNT = Vector((.535, .26, .90))
REST_Z, STROKE = .212, .012
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for group in list(bpy.data.collections):
    bpy.data.collections.remove(group)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1
scene.render.fps = 30
scene.frame_start, scene.frame_end = 1, 21
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def collection(name):
    group = bpy.data.collections.new(name)
    scene.collection.children.link(group)
    return group


asset = collection("01_Soap_Dispenser_Asset")
studio = collection("90_Preview_Studio")


def material(name, color, roughness, alpha=1):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, alpha)
    mat.use_backface_culling = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Alpha"].default_value = alpha
    shader.inputs["IOR"].default_value = 1.46
    if alpha < 1:
        mat.surface_render_method = "DITHERED"
    return mat


shell_mat = material("Soap_Clear_PET", (.78, .90, .82), .16, .10)
liquid_mat = material("Soap_Green_Liquid", (.12, .40, .035), .24)
ivory = material("Soap_Ivory_Pump", (.82, .80, .73), .28)
tube_mat = material("Soap_Dip_Tube", (.60, .72, .58), .32)
gasket_mat = material("Soap_Seal", (.11, .19, .13), .65)


def marker(name, position, parent=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = position
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .014
    return obj


root = marker("Soap_Dispenser", (0, 0, 0))
root["mount_blender_world"] = list(MOUNT)
root["scope"] = "Separated bottle, fixed liquid and animated pump; no dispensing or collision logic"
root["shell_material"] = "Alpha-blended PET approximation; no refraction dependency"
marker("Bottle_Base_Contact", (0, 0, 0), root)
marker("Soap_Interaction", (0, -.034, .12), root)
marker("Liquid_Surface", (0, 0, .143), root)
marker("Pump_Rest", (0, 0, REST_Z), root)
marker("Pump_Pressed", (0, 0, REST_Z-STROKE), root)
dose_pose = marker("Sponge_Dose_Pose", (0, -.09, .163), root)
dose_pose["purpose"] = "Root pose for the standard 110x70x32 mm sponge; yellow foam faces up"
pump = marker("Pump_Actuator", (0, 0, REST_Z), root)
pump["press_axis"] = "Blender local -Z / Godot local -Y"
pump["stroke_m"] = STROKE
marker("Pump_Interaction", (0, -.002, .034), pump)
nozzle = marker("Soap_Nozzle_Point", (0, -.064, .012), pump)
nozzle.rotation_euler.x = math.pi
nozzle["emission_axis"] = "Marker local +Z in Blender / +Y in Godot"


def mesh_object(name, vertices, faces, mat, parent):
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
    for face in mesh.polygons:
        face.use_smooth = True
    return obj


def lathe(name, profile, mat, parent, segments=64, ribs=False):
    vertices, rings, faces = [], [], []
    for point in profile:
        radius, z = point[:2]
        yscale = point[2] if len(point) > 2 else 1
        ring = []
        for i in range(1 if radius == 0 else segments):
            angle = math.tau*i/segments
            r = radius
            if ribs and radius >= .018:
                r += .00035*(1-math.cos(24*angle))/2
            ring.append(len(vertices))
            vertices.append((r*math.cos(angle), r*math.sin(angle)*yscale, z))
        rings.append(ring)
    for j, a in enumerate(rings):
        b = rings[(j+1) % len(rings)]
        if len(a) == len(b) == 1:
            continue
        for i in range(segments):
            nxt = (i+1) % segments
            faces.append((a[0], b[i], b[nxt]) if len(a) == 1 else
                         (a[i], b[0], a[nxt]) if len(b) == 1 else
                         (a[i], a[nxt], b[nxt], b[i]))
    return mesh_object(name, vertices, faces, mat, parent)


# One continuous material boundary: exterior, open neck, interior, thick base.
body = lathe("Bottle_Shell", [
    (0, 0), (.030, 0, .86), (.035, .001, .86), (.038, .004, .86),
    (.039, .009, .86), (.039, .137, .86), (.0385, .149, .86),
    (.0365, .158, .88), (.032, .166, .91), (.024, .174, .96),
    (.017, .181, 1), (.014, .185, 1), (.014, .191, 1),
    (.0125, .191, 1), (.0125, .185, 1), (.0155, .180, 1),
    (.0225, .173, .96), (.0305, .165, .91), (.035, .157, .88),
    (.037, .148, .86), (.0375, .137, .86), (.0375, .010, .86),
    (.036, .006, .86), (.032, .004, .86), (0, .004)], shell_mat, root)
liquid = lathe("Soap_Liquid", [
    (0, .006), (.030, .006, .86), (.0345, .008, .86),
    (.036, .012, .86), (.036, .1425, .86), (.0358, .1445, .86),
    (.035, .145, .86), (.0335, .143, .86), (0, .143)], liquid_mat, root)
liquid["surface_mode"] = "Fixed green volume with shallow meniscus; no fluid or depletion simulation"
lathe("Dip_Tube", [(.0022, .009), (.0033, .009), (.0033, .197), (.0022, .197)], tube_mat, root, 32)
lathe("Closure_Gasket", [(.014, .1865), (.0168, .1865), (.0172, .188),
                          (.0172, .190), (.014, .190)], gasket_mat, root)
lathe("Closure_Cap", [(.0142, .1885), (.018, .1885), (.019, .191),
                       (.019, .206), (.018, .209), (.008, .211),
                       (.0062, .211), (.0062, .201), (.0142, .201)], ivory, root, 96, ribs=True)
lathe("Pump_Stem", [(.0024, -.035), (.0055, -.035), (.0055, .022), (.0024, .022)], ivory, pump, 32)


def box(name, location, size, radius, mat, parent):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for group in list(obj.users_collection):
        group.objects.unlink(obj)
    asset.objects.link(obj)
    obj.parent = parent
    obj.data.materials.append(mat)
    bevel = obj.modifiers.new("Soft_Edges", "BEVEL")
    bevel.width, bevel.segments = radius, 4
    bpy.ops.object.modifier_apply(modifier=bevel.name)
    for face in obj.data.polygons:
        face.use_smooth = True
    normal = obj.modifiers.new("Weighted_Normals", "WEIGHTED_NORMAL")
    bpy.ops.object.modifier_apply(modifier=normal.name)
    return obj


box("Pump_Head", (0, -.002, .026), (.030, .033, .014), .004, ivory, pump)
# Offset the underside slightly so the two molded parts have no coplanar overlap.
box("Pump_Nozzle_Arm", (0, -.035, .0246), (.016, .063, .010), .003, ivory, pump)
outlet = lathe("Pump_Outlet", [(.0022, .013), (.0038, .013), (.0048, .015),
                               (.0048, .024), (.0022, .024)], ivory, pump, 40)
outlet.location.y = -.064

# The stem and the outlet move with the head; cap, body and liquid stay fixed.
for frame, z in ((1, REST_Z), (7, REST_Z-STROKE), (13, REST_Z-STROKE), (21, REST_Z)):
    pump.location.z = z
    pump.keyframe_insert(data_path="location", frame=frame)
pump.animation_data.action.name = "Pump_Press"
scene.frame_set(1)
meshes = [obj for obj in asset.objects if obj.type == "MESH"]
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
    assert all(edge.is_manifold for edge in bm.edges), obj.name+" is not closed"
    assert all(face.calc_area() > 1e-13 for face in bm.faces), obj.name+" has degenerate faces"
    assert bm.calc_volume(signed=True) > 0, obj.name+" has inward normals"
    bm.free()
    obj.data.calc_loop_triangles()
bpy.context.view_layer.update()
assert not body.ray_cast(Vector((0, 0, .22)), Vector((0, 0, -1)), distance=.03)[0], "Bottle neck blocked"
assert not outlet.ray_cast(Vector((0, 0, .01)), Vector((0, 0, 1)))[0], "Pump outlet blocked"
assert MOUNT.x-.039 > .48 and MOUNT.x+.039 < .61, "Bottle overlaps sink or rack bounds"
before = nozzle.matrix_world.translation.copy()
fixed_body = body.matrix_world.copy()
scene.frame_set(7)
after = nozzle.matrix_world.translation.copy()
assert abs((before-after).z-STROKE) < 1e-6 and body.matrix_world == fixed_body
assert abs(pump.location.z+.019-.211-.008) < 1e-6, "Pressed head must clear the fixed cap by 8mm"
scene.frame_set(1)
counts = {"vertices": sum(len(o.data.vertices) for o in meshes),
          "triangles": sum(len(o.data.loop_triangles) for o in meshes),
          "meshes": len(meshes), "nodes": len(asset.objects)}
print("SOAP_GEOMETRY_OK", json.dumps(counts), flush=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "soap-dispenser.glb"), export_format="GLB",
                          use_selection=True, export_extras=True, export_animations=True)


def camera(name, location, target, size):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat("-Z", "Y").to_euler()
    data.type, data.ortho_scale, data.clip_start = "ORTHO", size, .001
    return obj


def render(cam, filename):
    scene.camera = cam
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


for name, location, energy, size in (("Preview_Key", (-.30, -.35, .45), 9, .25),
                                     ("Preview_Fill", (.40, -.15, .30), 5, .25),
                                     ("Preview_Rim", (.12, .35, .42), 10, .20)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, .12))-obj.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.0001))
floor = bpy.context.object
floor.name = "Preview_Ground"
for group in list(floor.users_collection):
    group.objects.unlink(floor)
studio.objects.link(floor)
floor.data.materials.append(material("Preview_Sage_Ground", (.16, .22, .215), .9))
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.cycles.transparent_max_bounces = 12
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.22, .22, .22)
scene.view_settings.view_transform = "AgX"
hero = camera("Preview_Soap_Overview", (.30, -.48, .29), (0, -.01, .12), .46)
render(hero, "soap-dispenser-overview.png")
scene.frame_set(7)
detail = camera("Preview_Pump_Pressed", (.12, -.19, .17), (0, -.025, .211), .14)
render(detail, "soap-dispenser-pump-detail.png")
scene.frame_set(1)
scene.camera = hero
studio.hide_viewport = True
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        region = area.spaces.active.region_3d
        region.view_distance = .45
        region.view_location = (0, 0, .12)
        region.view_rotation = hero.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "soap-dispenser.blend"))

# Integration previews only: existing sources are loaded but never saved over.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for path, name in ((ROOT / "Assets" / "Kitchen" / "sink-countertop.blend", "01_Sink_Countertop_Asset"),
                   (ROOT / "Assets" / "Kitchen" / "faucet-pullout.blend", "01_Faucet_Asset"),
                   (ROOT / "Assets" / "Dishes" / "plate-standard.blend", "01_Plate_Asset"),
                   (ASSETS / "sponge-standard.blend", "01_Sponge_Asset"),
                   (ASSETS / "soap-dispenser.blend", "01_Soap_Dispenser_Asset")):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [name]
    scene.collection.children.link(target.collections[0])
for name in ("Counter_Left", "Counter_Right", "Counter_Front", "Counter_Back", "Sink_Open_Shell",
             "Drain_Placeholder", "Faucet_Proxy", "Faucet_Base", "Spray_Head_Proxy",
             "Faucet_Switch_Base", "Faucet_Switch_Body", "Faucet_Switch_Hinge", "Faucet_Switch_Lever",
             "Faucet_Switch_Grip", "Soap_Bottle_Proxy", "Soap_Pump_Proxy", "Soap_Nozzle_Proxy",
             "Sponge_Proxy", "QA_Held_Plate_250mm"):
    bpy.data.objects[name].hide_render = True
    bpy.data.objects[name].hide_set(True)
bpy.data.objects["Sink_Countertop"].location.z = .90
bpy.data.objects["Faucet_Assembly"].location = (.16, .32, .90)
root = bpy.data.objects["Soap_Dispenser"]
root.location = MOUNT
pump = bpy.data.objects["Pump_Actuator"]
nozzle = bpy.data.objects["Soap_Nozzle_Point"]
plate = bpy.data.objects["Plate_Surface"]
plate.hide_render = True
plate.hide_set(True)
sponge_root = bpy.data.objects["Sponge_Standard"]
sponge_root.location = (-.30, .17, .9285)
scene.frame_set(1)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 40
scene.cycles.transparent_max_bounces = 12
player = bpy.data.objects["Player_Camera"]
render(player, "soap-dispenser-player.png")
plate.hide_render = False
plate.hide_set(False)
plate_root = bpy.data.objects["Plate_Standard"]
plate_root.parent = bpy.data.objects["Carry_Anchor"]
plate_root.location = (0, 0, 0)
bpy.context.view_layer.update()
target = next(child for child in root.children if child.name.startswith("Soap_Interaction"))
screen = world_to_camera_view(scene, player, target.matrix_world.translation)
assert .05 < screen.x < .95 and .05 < screen.y < .95 and screen.z > player.data.clip_start
origin = player.matrix_world.translation
delta = target.matrix_world.translation-origin
hit, pos, normal, face, hit_object, matrix = scene.ray_cast(bpy.context.evaluated_depsgraph_get(), origin, delta.normalized(), distance=delta.length+.02)
assert hit and hit_object.name in {obj.name for obj in bpy.data.collections["01_Soap_Dispenser_Asset"].objects}, "Bottle target occluded in carry view"
print("SOAP_CARRY_VISIBILITY_OK", tuple(screen), hit_object.name, flush=True)
render(player, "soap-dispenser-carry.png")
plate.hide_render = True
plate.hide_set(True)
dose_pose = bpy.data.objects["Sponge_Dose_Pose"]
sponge_root.matrix_world = dose_pose.matrix_world.copy()
scene.frame_set(7)
bpy.context.view_layer.update()
foam = bpy.data.objects["Sponge_Foam"]
inverse = foam.matrix_world.inverted()
origin = nozzle.matrix_world.translation
direction = nozzle.matrix_world.to_3x3() @ Vector((0, 0, 1))
hit, pos, normal, face = foam.ray_cast(inverse @ origin, inverse.to_3x3() @ direction)
assert hit and normal.z > .9, "Nozzle must hit the upper yellow foam"
gap = ((foam.matrix_world @ pos)-origin).length
assert .015 < gap < .02
assert sponge_root.location.y+.035 < MOUNT.y-.034, "Sponge intersects bottle body"
print("SOAP_DOSE_OK", "pressed_gap_m", gap, flush=True)
studio = scene.collection
dose_camera = camera("Preview_Sponge_Dose", MOUNT+Vector((.06, -.45, .30)), MOUNT+Vector((0, -.045, .14)), .37)
scene.render.resolution_y = 1000
render(dose_camera, "soap-dispenser-dose.png")
print("SOAP_COMPLETE", ASSETS, flush=True)

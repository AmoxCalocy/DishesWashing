"""Build a pull-out faucet, separate spray head and deck-mounted lever.

blender --background --factory-startup --python-exit-code 1 --python Tools/build_faucet.py
The hose morph is a fixed inspection pose, not a runtime hose simulation.
"""
import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Kitchen"
DOCS = ROOT / "Docs" / "assets" / "faucet-pullout"
ASSETS.mkdir(parents=True, exist_ok=True)
DOCS.mkdir(parents=True, exist_ok=True)
MOUNT = Vector((.16, .32, .90))
DOCK = Vector((-.28, -.27, .30))
HOSE_EXIT = Vector((-.28, -.27, .34))
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for collection in list(bpy.data.collections):
    bpy.data.collections.remove(collection)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def group(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


asset = group("01_Faucet_Asset")
studio = group("90_Preview_Studio")


def material(name, color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_backface_culling = True
    shader = mat.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Metallic"].default_value = metallic
    shader.inputs["Roughness"].default_value = roughness
    return mat


steel = material("Faucet_Satin_Steel", (.55, .59, .62), 1, .25)
trim = material("Faucet_Polished_Trim", (.64, .67, .69), 1, .18)
rubber = material("Faucet_Charcoal_Rubber", (.026, .032, .034), 0, .72)


def marker(name, location, parent=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = location
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .025
    return obj


root = marker("Faucet_Assembly", (0, 0, 0))
root["mount_blender_world"] = list(MOUNT)
root["scope"] = "Editable meshes, nozzle and dock markers, fixed hose inspection morph; no water or input logic"
marker("Faucet_Base_Contact", (0, 0, 0), root)
switch_root = marker("Handle_Assembly", (.145, 0, 0), root)
marker("Handle_Base_Contact", (0, 0, 0), switch_root)
dock = marker("Spray_Dock", DOCK, root)
exit_marker = marker("Hose_Exit", HOSE_EXIT, root)
head = marker("Spray_Head", DOCK, root)
head["axis"] = "Body axis +Z in Blender / +Y in Godot; nozzle emits in the opposite direction"
marker("Hose_Attach", (0, 0, .009), head)
nozzle = marker("Spray_Nozzle_Point", (0, 0, -.085), head)
nozzle.rotation_euler.x = math.pi
nozzle["emission_axis"] = "Marker local +Z in Blender / +Y in Godot"
marker("Spray_Interaction", (0, -.025, -.04), head)


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


def lathe(name, profile, mat, parent, segments=64):
    vertices, rings, faces = [], [], []
    for radius, z in profile:
        ring = []
        for i in range(1 if radius == 0 else segments):
            angle = math.tau*i/segments
            ring.append(len(vertices))
            vertices.append((radius*math.cos(angle), radius*math.sin(angle), z))
        rings.append(ring)
    for j, a in enumerate(rings):
        b = rings[(j+1) % len(rings)]
        if len(a) == len(b) == 1:
            continue
        for i in range(segments):
            n = (i+1) % segments
            faces.append((a[0], b[i], b[n]) if len(a) == 1 else
                         (a[i], b[0], a[n]) if len(b) == 1 else (a[i], a[n], b[n], b[i]))
    return mesh_object(name, vertices, faces, mat, parent)


def tube_data(points, radius, sides=24, inner=None):
    vertices, frames = [], []
    previous_tangent, u = None, None
    for i, p in enumerate(points):
        tangent = (points[min(i+1, len(points)-1)]-points[max(0, i-1)]).normalized()
        if u is None:
            reference = Vector((1, 0, 0)) if abs(tangent.x) < .9 else Vector((0, 1, 0))
            u = (reference-tangent*tangent.dot(reference)).normalized()
        else:
            u = previous_tangent.rotation_difference(tangent) @ u
        v = tangent.cross(u).normalized()
        frames.append((u.copy(), v))
        previous_tangent = tangent
    for r in ([radius, inner] if inner else [radius]):
        for p, (u, v) in zip(points, frames):
            for i in range(sides):
                angle = math.tau*i/sides
                vertices.append(tuple(p+r*(u*math.cos(angle)+v*math.sin(angle))))
    faces = []
    count = len(points)*sides
    for offset in ([0, count] if inner else [0]):
        for j in range(len(points)-1):
            for i in range(sides):
                n = (i+1) % sides
                faces.append((offset+j*sides+i, offset+j*sides+n, offset+(j+1)*sides+n, offset+(j+1)*sides+i))
    if inner:
        for j in (0, len(points)-1):
            for i in range(sides):
                n = (i+1) % sides
                faces.append((j*sides+i, j*sides+n, count+j*sides+n, count+j*sides+i))
    else:
        faces += [tuple(reversed(range(sides))), tuple(range(count-sides, count))]
    return vertices, faces


lathe("Faucet_Base_Gasket", [(0, 0), (.039, 0), (.041, .001), (.041, .002), (0, .002)], rubber, root)
lathe("Faucet_Base", [(0, .002), (.039, .002), (.041, .004), (.041, .013),
                     (.039, .017), (.024, .021), (.018, .021), (0, .021)], steel, root)
lathe("Stem_Collar", [(.0178, .018), (.023, .018), (.024, .021), (.024, .049),
                     (.0225, .053), (.0178, .053)], trim, root)
points = [Vector((0, 0, z)) for z in (.018, .06, .20, .33)]
for i in range(1, 65):
    a = math.pi*i/64
    points.append(Vector((-.14*(1-math.cos(a)), -.135*(1-math.cos(a)), .33+.14*math.sin(a))))
points.append(Vector((DOCK.x, DOCK.y, .308)))
neck = mesh_object("Faucet_Neck", *tube_data(points, .0175, 32, .0135), steel, root)
collar = lathe("Spray_Dock_Collar", [(.018, .013), (.0215, .013), (.0235, .009),
                                   (.0235, -.011), (.022, -.014), (.020, -.014),
                                   (.019, -.006), (.018, .004)], trim, root)
collar.location = (DOCK.x, DOCK.y, .308)

lathe("Spray_Shell", [(.017, .005), (.019, .001), (.019, -.005), (.022, -.018),
                      (.024, -.04), (.025, -.064), (.025, -.076), (.023, -.084),
                      (.0195, -.084), (.0195, -.079), (.021, -.072), (.020, -.041),
                      (.016, -.017), (.013, .005)], steel, head)
lathe("Spray_Hose_Coupling", [(.005, 0), (.009, 0), (.010, .003), (.010, .013),
                              (.008, .016), (.005, .016)], trim, head)
lathe("Spray_Outlet_Rim", [(.0195, -.084), (.023, -.084), (.0245, -.081),
                          (.0245, -.076), (.023, -.075), (.0215, -.080)], trim, head)


def box(name, location, size, radius, mat, parent):
    bpy.ops.mesh.primitive_cube_add(size=1, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for linked in list(obj.users_collection):
        linked.objects.unlink(obj)
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


button = box("Spray_Mode_Button", (0, -.023, -.037), (.014, .006, .032), .0025, rubber, head)
button["press_axis_blender"] = "+Y"
bpy.ops.mesh.primitive_cylinder_add(vertices=64, radius=.0195, depth=.002)
outlet = bpy.context.object
outlet.name = "Spray_Outlet_Plate"
for linked in list(outlet.users_collection):
    linked.objects.unlink(outlet)
asset.objects.link(outlet)
outlet.data.materials.append(rubber)
# Perforate before parenting so booleans operate in a simple local coordinate frame.
for i in range(19):
    angle = math.tau*i/18
    centre = (.0145*math.cos(angle), .0145*math.sin(angle), 0) if i < 18 else (0, 0, 0)
    bpy.ops.mesh.primitive_cylinder_add(vertices=12 if i < 18 else 48,
                                      radius=.00115 if i < 18 else .0065, depth=.01, location=centre)
    cutter = bpy.context.object
    modifier = outlet.modifiers.new("Nozzle_Hole", "BOOLEAN")
    modifier.operation, modifier.solver, modifier.object = "DIFFERENCE", "EXACT", cutter
    bpy.context.view_layer.objects.active = outlet
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    bpy.data.objects.remove(cutter, do_unlink=True)
outlet.parent = head
outlet.location = (0, 0, -.083)
# Seat the trim slightly proud of the outlet plate to avoid coplanar surfaces.
lathe("Spray_Aerator_Ring", [(.0063, -.0846), (.009, -.0846), (.009, -.0833), (.0063, -.0833)], trim, head)

# A separate deck-mounted handle. Only the lever assembly rotates.
lathe("Handle_Base_Gasket", [(0, 0), (.032, 0), (.034, .001), (.034, .002), (0, .002)], rubber, switch_root)
lathe("Handle_Base", [(0, .002), (.032, .002), (.034, .004), (.034, .012),
                     (.031, .016), (.022, .018), (0, .018)], steel, switch_root)
lathe("Handle_Valve_Body", [(0, .015), (.021, .015), (.023, .020), (.023, .049),
                           (.021, .060), (.015, .065), (0, .065)], steel, switch_root)
hinge = lathe("Handle_Hinge", [(0, -.024), (.015, -.024), (.018, -.021), (.018, .021),
                              (.015, .024), (0, .024)], trim, switch_root)
hinge.location.z = .063
hinge.rotation_euler.y = math.pi/2
pivot = marker("Handle_Pivot", (0, 0, .063), switch_root)
pivot.rotation_euler.x = math.radians(10)
pivot["rotation_axis"] = "local X"
pivot["closed_angle_degrees"], pivot["open_angle_degrees"] = 10.0, 45.0
lathe("Handle_Lever", [(0, .003), (.008, .003), (.008, .015), (.0065, .024),
                      (.0065, .103), (.008, .108), (0, .108)], steel, pivot, 32)
lathe("Handle_Grip", [(0, .098), (.007, .098), (.009, .101), (.009, .118),
                     (.007, .122), (0, .122)], rubber, pivot, 32)
marker("Handle_Interaction", (0, 0, .110), pivot)

# Compute one reproducible pulled-out pose against the existing player camera.
eye = Vector((0, -1.18, 1.62))
camera_rotation = (Vector((0, .03, 1.02))-eye).to_track_quat("-Z", "Y")
demo_position = eye + camera_rotation @ Vector((.20, .045, -.34)) - MOUNT
demo_target = eye + camera_rotation @ Vector((.045, -.035, -.452)) - MOUNT
demo_rotation = (demo_target-demo_position).to_track_quat("-Z", "Y")
inspection_pose = marker("Spray_Inspection_Pose", demo_position, root)
inspection_pose.rotation_mode = "QUATERNION"
inspection_pose.rotation_quaternion = demo_rotation
inspection_pose["purpose"] = "Fixed pose paired with hose Pullout_Inspection=1; not a runtime movement target"
head["inspection_position_blender"] = list(demo_position)
head["inspection_quaternion_wxyz"] = list(demo_rotation)
head["inspection_note"] = "Move head to this fixed pose and set hose morph to 1; arbitrary targets require a dynamic hose"
end_rest = DOCK + Vector((0, 0, .009))
end_pulled = demo_position + demo_rotation @ Vector((0, 0, .009))
rest_path = [HOSE_EXIT.lerp(end_rest, i/64) for i in range(65)]
controls = [HOSE_EXIT, HOSE_EXIT + Vector((0, 0, -.23)),
            end_pulled + demo_rotation @ Vector((0, 0, .12)), end_pulled]
pulled_path = []
for i in range(65):
    t = i/64
    pulled_path.append((1-t)**3*controls[0]+3*(1-t)**2*t*controls[1]+3*(1-t)*t*t*controls[2]+t**3*controls[3])
hose = mesh_object("Pullout_Hose", *tube_data(rest_path, .0045, 16), rubber, root)
hose.shape_key_add(name="Basis")
shape = hose.shape_key_add(name="Pullout_Inspection")
pulled_vertices, _ = tube_data(pulled_path, .0045, 16)
for point, co in zip(shape.data, pulled_vertices):
    point.co = co
shape.value = 0
hose["purpose"] = "Fixed rest / inspection shape only; not an automatic following hose"
hose["inspection_path_length_m"] = sum((a-b).length for a, b in zip(pulled_path[:-1], pulled_path[1:]))

# UVs and geometry validation before exporting the default docked / closed state.
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
assert not outlet.ray_cast(Vector((0, 0, -.01)), Vector((0, 0, 1)))[0]
assert not outlet.ray_cast(Vector((.0145, 0, -.01)), Vector((0, 0, 1)))[0]
assert (head.location-dock.location).length < 1e-6
assert abs((MOUNT.y + .0175)-.3375) < 1e-6
print("FAUCET_GEOMETRY_OK", sum(len(o.data.vertices) for o in meshes), "vertices",
      sum(len(o.data.loop_triangles) for o in meshes), "triangles", len(meshes), "meshes", flush=True)
print("HOSE_INSPECTION_LENGTH_M", hose["inspection_path_length_m"], flush=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "faucet-pullout.glb"), export_format="GLB",
                          use_selection=True, export_extras=True, export_morph=True)


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


for name, location, energy, size in (("Preview_Key", (-.7, -.8, 1.0), 65, .6),
                                     ("Preview_Fill", (.7, .1, .8), 40, .5),
                                     ("Preview_Rim", (-.5, .4, .5), 30, .4)):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size = energy, size
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector((0, 0, .2))-obj.location).to_track_quat("-Z", "Y").to_euler()
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.0001))
floor = bpy.context.object
floor.name = "Preview_Ground"
for linked in list(floor.users_collection):
    linked.objects.unlink(floor)
studio.objects.link(floor)
floor.data.materials.append(material("Preview_Sage_Ground", (.16, .22, .215), 0, .9))
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.22, .22, .22)
scene.view_settings.view_transform = "AgX"
hero = camera("Preview_Faucet_Overview", (.65, -.95, .65), (-.07, -.10, .23), .95)
render(hero, "faucet-pullout-overview.png")
detail = camera("Preview_Nozzle", DOCK+Vector((.09, -.15, -.16)), DOCK+Vector((0, 0, -.045)), .145)
fill_data = bpy.data.lights.new("Preview_Nozzle_Fill", "AREA")
fill_data.energy, fill_data.size = 1.2, .08
nozzle_fill = bpy.data.objects.new("Preview_Nozzle_Fill", fill_data)
studio.objects.link(nozzle_fill)
nozzle_fill.location = DOCK + Vector((0, -.08, -.15))
nozzle_fill.rotation_euler = (DOCK+Vector((0, 0, -.08))-nozzle_fill.location).to_track_quat("-Z", "Y").to_euler()
floor.hide_render = True
render(detail, "faucet-nozzle-detail.png")
nozzle_fill.hide_render = True
floor.hide_render = False
pivot.rotation_euler.x = math.radians(45)
handle_camera = camera("Preview_Handle_Open", (.35, -.28, .22), (.145, -.035, .083), .25)
render(handle_camera, "faucet-handle-open.png")
pivot.rotation_euler.x = math.radians(10)
studio.hide_viewport = True
scene.camera = hero
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_distance = 1
        area.spaces.active.region_3d.view_location = (-.07, -.1, .23)
        area.spaces.active.region_3d.view_rotation = hero.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
neck.select_set(True)
bpy.context.view_layer.objects.active = neck
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "faucet-pullout.blend"))

# In-memory integration only; the greybox and previously delivered assets are untouched.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for path, name in ((ASSETS / "sink-countertop.blend", "01_Sink_Countertop_Asset"),
                   (ASSETS / "faucet-pullout.blend", "01_Faucet_Asset"),
                   (ROOT / "Assets" / "Dishes" / "plate-standard.blend", "01_Plate_Asset")):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [name]
    scene.collection.children.link(target.collections[0])
for name in ("Counter_Left", "Counter_Right", "Counter_Front", "Counter_Back", "Sink_Open_Shell",
             "Drain_Placeholder", "Faucet_Proxy", "Faucet_Base", "Spray_Head_Proxy",
             "Faucet_Switch_Base", "Faucet_Switch_Body", "Faucet_Switch_Hinge", "Faucet_Switch_Lever",
             "Faucet_Switch_Grip", "QA_Held_Plate_250mm"):
    bpy.data.objects[name].hide_render = True
bpy.data.objects["Sink_Countertop"].location.z = .90
root = bpy.data.objects["Faucet_Assembly"]
root.location = MOUNT
plate = bpy.data.objects["Plate_Surface"]
plate.hide_render = True
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 40
player_camera = bpy.data.objects["Player_Camera"]
render(player_camera, "faucet-docked-player.png")

plate.hide_render = False
plate_root = bpy.data.objects["Plate_Standard"]
plate_root.parent = bpy.data.objects["Clean_Anchor"]
plate_root.location = (0, 0, 0)
head = bpy.data.objects["Spray_Head"]
head.location = demo_position
head.rotation_mode = "QUATERNION"
head.rotation_quaternion = demo_rotation
bpy.data.objects["Pullout_Hose"].data.shape_keys.key_blocks["Pullout_Inspection"].value = 1
bpy.data.objects["Handle_Pivot"].rotation_euler.x = math.radians(45)
bpy.context.view_layer.update()
# The greybox already has a marker with this name; use the new head's child.
nozzle = next(child for child in head.children if child.name.startswith("Spray_Nozzle_Point"))
origin = nozzle.matrix_world.translation
direction = nozzle.matrix_world.to_3x3() @ Vector((0, 0, 1))
inverse = plate.matrix_world.inverted()
hit, position, normal, face = plate.ray_cast(inverse @ origin, inverse.to_3x3() @ direction)
assert hit and normal.z > .99, "Nozzle must aim at the visible plate surface"
for a, b in zip(pulled_path[:-1], pulled_path[1:]):
    start = inverse @ (a+MOUNT)
    end = inverse @ (b+MOUNT)
    delta = end-start
    assert not plate.ray_cast(start, delta.normalized(), distance=delta.length)[0], "Hose centreline crosses the plate"
print("SPRAY_AIM_OK", tuple(position), "distance_m", ((plate.matrix_world @ position)-origin).length, flush=True)
render(player_camera, "faucet-pullout-clean.png")
print("FAUCET_COMPLETE", ASSETS, flush=True)

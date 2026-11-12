"""Build a 250 mm dinner plate and render asset / workstation previews.

Run: blender --background --factory-startup --python-exit-code 1 --python Tools/build_standard_plate.py
The existing workstation .blend is read for previews, never overwritten.
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
SEGMENTS = 128
PIVOT_HEIGHT = 0.012
# Radius, height above the table. Runs from front centre around the rim,
# down the back and foot ring, and back to the underside centre.
PROFILE = [
    (0, .010), (.035, .010), (.065, .010), (.076, .010),
    (.080, .0102), (.083, .0109), (.086, .0126), (.089, .0153),
    (.092, .0186), (.0955, .0210), (.100, .0222), (.113, .0232),
    (.1235, .0240), (.1243, .0238), (.1248, .0233),
    (.125, .0225), (.125, .0215), (.1247, .0207),
    (.1241, .0201), (.1232, .0198), (.119, .0197),
    (.113, .0192), (.106, .0186), (.100, .0182), (.094, .0163),
    (.088, .0115), (.082, .0068), (.070, .0060), (.065, .0059),
    (.0625, .0053), (.0612, .0038), (.0608, .0015),
    (.0604, .0005), (.0596, .0000), (.0555, .0000),
    (.0545, .0005), (.0540, .0015), (.0536, .0035),
    (.0527, .0050), (.0510, .0058), (.048, .0060),
    (.035, .0060), (0, .0060),
]
UV_SPLIT = 15

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for group in list(bpy.data.collections):
    bpy.data.collections.remove(group)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1.0
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


asset = collection("01_Plate_Asset")
studio = collection("90_Preview_Studio")


def material(name, color, roughness):
    result = bpy.data.materials.new(name)
    result.diffuse_color = (*color, 1)
    shader = result.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1)
    shader.inputs["Roughness"].default_value = roughness
    return result


glaze = material("Plate_Warm_Ivory_Glaze", (.82, .785, .70), .23)
foot_mat = material("Plate_Unglazed_Foot", (.64, .58, .47), .72)


def empty(name, position, parent=None, normal=None):
    obj = bpy.data.objects.new(name, None)
    asset.objects.link(obj)
    obj.parent = parent
    obj.location = position
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .015
    if normal is not None:
        obj.rotation_euler = Vector(normal).to_track_quat("Z", "Y").to_euler()
    return obj


root = empty("Plate_Standard", (0, 0, 0))
root["diameter_m"] = .25
root["height_m"] = .024
root["pivot"] = "Bounding-box centre; Blender +Z / Godot +Y is the front"
root["scope"] = "Clean mesh and surface markers; no runtime cleaning or collision body"

vertices, rings, faces, face_bands = [], [], [], []
vertex_rings = []
for ring_index, (radius, height) in enumerate(PROFILE):
    ring = []
    for index in range(1 if radius == 0 else SEGMENTS):
        angle = math.tau * index / SEGMENTS
        ring.append(len(vertices))
        vertices.append((radius * math.cos(angle), radius * math.sin(angle), height - PIVOT_HEIGHT))
        vertex_rings.append(ring_index)
    rings.append(ring)
for band, (inner, outer) in enumerate(zip(rings[:-1], rings[1:])):
    for index in range(SEGMENTS):
        nxt = (index + 1) % SEGMENTS
        if len(inner) == 1:
            face = (inner[0], outer[index], outer[nxt])
        elif len(outer) == 1:
            face = (inner[index], outer[0], inner[nxt])
        else:
            face = (inner[index], outer[index], outer[nxt], inner[nxt])
        faces.append(face)
        face_bands.append(band)

mesh = bpy.data.meshes.new("Plate_Standard_Surface")
mesh.from_pydata(vertices, [], faces)
mesh.update()
plate = bpy.data.objects.new("Plate_Surface", mesh)
asset.objects.link(plate)
plate.parent = root
mesh.materials.append(glaze)
mesh.materials.append(foot_mat)
for poly, band in zip(mesh.polygons, face_bands):
    poly.use_smooth = True
    poly.material_index = 1 if 32 <= band <= 35 else 0

# Separate front/back UV disks. Arc-length radius makes the folded foot ring
# injective in UV space, unlike a planar projection of the underside.
arc = [0.0]
for a, b in zip(PROFILE[:-1], PROFILE[1:]):
    arc.append(arc[-1] + math.dist(a, b))
uv = mesh.uv_layers.new(name="UV_Cleaning")
for poly, band in zip(mesh.polygons, face_bands):
    is_front = band < UV_SPLIT
    center = (.295, .705) if is_front else (.705, .295)
    for loop_index in poly.loop_indices:
        vertex_index = mesh.loops[loop_index].vertex_index
        ring_index = vertex_rings[vertex_index]
        x, y, _ = vertices[vertex_index]
        angle = math.atan2(y, x)
        fraction = (arc[ring_index] / arc[UV_SPLIT] if is_front
                    else (arc[-1] - arc[ring_index]) / (arc[-1] - arc[UV_SPLIT]))
        uv.data[loop_index].uv = (center[0] + .28 * fraction * math.cos(angle),
                                  center[1] + .28 * fraction * math.sin(angle))
for name, predicate in (("Clean_Front", lambda i: i <= UV_SPLIT),
                         ("Clean_Back", lambda i: i >= UV_SPLIT)):
    group = plate.vertex_groups.new(name=name)
    group.add([i for i, ring in enumerate(vertex_rings) if predicate(ring)], 1, "REPLACE")

empty("Placement_Base", (0, 0, -.012), root)
for name, position, normal, radius in (
    ("Dirt_Front_Center", (.025, -.02, -.002), (0, 0, 1), .027),
    ("Dirt_Front_Rim", (.113, 0, .0112), (-.076, 0, .997), .008),
    ("Dirt_Back_Center", (-.022, .015, -.006), (0, 0, -1), .022),
    ("Dirt_Back_Foot", (-.0575, 0, -.012), (0, 0, -1), .002),
):
    point = empty(name, position, root, normal)
    point["test_radius_m"] = radius
    point["purpose"] = "Surface attachment only; visual dirt and cleaning are implemented in Godot"

# Fail the CLI build if the actual plate is broken or the UV disks overlap.
bm = bmesh.new()
bm.from_mesh(mesh)
assert all(edge.is_manifold for edge in bm.edges), "Open or non-manifold plate"
assert all(face.calc_area() > 1e-12 for face in bm.faces), "Degenerate face"
assert bm.calc_volume(signed=True) > 0, "Inverted normals"
bm.free()
assert math.dist((.295, .705), (.705, .295)) > .56
for item in uv.data:
    assert 0 <= item.uv.x <= 1 and 0 <= item.uv.y <= 1
bpy.context.view_layer.update()
assert all(abs(a - b) < 1e-6 for a, b in zip(plate.dimensions, (.25, .25, .024)))
for start, direction, expected_z, normal_z in (
    ((0, 0, .1), (0, 0, -1), -.002, 1),
    ((0, 0, -.1), (0, 0, 1), -.006, -1),
    ((.057, 0, -.1), (0, 0, 1), -.012, -1),
):
    hit, position, normal, _ = plate.ray_cast(Vector(start), Vector(direction))
    assert hit and abs(position.z - expected_z) < 1e-6 and normal.z * normal_z > .99
mesh.calc_loop_triangles()
print("PLATE_GEOMETRY_OK", len(mesh.vertices), "vertices", len(mesh.loop_triangles), "triangles")

bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = plate
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "plate-standard.glb"),
                          export_format="GLB", use_selection=True,
                          export_apply=True, export_extras=True)


def camera(name, location, target, ortho=None):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    data.clip_start = .005
    if ortho:
        data.type = "ORTHO"
        data.ortho_scale = ortho
    return obj


def light(name, location, energy, size, color):
    data = bpy.data.lights.new(name, "AREA")
    data.energy, data.size, data.color = energy, size, color
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (-obj.location).to_track_quat("-Z", "Y").to_euler()


def render(camera_obj, filename):
    scene.camera = camera_obj
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


# Keep the editable asset at the origin. Product views are linked mesh copies.
plate.hide_render = True
front = bpy.data.objects.new("Preview_Front", mesh)
studio.objects.link(front)
front.location = (-.145, 0, 0)
back = bpy.data.objects.new("Preview_Back", mesh)
studio.objects.link(back)
back.location = (.145, .015, 0)
back.rotation_euler.x = math.pi
bpy.ops.mesh.primitive_plane_add(size=200, location=(0, 0, -.0121))
floor = bpy.context.object
floor.name = "Preview_Ground"
for linked in list(floor.users_collection):
    linked.objects.unlink(floor)
studio.objects.link(floor)
floor.data.materials.append(material("Preview_Sage_Ground", (.16, .22, .215), .9))
light("Preview_Key", (-.40, -.15, .40), 12, .25, (1.0, .94, .85))
light("Preview_Fill", (.45, .15, .50), 4, .35, (.84, .92, 1.0))
hero = camera("Preview_Plate_Front_Back", (0, -.65, .70), (0, 0, 0), .66)
scene.render.engine = "CYCLES"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 1600
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.world.color = (.22, .22, .22)
scene.view_settings.view_transform = "AgX"
render(hero, "plate-standard-overview.png")

# Opening the source shows the single asset; the studio can be enabled manually.
plate.hide_render = False
front.hide_render = back.hide_render = True
studio.hide_viewport = True
scene.camera = camera("Preview_Single_Plate", (0, -.34, .32), (0, 0, 0), .34)
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        region = area.spaces.active.region_3d
        region.view_distance = .45
        region.view_location = (0, 0, 0)
        region.view_rotation = scene.camera.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
plate.select_set(True)
bpy.context.view_layer.objects.active = plate
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "plate-standard.blend"))

# Load the existing greybox only to render the actual in-game viewing distances.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
with bpy.data.libraries.load(str(ASSETS / "plate-standard.blend"), link=False) as (source, target):
    target.collections = ["01_Plate_Asset"]
scene.collection.children.link(target.collections[0])
root = bpy.data.objects["Plate_Standard"]
plate = bpy.data.objects["Plate_Surface"]
for name in ("Proxy_Dirty_Plate_250mm", "Proxy_Clean_Plate_250mm", "QA_Held_Plate_250mm"):
    bpy.data.objects[name].hide_render = True
for name, location, rotation in (
    ("Preview_Tray_Plate", (-.99, -.075, .9415), (0, 0, 0)),
    ("Preview_Rack_Plate", (.7595, .035, 1.055), (0, math.pi / 2, 0)),
):
    obj = bpy.data.objects.new(name, plate.data)
    scene.collection.objects.link(obj)
    obj.location, obj.rotation_euler = location, rotation
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 32
player_camera = bpy.data.objects["Player_Camera"]
bounds = {}
for anchor, filename, rotation in (
    ("Carry_Anchor", "plate-standard-carry.png", (0, 0, 0)),
    ("Clean_Anchor", "plate-standard-clean.png", (0, 0, 0)),
    ("Clean_Anchor", "plate-standard-back.png", (math.pi, 0, 0)),
):
    root.parent = bpy.data.objects[anchor]
    root.location = (0, 0, 0)
    root.rotation_euler = rotation
    bpy.context.view_layer.update()
    screen_points = [world_to_camera_view(scene, player_camera, plate.matrix_world @ v.co)
                     for v in plate.data.vertices]
    limits = [min(p.x for p in screen_points), max(p.x for p in screen_points),
              min(p.y for p in screen_points), max(p.y for p in screen_points)]
    assert all(.01 < value < .99 for value in limits), "Plate clipped in holding view"
    assert min(p.z for p in screen_points) > player_camera.data.clip_start
    bounds[filename] = limits
    render(player_camera, filename)
print("PLATE_HOLD_VIEWS_OK", json.dumps(bounds))
print("PLATE_COMPLETE", ASSETS)

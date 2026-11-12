"""Build and bake the floating cleaning sponge with Blender's background CLI.

Run from the project root with Blender --background --factory-startup
--python-exit-code 1 --python Tools/build_standard_sponge.py.
Existing plate and workstation sources are read for previews, not overwritten.
"""

import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "Assets" / "Tools"
TEXTURES = ASSETS / "Textures"
DOCS = ROOT / "Docs"
TEXTURES.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
for group in list(bpy.data.collections):
    bpy.data.collections.remove(group)
scene = bpy.context.scene
scene.unit_settings.system = "METRIC"
scene.unit_settings.scale_length = 1
scene.render.engine = "CYCLES"
scene.cycles.samples = 16
scene.cycles.use_denoising = True
bpy.context.preferences.filepaths.save_version = 0
bpy.context.preferences.filepaths.file_preview_type = "NONE"


def collection(name):
    result = bpy.data.collections.new(name)
    scene.collection.children.link(result)
    return result


asset = collection("01_Sponge_Asset")
studio = collection("90_Preview_Studio")


def empty(name, position, group, parent=None):
    obj = bpy.data.objects.new(name, None)
    group.objects.link(obj)
    obj.location = position
    obj.parent = parent
    obj.empty_display_type = "ARROWS"
    obj.empty_display_size = .015
    return obj


root = empty("Sponge_Standard", (0, 0, 0), asset)
root["dimensions_m"] = [.110, .070, .032]
root["pivot"] = "Centre of contact plane; body above Blender Z=0 / Godot Y=0"
root["contact_normal"] = "Blender -Z / Godot -Y; opposite the dish outward normal"
root["scope"] = "Model, baked PBR maps and compression morph; gameplay is not included"
contact = empty("Scrub_Contact", (0, 0, 0), asset, root)
contact.rotation_euler.x = math.pi
contact["suggested_query_radius_m"] = .018
contact["purpose"] = "Contact target, not a collision body or full cleaning footprint"


def rounded_layer(name, bottom, top, lower_bevel, upper_bevel):
    """Rounded rectangle rings, with a small bonded edge and softer top edge."""
    rings = []
    for i in range(4):
        angle = math.pi / 2 * i / 3
        rings.append((bottom + lower_bevel * (1 - math.cos(angle)),
                      lower_bevel * (1 - math.sin(angle))))
    for i in range(7):
        angle = math.pi / 2 * i / 6
        rings.append((top - upper_bevel + upper_bevel * math.sin(angle),
                      upper_bevel * (1 - math.cos(angle))))
    vertices = []
    for z, inset in rings:
        hx, hy, radius = .055 - inset, .035 - inset, .008 - inset
        for cx, cy, start in ((hx-radius, hy-radius, 0), (-hx+radius, hy-radius, 90),
                              (-hx+radius, -hy+radius, 180), (hx-radius, -hy+radius, 270)):
            for step in range(9):
                angle = math.radians(start + 90 * step / 8)
                vertices.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle), z))
    count = 36
    faces = [tuple(reversed(range(count)))]
    for ring in range(len(rings) - 1):
        for i in range(count):
            nxt = (i + 1) % count
            faces.append((ring*count+i, ring*count+nxt, (ring+1)*count+nxt, (ring+1)*count+i))
    faces.append(tuple(range((len(rings)-1)*count, len(rings)*count)))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    asset.objects.link(obj)
    obj.parent = root
    for face in mesh.polygons:
        face.use_smooth = len(face.vertices) == 4
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.025)
    bpy.ops.object.mode_set(mode="OBJECT")
    bm = bmesh.new()
    bm.from_mesh(mesh)
    assert all(edge.is_manifold for edge in bm.edges)
    assert all(face.calc_area() > 1e-12 for face in bm.faces)
    assert bm.calc_volume(signed=True) > 0
    bm.free()
    return obj


foam = rounded_layer("Sponge_Foam", .0045, .032, .001, .005)
pad = rounded_layer("Sponge_Scrub_Pad", 0, .005, .0008, .0006)


def procedural_material(obj, name, is_foam):
    mat = bpy.data.materials.new(name)
    mat.use_backface_culling = True
    obj.data.materials.append(mat)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader = nodes.get("Principled BSDF")
    shader.inputs["Roughness"].default_value = .86
    shader.inputs["Specular IOR Level"].default_value = .25
    coords = nodes.new("ShaderNodeTexCoord")
    scale = nodes.new("ShaderNodeVectorMath")
    scale.operation = "MULTIPLY"
    # Scale each axis to keep cell sizes isotropic in real metres.
    cell = .0019 if is_foam else .00065
    scale.inputs[1].default_value = (.110/cell, .070/cell, (.0275 if is_foam else .005)/cell)
    links.new(coords.outputs["Generated"], scale.inputs[0])
    voronoi = nodes.new("ShaderNodeTexVoronoi")
    voronoi.feature = "F1" if is_foam else "DISTANCE_TO_EDGE"
    links.new(scale.outputs["Vector"], voronoi.inputs["Vector"])
    voronoi.inputs["Scale"].default_value = 1
    height = nodes.new("ShaderNodeValToRGB")
    height.color_ramp.elements[0].position = .08 if is_foam else .015
    height.color_ramp.elements[0].color = (.05, .05, .05, 1)
    height.color_ramp.elements[1].position = .43 if is_foam else .12
    links.new(voronoi.outputs["Distance"], height.inputs["Fac"])
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = 5
    noise.inputs["Detail"].default_value = 3
    links.new(scale.outputs["Vector"], noise.inputs["Vector"])
    multiply = nodes.new("ShaderNodeMath")
    multiply.operation = "MULTIPLY"
    links.new(height.outputs["Color"], multiply.inputs[0])
    links.new(noise.outputs["Fac"], multiply.inputs[1])
    bump = nodes.new("ShaderNodeBump")
    bump.inputs["Strength"].default_value = .65 if is_foam else .55
    bump.inputs["Distance"].default_value = .0007 if is_foam else .0003
    links.new(multiply.outputs[0], bump.inputs["Height"])
    links.new(bump.outputs["Normal"], shader.inputs["Normal"])
    color = nodes.new("ShaderNodeValToRGB")
    colors = ((.38, .16, .012, 1), (.95, .64, .08, 1)) if is_foam else ((.012, .047, .025, 1), (.07, .19, .095, 1))
    for element, rgba in zip(color.color_ramp.elements, colors):
        element.color = rgba
    links.new(height.outputs["Color"], color.inputs["Fac"])
    links.new(color.outputs["Color"], shader.inputs["Base Color"])
    rough = nodes.new("ShaderNodeMapRange")
    rough.inputs["To Min"].default_value = .76 if is_foam else .84
    rough.inputs["To Max"].default_value = .95
    links.new(noise.outputs["Fac"], rough.inputs["Value"])
    links.new(rough.outputs["Result"], shader.inputs["Roughness"])
    return mat, color.outputs["Color"], rough.outputs["Result"]


def bake_material(obj, name, is_foam):
    mat, color_socket, rough_socket = procedural_material(obj, name, is_foam)
    nodes, links = mat.node_tree.nodes, mat.node_tree.links
    shader, output = nodes.get("Principled BSDF"), nodes.get("Material Output")
    emitter = nodes.new("ShaderNodeEmission")
    target = nodes.new("ShaderNodeTexImage")
    nodes.active = target
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    images = {}
    prefix = "sponge-foam" if is_foam else "sponge-pad"
    for channel in ("normal", "basecolor", "roughness"):
        image = bpy.data.images.new(prefix + "-" + channel, width=1024, height=1024, alpha=False)
        image.colorspace_settings.name = "sRGB" if channel == "basecolor" else "Non-Color"
        target.image = image
        if channel == "normal":
            bpy.ops.object.bake(type="NORMAL", normal_space="TANGENT", margin=16, use_clear=True)
        else:
            links.new(color_socket if channel == "basecolor" else rough_socket, emitter.inputs["Color"])
            links.new(emitter.outputs[0], output.inputs["Surface"])
            bpy.ops.object.bake(type="EMIT", margin=16, use_clear=True)
        image.filepath_raw = str(TEXTURES / (prefix + "-" + channel + ".png"))
        image.file_format = "PNG"
        image.save()
        image.pack()
        image.filepath = "//Textures/" + prefix + "-" + channel + ".png"
        images[channel] = image
    # Replace the Blender-only procedural graph with portable baked PBR maps.
    for node in list(nodes):
        if node not in (shader, output):
            nodes.remove(node)
    links.new(shader.outputs["BSDF"], output.inputs["Surface"])
    for channel, socket_name in (("basecolor", "Base Color"), ("roughness", "Roughness"), ("normal", "Normal")):
        texture = nodes.new("ShaderNodeTexImage")
        texture.image = images[channel]
        if channel == "normal":
            normal = nodes.new("ShaderNodeNormalMap")
            links.new(texture.outputs["Color"], normal.inputs["Color"])
            links.new(normal.outputs["Normal"], shader.inputs[socket_name])
        else:
            links.new(texture.outputs["Color"], shader.inputs[socket_name])
    print("SPONGE_BAKED", name, flush=True)


bake_material(foam, "Sponge_Yellow_Foam", True)
bake_material(pad, "Sponge_Green_Scrub", False)
foam.shape_key_add(name="Basis")
compressed = foam.shape_key_add(name="Contact_Compress")
for point in compressed.data:
    point.co.z = .0045 + (point.co.z - .0045) * .82
    point.co.x *= 1.012
    point.co.y *= 1.012
compressed.value = 0
bpy.context.view_layer.update()
for obj in (foam, pad):
    assert tuple(obj.scale) == (1, 1, 1)
    assert all(0 <= component <= 1 for data in obj.data.uv_layers.active.data for component in data.uv)
    obj.data.calc_loop_triangles()
print("SPONGE_GEOMETRY_OK", sum(len(o.data.vertices) for o in (foam, pad)), "vertices",
      sum(len(o.data.loop_triangles) for o in (foam, pad)), "triangles", flush=True)
bpy.ops.object.select_all(action="DESELECT")
for obj in asset.objects:
    obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(ASSETS / "sponge-standard.glb"), export_format="GLB",
                          use_selection=True, export_extras=True, export_morph=True)


def camera(name, location, target, size):
    data = bpy.data.cameras.new(name)
    obj = bpy.data.objects.new(name, data)
    studio.objects.link(obj)
    obj.location = location
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    data.type = "ORTHO"
    data.ortho_scale = size
    data.clip_start = .002
    return obj


def render(camera_obj, filename):
    scene.camera = camera_obj
    scene.render.filepath = str(DOCS / filename)
    bpy.ops.render.render(write_still=True)


for name, location, energy, size in (("Preview_Key", (-.25, -.20, .30), 6, .18),
                                     ("Preview_Fill", (.25, .15, .30), 3, .22)):
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
ground_mat = bpy.data.materials.new("Preview_Sage_Ground")
ground_mat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (.16, .22, .215, 1)
ground_mat.node_tree.nodes["Principled BSDF"].inputs["Roughness"].default_value = .9
floor.data.materials.append(ground_mat)
preview_objects = []
for index, (position, rotation) in enumerate((((-.065, 0, 0), 0), ((.065, .012, .032), math.pi))):
    holder = empty("Preview_Sponge_" + str(index), position, studio)
    holder.rotation_euler.x = rotation
    for source in (foam, pad):
        obj = source.copy()
        studio.objects.link(obj)
        obj.parent = holder
        preview_objects.append(obj)
foam.hide_render = pad.hide_render = True
scene.cycles.samples = 48
scene.render.resolution_x, scene.render.resolution_y = 1600, 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = "PNG"
scene.view_settings.view_transform = "AgX"
scene.world.color = (.22, .22, .22)
hero = camera("Preview_Foam_And_Scrub", (0, -.28, .25), (0, 0, .012), .30)
render(hero, "sponge-standard-overview.png")
for obj in preview_objects:
    obj.hide_render = True
foam.hide_render = pad.hide_render = False
studio.hide_viewport = True
scene.camera = camera("Preview_Single_Sponge", (.15, -.20, .15), (0, 0, .016), .15)
for area in bpy.context.screen.areas:
    if area.type == "VIEW_3D":
        area.spaces.active.region_3d.view_distance = .23
        area.spaces.active.region_3d.view_location = (0, 0, .016)
        area.spaces.active.region_3d.view_rotation = scene.camera.rotation_euler.to_quaternion()
bpy.ops.object.select_all(action="DESELECT")
foam.select_set(True)
bpy.context.view_layer.objects.active = foam
bpy.ops.wm.save_as_mainfile(filepath=str(ASSETS / "sponge-standard.blend"))

# Preview contact in the actual near-cleaning view. The original files stay intact.
bpy.ops.wm.open_mainfile(filepath=str(ROOT / "Assets" / "Graybox" / "kitchen-workstation.blend"))
scene = bpy.context.scene
for path, group_name in ((ROOT / "Assets" / "Dishes" / "plate-standard.blend", "01_Plate_Asset"),
                          (ASSETS / "sponge-standard.blend", "01_Sponge_Asset")):
    with bpy.data.libraries.load(str(path), link=False) as (source, target):
        target.collections = [group_name]
    scene.collection.children.link(target.collections[0])
plate_root = bpy.data.objects["Plate_Standard"]
plate = bpy.data.objects["Plate_Surface"]
root = bpy.data.objects["Sponge_Standard"]
foam = bpy.data.objects["Sponge_Foam"]
pad = bpy.data.objects["Sponge_Scrub_Pad"]
for name in ("Sponge_Proxy", "QA_Held_Plate_250mm"):
    bpy.data.objects[name].hide_render = True
plate.hide_render = True
root.location = (-.30, .17, .9285)
scene.render.resolution_x, scene.render.resolution_y = 1600, 900
scene.cycles.samples = 32
player_camera = bpy.data.objects["Player_Camera"]
render(player_camera, "sponge-standard-rest.png")
plate.hide_render = False
plate_root.parent = bpy.data.objects["Clean_Anchor"]
plate_root.location = (0, 0, 0)
root.parent = plate_root
root.location = (.014, -.009, -.002)
root.rotation_euler.z = math.radians(-18)
foam.data.shape_keys.key_blocks["Contact_Compress"].value = .65
bpy.context.view_layer.update()
# The pad's flat contact plane touches the plate's flat central well.
assert (bpy.data.objects["Scrub_Contact"].matrix_world.translation -
        plate.matrix_world @ Vector((.014, -.009, -.002))).length < 1e-6
render(player_camera, "sponge-standard-clean.png")

# A close oblique inspection makes the contact edge and layer thickness readable.
studio = scene.collection
contact_cam = camera("Preview_Contact_Detail", (0, 0, 0), (0, 0, 0), .30)
contact_cam.location = plate.matrix_world @ Vector((.20, -.28, .18))
target = plate.matrix_world @ Vector((0, 0, .005))
contact_cam.rotation_euler = (target-contact_cam.location).to_track_quat("-Z", "Y").to_euler()
scene.render.resolution_y = 1000
render(contact_cam, "sponge-standard-contact.png")
print("SPONGE_COMPLETE", ASSETS, flush=True)

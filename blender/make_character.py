# Blender 4.x script — สร้างตัวละคร Low-Poly จาก Primitive พื้นฐาน (Cube / Cylinder / UV Sphere)
# + โครงกระดูกตั้งชื่อแบบ Mixamo (mixamorig_*) + ท่า TPose  แล้ว export เป็น .glb ให้ Godot
# รัน:  blender -b -P make_character.py
import bpy, bmesh, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
OUT_GLB = os.path.join(HERE, "..", "godot", "Assets", "Character", "Purichaya.glb")
OUT_BLEND = os.path.join(HERE, "Purichaya.blend")
FACE_PNG = os.path.join(HERE, "face.png")

bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

# ------------------------------------------------------------------ materials
def mat(name, rgb, rough=0.7):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1)
    b.inputs["Roughness"].default_value = rough
    m.diffuse_color = (*rgb, 1)
    return m

SKIN = mat("Skin", (0.93, 0.72, 0.6))
HAIR = mat("Hair", (0.12, 0.07, 0.05), 0.5)
SHIRT = mat("Hoodie", (0.95, 0.55, 0.68))
PANTS = mat("Pants", (0.16, 0.2, 0.36))
SHOES = mat("Shoes", (0.96, 0.96, 0.96))
SOLE = mat("Sole", (0.25, 0.22, 0.25))

FACE = bpy.data.materials.new("Face")
FACE.use_nodes = True
nt = FACE.node_tree
bsdf = nt.nodes["Principled BSDF"]
tex = nt.nodes.new("ShaderNodeTexImage")
tex.image = bpy.data.images.load(FACE_PNG)
nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
nt.links.new(tex.outputs["Alpha"], bsdf.inputs["Alpha"])
FACE.blend_method = "CLIP"

# ------------------------------------------------------------------ helpers
parts = []   # (object, allowed bones)

def finish(obj, material, bones, smooth=False, subsurf=0):
    obj.data.materials.append(material)
    if subsurf:
        m = obj.modifiers.new("Subsurf", "SUBSURF")
        m.levels = subsurf
        m.render_levels = subsurf
    for p in obj.data.polygons:
        p.use_smooth = smooth
    parts.append((obj, bones))
    return obj

def cube(name, loc, size, material, bones, bevel=0.0, subsurf=0, smooth=False):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    if bevel > 0:
        b = o.modifiers.new("Bevel", "BEVEL")
        b.width = bevel
        b.segments = 2
    return finish(o, material, bones, smooth, subsurf)

def cyl(name, a, b, r1, r2, material, bones, verts=8, sy=1.0, subsurf=0):
    a, b = Vector(a), Vector(b)
    d = b - a
    bpy.ops.mesh.primitive_cone_add(vertices=verts, radius1=r1, radius2=r2, depth=d.length, location=(a + b) / 2)
    o = bpy.context.active_object
    o.name = name
    o.rotation_mode = "QUATERNION"
    o.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(d.normalized())
    bpy.ops.object.transform_apply(rotation=True)
    if sy != 1.0:
        o.scale = (1, sy, 1)
        bpy.ops.object.transform_apply(scale=True)
    return finish(o, material, bones, subsurf > 0, subsurf)

def sphere(name, loc, scale, material, bones, seg=12, rings=8, smooth=True):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=rings, radius=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    return finish(o, material, bones, smooth)

# ------------------------------------------------------------------ joint positions (เมตร, หันหน้าไป -Y)
J = {
    "Hips": (0, 0, 0.95), "Spine": (0, 0, 1.05), "Spine1": (0, 0, 1.17), "Spine2": (0, 0, 1.29),
    "Neck": (0, 0, 1.45), "Head": (0, 0, 1.53), "HeadTop_End": (0, 0, 1.88),
    "LeftShoulder": (0.05, 0, 1.40), "LeftArm": (0.19, 0, 1.40), "LeftForeArm": (0.45, 0, 1.40),
    "LeftHand": (0.69, 0, 1.40), "LeftHand_End": (0.80, 0, 1.40),
    "LeftUpLeg": (0.10, 0, 0.92), "LeftLeg": (0.10, 0, 0.50), "LeftFoot": (0.10, 0.0, 0.09),
    "LeftToeBase": (0.10, -0.12, 0.02), "LeftToe_End": (0.10, -0.2, 0.02),
}
for k in list(J):
    if k.startswith("Left"):
        x, y, z = J[k]
        J["Right" + k[4:]] = (-x, y, z)
V = lambda k: Vector(J[k])

# ------------------------------------------------------------------ body (Primitive modelling)
# ศีรษะ + ผม + ใบหน้า
head_c = Vector((0, 0, 1.68))
sphere("Head", head_c, (0.165, 0.155, 0.185), SKIN, ["Head"], seg=16, rings=10)
hair = sphere("HairCap", head_c + Vector((0, 0.012, 0.03)), (0.178, 0.172, 0.192), HAIR, ["Head"], seg=16, rings=10)
bm = bmesh.new(); bm.from_mesh(hair.data)
cut = [v for v in bm.verts if (v.co.y < -0.04 and v.co.z < head_c.z + 0.055) or (v.co.z < head_c.z - 0.11)]
bmesh.ops.delete(bm, geom=cut, context="VERTS"); bm.to_mesh(hair.data); bm.free()
cube("Bangs", head_c + Vector((0, -0.135, 0.12)), (0.3, 0.07, 0.08), HAIR, ["Head"], bevel=0.02)
sphere("PonyTail", head_c + Vector((0, 0.19, -0.06)), (0.08, 0.075, 0.16), HAIR, ["Head"], seg=10, rings=6)
cube("BackHair", head_c + Vector((0, 0.1, -0.1)), (0.3, 0.12, 0.16), HAIR, ["Head"], bevel=0.05, subsurf=1, smooth=True)
for sx in (-1, 1):
    cube("SideHair", head_c + Vector((sx * 0.15, -0.03, -0.06)), (0.05, 0.12, 0.2), HAIR, ["Head"], bevel=0.02, subsurf=1, smooth=True)
sphere("HairTie", head_c + Vector((0, 0.15, 0.06)), (0.035, 0.03, 0.035), SHIRT, ["Head"], seg=8, rings=5)
for sx in (-1, 1):
    sphere("Ear", head_c + Vector((sx * 0.16, 0, 0)), (0.025, 0.02, 0.04), SKIN, ["Head"], seg=8, rings=5)
bpy.ops.mesh.primitive_plane_add(size=0.28, location=head_c + Vector((0, -0.162, -0.025)), rotation=(math.radians(90), 0, 0))
face = bpy.context.active_object
face.name = "FaceDecal"
bpy.ops.object.transform_apply(rotation=True)
# ทำให้ระนาบโค้งตามหน้า (ลูกบาศก์เล็กน้อย)
face_mod = face.modifiers.new("Sub", "SUBSURF"); face_mod.levels = 2; face_mod.subdivision_type = "SIMPLE"
bpy.ops.object.modifier_apply(modifier="Sub")
for v in face.data.vertices:
    x = v.co.x
    v.co.y += (x / 0.15) ** 2 * 0.05
finish(face, FACE, ["Head"])

# คอ ลำตัว (เสื้อฮู้ด)
cyl("Neck", V("Spine2") + Vector((0, 0, 0.1)), V("Head") + Vector((0, 0, 0.02)), 0.05, 0.045, SKIN, ["Neck", "Head"], 8)
cyl("Torso", (0, 0, 0.93), (0, 0, 1.44), 0.155, 0.185, SHIRT, ["Hips", "Spine", "Spine1", "Spine2", "LeftShoulder", "RightShoulder"], 12, 0.62, 1)
sphere("Shoulders", (0, 0, 1.40), (0.2, 0.11, 0.06), SHIRT, ["Spine2", "LeftShoulder", "RightShoulder"], seg=12, rings=6)
cube("Pocket", (0, -0.1, 1.06), (0.18, 0.02, 0.08), mat("Pocket", (0.88, 0.45, 0.58)), ["Spine"], bevel=0.01)
cyl("Hood", (0, 0.11, 1.38), (0, 0.1, 1.46), 0.13, 0.11, SHIRT, ["Spine2", "Neck"], 10)
cube("Pelvis", (0, 0, 0.94), (0.31, 0.18, 0.14), PANTS, ["Hips", "LeftUpLeg", "RightUpLeg"], bevel=0.04)

for side in ("Left", "Right"):
    s = 1 if side == "Left" else -1
    # แขน
    cyl(side + "Sleeve", V(side + "Arm") + Vector((-s * 0.05, 0, 0)), V(side + "ForeArm"), 0.06, 0.05, SHIRT, [side + "Shoulder", side + "Arm", side + "ForeArm"], 8)
    cyl(side + "ForeArmM", V(side + "ForeArm"), V(side + "Hand") - Vector((s * 0.03, 0, 0)), 0.05, 0.042, SHIRT, [side + "Arm", side + "ForeArm", side + "Hand"], 8)
    cyl(side + "Cuff", V(side + "Hand") - Vector((s * 0.05, 0, 0)), V(side + "Hand") - Vector((s * 0.01, 0, 0)), 0.046, 0.046, mat("Cuff", (0.88, 0.45, 0.58)), [side + "ForeArm", side + "Hand"], 8)
    sphere(side + "Palm", V(side + "Hand") + Vector((s * 0.05, 0, 0)), (0.06, 0.03, 0.045), SKIN, [side + "Hand"], seg=8, rings=6)
    sphere(side + "Thumb", V(side + "Hand") + Vector((s * 0.03, -0.035, 0)), (0.02, 0.02, 0.015), SKIN, [side + "Hand"], seg=6, rings=4)
    # ขา
    cyl(side + "Thigh", V(side + "UpLeg") + Vector((0, 0, 0.02)), V(side + "Leg"), 0.085, 0.065, PANTS, ["Hips", side + "UpLeg", side + "Leg"], 8)
    cyl(side + "Shin", V(side + "Leg"), V(side + "Foot") + Vector((0, 0, 0.04)), 0.065, 0.05, PANTS, [side + "UpLeg", side + "Leg", side + "Foot"], 8)
    cube(side + "Shoe", V(side + "Foot") + Vector((0, -0.05, -0.035)), (0.1, 0.24, 0.1), SHOES, [side + "Foot", side + "ToeBase"], bevel=0.035)
    cube(side + "Sole", V(side + "Foot") + Vector((0, -0.05, -0.08)), (0.105, 0.245, 0.02), SOLE, [side + "Foot", side + "ToeBase"])

# apply modifiers ก่อนรวมร่าง
for o, _ in parts:
    bpy.context.view_layer.objects.active = o
    for m in list(o.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)

# ------------------------------------------------------------------ armature (ชื่อกระดูกแบบ Mixamo)
bpy.ops.object.armature_add(location=(0, 0, 0))
arm = bpy.context.active_object
arm.name = "Armature"
arm.data.name = "Armature"
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones
for b in list(eb):
    eb.remove(b)
P = "mixamorig_"
chain = [
    ("Hips", None, "Spine"), ("Spine", "Hips", "Spine1"), ("Spine1", "Spine", "Spine2"), ("Spine2", "Spine1", "Neck"),
    ("Neck", "Spine2", "Head"), ("Head", "Neck", "HeadTop_End"),
]
for side in ("Left", "Right"):
    chain += [
        (side + "Shoulder", "Spine2", side + "Arm"), (side + "Arm", side + "Shoulder", side + "ForeArm"),
        (side + "ForeArm", side + "Arm", side + "Hand"), (side + "Hand", side + "ForeArm", side + "Hand_End"),
        (side + "UpLeg", "Hips", side + "Leg"), (side + "Leg", side + "UpLeg", side + "Foot"),
        (side + "Foot", side + "Leg", side + "ToeBase"), (side + "ToeBase", side + "Foot", side + "Toe_End"),
    ]
for name, parent, tail in chain:
    b = eb.new(P + name)
    b.head = V(name)
    b.tail = V(tail)
    if name == "Hips":
        b.tail = V("Spine")
    if parent:
        b.parent = eb[P + parent]
        b.use_connect = False
    # roll ให้แกนแขนชี้ไปทางเดียวกัน
    b.roll = 0
bpy.ops.object.mode_set(mode="OBJECT")

# ------------------------------------------------------------------ รวม mesh + skin weights (เบลนด์ตามระยะห่างจากกระดูก)
def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab.length_squared))
    return (a + ab * t - p).length

bone_seg = {}
for name, parent, tail in chain:
    bone_seg[P + name] = (V(name), V(tail) if name != "Hips" else V("Spine"))

for o, bones in parts:
    for bn in bones:
        o.vertex_groups.new(name=P + bn)
    mw = o.matrix_world
    for v in o.data.vertices:
        p = mw @ v.co
        ws = []
        for bn in bones:
            a, b = bone_seg[P + bn]
            d = seg_dist(p, a, b) + 0.01
            ws.append(1.0 / d ** 6)
        tot = sum(ws)
        for bn, w in zip(bones, ws):
            w = w / tot
            if w > 0.02:
                o.vertex_groups[P + bn].add([v.index], w, "REPLACE")

bpy.ops.object.select_all(action="DESELECT")
for o, _ in parts:
    o.select_set(True)
bpy.context.view_layer.objects.active = parts[0][0]
bpy.ops.object.join()
body = bpy.context.active_object
body.name = "PurichayaMesh"
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
body.parent = arm
mod = body.modifiers.new("Armature", "ARMATURE")
mod.object = arm

# ------------------------------------------------------------------ ท่า TPose (คีย์เฟรมเดียว)
bpy.context.view_layer.objects.active = arm
arm.animation_data_create()
act = bpy.data.actions.new("TPose")
arm.animation_data.action = act
bpy.ops.object.mode_set(mode="POSE")
for pb in arm.pose.bones:
    pb.rotation_mode = "QUATERNION"
    pb.keyframe_insert("rotation_quaternion", frame=1)
    pb.keyframe_insert("location", frame=1)
bpy.ops.object.mode_set(mode="OBJECT")
scene.frame_start = 1
scene.frame_end = 1

os.makedirs(os.path.dirname(OUT_GLB), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
bpy.ops.export_scene.gltf(filepath=OUT_GLB, export_format="GLB", export_animations=True, export_skins=True,
                          export_apply=False, export_yup=True, export_image_format="AUTO")
print("EXPORTED", OUT_GLB, "verts", len(body.data.vertices))

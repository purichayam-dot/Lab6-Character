extends SceneTree
## สร้างฉาก Scenes/Character.tscn อัตโนมัติ:
## Node2D -> Skeleton2D/Bone2D + Polygon2D (UV จาก sprite sheet) + AnimationPlayer

const ORIGIN := Vector2(263, 744)   # จุดกึ่งกลางเท้า ในพิกัดภาพประกอบ
# ชื่อกระดูก: [parent, ตำแหน่งข้อต่อ (พิกัดภาพ), ปลายกระดูก (พิกัดภาพ)]
const BONES := {
	"hip":          ["",            Vector2(263, 470), Vector2(263, 420)],
	"torso":        ["hip",         Vector2(263, 420), Vector2(263, 262)],
	"head":         ["torso",       Vector2(263, 262), Vector2(263, 110)],
	"arm_far_up":   ["torso",       Vector2(214, 282), Vector2(192, 368)],
	"arm_far_low":  ["arm_far_up",  Vector2(192, 368), Vector2(176, 470)],
	"arm_near_up":  ["torso",       Vector2(312, 282), Vector2(336, 368)],
	"arm_near_low": ["arm_near_up", Vector2(336, 368), Vector2(352, 470)],
	"leg_far_up":   ["hip",         Vector2(240, 470), Vector2(236, 592)],
	"leg_far_low":  ["leg_far_up",  Vector2(236, 592), Vector2(234, 714)],
	"leg_near_up":  ["hip",         Vector2(288, 470), Vector2(292, 592)],
	"leg_near_low": ["leg_near_up", Vector2(292, 592), Vector2(294, 714)],
}
const BONE_ORDER := ["hip", "torso", "head", "arm_far_up", "arm_far_low", "arm_near_up", "arm_near_low",
	"leg_far_up", "leg_far_low", "leg_near_up", "leg_near_low"]
# ชิ้นส่วน -> กระดูกที่ผูก (weight = 1.0)
const PART_BONE := {
	"hair": "head", "head": "head", "torso": "torso", "skirt": "hip",
	"arm_far_up": "arm_far_up", "arm_far_low": "arm_far_low",
	"arm_near_up": "arm_near_up", "arm_near_low": "arm_near_low",
	"leg_far_up": "leg_far_up", "leg_far_low": "leg_far_low",
	"leg_near_up": "leg_near_up", "leg_near_low": "leg_near_low",
}
# ชิ้นส่วนที่ข้อต่อ: กระจายน้ำหนักบางส่วนให้กระดูกแม่ (in-between ที่ข้อต่อดูเนียนขึ้น)
const SOFT_JOINT := {
	"torso": ["hip", Vector2(263, 424), 26.0],
	"skirt": ["torso", Vector2(263, 412), 14.0],
}

var bone_paths := {}

func _init() -> void:
	process_frame.connect(_build, CONNECT_ONE_SHOT)

func _own(n: Node, owner_node: Node) -> void:
	n.owner = owner_node
	for c in n.get_children():
		_own(c, owner_node)

func _build() -> void:
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tools/rig.json"))
	var tex: Texture2D = load("res://Assets/Art/purichaya_sheet.png")

	var root := Node2D.new()
	root.name = "Purichaya"
	root.set_script(load("res://Scripts/Character.gd"))

	# เงาใต้เท้า
	var shadow := Polygon2D.new()
	shadow.name = "Shadow"
	var sp := PackedVector2Array()
	for i in 32:
		var a := TAU * i / 32.0
		sp.append(Vector2(cos(a) * 95.0, sin(a) * 16.0 - 6.0))
	shadow.polygon = sp
	shadow.color = Color(0.1, 0.15, 0.1, 1)
	shadow.modulate.a = 0.35
	root.add_child(shadow)

	# ---- Skeleton2D + Bone2D
	var skel := Skeleton2D.new()
	skel.name = "Skeleton"
	root.add_child(skel)
	var nodes := {}
	for b in BONE_ORDER:
		var info: Array = BONES[b]
		var bone := Bone2D.new()
		bone.name = b
		var parent_pos: Vector2 = ORIGIN if info[0] == "" else BONES[info[0]][1]
		bone.position = info[1] - parent_pos
		bone.set_autocalculate_length_and_angle(false)
		var dir: Vector2 = info[2] - info[1]
		bone.set_length(dir.length())
		bone.set_bone_angle(dir.angle())
		bone.rest = bone.transform
		if info[0] == "":
			skel.add_child(bone)
			bone_paths[b] = b
		else:
			nodes[info[0]].add_child(bone)
			bone_paths[b] = bone_paths[info[0]] + "/" + b
		nodes[b] = bone

	# ---- Polygon2D ชิ้นส่วนร่างกาย (ใช้ texture เดียว + UV)
	var body := Node2D.new()
	body.name = "Body"
	root.add_child(body)
	for part in rig["order"]:
		var d: Dictionary = rig["parts"][part]
		var poly := Polygon2D.new()
		poly.name = part
		poly.texture = tex
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for v in d["polygon"]:
			pts.append(Vector2(v[0], v[1]))
		for v in d["uv"]:
			uvs.append(Vector2(v[0], v[1]))
		poly.polygon = pts
		poly.uv = uvs
		body.add_child(poly)
		poly.skeleton = poly.get_path_to(skel)
		var main_bone: String = PART_BONE[part]
		var w_main := PackedFloat32Array()
		var w_soft := PackedFloat32Array()
		var soft: Array = SOFT_JOINT.get(part, [])
		for p in pts:
			var ws := 0.0
			if soft.size() > 0:
				var dist: float = absf((p + ORIGIN).y - soft[1].y)
				ws = clampf(1.0 - dist / soft[2], 0.0, 1.0) * 0.5
			w_main.append(1.0 - ws)
			w_soft.append(ws)
		# ทุกกระดูกต้องอยู่ในรายการ (Godot ต้องการน้ำหนักครบทุกกระดูก)
		for b in BONE_ORDER:
			var w := PackedFloat32Array()
			if b == main_bone:
				w = w_main
			elif soft.size() > 0 and b == soft[0]:
				w = w_soft
			else:
				w.resize(pts.size())
				w.fill(0.0)
			poly.add_bone(NodePath(bone_paths[b]), w)

	# ---- เส้นโครงกระดูก (เปิด/ปิดได้)
	var overlay := Node2D.new()
	overlay.name = "BoneOverlay"
	overlay.set_script(load("res://Scripts/BoneOverlay.gd"))
	overlay.visible = false
	root.add_child(overlay)

	# ---- AnimationPlayer
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	root.add_child(ap)
	var lib := AnimationLibrary.new()
	var A = load("res://tools/anim_data.gd").new()
	lib.add_animation("RESET", _make_anim("RESET", [[0.0, {}]], 0.001, false))
	for n in A.ANIMS:
		var spec: Dictionary = A.ANIMS[n]
		lib.add_animation(n, _make_anim(n, spec["keys"], spec["length"], spec["loop"]))
	ap.add_animation_library("", lib)
	ap.autoplay = "idle"


	for c in root.get_children():
		_own(c, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	print("pack: ", err)
	print("save: ", ResourceSaver.save(ps, "res://Scenes/Character.tscn"))
	quit()

func _make_anim(_n: String, keys: Array, length: float, loop: bool) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	# rotation ของกระดูกทุกชิ้น
	for b in BONE_ORDER:
		var t := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(t, NodePath("Skeleton/" + bone_paths[b] + ":rotation"))
		a.track_set_interpolation_type(t, Animation.INTERPOLATION_CUBIC)
		a.value_track_set_update_mode(t, Animation.UPDATE_CONTINUOUS)
		for k in keys:
			a.track_insert_key(t, k[0], float(k[1].get(b, 0.0)))
	# สลับลำดับการวาด (z_index) ของแขนด้านหลังตอนต่อยหมัดหลัง
	for part in ["arm_far_up", "arm_far_low"]:
		var tz := a.add_track(Animation.TYPE_VALUE)
		a.track_set_path(tz, NodePath("Body/" + part + ":z_index"))
		a.value_track_set_update_mode(tz, Animation.UPDATE_DISCRETE)
		a.track_set_interpolation_type(tz, Animation.INTERPOLATION_NEAREST)
		for k in keys:
			a.track_insert_key(tz, k[0], int(k[1].get("z_far", 0)))
	# ตำแหน่งสะโพก (ยก/ย่อตัว)
	var rest_hip: Vector2 = BONES["hip"][1] - ORIGIN
	var tp := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(tp, NodePath("Skeleton/hip:position"))
	a.track_set_interpolation_type(tp, Animation.INTERPOLATION_CUBIC)
	for k in keys:
		a.track_insert_key(tp, k[0], rest_hip + Vector2(k[1].get("hip_x", 0.0), k[1].get("hip_y", 0.0)))
	return a

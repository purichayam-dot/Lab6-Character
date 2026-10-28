extends Node2D
## ฉาก 2D แสดงตัวละครในแต่ละท่า: ยืน เดิน กระโดด ต่อย
## โหมดอัตโนมัติ (ใช้บันทึกวิดีโอ ~1 นาที) และโหมดควบคุมเอง

const FONT_B := preload("res://Assets/Fonts/Kanit-Bold.ttf")
const FONT_R := preload("res://Assets/Fonts/Kanit-Regular.ttf")
const GROUND_Y := 640.0
const SOLO_SCALE := 0.62
const NAMES := {"idle": "ยืน (Idle)", "walk": "เดิน (Walk)", "jump": "กระโดด (Jump)", "punch": "ต่อย (Punch)", "die": "ตาย (Die)"}

# ลำดับการแสดงอัตโนมัติ รวม 60 วินาที
const SEQUENCE := [
	{"dur": 9.0,  "mode": "gallery", "caption": "ท่าหลักทั้ง 5 ท่า: Keyframes + In-betweens"},
	{"dur": 7.0,  "mode": "solo", "anim": "idle",  "bones_at": 2.0, "caption": "ยืน: หายใจ/โยกตัว • แสดงโครงกระดูก Skeleton2D / Bone2D"},
	{"dur": 11.0, "mode": "walk", "anim": "walk",  "caption": "เดิน: Contact → Passing → Contact → Passing (วนลูป)"},
	{"dur": 8.0,  "mode": "solo", "anim": "jump",  "caption": "กระโดด: ย่อตัว → ส่งตัว → ลอยสูงสุด → ตกลง → ย่อรับแรง"},
	{"dur": 8.0,  "mode": "solo", "anim": "punch", "caption": "ต่อสู้: การ์ด → ง้าง → หมัดหน้า → หมัดหลัง → การ์ด"},
	{"dur": 8.0,  "mode": "solo", "anim": "die",   "caption": "ตาย: โดนโจมตี → เซ → เข่าทรุด → ล้มหงาย → นิ่ง"},
	{"dur": 9.0,  "mode": "gallery", "bones_at": 4.0, "caption": "Polygon2D ผูกกับ Bone2D — ทุกท่าใช้โครงกระดูกเดียวกัน"},
]

@onready var solo: Node2D = $Solo
@onready var gallery: Node2D = $Gallery

var auto_mode := true
var seg_index := 0
var seg_time := 0.0
var walk_targets: Array = []
var bones_on := false
var manual_anim := "idle"

var pose_label: Label
var caption_label: Label
var hint_label: Label
var time_label: Label

func _ready() -> void:
	_build_ui()
	var anims := ["idle", "walk", "jump", "punch", "die"]
	for i in gallery.get_child_count():
		var c: Node2D = gallery.get_child(i)
		if c.has_method("play_anim"):
			c.call_deferred("restart_anim", anims[i], 0.0)
	_start_segment(0)

# ---------------------------------------------------------------- อัตโนมัติ
func _start_segment(i: int) -> void:
	seg_index = i % SEQUENCE.size()
	seg_time = 0.0
	var s: Dictionary = SEQUENCE[seg_index]
	_set_bones(false)
	caption_label.text = s["caption"]
	if s["mode"] == "gallery":
		_show_gallery(true)
		pose_label.text = "ท่าทั้งหมด"
	else:
		_show_gallery(false)
		solo.position = Vector2(640, GROUND_Y)
		solo.set_facing(1)
		solo.restart_anim(s["anim"], 0.0)
		pose_label.text = NAMES[s["anim"]]
		walk_targets = []
		if s["mode"] == "walk":
			solo.position.x = 170
			walk_targets = [1110.0, 170.0, 640.0]

func _show_gallery(on: bool) -> void:
	gallery.visible = on
	solo.visible = not on

func _set_bones(on: bool) -> void:
	bones_on = on
	solo.show_bones(on)
	for c in gallery.get_children():
		if c.has_method("show_bones"):
			c.show_bones(on)

func _process(delta: float) -> void:
	if auto_mode:
		seg_time += delta
		var s: Dictionary = SEQUENCE[seg_index]
		if s.has("bones_at") and not bones_on and seg_time >= s["bones_at"]:
			_set_bones(true)
		if s["mode"] == "walk":
			_auto_walk(delta)
		_replay_finished()
		if seg_time >= s["dur"]:
			_start_segment(seg_index + 1)
		time_label.text = "AUTO  %d / 60 วินาที" % int(_elapsed())
	else:
		_manual(delta)

# ท่าที่ไม่วนลูป (ตาย) เล่นซ้ำเมื่อจบ
func _replay_finished() -> void:
	for c in [solo] + gallery.get_children():
		if c.has_method("restart_anim") and c.visible and not c.anim.is_playing():
			c.restart_anim(c.anim.assigned_animation, 0.3)

func _elapsed() -> float:
	var t := 0.0
	for i in seg_index:
		t += SEQUENCE[i]["dur"]
	return t + seg_time

func _auto_walk(delta: float) -> void:
	if walk_targets.is_empty():
		solo.play_anim("idle", 0.35)
		pose_label.text = NAMES["idle"]
		return
	var tx: float = walk_targets[0]
	var dir := signf(tx - solo.position.x)
	solo.set_facing(int(dir))
	solo.play_anim("walk", 0.2)
	solo.position.x += dir * 456.0 * SOLO_SCALE * delta
	if signf(tx - solo.position.x) != dir:
		solo.position.x = tx
		walk_targets.pop_front()

# ---------------------------------------------------------------- ควบคุมเอง
func _manual(delta: float) -> void:
	var dir := 0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		dir -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		dir += 1
	var busy: bool = solo.anim.current_animation in ["jump", "punch"] and solo.anim.current_animation_position < solo.anim.current_animation_length - 0.05 and manual_anim != solo.anim.current_animation
	if dir != 0 and not busy:
		solo.set_facing(dir)
		solo.play_anim("walk", 0.2)
		solo.position.x = clampf(solo.position.x + dir * 456.0 * SOLO_SCALE * delta, 120.0, 1160.0)
		pose_label.text = NAMES["walk"]
	elif not busy:
		solo.play_anim(manual_anim, 0.3)
		pose_label.text = NAMES[manual_anim]
	time_label.text = "MANUAL"

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k: int = event.keycode
	var keymap := {KEY_1: "idle", KEY_2: "walk", KEY_3: "jump", KEY_4: "punch", KEY_5: "die"}
	if k == KEY_ENTER:
		auto_mode = true
		_start_segment(0)
		return
	if k == KEY_B:
		_set_bones(not bones_on)
		return
	if k == KEY_G:
		auto_mode = false
		_show_gallery(not gallery.visible)
		return
	# ปุ่มอื่น ๆ = ควบคุมเอง
	if auto_mode:
		auto_mode = false
		_show_gallery(false)
		solo.position = Vector2(640, GROUND_Y)
		caption_label.text = "←/→ เดิน • Space กระโดด • J ต่อย • K ตาย • 1-5 เลือกท่า • B กระดูก • G แกลเลอรี • Enter เล่นอัตโนมัติ"
	_show_gallery(false)
	if keymap.has(k):
		manual_anim = keymap[k]
		solo.restart_anim(manual_anim, 0.15)
	elif k == KEY_SPACE:
		manual_anim = "idle"
		solo.restart_anim("jump", 0.1)
		pose_label.text = NAMES["jump"]
		await get_tree().create_timer(1.55).timeout
		if solo.anim.current_animation == "jump":
			solo.play_anim("idle", 0.2)
	elif k == KEY_K:
		manual_anim = "die"
		solo.restart_anim("die", 0.15)
	elif k == KEY_J or k == KEY_F:
		manual_anim = "idle"
		solo.restart_anim("punch", 0.1)
		pose_label.text = NAMES["punch"]
		await get_tree().create_timer(1.3).timeout
		if solo.anim.current_animation == "punch":
			solo.play_anim("idle", 0.25)

# ---------------------------------------------------------------- UI
func _lbl(t: String, size: int, bold := true, col := Color.WHITE, outline := 8) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", FONT_B if bold else FONT_R)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.1, 0.2))
	l.add_theme_constant_override("outline_size", outline)
	return l

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := VBoxContainer.new()
	title.position = Vector2(24, 12)
	root.add_child(title)
	title.add_child(_lbl("Lab 7 · 2D Skeleton Animation (Cutout)", 30, true, Color(1, 0.9, 0.95)))
	title.add_child(_lbl("ภูริชญา โมรา  •  673380636-9  •  AI3  •  Godot 4.7", 18, false))

	time_label = _lbl("", 16, false, Color(1, 1, 1, 0.9), 6)
	time_label.position = Vector2(1080, 18)
	root.add_child(time_label)

	pose_label = _lbl("", 44, true, Color(1, 0.95, 0.55), 10)
	pose_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pose_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pose_label.position.y = 92
	pose_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(pose_label)

	caption_label = _lbl("", 19, false, Color.WHITE, 7)
	caption_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	caption_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	caption_label.position.y = -16
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(caption_label)

	# ป้ายชื่อท่าในแกลเลอรี
	var anims := ["idle", "walk", "jump", "punch", "die"]
	for i in gallery.get_child_count():
		var c: Node2D = gallery.get_child(i)
		var l := _lbl(NAMES[anims[i]], 22, true, Color.WHITE, 7)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(240, 40)
		l.add_theme_font_size_override("font_size", 20)
		l.position = Vector2(c.position.x - 120, GROUND_Y + 10)
		root.add_child(l)
		gallery_labels.append(l)

var gallery_labels: Array = []

func _physics_process(_d: float) -> void:
	for l in gallery_labels:
		l.visible = gallery.visible

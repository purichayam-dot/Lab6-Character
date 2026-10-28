extends Node3D
# ฉาก Demo: แสดงตัวละครในท่าทางต่าง ๆ + โหมดเดินเล่นด้วยคีย์บอร์ด

const FONT := preload("res://Assets/Fonts/Kanit-Bold.ttf")
const FONT_R := preload("res://Assets/Fonts/Kanit-Regular.ttf")

const SHOWCASE := [
	["ยืนพัก (Idle)", "shooter/idle"],
	["เดิน (Walk)", "shooter/walk"],
	["วิ่ง (Run)", "shooter/run_067"],
	["วิ่งเร็ว (Sprint)", "melee/Sprint"],
	["กระโดด (Jump)", "shooter/jump"],
	["กลิ้งหลบ (Roll)", "melee/Roll"],
	["ฟันดาบ 1 (Slash)", "melee/Slash1"],
	["ฟันดาบ 2", "melee/Slash2"],
	["ฟันหมุนตัว (Heavy Spin)", "melee/HeavySpin"],
	["กระโดดโจมตี", "melee/LightJumpAttack"],
	["ต่อย (Punch)", "shooter/punch1"],
	["เตะ (Kick)", "shooter/kick1"],
	["ตั้งการ์ด (Guard)", "melee/Guarding"],
	["เล็งปืน (Aim Rifle)", "shooter/aim-rifle"],
	["ยิงปืน (Shoot)", "shooter/shoot-rifle-light"],
	["ขว้างระเบิด (Throw)", "shooter/throw-grenade-"],
	["ย่องเดิน (Sneak)", "shooter/sneak-walk"],
	["หมอบคลาน (Crawl)", "shooter/prone-crawl"],
	["ปีนบันได (Climb)", "melee/LadderClimbing"],
	["เปิดหีบ (Open Chest)", "melee/OpenChest"],
	["ดื่มยา (Use Potion)", "melee/UsePotion"],
	["บาดเจ็บ (Hurt)", "melee/Hurt1"],
	["ล้มลง (Die)", "melee/Die1"],
	["ยกมือยอมแพ้", "shooter/handsup-idle"],
]

@onready var player: CharacterBody3D = $Player
@onready var cam_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D

var current_label: Label
var mode_button: Button
var list_box: VBoxContainer
var side_panel: PanelContainer
var all_select: OptionButton
var hint: Label
var showcase_index := 0
var auto_play := true
var auto_timer := 0.0
var dragging := false
var zoom := 4.2

func _ready():
	_build_ui()
	_play_index(0)

func _process(delta):
	# กล้องตามตัวละคร
	cam_pivot.global_position = cam_pivot.global_position.lerp(player.global_position + Vector3(0, 1.0, 0), delta * 6.0)
	cam.position = cam.position.lerp(Vector3(0, 0.3, zoom), delta * 6.0)
	if not player.control_enabled and not dragging:
		cam_pivot.rotation.y += delta * 0.12
	player.cam_yaw = cam_pivot.rotation.y
	if auto_play and not player.control_enabled:
		auto_timer += delta
		var a: AnimationPlayer = player.anim
		var length: float = a.current_animation_length if a.current_animation != "" else 3.0
		if auto_timer > max(length, 2.5) + 0.6:
			_play_index((showcase_index + 1) % SHOWCASE.size())

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - 0.3, 1.8, 8.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + 0.3, 1.8, 8.0)
	elif event is InputEventMouseMotion and dragging:
		cam_pivot.rotation.y -= event.relative.x * 0.008
		cam_pivot.rotation.x = clamp(cam_pivot.rotation.x - event.relative.y * 0.005, -1.0, 0.3)
	elif event.is_action_pressed("toggle_mode"):
		_toggle_mode()

func _play_index(i: int):
	showcase_index = i
	auto_timer = 0.0
	player.play_showcase(SHOWCASE[i][1])
	current_label.text = "ท่า: " + SHOWCASE[i][0]

func _play_name(n: String):
	auto_timer = 0.0
	player.play_showcase(n)
	current_label.text = "ท่า: " + n

func _toggle_mode():
	player.control_enabled = not player.control_enabled
	mode_button.text = "โหมดโชว์ท่า" if player.control_enabled else "โหมดเดินเล่น (Tab)"
	side_panel.visible = not player.control_enabled
	hint.visible = player.control_enabled
	if player.control_enabled:
		player.play("shooter/idle")
		current_label.text = "โหมดเดินเล่น"
	else:
		player.global_position = Vector3(0, 0.05, 0)
		_play_index(showcase_index)

# ---------------------------------------------------------------- UI
func _lbl(t: String, size: int, bold := true, col := Color.WHITE) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_override("font", FONT if bold else FONT_R)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.2))
	l.add_theme_constant_override("outline_size", 8)
	return l

func _style(col: Color, r := 14) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(r)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

func _btn(t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_override("font", FONT_R)
	b.add_theme_font_size_override("font_size", 17)
	b.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.12), 10))
	b.add_theme_stylebox_override("hover", _style(Color(1, 0.55, 0.7, 0.6), 10))
	b.add_theme_stylebox_override("pressed", _style(Color(1, 0.45, 0.62, 0.9), 10))
	b.add_theme_stylebox_override("focus", _style(Color(1, 0.55, 0.7, 0.35), 10))
	b.pressed.connect(cb)
	return b

func _build_ui():
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)

	var title := VBoxContainer.new()
	title.position = Vector2(28, 18)
	root.add_child(title)
	title.add_child(_lbl("Lab 6 · ตัวละคร 3D จาก Blender + Mixamo", 30, true, Color(1, 0.85, 0.92)))
	title.add_child(_lbl("ภูริชญา โมรา  •  Godot 4.7  •  Mixamo BoneMap + MeleeLib / ShooterLib", 17, false))

	current_label = _lbl("", 34, true, Color(1, 0.95, 0.6))
	current_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	current_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	current_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	current_label.position.y = -70
	current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(current_label)

	# แผงรายการท่าทาง
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(Color(0.12, 0.07, 0.16, 0.72), 18))
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -300
	panel.offset_right = -16
	panel.offset_top = 16
	panel.offset_bottom = -16
	root.add_child(panel)
	side_panel = panel
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 8)
	panel.add_child(pv)
	pv.add_child(_lbl("ท่าทางตัวละคร", 22, true, Color(1, 0.8, 0.9)))
	var auto := CheckButton.new()
	auto.text = "เล่นต่อเนื่องอัตโนมัติ"
	auto.button_pressed = true
	auto.add_theme_font_override("font", FONT_R)
	auto.toggled.connect(func(v): auto_play = v)
	pv.add_child(auto)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pv.add_child(scroll)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list_box)
	for i in SHOWCASE.size():
		var idx := i
		list_box.add_child(_btn(SHOWCASE[i][0], func(): _play_index(idx)))
	pv.add_child(_lbl("ท่าทั้งหมดในไลบรารี:", 16, false))
	all_select = OptionButton.new()
	all_select.add_theme_font_override("font", FONT_R)
	all_select.fit_to_longest_item = false
	var all: PackedStringArray = player.get_all_animations()
	for n in all:
		all_select.add_item(n)
	all_select.item_selected.connect(func(i): _play_name(all_select.get_item_text(i)))
	pv.add_child(all_select)
	pv.add_child(_lbl("ทั้งหมด %d ท่า" % all.size(), 14, false, Color(1, 1, 1, 0.7)))

	mode_button = _btn("โหมดเดินเล่น (Tab)", _toggle_mode)
	mode_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_button.position = Vector2(28, 100)
	mode_button.custom_minimum_size = Vector2(230, 44)
	mode_button.add_theme_font_override("font", FONT)
	mode_button.add_theme_font_size_override("font_size", 19)
	mode_button.add_theme_stylebox_override("normal", _style(Color(0.9, 0.35, 0.55, 0.9), 22))
	root.add_child(mode_button)

	hint = _lbl("WASD เดิน • Shift วิ่ง • Space กระโดด • J ฟันดาบ • K ต่อย • L เตะ • Q กลิ้ง • ลากเมาส์หมุนกล้อง • ล้อเมาส์ซูม", 17, false)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position.y = -24
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.visible = false
	root.add_child(hint)
	var hint2 := _lbl("ลากเมาส์ = หมุนกล้อง • ล้อเมาส์ = ซูม • Tab = สลับโหมดเดินเล่น", 15, false, Color(1, 1, 1, 0.8))
	hint2.position = Vector2(28, 152)
	root.add_child(hint2)

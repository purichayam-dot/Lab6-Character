extends CharacterBody3D
# ตัวละครที่สร้างจาก Blender + โครงกระดูก Mixamo
# ใช้ Animation Library จาก Godot4-OpenAnimationLibraries (MeleeLib + ShooterLib)
# ผ่าน Mixamo BoneMap (retarget เป็น SkeletonProfileHumanoid)

const MELEE := preload("res://Assets/Animations/MeleeLib.res")
const SHOOTER := preload("res://Assets/Animations/ShooterLib.res")

@export var walk_speed := 2.0
@export var run_speed := 5.0
@export var jump_force := 6.0

@onready var model: Node3D = $Model
@onready var anim: AnimationPlayer = $Model/AnimationPlayer

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var control_enabled := false   # false = โหมดโชว์ท่า, true = โหมดเดินเล่น
var action_lock := 0.0         # ระหว่างเล่นท่าโจมตีจะไม่ถูกท่าเดินแทรก
var cam_yaw := 0.0

# ท่าที่ใช้ตอนเดินเล่น (แบบไม่มี root motion)
const A_IDLE := "shooter/idle"
const A_WALK := "shooter/walk"
const A_RUN := "shooter/run_067"
const A_JUMP := "shooter/jump"
const A_FALL := "shooter/fall"
const ACTIONS := {
	"attack_1": "melee/Slash1",
	"attack_2": "shooter/punch1",
	"attack_3": "shooter/kick1",
	"roll": "melee/Roll",
}

func _ready():
	anim.add_animation_library("melee", MELEE)
	anim.add_animation_library("shooter", SHOOTER)
	for lib in ["melee", "shooter"]:
		for n in anim.get_animation_library(lib).get_animation_list():
			var a := anim.get_animation(lib + "/" + n)
			if n in ["idle", "walk", "run_067", "fall", "LightIdle", "HeavyIdle", "Guarding", "crouch-idle", "sneak-idle", "prone-idle", "Sprint", "LightWalking", "LightRunning", "LadderClimbing", "dead-idle", "handsup-idle", "idle-rifle", "idle-pistol", "crouch-walk", "prone-crawl", "sneak-walk", "aim-rifle"]:
				a.loop_mode = Animation.LOOP_LINEAR
	play(A_IDLE)

func play(name: String, blend := 0.2):
	if anim.has_animation(name) and anim.current_animation != name:
		anim.play(name, blend)

func play_showcase(name: String):
	action_lock = 0.0
	velocity = Vector3.ZERO
	anim.play(name, 0.25)
	anim.seek(0.0, true)

func get_all_animations() -> PackedStringArray:
	var out := PackedStringArray()
	for lib in ["melee", "shooter"]:
		for n in anim.get_animation_library(lib).get_animation_list():
			if not String(n).begins_with("root-") and not String(n).contains("|"):
				out.append(lib + "/" + n)
	return out

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	if not control_enabled:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	action_lock = max(action_lock - delta, 0.0)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(input.x, 0, input.y).rotated(Vector3.UP, cam_yaw)
	var running := Input.is_action_pressed("run")
	var speed := run_speed if running else walk_speed
	if action_lock > 0.0:
		speed *= 0.2
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	if is_on_floor() and Input.is_action_just_pressed("jump") and action_lock <= 0.0:
		velocity.y = jump_force
		play(A_JUMP, 0.1)

	for act in ACTIONS:
		if Input.is_action_just_pressed(act) and is_on_floor():
			var a: String = ACTIONS[act]
			anim.play(a, 0.1)
			action_lock = anim.get_animation(a).length * 0.9
			if act == "roll":
				velocity += model.global_basis.z * 4.0

	move_and_slide()

	if dir.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y, atan2(dir.x, dir.z), delta * 10.0)

	if action_lock > 0.0:
		return
	if not is_on_floor():
		if velocity.y < -1.0:
			play(A_FALL, 0.3)
	elif dir.length() > 0.1:
		play(A_RUN if running else A_WALK, 0.2)
	else:
		play(A_IDLE, 0.3)

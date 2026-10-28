extends Node2D
## ตัวละคร 2D แบบ Cutout / Skeletal Animation
## Polygon2D (ชิ้นส่วนร่างกาย) ผูกกับ Skeleton2D + Bone2D
## ท่าทาง: idle (ยืน), walk (เดิน), jump (กระโดด), punch (ต่อย)

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var hip: Bone2D = $Skeleton/hip
@onready var shadow: Polygon2D = $Shadow
@onready var bones_view: Node2D = $BoneOverlay

var rest_hip_y := 0.0

func _ready() -> void:
	rest_hip_y = hip.rest.origin.y
	if not anim.is_playing():
		anim.play("idle")

func play_anim(n: String, blend := 0.25) -> void:
	if anim.current_animation != n:
		anim.play(n, blend)

func restart_anim(n: String, blend := 0.2) -> void:
	anim.play(n, blend)
	anim.seek(0.0, true)

func show_bones(on: bool) -> void:
	bones_view.visible = on

func set_facing(dir: int) -> void:
	scale.x = abs(scale.x) * (1 if dir >= 0 else -1)

func _process(_d: float) -> void:
	# เงาเล็กลงเมื่อกระโดดสูงขึ้น
	var lift: float = clamp((rest_hip_y - hip.position.y) / 200.0, 0.0, 1.0)
	shadow.scale = Vector2.ONE * lerp(1.0, 0.55, lift)
	shadow.modulate.a = lerp(0.35, 0.15, lift)

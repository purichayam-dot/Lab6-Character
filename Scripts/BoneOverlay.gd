extends Node2D
## วาดโครงกระดูก (Bone2D) ทับตัวละคร เพื่อแสดงการทำงานของ Skeleton2D

@export var skeleton_path: NodePath = ^"../Skeleton"
var skel: Skeleton2D

func _ready() -> void:
	skel = get_node(skeleton_path)

func _process(_d: float) -> void:
	if visible:
		queue_redraw()

func _draw() -> void:
	if skel == null:
		return
	for i in skel.get_bone_count():
		var b: Bone2D = skel.get_bone(i)
		var p := to_local(b.global_position)
		var tip := to_local(b.global_transform * (Vector2.from_angle(b.get_bone_angle()) * b.get_length()))
		var d := tip - p
		var n := Vector2(-d.y, d.x).normalized() * minf(14.0, d.length() * 0.18)
		var pts := PackedVector2Array([p, p + d * 0.2 + n, tip, p + d * 0.2 - n])
		draw_colored_polygon(pts, Color(1.0, 0.85, 0.2, 0.55))
		draw_polyline(pts + PackedVector2Array([p]), Color(0.35, 0.2, 0.05, 0.9), 3.0)
		draw_circle(p, 9.0, Color(1, 1, 1, 0.95))
		draw_circle(p, 5.0, Color(0.9, 0.3, 0.45))

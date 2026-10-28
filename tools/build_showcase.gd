extends SceneTree
func _init() -> void:
	process_frame.connect(_build, CONNECT_ONE_SHOT)
func _build() -> void:
	var CH: PackedScene = load("res://Scenes/Character.tscn")
	var root := Node2D.new()
	root.name = "Showcase"
	root.set_script(load("res://Scripts/Showcase.gd"))
	var bg := Sprite2D.new()
	bg.name = "Background"
	bg.texture = load("res://Assets/Art/background.png")
	bg.centered = false
	root.add_child(bg)
	var gal := Node2D.new()
	gal.name = "Gallery"
	root.add_child(gal)
	var names := ["Stand", "Walk", "Jump", "Punch", "Die"]
	for i in 5:
		var c: Node2D = CH.instantiate()
		c.name = names[i]
		c.position = Vector2(1150 if i == 4 else 115 + i * 240, 640)
		c.scale = Vector2(0.38, 0.38)
		gal.add_child(c)
	var solo: Node2D = CH.instantiate()
	solo.name = "Solo"
	solo.position = Vector2(640, 640)
	solo.scale = Vector2(0.62, 0.62)
	root.add_child(solo)
	for n in [bg, gal, solo]:
		n.owner = root
	for c in gal.get_children():
		c.owner = root
	var ps := PackedScene.new()
	print("pack ", ps.pack(root), " save ", ResourceSaver.save(ps, "res://Scenes/Showcase.tscn"))
	quit()

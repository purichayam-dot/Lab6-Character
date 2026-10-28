extends SceneTree
func _init():
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run():
	var r := Node3D.new(); root.add_child(r)
	var env := WorldEnvironment.new(); var e := Environment.new(); e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.75,0.8,0.9); e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color.WHITE; e.ambient_light_energy = 0.6; env.environment = e; r.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 25, 0); r.add_child(sun)
	var melee: AnimationLibrary = load("res://Assets/Animations/MeleeLib.res")
	var shooter: AnimationLibrary = load("res://Assets/Animations/ShooterLib.res")
	var names: Array = OS.get_cmdline_user_args()[0].split(",")
	var t := float(OS.get_cmdline_user_args()[1])
	for i in names.size():
		var c: Node3D = load("res://Assets/Character/Purichaya.glb").instantiate()
		c.position = Vector3((i % 4) * 1.5 - 2.25, 0 if i < 4 else -2.1, 0)
		r.add_child(c)
		var ap: AnimationPlayer = c.get_node("AnimationPlayer")
		ap.add_animation_library("melee", melee)
		ap.add_animation_library("shooter", shooter)
		ap.play(names[i])
		ap.seek(t, true)
		ap.pause()
		var l := Label3D.new(); l.text = names[i]; l.position = c.position + Vector3(0, -0.15, 0.5); l.font_size = 36; r.add_child(l)
	var cam := Camera3D.new(); r.add_child(cam); cam.look_at_from_position(Vector3(0, 0.0, 6.2), Vector3(0, -0.15, 0)); cam.current = true
	for k in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/home/claude/shots/lab6_anims.png")
	quit()

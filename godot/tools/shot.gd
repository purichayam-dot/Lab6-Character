extends SceneTree
func _init():
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run():
	var a := OS.get_cmdline_user_args()
	change_scene_to_file("res://Scenes/Demo.tscn")
	for i in 3: await process_frame
	var demo = current_scene
	for i in range(1, a.size()):
		var p := a[i].split(",")
		if p[1] == "walk":
			demo._toggle_mode()
			Input.action_press("move_forward"); Input.action_press("run")
			await create_timer(1.0).timeout
			Input.action_release("move_forward"); Input.action_release("run")
			Input.action_press("attack_1")
			await physics_frame
			Input.action_release("attack_1")
			await create_timer(0.35).timeout
		else:
			demo._play_index(int(p[1]))
			demo.auto_play = false
			await create_timer(float(p[2])).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(a[0] + "/" + p[0] + ".png")
	quit()

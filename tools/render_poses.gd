extends SceneTree
## เรนเดอร์ภาพท่าหลัก (key poses) สำหรับใส่สไลด์
const SETS := {
	"poses4": [["idle", 1.2, "ยืน"], ["walk", 0.0, "เดิน"], ["jump", 0.72, "กระโดด"], ["punch", 0.24, "ต่อย"]],
	"poses5": [["idle", 1.2, "ยืน"], ["walk", 0.0, "เดิน"], ["jump", 0.72, "กระโดด"], ["punch", 0.24, "ต่อสู้"], ["die", 2.0, "ตาย"]],
	"die_keys": [["die", 0.15, "โดนโจมตี"], ["die", 0.45, "เข่าทรุด"], ["die", 0.8, "ล้ม"], ["die", 2.0, "นิ่ง"]],
	"walk_keys": [["walk", 0.0, "Contact"], ["walk", 0.25, "Passing"], ["walk", 0.5, "Contact"], ["walk", 0.75, "Passing"]],
	"jump_keys": [["jump", 0.3, "ย่อตัว"], ["jump", 0.45, "ส่งตัว"], ["jump", 0.72, "ลอยสูงสุด"], ["jump", 0.98, "ตกลง"], ["jump", 1.1, "ลงพื้น"]],
	"punch_keys": [["punch", 0.0, "การ์ด"], ["punch", 0.12, "ง้าง"], ["punch", 0.24, "หมัดหน้า"], ["punch", 0.88, "หมัดหลัง"]],
}
func _init() -> void:
	process_frame.connect(_run, CONNECT_ONE_SHOT)
func _run() -> void:
	var CH: PackedScene = load("res://Scenes/Character.tscn")
	var font: Font = load("res://Assets/Fonts/Kanit-Bold.ttf")
	for set_name in SETS:
		var items: Array = SETS[set_name]
		var holder := Node2D.new()
		root.add_child(holder)
		var bg := ColorRect.new()
		bg.color = Color("fff4f8")
		bg.size = Vector2(1280, 720)
		holder.add_child(bg)
		var n := items.size()
		var sc := 0.62 if n == 4 else 0.5
		for i in n:
			var c: Node2D = CH.instantiate()
			holder.add_child(c)
			var px := 1280.0 * (i + 0.5) / n
			if set_name == "poses5":
				px = [130.0, 340.0, 550.0, 760.0, 1080.0][i]
			if set_name == "die_keys":
				px = [150.0, 420.0, 720.0, 1070.0][i]
			c.position = Vector2(px, 600)
			c.scale = Vector2(sc, sc)
			var ap: AnimationPlayer = c.get_node("AnimationPlayer")
			ap.play(items[i][0])
			ap.seek(items[i][1], true)
			ap.pause()
			var l := Label.new()
			l.text = items[i][2]
			l.add_theme_font_override("font", font)
			l.add_theme_font_size_override("font_size", 34)
			l.add_theme_color_override("font_color", Color("6b2346"))
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.size = Vector2(1280.0 / n, 50)
			l.position = Vector2(c.position.x - 640.0 / n, 640)
			holder.add_child(l)
		for f in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://../video/%s.png" % set_name)
		holder.queue_free()
		await process_frame
	quit()

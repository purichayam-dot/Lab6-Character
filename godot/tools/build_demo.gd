extends SceneTree
func own(n: Node, root: Node):
	if n != root: n.owner = root
	if n.scene_file_path != "" and n != root: return
	for c in n.get_children(): own(c, root)
func mi(parent: Node, mesh: Mesh, col: Color, pos: Vector3, name: String) -> MeshInstance3D:
	var m := MeshInstance3D.new(); m.mesh = mesh; m.name = name
	var mat := StandardMaterial3D.new(); mat.albedo_color = col; mat.roughness = 0.8
	m.material_override = mat; parent.add_child(m); m.position = pos; return m
func cyl(t: float, b: float, h: float, seg: int) -> CylinderMesh:
	var c := CylinderMesh.new(); c.top_radius = t; c.bottom_radius = b; c.height = h; c.radial_segments = seg; c.rings = 0; return c
func inst(path: String, parent: Node, pos: Vector3, s := 1.0, ry := 0.0, name := "") -> Node3D:
	var n: Node3D = (load(path) as PackedScene).instantiate()
	if name != "": n.name = name
	parent.add_child(n); n.position = pos; n.scale = Vector3.ONE * s; n.rotation_degrees.y = ry; return n
func _init():
	process_frame.connect(_go, CONNECT_ONE_SHOT)
func _go():
	var root := Node3D.new(); root.name = "Demo"
	root.set_script(load("res://Scripts/Demo.gd"))
	var we := WorldEnvironment.new(); we.name = "WorldEnvironment"
	var env := Environment.new(); var sky := Sky.new(); var psm := ProceduralSkyMaterial.new()
	psm.sky_top_color = Color(0.42, 0.55, 0.92); psm.sky_horizon_color = Color(1.0, 0.8, 0.85)
	psm.ground_horizon_color = Color(1.0, 0.8, 0.85); psm.ground_bottom_color = Color(0.5, 0.45, 0.6)
	sky.sky_material = psm; env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.glow_enabled = true; env.glow_intensity = 0.5
	env.fog_enabled = true; env.fog_light_color = Color(1, 0.85, 0.9); env.fog_density = 0.004
	env.ssao_enabled = true
	we.environment = env; root.add_child(we)
	var sun := DirectionalLight3D.new(); sun.name = "Sun"; sun.shadow_enabled = true; sun.light_energy = 1.1
	sun.light_color = Color(1, 0.95, 0.88); root.add_child(sun); sun.rotation_degrees = Vector3(-50, -30, 0)
	# เวที
	var stage := Node3D.new(); stage.name = "Stage"; root.add_child(stage)
	mi(stage, cyl(4.0, 4.2, 0.3, 24), Color(0.98, 0.78, 0.86), Vector3(0, -0.15, 0), "StageTop")
	mi(stage, cyl(4.2, 3.6, 0.6, 24), Color(0.55, 0.42, 0.6), Vector3(0, -0.6, 0), "StageBase")
	mi(stage, cyl(3.2, 3.2, 0.02, 24), Color(1, 0.92, 0.95), Vector3(0, 0.005, 0), "Ring")
	mi(stage, cyl(2.9, 2.9, 0.03, 24), Color(0.98, 0.78, 0.86), Vector3(0, 0.01, 0), "RingInner")
	var ground := mi(stage, cyl(60, 60, 0.2, 32), Color(0.6, 0.82, 0.55), Vector3(0, -0.95, 0), "Ground")
	var body := StaticBody3D.new(); body.name = "Floor"; stage.add_child(body)
	var cs := CollisionShape3D.new(); var bs := BoxShape3D.new(); bs.size = Vector3(120, 1, 120); cs.shape = bs; cs.position = Vector3(0, -0.5, 0); body.add_child(cs)
	inst("res://Assets/Props/torii.glb", stage, Vector3(0, 0, -3.2), 0.8, 0, "Torii")
	for t in [[Vector3(-6, -0.85, -4), 30, 0.05], [Vector3(6.5, -0.85, -3), 140, 0.045], [Vector3(-8, -0.85, 4), 220, 0.05], [Vector3(8, -0.85, 5), 300, 0.04], [Vector3(0, -0.85, -10), 90, 0.06]]:
		inst("res://Assets/Props/sakura_tree.glb", stage, t[0], t[2], t[1])
	for b in [Vector3(-3.3, 0, 1.6), Vector3(3.4, 0, 1.2), Vector3(-2.6, 0, -2.4), Vector3(2.8, 0, -2.2)]:
		inst("res://Assets/Props/bush.glb", stage, b, 0.9, randf() * 360)
	inst("res://Assets/Props/stone_lamp.glb", stage, Vector3(-3.4, 2.19 * 0.5, -0.4), 0.5)
	inst("res://Assets/Props/stone_lamp.glb", stage, Vector3(3.4, 2.19 * 0.5, -0.4), 0.5)
	# ผู้เล่น
	var p := CharacterBody3D.new(); p.name = "Player"; p.set_script(load("res://Scripts/PlayerCharacter.gd")); root.add_child(p)
	p.position = Vector3(0, 0.05, 0)
	var pc := CollisionShape3D.new(); var cap := CapsuleShape3D.new(); cap.radius = 0.3; cap.height = 1.8; pc.shape = cap; pc.position = Vector3(0, 0.9, 0); p.add_child(pc)
	inst("res://Assets/Character/Purichaya.glb", p, Vector3.ZERO, 1.0, 0, "Model")
	# กล้อง
	var pivot := Node3D.new(); pivot.name = "CameraPivot"; root.add_child(pivot); pivot.position = Vector3(0, 1.0, 0); pivot.rotation_degrees = Vector3(-12, 0, 0)
	var cam := Camera3D.new(); cam.name = "Camera3D"; cam.fov = 50; pivot.add_child(cam); cam.position = Vector3(0, 0.3, 4.2); cam.current = true
	# กลีบซากุระ
	var pt := CPUParticles3D.new(); pt.name = "Petals"; root.add_child(pt); pt.position = Vector3(0, 7, 0)
	var q := QuadMesh.new(); q.size = Vector2(0.12, 0.12); var qm := StandardMaterial3D.new(); qm.albedo_color = Color(1, 0.75, 0.85); qm.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; qm.cull_mode = BaseMaterial3D.CULL_DISABLED; q.material = qm
	pt.mesh = q; pt.amount = 120; pt.lifetime = 9.0; pt.preprocess = 9.0; pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX; pt.emission_box_extents = Vector3(9, 1, 9)
	pt.gravity = Vector3(0.2, -0.9, 0); pt.angle_max = 360; pt.angular_velocity_min = -90; pt.angular_velocity_max = 90
	own(root, root)
	var ps := PackedScene.new(); ps.pack(root)
	print("save ", ResourceSaver.save(ps, "res://Scenes/Demo.tscn"))
	quit()

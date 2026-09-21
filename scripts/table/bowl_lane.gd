class_name BowlLane
extends Node3D

const Pins = preload("res://scripts/bowl/bowl_pins.gd")

const PIN_Z := 11.55
const LANE_W := 1.05
const DECK_Y := 0.0
const BALL_R := 0.108

var pins: Array[RigidBody3D] = []
var pinsetter: MeshInstance3D


func _ready() -> void:
	_room()
	_lane()
	_markings()
	_gutters()
	_pit()
	_pinsetter()
	reset_pins([])


func reset_pins(keep_standing: Array) -> void:
	for p in pins:
		if is_instance_valid(p):
			p.queue_free()
	pins.clear()
	var spots := Pins.spots(PIN_Z, Pins.PIN_HEIGHT * 0.5)
	for i in 10:
		if keep_standing.size() == 10 and not bool(keep_standing[i]):
			continue
		var body := _make_pin(i)
		body.position = spots[i]
		add_child(body)
		pins.append(body)


func standing_mask() -> Array:
	var mask: Array = []
	for _i in 10:
		mask.append(false)
	for p in pins:
		if not is_instance_valid(p):
			continue
		var i := int(p.get_meta("pin_index"))
		if Pins.is_standing(p.global_position, p.global_transform.basis.y, DECK_Y, PIN_Z):
			mask[i] = true
	return mask


func downed_count(before: Array) -> int:
	var after := standing_mask()
	var n := 0
	for i in 10:
		if bool(before[i]) and not bool(after[i]):
			n += 1
	return n


func clamp_bodies() -> void:
	for p in pins:
		if not is_instance_valid(p):
			continue
		if p.linear_velocity.length() > 14.0:
			p.linear_velocity = p.linear_velocity.limit_length(14.0)
		if p.angular_velocity.length() > 28.0:
			p.angular_velocity = p.angular_velocity.limit_length(28.0)
		if p.global_position.y < -0.6 or is_nan(p.global_position.x):
			p.freeze = true
			p.global_position = Vector3(0.0, 0.12, PIN_Z + 1.6)


func settled(ball: RigidBody3D) -> bool:
	if ball and is_instance_valid(ball) and ball.linear_velocity.length() > 0.16:
		return false
	for p in pins:
		if not is_instance_valid(p) or p.freeze:
			continue
		if p.linear_velocity.length() > 0.14 or p.angular_velocity.length() > 0.35:
			return false
	return true


func _make_pin(i: int) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.mass = 1.55
	body.continuous_cd = true
	body.linear_damp = 0.55
	body.angular_damp = 0.85
	body.can_sleep = true
	body.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	body.center_of_mass = Vector3(0, -0.05, 0)
	var mesh_i := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.032
	cyl.bottom_radius = 0.055
	cyl.height = Pins.PIN_HEIGHT
	cyl.radial_segments = 12
	mesh_i.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.93, 0.9, 0.84)
	mat.roughness = 0.28
	mat.metallic = 0.05
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	var neck := MeshInstance3D.new()
	var band := CylinderMesh.new()
	band.top_radius = 0.036
	band.bottom_radius = 0.036
	band.height = 0.03
	neck.mesh = band
	neck.position = Vector3(0, 0.06, 0)
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(0.72, 0.12, 0.16)
	red.roughness = 0.4
	neck.material_override = red
	body.add_child(neck)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.055
	cap.height = Pins.PIN_HEIGHT
	col.shape = cap
	body.add_child(col)
	var phys := PhysicsMaterial.new()
	phys.friction = 0.28
	phys.bounce = 0.18
	body.physics_material_override = phys
	body.set_meta("pin_index", i)
	return body


func make_ball() -> RigidBody3D:
	var ball := RigidBody3D.new()
	ball.mass = 7.1
	ball.continuous_cd = true
	ball.linear_damp = 0.18
	ball.angular_damp = 0.22
	ball.can_sleep = true
	var mesh_i := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = BALL_R
	sph.height = BALL_R * 2.0
	mesh_i.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.16, 0.22)
	mat.roughness = 0.22
	mat.metallic = 0.35
	mesh_i.material_override = mat
	ball.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = BALL_R
	col.shape = sh
	ball.add_child(col)
	var phys := PhysicsMaterial.new()
	phys.friction = 0.22
	phys.bounce = 0.12
	ball.physics_material_override = phys
	return ball


func _room() -> void:
	var env_n := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.38, 0.36, 0.34)
	env.ambient_light_energy = 0.95
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.glow_enabled = false
	env_n.environment = env
	add_child(env_n)


func _lane() -> void:
	_static_box(Vector3(LANE_W, 0.12, 13.4), Vector3(0, -0.06, 6.4), Color(0.55, 0.32, 0.14), 0.42, 0.06)
	for i in 7:
		var board := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.138, 0.003, 13.15)
		board.mesh = box
		board.position = Vector3(-0.42 + i * 0.14, 0.003, 6.4)
		var mat := StandardMaterial3D.new()
		var shade := 0.07 if i % 2 == 0 else 0.0
		mat.albedo_color = Color(0.5 - shade, 0.3 - shade * 0.4, 0.13)
		mat.roughness = 0.18
		mat.metallic = 0.08
		board.material_override = mat
		add_child(board)
	_static_box(Vector3(6.4, 0.24, 18.0), Vector3(0, -0.28, 6.5), Color(0.06, 0.06, 0.07), 0.92, 0.0)


func _markings() -> void:
	for x in [-0.28, 0.0, 0.28]:
		var arrow := MeshInstance3D.new()
		var prism := PrismMesh.new()
		prism.size = Vector3(0.07, 0.09, 0.004)
		arrow.mesh = prism
		arrow.rotation_degrees = Vector3(-90, 0, 0)
		arrow.position = Vector3(x, 0.006, 4.15)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18, 0.12, 0.08)
		mat.roughness = 0.55
		arrow.material_override = mat
		add_child(arrow)
	for x in [-0.42, -0.21, 0.0, 0.21, 0.42]:
		var dot := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.012
		cyl.bottom_radius = 0.012
		cyl.height = 0.004
		dot.mesh = cyl
		dot.position = Vector3(x, 0.005, 2.2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.16, 0.1, 0.07)
		dot.material_override = mat
		add_child(dot)


func _gutters() -> void:
	_static_box(Vector3(0.26, 0.08, 13.0), Vector3(-(LANE_W * 0.5 + 0.16), -0.055, 6.3), Color(0.08, 0.09, 0.11), 0.55, 0.35)
	_static_box(Vector3(0.26, 0.08, 13.0), Vector3(LANE_W * 0.5 + 0.16, -0.055, 6.3), Color(0.08, 0.09, 0.11), 0.55, 0.35)
	_static_box(Vector3(0.07, 0.22, 13.0), Vector3(-(LANE_W * 0.5 + 0.01), 0.08, 6.3), Color(0.72, 0.78, 0.84), 0.28, 0.62)
	_static_box(Vector3(0.07, 0.22, 13.0), Vector3(LANE_W * 0.5 + 0.01, 0.08, 6.3), Color(0.72, 0.78, 0.84), 0.28, 0.62)
	_static_box(Vector3(0.1, 0.42, 13.0), Vector3(-(LANE_W * 0.5 + 0.32), 0.14, 6.3), Color(0.16, 0.18, 0.22), 0.4, 0.45)
	_static_box(Vector3(0.1, 0.42, 13.0), Vector3(LANE_W * 0.5 + 0.32, 0.14, 6.3), Color(0.16, 0.18, 0.22), 0.4, 0.45)


func _pit() -> void:
	_static_box(Vector3(1.8, 0.9, 0.12), Vector3(0, 0.35, PIN_Z + 1.55), Color(0.08, 0.07, 0.08), 0.8, 0.05)
	_static_box(Vector3(1.8, 0.08, 1.4), Vector3(0, -0.02, PIN_Z + 0.95), Color(0.1, 0.09, 0.1), 0.85, 0.0)


func _pinsetter() -> void:
	pinsetter = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.35, 0.08, 0.22)
	pinsetter.mesh = box
	pinsetter.position = Vector3(0, 1.15, PIN_Z + 0.35)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.2, 0.24)
	mat.metallic = 0.55
	mat.roughness = 0.3
	pinsetter.material_override = mat
	add_child(pinsetter)


func _static_box(size: Vector3, pos: Vector3, color: Color, rough: float, metal: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mesh_i := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_i.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = metal
	mesh_i.material_override = mat
	body.add_child(mesh_i)
	var col := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	col.shape = sh
	body.add_child(col)
	var phys := PhysicsMaterial.new()
	phys.friction = 0.24
	phys.bounce = 0.05
	body.physics_material_override = phys
	add_child(body)

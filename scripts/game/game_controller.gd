class_name BowlGameController
extends Node3D

const Types = preload("res://scripts/bowl/bowl_types.gd")
const Rules = preload("res://scripts/bowl/bowl_engine.gd")
const Pins = preload("res://scripts/bowl/bowl_pins.gd")

var engine = Rules.new()
var lane: BowlLane
var camera: Camera3D
var ui: BowlHUD
var ball: RigidBody3D
var _charging := false
var _charge := 0.45
var _busy := false
var _aim := 0.0
var _hook := 0.0
var _stats: Dictionary = {}
var _before: Array = []
var _wait := 0.0
var _quiet := 0.0
var _follow := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stats = StatsStore.load_stats()
	engine.reset(GameSession.mode)
	_world()
	ui = BowlHUD.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(ui)
	ui.setup(engine)
	ui.throw_requested.connect(_throw)
	ui.pause_requested.connect(_toggle_pause)
	ui.restart_requested.connect(_restart)
	ui.settings_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")
	)
	ui.menu_requested.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
	)
	ui.quit_requested.connect(func(): get_tree().quit())
	_before = lane.standing_mask()
	_handle_cli()


func _world() -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 18, 0)
	key.light_energy = 1.45
	key.shadow_enabled = SettingsStore.quality_shadows()
	add_child(key)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 2.6, 4.2)
	fill.light_energy = 2.1
	fill.omni_range = 16.0
	fill.light_color = Color(1.0, 0.92, 0.82)
	add_child(fill)
	var pin_light := SpotLight3D.new()
	pin_light.position = Vector3(0.0, 3.4, 9.2)
	pin_light.light_energy = 4.2
	pin_light.spot_range = 12.0
	pin_light.spot_angle = 42.0
	pin_light.light_color = Color(1.0, 0.95, 0.88)
	add_child(pin_light)
	pin_light.look_at(Vector3(0, 0.2, BowlLane.PIN_Z))
	var approach := OmniLight3D.new()
	approach.position = Vector3(0, 1.8, 1.2)
	approach.light_energy = 1.6
	approach.omni_range = 6.0
	add_child(approach)
	lane = BowlLane.new()
	add_child(lane)
	camera = Camera3D.new()
	camera.fov = 40
	camera.position = Vector3(0.0, 1.22, 0.35)
	add_child(camera)
	camera.look_at(Vector3(0, 0.28, 8.6))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		return
	if get_tree().paused or _busy or engine.phase == Types.Phase.OVER:
		return
	if _ai_turn():
		return
	if event is InputEventMouseMotion:
		var w := get_viewport().get_visible_rect().size.x
		_aim = clampf(((event.position.x / w) - 0.5) * 0.9, -0.42, 0.42)
		_hook = clampf(((event.position.y / get_viewport().get_visible_rect().size.y) - 0.5) * -1.4, -1.0, 1.0)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_charging = true
				_charge = 0.28
			elif _charging:
				_charging = false
				_throw()


func _process(dt: float) -> void:
	if ui == null or lane == null:
		return
	if get_tree().paused:
		return
	if _charging:
		_charge = minf(_charge + dt * 0.95 * SettingsStore.shot_sensitivity, 1.0)
		ui.set_power(_charge)
	if _busy:
		_wait += dt
		lane.clamp_bodies()
		if ball and is_instance_valid(ball):
			if ball.linear_velocity.length() > 16.0:
				ball.linear_velocity = ball.linear_velocity.limit_length(16.0)
			if ball.global_position.y < -0.8 or is_nan(ball.global_position.x):
				ball.freeze = true
				ball.global_position = Vector3(0, 0.12, BowlLane.PIN_Z + 1.2)
			if _follow:
				var t := ball.global_position + Vector3(0, 1.15, -2.4)
				camera.global_position = camera.global_position.lerp(t, 0.12)
				camera.look_at(ball.global_position + Vector3(0, 0.1, 1.6))
		if lane.settled(ball):
			_quiet += dt
		else:
			_quiet = 0.0
		if _quiet > 0.42 or _wait > 6.8:
			_resolve()
	elif _ai_turn() and engine.phase != Types.Phase.OVER:
		_ai_roll()
	ui.refresh()


func _throw() -> void:
	if _busy or engine.phase == Types.Phase.OVER:
		return
	if _ai_turn():
		return
	_launch(_aim, _charge, _hook)
	_charge = 0.45
	ui.set_power(_charge)


func _ai_turn() -> bool:
	if engine.mode != Types.Mode.AI_MATCH:
		return false
	return engine.current == 1


func _ai_roll() -> void:
	var spread := 0.28
	match SettingsStore.ai_difficulty:
		"easy":
			spread = 0.34
		"hard":
			spread = 0.1
		_:
			spread = 0.2
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	_launch(rng.randfn(0.0, spread), clampf(rng.randfn(0.78, 0.1), 0.4, 1.0), rng.randfn(0.0, spread))


func _launch(aim: float, power: float, hook: float) -> void:
	if _busy:
		return
	_busy = true
	_wait = 0.0
	_quiet = 0.0
	_follow = true
	_before = lane.standing_mask()
	if ball and is_instance_valid(ball):
		ball.queue_free()
	ball = lane.make_ball()
	ball.position = Vector3(clampf(aim * 0.38, -0.4, 0.4), BowlLane.BALL_R + 0.01, 0.55)
	add_child(ball)
	var dir := Vector3(aim * 0.22, 0.01, 1.0).normalized()
	var impulse := 7.2 + power * 7.8
	ball.apply_central_impulse(dir * impulse)
	ball.apply_torque_impulse(Vector3(hook * 0.55, hook * 0.12, -power * 0.35))
	AudioManager.play("hit")


func _resolve() -> void:
	if not _busy:
		return
	_busy = false
	_follow = false
	var down := lane.downed_count(_before)
	var r: Dictionary = engine.add_roll(down)
	if str(engine.last_message) == "Strike":
		_stats["strikes"] = int(_stats.get("strikes", 0)) + 1
	if str(engine.last_message) == "Spare":
		_stats["spares"] = int(_stats.get("spares", 0)) + 1
	if ball and is_instance_valid(ball):
		ball.queue_free()
		ball = null
	if bool(r.get("frame_done", false)) or engine.phase == Types.Phase.OVER:
		lane.reset_pins([])
	else:
		lane.reset_pins(lane.standing_mask())
	_before = lane.standing_mask()
	camera.position = Vector3(0.0, 1.22, 0.35)
	camera.look_at(Vector3(0, 0.28, 8.6))
	if engine.phase == Types.Phase.OVER:
		_stats["games"] = int(_stats.get("games", 0)) + 1
		_stats["high_score"] = maxi(int(_stats.get("high_score", 0)), engine.score_of(0))
		if engine.winner == 0:
			_stats["wins"] = int(_stats.get("wins", 0)) + 1
		elif engine.winner == 1:
			_stats["losses"] = int(_stats.get("losses", 0)) + 1
		StatsStore.save_stats(_stats)
		AudioManager.play("win")
	else:
		AudioManager.play("goal")
	ui.refresh()


func _toggle_pause() -> void:
	ui.set_paused(not get_tree().paused)


func _restart() -> void:
	get_tree().paused = false
	engine.reset(GameSession.mode)
	_busy = false
	if ball and is_instance_valid(ball):
		ball.queue_free()
		ball = null
	lane.reset_pins([])
	_before = lane.standing_mask()
	ui.refresh()


func _handle_cli() -> void:
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.65).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("lane.png"))
			print("SCREENSHOT ", dir.path_join("lane.png"))
		get_tree().quit()
	if "--self-test" in args or GameSession.self_test:
		await get_tree().process_frame
		var e = Rules.new()
		e.reset(Types.Mode.SINGLE)
		for _i in 12:
			e.add_roll(10)
		var spots := Pins.spots(BowlLane.PIN_Z, Pins.PIN_HEIGHT * 0.5)
		var up := 0
		for v in lane.standing_mask():
			if v:
				up += 1
		var ok := e.score() == 300 and Pins.centers_legal(spots) and up == 10
		print("SELFTEST contact=true first=300 pocketed=300 foul= ok=%s" % ok)
		get_tree().quit(0 if ok else 1)

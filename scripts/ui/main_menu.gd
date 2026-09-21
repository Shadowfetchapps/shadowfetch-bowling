extends Control

const Types = preload("res://scripts/bowl/bowl_types.gd")


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.04, 0.05)
	add_child(bg)
	_preview()
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	box.offset_left = 56
	box.offset_right = 500
	box.offset_top = 72
	box.offset_bottom = -72
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	var k := Label.new()
	k.text = "TEN PIN"
	k.add_theme_color_override("font_color", ThemeFactory.accent())
	box.add_child(k)
	var title := Label.new()
	title.text = "Shadowfetch"
	title.add_theme_font_size_override("font_size", 46)
	box.add_child(title)
	var sub := Label.new()
	sub.text = "Bowling"
	sub.add_theme_font_size_override("font_size", 30)
	box.add_child(sub)
	var blurb := Label.new()
	blurb.text = "Regulation scoring. Hook, gutters, and a pinsetter that puts them back."
	blurb.add_theme_color_override("font_color", ThemeFactory.muted())
	blurb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(blurb)
	box.add_child(_btn("PLAY", func(): _start(Types.Mode.SINGLE)))
	box.add_child(_btn("GAME MODES", func(): get_tree().change_scene_to_file("res://scenes/menus/game_modes.tscn")))
	box.add_child(_btn("HOW TO PLAY", func(): get_tree().change_scene_to_file("res://scenes/menus/how_to_play.tscn")))
	box.add_child(_btn("STATISTICS", func(): get_tree().change_scene_to_file("res://scenes/menus/statistics.tscn")))
	box.add_child(_btn("SETTINGS", func(): get_tree().change_scene_to_file("res://scenes/menus/settings_menu.tscn")))
	box.add_child(_btn("QUIT", func(): get_tree().quit()))
	SettingsStore.apply_display()
	SettingsStore.apply_audio()
	var args := OS.get_cmdline_user_args()
	if "--screenshot" in args:
		await get_tree().create_timer(0.55).timeout
		var img := get_viewport().get_texture().get_image()
		if img:
			var dir := ProjectSettings.globalize_path("res://docs/screenshots")
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("menu.png"))
			print("SCREENSHOT ", dir.path_join("menu.png"))
		get_tree().quit()
	if "--self-test" in args:
		GameSession.reset_defaults()
		GameSession.self_test = true
		get_tree().call_deferred("change_scene_to_file", "res://scenes/main/game.tscn")


func _preview() -> void:
	var wrap := SubViewportContainer.new()
	wrap.set_anchors_preset(Control.PRESET_FULL_RECT)
	wrap.stretch = true
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	wrap.add_child(vp)
	add_child(wrap)
	var world := Node3D.new()
	vp.add_child(world)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.035, 0.04, 0.05)
	e.ambient_light_energy = 0.75
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.3, 0.32, 0.38)
	e.glow_enabled = false
	env.environment = e
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-42, 20, 0)
	light.light_energy = 1.55
	world.add_child(light)
	var spot := SpotLight3D.new()
	spot.position = Vector3(0.15, 3.2, 8.8)
	spot.light_energy = 4.4
	spot.spot_range = 14.0
	spot.spot_angle = 40.0
	spot.light_color = Color(1.0, 0.95, 0.86)
	world.add_child(spot)
	spot.look_at(Vector3(0, 0.2, 11.4))
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.4, 2.2, 10.2)
	fill.light_energy = 2.4
	fill.omni_range = 8.0
	world.add_child(fill)
	var t: Node3D = BowlLane.new()
	world.add_child(t)
	var cam := Camera3D.new()
	cam.fov = 36
	world.add_child(cam)
	var tw := create_tween().set_loops()
	tw.tween_method(func(a: float):
		if is_instance_valid(cam):
			cam.position = Vector3(1.15 + sin(a) * 0.08, 1.55, 8.35)
			cam.look_at(Vector3(0.0, 0.22, 11.55))
	, 0.0, TAU, 20.0)


func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size.y = 46
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		cb.call()
	)
	return b


func _start(mode) -> void:
	GameSession.reset_defaults()
	GameSession.mode = mode
	get_tree().change_scene_to_file("res://scenes/main/game.tscn")

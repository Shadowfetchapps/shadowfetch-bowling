extends Control

const Types = preload("res://scripts/bowl/bowl_types.gd")


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.04, 0.05)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.custom_minimum_size = Vector2(540, 520)
	box.offset_left = -270
	box.offset_right = 270
	box.offset_top = -260
	box.offset_bottom = 260
	add_child(box)
	var t := Label.new()
	t.text = "Game Modes"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 28)
	box.add_child(t)
	box.add_child(_m("SINGLE", "Ten frames. Chase 300.", Types.Mode.SINGLE))
	box.add_child(_m("PRACTICE", "Keep rolling. Frames reset.", Types.Mode.PRACTICE))
	box.add_child(_m("AI MATCH", "Same lane. Reaction, not cheat physics.", Types.Mode.AI_MATCH))
	box.add_child(_m("LOCAL", "Two players, one machine.", Types.Mode.LOCAL))
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size.y = 44
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	box.add_child(back)


func _m(title: String, blurb: String, mode) -> Button:
	var b := Button.new()
	b.text = "%s\n%s" % [title, blurb]
	b.custom_minimum_size.y = 68
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		AudioManager.play("ui")
		GameSession.reset_defaults()
		GameSession.mode = mode
		get_tree().change_scene_to_file("res://scenes/main/game.tscn")
	)
	return b

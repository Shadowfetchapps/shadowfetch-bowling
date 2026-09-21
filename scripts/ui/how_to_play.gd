extends Control


func _ready() -> void:
	theme = ThemeFactory.make()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.035, 0.04, 0.05)
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 70
	panel.offset_right = -70
	panel.offset_top = 40
	panel.offset_bottom = -40
	add_child(panel)
	var v := VBoxContainer.new()
	panel.add_child(v)
	var t := Label.new()
	t.text = "How to Play"
	t.add_theme_font_size_override("font_size", 28)
	v.add_child(t)
	var s := ScrollContainer.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(s)
	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text = """ROLL
Move the mouse left and right to aim. Move it up or down to add hook. Hold to charge, release to roll.

PINS
Ten pins, regulation triangle. A strike scores ten plus the next two rolls. A spare scores ten plus the next roll. Open frames add the pins you leave.

TENTH FRAME
A strike or spare in the tenth earns extra rolls. Three strikes is a turkey on the fill.

MODES
SINGLE — one player, ten frames.
PRACTICE — frames keep resetting.
AI MATCH — the house bowls the other lane with the same physics.
LOCAL — pass the mouse.

Esc pauses. Gutters score zero. Fictional scores only.
"""
	s.add_child(body)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn"))
	v.add_child(back)

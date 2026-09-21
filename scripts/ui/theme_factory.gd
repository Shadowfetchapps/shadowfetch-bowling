class_name ThemeFactory
extends RefCounted


static func make() -> Theme:
	var theme := Theme.new()
	var regular: FontFile = load("res://assets/fonts/Inter-Regular.ttf")
	var medium: FontFile = load("res://assets/fonts/Inter-Medium.ttf")
	if regular:
		theme.default_font = regular
	theme.default_font_size = 15
	var btn := StyleBoxFlat.new()
	btn.bg_color = Color(0.1, 0.12, 0.16, 0.96)
	btn.border_color = Color(0.62, 0.72, 0.82, 0.7)
	btn.set_border_width_all(1)
	btn.set_corner_radius_all(8)
	btn.content_margin_left = 16
	btn.content_margin_right = 16
	btn.content_margin_top = 9
	btn.content_margin_bottom = 9
	var btn_h := btn.duplicate()
	btn_h.bg_color = Color(0.12, 0.16, 0.22, 0.97)
	btn_h.border_color = Color(0.72, 0.82, 0.92, 0.9)
	var btn_p := btn.duplicate()
	btn_p.bg_color = Color(0.16, 0.2, 0.28, 0.97)
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.045, 0.05, 0.07, 0.93)
	panel.border_color = Color(0.28, 0.34, 0.42, 0.5)
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(12)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 14
	panel.content_margin_bottom = 14
	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_h)
	theme.set_stylebox("pressed", "Button", btn_p)
	theme.set_stylebox("focus", "Button", btn_h)
	theme.set_stylebox("panel", "PanelContainer", panel)
	theme.set_stylebox("panel", "Panel", panel)
	theme.set_color("font_color", "Button", Color(0.9, 0.92, 0.95))
	theme.set_color("font_color", "Label", Color(0.82, 0.86, 0.9))
	if medium:
		theme.set_font("font", "Button", medium)
	return theme


static func accent() -> Color:
	return Color(0.72, 0.82, 0.94)


static func muted() -> Color:
	return Color(0.58, 0.64, 0.72)

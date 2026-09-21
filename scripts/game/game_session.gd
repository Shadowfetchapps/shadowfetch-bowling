extends Node

const Types = preload("res://scripts/bowl/bowl_types.gd")

var mode: Types.Mode = Types.Mode.SINGLE
var self_test: bool = false


func reset_defaults() -> void:
	mode = Types.Mode.SINGLE
	self_test = false


func mode_name() -> String:
	return Types.mode_name(mode)

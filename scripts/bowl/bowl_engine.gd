class_name BowlEngine
extends RefCounted

const Types = preload("res://scripts/bowl/bowl_types.gd")
const Scorer = preload("res://scripts/bowl/bowl_scorer.gd")

var mode: Types.Mode = Types.Mode.SINGLE
var phase: Types.Phase = Types.Phase.AIMING
var rolls: Array[int] = []
var winner: int = -1
var players: int = 1
var current: int = 0
var last_message: String = "Aim and roll"
var last_pins: int = 0
var standing: int = 10
var _p_rolls: Array = []


func reset(p_mode: Types.Mode) -> void:
	mode = p_mode
	phase = Types.Phase.AIMING
	players = 2 if mode == Types.Mode.AI_MATCH or mode == Types.Mode.LOCAL else 1
	current = 0
	_p_rolls = []
	for _i in players:
		var empty: Array[int] = []
		_p_rolls.append(empty)
	rolls = _p_rolls[0]
	winner = -1
	standing = 10
	last_pins = 0
	last_message = "Aim and roll"


func add_roll(pins: int) -> Dictionary:
	pins = clampi(pins, 0, next_max_pins())
	if phase == Types.Phase.OVER:
		return {"accepted": false}
	if mode == Types.Mode.PRACTICE and _complete(rolls):
		var empty: Array[int] = []
		_p_rolls[0] = empty
		rolls = _p_rolls[0]
	rolls.append(pins)
	last_pins = pins
	standing = maxi(0, standing - pins)
	_message_for(pins)
	var frame_done := not _same_player_continues(rolls)
	if frame_done:
		standing = 10
	if players > 1 and frame_done and not _complete(rolls):
		current = 1 - current
		rolls = _p_rolls[current]
		standing = 10
		last_message = "Player %d" % (current + 1)
	if mode != Types.Mode.PRACTICE and _all_complete():
		phase = Types.Phase.OVER
		if players == 1:
			winner = 0
		else:
			var s0 := score_of(0)
			var s1 := score_of(1)
			if s0 > s1:
				winner = 0
			elif s1 > s0:
				winner = 1
			else:
				winner = -1
		if players == 1:
			last_message = "Final  %d" % score_of(0)
		else:
			last_message = "Final  %d – %d" % [score_of(0), score_of(1)]
	return {"accepted": true, "pins": pins, "score": score(), "standing": standing, "frame_done": frame_done}


func next_max_pins() -> int:
	if _complete(rolls) and mode != Types.Mode.PRACTICE:
		return 0
	var fr := _open_frame(rolls)
	if fr < 9:
		if _rolls_in_frame(rolls, fr) == 1:
			return 10 - int(rolls[rolls.size() - 1])
		return 10
	var tenth := _tenth_rolls(rolls)
	if tenth.is_empty():
		return 10
	if tenth.size() == 1:
		if int(tenth[0]) == 10:
			return 10
		return 10 - int(tenth[0])
	return 10


func score() -> int:
	return Scorer.score(rolls)


func score_of(player: int) -> int:
	return Scorer.score(_p_rolls[player])


func is_complete() -> bool:
	return _complete(rolls)


func frame_index() -> int:
	return mini(_open_frame(rolls), 9)


func ball_in_frame() -> int:
	return _rolls_in_frame(rolls, frame_index()) + 1


func marks_of(player: int) -> PackedStringArray:
	return Scorer.marks(_p_rolls[player])


func _all_complete() -> bool:
	for i in players:
		if not _complete(_p_rolls[i]):
			return false
	return true


func _complete(rs: Array) -> bool:
	return Scorer.is_complete(rs)


func _open_frame(rs: Array) -> int:
	return Scorer.open_frame(rs)


func _rolls_in_frame(rs: Array, frame: int) -> int:
	return Scorer.rolls_in_frame(rs, frame)


func _tenth_rolls(rs: Array) -> Array:
	return Scorer.tenth_rolls(rs)


func _same_player_continues(rs: Array) -> bool:
	if _complete(rs):
		return false
	var fr := _open_frame(rs)
	if fr < 9:
		return _rolls_in_frame(rs, fr) == 1
	return true


func _message_for(pins: int) -> void:
	var fr := frame_index()
	if fr < 9:
		if _rolls_in_frame(rolls, fr) == 0 and pins == 10:
			last_message = "Strike"
		elif not _same_player_continues(rolls) and _open_frame(rolls) > 0:
			var prev := _closed_frame_pins(rolls, _open_frame(rolls) - 1)
			if prev == 10 and pins != 10:
				last_message = "Spare"
			elif pins == 0 and standing == 10:
				last_message = "Gutter"
			else:
				last_message = "%d pins" % pins
		elif pins == 0:
			last_message = "Gutter"
		else:
			last_message = "%d pins" % pins
	else:
		if pins == 10:
			last_message = "Strike"
		elif pins == 0:
			last_message = "Gutter"
		else:
			last_message = "%d pins" % pins


func _closed_frame_pins(rs: Array, frame: int) -> int:
	return Scorer.frame_pin_total(rs, frame)

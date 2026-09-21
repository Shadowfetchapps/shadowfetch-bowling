extends RefCounted

const Types = preload("res://scripts/bowl/bowl_types.gd")
const Rules = preload("res://scripts/bowl/bowl_engine.gd")
const Scorer = preload("res://scripts/bowl/bowl_scorer.gd")
const Pins = preload("res://scripts/bowl/bowl_pins.gd")

var _failures: Array[String] = []
var _checks := 0


func run_all() -> bool:
	_perfect()
	_gutters()
	_all_spares()
	_opens()
	_tenth()
	_turkey()
	_alternating()
	_mixed()
	_clamp()
	_two_player()
	_pins_layout()
	_random_games(20000)
	_random_partial(8000)
	print("Bowling checks: %d  failures: %d" % [_checks, _failures.size()])
	for m in _failures:
		print("FAIL: ", m)
	return _failures.is_empty()


func _perfect() -> void:
	var e = _fresh()
	for _i in 12:
		e.add_roll(10)
	_ok(e.score() == 300, "perfect 300")
	_ok(e.is_complete(), "perfect complete")
	_ok(Scorer.score(e.rolls) == 300, "scorer 300")


func _gutters() -> void:
	var e = _fresh()
	for _i in 20:
		e.add_roll(0)
	_ok(e.score() == 0, "all gutter")
	_ok(e.is_complete(), "gutter complete")


func _all_spares() -> void:
	var e = _fresh()
	for _i in 21:
		e.add_roll(5)
	_ok(e.score() == 150, "all 5-spares = 150")


func _opens() -> void:
	var e = _fresh()
	for _i in 10:
		e.add_roll(9)
		e.add_roll(0)
	_ok(e.score() == 90, "nine-gutter 90")


func _tenth() -> void:
	var e = _fresh()
	for _i in 9:
		e.add_roll(10)
	e.add_roll(10)
	e.add_roll(10)
	e.add_roll(10)
	_ok(e.score() == 300, "tenth three strikes still 300")
	e = _fresh()
	for _i in 9:
		e.add_roll(0)
		e.add_roll(0)
	e.add_roll(5)
	e.add_roll(5)
	e.add_roll(7)
	_ok(e.score() == 17, "tenth spare plus 7")
	e = _fresh()
	for _i in 9:
		e.add_roll(0)
		e.add_roll(0)
	e.add_roll(10)
	e.add_roll(3)
	e.add_roll(4)
	_ok(e.score() == 17, "tenth strike 3 4")
	e = _fresh()
	for _i in 9:
		e.add_roll(10)
	e.add_roll(0)
	e.add_roll(10)
	e.add_roll(10)
	_ok(e.score() == 270, "tenth gutter spare strike after 9 strikes")


func _turkey() -> void:
	var e = _fresh()
	e.add_roll(10)
	e.add_roll(10)
	e.add_roll(10)
	e.add_roll(0)
	e.add_roll(0)
	for _i in 8:
		e.add_roll(0)
		e.add_roll(0)
	_ok(e.score() == 60, "turkey then gutters = 60")


func _alternating() -> void:
	var e = _fresh()
	for _i in 5:
		e.add_roll(10)
		e.add_roll(5)
		e.add_roll(5)
	e.add_roll(5)
	_ok(e.is_complete(), "alt complete")
	_ok(e.score() == 195, "strike spare alternating 195")


func _mixed() -> void:
	var e = _fresh()
	var seq := [10, 7, 3, 9, 0, 10, 0, 8, 8, 2, 0, 6, 10, 10, 10, 8, 1]
	for p in seq:
		e.add_roll(int(p))
	_ok(e.score() == 167, "mixed 167")


func _clamp() -> void:
	var e = _fresh()
	e.add_roll(7)
	e.add_roll(8)
	_ok(e.rolls[1] == 3, "cannot knock more than remaining")
	e.add_roll(11)
	_ok(e.rolls[2] == 10, "clamp 11 to 10")


func _two_player() -> void:
	var e = Rules.new()
	e.reset(Types.Mode.LOCAL)
	e.add_roll(10)
	_ok(e.current == 1, "strike hands off")
	e.add_roll(3)
	e.add_roll(4)
	_ok(e.current == 0, "open frame returns")
	_ok(e.score_of(0) == 10, "p1 pending strike bonus later")
	_ok(e.score_of(1) == 7, "p2 open 7")


func _pins_layout() -> void:
	var spots := Pins.spots(11.5, 0.19)
	_ok(spots.size() == 10, "ten pins")
	_ok(Pins.centers_legal(spots), "pins do not overlap")
	_ok(Pins.is_standing(Vector3(0, 0.19, 11.5), Vector3.UP, 0.0, 11.5), "upright stands")
	_ok(not Pins.is_standing(Vector3(0, 0.02, 11.5), Vector3.UP, 0.0, 11.5), "floor drop is down")
	_ok(not Pins.is_standing(Vector3(0, 0.19, 11.5), Vector3.RIGHT, 0.0, 11.5), "flat is down")
	_ok(not Pins.is_standing(Vector3(0, 0.19, 13.2), Vector3.UP, 0.0, 11.5), "pit is down")


func _random_games(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260920
	for g in n:
		var e = _fresh()
		var twin: Array = []
		while not e.is_complete():
			var mx = e.next_max_pins()
			_ok(mx == Scorer.next_max(e.rolls), "max sync")
			var pins := rng.randi_range(0, mx)
			e.add_roll(pins)
			twin.append(e.last_pins)
		_ok(e.score() == Scorer.score(twin), "random game score")
		_ok(Scorer.is_complete(twin), "random complete")
		_ok(e.score() >= 0 and e.score() <= 300, "score bounds")
	_ok(n >= 20000, "20000 random games")


func _random_partial(n: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for g in n:
		var e = _fresh()
		var balls := rng.randi_range(0, 12)
		for _b in balls:
			if e.is_complete():
				break
			e.add_roll(rng.randi_range(0, e.next_max_pins()))
		_ok(e.score() == Scorer.score(e.rolls), "partial match")
		_ok(e.score() <= 300, "partial cap")


func _fresh():
	var e = Rules.new()
	e.reset(Types.Mode.SINGLE)
	return e


func _ok(cond: bool, msg: String) -> void:
	_checks += 1
	if not cond:
		if _failures.size() < 40:
			_failures.append(msg)

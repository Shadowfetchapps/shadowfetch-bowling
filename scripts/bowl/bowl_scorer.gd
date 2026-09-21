class_name BowlScorer
extends RefCounted


static func score(rs: Array) -> int:
	var total := 0
	var i := 0
	for _f in 10:
		if i >= rs.size():
			break
		if int(rs[i]) == 10:
			total += 10 + _peek(rs, i + 1) + _peek(rs, i + 2)
			i += 1
		elif i + 1 < rs.size() and int(rs[i]) + int(rs[i + 1]) == 10:
			total += 10 + _peek(rs, i + 2)
			i += 2
		elif i + 1 < rs.size():
			total += int(rs[i]) + int(rs[i + 1])
			i += 2
		else:
			total += int(rs[i])
			i += 1
	return total


static func is_complete(rs: Array) -> bool:
	var i := 0
	for _f in 9:
		if i >= rs.size():
			return false
		if int(rs[i]) == 10:
			i += 1
		else:
			if i + 1 >= rs.size():
				return false
			i += 2
	if i >= rs.size():
		return false
	if int(rs[i]) == 10:
		return rs.size() >= i + 3
	if i + 1 >= rs.size():
		return false
	if int(rs[i]) + int(rs[i + 1]) == 10:
		return rs.size() >= i + 3
	return rs.size() >= i + 2


static func open_frame(rs: Array) -> int:
	var i := 0
	for f in 10:
		if i >= rs.size():
			return f
		if f < 9:
			if int(rs[i]) == 10:
				i += 1
			elif i + 1 < rs.size():
				i += 2
			else:
				return f
		else:
			return 9
	return 10


static func rolls_in_frame(rs: Array, frame: int) -> int:
	var i := _frame_start(rs, frame)
	if i >= rs.size():
		return 0
	if frame < 9:
		if int(rs[i]) == 10:
			return 1 if i < rs.size() else 0
		return mini(2, rs.size() - i)
	return rs.size() - i


static func tenth_rolls(rs: Array) -> Array:
	var i := _frame_start(rs, 9)
	var out: Array = []
	while i < rs.size():
		out.append(int(rs[i]))
		i += 1
	return out


static func frame_pin_total(rs: Array, frame: int) -> int:
	var i := _frame_start(rs, frame)
	if i >= rs.size():
		return 0
	if frame < 9:
		if int(rs[i]) == 10:
			return 10
		if i + 1 < rs.size():
			return int(rs[i]) + int(rs[i + 1])
		return int(rs[i])
	var t := 0
	for k in mini(3, rs.size() - i):
		t += int(rs[i + k])
	return t


static func marks(rs: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var i := 0
	for f in 10:
		if i >= rs.size():
			out.append("")
			continue
		if f < 9:
			if int(rs[i]) == 10:
				out.append("X")
				i += 1
			elif i + 1 < rs.size():
				if int(rs[i]) + int(rs[i + 1]) == 10:
					out.append("%s/" % _digit(int(rs[i])))
				else:
					out.append("%s%s" % [_digit(int(rs[i])), _digit(int(rs[i + 1]))])
				i += 2
			else:
				out.append(_digit(int(rs[i])))
				i += 1
		else:
			var parts: Array[String] = []
			while i < rs.size() and parts.size() < 3:
				parts.append(_tenth_mark(rs, i, parts.size()))
				i += 1
			out.append("".join(parts))
	return out


static func next_max(rs: Array) -> int:
	if is_complete(rs):
		return 0
	var fr := open_frame(rs)
	if fr < 9:
		if rolls_in_frame(rs, fr) == 1:
			return 10 - int(rs[rs.size() - 1])
		return 10
	var tenth := tenth_rolls(rs)
	if tenth.is_empty():
		return 10
	if tenth.size() == 1:
		if int(tenth[0]) == 10:
			return 10
		return 10 - int(tenth[0])
	return 10


static func _frame_start(rs: Array, frame: int) -> int:
	var i := 0
	for f in frame:
		if i >= rs.size():
			return rs.size()
		if f < 9 and int(rs[i]) == 10:
			i += 1
		else:
			i += 2
	return i


static func _peek(rs: Array, i: int) -> int:
	if i < 0 or i >= rs.size():
		return 0
	return int(rs[i])


static func _digit(n: int) -> String:
	if n == 0:
		return "-"
	return str(n)


static func _tenth_mark(rs: Array, i: int, slot: int) -> String:
	var n := int(rs[i])
	if n == 10:
		return "X"
	if slot >= 1:
		var prev := int(rs[i - 1])
		if prev != 10 and prev + n == 10:
			return "/"
	return _digit(n)

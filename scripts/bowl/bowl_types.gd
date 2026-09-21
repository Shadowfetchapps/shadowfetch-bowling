class_name BowlTypes
extends RefCounted

enum Mode { SINGLE, PRACTICE, AI_MATCH, LOCAL }
enum Phase { AIMING, ROLLING, OVER }


static func mode_name(mode: Mode) -> String:
	match mode:
		Mode.PRACTICE:
			return "Practice"
		Mode.AI_MATCH:
			return "AI Match"
		Mode.LOCAL:
			return "Local"
		_:
			return "Single"

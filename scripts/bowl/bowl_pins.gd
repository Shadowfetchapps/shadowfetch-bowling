class_name BowlPins
extends RefCounted

const GAP := 0.3048
const ROW := 0.3048 * 0.86602540378
const PIN_RADIUS := 0.061
const PIN_HEIGHT := 0.381


static func spots(pin_z: float, pin_y: float) -> Array[Vector3]:
	var z0 := pin_z
	return [
		Vector3(0.0, pin_y, z0),
		Vector3(-0.1524, pin_y, z0 + ROW),
		Vector3(0.1524, pin_y, z0 + ROW),
		Vector3(-0.3048, pin_y, z0 + ROW * 2.0),
		Vector3(0.0, pin_y, z0 + ROW * 2.0),
		Vector3(0.3048, pin_y, z0 + ROW * 2.0),
		Vector3(-0.4572, pin_y, z0 + ROW * 3.0),
		Vector3(-0.1524, pin_y, z0 + ROW * 3.0),
		Vector3(0.1524, pin_y, z0 + ROW * 3.0),
		Vector3(0.4572, pin_y, z0 + ROW * 3.0),
	]


static func is_standing(origin: Vector3, up: Vector3, floor_y: float, pin_z: float) -> bool:
	if origin.y < floor_y + 0.08:
		return false
	if up.dot(Vector3.UP) < 0.72:
		return false
	if origin.z > pin_z + 1.35:
		return false
	if absf(origin.x) > 0.72:
		return false
	return true


static func centers_legal(points: Array[Vector3]) -> bool:
	var min_d := PIN_RADIUS * 2.0 - 0.002
	for i in points.size():
		for j in range(i + 1, points.size()):
			var a := Vector2(points[i].x, points[i].z)
			var b := Vector2(points[j].x, points[j].z)
			if a.distance_to(b) < min_d:
				return false
	return true

extends Control

const COLOR_LOCKED_LINE := Color(0.2, 0.85, 0.3, 0.8)
const COLOR_SCAN_COLD   := Color(0.4, 0.6, 0.4, 0.6)
const COLOR_SCAN_HOT    := Color(0.1, 1.0, 0.2, 0.9)
const COLOR_LOCKABLE    := Color(1.0, 1.0, 0.2)

const RECEIVER_RADIUS := 12.0
const SCAN_LINE_LENGTH := 1200.0

@onready var _map: TriangulationMap = $"../../.."

func _draw() -> void:
	_draw_locked_lines()

	if not _map.is_complete():
		_draw_scan_line()


func _draw_locked_lines() -> void:
	for line_data in _map.get_locked_lines():
		var origin: Vector2 = line_data["origin"]
		var dir: Vector2 = line_data["direction"]
		var end_pt := origin + dir * SCAN_LINE_LENGTH
		draw_line(origin, end_pt, COLOR_LOCKED_LINE, 2.5)


func _draw_scan_line() -> void:
	var origin := _map._receiver_map_position
	var dir := Vector2.from_angle(_map.get_current_angle())
	var thickness := _map.get_scan_thickness()
	var lockable := _map.is_lockable()

	var t := inverse_lerp(_map.min_line_thickness, _map.max_line_thickness, thickness)
	var color: Color
	if lockable:
		color = COLOR_LOCKABLE
	else:
		color = COLOR_SCAN_COLD.lerp(COLOR_SCAN_HOT, t)

	var end_pt := origin + dir * SCAN_LINE_LENGTH
	draw_line(origin, end_pt, color, thickness)

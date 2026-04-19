class_name TriangulationMap
extends Control

signal signal_triangulated()
signal map_closed(success:bool)
signal scan_too_close()
signal signal_too_weak()

@export var rotate_speed: float = 90.0
@export var lock_angle_threshold: float = 8.0
@export var min_line_thickness: float = 1.5
@export var max_line_thickness: float = 7.0
@export var thickness_falloff_angle: float = 60.0

# Area for the map with the margin is 600x320
var _target_map_position: Vector2 = Vector2(626, -44)
var _receiver_map_position: Vector2 = Vector2(300, 350)
var _required_lines: int = 3
var _current_angle: float = 0.0
var _locked_lines: Array[Dictionary] = []
var _active: bool = false
var _too_close: bool = false

@onready var canvas: Control = $MarginContainer/Panel/Canvas
@onready var receiver: Sprite2D = $MarginContainer/Panel/Receiver
@onready var transmitter: Sprite2D = $MarginContainer/Panel/Transmitter
@onready var static_loop: AudioStreamPlayer = $StaticLoop

func _ready() -> void:
	set_process(false)

func clear() -> void:
	_locked_lines.clear()
	transmitter.visible = false

func show_map(_target:Vector2, _player:Vector2, direction:Vector2i) -> void:
	receiver.position = _player
	transmitter.position = _target
	_target_map_position = _target
	_receiver_map_position = _player
	_current_angle = Vector2(direction).angle()
	receiver.rotation = _current_angle
	_active = true
	_too_close = false
	set_process(true)
	canvas.queue_redraw()
	if _locked_lines.size() < _required_lines:
		if is_point_too_close(_receiver_map_position):
			_too_close = true
			scan_too_close.emit()
		else:
			static_loop.play()

func is_point_too_close(point: Vector2) -> bool:
	var min_dist := 50.0
	for line in _locked_lines:
		var origin: Vector2 = line.origin
		if point.distance_to(origin) < min_dist:
			return true
		var max_length := 500.0
		var end: Vector2 = origin + line.direction * max_length
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, origin, end)
		if point.distance_to(closest) < min_dist:
			return true

	return false

func hide_map() -> void:
	_active = false
	set_process(false)
	static_loop.stop()

func _process(delta: float) -> void:
	if not _active or _too_close:
		return
	
	if _locked_lines.size() < _required_lines:
		var rotation_input := 0.0
		if Input.is_action_pressed("left"):
			rotation_input -= 1.0
		if Input.is_action_pressed("right"):
			rotation_input += 1.0
		
		if rotation_input != 0.0:
			_current_angle += deg_to_rad(rotate_speed * rotation_input * delta)
			receiver.rotation = _current_angle
			canvas.queue_redraw()
		
		var diff_deg := rad_to_deg(get_angle_diff_abs())
		var volume_clamped := clampf(diff_deg / thickness_falloff_angle, 0.0, 1.0)
		static_loop.volume_linear = lerpf(0, 1.0, volume_clamped)
	
	if Input.is_action_just_pressed("lock_line"):
		if transmitter.visible:
			map_closed.emit(false)
		else:	
			_try_lock_line()

func _try_lock_line() -> void:
	if _locked_lines.size() >= _required_lines:
		return

	var angle_to_target := _angle_to_target()
	var diff := absf(angle_to_target)

	if diff > deg_to_rad(lock_angle_threshold):
		signal_too_weak.emit()
		return

	var dir := Vector2.from_angle(_current_angle)
	_locked_lines.append({ "origin": _receiver_map_position, "direction": dir })
	canvas.queue_redraw()

	if _locked_lines.size() >= _required_lines:
		transmitter.visible = true
		signal_triangulated.emit()
	else:
		map_closed.emit(true)

func _angle_to_target() -> float:
	var to_target := (_target_map_position - _receiver_map_position).angle()
	return wrapf(_current_angle - to_target, -PI, PI)

func get_current_angle() -> float:
	return _current_angle

func get_locked_lines() -> Array[Dictionary]:
	return _locked_lines

func get_angle_diff_abs() -> float:
	return abs(_angle_to_target())

func get_scan_thickness() -> float:
	# TODO: refactor this if I get a chance, it's gotten messy, see canvas.gd
	var diff_deg := rad_to_deg(get_angle_diff_abs())
	var t := 1.0 - clampf(diff_deg / thickness_falloff_angle, 0.0, 1.0)
	return lerpf(min_line_thickness, max_line_thickness, t)

func is_lockable() -> bool:
	return get_angle_diff_abs() <= deg_to_rad(lock_angle_threshold)

func is_complete() -> bool:
	return _locked_lines.size() >= _required_lines

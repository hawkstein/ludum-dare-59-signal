class_name TriangulationMap
extends Control

signal signal_triangulated()
signal map_closed()

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

@onready var canvas: Control = $MarginContainer/Panel/Canvas
@onready var receiver: Sprite2D = $MarginContainer/Panel/Receiver
@onready var transmitter: Sprite2D = $MarginContainer/Panel/Transmitter

func _ready() -> void:
	set_process(false)

func show_map(_target:Vector2, _player:Vector2) -> void:
	receiver.position = _player
	transmitter.position = _target
	_target_map_position = _target
	_receiver_map_position = _player
	_current_angle = 0.0
	_active = true
	set_process(true)
	canvas.queue_redraw()


func hide_map() -> void:
	_active = false
	set_process(false)

func _process(delta: float) -> void:
	if not _active:
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
	
	if Input.is_action_just_pressed("lock_line"):
		_try_lock_line()

func _try_lock_line() -> void:
	if _locked_lines.size() >= _required_lines:
		return

	var angle_to_target := _angle_to_target()
	var diff := absf(angle_to_target)

	if diff > deg_to_rad(lock_angle_threshold):
		#TODO: add feedback that this doesn't work (tutorial message from character, sound)
		return

	var dir := Vector2.from_angle(_current_angle)
	_locked_lines.append({ "origin": _receiver_map_position, "direction": dir })
	canvas.queue_redraw()

	if _locked_lines.size() >= _required_lines:
		transmitter.visible = true
		signal_triangulated.emit()
	else:
		map_closed.emit()

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
	var diff_deg := rad_to_deg(get_angle_diff_abs())
	var t := 1.0 - clampf(diff_deg / thickness_falloff_angle, 0.0, 1.0)
	return lerpf(min_line_thickness, max_line_thickness, t)

func is_lockable() -> bool:
	return get_angle_diff_abs() <= deg_to_rad(lock_angle_threshold)

func is_complete() -> bool:
	return _locked_lines.size() >= _required_lines

extends CharacterBody2D

@export var tile_map: TileMapLayer
@export var base_velocity: float = 64.0 

var speed := 1.0
var current_direction:= Vector2i.ZERO
var desired_direction:= Vector2i.ZERO

func _physics_process(_delta: float) -> void:
	_read_input()
	velocity = Vector2(current_direction) * speed * base_velocity
	move_and_slide()

func _read_input() -> void:
	if Input.is_action_just_pressed("up"):
		if current_direction == Vector2i.UP:
			speed = 2.0
		else:
			speed = 1.0
		desired_direction = Vector2i.UP
	elif Input.is_action_just_pressed("down"):
		if current_direction == Vector2i.DOWN:
			speed = 2.0
		else:
			speed = 1.0
		desired_direction = Vector2i.DOWN
	elif Input.is_action_just_pressed("left"):
		if current_direction == Vector2i.LEFT:
			speed = 2.0
		else:
			speed = 1.0
		desired_direction = Vector2i.LEFT
	elif Input.is_action_just_pressed("right"):
		if current_direction == Vector2i.RIGHT:
			speed = 2.0
		else:
			speed = 1.0
		desired_direction = Vector2i.RIGHT
	
	current_direction = desired_direction
	# TODO: add speed up or brake code i.e if you tap the same direction speed up, tap the opposite to brake

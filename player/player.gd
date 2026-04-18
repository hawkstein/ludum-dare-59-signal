extends CharacterBody2D

@export var tile_map: TileMapLayer
@export var base_velocity: float = 64.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var left_marker: Marker2D = $LeftMarker
@onready var right_marker: Marker2D = $RightMarker
@onready var up_marker: Marker2D = $UpMarker
@onready var down_marker: Marker2D = $DownMarker

var speed := 1.0
var current_direction:= Vector2i.ZERO
var desired_direction:= Vector2i.ZERO

var active := true

func _physics_process(_delta: float) -> void:
	if not active:
		return
	_read_input()
	_update_sprite()
	velocity = Vector2(current_direction) * speed * base_velocity
	_update_particles()
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

func _update_sprite() -> void:
	if current_direction == Vector2i.UP:
		animated_sprite.play("up")
	elif current_direction == Vector2i.LEFT:
		animated_sprite.play("sideways")
		animated_sprite.flip_h = true
	elif current_direction == Vector2i.RIGHT:
		animated_sprite.play("sideways")
		animated_sprite.flip_h = false
	elif current_direction == Vector2i.DOWN:
		animated_sprite.play("down")

func _update_particles() -> void:
	if speed >= 2.0:
		dust_particles.emitting = true
	else:
		dust_particles.emitting = false
		return
	
	if current_direction == Vector2i.UP:
		dust_particles.position = up_marker.position
	elif current_direction == Vector2i.LEFT:
		dust_particles.position = left_marker.position
	elif current_direction == Vector2i.RIGHT:
		dust_particles.position = right_marker.position
	elif current_direction == Vector2i.DOWN:
		dust_particles.position = down_marker.position

func reset() -> void:
#	TODO: clear any data for this attempt
	pass

func collect_transmitter() -> void:
#	TODO: add collection code when player is expected to collect multiple transmitters
	pass

func stop_moving() -> void:
	current_direction = Vector2.ZERO
	desired_direction = Vector2.ZERO
	active = false

func start_moving() -> void:
	active = true

extends CharacterBody2D

@export var tile_map: TileMapLayer
@export var base_velocity: float = 64.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var dust_particles: GPUParticles2D = $DustParticles
@onready var left_marker: Marker2D = $LeftMarker
@onready var right_marker: Marker2D = $RightMarker
@onready var up_marker: Marker2D = $UpMarker
@onready var down_marker: Marker2D = $DownMarker
@onready var ignore_timer: Timer = $IgnoreTimer

var speed := 1.0
var current_direction:= Vector2i.ZERO
var desired_direction:= Vector2i.ZERO

var active := true
var _ignore_input :=false

func _physics_process(_delta: float) -> void:
	if not active:
		return
	_read_input()
	_update_sprite()
	velocity = Vector2(current_direction) * speed * base_velocity
	_update_particles()
	move_and_slide()

func _read_input() -> void:
	if _ignore_input:
		return
	var input_direction := false
	if Input.is_action_just_pressed("up"):
		desired_direction = Vector2i.UP
		input_direction = true
	elif Input.is_action_just_pressed("down"):
		desired_direction = Vector2i.DOWN
		input_direction = true
	elif Input.is_action_just_pressed("left"):
		desired_direction = Vector2i.LEFT
		input_direction = true
	elif Input.is_action_just_pressed("right"):
		desired_direction = Vector2i.RIGHT
		input_direction = true
	
	if input_direction and current_direction == desired_direction:
		speed = 2.0
	
	if input_direction and current_direction == -desired_direction:
		if speed >= 2.0:
			speed = 1.0
			desired_direction = current_direction
		else:
			desired_direction = Vector2i.ZERO
			current_direction = Vector2i.ZERO
	else:	
		current_direction = desired_direction

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
	elif current_direction == Vector2i.ZERO:
		var current_anim := animated_sprite.animation
		if current_anim.ends_with("_idle"):
			return
		if current_anim == "up":
			animated_sprite.play("up_idle")
		elif current_anim == "down":
			animated_sprite.play("down_idle")
		else:
			animated_sprite.play("sideways_idle")

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

func reverse_direction() -> void:
	desired_direction = -desired_direction
	current_direction = -current_direction
	speed = 1.0
	_ignore_input = true
	ignore_timer.start()
	await ignore_timer.timeout
	_ignore_input = false

func reset() -> void:
#	TODO: clear any data for this attempt
	pass

func collect_transmitter() -> void:
#	TODO: add collection code when player is expected to collect multiple transmitters
	pass

func stop_moving() -> void:
	current_direction = Vector2i.ZERO
	desired_direction = Vector2i.ZERO
	active = false
	speed = 1.0

func start_moving() -> void:
	active = true

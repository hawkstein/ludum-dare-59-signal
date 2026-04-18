extends Node2D

@export var duration := 10.0
@export var final_scale := 20.0
@export var wobble_amplitude := 15.0
@export var wobble_frequency := 2.0

@onready var line_2d: Line2D = $Line2D

var _elapsed := 0.0

func _ready() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * final_scale, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_property(line_2d, "width", 0.1, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_callback(queue_free)

func _process(delta: float) -> void:
	_elapsed += delta
	rotation_degrees = sin(_elapsed * wobble_frequency * TAU) * wobble_amplitude

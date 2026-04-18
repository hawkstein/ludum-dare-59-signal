class_name Transmitter
extends Node2D

const TRANSMITTER_PULSE = preload("uid://cog58bmw7p2r7")

signal transmitter_found()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("collect_transmitter"):
		transmitter_found.emit()
		call_deferred("queue_free")


func _on_timer_timeout() -> void:
	var pulse := TRANSMITTER_PULSE.instantiate()
	add_child(pulse)

class_name Transmitter
extends Node2D

signal transmitter_found()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("collect_transmitter"):
		transmitter_found.emit()
		call_deferred("queue_free")

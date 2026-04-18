extends Node2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("collect_transmitter"):
		call_deferred("_switch_to_win")

func _switch_to_win() -> void:
	get_tree().change_scene_to_file("res://narrative/win.tscn")

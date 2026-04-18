extends Node2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("reset"):
		body.reset()
		call_deferred("_switch_to_start_again")

func _switch_to_start_again() -> void:
	get_tree().change_scene_to_file("res://narrative/start-again.tscn")

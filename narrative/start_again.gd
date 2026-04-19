extends Control

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("lock_line"):
		_on_button_pressed()

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

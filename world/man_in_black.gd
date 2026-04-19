extends Node2D

@onready var despawn_timer: Timer = $DespawnTimer

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("reset"):
		body.reset()
		call_deferred("_switch_to_start_again")

func _switch_to_start_again() -> void:
	get_tree().change_scene_to_file("res://narrative/start-again.tscn")


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	despawn_timer.start(randi_range(5, 10))


func _on_despawn_timer_timeout() -> void:
	print("despawning man in black")
	call_deferred("queue_free")


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	despawn_timer.stop()

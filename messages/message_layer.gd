class_name MessageLayer
extends CanvasLayer

@onready var message_label: Label = %MessageLabel
@onready var push_to_talk_player: AudioStreamPlayer = $PushToTalkPlayer

var hide_timer := Timer.new()

func _ready() -> void:
	visible = false
	hide_timer.connect("timeout", _on_hide_timer)
	hide_timer.wait_time = 6.0
	add_child(hide_timer)

func display_message(message:String) -> void:
	visible = true
	message_label.text = message
	hide_timer.start()
	push_to_talk_player.play()

func hide_messages() -> void:
	visible = false

func _on_hide_timer() -> void:
	hide_messages()

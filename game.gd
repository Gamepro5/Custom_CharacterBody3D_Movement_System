extends Node

func _ready():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -15)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mouse_input"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

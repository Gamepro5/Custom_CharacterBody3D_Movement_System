extends Control

func _ready():
	_on_resized()

func _on_resized():
	$Crosshair.position.x = get_viewport_rect().size.x/2
	$Crosshair.position.y = get_viewport_rect().size.y/2

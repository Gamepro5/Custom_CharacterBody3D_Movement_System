extends AnimatableBody3D

@onready var original_position = position
var speed = 5
var dir = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _physics_process(delta):
	#move_and_collide(Vector3(0, 0.1, 0)*delta) #doesn't work because the platform stops if someone is on it.
	if position.y > original_position.y+10 || position.y < original_position.y:
		dir = dir * -1	
	position.y += dir*speed*delta

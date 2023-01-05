extends AnimatableBody3D

var velocity = Vector3.ZERO
var original_position = position
@export var relative_end_position_per_axis = position
@export var to_velocity = Vector3.ZERO
@export var from_velocity = Vector3.ZERO


func _physics_process(delta):
	
	if position.x >= original_position.x+relative_end_position_per_axis.x:
		constant_linear_velocity.x = from_velocity.x
	if position.x <= original_position.x:
		constant_linear_velocity.x = to_velocity.x
		
	if position.y >= original_position.y+relative_end_position_per_axis.y:
		constant_linear_velocity.y = from_velocity.y
	if position.y <= original_position.y:
		constant_linear_velocity.y = to_velocity.y
		
	if position.z >= original_position.z+relative_end_position_per_axis.z:
		constant_linear_velocity.z = from_velocity.z
	if position.z <= original_position.z:
		constant_linear_velocity.z = to_velocity.z
		
	position += constant_linear_velocity * delta

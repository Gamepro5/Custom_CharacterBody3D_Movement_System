extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 10
var mouse_axis = Vector2.ZERO
var vertical
var horizontal
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0,0,0)
var max_floor_angle = deg_to_rad(89)
var last_floor_normal = Vector3.UP
@onready var label = $VelocityLabel
var previous_vel = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		#get_tree().quit() # Quits the game
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		
	if event.is_action_pressed("mouse_input"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion:
		mouse_axis = event.relative
		
		var horizontal: float = -mouse_axis.x * 0.05
		var vertical: float = -mouse_axis.y * 0.05
			
		mouse_axis = Vector2(0,0)
		rotate_y(deg_to_rad(horizontal))
		$Head.rotate_x(deg_to_rad(vertical))
		#print($Head.rotation)
		$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		vel.x = dir.x * SPEED
		vel.z = dir.z * SPEED
	else:
		vel.x = move_toward(vel.x, 0, SPEED)
		vel.z = move_toward(vel.z, 0, SPEED)
		
	$RayCast3d.set_rotation(- $RayCast3d.get_parent().rotation)
	$RayCast3d.target_position = vel;
	#(0.01+vel.length()*delta)
	var floor_check_vector = Vector3.DOWN*(rad_to_deg(last_floor_normal.angle_to(Vector3.UP))+1)*10
	var ground_check = move_and_collide(floor_check_vector*delta, true)
	if ground_check: #on floor
		var normal = ground_check.get_normal()
		ground_check = move_and_collide(Vector3.DOWN*0.01, true)
		if !ground_check:
			move_and_collide(floor_check_vector)
		vel.y = 0;
		last_floor_normal = normal;
		if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
			vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
			if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
				vel.y = 0
		var col = move_and_collide(vel*delta)
		if col:
			normal = col.get_normal()
			last_floor_normal = normal;
			if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
				vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
				if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
					vel.y = 0
				move_and_collide(vel*delta)
			else: #slope is not the floor. it is either a ceiling or a wall.
				velocity = vel
				move_and_slide()
			
	else:
		if (last_floor_normal.angle_to(Vector3.UP) >= deg_to_rad(45)):
			if ((vel.x == 0 && previous_vel.x != 0) && (vel.z == 0 && previous_vel.z != 0)): #just stopped moving
				vel.y = 0;
			print(last_floor_normal.angle_to(Vector3.UP), "  ", deg_to_rad(45))
			print("error! correcting...")
			move_and_collide(Vector3(0,-(abs(vel.y)),0))
			last_floor_normal = Vector3.UP
		else:
			vel.y -= gravity * delta
			move_and_collide(vel*delta)
	
	previous_vel = vel
	
	label.text = var_to_str(vel)
	print(floor_check_vector*delta)
	
	

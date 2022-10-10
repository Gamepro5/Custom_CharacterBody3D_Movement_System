extends CharacterBody3D


const SPEED = 10
const JUMP_VELOCITY = 7
var ACCELERATION = 20
var DECELERATION = 8
var AIR_ACCELERATION = 1
var mouse_axis = Vector2.ZERO
var vertical
var horizontal
var gravity = 15#ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0,0,0)
var max_floor_angle = deg_to_rad(65)
var last_col_normal = Vector3.UP
@onready var label = $VelocityLabel
@onready var label2 = $on_floor
var previous_vel = Vector3.ZERO
var on_floor = false;
var on_wall = false;
var on_ceiling = false;
var impulse_vel = Vector3.ZERO
var snap_vector = Vector3.UP

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
	
	var temp = vel.y
	if (on_floor):
		if (dir.dot(vel) > 0):#(dir != Vector3.ZERO):
			vel = vel.lerp(dir*SPEED, ACCELERATION * delta)
		else:
			vel = vel.lerp(dir*SPEED, DECELERATION * delta)
	else:
		vel = vel.lerp(dir*SPEED, AIR_ACCELERATION * delta)
	vel.y = temp
	
	if (Vector3(vel.x,0,vel.z).length() < 0.001): #sigfigs!
		vel.x = 0
		vel.z = 0
	
	$Velocity.set_rotation(- $Velocity.get_parent().rotation)
	$Velocity.target_position = vel/5;
	
	$SurfaceNormal.set_rotation(- $SurfaceNormal.get_parent().rotation)
	$SurfaceNormal.target_position = last_col_normal*SPEED/5;
	
	$HorizontalVel.set_rotation(- $HorizontalVel.get_parent().rotation)
	$HorizontalVel.target_position = Vector3(vel.x,0,vel.z)/5;
	
	
	#(0.01+vel.length()*delta)
	#var snap_vector = Vector3.DOWN*(rad_to_deg(last_col_normal.angle_to(Vector3.UP))+1)*10
	if (snap_vector != Vector3.ZERO): # we don't want to snap if we received an impulse (like jumping)!
		snap_vector = -last_col_normal * (abs(vel.y)+10) * 0.01
	
	if Input.is_action_just_pressed("jump") and on_floor:
		last_col_normal = Vector3.UP
		vel.y = JUMP_VELOCITY
		on_floor = false;
		snap_vector = Vector3.ZERO
		
	$snapVector.set_rotation(- $snapVector.get_parent().rotation)
	$snapVector.target_position = snap_vector;
	#print(snap_vector)
	var ground_check = move_and_collide(snap_vector, true)
	if !ground_check && snap_vector != Vector3.ZERO:
		ground_check = move_and_collide( Vector3.DOWN * (abs(vel.y)+0.1) * 0.005, true)
	if ground_check:
		var normal = ground_check.get_normal()
		last_col_normal = normal;
		if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
			ground_check = move_and_collide(Vector3.DOWN*0.05, true)
			if !ground_check:
				move_and_collide(Vector3.DOWN*0.5) #snap
			vel.y = 0;
			on_floor = true
			vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
			if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
				vel.y = 0
		### this may need to be done recursively
		var col = move_and_collide(vel*delta)
		if col:
			normal = col.get_normal()
			last_col_normal = normal;
			if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
				on_floor = true
				vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
				if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
					vel.y = 0
				move_and_collide(vel*delta)
		###
			else: #slope is not the floor. it is either a ceiling or a wall.
				on_floor = false
				velocity = vel
				move_and_slide() #placeholder
				vel = velocity
			
	else:
		on_floor = false
		#print(last_col_normal, "  ", previous_vel.y)
		if (last_col_normal == Vector3(0,1,0) && floor(previous_vel.y) == 0):
			printerr("ERROR! Godot Collision Engine most likely reported a false negative just now. Snap Vector is: ", snap_vector)
		vel.y -= gravity * delta
		var col = move_and_collide(vel*delta)
		if col:
			last_col_normal = col.get_normal()
			snap_vector = -last_col_normal * (abs(vel.y)+1) * 0.01
	
		
	previous_vel = vel
	
	$velx.text = "vel.x: " + var_to_str(vel.x)
	$vely.text = "vel.y: " + var_to_str(vel.y)
	$velz.text = "vel.z: " + var_to_str(vel.z)
	$velmag.text = "vel mag: " + var_to_str(Vector3(vel.x,0,vel.z).length())
	label2.text = "on_floor: " + var_to_str(on_floor)
	
	

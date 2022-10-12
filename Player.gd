extends CharacterBody3D


var SPEED = 10
var JUMP_VELOCITY = 7
var ACCELERATION = 20
var DECELERATION = 8
var AIR_ACCELERATION = 1
var AIR_DECELERATION = 7
var mouse_axis = Vector2.ZERO
var vertical
var horizontal
var gravity = 12
var dir = Vector3.ZERO
var vel = Vector3(0,0,0)
var max_floor_angle = deg_to_rad(65)
var last_col_normal = Vector3.UP
var previous_vel = Vector3.ZERO
var on_floor = false
var on_wall = false
var on_ceiling = false
var impulse_vel = Vector3.ZERO
var snap_vector = Vector3.UP
var snap_magnitude = 0.001
var previous_dir = Vector3.ZERO
@onready var fps_camera = $Head/Camera
@onready var tps_camera = $Head/Camera2
var cached_impulses = []

func _input(event: InputEvent) -> void:
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		if event is InputEventMouseMotion:
			mouse_axis = event.relative
			
			var horizontal: float = -mouse_axis.x * 0.05
			var vertical: float = -mouse_axis.y * 0.05
				
			mouse_axis = Vector2(0,0)
			rotate_y(deg_to_rad(horizontal))
			$Head.rotate_x(deg_to_rad(vertical))
			#print($Head.rotation)
			$Head.rotation.x = clamp($Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func apply_impulse(vect: Array):
	cached_impulses.append(vect)
	
func _process(delta):
	#print(cached_impulses)
	pass

func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var temp = vel.y
	if (on_floor):
		if (dir.dot(vel) > 0):#(dir != Vector3.ZERO):
			vel = vel.lerp(dir*SPEED, ACCELERATION * delta)
		else:
			vel = vel.lerp(dir*SPEED, DECELERATION * delta)
	else:
		if dir == Vector3.ZERO:
			dir = previous_dir # so you don't need to hold a movement key to get the max possible distance
		if (dir.dot(vel) > 0): # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
			vel = vel.lerp(dir*SPEED, AIR_ACCELERATION * delta)
		else:
			vel = vel.lerp(dir*SPEED, AIR_DECELERATION * delta)
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
		#snap_vector = -last_col_normal * (abs(vel.y)+10) * snap_magnitude
		snap_vector = Vector3.DOWN * (vel.length()+10) * snap_magnitude
		
	if Input.is_action_just_pressed("jump") and on_floor and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#last_col_normal = Vector3.UP
		#vel.y = JUMP_VELOCITY
		#on_floor = false;
		apply_impulse([[null,JUMP_VELOCITY,null], true]) #apply impulse works such that the first item in the array is the velocity (represented in another array of length 3), and the second item is a boolean for if you desire to set the vel instead of adding to it.
		#snap_vector = Vector3.ZERO
	
	if cached_impulses.size() > 0:
		for i in cached_impulses:
			if i[1] == true:
				if i[0][0] != null:
					vel.x = i[0][0]
				if i[0][1] != null:
					vel.y = i[0][1]
				if i[0][2] != null:
					vel.z = i[0][2]
			else:
				if i[0][0] != null:
					vel.x += i[0][0]
				if i[0][1] != null:
					vel.y += i[0][1]
				if i[0][2] != null:
					vel.z += i[0][2]
			last_col_normal = Vector3.UP
			snap_vector = Vector3.ZERO
		cached_impulses.clear()
	
	$snapVector.set_rotation(- $snapVector.get_parent().rotation)
	$snapVector.target_position = snap_vector;
	
	var ground_check
	if (snap_vector!=Vector3.ZERO): # snap vector is only unset from zero in the "in air" part of this code, where a collision would set it to Vector3.DOWN
		ground_check = move_and_collide(snap_vector, true, 0.001, true, 10)
	if !ground_check && snap_vector != Vector3.ZERO:
		ground_check = move_and_collide( Vector3.DOWN * (abs(vel.y)+0.1) * 0.005, true) #this is here to snap down if you just climbed a slope that is so steep that you would otherwise go flying.
	if ground_check:
		var normal = ground_check.get_normal()
		last_col_normal = normal;
		var wall_collision_normal = Vector3.ZERO
		var ceiling_collision_normal = Vector3.ZERO
		for i in range(ground_check.get_collision_count()): #there may be several collisions 
			normal = ground_check.get_normal(i)
			if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
				var ground_check2 = move_and_collide(Vector3.DOWN*0.005, true, 0.001, true, 10) #we already established that we are on the floor. let's double check. if we aren't, snap down to the floor with a massive snap vector.
				if !ground_check2:
					move_and_collide(Vector3.DOWN*0.5) #snap
				vel.y = 0;
				on_floor = true
				vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
				if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
					vel.y = 0
			else: #collision is wall
				#wall_collision_normal = normal
				pass
		### this may need to be done recursively
		var col = move_and_collide(vel*delta, false, 0.001, false, 10) #actually move!
		if col:
			normal = col.get_normal()
			last_col_normal = normal;
			for i in range(col.get_collision_count()):
				normal = col.get_normal(i)
				if (normal.angle_to(Vector3.UP) <= max_floor_angle): #slope counts as the floor
					on_floor = true
					vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
					if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
						vel.y = 0
					move_and_collide(vel*delta) #move the remainder of the distnace up the slope
			###
				else: #collision is not the floor. it is either a ceiling or a wall.
					if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91: #collision is ceiling
						ceiling_collision_normal = normal
					else:
						wall_collision_normal = normal
						#vel = vel - ((vel.dot(normal))/normal.length()) * normal
		if (wall_collision_normal != Vector3.ZERO):
			on_wall = true
			vel = vel - ((vel.dot(wall_collision_normal))/wall_collision_normal.length()) * wall_collision_normal
			if vel.y > 0:
				vel.y = 0
		else:
			on_wall = false
			wall_collision_normal = Vector3.ZERO
		if (ceiling_collision_normal != Vector3.ZERO):
			on_ceiling = true
			vel.x = (vel - ((vel.dot(ceiling_collision_normal))/ceiling_collision_normal.length()) * ceiling_collision_normal).z
			vel.z = (vel - ((vel.dot(ceiling_collision_normal))/ceiling_collision_normal.length()) * ceiling_collision_normal).z
		else:
			on_ceiling = false
			ceiling_collision_normal = Vector3.ZERO
	else:
		on_floor = false
		vel.y -= gravity * delta
		var col = move_and_collide(vel*delta, false, 0.001, false, 10)
		if col:
			last_col_normal = col.get_normal()
			var normal = col.get_normal()
			for i in range(col.get_collision_count()):
				normal = col.get_normal(i)
				if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91:
					vel = vel - ((vel.dot(normal))/normal.length()) * normal
				elif (normal.angle_to(Vector3.UP) <= max_floor_angle):
					snap_vector = -last_col_normal * (abs(vel.y)+1) * snap_magnitude
				else:
					vel = vel - ((vel.dot(normal))/normal.length()) * normal
		
	previous_vel = vel
	previous_dir = dir
	$UI/pos.text = "pos: {" + var_to_str(position.x) + ", " + var_to_str(position.y) + ", " + var_to_str(position.z) + "}"
	$UI/velx.text = "vel.x: " + var_to_str(vel.x)
	$UI/vely.text = "vel.y: " + var_to_str(vel.y)
	$UI/velz.text = "vel.z: " + var_to_str(vel.z)
	$UI/velmag.text = "vel mag: " + var_to_str(Vector3(vel.x,0,vel.z).length())
	$UI/on_floor.text = "on_floor: " + var_to_str(on_floor)
	$UI/on_wall.text = "on_wall: " + var_to_str(on_wall)
	$UI/on_ceiling.text = "on_ceiling: " + var_to_str(on_ceiling)
	
	

extends CharacterBody3D


@export_range(0, 100, 1) var SPEED : int = 15
@export var JUMP_VELOCITY = 10
@export var ACCELERATION = 20
@export var DECELERATION = 8
@export var AIR_ACCELERATION = 1
@export var AIR_DECELERATION = 7
var mouse_axis = Vector2.ZERO
var vel = Vector3.ZERO
@export var gravity = 28
var dir = Vector3.ZERO
@export_range(0, 89, 1) var max_floor_angle = 65
var last_col_normal = Vector3.UP
var previous_velocity = Vector3.ZERO
var on_floor = false
var on_wall = false
var on_ceiling = false
var impulse_velocity = Vector3.ZERO
var snap_vector = Vector3.ZERO
var snap_magnitude = 1
var previous_dir = Vector3.ZERO
var cached_impulses = []
@export var noclip = false
@export var mouse_sensitivity = 0.05
var wall_collision_normal = Vector3.ZERO #needed so we can choose how we apply the input velocity when touching walls
@export var max_air_jumps = 999 #CHANGE THIS VALUE TO ADJUST YOUR MAX AIR JUMPS (SCOUT FROM TF2 HAS 1)
var air_jumps = 0 #DON'T FUCKING TOUCH THIS VALUE
var input_dir = Vector2.ZERO
var previously_on_floor = false

func _ready():
	#$StairStepper.add_collision_exception_with(self)
	#add_collision_exception_with($StairStepper)
	pass

func _input(event: InputEvent) -> void:
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		if event is InputEventMouseMotion:
			mouse_axis = event.relative
			
			var horizontal: float = -mouse_axis.x * mouse_sensitivity
			var vertical: float = -mouse_axis.y * mouse_sensitivity
				
			mouse_axis = Vector2(0,0)
			$Torso.rotate_y(deg_to_rad(horizontal))
			$Torso/Head.rotate_x(deg_to_rad(vertical))
			$Torso/Head.rotation.x = clamp($Torso/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func apply_impulse(vect: Array):
	cached_impulses.append(vect)

func _physics_process(delta):
	var max_flr_ang = deg_to_rad(max_floor_angle)
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		input_dir = Input.get_vector("left", "right", "forward", "backward")
		if (noclip):
			dir = ($Torso/Head.get_global_transform().basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
			on_floor = false
			on_wall = false
			on_ceiling = false
		else:
			dir = ($Torso.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if (!noclip):
		var temp = velocity.y
		if (on_floor):
			if (dir.dot(velocity) > 0):#(dir != Vector3.ZERO):
				velocity = velocity.lerp(dir*SPEED, ACCELERATION * delta)
			else:
				velocity = velocity.lerp(dir*SPEED, DECELERATION * delta)
		elif !on_wall or Vector3(velocity.x,0,velocity.z).dot(wall_collision_normal) >= 0: #prevent velocity from going up slopes
			if dir == Vector3.ZERO:
				dir = previous_dir # so you don't need to hold a movement key to get the max possible distance
			if (dir.dot(velocity) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
				velocity = velocity.lerp(dir*SPEED, AIR_ACCELERATION * delta)
			else:
				velocity = velocity.lerp(dir*SPEED, AIR_DECELERATION * delta)
		velocity.y = temp
		if (Vector3(velocity.x,0,velocity.z).length() < 0.001): #sigfigs!
			velocity.x = 0
			velocity.z = 0
	if noclip:
		velocity = velocity.lerp(dir*SPEED, ACCELERATION * delta)
		if (velocity.length() < 0.001): #sigfigs!
			velocity.x = 0
			velocity.y = 0
			velocity.z = 0
	
	$Velocity.set_rotation(- $Velocity.get_parent().rotation)
	$Velocity.target_position = velocity/5;
		
	$HorizontalVel.set_rotation(- $HorizontalVel.get_parent().rotation)
	$HorizontalVel.target_position = Vector3(velocity.x,0,velocity.z)/5;
	
	
	#(0.01+velocity.length()*delta)
	#var snap_vector = Vector3.DOWN*(rad_to_deg(last_col_normal.angle_to(Vector3.UP))+1)*10
	if (snap_vector != Vector3.ZERO): # we don't want to snap if we received an impulse (like jumping)!
		#snap_vector = -last_col_normal * (abs(velocity.y)+10) * snap_magnitude
		snap_vector = Vector3.DOWN * (Vector3(velocity.x, clamp(velocity.y,0,9999999), velocity.z).length()+5) * snap_magnitude
		
	if Input.is_action_just_pressed("jump") and !noclip and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		#last_col_normal = Vector3.UP
		#velocity.y = JUMP_VELOCITY
		#on_floor = false;
		if on_floor:
			apply_impulse([[null,JUMP_VELOCITY,null], true]) #apply impulse works such that the first item in the array is the velocity (represented in another array of length 3), and the second item is a boolean for if you desire to set the velocity instead of adding to it.
		elif air_jumps > 0: #double jump
			apply_impulse([[null,JUMP_VELOCITY,null], true])
			if input_dir == Vector2.ZERO:
				velocity = Vector3.ZERO*SPEED
				dir = Vector3.ZERO
				air_jumps -= 1
			else:
				velocity = dir*SPEED
				air_jumps -= 1
			
		#snap_vector = Vector3.ZERO
	
	if cached_impulses.size() > 0:
		for i in cached_impulses:
			if i[1] == true:
				if i[0][0] != null:
					velocity.x = i[0][0]
				if i[0][1] != null:
					velocity.y = i[0][1]
				if i[0][2] != null:
					velocity.z = i[0][2]
			else:
				if i[0][0] != null:
					velocity.x += i[0][0]
				if i[0][1] != null:
					velocity.y += i[0][1]
				if i[0][2] != null:
					velocity.z += i[0][2]
			last_col_normal = Vector3.UP
			snap_vector = Vector3.ZERO
		cached_impulses.clear()
	
	$snapVector.set_rotation(- $snapVector.get_parent().rotation)
	$snapVector.target_position = snap_vector;
	if (!noclip):
		var ground_check = null
		var col_normals = []
		if (snap_vector!=Vector3.ZERO): # snap vector is only unset from zero in the "in air" part of this code, where a collision would set it to Vector3.DOWN
			ground_check = move_and_collide(snap_vector*delta, true, 0.001, true, 3)
		if ground_check:
			var normal = ground_check.get_normal()
			last_col_normal = normal;
			wall_collision_normal = Vector3.ZERO
			var ceiling_collision_normal = Vector3.ZERO
			var floor_collision_normal = Vector3.ZERO
			#var collision_remainder = Vector3.ZERO
			for i in range(ground_check.get_collision_count()): #there may be several collisions 
				normal = ground_check.get_normal(i)
				col_normals.push_back(normal)
				if (normal.angle_to(Vector3.UP) <= max_flr_ang): #slope counts as the floor
					var ground_check2 = move_and_collide(Vector3.DOWN*0.005, true, 0.001, true) #we already established that we are on the floor. let's double check. if we aren't, snap down to the floor with a massive snap vector.
					if !ground_check2:
						move_and_collide(Vector3.DOWN*5*delta,false, 0.001, true) #snap
					velocity.y = 0;
					on_floor = true
					floor_collision_normal += normal
					velocity.y = (-normal.z*velocity.z-normal.x*velocity.x)/normal.y
					if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completle`y vertical wall. Good luck with that lol.
						velocity.y = 0
				else: #collision is wall
					#wall_collision_normal = normal
					pass
			### this may need to be done recursivelocityy
			var col = move_and_collide(velocity*delta, true, 0.001, true, 5)
			#if !col:
				#move_and_collide(velocity*delta, false, 0.001, false)
			if col:
				normal = col.get_normal()
				last_col_normal = normal;
				#collision_remainder = col.get_remainder()
				for i in range(col.get_collision_count()):
					normal = col.get_normal(i)
					col_normals.push_back(normal)
					print(rad_to_deg(col.get_angle(i)))
					if (normal.angle_to(Vector3.UP) <= max_flr_ang): #slope counts as the floor
						floor_collision_normal += col.get_normal(i)
				###
					else: #collision is not the floor. it is either a ceiling or a wall.
						if rad_to_deg(col.get_angle(i, Vector3.UP)) > 115: #collision is ceiling
							ceiling_collision_normal += col.get_normal(i)
						else:
							wall_collision_normal += col.get_normal(i)
							#velocity = velocity - ((velocity.dot(normal))/normal.length()) * normal
			if (floor_collision_normal != Vector3.ZERO):
				floor_collision_normal = floor_collision_normal.normalized()
				on_floor = true
				velocity.y = (-floor_collision_normal.z*velocity.z-floor_collision_normal.x*velocity.x)/floor_collision_normal.y
				if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
					velocity.y = 0
				air_jumps = max_air_jumps
			if (wall_collision_normal != Vector3.ZERO):
				wall_collision_normal = wall_collision_normal.normalized()
				on_wall = true
				if floor_collision_normal != Vector3.ZERO:
					wall_collision_normal = Vector3(wall_collision_normal.x,0,wall_collision_normal.z).normalized()
				else:
					velocity.y -= gravity * delta
				velocity = velocity.slide(wall_collision_normal)
				if velocity.y > 0 and floor_collision_normal == Vector3.ZERO:
					velocity.y = 0 #prevent wall climbing
			else:
				on_wall = false
			if (ceiling_collision_normal != Vector3.ZERO):
				ceiling_collision_normal = ceiling_collision_normal.normalized()
				on_ceiling = true
				velocity = velocity.slide(Vector3(ceiling_collision_normal.x, 0, ceiling_collision_normal.z).normalized()) # this will only execute if we are on the ground. this is helpful because we want to slide along it as if it were a wall, and not a ceiling. That way we can actually slide along it and it won't try to push us down into the ground.
			else:
				on_ceiling = false
			#if col:
				#move_and_collide(velocity.normalized() * collision_remainder.length()) #move the remainder of the distnace up the slope
			move_and_collide(velocity*delta, false, 0.001, false)
			$SurfaceNormal.set_rotation(- $SurfaceNormal.get_parent().rotation)
			$SurfaceNormal.target_position = floor_collision_normal*SPEED/5;
			$UI/floor_angle.text = "floor_angle: " + var_to_str(rad_to_deg(floor_collision_normal.angle_to(Vector3.UP)))
		else:
			if previously_on_floor == true and snap_vector != Vector3.ZERO:
				velocity.y = 0 #stop your falling speed from increasing if you slid off a slope.
			on_floor = false
			velocity.y -= gravity * delta
			var col = move_and_collide(velocity*delta, false, 0.001, false, 3)
			if col:
				last_col_normal = col.get_normal()
				var normal = col.get_normal()
				col_normals.push_back(normal)
				for i in range(col.get_collision_count()):
					normal = col.get_normal(i)
					if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91:#ceiling
						velocity = velocity.slide(normal)
						#velocity = velocity - ((velocity.dot(normal))/normal.length()) * normal
					elif (normal.angle_to(Vector3.UP) <= max_flr_ang):#floor
						snap_vector = Vector3.DOWN * (Vector3(velocity.x, clamp(velocity.y,0,9999999), velocity.z).length()+5) * snap_magnitude
					else:#wall
						on_wall = true
						wall_collision_normal = normal
						velocity = velocity.slide(normal)
			else:
				on_wall = false
				on_ceiling = false
	else:
		move_and_collide(velocity*delta) # noclip movement
	previously_on_floor = on_floor
	previous_velocity = velocity
	previous_dir = dir
	$UI/pos.text = "pos: {" + var_to_str(position.x) + ", " + var_to_str(position.y) + ", " + var_to_str(position.z) + "}"
	$UI/velx.text = "velocity.x: " + var_to_str(velocity.x)
	$UI/vely.text = "velocity.y: " + var_to_str(velocity.y)
	$UI/velz.text = "velocity.z: " + var_to_str(velocity.z)
	$UI/velmag.text = "velocity mag: " + var_to_str(Vector3(velocity.x,0,velocity.z).length())
	$UI/on_floor.text = "on_floor: " + var_to_str(on_floor)
	$UI/on_wall.text = "on_wall: " + var_to_str(on_wall)
	$UI/on_ceiling.text = "on_ceiling: " + var_to_str(on_ceiling)
	
	

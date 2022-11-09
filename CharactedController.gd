extends CharacterBody3D


@export_range(0, 100, 1) var SPEED : int = 7
@export var JUMP_vel = 10
@export var ACCELERATION = 20
@export var DECELERATION = 8
var current_acceleration = ACCELERATION
var current_deceleration = DECELERATION
@export var AIR_ACCELERATION = 1
@export var AIR_DECELERATION = 7
var mouse_axis = Vector2.ZERO
var vel = Vector3.ZERO
@export var gravity = Vector3(0,-28,0)
var current_gravity = gravity
var dir = Vector3.ZERO
@export_range(0, 89, 1) var max_floor_angle = 65
var last_col_normal = Vector3.UP
var previous_vel = Vector3.ZERO
var on_floor = false
var on_wall = false
var on_ceiling = false
var in_water = false
var impulse_vel = Vector3.ZERO
var snap_vector = Vector3.ZERO
var snap_magnitude = 0.01
var previous_dir = Vector3.ZERO
var cached_impulses = []
@export var noclip = false
@export var mouse_sensitivity = 0.15#0.05
var wall_collision_normal = Vector3.ZERO #needed so we can choose how we apply the input vel when touching walls
@export var max_air_jumps = 1 #CHANGE THIS VALUE TO ADJUST YOUR MAX AIR JUMPS (SCOUT FROM TF2 HAS 1)
var air_jumps = 0 #DON'T TOUCH THIS VALUE
var input_dir = Vector2.ZERO
var previously_on_floor = false
var hud = null



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
	velocity = Vector3.ZERO
		
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
			in_water = false
		elif in_water:
			dir = ($Torso/Head.get_global_transform().basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		else:
			dir = ($Torso.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	else:
		dir = Vector3.ZERO
		
	var old_vel = vel
	if noclip:
		vel = vel.lerp(dir*SPEED, ACCELERATION * delta)
		if (vel.length() < 0.001): #sigfigs!
			vel = Vector3.ZERO
	else:
		var temp = vel.y
		if (on_floor):
			if (dir.dot(vel) > 0):#(dir != Vector3.ZERO):
				vel = vel.lerp(dir*SPEED, current_acceleration * delta)
			else:
				vel = vel.lerp(dir*SPEED, current_deceleration * delta)
			vel.y = temp
		elif in_water:
			if (dir.dot(vel) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
				vel = vel.lerp(dir*SPEED, current_acceleration * delta)
			else:
				vel = vel.lerp(dir*SPEED, current_deceleration * delta)
		elif !on_wall or Vector3(vel.x,0,vel.z).dot(wall_collision_normal) >= 0: #prevent vel from going up slopes
			if dir == Vector3.ZERO:
				dir = previous_dir # so you don't need to hold a movement key to get the max possible distance
			if (dir.dot(vel) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
				vel = vel.lerp(dir*SPEED, AIR_ACCELERATION * delta)
			else:
				vel = vel.lerp(dir*SPEED, AIR_DECELERATION * delta)
			vel.y = temp
		if (Vector3(vel.x,0,vel.z).length() < 0.001): #sigfigs!
			vel.x = 0
			vel.z = 0
	
	
	if (snap_vector != Vector3.ZERO): # we don't want to snap if we received an impulse (like jumping)!
		snap_vector = Vector3.DOWN * (Vector3(vel.x, clamp(vel.y,0,9999999), vel.z).length()+5) * snap_magnitude
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		if Input.is_action_just_pressed("jump") and !noclip and !in_water:
			if on_floor:
				apply_impulse([[null,JUMP_vel,null], true]) #apply impulse works such that the first item in the array is the vel (represented in another array of length 3), and the second item is a boolean for if you desire to set the vel instead of adding to it.
			elif air_jumps > 0: #double jump
				apply_impulse([[null,JUMP_vel,null], true])
				if input_dir == Vector2.ZERO:
					vel = Vector3.ZERO*SPEED
					dir = Vector3.ZERO
					air_jumps -= 1
				else:
					vel = dir*SPEED
					air_jumps -= 1
		if Input.is_action_pressed("jump") and in_water:
			vel.y = 5		
		if Input.is_action_pressed("jump") and noclip:
			vel.y = SPEED
	
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
	if (!noclip):
		var ground_check = null
		var col_normals = []
		if (snap_vector!=Vector3.ZERO): # snap vector is only unset from zero in the "in air" part of this code, where a collision would set it to Vector3.DOWN
			ground_check = move_and_collide(snap_vector, true, 0.001, true, 3)
		if ground_check:
			var normal = ground_check.get_normal()
			last_col_normal = normal;
			wall_collision_normal = Vector3.ZERO
			var ceiling_collision_normal = Vector3.ZERO
			var floor_collision_normal = Vector3.ZERO
			
			#get the friction of the floor:
			var collider = ground_check.get_collider()
			if !(collider is CSGCombiner3D or (collider is CharacterBody3D and collider is not self)):
				var collider_physics_material = collider.get_physics_material_override()
				var floor_friction = 1;
				if collider_physics_material:
					floor_friction = collider_physics_material.get_friction()
					#re-calculate the on_floor part of the setting input vel:
					vel.x = old_vel.x #ignore our previous vel calculations
					vel.z = old_vel.z
					var temp_vel = vel.y
					if (dir.dot(vel) > 0):
						vel = vel.lerp(dir*SPEED, current_acceleration*floor_friction*delta)
					else:
						vel = vel.lerp(dir*SPEED, current_deceleration*floor_friction*delta)
					vel.y = temp_vel
			
			for i in range(ground_check.get_collision_count()): #there may be several collisions 
				velocity += ground_check.get_collider_velocity(i) # inherit platform velocity
				normal = ground_check.get_normal(i)
				col_normals.push_back(normal)
				if (normal.angle_to(Vector3.UP) <= max_flr_ang): #slope counts as the floor
					var ground_check2 = move_and_collide(Vector3.DOWN*0.005, true, 0.001, true) #we already established that we are on the floor. let's double check. if we aren't, snap down to the floor with a massive snap vector.
					if !ground_check2:
						move_and_collide(Vector3.DOWN*5,false, 0.001, true) #snap
					vel.y = 0;
					on_floor = true
					floor_collision_normal += normal
					vel.y = (-normal.z*vel.z-normal.x*vel.x)/normal.y
					if (normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completle`y vertical wall. Good luck with that lol.
						vel.y = 0
				else: #collision is wall
					#wall_collision_normal = normal
					pass
			### this may need to be done recursively
			var col = move_and_collide(vel*delta, true, 0.001, true, 5)
			if col:
				normal = col.get_normal()
				last_col_normal = normal;
				for i in range(col.get_collision_count()):
					normal = col.get_normal(i)
					col_normals.push_back(normal)
					if (normal.angle_to(Vector3.UP) <= max_flr_ang): #slope counts as the floor
						floor_collision_normal += col.get_normal(i)
						floor_collision_normal = floor_collision_normal.normalized()
				###
					else: #collision is not the floor. it is either a ceiling or a wall.
						if rad_to_deg(col.get_angle(i, Vector3.UP)) > 115: #collision is ceiling
							ceiling_collision_normal += col.get_normal(i)
							ceiling_collision_normal = ceiling_collision_normal.normalized()
						else:
							wall_collision_normal += col.get_normal(i)
							wall_collision_normal = wall_collision_normal.normalized()
			if (floor_collision_normal != Vector3.ZERO):
				on_floor = true
				vel.y = (-floor_collision_normal.z*vel.z-floor_collision_normal.x*vel.x)/floor_collision_normal.y
				if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
					vel.y = 0
				air_jumps = max_air_jumps
			if (wall_collision_normal != Vector3.ZERO):
				on_wall = true
				if floor_collision_normal != Vector3.ZERO:
					wall_collision_normal = Vector3(wall_collision_normal.x,0,wall_collision_normal.z).normalized()
				else:
					vel += current_gravity * delta
				vel = vel.slide(wall_collision_normal)
				if vel.y > 0 and floor_collision_normal == Vector3.ZERO:
					vel.y = 0 #prevent wall climbing
			else:
				on_wall = false
			if (ceiling_collision_normal != Vector3.ZERO):
				on_ceiling = true
				var temp = vel.length()
				vel = vel.normalized()
				vel = vel.slide( Vector3(ceiling_collision_normal.x, 0, ceiling_collision_normal.z).normalized() ) # this will only execute if we are on the ground. this is helpful because we want to slide along it as if it were a wall, and not a ceiling. That way we can actually slide along it and it won't try to push us down into the ground.
				vel *= temp
			else:
				on_ceiling = false
			velocity += vel
			move_and_collide(velocity*delta, false, 0.001, false)
			$SurfaceNormal.set_rotation(- $SurfaceNormal.get_parent().rotation)
			$SurfaceNormal.target_position = floor_collision_normal*SPEED/5;
			#$HUD/floor_angle.text = "floor_angle: " + var_to_str(rad_to_deg(floor_collision_normal.angle_to(Vector3.UP)))
		else:
			if previously_on_floor == true and snap_vector != Vector3.ZERO:
				vel.y = 0 #stop your falling speed from increasing if you slid off a slope.
			on_floor = false
			
			if !(in_water and dir.length() > 0):
				vel += current_gravity * delta
			velocity += vel
			var col = move_and_collide(velocity*delta, false, 0.001, false, 3)
			if col:
				last_col_normal = col.get_normal()
				var normal = col.get_normal()
				col_normals.push_back(normal)
				for i in range(col.get_collision_count()):
					normal = col.get_normal(i)
					if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91:#ceiling
						vel = vel.slide(normal)
						#vel = vel - ((vel.dot(normal))/normal.length()) * normal
					elif (normal.angle_to(Vector3.UP) <= max_flr_ang) and !in_water:#floor
						snap_vector = Vector3.DOWN * (Vector3(vel.x, clamp(vel.y,0,9999999), vel.z).length()+5) * snap_magnitude
					else:#wall
						on_wall = true
						wall_collision_normal = normal
						vel = vel.slide(normal)
			else:
				on_wall = false
				on_ceiling = false
	else:
		move_and_collide(vel*delta) # noclip movement
	previously_on_floor = on_floor
	previous_vel = vel
	previous_dir = dir
	hud = $UI
	if (hud):
		hud.get_node("pos").text = "pos: {" + var_to_str(position.x) + ", " + var_to_str(position.y) + ", " + var_to_str(position.z) + "}"
		hud.get_node("velx").text = "vel.x: " + var_to_str(velocity.x)
		hud.get_node("vely").text = "vel.y: " + var_to_str(velocity.y)
		hud.get_node("velz").text = "vel.z: " + var_to_str(velocity.z)
		hud.get_node("velmag").text = "vel mag: " + var_to_str(Vector3(velocity.x,velocity.y,velocity.z).length())
		hud.get_node("on_floor").text = "on_floor: " + var_to_str(on_floor)
		hud.get_node("on_wall").text = "on_wall: " + var_to_str(on_wall)
		hud.get_node("on_ceiling").text = "on_ceiling: " + var_to_str(on_ceiling)
	


func _on_area_3d_area_entered(area):
	if area.get_meta("medium_type") == "water":
		in_water = true
		current_gravity = gravity * 0.4
		print(current_gravity)
		current_acceleration = 3
		snap_vector = Vector3.ZERO
	else:
		current_gravity = area.gravity_direction * area.gravity
		print(current_gravity)
		current_acceleration = ACCELERATION - area.linear_damp


func _on_area_3d_area_exited(area):
	if area.get_meta("medium_type") == "water":
		in_water = false
	snap_vector = Vector3.DOWN * (Vector3(vel.x, clamp(vel.y,0,9999999), vel.z).length()+5) * snap_magnitude
	current_gravity = gravity
	current_acceleration = ACCELERATION

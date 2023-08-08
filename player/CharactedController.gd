class_name CharacterController extends CharacterBody3D

@export_range(0, 100, 0.1) var SPEED := 10.0:
	set(value):
		SPEED = value
		if !crouched:
			current_speed = SPEED
		else:
			CROUCH_SPEED = SPEED/3
			current_speed = CROUCH_SPEED
@export var CROUCH_SPEED = SPEED/3
var current_speed = SPEED
@export var vel = Vector3(0,0,0)
@export var JUMP_vel = 10
@export var ACCELERATION := 15:
	set(value):
		ACCELERATION = value
		if !crouched:
			current_acceleration = ACCELERATION
@export var DECELERATION := 5.5:
	set(value):
		DECELERATION = value
		if !crouched:
			current_deceleration = DECELERATION
@export var STRAFE_DECELERATION := 10:
	set(value):
		STRAFE_DECELERATION = value
		if !crouched:
			current_strafe_deceleration = STRAFE_DECELERATION
var current_acceleration = ACCELERATION
var current_deceleration = DECELERATION
var current_strafe_deceleration = STRAFE_DECELERATION
@export var AIR_ACCELERATION = 1
@export var AIR_DECELERATION = 2
@export var AIR_STRAFE_ACCELERATION = 4
@export var mouse_axis = Vector2.ZERO
@export var gravity := Vector3(0,-28,0):
	set(value):
		current_gravity = value
var current_gravity = gravity
var dir = Vector3.ZERO
@export_range(0, 89, 1) var max_floor_angle := 60:
	set(value):
		max_flr_ang_rad = deg_to_rad(value)
var max_flr_ang_rad = deg_to_rad(max_floor_angle)
var previous_vel = Vector3.ZERO
var on_floor = false
var on_wall = false
var on_ceiling = false
var in_water = false
var impulse_vel = Vector3.ZERO
var snap_vector = Vector3.ZERO
var snap_magnitude = 1#0.5
var previous_dir = Vector3.ZERO
@export var noclip = false
@onready var mouse_sensitivity = 0.05
var wall_collision_normal = Vector3.ZERO #needed so we can choose how we apply the input vel when touching walls
var ceiling_collision_normal = Vector3.ZERO
var floor_collision_normal = Vector3.ZERO
@export var max_air_jumps = 0 #CHANGE THIS VALUE TO ADJUST YOUR MAX AIR JUMPS (SCOUT FROM TF2 HAS 1)
@export var max_wall_jumps = 0
var air_jumps = 0 #DON'T TOUCH THIS VALUE
var wall_jumps = 0 #DON'T TOUCH THIS VALUE
var input_dir = Vector2.ZERO
var previously_on_floor = false
var debug = null
var in_area = false
var inherited_vel = Vector3.ZERO
@export var stair_step_height = 1.0
@onready var collisionHull = $CollisionHull.shape
@onready var originalCollisionHull = collisionHull.duplicate()
@onready var originalHeadPosition = $Torso/Head.position
@onready var FootStepPlayer = $FootStepPlayer
@onready var SoundEffectPlayer = $SoundEffectPlayer
@export var crouchHeight = 0.75
var uncrouch_check_run = false
@export var crouched = false
@onready var trace = Trace.new()
var ceiling_collision_normals = []


func crouch():
	if !crouched:
		collisionHull.size = Vector3(collisionHull.size.x, crouchHeight, collisionHull.size.z)
		$Area3D/CollisionHull.shape.size = Vector3(collisionHull.size.x, crouchHeight, collisionHull.size.z)
		position.y -= ((originalCollisionHull.size.y - crouchHeight)/2)-0.01
		CROUCH_SPEED = SPEED/3
		current_speed = CROUCH_SPEED
		current_deceleration = DECELERATION*3
		current_strafe_deceleration = STRAFE_DECELERATION*3
		$Torso/Head.position.y = originalHeadPosition.y - ((originalCollisionHull.size.y - crouchHeight)/2)
	
		if on_floor:
			move_and_collide(Vector3(0,-1,0))
		#else:
			#position.y -= ((originalCollisionHullSize.y/2)-crouchHeight/2)
		crouched = true

func uncrouch_check(): #checks if the player can uncrouch. if yes, proceeds to uncrouch the player.
	if crouched:
		var uncrouchShape = BoxShape3D.new()
		uncrouchShape.size = originalCollisionHull.size
		trace.intersect_groups(Vector3(position.x,position.y+((originalCollisionHull.size.y/2)-crouchHeight/2),position.z), uncrouchShape, self, 0x1)
		if trace.hit == false:
			position.y += (originalCollisionHull.size.y - crouchHeight)/2
			collisionHull.size = Vector3(originalCollisionHull.size.x, originalCollisionHull.size.y, originalCollisionHull.size.z)
			$Area3D/CollisionHull.shape.size = Vector3(originalCollisionHull.size.x, originalCollisionHull.size.y, originalCollisionHull.size.z)
			$Torso/Head.position.y = originalHeadPosition.y
			current_speed = SPEED
			current_deceleration = DECELERATION
			current_strafe_deceleration = STRAFE_DECELERATION
			uncrouch_check_run = false
			crouched = false
		else:
			uncrouch_check_run = true
			crouched = true

func _input(event: InputEvent):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			
		if event.is_action_pressed("crouch"):
			crouch()
				
		if event.is_action_released("crouch"):
			uncrouch_check()
			
		if event is InputEventMouseMotion:
			mouse_axis = event.relative
			
			var horizontal: float = -mouse_axis.x * mouse_sensitivity
			var vertical: float = -mouse_axis.y * mouse_sensitivity
				
			mouse_axis = Vector2(0,0)
			$Torso.rotate_y(deg_to_rad(horizontal))
			$Torso/Head.rotate_x(deg_to_rad(vertical))
			$Torso/Head.rotation.x = clamp($Torso/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func apply_impulse(vector: Vector3, position: Vector3 = Vector3.ZERO):
	
	vel += vector
	snap_vector = Vector3.ZERO

func floor_collision_solver(delta):
	vel.y = 0
	vel.y = (-floor_collision_normal.z*vel.z-floor_collision_normal.x*vel.x)/floor_collision_normal.y
	if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
		vel.y = 0
	pass

func ceiling_collision_solver(delta):
	if (wall_collision_normal != Vector3.ZERO):
		var wall_floor_tangent = wall_collision_normal.cross(floor_collision_normal).normalized()
		vel = wall_floor_tangent * vel.dot(wall_floor_tangent)
		var ceiling_floor_tangent = ceiling_collision_normal.cross(floor_collision_normal).normalized()
		if wall_floor_tangent.dot(ceiling_floor_tangent) <= 0:
			vel.x = 0
			vel.z = 0
		else:
			vel = ceiling_floor_tangent * vel.dot(ceiling_floor_tangent)
		
		ceiling_floor_tangent = ceiling_collision_normal.cross(floor_collision_normal).normalized()
		vel = ceiling_floor_tangent * vel.dot(ceiling_floor_tangent)
		
	else:
		var ceiling_floor_tangent = ceiling_collision_normal.cross(floor_collision_normal).normalized()
		vel = ceiling_floor_tangent * vel.dot(ceiling_floor_tangent)

func wall_collision_solver(delta):
	#do the stair stepping check before treating the collision like a wall!
	if ceiling_collision_normal == Vector3.ZERO:
		if (vel.length() > 0):
				
			#make a new collision hull that is slightly wider (so we can step even with low velocities and not get false negatives)
			var StairStepShape = BoxShape3D.new()
			StairStepShape.size = collisionHull.size
			
			# Get destination position that is one step-size above the intended move
			var dest = position + Vector3(vel.x * delta, stair_step_height, vel.z * delta) # if your vel isn't large enough, this won't work :(
				
			# 1st Trace: check for collisions one stepsize above the original position
			var up = position + Vector3.UP * stair_step_height
			trace.standard(position, up, StairStepShape, self, 9)
				
			dest.y = trace.endpos.y
				
			# 2nd Trace: Check for collisions one stepsize above the original position
			# and along the intended destination
			trace.standard(trace.endpos, dest, StairStepShape, self, 9)
				
			# 3rd Trace: Check for collisions below the stepsize until 
			# level with original position
			var down = Vector3(trace.endpos.x, position.y, trace.endpos.z)
			trace.standard(trace.endpos, down, StairStepShape, self, 9)
				
			# Move to trace collision position if step is higher than original position and not steep 
			if trace.endpos.y > position.y and trace.normal.angle_to(Vector3.UP) <= max_flr_ang_rad: #stair step sucessful, not a wall.
				global_transform.origin = trace.endpos
				on_wall = false
				wall_collision_normal = Vector3.ZERO
			else:
				if ceiling_collision_normal == Vector3.ZERO:
					on_wall = true
					if on_floor:
						var wall_floor_tangent = wall_collision_normal.cross(floor_collision_normal).normalized()
						vel = wall_floor_tangent * vel.dot(wall_floor_tangent)
					else:
						vel += current_gravity * delta
						vel = vel.slide(wall_collision_normal)
					if vel.y > 0 and floor_collision_normal == Vector3.ZERO:
						vel.y = 0 #prevent wall climbing
		
func ground_movement(delta, ground_check):
	inherited_vel = ground_check.get_collider_velocity() # inherit platform velocity
	move_and_collide(inherited_vel*delta)
	FootStepPlayer.update_groundtype(ground_check)
	floor_collision_normal = Vector3.ZERO
	var snap_ground_check = move_and_collide(snap_vector*0.001, true, 0.001, false, 5) #we already established that we are on the floor. let's double check. if we aren't, snap down to the floor with a massive snap vector. The (1+(delta*10)) makes the snap vector larger if your physics frame rate is low, with a multiplier limit of 1.
	if !snap_ground_check: #this prevents small false positives from adding up and making the player appear to slide down a slope even with zero velocity
		snap_ground_check = move_and_collide(snap_vector*snap_magnitude, false, 0.001, false, 5) 
	if snap_ground_check:
		var average_normal = Vector3.ZERO
		for i in range(snap_ground_check.get_collision_count()):
			var normal = snap_ground_check.get_normal(i)
			if (normal.angle_to(Vector3.UP) <= max_flr_ang_rad):
				floor_collision_normal = normal
			elif rad_to_deg(normal.angle_to(Vector3.UP)) < 91:
				average_normal += normal
		var fallback_average_normal = average_normal
		average_normal = average_normal.normalized()
		$AverageNormal.set_rotation(- $AverageNormal.get_parent().rotation)
		$AverageNormal.target_position = average_normal;
		if (average_normal != Vector3.ZERO):
			if (average_normal.angle_to(Vector3.UP) <= max_flr_ang_rad):
				floor_collision_normal = average_normal
			else:
				var verticalwallcol = move_and_collide(Vector3(average_normal.x,0,average_normal.z), true, 0.001, true) #this is for the edge case of if the "slope" that we consider to be too steep to be a floor averages to not be a floor, but there is still the possibility that we are wedged between a steep slop and a perfectly straight wall. this straight wall's normal would not have been reported until now because the gorund check only checks under the player.
				if verticalwallcol:
					fallback_average_normal += verticalwallcol.get_normal()
					fallback_average_normal = fallback_average_normal.normalized()
					if (fallback_average_normal.angle_to(Vector3.UP) <= max_flr_ang_rad):
						floor_collision_normal = fallback_average_normal
		if floor_collision_normal != Vector3.ZERO:
			wall_collision_normal = Vector3.ZERO
			on_floor = true
			air_jumps = max_air_jumps
			wall_jumps = max_wall_jumps
			vel.y = 0
			vel.y = (-floor_collision_normal.z*vel.z-floor_collision_normal.x*vel.x)/floor_collision_normal.y
			if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
				vel.y = 0
		else:
			on_floor = false
			if !previously_on_floor:
				snap_vector = Vector3.ZERO
		
		var collider = ground_check.get_collider() # change friction
		if !(collider is CSGCombiner3D or (collider is CharacterBody3D and collider != self)):
			var collider_physics_material = collider.get_physics_material_override()
			var floor_friction = 1;
			if collider_physics_material:
				floor_friction = collider_physics_material.get_friction()
				#re-calculate the on_floor part of the setting input vel:
				current_acceleration = ACCELERATION * floor_friction
				current_deceleration = DECELERATION * floor_friction
				current_strafe_deceleration = STRAFE_DECELERATION * floor_friction
			else:
				current_acceleration = ACCELERATION
				current_deceleration = DECELERATION
				current_strafe_deceleration = STRAFE_DECELERATION
		elif !in_area:
				current_acceleration = ACCELERATION
				current_deceleration = DECELERATION
				current_strafe_deceleration = STRAFE_DECELERATION
		
		var col = move_and_collide(vel*delta, true, 0.001, true, 4)
		var floor_collision_normal_override = Vector3.ZERO
		var wall_collision_normal_override = Vector3.ZERO
		var ceiling_collision_normal_override = Vector3.ZERO
		#var floor_collision_normal_overrides = []
		#var wall_collision_normal_overrides = []
		if col:
			wall_collision_normal = Vector3.ZERO
			ceiling_collision_normal = Vector3.ZERO
			for i in range(col.get_collision_count()):
				var normal = col.get_normal(i)
				if (normal.angle_to(Vector3.UP) <= max_flr_ang_rad): #slope counts as the floor
					floor_collision_normal_override = normal
					#floor_collision_normal_override += col.get_normal(i)
					#floor_collision_normal_overrides.append(floor_collision_normal_override)
				else: #collision is not the floor. it is either a ceiling or a wall.
					if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91: #collision is ceiling
						ceiling_collision_normal_override = normal
						#ceiling_collision_normal += col.get_normal(i)
						#ceiling_collision_normals.append(ceiling_collision_normal)
					else: #collision is wall
						wall_collision_normal_override = normal
						#wall_collision_normal_override += col.get_normal(i)
						#wall_collision_normal_overrides.append(wall_collision_normal_override)
						
			#if floor_collision_normal_overrides.size() > 0:
			#	floor_collision_normal_override /= floor_collision_normal_overrides.size()
			#	floor_collision_normal = floor_collision_normal_override.normalized()
				
			#if ceiling_collision_normals.size() > 0:	
			#	ceiling_collision_normal /= ceiling_collision_normals.size()
			#	ceiling_collision_normal = ceiling_collision_normal.normalized()
				
			#if wall_collision_normal_overrides.size() > 0:
				#print(wall_collision_normal_overrides)
				#wall_collision_normal_override /= wall_collision_normal_overrides.size()
			#	wall_collision_normal = wall_collision_normal_override.normalized()
			
			if (ceiling_collision_normal_override != Vector3.ZERO):
				on_ceiling = true
				ceiling_collision_normal = ceiling_collision_normal_override
				ceiling_collision_solver(delta)
			else:
				on_ceiling = false
			if wall_collision_normal_override != Vector3.ZERO:
				wall_collision_normal = wall_collision_normal_override
				wall_collision_solver(delta)
			if floor_collision_normal_override != Vector3.ZERO:
				floor_collision_normal = floor_collision_normal_override
				floor_collision_solver(delta)

func air_movement(delta):
	if !in_area:
		current_acceleration = ACCELERATION
		current_deceleration = DECELERATION
		
	if previously_on_floor:
		if snap_vector != Vector3.ZERO:
			vel.y = 0 #stop your falling speed from increasing if you slid off a slope.
		snap_vector = Vector3.ZERO
	on_floor = false
	
	if !(in_water and dir.length() > 0):
		vel += current_gravity * delta
	velocity = vel #+ inherited_vel
	var col = move_and_collide(velocity*delta, true, 0.001, true, 5)
	if col:
		var ground_collision_normals = []
		var average_normal = Vector3.ZERO
		for i in range(col.get_collision_count()):
			var normal = col.get_normal(i)
			ground_collision_normals.append(normal)
			average_normal += col.get_normal(i)
		average_normal /= col.get_collision_count()
		average_normal = average_normal.normalized() # just in case
		$AverageNormal.set_rotation(- $AverageNormal.get_parent().rotation)
		$AverageNormal.target_position = average_normal;
		if (average_normal.angle_to(Vector3.UP) <= max_flr_ang_rad):
			floor_collision_normal = average_normal	
			
		if (average_normal.angle_to(Vector3.UP)) > 91:#ceiling
			vel = vel.slide(average_normal)
			#vel = vel - ((vel.dot(normal))/normal.length()) * normal
		elif (average_normal.angle_to(Vector3.UP) <= max_flr_ang_rad) and !in_water:#floor
			snap_vector = Vector3.DOWN
			FootStepPlayer.update_groundtype(col)
			$SoundEffectPlayer2.play_sound(FootStepPlayer.getRandomFootstepPath(FootStepPlayer.groundtype), 0.9, 1)
			if (vel.y < -100):
				SoundEffectPlayer.play_sound("sound/player/fallpain_intense.wav")
			elif (vel.y < -30):
				SoundEffectPlayer.play_sound("sound/player/fallpain.wav")
		else:#wall
			on_wall = true
			wall_collision_normal = average_normal
			vel = vel.slide(average_normal)
	else:
		on_wall = false
		on_ceiling = false

func input_direction_to_vel_solver(delta):
	
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
	$InputDirection.set_rotation(- $InputDirection.get_parent().rotation)
	$InputDirection.target_position = dir*current_speed
	if noclip:
		vel = vel.lerp(dir*current_speed, ACCELERATION * delta)
		if (vel.length() < 0.1) and (vel.length() < previous_vel.length()): #sigfigs! if we are decelerating and our velocity's magnitude is less than 0.1, just stop.
			vel = Vector3.ZERO
	
	#jump_if_desired(delta)
	
	var temp = vel.y
	var velxz = Vector3(vel.x,0,vel.z)
	
	var accel_step = ((1) if (current_acceleration * delta > 1) else (current_acceleration * delta))
	var decel_step = ((1) if (current_deceleration * delta > 1) else (current_deceleration * delta))
	var strafe_accel_step = ((1) if (current_strafe_deceleration * delta > 1) else (current_strafe_deceleration * delta))
	
	if (on_floor):
		if (dir.dot(velxz) < 0): #player is trying to move in the opposite direction he is moving
			vel = vel.lerp(dir*current_speed, strafe_accel_step)
		elif (dir != Vector3.ZERO) and (velxz.length() <= (dir*current_speed).length()): #player trying to move
			vel = vel.lerp(dir*current_speed, accel_step)
		else: #player is not trying to move
			vel = vel.lerp(dir*current_speed, decel_step)
		vel.y = temp
	elif in_water:
		if (dir.dot(velxz) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
			vel = vel.lerp(dir*current_speed, accel_step)
		else:
			vel = vel.lerp(dir*current_speed, decel_step)
	elif !on_wall or velxz.dot(wall_collision_normal) >= 0: #prevent vel from going up slopes
		var vel_length = velxz.length()
		if dir == Vector3.ZERO:
			dir = Vector3(vel.x,0,vel.z)/current_speed
		if (dir.dot(velxz) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
			vel = vel.lerp(dir*current_speed, AIR_STRAFE_ACCELERATION * delta)
			if Vector3(vel.x,0,vel.z).length() < vel_length:
				vel = Vector3(vel.x,0,vel.z).normalized() * vel_length # air movement does not affect the velocity length, only the rotation.
			else:
				vel = velxz.lerp(dir*current_speed, AIR_ACCELERATION * delta)
			
		else:
			vel = vel.lerp(dir*current_speed, AIR_DECELERATION * delta)
		vel.y = temp
		
	velxz = Vector3(vel.x,0,vel.z)
	if (velxz.length() < 0.1) and (velxz.length() < Vector3(previous_vel.x,0,previous_vel.z).length()): #sigfigs! if we are decelerating and our velocity's magnitude is less than 0.1, just stop.
		vel.x = 0
		vel.z = 0

func jump_if_desired(delta):
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: #JUMPING CODE
		
		if Input.is_action_just_pressed("jump") and !noclip and !in_water:
			if on_floor:
				vel.y = 0
				var impulse_vel = Vector3(0,JUMP_vel,0)# + dir*5
				if (inherited_vel.y > 0):
					impulse_vel.y += impulse_vel.y
				impulse_vel += Vector3(inherited_vel.x, 0, inherited_vel.z)
				apply_impulse(impulse_vel)
				
				$SoundEffectPlayer2.play_sound(FootStepPlayer.getRandomFootstepPath(FootStepPlayer.groundtype), 1.1, 1)
			elif on_wall and wall_jumps > 0:
				apply_impulse(((wall_collision_normal * 5) + (Vector3.UP * JUMP_vel)) + vel.slide(wall_collision_normal) * Vector3(1,0,1))
				wall_jumps -= 1
			elif air_jumps > 0: #double jump
				vel.y = 0
				vel = Vector3.ZERO
				apply_impulse(dir*current_speed + Vector3(0,JUMP_vel,0))
				air_jumps -= 1
		if Input.is_action_pressed("jump") and in_water:
			vel.y = 5		
		if Input.is_action_pressed("jump") and noclip:
			vel.y = current_speed

func _physics_process(delta):

	if uncrouch_check_run:
		uncrouch_check()
		
	jump_if_desired(delta)
	
	input_direction_to_vel_solver(delta)
			
	if (snap_vector != Vector3.ZERO): # we don't want to snap if we received an impulse (like jumping)!
		snap_vector = Vector3.DOWN

	if (!noclip):
		inherited_vel = Vector3.ZERO
		var ground_check = null
		if (snap_vector != Vector3.ZERO): # snap vector is only unset from zero in the "in air" part of this code, where a collision would set it to Vector3.DOWN
			ground_check = move_and_collide(snap_vector*snap_magnitude*(1+(delta*10)), true, 0.001, true, 5) # ground check == true does not nessesarily mean that we are on the floor. we need to double check with the snap check
		if ground_check:
			ground_movement(delta, ground_check)
		else:
			air_movement(delta)
	else:
		move_and_collide(vel*delta) # noclip movement
	velocity = vel
	move_and_collide(velocity*delta)
		
	previously_on_floor = on_floor
	previous_vel = vel
	previous_dir = dir
	if (debug):
		debug.get_node("pos").text = "pos: {" + var_to_str(position.x) + ", " + var_to_str(position.y) + ", " + var_to_str(position.z) + "}"
		debug.get_node("velx").text = "vel.x: " + var_to_str(velocity.x+inherited_vel.x)
		debug.get_node("vely").text = "vel.y: " + var_to_str(velocity.y+inherited_vel.y)
		debug.get_node("velz").text = "vel.z: " + var_to_str(velocity.z+inherited_vel.z)
		debug.get_node("velmag").text = "vel mag: " + var_to_str(Vector3(velocity.x,0,velocity.z).length())
		debug.get_node("on_floor").text = "on_floor: " + var_to_str(on_floor)
		debug.get_node("on_wall").text = "on_wall: " + var_to_str(on_wall)
		debug.get_node("on_ceiling").text = "on_ceiling: " + var_to_str(on_ceiling)
		debug.get_node("in_water").text = "in_water: " + var_to_str(in_water)
		debug.get_node("snapvector").text = "snap_vector: " + var_to_str(snap_vector)
		debug.get_node("floor_normal").text = "floor_normal: " + var_to_str(floor_collision_normal)
		debug.get_node("wall_normal").text = "wall_normal: " + var_to_str(wall_collision_normal)
		debug.get_node("ceiling_normal").text = "ceiling_normal: " + var_to_str(ceiling_collision_normal)
		debug.get_node("air_jumps").text = "air_jumps: " + var_to_str(air_jumps)
	
	
	
	$Velocity.set_rotation(- $Velocity.get_parent().rotation)
	$Velocity.target_position = vel;

func _on_area_3d_area_entered(area):
	in_area = true
	if area.get_meta("medium_type") == "water":
		in_water = true
		current_gravity = gravity * 0.4
		current_acceleration = 3
		snap_vector = Vector3.ZERO
	else:
		current_gravity = area.gravity_direction * area.gravity
		current_acceleration = ACCELERATION - area.linear_damp

func _on_area_3d_area_exited(area):
	in_area = false
	if area.get_meta("medium_type") == "water":
		in_water = false
	snap_vector = Vector3.DOWN
	current_gravity = gravity
	current_acceleration = ACCELERATION

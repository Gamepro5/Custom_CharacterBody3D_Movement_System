extends CharacterBody3D

# CREDITS:
# Code by Gamepro5 (https://gamepro5.com)
 
@export_range(0, 100, 0.1) var SPEED : float = 7
@export var CROUCH_SPEED = SPEED/3
var current_speed = SPEED
@export var JUMP_vel = 10
@export var ACCELERATION = 15#8.5725
@export var DECELERATION = 5.5
@export var STRAFE_DECELERATION = 10
var current_acceleration = ACCELERATION
var current_deceleration = DECELERATION
var current_strafe_deceleration = STRAFE_DECELERATION
@export var AIR_ACCELERATION = 3
@export var AIR_DECELERATION = 15
@export var AIR_STRAFE_ACCELERATION = 1
var mouse_axis = Vector2.ZERO
var vel = Vector3.ZERO
@export var gravity = Vector3(0,-28,0)
var current_gravity = gravity
var dir = Vector3.ZERO
@export_range(0, 89, 1) var max_floor_angle = 65
var previous_vel = Vector3.ZERO
var on_floor = false
var on_wall = false
var on_ceiling = false
var in_water = false
var impulse_vel = Vector3.ZERO
var snap_vector = Vector3.ZERO
var snap_magnitude = 1
var previous_dir = Vector3.ZERO
var cached_impulses = []
@export var noclip = false
@export var mouse_sensitivity = 0.15#0.05
var wall_collision_normal = Vector3.ZERO #needed so we can choose how we apply the input vel when touching walls
var ceiling_collision_normal = Vector3.ZERO
var floor_collision_normal = Vector3.ZERO
@export var max_air_jumps = 0 #CHANGE THIS VALUE TO ADJUST YOUR MAX AIR JUMPS (SCOUT FROM TF2 HAS 1)
@export var max_wall_jumps = 0
var air_jumps = 0 #DON'T TOUCH THIS VALUE
var wall_jumps = 0 #DON'T TOUCH THIS VALUE
var input_dir = Vector2.ZERO
var previously_on_floor = false
@onready var hud = $UI
var in_area = false
var inherited_vel = Vector3.ZERO
var stair_step_height = 1.5
@onready var collisionHull = $CollisionHull
@onready var originalCollisionHullSize = $CollisionHull.shape.size

@export var crouchHeight = 1
var uncrouch_check_run = false
var crouched = false
@onready var trace = Trace.new()

func crouch():
	if !crouched:
		collisionHull.shape.size.y = crouchHeight
		$Area3D/CollisionHull.shape.size.y = crouchHeight
		current_speed = CROUCH_SPEED
		position.y += 0.5
		$Torso.position.y = -0.5
		if on_floor:
			move_and_collide(Vector3(0,-1,0))
		crouched = true

func uncrouch_check(): #checks if the player can uncrouch. if yes, proceeds to uncrouch the player.
	if crouched:
		var uncrouchShape = BoxShape3D.new()
		uncrouchShape.size = Vector3(originalCollisionHullSize.x-0.01, originalCollisionHullSize.y, originalCollisionHullSize.z-0.01)
		trace.intersect_groups(Vector3(position.x,position.y+0.5+0.01,position.z), uncrouchShape, self, 0x1)
		if trace.hit == false:
			position.y += 0.5
			$Torso.position.y = 0
			collisionHull.shape.size.y = originalCollisionHullSize.y
			$Area3D/CollisionHull.shape.size.y = originalCollisionHullSize.y
			current_speed = SPEED
			uncrouch_check_run = false
			crouched = false
		else:
			uncrouch_check_run = true
			crouched = true

func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("mouse_input"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
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
			
			
#func apply_impulse(vect: Array):
	#cached_impulses.append(vect)
	#vel += cached_impulses
func apply_impulse(vector: Vector3, position: Vector3 = Vector3.ZERO):
	vel += vector
	snap_vector = Vector3.ZERO
	
func _ready():
	print(pow(2, 1-1))
	#Engine.set_time_scale(0.1)
	pass
	


func accelerate(accel, deltat):
	var wishspeed = current_speed#
	var currentspeed = Vector3(vel.x,0,vel.z).dot(dir)
	var addspeed = wishspeed - currentspeed
	
	if addspeed <= 0:
		return
	
	var accelspeed = accel * deltat * wishspeed * 1
	
	if (accelspeed > addspeed):
		accelspeed = addspeed
	
	vel += dir * accelspeed

func _physics_process(delta):
	inherited_vel = Vector3.ZERO
	var old_pos = position
		
	var max_flr_ang = deg_to_rad(max_floor_angle)
	
	if uncrouch_check_run:
		uncrouch_check()
	
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
			
	if (snap_vector != Vector3.ZERO): # we don't want to snap if we received an impulse (like jumping)!
		snap_vector = Vector3.DOWN * snap_magnitude
		
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED: #JUMPING CODE
		
		if Input.is_action_just_pressed("jump") and !noclip and !in_water:
			if on_floor:
				vel.y = 0
				apply_impulse(dir*current_speed + Vector3(0,JUMP_vel,0))
			elif on_wall and wall_jumps > 0:
				apply_impulse(((wall_collision_normal * 5) + (Vector3.UP * JUMP_vel)) + vel.slide(wall_collision_normal) * Vector3(1,0,1))
				wall_jumps -= 1
			elif air_jumps > 0: #double jump
				vel.y = 0
				if input_dir == Vector2.ZERO:
					apply_impulse(dir*current_speed + Vector3(0,JUMP_vel,0))
				else:
					vel = Vector3.ZERO
					apply_impulse(dir*current_speed + Vector3(0,JUMP_vel,0))
				air_jumps -= 1
		if Input.is_action_pressed("jump") and in_water:
			vel.y = 5		
		if Input.is_action_pressed("jump") and noclip:
			vel.y = current_speed
	
	
	var temp = vel.y
		
	
		
		
		
	var velxz = Vector3(vel.x,0,vel.z)
	
	
	
	var accel_step = ((1) if (current_acceleration * delta > 1) else (current_acceleration * delta))
	var decel_step = ((1) if (current_deceleration * delta > 1) else (current_deceleration * delta))
	var strafe_accel_step = ((1) if (current_strafe_deceleration * delta > 1) else (current_strafe_deceleration * delta))
	
	if (on_floor):
		if (dir.dot(vel) < 0): #player is trying to move in the opposite direction he is moving
			vel = vel.lerp(dir*current_speed, strafe_accel_step)
		elif (dir != Vector3.ZERO): #player trying to move
			vel = vel.lerp(dir*current_speed, accel_step)
		else: #player is not trying to move
			vel = vel.lerp(dir*current_speed, decel_step)
		vel.y = temp
	elif in_water:
		if (dir.dot(vel) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
			vel = vel.lerp(dir*current_speed, accel_step)
		else:
			vel = vel.lerp(dir*current_speed, decel_step)
	elif !on_wall or velxz.dot(wall_collision_normal) >= 0: #prevent vel from going up slopes
		var vel_length = velxz.length()
		if dir == Vector3.ZERO:
			dir = Vector3(vel.x,0,vel.z)/current_speed
		if (dir.dot(vel) > 0) && dir != Vector3.ZERO: # makes it easy to stop your trajectory, but if you wish to change, you won't be able to super well. this is similar to tf2.
			vel = vel.lerp(dir*current_speed, AIR_ACCELERATION * delta)
			vel = Vector3(vel.x,0,vel.z).normalized() * vel_length # air movement does not affect the velocity length, only the rotation.
		else:
			vel = vel.lerp(dir*current_speed, AIR_DECELERATION * delta)
		vel.y = temp
	if (Vector3(vel.x,0,vel.z).length() < 0.1) and (Vector3(vel.x,0,vel.z).length() < Vector3(previous_vel.x,0,previous_vel.z).length()): #sigfigs! if we are decelerating and our velocity's magnitude is less than 0.1, just stop.
		vel.x = 0
		vel.z = 0
	
	
	$snapVector.set_rotation(- $snapVector.get_parent().rotation)
	$snapVector.target_position = snap_vector;
	if (!noclip):
		var before_ground_check_vel = vel
		var ground_check = null
		if (snap_vector != Vector3.ZERO): # snap vector is only unset from zero in the "in air" part of this code, where a collision would set it to Vector3.DOWN
			ground_check = move_and_collide(snap_vector*snap_magnitude*(1+(delta*10)), true, 0.001, true, 5) # ground check == true does not nessesarily mean that we are on the floor. we need to double check with the snap check
		if ground_check:
			hud.get_node("groundcheck").text = "groundcheck: true"
			wall_collision_normal = Vector3.ZERO
			floor_collision_normal = Vector3.ZERO
			ceiling_collision_normal = Vector3.ZERO
			#for i in range(ground_check.get_collision_count()):
				#var normal = ground_check.get_normal(i)
				#if (normal.angle_to(Vector3.UP) <= max_flr_ang):
					#floor_collision_normal = normal
			floor_collision_normal = Vector3.UP
			if floor_collision_normal != Vector3.ZERO:
				floor_collision_normal = Vector3.ZERO
				if vel.length() > 0:
					var snap_ground_check = move_and_collide(snap_vector*0.001*(1+(delta*10)), true, 0.001, true, 3) #we already established that we are on the floor. let's double check. if we aren't, snap down to the floor with a massive snap vector. The (1+(delta*10)) makes the snap vector larger if your physics frame rate is low, with a multiplier limit of 1.
					if !snap_ground_check:
						snap_ground_check = move_and_collide(snap_vector*snap_magnitude*(1+(delta*10)), false, 0.001, false, 3)
					if snap_ground_check:
						for i in range(snap_ground_check.get_collision_count()):
							var normal = snap_ground_check.get_normal(i)
							if (normal.angle_to(Vector3.UP) <= max_flr_ang):
								floor_collision_normal = normal	
						if floor_collision_normal != Vector3.ZERO:
							on_floor = true
							vel.y = 0;
							vel.y = (-floor_collision_normal.z*vel.z-floor_collision_normal.x*vel.x)/floor_collision_normal.y
							if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completle`y vertical wall. Good luck with that lol.
								vel.y = 0
						else:
							on_floor = false
							if !previously_on_floor:
								snap_vector = Vector3.ZERO
							
					else:
						on_floor = false
						snap_vector = Vector3.ZERO
			else:
				on_floor = false
				snap_vector = Vector3.ZERO
			#get the friction of the floor:
			inherited_vel += ground_check.get_collider_velocity() # inherit platform velocity
			var collider = ground_check.get_collider()
			if !(collider is CSGCombiner3D or (collider is CharacterBody3D and collider is not self)):
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
					
			### this may need to be done recursively
			var col = move_and_collide(vel*delta, true, 0.001, true, 5)
			if col:
				for i in range(col.get_collision_count()):
					var normal = col.get_normal(i)
					if (normal.angle_to(Vector3.UP) <= max_flr_ang): #slope counts as the floor
						floor_collision_normal += col.get_normal(i)
						floor_collision_normal = floor_collision_normal.normalized()
					else: #collision is not the floor. it is either a ceiling or a wall.
						if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91: #collision is ceiling
							ceiling_collision_normal += col.get_normal(i)
							ceiling_collision_normal = ceiling_collision_normal.normalized()
						else:
							wall_collision_normal += col.get_normal(i)
							wall_collision_normal = wall_collision_normal.normalized()
				if (ceiling_collision_normal != Vector3.ZERO):
					
					on_ceiling = true
					var curspeed = vel.length()
					var ceiling_floor_tangent = ceiling_collision_normal.cross(floor_collision_normal).normalized()
					if (wall_collision_normal != Vector3.ZERO):
						var wall_floor_tangent = wall_collision_normal.cross(floor_collision_normal).normalized()
						print(wall_floor_tangent.dot(ceiling_floor_tangent))
						if wall_floor_tangent.dot(ceiling_floor_tangent) <= 0:
							vel.x = 0
							vel.z = 0
						else:
							vel = ceiling_floor_tangent * vel.dot(ceiling_floor_tangent)
					else:
						vel = ceiling_floor_tangent * vel.dot(ceiling_floor_tangent)
				else:
					on_ceiling = false		
				if (wall_collision_normal != Vector3.ZERO):
					#do the stair stepping check before treating the collision like a wall!
					#if !on_floor:
						#snap_vector = Vector3.ZERO
					if ceiling_collision_normal == Vector3.ZERO:
						if (vel.length() > 0):
								
							#make a new collision hull that is slightly wider (so we can step even with low velocities and not get false negatives)
							var StairStepShape = BoxShape3D.new()
							StairStepShape.size = Vector3(collisionHull.shape.size.x+0.01, collisionHull.shape.size.y, collisionHull.shape.size.x+0.01)
							
							# Get destination position that is one step-size above the intended move
							var dest = position + Vector3(vel.x * delta, stair_step_height * (1+(delta*10)), vel.z * delta) # if your vel isn't large enough, this won't work :(
								
							# 1st Trace: check for collisions one stepsize above the original position
							var up = position + Vector3.UP * stair_step_height * (1+(delta*10))
							trace.standard(position, up, StairStepShape, self, 0x1)
								
							dest.y = trace.endpos.y
								
							# 2nd Trace: Check for collisions one stepsize above the original position
							# and along the intended destination
							trace.standard(trace.endpos, dest, StairStepShape, self, 0x1)
								
							# 3rd Trace: Check for collisions below the stepsize until 
							# level with original position
							var down = Vector3(trace.endpos.x, position.y, trace.endpos.z)
							trace.standard(trace.endpos, down, StairStepShape, self, 0x1)
								
							# Move to trace collision position if step is higher than original position 
							# and not steep
							if trace.endpos.y > position.y and trace.normal.angle_to(Vector3.UP) <= max_flr_ang: 
								print("stepped")
								global_transform.origin = trace.endpos
								on_wall = false
								wall_collision_normal = Vector3.ZERO
							else:
								if ceiling_collision_normal == Vector3.ZERO:
									on_wall = true
									if on_floor:
										#wall_collision_normal = Vector3(wall_collision_normal.x,0,wall_collision_normal.z).normalized()
										temp = vel.slide( wall_collision_normal )
										vel = Vector3(temp.x,vel.y,temp.z)
									else:
										vel += current_gravity * delta
										temp = vel.slide(wall_collision_normal)
										vel = Vector3(temp.x,vel.y,temp.z)
									
									if vel.y > 0 and floor_collision_normal == Vector3.ZERO:
										vel.y = 0 #prevent wall climbing
				else:
					on_wall = false
				if (floor_collision_normal != Vector3.ZERO):
					if (ceiling_collision_normal == Vector3.ZERO):
						var slopecheck = move_and_collide(vel*delta, true, 0.001, true) #slopecheck is to "move inbetween physics frames". This is useful if you just touched a slope and want to move up it at low physics framerates
						if slopecheck:
							var slopecheck_normal = slopecheck.get_normal()
							var vel_remainder = slopecheck.get_remainder()
							if slopecheck_normal.angle_to(Vector3.UP) <= max_flr_ang:
								on_floor = true
								vel_remainder.y = (-slopecheck_normal.z*vel_remainder.z-slopecheck_normal.x*vel_remainder.x)/slopecheck_normal.y
								vel.y = (-slopecheck_normal.z*vel.z-slopecheck_normal.x*vel.x)/slopecheck_normal.y
								move_and_collide(vel_remainder*delta)
						on_floor = true
						vel.y = (-floor_collision_normal.z*vel.z-floor_collision_normal.x*vel.x)/floor_collision_normal.y
						if (floor_collision_normal.y == 0): #safeguard. if the y normal of the slope is 0, it means you are trying to climb a completley vertical wall. Good luck with that lol.
							vel.y = 0
						air_jumps = max_air_jumps
						wall_jumps = max_wall_jumps
				#if (ceiling_collision_normal != Vector3.ZERO and wall_collision_normal != Vector3.ZERO):
					#vel = -vel
			
			$SurfaceNormal.set_rotation(- $SurfaceNormal.get_parent().rotation)
			$SurfaceNormal.target_position = floor_collision_normal;
			hud.get_node("floor_angle").text = "floor_angle: " + var_to_str(rad_to_deg(floor_collision_normal.angle_to(Vector3.UP)))
		else:
			hud.get_node("groundcheck").text = "groundcheck: false"
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
			velocity = vel + inherited_vel
			var col = move_and_collide(velocity*delta, true, 0.001, true, 3)
			if col:
				var normal = col.get_normal()
				for i in range(col.get_collision_count()):
					normal = col.get_normal(i)
					if rad_to_deg(col.get_angle(i, Vector3.UP)) > 91:#ceiling
						vel = vel.slide(normal)
						#vel = vel - ((vel.dot(normal))/normal.length()) * normal
					elif (normal.angle_to(Vector3.UP) <= max_flr_ang) and !in_water:#floor
						snap_vector = Vector3.DOWN * snap_magnitude
					else:#wall
						on_wall = true
						wall_collision_normal = normal
						vel = vel.slide(normal)
			else:
				on_wall = false
				on_ceiling = false
		var wallJumpCheckShape = BoxShape3D.new()
		wallJumpCheckShape.size = Vector3(collisionHull.shape.size.x+0.1, collisionHull.shape.size.y, collisionHull.shape.size.x+0.1)
		trace.intersect_groups(position, wallJumpCheckShape, self, 0x1)
		if trace.hit == true:
			on_wall = true
		else:
			on_wall = false
		velocity = vel + inherited_vel
		move_and_collide(velocity*delta, false, 0.001, false)
		
		#previously_on_floor = on_floor
		#previous_vel = vel
		#previous_dir = dir
		
			
		
		
	else:
		move_and_collide(vel*delta) # noclip movement
	previously_on_floor = on_floor
	previous_vel = vel
	previous_dir = dir
	if (hud):
		hud.get_node("pos").text = "pos: {" + var_to_str(position.x) + ", " + var_to_str(position.y) + ", " + var_to_str(position.z) + "}"
		hud.get_node("velx").text = "vel.x: " + var_to_str(velocity.x)
		hud.get_node("vely").text = "vel.y: " + var_to_str(velocity.y)
		hud.get_node("velz").text = "vel.z: " + var_to_str(velocity.z)
		hud.get_node("velmag").text = "vel mag: " + var_to_str(Vector3(velocity.x,0,velocity.z).length())
		hud.get_node("on_floor").text = "on_floor: " + var_to_str(on_floor)
		hud.get_node("on_wall").text = "on_wall: " + var_to_str(on_wall)
		hud.get_node("on_ceiling").text = "on_ceiling: " + var_to_str(on_ceiling)
		hud.get_node("in_water").text = "in_water: " + var_to_str(in_water)
		hud.get_node("snapvector").text = "snap_vector: " + var_to_str(snap_vector)
		hud.get_node("floor_normal").text = "floor_normal: " + var_to_str(floor_collision_normal)
		hud.get_node("wall_normal").text = "wall_normal: " + var_to_str(wall_collision_normal)
		hud.get_node("ceiling_normal").text = "ceiling_normal: " + var_to_str(ceiling_collision_normal)
	
	
	$Velocity.set_rotation(- $Velocity.get_parent().rotation)
	$Velocity.target_position = velocity;
	

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
	snap_vector = Vector3.DOWN * snap_magnitude 
	current_gravity = gravity
	current_acceleration = ACCELERATION

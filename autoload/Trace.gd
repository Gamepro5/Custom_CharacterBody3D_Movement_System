extends Node3D

# CREDITS: 
# Code by Btan2 (https://thelowrooms.com/articledir/programming_stepclimbing.php) and updated by Gamepro5 (https://gamepro5.com). Concept by ID Software

var endpos : Vector3
var fraction : float
var normal : Vector3
var type : String
var groups : PackedStringArray
var hit : bool


func new():
	endpos = Vector3.ZERO
	fraction = 0.0
	normal = Vector3.ZERO
	type = ""
	groups = PackedStringArray()
	hit = false
	
	return self


func motion(origin : Vector3, dest : Vector3, shape : Shape3D, e):
	var params
	var space_state
	
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = origin
	params.collide_with_bodies = true
	params.exclude = [e]
	params.motion = dest - origin
	
	space_state = get_world_3d().direct_space_state
	var results = space_state.cast_motion(params)
	fraction = results[0]


func rest(origin : Vector3, shape : Shape3D, e, mask):
	var params
	var space_state
	
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.set_collision_mask(mask)
	params.transform.origin = origin
	params.collide_with_bodies = true
	params.exclude = [e]
	
	hit = false
	
	space_state = get_world_3d().direct_space_state
	var results = space_state.get_rest_info(params)
	
	if results.empty():
		return
	
	hit = true
	normal = results.get("normal")


func intersect_groups(origin : Vector3, shape : Shape3D, e, mask):
	var params : PhysicsShapeQueryParameters3D
	var space_state
	var results
	
	groups = PackedStringArray()
	
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = origin
	params.collide_with_bodies = true
	params.exclude = [e]
	params.set_collision_mask(mask)
	
	hit = false
	
	space_state = get_world_3d().direct_space_state
	results = space_state.intersect_shape(params, 8)
	
	if results.is_empty():
		return
	
	hit = true
	
	for r in results:
		var group = r.get("collider").get_groups()
		if len(group) > 0:
			groups.append_array(group)

func standard(origin : Vector3, dest : Vector3, shape : Shape3D, e, mask):
	var params : PhysicsShapeQueryParameters3D
	var space_state
	var results
	
	# Create collision parameters
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = origin
	params.set_collide_with_bodies(true)
	params.set_exclude([e])
	params.set_motion(dest - origin)
	params.set_margin(0.04)
	params.set_collision_mask(mask)
	
	hit = false
	
	# Get distance fraction and position of first collision
	space_state = get_world_3d().direct_space_state
	results = space_state.cast_motion(params)
	
	if !results.is_empty():
		fraction = results[0]
		endpos = origin + (dest - origin).normalized() * (origin.distance_to(dest) * fraction)
	else:
		fraction = 1
		endpos = dest
		return # didn't hit anything
	
	hit = true
	
	# Set next parameter position to endpos
	params.transform.origin = endpos
	
	# Get collision normal
	results = space_state.get_rest_info(params)
	if !results.is_empty():
		normal = results.get("normal")
	else:
		normal = Vector3.UP


func full(origin : Vector3, dest : Vector3, shape : Shape3D, e):
	var params : PhysicsShapeQueryParameters3D
	var space_state
	var results
	var col_id
	
	# Create collision parameters
	params = PhysicsShapeQueryParameters3D.new()
	params.set_shape(shape)
	params.transform.origin = origin
	params.collide_with_bodies = true
	params.exclude = [e]
	params.motion = dest - origin
	hit = false
	
	# Get distance fraction and position of first collision
	space_state = get_world_3d().direct_space_state
	results = space_state.cast_motion(params)
	if !results.is_empty():
		fraction = results[0]
		endpos = origin + (dest - origin).normalized() * (origin.distance_to(dest) * fraction)
	else:
		fraction = 1
		endpos = dest
		return # Didn't hit anything
	
	hit = true
	
	# Set next parameter position to endpos
	params.transform.origin = endpos
	
	col_id = 0
	#type = "DEFAULT"
	
	# Get collision normal
	results = space_state.get_rest_info(params)
	if !results.is_empty():
		col_id = results.get("collider_id")
		normal = results.get("normal")
	else:
		normal = Vector3.UP
	
	# Get collision group
	if col_id != 0:
		results = space_state.intersect_shape(params, 8)
		if !results.is_empty():
			for r in results:
				if r.get("collider_id") == col_id:
					var g = r.get("collider").get_groups()
					if len(g) > 0:
						type = g[0]
					break


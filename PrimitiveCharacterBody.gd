extends CharacterBody3D


const SPEED = 15
const JUMP_VELOCITY = 7
var mouse_axis = Vector2.ZERO

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
		$Torso.rotate_y(deg_to_rad(horizontal))
		$Torso/Head.rotate_x(deg_to_rad(vertical))
		#print($Head.rotation)
		$Torso/Head.rotation.x = clamp($Torso/Head.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = ($Torso.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
	print(velocity)
	#print(is_on_floor())

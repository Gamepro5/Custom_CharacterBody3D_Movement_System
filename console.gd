extends Control

@onready var input = $Input
@onready var output = $Output
@onready var player = get_parent().get_parent()
enum {#useless rn
		ARG_INT,
		ARG_STRING,
		ARG_BOOL,
		ARG_FLOAT,
}

const convars = [
	["cl_apply_impulse", [ARG_FLOAT, ARG_FLOAT, ARG_FLOAT, ARG_BOOL]],
	["quit", []],
	["cl_set_pos", [ARG_FLOAT, ARG_FLOAT, ARG_FLOAT]],
	["thirdperson",[]],
	["firstperson", []],
	["fov_desired", [ARG_INT]]
]

func cl_apply_impulse(params):
	player.apply_impulse([ [str_to_var(params[0]), str_to_var(params[1]), str_to_var(params[2])] , str_to_var(params[3]) ])

func quit(params):
	get_tree().quit() # Quits the game
	
func cl_set_pos(params):
	player.position.x = str_to_var(params[0])
	player.position.y = str_to_var(params[1])
	player.position.z = str_to_var(params[2])

func thirdperson(params):
	player.get_node("Head").get_node("Camera2").set_current(true)
	player.get_node("Head").get_node("Camera").set_current(false)
	
func firstperson(params):
	player.get_node("Head").get_node("Camera2").set_current(false)
	player.get_node("Head").get_node("Camera").set_current(true)

func fov_desired(params):
	player.get_node("Head").get_node("Camera2").set_fov(str_to_var(params[0]))
	player.get_node("Head").get_node("Camera").set_fov(str_to_var(params[0]))
	
func evaluate_input(input:String):
	for k in input.split(";"):
		var params = k.split(" ")
		params = Array(params)
		var found = false;
		for i in range(convars.size()):
			if (params[0] == convars[i][0]):
				if params.size()-1 != convars[i][1].size():
					output.text = "Error! Too many params given to convar '" + convars[i][0] + "'. Expected exactly " + var_to_str(convars[i][1].size()) + ". You gave: " + var_to_str(params.size()-1) + ".\n" + output.text
					found = true
					break
				else:#execute command
					var temp = params.duplicate()
					temp.pop_front()
					call(params[0], temp) #todo: add a better param type check
					output.text = "'" + k + "'" + " executed.\n" + output.text
					found = true
					break
		if !found:
			output.text = "Error! Invalid convar: '" + params[0] + "'.\n" + output.text
		

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.is_action_pressed("console"):
			set_visible(!is_visible())
			if !is_visible():
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if is_visible():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if event.keycode == KEY_ENTER:
				if input.text.length() > 0:
					evaluate_input(input.text)
			
				



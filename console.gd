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
	["help", []],
	["cl_apply_impulse", [ARG_FLOAT, ARG_FLOAT, ARG_FLOAT, ARG_BOOL]],
	["quit", []],
	["cl_set_pos", [ARG_FLOAT, ARG_FLOAT, ARG_FLOAT]],
	["thirdperson",[]],
	["firstperson", []],
	["fov_desired", [ARG_INT]],
	["host_timescale", [ARG_FLOAT]],
	["fullscreen", []]
]
func help(params):
	output.text += "Here is a list of all convars. (Documentation not included because I'm lazy):\n"
	for i in convars:
		output.text += "		" + var_to_str(i) + "\n"
	output.text += "Where 0=ARG_INT, 1=ARG_STRING, 2=ARG_BOOL, and 3=ARG_FLOAT\n"

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

func host_timescale(params):
	Engine.set_time_scale(str_to_var(params[0]))

func fullscreen(params):
	if (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func evaluate_input(input:String):
	
	for k in input.split(";"):
		var params = k.split(" ")
		params = Array(params)
		var found = false;
		for i in range(convars.size()):
			if (params[0] == convars[i][0]):
				if params.size()-1 != convars[i][1].size():
					output.text += "Error! Too many params given to convar '" + convars[i][0] + "'. Expected exactly " + var_to_str(convars[i][1].size()) + ". You gave: " + var_to_str(params.size()-1) + ".\n"
					found = true
					break
				else:#execute command
					var temp = params.duplicate()
					temp.pop_front()
					output.text += k + "\n"
					call(params[0], temp) #todo: add a better param type check
					found = true
					break
		if !found:
			output.text += "Error! Invalid convar: '" + params[0] + "'.\n"
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			set_visible(false)
		elif Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if event is InputEventKey:
		if event.is_action_pressed("console"):
			set_visible(!is_visible())
			if !is_visible():
				input.clear()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if is_visible():
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			if event.is_action_pressed("console_submit"):
				if input.text.length() > 0:
					evaluate_input(input.text)
		
		if event.is_action_released("console"):
			if is_visible():
				input.grab_focus()
				input.clear()
			



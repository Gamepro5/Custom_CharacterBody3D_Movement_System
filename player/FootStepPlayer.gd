extends "res://lib/GeneralAudioPlayer.gd" 

# Written by Gamepro5 with conceptual help from unfau

@onready var player = self.get_parent()
var groundtype = "stone"
var rng = RandomNumberGenerator.new()
#enum groundtype {CHAINLINK,CONCRETE,DIRT,DUCT,GRASS,GRAVEL,LADDER,METAL,METALGRATE,MUD,SAND,SLOSH,TILE,WADE,WOOD,WOODPANEL}

var footsteps_timer : float = 0
var footsteps_delay : float = 0.5 # seconds
var play_footsteps = false;


func update_groundtype(col):
	var previous_groundtype = groundtype
	var collider = col.get_collider()
	if collider.has_meta("material"):
		groundtype = collider.get_meta("material")
	else:
		groundtype = "pl_step"
	#if groundtype != previous_groundtype and play_footsteps:
		#playRandomFootstep(groundtype)
	
func _physics_process(delta):
	if player.on_floor and player.vel.length() > 0:
		footsteps_delay = (1/(Vector3(player.vel.x,0,player.vel.z).length()))*2
		if footsteps_delay > 10 or footsteps_delay < 0.05:
			play_footsteps = false;
		else:
			play_footsteps = true;
	else:
		play_footsteps = false;
	footsteps_timer += delta
	if play_footsteps and footsteps_timer >= footsteps_delay:
		playRandomFootstep(groundtype)
		footsteps_timer = 0

func getRandomFootstepPath(category):
	return "sound/player/footsteps/" + category + var_to_str(int(round(rng.randf_range(1, 4)))) + ".wav"

func playRandomFootstep(category, pitch:int = 1, volume:int = 0):
	play_sound(getRandomFootstepPath(category), pitch, volume)


extends AudioStreamPlayer3D

# Written by Gamepro5

func play_sound(path, pitch:float = 1.0, volume:float = 0.0):
	set_stream(load("res://" + path))
	set_volume_db(volume)
	set_pitch_scale(pitch)
	if playing:
		stop()
		play()
	else:
		play()

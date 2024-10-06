extends AudioStreamPlayer

func _ready():
	max_polyphony = 16

func play_rand():
	pitch_scale = randf_range(0.95, 1.05)
	play()

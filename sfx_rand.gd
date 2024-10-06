extends AudioStreamPlayer

#func _ready():
#	max_polyphony = 16

func _ready():
	# Hack: ALl our BFXR sounds are tooloud, so turn them down here.
	volume_db -= 12

func play_rand():
	var copy = self.duplicate()
	add_sibling(copy)
	copy.pitch_scale = randf_range(0.92, 1.08)
	copy.play()
	copy.finished.connect(copy.queue_free)

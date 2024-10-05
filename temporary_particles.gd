extends CPUParticles2D

@export var time: float = 2.0

func _ready():
	emitting = true

func _process(delta):
	time -= delta
	if time < 0:
		queue_free()

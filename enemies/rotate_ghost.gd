extends GhostBase

@onready var sprites = [
	$Look/a, $Look/b, $Look/c
]

var theta = 0
const RADIUS = 80

func animate(delta):
	theta += delta
	theta = fmod(theta, TAU)
	var angle = theta
	for s in sprites:
		s.scale.x = 1.2 * 0.7
		s.scale.y = 0.9 * 0.7
		var offset = Vector2.from_angle(angle) * RADIUS
		s.position = offset
		angle += TAU / 3

func _physics_process(delta):
	animate(delta)
	update_collision_timeouts(delta)
	
	var to_pos = handle_sleep()
	if asleep:
		return
	to_pos = GS.get_nav_move_target(global_position, to_pos)
	
	var vel_dir = (to_pos - global_position).normalized()
	velocity = vel_dir * 32
	
	move_and_slide()


func on_death(body):
	pass

extends CharacterBody2D

var health: int = 6

func _physics_process(delta):
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty():
		return
	
	var to_pos = Vector2.ZERO
	for p in players:
		to_pos += p.global_position * randf_range(0.8, 1.2)
		
	to_pos /= players.size()
	
	var vel_dir = (to_pos - global_position).normalized()
	velocity = vel_dir * 32
	
	move_and_slide()
	

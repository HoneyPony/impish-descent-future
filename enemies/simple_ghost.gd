extends CharacterBody2D

var health: int = 6

var current_projectile = null

func handle_simple_projectile():
	if current_projectile != null:
		if not current_projectile.fired:
			# If we have an un-fired projectile, update its pos
			current_projectile.global_position = $FireFrom.global_position
			return
	
	# Spawn a new projectile if we don't have one
	var proj = GS.EnemyProjectile1.instantiate()
	proj.global_position = $FireFrom.global_position
	add_sibling(proj)
	
	current_projectile = proj

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
	
	handle_simple_projectile()
	


func _on_hazard_body_entered(body):
	health -= body.damage
	body.hit_target()
	
	if health <= 0:
		queue_free()

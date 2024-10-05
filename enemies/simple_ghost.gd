extends CharacterBody2D

var health: int = 6

var current_projectile = null

var collision_timeouts = {}

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
	
	var to_delete = []
	
	for k in collision_timeouts:
		collision_timeouts[k] -= delta
		if collision_timeouts[k] < 0:
			to_delete.push_back(k)
			
	for k in to_delete:
		collision_timeouts.erase(k)


func _on_hazard_body_entered(body):
	if collision_timeouts.get(body, -1.0) > 0.0:
		return
	
	# Call hit_target() first in case the damage gets buffed.
	body.hit_target()
	health -= body.damage
	
	
	# Time out collision
	collision_timeouts[body] = 0.5
	
	if health <= 0:
		if current_projectile != null and not current_projectile.fired:
			current_projectile.die()
		queue_free()

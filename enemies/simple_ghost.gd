extends GhostBase

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
	update_collision_timeouts(delta)
	
	var to_pos = handle_sleep()
	if asleep:
		return
	to_pos = GS.get_nav_move_target(global_position, to_pos)
	
	var vel_dir = (to_pos - global_position).normalized()
	velocity = vel_dir * 32
	
	move_and_slide()
	handle_simple_projectile()


func on_death(body):
	if current_projectile != null and not current_projectile.fired:
		current_projectile.die()

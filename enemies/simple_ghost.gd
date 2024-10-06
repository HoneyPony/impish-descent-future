extends GhostBase

var fire_timer = 2.3

@export var big = false

func _ready():
	fire_timer = randf_range(0, 2.3)

func handle_simple_projectile(delta):
	#if current_projectile != null:
		#if not current_projectile.fired:
			## If we have an un-fired projectile, update its pos
			#current_projectile.global_position = $FireFrom.global_position
			#return
	
	fire_timer -= delta
	if fire_timer <= 0:
		fire_timer = 2.3
	
		var count = 1
		var sound_count = 1
		var dx = 128 - 16
		var start_offset = Vector2.ZERO
		if big:
			sound_count = 2
			count = 5
			start_offset.y = 0
			start_offset.x = -dx * 2
	
		for i in range(0, count):
			# Spawn a new projectile if we don't have one
			var proj = GS.EnemyProjectile1.instantiate()
			proj.global_position = global_position
			proj.goal_position = $FireFrom.global_position + start_offset
			add_sibling(proj)
			
			start_offset.x += randf_range(dx - 2, dx + 2)
			start_offset.y += randf_range(-32, 32)
			
		for i in range(0, sound_count):
			Sounds.ghost_bullet_spawn.play_rand()
		
		#current_projectile = proj

func _physics_process(delta):
	update_collision_timeouts(delta)
	
	var to_pos = handle_sleep()
	if asleep:
		return
	to_pos = GS.get_nav_move_target(global_position, to_pos)
	
	var vel_dir = (to_pos - global_position).normalized()
	velocity = vel_dir * 32
	
	move_and_slide()
	handle_simple_projectile(delta)

func on_death(body):
	return
#
#func on_death(body):
	#if current_projectile != null and not current_projectile.fired:
		#current_projectile.die()

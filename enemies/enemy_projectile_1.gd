extends AnimatableBody2D

var velocity = Vector2.ZERO

var fired = false

var targetted_player = null

const SPEED = 512

# IMPORTANT: ALL ENEMY PROJECTILES MUST IMPLEMENT THIS
func hit_player():
	die()

func die():
	var particle = GS.EnemyProjectile1Particle.instantiate()
	particle.position = position
	add_sibling(particle)
	queue_free()

func _physics_process(delta):
	if velocity != Vector2.ZERO:
		var collide = move_and_collide(velocity * delta)
		
		if targetted_player != null:
			var dir = (targetted_player.global_position - global_position).normalized()
			var new_vel = dir * SPEED
			
			velocity = velocity.slerp(new_vel, 0.02)
	
		# Die when we hit a wall
		if collide != null:
			die()
			
# Called by animation
func fire_now():
	var dir = Vector2.DOWN
	
	var players = get_tree().get_nodes_in_group("Players")
	if not players.is_empty():
		var random = players.pick_random()
		dir = (random.global_position - global_position).normalized()
		
		targetted_player = random

	# Can adjust this speed value
	velocity = dir * SPEED
	
	fired = true

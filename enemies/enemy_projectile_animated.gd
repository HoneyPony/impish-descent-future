extends AnimatableBody2D

var velocity = Vector2.ZERO

var fired = false

var targetted_player = null

var goal_position = Vector2.ZERO

var projectile_source = null

const SPEED = 512

# Projectiles can't hit twice.
var slowness = 10.0

# IMPORTANT: ALL ENEMY PROJECTILES MUST IMPLEMENT THIS
func hit_target(target):
	die()
func killed_target(target):
	pass
	
func _ready():
	$CollisionShape2D.disabled = true
	if GS.ascensions[3]:
		$AnimationPlayer.speed_scale = 1.4

func die():
	var particle = GS.EnemyProjectile1Particle.instantiate()
	particle.position = position
	add_sibling(particle)
	queue_free()

func _physics_process(delta):
	if not fired:
		var to_goal = (goal_position - global_position)
		move_and_collide(to_goal * 0.1)
	
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
	$CollisionShape2D.disabled = false
	Sounds.ghost_bullet_shoot.play_rand()
	
	var dir = Vector2.DOWN
	
	# Safer way to check if get_tree() is null?
	if not is_inside_tree():
		return
	
	var tree = get_tree()
	if tree == null:
		return
	
	var players = tree.get_nodes_in_group("Players")
	if not players.is_empty():
		var random = players.pick_random()
		dir = (random.global_position - global_position).normalized()
		
		targetted_player = random

	# Can adjust this speed value
	velocity = dir * SPEED
	
	fired = true

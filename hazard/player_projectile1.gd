extends AnimatableBody2D

var velocity = Vector2.ZERO

var projectile_source = null

var damage: int = 1

# Projectiles can't hit twice.
var slowness = 10.0

var lifetime = 10.0
var died = false

@onready var sprite = $Sprite

# IMPORTANT: ALL  PROJECTILES MUST IMPLEMENT THIS
func hit_target(target):
	die()
	
func killed_target(target):
	pass

func die():
	if died:
		return
	var particle = GS.PlayerProjectile1Particle.instantiate()
	particle.position = position
	add_sibling(particle)
	queue_free()
	died = true

func _physics_process(delta):
	# Animate sprite
	sprite.rotate(0.25 * TAU * delta)
	
	var collide = move_and_collide(velocity * delta)
	
	#if targetted_player != null:
		#var dir = (targetted_player.global_position - global_position).normalized()
		#var new_vel = dir * SPEED
		#
		#velocity = velocity.slerp(new_vel, 0.02)

	# Die when we hit a wall
	if collide != null:
		die()
		
	lifetime -= delta
	if lifetime <= 0:
		die()

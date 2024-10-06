extends AnimatableBody2D

var fired = false

var targetted_player = null

var projectile_source = null

const SPEED = 256

# Projectiles can't hit twice.
var slowness = 10.0

#const RADIUS = 384
var radius = 16
var theta = 0

var lifetime = 10.0

# IMPORTANT: ALL ENEMY PROJECTILES MUST IMPLEMENT THIS
func hit_target(target):
	die()
func killed_target(target):
	pass
	
func _ready():
	theta = randf_range(0, TAU)
	radius = randf_range(64, 384)
	$CollisionShape2D.disabled = true
	scale = Vector2(0.2, 0.2)

func die():
	var particle = GS.EnemyProjectile1Particle.instantiate()
	particle.position = position
	add_sibling(particle)
	queue_free()

func _physics_process(delta):
	var s = scale.x
	if s < 1.0:
		s += delta * 0.6
		scale = Vector2(s, s)
		if s >= 1.0:
			$CollisionShape2D.disabled = false
	
	var to_pos = Vector2.from_angle(theta) * radius
	to_pos -= Vector2(0, 128)
	var impulse = (to_pos - position) * s * s * s
	
	theta += TAU * delta * 0.25
	
	var collide = move_and_collide(impulse)

	# Die when we hit a wall
	if collide != null:
		die()
		
	lifetime -= delta
	if lifetime < 0:
		die()
			
			
			

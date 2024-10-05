extends AnimatableBody2D

var velocity = Vector2.ZERO
var buff = GS.Buff.None
var buff_source = null

# IMPORTANT: ALL  PROJECTILES MUST IMPLEMENT THIS
func hit_target(target):
	# Reset to None so we don't help more than one player
	buff = GS.Buff.None
	die()
	
func killed_target(target):
	pass

func die():
	var particle = GS.EnemyProjectile1Particle.instantiate()
	particle.position = position
	add_sibling(particle)
	queue_free()
	
func set_sprite(texture: Texture2D):
	$Sprite.texture = texture

func _physics_process(delta):
	var collide = move_and_collide(velocity * delta)

	# Die when we hit a wall
	if collide != null:
		die()

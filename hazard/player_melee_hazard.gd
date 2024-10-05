extends PhysicsBody2D

@export var damage: int = 2

func hit_target():
	# When we hit the target, see if we get a damage buff from the player.
	# Note that this means that melee attacks that miss don't use up damage
	# buffs.
	damage = get_parent().get_buffed_damage(damage)

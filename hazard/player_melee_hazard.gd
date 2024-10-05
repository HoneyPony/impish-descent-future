extends PhysicsBody2D

@export var damage: int = 2

var only_half_health: bool = false
var upgrades_on_kill: bool = false

var projectile_source = null

var slowness = 1.0

func killed_target(target):
	if upgrades_on_kill:
		get_parent().melee_base_damage += 1

func hit_target(target):
	if only_half_health:
		if target.health * 2 > target.max_health:
			damage = 0
			# Don't use up damage buffs in this case
			return
	
	# When we hit the target, see if we get a damage buff from the player.
	# Note that this means that melee attacks that miss don't use up damage
	# buffs.
	# ALSO: This means that e.g.. damage up buffs only apply to a single hit,
	# rather than the whole attack.
	damage = get_parent().get_buffed_damage(get_parent().melee_base_damage)
	
	

extends CharacterBody2D
class_name GhostBase

var health: int = 6
@export var max_health: int = 6
@export var regen: bool = false

var regen_timer = 1
var my_regen_rate = 1

var asleep = true

var collision_timeouts = {}

func init_ghost_base():
	if GS.ascensions[2]:
		max_health = int(max_health * 1.5)
		
	get_node("Health").parent_ready()
	
	health = max_health
	if GS.ascensions[1]:
		if not regen:
			regen = true
			# Make normal enemies still regnerate slower.
			my_regen_rate *= 3
			# Hack: The health bar is still pink for fast-rgenerating
			# and red for slow, which is helpful info.
	if GS.ascensions[4]:
		# This is scary ish.
		my_regen_rate *= 0.5

func _ready():
	init_ghost_base()

func compute_random_weighted_player_average():
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty():
		return null
	
	var to_pos = Vector2.ZERO
	for p in players:
		to_pos += p.global_position * randf_range(0.8, 1.2)
		
	to_pos /= players.size()
	
	return to_pos

# Returns player average thing.
func handle_sleep() -> Vector2:
	var to_pos = compute_random_weighted_player_average()
	
	# can't wake up when there's no players.
	if to_pos == null:
		return global_position
	
	if asleep:
		var dist = (to_pos - global_position).length_squared()
		if dist < 768 * 768:
			asleep = false
		else:
			return to_pos
			
	return to_pos

func update_collision_timeouts(delta):
	# Just do regen here too, cause we have to callthis fun...
	if regen:
		regen_timer -= delta
		if regen_timer <= 0:
			regen_timer = my_regen_rate
			if health < max_health:
				health += 1
	
	var to_delete = []
	
	var new_timeouts = {}
	
	var keys = collision_timeouts.keys()
	for k in keys:
		if not is_instance_valid(k):
			continue
		if collision_timeouts[k] < 0:
			continue
		new_timeouts[k] = collision_timeouts[k] - delta

	collision_timeouts = new_timeouts

func do_explode():
	var explode = GS.GhostExplode.instantiate()
	explode.global_position = global_position + Vector2(0, -64)
	add_sibling(explode)

func on_death(body):
	pass

func _on_hazard_body_entered(body):
	if collision_timeouts.get(body, -1.0) > 0.0:
		return
	
	# Call hit_target() first in case the damage gets buffed.
	body.hit_target(self)
	health -= body.damage
	
	# Time out collision
	collision_timeouts[body] = body.slowness
	
	if health <= 0:
		Sounds.kill_ghost.play_rand()
		on_death(body)
		body.killed_target(self)
		GS.an_enemy_died()
		queue_free()
	else:
		Sounds.hit_ghost.play_rand()

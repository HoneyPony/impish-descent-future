extends CharacterBody2D
class_name GhostBase

var health: int = 6
@export var max_health: int = 6

var asleep = true

var collision_timeouts = {}

func _ready():
	health = max_health

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
		on_death(body)
		body.killed_target(self)
		GS.an_enemy_died()
		queue_free()

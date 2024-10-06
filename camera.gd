extends Camera2D

# let the win screen freeze the camera so we don't get motion sickness
var frozen = false

func _physics_process(delta):
	if frozen:
		return
	
	var target = Vector2.ZERO
	
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty():
		return
	
	for p in players:
		target += p.global_position
	target /= players.size()
	
	var c_offset = target - global_position
	
	var lerp_strength = (c_offset.length() - 512.0) / 1024.0
	lerp_strength = clamp(lerp_strength, 0.05, 0.3)
	
	global_position += c_offset * lerp_strength

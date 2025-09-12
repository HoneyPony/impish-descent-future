extends Camera2D

# let the win screen freeze the camera so we don't get motion sickness
var frozen := false

const MOUSE_WEIGHT := 0.6

var player_smoothed: Vector2 = Vector2.ZERO
var mouse_smoothed: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if frozen:
		return
		
	var player_target = Vector2.ZERO
	
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty():
		return
		
	var formation = get_tree().get_first_node_in_group("ImpFormation")
	if formation == null:
		return
	
	for p in players:
		player_target += p.global_position
	player_target /= players.size()
	
	# Seems easiest...?
	player_target = formation.global_position
	
	var lerp_strength = ((player_target - player_smoothed).length() - 512.0) / 1024.0
	#lerp_strength = clamp(lerp_strength, 0.0, 1.0)
	#lerp_strength = 1.0 - lerp_strength
	lerp_strength = clamp(lerp_strength, 0.0, 0.2)
	player_smoothed += (player_target - player_smoothed) * lerp_strength
	
	# TODO: This should probably be the relative mouse pos...?
	
	var mouse_dir: Vector2 = get_global_mouse_position() - formation.global_position
	const min_length: float = 128
	const max_length: float = 1024
	
	
	if mouse_dir.length() > max_length:
		mouse_dir = mouse_dir.normalized() * max_length
		
	# We track the mouse position in local coordinates so that it can be smoothed
	# separately.
	var mouse_target = get_local_mouse_position()#formation.global_position + mouse_dir - global_position
	
	#var mouse_target = get_local_mouse_position()
	mouse_smoothed += (mouse_target - mouse_smoothed) * 0.05
	
	# If the mouse isn't far enough away, just don't update the formation.
	if mouse_dir.length() >= min_length:
		formation.tracked_mouse = mouse_smoothed + global_position - formation.global_position
	
	var target: Vector2 = lerp(player_smoothed, player_smoothed + mouse_smoothed, MOUSE_WEIGHT)

	global_position = target
	
	if GS.flag_in_formation_menu:
		# Compute the smoothing when we do this anyway.
		global_position = get_tree().get_first_node_in_group("ImpStartPos").global_position
		# Reset the mouse pos when we're in the menu so it smoothes out.
		mouse_smoothed = Vector2.ZERO

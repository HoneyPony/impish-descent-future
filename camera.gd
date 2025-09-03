extends Camera2D

# let the win screen freeze the camera so we don't get motion sickness
var frozen := false

const MOUSE_WEIGHT := 0.45

var player_smoothed: Vector2 = Vector2.ZERO
var mouse_smoothed: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if frozen:
		return
		
	var player_target = Vector2.ZERO
	
	var players = get_tree().get_nodes_in_group("Players")
	if players.is_empty():
		return
	
	for p in players:
		player_target += p.global_position
	player_target /= players.size()
	
	var lerp_strength = ((player_target - player_smoothed).length() - 512.0) / 1024.0
	lerp_strength = clamp(lerp_strength, 0.05, 0.2)
	player_smoothed += (player_target - player_smoothed) * lerp_strength
	
	# TODO: This should probably be the relative mouse pos...?
	var mouse_target = get_local_mouse_position()
	mouse_smoothed += (mouse_target - mouse_smoothed) * 0.05
	
	var target: Vector2 = lerp(player_smoothed, player_smoothed + mouse_smoothed, MOUSE_WEIGHT)

	global_position = target
	
	if GS.flag_in_formation_menu:
		# Compute the smoothing when we do this anyway.
		global_position = get_tree().get_first_node_in_group("ImpStartPos").global_position
		# Reset the mouse pos when we're in the menu so it smoothes out.
		mouse_smoothed = Vector2.ZERO

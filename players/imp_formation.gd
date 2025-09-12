extends Node2D
class_name ImpFormation

var edited_player: Player = null

@onready var circle = %Circle

func _ready() -> void:
	# Reparent ourselves off of the ImpStartPos. This makes sure our starting
	# point is always synchronized
	reparent.call_deferred(get_parent().get_parent())

func _physics_process(delta: float) -> void:
	if GS.flag_in_formation_menu:
		# TODO: There is probably a better way to do this
		global_position = get_tree().get_first_node_in_group("ImpStartPos").global_position
		return
	
	# This is probably not even what we want...
	var pos = Vector2.ZERO
	var players = get_tree().get_nodes_in_group("Players")
	for player in players:
		# Get the player's target position
		var target = global_transform * player.formation_position
		# Compute the player's 'where should we be for this to be neutral' target
		var our_rel_pos: Vector2 = player.global_position + global_position - target
		pos += our_rel_pos
	pos /= players.size()
	
	
	
	global_position += (pos - global_position) * 0.05
	#global_position = pos
	
	var vel = Vector2.ZERO
	vel.x = Input.get_axis("player_left", "player_right")
	vel.y = Input.get_axis("player_up", "player_down")
	vel = vel.normalized() * Player.MAX_VEL
	# print(global_position)
	
	global_position += vel * delta * 2.0
	
	var dist: float = (circle.global_position - pos).length()
	var circle_vis: float = 1.0 - clamp(dist / 50.0, 0.0, 1.0)
	circle.self_modulate.a = 1.0 #circle_vis
	circle.global_position += (pos - circle.global_position) * 0.9
	
	# We need to use the global mouse position versus our own position, because
	# the local mouse position is affected by our own rotation.
	
	# Add an offset of 90 degrees because we want the user to configure their
	# formation pointing 'up'.
	var target_rot = (get_global_mouse_position() - global_position).angle() + TAU * 0.25
	rotation = rotate_toward(rotation, target_rot, TAU * delta)

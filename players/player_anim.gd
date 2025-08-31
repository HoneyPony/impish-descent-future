extends Node2D
class_name PlayerAnimation

@onready var tree: AnimationTree = %AnimationTree

func update_tree(player_speed_fac: float) -> void:
	player_speed_fac = clamp(player_speed_fac, 0.0, 1.0)
	var speed := 4.0 * player_speed_fac
	var blend: float = clamp(2.0 * player_speed_fac, 0.0, 1.0)
	
	tree["parameters/walk_speed/scale"] = speed
	tree["parameters/walk_blend/blend_amount"] = blend

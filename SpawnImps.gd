extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	GS.spawn_imp(get_parent(), GS.valid_imps[2], global_position)
	GS.spawn_imp(get_parent(), GS.valid_imps[3], global_position)
	GS.spawn_imp(get_parent(), GS.valid_imps[2], global_position)
	#GS.spawn_imp(get_parent(), GS.valid_imps[1], global_position)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

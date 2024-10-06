extends ColorRect

func _ready():
	hide() # Success menu is hidden at the beginning of levels
	

func _process(delta):
	# When we detect there are no enemies left, we handle that case and
	# show the win screen.
	if get_tree().get_node_count_in_group("Enemy") == 0:
		GS.has_won = true
		show()
		# Freeze the camera.
		%GameCamera.frozen = true


func _on_confirm_button_pressed():
	GS.current_level += 1
	if GS.current_level < GS.levels.size():
		SceneTransition.change_scene(GS.levels[GS.current_level])

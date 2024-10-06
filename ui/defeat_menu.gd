extends ColorRect

var going = false

func _ready():
	hide() # Defeat menu is hidden at the beginning of levels
	
func _process(delta):
	if not going:
		return
	
	# When we detect there are no players left, defeat...
	if get_tree().get_node_count_in_group("Players") == 0:
		show()
		# Freeze the camera.
		%GameCamera.frozen = true

func _on_retry_pressed():
	# Reload the current level
	# Flag to the upgrade menu that we are retrying, i.e. we don't get an upgrade
	GS.flag_retry_this_level = true
	GS.reset_inter_level_state()
	if GS.current_level < GS.levels.size():
		SceneTransition.change_scene(GS.levels[GS.current_level])


func _on_main_menu_pressed():
	# TODO figure out who resets the global state
	SceneTransition.change_scene(GS.MainMenu)

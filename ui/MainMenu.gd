extends Control
class_name MainMenu

func _ready():
	# Each time we load the main menu, reset all of the state.
	GS.reset_game_state()

func _on_PlayButton_pressed():
	# might as well...
	GS.reset_game_state()
	# Restart msuic
	Sounds.get_node("GameMusic").seek(0)
	#print(Sounds.get_node("GameMusic").playing)
	SceneTransition.change_scene(GS.levels(0))

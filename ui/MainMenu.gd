extends Control

func _ready():
	# Each time we load the main menu, reset all of the state.
	GS.reset_game_state()

func _on_PlayButton_pressed():
	SceneTransition.change_scene(GS.levels[0])

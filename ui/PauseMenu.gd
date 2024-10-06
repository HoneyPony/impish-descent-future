extends CanvasLayer

func _ready():
	visible = get_tree().paused

func pause():
	get_tree().paused = true
	show()
	
func unpause():
	get_tree().paused = false
	hide()
	
func toggle_pause():
	if get_tree().paused:
		unpause()
	else:
		pause()

func _on_ResumeButton_pressed():
	unpause()
	
func _on_QuitButton_pressed():
	unpause()
	#get_tree().change_scene_to_packed(GS.MainMenu)
	SceneTransition.change_scene(GS.MainMenu)
	
func _process(delta):
	if Input.is_action_just_pressed("pause_button"):
		toggle_pause()
		
	if Input.is_action_just_pressed("retry"):
		_on_retry_pressed()


func _on_retry_pressed():
	GS.flag_retry_this_level = true
	GS.reset_inter_level_state()
	if GS.current_level < GS.levels_size():
		SceneTransition.change_scene(GS.levels(GS.current_level))

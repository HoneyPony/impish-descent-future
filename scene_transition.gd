extends CanvasLayer

var next_scene = null

func change_scene(to: PackedScene):
	if next_scene != null:
		return
		
	next_scene = to
	show()
	$AnimationPlayer.play("FadeOut")

func _change_now():
	get_tree().change_scene_to_packed(next_scene)
	next_scene = null
	$AnimationPlayer.play("FadeIn")
	
func _done():
	hide()

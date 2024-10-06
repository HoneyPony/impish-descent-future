extends Node

var menu_vol_actual = 0.0
var game_vol_actual = 0.0

func _ready():
	$MenuMusic.volume_db = linear_to_db(0)
	
	$MenuMusic.play()

func _process(delta):
	var menu_vol = 0.0
	if is_instance_of(get_tree().current_scene, MainMenu):
		menu_vol = 1.0
	var game_vol = 1.0 - menu_vol
	
	menu_vol_actual += (menu_vol - menu_vol_actual) * 0.01
	game_vol_actual += (game_vol - game_vol_actual) * 0.01
	
	$MenuMusic.volume_db = linear_to_db(menu_vol_actual)

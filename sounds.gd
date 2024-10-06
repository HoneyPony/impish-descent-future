extends Node

var menu_vol_actual = 0.0
var game_vol_actual = 0.0

var game_vol_adjust = -9

@onready var imp_act = $ImpAct
@onready var hit_ghost = $HitGhost
@onready var kill_ghost = $KillGhost
@onready var imp_act_crunchy = $ImpActCrunchy

func _ready():
	$MenuMusic.volume_db = linear_to_db(0)
	$GameMusic.volume_db = linear_to_db(0) + game_vol_adjust
	$MenuMusic.play()
	$GameMusic.play()

func _process(delta):
	var menu_vol = 0.0
	if is_instance_of(get_tree().current_scene, MainMenu):
		menu_vol = 1.0
	var game_vol = 1.0 - menu_vol
	
	menu_vol_actual += (menu_vol - menu_vol_actual) * 0.01
	game_vol_actual += (game_vol - game_vol_actual) * 0.01
	
	$MenuMusic.volume_db = linear_to_db(menu_vol_actual)
	$GameMusic.volume_db = linear_to_db(game_vol_actual) + game_vol_adjust

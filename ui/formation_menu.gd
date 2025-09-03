extends Control
class_name FormationMenu

func _ready() -> void:
	$ConfirmButton.pressed.connect(_on_confirm_pressed)

func show_menu() -> void:
	# Spawn the army when we show the menu. The army needs to exist so that
	# we can edit its formation.
	GS.spawn_current_army()
	
	show()
	GS.flag_in_formation_menu = true
	
func _on_confirm_pressed() -> void:
	GS.flag_in_formation_menu = false
	
	hide()
	%DefeatMenu.going = true

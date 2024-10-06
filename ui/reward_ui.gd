extends ColorRect

@onready var rows = [
	$ImpSelectRow,
	$ImpSelectRow2,
	$ImpSelectRow3
]

var current_new_imp = 0

func unselect_imps():
	for row in rows:
		row.unselect()

func sample_imp(require_combat: bool) -> int:
	if require_combat:
		return GS.combat_imps.pick_random()
	else:
		return randi_range(0, GS.valid_imps.size() - 1)

func setup_rewards(relic: bool = false, require_combat: bool = false):
	var imps = []
	
	# Sample imps
	for i in range(0, 1000):
		var next = sample_imp(require_combat)
		if next in imps:
			continue
		imps.push_back(next)
		if imps.size() >= 3:
			break
			
	# If somehow we didn't get them all yet, force that here
	while imps.size() < 3:
		imps.push_back(sample_imp(true))
			
	for i in range(0, 3):
		rows[i].setup(GS.valid_imps[imps[i]], imps[i])
		
	rows[0].select_this()
	
func _ready():
	# Make sure we haven't won yet
	GS.has_won = false
	# This menu begins each level. Note that the camera won't move until enemies
	# are spawned in, which is perfect.
	show()
	
	# Nonetheless, reset the camera to point at the ImpStartPos.
	%GameCamera.global_position = get_tree().get_first_node_in_group("ImpStartPos").global_position
	
	setup_rewards(false, true)

# This is basically the entry point into the gameplay for now.
func _on_confirm_button_pressed():
	hide()
	GS.current_army.push_back(current_new_imp)
	GS.spawn_current_army()

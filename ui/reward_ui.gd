extends ColorRect

@onready var rows = [
	$ImpSelectRow,
	$ImpSelectRow2,
	$ImpSelectRow3
]

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
		rows[i].setup(GS.valid_imps[imps[i]])
	
func _ready():
	setup_rewards(false, true)

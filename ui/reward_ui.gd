extends Control

@onready var cards := [
	%Card1,
	%Card2,
	%Card3
]

@onready var relics = [
	%Relic1,
	%Relic2,
]

## Which of the main row of cards will be picked.
var current_main_card: UpgradeCard = null

var current_relic: UpgradeCard = null

var do_choose_relic = false

@export var double_upgrade: ColorRect = null
@export var double_upgrade_child: ColorRect = null
var flag_own_hide = false

func unselect_main_cards() -> void:
	for card in cards:
		card.selected = false

func unselect_relics() -> void:
	for relic in relics:
		relic.selected = false
	%NoRelic.button_pressed = true
	
func select_relic(card: UpgradeCard) -> void:
	unselect_relics()
	current_relic = card
	%NoRelic.button_pressed = false

func sample_imp(require_combat: bool) -> int:
	if require_combat:
		return GS.combat_imps.pick_random()
	else:
		return randi_range(0, GS.valid_imps.size() - 1)

func setup_rewards(relic: bool = false, require_combat: bool = false):
	do_choose_relic = relic
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
		cards[i].setup_as_imp(GS.valid_imps[imps[i]], imps[i])
		
	cards[0].select_self()
	
	if relic:
		var first = GS.avail_relics.pick_random()
		GS.avail_relics.remove_at(GS.avail_relics.find(first))
		var second = GS.avail_relics.pick_random()
		GS.avail_relics.remove_at(GS.avail_relics.find(second))
		
		relics[0].setup_as_relic(first)
		relics[1].setup_as_relic(second)
		
		unselect_relics()
	
func _ready():
	
	# If we're the double upgrader, defer to the other one
	if double_upgrade == null:
		# Make sure we haven't won yet
		GS.has_won = false
	
		if GS.flag_retry_this_level:
			GS.flag_retry_this_level = false
			hide()
			GS.spawn_current_army()
			%DefeatMenu.going = true
			if double_upgrade_child != null:
				double_upgrade_child.hide()
				double_upgrade_child.flag_own_hide = true
			return
		GS.flag_in_upgrade_menu = true
		
	if flag_own_hide:
		hide()
		return
			
	
	# This menu begins each level. Note that the camera won't move until enemies
	# are spawned in, which is perfect.
	show()
	
	# Nonetheless, reset the camera to point at the ImpStartPos.
	%GameCamera.global_position = get_tree().get_first_node_in_group("ImpStartPos").global_position
	
	var require_combat = false
	# We always get an imp capable of dealing damage on the first level.
	if GS.current_level == 0:
		require_combat = true
		
	var relics = false
	if GS.current_level == 1 or GS.current_level == 3 or GS.current_level == 5:
		relics = true
		
	# relics = true
		
	setup_rewards(relics, require_combat)
	
	if double_upgrade != null:
		double_upgrade.get_node("ImpTitle").text = "Choose two Imps to add to your army"

	%NoRelic.pressed.connect(func():
		unselect_relics()
	)

func _earn_reward(card: UpgradeCard) -> void:
	if card == null:
		return
	if card.kind == UpgradeCard.RewardKind.IMP:
		GS.current_army.push_back(card.id)
	if card.kind == UpgradeCard.RewardKind.RELIC:
		GS.accept_relic(card.id)

# This is basically the entry point into the gameplay for now.
func _on_confirm_button_pressed():
	hide()
	
	_earn_reward(current_main_card)
	_earn_reward(current_relic)
	
	if double_upgrade != null:
		# Just defer to the other one to do the rest of the work.
		double_upgrade._on_confirm_button_pressed()
		return
		
	GS.flag_in_upgrade_menu = false
	%FormationMenu.show_menu()

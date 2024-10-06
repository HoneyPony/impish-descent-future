extends Node

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

#var Game = preload("res://Game.tscn")

var has_won = false

var flag_retry_this_level = false

var current_level = 0

@onready var levels = [
	load("res://levels/level1.tscn"),
	load("res://levels/level2.tscn"),
	load("res://levels/level3.tscn"),
	load("res://levels/level4.tscn"),
	load("res://levels/level5.tscn"),
	
	load("res://ui/win_screen.tscn")
]
	

var MainMenu = preload("res://MainMenu.tscn")

var EnemyProjectile1 = preload("res://enemies/enemy_projectile1.tscn")
var EnemyProjectile2 = preload("res://enemies/enemy_projectile2.tscn")
var EnemyProjectile1Particle = preload("res://enemies/enemy_projectile_1_particle.tscn")

var PlayerProjectile1 = preload("res://hazard/player_projectile1.tscn")
var PlayerProjectile1Particle = preload("res://hazard/player_projectile1_particle.tscn")

var BuffProjectile = preload("res://buffs/player_buff.tscn")
var BuffParticle = preload("res://buffs/buff_particle.tscn")
var SplitProjectile = preload("res://buffs/split_buff.tscn")

var Player = preload("res://players/player.tscn")

var nav: AStarGrid2D = AStarGrid2D.new()

func get_nav_point(global_pos: Vector2) -> Vector2i:
	global_pos -= Vector2(64, 64)
	var point = Vector2i((global_pos / 128.0).round())
	#point -= nav.region.position
	#print(point)
	return point
	
func get_nav_move_target(global_pos: Vector2, move_target: Vector2) -> Vector2:
	var from_point = GS.get_nav_point(global_pos)
	var to_point = GS.get_nav_point(move_target)
	
	# Only try to navigate if the target isn't on the same tile.
	if from_point != to_point:
		# Can't navigate if we don't have both points in the rectangle.
		# (We get many errors in the console and a 0-length nav array to boot).
		if not GS.nav.region.has_point(from_point):
			return move_target
		if not GS.nav.region.has_point(to_point):
			return move_target
		var move_target_nav = GS.nav.get_id_path(from_point, to_point, true)
		if move_target_nav.size() >= 2:
			var p1 = GS.nav.get_point_position(move_target_nav[1])
			var good_move_target = p1 + Vector2(64, 64)
			
			# If the move target and good_move_target are in a similar direction,
			# mostly use the existing move_target.
			
			var d0 = (good_move_target - global_pos).normalized()
			var d1 = (move_target - global_pos).normalized()
			# Exaggerate the nav weight to some degree.
			var facing = d0.dot(d1)
			facing = facing * facing
			var good_weight = 1.0 - facing
			#var good_weight = (1.0 - d0.dot(d1)) * 5.0
			good_weight = clamp(good_weight, 0, 1)
			move_target = lerp(move_target, good_move_target, good_weight)

	return move_target

enum Item {
	Sword,
	Club,
	Dagger,
	Mace,
	Staff,
	Scythe
}

enum Class {
	Brawler,
	Mage,
	Cleric,
	Summoner
}

enum Buff {
	None,
	Shield,
	Dagger,
	Split,
	Ethereal,
}

var valid_imps = [
	[Class.Brawler, Item.Sword, "Brawler wielding Sword:\n- Attacks at 100% speed for 2 Melee damage."],
	[Class.Brawler, Item.Club, "Brawler wielding Club:\n- Attacks at 50% speed for 3 Melee damage."],
	[Class.Brawler, Item.Dagger, "Brawler wielding Dagger:\n- Attacks at 200% speed for 1 Melee damage."],
	[Class.Brawler, Item.Mace, "Brawler wielding Mace:\n- Attacks at 100% speed for 5 Melee damage.\n- Can only attack when enemies are below half health."],
	[Class.Mage, Item.Staff, "Mage wielding Staff:\n- Attacks at 100% speed for 1 Ranged damage."],
	[Class.Mage, Item.Dagger, "Mage wielding Dagger:\n- Applies Strength buff to other imps.\n- Strength adds 1 damage to the next attack."],
	[Class.Mage, Item.Club, "Mage wielding Club:\n- Attacks at 100% speed for 0-4 Ranged damage.\n- Damage is rolled randomly."],
	[Class.Mage, Item.Scythe, "Mage wielding Scythe:\n- Attacks at 100% speed for 1 Ranged damage.\n- Shoots 5 shots in random directions."],
	[Class.Cleric, Item.Staff, "Cleric wielding Staff:\n- Applies Shield buff to nearby imps.\n- Shield buff blocks 1 hit from enemies."],
	[Class.Cleric, Item.Sword, "Cleric wielding Sword:\n- Attacks at 100% speed for 1 damage.\n- On kill, increase damage by 1 (resets next level)"],
	[Class.Cleric, Item.Scythe, "Cleric wielding Scythe:\n- Splits nearby imps into two imps.\n- Split imps randomly do 1 fewer damage."],
	[Class.Summoner, Item.Staff, "Summoner wielding Staff:\n- Summons random Ethereal imps.\n- Ethereal imps disappear after 4 seconds."],
	[Class.Summoner, Item.Scythe, "Summoner wielding Scythe:\n- Resurrects dead imps."],
]

var nonbreaking_imps = [0, 1, 2, 3,
4, 5, 6, # no 7, because it splits
8, 9, 10, 11, 12]

var combat_imps = [
	0, # All brawlers
	1,
	2,
	# 3, # No mace.
	
	4,
	# 5
	6,
	7,
	
	# 8, [cleric staff]
 	9 
	# 10, [cleric splitter]
	# 11 might become a cleric
	
	# Right now summoners are 11, etc
]

var current_army = []

func pick_nonbreaking_imp():
	return valid_imps[nonbreaking_imps.pick_random()]

func spawn_current_army():
	var pos = get_tree().get_first_node_in_group("ImpStartPos")
	assert(pos != null)
	
	for imp in current_army:
		spawn_imp(pos.get_parent(), valid_imps[imp], pos.global_position)

func finish_spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool, ethereal: bool):
	var imp = Player.instantiate()
	parent.add_child(imp)
	imp.global_position = global_pos
	imp.set_class(config[0])
	imp.set_item(config[1])
	imp.compute_basic_properties()
	imp.finalize_properties()
	if split:
		imp.add_buff(GS.Buff.Split)
	if ethereal:
		imp.add_buff(GS.Buff.Ethereal)
		
	if relic_spawn_shield:
		imp.add_buff(GS.Buff.Shield)

func spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool = false, ethereal: bool = false):
	call_deferred("finish_spawn_imp", parent, config, global_pos, split, ethereal)
	
func get_item_tex(item: Item):
	var tex = null
	match item:
		GS.Item.Sword:
			tex = preload("res://players/sword.png")
		GS.Item.Staff:
			tex = preload("res://players/staff.png")
		GS.Item.Scythe:
			tex = preload("res://players/scythe.png")
		GS.Item.Dagger:
			tex = preload("res://players/dagger.png")
		GS.Item.Mace:
			tex = preload("res://players/mace.png")
		GS.Item.Club:
			tex = preload("res://players/club.png")
		_:
			print("Oops, we don't support that item yet")
	return tex
	
func get_body_tex(klass: Class):
	var tex = null
	match klass:
		GS.Class.Brawler:
			tex = preload("res://players/body0.png")
		GS.Class.Mage:
			tex = preload("res://players/body1.png")
		GS.Class.Cleric:
			tex = preload("res://players/body2.png")
		GS.Class.Summoner:
			tex = preload("res://players/body3.png")
		_:
			print("Oops, we don't support that class yet")
	return tex
	#
#func _process(delta):
	#print(get_nav_point($"/root/Game".get_global_mouse_position()))

var relics = [
"Essence of Slime
When your imps would die, they Split instead.
Split imps randomly do -1 damage and cannot split.",

"Conch Horn
Every 3rd time you kill an enemy, spawn a random Brawler.",

"Quarterstaff
All Mages now Melee attack for 3 damage.",

"Amulet of Protection
All imps spawn with 1 Shield.
(Shields protect against one hit).",

"Thorny Bush
Your Shields no longer protect. Instead, they grant +2 damage
to the next attack.",

"Book of Stabbing
All daggers gain an additional x1.5 speed.",

"Cursed Sword
Melee attacks gain +1 damage. Your imps can no longer resurrect.",

"Strange Skull
When you kill an enemy, summon two random Ethereal imps.",

"Holy Scepter
Non-Ethereal imps deal triple melee damage.
Attacks made this way kill that imp.",
]

var relic_sprite = [
	preload("res://relics/relic0.png"),
	preload("res://relics/relic1.png"),
	preload("res://relics/relic2.png"),
	preload("res://relics/relic3.png"),
	preload("res://relics/relic4.png"),
	preload("res://relics/relic_5.png"),
	preload("res://relics/relic6.png"),
	preload("res://relics/relic7.png"),
	preload("res://relics/relic8.png"),
]

var avail_relics: Array = []

var enemy_killed_mod3 = 0

# Called when we retry a level, to ensure that inter-level state is always consistent in that
# case.
func reset_inter_level_state():
	enemy_killed_mod3 = 0
	
func reset_game_state():
	reset_inter_level_state()
	avail_relics.clear()
	for i in range(0, relics.size()):
		avail_relics.push_back(i)
		
	relic_always_split = false
	relic_3_enemies_spawn_brawler = false
	relic_mages_melee = false
	relic_spawn_shield = false
	relic_shields_are_damage = false
	relic_daggers_150_speed = false
	relic_attacks_1dmg_no_resurrect = false
	relic_kill_equals_eth_resurrecter = false
	relic_tripledmg_killself = false
	
	current_level = 0
	has_won = false
	flag_retry_this_level = false
	
	current_army = []
	#relic_tripledmg_killself = true

func get_imp_spawn_info():
	var to_pos = Vector2.ZERO
	var players = get_tree().get_nodes_in_group("Players")
	var original_spawner = get_tree().get_first_node_in_group("ImpStartPos")
	assert(original_spawner != null)
	
	if players.is_empty():
		to_pos = original_spawner.global_position
	
	else:
		to_pos = players.pick_random().global_position
		
	return [original_spawner.get_parent(), to_pos]

func spawn_random_brawler():
	var info = get_imp_spawn_info()

	var brawler = randi_range(0, 3);
	spawn_imp(info[0], valid_imps[brawler], info[1])

func an_enemy_died():
	if relic_3_enemies_spawn_brawler:
		enemy_killed_mod3 += 1
		if enemy_killed_mod3 >= 3:
			spawn_random_brawler()
			enemy_killed_mod3 = 0
			
	if relic_kill_equals_eth_resurrecter:
		var info = get_imp_spawn_info()
		spawn_imp(info[0], pick_nonbreaking_imp(), info[1], false, true)
		#spawn_imp(info[0], valid_imps[12], info[1], false, true)
		var info2 = get_imp_spawn_info()
		spawn_imp(info2[0], pick_nonbreaking_imp(), info2[1], false, true)

var relic_always_split = false
var relic_3_enemies_spawn_brawler = false
var relic_mages_melee = false
var relic_spawn_shield = false
var relic_shields_are_damage = false
var relic_daggers_150_speed = false
var relic_attacks_1dmg_no_resurrect = false
var relic_kill_equals_eth_resurrecter = false
var relic_tripledmg_killself = false

func accept_relic(id: int):
	match id:
		0: relic_always_split = true
		1: relic_3_enemies_spawn_brawler = true
		2: relic_mages_melee = true
		3: relic_spawn_shield = true
		4: relic_shields_are_damage = true
		5: relic_daggers_150_speed = true
		6: relic_attacks_1dmg_no_resurrect = true
		7: relic_kill_equals_eth_resurrecter = true
		8: relic_tripledmg_killself = true

func _ready():
	reset_game_state()

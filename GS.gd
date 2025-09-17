extends Node

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

#var Game = preload("res://Game.tscn")

var has_won = false

var flag_retry_this_level = false
var flag_in_upgrade_menu = false
var flag_in_formation_menu = false

var current_level = 0

var ascensions = [true, false, false, false, false]

@onready var levels_all = [
	load("res://levels/level1.tscn"),
	load("res://levels/level2.tscn"),
	load("res://levels/level3.tscn"),
	load("res://levels/level4.tscn"),
	load("res://levels/level5.tscn"),
	load("res://levels/level6.tscn"),
	
	load("res://ui/win_screen.tscn")
]
	
func levels(index: int) -> PackedScene:
	if not ascensions[0]:
		if index >= 5:
			return levels_all[6]
		return levels_all[index]
	else:
		return levels_all[index]
		
func levels_size():
	if not ascensions[0]:
		return levels_all.size() - 1
	return levels_all.size()
	

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

var GhostExplode = preload("res://enemies/ghost_explode.tscn")
var PlayerExplode = preload("res://players/player_explode.tscn")

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
	[Class.Brawler, Item.Sword , "- Attacks for 2 Melee damage."],
	[Class.Brawler, Item.Club  , "- Attacks for 3 Melee damage."],
	[Class.Brawler, Item.Dagger, "- Attacks for 1 Melee damage."],
	[Class.Brawler, Item.Mace  , "- Attacks for 5 Melee damage.\n- Can only attack when enemies are below half health."],
	
	[Class.Mage, Item.Staff , "- Attacks for 1 Ranged damage."],
	[Class.Mage, Item.Dagger, "- Applies Strength buff to other imps.\n- Strength adds 1 damage to the next attack."],
	[Class.Mage, Item.Club  , "- Attacks for 0-4 Ranged damage.\n- Damage is rolled randomly."],
	[Class.Mage, Item.Scythe, "- Attacks for 1 Ranged damage.\n- Shoots 7 shots in random directions."],
	
	[Class.Cleric, Item.Staff , "- Applies Shield buff to nearby imps.\n- Shield buff blocks 1 hit from enemies."],
	[Class.Cleric, Item.Dagger, "- Attacks for 1 Melee damage.\n- On kill, increase damage by 1 (resets next level)"],
	[Class.Cleric, Item.Scythe, "- Splits nearby imps into two imps.\n- Split imps randomize their damage."],
	
	[Class.Summoner, Item.Staff , "- Summons random Ethereal imps.\n- Ethereal imps disappear after 4 seconds."],
	[Class.Summoner, Item.Scythe, "- Resurrects dead imps."],
]

func get_class_name(klass: Class) -> String:
	return Class.keys()[klass]
func get_item_name(item: Item) -> String:
	return Item.keys()[item]

var nonbreaking_imps = [0, 1, 2, 3,
4, 5, 6, 7, 8, 9,  # no 10, because it splits
 11, 12]

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

var current_army      = []
var current_formation: Array[Vector2i] = []

var formation_avail_perm: Array[Vector2i] = []
var formation_avail_temp: Array[Vector2i] = []

func sort_formation_avail() -> void:
	formation_avail_perm.sort_custom(sort_for_formation)
	
# We actually want to sort this one in the opposite way of the perm one.
# You usually want temporary imps in the front.
func sort_formation_temp() -> void:
	formation_avail_temp.sort_custom(func(a, b):
		var adist = (a - Vector2i(0, 5)).length_squared()
		var bdist = (b - Vector2i(0, 5)).length_squared()
		# Sort based on who is closer to the front??
		return bdist > adist
		#var al = a.length_squared()
		#var bl = b.length_squared()
		#if al < bl:
			#return true
		#if bl < al:
			#return false
		## Ok, length is equal, what else?
		## I think this should do the thing?
		#return a.y > b.y
	)

func sort_for_formation(a, b):
	# Shorter ones go near the back
	return a.length_squared() > b.length_squared()

func create_formation_avail() -> Array[Vector2i]:
	var dict: Array[Vector2i] = []
	
	for x in range(-5, 6):
		for y in range(-5, 6):
			if x*x + y*y <= 5*5:
				dict.append(Vector2i(x, y))
	
	dict.sort_custom(sort_for_formation)
	
	return dict
	
func take_middle_formation() -> Vector2i:
	var result = Vector2i.ZERO
	if formation_avail_temp.is_empty():
		print("take_middle_formation: :(")
		# Nothing really to do...
		return result
	print("take_middle_formation: ", formation_avail_temp)
	print("take_middle_formation: ", Vector2i.ZERO in formation_avail_temp, " ", formation_avail_temp.size())
		
	result = formation_avail_temp[0]
	for i in range(1, formation_avail_temp.size()):
		var check = formation_avail_temp[i]
		if check.length_squared() < result.length_squared():
			result = check
			
	print("take_middle_formation: ", result)
	# This should be possible
	formation_avail_temp.erase(result)
	sort_formation_temp()
	return result

# Formation idea:
# - Have a list of "available formation positions",
#   with closer positions sorted earlier.
# - Whenever an imp is spawned, it picks one of the available formation positions
#   as its position.
# - Whenever an imp dies, it puts its position back into the pool.


func pick_nonbreaking_imp():
	return valid_imps[nonbreaking_imps.pick_random()]

func spawn_current_army():
	var pos = get_tree().get_first_node_in_group("ImpStartPos")
	assert(pos != null)
	
	var id: int = 0
	for imp in current_army:
		spawn_imp(pos.get_parent(), valid_imps[imp], pos.global_position, false, false, false, false, id)
		id += 1

func finish_spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool, ethereal: bool, play_sound: bool, invuln: bool, army_id: int):
	var imp = Player.instantiate()
	imp.army_id = army_id
	imp.spawn_as_split_flag = split
	print("army id -> ", army_id)
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
	if invuln:
		imp.invulnerability = 0.5
		
	if relic_spawn_shield:
		imp.add_buff(GS.Buff.Shield)
	
	if play_sound:	
		Sounds.imp_spawn.play_rand()

func spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool = false, ethereal: bool = false, play_sound: bool = true, invuln: bool = false, army_id: int = -1):
	call_deferred("finish_spawn_imp", parent, config, global_pos, split, ethereal, play_sound, invuln, army_id)
	
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
	
func get_body_tex_path(klass: Class) -> String:
	match klass:
		GS.Class.Brawler:
			return "res://players/red"
		GS.Class.Mage:
			return "res://players/green"
		GS.Class.Cleric:
			return "res://players/purple"
		GS.Class.Summoner:
			return "res://players/black"
		_:
			print("oops, we don't have specific textures yet.")
			return "res://players/red"
	
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

func _process(delta):
	if Input.is_action_just_pressed("toggle_fullscreen"):

		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
#func _process(delta):
	#print(get_nav_point($"/root/Game".get_global_mouse_position()))

var relics: Array[String] = [
"Essence of Slime
When your imps die, summon 3 Ethereal copies of them.
Your imps can no longer resurrect.",

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

var relic_sprite: Array[Texture2D] = [
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
var owned_relics: Array = []

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
	current_formation = []
	owned_relics = []
	
	formation_avail_perm = create_formation_avail()
	formation_avail_temp = create_formation_avail()
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
	owned_relics.push_back(id)
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
		# Go in fullscreen for nicer experience..?
	if OS.get_name() != "Web":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	reset_game_state()

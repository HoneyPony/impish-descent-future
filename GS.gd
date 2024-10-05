extends Node

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")

var EnemyProjectile1 = preload("res://enemies/enemy_projectile1.tscn")
var EnemyProjectile1Particle = preload("res://enemies/enemy_projectile_1_particle.tscn")

var PlayerProjectile1 = preload("res://hazard/player_projectile1.tscn")

var BuffProjectile = preload("res://buffs/player_buff.tscn")
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
			var good_weight = (1.0 - d0.dot(d1)) * 5.0
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
	[Class.Brawler, Item.Sword],
	[Class.Brawler, Item.Club],
	[Class.Brawler, Item.Dagger],
	[Class.Brawler, Item.Mace],
	[Class.Mage, Item.Staff],
	[Class.Mage, Item.Dagger],
	[Class.Mage, Item.Club],
	[Class.Mage, Item.Scythe],
	[Class.Cleric, Item.Staff],
	[Class.Cleric, Item.Sword],
	[Class.Cleric, Item.Scythe],
	[Class.Summoner, Item.Staff],
	[Class.Summoner, Item.Scythe],
]

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

func spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool = false, ethereal: bool = false):
	call_deferred("finish_spawn_imp", parent, config, global_pos, split, ethereal)
	
	
	#
#func _process(delta):
	#print(get_nav_point($"/root/Game".get_global_mouse_position()))

func _ready():
	pass

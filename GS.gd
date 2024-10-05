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
	Split
}

var valid_imps = [
	[Class.Brawler, Item.Sword],
	[Class.Brawler, Item.Club],
	[Class.Brawler, Item.Dagger],
	[Class.Brawler, Item.Mace],
	[Class.Mage, Item.Staff],
	[Class.Mage, Item.Dagger],
	[Class.Cleric, Item.Staff],
	[Class.Cleric, Item.Sword],
	[Class.Cleric, Item.Scythe],
	[Class.Summoner, Item.Scythe],
]

func finish_spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool):
	var imp = Player.instantiate()
	parent.add_child(imp)
	imp.global_position = global_pos
	imp.set_class(config[0])
	imp.set_item(config[1])
	imp.compute_basic_properties()
	imp.finalize_properties()
	if split:
		imp.add_buff(GS.Buff.Split)

func spawn_imp(parent: Node, config: Array, global_pos: Vector2, split: bool = false):
	call_deferred("finish_spawn_imp", parent, config, global_pos, split)
	
	
	#
#func _process(delta):
	#print(get_nav_point($"/root/Game".get_global_mouse_position()))

func _ready():
	pass

extends Node

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")

var EnemyProjectile1 = preload("res://enemies/enemy_projectile1.tscn")
var EnemyProjectile1Particle = preload("res://enemies/enemy_projectile_1_particle.tscn")

var PlayerProjectile1 = preload("res://hazard/player_projectile1.tscn")

var Player = preload("res://players/player.tscn")

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

var valid_imps = [
	[Class.Brawler, Item.Sword]
]

func finish_spawn_imp(parent: Node, config: Array, global_pos: Vector2):
	var imp = Player.instantiate()
	parent.add_child(imp)
	imp.global_position = global_pos
	imp.set_class(config[0])
	imp.set_item(config[1])

func spawn_imp(parent: Node, config: Array, global_pos: Vector2):
	call_deferred("finish_spawn_imp", parent, config, global_pos)
	
	
	

func _ready():
	pass

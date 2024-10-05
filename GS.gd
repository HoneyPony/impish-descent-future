extends Node

# The "global state" node. This is where global variables are usually stored,
# as well as things like scene preloads.

var Game = preload("res://Game.tscn")
var MainMenu = preload("res://MainMenu.tscn")

var EnemyProjectile1 = preload("res://enemies/enemy_projectile1.tscn")
var EnemyProjectile1Particle = preload("res://enemies/enemy_projectile_1_particle.tscn")

func _ready():
	pass

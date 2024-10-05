extends Node2D

@onready var init = $Init

const SPRITE_TEX_WIDTH = 128

var full_heart = preload("res://health/full_heart.png")
var half_heart = preload("res://health/half_heart.png")

var extra_sprites = []

var current_val: int = 0

# Initialized by the first call to render_amount, which decides where the bar will be centered.
var real_total_width = 0

func _ready():
	call_deferred("render_amount", int(get_parent().health))

func render_amount(health: int):
	current_val = health
	
	var needed_sprites = (health + 1) / 2
	var needed_extra = needed_sprites - 1
	while extra_sprites.size() > needed_extra:
		if extra_sprites.is_empty():
			break
		extra_sprites.pop_back().queue_free()
		
	while extra_sprites.size() < needed_extra:
		var extra = init.duplicate()
		add_child(extra)
		extra_sprites.push_back(extra)
		
	var padding = 8
	var total_sprites = (extra_sprites.size() + 1) 
	var real_sprite_width = SPRITE_TEX_WIDTH * init.scale.x
	
	# Compute this once, when this is first called.
	if real_total_width == 0:
		var total_width = (total_sprites * real_sprite_width) + padding * (total_sprites - 1)
		real_total_width = total_width
	
	var out_x = -real_total_width * 0.5 + real_sprite_width * 0.5
	init.position.x = out_x
	if health == 1:
		init.texture = half_heart
	else:
		init.texture = full_heart
	init.visible = (health > 0)
		
	health -= 2
		
	out_x += padding + real_sprite_width
	for spr in extra_sprites:
		spr.position.x = out_x
		if health == 1:
			spr.texture = half_heart
		else:
			spr.texture = full_heart
		health -= 2
		out_x += padding + real_sprite_width

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var p_health = int(get_parent().health)
	if p_health != current_val:
		render_amount(p_health)

extends Node2D
class_name WinScreenImp

var is_root = true

func setup_with(klass: GS.Class, item: GS.Item) -> void:
	var tex_path = GS.get_body_tex_path(klass)
	# TODO: Body types
	%Body.texture    = load(tex_path + "/body-m.png")
	%ImpHead.texture = load(tex_path + "/head.png")
	%LLeg.texture    = load(tex_path + "/lleg.png")
	%RLeg.texture    = load(tex_path + "/rleg.png")
	%Item.texture = GS.get_item_tex(item)

func setup():
	var first = true
	var xo = 70
	var extra = (GS.current_army.size() - 1) * 70
	position.x -= extra / 2
	for imp in GS.current_army:
		var target = self
		if first:
			first = false
		else:
			target = preload("res://ui/win_screen/win_screen_imp.tscn").instantiate()
			target.is_root = false
			add_sibling(target)
			target.position = position + Vector2(xo, 0)
			xo += 70
			
		target.setup_with(GS.valid_imps[imp][0], GS.valid_imps[imp][1])

func _ready():
	if is_root:
		call_deferred("setup")

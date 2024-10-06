extends Sprite2D

var is_root = true

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
			target = self.duplicate()
			target.is_root = false
			add_sibling(target)
			target.position.x += xo
			xo += 70
			
		target.texture = GS.get_body_tex(GS.valid_imps[imp][0])
		target.get_node("Item").texture = GS.get_item_tex(GS.valid_imps[imp][1])

func _ready():
	if is_root:
		call_deferred("setup")

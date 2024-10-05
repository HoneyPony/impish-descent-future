extends ColorRect

const GRAY_UNSELECT = 0.337
const GRAY_SELECT = 0.267

func setup(data):
	var klass = data[0]
	var item = data[1]
	var description = data[2]
	
	$Body.texture = GS.get_body_tex(klass)
	$Item.texture = GS.get_item_tex(item)
	$Label.text = description
	
func _ready():
	$Button.pressed.connect(self.select_this)
	
func select_this():
	if not $Button.button_pressed:
		$Button.button_pressed = true
	
	get_parent().unselect_imps()
	color = Color(GRAY_SELECT, GRAY_SELECT, GRAY_SELECT)
	
func unselect():
	color = Color(GRAY_UNSELECT, GRAY_UNSELECT, GRAY_UNSELECT)

extends ColorRect

const GRAY_UNSELECT = 0.337
const GRAY_SELECT = 0.267

var relic_id = 0

func setup(id):
	relic_id = id
	
	#$Body.texture = GS.get_body_tex(klass)
	$Label.text = GS.relics[id]
	
func _ready():
	$Button.pressed.connect(self.select_this)
	
func select_this():
	if not $Button.button_pressed:
		$Button.button_pressed = true
	
	get_parent().get_parent().unselect_relics()
	get_parent().get_parent().current_new_relic = relic_id
	color = Color(GRAY_SELECT, GRAY_SELECT, GRAY_SELECT)
	
func unselect():
	color = Color(GRAY_UNSELECT, GRAY_UNSELECT, GRAY_UNSELECT)

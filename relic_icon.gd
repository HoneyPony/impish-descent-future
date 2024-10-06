extends Sprite2D

@export var index = 0

func show_if_should_be_visible():
	if visible:
		return
	
	if index >= GS.owned_relics.size():
		return
	
	var id = GS.owned_relics[index]
	
	if id >= 0:
		texture = GS.relic_sprite[id]
		
		show()

func _ready():
	hide()
	show_if_should_be_visible()
	
func _process(delta):
	show_if_should_be_visible()
	

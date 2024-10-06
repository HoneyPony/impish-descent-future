extends CheckBox

@export var index: int = 0

func _ready():
	button_pressed = GS.ascensions[index]
	connect("pressed", self._pressed)
	
func _pressed():
	GS.ascensions[index] = button_pressed

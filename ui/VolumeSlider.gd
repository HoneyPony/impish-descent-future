extends HSlider

@export var bus_name = "Master"

var bus_idx

func _ready():
	min_value = 0
	max_value = 1
	step = 0.005
	
	bus_idx = AudioServer.get_bus_index(bus_name)
	
	value = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	
	value_changed.connect(self.update_volume)
	
func update_volume(val):
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(val))

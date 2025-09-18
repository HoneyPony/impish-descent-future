extends Control
class_name Tutorial

func _ready() -> void:
	hide()
	SignalBus.real_gameplay_started.connect(func(): show())

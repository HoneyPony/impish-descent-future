extends Node2D
## Represents a single upgrade in the upgrade menu. Handles selection of itself
## and display.
class_name UpgradeCard

## Stores the ID for the item that we represent. This could be either an Imp
## or a Relic (or maybe other stuff in the future).
var id: int = 0

enum RewardKind {
	IMP,
	RELIC
}

enum Row {
	MAIN_CARD,
	RELIC
}

@export var row: Row = Row.MAIN_CARD

## The kind of reward this is.
var kind: RewardKind = RewardKind.IMP

const BBCODE_MODIFIED := "[color=#a0ffc0]"

@onready var hover_tex := %HoverTex
@onready var select_tex := %SelectTex
@onready var card_rect := %Card

var selected: bool = false

func setup_as_relic(id: int) -> void:
	self.kind = RewardKind.RELIC
	self.id   = id
	
	%ImpBody.queue_free()
	%ImpHead.queue_free()
	%ImpItem.queue_free()
	
	# TODO: Consider making these separate pieces of data. Also we may eventually
	# have relic descriptions as tooltips instead of like this
	var text := GS.relics[id]
	var pieces := text.split("\n", true, 1)
	
	%Title.text = pieces[0]
	%Description.text = pieces[1]
	
	%Relic.texture = GS.relic_sprite[id]
	
	%ActionSpeed.queue_free()

func setup_as_imp(data, id: int) -> void:
	self.kind = RewardKind.IMP
	self.id = id
	
	var klass       = data[0]
	var item        = data[1]
	var description = data[2]
	
	var tex_path: String = GS.get_body_tex_path(klass)
	
	# TODO: Body types
	%ImpBody.texture = load(tex_path + "/body-m.png")
	%ImpHead.texture = load(tex_path + "/head.png")
	
	%ImpItem.texture = GS.get_item_tex(item)
	
	%Relic.queue_free()
	
	var speed := Player.compute_action_speed(klass, item)
	var speed_percent = int(speed.x * 100) # speed.x is the actual speed
	if speed.y > 0.5: # speed.y represents if the speed is modified
		%ActionSpeed.text = str(BBCODE_MODIFIED, speed_percent, "%[/color] action speed")
	else:
		%ActionSpeed.text = str(speed_percent, "% action speed")
	
	%Title.text = str(GS.get_class_name(klass), " / ", GS.get_item_name(item))
	%Description.text = description

func _physics_process(delta: float) -> void:
	var is_hovered = card_rect.get_global_rect().has_point(get_global_mouse_position())
	
	var hover_tex_target := 1.0 if is_hovered else 0.0
	var scale_target := 1.0
	if is_hovered:
		scale_target = 1.08 # select overrides hover..?
	if selected:
		scale_target = 0.95
	
	var select_tex_target := 1.0 if selected else 0.0
	
	hover_tex.modulate.a += (hover_tex_target - hover_tex.modulate.a) * 0.2
	
	scale.x += (scale_target - scale.x) * 0.2
	scale.y = scale.x
	
	select_tex.modulate.a += (select_tex_target - select_tex.modulate.a) * 0.2
	
func select_self() -> void:
	match row:
		Row.MAIN_CARD:
			get_parent().unselect_main_cards()
			get_parent().current_main_card = self
		Row.RELIC:
			get_parent().select_relic(self)
	
	selected = true
	
func _ready() -> void:
	%Card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_self()
	)

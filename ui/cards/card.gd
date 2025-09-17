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
	RELIC,
	SECOND_IMP,
}

@export var row: Row = Row.MAIN_CARD

## The kind of reward this is.
var kind: RewardKind = RewardKind.IMP

const BBCODE_MODIFIED := "[color=#a0ffc0]"
const BBCODE_DESC_CHANGE := "[color=#d0d0ff]"

@onready var hover_tex := %HoverTex
@onready var select_tex := %SelectTex
@onready var card_rect := %Card

var selected: bool = false

@onready var description := %Description
@onready var tooltip_pos := %TooltipPos

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
	
	# Just for fun, center the text for relics.
	%Description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func setup_as_imp(id: int) -> void:
	self.kind = RewardKind.IMP
	self.id = id
	
	var data = GS.valid_imps[id]
	
	var klass       = data[0]
	var item        = data[1]
	var description: String = data[2]
	
	var desc_modified = false
	
	if klass == GS.Class.Mage:
		if GS.relic_mages_melee:
			description = "- Attacks for %m Melee damage."
			desc_modified = true
	if klass == GS.Class.Summoner and item == GS.Item.Scythe:
		if GS.relic_attacks_1dmg_no_resurrect or GS.relic_always_split:
			description = "- Attempts to resurrect imps, but a relic blocks this power."
			desc_modified = true
	
	var tex_path: String = GS.get_body_tex_path(klass)
	
	# TODO: Body types
	%ImpBody.texture = load(tex_path + "/body-m.png")
	%ImpHead.texture = load(tex_path + "/head.png")
	
	%ImpItem.texture = GS.get_item_tex(item)
	
	if %Relic:
		%Relic.queue_free()
	
	var speed := Player.compute_action_speed(klass, item)
	var speed_percent = int(speed.x * 100) # speed.x is the actual speed
	if speed.y > 0.5: # speed.y represents if the speed is modified
		%ActionSpeed.text = str(BBCODE_MODIFIED, speed_percent, "%[/color] action speed")
	else:
		%ActionSpeed.text = str(speed_percent, "% action speed")
		
	if "%m" in description:
		var melee_damage_tuple := Player.compute_melee_relic_damage(klass, item)
		var damage: int = melee_damage_tuple.x
		var modified: bool = bool(melee_damage_tuple.y)
		var str = str(damage)
		if modified:
			str = str(BBCODE_MODIFIED, str, "[/color]")
		# Replace melee damage in the description
		description = description.replace("%m", str)
		
		# For now, %m is a proxy for melee attack. This is maybe bad. Anyway,
		# If this is a thing, add a line about holy scepter.
		if GS.relic_tripledmg_killself:
			description += str(BBCODE_DESC_CHANGE, "\n- Dies on attack.\n[/color]")
	
	%Title.text = str(GS.get_class_name(klass), " / ", GS.get_item_name(item))
	%Description.text = description
	
	if desc_modified:
		%Description.text = str(BBCODE_DESC_CHANGE, description, "[/color]")
	
func update_as_imp() -> void:
	setup_as_imp(id)

func _physics_process(delta: float) -> void:
	var is_hovered = card_rect.get_global_rect().has_point(get_global_mouse_position())
	
	if visible:
		TooltipStack.update_label(description, tooltip_pos.global_position, is_hovered)
	
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
		Row.SECOND_IMP:
			get_parent().unselect_second_imp()
			get_parent().current_second_imp = self
	
	selected = true
	
func _ready() -> void:
	%Card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				select_self()
	)

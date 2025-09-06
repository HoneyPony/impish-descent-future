extends TextureRect
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

## The kind of reward this is.
var kind: RewardKind = RewardKind.IMP

const BBCODE_MODIFIED := "[color=#a0ffc0]"

func setup_as_imp(data, id: int) -> void:
	var klass       = data[0]
	var item        = data[1]
	var description = data[2]
	
	self.id = id
	
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

extends CharacterBody2D

@export var tmp_target: Node = null

@onready var item = $Item
@onready var item_rest = $Body/ItemRest

enum State {
	NO_ACTION,
	MELEE_ATTACK
}

var state: State = State.NO_ACTION

var state_timer = 0.0

var melee_attack_target_pos: Vector2
var melee_attack_target_rot: float

func parabola_one(t: float) -> float:
	t = 2.0 * t - 1.0
	return 1.0 - t * t

func melee_attack(what: Vector2):
	# Only attack if we're not doing something else.
	if state != State.NO_ACTION:
		return
		
	state = State.MELEE_ATTACK
	state_timer = 0.0
	
	melee_attack_target_pos = what
	melee_attack_target_rot = (what - global_position).angle()

func _physics_process(delta):
	# Uncomment this if we want to animate the item
	if state == State.NO_ACTION:
		item.global_transform = item_rest.global_transform
	
	if state == State.MELEE_ATTACK:
		state_timer += delta
		var to_t = parabola_one(state_timer)
		# To update both rotation and angle while sync_to_physics is on, we have to do it in
		# one step.
		var new_tform = Transform2D.IDENTITY
		new_tform = new_tform.rotated(lerp_angle(0.0, melee_attack_target_rot + TAU * 0.25, to_t))
		new_tform.origin = lerp(item_rest.global_position, melee_attack_target_pos, to_t)
		item.global_transform = new_tform
		
		if state_timer >= 1.0:
			item.global_transform = item_rest.global_transform
			state = State.NO_ACTION
			state_timer = 0.0
			
	if Input.is_action_just_pressed("player_right"):
		melee_attack(tmp_target.global_position)
		
		

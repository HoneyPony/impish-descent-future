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
	if state == State.MELEE_ATTACK:
		state_timer += delta
		var to_t = parabola_one(state_timer)
		print(lerp_angle(0.0, melee_attack_target_rot, to_t))
		item.rotation = lerp_angle(0.0, melee_attack_target_rot, to_t)
		print(item.rotation)
		item.global_position = lerp(item_rest.global_position, melee_attack_target_pos, to_t)
		print(item.rotation)
		
		if state_timer >= 1.0:
			item.global_transform = item_rest.global_transform
			state = State.NO_ACTION
			state_timer = 0.0
			
	if Input.is_action_just_pressed("player_right"):
		melee_attack(tmp_target.global_position)
		
		

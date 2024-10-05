extends CharacterBody2D

@export var tmp_target: Node = null

@onready var item = $Item
@onready var item_rest = $ItemRest
@onready var body_sprite = $Body

@onready var melee_range = $MeleeRange

@onready var item_tex = $Item/Look

@export var melee_attack_range = 150
@export var melee_cooldown = 0.3

enum State {
	NO_ACTION,
	MELEE_ATTACK
}

enum Goals {
	GOAL_MELEE
}

var current_item: GS.Item = GS.Item.Scythe
var current_class: GS.Class = GS.Class.Summoner

func set_item(item: GS.Item):
	var tex = null
	
	match item:
		GS.Item.Sword:
			tex = preload("res://players/sword.png")
		GS.Item.Scythe:
			tex = preload("res://players/scythe.png")
		_:
			print("Oops, we don't support that item yet")
	
	item_tex.texture = tex
	current_item = item
	
func set_class(klass: GS.Class):
	var tex = null
	
	match klass:
		GS.Class.Brawler:
			tex = preload("res://players/body0.png")
		GS.Class.Summoner:
			tex = preload("res://players/body3.png")
		_:
			print("Oops, we don't support that class yet")
			
	body_sprite.texture = tex
	current_class = klass

var state: State = State.NO_ACTION
var goal: Goals = Goals.GOAL_MELEE

var state_timer = 0.0

var melee_attack_target_pos: Vector2
var melee_attack_target_rot: float

func parabola_one(t: float) -> float:
	t = 2.0 * t - 1.0
	return 1.0 - t * t

func melee_attack(what: Vector2):
	# Only attack if we're not doing something else.
	if state != State.NO_ACTION || state_timer < melee_cooldown:
		return
		
	state = State.MELEE_ATTACK
	state_timer = 0.0
	
	melee_attack_target_pos = what
	melee_attack_target_rot = (what - global_position).angle()
	
var target_noise = Vector2.ZERO

func _ready():
	item.global_position = item_rest.global_position

func _physics_process(delta):
	# Uncomment this if we want to animate the item
	# Note: Additional latency from the frame being delayed makes this not really work.
	# Probably need to either reparent the item or...?
	if state == State.NO_ACTION:
		#item.sync_to_physics = false
		item.global_transform = item_rest.global_transform
	#else:
		## For now...
		#item.sync_to_physics = true
	
	
	if abs(velocity.x) > 64 and sign(velocity.x) != sign(body_sprite.scale.x):
		body_sprite.scale.x *= -1
		# Uncomment to have the items flip when stuff...
		# I guess for now we'll just leave ItemRest not under Body??
		#item.global_position.x = item_rest.global_position.x
	
	if state == State.NO_ACTION:
		state_timer += delta
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
			
	#if Input.is_action_just_pressed("player_right"):
		#melee_attack(tmp_target.global_position)
		
	var move_target = get_global_mouse_position()
		
	var target_noise_nosmooth = Vector2.from_angle(randf_range(0, TAU)) * randf_range(256, 1024.0)
	var smoothing = 0.05
	
	
	if goal == Goals.GOAL_MELEE:
		var bodies: Array = melee_range.get_overlapping_bodies()
		if not bodies.is_empty():
			var closest = bodies[0]
			var dist = (bodies[0].global_position - global_position).length_squared()
			for i in range(1, bodies.size()):
				var newdist = (bodies[i].global_position - global_position).length_squared()
				if newdist < dist:
					closest = bodies[i]
					dist = newdist
					
			# Move to a random position near the targetted enemy. This hooks into
			# the target_noise system so that we at once:
			# - Don't have extra random offset
			var dir_to = global_position - closest.global_position
			#target_noise_nosmooth = closest.global_position + dir_to.normalized() * 128
			# Ensure that we're headed straight to the average between the player intention
			# and this targetting point
			
			#var player_intention_amount = (move_target - closest.global_position).length() - 128.0
			#player_intention_amount /= 128.0
			#player_intention_amount = clamp(player_intention_amount, 0.0, 1.0)
			
			# Right now we're treating target_noise_nosmooth at itself the real target position
			# To make sure we only try to move near there if the player wants us to, we use
			# an intention amount based on distance.
			# Intention of 0 means do move there -- the lerp of 0 will take us straight there.
			# Intention of 1 means do not -- instead we lerp back to the real move target
			#target_noise_nosmooth = lerp(target_noise_nosmooth, move_target, player_intention_amount)
			# This is how we turn target_noise_nosmooth into the real  target
			#target_noise_nosmooth -= move_target
			
			if dir_to.length_squared() < melee_attack_range * melee_attack_range:
				melee_attack(closest.global_position)
		
	target_noise += (target_noise_nosmooth - target_noise) * smoothing
		
	move_target += target_noise
	var vel = (move_target - global_position) * 5.0
	velocity = vel.limit_length(256)
	
	# Add impulses for each nearby imp.
	for imp in get_tree().get_nodes_in_group("Players"):
		var to_vec = global_position - imp.global_position
		if to_vec.length_squared() < 72.0 * 72.0:
			var impulse = 1024.0 * to_vec / (to_vec.length_squared() + 0.005)
			#print(impulse)
			velocity += impulse
	
	
	
	move_and_slide()
		

func on_hit():
	# Summoner with sycthe: summons new imp on hit
	if current_class == GS.Class.Summoner && current_item == GS.Item.Scythe:
		GS.spawn_imp(get_parent(), GS.valid_imps.pick_random(), global_position)

func on_death():
	pass
		

func _on_hazard_body_entered(body):
	body.hit_player()
	# TODO: Check shields, etc
	on_hit()
	on_death()
	queue_free()

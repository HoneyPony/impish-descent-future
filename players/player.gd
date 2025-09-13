extends CharacterBody2D
class_name Player

@onready var item = $Item
@onready var item_rest = $ItemRest

@onready var melee_range = $EnemyRange

@onready var item_tex = $Item/Look

@onready var melee_collision_shape = $Item/CollisionShape2D

@onready var player_anim: PlayerAnimation = %PlayerAnim

@export var melee_attack_range = 150
#@export var melee_cooldown = 0.3

# TODO: Get rid of this...?
@export var action_cooldown = 0.3

var formation: ImpFormation = null

var formation_position: Vector2 = Vector2.ZERO

# NOTE: Only set this to positive if you've actually added an ethereal buff.
var ethereal_lifetime = -1.0

enum DamageMode {
	Fixed,
	Random
}

var damage_mode: DamageMode = DamageMode.Fixed

var is_dead: bool = false

# We need to reset this each time we melee swing due to the possibility of buffs.
# (too stateful, I guess...)
var melee_base_damage = 1
var ranged_base_damage = 1

# Counter for splitter guy
var other_players_hit = 0

var action_speed = 1.0
# This should never be slower than action speed, but it should often be faster.
var melee_speed = 1.0

var ranged_attack_target: Node2D = null
var ranged_attack_target_cached: Vector2 = Vector2.ZERO

var buff_target_buff: GS.Buff = GS.Buff.None

var projectile_scene: PackedScene = GS.PlayerProjectile1

var invulnerability = 0

## Which slot this imp corresponds to in the army.
##
## Used for permanent effects, for now just formation edit. TODO: How does
## this interact with split, if we have permanent scaling ever..?
var army_id: int = -1

enum State {
	NO_ACTION,
	MELEE_ATTACK,
	RANGED_ATTACK,
	SIMPLE_ACTION
}

enum Goals {
	GOAL_MELEE,
	GOAL_RANGED,
	GOAL_BUFF,
	GOAL_NONE,
	GOAL_ATTACK_OWN,
	GOAL_GENERIC,
}

var current_item: GS.Item = GS.Item.Staff
var current_class: GS.Class = GS.Class.Mage

var buffs = [GS.Buff.None, GS.Buff.None, GS.Buff.None]

var ranged_attack_is_nova: bool = false

# TODO: Deduplicate this with split buff?
# Set this when this enemy  is split, so it can choose a relevant position in
# the formation.
var spawn_as_split_flag: bool = false

func grab_buff_tex(buf):
	match buf:
		GS.Buff.None:
			return null
		GS.Buff.Shield:
			return preload("res://buffs/buff_protect.png")
		GS.Buff.Dagger:
			return preload("res://buffs/buff_dagger.png")
		GS.Buff.Split:
			return preload("res://players/buff_split.png")
		GS.Buff.Ethereal:
			return preload("res://buffs/buff_ethereal.png")
		_:
			print("unknown buff!")
			return null

func render_buffs():
	# NOTE: 1am code
	# Probably better way to shift these down...
	if buffs[1] == GS.Buff.None && buffs[2] != GS.Buff.None:
		buffs[1] = buffs[2]
		buffs[2] = GS.Buff.None
	if buffs[0] == GS.Buff.None && buffs[2] != GS.Buff.None:
		buffs[0] = buffs[2]
		buffs[2] = GS.Buff.None
	if buffs[0] == GS.Buff.None && buffs[1] != GS.Buff.None:
		buffs[0] = buffs[1]
		buffs[1] = GS.Buff.None

	$Buff0.texture = grab_buff_tex(buffs[0])
	$Buff1.texture = grab_buff_tex(buffs[1])
	$Buff2.texture = grab_buff_tex(buffs[2])

func set_item(item: GS.Item):
	item_tex.texture = GS.get_item_tex(item)
	current_item = item
	
func set_class(klass: GS.Class):
	player_anim.fill_textures(GS.get_body_tex_path(klass))
	# body_sprite.texture = GS.get_body_tex(klass)
	current_class = klass

# general buff to melee speed
const MELEE_GENERAL_BUFF = 1.2

## Computes the action speed for the given Class. Returns a Vector2 tuple:
## - The x component is the actual speed
## - The y component is 0 if no modifiers were applied; it is 1 if some
##   modifier was applied.
##
## TODO: Consider putting the base speed value just in the big table of guys?
static func compute_action_speed(klass: GS.Class, item: GS.Item) -> Vector2:
	var speed    := 1.0
	var modified := false
	
	match klass:
		GS.Class.Brawler:
			match item:
				GS.Item.Dagger: speed = 2.0
				GS.Item.Club:   speed = 0.5
		GS.Class.Mage:
			match item:
				GS.Item.Club:   speed = 0.5
				GS.Item.Scythe: speed = 0.5
		GS.Class.Cleric:
			match item:
				# The shield is very very strong at 100% speed. Make it a bit slower.
				GS.Item.Staff: speed = 0.5
				# Split-resurrect is VERY strong. Make these guys act very slowly.
				GS.Item.Scythe: speed = 0.25
		GS.Class.Summoner:
			match item:
				# Make summoning eth guys very slow.
				GS.Item.Staff: speed = 0.25
				# resurrecting can actually be quite fast.
				_: speed = 1.5
				
	if GS.relic_daggers_150_speed and item == GS.Item.Dagger:
		speed *= 1.5
		modified = true
	
	return Vector2(speed, 1.0 if modified else 0.0)
	
# Computes intrinsic class-based properties before we get to the effects of
# relics.
func compute_basic_properties():
	action_speed = compute_action_speed(current_class, current_item).x
	
	if GS.relic_daggers_150_speed and current_item == GS.Item.Dagger:
		# Also change the cooldown.
		action_cooldown /= 1.5
	
	damage_mode = DamageMode.Fixed
	match current_class:
		GS.Class.Brawler:
			# Brwaler is thankfully always melee.
			goal = Goals.GOAL_MELEE
			match current_item:
				GS.Item.Sword:
					melee_base_damage = 2
				GS.Item.Dagger:
					melee_base_damage = 1
				GS.Item.Club:
					melee_base_damage = 3
				GS.Item.Mace:
					melee_base_damage = 5
					$Item.only_half_health = true
			
		GS.Class.Mage:
			goal = Goals.GOAL_RANGED
			ranged_base_damage = 1
			if current_item == GS.Item.Dagger:
				goal = Goals.GOAL_BUFF
				buff_target_buff = GS.Buff.Dagger
			if current_item == GS.Item.Club:
				ranged_base_damage = 4
				damage_mode = DamageMode.Random
			if current_item == GS.Item.Scythe:
				ranged_base_damage = 1
				ranged_attack_is_nova = true
				
			# Relic can turn mages into melee fighters
			if GS.relic_mages_melee:
				melee_base_damage = 3
				goal = Goals.GOAL_MELEE
		GS.Class.Cleric:
			goal = Goals.GOAL_BUFF
			buff_target_buff = GS.Buff.Shield
			
			match current_item:
				GS.Item.Scythe:
					goal = Goals.GOAL_ATTACK_OWN
					projectile_scene = GS.SplitProjectile
				GS.Item.Dagger:
					melee_base_damage = 1
					goal = Goals.GOAL_MELEE
					$Item.upgrades_on_kill = true
		GS.Class.Summoner:
			# Summoner can't do anything but get hit by default.
			goal = Goals.GOAL_GENERIC
			# Summoner has powerful effects that are slow.
	
var state: State = State.NO_ACTION
var goal: Goals = Goals.GOAL_MELEE

var state_timer = 0.0

var melee_attack_target_pos: Vector2
var melee_attack_target_rot: float
# The melee timer is separate from the state timer as it should usually tick
# faster.
var melee_timer = 0.0

func parabola_one(t: float) -> float:
	t = 2.0 * t - 1.0
	return 1.0 - t * t
	
func start_generic():
	if state != State.NO_ACTION || state_timer < action_cooldown:
		return
		
	if not happy_to_start_action():
		return
		
	state = State.SIMPLE_ACTION
	state_timer = 0.0

func melee_attack(what: Vector2):
	# Only attack if we're not doing something else.
	if state != State.NO_ACTION || state_timer < action_cooldown:
		return
		
	state = State.MELEE_ATTACK
	state_timer = 0.0
	melee_timer = 0.0
	
	Sounds.imp_act_crunchy.play_rand()
	
	$Item.damage = melee_base_damage
	melee_attack_target_pos = what
	melee_attack_target_rot = (what - global_position).angle()
	
func ranged_attack(target: Node2D):
	if state != State.NO_ACTION || state_timer < action_cooldown:
		return
		
	state = State.RANGED_ATTACK
	state_timer = 0.0
	
	ranged_attack_target = target
	ranged_attack_target_cached = target.global_position
	
var target_noise = Vector2.ZERO

func _ready():
	
	item.global_position = item_rest.global_position
	add_to_group("Players")
	
	# For now, we just get our formation from the group.
	formation = get_tree().get_first_node_in_group("ImpFormation")
	assert(formation)
	
	if army_id >= 0:
		formation_position = GS.current_formation[army_id] * 32
		# Reset to the formation position for editing if we're in the menu
		if GS.flag_in_formation_menu:
			global_position = formation.global_position + formation_position
		print("my pos: ", formation_position)
	else:
		# If we're a split guy, try to get a position near the middle, for now.
		if spawn_as_split_flag:
			formation_position = GS.take_middle_formation() * 32
		else:
			# Get a formation position from the temporary ones, if possible.
			var pos = GS.formation_avail_temp.pop_back()
			if pos != null:
				formation_position = pos * 32
	
	# TODO: Just delete the FormationEdit once the formation is done being
	# edited? Although I guess we might have the option to re-edit it dynamically...
	%FormationEdit.input_event.connect(func(viewport: Node, event: InputEvent, shape_idx: int):
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				if formation.edited_player == null:
					formation.edited_player = self
	)
	
func finalize_properties():
	
	# TODO: Do we actually do this here? Probably not
	# compute_basic_properties()
	
	# Set up our range based on our goals.
	if goal == Goals.GOAL_RANGED or goal == Goals.GOAL_BUFF:
		$EnemyRange/CollisionShape.shape.radius *= 3
		
	if goal == Goals.GOAL_BUFF:
		projectile_scene = GS.BuffProjectile
		
	render_buffs()
	
	# General melee buff: Increase our action speed because melee is hard.
	if goal == Goals.GOAL_MELEE:
		action_speed *= MELEE_GENERAL_BUFF
	
	# The melee collision is only on when we are attacking melee.
	melee_collision_shape.disabled = true
	
	# Make the melee speed at least as good as the action speed
	melee_speed = action_speed
	melee_speed = max(melee_speed, 1.2)
	
	$Item.slowness = 1.0 / action_speed
	
	#print(action_cooldown)
	
	
	# DEBUG DEBUG DEBUG
	#melee_base_damage *= 10
	#ranged_base_damage *= 10

func target_meets_goals(enemy) -> bool:
	if $Item.only_half_health:
		return enemy.health * 2 <= enemy.max_health
	return true
	
func happy_to_start_action() -> bool:
	if current_class == GS.Class.Summoner:
		if current_item == GS.Item.Scythe:
			# Don't try to take hits if there are no dead imps.
			if 0 == get_tree().get_node_count_in_group("DeadPlayers"):
				return false
			return true
		return true
	return false
	
func fire_generic_action():
	# Summoner with staff: summons new imp on hit
	if current_class == GS.Class.Summoner:
		if current_item == GS.Item.Staff:
			GS.spawn_imp(get_parent(), GS.pick_nonbreaking_imp(), global_position,
				false, true)
		# WIth sycthe: resurrect a random imp
		if current_item == GS.Item.Scythe:
			var dead = get_tree().get_nodes_in_group("DeadPlayers")
			if not dead.is_empty():
				var player = dead.pick_random()
				player.resurrect()

const MAX_VEL = 512

func _formation_physics_process(delta: float) -> void:
	if formation.edited_player == self:
		#print(get_global_mouse_position())
		#print(formation.global_position)
		formation_position = get_global_mouse_position() - formation.global_position
		var formation_pos_i = round(formation_position / 32)
		formation_position = formation_pos_i * 32
		#GS.current_formation[army_id] = Vector2i(formation_pos_i)
		#print(formation_position)
		
		
		if not Input.is_action_pressed("edit_player"):
			# Finalize ourselves here.
			formation.edited_player = null
			var fpi := Vector2i(formation_pos_i)
			var prev: Vector2i = GS.current_formation[army_id]
			
			# If we can use this new position cause it's avail, do so.
			#
			# TODO: Let us swap with another player if they're there.
			if fpi in GS.formation_avail_perm:
				GS.formation_avail_perm.erase(fpi)
				GS.formation_avail_perm.append(prev)
				GS.current_formation[army_id] = fpi
				GS.sort_formation_avail()
			# Now update our actual position
			formation_position = GS.current_formation[army_id] * 32.0
			#if GS.formation_avail_perm.erase()
				
		global_position = formation.global_position + formation_position
	else:
		global_position = formation.global_position + formation_position
		pass

func _physics_process(delta: float) -> void:
	if GS.has_won:
		return
	
	if is_dead:
		return
		
	if GS.flag_in_formation_menu:
		_formation_physics_process(delta)
		return
		
	if invulnerability > 0:
		modulate = Color(1.5, 1, 1, 0.8)
		invulnerability -= delta
	else:
		modulate = Color(1, 1, 1)
		
	if ethereal_lifetime > 0.0:
		ethereal_lifetime -= delta
		if ethereal_lifetime <= 0:
			die(null)
	
	# Uncomment this if we want to animate the item
	# Note: Additional latency from the frame being delayed makes this not really work.
	# Probably need to either reparent the item or...?
	if state == State.NO_ACTION:
		#item.sync_to_physics = false
		item.global_transform = item_rest.global_transform
	#else:
		## For now...
		#item.sync_to_physics = true
	
	
	if abs(velocity.x) > 128 and sign(velocity.x) != sign(player_anim.scale.x):
		player_anim.scale.x *= -1
		# Uncomment to have the items flip when stuff...
		# I guess for now we'll just leave ItemRest not under Body??
		#item.global_position.x = item_rest.global_position.x
	
	if state == State.NO_ACTION:
		state_timer += delta
	if state == State.SIMPLE_ACTION:
		var may_fire = state_timer < 0.5
		state_timer += delta * action_speed
		var to_t = parabola_one(state_timer)
		if state_timer >= 0.5 && may_fire:
			Sounds.imp_act.play_rand()
			fire_generic_action()
			
		var tform = item_rest.global_transform
		tform = tform.rotated_local(TAU * -0.125 * to_t)
		tform = tform.translated(Vector2(0, to_t * -16))
		
		item.global_transform = tform
		if state_timer >= 1.0:
			item.global_transform = item_rest.global_transform
			state = State.NO_ACTION
			state_timer = 0.0
	if state == State.MELEE_ATTACK:

		state_timer += delta * action_speed
		# the melee timer will finish before the action timer
		melee_timer = clamp(melee_timer + delta * melee_speed, 0.0, 1.0)
			
		var to_t = parabola_one(melee_timer)
		# The cooldown is basically the remaining time in the animation.
		# Because then, we can attack again.
		$Item.slowness = (1.0 - to_t) / melee_speed + action_cooldown
		melee_collision_shape.disabled = not (to_t > 0.25 and to_t < 0.75)
			
		# To update both rotation and angle while sync_to_physics is on, we have to do it in
		# one step.
		var new_tform = Transform2D.IDENTITY
		new_tform = new_tform.rotated(lerp_angle(0.0, melee_attack_target_rot + TAU * 0.25, to_t))
		new_tform.origin = lerp(item_rest.global_position, melee_attack_target_pos, to_t)
		item.global_transform = new_tform
		
		if melee_timer >= 0.6:
			if GS.relic_tripledmg_killself and not self.is_ethereal():
				die(null)
				item.global_transform = item_rest.global_transform
				state = State.NO_ACTION
				state_timer = 0.0
				melee_timer = 0.0
		
		if state_timer >= 1.0:
			item.global_transform = item_rest.global_transform
			state = State.NO_ACTION
			state_timer = 0.0
			melee_timer = 0.0
			
		
	elif state == State.RANGED_ATTACK:
		var may_fire = state_timer < 0.5
		state_timer += delta * action_speed
		
		var to_t = parabola_one(state_timer)
		
		if ranged_attack_target != null:
			ranged_attack_target_cached = ranged_attack_target.global_position
			
		if state_timer >= 0.5 && may_fire:
			Sounds.imp_act.play_rand()
			if ranged_attack_is_nova:
				# Buffs are very vvery good on nova.
				var damage: int = get_buffed_damage(ranged_base_damage)
				for i in range(0, 7):
					var projectile = projectile_scene.instantiate()
					projectile.global_position = item.global_position
					projectile.velocity = Vector2.from_angle(randf_range(0, TAU)) * 512.0
					projectile.damage = damage
					add_sibling(projectile)
			else:
				# Fire the projectile when we cross the 0.5 on the timer.
				var projectile = projectile_scene.instantiate()
				projectile.global_position = item.global_position
				var vel = ranged_attack_target_cached - item.global_position
				# Hack for buff related textures
				if goal == Goals.GOAL_ATTACK_OWN:
					projectile.projectile_source = self
					# do nothing special...?
					pass
				elif goal == Goals.GOAL_BUFF:
					# TODO: Actually set our buff intent
					projectile.set_sprite(grab_buff_tex(buff_target_buff))
					projectile.buff = buff_target_buff
					projectile.projectile_source = self
				elif goal == Goals.GOAL_RANGED:
					# Use up damage buffs when the projectile is fired.
					projectile.damage = get_buffed_damage(ranged_base_damage)
				
				# TODO: Somehow set this velocity when relevant
				projectile.velocity = vel.normalized() * 512.0
				add_sibling(projectile)
			
		var target_rot = item.global_position.angle_to_point(ranged_attack_target_cached)
		item.rotation = lerp_angle(0.0, target_rot + TAU * 0.25, to_t)
		
		if state_timer >= 1.0:
			item.global_transform = item_rest.global_transform
			state = State.NO_ACTION
			state_timer = 0.0
			
	#if Input.is_action_just_pressed("player_right"):
		#melee_attack(tmp_target.global_position)
		
	if goal == Goals.GOAL_GENERIC:
		start_generic()
		
	var move_target = formation.global_transform * formation_position
		
	var target_noise_nosmooth = Vector2.ZERO # Vector2.from_angle(randf_range(0, TAU)) * randf_range(256, 1024.0)
	var smoothing = 0.05
	
	var stay_away_enemies = false
	# These cases always stay away.
	if goal == Goals.GOAL_RANGED or goal == Goals.GOAL_BUFF or goal == Goals.GOAL_ATTACK_OWN:
		stay_away_enemies = true
	# Summoner stays away if we don't want to be hit yet.
	if current_class == GS.Class.Summoner:
		stay_away_enemies = true
	
	if goal == Goals.GOAL_MELEE:
		var bodies: Array = melee_range.get_overlapping_bodies()
		if not bodies.is_empty():
			var closest = bodies[0]
			var dist = (bodies[0].global_position - global_position).length_squared()
			var meets_goals = target_meets_goals(bodies[0])
			for i in range(1, bodies.size()):
				var newdist = (bodies[i].global_position - global_position).length_squared()
				var new_meets_goals = target_meets_goals(bodies[i])
				
				var better = false
				if new_meets_goals and not meets_goals:
					better = true
				else:
					better = newdist < dist
				
				if better:
					closest = bodies[i]
					dist = newdist
					meets_goals = new_meets_goals
					
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
				# Target the center of enemies (averaging 2 tiles large)
				melee_attack(closest.global_position + Vector2(0, -64))
		# If we're ranged, we want to avoid damage, so back away from nearby enemies
		# TODO: I guess we want a larger ranged here..?
		
	if goal == Goals.GOAL_RANGED:
		var bodies: Array = melee_range.get_overlapping_bodies()
			
		# Ranged characters actually try to attack the enemies
		if not bodies.is_empty() and goal == Goals.GOAL_RANGED:
			var closest = bodies[0]
			var dist = (bodies[0].global_position - global_position).length_squared()
			for i in range(1, bodies.size()):
				var newdist = (bodies[i].global_position - global_position).length_squared()
				if newdist < dist:
					closest = bodies[i]
					dist = newdist
			
			ranged_attack(closest)
			
		
	target_noise += (target_noise_nosmooth - target_noise) * smoothing
		
	# move_target += target_noise
	
	move_target = GS.get_nav_move_target(global_position, move_target)
	var vel = (move_target - global_position) * 5.0
	
	#vel.x = Input.get_axis("player_left", "player_right")
	#vel.y = Input.get_axis("player_up", "player_down")
	#vel = vel.normalized() * MAX_VEL
	
	# Let us move slightly faster than the formation moves, so that we can
	# stay in position.
	var vel_buf = 1.5 #clamp((move_target - global_position).length() / 100.0, 1.0, 1.3)
	var target_vel = vel.limit_length(MAX_VEL * vel_buf)
	
	velocity += (target_vel - velocity) * 0.5
	
	## Add impulses for each nearby imp.
	var all_players = get_tree().get_nodes_in_group("Players")
	#for imp in all_players:
		#var impulse_strength = 2048
		#var max_range = 72
		#var stay_away = false
		##if happy_to_take_hit() != imp.happy_to_take_hit():
		##	stay_away = true
		## summoners want to get hit, so make them stay far away from other imps.
		#if stay_away:
			#impulse_strength = 2048
			#max_range = 256
		#var to_vec = global_position - imp.global_position
		#if to_vec.length_squared() < max_range * max_range:
			#var impulse = impulse_strength * to_vec / (to_vec.length_squared() + 512)
			##print(impulse)
			#velocity += impulse
	
	if goal == Goals.GOAL_BUFF or goal == Goals.GOAL_ATTACK_OWN:
		# 10 tries to find a player
		var target_player = all_players[0]
		for i in range(0, 10):
			var player = all_players.pick_random()
			if player == self:
				continue
			# Always overwrite a target of self, as that's a really bad target.
			if target_player == self:
				target_player = player
				continue
			# Break if we find a good target
			if goal == Goals.GOAL_BUFF:
				# When we're buffing, look for players with an empty buff.
				if player.has_empty_buff():
					target_player = player
					break
				elif not player.is_split(true):
					target_player = player
					break
		# Only bother doing anything if we have a real target
		if target_player != self:
			# We re-use the ranged attack logic.
			ranged_attack(target_player)

	move_and_slide()
	player_anim.update_tree(get_real_velocity().length() / MAX_VEL)
	
	#if goal == Goals.GOAL_ATTACK_OWN:
		#if other_players_hit >= 5:
			#on_death(null)
			#queue_free()
		


func on_hit(body):
	

	if body.projectile_source != null:
		if is_instance_of(body.projectile_source, Player):
			body.projectile_source.other_players_hit += 1
			

func split_into_eth():
	# Cannot split if already eth or split.
	if self.is_split(true):
		return
		
	var pos = self.global_position
	GS.spawn_imp(get_parent(), [self.current_class, self.current_item], pos, false, true, true, true)

var did_split: bool = false
func split(new_army_id: int = -1):
	if self.is_split(true):
		return
	
	#var split_dmg = melee_base_damage
	#if self.goal != Goals.GOAL_MELEE:
		#split_dmg = ranged_base_damage
	#split_dmg -= 1
	#if split_dmg < 0:
		#split_dmg = 0
	var pos = self.global_position
	#pos += Vector2.from_angle(randf_range(0, TAU)) * randf_range(16, 256)
	GS.spawn_imp(get_parent(), [self.current_class, self.current_item], pos, true,
		false, true, false, new_army_id)
	did_split = true # Keep track of this..?

func set_own_damage(amount: int):
	melee_base_damage = amount
	ranged_base_damage = amount

# Return whether to outright delete the palyer (prevent it from resurrecting)
func on_death(body) -> bool:
	if not self.is_split():
		# Splitters can't themselves be split.
		if body != null and is_instance_of(body, SplitBuff) and self.goal != Goals.GOAL_ATTACK_OWN:
			split(-1)
			split(army_id)
			# Don't let us resurrect after we split
			return true
		# In order to ensure that the relic doesn't change the bevhaivor of whether we can resurrect
		# on split, we add this second part of the condition.
		#elif GS.relic_always_split:
			#split()
			#split()
			#return true
			
	if not is_ethereal() and GS.relic_always_split:
		# Non-ethereal imps get essenced-of-slime'd.
		split_into_eth()
		split_into_eth()
		split_into_eth()
		# And we're perma-dead. But, we also checkc this below.
		return true
	return false	

func _on_hazard_body_entered(body):
	if GS.has_won:
		return
	
	if is_dead:
		return
	
	if body.projectile_source == self:
		return
		
	# Split players can't be split again.
	# This includes ethereal players.
	if body != null and is_instance_of(body, SplitBuff) and body.still_has_split:
		if self.is_split(true):
			return
		else:
			# Die to splitbuffs in general.
			die(body)
			return
			
	# Ignore attacks while invulnverable
	if invulnerability > 0:
		return
	
	body.hit_target(self)
	# TODO: Check shields, etc
	on_hit(body)
	invulnerability = 0.5
	
	if not GS.relic_shields_are_damage:
		for i in range(0, 3):
			if buffs[i] == GS.Buff.Shield:
				# If we had a shield, it saves us from the hit
				buffs[i] = GS.Buff.None
				render_buffs()
				# Don't die now, play hit sound
				Sounds.imp_hit.play_rand()
				return
	
	
	# Do die now
	die(body)
	
func resurrect():
	remove_from_group("DeadPlayers")
	add_to_group("Players")
	
	# Undo other changes
	$Item/Look.show()
	player_anim.modulate = Color(1, 1, 1)
	# Back to life
	is_dead = false
	
	# Resurrected imps spawn with one shield?
	add_buff(GS.Buff.Shield)
	Sounds.imp_spawn.play_rand()
	#invulnerability = 1.0
	
func die(killer_projectile):
	if GS.has_won:
		print("Warning: Somehow died after we won")
		return
	
	# note that on death happens before we die, so we can't e.g. resurrect ourselves
	# on death.
	var perma = on_death(killer_projectile)
	
	# Ethereal imps can't be resurrected
	if is_ethereal() or perma or GS.relic_attacks_1dmg_no_resurrect or GS.relic_always_split:
		var explode = GS.PlayerExplode.instantiate()
		explode.global_position = global_position
		add_sibling(explode)
		queue_free()
		
		# If we died permanently, then put our formation position back onto
		# the list.
		if not did_split:
			# If we got here because we split and "died", then don't put our
			# position back on the list.
			var pos = Vector2i(formation_position / 32.0)
			GS.formation_avail_temp.append(pos)
			GS.sort_formation_temp()
		
		Sounds.imp_kill_eth.play_rand()
		return
	
	remove_from_group("Players")
	add_to_group("DeadPlayers")
	
	Sounds.imp_kill.play_rand()
	
	# Clear buffs when we die
	for i in range(0, 3):
		buffs[i] = GS.Buff.None
	render_buffs()
	
	# Hide our item when we die
	$Item/Look.hide()
	player_anim.modulate = Color(0.5, 0.5, 0.5)
	# We will stop doing stuff till we're resurrected
	is_dead = true
	# TODO Show a "dead" sprite

func add_buff(buff: GS.Buff):
	for i in range(0, 3):
		if buffs[i] == GS.Buff.None:
			# Sounds.buffed.play_rand()
			buffs[i] = buff
			if buff == GS.Buff.Ethereal:
				ethereal_lifetime = 4.0
			render_buffs()
			return

func _on_buff_body_entered(body):
	if is_dead:
		return
	
	# Don't consume buffs we created
	if body.projectile_source == self:
		return
	for i in range(0, 3):
		# Don't consume buffs if we already have 3.
		if buffs[i] == GS.Buff.None and body.buff != GS.Buff.None:
			buffs[i] = body.buff
			Sounds.buffed.play_rand()
			render_buffs()
			body.hit_target(self)
			return

func has_empty_buff():
	for i in range(0, 3):
		if buffs[i] == GS.Buff.None:
			return true
			
func is_split(count_eth: bool = false):
	for i in range(0, 3):
		if buffs[i] == GS.Buff.Split:
			return true
		if count_eth and buffs[i] == GS.Buff.Ethereal:
			return true
			
	return false
	
func is_ethereal():
	for i in range(0, 3):
		if buffs[i] == GS.Buff.Ethereal:
			return true
	return false
			
func get_buffed_damage(damage: int) -> int:
	# Randomize damage if it's random.
	if damage_mode == DamageMode.Random:
		damage = randi_range(0, damage)
		
	if GS.relic_attacks_1dmg_no_resurrect and goal == Goals.GOAL_MELEE:
		damage += 1
	
	for i in range(0, 3):
		# Split buff/debuff is never consumed
		if buffs[i] == GS.Buff.Split:
			damage = randi_range(0, damage)
			if damage < 0:
				damage = 0
		
	if GS.relic_shields_are_damage:
		for i in range(0, 3):
			if buffs[i] == GS.Buff.Shield:
				buffs[i] = GS.Buff.None
				render_buffs()
				damage += 2
				break
	
	# Consume dagger buff and return separately
	for i in range(0, 3):
		if buffs[i] == GS.Buff.Dagger:
			buffs[i] = GS.Buff.None
			render_buffs()
			damage += 1
			break
			
	if GS.relic_tripledmg_killself:
		if not self.is_ethereal() and goal == Goals.GOAL_MELEE:
			damage *= 3
			
	return damage

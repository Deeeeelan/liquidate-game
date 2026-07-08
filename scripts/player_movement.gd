extends CharacterBody2D

@export var select: AnimatedSprite2D

@export var debris: Node2D

@export var items: Array[Dictionary] = []
var max_items = 3

const BASE_SPEED: float = 800.0
const MAX_SPEED: float = 1300.0
var current_speed: float = 0.0
var curr_accel: float = 0.0
const ACCELERATION: float = 0.2

const BASE_JUMP: float = -600.0
const LERP_SPEED: float = 0.08
var jumps: int = 0
const MAX_JUMPS: int = 2

var dashes: int = 0
const MAX_DASHES: int = 1
const DASH_VEL: float  = 2750
var dash_cd = false
const DASH_TIME: float  = 0.5


var direction: float = 0
var last_dir: float = 0
var jmp_debounce = false

const WALL_JUMP_X_VEL = 2400
var last_wall_jump_dir = 0

var coyote_time_valid = false
var coyote_time_started = false
const COYOTE_TIME = 0.22

const SLAM_GRAV_MULT: float = 4.0
var can_slam = false

var grab_ledge = false
var ledge_check = false

const SLIDE_VEL = 3000
var slide_cd = false
const Slide_TIME: float  = 0.6
var selected_item: Area2D
var slide_slam_stop = false

const GRAVITY_MULT: float = 1.5

var has_dash_mom = false

const GLASS_SHARDS = preload("res://assets/nodes/glass_shards.tscn")

func debug_point(pos: Vector2, color: Color = Color(1.0, 1.0, 1.0, 1.0)):
	var node = $Sprite2D.duplicate()
	node.scale = Vector2(0.2, 0.2)
	node.modulate = color
	$'..'.add_child(node)
	node.global_position = pos

func process_jump_y(j_add: bool):
	if j_add: jumps += 1
	velocity.y = min(BASE_JUMP, velocity.y + BASE_JUMP)
	
	get_tree().create_timer(0.1).timeout.connect(func():
		jmp_debounce = false
		)
	
# one of the one liners of all time
func get_jump_condition(wall: bool):
	return not jmp_debounce and ((Input.is_action_just_pressed("jump") and ((wall and jumps <= MAX_JUMPS) or jumps < MAX_JUMPS)) or (Input.is_action_pressed("jump") and jumps == 0))

func find_tick():
	var cols = $Pickup.get_overlapping_areas()
	var closest_col: Area2D
	var closest_dist = 9999
	for col in cols:
		if col.is_in_group("item"):
			var space_state = get_world_2d().direct_space_state
			var horiz_query = PhysicsRayQueryParameters2D.create(global_position, col.global_position)
			horiz_query.exclude = [self]
			var horiz_result = space_state.intersect_ray(horiz_query)
			if not horiz_result and (col.position - position).length() < closest_dist:
				closest_dist = (col.position - position).length()
				closest_col = col
	if closest_col:
		selected_item = closest_col
		var tween = get_tree().create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(select, "position", closest_col.position, 0.55)
		tween.play()
		select.visible = true
	else:
		selected_item = null
		select.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pickup"): # SELL ITEMS
		if $Interact.overlaps_area(%Truck) and len(items) > 0:
			var total = 0
			for item in items:
				total += item.value
				item.gui.queue_free()
			items.clear()
			GameManager.score += total
			%Score.label_settings.font_color = Color(0.0, 1.0, 0.0, 1.0)
			%CashSFX.play()
			var tween = get_tree().create_tween()
			tween.tween_property(%Score.label_settings, "font_color", Color(0.0, 0.0, 0.0, 1.0), 1)
			tween.play()
		elif len(items) < max_items and selected_item != null:
			var tex_copy = selected_item.sprite.duplicate()
			var tex_rect = TextureRect.new()
			tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			tex_rect.texture = tex_copy
			%ItemsGUI.add_child(tex_rect)
			items.append({sprite = selected_item.sprite.duplicate(), value = selected_item.value, gui = tex_rect})

			var sprite = Sprite2D.new()
			sprite.texture = selected_item.sprite
			sprite.position = selected_item.position
			debris.add_child(sprite)
			var tween = get_tree().create_tween().set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN_OUT)
			tween.tween_property(sprite, "global_position", global_position, 0.35)
			tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.2)
			tween.play()
			selected_item.queue_free()

func interact_collide(area: Area2D):
	if area.is_in_group("instant"):
		GameManager.score += area.value
		area.queue_free()

func _ready() -> void:
	$FindTick.timeout.connect(find_tick)
	$Interact.area_entered.connect(interact_collide)
	

func _physics_process(delta: float) -> void:
	if has_dash_mom:
		var space_state = get_world_2d().direct_space_state
		var horiz_query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(direction * 128, 0))
		horiz_query.exclude = [self]
		var horiz_result = space_state.intersect_ray(horiz_query)

		if horiz_result:
			if horiz_result.collider.is_in_group("glass"):
				
				%GlassSFX.play()
				var shards = GLASS_SHARDS.instantiate()
				shards.position = horiz_result.collider.position
				debris.add_child(shards)
				shards.emitting = true
				get_tree().create_timer(5.0).timeout.connect(func():
					shards.queue_free()
					)
				horiz_result.collider.queue_free()
				get_tree().create_timer(0.06).timeout.connect(func():
					velocity.x = last_dir * DASH_VEL * 0.75
					)
				
	# scrapped cuz its annoying to debug
	# ledge grabbing: (I need to plan this out since I dunno how to visualize this)
	# uh so basically horiz. raycast in char direction + raycast offet in direction facing down
	# if raycasts are the some collision = distance < certian param jump is overriden and player
	# smoothly moves/"clips" corner without losing momentum
	# NOTE: player cannot grab onto ledges greater than raycast offset
	if Input.is_action_pressed("jump") and not ledge_check:
		ledge_check = true
		var space_state = get_world_2d().direct_space_state
		var origin = global_position + Vector2(last_dir * 32, 48) # bottom-ish left corner
		
		var offset_pos = origin + Vector2(last_dir * 64, 0)
		var horiz_query = PhysicsRayQueryParameters2D.create(origin, offset_pos)
		horiz_query.exclude = [self]
		var horiz_result = space_state.intersect_ray(horiz_query)
		var down_query = PhysicsRayQueryParameters2D.create(offset_pos + Vector2(0, -129), offset_pos + Vector2(0, 32))
		var down_result = space_state.intersect_ray(down_query)
		var air_query = PhysicsPointQueryParameters2D.new()
		air_query.position = offset_pos + Vector2(0, -129)
		var air_result = space_state.intersect_point(air_query)
		# debug_point(offset_pos + Vector2(0, -129), Color(0.0, 0.651, 0.604, 1.0))
		# print(air_result)
		# get_tree().create_timer(randf(0.005, 0.06)).timeout.connect(func():)
		#debug_point(origin, Color(0.0, 0.651, 0.604, 1.0))
		#debug_point(offset_pos, Color(0.0, 0.651, 0.604, 1.0))
		#debug_point(offset_pos + Vector2(0, -180), Color(1.0, 0.208, 0.604, 1.0))
		#debug_point(offset_pos + Vector2(0, -132), Color(1.0, 0.208, 0.604, 1.0))
		#debug_point(offset_pos + Vector2(0, 32), Color(1.0, 0.208, 0.604, 1.0))
		if horiz_result and down_result and (not air_result) and (not grab_ledge):
			var target_pos = down_result.position - Vector2(0, 64)
			grab_ledge = true
			
			#debug_point(target_pos )
			#debug_point(horiz_result.position, Color(0.722, 0.526, 0.0, 1.0))

			var tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(self, "global_position", target_pos, 0.21)
			collision_layer = 0
			collision_mask = 0
			tween.play()
			tween.finished.connect(func():
				collision_layer = 1
				collision_mask = 1
				grab_ledge = false
			)
		get_tree().create_timer(0.1).timeout.connect(func():
			ledge_check = false
		)
	
	if Input.is_action_just_released("down"):
		slide_slam_stop = false
	# floor conditions, coyote, gravity, and slam
	if not is_on_floor(): #TODO: add slam particles
		if Input.is_action_pressed("down") and not slide_slam_stop:
			can_slam = true
			velocity += (get_gravity() * GRAVITY_MULT * SLAM_GRAV_MULT) * delta
		else:
			if is_on_wall():
				velocity += (get_gravity() * GRAVITY_MULT / 3) * delta
			else:
				velocity += get_gravity() * GRAVITY_MULT * delta
		if jumps == 0:
			if not coyote_time_started:
				coyote_time_started = true
				coyote_time_valid = true
				get_tree().create_timer(COYOTE_TIME).timeout.connect(func():
					if jumps == 0:
						jumps = 1
						# print("cy time")
					coyote_time_valid = false
					)
			#elif not coyote_time_valid:
				#jumps = 1
	else:
		if Input.is_action_pressed("down") and can_slam:
			print("SLAM (placeholder)") #TODO
		can_slam = false
			
		coyote_time_started = false
		coyote_time_valid = false
		jumps = 0
		dashes = 0
			
	
	# jumps
	if not grab_ledge:
		if is_on_wall():
			if get_jump_condition(true): #TODO: change momentumn to direction of wall jump
				#print(grab_ledge)
				if get_wall_normal().normalized().x == -1: # left
					velocity.x = -WALL_JUMP_X_VEL
				else:
					velocity.x = WALL_JUMP_X_VEL
				last_wall_jump_dir = get_wall_normal().normalized().x
				get_tree().create_timer(0.25).timeout.connect(func():
					last_wall_jump_dir = 0
				)
				curr_accel = 0.65
				process_jump_y(false)
		else:
			if get_jump_condition(false):
				process_jump_y(true)
	
	# actual horizontal movement (and dashing)
	direction = Input.get_axis("left", "right")
	if direction:
		current_speed = lerpf(BASE_SPEED, MAX_SPEED, curr_accel)
		velocity.x = lerp(velocity.x, direction * current_speed, LERP_SPEED)
		if last_wall_jump_dir != 0:
			if direction == last_wall_jump_dir:
				curr_accel = 0.75
			else:
				curr_accel = 0
		else:
			if last_dir == direction and not is_on_wall() and curr_accel < 1.0:
				curr_accel = minf(curr_accel + (ACCELERATION * delta), 1.0)
			else:
				last_dir = direction
				curr_accel = 0.2
			
		if is_on_floor() and Input.is_action_pressed("down") and not slide_cd:
			slide_cd = true
			slide_slam_stop = true
			has_dash_mom = true
			velocity.x = direction * SLIDE_VEL
			velocity.y = 1000
			$CollisionShape2D.shape.radius = 24.0
			$CollisionShape2D.shape.height = 48.0
			get_tree().create_timer(0.4).timeout.connect(func():
				$CollisionShape2D.shape.radius = 48.0
				$CollisionShape2D.shape.height = 128.0
			)
			get_tree().create_timer(0.35).timeout.connect(func():
				has_dash_mom = false
			)
			get_tree().create_timer(Slide_TIME).timeout.connect(func():
				slide_cd = false
			)
	else:
		velocity.x = lerp(velocity.x, move_toward(velocity.x, 0, current_speed), LERP_SPEED)
		curr_accel = 0
		
	if Input.is_action_just_pressed("dash") and dashes < MAX_DASHES and not dash_cd:
		dash_cd = true
		velocity.x = last_dir * DASH_VEL
		has_dash_mom = true
		get_tree().create_timer(0.35).timeout.connect(func():
			has_dash_mom = false
		)
		get_tree().create_timer(DASH_TIME).timeout.connect(func():
			dash_cd = false
		)
	
	grab_ledge = false
		
	move_and_slide()
	

extends CharacterBody2D


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
const DASH_VEL: float  = 3000
var dash_cd = false
const DASH_TIME: float  = 0.75


var direction: float = 0
var last_dir: float = 0
var jmp_debounce = false

const WALL_JUMP_X_VEL = 2400

var coyote_time_valid = false
var coyote_time_started = false
const COYOTE_TIME = 0.22

const SLAM_GRAV_MULT: float = 4.0
var can_slam = false

var grab_ledge = false
var ledge_check = false

func debug_point(pos: Vector2, color: Color = Color(1.0, 1.0, 1.0, 1.0)):
	var node = $Sprite2D.duplicate()
	node.scale = Vector2(0.2, 0.2)
	node.modulate = color
	$'..'.add_child(node)
	node.global_position = pos

func process_jump_y(j_add: bool):
	if j_add: jumps += 1
	
	# TODO: make second jump more powerful, but make sure it actually works at negative velocity
	
	velocity.y = min(BASE_JUMP, velocity.y + BASE_JUMP)

			
	get_tree().create_timer(0.1).timeout.connect(func():
		jmp_debounce = false
		)
	
# one of the one liners of all time
func get_jump_condition(wall: bool):
	return not jmp_debounce and ((Input.is_action_just_pressed("jump") and ((wall and jumps <= MAX_JUMPS) or jumps < MAX_JUMPS)) or (Input.is_action_pressed("jump") and jumps == 0))

func _physics_process(delta: float) -> void:
	
	
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
		var down_query = PhysicsRayQueryParameters2D.create(offset_pos + Vector2(0, -255), offset_pos + Vector2(0, 32))
		var down_result = space_state.intersect_ray(down_query)
		
		# get_tree().create_timer(randf(0.005, 0.06)).timeout.connect(func():)
		#debug_point(origin, Color(0.0, 0.651, 0.604, 1.0))
		#debug_point(offset_pos, Color(0.0, 0.651, 0.604, 1.0))
		#debug_point(offset_pos + Vector2(0, -255), Color(1.0, 0.208, 0.604, 1.0))
		#debug_point(offset_pos + Vector2(0, 32), Color(1.0, 0.208, 0.604, 1.0))
		
		if horiz_result and down_result and horiz_result.collider == down_result.collider and not grab_ledge:
			grab_ledge = true
			var target_pos = down_result.position - Vector2(0, 64)
			#debug_point(target_pos )
			#debug_point(horiz_result.position, Color(0.722, 0.526, 0.0, 1.0))

			var tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
			tween.tween_property(self, "global_position", target_pos, 0.15)
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

	# floor conditions, coyote, gravity, and slam
	if not is_on_floor(): #TODO: add slam particles
		if Input.is_action_pressed("down"):
			can_slam = true
			velocity += (get_gravity() * SLAM_GRAV_MULT) * delta
		else:
			if is_on_wall():
				velocity += (get_gravity() / 2) * delta
			else:
				velocity += get_gravity() * delta
		if jumps == 0:
			if not coyote_time_started:
				coyote_time_started = true
				coyote_time_valid = true
				get_tree().create_timer(COYOTE_TIME).timeout.connect(func():
					if jumps == 0:
						jumps = 1
						print("cy time")
					coyote_time_valid = false
					)
			#elif not coyote_time_valid:
				#jumps = 1
	else:
		if Input.is_action_pressed("down") and can_slam:
			print("SLAM (placeholder)")
		can_slam = false
			
		coyote_time_started = false
		coyote_time_valid = false
		jumps = 0
		dashes = 0
			
	
	# jumps
	if not grab_ledge:
		if is_on_wall():
			if get_jump_condition(true): #TODO: change momentumn to direction of wall jump
				print(grab_ledge)
				if get_wall_normal().normalized().x == -1: # left
					velocity.x = -WALL_JUMP_X_VEL
				else:
					velocity.x = WALL_JUMP_X_VEL
				curr_accel = 0
				process_jump_y(false)
		else:
			if get_jump_condition(false):
				process_jump_y(true)
	
	# actual horizontal movement (and dashing)
	direction = Input.get_axis("left", "right")
	if direction:
		current_speed = lerpf(BASE_SPEED, MAX_SPEED, curr_accel)
		velocity.x = lerp(velocity.x, direction * current_speed, LERP_SPEED)
		if last_dir == direction and not is_on_wall() and curr_accel < 1.0:
			curr_accel = minf(curr_accel + (ACCELERATION * delta), 1.0)
		else:
			last_dir = direction
			curr_accel = 0.2
	else:
		velocity.x = lerp(velocity.x, move_toward(velocity.x, 0, current_speed), LERP_SPEED)
		curr_accel = 0
		
	if Input.is_action_just_pressed("dash") and dashes < MAX_DASHES and not dash_cd:
		dash_cd = true
		velocity.x = last_dir * DASH_VEL
		get_tree().create_timer(DASH_TIME).timeout.connect(func():
			dash_cd = false
		)
	
	grab_ledge = false
		
	move_and_slide()
	

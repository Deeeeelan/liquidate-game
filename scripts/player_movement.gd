extends CharacterBody2D


const BASE_SPEED: float = 800.0
const MAX_SPEED: float = 1300.0
var current_speed: float = 0.0
var curr_accel: float = 0.0

const BASE_JUMP: float = -600.0
const LERP_SPEED: float = 0.08
var jumps: int = 0
const MAX_JUMPS: int = 2

var direction: float = 0
var last_dir: float = 0
var jmp_debounce = false

const WALL_JUMP_X_VEL = 2400

func process_jump_y(j_add: bool):
	if j_add: jumps += 1
	velocity.y = BASE_JUMP

			
	get_tree().create_timer(0.1).timeout.connect(func():
		jmp_debounce = false
		)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		if Input.is_action_pressed("down"):
			print("DOWN")
			velocity += (get_gravity() * 3) * delta
		else:
			if is_on_wall():
				velocity += (get_gravity() / 2) * delta
			else:
				velocity += get_gravity() * delta
		if jumps == 0:
			jumps = 1
	else:
		jumps = 0
	
	if is_on_wall():
		if Input.is_action_just_pressed("jump") and jumps <= MAX_JUMPS and not jmp_debounce:
			print("WALL")
			if get_wall_normal().normalized().x == -1: # left
				velocity.x = -WALL_JUMP_X_VEL
			else:
				velocity.x = WALL_JUMP_X_VEL
			curr_accel = 0
			process_jump_y(false)
	else:
		if Input.is_action_just_pressed("jump") and jumps < MAX_JUMPS and not jmp_debounce:
			process_jump_y(true)

	
	direction = Input.get_axis("left", "right")
	if direction:
		current_speed = lerpf(BASE_SPEED, MAX_SPEED, curr_accel)
		velocity.x = lerp(velocity.x, direction * current_speed, LERP_SPEED)
		if last_dir == direction and not is_on_wall() and curr_accel < 1.0:
			curr_accel = minf(curr_accel + (0.2 * delta), 1.0)
		else:
			last_dir = direction
			curr_accel = 0.2
	else:
		velocity.x = lerp(velocity.x, move_toward(velocity.x, 0, current_speed), LERP_SPEED)
		curr_accel = 0
	print (curr_accel)
	move_and_slide()

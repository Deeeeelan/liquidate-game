extends CharacterBody2D


const BASE_SPEED: float = 600.0
const MAX_SPEED: float = 1000.0
var current_speed: float = 0.0
var curr_accel: float = 0.0

const BASE_JUMP: float = -600.0
const LERP_SPEED: float = 0.08
var jumps: int = 0
const MAX_JUMPS: int = 2

var direction: float = 0
var last_dir: float = 0
var jmp_debounce = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if jumps == 0:
			jumps = 1
	else:
		jumps = 0

	# Handle jump.
	if Input.is_action_just_pressed("jump") and jumps < MAX_JUMPS and not jmp_debounce:
		jumps += 1
		print(jumps)
		velocity.y = BASE_JUMP
		get_tree().create_timer(0.1).timeout.connect(func():
			jmp_debounce = false
			)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Input.get_axis("left", "right")
	if direction:
		current_speed = lerpf(BASE_SPEED, MAX_SPEED, curr_accel)
		velocity.x = lerp(velocity.x, direction * current_speed, LERP_SPEED)
		if last_dir == direction:
			curr_accel += 0.05 # TODO: DELTATIME
		else:
			last_dir = direction
			curr_accel = 0.4
	else:
		velocity.x = lerp(velocity.x, move_toward(velocity.x, 0, current_speed), LERP_SPEED)
		curr_accel = 0

	move_and_slide()

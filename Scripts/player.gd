extends CharacterBody3D

# PLAYER HEALTH
var hp := 100

func apply_damage(amount: float):
	hp -= amount
	print("[Player] Damage:", amount, " | HP Left:", hp)

	if hp <= 0 and current_state != State.DEAD:
		died()


enum State { IDLE, WALK, ATTACK, INTERACT, DEAD }
var current_state: State = State.IDLE

@export var speed = 100
const SPRINT_SPEED = 8.0
const JUMP_VELOCITY = 4.8

var gravity = 9.8

@onready var anim: AnimationPlayer = $AnimationPlayer

func _physics_process(delta):
	match current_state:
		State.DEAD:
			_process_dead(delta)
		State.ATTACK:
			_process_attack(delta)
		State.INTERACT:
			_process_interact(delta)
		State.IDLE, State.WALK:
			_process_movement(delta)


func _process_movement(delta):
	_apply_gravity(delta)
	_handle_jump()

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var move_dir = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if is_on_floor():
		if move_dir != Vector3.ZERO:
			velocity.x = move_dir.x * speed
			velocity.z = move_dir.z * speed

			rotation.y = lerp_angle(rotation.y, atan2(move_dir.x, move_dir.z), delta * 10)
			_set_state(State.WALK)
		else:
			velocity.x = lerp(velocity.x, 0.0, delta * 7)
			velocity.z = lerp(velocity.z, 0.0, delta * 7)
			_set_state(State.IDLE)
	else:
		velocity.x = lerp(velocity.x, move_dir.x * speed, delta * 3)
		velocity.z = lerp(velocity.z, move_dir.z * speed, delta * 3)

	move_and_slide()

func _apply_gravity(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

func _handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _play(anim_name: String):
	if anim.current_animation != anim_name:
		anim.play(anim_name)


func attack():
	if current_state == State.DEAD:
		return
	_set_state(State.ATTACK)

func _process_attack(_delta):
	velocity.x = 0
	velocity.z = 0
	move_and_slide()

	_play("attack")
	await anim.animation_finished
	_set_state(State.IDLE)


func interact():
	if current_state == State.DEAD:
		return
	_set_state(State.INTERACT)

func _process_interact(_delta):
	velocity.x = 0
	velocity.z = 0
	move_and_slide()

	_play("interact")
	await anim.animation_finished
	_set_state(State.IDLE)


func died():
	_set_state(State.DEAD)
	velocity = Vector3.ZERO
	print("[Player] Died")

func _process_dead(_delta):
	velocity.x = 0
	velocity.z = 0
	move_and_slide()
	_play("dead")

func _set_state(new_state: State):
	if current_state == new_state:
		return

	current_state = new_state

	match new_state:
		State.IDLE:
			_play("Idle")
		State.WALK:
			_play("Walk")
		State.ATTACK:
			_play("Punch_jab")
		State.INTERACT:
			_play("Interact")
		State.DEAD:
			_play("dead")

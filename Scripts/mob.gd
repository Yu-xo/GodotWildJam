extends CharacterBody3D

@onready var anim = $AnimationPlayer
@onready var agent = $NavigationAgent3D

var target

# HEALTH
var hp := 50   # enemy base HP

func apply_damage(amount: float):
	hp -= amount
	print("[Enemy:", name, "] Damage:", amount, " | HP Left:", hp)

	if hp <= 0:
		_die()

func _die():
	print("[Enemy:", name, "] Died.")
	queue_free()

# --------------------------
# ORIGINAL NAVIGATION LOGIC
# --------------------------
const UPDATE_TIME = 0.2
const SPEED = 5.0
const SMOOTHING_FACTOR = 0.2

var update_timer := 0.0

func _ready():
	target = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	move_to_agent(delta)

func set_target(pos):
	agent.set_target_position(pos)

func move_to_agent(delta: float, speed: float = SPEED):
	update_timer -= delta
	if update_timer <= 0.0:
		update_timer = UPDATE_TIME
		if target:
			set_target(target.global_position)

	if not is_on_floor():
		velocity += get_gravity() * delta
		move_and_slide()
		return

	if agent.is_navigation_finished():
		return

	var next_pos = agent.get_next_path_position()
	var dir = next_pos - global_position
	dir.y = 0
	dir = dir.normalized()

	var current_facing = -global_transform.basis.z
	var new_dir = current_facing.slerp(dir, SMOOTHING_FACTOR).normalized()
	look_at(global_position + new_dir, Vector3.UP)

	velocity = velocity.lerp(dir * speed, SMOOTHING_FACTOR)
	move_and_slide()

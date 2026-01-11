extends Node3D

@export var speed := 20.0
@export var hit_radius := 0.5  # Small radial hit area

var target: Node3D = null
var damage_per_second := 2.0
var duration := 3.0

var stuck := false
var timer := 0.0

func _ready():
	timer = duration

func _physics_process(delta):
	if stuck:
		timer -= delta

		# Apply DOT
		if target and target.has_variable("hp"):
			target.hp -= damage_per_second * delta
			if target.hp <= 0:
				target.queue_free()

		if timer <= 0:
			queue_free()
		return

	# ----------- PROJECTILE MOVEMENT -----------
	var move_vec = -transform.basis.z * speed * delta
	global_translate(move_vec)

	# ----------- HIT DETECTION (RADIUS-BASED) -----------
	_check_hit()

func _check_hit():
	if target == null:
		return

	var dist = global_position.distance_to(target.global_position)

	if dist <= hit_radius:
		_on_hit(target)

func _on_hit(body):
	if body == null:
		queue_free()
		return

	stuck = true
	target = body

	# Attach projectile to target so it follows it
	if target.is_inside_tree():
		get_parent().remove_child(self)
		target.add_child(self)
		global_position = target.global_position

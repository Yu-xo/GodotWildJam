extends Node3D

@onready var pivot: Marker3D = $Marker3D
@onready var beam_container := $BeamContainer
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

# ---------------------------------------------------
# CONNECTION MODES
# ---------------------------------------------------
enum ConnectionMode {
	MODE_ALL_NEARBY,
	MODE_CLOSEST,
	MODE_CHAIN
}

# ---------------------------------------------------
# EXPORTED VARIABLES
# ---------------------------------------------------
@export var connection_mode: ConnectionMode = ConnectionMode.MODE_ALL_NEARBY
@export var max_connections := 0        # 0 = unlimited
@export var link_range := 30.0
@export var beam_radius := 0.1
@export var beam_color := Color(0.3, 0.7, 1.0, 1.0)
@export var enable_beams := true

# Independent cooldown system
@export var beam_active_time := 1.0       # Seconds beams stay active
@export var beam_cooldown_time := 2.0     # Seconds beams stay off
@export var start_charged := true         # Start active or start cooling down

# ---------------------------------------------------
# STATE
# ---------------------------------------------------
var is_beam_active := false
var beam_timer := 0.0


# ---------------------------------------------------
# READY / EXIT
# ---------------------------------------------------
func _ready():
	print("[Pillar] Ready:", name)
	PillarManager.register_electric(self)

	# Initialize charge / cooldown state
	if start_charged:
		_activate_beams()
		beam_timer = beam_active_time
	else:
		_deactivate_beams()
		beam_timer = beam_cooldown_time


func _exit_tree():
	print("[Pillar] Exiting:", name)
	PillarManager.unregister_electric(self)


# ---------------------------------------------------
# PROCESS — Handle cooldown cycle
# ---------------------------------------------------
func _process(delta):
	beam_timer -= delta

	if is_beam_active:
		if beam_timer <= 0.0:
			_deactivate_beams()
			beam_timer = beam_cooldown_time
	else:
		if beam_timer <= 0.0:
			_activate_beams()
			beam_timer = beam_active_time


# ---------------------------------------------------
# ACTIVATE / DEACTIVATE BEAMS
# ---------------------------------------------------
func _activate_beams():
	is_beam_active = true
	_update_visual_charge(true)

	# Regenerate links normally through PillarManager
	if PillarManager:
		update_links(PillarManager.electric_pillars)



func _deactivate_beams():
	is_beam_active = false
	_update_visual_charge(false)

	# Remove existing beams immediately
	for c in beam_container.get_children():
		c.queue_free()


# ---------------------------------------------------
# OPTIONAL VISUAL CHARGE FEEDBACK
# ---------------------------------------------------
func _update_visual_charge(active: bool):
	if not mesh_instance_3d:
		return

	var mat := mesh_instance_3d.get_active_material(0)
	if not mat:
		return

	if active:
		mat.emission_energy = 2.0
	else:
		mat.emission_energy = 0.2


# ---------------------------------------------------
# MAIN UPDATE ENTRY POINT (now respects cooldown)
# ---------------------------------------------------
func update_links(all_pillars: Array):
	if not is_beam_active:
		return  # Do NOT generate beams during cooldown

	print("\n[Pillar:", name, "] Updating links with mode =", connection_mode)

	# Clear old beams (fresh cycle)
	for c in beam_container.get_children():
		c.queue_free()

	if not enable_beams:
		print("[Pillar:", name, "] Beams disabled. Skipping.")
		return

	# Collect nearby pillars
	var neighbors := []
	for p in all_pillars:
		if p != self:
			var d = global_position.distance_to(p.global_position)
			if d <= link_range:
				neighbors.append(p)

	print("[Pillar:", name, "] Nearby pillars:", neighbors.size())

	match connection_mode:
		ConnectionMode.MODE_ALL_NEARBY:
			_update_all_nearby(neighbors)

		ConnectionMode.MODE_CLOSEST:
			_update_closest(neighbors)

		ConnectionMode.MODE_CHAIN:
			_update_chain(all_pillars)


# ---------------------------------------------------
# MODE 1 — CONNECT TO ALL NEARBY
# ---------------------------------------------------
func _update_all_nearby(neighbors: Array):
	print("[Pillar:", name, "] MODE_ALL_NEARBY active")

	neighbors.sort_custom(func(a, b):
		return pivot.global_position.distance_to(a.pivot.global_position) < pivot.global_position.distance_to(b.pivot.global_position)
	)

	if max_connections > 0:
		neighbors = neighbors.slice(0, max_connections)

	print("[Pillar:", name, "] Connecting to:", neighbors.size())

	for other in neighbors:
		_create_beam_to(other)


# ---------------------------------------------------
# MODE 2 — CONNECT TO CLOSEST ONLY
# ---------------------------------------------------
func _update_closest(neighbors: Array):
	print("[Pillar:", name, "] MODE_CLOSEST active")

	if neighbors.is_empty():
		print("[Pillar:", name, "] No neighbors.")
		return

	neighbors.sort_custom(func(a, b):
		return pivot.global_position.distance_to(a.pivot.global_position) < pivot.global_position.distance_to(b.pivot.global_position)
	)

	var count = max_connections if max_connections > 0 else 1
	var limited = neighbors.slice(0, count)

	for other in limited:
		_create_beam_to(other)


# ---------------------------------------------------
# MODE 3 — CHAIN MODE
# ---------------------------------------------------
func _update_chain(all_pillars: Array):
	print("[Pillar:", name, "] MODE_CHAIN active")

	var sorted := all_pillars.filter(func(p):
		return p != self
	)

	sorted.sort_custom(func(a, b):
		return pivot.global_position.distance_to(a.pivot.global_position) < pivot.global_position.distance_to(b.pivot.global_position)
	)

	if sorted.is_empty():
		print("[Pillar:", name, "] No chain partners.")
		return

	var count = max_connections if max_connections > 0 else 1
	var limited = sorted.slice(0, count)

	for other in limited:
		_create_beam_to(other)


# ---------------------------------------------------
# BEAM CREATION
# ---------------------------------------------------
func _create_beam_to(other: Node3D):
	print("[Pillar:", name, "] Creating beam to:", other.name)

	var start_pos = pivot.global_position
	var end_pos = other.pivot.global_position
	var dir = end_pos - start_pos
	var length = dir.length()

	# Beam Area3D
	var beam := Area3D.new()
	beam_container.add_child(beam)
	beam.body_entered.connect(_on_beam_body_entered)

	# Collision
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.height = length
	shape.radius = beam_radius
	collision.shape = shape
	beam.add_child(collision)

	# Mesh
	var mesh_instance := MeshInstance3D.new()
	beam.add_child(mesh_instance)

	var mesh := CylinderMesh.new()
	mesh.height = length
	mesh.top_radius = beam_radius
	mesh.bottom_radius = beam_radius
	mesh.radial_segments = 32
	mesh_instance.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	mat.emission_energy = 2.0
	mat.emission = beam_color
	mat.albedo_color = beam_color
	mat.unshaded = true
	mesh_instance.material_override = mat

	# Position + Orientation
	var midpoint = (start_pos + end_pos) * 0.5
	var t := Transform3D()
	t.origin = midpoint

	var y_axis = dir.normalized()
	var x_axis = y_axis.cross(Vector3.UP).normalized()
	if x_axis.length() < 0.01:
		x_axis = y_axis.cross(Vector3.FORWARD).normalized()
	var z_axis = x_axis.cross(y_axis).normalized()

	t.basis = Basis(x_axis, y_axis, z_axis)
	beam.global_transform = t

	print("[BEAM DEBUG] Beam created. Length:", length)


# ---------------------------------------------------
# PLAYER / ENEMY COLLISION HANDLING
# ---------------------------------------------------
func _on_beam_body_entered(body):
	if body.is_in_group("enemy"):
		body.queue_free()

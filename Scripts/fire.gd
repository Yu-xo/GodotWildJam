extends Node3D

@onready var pivot: Marker3D = $pivot
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D
@onready var projectile_spawn: Marker3D = $projectile_spawn


@export var projectile_scene: PackedScene


@export var fire_interval := 3.0


@export var projectile_damage_per_second := 2.0
@export var projectile_duration := 3.0


@export var emission_active := 2.0
@export var emission_inactive := 0.2


var shoot_timer := 0.0
var active := true   # Fire pillar is always active unless you want cooldown cycles

func _ready():
	print("[FirePillar] Ready:", name)
	

	shoot_timer = fire_interval

func _exit_tree():
	PillarManager.unregister_electric(self)

func _process(delta):
	if not active:
		return

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = fire_interval
		_shoot_projectile_at_closest_enemy()


func _shoot_projectile_at_closest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return

	var closest = null
	var closest_dist = INF
	var pos = global_position

	for e in enemies:
		if not e or not e.is_inside_tree():
			continue
		var d = pos.distance_to(e.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = e

	if closest == null:
		return

	_spawn_projectile(closest)

func _spawn_projectile(target):
	if projectile_scene == null:
		print("[FirePillar] ERROR: projectile_scene not assigned")
		return

	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = projectile_spawn.global_position
	projectile.look_at(target.global_position)

	projectile.target = target
	projectile.damage_per_second = projectile_damage_per_second
	projectile.duration = projectile_duration


func _set_glow(on: bool):
	var mat := mesh_instance_3d.get_active_material(0)
	if mat:
		mat.emission_energy = emission_active if on else emission_inactive

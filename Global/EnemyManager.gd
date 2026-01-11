extends Node
class_name Enemy_Manager

# Exported enemy scenes (Inspector)
@onready var melee_enemy_scene =  preload("res://Scenes/Enemies/Mobs/mobs.tscn")
@export var ranged_enemy_scene: PackedScene
@export var tank_enemy_scene: PackedScene
@export var elite_enemy_scene: PackedScene

@export var drop_scene: PackedScene

var enemies: Array[Node3D] = []

var enemy_scenes := {}

func _ready():
	enemy_scenes = {
		"melee": melee_enemy_scene,
		"ranged": ranged_enemy_scene,
		"tank": tank_enemy_scene,
		"elite": elite_enemy_scene
	}

func register_enemy(enemy: Node3D):
	enemies.append(enemy)
	print("[EnemyManager] Registered:", enemy.name)

func unregister_enemy(enemy: Node3D):
	enemies.erase(enemy)
	print("[EnemyManager] Unregistered:", enemy.name)

func spawn_enemy(enemy_type: String, position: Vector3):
	if not enemy_scenes.has(enemy_type):
		push_error("Invalid enemy type: " + enemy_type)
		return null
	
	var scene: PackedScene = enemy_scenes[enemy_type]
	if scene == null:
		push_error("Scene for type is not assigned: " + enemy_type)
		return null

	var enemy = scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = position

	print("[EnemyManager] Spawned:", enemy_type, "at", position)
	return enemy

func drop_material(position: Vector3):
	if drop_scene == null:
		push_error("Drop scene not assigned.")
		return

	var drop = drop_scene.instantiate()
	get_tree().current_scene.add_child(drop)
	drop.global_position = position

	print("[EnemyManager] Dropped material at:", position)

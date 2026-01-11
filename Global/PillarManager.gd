extends Node

var electric_pillars: Array[Node3D] = []

func register_electric(pillar: Node3D) -> void:
	print("[PillarManager] Register Pillar:", pillar.name)
	electric_pillars.append(pillar)
	_update_links()

func unregister_electric(pillar: Node3D) -> void:
	print("[PillarManager] Unregister Pillar:", pillar.name)
	electric_pillars.erase(pillar)
	_update_links()

func _update_links():
	print("[PillarManager] Updating links for all pillars. Count =", electric_pillars.size())
	for p in electric_pillars:
		p.update_links(electric_pillars)

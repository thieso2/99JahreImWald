extends Node

# Speichersystem – sichert den Spielstand automatisch als JSON
# Datei: user://savegame.json (auf iPad im App-Sandbox-Ordner)
# Autosave alle 10 Sekunden + beim Beenden des Spiels

const SAVE_PATH: String = "user://savegame.json"
const AUTOSAVE_INTERVAL: float = 10.0

var game_manager: Node = null
var player: CharacterBody3D = null
var day_night: Node = null

var autosave_timer: float = AUTOSAVE_INTERVAL


func _process(delta: float) -> void:
	if not game_manager or not player:
		return
	autosave_timer -= delta
	if autosave_timer <= 0:
		autosave_timer = AUTOSAVE_INTERVAL
		save_game()


func read_save() -> Dictionary:
	# Liest die Speicherdatei (leeres Dictionary wenn keine existiert)
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}


func save_game() -> void:
	if not game_manager or not player or not day_night:
		return

	var data: Dictionary = {
		"player": {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
			"rot_y": player.rotation.y,
			"hp": player.hp,
			"inventory": player.inventory,
			"wood_count": player.wood_count,
			"sapling_count": player.sapling_count,
			"has_torch": player.has_torch,
			"has_axe": player.has_axe,
			"axe_tier": player.axe_tier,
		},
		"world": {
			"day": day_night.current_day,
			"time": day_night.current_time,
			"is_night": day_night.is_night,
			"total_nights": game_manager.total_nights,
			"children_rescued": game_manager.children_rescued,
			"rescued_spots": game_manager.rescued_spots,
		},
		"placeables": _collect_placeables(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func _collect_placeables() -> Array:
	var result: Array = []
	for node in get_tree().get_nodes_in_group("placeable"):
		result.append({
			"type": node.item_type,
			"x": node.global_position.x,
			"y": node.global_position.y,
			"z": node.global_position.z,
			"rot_y": node.rotation.y,
		})
	return result


func apply_save(data: Dictionary) -> void:
	# Stellt Spieler, Welt und platzierte Gegenstände wieder her
	# (Kinder werden vom GameManager beim Spawnen berücksichtigt)
	if data.is_empty():
		return

	var p: Dictionary = data.get("player", {})
	if not p.is_empty():
		player.global_position = Vector3(p.get("x", 0.0), p.get("y", 1.0), p.get("z", 5.0))
		player.rotation.y = p.get("rot_y", 0.0)
		player.hp = p.get("hp", player.max_hp)
		player.hp_changed.emit(player.hp)
		player.inventory = p.get("inventory", [])
		player.wood_count = int(p.get("wood_count", 0))
		player.sapling_count = int(p.get("sapling_count", 0))
		player.has_torch = p.get("has_torch", false)
		player.wood_changed.emit(player.wood_count)
		player.sapling_changed.emit(player.sapling_count)
		player.inventory_changed.emit()
		if p.get("has_axe", false):
			player.give_axe(int(p.get("axe_tier", 0)))

	var w: Dictionary = data.get("world", {})
	if not w.is_empty():
		day_night.current_day = int(w.get("day", 1))
		day_night.current_time = w.get("time", 0.0)
		day_night.is_night = w.get("is_night", false)

	for entry in data.get("placeables", []):
		var placeable_script: GDScript = preload("res://scripts/placeable_item.gd")
		var item := StaticBody3D.new()
		item.set_script(placeable_script)
		item.item_type = entry.get("type", "fence")
		item.position = Vector3(entry.get("x", 0.0), entry.get("y", 0.0), entry.get("z", 0.0))
		item.rotation.y = entry.get("rot_y", 0.0)
		get_tree().current_scene.add_child(item)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

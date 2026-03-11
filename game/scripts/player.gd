extends CharacterBody3D

# Spieler-Einstellungen
@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var max_hp: float = 100.0
@export var rotation_speed: float = 15.0  # Schnelle Drehung wie in Roblox

# Zustand
var hp: float = 100.0
var inventory: Array = []  # FIFO-Queue: ["wood", "sapling", "wood", ...]
var wood_count: int = 0
var sapling_count: int = 0
var has_torch: bool = false
var is_near_campfire: bool = false
var is_safe: bool = false

# Axt-System
var has_axe: bool = false
var axe_tier: int = 0         # 0=Stein, 1=Eisen, 2=Stahl
var axe_active: bool = false  # Axt gezückt?
var chop_cooldown: float = 0.0

# Touch-Steuerung
var joystick_direction: Vector2 = Vector2.ZERO

# Kamera-Yaw für richtungsrelative Bewegung
var camera_yaw: float = 0.0

# Modell & Sound
var player_model: Node3D = null
var footsteps: Node = null

# Signale
signal hp_changed(new_hp: float)
signal wood_changed(new_count: int)
signal player_died()
signal entered_safe_zone()
signal left_safe_zone()
signal axe_changed(active: bool)
signal sapling_changed(new_count: int)
signal inventory_changed()


func _ready() -> void:
	hp = max_hp

	# Spieler-Modell erstellen
	var model_script: GDScript = preload("res://scripts/player_model.gd")
	player_model = Node3D.new()
	player_model.set_script(model_script)
	player_model.name = "PlayerModel"
	add_child(player_model)

	# Schrittgeräusche erstellen
	var footstep_script: GDScript = preload("res://scripts/footstep_sounds.gd")
	footsteps = Node.new()
	footsteps.set_script(footstep_script)
	footsteps.name = "FootstepSounds"
	add_child(footsteps)


func _physics_process(delta: float) -> void:
	# Axt-Cooldown
	if chop_cooldown > 0:
		chop_cooldown -= delta

	# Schwerkraft
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Input sammeln (Joystick oder Tastatur)
	var input_dir := Vector2.ZERO
	var shift_held := Input.is_key_pressed(KEY_SHIFT)

	if joystick_direction.length() > 0.1:
		input_dir = joystick_direction

	# WASD: immer Bewegung
	if input_dir.length() < 0.1:
		if Input.is_action_pressed("move_forward"):
			input_dir.y += 1
		if Input.is_action_pressed("move_backward"):
			input_dir.y -= 1
		if Input.is_action_pressed("move_left"):
			input_dir.x -= 1
		if Input.is_action_pressed("move_right"):
			input_dir.x += 1

	# Pfeiltasten Hoch/Runter: Bewegung (nur ohne Ctrl)
	if input_dir.length() < 0.1 and not shift_held:
		if Input.is_key_pressed(KEY_UP):
			input_dir.y += 1
		if Input.is_key_pressed(KEY_DOWN):
			input_dir.y -= 1

	# Bewegung relativ zur Kamera-Blickrichtung
	var direction := Vector3.ZERO
	var walking := false
	if input_dir.length() > 0.1:
		input_dir = input_dir.normalized()
		var yaw_rad: float = deg_to_rad(camera_yaw)

		# "Vorwärts" = Richtung von der Kamera weg zum Spieler
		var forward := Vector3(sin(yaw_rad), 0, -cos(yaw_rad))
		var right := Vector3(cos(yaw_rad), 0, sin(yaw_rad))

		direction = (forward * input_dir.y + right * input_dir.x).normalized()
		walking = true

	# Geschwindigkeit setzen
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	# Charakter dreht sofort in Bewegungsrichtung (Roblox-Style)
	if direction.length() > 0.1:
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, rotation_speed * delta)

	# Animation und Sound
	if player_model:
		player_model.set_walking(walking)
	if footsteps:
		footsteps.set_walking(walking)

	move_and_slide()


func take_damage(amount: float) -> void:
	if is_safe:
		return
	hp -= amount
	hp_changed.emit(hp)
	if hp <= 0:
		die()


func heal(amount: float) -> void:
	hp = min(hp + amount, max_hp)
	hp_changed.emit(hp)


func die() -> void:
	player_died.emit()
	# Respawn am Lagerfeuer
	hp = max_hp
	hp_changed.emit(hp)
	global_position = Vector3(0, 1, 0)


func add_wood(amount: int = 1) -> void:
	for i in range(amount):
		inventory.append("wood")
	wood_count += amount
	wood_changed.emit(wood_count)
	inventory_changed.emit()


func craft_torch() -> bool:
	if wood_count >= 3:
		# 3 Holz aus dem Inventar entfernen (FIFO)
		var removed: int = 0
		var i: int = 0
		while i < inventory.size() and removed < 3:
			if inventory[i] == "wood":
				inventory.remove_at(i)
				removed += 1
			else:
				i += 1
		wood_count -= 3
		has_torch = true
		wood_changed.emit(wood_count)
		inventory_changed.emit()
		return true
	return false


func set_joystick_input(direction: Vector2) -> void:
	joystick_direction = direction


func _on_safe_zone_entered() -> void:
	is_safe = true
	is_near_campfire = true
	entered_safe_zone.emit()


func _on_safe_zone_exited() -> void:
	is_safe = false
	is_near_campfire = false
	left_safe_zone.emit()


func add_sapling(amount: int = 1) -> void:
	for i in range(amount):
		inventory.append("sapling")
	sapling_count += amount
	sapling_changed.emit(sapling_count)
	inventory_changed.emit()


func drop_item() -> String:
	# Ältestes Item aus dem Inventar droppen (FIFO)
	if inventory.size() == 0:
		return ""

	var item_type: String = inventory[0]
	inventory.remove_at(0)

	# Zähler aktualisieren
	match item_type:
		"wood":
			wood_count -= 1
			wood_changed.emit(wood_count)
		"sapling":
			sapling_count -= 1
			sapling_changed.emit(sapling_count)

	inventory_changed.emit()

	# Item vor dem Spieler spawnen
	var dropped_item_script: GDScript = preload("res://scripts/dropped_item.gd")
	var item := Area3D.new()
	item.set_script(dropped_item_script)

	match item_type:
		"wood":
			item.item_type = 0  # LOG
		"sapling":
			item.item_type = 1  # SAPLING

	# Vor dem Spieler ablegen (nicht fliegen, sondern sanft fallen)
	var forward := Vector3(sin(rotation.y), 0, cos(rotation.y))
	item.position = global_position + forward * 1.5 + Vector3(0, 1.0, 0)
	item.collision_layer = 0
	item.collision_mask = 1

	var tree_root: Node = get_tree().current_scene
	if tree_root:
		tree_root.add_child(item)

	return item_type


func plant_sapling() -> bool:
	if sapling_count <= 0:
		return false

	var sapling_script: GDScript = preload("res://scripts/sapling.gd")
	var sapling := StaticBody3D.new()
	sapling.set_script(sapling_script)

	# Setzling 2m vor dem Spieler pflanzen
	var forward := Vector3(sin(rotation.y), 0, cos(rotation.y))
	var plant_pos: Vector3 = global_position + forward * 2.0
	plant_pos.y = 0.0
	sapling.position = plant_pos

	var tree_root: Node = get_tree().current_scene
	if tree_root:
		tree_root.add_child(sapling)
		# Setzling aus Inventar entfernen
		var idx: int = inventory.find("sapling")
		if idx >= 0:
			inventory.remove_at(idx)
		sapling_count -= 1
		sapling_changed.emit(sapling_count)
		inventory_changed.emit()
		return true
	return false


func give_axe(tier: int) -> void:
	has_axe = true
	axe_tier = tier
	if axe_active and player_model:
		player_model.equip_axe(tier)


func toggle_axe() -> void:
	if not has_axe:
		return
	axe_active = not axe_active
	if player_model:
		if axe_active:
			player_model.equip_axe(axe_tier)
		else:
			player_model.unequip_axe()
	axe_changed.emit(axe_active)


func get_axe_strength() -> float:
	match axe_tier:
		0: return 1.0
		1: return 2.5
		2: return 5.0
	return 1.0


func get_chop_cooldown_time() -> float:
	match axe_tier:
		0: return 1.0
		1: return 0.7
		2: return 0.45
	return 1.0


func try_chop_tree() -> Dictionary:
	# Gibt {"chopped": bool, "felled": bool, "wood": int, "tree": Node} zurück
	var result := {"chopped": false, "felled": false, "wood": 0, "tree": null}

	if not axe_active or chop_cooldown > 0:
		return result

	# Nächsten Baum in Reichweite finden
	var trees: Array = get_tree().get_nodes_in_group("tree")
	var nearest_tree: Node = null
	var nearest_dist: float = 999.0

	for tree in trees:
		if tree.has_method("chop") and not tree.is_harvested:
			var dist: float = global_position.distance_to(tree.global_position)
			if dist < 4.0 and dist < nearest_dist:
				nearest_dist = dist
				nearest_tree = tree

	if nearest_tree == null:
		return result

	# Hacken!
	chop_cooldown = get_chop_cooldown_time()

	# Animation abspielen
	if player_model:
		player_model.play_chop()

	# Spieler zum Baum drehen
	var dir_to_tree: Vector3 = nearest_tree.global_position - global_position
	dir_to_tree.y = 0
	if dir_to_tree.length() > 0.1:
		var target_rot: float = atan2(dir_to_tree.x, dir_to_tree.z)
		rotation.y = target_rot

	var felled: bool = nearest_tree.chop(get_axe_strength())
	result.chopped = true
	result.tree = nearest_tree

	if felled:
		result.felled = true
		result.wood = nearest_tree.wood_amount
		# Holz kommt jetzt durch aufsammelbare Drops, nicht direkt

	return result

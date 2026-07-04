extends CharacterBody3D

# Hirsch-Monster Einstellungen
@export var speed: float = 4.0
@export var chase_speed: float = 7.0
@export var damage: float = 20.0
@export var attack_range: float = 2.5
@export var detection_range: float = 25.0
@export var attack_cooldown: float = 1.5
@export var spawn_distance: float = 40.0

# Zustand
enum State { INACTIVE, ROAMING, CHASING, ATTACKING, FLEEING }
var current_state: State = State.INACTIVE
var target_player: CharacterBody3D = null
var attack_timer: float = 0.0
var roam_target: Vector3 = Vector3.ZERO
var roam_timer: float = 0.0
var flee_timer: float = 0.0

# Referenzen
var campfire_position: Vector3 = Vector3.ZERO
var campfire_safe_radius: float = 8.0

# Variante: hungriger Hirsch (rote Augen) oder normaler Hirsch (weiße Augen)
var hungry: bool = false

# Modell
var deer_model: Node3D = null


func _ready() -> void:
	# Alte Meshes entfernen (aus tscn)
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()

	# Prozedurales Modell erstellen
	_rebuild_model()

	# Starte inaktiv (wird nachts aktiviert)
	visible = false
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# Schwerkraft
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	match current_state:
		State.ROAMING:
			_process_roaming(delta)
		State.CHASING:
			_process_chasing(delta)
		State.ATTACKING:
			_process_attacking(delta)
		State.FLEEING:
			_process_fleeing(delta)

	# Modell-Animation: bewegt sich wenn Geschwindigkeit > 0
	if deer_model:
		var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.5
		deer_model.set_moving(moving)

	move_and_slide()


func _process_roaming(delta: float) -> void:
	roam_timer -= delta
	if roam_timer <= 0:
		_pick_roam_target()
		roam_timer = randf_range(3.0, 6.0)

	# Zum Roam-Ziel bewegen
	var direction := (roam_target - global_position)
	direction.y = 0
	if direction.length() > 1.0:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		_face_direction(direction, delta)
	else:
		velocity.x = 0
		velocity.z = 0

	# Spieler suchen
	_check_for_player()


func _process_chasing(delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.ROAMING
		return

	# Prüfe ob Spieler Fackel hat – dann fliehen!
	if target_player.has_method("toggle_torch") and target_player.torch_active:
		current_state = State.FLEEING
		flee_timer = 4.0
		return

	# Prüfe ob Spieler in sicherer Zone ist
	var dist_to_campfire: float = target_player.global_position.distance_to(campfire_position)
	if dist_to_campfire < campfire_safe_radius:
		current_state = State.FLEEING
		flee_timer = 3.0
		return

	var direction: Vector3 = target_player.global_position - global_position
	direction.y = 0
	var distance: float = direction.length()

	if distance < attack_range:
		current_state = State.ATTACKING
		attack_timer = 0.0
		velocity.x = 0
		velocity.z = 0
	elif distance > detection_range * 1.5:
		# Spieler zu weit weg, aufgeben
		target_player = null
		current_state = State.ROAMING
	else:
		direction = direction.normalized()
		velocity.x = direction.x * chase_speed
		velocity.z = direction.z * chase_speed
		_face_direction(direction, delta)


func _process_attacking(delta: float) -> void:
	attack_timer -= delta
	if attack_timer <= 0:
		if is_instance_valid(target_player):
			var distance: float = global_position.distance_to(target_player.global_position)
			if distance < attack_range:
				# Schaden zufügen
				target_player.take_damage(damage)
				attack_timer = attack_cooldown
			else:
				current_state = State.CHASING
		else:
			current_state = State.ROAMING


func _process_fleeing(delta: float) -> void:
	flee_timer -= delta
	if flee_timer <= 0:
		current_state = State.ROAMING
		return

	# Fliehe vom Spieler (wenn Fackel aktiv) oder vom Lagerfeuer
	var flee_from: Vector3 = campfire_position
	if is_instance_valid(target_player) and target_player.has_method("toggle_torch") and target_player.torch_active:
		flee_from = target_player.global_position

	var direction := (global_position - flee_from)
	direction.y = 0
	direction = direction.normalized()
	velocity.x = direction.x * chase_speed  # Schneller fliehen
	velocity.z = direction.z * chase_speed
	_face_direction(direction, delta)


func _rebuild_model() -> void:
	if deer_model and is_instance_valid(deer_model):
		deer_model.queue_free()
	var model_script: GDScript = preload("res://scripts/deer_model.gd")
	deer_model = Node3D.new()
	deer_model.set_script(model_script)
	deer_model.hungry = hungry
	deer_model.name = "DeerModel"
	add_child(deer_model)


func set_hungry(is_hungry: bool) -> void:
	hungry = is_hungry
	_rebuild_model()


func activate(player: CharacterBody3D, campfire_pos: Vector3) -> void:
	campfire_position = campfire_pos

	# 30% Chance auf hungrigen Hirsch
	set_hungry(randf() < 0.3)

	visible = true
	set_physics_process(true)
	current_state = State.ROAMING

	# Spawn weit weg vom Spieler
	var spawn_angle := randf() * TAU
	var spawn_pos: Vector3 = player.global_position + Vector3(
		cos(spawn_angle) * spawn_distance,
		0,
		sin(spawn_angle) * spawn_distance
	)
	spawn_pos.y = 1.0
	global_position = spawn_pos
	_pick_roam_target()


func deactivate() -> void:
	visible = false
	set_physics_process(false)
	current_state = State.INACTIVE
	target_player = null


func _pick_roam_target() -> void:
	var angle := randf() * TAU
	var dist := randf_range(10.0, 30.0)
	roam_target = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	roam_target.y = global_position.y


func _check_for_player() -> void:
	# Spieler im Szenenbaum finden
	var players := get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody3D:
			var distance: float = global_position.distance_to(p.global_position)
			if distance < detection_range:
				# Prüfe ob Spieler Fackel hat – dann fliehen!
				if p.has_method("toggle_torch") and p.torch_active:
					if distance < 12.0:
						target_player = p
						current_state = State.FLEEING
						flee_timer = 4.0
						return
					else:
						continue  # Zu weit weg, Fackel schreckt nicht ab
				# Prüfe ob Spieler nicht in sicherer Zone
				var dist_to_campfire: float = p.global_position.distance_to(campfire_position)
				if dist_to_campfire >= campfire_safe_radius:
					target_player = p
					current_state = State.CHASING
					return


func _face_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0.1:
		var target_rot := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 8.0 * delta)

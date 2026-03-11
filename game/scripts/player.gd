extends CharacterBody3D

# Spieler-Einstellungen
@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var max_hp: float = 100.0
@export var rotation_speed: float = 15.0  # Schnelle Drehung wie in Roblox

# Zustand
var hp: float = 100.0
var inventory: Array = []
var wood_count: int = 0
var has_torch: bool = false
var is_near_campfire: bool = false
var is_safe: bool = false

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
	# Schwerkraft
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Input sammeln (Joystick oder Tastatur)
	var input_dir := Vector2.ZERO
	var ctrl_held := Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META)

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
	if input_dir.length() < 0.1 and not ctrl_held:
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
	wood_count += amount
	wood_changed.emit(wood_count)


func craft_torch() -> bool:
	if wood_count >= 3:
		wood_count -= 3
		has_torch = true
		wood_changed.emit(wood_count)
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

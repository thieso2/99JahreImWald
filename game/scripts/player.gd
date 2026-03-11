extends CharacterBody3D

# Spieler-Einstellungen
@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var max_hp: float = 100.0

# Zustand
var hp: float = 100.0
var inventory: Array = []
var wood_count: int = 0
var has_torch: bool = false
var is_near_campfire: bool = false
var is_safe: bool = false

# Touch-Steuerung
var joystick_direction: Vector2 = Vector2.ZERO

# Kamera
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

# Signale
signal hp_changed(new_hp: float)
signal wood_changed(new_count: int)
signal player_died()
signal entered_safe_zone()
signal left_safe_zone()


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	# Schwerkraft
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Bewegung aus Joystick-Input
	var direction := Vector3.ZERO
	if joystick_direction.length() > 0.1:
		# Bewegung relativ zur Kamera
		var cam_basis := camera.global_transform.basis
		var forward := -cam_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right := cam_basis.x
		right.y = 0
		right = right.normalized()

		direction = (forward * -joystick_direction.y + right * joystick_direction.x).normalized()

	# Auch Tastatur-Input unterstützen (zum Testen am PC)
	var kb_dir := Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		kb_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		kb_dir.y += 1
	if Input.is_action_pressed("move_left"):
		kb_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		kb_dir.x += 1

	if kb_dir.length() > 0.1:
		var cam_basis := camera.global_transform.basis
		var forward := -cam_basis.z
		forward.y = 0
		forward = forward.normalized()
		var right := cam_basis.x
		right.y = 0
		right = right.normalized()
		direction = (forward * -kb_dir.y + right * kb_dir.x).normalized()

	# Geschwindigkeit setzen
	var current_speed := speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed

	# Spieler in Bewegungsrichtung drehen
	if direction.length() > 0.1:
		var target_rotation := atan2(direction.x, direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 10.0 * delta)

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

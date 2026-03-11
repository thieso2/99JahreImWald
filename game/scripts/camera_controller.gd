extends Node3D

# Kamera-Steuerung
#
# Pfeiltasten:
#   Links/Rechts = Kamera drehen
#   Hoch = Vorwärts laufen (in Kamera-Blickrichtung)
#   Runter = Umdrehen und rückwärts laufen
#
# Shift + Pfeiltasten:
#   Hoch/Runter = Kamera-Abstand (Zoom)
#   Links/Rechts = Kamera-Winkel (Neigung)
#
# +/- = Zoom, Mausrad = Zoom
# Rechte Maustaste + Maus = Kamera frei drehen
# Touch: Bildschirm wischen = drehen, Pinch = Zoom

@export var rotation_sensitivity_mouse: float = 0.3
@export var rotation_sensitivity_touch: float = 0.3
@export var turn_speed: float = 120.0         # Grad/s: Pfeiltasten drehen
@export var pitch_speed: float = 60.0         # Grad/s: Ctrl+Hoch/Runter neigen
@export var zoom_speed_scroll: float = 1.0
@export var zoom_speed_key: float = 8.0
@export var min_distance: float = 2.0
@export var max_distance: float = 20.0
@export var default_distance: float = 8.0
@export var first_person_threshold: float = 2.5

# Kamera-Winkel (in Grad)
var yaw: float = 0.0       # Horizontale Drehung
var pitch: float = 25.0    # Vertikale Neigung (positiv = von oben schauen)
var distance: float = 8.0  # Abstand zum Spieler

var target: Node3D = null

# Touch-Tracking
var camera_touch_index: int = -1
var last_camera_touch_pos: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	distance = default_distance


func _process(delta: float) -> void:
	var shift_held := Input.is_key_pressed(KEY_SHIFT)

	if shift_held:
		# Shift + Pfeiltasten: Kamera-Winkel und Abstand
		if Input.is_key_pressed(KEY_UP):
			distance = clampf(distance - zoom_speed_key * delta, min_distance, max_distance)
		if Input.is_key_pressed(KEY_DOWN):
			distance = clampf(distance + zoom_speed_key * delta, min_distance, max_distance)
		if Input.is_key_pressed(KEY_LEFT):
			pitch = clampf(pitch + pitch_speed * delta, 5.0, 80.0)
		if Input.is_key_pressed(KEY_RIGHT):
			pitch = clampf(pitch - pitch_speed * delta, 5.0, 80.0)
	else:
		# Pfeiltasten Links/Rechts: Kamera drehen
		if Input.is_key_pressed(KEY_LEFT):
			yaw -= turn_speed * delta
		if Input.is_key_pressed(KEY_RIGHT):
			yaw += turn_speed * delta

	# Zoom mit +/-
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		distance = clampf(distance - zoom_speed_key * delta, min_distance, max_distance)
	if Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		distance = clampf(distance + zoom_speed_key * delta, min_distance, max_distance)

	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	# Rechte Maustaste + Maus = Kamera frei drehen
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw += event.relative.x * rotation_sensitivity_mouse
		pitch = clampf(pitch - event.relative.y * rotation_sensitivity_mouse, 5.0, 80.0)

	# Mausrad = Zoom
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_speed_scroll, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_speed_scroll, min_distance, max_distance)

	# Touch: Bildschirm wischen = drehen
	elif event is InputEventScreenTouch:
		if event.pressed:
			if not _is_on_joystick(event.position) and camera_touch_index == -1:
				camera_touch_index = event.index
				last_camera_touch_pos = event.position
		else:
			if event.index == camera_touch_index:
				camera_touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == camera_touch_index:
			var delta_pos: Vector2 = event.position - last_camera_touch_pos
			yaw += delta_pos.x * rotation_sensitivity_touch
			pitch = clampf(pitch - delta_pos.y * rotation_sensitivity_touch, 5.0, 80.0)
			last_camera_touch_pos = event.position


func _update_camera() -> void:
	if not camera or not target:
		return

	var is_first_person: bool = distance < first_person_threshold

	if is_first_person:
		global_position = target.global_position + Vector3(0, 1.7, 0)
		camera.position = Vector3.ZERO
		camera.rotation_degrees = Vector3(-pitch, -yaw, 0)
		_set_player_visible(false)
	else:
		var yaw_rad: float = deg_to_rad(yaw)
		var pitch_rad: float = deg_to_rad(pitch)

		var cam_offset := Vector3.ZERO
		cam_offset.x = -sin(yaw_rad) * cos(pitch_rad) * distance
		cam_offset.z = cos(yaw_rad) * cos(pitch_rad) * distance
		cam_offset.y = sin(pitch_rad) * distance

		global_position = target.global_position
		camera.position = cam_offset
		camera.look_at(target.global_position + Vector3(0, 1.2, 0), Vector3.UP)
		_set_player_visible(true)


func _set_player_visible(vis: bool) -> void:
	if target:
		for child in target.get_children():
			if child.name == "PlayerModel":
				child.visible = vis


func _is_on_joystick(pos: Vector2) -> bool:
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	return pos.x < 250 and pos.y > screen_size.y - 250


func get_yaw() -> float:
	return yaw



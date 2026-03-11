extends Node3D

# Roblox-Style Kamera: Orbitet um den Spieler
# - Rechte Maustaste + Maus = Drehen (PC)
# - Touch-Drag (nicht auf Joystick) = Drehen (iPad)
# - Mausrad / Pinch / Shift+Pfeiltasten = Zoom
# - Kamera folgt dem Spieler sanft

@export var follow_speed: float = 10.0
@export var rotation_sensitivity_mouse: float = 0.2
@export var rotation_sensitivity_touch: float = 0.25
@export var zoom_speed_scroll: float = 1.5
@export var zoom_speed_key: float = 8.0
@export var min_zoom: float = 2.0
@export var max_zoom: float = 25.0
@export var default_zoom: float = 10.0
@export var min_pitch: float = -80.0   # Fast von oben
@export var max_pitch: float = -5.0    # Fast horizontal
@export var first_person_threshold: float = 2.5

var target: Node3D = null
var current_zoom: float = 10.0
var camera_yaw: float = 0.0
var camera_pitch: float = -30.0

# Touch-Tracking
var camera_touch_index: int = -1
var last_camera_touch_pos: Vector2 = Vector2.ZERO
var pinch_touch_ids: Array[int] = []
var last_pinch_distance: float = 0.0

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	current_zoom = default_zoom
	_update_camera_transform()


func _process(delta: float) -> void:
	# Spieler folgen
	if target:
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

	# Tastatur: Zoom mit Shift + Pfeiltasten
	var shift_held := Input.is_key_pressed(KEY_SHIFT)
	if shift_held:
		if Input.is_key_pressed(KEY_UP):
			current_zoom = clampf(current_zoom - zoom_speed_key * delta, min_zoom, max_zoom)
		if Input.is_key_pressed(KEY_DOWN):
			current_zoom = clampf(current_zoom + zoom_speed_key * delta, min_zoom, max_zoom)

	_update_camera_transform()


func _unhandled_input(event: InputEvent) -> void:
	# === MAUS (PC) ===
	# Rechte Maustaste + Mausbewegung = Kamera drehen
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_yaw -= event.relative.x * rotation_sensitivity_mouse
		camera_pitch = clampf(camera_pitch + event.relative.y * rotation_sensitivity_mouse, min_pitch, max_pitch)
		get_viewport().set_input_as_handled()

	# Mausrad = Zoom
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = clampf(current_zoom - zoom_speed_scroll, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = clampf(current_zoom + zoom_speed_scroll, min_zoom, max_zoom)
			get_viewport().set_input_as_handled()

	# === TOUCH (iPad) ===
	elif event is InputEventScreenTouch:
		if event.pressed:
			# Prüfe ob Touch NICHT auf dem Joystick ist (linke untere Ecke)
			if not _is_on_joystick(event.position):
				if pinch_touch_ids.size() == 0 and camera_touch_index == -1:
					# Erster Finger für Kamera-Rotation
					camera_touch_index = event.index
					last_camera_touch_pos = event.position
				elif pinch_touch_ids.size() == 0 and camera_touch_index != -1:
					# Zweiter Finger -> Pinch-Zoom
					pinch_touch_ids = [camera_touch_index, event.index]
					camera_touch_index = -1
					var pos1: Vector2 = last_camera_touch_pos
					var pos2: Vector2 = event.position
					last_pinch_distance = pos1.distance_to(pos2)
		else:
			# Finger losgelassen
			if event.index == camera_touch_index:
				camera_touch_index = -1
			if event.index in pinch_touch_ids:
				pinch_touch_ids.clear()
				last_pinch_distance = 0.0

	elif event is InputEventScreenDrag:
		# Kamera-Rotation mit einem Finger
		if event.index == camera_touch_index and pinch_touch_ids.is_empty():
			var delta_pos: Vector2 = event.position - last_camera_touch_pos
			camera_yaw -= delta_pos.x * rotation_sensitivity_touch
			camera_pitch = clampf(camera_pitch + delta_pos.y * rotation_sensitivity_touch, min_pitch, max_pitch)
			last_camera_touch_pos = event.position

		# Pinch-Zoom
		if event.index in pinch_touch_ids and pinch_touch_ids.size() == 2:
			# Wir tracken nur die Distanzänderung
			# (vereinfacht: reagiert auf jede Drag-Bewegung)
			if last_pinch_distance > 0:
				# Berechne neue Distanz basierend auf aktuellem Drag
				var zoom_change: float = -event.relative.y * 0.03
				current_zoom = clampf(current_zoom + zoom_change, min_zoom, max_zoom)


func _update_camera_transform() -> void:
	if not camera:
		return

	var is_first_person: bool = current_zoom < first_person_threshold

	if is_first_person:
		# First-Person: Kamera auf Augenhöhe
		camera.position = Vector3(0, 1.8, 0)
		var fp_pitch: float = clampf(camera_pitch, -80.0, 10.0)
		camera.rotation_degrees = Vector3(fp_pitch, camera_yaw, 0)
		if target:
			_set_player_visible(false)
	else:
		# Third-Person: Kamera orbitet um den Spieler
		var yaw_rad: float = deg_to_rad(camera_yaw)
		var pitch_rad: float = deg_to_rad(camera_pitch)

		var offset := Vector3.ZERO
		offset.x = sin(yaw_rad) * cos(pitch_rad) * current_zoom
		offset.z = cos(yaw_rad) * cos(pitch_rad) * current_zoom
		offset.y = -sin(pitch_rad) * current_zoom

		camera.position = offset
		camera.look_at(Vector3(0, 1.2, 0), Vector3.UP)

		if target:
			_set_player_visible(true)


func _set_player_visible(vis: bool) -> void:
	if target:
		# PlayerModel ist ein Kind des Spielers
		for child in target.get_children():
			if child.name == "PlayerModel":
				child.visible = vis


func _is_on_joystick(pos: Vector2) -> bool:
	# Joystick ist links unten, ca. 200x200 Pixel
	var screen_size: Vector2 = get_viewport().get_visible_rect().size
	return pos.x < 230 and pos.y > screen_size.y - 230


func get_camera_yaw() -> float:
	return camera_yaw

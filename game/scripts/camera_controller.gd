extends Node3D

# Kamera-Controller: Rotation per Touch-Drag, Zoom per Pinch

@export var follow_speed: float = 8.0
@export var rotation_sensitivity: float = 0.3
@export var zoom_speed: float = 2.0
@export var key_rotate_speed: float = 120.0  # Grad pro Sekunde
@export var key_zoom_speed: float = 8.0      # Einheiten pro Sekunde
@export var min_zoom: float = 1.5   # Nah (fast First-Person)
@export var max_zoom: float = 20.0  # Weit weg
@export var default_zoom: float = 12.0
@export var min_pitch: float = -10.0  # Grad - fast horizontal
@export var max_pitch: float = -70.0  # Grad - fast von oben
@export var first_person_threshold: float = 2.5  # Ab diesem Zoom -> First Person

var target: Node3D = null
var current_zoom: float = 12.0
var camera_yaw: float = 0.0    # Horizontale Rotation (Grad)
var camera_pitch: float = -35.0  # Vertikale Neigung (Grad)

# Touch-Tracking
var touch_points: Dictionary = {}  # index -> position
var last_touch_distance: float = 0.0
var is_rotating: bool = false
var rotate_touch_index: int = -1
var last_rotate_pos: Vector2 = Vector2.ZERO

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	current_zoom = default_zoom
	_update_camera_transform()


func _process(delta: float) -> void:
	if target:
		# Sanft dem Spieler folgen
		global_position = global_position.lerp(target.global_position, follow_speed * delta)

	# Tastatur-Kamerasteuerung
	var shift_held := Input.is_key_pressed(KEY_SHIFT)

	if shift_held:
		# Shift + Hoch/Runter: Zoom
		if Input.is_key_pressed(KEY_UP):
			current_zoom = clampf(current_zoom - key_zoom_speed * delta, min_zoom, max_zoom)
		if Input.is_key_pressed(KEY_DOWN):
			current_zoom = clampf(current_zoom + key_zoom_speed * delta, min_zoom, max_zoom)
	else:
		# Hoch/Runter: Kamera neigen
		if Input.is_key_pressed(KEY_UP):
			camera_pitch = clampf(camera_pitch + key_rotate_speed * delta, max_pitch, min_pitch)
		if Input.is_key_pressed(KEY_DOWN):
			camera_pitch = clampf(camera_pitch - key_rotate_speed * delta, max_pitch, min_pitch)

	# Links/Rechts: Kamera drehen (immer, mit oder ohne Shift)
	if Input.is_key_pressed(KEY_LEFT):
		camera_yaw += key_rotate_speed * delta
	if Input.is_key_pressed(KEY_RIGHT):
		camera_yaw -= key_rotate_speed * delta

	_update_camera_transform()


func _input(event: InputEvent) -> void:
	# Touch-Events tracken
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			# Wenn nur ein Finger und auf der rechten Bildschirmhälfte -> Rotation
			if touch_points.size() == 1:
				var screen_width: float = get_viewport().get_visible_rect().size.x
				if event.position.x > screen_width * 0.35:
					is_rotating = true
					rotate_touch_index = event.index
					last_rotate_pos = event.position
			# Zwei Finger -> Pinch-Zoom vorbereiten
			if touch_points.size() == 2:
				is_rotating = false
				var points := touch_points.values()
				last_touch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)
		else:
			touch_points.erase(event.index)
			if event.index == rotate_touch_index:
				is_rotating = false
				rotate_touch_index = -1

	elif event is InputEventScreenDrag:
		touch_points[event.index] = event.position

		# Rotation mit einem Finger (rechte Seite)
		if is_rotating and event.index == rotate_touch_index and touch_points.size() == 1:
			var delta_pos: Vector2 = event.position - last_rotate_pos
			camera_yaw -= delta_pos.x * rotation_sensitivity
			camera_pitch = clampf(camera_pitch - delta_pos.y * rotation_sensitivity, max_pitch, min_pitch)
			last_rotate_pos = event.position

		# Pinch-Zoom mit zwei Fingern
		if touch_points.size() == 2:
			var points := touch_points.values()
			var current_distance: float = (points[0] as Vector2).distance_to(points[1] as Vector2)
			if last_touch_distance > 0:
				var zoom_delta: float = (last_touch_distance - current_distance) * 0.05
				current_zoom = clampf(current_zoom + zoom_delta, min_zoom, max_zoom)
			last_touch_distance = current_distance

	# Mausrad zum Zoomen (PC-Test)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_zoom = clampf(current_zoom - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_zoom = clampf(current_zoom + zoom_speed, min_zoom, max_zoom)

	# Rechte Maustaste zum Rotieren (PC-Test)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		camera_yaw -= event.relative.x * rotation_sensitivity
		camera_pitch = clampf(camera_pitch - event.relative.y * rotation_sensitivity, max_pitch, min_pitch)


func _update_camera_transform() -> void:
	if not camera:
		return

	var is_first_person: bool = current_zoom < first_person_threshold

	if is_first_person:
		# First-Person: Kamera auf Augenhöhe des Spielers
		camera.position = Vector3(0, 1.8, 0)
		camera.rotation_degrees = Vector3(camera_pitch * 0.3, camera_yaw, 0)
		# Spieler-Mesh verstecken in First-Person
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
		camera.look_at(Vector3.ZERO, Vector3.UP)

		if target:
			_set_player_visible(true)


func _set_player_visible(visible: bool) -> void:
	if target:
		for child in target.get_children():
			if child is MeshInstance3D:
				child.visible = visible


func get_camera_yaw() -> float:
	return camera_yaw

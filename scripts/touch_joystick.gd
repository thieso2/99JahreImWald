extends Control

# Dynamischer Touch-Joystick im Roblox-Stil:
# - Erscheint dort, wo man im linken unteren Bildschirmbereich hintippt
# - Zieht man über den Rand hinaus, wandert die Basis mit dem Finger mit
# - Beim Loslassen bleibt nur ein blasser Ruhe-Kreis an der Standardposition

@export var joystick_radius: float = 75.0
@export var dead_zone: float = 0.15

# Referenzen
@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

# Zustand
var is_pressed: bool = false
var touch_index: int = -1
var joystick_output: Vector2 = Vector2.ZERO
var rest_position: Vector2 = Vector2.ZERO  # Globale Ruheposition der Basis

# Signal
signal joystick_input(direction: Vector2)


func _ready() -> void:
	if knob:
		knob.position = base.size / 2.0 - knob.size / 2.0
	rest_position = base.global_position
	_set_active(false)


# Bewegungszone wie bei Roblox: linkes Bildschirmdrittel, unterhalb des oberen Randes
# (Kamera-Drag hat dieselbe Formel in camera_controller._is_on_joystick)
static func is_in_move_zone(pos: Vector2, screen: Vector2) -> bool:
	return pos.x < screen.x * 0.4 and pos.y > screen.y * 0.3


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			var screen: Vector2 = get_viewport().get_visible_rect().size
			if is_in_move_zone(event.position, screen):
				is_pressed = true
				touch_index = event.index
				# Joystick erscheint am Finger
				base.global_position = event.position - base.size / 2.0
				_set_active(true)
				_update_knob(event.position)
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_index and is_pressed:
			_update_knob(event.position)


func _update_knob(touch_pos: Vector2) -> void:
	var center: Vector2 = base.global_position + base.size / 2.0
	var direction: Vector2 = touch_pos - center
	var distance: float = direction.length()

	# Roblox-Verhalten: Über den Rand hinausziehen nimmt die Basis mit
	if distance > joystick_radius:
		var excess: Vector2 = direction.normalized() * (distance - joystick_radius)
		base.global_position += excess
		center += excess
		direction = direction.normalized() * joystick_radius

	# Knob-Position aktualisieren
	if knob:
		knob.global_position = center + direction - knob.size / 2.0

	# Output berechnen (normalisiert -1 bis 1)
	joystick_output = direction / joystick_radius

	# Dead Zone anwenden
	if joystick_output.length() < dead_zone:
		joystick_output = Vector2.ZERO

	joystick_input.emit(joystick_output)


func _reset_joystick() -> void:
	is_pressed = false
	touch_index = -1
	joystick_output = Vector2.ZERO
	base.global_position = rest_position
	if knob:
		knob.position = base.size / 2.0 - knob.size / 2.0
	_set_active(false)
	joystick_input.emit(Vector2.ZERO)


func _set_active(active: bool) -> void:
	# Aktiv: deutlich sichtbar – Ruhezustand: blasser Kreis
	if base:
		base.modulate.a = 0.95 if active else 0.35

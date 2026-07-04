extends Control

# Virtueller Joystick für Touch-Steuerung

@export var joystick_radius: float = 75.0
@export var dead_zone: float = 0.15

# Referenzen
@onready var base: TextureRect = $Base
@onready var knob: TextureRect = $Base/Knob

# Zustand
var is_pressed: bool = false
var touch_index: int = -1
var joystick_output: Vector2 = Vector2.ZERO

# Signal
signal joystick_input(direction: Vector2)


func _ready() -> void:
	# Joystick zentrieren
	if knob:
		knob.position = base.size / 2.0 - knob.size / 2.0


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_in_joystick(event.position):
				is_pressed = true
				touch_index = event.index
				_update_knob(event.position)
		else:
			if event.index == touch_index:
				_reset_joystick()

	elif event is InputEventScreenDrag:
		if event.index == touch_index and is_pressed:
			_update_knob(event.position)


func _update_knob(touch_pos: Vector2) -> void:
	var center := base.global_position + base.size / 2.0
	var direction := touch_pos - center
	var distance := direction.length()

	# Begrenze auf Radius
	if distance > joystick_radius:
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
	if knob:
		knob.position = base.size / 2.0 - knob.size / 2.0
	joystick_input.emit(Vector2.ZERO)


func _is_point_in_joystick(point: Vector2) -> bool:
	var rect := Rect2(base.global_position, base.size)
	# Erweiterter Bereich für einfachere Touch-Bedienung
	rect = rect.grow(30.0)
	return rect.has_point(point)

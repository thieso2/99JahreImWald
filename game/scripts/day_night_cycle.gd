extends Node3D

# Tag/Nacht-Einstellungen
@export var day_duration: float = 60.0  # Sekunden pro Tag-Phase
@export var night_duration: float = 45.0  # Sekunden pro Nacht-Phase

# Zustand
var current_time: float = 0.0  # 0.0 = Morgen, 0.5 = Mitternacht, 1.0 = nächster Morgen
var current_day: int = 1
var is_night: bool = false
var total_cycle_duration: float = 0.0

# Referenzen
@onready var sun: DirectionalLight3D = $Sun
@onready var environment: WorldEnvironment = $WorldEnvironment

# Farben
var day_sky_color := Color(0.55, 0.72, 0.92)
var sunset_sky_color := Color(0.95, 0.5, 0.3)
var night_sky_color := Color(0.05, 0.05, 0.15)
var day_light_color := Color(1.0, 0.97, 0.9)
var night_light_color := Color(0.15, 0.15, 0.3)

# Signale
signal time_changed(time: float, day: int)
signal night_started(day: int)
signal day_started(day: int)


func _ready() -> void:
	total_cycle_duration = day_duration + night_duration
	current_time = 0.0


func _process(delta: float) -> void:
	# Zeit voranschreiten
	current_time += delta / total_cycle_duration
	if current_time >= 1.0:
		current_time -= 1.0
		current_day += 1

	# Nacht-Status aktualisieren
	var was_night := is_night
	is_night = current_time > 0.35 and current_time < 0.85

	if is_night and not was_night:
		night_started.emit(current_day)
	elif not is_night and was_night:
		day_started.emit(current_day)

	# Sonne rotieren (Vollkreis über den Tag)
	if sun:
		sun.rotation_degrees.x = -current_time * 360.0 + 90.0

		# Lichtintensität und Farbe
		var light_intensity: float
		var light_color: Color
		var sky_color: Color

		if current_time < 0.25:
			# Morgen -> Mittag
			light_intensity = lerp(0.5, 1.0, current_time / 0.25)
			light_color = day_light_color
			sky_color = day_sky_color
		elif current_time < 0.35:
			# Mittag -> Sonnenuntergang
			var t := (current_time - 0.25) / 0.1
			light_intensity = lerp(1.0, 0.3, t)
			light_color = day_light_color.lerp(sunset_sky_color, t)
			sky_color = day_sky_color.lerp(sunset_sky_color, t)
		elif current_time < 0.5:
			# Sonnenuntergang -> Nacht
			var t := (current_time - 0.35) / 0.15
			light_intensity = lerp(0.3, 0.05, t)
			light_color = sunset_sky_color.lerp(night_light_color, t)
			sky_color = sunset_sky_color.lerp(night_sky_color, t)
		elif current_time < 0.75:
			# Nacht
			light_intensity = 0.05
			light_color = night_light_color
			sky_color = night_sky_color
		elif current_time < 0.85:
			# Nacht -> Morgendämmerung
			var t := (current_time - 0.75) / 0.1
			light_intensity = lerp(0.05, 0.3, t)
			light_color = night_light_color.lerp(sunset_sky_color, t)
			sky_color = night_sky_color.lerp(sunset_sky_color, t)
		else:
			# Morgendämmerung -> Tag
			var t := (current_time - 0.85) / 0.15
			light_intensity = lerp(0.3, 0.5, t)
			light_color = sunset_sky_color.lerp(day_light_color, t)
			sky_color = sunset_sky_color.lerp(day_sky_color, t)

		sun.light_energy = light_intensity
		sun.light_color = light_color

		# Umgebungslicht anpassen
		if environment and environment.environment:
			environment.environment.ambient_light_color = sky_color
			environment.environment.ambient_light_energy = light_intensity * 0.5

	time_changed.emit(current_time, current_day)


func get_day() -> int:
	return current_day


func get_is_night() -> bool:
	return is_night


func get_time_of_day_string() -> String:
	if current_time < 0.25:
		return "Morgen"
	elif current_time < 0.35:
		return "Nachmittag"
	elif current_time < 0.5:
		return "Abend"
	elif current_time < 0.85:
		return "Nacht"
	else:
		return "Morgendämmerung"

extends Node3D

# Game Manager – steuert den Spielablauf

@export var total_nights: int = 99

# Referenzen
@onready var player: CharacterBody3D = $Player
@onready var day_night: Node3D = $DayNightCycle
@onready var deer: CharacterBody3D = $DeerMonster
@onready var campfire: StaticBody3D = $Campfire
@onready var camera_controller: Node3D = $CameraController
@onready var hud: CanvasLayer = $HUD

# UI-Referenzen
@onready var hp_bar: ProgressBar = $HUD/HPBar
@onready var wood_label: Label = $HUD/WoodLabel
@onready var day_label: Label = $HUD/DayLabel
@onready var time_label: Label = $HUD/TimeLabel
@onready var message_label: Label = $HUD/MessageLabel
@onready var craft_button: Button = $HUD/CraftButton
@onready var joystick: Control = $HUD/TouchJoystick
@onready var harvest_button: Button = $HUD/HarvestButton

var message_timer: float = 0.0
var deer_active: bool = false


func _ready() -> void:
	# Signale verbinden
	player.hp_changed.connect(_on_hp_changed)
	player.wood_changed.connect(_on_wood_changed)
	player.player_died.connect(_on_player_died)
	player.entered_safe_zone.connect(_on_entered_safe_zone)
	player.left_safe_zone.connect(_on_left_safe_zone)

	day_night.night_started.connect(_on_night_started)
	day_night.day_started.connect(_on_day_started)
	day_night.time_changed.connect(_on_time_changed)

	joystick.joystick_input.connect(_on_joystick_input)

	craft_button.pressed.connect(_on_craft_pressed)
	harvest_button.pressed.connect(_on_harvest_pressed)

	# Kamera-Controller mit Spieler verbinden
	camera_controller.target = player

	# UI initialisieren
	_update_hp_bar(player.max_hp)
	_update_wood_label(0)
	day_label.text = "Tag 1"
	time_label.text = "Morgen"
	message_label.text = ""
	craft_button.text = "Fackel bauen (3 Holz)"

	_show_message("Willkommen im Wald! Sammle Holz und überlebe die Nacht!")


func _process(delta: float) -> void:
	# Kamera-Yaw an Spieler weitergeben für richtungsrelative Bewegung
	player.camera_yaw = camera_controller.get_camera_yaw()

	# Nachricht ausblenden
	if message_timer > 0:
		message_timer -= delta
		if message_timer <= 0:
			message_label.text = ""

	# Craft-Button aktivieren/deaktivieren
	craft_button.disabled = player.wood_count < 3 or player.has_torch

	# Harvest-Button nur anzeigen wenn Bäume in der Nähe
	_update_harvest_button()


func _on_hp_changed(new_hp: float) -> void:
	_update_hp_bar(new_hp)


func _on_wood_changed(new_count: int) -> void:
	_update_wood_label(new_count)


func _on_player_died() -> void:
	_show_message("Du bist gestorben! Respawn am Lagerfeuer...", 3.0)


func _on_entered_safe_zone() -> void:
	_show_message("Sichere Zone – das Feuer beschützt dich!", 2.0)


func _on_left_safe_zone() -> void:
	if day_night.get_is_night():
		_show_message("Vorsicht! Du verlässt die sichere Zone!", 2.0)


func _on_night_started(day: int) -> void:
	_show_message("Nacht %d beginnt... der Hirsch erwacht!" % day, 3.0)
	# Hirsch aktivieren
	if not deer_active:
		deer.activate(player, campfire.global_position)
		deer_active = true


func _on_day_started(day: int) -> void:
	if day >= total_nights:
		_show_message("Du hast alle 99 Nächte überlebt! GEWONNEN!", 10.0)
	else:
		_show_message("Tag %d – der Hirsch zieht sich zurück." % day, 3.0)
	# Hirsch deaktivieren
	deer.deactivate()
	deer_active = false


func _on_time_changed(time: float, day: int) -> void:
	day_label.text = "Tag %d / %d" % [day, total_nights]
	time_label.text = day_night.get_time_of_day_string()


func _on_joystick_input(direction: Vector2) -> void:
	player.set_joystick_input(direction)


func _on_craft_pressed() -> void:
	if player.craft_torch():
		_show_message("Fackel gebaut! Du hast jetzt Licht.", 2.0)
	else:
		_show_message("Nicht genug Holz! (3 benötigt)", 2.0)


func _on_harvest_pressed() -> void:
	# Nächsten Baum in Reichweite finden und ernten
	var trees := get_tree().get_nodes_in_group("tree")
	for tree in trees:
		if tree.has_method("harvest"):
			var distance: float = player.global_position.distance_to(tree.global_position)
			if distance < 4.0 and not tree.is_harvested:
				tree.harvest(player)
				_show_message("+%d Holz!" % tree.wood_amount, 1.0)
				return
	_show_message("Kein Baum in Reichweite.", 1.5)


func _update_harvest_button() -> void:
	var near_tree := false
	var trees := get_tree().get_nodes_in_group("tree")
	for tree in trees:
		if tree.has_method("harvest") and not tree.is_harvested:
			var distance: float = player.global_position.distance_to(tree.global_position)
			if distance < 5.0:
				near_tree = true
				break
	harvest_button.visible = near_tree


func _update_hp_bar(hp: float) -> void:
	if hp_bar:
		hp_bar.value = hp


func _update_wood_label(count: int) -> void:
	if wood_label:
		wood_label.text = "Holz: %d" % count


func _show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_timer = duration

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
@onready var axe_button: Button = $HUD/AxeButton
@onready var sapling_label: Label = $HUD/SaplingLabel
@onready var plant_button: Button = $HUD/PlantButton

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
	axe_button.pressed.connect(_on_axe_toggle_pressed)
	plant_button.pressed.connect(_on_plant_pressed)
	player.sapling_changed.connect(_on_sapling_changed)

	# Kamera-Controller mit Spieler verbinden
	camera_controller.target = player

	# Spieler bekommt zum Start eine Steinaxt
	player.give_axe(0)

	# UI initialisieren
	_update_hp_bar(player.max_hp)
	_update_wood_label(0)
	day_label.text = "Tag 1"
	time_label.text = "Morgen"
	message_label.text = ""
	craft_button.text = "Fackel bauen (3 Holz)"
	axe_button.text = "Axt ziehen"
	sapling_label.text = "Setzlinge: 0"
	plant_button.text = "Setzling pflanzen"
	plant_button.visible = false

	_show_message("Willkommen im Wald! Drücke 'Axt ziehen' und hacke Bäume!")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_chop"):
		_on_harvest_pressed()
	elif event.is_action_pressed("action_toggle_axe"):
		_on_axe_toggle_pressed()
	elif event.is_action_pressed("action_plant"):
		_on_plant_pressed()


func _process(delta: float) -> void:
	# Kamera-Yaw an Spieler weitergeben für richtungsrelative Bewegung
	player.camera_yaw = camera_controller.get_yaw()

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
	if player.axe_active:
		# Mit Axt: Baum hacken (mehrere Hiebe nötig)
		var result: Dictionary = player.try_chop_tree()
		if result.chopped:
			if result.felled:
				_show_message("Baum gefällt! Sammle die Holzscheite auf!", 2.0)
			else:
				_show_message("Hack!", 0.5)
		else:
			if player.chop_cooldown > 0:
				pass  # Cooldown, keine Nachricht
			else:
				_show_message("Kein Baum in Reichweite.", 1.5)
	else:
		_show_message("Ziehe zuerst deine Axt!", 1.5)


func _on_sapling_changed(new_count: int) -> void:
	sapling_label.text = "Setzlinge: %d" % new_count
	plant_button.visible = new_count > 0


func _on_plant_pressed() -> void:
	if player.plant_sapling():
		_show_message("Setzling gepflanzt! Er wird langsam wachsen.", 2.0)
	else:
		_show_message("Keine Setzlinge vorhanden.", 1.5)


func _on_axe_toggle_pressed() -> void:
	player.toggle_axe()
	if player.axe_active:
		axe_button.text = "Axt wegstecken"
		harvest_button.text = "Baum hacken"
	else:
		axe_button.text = "Axt ziehen"
		harvest_button.text = "Holz sammeln"


func _update_harvest_button() -> void:
	var near_tree := false
	var trees := get_tree().get_nodes_in_group("tree")
	for tree in trees:
		if tree.has_method("chop") and not tree.is_harvested:
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

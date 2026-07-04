extends Node3D

# Game Manager – steuert den Spielablauf

@export var total_nights: int = 99
const NIGHTS_PER_CHILD: int = 20  # Jedes gerettete Kind verkürzt die Nächte
var children_rescued: int = 0
var rescued_spots: Array = []  # Indizes der bereits geretteten Kinder (für Speicherstand)
var save_system: Node = null

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
@onready var pickup_button: Button = $HUD/PickupButton
@onready var drop_button: Button = $HUD/DropButton
@onready var inventory_label: Label = $HUD/InventoryLabel

# Sound-System
var game_sounds: Node = null
var inventory_bar: Control = null
var cheat_menu: PanelContainer = null
var workbench_menu: PanelContainer = null
var minimap: Control = null

var message_timer: float = 0.0
var deer_active: bool = false

# Touch-Buttons (per Code erstellt, kontextabhängig sichtbar)
var help_menu: PanelContainer = null
var torch_button: Button = null
var cook_button: Button = null
var eat_button: Button = null
var place_button: Button = null
var workbench_button: Button = null
var help_button: Button = null


func _ready() -> void:
	# Speichersystem zuerst – Spielstand lesen bevor die Welt aufgebaut wird
	var save_script: GDScript = preload("res://scripts/save_system.gd")
	save_system = Node.new()
	save_system.set_script(save_script)
	save_system.name = "SaveSystem"
	add_child(save_system)
	var save_data: Dictionary = save_system.read_save()

	# Welt-Fortschritt wiederherstellen (vor dem Kinder-Spawn!)
	var saved_world: Dictionary = save_data.get("world", {})
	if not saved_world.is_empty():
		total_nights = int(saved_world.get("total_nights", total_nights))
		children_rescued = int(saved_world.get("children_rescued", 0))
		for idx in saved_world.get("rescued_spots", []):
			rescued_spots.append(int(idx))

	# Landschaft generieren
	var landscape_script: GDScript = preload("res://scripts/landscape_generator.gd")
	var landscape := Node3D.new()
	landscape.set_script(landscape_script)
	landscape.name = "LandscapeGenerator"
	add_child(landscape)

	# Unterirdische Welt tief unter der Karte
	var underworld_script: GDScript = preload("res://scripts/underground_world.gd")
	var underworld := Node3D.new()
	underworld.set_script(underworld_script)
	underworld.name = "UndergroundWorld"
	underworld.position = Vector3(0, -100.0, 0)
	add_child(underworld)

	# Portal im Wald (wo früher die Höhle war) → führt in die Unterwelt
	var portal_script: GDScript = preload("res://scripts/portal.gd")
	var portal := Node3D.new()
	portal.set_script(portal_script)
	portal.name = "Portal"
	portal.position = Vector3(40.0, 0, -30.0)  # Nordöstlich vom Camp
	portal.target_position = Vector3(0, -99.0, 6.0)  # Ankunft in der Unterwelt
	portal.arrival_message = "Du betrittst die Unterwelt... Sei vorsichtig!"
	add_child(portal)
	portal.player_teleported.connect(_on_portal_teleported)

	# Rück-Portal in der Unterwelt → führt zurück in den Wald
	var return_portal := Node3D.new()
	return_portal.set_script(portal_script)
	return_portal.name = "ReturnPortal"
	return_portal.position = Vector3(0, -100.0, 12.0)
	return_portal.target_position = Vector3(40.0, 1.0, -25.0)  # Vor dem Wald-Portal
	return_portal.portal_color = Color(0.2, 0.8, 0.4, 1)  # Grün = zurück
	return_portal.arrival_message = "Zurück im Wald!"
	add_child(return_portal)
	return_portal.player_teleported.connect(_on_portal_teleported)

	# Die 4 vermissten Kinder in den Ecken der Unterwelt verstecken
	_spawn_lost_children()

	# Tiere spawnen: Hasen (friedlich) und Wölfe (feindlich)
	_spawn_animals()

	# Sound-System erstellen
	var sounds_script: GDScript = preload("res://scripts/game_sounds.gd")
	game_sounds = Node.new()
	game_sounds.set_script(sounds_script)
	game_sounds.name = "GameSounds"
	add_child(game_sounds)

	# Inventarleiste erstellen
	var inv_bar_script: GDScript = preload("res://scripts/inventory_bar.gd")
	inventory_bar = Control.new()
	inventory_bar.set_script(inv_bar_script)
	inventory_bar.name = "InventoryBar"
	hud.add_child(inventory_bar)

	# Cheat-Menü erstellen
	var cheat_script: GDScript = preload("res://scripts/cheat_menu.gd")
	cheat_menu = PanelContainer.new()
	cheat_menu.set_script(cheat_script)
	cheat_menu.name = "CheatMenu"
	cheat_menu.player = player
	cheat_menu.deer = deer
	cheat_menu.camera_controller = camera_controller
	hud.add_child(cheat_menu)

	# Werkbank-Menü erstellen
	var wb_script: GDScript = preload("res://scripts/workbench_menu.gd")
	workbench_menu = PanelContainer.new()
	workbench_menu.set_script(wb_script)
	workbench_menu.name = "WorkbenchMenu"
	workbench_menu.player = player
	workbench_menu.item_crafted.connect(_on_workbench_crafted)
	hud.add_child(workbench_menu)

	# Minimap erstellen
	var minimap_script: GDScript = preload("res://scripts/minimap.gd")
	minimap = Control.new()
	minimap.set_script(minimap_script)
	minimap.name = "Minimap"
	minimap.player = player
	minimap.camera_controller = camera_controller
	hud.add_child(minimap)

	# Hilfe-Menü erstellen (? zum Öffnen)
	var help_script: GDScript = preload("res://scripts/help_menu.gd")
	help_menu = PanelContainer.new()
	help_menu.set_script(help_script)
	help_menu.name = "HelpMenu"
	hud.add_child(help_menu)

	# Touch-Buttons für iPad (kontextabhängig sichtbar)
	_create_touch_buttons()

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
	pickup_button.pressed.connect(_on_pickup_pressed)
	drop_button.pressed.connect(_on_drop_pressed)
	player.sapling_changed.connect(_on_sapling_changed)
	player.inventory_changed.connect(_on_inventory_changed)

	# Werkbank-Signale
	campfire.workbench_entered.connect(_on_workbench_entered)
	campfire.workbench_exited.connect(_on_workbench_exited)

	# Kamera-Controller mit Spieler verbinden
	camera_controller.target = player

	# Kamera näher und höher am Start
	camera_controller.distance = 5.0
	camera_controller.pitch = 35.0

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
	pickup_button.text = "Aufsammeln [E]"
	pickup_button.visible = false
	drop_button.text = "Ablegen [G]"
	drop_button.visible = false
	inventory_label.text = ""

	_show_message("Q=Axt, T=Fackel, E=Hacken/Sammeln, F=Pflanzen, G=Ablegen, P=Platzieren, B=Werkbank")

	# Spielstand anwenden (Spieler-Position, Inventar, Tag/Zeit, platzierte Items)
	save_system.game_manager = self
	save_system.player = player
	save_system.day_night = day_night
	save_system.apply_save(save_data)

	# Wenn mitten in der Nacht geladen wurde: Hirsch direkt aktivieren
	if day_night.is_night and not deer_active:
		deer.activate(player, campfire.global_position)
		deer_active = true

	if not save_data.is_empty():
		_show_message("Spielstand geladen! Weiter geht's an Tag %d." % day_night.current_day, 3.0)


func reset_game() -> void:
	# Speicherstand löschen und Spiel komplett neu starten
	if save_system:
		save_system.delete_save()
		save_system.game_manager = null  # Autosave stoppen
	get_tree().reload_current_scene()


func _notification(what: int) -> void:
	# Beim Schließen des Spiels speichern
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if save_system:
			save_system.save_game()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action_chop"):
		_on_action_pressed()
	elif event.is_action_pressed("action_toggle_axe"):
		_on_axe_toggle_pressed()
	elif event.is_action_pressed("action_plant"):
		_on_plant_pressed()
	elif event.is_action_pressed("action_drop"):
		_on_drop_pressed()
	elif event.is_action_pressed("action_toggle_torch"):
		_on_torch_toggle_pressed()
	elif event.is_action_pressed("action_place"):
		_on_place_pressed()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_C:
			_on_cook_pressed()
		elif event.keycode == KEY_V:
			_on_eat_pressed()


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

	# Buttons aktualisieren
	_update_action_buttons()


func _on_hp_changed(new_hp: float) -> void:
	_update_hp_bar(new_hp)


func _on_wood_changed(new_count: int) -> void:
	_update_wood_label(new_count)


func _on_player_died() -> void:
	_show_message("Du bist gestorben! Respawn am Lagerfeuer... (Feinde haben dich getötet)", 4.0)


func _on_entered_safe_zone() -> void:
	_show_message("Sichere Zone – das Feuer beschützt dich!", 2.0)


func _on_left_safe_zone() -> void:
	if day_night.get_is_night():
		_show_message("Vorsicht! Du verlässt die sichere Zone!", 2.0)


func _on_night_started(day: int) -> void:
	_show_message("Nacht %d beginnt... der Hirsch erwacht!" % day, 3.0)
	if not deer_active:
		deer.activate(player, campfire.global_position)
		deer_active = true


func _on_day_started(day: int) -> void:
	if day >= total_nights:
		_show_message("Du hast alle %d Nächte überlebt! GEWONNEN!" % total_nights, 10.0)
	else:
		_show_message("Tag %d – der Hirsch zieht sich zurück." % day, 3.0)
	deer.deactivate()
	deer_active = false


func _on_time_changed(time: float, day: int) -> void:
	day_label.text = "Tag %d / %d  |  Kinder %d/4" % [day, total_nights, children_rescued]
	time_label.text = day_night.get_time_of_day_string()


func _on_joystick_input(direction: Vector2) -> void:
	player.set_joystick_input(direction)


func _on_craft_pressed() -> void:
	if player.craft_torch():
		_show_message("Fackel gebaut! Drücke T zum Anzünden.", 2.0)
		if game_sounds:
			game_sounds.play_pickup_sound()
	else:
		_show_message("Nicht genug Holz! (3 benötigt)", 2.0)


func _on_torch_toggle_pressed() -> void:
	if not player.has_torch:
		_show_message("Du hast keine Fackel. Baue eine! (3 Holz)", 1.5)
		return
	player.toggle_torch()
	if player.torch_active:
		_show_message("Fackel angezündet! Hirsche fliehen vor dem Licht.", 2.0)
	else:
		_show_message("Fackel ausgemacht.", 1.0)


func _on_action_pressed() -> void:
	# E-Taste: Kind retten → Items aufsammeln → Tier angreifen → Baum hacken
	if _try_rescue_child():
		return
	if _try_pickup_nearby():
		return
	_on_harvest_pressed()


const CHILD_COLORS: Array = [
	Color(0.85, 0.3, 0.25, 1),   # Rot
	Color(0.25, 0.5, 0.9, 1),    # Blau
	Color(0.9, 0.8, 0.2, 1),     # Gelb
	Color(0.9, 0.4, 0.7, 1),     # Rosa
]


func _spawn_lost_children() -> void:
	# 4 Kinder in den Ecken der Unterwelt, jedes mit eigener Hemdfarbe
	# Bereits gerettete Kinder (aus dem Speicherstand) sitzen am Lagerfeuer
	var child_script: GDScript = preload("res://scripts/lost_child.gd")
	var spots: Array = [
		Vector3(-29.0, -100.0, -29.0),
		Vector3(30.0, -100.0, -27.0),
		Vector3(-27.0, -100.0, 29.0),
		Vector3(29.0, -100.0, 30.0),
	]
	for i in range(4):
		if i in rescued_spots:
			_spawn_saved_child(i)
			continue
		var lost_child := Node3D.new()
		lost_child.set_script(child_script)
		lost_child.name = "VermisstesKind%d" % i
		lost_child.position = spots[i]
		lost_child.shirt_color = CHILD_COLORS[i]
		add_child(lost_child)
		lost_child.rescued.connect(_on_child_rescued.bind(i))


func _spawn_saved_child(spot_index: int) -> void:
	# Gerettetes Kind sitzt am Lagerfeuer
	var child_script: GDScript = preload("res://scripts/lost_child.gd")
	var saved_spots: Array = [
		Vector3(2.5, 0, 2.0), Vector3(-2.5, 0, 2.0),
		Vector3(2.0, 0, -2.5), Vector3(-2.0, 0, -2.5),
	]
	var saved_child := Node3D.new()
	saved_child.set_script(child_script)
	saved_child.name = "GerettetesKind%d" % spot_index
	saved_child.saved_mode = true
	saved_child.shirt_color = CHILD_COLORS[spot_index]
	saved_child.position = saved_spots[spot_index % 4]
	add_child(saved_child)


func _try_rescue_child() -> bool:
	var lost_children: Array = get_tree().get_nodes_in_group("lost_child")
	for lost_child in lost_children:
		if lost_child.has_method("try_rescue"):
			if lost_child.try_rescue(player):
				return true
	return false


func _on_child_rescued(spot_index: int) -> void:
	children_rescued += 1
	rescued_spots.append(spot_index)
	total_nights = max(total_nights - NIGHTS_PER_CHILD, 1)

	_spawn_saved_child(spot_index)
	if save_system:
		save_system.save_game()

	if children_rescued >= 4:
		_show_message("ALLE 4 KINDER GERETTET! Nur noch %d Nächte überleben!" % total_nights, 6.0)
	else:
		_show_message("Kind gerettet! (%d/4) Es wartet am Lagerfeuer. Nur noch %d Nächte!" % [children_rescued, total_nights], 4.0)


func _spawn_animals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77  # Fester Seed für konsistente Positionen

	# 6 Hasen dicht am Lagerfeuer, aber außerhalb der sicheren Zone (8m)
	var rabbit_script: GDScript = preload("res://scripts/rabbit_animal.gd")
	for i in range(6):
		var rabbit := CharacterBody3D.new()
		rabbit.set_script(rabbit_script)
		rabbit.name = "Hase%d" % i
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(9.0, 13.0)
		rabbit.position = Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
		add_child(rabbit)

	# 3 Wölfe weiter draußen (nicht direkt am Camp)
	var wolf_script: GDScript = preload("res://scripts/wolf_enemy.gd")
	for i in range(3):
		var wolf := CharacterBody3D.new()
		wolf.set_script(wolf_script)
		wolf.name = "Wolf%d" % i
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(30.0, 60.0)
		wolf.position = Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
		add_child(wolf)


func _on_harvest_pressed() -> void:
	if player.axe_active:
		# Erst versuchen ein Tier anzugreifen
		var animal_result: Dictionary = player.try_attack_animal()
		if animal_result.attacked:
			if game_sounds:
				game_sounds.play_chop_sound()
			if animal_result.killed:
				_show_message("%s erlegt! Sammle die Beute auf! [E]" % animal_result.animal_name, 2.0)
			return

		var result: Dictionary = player.try_chop_tree()
		if result.chopped:
			# Hack-Sound abspielen
			if game_sounds:
				game_sounds.play_chop_sound()
			if result.felled:
				_show_message("Baum gefällt! Sammle die Säcke auf! [E]", 2.0)
				if game_sounds:
					game_sounds.play_fell_sound()
			# Kein "Hack!" Text bei jedem Hieb – Sound reicht
		else:
			if player.chop_cooldown > 0:
				pass
			else:
				_show_message("Kein Baum in Reichweite.", 1.5)
	else:
		_show_message("Ziehe zuerst deine Axt! [Q]", 1.5)


func _on_pickup_pressed() -> void:
	_try_pickup_nearby()


func _try_pickup_nearby() -> bool:
	# Alle gedroppten Items durchsuchen
	var items: Array = get_tree().get_nodes_in_group("dropped_item")
	# Auch ohne Gruppe: alle Area3D-Kinder der Szene prüfen
	if items.size() == 0:
		items = _find_dropped_items()

	for item in items:
		if item.has_method("try_pickup"):
			var picked: bool = item.try_pickup(player)
			if picked:
				if game_sounds:
					game_sounds.play_pickup_sound()
				_show_message("+1 aufgesammelt!", 1.0)
				return true
	return false


func _find_dropped_items() -> Array:
	var result: Array = []
	for child in get_tree().current_scene.get_children():
		if child.has_method("try_pickup"):
			result.append(child)
	return result


func _on_sapling_changed(new_count: int) -> void:
	sapling_label.text = "Setzlinge: %d" % new_count
	plant_button.visible = new_count > 0


func _on_plant_pressed() -> void:
	if player.plant_sapling():
		_show_message("Setzling gepflanzt! Er wird langsam wachsen.", 2.0)
		if game_sounds:
			game_sounds.play_pickup_sound()
	else:
		_show_message("Keine Setzlinge vorhanden.", 1.5)


func _on_drop_pressed() -> void:
	var drop_idx: int = 0
	if inventory_bar:
		drop_idx = inventory_bar.get_selected_index()
	var dropped: String = player.drop_item_at(drop_idx)
	if dropped != "":
		var name_de: String = "Holz"
		match dropped:
			"sapling": name_de = "Setzling"
			"torch": name_de = "Fackel"
		_show_message("%s abgelegt!" % name_de, 1.0)
		if game_sounds:
			game_sounds.play_pickup_sound()
	else:
		_show_message("Inventar ist leer.", 1.0)


func _on_inventory_changed() -> void:
	_update_inventory_label()
	if inventory_bar:
		inventory_bar.set_inventory(player.inventory)
		inventory_bar.update_display()


func _on_axe_toggle_pressed() -> void:
	player.toggle_axe()
	if player.axe_active:
		axe_button.text = "Axt wegstecken"
	else:
		axe_button.text = "Axt ziehen"


func _make_touch_button(text: String, offset_y: float) -> Button:
	# Button im rechten Stapel (wie die bestehenden HUD-Buttons aus der Szene)
	var btn := Button.new()
	btn.text = text
	btn.visible = false
	btn.anchor_left = 1.0
	btn.anchor_top = 1.0
	btn.anchor_right = 1.0
	btn.anchor_bottom = 1.0
	btn.offset_left = -220.0
	btn.offset_top = offset_y
	btn.offset_right = -20.0
	btn.offset_bottom = offset_y + 44.0
	btn.add_theme_font_size_override("font_size", 15)
	hud.add_child(btn)
	return btn


func _create_touch_buttons() -> void:
	# Rechter Stapel: über den bestehenden Buttons (Plant endet bei -300)
	torch_button = _make_touch_button("Fackel an/aus [T]", -360.0)
	torch_button.pressed.connect(_on_torch_toggle_pressed)

	cook_button = _make_touch_button("Braten [C]", -420.0)
	cook_button.pressed.connect(_on_cook_pressed)

	eat_button = _make_touch_button("Essen [V]", -480.0)
	eat_button.pressed.connect(_on_eat_pressed)

	place_button = _make_touch_button("Platzieren [P]", -540.0)
	place_button.pressed.connect(_on_place_pressed)

	# Werkbank-Button: unten Mitte, über der Hotbar (nur in Werkbank-Nähe)
	workbench_button = Button.new()
	workbench_button.text = "Werkbank öffnen [B]"
	workbench_button.visible = false
	workbench_button.anchor_left = 0.5
	workbench_button.anchor_right = 0.5
	workbench_button.anchor_top = 1.0
	workbench_button.anchor_bottom = 1.0
	workbench_button.offset_left = -110.0
	workbench_button.offset_right = 110.0
	workbench_button.offset_top = -150.0
	workbench_button.offset_bottom = -106.0
	workbench_button.add_theme_font_size_override("font_size", 15)
	workbench_button.pressed.connect(_on_workbench_button_pressed)
	hud.add_child(workbench_button)

	# Hilfe-Button: oben rechts, immer sichtbar
	help_button = Button.new()
	help_button.text = "?"
	help_button.anchor_left = 1.0
	help_button.anchor_right = 1.0
	help_button.offset_left = -64.0
	help_button.offset_top = 16.0
	help_button.offset_right = -16.0
	help_button.offset_bottom = 64.0
	help_button.add_theme_font_size_override("font_size", 24)
	help_button.pressed.connect(_on_help_button_pressed)
	hud.add_child(help_button)


func _on_workbench_button_pressed() -> void:
	if workbench_menu:
		workbench_menu.toggle_menu()


func _on_help_button_pressed() -> void:
	if help_menu:
		help_menu.visible = not help_menu.visible


func _update_action_buttons() -> void:
	# Hack-Button: sichtbar wenn Baum in der Nähe und Axt aktiv
	var near_tree := false
	var trees := get_tree().get_nodes_in_group("tree")
	for tree in trees:
		if tree.has_method("chop") and not tree.is_harvested:
			var distance: float = player.global_position.distance_to(tree.global_position)
			if distance < 5.0:
				near_tree = true
				break
	harvest_button.visible = near_tree and player.axe_active
	harvest_button.text = "Baum hacken [E]"

	# Pickup-Button: sichtbar wenn Items in der Nähe
	var near_item := false
	var items: Array = _find_dropped_items()
	for item in items:
		var dist: float = player.global_position.distance_to(item.global_position)
		if dist < 3.0:
			near_item = true
			break
	pickup_button.visible = near_item

	# Drop-Button: sichtbar wenn Inventar nicht leer
	drop_button.visible = player.inventory.size() > 0

	# Fackel-Button: sichtbar wenn der Spieler eine Fackel hat
	if torch_button:
		torch_button.visible = player.has_torch
		torch_button.text = "Fackel aus [T]" if player.torch_active else "Fackel an [T]"

	# Braten-Button: am Lagerfeuer mit rohem Fleisch
	if cook_button:
		var has_raw: bool = false
		for item in player.inventory:
			if item in COOK_MAP:
				has_raw = true
				break
		cook_button.visible = player.is_near_campfire and has_raw

	# Essen-Button: gebratenes Fleisch dabei und nicht volle HP
	if eat_button:
		var has_food: bool = false
		for item in player.inventory:
			if item in FOOD_HEAL:
				has_food = true
				break
		eat_button.visible = has_food and player.hp < player.max_hp

	# Platzieren-Button: ausgewähltes Item ist platzierbar
	if place_button and inventory_bar:
		var sel_item: String = inventory_bar.get_selected_item()
		place_button.visible = sel_item in ["bed", "fence", "wall", "chest"]

	# Werkbank-Button: in Werkbank-Nähe
	if workbench_button and workbench_menu:
		workbench_button.visible = workbench_menu.is_near_workbench and not workbench_menu.visible


func _update_hp_bar(hp: float) -> void:
	if hp_bar:
		hp_bar.value = hp


func _update_wood_label(count: int) -> void:
	if wood_label:
		wood_label.text = "Holz: %d" % count


func _update_inventory_label() -> void:
	if not inventory_label:
		return
	if player.inventory.size() == 0:
		inventory_label.text = ""
		return

	# Nächstes Item anzeigen (FIFO – das was als nächstes rausfliegt)
	var next_item: String = player.inventory[0]
	var next_de: String = "Holz"
	match next_item:
		"sapling": next_de = "Setzling"
		"torch": next_de = "Fackel"
	inventory_label.text = "Inventar (%d): Nächstes: %s" % [player.inventory.size(), next_de]


func _on_place_pressed() -> void:
	var place_idx: int = 0
	if inventory_bar:
		place_idx = inventory_bar.get_selected_index()
	var placed: String = player.place_item_at(place_idx)
	if placed != "":
		var name_de: String = placed
		match placed:
			"bed": name_de = "Bett"
			"fence": name_de = "Zaun"
			"wall": name_de = "Holzwand"
			"chest": name_de = "Truhe"
		_show_message("%s platziert!" % name_de, 2.0)
		if game_sounds:
			game_sounds.play_pickup_sound()
	else:
		# Prüfe ob ausgewähltes Item überhaupt platzierbar ist
		if inventory_bar:
			var sel: String = inventory_bar.get_selected_item()
			if sel == "":
				_show_message("Inventar ist leer.", 1.0)
			else:
				_show_message("Dieses Item kann nicht platziert werden.", 1.0)


func _on_workbench_entered() -> void:
	if workbench_menu:
		workbench_menu.set_near_workbench(true)
	_show_message("Werkbank! Drücke B zum Bauen.", 2.0)


func _on_workbench_exited() -> void:
	if workbench_menu:
		workbench_menu.set_near_workbench(false)


func _on_workbench_crafted(item_type: String) -> void:
	var name_de: String = item_type
	match item_type:
		"bed": name_de = "Bett"
		"fence": name_de = "Zaun"
		"wall": name_de = "Holzwand"
		"chest": name_de = "Truhe"
		"torch": name_de = "Fackel"
		"iron_axe": name_de = "Eisenaxt"
	_show_message("%s gebaut!" % name_de, 2.0)
	if game_sounds:
		game_sounds.play_pickup_sound()


# Rohes Fleisch → gebratene Variante (am Lagerfeuer mit C)
const COOK_MAP: Dictionary = {
	"meat_small": "cooked_meat_small",
	"meat_chunk": "cooked_meat_chunk",
	"steak": "cooked_steak",
}
# Gebratenes Fleisch → HP-Heilung (mit V essen)
const FOOD_HEAL: Dictionary = {
	"cooked_meat_small": 15.0,
	"cooked_meat_chunk": 30.0,
	"cooked_steak": 50.0,
}
const ITEM_NAMES_DE: Dictionary = {
	"meat_small": "Fleischstückchen",
	"meat_chunk": "Fleischklumpen",
	"steak": "Steak",
	"cooked_meat_small": "Gebratenes Fleischstückchen",
	"cooked_meat_chunk": "Gebratener Fleischklumpen",
	"cooked_steak": "Gebratenes Steak",
}


func _on_cook_pressed() -> void:
	if not player.is_near_campfire:
		_show_message("Zum Braten musst du am Lagerfeuer sein!", 2.0)
		return

	# Erst das ausgewählte Item probieren, sonst das erste rohe Fleisch
	var cook_idx: int = -1
	if inventory_bar:
		var sel: int = inventory_bar.get_selected_index()
		if sel >= 0 and sel < player.inventory.size() and player.inventory[sel] in COOK_MAP:
			cook_idx = sel
	if cook_idx == -1:
		for i in range(player.inventory.size()):
			if player.inventory[i] in COOK_MAP:
				cook_idx = i
				break
	if cook_idx == -1:
		_show_message("Du hast kein rohes Fleisch zum Braten.", 2.0)
		return

	var raw: String = player.inventory[cook_idx]
	var cooked: String = COOK_MAP[raw]
	player.inventory[cook_idx] = cooked
	player.inventory_changed.emit()
	if game_sounds:
		game_sounds.play_pickup_sound()
	_show_message("%s gebraten! Mit V essen (+%d HP)" % [ITEM_NAMES_DE[raw], int(FOOD_HEAL[cooked])], 2.5)


func _on_eat_pressed() -> void:
	# Erst das ausgewählte Item probieren, sonst das erste gebratene Fleisch
	var eat_idx: int = -1
	if inventory_bar:
		var sel: int = inventory_bar.get_selected_index()
		if sel >= 0 and sel < player.inventory.size() and player.inventory[sel] in FOOD_HEAL:
			eat_idx = sel
	if eat_idx == -1:
		for i in range(player.inventory.size()):
			if player.inventory[i] in FOOD_HEAL:
				eat_idx = i
				break
	if eat_idx == -1:
		_show_message("Du hast nichts Gebratenes zum Essen. (C = Braten am Feuer)", 2.0)
		return

	if player.hp >= player.max_hp:
		_show_message("Du bist schon bei voller Gesundheit!", 2.0)
		return

	var food: String = player.inventory[eat_idx]
	player.inventory.remove_at(eat_idx)
	player.inventory_changed.emit()
	player.heal(FOOD_HEAL[food])
	if game_sounds:
		game_sounds.play_pickup_sound()
	_show_message("%s gegessen! +%d HP" % [ITEM_NAMES_DE[food], int(FOOD_HEAL[food])], 2.0)


func _on_portal_teleported(message: String) -> void:
	if message != "":
		_show_message(message, 3.0)


func _show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_timer = duration

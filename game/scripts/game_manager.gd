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


func _ready() -> void:
	# Landschaft generieren
	var landscape_script: GDScript = preload("res://scripts/landscape_generator.gd")
	var landscape := Node3D.new()
	landscape.set_script(landscape_script)
	landscape.name = "LandscapeGenerator"
	add_child(landscape)

	# Höhle spawnen – feste Position, Eingang zeigt in +Z (zum Spieler)
	var cave_script: GDScript = preload("res://scripts/cave.gd")
	var cave := Node3D.new()
	cave.set_script(cave_script)
	cave.name = "Cave"
	cave.position = Vector3(40.0, 0, -30.0)  # Nordöstlich vom Camp
	add_child(cave)

	# Loch im Boden für die Höhle
	_cut_ground_hole(cave.position)

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
		_show_message("Du hast alle 99 Nächte überlebt! GEWONNEN!", 10.0)
	else:
		_show_message("Tag %d – der Hirsch zieht sich zurück." % day, 3.0)
	deer.deactivate()
	deer_active = false


func _on_time_changed(time: float, day: int) -> void:
	day_label.text = "Tag %d / %d" % [day, total_nights]
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
	# E-Taste: Erst versuchen Items aufzusammeln, dann Baum hacken
	if _try_pickup_nearby():
		return
	_on_harvest_pressed()


func _on_harvest_pressed() -> void:
	if player.axe_active:
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


func _cut_ground_hole(cave_pos: Vector3) -> void:
	# Originalen Boden entfernen und durch Kacheln mit Loch ersetzen
	var ground_node: Node = get_node_or_null("Ground")
	if not ground_node:
		return

	var ground_mat: Material = null
	for child in ground_node.get_children():
		if child is MeshInstance3D:
			ground_mat = child.get_surface_override_material(0)
			break

	ground_node.queue_free()

	# Loch: Rechteck um den Höhlenbereich (Tunnel geht in -Z Richtung)
	# cave_pos ist der Eingang, Tunnel geht 20m in -Z, Raum nochmal 14m
	# Loch für Rampe + 3 Räume
	# Rampe: 5m breit, ab cave_pos.z -1 bis -18
	var tunnel_x1: float = cave_pos.x - 3.5
	var tunnel_x2: float = cave_pos.x + 3.5
	var tunnel_z2: float = cave_pos.z - 1.0
	var tunnel_z1: float = cave_pos.z - 20.0

	# Räume: Raum1 unter Rampe, Raum2 rechts versetzt (+20x), Raum3 noch weiter hinten
	var room_x1: float = cave_pos.x - 9.0
	var room_x2: float = cave_pos.x + 30.0  # Raum 2 ist ~20m rechts
	var room_z2: float = cave_pos.z - 18.0
	var room_z1: float = cave_pos.z - 50.0  # Raum 3 ist weit hinten

	# Boden in 5x5 Kacheln für mehr Präzision
	var tile: float = 5.0
	for tx in range(40):
		for tz in range(40):
			var x: float = -100.0 + float(tx) * tile + tile / 2.0
			var z: float = -100.0 + float(tz) * tile + tile / 2.0

			# Liegt diese Kachel im Tunnel-Loch?
			var in_tunnel: bool = (x + tile / 2.0 > tunnel_x1 and x - tile / 2.0 < tunnel_x2 \
				and z + tile / 2.0 > tunnel_z1 and z - tile / 2.0 < tunnel_z2)
			# Liegt diese Kachel im Raum-Loch?
			var in_room: bool = (x + tile / 2.0 > room_x1 and x - tile / 2.0 < room_x2 \
				and z + tile / 2.0 > room_z1 and z - tile / 2.0 < room_z2)
			if in_tunnel or in_room:
				continue

			var tb := StaticBody3D.new()
			add_child(tb)

			var tc := CollisionShape3D.new()
			var ts := BoxShape3D.new()
			ts.size = Vector3(tile, 0.2, tile)
			tc.shape = ts
			tc.position = Vector3(x, -0.1, z)
			tb.add_child(tc)

			var tm := MeshInstance3D.new()
			var tmm := BoxMesh.new()
			tmm.size = Vector3(tile, 0.2, tile)
			tm.mesh = tmm
			if ground_mat:
				tm.material_override = ground_mat
			tm.position = Vector3(x, -0.1, z)
			tb.add_child(tm)


func _show_message(text: String, duration: float = 3.0) -> void:
	message_label.text = text
	message_timer = duration

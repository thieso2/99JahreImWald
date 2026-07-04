extends PanelContainer

# Cheat-Menü für Entwickler – F1 zum Öffnen/Schließen

var player: CharacterBody3D = null
var deer: CharacterBody3D = null
var camera_controller: Node3D = null
var viewing_deer: bool = false

var btn_wood: Button
var btn_wood_10: Button
var btn_sapling: Button
var btn_torch: Button
var btn_axe_stone: Button
var btn_axe_iron: Button
var btn_axe_steel: Button
var btn_heal: Button
var btn_kill: Button

func _ready() -> void:
	visible = false

	# Panel-Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.border_color = Color(0.8, 0.2, 0.2, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	add_theme_stylebox_override("panel", style)

	# Layout
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "--- CHEAT MENU (F1) ---"
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	title.add_theme_font_size_override("font_size", 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Items
	btn_wood = _add_button(vbox, "+1 Holz")
	btn_wood.pressed.connect(_give_wood)
	btn_wood_10 = _add_button(vbox, "+10 Holz")
	btn_wood_10.pressed.connect(_give_wood_10)
	btn_sapling = _add_button(vbox, "+1 Setzling")
	btn_sapling.pressed.connect(_give_sapling)
	btn_torch = _add_button(vbox, "Fackel geben")
	btn_torch.pressed.connect(_give_torch)
	var btn_bed := _add_button(vbox, "+1 Bett")
	btn_bed.pressed.connect(_give_item.bind("bed"))
	var btn_fence := _add_button(vbox, "+1 Zaun")
	btn_fence.pressed.connect(_give_item.bind("fence"))
	var btn_wall := _add_button(vbox, "+1 Wand")
	btn_wall.pressed.connect(_give_item.bind("wall"))
	var btn_chest := _add_button(vbox, "+1 Truhe")
	btn_chest.pressed.connect(_give_item.bind("chest"))

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Äxte
	btn_axe_stone = _add_button(vbox, "Steinaxt")
	btn_axe_stone.pressed.connect(_give_axe_stone)
	btn_axe_iron = _add_button(vbox, "Eisenaxt")
	btn_axe_iron.pressed.connect(_give_axe_iron)
	btn_axe_steel = _add_button(vbox, "Stahlaxt")
	btn_axe_steel.pressed.connect(_give_axe_steel)

	# Separator
	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Spieler
	btn_heal = _add_button(vbox, "Voll heilen")
	btn_heal.pressed.connect(_heal_player)
	btn_kill = _add_button(vbox, "Spieler töten")
	btn_kill.pressed.connect(_kill_player)

	# Separator
	var sep3 := HSeparator.new()
	vbox.add_child(sep3)

	# Debug
	var btn_view_deer := _add_button(vbox, "Hirsch anschauen")
	btn_view_deer.pressed.connect(_toggle_view_deer)
	var btn_spawn_deer := _add_button(vbox, "Hirsch spawnen")
	btn_spawn_deer.pressed.connect(_spawn_deer_nearby)
	var btn_deer_normal := _add_button(vbox, "Normaler Hirsch")
	btn_deer_normal.pressed.connect(_set_deer_normal)
	var btn_deer_hungry := _add_button(vbox, "Hungriger Hirsch")
	btn_deer_hungry.pressed.connect(_set_deer_hungry)
	var btn_tp_portal := _add_button(vbox, "Zum Portal teleportieren")
	btn_tp_portal.pressed.connect(_teleport_to_portal)
	var btn_tp_underworld := _add_button(vbox, "In die Unterwelt teleportieren")
	btn_tp_underworld.pressed.connect(_teleport_to_underworld)

	# Position: oben links
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	offset_left = 10
	offset_top = 10
	offset_right = 220
	offset_bottom = 400


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			visible = not visible
			get_viewport().set_input_as_handled()


func _add_button(parent: Control, text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 14)
	parent.add_child(btn)
	return btn


func _give_wood() -> void:
	if player:
		player.add_wood(1)

func _give_wood_10() -> void:
	if player:
		player.add_wood(10)

func _give_sapling() -> void:
	if player:
		player.add_sapling(1)

func _give_torch() -> void:
	if player:
		player.has_torch = true
		player.inventory.append("torch")
		player.inventory_changed.emit()

func _give_item(item_type: String) -> void:
	if player:
		player.inventory.append(item_type)
		player.inventory_changed.emit()


func _give_axe_stone() -> void:
	if player:
		player.give_axe(0)

func _give_axe_iron() -> void:
	if player:
		player.give_axe(1)

func _give_axe_steel() -> void:
	if player:
		player.give_axe(2)

func _heal_player() -> void:
	if player:
		player.heal(player.max_hp)

func _kill_player() -> void:
	if player:
		player.take_damage(player.hp + 1)


func _toggle_view_deer() -> void:
	if not deer or not camera_controller:
		return
	viewing_deer = not viewing_deer
	if viewing_deer:
		# Hirsch sichtbar machen und vor den Spieler setzen
		deer.visible = true
		deer.set_physics_process(false)
		var forward := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
		deer.global_position = player.global_position + forward * 5.0
		deer.global_position.y = 0.0
		# Hirsch zum Spieler drehen
		var dir: Vector3 = player.global_position - deer.global_position
		deer.rotation.y = atan2(dir.x, dir.z)
		# Kamera auf Hirsch richten
		camera_controller.target = deer
	else:
		# Zurück zum Spieler
		camera_controller.target = player
		deer.visible = false


func _set_deer_normal() -> void:
	if deer and deer.has_method("set_hungry"):
		deer.set_hungry(false)


func _set_deer_hungry() -> void:
	if deer and deer.has_method("set_hungry"):
		deer.set_hungry(true)


func _teleport_to_portal() -> void:
	if not player:
		return
	var portal: Node = player.get_tree().current_scene.find_child("Portal", false, false)
	if portal:
		player.global_position = portal.global_position + Vector3(0, 1, 5)
	else:
		player.global_position = Vector3(40, 1, -25)


func _teleport_to_underworld() -> void:
	if not player:
		return
	var underworld: Node = player.get_tree().current_scene.find_child("UndergroundWorld", false, false)
	if underworld:
		player.global_position = underworld.global_position + Vector3(0, 1.0, 6.0)
	else:
		player.global_position = Vector3(0, -99.0, 6.0)


func _spawn_deer_nearby() -> void:
	if not deer or not player:
		return
	deer.visible = true
	deer.set_physics_process(true)
	deer.current_state = 1  # ROAMING
	var forward := Vector3(sin(player.rotation.y), 0, cos(player.rotation.y))
	deer.global_position = player.global_position + forward * 8.0
	deer.global_position.y = 1.0

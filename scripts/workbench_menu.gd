extends PanelContainer

# Werkbank-Menü: Crafting-Rezepte für Möbel und Ausrüstung
# Öffnet sich mit B-Taste wenn Spieler in der Nähe der Werkbank ist

var player: CharacterBody3D = null
var is_near_workbench: bool = false

# Crafting-Rezepte: [Name, Beschreibung, Kosten {item: anzahl}, Ergebnis-Item]
var recipes: Array = [
	{"name": "Bett", "desc": "Zum Schlafen (spart Zeit)", "cost": {"wood": 5}, "result": "bed"},
	{"name": "Zaun", "desc": "Hält Feinde ab", "cost": {"wood": 3}, "result": "fence"},
	{"name": "Holzwand", "desc": "Schutz vor Wind und Feinden", "cost": {"wood": 8}, "result": "wall"},
	{"name": "Truhe", "desc": "Items lagern", "cost": {"wood": 4}, "result": "chest"},
	{"name": "Fackel", "desc": "Licht in der Dunkelheit", "cost": {"wood": 3}, "result": "torch"},
	{"name": "Eisenaxt", "desc": "Stärkere Axt", "cost": {"wood": 10}, "result": "iron_axe"},
]

var recipe_buttons: Array = []

signal item_crafted(item_type: String)


func _ready() -> void:
	visible = false

	# Panel-Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.08, 0.05, 0.92)
	style.border_color = Color(0.6, 0.4, 0.2, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)

	# ScrollContainer für viele Rezepte
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 350)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "=== WERKBANK [B] ==="
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3, 1))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Baue Gegenstände aus Holz"
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color(0.7, 0.6, 0.5, 1))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Rezepte
	for i in range(recipes.size()):
		var recipe: Dictionary = recipes[i]
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		vbox.add_child(hbox)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_label := Label.new()
		name_label.text = recipe.name
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8, 1))
		info.add_child(name_label)

		var desc_label := Label.new()
		desc_label.text = recipe.desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.5, 1))
		info.add_child(desc_label)

		# Kosten anzeigen
		var cost_text: String = ""
		var cost: Dictionary = recipe.cost
		for item_key in cost:
			var amount: int = cost[item_key]
			var item_de: String = "Holz"
			match item_key:
				"sapling": item_de = "Setzling"
				"torch": item_de = "Fackel"
			cost_text += "%d %s  " % [amount, item_de]

		var cost_label := Label.new()
		cost_label.text = cost_text
		cost_label.add_theme_font_size_override("font_size", 11)
		cost_label.add_theme_color_override("font_color", Color(0.8, 0.6, 0.3, 1))
		info.add_child(cost_label)

		hbox.add_child(info)

		var btn := Button.new()
		btn.text = "Bauen"
		btn.add_theme_font_size_override("font_size", 13)
		btn.custom_minimum_size = Vector2(70, 40)
		btn.pressed.connect(_on_craft_pressed.bind(i))
		hbox.add_child(btn)
		recipe_buttons.append(btn)

	# Position: Mitte des Bildschirms
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -155
	offset_right = 155
	offset_top = -200
	offset_bottom = 200


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			if is_near_workbench:
				visible = not visible
				if visible:
					_update_buttons()
				get_viewport().set_input_as_handled()
			elif visible:
				visible = false
				get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		_update_buttons()


func toggle_menu() -> void:
	# Für den Touch-Button (gleiche Logik wie die B-Taste)
	if is_near_workbench:
		visible = not visible
		if visible:
			_update_buttons()
	elif visible:
		visible = false


func set_near_workbench(near: bool) -> void:
	is_near_workbench = near
	if not near and visible:
		visible = false


func _update_buttons() -> void:
	if not player:
		return
	for i in range(recipes.size()):
		var recipe: Dictionary = recipes[i]
		var can_craft: bool = _can_afford(recipe.cost)
		recipe_buttons[i].disabled = not can_craft


func _can_afford(cost: Dictionary) -> bool:
	if not player:
		return false
	for item_key in cost:
		var needed: int = cost[item_key]
		var have: int = 0
		for inv_item in player.inventory:
			if inv_item == item_key:
				have += 1
		if have < needed:
			return false
	return true


func _remove_items(cost: Dictionary) -> void:
	for item_key in cost:
		var to_remove: int = cost[item_key]
		var removed: int = 0
		var idx: int = 0
		while idx < player.inventory.size() and removed < to_remove:
			if player.inventory[idx] == item_key:
				player.inventory.remove_at(idx)
				removed += 1
				match item_key:
					"wood":
						player.wood_count -= 1
						player.wood_changed.emit(player.wood_count)
					"sapling":
						player.sapling_count -= 1
						player.sapling_changed.emit(player.sapling_count)
			else:
				idx += 1
		player.inventory_changed.emit()


func _on_craft_pressed(recipe_idx: int) -> void:
	var recipe: Dictionary = recipes[recipe_idx]
	if not _can_afford(recipe.cost):
		return

	_remove_items(recipe.cost)

	var result: String = recipe.result
	match result:
		"torch":
			player.has_torch = true
			player.inventory.append("torch")
			player.inventory_changed.emit()
		"iron_axe":
			player.give_axe(1)
		_:
			# Andere Items ins Inventar legen
			player.inventory.append(result)
			player.inventory_changed.emit()

	item_crafted.emit(result)
	_update_buttons()

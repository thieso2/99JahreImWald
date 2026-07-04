extends Control

# Inventarleiste am unteren Bildschirmrand (Minecraft-Style)
# Zeigt alle Items als Slots, aktiver Slot ist hervorgehoben
# Tab = nächster Slot, Shift+Tab = vorheriger Slot

const SLOT_SIZE: float = 60.0
const SLOT_MARGIN: float = 4.0
const MAX_VISIBLE_SLOTS: int = 9
const BAR_PADDING: float = 8.0

var selected_index: int = 0
var inventory_ref: Array = []  # Referenz auf Spieler-Inventar

# Visuals
var slot_containers: Array = []  # Array von Control-Nodes
var slot_bg_color := Color(0.15, 0.15, 0.15, 0.7)
var slot_selected_color := Color(0.4, 0.4, 0.1, 0.85)
var slot_border_color := Color(0.5, 0.5, 0.5, 0.6)
var slot_selected_border := Color(1.0, 0.9, 0.3, 1.0)

# Materialfarben für Icons
var wood_color := Color(0.5, 0.3, 0.12, 1)
var sapling_color := Color(0.2, 0.55, 0.15, 1)


func _ready() -> void:
	# Bar zentriert am unteren Bildschirmrand
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0

	_rebuild_slots()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			if event.shift_pressed:
				_select_previous()
			else:
				_select_next()
			get_viewport().set_input_as_handled()
		# Nummerntasten 1-9 zum direkten Slot-Wechsel
		elif event.keycode >= KEY_1 and event.keycode <= KEY_9:
			var slot_num: int = event.keycode - KEY_1  # 0-basiert
			if slot_num < inventory_ref.size():
				selected_index = slot_num
				_rebuild_slots()
				get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	# Slot antippen/anklicken zum Auswählen (Touch + Maus)
	var tap_pos: Vector2 = Vector2.ZERO
	var tapped: bool = false
	if event is InputEventScreenTouch and event.pressed:
		tap_pos = event.position
		tapped = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = event.position
		tapped = true
	if not tapped or inventory_ref.size() == 0:
		return

	var slot: int = int((tap_pos.x - BAR_PADDING) / (SLOT_SIZE + SLOT_MARGIN))
	var visible_count: int = min(inventory_ref.size(), MAX_VISIBLE_SLOTS)
	if slot < 0 or slot >= visible_count:
		return
	var inv_idx: int = _get_start_index() + slot
	if inv_idx < inventory_ref.size():
		selected_index = inv_idx
		_rebuild_slots()
		accept_event()


func _get_start_index() -> int:
	if inventory_ref.size() <= MAX_VISIBLE_SLOTS:
		return 0
	return clampi(selected_index - MAX_VISIBLE_SLOTS / 2, 0, inventory_ref.size() - MAX_VISIBLE_SLOTS)


func set_inventory(inv: Array) -> void:
	inventory_ref = inv
	_rebuild_slots()


func update_display() -> void:
	_rebuild_slots()


func get_selected_index() -> int:
	return selected_index


func get_selected_item() -> String:
	if selected_index >= 0 and selected_index < inventory_ref.size():
		return inventory_ref[selected_index]
	return ""


func _select_next() -> void:
	if inventory_ref.size() == 0:
		selected_index = 0
		return
	selected_index = (selected_index + 1) % inventory_ref.size()
	_rebuild_slots()


func _select_previous() -> void:
	if inventory_ref.size() == 0:
		selected_index = 0
		return
	selected_index -= 1
	if selected_index < 0:
		selected_index = inventory_ref.size() - 1
	_rebuild_slots()


func _rebuild_slots() -> void:
	# Alte Slots entfernen
	for slot in slot_containers:
		if is_instance_valid(slot):
			slot.queue_free()
	slot_containers.clear()

	var item_count: int = inventory_ref.size()
	if item_count == 0:
		# Leere Inventarleiste mit 1 leeren Slot zeigen
		_build_empty_bar()
		_ignore_child_mouse()
		return

	# Clamp selected_index
	if selected_index >= item_count:
		selected_index = max(0, item_count - 1)

	# Sichtbare Slots berechnen (Fenster um selected_index)
	var visible_count: int = min(item_count, MAX_VISIBLE_SLOTS)
	var start_idx: int = 0
	if item_count > MAX_VISIBLE_SLOTS:
		start_idx = clampi(selected_index - MAX_VISIBLE_SLOTS / 2, 0, item_count - MAX_VISIBLE_SLOTS)

	var total_width: float = visible_count * (SLOT_SIZE + SLOT_MARGIN) - SLOT_MARGIN + BAR_PADDING * 2.0
	var bar_height: float = SLOT_SIZE + BAR_PADDING * 2.0

	# Control-Größe setzen
	offset_left = -total_width / 2.0
	offset_right = total_width / 2.0
	offset_top = -bar_height - 10.0
	offset_bottom = -10.0

	# Hintergrund
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.08, 0.6)
	bg.position = Vector2.ZERO
	bg.size = Vector2(total_width, bar_height)
	add_child(bg)
	slot_containers.append(bg)

	# Slots zeichnen
	for i in range(visible_count):
		var inv_idx: int = start_idx + i
		var is_selected: bool = inv_idx == selected_index

		var slot_x: float = BAR_PADDING + i * (SLOT_SIZE + SLOT_MARGIN)
		var slot_y: float = BAR_PADDING

		# Slot-Hintergrund
		var slot_bg := ColorRect.new()
		slot_bg.color = slot_selected_color if is_selected else slot_bg_color
		slot_bg.position = Vector2(slot_x, slot_y)
		slot_bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		add_child(slot_bg)
		slot_containers.append(slot_bg)

		# Rahmen (dünn) – 4 ColorRects als Rahmen
		_add_border(slot_x, slot_y, SLOT_SIZE, SLOT_SIZE,
			slot_selected_border if is_selected else slot_border_color)

		# Item-Icon
		if inv_idx < item_count:
			_add_item_icon(slot_x, slot_y, inventory_ref[inv_idx], is_selected)

		# Slot-Nummer
		var num_label := Label.new()
		num_label.text = str(inv_idx + 1)
		num_label.position = Vector2(slot_x + 2, slot_y + 1)
		num_label.add_theme_font_size_override("font_size", 10)
		num_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 0.5))
		add_child(num_label)
		slot_containers.append(num_label)

	_ignore_child_mouse()


func _ignore_child_mouse() -> void:
	# Kinder dürfen Taps nicht schlucken – die Leiste selbst wertet sie aus (_gui_input)
	for c in slot_containers:
		if is_instance_valid(c) and c is Control:
			c.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_empty_bar() -> void:
	var total_width: float = SLOT_SIZE + BAR_PADDING * 2.0
	var bar_height: float = SLOT_SIZE + BAR_PADDING * 2.0

	offset_left = -total_width / 2.0
	offset_right = total_width / 2.0
	offset_top = -bar_height - 10.0
	offset_bottom = -10.0

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.08, 0.6)
	bg.size = Vector2(total_width, bar_height)
	add_child(bg)
	slot_containers.append(bg)

	var slot_bg := ColorRect.new()
	slot_bg.color = slot_bg_color
	slot_bg.position = Vector2(BAR_PADDING, BAR_PADDING)
	slot_bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	add_child(slot_bg)
	slot_containers.append(slot_bg)

	_add_border(BAR_PADDING, BAR_PADDING, SLOT_SIZE, SLOT_SIZE, slot_border_color)


func _add_border(x: float, y: float, w: float, h: float, color: Color) -> void:
	var bw: float = 2.0  # Rahmenbreite
	# Oben
	var top := ColorRect.new()
	top.color = color
	top.position = Vector2(x, y)
	top.size = Vector2(w, bw)
	add_child(top)
	slot_containers.append(top)
	# Unten
	var bottom := ColorRect.new()
	bottom.color = color
	bottom.position = Vector2(x, y + h - bw)
	bottom.size = Vector2(w, bw)
	add_child(bottom)
	slot_containers.append(bottom)
	# Links
	var left := ColorRect.new()
	left.color = color
	left.position = Vector2(x, y)
	left.size = Vector2(bw, h)
	add_child(left)
	slot_containers.append(left)
	# Rechts
	var right := ColorRect.new()
	right.color = color
	right.position = Vector2(x + w - bw, y)
	right.size = Vector2(bw, h)
	add_child(right)
	slot_containers.append(right)


func _add_item_icon(slot_x: float, slot_y: float, item_type: String, is_selected: bool) -> void:
	var s: float = SLOT_SIZE  # Slot-Größe
	var cx: float = slot_x + s * 0.5  # Mitte X
	var cy: float = slot_y + s * 0.5  # Mitte Y
	var p: float = 6.0  # Padding

	match item_type:
		"wood":
			# Holzscheit: liegender Stamm mit Jahresringen
			_icon_rect(slot_x + p, cy - 4, s - p * 2, 12, Color(0.45, 0.28, 0.14))
			_icon_rect(slot_x + p, cy - 6, s - p * 2, 3, Color(0.55, 0.35, 0.18))
			# Jahresringe links
			_icon_rect(slot_x + p, cy - 8, 8, 20, Color(0.75, 0.55, 0.3))
			_icon_rect(slot_x + p + 2, cy - 6, 4, 16, Color(0.45, 0.28, 0.14))
			# Ast oben
			_icon_rect(cx + 4, cy - 12, 3, 10, Color(0.4, 0.25, 0.12))

		"sapling":
			# Setzling: Terrakotta-Topf + grüner Sprössling
			_icon_rect(cx - 10, cy + 6, 20, 14, Color(0.7, 0.4, 0.2))  # Topf
			_icon_rect(cx - 8, cy + 4, 16, 3, Color(0.3, 0.2, 0.12))   # Erde
			_icon_rect(cx - 1.5, cy - 10, 3, 20, Color(0.2, 0.5, 0.1)) # Stiel
			_icon_rect(cx - 10, cy - 14, 9, 6, Color(0.15, 0.7, 0.1))  # Blatt links
			_icon_rect(cx + 1, cy - 12, 9, 6, Color(0.15, 0.7, 0.1))   # Blatt rechts

		"torch":
			# Fackel: Stock + Wicklung + Flamme
			_icon_rect(cx - 2, cy - 4, 4, 28, Color(0.45, 0.28, 0.14))  # Stock
			_icon_rect(cx - 4, cy - 8, 8, 8, Color(0.2, 0.15, 0.1))     # Wicklung
			_icon_rect(cx - 6, cy - 18, 12, 12, Color(1.0, 0.6, 0.1))   # Flamme
			_icon_rect(cx - 4, cy - 16, 8, 8, Color(1.0, 0.9, 0.3))     # Flamme hell

		"bed":
			# Bett: Rahmen + rote Matratze + weißes Kissen
			_icon_rect(slot_x + p, cy + 4, s - p * 2, 6, Color(0.5, 0.3, 0.15))  # Rahmen
			_icon_rect(slot_x + p + 2, cy - 4, s - p * 2 - 4, 10, Color(0.8, 0.15, 0.12))  # Matratze
			_icon_rect(slot_x + s - p - 14, cy - 8, 12, 6, Color(1.0, 1.0, 0.9))  # Kissen
			_icon_rect(slot_x + p, cy - 2, s - p * 2 - 16, 6, Color(0.6, 0.1, 0.1))  # Decke
			_icon_rect(slot_x + s - p - 2, cy - 12, 4, 18, Color(0.5, 0.3, 0.15))  # Kopfteil

		"fence":
			# Zaun: 3 Pfosten + 2 Latten
			for i in range(3):
				var px: float = slot_x + p + 6 + i * 14
				_icon_rect(px, cy - 14, 5, 30, Color(0.6, 0.45, 0.25))
				_icon_rect(px, cy - 17, 7, 4, Color(0.4, 0.25, 0.12))  # Spitze
			_icon_rect(slot_x + p + 4, cy - 6, 32, 3, Color(0.4, 0.25, 0.12))
			_icon_rect(slot_x + p + 4, cy + 6, 32, 3, Color(0.4, 0.25, 0.12))

		"wall":
			# Wand: Stehende Planken + Seil
			for i in range(5):
				var px: float = slot_x + p + 3 + i * 7
				_icon_rect(px, cy - 14, 6, 30, Color(0.55, 0.38, 0.2))
			_icon_rect(slot_x + p, cy - 4, s - p * 2, 3, Color(0.7, 0.6, 0.4))  # Seil
			_icon_rect(slot_x + p, cy + 8, s - p * 2, 3, Color(0.7, 0.6, 0.4))  # Seil

		"chest":
			# Truhe: Dunkelbraune Box + Gold-Schloss + Metallbänder
			_icon_rect(cx - 16, cy - 6, 32, 20, Color(0.35, 0.2, 0.1))  # Körper
			_icon_rect(cx - 17, cy - 10, 34, 6, Color(0.4, 0.25, 0.12)) # Deckel
			_icon_rect(cx - 3, cy - 2, 6, 8, Color(0.85, 0.7, 0.2))     # Gold-Schloss
			_icon_rect(cx - 12, cy - 8, 3, 22, Color(0.3, 0.3, 0.28))   # Band links
			_icon_rect(cx + 9, cy - 8, 3, 22, Color(0.3, 0.3, 0.28))    # Band rechts

		"meat_small":
			# Fleischstückchen: kleiner rosa-roter Brocken mit Fett-Streifen
			_icon_rect(cx - 8, cy - 6, 16, 14, Color(0.85, 0.35, 0.3))
			_icon_rect(cx - 6, cy - 8, 12, 4, Color(0.95, 0.85, 0.75))

		"meat_chunk":
			# Fleischklumpen: großer dunkelroter Brocken mit Knochen
			_icon_rect(cx - 11, cy - 6, 22, 16, Color(0.65, 0.2, 0.15))
			_icon_rect(cx + 4, cy - 14, 4, 12, Color(0.95, 0.92, 0.85))  # Knochen
			_icon_rect(cx + 2, cy - 17, 8, 5, Color(0.95, 0.92, 0.85))   # Knochen-Ende

		"steak":
			# Steak: flache braun-rote Scheibe mit Grillstreifen
			_icon_rect(cx - 13, cy - 6, 26, 14, Color(0.55, 0.25, 0.15))
			_icon_rect(cx - 11, cy - 3, 22, 2, Color(0.3, 0.12, 0.08))
			_icon_rect(cx - 11, cy + 3, 22, 2, Color(0.3, 0.12, 0.08))

		"rabbit_foot":
			# Hasenfuß: kleiner Fuß mit heller Spitze
			_icon_rect(cx - 8, cy - 4, 14, 8, Color(0.65, 0.55, 0.45))
			_icon_rect(cx + 4, cy - 6, 8, 10, Color(0.85, 0.8, 0.75))

		"wolf_pelt":
			# Wolfspelz: graue Fell-Matte mit dunklem Streifen
			_icon_rect(cx - 14, cy - 10, 28, 22, Color(0.35, 0.35, 0.38))
			_icon_rect(cx - 5, cy - 10, 10, 22, Color(0.22, 0.22, 0.25))

		"cooked_meat_small":
			# Gebratenes Fleischstückchen: brauner Brocken
			_icon_rect(cx - 8, cy - 6, 16, 14, Color(0.5, 0.3, 0.15))
			_icon_rect(cx - 6, cy - 8, 12, 4, Color(0.7, 0.55, 0.35))

		"cooked_meat_chunk":
			# Gebratener Fleischklumpen: brauner Brocken mit Knochen
			_icon_rect(cx - 11, cy - 6, 22, 16, Color(0.45, 0.25, 0.12))
			_icon_rect(cx + 4, cy - 14, 4, 12, Color(0.95, 0.92, 0.85))
			_icon_rect(cx + 2, cy - 17, 8, 5, Color(0.95, 0.92, 0.85))

		"cooked_steak":
			# Gebratenes Steak: dunkelbraune Scheibe mit Grillstreifen
			_icon_rect(cx - 13, cy - 6, 26, 14, Color(0.4, 0.22, 0.1))
			_icon_rect(cx - 11, cy - 3, 22, 2, Color(0.2, 0.1, 0.05))
			_icon_rect(cx - 11, cy + 3, 22, 2, Color(0.2, 0.1, 0.05))

		"cultist_gem":
			# Kultisten-Edelstein: leuchtender lila Kristall (Raute)
			_icon_rect(cx - 4, cy - 14, 8, 8, Color(0.7, 0.3, 0.9))
			_icon_rect(cx - 8, cy - 6, 16, 10, Color(0.6, 0.2, 0.8))
			_icon_rect(cx - 4, cy + 4, 8, 8, Color(0.5, 0.15, 0.7))
			_icon_rect(cx - 2, cy - 8, 4, 6, Color(0.95, 0.8, 1.0))  # Glanzpunkt

		_:
			_icon_rect(slot_x + p, slot_y + p, s - p * 2, s - p * 2, Color(0.5, 0.45, 0.4))

	# Item-Name unter dem Slot (nur für ausgewähltes Item)
	if is_selected:
		var name_de: String = "Holz"
		match item_type:
			"sapling": name_de = "Setzling"
			"torch": name_de = "Fackel"
			"bed": name_de = "Bett"
			"fence": name_de = "Zaun"
			"wall": name_de = "Wand"
			"chest": name_de = "Truhe"
			"meat_small": name_de = "Fleischstückchen"
			"meat_chunk": name_de = "Fleischklumpen"
			"steak": name_de = "Steak"
			"rabbit_foot": name_de = "Hasenfuß"
			"wolf_pelt": name_de = "Wolfspelz"
			"cultist_gem": name_de = "Kultisten-Edelstein"
			"cooked_meat_small": name_de = "Gebr. Fleischstückchen"
			"cooked_meat_chunk": name_de = "Gebr. Fleischklumpen"
			"cooked_steak": name_de = "Gebratenes Steak"
		var name_label := Label.new()
		name_label.text = name_de
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(slot_x, slot_y + SLOT_SIZE + 2)
		name_label.size = Vector2(SLOT_SIZE, 16)
		name_label.add_theme_font_size_override("font_size", 11)
		add_child(name_label)
		slot_containers.append(name_label)


func _icon_rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	var r := ColorRect.new()
	r.position = Vector2(x, y)
	r.size = Vector2(w, h)
	r.color = color
	add_child(r)
	slot_containers.append(r)

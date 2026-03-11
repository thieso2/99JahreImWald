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
	var icon_size: float = SLOT_SIZE * 0.6
	var icon_x: float = slot_x + (SLOT_SIZE - icon_size) / 2.0
	var icon_y: float = slot_y + (SLOT_SIZE - icon_size) / 2.0

	match item_type:
		"wood":
			# Holz-Icon: braunes Rechteck
			var icon := ColorRect.new()
			icon.color = wood_color
			icon.position = Vector2(icon_x + 4, icon_y + 8)
			icon.size = Vector2(icon_size - 8, icon_size - 16)
			add_child(icon)
			slot_containers.append(icon)

			# Hellerer Kern (Holzmaserung)
			var inner := ColorRect.new()
			inner.color = Color(0.65, 0.45, 0.2, 1)
			inner.position = Vector2(icon_x + 12, icon_y + 14)
			inner.size = Vector2(icon_size - 24, icon_size - 28)
			add_child(inner)
			slot_containers.append(inner)

		"sapling":
			# Setzling-Icon: grüner Stiel + Blatt
			var stem := ColorRect.new()
			stem.color = Color(0.3, 0.45, 0.15, 1)
			stem.position = Vector2(icon_x + icon_size / 2.0 - 2, icon_y + icon_size * 0.3)
			stem.size = Vector2(4, icon_size * 0.6)
			add_child(stem)
			slot_containers.append(stem)

			# Blatt
			var leaf := ColorRect.new()
			leaf.color = sapling_color
			leaf.position = Vector2(icon_x + icon_size * 0.2, icon_y + 4)
			leaf.size = Vector2(icon_size * 0.6, icon_size * 0.4)
			add_child(leaf)
			slot_containers.append(leaf)

	# Item-Name unter dem Slot (nur für ausgewähltes Item)
	if is_selected:
		var name_de: String = "Holz" if item_type == "wood" else "Setzling"
		var name_label := Label.new()
		name_label.text = name_de
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(slot_x, slot_y + SLOT_SIZE + 2)
		name_label.size = Vector2(SLOT_SIZE, 16)
		name_label.add_theme_font_size_override("font_size", 11)
		add_child(name_label)
		slot_containers.append(name_label)

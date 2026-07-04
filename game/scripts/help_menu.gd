extends PanelContainer

# Hilfe-Fenster: Zeigt alle Tastaturbefehle – ? zum Öffnen/Schließen

# Abschnitte: [Titel, [[Taste, Beschreibung], ...]]
var sections: Array = [
	["Bewegung", [
		["W A S D", "Laufen"],
		["Pfeil Hoch / Runter", "Vorwärts / Rückwärts laufen"],
		["Shift", "Sprinten"],
		["Leertaste", "Springen"],
	]],
	["Kamera", [
		["Pfeil Links / Rechts", "Kamera drehen"],
		["Strg + Pfeiltasten", "Kamera neigen / schnell drehen"],
		["+ / -", "Zoom rein / raus"],
		["Mausrad", "Zoom"],
		["Rechte Maustaste + Maus", "Kamera drehen"],
	]],
	["Aktionen", [
		["Q", "Axt ziehen / wegstecken"],
		["E", "Aufsammeln / Baum hacken"],
		["F", "Setzling pflanzen"],
		["G", "Ausgewähltes Item ablegen"],
		["T", "Fackel anzünden / ausmachen"],
		["P", "Item platzieren"],
		["B", "Werkbank öffnen (in der Nähe)"],
	]],
	["Inventar", [
		["Tab / Shift + Tab", "Slot wechseln"],
		["1 - 9", "Slot direkt wählen"],
	]],
	["Sonstiges", [
		["F1", "Cheat-Menü"],
		["?", "Diese Hilfe anzeigen"],
	]],
]


func _ready() -> void:
	visible = false

	# Panel-Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.14, 0.92)
	style.border_color = Color(0.4, 0.6, 0.9, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(14)
	add_theme_stylebox_override("panel", style)

	# ScrollContainer falls das Fenster höher als der Bildschirm wird
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(360, 460)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Titel
	var title := Label.new()
	title.text = "=== TASTATURBEFEHLE [?] ==="
	title.add_theme_color_override("font_color", Color(0.6, 0.8, 1, 1))
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	for section in sections:
		var section_title: String = section[0]
		var bindings: Array = section[1]

		var sep := HSeparator.new()
		vbox.add_child(sep)

		var header := Label.new()
		header.text = section_title
		header.add_theme_font_size_override("font_size", 15)
		header.add_theme_color_override("font_color", Color(0.9, 0.8, 0.4, 1))
		vbox.add_child(header)

		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 2)
		vbox.add_child(grid)

		for binding in bindings:
			var key_label := Label.new()
			key_label.text = binding[0]
			key_label.add_theme_font_size_override("font_size", 13)
			key_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1))
			key_label.custom_minimum_size = Vector2(170, 0)
			grid.add_child(key_label)

			var desc_label := Label.new()
			desc_label.text = binding[1]
			desc_label.add_theme_font_size_override("font_size", 13)
			desc_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75, 1))
			grid.add_child(desc_label)

	# Hinweis zum Schließen
	var hint := Label.new()
	hint.text = "Zum Schließen ? oder Esc drücken"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 1))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hint)

	# Position: Mitte des Bildschirms
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 0.5
	anchor_bottom = 0.5
	offset_left = -195
	offset_right = 195
	offset_top = -245
	offset_bottom = 245


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# unicode 63 = "?" – funktioniert unabhängig vom Tastatur-Layout
		if event.unicode == 63 or event.keycode == KEY_QUESTION:
			visible = not visible
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and visible:
			visible = false
			get_viewport().set_input_as_handled()

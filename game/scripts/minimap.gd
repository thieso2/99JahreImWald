extends Control

# Minimap – Klick zum Vergrößern/Verkleinern
# Frohe Farben, klarer Kontrast, Fog of War

const SIZE_SMALL: float = 170.0
const SIZE_BIG: float = 460.0
const WORLD_RANGE: float = 90.0
const REVEAL_RADIUS: float = 25.0
const GRID: int = 80

var player: CharacterBody3D = null
var camera_controller: Node3D = null
var fog: Array = []
var is_big: bool = false
var sz: float = SIZE_SMALL


func _ready() -> void:
	# Fog-Grid: false = nicht erkuntet
	fog.resize(GRID)
	for x in range(GRID):
		fog[x] = []
		fog[x].resize(GRID)
		for y in range(GRID):
			fog[x][y] = false

	mouse_filter = Control.MOUSE_FILTER_STOP
	_apply_layout()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		is_big = not is_big
		sz = SIZE_BIG if is_big else SIZE_SMALL
		_apply_layout()
		get_viewport().set_input_as_handled()


func _apply_layout() -> void:
	if is_big:
		anchor_left = 0.5
		anchor_top = 0.5
		anchor_right = 0.5
		anchor_bottom = 0.5
		offset_left = -sz / 2.0
		offset_top = -sz / 2.0
		offset_right = sz / 2.0
		offset_bottom = sz / 2.0
	else:
		anchor_left = 1.0
		anchor_top = 0.0
		anchor_right = 1.0
		anchor_bottom = 0.0
		offset_left = -sz - 12
		offset_top = 8
		offset_right = -12
		offset_bottom = sz + 8


func _process(_delta: float) -> void:
	if not player:
		return
	_reveal()
	queue_redraw()


func _reveal() -> void:
	var px: float = player.global_position.x
	var pz: float = player.global_position.z
	var cr: float = REVEAL_RADIUS / (WORLD_RANGE * 2.0) * GRID
	var cx: int = int((px + WORLD_RANGE) / (WORLD_RANGE * 2.0) * GRID)
	var cy: int = int((pz + WORLD_RANGE) / (WORLD_RANGE * 2.0) * GRID)
	var ri: int = int(cr) + 1
	for dx in range(-ri, ri + 1):
		for dy in range(-ri, ri + 1):
			if dx * dx + dy * dy <= ri * ri:
				var gx: int = cx + dx
				var gy: int = cy + dy
				if gx >= 0 and gx < GRID and gy >= 0 and gy < GRID:
					fog[gx][gy] = true


func _w2m(wp: Vector3) -> Vector2:
	var f: float = sz / (WORLD_RANGE * 2.0)
	return Vector2(sz / 2.0 + wp.x * f, sz / 2.0 + wp.z * f)


func _revealed(wp: Vector3) -> bool:
	var gx: int = int((wp.x + WORLD_RANGE) / (WORLD_RANGE * 2.0) * GRID)
	var gy: int = int((wp.z + WORLD_RANGE) / (WORLD_RANGE * 2.0) * GRID)
	if gx >= 0 and gx < GRID and gy >= 0 and gy < GRID:
		return fog[gx][gy]
	return false


func _draw() -> void:
	if not player:
		return

	var c: float = sz / 2.0
	var center := Vector2(c, c)
	var cell: float = sz / GRID
	var sc: float = sz / SIZE_SMALL

	# --- Hintergrund: sanftes Beige (unerkuntet) ---
	draw_rect(Rect2(0, 0, sz, sz), Color(0.82, 0.78, 0.7, 1.0))

	# --- Erkundete Bereiche: kräftiges Grün ---
	for gx in range(GRID):
		for gy in range(GRID):
			if fog[gx][gy]:
				draw_rect(Rect2(float(gx) * cell, float(gy) * cell, cell + 0.5, cell + 0.5),
					Color(0.35, 0.75, 0.25, 1.0))

	# --- Rahmen ---
	draw_rect(Rect2(0, 0, sz, 3), Color(0.3, 0.2, 0.1, 1))
	draw_rect(Rect2(0, sz - 3, sz, 3), Color(0.3, 0.2, 0.1, 1))
	draw_rect(Rect2(0, 0, 3, sz), Color(0.3, 0.2, 0.1, 1))
	draw_rect(Rect2(sz - 3, 0, 3, sz), Color(0.3, 0.2, 0.1, 1))

	# --- Bäume: dunkelgrüne Punkte ---
	var trees: Array = get_tree().get_nodes_in_group("tree")
	for tree in trees:
		if not is_instance_valid(tree):
			continue
		if _revealed(tree.global_position):
			var tp: Vector2 = _w2m(tree.global_position)
			if tp.x > 3 and tp.x < sz - 3 and tp.y > 3 and tp.y < sz - 3:
				draw_circle(tp, 2.0 * sc, Color(0.1, 0.4, 0.08, 1.0))

	# --- Lagerfeuer: großer orangener Punkt (IMMER sichtbar) ---
	draw_circle(center, 8.0 * sc, Color(1.0, 0.45, 0.0, 1.0))
	draw_circle(center, 5.0 * sc, Color(1.0, 0.75, 0.1, 1.0))
	draw_circle(center, 2.5 * sc, Color(1.0, 1.0, 0.4, 1.0))

	# --- Safe-Zone-Ring: gelb ---
	var sr: float = 8.0 * sz / (WORLD_RANGE * 2.0)
	for i in range(48):
		var a1: float = float(i) / 48.0 * TAU
		var a2: float = float(i + 1) / 48.0 * TAU
		draw_line(center + Vector2(cos(a1), sin(a1)) * sr,
			center + Vector2(cos(a2), sin(a2)) * sr,
			Color(1.0, 0.9, 0.0, 1.0), 2.0 * sc)

	# --- Portal: lila Quadrat mit weißem Rand ---
	var portal: Node = get_tree().current_scene.find_child("Portal", false, false)
	if portal and _revealed(portal.global_position):
		var cp: Vector2 = _w2m(portal.global_position)
		var hs: float = 7.0 * sc
		draw_rect(Rect2(cp.x - hs - 2, cp.y - hs - 2, hs * 2 + 4, hs * 2 + 4), Color.WHITE)
		draw_rect(Rect2(cp.x - hs, cp.y - hs, hs * 2, hs * 2), Color(0.6, 0.2, 0.9, 1.0))
		draw_rect(Rect2(cp.x - hs * 0.4, cp.y - hs * 0.3, hs * 0.8, hs * 0.6), Color(0.9, 0.8, 1.0, 1.0))

	# --- Spieler: weißes Dreieck mit schwarzer Outline ---
	var pp: Vector2 = _w2m(player.global_position)
	var yaw: float = 0.0
	if camera_controller and camera_controller.has_method("get_yaw"):
		yaw = deg_to_rad(camera_controller.get_yaw())
	var fwd := Vector2(sin(yaw), -cos(yaw))
	var lft := Vector2(-fwd.y, fwd.x)

	# Schwarze Outline
	draw_polygon(
		PackedVector2Array([
			pp + fwd * 14.0 * sc,
			pp - fwd * 7.0 * sc + lft * 8.0 * sc,
			pp - fwd * 7.0 * sc - lft * 8.0 * sc]),
		PackedColorArray([Color.BLACK, Color.BLACK, Color.BLACK]))

	# Weißes Dreieck
	draw_polygon(
		PackedVector2Array([
			pp + fwd * 12.0 * sc,
			pp - fwd * 5.0 * sc + lft * 6.5 * sc,
			pp - fwd * 5.0 * sc - lft * 6.5 * sc]),
		PackedColorArray([Color.WHITE, Color.WHITE, Color.WHITE]))

	# Blauer Richtungspunkt vorne
	draw_circle(pp + fwd * 6.0 * sc, 2.5 * sc, Color(0.2, 0.5, 1.0, 1.0))

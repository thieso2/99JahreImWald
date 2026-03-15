extends Node3D

# Unterirdische Höhle mit 3 Räumen
# Rampe → Raum 1 → Gang → Raum 2 → Gang → Raum 3

var bat_script: GDScript
var cultist_script: GDScript

var rock_mat: StandardMaterial3D
var dark_rock_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D

const W: float = 5.0         # Gangbreite
const RAMP_LEN: float = 18.0
const DEPTH: float = 5.0
const STEPS: int = 18
const ROOM_H: float = 5.0
const CORRIDOR_LEN: float = 8.0


func _ready() -> void:
	bat_script = preload("res://scripts/bat_enemy.gd")
	cultist_script = preload("res://scripts/cultist_enemy.gd")

	rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.32, 0.28, 0.25, 1)
	dark_rock_mat = StandardMaterial3D.new()
	dark_rock_mat.albedo_color = Color(0.18, 0.15, 0.13, 1)
	floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.25, 0.22, 0.18, 1)

	call_deferred("_build_all")


func _build_all() -> void:
	var root: Node = get_tree().current_scene
	var gp: Vector3 = global_position
	var y: float = -DEPTH  # Tiefe aller Räume

	# Eingang
	_build_entrance(root, gp)

	# Rampe (geht von z=+2 nach z=-RAMP_LEN+2)
	_build_ramp(root, gp)

	# Raum 1: direkt am Rampen-Ende
	var r1_z: float = -RAMP_LEN + 2.0 - 6.0  # Mitte Raum 1
	_build_room(root, gp, y, r1_z, 12.0, 10.0, "Raum 1")

	# Korridor 1: von Raum 1 nach rechts (+X) zu Raum 2
	var cor1_start_x: float = 6.0  # Rechte Wand von Raum 1
	_build_corridor_x(root, gp, y, cor1_start_x, r1_z, CORRIDOR_LEN)

	# Raum 2: rechts von Raum 1
	var r2_x: float = cor1_start_x + CORRIDOR_LEN + 6.0
	_build_room(root, gp + Vector3(r2_x, 0, 0), y, r1_z, 14.0, 12.0, "Raum 2")

	# Korridor 2: von Raum 2 weiter in -Z Richtung zu Raum 3
	var r2_z_end: float = r1_z - 6.0
	_build_corridor_z(root, gp + Vector3(r2_x, 0, 0), y, r2_z_end, CORRIDOR_LEN)

	# Raum 3: hinter Raum 2
	var r3_z: float = r2_z_end - CORRIDOR_LEN - 7.0
	_build_room(root, gp + Vector3(r2_x, 0, 0), y, r3_z, 16.0, 14.0, "Raum 3")

	# Feinde verteilen
	_spawn_enemies(root, gp, y, r1_z, r2_x, r3_z)

	# Lichter in jedem Raum
	_add_light(root, gp + Vector3(0, y + ROOM_H * 0.6, r1_z), 0.12)
	_add_light(root, gp + Vector3(r2_x, y + ROOM_H * 0.6, r1_z), 0.1)
	_add_light(root, gp + Vector3(r2_x, y + ROOM_H * 0.6, r3_z), 0.08)


func _build_entrance(root: Node, gp: Vector3) -> void:
	for side in [-1, 1]:
		_box(root, gp + Vector3(side * (W / 2.0 + 0.8), 1.8, 2.0),
			Vector3(1.5, 3.6, 2.0), rock_mat)
	_box(root, gp + Vector3(0, 3.8, 2.0),
		Vector3(W + 3.0, 1.0, 2.5), dark_rock_mat)


func _build_ramp(root: Node, gp: Vector3) -> void:
	var step_len: float = RAMP_LEN / STEPS
	var step_drop: float = DEPTH / STEPS

	for i in range(STEPS):
		# +2.0 damit erste Stufen VOR dem Loch beginnen und mit Boden überlappen
		var z: float = -float(i) * step_len - step_len / 2.0 + 2.0
		var sy: float = -float(i) * step_drop

		# Boden-Stufe
		_box(root, gp + Vector3(0, sy - 0.1, z),
			Vector3(W, 0.25, step_len + 0.15), floor_mat)

		# Wände und Decke nur unterirdisch
		if sy < -0.3:
			_box(root, gp + Vector3(W / 2.0 + 0.5, sy + 1.5, z),
				Vector3(1.0, 4.0, step_len + 0.2), rock_mat)
			_box(root, gp + Vector3(-W / 2.0 - 0.5, sy + 1.5, z),
				Vector3(1.0, 4.0, step_len + 0.2), rock_mat)
			_box(root, gp + Vector3(0, sy + 3.5, z),
				Vector3(W + 2.0, 0.5, step_len + 0.2), dark_rock_mat)


func _build_room(root: Node, center_xz: Vector3, y: float, rz: float, w: float, d: float, _name: String) -> void:
	# Boden
	_box(root, center_xz + Vector3(0, y + 0.1, rz), Vector3(w, 0.25, d), floor_mat)

	# Decke
	_box(root, center_xz + Vector3(0, y + ROOM_H + 0.3, rz), Vector3(w + 2.0, 0.6, d + 2.0), dark_rock_mat)

	# 4 Wände (mit Öffnungen wo Korridore anschließen)
	# Hintere Wand (-Z)
	_box(root, center_xz + Vector3(0, y + ROOM_H / 2.0, rz - d / 2.0 - 0.5),
		Vector3(w + 2.0, ROOM_H + 1.0, 1.0), rock_mat)

	# Vordere Wand (+Z) - Öffnung in der Mitte
	var front_side_w: float = (w / 2.0 - W / 2.0)
	if front_side_w > 0.3:
		_box(root, center_xz + Vector3(W / 2.0 + front_side_w / 2.0, y + ROOM_H / 2.0, rz + d / 2.0 + 0.5),
			Vector3(front_side_w, ROOM_H + 1.0, 1.0), rock_mat)
		_box(root, center_xz + Vector3(-W / 2.0 - front_side_w / 2.0, y + ROOM_H / 2.0, rz + d / 2.0 + 0.5),
			Vector3(front_side_w, ROOM_H + 1.0, 1.0), rock_mat)

	# Linke Wand (-X) - volle Wand
	_box(root, center_xz + Vector3(-w / 2.0 - 0.5, y + ROOM_H / 2.0, rz),
		Vector3(1.0, ROOM_H + 1.0, d + 1.0), rock_mat)

	# Rechte Wand (+X) - Öffnung für Korridor
	var right_side_d: float = (d / 2.0 - W / 2.0)
	if right_side_d > 0.3:
		_box(root, center_xz + Vector3(w / 2.0 + 0.5, y + ROOM_H / 2.0, rz + d / 2.0 - right_side_d / 2.0),
			Vector3(1.0, ROOM_H + 1.0, right_side_d), rock_mat)
		_box(root, center_xz + Vector3(w / 2.0 + 0.5, y + ROOM_H / 2.0, rz - d / 2.0 + right_side_d / 2.0),
			Vector3(1.0, ROOM_H + 1.0, right_side_d), rock_mat)

	# Stalaktiten
	for i in range(4):
		var sx: float = randf_range(-w * 0.3, w * 0.3)
		var sz: float = randf_range(-d * 0.3, d * 0.3)
		var sh: float = randf_range(0.4, 1.0)
		var st := MeshInstance3D.new()
		var stm := CylinderMesh.new()
		stm.top_radius = randf_range(0.05, 0.1)
		stm.bottom_radius = 0.02
		stm.height = sh
		st.mesh = stm
		st.material_override = rock_mat
		st.position = center_xz + Vector3(sx, y + ROOM_H - sh / 2.0, sz + rz)
		root.add_child(st)


func _build_corridor_x(root: Node, gp: Vector3, y: float, start_x: float, z: float, length: float) -> void:
	# Horizontaler Korridor in +X Richtung
	var cx: float = start_x + length / 2.0
	# Boden
	_box(root, gp + Vector3(cx, y + 0.1, z), Vector3(length, 0.25, W), floor_mat)
	# Decke
	_box(root, gp + Vector3(cx, y + ROOM_H + 0.3, z), Vector3(length + 0.5, 0.6, W + 2.0), dark_rock_mat)
	# Wände (vorne und hinten)
	_box(root, gp + Vector3(cx, y + ROOM_H / 2.0, z + W / 2.0 + 0.5), Vector3(length, ROOM_H + 1.0, 1.0), rock_mat)
	_box(root, gp + Vector3(cx, y + ROOM_H / 2.0, z - W / 2.0 - 0.5), Vector3(length, ROOM_H + 1.0, 1.0), rock_mat)


func _build_corridor_z(root: Node, center_x: Vector3, y: float, start_z: float, length: float) -> void:
	# Korridor in -Z Richtung
	var cz: float = start_z - length / 2.0
	# Boden
	_box(root, center_x + Vector3(0, y + 0.1, cz), Vector3(W, 0.25, length), floor_mat)
	# Decke
	_box(root, center_x + Vector3(0, y + ROOM_H + 0.3, cz), Vector3(W + 2.0, 0.6, length + 0.5), dark_rock_mat)
	# Wände
	_box(root, center_x + Vector3(W / 2.0 + 0.5, y + ROOM_H / 2.0, cz), Vector3(1.0, ROOM_H + 1.0, length), rock_mat)
	_box(root, center_x + Vector3(-W / 2.0 - 0.5, y + ROOM_H / 2.0, cz), Vector3(1.0, ROOM_H + 1.0, length), rock_mat)


func _spawn_enemies(root: Node, gp: Vector3, y: float, r1_z: float, r2_x: float, r3_z: float) -> void:
	# Raum 1: 1 Fledermaus
	_spawn_bat(root, gp + Vector3(0, y + ROOM_H * 0.6, r1_z))

	# Raum 2: 1 Kultist + 1 Fledermaus
	_spawn_bat(root, gp + Vector3(r2_x, y + ROOM_H * 0.6, r1_z))
	_spawn_cultist(root, gp + Vector3(r2_x + randf_range(-3, 3), y + 0.5, r1_z + randf_range(-3, 3)))

	# Raum 3: 2 Kultisten + 1 Fledermaus (schwieriger)
	_spawn_bat(root, gp + Vector3(r2_x, y + ROOM_H * 0.6, r3_z))
	_spawn_cultist(root, gp + Vector3(r2_x + randf_range(-4, 4), y + 0.5, r3_z + randf_range(-4, 4)))
	_spawn_cultist(root, gp + Vector3(r2_x + randf_range(-4, 4), y + 0.5, r3_z + randf_range(-4, 4)))


func _spawn_bat(root: Node, pos: Vector3) -> void:
	var bat := CharacterBody3D.new()
	bat.set_script(bat_script)
	bat.position = pos
	root.add_child(bat)


func _spawn_cultist(root: Node, pos: Vector3) -> void:
	var cultist := CharacterBody3D.new()
	cultist.set_script(cultist_script)
	cultist.position = pos
	root.add_child(cultist)


func _add_light(root: Node, pos: Vector3, energy: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(0.3, 0.25, 0.4)
	light.light_energy = energy
	light.omni_range = 18.0
	light.shadow_enabled = false
	light.position = pos
	root.add_child(light)


func _box(root: Node, pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	root.add_child(body)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mesh.mesh = bm
	mesh.material_override = mat
	body.add_child(mesh)

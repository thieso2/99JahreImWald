extends Node3D

# Unterirdische Welt – große Höhlenwelt tief unter der Karte
# Erreichbar nur durch das Portal im Wald
# Leuchtende Kristalle, Stalagmiten, Pilze und Feinde (Kultisten + Fledermäuse)

const SIZE: float = 70.0       # Kantenlänge der Kaverne
const HEIGHT: float = 13.0     # Deckenhöhe

var rock_mat: StandardMaterial3D
var dark_rock_mat: StandardMaterial3D
var floor_mat: StandardMaterial3D

var bat_script: GDScript = null
var cultist_script: GDScript = null


func _ready() -> void:
	bat_script = preload("res://scripts/bat_enemy.gd")
	cultist_script = preload("res://scripts/cultist_enemy.gd")

	_create_materials()
	_build_cavern()
	_add_crystals()
	_add_stalagmites()
	_add_mushrooms()
	_spawn_enemies()


func _create_materials() -> void:
	rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.3, 0.28, 0.26, 1)

	dark_rock_mat = StandardMaterial3D.new()
	dark_rock_mat.albedo_color = Color(0.18, 0.16, 0.15, 1)

	floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.24, 0.21, 0.19, 1)


func _build_cavern() -> void:
	# Boden
	_static_box(Vector3(0, -0.5, 0), Vector3(SIZE, 1.0, SIZE), floor_mat)

	# Decke
	_static_box(Vector3(0, HEIGHT + 0.5, 0), Vector3(SIZE, 1.0, SIZE), dark_rock_mat)

	# 4 Wände
	var half: float = SIZE / 2.0
	_static_box(Vector3(0, HEIGHT / 2.0, -half), Vector3(SIZE, HEIGHT, 1.0), rock_mat)
	_static_box(Vector3(0, HEIGHT / 2.0, half), Vector3(SIZE, HEIGHT, 1.0), rock_mat)
	_static_box(Vector3(-half, HEIGHT / 2.0, 0), Vector3(1.0, HEIGHT, SIZE), rock_mat)
	_static_box(Vector3(half, HEIGHT / 2.0, 0), Vector3(1.0, HEIGHT, SIZE), rock_mat)


func _static_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var body := StaticBody3D.new()
	body.position = pos

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

	add_child(body)


func _add_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123

	# 10 Kristall-Gruppen, 5 davon mit Licht (Mobile-Renderer-Limit beachten)
	for i in range(10):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(8.0, SIZE / 2.0 - 5.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		var crystal_color := Color(
			rng.randf_range(0.2, 0.5),
			rng.randf_range(0.5, 0.8),
			rng.randf_range(0.8, 1.0), 1)

		var crystal_mat := StandardMaterial3D.new()
		crystal_mat.albedo_color = crystal_color
		crystal_mat.emission_enabled = true
		crystal_mat.emission = crystal_color
		crystal_mat.emission_energy_multiplier = 1.5

		# 2-4 Kristall-Zacken pro Gruppe
		var count: int = rng.randi_range(2, 4)
		for j in range(count):
			var crystal := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.02
			cm.bottom_radius = rng.randf_range(0.15, 0.3)
			cm.height = rng.randf_range(0.8, 2.2)
			cm.radial_segments = 6
			crystal.mesh = cm
			crystal.material_override = crystal_mat
			crystal.position = pos + Vector3(rng.randf_range(-0.6, 0.6), cm.height / 2.0, rng.randf_range(-0.6, 0.6))
			crystal.rotation.x = rng.randf_range(-0.3, 0.3)
			crystal.rotation.z = rng.randf_range(-0.3, 0.3)
			add_child(crystal)

		# Nur jede zweite Gruppe bekommt echtes Licht
		if i % 2 == 0:
			var light := OmniLight3D.new()
			light.light_color = crystal_color
			light.omni_range = 12.0
			light.light_energy = 1.2
			light.position = pos + Vector3(0, 1.5, 0)
			add_child(light)


func _add_stalagmites() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 456

	for i in range(14):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(6.0, SIZE / 2.0 - 3.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		# Stalagmit (vom Boden)
		var stal := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.05
		sm.bottom_radius = rng.randf_range(0.4, 0.9)
		sm.height = rng.randf_range(1.5, 4.0)
		sm.radial_segments = 7
		stal.mesh = sm
		stal.material_override = rock_mat
		stal.position = pos + Vector3(0, sm.height / 2.0, 0)
		add_child(stal)

		# Stalaktit (von der Decke, versetzt)
		var stak := MeshInstance3D.new()
		var km := CylinderMesh.new()
		km.top_radius = rng.randf_range(0.3, 0.7)
		km.bottom_radius = 0.03
		km.height = rng.randf_range(1.0, 3.0)
		km.radial_segments = 7
		stak.mesh = km
		stak.material_override = dark_rock_mat
		stak.position = Vector3(pos.x + rng.randf_range(-3, 3), HEIGHT - km.height / 2.0, pos.z + rng.randf_range(-3, 3))
		add_child(stak)


func _add_mushrooms() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 789

	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.8, 0.75, 0.65, 1)

	for i in range(16):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(4.0, SIZE / 2.0 - 3.0)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		var glow_color := Color(rng.randf_range(0.3, 0.9), rng.randf_range(0.6, 1.0), rng.randf_range(0.3, 0.7), 1)
		var cap_mat := StandardMaterial3D.new()
		cap_mat.albedo_color = glow_color
		cap_mat.emission_enabled = true
		cap_mat.emission = glow_color
		cap_mat.emission_energy_multiplier = 0.8

		# Stiel
		var stem := MeshInstance3D.new()
		var stm := CylinderMesh.new()
		stm.top_radius = 0.04
		stm.bottom_radius = 0.06
		stm.height = rng.randf_range(0.2, 0.5)
		stem.mesh = stm
		stem.material_override = stem_mat
		stem.position = pos + Vector3(0, stm.height / 2.0, 0)
		add_child(stem)

		# Leuchtender Hut
		var cap := MeshInstance3D.new()
		var cpm := SphereMesh.new()
		cpm.radius = rng.randf_range(0.1, 0.22)
		cpm.height = cpm.radius * 1.2
		cap.mesh = cpm
		cap.material_override = cap_mat
		cap.position = pos + Vector3(0, stm.height + cpm.radius * 0.3, 0)
		add_child(cap)


func _spawn_enemies() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 321

	# 3 Fledermäuse in der Luft
	for i in range(3):
		var bat := CharacterBody3D.new()
		bat.set_script(bat_script)
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(10.0, SIZE / 2.0 - 8.0)
		bat.position = Vector3(cos(angle) * dist, HEIGHT * 0.6, sin(angle) * dist)
		add_child(bat)

	# 3 Kultisten am Boden
	for i in range(3):
		var cultist := CharacterBody3D.new()
		cultist.set_script(cultist_script)
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(10.0, SIZE / 2.0 - 8.0)
		cultist.position = Vector3(cos(angle) * dist, 0.5, sin(angle) * dist)
		add_child(cultist)

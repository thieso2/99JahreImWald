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
	_add_wall_boulders()
	_add_floor_rocks()
	_add_crystals()
	_add_stalagmites()
	_add_roots()
	_add_mushrooms()
	_add_dust_particles()
	_spawn_enemies()


func _make_rock_material(base_color: Color, noise_seed: int, noise_scale: float = 4.0) -> StandardMaterial3D:
	# Felsmaterial mit prozeduraler Noise-Textur und Normal-Map
	# Triplanar-Mapping, damit die Textur auf allen Flächen ohne Verzerrung liegt
	var mat := StandardMaterial3D.new()
	mat.albedo_color = base_color
	mat.roughness = 0.95

	# Farbvariation über Noise
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = 0.02
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.55, 0.5, 0.45, 1))
	ramp.set_color(1, Color(1.15, 1.1, 1.05, 1))
	tex.color_ramp = ramp
	mat.albedo_texture = tex

	# Normal-Map für Fels-Struktur (Licht bricht sich an Unebenheiten)
	var nnoise := FastNoiseLite.new()
	nnoise.seed = noise_seed + 1
	nnoise.frequency = 0.05
	nnoise.fractal_octaves = 5
	var ntex := NoiseTexture2D.new()
	ntex.noise = nnoise
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 8.0
	mat.normal_enabled = true
	mat.normal_texture = ntex
	mat.normal_scale = 1.0

	mat.uv1_triplanar = true
	mat.uv1_scale = Vector3(noise_scale, noise_scale, noise_scale)
	return mat


func _create_materials() -> void:
	rock_mat = _make_rock_material(Color(0.32, 0.3, 0.28, 1), 100, 3.0)
	dark_rock_mat = _make_rock_material(Color(0.2, 0.18, 0.17, 1), 200, 4.0)
	floor_mat = _make_rock_material(Color(0.28, 0.24, 0.21, 1), 300, 5.0)


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


func _add_wall_boulders() -> void:
	# Unregelmäßige Felsbrocken entlang der Wände – kaschieren die flachen Flächen
	var rng := RandomNumberGenerator.new()
	rng.seed = 555
	var half: float = SIZE / 2.0

	for i in range(40):
		var boulder := MeshInstance3D.new()
		var bm := SphereMesh.new()
		bm.radius = rng.randf_range(1.0, 3.0)
		bm.height = bm.radius * 2.0
		bm.radial_segments = 8
		bm.rings = 5
		boulder.mesh = bm
		boulder.material_override = rock_mat

		# Position an einer der 4 Wände
		var wall: int = i % 4
		var along: float = rng.randf_range(-half + 3.0, half - 3.0)
		var depth_in: float = rng.randf_range(0.3, 1.2)
		match wall:
			0: boulder.position = Vector3(along, rng.randf_range(0, 6.0), -half + depth_in)
			1: boulder.position = Vector3(along, rng.randf_range(0, 6.0), half - depth_in)
			2: boulder.position = Vector3(-half + depth_in, rng.randf_range(0, 6.0), along)
			3: boulder.position = Vector3(half - depth_in, rng.randf_range(0, 6.0), along)

		# Unregelmäßig verzerren – wirkt wie echter Fels statt Kugel
		boulder.scale = Vector3(
			rng.randf_range(0.7, 1.6),
			rng.randf_range(0.5, 1.2),
			rng.randf_range(0.7, 1.6))
		boulder.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		add_child(boulder)


func _add_floor_rocks() -> void:
	# Flache Felsplatten und kleine Steine auf dem Boden – bricht die ebene Fläche auf
	var rng := RandomNumberGenerator.new()
	rng.seed = 666

	for i in range(30):
		var rock := MeshInstance3D.new()
		var rm := SphereMesh.new()
		rm.radius = rng.randf_range(0.5, 2.2)
		rm.height = rm.radius * 2.0
		rm.radial_segments = 8
		rm.rings = 5
		rock.mesh = rm
		rock.material_override = floor_mat if i % 2 == 0 else rock_mat

		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(4.0, SIZE / 2.0 - 3.0)
		rock.position = Vector3(cos(angle) * dist, rng.randf_range(-rm.radius * 0.7, -rm.radius * 0.4), sin(angle) * dist)
		# Stark abgeflacht = aus dem Boden ragende Felsplatte
		rock.scale = Vector3(rng.randf_range(0.8, 1.8), rng.randf_range(0.3, 0.6), rng.randf_range(0.8, 1.8))
		rock.rotation.y = rng.randf() * TAU
		add_child(rock)


func _add_roots() -> void:
	# Baumwurzeln hängen von der Decke – wir sind ja unter dem Wald!
	var rng := RandomNumberGenerator.new()
	rng.seed = 888
	var root_mat := StandardMaterial3D.new()
	root_mat.albedo_color = Color(0.35, 0.25, 0.15, 1)
	root_mat.roughness = 0.9

	for i in range(22):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(3.0, SIZE / 2.0 - 4.0)
		var base := Vector3(cos(angle) * dist, HEIGHT, sin(angle) * dist)

		# Jede Wurzel: 2-4 Segmente, die sich nach unten verjüngen und leicht knicken
		var segments: int = rng.randi_range(2, 4)
		var seg_top: float = rng.randf_range(0.1, 0.2)
		var pos := base
		var tilt := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		for s in range(segments):
			var seg := MeshInstance3D.new()
			var sm := CylinderMesh.new()
			sm.top_radius = seg_top
			sm.bottom_radius = seg_top * 0.6
			sm.height = rng.randf_range(0.8, 1.6)
			sm.radial_segments = 6
			seg.mesh = sm
			seg.material_override = root_mat
			pos += Vector3(tilt.x, -sm.height * 0.9, tilt.z)
			seg.position = pos
			seg.rotation.x = tilt.z * 0.8
			seg.rotation.z = -tilt.x * 0.8
			add_child(seg)
			seg_top *= 0.6
			tilt += Vector3(rng.randf_range(-0.15, 0.15), 0, rng.randf_range(-0.15, 0.15))


func _add_dust_particles() -> void:
	# Schwebende Staub-/Sporenpartikel in der ganzen Kaverne
	var particles := GPUParticles3D.new()
	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(SIZE / 2.0 - 2.0, HEIGHT / 2.0, SIZE / 2.0 - 2.0)
	mat.gravity = Vector3(0, -0.02, 0)
	mat.initial_velocity_min = 0.02
	mat.initial_velocity_max = 0.15
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	particles.process_material = mat
	particles.amount = 120
	particles.lifetime = 12.0
	particles.preprocess = 12.0  # Sofort gefüllt beim Betreten

	var dust_mesh := SphereMesh.new()
	dust_mesh.radius = 0.02
	dust_mesh.height = 0.04
	dust_mesh.radial_segments = 4
	dust_mesh.rings = 2
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.8, 0.85, 1.0, 0.5)
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.emission_enabled = true
	dust_mat.emission = Color(0.6, 0.7, 0.9, 1)
	dust_mat.emission_energy_multiplier = 0.6
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mesh.material = dust_mat
	particles.draw_pass_1 = dust_mesh

	particles.position = Vector3(0, HEIGHT / 2.0, 0)
	add_child(particles)


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
		crystal_mat.albedo_color = Color(crystal_color.r, crystal_color.g, crystal_color.b, 0.85)
		crystal_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		crystal_mat.emission_enabled = true
		crystal_mat.emission = crystal_color
		crystal_mat.emission_energy_multiplier = 2.0
		crystal_mat.metallic = 0.3
		crystal_mat.roughness = 0.1  # Glänzend wie Glas

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

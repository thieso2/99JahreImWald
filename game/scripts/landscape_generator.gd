extends Node3D

# Landschafts-Generator: Plateaus, Graswiesen, Sträucher, Teiche, Bäche, Sand-Bereiche

@export var landscape_radius: float = 75.0
@export var min_distance_from_camp: float = 12.0

# Anzahl der Elemente
@export var plateau_count: int = 6
@export var tall_grass_count: int = 10
@export var bush_count: int = 80
@export var pond_count: int = 3
@export var stream_count: int = 2
@export var meadow_count: int = 5
@export var sand_patch_count: int = 4

# Materialien
var grass_mat: StandardMaterial3D
var dark_grass_mat: StandardMaterial3D
var bush_mats: Array = []
var water_mat: StandardMaterial3D
var water_deep_mat: StandardMaterial3D
var sand_mat: StandardMaterial3D
var plateau_mat: StandardMaterial3D
var plateau_side_mat: StandardMaterial3D
var tall_grass_mat: StandardMaterial3D
var short_grass_mat: StandardMaterial3D
var meadow_mat: StandardMaterial3D
var rock_mat: StandardMaterial3D
var flower_mats: Array = []

var rng: RandomNumberGenerator


func _ready() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 123  # Fester Seed für konsistente Landschaft

	_create_materials()
	_generate_plateaus()
	_generate_tall_grass_areas()
	_generate_ponds()
	_generate_streams()
	_generate_meadows()
	_generate_sand_patches()
	_generate_bushes()
	_generate_rocks()


func _create_materials() -> void:
	# Gras
	grass_mat = StandardMaterial3D.new()
	grass_mat.albedo_color = Color(0.2, 0.5, 0.12, 1)

	dark_grass_mat = StandardMaterial3D.new()
	dark_grass_mat.albedo_color = Color(0.15, 0.4, 0.1, 1)

	# Busch-Farben (verschiedene Grüntöne)
	var bush_colors := [
		Color(0.1, 0.38, 0.08, 1),
		Color(0.15, 0.42, 0.1, 1),
		Color(0.08, 0.35, 0.12, 1),
		Color(0.12, 0.3, 0.08, 1),
	]
	for c in bush_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		bush_mats.append(mat)

	# Wasser (halbtransparent, blau)
	water_mat = StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.15, 0.35, 0.55, 0.75)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	water_deep_mat = StandardMaterial3D.new()
	water_deep_mat.albedo_color = Color(0.08, 0.2, 0.4, 0.85)
	water_deep_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Sand
	sand_mat = StandardMaterial3D.new()
	sand_mat.albedo_color = Color(0.72, 0.62, 0.42, 1)

	# Plateaus (Grasdecke oben)
	plateau_mat = StandardMaterial3D.new()
	plateau_mat.albedo_color = Color(0.28, 0.58, 0.16, 1)

	# Plateau-Seiten (Erde/Stein)
	plateau_side_mat = StandardMaterial3D.new()
	plateau_side_mat.albedo_color = Color(0.4, 0.3, 0.2, 1)

	# Hohes Gras
	tall_grass_mat = StandardMaterial3D.new()
	tall_grass_mat.albedo_color = Color(0.25, 0.55, 0.12, 1)

	# Kurzes Gras (heller)
	short_grass_mat = StandardMaterial3D.new()
	short_grass_mat.albedo_color = Color(0.38, 0.68, 0.22, 1)

	# Wiese (helleres Grün)
	meadow_mat = StandardMaterial3D.new()
	meadow_mat.albedo_color = Color(0.35, 0.65, 0.2, 1)

	# Steine
	rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.4, 0.38, 0.35, 1)

	# Blumen
	var flower_colors := [
		Color(0.9, 0.2, 0.2, 1),    # Rot
		Color(0.9, 0.85, 0.2, 1),   # Gelb
		Color(0.6, 0.3, 0.8, 1),    # Lila
		Color(1.0, 1.0, 1.0, 1),    # Weiß
		Color(0.2, 0.5, 0.9, 1),    # Blau
	]
	for c in flower_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = c
		flower_mats.append(mat)


func _get_valid_pos(min_dist: float = 0.0) -> Vector3:
	for _i in range(20):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(min_distance_from_camp, landscape_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		if pos.length() >= min_dist:
			return pos
	return Vector3(rng.randf_range(20, 60), 0, rng.randf_range(20, 60))


# === PLATEAUS (begehbare Stufen) ===
func _generate_plateaus() -> void:
	for i in range(plateau_count):
		var pos: Vector3 = _get_valid_pos(min_distance_from_camp)
		var width: float = rng.randf_range(8.0, 18.0)
		var depth: float = rng.randf_range(8.0, 16.0)
		var steps: int = rng.randi_range(1, 3)  # 1-3 Stufen
		var step_height: float = rng.randf_range(0.4, 0.8)
		_create_plateau(pos, width, depth, steps, step_height)


func _create_plateau(pos: Vector3, width: float, depth: float, steps: int, step_height: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	add_child(body)

	# Jede Stufe ist ein eigenständiger Block ohne Überlappung
	for s in range(steps):
		var shrink: float = 1.0 - float(s) * 0.25
		var sw: float = width * shrink
		var sd: float = depth * shrink
		var sy: float = float(s) * step_height + 0.12  # Über dem Boden

		# Ein einzelner Block pro Stufe (grüne Oberfläche, braune Seite sichtbar durch Größenunterschied)
		var block := MeshInstance3D.new()
		var block_mesh := BoxMesh.new()
		block_mesh.size = Vector3(sw, step_height, sd)
		block.mesh = block_mesh
		block.material_override = plateau_mat if s == steps - 1 else plateau_side_mat
		block.position = Vector3(0, sy + step_height / 2.0, 0)
		body.add_child(block)

		# Kollision
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(sw, step_height, sd)
		col.shape = shape
		col.position = Vector3(0, sy + step_height / 2.0, 0)
		body.add_child(col)

	# Gras auf dem obersten Plateau
	var top_y: float = float(steps) * step_height + 0.2
	for j in range(rng.randi_range(4, 8)):
		var gx: float = rng.randf_range(-width * 0.3, width * 0.3)
		var gz: float = rng.randf_range(-depth * 0.3, depth * 0.3)
		_create_grass_tuft(pos + Vector3(gx, top_y, gz))


# === HOHES GRAS / NIEDRIGES GRAS ===
func _generate_tall_grass_areas() -> void:
	for i in range(tall_grass_count):
		var pos: Vector3 = _get_valid_pos(8.0)
		var radius: float = rng.randf_range(4.0, 10.0)
		var is_tall: bool = rng.randf() > 0.4  # 60% hohes Gras, 40% niedriges
		_create_grass_area(pos, radius, is_tall)


func _create_grass_area(pos: Vector3, radius: float, tall: bool) -> void:
	# Bodenfläche (leicht andere Farbe als Hauptboden)
	var ground := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = radius
	gm.bottom_radius = radius + 0.3
	gm.height = 0.04
	ground.mesh = gm
	ground.material_override = short_grass_mat if not tall else dark_grass_mat
	ground.position = pos
	ground.position.y = 0.12
	add_child(ground)

	var blade_count: int = rng.randi_range(30, 60) if tall else rng.randi_range(15, 30)
	var max_height: float = 0.8 if tall else 0.2
	var min_height: float = 0.4 if tall else 0.08

	for j in range(blade_count):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0, radius * 0.9)
		var blade_height: float = rng.randf_range(min_height, max_height)

		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.04, blade_height, 0.02)
		blade.mesh = blade_mesh
		blade.material_override = tall_grass_mat if tall else short_grass_mat
		blade.position = pos + Vector3(cos(angle) * dist, blade_height / 2.0 + 0.1, sin(angle) * dist)
		blade.rotation.y = rng.randf() * TAU
		blade.rotation.z = rng.randf_range(-0.25, 0.25)  # Leicht geneigt
		add_child(blade)


# === TEICHE ===
func _generate_ponds() -> void:
	for i in range(pond_count):
		var pos: Vector3 = _get_valid_pos(18.0)
		var radius: float = rng.randf_range(4.0, 8.0)
		_create_pond(pos, radius)


func _create_pond(pos: Vector3, radius: float) -> void:
	# Teichbett (etwas dunkler unter dem Wasser)
	var bed := MeshInstance3D.new()
	var bed_mesh := CylinderMesh.new()
	bed_mesh.top_radius = radius + 0.3
	bed_mesh.bottom_radius = radius + 0.5
	bed_mesh.height = 0.08
	bed.mesh = bed_mesh
	bed.material_override = dark_grass_mat
	bed.position = pos
	bed.position.y = -0.02
	add_child(bed)

	# Wasser-Oberfläche
	var water := MeshInstance3D.new()
	var water_mesh := CylinderMesh.new()
	water_mesh.top_radius = radius
	water_mesh.bottom_radius = radius - 0.2
	water_mesh.height = 0.15
	water.mesh = water_mesh
	water.material_override = water_mat
	water.position = pos
	water.position.y = 0.07
	add_child(water)

	# Tiefere Mitte
	var deep := MeshInstance3D.new()
	var deep_mesh := CylinderMesh.new()
	deep_mesh.top_radius = radius * 0.5
	deep_mesh.bottom_radius = radius * 0.3
	deep_mesh.height = 0.1
	deep.mesh = deep_mesh
	deep.material_override = water_deep_mat
	deep.position = pos
	deep.position.y = 0.08
	add_child(deep)

	# Steine am Rand
	for j in range(rng.randi_range(4, 8)):
		var angle: float = rng.randf() * TAU
		var stone_pos: Vector3 = pos + Vector3(cos(angle) * (radius + 0.3), 0, sin(angle) * (radius + 0.3))
		_create_stone(stone_pos, rng.randf_range(0.15, 0.35))

	# Schilfgras am Rand
	for j in range(rng.randi_range(3, 6)):
		var angle: float = rng.randf() * TAU
		var reed_pos: Vector3 = pos + Vector3(cos(angle) * (radius - 0.5), 0, sin(angle) * (radius - 0.5))
		_create_reed(reed_pos)


# === BÄCHE ===
func _generate_streams() -> void:
	for i in range(stream_count):
		var start_angle: float = rng.randf() * TAU
		var start_dist: float = rng.randf_range(20.0, 40.0)
		var start_pos := Vector3(cos(start_angle) * start_dist, 0, sin(start_angle) * start_dist)

		var direction: float = start_angle + rng.randf_range(-0.5, 0.5) + PI
		var length: float = rng.randf_range(25.0, 45.0)
		var width: float = rng.randf_range(1.0, 2.0)

		_create_stream(start_pos, direction, length, width)


func _create_stream(start: Vector3, direction: float, length: float, width: float) -> void:
	var segments: int = int(length / 3.0)
	var current_pos: Vector3 = start
	var current_dir: float = direction

	for i in range(segments):
		# Leicht kurviger Verlauf
		current_dir += rng.randf_range(-0.3, 0.3)
		var next_pos: Vector3 = current_pos + Vector3(cos(current_dir) * 3.0, 0, sin(current_dir) * 3.0)

		# Wasser-Segment
		var segment := MeshInstance3D.new()
		var seg_mesh := BoxMesh.new()
		seg_mesh.size = Vector3(width, 0.1, 3.2)
		segment.mesh = seg_mesh
		segment.material_override = water_mat

		var mid: Vector3 = (current_pos + next_pos) / 2.0
		segment.position = mid
		segment.position.y = 0.06
		segment.rotation.y = atan2(next_pos.x - current_pos.x, next_pos.z - current_pos.z)
		add_child(segment)

		# Gelegentlich Steine am Ufer
		if rng.randf() < 0.4:
			var side: float = width * 0.8 * (1 if rng.randf() > 0.5 else -1)
			var stone_offset := Vector3(cos(current_dir + PI/2) * side, 0, sin(current_dir + PI/2) * side)
			_create_stone(mid + stone_offset, rng.randf_range(0.1, 0.25))

		current_pos = next_pos


# === WIESEN ===
func _generate_meadows() -> void:
	for i in range(meadow_count):
		var pos: Vector3 = _get_valid_pos(15.0)
		var radius: float = rng.randf_range(5.0, 12.0)
		_create_meadow(pos, radius)


func _create_meadow(pos: Vector3, radius: float) -> void:
	# Hellgrüne Bodenfläche
	var ground := MeshInstance3D.new()
	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = radius
	ground_mesh.bottom_radius = radius + 0.5
	ground_mesh.height = 0.05
	ground.mesh = ground_mesh
	ground.material_override = meadow_mat
	ground.position = pos
	ground.position.y = 0.11
	add_child(ground)

	# Blumen verstreuen
	for j in range(rng.randi_range(8, 20)):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0, radius * 0.9)
		var flower_pos: Vector3 = pos + Vector3(cos(angle) * dist, 0.12, sin(angle) * dist)
		_create_flower(flower_pos)

	# Grasbüschel
	for j in range(rng.randi_range(4, 8)):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0, radius * 0.8)
		var tuft_pos: Vector3 = pos + Vector3(cos(angle) * dist, 0.1, sin(angle) * dist)
		_create_grass_tuft(tuft_pos)


# === SAND-BEREICHE ===
func _generate_sand_patches() -> void:
	for i in range(sand_patch_count):
		var pos: Vector3 = _get_valid_pos(15.0)
		var radius: float = rng.randf_range(4.0, 9.0)
		_create_sand_patch(pos, radius)


func _create_sand_patch(pos: Vector3, radius: float) -> void:
	# Sandfarbene Bodenfläche
	var ground := MeshInstance3D.new()
	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = radius
	ground_mesh.bottom_radius = radius + 0.3
	ground_mesh.height = 0.05
	ground.mesh = ground_mesh
	ground.material_override = sand_mat
	ground.position = pos
	ground.position.y = 0.11
	add_child(ground)

	# Kleine Steine auf dem Sand
	for j in range(rng.randi_range(3, 7)):
		var angle: float = rng.randf() * TAU
		var dist: float = rng.randf_range(0, radius * 0.8)
		var stone_pos: Vector3 = pos + Vector3(cos(angle) * dist, 0.1, sin(angle) * dist)
		_create_stone(stone_pos, rng.randf_range(0.08, 0.2))


# === STRÄUCHER ===
func _generate_bushes() -> void:
	for i in range(bush_count):
		var pos: Vector3 = _get_valid_pos(8.0)
		pos.y = 0.0
		_create_bush(pos)


func _create_bush(pos: Vector3) -> void:
	var bush_size: float = rng.randf_range(0.4, 1.0)

	# Hauptkugel
	var bush := MeshInstance3D.new()
	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = bush_size
	bush_mesh.height = bush_size * 1.5
	bush.mesh = bush_mesh
	bush.material_override = bush_mats[rng.randi() % bush_mats.size()]
	bush.position = pos
	bush.position.y = bush_size * 0.5
	add_child(bush)

	# Keine zweite Kugel (Z-Fighting vermeiden)

	# Kollision
	var body := StaticBody3D.new()
	body.position = pos
	body.position.y = bush_size * 0.5
	var col := CollisionShape3D.new()
	var col_shape := SphereShape3D.new()
	col_shape.radius = bush_size * 0.8
	col.shape = col_shape
	body.add_child(col)
	add_child(body)


# === STEINE (verstreut) ===
func _generate_rocks() -> void:
	for i in range(30):
		var pos: Vector3 = _get_valid_pos(6.0)
		_create_stone(pos, rng.randf_range(0.15, 0.5))


# === Hilfsfunktionen ===

func _create_stone(pos: Vector3, size: float) -> void:
	var stone := MeshInstance3D.new()
	var stone_mesh := BoxMesh.new()
	stone_mesh.size = Vector3(size * 1.3, size, size * 1.1)
	stone.mesh = stone_mesh
	stone.material_override = rock_mat
	stone.position = pos
	stone.position.y = size * 0.4
	stone.rotation.y = rng.randf() * TAU
	stone.rotation.x = rng.randf_range(-0.2, 0.2)
	add_child(stone)


func _create_grass_tuft(pos: Vector3) -> void:
	# 3-5 dünne grüne Halme
	var blade_count: int = rng.randi_range(3, 5)
	for k in range(blade_count):
		var blade := MeshInstance3D.new()
		var blade_mesh := BoxMesh.new()
		blade_mesh.size = Vector3(0.03, rng.randf_range(0.2, 0.5), 0.01)
		blade.mesh = blade_mesh
		blade.material_override = grass_mat
		blade.position = pos + Vector3(rng.randf_range(-0.1, 0.1), blade_mesh.size.y * 0.5, rng.randf_range(-0.1, 0.1))
		blade.rotation.y = rng.randf() * TAU
		blade.rotation.z = rng.randf_range(-0.3, 0.3)
		add_child(blade)


func _create_flower(pos: Vector3) -> void:
	# Stiel
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	var height: float = rng.randf_range(0.15, 0.3)
	stem_mesh.top_radius = 0.01
	stem_mesh.bottom_radius = 0.015
	stem_mesh.height = height
	stem.mesh = stem_mesh
	stem.material_override = grass_mat
	stem.position = pos
	stem.position.y = height * 0.5
	add_child(stem)

	# Blüte
	var flower := MeshInstance3D.new()
	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = rng.randf_range(0.04, 0.08)
	flower_mesh.height = flower_mesh.radius * 1.5
	flower.mesh = flower_mesh
	flower.material_override = flower_mats[rng.randi() % flower_mats.size()]
	flower.position = pos
	flower.position.y = height + flower_mesh.radius * 0.3
	add_child(flower)


func _create_reed(pos: Vector3) -> void:
	# Schilfhalm (dünn, hoch)
	for k in range(rng.randi_range(2, 4)):
		var reed := MeshInstance3D.new()
		var reed_mesh := CylinderMesh.new()
		var height: float = rng.randf_range(0.5, 1.0)
		reed_mesh.top_radius = 0.01
		reed_mesh.bottom_radius = 0.02
		reed_mesh.height = height
		reed.mesh = reed_mesh
		reed.material_override = dark_grass_mat
		reed.position = pos + Vector3(rng.randf_range(-0.1, 0.1), height * 0.5, rng.randf_range(-0.1, 0.1))
		reed.rotation.z = rng.randf_range(-0.1, 0.1)
		add_child(reed)

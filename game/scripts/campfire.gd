extends StaticBody3D

# Lagerfeuer mit Holzscheiten, Steinen und Flammen-Effekt

@export var safe_radius: float = 8.0
@export var light_range: float = 12.0

# Referenzen
@onready var light: OmniLight3D = $OmniLight3D
@onready var safe_zone: Area3D = $SafeZone
@onready var particles: GPUParticles3D = $GPUParticles3D

# Flacker-Effekt
var base_light_energy: float = 2.0
var flicker_timer: float = 0.0

# Materialien
var log_mat: StandardMaterial3D
var stone_mat: StandardMaterial3D
var ember_mat: StandardMaterial3D


func _ready() -> void:
	safe_zone.body_entered.connect(_on_body_entered)
	safe_zone.body_exited.connect(_on_body_exited)

	if light:
		light.omni_range = light_range
		light.light_energy = base_light_energy
		light.light_color = Color(1.0, 0.7, 0.3)

	_create_materials()
	_build_fire_pit()


func _process(delta: float) -> void:
	# Flacker-Effekt für das Licht
	flicker_timer += delta * 8.0
	if light:
		light.light_energy = base_light_energy + sin(flicker_timer) * 0.3 + sin(flicker_timer * 2.3) * 0.15


func _create_materials() -> void:
	log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.35, 0.2, 0.1, 1)

	stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.3, 0.3, 0.32, 1)

	ember_mat = StandardMaterial3D.new()
	ember_mat.albedo_color = Color(0.8, 0.3, 0.05, 1)
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(1.0, 0.4, 0.1, 1)
	ember_mat.emission_energy_multiplier = 2.0


func _build_fire_pit() -> void:
	# Steinkreis um das Feuer
	var stone_count: int = 8
	for i in range(stone_count):
		var angle: float = (float(i) / stone_count) * TAU
		var stone := MeshInstance3D.new()
		var stone_mesh := BoxMesh.new()
		stone_mesh.size = Vector3(0.4, 0.25, 0.35)
		stone.mesh = stone_mesh
		stone.material_override = stone_mat
		stone.position = Vector3(cos(angle) * 0.8, 0.12, sin(angle) * 0.8)
		stone.rotation.y = angle + 0.3
		add_child(stone)

	# Holzscheite im Feuer (wie im Screenshot: übereinander gestapelt)
	_add_fire_log(Vector3(-0.2, 0.15, -0.1), 0.5, 0.12, 0.3)
	_add_fire_log(Vector3(0.15, 0.15, 0.15), 0.55, 0.11, -0.4)
	_add_fire_log(Vector3(0.0, 0.28, 0.0), 0.45, 0.10, 0.8)

	# Glühende Basis
	var ember := MeshInstance3D.new()
	var ember_mesh := CylinderMesh.new()
	ember_mesh.top_radius = 0.5
	ember_mesh.bottom_radius = 0.6
	ember_mesh.height = 0.08
	ember.mesh = ember_mesh
	ember.material_override = ember_mat
	ember.position.y = 0.04
	add_child(ember)

	# Verstreute Holzscheite um das Lagerfeuer (wie im Screenshot)
	_add_ground_log(Vector3(-2.5, 0.15, -1.0), 1.5, 0.18, 0.6)
	_add_ground_log(Vector3(-2.0, 0.15, -0.5), 1.3, 0.16, 1.2)
	_add_ground_log(Vector3(2.0, 0.15, 1.5), 1.6, 0.2, -0.3)
	_add_ground_log(Vector3(1.5, 0.15, 2.2), 1.2, 0.15, 0.9)

	# Große Steinplattform (wie im Screenshot: dunkelgrauer Felsblock)
	var rock_mat := StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.22, 0.22, 0.24, 1)

	var rock_base := MeshInstance3D.new()
	var rock_mesh := BoxMesh.new()
	rock_mesh.size = Vector3(2.5, 0.8, 2.0)
	rock_base.mesh = rock_mesh
	rock_base.material_override = rock_mat
	rock_base.position = Vector3(3.0, 0.4, -1.0)
	add_child(rock_base)

	# Zweite Stufe auf dem Felsen
	var rock_top := MeshInstance3D.new()
	var rock_top_mesh := BoxMesh.new()
	rock_top_mesh.size = Vector3(1.8, 0.5, 1.4)
	rock_top.mesh = rock_top_mesh
	rock_top.material_override = rock_mat
	rock_top.position = Vector3(3.0, 1.05, -0.8)
	add_child(rock_top)

	# Fels-Kollision
	var rock_col := CollisionShape3D.new()
	var rock_shape := BoxShape3D.new()
	rock_shape.size = Vector3(2.5, 0.8, 2.0)
	rock_col.shape = rock_shape
	rock_col.position = Vector3(3.0, 0.4, -1.0)
	add_child(rock_col)


func _add_fire_log(pos: Vector3, length: float, radius: float, rot_y: float) -> void:
	var log := MeshInstance3D.new()
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = radius * 0.9
	log_mesh.bottom_radius = radius
	log_mesh.height = length
	log.mesh = log_mesh
	log.material_override = log_mat
	log.position = pos
	log.rotation = Vector3(0, rot_y, PI / 2.0)  # Auf der Seite liegend
	add_child(log)


func _add_ground_log(pos: Vector3, length: float, radius: float, rot_y: float) -> void:
	var log := MeshInstance3D.new()
	var log_mesh := CylinderMesh.new()
	log_mesh.top_radius = radius * 0.85
	log_mesh.bottom_radius = radius
	log_mesh.height = length
	log.mesh = log_mesh
	log.material_override = log_mat
	log.position = pos
	log.rotation = Vector3(0, rot_y, PI / 2.0)  # Auf der Seite liegend
	add_child(log)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("_on_safe_zone_entered"):
		body._on_safe_zone_entered()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("_on_safe_zone_exited"):
		body._on_safe_zone_exited()

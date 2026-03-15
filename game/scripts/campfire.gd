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
	# Safe-Area-Markierung am Boden (gestrichelte Linie wie im Roblox-Vorbild)
	_build_safe_zone_circle()

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

	# Werkbank neben dem Lagerfeuer
	_build_workbench()


func _build_workbench() -> void:
	var bench_wood := StandardMaterial3D.new()
	bench_wood.albedo_color = Color(0.45, 0.28, 0.14, 1)

	var bench_dark := StandardMaterial3D.new()
	bench_dark.albedo_color = Color(0.3, 0.18, 0.1, 1)

	var bench_top_mat := StandardMaterial3D.new()
	bench_top_mat.albedo_color = Color(0.5, 0.35, 0.18, 1)

	# Tischplatte
	var top := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(1.8, 0.12, 1.2)
	top.mesh = top_mesh
	top.material_override = bench_top_mat
	top.position = Vector3(-3.5, 0.85, 1.5)
	add_child(top)

	# 4 Beine
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.8, 0.1)
	var leg_positions := [
		Vector3(-4.25, 0.4, 0.95),
		Vector3(-2.75, 0.4, 0.95),
		Vector3(-4.25, 0.4, 2.05),
		Vector3(-2.75, 0.4, 2.05),
	]
	for lp in leg_positions:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.material_override = bench_dark
		leg.position = lp
		add_child(leg)

	# Querstreben (Stabilität)
	var brace_mesh := BoxMesh.new()
	brace_mesh.size = Vector3(1.5, 0.06, 0.06)
	var brace1 := MeshInstance3D.new()
	brace1.mesh = brace_mesh
	brace1.material_override = bench_dark
	brace1.position = Vector3(-3.5, 0.25, 0.95)
	add_child(brace1)

	var brace2 := MeshInstance3D.new()
	brace2.mesh = brace_mesh
	brace2.material_override = bench_dark
	brace2.position = Vector3(-3.5, 0.25, 2.05)
	add_child(brace2)

	# Werkzeuge auf der Bank
	# Hammer
	var hammer_handle := MeshInstance3D.new()
	var hh_mesh := CylinderMesh.new()
	hh_mesh.top_radius = 0.02
	hh_mesh.bottom_radius = 0.025
	hh_mesh.height = 0.3
	hammer_handle.mesh = hh_mesh
	hammer_handle.material_override = bench_dark
	hammer_handle.position = Vector3(-3.8, 0.96, 1.3)
	hammer_handle.rotation.z = PI / 2.0
	add_child(hammer_handle)

	var hammer_head := MeshInstance3D.new()
	var hhead_mesh := BoxMesh.new()
	hhead_mesh.size = Vector3(0.12, 0.06, 0.06)
	hammer_head.mesh = hhead_mesh
	hammer_head.material_override = stone_mat
	hammer_head.position = Vector3(-3.95, 0.96, 1.3)
	add_child(hammer_head)

	# Holzplanken (gestapelt)
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.55, 0.38, 0.2, 1)

	var plank_mesh := BoxMesh.new()
	plank_mesh.size = Vector3(0.6, 0.04, 0.2)
	for i in range(3):
		var plank := MeshInstance3D.new()
		plank.mesh = plank_mesh
		plank.material_override = plank_mat
		plank.position = Vector3(-3.2, 0.93 + i * 0.04, 1.7)
		plank.rotation.y = 0.15 * i
		add_child(plank)

	# Säge (kleines Blatt)
	var saw_mat := StandardMaterial3D.new()
	saw_mat.albedo_color = Color(0.6, 0.6, 0.62, 1)
	var saw := MeshInstance3D.new()
	var saw_mesh := BoxMesh.new()
	saw_mesh.size = Vector3(0.35, 0.15, 0.01)
	saw.mesh = saw_mesh
	saw.material_override = saw_mat
	saw.position = Vector3(-3.5, 0.96, 1.85)
	saw.rotation.z = 0.1
	add_child(saw)

	# Kollision für die Werkbank
	var bench_col := CollisionShape3D.new()
	var bench_shape := BoxShape3D.new()
	bench_shape.size = Vector3(1.8, 0.95, 1.2)
	bench_col.shape = bench_shape
	bench_col.position = Vector3(-3.5, 0.47, 1.5)
	add_child(bench_col)

	# Werkbank-Interaktionszone (Area3D)
	var interact := Area3D.new()
	interact.name = "WorkbenchZone"
	var interact_col := CollisionShape3D.new()
	var interact_shape := SphereShape3D.new()
	interact_shape.radius = 3.0
	interact_col.shape = interact_shape
	interact_col.position = Vector3(-3.5, 1.0, 1.5)
	interact.add_child(interact_col)
	interact.body_entered.connect(_on_workbench_entered)
	interact.body_exited.connect(_on_workbench_exited)
	add_child(interact)

	# Schild über der Werkbank
	var sign_post := MeshInstance3D.new()
	var sign_mesh := CylinderMesh.new()
	sign_mesh.top_radius = 0.03
	sign_mesh.bottom_radius = 0.04
	sign_mesh.height = 1.2
	sign_post.mesh = sign_mesh
	sign_post.material_override = bench_dark
	sign_post.position = Vector3(-4.5, 0.6, 1.5)
	add_child(sign_post)

	var sign_board := MeshInstance3D.new()
	var sign_board_mesh := BoxMesh.new()
	sign_board_mesh.size = Vector3(0.6, 0.3, 0.04)
	sign_board.mesh = sign_board_mesh
	sign_board.material_override = bench_top_mat
	sign_board.position = Vector3(-4.5, 1.3, 1.5)
	add_child(sign_board)


func _build_safe_zone_circle() -> void:
	# Gestrichelter Kreis am Boden der die Safe Area anzeigt
	var circle_mat := StandardMaterial3D.new()
	circle_mat.albedo_color = Color(0.5, 0.65, 0.35, 0.6)
	circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var dash_count: int = 24
	for i in range(dash_count):
		var angle: float = (float(i) / dash_count) * TAU
		var dash := MeshInstance3D.new()
		var dash_mesh := BoxMesh.new()
		dash_mesh.size = Vector3(1.2, 0.03, 0.25)
		dash.mesh = dash_mesh
		dash.material_override = circle_mat
		dash.position = Vector3(cos(angle) * safe_radius, 0.12, sin(angle) * safe_radius)
		dash.rotation.y = angle + PI / 2.0
		add_child(dash)


var player_near_workbench: bool = false

signal workbench_entered()
signal workbench_exited()


func _on_workbench_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_workbench = true
		workbench_entered.emit()


func _on_workbench_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_near_workbench = false
		workbench_exited.emit()


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

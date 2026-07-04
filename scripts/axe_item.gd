extends Node3D

# Axt-Gegenstand: verschiedene Stärken, prozedurales 3D-Modell
#
# Stufen:
#   STEIN  = schwach, langsam, graue Klinge
#   EISEN  = mittel, silberne Klinge
#   STAHL  = stark, schnell, dunkle Klinge

enum AxeTier { STEIN, EISEN, STAHL }

var tier: int = AxeTier.STEIN

# Stärke-Werte pro Stufe
var axe_strength: float = 1.0
var chop_cooldown_time: float = 1.2  # Sekunden zwischen Hieben

# Visuals
var handle_mesh: MeshInstance3D
var blade_mesh: MeshInstance3D

# Materialien
var handle_mat: StandardMaterial3D
var blade_mat: StandardMaterial3D


func _ready() -> void:
	_apply_tier()
	_build_axe()


func set_tier(new_tier: int) -> void:
	tier = new_tier
	_apply_tier()


func _apply_tier() -> void:
	match tier:
		AxeTier.STEIN:
			axe_strength = 1.0
			chop_cooldown_time = 1.0
		AxeTier.EISEN:
			axe_strength = 2.5
			chop_cooldown_time = 0.7
		AxeTier.STAHL:
			axe_strength = 5.0
			chop_cooldown_time = 0.45


func _build_axe() -> void:
	# Materialien
	handle_mat = StandardMaterial3D.new()
	handle_mat.albedo_color = Color(0.4, 0.25, 0.12, 1)

	blade_mat = StandardMaterial3D.new()
	match tier:
		AxeTier.STEIN:
			blade_mat.albedo_color = Color(0.5, 0.48, 0.45, 1)
		AxeTier.EISEN:
			blade_mat.albedo_color = Color(0.7, 0.7, 0.72, 1)
		AxeTier.STAHL:
			blade_mat.albedo_color = Color(0.3, 0.3, 0.35, 1)

	# Stiel
	handle_mesh = MeshInstance3D.new()
	var h_mesh := BoxMesh.new()
	h_mesh.size = Vector3(0.04, 0.5, 0.04)
	handle_mesh.mesh = h_mesh
	handle_mesh.material_override = handle_mat
	handle_mesh.position = Vector3(0, -0.15, 0)
	add_child(handle_mesh)

	# Klinge (oben am Stiel, seitlich)
	blade_mesh = MeshInstance3D.new()
	var b_mesh := BoxMesh.new()
	b_mesh.size = Vector3(0.18, 0.14, 0.04)
	blade_mesh.mesh = b_mesh
	blade_mesh.material_override = blade_mat
	blade_mesh.position = Vector3(0.1, 0.12, 0)
	add_child(blade_mesh)

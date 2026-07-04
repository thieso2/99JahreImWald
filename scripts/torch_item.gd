extends Node3D

# Fackel-Gegenstand: Sichtbar in der Hand mit Licht und Flammen-Effekt

var torch_light: OmniLight3D = null
var flicker_timer: float = 0.0
var base_energy: float = 1.8

# Materialien
var stick_mat: StandardMaterial3D
var flame_mat: StandardMaterial3D


func _ready() -> void:
	_build_torch()


func _process(delta: float) -> void:
	# Flacker-Effekt
	flicker_timer += delta * 10.0
	if torch_light:
		torch_light.light_energy = base_energy + sin(flicker_timer) * 0.3 + sin(flicker_timer * 2.7) * 0.15


func _build_torch() -> void:
	# Stiel
	stick_mat = StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.4, 0.25, 0.12, 1)

	var stick := MeshInstance3D.new()
	var stick_mesh := CylinderMesh.new()
	stick_mesh.top_radius = 0.025
	stick_mesh.bottom_radius = 0.03
	stick_mesh.height = 0.55
	stick.mesh = stick_mesh
	stick.material_override = stick_mat
	stick.position = Vector3(0, -0.1, 0)
	add_child(stick)

	# Flammen-Kopf (leuchtend)
	flame_mat = StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.6, 0.1, 1)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.5, 0.05, 1)
	flame_mat.emission_energy_multiplier = 3.0

	var flame := MeshInstance3D.new()
	var flame_mesh := SphereMesh.new()
	flame_mesh.radius = 0.06
	flame_mesh.height = 0.15
	flame.mesh = flame_mesh
	flame.material_override = flame_mat
	flame.position = Vector3(0, 0.2, 0)
	add_child(flame)

	# Zweite Flamme (größer, transparenter)
	var flame_mat2 := StandardMaterial3D.new()
	flame_mat2.albedo_color = Color(1.0, 0.4, 0.05, 0.6)
	flame_mat2.emission_enabled = true
	flame_mat2.emission = Color(1.0, 0.4, 0.05, 1)
	flame_mat2.emission_energy_multiplier = 2.0
	flame_mat2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	var flame2 := MeshInstance3D.new()
	var flame_mesh2 := SphereMesh.new()
	flame_mesh2.radius = 0.09
	flame_mesh2.height = 0.2
	flame2.mesh = flame_mesh2
	flame2.material_override = flame_mat2
	flame2.position = Vector3(0, 0.25, 0)
	add_child(flame2)

	# Licht
	torch_light = OmniLight3D.new()
	torch_light.light_color = Color(1.0, 0.7, 0.3)
	torch_light.light_energy = base_energy
	torch_light.omni_range = 10.0
	torch_light.shadow_enabled = true
	torch_light.position = Vector3(0, 0.25, 0)
	add_child(torch_light)

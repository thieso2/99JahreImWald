extends StaticBody3D

# Eingepflanzter Setzling – wächst langsam zu einem vollen Baum heran
#
# Wachstumsphasen:
#   0.0 = gerade gepflanzt (kleiner Trieb)
#   0.5 = junger Baum (dünner Stamm, kleine Krone)
#   1.0 = ausgewachsen (voller Baum, kann gefällt werden)

@export var grow_duration: float = 120.0  # Sekunden bis ausgewachsen

var growth: float = 0.0  # 0.0 bis 1.0
var fully_grown: bool = false

# Visuals
var trunk_mesh: MeshInstance3D = null
var leaves_mesh: MeshInstance3D = null
var sprout_mesh: MeshInstance3D = null

# Materialien
var trunk_mat: StandardMaterial3D
var leaves_mat: StandardMaterial3D
var sprout_mat: StandardMaterial3D

# Zielgrößen (ausgewachsener Baum)
var target_trunk_height: float = 6.0
var target_trunk_bottom_radius: float = 0.45
var target_trunk_top_radius: float = 0.35
var target_crown_radius: float = 2.5


func _ready() -> void:
	add_to_group("tree")

	_create_materials()
	_build_sapling()


func _process(delta: float) -> void:
	if fully_grown:
		return

	growth += delta / grow_duration
	if growth >= 1.0:
		growth = 1.0
		fully_grown = true
		_convert_to_full_tree()
		return

	_update_growth()


func _create_materials() -> void:
	trunk_mat = StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.22, 0.12, 1)

	leaves_mat = StandardMaterial3D.new()
	leaves_mat.albedo_color = Color(0.1, 0.36, 0.08, 1)

	sprout_mat = StandardMaterial3D.new()
	sprout_mat.albedo_color = Color(0.2, 0.55, 0.15, 1)


func _build_sapling() -> void:
	# Kleiner grüner Trieb (sichtbar in frühen Phasen)
	sprout_mesh = MeshInstance3D.new()
	var s_mesh := CylinderMesh.new()
	s_mesh.top_radius = 0.02
	s_mesh.bottom_radius = 0.03
	s_mesh.height = 0.3
	sprout_mesh.mesh = s_mesh
	sprout_mesh.material_override = sprout_mat
	sprout_mesh.position.y = 0.15
	sprout_mesh.name = "Sprout"
	add_child(sprout_mesh)

	# Kleine Blätter am Trieb
	var leaf := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.1
	leaf_mesh.height = 0.08
	leaf.mesh = leaf_mesh
	leaf.material_override = sprout_mat
	leaf.position.y = 0.18
	sprout_mesh.add_child(leaf)

	# Stamm (anfangs unsichtbar, wächst mit)
	trunk_mesh = MeshInstance3D.new()
	trunk_mesh.name = "MeshInstance3D"
	var t_mesh := CylinderMesh.new()
	t_mesh.top_radius = 0.02
	t_mesh.bottom_radius = 0.03
	t_mesh.height = 0.1
	trunk_mesh.mesh = t_mesh
	trunk_mesh.material_override = trunk_mat
	trunk_mesh.position.y = 0.05
	trunk_mesh.visible = false
	add_child(trunk_mesh)

	# Krone (anfangs unsichtbar)
	leaves_mesh = MeshInstance3D.new()
	leaves_mesh.name = "Leaves"
	var l_mesh := SphereMesh.new()
	l_mesh.radius = 0.1
	l_mesh.height = 0.08
	leaves_mesh.mesh = l_mesh
	leaves_mesh.material_override = leaves_mat
	leaves_mesh.position.y = 0.2
	leaves_mesh.visible = false
	add_child(leaves_mesh)


func _update_growth() -> void:
	# Phase 1 (0-0.3): Trieb wächst
	if growth < 0.3:
		var t: float = growth / 0.3
		var sprout_height: float = 0.3 + t * 0.5
		sprout_mesh.scale = Vector3(1.0 + t, 1.0 + t * 2.0, 1.0 + t)
		sprout_mesh.position.y = sprout_height * 0.5

	# Phase 2 (0.3-1.0): Stamm und Krone wachsen
	elif growth >= 0.3:
		var t: float = (growth - 0.3) / 0.7

		# Trieb einblenden -> Stamm
		sprout_mesh.visible = t < 0.3

		# Stamm sichtbar machen und wachsen lassen
		trunk_mesh.visible = true
		var current_height: float = lerp(0.5, target_trunk_height, t)
		var current_bottom: float = lerp(0.03, target_trunk_bottom_radius, t)
		var current_top: float = lerp(0.02, target_trunk_top_radius, t)

		var t_mesh := CylinderMesh.new()
		t_mesh.top_radius = current_top
		t_mesh.bottom_radius = current_bottom
		t_mesh.height = current_height
		trunk_mesh.mesh = t_mesh
		trunk_mesh.position.y = current_height / 2.0

		# Krone sichtbar machen und wachsen lassen
		leaves_mesh.visible = t > 0.1
		if t > 0.1:
			var crown_t: float = (t - 0.1) / 0.9
			var current_crown: float = lerp(0.2, target_crown_radius, crown_t)
			var l_mesh := SphereMesh.new()
			l_mesh.radius = current_crown
			l_mesh.height = current_crown * 1.2
			leaves_mesh.mesh = l_mesh
			leaves_mesh.position.y = current_height + current_crown * 0.3


func _convert_to_full_tree() -> void:
	# Trieb entfernen
	if sprout_mesh:
		sprout_mesh.queue_free()
		sprout_mesh = null

	# Stamm auf Endgröße setzen
	var t_mesh := CylinderMesh.new()
	t_mesh.top_radius = target_trunk_top_radius
	t_mesh.bottom_radius = target_trunk_bottom_radius
	t_mesh.height = target_trunk_height
	trunk_mesh.mesh = t_mesh
	trunk_mesh.material_override = trunk_mat
	trunk_mesh.position.y = target_trunk_height / 2.0
	trunk_mesh.visible = true

	# Krone auf Endgröße
	var l_mesh := SphereMesh.new()
	l_mesh.radius = target_crown_radius
	l_mesh.height = target_crown_radius * 1.2
	leaves_mesh.mesh = l_mesh
	leaves_mesh.material_override = leaves_mat
	leaves_mesh.position.y = target_trunk_height + target_crown_radius * 0.3
	leaves_mesh.visible = true

	# Kollision hinzufügen (jetzt fällbar)
	var col := CollisionShape3D.new()
	var col_shape := CylinderShape3D.new()
	col_shape.radius = target_trunk_bottom_radius + 0.1
	col_shape.height = target_trunk_height
	col.shape = col_shape
	col.position.y = target_trunk_height / 2.0
	add_child(col)

	# tree_resource-Script zuweisen, damit der Baum fällbar wird
	var tree_script: GDScript = preload("res://scripts/tree_resource.gd")
	set_script(tree_script)
	# tree_scale_factor für mittlere Größe
	tree_scale_factor = 1.0

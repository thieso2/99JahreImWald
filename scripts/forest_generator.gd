extends Node3D

# Wald-Generator – erzeugt prozedural einen dichten Wald

@export var tree_count: int = 300
@export var forest_radius: float = 80.0
@export var min_distance_from_camp: float = 10.0
@export var min_distance_between_trees: float = 4.5
@export var tree_scale_min: float = 0.7
@export var tree_scale_max: float = 1.4

# Materialien (werden einmal erstellt und geteilt)
var trunk_material: StandardMaterial3D
var leaves_materials: Array[StandardMaterial3D] = []

# Baum-Script
var tree_script: GDScript

# Gesetzte Baum-Positionen (für Mindestabstand)
var placed_positions: Array[Vector3] = []


func _ready() -> void:
	# Materialien vorbereiten – Stämme mit echter Rinden-Textur (CC0)
	trunk_material = StandardMaterial3D.new()
	trunk_material.albedo_texture = preload("res://assets/textures/bark_color.jpg")
	trunk_material.albedo_color = Color(1.0, 0.85, 0.7, 1)
	trunk_material.normal_enabled = true
	trunk_material.normal_texture = preload("res://assets/textures/bark_normal.jpg")
	trunk_material.roughness = 0.95
	trunk_material.uv1_triplanar = true
	trunk_material.uv1_world_triplanar = true
	trunk_material.uv1_scale = Vector3(0.8, 0.8, 0.8)

	# Mischung aus Grün und Grau-Grün (wie im Roblox-Vorbild)
	var green_colors := [
		Color(0.2, 0.45, 0.18, 1),
		Color(0.25, 0.5, 0.2, 1),
		Color(0.18, 0.4, 0.22, 1),
		Color(0.35, 0.42, 0.3, 1),   # Grau-grün
		Color(0.3, 0.38, 0.28, 1),   # Grau-grün
	]
	for color in green_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		leaves_materials.append(mat)

	tree_script = preload("res://scripts/tree_resource.gd")

	# Wald generieren
	_generate_forest()


func _generate_forest() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # Fester Seed für konsistenten Wald

	var trees_placed := 0
	var max_attempts := tree_count * 5

	for attempt in range(max_attempts):
		if trees_placed >= tree_count:
			break

		# Zufällige Position im Kreis
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(min_distance_from_camp, forest_radius)
		var pos := Vector3(cos(angle) * dist, 0, sin(angle) * dist)

		# Mindestabstand zum Camp prüfen
		if pos.length() < min_distance_from_camp:
			continue

		# Mindestabstand zu anderen Bäumen prüfen
		var too_close := false
		for placed_pos in placed_positions:
			if pos.distance_to(placed_pos) < min_distance_between_trees:
				too_close = true
				break
		if too_close:
			continue

		# Baum erstellen
		var tree := _create_tree(rng)
		tree.position = pos
		var s := rng.randf_range(tree_scale_min, tree_scale_max)
		tree.tree_scale_factor = s
		tree.scale = Vector3(s, s, s)
		# Leichte zufällige Rotation für natürlicheren Look
		tree.rotation.y = rng.randf() * TAU

		add_child(tree)
		placed_positions.append(pos)
		trees_placed += 1


func _create_tree(rng: RandomNumberGenerator) -> StaticBody3D:
	var tree := StaticBody3D.new()
	tree.add_to_group("tree")
	tree.set_script(tree_script)

	# Stamm – dick und hoch wie im Roblox-Vorbild
	var trunk_mesh_instance := MeshInstance3D.new()
	trunk_mesh_instance.name = "MeshInstance3D"
	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = rng.randf_range(0.3, 0.45)
	trunk_mesh.bottom_radius = rng.randf_range(0.4, 0.6)
	trunk_mesh.height = rng.randf_range(5.0, 8.0)
	trunk_mesh_instance.mesh = trunk_mesh
	trunk_mesh_instance.material_override = trunk_material
	trunk_mesh_instance.position.y = trunk_mesh.height / 2.0
	tree.add_child(trunk_mesh_instance)

	# Blätterkrone – blockig wie im Roblox-Vorbild
	var crown_mat: StandardMaterial3D = leaves_materials[rng.randi() % leaves_materials.size()]

	# Hauptkrone (große Box, leicht abgerundet wirkend)
	var crown_width: float = rng.randf_range(3.0, 5.0)
	var crown_height: float = rng.randf_range(2.5, 4.0)
	var crown_depth: float = rng.randf_range(3.0, 5.0)

	var leaves_mesh_instance := MeshInstance3D.new()
	leaves_mesh_instance.name = "Leaves"
	var leaves_mesh := BoxMesh.new()
	leaves_mesh.size = Vector3(crown_width, crown_height, crown_depth)
	leaves_mesh_instance.mesh = leaves_mesh
	leaves_mesh_instance.material_override = crown_mat
	leaves_mesh_instance.position.y = trunk_mesh.height + crown_height * 0.4
	tree.add_child(leaves_mesh_instance)

	# Zweite kleinere Box oben drauf (für mehr Volumen)
	var top_leaves := MeshInstance3D.new()
	var top_mesh := BoxMesh.new()
	top_mesh.size = Vector3(crown_width * 0.7, crown_height * 0.5, crown_depth * 0.7)
	top_leaves.mesh = top_mesh
	top_leaves.material_override = crown_mat
	top_leaves.position.y = trunk_mesh.height + crown_height * 0.85
	top_leaves.rotation.y = rng.randf_range(-0.3, 0.3)
	tree.add_child(top_leaves)

	# Kollision (Stamm)
	var collision := CollisionShape3D.new()
	var col_shape := CylinderShape3D.new()
	col_shape.radius = trunk_mesh.bottom_radius + 0.1
	col_shape.height = trunk_mesh.height
	collision.shape = col_shape
	collision.position.y = trunk_mesh.height / 2.0
	tree.add_child(collision)

	# Interaktions-Area
	var interact_area := Area3D.new()
	interact_area.name = "InteractArea"
	var interact_collision := CollisionShape3D.new()
	var interact_shape := SphereShape3D.new()
	interact_shape.radius = 4.0
	interact_collision.shape = interact_shape
	interact_collision.position.y = 1.5
	interact_area.add_child(interact_collision)
	tree.add_child(interact_area)

	return tree

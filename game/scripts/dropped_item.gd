extends Area3D

# Gedropptes Item: Holzscheit oder Setzling
# Fliegt kurz durch die Luft, landet auf dem Boden, wird aufgesammelt bei Berührung

enum ItemType { LOG, SAPLING }

var item_type: int = ItemType.LOG

# Physik-Simulation (kein RigidBody, einfache Berechnung)
var fly_velocity: Vector3 = Vector3.ZERO
var on_ground: bool = false
var lifetime: float = 0.0
var bob_offset: float = 0.0

# Materialien
var log_mat: StandardMaterial3D
var sapling_mat: StandardMaterial3D
var pot_mat: StandardMaterial3D


func _ready() -> void:
	# Kollision für Auto-Pickup
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0
	col.shape = shape
	col.position.y = 0.5
	add_child(col)

	body_entered.connect(_on_body_entered)

	_build_mesh()

	# Zufällige Flugrichtung
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	fly_velocity = Vector3(
		rng.randf_range(-2.0, 2.0),
		rng.randf_range(3.0, 5.0),
		rng.randf_range(-2.0, 2.0)
	)
	bob_offset = rng.randf() * TAU


func _process(delta: float) -> void:
	lifetime += delta

	if not on_ground:
		# Einfache Physik: fliegen + Schwerkraft
		fly_velocity.y -= 12.0 * delta
		position += fly_velocity * delta
		# Am Boden landen
		if position.y <= 0.2:
			position.y = 0.2
			on_ground = true
			fly_velocity = Vector3.ZERO
	else:
		# Leichtes Auf-und-Ab-Schweben wenn am Boden
		position.y = 0.2 + sin(lifetime * 2.0 + bob_offset) * 0.08
		# Langsam drehen
		rotation.y += delta * 1.5

	# Nach 60 Sekunden verschwinden
	if lifetime > 60.0:
		queue_free()


func _build_mesh() -> void:
	match item_type:
		ItemType.LOG:
			_build_log_mesh()
		ItemType.SAPLING:
			_build_sapling_mesh()


func _build_log_mesh() -> void:
	log_mat = StandardMaterial3D.new()
	log_mat.albedo_color = Color(0.4, 0.25, 0.12, 1)

	var log_mesh := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.08
	mesh.bottom_radius = 0.1
	mesh.height = 0.6
	log_mesh.mesh = mesh
	log_mesh.material_override = log_mat
	# Auf der Seite liegend
	log_mesh.rotation.z = PI / 2.0
	log_mesh.position.y = 0.1
	add_child(log_mesh)


func _build_sapling_mesh() -> void:
	# Kleiner Topf
	pot_mat = StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.5, 0.3, 0.15, 1)

	var pot := MeshInstance3D.new()
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.12
	pot_mesh.bottom_radius = 0.08
	pot_mesh.height = 0.15
	pot.mesh = pot_mesh
	pot.material_override = pot_mat
	pot.position.y = 0.08
	add_child(pot)

	# Kleiner grüner Trieb
	sapling_mat = StandardMaterial3D.new()
	sapling_mat.albedo_color = Color(0.15, 0.5, 0.12, 1)

	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.015
	stem_mesh.bottom_radius = 0.02
	stem_mesh.height = 0.2
	stem.mesh = stem_mesh
	stem.material_override = sapling_mat
	stem.position.y = 0.25
	add_child(stem)

	# Kleine Blätter oben
	var leaf := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.08
	leaf_mesh.height = 0.1
	leaf.mesh = leaf_mesh
	leaf.material_override = sapling_mat
	leaf.position.y = 0.38
	add_child(leaf)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		match item_type:
			ItemType.LOG:
				if body.has_method("add_wood"):
					body.add_wood(1)
			ItemType.SAPLING:
				if body.has_method("add_sapling"):
					body.add_sapling(1)
		queue_free()

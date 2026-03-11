extends Area3D

# Gedropptes Item: Holzscheit oder Setzling
# Fliegt durch die Luft, landet am Boden, muss mit E-Taste eingesammelt werden
# Sichtbar als kleiner Sack

enum ItemType { LOG, SAPLING }

var item_type: int = ItemType.LOG

# Physik-Simulation
var fly_velocity: Vector3 = Vector3.ZERO
var on_ground: bool = false
var lifetime: float = 0.0
var bob_offset: float = 0.0
var can_pickup: bool = false  # Erst nach Landung einsammelbar

# Materialien
var sack_mat: StandardMaterial3D
var tie_mat: StandardMaterial3D
var icon_mat: StandardMaterial3D


func _ready() -> void:
	# Kollision für Nähe-Erkennung
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.0  # Erkennungsradius
	col.shape = shape
	col.position.y = 0.3
	add_child(col)

	_build_sack_mesh()

	# Zufällige Flugrichtung
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	fly_velocity = Vector3(
		rng.randf_range(-2.5, 2.5),
		rng.randf_range(3.0, 5.0),
		rng.randf_range(-2.5, 2.5)
	)
	bob_offset = rng.randf() * TAU


func _process(delta: float) -> void:
	lifetime += delta

	if not on_ground:
		fly_velocity.y -= 12.0 * delta
		position += fly_velocity * delta
		# Rotation beim Fliegen
		rotation.x += delta * 3.0
		if position.y <= 0.25:
			position.y = 0.25
			on_ground = true
			can_pickup = true
			fly_velocity = Vector3.ZERO
			rotation.x = 0.0
	else:
		# Leichtes Schweben am Boden
		position.y = 0.25 + sin(lifetime * 2.0 + bob_offset) * 0.06
		rotation.y += delta * 0.8

	# Nach 90 Sekunden verschwinden
	if lifetime > 90.0:
		queue_free()


func try_pickup(body: Node3D) -> bool:
	# Wird vom GameManager aufgerufen wenn E gedrückt wird
	if not can_pickup:
		return false
	if not on_ground:
		return false

	var dist: float = body.global_position.distance_to(global_position)
	if dist > 2.5:
		return false

	match item_type:
		ItemType.LOG:
			if body.has_method("add_wood"):
				body.add_wood(1)
		ItemType.SAPLING:
			if body.has_method("add_sapling"):
				body.add_sapling(1)

	queue_free()
	return true


func _build_sack_mesh() -> void:
	# Sack-Farbe je nach Item-Typ
	sack_mat = StandardMaterial3D.new()
	match item_type:
		ItemType.LOG:
			sack_mat.albedo_color = Color(0.55, 0.35, 0.15, 1)  # Brauner Sack
		ItemType.SAPLING:
			sack_mat.albedo_color = Color(0.3, 0.5, 0.2, 1)  # Grüner Sack

	tie_mat = StandardMaterial3D.new()
	tie_mat.albedo_color = Color(0.35, 0.2, 0.1, 1)

	# Sack-Körper (abgerundete Box)
	var sack_body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.2
	body_mesh.height = 0.35
	sack_body.mesh = body_mesh
	sack_body.material_override = sack_mat
	sack_body.position.y = 0.18
	sack_body.name = "SackBody"
	add_child(sack_body)

	# Sack-Zipfel oben (zusammengebunden)
	var tie := MeshInstance3D.new()
	var tie_mesh := CylinderMesh.new()
	tie_mesh.top_radius = 0.02
	tie_mesh.bottom_radius = 0.06
	tie_mesh.height = 0.1
	tie.mesh = tie_mesh
	tie.material_override = tie_mat
	tie.position.y = 0.38
	add_child(tie)

	# Icon je nach Item-Typ
	match item_type:
		ItemType.LOG:
			_add_log_icon()
		ItemType.SAPLING:
			_add_sapling_icon()


func _add_log_icon() -> void:
	# Kleines Holzscheit oben auf dem Sack
	icon_mat = StandardMaterial3D.new()
	icon_mat.albedo_color = Color(0.4, 0.22, 0.1, 1)

	var log_icon := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.04
	mesh.bottom_radius = 0.05
	mesh.height = 0.25
	log_icon.mesh = mesh
	log_icon.material_override = icon_mat
	log_icon.rotation.z = PI / 4.0  # Schräg
	log_icon.position = Vector3(0.05, 0.42, 0)
	add_child(log_icon)


func _add_sapling_icon() -> void:
	# Kleiner Trieb oben auf dem Sack
	icon_mat = StandardMaterial3D.new()
	icon_mat.albedo_color = Color(0.15, 0.55, 0.12, 1)

	var stem := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = 0.015
	mesh.height = 0.12
	stem.mesh = mesh
	stem.material_override = icon_mat
	stem.position = Vector3(0, 0.45, 0)
	add_child(stem)

	var leaf := MeshInstance3D.new()
	var leaf_mesh := SphereMesh.new()
	leaf_mesh.radius = 0.05
	leaf_mesh.height = 0.04
	leaf.mesh = leaf_mesh
	leaf.material_override = icon_mat
	leaf.position = Vector3(0, 0.53, 0)
	add_child(leaf)

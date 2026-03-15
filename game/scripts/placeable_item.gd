extends StaticBody3D

# Platzierbares Item in der Welt (Bett, Zaun, Wand, Truhe)

var item_type: String = ""

# Materialien
var wood_mat: StandardMaterial3D
var dark_wood_mat: StandardMaterial3D
var fabric_mat: StandardMaterial3D
var metal_mat: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	match item_type:
		"bed":
			_build_bed()
		"fence":
			_build_fence()
		"wall":
			_build_wall()
		"chest":
			_build_chest()


func _create_materials() -> void:
	wood_mat = StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.5, 0.32, 0.16, 1)

	dark_wood_mat = StandardMaterial3D.new()
	dark_wood_mat.albedo_color = Color(0.35, 0.2, 0.1, 1)

	fabric_mat = StandardMaterial3D.new()
	fabric_mat.albedo_color = Color(0.6, 0.15, 0.12, 1)  # Rotes Bettlaken

	metal_mat = StandardMaterial3D.new()
	metal_mat.albedo_color = Color(0.4, 0.38, 0.35, 1)


func _build_bed() -> void:
	# Bettrahmen
	var frame := MeshInstance3D.new()
	var frame_mesh := BoxMesh.new()
	frame_mesh.size = Vector3(1.0, 0.15, 2.0)
	frame.mesh = frame_mesh
	frame.material_override = wood_mat
	frame.position = Vector3(0, 0.3, 0)
	add_child(frame)

	# 4 Beine
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.08, 0.25, 0.08)
	var leg_pos := [
		Vector3(-0.42, 0.12, -0.88),
		Vector3(0.42, 0.12, -0.88),
		Vector3(-0.42, 0.12, 0.88),
		Vector3(0.42, 0.12, 0.88),
	]
	for lp in leg_pos:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.material_override = dark_wood_mat
		leg.position = lp
		add_child(leg)

	# Matratze
	var mattress := MeshInstance3D.new()
	var matt_mesh := BoxMesh.new()
	matt_mesh.size = Vector3(0.9, 0.12, 1.8)
	mattress.mesh = matt_mesh
	mattress.material_override = fabric_mat
	mattress.position = Vector3(0, 0.44, 0)
	add_child(mattress)

	# Kissen
	var pillow_mat := StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(0.85, 0.82, 0.75, 1)
	var pillow := MeshInstance3D.new()
	var pillow_mesh := BoxMesh.new()
	pillow_mesh.size = Vector3(0.6, 0.1, 0.35)
	pillow.mesh = pillow_mesh
	pillow.material_override = pillow_mat
	pillow.position = Vector3(0, 0.52, 0.7)
	add_child(pillow)

	# Kopfteil
	var headboard := MeshInstance3D.new()
	var hb_mesh := BoxMesh.new()
	hb_mesh.size = Vector3(1.0, 0.5, 0.08)
	headboard.mesh = hb_mesh
	headboard.material_override = dark_wood_mat
	headboard.position = Vector3(0, 0.5, 0.97)
	add_child(headboard)

	# Kollision
	_add_collision(Vector3(1.0, 0.55, 2.0), Vector3(0, 0.28, 0))


func _build_fence() -> void:
	# 3 Pfosten
	var post_mesh := CylinderMesh.new()
	post_mesh.top_radius = 0.05
	post_mesh.bottom_radius = 0.06
	post_mesh.height = 1.2

	for i in range(3):
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.material_override = dark_wood_mat
		post.position = Vector3((i - 1) * 1.0, 0.6, 0)
		add_child(post)

		# Spitze oben
		var tip := MeshInstance3D.new()
		var tip_mesh := CylinderMesh.new()
		tip_mesh.top_radius = 0.01
		tip_mesh.bottom_radius = 0.05
		tip_mesh.height = 0.12
		tip.mesh = tip_mesh
		tip.material_override = wood_mat
		tip.position = Vector3((i - 1) * 1.0, 1.26, 0)
		add_child(tip)

	# 2 Querlatten
	var rail_mesh := BoxMesh.new()
	rail_mesh.size = Vector3(2.0, 0.08, 0.05)

	var rail1 := MeshInstance3D.new()
	rail1.mesh = rail_mesh
	rail1.material_override = wood_mat
	rail1.position = Vector3(0, 0.4, 0)
	add_child(rail1)

	var rail2 := MeshInstance3D.new()
	rail2.mesh = rail_mesh
	rail2.material_override = wood_mat
	rail2.position = Vector3(0, 0.85, 0)
	add_child(rail2)

	# Kollision
	_add_collision(Vector3(2.1, 1.3, 0.15), Vector3(0, 0.65, 0))


func _build_wall() -> void:
	# Hauptwand (Holzplanken)
	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.0, 2.0, 0.15)
	wall.mesh = wall_mesh
	wall.material_override = wood_mat
	wall.position = Vector3(0, 1.0, 0)
	add_child(wall)

	# Planken-Rillen (dunklere Streifen)
	var groove_mesh := BoxMesh.new()
	groove_mesh.size = Vector3(0.02, 2.0, 0.16)
	for i in range(5):
		var groove := MeshInstance3D.new()
		groove.mesh = groove_mesh
		groove.material_override = dark_wood_mat
		groove.position = Vector3(-1.2 + i * 0.6, 1.0, 0)
		add_child(groove)

	# Stützbalken oben und unten
	var beam_mesh := BoxMesh.new()
	beam_mesh.size = Vector3(3.1, 0.12, 0.18)

	var top_beam := MeshInstance3D.new()
	top_beam.mesh = beam_mesh
	top_beam.material_override = dark_wood_mat
	top_beam.position = Vector3(0, 2.0, 0)
	add_child(top_beam)

	var bottom_beam := MeshInstance3D.new()
	bottom_beam.mesh = beam_mesh
	bottom_beam.material_override = dark_wood_mat
	bottom_beam.position = Vector3(0, 0.06, 0)
	add_child(bottom_beam)

	# Kollision
	_add_collision(Vector3(3.0, 2.0, 0.2), Vector3(0, 1.0, 0))


func _build_chest() -> void:
	# Truhen-Körper
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.8, 0.5, 0.5)
	body.mesh = body_mesh
	body.material_override = wood_mat
	body.position = Vector3(0, 0.25, 0)
	add_child(body)

	# Deckel (leicht offen)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.82, 0.08, 0.52)
	lid.mesh = lid_mesh
	lid.material_override = dark_wood_mat
	lid.position = Vector3(0, 0.54, 0)
	add_child(lid)

	# Gewölbter Deckel-Oberteil
	var lid_top := MeshInstance3D.new()
	var lt_mesh := BoxMesh.new()
	lt_mesh.size = Vector3(0.78, 0.06, 0.48)
	lid_top.mesh = lt_mesh
	lid_top.material_override = wood_mat
	lid_top.position = Vector3(0, 0.6, 0)
	add_child(lid_top)

	# Metallbeschläge
	var clasp := MeshInstance3D.new()
	var clasp_mesh := BoxMesh.new()
	clasp_mesh.size = Vector3(0.15, 0.12, 0.04)
	clasp.mesh = clasp_mesh
	clasp.material_override = metal_mat
	clasp.position = Vector3(0, 0.42, 0.26)
	add_child(clasp)

	# Seitliche Beschläge
	var side_mesh := BoxMesh.new()
	side_mesh.size = Vector3(0.04, 0.35, 0.45)
	for side in [-1, 1]:
		var band := MeshInstance3D.new()
		band.mesh = side_mesh
		band.material_override = metal_mat
		band.position = Vector3(0.39 * side, 0.3, 0)
		add_child(band)

	# Kollision
	_add_collision(Vector3(0.82, 0.65, 0.52), Vector3(0, 0.32, 0))


func _add_collision(size: Vector3, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	col.position = pos
	add_child(col)

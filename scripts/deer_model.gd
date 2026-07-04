extends Node3D

# Prozedurales Hirsch-Monster – aufrecht auf 2 Beinen
# Zwei Varianten:
#   hungry = true:  Hungriger Hirsch – rote Augen mit schwarzen Pupillen, aggressiver
#   hungry = false: Normaler Hirsch – weiße Augen mit schwarzen Pupillen, ruhiger

# Variante
var hungry: bool = false

# Körperteile
var body: MeshInstance3D
var head: MeshInstance3D
var neck: MeshInstance3D
var snout: MeshInstance3D
var jaw: MeshInstance3D
var left_eye_white: MeshInstance3D
var right_eye_white: MeshInstance3D
var left_pupil: MeshInstance3D
var right_pupil: MeshInstance3D
var left_ear: MeshInstance3D
var right_ear: MeshInstance3D
var tail: MeshInstance3D

# Arme (mit Krallen)
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_forearm: MeshInstance3D
var right_forearm: MeshInstance3D

# Beine (2 Beine, aufrecht)
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var left_upper_leg: MeshInstance3D
var right_upper_leg: MeshInstance3D
var left_lower_leg: MeshInstance3D
var right_lower_leg: MeshInstance3D

# Animation
var walk_cycle: float = 0.0
var is_moving: bool = false
@export var walk_speed: float = 6.0
@export var leg_swing: float = 25.0
@export var arm_swing: float = 15.0

# Atem-Animation
var breath_cycle: float = 0.0

# Materialien
var fur_mat: StandardMaterial3D
var dark_fur_mat: StandardMaterial3D
var belly_mat: StandardMaterial3D
var antler_mat: StandardMaterial3D
var eye_white_mat: StandardMaterial3D
var pupil_mat: StandardMaterial3D
var hoof_mat: StandardMaterial3D
var nose_mat: StandardMaterial3D
var ear_inner_mat: StandardMaterial3D
var mouth_mat: StandardMaterial3D
var throat_mat: StandardMaterial3D
var teeth_mat: StandardMaterial3D
var claw_mat: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_build_body()
	_build_head()
	_build_arms()
	_build_legs()
	_build_tail()


func _process(delta: float) -> void:
	breath_cycle += delta * 2.0

	if is_moving:
		walk_cycle += delta * walk_speed
		_animate_walk()
	else:
		_animate_idle(delta)

	# Hungriger Hirsch: Augen pulsieren leicht
	if hungry:
		var pulse: float = 0.8 + sin(breath_cycle * 3.0) * 0.2
		eye_white_mat.emission_energy_multiplier = pulse


func set_moving(moving: bool) -> void:
	is_moving = moving


func _create_materials() -> void:
	# Dunkles Fell
	fur_mat = StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.18, 0.14, 0.12, 1)

	# Noch dunkleres Fell
	dark_fur_mat = StandardMaterial3D.new()
	dark_fur_mat.albedo_color = Color(0.12, 0.09, 0.08, 1)

	# Bauch
	belly_mat = StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.25, 0.2, 0.17, 1)

	# Geweih – knochenbleich
	antler_mat = StandardMaterial3D.new()
	antler_mat.albedo_color = Color(0.75, 0.7, 0.6, 1)

	# Augen – abhängig von Variante
	eye_white_mat = StandardMaterial3D.new()
	if hungry:
		# Rote Augen mit Glow
		eye_white_mat.albedo_color = Color(1.0, 0.15, 0.05, 1)
		eye_white_mat.emission_enabled = true
		eye_white_mat.emission = Color(1.0, 0.1, 0.0, 1)
		eye_white_mat.emission_energy_multiplier = 0.8
	else:
		# Weiße Augen (normal)
		eye_white_mat.albedo_color = Color(0.92, 0.9, 0.88, 1)

	# Schwarze Pupillen (beide Varianten)
	pupil_mat = StandardMaterial3D.new()
	pupil_mat.albedo_color = Color(0.02, 0.02, 0.02, 1)

	# Hufe/Füße
	hoof_mat = StandardMaterial3D.new()
	hoof_mat.albedo_color = Color(0.08, 0.06, 0.05, 1)

	# Nase
	nose_mat = StandardMaterial3D.new()
	nose_mat.albedo_color = Color(0.1, 0.08, 0.08, 1)

	# Ohr-Innenseite
	ear_inner_mat = StandardMaterial3D.new()
	ear_inner_mat.albedo_color = Color(0.3, 0.15, 0.12, 1)

	# Mundinneres – dunkelrot
	mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.3, 0.06, 0.06, 1)

	# Schlund – tiefschwarz-rot, bedrohlich
	throat_mat = StandardMaterial3D.new()
	throat_mat.albedo_color = Color(0.08, 0.02, 0.02, 1)

	# Zähne
	teeth_mat = StandardMaterial3D.new()
	teeth_mat.albedo_color = Color(0.85, 0.8, 0.65, 1)

	# Krallen
	claw_mat = StandardMaterial3D.new()
	claw_mat.albedo_color = Color(0.7, 0.65, 0.55, 1)


func _build_body() -> void:
	# Aufrechter Oberkörper
	body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.75, 0.85, 0.5)
	body.mesh = body_mesh
	body.material_override = fur_mat
	body.position = Vector3(0, 1.45, 0)
	body.name = "Body"
	add_child(body)

	# Rücken dunkler
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.6, 0.7, 0.1)
	back.mesh = back_mesh
	back.material_override = dark_fur_mat
	back.position = Vector3(0, 0.05, -0.22)
	body.add_child(back)

	# Bauch heller
	var belly := MeshInstance3D.new()
	var belly_mesh := BoxMesh.new()
	belly_mesh.size = Vector3(0.55, 0.5, 0.15)
	belly.mesh = belly_mesh
	belly.material_override = belly_mat
	belly.position = Vector3(0, -0.1, 0.2)
	body.add_child(belly)

	# Schultern
	var shoulders := MeshInstance3D.new()
	var shoulders_mesh := BoxMesh.new()
	shoulders_mesh.size = Vector3(0.9, 0.25, 0.45)
	shoulders.mesh = shoulders_mesh
	shoulders.material_override = dark_fur_mat
	shoulders.position = Vector3(0, 0.35, 0)
	body.add_child(shoulders)

	# Becken
	var pelvis := MeshInstance3D.new()
	var pelvis_mesh := BoxMesh.new()
	pelvis_mesh.size = Vector3(0.6, 0.3, 0.4)
	pelvis.mesh = pelvis_mesh
	pelvis.material_override = fur_mat
	pelvis.position = Vector3(0, -0.5, 0)
	body.add_child(pelvis)


func _build_head() -> void:
	# Hals
	neck = MeshInstance3D.new()
	var neck_mesh := BoxMesh.new()
	neck_mesh.size = Vector3(0.3, 0.35, 0.25)
	neck.mesh = neck_mesh
	neck.material_override = fur_mat
	neck.position = Vector3(0, 2.05, 0.05)
	neck.name = "Neck"
	add_child(neck)

	# Kopf (groß für die Augen und das Maul)
	head = MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.45, 0.5)
	head.mesh = head_mesh
	head.material_override = fur_mat
	head.position = Vector3(0, 2.42, 0.08)
	head.name = "Head"
	add_child(head)

	# === GROßES MAUL ===
	# Oberkiefer / Schnauze (breit und lang)
	snout = MeshInstance3D.new()
	var snout_mesh := BoxMesh.new()
	snout_mesh.size = Vector3(0.38, 0.2, 0.5)
	snout.mesh = snout_mesh
	snout.material_override = fur_mat
	snout.position = Vector3(0, -0.06, 0.42)
	head.add_child(snout)

	# Nase
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.2, 0.08, 0.06)
	nose.mesh = nose_mesh
	nose.material_override = nose_mat
	nose.position = Vector3(0, 0.06, 0.23)
	snout.add_child(nose)

	# Oberkiefer-Innenseite (Gaumen – dunkelrot)
	var palate := MeshInstance3D.new()
	var palate_mesh := BoxMesh.new()
	palate_mesh.size = Vector3(0.3, 0.05, 0.42)
	palate.mesh = palate_mesh
	palate.material_override = mouth_mat
	palate.position = Vector3(0, -0.09, 0.0)
	snout.add_child(palate)

	# Unterkiefer (groß, immer offen)
	jaw = MeshInstance3D.new()
	var jaw_mesh := BoxMesh.new()
	jaw_mesh.size = Vector3(0.36, 0.12, 0.48)
	jaw.mesh = jaw_mesh
	jaw.material_override = fur_mat
	jaw.position = Vector3(0, -0.22, 0.0)
	jaw.rotation_degrees.x = 15.0  # Maul steht offen
	snout.add_child(jaw)

	# Unterkiefer-Innenseite
	var jaw_inner := MeshInstance3D.new()
	var jaw_inner_mesh := BoxMesh.new()
	jaw_inner_mesh.size = Vector3(0.28, 0.04, 0.4)
	jaw_inner.mesh = jaw_inner_mesh
	jaw_inner.material_override = mouth_mat
	jaw_inner.position = Vector3(0, 0.05, 0.0)
	jaw.add_child(jaw_inner)

	# === SCHLUND (tief im Maul, dunkel) ===
	var throat := MeshInstance3D.new()
	var throat_mesh := CylinderMesh.new()
	throat_mesh.top_radius = 0.1
	throat_mesh.bottom_radius = 0.06
	throat_mesh.height = 0.2
	throat.mesh = throat_mesh
	throat.material_override = throat_mat
	throat.position = Vector3(0, -0.08, -0.18)
	throat.rotation_degrees.x = 90.0  # Horizontal nach hinten
	snout.add_child(throat)

	# Schlund-Rand (dunkelrot, Übergang)
	var throat_ring := MeshInstance3D.new()
	var ring_mesh := CylinderMesh.new()
	ring_mesh.top_radius = 0.13
	ring_mesh.bottom_radius = 0.1
	ring_mesh.height = 0.04
	throat_ring.mesh = ring_mesh
	throat_ring.material_override = mouth_mat
	throat_ring.position = Vector3(0, -0.08, -0.1)
	throat_ring.rotation_degrees.x = 90.0
	snout.add_child(throat_ring)

	# === ZÄHNE (oben und unten, groß) ===
	_add_upper_teeth(snout)
	_add_lower_teeth(jaw)

	# === GROßE AUGEN ===
	_build_eyes()

	# === OHREN ===
	left_ear = MeshInstance3D.new()
	var ear_mesh := BoxMesh.new()
	ear_mesh.size = Vector3(0.07, 0.22, 0.12)
	left_ear.mesh = ear_mesh
	left_ear.material_override = fur_mat
	left_ear.position = Vector3(-0.2, 0.28, -0.08)
	left_ear.rotation_degrees.z = 25.0
	left_ear.rotation_degrees.x = -10.0
	head.add_child(left_ear)

	var ear_inner_mesh := BoxMesh.new()
	ear_inner_mesh.size = Vector3(0.03, 0.15, 0.08)

	var left_ear_inner := MeshInstance3D.new()
	left_ear_inner.mesh = ear_inner_mesh
	left_ear_inner.material_override = ear_inner_mat
	left_ear_inner.position = Vector3(0.01, 0, 0.02)
	left_ear.add_child(left_ear_inner)

	right_ear = MeshInstance3D.new()
	right_ear.mesh = ear_mesh
	right_ear.material_override = fur_mat
	right_ear.position = Vector3(0.2, 0.28, -0.08)
	right_ear.rotation_degrees.z = -25.0
	right_ear.rotation_degrees.x = -10.0
	head.add_child(right_ear)

	var right_ear_inner := MeshInstance3D.new()
	right_ear_inner.mesh = ear_inner_mesh
	right_ear_inner.material_override = ear_inner_mat
	right_ear_inner.position = Vector3(-0.01, 0, 0.02)
	right_ear.add_child(right_ear_inner)

	# === GEWEIH ===
	_build_antler(-1)
	_build_antler(1)


func _build_eyes() -> void:
	# Große Augen mit sichtbaren Pupillen
	var eye_size: float = 0.1 if hungry else 0.08
	var pupil_size: float = 0.05 if hungry else 0.04

	# Linkes Auge – Augapfel
	left_eye_white = MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = eye_size
	eye_mesh.height = eye_size * 2.0
	left_eye_white.mesh = eye_mesh
	left_eye_white.material_override = eye_white_mat
	left_eye_white.position = Vector3(-0.17, 0.1, 0.24)
	head.add_child(left_eye_white)

	# Linke Pupille
	left_pupil = MeshInstance3D.new()
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = pupil_size
	pupil_mesh.height = pupil_size * 2.0
	left_pupil.mesh = pupil_mesh
	left_pupil.material_override = pupil_mat
	left_pupil.position = Vector3(0, 0, eye_size * 0.65)
	left_eye_white.add_child(left_pupil)

	# Rechtes Auge – Augapfel
	right_eye_white = MeshInstance3D.new()
	right_eye_white.mesh = eye_mesh
	right_eye_white.material_override = eye_white_mat
	right_eye_white.position = Vector3(0.17, 0.1, 0.24)
	head.add_child(right_eye_white)

	# Rechte Pupille
	right_pupil = MeshInstance3D.new()
	right_pupil.mesh = pupil_mesh
	right_pupil.material_override = pupil_mat
	right_pupil.position = Vector3(0, 0, eye_size * 0.65)
	right_eye_white.add_child(right_pupil)


func _add_upper_teeth(parent: Node3D) -> void:
	# Reihe kleiner Zähne
	var tooth_mesh := BoxMesh.new()
	tooth_mesh.size = Vector3(0.03, 0.08, 0.025)
	var positions: Array = [-0.1, -0.05, 0.0, 0.05, 0.1]
	for x_pos in positions:
		var tooth := MeshInstance3D.new()
		tooth.mesh = tooth_mesh
		tooth.material_override = teeth_mat
		tooth.position = Vector3(x_pos, -0.12, 0.18)
		parent.add_child(tooth)

	# Große Eckzähne (Fänge!)
	var fang_mesh := BoxMesh.new()
	fang_mesh.size = Vector3(0.04, 0.14, 0.035)
	for side in [-1, 1]:
		var fang := MeshInstance3D.new()
		fang.mesh = fang_mesh
		fang.material_override = teeth_mat
		fang.position = Vector3(0.14 * side, -0.14, 0.15)
		parent.add_child(fang)


func _add_lower_teeth(parent: Node3D) -> void:
	var tooth_mesh := BoxMesh.new()
	tooth_mesh.size = Vector3(0.03, 0.06, 0.025)
	var positions: Array = [-0.08, -0.03, 0.03, 0.08]
	for x_pos in positions:
		var tooth := MeshInstance3D.new()
		tooth.mesh = tooth_mesh
		tooth.material_override = teeth_mat
		tooth.position = Vector3(x_pos, 0.07, 0.18)
		parent.add_child(tooth)

	# Untere Eckzähne (kleiner)
	var fang_mesh := BoxMesh.new()
	fang_mesh.size = Vector3(0.035, 0.1, 0.03)
	for side in [-1, 1]:
		var fang := MeshInstance3D.new()
		fang.mesh = fang_mesh
		fang.material_override = teeth_mat
		fang.position = Vector3(0.12 * side, 0.08, 0.15)
		parent.add_child(fang)


func _build_antler(side: int) -> void:
	var x_offset: float = 0.15 * side

	var base := MeshInstance3D.new()
	var base_mesh := CylinderMesh.new()
	base_mesh.top_radius = 0.02
	base_mesh.bottom_radius = 0.04
	base_mesh.height = 0.5
	base.mesh = base_mesh
	base.material_override = antler_mat
	base.position = Vector3(x_offset, 0.3, -0.08)
	base.rotation_degrees.z = -20.0 * side
	base.rotation_degrees.x = -10.0
	head.add_child(base)

	var b1 := MeshInstance3D.new()
	var b1_mesh := CylinderMesh.new()
	b1_mesh.top_radius = 0.012
	b1_mesh.bottom_radius = 0.025
	b1_mesh.height = 0.28
	b1.mesh = b1_mesh
	b1.material_override = antler_mat
	b1.position = Vector3(0, 0.12, 0)
	b1.rotation_degrees.x = 40.0
	b1.rotation_degrees.z = -12.0 * side
	base.add_child(b1)

	var t1 := MeshInstance3D.new()
	var t1_mesh := CylinderMesh.new()
	t1_mesh.top_radius = 0.005
	t1_mesh.bottom_radius = 0.012
	t1_mesh.height = 0.15
	t1.mesh = t1_mesh
	t1.material_override = antler_mat
	t1.position = Vector3(0, 0.13, 0)
	b1.add_child(t1)

	var b2 := MeshInstance3D.new()
	var b2_mesh := CylinderMesh.new()
	b2_mesh.top_radius = 0.008
	b2_mesh.bottom_radius = 0.022
	b2_mesh.height = 0.35
	b2.mesh = b2_mesh
	b2.material_override = antler_mat
	b2.position = Vector3(0, 0.24, 0)
	b2.rotation_degrees.z = -8.0 * side
	base.add_child(b2)

	var t2 := MeshInstance3D.new()
	var t2_mesh := CylinderMesh.new()
	t2_mesh.top_radius = 0.003
	t2_mesh.bottom_radius = 0.008
	t2_mesh.height = 0.2
	t2.mesh = t2_mesh
	t2.material_override = antler_mat
	t2.position = Vector3(0, 0.17, 0)
	b2.add_child(t2)

	var b3 := MeshInstance3D.new()
	var b3_mesh := CylinderMesh.new()
	b3_mesh.top_radius = 0.006
	b3_mesh.bottom_radius = 0.018
	b3_mesh.height = 0.2
	b3.mesh = b3_mesh
	b3.material_override = antler_mat
	b3.position = Vector3(0, 0.06, 0)
	b3.rotation_degrees.x = -35.0
	b3.rotation_degrees.z = -18.0 * side
	base.add_child(b3)


func _build_arms() -> void:
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.16, 0.5, 0.16)
	var forearm_mesh := BoxMesh.new()
	forearm_mesh.size = Vector3(0.13, 0.45, 0.13)

	# Linker Arm
	left_arm_pivot = Node3D.new()
	left_arm_pivot.position = Vector3(-0.48, 1.72, 0)
	left_arm_pivot.name = "LeftArmPivot"
	add_child(left_arm_pivot)

	left_arm = MeshInstance3D.new()
	left_arm.mesh = arm_mesh
	left_arm.material_override = fur_mat
	left_arm.position = Vector3(0, -0.25, 0)
	left_arm_pivot.add_child(left_arm)

	left_forearm = MeshInstance3D.new()
	left_forearm.mesh = forearm_mesh
	left_forearm.material_override = fur_mat
	left_forearm.position = Vector3(0, -0.52, 0)
	left_arm_pivot.add_child(left_forearm)

	_add_claws(left_arm_pivot, Vector3(0, -0.78, 0))

	# Rechter Arm
	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.48, 1.72, 0)
	right_arm_pivot.name = "RightArmPivot"
	add_child(right_arm_pivot)

	right_arm = MeshInstance3D.new()
	right_arm.mesh = arm_mesh
	right_arm.material_override = fur_mat
	right_arm.position = Vector3(0, -0.25, 0)
	right_arm_pivot.add_child(right_arm)

	right_forearm = MeshInstance3D.new()
	right_forearm.mesh = forearm_mesh
	right_forearm.material_override = fur_mat
	right_forearm.position = Vector3(0, -0.52, 0)
	right_arm_pivot.add_child(right_forearm)

	_add_claws(right_arm_pivot, Vector3(0, -0.78, 0))


func _add_claws(parent: Node3D, base_pos: Vector3) -> void:
	var hand := MeshInstance3D.new()
	var hand_mesh := BoxMesh.new()
	hand_mesh.size = Vector3(0.12, 0.1, 0.1)
	hand.mesh = hand_mesh
	hand.material_override = dark_fur_mat
	hand.position = base_pos
	parent.add_child(hand)

	var claw_mesh := BoxMesh.new()
	claw_mesh.size = Vector3(0.02, 0.12, 0.025)
	for i in range(3):
		var claw := MeshInstance3D.new()
		claw.mesh = claw_mesh
		claw.material_override = claw_mat
		var x_off: float = (i - 1) * 0.04
		claw.position = base_pos + Vector3(x_off, -0.1, 0.03)
		claw.rotation_degrees.x = -20.0
		parent.add_child(claw)


func _build_legs() -> void:
	var upper_mesh := BoxMesh.new()
	upper_mesh.size = Vector3(0.22, 0.5, 0.22)
	var lower_mesh := BoxMesh.new()
	lower_mesh.size = Vector3(0.14, 0.45, 0.14)
	var foot_mesh := BoxMesh.new()
	foot_mesh.size = Vector3(0.18, 0.1, 0.25)

	# Linkes Bein
	left_leg_pivot = Node3D.new()
	left_leg_pivot.position = Vector3(-0.2, 0.95, 0)
	left_leg_pivot.name = "LeftLegPivot"
	add_child(left_leg_pivot)

	left_upper_leg = MeshInstance3D.new()
	left_upper_leg.mesh = upper_mesh
	left_upper_leg.material_override = fur_mat
	left_upper_leg.position = Vector3(0, -0.25, 0)
	left_leg_pivot.add_child(left_upper_leg)

	left_lower_leg = MeshInstance3D.new()
	left_lower_leg.mesh = lower_mesh
	left_lower_leg.material_override = fur_mat
	left_lower_leg.position = Vector3(0, -0.55, 0)
	left_leg_pivot.add_child(left_lower_leg)

	var left_foot := MeshInstance3D.new()
	left_foot.mesh = foot_mesh
	left_foot.material_override = hoof_mat
	left_foot.position = Vector3(0, -0.82, 0.04)
	left_leg_pivot.add_child(left_foot)

	_add_foot_claws(left_leg_pivot, Vector3(0, -0.86, 0.14))

	# Rechtes Bein
	right_leg_pivot = Node3D.new()
	right_leg_pivot.position = Vector3(0.2, 0.95, 0)
	right_leg_pivot.name = "RightLegPivot"
	add_child(right_leg_pivot)

	right_upper_leg = MeshInstance3D.new()
	right_upper_leg.mesh = upper_mesh
	right_upper_leg.material_override = fur_mat
	right_upper_leg.position = Vector3(0, -0.25, 0)
	right_leg_pivot.add_child(right_upper_leg)

	right_lower_leg = MeshInstance3D.new()
	right_lower_leg.mesh = lower_mesh
	right_lower_leg.material_override = fur_mat
	right_lower_leg.position = Vector3(0, -0.55, 0)
	right_leg_pivot.add_child(right_lower_leg)

	var right_foot := MeshInstance3D.new()
	right_foot.mesh = foot_mesh
	right_foot.material_override = hoof_mat
	right_foot.position = Vector3(0, -0.82, 0.04)
	right_leg_pivot.add_child(right_foot)

	_add_foot_claws(right_leg_pivot, Vector3(0, -0.86, 0.14))


func _add_foot_claws(parent: Node3D, base_pos: Vector3) -> void:
	var claw_mesh := BoxMesh.new()
	claw_mesh.size = Vector3(0.025, 0.04, 0.08)
	for i in range(3):
		var claw := MeshInstance3D.new()
		claw.mesh = claw_mesh
		claw.material_override = claw_mat
		var x_off: float = (i - 1) * 0.05
		claw.position = base_pos + Vector3(x_off, 0, 0.03)
		parent.add_child(claw)


func _build_tail() -> void:
	tail = MeshInstance3D.new()
	var tail_mesh := BoxMesh.new()
	tail_mesh.size = Vector3(0.1, 0.3, 0.08)
	tail.mesh = tail_mesh
	tail.material_override = dark_fur_mat
	tail.position = Vector3(0, 1.05, -0.28)
	tail.rotation_degrees.x = 30.0
	tail.name = "Tail"
	add_child(tail)


func _animate_walk() -> void:
	var swing: float = sin(walk_cycle)
	var swing2: float = cos(walk_cycle)
	var l_angle: float = deg_to_rad(leg_swing)
	var a_angle: float = deg_to_rad(arm_swing)

	left_leg_pivot.rotation.x = swing * l_angle
	right_leg_pivot.rotation.x = -swing * l_angle

	left_arm_pivot.rotation.x = -swing * a_angle
	right_arm_pivot.rotation.x = swing * a_angle

	body.position.y = 1.45 + abs(swing2) * 0.03
	body.rotation.z = swing * deg_to_rad(2.0)

	head.position.y = 2.42 + abs(swing2) * 0.02
	head.rotation.z = swing * deg_to_rad(1.0)

	tail.rotation.z = swing * deg_to_rad(10.0)

	# Kiefer klappert beim Laufen – Maul bleibt immer offen
	var jaw_extra: float = 8.0 if hungry else 4.0
	jaw.rotation_degrees.x = 15.0 + abs(sin(walk_cycle * 0.5)) * jaw_extra


func _animate_idle(delta: float) -> void:
	var rs: float = 4.0

	left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, rs * delta)
	right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, rs * delta)
	left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, 0.0, rs * delta)
	right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, 0.0, rs * delta)

	body.position.y = lerp(body.position.y, 1.45, rs * delta)
	body.rotation.z = lerp(body.rotation.z, 0.0, rs * delta)
	head.position.y = lerp(head.position.y, 2.42, rs * delta)
	head.rotation.z = lerp(head.rotation.z, 0.0, rs * delta)

	# Atem
	var breath: float = sin(breath_cycle) * 0.01
	body.position.y += breath

	# Ohren zucken
	var twitch: float = sin(breath_cycle * 5.0) * sin(breath_cycle * 0.7)
	if abs(twitch) > 0.8:
		left_ear.rotation_degrees.z = 25.0 + twitch * 6.0
		right_ear.rotation_degrees.z = -25.0 - twitch * 6.0

	# Kiefer atmet – Maul bleibt immer offen, pulsiert leicht
	var jaw_idle: float = 4.0 if hungry else 2.0
	jaw.rotation_degrees.x = lerp(jaw.rotation_degrees.x, 15.0 + sin(breath_cycle) * jaw_idle, rs * delta)

	tail.rotation.z = sin(breath_cycle * 0.8) * deg_to_rad(4.0)

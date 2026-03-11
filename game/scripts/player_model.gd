extends Node3D

# Spieler-Modell: Körper, Arme, Beine, Gesicht + Gehanimation

# Körperteile
var body: MeshInstance3D
var head: MeshInstance3D
var left_eye: MeshInstance3D
var right_eye: MeshInstance3D
var mouth: MeshInstance3D
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var left_leg: MeshInstance3D
var right_leg: MeshInstance3D

# Animation
var walk_cycle: float = 0.0
var is_walking: bool = false
@export var walk_anim_speed: float = 8.0
@export var arm_swing_angle: float = 35.0
@export var leg_swing_angle: float = 40.0
@export var body_bob_amount: float = 0.06
@export var head_bob_amount: float = 0.03

# Axt
var axe_node: Node3D = null
var axe_script: GDScript = null

# Hack-Animation
var is_chopping: bool = false
var chop_cycle: float = 0.0
var chop_duration: float = 0.4

# Materialien
var skin_mat: StandardMaterial3D
var shirt_mat: StandardMaterial3D
var pants_mat: StandardMaterial3D
var shoe_mat: StandardMaterial3D
var eye_white_mat: StandardMaterial3D
var eye_pupil_mat: StandardMaterial3D
var mouth_mat: StandardMaterial3D
var hair_mat: StandardMaterial3D


func _ready() -> void:
	axe_script = preload("res://scripts/axe_item.gd")
	_create_materials()
	_build_body()


func _process(delta: float) -> void:
	# Hack-Animation hat Priorität für den rechten Arm
	if is_chopping:
		chop_cycle += delta
		if chop_cycle >= chop_duration:
			is_chopping = false
			chop_cycle = 0.0

	if is_walking:
		walk_cycle += delta * walk_anim_speed
		_animate_walk()
	else:
		walk_cycle = 0.0
		_animate_idle(delta)

	# Hack-Animation überschreibt rechten Arm
	if is_chopping:
		_animate_chop()


func set_walking(walking: bool) -> void:
	is_walking = walking


func _create_materials() -> void:
	# Haut
	skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.75, 0.6, 1)

	# Hemd (dunkles T-Shirt wie im Roblox-Vorbild)
	shirt_mat = StandardMaterial3D.new()
	shirt_mat.albedo_color = Color(0.12, 0.12, 0.12, 1)

	# Hose (dunkle Jeans)
	pants_mat = StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.15, 0.15, 0.18, 1)

	# Schuhe (dunkelgrau)
	shoe_mat = StandardMaterial3D.new()
	shoe_mat.albedo_color = Color(0.2, 0.18, 0.15, 1)

	# Augen
	eye_white_mat = StandardMaterial3D.new()
	eye_white_mat.albedo_color = Color(0.95, 0.95, 0.95, 1)

	eye_pupil_mat = StandardMaterial3D.new()
	eye_pupil_mat.albedo_color = Color(0.15, 0.1, 0.05, 1)

	# Mund
	mouth_mat = StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.6, 0.25, 0.2, 1)

	# Haare
	hair_mat = StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.6, 0.35, 0.15, 1)


func _build_body() -> void:
	# === KÖRPER (Oberkörper) ===
	body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.5, 0.6, 0.3)
	body.mesh = body_mesh
	body.material_override = shirt_mat
	body.position = Vector3(0, 1.05, 0)
	body.name = "Body"
	add_child(body)

	# === KOPF ===
	head = MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.4, 0.4, 0.35)
	head.mesh = head_mesh
	head.material_override = skin_mat
	head.position = Vector3(0, 1.6, 0)
	head.name = "Head"
	add_child(head)

	# Haare (Platte oben auf dem Kopf)
	var hair := MeshInstance3D.new()
	var hair_mesh := BoxMesh.new()
	hair_mesh.size = Vector3(0.42, 0.12, 0.37)
	hair.mesh = hair_mesh
	hair.material_override = hair_mat
	hair.position = Vector3(0, 0.22, 0)
	head.add_child(hair)

	# === GESICHT ===
	# Linkes Auge (weiss)
	left_eye = MeshInstance3D.new()
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.055
	eye_mesh.height = 0.11
	left_eye.mesh = eye_mesh
	left_eye.material_override = eye_white_mat
	left_eye.position = Vector3(-0.09, 0.05, 0.16)
	head.add_child(left_eye)

	# Linke Pupille
	var left_pupil := MeshInstance3D.new()
	var pupil_mesh := SphereMesh.new()
	pupil_mesh.radius = 0.03
	pupil_mesh.height = 0.06
	left_pupil.mesh = pupil_mesh
	left_pupil.material_override = eye_pupil_mat
	left_pupil.position = Vector3(0, 0, 0.03)
	left_eye.add_child(left_pupil)

	# Rechtes Auge (weiss)
	right_eye = MeshInstance3D.new()
	right_eye.mesh = eye_mesh
	right_eye.material_override = eye_white_mat
	right_eye.position = Vector3(0.09, 0.05, 0.16)
	head.add_child(right_eye)

	# Rechte Pupille
	var right_pupil := MeshInstance3D.new()
	right_pupil.mesh = pupil_mesh
	right_pupil.material_override = eye_pupil_mat
	right_pupil.position = Vector3(0, 0, 0.03)
	right_eye.add_child(right_pupil)

	# Mund
	mouth = MeshInstance3D.new()
	var mouth_mesh := BoxMesh.new()
	mouth_mesh.size = Vector3(0.12, 0.03, 0.02)
	mouth.mesh = mouth_mesh
	mouth.material_override = mouth_mat
	mouth.position = Vector3(0, -0.1, 0.17)
	head.add_child(mouth)

	# Nase
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.06, 0.06, 0.06)
	nose.mesh = nose_mesh
	nose.material_override = skin_mat
	nose.position = Vector3(0, 0.0, 0.19)
	head.add_child(nose)

	# === ARME ===
	# Linker Arm (Pivot am Schultergelenk)
	left_arm_pivot = Node3D.new()
	left_arm_pivot.position = Vector3(-0.32, 1.3, 0)
	left_arm_pivot.name = "LeftArmPivot"
	add_child(left_arm_pivot)

	left_arm = MeshInstance3D.new()
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.15, 0.55, 0.15)
	left_arm.mesh = arm_mesh
	left_arm.material_override = shirt_mat
	left_arm.position = Vector3(0, -0.28, 0)
	left_arm_pivot.add_child(left_arm)

	# Linke Hand
	var left_hand := MeshInstance3D.new()
	var hand_mesh := BoxMesh.new()
	hand_mesh.size = Vector3(0.12, 0.12, 0.12)
	left_hand.mesh = hand_mesh
	left_hand.material_override = skin_mat
	left_hand.position = Vector3(0, -0.33, 0)
	left_arm_pivot.add_child(left_hand)

	# Rechter Arm
	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.32, 1.3, 0)
	right_arm_pivot.name = "RightArmPivot"
	add_child(right_arm_pivot)

	right_arm = MeshInstance3D.new()
	right_arm.mesh = arm_mesh
	right_arm.material_override = shirt_mat
	right_arm.position = Vector3(0, -0.28, 0)
	right_arm_pivot.add_child(right_arm)

	# Rechte Hand
	var right_hand := MeshInstance3D.new()
	right_hand.mesh = hand_mesh
	right_hand.material_override = skin_mat
	right_hand.position = Vector3(0, -0.33, 0)
	right_arm_pivot.add_child(right_hand)

	# === BEINE ===
	# Linkes Bein (Pivot am Hüftgelenk)
	left_leg_pivot = Node3D.new()
	left_leg_pivot.position = Vector3(-0.12, 0.75, 0)
	left_leg_pivot.name = "LeftLegPivot"
	add_child(left_leg_pivot)

	left_leg = MeshInstance3D.new()
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.18, 0.55, 0.18)
	left_leg.mesh = leg_mesh
	left_leg.material_override = pants_mat
	left_leg.position = Vector3(0, -0.28, 0)
	left_leg_pivot.add_child(left_leg)

	# Linker Schuh
	var left_shoe := MeshInstance3D.new()
	var shoe_mesh := BoxMesh.new()
	shoe_mesh.size = Vector3(0.2, 0.12, 0.28)
	left_shoe.mesh = shoe_mesh
	left_shoe.material_override = shoe_mat
	left_shoe.position = Vector3(0, -0.58, 0.04)
	left_leg_pivot.add_child(left_shoe)

	# Rechtes Bein
	right_leg_pivot = Node3D.new()
	right_leg_pivot.position = Vector3(0.12, 0.75, 0)
	right_leg_pivot.name = "RightLegPivot"
	add_child(right_leg_pivot)

	right_leg = MeshInstance3D.new()
	right_leg.mesh = leg_mesh
	right_leg.material_override = pants_mat
	right_leg.position = Vector3(0, -0.28, 0)
	right_leg_pivot.add_child(right_leg)

	# Rechter Schuh
	var right_shoe := MeshInstance3D.new()
	right_shoe.mesh = shoe_mesh
	right_shoe.material_override = shoe_mat
	right_shoe.position = Vector3(0, -0.58, 0.04)
	right_leg_pivot.add_child(right_shoe)


func _animate_walk() -> void:
	var swing: float = sin(walk_cycle)
	var swing_offset: float = cos(walk_cycle)

	# Beine schwingen gegenläufig
	var leg_angle: float = swing * deg_to_rad(leg_swing_angle)
	left_leg_pivot.rotation.x = leg_angle
	right_leg_pivot.rotation.x = -leg_angle

	# Arme schwingen gegenläufig zu den Beinen
	var arm_angle: float = swing * deg_to_rad(arm_swing_angle)
	left_arm_pivot.rotation.x = -arm_angle
	right_arm_pivot.rotation.x = arm_angle

	# Körper wippt leicht
	body.position.y = 1.05 + abs(swing_offset) * body_bob_amount

	# Kopf wippt leicht (weniger als Körper)
	head.position.y = 1.6 + abs(swing_offset) * head_bob_amount

	# Leichtes seitliches Wippen des Körpers
	body.rotation.z = swing * deg_to_rad(2.0)
	head.rotation.z = swing * deg_to_rad(1.0)


func _animate_idle(delta: float) -> void:
	# Sanft zurück zur Ruheposition
	var return_speed: float = 5.0

	left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, return_speed * delta)
	right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, return_speed * delta)
	left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, 0.0, return_speed * delta)
	right_arm_pivot.rotation.x = lerp(right_arm_pivot.rotation.x, 0.0, return_speed * delta)

	body.position.y = lerp(body.position.y, 1.05, return_speed * delta)
	head.position.y = lerp(head.position.y, 1.6, return_speed * delta)
	body.rotation.z = lerp(body.rotation.z, 0.0, return_speed * delta)
	head.rotation.z = lerp(head.rotation.z, 0.0, return_speed * delta)

	# Leichte Atem-Animation im Idle
	var breath: float = sin(Time.get_ticks_msec() * 0.003) * 0.01
	body.position.y += breath


func equip_axe(tier: int) -> void:
	unequip_axe()
	axe_node = Node3D.new()
	axe_node.set_script(axe_script)
	axe_node.tier = tier
	axe_node.name = "AxeItem"
	# Axt in der rechten Hand positionieren
	axe_node.position = Vector3(0, -0.38, 0.08)
	right_arm_pivot.add_child(axe_node)


func unequip_axe() -> void:
	if axe_node and is_instance_valid(axe_node):
		axe_node.queue_free()
		axe_node = null


func play_chop() -> void:
	is_chopping = true
	chop_cycle = 0.0


func _animate_chop() -> void:
	if not right_arm_pivot:
		return
	# t geht von 0 bis 1 über die Hack-Dauer
	var t: float = chop_cycle / chop_duration
	# Schneller Schwung nach vorne/unten: hoch -> runter
	var chop_angle: float
	if t < 0.3:
		# Ausholen (nach hinten)
		chop_angle = lerp(0.0, -70.0, t / 0.3)
	else:
		# Zuschlagen (nach vorne/unten)
		chop_angle = lerp(-70.0, 30.0, (t - 0.3) / 0.7)
	right_arm_pivot.rotation_degrees.x = chop_angle
	# Körper neigt sich leicht vor
	body.rotation.x = -t * 0.1 * (1.0 - t)

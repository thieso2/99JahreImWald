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
var is_sprinting: bool = false
@export var walk_anim_speed: float = 8.0
@export var sprint_anim_speed: float = 14.0
@export var arm_swing_angle: float = 35.0
@export var leg_swing_angle: float = 40.0
@export var body_bob_amount: float = 0.06
@export var head_bob_amount: float = 0.03

# Axt
var axe_node: Node3D = null
var axe_script: GDScript = null

# Fackel
var torch_node: Node3D = null
var torch_script: GDScript = null

# Hack-Animation
var is_chopping: bool = false
var chop_cycle: float = 0.0
var chop_duration: float = 0.55  # Länger für realistischeren Schwung

# Sprung-Animation
var is_jumping: bool = false

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
	torch_script = preload("res://scripts/torch_item.gd")
	_create_materials()
	_build_body()


func _process(delta: float) -> void:
	# Hack-Animation hat Priorität für den rechten Arm
	if is_chopping:
		chop_cycle += delta
		if chop_cycle >= chop_duration:
			is_chopping = false
			chop_cycle = 0.0

	if is_jumping:
		_animate_jump(delta)
	elif is_walking:
		var anim_speed: float = sprint_anim_speed if is_sprinting else walk_anim_speed
		walk_cycle += delta * anim_speed
		_animate_walk()
	else:
		walk_cycle = 0.0
		_animate_idle(delta)

	# Hack-Animation überschreibt rechten Arm
	if is_chopping:
		_animate_chop()


func set_walking(walking: bool) -> void:
	is_walking = walking


func set_sprinting(sprinting: bool) -> void:
	is_sprinting = sprinting


func set_jumping(jumping: bool) -> void:
	is_jumping = jumping


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

	# Sprint = größere Ausschläge, mehr Körperneigung
	var sprint_mult: float = 1.6 if is_sprinting else 1.0

	# Beine schwingen gegenläufig
	var leg_angle: float = swing * deg_to_rad(leg_swing_angle * sprint_mult)
	left_leg_pivot.rotation.x = leg_angle
	right_leg_pivot.rotation.x = -leg_angle

	# Arme schwingen gegenläufig zu den Beinen
	var arm_angle: float = swing * deg_to_rad(arm_swing_angle * sprint_mult)
	left_arm_pivot.rotation.x = -arm_angle
	right_arm_pivot.rotation.x = arm_angle

	# Körper wippt leicht (Sprint = mehr)
	body.position.y = 1.05 + abs(swing_offset) * body_bob_amount * sprint_mult

	# Kopf wippt leicht (weniger als Körper)
	head.position.y = 1.6 + abs(swing_offset) * head_bob_amount * sprint_mult

	# Leichtes seitliches Wippen des Körpers
	body.rotation.z = swing * deg_to_rad(2.0 * sprint_mult)
	head.rotation.z = swing * deg_to_rad(1.0 * sprint_mult)

	# Beim Sprint: Oberkörper leicht nach vorne geneigt
	if is_sprinting:
		body.rotation.x = -0.15
		head.rotation.x = -0.08
	else:
		body.rotation.x = 0.0
		head.rotation.x = 0.0


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


func _animate_jump(delta: float) -> void:
	var target_speed: float = 8.0

	# Arme hoch (nach oben gestreckt)
	left_arm_pivot.rotation_degrees.x = lerp(left_arm_pivot.rotation_degrees.x, -160.0, target_speed * delta)
	right_arm_pivot.rotation_degrees.x = lerp(right_arm_pivot.rotation_degrees.x, -160.0, target_speed * delta)

	# Beine leicht angezogen
	left_leg_pivot.rotation_degrees.x = lerp(left_leg_pivot.rotation_degrees.x, -20.0, target_speed * delta)
	right_leg_pivot.rotation_degrees.x = lerp(right_leg_pivot.rotation_degrees.x, -20.0, target_speed * delta)

	# Körper leicht nach vorne
	body.rotation.x = lerp(body.rotation.x, -0.05, target_speed * delta)
	head.rotation.x = lerp(head.rotation.x, 0.1, target_speed * delta)


func equip_axe(tier: int) -> void:
	unequip_axe()
	axe_node = Node3D.new()
	axe_node.set_script(axe_script)
	axe_node.tier = tier
	axe_node.name = "AxeItem"
	# Axt weit vorne in der Hand – bereit zum Zuschlagen
	axe_node.position = Vector3(0, -0.45, 0.25)
	# Klinge nach unten + nach vorne ausrichten
	axe_node.rotation_degrees.z = -90.0
	axe_node.rotation_degrees.y = 270.0
	right_arm_pivot.add_child(axe_node)
	# Arm leicht nach vorne kippen (Axt vor dem Körper halten)
	right_arm_pivot.rotation_degrees.x = -25.0


func unequip_axe() -> void:
	if axe_node and is_instance_valid(axe_node):
		axe_node.queue_free()
		axe_node = null
	if right_arm_pivot:
		right_arm_pivot.rotation_degrees.x = 0.0


func play_chop() -> void:
	is_chopping = true
	chop_cycle = 0.0


func _animate_chop() -> void:
	if not right_arm_pivot or not left_arm_pivot:
		return

	var t: float = chop_cycle / chop_duration

	# Beide Arme greifen die Axt – realistischer Holzfäller-Schwung
	var right_angle: float
	var left_angle: float
	var body_lean: float
	var body_twist: float

	if t < 0.25:
		# Phase 1: Ausholen – Arme nach hinten über den Kopf
		var ease_t: float = t / 0.25
		ease_t = ease_t * ease_t  # Ease-in
		right_angle = lerp(0.0, -120.0, ease_t)
		left_angle = lerp(0.0, -100.0, ease_t)
		body_lean = lerp(0.0, 0.1, ease_t)  # Leicht nach hinten lehnen
		body_twist = lerp(0.0, -0.15, ease_t)  # Körper dreht sich zum Ausholen
	elif t < 0.5:
		# Phase 2: Zuschlagen – schneller Schwung nach vorne/unten
		var ease_t: float = (t - 0.25) / 0.25
		ease_t = 1.0 - (1.0 - ease_t) * (1.0 - ease_t)  # Ease-out (schnell)
		right_angle = lerp(-120.0, 45.0, ease_t)
		left_angle = lerp(-100.0, 35.0, ease_t)
		body_lean = lerp(0.1, -0.25, ease_t)  # Nach vorne lehnen beim Zuschlag
		body_twist = lerp(-0.15, 0.1, ease_t)  # Körper dreht mit
	else:
		# Phase 3: Nachschwung + Zurückkehren
		var ease_t: float = (t - 0.5) / 0.5
		right_angle = lerp(45.0, 0.0, ease_t)
		left_angle = lerp(35.0, 0.0, ease_t)
		body_lean = lerp(-0.25, 0.0, ease_t)
		body_twist = lerp(0.1, 0.0, ease_t)

	right_arm_pivot.rotation_degrees.x = right_angle
	left_arm_pivot.rotation_degrees.x = left_angle

	# Körper neigt sich nach vorne/hinten beim Schwung
	body.rotation.x = body_lean
	head.rotation.x = body_lean * 0.5

	# Körper dreht sich leicht seitlich (wie ein echter Holzfäller)
	body.rotation.y = body_twist
	head.rotation.y = body_twist * 0.3


func equip_torch() -> void:
	unequip_torch()
	torch_node = Node3D.new()
	torch_node.set_script(torch_script)
	torch_node.name = "TorchItem"
	# Fackel weit vorne – gleiche Position und Winkel wie Axt
	torch_node.position = Vector3(0, -0.45, 0.25)
	torch_node.rotation_degrees.z = -90.0
	torch_node.rotation_degrees.y = 270.0
	left_arm_pivot.add_child(torch_node)
	# Arm nach vorne strecken (gleich wie bei Axt)
	left_arm_pivot.rotation_degrees.x = -25.0


func unequip_torch() -> void:
	if torch_node and is_instance_valid(torch_node):
		torch_node.queue_free()
		torch_node = null
	if left_arm_pivot:
		left_arm_pivot.rotation_degrees.x = 0.0

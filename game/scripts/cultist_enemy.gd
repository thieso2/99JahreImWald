extends CharacterBody3D

# Kultist – humanoider Feind in der Höhle
# Trägt ein Schwert, ächzt und stöhnt, greift Spieler an

@export var speed: float = 2.5
@export var chase_speed: float = 4.5
@export var damage: float = 25.0
@export var attack_range: float = 2.5
@export var detection_range: float = 10.0
@export var max_hp: float = 40.0
@export var attack_cooldown: float = 1.8

enum State { IDLE, PATROLLING, CHASING, ATTACKING }
var current_state: State = State.IDLE

var hp: float = 40.0
var target_player: CharacterBody3D = null
var patrol_target: Vector3 = Vector3.ZERO
var patrol_timer: float = 0.0
var attack_timer: float = 0.0
var groan_timer: float = 3.0

# Animation
var walk_cycle: float = 0.0
var is_moving: bool = false

# Modell-Teile
var body: MeshInstance3D
var head: MeshInstance3D
var left_arm_pivot: Node3D
var right_arm_pivot: Node3D
var left_leg_pivot: Node3D
var right_leg_pivot: Node3D
var sword: MeshInstance3D

# Materialien
var robe_mat: StandardMaterial3D
var skin_mat: StandardMaterial3D
var hood_mat: StandardMaterial3D
var sword_blade_mat: StandardMaterial3D
var sword_handle_mat: StandardMaterial3D
var eye_mat: StandardMaterial3D


func _ready() -> void:
	hp = max_hp
	patrol_timer = randf_range(2.0, 5.0)
	groan_timer = randf_range(2.0, 6.0)

	_create_materials()
	_build_model()

	# Kollision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	col.shape = shape
	col.position = Vector3(0, 0.9, 0)
	add_child(col)


func _physics_process(delta: float) -> void:
	# Schwerkraft
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	groan_timer -= delta
	if groan_timer <= 0:
		_play_groan()
		groan_timer = randf_range(4.0, 8.0)

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.PATROLLING:
			_process_patrolling(delta)
		State.CHASING:
			_process_chasing(delta)
		State.ATTACKING:
			_process_attacking(delta)

	# Animation
	is_moving = Vector2(velocity.x, velocity.z).length() > 0.3
	if is_moving:
		walk_cycle += delta * 5.0
		_animate_walk()
	else:
		_animate_idle(delta)

	move_and_slide()


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	patrol_timer -= delta
	if patrol_timer <= 0:
		_pick_patrol_target()
		current_state = State.PATROLLING

	_check_for_player()


func _process_patrolling(delta: float) -> void:
	var dir: Vector3 = patrol_target - global_position
	dir.y = 0
	if dir.length() > 1.0:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		_face_direction(dir, delta)
	else:
		current_state = State.IDLE
		patrol_timer = randf_range(2.0, 5.0)

	_check_for_player()


func _process_chasing(delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.IDLE
		target_player = null
		return

	var dir: Vector3 = target_player.global_position - global_position
	dir.y = 0
	var dist: float = dir.length()

	if dist < attack_range:
		current_state = State.ATTACKING
		attack_timer = 0.3  # Kurze Verzögerung vor erstem Angriff
		velocity.x = 0
		velocity.z = 0
	elif dist > detection_range * 2.0:
		target_player = null
		current_state = State.IDLE
	else:
		dir = dir.normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		_face_direction(dir, delta)


func _process_attacking(delta: float) -> void:
	attack_timer -= delta
	velocity.x = 0
	velocity.z = 0

	if attack_timer <= 0:
		if is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < attack_range * 1.2:
				target_player.take_damage(damage)
				attack_timer = attack_cooldown
				_play_attack_sound()
				# Schwert-Schwung Animation
				if right_arm_pivot:
					right_arm_pivot.rotation_degrees.x = -80.0
			else:
				current_state = State.CHASING
		else:
			target_player = null
			current_state = State.IDLE


func _check_for_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody3D:
			var dist: float = global_position.distance_to(p.global_position)
			if dist < detection_range:
				target_player = p
				current_state = State.CHASING
				return


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()


func _pick_patrol_target() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(2.0, 5.0)
	patrol_target = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.1:
		var target_rot: float = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 6.0 * delta)


func _play_groan() -> void:
	var player := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 1.2
	player.stream = gen
	player.max_distance = 15.0
	player.unit_size = 2.0
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var sample_rate: float = 22050.0
	var duration: float = randf_range(0.6, 1.0)
	var samples: int = int(sample_rate * duration)
	var base_freq: float = randf_range(80.0, 140.0)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = sin(t / duration * PI) * 0.5
		# Tiefes Ächzen mit Vibrato
		var vibrato: float = sin(t * 5.0) * 15.0
		var sample: float = sin(t * TAU * (base_freq + vibrato)) * env * 0.25
		# Zweite Harmonische
		sample += sin(t * TAU * (base_freq * 1.5 + vibrato * 0.5)) * env * 0.1
		# Raues Rauschen
		sample += (randf() - 0.5) * env * 0.08
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.3).timeout.connect(player.queue_free)


func _play_attack_sound() -> void:
	var player := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	player.stream = gen
	player.max_distance = 12.0
	player.unit_size = 2.5
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var sample_rate: float = 22050.0
	var samples: int = int(sample_rate * 0.35)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = max(1.0 - t * 3.0, 0.0)
		# Schwert-Schwung: Whoosh + metallischer Klang
		var whoosh: float = (randf() - 0.5) * env * 0.4
		var metal: float = sin(t * TAU * 800.0) * env * env * 0.15
		var sample: float = whoosh + metal
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(0.5).timeout.connect(player.queue_free)


func _create_materials() -> void:
	# Dunkle Kutte
	robe_mat = StandardMaterial3D.new()
	robe_mat.albedo_color = Color(0.12, 0.08, 0.15, 1)

	# Haut (blass)
	skin_mat = StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.6, 0.55, 0.5, 1)

	# Kapuze (noch dunkler)
	hood_mat = StandardMaterial3D.new()
	hood_mat.albedo_color = Color(0.08, 0.05, 0.1, 1)

	# Schwert
	sword_blade_mat = StandardMaterial3D.new()
	sword_blade_mat.albedo_color = Color(0.6, 0.58, 0.55, 1)
	sword_blade_mat.metallic = 0.7

	sword_handle_mat = StandardMaterial3D.new()
	sword_handle_mat.albedo_color = Color(0.25, 0.15, 0.08, 1)

	# Leuchtende Augen (unheimlich)
	eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.7, 0.4, 0.8, 1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.5, 0.2, 0.7, 1)
	eye_mat.emission_energy_multiplier = 1.5


func _build_model() -> void:
	# === KÖRPER (Kutte) ===
	body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.5, 0.7, 0.35)
	body.mesh = body_mesh
	body.material_override = robe_mat
	body.position = Vector3(0, 1.05, 0)
	add_child(body)

	# Kutten-Rock (breiter unten)
	var skirt := MeshInstance3D.new()
	var skirt_mesh := BoxMesh.new()
	skirt_mesh.size = Vector3(0.6, 0.5, 0.4)
	skirt.mesh = skirt_mesh
	skirt.material_override = robe_mat
	skirt.position = Vector3(0, 0.65, 0)
	add_child(skirt)

	# === KOPF MIT KAPUZE ===
	head = MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.35, 0.35, 0.35)
	head.mesh = head_mesh
	head.material_override = skin_mat
	head.position = Vector3(0, 1.6, 0)
	add_child(head)

	# Kapuze
	var hood := MeshInstance3D.new()
	var hood_mesh := BoxMesh.new()
	hood_mesh.size = Vector3(0.42, 0.4, 0.4)
	hood.mesh = hood_mesh
	hood.material_override = hood_mat
	hood.position = Vector3(0, 0.03, -0.02)
	head.add_child(hood)

	# Leuchtende Augen (unter der Kapuze)
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.03
	eye_mesh.height = 0.06
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(0.07 * side, 0.02, 0.17)
		head.add_child(eye)

	# === ARME ===
	left_arm_pivot = Node3D.new()
	left_arm_pivot.position = Vector3(-0.32, 1.3, 0)
	add_child(left_arm_pivot)

	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.14, 0.55, 0.14)

	var left_arm := MeshInstance3D.new()
	left_arm.mesh = arm_mesh
	left_arm.material_override = robe_mat
	left_arm.position = Vector3(0, -0.28, 0)
	left_arm_pivot.add_child(left_arm)

	right_arm_pivot = Node3D.new()
	right_arm_pivot.position = Vector3(0.32, 1.3, 0)
	add_child(right_arm_pivot)

	var right_arm := MeshInstance3D.new()
	right_arm.mesh = arm_mesh
	right_arm.material_override = robe_mat
	right_arm.position = Vector3(0, -0.28, 0)
	right_arm_pivot.add_child(right_arm)

	# Hände (blass)
	var hand_mesh := BoxMesh.new()
	hand_mesh.size = Vector3(0.1, 0.1, 0.1)
	var lh := MeshInstance3D.new()
	lh.mesh = hand_mesh
	lh.material_override = skin_mat
	lh.position = Vector3(0, -0.35, 0)
	left_arm_pivot.add_child(lh)

	var rh := MeshInstance3D.new()
	rh.mesh = hand_mesh
	rh.material_override = skin_mat
	rh.position = Vector3(0, -0.35, 0)
	right_arm_pivot.add_child(rh)

	# === SCHWERT (rechte Hand) ===
	# Griff
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.02
	handle_mesh.bottom_radius = 0.025
	handle_mesh.height = 0.2
	handle.mesh = handle_mesh
	handle.material_override = sword_handle_mat
	handle.position = Vector3(0, -0.45, 0.1)
	right_arm_pivot.add_child(handle)

	# Parierstange
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.12, 0.03, 0.03)
	guard.mesh = guard_mesh
	guard.material_override = sword_blade_mat
	guard.position = Vector3(0, -0.37, 0.1)
	right_arm_pivot.add_child(guard)

	# Klinge
	sword = MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.04, 0.55, 0.02)
	sword.mesh = blade_mesh
	sword.material_override = sword_blade_mat
	sword.position = Vector3(0, -0.65, 0.1)
	right_arm_pivot.add_child(sword)

	# === BEINE ===
	left_leg_pivot = Node3D.new()
	left_leg_pivot.position = Vector3(-0.12, 0.45, 0)
	add_child(left_leg_pivot)

	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.16, 0.45, 0.16)
	var ll := MeshInstance3D.new()
	ll.mesh = leg_mesh
	ll.material_override = robe_mat
	ll.position = Vector3(0, -0.22, 0)
	left_leg_pivot.add_child(ll)

	right_leg_pivot = Node3D.new()
	right_leg_pivot.position = Vector3(0.12, 0.45, 0)
	add_child(right_leg_pivot)

	var rl := MeshInstance3D.new()
	rl.mesh = leg_mesh
	rl.material_override = robe_mat
	rl.position = Vector3(0, -0.22, 0)
	right_leg_pivot.add_child(rl)

	# Schuhe
	var shoe_mat := StandardMaterial3D.new()
	shoe_mat.albedo_color = Color(0.1, 0.08, 0.08, 1)
	var shoe_mesh := BoxMesh.new()
	shoe_mesh.size = Vector3(0.17, 0.1, 0.22)
	for pivot in [left_leg_pivot, right_leg_pivot]:
		var shoe := MeshInstance3D.new()
		shoe.mesh = shoe_mesh
		shoe.material_override = shoe_mat
		shoe.position = Vector3(0, -0.48, 0.03)
		pivot.add_child(shoe)


func _animate_walk() -> void:
	var swing: float = sin(walk_cycle)
	left_leg_pivot.rotation.x = swing * deg_to_rad(25.0)
	right_leg_pivot.rotation.x = -swing * deg_to_rad(25.0)
	left_arm_pivot.rotation.x = -swing * deg_to_rad(15.0)
	# Rechter Arm hält Schwert – weniger Schwung
	right_arm_pivot.rotation_degrees.x = lerp(right_arm_pivot.rotation_degrees.x, swing * 8.0 - 20.0, 0.2)

	body.position.y = 1.05 + abs(cos(walk_cycle)) * 0.02


func _animate_idle(delta: float) -> void:
	var rs: float = 4.0
	left_leg_pivot.rotation.x = lerp(left_leg_pivot.rotation.x, 0.0, rs * delta)
	right_leg_pivot.rotation.x = lerp(right_leg_pivot.rotation.x, 0.0, rs * delta)
	left_arm_pivot.rotation.x = lerp(left_arm_pivot.rotation.x, 0.0, rs * delta)
	right_arm_pivot.rotation_degrees.x = lerp(right_arm_pivot.rotation_degrees.x, -20.0, rs * delta)
	body.position.y = lerp(body.position.y, 1.05, rs * delta)

	# Leichtes Atmen
	var breath: float = sin(Time.get_ticks_msec() * 0.002) * 0.005
	body.position.y += breath

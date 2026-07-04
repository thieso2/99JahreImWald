extends CharacterBody3D

# Wolf – feindliches Tier, jagt den Spieler wie der Hirsch
# Kann mit der Axt erlegt werden
# Drops: 1 Steak, 2 Fleischklumpen, manchmal ein Wolfspelz

@export var speed: float = 2.0
@export var chase_speed: float = 5.0
@export var damage: float = 20.0
@export var attack_range: float = 2.0
@export var detection_range: float = 10.0
@export var max_hp: float = 6.0
@export var attack_cooldown: float = 1.5

enum State { IDLE, PATROLLING, CHASING, ATTACKING }
var current_state: State = State.IDLE
var animal_name: String = "Wolf"

var hp: float = 6.0
var target_player: CharacterBody3D = null
var patrol_target: Vector3 = Vector3.ZERO
var patrol_timer: float = 0.0
var attack_timer: float = 0.0
var growl_timer: float = 4.0

# Animation
var walk_cycle: float = 0.0

# Modell-Teile
var body: MeshInstance3D
var head: MeshInstance3D
var tail: MeshInstance3D
var leg_pivots: Array = []

var dropped_item_script: GDScript = null


func _ready() -> void:
	hp = max_hp
	add_to_group("animal")
	patrol_timer = randf_range(2.0, 5.0)
	growl_timer = randf_range(3.0, 8.0)
	dropped_item_script = preload("res://scripts/dropped_item.gd")

	_build_model()

	# Kollision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.0
	col.shape = shape
	col.position = Vector3(0, 0.45, 0)
	col.rotation.x = PI / 2.0
	add_child(col)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	growl_timer -= delta
	if growl_timer <= 0:
		_play_growl()
		growl_timer = randf_range(5.0, 10.0)

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
	var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.3
	if moving:
		walk_cycle += delta * 8.0
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

	# Spieler in der sicheren Zone (Lagerfeuer) → aufgeben
	if target_player.get("is_safe"):
		target_player = null
		current_state = State.IDLE
		patrol_timer = randf_range(2.0, 4.0)
		return

	var dir: Vector3 = target_player.global_position - global_position
	dir.y = 0
	var dist: float = dir.length()

	if dist < attack_range:
		current_state = State.ATTACKING
		attack_timer = 0.3
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
		if is_instance_valid(target_player) and not target_player.get("is_safe"):
			var dist: float = global_position.distance_to(target_player.global_position)
			if dist < attack_range * 1.3:
				target_player.take_damage(damage)
				attack_timer = attack_cooldown
				_play_bite_sound()
				# Biss-Animation: Kopf schnappt nach vorne
				if head:
					head.rotation.x = 0.4
			else:
				current_state = State.CHASING
		else:
			target_player = null
			current_state = State.IDLE


func _check_for_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody3D:
			if p.get("is_safe"):
				continue  # Am Lagerfeuer sicher
			var dist: float = global_position.distance_to(p.global_position)
			if dist < detection_range:
				target_player = p
				current_state = State.CHASING
				return


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_spawn_drops()
		queue_free()
	else:
		# Getroffener Wolf wird sofort aggressiv
		var players: Array = get_tree().get_nodes_in_group("player")
		for p in players:
			if p is CharacterBody3D:
				target_player = p
				current_state = State.CHASING
				return


func _spawn_drops() -> void:
	if not dropped_item_script:
		return
	var drops: Array = ["steak", "meat_chunk", "meat_chunk"]
	# 25% Chance auf einen Wolfspelz
	if randf() < 0.25:
		drops.append("wolf_pelt")

	for drop_type in drops:
		var item := Area3D.new()
		item.set_script(dropped_item_script)
		item.item_string = drop_type
		item.position = global_position + Vector3(0, 0.5, 0)
		item.add_to_group("dropped_item")
		var scene_root: Node = get_tree().current_scene
		if scene_root:
			scene_root.add_child(item)


func _play_growl() -> void:
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 1.2
	audio.stream = gen
	audio.max_distance = 18.0
	audio.unit_size = 2.0
	add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var duration: float = randf_range(0.7, 1.0)
	var samples: int = int(sample_rate * duration)
	var base_freq: float = randf_range(55.0, 75.0)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = sin(t / duration * PI) * 0.5
		# Tiefes Knurren: raue tiefe Frequenz + Rauschen
		var rumble: float = sin(t * TAU * base_freq) * env * 0.2
		rumble += sin(t * TAU * base_freq * 1.5) * env * 0.1
		var noise: float = (randf() - 0.5) * env * 0.15
		var sample: float = rumble + noise
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.3).timeout.connect(audio.queue_free)


func _play_bite_sound() -> void:
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.5
	audio.stream = gen
	audio.max_distance = 12.0
	audio.unit_size = 2.5
	add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var samples: int = int(sample_rate * 0.3)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = max(1.0 - t * 4.0, 0.0)
		# Schnappen: kurzes Knacken + Knurren
		var snap: float = (randf() - 0.5) * env * env * 0.5
		var growl: float = sin(t * TAU * 90.0) * env * 0.2
		var sample: float = snap + growl
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(0.5).timeout.connect(audio.queue_free)


func _pick_patrol_target() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(3.0, 8.0)
	patrol_target = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.1:
		var target_rot: float = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 6.0 * delta)


func _build_model() -> void:
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.35, 0.35, 0.38, 1)  # Grau
	var dark_fur_mat := StandardMaterial3D.new()
	dark_fur_mat.albedo_color = Color(0.22, 0.22, 0.25, 1)  # Dunkler Rücken
	var snout_mat := StandardMaterial3D.new()
	snout_mat.albedo_color = Color(0.15, 0.13, 0.12, 1)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.9, 0.75, 0.2, 1)  # Gelbe Augen
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.7, 0.55, 0.1, 1)
	eye_mat.emission_energy_multiplier = 0.8

	# Körper (länglich, horizontal)
	body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.35, 0.35, 0.9)
	body.mesh = body_mesh
	body.material_override = fur_mat
	body.position = Vector3(0, 0.55, 0)
	add_child(body)

	# Dunkler Rücken-Streifen
	var back := MeshInstance3D.new()
	var back_mesh := BoxMesh.new()
	back_mesh.size = Vector3(0.25, 0.08, 0.85)
	back.mesh = back_mesh
	back.material_override = dark_fur_mat
	back.position = Vector3(0, 0.2, 0)
	body.add_child(back)

	# Kopf
	head = MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.28, 0.28, 0.3)
	head.mesh = head_mesh
	head.material_override = fur_mat
	head.position = Vector3(0, 0.7, 0.55)
	add_child(head)

	# Schnauze
	var snout := MeshInstance3D.new()
	var snout_mesh := BoxMesh.new()
	snout_mesh.size = Vector3(0.14, 0.12, 0.2)
	snout.mesh = snout_mesh
	snout.material_override = snout_mat
	snout.position = Vector3(0, -0.05, 0.23)
	head.add_child(snout)

	# Ohren (spitz)
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.005
		ear_mesh.bottom_radius = 0.05
		ear_mesh.height = 0.15
		ear.mesh = ear_mesh
		ear.material_override = dark_fur_mat
		ear.position = Vector3(0.09 * side, 0.2, -0.05)
		head.add_child(ear)

	# Leuchtende Augen
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.03
		eye_mesh.height = 0.06
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(0.08 * side, 0.05, 0.16)
		head.add_child(eye)

	# Schwanz (buschig, nach hinten oben)
	tail = MeshInstance3D.new()
	var tail_mesh := CapsuleMesh.new()
	tail_mesh.radius = 0.06
	tail_mesh.height = 0.45
	tail.mesh = tail_mesh
	tail.material_override = dark_fur_mat
	tail.position = Vector3(0, 0.65, -0.55)
	tail.rotation.x = deg_to_rad(-50.0)
	add_child(tail)

	# 4 Beine mit Pivots für Lauf-Animation
	var leg_mesh := BoxMesh.new()
	leg_mesh.size = Vector3(0.1, 0.4, 0.1)
	for x_side in [-1, 1]:
		for z_pos in [0.3, -0.3]:
			var pivot := Node3D.new()
			pivot.position = Vector3(0.13 * x_side, 0.42, z_pos)
			add_child(pivot)
			leg_pivots.append(pivot)

			var leg := MeshInstance3D.new()
			leg.mesh = leg_mesh
			leg.material_override = fur_mat
			leg.position = Vector3(0, -0.2, 0)
			pivot.add_child(leg)

			# Pfote
			var paw := MeshInstance3D.new()
			var paw_mesh := BoxMesh.new()
			paw_mesh.size = Vector3(0.11, 0.06, 0.13)
			paw.mesh = paw_mesh
			paw.material_override = dark_fur_mat
			paw.position = Vector3(0, -0.39, 0.02)
			pivot.add_child(paw)


func _animate_walk() -> void:
	var swing: float = sin(walk_cycle)
	# Diagonale Beinpaare bewegen sich zusammen (Trab)
	if leg_pivots.size() == 4:
		leg_pivots[0].rotation.x = swing * deg_to_rad(30.0)   # vorne links
		leg_pivots[1].rotation.x = -swing * deg_to_rad(30.0)  # hinten links
		leg_pivots[2].rotation.x = -swing * deg_to_rad(30.0)  # vorne rechts
		leg_pivots[3].rotation.x = swing * deg_to_rad(30.0)   # hinten rechts

	body.position.y = 0.55 + abs(cos(walk_cycle)) * 0.02
	# Schwanz wedelt leicht beim Laufen
	if tail:
		tail.rotation.z = sin(walk_cycle * 1.5) * 0.15
	# Kopf zurück zur Normalposition nach Biss
	if head:
		head.rotation.x = lerp(head.rotation.x, 0.0, 0.15)


func _animate_idle(delta: float) -> void:
	var rs: float = 4.0
	for pivot in leg_pivots:
		pivot.rotation.x = lerp(pivot.rotation.x, 0.0, rs * delta)
	body.position.y = lerp(body.position.y, 0.55, rs * delta)
	if head:
		head.rotation.x = lerp(head.rotation.x, 0.0, rs * delta)

	# Leichtes Atmen
	var breath: float = sin(Time.get_ticks_msec() * 0.002) * 0.004
	body.position.y += breath

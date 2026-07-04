extends CharacterBody3D

# Hase – friedliches Tier, hoppelt durch den Wald
# Flieht vor dem Spieler, kann mit der Axt erlegt werden
# Drops: 1-2 Fleischstückchen, manchmal ein Hasenfuß

@export var hop_speed: float = 2.0
@export var flee_speed: float = 4.5
@export var flee_range: float = 5.0
@export var max_hp: float = 1.0

enum State { IDLE, HOPPING, FLEEING }
var current_state: State = State.IDLE
var animal_name: String = "Hase"

var hp: float = 1.0
var hop_target: Vector3 = Vector3.ZERO
var idle_timer: float = 0.0
var hop_cycle: float = 0.0

# Modell-Teile
var body: MeshInstance3D
var head: MeshInstance3D

var dropped_item_script: GDScript = null


func _ready() -> void:
	hp = max_hp
	add_to_group("animal")
	idle_timer = randf_range(1.0, 3.0)
	dropped_item_script = preload("res://scripts/dropped_item.gd")

	_build_model()

	# Kollision
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.2
	shape.height = 0.5
	col.shape = shape
	col.position = Vector3(0, 0.25, 0)
	add_child(col)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.HOPPING:
			_process_hopping(delta)
		State.FLEEING:
			_process_fleeing(delta)

	# Hoppel-Animation: kleine Sprünge bei Bewegung
	var moving: bool = Vector2(velocity.x, velocity.z).length() > 0.3
	if moving and is_on_floor():
		velocity.y = 2.2  # Kleiner Hüpfer
	if moving:
		hop_cycle += delta * 8.0
		if body:
			body.rotation.x = sin(hop_cycle) * 0.15
	else:
		if body:
			body.rotation.x = lerp(body.rotation.x, 0.0, 5.0 * delta)
			# Nase wackelt im Idle
			if head:
				head.rotation.x = sin(Time.get_ticks_msec() * 0.01) * 0.03

	move_and_slide()
	_check_for_player()


func _process_idle(delta: float) -> void:
	velocity.x = 0
	velocity.z = 0
	idle_timer -= delta
	if idle_timer <= 0:
		_pick_hop_target()
		current_state = State.HOPPING


func _process_hopping(delta: float) -> void:
	var dir: Vector3 = hop_target - global_position
	dir.y = 0
	if dir.length() > 0.8:
		dir = dir.normalized()
		velocity.x = dir.x * hop_speed
		velocity.z = dir.z * hop_speed
		_face_direction(dir, delta)
	else:
		current_state = State.IDLE
		idle_timer = randf_range(1.5, 4.0)


func _process_fleeing(delta: float) -> void:
	var player: CharacterBody3D = _get_nearest_player()
	if player == null:
		current_state = State.IDLE
		idle_timer = randf_range(1.0, 2.0)
		return

	var dist: float = global_position.distance_to(player.global_position)
	if dist > flee_range * 2.0:
		current_state = State.IDLE
		idle_timer = randf_range(1.0, 2.0)
		return

	# Vom Spieler weg hoppeln
	var dir: Vector3 = global_position - player.global_position
	dir.y = 0
	dir = dir.normalized()
	velocity.x = dir.x * flee_speed
	velocity.z = dir.z * flee_speed
	_face_direction(dir, delta)


func _check_for_player() -> void:
	if current_state == State.FLEEING:
		return
	var player: CharacterBody3D = _get_nearest_player()
	if player and global_position.distance_to(player.global_position) < flee_range:
		current_state = State.FLEEING


func _get_nearest_player() -> CharacterBody3D:
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody3D:
			return p
	return null


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_play_squeak()
		_spawn_drops()
		queue_free()


func _spawn_drops() -> void:
	if not dropped_item_script:
		return
	var drops: Array = []
	# 1-2 Fleischstückchen
	var meat_count: int = randi_range(1, 2)
	for i in range(meat_count):
		drops.append("meat_small")
	# 30% Chance auf einen Hasenfuß
	if randf() < 0.3:
		drops.append("rabbit_foot")

	for drop_type in drops:
		var item := Area3D.new()
		item.set_script(dropped_item_script)
		item.item_string = drop_type
		item.position = global_position + Vector3(0, 0.5, 0)
		item.add_to_group("dropped_item")
		var scene_root: Node = get_tree().current_scene
		if scene_root:
			scene_root.add_child(item)


func _play_squeak() -> void:
	# Kurzer hoher Quiek-Laut
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.4
	audio.stream = gen
	audio.max_distance = 12.0
	audio.unit_size = 2.0
	# An Szene hängen, da der Hase gleich verschwindet
	var scene_root: Node = get_tree().current_scene
	if not scene_root:
		return
	audio.position = global_position
	scene_root.add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var duration: float = 0.25
	var samples: int = int(sample_rate * duration)
	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = max(1.0 - t / duration, 0.0)
		var freq: float = 1400.0 - t * 1800.0  # Abfallender Quiek
		var sample: float = sin(t * TAU * freq) * env * 0.2
		playback.push_frame(Vector2(sample, sample))

	scene_root.get_tree().create_timer(duration + 0.3).timeout.connect(audio.queue_free)


func _pick_hop_target() -> void:
	var angle: float = randf() * TAU
	var dist: float = randf_range(2.0, 5.0)
	hop_target = global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)


func _face_direction(dir: Vector3, delta: float) -> void:
	if dir.length() > 0.1:
		var target_rot: float = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 8.0 * delta)


func _build_model() -> void:
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.65, 0.55, 0.45, 1)  # Graubraun
	var belly_mat := StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.85, 0.8, 0.75, 1)  # Helles Bauchfell
	var inner_ear_mat := StandardMaterial3D.new()
	inner_ear_mat.albedo_color = Color(0.9, 0.7, 0.7, 1)  # Rosa
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.05, 0.05, 1)

	# Körper (gedrungen, leicht nach vorne geneigt)
	body = MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.18
	body_mesh.height = 0.32
	body.mesh = body_mesh
	body.material_override = fur_mat
	body.position = Vector3(0, 0.2, 0)
	body.scale = Vector3(1.0, 0.9, 1.3)
	add_child(body)

	# Bauch
	var belly := MeshInstance3D.new()
	var belly_mesh := SphereMesh.new()
	belly_mesh.radius = 0.13
	belly_mesh.height = 0.24
	belly.mesh = belly_mesh
	belly.material_override = belly_mat
	belly.position = Vector3(0, -0.05, 0.03)
	body.add_child(belly)

	# Kopf
	head = MeshInstance3D.new()
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.11
	head_mesh.height = 0.2
	head.mesh = head_mesh
	head.material_override = fur_mat
	head.position = Vector3(0, 0.35, 0.15)
	add_child(head)

	# Ohren (lang, aufrecht)
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		var ear_mesh := CapsuleMesh.new()
		ear_mesh.radius = 0.03
		ear_mesh.height = 0.22
		ear.mesh = ear_mesh
		ear.material_override = fur_mat
		ear.position = Vector3(0.05 * side, 0.16, -0.02)
		ear.rotation.z = side * -0.15
		head.add_child(ear)

		var inner := MeshInstance3D.new()
		var inner_mesh := CapsuleMesh.new()
		inner_mesh.radius = 0.015
		inner_mesh.height = 0.14
		inner.mesh = inner_mesh
		inner.material_override = inner_ear_mat
		inner.position = Vector3(0.05 * side, 0.16, 0.01)
		inner.rotation.z = side * -0.15
		head.add_child(inner)

	# Augen
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.02
		eye_mesh.height = 0.04
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(0.07 * side, 0.02, 0.08)
		head.add_child(eye)

	# Schwanz-Puschel (weiß)
	var tail := MeshInstance3D.new()
	var tail_mesh := SphereMesh.new()
	tail_mesh.radius = 0.05
	tail_mesh.height = 0.1
	tail.mesh = tail_mesh
	tail.material_override = belly_mat
	tail.position = Vector3(0, 0.18, -0.22)
	add_child(tail)

	# Vorderpfoten
	for side in [-1, 1]:
		var paw := MeshInstance3D.new()
		var paw_mesh := CapsuleMesh.new()
		paw_mesh.radius = 0.025
		paw_mesh.height = 0.12
		paw.mesh = paw_mesh
		paw.material_override = fur_mat
		paw.position = Vector3(0.08 * side, 0.08, 0.12)
		add_child(paw)

	# Hinterläufe (größer)
	for side in [-1, 1]:
		var leg := MeshInstance3D.new()
		var leg_mesh := SphereMesh.new()
		leg_mesh.radius = 0.06
		leg_mesh.height = 0.12
		leg.mesh = leg_mesh
		leg.material_override = fur_mat
		leg.position = Vector3(0.12 * side, 0.08, -0.1)
		leg.scale = Vector3(0.8, 1.0, 1.4)
		add_child(leg)

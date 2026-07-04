extends CharacterBody3D

# Fledermaus – blind, spürt Spieler durch Echolokations-Schrei auf
# Fliegt im Kreis, schreit regelmäßig, greift an wenn Spieler in der Nähe

@export var fly_speed: float = 3.0
@export var attack_speed: float = 6.0
@export var damage: float = 15.0
@export var detection_range: float = 12.0
@export var attack_range: float = 1.5
@export var screech_interval: float = 4.0
@export var max_hp: float = 3.0

var hp: float = 3.0
var animal_name: String = "Fledermaus"

enum State { IDLE, SCREECHING, CHASING, ATTACKING }
var current_state: State = State.IDLE

var target_player: CharacterBody3D = null
var fly_angle: float = 0.0
var fly_center: Vector3 = Vector3.ZERO
var fly_radius: float = 3.0
var fly_height: float = 3.5
var screech_timer: float = 2.0
var attack_timer: float = 0.0
var screech_duration: float = 0.0
var lost_timer: float = 0.0

# Modell
var body_mesh: MeshInstance3D
var left_wing: MeshInstance3D
var right_wing: MeshInstance3D
var wing_cycle: float = 0.0

# Materialien
var fur_mat: StandardMaterial3D
var wing_mat: StandardMaterial3D
var eye_mat: StandardMaterial3D


func _ready() -> void:
	hp = max_hp
	add_to_group("animal")  # Mit der Axt angreifbar
	fly_center = position
	fly_angle = randf() * TAU
	fly_radius = randf_range(2.0, 4.0)

	_create_materials()
	_build_model()

	# Kollision
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	add_child(col)


func take_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_spawn_drops()
		queue_free()


func _spawn_drops() -> void:
	# 1 Fleischstückchen
	var dropped_item_script: GDScript = preload("res://scripts/dropped_item.gd")
	var item := Area3D.new()
	item.set_script(dropped_item_script)
	item.item_string = "meat_small"
	item.position = global_position
	item.add_to_group("dropped_item")
	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(item)


func _physics_process(delta: float) -> void:
	wing_cycle += delta * 15.0
	_animate_wings()

	screech_timer -= delta

	match current_state:
		State.IDLE:
			_process_idle(delta)
		State.SCREECHING:
			_process_screeching(delta)
		State.CHASING:
			_process_chasing(delta)
		State.ATTACKING:
			_process_attacking(delta)

	move_and_slide()


func _process_idle(delta: float) -> void:
	# Im Kreis fliegen
	fly_angle += delta * 0.8
	var target_pos := fly_center + Vector3(cos(fly_angle) * fly_radius, fly_height, sin(fly_angle) * fly_radius)
	var dir: Vector3 = target_pos - global_position
	velocity = dir.normalized() * fly_speed

	# Zum Flugziel schauen
	var look_dir := Vector3(velocity.x, 0, velocity.z)
	if look_dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(look_dir.x, look_dir.z), 5.0 * delta)

	# Regelmäßig schreien (Echolokation)
	if screech_timer <= 0:
		current_state = State.SCREECHING
		screech_duration = 0.6
		screech_timer = screech_interval + randf_range(-1.0, 1.0)
		_play_screech()


func _process_screeching(delta: float) -> void:
	# Kurz stoppen beim Schreien
	velocity = Vector3(0, 0, 0)
	screech_duration -= delta

	if screech_duration <= 0:
		# Nach dem Schrei: Spieler suchen (Echolokation)
		_echolocate()
		if target_player != null:
			current_state = State.CHASING
		else:
			current_state = State.IDLE


func _process_chasing(delta: float) -> void:
	if not is_instance_valid(target_player):
		current_state = State.IDLE
		target_player = null
		return

	var dir: Vector3 = target_player.global_position + Vector3(0, 1.5, 0) - global_position
	var dist: float = dir.length()

	if dist < attack_range:
		current_state = State.ATTACKING
		attack_timer = 0.0
	else:
		velocity = dir.normalized() * attack_speed
		var look_dir := Vector3(velocity.x, 0, velocity.z)
		if look_dir.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(look_dir.x, look_dir.z), 6.0 * delta)

	# Spieler verloren? (zu weit weg)
	if dist > detection_range * 1.5:
		lost_timer += delta
		if lost_timer > 3.0:
			target_player = null
			current_state = State.IDLE
			lost_timer = 0.0
	else:
		lost_timer = 0.0


func _process_attacking(delta: float) -> void:
	attack_timer -= delta
	velocity = Vector3.ZERO

	if attack_timer <= 0:
		if is_instance_valid(target_player):
			var dist: float = global_position.distance_to(target_player.global_position + Vector3(0, 1.5, 0))
			if dist < attack_range * 1.5:
				target_player.take_damage(damage)
				attack_timer = 1.0
			else:
				current_state = State.CHASING
		else:
			current_state = State.IDLE
			target_player = null


func _echolocate() -> void:
	# "Echolokation" – Spieler finden durch Schrei
	var players: Array = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is CharacterBody3D:
			var dist: float = global_position.distance_to(p.global_position)
			if dist < detection_range:
				target_player = p
				return


func _play_screech() -> void:
	# Prozeduraler Fledermaus-Schrei via AudioStreamGenerator
	var player := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.6
	player.stream = gen
	player.max_distance = 20.0
	player.unit_size = 3.0
	add_child(player)
	player.play()

	var playback: AudioStreamGeneratorPlayback = player.get_stream_playback()
	var sample_rate: float = 22050.0
	var samples: int = int(sample_rate * 0.5)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = 1.0 - t * 2.0
		env = max(env, 0.0) * max(env, 0.0)

		# Hochfrequenter Schrei (2000-5000 Hz, moduliert)
		var freq: float = 3000.0 + sin(t * 40.0) * 1500.0
		var sample: float = sin(t * TAU * freq) * env * 0.3
		# Rauschen dazu
		sample += (randf() - 0.5) * env * 0.15

		playback.push_frame(Vector2(sample, sample))

	# AudioStreamPlayer nach dem Abspielen entfernen
	get_tree().create_timer(0.7).timeout.connect(player.queue_free)


func _create_materials() -> void:
	fur_mat = StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.12, 0.1, 0.1, 1)

	wing_mat = StandardMaterial3D.new()
	wing_mat.albedo_color = Color(0.08, 0.06, 0.06, 0.9)
	wing_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	eye_mat = StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.6, 0.6, 0.6, 1)  # Blinde, milchige Augen


func _build_model() -> void:
	# Körper (klein, oval)
	body_mesh = MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.15
	bm.height = 0.25
	body_mesh.mesh = bm
	body_mesh.material_override = fur_mat
	add_child(body_mesh)

	# Kopf
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.1
	hm.height = 0.16
	head.mesh = hm
	head.material_override = fur_mat
	head.position = Vector3(0, 0.05, 0.12)
	add_child(head)

	# Blinde Augen (milchig weiß, klein)
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.025
	eye_mesh.height = 0.05
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(0.04 * side, 0.02, 0.08)
		head.add_child(eye)

	# Ohren (groß – für Echolokation)
	var ear_mesh := BoxMesh.new()
	ear_mesh.size = Vector3(0.04, 0.12, 0.06)
	for side in [-1, 1]:
		var ear := MeshInstance3D.new()
		ear.mesh = ear_mesh
		ear.material_override = fur_mat
		ear.position = Vector3(0.06 * side, 0.1, 0.02)
		ear.rotation_degrees.z = -20.0 * side
		head.add_child(ear)

	# Maul (offen)
	var mouth := MeshInstance3D.new()
	var mouth_mesh := BoxMesh.new()
	mouth_mesh.size = Vector3(0.06, 0.03, 0.04)
	mouth.mesh = mouth_mesh
	var mouth_mat := StandardMaterial3D.new()
	mouth_mat.albedo_color = Color(0.3, 0.08, 0.08, 1)
	mouth.material_override = mouth_mat
	mouth.position = Vector3(0, -0.04, 0.1)
	head.add_child(mouth)

	# Kleine Zähne
	var fang_mesh := BoxMesh.new()
	fang_mesh.size = Vector3(0.01, 0.03, 0.01)
	var teeth_mat := StandardMaterial3D.new()
	teeth_mat.albedo_color = Color(0.9, 0.85, 0.75, 1)
	for side in [-1, 1]:
		var fang := MeshInstance3D.new()
		fang.mesh = fang_mesh
		fang.material_override = teeth_mat
		fang.position = Vector3(0.02 * side, -0.06, 0.1)
		head.add_child(fang)

	# Flügel
	left_wing = MeshInstance3D.new()
	var wm := BoxMesh.new()
	wm.size = Vector3(0.5, 0.02, 0.3)
	left_wing.mesh = wm
	left_wing.material_override = wing_mat
	left_wing.position = Vector3(-0.3, 0, 0)
	add_child(left_wing)

	right_wing = MeshInstance3D.new()
	right_wing.mesh = wm
	right_wing.material_override = wing_mat
	right_wing.position = Vector3(0.3, 0, 0)
	add_child(right_wing)


func _animate_wings() -> void:
	var flap: float = sin(wing_cycle) * 0.6
	left_wing.rotation.z = flap + 0.2
	right_wing.rotation.z = -flap - 0.2

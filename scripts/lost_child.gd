extends Node3D

# Vermisstes Kind – von den Kultisten in der Unterwelt eingesperrt
# Sitzt in einem Holzkäfig, schluchzt leise (Audio-Hinweis zum Finden)
# Mit E-Taste befreien; gerettete Kinder sitzen danach am Lagerfeuer

@export var shirt_color: Color = Color(0.85, 0.3, 0.25, 1)
@export var saved_mode: bool = false  # true = sitzt gerettet am Lagerfeuer (kein Käfig)

signal rescued()

var is_rescued: bool = false
var sob_timer: float = 4.0
var cage_root: Node3D = null
var body: MeshInstance3D = null
var idle_time: float = 0.0


func _ready() -> void:
	if not saved_mode:
		add_to_group("lost_child")
	_build_child_model()
	if not saved_mode:
		_build_cage()
		sob_timer = randf_range(2.0, 6.0)


func _process(delta: float) -> void:
	idle_time += delta
	# Leichtes Atmen/Zittern
	if body:
		body.scale.y = 1.0 + sin(idle_time * (5.0 if not saved_mode else 2.0)) * 0.02

	if saved_mode or is_rescued:
		return

	sob_timer -= delta
	if sob_timer <= 0:
		_play_sob()
		sob_timer = randf_range(5.0, 10.0)


func try_rescue(by: Node3D) -> bool:
	# Wird vom GameManager aufgerufen wenn E gedrückt wird
	if saved_mode or is_rescued:
		return false
	var dist: float = by.global_position.distance_to(global_position)
	if dist > 3.0:
		return false

	is_rescued = true
	_play_rescue_sound()

	# Käfig verschwindet sofort, Kind kurz danach
	if cage_root:
		cage_root.queue_free()
	get_tree().create_timer(0.8).timeout.connect(queue_free)

	rescued.emit()
	return true


func _play_sob() -> void:
	# Leises Schluchzen – hilft beim Finden im Dunkeln
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 1.0
	audio.stream = gen
	audio.max_distance = 14.0
	audio.unit_size = 2.0
	add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var duration: float = 0.7
	var samples: int = int(sample_rate * duration)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		# Zwei kurze Schluchzer hintereinander
		var phase: float = fmod(t, 0.35) / 0.35
		var env: float = sin(phase * PI) * 0.5
		var freq: float = 400.0 + sin(t * 20.0) * 60.0  # Zittrige Stimme
		var sample: float = sin(t * TAU * freq) * env * 0.1
		sample += sin(t * TAU * freq * 2.0) * env * 0.04
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.3).timeout.connect(audio.queue_free)


func _play_rescue_sound() -> void:
	# Fröhlicher aufsteigender Dreiklang
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 1.2
	audio.stream = gen
	audio.max_distance = 15.0
	audio.unit_size = 2.5
	add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var notes: Array = [523.25, 659.25, 783.99]  # C5, E5, G5
	var note_len: float = 0.22

	for n in range(notes.size()):
		var freq: float = notes[n]
		var samples: int = int(sample_rate * note_len)
		for i in range(samples):
			var t: float = float(i) / sample_rate
			var env: float = sin(t / note_len * PI)
			var sample: float = sin(t * TAU * freq) * env * 0.15
			sample += sin(t * TAU * freq * 2.0) * env * 0.05
			playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(1.0).timeout.connect(audio.queue_free)


func _build_child_model() -> void:
	var skin_mat := StandardMaterial3D.new()
	skin_mat.albedo_color = Color(0.9, 0.75, 0.6, 1)
	var shirt_mat := StandardMaterial3D.new()
	shirt_mat.albedo_color = shirt_color
	# Leichtes Leuchten, damit man das Kind im Dunkeln sieht
	shirt_mat.emission_enabled = true
	shirt_mat.emission = shirt_color
	shirt_mat.emission_energy_multiplier = 0.3
	var pants_mat := StandardMaterial3D.new()
	pants_mat.albedo_color = Color(0.25, 0.3, 0.45, 1)
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = Color(0.35, 0.22, 0.1, 1)

	# Körper (klein, sitzend/kauernd)
	body = MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.35, 0.4, 0.25)
	body.mesh = body_mesh
	body.material_override = shirt_mat
	body.position = Vector3(0, 0.45, 0)
	add_child(body)

	# Kopf
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.28, 0.28, 0.28)
	head.mesh = head_mesh
	head.material_override = skin_mat
	head.position = Vector3(0, 0.8, 0.03)
	head.rotation.x = 0.25 if not saved_mode else 0.0  # Kopf gesenkt wenn gefangen
	add_child(head)

	# Haare
	var hair := MeshInstance3D.new()
	var hair_mesh := BoxMesh.new()
	hair_mesh.size = Vector3(0.3, 0.1, 0.3)
	hair.mesh = hair_mesh
	hair.material_override = hair_mat
	hair.position = Vector3(0, 0.16, 0)
	head.add_child(hair)

	# Augen
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.1, 0.08, 0.08, 1)
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.025
		eye_mesh.height = 0.05
		eye.mesh = eye_mesh
		eye.material_override = eye_mat
		eye.position = Vector3(0.06 * side, 0.0, 0.14)
		head.add_child(eye)

	# Angezogene Beine (kauernd)
	var legs := MeshInstance3D.new()
	var legs_mesh := BoxMesh.new()
	legs_mesh.size = Vector3(0.32, 0.25, 0.3)
	legs.mesh = legs_mesh
	legs.material_override = pants_mat
	legs.position = Vector3(0, 0.15, 0.1)
	add_child(legs)

	# Arme (um die Knie geschlungen)
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.08, 0.3, 0.08)
	for side in [-1, 1]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = shirt_mat
		arm.position = Vector3(0.2 * side, 0.4, 0.12)
		arm.rotation.x = -0.5
		add_child(arm)


func _build_cage() -> void:
	cage_root = Node3D.new()
	add_child(cage_root)

	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = Color(0.3, 0.2, 0.1, 1)

	# 8 senkrechte Gitterstäbe im Kreis
	var bar_mesh := CylinderMesh.new()
	bar_mesh.top_radius = 0.04
	bar_mesh.bottom_radius = 0.04
	bar_mesh.height = 1.5
	for i in range(8):
		var angle: float = float(i) / 8.0 * TAU
		var bar := MeshInstance3D.new()
		bar.mesh = bar_mesh
		bar.material_override = wood_mat
		bar.position = Vector3(cos(angle) * 0.7, 0.75, sin(angle) * 0.7)
		cage_root.add_child(bar)

	# Ring oben und unten
	for y_pos in [0.08, 1.45]:
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.65
		ring_mesh.outer_radius = 0.75
		ring.mesh = ring_mesh
		ring.material_override = wood_mat
		ring.position = Vector3(0, y_pos, 0)
		cage_root.add_child(ring)

extends Node3D

# Portal – Steinbogen mit wirbelnder Magie-Scheibe
# Teleportiert den Spieler zu target_position wenn er hindurchgeht

@export var target_position: Vector3 = Vector3.ZERO
@export var portal_color: Color = Color(0.6, 0.2, 0.9, 1)  # Lila
@export var arrival_message: String = ""

signal player_teleported(message: String)

var disk: MeshInstance3D
var portal_light: OmniLight3D
var pulse_time: float = 0.0

const TELEPORT_COOLDOWN_MS: int = 2000


func _ready() -> void:
	_build_model()

	# Trigger-Bereich in der Mitte des Bogens
	var area := Area3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 3.0, 1.0)
	col.shape = shape
	col.position = Vector3(0, 1.6, 0)
	area.add_child(col)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	pulse_time += delta
	# Wirbelnde Scheibe
	if disk:
		disk.rotation.z += delta * 1.5
	# Pulsierendes Licht
	if portal_light:
		portal_light.light_energy = 1.5 + sin(pulse_time * 3.0) * 0.5


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	# Cooldown verhindert sofortiges Zurück-Teleportieren
	var now: int = Time.get_ticks_msec()
	if body.has_meta("portal_cooldown") and now < body.get_meta("portal_cooldown"):
		return
	body.set_meta("portal_cooldown", now + TELEPORT_COOLDOWN_MS)

	body.global_position = target_position
	_play_teleport_sound()
	player_teleported.emit(arrival_message)


func _play_teleport_sound() -> void:
	var audio := AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 1.0
	audio.stream = gen
	audio.max_distance = 20.0
	audio.unit_size = 3.0
	add_child(audio)
	audio.play()

	var playback: AudioStreamGeneratorPlayback = audio.get_stream_playback()
	var sample_rate: float = 22050.0
	var duration: float = 0.8
	var samples: int = int(sample_rate * duration)

	for i in range(samples):
		var t: float = float(i) / sample_rate
		var env: float = sin(t / duration * PI)
		# Magisches Schimmern: aufsteigender Ton + Obertöne
		var freq: float = 220.0 + t * 600.0
		var sample: float = sin(t * TAU * freq) * env * 0.15
		sample += sin(t * TAU * freq * 1.5) * env * 0.08
		sample += sin(t * TAU * freq * 2.0) * env * 0.05
		playback.push_frame(Vector2(sample, sample))

	get_tree().create_timer(duration + 0.3).timeout.connect(audio.queue_free)


func _build_model() -> void:
	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.35, 0.33, 0.3, 1)
	var rune_mat := StandardMaterial3D.new()
	rune_mat.albedo_color = portal_color
	rune_mat.emission_enabled = true
	rune_mat.emission = portal_color
	rune_mat.emission_energy_multiplier = 1.2

	# Zwei Steinsäulen
	for side in [-1, 1]:
		var pillar := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.6, 3.4, 0.6)
		pillar.mesh = pm
		pillar.material_override = stone_mat
		pillar.position = Vector3(side * 1.5, 1.7, 0)
		add_child(pillar)

		# Leuchtende Rune auf jeder Säule
		var rune := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.15, 0.4, 0.05)
		rune.mesh = rm
		rune.material_override = rune_mat
		rune.position = Vector3(side * 1.5, 1.8, 0.31)
		add_child(rune)

	# Querbalken oben
	var beam := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.9, 0.7, 0.7)
	beam.mesh = bm
	beam.material_override = stone_mat
	beam.position = Vector3(0, 3.6, 0)
	add_child(beam)

	# Wirbelnde Portal-Scheibe
	var disk_mat := StandardMaterial3D.new()
	disk_mat.albedo_color = Color(portal_color.r, portal_color.g, portal_color.b, 0.75)
	disk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	disk_mat.emission_enabled = true
	disk_mat.emission = portal_color
	disk_mat.emission_energy_multiplier = 2.0
	disk_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	disk = MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 1.25
	dm.bottom_radius = 1.25
	dm.height = 0.08
	disk.mesh = dm
	disk.material_override = disk_mat
	disk.position = Vector3(0, 1.7, 0)
	disk.rotation.x = PI / 2.0
	add_child(disk)

	# Innerer heller Kern
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1, 1, 1, 0.9)
	core_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	core_mat.emission_enabled = true
	core_mat.emission = Color(0.9, 0.8, 1.0, 1)
	core_mat.emission_energy_multiplier = 3.0

	var core := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.3
	cm.height = 0.6
	core.mesh = cm
	core.material_override = core_mat
	core.position = Vector3(0, 1.7, 0)
	add_child(core)

	# Pulsierendes Licht
	portal_light = OmniLight3D.new()
	portal_light.light_color = portal_color
	portal_light.omni_range = 8.0
	portal_light.light_energy = 1.5
	portal_light.position = Vector3(0, 1.7, 0)
	add_child(portal_light)

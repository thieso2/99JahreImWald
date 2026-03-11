extends Node

# Prozedural generierte Schrittgeräusche im Wald
# Klingt wie: Laub rascheln, Äste knacken, weicher Waldboden

var sample_rate: float = 22050.0
var playback: AudioStreamPlayback = null
var audio_player: AudioStreamPlayer = null

# Schritt-Timing
var step_timer: float = 0.0
var step_interval: float = 0.38  # Sekunden zwischen Schritten
var is_walking: bool = false

# Sound-Zustand pro Schritt
var step_active: bool = false
var step_phase: float = 0.0
var step_duration: float = 0.0
var step_pitch: float = 0.0
var step_type: int = 0  # 0=Laub, 1=Ast, 2=weich

# Noise-Generator
var noise_phase: float = 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = -8.0
	add_child(audio_player)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.3
	audio_player.stream = generator
	audio_player.play()
	playback = audio_player.get_stream_playback()


func _process(delta: float) -> void:
	if is_walking:
		step_timer += delta
		if step_timer >= step_interval:
			step_timer -= step_interval
			_trigger_step()
			# Leichte Variation im Timing
			step_interval = rng.randf_range(0.32, 0.42)

	if playback:
		_fill_buffer()


func set_walking(walking: bool) -> void:
	is_walking = walking
	if not walking:
		step_timer = 0.0


func _trigger_step() -> void:
	step_active = true
	step_phase = 0.0

	# Zufälliger Schritttyp
	var roll: float = rng.randf()
	if roll < 0.5:
		step_type = 0  # Laub rascheln
		step_duration = rng.randf_range(0.08, 0.14)
		step_pitch = rng.randf_range(800.0, 2000.0)
	elif roll < 0.8:
		step_type = 2  # Weicher Boden
		step_duration = rng.randf_range(0.1, 0.16)
		step_pitch = rng.randf_range(200.0, 500.0)
	else:
		step_type = 1  # Ast knacken
		step_duration = rng.randf_range(0.03, 0.06)
		step_pitch = rng.randf_range(1500.0, 3500.0)


func _fill_buffer() -> void:
	var frames_available: int = playback.get_frames_available()
	if frames_available <= 0:
		return

	for i in range(frames_available):
		var sample: float = _generate_sample()
		playback.push_frame(Vector2(sample, sample))


func _generate_sample() -> float:
	var dt: float = 1.0 / sample_rate

	if not step_active:
		return 0.0

	step_phase += dt
	if step_phase > step_duration:
		step_active = false
		return 0.0

	var t: float = step_phase / step_duration
	var sample: float = 0.0

	match step_type:
		0:
			# Laub rascheln: gefiltertes Rauschen mit schnellem Abklingen
			var envelope: float = (1.0 - t) * (1.0 - t)
			noise_phase += step_pitch * dt
			var noise: float = sin(noise_phase * 6.28) * 0.3 + sin(noise_phase * 13.7) * 0.2 + sin(noise_phase * 29.1) * 0.15
			# Rauschen dazumischen
			noise += (rng.randf() * 2.0 - 1.0) * 0.5
			sample = noise * envelope * 0.4

		1:
			# Ast knacken: kurzer scharfer Impuls
			var envelope: float = (1.0 - t * t * t)
			noise_phase += step_pitch * dt
			var click: float = sin(noise_phase * 6.28)
			click += (rng.randf() * 2.0 - 1.0) * 0.3
			sample = click * envelope * 0.5

		2:
			# Weicher Waldboden: dumpfer, tiefer Aufprall
			var envelope: float = sin(t * 3.14159) * (1.0 - t)
			noise_phase += step_pitch * dt
			var thud: float = sin(noise_phase * 6.28) * 0.5
			thud += (rng.randf() * 2.0 - 1.0) * 0.2
			sample = thud * envelope * 0.35

	# Soft-Clipping
	sample = tanh(sample * 2.0) * 0.5

	return sample

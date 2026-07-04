extends Node

# Prozedural generierte Schrittgeräusche im Wald
# Weiche, natürliche Klänge: Laub rascheln, weicher Erde, gelegentlich Zweig knacken

var sample_rate: float = 22050.0
var playback: AudioStreamPlayback = null
var audio_player: AudioStreamPlayer = null

# Schritt-Timing
var step_timer: float = 0.0
var step_interval: float = 0.38
var is_walking: bool = false

# Sound-Zustand pro Schritt
var step_active: bool = false
var step_phase: float = 0.0
var step_duration: float = 0.0
var step_type: int = 0  # 0=Laub, 1=Erde, 2=Zweig

# Noise für weiche Klänge
var noise_state: float = 0.0  # einfacher Tiefpass-Zustand
var prev_noise: float = 0.0
var rng := RandomNumberGenerator.new()

# Envelope-Parameter pro Schritt
var step_attack: float = 0.0
var step_volume: float = 0.0


func _ready() -> void:
	rng.randomize()

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = -10.0
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
			step_interval = rng.randf_range(0.34, 0.44)

	if playback:
		_fill_buffer()


func set_walking(walking: bool) -> void:
	is_walking = walking
	if not walking:
		step_timer = 0.0


func _trigger_step() -> void:
	step_active = true
	step_phase = 0.0
	noise_state = 0.0
	prev_noise = 0.0

	var roll: float = rng.randf()
	if roll < 0.55:
		step_type = 0  # Laub rascheln
		step_duration = rng.randf_range(0.12, 0.22)
		step_attack = rng.randf_range(0.01, 0.03)
		step_volume = rng.randf_range(0.15, 0.25)
	elif roll < 0.85:
		step_type = 1  # Weiche Erde
		step_duration = rng.randf_range(0.10, 0.18)
		step_attack = rng.randf_range(0.005, 0.015)
		step_volume = rng.randf_range(0.12, 0.20)
	else:
		step_type = 2  # Zweig knacken
		step_duration = rng.randf_range(0.06, 0.10)
		step_attack = 0.002
		step_volume = rng.randf_range(0.18, 0.28)


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

	# Weiche Envelope: schneller Attack, langsamer Decay
	var envelope: float = 0.0
	if step_phase < step_attack:
		envelope = step_phase / step_attack
	else:
		var decay_t: float = (step_phase - step_attack) / (step_duration - step_attack)
		envelope = (1.0 - decay_t) * (1.0 - decay_t)

	# Gefiltertes Rauschen erzeugen (Tiefpass)
	var raw_noise: float = rng.randf() * 2.0 - 1.0

	match step_type:
		0:
			# Laub rascheln: mittel-gefiltertes Rauschen, wie trockene Blätter
			# Stärkerer Tiefpass = weicher
			var cutoff: float = 0.08 + t * 0.04  # wird weicher über Zeit
			noise_state = noise_state * (1.0 - cutoff) + raw_noise * cutoff
			# Zweiter Tiefpass für mehr Weichheit
			prev_noise = prev_noise * 0.85 + noise_state * 0.15
			# Leichte Modulation für Raschel-Charakter
			var rustle: float = prev_noise * (1.0 + sin(step_phase * 180.0) * 0.3)
			sample = rustle * envelope * step_volume

		1:
			# Weiche Erde: sehr tief gefiltert, dumpfer Aufprall
			var cutoff: float = 0.04  # sehr weich
			noise_state = noise_state * (1.0 - cutoff) + raw_noise * cutoff
			prev_noise = prev_noise * 0.92 + noise_state * 0.08
			# Tiefe Resonanz hinzufügen
			var low_thud: float = sin(step_phase * 140.0) * 0.3 * (1.0 - t)
			sample = (prev_noise + low_thud) * envelope * step_volume

		2:
			# Zweig knacken: kurzer Knack mit etwas Rauschen danach
			if t < 0.15:
				# Initialer Knack: breitbandiger
				var cutoff: float = 0.25
				noise_state = noise_state * (1.0 - cutoff) + raw_noise * cutoff
				sample = noise_state * envelope * step_volume * 1.5
			else:
				# Nachklingen: schnell leiser werdendes gefiltertes Rauschen
				var cutoff: float = 0.06
				noise_state = noise_state * (1.0 - cutoff) + raw_noise * cutoff
				prev_noise = prev_noise * 0.9 + noise_state * 0.1
				sample = prev_noise * envelope * step_volume * 0.6

	# Sanftes Clipping
	sample = clampf(sample, -0.5, 0.5)

	return sample

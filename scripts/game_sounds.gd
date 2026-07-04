extends Node

# Prozedural generierte Spielgeräusche
# Hack-Sound, Sammel-Sound, Baum-Fäll-Sound

var sample_rate: float = 22050.0
var rng := RandomNumberGenerator.new()

# Sound-Warteschlange
var pending_sounds: Array = []  # [{type, phase, duration, params}]

var audio_player: AudioStreamPlayer = null
var playback: AudioStreamPlayback = null


func _ready() -> void:
	rng.randomize()

	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = -4.0
	add_child(audio_player)

	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.5
	audio_player.stream = generator
	audio_player.play()
	playback = audio_player.get_stream_playback()


func _process(_delta: float) -> void:
	if playback:
		_fill_buffer()


func play_chop_sound() -> void:
	# Holz-Einschlag: dumpfer Aufprall + kurzes Knacken
	pending_sounds.append({
		"type": "chop",
		"phase": 0.0,
		"duration": 0.25,
		"freq": rng.randf_range(120.0, 180.0),
		"noise_state": 0.0,
	})


func play_pickup_sound() -> void:
	# Aufsammel-Geräusch: kurzes aufsteigendes "Swoosh"
	pending_sounds.append({
		"type": "pickup",
		"phase": 0.0,
		"duration": 0.18,
		"freq": rng.randf_range(400.0, 500.0),
		"noise_state": 0.0,
	})


func play_fell_sound() -> void:
	# Baum fällt: langes Krachen + Aufprall
	pending_sounds.append({
		"type": "fell",
		"phase": 0.0,
		"duration": 0.6,
		"freq": rng.randf_range(80.0, 120.0),
		"noise_state": 0.0,
	})


func _fill_buffer() -> void:
	var frames: int = playback.get_frames_available()
	if frames <= 0:
		return

	for i in range(frames):
		var sample: float = 0.0
		var dt: float = 1.0 / sample_rate

		# Alle aktiven Sounds mischen
		var j: int = 0
		while j < pending_sounds.size():
			var s: Dictionary = pending_sounds[j]
			s.phase += dt

			if s.phase >= s.duration:
				pending_sounds.remove_at(j)
				continue

			sample += _generate_sound_sample(s)
			j += 1

		sample = clampf(sample, -0.8, 0.8)
		playback.push_frame(Vector2(sample, sample))


func _generate_sound_sample(s: Dictionary) -> float:
	var t: float = s.phase / s.duration
	var dt: float = 1.0 / sample_rate
	var result: float = 0.0

	match s.type:
		"chop":
			# Holz-Einschlag: tiefer Schlag + Knack-Rauschen
			var envelope: float = (1.0 - t) * (1.0 - t) * (1.0 - t)

			# Dumpfer Aufprall (tiefe Frequenz)
			var thud: float = sin(s.phase * s.freq * TAU) * 0.5
			thud *= (1.0 - t * 2.0) if t < 0.5 else 0.0

			# Holz-Knack (gefiltertes Rauschen)
			var raw: float = rng.randf() * 2.0 - 1.0
			s.noise_state = s.noise_state * 0.88 + raw * 0.12
			var crack: float = s.noise_state * 0.4

			# Kurzer heller Knack am Anfang
			var attack_crack: float = 0.0
			if t < 0.08:
				attack_crack = (rng.randf() * 2.0 - 1.0) * (1.0 - t / 0.08) * 0.5

			result = (thud + crack + attack_crack) * envelope * 0.6

		"pickup":
			# Aufsteigendes "Swoosh" – angenehm, kurz
			var envelope: float
			if t < 0.2:
				envelope = t / 0.2
			else:
				envelope = (1.0 - t) / 0.8

			# Aufsteigende Frequenz
			var freq: float = s.freq * (1.0 + t * 1.5)
			var tone: float = sin(s.phase * freq * TAU) * 0.25

			# Leichtes Rauschen dazu
			var raw: float = rng.randf() * 2.0 - 1.0
			s.noise_state = s.noise_state * 0.93 + raw * 0.07
			var swoosh: float = s.noise_state * 0.15

			result = (tone + swoosh) * envelope * 0.5

		"fell":
			# Baum fällt: Krachen + dumpfer Aufprall
			var envelope: float
			if t < 0.1:
				envelope = t / 0.1
			elif t < 0.7:
				envelope = 1.0 - (t - 0.1) / 0.6 * 0.5
			else:
				envelope = 0.5 * (1.0 - (t - 0.7) / 0.3)

			# Krach-Rauschen (breitbandig)
			var raw: float = rng.randf() * 2.0 - 1.0
			s.noise_state = s.noise_state * 0.82 + raw * 0.18
			var crash: float = s.noise_state * 0.5

			# Tiefer Aufprall
			var thud: float = sin(s.phase * s.freq * TAU) * 0.4 * (1.0 - t)

			result = (crash + thud) * envelope * 0.5

	return result

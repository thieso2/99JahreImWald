extends Node

# Gruselige Ambient-Musik – prozedural generiert

var sample_rate: float = 22050.0
var playback: AudioStreamPlayback = null

# Drone-Töne (tiefe, unheimliche Frequenzen)
var drone_freq_1: float = 55.0   # Tiefer Basston (A1)
var drone_freq_2: float = 58.3   # Leicht verstimmt -> schwebende Dissonanz
var drone_freq_3: float = 82.4   # Quinte dazu (E2)

# LFO für langsames Pulsieren
var lfo_phase: float = 0.0
var lfo_freq: float = 0.15  # Sehr langsam

# Oszillator-Phasen
var phase_1: float = 0.0
var phase_2: float = 0.0
var phase_3: float = 0.0
var phase_wind: float = 0.0
var phase_creak: float = 0.0

# Zufällige Grusel-Sounds
var random_timer: float = 0.0
var random_pitch: float = 0.0
var random_volume: float = 0.0
var random_decay: float = 0.0

var time: float = 0.0

@onready var audio_player: AudioStreamPlayer = null


func _ready() -> void:
	# AudioStreamPlayer erstellen
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	audio_player.volume_db = -6.0
	add_child(audio_player)

	# AudioStreamGenerator konfigurieren
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.5
	audio_player.stream = generator
	audio_player.play()
	playback = audio_player.get_stream_playback()


func _process(delta: float) -> void:
	time += delta

	# Zufällige Grusel-Geräusche Timer
	random_timer -= delta
	if random_timer <= 0:
		random_timer = randf_range(4.0, 12.0)
		random_pitch = randf_range(200.0, 600.0)
		random_volume = randf_range(0.03, 0.08)
		random_decay = 0.0

	# Audio-Buffer füllen
	if playback:
		_fill_buffer()


func _fill_buffer() -> void:
	var frames_available: int = playback.get_frames_available()
	if frames_available <= 0:
		return

	for i in range(frames_available):
		var sample: float = _generate_sample()
		playback.push_frame(Vector2(sample, sample))


func _generate_sample() -> float:
	var dt: float = 1.0 / sample_rate

	# LFO für langsames Pulsieren
	lfo_phase += lfo_freq * dt
	var lfo: float = sin(lfo_phase * TAU) * 0.5 + 0.5  # 0 bis 1

	# Drone 1: Tiefer Sinus mit leichter Verzerrung
	phase_1 += drone_freq_1 * dt
	var drone1: float = sin(phase_1 * TAU)
	drone1 = drone1 * 0.7 + sin(phase_1 * TAU * 2.0) * 0.1  # Leichter Oberton

	# Drone 2: Verstimmter Ton -> Schwebung
	phase_2 += drone_freq_2 * dt
	var drone2: float = sin(phase_2 * TAU) * 0.5

	# Drone 3: Quinte, pulsiert mit LFO
	phase_3 += drone_freq_3 * dt
	var drone3: float = sin(phase_3 * TAU) * 0.3 * lfo

	# Wind-artiges Rauschen (gefiltertes Noise)
	phase_wind += 0.01 * dt
	var wind: float = sin(phase_wind * TAU * 3.7) * sin(phase_wind * TAU * 7.3)
	wind *= 0.08 * (sin(time * 0.3) * 0.5 + 0.5)

	# Gelegentliches "Knarzen" (hoher Ton der schnell abklingt)
	var creak: float = 0.0
	if random_decay < 2.0:
		random_decay += dt
		var envelope: float = exp(-random_decay * 3.0)
		phase_creak += random_pitch * dt
		creak = sin(phase_creak * TAU) * random_volume * envelope
		# Pitch gleitet nach unten für gruseligen Effekt
		random_pitch *= (1.0 - dt * 0.5)

	# Alles zusammenmischen
	var sample: float = drone1 * 0.12 + drone2 * 0.08 + drone3 * 0.06 + wind + creak

	# Soft-Clipping
	sample = tanh(sample * 2.0) * 0.5

	return sample

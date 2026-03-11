extends StaticBody3D

# Lagerfeuer-Einstellungen
@export var safe_radius: float = 8.0
@export var light_range: float = 12.0

# Referenzen
@onready var light: OmniLight3D = $OmniLight3D
@onready var safe_zone: Area3D = $SafeZone
@onready var particles: GPUParticles3D = $GPUParticles3D

# Flacker-Effekt
var base_light_energy: float = 2.0
var flicker_timer: float = 0.0


func _ready() -> void:
	safe_zone.body_entered.connect(_on_body_entered)
	safe_zone.body_exited.connect(_on_body_exited)

	if light:
		light.omni_range = light_range
		light.light_energy = base_light_energy
		light.light_color = Color(1.0, 0.7, 0.3)


func _process(delta: float) -> void:
	# Flacker-Effekt für das Licht
	flicker_timer += delta * 8.0
	if light:
		light.light_energy = base_light_energy + sin(flicker_timer) * 0.3 + sin(flicker_timer * 2.3) * 0.15


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("_on_safe_zone_entered"):
		body._on_safe_zone_entered()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("_on_safe_zone_exited"):
		body._on_safe_zone_exited()

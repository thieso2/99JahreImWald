extends StaticBody3D

# Baum-Einstellungen
@export var wood_amount: int = 2
@export var respawn_time: float = 30.0

# Zustand
var is_harvested: bool = false
var respawn_timer: float = 0.0

# Referenzen
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D
@onready var interact_area: Area3D = $InteractArea


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	# Interaktionsbereich für Touch
	interact_area.input_event.connect(_on_input_event)


func _process(delta: float) -> void:
	if is_harvested:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()


func harvest(player: CharacterBody3D) -> void:
	if is_harvested:
		return

	is_harvested = true
	respawn_timer = respawn_time

	# Holz dem Spieler geben
	if player.has_method("add_wood"):
		player.add_wood(wood_amount)

	# Baum verstecken
	mesh.visible = false
	collision.disabled = true


func _respawn() -> void:
	is_harvested = false
	mesh.visible = true
	collision.disabled = false


func _on_body_entered(body: Node3D) -> void:
	pass  # Wird für Touch-Interaktion nicht gebraucht


func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventScreenTouch and event.pressed:
		# Nächsten Spieler finden
		var players := get_tree().get_nodes_in_group("player")
		for p in players:
			if p is CharacterBody3D:
				var distance: float = global_position.distance_to(p.global_position)
				if distance < 4.0:
					harvest(p)
					break

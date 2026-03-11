extends StaticBody3D

# Baum-Einstellungen
@export var wood_amount: int = 2
@export var respawn_time: float = 30.0

# Zustand
var is_harvested: bool = false
var respawn_timer: float = 0.0

# Referenzen (werden dynamisch gesucht)
var trunk_mesh: MeshInstance3D = null
var leaves_mesh: MeshInstance3D = null
var collision: CollisionShape3D = null


func _ready() -> void:
	# Nodes dynamisch finden statt @onready (funktioniert auch bei prozeduraler Erzeugung)
	for child in get_children():
		if child is MeshInstance3D and child.name == "MeshInstance3D":
			trunk_mesh = child
		elif child is MeshInstance3D and child.name == "Leaves":
			leaves_mesh = child
		elif child is CollisionShape3D:
			collision = child


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
	if trunk_mesh:
		trunk_mesh.visible = false
	if leaves_mesh:
		leaves_mesh.visible = false
	if collision:
		collision.disabled = true


func _respawn() -> void:
	is_harvested = false
	if trunk_mesh:
		trunk_mesh.visible = true
	if leaves_mesh:
		leaves_mesh.visible = true
	if collision:
		collision.disabled = false

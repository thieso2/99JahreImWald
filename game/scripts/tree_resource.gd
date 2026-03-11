extends StaticBody3D

# Baum mit HP-System: Größere Bäume brauchen mehr Hiebe
# tree_scale_factor wird vom ForestGenerator gesetzt vor add_child()

@export var wood_amount: int = 2
@export var respawn_time: float = 30.0

# Zustand
var is_harvested: bool = false
var respawn_timer: float = 0.0
var tree_hp: float = 3.0
var tree_max_hp: float = 3.0
var tree_scale_factor: float = 1.0  # Gesetzt vom ForestGenerator

# Shake-Effekt beim Hacken
var shake_offset: float = 0.0
var shake_decay: float = 0.0

# Referenzen (werden dynamisch gesucht)
var trunk_mesh: MeshInstance3D = null
var leaves_mesh: MeshInstance3D = null
var collision: CollisionShape3D = null

# Signale
signal tree_felled(wood: int)


func _ready() -> void:
	# Nodes dynamisch finden
	for child in get_children():
		if child is MeshInstance3D and child.name == "MeshInstance3D":
			trunk_mesh = child
		elif child is MeshInstance3D and child.name == "Leaves":
			leaves_mesh = child
		elif child is CollisionShape3D:
			collision = child

	# HP basierend auf Baumgröße berechnen
	if tree_scale_factor < 0.9:
		tree_hp = 2.0    # Klein: 2 Hiebe mit Steinaxt
		wood_amount = 1
	elif tree_scale_factor < 1.1:
		tree_hp = 4.0    # Mittel: 4 Hiebe mit Steinaxt
		wood_amount = 2
	else:
		tree_hp = 8.0    # Groß: 8 Hiebe mit Steinaxt, 2 mit Stahlaxt
		wood_amount = 4
	tree_max_hp = tree_hp


func _process(delta: float) -> void:
	# Respawn-Timer
	if is_harvested:
		respawn_timer -= delta
		if respawn_timer <= 0:
			_respawn()

	# Shake-Effekt abklingen lassen
	if shake_decay > 0:
		shake_decay -= delta * 6.0
		if shake_decay <= 0:
			shake_decay = 0.0
			shake_offset = 0.0
		else:
			shake_offset = sin(shake_decay * 30.0) * shake_decay * 0.15
		if trunk_mesh:
			trunk_mesh.position.x = shake_offset
		if leaves_mesh:
			leaves_mesh.position.x = shake_offset


func chop(axe_strength: float) -> bool:
	if is_harvested:
		return false

	tree_hp -= axe_strength

	if tree_hp <= 0:
		_fell_tree()
		return true
	else:
		_shake_tree()
		return false


func harvest(player: CharacterBody3D) -> void:
	# Alte Methode: sofortiges Ernten (Rückwärtskompatibilität)
	if is_harvested:
		return
	if player.has_method("add_wood"):
		player.add_wood(wood_amount)
	_fell_tree()


func _fell_tree() -> void:
	is_harvested = true
	respawn_timer = respawn_time
	tree_felled.emit(wood_amount)

	if trunk_mesh:
		trunk_mesh.visible = false
		trunk_mesh.position.x = 0
	if leaves_mesh:
		leaves_mesh.visible = false
		leaves_mesh.position.x = 0
	if collision:
		collision.disabled = true
	shake_offset = 0.0
	shake_decay = 0.0


func _shake_tree() -> void:
	shake_decay = 1.0


func _respawn() -> void:
	is_harvested = false
	tree_hp = tree_max_hp
	if trunk_mesh:
		trunk_mesh.visible = true
	if leaves_mesh:
		leaves_mesh.visible = true
	if collision:
		collision.disabled = false

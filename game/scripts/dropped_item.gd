extends Area3D

# Gedropptes Item – sieht aus wie der echte Gegenstand auf dem Boden
# Fliegt durch die Luft, landet am Boden, muss mit E-Taste eingesammelt werden

enum ItemType { NONE = -1, LOG = 0, SAPLING = 1 }

var item_type: int = ItemType.NONE
var item_string: String = ""  # Alternativ: String-basierter Typ

# Physik-Simulation
var fly_velocity: Vector3 = Vector3.ZERO
var on_ground: bool = false
var lifetime: float = 0.0
var bob_offset: float = 0.0
var can_pickup: bool = false  # Erst nach Landung einsammelbar

# Materialien
var sack_mat: StandardMaterial3D
var tie_mat: StandardMaterial3D
var icon_mat: StandardMaterial3D

# Ruhehöhe: Waldboden (0) oder Unterwelt-Boden (-100)
var rest_height: float = 0.25


func _ready() -> void:
	if position.y < -50.0:
		rest_height = -99.75  # Unterwelt-Boden liegt bei y=-100

	# Kollision für Nähe-Erkennung
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 2.0  # Erkennungsradius
	col.shape = shape
	col.position.y = 0.3
	add_child(col)

	_build_item_mesh()

	# Zufällige Flugrichtung
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	fly_velocity = Vector3(
		rng.randf_range(-2.5, 2.5),
		rng.randf_range(3.0, 5.0),
		rng.randf_range(-2.5, 2.5)
	)
	bob_offset = rng.randf() * TAU


func _process(delta: float) -> void:
	lifetime += delta

	if not on_ground:
		fly_velocity.y -= 12.0 * delta
		position += fly_velocity * delta
		# Rotation beim Fliegen
		rotation.x += delta * 3.0
		if position.y <= rest_height:
			position.y = rest_height
			on_ground = true
			can_pickup = true
			fly_velocity = Vector3.ZERO
			rotation.x = 0.0
	else:
		# Leichtes Schweben am Boden
		position.y = rest_height + sin(lifetime * 2.0 + bob_offset) * 0.06
		rotation.y += delta * 0.8

	# Nach 90 Sekunden verschwinden
	if lifetime > 90.0:
		queue_free()


func try_pickup(body: Node3D) -> bool:
	# Wird vom GameManager aufgerufen wenn E gedrückt wird
	if not can_pickup:
		return false
	if not on_ground:
		return false

	var dist: float = body.global_position.distance_to(global_position)
	if dist > 2.5:
		return false

	if item_string != "":
		# String-basiertes Item ins Inventar
		if body.has_method("add_wood"):  # Hat Inventar-System
			match item_string:
				"torch":
					body.has_torch = true
					body.inventory.append("torch")
					body.inventory_changed.emit()
				_:
					body.inventory.append(item_string)
					body.inventory_changed.emit()
	else:
		match item_type:
			ItemType.LOG:
				if body.has_method("add_wood"):
					body.add_wood(1)
			ItemType.SAPLING:
				if body.has_method("add_sapling"):
					body.add_sapling(1)

	queue_free()
	return true


func _build_item_mesh() -> void:
	# Zuerst String-basierte Items prüfen
	if item_string != "":
		match item_string:
			"wood": _build_log()
			"sapling": _build_sapling()
			"torch": _build_torch()
			"bed": _build_bed()
			"fence": _build_fence()
			"wall": _build_wall_item()
			"chest": _build_chest()
			"meat_small": _build_meat_small()
			"meat_chunk": _build_meat_chunk()
			"steak": _build_steak()
			"rabbit_foot": _build_rabbit_foot()
			"wolf_pelt": _build_wolf_pelt()
			"cultist_gem": _build_cultist_gem()
			_: _build_log()
		return

	# Dann enum-basierte Items (von Bäumen gedroppt)
	match item_type:
		ItemType.LOG:
			_build_log()
		ItemType.SAPLING:
			_build_sapling()
		_:
			_build_log()


func _build_log() -> void:
	# HOLZSCHEIT: Dicker brauner Stamm, liegend, mit Jahresringen
	var bark := StandardMaterial3D.new()
	bark.albedo_color = Color(0.45, 0.28, 0.14, 1)
	var rings := StandardMaterial3D.new()
	rings.albedo_color = Color(0.75, 0.55, 0.3, 1)

	# Dicker Stamm liegend
	var log := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.15
	lm.bottom_radius = 0.18
	lm.height = 0.7
	log.mesh = lm
	log.material_override = bark
	log.rotation.z = PI / 2.0
	log.position.y = 0.18
	add_child(log)

	# Jahresringe an beiden Enden
	for side in [-1, 1]:
		var ring := MeshInstance3D.new()
		var rm := CylinderMesh.new()
		rm.top_radius = 0.13
		rm.bottom_radius = 0.13
		rm.height = 0.02
		ring.mesh = rm
		ring.material_override = rings
		ring.rotation.z = PI / 2.0
		ring.position = Vector3(side * 0.35, 0.18, 0)
		add_child(ring)

	# Kleiner Ast
	var twig := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.01
	tm.bottom_radius = 0.02
	tm.height = 0.15
	twig.mesh = tm
	twig.material_override = bark
	twig.position = Vector3(0.1, 0.32, 0)
	twig.rotation.z = 0.5
	add_child(twig)


func _build_sapling() -> void:
	# SETZLING: Terrakotta-Topf mit grünem Sprössling und 2 Blättern
	var pot_mat := StandardMaterial3D.new()
	pot_mat.albedo_color = Color(0.7, 0.4, 0.2, 1)  # Terrakotta
	var earth_mat := StandardMaterial3D.new()
	earth_mat.albedo_color = Color(0.3, 0.2, 0.12, 1)
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.1, 1)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.15, 0.7, 0.1, 1)  # Leuchtend grün

	# Topf
	var pot := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.15
	pm.bottom_radius = 0.1
	pm.height = 0.15
	pot.mesh = pm
	pot.material_override = pot_mat
	pot.position.y = 0.08
	add_child(pot)

	# Erde im Topf
	var earth := MeshInstance3D.new()
	var em := CylinderMesh.new()
	em.top_radius = 0.13
	em.bottom_radius = 0.13
	em.height = 0.03
	earth.mesh = em
	earth.material_override = earth_mat
	earth.position.y = 0.16
	add_child(earth)

	# Stiel
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.015
	sm.bottom_radius = 0.025
	sm.height = 0.25
	stem.mesh = sm
	stem.material_override = stem_mat
	stem.position.y = 0.3
	add_child(stem)

	# 2 Blätter (seitlich)
	for side in [-1, 1]:
		var leaf := MeshInstance3D.new()
		var lfm := BoxMesh.new()
		lfm.size = Vector3(0.12, 0.02, 0.08)
		leaf.mesh = lfm
		leaf.material_override = leaf_mat
		leaf.position = Vector3(side * 0.06, 0.4, 0)
		leaf.rotation.z = side * 0.4
		add_child(leaf)


func _build_torch() -> void:
	# FACKEL: Langer Stock mit orangem Feuer-Tuch oben, leuchtend
	var stick_mat := StandardMaterial3D.new()
	stick_mat.albedo_color = Color(0.45, 0.28, 0.14, 1)
	var wrap_mat := StandardMaterial3D.new()
	wrap_mat.albedo_color = Color(0.2, 0.15, 0.1, 1)
	var flame_mat := StandardMaterial3D.new()
	flame_mat.albedo_color = Color(1.0, 0.6, 0.1, 1)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.4, 0.0, 1)
	flame_mat.emission_energy_multiplier = 0.5

	# Stock (schräg liegend)
	var stick := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.025
	sm.bottom_radius = 0.035
	sm.height = 0.7
	stick.mesh = sm
	stick.material_override = stick_mat
	stick.rotation.z = PI / 3.0
	stick.position = Vector3(-0.1, 0.2, 0)
	add_child(stick)

	# Wicklung oben
	var wrap := MeshInstance3D.new()
	var wm := CylinderMesh.new()
	wm.top_radius = 0.05
	wm.bottom_radius = 0.04
	wm.height = 0.12
	wrap.mesh = wm
	wrap.material_override = wrap_mat
	wrap.rotation.z = PI / 3.0
	wrap.position = Vector3(0.15, 0.48, 0)
	add_child(wrap)

	# Glühender Kopf
	var flame := MeshInstance3D.new()
	var fm := SphereMesh.new()
	fm.radius = 0.07
	fm.height = 0.1
	flame.mesh = fm
	flame.material_override = flame_mat
	flame.position = Vector3(0.2, 0.55, 0)
	add_child(flame)


func _build_bed() -> void:
	# BETT: Rotes Bett mit Holzrahmen, Kissen, Decke
	var frame_mat := StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.5, 0.3, 0.15, 1)
	var mattress_mat := StandardMaterial3D.new()
	mattress_mat.albedo_color = Color(0.8, 0.2, 0.15, 1)  # Leuchtend rot
	var pillow_mat := StandardMaterial3D.new()
	pillow_mat.albedo_color = Color(1.0, 1.0, 0.9, 1)  # Weiß
	var blanket_mat := StandardMaterial3D.new()
	blanket_mat.albedo_color = Color(0.6, 0.1, 0.1, 1)  # Dunkelrot

	# Holzrahmen
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.45, 0.08, 0.7)
	frame.mesh = fm
	frame.material_override = frame_mat
	frame.position.y = 0.08
	add_child(frame)

	# Beine
	for x in [-1, 1]:
		for z in [-1, 1]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.04, 0.06, 0.04)
			leg.mesh = lm
			leg.material_override = frame_mat
			leg.position = Vector3(x * 0.18, 0.03, z * 0.3)
			add_child(leg)

	# Matratze
	var matt := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.4, 0.06, 0.65)
	matt.mesh = mm
	matt.material_override = mattress_mat
	matt.position.y = 0.15
	add_child(matt)

	# Kissen
	var pillow := MeshInstance3D.new()
	var plm := BoxMesh.new()
	plm.size = Vector3(0.25, 0.05, 0.12)
	pillow.mesh = plm
	pillow.material_override = pillow_mat
	pillow.position = Vector3(0, 0.2, 0.25)
	add_child(pillow)

	# Decke (halb aufgedeckt)
	var blanket := MeshInstance3D.new()
	var blm := BoxMesh.new()
	blm.size = Vector3(0.38, 0.03, 0.35)
	blanket.mesh = blm
	blanket.material_override = blanket_mat
	blanket.position = Vector3(0, 0.19, -0.12)
	add_child(blanket)

	# Kopfteil
	var headboard := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.45, 0.2, 0.04)
	headboard.mesh = hm
	headboard.material_override = frame_mat
	headboard.position = Vector3(0, 0.2, 0.35)
	add_child(headboard)


func _build_fence() -> void:
	# ZAUN: Helle Holzpfosten mit spitzen Enden
	var light_wood := StandardMaterial3D.new()
	light_wood.albedo_color = Color(0.6, 0.45, 0.25, 1)  # Helles Holz
	var dark_wood := StandardMaterial3D.new()
	dark_wood.albedo_color = Color(0.4, 0.25, 0.12, 1)

	# 3 spitze Pfosten
	for i in range(3):
		var post := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.05, 0.5, 0.05)
		post.mesh = pm
		post.material_override = light_wood
		post.position = Vector3((i - 1) * 0.22, 0.25, 0)
		add_child(post)

		# Spitze
		var tip := MeshInstance3D.new()
		var tm := CylinderMesh.new()
		tm.top_radius = 0.001
		tm.bottom_radius = 0.035
		tm.height = 0.08
		tip.mesh = tm
		tip.material_override = dark_wood
		tip.position = Vector3((i - 1) * 0.22, 0.54, 0)
		add_child(tip)

	# 2 Querlatten
	for y_pos in [0.18, 0.38]:
		var rail := MeshInstance3D.new()
		var rm := BoxMesh.new()
		rm.size = Vector3(0.5, 0.04, 0.03)
		rail.mesh = rm
		rail.material_override = dark_wood
		rail.position.y = y_pos
		add_child(rail)


func _build_wall_item() -> void:
	# WAND: Große aufgestellte Holzplanken, gebündelt mit Seil
	var plank_mat := StandardMaterial3D.new()
	plank_mat.albedo_color = Color(0.55, 0.38, 0.2, 1)
	var rope_mat := StandardMaterial3D.new()
	rope_mat.albedo_color = Color(0.7, 0.6, 0.4, 1)  # Helles Seil

	# 5 stehende Planken
	for i in range(5):
		var plank := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.06, 0.55, 0.03)
		plank.mesh = pm
		plank.material_override = plank_mat
		plank.position = Vector3((i - 2) * 0.07, 0.28, 0)
		plank.rotation.z = randf_range(-0.05, 0.05)
		add_child(plank)

	# Seil drum
	var rope := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.4, 0.025, 0.06)
	rope.mesh = rm
	rope.material_override = rope_mat
	rope.position.y = 0.35
	add_child(rope)

	var rope2 := MeshInstance3D.new()
	rope2.mesh = rm
	rope2.material_override = rope_mat
	rope2.position.y = 0.15
	add_child(rope2)


func _build_meat_small() -> void:
	# FLEISCHSTÜCKCHEN: Kleiner rosa-roter Fleischbrocken
	var meat_mat := StandardMaterial3D.new()
	meat_mat.albedo_color = Color(0.85, 0.35, 0.3, 1)
	var fat_mat := StandardMaterial3D.new()
	fat_mat.albedo_color = Color(0.95, 0.85, 0.75, 1)

	var meat := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.12
	mm.height = 0.2
	meat.mesh = mm
	meat.material_override = meat_mat
	meat.position.y = 0.12
	meat.scale = Vector3(1.2, 0.8, 1.0)
	add_child(meat)

	# Fett-Streifen
	var fat := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.2, 0.03, 0.08)
	fat.mesh = fm
	fat.material_override = fat_mat
	fat.position = Vector3(0, 0.2, 0)
	fat.rotation.y = 0.4
	add_child(fat)


func _build_meat_chunk() -> void:
	# FLEISCHKLUMPEN: Großer dunkelroter Brocken mit Knochen
	var meat_mat := StandardMaterial3D.new()
	meat_mat.albedo_color = Color(0.65, 0.2, 0.15, 1)
	var bone_mat := StandardMaterial3D.new()
	bone_mat.albedo_color = Color(0.95, 0.92, 0.85, 1)

	var meat := MeshInstance3D.new()
	var mm := SphereMesh.new()
	mm.radius = 0.16
	mm.height = 0.28
	meat.mesh = mm
	meat.material_override = meat_mat
	meat.position.y = 0.15
	meat.scale = Vector3(1.3, 0.9, 1.1)
	add_child(meat)

	# Herausragender Knochen
	var bone := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.025
	bm.bottom_radius = 0.025
	bm.height = 0.25
	bone.mesh = bm
	bone.material_override = bone_mat
	bone.position = Vector3(0.15, 0.22, 0)
	bone.rotation.z = deg_to_rad(-60.0)
	add_child(bone)

	# Knochen-Ende (Kugel)
	var knob := MeshInstance3D.new()
	var km := SphereMesh.new()
	km.radius = 0.04
	km.height = 0.08
	knob.mesh = km
	knob.material_override = bone_mat
	knob.position = Vector3(0.26, 0.28, 0)
	add_child(knob)


func _build_steak() -> void:
	# STEAK: Flache braun-rote Scheibe mit Grillstreifen
	var steak_mat := StandardMaterial3D.new()
	steak_mat.albedo_color = Color(0.55, 0.25, 0.15, 1)
	var stripe_mat := StandardMaterial3D.new()
	stripe_mat.albedo_color = Color(0.3, 0.12, 0.08, 1)

	var steak := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.16
	sm.bottom_radius = 0.16
	sm.height = 0.06
	steak.mesh = sm
	steak.material_override = steak_mat
	steak.position.y = 0.1
	steak.scale = Vector3(1.2, 1.0, 0.9)
	add_child(steak)

	# Grillstreifen
	for i in range(2):
		var stripe := MeshInstance3D.new()
		var stm := BoxMesh.new()
		stm.size = Vector3(0.28, 0.01, 0.03)
		stripe.mesh = stm
		stripe.material_override = stripe_mat
		stripe.position = Vector3(0, 0.14, (i - 0.5) * 0.12)
		add_child(stripe)


func _build_rabbit_foot() -> void:
	# HASENFUSS: Kleiner grau-brauner Fuß mit hellem Fell
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.65, 0.55, 0.45, 1)
	var light_fur_mat := StandardMaterial3D.new()
	light_fur_mat.albedo_color = Color(0.85, 0.8, 0.75, 1)

	var foot := MeshInstance3D.new()
	var fm := CapsuleMesh.new()
	fm.radius = 0.05
	fm.height = 0.25
	foot.mesh = fm
	foot.material_override = fur_mat
	foot.position.y = 0.12
	foot.rotation.z = deg_to_rad(70.0)
	add_child(foot)

	# Helle Pfoten-Spitze
	var tip := MeshInstance3D.new()
	var tm := SphereMesh.new()
	tm.radius = 0.05
	tm.height = 0.1
	tip.mesh = tm
	tip.material_override = light_fur_mat
	tip.position = Vector3(0.12, 0.14, 0)
	add_child(tip)


func _build_cultist_gem() -> void:
	# KULTISTEN-EDELSTEIN: Leuchtender lila Kristall
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.7, 0.3, 0.9, 0.9)
	gem_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.6, 0.2, 0.8, 1)
	gem_mat.emission_energy_multiplier = 1.5
	gem_mat.metallic = 0.4
	gem_mat.roughness = 0.1

	# Kristall: zwei Pyramiden (oben + unten gespiegelt)
	var top := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.001
	tm.bottom_radius = 0.12
	tm.height = 0.2
	tm.radial_segments = 6
	top.mesh = tm
	top.material_override = gem_mat
	top.position.y = 0.3
	add_child(top)

	var bottom := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 0.12
	bm.bottom_radius = 0.001
	bm.height = 0.15
	bm.radial_segments = 6
	bottom.mesh = bm
	bottom.material_override = gem_mat
	bottom.position.y = 0.125
	add_child(bottom)


func _build_wolf_pelt() -> void:
	# WOLFSPELZ: Graue Fell-Matte, leicht gewellt
	var fur_mat := StandardMaterial3D.new()
	fur_mat.albedo_color = Color(0.35, 0.35, 0.38, 1)
	var dark_fur_mat := StandardMaterial3D.new()
	dark_fur_mat.albedo_color = Color(0.22, 0.22, 0.25, 1)

	# Fell-Matte
	var pelt := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.4, 0.04, 0.5)
	pelt.mesh = pm
	pelt.material_override = fur_mat
	pelt.position.y = 0.06
	add_child(pelt)

	# Dunkler Rücken-Streifen
	var stripe := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.15, 0.05, 0.5)
	stripe.mesh = sm
	stripe.material_override = dark_fur_mat
	stripe.position.y = 0.07
	add_child(stripe)

	# Schwanz-Ende
	var tail_end := MeshInstance3D.new()
	var tem := CapsuleMesh.new()
	tem.radius = 0.04
	tem.height = 0.2
	tail_end.mesh = tem
	tail_end.material_override = dark_fur_mat
	tail_end.position = Vector3(0, 0.06, -0.3)
	tail_end.rotation.x = deg_to_rad(90.0)
	add_child(tail_end)


func _build_chest() -> void:
	# TRUHE: Dunkelbraune Kiste mit goldenem Schloss und Metallbändern
	var dark_wood := StandardMaterial3D.new()
	dark_wood.albedo_color = Color(0.35, 0.2, 0.1, 1)
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.85, 0.7, 0.2, 1)  # Gold
	gold_mat.metallic = 0.8
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.3, 0.3, 0.28, 1)
	band_mat.metallic = 0.5

	# Kisten-Körper
	var body_m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.35, 0.22, 0.25)
	body_m.mesh = bm
	body_m.material_override = dark_wood
	body_m.position.y = 0.11
	add_child(body_m)

	# Gewölbter Deckel
	var lid := MeshInstance3D.new()
	var lm := BoxMesh.new()
	lm.size = Vector3(0.37, 0.06, 0.27)
	lid.mesh = lm
	lid.material_override = dark_wood
	lid.position.y = 0.25
	add_child(lid)

	# Goldenes Schloss vorne
	var lock := MeshInstance3D.new()
	var lockm := BoxMesh.new()
	lockm.size = Vector3(0.06, 0.08, 0.03)
	lock.mesh = lockm
	lock.material_override = gold_mat
	lock.position = Vector3(0, 0.18, 0.14)
	add_child(lock)

	# Metallbänder
	for x_pos in [-0.14, 0.14]:
		var band := MeshInstance3D.new()
		var bandm := BoxMesh.new()
		bandm.size = Vector3(0.03, 0.28, 0.27)
		band.mesh = bandm
		band.material_override = band_mat
		band.position = Vector3(x_pos, 0.14, 0)
		add_child(band)

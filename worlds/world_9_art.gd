extends RefCounted
## World 9, Ember Forge: models and decoration (lava vents, hot coal beds,
## anvils, chimneys, little volcanoes, the Magma Slug critter and
## Cinderclank the forge golem). Static helpers only; world_9.gd preloads
## this script by path.

const IRON := Color("#4A4250")
const IRON_LIGHT := Color("#6E6478")
const BASALT := Color("#5A464C")
const BRICK := Color("#C46A4E")
const BRICK_DARK := Color("#9E4E3A")
const LAVA := Color("#FF7A2E")
const LAVA_HOT := Color("#FFC24A")
const COAL := Color("#3A3036")
const CRUST := Color("#6B3E3A")
const GOLD := Color("#FFC64A")
const SMOKE := Color("#E9DCD6")
const SLUG_SKIN := Color("#B4473C")
const SLUG_TOP := Color("#D2654A")


## A glowing, emissive material (unshaded so it reads as hot). Not shared.
static func hot_mat(color: Color, energy: float = 1.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## A lava vent set in the floor: an iron ring round a dark hole. "Glow" is
## the hot disc inside (scaled up while it warns), "Column" the fire that
## shoots up (scaled from zero) and "Ring" the iron rim.
static func vent(flame_mesh: Mesh) -> Node3D:
	var root := Node3D.new()
	var ring := Models.part(root, Models.cylinder(0.42, 0.45, 0.08, 8), IRON, Vector3(0, 0.02, 0))
	ring.name = "Ring"
	ring.rotation.y = PI / 8.0
	Models.part(root, Models.cylinder(0.3, 0.3, 0.085, 8), COAL, Vector3(0, 0.025, 0)).rotation.y = PI / 8.0
	for k in 4:
		var a: float = TAU * k / 4.0 + PI * 0.25
		Models.part(root, Models.box_mesh(Vector3(0.08, 0.05, 0.08), 0.015), IRON_LIGHT, Vector3(cos(a) * 0.36, 0.07, sin(a) * 0.36))
	var glow := MeshInstance3D.new()
	glow.name = "Glow"
	glow.mesh = Models.cylinder(0.26, 0.26, 0.02, 8)
	glow.material_override = hot_mat(LAVA, 1.4)
	glow.position.y = 0.07
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(glow)
	var col := Node3D.new()
	col.name = "Column"
	col.scale = Vector3.ONE * 0.001
	root.add_child(col)
	for k in 5:
		var cube := Models.part(col, flame_mesh, LAVA if k % 2 == 0 else LAVA_HOT, Vector3(0, 0.24 + k * 0.27, 0), 1.6 if k % 2 == 0 else 2.0)
		cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cube.scale = Vector3.ONE * (1.4 - k * 0.18)
		cube.rotation = Vector3(0.6 * k, 0.9 * k, 0.3 * k)
	return root


## Magma Slug: a low, crusty slug with glowing cracks, eye stalks and a
## glowing belly. "Body/Shell" squashes as it inches along.
static func slug() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Node3D.new()
	shell.name = "Shell"
	body.add_child(shell)
	Models.part(shell, Models.box_mesh(Vector3(0.52, 0.12, 0.74), 0.06), LAVA, Vector3(0, 0.07, 0), 1.2)
	Models.part(shell, Models.box_mesh(Vector3(0.5, 0.28, 0.66), 0.13), SLUG_SKIN, Vector3(0, 0.22, -0.02))
	Models.part(shell, Models.box_mesh(Vector3(0.38, 0.22, 0.42), 0.1), SLUG_TOP, Vector3(0, 0.38, -0.08))
	# Glowing cracks on the back.
	for spot: Vector3 in [Vector3(-0.12, 0.37, 0.05), Vector3(0.1, 0.4, -0.12), Vector3(0.18, 0.3, 0.12), Vector3(-0.2, 0.3, -0.2), Vector3(0.0, 0.5, -0.06)]:
		var c := Models.part(shell, Models.box_mesh(Vector3(0.1, 0.03, 0.05), 0.012), LAVA_HOT, spot, 1.6)
		c.rotation.y = spot.x * 6.0
		c.rotation.z = spot.z * 2.0
	# Face on the front.
	var face := Node3D.new()
	face.position = Vector3(0, 0.26, 0.31)
	shell.add_child(face)
	for side: int in [-1, 1]:
		var stalk := Models.part(face, Models.cylinder(0.025, 0.035, 0.22, 6), SLUG_TOP, Vector3(side * 0.1, 0.12, -0.02))
		stalk.rotation.z = side * -0.25
		var eye := Node3D.new()
		eye.position = Vector3(side * 0.13, 0.25, 0.0)
		face.add_child(eye)
		Models.part(eye, Models.sphere(0.06, -1, 12), Models.WHITE, Vector3.ZERO)
		Models.part(eye, Models.sphere(0.034, -1, 10), Models.INK, Vector3(0, -0.005, 0.04))
		Models.part(eye, Models.sphere(0.012, -1, 6), Models.WHITE, Vector3(0.012, 0.012, 0.065), 1.0)
		var cheek := Models.part(face, Models.sphere(0.04, -1, 8), Color("#FF9AA8"), Vector3(side * 0.15, -0.04, 0.05))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	Models.part(face, Models.box_mesh(Vector3(0.09, 0.03, 0.03), 0.01), Models.INK, Vector3(0, -0.03, 0.06))
	return root


## Cinderclank, the boss: a chunky iron-and-brick forge golem with a
## glowing furnace belly, a little chimney on his head and a big hammer.
## "Rig/ArmR" holds the hammer; "Rig/Furnace" glows.
static func golem() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.5)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var rig := Node3D.new()
	rig.name = "Rig"
	rig.scale = Vector3.ONE * 1.4
	rig.position.y = 0.1
	rig.rotation.x = -0.45
	body.add_child(rig)
	Models.part(rig, Models.box_mesh(Vector3(1.1, 0.9, 0.86), 0.2), IRON, Vector3(0, 0.62, 0))
	Models.part(rig, Models.box_mesh(Vector3(0.96, 0.08, 0.74), 0.04), IRON_LIGHT, Vector3(0, 1.08, 0))
	Models.part(rig, Models.box_mesh(Vector3(1.16, 0.14, 0.92), 0.06), BRICK, Vector3(0, 0.32, 0))
	Models.part(rig, Models.box_mesh(Vector3(1.0, 0.16, 0.8), 0.06), IRON_LIGHT, Vector3(0, 0.2, 0))
	# Furnace belly: a brick arch with a glowing mouth.
	var furnace := Node3D.new()
	furnace.name = "Furnace"
	furnace.position = Vector3(0, 0.46, 0.43)
	rig.add_child(furnace)
	Models.part(furnace, Models.box_mesh(Vector3(0.56, 0.36, 0.08), 0.06), BRICK_DARK, Vector3.ZERO)
	var fire := MeshInstance3D.new()
	fire.name = "Fire"
	fire.mesh = Models.box_mesh(Vector3(0.38, 0.2, 0.06), 0.05)
	fire.material_override = hot_mat(LAVA, 1.8)
	fire.position = Vector3(0, -0.02, 0.03)
	furnace.add_child(fire)
	for k in 3:
		Models.part(furnace, Models.box_mesh(Vector3(0.03, 0.2, 0.03), 0.01), IRON, Vector3(-0.1 + k * 0.1, -0.02, 0.07))
	# Face, tilted up to the camera.
	var face := Node3D.new()
	face.position = Vector3(0, 0.86, 0.44)
	rig.add_child(face)
	Models.part(face, Models.box_mesh(Vector3(0.8, 0.36, 0.06), 0.06), IRON_LIGHT, Vector3(0, 0, -0.01))
	Models._eyes(face, 0.02, 0.04, 0.2, 0.13, true)
	for side: int in [-1, 1]:
		var cheek := Models.part(face, Models.sphere(0.055, -1, 8), Color("#FF8E7A"), Vector3(side * 0.3, -0.08, 0.05))
		cheek.scale = Vector3(1.0, 0.55, 0.4)
		var foot := Models.part(rig, Models.box_mesh(Vector3(0.36, 0.18, 0.46), 0.07), BASALT, Vector3(side * 0.3, 0.09, 0.12))
		foot.name = "FootL" if side < 0 else "FootR"
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.64, 0.86, 0.05)
		rig.add_child(arm)
		Models.part(arm, Models.box_mesh(Vector3(0.28, 0.5, 0.3), 0.1), IRON_LIGHT, Vector3(side * 0.04, -0.22, 0))
		Models.part(arm, Models.box_mesh(Vector3(0.3, 0.2, 0.32), 0.08), BRICK, Vector3(side * 0.05, -0.52, 0.02))
		Models.part(arm, Models.box_mesh(Vector3(0.32, 0.12, 0.34), 0.05), BRICK_DARK, Vector3(side * 0.03, 0.04, 0))
		if side > 0:
			# The hammer: a handle and a chunky head with a gold band.
			var hammer := Node3D.new()
			hammer.position = Vector3(0.06, -0.55, 0.12)
			arm.add_child(hammer)
			Models.part(hammer, Models.box_mesh(Vector3(0.07, 0.07, 0.6), 0.025), Color("#8B5E3C"), Vector3(0, 0, 0.22))
			Models.part(hammer, Models.box_mesh(Vector3(0.34, 0.24, 0.24), 0.06), IRON, Vector3(0, 0, 0.52))
			Models.part(hammer, Models.box_mesh(Vector3(0.36, 0.08, 0.26), 0.03), GOLD, Vector3(0, 0, 0.52))
	# Chimney hat with a glowing top.
	Models.part(rig, Models.box_mesh(Vector3(0.24, 0.32, 0.24), 0.05), BRICK, Vector3(0.22, 1.33, -0.1))
	Models.part(rig, Models.box_mesh(Vector3(0.3, 0.07, 0.3), 0.025), BRICK_DARK, Vector3(0.22, 1.5, -0.1))
	var ember := MeshInstance3D.new()
	ember.mesh = Models.box_mesh(Vector3(0.16, 0.03, 0.16), 0.01)
	ember.material_override = hot_mat(LAVA_HOT, 1.6)
	ember.position = Vector3(0.22, 1.54, -0.1)
	rig.add_child(ember)
	return root


## A brick chimney stack; "Puff" sits on the top for smoke.
static func chimney(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	var h: float = r.randf_range(0.9, 1.3)
	Models.part(root, Models.box_mesh(Vector3(0.36, h, 0.36), 0.05), BRICK, Vector3(0, h * 0.5, 0))
	Models.part(root, Models.box_mesh(Vector3(0.44, 0.09, 0.44), 0.03), BRICK_DARK, Vector3(0, h, 0))
	for k in 3:
		Models.part(root, Models.box_mesh(Vector3(0.37, 0.025, 0.37), 0.01), BRICK_DARK, Vector3(0, 0.2 + k * h * 0.28, 0))
	var top := MeshInstance3D.new()
	top.mesh = Models.box_mesh(Vector3(0.26, 0.02, 0.26), 0.01)
	top.material_override = hot_mat(LAVA, 1.2)
	top.position.y = h + 0.05
	root.add_child(top)
	var puff := Node3D.new()
	puff.name = "Puff"
	puff.position.y = h + 0.1
	root.add_child(puff)
	return root


## A little volcano: a stepped cone with a glowing crater.
static func volcano(size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.part(root, Models.cylinder(0.75, 1.0, 0.4, 8), BASALT, Vector3(0, 0.2, 0))
	Models.part(root, Models.cylinder(0.5, 0.75, 0.42, 8), BASALT.lightened(0.08), Vector3(0, 0.61, 0))
	Models.part(root, Models.cylinder(0.32, 0.5, 0.36, 8), BASALT.lightened(0.14), Vector3(0, 0.99, 0))
	var lava := MeshInstance3D.new()
	lava.mesh = Models.cylinder(0.26, 0.26, 0.04, 8)
	lava.material_override = hot_mat(LAVA, 1.5)
	lava.position.y = 1.17
	root.add_child(lava)
	for k in 3:
		var a: float = TAU * k / 3.0 + 0.4
		var drip := MeshInstance3D.new()
		drip.mesh = Models.box_mesh(Vector3(0.1, 0.5, 0.05), 0.02)
		drip.material_override = hot_mat(LAVA, 1.1)
		drip.position = Vector3(cos(a) * 0.5, 0.85, sin(a) * 0.5)
		drip.rotation = Vector3(0, -a + PI * 0.5, 0)
		drip.rotate_object_local(Vector3.RIGHT, 0.55)
		root.add_child(drip)
	var puff := Node3D.new()
	puff.name = "Puff"
	puff.position.y = 1.25
	root.add_child(puff)
	return root


## A coal cart on little wheels.
static func cart(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.5, 0.26, 0.36), 0.05), IRON_LIGHT, Vector3(0, 0.23, 0))
	for k in 5:
		Models.part(root, Models.box_mesh(Vector3(0.12, 0.1, 0.12), 0.03), COAL, Vector3(r.randf_range(-0.15, 0.15), 0.38, r.randf_range(-0.1, 0.1))).rotation.y = r.randf() * TAU
	for sx: int in [-1, 1]:
		for sz: int in [-1, 1]:
			var w := Models.part(root, Models.cylinder(0.07, 0.07, 0.04, 8), IRON, Vector3(sx * 0.17, 0.07, sz * 0.19))
			w.rotation.x = PI * 0.5
	root.rotation.y = r.randf() * TAU
	return root


## A small stack of gold ingots.
static func ingots(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var bar := Models.box_mesh(Vector3(0.2, 0.07, 0.1), 0.02)
	for k in 3:
		Models.part(root, bar, GOLD, Vector3(-0.06 + k * 0.06 if k < 2 else 0.0, 0.035 + (0.07 if k == 2 else 0.0), 0.0), 0.15).rotation.y = 0.1 * k
	root.rotation.y = r.randf() * TAU
	return root


## A low pool of lava in a stone rim.
static func lava_pool(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s: float = r.randf_range(0.5, 0.7)
	Models.part(root, Models.box_mesh(Vector3(s, 0.08, s * 0.8), 0.04), BASALT, Vector3(0, 0.04, 0))
	var lava := MeshInstance3D.new()
	lava.mesh = Models.box_mesh(Vector3(s * 0.75, 0.02, s * 0.58), 0.01)
	lava.material_override = hot_mat(LAVA, 1.3)
	lava.position.y = 0.085
	root.add_child(lava)
	root.rotation.y = r.randf() * TAU
	return root


## A rack with a hammer and tongs.
static func tool_rack(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for sx: int in [-1, 1]:
		Models.part(root, Models.box_mesh(Vector3(0.06, 0.56, 0.06), 0.02), Color("#8B5E3C"), Vector3(sx * 0.25, 0.28, 0))
	Models.part(root, Models.box_mesh(Vector3(0.6, 0.06, 0.07), 0.02), Color("#8B5E3C"), Vector3(0, 0.52, 0))
	Models.part(root, Models.box_mesh(Vector3(0.04, 0.32, 0.04), 0.01), Color("#A87A52"), Vector3(-0.1, 0.33, 0.06))
	Models.part(root, Models.box_mesh(Vector3(0.14, 0.08, 0.08), 0.02), IRON, Vector3(-0.1, 0.17, 0.06))
	Models.part(root, Models.box_mesh(Vector3(0.03, 0.34, 0.03), 0.01), IRON_LIGHT, Vector3(0.08, 0.33, 0.06)).rotation.z = 0.1
	Models.part(root, Models.box_mesh(Vector3(0.03, 0.34, 0.03), 0.01), IRON_LIGHT, Vector3(0.13, 0.33, 0.06)).rotation.z = -0.1
	root.rotation.y = r.randf_range(-0.4, 0.4)
	return root

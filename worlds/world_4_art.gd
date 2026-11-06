extends RefCounted
## World 4, Frost Peaks: the models and decoration (snowy pines, snowmen,
## ice spires, the Snowpuff critter and Big Brrr the yeti). Static helpers
## only; world_4.gd preloads this script by path.

const SNOW := Color("#F7FBFF")
const SNOW_SHADE := Color("#DCE8F6")
const ICE := Color("#9FE2FA")
const ICE_DEEP := Color("#6CC4EE")
const PINE_A := Color("#3E8C86")
const PINE_B := Color("#2F7472")
const CARROT := Color("#FF9440")
const SCARF := Color("#F2727F")
const PUFF := Color("#A9C7F5")
const COAL := Color("#3A3858")


static func ice_glass(color: Color = ICE, tint: float = 0.38, glow: float = 0.12) -> Material:
	return Models.glass(color, tint, glow) if Models.GLASS else Models.mat(color, glow)


## A crystal: a hexagonal prism with a pointed tip, standing on y = 0.
static func crystal(parent: Node3D, r: float, h: float, at: Vector3, tilt: Vector3, color: Color = ICE) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.rotation = tilt
	parent.add_child(n)
	var body := Models.part(n, Models.cylinder(r, r, h, 6), color, Vector3(0, h * 0.5, 0))
	body.material_override = ice_glass(color)
	var tip := Models.part(n, Models.cylinder(0.0, r, r * 1.6, 6), color, Vector3(0, h + r * 0.8, 0))
	tip.material_override = ice_glass(color.lightened(0.25))
	return n


## A snow-dusted pine: faceted green tiers, each with a snowy top.
static func pine(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0 * size, 0.28)
	Models.part(root, Models.cylinder(0.06 * size, 0.08 * size, 0.3 * size, 8), Models.TRUNK, Vector3(0, 0.15 * size, 0))
	var green: Color = PINE_A.lerp(PINE_B, r.randf())
	for k in 3:
		var w: float = (0.42 - k * 0.1) * size
		var y: float = (0.38 + k * 0.27) * size
		var tier := Models.part(root, Models.cylinder(0.0, w, 0.44 * size, 8), green, Vector3(0, y, 0))
		tier.rotation.y = k * 0.4
		var cap := Models.part(root, Models.cylinder(0.0, w * 0.62, 0.27 * size, 8), SNOW, Vector3(0, y + 0.085 * size, 0))
		cap.rotation.y = k * 0.4
	return root


## A snowman with a carrot nose, coal eyes, a scarf and a little hat.
static func snowman(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.blob_shadow(root, 0.9, 0.3)
	Models.part(root, Models.sphere(0.26, 0.48, 16), SNOW, Vector3(0, 0.22, 0))
	Models.part(root, Models.sphere(0.19, 0.36, 16), SNOW, Vector3(0, 0.56, 0))
	Models.part(root, Models.sphere(0.14, 0.27, 14), SNOW, Vector3(0, 0.82, 0))
	var nose := Models.part(root, Models.cylinder(0.0, 0.035, 0.14, 8), CARROT, Vector3(0, 0.82, 0.17))
	nose.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		Models.part(root, Models.sphere(0.022, -1, 6), COAL, Vector3(side * 0.05, 0.87, 0.125))
		var arm := Models.part(root, Models.box_mesh(Vector3(0.26, 0.03, 0.03), 0.01), Models.TRUNK, Vector3(side * 0.28, 0.62, 0))
		arm.rotation.z = side * 0.5
	for k in 2:
		Models.part(root, Models.sphere(0.025, -1, 6), COAL, Vector3(0, 0.6 - k * 0.1, 0.18 - k * 0.005))
	var scarf_c: Color = [SCARF, Color("#7FB2F0"), Color("#FFD166")][r.randi() % 3]
	Models.part(root, Models.cylinder(0.15, 0.16, 0.06, 14), scarf_c, Vector3(0, 0.71, 0))
	var tail := Models.part(root, Models.box_mesh(Vector3(0.07, 0.18, 0.03), 0.01), scarf_c, Vector3(0.09, 0.62, 0.14))
	tail.rotation.z = 0.2
	Models.part(root, Models.cylinder(0.15, 0.15, 0.02, 14), COAL, Vector3(0, 0.94, 0))
	Models.part(root, Models.cylinder(0.09, 0.1, 0.13, 14), COAL, Vector3(0, 1.01, 0))
	root.rotation.y = r.randf_range(-0.6, 0.6)
	return root


## A cluster of tall ice crystals.
static func ice_spire(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.5, 0.12, 0.44) * size, 0.05), SNOW_SHADE, Vector3(0, 0.05, 0))
	crystal(root, 0.11 * size, 0.85 * size, Vector3.ZERO, Vector3(0, r.randf() * TAU, 0.05), ICE)
	crystal(root, 0.07 * size, 0.45 * size, Vector3(0.14, 0, 0.06) * size, Vector3(0.2, 0, -0.45), ICE_DEEP)
	crystal(root, 0.06 * size, 0.32 * size, Vector3(-0.13, 0, -0.04) * size, Vector3(-0.15, 0, 0.5), ICE.lightened(0.2))
	return root


## A low drift of snow: a few crisp rounded slabs.
static func snow_mound(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var n: int = r.randi_range(1, 2)
	for k in n:
		var s := Vector3(r.randf_range(0.42, 0.62), r.randf_range(0.07, 0.12), r.randf_range(0.3, 0.42)) * (1.0 - k * 0.35)
		var m := Models.part(root, Models.box_mesh(s, 0.045), SNOW if k == 0 else SNOW_SHADE.lerp(SNOW, 0.5),
			Vector3(r.randf_range(-0.12, 0.12), s.y * 0.5 + k * 0.06, r.randf_range(-0.1, 0.1)))
		m.rotation.y = r.randf() * TAU
	return root


## A tiny wrapped present half in the snow (for the low, camera-side rim).
static func present(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var col: Color = [SCARF, Color("#7FB2F0"), Color("#9C8CF0"), Color("#7BD389")][r.randi() % 4]
	var s: float = r.randf_range(0.2, 0.28)
	Models.part(root, Models.box_mesh(Vector3(s, s * 0.8, s), 0.03), col, Vector3(0, s * 0.4, 0))
	Models.part(root, Models.box_mesh(Vector3(s + 0.01, s * 0.82, 0.05), 0.012), Color("#FFE9A8"), Vector3(0, s * 0.4, 0))
	Models.part(root, Models.box_mesh(Vector3(0.05, s * 0.82, s + 0.01), 0.012), Color("#FFE9A8"), Vector3(0, s * 0.4, 0))
	root.rotation.y = r.randf() * TAU
	return root


## Snowpuff: a round snowball critter that rolls. "Ball" spins as it rolls;
## the face, hat and feet stay upright on "Body".
static func snowpuff() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var ball := Node3D.new()
	ball.name = "Ball"
	ball.position.y = 0.33
	body.add_child(ball)
	Models.part(ball, Models.sphere(0.31, -1, 20), PUFF)
	# Packed-snow chunks and a few blue specks so the roll reads.
	var bits: Array[Vector3] = [Vector3(0.0, 0.26, -0.17), Vector3(0.22, -0.1, -0.2), Vector3(-0.24, 0.05, -0.18),
		Vector3(0.0, -0.3, 0.05), Vector3(0.27, 0.12, 0.08), Vector3(-0.26, -0.14, 0.1)]
	for k in bits.size():
		var p: Vector3 = bits[k].normalized() * 0.29
		var chunk := Models.part(ball, Models.box_mesh(Vector3(0.12, 0.1, 0.12), 0.035), SNOW if k % 2 == 0 else PUFF.darkened(0.12), p)
		chunk.basis = Basis.looking_at(p.normalized(), Vector3.UP if absf(p.normalized().y) < 0.9 else Vector3.RIGHT)
	# The face sits in front of the ball and never rolls.
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.36, 0.2)
	body.add_child(face)
	Models._eyes(face, 0.03, 0.07, 0.1, 0.07)
	for side: int in [-1, 1]:
		var cheek := Models.part(face, Models.sphere(0.04, -1, 8), Color("#FF9AA8"), Vector3(side * 0.17, -0.06, 0.07))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	var mouth := Models.part(face, Models.box_mesh(Vector3(0.07, 0.03, 0.03), 0.01), Models.INK, Vector3(0, -0.07, 0.1))
	mouth.rotation.x = -0.2
	# A little knit hat with a pompom.
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 0.6, -0.02)
	hat.rotation.x = -0.15
	body.add_child(hat)
	Models.part(hat, Models.cylinder(0.13, 0.17, 0.12, 14), SCARF, Vector3(0, 0.0, 0))
	Models.part(hat, Models.cylinder(0.175, 0.175, 0.05, 14), SNOW, Vector3(0, -0.05, 0))
	Models.part(hat, Models.sphere(0.06, -1, 10), SNOW, Vector3(0, 0.1, 0))
	return root


## Big Brrr, the Frost Peaks boss: a chunky, fluffy blue yeti with snow on
## his shoulders, an ice-blue face, little ice horns, big swinging arms and
## an icicle crown. Everything hangs off "Body/Rig" (scaled up), and the
## arms are "Rig/ArmL" and "Rig/ArmR".
static func yeti() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var rig := Node3D.new()
	rig.name = "Rig"
	rig.scale = Vector3.ONE * 1.22
	body.add_child(rig)
	var fur := Color("#B3C3F2")
	var fur_dark := Color("#94A8E6")
	var face_c := Color("#E9F1FF")
	var hand_c := Color("#6C86D4")
	Models.part(rig, Models.box_mesh(Vector3(1.16, 1.06, 0.96), 0.34), fur, Vector3(0, 0.62, 0))
	# Snow on his head and shoulders: crisp little slabs.
	for k in 5:
		var a: float = -0.9 + k * 0.45
		var t := Models.part(rig, Models.box_mesh(Vector3(0.32, 0.16, 0.32), 0.07), SNOW if k % 2 == 0 else SNOW_SHADE,
			Vector3(sin(a) * 0.4, 1.14 - absf(a) * 0.12, -0.08 + cos(a) * 0.04))
		t.rotation = Vector3(0.15, a, a * 0.35)
	# Belly patch.
	Models.part(rig, Models.box_mesh(Vector3(0.62, 0.36, 0.1), 0.12), face_c, Vector3(0, 0.32, 0.46))
	# The face tilts up a little so it reads from the camera above.
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.78, 0.44)
	face.rotation.x = -0.35
	rig.add_child(face)
	Models.part(face, Models.box_mesh(Vector3(0.8, 0.5, 0.14), 0.12), face_c, Vector3.ZERO)
	Models._eyes(face, 0.07, 0.08, 0.17, 0.1, true)
	Models.part(face, Models.box_mesh(Vector3(0.3, 0.09, 0.05), 0.03), Models.INK, Vector3(0, -0.13, 0.08))
	for side: int in [-1, 1]:
		var fang := Models.part(face, Models.cylinder(0.035, 0.0, 0.09, 6), Models.WHITE, Vector3(side * 0.08, -0.17, 0.1))
		fang.rotation.x = 0.1
		var cheek := Models.part(face, Models.sphere(0.06, -1, 8), Color("#FF9AA8"), Vector3(side * 0.3, -0.06, 0.07))
		cheek.scale = Vector3(1.0, 0.55, 0.4)
		var foot := Models.part(rig, Models.box_mesh(Vector3(0.36, 0.16, 0.44), 0.07), hand_c, Vector3(side * 0.3, 0.08, 0.18))
		foot.name = "FootL" if side < 0 else "FootR"
		# Horns of ice.
		var horn := Models.part(rig, Models.cylinder(0.0, 0.08, 0.32, 6), ICE, Vector3(side * 0.44, 1.28, 0.05))
		horn.rotation.z = side * -0.55
		horn.material_override = ice_glass(ICE_DEEP, 0.5, 0.2)
		# Arms hang from a shoulder pivot so they can swing.
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.6, 0.88, 0.05)
		rig.add_child(arm)
		Models.part(arm, Models.box_mesh(Vector3(0.32, 0.64, 0.36), 0.13), fur_dark, Vector3(side * 0.06, -0.3, 0))
		Models.part(arm, Models.box_mesh(Vector3(0.3, 0.16, 0.3), 0.07), hand_c, Vector3(side * 0.07, -0.63, 0.02))
		Models.part(arm, Models.box_mesh(Vector3(0.3, 0.1, 0.3), 0.04), SNOW, Vector3(side * 0.06, 0.02, 0))
	# Icicle crown.
	var crown := Node3D.new()
	crown.position = Vector3(0, 1.2, 0.02)
	rig.add_child(crown)
	for k in 5:
		var a2: float = PI * (0.15 + 0.7 * k / 4.0)
		var h: float = 0.22 + (0.1 if k == 2 else 0.0)
		var c := Models.part(crown, Models.cylinder(0.0, 0.06, h, 6), ICE, Vector3(cos(a2) * 0.22, h * 0.5, sin(a2) * 0.12 + 0.1))
		c.material_override = ice_glass(Color("#7FD0F6"), 0.5, 0.35)
	return root

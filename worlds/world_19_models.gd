extends RefCounted
## Models for World 19, Slime Lab: the jelly-cube slimes (a solid core in a
## glossy glass skin, three sizes), the Lab Rat robot, the potion vats (green
## goo, blue freeze), goo puddles, ice cubes, King Slime in his beaker and
## the bright lab props: bubbling glass columns, test-tube racks, flasks,
## microscopes and supply boxes. Built from crisp, slightly rounded clay
## blocks and frosted glass like render/Models.gd.

const WHITE := Color("#F7FBFA")
const MINT := Color("#CDEFE2")
const TEAL := Color("#2FB3AE")
const TEAL_DARK := Color("#1F8C8C")
const LIME := Color("#8EDC4E")
const LIME_DARK := Color("#56AE2E")
const LIME_LIGHT := Color("#CDF5A0")
const ICE := Color("#8ED6FF")
const ICE_DARK := Color("#3F9EE8")
const ICE_LIGHT := Color("#E2F6FF")
const PINK := Color("#FF8DB5")
const VIOLET := Color("#A184EE")
const AMBER := Color("#F4AE3D")
const STEEL := Color("#C6D1DC")
const STEEL_DARK := Color("#8292A5")
const INK := Color("#2E2A4A")
const RED := Color("#FF6363")
const GOLD := Color("#F6C445")
const VAT_GOO := Color("#58C734")
const VAT_FREEZE := Color("#46A8F2")

## Body width of each slime size (height is a little less).
const SLIME_SIZE: Dictionary = {&"slime_big": 0.9, &"slime_mid": 0.68, &"slime_small": 0.5}
const SLIME_COLOR: Dictionary = {&"slime_big": Color("#4FBF2E"), &"slime_mid": Color("#5CCB34"), &"slime_small": Color("#6FD63E")}
const BOSS_SIZE: float = 1.3


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _glass_part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, tint: float = 0.3, glow: float = 0.0) -> MeshInstance3D:
	var mi := Models.part(parent, mesh, color, pos)
	mi.material_override = Models.glass(color, tint, glow)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A small smile made of three ink bits.
static func _smile(parent: Node3D, y: float, z: float, w: float) -> void:
	_no_shadow(Models.part(parent, _box(Vector3(w, w * 0.28, w * 0.25), w * 0.1), INK, Vector3(0, y, z)))
	for side: int in [-1, 1]:
		var tip := _no_shadow(Models.part(parent, _box(Vector3(w * 0.4, w * 0.26, w * 0.25), w * 0.1), INK, Vector3(side * w * 0.6, y + w * 0.12, z)))
		tip.rotation.z = side * 0.55


# --- Critters --------------------------------------------------------------------

## A jelly-cube slime: a solid lime core inside a glossy glass skin, with a
## shine on top and a happy face. [param size] is the body width.
static func slime(size: float, color: Color) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, size * 1.35, 0.36)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var h: float = size * 0.8
	Models.part(body, _box(Vector3(size * 0.8, h * 0.8, size * 0.8), size * 0.2), color.darkened(0.2), Vector3(0, h * 0.44, 0))
	_glass_part(body, _box(Vector3(size, h, size), size * 0.24), color, Vector3(0, h * 0.5, 0), 0.72, 0.04)
	_no_shadow(Models.part(body, _box(Vector3(size * 0.3, size * 0.04, size * 0.13), size * 0.02), Color.WHITE, Vector3(-size * 0.2, h * 0.99, -size * 0.14), 0.7))
	_no_shadow(Models.part(body, _box(Vector3(size * 0.1, size * 0.04, size * 0.1), size * 0.02), Color.WHITE, Vector3(-size * 0.02, h * 0.99, -size * 0.2), 0.7))
	var face := Node3D.new()
	face.name = "Face"
	body.add_child(face)
	# The face sits just proud of the glass skin so it reads clearly.
	Models._eyes(face, h * 0.64, size * 0.52, size * 0.2, size * 0.15)
	_smile(face, h * 0.36, size * 0.53, size * 0.15)
	for side: int in [-1, 1]:
		var cheek := _no_shadow(Models.part(face, Models.sphere(size * 0.065, -1, 8), PINK, Vector3(side * size * 0.34, h * 0.44, size * 0.52)))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	return root


## The Lab Rat: a small wheeled steel robot mouse with round ears, a pink
## nose, a cable tail and an antenna light that blinks while it scans.
static func labrat() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.34)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, _box(Vector3(0.44, 0.26, 0.56), 0.11), STEEL, Vector3(0, 0.25, -0.02))
	Models.part(body, _box(Vector3(0.46, 0.07, 0.58), 0.03), TEAL, Vector3(0, 0.15, -0.02))
	Models.part(body, _box(Vector3(0.3, 0.05, 0.3), 0.02), WHITE, Vector3(0, 0.385, -0.06))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.3, 0.24)
	body.add_child(head)
	Models.part(head, _box(Vector3(0.34, 0.24, 0.26), 0.1), WHITE, Vector3(0, 0.0, 0.04))
	Models.part(head, Models.sphere(0.05, -1, 10), PINK, Vector3(0, -0.02, 0.19), 0.2)
	Models._eyes(head, 0.04, 0.15, 0.085, 0.055)
	for side: int in [-1, 1]:
		var ear := Models.part(head, Models.cylinder(0.11, 0.11, 0.035, 18), STEEL, Vector3(side * 0.15, 0.17, -0.02))
		ear.rotation.x = PI * 0.5
		var inner := _no_shadow(Models.part(head, Models.cylinder(0.07, 0.07, 0.02, 14), PINK, Vector3(side * 0.15, 0.17, 0.0)))
		inner.rotation.x = PI * 0.5
	var wheels := Node3D.new()
	wheels.name = "Wheels"
	body.add_child(wheels)
	for sx: int in [-1, 1]:
		for sz: int in [-1, 1]:
			var w := Models.part(wheels, Models.cylinder(0.075, 0.075, 0.06, 12), INK, Vector3(sx * 0.21, 0.08, sz * 0.16 - 0.02))
			w.rotation.z = PI * 0.5
	Models.part(body, Models.cylinder(0.014, 0.014, 0.2, 6), STEEL_DARK, Vector3(0, 0.48, -0.1))
	var light := Models.part(body, Models.sphere(0.05, -1, 10), TEAL, Vector3(0, 0.6, -0.1), 1.2)
	light.name = "Light"
	for k in 3:
		var seg := Models.part(body, Models.cylinder(0.022, 0.022, 0.16, 6), PINK, Vector3(0.04 * k, 0.16 + 0.04 * k, -0.36 - 0.12 * k))
		seg.rotation.x = PI * 0.5 - 0.3 * k
	return root


## King Slime: a huge crowned jelly cube sitting in a glass beaker.
static func king_slime() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, Models.cylinder(0.62, 0.65, 0.1, 28), STEEL, Vector3(0, 0.05, 0))
	# A big crowned jelly cube, rising well out of its beaker.
	var slime := Node3D.new()
	slime.name = "Slime"
	slime.position = Vector3(0, 0.06, 0)
	body.add_child(slime)
	Models.part(slime, _box(Vector3(0.9, 0.84, 0.9), 0.28), LIME_DARK, Vector3(0, 0.46, 0))
	_glass_part(slime, _box(Vector3(1.08, 1.04, 1.08), 0.32), Color("#4FBF2E"), Vector3(0, 0.52, 0), 0.72, 0.04)
	_no_shadow(Models.part(slime, _box(Vector3(0.34, 0.04, 0.14), 0.02), Color.WHITE, Vector3(-0.26, 1.04, -0.22), 0.7))
	_no_shadow(Models.part(slime, _box(Vector3(0.12, 0.04, 0.12), 0.02), Color.WHITE, Vector3(-0.06, 1.04, -0.3), 0.7))
	var face := Node3D.new()
	face.name = "Face"
	slime.add_child(face)
	Models._eyes(face, 0.78, 0.56, 0.22, 0.15, true)
	_smile(face, 0.56, 0.57, 0.16)
	for side: int in [-1, 1]:
		var cheek := _no_shadow(Models.part(face, Models.sphere(0.06, -1, 8), PINK, Vector3(side * 0.36, 0.62, 0.56)))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0, 1.03, 0.0)
	slime.add_child(crown)
	Models.part(crown, Models.cylinder(0.26, 0.28, 0.14, 20), GOLD, Vector3(0, 0.07, 0), 0.15)
	for k in 5:
		var a: float = TAU * k / 5.0
		Models.part(crown, Models.cylinder(0.0, 0.08, 0.2, 4), GOLD, Vector3(sin(a) * 0.21, 0.24, cos(a) * 0.21), 0.15)
		Models.part(crown, Models.sphere(0.045, -1, 8), PINK if k % 2 == 0 else ICE_DARK, Vector3(sin(a) * 0.275, 0.07, cos(a) * 0.275), 0.5)
	# The beaker: open-topped glass with a white lip ring, a spout and marks.
	var glass_mesh := Models.cylinder(0.65, 0.64, 0.44, 28)
	glass_mesh.cap_top = false
	_glass_part(body, glass_mesh, ICE_LIGHT, Vector3(0, 0.32, 0), 0.12, 0.05)
	var lip := TorusMesh.new()
	lip.inner_radius = 0.62
	lip.outer_radius = 0.7
	lip.rings = 32
	lip.ring_segments = 8
	Models.part(body, lip, WHITE, Vector3(0, 0.54, 0)).scale = Vector3(1.0, 0.6, 1.0)
	Models.part(body, _box(Vector3(0.18, 0.05, 0.14), 0.02), WHITE, Vector3(0.6, 0.55, -0.32)).rotation.y = 0.5
	for k in 3:
		_no_shadow(Models.part(body, _box(Vector3(0.14 - k * 0.03, 0.02, 0.02), 0.006), WHITE, Vector3(-0.4, 0.18 + k * 0.1, 0.52)))
	return root


# --- Lab tiles ----------------------------------------------------------------------

## A potion vat: a glass tank of glowing liquid on a steel base, with a
## label plate (a goo drop or a snowflake) and bubbles. Its "Liquid" pivot
## scales down when the vat is emptied.
static func vat(freeze: bool) -> Node3D:
	var color: Color = VAT_FREEZE if freeze else VAT_GOO
	var root := Node3D.new()
	Models.blob_shadow(root, 1.15, 0.32)
	Models.part(root, Models.cylinder(0.42, 0.45, 0.14, 22), STEEL, Vector3(0, 0.07, 0))
	Models.part(root, Models.cylinder(0.43, 0.43, 0.04, 22), color.darkened(0.3), Vector3(0, 0.15, 0))
	# The potion itself is the tank's body (solid, so its colour reads
	# clean); a glass shell shows above it once the vat has been emptied.
	var liquid := Node3D.new()
	liquid.name = "Liquid"
	liquid.position = Vector3(0, 0.16, 0)
	root.add_child(liquid)
	Models.part(liquid, Models.cylinder(0.36, 0.36, 0.62, 24), color, Vector3(0, 0.31, 0), 0.12)
	Models.part(liquid, Models.cylinder(0.3, 0.3, 0.02, 22), color.lightened(0.18), Vector3(0, 0.625, 0), 0.2)
	var shine := _no_shadow(Models.part(liquid, _box(Vector3(0.05, 0.46, 0.02), 0.01), Color.WHITE, Vector3(-0.2, 0.33, 0.29), 0.4))
	shine.rotation.y = -0.6
	var tank := Models.cylinder(0.345, 0.345, 0.68, 24)
	tank.cap_top = false
	_glass_part(root, tank, ICE_LIGHT, Vector3(0, 0.5, 0), 0.1, 0.04)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.32
	ring.outer_radius = 0.4
	ring.rings = 24
	ring.ring_segments = 8
	var top := Models.part(root, ring, STEEL, Vector3(0, 0.84, 0))
	top.scale = Vector3(1.0, 0.6, 1.0)
	for k in 3:
		var a: float = TAU * k / 3.0 + PI / 3.0
		Models.part(root, _box(Vector3(0.05, 0.7, 0.05), 0.02), STEEL, Vector3(sin(a) * 0.37, 0.5, cos(a) * 0.37))
	var bubbles := Node3D.new()
	bubbles.name = "Bubbles"
	root.add_child(bubbles)
	for k in 3:
		var b := _no_shadow(Models.part(bubbles, Models.sphere(0.055, -1, 8), color.lightened(0.5), Vector3(-0.12 + k * 0.12, 0.8, 0.06 - k * 0.07), 0.5))
		b.set_meta(&"phase", k / 3.0)
	# Label plate facing the camera.
	Models.part(root, _box(Vector3(0.28, 0.24, 0.03), 0.03), WHITE, Vector3(0, 0.44, 0.375))
	if freeze:
		for k in 3:
			var arm := _no_shadow(Models.part(root, _box(Vector3(0.18, 0.03, 0.02), 0.008), ICE_DARK, Vector3(0, 0.44, 0.395), 0.2))
			arm.rotation.z = PI * k / 3.0
	else:
		_no_shadow(Models.part(root, Models.sphere(0.055, -1, 10), LIME_DARK, Vector3(0, 0.42, 0.395), 0.2))
		var tip := _no_shadow(Models.part(root, Models.cylinder(0.0, 0.05, 0.08, 10), LIME_DARK, Vector3(0, 0.48, 0.395), 0.2))
		tip.rotation.x = 0.0
	return root


## A glossy goo puddle filling one tile.
static func goo_puddle(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	_no_shadow(Models.part(root, _box(Vector3(0.88, 0.05, 0.88), 0.025), LIME, Vector3(0, 0.03, 0), 0.12))
	for k in 2:
		var bump := _no_shadow(Models.part(root, Models.sphere(0.07, 0.06, 10), LIME_LIGHT, Vector3(r.randf_range(-0.28, 0.28), 0.06, r.randf_range(-0.28, 0.28)), 0.3))
		bump.scale = Vector3(1.3, 1.0, 1.3)
	_no_shadow(Models.part(root, _box(Vector3(0.22, 0.02, 0.06), 0.01), Color.WHITE, Vector3(-0.2, 0.06, -0.24), 0.5))
	return root


## A thin frosty sheet left for a moment where a freeze splash lands.
static func frost() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = _box(Vector3(0.9, 0.03, 0.9), 0.015)
	mi.material_override = Models.mat(ICE_LIGHT, 0.35)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A glass ice cube to put round a frozen critter.
static func ice_cube(size: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Ice"
	_glass_part(root, _box(Vector3(size, size * 0.95, size), size * 0.1), ICE, Vector3(0, size * 0.47, 0), 0.22, 0.12)
	_no_shadow(Models.part(root, _box(Vector3(size * 0.5, size * 0.04, size * 0.08), size * 0.02), Color.WHITE, Vector3(-size * 0.15, size * 0.95, -size * 0.3), 0.8))
	return root


## The dashed target ring King Slime's goo lob aims at.
static func lob_marker() -> Node3D:
	var root := Node3D.new()
	for k in 8:
		var a: float = TAU * k / 8.0
		var dash := _no_shadow(Models.part(root, _box(Vector3(0.2, 0.04, 0.08), 0.02), LIME_DARK, Vector3(sin(a) * 0.4, 0.04, cos(a) * 0.4), 0.6))
		dash.rotation.y = a + PI * 0.5
	_no_shadow(Models.part(root, Models.cylinder(0.12, 0.12, 0.03, 14), LIME, Vector3(0, 0.03, 0), 0.8))
	return root


static func goo_blob() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.sphere(0.2, -1, 14), LIME_DARK, Vector3.ZERO, 0.2)
	_glass_part(root, Models.sphere(0.27, -1, 16), LIME, Vector3.ZERO, 0.5, 0.1)
	return root


# --- Lab props ----------------------------------------------------------------------

## A tall glass column of glowing liquid with steel caps. Its bubbles are
## put in [param bubbles] for the world to animate.
static func column(r: RandomNumberGenerator, h: float, bubbles: Array[Dictionary]) -> Node3D:
	var colors: Array[Color] = [LIME, ICE, PINK, VIOLET]
	var color: Color = colors[r.randi() % colors.size()]
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.3)
	Models.part(root, Models.cylinder(0.3, 0.32, 0.14, 18), STEEL, Vector3(0, 0.07, 0))
	Models.part(root, Models.cylinder(0.21, 0.21, h * 0.78, 16), color, Vector3(0, 0.14 + h * 0.39, 0), 0.3)
	_glass_part(root, Models.cylinder(0.25, 0.25, h, 18), ICE_LIGHT, Vector3(0, 0.14 + h * 0.5, 0), 0.1, 0.04)
	Models.part(root, Models.cylinder(0.28, 0.3, 0.12, 18), STEEL, Vector3(0, 0.2 + h, 0))
	Models.part(root, Models.sphere(0.06, -1, 8), color, Vector3(0, 0.3 + h, 0), 1.0)
	for k in 3:
		var b := _no_shadow(Models.part(root, Models.sphere(0.045, -1, 8), color.lightened(0.6), Vector3(r.randf_range(-0.1, 0.1), 0.3, r.randf_range(-0.1, 0.1)), 0.8))
		bubbles.append({"node": b, "y0": 0.25, "h": h * 0.65, "speed": r.randf_range(0.35, 0.55), "phase": r.randf()})
	return root


## A white rack of test tubes with coloured liquid.
static func tube_rack(r: RandomNumberGenerator) -> Node3D:
	var colors: Array[Color] = [LIME, ICE, PINK, VIOLET, AMBER]
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.28)
	Models.part(root, _box(Vector3(0.62, 0.08, 0.24), 0.03), WHITE, Vector3(0, 0.04, 0))
	Models.part(root, _box(Vector3(0.62, 0.05, 0.24), 0.02), TEAL, Vector3(0, 0.22, 0))
	for k in 4:
		var x: float = -0.21 + k * 0.14
		var fill: float = r.randf_range(0.12, 0.24)
		Models.part(root, Models.cylinder(0.04, 0.04, fill, 10), colors[r.randi() % colors.size()], Vector3(x, 0.08 + fill * 0.5, 0), 0.3)
		_glass_part(root, Models.cylinder(0.05, 0.05, 0.34, 10), ICE_LIGHT, Vector3(x, 0.24, 0), 0.08)
	return root


## A conical flask with a coloured potion.
static func flask(r: RandomNumberGenerator, s: float = 1.0) -> Node3D:
	var colors: Array[Color] = [LIME, ICE, PINK, VIOLET]
	var color: Color = colors[r.randi() % colors.size()]
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7 * s, 0.26)
	Models.part(root, Models.cylinder(0.1 * s, 0.2 * s, 0.16 * s, 16), color, Vector3(0, 0.09 * s, 0), 0.3)
	_glass_part(root, Models.cylinder(0.07 * s, 0.24 * s, 0.34 * s, 16), ICE_LIGHT, Vector3(0, 0.17 * s, 0), 0.08)
	_glass_part(root, Models.cylinder(0.065 * s, 0.065 * s, 0.16 * s, 12), ICE_LIGHT, Vector3(0, 0.42 * s, 0), 0.08)
	Models.part(root, Models.cylinder(0.075 * s, 0.075 * s, 0.03 * s, 12), WHITE, Vector3(0, 0.5 * s, 0))
	return root


## A friendly white microscope.
static func microscope() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.28)
	Models.part(root, _box(Vector3(0.36, 0.07, 0.42), 0.03), WHITE, Vector3(0, 0.035, 0))
	Models.part(root, _box(Vector3(0.1, 0.42, 0.1), 0.04), WHITE, Vector3(0, 0.25, -0.14))
	Models.part(root, _box(Vector3(0.26, 0.04, 0.22), 0.02), TEAL, Vector3(0, 0.2, 0.04))
	var tube := Models.part(root, Models.cylinder(0.06, 0.07, 0.36, 12), WHITE, Vector3(0, 0.44, -0.04))
	tube.rotation.x = 0.4
	Models.part(root, Models.cylinder(0.045, 0.045, 0.06, 10), INK, Vector3(0, 0.6, -0.11))
	Models.part(root, Models.cylinder(0.04, 0.04, 0.08, 10), STEEL_DARK, Vector3(0, 0.25, 0.07))
	return root


## A white supply box with a teal stripe.
static func supply_box(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.3)
	var w: float = r.randf_range(0.42, 0.58)
	Models.part(root, _box(Vector3(w, 0.32, w * 0.8), 0.05), WHITE, Vector3(0, 0.16, 0))
	Models.part(root, _box(Vector3(w + 0.01, 0.06, w * 0.8 + 0.01), 0.02), TEAL, Vector3(0, 0.2, 0))
	Models.part(root, _box(Vector3(0.1, 0.1, 0.02), 0.01), LIME, Vector3(0, 0.16, w * 0.4 + 0.005), 0.3)
	return root


## A big glass dome greenhouse of glowing goo for the far islands.
static func dome(size: float) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(size * 0.5, size * 0.52, size * 0.12, 24), WHITE, Vector3(0, size * 0.06, 0))
	var goo := Models.part(root, Models.sphere(size * 0.36, -1, 20), LIME, Vector3(0, size * 0.12, 0), 0.3)
	goo.scale = Vector3(1.0, 0.45, 1.0)
	var glass := _glass_part(root, Models.sphere(size * 0.46, -1, 24), ICE_LIGHT, Vector3(0, size * 0.12, 0), 0.08, 0.04)
	glass.scale = Vector3(1.0, 0.9, 1.0)
	Models.part(root, Models.sphere(size * 0.05, -1, 10), TEAL, Vector3(0, size * 0.55, 0), 0.6)
	return root

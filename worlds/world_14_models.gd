extends RefCounted
## Models for World 14, Magnet Mines: horseshoe magnets (red pulls, blue
## pushes), the flip-switch dial, the Cartbug (a tin mine-cart beetle),
## Magnamole the boss and the cheerful copper-and-teal mine props. Built from
## crisp, slightly rounded clay blocks like render/Models.gd.

const RED := Color("#F2554E")
const BLUE := Color("#4F86F7")
const SILVER := Color("#E6EEF2")
const STEEL := Color("#3E5C66")
const STEEL_DARK := Color("#2B434C")
const TIN := Color("#B9CAD3")
const COPPER := Color("#E08A4A")
const COPPER_DARK := Color("#B4622F")
const TEAL := Color("#2FB8AC")
const TEAL_LIGHT := Color("#7FE6D8")
const TIMBER := Color("#B07A4C")
const TIMBER_DARK := Color("#875733")
const LANTERN := Color("#FFD27A")
const GOLD := Color("#F6C445")
const ROCK := Color("#A98C79")
const MOLE := Color("#6F6680")
const MOLE_BELLY := Color("#D9C6B5")
const NOSE := Color("#FF8FA3")
const HAT := Color("#F7C548")
const BOSS_SIZE: float = 1.25
const CART_SIZE: float = 1.05

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A horseshoe magnet's U in the xy plane (opening up), [param size] tall.
static func horseshoe_mesh(size: float, depth: float) -> ArrayMesh:
	var key := "shoe/%.3f/%.3f" % [size, depth]
	if not _shapes.has(key):
		var ro: float = size * 0.5
		var ri: float = size * 0.22
		var top: float = size * 0.5
		var pts := PackedVector2Array()
		pts.append(Vector2(-ro, top))
		for k in 13:
			var a: float = PI + PI * k / 12.0
			pts.append(Vector2(cos(a) * ro, sin(a) * ro))
		pts.append(Vector2(ro, top))
		pts.append(Vector2(ri, top))
		for k in 13:
			var a2: float = TAU - PI * k / 12.0
			pts.append(Vector2(cos(a2) * ri, sin(a2) * ri))
		pts.append(Vector2(-ri, top))
		# Counter-clockwise for the extruder.
		var ccw := PackedVector2Array()
		for i in range(pts.size() - 1, -1, -1):
			ccw.append(pts[i])
		if Geometry2D.is_polygon_clockwise(ccw):
			ccw = pts
		_shapes[key] = ClayShapes.extrusion(ccw, depth, depth * 0.25, 2)
	return _shapes[key]


## A flat arrow (chevron) lying on the floor, pointing +X.
static func floor_chevron() -> ArrayMesh:
	var key := "fchev"
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(-0.16, 0.22), Vector2(0.0, 0.22), Vector2(0.18, 0.0), Vector2(0.0, -0.22), Vector2(-0.16, -0.22), Vector2(0.02, 0.0)])
		var m: ArrayMesh = ClayShapes.extrusion(pts, 0.025, 0.008, 1)
		_shapes[key] = m
	return _shapes[key]


# --- Magnets and switches -------------------------------------------------------

## One horseshoe in [param color] with silver pole tips.
static func _shoe(parent: Node3D, color: Color, name: String) -> Node3D:
	var n := Node3D.new()
	n.name = name
	parent.add_child(n)
	Models.part(n, horseshoe_mesh(0.74, 0.26), color, Vector3(0, 0.0, 0), 0.2)
	for side: int in [-1, 1]:
		Models.part(n, _box(Vector3(0.22, 0.15, 0.28), 0.05), SILVER, Vector3(side * 0.24, 0.41, 0))
	# A shine on the bend so the colours read even at a glance.
	_no_shadow(Models.part(n, _box(Vector3(0.2, 0.06, 0.03), 0.02), color.lightened(0.6), Vector3(-0.12, -0.26, 0.135), 1.0)).rotation.z = -0.5
	return n


## A magnet block: a riveted steel pedestal with a glowing polarity band and
## a big horseshoe magnet standing on it. "Spin" holds a red ("Red") and a
## blue ("Blue") magnet; show the one that matches the polarity.
static func magnet(pull: bool) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.86, 0.24, 0.86), 0.08), STEEL, Vector3(0, 0.12, 0))
	Models.part(root, _box(Vector3(0.9, 0.07, 0.9), 0.03), STEEL_DARK, Vector3(0, 0.26, 0))
	for sx: float in [-0.34, 0.34]:
		for sz: float in [-0.34, 0.34]:
			Models.part(root, Models.sphere(0.035, -1, 8), COPPER, Vector3(sx, 0.3, sz))
	var band := Node3D.new()
	band.name = "Band"
	root.add_child(band)
	var br := _no_shadow(Models.part(band, _box(Vector3(0.88, 0.05, 0.88), 0.02), RED, Vector3(0, 0.15, 0), 1.3))
	br.name = "Red"
	var bb := _no_shadow(Models.part(band, _box(Vector3(0.88, 0.05, 0.88), 0.02), BLUE, Vector3(0, 0.15, 0), 1.3))
	bb.name = "Blue"
	var spin := Node3D.new()
	spin.name = "Spin"
	spin.position.y = 0.66
	root.add_child(spin)
	_shoe(spin, RED, "Red")
	_shoe(spin, BLUE, "Blue")
	set_pole(root, pull)
	return root


static func set_pole(root: Node3D, pull: bool) -> void:
	root.get_node("Spin/Red").visible = pull
	root.get_node("Spin/Blue").visible = not pull
	root.get_node("Band/Red").visible = pull
	root.get_node("Band/Blue").visible = not pull


## The flip switch: a copper post with a round dial, half red half blue,
## that turns over every time a blast hits it ("Dial").
static func flipper() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.8, 0.22, 0.8), 0.07), COPPER_DARK, Vector3(0, 0.11, 0))
	Models.part(root, _box(Vector3(0.6, 0.1, 0.6), 0.04), COPPER, Vector3(0, 0.26, 0))
	Models.part(root, Models.cylinder(0.08, 0.1, 0.36, 10), STEEL, Vector3(0, 0.46, 0))
	var dial := Node3D.new()
	dial.name = "Dial"
	dial.position = Vector3(0, 0.78, 0.0)
	root.add_child(dial)
	var rim := Models.part(dial, Models.cylinder(0.33, 0.33, 0.14, 24), SILVER, Vector3.ZERO)
	rim.rotation.x = PI * 0.5
	for k in 2:
		var half := Node3D.new()
		half.rotation.z = PI * k
		dial.add_child(half)
		var pts := PackedVector2Array()
		for i in 13:
			var a: float = PI * i / 12.0
			pts.append(Vector2(cos(a), sin(a)) * 0.27)
		var mesh: ArrayMesh = ClayShapes.extrusion(pts, 0.18, 0.03, 1)
		_no_shadow(Models.part(half, mesh, RED if k == 0 else BLUE, Vector3(0, 0.012, 0), 0.5))
	# A lightning tick across the middle.
	_no_shadow(Models.part(dial, _box(Vector3(0.5, 0.05, 0.2), 0.02), SILVER, Vector3.ZERO, 0.4))
	var bulb := _no_shadow(Models.part(root, Models.sphere(0.07, -1, 10), LANTERN, Vector3(0, 1.16, 0), 1.6))
	bulb.name = "Bulb"
	return root


# --- Critters -----------------------------------------------------------------------

## The Cartbug: a tin mine cart with a beetle's face, lantern feelers and
## four wheels ("WheelA".."WheelD").
static func cartbug() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.95, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * CART_SIZE
	root.add_child(body)
	var wheel := Models.cylinder(0.085, 0.085, 0.06, 12)
	var k: int = 0
	for sx: float in [-0.22, 0.22]:
		for sz: float in [-0.14, 0.14]:
			var w := Models.part(body, wheel, STEEL_DARK, Vector3(sx, 0.09, sz))
			w.rotation.z = PI * 0.5
			w.name = "Wheel" + "ABCD"[k]
			Models.part(w, Models.cylinder(0.04, 0.04, 0.075, 8), COPPER, Vector3.ZERO)
			k += 1
	# The tub, wider at the top like a real cart.
	Models.part(body, _box(Vector3(0.42, 0.12, 0.36), 0.04), TIN.darkened(0.12), Vector3(0, 0.2, 0))
	Models.part(body, _box(Vector3(0.52, 0.2, 0.44), 0.06), TIN, Vector3(0, 0.34, 0))
	Models.part(body, _box(Vector3(0.56, 0.06, 0.48), 0.025), COPPER, Vector3(0, 0.45, 0))
	for sx: float in [-0.14, 0.14]:
		Models.part(body, _box(Vector3(0.04, 0.2, 0.46), 0.015), COPPER_DARK, Vector3(sx, 0.33, 0))
	# Ore heaped inside.
	Models.part(body, Models.sphere(0.1, -1, 8), GOLD, Vector3(-0.1, 0.5, -0.04), 0.2)
	Models.part(body, Models.sphere(0.08, -1, 8), TEAL_LIGHT, Vector3(0.1, 0.5, -0.06), 0.4)
	Models.part(body, Models.sphere(0.07, -1, 8), COPPER, Vector3(0.0, 0.52, 0.08))
	# Beetle face on the front.
	Models._eyes(body, 0.36, 0.23, 0.11, 0.075)
	var mouth := Models.part(body, _box(Vector3(0.1, 0.03, 0.03), 0.01), Models.INK, Vector3(0, 0.26, 0.235))
	mouth.rotation.x = -0.2
	var ant := Node3D.new()
	ant.name = "Antennae"
	ant.position = Vector3(0, 0.46, 0.18)
	body.add_child(ant)
	for side: int in [-1, 1]:
		var stalk := Models.part(ant, Models.cylinder(0.012, 0.016, 0.2, 6), STEEL_DARK, Vector3(side * 0.08, 0.09, 0.03))
		stalk.rotation.z = side * -0.35
		stalk.rotation.x = 0.3
		_no_shadow(Models.part(ant, Models.sphere(0.045, -1, 8), LANTERN, Vector3(side * 0.12, 0.19, 0.07), 1.8))
	return root


## Magnamole: a big soft mole miner in a hard hat and iron armour with a
## giant horseshoe magnet on his back ("Mag/Red", "Mag/Blue"), goggles, a pink
## nose and digging claws ("ArmL", "ArmR"). "Aura" is a floor ring for when
## he magnetises himself.
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	# Feet.
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.3, 0.16, 0.36), 0.07), MOLE.darkened(0.2), Vector3(side * 0.32, 0.08, 0.1))
	# Round body with an iron chest plate.
	var trunk := Models.part(body, Models.sphere(0.62, 1.1, 24), MOLE, Vector3(0, 0.66, 0))
	trunk.scale = Vector3(1.0, 1.0, 0.92)
	var belly := Models.part(body, Models.sphere(0.42, 0.7, 18), MOLE_BELLY, Vector3(0, 0.56, 0.26))
	belly.scale = Vector3(1.0, 1.0, 0.6)
	Models.part(body, _box(Vector3(0.62, 0.3, 0.1), 0.05), STEEL, Vector3(0, 0.5, 0.52))
	for sx: float in [-0.22, 0.22]:
		Models.part(body, Models.sphere(0.035, -1, 8), COPPER, Vector3(sx, 0.58, 0.58))
	# Shoulder armour.
	for side: int in [-1, 1]:
		var pad := Models.part(body, _box(Vector3(0.34, 0.14, 0.42), 0.06), STEEL, Vector3(side * 0.5, 1.0, 0))
		pad.rotation.z = side * -0.45
	# Face: goggles, a pink nose, whiskers.
	for side: int in [-1, 1]:
		var ring := Models.part(body, Models.cylinder(0.12, 0.12, 0.07, 16), COPPER, Vector3(side * 0.17, 0.98, 0.5))
		ring.rotation.x = PI * 0.5
		_no_shadow(Models.part(body, Models.cylinder(0.085, 0.085, 0.08, 16), TEAL_LIGHT, Vector3(side * 0.17, 0.98, 0.52), 0.7)).rotation.x = PI * 0.5
		var pupil := Models.part(body, Models.sphere(0.04, -1, 8), Models.INK, Vector3(side * 0.17, 0.97, 0.57))
		pupil.name = "PupilL" if side < 0 else "PupilR"
		for k in 2:
			var wh := Models.part(body, _box(Vector3(0.22, 0.018, 0.018), 0.006), Models.INK.lightened(0.3), Vector3(side * 0.25, 0.8 - k * 0.05, 0.56))
			wh.rotation.z = side * (0.15 - k * 0.3)
	Models.part(body, Models.cylinder(0.035, 0.035, 0.3, 6), COPPER_DARK, Vector3(0, 0.98, 0.5)).rotation.z = PI * 0.5
	var nose := Models.part(body, Models.sphere(0.11, -1, 14), NOSE, Vector3(0, 0.82, 0.62))
	nose.name = "Nose"
	# Hard hat with a lantern.
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 1.18, 0.05)
	body.add_child(hat)
	Models.part(hat, Models.sphere(0.4, 0.5, 20), HAT, Vector3(0, 0.02, 0))
	Models.part(hat, Models.cylinder(0.5, 0.5, 0.05, 24), HAT.darkened(0.12), Vector3(0, 0.0, 0.02))
	Models.part(hat, _box(Vector3(0.08, 0.3, 0.06), 0.02), HAT.darkened(0.1), Vector3(0, 0.12, 0.0)).rotation.x = -0.2
	Models.part(hat, Models.cylinder(0.09, 0.1, 0.1, 12), STEEL, Vector3(0, 0.12, 0.36)).rotation.x = PI * 0.5
	var lamp := _no_shadow(Models.part(hat, Models.cylinder(0.07, 0.07, 0.03, 12), LANTERN, Vector3(0, 0.12, 0.42), 2.2))
	lamp.rotation.x = PI * 0.5
	lamp.name = "Lamp"
	# The big magnet on his back.
	var mag := Node3D.new()
	mag.name = "Mag"
	mag.position = Vector3(0, 1.0, -0.62)
	mag.rotation.x = -0.25
	body.add_child(mag)
	_shoe(mag, RED, "Red").scale = Vector3.ONE * 1.25
	_shoe(mag, BLUE, "Blue").scale = Vector3.ONE * 1.25
	mag.get_node("Red").visible = false
	mag.get_node("Blue").visible = false
	Models.part(mag, _box(Vector3(0.12, 0.3, 0.12), 0.03), STEEL, Vector3(0, -0.3, 0.1))
	# Digging claws.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.6, 0.7, 0.18)
		body.add_child(arm)
		Models.part(arm, Models.sphere(0.16, -1, 12), MOLE, Vector3.ZERO)
		Models.part(arm, _box(Vector3(0.26, 0.1, 0.24), 0.04), NOSE.lightened(0.25), Vector3(side * 0.08, -0.12, 0.14))
		for c in 3:
			var claw := Models.part(arm, Models.cylinder(0.0, 0.035, 0.14, 6), Models.WHITE, Vector3(side * 0.08 + (c - 1) * 0.07, -0.14, 0.3))
			claw.rotation.x = PI * 0.5
	var aura := Node3D.new()
	aura.name = "Aura"
	root.add_child(aura)
	var ring_mesh := TorusMesh.new()
	ring_mesh.inner_radius = 0.78
	ring_mesh.outer_radius = 0.88
	ring_mesh.rings = 32
	ring_mesh.ring_segments = 4
	var ar := _no_shadow(Models.part(aura, ring_mesh, RED, Vector3(0, 0.05, 0), 1.6))
	ar.name = "Red"
	ar.scale = Vector3(1, 0.4, 1)
	var ab := _no_shadow(Models.part(aura, ring_mesh, BLUE, Vector3(0, 0.05, 0), 1.6))
	ab.name = "Blue"
	ab.scale = Vector3(1, 0.4, 1)
	aura.visible = false
	return root


## Shows Magnamole's own magnet: 0 none, 1 red (pull), -1 blue (push).
static func set_boss_pole(root: Node3D, pole: int) -> void:
	var mag: Node3D = root.get_node("Body/Mag")
	mag.get_node("Red").visible = pole > 0
	mag.get_node("Blue").visible = pole < 0
	var aura: Node3D = root.get_node("Aura")
	aura.visible = pole != 0
	aura.get_node("Red").visible = pole > 0
	aura.get_node("Blue").visible = pole < 0


# --- Mine props ---------------------------------------------------------------------

## A timber post with a glowing lantern hanging off an arm.
static func lantern_post() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.14, 1.1, 0.14), 0.03), TIMBER, Vector3(0, 0.55, 0))
	Models.part(root, _box(Vector3(0.36, 0.08, 0.08), 0.02), TIMBER_DARK, Vector3(0.12, 1.06, 0))
	Models.part(root, Models.cylinder(0.008, 0.008, 0.12, 4), STEEL_DARK, Vector3(0.26, 0.97, 0))
	Models.part(root, _box(Vector3(0.16, 0.04, 0.16), 0.015), COPPER_DARK, Vector3(0.26, 0.9, 0))
	_no_shadow(Models.part(root, _box(Vector3(0.12, 0.16, 0.12), 0.03), LANTERN, Vector3(0.26, 0.8, 0), 2.0))
	Models.part(root, _box(Vector3(0.16, 0.04, 0.16), 0.015), COPPER_DARK, Vector3(0.26, 0.7, 0))
	return root


## A small mine cart full of ore on a stub of rail.
static func ore_cart(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.rotation.y = r.randf_range(-0.4, 0.4)
	for sz: float in [-0.13, 0.13]:
		Models.part(root, _box(Vector3(0.8, 0.03, 0.04), 0.01), SILVER.darkened(0.25), Vector3(0, 0.03, sz))
	for sx: float in [-0.28, 0.0, 0.28]:
		Models.part(root, _box(Vector3(0.08, 0.025, 0.42), 0.01), TIMBER_DARK, Vector3(sx, 0.012, 0))
	for sx: float in [-0.15, 0.15]:
		for sz: float in [-0.12, 0.12]:
			Models.part(root, Models.cylinder(0.06, 0.06, 0.04, 10), STEEL_DARK, Vector3(sx, 0.09, sz)).rotation.x = PI * 0.5
	Models.part(root, _box(Vector3(0.44, 0.22, 0.32), 0.05), COPPER, Vector3(0, 0.24, 0))
	Models.part(root, _box(Vector3(0.48, 0.04, 0.36), 0.015), COPPER_DARK, Vector3(0, 0.36, 0))
	var ore: Array[Color] = [GOLD, TEAL_LIGHT, COPPER.lightened(0.2)]
	for k in 3:
		Models.part(root, Models.sphere(0.08, -1, 8), ore[(k + r.randi()) % 3], Vector3(-0.1 + k * 0.1, 0.4, r.randf_range(-0.05, 0.05)), 0.2)
	return root


## A cluster of glowing teal crystals.
static func crystals(r: RandomNumberGenerator, s: float) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.42, 0.14, 0.36), 0.06), ROCK.darkened(0.1), Vector3(0, 0.07, 0))
	for k in 3:
		var h: float = r.randf_range(0.3, 0.55) * s
		var c := _no_shadow(Models.part(root, Models.cylinder(0.0, 0.09 * s, h, 6), TEAL if k % 2 == 0 else TEAL_LIGHT, Vector3(-0.1 + k * 0.1, 0.1 + h * 0.5, r.randf_range(-0.06, 0.06)), 0.5))
		c.rotation.z = (k - 1) * 0.35
	return root


## A mine entrance: two timber posts and a beam over a dark doorway.
static func mine_door() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.9, 0.8, 0.1), 0.05), Color("#3A2C2A"), Vector3(0, 0.4, -0.02))
	for sx: float in [-0.48, 0.48]:
		Models.part(root, _box(Vector3(0.14, 0.95, 0.14), 0.03), TIMBER, Vector3(sx, 0.47, 0.04))
	Models.part(root, _box(Vector3(1.2, 0.16, 0.18), 0.04), TIMBER_DARK, Vector3(0, 0.98, 0.04))
	_no_shadow(Models.part(root, _box(Vector3(0.1, 0.13, 0.1), 0.03), LANTERN, Vector3(0.3, 0.82, 0.14), 2.0))
	return root


## A low heap of ore rocks with a nugget or two.
static func ore_pile(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf()
		var b := Models.part(root, _box(Vector3(0.22, 0.16, 0.2), 0.06), ROCK.darkened(r.randf() * 0.15), Vector3(cos(a) * 0.12, 0.08, sin(a) * 0.12))
		b.rotation.y = r.randf() * TAU
	Models.part(root, Models.sphere(0.06, -1, 8), GOLD, Vector3(0.0, 0.2, 0.02), 0.3)
	if r.randf() < 0.5:
		Models.part(root, Models.sphere(0.05, -1, 8), TEAL_LIGHT, Vector3(0.1, 0.16, -0.05), 0.5)
	return root

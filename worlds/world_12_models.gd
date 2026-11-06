extends RefCounted
## Models for World 12, Toybox Town: springboards, rubber bumpers, the
## wind-up Tin Soldier, the bouncy ball and toy plane re-skins, Bonkers the
## jack-in-the-box and his toy boxes, the toy train and playroom props.
## Built from crisp, slightly rounded clay blocks like render/Models.gd.
## Static helpers only; world_12.gd preloads this script by path.

const RED := Color("#FF5A5F")
const BLUE := Color("#4D96FF")
const YELLOW := Color("#FFD23F")
const GREEN := Color("#5CCB7A")
const ORANGE := Color("#FF9F43")
const PURPLE := Color("#9B7BF0")
const PINK := Color("#FF8FC2")
const NAVY := Color("#2F3B8F")
const SILVER := Color("#E3E6F2")
const STEEL := Color("#9AA2C8")
const SKIN := Color("#FFDCC0")
const CREAM := Color("#FFF6E6")
const INK := Color("#2E2A4A")
const GOLD := Color("#FFC53D")
const RUBBER := Color("#FF4F9A")
## Toy block colours (no blue: blue is for the glass crates).
const BLOCKS: Array[Color] = [RED, YELLOW, GREEN, ORANGE, PURPLE]
const BOSS_SIZE: float = 1.35

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func torus(inner: float, outer: float, segs: int = 20) -> TorusMesh:
	var key := "torus/%.3f/%.3f/%d" % [inner, outer, segs]
	if not _shapes.has(key):
		var t := TorusMesh.new()
		t.inner_radius = inner
		t.outer_radius = outer
		t.rings = segs
		t.ring_segments = 8
		_shapes[key] = t
	return _shapes[key]


## A flat five-point star in the xy plane.
static func star_mesh(size: float, depth: float) -> ArrayMesh:
	var key := "star/%.3f/%.3f" % [size, depth]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = PI * 0.5 + TAU * k / 10.0
			var r: float = size if k % 2 == 0 else size * 0.45
			pts.append(Vector2(cos(a), sin(a)) * r)
		_shapes[key] = ClayShapes.extrusion(pts, depth, depth * 0.3, 1)
	return _shapes[key]


## A crayon lying along +X: a body, a paper wrap and a cone tip.
static func crayon_meshes() -> Array[Mesh]:
	return [Models.cylinder(0.055, 0.055, 0.42, 10), Models.cylinder(0.058, 0.058, 0.2, 10), Models.cylinder(0.0, 0.055, 0.12, 10)]


# --- Tiles ---------------------------------------------------------------------------

## A springboard: an indigo base plate, a silver coil ("Coil") and a red
## top pad with a yellow star ("Pad"). Squash Coil's y and lower Pad to
## make it boing.
static func springboard() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.8, 0.07, 0.8), 0.03), NAVY, Vector3(0, 0.02, 0))
	var coil := Node3D.new()
	coil.name = "Coil"
	coil.position.y = 0.05
	root.add_child(coil)
	for k in 3:
		var ring := Models.part(coil, torus(0.17, 0.23), SILVER, Vector3(0, 0.03 + k * 0.05, 0))
		ring.scale = Vector3(1, 0.7, 1)
	var pad := Node3D.new()
	pad.name = "Pad"
	pad.position.y = 0.2
	root.add_child(pad)
	Models.part(pad, _box(Vector3(0.66, 0.07, 0.66), 0.03), RED, Vector3.ZERO)
	var star := Models.part(pad, star_mesh(0.2, 0.03), YELLOW, Vector3(0, 0.045, 0), 0.25)
	star.rotation.x = -PI * 0.5
	return root


## A rubber bumper laid diagonally over its tile: a low base, two toy posts
## on opposite corners and a fat pink rubber band between them ("Band").
## [param slash] true runs it like "/" (bottom-left to top-right on screen).
static func bumper(slash: bool) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.9, 0.06, 0.9), 0.03), CREAM.darkened(0.06), Vector3(0, 0.02, 0))
	var s: float = 1.0 if slash else -1.0
	for k: int in [-1, 1]:
		var at := Vector3(k * 0.34, 0, -k * 0.34 * s)
		Models.part(root, Models.cylinder(0.12, 0.14, 0.62, 14), BLUE, at + Vector3(0, 0.31, 0))
		Models.part(root, Models.sphere(0.13, 0.16, 14), YELLOW, at + Vector3(0, 0.64, 0))
	var band := Node3D.new()
	band.name = "Band"
	band.position.y = 0.34
	band.rotation.y = PI * 0.25 * s
	root.add_child(band)
	Models.part(band, _box(Vector3(0.86, 0.36, 0.2), 0.09), RUBBER, Vector3.ZERO, 0.15)
	Models.part(band, _box(Vector3(0.7, 0.08, 0.22), 0.03), Color("#FFD0E6"), Vector3(0, 0.0, 0), 0.2)
	return root


## Bonkers' toy box: a striped cube with a hinged "Lid" (rotate x to open),
## a crank on its side and stars on its faces.
static func toy_box(color: Color) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Box"
	root.add_child(body)
	Models.part(body, _box(Vector3(0.86, 0.7, 0.86), 0.08), color, Vector3(0, 0.35, 0))
	Models.part(body, _box(Vector3(0.9, 0.08, 0.9), 0.03), YELLOW, Vector3(0, 0.08, 0))
	Models.part(body, _box(Vector3(0.9, 0.06, 0.9), 0.03), YELLOW, Vector3(0, 0.66, 0))
	var star := Models.part(body, star_mesh(0.17, 0.03), YELLOW, Vector3(0, 0.37, 0.44), 0.2)
	star.rotation.z = 0.1
	var crank := Node3D.new()
	crank.name = "Crank"
	crank.position = Vector3(0.45, 0.4, 0)
	body.add_child(crank)
	var axle := Models.part(crank, Models.cylinder(0.025, 0.025, 0.1, 8), SILVER, Vector3(0.05, 0, 0))
	axle.rotation.z = PI * 0.5
	Models.part(crank, _box(Vector3(0.04, 0.22, 0.05), 0.015), SILVER, Vector3(0.1, -0.09, 0))
	Models.part(crank, Models.sphere(0.045, -1, 10), RED, Vector3(0.14, -0.19, 0))
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.7, -0.43)
	body.add_child(lid)
	Models.part(lid, _box(Vector3(0.88, 0.08, 0.88), 0.035), color.lightened(0.15), Vector3(0, 0.03, 0.43))
	Models.part(lid, Models.sphere(0.06, -1, 10), YELLOW, Vector3(0, 0.09, 0.43))
	return root


# --- Critters ------------------------------------------------------------------------

## The Tin Soldier: a wind-up toy in a red jacket and tall black hat with a
## gold key turning on his back. LegL/LegR and ArmL/ArmR pivot at the top.
static func soldier() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.75, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	for side: int in [-1, 1]:
		var leg := Node3D.new()
		leg.name = "LegL" if side < 0 else "LegR"
		leg.position = Vector3(side * 0.085, 0.25, 0)
		body.add_child(leg)
		Models.part(leg, _box(Vector3(0.12, 0.22, 0.13), 0.035), NAVY, Vector3(0, -0.12, 0))
		Models.part(leg, _box(Vector3(0.13, 0.06, 0.17), 0.025), INK, Vector3(0, -0.22, 0.02))
	Models.part(body, _box(Vector3(0.36, 0.3, 0.27), 0.08), RED, Vector3(0, 0.39, 0))
	Models.part(body, _box(Vector3(0.38, 0.05, 0.29), 0.02), CREAM, Vector3(0, 0.27, 0))
	Models.part(body, _box(Vector3(0.05, 0.05, 0.03), 0.01), GOLD, Vector3(0, 0.27, 0.15), 0.3)
	for k in 2:
		Models.part(body, Models.sphere(0.022, -1, 6), GOLD, Vector3(0, 0.35 + k * 0.08, 0.14), 0.3)
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.215, 0.5, 0)
		body.add_child(arm)
		Models.part(arm, _box(Vector3(0.09, 0.24, 0.1), 0.035), RED, Vector3(0, -0.1, 0))
		Models.part(arm, Models.sphere(0.05, -1, 8), CREAM, Vector3(0, -0.23, 0))
		Models.part(body, _box(Vector3(0.12, 0.04, 0.12), 0.015), GOLD, Vector3(side * 0.2, 0.54, 0), 0.25)
	var head := Models.part(body, Models.sphere(0.15, 0.29, 18), SKIN, Vector3(0, 0.66, 0))
	head.scale = Vector3(1.0, 1.0, 0.95)
	Models._eyes(body, 0.67, 0.12, 0.06, 0.045)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.03, -1, 6), Color("#FF8FA3"), Vector3(side * 0.1, 0.62, 0.12))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	Models.part(body, Models.cylinder(0.13, 0.135, 0.26, 16), INK, Vector3(0, 0.88, -0.01))
	Models.part(body, Models.cylinder(0.14, 0.14, 0.03, 16), INK.lightened(0.15), Vector3(0, 0.76, -0.01))
	Models.part(body, star_mesh(0.045, 0.02), GOLD, Vector3(0, 0.86, 0.125), 0.4)
	Models.part(body, Models.sphere(0.04, -1, 8), RED, Vector3(0.07, 1.02, 0))
	var key := Node3D.new()
	key.name = "Key"
	key.position = Vector3(0, 0.42, -0.14)
	body.add_child(key)
	var stem := Models.part(key, Models.cylinder(0.02, 0.02, 0.12, 8), GOLD, Vector3(0, 0, -0.06), 0.2)
	stem.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		var loop := Models.part(key, torus(0.03, 0.065, 14), GOLD, Vector3(side * 0.07, 0, -0.13), 0.2)
		loop.rotation.z = PI * 0.5
	return root


## A bouncy ball with a cream stripe and a happy face (re-skins Blobbits).
static func ball() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var b := Node3D.new()
	b.name = "Ball"
	b.position.y = 0.32
	body.add_child(b)
	Models.part(b, Models.sphere(0.3, -1, 22), PINK, Vector3.ZERO)
	var band := Models.part(b, Models.cylinder(0.302, 0.302, 0.09, 22), CREAM, Vector3.ZERO)
	band.rotation.z = PI * 0.5
	Models.part(b, Models.sphere(0.07, -1, 8), PINK.lightened(0.4), Vector3(-0.12, 0.17, 0.17))
	Models._eyes(body, 0.38, 0.25, 0.1, 0.065)
	return root


## A little wind-up toy plane with a spinning propeller ("Prop") on its
## nose (re-skins Buzzers).
static func plane() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.25)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, _box(Vector3(0.26, 0.24, 0.6), 0.1), YELLOW, Vector3(0, 0.55, 0))
	Models.part(body, _box(Vector3(0.8, 0.05, 0.22), 0.025), BLUE, Vector3(0, 0.56, 0.02))
	Models.part(body, _box(Vector3(0.34, 0.04, 0.13), 0.02), BLUE, Vector3(0, 0.6, -0.27))
	Models.part(body, _box(Vector3(0.04, 0.16, 0.12), 0.02), RED, Vector3(0, 0.7, -0.26))
	Models._eyes(body, 0.6, 0.27, 0.07, 0.05, true)
	var prop := Node3D.new()
	prop.name = "Prop"
	prop.position = Vector3(0, 0.53, 0.32)
	body.add_child(prop)
	Models.part(prop, Models.sphere(0.04, -1, 8), RED, Vector3.ZERO)
	_no_shadow(Models.part(prop, _box(Vector3(0.36, 0.05, 0.02), 0.012), INK.lightened(0.2), Vector3(0, 0, 0.02)))
	for side: int in [-1, 1]:
		Models.part(body, Models.cylinder(0.05, 0.05, 0.04, 10), INK, Vector3(side * 0.1, 0.36, 0.1)).rotation.z = PI * 0.5
	return root


## Bonkers, the jack-in-the-box: a big round clown face on a silver coil
## ("Coil"), a ruffled collar and a two-pointed jester hat with bells.
## "Head" holds everything above the coil. Bob Body's y to pop him up out
## of a toy box (about -0.95 is tucked inside).
static func jack() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var coil := Node3D.new()
	coil.name = "Coil"
	coil.position.y = 0.55
	body.add_child(coil)
	for k in 6:
		var ring := Models.part(coil, torus(0.16, 0.22), SILVER, Vector3(0, k * 0.075, 0))
		ring.scale = Vector3(1, 0.8, 1)
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.0
	body.add_child(head)
	for k in 10:
		var a: float = TAU * k / 10.0
		var c: Color = CREAM if k % 2 == 0 else PINK
		var ruff := Models.part(head, Models.sphere(0.13, 0.12, 10), c, Vector3(cos(a) * 0.3, 0.04, sin(a) * 0.3))
		ruff.scale = Vector3(1.2, 1.0, 1.2)
	Models.part(head, Models.sphere(0.4, 0.74, 24), CREAM, Vector3(0, 0.4, 0))
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	head.add_child(eyes)
	Models._eyes(eyes, 0.48, 0.32, 0.14, 0.085, true)
	var nose := Models.part(head, Models.sphere(0.085, -1, 14), RED, Vector3(0, 0.37, 0.39), 0.2)
	nose.name = "Nose"
	var mouth := Models.part(head, torus(0.11, 0.15, 18), RED.darkened(0.2), Vector3(0, 0.25, 0.32))
	mouth.rotation.x = PI * 0.5
	mouth.scale = Vector3(1.0, 1.0, 0.5)
	Models.part(head, _box(Vector3(0.28, 0.08, 0.04), 0.02), CREAM, Vector3(0, 0.29, 0.37))
	for side: int in [-1, 1]:
		var cheek := Models.part(head, Models.sphere(0.07, -1, 10), Color("#FF8FA3"), Vector3(side * 0.24, 0.32, 0.29))
		cheek.scale = Vector3(1.0, 0.7, 0.5)
		var hat := Models.part(head, Models.cylinder(0.0, 0.17, 0.5, 12), PURPLE if side < 0 else YELLOW, Vector3(side * 0.18, 0.86, 0))
		hat.rotation.z = side * -0.75
		Models.part(head, Models.sphere(0.07, -1, 10), GOLD if side < 0 else RED, Vector3(side * 0.37, 1.02, 0), 0.4)
	Models.part(head, Models.cylinder(0.3, 0.34, 0.1, 18), PURPLE.lerp(YELLOW, 0.5), Vector3(0, 0.72, 0))
	return root


# --- The toy train ---------------------------------------------------------------------

## The engine, facing +X.
static func engine() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.62, 0.12, 0.34), 0.03), INK, Vector3(0, 0.1, 0))
	Models.part(root, Models.cylinder(0.14, 0.14, 0.38, 14), RED, Vector3(0.08, 0.3, 0)).rotation.z = PI * 0.5
	Models.part(root, _box(Vector3(0.24, 0.34, 0.32), 0.05), BLUE, Vector3(-0.17, 0.35, 0))
	Models.part(root, _box(Vector3(0.3, 0.05, 0.38), 0.02), YELLOW, Vector3(-0.17, 0.54, 0))
	Models.part(root, Models.cylinder(0.05, 0.07, 0.18, 10), INK, Vector3(0.2, 0.52, 0))
	Models.part(root, Models.sphere(0.04, -1, 8), YELLOW, Vector3(0.3, 0.32, 0), 1.0)
	_wheels(root)
	return root


## A wagon carrying a couple of toy blocks, facing +X.
static func wagon(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var c: Color = BLOCKS[r.randi() % BLOCKS.size()]
	Models.part(root, _box(Vector3(0.48, 0.2, 0.32), 0.04), c, Vector3(0, 0.2, 0))
	for k in 2:
		var bc: Color = BLOCKS[(r.randi() + k) % BLOCKS.size()]
		var blk := Models.part(root, _box(Vector3(0.15, 0.15, 0.15), 0.03), bc, Vector3(-0.1 + k * 0.2, 0.36, 0))
		blk.rotation.y = r.randf_range(-0.4, 0.4)
	_wheels(root)
	return root


static func _wheels(root: Node3D) -> void:
	for x: float in [-0.16, 0.16]:
		for z: float in [-0.17, 0.17]:
			var w := Models.part(root, Models.cylinder(0.07, 0.07, 0.04, 12), INK.lightened(0.15), Vector3(x, 0.07, z))
			w.rotation.x = PI * 0.5


# --- Props -------------------------------------------------------------------------------

## A stack of toy blocks, turned a little each.
static func block_stack(r: RandomNumberGenerator, size: float = 1.0, count: int = 3) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9 * size, 0.25)
	var y: float = 0.0
	var s: float = 0.42 * size
	for k in count:
		var c: Color = BLOCKS[r.randi() % BLOCKS.size()]
		var blk := Models.part(root, _box(Vector3(s, s, s), s * 0.12), c, Vector3(r.randf_range(-0.04, 0.04), y + s * 0.5, r.randf_range(-0.04, 0.04)))
		blk.rotation.y = r.randf_range(-0.5, 0.5)
		var face := Models.part(root, star_mesh(s * 0.28, 0.02), CREAM, blk.position + Basis(Vector3.UP, blk.rotation.y) * Vector3(0, 0, s * 0.5 + 0.005))
		face.rotation.y = blk.rotation.y
		y += s
		s *= 0.82
	return root


## A ring-stacker toy: a cone of coloured rings on a pole.
static func ring_stacker(size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8 * size, 0.25)
	Models.part(root, Models.cylinder(0.24 * size, 0.26 * size, 0.08 * size, 16), BLUE, Vector3(0, 0.04 * size, 0))
	Models.part(root, Models.cylinder(0.035 * size, 0.035 * size, 0.6 * size, 8), CREAM, Vector3(0, 0.36 * size, 0))
	var cols: Array[Color] = [RED, ORANGE, YELLOW, GREEN]
	for k in 4:
		var rr: float = (0.22 - k * 0.035) * size
		var ring := Models.part(root, torus(rr * 0.35, rr), cols[k], Vector3(0, (0.13 + k * 0.1) * size, 0))
		ring.scale = Vector3(1, 1.3, 1)
	Models.part(root, Models.sphere(0.07 * size, -1, 10), PURPLE, Vector3(0, 0.66 * size, 0))
	return root


## A crayon standing in a little cup of crayons.
static func crayon_cup(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.6, 0.25)
	Models.part(root, Models.cylinder(0.16, 0.14, 0.3, 14), CREAM.darkened(0.05), Vector3(0, 0.15, 0))
	var m: Array[Mesh] = crayon_meshes()
	for k in 3:
		var c: Color = BLOCKS[(r.randi() + k) % BLOCKS.size()]
		var holder := Node3D.new()
		holder.position = Vector3(-0.06 + k * 0.06, 0.32, r.randf_range(-0.04, 0.04))
		holder.rotation.z = (k - 1) * 0.18
		root.add_child(holder)
		Models.part(holder, m[0], c, Vector3(0, 0.1, 0))
		Models.part(holder, m[2], c, Vector3(0, 0.37, 0))
	return root


## A rubber duck.
static func duck(size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.blob_shadow(root, 0.7, 0.25)
	var b := Models.part(root, Models.sphere(0.25, 0.36, 16), YELLOW, Vector3(0, 0.18, 0))
	b.scale = Vector3(1.0, 1.0, 1.25)
	Models.part(root, Models.sphere(0.16, -1, 14), YELLOW, Vector3(0, 0.44, 0.12))
	var beak := Models.part(root, _box(Vector3(0.14, 0.05, 0.12), 0.02), ORANGE, Vector3(0, 0.42, 0.28))
	beak.rotation.x = 0.1
	Models._eyes(root, 0.49, 0.24, 0.07, 0.035)
	return root

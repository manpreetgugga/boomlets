extends RefCounted
## Models for World 13, Rhythm Cloudway: beat tiles and cloud holes, drum
## pads, the Thumper drum critter, the note-blob and songbird re-skins,
## Maestro the conductor bird, drum pillars and sky props. Crisp, slightly
## rounded clay shapes like render/Models.gd. Static helpers only;
## world_13.gd preloads this script by path.

const PINK := Color("#FF7FAA")
const BLUE := Color("#3ED8F7")
const HOLE := Color("#3F3A8E")
const HOLE_IN := Color("#5049A8")
const CREAM := Color("#FFF8EC")
const INK := Color("#2E2A4A")
const GOLD := Color("#FFC53D")
const NAVY := Color("#33408F")
const COAT := Color("#5266D9")
const RED := Color("#FF5D6C")
const ORANGE := Color("#FFA14A")
const PURPLE := Color("#8C72F0")
const MINT := Color("#62D9A8")
const WHITE := Color("#FFFFFF")
const SET_COLORS: Array[Color] = [PINK, BLUE]
## Drum shell colours for pillars and critters.
const SHELLS: Array[Color] = [RED, ORANGE, PURPLE, MINT, Color("#FF8FC2")]
const BOSS_SIZE: float = 1.5

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


## An eighth note: a round head, a stem and a little flag, standing on the
## origin, about [param size] tall.
static func note(parent: Node3D, color: Color, size: float, glow: float = 0.0) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var k: float = size
	var head := Models.part(n, Models.sphere(0.2 * k, -1, 14), color, Vector3(0, 0.17 * k, 0), glow)
	head.scale = Vector3(1.25, 0.85, 0.9)
	head.rotation.z = 0.35
	Models.part(n, Models.cylinder(0.035 * k, 0.035 * k, 0.75 * k, 8), color, Vector3(0.2 * k, 0.55 * k, 0), glow)
	var flag := Models.part(n, _box(Vector3(0.24 * k, 0.09 * k, 0.07 * k), 0.03 * k), color, Vector3(0.3 * k, 0.83 * k, 0), glow)
	flag.rotation.z = -0.6
	return n


# --- Tiles ---------------------------------------------------------------------------

## A beat tile: "Plat" is the cloud-candy platform (scaled away when the
## tile is off), "Ghost" its outline left on the hole, which pulses in the
## count-in before it comes back.
static func beat_tile(set_index: int) -> Node3D:
	var root := Node3D.new()
	var col: Color = SET_COLORS[set_index]
	var plat := Node3D.new()
	plat.name = "Plat"
	root.add_child(plat)
	Models.part(plat, _box(Vector3(0.92, 0.24, 0.92), 0.08), col, Vector3(0, 0.0, 0))
	Models.part(plat, _box(Vector3(0.74, 0.04, 0.74), 0.02), col.lightened(0.3), Vector3(0, 0.13, 0))
	if set_index == 0:
		# Pink: a round note dot. Blue: a diamond, so the sets differ by
		# shape as well as colour.
		var dot := Models.part(plat, Models.cylinder(0.17, 0.17, 0.05, 20), CREAM, Vector3(0, 0.155, 0))
		dot.scale = Vector3(1, 1, 1)
	else:
		var dia := Models.part(plat, _box(Vector3(0.26, 0.05, 0.26), 0.03), CREAM, Vector3(0, 0.155, 0))
		dia.rotation.y = PI * 0.25
	var ghost := Node3D.new()
	ghost.name = "Ghost"
	root.add_child(ghost)
	for k in 4:
		var bar := Models.part(ghost, _box(Vector3(0.84, 0.03, 0.07), 0.015), col, Vector3(0, 0.0, 0), 0.6)
		bar.position = Vector3(0, 0.0, 0.0)
		var a: float = PI * 0.5 * k
		bar.position = Vector3(sin(a) * 0.4, 0.005, cos(a) * 0.4)
		bar.rotation.y = a
		_no_shadow(bar)
	return root


## A floor drum: a short shell, a cream skin ("Skin") and gold rims.
static func drum_pad() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.4, 0.4, 0.16, 28), PURPLE, Vector3(0, 0.07, 0))
	for k in 8:
		var a: float = TAU * k / 8.0
		var lug := Models.part(root, _box(Vector3(0.05, 0.1, 0.05), 0.015), GOLD, Vector3(cos(a) * 0.405, 0.08, sin(a) * 0.405), 0.2)
		lug.rotation.y = -a
	var skin := Node3D.new()
	skin.name = "Skin"
	skin.position.y = 0.155
	root.add_child(skin)
	Models.part(skin, Models.cylinder(0.37, 0.37, 0.03, 28), CREAM)
	Models.part(skin, Models.cylinder(0.25, 0.25, 0.01, 24), RED, Vector3(0, 0.017, 0))
	Models.part(skin, Models.cylinder(0.13, 0.13, 0.01, 20), CREAM, Vector3(0, 0.022, 0))
	Models.part(skin, Models.cylinder(0.05, 0.05, 0.01, 12), RED, Vector3(0, 0.027, 0))
	var rim := Models.part(root, torus(0.36, 0.42, 28), GOLD, Vector3(0, 0.16, 0), 0.15)
	rim.scale = Vector3(1, 0.5, 1)
	return root


# --- Critters ------------------------------------------------------------------------

## Thumper: a snare drum on little feet that holds two drumsticks and hops
## on the beat.
static func thumper(shell: Color) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.13, 0.08, 0.17), 0.035), INK, Vector3(side * 0.12, 0.04, 0.02))
	Models.part(body, Models.cylinder(0.3, 0.3, 0.36, 24), shell, Vector3(0, 0.3, 0))
	for y: float in [0.13, 0.47]:
		var rim := Models.part(body, torus(0.28, 0.32, 24), GOLD, Vector3(0, y, 0), 0.15)
		rim.scale = Vector3(1, 0.6, 1)
	# Zigzag cord round the shell.
	for k in 10:
		var a: float = TAU * k / 10.0
		var cord := Models.part(body, _box(Vector3(0.03, 0.32, 0.03), 0.01), CREAM, Vector3(cos(a) * 0.305, 0.3, sin(a) * 0.305))
		cord.rotation = Vector3(0, -a, 0.35 if k % 2 == 0 else -0.35)
	Models.part(body, Models.cylinder(0.29, 0.29, 0.03, 24), shell.lightened(0.55), Vector3(0, 0.49, 0))
	Models.part(body, Models.cylinder(0.1, 0.1, 0.01, 16), shell, Vector3(0, 0.505, 0))
	Models._eyes(body, 0.33, 0.27, 0.1, 0.075)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.04, -1, 8), Color("#FFB3C7"), Vector3(side * 0.19, 0.25, 0.24))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	for side: int in [-1, 1]:
		var stick := Node3D.new()
		stick.name = "StickL" if side < 0 else "StickR"
		stick.position = Vector3(side * 0.31, 0.32, 0.02)
		body.add_child(stick)
		var s := Models.part(stick, Models.cylinder(0.02, 0.025, 0.42, 8), Color("#F5D29B"), Vector3(0, 0.17, 0.0))
		s.rotation.x = 0.0
		Models.part(stick, Models.sphere(0.04, -1, 8), Color("#F5D29B"), Vector3(0, 0.38, 0))
		Models.part(stick, Models.sphere(0.06, -1, 8), shell.lightened(0.2), Vector3(0, 0.0, 0))
		stick.rotation.z = side * -0.5
	return root


## The blobbit of this world: a round note with a face and a bouncy stem.
static func note_blob() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var col := PURPLE
	var head := Models.part(body, Models.sphere(0.27, -1, 20), col, Vector3(0, 0.27, 0))
	head.scale = Vector3(1.15, 0.92, 1.0)
	var stem := Node3D.new()
	stem.name = "Stem"
	stem.position = Vector3(0.24, 0.32, -0.04)
	body.add_child(stem)
	Models.part(stem, Models.cylinder(0.04, 0.045, 0.6, 8), col, Vector3(0, 0.3, 0))
	var flag := Models.part(stem, _box(Vector3(0.26, 0.1, 0.08), 0.035), col, Vector3(0.1, 0.55, 0))
	flag.rotation.z = -0.65
	Models._eyes(body, 0.3, 0.23, 0.1, 0.075)
	Models.part(body, Models.sphere(0.03, -1, 8), Color("#FFB3C7"), Vector3(0, 0.2, 0.26))
	return root


## The buzzer of this world: a round songbird with flapping wings.
static func songbird() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7, 0.25)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var fly := Node3D.new()
	fly.name = "Fly"
	fly.position.y = 0.55
	body.add_child(fly)
	var col := Color("#FFC94A")
	var b := Models.part(fly, Models.sphere(0.24, -1, 18), col)
	b.scale = Vector3(1.0, 0.95, 1.1)
	Models.part(fly, Models.sphere(0.15, -1, 14), CREAM, Vector3(0, -0.06, 0.12))
	var beak := Models.part(fly, Models.cylinder(0.0, 0.06, 0.13, 10), ORANGE, Vector3(0, 0.02, 0.27))
	beak.rotation.x = PI * 0.5
	Models._eyes(fly, 0.07, 0.19, 0.09, 0.06, true)
	for side: int in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.2, 0.04, 0)
		fly.add_child(wing)
		var w := Models.part(wing, _box(Vector3(0.28, 0.05, 0.2), 0.025), col.darkened(0.08), Vector3(side * 0.13, 0, 0))
		w.rotation.z = side * 0.1
	var tail := Models.part(fly, _box(Vector3(0.14, 0.04, 0.16), 0.02), col.darkened(0.1), Vector3(0, 0.08, -0.25))
	tail.rotation.x = -0.5
	note(fly, INK, 0.25).position = Vector3(0, 0.22, -0.02)
	return root


## Maestro, the conductor bird: a plump navy bird in a tailcoat with a
## white shirt front, a red bow tie, a crest and a baton in his right wing.
static func maestro() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.3, 0.4)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.14, 0.06, 0.2), 0.03), ORANGE, Vector3(side * 0.13, 0.03, 0.04))
	var torso := Models.part(body, Models.sphere(0.4, -1, 24), COAT, Vector3(0, 0.45, 0))
	torso.scale = Vector3(1.0, 1.05, 0.95)
	var shirt := Models.part(body, Models.sphere(0.27, -1, 20), CREAM, Vector3(0, 0.42, 0.17))
	shirt.scale = Vector3(1.0, 1.2, 0.7)
	for k in 3:
		Models.part(body, Models.sphere(0.025, -1, 8), INK, Vector3(0, 0.3 + k * 0.08, 0.36))
	for side: int in [-1, 1]:
		var bow := Models.part(body, Models.cylinder(0.0, 0.08, 0.12, 4), RED, Vector3(side * 0.065, 0.62, 0.33))
		bow.rotation.z = side * PI * 0.5
	Models.part(body, Models.sphere(0.035, -1, 8), RED, Vector3(0, 0.62, 0.35))
	# Coat tails at the back.
	for side: int in [-1, 1]:
		var tail := Models.part(body, _box(Vector3(0.14, 0.32, 0.06), 0.03), COAT.darkened(0.15), Vector3(side * 0.09, 0.2, -0.36))
		tail.rotation.x = 0.35
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.88, 0.02)
	body.add_child(head)
	Models.part(head, Models.sphere(0.27, -1, 20), COAT)
	Models.part(head, Models.sphere(0.17, -1, 16), CREAM, Vector3(0, -0.06, 0.15)).scale = Vector3(1.2, 0.9, 0.7)
	var beak := Models.part(head, Models.cylinder(0.0, 0.08, 0.2, 10), ORANGE, Vector3(0, -0.02, 0.33))
	beak.rotation.x = PI * 0.5
	Models._eyes(head, 0.06, 0.2, 0.11, 0.075, true)
	for k in 3:
		var f := Models.part(head, _box(Vector3(0.06, 0.22, 0.05), 0.025), PURPLE, Vector3((k - 1) * 0.07, 0.3, -0.04 - abs(k - 1) * 0.03))
		f.rotation.z = (k - 1) * -0.35
	for side: int in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.37, 0.55, 0)
		body.add_child(wing)
		var w := Models.part(wing, _box(Vector3(0.14, 0.38, 0.26), 0.06), COAT.lightened(0.08), Vector3(0, -0.15, 0))
		w.rotation.z = side * 0.2
		Models.part(wing, Models.sphere(0.07, -1, 10), WHITE, Vector3(side * 0.04, -0.34, 0.04))
		if side > 0:
			var baton := Node3D.new()
			baton.name = "Baton"
			baton.position = Vector3(0.04, -0.34, 0.08)
			wing.add_child(baton)
			var stick := Models.part(baton, Models.cylinder(0.012, 0.022, 0.6, 8), WHITE, Vector3(0, 0.3, 0), 0.4)
			stick.rotation.x = 0.0
			Models.part(baton, Models.sphere(0.035, -1, 8), GOLD, Vector3(0, 0.0, 0), 0.3)
			baton.rotation.x = 0.9
	return root


# --- Props ----------------------------------------------------------------------------

## A cloud puff: a few overlapping spheres.
static func cloud(parent: Node3D, size: float, r: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	parent.add_child(n)
	var lumps: int = 4 + r.randi() % 3
	for k in lumps:
		var a: float = TAU * k / lumps + r.randf_range(-0.3, 0.3)
		var rr: float = size * r.randf_range(0.28, 0.42)
		var s := Models.part(n, Models.sphere(rr, -1, 14), WHITE.lerp(Color("#E8ECFF"), r.randf() * 0.5),
			Vector3(cos(a) * size * 0.35, rr * 0.7, sin(a) * size * 0.3))
		s.scale = Vector3(1.0, 0.8, 1.0)
	Models.part(n, Models.sphere(size * 0.45, -1, 16), WHITE, Vector3(0, size * 0.4, 0)).scale = Vector3(1.0, 0.85, 1.0)
	return n


## A drum kit on a cloud for the far islands.
static func drum_kit(size: float) -> Node3D:
	var root := Node3D.new()
	var k: float = size
	var bass := Models.part(root, Models.cylinder(0.45 * k, 0.45 * k, 0.4 * k, 24), RED, Vector3(0, 0.45 * k, 0))
	bass.rotation.x = PI * 0.5
	var skin := Models.part(root, Models.cylinder(0.4 * k, 0.4 * k, 0.03 * k, 24), CREAM, Vector3(0, 0.45 * k, 0.21 * k))
	skin.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		Models.part(root, Models.cylinder(0.22 * k, 0.22 * k, 0.2 * k, 20), ORANGE, Vector3(side * 0.42 * k, 0.75 * k, 0.1 * k))
		Models.part(root, Models.cylinder(0.02 * k, 0.02 * k, 1.0 * k, 6), Color("#C9CEE6"), Vector3(side * 0.7 * k, 0.5 * k, -0.2 * k))
		var cym := Models.part(root, Models.cylinder(0.02 * k, 0.32 * k, 0.04 * k, 20), GOLD, Vector3(side * 0.7 * k, 1.0 * k, -0.2 * k), 0.2)
		cym.rotation.z = side * 0.2
	return root

extends RefCounted
## Models for World 16, Inkwell Library: heavy book stacks Pip can shove,
## bookmark pressure plates, the shelf-doors they open, the ink reset pad,
## the Bookworm (a bespectacled worm that tunnels under book stacks),
## Professor Inkle the ink-octopus librarian and the cosy library props.
## Built from crisp, slightly rounded clay blocks like render/Models.gd.

const INK := Color("#2B3A78")
const INK_DEEP := Color("#1E2A5C")
const INK_LIGHT := Color("#5D78D6")
const PARCHMENT := Color("#F6E7C8")
const PAGES := Color("#FFF6E2")
const WOOD := Color("#8A5634")
const WOOD_DARK := Color("#6A3F25")
const WOOD_LIGHT := Color("#B57A4A")
const BRASS := Color("#E8B64C")
const LAMP_GLOW := Color("#FFE3A0")
const LAMP_GREEN := Color("#3E9A6E")
const RIBBON_A := Color("#E8475B")     # bookmark group A (red)
const RIBBON_B := Color("#36B37E")     # bookmark group B (green)
const WORM := Color("#9BDB6A")
const WORM_DARK := Color("#74C24E")
const WORM_BELLY := Color("#FFE9A8")
const OCTO := Color("#5A63C9")
const OCTO_DARK := Color("#434BA8")
const OCTO_BELLY := Color("#B9C2FF")
## Book cover colours, cheerful but a touch dusty.
const COVERS: Array[Color] = [Color("#E05A5A"), Color("#4E7FD9"), Color("#3FAE84"), Color("#F2B13D"), Color("#9A6AD6"), Color("#E9845A")]
const BOSS_SIZE: float = 1.3
const WORM_SIZE: float = 1.0

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A flat chevron arrow lying in the xz plane (pointing +X).
static func chevron() -> ArrayMesh:
	var key := "chev"
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(-0.1, 0.13), Vector2(0.0, 0.13), Vector2(0.11, 0.0), Vector2(0.0, -0.13), Vector2(-0.1, -0.13), Vector2(0.01, 0.0)])
		_shapes[key] = ClayShapes.extrusion(pts, 0.03, 0.01, 1)
	return _shapes[key]


## A ribbon bookmark strip with a swallow-tail end, in the xy plane.
static func ribbon_mesh(length: float, width: float) -> ArrayMesh:
	var key := "ribbon/%.2f/%.2f" % [length, width]
	if not _shapes.has(key):
		var h: float = width * 0.5
		var pts := PackedVector2Array([Vector2(-length * 0.5, -h), Vector2(length * 0.5, -h), Vector2(length * 0.5 - width * 0.6, 0.0), Vector2(length * 0.5, h), Vector2(-length * 0.5, h)])
		_shapes[key] = ClayShapes.extrusion(pts, 0.03, 0.01, 1)
	return _shapes[key]


# --- Book stacks, plates, doors, the reset pad ---------------------------------

## One chunky book lying flat: cover, cream page block and a spine band.
static func _book(parent: Node3D, size: Vector3, cover: Color, pos: Vector3, yaw: float) -> Node3D:
	var b := Node3D.new()
	b.position = pos
	b.rotation.y = yaw
	parent.add_child(b)
	Models.part(b, _box(size, 0.035), cover)
	# Page block showing on three sides (inset from the covers).
	Models.part(b, _box(Vector3(size.x - 0.06, size.y - 0.07, size.z - 0.03), 0.02), PAGES, Vector3(0.04, 0, 0))
	# Spine bands on the left edge.
	for s: float in [-0.25, 0.25]:
		Models.part(b, _box(Vector3(0.03, size.y + 0.012, 0.05), 0.01), BRASS, Vector3(-size.x * 0.5 + 0.02, 0, s * size.z))
	return b


## A heavy stack of three or four big books ("Body"), some askew, with a
## ribbon hanging out of the top one. About 0.72 tall.
static func book_stack(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.05, 0.4)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var y: float = 0.0
	var n: int = 3 if r.randf() < 0.6 else 4
	var first: int = r.randi() % COVERS.size()
	for k in n:
		var h: float = r.randf_range(0.15, 0.2) if n == 4 else r.randf_range(0.2, 0.25)
		var w: float = 0.86 - k * 0.05 + r.randf_range(-0.03, 0.03)
		var d: float = 0.74 - k * 0.04 + r.randf_range(-0.03, 0.03)
		var yaw: float = r.randf_range(-0.16, 0.16) + (PI if k % 2 == 1 else 0.0)
		_book(body, Vector3(w, h, d), COVERS[(first + k * 2) % COVERS.size()], Vector3(r.randf_range(-0.03, 0.03), y + h * 0.5, r.randf_range(-0.03, 0.03)), yaw)
		y += h
	# A ribbon bookmark draped over the front of the top book.
	var rib := _no_shadow(Models.part(body, _box(Vector3(0.07, 0.02, 0.36), 0.008), RIBBON_A.lightened(0.1), Vector3(0.15, y + 0.005, 0.18)))
	rib.rotation.y = 0.2
	var tail := _no_shadow(Models.part(body, _box(Vector3(0.07, 0.16, 0.02), 0.008), RIBBON_A.lightened(0.1), Vector3(0.19, y - 0.07, 0.37)))
	tail.rotation.y = 0.2
	return root


## A bookmark pressure plate: a brass-rimmed slot in the floor with a
## ribbon bookmark lying across it ("Ribbon"; it glows while pressed).
static func plate(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.8, 0.05, 0.8), 0.03), BRASS.darkened(0.15), Vector3(0, 0.02, 0))
	Models.part(root, _box(Vector3(0.66, 0.05, 0.66), 0.025), WOOD_DARK, Vector3(0, 0.035, 0))
	var rib := Node3D.new()
	rib.name = "Ribbon"
	rib.position.y = 0.07
	root.add_child(rib)
	var strip := _no_shadow(Models.part(rib, ribbon_mesh(0.62, 0.2), color, Vector3.ZERO, 0.35))
	strip.rotation.x = -PI * 0.5
	strip.rotation.y = PI * 0.25
	var lit := _no_shadow(Models.part(rib, ribbon_mesh(0.62, 0.2), color.lightened(0.35), Vector3(0, 0.005, 0), 1.6))
	lit.rotation.x = -PI * 0.5
	lit.rotation.y = PI * 0.25
	lit.name = "Lit"
	lit.visible = false
	# Little corner studs.
	for sx: float in [-0.32, 0.32]:
		for sz: float in [-0.32, 0.32]:
			Models.part(root, Models.sphere(0.03, -1, 6), BRASS, Vector3(sx, 0.06, sz))
	return root


## A shelf-door: a bookcase block ("Shelf") with a ribbon-coloured crest that
## sinks into the floor when its bookmarks are all pressed.
static func door(color: Color, r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	# The slot in the floor it sinks into.
	Models.part(root, _box(Vector3(0.9, 0.04, 0.9), 0.02), WOOD_DARK.darkened(0.2), Vector3(0, 0.01, 0))
	var shelf := Node3D.new()
	shelf.name = "Shelf"
	root.add_child(shelf)
	Models.part(shelf, _box(Vector3(0.86, 0.8, 0.86), 0.06), WOOD, Vector3(0, 0.4, 0))
	Models.part(shelf, _box(Vector3(0.92, 0.08, 0.92), 0.03), color, Vector3(0, 0.83, 0), 0.25)
	# Books on two shelves, front and back.
	for side: int in [-1, 1]:
		for row in 2:
			var x: float = -0.32
			while x < 0.3:
				var w: float = r.randf_range(0.08, 0.12)
				var h: float = r.randf_range(0.22, 0.28)
				Models.part(shelf, _box(Vector3(w, h, 0.08), 0.015), COVERS[r.randi() % COVERS.size()], Vector3(x + w * 0.5, 0.06 + row * 0.38 + h * 0.5, side * 0.41))
				x += w + 0.015
	# A crest on the front so it reads as a door of that colour.
	var crest := _no_shadow(Models.part(shelf, Models.cylinder(0.14, 0.14, 0.04, 16), color, Vector3(0, 0.62, 0.45), 0.5))
	crest.rotation.x = PI * 0.5
	_no_shadow(Models.part(shelf, Models.cylinder(0.06, 0.06, 0.05, 10), PAGES, Vector3(0, 0.62, 0.46), 0.3)).rotation.x = PI * 0.5
	var top := _no_shadow(Models.part(shelf, ribbon_mesh(0.5, 0.16), color.lightened(0.2), Vector3(0, 0.88, 0), 0.6))
	top.rotation.x = -PI * 0.5
	return root


## The ink reset pad: a round parchment pad with an ink pool in the middle and
## three arrows chasing round it ("Spin"); it glows when stacks have moved.
static func reset_pad() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.42, 0.44, 0.05, 28), BRASS.darkened(0.1), Vector3(0, 0.02, 0))
	Models.part(root, Models.cylinder(0.37, 0.37, 0.05, 28), PARCHMENT, Vector3(0, 0.04, 0))
	var pool := _no_shadow(Models.part(root, Models.cylinder(0.17, 0.17, 0.03, 20), INK, Vector3(0, 0.06, 0), 0.2))
	pool.name = "Pool"
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	for k in 3:
		var a: float = TAU * k / 3.0
		var ch := _no_shadow(Models.part(spin, chevron(), INK_LIGHT, Vector3(cos(a) * 0.27, 0.075, sin(a) * 0.27), 0.5))
		ch.rotation = Vector3(-PI * 0.5, -a - PI * 0.5, 0)
	# A tiny quill standing in the ink.
	var quill := Node3D.new()
	quill.name = "Quill"
	quill.position = Vector3(0, 0.07, 0)
	quill.rotation.z = -0.35
	root.add_child(quill)
	Models.part(quill, Models.cylinder(0.012, 0.012, 0.36, 6), PAGES, Vector3(0, 0.18, 0))
	var feather := Models.part(quill, Models.sphere(0.06, 0.32, 10), Color("#FFFFFF"), Vector3(0.03, 0.27, 0))
	feather.scale = Vector3(0.6, 1.0, 0.25)
	return root


# --- Critters --------------------------------------------------------------------

## The Bookworm: four round green segments ("Seg1".."Seg3" behind the head),
## a head ("Head") with big round spectacles and a tiny scholar's cap.
static func bookworm() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * WORM_SIZE
	root.add_child(body)
	for k in range(3, 0, -1):
		var seg := Node3D.new()
		seg.name = "Seg%d" % k
		seg.position = Vector3(0, 0.15, -0.17 * k + 0.02)
		body.add_child(seg)
		var s: float = 0.15 - k * 0.012
		Models.part(seg, Models.sphere(s, s * 1.9, 14), WORM if k % 2 == 1 else WORM_DARK, Vector3.ZERO)
		Models.part(seg, Models.sphere(s * 0.7, s * 1.0, 10), WORM_BELLY, Vector3(0, -s * 0.45, 0.02))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.25, 0.1)
	body.add_child(head)
	Models.part(head, Models.sphere(0.2, 0.38, 18), WORM, Vector3.ZERO)
	# Big glasses: brass rims, glass, eyes behind.
	for side: int in [-1, 1]:
		var rim := Models.part(head, Models.cylinder(0.085, 0.085, 0.03, 16), BRASS, Vector3(side * 0.085, 0.04, 0.17))
		rim.rotation.x = PI * 0.5
		_no_shadow(Models.part(head, Models.cylinder(0.068, 0.068, 0.034, 16), Color("#E8F4FF"), Vector3(side * 0.085, 0.04, 0.172))).rotation.x = PI * 0.5
		Models.part(head, Models.sphere(0.035, -1, 10), Models.INK, Vector3(side * 0.08, 0.035, 0.19))
		_no_shadow(Models.part(head, Models.sphere(0.012, -1, 6), Color.WHITE, Vector3(side * 0.08 + 0.012, 0.05, 0.205), 1.0))
	Models.part(head, _box(Vector3(0.05, 0.016, 0.016), 0.005), BRASS, Vector3(0, 0.045, 0.19))
	var smile := Models.part(head, _box(Vector3(0.08, 0.02, 0.02), 0.008), Models.INK, Vector3(0, -0.07, 0.18))
	smile.rotation.x = -0.3
	for side: int in [-1, 1]:
		var cheek := Models.part(head, Models.sphere(0.03, -1, 8), Color("#FF9AA8"), Vector3(side * 0.13, -0.04, 0.14))
		cheek.scale = Vector3(1, 0.6, 0.5)
	# Mortarboard cap with a tassel.
	var cap := Node3D.new()
	cap.name = "Cap"
	cap.position = Vector3(0, 0.17, -0.01)
	cap.rotation.x = -0.15
	head.add_child(cap)
	Models.part(cap, Models.cylinder(0.08, 0.1, 0.06, 12), INK_DEEP, Vector3(0, 0.0, 0))
	Models.part(cap, _box(Vector3(0.26, 0.025, 0.26), 0.008), INK_DEEP, Vector3(0, 0.04, 0)).rotation.y = PI * 0.25
	Models.part(cap, Models.cylinder(0.008, 0.008, 0.1, 4), BRASS, Vector3(0.1, 0.0, 0.06))
	Models.part(cap, Models.sphere(0.022, -1, 6), BRASS, Vector3(0.1, -0.06, 0.06))
	return root


## Professor Inkle, the boss: a big round ink-blue octopus librarian with
## spectacles, a bun skewered with a quill, a lace collar, an open book in her
## front tentacles ("Book") and six curling tentacles ("Tent0".."Tent5").
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	# Tentacles: chains of shrinking spheres curling outward.
	for k in 6:
		var a: float = TAU * (k + 0.5) / 6.0
		var t := Node3D.new()
		t.name = "Tent%d" % k
		t.position = Vector3(cos(a) * 0.32, 0.18, sin(a) * 0.32)
		t.rotation.y = -a
		body.add_child(t)
		for i in 4:
			var s: float = 0.13 - i * 0.022
			Models.part(t, Models.sphere(s, s * 1.7, 12), OCTO if i % 2 == 0 else OCTO_DARK, Vector3(0.12 + i * 0.13, -0.08 - i * 0.012 + (0.05 if i == 3 else 0.0), 0))
			if i < 3:
				_no_shadow(Models.part(t, Models.sphere(s * 0.35, -1, 6), OCTO_BELLY, Vector3(0.12 + i * 0.13, -0.12 - i * 0.01, s * 0.6)))
	# The mantle (head-body).
	var mantle := Models.part(body, Models.sphere(0.56, 1.1, 26), OCTO, Vector3(0, 0.72, 0))
	mantle.scale = Vector3(1.0, 1.0, 0.95)
	Models.part(body, Models.sphere(0.4, 0.5, 18), OCTO_BELLY, Vector3(0, 0.46, 0.22)).scale = Vector3(1.0, 1.0, 0.7)
	# Spots.
	for p: Vector3 in [Vector3(-0.3, 1.02, 0.25), Vector3(0.34, 0.95, 0.22), Vector3(0.1, 1.2, -0.1), Vector3(-0.15, 1.15, -0.3)]:
		var sp := Models.part(body, Models.sphere(0.06, -1, 8), OCTO_DARK, p)
		sp.scale = Vector3(1, 0.7, 1)
	# Lace collar.
	for k in 9:
		var a2: float = PI * (0.1 + 0.8 * k / 8.0)
		Models.part(body, Models.sphere(0.07, 0.06, 8), PAGES, Vector3(cos(a2) * 0.42, 0.42, sin(a2) * 0.3 + 0.1))
	# Face: big eyes behind spectacles.
	for side: int in [-1, 1]:
		var eye := Models.part(body, Models.sphere(0.12, 0.26, 14), Models.WHITE, Vector3(side * 0.18, 0.82, 0.46))
		eye.scale = Vector3(1, 1, 0.6)
		var pupil := Models.part(body, Models.sphere(0.06, -1, 10), Models.INK, Vector3(side * 0.18, 0.8, 0.53))
		pupil.name = "PupilL" if side < 0 else "PupilR"
		var rim := Models.part(body, Models.cylinder(0.15, 0.15, 0.03, 18), BRASS, Vector3(side * 0.18, 0.82, 0.52))
		rim.rotation.x = PI * 0.5
		rim.scale = Vector3(1, 1, 1)
		_no_shadow(Models.part(body, Models.cylinder(0.125, 0.125, 0.032, 18), Color(0.85, 0.95, 1.0), Vector3(side * 0.18, 0.82, 0.525), 0.15)).rotation.x = PI * 0.5
	Models.part(body, _box(Vector3(0.08, 0.025, 0.025), 0.008), BRASS, Vector3(0, 0.84, 0.53))
	# Chain hanging from the spectacles.
	for k in 4:
		Models.part(body, Models.sphere(0.014, -1, 4), BRASS, Vector3(0.33 + k * 0.01, 0.74 - k * 0.07, 0.43 - k * 0.02))
	var smile := Models.part(body, _box(Vector3(0.16, 0.035, 0.03), 0.012), OCTO_DARK.darkened(0.4), Vector3(0, 0.6, 0.52))
	smile.rotation.x = -0.2
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.05, -1, 8), Color("#FF9AC0"), Vector3(side * 0.34, 0.66, 0.42))
		cheek.scale = Vector3(1, 0.6, 0.5)
	# A bun on top with a quill through it.
	var bun := Models.part(body, Models.sphere(0.18, 0.3, 14), OCTO_DARK, Vector3(0, 1.3, -0.06))
	bun.name = "Bun"
	var quill := Node3D.new()
	quill.name = "Quill"
	quill.position = Vector3(0, 1.33, -0.06)
	quill.rotation.z = 0.9
	body.add_child(quill)
	Models.part(quill, Models.cylinder(0.014, 0.014, 0.6, 6), PAGES, Vector3(0, 0.0, 0))
	var feather := Models.part(quill, Models.sphere(0.08, 0.42, 10), Color("#FFFFFF"), Vector3(0.03, 0.2, 0))
	feather.scale = Vector3(0.6, 1.0, 0.25)
	# The open book held in front.
	var book := Node3D.new()
	book.name = "Book"
	book.position = Vector3(0, 0.42, 0.62)
	book.rotation.x = -0.6
	body.add_child(book)
	for side: int in [-1, 1]:
		var page := Models.part(book, _box(Vector3(0.26, 0.04, 0.32), 0.015), PAGES, Vector3(side * 0.14, 0.03, 0))
		page.rotation.z = side * 0.12
		var cov := Models.part(book, _box(Vector3(0.28, 0.025, 0.34), 0.01), RIBBON_A, Vector3(side * 0.145, 0.0, 0))
		cov.rotation.z = side * 0.12
		for k in 3:
			_no_shadow(Models.part(book, _box(Vector3(0.18, 0.006, 0.02), 0.002), INK, Vector3(side * 0.14, 0.055, -0.08 + k * 0.07)))
	return root


## An ink ball in flight.
static func ink_ball() -> Node3D:
	var root := Node3D.new()
	var b := _no_shadow(Models.part(root, Models.sphere(0.18, -1, 12), INK, Vector3.ZERO, 0.15))
	b.name = "Ball"
	_no_shadow(Models.part(root, Models.sphere(0.05, -1, 6), INK_LIGHT.lightened(0.4), Vector3(-0.06, 0.08, 0.1), 0.6))
	return root


## A flat ink puddle on the floor with a few droplets around it.
static func ink_puddle(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var main := _no_shadow(Models.part(root, Models.cylinder(0.36, 0.38, 0.03, 18), INK_DEEP, Vector3(0, 0.02, 0), 0.05))
	main.scale = Vector3(1.0, 1.0, r.randf_range(0.8, 1.0))
	for k in 4:
		var a: float = TAU * k / 4.0 + r.randf()
		var s: float = r.randf_range(0.08, 0.14)
		_no_shadow(Models.part(root, Models.cylinder(s, s, 0.03, 10), INK_DEEP, Vector3(cos(a) * 0.36, 0.02, sin(a) * 0.36), 0.05))
	_no_shadow(Models.part(root, Models.cylinder(0.1, 0.1, 0.035, 10), INK_LIGHT, Vector3(-0.1, 0.025, -0.08), 0.4)).scale = Vector3(1, 1, 0.5)
	return root


## A dark ring warning where an ink ball will land.
static func ink_warning() -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.34
	ring.outer_radius = 0.44
	ring.rings = 24
	ring.ring_segments = 4
	var r := _no_shadow(Models.part(root, ring, INK_LIGHT, Vector3(0, 0.04, 0), 0.9))
	r.scale = Vector3(1, 0.3, 1)
	var disc := _no_shadow(Models.part(root, Models.cylinder(0.32, 0.32, 0.01, 20), INK, Vector3(0, 0.025, 0), 0.0))
	disc.name = "Disc"
	return root


# --- Library props ----------------------------------------------------------------

## A green banker's reading lamp on a little side table.
static func reading_lamp() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.5, 0.05, 0.4), 0.02), WOOD_LIGHT, Vector3(0, 0.42, 0))
	for sx: float in [-0.2, 0.2]:
		for sz: float in [-0.15, 0.15]:
			Models.part(root, _box(Vector3(0.05, 0.42, 0.05), 0.015), WOOD_DARK, Vector3(sx, 0.2, sz))
	Models.part(root, Models.cylinder(0.08, 0.1, 0.04, 12), BRASS, Vector3(0, 0.46, 0))
	Models.part(root, Models.cylinder(0.015, 0.015, 0.3, 6), BRASS, Vector3(0, 0.62, 0))
	var shade := Models.part(root, Models.sphere(0.17, 0.16, 16), LAMP_GREEN, Vector3(0, 0.78, 0.0), 0.15)
	shade.scale = Vector3(1.2, 1.0, 0.8)
	_no_shadow(Models.part(root, Models.cylinder(0.15, 0.15, 0.02, 14), LAMP_GLOW, Vector3(0, 0.71, 0), 2.4)).scale = Vector3(1.2, 1, 0.8)
	_no_shadow(Models.part(root, _box(Vector3(0.2, 0.04, 0.14), 0.01), COVERS[1], Vector3(0.1, 0.47, 0.06)))
	return root


## A brass-ringed globe on a wooden stand.
static func globe() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.14, 0.18, 0.06, 14), WOOD_DARK, Vector3(0, 0.03, 0))
	Models.part(root, Models.cylinder(0.03, 0.04, 0.4, 8), WOOD, Vector3(0, 0.25, 0))
	var g := Node3D.new()
	g.name = "Globe"
	g.position = Vector3(0, 0.62, 0)
	g.rotation.z = 0.4
	root.add_child(g)
	Models.part(g, Models.sphere(0.22, -1, 18), Color("#5FA8E0"), Vector3.ZERO)
	Models.part(g, Models.sphere(0.1, 0.12, 10), Color("#7CC46A"), Vector3(0.1, 0.1, 0.13))
	Models.part(g, Models.sphere(0.08, 0.1, 10), Color("#7CC46A"), Vector3(-0.14, -0.04, -0.12))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.25
	ring.outer_radius = 0.28
	ring.rings = 24
	ring.ring_segments = 6
	var rr := Models.part(g, ring, BRASS, Vector3.ZERO)
	rr.rotation.x = PI * 0.5
	return root


## A loose heap of books on the floor, some open.
static func book_pile(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var y: float = 0.0
	for k in r.randi_range(2, 4):
		var h: float = r.randf_range(0.07, 0.11)
		var s := Vector3(r.randf_range(0.34, 0.44), h, r.randf_range(0.26, 0.32))
		_book(root, s, COVERS[r.randi() % COVERS.size()], Vector3(r.randf_range(-0.04, 0.04), y + h * 0.5, r.randf_range(-0.04, 0.04)), r.randf() * TAU)
		y += h
	if r.randf() < 0.5:
		var open := Node3D.new()
		open.position = Vector3(r.randf_range(-0.3, 0.3), 0.02, 0.28)
		open.rotation.y = r.randf_range(-0.6, 0.6)
		root.add_child(open)
		for side: int in [-1, 1]:
			Models.part(open, _box(Vector3(0.18, 0.03, 0.24), 0.01), PAGES, Vector3(side * 0.095, 0.02, 0)).rotation.z = side * 0.1
	return root


## A tall bookcase for the far side of the rim.
static func bookcase(r: RandomNumberGenerator, rows: int = 3) -> Node3D:
	var root := Node3D.new()
	var h: float = 0.36 * rows + 0.12
	Models.part(root, _box(Vector3(0.94, h, 0.36), 0.04), WOOD, Vector3(0, h * 0.5, 0))
	Models.part(root, _box(Vector3(1.0, 0.07, 0.42), 0.025), WOOD_DARK, Vector3(0, h + 0.03, 0))
	for row in rows:
		var x: float = -0.4
		Models.part(root, _box(Vector3(0.86, 0.03, 0.3), 0.01), WOOD_DARK, Vector3(0, 0.07 + row * 0.36, 0.04))
		while x < 0.38:
			var w: float = r.randf_range(0.06, 0.1)
			var bh: float = r.randf_range(0.22, 0.3)
			var book := Models.part(root, _box(Vector3(w, bh, 0.24), 0.012), COVERS[r.randi() % COVERS.size()], Vector3(x + w * 0.5, 0.09 + row * 0.36 + bh * 0.5, 0.07))
			if r.randf() < 0.1:
				book.rotation.z = -0.25
				x += 0.05
			x += w + 0.012
	if r.randf() < 0.5:
		var c := candle()
		c.position = Vector3(r.randf_range(-0.3, 0.3), h + 0.06, 0)
		root.add_child(c)
	return root


## A short candle in a brass holder with a glowing flame.
static func candle() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.07, 0.09, 0.03, 12), BRASS, Vector3(0, 0.015, 0))
	Models.part(root, Models.cylinder(0.035, 0.035, 0.16, 10), PAGES, Vector3(0, 0.11, 0))
	_no_shadow(Models.part(root, Models.sphere(0.03, 0.06, 8), LAMP_GLOW, Vector3(0, 0.22, 0), 3.0))
	return root


## A plump reading armchair.
static func armchair(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.62, 0.22, 0.56), 0.08), color, Vector3(0, 0.2, 0))
	Models.part(root, _box(Vector3(0.62, 0.42, 0.14), 0.07), color.darkened(0.08), Vector3(0, 0.45, -0.22))
	for side: int in [-1, 1]:
		Models.part(root, _box(Vector3(0.13, 0.32, 0.56), 0.06), color.darkened(0.12), Vector3(side * 0.3, 0.3, 0))
	Models.part(root, _box(Vector3(0.5, 0.06, 0.4), 0.03), color.lightened(0.15), Vector3(0, 0.33, 0.04))
	for sx: float in [-0.25, 0.25]:
		for sz: float in [-0.2, 0.2]:
			Models.part(root, Models.cylinder(0.03, 0.03, 0.1, 6), WOOD_DARK, Vector3(sx, 0.05, sz))
	return root


## A potted fern.
static func fern(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.14, 0.11, 0.2, 12), Color("#D9734E"), Vector3(0, 0.1, 0))
	Models.part(root, Models.cylinder(0.15, 0.15, 0.04, 12), Color("#C45F3E"), Vector3(0, 0.2, 0))
	for k in 6:
		var a: float = TAU * k / 6.0 + r.randf()
		var leaf := Models.part(root, Models.sphere(0.07, 0.3, 8), Color("#5DB060") if k % 2 == 0 else Color("#4A9C55"), Vector3(cos(a) * 0.1, 0.34, sin(a) * 0.1))
		leaf.rotation = Vector3(sin(a) * 0.7, 0, -cos(a) * 0.7)
		leaf.scale = Vector3(1, 1, 0.5)
	return root

extends RefCounted
## Models for World 15, Origami Valley: everything is folded from crisp
## paper. Fold markers (a paper pinwheel on a block), the Paper Crane (glides
## in long straight lines), the Paper Frog (hops two tiles at a time), the
## Origami Dragon boss and the valley props: paper trees, houses, lanterns,
## pinwheels and folded mountains. Built from crisp, slightly rounded clay
## shapes like render/Models.gd; folds read through flat triangle faces.

const PAPER := Color("#FFF8EC")
const PAPER_SHADE := Color("#EADFCC")
const INK := Color("#3A3550")
const PINK := Color("#FF8FB1")
const SKY := Color("#6FB7FF")
const MINT := Color("#5FD3A6")
const LEMON := Color("#FFC94D")
const CORAL := Color("#FF7A6B")
const LILAC := Color("#B79CFF")
const CRANE := Color("#FFFFFF")
const CRANE_WING := Color("#FF9EBF")
const FROG := Color("#5CC46A")
const FROG_DARK := Color("#3E9C55")
const FROG_BELLY := Color("#C9F2B5")
const DRAGON := Color("#E8524A")
const DRAGON_DARK := Color("#B93A3A")
const DRAGON_GOLD := Color("#F7C14B")
const DRAGON_BELLY := Color("#FFE3B8")
const TRUNK := Color("#C08A5A")
const BOSS_SIZE: float = 1.45
const CRANE_SIZE: float = 1.3
const FROG_SIZE: float = 1.45

## One colour per fold: its marker and the coloured side of its paper panel.
const FOLD_COLORS: Array[Color] = [Color("#FF8FB1"), Color("#6FB7FF"), Color("#FFC94D"), Color("#5FD3A6")]

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A triangular prism: a [param w]-wide, [param h]-tall triangle (apex up,
## base on y = 0) in the XY plane, [param d] deep along Z.
static func prism(w: float, h: float, d: float) -> ArrayMesh:
	var key := "prism/%.3f/%.3f/%.3f" % [w, h, d]
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0), Vector2(0.0, h)])
		var r: float = minf(w, h) * 0.06
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, r, 2), d, minf(d * 0.3, 0.02), 1)
	return _shapes[key]


## A flat paper triangle lying in the XZ plane: base along X at z = 0,
## apex at z = [param h] (pointing +Z), [param t] thick.
static func flat_tri(w: float, h: float, t: float = 0.03) -> ArrayMesh:
	var key := "tri/%.3f/%.3f/%.3f" % [w, h, t]
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0), Vector2(0.0, h)])
		var m: ArrayMesh = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.012, 1), t, t * 0.3, 1)
		_shapes[key] = m
	return _shapes[key]


## A square pyramid (a cone with four sides), turned so its faces look
## folded.
static func pyramid(r: float, h: float) -> CylinderMesh:
	return Models.cylinder(0.0, r, h, 4)


static func _tri_part(parent: Node3D, w: float, h: float, color: Color, pos: Vector3, t: float = 0.03) -> MeshInstance3D:
	# flat_tri is built in XY then extruded along Z; turn it to lie flat.
	var mi := Models.part(parent, flat_tri(w, h, t), color, pos)
	mi.rotation.x = PI * 0.5
	return mi


# --- Fold marker --------------------------------------------------------------------

## A paper block in the fold's colour with a white top, a big pinwheel
## ("Wheel") tilted to face the camera, and a glowing button ("Bulb").
static func marker(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.84, 0.34, 0.84), 0.07), color.lerp(Color.WHITE, 0.15), Vector3(0, 0.17, 0))
	Models.part(root, _box(Vector3(0.9, 0.07, 0.9), 0.03), PAPER, Vector3(0, 0.36, 0))
	var fold := Models.part(root, half_square(0.7, 0.04), color.darkened(0.08), Vector3(0, 0.41, 0))
	fold.rotation.x = -PI * 0.5
	Models.part(root, Models.cylinder(0.035, 0.045, 0.5, 8), INK.lightened(0.25), Vector3(0, 0.62, -0.05))
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	wheel.position = Vector3(0, 0.9, 0.0)
	wheel.rotation.x = -0.55
	wheel.scale = Vector3.ONE * 1.35
	root.add_child(wheel)
	var spin := Node3D.new()
	spin.name = "Spin"
	wheel.add_child(spin)
	# Four folded vanes, alternating paper white and the fold colour.
	for k in 4:
		var vane := Node3D.new()
		vane.rotation.z = k * PI * 0.5
		spin.add_child(vane)
		var col: Color = color if k % 2 == 0 else PAPER
		var a := Models.part(vane, flat_tri(0.34, 0.3, 0.025), col, Vector3(0.0, 0.17, 0.0))
		a.rotation = Vector3(0, 0, -PI * 0.5)
		var b := Models.part(vane, flat_tri(0.2, 0.3, 0.025), col.darkened(0.15), Vector3(0.1, 0.09, 0.015))
		b.rotation = Vector3(0, 0, -PI * 0.5)
	Models.part(spin, Models.sphere(0.055, -1, 10), LEMON, Vector3(0, 0, 0.04))
	_no_shadow(Models.part(root, Models.sphere(0.07, -1, 10), color, Vector3(0, 0.38, 0.44), 1.6)).name = "Bulb"
	return root


## A right triangle covering half of a [param size] square, lying flat
## (its crease runs corner to corner), [param t] thick.
static func half_square(size: float, t: float) -> ArrayMesh:
	var key := "half/%.3f/%.3f" % [size, t]
	if not _shapes.has(key):
		var h: float = size * 0.5
		var pts := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(-h, h)])
		var m: ArrayMesh = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.02, 1), t, t * 0.3, 1)
		_shapes[key] = m
	return _shapes[key]


# --- Critters ------------------------------------------------------------------------

## Paper Crane: a white folded bird with pink-backed wings ("WingL",
## "WingR"), a long neck and tail. It faces +Z.
static func crane() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.28)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * CRANE_SIZE
	root.add_child(body)
	var fly := Node3D.new()
	fly.name = "Fly"
	fly.position.y = 0.42
	body.add_child(fly)
	# A diamond body: two square pyramids base to base.
	var top := Models.part(fly, pyramid(0.2, 0.2), CRANE, Vector3(0, 0.1, 0))
	top.rotation.y = PI * 0.25
	top.scale = Vector3(0.8, 1.0, 1.5)
	var bot := Models.part(fly, pyramid(0.2, 0.14), PAPER_SHADE, Vector3(0, -0.07, 0))
	bot.rotation = Vector3(PI, PI * 0.25, 0)
	bot.scale = Vector3(0.8, 1.0, 1.5)
	# Neck and head up front, tail behind: slim prisms tilted up.
	var neck := Models.part(fly, prism(0.07, 0.42, 0.05), CRANE, Vector3(0, 0.04, 0.15))
	neck.rotation.x = 0.75
	var head := Node3D.new()
	head.position = Vector3(0, 0.31, 0.42)
	fly.add_child(head)
	var skull := Models.part(head, pyramid(0.07, 0.14), CRANE, Vector3(0, 0, 0))
	skull.rotation = Vector3(PI * 0.5, PI * 0.25, 0)
	var beak := Models.part(head, pyramid(0.03, 0.12), CORAL, Vector3(0, -0.01, 0.12))
	beak.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		Models.part(head, Models.sphere(0.022, -1, 8), INK, Vector3(side * 0.05, 0.03, 0.02))
	var cheek := Models.part(head, Models.sphere(0.02, -1, 6), PINK, Vector3(0.0, 0.07, -0.02))
	cheek.scale = Vector3(2.0, 0.6, 1.0)
	var tail := Models.part(fly, prism(0.08, 0.36, 0.05), CRANE, Vector3(0, 0.04, -0.15))
	tail.rotation.x = -0.9
	# Wings: flat triangles hinged at the body's sides.
	for side: int in [-1, 1]:
		var hinge := Node3D.new()
		hinge.name = "WingL" if side < 0 else "WingR"
		hinge.position = Vector3(side * 0.06, 0.05, 0)
		fly.add_child(hinge)
		var up := Models.part(hinge, flat_tri(0.46, 0.5, 0.02), CRANE, Vector3(side * 0.0, 0.006, 0))
		up.rotation = Vector3(PI * 0.5, 0, side * -PI * 0.5)
		var under := Models.part(hinge, flat_tri(0.44, 0.48, 0.02), CRANE_WING, Vector3(0, -0.012, 0))
		under.rotation = Vector3(PI * 0.5, 0, side * -PI * 0.5)
	return root


## Paper Frog: a squat green folded frog with big eyes and folded legs
## ("LegL", "LegR"). It faces +Z.
static func frog() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * FROG_SIZE
	root.add_child(body)
	var trunk := Models.part(body, Models.cylinder(0.14, 0.3, 0.26, 4), FROG, Vector3(0, 0.17, -0.02))
	trunk.rotation.y = PI * 0.25
	trunk.scale = Vector3(1.0, 1.0, 1.15)
	var belly := Models.part(body, _box(Vector3(0.3, 0.05, 0.12), 0.02), FROG_BELLY, Vector3(0, 0.1, 0.19))
	belly.rotation.x = -0.6
	# Front feet and the big folded back legs.
	for side: int in [-1, 1]:
		var front := Models.part(body, prism(0.1, 0.14, 0.06), FROG_DARK, Vector3(side * 0.16, 0.0, 0.17))
		front.rotation.y = side * 0.3
		var leg := Node3D.new()
		leg.name = "LegL" if side < 0 else "LegR"
		leg.position = Vector3(side * 0.22, 0.04, -0.12)
		body.add_child(leg)
		var thigh := Models.part(leg, prism(0.26, 0.2, 0.1), FROG_DARK, Vector3(0, 0, 0))
		thigh.rotation.y = PI * 0.5
		var foot := Models.part(leg, flat_tri(0.14, 0.2, 0.02), FROG_DARK.darkened(0.1), Vector3(side * 0.03, 0.01, 0.06))
		foot.rotation.x = PI * 0.5
	# Eyes on top: white bumps with ink pupils, and a small smile.
	for side: int in [-1, 1]:
		var bump := Models.part(body, Models.cylinder(0.06, 0.075, 0.08, 6), FROG, Vector3(side * 0.1, 0.33, 0.07))
		bump.rotation.y = 0.3
		var eye := Models.part(body, Models.sphere(0.06, -1, 10), Models.WHITE, Vector3(side * 0.1, 0.38, 0.09))
		eye.scale = Vector3(1.0, 1.0, 0.8)
		Models.part(body, Models.sphere(0.032, -1, 8), INK, Vector3(side * 0.1, 0.38, 0.14))
		_no_shadow(Models.part(body, Models.sphere(0.012, -1, 6), Models.WHITE, Vector3(side * 0.1 + 0.012, 0.395, 0.17), 1.0))
		var blush := Models.part(body, Models.sphere(0.03, -1, 6), PINK, Vector3(side * 0.17, 0.22, 0.17))
		blush.scale = Vector3(1.0, 0.6, 0.5)
	var mouth := Models.part(body, _box(Vector3(0.14, 0.022, 0.02), 0.008), INK, Vector3(0, 0.24, 0.215))
	mouth.rotation.x = -0.5
	return root


## The Origami Dragon: a red-and-gold folded dragon with a horned head
## ("Head", with "Jaw"), spread wings ("WingL", "WingR"), a crest of gold
## spikes and a three-part tail ("Tail"). "Glow" is a floor ring shown when
## it is about to fold the valley.
static func dragon() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.6, 0.4)
	var ring := _no_shadow(Models.part(root, Models.cylinder(0.75, 0.75, 0.03, 32), LEMON, Vector3(0, 0.03, 0), 1.2))
	ring.name = "Glow"
	ring.visible = false
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	# Legs: four folded gold feet.
	for sx: float in [-0.2, 0.2]:
		for sz: float in [-0.14, 0.14]:
			var leg := Models.part(body, pyramid(0.08, 0.2), DRAGON_DARK, Vector3(sx, 0.1, sz))
			leg.rotation.y = PI * 0.25
			Models.part(body, _box(Vector3(0.12, 0.04, 0.14), 0.015), DRAGON_GOLD, Vector3(sx, 0.02, sz + 0.03))
	# Body: a chunky folded diamond.
	var torso := Models.part(body, Models.cylinder(0.27, 0.36, 0.38, 4), DRAGON, Vector3(0, 0.36, 0))
	torso.rotation.y = PI * 0.25
	torso.scale = Vector3(1.0, 1.0, 1.2)
	var top := Models.part(body, pyramid(0.27, 0.2), DRAGON_DARK, Vector3(0, 0.65, 0))
	top.rotation.y = PI * 0.25
	top.scale = Vector3(1.0, 1.0, 1.2)
	var belly := Models.part(body, _box(Vector3(0.32, 0.28, 0.06), 0.03), DRAGON_BELLY, Vector3(0, 0.36, 0.27))
	belly.rotation.x = 0.2
	for k in 3:
		Models.part(body, _box(Vector3(0.28, 0.022, 0.07), 0.008), DRAGON_GOLD, Vector3(0, 0.27 + k * 0.08, 0.3))
	# Crest spikes down the back.
	for k in 4:
		var spike := Models.part(body, prism(0.14, 0.17 - k * 0.02, 0.04), DRAGON_GOLD, Vector3(0, 0.7 - k * 0.05, 0.1 - k * 0.12))
		spike.rotation.y = PI * 0.5
	# Wings: big flat triangles in two layers, hinged at the shoulders.
	for side: int in [-1, 1]:
		var hinge := Node3D.new()
		hinge.name = "WingL" if side < 0 else "WingR"
		hinge.position = Vector3(side * 0.2, 0.58, -0.06)
		body.add_child(hinge)
		var a := Models.part(hinge, flat_tri(0.46, 0.46, 0.03), DRAGON, Vector3(0, 0, 0))
		a.rotation = Vector3(PI * 0.5, 0, side * -PI * 0.5)
		var b := Models.part(hinge, flat_tri(0.3, 0.36, 0.03), DRAGON_GOLD, Vector3(0, 0.025, -0.05))
		b.rotation = Vector3(PI * 0.5, 0, side * -PI * 0.5)
		hinge.rotation.z = side * 0.85
	# Head on a short neck.
	var neck := Models.part(body, Models.cylinder(0.11, 0.16, 0.3, 4), DRAGON, Vector3(0, 0.64, 0.24))
	neck.rotation = Vector3(0.6, PI * 0.25, 0)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.84, 0.36)
	body.add_child(head)
	Models.part(head, _box(Vector3(0.38, 0.26, 0.3), 0.06), DRAGON, Vector3(0, 0, 0))
	var snout := Models.part(head, _box(Vector3(0.28, 0.13, 0.2), 0.045), DRAGON, Vector3(0, -0.02, 0.2))
	snout.rotation.x = 0.1
	var jaw := Models.part(head, _box(Vector3(0.26, 0.06, 0.22), 0.02), DRAGON_DARK, Vector3(0, -0.12, 0.15))
	jaw.name = "Jaw"
	for side: int in [-1, 1]:
		var horn := Models.part(head, pyramid(0.05, 0.24), DRAGON_GOLD, Vector3(side * 0.12, 0.2, -0.06))
		horn.rotation = Vector3(-0.5, PI * 0.25, side * -0.3)
		var whisker := Models.part(head, prism(0.05, 0.26, 0.025), DRAGON_GOLD, Vector3(side * 0.15, -0.03, 0.26))
		whisker.rotation = Vector3(0, 0, side * -1.9)
		_no_shadow(Models.part(head, Models.sphere(0.025, -1, 6), INK, Vector3(side * 0.06, 0.04, 0.305)))
	Models._eyes(head, 0.07, 0.15, 0.1, 0.065, true)
	var nose := Models.part(head, _box(Vector3(0.14, 0.035, 0.04), 0.01), DRAGON_GOLD, Vector3(0, 0.05, 0.3))
	nose.rotation.x = -0.3
	# Tail: three pyramids getting smaller, each child of the last so it can
	# swish.
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.34, -0.24)
	body.add_child(tail)
	var parent: Node3D = tail
	for k in 3:
		var seg := Node3D.new()
		seg.name = "Seg%d" % k
		seg.position = Vector3(0, 0, -0.04 if k == 0 else -0.17)
		parent.add_child(seg)
		var piece := Models.part(seg, pyramid(0.11 - k * 0.025, 0.24), DRAGON if k % 2 == 0 else DRAGON_DARK, Vector3(0, 0, -0.08))
		piece.rotation = Vector3(-PI * 0.5, PI * 0.25, 0)
		parent = seg
	var tip := Models.part(parent, flat_tri(0.2, 0.16, 0.02), DRAGON_GOLD, Vector3(0, 0, -0.2))
	tip.rotation.x = -PI * 0.5
	return root


# --- Valley props ----------------------------------------------------------------------

## A paper tree: stacked folded cones on a little trunk.
static func paper_tree(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s: float = r.randf_range(0.8, 1.15)
	root.scale = Vector3.ONE * s
	Models.part(root, _box(Vector3(0.12, 0.3, 0.12), 0.02), TRUNK, Vector3(0, 0.15, 0))
	var greens: Array[Color] = [Color("#6CC77A"), Color("#4FB06A"), Color("#8ED98A"), Color("#5FC4A6")]
	var g: Color = greens[r.randi() % greens.size()]
	for k in 3:
		var c := Models.part(root, pyramid(0.42 - k * 0.1, 0.42), g.darkened(k * 0.06), Vector3(0, 0.42 + k * 0.24, 0))
		c.rotation.y = PI * 0.25 + k * 0.4
	return root


## A little paper house with a folded roof.
static func paper_house(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.rotation.y = r.randf_range(-0.4, 0.4)
	var walls: Array[Color] = [PAPER, Color("#FFE7D1"), Color("#E3F1FF")]
	Models.part(root, _box(Vector3(0.6, 0.42, 0.5), 0.04), walls[r.randi() % walls.size()], Vector3(0, 0.21, 0))
	var roofs: Array[Color] = [CORAL, SKY, PINK, LILAC]
	var roof := Models.part(root, prism(0.76, 0.34, 0.62), roofs[r.randi() % roofs.size()], Vector3(0, 0.42, 0))
	roof.rotation.y = PI * 0.5
	Models.part(root, _box(Vector3(0.14, 0.22, 0.03), 0.02), INK.lightened(0.3), Vector3(0.08, 0.11, 0.26))
	_no_shadow(Models.part(root, _box(Vector3(0.11, 0.1, 0.03), 0.015), LEMON, Vector3(-0.15, 0.25, 0.26), 1.0))
	return root


## A round paper lantern on a post, glowing softly.
static func paper_lantern() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.08, 0.7, 0.08), 0.02), INK.lightened(0.3), Vector3(0, 0.35, 0))
	Models.part(root, _box(Vector3(0.3, 0.04, 0.06), 0.015), INK.lightened(0.3), Vector3(0.1, 0.7, 0))
	var lamp := Models.part(root, Models.sphere(0.13, 0.22, 12), CORAL, Vector3(0.22, 0.55, 0), 0.9)
	lamp.scale = Vector3(1.0, 1.0, 1.0)
	_no_shadow(lamp)
	for y: float in [0.44, 0.66]:
		Models.part(root, Models.cylinder(0.06, 0.06, 0.03, 8), INK, Vector3(0.22, y, 0))
	return root


## A paper pinwheel on a stick ("Wheel" spins).
static func pinwheel(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.02, 0.025, 0.7, 6), PAPER_SHADE, Vector3(0, 0.35, 0))
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	wheel.position = Vector3(0, 0.72, 0.04)
	root.add_child(wheel)
	for k in 4:
		var vane := Node3D.new()
		vane.rotation.z = k * PI * 0.5
		wheel.add_child(vane)
		var a := Models.part(vane, flat_tri(0.24, 0.22, 0.02), color if k % 2 == 0 else PAPER, Vector3(0, 0.12, 0))
		a.rotation = Vector3(0, 0, -PI * 0.5)
	return root


## A folded paper mountain: two or three steep prisms with snowy tips.
static func paper_mountain(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var tones: Array[Color] = [Color("#8FB8E8"), Color("#A9C7F0"), Color("#9AD0B8")]
	for k in r.randi_range(2, 3):
		var h: float = size * r.randf_range(0.55, 0.9)
		var w: float = size * r.randf_range(0.5, 0.75)
		var p := Vector3(r.randf_range(-0.3, 0.3) * size, 0, r.randf_range(-0.25, 0.25) * size)
		var m := Models.part(root, pyramid(w * 0.6, h), tones[k % tones.size()], p + Vector3(0, h * 0.5, 0))
		m.rotation.y = PI * 0.25 + r.randf_range(-0.3, 0.3)
		var cap := Models.part(root, pyramid(w * 0.6 * 0.3, h * 0.3), PAPER, p + Vector3(0, h * 0.85 + 0.005, 0))
		cap.rotation.y = m.rotation.y
	return root

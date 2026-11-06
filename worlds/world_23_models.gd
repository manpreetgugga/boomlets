extends RefCounted
## Models for World 23, Seasons Grove: the season totem, flower bushes,
## leaf piles, pond water and ice, hedgehogs, the Season Stag and the
## orchard decor. Parts that change colour with the seasons take a material
## from the caller (see world_23.gd), so one tween recolours them all.

const SPRING := Color("#FF8FB8")
const SUMMER := Color("#FFC93C")
const AUTUMN := Color("#F27A2E")
const WINTER := Color("#7CC4F2")
const SEASON_COLORS: Array[Color] = [SPRING, SUMMER, AUTUMN, WINTER]

const WOOD := Color("#B98252")
const WOOD_DARK := Color("#8C5A36")
const WOOD_LIGHT := Color("#E2B07A")
const CREAM := Color("#FFF4E2")
const INK := Color("#2E2A4A")
const WATER := Color("#69C3E8")
const WATER_DEEP := Color("#4DA6D6")
const ICE := Color("#E3F6FF")
const ICE_EDGE := Color("#BFE6FA")
const LEAF_COLORS: Array[Color] = [Color("#F2902E"), Color("#E5562E"), Color("#F7C443"), Color("#C9662C")]
const HOG := Color("#A7744F")
const HOG_SPIKE := Color("#6E4A33")
const HOG_FACE := Color("#F4DDBE")
const STAG := Color("#C27F4C")
const STAG_BELLY := Color("#F6E3C6")
const ANTLER := Color("#EEDDBF")
const APPLE := Color("#E8463C")
const HAY := Color("#F0C860")

const HOG_SIZE: float = 1.2
const BOSS_SIZE: float = 2.0

static var _shapes: Dictionary = {}


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A part with a given (shared, recolourable) material.
static func part_m(parent: Node3D, mesh: Mesh, m: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	return mi


## A flat leaf shape (pointed oval), lying in XY, [param d] deep.
static func leaf_mesh(r: float, d: float) -> ArrayMesh:
	var key := "leaf/%.3f/%.3f" % [r, d]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 12:
			var a: float = TAU * k / 12.0
			var w: float = 0.55 * (1.0 - 0.35 * absf(sin(a)))
			pts.append(Vector2(cos(a) * w * r, sin(a) * r))
		pts[3] = Vector2(0, r * 1.15)
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, r * 0.08, 2), d, d * 0.3, 1)
	return _shapes[key]


static func star_mesh(r: float, d: float, points: int = 5, inner: float = 0.48) -> ArrayMesh:
	var key := "star/%.3f/%.3f/%d/%.2f" % [r, d, points, inner]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in points * 2:
			var a: float = PI * 0.5 + TAU * k / (points * 2.0)
			var rr: float = r if k % 2 == 0 else r * inner
			pts.append(Vector2(cos(a), sin(a)) * rr)
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, r * 0.06, 2), d, d * 0.3, 1)
	return _shapes[key]


# --- Season icons ------------------------------------------------------------------------

## A little emblem for season [param s], standing up in XY, facing +Z.
static func season_icon(s: int) -> Node3D:
	var root := Node3D.new()
	match s:
		0:
			for k in 5:
				var a: float = TAU * k / 5.0 + PI * 0.5
				var petal := Models.part(root, Models.sphere(0.06, -1, 10), SPRING, Vector3(cos(a) * 0.065, sin(a) * 0.065, 0))
				petal.scale = Vector3(1, 1, 0.45)
			Models.part(root, Models.sphere(0.04, -1, 8), Color("#FFE27A"), Vector3(0, 0, 0.02))
		1:
			Models.part(root, star_mesh(0.13, 0.03, 8, 0.62), Color("#FFB627"))
			var c := Models.part(root, Models.sphere(0.07, -1, 12), SUMMER, Vector3(0, 0, 0.02), 0.2)
			c.scale = Vector3(1, 1, 0.5)
		2:
			var l := Models.part(root, leaf_mesh(0.12, 0.03), AUTUMN)
			l.rotation.z = -0.5
			var stem := Models.part(root, Models.box_mesh(Vector3(0.015, 0.08, 0.02), 0.005), WOOD_DARK, Vector3(0.05, -0.1, 0))
			stem.rotation.z = -0.5
		3:
			for k in 3:
				var arm := Models.part(root, Models.box_mesh(Vector3(0.03, 0.24, 0.03), 0.012), WINTER)
				arm.rotation.z = PI * k / 3.0
			Models.part(root, Models.sphere(0.035, -1, 8), Color("#FFFFFF"), Vector3(0, 0, 0.02))
	for c in root.get_children():
		_no_shadow(c)
	return root


# --- Board pieces ------------------------------------------------------------------------

## The season totem: a carved wooden post with a turning head ("Icons")
## that shows the four seasons on its four sides, and a ring ("Glow") at its
## foot that pulses before each change.
static func totem() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0, 0.35)
	Models.part(root, Models.box_mesh(Vector3(0.74, 0.16, 0.74), 0.06), WOOD_DARK, Vector3(0, 0.08, 0))
	Models.part(root, Models.box_mesh(Vector3(0.5, 0.5, 0.5), 0.1), WOOD, Vector3(0, 0.4, 0))
	for y: float in [0.25, 0.55]:
		Models.part(root, Models.box_mesh(Vector3(0.54, 0.05, 0.54), 0.02), WOOD_DARK, Vector3(0, y, 0))
	# A sleepy carved face.
	for side: int in [-1, 1]:
		var eye := Models.part(root, Models.box_mesh(Vector3(0.09, 0.025, 0.02), 0.01), INK, Vector3(side * 0.1, 0.44, 0.255))
		eye.rotation.z = side * 0.15
	Models.part(root, Models.box_mesh(Vector3(0.08, 0.03, 0.02), 0.01), INK, Vector3(0, 0.34, 0.255))
	var head := Node3D.new()
	head.name = "Icons"
	head.position = Vector3(0, 0.86, 0)
	root.add_child(head)
	Models.part(head, Models.box_mesh(Vector3(0.56, 0.36, 0.56), 0.1), WOOD_LIGHT)
	Models.part(head, Models.box_mesh(Vector3(0.62, 0.06, 0.62), 0.03), WOOD_DARK, Vector3(0, 0.2, 0))
	for s in 4:
		var holder := Node3D.new()
		holder.rotation.y = -PI * 0.5 * s
		head.add_child(holder)
		var icon := season_icon(s)
		icon.position = Vector3(0, 0, 0.29)
		icon.scale = Vector3.ONE * 1.3
		holder.add_child(icon)
	# A flat emblem on top, easy to read from above: a disc in the season's
	# colour ("Disc") with that season's icon lying on it ("Flat0".."Flat3").
	var top := Node3D.new()
	top.name = "Top"
	top.position = Vector3(0, 0.24, 0)
	head.add_child(top)
	Models.part(top, Models.cylinder(0.3, 0.3, 0.05, 24), CREAM)
	var disc := Models.part(top, Models.cylinder(0.25, 0.25, 0.03, 24), SPRING, Vector3(0, 0.03, 0))
	disc.name = "Disc"
	for s in 4:
		var flat := season_icon(s)
		flat.name = "Flat%d" % s
		flat.rotation.x = -PI * 0.5
		flat.position = Vector3(0, 0.06, 0)
		flat.scale = Vector3.ONE * 1.5
		flat.visible = s == 0
		top.add_child(flat)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	ring.rings = 24
	ring.ring_segments = 4
	var glow := _no_shadow(Models.part(root, ring, Color("#FFFFFF"), Vector3(0, 0.04, 0), 0.8))
	glow.name = "Glow"
	glow.scale = Vector3(1, 0.3, 1)
	glow.visible = false
	return root


## A round flowering bush that grows on a flower spot in spring.
static func flower_bush(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.95, 0.35)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var greens: Array[Color] = [Color("#7CC75E"), Color("#69B852"), Color("#8ED36C")]
	Models.part(body, Models.sphere(0.36, 0.56, 16), greens[1], Vector3(0, 0.28, 0))
	for k in 5:
		var a: float = TAU * k / 5.0 + r.randf() * 0.4
		Models.part(body, Models.sphere(0.2, -1, 12), greens[k % 3], Vector3(cos(a) * 0.24, 0.3 + r.randf() * 0.08, sin(a) * 0.24))
	Models.part(body, Models.sphere(0.22, -1, 12), greens[2], Vector3(0, 0.52, 0))
	var bloom := [Color("#FF8FB8"), Color("#FFFFFF"), Color("#FFD166")]
	for k in 9:
		var a: float = TAU * k / 9.0 + r.randf() * 0.3
		var up: float = r.randf_range(0.0, 0.9)
		var p := Vector3(cos(a) * 0.36 * (1.0 - up * 0.5), 0.3 + up * 0.32, sin(a) * 0.36 * (1.0 - up * 0.5))
		var f := Node3D.new()
		f.position = p
		body.add_child(f)
		var col: Color = bloom[k % 3]
		for j in 4:
			var b := Models.part(f, Models.sphere(0.04, -1, 6), col, Vector3(cos(j * PI * 0.5) * 0.04, 0.02, sin(j * PI * 0.5) * 0.04))
			_no_shadow(b)
		_no_shadow(Models.part(f, Models.sphere(0.028, -1, 6), Color("#FFB627"), Vector3(0, 0.035, 0)))
	return root


## The always-visible flower spot: a soil ring with a tiny sprout.
static func sprout() -> Node3D:
	var root := Node3D.new()
	var soil := _no_shadow(Models.part(root, Models.cylinder(0.3, 0.32, 0.03, 18), Color("#9B6E4C"), Vector3(0, 0.015, 0)))
	soil.name = "Soil"
	var s := Node3D.new()
	s.name = "Sprout"
	root.add_child(s)
	Models.part(s, Models.cylinder(0.015, 0.02, 0.12, 6), Color("#5DAE5E"), Vector3(0, 0.07, 0))
	for side: int in [-1, 1]:
		var l := Models.part(s, Models.sphere(0.05, -1, 8), Color("#7CC75E"), Vector3(side * 0.05, 0.13, 0))
		l.scale = Vector3(1.0, 0.4, 0.6)
		l.rotation.z = side * -0.4
	return root


## A heap of autumn leaves.
static func leaf_pile(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var mound := Models.part(body, Models.sphere(0.42, 0.34, 16), Color("#E58A34"), Vector3(0, 0.03, 0))
	mound.scale = Vector3(1.0, 1.0, 0.95)
	var lm := leaf_mesh(0.11, 0.025)
	for k in 16:
		var a: float = r.randf() * TAU
		var d: float = sqrt(r.randf()) * 0.38
		var h: float = 0.17 * (1.0 - d * d / 0.16) + 0.04
		var l := Models.part(body, lm, LEAF_COLORS[k % LEAF_COLORS.size()], Vector3(cos(a) * d, h, sin(a) * d))
		l.rotation = Vector3(-PI * 0.5 + r.randf_range(-0.4, 0.4), r.randf() * TAU, r.randf_range(-0.3, 0.3))
		_no_shadow(l)
	return root


## A few fallen leaves marking a leaf spot.
static func leaf_mark(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var lm := leaf_mesh(0.08, 0.02)
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf()
		var l := Models.part(root, lm, LEAF_COLORS[k].lerp(Color("#C9A46C"), 0.35), Vector3(cos(a) * 0.17, 0.015, sin(a) * 0.17))
		l.rotation = Vector3(-PI * 0.5, r.randf() * TAU, 0)
		_no_shadow(l)
	return root


## One pond tile: a stone lip, the "Water" and a hidden "Ice" slab.
static func pond(r: RandomNumberGenerator, edges: Array) -> Node3D:
	var root := Node3D.new()
	var water := Node3D.new()
	water.name = "Water"
	root.add_child(water)
	_no_shadow(Models.part(water, Models.box_mesh(Vector3(1.0, 0.06, 1.0), 0.02), WATER_DEEP, Vector3(0, 0.0, 0)))
	var top := _no_shadow(Models.part(water, Models.box_mesh(Vector3(0.96, 0.02, 0.96), 0.01), WATER, Vector3(0, 0.035, 0), 0.08))
	top.name = "Top"
	if r.randf() < 0.4:
		var pad := _no_shadow(Models.part(water, Models.cylinder(0.14, 0.14, 0.02, 14), Color("#6DBE5A"), Vector3(r.randf_range(-0.25, 0.25), 0.05, r.randf_range(-0.25, 0.25))))
		pad.name = "Pad"
	var ripple := TorusMesh.new()
	ripple.inner_radius = 0.16
	ripple.outer_radius = 0.2
	ripple.rings = 18
	ripple.ring_segments = 3
	var rp := _no_shadow(Models.part(water, ripple, Color("#BDE9FA"), Vector3(r.randf_range(-0.15, 0.15), 0.05, r.randf_range(-0.15, 0.15)), 0.2))
	rp.name = "Ripple"
	rp.scale = Vector3(1, 0.2, 1)
	# Stone lip on sides that border dry land.
	for e: Vector2i in edges:
		var lip := Models.part(root, Models.box_mesh(Vector3(1.0 if e.y != 0 else 0.14, 0.1, 0.14 if e.y != 0 else 1.0), 0.04), Color("#CFC6B8"), Vector3(e.x * 0.47, 0.03, e.y * 0.47))
		lip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ice := Node3D.new()
	ice.name = "Ice"
	ice.visible = false
	root.add_child(ice)
	_no_shadow(Models.part(ice, Models.box_mesh(Vector3(0.98, 0.1, 0.98), 0.03), ICE, Vector3(0, 0.03, 0), 0.05))
	for k in 2:
		var crack := _no_shadow(Models.part(ice, Models.box_mesh(Vector3(r.randf_range(0.3, 0.5), 0.012, 0.025), 0.005), ICE_EDGE.darkened(0.1), Vector3(r.randf_range(-0.2, 0.2), 0.085, r.randf_range(-0.2, 0.2))))
		crack.rotation.y = r.randf() * PI
		crack.name = "Crack%d" % k
	var shine := _no_shadow(Models.part(ice, Models.box_mesh(Vector3(0.4, 0.012, 0.06), 0.005), Color("#FFFFFF"), Vector3(-0.15, 0.086, -0.18), 0.4))
	shine.rotation.y = 0.6
	return root


# --- Critters ----------------------------------------------------------------------------

## Hedgehog: a round brown spiky ball with a cream face ("Face"), little
## feet ("Feet"), a snow cap ("Snow", shown while it hibernates), a "Zzz"
## label and a leaf it carries in autumn ("Leaf").
static func hedgehog() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * HOG_SIZE
	root.add_child(body)
	var ball := Node3D.new()
	ball.name = "Ball"
	ball.position.y = 0.27
	body.add_child(ball)
	var core := Models.part(ball, Models.sphere(0.26, -1, 18), HOG)
	core.scale = Vector3(1.0, 0.88, 1.08)
	# Spikes: short cones over the back.
	var spike := Models.cylinder(0.0, 0.065, 0.17, 6)
	for ring in 3:
		var tilt: float = 0.35 + ring * 0.42
		var n: int = 6 + ring * 2
		for k in n:
			var yaw: float = TAU * k / n + ring * 0.3
			var dir := Vector3(sin(tilt) * sin(yaw), cos(tilt), sin(tilt) * cos(yaw))
			if dir.z > 0.55:
				continue
			var s := Models.part(ball, spike, HOG_SPIKE, dir * 0.24)
			s.basis = Basis(Quaternion(Vector3.UP, dir)).scaled(Vector3.ONE)
	var top := Models.part(ball, spike, HOG_SPIKE, Vector3(0, 0.25, -0.05))
	top.rotation.x = -0.3
	var face := Node3D.new()
	face.name = "Face"
	ball.add_child(face)
	var mask := Models.part(face, Models.sphere(0.17, -1, 14), HOG_FACE, Vector3(0, -0.02, 0.15))
	mask.scale = Vector3(1.05, 0.9, 0.8)
	var snout := Models.part(face, Models.sphere(0.08, -1, 10), HOG_FACE, Vector3(0, -0.04, 0.29))
	snout.scale = Vector3(0.9, 0.8, 1.2)
	Models.part(face, Models.sphere(0.035, -1, 8), INK, Vector3(0, -0.02, 0.38))
	Models._eyes(face, 0.04, 0.24, 0.075, 0.042)
	for side: int in [-1, 1]:
		var cheek := _no_shadow(Models.part(face, Models.sphere(0.03, -1, 8), Color("#FF8FA3"), Vector3(side * 0.13, -0.05, 0.23)))
		cheek.scale = Vector3(1, 0.6, 0.5)
		var ear := Models.part(ball, Models.sphere(0.05, -1, 8), HOG_FACE.darkened(0.1), Vector3(side * 0.15, 0.14, 0.1))
		ear.scale = Vector3(1, 1, 0.5)
	var feet := Node3D.new()
	feet.name = "Feet"
	body.add_child(feet)
	for k in 4:
		var f := Models.part(feet, Models.sphere(0.055, -1, 8), HOG_SPIKE, Vector3((k % 2) * 0.24 - 0.12, 0.04, (k / 2) * 0.24 - 0.12))
		f.scale = Vector3(1, 0.6, 1.2)
	var snow := Node3D.new()
	snow.name = "Snow"
	snow.visible = false
	ball.add_child(snow)
	var cap := Models.part(snow, Models.sphere(0.22, 0.2, 14), Color("#FFFFFF"), Vector3(0, 0.22, -0.02))
	cap.scale = Vector3(1.1, 1.0, 1.1)
	var leaf := Models.part(ball, leaf_mesh(0.1, 0.025), AUTUMN, Vector3(0.05, 0.33, -0.05))
	leaf.rotation = Vector3(-1.2, 0.4, 0)
	leaf.name = "Leaf"
	leaf.visible = false
	var z := Label3D.new()
	z.name = "Zzz"
	z.text = "z Z"
	z.font = Ui.font(900)
	z.font_size = 64
	z.pixel_size = 0.004
	z.modulate = Color("#5E7FB8")
	z.outline_modulate = Color("#FFFFFF")
	z.outline_size = 14
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.no_depth_test = false
	z.position = Vector3(0.18, 0.75, 0)
	z.visible = false
	root.add_child(z)
	return root


## The Season Stag: a proud deer whose antlers carry the season's blooms,
## leaves or snow ("Tips" take the material [param tips]).
static func stag(tips: Material) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.5, 0.42)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position.y = 0.48
	body.add_child(torso)
	Models.part(torso, Models.box_mesh(Vector3(0.44, 0.36, 0.58), 0.17), STAG)
	var belly := Models.part(torso, Models.box_mesh(Vector3(0.34, 0.12, 0.44), 0.06), STAG_BELLY, Vector3(0, -0.14, 0))
	belly.scale = Vector3(1, 1, 1)
	for k in 4:
		_no_shadow(Models.part(torso, Models.sphere(0.035, -1, 8), CREAM, Vector3((k % 2) * 0.16 - 0.08, 0.18, -0.2 + k * 0.1)))
	var tail := Models.part(torso, Models.sphere(0.08, -1, 10), CREAM, Vector3(0, 0.08, -0.31))
	tail.name = "Tail"
	for k in 4:
		var leg := Node3D.new()
		leg.name = "Leg%d" % k
		leg.position = Vector3((k % 2) * 0.28 - 0.14, 0.36, (k / 2) * 0.38 - 0.19)
		body.add_child(leg)
		Models.part(leg, Models.cylinder(0.045, 0.055, 0.34, 8), STAG.darkened(0.08), Vector3(0, -0.17, 0))
		Models.part(leg, Models.cylinder(0.06, 0.06, 0.06, 8), WOOD_DARK.darkened(0.2), Vector3(0, -0.33, 0))
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 0.62, 0.2)
	body.add_child(neck)
	var nk := Models.part(neck, Models.box_mesh(Vector3(0.2, 0.42, 0.2), 0.09), STAG, Vector3(0, 0.16, 0.04))
	nk.rotation.x = 0.35
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.42, 0.12)
	neck.add_child(head)
	Models.part(head, Models.box_mesh(Vector3(0.26, 0.24, 0.3), 0.11), STAG)
	var muzzle := Models.part(head, Models.box_mesh(Vector3(0.18, 0.14, 0.16), 0.06), STAG_BELLY, Vector3(0, -0.05, 0.17))
	muzzle.rotation.x = 0.1
	Models.part(head, Models.sphere(0.035, -1, 8), INK, Vector3(0, -0.01, 0.26))
	Models._eyes(head, 0.04, 0.13, 0.085, 0.045, true)
	for side: int in [-1, 1]:
		var ear := Models.part(head, Models.sphere(0.07, -1, 10), STAG, Vector3(side * 0.17, 0.08, -0.04))
		ear.scale = Vector3(1.4, 0.55, 0.6)
		ear.rotation.z = side * 0.4
	var antlers := Node3D.new()
	antlers.name = "Antlers"
	antlers.position = Vector3(0, 0.12, -0.02)
	head.add_child(antlers)
	var tips_node := Node3D.new()
	tips_node.name = "Tips"
	antlers.add_child(tips_node)
	for side: int in [-1, 1]:
		var a := Node3D.new()
		a.position = Vector3(side * 0.07, 0, 0)
		a.rotation.z = side * -0.45
		antlers.add_child(a)
		Models.part(a, Models.cylinder(0.028, 0.04, 0.46, 7), ANTLER, Vector3(0, 0.23, 0))
		var tip_spots: Array[Vector3] = [Vector3(0, 0.38, 0)]
		for k in 2:
			var b := Node3D.new()
			b.position = Vector3(0, 0.15 + k * 0.15, 0)
			b.rotation = Vector3(-0.3 + k * 0.2, 0, side * (0.9 - k * 0.2) * -1.0)
			a.add_child(b)
			Models.part(b, Models.cylinder(0.02, 0.028, 0.22, 6), ANTLER, Vector3(0, 0.11, 0))
			tip_spots.append(a.position + Basis.from_euler(a.rotation) * (b.position + Basis.from_euler(b.rotation) * Vector3(0, 0.23, 0)))
		tip_spots[0] = a.position + Basis.from_euler(a.rotation) * Vector3(0, 0.47, 0)
		for p: Vector3 in tip_spots:
			for j in 3:
				var bl := part_m(tips_node, Models.sphere(0.065, -1, 8), tips, p + Vector3(randf_range(-0.04, 0.04), randf_range(-0.02, 0.04), randf_range(-0.04, 0.04)))
				_no_shadow(bl)
	return root


# --- Decor -------------------------------------------------------------------------------

## An orchard tree: trunk and a round crown in [param crown] (and a
## second tone [param crown2]); "Fruit" holds apples (shown in summer and
## autumn) and "Snow" a snowy cap (winter).
static func orchard_tree(r: RandomNumberGenerator, crown: Material, crown2: Material, scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.1 * scale, 0.3)
	var h: float = r.randf_range(0.55, 0.75) * scale
	Models.part(root, Models.cylinder(0.07 * scale, 0.1 * scale, h, 8), WOOD, Vector3(0, h * 0.5, 0))
	var c := Node3D.new()
	c.position.y = h + 0.22 * scale
	root.add_child(c)
	part_m(c, Models.sphere(0.36 * scale, 0.6 * scale, 16), crown, Vector3.ZERO)
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf()
		part_m(c, Models.sphere(0.22 * scale, -1, 12), crown2 if k % 2 == 0 else crown, Vector3(cos(a) * 0.26 * scale, 0.04 * scale, sin(a) * 0.26 * scale))
	part_m(c, Models.sphere(0.2 * scale, -1, 12), crown2, Vector3(0.02, 0.26 * scale, 0.0))
	var fruit := Node3D.new()
	fruit.name = "Fruit"
	c.add_child(fruit)
	for k in 5:
		var a: float = TAU * k / 5.0 + r.randf()
		_no_shadow(Models.part(fruit, Models.sphere(0.055 * scale, -1, 8), APPLE, Vector3(cos(a) * 0.33 * scale, r.randf_range(-0.05, 0.15) * scale, sin(a) * 0.33 * scale)))
	var snow := Node3D.new()
	snow.name = "Snow"
	snow.visible = false
	c.add_child(snow)
	var cap := Models.part(snow, Models.sphere(0.3 * scale, 0.22 * scale, 14), Color("#FFFFFF"), Vector3(0, 0.25 * scale, 0))
	cap.scale = Vector3(1.1, 1, 1.1)
	return root


static func haystack(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.3)
	var b := Models.part(root, Models.box_mesh(Vector3(0.5, 0.32, 0.36), 0.08), HAY, Vector3(0, 0.16, 0))
	b.rotation.y = r.randf_range(-0.4, 0.4)
	for k in 2:
		var band := Models.part(b, Models.box_mesh(Vector3(0.04, 0.34, 0.38), 0.015), Color("#C9963E"), Vector3(-0.12 + k * 0.24, 0, 0))
		band.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func pumpkin(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s: float = r.randf_range(0.8, 1.1)
	for k in 5:
		var a: float = TAU * k / 5.0
		var lobe := Models.part(root, Models.sphere(0.11 * s, -1, 10), Color("#F28A2E"), Vector3(cos(a) * 0.07 * s, 0.1 * s, sin(a) * 0.07 * s))
		lobe.scale = Vector3(0.8, 1.0, 0.8)
	Models.part(root, Models.cylinder(0.015, 0.025, 0.08, 6), Color("#6E8A3A"), Vector3(0, 0.22 * s, 0))
	return root


static func fence(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in 2:
		Models.part(root, Models.box_mesh(Vector3(0.08, 0.36, 0.08), 0.02), WOOD_LIGHT, Vector3(-0.3 + k * 0.6, 0.18, 0))
	for y: float in [0.13, 0.27]:
		Models.part(root, Models.box_mesh(Vector3(0.74, 0.06, 0.05), 0.02), WOOD_LIGHT.darkened(0.08), Vector3(0, y, 0))
	root.rotation.y = r.randf_range(-0.2, 0.2)
	return root


static func mushroom(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(1, 3):
		var s: float = r.randf_range(0.6, 1.0)
		var at := Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
		Models.part(root, Models.cylinder(0.03 * s, 0.04 * s, 0.12 * s, 6), CREAM, at + Vector3(0, 0.06 * s, 0))
		Models.part(root, Models.sphere(0.08 * s, 0.09 * s, 10), Color("#E5533D"), at + Vector3(0, 0.13 * s, 0))
	return root


static func apple_crate(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7, 0.3)
	Models.part(root, Models.box_mesh(Vector3(0.44, 0.2, 0.32), 0.03), WOOD_LIGHT, Vector3(0, 0.1, 0))
	for k in 6:
		_no_shadow(Models.part(root, Models.sphere(0.06, -1, 8), APPLE if k % 3 else Color("#9BCB4A"), Vector3((k % 3) * 0.13 - 0.13, 0.22, (k / 3) * 0.13 - 0.065)))
	root.rotation.y = r.randf_range(-0.5, 0.5)
	return root

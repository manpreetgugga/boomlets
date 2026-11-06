extends RefCounted
## Models for World 18, Domino Dunes: ivory domino tiles (with a floor arrow
## showing which way they topple), the Sand Scarab (a turquoise beetle that
## burrows, leaving a sand ripple), Cleopawtra the sphinx-cat boss and the
## warm desert props: palms, striped tents, dunes, pots, cacti and little
## pyramids. Built from crisp, slightly rounded clay blocks like
## render/Models.gd.

const SAND := Color("#F2C879")
const SAND_DARK := Color("#E2AE5E")
const SAND_LIGHT := Color("#FBE3B2")
const TERRA := Color("#DD7A4C")
const TERRA_DARK := Color("#B95C36")
const SANDSTONE := Color("#EDBE80")
const SANDSTONE_DARK := Color("#D39D5C")
const TURQ := Color("#2FB5A8")
const TURQ_LIGHT := Color("#86E3D6")
const LAPIS := Color("#3F6FD3")
const GOLD := Color("#F6C445")
const IVORY := Color("#FFF8EA")
const PIP := Color("#2E2A4A")
const TRUNK := Color("#B98552")
const TRUNK_DARK := Color("#94663C")
const PALM_A := Color("#5DBB6C")
const PALM_B := Color("#3FA05C")
const TENT_RED := Color("#E8604C")
const TENT_CREAM := Color("#FFF1D6")
const TENT_BLUE := Color("#4C8FD6")
const WATER := Color("#5CCBE3")
const CACTUS := Color("#6CBF7A")
const SHELL := Color("#5143B0")
const SHELL_DARK := Color("#362C7A")
const SHELL_SHINE := Color("#A79CF2")
const BEETLE := Color("#2E2A4A")
const MOUND := Color("#D29A52")
const FUR := Color("#F2C47E")
const FUR_DARK := Color("#D9A35E")
const CREAM := Color("#FFF0D8")
const NOSE := Color("#FF8FA3")
const BOSS_SIZE: float = 1.3
const SCARAB_SIZE: float = 1.0

## Domino slab size (x wide, y tall, z thick) and the forward lean it rests at.
const SLAB := Vector3(0.66, 0.74, 0.21)
const LEAN: float = 0.1
## Domino colours, one per chain, and the boss's gold ones.
const CHAIN_COLORS: Array[Color] = [Color("#4A5FD0"), Color("#E5585A"), Color("#8F5BCC"), Color("#E9873A")]
const BOSS_DOMINO := Color("#F2B53A")
const GROOVE := Color("#D9A65F")

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A flat arrow lying on the floor, pointing +Z.
static func floor_arrow() -> ArrayMesh:
	var key := "arrow"
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(-0.15, 0.13), Vector2(-0.15, 0.0), Vector2(0.0, -0.17), Vector2(0.15, 0.0), Vector2(0.15, 0.13), Vector2(0.0, -0.03)])
		# Extruded in xy; turn it to lie on the floor with its tip at +Z.
		var m: ArrayMesh = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.02), 0.025, 0.008, 1)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(m, 0, Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3.ZERO))
		_shapes[key] = st.commit()
	return _shapes[key]


## The pips and centre bar of a domino showing [param top] and
## [param bottom], merged into one mesh. Each pip is a short rod through the
## slab, so it shows on both faces.
static func pips_mesh(top: int, bottom: int) -> ArrayMesh:
	var key := "pips/%d/%d" % [top, bottom]
	if not _shapes.has(key):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var circle := PackedVector2Array()
		for k in 12:
			circle.append(Vector2.from_angle(TAU * k / 12.0) * 0.046)
		var rod: ArrayMesh = ClayShapes.extrusion(circle, SLAB.z + 0.018, 0.008, 1)
		var bar: ArrayMesh = _box(Vector3(SLAB.x - 0.14, 0.035, SLAB.z + 0.016), 0.012)
		st.append_from(bar, 0, Transform3D(Basis(), Vector3(0, SLAB.y * 0.5, 0)))
		for half in 2:
			var v: int = top if half == 0 else bottom
			var cy: float = SLAB.y * (0.75 if half == 0 else 0.25)
			for p: Vector2 in _pip_spots(v):
				st.append_from(rod, 0, Transform3D(Basis(), Vector3(p.x * 0.135, cy + p.y * 0.105, 0)))
		_shapes[key] = st.commit()
	return _shapes[key]


static func _pip_spots(v: int) -> Array[Vector2]:
	var c := Vector2.ZERO
	var tl := Vector2(-1, 1)
	var tr := Vector2(1, 1)
	var bl := Vector2(-1, -1)
	var br := Vector2(1, -1)
	match v:
		1:
			return [c]
		2:
			return [tl, br]
		3:
			return [tl, c, br]
		4:
			return [tl, tr, bl, br]
		5:
			return [tl, tr, c, bl, br]
		_:
			return [tl, tr, Vector2(-1, 0), Vector2(1, 0), bl, br]


## A domino standing on its tile, its slab in [param color] with cream
## pips. The root faces +Z (turn it to the domino's facing); "Pivot" sits on
## the front bottom edge so turning it about X topples the slab forward.
## "Guide" is the groove and arrow on the floor that run to the tile it
## lands on.
static func domino(top: int, bottom: int, color: Color) -> Node3D:
	var root := Node3D.new()
	var guide := Node3D.new()
	guide.name = "Guide"
	root.add_child(guide)
	_no_shadow(Models.part(guide, _box(Vector3(0.16, 0.02, 0.9), 0.008), GROOVE, Vector3(0, 0.006, 0.5)))
	_no_shadow(Models.part(guide, floor_arrow(), color.lightened(0.15), Vector3(0, 0.014, 0.44)))
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	pivot.position = Vector3(0, 0, SLAB.z * 0.5)
	pivot.rotation.x = LEAN
	root.add_child(pivot)
	var slab := Models.part(pivot, _box(SLAB, 0.06), color, Vector3(0, SLAB.y * 0.5, -SLAB.z * 0.5))
	slab.name = "Slab"
	# A lighter rim round the top edge, so a line reads from above.
	_no_shadow(Models.part(pivot, _box(Vector3(SLAB.x - 0.04, 0.05, SLAB.z + 0.012), 0.02), color.lightened(0.35), Vector3(0, SLAB.y - 0.035, -SLAB.z * 0.5)))
	var pips := MeshInstance3D.new()
	pips.mesh = pips_mesh(top, bottom)
	pips.material_override = Models.mat(IVORY)
	pips.position = Vector3(0, 0, -SLAB.z * 0.5)
	pips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pivot.add_child(pips)
	# A gold stud in the middle of the bar.
	var stud := _no_shadow(Models.part(pivot, Models.cylinder(0.05, 0.05, SLAB.z + 0.03, 12), GOLD, Vector3(0, SLAB.y * 0.5, -SLAB.z * 0.5), 0.3))
	stud.rotation.x = PI * 0.5
	return root


# --- Critters -----------------------------------------------------------------------

## Sand Scarab: a round turquoise beetle with a gold seam and a tiny horn.
## "Mound" (on the root, not the body) is the sand ripple shown while it is
## underground.
static func scarab() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Models.part(body, Models.sphere(0.3, 0.42, 20), SHELL, Vector3(0, 0.27, -0.04))
	shell.scale = Vector3(1.0, 1.0, 1.15)
	shell.name = "Shell"
	Models.part(body, _box(Vector3(0.6, 0.08, 0.66), 0.035), SHELL_DARK, Vector3(0, 0.12, -0.04))
	_no_shadow(Models.part(body, _box(Vector3(0.05, 0.03, 0.56), 0.012), GOLD, Vector3(0, 0.48, -0.04), 0.3))
	_no_shadow(Models.part(body, Models.sphere(0.07, -1, 10), SHELL_SHINE, Vector3(-0.13, 0.42, -0.12), 0.5)).scale = Vector3(1.0, 0.6, 1.3)
	var head := Models.part(body, Models.sphere(0.17, -1, 16), BEETLE, Vector3(0, 0.24, 0.28))
	head.scale = Vector3(1.15, 0.9, 0.9)
	Models._eyes(body, 0.29, 0.39, 0.085, 0.06)
	var horn := Models.part(body, Models.cylinder(0.0, 0.035, 0.12, 8), GOLD, Vector3(0, 0.4, 0.33), 0.2)
	horn.rotation.x = 0.5
	var legs := Node3D.new()
	legs.name = "Legs"
	body.add_child(legs)
	for side: int in [-1, 1]:
		for k in 3:
			var leg := Models.part(legs, _box(Vector3(0.16, 0.05, 0.05), 0.02), BEETLE, Vector3(side * 0.31, 0.08, 0.12 - k * 0.17))
			leg.rotation.z = side * -0.35
			leg.rotation.y = side * (k - 1) * -0.35
	var mound := Node3D.new()
	mound.name = "Mound"
	mound.visible = false
	root.add_child(mound)
	var hump := Models.part(mound, Models.sphere(0.32, 0.3, 14), MOUND, Vector3(0, 0.0, 0))
	hump.scale = Vector3(1.2, 1.0, 1.3)
	hump.name = "Hump"
	_no_shadow(Models.part(mound, Models.sphere(0.17, 0.16, 10), SAND_LIGHT, Vector3(0.05, 0.09, 0.06)))
	# A gold tip of the shell peeking through the sand.
	_no_shadow(Models.part(mound, _box(Vector3(0.05, 0.05, 0.16), 0.015), GOLD, Vector3(-0.06, 0.13, -0.04), 0.3))
	for k in 4:
		var a: float = TAU * k / 4.0 + 0.4
		_no_shadow(Models.part(mound, _box(Vector3(0.1, 0.07, 0.1), 0.02), MOUND.darkened(0.1), Vector3(cos(a) * 0.36, 0.02, sin(a) * 0.36)))
	return root


## Cleopawtra: a grand sandy sphinx-cat in a striped lapis-and-gold
## headdress, a turquoise collar and a curling tail. "Head", "PawL"/"PawR"
## (front paws, pivoting at the shoulder) and "Tail" animate.
static func sphinx() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	# A sitting cat: haunches behind, chest up front.
	Models.part(body, _box(Vector3(1.0, 0.62, 0.95), 0.26), FUR, Vector3(0, 0.33, -0.3))
	Models.part(body, _box(Vector3(0.8, 0.8, 0.6), 0.25), FUR, Vector3(0, 0.55, 0.08))
	Models.part(body, _box(Vector3(0.5, 0.56, 0.12), 0.1), CREAM, Vector3(0, 0.55, 0.36))
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.3, 0.4, 0.62), 0.14), FUR_DARK, Vector3(side * 0.44, 0.22, -0.32))
	# Front paws on shoulder pivots, so one can rise for a swat.
	for side: int in [-1, 1]:
		var paw := Node3D.new()
		paw.name = "PawL" if side < 0 else "PawR"
		paw.position = Vector3(side * 0.24, 0.5, 0.2)
		body.add_child(paw)
		Models.part(paw, _box(Vector3(0.22, 0.46, 0.22), 0.09), FUR, Vector3(0, -0.24, 0.08))
		Models.part(paw, _box(Vector3(0.26, 0.14, 0.32), 0.07), CREAM, Vector3(0, -0.44, 0.16))
		for k in 3:
			_no_shadow(Models.part(paw, _box(Vector3(0.02, 0.05, 0.04), 0.008), FUR_DARK, Vector3(-0.06 + k * 0.06, -0.42, 0.32)))
	# Turquoise and gold collar.
	var collar := Models.part(body, Models.cylinder(0.42, 0.46, 0.12, 20), TURQ, Vector3(0, 0.92, 0.06))
	collar.scale = Vector3(1.0, 1.0, 0.85)
	Models.part(body, Models.cylinder(0.47, 0.47, 0.04, 20), GOLD, Vector3(0, 0.87, 0.06), 0.2).scale = Vector3(1.0, 1.0, 0.85)
	var gem := Models.part(body, _box(Vector3(0.12, 0.12, 0.05), 0.03), LAPIS, Vector3(0, 0.84, 0.44), 0.4)
	gem.rotation.z = PI * 0.25
	# Head.
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.28, 0.12)
	body.add_child(head)
	Models.part(head, _box(Vector3(0.78, 0.62, 0.62), 0.24), FUR, Vector3.ZERO)
	var muzzle := Models.part(head, Models.sphere(0.18, -1, 14), CREAM, Vector3(0, -0.13, 0.28))
	muzzle.scale = Vector3(1.5, 0.85, 0.75)
	Models.part(head, Models.sphere(0.05, -1, 8), NOSE, Vector3(0, -0.07, 0.4))
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	head.add_child(eyes)
	Models._eyes(eyes, 0.06, 0.29, 0.17, 0.085)
	# Gold eye-liner flicks, very pharaoh.
	for side: int in [-1, 1]:
		var flick := _no_shadow(Models.part(head, _box(Vector3(0.12, 0.025, 0.02), 0.008), PIP, Vector3(side * 0.29, 0.07, 0.3)))
		flick.rotation.z = side * 0.35
		for k in 2:
			var w := _no_shadow(Models.part(head, _box(Vector3(0.22, 0.012, 0.012), 0.004), CREAM, Vector3(side * 0.3, -0.13 - k * 0.05, 0.31)))
			w.rotation.z = side * (0.12 - k * 0.22)
	# The striped nemes headdress: a crown cloth, two lappets down the
	# sides of the face and a gold cobra on the brow.
	var nemes := Node3D.new()
	nemes.name = "Nemes"
	head.add_child(nemes)
	Models.part(nemes, _box(Vector3(0.62, 0.15, 0.62), 0.07), LAPIS, Vector3(0, 0.3, -0.03))
	# Gold stripes run front to back so they read from the top-down camera.
	for k in 4:
		_no_shadow(Models.part(nemes, _box(Vector3(0.06, 0.16, 0.63), 0.02), GOLD, Vector3(-0.21 + k * 0.14, 0.305, -0.03), 0.15))
	for side: int in [-1, 1]:
		var lap := Node3D.new()
		lap.position = Vector3(side * 0.44, -0.02, 0.0)
		nemes.add_child(lap)
		Models.part(lap, _box(Vector3(0.16, 0.66, 0.32), 0.06), LAPIS, Vector3(0, -0.12, 0.02))
		for k in 4:
			_no_shadow(Models.part(lap, _box(Vector3(0.17, 0.045, 0.33), 0.015), GOLD, Vector3(0, 0.12 - k * 0.15, 0.02), 0.15))
	var cobra := Models.part(nemes, _box(Vector3(0.09, 0.2, 0.06), 0.03), GOLD, Vector3(0, 0.36, 0.32), 0.3)
	cobra.rotation.x = -0.25
	Models.part(nemes, Models.sphere(0.035, -1, 8), TURQ, Vector3(0, 0.43, 0.36), 0.5)
	# Ears poking up through the cloth.
	for side: int in [-1, 1]:
		var ear := Models.part(head, Models.cylinder(0.0, 0.19, 0.4, 4), FUR, Vector3(side * 0.33, 0.52, -0.04))
		ear.rotation = Vector3(0.0, PI * 0.25, side * -0.3)
		var inner := _no_shadow(Models.part(head, Models.cylinder(0.0, 0.1, 0.24, 4), NOSE, Vector3(side * 0.33, 0.49, 0.04)))
		inner.rotation = Vector3(0.0, PI * 0.25, side * -0.3)
	# A curling tail with a dark tip.
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0.3, 0.2, -0.72)
	body.add_child(tail)
	for k in 4:
		var seg := Models.part(tail, _box(Vector3(0.13, 0.13, 0.22), 0.06), FUR if k < 3 else FUR_DARK, Vector3(0.1 * k, 0.12 * k, -0.08 * k + (0.04 * k * k)))
		seg.rotation.x = -0.4 * k
	return root


# --- Desert props --------------------------------------------------------------------

## A date palm: a ringed, gently curving trunk with drooping fronds.
static func palm(r: RandomNumberGenerator, h: float = 1.4) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.1, 0.28)
	var segs: int = 5
	var lean: float = r.randf_range(-0.12, 0.12)
	var top := Vector3.ZERO
	for k in segs:
		var y: float = h * (k + 0.5) / segs
		var at := Vector3(lean * y * y, y, 0)
		var s := Models.part(root, _box(Vector3(0.15, h / segs + 0.02, 0.15), 0.05), TRUNK if k % 2 == 0 else TRUNK_DARK, at)
		s.rotation.z = -lean * 1.6 * y
		top = Vector3(lean * h * h, h, 0)
	var fronds := Node3D.new()
	fronds.position = top
	fronds.rotation.y = r.randf() * TAU
	root.add_child(fronds)
	var n: int = 6
	for k in n:
		var a: float = TAU * k / n
		var f := Node3D.new()
		f.rotation = Vector3(0, a, 0)
		fronds.add_child(f)
		var leaf := Models.part(f, _box(Vector3(0.6, 0.04, 0.2), 0.03), PALM_A if k % 2 == 0 else PALM_B, Vector3(0.3, -0.06, 0))
		leaf.rotation.z = -0.4
		var tip := Models.part(f, _box(Vector3(0.3, 0.035, 0.14), 0.02), PALM_B if k % 2 == 0 else PALM_A, Vector3(0.62, -0.25, 0))
		tip.rotation.z = -0.9
	for k in 3:
		var a2: float = TAU * k / 3.0
		Models.part(fronds, Models.sphere(0.06, -1, 8), TRUNK_DARK, Vector3(cos(a2) * 0.08, -0.08, sin(a2) * 0.08))
	return root


## A striped tent: a ridge tent of alternating stripes with a door and a
## pennant on the ridge pole.
static func tent(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.2, 0.3)
	var stripe: Color = TENT_RED if r.randf() < 0.55 else TENT_BLUE
	var tri := PackedVector2Array([Vector2(-0.42, 0.0), Vector2(0.42, 0.0), Vector2(0.0, 0.62)])
	var key := "tent"
	if not _shapes.has(key):
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(tri, 0.04), 0.16, 0.02, 1)
	var slice: ArrayMesh = _shapes[key]
	for k in 5:
		Models.part(root, slice, stripe if k % 2 == 0 else TENT_CREAM, Vector3(0, 0, -0.32 + k * 0.16))
	var door := _no_shadow(Models.part(root, ClayShapes.extrusion(PackedVector2Array([Vector2(-0.14, 0.0), Vector2(0.14, 0.0), Vector2(0.0, 0.3)]), 0.02, 0.006, 1), PIP.lightened(0.15), Vector3(0, 0.01, 0.42)))
	door.name = "Door"
	Models.part(root, Models.cylinder(0.02, 0.02, 0.36, 6), TRUNK_DARK, Vector3(0, 0.78, 0.36))
	var flag := Models.part(root, ClayShapes.extrusion(PackedVector2Array([Vector2(0, 0), Vector2(0.2, -0.06), Vector2(0, -0.12)]), 0.02, 0.006, 1), GOLD, Vector3(0.01, 0.95, 0.36), 0.2)
	flag.name = "Flag"
	return root


## A low sand dune (two soft humps and a ripple).
static func dune(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var big := Models.part(root, Models.sphere(0.4, 0.34, 14), SAND_LIGHT.lerp(SAND, r.randf()), Vector3(0, 0.0, 0))
	big.scale = Vector3(1.4, 1.0, 1.0)
	big.rotation.y = r.randf() * TAU
	var small := Models.part(root, Models.sphere(0.24, 0.22, 12), SAND_DARK.lerp(SAND, 0.5), Vector3(r.randf_range(0.2, 0.35), 0.0, r.randf_range(-0.2, 0.2)))
	small.scale = Vector3(1.3, 1.0, 1.0)
	return root


## A terracotta pot with a turquoise band.
static func pot(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.6, 0.25)
	var s: float = r.randf_range(0.8, 1.1)
	Models.part(root, Models.sphere(0.2 * s, 0.34 * s, 14), TERRA, Vector3(0, 0.17 * s, 0))
	Models.part(root, Models.cylinder(0.1 * s, 0.13 * s, 0.12 * s, 12), TERRA, Vector3(0, 0.36 * s, 0))
	Models.part(root, Models.cylinder(0.13 * s, 0.13 * s, 0.04 * s, 12), TERRA_DARK, Vector3(0, 0.43 * s, 0))
	_no_shadow(Models.part(root, Models.cylinder(0.205 * s, 0.205 * s, 0.05 * s, 14), TURQ, Vector3(0, 0.2 * s, 0)))
	return root


## A friendly round cactus with a pink flower.
static func cactus(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.6, 0.25)
	var h: float = r.randf_range(0.5, 0.75)
	Models.part(root, _box(Vector3(0.24, h, 0.24), 0.1), CACTUS, Vector3(0, h * 0.5, 0))
	var side: float = 1.0 if r.randf() < 0.5 else -1.0
	Models.part(root, _box(Vector3(0.18, 0.12, 0.14), 0.05), CACTUS, Vector3(side * 0.17, h * 0.45, 0))
	Models.part(root, _box(Vector3(0.13, 0.24, 0.13), 0.055), CACTUS, Vector3(side * 0.24, h * 0.58, 0))
	Models.part(root, Models.sphere(0.06, -1, 8), NOSE, Vector3(0, h + 0.03, 0))
	return root


## A little stepped pyramid with a gold cap.
static func pyramid(size: float) -> Node3D:
	var root := Node3D.new()
	var steps: int = 4
	for k in steps:
		var w: float = size * (1.0 - k * 0.22)
		Models.part(root, _box(Vector3(w, size * 0.18, w), 0.04), SANDSTONE if k % 2 == 0 else SANDSTONE_DARK, Vector3(0, size * (0.09 + k * 0.18), 0))
	var cap := Models.part(root, Models.cylinder(0.0, size * 0.18, size * 0.2, 4), GOLD, Vector3(0, size * 0.82, 0), 0.25)
	cap.rotation.y = PI * 0.25
	return root


## An oasis pool: a round spring with a sandy lip.
static func pool(size: float) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(size * 0.5, size * 0.55, 0.08, 20), SAND_LIGHT, Vector3(0, 0.03, 0))
	_no_shadow(Models.part(root, Models.cylinder(size * 0.42, size * 0.42, 0.06, 20), WATER, Vector3(0, 0.06, 0), 0.25))
	return root

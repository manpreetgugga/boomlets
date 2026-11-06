extends RefCounted
## Models for World 17, Paint Plaza: paint tubs that dye Pip's blasts, paint
## crates and canvas gates that only give way to their own colour, floor
## splats, the chameleon Paint Blobs, Brushbot the painter robot, Pip's beret
## and the sunny artists'-square props (easels, café tables, striped stalls,
## planters, lamp posts). Built from crisp, slightly rounded clay blocks like
## render/Models.gd.
##
## Paint colours are passed around as an index: 0 red, 1 yellow, 2 blue.
## Every painted thing also carries a cream symbol for its colour (red a
## dot, yellow a triangle, blue a square), so the colours never rely on hue
## alone.

const RED := Color("#F0475A")
const YELLOW := Color("#FFC21F")
const BLUE := Color("#3B86F0")
const PAINTS: Array[Color] = [RED, YELLOW, BLUE]
const PAINT_NAMES: Array[String] = ["red", "yellow", "blue"]
## Blast colours: the tumbling cubes and their white-hot cores.
const FLAME_ARM: Array[Color] = [Color("#FF3550"), Color("#FFC414"), Color("#2C7DFF")]
const FLAME_CORE: Array[Color] = [Color("#FFD0D7"), Color("#FFF7CC"), Color("#D2EAFF")]

const CREAM := Color("#FFF4DE")
const CANVAS := Color("#FBF6EC")
const WOOD := Color("#B07A48")
const WOOD_DARK := Color("#7E5232")
const WOOD_LIGHT := Color("#D8A86E")
const METAL := Color("#D5DAE3")
const METAL_DARK := Color("#7C8396")
const TERRACOTTA := Color("#D9774B")
const TERRA_DARK := Color("#B85F38")
const LEAF := Color("#5DB060")
const LEAF_DARK := Color("#46934C")
const INK := Color("#2E2A44")
const LAMP := Color("#3E5F55")
const GLOW := Color("#FFE7A6")
## Awning and umbrella stripes: soft hues that never pass for paint colours.
const AWNINGS: Array[Color] = [Color("#6FCFAE"), Color("#B79BEA"), Color("#8FD3E8"), Color("#C9B08A")]
const FLOWERS: Array[Color] = [Color("#FF8FB1"), Color("#FFFFFF"), Color("#FFB347"), Color("#C792EA"), Color("#FF6F91")]
const BOSS_SIZE: float = 1.4

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _flat(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, glow: float = 0.0) -> MeshInstance3D:
	var mi := Models.part(parent, mesh, color, pos, glow)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Marks a mesh as painted, so tint() can recolour it later.
static func _paint(mi: MeshInstance3D, shade: float = 0.0, glow: float = 0.0) -> MeshInstance3D:
	mi.set_meta(&"paint", Vector2(shade, glow))
	return mi


## Recolours every painted mesh under [param root] in paint [param idx].
static func tint(root: Node, idx: int) -> void:
	for ch: Node in root.get_children():
		if ch is MeshInstance3D and ch.has_meta(&"paint"):
			var sg: Vector2 = ch.get_meta(&"paint")
			var c: Color = PAINTS[idx]
			if sg.x > 0.0:
				c = c.lightened(sg.x)
			elif sg.x < 0.0:
				c = c.darkened(-sg.x)
			(ch as MeshInstance3D).material_override = Models.mat(c, sg.y)
		tint(ch, idx)


## The colour symbol, standing upright in the xy plane (dot, triangle or
## square) about [param size] across.
static func symbol_mesh(idx: int, size: float) -> Mesh:
	var key := "sym/%d/%.2f" % [idx, size]
	if not _shapes.has(key):
		var h: float = size * 0.5
		var pts: PackedVector2Array
		match idx:
			0:
				pts = PackedVector2Array()
				for k in 16:
					var a: float = TAU * k / 16.0
					pts.append(Vector2(cos(a), sin(a)) * h)
			1:
				pts = PackedVector2Array([Vector2(-h * 1.05, -h * 0.85), Vector2(h * 1.05, -h * 0.85), Vector2(0, h * 1.0)])
			_:
				pts = PackedVector2Array([Vector2(-h * 0.85, -h * 0.85), Vector2(h * 0.85, -h * 0.85), Vector2(h * 0.85, h * 0.85), Vector2(-h * 0.85, h * 0.85)])
		_shapes[key] = ClayShapes.extrusion(pts, 0.03, 0.008, 1)
	return _shapes[key]


## A symbol lying flat (facing up) at [param pos].
static func symbol_flat(parent: Node3D, idx: int, size: float, color: Color, pos: Vector3) -> MeshInstance3D:
	var mi := _flat(parent, symbol_mesh(idx, size), color, pos)
	mi.rotation.x = -PI * 0.5
	return mi


## A flat paint splat on the floor: a round puddle with lobes and droplets.
static func splat_shape(parent: Node3D, color: Color, size: float, r: RandomNumberGenerator, y: float = 0.012) -> void:
	_flat(parent, Models.cylinder(size, size, 0.02, 20), color, Vector3(0, y, 0))
	var lobes: int = r.randi_range(5, 7)
	for k in lobes:
		var a: float = TAU * k / lobes + r.randf_range(-0.3, 0.3)
		var d: float = size * r.randf_range(0.65, 0.95)
		var lr: float = size * r.randf_range(0.28, 0.42)
		_flat(parent, Models.cylinder(lr, lr, 0.02, 14), color, Vector3(cos(a) * d, y + 0.002, sin(a) * d))
	for k in r.randi_range(3, 5):
		var a2: float = r.randf() * TAU
		var d2: float = size * r.randf_range(1.25, 1.6)
		var dr: float = size * r.randf_range(0.08, 0.15)
		_flat(parent, Models.cylinder(dr, dr, 0.02, 8), color, Vector3(cos(a2) * d2, y, sin(a2) * d2))


## A floor splat that recolours Paint Blobs walking through it.
static func splat(idx: int, r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var holder := Node3D.new()
	holder.name = "Splat"
	root.add_child(holder)
	splat_shape(holder, PAINTS[idx], 0.3, r)
	# A glossy highlight and the colour symbol.
	_flat(holder, Models.cylinder(0.08, 0.08, 0.02, 10), PAINTS[idx].lightened(0.45), Vector3(-0.1, 0.02, -0.1))
	symbol_flat(holder, idx, 0.16, CREAM, Vector3(0.04, 0.03, 0.04))
	return root


## A paint tub sunk in the plaza: step in to dye Pip's blasts. "Paint" is
## the surface (it wobbles), "Brush" leans on the rim.
static func tub(idx: int, r: RandomNumberGenerator) -> Node3D:
	var col: Color = PAINTS[idx]
	var root := Node3D.new()
	var under := Node3D.new()
	root.add_child(under)
	splat_shape(under, col.darkened(0.05), 0.4, r, 0.008)
	Models.part(root, Models.cylinder(0.42, 0.45, 0.12, 24), METAL, Vector3(0, 0.06, 0))
	Models.part(root, Models.cylinder(0.44, 0.44, 0.03, 24), METAL_DARK.lightened(0.25), Vector3(0, 0.11, 0))
	var paint := Models.part(root, Models.cylinder(0.39, 0.39, 0.04, 24), col, Vector3(0, 0.15, 0), 0.25)
	paint.name = "Paint"
	# A glossy swirl and the colour symbol on the paint.
	_flat(paint, Models.cylinder(0.1, 0.1, 0.012, 12), col.lightened(0.45), Vector3(-0.15, 0.012, -0.12), 0.2)
	symbol_flat(paint, idx, 0.22, CREAM, Vector3(0.05, 0.02, 0.05))
	# Drips over the rim.
	for k in 4:
		var a: float = TAU * (k + 0.3) / 4.0 + r.randf_range(-0.3, 0.3)
		var drip := Models.part(root, _box(Vector3(0.07, 0.09, 0.03), 0.014), col, Vector3(cos(a) * 0.42, 0.09, sin(a) * 0.42))
		drip.rotation.y = -a + PI * 0.5
	# A brush leaning on the rim.
	var brush := Node3D.new()
	brush.name = "Brush"
	brush.position = Vector3(0.28, 0.12, -0.18)
	brush.rotation = Vector3(0.0, 0.6, -0.75)
	root.add_child(brush)
	Models.part(brush, Models.cylinder(0.022, 0.026, 0.48, 8), WOOD_LIGHT, Vector3(0, 0.26, 0))
	Models.part(brush, Models.cylinder(0.035, 0.03, 0.08, 10), METAL, Vector3(0, 0.0, 0))
	Models.part(brush, Models.sphere(0.04, 0.12, 10), col, Vector3(0, -0.07, 0))
	return root


## A paint crate: a sturdy painted crate in one colour with cream corner
## posts, a fat dollop of paint on top and the colour symbol. Only a blast
## of the same colour breaks it. "Body" holds it all.
static func paint_crate(idx: int, r: RandomNumberGenerator) -> Node3D:
	var col: Color = PAINTS[idx]
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, _box(Vector3(0.78, 0.7, 0.78), 0.05), col, Vector3(0, 0.36, 0))
	# Slats across the front and sides.
	for k in 2:
		var y: float = 0.22 + k * 0.28
		Models.part(body, _box(Vector3(0.8, 0.06, 0.8), 0.02), col.darkened(0.14), Vector3(0, y, 0))
	for sx: float in [-0.37, 0.37]:
		for sz: float in [-0.37, 0.37]:
			Models.part(body, _box(Vector3(0.11, 0.74, 0.11), 0.03), CREAM, Vector3(sx, 0.37, sz))
	for sz2: float in [-0.37, 0.37]:
		Models.part(body, _box(Vector3(0.8, 0.08, 0.1), 0.025), CREAM, Vector3(0, 0.71, sz2))
	for sx2: float in [-0.37, 0.37]:
		Models.part(body, _box(Vector3(0.1, 0.08, 0.8), 0.025), CREAM, Vector3(sx2, 0.71, 0))
	# The dollop and drips.
	var top := Models.part(body, Models.sphere(0.26, 0.14, 18), col.lightened(0.12), Vector3(0.0, 0.74, 0.0))
	top.scale = Vector3(1.0, 1.0, 0.9)
	Models.part(body, Models.sphere(0.12, 0.12, 12), col.lightened(0.12), Vector3(0.1, 0.8, -0.05))
	for k in 3:
		var a: float = r.randf() * TAU
		var dl: float = r.randf_range(0.12, 0.26)
		Models.part(body, _box(Vector3(0.07, dl, 0.03), 0.014), col.lightened(0.12), Vector3(cos(a) * 0.12, 0.72 - dl * 0.5, 0.4))
	symbol_flat(body, idx, 0.24, CREAM, Vector3(0.0, 0.82, 0.02))
	# A symbol on the front face too.
	var front := _flat(body, symbol_mesh(idx, 0.22), CREAM, Vector3(0, 0.36, 0.4))
	front.rotation = Vector3.ZERO
	return root


## A canvas gate standing in a gap of the wall: two wooden easel posts and a
## big painted canvas ("Panel", pivoting at its foot). A blast of its own
## colour knocks the canvas flat like a rug, and the way is open.
static func gate(idx: int) -> Node3D:
	var col: Color = PAINTS[idx]
	var root := Node3D.new()
	for sx: float in [-0.44, 0.44]:
		Models.part(root, _box(Vector3(0.1, 1.0, 0.16), 0.03), WOOD_DARK, Vector3(sx, 0.5, 0))
		Models.part(root, Models.sphere(0.07, -1, 10), col, Vector3(sx, 1.04, 0))
	# The canvas leans back a little, like a painting on an easel, so its
	# face shows from above.
	var panel := Node3D.new()
	panel.name = "Panel"
	panel.position = Vector3(0, 0.04, 0.08)
	panel.rotation.x = -0.3
	root.add_child(panel)
	Models.part(panel, _box(Vector3(0.8, 0.86, 0.08), 0.02), CANVAS, Vector3(0, 0.45, 0))
	Models.part(panel, _box(Vector3(0.84, 0.06, 0.1), 0.02), WOOD_LIGHT, Vector3(0, 0.03, 0))
	Models.part(panel, _box(Vector3(0.84, 0.06, 0.1), 0.02), WOOD_LIGHT, Vector3(0, 0.88, 0))
	Models.part(panel, _box(Vector3(0.66, 0.68, 0.1), 0.03), col, Vector3(0, 0.45, 0.004))
	# Brushstroke swirls and the symbol on the canvas.
	Models.part(panel, _box(Vector3(0.5, 0.06, 0.11), 0.03), col.lightened(0.3), Vector3(-0.04, 0.68, 0.006)).rotation.z = 0.15
	Models.part(panel, _box(Vector3(0.36, 0.05, 0.11), 0.025), col.darkened(0.15), Vector3(0.08, 0.2, 0.006)).rotation.z = -0.2
	var sym := _flat(panel, symbol_mesh(idx, 0.3), CREAM, Vector3(0, 0.45, 0.06))
	sym.rotation = Vector3.ZERO
	var sym2 := _flat(panel, symbol_mesh(idx, 0.3), CREAM, Vector3(0, 0.45, -0.06))
	sym2.rotation = Vector3.ZERO
	return root


## A Paint Blob: a gooey drop of paint with a curly chameleon tail and big
## eyes. Its colour is the one blast colour that pops it.
static func blob(idx: int) -> Node3D:
	var col: Color = PAINTS[idx]
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var skin := _paint(Models.part(body, Models.sphere(0.3, 0.5, 22), col, Vector3(0, 0.26, 0)), 0.0, 0.08)
	skin.scale = Vector3(1.0, 1.0, 0.95)
	_paint(Models.part(body, Models.cylinder(0.0, 0.16, 0.22, 14), col, Vector3(0, 0.56, -0.02)), 0.0, 0.08)
	_paint(Models.part(body, Models.sphere(0.2, 0.3, 16), col.lightened(0.35), Vector3(0, 0.2, 0.13)), 0.35).scale = Vector3(1.0, 1.0, 0.6)
	# Drippy little feet.
	for k in 3:
		var a: float = PI * 0.5 + (k - 1) * 1.2
		_paint(Models.part(body, Models.sphere(0.09, 0.1, 10), col.darkened(0.08), Vector3(cos(a) * 0.22, 0.04, sin(a) * 0.22)), -0.08)
	# The curly tail.
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.2, -0.24)
	body.add_child(tail)
	for k in 5:
		var a2: float = k * 0.9
		var rr: float = 0.13 - k * 0.018
		_paint(Models.part(tail, Models.sphere(0.06 - k * 0.007, -1, 10), col if k % 2 == 0 else col.darkened(0.12), Vector3(0, rr * sin(a2) + 0.04, -0.06 - rr * (1.0 - cos(a2)) * 0.8)), 0.0 if k % 2 == 0 else -0.12)
	Models._eyes(body, 0.36, 0.22, 0.11, 0.08)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.04, -1, 8), Color("#FFFFFF").lerp(Color("#FF9AA8"), 0.7), Vector3(side * 0.2, 0.24, 0.23))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	_no_shadow(Models.part(body, Models.sphere(0.06, -1, 8), Color.WHITE, Vector3(-0.12, 0.44, 0.12), 0.6))
	return root


## Pip's beret, in the colour his blasts are dyed.
static func beret(idx: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Beret"
	var cap := _paint(Models.part(root, Models.sphere(0.22, 0.1, 18), PAINTS[idx], Vector3(0, 0.0, 0), 0.1), 0.0, 0.1)
	cap.scale = Vector3(1.0, 1.0, 0.95)
	_paint(Models.part(root, Models.cylinder(0.19, 0.19, 0.03, 18), PAINTS[idx], Vector3(0, -0.03, 0)), -0.2)
	_paint(Models.part(root, Models.cylinder(0.015, 0.025, 0.06, 6), PAINTS[idx], Vector3(0.02, 0.06, 0)), -0.2)
	return root


## Brushbot, the boss: a boxy painter robot on a wheeled cart with a screen
## face and a curly moustache, a beret, a palette in one hand and a giant
## brush in the other. Painted parts show its current colour; "Brush",
## "Palette", "Head" and "Bulb" are animated.
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	var shell := Color("#EDE6DA")
	# Cart and wheels.
	Models.part(body, _box(Vector3(0.95, 0.22, 0.8), 0.06), Color("#5B6175"), Vector3(0, 0.2, 0))
	for sx: float in [-0.42, 0.42]:
		for sz: float in [-0.3, 0.3]:
			var wheel := Models.part(body, Models.cylinder(0.13, 0.13, 0.1, 14), INK, Vector3(sx, 0.13, sz))
			wheel.rotation.z = PI * 0.5
			var hub := Models.part(body, Models.cylinder(0.05, 0.05, 0.11, 8), METAL, Vector3(sx, 0.13, sz))
			hub.rotation.z = PI * 0.5
	# Torso with a painted chest panel.
	_paint(Models.part(body, _box(Vector3(0.82, 0.62, 0.66), 0.1), RED.lightened(0.15), Vector3(0, 0.6, 0)), 0.15)
	# A cream painter's smock collar over the shoulders.
	Models.part(body, _box(Vector3(0.86, 0.1, 0.7), 0.05), shell, Vector3(0, 0.88, 0))
	Models.part(body, _box(Vector3(0.5, 0.32, 0.06), 0.03), shell, Vector3(0, 0.6, 0.32))
	for k in 3:
		Models.part(body, Models.sphere(0.04, -1, 8), PAINTS[k], Vector3(-0.15 + k * 0.15, 0.6, 0.36), 0.3)
	# Splatters on the shell.
	for p: Vector3 in [Vector3(-0.38, 0.45, 0.2), Vector3(0.3, 0.75, -0.2), Vector3(0.41, 0.42, 0.1)]:
		_paint(Models.part(body, Models.sphere(0.06, 0.03, 8), RED, p), 0.1).rotation.z = PI * 0.5
	# Head: a screen face, eyes, moustache, beret and antenna.
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 1.13, 0)
	body.add_child(head)
	Models.part(head, _box(Vector3(0.62, 0.44, 0.5), 0.08), shell, Vector3.ZERO)
	Models.part(head, _box(Vector3(0.5, 0.3, 0.04), 0.04), INK, Vector3(0, 0.02, 0.25))
	for side: int in [-1, 1]:
		var eye := _no_shadow(Models.part(head, Models.sphere(0.055, 0.09, 10), Color("#BFF4FF"), Vector3(side * 0.12, 0.06, 0.27), 1.6)) as MeshInstance3D
		eye.scale = Vector3(1.0, 1.0, 0.4)
		var tash := Models.part(head, Models.sphere(0.08, 0.06, 10), INK, Vector3(side * 0.08, -0.17, 0.27))
		tash.scale = Vector3(1.3, 1.0, 0.7)
		tash.rotation.z = side * 0.35
		var curl := Models.part(head, Models.sphere(0.035, -1, 8), INK, Vector3(side * 0.18, -0.13, 0.27))
		curl.scale = Vector3(1.0, 1.0, 0.7)
	for side2: int in [-1, 1]:
		var ear := Models.part(head, Models.cylinder(0.08, 0.08, 0.06, 12), METAL_DARK, Vector3(side2 * 0.33, 0.0, 0))
		ear.rotation.z = PI * 0.5
	var beret_node := beret(0)
	beret_node.position = Vector3(-0.06, 0.27, -0.02)
	beret_node.rotation.z = 0.25
	beret_node.scale = Vector3.ONE * 1.4
	head.add_child(beret_node)
	Models.part(head, Models.cylinder(0.012, 0.012, 0.26, 6), METAL_DARK, Vector3(0.2, 0.33, 0))
	var bulb := _paint(Models.part(head, Models.sphere(0.055, -1, 10), RED, Vector3(0.2, 0.48, 0), 1.2), 0.15, 1.2)
	bulb.name = "Bulb"
	# Palette arm (left).
	var pal := Node3D.new()
	pal.name = "Palette"
	pal.position = Vector3(-0.58, 0.75, 0.12)
	body.add_child(pal)
	Models.part(pal, _box(Vector3(0.3, 0.1, 0.1), 0.04), METAL_DARK, Vector3(0.15, -0.05, 0))
	var board := Models.part(pal, Models.cylinder(0.3, 0.3, 0.04, 20), WOOD_LIGHT, Vector3(-0.12, 0.05, 0.05))
	board.rotation.x = 0.9
	board.scale = Vector3(1.2, 1.0, 0.9)
	for k2 in 3:
		var a: float = -0.9 + k2 * 0.9
		var dab := Models.part(pal, Models.sphere(0.07, 0.06, 10), PAINTS[k2], Vector3(-0.12 + cos(a) * 0.22, 0.12 + sin(a) * 0.1, 0.1 + sin(a) * 0.05), 0.2)
		dab.rotation.x = 0.9
	# Brush arm (right): a giant brush held up high.
	var brush := Node3D.new()
	brush.name = "Brush"
	brush.position = Vector3(0.5, 0.7, 0.1)
	brush.rotation.z = -0.45
	body.add_child(brush)
	Models.part(brush, _box(Vector3(0.24, 0.1, 0.1), 0.04), METAL_DARK, Vector3(0.0, 0, 0))
	Models.part(brush, Models.cylinder(0.04, 0.05, 1.0, 10), WOOD, Vector3(0.1, 0.4, 0))
	Models.part(brush, Models.cylinder(0.075, 0.06, 0.14, 12), METAL, Vector3(0.1, 0.95, 0))
	var tip := _paint(Models.part(brush, Models.sphere(0.1, 0.32, 14), RED, Vector3(0.1, 1.14, 0), 0.25), 0.0, 0.25)
	tip.name = "Tip"
	return root


static func paint_ball(idx: int) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.sphere(0.2, 0.36, 14), PAINTS[idx], Vector3.ZERO, 0.3)
	_no_shadow(Models.part(root, Models.sphere(0.06, -1, 8), Color.WHITE, Vector3(-0.07, 0.08, 0.07), 0.6))
	return root


## The ring that marks where a paint ball will land; "Disc" fills in.
static func warning(idx: int) -> Node3D:
	var root := Node3D.new()
	_flat(root, Models.cylinder(0.46, 0.46, 0.012, 24), PAINTS[idx].darkened(0.25), Vector3(0, 0.02, 0))
	_flat(root, Models.cylinder(0.39, 0.39, 0.014, 24), CREAM, Vector3(0, 0.024, 0))
	var disc := _flat(root, Models.cylinder(0.39, 0.39, 0.016, 24), PAINTS[idx], Vector3(0, 0.028, 0), 0.3)
	disc.name = "Disc"
	return root


# --- Props ---------------------------------------------------------------------------

## An artist's easel with a cheerful little painting on it.
static func easel(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for side: int in [-1, 1]:
		var leg := Models.part(root, _box(Vector3(0.05, 1.05, 0.05), 0.015), WOOD, Vector3(side * 0.2, 0.5, 0.04))
		leg.rotation.z = side * 0.14
		leg.rotation.x = -0.08
	var back := Models.part(root, _box(Vector3(0.05, 1.0, 0.05), 0.015), WOOD_DARK, Vector3(0, 0.48, -0.2))
	back.rotation.x = 0.3
	Models.part(root, _box(Vector3(0.56, 0.04, 0.08), 0.015), WOOD, Vector3(0, 0.42, 0.08))
	var canvas := Node3D.new()
	canvas.position = Vector3(0, 0.7, 0.07)
	canvas.rotation.x = -0.1
	root.add_child(canvas)
	Models.part(canvas, _box(Vector3(0.56, 0.44, 0.04), 0.012), CANVAS, Vector3.ZERO)
	# A sky, a hill and a sun (or some bold blocks of colour).
	if r.randf() < 0.5:
		Models.part(canvas, _box(Vector3(0.5, 0.2, 0.045), 0.01), Color("#8FD0F5"), Vector3(0, 0.1, 0.002))
		Models.part(canvas, _box(Vector3(0.5, 0.18, 0.045), 0.01), LEAF, Vector3(0, -0.1, 0.002))
		Models.part(canvas, Models.sphere(0.06, -1, 10), YELLOW, Vector3(0.14, 0.12, 0.03))
	else:
		for k in 4:
			var c: Color = [RED, YELLOW, BLUE, AWNINGS[r.randi() % AWNINGS.size()]][k]
			Models.part(canvas, _box(Vector3(r.randf_range(0.12, 0.22), r.randf_range(0.1, 0.18), 0.045), 0.012), c, Vector3(r.randf_range(-0.16, 0.16), r.randf_range(-0.12, 0.12), 0.002 + k * 0.002))
	# A paint pot at its feet.
	var pot := Models.part(root, Models.cylinder(0.07, 0.07, 0.1, 10), METAL, Vector3(0.24, 0.05, 0.2))
	Models.part(pot, Models.cylinder(0.062, 0.062, 0.02, 10), PAINTS[r.randi() % 3], Vector3(0, 0.05, 0))
	return root


## A round café table with two chairs under a striped umbrella.
static func cafe_table(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var stripe: Color = AWNINGS[r.randi() % AWNINGS.size()]
	Models.part(root, Models.cylinder(0.24, 0.24, 0.04, 16), CREAM, Vector3(0, 0.46, 0))
	Models.part(root, Models.cylinder(0.025, 0.025, 0.44, 8), INK, Vector3(0, 0.23, 0))
	Models.part(root, Models.cylinder(0.12, 0.14, 0.03, 12), INK, Vector3(0, 0.015, 0))
	for side: int in [-1, 1]:
		var chair := Node3D.new()
		chair.position = Vector3(side * 0.36, 0, 0.05 * side)
		chair.rotation.y = side * PI * 0.5
		root.add_child(chair)
		Models.part(chair, _box(Vector3(0.24, 0.04, 0.24), 0.015), stripe.darkened(0.1), Vector3(0, 0.28, 0))
		Models.part(chair, _box(Vector3(0.24, 0.24, 0.04), 0.015), stripe.darkened(0.1), Vector3(0, 0.42, 0.11))
		for lx: float in [-0.1, 0.1]:
			for lz: float in [-0.1, 0.1]:
				Models.part(chair, Models.cylinder(0.014, 0.014, 0.28, 6), INK, Vector3(lx, 0.14, lz))
	# A coffee cup and the umbrella.
	Models.part(root, Models.cylinder(0.035, 0.03, 0.05, 8), Color.WHITE, Vector3(0.08, 0.5, 0.04))
	Models.part(root, Models.cylinder(0.015, 0.015, 0.95, 6), WOOD_DARK, Vector3(0, 0.9, 0))
	var umb := Node3D.new()
	umb.position = Vector3(0, 1.32, 0)
	root.add_child(umb)
	for k in 8:
		var a: float = TAU * k / 8.0
		var slat := Node3D.new()
		slat.rotation.y = a
		umb.add_child(slat)
		var panel := Models.part(slat, _box(Vector3(0.24, 0.025, 0.5), 0.01), stripe if k % 2 == 0 else Color.WHITE, Vector3(0, -0.1, 0.24))
		panel.rotation.x = 0.38
	Models.part(umb, Models.sphere(0.04, -1, 8), stripe, Vector3(0, 0.03, 0))
	return root


## A market stall with a striped awning and paint pots on the counter.
static func stall(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var stripe: Color = AWNINGS[r.randi() % AWNINGS.size()]
	Models.part(root, _box(Vector3(0.9, 0.42, 0.42), 0.04), WOOD_LIGHT, Vector3(0, 0.21, 0))
	Models.part(root, _box(Vector3(0.94, 0.05, 0.46), 0.02), WOOD, Vector3(0, 0.44, 0))
	for sx: float in [-0.43, 0.43]:
		Models.part(root, Models.cylinder(0.025, 0.025, 1.1, 6), WOOD_DARK, Vector3(sx, 0.55, -0.18))
	for k in 6:
		var s := Models.part(root, _box(Vector3(0.17, 0.03, 0.6), 0.01), stripe if k % 2 == 0 else Color.WHITE, Vector3(-0.425 + k * 0.17, 1.05, 0.02))
		s.rotation.x = 0.35
	for k2 in 4:
		var pot := Models.part(root, Models.cylinder(0.06, 0.06, 0.09, 10), METAL, Vector3(-0.3 + k2 * 0.2, 0.51, r.randf_range(-0.05, 0.08)))
		Models.part(pot, Models.cylinder(0.054, 0.054, 0.02, 10), [RED, YELLOW, BLUE, stripe][k2], Vector3(0, 0.045, 0))
	return root


## A terracotta planter with a round shrub and flowers.
static func planter(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.22, 0.17, 0.3, 14), TERRACOTTA, Vector3(0, 0.15, 0))
	Models.part(root, Models.cylinder(0.24, 0.24, 0.05, 14), TERRA_DARK, Vector3(0, 0.3, 0))
	var bush := Models.part(root, Models.sphere(0.24, 0.4, 14), LEAF, Vector3(0, 0.48, 0))
	bush.scale = Vector3(1.0, 1.0, 1.0) * r.randf_range(0.9, 1.15)
	for k in 6:
		var a: float = r.randf() * TAU
		var e: float = r.randf_range(0.2, 1.1)
		Models.part(root, Models.sphere(0.045, -1, 8), FLOWERS[r.randi() % FLOWERS.size()], Vector3(cos(a) * 0.2 * cos(e * 0.6), 0.48 + sin(e) * 0.18, sin(a) * 0.2 * cos(e * 0.6)))
	return root


## A little potted topiary tree.
static func topiary(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.36, 0.3, 0.36), 0.04), TERRACOTTA, Vector3(0, 0.15, 0))
	Models.part(root, Models.cylinder(0.03, 0.04, 0.6, 6), WOOD_DARK, Vector3(0, 0.55, 0))
	Models.part(root, Models.sphere(0.3, 0.56, 16), LEAF_DARK, Vector3(0, 1.0, 0))
	for k in 4:
		var a: float = r.randf() * TAU
		Models.part(root, Models.sphere(0.05, -1, 8), Color("#FFB347"), Vector3(cos(a) * 0.26, 1.0 + r.randf_range(-0.1, 0.15), sin(a) * 0.26))
	return root


## A dark green lamp post with a glowing lantern.
static func lamp_post() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.11, 0.14, 0.12, 12), LAMP, Vector3(0, 0.06, 0))
	Models.part(root, Models.cylinder(0.035, 0.045, 1.3, 8), LAMP, Vector3(0, 0.75, 0))
	Models.part(root, Models.cylinder(0.12, 0.09, 0.05, 8), LAMP, Vector3(0, 1.42, 0))
	_no_shadow(Models.part(root, Models.cylinder(0.08, 0.1, 0.2, 8), GLOW, Vector3(0, 1.55, 0), 2.2))
	Models.part(root, Models.cylinder(0.0, 0.14, 0.1, 8), LAMP, Vector3(0, 1.7, 0))
	return root


## A heap of paint tins and a rag.
static func paint_pots(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(2, 4):
		var a: float = r.randf() * TAU
		var d: float = r.randf_range(0.0, 0.16)
		var h: float = r.randf_range(0.1, 0.16)
		var pot := Models.part(root, Models.cylinder(0.08, 0.08, h, 12), METAL, Vector3(cos(a) * d, h * 0.5, sin(a) * d))
		var col: Color = [RED, YELLOW, BLUE, AWNINGS[r.randi() % AWNINGS.size()]][r.randi() % 4]
		Models.part(pot, Models.cylinder(0.072, 0.072, 0.02, 12), col, Vector3(0, h * 0.5, 0))
		Models.part(pot, _box(Vector3(0.162, h * 0.4, 0.162), 0.03), col, Vector3(0, 0, 0)).scale = Vector3(1.0, 1.0, 1.0)
	return root


## A small fountain for the far-off islands.
static func fountain() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.7, 0.75, 0.25, 24), CREAM.darkened(0.08), Vector3(0, 0.12, 0))
	_no_shadow(Models.part(root, Models.cylinder(0.62, 0.62, 0.04, 24), Color("#7CC8F0"), Vector3(0, 0.22, 0), 0.2))
	Models.part(root, Models.cylinder(0.1, 0.14, 0.6, 12), CREAM.darkened(0.08), Vector3(0, 0.5, 0))
	Models.part(root, Models.cylinder(0.32, 0.22, 0.1, 16), CREAM.darkened(0.08), Vector3(0, 0.82, 0))
	_no_shadow(Models.part(root, Models.sphere(0.16, 0.3, 12), Color("#BDE8FF"), Vector3(0, 0.95, 0), 0.4))
	return root

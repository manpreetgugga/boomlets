extends RefCounted
## Models for World 5, Neon Nightway: light gates and their switches, the
## Zapper robot, Gigabolt the boss and the little night-city props. Built
## from crisp, slightly rounded clay blocks with emissive neon parts, the
## same way render/Models.gd builds everything else.

const GOLD := Color("#FFC53D")
const PINK := Color("#FF4FB8")
const CYAN := Color("#3FE6FF")
const LIME := Color("#B6FF5C")
const VIOLET := Color("#B07BFF")
const CHROME := Color("#D9DDF7")
const CHROME_DARK := Color("#7D84B8")
const STEEL := Color("#2A2F66")
const NIGHT := Color("#1B1E47")
const WARM := Color("#FFE2A8")
const CORAL := Color("#FF8A5C")
const BOSS_RED := Color("#FF5F6D")
const BOSS_SIZE: float = 1.2
## The Zapper is drawn a little bigger than its parts are built.
const ZAP_SIZE: float = 1.15

## Gate / switch colours, by colour index (0 gold, 1 pink).
const GATE_COLORS: Array[Color] = [GOLD, PINK]

static var _shapes: Dictionary = {}


# --- Shapes ---------------------------------------------------------------------

static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


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


## A flat heart in the xy plane.
static func heart_mesh(size: float, depth: float) -> ArrayMesh:
	var key := "heart/%.3f/%.3f" % [size, depth]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 24:
			var t: float = TAU * k / 24.0
			pts.append(Vector2(16.0 * pow(sin(t), 3.0), 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * size / 16.0)
		_shapes[key] = ClayShapes.extrusion(pts, depth, depth * 0.3, 1)
	return _shapes[key]


## A flat lightning bolt in the xy plane.
static func bolt_mesh(size: float, depth: float) -> ArrayMesh:
	var key := "bolt/%.3f/%.3f" % [size, depth]
	if not _shapes.has(key):
		var pts := PackedVector2Array([Vector2(0.04, 0.17), Vector2(-0.1, -0.01), Vector2(-0.01, -0.01), Vector2(-0.05, -0.17), Vector2(0.1, 0.03), Vector2(0.01, 0.03)])
		for i in pts.size():
			pts[i] *= size / 0.17
		_shapes[key] = ClayShapes.extrusion(pts, depth, depth * 0.3, 1)
	return _shapes[key]


static func icon_mesh(color_index: int, size: float, depth: float) -> ArrayMesh:
	return star_mesh(size, depth) if color_index == 0 else heart_mesh(size, depth)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- Gates and switches -----------------------------------------------------------

## A light gate: a dark floor frame with a glowing outline and four chrome
## corner posts, plus a "Field" (glass light block wrapped in neon bands)
## that rises out of the floor when the gate is shut. Scale Field's y from
## 0 (open) to 1 (shut).
static func gate(ci: int) -> Node3D:
	var color: Color = GATE_COLORS[ci]
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.94, 0.06, 0.94), 0.02), NIGHT, Vector3(0, 0.01, 0))
	for k in 4:
		var horizontal: bool = k < 2
		var s: float = -1.0 if k % 2 == 0 else 1.0
		var bar := Models.part(root, _box(Vector3(0.78, 0.04, 0.06) if horizontal else Vector3(0.06, 0.04, 0.78), 0.015), color, Vector3(0, 0.05, s * 0.4) if horizontal else Vector3(s * 0.4, 0.05, 0), 1.3)
		_no_shadow(bar)
	for sx: float in [-0.42, 0.42]:
		for sz: float in [-0.42, 0.42]:
			Models.part(root, _box(Vector3(0.1, 0.86, 0.1), 0.03), CHROME_DARK, Vector3(sx, 0.43, sz))
			var cap := Models.part(root, _box(Vector3(0.13, 0.08, 0.13), 0.03), color, Vector3(sx, 0.88, sz), 1.6)
			_no_shadow(cap)
	var field := Node3D.new()
	field.name = "Field"
	root.add_child(field)
	var glass := MeshInstance3D.new()
	glass.mesh = _box(Vector3(0.74, 0.78, 0.74), 0.06)
	glass.material_override = Models.glass(color, 0.45, 0.55)
	glass.position.y = 0.41
	field.add_child(_no_shadow(glass))
	for y: float in [0.16, 0.42, 0.68]:
		_no_shadow(Models.part(field, _box(Vector3(0.8, 0.055, 0.8), 0.02), color.lightened(0.25), Vector3(0, y, 0), 1.7))
	var icon := Models.part(field, icon_mesh(ci, 0.2, 0.05), color.lightened(0.55), Vector3(0, 0.82, 0), 1.6)
	icon.rotation.x = -PI * 0.5
	_no_shadow(icon)
	return root


## A floor switch: a dark plate, a glowing ring and a round button in the
## gate colour with the colour's icon (gold star, pink heart) on top.
static func switch(ci: int) -> Node3D:
	var color: Color = GATE_COLORS[ci]
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.76, 0.07, 0.76), 0.03), STEEL, Vector3(0, 0.02, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.28
	ring.outer_radius = 0.33
	ring.rings = 24
	ring.ring_segments = 6
	var rmi := Models.part(root, ring, color, Vector3(0, 0.065, 0), 1.4)
	rmi.scale = Vector3(1, 0.5, 1)
	rmi.name = "Ring"
	_no_shadow(rmi)
	var button := Node3D.new()
	button.name = "Button"
	button.position.y = 0.06
	root.add_child(button)
	Models.part(button, Models.cylinder(0.22, 0.24, 0.12, 20), color, Vector3(0, 0.06, 0), 0.45)
	var icon := Models.part(button, icon_mesh(ci, 0.13, 0.05), Models.WHITE, Vector3(0, 0.135, 0), 0.9)
	icon.rotation.x = -PI * 0.5
	icon.name = "Icon"
	return root


# --- Critters -----------------------------------------------------------------------

## The Zapper: a little chrome robot on a tread with a glowing visor and an
## antenna spark. It dashes in straight lines, then stops to look around.
static func zapper() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.95, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * ZAP_SIZE
	root.add_child(body)
	Models.part(body, _box(Vector3(0.5, 0.14, 0.42), 0.05), STEEL, Vector3(0, 0.08, 0))
	_no_shadow(Models.part(body, _box(Vector3(0.52, 0.03, 0.44), 0.01), CYAN, Vector3(0, 0.03, 0), 1.6))
	Models.part(body, _box(Vector3(0.46, 0.3, 0.4), 0.09), CHROME, Vector3(0, 0.3, 0))
	Models.part(body, _box(Vector3(0.48, 0.05, 0.42), 0.02), CHROME_DARK, Vector3(0, 0.44, 0))
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 0.6
	body.add_child(head)
	Models.part(head, _box(Vector3(0.44, 0.26, 0.38), 0.08), CORAL, Vector3.ZERO)
	Models.part(head, _box(Vector3(0.36, 0.14, 0.04), 0.02), NIGHT, Vector3(0, 0.0, 0.19))
	for side: int in [-1, 1]:
		var eye := Models.part(head, _box(Vector3(0.09, 0.07, 0.03), 0.015), CYAN, Vector3(side * 0.08, 0.005, 0.21), 2.0)
		eye.name = "EyeL" if side < 0 else "EyeR"
		_no_shadow(eye)
		var ear := Models.part(head, Models.cylinder(0.05, 0.05, 0.05, 10), LIME, Vector3(side * 0.235, 0, 0), 1.2)
		ear.rotation.z = PI * 0.5
	Models.part(head, Models.cylinder(0.014, 0.014, 0.18, 6), CHROME_DARK, Vector3(0.06, 0.21, 0))
	var tip := Models.part(head, Models.sphere(0.05, -1, 10), LIME, Vector3(0.06, 0.32, 0), 2.0)
	tip.name = "Tip"
	_no_shadow(tip)
	# A little chest light.
	_no_shadow(Models.part(body, _box(Vector3(0.12, 0.08, 0.03), 0.015), PINK, Vector3(0, 0.3, 0.205), 1.5))
	return root


## Gigabolt, the final boss: a big friendly-menacing chrome robot on treads,
## with a glowing visor, a bolt on his chest, claw arms and a neon crown.
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	# Treads.
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.36, 0.3, 1.1), 0.1), STEEL, Vector3(side * 0.5, 0.15, 0))
		_no_shadow(Models.part(body, _box(Vector3(0.38, 0.04, 1.12), 0.015), CYAN, Vector3(side * 0.5, 0.2, 0), 1.6))
	# Torso.
	Models.part(body, _box(Vector3(1.12, 0.66, 0.86), 0.16), BOSS_RED, Vector3(0, 0.62, 0))
	Models.part(body, _box(Vector3(1.18, 0.08, 0.9), 0.03), CHROME_DARK, Vector3(0, 0.95, 0))
	Models.part(body, _box(Vector3(0.56, 0.38, 0.05), 0.04), NIGHT, Vector3(0, 0.62, 0.43))
	var bolt := Models.part(body, bolt_mesh(0.15, 0.05), GOLD, Vector3(0, 0.62, 0.46), 1.8)
	bolt.name = "Bolt"
	_no_shadow(bolt)
	# Head.
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.28
	body.add_child(head)
	Models.part(head, _box(Vector3(0.86, 0.52, 0.72), 0.14), CHROME, Vector3.ZERO)
	Models.part(head, _box(Vector3(0.74, 0.32, 0.06), 0.06), NIGHT, Vector3(0, 0.02, 0.36))
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	head.add_child(eyes)
	for side: int in [-1, 1]:
		var eye := Models.part(eyes, _box(Vector3(0.2, 0.15, 0.04), 0.04), CYAN, Vector3(side * 0.17, 0.02, 0.4), 2.0)
		eye.rotation.z = side * 0.18
		_no_shadow(eye)
		var bolt_ear := Models.part(head, Models.cylinder(0.11, 0.11, 0.08, 14), GOLD, Vector3(side * 0.45, 0, 0), 0.8)
		bolt_ear.rotation.z = PI * 0.5
	# Neon crown and antenna.
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0, 0.3, 0)
	head.add_child(crown)
	Models.part(crown, _box(Vector3(0.5, 0.1, 0.4), 0.03), GOLD, Vector3(0, 0.03, 0), 0.6)
	for k in 3:
		var x: float = -0.17 + k * 0.17
		var spike := Models.part(crown, Models.cylinder(0.0, 0.07, 0.2 if k == 1 else 0.15, 4), GOLD, Vector3(x, 0.16 if k == 1 else 0.13, 0), 0.6)
		spike.rotation.y = PI * 0.25
		_no_shadow(Models.part(crown, Models.sphere(0.035, -1, 8), PINK, Vector3(x, 0.28 if k == 1 else 0.22, 0), 2.0))
	Models.part(head, Models.cylinder(0.02, 0.02, 0.3, 6), CHROME_DARK, Vector3(0.3, 0.38, -0.12))
	var orb := Models.part(head, Models.sphere(0.07, -1, 12), LIME, Vector3(0.3, 0.55, -0.12), 2.0)
	orb.name = "Orb"
	_no_shadow(orb)
	# Arms: shoulder ball, arm block, claw.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.66, 0.8, 0)
		body.add_child(arm)
		Models.part(arm, Models.sphere(0.15, -1, 14), CHROME_DARK, Vector3.ZERO)
		Models.part(arm, _box(Vector3(0.2, 0.42, 0.22), 0.07), BOSS_RED, Vector3(side * 0.05, -0.26, 0.04))
		for c: int in [-1, 1]:
			Models.part(arm, _box(Vector3(0.07, 0.14, 0.1), 0.03), GOLD, Vector3(side * 0.05 + c * 0.06, -0.52, 0.06), 0.4)
	return root


# --- City props ---------------------------------------------------------------------

## A street lamp: a slim pole with a glowing globe under a little cap.
static func lamp(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.18, 0.08, 0.18), 0.03), STEEL, Vector3(0, 0.04, 0))
	Models.part(root, Models.cylinder(0.035, 0.045, 0.95, 8), CHROME_DARK, Vector3(0, 0.5, 0))
	_no_shadow(Models.part(root, Models.sphere(0.12, -1, 14), color, Vector3(0, 1.04, 0), 2.0))
	Models.part(root, Models.cylinder(0.05, 0.14, 0.07, 10), CHROME_DARK, Vector3(0, 1.17, 0))
	return root


## A little skyscraper with glowing window bands and a blinking roof light.
static func tower(r: RandomNumberGenerator, max_h: float) -> Node3D:
	var root := Node3D.new()
	var h: float = r.randf_range(max_h * 0.55, max_h)
	var w: float = r.randf_range(0.42, 0.62)
	var d: float = r.randf_range(0.42, 0.62)
	var shade: Color = [Color("#3A3F8F"), Color("#463A86"), Color("#2F4A86")][r.randi() % 3]
	Models.part(root, _box(Vector3(w, h, d), 0.05), shade, Vector3(0, h * 0.5, 0))
	Models.part(root, _box(Vector3(w + 0.06, 0.06, d + 0.06), 0.02), shade.lightened(0.25), Vector3(0, h + 0.02, 0))
	var lit: Color = [WARM, CYAN, PINK, VIOLET][r.randi() % 4]
	var bands: int = clampi(int(h / 0.32), 1, 5)
	for k in bands:
		var y: float = 0.22 + k * (h - 0.3) / maxf(bands, 1)
		_no_shadow(Models.part(root, _box(Vector3(w + 0.015, 0.07, d + 0.015), 0.01), lit, Vector3(0, y, 0), 1.3))
	if r.randf() < 0.6:
		Models.part(root, Models.cylinder(0.012, 0.012, 0.3, 4), CHROME_DARK, Vector3(0, h + 0.17, 0))
		_no_shadow(Models.part(root, Models.sphere(0.04, -1, 8), PINK if r.randf() < 0.5 else LIME, Vector3(0, h + 0.33, 0), 2.0))
	return root


## A neon sign on a post: a dark board with a glowing star, heart or bolt.
static func neon_sign(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.03, 0.03, 0.6, 6), CHROME_DARK, Vector3(0, 0.3, 0))
	Models.part(root, _box(Vector3(0.5, 0.42, 0.06), 0.05), NIGHT, Vector3(0, 0.78, 0))
	var pick: int = r.randi() % 3
	var mesh: ArrayMesh = star_mesh(0.15, 0.04) if pick == 0 else (heart_mesh(0.15, 0.04) if pick == 1 else bolt_mesh(0.16, 0.04))
	var color: Color = [GOLD, PINK, CYAN][pick]
	_no_shadow(Models.part(root, mesh, color, Vector3(0, 0.78, 0.045), 2.0))
	_no_shadow(Models.part(root, _box(Vector3(0.54, 0.46, 0.03), 0.04), color.darkened(0.4), Vector3(0, 0.78, -0.03), 0.4))
	return root


## A short glowing bollard for the low near side.
static func bollard(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.16, 0.24, 0.16), 0.05), STEEL, Vector3(0, 0.12, 0))
	_no_shadow(Models.part(root, _box(Vector3(0.17, 0.05, 0.17), 0.02), color, Vector3(0, 0.2, 0), 1.8))
	return root


## A low planter with glowing neon "grass" blades.
static func planter(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.5, 0.16, 0.3), 0.05), STEEL, Vector3(0, 0.08, 0))
	var color: Color = [CYAN, PINK, LIME, VIOLET][r.randi() % 4]
	for k in 3:
		var blade := Models.part(root, _box(Vector3(0.05, 0.18 + 0.06 * (k % 2), 0.05), 0.015), color, Vector3(-0.14 + k * 0.14, 0.24, 0), 1.4)
		blade.rotation.z = (k - 1) * 0.25
		_no_shadow(blade)
	return root


## A cluster of towers for a far-off floating block.
static func city_cluster(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var spots: Array[Vector3] = [Vector3(-0.25, 0, -0.2), Vector3(0.25, 0, -0.15), Vector3(0.0, 0, 0.25), Vector3(-0.3, 0, 0.3)]
	for k in spots.size():
		var t := tower(r, 1.0 + size * 0.45 - k * 0.25)
		t.position = spots[k] * size
		root.add_child(t)
	var l := lamp([PINK, CYAN, WARM][r.randi() % 3])
	l.position = Vector3(size * 0.32, 0, size * 0.32)
	root.add_child(l)
	return root

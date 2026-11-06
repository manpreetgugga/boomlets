extends RefCounted
## Models for World 6, Clockwork Keep: turnstiles (blast-turned and
## gear-driven), the Wind-up Mouse, Sir Cuckoo the boss and the clocktower
## props. Crisp, slightly rounded clay blocks in brass, teal and cream, built
## the same way render/Models.gd builds everything else.

const BRASS := Color("#E7B24C")
const BRASS_DARK := Color("#B9832E")
const TEAL := Color("#2FB0A3")
const TEAL_DARK := Color("#1E8379")
const CREAM := Color("#FFF5E0")
const WOOD := Color("#A8613F")
const WOOD_LIGHT := Color("#C98458")
const ROSE := Color("#F27E8C")
const MOUSE := Color("#B8A6EE")
const MOUSE_BELLY := Color("#F1EAFF")
const INK := Color("#2E2A4A")
const SUNNY := Color("#FFD45C")
const BOSS_SIZE: float = 1.15

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A flat cog in the xy plane: [param teeth] square-ish teeth round a disc.
static func gear_mesh(radius: float, depth: float, teeth: int = 8) -> ArrayMesh:
	var key := "gear/%.3f/%.3f/%d" % [radius, depth, teeth]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		var inner: float = radius * 0.78
		for k in teeth:
			var a0: float = TAU * k / teeth
			var step: float = TAU / teeth
			pts.append(Vector2.from_angle(a0) * inner)
			pts.append(Vector2.from_angle(a0 + step * 0.18) * radius)
			pts.append(Vector2.from_angle(a0 + step * 0.5) * radius)
			pts.append(Vector2.from_angle(a0 + step * 0.68) * inner)
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, radius * 0.05, 2), depth, depth * 0.3, 1)
	return _shapes[key]


static func ring_mesh(inner: float, outer: float, segs: int = 32) -> TorusMesh:
	var r := TorusMesh.new()
	r.inner_radius = inner
	r.outer_radius = outer
	r.rings = segs
	r.ring_segments = 6
	return r


## A little clock face facing +z: cream dial, brass rim and two ink hands.
static func clock_face(parent: Node3D, at: Vector3, radius: float, hour: float) -> Node3D:
	var face := Node3D.new()
	face.position = at
	parent.add_child(face)
	var dial := Models.part(face, Models.cylinder(radius, radius, 0.04, 20), CREAM)
	dial.rotation.x = PI * 0.5
	var rim := Models.part(face, ring_mesh(radius * 0.92, radius * 1.12, 24), BRASS, Vector3(0, 0, 0.01))
	rim.rotation.x = PI * 0.5
	rim.scale = Vector3(1, 0.5, 1)
	for k in 2:
		var hand := Node3D.new()
		hand.rotation.z = -hour * TAU / 12.0 if k == 0 else -hour * TAU
		hand.position.z = 0.03
		face.add_child(hand)
		var len: float = radius * (0.5 if k == 0 else 0.78)
		Models.part(hand, _box(Vector3(radius * 0.13, len, 0.02), 0.006), INK, Vector3(0, len * 0.45, 0))
	return face


# --- Turnstiles ---------------------------------------------------------------------

## A turnstile standing on its hub cell. Its "Arms" node holds two gate
## panels along local ±z that reach over the neighbouring cells; turn it by
## Arms.rotation.y. Gear-driven ones carry a ticking "Dial" (with a "Hand")
## and a "Cog" on top; blast ones have a teal cap with a burst mark.
static func turnstile(gear: bool) -> Node3D:
	var root := Node3D.new()
	var panel_c: Color = ROSE if gear else BRASS
	var trim_c: Color = BRASS if gear else TEAL_DARK
	# The swing track on the floor, so the reach of the arms reads at a glance.
	var track := Models.part(root, ring_mesh(0.86, 1.0, 40), panel_c.darkened(0.05), Vector3(0, 0.02, 0))
	track.scale = Vector3(1, 0.25, 1)
	_no_shadow(track)
	Models.part(root, Models.cylinder(0.42, 0.44, 0.06, 24), BRASS_DARK, Vector3(0, 0.02, 0))
	# Hub post.
	Models.part(root, Models.cylinder(0.27, 0.3, 0.72, 20), BRASS, Vector3(0, 0.38, 0))
	Models.part(root, Models.cylinder(0.31, 0.31, 0.07, 20), BRASS_DARK, Vector3(0, 0.2, 0))
	var arms := Node3D.new()
	arms.name = "Arms"
	root.add_child(arms)
	for side: int in [-1, 1]:
		var z: float = side * 0.64
		Models.part(arms, _box(Vector3(0.56, 0.52, 0.76), 0.09), panel_c, Vector3(0, 0.3, z))
		Models.part(arms, _box(Vector3(0.62, 0.1, 0.82), 0.04), panel_c.lightened(0.12), Vector3(0, 0.6, z))
		Models.part(arms, _box(Vector3(0.64, 0.05, 0.84), 0.02), trim_c, Vector3(0, 0.53, z))
		Models.part(arms, _box(Vector3(0.6, 0.07, 0.8), 0.03), trim_c, Vector3(0, 0.1, z))
		# A cream stripe and two rivets on top so the arm reads from above.
		_no_shadow(Models.part(arms, _box(Vector3(0.16, 0.03, 0.6), 0.012), trim_c, Vector3(0, 0.66, z)))
		# Little round windows down both sides of the panel.
		for k in 2:
			for sx: int in [-1, 1]:
				var win := Models.part(arms, Models.cylinder(0.07, 0.07, 0.02, 12), CREAM, Vector3(sx * 0.285, 0.33, z + (-0.17 + k * 0.34)))
				win.rotation.z = PI * 0.5
				_no_shadow(win)
		Models.part(arms, Models.sphere(0.15, -1, 14), trim_c, Vector3(0, 0.6, side * 1.0))
	var top := Node3D.new()
	top.name = "Top"
	top.position.y = 0.76
	root.add_child(top)
	if gear:
		var cog := Node3D.new()
		cog.name = "Cog"
		top.add_child(cog)
		var g := Models.part(cog, gear_mesh(0.4, 0.09, 10), BRASS_DARK, Vector3(0, 0.02, 0))
		g.rotation.x = -PI * 0.5
		var dial := Node3D.new()
		dial.name = "Dial"
		dial.position.y = 0.08
		top.add_child(dial)
		Models.part(dial, Models.cylinder(0.24, 0.24, 0.05, 22), CREAM)
		for k in 4:
			var a: float = TAU * k / 4.0
			_no_shadow(Models.part(dial, _box(Vector3(0.05, 0.02, 0.05), 0.01), INK, Vector3(sin(a) * 0.18, 0.03, -cos(a) * 0.18)))
		var hand := Node3D.new()
		hand.name = "Hand"
		hand.position.y = 0.04
		dial.add_child(hand)
		_no_shadow(Models.part(hand, _box(Vector3(0.045, 0.025, 0.2), 0.01), ROSE, Vector3(0, 0, -0.08), 0.4))
		_no_shadow(Models.part(dial, Models.cylinder(0.04, 0.04, 0.04, 10), BRASS, Vector3(0, 0.05, 0)))
	else:
		Models.part(top, Models.cylinder(0.25, 0.29, 0.1, 20), TEAL_DARK, Vector3(0, 0.02, 0))
		var mark := Models.part(top, burst_mesh(0.17, 0.05), SUNNY, Vector3(0, 0.09, 0), 0.6)
		mark.rotation.x = -PI * 0.5
		mark.name = "Mark"
	return root


## A spiky burst (blast mark) in the xy plane.
static func burst_mesh(size: float, depth: float) -> ArrayMesh:
	var key := "burst/%.3f/%.3f" % [size, depth]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 16:
			var a: float = PI * 0.5 + TAU * k / 16.0
			var r: float = size if k % 2 == 0 else size * 0.5
			pts.append(Vector2(cos(a), sin(a)) * r)
		_shapes[key] = ClayShapes.extrusion(pts, depth, depth * 0.3, 1)
	return _shapes[key]


# --- Critters -----------------------------------------------------------------------

## The Wind-up Mouse: a lilac clockwork mouse on little wheels with round
## ears, a curly tail and a brass "Key" in its back.
static func mouse() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Models.part(body, Models.sphere(0.25, -1, 20), MOUSE, Vector3(0, 0.27, -0.02))
	shell.scale = Vector3(0.95, 0.85, 1.25)
	var belly := Models.part(body, Models.sphere(0.2, -1, 16), MOUSE_BELLY, Vector3(0, 0.22, 0.08))
	belly.scale = Vector3(0.9, 0.75, 1.1)
	# Snout and nose.
	var snout := Models.part(body, Models.sphere(0.12, -1, 14), MOUSE, Vector3(0, 0.25, 0.28))
	snout.scale = Vector3(0.9, 0.8, 1.2)
	Models.part(body, Models.sphere(0.045, -1, 10), ROSE, Vector3(0, 0.27, 0.42), 0.3)
	for side: int in [-1, 1]:
		var whisker := Models.part(body, _box(Vector3(0.16, 0.012, 0.012), 0.004), INK, Vector3(side * 0.12, 0.24, 0.34))
		whisker.rotation.y = side * 0.25
		# Round ears.
		var ear := Models.part(body, Models.cylinder(0.12, 0.12, 0.04, 16), MOUSE, Vector3(side * 0.14, 0.48, 0.08))
		ear.rotation = Vector3(PI * 0.5, 0, side * -0.35)
		var inner := Models.part(ear, Models.cylinder(0.08, 0.08, 0.02, 14), ROSE.lightened(0.3), Vector3(0, 0.022, 0))
		inner.rotation = Vector3.ZERO
	Models._eyes(body, 0.36, 0.2, 0.085, 0.055)
	# Wheels.
	for sx: int in [-1, 1]:
		for sz: int in [-1, 1]:
			var w := Models.part(body, Models.cylinder(0.065, 0.065, 0.05, 12), BRASS_DARK, Vector3(sx * 0.17, 0.065, sz * 0.15))
			w.rotation.z = PI * 0.5
	# Curly tail of three bits.
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.2, -0.3)
	body.add_child(tail)
	for k in 3:
		var seg := Models.part(tail, Models.cylinder(0.022, 0.022, 0.13, 6), ROSE, Vector3(0, 0.02 + k * 0.05, -0.05 - k * 0.07))
		seg.rotation.x = 0.9 - k * 0.6
	# The wind-up key.
	var key := Node3D.new()
	key.name = "Key"
	key.position = Vector3(0, 0.48, -0.1)
	body.add_child(key)
	Models.part(key, Models.cylinder(0.025, 0.025, 0.16, 8), BRASS, Vector3(0, -0.04, 0))
	for side: int in [-1, 1]:
		var loop := Models.part(key, ring_mesh(0.04, 0.075, 16), BRASS, Vector3(side * 0.08, 0.06, 0), 0.2)
		loop.rotation.x = PI * 0.5
	return root


## Sir Cuckoo: a grand cuckoo clock on brass legs with a teal gabled roof,
## a knightly plume, a clock face for a face (its "Hands" sweep round), a
## "Bird" that pops out of the little door and a swinging "Pendulum".
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	# Legs and feet.
	for side: int in [-1, 1]:
		Models.part(body, Models.cylinder(0.08, 0.09, 0.3, 10), BRASS_DARK, Vector3(side * 0.28, 0.2, 0))
		Models.part(body, _box(Vector3(0.26, 0.1, 0.36), 0.04), BRASS, Vector3(side * 0.28, 0.05, 0.05))
	# The clock house.
	Models.part(body, _box(Vector3(1.08, 0.95, 0.78), 0.12), WOOD, Vector3(0, 0.82, 0))
	Models.part(body, _box(Vector3(1.14, 0.1, 0.84), 0.04), BRASS, Vector3(0, 0.36, 0))
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.1, 0.92, 0.82), 0.04), WOOD_LIGHT, Vector3(side * 0.53, 0.82, 0))
	# Gable roof.
	for side: int in [-1, 1]:
		var slab := Models.part(body, _box(Vector3(0.74, 0.11, 0.96), 0.04), Color("#E8664F"), Vector3(side * 0.29, 1.47, 0))
		slab.rotation.z = side * -0.62
	Models.part(body, _box(Vector3(0.62, 0.36, 0.7), 0.06), WOOD_LIGHT, Vector3(0, 1.36, 0))
	# Plume.
	var plume := Node3D.new()
	plume.name = "Plume"
	plume.position = Vector3(0, 1.72, -0.05)
	body.add_child(plume)
	Models.part(plume, Models.cylinder(0.04, 0.05, 0.12, 8), BRASS, Vector3.ZERO)
	for k in 3:
		var f := Models.part(plume, Models.sphere(0.11, -1, 12), ROSE.lightened(k * 0.12), Vector3(0, 0.12 + k * 0.07, -0.08 - k * 0.07))
		f.scale = Vector3(0.7, 0.6, 1.3)
	# Clock face with eyes.
	var face := clock_face(body, Vector3(0, 0.8, 0.4), 0.36, 0.0)
	face.name = "Face"
	face.rotation.x = -0.25
	for ch: Node in face.get_children():
		if ch is Node3D and (ch as Node3D).position.z > 0.02:
			ch.queue_free()
	var hands := Node3D.new()
	hands.name = "Hands"
	hands.position = Vector3(0, 0.0, 0.04)
	face.add_child(hands)
	Models.part(hands, _box(Vector3(0.04, 0.2, 0.02), 0.008), INK, Vector3(0, -0.1, 0))
	Models.part(hands, _box(Vector3(0.03, 0.27, 0.02), 0.008), ROSE, Vector3(0, -0.13, 0.01)).rotation.z = 0.0
	Models._eyes(body, 0.9, 0.42, 0.13, 0.075, true)
	# Little door with the cuckoo.
	Models.part(body, _box(Vector3(0.26, 0.22, 0.04), 0.03), WOOD.darkened(0.3), Vector3(0, 1.32, 0.36))
	var bird := Node3D.new()
	bird.name = "Bird"
	bird.position = Vector3(0, 1.32, 0.3)
	body.add_child(bird)
	Models.part(bird, Models.sphere(0.1, -1, 12), SUNNY, Vector3.ZERO)
	var beak := Models.part(bird, Models.cylinder(0.0, 0.04, 0.08, 8), Color("#F28A3D"), Vector3(0, -0.01, 0.12))
	beak.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		_no_shadow(Models.part(bird, Models.sphere(0.02, -1, 6), INK, Vector3(side * 0.05, 0.03, 0.08)))
	# Pendulum.
	var pend := Node3D.new()
	pend.name = "Pendulum"
	pend.position = Vector3(0, 0.42, 0.42)
	body.add_child(pend)
	Models.part(pend, _box(Vector3(0.04, 0.26, 0.03), 0.01), BRASS_DARK, Vector3(0, -0.13, 0))
	var bob := Models.part(pend, Models.cylinder(0.09, 0.09, 0.04, 16), BRASS, Vector3(0, -0.28, 0), 0.2)
	bob.rotation.x = PI * 0.5
	# Arms with a tiny lance and a cog shield.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.62, 0.86, 0.05)
		body.add_child(arm)
		Models.part(arm, Models.sphere(0.11, -1, 12), BRASS, Vector3.ZERO)
		Models.part(arm, _box(Vector3(0.12, 0.34, 0.12), 0.04), BRASS_DARK, Vector3(side * 0.04, -0.2, 0.04))
		if side < 0:
			var shield := Models.part(arm, gear_mesh(0.26, 0.07, 9), TEAL, Vector3(-0.1, -0.24, 0.12))
			shield.rotation.y = -PI * 0.5
		else:
			var lance := Models.part(arm, Models.cylinder(0.0, 0.06, 0.6, 10), CREAM, Vector3(0.06, -0.3, 0.32))
			lance.rotation.x = PI * 0.5
	# Wind-up key on the back.
	var key := Node3D.new()
	key.name = "Key"
	key.position = Vector3(0, 0.9, -0.48)
	body.add_child(key)
	var shaft := Models.part(key, Models.cylinder(0.04, 0.04, 0.2, 8), BRASS, Vector3(0, 0, -0.06))
	shaft.rotation.x = PI * 0.5
	for side: int in [-1, 1]:
		var loop := Models.part(key, ring_mesh(0.07, 0.13, 16), BRASS, Vector3(side * 0.14, 0, -0.16))
		loop.rotation.z = PI * 0.5
		loop.rotation.y = PI * 0.5
	return root


# --- Props --------------------------------------------------------------------------

## An upright cog on a little stand; its "Spin" child turns.
static func standing_gear(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.3, 0.1, 0.24), 0.03), BRASS_DARK, Vector3(0, 0.05, 0))
	Models.part(root, _box(Vector3(0.07, size * 0.55, 0.07), 0.02), BRASS_DARK, Vector3(0, size * 0.28, 0))
	var spin := Node3D.new()
	spin.name = "Spin"
	spin.position.y = size * 0.55
	root.add_child(spin)
	var c: Color = [BRASS, TEAL, ROSE.darkened(0.05)][r.randi() % 3]
	Models.part(spin, gear_mesh(size * 0.42, 0.08, 8 + r.randi() % 4), c)
	Models.part(spin, Models.cylinder(size * 0.09, size * 0.09, 0.12, 12), CREAM, Vector3.ZERO).rotation.x = PI * 0.5
	spin.set_meta(&"speed", r.randf_range(0.4, 0.9) * (1.0 if r.randf() < 0.5 else -1.0))
	return root


## A little clock tower: stacked cream and teal blocks, a clock face and a
## pointed roof.
static func clock_tower(r: RandomNumberGenerator, h: float) -> Node3D:
	var root := Node3D.new()
	var w: float = r.randf_range(0.42, 0.55)
	Models.part(root, _box(Vector3(w, h, w), 0.05), CREAM.darkened(0.04), Vector3(0, h * 0.5, 0))
	Models.part(root, _box(Vector3(w + 0.06, 0.07, w + 0.06), 0.02), TEAL, Vector3(0, h * 0.35, 0))
	Models.part(root, _box(Vector3(w + 0.08, 0.1, w + 0.08), 0.03), BRASS, Vector3(0, h + 0.03, 0))
	clock_face(root, Vector3(0, h * 0.72, w * 0.5 + 0.02), w * 0.32, r.randf() * 12.0)
	var roof := Models.part(root, Models.cylinder(0.0, w * 0.75, h * 0.42, 4), TEAL, Vector3(0, h + 0.08 + h * 0.21, 0))
	roof.rotation.y = PI * 0.25
	_no_shadow(Models.part(root, Models.sphere(0.05, -1, 8), BRASS, Vector3(0, h + 0.1 + h * 0.42, 0), 0.4))
	return root


## A tall pendulum post: a slim frame and a swinging brass bob ("Swing").
static func pendulum_post() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.36, 0.08, 0.2), 0.03), WOOD, Vector3(0, 0.04, 0))
	for side: int in [-1, 1]:
		Models.part(root, _box(Vector3(0.06, 1.1, 0.06), 0.02), WOOD, Vector3(side * 0.15, 0.58, 0))
	Models.part(root, _box(Vector3(0.4, 0.08, 0.1), 0.03), BRASS, Vector3(0, 1.14, 0))
	var swing := Node3D.new()
	swing.name = "Swing"
	swing.position.y = 1.1
	root.add_child(swing)
	Models.part(swing, _box(Vector3(0.025, 0.6, 0.025), 0.008), BRASS_DARK, Vector3(0, -0.3, 0))
	var bob := Models.part(swing, Models.cylinder(0.09, 0.09, 0.04, 14), BRASS, Vector3(0, -0.64, 0), 0.2)
	bob.rotation.x = PI * 0.5
	return root


## A low pile of loose cogs and a bolt for the near side.
static func cog_pile(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(1, 3):
		var g := Models.part(root, gear_mesh(r.randf_range(0.1, 0.17), 0.05, 7 + r.randi() % 3), [BRASS, TEAL, BRASS_DARK][r.randi() % 3], Vector3(r.randf_range(-0.2, 0.2), 0.03 + k * 0.05, r.randf_range(-0.15, 0.15)))
		g.rotation = Vector3(-PI * 0.5 + r.randf_range(-0.15, 0.15), r.randf() * TAU, 0)
	return root


## A brass bell on a little stand.
static func bell() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.06, 0.6, 0.06), 0.02), WOOD, Vector3(0, 0.3, 0))
	Models.part(root, Models.cylinder(0.08, 0.17, 0.24, 14), BRASS, Vector3(0, 0.52, 0), 0.15)
	Models.part(root, Models.sphere(0.04, -1, 8), BRASS_DARK, Vector3(0, 0.39, 0))
	return root

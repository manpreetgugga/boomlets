extends RefCounted
## Bramblewood's own models: bramble hedge parts, bounce mushrooms, the
## Sproutling, the boss Old Thornroot and the storybook-forest decor. Built
## from slightly rounded clay blocks to match the rest of the game.
## Loaded by path from worlds/world_10.gd (no class_name on purpose).

# Colours (sRGB).
const BRAMBLE := Color("#2E6B3E")
const BRAMBLE_LIGHT := Color("#47934F")
const THORN := Color("#F6E7BE")
const ROSE := Color("#FF7FAA")
const ROSE_CORE := Color("#FFE27A")
const CHAR := Color("#4A3426")
const SHOOT := Color("#A6E86E")
const BARK := Color("#8A5A3A")
const BARK_DARK := Color("#6A4128")
const WOOD_TOP := Color("#EBC994")
const WOOD_RING := Color("#C99A62")
const MOSS := Color("#7CC25A")
const MOSS_DARK := Color("#5AA548")
const CAP := Color("#E8463C")
const CAP_DOT := Color("#FFF6E8")
const STALK := Color("#F6EBD6")
const SPRITE := Color("#BDEB72")
const SPRITE_BELLY := Color("#F4FBD9")
const PETAL := Color("#FF9EC4")
const PETAL_DARK := Color("#F06FA6")
const LEAF_A := Color("#5DAE4E")
const LEAF_B := Color("#3F8F45")
const LEAF_C := Color("#8CCB5A")
const APPLE := Color("#FF6B5A")
const GOLD := Color("#F3C623")
const WINDOW := Color("#FFE7A0")

const SPROUT_SIZE: float = 1.22
const BOSS_SIZE: float = 1.0


# --- Bramble parts (shared meshes, drawn in multimeshes) -----------------------

static func body_mesh() -> Mesh:
	return Models.box_mesh(Vector3(0.84, 0.5, 0.84), 0.16)


static func tuft_mesh() -> Mesh:
	return Models.box_mesh(Vector3(0.38, 0.3, 0.38), 0.12)


static func thorn_mesh() -> Mesh:
	if not Models._boxes.has("w10_thorn"):
		Models._boxes["w10_thorn"] = Models.cylinder(0.0, 0.065, 0.24, 6)
	return Models._boxes["w10_thorn"]


static func rose_mesh() -> Mesh:
	if not Models._boxes.has("w10_rose"):
		Models._boxes["w10_rose"] = Models.sphere(0.09, 0.12, 10)
	return Models._boxes["w10_rose"]


static func rose_core_mesh() -> Mesh:
	if not Models._boxes.has("w10_rose_core"):
		Models._boxes["w10_rose_core"] = Models.sphere(0.04, -1, 8)
	return Models._boxes["w10_rose_core"]


static func stub_mesh() -> Mesh:
	return Models.box_mesh(Vector3(0.15, 0.22, 0.15), 0.04)


static func shoot_mesh() -> Mesh:
	return Models.box_mesh(Vector3(0.06, 0.3, 0.06), 0.02)


static func leaf_mesh() -> Mesh:
	return Models.box_mesh(Vector3(0.17, 0.04, 0.1), 0.018)


## The parts of one bramble, in its own space (origin at the floor centre of
## its tile): one array of transforms per part group, in the order body,
## tufts, thorns, roses, rose cores, stubs, shoots, shoot leaves.
static func bramble_parts(r: RandomNumberGenerator) -> Array:
	var body: Array[Transform3D] = [Transform3D(Basis(Vector3.UP, r.randf_range(-0.12, 0.12)), Vector3(0, 0.27, 0))]
	var tufts: Array[Transform3D] = []
	for k in 4:
		var a: float = PI * 0.25 + k * PI * 0.5 + r.randf_range(-0.25, 0.25)
		var s: float = r.randf_range(0.9, 1.12)
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s))
		tufts.append(Transform3D(b, Vector3(cos(a) * 0.2, 0.56 + r.randf_range(-0.02, 0.06), sin(a) * 0.2)))
	var thorns: Array[Transform3D] = []
	for k in 8:
		var a: float = TAU * k / 8.0 + r.randf_range(-0.2, 0.2)
		var y: float = 0.18 + float(k % 3) * 0.17 + r.randf_range(-0.03, 0.03)
		var dir := Vector3(cos(a), 0.3, sin(a)).normalized()
		var tb := Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
		thorns.append(Transform3D(tb, Vector3(cos(a) * 0.47, y, sin(a) * 0.47)))
	var roses: Array[Transform3D] = []
	var cores: Array[Transform3D] = []
	var a0: float = r.randf() * TAU
	for k in 2:
		var a: float = a0 if k == 0 else a0 + PI + r.randf_range(-0.6, 0.6)
		var at := Vector3(cos(a) * 0.3, 0.62 + r.randf_range(0.0, 0.06), sin(a) * 0.3)
		if k == 1:
			at = Vector3(cos(a) * 0.43, 0.38, sin(a) * 0.43)
		roses.append(Transform3D(Basis(), at))
		cores.append(Transform3D(Basis(), at + Vector3(0, 0.05, 0)))
	var stubs: Array[Transform3D] = []
	for k in 4:
		var a: float = PI * 0.25 + k * PI * 0.5 + r.randf_range(-0.3, 0.3)
		var b2 := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.25, 0.25))
		var h: float = r.randf_range(0.6, 1.1)
		stubs.append(Transform3D(b2.scaled(Vector3(1, h, 1)), Vector3(cos(a) * 0.22, 0.08 * h, sin(a) * 0.22)))
	var shoots: Array[Transform3D] = []
	var leaves: Array[Transform3D] = []
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf_range(-0.3, 0.3)
		var base := Vector3(cos(a) * 0.14, 0.0, sin(a) * 0.14)
		var tilt := Basis(Vector3(-sin(a), 0, cos(a)), -0.25)
		var h: float = r.randf_range(0.8, 1.15)
		shoots.append(Transform3D(tilt.scaled(Vector3(1, h, 1)), base + tilt * Vector3(0, 0.15 * h, 0)))
		var tip: Vector3 = base + tilt * Vector3(0, 0.3 * h, 0)
		leaves.append(Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3.FORWARD, 0.4), tip + Vector3(cos(a) * 0.05, 0, sin(a) * 0.05)))
	return [body, tufts, thorns, roses, cores, stubs, shoots, leaves]


# --- Bounce mushroom ------------------------------------------------------------------

## A springy red toadstool pad that leans (and has an arrow) toward +Z; the
## caller turns it to face its launch direction. "Cap" squashes.
static func bounce_shroom() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.95, 0.3)
	Models.part(root, Models.cylinder(0.15, 0.19, 0.14, 14), STALK, Vector3(0, 0.07, 0))
	var cap := Node3D.new()
	cap.name = "Cap"
	cap.position = Vector3(0, 0.12, 0)
	root.add_child(cap)
	var tilt := Node3D.new()
	tilt.rotation.x = 0.16
	cap.add_child(tilt)
	var dome := SphereMesh.new()
	dome.radius = 0.4
	dome.height = 0.4
	dome.is_hemisphere = true
	dome.radial_segments = 22
	dome.rings = 6
	var d := Models.part(tilt, dome, CAP, Vector3(0, 0.0, 0))
	d.scale = Vector3(1.0, 0.36, 1.0)
	Models.part(tilt, Models.cylinder(0.4, 0.37, 0.05, 22), STALK.darkened(0.06), Vector3(0, -0.01, 0))
	for k in 5:
		var a: float = TAU * k / 5.0 + 0.6
		var dot := Models.part(tilt, Models.sphere(0.05, 0.03, 8), CAP_DOT, Vector3(cos(a) * 0.27, 0.09, sin(a) * 0.27))
		dot.scale = Vector3(1.0, 1.0, 1.0)
	# A cream arrow on top showing which way it flings pods.
	var arrow := Node3D.new()
	arrow.position = Vector3(0, 0.15, 0.02)
	arrow.rotation.y = -PI * 0.5
	tilt.add_child(arrow)
	var ch := Models.part(arrow, Models.chevron_mesh(), CAP_DOT, Vector3(0.04, 0, 0), 0.5)
	ch.rotation.x = -PI * 0.5
	ch.scale = Vector3(1.05, 1.05, 1.0)
	return root


# --- Critters --------------------------------------------------------------------------

## The Sproutling: a little lime seed-sprite crowned with a pink tulip bud and
## two leaf arms. Plants brambles as it walks.
static func sproutling() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Models.part(body, Models.sphere(0.27, 0.5, 20), SPRITE, Vector3(0, 0.28, 0))
	shell.scale = Vector3(1.0, 1.0, 0.95)
	var belly := Models.part(body, Models.sphere(0.19, 0.32, 14), SPRITE_BELLY, Vector3(0, 0.24, 0.13))
	belly.scale = Vector3(1.0, 1.0, 0.55)
	Models._eyes(body, 0.33, 0.21, 0.095, 0.065)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.035, -1, 8), Color("#FF8FA8"), Vector3(side * 0.17, 0.26, 0.2))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
		var foot := Models.part(body, Models.sphere(0.07, 0.07, 10), MOSS_DARK, Vector3(side * 0.12, 0.035, 0.03))
		foot.scale = Vector3(1, 1, 1.3)
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.25, 0.28, 0.0)
		body.add_child(arm)
		var leaf := Models.part(arm, Models.box_mesh(Vector3(0.2, 0.04, 0.11), 0.02), LEAF_A, Vector3(side * 0.08, 0.0, 0.0))
		leaf.rotation.z = side * 0.5
	var mouth := Models.part(body, Models.box_mesh(Vector3(0.07, 0.025, 0.02), 0.01), Models.INK, Vector3(0, 0.235, 0.265))
	mouth.rotation.x = -0.2
	# The tulip bud on a short stem.
	var bud := Node3D.new()
	bud.name = "Bud"
	bud.position = Vector3(0, 0.53, 0)
	body.add_child(bud)
	Models.part(bud, Models.cylinder(0.02, 0.025, 0.12, 6), LEAF_B, Vector3(0, 0.04, 0))
	for k in 3:
		var a: float = TAU * k / 3.0 + 0.5
		var p := Models.part(bud, Models.sphere(0.085, 0.2, 12), PETAL if k != 1 else PETAL_DARK, Vector3(cos(a) * 0.045, 0.17, sin(a) * 0.045))
		p.rotation = Vector3(sin(a) * 0.3, 0, -cos(a) * 0.3)
	return root


## Old Thornroot, World 10's boss: a huge friendly-grumpy tree stump with a
## mossy moustache, branch arms, a sapling on his head and a belt of bramble
## armour ("Armour") that grows back after it is burnt off.
static func thornroot() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, Models.cylinder(0.66, 0.74, 1.1, 18), BARK, Vector3(0, 0.58, 0))
	for k in 10:
		var a: float = TAU * k / 10.0 + 0.3
		var ridge := Models.part(body, Models.box_mesh(Vector3(0.13, 0.95, 0.1), 0.04), BARK_DARK, Vector3(cos(a) * 0.68, 0.56, sin(a) * 0.68))
		ridge.rotation.y = -a
	# The cut top with growth rings.
	Models.part(body, Models.cylinder(0.64, 0.64, 0.07, 22), WOOD_TOP, Vector3(0, 1.15, 0))
	Models.part(body, Models.cylinder(0.44, 0.44, 0.075, 20), WOOD_RING, Vector3(0, 1.152, 0))
	Models.part(body, Models.cylinder(0.36, 0.36, 0.08, 20), WOOD_TOP, Vector3(0, 1.154, 0))
	Models.part(body, Models.cylinder(0.14, 0.14, 0.085, 14), WOOD_RING, Vector3(0, 1.156, 0))
	# Roots for feet.
	for k in 4:
		var a: float = TAU * k / 4.0 + PI * 0.25
		var rt := Models.part(body, Models.box_mesh(Vector3(0.3, 0.2, 0.5), 0.08), BARK_DARK, Vector3(cos(a) * 0.72, 0.09, sin(a) * 0.72))
		rt.rotation.y = -a + PI * 0.5
	# Face.
	var face := Node3D.new()
	face.name = "Face"
	body.add_child(face)
	Models._eyes(face, 0.8, 0.66, 0.24, 0.13, true)
	for side: int in [-1, 1]:
		var stache := Models.part(face, Models.box_mesh(Vector3(0.3, 0.12, 0.14), 0.05), MOSS, Vector3(side * 0.15, 0.55, 0.72))
		stache.rotation.z = side * -0.3
		var cheek := Models.part(face, Models.sphere(0.07, -1, 8), Color("#FF9AA8"), Vector3(side * 0.42, 0.64, 0.6))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	Models.part(face, Models.sphere(0.08, -1, 10), BARK_DARK.darkened(0.2), Vector3(0, 0.66, 0.74))
	# Branch arms with leaf mittens.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.66, 0.72, 0.05)
		body.add_child(arm)
		var br := Models.part(arm, Models.box_mesh(Vector3(0.5, 0.13, 0.13), 0.05), BARK, Vector3(side * 0.22, 0.05, 0))
		br.rotation.z = side * 0.4
		var mitt := Models.part(arm, Models.box_mesh(Vector3(0.26, 0.22, 0.22), 0.09), LEAF_A, Vector3(side * 0.46, 0.2, 0))
		mitt.rotation.y = 0.4
	# A sapling and two toadstools on his head.
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0, 1.19, 0)
	body.add_child(crown)
	Models.part(crown, Models.cylinder(0.035, 0.05, 0.4, 8), BARK, Vector3(0.1, 0.2, -0.1))
	var tier1 := Models.part(crown, Models.box_mesh(Vector3(0.42, 0.24, 0.42), 0.1), LEAF_A, Vector3(0.1, 0.45, -0.1))
	tier1.rotation.y = 0.5
	var tier2 := Models.part(crown, Models.box_mesh(Vector3(0.26, 0.18, 0.26), 0.07), LEAF_C, Vector3(0.1, 0.62, -0.1))
	tier2.rotation.y = 1.1
	for k in 2:
		var ts := toadstool(0.5 + k * 0.15)
		ts.position = Vector3(-0.3 + k * 0.12, 0, 0.2 - k * 0.38)
		crown.add_child(ts)
	# The bramble armour: two thorny belts round the trunk, with roses.
	var armour := Node3D.new()
	armour.name = "Armour"
	body.add_child(armour)
	for band in 2:
		var y: float = 0.36 + band * 0.5
		var rad: float = 0.8 - band * 0.04
		var n: int = 11
		for k in n:
			var a: float = TAU * k / n + band * 0.3
			var blk := Models.part(armour, Models.box_mesh(Vector3(0.44, 0.3, 0.26), 0.1), BRAMBLE if k % 2 else BRAMBLE_LIGHT, Vector3(cos(a) * rad, y + (0.04 if k % 2 else -0.03), sin(a) * rad))
			blk.rotation.y = -a + PI * 0.5
			var dir := Vector3(cos(a), 0.15, sin(a)).normalized()
			var th := Models.part(armour, thorn_mesh(), THORN, Vector3(cos(a) * (rad + 0.14), y + 0.05, sin(a) * (rad + 0.14)))
			th.transform = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3.ONE * 1.5), th.position)
	for k in 4:
		var a: float = TAU * k / 4.0 + 0.4
		Models.part(armour, Models.sphere(0.12, 0.16, 12), ROSE, Vector3(cos(a) * 0.86, 0.66, sin(a) * 0.86))
		Models.part(armour, Models.sphere(0.05, -1, 8), ROSE_CORE, Vector3(cos(a) * 0.9, 0.72, sin(a) * 0.9))
	return root


# --- Decor -----------------------------------------------------------------------------

## A small spotted toadstool standing on y = 0.
static func toadstool(size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.07 * size, 0.09 * size, 0.24 * size, 10), STALK, Vector3(0, 0.12 * size, 0))
	var dome := SphereMesh.new()
	dome.radius = 0.2 * size
	dome.height = 0.2 * size
	dome.is_hemisphere = true
	dome.radial_segments = 16
	dome.rings = 5
	var cap := Models.part(root, dome, CAP, Vector3(0, 0.22 * size, 0))
	cap.scale = Vector3(1, 0.75, 1)
	for k in 3:
		var a: float = TAU * k / 3.0 + 0.3
		Models.part(root, Models.sphere(0.03 * size, 0.02 * size, 6), CAP_DOT, Vector3(cos(a) * 0.12 * size, 0.33 * size, sin(a) * 0.12 * size))
	return root


## A storybook tree: a trunk and three stacked, turned leafy blocks.
static func story_tree(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.2 * size, 0.3)
	Models.part(root, Models.cylinder(0.08 * size, 0.12 * size, 0.6 * size, 8), Models.TRUNK, Vector3(0, 0.3 * size, 0))
	var greens: Array[Color] = [LEAF_B, LEAF_A, LEAF_C]
	var w: float = 0.95
	var y: float = 0.62
	for k in 3:
		var h: float = 0.36 - k * 0.04
		var t := Models.part(root, Models.box_mesh(Vector3(w, h, w) * size, 0.13 * size), greens[k], Vector3(0, y * size, 0))
		t.rotation.y = r.randf() * TAU
		y += h * 0.85
		w *= 0.74
	if r.randf() < 0.45:
		for k in 3:
			var a: float = r.randf() * TAU
			Models.part(root, Models.sphere(0.06 * size, -1, 8), APPLE, Vector3(cos(a) * 0.44 * size, (0.6 + r.randf() * 0.2) * size, sin(a) * 0.44 * size))
	return root


## A fan of fern fronds.
static func fern(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var n: int = 5
	for k in n:
		var a: float = TAU * k / n + r.randf_range(-0.2, 0.2)
		var piv := Node3D.new()
		piv.rotation = Vector3(0, -a, 0)
		root.add_child(piv)
		var f := Models.part(piv, Models.box_mesh(Vector3(0.36, 0.03, 0.07) * size, 0.012), LEAF_B if k % 2 else MOSS_DARK, Vector3(0.14 * size, 0.13 * size, 0))
		f.rotation.z = 0.85
	return root


## A mossy fallen log.
static func log_prop(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0, 0.25)
	var l := Models.part(root, Models.cylinder(0.14, 0.14, 0.75, 12), BARK, Vector3(0, 0.14, 0))
	l.rotation.z = PI * 0.5
	for side: int in [-1, 1]:
		var e := Models.part(root, Models.cylinder(0.12, 0.12, 0.02, 12), WOOD_TOP, Vector3(side * 0.375, 0.14, 0))
		e.rotation.z = PI * 0.5
	Models.part(root, Models.box_mesh(Vector3(0.3, 0.06, 0.2), 0.025), MOSS, Vector3(r.randf_range(-0.15, 0.15), 0.28, 0))
	return root


## A little cluster of flowers (white and yellow, storybook style).
static func flowers(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in 4:
		var p := Vector3(r.randf_range(-0.28, 0.28), 0, r.randf_range(-0.28, 0.28))
		Models.part(root, Models.cylinder(0.01, 0.01, 0.15, 4), LEAF_B, p + Vector3(0, 0.075, 0))
		Models.part(root, Models.sphere(0.045, -1, 8), [CAP_DOT, ROSE_CORE, PETAL, Color("#B9A7F0")][r.randi() % 4], p + Vector3(0, 0.16, 0))
	return root


## A toadstool cottage: a cream stalk house under a big spotted cap.
static func shroom_house(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.6 * size, 0.35)
	Models.part(root, Models.cylinder(0.36 * size, 0.42 * size, 0.7 * size, 16), STALK, Vector3(0, 0.35 * size, 0))
	Models.part(root, Models.box_mesh(Vector3(0.2, 0.3, 0.06) * size, 0.04), BARK, Vector3(0, 0.15 * size, 0.4 * size))
	Models.part(root, Models.cylinder(0.08 * size, 0.08 * size, 0.04 * size, 12), WINDOW, Vector3(0.18 * size, 0.46 * size, 0.36 * size), 1.4).rotation.x = PI * 0.5
	var dome := SphereMesh.new()
	dome.radius = 0.7 * size
	dome.height = 0.7 * size
	dome.is_hemisphere = true
	dome.radial_segments = 22
	dome.rings = 7
	var cap := Models.part(root, dome, CAP, Vector3(0, 0.66 * size, 0))
	cap.scale = Vector3(1, 0.8, 1)
	Models.part(root, Models.cylinder(0.7 * size, 0.66 * size, 0.06 * size, 22), STALK.darkened(0.08), Vector3(0, 0.66 * size, 0))
	for k in 6:
		var a: float = TAU * k / 6.0 + r.randf()
		Models.part(root, Models.sphere(0.07 * size, 0.04 * size, 8), CAP_DOT, Vector3(cos(a) * 0.45 * size, 1.0 * size, sin(a) * 0.45 * size))
	Models.part(root, Models.box_mesh(Vector3(0.12, 0.3, 0.12) * size, 0.03), BARK_DARK, Vector3(0.3 * size, 1.1 * size, -0.2 * size))
	return root

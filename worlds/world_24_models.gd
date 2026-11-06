extends RefCounted
## Models for World 24, Mirror Marsh: a calm misty marsh split by a glassy
## lake. Pip's reflection (the Shade), its ghostly pods, Lily Frogs and their
## Mirror Frogs, Dragonflies, the Great Heron boss, lotus bells and reed
## gates, and the marsh props (reeds, cattails, lily ponds, willows, stone
## lanterns). Built from crisp, slightly rounded clay shapes like
## render/Models.gd. Loaded by path from world_24.gd (no class_name).

const MINT := Color("#7CCB8A")
const MINT_DARK := Color("#4FA36A")
const BELLY := Color("#F1F7DE")
const LILAC := Color("#A693E6")
const LILAC_DARK := Color("#7E6BC9")
const SILVER := Color("#EEF0FA")
const SHADE := Color("#D2C6FF")
const SHADE_BELLY := Color("#FFFFFF")
const SHADE_FOOT := Color("#6C5BC0")
const GHOST_POD := Color("#4A3F9C")
const WATER := Color("#BFE6E0")
const WATER_DEEP := Color("#86C2C4")
const PAD := Color("#6FBF7A")
const PAD_DARK := Color("#56A866")
const LOTUS_WHITE := Color("#F6F0FF")
const LOTUS_PINK := Color("#F59BC0")
const REED := Color("#7DB46C")
const REED_DARK := Color("#5E9A57")
const CATTAIL := Color("#8A5E44")
const BASIN := Color("#B9C8C1")
const MUSHROOM := Color("#E9DDF7")
const HERON := Color("#D5DFEE")
const HERON_WING := Color("#9DB0CC")
const HERON_TIP := Color("#5D6C8C")
const HERON_LEG := Color("#F2B46B")
const BEAK := Color("#F7C94B")
const CREST := Color("#3D4360")
const DFLY := Color("#4FC3D9")
const DFLY_TAIL := Color("#7C6FE0")
const WING := Color("#E4F6FF")
const INK := Color("#2E2A4A")
const BOSS_SIZE: float = 1.4
const FROG_SIZE: float = 1.0

## Lotus bell and reed gate colours, per group (lilac-white, pink).
const GROUP_COLORS: Array[Color] = [Color("#B7A6F2"), Color("#F59BC0")]

static var _shapes: Dictionary = {}


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _eyes(body: Node3D, y: float, z: float, spread: float, size: float) -> void:
	for side: int in [-1, 1]:
		var eye := Models.part(body, Models.sphere(size, size * 2.2, 14), Models.WHITE, Vector3(side * spread, y, z))
		eye.scale = Vector3(1.0, 1.0, 0.6)
		var pupil := Models.part(body, Models.sphere(size * 0.55, -1, 12), INK, Vector3(side * spread, y - size * 0.1, z + size * 0.45))
		pupil.scale = Vector3(1.0, 1.15, 0.6)
		Models.part(body, Models.sphere(size * 0.16, -1, 8), Models.WHITE, Vector3(side * spread + size * 0.18, y + size * 0.2, z + size * 0.75), 1.0)


# --- The Shade (Pip's reflection) ----------------------------------------------

## Pip's reflection: Pip's shape in misty lilac and silver, with a glowing
## sprout and a faint ring on the ground. Same part names as the hero
## (Body, FootL, FootR) so it walks the same way.
static func shade() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.95, 0.22)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.36
	ring.outer_radius = 0.43
	ring.rings = 24
	ring.ring_segments = 4
	var halo := _no_shadow(Models.part(root, ring, SILVER, Vector3(0, 0.03, 0), 0.9)) as MeshInstance3D
	halo.scale = Vector3(1, 0.3, 1)
	halo.name = "Halo"
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Models.part(body, Models.sphere(0.34, 0.74, 24), SHADE, Vector3(0, 0.42, 0), 0.5)
	shell.scale = Vector3(1.0, 1.0, 0.92)
	var belly := Models.part(body, Models.sphere(0.25, 0.46, 18), SHADE_BELLY, Vector3(0, 0.36, 0.16), 0.15)
	belly.scale = Vector3(1.0, 1.0, 0.6)
	_eyes(body, 0.55, 0.26, 0.12, 0.085)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.045, -1, 8), Color("#D9B8F5"), Vector3(side * 0.22, 0.45, 0.25))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	Models.part(body, Models.cylinder(0.018, 0.025, 0.16, 8), SHADE_FOOT, Vector3(0, 0.84, 0))
	for side: int in [-1, 1]:
		var leaf := Models.part(body, Models.sphere(0.08, 0.05, 12), SILVER, Vector3(side * 0.08, 0.92, 0), 0.8)
		leaf.scale = Vector3(1.4, 1.0, 0.8)
		leaf.rotation.z = side * -0.5
	for side: int in [-1, 1]:
		var foot := Models.part(body, Models.sphere(0.09, 0.1, 12), SHADE_FOOT, Vector3(side * 0.15, 0.05, 0.05))
		foot.name = "FootL" if side < 0 else "FootR"
		foot.scale = Vector3(1.0, 1.0, 1.4)
	return root


## The Shade's pod: a frosted lilac ball with a silver band and a cool
## white spark.
static func ghost_pod() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.22)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var ball := Models.part(body, Models.sphere(0.3, 0.6, 22), GHOST_POD, Vector3(0, 0.32, 0), 0.25)
	if Models.GLASS:
		ball.material_override = Models.glass(GHOST_POD, 0.55, 0.25)
	Models.part(body, Models.cylinder(0.305, 0.305, 0.07, 22), SILVER, Vector3(0, 0.32, 0), 0.4)
	Models.part(body, Models.cylinder(0.07, 0.09, 0.08, 10), LILAC_DARK, Vector3(0, 0.63, 0))
	var wick := Models.part(body, Models.cylinder(0.018, 0.018, 0.14, 6), Color("#8E86A8"), Vector3(-0.03, 0.72, 0))
	wick.rotation.z = 0.3
	var spark := _no_shadow(Models.part(body, Models.sphere(0.06, -1, 8), Color("#F2EEFF"), Vector3(-0.06, 0.8, 0), 2.5))
	spark.name = "Spark"
	return root


# --- Critters ---------------------------------------------------------------------

## Lily Frog: a round mint frog with eyes on top, a cream belly, chunky back
## legs and a tiny lotus on its head. A Mirror Frog is the same in lilac and
## silver with a soft glow.
static func frog(mirror: bool) -> Node3D:
	var col: Color = SHADE if mirror else MINT
	var dark: Color = LILAC_DARK if mirror else MINT_DARK
	var belly_col: Color = SHADE_BELLY if mirror else BELLY
	var glow: float = 0.2 if mirror else 0.0
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var torso := Models.part(body, Models.sphere(0.3, 0.46, 20), col, Vector3(0, 0.25, 0), glow)
	torso.scale = Vector3(1.1, 1.0, 1.0)
	var belly := Models.part(body, Models.sphere(0.22, 0.3, 16), belly_col, Vector3(0, 0.2, 0.14), glow)
	belly.scale = Vector3(1.1, 1.0, 0.7)
	for side: int in [-1, 1]:
		Models.part(body, Models.sphere(0.12, -1, 14), col, Vector3(side * 0.14, 0.44, 0.08), glow)
	_eyes(body, 0.47, 0.15, 0.14, 0.075)
	var mouth := Models.part(body, Models.box_mesh(Vector3(0.22, 0.025, 0.03), 0.01), dark, Vector3(0, 0.27, 0.29))
	mouth.rotation.x = -0.15
	for side: int in [-1, 1]:
		var leg := Models.part(body, Models.sphere(0.12, 0.18, 12), dark, Vector3(side * 0.25, 0.1, -0.08))
		leg.scale = Vector3(0.9, 1.0, 1.5)
		leg.name = "LegL" if side < 0 else "LegR"
		var foot := Models.part(body, Models.sphere(0.07, 0.06, 10), dark, Vector3(side * 0.16, 0.03, 0.2))
		foot.scale = Vector3(1.3, 1.0, 1.2)
	# A tiny lotus hat.
	var hat := Models.part(body, Models.cylinder(0.09, 0.09, 0.025, 14), PAD if not mirror else SILVER, Vector3(0.0, 0.5, -0.06))
	hat.rotation.x = -0.15
	Models.part(body, Models.sphere(0.05, 0.07, 10), LOTUS_PINK if not mirror else LOTUS_WHITE, Vector3(0, 0.54, -0.07), 0.3)
	return root


## Dragonfly: a slim teal body with a lilac-tipped tail, big round eyes and
## two pairs of shimmering wings, hovering at knee height.
static func dragonfly() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.65, 0.2)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var fly := Node3D.new()
	fly.name = "Fly"
	fly.position.y = 0.55
	body.add_child(fly)
	Models.part(fly, Models.sphere(0.13, -1, 14), DFLY, Vector3(0, 0, 0.12))
	for side: int in [-1, 1]:
		Models.part(fly, Models.sphere(0.09, -1, 12), Color("#2F7FA8"), Vector3(side * 0.08, 0.05, 0.24))
		Models.part(fly, Models.sphere(0.03, -1, 8), Models.WHITE, Vector3(side * 0.1, 0.09, 0.31), 1.0)
	Models.part(fly, Models.sphere(0.1, 0.18, 12), DFLY, Vector3(0, 0, -0.05))
	for k in 4:
		var seg := Models.part(fly, Models.sphere(0.065 - k * 0.008, 0.16, 10), DFLY.lerp(DFLY_TAIL, k / 3.0), Vector3(0, 0.0, -0.2 - k * 0.12))
		seg.scale = Vector3(1, 1, 1.0)
	var wing_mesh := Models.sphere(0.3, 0.03, 14)
	for side: int in [-1, 1]:
		for k in 2:
			var pivot := Node3D.new()
			pivot.name = ("WingL" if side < 0 else "WingR") + str(k)
			pivot.position = Vector3(side * 0.05, 0.06, 0.02 - k * 0.14)
			fly.add_child(pivot)
			var w := _no_shadow(Models.part(pivot, wing_mesh, WING, Vector3(side * 0.26, 0, 0), 0.45)) as MeshInstance3D
			w.scale = Vector3(1.0, 1.0, 0.32)
			w.rotation.y = side * (0.12 - k * 0.28)
	return root


## The Great Heron of the Lake: a tall, elegant blue-grey heron with folded
## wings, an S-curved neck, a long golden beak, a dark crest plume and long
## orange legs.
static func heron() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.5, 0.4)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var torso := Models.part(body, Models.sphere(0.4, 0.62, 24), HERON, Vector3(0, 0.95, -0.05))
	torso.scale = Vector3(0.9, 1.0, 1.35)
	var chest := Models.part(body, Models.sphere(0.28, 0.48, 18), Models.WHITE, Vector3(0, 0.95, 0.25))
	chest.scale = Vector3(0.9, 1.0, 0.8)
	for side: int in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.3, 1.08, 0.05)
		body.add_child(wing)
		var w := Models.part(wing, Models.sphere(0.3, 0.2, 16), HERON_WING, Vector3(side * 0.08, -0.04, -0.15))
		w.scale = Vector3(0.55, 1.0, 1.7)
		var tip := Models.part(wing, Models.sphere(0.16, 0.12, 12), HERON_TIP, Vector3(side * 0.08, -0.08, -0.6))
		tip.scale = Vector3(0.6, 1.0, 1.6)
	var tail := Models.part(body, Models.cylinder(0.0, 0.16, 0.36, 8), HERON_TIP, Vector3(0, 0.88, -0.62))
	tail.rotation.x = -PI * 0.5 - 0.35
	# Legs.
	for side: int in [-1, 1]:
		Models.part(body, Models.cylinder(0.035, 0.04, 0.62, 8), HERON_LEG, Vector3(side * 0.13, 0.33, 0.0))
		Models.part(body, Models.sphere(0.05, -1, 8), HERON_LEG.darkened(0.1), Vector3(side * 0.13, 0.42, 0.0))
		for k in 3:
			var toe := Models.part(body, Models.box_mesh(Vector3(0.04, 0.03, 0.2), 0.012), HERON_LEG, Vector3(side * 0.13, 0.02, 0.07))
			toe.rotation.y = (k - 1) * 0.5
	# Neck: three segments curving up and forward, then the head.
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 1.2, 0.28)
	body.add_child(neck)
	var seg_mesh := Models.cylinder(0.08, 0.1, 0.32, 12)
	var a := Models.part(neck, seg_mesh, HERON, Vector3(0, 0.12, 0.04))
	a.rotation.x = 0.35
	var b := Models.part(neck, seg_mesh, Models.WHITE, Vector3(0, 0.38, 0.0))
	b.rotation.x = -0.4
	Models.part(neck, Models.sphere(0.09, -1, 10), HERON, Vector3(0, 0.25, 0.05))
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.6, 0.06)
	neck.add_child(head)
	var skull := Models.part(head, Models.sphere(0.15, 0.26, 16), Models.WHITE, Vector3.ZERO)
	skull.scale = Vector3(0.9, 1.0, 1.15)
	var beak := Models.part(head, Models.cylinder(0.0, 0.055, 0.42, 10), BEAK, Vector3(0, -0.02, 0.32))
	beak.rotation.x = PI * 0.5
	beak.name = "Beak"
	var stripe := Models.part(head, Models.box_mesh(Vector3(0.32, 0.05, 0.22), 0.02), CREST, Vector3(0, 0.07, -0.02))
	stripe.scale = Vector3(0.9, 1.0, 1.0)
	for k in 2:
		var plume := Models.part(head, Models.box_mesh(Vector3(0.035, 0.03, 0.34), 0.012), CREST, Vector3((k - 0.5) * 0.05, 0.1, -0.24))
		plume.rotation.x = 0.35 + k * 0.12
	for side: int in [-1, 1]:
		Models.part(head, Models.sphere(0.04, -1, 10), Color("#FFE27A"), Vector3(side * 0.11, 0.02, 0.07), 0.6)
		Models.part(head, Models.sphere(0.022, -1, 8), INK, Vector3(side * 0.125, 0.02, 0.095))
	return root


# --- Lotus bells and reed gates ----------------------------------------------------

## A lotus bell: a round stone basin of water with a lily pad and a lotus
## bud on top. Its petals ("Petal0".."Petal5" pivots) open when it is lit;
## "Heart" glows.
static func lotus(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.4, 0.42, 0.3, 20), BASIN, Vector3(0, 0.15, 0))
	Models.part(root, Models.cylinder(0.43, 0.43, 0.06, 20), BASIN.lightened(0.25), Vector3(0, 0.31, 0))
	_no_shadow(Models.part(root, Models.cylinder(0.35, 0.35, 0.02, 20), WATER, Vector3(0, 0.33, 0), 0.15))
	var pad := Models.part(root, Models.cylinder(0.3, 0.3, 0.035, 18), PAD, Vector3(0.02, 0.36, 0.02))
	pad.rotation.y = 0.4
	var bloom := Node3D.new()
	bloom.name = "Bloom"
	bloom.position = Vector3(0, 0.38, 0)
	root.add_child(bloom)
	var petal_mesh := Models.sphere(0.12, 0.3, 12)
	for k in 6:
		var pivot := Node3D.new()
		pivot.name = "Petal%d" % k
		pivot.rotation.y = TAU * k / 6.0
		bloom.add_child(pivot)
		var tilt := Node3D.new()
		tilt.name = "Tilt"
		pivot.add_child(tilt)
		var p := Models.part(tilt, petal_mesh, LOTUS_WHITE.lerp(color, 0.8 if k % 2 == 0 else 0.55), Vector3(0, 0.14, 0.05))
		p.scale = Vector3(0.75, 1.0, 0.45)
	var heart := _no_shadow(Models.part(bloom, Models.sphere(0.08, -1, 12), Color("#FFE27A"), Vector3(0, 0.1, 0), 0.4))
	heart.name = "Heart"
	return root


## A reed gate: a tight bundle of tall reeds with cattail heads, tied with
## a band in its group's colour. "Stalks" sinks into the ground when the
## gate opens.
static func reed_gate(color: Color, r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.86, 0.1, 0.86), 0.04), Color("#8FA87E"), Vector3(0, 0.05, 0))
	var stalks := Node3D.new()
	stalks.name = "Stalks"
	root.add_child(stalks)
	var spots: Array[Vector2] = [Vector2(-0.24, -0.14), Vector2(0.0, -0.2), Vector2(0.24, -0.12), Vector2(-0.14, 0.14), Vector2(0.14, 0.16), Vector2(0.0, 0.0)]
	for k in spots.size():
		var h: float = r.randf_range(0.85, 1.05)
		var s: Vector2 = spots[k]
		var stem := Models.part(stalks, Models.box_mesh(Vector3(0.11, h, 0.11), 0.045), REED if k % 2 == 0 else REED_DARK, Vector3(s.x, h * 0.5, s.y))
		stem.rotation = Vector3(r.randf_range(-0.06, 0.06), r.randf() * TAU, r.randf_range(-0.06, 0.06))
		if k % 2 == 0:
			Models.part(stalks, Models.box_mesh(Vector3(0.13, 0.24, 0.13), 0.06), CATTAIL, Vector3(s.x, h + 0.04, s.y))
	var band := Models.part(stalks, Models.box_mesh(Vector3(0.74, 0.1, 0.62), 0.05), color, Vector3(0, 0.42, -0.02), 0.25)
	band.name = "Band"
	return root


# --- Props -----------------------------------------------------------------------

static func reeds(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var n: int = r.randi_range(4, 7)
	for k in n:
		var h: float = r.randf_range(0.35, 0.8)
		var at := Vector3(r.randf_range(-0.25, 0.25), h * 0.5, r.randf_range(-0.25, 0.25))
		var blade := Models.part(root, Models.box_mesh(Vector3(0.06, h, 0.06), 0.025), REED if k % 2 == 0 else REED_DARK, at)
		blade.rotation = Vector3(r.randf_range(-0.2, 0.2), r.randf() * TAU, r.randf_range(-0.2, 0.2))
		if k % 3 == 0:
			Models.part(root, Models.box_mesh(Vector3(0.09, 0.18, 0.09), 0.04), CATTAIL, at + Vector3(0, h * 0.5 + 0.05, 0))
	return root


## A little pond: a pale water disc with lily pads and a lotus or two.
static func pond(r: RandomNumberGenerator, size: float = 0.7) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(size * 0.55, size * 0.58, 0.05, 20), BASIN.darkened(0.05), Vector3(0, 0.02, 0))
	_no_shadow(Models.part(root, Models.cylinder(size * 0.48, size * 0.48, 0.03, 20), WATER, Vector3(0, 0.04, 0), 0.1))
	for k in r.randi_range(1, 3):
		var a: float = r.randf() * TAU
		var pad := Models.part(root, Models.cylinder(0.11, 0.11, 0.02, 12), PAD, Vector3(cos(a) * size * 0.25, 0.065, sin(a) * size * 0.25))
		pad.rotation.y = r.randf() * TAU
		if r.randf() < 0.5:
			Models.part(root, Models.sphere(0.05, 0.08, 10), LOTUS_PINK if r.randf() < 0.5 else LOTUS_WHITE, pad.position + Vector3(0, 0.04, 0), 0.2)
	return root


static func mushroom(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(1, 3):
		var at := Vector3(r.randf_range(-0.2, 0.2), 0, r.randf_range(-0.2, 0.2))
		var h: float = r.randf_range(0.1, 0.2)
		Models.part(root, Models.cylinder(0.03, 0.04, h, 8), BELLY, at + Vector3(0, h * 0.5, 0))
		var cap := Models.part(root, Models.sphere(0.09, 0.1, 12), MUSHROOM if k % 2 == 0 else Color("#C9E6F2"), at + Vector3(0, h, 0), 0.15)
		cap.scale = Vector3(1.0, 1.0, 1.0)
	return root


## A drooping willow: a short trunk and a crown of long hanging leaf curtains.
static func willow(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.3, 0.25)
	Models.part(root, Models.cylinder(0.08, 0.12, 0.8, 8), Color("#8C7A6A"), Vector3(0, 0.4, 0))
	var green := Models.BLOSSOM_A.lerp(Models.BLOSSOM_B, r.randf())
	var crown := Models.part(root, Models.sphere(0.42, 0.42, 16), green, Vector3(0, 0.95, 0))
	crown.scale = Vector3(1.0, 1.0, 1.0)
	for k in 7:
		var a: float = TAU * k / 7.0 + r.randf() * 0.3
		var drape := Models.part(root, Models.box_mesh(Vector3(0.18, 0.62, 0.1), 0.05), green.lerp(Models.BLOSSOM_B, 0.3 * (k % 2)), Vector3(cos(a) * 0.38, 0.62, sin(a) * 0.38))
		drape.rotation.y = -a
		drape.rotation.z = 0.08
	return root


## A short stone lantern with a soft misty glow.
static func stone_lantern() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.26, 0.06, 0.26), 0.02), BASIN, Vector3(0, 0.03, 0))
	Models.part(root, Models.box_mesh(Vector3(0.1, 0.3, 0.1), 0.02), BASIN, Vector3(0, 0.2, 0))
	Models.part(root, Models.box_mesh(Vector3(0.22, 0.16, 0.22), 0.03), BASIN.lightened(0.1), Vector3(0, 0.43, 0))
	_no_shadow(Models.part(root, Models.box_mesh(Vector3(0.14, 0.1, 0.24), 0.02), Color("#FFF1C2"), Vector3(0, 0.43, 0), 1.4))
	Models.part(root, Models.cylinder(0.0, 0.2, 0.12, 4), BASIN.darkened(0.1), Vector3(0, 0.57, 0)).rotation.y = PI * 0.25
	return root


# --- Water ----------------------------------------------------------------------

## The still lake: glassy pale mint water with slow ripples, a silver sheen
## that drifts along it and a faint shimmer on the mirror line down its
## middle.
static func lake_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 shallow : source_color = vec4(0.42, 0.78, 0.84, 1.0);
uniform vec4 deep : source_color = vec4(0.2, 0.55, 0.68, 1.0);
uniform float axis_x = 6.0;
varying vec3 wp;
float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 w = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), w.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), w.x), w.y);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = mod(TIME, 600.0);
	vec2 p = wp.xz;
	float edge = abs(p.x - axis_x);
	float n1 = noise(p * vec2(2.0, 1.2) + vec2(t * 0.05, t * 0.11));
	float n2 = noise(p * vec2(3.6, 2.4) + vec2(-t * 0.07, t * 0.09));
	vec3 col = mix(deep.rgb, shallow.rgb, smoothstep(0.55, 0.05, edge) * 0.55 + n1 * 0.25);
	// Slow silver sheen bands drifting down the lake.
	float band = smoothstep(0.75, 1.0, sin(p.y * 0.9 - t * 0.6 + n2 * 1.5) * 0.5 + 0.5);
	col = mix(col, vec3(0.85, 0.95, 1.0), band * 0.2);
	// The mirror line: a thin, softly blinking silver thread.
	float line = 1.0 - smoothstep(0.0, 0.035, edge);
	float dash = step(0.45, fract(p.y * 1.5 - t * 0.25));
	col = mix(col, vec3(1.0), line * dash * 0.55);
	// Soft lilac on the reflection side of the lake.
	col = mix(col, vec3(0.45, 0.45, 0.8), smoothstep(0.1, 0.5, p.x - axis_x) * 0.15);
	float web = 1.0 - clamp(abs(n1 - n2) * 5.0, 0.0, 1.0);
	col += vec3(1.0) * pow(web, 5.0) * 0.12;
	ALBEDO = col;
	ROUGHNESS = 0.12;
	SPECULAR = 0.55;
	EMISSION = col * 0.08 + vec3(1.0) * line * dash * 0.25;
	vec3 nrm = normalize(vec3((n2 - 0.5) * 0.12, 1.0, (n1 - 0.5) * 0.12));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

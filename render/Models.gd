class_name Models
extends RefCounted
## Every 3D model in Boomlets, built in code from clay parts (no outside
## model files). Each builder returns a fresh Node3D standing on y = 0.
## Children named "Body" are the part the game squashes and bobs.

const BLOB_SHADER: Shader = preload("res://shaders/blob_shadow.gdshader")

# Colours (sRGB).
static var GRASS_A: Color = Color("#9AD27A")      # floor checker, light
static var GRASS_B: Color = Color("#86C46A")      # floor checker, dark
static var RIM: Color = Color("#86C46A")          # the island's top around the arena
static var EDGE: Color = Color("#5FA85A")         # the arena's hedge border
static var STONE: Color = Color("#E2D8CB")
static var DARK_STONE: Color = Color("#B3A496")
static var DIRT: Color = Color("#B98563")
static var ROCK: Color = Color("#C9B9A8")
static var WOOD: Color = Color("#DDA066")
static var WOOD_DARK: Color = Color("#B97A48")
static var INK: Color = Color("#2E2A4A")
static var WHITE: Color = Color("#FFFDF8")
static var HERO: Color = Color("#5CC8B4")
static var HERO_BELLY: Color = Color("#FFF1D6")
static var LEAF: Color = Color("#6CBF5A")
static var POD: Color = Color("#3B3A5C")
static var FLAME: Color = Color("#FF8A3D")
static var FLAME_CORE: Color = Color("#FFD45C")
static var BLOBBIT: Color = Color("#F28DB2")
static var BUZZER: Color = Color("#F3C623")
static var WISP: Color = Color("#B9A7F0")
static var BOSS: Color = Color("#8A6A52")
static var BOSS_SPIKE: Color = Color("#F4DEAA")
static var GOLD: Color = Color("#F3C623")
static var BARREL: Color = Color("#E4572E")
static var BELT: Color = Color("#6B6580")
static var ACCENT: Color = Color("#F2A541")
static var MARKER: Color = Color("#FFF6E8")
static var BLOSSOM_A: Color = Color("#6CBF5A")    # tree leaves
static var BLOSSOM_B: Color = Color("#4FA463")
static var TRUNK: Color = Color("#8B5E3C")
static var LEAFY_A: Color = Color("#7BC66A")      # bushes
static var LEAFY_B: Color = Color("#5DAE5E")

# The sky and light that go with the palette.
static var SKY_TOP: Color = Color("#8EC5EC")
static var SKY_HORIZON: Color = Color("#FCEFD9")
static var SKY_GROUND: Color = Color("#D6E2DC")
static var CLOUD: Color = Color("#FFFFFF")
static var CLOUDS: float = 0.6
static var AMBIENT: Color = Color("#AFC8EA")
static var AMBIENT_ENERGY: float = 0.5
static var SUN: Color = Color("#FFF0DC")
static var SUN_ENERGY: float = 1.55

## Colour themes for the world. "meadow" is the original look; the others
## change only what they list. Pick one with [method use_palette].
const PALETTES: Dictionary = {
	"meadow": {},
	"candy_coast": {
		"GRASS_A": "#F6DEB0", "GRASS_B": "#EDCF98", "RIM": "#F2D49C", "EDGE": "#3FA7D6",
		"STONE": "#FFF6EA", "DARK_STONE": "#D9CBB8", "DIRT": "#E8B07A", "ROCK": "#D9A77C",
		"WOOD": "#FF7F6B", "WOOD_DARK": "#E0584F", "BARREL": "#3F7FE0", "FLAME_CORE": "#FFE36E",
		"BLOSSOM_A": "#4DBF7A", "BLOSSOM_B": "#2FA36B", "TRUNK": "#A8743F", "LEAFY_A": "#6FD39B", "LEAFY_B": "#45B883",
		"SKY_TOP": "#39C5D9", "SKY_HORIZON": "#FFF3D6", "SKY_GROUND": "#BFEFF0", "AMBIENT": "#B9E6EE", "SUN": "#FFF3DF",
	},
	"berry_choco": {
		"GRASS_A": "#FBD9E1", "GRASS_B": "#F5C6D2", "RIM": "#F2B8C8", "EDGE": "#6B3F2A",
		"STONE": "#E3D0BC", "DARK_STONE": "#C2A98F", "DIRT": "#8E5B3E", "ROCK": "#6E4630",
		"WOOD": "#9B6340", "WOOD_DARK": "#FFF0D0", "BLOBBIT": "#A6E36B",
		"BLOSSOM_A": "#8EDFC1", "BLOSSOM_B": "#6CCFAE", "TRUNK": "#6E4630", "LEAFY_A": "#9FE6CC", "LEAFY_B": "#7FD8B8",
		"SKY_TOP": "#F7A8C4", "SKY_HORIZON": "#FFF4DA", "SKY_GROUND": "#FBE3E9", "AMBIENT": "#F3D3E0", "SUN": "#FFF0DC",
	},
	"neon_night": {
		"GRASS_A": "#363C7C", "GRASS_B": "#2C316B", "RIM": "#262A5C", "EDGE": "#7A4BE0",
		"STONE": "#5464C8", "DARK_STONE": "#3A4590", "DIRT": "#2C2556", "ROCK": "#221D45",
		"WOOD": "#FF5FA2", "WOOD_DARK": "#FFD166", "HERO": "#5CE8C8", "POD": "#ECE9FF",
		"FLAME": "#39E6FF", "FLAME_CORE": "#F2FFFF", "BLOBBIT": "#B6FF5C", "WISP": "#9FE3FF",
		"BARREL": "#FF8A3D", "BELT": "#1E2250", "ACCENT": "#39E6FF",
		"BLOSSOM_A": "#3FD9B0", "BLOSSOM_B": "#2BB7C9", "TRUNK": "#4A3B7A", "LEAFY_A": "#FF6FB5", "LEAFY_B": "#B07BFF",
		"SKY_TOP": "#0E1033", "SKY_HORIZON": "#6A2F8F", "SKY_GROUND": "#1A1440", "CLOUD": "#4A3C7E", "CLOUDS": 0.35,
		"AMBIENT": "#6A74C8", "AMBIENT_ENERGY": 0.7, "SUN": "#C9D2FF", "SUN_ENERGY": 1.1,
	},
	"plum_cocoa": {
		"GRASS_A": "#5B3F7A", "GRASS_B": "#4E3570", "RIM": "#3F2B5E", "EDGE": "#6B3F2A",
		"STONE": "#C9B9CC", "DARK_STONE": "#9E8AA3", "DIRT": "#5A3726", "ROCK": "#3E2A40",
		"WOOD": "#FF8FB8", "WOOD_DARK": "#FFE3A3", "POD": "#F4EBFF", "BLOBBIT": "#B6FF5C",
		"BELT": "#2E2147", "ACCENT": "#FFC36B",
		"BLOSSOM_A": "#FF9EC4", "BLOSSOM_B": "#E07BB0", "TRUNK": "#6B3F2A", "LEAFY_A": "#B48CF0", "LEAFY_B": "#9670DB",
		"SKY_TOP": "#2B1D4F", "SKY_HORIZON": "#C9709A", "SKY_GROUND": "#2A1F45", "CLOUD": "#7A5A9E", "CLOUDS": 0.4,
		"AMBIENT": "#9C86C8", "AMBIENT_ENERGY": 0.65, "SUN": "#FFE2C4", "SUN_ENERGY": 1.3,
	},
	"frost_gift": {
		"GRASS_A": "#EEF6FB", "GRASS_B": "#DCEBF5", "RIM": "#F7FBFE", "EDGE": "#2F7A63",
		"STONE": "#A9D6EE", "DARK_STONE": "#7FB8DA", "DIRT": "#BFD9EA", "ROCK": "#8FAFC8",
		"WOOD": "#E8505B", "WOOD_DARK": "#F7C948",
		"BLOSSOM_A": "#2F7A63", "BLOSSOM_B": "#3E9A7A", "TRUNK": "#7A5A44", "LEAFY_A": "#DDEFFA", "LEAFY_B": "#BFE0F2",
		"SKY_TOP": "#9DB8F0", "SKY_HORIZON": "#FFE3EC", "SKY_GROUND": "#E4EEF7", "AMBIENT": "#C5D8F2", "SUN": "#FFF0E6",
	},
}
static var _defaults: Dictionary = {}
## Set by dev tools that force a palette, so the world's own one is skipped.
static var palette_locked: bool = false


## Switches every colour to [param name]'s palette (see [constant PALETTES]).
## Call before building an arena.
static func use_palette(name: Variant) -> void:
	var script: GDScript = load("res://render/Models.gd")
	for key: String in _defaults:
		script.set(key, _defaults[key])
	var pal: Dictionary = name if name is Dictionary else PALETTES.get(name, {})
	for key: String in pal:
		# Only keys stored here are ever changed, so an unseen key still holds
		# its default.
		if not _defaults.has(key):
			_defaults[key] = script.get(key)
		var v: Variant = pal[key]
		script.set(key, Color(v) if v is String else v)


static var _boxes: Dictionary = {}
static var _glass: Dictionary = {}

## When on, crates (and the shards they break into) and the HUD are frosted
## glass instead of clay and cream cards.
static var GLASS: bool = true
const GLASS_SHADER: Shader = preload("res://shaders/glass.gdshader")


static func mat(color: Color, glow: float = 0.0) -> ShaderMaterial:
	return ClayShapes.material(color, glow)


## Shared frosted-glass material in [param color].
static func glass(color: Color, tint: float = 0.3, glow: float = 0.0) -> ShaderMaterial:
	var key: String = "%s/%.2f/%.2f" % [color.to_html(), tint, glow]
	if not _glass.has(key):
		var m := ShaderMaterial.new()
		m.shader = GLASS_SHADER
		m.set_shader_parameter(&"albedo", color)
		m.set_shader_parameter(&"tint", tint)
		m.set_shader_parameter(&"glow", glow)
		_glass[key] = m
	return _glass[key]


static func box_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var key: String = "%s/%.3f" % [size, radius]
	if not _boxes.has(key):
		_boxes[key] = ClayShapes.rounded_box(size, radius)
	return _boxes[key]


static func part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, glow: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat(color, glow)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func sphere(r: float, h: float = -1.0, segs: int = 20) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0 if h < 0.0 else h
	s.radial_segments = segs
	s.rings = maxi(segs / 2, 6)
	return s


static func cylinder(top: float, bottom: float, h: float, segs: int = 16) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


static func blob_shadow(parent: Node3D, size: float, strength: float = 0.38) -> MeshInstance3D:
	var plane := PlaneMesh.new()
	plane.size = Vector2(size, size)
	var m := ShaderMaterial.new()
	m.shader = BLOB_SHADER
	m.set_shader_parameter(&"strength", strength)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.material_override = m
	mi.position.y = 0.025
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.name = "Shadow"
	parent.add_child(mi)
	return mi


static func _eyes(body: Node3D, y: float, z: float, spread: float, size: float, angry: bool = false) -> void:
	for side: int in [-1, 1]:
		var eye := part(body, sphere(size, size * 2.2, 14), WHITE, Vector3(side * spread, y, z))
		eye.scale = Vector3(1.0, 1.0, 0.6)
		var pupil := part(body, sphere(size * 0.55, -1, 12), INK, Vector3(side * spread, y - size * 0.1, z + size * 0.45))
		pupil.scale = Vector3(1.0, 1.15, 0.6)
		part(body, sphere(size * 0.16, -1, 8), WHITE, Vector3(side * spread + size * 0.18, y + size * 0.2, z + size * 0.75), 1.0)
		if angry:
			var brow := part(body, box_mesh(Vector3(size * 1.9, size * 0.42, size * 0.4), 0.02), INK, Vector3(side * spread, y + size * 1.15, z + size * 0.2))
			brow.rotation.z = side * -0.45


## Pip, the hero: a round teal clay bean with a leaf sprout and stubby feet.
static func hero() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.95)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := part(body, sphere(0.34, 0.74, 24), HERO, Vector3(0, 0.42, 0))
	shell.scale = Vector3(1.0, 1.0, 0.92)
	var belly := part(body, sphere(0.25, 0.46, 18), HERO_BELLY, Vector3(0, 0.36, 0.16))
	belly.scale = Vector3(1.0, 1.0, 0.6)
	_eyes(body, 0.55, 0.26, 0.12, 0.085)
	# Blush.
	for side: int in [-1, 1]:
		var cheek := part(body, sphere(0.045, -1, 8), Color("#FF9AA8"), Vector3(side * 0.22, 0.45, 0.25))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	# Sprout: a stem and two leaves.
	part(body, cylinder(0.018, 0.025, 0.16, 8), Color("#4E9A45"), Vector3(0, 0.84, 0))
	for side: int in [-1, 1]:
		var leaf := part(body, sphere(0.08, 0.05, 12), LEAF, Vector3(side * 0.08, 0.92, 0))
		leaf.scale = Vector3(1.4, 1.0, 0.8)
		leaf.rotation.z = side * -0.5
	# Feet.
	for side: int in [-1, 1]:
		var foot := part(body, sphere(0.09, 0.1, 12), Color("#3E9C8B"), Vector3(side * 0.15, 0.05, 0.05))
		foot.name = "FootL" if side < 0 else "FootR"
		foot.scale = Vector3(1.0, 1.0, 1.4)
	return root


## Fizz pod: a navy clay ball with a cream band, a short wick and a spark.
static func pod() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.8, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	part(body, sphere(0.3, 0.6, 22), POD, Vector3(0, 0.32, 0))
	var band := part(body, cylinder(0.305, 0.305, 0.07, 22), Color("#FFE9C4"), Vector3(0, 0.32, 0))
	band.name = "Band"
	part(body, cylinder(0.07, 0.09, 0.08, 10), Color("#6E6C8E"), Vector3(0, 0.63, 0))
	var wick := part(body, cylinder(0.018, 0.018, 0.14, 6), Color("#8B6B4A"), Vector3(0.03, 0.72, 0))
	wick.rotation.z = -0.3
	var spark := part(body, sphere(0.06, -1, 8), FLAME_CORE, Vector3(0.06, 0.8, 0), 2.5)
	spark.name = "Spark"
	return root


## Blobbit: a wobbly pink jelly dome. Wanders.
static func blobbit() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.95)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var dome := part(body, sphere(0.36, 0.6, 22), BLOBBIT, Vector3(0, 0.26, 0))
	dome.scale = Vector3(1.0, 1.0, 1.0)
	part(body, sphere(0.1, -1, 10), BLOBBIT.lightened(0.35), Vector3(-0.15, 0.46, 0.1))
	_eyes(body, 0.32, 0.27, 0.11, 0.075)
	var mouth := part(body, box_mesh(Vector3(0.1, 0.035, 0.03), 0.012), INK, Vector3(0, 0.2, 0.33))
	mouth.rotation.x = -0.2
	return root


## Buzzer: a round yellow bee with stripes and flapping wings. Chases.
static func buzzer() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.8, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	part(body, sphere(0.28, 0.56, 22), BUZZER, Vector3(0, 0.55, 0))
	for k in 2:
		var stripe := part(body, cylinder(0.27 - k * 0.04, 0.28 - k * 0.04, 0.06, 20), INK, Vector3(0, 0.55, -0.05 - k * 0.13))
		stripe.rotation.x = PI * 0.5
	var sting := part(body, cylinder(0.0, 0.05, 0.14, 8), INK, Vector3(0, 0.55, -0.33))
	sting.rotation.x = -PI * 0.5
	_eyes(body, 0.62, 0.22, 0.1, 0.07, true)
	for side: int in [-1, 1]:
		var wing := part(body, sphere(0.16, 0.04, 12), Color("#EAF6FF"), Vector3(side * 0.24, 0.84, -0.04), 0.3)
		wing.scale = Vector3(1.0, 1.0, 0.6)
		wing.name = "WingL" if side < 0 else "WingR"
	return root


## Wisp: a floating lilac puff that drifts through crates.
static func wisp() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.7, 0.22)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	part(body, sphere(0.3, 0.62, 20), WISP, Vector3(0, 0.62, 0), 0.35)
	for k in 3:
		var a: float = TAU * k / 3.0
		part(body, sphere(0.11, -1, 10), WISP, Vector3(cos(a) * 0.17, 0.36, sin(a) * 0.17 - 0.05), 0.35)
	_eyes(body, 0.66, 0.24, 0.1, 0.07)
	return root


## Thornback, World 1's boss: a big round hedgehog-like critter with a back
## of cream spikes and a little gold crown.
static func boss() -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 1.9, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var dome := part(body, sphere(0.72, 1.2, 28), BOSS, Vector3(0, 0.62, 0))
	dome.name = "Dome"
	part(body, sphere(0.42, 0.62, 20), Color("#E9C9A3"), Vector3(0, 0.58, 0.42)).scale = Vector3(1.0, 1.0, 0.6)
	var spike_mesh := cylinder(0.0, 0.12, 0.42, 10)
	for ring in 4:
		var el: float = 0.2 + ring * 0.38
		var count: int = 7 - ring
		for k in count:
			var a: float = -PI * (0.08 + 0.84 * (k + 0.5) / count)
			var dir := Vector3(cos(a) * cos(el), sin(el), sin(a) * cos(el)).normalized()
			var s := part(body, spike_mesh, BOSS_SPIKE, Vector3(0, 0.62, 0) + dir * 0.64)
			var up: Vector3 = Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD
			s.transform = Transform3D(Basis.looking_at(dir, up) * Basis(Vector3.RIGHT, -PI * 0.5), s.position)
	_eyes(body, 0.82, 0.55, 0.2, 0.12, true)
	part(body, sphere(0.09, -1, 10), INK, Vector3(0, 0.66, 0.72))
	var crown := Node3D.new()
	crown.position = Vector3(0, 1.22, 0.05)
	body.add_child(crown)
	part(crown, cylinder(0.2, 0.2, 0.14, 14), GOLD, Vector3.ZERO, 0.2)
	for k in 5:
		var a2: float = TAU * k / 5.0
		part(crown, cylinder(0.0, 0.06, 0.16, 6), GOLD, Vector3(cos(a2) * 0.16, 0.14, sin(a2) * 0.16), 0.2)
	for side: int in [-1, 1]:
		part(body, sphere(0.16, 0.16, 12), BOSS.darkened(0.25), Vector3(side * 0.42, 0.08, 0.3)).scale = Vector3(1, 1, 1.4)
	return root


static func barrel() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	part(body, cylinder(0.3, 0.3, 0.72, 20), BARREL, Vector3(0, 0.38, 0))
	part(body, sphere(0.3, 0.2, 20), BARREL, Vector3(0, 0.74, 0))
	for y: float in [0.16, 0.6]:
		part(body, cylinder(0.315, 0.315, 0.07, 20), Color("#F7D774"), Vector3(0, y, 0))
	# A little flame mark on the front.
	var mark := part(body, sphere(0.09, 0.2, 10), FLAME_CORE, Vector3(0, 0.38, 0.28), 0.6)
	mark.scale = Vector3(1, 1, 0.4)
	return root


## The exit: a stone ring around a swirl pad, with a pennant post.
static func exit_gate() -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.44
	ring.rings = 24
	ring.ring_segments = 10
	var r := part(root, ring, STONE, Vector3(0, 0.05, 0))
	r.scale = Vector3(1, 0.6, 1)
	var disc := part(root, cylinder(0.31, 0.31, 0.04, 24), Color("#8E86A8"), Vector3(0, 0.04, 0))
	disc.name = "Disc"
	part(root, cylinder(0.025, 0.03, 1.1, 8), Color("#7D6F66"), Vector3(0.36, 0.55, -0.3))
	var flag := part(root, ClayShapes.extrusion(PackedVector2Array([Vector2(0, 0), Vector2(0.36, -0.1), Vector2(0, -0.22)]), 0.03, 0.01, 1), ACCENT, Vector3(0.38, 0.4, -0.3))
	flag.name = "Flag"
	return root


static func teleporter(color: Color) -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.28
	ring.outer_radius = 0.4
	ring.rings = 24
	ring.ring_segments = 8
	part(root, ring, color, Vector3(0, 0.04, 0)).scale = Vector3(1, 0.5, 1)
	part(root, cylinder(0.3, 0.3, 0.03, 24), color.lightened(0.45), Vector3(0, 0.03, 0), 0.6)
	var orbit := Node3D.new()
	orbit.name = "Orbit"
	root.add_child(orbit)
	for k in 3:
		var a: float = TAU * k / 3.0
		part(orbit, sphere(0.05, -1, 8), color.lightened(0.6), Vector3(cos(a) * 0.3, 0.18, sin(a) * 0.3), 1.2)
	return root


## Where a tap sent Pip: a glowing ring with four little studs.
static func walk_marker() -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.38
	ring.rings = 28
	ring.ring_segments = 8
	var r := part(root, ring, MARKER, Vector3(0, 0.04, 0), 0.9)
	r.scale = Vector3(1, 0.35, 1)
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 4:
		var a: float = TAU * k / 4.0
		var s := part(root, sphere(0.05, -1, 8), MARKER, Vector3(cos(a) * 0.34, 0.07, sin(a) * 0.34), 1.2)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## A power-up coin: a coloured disc with an icon on top.
static func powerup(kind: StringName) -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 0.7, 0.25)
	var body := Node3D.new()
	body.name = "Body"
	body.position.y = 0.35
	root.add_child(body)
	var colors := {&"bomb": Color("#FFD166"), &"fire": Color("#FF7A59"), &"speed": Color("#7BD389"),
		&"kick": Color("#6EC6EA"), &"shield": Color("#B8A6F2"), &"heart": Color("#FFB3C7")}
	var disc := part(body, cylinder(0.32, 0.32, 0.12, 24), colors.get(kind, WHITE), Vector3.ZERO, 0.25)
	disc.rotation.x = PI * 0.5
	part(body, cylinder(0.26, 0.26, 0.13, 24), WHITE).rotation.x = PI * 0.5
	var icon := Node3D.new()
	icon.position.z = 0.08
	body.add_child(icon)
	match kind:
		&"bomb":
			part(icon, sphere(0.13, -1, 14), POD, Vector3(0, -0.02, 0))
			part(icon, sphere(0.035, -1, 8), FLAME_CORE, Vector3(0.06, 0.14, 0), 2.0)
		&"fire":
			part(icon, sphere(0.12, 0.2, 12), FLAME, Vector3(0, -0.04, 0), 0.6)
			var tip := part(icon, cylinder(0.0, 0.1, 0.16, 10), FLAME, Vector3(0, 0.1, 0), 0.6)
			tip.scale = Vector3(1, 1, 0.8)
			part(icon, sphere(0.06, -1, 8), FLAME_CORE, Vector3(0, -0.04, 0.06), 1.0)
		&"speed":
			var bolt := PackedVector2Array([Vector2(0.04, 0.17), Vector2(-0.1, -0.01), Vector2(-0.01, -0.01), Vector2(-0.05, -0.17), Vector2(0.1, 0.03), Vector2(0.01, 0.03)])
			part(icon, ClayShapes.extrusion(bolt, 0.06, 0.015, 1), Color("#F3C623"), Vector3.ZERO, 0.3)
		&"kick":
			var boot := PackedVector2Array([Vector2(-0.08, 0.15), Vector2(0.02, 0.15), Vector2(0.02, -0.03), Vector2(0.14, -0.05), Vector2(0.14, -0.14), Vector2(-0.08, -0.14)])
			part(icon, ClayShapes.extrusion(ClayShapes.rounded_polygon(boot, 0.03), 0.07, 0.02, 2), Color("#E4572E"))
		&"shield":
			part(icon, sphere(0.14, -1, 14), Color("#DDE9FF"), Vector3.ZERO, 0.4)
			part(icon, sphere(0.04, -1, 8), WHITE, Vector3(-0.05, 0.05, 0.11), 1.0)
		&"heart":
			var pts := PackedVector2Array()
			for k in 24:
				var t: float = TAU * k / 24.0
				pts.append(Vector2(16.0 * pow(sin(t), 3.0), 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)) * 0.009)
			part(icon, ClayShapes.extrusion(pts, 0.07, 0.02, 2), Color("#E4572E"), Vector3(0, 0.0, 0), 0.2)
	return root


## A flat chevron for conveyor belts, pointing +X.
static func chevron_mesh() -> ArrayMesh:
	var key := "chevron"
	if not _boxes.has(key):
		var pts := PackedVector2Array([Vector2(-0.14, 0.22), Vector2(0.0, 0.22), Vector2(0.16, 0.0), Vector2(0.0, -0.22), Vector2(-0.14, -0.22), Vector2(0.02, 0.0)])
		_boxes[key] = ClayShapes.extrusion(pts, 0.03, 0.01, 1)
	return _boxes[key]


static func tree(tall: bool, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	blob_shadow(root, 1.0, 0.3)
	var h: float = 0.9 if tall else 0.55
	part(root, cylinder(0.06, 0.08, h * 0.5, 8), TRUNK, Vector3(0, h * 0.25, 0))
	var green := BLOSSOM_A.lerp(BLOSSOM_B, rng.randf())
	if tall:
		for k in 3:
			var cone := part(root, cylinder(0.0, 0.38 - k * 0.09, 0.42, 14), green, Vector3(0, h * 0.42 + k * 0.24, 0))
			cone.scale = Vector3(1, 1, 1)
	else:
		part(root, sphere(0.32, 0.56, 16), green, Vector3(0, h * 0.62, 0))
		part(root, sphere(0.2, 0.34, 12), green.lightened(0.08), Vector3(0.14, h * 0.9, 0.05))
	return root


static func bush(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var green := LEAFY_A.lerp(LEAFY_B, rng.randf())
	for k in 3:
		var a: float = TAU * k / 3.0 + rng.randf()
		part(root, sphere(0.17 + rng.randf() * 0.06, -1, 12), green, Vector3(cos(a) * 0.13, 0.15, sin(a) * 0.13))
	if rng.randf() < 0.5:
		for k in 3:
			part(root, sphere(0.04, -1, 6), [Color("#FF8FA3"), Color("#FFE27A"), WHITE][k], Vector3(rng.randf_range(-0.2, 0.2), 0.3, rng.randf_range(-0.2, 0.2)))
	return root


static func lamp() -> Node3D:
	var root := Node3D.new()
	part(root, cylinder(0.04, 0.05, 1.1, 8), INK.lightened(0.15), Vector3(0, 0.55, 0))
	part(root, cylinder(0.1, 0.1, 0.05, 10), INK.lightened(0.15), Vector3(0, 0.03, 0))
	part(root, sphere(0.11, 0.16, 12), Color("#FFE7A8"), Vector3(0, 1.16, 0), 1.6)
	part(root, cylinder(0.0, 0.14, 0.1, 10), INK.lightened(0.15), Vector3(0, 1.27, 0))
	return root


static func flowers(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in 4:
		var p := Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
		part(root, cylinder(0.01, 0.01, 0.16, 4), Color("#4E9A45"), p + Vector3(0, 0.08, 0))
		part(root, sphere(0.045, -1, 8), [Color("#FF8FA3"), Color("#FFE27A"), WHITE, Color("#B9A7F0")][rng.randi() % 4], p + Vector3(0, 0.17, 0))
	return root


static func rock(rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var r := part(root, sphere(0.22, 0.3, 10), ROCK.darkened(rng.randf() * 0.1), Vector3(0, 0.08, 0))
	r.scale = Vector3(1.2, 1, 0.9)
	r.rotation.y = rng.randf() * TAU
	return root

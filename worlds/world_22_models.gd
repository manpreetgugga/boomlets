extends RefCounted
## Models for World 22, Comet Orbit: a playful little planetoid in space.
## Planet blocks (a banded clay globe on a pedestal, girdled by a ring whose
## gold arrows show which way its moons orbit), the round orbiting asteroids
## (cute little rocks), the UFO saucer critter with its warning spot and
## tractor beam, the Moon Whale boss and the space props: crystals, moon
## rocks, tiny rockets, dishes, beacons and big ringed planets for the sky.

const CORAL := Color("#FF8C8C")
const CORAL_DARK := Color("#E8667A")
const CREAM := Color("#FFF4E2")
const GOLD := Color("#FFC94D")
const MINT := Color("#62D8B6")
const MINT_DARK := Color("#3FB59A")
const PINK := Color("#FF9ECF")
const LILAC := Color("#B49CFF")
const SKY := Color("#8FC8FF")
const INK := Color("#3A3256")
const ROCK := Color("#DCA27A")
const ROCK_DARK := Color("#B47C5A")
const ROCK_LIGHT := Color("#F3D0B0")
const SAUCER := Color("#5CCBC0")
const SAUCER_RIM := Color("#F4F1FF")
const ALIEN := Color("#A8E85C")
const BEAM := Color("#FFE57A")
const WHALE := Color("#7C8CF0")
const WHALE_DARK := Color("#5F6BD0")
const WHALE_BELLY := Color("#FFEBD6")
const CRYSTAL_COLORS: Array[Color] = [Color("#8FE3FF"), Color("#FFA8DD"), Color("#B9A2FF"), Color("#8AF0C8")]
const PLANET_COLORS: Array = [[Color("#FF8C8C"), Color("#FFD0A6")], [Color("#7FD3FF"), Color("#D8F2FF")], [Color("#9FE38C"), Color("#E8FFC9")], [Color("#FFB86B"), Color("#FFE6B3")]]
const UFO_SIZE: float = 1.15
const BOSS_SIZE: float = 1.5
const AST_SIZE: float = 1.2

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A soft-edged five-point star, flat in XY, [param d] deep.
static func star_mesh(r: float, d: float) -> ArrayMesh:
	var key := "star/%.3f/%.3f" % [r, d]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = PI * 0.5 + TAU * k / 10.0
			var rr: float = r if k % 2 == 0 else r * 0.48
			pts.append(Vector2(cos(a), sin(a)) * rr)
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, r * 0.08, 2), d, d * 0.3, 1)
	return _shapes[key]


## A faceted gem: an eight-sided prism with pointed ends.
static func gem_mesh(r: float, h: float) -> CylinderMesh:
	return Models.cylinder(r, r, h, 6)


static func translucent(color: Color, alpha: float, glow: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(color, alpha)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = glow
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


# --- Planets and asteroids ------------------------------------------------------------

## A planet block: a pedestal, a banded globe ("Globe") and the spin ring
## ("Ring") whose "Arrows" point the way its asteroids orbit (clockwise seen
## from above; mirror "Arrows" for anticlockwise).
static func planet(colors: Array) -> Node3D:
	var root := Node3D.new()
	var a: Color = colors[0]
	var b: Color = colors[1]
	Models.part(root, Models.cylinder(0.36, 0.42, 0.14, 20), Color("#D9CFF2"), Vector3(0, 0.07, 0))
	Models.part(root, Models.cylinder(0.3, 0.34, 0.06, 20), Color("#EEE8FB"), Vector3(0, 0.16, 0))
	var globe := Node3D.new()
	globe.name = "Globe"
	globe.position = Vector3(0, 0.52, 0)
	root.add_child(globe)
	Models.part(globe, Models.sphere(0.32, -1, 24), a)
	for y: float in [-0.12, 0.1]:
		var band := Models.part(globe, Models.cylinder(0.31 - absf(y) * 0.3, 0.31 - absf(y) * 0.3, 0.07, 24), b, Vector3(0, y, 0))
		band.scale = Vector3(1.02, 1.0, 1.02)
	# A little face, so the planet reads as friendly.
	for side: int in [-1, 1]:
		_no_shadow(Models.part(globe, Models.sphere(0.035, -1, 8), INK, Vector3(side * 0.09, 0.03, 0.29)))
		var cheek := _no_shadow(Models.part(globe, Models.sphere(0.035, -1, 8), Color("#FF7A9C"), Vector3(side * 0.17, -0.04, 0.26)))
		cheek.scale = Vector3(1.0, 0.6, 0.5)
	var smile := Models.part(globe, _box(Vector3(0.07, 0.018, 0.02), 0.008), INK, Vector3(0, -0.04, 0.315))
	smile.rotation.x = -0.25
	var ring := Node3D.new()
	ring.name = "Ring"
	ring.position = Vector3(0, 0.52, 0)
	ring.rotation = Vector3(0.32, 0, 0.12)
	root.add_child(ring)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.42
	torus.outer_radius = 0.52
	torus.rings = 32
	torus.ring_segments = 6
	var t := Models.part(ring, torus, CREAM)
	t.scale = Vector3(1.0, 0.35, 1.0)
	var arrows := Node3D.new()
	arrows.name = "Arrows"
	ring.add_child(arrows)
	var spin := Node3D.new()
	spin.name = "Spin"
	arrows.add_child(spin)
	# Three gold chevrons riding the ring, pointing clockwise seen from above
	# (at +X that is towards +Z). Spin turns them; mirroring "Arrows" in Z
	# turns both the chevrons and the spin round.
	for k in 3:
		var at: float = TAU * k / 3.0
		var holder := Node3D.new()
		holder.rotation.y = at
		spin.add_child(holder)
		var ch := Models.part(holder, Models.chevron_mesh(), GOLD, Vector3(0.47, 0.05, 0), 0.7)
		ch.rotation = Vector3(-PI * 0.5, -PI * 0.5, 0)
		ch.scale = Vector3(0.75, 0.75, 1.6)
		_no_shadow(ch)
	return root


## An asteroid: a chunky faceted rock ("Rock", which rolls) with craters and
## a sleepy little face, and a "Ghost" of pebbles and a floor ring shown
## while it is rubble.
static func asteroid(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var rock := Node3D.new()
	rock.name = "Rock"
	rock.position = Vector3(0, 0.4, 0)
	body.add_child(rock)
	var tone: Color = ROCK.lerp(ROCK_LIGHT, r.randf() * 0.35)
	var main := Models.part(rock, Models.sphere(0.36, -1, 9), tone)
	main.scale = Vector3(1.0, 0.94, 0.98)
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf() * 0.6
		var el: float = r.randf_range(0.1, 0.9)
		var dir := Vector3(cos(a) * cos(el), sin(el), sin(a) * cos(el))
		if dir.z > 0.5 and dir.y < 0.45:
			dir = Vector3(dir.x, dir.y + 0.5, -dir.z).normalized()
		var crater := Models.part(rock, Models.cylinder(0.09, 0.07, 0.05, 10), ROCK_DARK, dir * 0.33)
		crater.transform = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.FORWARD) * Basis(Vector3.RIGHT, PI * 0.5), dir * 0.33)
		crater.scale = Vector3.ONE * r.randf_range(0.8, 1.3)
	var bump := Models.part(rock, Models.sphere(0.16, -1, 7), tone.darkened(0.06), Vector3(r.randf_range(-0.2, 0.2), 0.22, -0.12))
	bump.scale = Vector3(1.0, 0.7, 1.0)
	# Face on the front (+Z): closed sleepy eyes and blush; it does not roll
	# with the rock.
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.4, 0)
	body.add_child(face)
	for side: int in [-1, 1]:
		var eye := Models.part(face, _box(Vector3(0.08, 0.022, 0.02), 0.009), INK, Vector3(side * 0.11, 0.06, 0.345))
		eye.rotation.z = side * 0.18
		var cheek := _no_shadow(Models.part(face, Models.sphere(0.04, -1, 8), Color("#FF9AA8"), Vector3(side * 0.19, -0.02, 0.31)))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	var ghost := Node3D.new()
	ghost.name = "Ghost"
	ghost.visible = false
	root.add_child(ghost)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.36
	ring.rings = 24
	ring.ring_segments = 4
	var gr := _no_shadow(Models.part(ghost, ring, ROCK_LIGHT, Vector3(0, 0.04, 0), 0.5))
	gr.name = "GhostRing"
	gr.scale = Vector3(1, 0.3, 1)
	var orbit := Node3D.new()
	orbit.name = "Pebbles"
	ghost.add_child(orbit)
	for k in 5:
		var a2: float = TAU * k / 5.0
		var p := Models.part(orbit, Models.sphere(0.06 + 0.02 * (k % 2), -1, 6), ROCK.darkened(0.05 * (k % 3)), Vector3(cos(a2) * 0.22, 0.1 + 0.05 * (k % 2), sin(a2) * 0.22))
		p.rotation = Vector3(k, k * 2.0, 0)
	return root


# --- Critters ------------------------------------------------------------------------

## UFO saucer: a teal disc with a cream rim of blinking lights ("Lights"),
## a glass dome with a little green pilot ("Pilot"), all on "Hover". Root
## children "Mark" (the warning spot one tile ahead) and "Beam" (the light
## cone) are hidden until it charges and fires. It faces +Z.
static func ufo() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.26)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * UFO_SIZE
	root.add_child(body)
	var hover := Node3D.new()
	hover.name = "Hover"
	hover.position.y = 0.5
	body.add_child(hover)
	var disc := Models.part(hover, Models.sphere(0.36, 0.2, 22), SAUCER)
	disc.scale = Vector3(1.0, 1.0, 1.0)
	Models.part(hover, Models.cylinder(0.37, 0.37, 0.05, 24), SAUCER_RIM, Vector3(0, 0.0, 0))
	Models.part(hover, Models.cylinder(0.16, 0.24, 0.08, 18), SAUCER.darkened(0.15), Vector3(0, -0.1, 0))
	var glow := _no_shadow(Models.part(hover, Models.cylinder(0.12, 0.12, 0.03, 16), BEAM, Vector3(0, -0.145, 0), 1.2))
	glow.name = "Glow"
	var lights := Node3D.new()
	lights.name = "Lights"
	hover.add_child(lights)
	for k in 8:
		var a: float = TAU * k / 8.0
		var col: Color = GOLD if k % 2 == 0 else PINK
		_no_shadow(Models.part(lights, Models.sphere(0.035, -1, 8), col, Vector3(cos(a) * 0.33, 0.02, sin(a) * 0.33), 1.4))
	# The pilot in a glass dome.
	var pilot := Node3D.new()
	pilot.name = "Pilot"
	pilot.position = Vector3(0, 0.08, 0)
	hover.add_child(pilot)
	Models.part(pilot, Models.sphere(0.12, 0.2, 14), ALIEN, Vector3(0, 0.08, 0))
	var eye := Models.part(pilot, Models.sphere(0.055, -1, 12), Models.WHITE, Vector3(0, 0.11, 0.09))
	eye.scale = Vector3(1.0, 1.0, 0.6)
	Models.part(pilot, Models.sphere(0.03, -1, 8), INK, Vector3(0, 0.105, 0.12))
	for side: int in [-1, 1]:
		var ant := Models.part(pilot, Models.cylinder(0.008, 0.01, 0.1, 5), ALIEN.darkened(0.2), Vector3(side * 0.05, 0.22, 0))
		ant.rotation.z = side * -0.4
		_no_shadow(Models.part(pilot, Models.sphere(0.022, -1, 6), PINK, Vector3(side * 0.075, 0.27, 0), 0.8))
	var dome := MeshInstance3D.new()
	dome.mesh = Models.sphere(0.2, 0.3, 18)
	dome.material_override = Models.glass(Color("#CFF6FF"), 0.15, 0.1) if Models.GLASS else translucent(Color("#CFF6FF"), 0.35, 0.2)
	dome.position = Vector3(0, 0.12, 0)
	_no_shadow(dome)
	hover.add_child(dome)
	# The warning spot on the floor ahead and the beam itself.
	var mark := Node3D.new()
	mark.name = "Mark"
	mark.position = Vector3(0, 0.03, 1.0)
	mark.visible = false
	root.add_child(mark)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.36
	ring.outer_radius = 0.47
	ring.rings = 28
	ring.ring_segments = 4
	var mr := MeshInstance3D.new()
	mr.mesh = ring
	mr.material_override = translucent(Color("#FF7A59"), 0.95, 0.6)
	mr.scale = Vector3(1, 0.25, 1)
	_no_shadow(mr)
	mark.add_child(mr)
	var dot := MeshInstance3D.new()
	dot.mesh = Models.cylinder(0.26, 0.26, 0.01, 20)
	dot.material_override = translucent(Color("#FFB36B"), 0.45, 0.5)
	dot.name = "Dot"
	_no_shadow(dot)
	mark.add_child(dot)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	beam.mesh = Models.cylinder(0.1, 0.42, 1.0, 16)
	beam.material_override = translucent(BEAM, 0.45, 1.6)
	_no_shadow(beam)
	beam.visible = false
	root.add_child(beam)
	return root


## The Moon Whale: a big round periwinkle whale with a cream belly, little
## fins ("FinL", "FinR"), a tail fluke ("Tail"), a twinkling spout ("Spout")
## and a crescent-moon crown. It faces +Z.
static func whale() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.9, 0.42)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	var hull := Models.part(body, Models.sphere(0.46, -1, 26), WHALE, Vector3(0, 0.5, 0))
	hull.scale = Vector3(1.0, 0.86, 1.18)
	var belly := Models.part(body, Models.sphere(0.36, -1, 20), WHALE_BELLY, Vector3(0, 0.38, 0.16))
	belly.scale = Vector3(1.0, 0.7, 1.0)
	for k in 3:
		var groove := Models.part(body, _box(Vector3(0.36 - k * 0.06, 0.018, 0.03), 0.008), WHALE_BELLY.darkened(0.1), Vector3(0, 0.26 + k * 0.07, 0.47 - k * 0.03))
		groove.rotation.x = 0.3
	# Spots on the back.
	for k in 4:
		var a: float = -0.8 + k * 0.55
		var spot := _no_shadow(Models.part(body, Models.sphere(0.05, -1, 8), Color("#AFC0FF"), Vector3(sin(a) * 0.3, 0.86, cos(a) * 0.12 - 0.1)))
		spot.scale = Vector3(1.0, 0.35, 1.0)
	Models._eyes(body, 0.6, 0.48, 0.18, 0.075)
	for side: int in [-1, 1]:
		var cheek := _no_shadow(Models.part(body, Models.sphere(0.05, -1, 8), Color("#FF9AB8"), Vector3(side * 0.3, 0.48, 0.42)))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
		var fin := Node3D.new()
		fin.name = "FinL" if side < 0 else "FinR"
		fin.position = Vector3(side * 0.42, 0.34, 0.12)
		body.add_child(fin)
		var f := Models.part(fin, Models.sphere(0.16, -1, 12), WHALE_DARK, Vector3(side * 0.12, 0, 0))
		f.scale = Vector3(1.0, 0.3, 0.6)
	var smile := Models.part(body, _box(Vector3(0.18, 0.025, 0.02), 0.01), INK, Vector3(0, 0.46, 0.56))
	smile.rotation.x = -0.2
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.55, -0.5)
	body.add_child(tail)
	var stem := Models.part(tail, Models.sphere(0.14, -1, 12), WHALE, Vector3(0, 0.02, -0.08))
	stem.scale = Vector3(1.0, 0.8, 1.3)
	for side: int in [-1, 1]:
		var lobe := Models.part(tail, Models.sphere(0.16, -1, 12), WHALE_DARK, Vector3(side * 0.15, 0.1, -0.2))
		lobe.scale = Vector3(1.2, 0.3, 0.75)
		lobe.rotation.z = side * 0.35
	# Spout: three little glowing stars on stalks.
	var spout := Node3D.new()
	spout.name = "Spout"
	spout.position = Vector3(0, 0.92, 0.05)
	body.add_child(spout)
	for k in 3:
		var a2: float = -0.5 + k * 0.5
		var st := _no_shadow(Models.part(spout, star_mesh(0.07, 0.03), GOLD, Vector3(sin(a2) * 0.14, 0.12 + 0.05 * (1 - absi(k - 1)), 0), 1.2))
		st.rotation.z = a2
	# A crescent moon crown.
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0.0, 0.88, 0.22)
	body.add_child(crown)
	var moon := Models.part(crown, Models.cylinder(0.11, 0.11, 0.05, 20), GOLD, Vector3.ZERO, 0.4)
	moon.rotation.x = PI * 0.5
	var bite := Models.part(crown, Models.cylinder(0.09, 0.09, 0.07, 20), WHALE, Vector3(0.05, 0.03, 0))
	bite.rotation.x = PI * 0.5
	return root


# --- Space props -----------------------------------------------------------------------

## A cluster of glowing crystals.
static func crystals(r: RandomNumberGenerator, scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var col: Color = CRYSTAL_COLORS[r.randi() % CRYSTAL_COLORS.size()]
	var n: int = r.randi_range(2, 4)
	for k in n:
		var h: float = r.randf_range(0.25, 0.55) * scale
		var w: float = r.randf_range(0.06, 0.1) * scale
		var g := Node3D.new()
		g.position = Vector3(r.randf_range(-0.16, 0.16), 0, r.randf_range(-0.16, 0.16)) * scale
		g.rotation = Vector3(r.randf_range(-0.35, 0.35), r.randf() * TAU, r.randf_range(-0.35, 0.35))
		root.add_child(g)
		Models.part(g, gem_mesh(w, h), col, Vector3(0, h * 0.5, 0), 0.35)
		Models.part(g, Models.cylinder(0.0, w, w * 1.6, 6), col.lightened(0.25), Vector3(0, h + w * 0.8, 0), 0.5)
	Models.part(root, Models.sphere(0.13 * scale, 0.12 * scale, 8), Color("#C7BCE6"), Vector3(0, 0.03, 0))
	return root


## A lumpy moon rock or two.
static func moon_rock(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(1, 2):
		var s: float = r.randf_range(0.14, 0.24)
		var m := Models.part(root, Models.sphere(s, -1, 8), Color("#CFC4EA").darkened(r.randf() * 0.12), Vector3(r.randf_range(-0.15, 0.15), s * 0.6, r.randf_range(-0.15, 0.15)))
		m.scale = Vector3(1.2, 0.8, 1.0)
		m.rotation.y = r.randf() * TAU
	return root


## A tiny cartoon rocket on three fins.
static func rocket(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var col: Color = [CORAL, SKY, MINT, LILAC][r.randi() % 4]
	Models.part(root, Models.cylinder(0.13, 0.13, 0.5, 14), CREAM, Vector3(0, 0.4, 0))
	Models.part(root, Models.cylinder(0.0, 0.13, 0.24, 14), col, Vector3(0, 0.77, 0))
	Models.part(root, Models.cylinder(0.135, 0.135, 0.06, 14), col, Vector3(0, 0.28, 0))
	var win := Models.part(root, Models.cylinder(0.06, 0.06, 0.03, 12), SKY.lightened(0.3), Vector3(0, 0.5, 0.125), 0.5)
	win.rotation.x = PI * 0.5
	for k in 3:
		var fin := Node3D.new()
		fin.rotation.y = TAU * k / 3.0
		root.add_child(fin)
		Models.part(fin, _box(Vector3(0.03, 0.22, 0.16), 0.012), col, Vector3(0, 0.18, 0.15))
	_no_shadow(Models.part(root, Models.cylinder(0.08, 0.02, 0.12, 10), GOLD, Vector3(0, 0.1, 0), 1.4))
	root.rotation.y = r.randf() * TAU
	return root


## A little satellite dish.
static func dish() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.12, 0.15, 0.08, 12), Color("#D9CFF2"), Vector3(0, 0.04, 0))
	Models.part(root, Models.cylinder(0.025, 0.03, 0.34, 8), Color("#9E92C8"), Vector3(0, 0.25, 0))
	var bowl := Models.part(root, Models.sphere(0.24, 0.14, 16), CREAM, Vector3(0, 0.46, 0.03))
	bowl.rotation.x = -0.6
	var tip := _no_shadow(Models.part(root, Models.sphere(0.035, -1, 8), PINK, Vector3(0, 0.56, 0.16), 1.3))
	tip.name = "Tip"
	return root


## A beacon: a short post topped with a glowing star.
static func beacon(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.035, 0.045, 0.7, 8), Color("#9E92C8"), Vector3(0, 0.35, 0))
	Models.part(root, Models.cylinder(0.09, 0.11, 0.05, 10), Color("#9E92C8"), Vector3(0, 0.025, 0))
	var st := _no_shadow(Models.part(root, star_mesh(0.13, 0.05), color, Vector3(0, 0.82, 0), 1.3))
	st.name = "Star"
	return root


## A big ringed planet for the backdrop.
static func ringed_planet(size: float, a: Color, b: Color, tilt: float) -> Node3D:
	var root := Node3D.new()
	_no_shadow(Models.part(root, Models.sphere(size, -1, 32), a, Vector3.ZERO, 0.15))
	var band := _no_shadow(Models.part(root, Models.cylinder(size * 0.97, size * 0.97, size * 0.22, 32), b, Vector3(0, size * 0.25, 0), 0.15))
	band.scale = Vector3(1.01, 1.0, 1.01)
	var band2 := _no_shadow(Models.part(root, Models.cylinder(size * 0.9, size * 0.9, size * 0.12, 32), b, Vector3(0, -size * 0.38, 0), 0.15))
	band2.scale = Vector3(1.01, 1.0, 1.01)
	var ring := TorusMesh.new()
	ring.inner_radius = size * 1.35
	ring.outer_radius = size * 1.75
	ring.rings = 48
	ring.ring_segments = 4
	var rr := _no_shadow(Models.part(root, ring, b.lerp(Color.WHITE, 0.3), Vector3.ZERO, 0.2))
	rr.scale = Vector3(1.0, 0.08, 1.0)
	root.rotation = Vector3(tilt, 0.4, tilt * 0.6)
	return root

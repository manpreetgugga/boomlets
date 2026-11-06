extends RefCounted
## Models for World 21, Echo Grotto: a bright seaside cave of shells, teal
## pools and pastel crystals. Echo stones (big spiral shells with a glowing
## mouth), Hermit Crabs (hide in their shells), Glow Jellies (a jellyfish
## skin for the floating wisps), the Grand Clam boss, crystal clusters and
## the cave props: tide pools, starfish, shells, coral and crystal spires.
## Crisp, slightly rounded clay shapes like render/Models.gd.

const SHELL := Color("#FFD9C7")
const SHELL_PINK := Color("#FFB1B8")
const SHELL_BAND := Color("#F58FA0")
const MOUTH := Color("#62E6DC")
const POOL := Color("#5FD6D2")
const POOL_DEEP := Color("#3FB7C2")
const CRAB := Color("#FF7E6B")
const CRAB_DARK := Color("#E25D50")
const CRAB_SHELL := Color("#B8A6F5")
const CRAB_SHELL_BAND := Color("#8E7BE6")
const JELLY := Color("#FF86C8")
const JELLY_GLOW := Color("#FFD6EE")
const CLAM := Color("#8FB8FF")
const CLAM_DARK := Color("#6A93E8")
const CLAM_LIP := Color("#FFD7E8")
const PEARL := Color("#FFF6FF")
const STONE_BASE := Color("#E8D2B4")
const LILAC := Color("#C6B3FF")
const MINT := Color("#9BEFD0")
const PEACH := Color("#FFC8A8")
const SKYBLUE := Color("#A8DCFF")
const INK := Color("#2D2A4A")
const WHITE := Color("#FFFDF8")
const SAND := Color("#F4E3C5")
const STAR := Color("#FF9E7A")
const CRYSTALS: Array[Color] = [Color("#C6B3FF"), Color("#9BEFD0"), Color("#FFC2DE"), Color("#A8DCFF")]
const CRAB_SIZE: float = 1.15
const JELLY_SIZE: float = 1.2
const BOSS_SIZE: float = 1.55

static var _meshes: Dictionary = {}


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A six-sided crystal: a hexagonal prism with a pointed top.
static func crystal_mesh(r: float, h: float) -> ArrayMesh:
	var key := "crystal/%.3f/%.3f" % [r, h]
	if _meshes.has(key):
		return _meshes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tip := Vector3(0, h, 0)
	var top: float = h - r * 1.1
	for k in 6:
		var a0: float = TAU * k / 6.0
		var a1: float = TAU * (k + 1) / 6.0
		var p0 := Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 := Vector3(cos(a1) * r, 0, sin(a1) * r)
		var q0 := Vector3(p0.x, top, p0.z)
		var q1 := Vector3(p1.x, top, p1.z)
		var n := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		_tri(st, p0, q1, p1, n)
		_tri(st, p0, q0, q1, n)
		_tri(st, q0, tip, q1, (n * (h - top) + Vector3.UP * r).normalized())
	var m: ArrayMesh = st.commit()
	_meshes[key] = m
	return m


## Adds a flat triangle facing [param n] (Godot's front faces are clockwise).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	if (b - a).cross(c - a).dot(n) > 0.0:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)
	else:
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)


## A spiral shell: a fat whorl and smaller whorls stacked up a spiral to a
## point, with coloured bands. Its opening faces +Z. Returns the root;
## the opening is "Mouth".
static func spiral_shell(base: Color, band: Color, size: float, mouth: Color, mouth_glow: float) -> Node3D:
	var root := Node3D.new()
	var heights: Array[float] = [0.3, 0.6, 0.82, 0.97]
	var sizes: Array[float] = [1.0, 0.72, 0.5, 0.33]
	for k in 4:
		var s: float = size * sizes[k]
		var a: float = k * 2.1
		var at := Vector3(cos(a) * size * 0.05 * k, size * heights[k], sin(a) * size * 0.05 * k - size * 0.05)
		var w := Models.part(root, Models.sphere(s * 0.5, s * 0.66, 18), base if k % 2 == 0 else base.lerp(band, 0.3), at)
		w.name = "Whorl%d" % k
		Models.part(root, Models.cylinder(s * 0.51, s * 0.51, s * 0.08, 18), band, at + Vector3(0, -s * 0.14, 0))
	Models.part(root, Models.cylinder(0.0, size * 0.09, size * 0.2, 8), band, Vector3(0, size * 1.12, -size * 0.05))
	# The flared lip and the opening.
	var lip := Models.part(root, Models.sphere(size * 0.34, size * 0.5, 18), base.lightened(0.15), Vector3(0, size * 0.27, size * 0.24))
	lip.scale = Vector3(1.15, 1.0, 0.55)
	var mouth_node := Models.part(root, Models.sphere(size * 0.24, size * 0.36, 16), mouth, Vector3(0, size * 0.28, size * 0.36), mouth_glow)
	mouth_node.scale = Vector3(1.0, 1.0, 0.3)
	mouth_node.name = "Mouth"
	return root


## A conch lying on its side: a round body, a spire of shrinking banded
## whorls rising towards the back, little knobs, and a wide flared lip round
## a glowing opening that faces +Z. The opening is "Mouth".
static func conch(base: Color, band: Color, size: float, mouth: Color, mouth_glow: float) -> Node3D:
	var root := Node3D.new()
	var axis := Vector3(0, 0.38, -1).normalized()
	var turn := Basis(Vector3.RIGHT, -atan2(1.0, 0.38))   # cylinder Y axis -> along the spire
	var body := Vector3(0, 0.34, 0.02) * size
	var steps: Array[float] = [0.0, 0.27, 0.45, 0.58, 0.67, 0.73]
	var radii: Array[float] = [0.38, 0.3, 0.22, 0.15, 0.1, 0.06]
	for k in steps.size():
		var at: Vector3 = body + axis * steps[k] * size
		var r: float = radii[k] * size
		var w := Models.part(root, Models.sphere(r, r * 1.8, 18), base if k % 2 == 0 else base.lerp(band, 0.25), at)
		w.basis = turn
		if k > 0 and k < steps.size() - 1:
			var ring := Models.part(root, Models.cylinder(r * 1.02, r * 1.02, r * 0.22, 18), band, at - axis * r * 0.45)
			ring.basis = turn
	# Knobs round the shoulder.
	for k in 5:
		var ang: float = lerpf(-1.2, 1.2, k / 4.0)
		var side := Vector3(sin(ang), cos(ang), 0) * size * 0.31
		var knob := Models.part(root, Models.cylinder(0.0, size * 0.05, size * 0.12, 8), base.lightened(0.2), body + axis * size * 0.12 + side)
		knob.basis = Basis(Vector3.BACK, -ang)
	# The flared lip and the glowing opening.
	var lip := Models.part(root, Models.sphere(size * 0.4, size * 0.8, 20), base.lightened(0.18), body + Vector3(0, -0.02, 0.2) * size)
	lip.scale = Vector3(1.0, 0.95, 0.42)
	var inner := Models.part(root, Models.sphere(size * 0.3, size * 0.62, 18), band.lightened(0.25), body + Vector3(0, 0.0, 0.29) * size)
	inner.scale = Vector3(1.0, 1.0, 0.3)
	var mouth_node := Models.part(root, Models.sphere(size * 0.22, size * 0.48, 16), mouth, body + Vector3(0, 0.0, 0.33) * size, mouth_glow)
	mouth_node.scale = Vector3(1.0, 1.0, 0.3)
	mouth_node.name = "Mouth"
	return root


## A big scallop shell standing on its hinge: a fan of rounded ribs in two
## tones over a backing disc, a frilled edge, two little "ears" at the hinge
## and a glowing pearl-like opening at its foot ("Mouth"). Faces +Z.
static func fan_shell(base: Color, band: Color, size: float, mouth: Color, mouth_glow: float) -> Node3D:
	var root := Node3D.new()
	var pivot := Vector3(0, 0.06, 0) * size
	var back := Models.part(root, Models.sphere(size * 0.44, size * 0.88, 22), band.darkened(0.12), pivot + Vector3(0, 0.3, -0.05) * size)
	back.scale = Vector3(1.0, 0.85, 0.18)
	var n: int = 7
	for k in n:
		var ang: float = lerpf(-1.25, 1.25, k / float(n - 1))
		var dir := Vector3(sin(ang), cos(ang), 0)
		var col: Color = base if k % 2 == 0 else band
		var len: float = size * (0.7 - absf(ang) * 0.07)
		var rib := Models.part(root, Models.box_mesh(Vector3(size * 0.17, len, size * 0.13), size * 0.06), col, pivot + dir * len * 0.5 + Vector3(0, 0, 0.06 * size))
		rib.basis = Basis(Vector3.BACK, -ang)
		Models.part(root, Models.sphere(size * 0.095, size * 0.15, 10), col.lightened(0.12), pivot + dir * len * 0.98 + Vector3(0, 0, 0.06 * size))
	for side: int in [-1, 1]:
		var ear := Models.part(root, Models.box_mesh(Vector3(0.2, 0.12, 0.1) * size, size * 0.04), band, pivot + Vector3(side * 0.13, 0.04, 0.03) * size)
		ear.rotation.z = side * 0.25
	var mouth_node := Models.part(root, Models.sphere(size * 0.16, size * 0.3, 16), mouth, pivot + Vector3(0, 0.12, 0.12) * size, mouth_glow)
	mouth_node.scale = Vector3(1.2, 1.0, 0.55)
	mouth_node.name = "Mouth"
	return root


# --- Echo stone ------------------------------------------------------------------------

## An echo stone: a big coral-pink spiral shell on a sandy rock with a teal
## glowing mouth ("Shell/Mouth") and a flat glow ring round its foot
## ("Halo") that lights up while it is about to echo.
static func echo_stone() -> Node3D:
	var root := Node3D.new()
	var base := Models.part(root, Models.box_mesh(Vector3(0.86, 0.18, 0.86), 0.08), STONE_BASE, Vector3(0, 0.09, 0))
	base.name = "Base"
	var shell := fan_shell(SHELL, SHELL_BAND, 1.05, MOUTH, 1.2)
	shell.name = "Shell"
	shell.position = Vector3(0, 0.12, -0.08)
	shell.rotation.x = -0.32
	root.add_child(shell)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.44
	ring.outer_radius = 0.56
	ring.rings = 24
	ring.ring_segments = 6
	var halo := Models.part(root, ring, MOUTH, Vector3(0, 0.05, 0), 1.8)
	halo.name = "Halo"
	halo.scale = Vector3(1, 0.4, 1)
	halo.visible = false
	_no_shadow(halo)
	# The stored reach: one glowing teal pearl per tile, in a row along the
	# front of the sandy base ("Pearls/P0".."P5", shown as the shell fills).
	var pearls := Node3D.new()
	pearls.name = "Pearls"
	root.add_child(pearls)
	for k in 6:
		var pp := Models.part(pearls, Models.sphere(0.08, -1, 10), PEARL, Vector3((k - 2.5) * 0.15, 0.25, 0.35), 1.2)
		pp.name = "P%d" % k
		pp.visible = false
		_no_shadow(pp)
	return root


## A conch horn pad: a round sandy pad with a teal rim, a little conch horn
## lying on it ("Horn") and a glow ring ("Glow") shown while shells are full.
static func horn_pad() -> Node3D:
	var root := Node3D.new()
	var pad := Models.part(root, Models.cylinder(0.4, 0.43, 0.06, 24), Color("#F3DDBF"), Vector3(0, 0.03, 0))
	pad.name = "Pad"
	var rim := TorusMesh.new()
	rim.inner_radius = 0.34
	rim.outer_radius = 0.42
	rim.rings = 24
	rim.ring_segments = 6
	var r := Models.part(root, rim, SHELL_BAND, Vector3(0, 0.06, 0))
	r.scale = Vector3(1, 0.35, 1)
	var horn_node := Node3D.new()
	horn_node.name = "Horn"
	horn_node.position = Vector3(0, 0.08, 0)
	root.add_child(horn_node)
	var h := conch(SHELL, SHELL_BAND, 0.68, MOUTH, 1.0)
	h.rotation.y = -0.6
	horn_node.add_child(h)
	var glow := Node3D.new()
	glow.name = "Glow"
	glow.visible = false
	root.add_child(glow)
	var gr := TorusMesh.new()
	gr.inner_radius = 0.42
	gr.outer_radius = 0.5
	gr.rings = 24
	gr.ring_segments = 6
	var g := Models.part(glow, gr, MOUTH, Vector3(0, 0.05, 0), 1.8)
	g.scale = Vector3(1, 0.3, 1)
	_no_shadow(g)
	return root


## A flat ripple square: this tile is about to be hit by an echo.
static func echo_mark() -> Node3D:
	var root := Node3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.27
	ring.outer_radius = 0.38
	ring.rings = 24
	ring.ring_segments = 6
	var r := Models.part(root, ring, MOUTH, Vector3(0, 0.035, 0), 1.6)
	r.scale = Vector3(1, 0.3, 1)
	r.name = "Ring"
	_no_shadow(r)
	var disc := MeshInstance3D.new()
	disc.mesh = Models.cylinder(0.3, 0.3, 0.02, 20)
	disc.material_override = Models.glass(MOUTH, 0.6, 0.8)
	disc.position = Vector3(0, 0.025, 0)
	_no_shadow(disc)
	root.add_child(disc)
	var dot := Models.part(root, Models.cylinder(0.09, 0.09, 0.03, 12), WHITE, Vector3(0, 0.04, 0), 1.4)
	_no_shadow(dot)
	return root


# --- Hermit crab ------------------------------------------------------------------------

## Hermit Crab: a coral crab with eye stalks, two claws and little legs,
## carrying a lilac spiral shell ("Shell"). "Crab" holds the parts that
## tuck away when it hides.
static func crab() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var crab := Node3D.new()
	crab.name = "Crab"
	body.add_child(crab)
	var torso := Models.part(crab, Models.sphere(0.2, 0.26, 16), CRAB, Vector3(0, 0.2, 0.08))
	torso.scale = Vector3(1.3, 1.0, 1.0)
	for side: int in [-1, 1]:
		var stalk := Models.part(crab, Models.cylinder(0.018, 0.022, 0.16, 6), CRAB_DARK, Vector3(side * 0.08, 0.36, 0.17))
		stalk.rotation.z = side * -0.2
		var eye := Models.part(crab, Models.sphere(0.055, -1, 10), WHITE, Vector3(side * 0.1, 0.45, 0.18))
		eye.scale = Vector3(1, 1.1, 1)
		Models.part(crab, Models.sphere(0.028, -1, 8), INK, Vector3(side * 0.1, 0.45, 0.225))
		var claw := Node3D.new()
		claw.name = "ClawL" if side < 0 else "ClawR"
		claw.position = Vector3(side * 0.24, 0.18, 0.2)
		crab.add_child(claw)
		Models.part(claw, Models.box_mesh(Vector3(0.07, 0.07, 0.12), 0.03), CRAB_DARK, Vector3(0, 0, -0.03))
		var pincer := Models.part(claw, Models.sphere(0.09, 0.12, 12), CRAB, Vector3(side * 0.03, 0.03, 0.07))
		pincer.scale = Vector3(1.0, 1.0, 1.25)
		Models.part(claw, Models.box_mesh(Vector3(0.05, 0.035, 0.1), 0.015), CRAB_DARK, Vector3(side * 0.03, 0.1, 0.09))
		for k in 3:
			var leg := Models.part(crab, Models.box_mesh(Vector3(0.18, 0.04, 0.04), 0.015), CRAB_DARK, Vector3(side * 0.2, 0.07, 0.02 - k * 0.09))
			leg.rotation.z = side * 0.5
			leg.name = "Leg%s%d" % ["L" if side < 0 else "R", k]
	var shell := spiral_shell(CRAB_SHELL, CRAB_SHELL_BAND, 0.62, CRAB_SHELL.lightened(0.4), 0.0)
	shell.name = "Shell"
	shell.position = Vector3(0, 0.08, -0.1)
	shell.rotation.x = -0.6
	body.add_child(shell)
	root.scale = Vector3.ONE
	return root


# --- Glow jelly (the wisps' skin here) ---------------------------------------------

static func jelly() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7, 0.22)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var bell := MeshInstance3D.new()
	bell.mesh = Models.sphere(0.3, 0.42, 20)
	bell.material_override = Models.glass(JELLY, 0.85, 0.7)
	bell.position = Vector3(0, 0.66, 0)
	body.add_child(bell)
	Models.part(body, Models.sphere(0.2, 0.26, 14), JELLY_GLOW, Vector3(0, 0.64, 0), 1.3)
	var skirt := Models.part(body, Models.cylinder(0.3, 0.27, 0.06, 20), JELLY.darkened(0.08), Vector3(0, 0.47, 0))
	skirt.name = "Skirt"
	for k in 5:
		var a: float = TAU * k / 5.0 + 0.3
		var t := Models.part(body, Models.box_mesh(Vector3(0.05, 0.3, 0.05), 0.02), JELLY.lightened(0.2), Vector3(cos(a) * 0.15, 0.3, sin(a) * 0.15), 0.4)
		t.name = "T%d" % k
	for side: int in [-1, 1]:
		Models.part(body, Models.sphere(0.04, -1, 8), INK, Vector3(side * 0.09, 0.62, 0.27))
	return root


# --- The Grand Clam (boss) -------------------------------------------------------

## The Grand Clam: a big periwinkle clam with a pink lip and a glowing pearl.
## The top shell ("Body/Lid") hinges open at the back; googly eyes sit on
## the bottom shell's rim. "Body/Pearl" glows while it is open.
static func clam() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.8, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var bottom := Models.part(body, Models.sphere(0.6, 0.6, 24), CLAM_DARK, Vector3(0, 0.26, 0))
	bottom.scale = Vector3(1.0, 0.75, 0.85)
	var lip := Models.part(body, Models.cylinder(0.6, 0.58, 0.08, 24), CLAM_LIP, Vector3(0, 0.44, 0))
	lip.scale = Vector3(1.0, 1.0, 0.85)
	# Ribs on the bottom shell, fanning out from the hinge.
	for k in 7:
		var a: float = lerpf(-1.1, 1.1, k / 6.0)
		var rib := Models.part(body, Models.box_mesh(Vector3(0.06, 0.06, 0.62), 0.02), CLAM_DARK.lightened(0.18), Vector3(sin(a) * 0.3, 0.3, cos(a) * 0.26))
		rib.rotation.y = a
		rib.rotation.x = 0.5
	var pearl := Models.part(body, Models.sphere(0.2, -1, 18), PEARL, Vector3(0, 0.56, 0.05), 1.4)
	pearl.name = "Pearl"
	var lid := Node3D.new()
	lid.name = "Lid"
	lid.position = Vector3(0, 0.46, -0.44)
	body.add_child(lid)
	var top := Models.part(lid, Models.sphere(0.62, 0.62, 24), CLAM, Vector3(0, 0.02, 0.44))
	top.scale = Vector3(1.0, 0.62, 0.86)
	for k in 7:
		var a2: float = lerpf(-1.1, 1.1, k / 6.0)
		var rib2 := Models.part(lid, Models.box_mesh(Vector3(0.06, 0.06, 0.6), 0.02), CLAM.lightened(0.2), Vector3(sin(a2) * 0.3, 0.18, 0.44 + cos(a2) * 0.2 - 0.1))
		rib2.rotation.y = a2
		rib2.rotation.x = -0.45
	var lid_lip := Models.part(lid, Models.cylinder(0.6, 0.6, 0.05, 24), CLAM_LIP, Vector3(0, -0.02, 0.44))
	lid_lip.scale = Vector3(1.0, 1.0, 0.85)
	# A crown of little crystals on top.
	for k in 3:
		var c := Models.part(lid, crystal_mesh(0.07, 0.3 - absi(k - 1) * 0.08), CRYSTALS[k], Vector3((k - 1) * 0.16, 0.16, 0.3), 0.4)
		c.rotation.z = (k - 1) * -0.3
	# Swallowed blasts show as teal pearls behind the crown ("Charge").
	var charge := Node3D.new()
	charge.name = "Charge"
	lid.add_child(charge)
	for k in 4:
		var cp := Models.part(charge, Models.sphere(0.075, -1, 10), MOUTH, Vector3((k - 1.5) * 0.2, 0.17, 0.12 + absf(k - 1.5) * 0.06), 1.8)
		cp.visible = false
		_no_shadow(cp)
	# Googly eyes on top of the lid, near its front edge.
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	lid.add_child(eyes)
	for side: int in [-1, 1]:
		var e := Models.part(eyes, Models.sphere(0.13, 0.26, 14), WHITE, Vector3(side * 0.22, 0.3, 0.7))
		e.scale = Vector3(1, 1, 0.75)
		Models.part(eyes, Models.sphere(0.065, -1, 10), INK, Vector3(side * 0.22, 0.29, 0.79))
		Models.part(eyes, Models.sphere(0.022, -1, 6), WHITE, Vector3(side * 0.22 + 0.025, 0.32, 0.84), 1.0)
		var brow := Models.part(eyes, Models.box_mesh(Vector3(0.18, 0.04, 0.04), 0.015), INK, Vector3(side * 0.22, 0.47, 0.7))
		brow.rotation.z = side * -0.35
		brow.name = "Brow%s" % ("L" if side < 0 else "R")
	# Little foot.
	var foot := Models.part(body, Models.sphere(0.2, 0.18, 14), CLAM_LIP.darkened(0.08), Vector3(0, 0.05, 0.25))
	foot.scale = Vector3(1.4, 1, 1)
	root.scale = Vector3.ONE * BOSS_SIZE
	return root


# --- Cave pieces ----------------------------------------------------------------------

## A tide pool: a flat teal pool with a sandy rim, a pebble and sometimes a
## starfish.
static func tide_pool(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var rim := Models.part(root, Models.cylinder(size * 0.5, size * 0.52, 0.08, 18), SAND.darkened(0.06), Vector3(0, 0.04, 0))
	rim.scale = Vector3(1.0, 1.0, r.randf_range(0.7, 1.0))
	var water := Models.part(root, Models.cylinder(size * 0.42, size * 0.42, 0.04, 18), POOL, Vector3(0, 0.07, 0), 0.25)
	water.scale = rim.scale
	_no_shadow(water)
	if r.randf() < 0.6:
		var s := starfish(STAR if r.randf() < 0.5 else SHELL_BAND)
		s.position = Vector3(r.randf_range(-0.1, 0.1) * size, 0.09, r.randf_range(-0.1, 0.1) * size)
		s.rotation.y = r.randf() * TAU
		s.scale = Vector3.ONE * 0.8
		root.add_child(s)
	return root


static func starfish(color: Color) -> Node3D:
	var root := Node3D.new()
	for k in 5:
		var a: float = TAU * k / 5.0
		var arm := Models.part(root, Models.box_mesh(Vector3(0.22, 0.05, 0.08), 0.03), color, Vector3(cos(a) * 0.1, 0.025, sin(a) * 0.1))
		arm.rotation.y = -a
	Models.part(root, Models.sphere(0.06, 0.06, 10), color.lightened(0.2), Vector3(0, 0.04, 0))
	return root


## A cluster of pastel crystals.
static func crystals(r: RandomNumberGenerator, scale: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var n: int = r.randi_range(2, 4)
	var col: Color = CRYSTALS[r.randi() % CRYSTALS.size()]
	for k in n:
		var h: float = r.randf_range(0.3, 0.7) * scale
		var c := Models.part(root, crystal_mesh(0.08 * scale + h * 0.06, h), col if k % 2 == 0 else col.lightened(0.2), Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15)) * scale, 0.35)
		c.rotation = Vector3(r.randf_range(-0.35, 0.35), r.randf() * TAU, r.randf_range(-0.35, 0.35))
	return root


## A shell lying on the sand.
static func beach_shell(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	if r.randf() < 0.5:
		var s := spiral_shell([SHELL, PEACH, LILAC][r.randi() % 3], SHELL_BAND, 0.4, SHELL.lightened(0.3), 0.0)
		s.rotation = Vector3(-1.2, r.randf() * TAU, 0)
		s.position.y = 0.12
		root.add_child(s)
	else:
		# A scallop: a fan of ribs.
		var col: Color = [SHELL_PINK, PEACH, SKYBLUE][r.randi() % 3]
		for k in 5:
			var a: float = lerpf(-0.9, 0.9, k / 4.0)
			var rib := Models.part(root, Models.box_mesh(Vector3(0.07, 0.05, 0.24), 0.025), col if k % 2 == 0 else col.lightened(0.15), Vector3(sin(a) * 0.08, 0.03, cos(a) * 0.08))
			rib.rotation.y = a
		root.rotation.y = r.randf() * TAU
	return root


## A soft coral branch.
static func coral(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var col: Color = [Color("#FF8FA8"), Color("#FFB36B"), LILAC][r.randi() % 3]
	Models.part(root, Models.cylinder(0.05, 0.07, 0.4, 8), col, Vector3(0, 0.2, 0))
	for k in 3:
		var a: float = TAU * k / 3.0 + r.randf()
		var br := Models.part(root, Models.cylinder(0.035, 0.045, 0.28, 8), col, Vector3(cos(a) * 0.08, 0.36, sin(a) * 0.08))
		br.rotation = Vector3(sin(a) * 0.6, 0, -cos(a) * 0.6)
		Models.part(root, Models.sphere(0.05, -1, 8), col.lightened(0.25), Vector3(cos(a) * 0.17, 0.5, sin(a) * 0.17))
	return root

extends RefCounted
## Candy Coast (World 2) models and materials: the sidestepping crab, the
## crab captain boss, jelly / gull / bubble re-skins of the base critters,
## beach props (palms, umbrellas, sandcastles, lollipop trees) and the sea and
## tide-pool water shaders. Loaded by path from world_2.gd (no class_name).

const CRAB := Color("#FF7262")
const CRAB_BELLY := Color("#FFD9BF")
const CRAB_HURT := Color("#FFB0A3")
const BOSS_SHELL := Color("#F2544B")
const JELLY := Color("#FF9ED6")
const GULL := Color("#FFFFFF")
const GULL_TIP := Color("#8E9BB3")
const BEAK := Color("#FFB04A")
const BUBBLE := Color("#BDEFFF")
const SAND := Color("#F3D29B")
const SAND_DARK := Color("#E2B878")
const WET_SAND := Color("#E6BE86")
const CANDY: Array[Color] = [Color("#8FE3C8"), Color("#C9B4F7"), Color("#FFE38A"), Color("#9FD3FF")]
const SWEETS: Array[Color] = [Color("#FF8FB8"), Color("#8FE3C8"), Color("#FFE38A"), Color("#C9B4F7"), Color("#FFB37A")]
const STAR_COLORS: Array[Color] = [Color("#FF9A5C"), Color("#FF7FA8"), Color("#FFD166")]
const SHELL_COLORS: Array[Color] = [Color("#FFE9DC"), Color("#FFC6D6")]
const CORAL := Color("#FF7E8C")
const PALM_LEAF := Color("#5CD68A")
const PALM_LEAF_B := Color("#3DBB76")
const PALM_TRUNK := Color("#D9A066")
const COCONUT := Color("#8A5A3A")

static var _meshes: Dictionary = {}


# --- Small shared meshes ------------------------------------------------------

## A flat five-point starfish lying on y = 0 (top at about 0.05).
static func star_mesh() -> Mesh:
	if not _meshes.has("star"):
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = PI * 0.5 + TAU * k / 10.0
			var r: float = 0.13 if k % 2 == 0 else 0.055
			pts.append(Vector2(cos(a), sin(a)) * r)
		_meshes["star"] = _flat(ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.025, 3), 0.05, 0.018, 2))
	return _meshes["star"]


## A scallop shell lying flat, hinge towards -Z.
static func shell_mesh() -> Mesh:
	if not _meshes.has("shell"):
		var pts := PackedVector2Array([Vector2(-0.03, -0.07), Vector2(0.03, -0.07)])
		for k in 15:
			var a: float = deg_to_rad(15.0 + 150.0 * k / 14.0)
			var r: float = 0.115 + (0.012 if k % 2 == 0 else 0.0)
			pts.append(Vector2(cos(a) * r, sin(a) * r - 0.03))
		_meshes["shell"] = _flat(ClayShapes.extrusion(pts, 0.045, 0.016, 2))
	return _meshes["shell"]


static func gumdrop_mesh() -> Mesh:
	if not _meshes.has("gum"):
		_meshes["gum"] = Models.cylinder(0.05, 0.075, 0.1, 10)
	return _meshes["gum"]


static func coral_mesh() -> Mesh:
	if not _meshes.has("coral"):
		_meshes["coral"] = Models.box_mesh(Vector3(0.065, 0.24, 0.065), 0.03)
	return _meshes["coral"]


## A palm frond pointing +X from the origin, lying flat.
static func frond_mesh() -> Mesh:
	if not _meshes.has("frond"):
		# A leaf from the stem (x = 0) to a single tip point (a doubled point
		# would break the triangulation).
		var pts := PackedVector2Array()
		var n: int = 9
		for k in range(0, n):
			var u: float = float(k) / n
			pts.append(Vector2(u * 0.62, -_frond_w(u)))
		pts.append(Vector2(0.66, 0.0))
		for k in range(n - 1, -1, -1):
			var u: float = float(k) / n
			pts.append(Vector2(u * 0.62, _frond_w(u)))
		_meshes["frond"] = _flat(ClayShapes.extrusion(pts, 0.035, 0.012, 1))
	return _meshes["frond"]


static func _frond_w(u: float) -> float:
	return 0.03 + 0.15 * pow(sin(PI * u), 0.7)


static func _flat(m: ArrayMesh) -> Mesh:
	# Extrusions run along Z; turn them to lie on the ground.
	var st := SurfaceTool.new()
	st.create_from(m, 0)
	var out := ArrayMesh.new()
	var arr: Array = st.commit_to_arrays()
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	var b := Basis(Vector3.RIGHT, -PI * 0.5)
	for i in verts.size():
		verts[i] = b * verts[i]
		norms[i] = b * norms[i]
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return out


static func _part(parent: Node3D, mesh: Mesh, color: Color, pos: Vector3, glow: float = 0.0) -> MeshInstance3D:
	return Models.part(parent, mesh, color, pos, glow)


# --- Critters -----------------------------------------------------------------

## The sidestepping crab: a round coral shell, eyes on stalks, two pincers
## ("ClawL"/"ClawR" with a "Snap" finger) and three legs a side ("LegsL"/
## "LegsR"). Faces +Z; [param s] scales it (the boss is a big one).
static func crab(shell_color: Color = CRAB, s: float = 1.0, angry: bool = false) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0 * s, 0.34)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := _part(body, Models.sphere(0.3 * s, 0.4 * s, 24), shell_color, Vector3(0, 0.3 * s, 0))
	shell.scale = Vector3(1.3, 1.0, 1.0)
	shell.name = "Shell"
	var belly := _part(body, Models.sphere(0.24 * s, 0.26 * s, 18), CRAB_BELLY, Vector3(0, 0.22 * s, 0.07 * s))
	belly.scale = Vector3(1.3, 1.0, 1.0)
	for k in 3:
		var a: float = -0.8 + k * 0.8
		var spot := _part(body, Models.sphere(0.045 * s, 0.03 * s, 10), shell_color.lightened(0.3), Vector3(sin(a) * 0.2 * s, 0.49 * s, cos(a) * -0.05 * s - 0.04 * s))
		spot.scale = Vector3(1.3, 1.0, 1.0)
	# Eyes on stalks.
	for side: int in [-1, 1]:
		_part(body, Models.cylinder(0.022 * s, 0.03 * s, 0.2 * s, 8), shell_color.darkened(0.08), Vector3(side * 0.11 * s, 0.53 * s, 0.1 * s))
		_part(body, Models.sphere(0.075 * s, -1, 14), Models.WHITE, Vector3(side * 0.11 * s, 0.65 * s, 0.11 * s))
		var pupil := _part(body, Models.sphere(0.042 * s, -1, 12), Models.INK, Vector3(side * 0.11 * s, 0.645 * s, 0.165 * s))
		pupil.scale = Vector3(1.0, 1.15, 0.7)
		_part(body, Models.sphere(0.013 * s, -1, 6), Models.WHITE, Vector3(side * 0.11 * s + 0.014 * s, 0.665 * s, 0.2 * s), 1.0)
		if angry:
			var brow := _part(body, Models.box_mesh(Vector3(0.12, 0.03, 0.03) * s, 0.012 * s), Models.INK, Vector3(side * 0.11 * s, 0.74 * s, 0.15 * s))
			brow.rotation.z = side * -0.4
		var cheek := _part(body, Models.sphere(0.04 * s, -1, 8), Color("#FF5F7E"), Vector3(side * 0.24 * s, 0.3 * s, 0.25 * s))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	var mouth := _part(body, Models.box_mesh(Vector3(0.1, 0.03, 0.03) * s, 0.012 * s), Models.INK, Vector3(0, 0.27 * s, 0.31 * s))
	mouth.name = "Mouth"
	# Pincers.
	for side: int in [-1, 1]:
		var claw := Node3D.new()
		claw.name = "ClawL" if side < 0 else "ClawR"
		claw.position = Vector3(side * 0.44 * s, 0.3 * s, 0.14 * s)
		body.add_child(claw)
		var arm := _part(claw, Models.cylinder(0.035 * s, 0.045 * s, 0.2 * s, 8), shell_color.darkened(0.06), Vector3(-side * 0.06 * s, -0.04 * s, -0.04 * s))
		arm.rotation = Vector3(0.6, 0, side * 1.1)
		var palm := _part(claw, Models.sphere(0.12 * s, 0.2 * s, 16), shell_color, Vector3(0, 0, 0.04 * s))
		palm.scale = Vector3(1.0, 0.85, 1.2)
		var snap := Node3D.new()
		snap.name = "Snap"
		snap.position = Vector3(0, 0.05 * s, 0.02 * s)
		claw.add_child(snap)
		var finger := _part(snap, Models.sphere(0.06 * s, 0.09 * s, 12), shell_color.lightened(0.08), Vector3(0, 0.03 * s, 0.1 * s))
		finger.scale = Vector3(0.9, 0.8, 1.6)
	# Legs: three a side, angled down to the sand.
	var leg_mesh := Models.box_mesh(Vector3(0.24, 0.05, 0.055) * s, 0.02 * s)
	for side: int in [-1, 1]:
		var legs := Node3D.new()
		legs.name = "LegsL" if side < 0 else "LegsR"
		legs.position = Vector3(side * 0.3 * s, 0.17 * s, 0)
		body.add_child(legs)
		for k in 3:
			var leg := _part(legs, leg_mesh, shell_color.darkened(0.1), Vector3(side * 0.08 * s, -0.06 * s, (-0.14 + k * 0.12) * s))
			leg.rotation = Vector3(0, side * (k - 1) * -0.35, side * -0.55)
	return root


## Captain Clawdia, Candy Coast's boss: a big crab in a sailor's cap.
static func boss_crab() -> Node3D:
	var s: float = 2.0
	var root := crab(BOSS_SHELL, s, true)
	var body: Node3D = root.get_node("Body")
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0.04 * s, 0.47 * s, -0.12 * s)
	hat.rotation = Vector3(-0.35, 0.0, 0.15)
	hat.scale = Vector3.ONE * 1.35
	body.add_child(hat)
	_part(hat, Models.cylinder(0.2, 0.22, 0.16, 20), Models.WHITE, Vector3(0, 0.08, 0))
	_part(hat, Models.cylinder(0.24, 0.24, 0.05, 20), Models.WHITE, Vector3(0, 0.17, 0))
	_part(hat, Models.cylinder(0.225, 0.225, 0.06, 20), Color("#2E4A8C"), Vector3(0, 0.03, 0))
	var visor := _part(hat, Models.box_mesh(Vector3(0.3, 0.035, 0.14), 0.015), Color("#2E4A8C"), Vector3(0, 0.0, 0.2))
	visor.rotation.x = 0.25
	var badge := _part(hat, star_mesh(), Models.GOLD, Vector3(0, 0.1, 0.205), 0.3)
	badge.rotation.x = PI * 0.5
	badge.scale = Vector3.ONE * 0.6
	return root


## Jelly: a glassy pink jellyfish bell with a frill and swaying tentacles
## ("Tent0".."Tent3"). Re-skins the wandering Blobbit.
static func jelly() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var bell := _part(body, Models.sphere(0.33, 0.48, 24), JELLY, Vector3(0, 0.5, 0), 0.12)
	bell.scale = Vector3(1.0, 0.9, 1.0)
	if Models.GLASS:
		bell.material_override = Models.glass(JELLY, 0.55, 0.1)
	var frill := TorusMesh.new()
	frill.inner_radius = 0.22
	frill.outer_radius = 0.34
	frill.rings = 24
	frill.ring_segments = 8
	var fr := _part(body, frill, JELLY.lightened(0.25), Vector3(0, 0.36, 0))
	fr.scale = Vector3(1.0, 0.5, 1.0)
	_part(body, Models.sphere(0.09, -1, 10), Color.WHITE, Vector3(-0.13, 0.66, 0.12), 0.4).scale = Vector3(1.0, 0.7, 0.7)
	Models._eyes(body, 0.5, 0.29, 0.11, 0.07)
	var mouth := _part(body, Models.box_mesh(Vector3(0.08, 0.03, 0.03), 0.012), Models.INK, Vector3(0, 0.41, 0.31))
	mouth.rotation.x = -0.2
	var tent := Models.box_mesh(Vector3(0.055, 0.26, 0.055), 0.025)
	for k in 4:
		var a: float = TAU * k / 4.0 + PI * 0.25
		var pivot := Node3D.new()
		pivot.name = "Tent%d" % k
		pivot.position = Vector3(cos(a) * 0.15, 0.34, sin(a) * 0.15)
		body.add_child(pivot)
		_part(pivot, tent, JELLY.darkened(0.05), Vector3(0, -0.12, 0))
	return root


## Gull: a round white seagull with grey wingtips ("WingL"/"WingR"), an
## orange beak and a cross look. Re-skins the chasing Buzzer.
static func gull() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.28)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var torso := _part(body, Models.sphere(0.26, 0.48, 22), GULL, Vector3(0, 0.58, -0.02))
	torso.scale = Vector3(0.95, 0.9, 1.2)
	_part(body, Models.sphere(0.2, -1, 20), GULL, Vector3(0, 0.78, 0.17))
	var beak := _part(body, Models.cylinder(0.0, 0.055, 0.16, 10), BEAK, Vector3(0, 0.76, 0.42))
	beak.rotation.x = PI * 0.5
	Models._eyes(body, 0.82, 0.32, 0.085, 0.055, true)
	var tail := _part(body, Models.box_mesh(Vector3(0.18, 0.05, 0.16), 0.02), GULL_TIP, Vector3(0, 0.6, -0.36))
	tail.rotation.x = -0.3
	var wing_mesh := Models.box_mesh(Vector3(0.36, 0.05, 0.22), 0.025)
	var tip_mesh := Models.box_mesh(Vector3(0.14, 0.055, 0.2), 0.025)
	for side: int in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.2, 0.66, -0.02)
		body.add_child(wing)
		_part(wing, wing_mesh, GULL.darkened(0.04), Vector3(side * 0.18, 0, 0))
		_part(wing, tip_mesh, GULL_TIP, Vector3(side * 0.36, 0, -0.01))
		var foot := _part(body, Models.sphere(0.05, 0.05, 8), BEAK, Vector3(side * 0.08, 0.32, 0.0))
		foot.scale = Vector3(1, 1, 1.5)
	return root


## Bubble: a floating glass soap bubble with a face. Re-skins the Wisp.
static func bubble() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7, 0.2)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var ball := _part(body, Models.sphere(0.32, -1, 24), BUBBLE, Vector3(0, 0.62, 0), 0.2)
	if Models.GLASS:
		ball.material_override = Models.glass(BUBBLE, 0.25, 0.15)
	_part(body, Models.sphere(0.07, -1, 10), Color.WHITE, Vector3(-0.15, 0.78, 0.19), 1.2).scale = Vector3(1.0, 0.7, 0.5)
	Models._eyes(body, 0.66, 0.26, 0.1, 0.065)
	var mouth := _part(body, Models.sphere(0.035, -1, 8), Models.INK, Vector3(0, 0.55, 0.3))
	mouth.scale = Vector3(1.0, 0.8, 0.5)
	for k in 2:
		var b := _part(body, Models.sphere(0.07 - k * 0.025, -1, 10), BUBBLE, Vector3(0.3 - k * 0.08, 0.32 + k * 0.12, -0.1), 0.2)
		b.name = "Mini%d" % k
		if Models.GLASS:
			b.material_override = Models.glass(BUBBLE, 0.25, 0.15)
	return root


# --- Props --------------------------------------------------------------------

static func palm(r: RandomNumberGenerator, h: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0, 0.25)
	var lean: float = r.randf_range(-0.25, 0.25)
	var lean_z: float = r.randf_range(-0.2, 0.05)
	var seg := Models.box_mesh(Vector3(0.2, 0.2, 0.2), 0.06)
	var top := Vector3.ZERO
	var n: int = 6
	for k in n:
		var u: float = float(k) / n
		var p := Vector3(lean * u * u * h, (0.1 + k * 0.19) * h, lean_z * u * u * h)
		var piece := _part(root, seg, PALM_TRUNK.darkened(0.06 * (k % 2)), p)
		piece.rotation = Vector3(lean_z * 0.6 * u, r.randf() * 0.6, -lean * 0.6 * u)
		piece.scale = Vector3(1.0 - u * 0.25, h, 1.0 - u * 0.25)
		top = p
	top.y += 0.12 * h
	var fm := frond_mesh()
	var count: int = 6
	var spin: float = r.randf() * TAU
	for k in count:
		var yaw: float = spin + TAU * k / count
		var droop: float = r.randf_range(0.18, 0.4)
		var f := _part(root, fm, PALM_LEAF if k % 2 == 0 else PALM_LEAF_B, top)
		f.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, -droop)
		f.scale = Vector3.ONE * (0.95 + r.randf() * 0.2) * h
	for k in 3:
		var a: float = TAU * k / 3.0 + spin
		_part(root, Models.sphere(0.065, -1, 10), COCONUT, top + Vector3(cos(a) * 0.08, -0.07, sin(a) * 0.08))
	return root


## A beach umbrella with alternating stripes.
static func umbrella(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.1, 0.25)
	var tilt: float = r.randf_range(-0.2, 0.2)
	var pivot := Node3D.new()
	pivot.rotation = Vector3(r.randf_range(-0.12, 0.12), 0, tilt)
	root.add_child(pivot)
	_part(pivot, Models.cylinder(0.022, 0.022, 0.95, 8), Models.WHITE, Vector3(0, 0.47, 0))
	var colors: Array[Color] = [SWEETS[r.randi() % 3], Models.WHITE]
	var canopy := MeshInstance3D.new()
	canopy.mesh = _canopy_mesh()
	canopy.position.y = 0.88
	canopy.rotation.y = r.randf() * TAU
	canopy.set_surface_override_material(0, Models.mat(colors[0]))
	canopy.set_surface_override_material(1, Models.mat(colors[1]))
	pivot.add_child(canopy)
	_part(pivot, Models.sphere(0.04, -1, 8), colors[0], Vector3(0, 1.08, 0))
	return root


static func _canopy_mesh() -> ArrayMesh:
	if _meshes.has("canopy"):
		return _meshes["canopy"]
	var mesh := ArrayMesh.new()
	var segs: int = 8
	var rad: float = 0.55
	var h: float = 0.2
	for surf in 2:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for k in segs:
			if k % 2 != surf:
				continue
			var a0: float = TAU * k / segs
			var a1: float = TAU * (k + 1) / segs
			var am: float = (a0 + a1) * 0.5
			var apex := Vector3(0, h, 0)
			var p0 := Vector3(cos(a0) * rad, 0.0, sin(a0) * rad)
			var p1 := Vector3(cos(a1) * rad, 0.0, sin(a1) * rad)
			var pm := Vector3(cos(am) * rad * 0.93, 0.03, sin(am) * rad * 0.93)
			for tri: Array in [[apex, p0, pm], [apex, pm, p1]]:
				var n: Vector3 = ((tri[1] as Vector3) - (tri[0] as Vector3)).cross((tri[2] as Vector3) - (tri[0] as Vector3)).normalized()
				if n.y < 0.0:
					n = -n
				_tri(st, tri[0], tri[1], tri[2], n, Vector3.ZERO)
				# Underside so the canopy reads from low angles too.
				_tri(st, tri[0], tri[1], tri[2], -n, Vector3(0, -0.01, 0))
		st.commit(mesh)
	_meshes["canopy"] = mesh
	return mesh


## Adds a triangle facing [param n] (Godot's front faces wind clockwise:
## (p2 - p0) x (p1 - p0) points out).
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3, off: Vector3) -> void:
	if (c - a).cross(b - a).dot(n) < 0.0:
		var tmp: Vector3 = b
		b = c
		c = tmp
	for v: Vector3 in [a, b, c]:
		st.set_normal(n)
		st.add_vertex(v + off)


static func sandcastle(r: RandomNumberGenerator, small: bool = false) -> Node3D:
	var root := Node3D.new()
	var s: float = 0.85 if small else 1.3
	var c: Color = SAND_DARK
	_part(root, Models.box_mesh(Vector3(0.6, 0.2, 0.6) * s, 0.05 * s), c, Vector3(0, 0.1 * s, 0))
	_part(root, Models.box_mesh(Vector3(0.3, 0.26, 0.3) * s, 0.04 * s), c.lightened(0.06), Vector3(0, 0.33 * s, 0))
	for k in 4:
		var x: float = 0.07 if k % 2 == 0 else -0.07
		var z: float = 0.07 if k < 2 else -0.07
		_part(root, Models.box_mesh(Vector3(0.07, 0.07, 0.07) * s, 0.015 * s), c.lightened(0.06), Vector3(x, 0.5, z) * s)
	for k in 4:
		var a: float = TAU * k / 4.0 + PI * 0.25
		var p := Vector3(cos(a) * 0.27, 0, sin(a) * 0.27) * s
		_part(root, Models.cylinder(0.075 * s, 0.09 * s, 0.32 * s, 10), c, p + Vector3(0, 0.16 * s, 0))
		_part(root, Models.cylinder(0.095 * s, 0.085 * s, 0.06 * s, 10), c.lightened(0.08), p + Vector3(0, 0.34 * s, 0))
	if not small:
		_part(root, Models.cylinder(0.012, 0.012, 0.3, 6), Models.WHITE, Vector3(0, 0.6, 0))
		var flag := _part(root, ClayShapes.extrusion(PackedVector2Array([Vector2(0, 0), Vector2(0.2, -0.06), Vector2(0, -0.12)]), 0.02, 0.006, 1), SWEETS[r.randi() % SWEETS.size()], Vector3(0.01, 0.74, 0))
		flag.rotation.y = r.randf_range(-0.6, 0.6)
	# A shell pressed into the wall.
	var sh := _part(root, shell_mesh(), SHELL_COLORS[r.randi() % 2], Vector3(0, 0.12 * s, 0.31 * s))
	sh.rotation.x = PI * 0.5
	sh.scale = Vector3.ONE * 0.6 * s
	return root


## A lollipop tree: a white stick and a striped candy disc.
static func lollipop(r: RandomNumberGenerator, h: float = 1.0) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.22)
	var stick_h: float = 0.75 * h
	_part(root, Models.cylinder(0.03, 0.035, stick_h, 8), Models.WHITE, Vector3(0, stick_h * 0.5, 0))
	var head := Node3D.new()
	head.position = Vector3(0, stick_h + 0.2 * h, 0)
	head.rotation.y = r.randf_range(-0.5, 0.5)
	head.rotation.z = r.randf_range(-0.15, 0.15)
	head.rotation.x = -0.75
	root.add_child(head)
	var a: Color = SWEETS[r.randi() % SWEETS.size()]
	var b: Color = Models.WHITE
	var radii: Array[float] = [0.26, 0.2, 0.14, 0.08]
	for k in radii.size():
		var rr: float = radii[k] * h
		var disc := _part(head, Models.cylinder(rr, rr, 0.08 * h + k * 0.012, 24), a if k % 2 == 0 else b, Vector3.ZERO)
		disc.rotation.x = PI * 0.5
	return root


static func beach_ball(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.45, 0.25)
	var ball := Node3D.new()
	ball.position.y = 0.15
	ball.rotation = Vector3(r.randf_range(-0.5, 0.5), r.randf() * TAU, r.randf_range(-0.5, 0.5))
	root.add_child(ball)
	var top := Models.sphere(0.15, -1, 16).duplicate() as SphereMesh
	top.is_hemisphere = true
	top.height = 0.15
	_part(ball, top, SWEETS[r.randi() % SWEETS.size()], Vector3.ZERO)
	var bottom := _part(ball, top, Models.WHITE, Vector3.ZERO)
	bottom.rotation.x = PI
	_part(ball, Models.cylinder(0.153, 0.153, 0.03, 16), Color("#5FB8F0"), Vector3.ZERO)
	return root


static func bucket(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var c: Color = SWEETS[r.randi() % SWEETS.size()]
	_part(root, Models.cylinder(0.11, 0.085, 0.17, 14), c, Vector3(0, 0.085, 0))
	_part(root, Models.cylinder(0.118, 0.118, 0.03, 14), c.lightened(0.2), Vector3(0, 0.17, 0))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.1
	handle.outer_radius = 0.115
	handle.rings = 16
	handle.ring_segments = 6
	var hm := _part(root, handle, Models.WHITE, Vector3(0, 0.17, 0))
	hm.rotation.x = PI * 0.5
	hm.rotation.z = 0.5
	root.rotation.y = r.randf() * TAU
	return root


## A starfish or two and a shell lying on the sand.
static func beach_bits(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(1, 3):
		var star: bool = r.randf() < 0.5
		var m := _part(root, star_mesh() if star else shell_mesh(), STAR_COLORS[r.randi() % 3] if star else SHELL_COLORS[r.randi() % 2],
			Vector3(r.randf_range(-0.3, 0.3), 0.005, r.randf_range(-0.3, 0.3)))
		m.rotation.y = r.randf() * TAU
		m.scale = Vector3.ONE * r.randf_range(0.8, 1.15)
	return root


# --- Water --------------------------------------------------------------------

const _NOISE := """
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
"""

## The open sea round the island: turquoise near the sand, deeper further
## out, with foam lapping the shores of up to six rectangles in [code]isles[/code]
## (centre xz, half size xz).
static func sea_material(isles: Array[Vector4]) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec4 shallow : source_color = vec4(0.36, 0.86, 0.86, 1.0);
uniform vec4 deep : source_color = vec4(0.13, 0.62, 0.80, 1.0);
uniform vec4 isles[6];
varying vec3 wp;
""" + _NOISE + """
float shore(vec2 p) {
	float d = 1000.0;
	for (int i = 0; i < 6; i++) {
		if (isles[i].z <= 0.0) { continue; }
		vec2 q = abs(p - isles[i].xy) - isles[i].zw;
		d = min(d, length(max(q, 0.0)) + min(max(q.x, q.y), 0.0));
	}
	return d;
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = mod(TIME, 600.0);
	vec2 p = wp.xz;
	float d = shore(p);
	float n1 = noise(p * 0.9 + vec2(t * 0.22, t * 0.14));
	float n2 = noise(p * 2.7 + vec2(-t * 0.31, t * 0.24));
	vec3 col = mix(shallow.rgb, deep.rgb, smoothstep(0.3, 7.0, d + (n1 - 0.5) * 1.2));
	// Sun glints: a thin web where two noise layers meet.
	float web = 1.0 - clamp(abs(n1 - n2) * 5.0, 0.0, 1.0);
	col += vec3(0.9, 1.0, 1.0) * pow(web, 6.0) * 0.18;
	// Foam that laps the sand, and a soft wave line that rolls in.
	float lap = 0.18 + 0.1 * sin(t * 1.4 + p.x * 0.3 + p.y * 0.2);
	float foam = 1.0 - smoothstep(lap, lap + 0.1, d + (n2 - 0.5) * 0.2);
	float w = fract(t * 0.18);
	float ring = (1.0 - smoothstep(0.0, 0.07, abs(d - (1.6 - w * 1.4)))) * smoothstep(0.0, 0.3, w) * (0.4 + 0.6 * n2);
	col = mix(col, vec3(1.0), clamp(foam * 0.95 + ring * 0.5, 0.0, 1.0));
	ALBEDO = col;
	ROUGHNESS = 0.18;
	SPECULAR = 0.45;
	vec3 nrm = normalize(vec3((n2 - 0.5) * 0.25, 1.0, (n1 - 0.5) * 0.25));
	NORMAL = normalize((VIEW_MATRIX * vec4(nrm, 0.0)).xyz);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	var arr: Array[Vector4] = []
	for i in 6:
		arr.append(isles[i] if i < isles.size() else Vector4.ZERO)
	m.set_shader_parameter(&"isles", arr)
	return m


## Tide-pool water: clear and see-through when shallow, a bright turquoise
## block when full. [code]fill[/code] (0..1) is the tide, [code]shimmer[/code]
## (0..1) the sparkle that warns of a change.
static func pool_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec4 shallow : source_color = vec4(0.42, 0.88, 0.90, 1.0);
uniform vec4 deep : source_color = vec4(0.02, 0.55, 0.82, 1.0);
uniform float fill = 0.0;
uniform float shimmer = 0.0;
varying vec3 wp;
varying vec3 wn;
""" + _NOISE + """
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float t = mod(TIME, 600.0);
	vec2 p = wp.xz;
	float top = smoothstep(0.6, 0.95, wn.y);
	float n1 = noise(p * 2.2 + vec2(t * 0.35, t * 0.2));
	float n2 = noise(p * 4.1 + vec2(-t * 0.28, t * 0.33));
	float web = 1.0 - clamp(abs(n1 - n2) * 4.0, 0.0, 1.0);
	vec3 col = mix(shallow.rgb, deep.rgb, clamp(fill * 0.85 + (1.0 - top) * 0.3, 0.0, 1.0));
	col += vec3(1.0) * pow(web, 4.0) * (0.12 + 0.25 * fill) * top;
	// Warning shimmer: bright sparkles that blink across the surface.
	float sp = noise(p * 7.0 + vec2(0.0, floor(t * 8.0) * 3.1));
	col += vec3(1.0) * smoothstep(0.78, 0.9, sp) * shimmer * 0.9;
	col = mix(col, vec3(1.0), shimmer * 0.12 * (0.5 + 0.5 * sin(t * 12.0)));
	ALBEDO = col;
	ALPHA = clamp(mix(0.7, 0.93, fill) + shimmer * 0.15, 0.0, 1.0);
	ROUGHNESS = 0.2;
	SPECULAR = 0.3;
	EMISSION = col * (0.12 + shimmer * 0.25);
	vec3 nrm = normalize(vec3((n2 - 0.5) * 0.35, 1.0, (n1 - 0.5) * 0.35));
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(nrm, 0.0)).xyz, top));
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m

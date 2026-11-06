extends RefCounted
## Models for World 20, Pixel Arcade: a bright retro arcade floor. Critters
## and props are built from crisp voxel "pixels" (one merged mesh per shape,
## only the outer faces), the rest from the usual slightly rounded clay
## blocks. Bleepers (marching pixel blobs), Blips (bouncing pixel balls), the
## Mega Cabinet boss, the wrap arches that mark the gaps in the border wall,
## and arcade props: joysticks, cabinets, coin stacks and pixel hearts.

const CRT := Color("#3D6CF0")
const CRT_DARK := Color("#2A4BB8")
const SCREEN := Color("#1E2A5C")
const SCREEN_GLOW := Color("#5FF2FF")
const CANDY := Color("#FF6FB5")
const CANDY_LIGHT := Color("#FFB3DA")
const LEMON := Color("#FFD84D")
const MINT := Color("#A2E23A")
const MINT_DARK := Color("#6DAE1F")
const GRAPE := Color("#9A6BFF")
const GRAPE_LIGHT := Color("#C9B2FF")
const INK := Color("#2A2550")
const WHITE := Color("#FFFDF8")
const NAVY := Color("#33306B")
const COIN := Color("#FFC93C")
const BLEEPER_SIZE: float = 1.2
const BLIP_SIZE: float = 1.15
const BOSS_SIZE: float = 1.35

## One colour per pair of wrap gaps: its arch, floor arrows and sparkles.
const PAIR_COLORS: Array[Color] = [Color("#38D6FF"), Color("#FF5FB8"), Color("#FFC93C"), Color("#5FE3A1")]

static var _meshes: Dictionary = {}


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- Voxels ---------------------------------------------------------------------------

## One mesh from a set of voxels (Vector3i cells, [param size] wide, cell
## (0, 0, 0) centred on [param origin] in voxel units). Only faces that touch
## an empty cell are kept, so a solid shape costs little.
static func voxel_mesh(key: String, cells: Array, size: float, origin: Vector3 = Vector3.ZERO) -> ArrayMesh:
	if _meshes.has(key):
		return _meshes[key]
	var solid: Dictionary = {}
	for c: Vector3i in cells:
		solid[c] = true
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	var faces: Array = [
		[Vector3i(1, 0, 0), Vector3(1, 0, 0)], [Vector3i(-1, 0, 0), Vector3(-1, 0, 0)],
		[Vector3i(0, 1, 0), Vector3(0, 1, 0)], [Vector3i(0, -1, 0), Vector3(0, -1, 0)],
		[Vector3i(0, 0, 1), Vector3(0, 0, 1)], [Vector3i(0, 0, -1), Vector3(0, 0, -1)],
	]
	for c: Vector3i in solid:
		var centre: Vector3 = (Vector3(c) - origin) * size
		for f: Array in faces:
			var nd: Vector3i = f[0]
			if solid.has(c + nd):
				continue
			var n: Vector3 = f[1]
			# Two axes spanning the face.
			var u: Vector3 = Vector3(n.y, n.z, n.x)
			var v: Vector3 = n.cross(u)
			var h: float = size * 0.5
			var mid: Vector3 = centre + n * h
			var a: Vector3 = mid + (-u - v) * h
			var b: Vector3 = mid + (u - v) * h
			var cc: Vector3 = mid + (u + v) * h
			var d: Vector3 = mid + (-u + v) * h
			var base: int = verts.size()
			for p: Vector3 in [a, b, cc, d]:
				verts.append(p)
				norms.append(n)
			var cross: Vector3 = (b - a).cross(cc - a)
			if cross.dot(n) > 0.0:
				idx.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
			else:
				idx.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	if not verts.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	_meshes[key] = mesh
	return mesh


## Voxels from rows of text: each string is one row (top row first), "#"
## filled, anything else empty; [param depth] layers deep along Z.
static func sprite_cells(rows: Array, depth: int) -> Array:
	var out: Array = []
	var h: int = rows.size()
	for r in h:
		var row: String = rows[r]
		for x in row.length():
			if row[x] == "#":
				for z in depth:
					out.append(Vector3i(x, h - 1 - r, z))
	return out


static func _vpart(parent: Node3D, key: String, cells: Array, size: float, origin: Vector3, color: Color, pos: Vector3, glow: float = 0.0) -> MeshInstance3D:
	return Models.part(parent, voxel_mesh(key, cells, size, origin), color, pos, glow)


# --- Bleeper ----------------------------------------------------------------------------

## Bleeper: a little mint pixel blob with big pixel eyes, one antenna with a
## glowing tip and four stubby feet that swap like a two-frame sprite
## ("FeetA" / "FeetB"). They march in rows and step down at the ends.
static func bleeper() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.9, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var vs: float = 0.075
	var blob: Dictionary = {}
	for x in range(-4, 5):
		for y in range(0, 7):
			for z in range(-3, 4):
				var e: float = pow(x / 4.6, 2.0) + pow((y - 2.6) / 3.7, 2.0) + pow(z / 3.6, 2.0)
				if e <= 1.0:
					blob[Vector3i(x, y, z)] = true
	# Eyes: 2x2 white pixels with a dark one, set into the front of the face.
	var whites: Array = _take_front(blob, [Vector2i(-2, 3), Vector2i(-2, 4), Vector2i(-1, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(2, 3)])
	var pupils: Array = _take_front(blob, [Vector2i(-1, 3), Vector2i(1, 3)])
	var belly: Array = []
	for c: Vector3i in blob.keys():
		if c.z >= 2 and c.y <= 1 and absi(c.x) <= 2:
			blob.erase(c)
			belly.append(c)
	var lift := Vector3(0, 0.12, 0)
	_vpart(body, "bleeper/body", blob.keys(), vs, Vector3.ZERO, MINT, lift)
	_vpart(body, "bleeper/belly", belly, vs, Vector3.ZERO, Color("#E4F9B5"), lift)
	_vpart(body, "bleeper/eyes", whites, vs, Vector3.ZERO, WHITE, lift)
	_vpart(body, "bleeper/pupils", pupils, vs, Vector3.ZERO, INK, lift)
	# Antenna with a glowing tip.
	_vpart(body, "bleeper/stalk", [Vector3i(0, 7, 0), Vector3i(0, 8, 0)], vs, Vector3.ZERO, MINT_DARK, lift)
	var tip := _vpart(body, "bleeper/tip", [Vector3i(0, 0, 0)], vs * 1.6, Vector3.ZERO, LEMON, lift + Vector3(0, 9.3 * vs, 0), 1.6)
	tip.name = "Tip"
	_no_shadow(tip)
	# Feet, two frames.
	for frame in 2:
		var feet: Array = []
		var xs: Array = [-3, 1] if frame == 0 else [-2, 2]
		for fx: int in xs:
			for dz in 2:
				feet.append(Vector3i(fx, -1, dz - 1))
				feet.append(Vector3i(fx + 1, -1, dz - 1))
		var f := _vpart(body, "bleeper/feet%d" % frame, feet, vs, Vector3.ZERO, MINT_DARK, lift)
		f.name = "FeetA" if frame == 0 else "FeetB"
		f.visible = frame == 0
	return root


## Removes the front-most voxel at each (x, y) of [param spots] from
## [param cells] (a set) and returns them, to colour them separately.
static func _take_front(cells: Dictionary, spots: Array) -> Array:
	var out: Array = []
	for s: Vector2i in spots:
		var best: Vector3i = Vector3i(0, 0, -999)
		for c: Vector3i in cells:
			if c.x == s.x and c.y == s.y and c.z > best.z:
				best = c
		if best.z > -999:
			cells.erase(best)
			out.append(best)
	return out


# --- Blip ---------------------------------------------------------------------------------

## Blip: a bouncing grape-coloured pixel ball with a light stripe and a
## cheeky face. Shoots along straight lines and ricochets.
static func blip() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.75, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var ball := Node3D.new()
	ball.name = "Ball"
	ball.position.y = 0.3
	body.add_child(ball)
	var vs: float = 0.08
	var shell: Dictionary = {}
	for x in range(-3, 4):
		for y in range(-3, 4):
			for z in range(-3, 4):
				if x * x + y * y + z * z <= 12:
					shell[Vector3i(x, y, z)] = true
	var eyes: Array = _take_front(shell, [Vector2i(-1, 1), Vector2i(1, 1)])
	var shine: Array = []
	for c: Vector3i in [Vector3i(-2, 2, 2), Vector3i(-1, 3, 1), Vector3i(-2, 1, 2)]:
		if shell.has(c):
			shell.erase(c)
			shine.append(c)
	var stripe: Array = []
	for c: Vector3i in shell.keys():
		if c.y == -1:
			shell.erase(c)
			stripe.append(c)
	_vpart(ball, "blip/shell", shell.keys(), vs, Vector3.ZERO, GRAPE, Vector3.ZERO)
	_vpart(ball, "blip/stripe", stripe, vs, Vector3.ZERO, GRAPE_LIGHT, Vector3.ZERO)
	_vpart(ball, "blip/shine", shine, vs, Vector3.ZERO, WHITE, Vector3.ZERO, 0.6)
	_vpart(ball, "blip/eyes", eyes, vs, Vector3.ZERO, INK, Vector3.ZERO)
	return root


# --- Mega Cabinet (boss) ------------------------------------------------------------

## The Mega Cabinet: a big arcade cabinet robot in CRT blue with candy-pink
## side panels, a glowing marquee, a screen face with pixel eyes ("Screen/
## Eyes", "Screen/Static" for the glitch before it teleports), a control
## panel with a joystick and buttons, little arms and sneaker feet.
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.7, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	# Feet and legs.
	for side: int in [-1, 1]:
		var leg := Node3D.new()
		leg.name = "LegL" if side < 0 else "LegR"
		leg.position = Vector3(side * 0.3, 0.0, 0.0)
		body.add_child(leg)
		Models.part(leg, Models.box_mesh(Vector3(0.14, 0.22, 0.14), 0.04), NAVY, Vector3(0, 0.2, 0))
		Models.part(leg, Models.box_mesh(Vector3(0.28, 0.14, 0.4), 0.06), WHITE, Vector3(0, 0.07, 0.06))
		Models.part(leg, Models.box_mesh(Vector3(0.29, 0.05, 0.41), 0.02), CANDY, Vector3(0, 0.02, 0.06))
	var cab := Node3D.new()
	cab.name = "Cab"
	cab.position.y = 0.3
	body.add_child(cab)
	# Cabinet body, side panels and the slanted top with its marquee.
	Models.part(cab, Models.box_mesh(Vector3(0.96, 1.25, 0.78), 0.08), CRT, Vector3(0, 0.63, 0))
	for side: int in [-1, 1]:
		Models.part(cab, Models.box_mesh(Vector3(0.08, 1.33, 0.84), 0.035), CANDY, Vector3(side * 0.5, 0.66, 0))
		Models.part(cab, Models.box_mesh(Vector3(0.09, 0.12, 0.6), 0.03), LEMON, Vector3(side * 0.51, 0.3, 0.02), 0.5)
	var marquee := Models.part(cab, Models.box_mesh(Vector3(0.92, 0.24, 0.24), 0.05), LEMON, Vector3(0, 1.34, 0.22), 1.1)
	marquee.name = "Marquee"
	Models.part(cab, Models.box_mesh(Vector3(0.98, 0.07, 0.86), 0.03), CRT_DARK, Vector3(0, 1.27, 0))
	# The screen, tilted a little up toward the camera.
	var screen := Node3D.new()
	screen.name = "Screen"
	screen.position = Vector3(0, 0.92, 0.4)
	screen.rotation.x = -0.32
	cab.add_child(screen)
	Models.part(screen, Models.box_mesh(Vector3(0.78, 0.5, 0.06), 0.03), INK, Vector3.ZERO)
	Models.part(screen, Models.box_mesh(Vector3(0.68, 0.4, 0.05), 0.02), SCREEN, Vector3(0, 0, 0.02), 0.3)
	var eyes := Node3D.new()
	eyes.name = "Eyes"
	eyes.position.z = 0.05
	screen.add_child(eyes)
	var eye_rows: Array = ["##...##", "##...##", ".......", "..###.."]
	var eye_cells: Array = sprite_cells(eye_rows, 1)
	var em: ArrayMesh = voxel_mesh("boss/eyes", eye_cells, 0.07, Vector3(3.0, 1.5, 0.0))
	_no_shadow(Models.part(eyes, em, SCREEN_GLOW, Vector3.ZERO, 1.8))
	var stat := Node3D.new()
	stat.name = "Static"
	stat.position.z = 0.05
	stat.visible = false
	screen.add_child(stat)
	var noise: Array = []
	var r := RandomNumberGenerator.new()
	r.seed = 2020
	for x in 9:
		for y in 5:
			if r.randf() < 0.45:
				noise.append(Vector3i(x, y, 0))
	_no_shadow(Models.part(stat, voxel_mesh("boss/static", noise, 0.07, Vector3(4.0, 2.0, 0.0)), WHITE, Vector3.ZERO, 1.4))
	# Control panel with a joystick and two buttons.
	var panel := Models.part(cab, Models.box_mesh(Vector3(0.98, 0.12, 0.38), 0.04), CRT_DARK, Vector3(0, 0.56, 0.5))
	panel.rotation.x = 0.25
	var stick := Node3D.new()
	stick.name = "Stick"
	stick.position = Vector3(-0.22, 0.62, 0.52)
	cab.add_child(stick)
	Models.part(stick, Models.cylinder(0.022, 0.026, 0.2, 8), INK, Vector3(0, 0.1, 0))
	Models.part(stick, Models.sphere(0.07, -1, 12), CANDY, Vector3(0, 0.22, 0), 0.4)
	for k in 2:
		Models.part(cab, Models.cylinder(0.055, 0.06, 0.06, 12), [LEMON, SCREEN_GLOW][k], Vector3(0.14 + k * 0.17, 0.64, 0.53), 0.9)
	# Coin door.
	Models.part(cab, Models.box_mesh(Vector3(0.36, 0.26, 0.04), 0.03), CRT_DARK, Vector3(0, 0.22, 0.4))
	Models.part(cab, Models.box_mesh(Vector3(0.05, 0.12, 0.03), 0.01), COIN, Vector3(0, 0.24, 0.425), 0.8)
	# Little arms.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.56, 0.75, 0.05)
		cab.add_child(arm)
		Models.part(arm, Models.box_mesh(Vector3(0.1, 0.36, 0.1), 0.04), NAVY, Vector3(side * 0.05, -0.16, 0))
		Models.part(arm, Models.box_mesh(Vector3(0.17, 0.15, 0.17), 0.05), WHITE, Vector3(side * 0.05, -0.38, 0))
	root.scale = Vector3.ONE * BOSS_SIZE
	return root


# --- Arena pieces ---------------------------------------------------------------------

## A wrap arch over one gap in the border wall: two pixel posts, a glowing
## beam on top and two floor chevrons ("Chev0", "Chev1") that slide out
## through the gap. Built facing -Z (the way out); the posts stand along X.
static func arch(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.96, 0.3, 0.96), 0.08), color.lerp(Color.WHITE, 0.55), Vector3(0, -0.15, 0))
	var pad := Models.part(root, Models.box_mesh(Vector3(0.66, 0.03, 0.86), 0.015), color, Vector3(0, 0.005, 0), 0.9)
	pad.name = "Pad"
	_no_shadow(pad)
	for side: int in [-1, 1]:
		Models.part(root, Models.box_mesh(Vector3(0.2, 1.08, 0.36), 0.05), color, Vector3(side * 0.46, 0.54, 0), 0.25)
		Models.part(root, Models.box_mesh(Vector3(0.24, 0.1, 0.4), 0.03), WHITE, Vector3(side * 0.46, 0.07, 0))
	var beam := Models.part(root, Models.box_mesh(Vector3(1.16, 0.22, 0.38), 0.06), color, Vector3(0, 1.12, 0), 0.8)
	beam.name = "Beam"
	# A shimmering glass "screen" across the opening: the way through.
	var film := MeshInstance3D.new()
	film.mesh = Models.box_mesh(Vector3(0.72, 1.0, 0.05), 0.02)
	film.material_override = Models.glass(color.lerp(Color.WHITE, 0.25), 0.45, 0.6)
	film.position = Vector3(0, 0.52, -0.12)
	film.name = "Film"
	film.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(film)
	# Pixel arrow on the beam, pointing out.
	var arrow: Array = sprite_cells(["..#..", ".###.", "#####"], 1)
	var am: ArrayMesh = voxel_mesh("arch/arrow", arrow, 0.075, Vector3(2.0, 1.0, 0.0))
	var ar := Models.part(root, am, WHITE, Vector3(0, 1.24, 0.0), 1.2)
	ar.rotation.x = -PI * 0.5
	_no_shadow(ar)
	var chev := Models.chevron_mesh()
	for k in 2:
		var c := Models.part(root, chev, WHITE, Vector3(0, 0.03, 0.2 - k * 0.4), 1.2)
		c.rotation = Vector3(-PI * 0.5, PI * 0.5, 0)
		c.name = "Chev%d" % k
		_no_shadow(c)
	return root


## A flat warning pixel square (the Mega Cabinet's beam is about to come
## through here).
static func warn_tile() -> Node3D:
	var root := Node3D.new()
	_no_shadow(Models.part(root, Models.box_mesh(Vector3(0.78, 0.04, 0.78), 0.02), CANDY, Vector3(0, 0.03, 0), 1.2))
	_no_shadow(Models.part(root, Models.box_mesh(Vector3(0.5, 0.05, 0.5), 0.02), WHITE, Vector3(0, 0.04, 0), 1.2))
	return root


# --- Props ------------------------------------------------------------------------------

## A giant arcade joystick: a navy base with a pink ball-top stick and two
## glowing buttons.
static func joystick(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var top: Color = [CANDY, SCREEN_GLOW, LEMON, MINT][r.randi() % 4]
	Models.part(root, Models.box_mesh(Vector3(0.6, 0.22, 0.46), 0.07), NAVY, Vector3(0, 0.11, 0))
	Models.part(root, Models.box_mesh(Vector3(0.62, 0.04, 0.48), 0.02), CRT, Vector3(0, 0.23, 0))
	var stick := Models.part(root, Models.cylinder(0.03, 0.035, 0.32, 8), INK, Vector3(-0.12, 0.38, 0))
	stick.rotation.z = r.randf_range(-0.25, 0.25)
	Models.part(root, Models.sphere(0.1, -1, 14), top, Vector3(-0.12 - stick.rotation.z * 0.3, 0.56, 0), 0.5)
	for k in 2:
		Models.part(root, Models.cylinder(0.055, 0.06, 0.06, 12), [LEMON, CANDY][k], Vector3(0.12 + k * 0.14, 0.26, 0.04 - k * 0.08), 1.0)
	return root


## A little arcade cabinet with a glowing screen and marquee.
static func cabinet(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var side_col: Color = [CANDY, MINT, GRAPE, LEMON][r.randi() % 4]
	Models.part(root, Models.box_mesh(Vector3(0.56, 1.0, 0.5), 0.05), CRT, Vector3(0, 0.5, 0))
	for side: int in [-1, 1]:
		Models.part(root, Models.box_mesh(Vector3(0.05, 1.06, 0.54), 0.02), side_col, Vector3(side * 0.29, 0.53, 0))
	Models.part(root, Models.box_mesh(Vector3(0.5, 0.15, 0.14), 0.03), side_col.lerp(Color.WHITE, 0.3), Vector3(0, 1.0, 0.16), 1.0)
	var scr := Models.part(root, Models.box_mesh(Vector3(0.42, 0.3, 0.04), 0.02), SCREEN_GLOW, Vector3(0, 0.74, 0.25), 0.9)
	scr.rotation.x = -0.25
	var panel := Models.part(root, Models.box_mesh(Vector3(0.56, 0.06, 0.2), 0.02), CRT_DARK, Vector3(0, 0.5, 0.3))
	panel.rotation.x = 0.25
	Models.part(root, Models.sphere(0.04, -1, 8), CANDY, Vector3(-0.1, 0.57, 0.32), 0.5)
	return root


## A short stack of big gold coins.
static func coins(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var n: int = r.randi_range(2, 4)
	for k in n:
		var c := Models.part(root, Models.cylinder(0.2, 0.2, 0.07, 16), COIN, Vector3(r.randf_range(-0.03, 0.03), 0.04 + k * 0.075, r.randf_range(-0.03, 0.03)), 0.15)
		c.rotation.y = r.randf() * TAU
	var top := Models.part(root, Models.cylinder(0.12, 0.12, 0.01, 12), COIN.lightened(0.35), Vector3(0, 0.08 + (n - 1) * 0.075, 0), 0.3)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## A floating pixel heart or star.
static func pixel_icon(heart: bool) -> Node3D:
	var root := Node3D.new()
	var rows: Array
	var col: Color
	if heart:
		rows = [".##.##.", "#######", "#######", ".#####.", "..###..", "...#..."]
		col = CANDY
	else:
		rows = ["...#...", "..###..", "#######", ".#####.", ".##.##.", "##...##"]
		col = LEMON
	var cells: Array = sprite_cells(rows, 2)
	var m: ArrayMesh = voxel_mesh("icon/%s" % ("heart" if heart else "star"), cells, 0.09, Vector3(3.0, 0.0, 0.5))
	var holder := Node3D.new()
	holder.name = "Spin"
	holder.position.y = 0.35
	root.add_child(holder)
	Models.part(holder, m, col, Vector3.ZERO, 0.5)
	Models.part(root, Models.cylinder(0.03, 0.03, 0.36, 6), WHITE, Vector3(0, 0.18, 0))
	Models.part(root, Models.cylinder(0.14, 0.16, 0.06, 12), NAVY, Vector3(0, 0.03, 0))
	return root

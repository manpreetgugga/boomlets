extends RefCounted
## Cocoa Canyon's own models and meshes: crisp crystals, layered sandstone,
## the burrowing Mole and the boss, Baron Burrow. Everything is built from
## slightly rounded blocks and faceted crystals to match the clay-block look.
## Loaded by path from worlds/world_3.gd (no class_name on purpose).

# Colours (sRGB).
const CRYSTAL_A := Color("#B48CFF")
const CRYSTAL_B := Color("#E0C8FF")
const CRYSTAL_DEEP := Color("#8A5CE6")
const COCOA := Color("#6E4532")
const CARAMEL := Color("#B07650")
const SAND := Color("#D9A57A")
const SAND_LIGHT := Color("#EBC39A")
const MUD := Color("#5A3122")
const MUD_LIGHT := Color("#7A4A33")
const DIRT_A := Color("#A56C4A")
const DIRT_B := Color("#7E4D35")
const MOLE := Color("#8C5B45")
const MOLE_BELLY := Color("#F6DDBE")
const MOLE_NOSE := Color("#FF86A6")
const HAT := Color("#FFD447")
const BARON := Color("#8F5E46")
const DRILL := Color("#F3C623")
const STEEL := Color("#D8D0E6")
const PLUM := Color("#6B3F8E")



## A faceted six-sided crystal: a prism from y = 0 to 1 with a point on top
## reaching y = 1.45, radius 0.5. Flat shaded so every facet catches light.
static func crystal_mesh() -> ArrayMesh:
	# Cached with the other shared meshes in Models.
	if Models._boxes.has("w3_crystal"):
		return Models._boxes["w3_crystal"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ring: Array[Vector3] = []
	for k in 6:
		var a: float = TAU * k / 6.0
		ring.append(Vector3(cos(a) * 0.5, 0.0, sin(a) * 0.5))
	var tip := Vector3(0, 1.45, 0)
	for k in 6:
		var a0: Vector3 = ring[k]
		var a1: Vector3 = ring[(k + 1) % 6]
		var b0: Vector3 = a0 + Vector3(0, 1, 0)
		var b1: Vector3 = a1 + Vector3(0, 1, 0)
		_tri(st, a0, b1, a1)
		_tri(st, a0, b0, b1)
		_tri(st, b0, tip, b1)
	var mesh: ArrayMesh = st.commit()
	Models._boxes["w3_crystal"] = mesh
	return mesh


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	# Make sure the facet faces outward (away from the crystal's axis).
	var centre := (a + b + c) / 3.0
	if n.dot(Vector3(centre.x, 0.0, centre.z)) < 0.0 and absf(n.y) < 0.99:
		var t: Vector3 = b
		b = c
		c = t
		n = -n
	# Godot treats clockwise triangles (seen from outside) as front faces.
	st.set_normal(n)
	st.add_vertex(a)
	st.set_normal(n)
	st.add_vertex(c)
	st.set_normal(n)
	st.add_vertex(b)


## Glossy chocolate mud: a dark, wet-looking material.
static func mud_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = MUD
	m.roughness = 0.12
	m.metallic_specular = 0.9
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.6
	return m


static func _crystal_part(parent: Node3D, color: Color, pos: Vector3, radius: float, height: float, tilt: Vector3, glow: float = 0.35) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = crystal_mesh()
	mi.material_override = Models.mat(color, glow)
	mi.position = pos
	mi.rotation = tilt
	mi.scale = Vector3(radius * 2.0, height, radius * 2.0)
	parent.add_child(mi)
	return mi


## A small cluster of three crystals standing on y = 0.
static func crystal_cluster(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var spin: float = r.randf() * TAU
	_crystal_part(root, CRYSTAL_A, Vector3.ZERO, 0.11 * size, 0.42 * size, Vector3(0, spin, 0))
	_crystal_part(root, CRYSTAL_B, Vector3(cos(spin) * 0.12, 0, sin(spin) * 0.12) * size, 0.08 * size, 0.28 * size, Vector3(0.0, spin, 0.45))
	_crystal_part(root, CRYSTAL_DEEP, Vector3(-sin(spin) * 0.11, 0, cos(spin) * 0.1) * size, 0.07 * size, 0.22 * size, Vector3(-0.45, spin, 0.0))
	return root


## A layered sandstone mesa (cocoa, caramel and sand strata) on y = 0.
static func mesa(r: RandomNumberGenerator, height: float, width: float) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, width * 1.4, 0.3)
	var colors: Array[Color] = [COCOA, CARAMEL, SAND, CARAMEL.lightened(0.1), SAND_LIGHT]
	var layers: int = clampi(int(height / 0.24), 2, 5)
	var y: float = 0.0
	var w: float = width
	for k in layers:
		var h: float = height / layers
		var slab := Models.part(root, Models.box_mesh(Vector3(w, h, w * r.randf_range(0.85, 1.0)), minf(0.06, h * 0.3)), colors[k % colors.size()], Vector3(r.randf_range(-0.04, 0.04), y + h * 0.5, r.randf_range(-0.04, 0.04)))
		slab.rotation.y = r.randf_range(-0.2, 0.2)
		y += h
		w *= r.randf_range(0.8, 0.92)
	if r.randf() < 0.5:
		var c := crystal_cluster(r, 0.9)
		c.position.y = y
		root.add_child(c)
	return root


## A rounded cocoa boulder with a smaller one leaning on it.
static func boulder(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	var b := Models.part(root, Models.box_mesh(Vector3(0.42, 0.3, 0.36) * size, 0.13 * size), COCOA.darkened(r.randf() * 0.15), Vector3(0, 0.15 * size, 0))
	b.rotation = Vector3(r.randf_range(-0.25, 0.25), r.randf() * TAU, r.randf_range(-0.25, 0.25))
	if r.randf() < 0.6:
		var s := Models.part(root, Models.box_mesh(Vector3(0.22, 0.18, 0.2) * size, 0.08 * size), CARAMEL, Vector3(0.2 * size, 0.09 * size, 0.1 * size))
		s.rotation = Vector3(0.1, r.randf() * TAU, 0.15)
	return root


## A tall crystal spire: one big crystal and two small ones, like a cactus.
static func crystal_spire(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.28)
	var spin: float = r.randf() * TAU
	var h: float = r.randf_range(0.6, 0.85)
	_crystal_part(root, CRYSTAL_A, Vector3.ZERO, 0.13, h, Vector3(0, spin, 0), 0.45)
	_crystal_part(root, CRYSTAL_B, Vector3(0.14, 0.0, 0.02), 0.08, h * 0.5, Vector3(0, spin, -0.5), 0.45)
	_crystal_part(root, CRYSTAL_DEEP, Vector3(-0.12, 0.0, 0.04), 0.07, h * 0.4, Vector3(0, spin, 0.55), 0.45)
	Models.part(root, Models.box_mesh(Vector3(0.36, 0.1, 0.32), 0.04), COCOA, Vector3(0, 0.04, 0))
	return root


## The dirt mound a burrowing critter shows above ground: a crisp pile of
## cocoa clods.
static func mound(size: float) -> Node3D:
	var root := Node3D.new()
	root.name = "Mound"
	Models.part(root, Models.box_mesh(Vector3(0.62, 0.16, 0.56) * size, 0.07 * size), DIRT_A, Vector3(0, 0.08 * size, 0))
	var top := Models.part(root, Models.box_mesh(Vector3(0.38, 0.14, 0.34) * size, 0.06 * size), DIRT_B, Vector3(0.02, 0.2 * size, -0.02))
	top.rotation.y = 0.5
	for k in 4:
		var a: float = TAU * k / 4.0 + 0.4
		var clod := Models.part(root, Models.box_mesh(Vector3(0.13, 0.1, 0.12) * size, 0.03 * size), DIRT_B if k % 2 else DIRT_A.lightened(0.12), Vector3(cos(a) * 0.36, 0.05, sin(a) * 0.32) * size)
		clod.rotation.y = a
	root.visible = false
	return root


## The Mole: a plump caramel critter in a little miner's hat with a glowing
## lamp. Dives underground and pops up somewhere nearby.
static func mole() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.32)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	# Scale the whole mole up a touch via an inner pivot (Body's own scale is
	# animated by the arena).
	var pivot := Node3D.new()
	pivot.scale = Vector3.ONE * 1.12
	body.add_child(pivot)
	body = pivot
	var shell := Models.part(body, Models.sphere(0.31, 0.58, 22), MOLE, Vector3(0, 0.3, -0.02))
	shell.scale = Vector3(1.0, 1.0, 1.08)
	var belly := Models.part(body, Models.sphere(0.22, 0.4, 16), MOLE_BELLY, Vector3(0, 0.25, 0.15))
	belly.scale = Vector3(1.0, 1.0, 0.6)
	var snout := Models.part(body, Models.sphere(0.11, 0.17, 14), Color("#F4C1A8"), Vector3(0, 0.28, 0.3))
	snout.scale = Vector3(1.1, 0.85, 1.0)
	Models.part(body, Models.sphere(0.055, -1, 10), MOLE_NOSE, Vector3(0, 0.31, 0.4), 0.25)
	Models._eyes(body, 0.42, 0.25, 0.1, 0.055)
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.04, -1, 8), Color("#FF9AA8"), Vector3(side * 0.18, 0.33, 0.27))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
		# Big digging paws: flat pink paddles with three claws.
		var paw := Node3D.new()
		paw.position = Vector3(side * 0.27, 0.14, 0.17)
		paw.rotation = Vector3(0.2, side * -0.5, side * 0.35)
		body.add_child(paw)
		Models.part(paw, Models.box_mesh(Vector3(0.16, 0.05, 0.13), 0.02), Color("#F4C1A8"))
		for k in 3:
			Models.part(paw, Models.box_mesh(Vector3(0.035, 0.035, 0.07), 0.012), MOLE_BELLY, Vector3(-0.05 + k * 0.05, 0.0, 0.08))
		var foot := Models.part(body, Models.sphere(0.08, 0.08, 10), MOLE.darkened(0.2), Vector3(side * 0.14, 0.04, 0.0))
		foot.scale = Vector3(1, 1, 1.3)
	# Miner's hat with a lamp.
	var hat := Node3D.new()
	hat.position = Vector3(0, 0.53, -0.01)
	hat.rotation.x = -0.12
	body.add_child(hat)
	var dome := SphereMesh.new()
	dome.radius = 0.19
	dome.height = 0.19
	dome.is_hemisphere = true
	dome.radial_segments = 18
	dome.rings = 6
	Models.part(hat, dome, HAT, Vector3.ZERO, 0.12)
	Models.part(hat, Models.cylinder(0.24, 0.24, 0.03, 18), HAT.darkened(0.15), Vector3(0, 0.0, 0))
	var lamp := Models.part(hat, Models.cylinder(0.05, 0.05, 0.06, 10), Color("#FFF6D2"), Vector3(0, 0.08, 0.18), 2.0)
	lamp.rotation.x = PI * 0.5
	root.add_child(mound(1.0))
	return root


## Baron Burrow, World 3's boss: a big cocoa mole with a golden drill for a
## nose, a plum miner's helmet with a lamp, a gold monocle and huge paws.
static func baron() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.9, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var shell := Models.part(body, Models.sphere(0.7, 1.22, 28), BARON, Vector3(0, 0.62, -0.05))
	shell.scale = Vector3(1.0, 1.0, 1.05)
	var belly := Models.part(body, Models.sphere(0.46, 0.78, 20), MOLE_BELLY, Vector3(0, 0.52, 0.36))
	belly.scale = Vector3(1.0, 1.0, 0.55)
	# The drill: stepped golden tiers round a steel collar, with spiral fins
	# so the spin reads.
	var drill := Node3D.new()
	drill.name = "Drill"
	drill.position = Vector3(0, 0.6, 0.66)
	body.add_child(drill)
	Models.part(drill, Models.cylinder(0.27, 0.27, 0.12, 20), STEEL, Vector3.ZERO).rotation.x = PI * 0.5
	var tiers: Array[float] = [0.23, 0.18, 0.13, 0.08]
	for k in tiers.size():
		var tier := Models.part(drill, Models.cylinder(tiers[k] * 0.78, tiers[k], 0.12, 16), DRILL if k % 2 == 0 else DRILL.darkened(0.12), Vector3(0, 0, 0.1 + k * 0.11), 0.15)
		tier.rotation.x = PI * 0.5
	var tip := Models.part(drill, Models.cylinder(0.0, 0.065, 0.14, 12), STEEL, Vector3(0, 0, 0.6), 0.2)
	tip.rotation.x = PI * 0.5
	for k in 3:
		var fin := Node3D.new()
		fin.rotation.z = TAU * k / 3.0
		drill.add_child(fin)
		var f := Models.part(fin, Models.box_mesh(Vector3(0.05, 0.05, 0.4), 0.015), DRILL.lightened(0.3), Vector3(0.13, 0, 0.3), 0.2)
		f.rotation = Vector3(0.0, -0.3, 0.6)
	Models._eyes(body, 0.9, 0.55, 0.22, 0.11, true)
	# Gold monocle over the right eye.
	var ring := TorusMesh.new()
	ring.inner_radius = 0.12
	ring.outer_radius = 0.155
	ring.rings = 18
	ring.ring_segments = 6
	var mono := Models.part(body, ring, Models.GOLD, Vector3(0.22, 0.9, 0.63), 0.2)
	mono.rotation.x = PI * 0.5
	Models.part(body, Models.cylinder(0.008, 0.008, 0.36, 4), Models.GOLD, Vector3(0.34, 0.72, 0.6)).rotation.z = 0.3
	for side: int in [-1, 1]:
		var cheek := Models.part(body, Models.sphere(0.08, -1, 8), Color("#FF9AA8"), Vector3(side * 0.42, 0.78, 0.48))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
		var paw := Node3D.new()
		paw.name = "PawL" if side < 0 else "PawR"
		paw.position = Vector3(side * 0.66, 0.36, 0.34)
		paw.rotation = Vector3(0.3, side * -0.45, side * 0.5)
		body.add_child(paw)
		Models.part(paw, Models.box_mesh(Vector3(0.36, 0.1, 0.3), 0.04), Color("#F4C1A8"))
		for k in 3:
			Models.part(paw, Models.box_mesh(Vector3(0.07, 0.07, 0.16), 0.025), STEEL, Vector3(-0.11 + k * 0.11, 0.0, 0.2))
		var foot := Models.part(body, Models.sphere(0.17, 0.16, 12), BARON.darkened(0.25), Vector3(side * 0.36, 0.07, 0.15))
		foot.scale = Vector3(1, 1, 1.4)
	# Helmet with a lamp, and a tiny gold crown on top: he is a Baron.
	var hat := Node3D.new()
	hat.position = Vector3(0, 1.2, -0.12)
	hat.rotation.x = -0.22
	body.add_child(hat)
	var dome := SphereMesh.new()
	dome.radius = 0.42
	dome.height = 0.42
	dome.is_hemisphere = true
	dome.radial_segments = 24
	dome.rings = 8
	Models.part(hat, dome, PLUM)
	Models.part(hat, Models.cylinder(0.52, 0.52, 0.05, 24), PLUM.darkened(0.2), Vector3.ZERO)
	var lamp := Models.part(hat, Models.cylinder(0.1, 0.1, 0.1, 12), Color("#FFF6D2"), Vector3(0, 0.18, 0.38), 2.2)
	lamp.rotation.x = PI * 0.5
	var crown := Node3D.new()
	crown.position = Vector3(0, 0.42, 0)
	hat.add_child(crown)
	Models.part(crown, Models.cylinder(0.15, 0.15, 0.1, 12), Models.GOLD, Vector3.ZERO, 0.25)
	for k in 5:
		var a: float = TAU * k / 5.0
		Models.part(crown, Models.cylinder(0.0, 0.05, 0.13, 6), Models.GOLD, Vector3(cos(a) * 0.12, 0.11, sin(a) * 0.12), 0.25)
	root.add_child(mound(2.0))
	return root

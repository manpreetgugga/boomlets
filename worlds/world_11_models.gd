extends RefCounted
## Clay models for World 11, Spooky Hollow: jack-o'-lanterns with glowing
## carved faces, little sheet ghosts, King Gourdy the pumpkin king, and the
## friendly-spooky village decor (crooked houses, autumn trees, lamp posts,
## hay bales, bats). Every builder returns a fresh Node3D standing on y = 0.
## Loaded by preload path (no class_name).

const PUMPKIN := Color("#FF8A2B")
const PUMPKIN_DARK := Color("#EE7420")
const PUMPKIN_RIB := Color("#D9621A")
const STEM := Color("#5E8A3A")
const VINE := Color("#7DB84A")
const FACE := Color("#FFC94A")
const FACE_HOT := Color("#FFF4B0")
const FACE_SPENT := Color("#8A4A2A")
const GHOST := Color("#FFFDF8")
const GHOST_TINT := Color("#E4DAFF")
const BLUSH := Color("#FFAFC6")
const PLUM := Color("#4A3566")
const STONE := Color("#5E4892")
const STONE_DARK := Color("#4A3878")
const STONE_TOP := Color("#7D66B4")
const IRON := Color("#3A3150")
const LAMP := Color("#FFB347")
const CANDLE := Color("#FFF1DA")
const CANDLE_FLAME := Color("#FFC24A")
const WALL_A := Color("#9C7FD0")
const WALL_B := Color("#7FA6D8")
const WALL_C := Color("#E8A0C0")
const ROOF := Color("#3E3062")
const ROOF_B := Color("#5A3D7A")
const WINDOW := Color("#FFC85C")
const DOOR := Color("#5A3A4A")
const BARK := Color("#5A4470")
const LEAF_ORANGE := Color("#FF9A3C")
const LEAF_PLUM := Color("#9A6CD0")
const LEAF_GOLD := Color("#FFC34D")
const HAY := Color("#EBC46A")
const HAY_DARK := Color("#C99E48")
const GOLD := Color("#FFD045")
const GEM := Color("#B04DE8")
const CAPE := Color("#8E3FC8")
const CAPE_IN := Color("#FF7AA8")
const BAT := Color("#3B2E55")
const INK := Color("#2E2A4A")
const WHITE := Color("#FFFDF8")

const GHOST_SIZE: float = 1.12
const BOSS_SIZE: float = 1.3

static var _cache: Dictionary = {}


static func _cached(key: String, maker: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]


# --- Shared meshes -------------------------------------------------------------

## A triangular carved eye (pointing up), extruded along Z.
static func eye_mesh() -> Mesh:
	return _cached("eye", func() -> Mesh:
		var p := PackedVector2Array([Vector2(0, 0.08), Vector2(-0.075, -0.045), Vector2(0.075, -0.045)])
		return ClayShapes.extrusion(ClayShapes.rounded_polygon(p, 0.016), 0.12, 0.012))


static func nose_mesh() -> Mesh:
	return _cached("nose", func() -> Mesh:
		var p := PackedVector2Array([Vector2(0, 0.04), Vector2(-0.04, -0.025), Vector2(0.04, -0.025)])
		return ClayShapes.extrusion(ClayShapes.rounded_polygon(p, 0.01), 0.12, 0.01))


## A wide grin with two little teeth.
static func mouth_mesh() -> Mesh:
	return _cached("mouth", func() -> Mesh:
		var p := PackedVector2Array([
			Vector2(-0.19, 0.05), Vector2(-0.13, -0.03), Vector2(-0.05, -0.065), Vector2(0.05, -0.065),
			Vector2(0.13, -0.03), Vector2(0.19, 0.05),
			Vector2(0.1, 0.012), Vector2(0.075, 0.012), Vector2(0.058, -0.028), Vector2(0.04, 0.0),
			Vector2(-0.04, 0.0), Vector2(-0.058, -0.028), Vector2(-0.075, 0.012), Vector2(-0.1, 0.012),
		])
		return ClayShapes.extrusion(ClayShapes.rounded_polygon(p, 0.012), 0.12, 0.012))


static func lobe_mesh() -> Mesh:
	return _cached("lobe", func() -> Mesh: return Models.sphere(0.25, 0.56, 18))


## The eight-lobed pumpkin body, about [param r] wide, on [param parent].
static func _pumpkin_body(parent: Node3D, r: float, h: float, y: float) -> void:
	var lobe := Models.sphere(r * 0.3, h, 16)
	for k in 8:
		var a: float = TAU * k / 8.0 + PI * 0.125
		var color: Color = PUMPKIN if k % 2 == 0 else PUMPKIN_DARK
		var n := Models.part(parent, lobe, color, Vector3(sin(a) * r * 0.2, y, cos(a) * r * 0.2))
		n.rotation.y = a
		n.scale = Vector3(0.78, 1.0, 1.0)
	Models.part(parent, Models.sphere(r * 0.42, h * 0.97, 20), PUMPKIN, Vector3(0, y, 0))


## A carved face on the +Z side; its meshes go under a node named "Face".
static func _face(parent: Node3D, scale: float, y: float, z: float, glow: float) -> Node3D:
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, y, z)
	face.scale = Vector3.ONE * scale
	parent.add_child(face)
	for side: int in [-1, 1]:
		var e := Models.part(face, eye_mesh(), FACE, Vector3(side * 0.12, 0.09, -0.01), glow)
		e.rotation.x = -0.12
		e.rotation.z = side * -0.12
	Models.part(face, nose_mesh(), FACE, Vector3(0, 0.0, 0.01), glow)
	var m := Models.part(face, mouth_mesh(), FACE, Vector3(0, -0.11, -0.005), glow)
	m.rotation.x = 0.22
	return face


# --- Jack-o'-lantern tile ---------------------------------------------------------

static func jack(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.0, 0.4)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	_pumpkin_body(body, 0.92, 0.64, 0.32)
	var stem := Models.part(body, Models.cylinder(0.045, 0.065, 0.2, 8), STEM, Vector3(0, 0.68, 0))
	stem.rotation.z = r.randf_range(-0.35, 0.35)
	var leaf := Models.part(body, Models.box_mesh(Vector3(0.18, 0.03, 0.11), 0.014), VINE, Vector3(0.1, 0.63, -0.04))
	leaf.rotation = Vector3(0.0, r.randf() * TAU, 0.3)
	var curl := Models.part(body, Models.sphere(0.035, -1, 8), VINE, Vector3(-0.09, 0.62, 0.05))
	curl.scale = Vector3(1.6, 0.6, 1.0)
	var face := _face(body, 1.15, 0.47, 0.36, 0.5)
	face.rotation.x = -0.7
	return root


# --- Ghost critter ------------------------------------------------------------------

## A little sheet ghost with a scalloped hem, rosy cheeks and nubby arms.
static func ghost() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.75, 0.25)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	Models.part(body, Models.sphere(0.3, 0.6, 22), GHOST, Vector3(0, 0.58, 0), 0.12)
	Models.part(body, Models.cylinder(0.3, 0.34, 0.3, 20), GHOST, Vector3(0, 0.4, 0), 0.12)
	for k in 7:
		var a: float = TAU * k / 7.0
		Models.part(body, Models.sphere(0.09, -1, 10), GHOST, Vector3(sin(a) * 0.28, 0.26, cos(a) * 0.28), 0.12)
	for side: int in [-1, 1]:
		var eye := Models.part(body, Models.sphere(0.05, 0.13, 12), INK, Vector3(side * 0.1, 0.6, 0.27))
		eye.scale = Vector3(1.0, 1.0, 0.6)
		Models.part(body, Models.sphere(0.016, -1, 6), WHITE, Vector3(side * 0.1 + 0.015, 0.63, 0.3), 1.0)
		var cheek := Models.part(body, Models.sphere(0.05, -1, 10), BLUSH, Vector3(side * 0.18, 0.52, 0.23))
		cheek.scale = Vector3(1.0, 0.6, 0.5)
		var arm := Models.part(body, Models.sphere(0.085, -1, 10), GHOST, Vector3(side * 0.31, 0.42, 0.04), 0.12)
		arm.scale = Vector3(1.0, 0.75, 0.85)
		arm.name = "ArmL" if side < 0 else "ArmR"
	var mouth := Models.part(body, Models.sphere(0.035, -1, 8), INK, Vector3(0, 0.5, 0.285))
	mouth.scale = Vector3(1.0, 1.25, 0.5)
	var tuft := Models.part(body, Models.sphere(0.07, -1, 10), GHOST, Vector3(0.03, 0.88, 0.0), 0.12)
	tuft.scale = Vector3(0.8, 1.4, 0.8)
	tuft.rotation.z = -0.4
	return root


# --- King Gourdy (boss) --------------------------------------------------------------

static func king_gourdy() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	# A royal cape behind him.
	var cape := Node3D.new()
	cape.name = "Cape"
	cape.position = Vector3(0, 0.95, -0.42)
	body.add_child(cape)
	var c1 := Models.part(cape, Models.box_mesh(Vector3(1.3, 0.95, 0.1), 0.05), CAPE, Vector3(0, -0.45, 0))
	c1.rotation.x = 0.18
	Models.part(cape, Models.box_mesh(Vector3(1.22, 0.86, 0.06), 0.04), CAPE_IN, Vector3(0, -0.43, 0.06)).rotation.x = 0.18
	# The great pumpkin himself.
	_pumpkin_body(body, 1.45, 1.1, 0.6)
	# Feet.
	for side: int in [-1, 1]:
		var foot := Models.part(body, Models.sphere(0.17, 0.2, 12), STEM, Vector3(side * 0.36, 0.08, 0.3))
		foot.scale = Vector3(1.0, 1.0, 1.4)
	# Friendly glowing face.
	var face := _face(body, 2.0, 0.74, 0.64, 0.7)
	face.rotation.x = -0.45
	# Stubby vine arms, one with a little lantern sceptre.
	for side: int in [-1, 1]:
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.68, 0.62, 0.12)
		body.add_child(arm)
		var a := Models.part(arm, Models.cylinder(0.06, 0.07, 0.36, 8), STEM, Vector3(side * 0.12, -0.05, 0))
		a.rotation.z = side * 1.0
		Models.part(arm, Models.sphere(0.1, -1, 10), VINE, Vector3(side * 0.28, -0.14, 0.02))
		if side > 0:
			Models.part(arm, Models.cylinder(0.025, 0.025, 0.7, 8), GOLD, Vector3(0.3, 0.1, 0.06), 0.15)
			var orb := Node3D.new()
			orb.position = Vector3(0.3, 0.5, 0.06)
			arm.add_child(orb)
			_pumpkin_body(orb, 0.26, 0.2, 0.0)
			Models.part(orb, Models.sphere(0.04, -1, 8), FACE_HOT, Vector3(0, 0.0, 0.1), 1.2)
	# Stem and crown.
	Models.part(body, Models.cylinder(0.07, 0.1, 0.22, 10), STEM, Vector3(0, 1.17, 0))
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0.0, 1.2, -0.04)
	crown.rotation.z = 0.12
	body.add_child(crown)
	Models.part(crown, Models.cylinder(0.3, 0.27, 0.18, 18), GOLD, Vector3(0, 0.07, 0), 0.2)
	Models.part(crown, Models.cylinder(0.26, 0.26, 0.19, 18), Color("#C98A1E"), Vector3(0, 0.08, 0))
	for k in 6:
		var a2: float = TAU * k / 6.0
		Models.part(crown, Models.cylinder(0.0, 0.08, 0.24, 6), GOLD, Vector3(sin(a2) * 0.25, 0.27, cos(a2) * 0.25), 0.2)
		Models.part(crown, Models.sphere(0.03, -1, 8), GOLD, Vector3(sin(a2) * 0.25, 0.41, cos(a2) * 0.25), 0.3)
		Models.part(crown, Models.sphere(0.045, -1, 8), GEM if k % 2 == 0 else Color("#4DD6E8"), Vector3(sin(a2) * 0.3, 0.07, cos(a2) * 0.3), 0.5)
	return root


# --- Decor ----------------------------------------------------------------------------

## A crooked little cottage with glowing windows.
static func cottage(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var lean := Node3D.new()
	lean.rotation.z = r.randf_range(-0.07, 0.07)
	lean.scale = Vector3.ONE * size
	root.add_child(lean)
	var walls: Array[Color] = [WALL_A, WALL_B, WALL_C]
	var wall: Color = walls[r.randi() % walls.size()]
	var w: float = r.randf_range(0.62, 0.78)
	var h: float = r.randf_range(0.55, 0.72)
	Models.part(lean, Models.box_mesh(Vector3(w, h, 0.6), 0.06), wall, Vector3(0, h * 0.5, 0))
	var roof := ClayShapes.extrusion(ClayShapes.rounded_polygon(PackedVector2Array([
		Vector2(-w * 0.62, 0.0), Vector2(w * 0.62, 0.0), Vector2(0.06, 0.5), Vector2(-0.02, 0.52)]), 0.04), 0.72, 0.05)
	var rf := Models.part(lean, roof, ROOF if r.randf() < 0.6 else ROOF_B, Vector3(0, h - 0.02, 0))
	rf.rotation.z = r.randf_range(-0.08, 0.08)
	Models.part(lean, Models.box_mesh(Vector3(0.12, 0.26, 0.12), 0.03), STONE_DARK, Vector3(w * 0.28, h + 0.32, -0.1))
	Models.part(lean, Models.box_mesh(Vector3(0.17, 0.26, 0.04), 0.04), DOOR, Vector3(-w * 0.18, 0.13, 0.3))
	Models.part(lean, Models.box_mesh(Vector3(0.15, 0.15, 0.04), 0.03), WINDOW, Vector3(w * 0.18, h * 0.55, 0.3), 1.0)
	if r.randf() < 0.6:
		Models.part(lean, Models.box_mesh(Vector3(0.14, 0.14, 0.04), 0.03), WINDOW, Vector3(0.0, h + 0.13, 0.25), 1.0)
	var mini := Node3D.new()
	mini.position = Vector3(w * 0.42, 0, 0.38)
	mini.scale = Vector3.ONE * 0.38
	lean.add_child(mini)
	_pumpkin_body(mini, 0.8, 0.62, 0.31)
	_face(mini, 1.0, 0.33, 0.37, 0.8)
	return root


## An autumn tree: a twisty plum trunk with round orange and violet puffs.
static func autumn_tree(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	var trunk := Models.part(root, Models.cylinder(0.07, 0.12, 0.9, 10), BARK, Vector3(0, 0.45, 0))
	trunk.rotation.z = r.randf_range(-0.12, 0.12)
	for side: int in [-1, 1]:
		var br := Models.part(root, Models.cylinder(0.035, 0.05, 0.42, 8), BARK, Vector3(side * 0.13, 0.75, 0))
		br.rotation.z = side * -0.8
	var colors: Array[Color] = [LEAF_ORANGE, LEAF_PLUM, LEAF_GOLD]
	var main: Color = colors[r.randi() % colors.size()]
	var spots: Array[Vector3] = [Vector3(0, 1.08, 0), Vector3(-0.3, 0.92, 0.05), Vector3(0.3, 0.95, -0.03), Vector3(0.05, 1.3, 0.02)]
	for k in spots.size():
		var s: float = r.randf_range(0.2, 0.28) if k > 0 else 0.33
		var c: Color = main if k % 2 == 0 else main.lerp(colors[(colors.find(main) + 1) % colors.size()], 0.5)
		Models.part(root, Models.sphere(s, s * 1.8, 14), c, spots[k])
	return root


## An iron lamp post with a warm glowing globe.
static func lamp_post(size: float) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.part(root, Models.cylinder(0.08, 0.1, 0.1, 10), IRON, Vector3(0, 0.05, 0))
	Models.part(root, Models.cylinder(0.03, 0.035, 0.95, 8), IRON, Vector3(0, 0.55, 0))
	Models.part(root, Models.sphere(0.13, 0.26, 14), LAMP, Vector3(0, 1.1, 0), 1.3)
	Models.part(root, Models.cylinder(0.02, 0.12, 0.08, 10), IRON, Vector3(0, 1.25, 0))
	return root


static func hay_bale(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.6, 0.34, 0.4), 0.08), HAY, Vector3(0, 0.17, 0))
	for k in 2:
		Models.part(root, Models.box_mesh(Vector3(0.04, 0.36, 0.42), 0.015), HAY_DARK, Vector3(-0.15 + k * 0.3, 0.17, 0))
	var mini := Node3D.new()
	mini.position = Vector3(r.randf_range(-0.12, 0.12), 0.34, 0)
	mini.scale = Vector3.ONE * 0.36
	root.add_child(mini)
	_pumpkin_body(mini, 0.8, 0.62, 0.31)
	return root


## A little patch of pumpkins, some with tiny faces.
static func pumpkin_patch(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var n: int = r.randi_range(1, 3)
	for k in n:
		var p := Node3D.new()
		p.position = Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
		p.scale = Vector3.ONE * r.randf_range(0.32, 0.5)
		p.rotation.y = r.randf_range(-0.5, 0.5)
		root.add_child(p)
		_pumpkin_body(p, 0.8, 0.62, 0.31)
		Models.part(p, Models.cylinder(0.045, 0.065, 0.2, 8), STEM, Vector3(0, 0.66, 0))
		if r.randf() < 0.5:
			_face(p, 1.0, 0.33, 0.37, 0.8)
	return root


## A gravestone-free friendly tower for the far islands: a round witch's
## tower with a pointed hat roof and lit windows.
static func witch_tower(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.part(root, Models.cylinder(0.32, 0.38, 1.3, 16), WALL_A, Vector3(0, 0.65, 0))
	var hat := Models.part(root, Models.cylinder(0.0, 0.5, 0.9, 16), ROOF, Vector3(0, 1.75, 0))
	hat.rotation.z = 0.12
	Models.part(root, Models.cylinder(0.56, 0.56, 0.05, 18), ROOF, Vector3(0, 1.3, 0))
	Models.part(root, Models.cylinder(0.5, 0.5, 0.07, 18), LAMP, Vector3(0, 1.36, 0), 0.4)
	for k in 3:
		var a: float = k * 0.9 - 0.9
		var y: float = 0.4 + k * 0.3
		var wnd := Models.part(root, Models.box_mesh(Vector3(0.12, 0.17, 0.05), 0.04), WINDOW, Vector3(sin(a) * 0.34, y, cos(a) * 0.34), 1.0)
		wnd.rotation.y = a
	var flag := Models.part(root, Models.box_mesh(Vector3(0.18, 0.1, 0.02), 0.01), LEAF_ORANGE, Vector3(0.12, 2.15, 0))
	flag.rotation.z = -0.2
	return root


## A cartoon bat: round body, two wing panels named "WingL"/"WingR".
static func bat() -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.sphere(0.12, 0.22, 12), BAT, Vector3.ZERO)
	for side: int in [-1, 1]:
		var ear := Models.part(root, Models.cylinder(0.0, 0.04, 0.08, 6), BAT, Vector3(side * 0.05, 0.12, 0.02))
		ear.rotation.z = side * -0.2
		var eye := Models.part(root, Models.sphere(0.025, -1, 8), LAMP, Vector3(side * 0.045, 0.03, 0.1), 1.0)
		eye.scale = Vector3(1, 1, 0.6)
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		root.add_child(wing)
		var panel := ClayShapes.extrusion(ClayShapes.rounded_polygon(PackedVector2Array([
			Vector2(0.0, -0.04), Vector2(0.1, -0.05), Vector2(0.18, 0.0), Vector2(0.26, -0.02), Vector2(0.3, 0.08), Vector2(0.0, 0.04)]), 0.012), 0.02, 0.008)
		var p := Models.part(wing, panel, BAT, Vector3.ZERO)
		p.rotation.x = PI * 0.5
		if side < 0:
			p.scale = Vector3(-1, 1, 1)
	return root

extends WorldKit
## World 3, Cocoa Canyon: violet floors between cocoa-and-sandstone walls,
## crystals everywhere. Its own rules:
##   m  mud: glossy chocolate puddles that slow Pip (and walking critters).
##   x  cracked tile: holds while Pip stands on it, then shakes, glows and
##      crumbles into a pit a moment after he steps off. Pits stop walkers
##      and pods but blasts fly straight over them. A tile never crumbles
##      if that would cut Pip off from the exit or a critter: it groans and
##      holds instead, so every level stays solvable.
##   o  Mole: wanders, then dives underground (safe from blasts, shown as a
##      moving dirt mound) and pops up a few tiles away. Blast it while up.
## The boss, Baron Burrow, drills underground after every hit and pops up
## somewhere far from Pip.

const M3 = preload("res://worlds/world_3_models.gd")

## Where a critter's logical cell is parked while it is underground: off the
## grid, so blasts and Pip can't touch it there.
const UNDER := Vector2i(-60, -60)
const MUD_SCALE: float = 0.55
const CRITTER_MUD_SCALE: float = 0.6
const WARN_TIME: float = 0.85
const HIDDEN := Transform3D(Basis(Vector3(0.0001, 0, 0), Vector3(0, 0.0001, 0), Vector3(0, 0, 0.0001)), Vector3(0, -6, 0))

## Crack patterns: polylines in tile space (x, z in -0.5..0.5), 4 segments each.
const CRACKS: Array = [
	[[Vector2(-0.34, -0.22), Vector2(-0.08, -0.06)], [Vector2(-0.08, -0.06), Vector2(0.06, 0.13)], [Vector2(0.06, 0.13), Vector2(0.33, 0.24)], [Vector2(-0.08, -0.06), Vector2(0.14, -0.28)]],
	[[Vector2(-0.3, 0.3), Vector2(-0.12, 0.04)], [Vector2(-0.12, 0.04), Vector2(0.12, -0.02)], [Vector2(0.12, -0.02), Vector2(0.28, -0.3)], [Vector2(0.12, -0.02), Vector2(0.32, 0.16)]],
	[[Vector2(-0.36, 0.02), Vector2(-0.1, 0.1)], [Vector2(-0.1, 0.1), Vector2(0.1, -0.08)], [Vector2(0.1, -0.08), Vector2(0.34, -0.02)], [Vector2(-0.1, 0.1), Vector2(-0.02, 0.34)]],
]

const LEVELS: Array[Dictionary] = [
	{
		"name": "Cocoa Crossing",
		"tip": "Gooey mud slows you down.\nCracked tiles crumble after you step off!",
		"crates": 0.4, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#x#x#.#.#",
			"#..b.xxx..b.#",
			"#.#.#x#x#.#.#",
			"#mmm.....mmm#",
			"#m#m#.#.#m#m#",
			"#mmm..b..mmm#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crumble Pass",
		"tip": "The pass is cracked all the way across.\nPlan your way over: it won't be there twice!",
		"crates": 0.45, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..z..E.....#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#xxxxx.xxxxx#",
			"#x#x#x#x#x#x#",
			"#xxxxx.xxxxx#",
			"#.#.#.#.#.#.#",
			"#mm...b...mm#",
			"#m#.#.#.#.#m#",
			"#mm......b.m#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Mole Hollow",
		"tip": "Moles dive and pop up nearby.\nBlast them while they're above ground!",
		"crates": 0.35, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..o.....o..#",
			"#.#m#.#.#m#.#",
			"#.mmm...mmm.#",
			"#.#m#.#.#m#.#",
			"#.....o.....#",
			"#.#.#x#x#.#.#",
			"#...xx_xx...#",
			"#.#.#x#x#.#.#",
			"#..b.....b..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Conveyor Quarry",
		"tip": "Quarry belts carry pods round the mud.\nBarrels make a big bang!",
		"crates": 0.35, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..B..E..B.z#",
			"#.#.#.#.#.#.#",
			"#.o>>>>>>v..#",
			"#.#^#.#.#v#.#",
			"#mm^..B..vmm#",
			"#m#^#.#.#v#m#",
			"#mm^..o..vmm#",
			"#.#^#.#.#v#.#",
			"#..^<<<<<<..#",
			"#.#.#x#x#.#.#",
			"#...xx.xx.o.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crystal Warps",
		"tip": "Swirl pads warp you across the canyon.\nWisps float over pits!",
		"crates": 0.4, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1....E....2#",
			"#.#.#.#.#.#.#",
			"#..xxxwxxx..#",
			"#.#x#.#.#x#.#",
			"#.ox.....xo.#",
			"###x#.#.#x###",
			"#2.x..b..x.1#",
			"###.#.#.#.###",
			"#mmm.....mmm#",
			"#.#m#.#.#m#.#",
			"#.o.......w.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Baron Burrow's Den",
		"tip": "Baron Burrow drills away after every hit.\nWatch his mound and blast him six times!",
		"crates": 0.25, "par": 130, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...mm.mm...#",
			"#...#...#...#",
			"#.x...K...x.#",
			"#.x.......x.#",
			"#...mm_mm...#",
			"#...#...#...#",
			"#.#.......#.#",
			"#..xx...xx..#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

var _mud: Dictionary = {}       # Vector2i -> bubble instance index
var _cracks: Dictionary = {}    # Vector2i -> {state, t, i, jig}
var _pits: Dictionary = {}      # Vector2i -> true
var _last_cell := Vector2i(-99, -99)
var _clock: float = 0.0
var _splash_t: float = 0.0
## Per-critter burrow state: Critter -> {state, t, timer, cell, from, to, dur, trail}
var _burrow: Dictionary = {}
var _base_speed: Dictionary = {}
var _boss_hp: int = -1

var _slab_mm: MultiMesh
var _line_mm: MultiMesh
var _hot_mm: MultiMesh
var _pit_mm: MultiMesh
var _pit_wall_mm: MultiMesh
var _pit_glow_mm: MultiMesh
var _bubble_mm: MultiMesh
var _crack_tf: Dictionary = {}  # Vector2i -> Array[Transform3D] (slab, then lines)
var _bubble_cells: Array[Vector2i] = []
var _chunk_mesh: Mesh
var _mud_mat: Material
var _crumb_mesh: Mesh


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Cocoa Canyon"


func palette() -> Variant:
	var p: Dictionary = (Models.PALETTES["plum_cocoa"] as Dictionary).duplicate()
	p.merge({
		"GRASS_A": "#5E4280", "GRASS_B": "#523873", "RIM": "#4B3468", "EDGE": "#6E4532",
		"STONE": "#D9A57A", "DARK_STONE": "#B07650", "DIRT": "#5A3726", "ROCK": "#3E2A40",
		"WOOD": "#FF8FB8", "WOOD_DARK": "#FFE3EE",
		"SKY_TOP": "#2E1F55", "SKY_HORIZON": "#E79A7E", "SKY_GROUND": "#2E2048",
		"CLOUD": "#8E6AA8", "CLOUDS": 0.4, "SUN": "#FFD9B4", "SUN_ENERGY": 1.4,
		"AMBIENT": "#A08AD0", "AMBIENT_ENERGY": 0.62,
	}, true)
	return p


func music() -> String:
	return "res://audio/music/world_3.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "BARON BURROW"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"m":
			_mud[c] = 0
			return true
		"x":
			_cracks[c] = {"state": &"intact", "t": 0.0, "i": _cracks.size(), "jig": 0.0}
			return true
	return false


func critter_chars() -> Dictionary:
	return {"o": &"mole"}


func _mm(mesh: Mesh, material: Material, transforms: Array[Transform3D], shadow: bool = true) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	return mm


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Little violet crystal clusters and stacked sandstone caps on the border.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 31
	var top: float = 0.685
	var crystals: Array = [[], [], []]
	var slabs_a: Array[Transform3D] = []
	var slabs_b: Array[Transform3D] = []
	for tf in blocks:
		var base: Vector3 = tf.origin
		var roll: float = r.randf()
		if roll < 0.42:
			var n: int = r.randi_range(2, 3)
			var spin: float = r.randf() * TAU
			for k in n:
				var a: float = spin + TAU * k / n
				var off := Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else 0.15)
				var h: float = r.randf_range(0.32, 0.48) if k == 0 else r.randf_range(0.18, 0.3)
				var rad: float = 0.12 if k == 0 else 0.085
				var tilt := Basis(Vector3.UP, r.randf() * TAU)
				if k > 0:
					tilt = Basis(Vector3(-sin(a), 0, cos(a)), -0.45) * tilt
				var b := tilt * Basis.from_scale(Vector3(rad * 2.0, h, rad * 2.0))
				(crystals[(k + r.randi()) % 3] as Array).append(Transform3D(b, Vector3(base.x, top - 0.02, base.z) + off))
		elif roll < 0.62:
			# A couple of round cocoa pebbles, tipped this way and that.
			var a0: float = r.randf() * TAU
			var tip := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.25, 0.25))
			slabs_a.append(Transform3D(tip, Vector3(base.x + cos(a0) * 0.1, top + 0.08, base.z + sin(a0) * 0.1)))
			if r.randf() < 0.7:
				var tip2 := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.FORWARD, r.randf_range(-0.3, 0.3))
				slabs_b.append(Transform3D(tip2, Vector3(base.x - cos(a0) * 0.18, top + 0.05, base.z - sin(a0) * 0.18)))
	var colors: Array[Color] = [M3.CRYSTAL_A, M3.CRYSTAL_B, M3.CRYSTAL_DEEP]
	for i in 3:
		var list: Array[Transform3D] = []
		list.assign(crystals[i])
		_mm(M3.crystal_mesh(), Models.mat(colors[i], 0.4), list)
	_mm(Models.box_mesh(Vector3(0.3, 0.2, 0.26), 0.085), Models.mat(M3.COCOA.lightened(0.08)), slabs_a)
	_mm(Models.box_mesh(Vector3(0.18, 0.12, 0.16), 0.05), Models.mat(M3.CARAMEL), slabs_b)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Layered sandstone mesas: cocoa, caramel and sand strata, each a little
	# turned so the layers read; some carry a crystal cluster.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 37
	var l1: Array[Transform3D] = []
	var l2: Array[Transform3D] = []
	var l3: Array[Transform3D] = []
	var crystals: Array = [[], [], []]
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		l1.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.06, 0.06)), p + Vector3(0, 0.15, 0)))
		l2.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.16, 0.16)), p + Vector3(r.randf_range(-0.03, 0.03), 0.42, r.randf_range(-0.03, 0.03))))
		l3.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.25, 0.25)), p + Vector3(r.randf_range(-0.05, 0.05), 0.64, r.randf_range(-0.05, 0.05))))
		if r.randf() < 0.3:
			var spin: float = r.randf() * TAU
			for k in 2:
				var a: float = spin + PI * k
				var off := Vector3(cos(a), 0, sin(a)) * (0.06 if k == 0 else 0.13)
				var h: float = 0.3 if k == 0 else 0.18
				var b := Basis(Vector3(-sin(a), 0, cos(a)), -0.3 * k) * Basis(Vector3.UP, r.randf() * TAU)
				(crystals[k + (1 if r.randf() < 0.4 else 0)] as Array).append(Transform3D(b * Basis.from_scale(Vector3(0.18 - k * 0.05, h, 0.18 - k * 0.05)), p + Vector3(0, 0.73, 0) + off))
	_mm(Models.box_mesh(Vector3(0.9, 0.3, 0.9), 0.08), Models.mat(M3.COCOA), l1)
	_mm(Models.box_mesh(Vector3(0.82, 0.26, 0.8), 0.07), Models.mat(M3.CARAMEL), l2)
	_mm(Models.box_mesh(Vector3(0.7, 0.2, 0.68), 0.06), Models.mat(M3.SAND), l3)
	var colors: Array[Color] = [M3.CRYSTAL_A, M3.CRYSTAL_B, M3.CRYSTAL_DEEP]
	for i in 3:
		var list: Array[Transform3D] = []
		list.assign(crystals[i])
		if not list.is_empty():
			_mm(M3.crystal_mesh(), Models.mat(colors[i], 0.4), list)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M3.boulder(r, 0.8)
		elif roll < 0.3:
			node = M3.crystal_cluster(r, 0.8)
	else:
		if roll < 0.13:
			node = M3.mesa(r, r.randf_range(0.7, 1.3), r.randf_range(0.6, 0.8))
		elif roll < 0.26:
			node = M3.crystal_spire(r)
		elif roll < 0.42:
			node = M3.boulder(r, r.randf_range(0.9, 1.3))
		elif roll < 0.52:
			node = M3.crystal_cluster(r, 1.0)
	if node == null:
		return Node3D.new()
	node.rotation.y = r.randf() * TAU
	var holder := Node3D.new()
	node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
	holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var m := M3.mesa(r, size * 0.7, size * 0.5)
	m.position = Vector3(-size * 0.1, 0, -size * 0.08)
	root.add_child(m)
	var s := M3.crystal_spire(r)
	s.scale = Vector3.ONE * 1.4
	s.position = Vector3(size * 0.28, 0, size * 0.18)
	root.add_child(s)
	var b := M3.boulder(r, 1.2)
	b.position = Vector3(-size * 0.25, 0, size * 0.25)
	root.add_child(b)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	# A warm late-afternoon canyon light.
	sun.rotation_degrees = Vector3(-50.0, -38.0, 0.0)
	env.glow_intensity = 0.55
	env.adjustment_saturation = 1.08


func build_extra() -> void:
	_chunk_mesh = Models.box_mesh(Vector3(0.2, 0.08, 0.18), 0.025)
	_crumb_mesh = Models.box_mesh(Vector3(0.08, 0.05, 0.08), 0.018)
	_build_mud()
	_build_cracks()


func _build_mud() -> void:
	if _mud.is_empty():
		return
	var slabs: Array[Transform3D] = []
	var joins: Array[Transform3D] = []
	var bubbles: Array[Transform3D] = []
	var shines: Array[Transform3D] = []
	var r := RandomNumberGenerator.new()
	r.seed = 99
	for c: Vector2i in _mud:
		slabs.append(Transform3D(Basis(), Vector3(c.x, 0.0, c.y)))
		# Bridge neighbouring puddles so a patch reads as one pool.
		if _mud.has(c + Vector2i(1, 0)):
			joins.append(Transform3D(Basis(), Vector3(c.x + 0.5, 0.0, c.y)))
		if _mud.has(c + Vector2i(0, 1)):
			joins.append(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(c.x, 0.0, c.y + 0.5)))
		_mud[c] = _bubble_cells.size()
		_bubble_cells.append(c)
		bubbles.append(HIDDEN)
		# A glossy glint or two so it reads as wet.
		var yaw: float = r.randf_range(-0.5, 0.5)
		shines.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(c.x + r.randf_range(-0.22, 0.1), 0.03, c.y + r.randf_range(-0.25, 0.0))))
		if r.randf() < 0.5:
			shines.append(Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(0.45, 1, 1)), Vector3(c.x + r.randf_range(-0.12, 0.0), 0.03, c.y + r.randf_range(-0.12, -0.04))))
	_mud_mat = M3.mud_material()
	_mm(Models.box_mesh(Vector3(0.9, 0.05, 0.9), 0.14), _mud_mat, slabs, false)
	_mm(Models.box_mesh(Vector3(0.3, 0.05, 0.9), 0.02), _mud_mat, joins, false)
	_mm(Models.box_mesh(Vector3(0.16, 0.012, 0.06), 0.025), Models.mat(Color("#E8C6B4"), 0.35), shines, false)
	_bubble_mm = _mm(Models.box_mesh(Vector3(0.12, 0.08, 0.12), 0.035), Models.mat(M3.MUD_LIGHT.lightened(0.15)), bubbles, false)


func _build_cracks() -> void:
	if _cracks.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 53
	var slabs: Array[Transform3D] = []
	var lines: Array[Transform3D] = []
	var hidden: Array[Transform3D] = []
	var hidden_lines: Array[Transform3D] = []
	var hidden_glow: Array[Transform3D] = []
	for c: Vector2i in _cracks:
		var list: Array[Transform3D] = []
		var slab := Transform3D(Basis(Vector3.UP, r.randf_range(-0.04, 0.04)), Vector3(c.x, 0.0, c.y))
		list.append(slab)
		slabs.append(slab)
		var pattern: Array = CRACKS[r.randi() % CRACKS.size()]
		var turn: float = PI * 0.5 * r.randi_range(0, 3)
		for seg: Array in pattern:
			var a: Vector2 = (seg[0] as Vector2).rotated(turn)
			var b: Vector2 = (seg[1] as Vector2).rotated(turn)
			var d: Vector2 = b - a
			var mid: Vector2 = (a + b) * 0.5
			var basis := Basis(Vector3.UP, atan2(-d.y, d.x)) * Basis.from_scale(Vector3(d.length() + 0.03, 1.0, 1.0))
			var tf := Transform3D(basis, Vector3(c.x + mid.x, 0.045, c.y + mid.y))
			list.append(tf)
			lines.append(tf)
			hidden_lines.append(HIDDEN)
		_crack_tf[c] = list
		hidden.append(HIDDEN)
		hidden_glow.append(HIDDEN)
		hidden_glow.append(HIDDEN)
	_slab_mm = _mm(Models.box_mesh(Vector3(0.9, 0.08, 0.9), 0.03), Models.mat(Color("#C9B2DE")), slabs)
	_line_mm = _mm(Models.box_mesh(Vector3(1.0, 0.03, 0.045), 0.012), Models.mat(Color("#3A2340")), lines, false)
	_hot_mm = _mm(Models.box_mesh(Vector3(1.0, 0.035, 0.05), 0.012), Models.mat(Color("#FFB347"), 1.6), hidden_lines, false)
	_pit_mm = _mm(Models.box_mesh(Vector3(0.94, 0.05, 0.94), 0.04), Models.mat(Color("#170C24")), hidden, false)
	_pit_wall_mm = _mm(Models.box_mesh(Vector3(0.94, 0.06, 0.26), 0.03), Models.mat(Color("#4A2C3E")), hidden.duplicate(), false)
	_pit_glow_mm = _mm(M3.crystal_mesh(), Models.mat(M3.CRYSTAL_A, 1.2), hidden_glow, false)


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return _pits.has(c)


func hero_speed_scale(c: Vector2i) -> float:
	return MUD_SCALE if _mud.has(c) else 1.0


func on_hero_enter(c: Vector2i) -> void:
	var prev: Vector2i = _last_cell
	_last_cell = c
	if _cracks.has(prev) and _cracks[prev]["state"] == &"intact":
		_cracks[prev]["state"] = &"warn"
		_cracks[prev]["t"] = WARN_TIME
		Sfx.play(&"kick", 0.1)
	if _cracks.has(c) and _cracks[c]["state"] == &"intact":
		_cracks[c]["jig"] = 0.3


func _flies(cr: Arena.Critter) -> bool:
	return cr.kind == &"buzzer" or cr.kind == &"wisp"


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if _pits.has(c) and not _flies(cr):
		return false
	if _burrow.has(cr):
		var b: Dictionary = _burrow[cr]
		if b["state"] != &"up" or float(b["timer"]) <= 0.0:
			return false
	return true


func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"mole":
			return M3.mole()
		&"boss":
			return M3.baron()
	return null


func critter_speed(kind: StringName) -> float:
	return 1.7 if kind == &"mole" else 1.5


func critter_hit(cr: Arena.Critter) -> bool:
	# Safe underground.
	return _burrow.has(cr) and _burrow[cr]["state"] == &"under"


func process(delta: float) -> void:
	_clock += delta
	_update_cracks(delta)
	_update_burrowers(delta)
	_update_mud(delta)


# --- Cracked tiles ------------------------------------------------------------------

func _update_cracks(delta: float) -> void:
	for c: Vector2i in _cracks:
		var st: Dictionary = _cracks[c]
		match st["state"]:
			&"intact":
				if float(st["jig"]) > 0.0:
					st["jig"] = maxf(float(st["jig"]) - delta, 0.0)
					var k: float = float(st["jig"]) / 0.3
					_place_crack(c, Vector3(0, -0.012 * k, 0), sin(_clock * 40.0) * 0.02 * k, false)
			&"warn":
				st["t"] = float(st["t"]) - delta
				var u: float = clampf(1.0 - float(st["t"]) / WARN_TIME, 0.0, 1.0)
				var amp: float = 0.012 + u * 0.035
				var j := Vector3(sin(_clock * 53.0) * amp, -u * 0.02, cos(_clock * 47.0) * amp)
				_place_crack(c, j, sin(_clock * 31.0) * 0.05 * u, true)
				if fmod(_clock, 0.22) < delta and arena._fx.size() < 220:
					_dust(Vector3(c.x + randf_range(-0.35, 0.35), 0.06, c.y + randf_range(-0.35, 0.35)), Color("#E2D4EE"), 0.5)
				if float(st["t"]) <= 0.0 and not _crack_occupied(c):
					if _safe_to_crumble(c):
						_crumble(c)
					else:
						# Crumbling here would strand Pip: it groans and holds.
						st["state"] = &"intact"
						st["jig"] = 0.3
						_place_crack(c, Vector3.ZERO, 0.0, false)


func _place_crack(c: Vector2i, offset: Vector3, tilt: float, hot: bool) -> void:
	var list: Array = _crack_tf[c]
	var i: int = int(_cracks[c]["i"])
	var pivot := Vector3(c.x, 0.0, c.y)
	var rot := Basis(Vector3(1, 0, 1).normalized(), tilt)
	for k in list.size():
		var tf: Transform3D = list[k]
		var moved := Transform3D(rot * tf.basis, pivot + rot * (tf.origin - pivot) + offset)
		if k == 0:
			_slab_mm.set_instance_transform(i, moved)
		else:
			_line_mm.set_instance_transform(i * 4 + k - 1, moved)
			if hot:
				var glow := moved.translated(Vector3(0, 0.004, 0))
				_hot_mm.set_instance_transform(i * 4 + k - 1, glow)
			else:
				_hot_mm.set_instance_transform(i * 4 + k - 1, HIDDEN)


## Someone is on the tile: Pip, a pod or the boss. It waits for them.
func _crack_occupied(c: Vector2i) -> bool:
	if arena.pod_at.has(c):
		return true
	if arena.hero != null and arena.hero_alive:
		if absf(arena.hero_pos.x - c.x) < 0.8 and absf(arena.hero_pos.y - c.y) < 0.8:
			return true
	if arena.boss != null and arena.boss.pos.distance_to(Vector2(c)) < 0.9:
		return true
	return false


## True when Pip could still reach the exit and every walking critter (going
## through crates, which he can blast) with [param c] gone.
func _safe_to_crumble(c: Vector2i) -> bool:
	if arena.hero == null:
		return true
	var start: Vector2i = arena.hero_cell()
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = at + d
			if seen.has(n) or n == c or _pits.has(n) or arena.tile(n) == Arena.WALL:
				continue
			seen[n] = true
			queue.append(n)
			if arena.warps.has(n) and not seen.has(arena.warps[n]):
				seen[arena.warps[n]] = true
				queue.append(arena.warps[n])
	var goals: Array[Vector2i] = []
	if arena.exit_cell.x >= 0:
		goals.append(arena.exit_cell)
	for cr: Arena.Critter in arena.critters:
		if _flies(cr):
			continue
		var at: Vector2i = Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		if _burrow.has(cr) and _burrow[cr]["state"] == &"under":
			at = _burrow[cr]["to"]
		if at == c:
			continue  # it falls in
		goals.append(at)
	for g: Vector2i in goals:
		if not seen.has(g):
			return false
	return _escape_ok(c, start, goals)


## When Pip would have to blast his way out of the open floor left to him,
## that floor must hold a spot to drop a pod by a crate and a spot out of
## its blast to hide in; otherwise the tile would trap him.
func _escape_ok(c: Vector2i, start: Vector2i, goals: Array[Vector2i]) -> bool:
	var open: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = at + d
			if open.has(n) or n == c or _pits.has(n) or arena.tile(n) != Arena.FLOOR:
				continue
			open[n] = true
			queue.append(n)
			if arena.warps.has(n) and not open.has(arena.warps[n]):
				open[arena.warps[n]] = true
				queue.append(arena.warps[n])
	var shut: bool = false
	for g: Vector2i in goals:
		if not open.has(g):
			shut = true
			break
	if not shut:
		return true
	for p: Vector2i in open:
		var by_crate: bool = false
		for d: Vector2i in Arena.DIRS:
			var t: int = arena.tile(p + d)
			if t == Arena.CRATE or t == Arena.BARREL:
				by_crate = true
		if not by_crate:
			continue
		var cross: Dictionary = {p: true}
		for d: Vector2i in Arena.DIRS:
			for i in range(1, arena.fire + 1):
				var cc: Vector2i = p + d * i
				if arena.tile(cc) != Arena.FLOOR:
					break
				cross[cc] = true
		for q: Vector2i in open:
			if not cross.has(q):
				return true
	return false


func _crumble(c: Vector2i) -> void:
	var st: Dictionary = _cracks[c]
	st["state"] = &"gone"
	_pits[c] = true
	var i: int = int(st["i"])
	_slab_mm.set_instance_transform(i, HIDDEN)
	for k in 4:
		_line_mm.set_instance_transform(i * 4 + k, HIDDEN)
		_hot_mm.set_instance_transform(i * 4 + k, HIDDEN)
	var p := Vector3(c.x, 0.0, c.y)
	_pit_mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, -0.005, 0)))
	_pit_wall_mm.set_instance_transform(i, Transform3D(Basis(), p + Vector3(0, 0.0, -0.34)))
	var r := RandomNumberGenerator.new()
	r.seed = c.x * 31 + c.y * 17
	for k in 2:
		var off := Vector3(r.randf_range(-0.25, 0.25), 0.0, r.randf_range(-0.05, 0.28))
		var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.3, 0.3))
		_pit_glow_mm.set_instance_transform(i * 2 + k, Transform3D(b * Basis.from_scale(Vector3(0.09, 0.14 - k * 0.04, 0.09)), p + off + Vector3(0, 0.0, 0)))
	# The slab breaks into chunks that drop away, with a puff of dust.
	for k in 8:
		var a: float = TAU * k / 8.0 + randf() * 0.4
		var n := Models.part(arena, _chunk_mesh, Color("#C9B2DE") if k % 3 else Color("#9C84B8"), p + Vector3(cos(a) * 0.22, 0.04, sin(a) * 0.22))
		n.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		arena._fx.append({"node": n, "t": 0.0, "life": 0.7, "kind": &"debris",
			"vel": Vector3(cos(a) * 0.6, randf_range(1.0, 2.2), sin(a) * 0.6),
			"spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))})
	for k in 5:
		var a2: float = TAU * k / 5.0
		_dust(p + Vector3(cos(a2) * 0.3, 0.1, sin(a2) * 0.3), Color("#E2D4EE"), 0.6, Vector3(cos(a2), 0.4, sin(a2)) * 1.4)
	Sfx.play(&"crunch", 0.15)
	arena._shake = maxf(arena._shake, 0.12)
	# Whatever stood on it falls in.
	if arena.pickups.has(c):
		(arena.pickups[c]["node"] as Node3D).queue_free()
		arena.pickups.erase(c)
	for cr: Arena.Critter in arena.critters.duplicate():
		if cr.kind == &"boss" or _flies(cr):
			continue
		if _burrow.has(cr) and _burrow[cr]["state"] == &"under":
			continue
		if Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			arena._kill_critter(cr)


func _dust(at: Vector3, color: Color, life: float, vel: Vector3 = Vector3(0, 0.3, 0)) -> void:
	var d := Models.part(arena, arena._smoke_mesh, color, at)
	d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	d.rotation.y = randf() * TAU
	d.scale = Vector3.ONE * 0.6
	arena._fx.append({"node": d, "t": 0.0, "life": life, "kind": &"dust", "vel": vel})


# --- Mud ------------------------------------------------------------------------------

func _update_mud(delta: float) -> void:
	if _mud.is_empty():
		return
	# Slow bubbles that swell and pop, one per puddle, out of step.
	for idx in _bubble_cells.size():
		var c: Vector2i = _bubble_cells[idx]
		var ph: float = fposmod(_clock * 0.45 + float(c.x * 7 + c.y * 13) * 0.137, 1.0)
		var s: float = sin(ph * PI) if ph < 0.85 else 0.0
		if s < 0.05:
			_bubble_mm.set_instance_transform(idx, HIDDEN)
		else:
			var off := Vector3(sin(float(c.x * 3 + c.y)) * 0.2, 0.025, cos(float(c.x + c.y * 5)) * 0.2)
			_bubble_mm.set_instance_transform(idx, Transform3D(Basis.from_scale(Vector3(s, s * 1.2, s)), Vector3(c.x, 0, c.y) + off))
	# Walking critters wade slowly too.
	for cr: Arena.Critter in arena.critters:
		if _flies(cr):
			continue
		var base: float
		if cr.kind == &"boss":
			base = 1.0 + (Arena.BOSS_HP - cr.hp) * 0.12
		else:
			if not _base_speed.has(cr):
				_base_speed[cr] = cr.speed
			base = _base_speed[cr]
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		cr.speed = base * (CRITTER_MUD_SCALE if _mud.has(here) else 1.0)
	# Pip squelches.
	if arena.hero != null and arena.hero_moving and arena.state == &"play" and _mud.has(arena.hero_cell()):
		_splash_t -= delta
		if _splash_t <= 0.0 and arena._fx.size() < 220:
			_splash_t = 0.16
			for k in 2:
				var a: float = randf() * TAU
				var n := MeshInstance3D.new()
				n.mesh = _crumb_mesh
				n.material_override = _mud_mat
				n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				n.position = Vector3(arena.hero_pos.x + cos(a) * 0.15, 0.05, arena.hero_pos.y + sin(a) * 0.15)
				arena.add_child(n)
				arena._fx.append({"node": n, "t": 0.0, "life": 0.5, "kind": &"debris", "floor": 0.03,
					"vel": Vector3(cos(a) * 1.1, randf_range(1.6, 2.4), sin(a) * 1.1),
					"spin": Vector3(randf_range(-8, 8), randf_range(-8, 8), 0)})
	else:
		_splash_t = 0.0


# --- Burrowers: moles and Baron Burrow ---------------------------------------------

func _state(cr: Arena.Critter) -> Dictionary:
	if not _burrow.has(cr):
		var boss: bool = cr.kind == &"boss"
		_burrow[cr] = {"state": &"up", "t": 0.0, "timer": 1e9 if boss else randf_range(1.8, 3.2),
			"cell": cr.cell, "from": Vector2(cr.cell), "to": cr.cell, "dur": 1.0, "trail": 0.0}
	return _burrow[cr]


func _update_burrowers(delta: float) -> void:
	for cr: Arena.Critter in _burrow.keys():
		if not arena.critters.has(cr):
			_burrow.erase(cr)
			_base_speed.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"mole" and cr.kind != &"boss":
			continue
		var b: Dictionary = _state(cr)
		var boss: bool = cr.kind == &"boss"
		if boss:
			if _boss_hp < 0:
				_boss_hp = cr.hp
			if cr.hp < _boss_hp and cr.hp > 0 and b["state"] == &"up":
				# Hit: he drills away.
				b["state"] = &"dive"
				b["t"] = 0.0
			_boss_hp = cr.hp
		b["t"] = float(b["t"]) + delta
		match b["state"]:
			&"up":
				if not boss:
					b["timer"] = float(b["timer"]) - delta
					if float(b["timer"]) <= 0.0 and cr.t >= 1.0:
						b["state"] = &"dive"
						b["t"] = 0.0
						Sfx.play(&"place", 0.1)
			&"dive":
				var dive_time: float = 0.55 if boss else 0.4
				if fmod(float(b["t"]), 0.1) < delta:
					_dirt_bits(cr.pos, 2 if not boss else 4)
				if float(b["t"]) >= dive_time:
					var from := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
					var dest: Vector2i = _burrow_dest(from, 3 if boss else 2, 9 if boss else 4, 4 if boss else 2, boss)
					if dest == Arena.NO_CELL:
						b["state"] = &"pop"
						b["t"] = 0.0
						continue
					b["cell"] = from
					b["from"] = cr.pos
					b["to"] = dest
					b["dur"] = clampf(Vector2(dest).distance_to(cr.pos) / (4.0 if boss else 2.6), 0.9, 2.0)
					b["state"] = &"under"
					b["t"] = 0.0
					cr.cell = UNDER
					cr.target = UNDER
					cr.t = 1.0
					if boss:
						Sfx.play(&"whoosh", 0.0)
			&"under":
				var u: float = float(b["t"]) / float(b["dur"])
				b["trail"] = float(b["trail"]) - delta
				if float(b["trail"]) <= 0.0:
					b["trail"] = 0.12
					_dirt_bits(_under_pos(b), 1 if not boss else 2)
				if u >= 1.0:
					var to: Vector2i = b["to"]
					if not _pop_ok(to, cr, 2 if boss else 1):
						# Someone is standing there: tunnel on a little.
						var again: Vector2i = _burrow_dest(to, 1, 4, 2 if boss else 1, boss)
						b["from"] = Vector2(to)
						b["t"] = 0.0
						if again != Arena.NO_CELL:
							b["to"] = again
							b["dur"] = 0.6
						continue
					cr.cell = to
					cr.target = to
					cr.t = 1.0
					cr.pos = Vector2(to)
					b["state"] = &"pop"
					b["t"] = 0.0
					Sfx.play(&"pop", 0.1)
					_dirt_bits(Vector2(to), 8 if boss else 5)
					if boss:
						arena._shake = maxf(arena._shake, 0.25)
						arena._spawn_ring(Vector3(to.x, 0.06, to.y), M3.SAND_LIGHT, 1.4)
			&"pop":
				if float(b["t"]) >= (0.5 if boss else 0.35):
					b["state"] = &"up"
					b["t"] = 0.0
					b["timer"] = 1e9 if boss else randf_range(2.6, 4.2)


func _under_pos(b: Dictionary) -> Vector2:
	var u: float = clampf(float(b["t"]) / float(b["dur"]), 0.0, 1.0)
	u = u * u * (3.0 - 2.0 * u)
	return (b["from"] as Vector2).lerp(Vector2(b["to"]), u)


func _dirt_bits(at: Vector2, count: int) -> void:
	if arena._fx.size() > 230:
		return
	for k in count:
		var a: float = randf() * TAU
		var n := Models.part(arena, _crumb_mesh, M3.DIRT_A if k % 2 else M3.DIRT_B, Vector3(at.x + cos(a) * 0.2, 0.06, at.y + sin(a) * 0.2))
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena._fx.append({"node": n, "t": 0.0, "life": 0.55, "kind": &"debris", "floor": 0.03,
			"vel": Vector3(cos(a) * 1.2, randf_range(2.0, 3.2), sin(a) * 1.2),
			"spin": Vector3(randf_range(-9, 9), randf_range(-9, 9), 0)})


## A tile a burrower may come up on.
func _pop_ok(c: Vector2i, cr: Arena.Critter, hero_gap: int) -> bool:
	if arena.tile(c) != Arena.FLOOR or _pits.has(c) or arena.pod_at.has(c) or arena.flames.has(c):
		return false
	if arena.warps.has(c) or arena.belts.has(c) or c == arena.exit_cell:
		return false
	if arena.hero != null and arena.hero_alive:
		var h: Vector2i = arena.hero_cell()
		if absi(h.x - c.x) + absi(h.y - c.y) <= hero_gap:
			return false
	if arena._danger_cells().has(c):
		return false
	for other: Arena.Critter in arena.critters:
		if other != cr and Vector2i(roundi(other.pos.x), roundi(other.pos.y)) == c:
			return false
	return true


## Picks where a burrower comes up: a tile [param lo] to [param hi] steps
## away underground (it tunnels under crates and pits, not stone). The boss
## prefers tiles far from Pip.
func _burrow_dest(from: Vector2i, lo: int, hi: int, hero_gap: int, far: bool) -> Vector2i:
	var dist: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	var options: Array[Vector2i] = []
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var dc: int = dist[c]
		if dc >= lo and _pop_ok(c, null, hero_gap):
			options.append(c)
		if dc >= hi:
			continue
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = c + d
			if dist.has(n) or n.x < 1 or n.y < 1 or n.x > Arena.W - 2 or n.y > Arena.H - 2:
				continue
			if arena.tile(n) == Arena.WALL:
				continue
			dist[n] = dc + 1
			queue.append(n)
	if options.is_empty():
		return Arena.NO_CELL
	if far and arena.hero != null:
		var h: Vector2 = arena.hero_pos
		options.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).distance_to(h) > Vector2(b).distance_to(h))
		return options[randi() % mini(4, options.size())]
	return options[randi() % options.size()]


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	var boss: bool = cr.kind == &"boss"
	var b: Dictionary = _state(cr)
	var n: Node3D = cr.node
	var mound: Node3D = n.get_node("Mound")
	var shadow: Node3D = n.get_node_or_null("Shadow")
	var k: float = float(b["t"])
	var rest := Vector3.ONE
	if boss:
		var drill: Node3D = body.get_node("Drill")
		drill.rotation.z += _delta * (26.0 if b["state"] != &"up" else 9.0)
	match b["state"]:
		&"up":
			body.visible = body.visible if boss else true
			body.rotation.y = lerpf(body.rotation.y, 0.0, 0.2)
			mound.visible = false
			if shadow:
				shadow.visible = true
			body.position.y = absf(sin(t * (6.0 if boss else 10.0))) * (0.05 if boss else 0.04)
			body.rotation.z = sin(t * 5.0) * 0.06
			rest = Vector3(1.0, 1.0 + sin(t * 8.0) * 0.04, 1.0)
		&"dive":
			var dive_time: float = 0.55 if boss else 0.4
			var u: float = clampf(k / dive_time, 0.0, 1.0)
			body.visible = true
			body.position.y = 0.12 * sin(u * PI) - (1.5 if boss else 0.75) * u * u
			body.rotation.y += _delta * 18.0
			mound.visible = true
			mound.scale = Vector3.ONE * maxf(u, 0.05)
			if shadow:
				shadow.visible = u < 0.6
		&"under":
			var at: Vector2 = _under_pos(b)
			n.position = Vector3(at.x, 0, at.y)
			body.visible = false
			if shadow:
				shadow.visible = false
			mound.visible = true
			var wob: float = sin(t * 18.0) * 0.08
			mound.scale = Vector3(1.0 + wob, 1.0 - wob, 1.0 + wob)
			mound.rotation.y = sin(t * 7.0) * 0.2
		&"pop":
			var pop_time: float = 0.5 if boss else 0.35
			var u2: float = clampf(k / pop_time, 0.0, 1.0)
			body.visible = true
			body.rotation.y = lerpf(body.rotation.y, 0.0, 0.3)
			body.position.y = lerpf(-(1.5 if boss else 0.7), 0.0, u2) + sin(u2 * PI) * (0.35 if boss else 0.25)
			mound.visible = u2 < 0.9
			mound.scale = Vector3.ONE * maxf(1.0 - u2, 0.05)
			if shadow:
				shadow.visible = true
			rest = Vector3(0.85, 1.25, 0.85)
	return rest

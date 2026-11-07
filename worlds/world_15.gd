extends WorldKit
## World 15, Origami Valley: a valley folded from crisp
## paper. The twist is fold lines. Some patches of the board are paper
## panels (a cream sheet with crease lines, its border in the panel's
## colour); blasting one of the panel's fold markers (a paper pinwheel block
## of the same colour) flips the whole panel over its centre crease like a
## page. Everything on it is mirrored: walls, crates, pods, power-ups,
## critters and Pip himself, so a route on one side opens while the other
## closes. Things only ever move with the paper under them, so a fold never
## crushes or traps Pip. Paper Cranes glide in long straight lines and swoop
## at Pip when he is in line; Paper Frogs hop two tiles at a time (and clear
## blasts mid-hop). The Origami Dragon starts folding the panels itself once
## hurt, and near the end folds fresh paper blocks into the valley.
##
## Extra map characters:
##   F  fold marker (which panel it flips is set in the level's "folds")
##   n  Paper Crane          g  Paper Frog
## Level key "folds": a list of {"r": [x0, z0, x1, z1], "ax": "x" or "z",
## "m": [[x, z], ...]}: the panel's rectangle, whether it mirrors left-right
## ("x") or top-bottom ("z"), and its markers. Panels never cover the start,
## the exit, markers, barrels, belts or warps (tools check this).

const M := preload("res://worlds/world_15_models.gd")

const FOLD_TIME: float = 0.75
const FOLD_COOLDOWN: float = 0.85
const SHEET_Y: float = 0.02
const FROG_SPEED: float = 1.7
const FROG_REST: float = 0.38
## The dragon starts folding panels at this many hits left...
const BOSS_FOLD_HP: int = 7
## ...and folds new paper blocks into the valley from here on.
const BOSS_BLOCK_HP: int = 4
const BOSS_FOLD_EVERY: float = 7.0
const BOSS_WARN: float = 1.4
const BOSS_BLOCK_EVERY: float = 8.5
const PAPER_BLOCKS: int = 12

const PALETTE: Dictionary = {
	"GRASS_A": "#CDE8B6", "GRASS_B": "#BCDDA2", "RIM": "#A9D48C", "EDGE": "#6F92DA",
	"STONE": "#F6F1E7", "DARK_STONE": "#7FA6E8", "DIRT": "#E9D7BC", "ROCK": "#C9B79E",
	"WOOD": "#C5A6F7", "WOOD_DARK": "#8C6BDE", "BARREL": "#FF9A5C", "BELT": "#5D6A8C", "ACCENT": "#FFC94D",
	"BLOSSOM_A": "#FF9EBF", "BLOSSOM_B": "#FF7FA8", "TRUNK": "#C08A5A", "LEAFY_A": "#7FD08A", "LEAFY_B": "#5FBF77",
	"SKY_TOP": "#8CC9F2", "SKY_HORIZON": "#FFF0DC", "SKY_GROUND": "#F5E6CF", "CLOUD": "#FFFFFF", "CLOUDS": 0.6,
	"AMBIENT": "#E4DCCB", "AMBIENT_ENERGY": 0.58, "SUN": "#FFF4E4", "SUN_ENERGY": 1.45,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "First Fold",
		"tip": "Blast the pinwheel to fold\nthe paper strip over its crease!\nThe gap in the wall flips sides.",
		"crates": 0.38, "par": 75,
		"drops": {"bomb": 2, "fire": 1, "speed": 1},
		"folds": [{"r": [2, 7, 10, 7], "ax": "x", "m": [[1, 7], [11, 7]]}],
		"map": [
			"#############",
			"#.b...#..E..#",
			"#.#.#.#.#.#.#",
			"#__n__#.....#",
			"#.#.#.#.#.#.#",
			"#.....#..b..#",
			"#.#.#.#.#.#.#",
			"#F#.#######F#",
			"#.#.#.#.#.#.#",
			"#..b.....b..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crane Lines",
		"tip": "Paper Cranes glide in long\nstraight lines and swoop when\nyou line up. Fold two strips!",
		"crates": 0.4, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"folds": [{"r": [2, 5, 10, 5], "ax": "x", "m": [[1, 5], [11, 5]]}, {"r": [2, 9, 10, 9], "ax": "x", "m": [[1, 9], [11, 9]]}],
		"map": [
			"#############",
			"#._n_.E._n_.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#F#######.#F#",
			"#.#.#.#.#.#.#",
			"#..b..#..z..#",
			"#.#.#.#.#.#.#",
			"#F#.#######F#",
			"#.#.#.#.#.#.#",
			"#._n_....b..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Frog Hop",
		"tip": "Paper Frogs hop two tiles\nand sail over blasts mid-air.\nTime your pods for the landing!",
		"crates": 0.4, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"folds": [{"r": [4, 2, 4, 10], "ax": "z", "m": [[4, 1], [4, 13]]}, {"r": [8, 4, 8, 12], "ax": "z", "m": [[8, 1], [8, 13]]}],
		"map": [
			"#############",
			"#.E.F...F_n_#",
			"#.#.#.#.#.#.#",
			"#.g.#...#...#",
			"#.#.#.#.#.#.#",
			"#...#.g.#..g#",
			"#####.#.#.#.#",
			"#.b.#.b.#...#",
			"#.#.#.#.#####",
			"#.....g.#.b.#",
			"#.#.#.#.#.#.#",
			"#.g.#......_#",
			"#.#.#_#_#.#n#",
			"#...F_S_F...#",
			"#############",
		],
	},
	{
		"name": "Crease Maze",
		"tip": "The middle panel turns the\npath round. Fold, cross, then\nfold back from the other side!",
		"crates": 0.36, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"folds": [{"r": [4, 5, 8, 9], "ax": "x", "m": [[6, 1], [6, 13]]}],
		"map": [
			"#############",
			"#.b...F..E_n#",
			"#.#.#.#.#.#.#",
			"#._n_.#..g..#",
			"#.#.#.#.#.#.#",
			"#.#####.#####",
			"#.#####.#####",
			"#.##...######",
			"#.###.#######",
			"#.###.#######",
			"#.#.#.#.#.#.#",
			"#.gB.z#....b#",
			"#.#.#.#.#_#.#",
			"#..b..F._S_.#",
			"#############",
		],
	},
	{
		"name": "Warp and Weft",
		"tip": "Warps skip across the valley,\nbut only a fold opens the way\nto the exit. Mind the barrels!",
		"crates": 0.42, "par": 110,
		"drops": {"bomb": 3, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"folds": [{"r": [2, 7, 10, 7], "ax": "x", "m": [[1, 7], [11, 7]]}],
		"map": [
			"#############",
			"#_n_..#...E.#",
			"#.#.#.#.#.#.#",
			"#.1.g.#.z...#",
			"#.#.#.#.#.#.#",
			"#..b..#.B.g.#",
			"#.#.#.#.#.#.#",
			"#F#.#######F#",
			"#.#.#.#.#.#.#",
			"#.b...#._n_.#",
			"#.#.#.#.#.#.#",
			"#.B...#.z.1.#",
			"#_#_#.#.#.#.#",
			"#._S_.#..b..#",
			"#############",
		],
	},
	{
		"name": "The Paper Dragon",
		"tip": "The Origami Dragon folds the\nvalley when hurt. Watch for the\nshaking panel, then strike!",
		"crates": 0.18, "par": 140,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"folds": [{"r": [1, 4, 3, 10], "ax": "z", "m": [[2, 3], [2, 11]]}, {"r": [9, 4, 11, 10], "ax": "z", "m": [[10, 3], [10, 11]]}],
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.F.......F.#",
			"#.#.#.#.#.#.#",
			"####........#",
			"#.#.#.#.#.#.#",
			"#.....K.....#",
			"#.#.#.#.#.#.#",
			"#........####",
			"#.#.#.#.#.#.#",
			"#.F.......F.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

var folds: Array[Dictionary] = []
var marker_fold: Dictionary = {}    # Vector2i -> fold index
var _markers: Dictionary = {}       # Vector2i -> {"node", "spin"}
var _wall_slot: Dictionary = {}     # Vector2i -> instance index in the wall multimeshes
var _wall_parts: Array = []         # [MultiMesh, Transform3D local] per wall piece
var _anims: Array[Dictionary] = []
var _queue: Array[int] = []
var _frogs: Dictionary = {}         # Critter -> {"tgt": Vector2i, "hop": bool}
var _held: Dictionary = {}          # Critter -> cell it is held on during a fold
var _hero_hold: Vector2i = Arena.NO_CELL
var _boss_fold_t: float = 3.0
var _boss_block_t: float = 2.0
var _warn_fold: int = -1
var _warn_t: float = 0.0
var _paper_mm: MultiMesh
var _paper_band_mm: MultiMesh
var _paper_slots: Dictionary = {}   # Vector2i -> slot
var _paper_grow: Dictionary = {}    # slot -> seconds since it appeared
var _player: AudioStreamPlayer
var _snd_fold: AudioStreamWAV
var _snd_warn: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Origami Valley"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_15.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "ORIGAMI DRAGON"


func boss_hp() -> int:
	return 10


func boss_minion_kind() -> StringName:
	# Cranes first; frogs once the dragon is down to half.
	if arena != null and arena.boss != null and arena.boss.hp * 2 <= arena.boss_max_hp:
		return &"frog"
	return &"crane"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "F":
		_markers[c] = {"spin": 0.0, "bump": 0.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"n": &"crane", "g": &"frog"}


func build_extra() -> void:
	var specs: Array = arena.data.get("folds", [])
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var r: Array = spec["r"]
		var f := {
			"x0": int(r[0]), "z0": int(r[1]), "x1": int(r[2]), "z1": int(r[3]),
			"ax": String(spec["ax"]), "angle": 0.0, "cool": 0.0,
			"color": M.FOLD_COLORS[i % M.FOLD_COLORS.size()],
		}
		folds.append(f)
		for m: Array in spec["m"]:
			marker_fold[Vector2i(int(m[0]), int(m[1]))] = i
		_build_sheet(f)
	for c: Vector2i in _markers:
		var color: Color = M.PAPER
		if marker_fold.has(c):
			color = folds[int(marker_fold[c])]["color"]
		var n: Node3D = M.marker(color)
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		_markers[c]["node"] = n
	if arena.boss != null:
		_build_paper_blocks()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	arena.add_child(_player)
	_snd_fold = _make_fold()
	_snd_warn = _make_warn()


func _cells(f: Dictionary) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for z in range(int(f["z0"]), int(f["z1"]) + 1):
		for x in range(int(f["x0"]), int(f["x1"]) + 1):
			out.append(Vector2i(x, z))
	return out


func _inside(f: Dictionary, c: Vector2i) -> bool:
	return c.x >= int(f["x0"]) and c.x <= int(f["x1"]) and c.y >= int(f["z0"]) and c.y <= int(f["z1"])


func _mirror(f: Dictionary, c: Vector2i) -> Vector2i:
	if f["ax"] == "x":
		return Vector2i(int(f["x0"]) + int(f["x1"]) - c.x, c.y)
	return Vector2i(c.x, int(f["z0"]) + int(f["z1"]) - c.y)


func _in_any_fold(c: Vector2i) -> bool:
	for f: Dictionary in folds:
		if _inside(f, c):
			return true
	return false


## The panel's paper: two halves hinged on the centre crease ("hinge"), each
## cream on top and the panel's colour underneath, with crease lines on both
## faces, so a folded panel shows its coloured side.
func _build_sheet(f: Dictionary) -> void:
	var x0: int = f["x0"]
	var z0: int = f["z0"]
	var x1: int = f["x1"]
	var z1: int = f["z1"]
	var mx: bool = f["ax"] == "x"
	var hinge := Node3D.new()
	hinge.position = Vector3((x0 + x1) * 0.5, SHEET_Y, (z0 + z1) * 0.5)
	arena.add_child(hinge)
	f["hinge"] = hinge
	var across: float = float(x1 - x0 + 1) if mx else float(z1 - z0 + 1)
	var along: float = float(z1 - z0 + 1) if mx else float(x1 - x0 + 1)
	var color: Color = f["color"]
	var front: Color = M.PAPER
	var back: Color = color.lerp(Color.WHITE, 0.25)
	var halves: Array[Node3D] = []
	var hw: float = across * 0.5 - 0.03
	var len: float = along - 0.06
	for side: int in [-1, 1]:
		var half := Node3D.new()
		hinge.add_child(half)
		halves.append(half)
		for face: int in [1, -1]:
			var col: Color = front if face > 0 else back
			var y: float = face * 0.009
			var slab := Models.part(half, Models.box_mesh(_size(mx, hw, 0.016, len), 0.006), col, _vec(mx, side * hw * 0.5, y, 0.0))
			slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var line_col: Color = col.darkened(0.16)
			var ly: float = face * 0.019
			# Crease lines parallel to the centre crease, on cell edges.
			for j in range(1, int(across)):
				var u: float = -across * 0.5 + j
				if absf(u) < 0.01 or signf(u) != side:
					continue
				_line(half, _size(mx, 0.03, 0.004, len), line_col, _vec(mx, u, ly, 0.0))
			# Crease lines across, on cell edges.
			for j in range(1, int(along)):
				var v: float = -along * 0.5 + j
				_line(half, _size(mx, hw, 0.004, 0.03), line_col, _vec(mx, side * hw * 0.5, ly, v))
			# A coloured border on the cream side.
			if face > 0:
				var edge: Color = color
				_line(half, _size(mx, 0.07, 0.006, len), edge, _vec(mx, side * (hw - 0.035), ly, 0.0))
				for s2: int in [-1, 1]:
					_line(half, _size(mx, hw, 0.006, 0.07), edge, _vec(mx, side * hw * 0.5, ly, s2 * (len * 0.5 - 0.035)))
			else:
				# A cream border round the coloured side.
				_line(half, _size(mx, 0.06, 0.006, len), M.PAPER, _vec(mx, side * (hw - 0.03), ly, 0.0))
	# The crease itself: a dark dashed line down the middle.
	var dashes: int = int(along * 2.0)
	for k in dashes:
		var v2: float = -along * 0.5 + (k + 0.5) * along / dashes
		_line(hinge, _size(mx, 0.035, 0.006, along / dashes * 0.55), color.darkened(0.35), _vec(mx, 0.0, 0.021, v2))
	f["halves"] = halves


## Builds a size or offset in the panel's own frame: u runs across the crease,
## v along it.
func _vec(mx: bool, u: float, y: float, v: float) -> Vector3:
	return Vector3(u, y, v) if mx else Vector3(v, y, u)


func _size(mx: bool, u: float, y: float, v: float) -> Vector3:
	return Vector3(u, y, v) if mx else Vector3(v, y, u)


func _line(parent: Node3D, size: Vector3, color: Color, pos: Vector3) -> void:
	var mi := Models.part(parent, Models.box_mesh(size, 0.0015), color, pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _pose_sheet(f: Dictionary, a: float) -> void:
	var halves: Array[Node3D] = f["halves"]
	var mx: bool = f["ax"] == "x"
	for i in 2:
		var side: int = -1 if i == 0 else 1
		if mx:
			halves[i].rotation = Vector3(0, 0, side * a)
		else:
			halves[i].rotation = Vector3(-side * a, 0, 0)


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Paper bunting: a folded paper tent on each border block, in turn pink,
	# sky, lemon and mint, on a cream coping strip.
	var tents: Array = [[], [], [], []]
	var strips: Array[Transform3D] = []
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var along_x: bool = z == 0 or z == Arena.H - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		var at := Vector3(x, 0.69, z)
		strips.append(Transform3D(turn, at))
		var k: int = (x + z) % 4
		(tents[k] as Array).append(Transform3D(turn, at + Vector3(0, 0.02, 0)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.05, 0.5), 0.02), M.PAPER, strips)
	var cols: Array[Color] = [M.PINK, M.SKY, M.LEMON, M.MINT]
	for k in 4:
		var arr: Array[Transform3D] = []
		arr.assign(tents[k])
		arena._multimesh(M.prism(0.5, 0.26, 0.44), cols[k], arr)
	return true


## Solid blocks: a blue paper box with a white coping and a folded paper
## top (two triangles meeting on a diagonal crease). Drawn in multimeshes
## whose instances are looked up by cell, so a fold can carry walls across
## its panel.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var flat := Basis(Vector3.RIGHT, -PI * 0.5)
	var pieces: Array = [
		[Models.box_mesh(Vector3(0.84, 0.56, 0.84), 0.06), Models.DARK_STONE, Transform3D(Basis(), Vector3(0, 0.28, 0))],
		[Models.box_mesh(Vector3(0.9, 0.08, 0.9), 0.03), Models.STONE, Transform3D(Basis(), Vector3(0, 0.6, 0))],
		[M.half_square(0.78, 0.05), Models.STONE, Transform3D(flat, Vector3(0, 0.655, 0))],
		[M.half_square(0.78, 0.05), Models.STONE.darkened(0.1), Transform3D(Basis(Vector3.UP, PI) * flat, Vector3(0, 0.66, 0))],
		[Models.box_mesh(Vector3(0.84, 0.035, 0.035), 0.01), Models.DARK_STONE.darkened(0.1), Transform3D(Basis(), Vector3(0, 0.17, 0.42))],
	]
	for i in spots.size():
		var tf: Transform3D = spots[i]
		_wall_slot[Vector2i(roundi(tf.origin.x), roundi(tf.origin.z))] = i
	for p: Array in pieces:
		var local: Transform3D = p[2]
		var arr: Array[Transform3D] = []
		for tf in spots:
			arr.append(Transform3D(Basis(), Vector3(tf.origin.x, 0, tf.origin.z)) * local)
		var mm: MultiMesh = arena._multimesh(p[0], p[1], arr)
		_wall_parts.append([mm, local])
	return true


func _place_wall(slot: int, base: Transform3D) -> void:
	for p: Array in _wall_parts:
		var mm: MultiMesh = p[0]
		mm.set_instance_transform(slot, base * (p[1] as Transform3D))


func _build_paper_blocks() -> void:
	var hidden: Array[Transform3D] = []
	for i in PAPER_BLOCKS:
		hidden.append(_hidden_tf())
	_paper_mm = arena._multimesh(Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), M.PAPER, hidden,
		Models.glass(M.PAPER, 0.25) if Models.GLASS else null)
	_paper_band_mm = arena._multimesh(Models.box_mesh(Vector3(0.88, 0.14, 0.88), 0.05), M.CORAL, hidden,
		Models.glass(M.CORAL, 0.7, 0.15) if Models.GLASS else null)
	for mm: MultiMesh in [_paper_mm, _paper_band_mm]:
		var mmi: MultiMeshInstance3D = _mm_instance(mm)
		if mmi != null:
			mmi.custom_aabb = AABB(Vector3(-2, -6, -2), Vector3(Arena.W + 4, 8, Arena.H + 4))


func _mm_instance(mm: MultiMesh) -> MultiMeshInstance3D:
	for ch: Node in arena.get_children():
		if ch is MultiMeshInstance3D and (ch as MultiMeshInstance3D).multimesh == mm:
			return ch
	return null


func _hidden_tf() -> Transform3D:
	return Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -5, 0))


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M.pinwheel([M.PINK, M.SKY, M.LEMON, M.MINT][r.randi() % 4])
			node.scale = Vector3.ONE * 0.7
		elif roll < 0.3:
			node = M.paper_tree(r)
			node.scale *= 0.6
	else:
		if roll < 0.24:
			node = M.paper_tree(r)
		elif roll < 0.34:
			node = M.paper_house(r)
		elif roll < 0.42:
			node = M.paper_lantern()
			node.rotation.y = 0.0 if p.x < 0.0 else PI
		elif roll < 0.5:
			node = M.pinwheel([M.PINK, M.SKY, M.LEMON, M.MINT][r.randi() % 4])
		elif roll < 0.54:
			node = M.crane()
			node.get_node("Body/Fly").position.y = 0.2
			node.rotation.y = r.randf() * TAU
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var mtn := M.paper_mountain(r, size * 0.9)
	mtn.position = Vector3(0, 0, -size * 0.12)
	root.add_child(mtn)
	var house := M.paper_house(r)
	house.position = Vector3(size * 0.28, 0, size * 0.22)
	root.add_child(house)
	var tree := M.paper_tree(r)
	tree.position = Vector3(-size * 0.28, 0, size * 0.2)
	root.add_child(tree)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF1E0")
	env.adjustment_saturation = 1.06
	env.glow_intensity = 0.5


# --- Rules ------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return _markers.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if _markers.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if marker_fold.has(c):
		var i: int = marker_fold[c]
		if not _queue.has(i):
			_queue.append(i)
		_markers[c]["bump"] = 1.0
		_markers[c]["spin"] = 1.0
	if _paper_slots.has(c) and arena.tile(c) == Arena.CRATE:
		var slot: int = _paper_slots[c]
		_paper_slots.erase(c)
		_paper_grow.erase(slot)
		_paper_mm.set_instance_transform(slot, _hidden_tf())
		_paper_band_mm.set_instance_transform(slot, _hidden_tf())


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not _markers.has(c)


# --- Folding ----------------------------------------------------------------------

func _busy(i: int) -> bool:
	for a: Dictionary in _anims:
		if int(a["fold"]) == i:
			return true
	return false


## Flips panel [param i]: the board under it is mirrored at once (tiles,
## crates, hidden power-ups, pods, pick-ups, critters and Pip all move with
## their paper), then the paper and everything on it swing over the crease.
func _start_fold(i: int) -> void:
	var f: Dictionary = folds[i]
	if _busy(i) or float(f["cool"]) > 0.0:
		return
	f["cool"] = FOLD_COOLDOWN
	var cells: Array[Vector2i] = _cells(f)
	var anim := {"fold": i, "t": 0.0, "from": f["angle"], "to": PI - float(f["angle"]),
		"walls": [], "crates": [], "critters": [], "pods": [], "pickups": [], "hero": Arena.NO_CELL, "hero_to": Arena.NO_CELL}
	# Tiles.
	var old: Dictionary = {}
	for c in cells:
		old[c] = arena.tile(c)
	for c in cells:
		arena._set_tile(_mirror(f, c), int(old[c]))
	# Walls (ours) and crates (the arena's multimesh slots), and their hidden
	# power-ups.
	anim["walls"] = _remap_slots(_wall_slot, f)
	anim["crates"] = _remap_slots(arena.crate_slot, f)
	_remap_keys(arena.drops, f)
	# Pick-ups lying on the panel.
	var moved_pk: Dictionary = {}
	for c: Vector2i in arena.pickups.keys():
		if _inside(f, c):
			moved_pk[c] = arena.pickups[c]
			arena.pickups.erase(c)
	for c: Vector2i in moved_pk:
		var to: Vector2i = _mirror(f, c)
		arena.pickups[to] = moved_pk[c]
		(anim["pickups"] as Array).append([moved_pk[c]["node"], c, to])
	# Pods.
	for p: Arena.Pod in arena.pods:
		if _inside(f, p.cell):
			var from: Vector2i = p.cell
			p.cell = _mirror(f, p.cell)
			p.pos = Vector2(p.cell)
			p.slide = Vector2i.ZERO
			p.kicked = false
			(anim["pods"] as Array).append([p, from])
		elif p.slide != Vector2i.ZERO and _inside(f, p.cell + p.slide):
			p.pos = Vector2(p.cell)
			p.slide = Vector2i.ZERO
			p.kicked = false
	arena.pod_at.clear()
	for p: Arena.Pod in arena.pods:
		arena.pod_at[p.cell] = p
	# The flip snuffs out flames on the paper.
	for c: Vector2i in arena.flames.keys():
		if _inside(f, c):
			arena.flames.erase(c)
	for fx: Dictionary in arena._fx:
		if fx["kind"] == &"flame":
			var n: Node3D = fx["node"]
			if is_instance_valid(n) and _inside(f, Vector2i(roundi(n.position.x), roundi(n.position.z))):
				n.visible = false
	# Critters ride their paper; ones stepping onto it step back.
	for cr: Arena.Critter in arena.critters:
		if _inside(f, cr.cell):
			var from2: Vector2i = cr.cell
			var to2: Vector2i = _mirror(f, cr.cell)
			_hold_critter(cr, to2)
			(anim["critters"] as Array).append([cr, from2, to2])
		elif _inside(f, cr.target):
			_hold_critter(cr, cr.cell)
			_held.erase(cr)
	# Pip too: onto the middle of his mirrored tile, with a moment's grace.
	if not arena.demo and arena.hero != null and arena.hero_alive:
		var hc: Vector2i = arena.hero_cell()
		if _inside(f, hc):
			anim["hero"] = hc
			anim["hero_to"] = _mirror(f, hc)
			arena.hero_pos = Vector2(_mirror(f, hc))
			arena.hero_invuln = maxf(arena.hero_invuln, 1.0)
			_hero_hold = _mirror(f, hc)
		else:
			var off: Vector2 = arena.hero_pos - Vector2(hc)
			var lean := Vector2i(roundi(signf(off.x)) if absf(off.x) > 0.02 else 0, roundi(signf(off.y)) if absf(off.y) > 0.02 else 0)
			if (lean.x != 0 and _inside(f, hc + Vector2i(lean.x, 0))) or (lean.y != 0 and _inside(f, hc + Vector2i(0, lean.y))):
				arena.hero_pos = Vector2(hc)
		if arena.walk_goal != Arena.NO_CELL and (_inside(f, arena.walk_goal) or _inside(f, hc)):
			arena.walk_goal = Arena.NO_CELL
	_anims.append(anim)
	_sound(_snd_fold, randf_range(0.92, 1.08))
	arena._shake = maxf(arena._shake, 0.25)
	var hinge: Node3D = f["hinge"]
	arena._spawn_sparkles(hinge.position + Vector3(0, 0.3, 0), f["color"])


## Moves the entries of a cell -> slot table that sit on panel [param f] to
## their mirrored cells. Returns [slot, from, to] for each one moved.
func _remap_slots(table: Dictionary, f: Dictionary) -> Array:
	var moved: Array = []
	var keep: Dictionary = {}
	for c: Vector2i in table.keys():
		if _inside(f, c):
			keep[c] = table[c]
			table.erase(c)
	for c: Vector2i in keep:
		var to: Vector2i = _mirror(f, c)
		table[to] = keep[c]
		moved.append([int(keep[c]), c, to])
	return moved


func _remap_keys(table: Dictionary, f: Dictionary) -> void:
	var keep: Dictionary = {}
	for c: Vector2i in table.keys():
		if _inside(f, c):
			keep[c] = table[c]
			table.erase(c)
	for c: Vector2i in keep:
		table[_mirror(f, c)] = keep[c]


func _hold_critter(cr: Arena.Critter, c: Vector2i) -> void:
	cr.cell = c
	cr.target = c
	cr.t = 1.0
	cr.pos = Vector2(c)
	_held[cr] = c
	_frogs.erase(cr)


## Where something that started on [param from] is, [param e] (0..1) of the
## way through a flip of panel [param f]: swung over the crease on a half
## circle, staying upright.
func _arc(f: Dictionary, from: Vector2i, e: float, y: float) -> Vector3:
	var th: float = e * PI
	if f["ax"] == "x":
		var cx: float = (int(f["x0"]) + int(f["x1"])) * 0.5
		var u: float = from.x - cx
		return Vector3(cx + u * cos(th), y + absf(u) * sin(th), from.y)
	var cz: float = (int(f["z0"]) + int(f["z1"])) * 0.5
	var u2: float = from.y - cz
	return Vector3(from.x, y + absf(u2) * sin(th), cz + u2 * cos(th))


## A full somersault about the crease (so things land upright).
func _spin(f: Dictionary, from: Vector2i, e: float) -> Basis:
	if f["ax"] == "x":
		var cx: float = (int(f["x0"]) + int(f["x1"])) * 0.5
		return Basis(Vector3.BACK, signf(from.x - cx) * e * TAU)
	var cz: float = (int(f["z0"]) + int(f["z1"])) * 0.5
	return Basis(Vector3.RIGHT, -signf(from.y - cz) * e * TAU)


func _update_folds(delta: float) -> void:
	for f: Dictionary in folds:
		f["cool"] = maxf(float(f["cool"]) - delta, 0.0)
	for i: int in _queue:
		_start_fold(i)
	_queue.clear()
	var done: Array[Dictionary] = []
	for a: Dictionary in _anims:
		a["t"] = float(a["t"]) + delta
		var f: Dictionary = folds[int(a["fold"])]
		var k: float = clampf(float(a["t"]) / FOLD_TIME, 0.0, 1.0)
		var e: float = k * k * (3.0 - 2.0 * k)
		var ang: float = lerpf(float(a["from"]), float(a["to"]), e)
		f["angle"] = ang
		_pose_sheet(f, ang)
		var fin: bool = k >= 1.0
		for w: Array in a["walls"]:
			var from: Vector2i = w[1]
			var to: Vector2i = w[2]
			if fin:
				_place_wall(int(w[0]), Transform3D(Basis(), Vector3(to.x, 0, to.y)))
			else:
				var mid: Vector3 = _arc(f, from, e, 0.4)
				_place_wall(int(w[0]), Transform3D(_spin(f, from, e), mid) * Transform3D(Basis(), Vector3(0, -0.4, 0)))
		for cdata: Array in a["crates"]:
			var slot: int = cdata[0]
			var tf := Transform3D(Basis(), Vector3(cdata[2].x, 0.4, cdata[2].y))
			if not fin:
				tf = Transform3D(_spin(f, cdata[1], e), _arc(f, cdata[1], e, 0.4))
			if arena.crate_slot.get(cdata[2], -1) == slot:
				arena._crates_mm.set_instance_transform(slot, tf)
				arena._bands_mm.set_instance_transform(slot, tf)
		for pk: Array in a["pickups"]:
			var node: Node3D = pk[0]
			if is_instance_valid(node):
				node.position = Vector3(pk[2].x, 0, pk[2].y) if fin else _arc(f, pk[1], e, 0.0)
		for pd: Array in a["pods"]:
			var p: Arena.Pod = pd[0]
			if arena.pods.has(p) and not fin:
				p.node.position = _arc(f, pd[1], e, 0.0)
		for cd: Array in a["critters"]:
			var cr: Arena.Critter = cd[0]
			if not arena.critters.has(cr):
				continue
			if fin:
				_held.erase(cr)
			else:
				_hold_critter(cr, cd[2])
				cr.node.position = _arc(f, cd[1], e, 0.0)
		if a["hero"] != Arena.NO_CELL and arena.hero != null:
			if fin:
				_hero_hold = Arena.NO_CELL
			elif arena.hero_alive:
				arena.hero_pos = Vector2(a["hero_to"])
				arena.hero.position = _arc(f, a["hero"], e, 0.0)
		if fin:
			f["angle"] = float(a["to"])
			_pose_sheet(f, float(a["to"]))
			done.append(a)
	for a: Dictionary in done:
		_anims.erase(a)


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	_animate_markers(delta)
	_update_folds(delta)
	_grow_paper_blocks(delta)
	if arena.demo:
		return
	_update_frogs()
	_update_boss(delta)


func _animate_markers(delta: float) -> void:
	for c: Vector2i in _markers:
		var mk: Dictionary = _markers[c]
		var n: Node3D = mk.get("node")
		if n == null:
			continue
		mk["spin"] = maxf(float(mk["spin"]) - delta * 0.8, 0.0)
		mk["bump"] = maxf(float(mk["bump"]) - delta * 3.0, 0.0)
		var wheel: Node3D = n.get_node("Wheel/Spin")
		wheel.rotation.z -= delta * (0.8 + float(mk["spin"]) * 16.0)
		var b: float = float(mk["bump"])
		n.scale = Vector3(1.0 + b * 0.15, 1.0 - b * 0.12, 1.0 + b * 0.15)
		var bulb: MeshInstance3D = n.get_node("Bulb")
		bulb.scale = Vector3.ONE * (1.0 + 0.2 * sin(arena._clock * 4.0 + c.x))


# --- Critters ---------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"crane":
			return M.crane()
		&"frog":
			return M.frog()
		&"boss":
			return M.dragon()
	return null


func critter_speed(kind: StringName) -> float:
	if kind == &"crane":
		return 2.1 + 0.08 * arena.level_id
	if kind == &"frog":
		return FROG_SPEED
	return 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_smart(kind: StringName) -> bool:
	if kind == &"crane":
		return arena.level_id >= 3
	if kind == &"frog":
		return arena.level_id >= 4
	return false


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind == &"crane":
		return _crane_step(cr)
	if cr.kind == &"frog":
		return _frog_step(cr)
	return Vector2i.ZERO


## Cranes glide straight on until something stops them, and swoop at Pip
## when he is in line and close with nothing in between.
func _crane_step(cr: Arena.Critter) -> Vector2i:
	var danger: Dictionary = arena._critter_danger(cr)
	if not arena.demo and arena.hero_alive:
		var hc: Vector2i = arena.hero_cell()
		var gap: Vector2i = hc - cr.cell
		if (gap.x == 0) != (gap.y == 0) and absi(gap.x) + absi(gap.y) <= 6:
			var d := Vector2i(signi(gap.x), signi(gap.y))
			var clear: bool = true
			var c: Vector2i = cr.cell + d
			while c != hc:
				if not arena._critter_can_enter(cr, c):
					clear = false
					break
				c += d
			if clear and not danger.has(cr.cell + d):
				return d
	var ahead: Vector2i = cr.cell + cr.dir
	if arena._critter_can_enter(cr, ahead) and not danger.has(ahead):
		return cr.dir
	return Vector2i.ZERO


## Frogs pick a hop whose landing tile is safe, keep going the same way most
## of the time, and (in later levels) hop towards Pip.
func _frog_step(cr: Arena.Critter) -> Vector2i:
	var danger: Dictionary = arena._critter_danger(cr)
	var options: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		if not arena._critter_can_enter(cr, cr.cell + d):
			continue
		var land: Vector2i = cr.cell + d * 2 if arena._critter_can_enter(cr, cr.cell + d * 2) else cr.cell + d
		if not danger.has(land):
			options.append(d)
	if options.is_empty():
		return Vector2i.ZERO
	if critter_smart(&"frog") and arena.hero_alive:
		var hc: Vector2i = arena.hero_cell()
		var best: Vector2i = Vector2i.ZERO
		var best_d: int = absi(hc.x - cr.cell.x) + absi(hc.y - cr.cell.y)
		if best_d <= 7:
			for d: Vector2i in options:
				var land2: Vector2i = cr.cell + d * 2
				var dd: int = absi(hc.x - land2.x) + absi(hc.y - land2.y)
				if dd < best_d:
					best_d = dd
					best = d
			if best != Vector2i.ZERO and arena.rng.randf() < 0.75:
				return best
	if options.has(cr.dir) and arena.rng.randf() < 0.6:
		return cr.dir
	return options[arena.rng.randi() % options.size()]


## Turns each frog's single steps into two-tile hops with a short rest in
## between (see the arena's critter stepping: a new step starts with t = 0).
func _update_frogs() -> void:
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"frog" or _held.has(cr):
			continue
		if not _frogs.has(cr):
			_frogs[cr] = {"tgt": cr.target, "hop": false}
		var st: Dictionary = _frogs[cr]
		if cr.target == st["tgt"]:
			continue
		if not bool(st["hop"]):
			if cr.target != cr.cell:
				var d: Vector2i = cr.target - cr.cell
				var far: Vector2i = cr.cell + d * 2
				if absi(d.x) + absi(d.y) == 1 and arena._critter_can_enter(cr, far):
					cr.target = far
				st["hop"] = true
		elif cr.t > 0.01:
			# Turned back mid-hop (something blocked the landing).
			pass
		else:
			# Landed and the arena picked the next hop: rest a moment first.
			cr.target = cr.cell
			cr.t = 1.0 - FROG_REST * cr.speed
			cr.pos = Vector2(cr.cell)
			st["hop"] = false
		st["tgt"] = cr.target


func critter_hidden(cr: Arena.Critter) -> bool:
	if cr.kind != &"frog" or not _frogs.has(cr):
		return false
	var st: Dictionary = _frogs[cr]
	var dist: int = absi(cr.target.x - cr.cell.x) + absi(cr.target.y - cr.cell.y)
	return bool(st["hop"]) and dist == 2 and cr.t > 0.22 and cr.t < 0.78


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"crane":
			var fly: Node3D = body.get_node("Fly")
			fly.position.y = 0.42 + sin(t * 2.2) * 0.07
			var flap: float = sin(t * 7.0) * 0.5 if fmod(t, 3.0) < 1.2 else 0.12 + sin(t * 1.5) * 0.06
			body.get_node("Fly/WingL").rotation.z = flap
			body.get_node("Fly/WingR").rotation.z = -flap
			fly.rotation.x = lerpf(fly.rotation.x, 0.12 if cr.t < 1.0 else 0.0, minf(delta * 6.0, 1.0))
			return Vector3.ONE * M.CRANE_SIZE
		&"frog":
			var st: Dictionary = _frogs.get(cr, {})
			var air: bool = bool(st.get("hop", false)) and cr.target != cr.cell and cr.t < 1.0
			var span: float = Vector2(cr.target - cr.cell).length()
			if air:
				body.position.y = sin(cr.t * PI) * (0.35 + 0.25 * span)
				body.rotation.x = lerpf(-0.35, 0.35, cr.t)
				for leg: String in ["LegL", "LegR"]:
					(body.get_node(leg) as Node3D).rotation.x = -0.9 * sin(cr.t * PI)
				return Vector3(0.9, 1.15, 0.9) * M.FROG_SIZE
			body.position.y = lerpf(body.position.y, 0.0, minf(delta * 14.0, 1.0))
			body.rotation.x = lerpf(body.rotation.x, 0.0, minf(delta * 10.0, 1.0))
			for leg2: String in ["LegL", "LegR"]:
				(body.get_node(leg2) as Node3D).rotation.x = 0.0
			var breathe: float = sin(t * 5.0) * 0.05
			return Vector3(1.0 + breathe, 1.0 - breathe * 1.4, 1.0 + breathe) * M.FROG_SIZE
		&"boss":
			var warn: bool = _warn_fold >= 0
			var flap2: float = 0.85 + sin(t * (9.0 if warn else 3.0)) * (0.45 if warn else 0.2)
			(body.get_node("WingL") as Node3D).rotation.z = -flap2
			(body.get_node("WingR") as Node3D).rotation.z = flap2
			var head: Node3D = body.get_node("Head")
			head.rotation.x = lerpf(head.rotation.x, -0.45 if warn else sin(t * 2.0) * 0.08, minf(delta * 8.0, 1.0))
			(head.get_node("Jaw") as Node3D).rotation.x = 0.35 if warn else maxf(sin(t * 1.3), 0.0) * 0.15
			var tail: Node3D = body.get_node("Tail")
			tail.rotation.y = sin(t * 2.4) * 0.35
			(tail.get_node("Seg0/Seg1") as Node3D).rotation.y = sin(t * 2.4 - 0.8) * 0.4
			body.rotation.x = lerpf(body.rotation.x, -0.25 if warn else 0.0, minf(delta * 6.0, 1.0))
			cr.node.get_node("Glow").visible = warn
			if warn:
				var g: Node3D = cr.node.get_node("Glow")
				g.scale = Vector3.ONE * (1.0 + 0.15 * sin(t * 18.0))
			return Vector3(1.0, 1.0 + absf(sin(t * 3.0)) * 0.04, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- The dragon ------------------------------------------------------------------

func _update_boss(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		_warn_fold = -1
		return
	# A touch quicker than the base boss, and quicker still as it tires.
	b.speed = 1.15 + (arena.boss_max_hp - b.hp) * 0.08
	if b.hp <= BOSS_FOLD_HP and not folds.is_empty():
		if _warn_fold < 0:
			_boss_fold_t -= delta
			if _boss_fold_t <= 0.0:
				var options: Array[int] = []
				var hc: Vector2i = arena.hero_cell()
				for i in folds.size():
					if not _busy(i) and float(folds[i]["cool"]) <= 0.0 and not _inside(folds[i], hc):
						options.append(i)
				if options.is_empty():
					_boss_fold_t = 1.0
				else:
					_warn_fold = options[arena.rng.randi() % options.size()]
					_warn_t = BOSS_WARN
					_sound(_snd_warn, 1.0)
		else:
			_warn_t -= delta
			var f: Dictionary = folds[_warn_fold]
			var lift: float = absf(sin(arena._clock * 16.0)) * 0.14
			var rest: float = float(f["angle"])
			_pose_sheet(f, rest + (lift if rest < 1.0 else -lift))
			if _warn_t <= 0.0:
				_pose_sheet(f, rest)
				_start_fold(_warn_fold)
				_warn_fold = -1
				_boss_fold_t = BOSS_FOLD_EVERY if b.hp > BOSS_BLOCK_HP else BOSS_FOLD_EVERY - 1.5
	if b.hp <= BOSS_BLOCK_HP and _paper_mm != null:
		_boss_block_t -= delta
		if _boss_block_t <= 0.0:
			_boss_block_t = BOSS_BLOCK_EVERY
			_fold_paper_blocks(3)


## The dragon folds a few paper blocks (crates) into empty tiles away from
## Pip and off the panels. They break like any crate.
func _fold_paper_blocks(count: int) -> void:
	var hc: Vector2i = arena.hero_cell()
	var spots: Array[Vector2i] = []
	for z in range(1, Arena.H - 1):
		for x in range(1, Arena.W - 1):
			var c := Vector2i(x, z)
			if arena.tile(c) != Arena.FLOOR or blocks(c) or _in_any_fold(c):
				continue
			if absi(c.x - hc.x) + absi(c.y - hc.y) < 3 or c == arena.exit_cell or c == arena.start_cell:
				continue
			if arena.pod_at.has(c) or arena.pickups.has(c) or arena.flames.has(c) or arena.warps.has(c):
				continue
			var taken: bool = false
			for cr: Arena.Critter in arena.critters:
				if cr.cell == c or cr.target == c or Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
					taken = true
					break
			if not taken:
				spots.append(c)
	arena._shuffle(spots)
	var made: int = 0
	for c: Vector2i in spots:
		if made >= count:
			break
		var slot: int = -1
		for s in PAPER_BLOCKS:
			if not _paper_grow.has(s):
				slot = s
				break
		if slot < 0:
			return
		arena._set_tile(c, Arena.CRATE)
		_paper_slots[c] = slot
		_paper_grow[slot] = 0.0
		arena._spawn_sparkles(Vector3(c.x, 0.5, c.y), M.CORAL)
		made += 1
	if made > 0:
		_sound(_snd_fold, 1.3)


func _grow_paper_blocks(delta: float) -> void:
	for c: Vector2i in _paper_slots:
		var slot: int = _paper_slots[c]
		var t: float = float(_paper_grow.get(slot, 1.0))
		if t >= 1.0:
			continue
		t = minf(t + delta / 0.35, 1.0)
		_paper_grow[slot] = t
		var s: float = maxf(t * (1.0 + sin(t * PI) * 0.25), 0.001)
		var basis := Basis(Vector3.UP, (1.0 - t) * PI).scaled(Vector3(s, s, s))
		var tf := Transform3D(basis, Vector3(c.x, 0.4 * s, c.y))
		_paper_mm.set_instance_transform(slot, tf)
		_paper_band_mm.set_instance_transform(slot, tf)


# --- Sound --------------------------------------------------------------------------

func _sound(s: AudioStreamWAV, pitch: float) -> void:
	if _player == null or s == null or not Save.sound_on:
		return
	_player.stream = s
	_player.pitch_scale = pitch
	_player.play()


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = 22050
	w.data = data
	return w


## A papery "fwip" (a swept, filtered rustle) ending in a soft flap.
func _make_fold() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.55)
	var out := PackedFloat32Array()
	out.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 1515
	var lp: float = 0.0
	var prev: float = 0.0
	for i in n:
		var t: float = i / rate
		var x: float = r.randf_range(-1.0, 1.0)
		var cut: float = 0.08 + 0.5 * sin(minf(t / 0.4, 1.0) * PI)
		lp += (x - lp) * cut
		var hp: float = lp - prev
		prev = lp
		var env: float = minf(t / 0.05, 1.0) * exp(-t * 5.0)
		var t2: float = maxf(t - 0.36, 0.0)
		var flap: float = sin(TAU * 140.0 * t2) * exp(-t2 * 30.0) * (1.0 if t > 0.36 else 0.0)
		out[i] = (hp * 1.6 * env + flap * 0.5) * 0.6
	return _wav(out)


## Two rising plucks: the dragon is about to fold the valley.
func _make_warn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for note: Array in [[0.0, 587.3], [0.18, 880.0]]:
			var tt: float = t - float(note[0])
			if tt < 0.0:
				continue
			var fr: float = note[1]
			v += (sin(TAU * fr * tt) + 0.5 * sin(TAU * fr * 2.0 * tt) * exp(-tt * 12.0)) * exp(-tt * 6.0) * minf(tt / 0.004, 1.0)
		out[i] = v * 0.35
	return _wav(out)

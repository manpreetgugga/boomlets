extends WorldKit
## World 17, Paint Plaza: a sunny artists' square of cream cobbles, striped
## market stalls, easels and café tables. The twist is colour: stepping into
## a paint tub (R, Y, U) dyes Pip's blasts red, yellow or blue, and his beret,
## his pods and their flames all show it. Paint crates (r, y, u) and canvas
## gates (4, 5, 6) only give way to a blast of their own colour (any other
## blast stops at them like a wall), while plain crates break for any colour.
## Paint Blobs (p, q, o) only pop for a blast of their colour, and they are
## chameleons: walking through a paint splat (7, 8, 9) turns them that
## colour. Barrels go off with plain fire, which paint shrugs off. Brushbot,
## the painter robot, changes colour as it takes hits, so Pip has to keep
## switching tubs, and flicks paint balls that splat where they land.
##
## Extra map characters:
##   R Y U  red / yellow / blue paint tub    p q o  red / yellow / blue Paint Blob
##   r y u  red / yellow / blue paint crate  7 8 9  red / yellow / blue splat
##   4 5 6  red / yellow / blue canvas gate

const M := preload("res://worlds/world_17_models.gd")

const NONE: int = -1
const NO_CELL := Vector2i(-99, -99)
const BLOB_SPEED: float = 1.45
## How long a blast of the wrong colour leaves a blob (or Brushbot) shrugging.
const DEFLECT: float = 0.6
const GATE_TIME: float = 0.45
## Brushbot's paint balls.
const BALL_EVERY: float = 5.0
const BALL_EVERY_HURT: float = 3.6
const BALL_FLIGHT: float = 1.05
const SPLAT_LIFE: float = 7.0
## In its last phase Brushbot repaints itself this often.
const BOSS_CYCLE: float = 6.0

const PALETTE: Dictionary = {
	"GRASS_A": "#F6E6C8", "GRASS_B": "#ECD6AE", "RIM": "#E9C99A", "EDGE": "#C98A5A",
	"STONE": "#F3E3C6", "DARK_STONE": "#D9B98E", "DIRT": "#B97A52", "ROCK": "#D9774B",
	"WOOD": "#C3CAD6", "WOOD_DARK": "#7C8396", "BARREL": "#9A6AD6", "BELT": "#5B6175", "ACCENT": "#FF9F7A",
	"BLOSSOM_A": "#5DB060", "BLOSSOM_B": "#46934C", "TRUNK": "#7E5232", "LEAFY_A": "#6FC46F", "LEAFY_B": "#55A85A",
	"SKY_TOP": "#4FA3F0", "SKY_HORIZON": "#FFF1D6", "SKY_GROUND": "#A8D4F2", "CLOUD": "#FFFFFF", "CLOUDS": 0.5,
	"AMBIENT": "#F2E6D6", "AMBIENT_ENERGY": 0.66, "SUN": "#FFF3DE", "SUN_ENERGY": 1.5,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "First Brushstroke",
		"tip": "Step in the red tub to dip your\nblasts in red. Red blasts break\nred crates and pop red blobs!",
		"crates": 0.3, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.p.......p.#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"####r#4#r####",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#..r..p..r..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#..R._S_....#",
			"#############",
		],
	},
	{
		"name": "Primary Colours",
		"tip": "Blue blasts open blue gates.\nBlobs take the colour of any\nsplat they cross: match the blob!",
		"crates": 0.34, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.o...E...o.#",
			"#.#.#.#.#.#.#",
			"#...9...7...#",
			"#.#.#.#.#.#.#",
			"#.p.......p.#",
			"######6######",
			"#...u...r...#",
			"#.#.#.#.#.#.#",
			"#.o..._..p..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#.R.._S_..U.#",
			"#############",
		],
	},
	{
		"name": "Coffee Corner",
		"tip": "Barrels blow plain fire: it\nbreaks plain crates, but paint\njust shrugs it off!",
		"crates": 0.34, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#z....E....z#",
			"#.#.#.#.#.#.#",
			"#..q.....q..#",
			"#.#.#.#.#.#.#",
			"#...B.8.B...#",
			"###y##5##y###",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.p..Y.U..o.#",
			"#.#.#.#.#.#.#",
			"#...B...B...#",
			"#.#.#_#_#.#.#",
			"#.R.._S_..u.#",
			"#############",
		],
	},
	{
		"name": "Gallery Walk",
		"tip": "Yellow gets you into the\ngalleries. Find red and blue\ninside to reach the top floor!",
		"crates": 0.34, "par": 110,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#..w..E..w..#",
			"#.#.#.#.#.#.#",
			"#.q...o...p.#",
			"###4#####6###",
			"#..b..#..z..#",
			"#.#.#.#.#.#.#",
			"#..R..#..U..#",
			"#####5#5#####",
			"#...7...9...#",
			"#.#.#.#.#.#.#",
			"#.Y.......q.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Rainbow Row",
		"tip": "Belts carry pods along the\nrow. Warp across for blue, and\nmind which colour you carry!",
		"crates": 0.34, "par": 120,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#q....E....o#",
			"#.#.#.#.#.#.#",
			"#...7.z.9...#",
			"#.#.#.#.#.#.#",
			"#..p.....p..#",
			"##y##4#6##u##",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#1..>>>>>..U#",
			"#.#.#.#.#.#.#",
			"#R..<<<<<..1#",
			"#.#.#_#_#.#.#",
			"#.Y.._S_..B.#",
			"#############",
		],
	},
	{
		"name": "Brushbot",
		"tip": "Brushbot repaints itself as it\ntakes hits! Dip in the matching\ntub, and dodge its paint balls.",
		"crates": 0.15, "par": 135, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#...#...#.#",
			"#.R.......Y.#",
			"#.#.#...#.#.#",
			"#.....K.....#",
			"#.#...#...#.#",
			"#...........#",
			"#.#.#...#.#.#",
			"#...........#",
			"#.#...#...#.#",
			"#.....U.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Cell -> {"idx", "node", "pulse"}.
var tubs: Dictionary = {}
## Cell -> {"idx", "node", "wob"}.
var pcrates: Dictionary = {}
## Cell -> {"idx", "node", "open", "a"}.
var gates: Dictionary = {}
## Cell -> {"idx", "node", "t"} (t < 0: there for good).
var splats: Dictionary = {}
## The colour Pip's blasts are dyed (NONE for plain fire).
var hero_color: int = NONE

var _clock: float = 0.0
var _rng := RandomNumberGenerator.new()
var _beret: Node3D
var _beret_pop: float = 0.0
var _pod_col: Dictionary = {}        # Arena.Pod -> colour it was dropped with
var _banded: Dictionary = {}         # Arena.Pod -> true once its band is painted
var _barrel_cells: Dictionary = {}
var _last_stop: Vector2i = NO_CELL
var _blast_col: int = NONE
var _blast_fire: int = 2
var _flame_col: Dictionary = {}      # Cell -> colour of the flame on it
var _col: Dictionary = {}            # Arena.Critter -> colour (Paint Blobs and the boss)
var _initial: Dictionary = {}
var _shrug: Dictionary = {}          # Arena.Critter -> seconds left of a shrug
var _boss_col: int = 0
var _boss_hp_seen: int = -1
var _boss_cycle: float = BOSS_CYCLE
var _balls: Array[Dictionary] = []
var _ball_t: float = BALL_EVERY
var _flame_mats: Array = []          # [arm material, core material] per colour
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_dip: AudioStreamWAV
var _snd_boink: AudioStreamWAV
var _snd_bonk: AudioStreamWAV
var _snd_splat: AudioStreamWAV
var _snd_chime: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Paint Plaza"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_17.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "BRUSHBOT"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"blob_r"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	var i: int = "RYU".find(ch)
	if i >= 0:
		tubs[c] = {"idx": i, "pulse": 0.0}
		return true
	i = "ryu".find(ch)
	if i >= 0:
		pcrates[c] = {"idx": i, "wob": 0.0}
		return true
	i = "456".find(ch)
	if i >= 0:
		gates[c] = {"idx": i, "open": false, "a": 0.0}
		return true
	i = "789".find(ch)
	if i >= 0:
		splats[c] = {"idx": i, "t": -1.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"p": &"blob_r", "q": &"blob_y", "o": &"blob_b"}


func build_extra() -> void:
	_rng.seed = hash(String(arena.data["name"])) + 17
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 71
	for c: Vector2i in tubs:
		var n: Node3D = M.tub(int(tubs[c]["idx"]), r)
		n.position = Vector3(c.x, 0, c.y)
		n.rotation.y = r.randf() * TAU
		arena.add_child(n)
		tubs[c]["node"] = n
	for c: Vector2i in pcrates:
		var n2: Node3D = M.paint_crate(int(pcrates[c]["idx"]), r)
		n2.position = Vector3(c.x, 0, c.y)
		arena.add_child(n2)
		pcrates[c]["node"] = n2
	for c: Vector2i in gates:
		var n3: Node3D = M.gate(int(gates[c]["idx"]))
		n3.position = Vector3(c.x, 0, c.y)
		arena.add_child(n3)
		gates[c]["node"] = n3
	for c: Vector2i in splats:
		var n4: Node3D = M.splat(int(splats[c]["idx"]), r)
		n4.position = Vector3(c.x, 0, c.y)
		n4.rotation.y = r.randf() * TAU
		arena.add_child(n4)
		splats[c]["node"] = n4
	# Warm grout under the cobbles.
	var under := Models.part(arena, Models.box_mesh(Vector3(Arena.W - 1.9, 0.1, Arena.H - 1.9), 0.02), Color("#CDAE84"), Vector3((Arena.W - 1) * 0.5, -0.06, (Arena.H - 1) * 0.5))
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c: Vector2i in arena.barrels:
		_barrel_cells[c] = true
	for k in 3:
		_flame_mats.append([Models.mat(M.FLAME_ARM[k], 1.1), Models.mat(M.FLAME_CORE[k], 1.8)])
	if arena.hero != null:
		_beret = M.beret(0)
		_beret.position = Vector3(-0.03, 0.8, -0.02)
		_beret.rotation = Vector3(-0.15, 0.0, 0.3)
		_beret.visible = false
		arena.hero.get_node("Body").add_child(_beret)
	for cr: Arena.Critter in arena.critters:
		_initial[cr] = true
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -6.0
	arena.add_child(_player2)
	_snd_dip = _make_dip()
	_snd_boink = _make_boink()
	_snd_bonk = _make_bonk()
	_snd_splat = _make_splat()
	_snd_chime = _make_chime()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Terracotta flower troughs along the plaza walls, cream stone finials
	# on the corners and only a low clipped hedge on the near wall.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 5
	var top: float = 0.69
	var w: int = Arena.W
	var h: int = Arena.H
	var troughs: Array[Transform3D] = []
	var rims: Array[Transform3D] = []
	var hedges: Array[Transform3D] = []
	var low: Array[Transform3D] = []
	var plinths: Array[Transform3D] = []
	var balls: Array[Transform3D] = []
	var flowers: Array = []
	for i in M.FLOWERS.size():
		flowers.append([])
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var base := Vector3(x, top, z)
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if corner:
			plinths.append(Transform3D(Basis(), base + Vector3(0, 0.1, 0)))
			balls.append(Transform3D(Basis(), base + Vector3(0, 0.33, 0)))
			continue
		var along_x: bool = z == 0 or z == h - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		if z == h - 1:
			low.append(Transform3D(turn, base + Vector3(0, 0.06, 0)))
			continue
		troughs.append(Transform3D(turn, base + Vector3(0, 0.09, 0)))
		rims.append(Transform3D(turn, base + Vector3(0, 0.19, 0)))
		hedges.append(Transform3D(turn, base + Vector3(0, 0.28, 0)))
		for k in r.randi_range(2, 4):
			var off := turn * Vector3(r.randf_range(-0.38, 0.38), 0.0, r.randf_range(-0.14, 0.14))
			(flowers[r.randi() % flowers.size()] as Array).append(Transform3D(Basis().scaled(Vector3.ONE * r.randf_range(0.8, 1.2)), base + off + Vector3(0, 0.39, 0)))
	if not troughs.is_empty():
		arena._multimesh(Models.box_mesh(Vector3(0.94, 0.18, 0.5), 0.04), M.TERRACOTTA, troughs)
		arena._multimesh(Models.box_mesh(Vector3(0.98, 0.04, 0.54), 0.015), M.TERRA_DARK, rims)
		arena._multimesh(Models.box_mesh(Vector3(0.9, 0.18, 0.42), 0.08), M.LEAF, hedges)
	if not low.is_empty():
		arena._multimesh(Models.box_mesh(Vector3(0.94, 0.12, 0.44), 0.05), M.LEAF_DARK, low)
	if not plinths.is_empty():
		arena._multimesh(Models.box_mesh(Vector3(0.6, 0.2, 0.6), 0.04), M.CREAM.darkened(0.06), plinths)
		arena._multimesh(Models.sphere(0.17, 0.34, 14), M.CREAM, balls)
	var bloom := Models.sphere(0.06, 0.08, 8)
	for i in flowers.size():
		var arr: Array[Transform3D] = []
		arr.assign(flowers[i])
		if not arr.is_empty():
			arena._multimesh(bloom, M.FLOWERS[i], arr)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Little market stalls seen from above: a wooden counter with paint pots
	# under a sloping striped awning with a scalloped edge.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 13
	var counters: Array[Transform3D] = []
	var tops: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var whites: Array[Transform3D] = []
	var stripes: Array = []
	var scallops: Array = []
	for i in M.AWNINGS.size():
		stripes.append([])
		scallops.append([])
	var pots: Array[Transform3D] = []
	var tilt := Basis(Vector3.RIGHT, 0.3)
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var ci: int = r.randi() % M.AWNINGS.size()
		counters.append(Transform3D(Basis(), p + Vector3(0, 0.22, 0.04)))
		tops.append(Transform3D(Basis(), p + Vector3(0, 0.46, 0.04)))
		for sx: float in [-0.39, 0.39]:
			posts.append(Transform3D(Basis(), p + Vector3(sx, 0.36, -0.36)))
			posts.append(Transform3D(Basis(), p + Vector3(sx, 0.32, 0.38)))
		for k in 5:
			var at := p + Vector3(-0.36 + k * 0.18, 0.74, 0.0)
			if k % 2 == 0:
				(stripes[ci] as Array).append(Transform3D(tilt, at))
			else:
				whites.append(Transform3D(tilt, at))
			(scallops[ci] as Array).append(Transform3D(Basis().scaled(Vector3(1.0, 0.7, 0.55)), p + Vector3(-0.36 + k * 0.18, 0.6, 0.45)))
		for k2 in 3:
			pots.append(Transform3D(Basis(), p + Vector3(-0.22 + k2 * 0.22, 0.53, 0.3)))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.44, 0.74), 0.05), M.WOOD_LIGHT, counters)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.05, 0.8), 0.02), M.WOOD, tops)
	arena._multimesh(Models.cylinder(0.03, 0.03, 0.72, 6), M.WOOD_DARK, posts)
	var stripe := Models.box_mesh(Vector3(0.18, 0.05, 0.96), 0.015)
	arena._multimesh(stripe, Color("#FFFDF7"), whites)
	var scallop := Models.sphere(0.09, 0.18, 10)
	for i in M.AWNINGS.size():
		var arr: Array[Transform3D] = []
		arr.assign(stripes[i])
		if not arr.is_empty():
			arena._multimesh(stripe, M.AWNINGS[i], arr)
		var arr2: Array[Transform3D] = []
		arr2.assign(scallops[i])
		if not arr2.is_empty():
			arena._multimesh(scallop, M.AWNINGS[i], arr2)
	arena._multimesh(Models.cylinder(0.06, 0.06, 0.1, 10), M.METAL, pots)
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.2:
			node = M.planter(r)
			node.scale = Vector3.ONE * 0.8
		elif roll < 0.34:
			node = M.paint_pots(r)
	elif p.z < 0.0:
		if roll < 0.24:
			node = M.easel(r)
		elif roll < 0.42:
			node = M.stall(r)
		elif roll < 0.58:
			node = M.cafe_table(r)
		elif roll < 0.68:
			node = M.lamp_post()
		elif roll < 0.8:
			node = M.topiary(r)
		elif roll < 0.88:
			node = M.planter(r)
	else:
		if roll < 0.16:
			node = M.easel(r)
		elif roll < 0.3:
			node = M.cafe_table(r)
		elif roll < 0.42:
			node = M.planter(r)
		elif roll < 0.5:
			node = M.lamp_post()
		elif roll < 0.58:
			node = M.paint_pots(r)
		if node != null and r.randf() < 0.5:
			node.rotation.y = PI * 0.5 * (1.0 if p.x < 0.0 else -1.0)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var f := M.fountain()
	f.position = Vector3(-size * 0.08, 0, -size * 0.12)
	root.add_child(f)
	var t := M.cafe_table(r)
	t.position = Vector3(size * 0.3, 0, size * 0.18)
	root.add_child(t)
	var tp := M.topiary(r)
	tp.position = Vector3(-size * 0.3, 0, size * 0.25)
	root.add_child(tp)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF2DC")
	env.glow_intensity = 0.55
	env.adjustment_saturation = 1.1


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	if pcrates.has(c):
		return true
	return gates.has(c) and not bool(gates[c]["open"])


func flame_stop(c: Vector2i) -> int:
	_last_stop = c
	var idx: int = _paint_at(c)
	if idx == NONE:
		return 0
	return 1 if idx == _blast_col else 2


## The colour of the paint crate or closed gate on [param c], or NONE.
func _paint_at(c: Vector2i) -> int:
	if pcrates.has(c):
		return int(pcrates[c]["idx"])
	if gates.has(c) and not bool(gates[c]["open"]):
		return int(gates[c]["idx"])
	return NONE


func on_flame(c: Vector2i) -> void:
	# Work out which blast this flame belongs to. A blast's centre comes
	# first: a pod that has just gone off on this cell (its colour), a barrel
	# bursting (plain fire) or, failing both, a blast from somewhere else
	# (Pip's colour). Arm flames come right after flame_stop() on their cell.
	var centre: bool = true
	var col: int = hero_color
	var known: bool = false
	for p: Arena.Pod in _pod_col.keys():
		if p.cell == c and not arena.pods.has(p):
			col = int(_pod_col[p])
			_blast_fire = p.fire
			_pod_col.erase(p)
			_banded.erase(p)
			known = true
			break
	if not known:
		if _barrel_cells.has(c) and arena.tile(c) == Arena.FLOOR and not arena.barrels.has(c):
			_barrel_cells.erase(c)
			col = NONE
			_blast_fire = Arena.BARREL_FIRE
		elif c == _last_stop:
			centre = false
	if centre:
		_blast_col = col
	_last_stop = NO_CELL
	_flame_col[c] = _blast_col
	if _blast_col == NONE:
		return
	if pcrates.has(c) and int(pcrates[c]["idx"]) == _blast_col:
		_break_paint_crate(c)
	elif gates.has(c) and not bool(gates[c]["open"]) and int(gates[c]["idx"]) == _blast_col:
		_open_gate(c)


func on_explode(c: Vector2i) -> void:
	if _blast_col != NONE:
		arena._spawn_ring(Vector3(c.x, 0.08, c.y), M.PAINTS[_blast_col], 1.2 + _blast_fire * 0.4)
	_shrug_paint(c, _blast_fire)


## Paint crates and gates of another colour in the blast's reach give a
## stubborn wobble, so it is clear the colour was wrong.
func _shrug_paint(c: Vector2i, reach: int) -> void:
	var any: bool = false
	for d: Vector2i in Arena.DIRS:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			var t: int = arena.tile(cc)
			if t == Arena.WALL:
				break
			var idx: int = _paint_at(cc)
			if idx != NONE:
				if idx != _blast_col:
					var holder: Dictionary = pcrates[cc] if pcrates.has(cc) else gates[cc]
					holder["wob"] = 1.0
					arena._spawn_sparkles(Vector3(cc.x - d.x * 0.45, 0.45, cc.y - d.y * 0.45), M.PAINTS[idx].lightened(0.3))
					any = true
				break
			if t != Arena.FLOOR:
				break
	if any:
		_sound(_snd_bonk, 1.0, 0.3, true)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not blocks(c)


func on_hero_enter(c: Vector2i) -> void:
	if not tubs.has(c):
		return
	var idx: int = tubs[c]["idx"]
	tubs[c]["pulse"] = 1.0
	arena._spawn_ring(Vector3(c.x, 0.16, c.y), M.PAINTS[idx], 0.9)
	if idx == hero_color:
		_sound(_snd_dip, 0.8 + idx * 0.12, 0.2)
		return
	hero_color = idx
	if _beret != null:
		M.tint(_beret, idx)
		_beret.visible = true
		_beret_pop = 1.0
	arena._spawn_sparkles(arena._to3(arena.hero_pos, 0.6), M.PAINTS[idx].lightened(0.2))
	_sound(_snd_dip, 1.0 + idx * 0.15)
	Save.buzz(20)


func critter_hit(cr: Arena.Critter) -> bool:
	if not _col.has(cr):
		return false
	var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
	if not _flame_col.has(here):
		# A flame that came from no blast at all (a debug hit): let it count.
		return false
	var fc: int = int(_flame_col[here])
	var want: int = _boss_col if cr == arena.boss else int(_col[cr])
	if fc == want:
		return false
	# Wrong colour: the paint just shrugs it off.
	cr.invuln = DEFLECT
	_shrug[cr] = DEFLECT
	var body: Node3D = cr.node.get_node("Body")
	body.scale = body.scale * Vector3(1.25, 0.75, 1.25)
	arena._spawn_sparkles(arena._to3(cr.pos, 0.5), M.PAINTS[want].lightened(0.25))
	_sound(_snd_boink, 1.0 if cr != arena.boss else 0.7, 0.3)
	return true


func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"blob_r":
			return M.blob(0)
		&"blob_y":
			return M.blob(1)
		&"blob_b":
			return M.blob(2)
		&"boss":
			return M.boss()
	return null


func critter_speed(_kind: StringName) -> float:
	return BLOB_SPEED


func critter_hp(_kind: StringName) -> int:
	return 1


func _is_blob(cr: Arena.Critter) -> bool:
	return cr.kind == &"blob_r" or cr.kind == &"blob_y" or cr.kind == &"blob_b"


func critter_step(cr: Arena.Critter) -> Vector2i:
	if not _is_blob(cr) or not _col.has(cr):
		return Vector2i.ZERO
	# Chameleons are drawn to a splat of another colour next to them.
	var options: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		var n: Vector2i = cr.cell + d
		if splats.has(n) and int(splats[n]["idx"]) != int(_col[cr]) and arena._critter_can_enter(cr, n):
			options.append(d)
	if not options.is_empty() and _rng.randf() < 0.45:
		return options[_rng.randi() % options.size()]
	return Vector2i.ZERO


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	var shrug: float = float(_shrug.get(cr, 0.0))
	if cr.kind == &"boss":
		if shrug > 0.0:
			body.visible = true
		var brush: Node3D = body.get_node("Brush")
		brush.rotation.z = -0.45 + sin(t * 2.6) * 0.35
		brush.rotation.x = sin(t * 1.3) * 0.15
		var pal: Node3D = body.get_node("Palette")
		pal.position.y = 0.75 + sin(t * 2.0) * 0.04
		var head: Node3D = body.get_node("Head")
		head.rotation.y = sin(t * 0.9) * 0.25
		head.rotation.z = sin(shrug * 30.0) * 0.12
		return Vector3(1.0, 1.0 + absf(sin(t * 3.4)) * 0.04, 1.0) * M.BOSS_SIZE
	var moving: bool = cr.t < 1.0
	var tail: Node3D = body.get_node("Tail")
	tail.rotation.y = sin(t * (8.0 if moving else 3.0)) * 0.5
	body.position.y = absf(sin(t * 7.0)) * (0.08 if moving else 0.02)
	body.rotation.z = sin(shrug * 28.0) * 0.25
	var sq: float = sin(t * (9.0 if moving else 4.0))
	return Vector3(1.0 + sq * 0.07, 1.0 - sq * 0.09, 1.0 + sq * 0.07)


# --- Every frame ----------------------------------------------------------------------

func process(delta: float) -> void:
	_clock += delta
	_last_stop = NO_CELL
	_track_pods()
	_paint_flames()
	_track_critters(delta)
	_animate(delta)
	if not arena.demo:
		_update_boss(delta)
		_update_balls(delta)


## Remembers the colour of every new pod and paints its band.
func _track_pods() -> void:
	for p: Arena.Pod in arena.pods:
		if not _pod_col.has(p):
			_pod_col[p] = hero_color
		if not _banded.has(p) and is_instance_valid(p.node):
			_banded[p] = true
			var idx: int = int(_pod_col[p])
			if idx != NONE:
				var band: MeshInstance3D = p.node.get_node("Body/Band")
				band.material_override = Models.mat(M.PAINTS[idx], 0.6)
				var spark: MeshInstance3D = p.node.get_node("Body/Spark")
				spark.material_override = Models.mat(M.FLAME_CORE[idx], 2.5)
	for p: Arena.Pod in _pod_col.keys():
		if not arena.pods.has(p):
			_pod_col.erase(p)
			_banded.erase(p)


## Recolours the fresh flames of dyed blasts.
func _paint_flames() -> void:
	for c: Vector2i in _flame_col.keys():
		if not arena.flames.has(c):
			_flame_col.erase(c)
	for f: Dictionary in arena._fx:
		if f["kind"] != &"flame" or f.has("w17"):
			continue
		f["w17"] = true
		var n: Node3D = f["node"]
		if not is_instance_valid(n):
			continue
		var c := Vector2i(roundi(n.position.x), roundi(n.position.z))
		var idx: int = int(_flame_col.get(c, NONE))
		if idx == NONE:
			continue
		var kids: Array[Node] = n.get_children()
		for i in kids.size():
			var mi := kids[i] as MeshInstance3D
			if mi != null:
				mi.material_override = _flame_mats[idx][1 if i == kids.size() - 1 else 0]


func _track_critters(delta: float) -> void:
	for cr: Arena.Critter in _col.keys():
		if not arena.critters.has(cr):
			_col.erase(cr)
			_shrug.erase(cr)
	for cr: Arena.Critter in _shrug.keys():
		_shrug[cr] = maxf(float(_shrug[cr]) - delta, 0.0)
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"boss":
			if not _col.has(cr):
				_col[cr] = _boss_col
				M.tint(cr.node, _boss_col)
			continue
		if not _is_blob(cr):
			continue
		if not _col.has(cr):
			var idx: int = [&"blob_r", &"blob_y", &"blob_b"].find(cr.kind)
			if not _initial.has(cr) and arena.boss != null:
				# Brushbot's helpers come out in its current colour.
				idx = _boss_col
			_col[cr] = idx
			M.tint(cr.node, idx)
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		if splats.has(here) and int(splats[here]["idx"]) != int(_col[cr]):
			var to: int = splats[here]["idx"]
			_col[cr] = to
			M.tint(cr.node, to)
			(cr.node.get_node("Body") as Node3D).scale = Vector3(1.3, 0.7, 1.3)
			arena._spawn_sparkles(arena._to3(cr.pos, 0.4), M.PAINTS[to].lightened(0.2))
			_sound(_snd_splat, 1.5, 0.3, true)


func _animate(delta: float) -> void:
	for c: Vector2i in tubs:
		var tb: Dictionary = tubs[c]
		tb["pulse"] = maxf(float(tb["pulse"]) - delta * 2.5, 0.0)
		var paint: Node3D = (tb["node"] as Node3D).get_node("Paint")
		var pulse: float = float(tb["pulse"])
		paint.position.y = 0.15 + sin(_clock * 3.0 + c.x) * 0.006 + pulse * 0.03
		paint.scale = Vector3(1.0 + sin(pulse * 12.0) * 0.06 * pulse, 1.0, 1.0 + cos(pulse * 12.0) * 0.06 * pulse)
	for c: Vector2i in pcrates:
		var pc: Dictionary = pcrates[c]
		var wob: float = float(pc["wob"])
		if wob > 0.0:
			wob = maxf(wob - delta * 3.0, 0.0)
			pc["wob"] = wob
			var body: Node3D = (pc["node"] as Node3D).get_node("Body")
			body.rotation.z = sin(wob * PI * 4.0) * 0.08 * wob
			body.scale = Vector3(1.0 + wob * 0.06, 1.0 - wob * 0.05, 1.0 + wob * 0.06)
	for c: Vector2i in gates:
		var g: Dictionary = gates[c]
		var panel: Node3D = (g["node"] as Node3D).get_node("Panel")
		if bool(g["open"]) and float(g["a"]) < 1.0:
			g["a"] = minf(float(g["a"]) + delta / GATE_TIME, 1.0)
			var a: float = float(g["a"])
			var e: float = a * a
			panel.rotation.x = lerpf(-0.3, -PI * 0.5, e)
			panel.position.z = lerpf(0.08, 0.43, e)
			if a >= 1.0:
				arena._spawn_sparkles(Vector3(c.x, 0.2, c.y), M.PAINTS[int(g["idx"])].lightened(0.3))
				arena._shake = maxf(arena._shake, 0.12)
		var wob2: float = float(g.get("wob", 0.0))
		if wob2 > 0.0 and not bool(g["open"]):
			wob2 = maxf(wob2 - delta * 3.0, 0.0)
			g["wob"] = wob2
			panel.rotation.x = -0.3 + sin(wob2 * PI * 4.0) * 0.1 * wob2
	for c: Vector2i in splats.keys():
		var sp: Dictionary = splats[c]
		var n: Node3D = sp["node"]
		if float(sp["t"]) < 0.0:
			continue
		sp["t"] = float(sp["t"]) - delta
		var left: float = float(sp["t"])
		var grow: float = minf((SPLAT_LIFE - left) / 0.15, 1.0)
		n.scale = Vector3.ONE * maxf(grow * clampf(left / 0.8, 0.0, 1.0), 0.01)
		if left <= 0.0:
			n.queue_free()
			splats.erase(c)
	if _beret != null:
		_beret_pop = maxf(_beret_pop - delta * 3.0, 0.0)
		_beret.scale = Vector3.ONE * (1.4 + sin(_beret_pop * PI) * 0.6)


func _break_paint_crate(c: Vector2i) -> void:
	var pc: Dictionary = pcrates[c]
	pcrates.erase(c)
	var idx: int = pc["idx"]
	var col: Color = M.PAINTS[idx]
	(pc["node"] as Node3D).queue_free()
	var at := Vector3(c.x, 0.4, c.y)
	var flash := Models.part(arena, Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), col.lightened(0.6), at, 2.0)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena._fx.append({"node": flash, "t": 0.0, "life": 0.12, "kind": &"flash"})
	var chunk := Models.box_mesh(Vector3(0.22, 0.18, 0.22), 0.04)
	var plank := Models.box_mesh(Vector3(0.4, 0.08, 0.12), 0.03)
	for k in 12:
		var color: Color = col if k % 3 != 0 else M.CREAM
		var n := Models.part(arena, plank if k < 7 else chunk, color, at + Vector3(_rng.randf_range(-0.2, 0.2), _rng.randf_range(-0.2, 0.25), _rng.randf_range(-0.2, 0.2)))
		n.rotation = Vector3(_rng.randf() * TAU, _rng.randf() * TAU, _rng.randf() * TAU)
		var a: float = TAU * k / 12.0 + _rng.randf_range(-0.3, 0.3)
		var out: float = _rng.randf_range(2.2, 4.0)
		arena._fx.append({"node": n, "t": 0.0, "life": _rng.randf_range(1.0, 1.3), "kind": &"debris", "floor": 0.06,
			"vel": Vector3(cos(a) * out, _rng.randf_range(3.5, 6.0), sin(a) * out),
			"spin": Vector3(_rng.randf_range(-14, 14), _rng.randf_range(-14, 14), _rng.randf_range(-14, 14))})
	# A stain is left on the cobbles (just paint: it does not recolour blobs).
	var stain := Node3D.new()
	stain.position = Vector3(c.x, 0, c.y)
	stain.rotation.y = _rng.randf() * TAU
	arena.add_child(stain)
	M.splat_shape(stain, col.lerp(Color("#F6E6C8"), 0.35), 0.26, _rng, 0.006)
	Sfx.play(&"crunch", 0.12)
	_sound(_snd_splat, 0.9, 0.2, true)
	arena._shake = maxf(arena._shake, 0.22)
	if not arena.demo:
		Save.buzz(18)


func _open_gate(c: Vector2i) -> void:
	gates[c]["open"] = true
	gates[c]["a"] = 0.0
	arena._spawn_ring(Vector3(c.x, 0.1, c.y), M.PAINTS[int(gates[c]["idx"])], 1.4)
	Sfx.play(&"gate", 0.0)


# --- Brushbot -----------------------------------------------------------------------

func _boss_phase_color(hp: int) -> int:
	if hp >= 7:
		return 0
	if hp >= 5:
		return 1
	if hp >= 3:
		return 2
	return _boss_col


func _update_boss(delta: float) -> void:
	var boss: Arena.Critter = arena.boss
	if boss == null or not arena.critters.has(boss):
		return
	var want: int = _boss_phase_color(boss.hp)
	if boss.hp <= 2:
		if _boss_hp_seen > 2:
			_boss_cycle = 0.0
		_boss_cycle -= delta
		if _boss_cycle <= 0.0:
			_boss_cycle = BOSS_CYCLE
			want = (_boss_col + 1) % 3
	_boss_hp_seen = boss.hp
	if want != _boss_col:
		_boss_col = want
		_col[boss] = want
		M.tint(boss.node, want)
		arena._spawn_ring(arena._to3(boss.pos, 0.1), M.PAINTS[want], 2.2)
		arena._spawn_sparkles(arena._to3(boss.pos, 1.4), M.PAINTS[want].lightened(0.3))
		_sound(_snd_chime, 1.0 + want * 0.12, 0.0, true)


func _update_balls(delta: float) -> void:
	var keep: Array[Dictionary] = []
	for b: Dictionary in _balls:
		b["t"] = float(b["t"]) + delta
		var u: float = float(b["t"]) / BALL_FLIGHT
		var ball: Node3D = b["ball"]
		var ring: Node3D = b["ring"]
		ring.scale = Vector3.ONE * (0.6 + 0.4 * minf(u, 1.0))
		(ring.get_node("Disc") as Node3D).scale = Vector3.ONE * maxf(minf(u, 1.0), 0.01)
		if u >= 1.0:
			ball.queue_free()
			ring.queue_free()
			_land(b["cell"], int(b["idx"]))
			continue
		var from: Vector3 = b["from"]
		var to: Vector3 = b["to"]
		ball.position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 2.6, 0)
		keep.append(b)
	_balls = keep
	var boss: Arena.Critter = arena.boss
	if boss == null or not arena.critters.has(boss) or arena.state != &"play":
		return
	_ball_t -= delta
	if _ball_t > 0.0:
		return
	var hurt: bool = boss.hp <= 4
	_ball_t = BALL_EVERY_HURT if hurt else BALL_EVERY
	var hc: Vector2i = arena.hero_cell()
	var targets: Array[Vector2i] = [hc]
	if hurt:
		var near: Array[Vector2i] = []
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				var c: Vector2i = hc + Vector2i(dx, dz)
				if absi(dx) + absi(dz) >= 2 and absi(dx) + absi(dz) <= 3 and arena.tile(c) == Arena.FLOOR and not blocks(c):
					near.append(c)
		for k in 2:
			if near.is_empty():
				break
			var i: int = _rng.randi() % near.size()
			targets.append(near[i])
			near.remove_at(i)
	for c: Vector2i in targets:
		var ball := M.paint_ball(_boss_col)
		var from := arena._to3(boss.pos, 2.0)
		ball.position = from
		arena.add_child(ball)
		var ring := M.warning(_boss_col)
		ring.position = Vector3(c.x, 0, c.y)
		arena.add_child(ring)
		_balls.append({"ball": ball, "ring": ring, "from": from, "to": Vector3(c.x, 0.15, c.y), "cell": c, "idx": _boss_col, "t": 0.0})
	(boss.node.get_node("Body/Brush") as Node3D).rotation.z = -1.4
	_sound(_snd_splat, 1.6, 0.4)


func _land(c: Vector2i, idx: int) -> void:
	arena._spawn_sparkles(Vector3(c.x, 0.2, c.y), M.PAINTS[idx].lightened(0.2))
	arena._shake = maxf(arena._shake, 0.1)
	_sound(_snd_splat, 1.0)
	if arena.hero_alive and arena.state == &"play" and arena.hero_cell() == c:
		arena._hurt_hero()
	if tubs.has(c) or blocks(c) or arena.tile(c) != Arena.FLOOR:
		return
	if splats.has(c):
		if float(splats[c]["t"]) < 0.0:
			return
		(splats[c]["node"] as Node3D).queue_free()
	var n: Node3D = M.splat(idx, _rng)
	n.position = Vector3(c.x, 0, c.y)
	n.rotation.y = _rng.randf() * TAU
	n.scale = Vector3.ONE * 0.01
	arena.add_child(n)
	splats[c] = {"idx": idx, "node": n, "t": SPLAT_LIFE}


# --- Sound ------------------------------------------------------------------------------

func _sound(s: AudioStreamWAV, pitch: float, jitter: float = 0.0, second: bool = false) -> void:
	var pl: AudioStreamPlayer = _player2 if second else _player
	if pl == null or s == null or not Save.sound_on:
		return
	pl.stream = s
	pl.pitch_scale = pitch * (1.0 + randf_range(-jitter, jitter) * 0.1)
	pl.play()


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


## A rising, bubbly "bloop" for dipping into a paint tub.
func _make_dip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		ph += TAU * (260.0 + 520.0 * (1.0 - exp(-t * 14.0))) / rate
		out[i] = (sin(ph) + 0.3 * sin(ph * 2.0)) * exp(-t * 9.0) * 0.45
	return _wav(out)


## A springy "boing" when paint shrugs off a blast of the wrong colour.
func _make_boink() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 330.0 + 140.0 * sin(t * 48.0) * exp(-t * 6.0) - t * 200.0
		ph += TAU * f / rate
		out[i] = sin(ph) * exp(-t * 7.0) * 0.45
	return _wav(out)


## A dull wooden knock for a paint crate refusing a blast.
func _make_bonk() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.2)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = sin(TAU * 180.0 * t) * exp(-t * 28.0) + sin(TAU * 410.0 * t) * exp(-t * 40.0) * 0.5
		out[i] = (v + randf_range(-1.0, 1.0) * exp(-t * 90.0) * 0.3) * 0.5
	return _wav(out)


## A wet "splotch".
func _make_splat() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		lp = lp * 0.8 + randf_range(-1.0, 1.0) * 0.2
		var blob: float = sin(TAU * (360.0 * exp(-t * 10.0) + 90.0) * t) * exp(-t * 15.0)
		out[i] = (lp * 2.0 * exp(-t * 12.0) + blob * 0.6) * 0.5
	return _wav(out)


## A bright three-note chime for Brushbot repainting itself.
func _make_chime() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var notes: Array[float] = [784.0, 987.8, 1174.7]
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for k in notes.size():
			var t0: float = t - k * 0.08
			if t0 > 0.0:
				v += (sin(TAU * notes[k] * t0) + 0.25 * sin(TAU * notes[k] * 3.0 * t0) * exp(-t0 * 10.0)) * exp(-t0 * 6.0)
		out[i] = v * 0.25
	return _wav(out)

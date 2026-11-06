extends WorldKit
## World 12, Toybox Town: a giant playroom of building blocks, crayons and a
## toy train running round the rim. The twist is springboards (o): step onto
## one and it bounces Pip two tiles on the way he was going, right over a
## block, crate or pod, as long as the landing tile is clear (otherwise he
## just stops on it). Rubber bumpers (/ and \) lie diagonally across their
## tiles and bank kicked pods and blast arms round a corner. Tin Soldiers (t)
## march in step and turn together, and Bonkers the jack-in-the-box pops out
## of his toy boxes (X, and K where he starts) in the boss fight.
##
## Extra level keys: "gift": [x, z, kind] puts a power-up on the floor.

const M := preload("res://worlds/world_12_models.gd")

const HOP_TIME: float = 0.36
const HOP_HEIGHT: float = 0.95
const SOLDIER_SPEED: float = 1.9
const BANK_SPEED: float = 7.5
const NO_CELL := Vector2i(-99, -99)
const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const PALETTE: Dictionary = {
	"GRASS_A": "#FFF1D6", "GRASS_B": "#F8DEB4", "RIM": "#8FD3C8", "EDGE": "#8C7BEA",
	"STONE": "#FFF6E6", "DARK_STONE": "#E5D5BD", "DIRT": "#6FBFB2", "ROCK": "#5AA89C",
	"WOOD": "#4FB6F2", "WOOD_DARK": "#FFF4D6", "BARREL": "#FF5A5F", "ACCENT": "#FFD23F",
	"BLOBBIT": "#FF8FC2", "LEAFY_A": "#7BD38F", "LEAFY_B": "#5CC07A",
	"SKY_TOP": "#9CC8FF", "SKY_HORIZON": "#FFE7F0", "SKY_GROUND": "#E8F1FF", "CLOUD": "#FFFFFF", "CLOUDS": 0.6,
	"AMBIENT": "#C9D6F5", "AMBIENT_ENERGY": 0.55, "SUN": "#FFF2E2", "SUN_ENERGY": 1.5,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Boing Boing Blocks",
		"tip": "Springboards bounce you two tiles,\nright over a wall of blocks!\nThe landing spot must be clear.",
		"crates": 0.4, "par": 65,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.......b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#__o_____o__#",
			"#############",
			"#__o_____o__#",
			"#..t.....t..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bumper Alley",
		"tip": "Grab the kick boot! Rubber bumpers\nbank kicked pods and blasts\nround the corner.",
		"crates": 0.42, "par": 75, "gift": [8, 13, "kick"],
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#/....E....\\#",
			"#.#.#.#.#.#.#",
			"#.t.......t.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#/.........\\#",
			"#.#.#.#.#.#.#",
			"#..b.....b..#",
			"#.#.#.#.#.#.#",
			"#\\........./#",
			"#.#.#_#_#.#.#",
			"#...._S__...#",
			"#############",
		],
	},
	{
		"name": "Tin Soldier Parade",
		"tip": "Tin Soldiers march in step\nand turn together.\nBounce over the crate walls!",
		"crates": 0.38, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#..z..E..b..#",
			"#.#.#.#.#.#.#",
			"#..t.....t..#",
			"#.#...o...#.#",
			"#...ccccc...#",
			"#.#...o...#.#",
			"#.t.......t.#",
			"#.#...o...#.#",
			"#...ccccc...#",
			"#.#...o...#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crayon Canyon",
		"tip": "Spring over the canyon walls.\nBank a blast off a bumper\nto reach round corners!",
		"crates": 0.4, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#/....E....\\#",
			"#.#.#.#.#.#.#",
			"#..z..t..z..#",
			"#.#.#.#.#.#.#",
			"#o....B....o#",
			"#####.#.#####",
			"#o....b....o#",
			"#.#.#.#.#.#.#",
			"#..t.....t..#",
			"#.#.#.#.#.#.#",
			"#\\....B..../#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Train Set Tangle",
		"tip": "Springs, bumpers and a big parade.\nThe only way up is a bounce!",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#/....E....\\#",
			"#.#.#.#.#.#.#",
			"#.z..t.t..z.#",
			"#.#.#.#.#.#.#",
			"#o....B....o#",
			"####.###.####",
			"#o./b...b\\.o#",
			"#.#.#.#.#.#.#",
			"#.t..o.o..t.#",
			"#############",
			"#....o.o....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bonkers' Toy Chest",
		"tip": "Bonkers pops out of his toy boxes!\nWatch for the box that rattles.\nHit him eight times.",
		"crates": 0.25, "par": 120, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...X...X...#",
			"#...........#",
			"#.#...K...#.#",
			"#...........#",
			"#...X...X...#",
			"#.#.......#.#",
			"#...........#",
			"#..cc...cc..#",
			"#.#o.....o#.#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Springboards: Vector2i -> {"node", "bump"}.
var springs: Dictionary = {}
## Rubber bumpers: Vector2i -> {"slash": bool, "node", "bump"}.
var bumpers: Dictionary = {}
## Bonkers' toy boxes, and their nodes (Vector2i -> Node3D).
var boxes: Array[Vector2i] = []
var box_nodes: Dictionary = {}

var _clock: float = 0.0
var _last_cell := NO_CELL
var _hop: Dictionary = {}

# Tap walking that knows about springboards.
var _goal := NO_CELL
var _goal_before := NO_CELL
var _seen_tap: int = -1
var _marker: Node3D
var _marker_goal := NO_CELL
var _marker_t: float = 0.0

# Kicked pods banking off bumpers, and blasts that bank.
var _pod_dir: Dictionary = {}
var _banking: Dictionary = {}
var _pod_seen: Dictionary = {}
var _bank_plans: Array[Dictionary] = []

# The marching squad.
var _squad_dir := Vector2i.ZERO
var _squad_steps: int = 0
var _march_len: int = 5
var _waiting: Dictionary = {}

# Bonkers.
var _bstate: StringName = &"start"
var _bt: float = 0.0
var _bbox: int = 0
var _boss_was: bool = false

# The toy train.
var _cars: Array[Node3D] = []
var _train_s: float = 0.0
var _track_len: float = 1.0

var _player: AudioStreamPlayer
var _snd_boing: AudioStreamWAV
var _snd_rattle: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Toybox Town"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_12.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "BONKERS"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"soldier"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"o":
			springs[c] = {"bump": 0.0}
			return true
		"/":
			bumpers[c] = {"slash": true, "bump": 0.0}
			return true
		"\\":
			bumpers[c] = {"slash": false, "bump": 0.0}
			return true
		"X":
			boxes.append(c)
			return true
	return false


func critter_chars() -> Dictionary:
	return {"t": &"soldier"}


func build_extra() -> void:
	for c: Vector2i in springs:
		var n: Node3D = M.springboard()
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		springs[c]["node"] = n
	for c: Vector2i in bumpers:
		var n: Node3D = M.bumper(bool(bumpers[c]["slash"]))
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		bumpers[c]["node"] = n
	if arena.boss != null:
		boxes.push_front(arena.boss.cell)
	var cols: Array[Color] = [M.RED, M.BLUE, M.GREEN, M.PURPLE, M.ORANGE]
	for i in boxes.size():
		var b: Node3D = M.toy_box(cols[i % cols.size()])
		b.position = Vector3(boxes[i].x, 0, boxes[i].y)
		arena.add_child(b)
		box_nodes[boxes[i]] = b
	_build_train()
	if not arena.demo:
		var gift: Array = arena.data.get("gift", [])
		if gift.size() == 3:
			arena._spawn_pickup(Vector2i(int(gift[0]), int(gift[1])), StringName(gift[2]))
		if arena._marker != null:
			# Pip's walk marker shows the tapped goal even while he hops
			# from springboard to springboard on his way there.
			_marker = arena._marker
			var stand_in := Node3D.new()
			arena.add_child(stand_in)
			arena._marker = stand_in
		var hud: Variant = _hud()
		if hud != null:
			_seen_tap = int(hud.get("_last_tap_ms"))
		_last_cell = arena.hero_cell()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -5.0
	arena.add_child(_player)
	_snd_boing = _make_boing()
	_snd_rattle = _make_rattle()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Toy blocks (some stacked two high) and crayons lying on the wall.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var sets: Dictionary = {}
	var top: float = 0.69
	for tf in blocks:
		var roll: float = r.randf()
		var base := Vector3(tf.origin.x, top, tf.origin.z)
		if roll < 0.42:
			var s: float = r.randf_range(0.3, 0.38)
			var yaw := Basis(Vector3.UP, r.randf_range(-0.5, 0.5))
			var c: Color = M.BLOCKS[r.randi() % M.BLOCKS.size()]
			_add(sets, "block", c, Transform3D(yaw.scaled(Vector3.ONE * s / 0.34), base + Vector3(r.randf_range(-0.12, 0.12), s * 0.5, r.randf_range(-0.12, 0.12))))
			if r.randf() < 0.3:
				var c2: Color = M.BLOCKS[r.randi() % M.BLOCKS.size()]
				var s2: float = s * 0.7
				_add(sets, "block", c2, Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * s2 / 0.34), base + Vector3(0, s + s2 * 0.5, 0)))
		elif roll < 0.6:
			var c3: Color = M.BLOCKS[r.randi() % M.BLOCKS.size()]
			var yaw2: float = r.randf() * TAU
			var lay := Basis(Vector3.UP, yaw2) * Basis(Vector3.FORWARD, PI * 0.5)
			var at := base + Vector3(r.randf_range(-0.08, 0.08), 0.06, r.randf_range(-0.08, 0.08))
			_add(sets, "crayon", c3, Transform3D(lay, at))
			_add(sets, "wrap", M.CREAM, Transform3D(lay, at + lay * Vector3(0, -0.04, 0)))
			_add(sets, "tip", c3, Transform3D(lay, at + lay * Vector3(0, 0.27, 0)))
	var cm: Array[Mesh] = M.crayon_meshes()
	var meshes := {"block": Models.box_mesh(Vector3(0.34, 0.34, 0.34), 0.05), "crayon": cm[0], "wrap": cm[1], "tip": cm[2]}
	for key: Array in sets:
		var list: Array[Transform3D] = []
		list.assign(sets[key])
		arena._multimesh(meshes[key[0]], key[1], list)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Stacked toy blocks: a big block, a smaller one turned on top and now
	# and then a little roof or a ball, each block with a cream star face.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var sets: Dictionary = {}
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var ci: int = (roundi(p.x) * 3 + roundi(p.z) * 5) % M.BLOCKS.size()
		var cj: int = (ci + 1 + r.randi() % (M.BLOCKS.size() - 1)) % M.BLOCKS.size()
		_add(sets, "low", M.BLOCKS[ci], Transform3D(Basis(Vector3.UP, r.randf_range(-0.05, 0.05)), p + Vector3(0, 0.29, 0)))
		_add(sets, "face", M.CREAM, Transform3D(Basis(), p + Vector3(0, 0.29, 0.405)))
		var turn := Basis(Vector3.UP, r.randf_range(-0.6, 0.6))
		_add(sets, "high", M.BLOCKS[cj], Transform3D(turn, p + Vector3(0, 0.75, 0)))
		var roll: float = r.randf()
		if roll < 0.3:
			_add(sets, "roof", M.BLOCKS[(cj + 2) % M.BLOCKS.size()], Transform3D(turn, p + Vector3(0, 0.95, 0)))
		elif roll < 0.5:
			_add(sets, "ball", M.CREAM, Transform3D(Basis(), p + Vector3(0, 1.0, 0)))
	var roof := Models.cylinder(0.0, 0.22, 0.2, 4)
	var meshes := {"low": Models.box_mesh(Vector3(0.8, 0.58, 0.8), 0.08), "high": Models.box_mesh(Vector3(0.46, 0.34, 0.46), 0.06),
		"face": M.star_mesh(0.15, 0.03), "roof": roof, "ball": Models.sphere(0.1, -1, 12)}
	for key: Array in sets:
		var list: Array[Transform3D] = []
		list.assign(sets[key])
		arena._multimesh(meshes[key[0]], key[1], list)
	return true


func rim_prop(_p: Vector3, _r: RandomNumberGenerator, _near_side: bool) -> Node3D:
	# The rim is the toy train's track.
	return Node3D.new()


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var stack: Node3D = M.block_stack(r, 1.6, 3)
	stack.position = Vector3(-size * 0.12, 0, -size * 0.08)
	root.add_child(stack)
	var other: Node3D
	match r.randi() % 3:
		0:
			other = M.ring_stacker(1.3)
		1:
			other = M.duck(1.2)
		_:
			other = M.crayon_cup(r)
	other.position = Vector3(size * 0.24, 0, size * 0.18)
	root.add_child(other)
	return root


func tune_environment(env: Environment, _sun: DirectionalLight3D) -> void:
	env.adjustment_saturation = 1.1


## The train track round the rim and the train itself: an engine and three
## wagons that potter round and round.
func _build_train() -> void:
	var x0: float = -1.0
	var x1: float = float(Arena.W)
	var z0: float = -1.0
	var z1: float = float(Arena.H)
	_track_len = 2.0 * (x1 - x0) + 2.0 * (z1 - z0) - 8.0 * 0.6 + TAU * 0.6
	var ties: Array[Transform3D] = []
	var rails: Array[Transform3D] = []
	var s: float = 0.0
	while s < _track_len:
		var a: Array = _track_at(s)
		var p: Vector3 = a[0]
		var yaw: float = a[1]
		var b := Basis(Vector3.UP, yaw)
		if fmod(s, 0.36) < 0.18:
			ties.append(Transform3D(b, p + Vector3(0, 0.02, 0)))
		for side: float in [-0.13, 0.13]:
			rails.append(Transform3D(b, p + b * Vector3(0, 0.055, side)))
		s += 0.18
	arena._multimesh(Models.box_mesh(Vector3(0.12, 0.05, 0.42), 0.015), Color("#B98563"), ties)
	arena._multimesh(Models.box_mesh(Vector3(0.2, 0.04, 0.035), 0.01), Color("#C9CEE6"), rails)
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 5
	_cars.append(M.engine())
	for k in 3:
		_cars.append(M.wagon(r))
	for n: Node3D in _cars:
		n.scale = Vector3.ONE * 0.9
		arena.add_child(n)
	_train_s = r.randf() * _track_len
	_place_train()


## Point and heading at distance [param s] round the track (a rectangle on
## the rim with rounded corners, running clockwise on screen).
func _track_at(s: float) -> Array:
	var rr: float = 0.6
	var x0: float = -1.0
	var x1: float = float(Arena.W)
	var z0: float = -1.0
	var z1: float = float(Arena.H)
	var corners: Array[Vector2] = [Vector2(x1, z0), Vector2(x1, z1), Vector2(x0, z1), Vector2(x0, z0)]
	var dirs: Array[Vector2] = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	var starts: Array[Vector2] = [Vector2(x0 + rr, z0), Vector2(x1, z0 + rr), Vector2(x1 - rr, z1), Vector2(x0, z1 - rr)]
	s = fposmod(s, _track_len)
	for i in 4:
		var seg: float = (corners[i] - starts[i]).length() - rr
		if s < seg:
			var p2: Vector2 = starts[i] + dirs[i] * s
			return [Vector3(p2.x, 0, p2.y), atan2(-dirs[i].y, dirs[i].x)]
		s -= seg
		var arc: float = PI * 0.5 * rr
		if s < arc:
			var u: float = s / arc
			var d0: Vector2 = dirs[i]
			var d1: Vector2 = dirs[(i + 1) % 4]
			var centre: Vector2 = corners[i] - d0 * rr + d1 * rr
			var ang: float = u * PI * 0.5
			var p3: Vector2 = centre - d1 * rr * cos(ang) + d0 * rr * sin(ang)
			var h: Vector2 = d0 * cos(ang) + d1 * sin(ang)
			return [Vector3(p3.x, 0, p3.y), atan2(-h.y, h.x)]
		s -= arc
	return [Vector3(x0, 0, z0), 0.0]


func _place_train() -> void:
	for k in _cars.size():
		var a: Array = _track_at(_train_s - k * 0.62)
		_cars[k].position = a[0]
		_cars[k].rotation.y = a[1]


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return bumpers.has(c) or box_nodes.has(c)


func flame_stop(c: Vector2i) -> int:
	if bumpers.has(c):
		return 2
	if box_nodes.has(c):
		return 1
	return 0


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not bumpers.has(c) and not box_nodes.has(c)


func on_hero_enter(c: Vector2i) -> void:
	if not _hop.is_empty() or arena.state != &"play":
		return
	var d: Vector2i = c - _last_cell
	if not springs.has(c) or absi(d.x) + absi(d.y) != 1:
		return
	var land: Vector2i = c + d * 2
	if not _landing_free(land, true):
		return
	_hop = {"from": arena.hero_pos, "to": land, "t": 0.0, "spring": c}
	arena.hero_pos = Vector2(land)
	arena.walk_goal = Arena.NO_CELL
	_last_cell = land
	springs[c]["bump"] = 1.0
	_sound(_snd_boing, 1.0 + arena.rng.randf_range(-0.05, 0.05))
	(arena.hero.get_node("Body") as Node3D).scale = Vector3(0.8, 1.3, 0.8)


## True when Pip may land on [param c]: an open floor tile with no pod,
## flame or critter on it (or about to step onto it, when [param live]).
func _landing_free(c: Vector2i, live: bool) -> bool:
	if c.x < 1 or c.y < 1 or c.x > Arena.W - 2 or c.y > Arena.H - 2:
		return false
	if arena.tile(c) != Arena.FLOOR or blocks(c) or arena.pod_at.has(c):
		return false
	if live:
		if arena.flames.has(c):
			return false
		for cr: Arena.Critter in arena.critters:
			if kit_hidden(cr):
				continue
			if cr.pos.distance_to(Vector2(c)) < 1.1 or cr.target == c:
				return false
	return true


func kit_hidden(cr: Arena.Critter) -> bool:
	return critter_hidden(cr)


func on_flame(c: Vector2i) -> void:
	# A pod has just gone off here: plan the arms that will bank off
	# bumpers (worked out now, before the blast changes the board).
	for p: Arena.Pod in _pod_seen.keys():
		if arena.pods.has(p):
			continue
		_pod_seen.erase(p)
		if p.cell == c:
			_plan_banks(c, p.fire)


func on_explode(c: Vector2i) -> void:
	var keep: Array[Dictionary] = []
	for plan: Dictionary in _bank_plans:
		if plan["centre"] == c:
			_bank_arm(plan["at"], plan["dir"], int(plan["rest"]), int(plan["dist"]), 0)
		else:
			keep.append(plan)
	_bank_plans = keep


static func deflect(d: Vector2i, slash: bool) -> Vector2i:
	return Vector2i(-d.y, -d.x) if slash else Vector2i(d.y, d.x)


func _plan_banks(c: Vector2i, reach: int) -> void:
	for d: Vector2i in DIRS4:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			var t: int = arena.tile(cc)
			if t == Arena.WALL:
				break
			if bumpers.has(cc):
				if reach - i > 0:
					_bank_plans.append({"centre": c, "at": cc, "dir": d, "rest": reach - i, "dist": i})
				break
			if flame_stop(cc) != 0 or t == Arena.CRATE or t == Arena.BARREL or arena.pod_at.has(cc):
				break


## A blast arm that hit the bumper at [param at] going [param d] carries
## on round the corner for [param rest] more tiles.
func _bank_arm(at: Vector2i, d: Vector2i, rest: int, dist: int, depth: int) -> void:
	var bm: Dictionary = bumpers[at]
	bm["bump"] = 1.0
	arena._add_flame(at, dist, d)
	var nd: Vector2i = deflect(d, bool(bm["slash"]))
	for k in range(1, rest + 1):
		var n: Vector2i = at + nd * k
		var t: int = arena.tile(n)
		if t == Arena.WALL:
			break
		if bumpers.has(n):
			if depth < 3 and rest - k > 0:
				_bank_arm(n, nd, rest - k, dist + k, depth + 1)
			break
		var own: int = flame_stop(n)
		if own == 2:
			break
		arena._add_flame(n, dist + k, nd)
		if own == 1:
			break
		if t == Arena.CRATE:
			arena._break_crate(n)
			break
		if t == Arena.BARREL:
			arena._ignite_barrel(n)
			break
		if arena.pod_at.has(n):
			var other: Arena.Pod = arena.pod_at[n]
			other.timer = minf(other.timer, 0.06)
			break
	_sound(_snd_boing, 0.8)


# --- Every frame --------------------------------------------------------------------------

func process(delta: float) -> void:
	_clock += delta
	_animate_tiles(delta)
	_train_s += delta * 1.4
	_place_train()
	if arena.demo or arena.hero == null:
		return
	_update_hop(delta)
	_drive_taps()
	_update_marker(delta)
	_update_pods(delta)
	_update_squad()
	_update_boss(delta)
	if _hop.is_empty():
		_last_cell = arena.hero_cell()
		_lift_on_spring()


func _animate_tiles(delta: float) -> void:
	for c: Vector2i in springs:
		var s: Dictionary = springs[c]
		var b: float = maxf(float(s["bump"]) - delta * 2.4, 0.0)
		s["bump"] = b
		var n: Node3D = s["node"]
		var squash: float = sin(b * PI * 2.0) * b
		(n.get_node("Pad") as Node3D).position.y = 0.2 + squash * 0.09
		(n.get_node("Coil") as Node3D).scale = Vector3(1.0, 1.0 + squash * 0.6, 1.0)
	for c: Vector2i in bumpers:
		var bm: Dictionary = bumpers[c]
		var b2: float = maxf(float(bm["bump"]) - delta * 3.0, 0.0)
		bm["bump"] = b2
		var band: Node3D = (bm["node"] as Node3D).get_node("Band")
		var w: float = sin(b2 * PI * 4.0) * b2
		band.scale = Vector3(1.0 - w * 0.08, 1.0 + w * 0.12, 1.0 + w * 0.6)


## Pip stands on top of a springboard's pad when he stops on one.
func _lift_on_spring() -> void:
	var hero: Node3D = arena.hero
	var c: Vector2i = arena.hero_cell()
	var lift: float = 0.0
	if springs.has(c):
		lift = 0.21 * clampf(1.6 - arena.hero_pos.distance_to(Vector2(c)) * 3.2, 0.0, 1.0)
	hero.position.y = lift
	(hero.get_node("Shadow") as Node3D).position.y = 0.025 - lift + (0.22 if lift > 0.0 else 0.0)


func _update_hop(delta: float) -> void:
	if _hop.is_empty():
		return
	var hero: Node3D = arena.hero
	var body: Node3D = hero.get_node("Body")
	var shadow: Node3D = hero.get_node("Shadow")
	if arena.state != &"play" or not arena.hero_alive:
		_hop.clear()
		body.rotation.y = 0.0
		shadow.position.y = 0.025
		return
	_hop["t"] = float(_hop["t"]) + delta
	var u: float = clampf(float(_hop["t"]) / HOP_TIME, 0.0, 1.0)
	var to: Vector2i = _hop["to"]
	# Pip cannot steer in the air.
	arena.hero_pos = Vector2(to)
	arena.walk_goal = Arena.NO_CELL
	var from: Vector2 = _hop["from"]
	var at: Vector2 = from.lerp(Vector2(to), u)
	var y: float = sin(u * PI) * HOP_HEIGHT
	hero.position = Vector3(at.x, y, at.y)
	shadow.position.y = 0.025 - y
	shadow.scale = Vector3.ONE * (1.0 - y * 0.4)
	body.rotation.y = u * TAU
	body.rotation.x = 0.0
	var st: float = sin(u * PI)
	body.scale = Vector3(1.0 - st * 0.12, 1.0 + st * 0.2, 1.0 - st * 0.12)
	if u >= 1.0:
		_hop.clear()
		body.rotation.y = 0.0
		body.scale = Vector3(1.3, 0.7, 1.3)
		shadow.position.y = 0.025
		shadow.scale = Vector3.ONE
		hero.position = Vector3(to.x, 0.0, to.y)
		arena._spawn_ring(Vector3(to.x, 0.05, to.y), Color("#FFF3B0"), 0.6)
		_last_cell = to


# --- Tap walking with springboards --------------------------------------------------------

func _hud() -> Variant:
	var main: Node = arena.get_parent()
	if main == null:
		return null
	return main.get("hud")


## The arena's own tap walking does not know springboards, so in this
## world a fresh tap is planned here (bounces included) and Pip is led
## along it one tile at a time.
func _drive_taps() -> void:
	var hud: Variant = _hud()
	if hud != null and is_instance_valid(hud):
		var ms: int = int(hud.get("_last_tap_ms"))
		if ms != _seen_tap:
			_seen_tap = ms
			if ms > 0:
				_goal_before = _goal
				var pos: Vector2 = hud.get("_last_tap_pos")
				var tc: Vector2i = arena.cell_at_screen(pos)
				_goal = _pick_goal(tc) if tc != Arena.NO_CELL else NO_CELL
			else:
				# The second tap of a double tap drops a pod and carries on
				# to wherever Pip was heading before.
				_goal = _goal_before
	if _goal == NO_CELL:
		return
	if arena.state != &"play" or not arena.hero_alive or arena.input_primary != Vector2i.ZERO:
		_goal = NO_CELL
		return
	if not _hop.is_empty():
		return
	var here: Vector2i = arena.hero_cell()
	if here == _goal:
		arena.walk_goal = _goal
		_goal = NO_CELL
		return
	var step: Vector2i = _next_waypoint(here, _goal, true, false)
	if step == NO_CELL and arena.can_kick:
		step = _next_waypoint(here, _goal, true, true)
	if step == NO_CELL:
		step = _next_waypoint(here, _goal, false, true)
		if step != NO_CELL and (arena.flames.has(step) or (arena.pod_at.has(step) and not arena.can_kick)):
			step = NO_CELL
	if step == NO_CELL:
		# The way is shut for now (a flame or a pod): wait in the middle of
		# the tile.
		arena.walk_goal = here
		return
	if springs.has(step):
		# A bounce on the way: wait here until its landing tile is clear
		# (a critter on it, say) rather than stop on the spring.
		var d: Vector2i = step - here
		var land: Vector2i = step + d * 2
		if _landing_free(land, false) and not _landing_free(land, true):
			arena.walk_goal = here
			return
	arena.walk_goal = step


## The reachable tile closest to the tapped one, counting bounces.
func _pick_goal(tap: Vector2i) -> Vector2i:
	var r: Dictionary = _search(arena.hero_cell(), false, true)
	var dist: Dictionary = r["dist"]
	var best: Vector2i = arena.hero_cell()
	var best_score: int = 1 << 30
	for cell: Vector2i in dist:
		var score: int = (absi(cell.x - tap.x) + absi(cell.y - tap.y)) * 1000 + int(dist[cell])
		if score < best_score:
			best_score = score
			best = cell
	return best


## The next tile to walk onto (a springboard, for a bounce) on the way
## from [param from] to [param goal], or NO_CELL.
func _next_waypoint(from: Vector2i, goal: Vector2i, strict: bool, through_pods: bool) -> Vector2i:
	var r: Dictionary = _search(from, strict, through_pods)
	var first: Dictionary = r["first"]
	return first.get(goal, NO_CELL)


## Breadth-first search over the tiles Pip can walk, where stepping onto a
## springboard with a clear landing lands two tiles on. Gives {"first":
## {tile: first waypoint}, "dist": {tile: steps}}.
func _search(start: Vector2i, strict: bool, through_pods: bool) -> Dictionary:
	var first: Dictionary = {start: NO_CELL}
	var dist: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d: Vector2i in DIRS4:
			var n: Vector2i = c + d
			if not arena._hero_can_walk(n, strict, through_pods):
				continue
			var arrive: Vector2i = n
			if springs.has(n) and _landing_free(n + d * 2, false) and (not strict or not arena.flames.has(n + d * 2)):
				arrive = n + d * 2
			if first.has(arrive):
				continue
			first[arrive] = n if c == start else first[c]
			dist[arrive] = int(dist[c]) + (2 if arrive != n else 1)
			queue.append(arrive)
	return {"first": first, "dist": dist}


func _update_marker(delta: float) -> void:
	if _marker == null:
		return
	var g: Vector2i = _goal if _goal != NO_CELL else arena.walk_goal
	if g == NO_CELL:
		g = Arena.NO_CELL
	if g != _marker_goal:
		_marker_goal = g
		_marker_t = 0.0
	_marker_t += delta
	var show: bool = arena.state == &"play" and g != Arena.NO_CELL and g != arena.hero_cell()
	_marker.visible = show
	if show:
		_marker.position = Vector3(g.x, 0.0, g.y)
		var pop: float = 1.0 + 0.5 * exp(-_marker_t * 9.0)
		_marker.scale = Vector3.ONE * pop * (1.0 + sin(_clock * 5.0) * 0.06)
		_marker.rotation.y += delta * 1.2


# --- Kicked pods and bumpers ----------------------------------------------------------------

func _update_pods(delta: float) -> void:
	for p: Arena.Pod in arena.pods:
		_pod_seen[p] = true
	for p: Arena.Pod in _banking.keys():
		if not arena.pods.has(p):
			_banking.erase(p)
			continue
		var b: Dictionary = _banking[p]
		var target := Vector2(b["at"])
		p.pos = p.pos.move_toward(target, BANK_SPEED * delta)
		p.node.position = arena._to3(p.pos)
		if p.pos.distance_to(target) < 0.001:
			_banking.erase(p)
			p.slide = b["dir"]
			p.kicked = true
			p.slide_speed = Arena.KICK_SPEED
	for p: Arena.Pod in arena.pods:
		if _banking.has(p):
			continue
		if p.slide != Vector2i.ZERO:
			_pod_dir[p] = p.slide
			continue
		if _pod_dir.has(p):
			var d: Vector2i = _pod_dir[p]
			_pod_dir.erase(p)
			_try_bank(p, d)
			continue
		# Pip kicking a pod that sits right against a bumper.
		if arena.can_kick and arena.hero_alive and not arena.hero_pass.has(p):
			var push: Vector2i = arena.input_primary
			if push == Vector2i.ZERO and arena.walk_goal != Arena.NO_CELL:
				push = arena.walk_goal - arena.hero_cell()
			if absi(push.x) + absi(push.y) == 1 and arena.hero_cell() + push == p.cell and bumpers.has(p.cell + push):
				var off: float = absf(arena.hero_pos.x - arena.hero_cell().x) + absf(arena.hero_pos.y - arena.hero_cell().y)
				if off < 0.08:
					if _try_bank(p, push):
						Sfx.play(&"kick")
	for p: Arena.Pod in _pod_dir.keys():
		if not arena.pods.has(p):
			_pod_dir.erase(p)


## Sends pod [param p] (stopped against something, last heading [param d])
## round the bumper in front of it, if there is one and the way out is
## clear.
func _try_bank(p: Arena.Pod, d: Vector2i) -> bool:
	var at: Vector2i = p.cell + d
	if not bumpers.has(at):
		return false
	var bm: Dictionary = bumpers[at]
	var nd: Vector2i = deflect(d, bool(bm["slash"]))
	if arena._pod_blocked(at + nd):
		return false
	if arena.pod_at.get(p.cell) == p:
		arena.pod_at.erase(p.cell)
	arena.hero_pass.erase(p)
	p.cell = at
	arena.pod_at[at] = p
	p.slide = Vector2i.ZERO
	_banking[p] = {"at": at, "dir": nd}
	bm["bump"] = 1.0
	_sound(_snd_boing, 1.25)
	return true


# --- Critters -----------------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"soldier":
			return M.soldier()
		&"blobbit":
			return M.ball()
		&"buzzer":
			return M.plane()
		&"boss":
			return M.jack()
	return null


func critter_speed(kind: StringName) -> float:
	return SOLDIER_SPEED if kind == &"soldier" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_hidden(cr: Arena.Critter) -> bool:
	if cr.kind != &"boss":
		return false
	match _bstate:
		&"out":
			return false
		&"up":
			return _bt < 0.12
		&"down":
			return _bt > 0.12
	return true


## Tin Soldiers all march the same way, one tile per beat. A soldier whose
## way is blocked marks time; when most of the squad is stuck, or after a
## few steps, they all turn together (preferring the way to Pip).
func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"soldier":
		return Vector2i.ZERO
	if _squad_dir == Vector2i.ZERO:
		_turn_squad(true)
	if _lead() == cr:
		_squad_steps += 1
		if _squad_steps > _march_len:
			_turn_squad(false)
	if _can_march(cr, _squad_dir):
		return _squad_dir
	if _stuck_share() >= 0.5:
		_turn_squad(false)
		if _can_march(cr, _squad_dir):
			return _squad_dir
	_waiting[cr] = true
	return Vector2i.ZERO


func _lead() -> Arena.Critter:
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"soldier":
			return cr
	return null


func _can_march(cr: Arena.Critter, d: Vector2i) -> bool:
	var to: Vector2i = cr.cell + d
	if not arena._critter_can_enter(cr, to):
		return false
	for other: Arena.Critter in arena.critters:
		if other != cr and (other.cell == to or other.target == to) and other.kind == &"soldier":
			return false
	if not arena.demo:
		var danger: Dictionary = arena._danger_cells()
		if danger.has(to) and not danger.has(cr.cell):
			return false
	return true


func _stuck_share() -> float:
	var n: int = 0
	var stuck: int = 0
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"soldier":
			continue
		n += 1
		if not arena._critter_can_enter(cr, cr.cell + _squad_dir):
			stuck += 1
	return float(stuck) / float(maxi(n, 1))


func _turn_squad(any: bool) -> void:
	var soldiers: Array[Arena.Critter] = []
	var centre := Vector2.ZERO
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"soldier":
			soldiers.append(cr)
			centre += Vector2(cr.cell)
	if soldiers.is_empty():
		return
	centre /= soldiers.size()
	var to_pip := Vector2.ZERO
	if not arena.demo and arena.hero_alive:
		to_pip = (arena.hero_pos - centre).normalized()
	var best := _squad_dir
	var best_score: float = -1e9
	for d: Vector2i in DIRS4:
		if not any and d == _squad_dir:
			continue
		var movers: int = 0
		for cr: Arena.Critter in soldiers:
			if arena._critter_can_enter(cr, cr.cell + d):
				movers += 1
		var score: float = movers * 10.0 + Vector2(d).dot(to_pip) * 7.0 + arena.rng.randf() * 4.0
		if d == -_squad_dir:
			score -= 6.0
		if score > best_score:
			best_score = score
			best = d
	_squad_dir = best
	_squad_steps = 0
	_march_len = arena.rng.randi_range(4, 7)
	for cr: Arena.Critter in soldiers:
		var body: Node3D = cr.node.get_node("Body")
		body.scale = Vector3(1.15, 0.85, 1.15)


func _update_squad() -> void:
	for cr: Arena.Critter in _waiting.keys():
		_waiting.erase(cr)
		if not arena.critters.has(cr):
			continue
		# Mark time on the spot for one beat, facing the squad's way.
		cr.target = cr.cell
		cr.t = 0.0
		cr.pos = Vector2(cr.cell)
		cr.dir = _squad_dir
		cr.node.set_meta(&"marking", 1.0 / SOLDIER_SPEED)


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"soldier":
			var mark: float = float(cr.node.get_meta(&"marking", 0.0))
			if mark > 0.0:
				cr.node.set_meta(&"marking", mark - delta)
			var moving: bool = cr.t < 1.0
			var ph: float = cr.t * PI * 2.0 if mark <= 0.0 else t * 11.0
			var swing: float = sin(ph) * (0.6 if moving else 0.0)
			(body.get_node("LegL") as Node3D).rotation.x = swing
			(body.get_node("LegR") as Node3D).rotation.x = -swing
			(body.get_node("ArmL") as Node3D).rotation.x = -swing * 0.8
			(body.get_node("ArmR") as Node3D).rotation.x = swing * 0.8
			(body.get_node("Key") as Node3D).rotation.z += delta * 6.0
			body.position.y = absf(sin(ph)) * 0.05
			body.rotation.z = sin(ph) * 0.05
			return Vector3.ONE * 1.3
		&"blobbit":
			var ball: Node3D = body.get_node("Ball")
			var h: float = absf(sin(t * 5.0))
			ball.position.y = 0.32 + h * 0.3
			ball.rotation.x += delta * 4.0
			var sq: float = clampf(1.0 - h * 4.0, 0.0, 1.0) * 0.18
			return Vector3(1.0 + sq, 1.0 - sq, 1.0 + sq)
		&"buzzer":
			(body.get_node("Prop") as Node3D).rotation.z += delta * 30.0
			body.position.y = sin(t * 4.0) * 0.07
			body.rotation.z = sin(t * 2.0) * 0.15
			return Vector3.ONE
		&"boss":
			return _pose_boss(cr, body, t)
	return Vector3.ONE


# --- Bonkers -----------------------------------------------------------------------------

## Bonkers sits in one toy box at a time: the next box rattles, he springs
## out, stays up for a few seconds (the only time blasts can reach him),
## ducks back in and moves on. A hit sends him straight back down.
func _update_boss(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null:
		if _boss_was:
			_boss_was = false
			for c: Vector2i in box_nodes:
				var lid: Node3D = (box_nodes[c] as Node3D).get_node("Box/Lid")
				lid.rotation.x = -1.9
				arena._spawn_sparkles(Vector3(c.x, 0.8, c.y), M.YELLOW)
		return
	_boss_was = true
	var box: Vector2i = boxes[_bbox]
	b.cell = box
	b.target = box
	b.t = 1.0
	b.pos = Vector2(box)
	b.speed = 0.0
	b.dir = Vector2i(0, 1)
	b.node.position = Vector3(box.x, 0, box.y)
	_bt += delta
	var hurt: bool = b.hp * 2 <= arena.boss_max_hp
	match _bstate:
		&"start":
			if _bt > 1.2:
				_set_bstate(&"warn")
		&"warn":
			if _bt > (1.0 if hurt else 1.3):
				_set_bstate(&"up")
				arena._spawn_ring(Vector3(box.x, 0.75, box.y), M.YELLOW, 0.8)
				_sound(_snd_boing, 0.7)
		&"up":
			if _bt > 0.25:
				_set_bstate(&"out")
		&"out":
			if _bt > (2.6 if hurt else 3.4):
				_set_bstate(&"down")
		&"down":
			if _bt > 0.3:
				_set_bstate(&"hidden")
		&"hidden":
			if _bt > 0.6:
				_next_box()
				_set_bstate(&"warn")
				_sound(_snd_rattle, 1.0)
	for i in boxes.size():
		var n: Node3D = box_nodes[boxes[i]]
		var shell: Node3D = n.get_node("Box")
		var lid2: Node3D = shell.get_node("Lid")
		var crank: Node3D = shell.get_node("Crank")
		var mine: bool = i == _bbox
		var open: float = 0.0
		if mine:
			match _bstate:
				&"up":
					open = clampf(_bt / 0.12, 0.0, 1.0)
				&"out":
					open = 1.0
				&"down":
					open = clampf(1.0 - (_bt - 0.15) / 0.15, 0.0, 1.0)
		var rattle: bool = mine and _bstate == &"warn"
		shell.rotation.z = sin(_clock * 40.0) * 0.06 if rattle else 0.0
		shell.position.y = absf(sin(_clock * 20.0)) * 0.05 if rattle else 0.0
		lid2.rotation.x = -1.9 * open - (absf(sin(_clock * 24.0)) * 0.25 if rattle else 0.0)
		if rattle:
			crank.rotation.x += delta * 14.0


func _set_bstate(s: StringName) -> void:
	_bstate = s
	_bt = 0.0


func _next_box() -> void:
	if boxes.size() < 2:
		return
	var pick: Array[int] = []
	for i in boxes.size():
		if i == _bbox:
			continue
		# Not the box Pip is standing right next to.
		var c: Vector2i = boxes[i]
		if arena.hero_alive and arena.hero_cell().distance_to(c) < 1.5:
			continue
		pick.append(i)
	if pick.is_empty():
		pick.append((_bbox + 1) % boxes.size())
	_bbox = pick[arena.rng.randi() % pick.size()]


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind == &"boss" and _bstate == &"out" and cr.invuln <= 0.0:
		# Ouch: a moment to see it land, then back into the box.
		_bt = maxf(_bt, (2.6 if cr.hp * 2 <= arena.boss_max_hp else 3.4) - 0.35)
		arena._spawn_sparkles(Vector3(cr.pos.x, 1.4, cr.pos.y), M.YELLOW)
	return false


func _pose_boss(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	var up: float = 0.0
	match _bstate:
		&"up":
			var u: float = clampf(_bt / 0.25, 0.0, 1.0)
			up = 1.0 + sin(u * PI) * 0.25 if u > 0.6 else u / 0.6
		&"out":
			up = 1.0
		&"down":
			up = 1.0 - clampf(_bt / 0.3, 0.0, 1.0)
	body.visible = body.visible and up > 0.05
	body.position.y = lerpf(-1.05 * M.BOSS_SIZE, 0.0, up) + (sin(t * 6.0) * 0.04 if _bstate == &"out" else 0.0)
	var head: Node3D = body.get_node("Head")
	head.rotation.z = sin(t * 3.4) * 0.16 * up
	head.rotation.x = sin(t * 2.3) * 0.08 * up
	var coil: Node3D = body.get_node("Coil")
	coil.scale = Vector3(1.0, 0.6 + 0.4 * up + sin(t * 6.0) * 0.05, 1.0)
	var eyes: Node3D = head.get_node("Eyes")
	eyes.scale = Vector3(1.0, 0.15 if fmod(t, 3.1) < 0.12 else 1.0, 1.0)
	if cr.hp * 2 <= arena.boss_max_hp:
		(head.get_node("Nose") as Node3D).scale = Vector3.ONE * (1.0 + absf(sin(t * 8.0)) * 0.25)
	return Vector3.ONE * M.BOSS_SIZE


# --- Sound --------------------------------------------------------------------------------

func _sound(s: AudioStreamWAV, pitch: float) -> void:
	if _player == null or s == null or not Save.sound_on or arena.demo:
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


## A rubbery "boi-oing": a pitch that bends up and wobbles.
func _make_boing() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 180.0 + 520.0 * (1.0 - exp(-t * 14.0)) + sin(TAU * 18.0 * t) * 60.0 * exp(-t * 4.0)
		phase += TAU * f / rate
		var env: float = minf(t / 0.004, 1.0) * exp(-t * 7.0)
		out[i] = (sin(phase) * 0.8 + sin(phase * 2.0) * 0.15) * env * 0.5
	return _wav(out)


## A wooden clackety rattle from a toy box about to pop.
func _make_rattle() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var k: float = fmod(t, 0.07)
		var tick: float = exp(-k * 90.0) * sin(TAU * 900.0 * k + sin(TAU * 230.0 * k) * 2.0)
		out[i] = tick * 0.35 * minf((0.7 - t) / 0.2, 1.0)
	return _wav(out)


static func _add(sets: Dictionary, key: String, color: Color, tf: Transform3D) -> void:
	var k: Array = [key, color]
	if not sets.has(k):
		sets[k] = []
	(sets[k] as Array).append(tf)

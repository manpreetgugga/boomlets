extends WorldKit
## World 18, Domino Dunes: a warm desert of golden dunes, palm oases and
## striped tents. The twist is domino lines: rows of standing ivory dominoes,
## each with a floor arrow showing the way it topples. A blast that touches a
## domino knocks it over; a beat later it lands on the next tile, scorching
## its own tile and the one it lands on like a flame, and if a domino stands
## there that one goes over too, so the chain races along the line (round
## corners where the arrows turn) and burns whatever waits at the far end:
## crates, critters, barrels or pods. Standing dominoes block Pip, pods,
## critters and blasts; fallen ones lie flat a moment, then sink into the
## sand. Sand Scarabs walk a while, then burrow (only a moving sand ripple
## shows; blasts pass over them) and pop up two tiles from Pip. Cleopawtra,
## the sphinx-cat boss, stands fallen lines back up, and once hurt raises
## short lines of her own and swats them at Pip. A line that topples right
## beside her knocks a hit off her too.
##
## Extra map characters:
##   R L U D  domino facing right, left, up (away from the camera), down
##   s        Sand Scarab

const M := preload("res://worlds/world_18_models.gd")

const FACING: Dictionary = {"R": Vector2i(1, 0), "L": Vector2i(-1, 0), "U": Vector2i(0, -1), "D": Vector2i(0, 1)}
## Seconds a domino takes to fall (the beat between links of a chain).
const FALL_TIME: float = 0.2
const REST_TIME: float = 2.4
const SINK_TIME: float = 0.7
const RISE_TIME: float = 0.5
const SCARAB_WALK: float = 1.7
const SCARAB_DIG: float = 2.6
const DIG_TIME: float = 0.55
const RISE_UP: float = 0.8
const UNDER_MAX: float = 4.5
const BOSS_RESTORE: float = 9.0
const SWAT_EVERY: float = 7.5
const SWAT_EVERY_HURT: float = 5.5
const SWAT_WIND: float = 1.3
const SWAT_LEN: int = 5

const PALETTE: Dictionary = {
	"GRASS_A": "#F4CF86", "GRASS_B": "#EBC177", "RIM": "#F1CC85", "EDGE": "#DB8457",
	"STONE": "#F7E6C6", "DARK_STONE": "#D7A266", "DIRT": "#D9A56C", "ROCK": "#C98F5E",
	"WOOD": "#35BFB2", "WOOD_DARK": "#1E8C8A", "BARREL": "#E8604C", "BELT": "#8C6F5A", "ACCENT": "#F6C445",
	"BLOSSOM_A": "#5DBB6C", "BLOSSOM_B": "#3FA05C", "TRUNK": "#B98552", "LEAFY_A": "#7FC77A", "LEAFY_B": "#5DAE5E",
	"SKY_TOP": "#6FC0EC", "SKY_HORIZON": "#FFE2B4", "SKY_GROUND": "#F4D3A0", "CLOUD": "#FFF8EC", "CLOUDS": 0.35,
	"AMBIENT": "#EBD3AE", "AMBIENT_ENERGY": 0.56, "SUN": "#FFE9C8", "SUN_ENERGY": 1.6,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Tumble Row",
		"tip": "Blast a domino and the line\ntopples on, burning as it goes!\nIt scorches the tile at the end too.",
		"crates": 0.4, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.b...E...b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#RRRRRRRRRRD#",
			"#.#.#.#.#.#D#",
			"#..........D#",
			"#.#.#.#.#.#D#",
			"#..........c#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Scarab Burrows",
		"tip": "Sand Scarabs dig under the dunes\nand pop up right near you.\nStrike when they surface!",
		"crates": 0.4, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.s...E.....#",
			"#.#.#.#.#.#.#",
			"#DLLLLL...s.#",
			"#D#.#.#.#.#.#",
			"#D....b.....#",
			"#D#.#.#.#.#.#",
			"#.......s...#",
			"#.#.#.#.#.#.#",
			"#.RRRRR.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Corner Chains",
		"tip": "Chains race round corners!\nUse a long line as a fuse\nfor a far-off trick shot.",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E..s..#",
			"#.#.#.#.#.#.#",
			"#.z..U......#",
			"#.#.#U#.#.#.#",
			"#..s.U....b.#",
			"#.#.#U#.#.#.#",
			"#RRRRU..s...#",
			"#.#.#.#.#.#.#",
			"#.....LLLLLL#",
			"#.#.#.#.#.#.#",
			"#.s.........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Barrel Bazaar",
		"tip": "Topple a line into a fizz barrel:\nits big boom knocks over\nthe next line too!",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.s.......s.#",
			"#.#.#.#.#.#.#",
			"#RRRRRBRRRRD#",
			"#.#.#.#.#.#D#",
			"#..z.......D#",
			"#.#.#.#.#.#D#",
			"#.c.s......c#",
			"#.#.#.#.#.#.#",
			"#B.......s..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Oasis Ring",
		"tip": "A ring of dominoes walls in\nthe oasis. Knock one and the\nchain runs all the way round!",
		"crates": 0.4, "par": 105,
		"drops": {"bomb": 3, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1....E.....#",
			"#.#.#.#.#.#.#",
			"#.zRRRRRRD..#",
			"#.#U#.#.#D#.#",
			"#..U.s...D..#",
			"#.#U#.#.#D#.#",
			"#..U..B..D.s#",
			"#.#U#.#.#D#.#",
			"#..U...s.D..#",
			"#.#U#.#.#D#.#",
			"#..ULLLLLLz.#",
			"#.#.#_#_#.#.#",
			"#...._S_...1#",
			"#############",
		],
	},
	{
		"name": "Cleopawtra's Court",
		"tip": "Cleopawtra stands the dominoes\nback up. Topple a line as she\nprowls beside it! Eight hits.",
		"crates": 0.15, "par": 130, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#...#.#.#",
			"#.RRRRD...D.#",
			"#.#...D...D.#",
			"#.....D...D.#",
			"#.#.......D.#",
			"#.RRR.K.LLL.#",
			"#.U.......#.#",
			"#.U...U.....#",
			"#.U.#.U.#...#",
			"#.U...ULLLL.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"dir", "st" (rise, stand, fall, down, gone), "t", "k" (link
## number in its chain), "home" (from the map), "boss" (raised by the boss),
## "node", "pivot", "arrow"}.
var dominoes: Dictionary = {}
var _scarabs: Dictionary = {}   # Critter -> {"st", "t", "walk", "dust"}
var _chain_k: int = 0
var _clock: float = 0.0
var _restore_t: float = BOSS_RESTORE
var _swat_t: float = SWAT_EVERY
var _wind: float = -1.0
var _swing: float = 0.0
var _swat_line: Array[Vector2i] = []
var _flags: Array[Node3D] = []
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _snd_clack: AudioStreamWAV
var _snd_dig: AudioStreamWAV
var _snd_rise: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Domino Dunes"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_18.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "CLEOPAWTRA"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"scarab"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if FACING.has(ch):
		dominoes[c] = {"dir": FACING[ch], "st": &"stand", "t": 0.0, "k": 0, "home": true, "boss": false}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"s": &"scarab"}


func build_extra() -> void:
	_color_chains()
	for c: Vector2i in dominoes:
		_make_node(c, dominoes[c])
	for k in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -7.0
		arena.add_child(p)
		_players.append(p)
	_snd_clack = _make_clack()
	_snd_dig = _make_dig()
	_snd_rise = _make_rise()


## Gives every connected line of the map its own colour, so separate
## chains read apart.
func _color_chains() -> void:
	var group: Dictionary = {}
	var cells: Array = dominoes.keys()
	cells.sort()
	for c: Vector2i in cells:
		group[c] = c
	for c: Vector2i in cells:
		var n: Vector2i = c + (dominoes[c]["dir"] as Vector2i)
		if dominoes.has(n):
			var a: Vector2i = _root_of(group, c)
			var b: Vector2i = _root_of(group, n)
			if a != b:
				group[b] = a
	var index: Dictionary = {}
	for c: Vector2i in cells:
		var g: Vector2i = _root_of(group, c)
		if not index.has(g):
			index[g] = index.size()
		dominoes[c]["color"] = M.CHAIN_COLORS[int(index[g]) % M.CHAIN_COLORS.size()]


func _root_of(group: Dictionary, c: Vector2i) -> Vector2i:
	while group[c] != c:
		c = group[c]
	return c


func _make_node(c: Vector2i, dm: Dictionary) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = c.x * 131 + c.y * 17 + 5
	var n: Node3D = M.domino(r.randi_range(1, 6), r.randi_range(1, 6), dm.get("color", M.BOSS_DOMINO))
	n.position = Vector3(c.x, 0, c.y)
	arena.add_child(n)
	dm["node"] = n
	dm["pivot"] = n.get_node("Pivot")
	dm["arrow"] = n.get_node("Guide")
	_face(dm)


func _face(dm: Dictionary) -> void:
	var d: Vector2i = dm["dir"]
	(dm["node"] as Node3D).rotation.y = atan2(float(d.x), float(d.y))


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# A terracotta coping with turquoise tiles, and little gold pyramids on
	# the corners.
	var strips: Array[Transform3D] = []
	var tiles: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, 0.7, z)
		var corner: bool = (x == 0 or x == Arena.W - 1) and (z == 0 or z == Arena.H - 1)
		if corner:
			caps.append(Transform3D(Basis(Vector3.UP, PI * 0.25), at + Vector3(0, 0.12, 0)))
			continue
		var along_x: bool = z == 0 or z == Arena.H - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		strips.append(Transform3D(turn, at))
		if (x + z) % 2 == 0:
			tiles.append(Transform3D(Basis(Vector3.UP, PI * 0.25), at + Vector3(0, 0.03, 0)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.05, 0.56), 0.02), M.TERRA, strips)
	arena._multimesh(Models.box_mesh(Vector3(0.2, 0.05, 0.2), 0.02), M.TURQ, tiles)
	arena._multimesh(Models.cylinder(0.0, 0.24, 0.26, 4), M.GOLD, caps, Models.mat(M.GOLD, 0.2))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Each solid block is a little stepped sandstone pyramid with a
	# turquoise band and a gold tip.
	var bases: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var mids: Array[Transform3D] = []
	var tops: Array[Transform3D] = []
	var tips: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		bases.append(Transform3D(Basis(), p + Vector3(0, 0.2, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.33, 0)))
		mids.append(Transform3D(Basis(), p + Vector3(0, 0.49, 0)))
		tops.append(Transform3D(Basis(), p + Vector3(0, 0.66, 0)))
		tips.append(Transform3D(Basis(Vector3.UP, PI * 0.25), p + Vector3(0, 0.83, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.88, 0.4, 0.88), 0.07), M.SANDSTONE, bases)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.06, 0.9), 0.02), M.TURQ, bands)
	arena._multimesh(Models.box_mesh(Vector3(0.66, 0.2, 0.66), 0.05), M.SANDSTONE_DARK, mids)
	arena._multimesh(Models.box_mesh(Vector3(0.44, 0.16, 0.44), 0.04), M.SANDSTONE, tops)
	arena._multimesh(Models.cylinder(0.0, 0.2, 0.2, 4), M.GOLD, tips, Models.mat(M.GOLD, 0.15))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.3:
			node = M.dune(r)
		elif roll < 0.4:
			node = M.pot(r)
		elif roll < 0.47:
			node = M.cactus(r)
			node.scale = Vector3.ONE * 0.8
	elif p.z < 0.0:
		if roll < 0.3:
			node = M.palm(r, r.randf_range(1.3, 1.8))
		elif roll < 0.5:
			node = M.tent(r)
			node.rotation.y = r.randf_range(-0.3, 0.3)
			_flags.append(node.get_node("Flag"))
		elif roll < 0.62:
			node = M.dune(r)
		elif roll < 0.7:
			node = M.pot(r)
	else:
		if roll < 0.22:
			node = M.palm(r, r.randf_range(1.0, 1.5))
		elif roll < 0.34:
			node = M.tent(r)
			node.rotation.y = PI * 0.5 if p.x < 0.0 else -PI * 0.5
			node.scale = Vector3.ONE * 0.85
			_flags.append(node.get_node("Flag"))
		elif roll < 0.46:
			node = M.cactus(r)
		elif roll < 0.58:
			node = M.pot(r)
		elif roll < 0.68:
			node = M.dune(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var pyr: Node3D = M.pyramid(size * 0.62)
	pyr.position = Vector3(-size * 0.12, 0, -size * 0.12)
	pyr.rotation.y = r.randf_range(-0.3, 0.3)
	root.add_child(pyr)
	var pool: Node3D = M.pool(size * 0.36)
	pool.position = Vector3(size * 0.24, 0, size * 0.22)
	root.add_child(pool)
	var palm: Node3D = M.palm(r, 1.2)
	palm.position = Vector3(size * 0.34, 0, size * 0.02)
	root.add_child(palm)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFE6C2")
	sun.rotation_degrees = Vector3(-52.0, -38.0, 0.0)
	env.adjustment_saturation = 1.1
	env.glow_intensity = 0.4


# --- Rules ------------------------------------------------------------------------

func _standing(c: Vector2i) -> bool:
	if not dominoes.has(c):
		return false
	var st: StringName = dominoes[c]["st"]
	return st == &"stand" or st == &"rise"


func blocks(c: Vector2i) -> bool:
	return _standing(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if _standing(c) else 0


func on_flame(c: Vector2i) -> void:
	if _standing(c):
		_topple(c, _chain_k)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not _standing(c)


func process(delta: float) -> void:
	_clock += delta
	_update_dominoes(delta)
	_update_scarabs(delta)
	_update_boss(delta)
	for f: Node3D in _flags:
		f.rotation.y = sin(_clock * 3.0 + f.global_position.x) * 0.35


# --- Dominoes -----------------------------------------------------------------------

func _topple(c: Vector2i, k: int) -> void:
	var dm: Dictionary = dominoes[c]
	dm["st"] = &"fall"
	dm["t"] = 0.0
	dm["k"] = k
	(dm["node"] as Node3D).position.y = 0.0
	(dm["arrow"] as Node3D).visible = false


func _update_dominoes(delta: float) -> void:
	for c: Vector2i in dominoes.keys():
		var dm: Dictionary = dominoes[c]
		var st: StringName = dm["st"]
		if st == &"stand" or st == &"gone":
			continue
		dm["t"] = float(dm["t"]) + delta
		var t: float = dm["t"]
		var node: Node3D = dm["node"]
		var pivot: Node3D = dm["pivot"]
		match st:
			&"rise":
				var u: float = minf(t / RISE_TIME, 1.0)
				# Pops up out of the sand with a little overshoot.
				var e: float = 1.0 + 2.2 * pow(u - 1.0, 3.0) + 1.2 * pow(u - 1.0, 2.0)
				node.position.y = lerpf(-0.85, 0.0, e)
				pivot.rotation.x = M.LEAN
				if u >= 1.0:
					dm["st"] = &"stand"
					node.position.y = 0.0
			&"fall":
				var u2: float = minf(t / FALL_TIME, 1.0)
				pivot.rotation.x = lerpf(M.LEAN, PI * 0.5, u2 * u2)
				if u2 >= 1.0:
					dm["st"] = &"down"
					dm["t"] = 0.0
					_land(c, dm)
			&"down":
				if t > REST_TIME:
					var s: float = minf((t - REST_TIME) / SINK_TIME, 1.0)
					node.position.y = -0.24 * s
					if s >= 1.0:
						dm["st"] = &"gone"
						node.visible = false
				else:
					# A little settle bounce right after landing.
					pivot.rotation.x = PI * 0.5 - sin(minf(t / 0.18, 1.0) * PI) * 0.12


## The domino at [param c] hits the floor: it scorches its own tile and the
## one it lands on, and topples whatever domino stands there.
func _land(c: Vector2i, dm: Dictionary) -> void:
	var d: Vector2i = dm["dir"]
	var k: int = dm["k"]
	_sound(_snd_clack, minf(0.92 + k * 0.035, 1.5))
	_puff(Vector3(c.x + d.x * 0.6, 0.08, c.y + d.y * 0.6), 3, M.SAND_LIGHT)
	arena._shake = maxf(arena._shake, 0.06)
	if not arena.demo:
		Save.buzz(8)
	arena._add_flame(c, 0, d)
	_boss_bump(c, dm)
	var n: Vector2i = c + d
	var t: int = arena.tile(n)
	if t == Arena.WALL:
		return
	_chain_k = k + 1
	arena._add_flame(n, 1, d)
	_chain_k = 0
	if t == Arena.CRATE:
		arena._break_crate(n)
	elif t == Arena.BARREL:
		arena._ignite_barrel(n)
	elif arena.pod_at.has(n):
		var p: Arena.Pod = arena.pod_at[n]
		p.timer = minf(p.timer, 0.06)
	_boss_bump(n, dm)


## A domino landing right beside Cleopawtra knocks a hit off her (her own
## swat lines never do).
func _boss_bump(c: Vector2i, dm: Dictionary) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or bool(dm["boss"]) or b.invuln > 0.0 or not arena.critters.has(b):
		return
	if b.pos.distance_to(Vector2(c)) <= 1.05:
		arena._hit_critter(b)


## Stands a domino up at [param c] facing [param d] (re-using its node).
func _raise(c: Vector2i, d: Vector2i, home: bool) -> void:
	var dm: Dictionary
	if dominoes.has(c):
		dm = dominoes[c]
	else:
		dm = {"home": home, "dir": d}
		dominoes[c] = dm
		_make_node(c, dm)
	dm["dir"] = d
	dm["st"] = &"rise"
	dm["t"] = 0.0
	dm["k"] = 0
	dm["boss"] = not home
	_face(dm)
	var node: Node3D = dm["node"]
	node.visible = true
	node.position.y = -0.85
	(dm["pivot"] as Node3D).rotation.x = M.LEAN
	(dm["arrow"] as Node3D).visible = true
	_puff(Vector3(c.x, 0.1, c.y), 4, M.SAND_DARK)


## True when a domino may rise at [param c] without trapping or crushing
## anyone: plain floor, nothing on it, and not right next to Pip.
func _clear_for_domino(c: Vector2i, near_boss: bool = false) -> bool:
	var a: Arena = arena
	if a.tile(c) != Arena.FLOOR or c == a.exit_cell or a.warps.has(c) or a.belts.has(c):
		return false
	if a.pod_at.has(c) or a.pickups.has(c) or a.flames.has(c):
		return false
	for p: Arena.Pod in a.pods:
		if p.pos.distance_to(Vector2(c)) < 0.9:
			return false
	if not a.demo and a.hero != null:
		var h: Vector2i = a.hero_cell()
		if absi(h.x - c.x) + absi(h.y - c.y) <= 1:
			return false
		if a.hero_pos.distance_to(Vector2(c)) < 1.2:
			return false
	for cr: Arena.Critter in a.critters:
		if cr.cell == c or cr.target == c or cr.pos.distance_to(Vector2(c)) < 0.9:
			return false
		if cr.kind == &"boss" and not near_boss and cr.pos.distance_to(Vector2(c)) < 1.4:
			return false
	return true


# --- Sand Scarabs -------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"scarab":
			return M.scarab()
		&"boss":
			return M.sphinx()
	return null


func critter_speed(kind: StringName) -> float:
	return SCARAB_WALK if kind == &"scarab" else 1.0


func critter_hp(_kind: StringName) -> int:
	return 1


func _scarab(cr: Arena.Critter) -> Dictionary:
	if not _scarabs.has(cr):
		_scarabs[cr] = {"st": &"walk", "t": 0.0, "walk": arena.rng.randf_range(2.0, 3.6), "dust": 0.0}
	return _scarabs[cr]


func critter_hidden(cr: Arena.Critter) -> bool:
	if cr.kind != &"scarab":
		return false
	var s: Dictionary = _scarab(cr)
	match s["st"]:
		&"under":
			return true
		&"dig":
			return float(s["t"]) > DIG_TIME * 0.5
		&"rise":
			return float(s["t"]) < RISE_UP * 0.55
	return false


## Underground, a scarab tunnels straight for Pip.
func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"scarab" or arena.demo or not arena.hero_alive:
		return Vector2i.ZERO
	if _scarab(cr)["st"] != &"under":
		return Vector2i.ZERO
	return arena._path_step(cr, arena.hero_cell())


func _at_cell(cr: Arena.Critter) -> bool:
	return cr.t <= 0.0 or cr.t >= 1.0


## Keeps a critter standing on its tile (it picks a fresh way on release).
func _hold(cr: Arena.Critter) -> void:
	cr.target = cr.cell
	cr.t = 0.0
	cr.pos = Vector2(cr.cell)
	cr.speed = 0.0


func _update_scarabs(delta: float) -> void:
	for cr: Arena.Critter in _scarabs.keys():
		if not arena.critters.has(cr):
			_scarabs.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"scarab":
			continue
		var s: Dictionary = _scarab(cr)
		s["t"] = float(s["t"]) + delta
		var t: float = s["t"]
		match s["st"]:
			&"walk":
				cr.speed = SCARAB_WALK
				if t >= float(s["walk"]) and _at_cell(cr):
					s["st"] = &"dig"
					s["t"] = 0.0
					_hold(cr)
					_near_sound(cr, _snd_dig, 1.0)
			&"dig":
				_hold(cr)
				if t >= DIG_TIME:
					s["st"] = &"under"
					s["t"] = 0.0
					cr.speed = SCARAB_DIG
					cr.t = 1.0
			&"under":
				cr.speed = SCARAB_DIG
				s["dust"] = float(s["dust"]) - delta
				if float(s["dust"]) <= 0.0:
					s["dust"] = 0.16
					_puff(Vector3(cr.pos.x, 0.06, cr.pos.y), 1, M.SAND_DARK)
				if _at_cell(cr) and _may_surface(cr, t):
					s["st"] = &"rise"
					s["t"] = 0.0
					_hold(cr)
					_near_sound(cr, _snd_dig, 1.3)
			&"rise":
				_hold(cr)
				if t >= RISE_UP:
					s["st"] = &"walk"
					s["t"] = 0.0
					s["walk"] = arena.rng.randf_range(2.4, 4.0)
					cr.speed = SCARAB_WALK
					cr.t = 1.0
					_puff(Vector3(cr.pos.x, 0.1, cr.pos.y), 5, M.SAND_LIGHT)


## A tunnelling scarab comes up two or three tiles from Pip (never on or next
## to him), or anywhere once it has dug long enough.
func _may_surface(cr: Arena.Critter, t: float) -> bool:
	if arena.flames.has(cr.cell) or arena.pod_at.has(cr.cell) or _standing(cr.cell):
		return false
	if arena.demo or not arena.hero_alive or arena.hero == null:
		return t >= 2.5
	var h: Vector2i = arena.hero_cell()
	var dist: int = absi(h.x - cr.cell.x) + absi(h.y - cr.cell.y)
	if dist <= 1:
		return false
	return dist <= 3 or t >= UNDER_MAX


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	if cr.kind == &"scarab":
		return _pose_scarab(cr, body, t)
	if cr.kind == &"boss":
		return _pose_boss(cr, body, t)
	return Vector3.ONE


func _pose_scarab(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	var s: Dictionary = _scarab(cr)
	var mound: Node3D = cr.node.get_node("Mound")
	var legs: Node3D = body.get_node("Legs")
	var u: float = float(s["t"])
	var size: float = M.SCARAB_SIZE
	match s["st"]:
		&"walk":
			body.visible = true
			mound.visible = false
			body.position = Vector3(0, absf(sin(t * 13.0)) * 0.025, 0)
			body.rotation.x = 0.0
			legs.rotation.y = sin(t * 22.0) * 0.18
			return Vector3.ONE * size
		&"dig":
			var k: float = minf(u / DIG_TIME, 1.0)
			body.visible = true
			mound.visible = true
			mound.scale = Vector3.ONE * maxf(k, 0.05)
			body.position = Vector3(sin(t * 70.0) * 0.025, -0.6 * k * k, 0)
			body.rotation.x = 0.55 * k
			legs.rotation.y = sin(t * 50.0) * 0.3
			return Vector3(1.06, 0.94, 1.06) * size
		&"under":
			body.visible = false
			mound.visible = true
			mound.scale = Vector3(1.0 + sin(t * 9.0) * 0.08, 0.8 + absf(sin(t * 11.0)) * 0.35, 1.0 - sin(t * 9.0) * 0.06)
			mound.rotation.y = sin(t * 4.0) * 0.3
			return Vector3.ONE * size
		&"rise":
			var k2: float = minf(u / RISE_UP, 1.0)
			mound.visible = true
			if k2 < 0.55:
				# The ripple stops and the sand bulges and shakes.
				body.visible = false
				var g: float = k2 / 0.55
				mound.scale = Vector3.ONE * (1.0 + g * 0.35)
				mound.rotation.y = sin(t * 60.0) * 0.12
			else:
				var v: float = (k2 - 0.55) / 0.45
				body.visible = true
				body.position = Vector3(0, sin(v * PI) * 0.38 - (1.0 - v) * 0.25, 0)
				body.rotation.x = -0.4 * (1.0 - v)
				mound.scale = Vector3.ONE * maxf(1.35 * (1.0 - v), 0.01)
				if v >= 0.98:
					mound.visible = false
			return Vector3.ONE * size
	return Vector3.ONE * size


# --- Cleopawtra -----------------------------------------------------------------------

func _update_boss(delta: float) -> void:
	_swing = maxf(_swing - delta, 0.0)
	var b: Arena.Critter = arena.boss
	if b == null or arena.demo or not arena.critters.has(b):
		return
	if arena.state != &"play":
		return
	_restore_t -= delta
	if _restore_t <= 0.0:
		_restore_t = BOSS_RESTORE
		_restore_lines(b)
	if _wind >= 0.0:
		_wind -= delta
		_hold(b)
		if _wind < 0.0:
			_swat(b)
		return
	if b.hp < arena.boss_max_hp:
		_swat_t -= delta
	if _swat_t <= 0.0 and _at_cell(b):
		if _start_swat(b):
			_wind = SWAT_WIND
			_hold(b)
		else:
			_swat_t = 1.0


## Stands every sunk line of the arena back up where it is safe to.
func _restore_lines(b: Arena.Critter) -> void:
	var raised: int = 0
	for c: Vector2i in dominoes:
		var dm: Dictionary = dominoes[c]
		if not bool(dm["home"]) or dm["st"] != &"gone":
			continue
		if not _clear_for_domino(c):
			continue
		_raise(c, dm["dir"], true)
		raised += 1
	if raised > 0:
		_sound(_snd_rise, 1.0)
		arena._spawn_sparkles(arena._to3(b.pos, 1.7), M.GOLD)
		_swing = 0.5


## Raises a short line from Cleopawtra toward Pip, to swat it at him once
## wound up. False when there is no room for one.
func _start_swat(b: Arena.Critter) -> bool:
	if not arena.hero_alive:
		return false
	var diff: Vector2i = arena.hero_cell() - b.cell
	var order: Array[Vector2i] = []
	var major := Vector2i(signi(diff.x), 0) if absi(diff.x) >= absi(diff.y) else Vector2i(0, signi(diff.y))
	var minor := Vector2i(0, signi(diff.y)) if absi(diff.x) >= absi(diff.y) else Vector2i(signi(diff.x), 0)
	for d: Vector2i in [major, minor]:
		if d != Vector2i.ZERO and not order.has(d):
			order.append(d)
	for d: Vector2i in Arena.DIRS:
		if not order.has(d):
			order.append(d)
	for d: Vector2i in order:
		var cells: Array[Vector2i] = []
		for i in range(1, SWAT_LEN + 1):
			var c: Vector2i = b.cell + d * i
			if dominoes.has(c) and (bool(dominoes[c]["home"]) or dominoes[c]["st"] != &"gone"):
				break
			if not _clear_for_domino(c, true):
				break
			cells.append(c)
		if cells.size() >= 2:
			_swat_line = cells
			for c in cells:
				_raise(c, d, false)
			b.dir = d
			_sound(_snd_rise, 1.15)
			return true
	return false


func _swat(b: Arena.Critter) -> void:
	_swat_t = SWAT_EVERY_HURT if b.hp * 2 <= arena.boss_max_hp else SWAT_EVERY
	_swing = 0.45
	b.speed = 1.0 + (arena.boss_max_hp - b.hp) * 0.72 / arena.boss_max_hp
	b.t = 1.0
	if not _swat_line.is_empty() and _standing(_swat_line[0]):
		_topple(_swat_line[0], 0)
	_swat_line.clear()
	arena._shake = maxf(arena._shake, 0.12)


func _pose_boss(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	var paw_l: Node3D = body.get_node("PawL")
	var paw_r: Node3D = body.get_node("PawR")
	var tail: Node3D = body.get_node("Tail")
	var head: Node3D = body.get_node("Head")
	tail.rotation.y = sin(t * 2.3) * 0.45
	tail.rotation.x = sin(t * 1.7) * 0.1
	head.rotation.y = sin(t * 0.8) * 0.15
	var eyes: Node3D = head.get_node("Eyes")
	eyes.scale = Vector3(1.0, 0.15 if fmod(t, 3.9) < 0.12 else 1.0, 1.0)
	var moving: bool = cr.t > 0.0 and cr.t < 1.0
	if _wind >= 0.0:
		# Winding up: the right paw rises high, the tail lashes.
		var k: float = 1.0 - clampf(_wind / SWAT_WIND, 0.0, 1.0)
		paw_r.rotation.x = lerpf(paw_r.rotation.x, -1.5, 0.2)
		paw_l.rotation.x = lerpf(paw_l.rotation.x, 0.0, 0.2)
		tail.rotation.y = sin(t * 9.0) * 0.6
		body.position = Vector3(sin(t * 40.0) * 0.015 * k, 0.0, 0.0)
		return Vector3(1.0, 1.0 + k * 0.05, 1.0) * M.BOSS_SIZE
	body.position = Vector3.ZERO
	if _swing > 0.0:
		# The swat (or a regal wave while standing lines back up).
		paw_r.rotation.x = lerpf(paw_r.rotation.x, 0.5, 0.35)
		return Vector3(1.04, 0.96, 1.04) * M.BOSS_SIZE
	var step: float = sin(t * 7.0) * 0.32 if moving else 0.0
	paw_l.rotation.x = lerpf(paw_l.rotation.x, step, 0.2)
	paw_r.rotation.x = lerpf(paw_r.rotation.x, -step, 0.2)
	return Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.035, 1.0) * M.BOSS_SIZE


# --- Effects and sound --------------------------------------------------------------

func _puff(at: Vector3, count: int, color: Color) -> void:
	if arena._fx.size() > 240:
		return
	for k in count:
		var a: float = TAU * k / maxf(count, 1) + arena.rng.randf() * 0.8
		var d := Models.part(arena, arena._smoke_mesh, color, at + Vector3(cos(a) * 0.15, 0.0, sin(a) * 0.15))
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.scale = Vector3.ONE * 0.6
		d.rotation.y = arena.rng.randf() * TAU
		arena._fx.append({"node": d, "t": 0.0, "life": 0.5, "kind": &"dust", "vel": Vector3(cos(a) * 1.2, 0.5, sin(a) * 1.2)})


func _near_sound(cr: Arena.Critter, s: AudioStreamWAV, pitch: float) -> void:
	if arena.demo or arena.hero == null or cr.pos.distance_to(arena.hero_pos) < 6.0:
		_sound(s, pitch)


func _sound(s: AudioStreamWAV, pitch: float) -> void:
	if _players.is_empty() or s == null or not Save.sound_on or arena.demo:
		return
	var p: AudioStreamPlayer = _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


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


## A wooden "clack": a knock with two hollow resonances and a soft thud.
func _make_clack() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.14)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 18
	for i in n:
		var t: float = i / rate
		var knock: float = sin(TAU * 1250.0 * t) * exp(-t * 60.0) * 0.5 + sin(TAU * 2100.0 * t) * exp(-t * 90.0) * 0.3
		var thud: float = sin(TAU * (180.0 - 60.0 * t) * t) * exp(-t * 35.0) * 0.45
		var click: float = rng.randf_range(-1.0, 1.0) * exp(-t * 400.0) * 0.5
		out[i] = (knock + thud + click) * minf(t / 0.001, 1.0) * 0.8
	return _wav(out)


## A soft sandy hiss for a scarab digging in or popping out.
func _make_dig() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		var x: float = rng.randf_range(-1.0, 1.0)
		lp += (x - lp) * 0.35
		var grain: float = 0.6 + 0.4 * sin(TAU * 31.0 * t)
		var env: float = minf(t / 0.03, 1.0) * exp(-t * 6.0)
		out[i] = lp * grain * env * 0.55
	return _wav(out)


## A rumbling "shhff" as dominoes rise out of the sand.
func _make_rise() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.55)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var lp: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * (0.08 + 0.3 * t)
		phase += TAU * (90.0 + 140.0 * t) / rate
		var env: float = minf(t / 0.08, 1.0) * minf((0.55 - t) / 0.12, 1.0)
		out[i] = (lp * 0.7 + sin(phase) * 0.35) * env * 0.5
	return _wav(out)

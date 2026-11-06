extends WorldKit
## World 19, Slime Lab: a bright, friendly science lab of white and mint
## checker floors, lab cabinets topped with beakers, bubbling glass columns
## and test-tube racks. The twist is splitting slimes: a blast splits a Big
## Slime into two Medium ones and a Medium into two Small ones, which pop for
## good. Each split squishes with a pop, then the halves hop apart to free
## tiles (never into walls or onto Pip), safe for a blink while they fly.
## Potion vats stand on the floor like blocks: blast one to splash its 3x3
## patch. Green goo puddles slow critters and Pip for a while; blue freeze
## locks critters in ice for a few seconds (frozen ones block the way and
## can't dodge). Emptied vats slowly refill. Lab Rats are little wheeled
## robots that chase, stopping now and then to scan. King Slime sits in a
## beaker, spills two minis each time he is hit, shrinks as he weakens and,
## once badly hurt, lobs goo at Pip (a dashed ring shows where it lands).
##
## Extra map characters:
##   L M m  Big, Medium and Small Slime
##   r      Lab Rat
##   g f    goo vat, freeze vat

const M := preload("res://worlds/world_19_models.gd")

const SPLIT_INTO: Dictionary = {&"slime_big": &"slime_mid", &"slime_mid": &"slime_small"}
const SPEEDS: Dictionary = {&"slime_big": 1.05, &"slime_mid": 1.5, &"slime_small": 1.95, &"labrat": 2.15}
## Seconds a split half spends in the air, and how long it is safe after.
const HOP_TIME: float = 0.42
const HOP_INVULN: float = 0.85
## Splits stop making halves once this many critters are out.
const MAX_CRITTERS: int = 10
const GOO_TIME: float = 8.0
const GOO_SLOW: float = 0.45
const HERO_GOO: float = 0.55
const FREEZE_TIME: float = 3.5
const BOSS_FREEZE: float = 2.5
const VAT_REFILL: float = 9.0
const RAT_SCAN: float = 0.75
const LOB_EVERY: float = 7.0
const LOB_AIM: float = 1.3
const LOB_FLY: float = 0.6
## King Slime only spills minis while fewer critters than this are out.
const BOSS_CROWD: int = 5

const PALETTE: Dictionary = {
	"GRASS_A": "#F4FBF8", "GRASS_B": "#C3EBDC", "RIM": "#BFE8DB", "EDGE": "#2FA9A3",
	"STONE": "#FFFFFF", "DARK_STONE": "#A9C4CF", "DIRT": "#9CCBD3", "ROCK": "#86A8BC",
	"WOOD": "#F4AE3D", "WOOD_DARK": "#D07F1C", "BARREL": "#E8508A", "BELT": "#6F8597", "ACCENT": "#8EDC4E",
	"BLOSSOM_A": "#8EDC4E", "BLOSSOM_B": "#5DB632", "TRUNK": "#C6D1DC", "LEAFY_A": "#9BE3C4", "LEAFY_B": "#6FCFAA",
	"SKY_TOP": "#7CC8F0", "SKY_HORIZON": "#E6F7F2", "SKY_GROUND": "#CDEBE4", "CLOUD": "#FFFFFF", "CLOUDS": 0.4,
	"AMBIENT": "#DDEFF0", "AMBIENT_ENERGY": 0.6, "SUN": "#FFF8EE", "SUN_ENERGY": 1.5,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Wobble Lab",
		"tip": "Blast a big slime and it splits\ninto two smaller ones. Pop them\nall the way down to open the exit!",
		"crates": 0.36, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..M.....m..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....L.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Goo Station",
		"tip": "Blast a green vat to splash goo.\nCritters crawl through it slowly,\nbut so do you!",
		"crates": 0.38, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#m....E....m#",
			"#.#.#.#.#.#.#",
			"#...g...g...#",
			"#.#.#.#.#.#.#",
			"#..M........#",
			"#.#.#.#.#.#.#",
			"#.....L.....#",
			"#.#.#.#.#.#.#",
			"#...g...g...#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Cold Storage",
		"tip": "Blue vats freeze critters solid!\nFrozen ones can't move or dodge.\nLab Rats pause to scan: strike then!",
		"crates": 0.4, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.r..f.f..r.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.M..f.f..m.#",
			"#.#.#.#.#.#.#",
			"#....L......#",
			"#.#.#.#.#.#.#",
			"#.g.......g.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Barrel Bench",
		"tip": "A barrel's big boom can tip a\nvat from afar. Kick pods down the\naisles to reach hiding slimes!",
		"crates": 0.38, "par": 100,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.......m.#",
			"#.#.#.#.#.#.#",
			"#.B_f...g_B.#",
			"#.#.#.#.#.#.#",
			"#.L.......r.#",
			"#.#.#.#.#.#.#",
			"#.B_g...f_B.#",
			"#.#.#.#.#.#.#",
			"#.....M.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Pipeline",
		"tip": "Belts carry pods to the middle,\nright under the big slime. Ride\nthe warp to reach the far side!",
		"crates": 0.36, "par": 110,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#1....E.....#",
			"#.#.#.#.#.#.#",
			"#..r.f.g.r..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.>>>>L<<<<.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.M..g.f..M.#",
			"#.#.#_#_#.#.#",
			"#..1._S_....#",
			"#############",
		],
	},
	{
		"name": "King Slime's Beaker",
		"tip": "King Slime spills minis when hit.\nFreeze him with a blue vat, then\nblast him! Eight hits.",
		"crates": 0.2, "par": 140, "boss": true,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..f.....f..#",
			"#.#.#.#.#.#.#",
			"#.....g.....#",
			"#.#.......#.#",
			"#.....K.....#",
			"#.#.......#.#",
			"#.....g.....#",
			"#.#.#.#.#.#.#",
			"#..f.....f..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"freeze": bool, "full": bool, "t": refill seconds left,
## "node", "liquid", "bubbles", "level"}.
var vats: Dictionary = {}
## Vector2i -> {"t": seconds left, "age", "node"}.
var goo: Dictionary = {}
var _frozen: Dictionary = {}   # Critter -> {"t", "ice"}
var _hops: Dictionary = {}     # Critter -> {"to": Vector2i, "dist": float}
var _rats: Dictionary = {}     # Critter -> {"run", "scan"}
var _frost: Array[Dictionary] = []
var _bubbles: Array[Dictionary] = []
var _lob: Dictionary = {}
var _lob_t: float = LOB_EVERY
var _clock: float = 0.0
var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0
var _snd_squish: AudioStreamWAV
var _snd_splash: AudioStreamWAV
var _snd_freeze: AudioStreamWAV
var _snd_blip: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Slime Lab"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_19.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "KING SLIME"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"slime_small"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "g" or ch == "f":
		vats[c] = {"freeze": ch == "f", "full": true, "t": 0.0, "level": 1.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"L": &"slime_big", "M": &"slime_mid", "m": &"slime_small", "r": &"labrat"}


func build_extra() -> void:
	for c: Vector2i in vats:
		var v: Dictionary = vats[c]
		var n: Node3D = M.vat(bool(v["freeze"]))
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		v["node"] = n
		v["liquid"] = n.get_node("Liquid")
		v["bubbles"] = n.get_node("Bubbles")
	for k in 3:
		var p := AudioStreamPlayer.new()
		p.volume_db = -7.0
		arena.add_child(p)
		_players.append(p)
	_snd_squish = _make_squish()
	_snd_splash = _make_splash()
	_snd_freeze = _make_freeze()
	_snd_blip = _make_blip()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# A white lab counter with a row of little status lights, and a round
	# potion flask on each corner.
	var strips: Array[Transform3D] = []
	var lime: Array[Transform3D] = []
	var teal: Array[Transform3D] = []
	var bulbs: Array[Transform3D] = []
	var potions: Array[Transform3D] = []
	var necks: Array[Transform3D] = []
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, 0.7, z)
		var corner: bool = (x == 0 or x == Arena.W - 1) and (z == 0 or z == Arena.H - 1)
		if corner:
			bulbs.append(Transform3D(Basis(), at + Vector3(0, 0.24, 0)))
			potions.append(Transform3D(Basis(), at + Vector3(0, 0.19, 0)))
			necks.append(Transform3D(Basis(), at + Vector3(0, 0.5, 0)))
			continue
		var along_x: bool = z == 0 or z == Arena.H - 1
		strips.append(Transform3D(Basis(Vector3.UP, 0.0 if along_x else PI * 0.5), at))
		if (x + z) % 2 == 0:
			(lime if (x + z) % 4 == 0 else teal).append(Transform3D(Basis(), at + Vector3(0, 0.04, 0)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.06, 0.62), 0.02), M.TEAL, strips)
	arena._multimesh(Models.cylinder(0.08, 0.08, 0.05, 12), M.LIME, lime, Models.mat(M.LIME, 0.5))
	arena._multimesh(Models.cylinder(0.08, 0.08, 0.05, 12), M.TEAL, teal, Models.mat(M.TEAL, 0.4))
	arena._multimesh(Models.sphere(0.15, -1, 14), M.PINK, potions, Models.mat(M.PINK, 0.4))
	arena._multimesh(Models.sphere(0.22, -1, 16), M.ICE_LIGHT, bulbs, Models.glass(M.ICE_LIGHT, 0.1, 0.04))
	arena._multimesh(Models.cylinder(0.06, 0.06, 0.14, 10), M.WHITE, necks)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Each solid block is a white lab cabinet with a teal top, a drawer line
	# and a glass beaker of potion on top.
	var bases: Array[Transform3D] = []
	var tops: Array[Transform3D] = []
	var drawers: Array[Transform3D] = []
	var beakers: Array[Transform3D] = []
	var liq_a: Array[Transform3D] = []
	var liq_b: Array[Transform3D] = []
	var liq_c: Array[Transform3D] = []
	var liquids: Array = [liq_a, liq_b, liq_c]
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		bases.append(Transform3D(Basis(), p + Vector3(0, 0.29, 0)))
		tops.append(Transform3D(Basis(), p + Vector3(0, 0.6, 0)))
		drawers.append(Transform3D(Basis(), p + Vector3(0, 0.38, 0.435)))
		var off := Vector3(0.12 if roundi(p.x) % 4 == 0 else -0.12, 0, 0.05)
		beakers.append(Transform3D(Basis(), p + off + Vector3(0, 0.86, 0)))
		(liquids[(roundi(p.x) + roundi(p.z) * 2) % 3] as Array[Transform3D]).append(Transform3D(Basis(), p + off + Vector3(0, 0.72, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.86, 0.58, 0.86), 0.07), M.WHITE, bases)
	arena._multimesh(Models.box_mesh(Vector3(0.92, 0.08, 0.92), 0.03), M.TEAL, tops)
	arena._multimesh(Models.box_mesh(Vector3(0.56, 0.05, 0.03), 0.015), M.STEEL_DARK, drawers)
	var colors: Array[Color] = [M.LIME, M.ICE, M.PINK]
	for k in 3:
		arena._multimesh(Models.cylinder(0.165, 0.155, 0.17, 16), colors[k], liquids[k], Models.mat(colors[k], 0.3))
	var cup := Models.cylinder(0.165, 0.165, 0.12, 16)
	cup.cap_top = false
	cup.cap_bottom = false
	arena._multimesh(cup, M.ICE_LIGHT, beakers, Models.glass(M.ICE_LIGHT, 0.1, 0.04))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M.supply_box(r)
		elif roll < 0.32:
			node = M.tube_rack(r)
			node.rotation.y = r.randf_range(-0.3, 0.3)
		elif roll < 0.42:
			node = M.flask(r, 0.8)
	elif p.z < 0.0:
		if roll < 0.3:
			node = M.column(r, r.randf_range(1.1, 1.7), _bubbles)
		elif roll < 0.44:
			node = M.microscope()
			node.rotation.y = r.randf_range(-0.5, 0.5)
		elif roll < 0.58:
			node = M.tube_rack(r)
		elif roll < 0.7:
			node = M.flask(r, r.randf_range(1.0, 1.4))
		elif roll < 0.8:
			node = M.supply_box(r)
	else:
		if roll < 0.2:
			node = M.column(r, r.randf_range(0.9, 1.3), _bubbles)
		elif roll < 0.34:
			node = M.flask(r, r.randf_range(0.9, 1.2))
		elif roll < 0.46:
			node = M.tube_rack(r)
			node.rotation.y = PI * 0.5
		elif roll < 0.56:
			node = M.supply_box(r)
		elif roll < 0.62:
			node = M.microscope()
			node.rotation.y = PI * 0.5 if p.x < 0.0 else -PI * 0.5
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var d: Node3D = M.dome(size * 0.62)
	d.position = Vector3(-size * 0.1, 0, -size * 0.1)
	root.add_child(d)
	var col: Node3D = M.column(r, 1.1, _bubbles)
	col.position = Vector3(size * 0.3, 0, size * 0.12)
	root.add_child(col)
	var f: Node3D = M.flask(r, 1.1)
	f.position = Vector3(size * 0.08, 0, size * 0.3)
	root.add_child(f)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFFBF2")
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	env.adjustment_saturation = 1.05
	env.glow_intensity = 0.45


# --- Rules ------------------------------------------------------------------------

func _frozen_at(c: Vector2i, besides: Arena.Critter = null) -> bool:
	for cr: Arena.Critter in _frozen:
		if cr != besides and cr.cell == c:
			return true
	return false


func blocks(c: Vector2i) -> bool:
	if vats.has(c):
		return true
	if _frozen.is_empty():
		return false
	return _frozen_at(c) and (arena.demo or arena.hero_cell() != c)


func flame_stop(c: Vector2i) -> int:
	return 1 if vats.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if vats.has(c) and bool(vats[c]["full"]):
		_splash(c)


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if vats.has(c):
		return false
	return _frozen.is_empty() or not _frozen_at(c, cr)


func hero_speed_scale(c: Vector2i) -> float:
	return HERO_GOO if goo.has(c) else 1.0


func process(delta: float) -> void:
	_clock += delta
	_tidy()
	_update_hops()
	_update_frozen(delta)
	_update_rats(delta)
	_update_speeds()
	_update_goo(delta)
	_update_vats(delta)
	_update_lob(delta)
	for b: Dictionary in _bubbles:
		var n: Node3D = b["node"]
		var u: float = fmod(_clock * float(b["speed"]) + float(b["phase"]), 1.0)
		n.position.y = float(b["y0"]) + u * float(b["h"])
		n.scale = Vector3.ONE * (1.0 - u * 0.5)
	var keep: Array[Dictionary] = []
	for f: Dictionary in _frost:
		f["t"] = float(f["t"]) + delta
		var n2: Node3D = f["node"]
		var k: float = float(f["t"]) / 1.4
		if k >= 1.0:
			n2.queue_free()
			continue
		n2.scale = Vector3(1.0 - k * k, 1.0, 1.0 - k * k)
		keep.append(f)
	_frost = keep


## Forgets critters that have left the arena.
func _tidy() -> void:
	for d: Dictionary in [_frozen, _hops, _rats]:
		for cr: Arena.Critter in d.keys():
			if not arena.critters.has(cr):
				d.erase(cr)


func _at_cell(cr: Arena.Critter) -> bool:
	return cr.t <= 0.0 or cr.t >= 1.0


## Keeps a critter standing on its tile (it picks a fresh way on release).
func _hold(cr: Arena.Critter) -> void:
	cr.target = cr.cell
	cr.t = 0.0
	cr.pos = Vector2(cr.cell)
	cr.speed = 0.0


func _base_speed(cr: Arena.Critter) -> float:
	if cr.kind == &"boss":
		return 1.0 + (arena.boss_max_hp - cr.hp) * 0.72 / arena.boss_max_hp
	return float(SPEEDS.get(cr.kind, -1.0))


## Sets every critter's pace: hopping halves fly, frozen and scanning ones
## stay put, and goo slows the rest.
func _update_speeds() -> void:
	for cr: Arena.Critter in arena.critters:
		if _hops.has(cr):
			cr.speed = 1.0 / HOP_TIME
			continue
		if _frozen.has(cr) or (_rats.has(cr) and float(_rats[cr]["scan"]) > 0.0):
			_hold(cr)
			continue
		var base: float = _base_speed(cr)
		if base < 0.0:
			continue
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		cr.speed = base * (GOO_SLOW if goo.has(here) else 1.0)


# --- Splitting slimes ------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	if M.SLIME_SIZE.has(kind):
		return M.slime(M.SLIME_SIZE[kind], M.SLIME_COLOR[kind])
	match kind:
		&"labrat":
			return M.labrat()
		&"boss":
			return M.king_slime()
	return null


func critter_speed(kind: StringName) -> float:
	return float(SPEEDS.get(kind, 1.0))


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_smart(kind: StringName) -> bool:
	return kind == &"slime_small" or kind == &"labrat"


func critter_hidden(cr: Arena.Critter) -> bool:
	return _hops.has(cr)


func critter_hit(cr: Arena.Critter) -> bool:
	if SPLIT_INTO.has(cr.kind):
		_split(cr)
		return true
	if cr.kind == &"boss" and cr.hp > 1:
		_boss_spill(cr)
	return false


## Squish, pop: the slime bursts into two of the next size down, which hop
## apart to free tiles. The halves are made before the parent goes so the
## exit never opens in between.
func _split(cr: Arena.Critter) -> void:
	var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
	var kind: StringName = SPLIT_INTO[cr.kind]
	var count: int = clampi(MAX_CRITTERS - arena.critters.size() + 1, 0, 2)
	var spots: Array[Vector2i] = _split_spots(here, cr)
	for i in count:
		var to: Vector2i = spots[i] if i < spots.size() else here
		_launch(kind, here, to)
	_burst(here, float(M.SLIME_SIZE[cr.kind]))
	_sound(_snd_squish, 1.25 if cr.kind == &"slime_mid" else 1.0)
	arena._kill_critter(cr)


## A new critter of [param kind] that springs from [param from] to [param to].
func _launch(kind: StringName, from: Vector2i, to: Vector2i) -> Arena.Critter:
	var h: Arena.Critter = arena._spawn_critter(kind, from)
	h.invuln = HOP_INVULN
	h.node.scale = Vector3.ONE * 0.55
	if to != from:
		h.target = to
		h.t = 0.0
		var d: Vector2i = to - from
		h.dir = Vector2i(signi(d.x), 0) if absi(d.x) >= absi(d.y) else Vector2i(0, signi(d.y))
		h.speed = 1.0 / HOP_TIME
		_hops[h] = {"to": to, "dist": Vector2(d).length()}
	return h


## Up to two landing tiles one or two steps from [param here] along open
## floor: away from Pip (never his tile), off flames and other critters
## where possible, and far apart from each other.
func _split_spots(here: Vector2i, probe: Arena.Critter) -> Array[Vector2i]:
	var hero: Vector2i = arena.hero_cell() if not arena.demo and arena.hero_alive else Vector2i(-99, -99)
	var depth: Dictionary = {here: 0}
	var queue: Array[Vector2i] = [here]
	var cands: Array[Vector2i] = []
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if int(depth[c]) >= 2:
			continue
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = c + d
			if depth.has(n) or n == hero or not arena._critter_can_enter(probe, n):
				continue
			depth[n] = int(depth[c]) + 1
			queue.append(n)
			cands.append(n)
	var out: Array[Vector2i] = []
	if cands.is_empty():
		return out
	var score: Dictionary = {}
	for c: Vector2i in cands:
		var s: float = float(depth[c]) + arena.rng.randf() * 0.6
		if absi(c.x - hero.x) + absi(c.y - hero.y) >= 2:
			s += 10.0
		if not arena.flames.has(c):
			s += 2.0
		var crowded: bool = false
		for o: Arena.Critter in arena.critters:
			if o.cell == c or o.target == c:
				crowded = true
		if not crowded:
			s += 1.5
		score[c] = s
	var first: Vector2i = cands[0]
	for c: Vector2i in cands:
		if float(score[c]) > float(score[first]):
			first = c
	out.append(first)
	var second := Vector2i(-99, -99)
	var best: float = -999.0
	for c: Vector2i in cands:
		if c == first:
			continue
		var s2: float = float(score[c]) + (absi(c.x - first.x) + absi(c.y - first.y)) * 2.0
		if s2 > best:
			best = s2
			second = c
	if second != Vector2i(-99, -99):
		out.append(second)
	return out


func _update_hops() -> void:
	for cr: Arena.Critter in _hops.keys():
		var hop: Dictionary = _hops[cr]
		if cr.cell == hop["to"] or cr.t >= 1.0:
			_hops.erase(cr)
			cr.speed = maxf(_base_speed(cr), 0.0)
			_drops(Vector3(cr.pos.x, 0.1, cr.pos.y), 3, M.LIME_LIGHT, 1.2)


# --- Potion vats ---------------------------------------------------------------------

func _splash(c: Vector2i) -> void:
	var v: Dictionary = vats[c]
	v["full"] = false
	v["t"] = VAT_REFILL
	var freeze: bool = v["freeze"]
	var color: Color = M.ICE if freeze else M.LIME
	arena._spawn_ring(Vector3(c.x, 0.08, c.y), color, 1.5)
	_drops(Vector3(c.x, 0.7, c.y), 10, color, 3.0)
	if freeze:
		_sound(_snd_freeze, 1.0)
		arena._spawn_sparkles(Vector3(c.x, 0.6, c.y), M.ICE_LIGHT)
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var n := Vector2i(c.x + dx, c.y + dz)
				if arena.tile(n) == Arena.FLOOR and not vats.has(n):
					var f: MeshInstance3D = M.frost()
					f.position = Vector3(n.x, 0.02, n.y)
					arena.add_child(f)
					_frost.append({"node": f, "t": 0.0})
		for cr: Arena.Critter in arena.critters:
			var p := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
			if absi(p.x - c.x) <= 1 and absi(p.y - c.y) <= 1 and not _hops.has(cr):
				_freeze(cr, BOSS_FREEZE if cr.kind == &"boss" else FREEZE_TIME)
	else:
		_sound(_snd_splash, 1.0)
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				_add_goo(Vector2i(c.x + dx, c.y + dz))


func _update_vats(delta: float) -> void:
	for c: Vector2i in vats:
		var v: Dictionary = vats[c]
		var want: float = 1.0
		if not bool(v["full"]):
			v["t"] = float(v["t"]) - delta
			# Drains at once, then fills back up steadily.
			want = clampf(1.0 - float(v["t"]) / VAT_REFILL, 0.06, 1.0)
			if float(v["t"]) <= 0.0:
				v["full"] = true
				want = 1.0
				arena._spawn_sparkles(Vector3(c.x, 0.9, c.y), M.ICE_LIGHT if bool(v["freeze"]) else M.LIME_LIGHT)
		var level: float = float(v["level"])
		level = want if want > level else lerpf(level, want, minf(delta * 12.0, 1.0))
		v["level"] = level
		var liquid: Node3D = v["liquid"]
		liquid.scale = Vector3(1.0, maxf(level, 0.02), 1.0)
		var bubbles: Node3D = v["bubbles"]
		bubbles.visible = level > 0.3
		for b: Node in bubbles.get_children():
			var n: Node3D = b
			var u: float = fmod(_clock * 0.7 + float(n.get_meta(&"phase", 0.0)), 1.0)
			# Bubbles bob up out of the surface and pop.
			n.position.y = 0.14 + 0.62 * level + u * 0.3
			n.scale = Vector3.ONE * (1.0 - u * 0.7)


func _add_goo(c: Vector2i) -> void:
	if arena.tile(c) != Arena.FLOOR or vats.has(c):
		return
	if goo.has(c):
		goo[c]["t"] = GOO_TIME
		return
	var r := RandomNumberGenerator.new()
	r.seed = c.x * 31 + c.y * 7 + int(_clock * 10.0)
	var n: Node3D = M.goo_puddle(r)
	n.position = Vector3(c.x, 0, c.y)
	n.rotation.y = r.randi_range(0, 3) * PI * 0.5
	n.scale = Vector3.ONE * 0.2
	arena.add_child(n)
	goo[c] = {"t": GOO_TIME, "age": 0.0, "node": n}


func _update_goo(delta: float) -> void:
	for c: Vector2i in goo.keys():
		var g: Dictionary = goo[c]
		g["t"] = float(g["t"]) - delta
		g["age"] = float(g["age"]) + delta
		var n: Node3D = g["node"]
		if float(g["t"]) <= 0.0:
			n.queue_free()
			goo.erase(c)
			continue
		var grow: float = minf(float(g["age"]) / 0.22, 1.0)
		var fade: float = minf(float(g["t"]) / 0.6, 1.0)
		var s: float = (0.2 + 0.8 * (1.0 - pow(1.0 - grow, 3.0))) * fade
		n.scale = Vector3(s, 1.0 + sin(_clock * 4.0 + c.x) * 0.15, s)


# --- Freezing ------------------------------------------------------------------------

func _freeze(cr: Arena.Critter, time: float) -> void:
	if _frozen.has(cr):
		_frozen[cr]["t"] = maxf(float(_frozen[cr]["t"]), time)
		return
	# Snap to the nearer tile so the ice sits square on the grid.
	if cr.t > 0.0 and cr.t < 1.0 and cr.t >= 0.5:
		cr.cell = cr.target
	_hold(cr)
	var size: float = 0.95
	if M.SLIME_SIZE.has(cr.kind):
		size = float(M.SLIME_SIZE[cr.kind]) + 0.18
	elif cr.kind == &"labrat":
		size = 0.72
	elif cr.kind == &"boss":
		size = 1.5
	var ice: Node3D = M.ice_cube(size)
	ice.scale = Vector3.ONE * 0.3
	cr.node.add_child(ice)
	_frozen[cr] = {"t": time, "ice": ice}


func _update_frozen(delta: float) -> void:
	for cr: Arena.Critter in _frozen.keys():
		var f: Dictionary = _frozen[cr]
		f["t"] = float(f["t"]) - delta
		var ice: Node3D = f["ice"]
		var left: float = float(f["t"])
		ice.scale = ice.scale.lerp(Vector3.ONE, minf(delta * 14.0, 1.0))
		if left < 0.8:
			# Cracking: a shiver before it thaws.
			ice.position.x = sin(_clock * 60.0) * 0.03
		if left <= 0.0:
			ice.queue_free()
			_frozen.erase(cr)
			cr.t = 1.0
			arena._spawn_sparkles(arena._to3(cr.pos, 0.5), M.ICE_LIGHT)


# --- Lab Rats ---------------------------------------------------------------------------

func _rat(cr: Arena.Critter) -> Dictionary:
	if not _rats.has(cr):
		_rats[cr] = {"run": arena.rng.randf_range(2.0, 3.2), "scan": 0.0}
	return _rats[cr]


## Rats zip about chasing Pip, and every few seconds stop on a tile to scan.
func _update_rats(delta: float) -> void:
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"labrat" or _frozen.has(cr):
			continue
		var s: Dictionary = _rat(cr)
		if float(s["scan"]) > 0.0:
			s["scan"] = float(s["scan"]) - delta
			if float(s["scan"]) <= 0.0:
				s["run"] = arena.rng.randf_range(2.2, 3.4)
				cr.t = 1.0
				cr.speed = SPEEDS[&"labrat"]
			continue
		s["run"] = float(s["run"]) - delta
		if float(s["run"]) <= 0.0 and _at_cell(cr):
			s["scan"] = RAT_SCAN
			_hold(cr)
			if not arena.demo and arena.hero_alive and cr.pos.distance_to(arena.hero_pos) < 6.0:
				_sound(_snd_blip, 1.0)


# --- King Slime -----------------------------------------------------------------------

## Each hit spills two minis that hop out of the beaker.
func _boss_spill(cr: Arena.Critter) -> void:
	if arena.demo:
		return
	var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
	var count: int = clampi(BOSS_CROWD - arena.critters.size(), 0, 2)
	var spots: Array[Vector2i] = _split_spots(here, cr)
	for i in count:
		if i < spots.size():
			_launch(&"slime_small", here, spots[i])
	_burst(here, 1.0)
	_sound(_snd_squish, 0.8)


func _update_lob(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	var live: bool = b != null and not arena.demo and arena.critters.has(b) and arena.state == &"play"
	if _lob.is_empty():
		if not live or b.hp * 2 > arena.boss_max_hp or _frozen.has(b) or not arena.hero_alive:
			return
		_lob_t -= delta
		if _lob_t > 0.0:
			return
		var cell: Vector2i = arena.hero_cell()
		# Only lob at range: up close the marker would hide under the King.
		if absi(cell.x - b.cell.x) + absi(cell.y - b.cell.y) < 3:
			return
		var marker: Node3D = M.lob_marker()
		marker.position = Vector3(cell.x, 0, cell.y)
		arena.add_child(marker)
		_lob = {"st": &"aim", "t": 0.0, "cell": cell, "marker": marker}
		return
	var marker2: Node3D = _lob["marker"]
	if not live:
		_end_lob()
		return
	_lob["t"] = float(_lob["t"]) + delta
	var t: float = _lob["t"]
	marker2.rotation.y += delta * 2.5
	marker2.scale = Vector3.ONE * (1.0 + sin(_clock * 12.0) * 0.08)
	var cell2: Vector2i = _lob["cell"]
	if _lob["st"] == &"aim":
		if t >= LOB_AIM:
			var blob: Node3D = M.goo_blob()
			var from := Vector3(b.pos.x, 1.3, b.pos.y)
			blob.position = from
			arena.add_child(blob)
			_lob["st"] = &"fly"
			_lob["t"] = 0.0
			_lob["blob"] = blob
			_lob["from"] = from
			_sound(_snd_squish, 0.7)
		return
	var u: float = minf(t / LOB_FLY, 1.0)
	var blob2: Node3D = _lob["blob"]
	var to := Vector3(cell2.x, 0.2, cell2.y)
	blob2.position = (_lob["from"] as Vector3).lerp(to, u) + Vector3(0, sin(u * PI) * 2.0, 0)
	blob2.rotation.x += delta * 8.0
	if u >= 1.0:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				if absi(dx) + absi(dz) <= 1:
					_add_goo(Vector2i(cell2.x + dx, cell2.y + dz))
		arena._spawn_ring(Vector3(cell2.x, 0.08, cell2.y), M.LIME, 1.2)
		_drops(Vector3(cell2.x, 0.3, cell2.y), 8, M.LIME, 2.6)
		_sound(_snd_splash, 1.15)
		arena._shake = maxf(arena._shake, 0.15)
		if arena.hero_alive and arena.hero_cell() == cell2:
			arena._hurt_hero()
		_end_lob()


func _end_lob() -> void:
	for key: String in ["marker", "blob"]:
		if _lob.has(key) and is_instance_valid(_lob[key]):
			(_lob[key] as Node3D).queue_free()
	_lob = {}
	_lob_t = LOB_EVERY


# --- Posing ------------------------------------------------------------------------------

func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	if M.SLIME_SIZE.has(cr.kind):
		return _pose_slime(cr, body, t)
	if cr.kind == &"labrat":
		return _pose_rat(cr, body, t)
	if cr.kind == &"boss":
		return _pose_boss(cr, body, t)
	return Vector3.ONE


func _pose_slime(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	# Jelly cubes hop about without turning, so their faces stay on view.
	body.rotation.y = -cr.node.rotation.y
	if _hops.has(cr):
		var u: float = clampf(cr.t, 0.0, 1.0)
		var dist: float = float(_hops[cr]["dist"])
		body.position.y = sin(u * PI) * (0.35 + 0.2 * dist)
		body.rotation.x = sin(u * TAU) * 0.25
		return Vector3(0.9, 1.15, 0.9)
	body.rotation.x = 0.0
	if _frozen.has(cr):
		body.position.y = 0.0
		return Vector3.ONE
	# A springy jelly hop as it goes.
	var moving: bool = cr.t > 0.0 and cr.t < 1.0
	var w: float = sin(t * (9.0 if moving else 4.0))
	body.position.y = absf(w) * 0.07 if moving else 0.0
	var a: float = 0.08 if moving else 0.04
	return Vector3(1.0 + w * a, 1.0 - w * a * 1.3, 1.0 + w * a)


func _pose_rat(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	var wheels: Node3D = body.get_node("Wheels")
	var light: MeshInstance3D = body.get_node("Light")
	var head: Node3D = body.get_node("Head")
	var scanning: bool = _rats.has(cr) and float(_rats[cr]["scan"]) > 0.0
	if _frozen.has(cr):
		return Vector3.ONE
	if scanning:
		head.rotation.y = sin(t * 9.0) * 0.5
		light.visible = fmod(t, 0.16) < 0.09
		light.material_override = Models.mat(M.RED, 1.6)
		body.position.y = 0.0
	else:
		head.rotation.y = lerpf(head.rotation.y, 0.0, 0.2)
		light.visible = true
		light.material_override = Models.mat(M.TEAL, 1.2)
		for w: Node in wheels.get_children():
			(w as Node3D).rotation.x = t * 14.0
		body.position.y = absf(sin(t * 16.0)) * 0.015
	return Vector3.ONE


func _pose_boss(cr: Arena.Critter, body: Node3D, t: float) -> Vector3:
	# The round beaker never needs to turn: the King keeps his face on view.
	body.rotation.y = -cr.node.rotation.y
	var slime: Node3D = body.get_node("Slime")
	var crown: Node3D = slime.get_node("Crown")
	var k: float = float(cr.hp) / float(maxi(arena.boss_max_hp, 1))
	var size: float = M.BOSS_SIZE * (0.74 + 0.26 * k)
	if _frozen.has(cr):
		return Vector3.ONE * size
	var aiming: bool = not _lob.is_empty() and _lob["st"] == &"aim"
	if aiming:
		slime.scale = slime.scale.lerp(Vector3(1.1, 0.86, 1.1), 0.2)
		crown.rotation.x = lerpf(crown.rotation.x, -0.35, 0.2)
	else:
		var w: float = sin(t * 5.0)
		slime.scale = Vector3(1.0 + w * 0.04, 1.0 - w * 0.05, 1.0 + w * 0.04)
		crown.rotation.x = lerpf(crown.rotation.x, 0.0, 0.2)
		crown.rotation.z = sin(t * 2.2) * 0.08
	return Vector3.ONE * size


# --- Effects and sound ----------------------------------------------------------------

## The squish-pop of a split: a ring, sparkles and flung jelly drops.
func _burst(c: Vector2i, size: float) -> void:
	var at := Vector3(c.x, 0.3 + size * 0.3, c.y)
	arena._spawn_ring(Vector3(c.x, 0.08, c.y), M.LIME, 0.8 + size)
	arena._spawn_sparkles(at, M.LIME_LIGHT)
	_drops(at, 6, M.LIME, 2.4)
	arena._shake = maxf(arena._shake, 0.08 + size * 0.1)


## Little glossy drops flung out from [param at].
func _drops(at: Vector3, count: int, color: Color, power: float) -> void:
	if arena._fx.size() > 240:
		return
	var mesh := Models.box_mesh(Vector3(0.12, 0.1, 0.12), 0.045)
	for k in count:
		var a: float = TAU * k / maxf(count, 1) + arena.rng.randf_range(-0.4, 0.4)
		var n := Models.part(arena, mesh, color, at, 0.25)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var out: float = arena.rng.randf_range(0.5, 1.0) * power
		arena._fx.append({"node": n, "t": 0.0, "life": arena.rng.randf_range(0.6, 0.85), "kind": &"debris", "floor": 0.05,
			"vel": Vector3(cos(a) * out, arena.rng.randf_range(2.5, 4.5), sin(a) * out),
			"spin": Vector3(arena.rng.randf_range(-8, 8), arena.rng.randf_range(-8, 8), 0)})


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


## A wet "squish-bloop": a pitch dip into a rising pop.
func _make_squish() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.26)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	var phase: float = 0.0
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 240.0 - 140.0 * minf(t / 0.06, 1.0) + 900.0 * maxf(t - 0.06, 0.0)
		phase += TAU * f / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.2
		var env: float = minf(t / 0.004, 1.0) * exp(-t * 14.0)
		out[i] = (sin(phase) * 0.7 + lp * 0.35 * exp(-t * 30.0)) * env * 0.8
	return _wav(out)


## A splashy slosh with a few bubble blips.
func _make_splash() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * (0.5 - 0.4 * minf(t / 0.4, 1.0))
		var env: float = minf(t / 0.01, 1.0) * exp(-t * 7.0)
		var v: float = lp * env * 0.6
		for b: Vector2 in [Vector2(0.08, 700.0), Vector2(0.17, 950.0), Vector2(0.27, 820.0)]:
			var tb: float = t - b.x
			if tb > 0.0:
				v += sin(TAU * (b.y + 1400.0 * tb) * tb) * exp(-tb * 40.0) * 0.3
		out[i] = v
	return _wav(out)


## A glassy, sparkling freeze: bright detuned chimes over a cold hiss.
func _make_freeze() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 29
	var prev: float = 0.0
	for i in n:
		var t: float = i / rate
		var x: float = rng.randf_range(-1.0, 1.0)
		var hiss: float = (x - prev) * 0.25 * exp(-t * 6.0)
		prev = x
		var chime: float = 0.0
		for f: float in [1760.0, 2217.0, 2637.0, 3520.0]:
			chime += sin(TAU * f * t) * exp(-t * (5.0 + f * 0.002))
		out[i] = (hiss + chime * 0.16) * minf(t / 0.003, 1.0)
	return _wav(out)


## A Lab Rat's double "bip-bip" as it scans.
func _make_blip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		if t < 0.07:
			v = sin(TAU * 1320.0 * t) * minf(t / 0.004, 1.0) * minf((0.07 - t) / 0.01, 1.0)
		elif t > 0.11 and t < 0.18:
			var u: float = t - 0.11
			v = sin(TAU * 1760.0 * u) * minf(u / 0.004, 1.0) * minf((0.07 - u) / 0.01, 1.0)
		out[i] = v * 0.3
	return _wav(out)

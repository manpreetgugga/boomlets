extends WorldKit
## World 7, Prism Caverns: bright pastel crystal caves. The twist is optics.
## A blast that reaches a mirror bends 90° and carries on with its full
## reach; a prism splits a blast three ways (straight on and both sides).
## Bounced beams break crates, light barrels and set off pods like any
## other blast. Crystal Bats zig-zag and dodge blasts they can see coming
## (bounced ones too). The Geode Golem, the boss, holds a crystal shield
## that always turns to face Pip: blasts from that side clink off, so hit it
## from the side or the back, best with a mirror bounce.
##
## Extra map characters (all solid):
##   /  mirror, bottom-left to top-right as seen on screen
##   \  mirror, top-left to bottom-right ("\\" in a map string)
##   P  prism
##   y  Crystal Bat

const Art := preload("res://worlds/world_7_art.gd")

const NONE := Vector2i(-999, -999)
const BAT_SPEED: float = 2.4
const MAX_BOUNCES: int = 6
const SHIELD_TURN: float = 0.9

const PALETTE: Dictionary = {
	"GRASS_A": "#DDF6EB", "GRASS_B": "#C2EBDB", "RIM": "#B994EA", "EDGE": "#9C78D6",
	"STONE": "#D9C9F8", "DARK_STONE": "#B29BE6", "DIRT": "#B79AD6", "ROCK": "#9C86C4",
	"WOOD": "#FFB3D6", "WOOD_DARK": "#FFF2B0", "BARREL": "#FF7A6B",
	"BELT": "#7C6AA6", "ACCENT": "#8FE8C8",
	"SKY_TOP": "#B7A6F2", "SKY_HORIZON": "#FFE0EE", "SKY_GROUND": "#EBD9F5", "CLOUD": "#FFFFFF", "CLOUDS": 0.4,
	"AMBIENT": "#D8D0F0", "SUN": "#FFF2FA",
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Mirror, Mirror",
		"tip": "Mirrors bend a blast 90°.\nAim a pod at a mirror to\nblast round the corner!",
		"crates": 0.45, "par": 65,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b/.....\\b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#../.....\\..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bat Grotto",
		"tip": "Crystal Bats zig-zag and\ndodge blasts they see coming.\nCatch them with a bounce!",
		"crates": 0.45, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.y...E...y.#",
			"#.#.#.#.#.#.#",
			"#../..b..\\..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.y.......y.#",
			"#.#.#.#.#.#.#",
			"#..\\...../..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Prism Split",
		"tip": "A prism splits a blast\ninto three. Light it up\nfrom any side!",
		"crates": 0.42, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.y...E...y.#",
			"#.#.#.#.#.#.#",
			"#../.....\\..#",
			"#.#.#.#.#.#.#",
			"#.....y.....#",
			"#.#..._...#.#",
			"#.b._.P._.b.#",
			"#.#..._...#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Glimmer Gallery",
		"tip": "Barrel blasts bounce off\nmirrors too. Watch out\nfor the backsplash!",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#.#.#.#.#.#",
			"#.y.........#",
			"#.#.#.#.#.#.#",
			"#/....b....\\#",
			"####.###.####",
			"#.y..B.B..y.#",
			"#.#.#.#.#.#.#",
			"#..\\...P./..#",
			"#.#.#.#.#.#.#",
			"#.b.......y.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Rainbow Relay",
		"tip": "Warp pads cross the cave.\nChain mirrors and prisms\nto reach far critters!",
		"crates": 0.4, "par": 100,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1..y#E#y..2#",
			"#.#.#._.#.#.#",
			"#../.....\\..#",
			"#.#.#.#.#.#.#",
			"#.y.P...P.y.#",
			"#.#.#._.#.#.#",
			"######_######",
			"#.#.#._.#.#.#",
			"#.b/..z..\\b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#2..._S_...1#",
			"#############",
		],
	},
	{
		"name": "Geode Heart",
		"tip": "The Geode Golem's shield\nalways faces you. Bounce blasts\noff mirrors to hit its back!",
		"crates": 0.2, "par": 135, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#../.....\\..#",
			"#...........#",
			"#.....K.....#",
			"#.#.......#.#",
			"#..P.....P..#",
			"#.#.......#.#",
			"#...........#",
			"#...........#",
			"#..\\...../..#",
			"#.#.._#_..#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> "/", "\\" or "P".
var optics: Dictionary = {}
var _optic_nodes: Dictionary = {}   # Vector2i -> Node3D
var _optic_flash: Dictionary = {}   # Vector2i -> 0..1
## Which way the newest flame on a cell was travelling (ZERO at a blast's
## centre), and a serial number per flame.
var _flame_dir: Dictionary = {}
var _flame_id: Dictionary = {}
var _flame_seq: int = 0
# Direction inference (flame_stop and on_flame carry no direction).
var _last_stop: Vector2i = NONE
var _origin: Vector2i = NONE
var _origin_frame: int = -1
var _origin_reach: int = 2
var _tracing: bool = false
var _trace_dir: Vector2i = Vector2i.ZERO
var _pod_fire: Dictionary = {}
var _barrel_set: Dictionary = {}
var _pinged: int = -1
# Bats.
var _bats: Dictionary = {}   # Critter -> {"h", "v", "flip"}
var _bat_danger: Dictionary = {}
# The golem's shield.
var _shield: Vector2i = Vector2i(0, 1)
var _shield_t: float = SHIELD_TURN
var _shield_yaw: float = 0.0
var _shield_flash: float = 0.0
var _clinked: int = -1
# Scenery.
var _motes: Array[Node3D] = []
var _spinners: Array[Node3D] = []
var _clock: float = 0.0
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_ping: AudioStreamWAV
var _snd_clink: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Prism Caverns"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_7.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "GEODE GOLEM"


func boss_hp() -> int:
	return 7


func boss_minion_kind() -> StringName:
	return &"bat"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "/" or ch == "\\" or ch == "P":
		optics[c] = ch
		return true
	return false


func critter_chars() -> Dictionary:
	return {"y": &"bat"}


func build_extra() -> void:
	for c: Vector2i in optics:
		var kind: String = optics[c]
		var n: Node3D = Art.prism() if kind == "P" else Art.mirror(kind)
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		_optic_nodes[c] = n
		_optic_flash[c] = 0.0
	for c: Vector2i in arena.barrels:
		_barrel_set[c] = true
	# A few glowing motes drifting over the cave.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var mote_mesh := Models.sphere(0.06, -1, 6)
	var cols: Array[Color] = [Art.LEMON, Art.PINK, Art.AQUA, Art.MINT]
	for k in 14:
		var m := MeshInstance3D.new()
		m.mesh = mote_mesh
		m.material_override = Models.mat(cols[k % cols.size()], 2.0)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(r.randf_range(-1.0, Arena.W), r.randf_range(1.0, 2.6), r.randf_range(-1.0, Arena.H))
		m.set_meta(&"home", m.position)
		m.set_meta(&"phase", r.randf() * TAU)
		arena.add_child(m)
		_motes.append(m)
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -6.0
	arena.add_child(_player2)
	_snd_ping = _make_ping()
	_snd_clink = _make_clink()


## Collects a crystal (unit shaft + tip meshes) into [param into] by colour.
func _crystal_at(into: Dictionary, color: int, p: Vector3, h: float, w: float, tilt: Basis) -> void:
	if not into.has(color):
		into[color] = [[] as Array[Transform3D], [] as Array[Transform3D]]
	var b: Basis = tilt * Basis.from_scale(Vector3(w, h, w))
	(into[color][0] as Array[Transform3D]).append(Transform3D(b, p + b * Vector3(0, 0.36, 0)))
	(into[color][1] as Array[Transform3D]).append(Transform3D(b, p + b * Vector3(0, 0.86, 0)))


func _draw_crystals(into: Dictionary) -> void:
	var cols: Array[Color] = [Art.MINT, Art.PINK, Art.AQUA, Art.LEMON, Art.LILAC]
	var shaft := Models.cylinder(0.1, 0.1, 0.72, 6)
	var tip := Models.cylinder(0.0, 0.1, 0.28, 6)
	for color: int in into:
		var col: Color = cols[color % cols.size()]
		arena._multimesh(shaft, col, into[color][0], Art.crystal_mat(col, 0.3))
		arena._multimesh(tip, col, into[color][1], Art.crystal_mat(col.lightened(0.15), 0.3))


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# A pale stone lip on the wall, and a small crystal on every other block,
	# a big cluster on each corner.
	var caps: Array[Transform3D] = []
	var into: Dictionary = {}
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, 0.66, z)
		caps.append(Transform3D(Basis(), at + Vector3(0, 0.02, 0)))
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if corner:
			for k in 3:
				var a: float = k * TAU / 3.0
				_crystal_at(into, k + x + z, at + Vector3(cos(a) * 0.14, 0, sin(a) * 0.14), 0.75 - k * 0.12, 1.5, Basis(Vector3(-sin(a), 0, cos(a)), 0.3))
		elif (x + z) % 2 == 0:
			var lean := Basis(Vector3.FORWARD, float((x * 5 + z * 3) % 5 - 2) * 0.12)
			_crystal_at(into, (x * 3 + z) % 5, at, 0.42 + float((x + z * 7) % 3) * 0.08, 1.1, lean)
	arena._multimesh(Models.box_mesh(Vector3(0.96, 0.06, 0.96), 0.025), Color(PALETTE["STONE"]), caps)
	_draw_crystals(into)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Lilac stone blocks with a crystal cluster growing out of the top.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 17
	var bodies: Array[Transform3D] = []
	var lids: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var into: Dictionary = {}
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		bodies.append(Transform3D(Basis(), p + Vector3(0, 0.33, 0)))
		lids.append(Transform3D(Basis(), p + Vector3(0, 0.66, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.08, 0)))
		var main: int = r.randi() % 5
		var n: int = r.randi_range(2, 3)
		for k in n:
			var a: float = r.randf() * TAU
			var off := Vector3(cos(a), 0, sin(a)) * (0.0 if k == 0 else r.randf_range(0.12, 0.2))
			var tilt := Basis(Vector3(-off.z, 0, off.x).normalized() if k > 0 else Vector3.RIGHT, 0.0 if k == 0 else 0.45)
			_crystal_at(into, main if k == 0 else (main + k * 2) % 5, p + Vector3(0, 0.68, 0) + off, 0.52 if k == 0 else r.randf_range(0.26, 0.36), 1.3 if k == 0 else 0.9, tilt)
	arena._multimesh(Models.box_mesh(Vector3(0.82, 0.62, 0.82), 0.1), Art.BLOCK, bodies)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.1, 0.9), 0.04), Art.BLOCK.lightened(0.3), lids)
	arena._multimesh(Models.box_mesh(Vector3(0.88, 0.14, 0.88), 0.04), Art.BLOCK.darkened(0.18), bands)
	_draw_crystals(into)
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.25:
			node = Art.crystal_cluster(r, 0.8)
		elif roll < 0.4:
			node = Art.mushroom(r)
	elif p.z < 0.0:
		if roll < 0.35:
			node = Art.spire(r, r.randf_range(1.2, 2.0))
		elif roll < 0.6:
			node = Art.crystal_cluster(r, 1.3)
		elif roll < 0.68:
			node = Art.lantern()
	else:
		if roll < 0.2:
			node = Art.crystal_cluster(r, 1.1)
		elif roll < 0.3:
			node = Art.spire(r, r.randf_range(0.9, 1.4))
		elif roll < 0.42:
			node = Art.mushroom(r)
		elif roll < 0.48:
			node = Art.lantern()
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
		node.rotation.y = r.randf() * TAU
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var s := Art.spire(r, 1.8 + size * 0.3)
	s.scale = Vector3.ONE * 1.3
	root.add_child(s)
	var c := Art.crystal_cluster(r, 1.4)
	c.position = Vector3(size * 0.28, 0, size * 0.18)
	root.add_child(c)
	var m := Art.mushroom(r)
	m.position = Vector3(-size * 0.25, 0, size * 0.2)
	m.scale = Vector3.ONE * 1.6
	root.add_child(m)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF2FA")
	env.adjustment_saturation = 1.08


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return optics.has(c)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not optics.has(c)


func flame_stop(c: Vector2i) -> int:
	# The arena checks this just before it puts a flame on c while running a
	# blast outward, so remember it: the on_flame that follows is an arm.
	_last_stop = c
	return 1 if optics.has(c) else 0


func _reach_at(c: Vector2i) -> int:
	if _pod_fire.has(c):
		return int(_pod_fire[c])
	if _barrel_set.has(c):
		return Arena.BARREL_FIRE
	return maxi(arena.fire, 2)


func on_flame(c: Vector2i) -> void:
	_flame_seq += 1
	_flame_id[c] = _flame_seq
	if _tracing:
		_flame_dir[c] = _trace_dir
		_last_stop = NONE
		return
	var frame: int = Engine.get_process_frames()
	var arm: bool = false
	if c == _last_stop and _origin_frame == frame:
		var off: Vector2i = c - _origin
		if (off.x == 0) != (off.y == 0) and absi(off.x) + absi(off.y) <= _origin_reach:
			arm = true
			var d := Vector2i(signi(off.x), signi(off.y))
			_flame_dir[c] = d
			_last_stop = NONE
			if optics.has(c):
				_bend(c, d, absi(off.x) + absi(off.y), 0, {})
	if not arm:
		# A blast's centre.
		_origin = c
		_origin_frame = frame
		_origin_reach = _reach_at(c)
		_flame_dir[c] = Vector2i.ZERO
		_last_stop = NONE


func _outs(kind: String, d: Vector2i) -> Array[Vector2i]:
	match kind:
		"/":
			return [Vector2i(-d.y, -d.x)]
		"\\":
			return [Vector2i(d.y, d.x)]
	return [d, Vector2i(d.y, d.x), Vector2i(-d.y, -d.x)]


## A blast travelling [param d] has reached the optic at [param c].
func _bend(c: Vector2i, d: Vector2i, dist: int, depth: int, seen: Dictionary) -> void:
	_optic_flash[c] = 1.0
	if _pinged != Engine.get_process_frames():
		_pinged = Engine.get_process_frames()
		_sound(_player, _snd_ping, 1.0 if optics[c] != "P" else 1.26)
	arena._spawn_ring(Vector3(c.x, 0.5, c.y), Art.AQUA.lightened(0.3), 0.8)
	for o: Vector2i in _outs(optics[c], d):
		_trace(c, o, _origin_reach, dist, depth, seen)


func _trace(from: Vector2i, d: Vector2i, reach: int, dist0: int, depth: int, seen: Dictionary) -> void:
	var a: Arena = arena
	for i in range(1, reach + 1):
		var cc: Vector2i = from + d * i
		var t: int = a.tile(cc)
		if t == Arena.WALL:
			break
		_tracing = true
		_trace_dir = d
		a._add_flame(cc, dist0 + i, d)
		_tracing = false
		if optics.has(cc):
			var key := Vector4i(cc.x, cc.y, d.x, d.y)
			if depth < MAX_BOUNCES and not seen.has(key):
				seen[key] = true
				_bend(cc, d, dist0 + i, depth + 1, seen)
			break
		if t == Arena.CRATE:
			a._break_crate(cc)
			break
		if t == Arena.BARREL:
			a._ignite_barrel(cc)
			break
		if a.pod_at.has(cc):
			var other: Arena.Pod = a.pod_at[cc]
			other.timer = minf(other.timer, 0.06)
			break


func process(delta: float) -> void:
	_clock += delta
	_last_stop = NONE
	_pod_fire.clear()
	for p: Arena.Pod in arena.pods:
		_pod_fire[p.cell] = p.fire
	for c: Vector2i in _flame_dir.keys():
		if not arena.flames.has(c):
			_flame_dir.erase(c)
			_flame_id.erase(c)
	for c: Vector2i in _optic_nodes:
		var n: Node3D = _optic_nodes[c]
		var f: float = maxf(float(_optic_flash[c]) - delta * 2.5, 0.0)
		_optic_flash[c] = f
		if optics[c] == "P":
			var spin: Node3D = n.get_node("Spin")
			spin.rotation.y += delta * (0.5 + f * 9.0)
			spin.scale = Vector3.ONE * (1.0 + f * 0.15)
		else:
			var pane: Node3D = n.get_node("Pane")
			pane.scale = Vector3.ONE * (1.0 + f * 0.12)
			var shine: Node3D = pane.get_node("Shine")
			shine.position.x = -0.2 + sin(_clock * 0.8 + c.x) * 0.25 + f * 0.4
	for m: Node3D in _motes:
		var home: Vector3 = m.get_meta(&"home")
		var ph: float = m.get_meta(&"phase")
		m.position = home + Vector3(sin(_clock * 0.4 + ph) * 0.5, sin(_clock * 0.9 + ph * 2.0) * 0.25, cos(_clock * 0.35 + ph) * 0.4)
		m.scale = Vector3.ONE * (0.8 + 0.4 * absf(sin(_clock * 1.6 + ph)))
	_shield_flash = maxf(_shield_flash - delta * 3.0, 0.0)
	var b: Arena.Critter = arena.boss
	if b != null and not arena.demo and arena.state == &"play":
		_shield_t -= delta
		if _shield_t <= 0.0:
			_shield_t = SHIELD_TURN if b.hp > 3 else SHIELD_TURN * 0.75
			_turn_shield(b)
	for cr: Arena.Critter in _bats.keys():
		if not arena.critters.has(cr):
			_bats.erase(cr)


## Turns the golem's shield a quarter step toward Pip.
func _turn_shield(b: Arena.Critter) -> void:
	if arena.hero == null or not arena.hero_alive:
		return
	var v: Vector2 = arena.hero_pos - b.pos
	if v.length() < 0.3:
		return
	var want := Vector2i(signi(roundi(signf(v.x))), 0) if absf(v.x) > absf(v.y) else Vector2i(0, signi(roundi(signf(v.y))))
	if want == _shield:
		return
	if want == -_shield:
		if _shield.x != 0:
			_shield = Vector2i(0, 1 if v.y >= 0.0 else -1)
		else:
			_shield = Vector2i(1 if v.x >= 0.0 else -1, 0)
	else:
		_shield = want


# --- Critters -----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"bat":
			return Art.bat()
		&"boss":
			return Art.boss()
	return null


func critter_speed(kind: StringName) -> float:
	return BAT_SPEED if kind == &"bat" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind != &"boss" or cr != arena.boss:
		return false
	var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
	if not _flame_dir.has(here):
		return false
	var d: Vector2i = _flame_dir[here]
	# A blast's centre has no direction: it reaches the golem from the side
	# it walks in from.
	var from_front: bool = d == -_shield if d != Vector2i.ZERO else cr.dir == _shield
	if not from_front:
		return false
	# Clink! The blast came from the shield side.
	var id: int = _flame_id.get(here, -1)
	if id != _clinked:
		_clinked = id
		_shield_flash = 1.0
		var at := Vector3(cr.pos.x + _shield.x * 0.7, 0.7, cr.pos.y + _shield.y * 0.7)
		arena._spawn_ring(at, Art.AQUA.lightened(0.4), 0.8)
		arena._spawn_sparkles(at, Art.AQUA.lightened(0.3))
		_sound(_player2, _snd_clink, arena.rng.randf_range(0.95, 1.08))
	return true


func _bat(cr: Arena.Critter) -> Dictionary:
	if not _bats.has(cr):
		_bats[cr] = {"h": 1 if arena.rng.randf() < 0.5 else -1, "v": 1 if arena.rng.randf() < 0.5 else -1, "flip": arena.rng.randf() < 0.5}
	return _bats[cr]


## Cells a bat should keep out of: live flames, plus the blast lines (and
## their bounces off mirrors and prisms) of pods it has noticed. Like every
## critter it only notices pods close by and about to burst (see Arena's
## critter_notice and critter_sight).
func _danger(cr: Arena.Critter) -> Dictionary:
	_bat_danger = arena.flames.duplicate()
	for p: Arena.Pod in arena.pods:
		if p.timer > arena.critter_notice or absi(p.cell.x - cr.cell.x) + absi(p.cell.y - cr.cell.y) > arena.critter_sight:
			continue
		_bat_danger[p.cell] = true
		for d: Vector2i in Arena.DIRS:
			_predict(p.cell, d, p.fire, 0)
	return _bat_danger


func _predict(from: Vector2i, d: Vector2i, reach: int, depth: int) -> void:
	for i in range(1, reach + 1):
		var cc: Vector2i = from + d * i
		if arena.tile(cc) == Arena.WALL:
			return
		_bat_danger[cc] = true
		if optics.has(cc):
			if depth < 3:
				for o: Vector2i in _outs(optics[cc], d):
					_predict(cc, o, reach, depth + 1)
			return
		if arena.tile(cc) != Arena.FLOOR or arena.pod_at.has(cc):
			return


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"bat":
		return Vector2i.ZERO
	var s: Dictionary = _bat(cr)
	var rng: RandomNumberGenerator = arena.rng
	if rng.randf() < 0.12:
		s["h"] = -int(s["h"])
	if rng.randf() < 0.12:
		s["v"] = -int(s["v"])
	var flip: bool = s["flip"]
	s["flip"] = not flip
	var first := Vector2i(int(s["h"]), 0) if flip else Vector2i(0, int(s["v"]))
	var second := Vector2i(0, int(s["v"])) if flip else Vector2i(int(s["h"]), 0)
	# Now and then a bat does not look where it flies (Arena's critter_miss).
	var dodge: bool = rng.randf() >= arena.critter_miss
	var danger: Dictionary = _danger(cr) if dodge else {}
	for d: Vector2i in [first, second, -first, -second]:
		var n: Vector2i = cr.cell + d
		if not arena._critter_can_enter(cr, n) or danger.has(n):
			continue
		# Bounce off walls: remember the new heading on that axis.
		if d.x != 0:
			s["h"] = d.x
		else:
			s["v"] = d.y
		return d
	return Vector2i.ZERO


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	if cr.kind == &"bat":
		var fly: Node3D = body.get_node("Fly")
		fly.position.y = 0.42 + sin(t * 6.0) * 0.07
		var flap: float = sin(t * 26.0)
		(fly.get_node("WingL") as Node3D).rotation.z = flap * 0.7
		(fly.get_node("WingR") as Node3D).rotation.z = -flap * 0.7
		fly.rotation.z = lerpf(fly.rotation.z, float(cr.dir.x) * -0.25, minf(delta * 6.0, 1.0))
		return Vector3.ONE * Art.BAT_SIZE
	if cr.kind == &"boss":
		var pivot: Node3D = cr.node.get_node("Pivot")
		_shield_yaw = lerp_angle(_shield_yaw, atan2(float(_shield.x), float(_shield.y)), minf(delta * 10.0, 1.0))
		pivot.rotation.y = _shield_yaw - cr.node.rotation.y
		var sh: Node3D = pivot.get_node("Shield")
		sh.scale = Vector3.ONE * (1.0 + _shield_flash * 0.18)
		sh.position.z = 0.78 + _shield_flash * 0.1
		(body.get_node("Head") as Node3D).rotation.y = sin(t * 1.3) * 0.18
		(body.get_node("ArmL") as Node3D).rotation.x = sin(t * 3.0) * 0.3
		(body.get_node("ArmR") as Node3D).rotation.x = -sin(t * 3.0) * 0.3
		var core: Node3D = body.get_node("Core")
		core.scale = Vector3.ONE * (1.0 + absf(sin(t * 2.5)) * 0.12)
		return Vector3(1.0, 1.0 + absf(sin(t * 3.0)) * 0.04, 1.0) * Art.BOSS_SIZE
	return Vector3.ONE


# --- Sound --------------------------------------------------------------------------

func _sound(p: AudioStreamPlayer, s: AudioStreamWAV, pitch: float) -> void:
	if p == null or s == null or not Save.sound_on or arena.demo:
		return
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


## A glassy chime with two soft echoes: a blast bouncing off a mirror.
func _make_ping() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for e in 3:
			var u: float = t - e * 0.13
			if u < 0.0:
				continue
			var g: float = pow(0.4, e)
			v += g * (sin(TAU * 1760.0 * u) * exp(-u * 7.0) + 0.5 * sin(TAU * 1760.0 * 2.76 * u) * exp(-u * 14.0) + 0.25 * sin(TAU * 1760.0 * 5.4 * u) * exp(-u * 24.0))
		out[i] = v * minf(t / 0.002, 1.0) * 0.45
	return _wav(out)


## A hard bright "clink": a blast glancing off the golem's shield.
func _make_clink() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = sin(TAU * 2637.0 * t) * exp(-t * 18.0) + 0.7 * sin(TAU * 3951.0 * t) * exp(-t * 26.0) + 0.4 * sin(TAU * 6100.0 * t) * exp(-t * 40.0)
		v += 0.5 * sin(TAU * 220.0 * t) * exp(-t * 30.0)
		out[i] = v * 0.42
	return _wav(out)

extends WorldKit
## World 6, Clockwork Keep: a brass-and-teal toy clocktower. The twist is
## turnstiles: a brass hub with two gate arms on opposite sides. Every blast
## that touches a turnstile turns it 90°, so a closed door swings open (and
## an open one shuts). Gear turnstiles tick round on their own every few
## seconds. A turning arm bonks any critter in its way. Wind-up Mice dash
## fast, then stop to wind their key, then dash again. Sir Cuckoo, the boss,
## calls in mice; a turnstile arm that swings into him counts as a hit.
##
## Extra map characters (the four cells round a hub must be "_" floor):
##   |  turnstile, arms north-south     -  turnstile, arms east-west
##   G  gear turnstile, north-south     g  gear turnstile, east-west
##   m  Wind-up Mouse

const Art := preload("res://worlds/world_6_art.gd")

const TURN_CHARS: Dictionary = {"|": [false, true], "-": [false, false], "G": [true, true], "g": [true, false]}
const GEAR_PERIOD: float = 4.0
const MOUSE_SPEED: float = 3.3
const MOUSE_WIND: float = 1.25
const SWAT_REACH: float = 0.78
const MOUSE_SIZE: float = 1.25

const PALETTE: Dictionary = {
	"GRASS_A": "#F7ECD3", "GRASS_B": "#EADBB9", "RIM": "#3FAEA2", "EDGE": "#2B9A8F",
	"STONE": "#F2E6CC", "DARK_STONE": "#CDB892", "DIRT": "#B98258", "ROCK": "#8D705B",
	"WOOD": "#86C3F0", "WOOD_DARK": "#FFF3DA", "BARREL": "#E4572E",
	"BELT": "#6E5A72", "ACCENT": "#FFD45C",
	"SKY_TOP": "#7FCBD9", "SKY_HORIZON": "#FFE6C4", "SKY_GROUND": "#F4DEC0", "CLOUD": "#FFFFFF", "CLOUDS": 0.5,
	"AMBIENT": "#C4DCE6", "SUN": "#FFEFD6",
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Turnstile Door",
		"tip": "A turnstile blocks the door.\nBlast it to turn it 90°\nand slip through the gap!",
		"crates": 0.45, "par": 65,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.......b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#._.#.#.#",
			"#####_-_#####",
			"#.#.#._.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Wind-Up Alley",
		"tip": "Wind-up Mice dash fast,\nthen stop to wind their key.\nCatch them while they wind!",
		"crates": 0.45, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.......b.#",
			"#.#._.#._.#.#",
			"###_|_#_-_###",
			"#.#._.#._.#.#",
			"#.....m.....#",
			"#.#.#.#.#.#.#",
			"#.b.......m.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Gear Gallery",
		"tip": "Gear turnstiles turn by themselves\nevery four ticks. Time your dash!\nA swinging arm bonks critters.",
		"crates": 0.42, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.......m.#",
			"#.#._.#.#.#.#",
			"###_g_#######",
			"#.#._.#.#.#.#",
			"#.b...m...b.#",
			"#.#.#.#._.#.#",
			"#######_-_###",
			"#.#.#.#._.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Pendulum Hall",
		"tip": "Barrel blasts turn turnstiles too.\nSix critters wind through the hall!",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#.#_#.#.#.#",
			"#.m._|_...m.#",
			"#.#.#_#.#.#.#",
			"#.._....._..#",
			"##_-_###_g_##",
			"#.b_..B.._m.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.m.......b.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Escapement",
		"tip": "The exit hides behind a turnstile.\nWarp pads cross the keep —\nmind the ticking gears!",
		"crates": 0.4, "par": 100,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#.m.#.E.#.m.#",
			"#.#.#._.#.#.#",
			"#1..#_-_#..2#",
			"#.#.#._.#.#.#",
			"#...........#",
			"#.#_#.#.#_#.#",
			"#._G_.b._g_.#",
			"#.#_#.#.#_#.#",
			"#.m.......m.#",
			"#.#.#.#.#.#.#",
			"#2....z....1#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Cuckoo's Belfry",
		"tip": "Sir Cuckoo keeps the time!\nBlast him seven times —\na turnstile bonk counts too!",
		"crates": 0.2, "par": 125, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#.._....._..#",
			"#._G_..._-_.#",
			"#.._....._..#",
			"#.....K.....#",
			"#.#.......#.#",
			"#...........#",
			"#.._....._..#",
			"#._|_..._g_.#",
			"#.._....._..#",
			"#.#.._#_..#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i hub -> {"gear", "vert", "angle", "target", "cool", "timer",
## "wobble", "node", "arms", "hand", "cog"}.
var turnstiles: Dictionary = {}
## Vector2i -> hub, for every cell a turnstile fills right now (hub + arms).
var _fill: Dictionary = {}
var _queued: Array[Vector2i] = []
var _mice: Dictionary = {}    # Critter -> {"run", "left", "wind"}
var _spinners: Array[Node3D] = []
var _swingers: Array[Node3D] = []
var _clock: float = 0.0
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_turn: AudioStreamWAV
var _snd_jam: AudioStreamWAV
var _snd_tick: AudioStreamWAV
var _snd_wind: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Clockwork Keep"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_6.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "SIR CUCKOO"


func boss_hp() -> int:
	return 7


func boss_minion_kind() -> StringName:
	return &"mouse"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if TURN_CHARS.has(ch):
		var spec: Array = TURN_CHARS[ch]
		var vert: bool = spec[1]
		var a: float = 0.0 if vert else PI * 0.5
		turnstiles[c] = {"gear": bool(spec[0]), "vert": vert, "angle": a, "target": a, "cool": 0.0,
			"timer": GEAR_PERIOD, "wobble": 0.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"m": &"mouse"}


func build_extra() -> void:
	for hub: Vector2i in turnstiles:
		var ts: Dictionary = turnstiles[hub]
		var n: Node3D = Art.turnstile(ts["gear"])
		n.position = Vector3(hub.x, 0, hub.y)
		arena.add_child(n)
		ts["node"] = n
		ts["arms"] = n.get_node("Arms")
		(ts["arms"] as Node3D).rotation.y = ts["angle"]
		if ts["gear"]:
			ts["hand"] = n.get_node("Top/Dial/Hand")
			ts["cog"] = n.get_node("Top/Cog")
			# Stagger the gears so they do not all turn at once.
			ts["timer"] = GEAR_PERIOD - float(turnstiles.keys().find(hub) % 2) * 2.0
	_refill()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -5.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -12.0
	arena.add_child(_player2)
	_snd_turn = _make_turn()
	_snd_jam = _make_jam()
	_snd_tick = _make_tick()
	_snd_wind = _make_wind()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# A brass rail along the top of the wall, rivets, and a little teal cog
	# lying on every third block.
	var rails_x: Array[Transform3D] = []
	var rails_z: Array[Transform3D] = []
	var rivets: Array[Transform3D] = []
	var cogs: Array[Transform3D] = []
	var hubs: Array[Transform3D] = []
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, 0.7, z)
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if corner:
			cogs.append(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5).scaled(Vector3(1.25, 1.25, 1.25)), at + Vector3(0, 0.03, 0)))
			hubs.append(Transform3D(Basis(), at + Vector3(0, 0.08, 0)))
			continue
		if z == 0 or z == h - 1:
			rails_x.append(Transform3D(Basis(), at))
		else:
			rails_z.append(Transform3D(Basis(), at))
		rivets.append(Transform3D(Basis(), at + Vector3(0, 0.02, 0)))
		if (x + z) % 3 == 0:
			cogs.append(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5) * Basis(Vector3.FORWARD, float(x * 7 + z) * 0.3), at + Vector3(0, 0.03, 0)))
			hubs.append(Transform3D(Basis(), at + Vector3(0, 0.07, 0)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.05, 0.22), 0.02), Art.BRASS, rails_x)
	arena._multimesh(Models.box_mesh(Vector3(0.22, 0.05, 1.0), 0.02), Art.BRASS, rails_z)
	arena._multimesh(Models.cylinder(0.05, 0.05, 0.05, 8), Art.BRASS_DARK, rivets)
	arena._multimesh(Art.gear_mesh(0.26, 0.07, 9), Art.TEAL, cogs)
	arena._multimesh(Models.cylinder(0.08, 0.08, 0.06, 10), Art.CREAM, hubs)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Each solid block is a little teal clock cabinet with a brass lid and a
	# clock face on the camera side; some have a cog on top.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var bodies: Array[Transform3D] = []
	var lids: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var dials: Array[Transform3D] = []
	var rims: Array[Transform3D] = []
	var hands_a: Array[Transform3D] = []
	var hands_b: Array[Transform3D] = []
	var cogs: Array[Transform3D] = []
	var face_rot := Basis(Vector3.RIGHT, PI * 0.5)
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		bodies.append(Transform3D(Basis(), p + Vector3(0, 0.35, 0)))
		lids.append(Transform3D(Basis(), p + Vector3(0, 0.72, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.12, 0)))
		var fc: Vector3 = p + Vector3(0, 0.42, 0.415)
		dials.append(Transform3D(face_rot, fc))
		rims.append(Transform3D(face_rot.scaled(Vector3(1, 0.5, 1)), fc + Vector3(0, 0, 0.005)))
		var hr: float = r.randf() * TAU
		hands_a.append(Transform3D(Basis(Vector3.BACK, hr), fc + Vector3(0, 0, 0.03)) * Transform3D(Basis(), Vector3(0, 0.05, 0)))
		var mn: float = r.randf() * TAU
		hands_b.append(Transform3D(Basis(Vector3.BACK, mn), fc + Vector3(0, 0, 0.035)) * Transform3D(Basis(), Vector3(0, 0.08, 0)))
		if r.randf() < 0.4:
			cogs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, -PI * 0.5), p + Vector3(r.randf_range(-0.12, 0.12), 0.8, r.randf_range(-0.12, 0.08))))
	arena._multimesh(Models.box_mesh(Vector3(0.8, 0.66, 0.8), 0.09), Art.TEAL, bodies)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.04), Art.TEAL.lightened(0.28), lids)
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.07, 0.84), 0.025), Art.BRASS, bands)
	arena._multimesh(Models.cylinder(0.2, 0.2, 0.03, 18), Art.CREAM, dials)
	arena._multimesh(Art.ring_mesh(0.18, 0.23, 20), Art.BRASS, rims)
	arena._multimesh(Models.box_mesh(Vector3(0.035, 0.11, 0.015), 0.005), Art.INK, hands_a)
	arena._multimesh(Models.box_mesh(Vector3(0.025, 0.16, 0.015), 0.005), Art.ROSE, hands_b)
	arena._multimesh(Art.gear_mesh(0.2, 0.08, 8), Art.BRASS_DARK, cogs)
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.3:
			node = Art.cog_pile(r)
	elif p.z < 0.0:
		if roll < 0.32:
			node = Art.clock_tower(r, r.randf_range(1.2, 1.9))
		elif roll < 0.55:
			node = Art.standing_gear(r, r.randf_range(0.9, 1.3))
		elif roll < 0.64:
			node = Art.pendulum_post()
	else:
		if roll < 0.18:
			node = Art.standing_gear(r, r.randf_range(0.7, 1.0))
		elif roll < 0.3:
			node = Art.clock_tower(r, r.randf_range(0.8, 1.2))
		elif roll < 0.38:
			node = Art.bell()
		elif roll < 0.5:
			node = Art.cog_pile(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
		if p.x < 0.0:
			node.rotation.y = PI * 0.5
		elif p.x > Arena.W - 1:
			node.rotation.y = -PI * 0.5
		holder.add_child(node)
		_collect_movers(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var t := Art.clock_tower(r, 1.6 + size * 0.2)
	t.scale = Vector3.ONE * 1.3
	root.add_child(t)
	var g := Art.standing_gear(r, 1.1)
	g.position = Vector3(size * 0.3, 0, size * 0.15)
	root.add_child(g)
	_collect_movers(root)
	return root


func _collect_movers(n: Node) -> void:
	for ch: Node in n.find_children("Spin", "", true, false):
		_spinners.append(ch as Node3D)
	for ch: Node in n.find_children("Swing", "", true, false):
		_swingers.append(ch as Node3D)


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF0DA")
	env.adjustment_saturation = 1.1


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return _fill.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if _fill.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if _fill.has(c):
		var hub: Vector2i = _fill[c]
		if float(turnstiles[hub]["cool"]) <= 0.0 and not _queued.has(hub):
			_queued.append(hub)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not _fill.has(c)


func _arm_cells(hub: Vector2i, vert: bool) -> Array[Vector2i]:
	if vert:
		return [hub + Vector2i(0, -1), hub + Vector2i(0, 1)]
	return [hub + Vector2i(-1, 0), hub + Vector2i(1, 0)]


func _refill() -> void:
	_fill.clear()
	for hub: Vector2i in turnstiles:
		_fill[hub] = hub
		for c: Vector2i in _arm_cells(hub, turnstiles[hub]["vert"]):
			_fill[c] = hub


## Turns the turnstile at [param hub] a quarter turn. Returns false when
## something stands in the way (it jams and wobbles instead).
func _turn(hub: Vector2i) -> bool:
	var ts: Dictionary = turnstiles[hub]
	ts["cool"] = 0.6
	var cells: Array[Vector2i] = _arm_cells(hub, not ts["vert"])
	var a: Arena = arena
	var jam: bool = false
	for c: Vector2i in cells:
		if a.tile(c) != Arena.FLOOR or a.pod_at.has(c):
			jam = true
		for p: Arena.Pod in a.pods:
			if p.pos.distance_to(Vector2(c)) < 0.85:
				jam = true
		if not a.demo and a.hero != null and a.hero_alive and a.hero_pos.distance_to(Vector2(c)) < 0.86:
			jam = true
		var b: Arena.Critter = a.boss
		if b != null and b.pos.distance_to(Vector2(c)) < SWAT_REACH + 0.1:
			jam = true
			if b.invuln <= 0.0 and a.state == &"play":
				# Bonk! The arm knocks Sir Cuckoo and bounces back.
				a._hit_critter(b)
				a._spawn_ring(Vector3(b.pos.x, 0.5, b.pos.y), Art.SUNNY, 0.9)
	if jam:
		ts["wobble"] = 1.0
		_sound(_snd_jam, 1.0)
		return false
	# Swat any critter the arms sweep into.
	for cr: Arena.Critter in a.critters.duplicate():
		if cr == a.boss:
			continue
		for c: Vector2i in cells:
			if cr.pos.distance_to(Vector2(c)) < SWAT_REACH and a.critters.has(cr):
				a._spawn_ring(Vector3(cr.pos.x, 0.4, cr.pos.y), Art.SUNNY, 0.7)
				a._kill_critter(cr)
	ts["vert"] = not ts["vert"]
	ts["target"] = float(ts["target"]) + PI * 0.5
	_refill()
	a._spawn_sparkles(Vector3(hub.x, 0.8, hub.y), Art.BRASS.lightened(0.3))
	a._shake = maxf(a._shake, 0.08)
	_sound(_snd_turn, 1.0 if not ts["gear"] else 1.12)
	return true


func process(delta: float) -> void:
	_clock += delta
	for n: Node3D in _spinners:
		n.rotation.z += delta * float(n.get_meta(&"speed", 0.5))
	for n: Node3D in _swingers:
		n.rotation.x = sin(_clock * 2.2) * 0.35
	for hub: Vector2i in _queued:
		_turn(hub)
		turnstiles[hub]["timer"] = GEAR_PERIOD
	_queued.clear()
	for hub: Vector2i in turnstiles:
		var ts: Dictionary = turnstiles[hub]
		ts["cool"] = maxf(float(ts["cool"]) - delta, 0.0)
		if ts["gear"] and arena.state == &"play":
			var before: float = ts["timer"]
			ts["timer"] = float(ts["timer"]) - delta
			# A soft tick each second through the last two.
			if not arena.demo and floorf(before) != floorf(float(ts["timer"])) and float(ts["timer"]) < 2.0 and float(ts["timer"]) > 0.0:
				_tick()
			if float(ts["timer"]) <= 0.0:
				ts["timer"] = GEAR_PERIOD if _turn(hub) else 0.3
		_animate(ts, delta)
	if not arena.demo:
		_update_mice(delta)


func _animate(ts: Dictionary, delta: float) -> void:
	var arms: Node3D = ts["arms"]
	ts["angle"] = move_toward(float(ts["angle"]), float(ts["target"]), delta * 7.5)
	ts["wobble"] = maxf(float(ts["wobble"]) - delta * 3.0, 0.0)
	arms.rotation.y = float(ts["angle"]) + sin(float(ts["wobble"]) * 30.0) * 0.12 * float(ts["wobble"])
	if ts["gear"]:
		# The hand steps round once per turn, a tick each second.
		var left: float = clampf(float(ts["timer"]), 0.0, GEAR_PERIOD)
		var ticks: float = floorf(GEAR_PERIOD - left)
		var frac: float = (GEAR_PERIOD - left) - ticks
		var step: float = ticks + minf(frac / 0.12, 1.0)
		(ts["hand"] as Node3D).rotation.y = -step * TAU / GEAR_PERIOD
		(ts["cog"] as Node3D).rotation.y = step * 0.4
		var warn: bool = left < 1.0
		var top: Node3D = (ts["node"] as Node3D).get_node("Top")
		top.scale = Vector3.ONE * (1.0 + (0.08 * absf(sin(_clock * 14.0)) if warn else 0.0))


# --- Critters -----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"mouse":
			return Art.mouse()
		&"boss":
			return Art.boss()
	return null


func critter_speed(kind: StringName) -> float:
	return MOUSE_SPEED if kind == &"mouse" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func _mouse(cr: Arena.Critter) -> Dictionary:
	if not _mice.has(cr):
		_mice[cr] = {"left": arena.rng.randi_range(4, 7), "wind": 0.0}
	return _mice[cr]


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"mouse":
		return Vector2i.ZERO
	var m: Dictionary = _mouse(cr)
	if float(m["wind"]) > 0.0:
		return Vector2i.ZERO
	m["left"] = int(m["left"]) - 1
	if int(m["left"]) <= 0:
		# Run down: stop and wind the key.
		m["wind"] = MOUSE_WIND + arena.rng.randf_range(0.0, 0.35)
		m["dir"] = cr.dir
		m["left"] = arena.rng.randi_range(4, 7)
		if arena.hero != null and arena.hero_pos.distance_to(cr.pos) < 5.0:
			_sound(_snd_wind, arena.rng.randf_range(0.95, 1.1), true)
	return Vector2i.ZERO


func _update_mice(delta: float) -> void:
	for cr: Arena.Critter in _mice.keys():
		if not arena.critters.has(cr):
			_mice.erase(cr)
			continue
		var m: Dictionary = _mice[cr]
		if float(m["wind"]) <= 0.0:
			continue
		m["wind"] = float(m["wind"]) - delta
		cr.target = cr.cell
		cr.dir = m.get("dir", cr.dir)
		cr.t = 1.0 if float(m["wind"]) <= 0.0 else 0.0
		cr.pos = Vector2(cr.cell)


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	if cr.kind == &"mouse":
		var m: Dictionary = _mouse(cr)
		var key: Node3D = body.get_node("Key")
		var tail: Node3D = body.get_node("Tail")
		if float(m["wind"]) > 0.0:
			# Winding up: the key whirls backwards and the mouse shivers.
			key.rotation.z -= delta * 16.0
			body.position = Vector3(sin(t * 55.0) * 0.015, 0.0, 0.0)
			body.rotation.x = lerpf(body.rotation.x, -0.12, 0.2)
			tail.rotation.y = sin(t * 30.0) * 0.4
			return Vector3(1.06, 0.92, 1.06) * MOUSE_SIZE
		key.rotation.z += delta * 6.0
		body.position = Vector3(0.0, absf(sin(t * 18.0)) * 0.035, 0.0)
		body.rotation.x = lerpf(body.rotation.x, 0.1, 0.25)
		tail.rotation.y = sin(t * 12.0) * 0.5
		return Vector3.ONE * MOUSE_SIZE
	if cr.kind == &"boss":
		var hands: Node3D = body.get_node("Face/Hands")
		hands.rotation.z -= delta * (1.5 + (7 - cr.hp) * 0.6)
		var pend: Node3D = body.get_node("Pendulum")
		pend.rotation.z = sin(t * 3.2) * 0.45
		var key: Node3D = body.get_node("Key")
		key.rotation.z += delta * 3.0
		var bird: Node3D = body.get_node("Bird")
		# The cuckoo pops out just before each summon.
		var out: bool = cr.think < 0.6 or cr.invuln > 0.9
		bird.position.z = lerpf(bird.position.z, 0.52 if out else 0.3, minf(delta * 12.0, 1.0))
		body.get_node("ArmL").rotation.x = sin(t * 4.0) * 0.25
		body.get_node("ArmR").rotation.x = -sin(t * 4.0) * 0.25
		body.get_node("Plume").rotation.x = sin(t * 5.0) * 0.12
		return Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.05, 1.0) * Art.BOSS_SIZE
	return Vector3.ONE


# --- Sound --------------------------------------------------------------------------

func _tick() -> void:
	if _player2 == null or not Save.sound_on:
		return
	_player2.stream = _snd_tick
	_player2.pitch_scale = 1.0
	_player2.play()


func _sound(s: AudioStreamWAV, pitch: float, quiet: bool = false) -> void:
	var p: AudioStreamPlayer = _player2 if quiet else _player
	if p == null or s == null or not Save.sound_on:
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


## A ratchety "clk-clk-clunk" and a little bell for a turn.
func _make_turn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.42)
	var out := PackedFloat32Array()
	out.resize(n)
	var seed_v: int = 7
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for k in 4:
			var t0: float = k * 0.045
			if t >= t0:
				var u: float = t - t0
				seed_v = (seed_v * 1103515245 + 12345) & 0x7fffffff
				var noise: float = float(seed_v % 2000) / 1000.0 - 1.0
				v += (noise * 0.5 + sin(TAU * (1800.0 - k * 150.0) * u)) * exp(-u * 160.0) * 0.5
		if t > 0.16:
			var u2: float = t - 0.16
			v += (sin(TAU * 1568.0 * u2) + 0.4 * sin(TAU * 2352.0 * u2)) * exp(-u2 * 9.0) * 0.35
		out[i] = v * 0.6
	return _wav(out)


## A dull wooden "thunk" when a turnstile jams.
func _make_jam() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var f: float = 160.0 + 90.0 * exp(-t * 30.0)
		out[i] = (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.7 * t)) * exp(-t * 22.0) * 0.6
	return _wav(out)


## A tiny clock tick.
func _make_tick() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.06)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		out[i] = (sin(TAU * 3200.0 * t) * 0.6 + sin(TAU * 1900.0 * t) * 0.4) * exp(-t * 120.0) * 0.5
	return _wav(out)


## A quick rising ratchet: a mouse winding its key.
func _make_wind() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var rate_hz: float = 18.0 + 20.0 * t
		var ph: float = fmod(t * rate_hz, 1.0)
		var click: float = exp(-ph * 30.0)
		out[i] = sin(TAU * (2200.0 + 600.0 * t) * t) * click * 0.35
	return _wav(out)

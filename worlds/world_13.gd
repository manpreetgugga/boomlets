extends WorldKit
## World 13, Rhythm Cloudway: a cloud-top concert in the sky. Everything
## moves to the world's own beat (100 BPM), kept by an elapsed-time clock so
## it plays the same with the sound off.
##
## Beat tiles: pink (m) and blue (n) cloud-candy platforms swap places every
## few beats over holes in the clouds (~ is a hole that never fills). In the
## last beats before a swap the leaving tiles shake and blink and the
## arriving ones' outlines pulse, and the beat chip at the bottom counts in.
## A tile never drops out from under Pip: it waits until he (or a pod or a
## critter on it) has stepped off, blinking.
## Drum pads (D): a pod set on a drum pops exactly on the next downbeat.
## Thumpers (h) are drum critters that hop one tile per beat, and Maestro
## the conductor bird (K) hops to the beat too, twice as often when hurt.
##
## Extra level keys: "swap": beats between tile swaps.

const M := preload("res://worlds/world_13_models.gd")

const BPM: float = 100.0
const BEAT: float = 60.0 / BPM
const BAR: float = BEAT * 4.0
## The music loop is 16 bars long; the beat clock is kept in step with it.
const LOOP: float = BAR * 16.0
const THUMP_SPEED: float = 1.0 / (BEAT * 0.5)
const NO_CELL := Vector2i(-99, -99)
const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const PALETTE: Dictionary = {
	"GRASS_A": "#F7F4FF", "GRASS_B": "#ECE7FC", "RIM": "#E9EEFF", "EDGE": "#8F9DEB",
	"STONE": "#FFFFFF", "DARK_STONE": "#DCE2FA", "DIRT": "#D5DDFA", "ROCK": "#BCC8F2",
	"WOOD": "#FFD36B", "WOOD_DARK": "#FFFFFF", "BARREL": "#FF5D6C", "ACCENT": "#FFC53D",
	"BLOBBIT": "#8C72F0", "LEAFY_A": "#FFFFFF", "LEAFY_B": "#E8ECFF",
	"SKY_TOP": "#86A9F2", "SKY_HORIZON": "#FFD9E8", "SKY_GROUND": "#F2E8FF", "CLOUD": "#FFFFFF", "CLOUDS": 0.85,
	"AMBIENT": "#CBD3F7", "AMBIENT_ENERGY": 0.6, "SUN": "#FFF0F2", "SUN_ENERGY": 1.45,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "First Beat",
		"tip": "Pink and blue tiles swap on the beat.\nWatch the count-in and cross\nwhen your bridge is up!",
		"crates": 0.35, "par": 70, "swap": 8,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..h.....h..#",
			"#.#.#.#.#.#.#",
			"#.._....._..#",
			"#~~m~~~~~n~~#",
			"#~~m~~~~~n~~#",
			"#~~m~~~~~n~~#",
			"#.._....._..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Stepping Stones",
		"tip": "Step on, wait for the swap, step on!\nA tile waits until you leave it.\nPods on drums pop on the downbeat.",
		"crates": 0.38, "par": 80, "swap": 4,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..h..b..h..#",
			"#.#.#.#.#.#.#",
			"#._...D..._.#",
			"#~m~~~m~~~n~#",
			"#~n~~~n~~~m~#",
			"#~m~~~m~~~n~#",
			"#._...D..._.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Drum Circle",
		"tip": "Thumpers hop on every beat.\nTime a drum pod to catch them\nmid-groove!",
		"crates": 0.36, "par": 85, "swap": 4,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..h.....h..#",
			"#.#_#._.#_#.#",
			"#~~m~~n~~m~~#",
			"#..D.....D..#",
			"#.#.#.b.#.#.#",
			"#..h.....h..#",
			"#~~n~~m~~n~~#",
			"#.#_#._.#_#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Cloud Hopscotch",
		"tip": "Rows of pink and blue:\nhop from one colour to the other\nas they swap.",
		"crates": 0.38, "par": 95, "swap": 4,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.z..h.h..z.#",
			"#.#.#.#.#.#.#",
			"#~mnmnmnmnm~#",
			"#~nmnmnmnmn~#",
			"#.....D.....#",
			"#.#.#.#.#.#.#",
			"#..h..b..h..#",
			"#~mnm~~~mnm~#",
			"#~nmn~~~nmn~#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Double Time",
		"tip": "The tiles swap every two beats now.\nKeep to the rhythm!",
		"crates": 0.36, "par": 100, "swap": 2,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.h.z...z.h.#",
			"#.#.#.#.#.#.#",
			"#mnm~D.D~mnm#",
			"#~~n~~m~~n~~#",
			"#..h..b..h..#",
			"#~~m~~n~~m~~#",
			"#.#.#.#.#.#.#",
			"#.....D.....#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Maestro's Finale",
		"tip": "Maestro hops to the beat!\nDrum pods pop on the downbeat.\nHit him nine times.",
		"crates": 0.22, "par": 130, "swap": 4, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#..m..n..m..#",
			"#.n.......n.#",
			"#...D...D...#",
			"#.m...K...m.#",
			"#...........#",
			"#.n.D...D.n.#",
			"#...........#",
			"#..m..n..m..#",
			"#.#.......#.#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Beat tiles: Vector2i -> {"set", "node", "solid", "held", "show"}.
var beat_tiles: Dictionary = {}
## Holes in the clouds that never fill.
var voids: Dictionary = {}
## Drum pads: Vector2i -> {"node", "bump"}.
var drums: Dictionary = {}

var _swap: int = 4
var _clock: float = 0.0
var _beat_i: int = -1
var _beat_hit: bool = false
var _half_hit: bool = false
var _half_i: int = -1
var _resync: bool = true
var _resync_t: float = 0.0
var _drummed: Dictionary = {}
var _notes: Array[Node3D] = []

# Tap walking: keep going once a bridge comes back.
var _want := NO_CELL
var _want_before := NO_CELL
var _seen_tap: int = -1

var _ui: Control
var _player: AudioStreamPlayer
var _snd_tick: AudioStreamWAV
var _snd_swap: AudioStreamWAV
var _snd_drum: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Rhythm Cloudway"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_13.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "MAESTRO"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	return &"thumper"


# --- Building -----------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"m":
			beat_tiles[c] = {"set": 0, "solid": true, "held": false, "show": 1.0}
			return true
		"n":
			beat_tiles[c] = {"set": 1, "solid": true, "held": false, "show": 1.0}
			return true
		"~":
			voids[c] = true
			return true
		"D":
			drums[c] = {"bump": 0.0}
			return true
	return false


func critter_chars() -> Dictionary:
	return {"h": &"thumper"}


func build_extra() -> void:
	_swap = int(arena.data.get("swap", 4))
	_resync = not OS.get_cmdline_args().has("--fixed-fps")
	_clock = _music_time() if _resync else 0.0
	if _clock < 0.0:
		_clock = 0.0
	_build_holes()
	for c: Vector2i in beat_tiles:
		var t: Dictionary = beat_tiles[c]
		var n: Node3D = M.beat_tile(int(t["set"]))
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		t["node"] = n
		t["solid"] = _set_on(int(t["set"]), _clock)
		t["show"] = 1.0 if t["solid"] else 0.0
	for c: Vector2i in drums:
		var d: Node3D = M.drum_pad()
		d.position = Vector3(c.x, 0, c.y)
		arena.add_child(d)
		drums[c]["node"] = d
	_build_notes()
	_beat_i = floori(_clock / BEAT)
	_half_i = floori(_clock / (BEAT * 0.5))
	_animate_tiles(0.0)
	if not arena.demo:
		var hud: Variant = _hud()
		if hud != null:
			_seen_tap = int(hud.get("_last_tap_ms"))
		_build_ui()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	arena.add_child(_player)
	_snd_tick = _make_tick()
	_snd_swap = _make_swap()
	_snd_drum = _make_drum()


## The holes: a deep-blue well with a lighter inner square and a wisp of
## cloud, under every beat tile and every ~ tile.
func _build_holes() -> void:
	var outer: Array[Transform3D] = []
	var inner: Array[Transform3D] = []
	var wisps: Array[Transform3D] = []
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 7
	var cells: Array = voids.keys() + beat_tiles.keys()
	for c: Vector2i in cells:
		outer.append(Transform3D(Basis(), Vector3(c.x, 0.0, c.y)))
		inner.append(Transform3D(Basis(), Vector3(c.x, 0.021, c.y)))
		if r.randf() < 0.6:
			var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(r.randf_range(0.8, 1.3), 0.25, r.randf_range(0.5, 0.8)))
			wisps.append(Transform3D(b, Vector3(c.x + r.randf_range(-0.15, 0.15), 0.024, c.y + r.randf_range(-0.15, 0.15))))
	arena._multimesh(Models.box_mesh(Vector3(0.98, 0.04, 0.98), 0.03), M.HOLE, outer)
	arena._multimesh(Models.box_mesh(Vector3(0.72, 0.01, 0.72), 0.005), M.HOLE_IN, inner)
	arena._multimesh(Models.sphere(0.16, -1, 12), Color("#8A84D6"), wisps)


## A few music notes that drift and bob round the arena edge.
func _build_notes() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 9
	var cols: Array[Color] = [M.PINK, M.BLUE, M.PURPLE, M.GOLD]
	for k in 8:
		var holder := Node3D.new()
		arena.add_child(holder)
		var n: Node3D = M.note(holder, cols[k % cols.size()], r.randf_range(0.7, 1.0), 0.15)
		n.rotation.y = r.randf_range(-0.6, 0.6)
		var side: int = k % 4
		var u: float = r.randf()
		var p: Vector3
		match side:
			0:
				p = Vector3(-1.6, 0, lerpf(1.0, Arena.H - 2.0, u))
			1:
				p = Vector3(Arena.W + 0.6, 0, lerpf(1.0, Arena.H - 2.0, u))
			2:
				p = Vector3(lerpf(1.0, Arena.W - 2.0, u), 0, -1.7)
			_:
				p = Vector3(lerpf(1.0, Arena.W - 2.0, u), 0, Arena.H + 0.7)
		holder.position = p + Vector3(0, 0.8 + r.randf() * 0.8, 0)
		holder.set_meta(&"base", holder.position)
		holder.set_meta(&"ph", r.randf() * TAU)
		_notes.append(holder)


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Little cloud puffs and the odd music note sitting on the wall.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var sets: Dictionary = {}
	var top: float = 0.69
	var note_cols: Array[Color] = [M.PINK, M.BLUE, M.PURPLE, M.GOLD]
	for tf in blocks:
		var base := Vector3(tf.origin.x, top, tf.origin.z)
		var roll: float = r.randf()
		if roll < 0.38:
			for k in 3:
				var s: float = r.randf_range(0.12, 0.2)
				_add(sets, "puff", Color("#FFFFFF"), Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.0) * s / 0.15),
					base + Vector3(r.randf_range(-0.25, 0.25), s * 0.5, r.randf_range(-0.2, 0.2))))
		elif roll < 0.52:
			var col: Color = note_cols[r.randi() % note_cols.size()]
			var yaw := Basis(Vector3.UP, r.randf_range(-0.8, 0.8))
			var k2: float = 0.55
			_add(sets, "head", col, Transform3D(yaw * Basis(Vector3.BACK, 0.35).scaled(Vector3(1.25, 0.85, 0.9)), base + yaw * Vector3(0, 0.17 * k2, 0)))
			_add(sets, "stem", col, Transform3D(yaw, base + yaw * Vector3(0.2 * k2, 0.55 * k2, 0)))
			_add(sets, "flag", col, Transform3D(yaw * Basis(Vector3.BACK, -0.6), base + yaw * Vector3(0.3 * k2, 0.83 * k2, 0)))
	var k3: float = 0.55
	var meshes := {"puff": Models.sphere(0.15, -1, 12), "head": Models.sphere(0.2 * k3, -1, 12),
		"stem": Models.cylinder(0.035 * k3, 0.035 * k3, 0.75 * k3, 8), "flag": Models.box_mesh(Vector3(0.24, 0.09, 0.07) * k3, 0.02)}
	for key: Array in sets:
		var list: Array[Transform3D] = []
		list.assign(sets[key])
		arena._multimesh(meshes[key[0]], key[1], list)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Drum pillars: a coloured shell, a cream skin, gold rims and lugs, now
	# and then a little cymbal on top.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var sets: Dictionary = {}
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var col: Color = M.SHELLS[(roundi(p.x) * 3 + roundi(p.z) * 5) % M.SHELLS.size()]
		_add(sets, "shell", col, Transform3D(Basis(), p + Vector3(0, 0.36, 0)))
		_add(sets, "skin", M.CREAM, Transform3D(Basis(), p + Vector3(0, 0.71, 0)))
		for y: float in [0.06, 0.68]:
			_add(sets, "rim", M.GOLD, Transform3D(Basis().scaled(Vector3(1, 0.5, 1)), p + Vector3(0, y, 0)))
		for k in 6:
			var a: float = TAU * k / 6.0 + 0.3
			_add(sets, "lug", M.GOLD, Transform3D(Basis(Vector3.UP, -a), p + Vector3(cos(a) * 0.385, 0.37, sin(a) * 0.385)))
		if r.randf() < 0.25:
			_add(sets, "cym", M.GOLD, Transform3D(Basis(Vector3.FORWARD, r.randf_range(-0.25, 0.25)), p + Vector3(0, 0.82, 0)))
	var meshes := {"shell": Models.cylinder(0.37, 0.37, 0.64, 24), "skin": Models.cylinder(0.35, 0.35, 0.04, 24),
		"rim": M.torus(0.34, 0.4, 24), "lug": Models.box_mesh(Vector3(0.05, 0.16, 0.05), 0.015),
		"cym": Models.cylinder(0.03, 0.26, 0.04, 20)}
	for key: Array in sets:
		var list: Array[Transform3D] = []
		list.assign(sets[key])
		arena._multimesh(meshes[key[0]], key[1], list)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, _near_side: bool) -> Node3D:
	var root := Node3D.new()
	M.cloud(root, r.randf_range(0.6, 0.95), r)
	if r.randf() < 0.3:
		var cols: Array[Color] = [M.PINK, M.BLUE, M.PURPLE, M.GOLD]
		var n: Node3D = M.note(root, cols[r.randi() % cols.size()], 0.7)
		n.position = Vector3(0.1, 0.45, 0)
		n.rotation.y = r.randf_range(-0.6, 0.6)
	return root


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var c: Node3D = M.cloud(root, size * 0.35, r)
	c.position = Vector3(size * 0.15, 0, size * 0.1)
	if r.randf() < 0.5:
		var kit: Node3D = M.drum_kit(1.4)
		kit.position = Vector3(-size * 0.12, 0, -size * 0.05)
		root.add_child(kit)
	else:
		var n: Node3D = M.note(root, [M.PINK, M.BLUE, M.PURPLE][r.randi() % 3], 2.4, 0.1)
		n.position = Vector3(-size * 0.1, 0, 0)
	return root


func tune_environment(env: Environment, _sun: DirectionalLight3D) -> void:
	env.adjustment_saturation = 1.08


# --- The beat --------------------------------------------------------------------------

## Whether tile set [param s] is up at beat-clock time [param t].
func _set_on(s: int, t: float) -> bool:
	var phase: int = floori(t / (BEAT * _swap)) % 2
	return phase == s


## Beats left before the next swap (1.._swap) and how far through the
## current beat the clock is (0..1).
func _count_in() -> Array:
	var b: float = _clock / BEAT
	var bi: int = floori(b)
	return [_swap - (bi % _swap), b - bi]


func _warn_beats() -> int:
	return 1 if _swap <= 2 else 2


## The music's playback time, or -1 when our track is not playing.
func _music_time() -> float:
	var sfx: Node = arena.get_node_or_null("/root/Sfx")
	if sfx == null:
		return -1.0
	var mp: Variant = sfx.get("_music")
	if not (mp is AudioStreamPlayer):
		return -1.0
	var player: AudioStreamPlayer = mp
	if not player.playing or player.stream == null or player.stream.resource_path != music():
		return -1.0
	var t: float = player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return fposmod(t, LOOP)


## Keeps the beat clock in step with the music when it is playing (it
## drifts apart after a pause, say). With the sound off the clock just
## runs on elapsed time.
func _keep_in_step(delta: float) -> void:
	if not _resync:
		return
	_resync_t -= delta
	if _resync_t > 0.0:
		return
	_resync_t = 0.5
	var mt: float = _music_time()
	if mt < 0.0:
		return
	var diff: float = wrapf(mt - fposmod(_clock, LOOP), -LOOP * 0.5, LOOP * 0.5)
	if absf(diff) < 0.02:
		return
	_clock += diff if absf(diff) > 0.25 else diff * 0.5


# --- Rules -------------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	if voids.has(c):
		return true
	if beat_tiles.has(c):
		return not bool(beat_tiles[c]["solid"])
	return false


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	if voids.has(c):
		return false
	if beat_tiles.has(c):
		var t: Dictionary = beat_tiles[c]
		# Only onto a tile that is up and will still be up when it lands.
		return bool(t["solid"]) and _set_on(int(t["set"]), _clock + 0.4)
	return true


func on_explode(c: Vector2i) -> void:
	if drums.has(c):
		drums[c]["bump"] = 1.6
		arena._spawn_ring(Vector3(c.x, 0.2, c.y), M.GOLD, 1.4)


# --- Every frame -------------------------------------------------------------------------

func process(delta: float) -> void:
	_clock += delta
	_keep_in_step(delta)
	var bi: int = floori(_clock / BEAT)
	_beat_hit = bi != _beat_i
	_beat_i = bi
	var hi: int = floori(_clock / (BEAT * 0.5))
	_half_hit = hi != _half_i
	_half_i = hi
	if _beat_hit:
		_on_beat(bi)
	_update_tiles()
	_animate_tiles(delta)
	_animate_drums(delta)
	_animate_notes()
	if arena.demo or arena.hero == null:
		return
	_gate_critters()
	_update_drum_pods()
	_drive_taps()
	if _ui != null:
		_ui.visible = arena.state == &"play" and not arena.get_tree().paused
		if _ui.visible:
			_ui.queue_redraw()


func _on_beat(bi: int) -> void:
	for c: Vector2i in drums:
		drums[c]["bump"] = maxf(float(drums[c]["bump"]), 1.0 if bi % 4 == 0 else 0.55)
	if arena.demo or arena.state != &"play":
		return
	var left: int = _swap - (bi % _swap)
	if bi % _swap == 0:
		_sound(_snd_swap, 1.0)
	elif left <= _warn_beats():
		_sound(_snd_tick, 1.0 if left > 1 else 1.25)


func _update_tiles() -> void:
	for c: Vector2i in beat_tiles:
		var t: Dictionary = beat_tiles[c]
		if _set_on(int(t["set"]), _clock):
			if not bool(t["solid"]):
				t["solid"] = true
				t["pop"] = 1.0
			t["held"] = false
		elif bool(t["solid"]):
			if _occupied(c):
				t["held"] = true
			else:
				t["solid"] = false
				if bool(t["held"]) and not arena.demo:
					arena._spawn_ring(Vector3(c.x, 0.05, c.y), M.SET_COLORS[int(t["set"])], 0.7)
				t["held"] = false


## Is anyone standing on [param c] (Pip, a pod or a critter, even partly)?
func _occupied(c: Vector2i) -> bool:
	if arena.hero != null and arena.hero_alive and not arena.demo:
		if absf(arena.hero_pos.x - c.x) < 0.95 and absf(arena.hero_pos.y - c.y) < 0.95:
			return true
	if arena.pod_at.has(c):
		return true
	for p: Arena.Pod in arena.pods:
		if absf(p.pos.x - c.x) < 0.95 and absf(p.pos.y - c.y) < 0.95:
			return true
	for cr: Arena.Critter in arena.critters:
		if cr.cell == c or cr.target == c:
			return true
		if absf(cr.pos.x - c.x) < 0.9 and absf(cr.pos.y - c.y) < 0.9:
			return true
	return false


func _animate_tiles(delta: float) -> void:
	var ci: Array = _count_in()
	var left: int = ci[0]
	var frac: float = ci[1]
	var warn: bool = left <= _warn_beats()
	var pulse: float = exp(-frac * 7.0)
	for c: Vector2i in beat_tiles:
		var t: Dictionary = beat_tiles[c]
		var node: Node3D = t["node"]
		var plat: Node3D = node.get_node("Plat")
		var ghost: Node3D = node.get_node("Ghost")
		var solid: bool = t["solid"]
		var show: float = move_toward(float(t["show"]), 1.0 if solid else 0.0, delta * 9.0)
		t["show"] = show
		var pop: float = maxf(float(t.get("pop", 0.0)) - delta * 3.0, 0.0)
		t["pop"] = pop
		var s: float = _ease_out(show)
		var leaving: bool = solid and warn and not bool(t["held"])
		var y: float = -0.32 * (1.0 - s) - 0.035 * pulse
		var off := Vector2.ZERO
		if leaving:
			var u: float = 1.0 - (float(left - 1) + frac) / float(_warn_beats())
			off = Vector2(sin(_clock * 43.0 + c.x), cos(_clock * 37.0 + c.y)) * 0.025 * (0.4 + u)
			y -= 0.05 * pulse
		if bool(t["held"]):
			off = Vector2(sin(_clock * 50.0), 0.0) * 0.02
			y -= 0.06
		plat.visible = s > 0.02
		plat.position = Vector3(off.x, y, off.y)
		var sq: float = sin(pop * PI * 2.0) * pop * 0.15
		plat.scale = Vector3(s * (1.0 + sq), maxf(s, 0.05) * (1.0 - sq), s * (1.0 + sq))
		# Blink: the leaving tiles flash on each half beat; held ones fast.
		var blink: bool = false
		if bool(t["held"]):
			blink = fmod(_clock, 0.2) < 0.1
		elif leaving:
			blink = frac > 0.5
		for k in range(1, plat.get_child_count()):
			(plat.get_child(k) as Node3D).visible = not blink
		ghost.visible = not solid or show < 0.9
		var arriving: bool = not solid and warn
		ghost.scale = Vector3.ONE * (1.0 + (0.12 * pulse if arriving else 0.0))
		ghost.position.y = 0.02 + (0.03 * pulse if arriving else 0.0)


static func _ease_out(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return 1.0 - (1.0 - u) * (1.0 - u)


func _animate_drums(delta: float) -> void:
	for c: Vector2i in drums:
		var d: Dictionary = drums[c]
		var b: float = maxf(float(d["bump"]) - delta * 4.0, 0.0)
		d["bump"] = b
		var skin: Node3D = (d["node"] as Node3D).get_node("Skin")
		var w: float = sin(b * PI * 3.0) * b
		skin.position.y = 0.155 - w * 0.035
		skin.scale = Vector3(1.0 + w * 0.04, 1.0, 1.0 + w * 0.04)


func _animate_notes() -> void:
	var ci: Array = _count_in()
	var pulse: float = exp(-float(ci[1]) * 6.0)
	for n: Node3D in _notes:
		var base: Vector3 = n.get_meta(&"base")
		var ph: float = n.get_meta(&"ph")
		n.position = base + Vector3(0, sin(_clock * 1.3 + ph) * 0.18, 0)
		n.scale = Vector3.ONE * (1.0 + pulse * 0.12)
		n.rotation.y = sin(_clock * 0.7 + ph) * 0.5


## Pods set on a drum pad go off exactly on the next downbeat that is at
## least two beats away (so there is always time to step clear).
func _update_drum_pods() -> void:
	for p: Arena.Pod in _drummed.keys():
		if not arena.pods.has(p):
			_drummed.erase(p)
			continue
		if p.cell != _drummed[p]["cell"] or p.slide != Vector2i.ZERO:
			_drummed.erase(p)
			continue
		p.timer = float(_drummed[p]["at"]) - _clock
	for p: Arena.Pod in arena.pods:
		if _drummed.has(p) or p.slide != Vector2i.ZERO or not drums.has(p.cell):
			continue
		var at: float = ceilf((_clock + BEAT * 1.98) / BAR) * BAR
		_drummed[p] = {"at": at, "cell": p.cell}
		p.timer = at - _clock
		drums[p.cell]["bump"] = 0.8
		_sound(_snd_drum, 1.0)


## Thumpers and Maestro only set off on a beat (Maestro on half beats too
## once he is hurt): a step that the arena starts in between is undone.
func _gate_critters() -> void:
	for cr: Arena.Critter in arena.critters:
		var thumper: bool = cr.kind == &"thumper"
		var boss: bool = cr.kind == &"boss"
		if not thumper and not boss:
			continue
		cr.speed = THUMP_SPEED if thumper else 1.0 / (BEAT * 0.42)
		if cr.t != 0.0 or cr.target == cr.cell:
			continue
		var ok: bool = _beat_hit
		if boss and cr.hp * 2 <= arena.boss_max_hp:
			ok = _half_hit
		if not ok:
			cr.target = cr.cell
			cr.t = 1.0
			cr.pos = Vector2(cr.cell)


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"thumper":
		return Vector2i.ZERO
	var open: Array[Vector2i] = []
	for d: Vector2i in DIRS4:
		if arena._critter_can_enter(cr, cr.cell + d):
			open.append(d)
	if open.is_empty():
		return Vector2i.ZERO
	var danger: Dictionary = arena._danger_cells() if not arena.demo else {}
	var safe: Array[Vector2i] = []
	for d: Vector2i in open:
		if not danger.has(cr.cell + d) or danger.has(cr.cell):
			safe.append(d)
	if safe.is_empty():
		safe = open
	# Mostly groove toward Pip, sometimes wander.
	if not arena.demo and arena.hero_alive and arena.rng.randf() < 0.6:
		var best := Vector2i.ZERO
		var best_d: int = 1 << 20
		var hc: Vector2i = arena.hero_cell()
		for d: Vector2i in safe:
			var n: Vector2i = cr.cell + d
			var md: int = absi(n.x - hc.x) + absi(n.y - hc.y)
			if md < best_d:
				best_d = md
				best = d
		return best
	if safe.has(cr.dir) and arena.rng.randf() < 0.5:
		return cr.dir
	return safe[arena.rng.randi() % safe.size()]


# --- Tap walking ---------------------------------------------------------------------------

func _hud() -> Variant:
	var main: Node = arena.get_parent()
	if main == null:
		return null
	return main.get("hud")


## When a tapped tile is across a bridge that is down, Pip walks as far as
## he can; this sends him on again as soon as the way opens.
func _drive_taps() -> void:
	var hud: Variant = _hud()
	if hud != null and is_instance_valid(hud):
		var ms: int = int(hud.get("_last_tap_ms"))
		if ms != _seen_tap:
			_seen_tap = ms
			if ms > 0:
				_want_before = _want
				var tc: Vector2i = arena.cell_at_screen(hud.get("_last_tap_pos"))
				_want = tc if tc != Arena.NO_CELL else NO_CELL
			else:
				_want = _want_before
	if _want == NO_CELL:
		return
	if arena.state != &"play" or not arena.hero_alive or arena.input_primary != Vector2i.ZERO:
		_want = NO_CELL
		return
	var here: Vector2i = arena.hero_cell()
	if here == _want:
		_want = NO_CELL
		return
	var idle: bool = arena.walk_goal == Arena.NO_CELL or arena.walk_goal == here
	if not idle or not _beat_hit:
		return
	var first: Dictionary = arena._hero_search(false, true)["first"]
	if first.has(_want):
		arena.walk_to(_want)
	else:
		# Not reachable yet: walk to the nearest tile, if that is closer.
		var best: Vector2i = here
		var best_score: int = absi(here.x - _want.x) + absi(here.y - _want.y)
		for cell: Vector2i in first:
			var sc: int = absi(cell.x - _want.x) + absi(cell.y - _want.y)
			if sc < best_score:
				best_score = sc
				best = cell
		if best != here:
			arena.set_walk_goal(best)


# --- Critters -----------------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"thumper":
			return M.thumper(M.SHELLS[arena.rng.randi() % M.SHELLS.size()])
		&"blobbit":
			return M.note_blob()
		&"buzzer":
			return M.songbird()
		&"boss":
			return M.maestro()
	return null


func critter_speed(kind: StringName) -> float:
	return THUMP_SPEED if kind == &"thumper" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_smart(kind: StringName) -> bool:
	return kind == &"thumper"


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	var ci: Array = _count_in()
	var frac: float = ci[1]
	var hop: float = sin(clampf(cr.t, 0.0, 1.0) * PI) if cr.t < 1.0 else 0.0
	match cr.kind:
		&"thumper":
			body.position.y = hop * 0.38
			var land: float = exp(-frac * 9.0) * (1.0 - hop)
			var left: bool = _beat_i % 2 == 0
			(body.get_node("StickL") as Node3D).rotation.x = -1.0 * land if left else 0.2
			(body.get_node("StickR") as Node3D).rotation.x = -1.0 * land if not left else 0.2
			return Vector3(1.0 + land * 0.12, 1.0 - land * 0.12, 1.0 + land * 0.12) * 1.1
		&"blobbit":
			var b: float = absf(sin(t * 5.0))
			body.position.y = b * 0.18
			(body.get_node("Stem") as Node3D).rotation.z = sin(t * 5.0) * 0.18
			var sq: float = clampf(1.0 - b * 4.0, 0.0, 1.0) * 0.15
			return Vector3(1.0 + sq, 1.0 - sq, 1.0 + sq)
		&"buzzer":
			var fly: Node3D = body.get_node("Fly")
			fly.position.y = 0.55 + sin(t * 4.0) * 0.07
			var flap: float = sin(t * 22.0) * 0.7
			(fly.get_node("WingL") as Node3D).rotation.z = flap
			(fly.get_node("WingR") as Node3D).rotation.z = -flap
			return Vector3.ONE
		&"boss":
			return _pose_boss(cr, body, hop, frac, delta)
	return Vector3.ONE


## Maestro conducts in four: down, in, out, up, on each beat of the bar,
## and bobs his head to the groove.
func _pose_boss(cr: Arena.Critter, body: Node3D, hop: float, frac: float, _delta: float) -> Vector3:
	body.position.y = hop * 0.45
	var beat_in_bar: int = posmod(_beat_i, 4)
	var aims: Array[Vector2] = [Vector2(1.4, 0.0), Vector2(0.6, 0.5), Vector2(0.6, -0.6), Vector2(-0.3, 0.0)]
	var from: Vector2 = aims[(beat_in_bar + 3) % 4]
	var to: Vector2 = aims[beat_in_bar]
	var u: float = _ease_out(clampf(frac * 2.5, 0.0, 1.0))
	var aim: Vector2 = from.lerp(to, u)
	var wing: Node3D = body.get_node("WingR")
	wing.rotation = Vector3(-aim.x, 0.0, 0.6 + aim.y)
	(body.get_node("WingL") as Node3D).rotation.z = -0.3 - exp(-frac * 6.0) * 0.3
	var head: Node3D = body.get_node("Head")
	head.rotation.x = exp(-frac * 6.0) * 0.18
	head.rotation.z = sin(_clock * PI / BEAT * 0.5) * 0.1
	var land: float = exp(-frac * 9.0) * (1.0 - hop) * 0.1
	var size: float = M.BOSS_SIZE * (1.0 + (0.06 if cr.hp * 2 <= arena.boss_max_hp else 0.0))
	return Vector3(1.0 + land, 1.0 - land, 1.0 + land) * size


# --- The beat chip ---------------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	arena.add_child(layer)
	_ui = Control.new()
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if Models.GLASS:
		_ui.material = Ui.glass_ui()
	_ui.draw.connect(_draw_ui)
	layer.add_child(_ui)


func _draw_ui() -> void:
	var vp: Vector2 = _ui.get_viewport_rect().size
	var ci: Array = _count_in()
	var left: int = ci[0]
	var frac: float = ci[1]
	var warn: bool = left <= _warn_beats()
	var on_set: int = 0 if _set_on(0, _clock) else 1
	var next_set: int = 1 - on_set
	var w: float = 360.0
	var h: float = 64.0
	var rect := Rect2(Vector2(vp.x * 0.5 - w * 0.5, vp.y - h - 28.0), Vector2(w, h))
	var sb := StyleBoxFlat.new()
	var flash: bool = warn and frac < 0.3
	sb.bg_color = Color(Color("#FFFFFF") if flash else Ui.CREAM, 0.94)
	sb.set_corner_radius_all(int(h * 0.5))
	sb.anti_aliasing = true
	sb.shadow_color = Ui.SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	_ui.draw_style_box(Ui.glassify(sb), rect)
	# The tile now up: a swatch in its colour and shape.
	var sc: Vector2 = rect.position + Vector2(h * 0.5 + 4.0, h * 0.5)
	var col: Color = M.SET_COLORS[on_set]
	var pop: float = 1.0 + exp(-frac * 8.0) * 0.12
	_swatch(sc, 19.0 * pop, on_set, col)
	# The four beats of the bar, the current one big.
	var beat_in_bar: int = posmod(_beat_i, 4)
	var dx: float = rect.position.x + h + 10.0
	for k in 4:
		var big: bool = k == beat_in_bar
		var r: float = (8.5 + 3.5 * exp(-frac * 6.0)) if big else 5.5
		var dc: Color = col if big else Color(Ui.INK, 0.22)
		_ui.draw_circle(Vector2(dx + k * 24.0, rect.position.y + h * 0.5), r, dc)
	# The count-in, or which tiles are up.
	var f: Font = Ui.font(900)
	var tx: float = dx + 4 * 24.0 + 4.0
	var label: String
	var lc: Color = Ui.INK
	if warn:
		label = "SWAP IN %d" % left
		lc = M.SET_COLORS[next_set].darkened(0.25)
	else:
		label = ("PINK" if on_set == 0 else "BLUE") + " UP"
		lc = col.darkened(0.3)
	_ui.draw_string(f, Vector2(tx, rect.position.y + 30.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, lc)
	var bar := Rect2(Vector2(tx, rect.position.y + 40.0), Vector2(rect.end.x - tx - 64.0, 9.0))
	_ui.draw_rect(bar, Color(Ui.INK, 0.12))
	var u: float = clampf((float(left - 1) + 1.0 - frac) / float(_swap), 0.0, 1.0)
	_ui.draw_rect(Rect2(bar.position, Vector2(bar.size.x * u, bar.size.y)), col)
	# The next set's swatch, small, at the end.
	var nc: Vector2 = Vector2(rect.end.x - h * 0.5 - 4.0, rect.position.y + h * 0.5)
	_swatch(nc, 12.0 * (1.0 + (exp(-frac * 8.0) * 0.25 if warn else 0.0)), next_set, Color(M.SET_COLORS[next_set], 0.55 if not warn else 1.0))


func _swatch(c: Vector2, r: float, set_index: int, col: Color) -> void:
	if set_index == 0:
		_ui.draw_circle(c, r, col)
		_ui.draw_circle(c, r * 0.42, Color(M.CREAM, col.a))
	else:
		var pts := PackedVector2Array([c + Vector2(0, -r * 1.15), c + Vector2(r * 1.15, 0), c + Vector2(0, r * 1.15), c + Vector2(-r * 1.15, 0)])
		_ui.draw_colored_polygon(pts, col)
		var s: float = r * 0.45
		var inner := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)])
		_ui.draw_colored_polygon(inner, Color(M.CREAM, col.a))


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


## A soft wooden tick for the count-in.
func _make_tick() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.12)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		out[i] = sin(TAU * 1500.0 * t) * exp(-t * 60.0) * 0.35
	return _wav(out)


## A bright two-note chime for the swap.
func _make_swap() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.45)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var a: float = sin(TAU * 880.0 * t) * exp(-t * 9.0)
		var b: float = sin(TAU * 1318.5 * maxf(t - 0.07, 0.0)) * exp(-maxf(t - 0.07, 0.0) * 9.0) if t > 0.07 else 0.0
		out[i] = (a * 0.25 + b * 0.25) * minf(t / 0.003, 1.0)
	return _wav(out)


## A tom thump when a pod lands on a drum.
func _make_drum() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		phase += TAU * (110.0 + 90.0 * exp(-t * 25.0)) / rate
		out[i] = sin(phase) * exp(-t * 12.0) * 0.6
	return _wav(out)


static func _add(sets: Dictionary, key: String, color: Color, tf: Transform3D) -> void:
	var k: Array = [key, color]
	if not sets.has(k):
		sets[k] = []
	(sets[k] as Array).append(tf)

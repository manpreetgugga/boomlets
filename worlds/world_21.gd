extends WorldKit
## World 21, Echo Grotto: a bright seaside cave of pale sand, teal tide
## pools, pastel crystal clusters and lavender rock. The twist is stored
## echoes that Pip lets out himself. Shell stones soak up any blast that
## reaches them: the blast stops at the shell as at a wall, and the shell
## keeps it, glowing, humming softly and showing the blast's reach as a row
## of pearls. Nothing more happens until Pip steps onto a conch horn pad:
## the horn sounds and every full shell lets its blast go at once. Halos,
## ripple rings and teal target tiles warn for a second, then each shell
## blasts a cross with the stored reach and is empty again. A let-out blast
## that reaches an empty shell fills it (it does not fire), so a relay is
## built one horn call at a time. A full shell tops up to a bigger reach.
## As a safety net, a shell that has been full for 12 s lets go by itself
## (with the same warning).
## Hermit Crabs duck into their shells when a pod is set close to them
## (blasts can't hurt them then) and pop out a moment after it has gone, so
## a blast stored earlier and let out from afar is the way to catch them.
## Glow Jellies are this world's skin for the wisps. The Grand Clam boss can
## only be hurt while it is open. A blast that hits it while it is shut is
## swallowed (teal pearls on its lid) and kept until its next roar, when it
## is blasted back out after a warning, just before the clam opens. Unlike
## World 11's lanterns, nothing here answers by itself: Pip decides when.
##
## Extra map characters:
##   e  shell stone (solid; stores blasts)
##   H  conch horn pad (floor; stepping on it lets every full shell go)
##   h  Hermit Crab

const M := preload("res://worlds/world_21_models.gd")

const RELEASE_DELAY: float = 1.0
const MAX_CHARGE: int = 6
const AUTO_RELEASE: float = 12.0
const CRAB_HIDE_RANGE: int = 2
const CRAB_POP_DELAY: float = 0.8
const CLAM_SHUT: float = 4.5
const CLAM_ROAR: float = 1.4
const CLAM_MAX_CHARGE: int = 4
const CLAM_OPEN: float = 3.6
const CLAM_PHASE2_HP: int = 4

const PALETTE: Dictionary = {
	"GRASS_A": "#F7DDB2", "GRASS_B": "#E9C48F", "RIM": "#FFEED6", "EDGE": "#B7A3F0",
	"STONE": "#CDBDF6", "DARK_STONE": "#9F8AE3", "DIRT": "#E7CFAE", "ROCK": "#B9A4EE",
	"WOOD": "#7FE0DA", "WOOD_DARK": "#3FB7C2", "BARREL": "#FF8A80", "BELT": "#6A7FC8", "ACCENT": "#FFC2DE",
	"BLOSSOM_A": "#FFB1C8", "BLOSSOM_B": "#FF9AB8", "TRUNK": "#A994E8", "LEAFY_A": "#8FE3C8", "LEAFY_B": "#6FD3B5",
	"SKY_TOP": "#7FD6DC", "SKY_HORIZON": "#F0E2FF", "SKY_GROUND": "#D8F4F0", "CLOUD": "#FFFFFF", "CLOUDS": 0.4,
	"AMBIENT": "#E2DCFF", "AMBIENT_ENERGY": 0.62, "SUN": "#FFF6EC", "SUN_ENERGY": 1.35,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Shell Song",
		"tip": "Blast a shell stone to fill it.\nThen step on a conch horn pad:\nevery full shell lets its blast go!",
		"crates": 0.32, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#...b.#eb_#E#",
			"#.#.#.#_###.#",
			"#....H......#",
			"#.#.#.#.#.#.#",
			"#..b........#",
			"#.#.#.#.#.#.#",
			"#..e.....e..#",
			"#.#.#.#.#.#.#",
			"#.......b...#",
			"#.#.#.#.#.#.#",
			"#....H......#",
			"#.#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Hermit Hollow",
		"tip": "Crabs hide when a pod lands close.\nFill a shell, wait for a crab to\nwander in line, then sound the horn!",
		"crates": 0.38, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.h...e...h.#",
			"#.#.#.#.#.#.#",
			"#.....H.....#",
			"#.#.#.#.#.#.#",
			"#.e.......e.#",
			"#.#.#.#.#.#.#",
			"#..h..E..h..#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#.....H.....#",
			"#.#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Ripple Relay",
		"tip": "A let-out blast fills the next\nempty shell. Sound the horn twice\nto pass it down to the sealed crab!",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.h.H.....w.#",
			"#.#.#.#.#.#.#",
			"#......e....#",
			"#.#.#.#_#.#.#",
			"#.....#e#...#",
			"#.#.#.#h#.#.#",
			"#E....#_#...#",
			"#.#.#.###.#.#",
			"#..h..H..h..#",
			"#.#.#.#.#.#.#",
			"#.e.......e.#",
			"#.#_#.#.#.#.#",
			"#._S_....w..#",
			"#############",
		],
	},
	{
		"name": "Crystal Chorus",
		"tip": "One horn call empties every full\nshell at once. Glow jellies drift\nthrough crates: catch them in a row!",
		"crates": 0.4, "par": 105,
		"drops": {"bomb": 3, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..h..e..h..#",
			"#.#.#.#.#.#.#",
			"#.w...H...w.#",
			"#.#.#.#.#.#.#",
			"#e.........e#",
			"#.#.#.#.#.#.#",
			"#...e.E.e...#",
			"#.#.#.#.#.#.#",
			"#e...w.w...e#",
			"#.#.#.#.#.#.#",
			"#.....H...h.#",
			"#.#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Pearl Maze",
		"tip": "A crab hides in the pearl vault.\nFill the shells at both ends\n(more fire, more pearls), then toot!",
		"crates": 0.4, "par": 115,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#z....E....h#",
			"#.#.#.#.#.#.#",
			"#.e...h...e.#",
			"#.#.#.#.#.#.#",
			"#.....H.w..z#",
			"#.#.#####.#.#",
			"#...eh__e...#",
			"#.#.#####.#.#",
			"#.w...H.....#",
			"#.#.#.#.#.#.#",
			"#.e...h...e.#",
			"#.#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Grand Clam",
		"tip": "Blasts on the shut Grand Clam\nget roared back! Hit it while it's\nopen: full shells and horns help.",
		"crates": 0.18, "par": 150,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#H....E.....#",
			"#.#.#.#.#.#.#",
			"#.....e.....#",
			"#.#.#...#.#.#",
			"#...........#",
			"#.#...#...#.#",
			"#..e..K..e..#",
			"#.#...#...#.#",
			"#...........#",
			"#.#.#...#.#.#",
			"#.....e.....#",
			"#.#.#_#_#.#.#",
			"#...._S_...H#",
			"#############",
		],
	},
]

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## Vector2i -> {"node", "charge": stored reach (0 = empty), "busy": bool
## (letting go), "held": seconds full, "bump": float, "shown": int}
var stones: Dictionary = {}
var _stone_list: Array[Vector2i] = []
var _horn_list: Array[Vector2i] = []
var horns: Dictionary = {}             # Vector2i -> {"node", "bump"}
## Releases on their way: {"at", "reach", "t", "delay", "marks", "path", "ring", "refresh", "clam"}
var _echoes: Array[Dictionary] = []
var _pending: Array[Vector2i] = []     # shells reached by a blast this frame
var _fresh: Array[Vector2i] = []       # flames from the arena's own blasts this frame
var _flame_reach: Dictionary = {}      # Vector2i -> reach of the blast that made the flame
var _own: bool = false
var _pod_fire: Dictionary = {}
var _seen_pods: Dictionary = {}        # Pod -> true once crabs have reacted to it
var _hide: Dictionary = {}             # Crab -> {"pods": Array, "out": float}
var _tuck: Dictionary = {}             # Crab -> 0 (out) .. 1 (tucked in)
var _clam_state: StringName = &"shut"
var _clam_t: float = CLAM_SHUT
var _clam_charge: int = 0
var _clam_open: float = 0.0            # eased lid opening, 0..1
var _clam_snap: float = 0.0
var _deflect: float = 0.0
var _pools: Array[Node3D] = []
var _mouth_on: Material
var _mouth_off: Material
var _base_on: Material
var _base_off: Material
var _player: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _snd_charge: AudioStreamWAV
var _snd_echo: AudioStreamWAV
var _snd_snap: AudioStreamWAV
var _snd_horn: AudioStreamWAV

# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Echo Grotto"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_21.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "GRAND CLAM"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	if arena != null and arena.boss != null and arena.boss.hp * 2 <= arena.boss_max_hp:
		return &"wisp"
	return &"crab"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "e":
		_stone_list.append(c)
		return true
	if ch == "H":
		_horn_list.append(c)
		return true
	return false


func critter_chars() -> Dictionary:
	return {"h": &"crab"}


func blocks(c: Vector2i) -> bool:
	return stones.has(c) or _stone_list.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if (stones.has(c) or _stone_list.has(c)) else 0


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not (stones.has(c) or _stone_list.has(c))


func build_wall_topper(blocks_tf: Array[Transform3D]) -> bool:
	# Little crystal clusters and shells along the top of the cave rock.
	var crystal_sets: Array = [[], [], [], []]
	var shells: Array[Transform3D] = []
	var r := RandomNumberGenerator.new()
	r.seed = 2121 + arena.level_id
	for tf in blocks_tf:
		var c := Vector2i(roundi(tf.origin.x), roundi(tf.origin.z))
		var roll: float = r.randf()
		if roll < 0.28:
			var col: int = r.randi() % 4
			for k in r.randi_range(1, 3):
				var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.35, 0.35))
				b = b.scaled(Vector3.ONE * r.randf_range(0.7, 1.15))
				(crystal_sets[col] as Array).append(Transform3D(b, Vector3(c.x + r.randf_range(-0.22, 0.22), 0.68, c.y + r.randf_range(-0.22, 0.22))))
		elif roll < 0.4:
			var b2 := Basis(Vector3.UP, r.randf() * TAU)
			shells.append(Transform3D(b2, Vector3(c.x + r.randf_range(-0.2, 0.2), 0.68, c.y + r.randf_range(-0.2, 0.2))))
	var mesh := M.crystal_mesh(0.07, 0.32)
	for k in 4:
		var arr: Array[Transform3D] = []
		arr.assign(crystal_sets[k])
		if not arr.is_empty():
			arena._multimesh(mesh, M.CRYSTALS[k], arr, Models.mat(M.CRYSTALS[k], 0.35))
	if not shells.is_empty():
		arena._multimesh(_scallop_mesh(), M.SHELL_PINK, shells)
	return true


## A small flat scallop shell as one mesh (for the border multimesh).
func _scallop_mesh() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rib: ArrayMesh = Models.box_mesh(Vector3(0.06, 0.05, 0.2), 0.02)
	for k in 5:
		var a: float = lerpf(-0.9, 0.9, k / 4.0)
		var tf := Transform3D(Basis(Vector3.UP, a), Vector3(sin(a) * 0.07, 0.025, cos(a) * 0.07))
		st.append_from(rib, 0, tf)
	return st.commit()


## Solid blocks are pastel crystal clusters on a lavender rock.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var rocks: Array[Transform3D] = []
	var sets: Array = [[], [], [], []]
	var r := RandomNumberGenerator.new()
	r.seed = 4242 + arena.level_id
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		rocks.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.15, 0.15)), p + Vector3(0, 0.17, 0)))
		var col: int = (roundi(p.x) * 3 + roundi(p.z) * 5) % 4
		var spots_in: Array[Vector3] = [Vector3(0.0, 0, 0.0), Vector3(-0.2, 0, 0.17), Vector3(0.21, 0, -0.15), Vector3(0.18, 0, 0.2), Vector3(-0.19, 0, -0.18)]
		for k in spots_in.size():
			var h: float = 1.0 if k == 0 else r.randf_range(0.55, 0.78)
			var tilt: float = 0.0 if k == 0 else 0.3
			var dir: Vector3 = spots_in[k].normalized() if k > 0 else Vector3.ZERO
			var b := Basis(Vector3.UP, r.randf() * TAU)
			if k > 0:
				b = Basis(Vector3(dir.z, 0, -dir.x).normalized(), tilt) * b
			b = b.scaled(Vector3(1.0, h, 1.0))
			var cc: int = col if k % 2 == 0 else (col + 1) % 4
			(sets[cc] as Array).append(Transform3D(b, p + spots_in[k] + Vector3(0, 0.3, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.86, 0.34, 0.86), 0.1), Models.DARK_STONE, rocks)
	var mesh := M.crystal_mesh(0.16, 0.62)
	for k in 4:
		var arr: Array[Transform3D] = []
		arr.assign(sets[k])
		if not arr.is_empty():
			arena._multimesh(mesh, M.CRYSTALS[k], arr, Models.mat(M.CRYSTALS[k], 0.3))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var holder := Node3D.new()
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.14:
			node = M.beach_shell(r)
		elif roll < 0.24:
			node = M.starfish(M.STAR if r.randf() < 0.5 else M.SHELL_BAND)
			node.rotation.y = r.randf() * TAU
		elif roll < 0.3:
			node = M.tide_pool(r, 0.7)
	else:
		if roll < 0.16:
			node = M.crystals(r, 1.2)
		elif roll < 0.3:
			node = M.tide_pool(r, 0.9)
			_pools.append(node)
		elif roll < 0.4:
			node = M.coral(r)
		elif roll < 0.5:
			node = M.beach_shell(r)
			node.scale = Vector3.ONE * 1.4
		elif roll < 0.56:
			node = M.starfish(M.STAR)
			node.rotation.y = r.randf() * TAU
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var spire := M.crystals(r, 2.6)
	spire.position = Vector3(-size * 0.12, 0, -size * 0.1)
	root.add_child(spire)
	var shell := M.conch(M.SHELL, M.SHELL_BAND, 1.2, M.MOUTH, 0.6)
	shell.position = Vector3(size * 0.22, 0, size * 0.15)
	shell.rotation.y = r.randf() * TAU
	root.add_child(shell)
	var pool := M.tide_pool(r, size * 0.35)
	pool.position = Vector3(-size * 0.2, 0, size * 0.25)
	root.add_child(pool)
	return root


func build_extra() -> void:
	for c: Vector2i in _stone_list:
		var node: Node3D = M.echo_stone()
		node.position = Vector3(c.x, 0, c.y)
		node.rotation.y = sin(c.x * 1.3 + c.y * 0.7) * 0.35
		arena.add_child(node)
		stones[c] = {"node": node, "charge": 0, "busy": false, "bump": 0.0, "shown": -1}
	for c: Vector2i in _horn_list:
		var horn: Node3D = M.horn_pad()
		horn.position = Vector3(c.x, 0, c.y)
		arena.add_child(horn)
		horns[c] = {"node": horn, "bump": 0.0}
	_mouth_on = Models.mat(M.MOUTH, 1.7)
	_mouth_off = Models.mat(M.SHELL_BAND.lightened(0.35), 0.0)
	_base_on = Models.mat(M.MOUTH.lightened(0.15), 0.7)
	_base_off = Models.mat(M.STONE_BASE)
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	arena.add_child(_player)
	_hum = AudioStreamPlayer.new()
	_hum.volume_db = -24.0
	_hum.stream = _make_hum()
	arena.add_child(_hum)
	_snd_charge = _make_charge()
	_snd_echo = _make_echo()
	_snd_snap = _make_snap()
	_snd_horn = _make_horn()


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF6EC")
	env.glow_intensity = 0.55
	env.glow_bloom = 0.07
	env.adjustment_saturation = 1.08


# --- Stored blasts ----------------------------------------------------------------------

func on_flame(c: Vector2i) -> void:
	if _own:
		return
	if stones.has(c):
		if not _pending.has(c):
			_pending.append(c)
	else:
		_fresh.append(c)


func on_explode(c: Vector2i) -> void:
	var fire: int = int(_pod_fire.get(c, arena.fire))
	_settle(fire)


## Notes the reach of the blast that just happened on its flames, and fills
## the shells it reached.
func _settle(reach: int) -> void:
	for f: Vector2i in _fresh:
		_flame_reach[f] = reach
	_fresh.clear()
	var list: Array[Vector2i] = _pending.duplicate()
	_pending.clear()
	for s: Vector2i in list:
		_charge(s, reach)


## A blast of [param reach] reached shell [param c]: it stores it (or tops
## up to the bigger reach). A shell that is letting go ignores it.
func _charge(c: Vector2i, reach: int) -> void:
	if not stones.has(c):
		return
	var s: Dictionary = stones[c]
	s["bump"] = 1.0
	if bool(s["busy"]):
		return
	var before: int = int(s["charge"])
	var now: int = mini(maxi(before, reach), MAX_CHARGE)
	if now == before:
		return
	s["charge"] = now
	s["held"] = 0.0
	arena._spawn_ring(Vector3(c.x, 0.1, c.y), M.MOUTH, 0.7)
	_sound(_snd_charge, 0.9 + 0.06 * now)


func on_hero_enter(c: Vector2i) -> void:
	if horns.has(c) and not arena.demo:
		_sound_horn(c)


## Pip stood on a horn pad: every full shell lets its blast go.
func _sound_horn(c: Vector2i) -> void:
	horns[c]["bump"] = 1.0
	arena._spawn_ring(Vector3(c.x, 0.1, c.y), M.SHELL_PINK, 1.1)
	var any: bool = false
	for sc: Vector2i in stones:
		if _release(sc):
			any = true
	_sound(_snd_horn, 1.0 if any else 1.25)


## Starts shell [param sc] letting its blast go, if it is full.
func _release(sc: Vector2i) -> bool:
	var s: Dictionary = stones[sc]
	if int(s["charge"]) <= 0 or bool(s["busy"]):
		return false
	s["busy"] = true
	_start_echo(sc, int(s["charge"]), RELEASE_DELAY, false)
	return true


func _start_echo(at: Vector2i, reach: int, delay: float, clam: bool) -> Dictionary:
	var e: Dictionary = {"at": at, "reach": reach, "t": delay, "delay": delay, "marks": [],
		"path": [], "ring": 0.0, "refresh": 0.0, "clam": clam}
	_echoes.append(e)
	_refresh_marks(e)
	return e


## The tiles a release from [param at] will reach, like a blast's arms.
func _echo_path(at: Vector2i, reach: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		var cc: Vector2i = at + d
		for i in reach:
			var t: int = arena.tile(cc)
			if t == Arena.WALL:
				break
			out.append(cc)
			if stones.has(cc) or t == Arena.CRATE or t == Arena.BARREL or arena.pod_at.has(cc):
				break
			cc += d
	return out


func _refresh_marks(e: Dictionary) -> void:
	var path: Array[Vector2i] = _echo_path(e["at"], e["reach"])
	var old: Array = e["path"]
	if old.size() == path.size() and old.all(func(c: Vector2i) -> bool: return path.has(c)):
		return
	e["path"] = path
	for n: Node3D in e["marks"]:
		if is_instance_valid(n):
			n.queue_free()
	var marks: Array = []
	for c: Vector2i in path:
		if stones.has(c):
			continue
		var m: Node3D = M.echo_mark()
		m.position = Vector3(c.x, 0, c.y)
		arena.add_child(m)
		marks.append(m)
	e["marks"] = marks


func _update_echoes(delta: float) -> void:
	for e: Dictionary in _echoes.duplicate():
		e["t"] = float(e["t"]) - delta
		var at: Vector2i = e["at"]
		e["ring"] = float(e["ring"]) - delta
		if float(e["ring"]) <= 0.0:
			e["ring"] = 0.33
			arena._spawn_ring(Vector3(at.x, 0.1, at.y), M.MOUTH, 0.6 + int(e["reach"]) * 0.35)
		e["refresh"] = float(e["refresh"]) - delta
		if float(e["refresh"]) <= 0.0:
			e["refresh"] = 0.2
			_refresh_marks(e)
		var left: float = clampf(float(e["t"]) / float(e["delay"]), 0.0, 1.0)
		var beat: float = 0.5 + 0.5 * sin(arena._clock * lerpf(22.0, 9.0, left))
		for m: Node3D in e["marks"]:
			if is_instance_valid(m):
				m.scale = Vector3.ONE * (0.75 + 0.25 * (1.0 - left) + beat * 0.12)
		if float(e["t"]) <= 0.0:
			_fire_echo(e)


func _fire_echo(e: Dictionary) -> void:
	_echoes.erase(e)
	for n: Node3D in e["marks"]:
		if is_instance_valid(n):
			n.queue_free()
	var at: Vector2i = e["at"]
	if stones.has(at):
		stones[at]["busy"] = false
		stones[at]["charge"] = 0
		stones[at]["bump"] = 1.0
	_own = true
	for d: Vector2i in DIRS:
		_arm(at + d, d, int(e["reach"]), 1)
	_own = false
	arena._spawn_ring(Vector3(at.x, 0.12, at.y), M.MOUTH, 1.2 + int(e["reach"]) * 0.4)
	arena._spawn_ring(Vector3(at.x, 0.14, at.y), Color.WHITE, 0.8)
	arena._shake = maxf(arena._shake, 0.15)
	_sound(_snd_echo, 1.0)


## One arm of a let-out blast: like the arena's blast arm, but a shell it
## reaches stores it instead of burning.
func _arm(start: Vector2i, d: Vector2i, reach: int, dist0: int) -> void:
	var cc: Vector2i = start
	for i in reach:
		var t: int = arena.tile(cc)
		if t == Arena.WALL:
			return
		arena._add_flame(cc, dist0 + i, d)
		_flame_reach[cc] = reach
		if stones.has(cc):
			_charge(cc, reach)
			return
		if t == Arena.CRATE:
			arena._break_crate(cc)
			return
		if t == Arena.BARREL:
			arena._ignite_barrel(cc)
			return
		if arena.pod_at.has(cc):
			var pod: Arena.Pod = arena.pod_at[cc]
			pod.timer = minf(pod.timer, 0.06)
			return
		cc += d


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	if not _pending.is_empty() or not _fresh.is_empty():
		# A blast that did not come from a pod (a barrel): reach 2.
		_settle(2)
	_update_echoes(delta)
	_update_crabs(delta)
	if not arena.demo:
		_update_clam(delta)
		# Safety net: a shell left full too long lets go by itself.
		for c: Vector2i in stones:
			var s: Dictionary = stones[c]
			if int(s["charge"]) > 0 and not bool(s["busy"]):
				s["held"] = float(s.get("held", 0.0)) + delta
				if float(s["held"]) >= AUTO_RELEASE:
					_release(c)
	_animate(delta)
	for c: Vector2i in _flame_reach.keys():
		if not arena.flames.has(c):
			_flame_reach.erase(c)
	_pod_fire.clear()
	for p: Arena.Pod in arena.pods:
		_pod_fire[p.cell] = p.fire


func _animate(delta: float) -> void:
	var clock: float = arena._clock
	var charged: bool = false
	for c: Vector2i in stones:
		var s: Dictionary = stones[c]
		s["bump"] = maxf(float(s["bump"]) - delta * 3.0, 0.0)
		var node: Node3D = s["node"]
		var shell: Node3D = node.get_node("Shell")
		var halo: Node3D = node.get_node("Halo")
		var mouth: MeshInstance3D = shell.get_node("Mouth")
		var busy: bool = bool(s["busy"])
		var charge: int = int(s["charge"])
		if charge > 0 and not busy:
			charged = true
		if int(s["shown"]) != charge:
			s["shown"] = charge
			var pearls: Node3D = node.get_node("Pearls")
			for k in pearls.get_child_count():
				(pearls.get_child(k) as Node3D).visible = k < charge
			mouth.material_override = _mouth_on if charge > 0 else _mouth_off
			(node.get_node("Base") as MeshInstance3D).material_override = _base_on if charge > 0 else _base_off
		halo.visible = charge > 0
		var b: float = float(s["bump"])
		if busy:
			var q: float = 0.5 + 0.5 * sin(clock * 18.0)
			shell.scale = Vector3.ONE * (1.0 + 0.07 * q + b * 0.12)
			shell.rotation.z = sin(clock * 30.0) * 0.05
			halo.scale = Vector3(1.0 + q * 0.35, 0.4, 1.0 + q * 0.35)
		elif charge > 0:
			# Full: a slow breathing glow (quicker in the last seconds before
			# the safety net lets it go).
			var late: bool = float(s.get("held", 0.0)) > AUTO_RELEASE - 3.0
			var q2: float = 0.5 + 0.5 * sin(clock * (8.0 if late else 3.0) + c.x)
			shell.scale = Vector3.ONE * (1.0 + 0.03 * q2 + b * 0.12)
			shell.rotation.z = 0.0
			halo.scale = Vector3(1.0 + q2 * 0.15, 0.4, 1.0 + q2 * 0.15)
			(node.get_node("Pearls") as Node3D).position.y = 0.02 * sin(clock * 2.4 + c.x)
		else:
			var idle: float = sin(clock * 1.6 + c.x + c.y * 0.7)
			shell.scale = Vector3(1.0 + b * 0.12, 1.0 + idle * 0.015 - b * 0.06, 1.0 + b * 0.12)
			shell.rotation.z = 0.0
		var pulse: float = 0.0
		if busy:
			pulse = 0.25 * (0.5 + 0.5 * sin(clock * 14.0))
		elif charge > 0:
			pulse = 0.1 * (0.5 + 0.5 * sin(clock * 3.0 + c.x))
		mouth.scale = Vector3(1.2, 1.0, 0.55) * (1.0 + pulse)
	for c: Vector2i in horns:
		var h: Dictionary = horns[c]
		h["bump"] = maxf(float(h["bump"]) - delta * 2.5, 0.0)
		var hn: Node3D = h["node"]
		var horn: Node3D = hn.get_node("Horn")
		var hb: float = float(h["bump"])
		horn.rotation.x = -0.5 * hb
		horn.scale = Vector3.ONE * (1.0 + 0.25 * hb)
		var glow: Node3D = hn.get_node("Glow")
		glow.visible = charged
		glow.scale = Vector3.ONE * (1.0 + 0.1 * sin(clock * 5.0))
	if _hum != null:
		var want: bool = charged and Save.sound_on and not arena.demo
		if want and not _hum.playing:
			_hum.play()
		elif not want and _hum.playing:
			_hum.stop()
	for pool: Node3D in _pools:
		if is_instance_valid(pool) and pool.get_child_count() > 1:
			var water: Node3D = pool.get_child(1)
			water.position.y = 0.07 + sin(clock * 1.3 + pool.global_position.x) * 0.006


# --- Hermit crabs -------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"crab":
			return M.crab()
		&"wisp":
			return M.jelly()
		&"boss":
			return M.clam()
	return null


func critter_speed(kind: StringName) -> float:
	if kind == &"crab":
		return _crab_speed()
	return 1.5


func _crab_speed() -> float:
	return 1.75 + 0.05 * arena.level_id


func _update_crabs(delta: float) -> void:
	# New pods spook the crabs close to them.
	for p: Arena.Pod in arena.pods:
		if _seen_pods.has(p):
			continue
		_seen_pods[p] = true
		for cr: Arena.Critter in arena.critters:
			if cr.kind != &"crab":
				continue
			var at := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
			if absi(at.x - p.cell.x) + absi(at.y - p.cell.y) > CRAB_HIDE_RANGE:
				continue
			if not _hide.has(cr):
				_hide[cr] = {"pods": [], "out": CRAB_POP_DELAY}
				arena._spawn_ring(Vector3(cr.pos.x, 0.1, cr.pos.y), M.CRAB_SHELL, 0.5)
			(_hide[cr]["pods"] as Array).append(p)
			_hide[cr]["out"] = CRAB_POP_DELAY
	for p: Arena.Pod in _seen_pods.keys():
		if not arena.pods.has(p):
			_seen_pods.erase(p)
	for cr: Arena.Critter in _hide.keys():
		if not arena.critters.has(cr):
			_hide.erase(cr)
			continue
		var h: Dictionary = _hide[cr]
		var list: Array = (h["pods"] as Array).filter(func(p: Arena.Pod) -> bool: return arena.pods.has(p))
		h["pods"] = list
		if list.is_empty():
			h["out"] = float(h["out"]) - delta
			if float(h["out"]) <= 0.0:
				_hide.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"crab":
			continue
		var hidden: bool = _hide.has(cr)
		cr.speed = 0.0 if hidden else _crab_speed()
		_tuck[cr] = move_toward(float(_tuck.get(cr, 0.0)), 1.0 if hidden else 0.0, delta * 6.0)
	for cr: Arena.Critter in _tuck.keys():
		if not arena.critters.has(cr):
			_tuck.erase(cr)


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr.kind == &"crab" and _hide.has(cr)


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"crab":
		return Vector2i.ZERO
	var open: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		var n: Vector2i = cr.cell + d
		if arena._critter_can_enter(cr, n) and not arena.flames.has(n) and not _marked(n):
			open.append(d)
	if open.is_empty():
		return Vector2i.ZERO
	# Shy: when Pip comes close they mostly scuttle away.
	if not arena.demo and arena.hero_alive:
		var hc: Vector2i = arena.hero_cell()
		var dist: int = absi(hc.x - cr.cell.x) + absi(hc.y - cr.cell.y)
		if dist <= 3 and arena.rng.randf() < 0.65:
			var best: Vector2i = open[0]
			var best_d: int = -1
			for d: Vector2i in open:
				var n2: Vector2i = cr.cell + d
				var dd: int = absi(hc.x - n2.x) + absi(hc.y - n2.y)
				if dd > best_d or (dd == best_d and arena.rng.randf() < 0.5):
					best_d = dd
					best = d
			return best
	if open.has(cr.dir) and arena.rng.randf() < 0.72:
		return cr.dir
	var turns: Array[Vector2i] = open.filter(func(d: Vector2i) -> bool: return d != -cr.dir)
	if turns.is_empty():
		return open[0]
	return turns[arena.rng.randi() % turns.size()]


## A tile an echo is about to hit (crabs avoid stepping onto those).
func _marked(c: Vector2i) -> bool:
	for e: Dictionary in _echoes:
		if (e["path"] as Array).has(c) and float(e["t"]) < 0.8:
			return true
	return false


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"crab":
			var tuck: float = float(_tuck.get(cr, 0.0))
			# Scuttle sideways.
			body.rotation.y = lerp_angle(body.rotation.y, PI * 0.5, minf(delta * 10.0, 1.0))
			var crab: Node3D = body.get_node("Crab")
			crab.scale = Vector3.ONE * maxf(1.0 - tuck, 0.001)
			crab.position = Vector3(0, -0.12 * tuck, -0.1 * tuck)
			var shell: Node3D = body.get_node("Shell")
			shell.position = Vector3(0, 0.08 - 0.06 * tuck, -0.1 + 0.08 * tuck)
			shell.rotation.x = lerpf(-0.6, -0.1, tuck)
			if tuck > 0.9:
				shell.rotation.z = sin(t * 9.0) * 0.06
			else:
				shell.rotation.z = 0.0
			var walking: bool = cr.t < 1.0 and cr.speed > 0.0
			var step: float = sin(t * 18.0) if walking else 0.0
			for side: String in ["L", "R"]:
				for k in 3:
					var leg: Node3D = crab.get_node("Leg%s%d" % [side, k])
					leg.rotation.x = step * 0.5 * (1.0 if k % 2 == 0 else -1.0)
			(crab.get_node("ClawL") as Node3D).rotation.x = -0.2 + sin(t * 3.0) * 0.25
			(crab.get_node("ClawR") as Node3D).rotation.x = -0.2 + sin(t * 3.0 + 1.3) * 0.25
			body.position.y = absf(step) * 0.03
			return Vector3.ONE * M.CRAB_SIZE
		&"wisp":
			body.position.y = sin(t * 2.2) * 0.1
			var pulse: float = sin(t * 3.0)
			for k in 5:
				var tt: Node3D = body.get_node("T%d" % k)
				tt.rotation.x = sin(t * 3.0 + k * 1.3) * 0.35
				tt.rotation.z = cos(t * 2.6 + k) * 0.25
			return Vector3(1.0 + pulse * 0.07, 1.0 - pulse * 0.08, 1.0 + pulse * 0.07) * M.JELLY_SIZE
		&"boss":
			return _pose_clam(cr, body, t, delta)
	return Vector3.ONE


# --- The Grand Clam ------------------------------------------------------------------

func _clam_phase2() -> bool:
	return arena.boss != null and arena.boss.hp <= CLAM_PHASE2_HP


func _clam_echoing() -> bool:
	for e: Dictionary in _echoes:
		if bool(e["clam"]):
			return true
	return false


## Shut 4.5 s (moving; blasts are swallowed and kept), then a roar (stands
## still; a kept blast is telegraphed and roared back out), then open 3.6 s
## (still, pearl showing, the only time it can be hurt).
func _update_clam(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		return
	_deflect = maxf(_deflect - delta, 0.0)
	_clam_snap = maxf(_clam_snap - delta * 3.0, 0.0)
	var p2: bool = _clam_phase2()
	match _clam_state:
		&"shut":
			_clam_t -= delta
			if _clam_t <= 0.0:
				_clam_state = &"roar"
				_clam_t = CLAM_ROAR
				_sound(_snd_horn, 0.62)
				arena._shake = maxf(arena._shake, 0.2)
				arena._spawn_ring(Vector3(b.pos.x, 0.1, b.pos.y), M.CLAM, 1.6)
				if _clam_charge > 0:
					var here: Vector2i = b.cell
					if b.t > 0.0 and b.t < 1.0 and b.t >= 0.15:
						here = b.target
					_start_echo(here, _clam_charge + (1 if p2 else 0), CLAM_ROAR, true)
		&"roar":
			_clam_t -= delta
			if _clam_t <= 0.0 and not _clam_echoing():
				_clam_charge = 0
				_clam_state = &"open"
				_clam_t = CLAM_OPEN - (0.5 if p2 else 0.0)
				arena._spawn_sparkles(Vector3(b.pos.x, 0.9, b.pos.y), M.PEARL)
				_sound(_snd_snap, 1.3)
		&"open":
			_clam_t -= delta
			if _clam_t <= 0.0:
				_shut_clam()
	var sp: float = 0.85 + (arena.boss_max_hp - b.hp) * 0.06
	if _clam_state != &"shut":
		sp = 0.0
	if sp == 0.0 and b.t > 0.0 and b.t < 1.0:
		if b.t < 0.15:
			# Only just set off: settle back on the tile.
			b.target = b.cell
			b.t = 1.0
			b.pos = Vector2(b.cell)
		else:
			# Finish the step first, then stop.
			sp = 1.4
	b.speed = sp
	_clam_open = move_toward(_clam_open, 1.0 if _clam_state == &"open" else 0.0, delta * (4.0 if _clam_state == &"open" else 9.0))


func _shut_clam() -> void:
	_clam_state = &"shut"
	_clam_t = CLAM_SHUT - (1.0 if _clam_phase2() else 0.0)
	_clam_snap = 1.0
	_sound(_snd_snap, 0.9)


func critter_hit(cr: Arena.Critter) -> bool:
	if cr != arena.boss or arena.demo:
		return false
	if _clam_state == &"open":
		# A real hit: it snaps shut straight after.
		_shut_clam()
		return false
	# Shut (or roaring): no harm done. While shut it swallows the blast and
	# keeps it for its next roar.
	cr.invuln = 0.7
	_deflect = 0.7
	_clam_snap = 1.0
	if _clam_state == &"shut":
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		var reach: int = int(_flame_reach.get(here, _flame_reach.get(cr.cell, 2)))
		_clam_charge = clampi(maxi(_clam_charge, reach), 1, CLAM_MAX_CHARGE)
		_sound(_snd_charge, 0.75)
	arena._spawn_sparkles(Vector3(cr.pos.x, 0.8, cr.pos.y), M.MOUTH)
	return true


func _pose_clam(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	if _deflect > 0.0:
		body.visible = true
	var lid: Node3D = body.get_node("Lid")
	var roar: bool = _clam_state == &"roar"
	var trem: float = (sin(t * 38.0) * 0.06 - 0.16) if roar else 0.0
	lid.rotation.x = -0.95 * _clam_open + trem - _clam_snap * 0.05
	body.rotation.z = (sin(t * 45.0) * 0.04) if roar else 0.0
	var pearl: Node3D = body.get_node("Pearl")
	pearl.scale = Vector3.ONE * (0.6 + 0.4 * _clam_open + 0.08 * sin(t * 6.0) * _clam_open)
	var charge: Node3D = lid.get_node("Charge")
	for k in charge.get_child_count():
		var p: Node3D = charge.get_child(k)
		p.visible = k < _clam_charge
		p.scale = Vector3.ONE * (1.0 + 0.2 * sin(t * 6.0 + k))
	var brows: Node3D = lid.get_node("Eyes")
	brows.position.y = 0.03 * sin(t * 2.0)
	var walk: float = absf(sin(t * 6.0)) if (cr.t < 1.0 and cr.speed > 0.0) else 0.0
	body.position.y = walk * 0.06
	var puff: float = 0.05 * absf(sin(t * 20.0)) if roar else 0.0
	return Vector3(1.0 + _clam_snap * 0.1 + puff, 1.0 - _clam_snap * 0.1 + walk * 0.03 + puff, 1.0 + _clam_snap * 0.1 + puff)


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


## A soft shimmering bell swell: a shell is about to echo.
func _make_charge() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var env: float = minf(t / 0.25, 1.0) * exp(-maxf(t - 0.25, 0.0) * 6.0)
		var trem: float = 0.75 + 0.25 * sin(TAU * 11.0 * t)
		var v: float = sin(TAU * 1046.5 * t) + 0.5 * sin(TAU * 1568.0 * t) + 0.25 * sin(TAU * 2793.0 * t)
		out[i] = v * env * trem * 0.16
	return _wav(out)


## A round "bwoom" with two fading repeats: the echo rings out.
func _make_echo() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.75)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for k in 3:
			var tk: float = t - k * 0.16
			if tk < 0.0:
				continue
			var f: float = 330.0 + 260.0 * exp(-tk * 14.0)
			var g: float = pow(0.45, k)
			v += g * (sin(TAU * f * tk) + 0.35 * sin(TAU * f * 2.01 * tk)) * minf(tk / 0.006, 1.0) * exp(-tk * 9.0)
		out[i] = v * 0.33
	return _wav(out)


## A woody clack: the clam snaps shut or pops open.
func _make_snap() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.25)
	var out := PackedFloat32Array()
	out.resize(n)
	var rs: int = 9
	for i in n:
		var t: float = i / rate
		rs = (rs * 1103515245 + 12345) & 0x7fffffff
		var noise: float = float(rs) / float(0x7fffffff) * 2.0 - 1.0
		var tone: float = sin(TAU * (520.0 + 300.0 * exp(-t * 40.0)) * t)
		out[i] = (tone * 0.7 + noise * 0.3 * exp(-t * 60.0)) * exp(-t * 22.0) * 0.4
	return _wav(out)


## A soft hum while any shell holds a blast. Whole cycles fit in one second,
## so it loops without a click.
func _make_hum() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var trem: float = 0.8 + 0.2 * sin(TAU * 3.0 * t)
		out[i] = (sin(TAU * 220.0 * t) + 0.45 * sin(TAU * 330.0 * t) + 0.2 * sin(TAU * 440.0 * t)) * trem * 0.3
	var w: AudioStreamWAV = _wav(out)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## A round conch-horn call: a breathy "hoooo" that slides up a little.
func _make_horn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	var rs: int = 21
	for i in n:
		var t: float = i / rate
		var f: float = 233.0 * (1.0 + 0.06 * (1.0 - exp(-t * 9.0))) * (1.0 + 0.008 * sin(TAU * 5.5 * t))
		ph += TAU * f / rate
		rs = (rs * 1103515245 + 12345) & 0x7fffffff
		var breath: float = (float(rs) / float(0x7fffffff) * 2.0 - 1.0) * 0.06
		var env: float = minf(t / 0.09, 1.0) * clampf((0.9 - t) / 0.3, 0.0, 1.0)
		var v: float = sin(ph) + 0.5 * sin(2.0 * ph) + 0.22 * sin(3.0 * ph) + 0.08 * sin(4.0 * ph)
		out[i] = (v * 0.3 + breath) * env
	return _wav(out)

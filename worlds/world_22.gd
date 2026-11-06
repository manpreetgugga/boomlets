extends WorldKit
## World 22, Comet Orbit: a playful little planetoid in space, with a
## lavender sky, soft stars, ringed planets on the horizon and bright
## moon-rock floors. The twist is orbits: round asteroids circle a planet
## block on a fixed ring of tiles (drawn as a faint dotted orbit with
## arrows), all stepping one tile round the ring every beat. They block
## walking, critters and blasts. One that rolls into Pip just bumps him
## aside (never hurts); a pod or a critter in the way jams the whole ring
## until it clears. Blasting a planet flips its spin switch, so its moons
## orbit the other way, and a blasted asteroid shatters into rubble that
## drifts round with the ring and reforms a few seconds later (after a
## flicker, and only on a clear tile). UFO saucers hover in straight lines
## and now and then stop, light a warning spot on the tile ahead and beam
## it. The Moon Whale boss swims round with its own little moons, which
## shield it from blasts on the tiles beside it.
##
## Extra map characters:
##   O  planet block (its ring is set in the level's "orbits")
##   u  UFO saucer
## Level key "orbits": a list of {"at": [x, z], "r": ring radius (1 or 2),
## "ast": [slot, ...], "dir": 1 (clockwise) or -1, "beat": seconds}. Ring
## slots count clockwise from the ring's top-left tile. Ring tiles must be
## plain floor ("_" in the map); build_extra checks this.

const M := preload("res://worlds/world_22_models.gd")

const MOVE_TIME: float = 0.32
const REFORM: float = 6.0
const REFORM_WARN: float = 1.3
const PUSH_TIME: float = 0.2
const FLIP_COOL: float = 0.6
const BEAM_TIME: float = 0.5
const BOSS_REFORM: float = 5.0

const PALETTE: Dictionary = {
	"GRASS_A": "#EAE2F9", "GRASS_B": "#DBD0F3", "RIM": "#D8CEF0", "EDGE": "#8C7DD6",
	"STONE": "#F6F2FC", "DARK_STONE": "#B6A8DE", "DIRT": "#A797D6", "ROCK": "#8B7CC0",
	"WOOD": "#FFB04F", "WOOD_DARK": "#FFF0C8", "BARREL": "#FF6B6B", "BELT": "#6E66A0", "ACCENT": "#FFC94D",
	"BLOSSOM_A": "#9FE3C9", "BLOSSOM_B": "#7FD3B8", "TRUNK": "#9E92C8", "LEAFY_A": "#C9B8F5", "LEAFY_B": "#B3A0EE",
	"SKY_TOP": "#A693EC", "SKY_HORIZON": "#FCE4F3", "SKY_GROUND": "#E2D5FA", "CLOUD": "#F7F0FF", "CLOUDS": 0.42,
	"AMBIENT": "#D7CBF4", "AMBIENT_ENERGY": 0.6, "SUN": "#FFF4FA", "SUN_ENERGY": 1.45,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Little Planet",
		"tip": "Moons orbit the planet one step\nevery beat. Time your dash past!\nBlast the planet to spin them back.",
		"crates": 0.4, "par": 72,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"orbits": [{"at": [6, 6], "r": 1, "ast": [0, 4], "dir": 1, "beat": 1.3}],
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.u.........#",
			"#.#.#.#.#.#.#",
			"#....___..b.#",
			"#####_O_#####",
			"#....___....#",
			"#.#.#.#.#.#.#",
			"#.b.......u.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Saucer Lanes",
		"tip": "UFOs stop, light a spot ahead\nand beam it. Step off the glow!\nBlasted moons reform in a moment.",
		"crates": 0.42, "par": 82,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"orbits": [
			{"at": [4, 6], "r": 1, "ast": [1, 5], "dir": 1, "beat": 1.15},
			{"at": [8, 8], "r": 1, "ast": [0, 4], "dir": -1, "beat": 1.15},
		],
		"map": [
			"#############",
			"#.u...E...u.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#..___......#",
			"#.#_O_#.#.#.#",
			"#..___.___..#",
			"#.#.#.#_O_#.#",
			"#.b....___..#",
			"#.#.#.#.#.#.#",
			"#.....b...u.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Ring Round the Exit",
		"tip": "The exit hides inside a big orbit.\nSlip through a gap, or shatter\na moon to make one!",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"orbits": [
			{"at": [6, 4], "r": 2, "ast": [0, 4, 8, 12], "dir": 1, "beat": 0.95},
			{"at": [6, 10], "r": 1, "ast": [1, 5], "dir": -1, "beat": 1.2},
		],
		"map": [
			"#############",
			"#.u.......u.#",
			"#.#._____.#.#",
			"#...__E__...#",
			"#.#.__O__.#.#",
			"#..._____...#",
			"#.#._____.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#.b..___..z.#",
			"#.#.#_O_#.#.#",
			"#....___..u.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Asteroid Belt",
		"tip": "Three orbits wall off the north.\nPods jam a ring, and planet blasts\nflip it. Find your moment!",
		"crates": 0.4, "par": 98,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"orbits": [
			{"at": [2, 6], "r": 1, "ast": [0, 4], "dir": 1, "beat": 1.0},
			{"at": [6, 6], "r": 1, "ast": [0, 3, 6], "dir": -1, "beat": 1.1},
			{"at": [10, 6], "r": 1, "ast": [2, 6], "dir": 1, "beat": 0.9},
		],
		"map": [
			"#############",
			"#.u...E...u.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#___.___.___#",
			"#_O_#_O_#_O_#",
			"#___.___.___#",
			"#.#.#.#.#.#.#",
			"#.b..B.B..z.#",
			"#.#.#.#.#.#.#",
			"#.u.......b.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Warp Nebula",
		"tip": "Warps hop across the nebula.\nHide behind a moon when\na saucer lines up its beam!",
		"crates": 0.4, "par": 106,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"orbits": [
			{"at": [4, 4], "r": 1, "ast": [0, 3, 6], "dir": 1, "beat": 0.95},
			{"at": [8, 10], "r": 1, "ast": [1, 4, 7], "dir": -1, "beat": 0.95},
		],
		"map": [
			"#############",
			"#1..u.E....2#",
			"#.#.#.#.#.#.#",
			"#..___...z..#",
			"#.#_O_#.#.#.#",
			"#..___.b....#",
			"#.#.#.#.#.#.#",
			"#.u.......u.#",
			"#.#.#.#.#.#.#",
			"#....b.___..#",
			"#.#.#.#_O_#.#",
			"#2..u..___.1#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "The Moon Whale",
		"tip": "Moons shield the Moon Whale!\nStrike when they swing to its\ncorners, or shatter one first.",
		"crates": 0.18, "par": 135, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"orbits": [
			{"at": [2, 4], "r": 1, "ast": [0, 4], "dir": 1, "beat": 1.2},
			{"at": [10, 10], "r": 1, "ast": [2, 6], "dir": -1, "beat": 1.2},
		],
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#___........#",
			"#_O_.......c#",
			"#___.#...#..#",
			"#.#.........#",
			"#.....K.....#",
			"#.........#.#",
			"#..#...#.___#",
			"#c......._O_#",
			"#........___#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## One per planet: {"p": planet cell, "r", "tiles": ring cells clockwise,
## "dir", "beat", "timer", "cool", "flip", "jam", "ast": [asteroid], "node",
## "arrows": [[node, base yaw]]}. An asteroid is {"ring", "slot", "from",
## "mt" (move 0..1), "alive", "rubble" (seconds left), "pop", "node"}.
var rings: Array[Dictionary] = []
var planets: Dictionary = {}       # Vector2i -> ring index
var _occ: Dictionary = {}          # Vector2i -> asteroid blocking it
var _push: Dictionary = {}
var _ufo: Dictionary = {}          # Critter -> {"mode", "t", "aim", "cd"}
var _boss_orb: Array[Dictionary] = []
var _boss_dir: int = 1
var _boss_timer: float = 1.0
var _boss_phase: int = -1
var _boss_hp: int = -1
var _clock: float = 0.0
var _dish_tips: Array[Node3D] = []
var _beacons: Array[Node3D] = []
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_flip: AudioStreamWAV
var _snd_bonk: AudioStreamWAV
var _snd_charge: AudioStreamWAV
var _snd_zap: AudioStreamWAV
var _snd_reform: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Comet Orbit"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_22.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "MOON WHALE"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	return &"ufo"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "O":
		planets[c] = -1
		return true
	return false


func critter_chars() -> Dictionary:
	return {"u": &"ufo"}


## The ring of cells [param r] steps round [param p], clockwise seen from
## above (z grows towards the camera), starting at the top-left corner.
static func ring_cells(p: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in range(p.x - r, p.x + r + 1):
		out.append(Vector2i(x, p.y - r))
	for z in range(p.y - r + 1, p.y + r + 1):
		out.append(Vector2i(p.x + r, z))
	for x in range(p.x + r - 1, p.x - r - 1, -1):
		out.append(Vector2i(x, p.y + r))
	for z in range(p.y + r - 1, p.y - r, -1):
		out.append(Vector2i(p.x - r, z))
	return out


func build_extra() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 22
	var specs: Array = arena.data.get("orbits", [])
	for i in specs.size():
		var spec: Dictionary = specs[i]
		var at := Vector2i(int(spec["at"][0]), int(spec["at"][1]))
		var ring := {
			"p": at, "r": int(spec["r"]), "tiles": ring_cells(at, int(spec["r"])),
			"dir": int(spec.get("dir", 1)), "beat": float(spec.get("beat", 1.2)),
			"timer": float(spec.get("beat", 1.2)), "cool": 0.0, "flip": 0.0, "jam": 0.0,
			"ast": [], "arrows": [],
		}
		planets[at] = i
		var n: Node3D = M.planet(M.PLANET_COLORS[i % M.PLANET_COLORS.size()])
		n.position = Vector3(at.x, 0, at.y)
		n.scale = Vector3.ONE * 1.25
		arena.add_child(n)
		ring["node"] = n
		for s: Variant in spec["ast"]:
			var a := {"ring": i, "slot": int(s), "from": int(s), "mt": 1.0, "alive": true, "rubble": 0.0, "pop": 0.0}
			var an: Node3D = M.asteroid(r)
			arena.add_child(an)
			a["node"] = an
			(ring["ast"] as Array).append(a)
		rings.append(ring)
		_build_track(ring)
		_pose_planet(ring, 0.0)
		for a: Dictionary in ring["ast"]:
			_pose_asteroid(ring, a, 0.0)
	_rebuild_occ()
	_check_level()
	_build_backdrop()
	_build_floor_craters()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -8.0
	arena.add_child(_player2)
	_snd_flip = _make_flip()
	_snd_bonk = _make_bonk()
	_snd_charge = _make_charge()
	_snd_zap = _make_zap()
	_snd_reform = _make_reform()


## The faint dotted orbit and its direction arrows.
func _build_track(ring: Dictionary) -> void:
	var tiles: Array[Vector2i] = []
	tiles.assign(ring["tiles"])
	var n: int = tiles.size()
	var dots: Array[Transform3D] = []
	var pads: Array[Transform3D] = []
	for i in n:
		var a: Vector2 = Vector2(tiles[i])
		var b: Vector2 = Vector2(tiles[(i + 1) % n])
		for k in 3:
			var p: Vector2 = a.lerp(b, k / 3.0)
			dots.append(Transform3D(Basis(), Vector3(p.x, 0.012, p.y)))
		pads.append(Transform3D(Basis(), Vector3(a.x, 0.004, a.y)))
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.02, 0.9), 0.008), Color("#D2C4F4"), pads)
	arena._multimesh(Models.cylinder(0.06, 0.06, 0.02, 8), Color("#9C84EA"), dots, Models.mat(Color("#9C84EA"), 0.3))
	# One arrow in the middle of each side (corner tiles turn).
	var side_len: int = 2 * int(ring["r"])
	for s in 4:
		var i: int = s * side_len + int(ring["r"])
		var a2: Vector2i = tiles[i % n]
		var b2: Vector2i = tiles[(i + 1) % n]
		var d: Vector2i = b2 - a2
		var holder := Node3D.new()
		holder.position = Vector3((a2.x + b2.x) * 0.5, 0.02, (a2.y + b2.y) * 0.5)
		var yaw: float = atan2(-float(d.y), float(d.x))
		holder.rotation.y = yaw
		arena.add_child(holder)
		var ch := Models.part(holder, Models.chevron_mesh(), M.GOLD, Vector3.ZERO, 0.5)
		ch.rotation.x = -PI * 0.5
		ch.scale = Vector3(0.8, 0.8, 0.6)
		ch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		(ring["arrows"] as Array).append([holder, yaw])
	_point_arrows(ring)


func _point_arrows(ring: Dictionary) -> void:
	for ar: Array in ring["arrows"]:
		var h: Node3D = ar[0]
		h.rotation.y = float(ar[1]) + (0.0 if int(ring["dir"]) > 0 else PI)


## Little craters scattered on the moon-rock floor (never on orbits).
func _build_floor_craters() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 5
	var rims: Array[Transform3D] = []
	var pits: Array[Transform3D] = []
	for z in range(1, Arena.H - 1):
		for x in range(1, Arena.W - 1):
			var c := Vector2i(x, z)
			if arena.tile(c) != Arena.FLOOR or _on_ring(c) or planets.has(c) or r.randf() > 0.12:
				continue
			if c == arena.exit_cell or c == arena.start_cell or arena.warps.has(c):
				continue
			var p := Vector3(x + r.randf_range(-0.2, 0.2), 0.004, z + r.randf_range(-0.2, 0.2))
			var s: float = r.randf_range(0.7, 1.1)
			rims.append(Transform3D(Basis().scaled(Vector3(s, 1, s)), p))
			pits.append(Transform3D(Basis().scaled(Vector3(s, 1, s)), p + Vector3(0, 0.006, 0)))
	var torus := TorusMesh.new()
	torus.inner_radius = 0.13
	torus.outer_radius = 0.2
	torus.rings = 16
	torus.ring_segments = 4
	arena._multimesh(torus, Color("#D4C9EE"), _flatten(rims, 0.3))
	arena._multimesh(Models.cylinder(0.14, 0.14, 0.01, 12), Color("#DCD2F1"), pits)


func _flatten(list: Array[Transform3D], y: float) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for tf in list:
		out.append(Transform3D(tf.basis.scaled(Vector3(1, y, 1)), tf.origin))
	return out


func _on_ring(c: Vector2i) -> bool:
	for ring: Dictionary in rings:
		if (ring["tiles"] as Array).has(c):
			return true
	return false


## Ringed planets on the horizon and soft stars below the island.
func _build_backdrop() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2222
	var specs: Array = [
		[Vector3(Arena.W + 0.5, -5.0, -9.5), 1.2, 0, 0.5],
		[Vector3(-2.5, -3.0, -8.0), 0.9, 1, -0.4],
		[Vector3(Arena.W + 3.0, -9.0, Arena.H + 4.0), 1.3, 3, 0.3],
		[Vector3(-6.0, -10.0, Arena.H + 1.0), 1.1, 2, -0.6],
	]
	for s: Array in specs:
		var cols: Array = M.PLANET_COLORS[int(s[2])]
		var pl: Node3D = M.ringed_planet(float(s[1]), (cols[0] as Color).lerp(Color("#E9DDFF"), 0.25), cols[1], float(s[3]))
		pl.position = s[0]
		arena.add_child(pl)
	var stars: Array[Transform3D] = []
	var big: Array[Transform3D] = []
	var face := Basis(Vector3.RIGHT, -atan2(11.0, 5.0))
	for k in 70:
		var p := Vector3(r.randf_range(-16, Arena.W + 15), r.randf_range(-12, -3), r.randf_range(-10, Arena.H + 10))
		# Keep clear of the island itself.
		if p.x > -3.5 and p.x < Arena.W + 2.5 and p.z > -3.5 and p.z < Arena.H + 2.5:
			continue
		var tf := Transform3D(face.rotated(Vector3.UP, r.randf_range(-0.3, 0.3)).scaled(Vector3.ONE * r.randf_range(0.7, 1.3)), p)
		if r.randf() < 0.25:
			big.append(tf)
		else:
			stars.append(tf)
	arena._multimesh(M.star_mesh(0.14, 0.03), Color("#FFF6D8"), stars, Models.mat(Color("#FFF6D8"), 1.6))
	arena._multimesh(M.star_mesh(0.24, 0.04), Color("#FFE0F2"), big, Models.mat(Color("#FFE0F2"), 1.5))


## Reports map mistakes: ring cells that are not plain floor, rings that
## share cells, and an exit or critter that cannot be reached from the
## start (planets count as walls, moons and crates do not).
func _check_level() -> void:
	var name: String = arena.data["name"]
	var seen: Dictionary = {}
	for ring: Dictionary in rings:
		for c: Vector2i in ring["tiles"]:
			var bad: String = ""
			if c.x < 1 or c.y < 1 or c.x > Arena.W - 2 or c.y > Arena.H - 2:
				bad = "off the board"
			elif arena.tile(c) != Arena.FLOOR:
				bad = "not floor"
			elif planets.has(c) or c == arena.start_cell or c == arena.exit_cell or arena.warps.has(c) or arena.belts.has(c):
				bad = "on a special tile"
			elif seen.has(c):
				bad = "shared by two rings"
			if bad != "":
				push_error("World 22 '%s': orbit cell %s is %s" % [name, c, bad])
			seen[c] = true
		var n: int = (ring["tiles"] as Array).size()
		for a: Dictionary in ring["ast"]:
			if int(a["slot"]) < 0 or int(a["slot"]) >= n:
				push_error("World 22 '%s': asteroid slot %d out of range" % [name, a["slot"]])
	for p: Vector2i in planets:
		if int(planets[p]) < 0:
			push_error("World 22 '%s': planet %s has no orbit" % [name, p])
	# Reachability.
	var reach: Dictionary = {arena.start_cell: true}
	var queue: Array[Vector2i] = [arena.start_cell]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var nexts: Array[Vector2i] = []
		for d: Vector2i in Arena.DIRS:
			nexts.append(c + d)
		if arena.warps.has(c):
			nexts.append(arena.warps[c])
		for nc: Vector2i in nexts:
			if reach.has(nc):
				continue
			var t: int = arena.tile(nc)
			if t == Arena.WALL or planets.has(nc):
				continue
			reach[nc] = true
			queue.append(nc)
	if arena.exit_cell.x >= 0 and not reach.has(arena.exit_cell):
		push_error("World 22 '%s': exit not reachable" % name)
	for cr: Arena.Critter in arena.critters:
		if not reach.has(cr.cell):
			push_error("World 22 '%s': critter at %s not reachable" % [name, cr.cell])


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# A lilac coping with a little glowing star on every third block and a
	# crystal on each corner.
	var strips: Array[Transform3D] = []
	var stars: Array[Transform3D] = []
	var gems: Array[Transform3D] = []
	var face := Basis(Vector3.RIGHT, -atan2(11.0, 5.0) * 0.6)
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var along_x: bool = z == 0 or z == Arena.H - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		var at := Vector3(x, 0.7, z)
		var corner: bool = (x == 0 or x == Arena.W - 1) and (z == 0 or z == Arena.H - 1)
		if corner:
			gems.append(Transform3D(Basis(Vector3.UP, 0.3), at + Vector3(0, 0.2, 0)))
			continue
		strips.append(Transform3D(turn, at))
		if (x + z) % 3 == 0:
			stars.append(Transform3D(face, at + Vector3(0, 0.2, 0)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.06, 0.42), 0.025), Color("#C9B8F5"), strips)
	arena._multimesh(M.star_mesh(0.15, 0.06), M.GOLD, stars, Models.mat(M.GOLD, 0.9))
	arena._multimesh(M.gem_mesh(0.12, 0.42), Color("#8FE3FF"), gems, Models.mat(Color("#8FE3FF"), 0.5))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Moon-rock pillars: a pale block with a lighter cap, a crater or two on
	# top and now and then a little crystal.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var bodies: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var craters: Array[Transform3D] = []
	var gems: Array[Array] = [[], []]
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var turn := Basis(Vector3.UP, r.randf_range(-0.12, 0.12))
		bodies.append(Transform3D(turn, p + Vector3(0, 0.33, 0)))
		caps.append(Transform3D(turn, p + Vector3(0, 0.7, 0)))
		for k in r.randi_range(1, 2):
			var s: float = r.randf_range(0.7, 1.15)
			craters.append(Transform3D(Basis().scaled(Vector3(s, 0.3, s)), p + Vector3(r.randf_range(-0.2, 0.2), 0.77, r.randf_range(-0.2, 0.2))))
		if r.randf() < 0.3:
			var g := Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.3, 0.3)), p + Vector3(r.randf_range(-0.22, 0.22), 0.85, r.randf_range(-0.22, 0.1)))
			(gems[r.randi() % 2] as Array).append(g)
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.66, 0.84), 0.12), Color("#9C8AD8"), bodies)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.05), Color("#C7B9F1"), caps)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.07
	torus.outer_radius = 0.12
	torus.rings = 14
	torus.ring_segments = 5
	arena._multimesh(torus, Color("#AE9EE4"), craters)
	var cols: Array[Color] = [Color("#8FE3FF"), Color("#FFA8DD")]
	for i in 2:
		var list: Array[Transform3D] = []
		list.assign(gems[i])
		arena._multimesh(M.gem_mesh(0.06, 0.26), cols[i], list, Models.mat(cols[i], 0.5))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.22:
			node = M.moon_rock(r)
		elif roll < 0.36:
			node = M.crystals(r, 0.7)
	elif p.z < 0.0:
		if roll < 0.22:
			node = M.crystals(r, 1.3)
		elif roll < 0.34:
			node = M.rocket(r)
		elif roll < 0.42:
			node = M.dish()
			_dish_tips.append(node.get_node("Tip"))
		elif roll < 0.52:
			node = M.beacon([M.GOLD, M.PINK, Color("#8FE3FF")][r.randi() % 3])
			_beacons.append(node.get_node("Star"))
		elif roll < 0.66:
			node = M.moon_rock(r)
	else:
		if roll < 0.18:
			node = M.crystals(r, 1.0)
		elif roll < 0.26:
			node = M.rocket(r)
		elif roll < 0.33:
			node = M.dish()
			node.rotation.y = -PI * 0.5 if p.x < 0.0 else PI * 0.5
			_dish_tips.append(node.get_node("Tip"))
		elif roll < 0.4:
			node = M.beacon([M.GOLD, M.PINK, Color("#8FE3FF")][r.randi() % 3])
			_beacons.append(node.get_node("Star"))
		elif roll < 0.58:
			node = M.moon_rock(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var c := M.crystals(r, 1.6)
	c.position = Vector3(-size * 0.2, 0, -size * 0.1)
	root.add_child(c)
	if r.randf() < 0.6:
		var rk := M.rocket(r)
		rk.scale = Vector3.ONE * 1.4
		rk.position = Vector3(size * 0.22, 0, size * 0.1)
		root.add_child(rk)
	else:
		var d := M.dish()
		d.scale = Vector3.ONE * 1.5
		d.position = Vector3(size * 0.22, 0, size * 0.1)
		root.add_child(d)
	var mr := M.moon_rock(r)
	mr.position = Vector3(0.1, 0, size * 0.3)
	root.add_child(mr)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF2FA")
	env.adjustment_saturation = 1.08
	env.glow_intensity = 0.55


# --- Rules ------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return planets.has(c) or _occ.has(c)


func flame_stop(c: Vector2i) -> int:
	if planets.has(c) or _occ.has(c) or _boss_orb_at(c) != null:
		return 1
	return 0


func on_flame(c: Vector2i) -> void:
	if planets.has(c):
		var i: int = planets[c]
		if i >= 0:
			_reverse(rings[i])
	if _occ.has(c):
		var a: Dictionary = _occ[c]
		_shatter(a)
	var bo: Variant = _boss_orb_at(c)
	if bo != null:
		_shatter_boss_orb(bo)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not blocks(c)


func _rebuild_occ() -> void:
	_occ.clear()
	for ring: Dictionary in rings:
		for a: Dictionary in ring["ast"]:
			if bool(a["alive"]):
				for c: Vector2i in _ast_cells(ring, a):
					_occ[c] = a


func _ast_cells(ring: Dictionary, a: Dictionary) -> Array[Vector2i]:
	var tiles: Array = ring["tiles"]
	var out: Array[Vector2i] = [tiles[int(a["slot"])]]
	if float(a["mt"]) < 1.0:
		out.append(tiles[int(a["from"])])
	return out


func _reverse(ring: Dictionary) -> void:
	if float(ring["cool"]) > 0.0:
		return
	ring["cool"] = FLIP_COOL
	ring["dir"] = -int(ring["dir"])
	ring["flip"] = 1.0
	_point_arrows(ring)
	var p: Vector2i = ring["p"]
	arena._spawn_sparkles(Vector3(p.x, 0.7, p.y), M.GOLD)
	arena._spawn_ring(Vector3(p.x, 0.08, p.y), M.GOLD, 1.2)
	_sound(_player, _snd_flip, 1.0)


func _shatter(a: Dictionary) -> void:
	if not bool(a["alive"]):
		return
	a["alive"] = false
	a["rubble"] = REFORM
	var n: Node3D = a["node"]
	_burst(n.position + Vector3(0, 0.4, 0), M.ROCK)
	n.get_node("Body").visible = false
	n.get_node("Ghost").visible = true
	_rebuild_occ()


func _burst(at: Vector3, color: Color) -> void:
	var chunk := Models.box_mesh(Vector3(0.18, 0.16, 0.18), 0.05)
	for k in 9:
		var piece := Models.part(arena, chunk, color.darkened(0.12 * (k % 3)), at + Vector3(randf_range(-0.15, 0.15), randf_range(-0.1, 0.15), randf_range(-0.15, 0.15)))
		piece.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang: float = TAU * k / 9.0 + randf_range(-0.3, 0.3)
		var out: float = randf_range(1.8, 3.4)
		arena._fx.append({"node": piece, "t": 0.0, "life": randf_range(0.8, 1.1), "kind": &"debris", "floor": 0.06,
			"vel": Vector3(cos(ang) * out, randf_range(3.0, 5.0), sin(ang) * out),
			"spin": Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))})
	arena._spawn_ring(Vector3(at.x, 0.06, at.z), M.ROCK_LIGHT, 0.8)
	Sfx.play(&"crunch", 0.15)
	arena._shake = maxf(arena._shake, 0.16)


## True while nothing stands on [param c], so a moon may reform there.
func _cell_clear(c: Vector2i) -> bool:
	if arena.pod_at.has(c) or arena.flames.has(c) or _occ.has(c):
		return false
	if _hero_on(c, 0.85):
		return false
	return not _critter_on(c)


func _hero_on(c: Vector2i, reach: float) -> bool:
	if arena.demo or arena.hero == null or not arena.hero_alive:
		return false
	return absf(arena.hero_pos.x - c.x) < reach and absf(arena.hero_pos.y - c.y) < reach


func _critter_on(c: Vector2i) -> bool:
	for cr: Arena.Critter in arena.critters:
		if cr.cell == c or (cr.t < 1.0 and cr.target == c) or Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			return true
	return false


# --- Orbits ------------------------------------------------------------------------

func _update_rings(delta: float) -> void:
	for ring: Dictionary in rings:
		ring["cool"] = maxf(float(ring["cool"]) - delta, 0.0)
		ring["flip"] = maxf(float(ring["flip"]) - delta * 1.6, 0.0)
		ring["jam"] = maxf(float(ring["jam"]) - delta * 3.0, 0.0)
		ring["timer"] = float(ring["timer"]) - delta
		if float(ring["timer"]) <= 0.0:
			if _try_step(ring):
				ring["timer"] = maxf(float(ring["timer"]) + float(ring["beat"]), MOVE_TIME + 0.05)
			else:
				ring["timer"] = 0.2
				ring["jam"] = 1.0
		for a: Dictionary in ring["ast"]:
			if float(a["mt"]) < 1.0:
				a["mt"] = minf(float(a["mt"]) + delta / MOVE_TIME, 1.0)
				if float(a["mt"]) >= 1.0:
					_rebuild_occ()
			a["pop"] = maxf(float(a["pop"]) - delta * 3.0, 0.0)
			if not bool(a["alive"]):
				a["rubble"] = float(a["rubble"]) - delta
				if float(a["rubble"]) <= 0.0:
					var ok: bool = true
					for c: Vector2i in _ast_cells(ring, a):
						if not _cell_clear(c):
							ok = false
					if ok:
						_reform(ring, a)
			else:
				for c: Vector2i in _ast_cells(ring, a):
					if arena.flames.has(c):
						_shatter(a)
						break
			_pose_asteroid(ring, a, delta)
		_pose_planet(ring, delta)


## Moves every moon of [param ring] on by one cell, unless a pod or critter
## is in the way (the ring jams) or Pip is and cannot be bumped aside.
func _try_step(ring: Dictionary) -> bool:
	var tiles: Array = ring["tiles"]
	var n: int = tiles.size()
	var dir: int = ring["dir"]
	var targets: Dictionary = {}   # cell -> [from cell, to cell]
	for a: Dictionary in ring["ast"]:
		if not bool(a["alive"]):
			continue
		var nxt: int = (int(a["slot"]) + dir + n) % n
		targets[tiles[nxt]] = [tiles[int(a["slot"])], tiles[nxt]]
	for c: Vector2i in targets:
		if arena.pod_at.has(c) or _critter_on(c):
			return false
	if not arena.demo and arena.hero != null and arena.hero_alive and arena.state == &"play":
		var hit: Array = []
		for c: Vector2i in targets:
			if _hero_on(c, 0.8):
				hit = targets[c]
				break
		if not hit.is_empty():
			var spot: Vector2i = _push_spot(ring, targets, hit[1] - hit[0])
			if spot == Arena.NO_CELL:
				return false
			_start_push(spot)
	for a: Dictionary in ring["ast"]:
		a["from"] = a["slot"]
		a["slot"] = (int(a["slot"]) + dir + n) % n
		a["mt"] = 0.0
	_rebuild_occ()
	return true


## Where to bump Pip so he clears the cells the moons move into: the middle
## of his own tile if that is clear, else the next tile along the moon's
## path, else away from the planet, else any free neighbour.
func _push_spot(ring: Dictionary, targets: Dictionary, push: Vector2i) -> Vector2i:
	var hc: Vector2i = arena.hero_cell()
	var cands: Array[Vector2i] = []
	if not targets.has(hc) and not _hero_on_other(hc, targets):
		cands.append(hc)
	var p: Vector2i = ring["p"]
	var away := Vector2i(signi(hc.x - p.x), 0) if absi(hc.x - p.x) >= absi(hc.y - p.y) else Vector2i(0, signi(hc.y - p.y))
	for d: Vector2i in [push, away, Vector2i(push.y, push.x), Vector2i(-push.y, -push.x), -push]:
		if d != Vector2i.ZERO and not cands.has(hc + d):
			cands.append(hc + d)
	var danger: Dictionary = arena._danger_cells()
	for strict: bool in [true, false]:
		for c: Vector2i in cands:
			if _push_ok(c, targets) and (not strict or not danger.has(c)):
				return c
	return Arena.NO_CELL


func _hero_on_other(hc: Vector2i, targets: Dictionary) -> bool:
	# Pip's own tile is clear, but is he leaning into a target tile? Then
	# easing back onto his own tile clears it.
	return targets.has(hc)


func _push_ok(c: Vector2i, targets: Dictionary) -> bool:
	if arena.tile(c) != Arena.FLOOR or planets.has(c) or _occ.has(c) or targets.has(c):
		return false
	if arena.flames.has(c) or _critter_on(c):
		return false
	if arena.pod_at.has(c) and not arena.hero_pass.has(arena.pod_at[c]):
		return false
	return true


func _start_push(spot: Vector2i) -> void:
	var moved: bool = arena.hero_pos.distance_to(Vector2(spot)) > 0.3
	_push = {"from": arena.hero_pos, "to": Vector2(spot), "t": 0.0}
	if arena.walk_goal != Arena.NO_CELL and _occ.has(arena.walk_goal):
		arena.walk_goal = Arena.NO_CELL
	if moved:
		_sound(_player2, _snd_bonk, randf_range(0.95, 1.08))
		arena._spawn_sparkles(arena._to3(arena.hero_pos, 0.5), M.ROCK_LIGHT)
		var body: Node3D = arena.hero.get_node("Body")
		body.scale = Vector3(1.25, 0.8, 1.25)


func _update_push(delta: float) -> void:
	if _push.is_empty():
		return
	if arena.hero == null or not arena.hero_alive or arena.state != &"play":
		_push.clear()
		return
	_push["t"] = float(_push["t"]) + delta / PUSH_TIME
	var k: float = minf(float(_push["t"]), 1.0)
	var e: float = k * k * (3.0 - 2.0 * k)
	arena.hero_pos = (_push["from"] as Vector2).lerp(_push["to"], e)
	if k >= 1.0:
		_push.clear()


func _reform(ring: Dictionary, a: Dictionary) -> void:
	a["alive"] = true
	a["pop"] = 1.0
	var n: Node3D = a["node"]
	n.get_node("Body").visible = true
	n.get_node("Ghost").visible = false
	arena._spawn_sparkles(n.position + Vector3(0, 0.4, 0), M.ROCK_LIGHT.lightened(0.3))
	_sound(_player2, _snd_reform, randf_range(0.95, 1.1))
	_rebuild_occ()


func _pose_asteroid(ring: Dictionary, a: Dictionary, delta: float) -> void:
	var tiles: Array = ring["tiles"]
	var from: Vector2 = Vector2(tiles[int(a["from"])])
	var to: Vector2 = Vector2(tiles[int(a["slot"])])
	var k: float = float(a["mt"])
	var e: float = k * k * (3.0 - 2.0 * k)
	var p: Vector2 = from.lerp(to, e)
	var n: Node3D = a["node"]
	var prev: Vector3 = n.position
	n.position = Vector3(p.x, 0.0, p.y)
	var body: Node3D = n.get_node("Body")
	var rock: Node3D = body.get_node("Rock")
	var step: Vector3 = n.position - prev
	step.y = 0.0
	if step.length() > 0.0001 and step.length() < 0.5:
		rock.rotate(Vector3(step.z, 0, -step.x).normalized(), step.length() / 0.36)
	var jam: float = float(ring["jam"])
	body.position = Vector3(sin(_clock * 40.0) * 0.03 * jam, sin(k * PI) * 0.1, 0.0)
	var pop: float = float(a["pop"])
	body.scale = Vector3.ONE * M.AST_SIZE * (1.0 + sin(pop * PI) * 0.25)
	if not bool(a["alive"]):
		var ghost: Node3D = n.get_node("Ghost")
		(ghost.get_node("Pebbles") as Node3D).rotation.y += delta * 2.0
		var left: float = float(a["rubble"])
		# Flicker back in just before reforming.
		var warn: bool = left < REFORM_WARN
		body.visible = warn and fmod(_clock, 0.24) < 0.12
		if warn:
			body.scale = Vector3.ONE * lerpf(0.9, 0.55, clampf(left / REFORM_WARN, 0.0, 1.0))
		var gr: Node3D = ghost.get_node("GhostRing")
		var pulse: float = 1.0 + (sin(_clock * 12.0) * 0.12 if warn else 0.0)
		gr.scale = Vector3(pulse, 0.3, pulse)


func _pose_planet(ring: Dictionary, delta: float) -> void:
	var n: Node3D = ring["node"]
	var r: Node3D = n.get_node("Ring")
	var arrows: Node3D = r.get_node("Arrows")
	arrows.scale = Vector3(1, 1, float(ring["dir"]))
	var spin: Node3D = arrows.get_node("Spin")
	var flip: float = float(ring["flip"])
	spin.rotation.y -= delta * (0.9 + flip * 9.0)
	r.rotation.z = 0.12 + sin(flip * PI * 3.0) * 0.25 * flip
	var globe: Node3D = n.get_node("Globe")
	globe.rotation.y = sin(_clock * 0.8 + float(ring["p"].x)) * 0.25
	globe.position.y = 0.52 + sin(_clock * 2.0 + float(ring["p"].y)) * 0.02


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	_clock += delta
	_update_rings(delta)
	_update_push(delta)
	for t: Node3D in _dish_tips:
		t.scale = Vector3.ONE * (0.8 + 0.4 * absf(sin(_clock * 3.0 + t.get_instance_id() % 7)))
	for b: Node3D in _beacons:
		b.rotation.y += delta * 1.2
	if arena.demo:
		return
	_update_ufos(delta)
	_update_boss(delta)


# --- UFOs ----------------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"ufo":
			return M.ufo()
		&"boss":
			return M.whale()
	return null


func critter_speed(kind: StringName) -> float:
	if kind == &"ufo":
		return 1.95 + 0.09 * arena.level_id
	return 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func _charge_time() -> float:
	return 1.15 if arena.level_id <= 2 else 1.0


func _ufo_state(cr: Arena.Critter) -> Dictionary:
	if not _ufo.has(cr):
		_ufo[cr] = {"mode": &"cruise", "t": arena.rng.randf_range(2.5, 5.0), "aim": cr.cell, "cd": 0.2}
	return _ufo[cr]


func _beamable(c: Vector2i) -> bool:
	return arena.tile(c) == Arena.FLOOR and not blocks(c)


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"ufo":
		return Vector2i.ZERO
	var st: Dictionary = _ufo_state(cr)
	if st["mode"] != &"cruise":
		return Vector2i.ZERO
	var hc: Vector2i = arena.hero_cell() if not arena.demo else Vector2i(-99, -99)
	var gap: Vector2i = hc - cr.cell
	var inline: bool = (gap.x == 0) != (gap.y == 0)
	# Pip close and in line: turn to him and charge a beam.
	if not arena.demo and arena.hero_alive and inline and absi(gap.x) + absi(gap.y) <= 2 and float(st["cd"]) <= 0.0:
		var d := Vector2i(signi(gap.x), signi(gap.y))
		if _beamable(cr.cell + d):
			_start_charge(cr, st, d)
			return Vector2i.ZERO
	if float(st["t"]) <= 0.0 and _beamable(cr.cell + cr.dir):
		_start_charge(cr, st, cr.dir)
		return Vector2i.ZERO
	# Otherwise hover straight on, turning only when blocked (or to line up
	# with Pip now and then).
	var danger: Dictionary = arena._danger_cells()
	var open: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		var c: Vector2i = cr.cell + d
		if arena._critter_can_enter(cr, c) and not danger.has(c):
			open.append(d)
	if open.is_empty():
		return Vector2i.ZERO
	if not arena.demo and arena.hero_alive and inline and absi(gap.x) + absi(gap.y) <= 6:
		var toward := Vector2i(signi(gap.x), signi(gap.y))
		if open.has(toward) and arena.rng.randf() < 0.6:
			return toward
	if open.has(cr.dir):
		return cr.dir
	var turns: Array[Vector2i] = []
	for d: Vector2i in open:
		if d != -cr.dir:
			turns.append(d)
	if turns.is_empty():
		turns = open
	return turns[arena.rng.randi() % turns.size()]


func _start_charge(cr: Arena.Critter, st: Dictionary, d: Vector2i) -> void:
	st["mode"] = &"charge"
	st["t"] = _charge_time()
	st["aim"] = cr.cell + d
	cr.dir = d
	_sound(_player2, _snd_charge, randf_range(0.95, 1.05))


func _hold(cr: Arena.Critter, st: Dictionary) -> void:
	cr.target = cr.cell
	cr.t = 0.0
	cr.pos = Vector2(cr.cell)
	cr.dir = (st["aim"] as Vector2i) - cr.cell


func _update_ufos(delta: float) -> void:
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"ufo":
			_ufo_state(cr)
	for cr: Arena.Critter in _ufo.keys():
		if not arena.critters.has(cr):
			_ufo.erase(cr)
			continue
		var st: Dictionary = _ufo[cr]
		st["cd"] = float(st["cd"]) - delta
		match st["mode"]:
			&"cruise":
				st["t"] = float(st["t"]) - delta
			&"charge":
				_hold(cr, st)
				st["t"] = float(st["t"]) - delta
				if float(st["t"]) <= 0.0:
					st["mode"] = &"beam"
					st["t"] = BEAM_TIME
					_sound(_player2, _snd_zap, randf_range(0.95, 1.05))
			&"beam":
				_hold(cr, st)
				var aim: Vector2i = st["aim"]
				if arena.hero_alive and arena.hero != null and arena.hero_pos.distance_to(Vector2(aim)) < 0.6:
					arena._hurt_hero()
				st["t"] = float(st["t"]) - delta
				if float(st["t"]) <= 0.0:
					st["mode"] = &"cruise"
					st["t"] = arena.rng.randf_range(3.5, 6.0)
					st["cd"] = 2.2
					cr.t = 1.0


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"ufo":
			var st: Dictionary = _ufo_state(cr)
			var hover: Node3D = body.get_node("Hover")
			var mode: StringName = st["mode"]
			var mark: Node3D = cr.node.get_node("Mark")
			var beam: MeshInstance3D = cr.node.get_node("Beam")
			hover.position.y = 0.5 + sin(t * 2.6) * 0.06
			var lights: Node3D = hover.get_node("Lights")
			lights.rotation.y += delta * (2.0 if mode == &"cruise" else 9.0)
			var tilt: float = 0.0
			mark.visible = mode != &"cruise"
			beam.visible = mode == &"beam"
			if mode == &"charge":
				tilt = 0.28
				var k: float = 1.0 - clampf(float(st["t"]) / _charge_time(), 0.0, 1.0)
				var pulse: float = 0.75 + 0.25 * sin(t * (10.0 + k * 20.0))
				mark.scale = Vector3.ONE * (0.55 + 0.45 * k) * pulse
				(hover.get_node("Glow") as Node3D).scale = Vector3.ONE * (1.0 + k * 1.2)
			elif mode == &"beam":
				tilt = 0.32
				mark.scale = Vector3.ONE * (1.05 + sin(t * 40.0) * 0.05)
				var top := Vector3(0, 0.5 * M.UFO_SIZE, 0.12)
				var bottom := Vector3(0, 0.02, 1.0)
				var axis: Vector3 = top - bottom
				var y_axis: Vector3 = axis
				var x_axis := Vector3(1, 0, 0) * (1.0 + sin(t * 50.0) * 0.08)
				var z_axis: Vector3 = x_axis.cross(y_axis).normalized() * (1.0 + sin(t * 50.0) * 0.08)
				beam.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (top + bottom) * 0.5)
			else:
				(hover.get_node("Glow") as Node3D).scale = Vector3.ONE
			hover.rotation.x = lerpf(hover.rotation.x, tilt if mode != &"cruise" else (0.1 if cr.t < 1.0 else 0.0), minf(delta * 8.0, 1.0))
			var pilot: Node3D = hover.get_node("Pilot")
			pilot.rotation.y = sin(t * 1.3) * 0.5 if mode == &"cruise" else 0.0
			return Vector3.ONE * M.UFO_SIZE
		&"boss":
			var tail: Node3D = body.get_node("Tail")
			tail.rotation.x = sin(t * 3.0) * 0.3
			var flap: float = sin(t * 4.0) * 0.4
			(body.get_node("FinL") as Node3D).rotation.z = flap
			(body.get_node("FinR") as Node3D).rotation.z = -flap
			var spout: Node3D = body.get_node("Spout")
			spout.scale = Vector3.ONE * (0.9 + 0.2 * absf(sin(t * 5.0)))
			spout.rotation.y += delta * 2.0
			return Vector3(1.0, 1.0 + absf(sin(t * 2.4)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- The Moon Whale ------------------------------------------------------------------

const BOSS_SLOTS: Array = [[1, 5], [1, 3, 5], [1, 3, 5, 7]]
const BOSS_BEATS: Array[float] = [1.15, 1.0, 0.75]


func _boss_offsets() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Vector2i in ring_cells(Vector2i.ZERO, 1):
		out.append(c)
	return out


func _update_boss(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		if not _boss_orb.is_empty():
			for o: Dictionary in _boss_orb:
				if bool(o["alive"]):
					_burst((o["node"] as Node3D).position + Vector3(0, 0.4, 0), M.ROCK)
				(o["node"] as Node3D).queue_free()
			_boss_orb.clear()
		return
	var phase: int = 0 if b.hp > 6 else (1 if b.hp > 3 else 2)
	if phase != _boss_phase:
		_boss_phase = phase
		_build_boss_orbs(b, BOSS_SLOTS[phase])
	if _boss_hp >= 0 and b.hp < _boss_hp:
		# Hit: the moons flip round and hurry for a moment.
		_boss_dir = -_boss_dir
		_boss_timer = minf(_boss_timer, 0.3)
		_sound(_player, _snd_flip, 0.8)
	_boss_hp = b.hp
	var offs: Array[Vector2i] = _boss_offsets()
	_boss_timer -= delta
	if _boss_timer <= 0.0:
		_boss_timer = BOSS_BEATS[phase]
		for o: Dictionary in _boss_orb:
			o["from"] = o["slot"]
			o["slot"] = (int(o["slot"]) + _boss_dir + 8) % 8
			o["mt"] = 0.0
	for o: Dictionary in _boss_orb:
		o["mt"] = minf(float(o["mt"]) + delta / MOVE_TIME, 1.0)
		var k: float = float(o["mt"])
		var e: float = k * k * (3.0 - 2.0 * k)
		var off: Vector2 = Vector2(offs[int(o["from"])]).lerp(Vector2(offs[int(o["slot"])]), e)
		var p: Vector2 = b.pos + off
		o["cell"] = Vector2i(roundi(p.x), roundi(p.y))
		var n: Node3D = o["node"]
		var prev: Vector3 = n.position
		n.position = Vector3(p.x, 0.0, p.y)
		var body: Node3D = n.get_node("Body")
		var step: Vector3 = n.position - prev
		if step.length() > 0.0001 and step.length() < 0.5:
			(body.get_node("Rock") as Node3D).rotate(Vector3(step.z, 0, -step.x).normalized(), step.length() / 0.36)
		body.position.y = 0.15 + sin(_clock * 3.0 + float(o["slot"])) * 0.05
		o["pop"] = maxf(float(o["pop"]) - delta * 3.0, 0.0)
		body.scale = Vector3.ONE * 0.9 * (1.0 + sin(float(o["pop"]) * PI) * 0.3)
		if bool(o["alive"]):
			if arena.flames.has(o["cell"]):
				_shatter_boss_orb(o)
		else:
			o["rubble"] = float(o["rubble"]) - delta
			var left: float = float(o["rubble"])
			body.visible = left < REFORM_WARN and fmod(_clock, 0.24) < 0.12
			(n.get_node("Ghost/Pebbles") as Node3D).rotation.y += delta * 2.0
			if left <= 0.0:
				o["alive"] = true
				o["pop"] = 1.0
				body.visible = true
				n.get_node("Ghost").visible = false
				_sound(_player2, _snd_reform, 1.1)


func _build_boss_orbs(b: Arena.Critter, slots: Array) -> void:
	for o: Dictionary in _boss_orb:
		(o["node"] as Node3D).queue_free()
	_boss_orb.clear()
	var r := RandomNumberGenerator.new()
	r.seed = 909 + _boss_phase
	for s: Variant in slots:
		var n: Node3D = M.asteroid(r)
		(n.get_node("Shadow") as Node3D).scale = Vector3.ONE * 0.8
		arena.add_child(n)
		var o := {"slot": int(s), "from": int(s), "mt": 1.0, "alive": true, "rubble": 0.0, "pop": 1.0, "node": n, "cell": b.cell}
		_boss_orb.append(o)
		arena._spawn_sparkles(Vector3(b.pos.x, 0.5, b.pos.y), M.ROCK_LIGHT)


func _boss_orb_at(c: Vector2i) -> Variant:
	for o: Dictionary in _boss_orb:
		if bool(o["alive"]) and o.get("cell", Arena.NO_CELL) == c:
			return o
	return null


func _shatter_boss_orb(o: Dictionary) -> void:
	if not bool(o["alive"]):
		return
	o["alive"] = false
	o["rubble"] = BOSS_REFORM
	var n: Node3D = o["node"]
	_burst(n.position + Vector3(0, 0.4, 0), M.ROCK)
	n.get_node("Body").visible = false
	n.get_node("Ghost").visible = true


# --- Sound --------------------------------------------------------------------------

func _sound(p: AudioStreamPlayer, s: AudioStreamWAV, pitch: float) -> void:
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


## A swirling "wheee-ooo" sweep: the spin switch flips.
func _make_flip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 520.0 + 520.0 * sin(minf(t / 0.5, 1.0) * PI) + 30.0 * sin(TAU * 14.0 * t)
		ph += TAU * f / rate
		var env: float = minf(t / 0.02, 1.0) * minf((0.5 - t) / 0.15, 1.0)
		out[i] = (sin(ph) * 0.6 + sin(ph * 2.0) * 0.15) * env * 0.4
	return _wav(out)


## A soft rubbery "boing" when a moon bumps Pip aside.
func _make_bonk() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 210.0 + 140.0 * exp(-t * 18.0) + 25.0 * sin(TAU * 22.0 * t) * exp(-t * 6.0)
		ph += TAU * f / rate
		out[i] = sin(ph) * minf(t / 0.004, 1.0) * exp(-t * 9.0) * 0.55
	return _wav(out)


## A rising wobbly hum: a saucer is charging its beam.
func _make_charge() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 300.0 + 500.0 * t + 40.0 * sin(TAU * 11.0 * t)
		ph += TAU * f / rate
		var env: float = minf(t / 0.1, 1.0) * minf((1.0 - t) / 0.08, 1.0)
		out[i] = (sin(ph) * 0.5 + sin(ph * 1.5) * 0.2) * env * 0.22
	return _wav(out)


## A bright fizzing "pshhew" for the beam.
func _make_zap() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	var r := RandomNumberGenerator.new()
	r.seed = 22
	for i in n:
		var t: float = i / rate
		var f: float = 1300.0 - 700.0 * t
		ph += TAU * f / rate
		var env: float = minf(t / 0.01, 1.0) * exp(-t * 4.5)
		out[i] = (sin(ph) * 0.4 + (1.0 if sin(ph * 0.5) > 0.0 else -1.0) * 0.12 + r.randf_range(-1.0, 1.0) * 0.12) * env * 0.4
	return _wav(out)


## Three twinkling bell notes: a moon reforms.
func _make_reform() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for note: Array in [[0.0, 1318.5], [0.07, 1568.0], [0.14, 2093.0]]:
			var tt: float = t - float(note[0])
			if tt < 0.0:
				continue
			var fr: float = note[1]
			v += (sin(TAU * fr * tt) + 0.3 * sin(TAU * fr * 2.76 * tt) * exp(-tt * 10.0)) * exp(-tt * 9.0) * minf(tt / 0.003, 1.0)
		out[i] = v * 0.2
	return _wav(out)

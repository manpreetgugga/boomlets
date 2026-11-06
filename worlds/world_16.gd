extends WorldKit
## World 16, Inkwell Library: a cosy magical library of bookshelf walls,
## green reading lamps and ink-blue carpet. The twist is push-blocks: heavy
## book stacks (H) that Pip shoves one tile by walking into them (or by
## tapping them), as long as the tile beyond is clear floor. Blasts stop at
## book stacks, so they make handy shields and can pen critters into a blast
## lane. Bookmark plates (m, n) open every shelf-door of their colour (D, G)
## while book stacks sit on all of them. An ink reset pad (R) sends every
## stack back to where it started, so no shove can ever lock Pip out.
## Bookworms tunnel under book stacks and nap in there out of reach: shove
## the stack off one to catch it blinking in the light. Professor Inkle, the
## ink-octopus librarian, lobs ink that leaves sticky puddles on the floor.
##
## Extra map characters:
##   H  book stack            R  ink reset pad          k  Bookworm
##   m  red bookmark plate    D  red shelf-door
##   n  green bookmark plate  G  green shelf-door

const M := preload("res://worlds/world_16_models.gd")

const NO_CELL := Vector2i(-99, -99)
const PUSH_TIME: float = 0.16
## How long Pip has to lean on a stack before it moves.
const PUSH_HOLD: float = 0.07
const WORM_SPEED: float = 1.75
const WORM_NAP_MIN: float = 1.0
const WORM_NAP_MAX: float = 2.4
const WORM_DAZE: float = 1.5
const DOOR_SINK: float = -0.78
## Professor Inkle's ink.
const INK_EVERY: float = 5.0
const INK_EVERY_HURT: float = 3.4
const INK_HURT_HP: int = 4
const INK_FLIGHT: float = 1.05
const INK_LIFE: float = 6.5
const INK_SLOW: float = 0.5

const PALETTE: Dictionary = {
	"GRASS_A": "#EAD6B0", "GRASS_B": "#DCC39A", "RIM": "#3F4F9A", "EDGE": "#7B4A2E",
	"STONE": "#C9A27A", "DARK_STONE": "#8A5634", "DIRT": "#6B4630", "ROCK": "#34407A",
	"WOOD": "#9DB7F0", "WOOD_DARK": "#3D55A8", "BARREL": "#E8475B", "BELT": "#4A3B5C", "ACCENT": "#E8B64C",
	"BLOSSOM_A": "#4A9C55", "BLOSSOM_B": "#3E8A4C", "TRUNK": "#6A3F25", "LEAFY_A": "#5DB060", "LEAFY_B": "#4A9C55",
	"SKY_TOP": "#26336E", "SKY_HORIZON": "#F2CF94", "SKY_GROUND": "#2B356B", "CLOUD": "#5D69A8", "CLOUDS": 0.35,
	"AMBIENT": "#DCCAB2", "AMBIENT_ENERGY": 0.62, "SUN": "#FFE8C6", "SUN_ENERGY": 1.42,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Shelf Shove",
		"tip": "Walk into a book stack (or tap it)\nto shove it. Push it onto the red\nbookmark to open the shelf-door!",
		"crates": 0.36, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.k...b...k.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#####D#######",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#...._Hm....#",
			"#.#.#_#_#.#.#",
			"#R..._S_....#",
			"#############",
		],
	},
	{
		"name": "Two Bookmarks",
		"tip": "Both bookmarks need a stack.\nBookworms nap inside stacks:\nshove one off to catch them!",
		"crates": 0.38, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#...#.E.#...#",
			"#.#.#...#.#.#",
			"#.k.##D##.k.#",
			"#.#.......#.#",
			"#..H.....H..#",
			"#.#.#.#.#.#.#",
			"#..m.....m..#",
			"#.#.#.#.#.#.#",
			"#.k...b...k.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#R..._S_....#",
			"#############",
		],
	},
	{
		"name": "Quiet, Please!",
		"tip": "Buzzers chase! Book stacks stop\nblasts, so duck behind one\nwhen the barrels go up.",
		"crates": 0.36, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#z....E....z#",
			"#.#.#.#.#.#.#",
			"#..B.....B..#",
			"#.#.#.#.#.#.#",
			"#.....k.....#",
			"#######D#####",
			"#...........#",
			"#.#H#.#.#.#.#",
			"#k....H..m..#",
			"#.#.#.#.#.#.#",
			"#...m.....k.#",
			"#.#.#_#_#.#.#",
			"#R..._S_..B.#",
			"#############",
		],
	},
	{
		"name": "Stacks and Stairs",
		"tip": "The green bookmark opens the\nway to the red one. Pen the\ncritters in with stacks, then pop!",
		"crates": 0.36, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.k...E...k.#",
			"#.#.#.#.#.#.#",
			"#...z...z...#",
			"#####D#######",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b..H...m..#",
			"#.#.#.#.#.#.#",
			"#.....k.....#",
			"#######G#####",
			"#..b....H.n.#",
			"#.#.#_#_#.#.#",
			"#R..._S_..k.#",
			"#############",
		],
	},
	{
		"name": "Midnight Stacks",
		"tip": "Each bookmark opens the door\non the other side. Warp across,\nshove, and warp back!",
		"crates": 0.38, "par": 115,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#..k..E..k..#",
			"#.#.#.#.#.#.#",
			"#.z.......z.#",
			"###D#####G###",
			"#.....#.....#",
			"#.#.#.#.#.#.#",
			"#.H.n.#.m.H.#",
			"#.#.#.#.#.#.#",
			"#..k..#..b..#",
			"#.#.#.#.#.#.#",
			"#..b..#..k..#",
			"#.#.#_#_#.#.#",
			"#1R._S#_.R1.#",
			"#############",
		],
	},
	{
		"name": "Professor Inkle",
		"tip": "Professor Inkle lobs sticky ink!\nWatch for the dark rings and\nhide behind stacks. Eight hits!",
		"crates": 0.16, "par": 135, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...H...H...#",
			"#.#.......#.#",
			"#.....K.....#",
			"#.#..#.#..#.#",
			"#...........#",
			"#.#..#.#..#.#",
			"#...H...H...#",
			"#.#.......#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#R..._S_....#",
			"#############",
		],
	},
]

const GROUP_COLORS: Array[Color] = [M.RIBBON_A, M.RIBBON_B]

## Vector2i -> {"node", "home", "from", "anim", "hop", "bump"}.
var stacks: Dictionary = {}
## Vector2i -> {"group", "node", "on"}.
var plates: Dictionary = {}
## Vector2i -> {"group", "node", "open", "y"}.
var doors: Dictionary = {}
## Vector2i -> {"node", "pulse"}.
var resets: Dictionary = {}
var group_open: Array[bool] = [false, false]
## Ink puddles: Vector2i -> {"node", "t"}.
var puddles: Dictionary = {}

var _clock: float = 0.0
var _worms: Dictionary = {}       # Critter -> {"nap", "daze", "slept": Vector2i}
var _balls: Array[Dictionary] = []
var _ink_t: float = INK_EVERY
var _push_hold: float = 0.0
var _plan: Dictionary = {}        # {"stack", "dir", "spot", "t"}
var _seen_tap: int = 0
var _stuck_check: float = -1.0
var _rng := RandomNumberGenerator.new()
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_thump: AudioStreamWAV
var _snd_splat: AudioStreamWAV
var _snd_reset: AudioStreamWAV
var _snd_click: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Inkwell Library"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_16.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "PROFESSOR INKLE"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"bookworm"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"H":
			stacks[c] = {"home": c, "from": c, "anim": 1.0, "hop": 0.0, "bump": 0.0}
			return true
		"m", "n":
			plates[c] = {"group": 0 if ch == "m" else 1, "on": false}
			return true
		"D", "G":
			doors[c] = {"group": 0 if ch == "D" else 1, "open": false, "y": 0.0}
			return true
		"R":
			resets[c] = {"pulse": 0.0}
			return true
	return false


func critter_chars() -> Dictionary:
	return {"k": &"bookworm"}


func build_extra() -> void:
	_rng.seed = hash(String(arena.data["name"])) + 16
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 61
	for c: Vector2i in stacks:
		var n: Node3D = M.book_stack(r)
		n.position = Vector3(c.x, 0, c.y)
		n.rotation.y = r.randf_range(-0.12, 0.12)
		arena.add_child(n)
		stacks[c]["node"] = n
	for c: Vector2i in plates:
		var n: Node3D = M.plate(GROUP_COLORS[int(plates[c]["group"])])
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		plates[c]["node"] = n
	for c: Vector2i in doors:
		var n: Node3D = M.door(GROUP_COLORS[int(doors[c]["group"])], r)
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		doors[c]["node"] = n
	for c: Vector2i in resets:
		var n: Node3D = M.reset_pad()
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		resets[c]["node"] = n
	# A warm grout under the floor boards (the gaps would show the blue carpet).
	var under := Models.part(arena, Models.box_mesh(Vector3(Arena.W - 1.9, 0.1, Arena.H - 1.9), 0.02), Color("#B48F62"), Vector3((Arena.W - 1) * 0.5, -0.06, (Arena.H - 1) * 0.5))
	under.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_update_plates(true)
	if not arena.demo:
		var hud: Variant = _hud()
		if hud != null:
			_seen_tap = int(hud.get("_last_tap_ms"))
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -6.0
	arena.add_child(_player2)
	_snd_thump = _make_thump()
	_snd_splat = _make_splat()
	_snd_reset = _make_reset()
	_snd_click = _make_click()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Rows of books standing on top of the shelf walls, brass bookends and a
	# candle here and there. The near wall gets low lying books only, so it
	# never hides the bottom row.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var lists: Array = []
	for i in M.COVERS.size():
		lists.append([])
	var pages: Array[Transform3D] = []
	var ends: Array[Transform3D] = []
	var candles: Array[Transform3D] = []
	var flames: Array[Transform3D] = []
	var top: float = 0.69
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var along_x: bool = z == 0 or z == h - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		var base := Vector3(x, top, z)
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if z == h - 1:
			# Lying books.
			var y: float = 0.0
			for k in r.randi_range(1, 2):
				var bh: float = r.randf_range(0.07, 0.09)
				var b := Basis(Vector3.UP, r.randf_range(-0.3, 0.3)).scaled(Vector3(r.randf_range(0.9, 1.1), 1.0, 1.0))
				(lists[r.randi() % lists.size()] as Array).append(Transform3D(b.scaled(Vector3(1, bh / 0.08, 1)), base + Vector3(r.randf_range(-0.1, 0.1), y + bh * 0.5, 0)))
				y += bh
			continue
		if corner:
			candles.append(Transform3D(Basis(), base + Vector3(0, 0.1, 0)))
			flames.append(Transform3D(Basis(), base + Vector3(0, 0.25, 0)))
			continue
		var s: float = -0.42
		while s < 0.38:
			var bw: float = r.randf_range(0.1, 0.16)
			var bh2: float = r.randf_range(0.24, 0.36)
			var lean: float = 0.0
			if r.randf() < 0.08:
				lean = r.randf_range(-0.3, 0.3)
			var at: Vector3 = base + turn * Vector3(s + bw * 0.5, bh2 * 0.5, 0)
			var bb := turn * Basis(Vector3.BACK, lean)
			var sc := Basis().scaled(Vector3(bw / 0.12, bh2 / 0.3, 1.0))
			(lists[r.randi() % lists.size()] as Array).append(Transform3D(bb * sc, at))
			pages.append(Transform3D(bb * Basis().scaled(Vector3(bw / 0.12, 1.0, 1.0)), at + Vector3(0, bh2 * 0.5 - 0.01, 0)))
			s += bw + 0.01
			if r.randf() < 0.06 and s < 0.2:
				ends.append(Transform3D(turn, base + turn * Vector3(s + 0.03, 0.12, 0)))
				s += 0.08
	var spine := Models.box_mesh(Vector3(0.12, 0.3, 0.5), 0.025)
	var flat := Models.box_mesh(Vector3(0.5, 0.08, 0.36), 0.02)
	for i in lists.size():
		var arr: Array[Transform3D] = []
		var arr_flat: Array[Transform3D] = []
		for tf2: Transform3D in lists[i]:
			if tf2.origin.z > h - 1.5:
				arr_flat.append(tf2)
			else:
				arr.append(tf2)
		if not arr.is_empty():
			arena._multimesh(spine, M.COVERS[i], arr)
		if not arr_flat.is_empty():
			arena._multimesh(flat, M.COVERS[i], arr_flat)
	if not pages.is_empty():
		arena._multimesh(Models.box_mesh(Vector3(0.09, 0.02, 0.44), 0.006), M.PAGES, pages)
	if not ends.is_empty():
		arena._multimesh(Models.box_mesh(Vector3(0.05, 0.24, 0.4), 0.02), M.BRASS, ends)
	if not candles.is_empty():
		arena._multimesh(Models.cylinder(0.06, 0.06, 0.2, 10), M.PAGES, candles)
		arena._multimesh(Models.sphere(0.045, 0.09, 8), M.LAMP_GLOW, flames, Models.mat(M.LAMP_GLOW, 3.0))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Little bookcases seen from above: a wooden case with a lighter rim, two
	# rows of books standing in its open top (colourful spines with cream page
	# edges, so it reads as books from high up), wooden bookends at the sides,
	# a row of spines on the front and now and then a candle.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var cases: Array[Transform3D] = []
	var trims: Array[Transform3D] = []
	var ends: Array[Transform3D] = []
	var pages: Array[Transform3D] = []
	var lists: Array = []
	for i in M.COVERS.size():
		lists.append([])
	var fronts: Array = []
	for i in M.COVERS.size():
		fronts.append([])
	var candles: Array[Transform3D] = []
	var flames: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		cases.append(Transform3D(Basis(), p + Vector3(0, 0.26, 0)))
		trims.append(Transform3D(Basis(), p + Vector3(0, 0.53, 0)))
		for sx: float in [-0.4, 0.4]:
			ends.append(Transform3D(Basis(), p + Vector3(sx, 0.68, 0)))
		var candle_row: int = r.randi() % 2 if r.randf() < 0.2 else -1
		for row in 2:
			var z: float = -0.19 + row * 0.38
			var x: float = -0.35
			var stop: float = 0.33
			if row == candle_row:
				stop = 0.12
				var cp := p + Vector3(0.24, 0.56, z)
				candles.append(Transform3D(Basis(), cp + Vector3(0, 0.08, 0)))
				flames.append(Transform3D(Basis(), cp + Vector3(0, 0.21, 0)))
			while x < stop:
				var bw: float = r.randf_range(0.085, 0.13)
				var bh: float = r.randf_range(0.2, 0.3)
				var lean: float = r.randf_range(-0.25, 0.25) if r.randf() < 0.1 else 0.0
				var bb := Basis(Vector3.BACK, lean)
				var at := p + Vector3(x + bw * 0.5, 0.56 + bh * 0.5, z)
				(lists[r.randi() % lists.size()] as Array).append(Transform3D(bb * Basis().scaled(Vector3(bw / 0.1, bh / 0.25, 1.0)), at))
				pages.append(Transform3D(bb * Basis().scaled(Vector3(bw / 0.1, 1.0, 1.0)), at + bb * Vector3(0, bh * 0.5 + 0.004, 0)))
				x += bw + 0.008
		# Spines along the front of the case.
		var fx: float = -0.36
		while fx < 0.32:
			var fw: float = r.randf_range(0.08, 0.12)
			var fh: float = r.randf_range(0.3, 0.38)
			(fronts[r.randi() % fronts.size()] as Array).append(Transform3D(Basis().scaled(Vector3(fw / 0.1, fh / 0.34, 1.0)), p + Vector3(fx + fw * 0.5, 0.06 + fh * 0.5, 0.42)))
			fx += fw + 0.012
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.52, 0.84), 0.06), M.WOOD, cases)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.06, 0.9), 0.025), M.WOOD_LIGHT, trims)
	arena._multimesh(Models.box_mesh(Vector3(0.06, 0.34, 0.84), 0.02), M.WOOD_LIGHT, ends)
	var spine := Models.box_mesh(Vector3(0.1, 0.25, 0.32), 0.016)
	var front := Models.box_mesh(Vector3(0.1, 0.34, 0.06), 0.014)
	for i in lists.size():
		var arr: Array[Transform3D] = []
		arr.assign(lists[i])
		if not arr.is_empty():
			arena._multimesh(spine, M.COVERS[i], arr)
		var arr2: Array[Transform3D] = []
		arr2.assign(fronts[i])
		if not arr2.is_empty():
			arena._multimesh(front, M.COVERS[i], arr2)
	arena._multimesh(Models.box_mesh(Vector3(0.075, 0.012, 0.28), 0.004), M.PAGES, pages)
	if not candles.is_empty():
		arena._multimesh(Models.cylinder(0.05, 0.05, 0.16, 10), M.PAGES, candles)
		arena._multimesh(Models.sphere(0.04, 0.08, 8), M.LAMP_GLOW, flames, Models.mat(M.LAMP_GLOW, 3.0))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.22:
			node = M.book_pile(r)
		elif roll < 0.3:
			node = M.candle()
		elif roll < 0.36:
			node = M.fern(r)
	elif p.z < 0.0:
		if roll < 0.42:
			node = M.bookcase(r, 3 if r.randf() < 0.6 else 2)
		elif roll < 0.54:
			node = M.reading_lamp()
		elif roll < 0.64:
			node = M.globe()
		elif roll < 0.74:
			node = M.armchair(M.COVERS[r.randi() % M.COVERS.size()].darkened(0.1))
		elif roll < 0.84:
			node = M.fern(r)
	else:
		if roll < 0.16:
			node = M.reading_lamp()
		elif roll < 0.28:
			node = M.book_pile(r)
		elif roll < 0.38:
			node = M.globe()
		elif roll < 0.48:
			node = M.fern(r)
		elif roll < 0.54:
			node = M.candle()
		if node != null and p.x < 0.0 and r.randf() < 0.5:
			node.rotation.y = PI * 0.5
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
		if p.z < 0.0:
			node.position.z = r.randf_range(-0.1, 0.05)
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var bc := M.bookcase(r, 4)
	bc.scale = Vector3.ONE * 1.3
	bc.position = Vector3(-size * 0.1, 0, -size * 0.2)
	root.add_child(bc)
	var lamp := M.reading_lamp()
	lamp.position = Vector3(size * 0.3, 0, size * 0.15)
	root.add_child(lamp)
	var pile := M.book_pile(r)
	pile.position = Vector3(-size * 0.25, 0, size * 0.25)
	root.add_child(pile)
	if r.randf() < 0.5:
		var g := M.globe()
		g.position = Vector3(size * 0.05, 0, size * 0.3)
		root.add_child(g)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFE4BE")
	env.glow_intensity = 0.6
	env.adjustment_saturation = 1.08


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	if stacks.has(c):
		return true
	return doors.has(c) and not bool(doors[c]["open"])


func flame_stop(c: Vector2i) -> int:
	if stacks.has(c):
		return 2
	if doors.has(c) and not bool(doors[c]["open"]):
		return 2
	return 0


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if doors.has(c) and not bool(doors[c]["open"]):
		return false
	if stacks.has(c):
		return cr.kind == &"bookworm"
	return true


func hero_speed_scale(c: Vector2i) -> float:
	return INK_SLOW if puddles.has(c) else 1.0


func on_hero_enter(c: Vector2i) -> void:
	if resets.has(c):
		_reset_stacks(c)


func process(delta: float) -> void:
	_clock += delta
	_animate(delta)
	if arena.demo:
		return
	_drive_taps()
	_drive_keys(delta)
	_drive_plan(delta)
	_update_worms(delta)
	_update_plates(false)
	_update_doors()
	_update_ink(delta)
	if _stuck_check >= 0.0:
		_stuck_check -= delta
		if _stuck_check < 0.0 and _cut_off():
			# Safety net: Pip has shut himself away from every reset pad and the
			# exit, so the ink pad calls the stacks home by itself.
			arena._spawn_ring(arena._to3(arena.hero_pos, 0.1), M.INK_LIGHT, 1.6)
			_reset_stacks(resets.keys()[0])


# --- Pushing ------------------------------------------------------------------------

func _hud() -> Variant:
	var main: Node = arena.get_parent()
	if main == null:
		return null
	return main.get("hud")


## A fresh tap on a book stack plans a shove: Pip walks to the tile behind it
## (on the side that sends it somewhere free) and pushes it away from him.
func _drive_taps() -> void:
	var hud: Variant = _hud()
	if hud == null or not is_instance_valid(hud):
		return
	var ms: int = int(hud.get("_last_tap_ms"))
	if ms == _seen_tap:
		return
	_seen_tap = ms
	_plan = {}
	if ms <= 0:
		return
	var tc: Vector2i = arena.cell_at_screen(hud.get("_last_tap_pos"))
	if not stacks.has(tc):
		return
	var dist: Dictionary = arena._hero_search(false, true)["dist"]
	var best_d := Vector2i.ZERO
	var best: int = 1 << 30
	var off: Vector2 = Vector2(tc) - arena.hero_pos
	for d: Vector2i in Arena.DIRS:
		var spot: Vector2i = tc - d
		if not dist.has(spot) or not _stack_can_enter(tc + d):
			continue
		# Shortest walk first; on a tie, the push that points away from Pip.
		var score: int = int(dist[spot]) * 10 - int(Vector2(d).dot(off.normalized()) * 4.0)
		if score < best:
			best = score
			best_d = d
	if best_d == Vector2i.ZERO:
		stacks[tc]["bump"] = 1.0
		return
	_plan = {"stack": tc, "dir": best_d, "spot": tc - best_d, "t": 0.0}
	arena.set_walk_goal(tc - best_d)


func _drive_plan(delta: float) -> void:
	if _plan.is_empty():
		return
	_plan["t"] = float(_plan["t"]) + delta
	var spot: Vector2i = _plan["spot"]
	var s: Vector2i = _plan["stack"]
	if arena.state != &"play" or arena.input_primary != Vector2i.ZERO or float(_plan["t"]) > 12.0 or not stacks.has(s) or (arena.walk_goal != spot and arena.walk_goal != Arena.NO_CELL):
		_plan = {}
		return
	if arena.hero_cell() != spot or arena.hero_pos.distance_to(Vector2(spot)) > 0.12:
		if arena.walk_goal == Arena.NO_CELL:
			arena.set_walk_goal(spot)
		return
	var d: Vector2i = _plan["dir"]
	if _push(s, d):
		_plan = {}
		# Follow the stack so a second tap shoves it again.
		arena.set_walk_goal(s)


## Pip leans on a stack with the keys or the pad.
func _drive_keys(delta: float) -> void:
	var d: Vector2i = arena.input_primary
	if d == Vector2i.ZERO or arena.state != &"play" or not arena.hero_alive:
		_push_hold = minf(_push_hold + delta, 0.0)
		return
	var hc: Vector2i = arena.hero_cell()
	var s: Vector2i = hc + d
	if not stacks.has(s):
		_push_hold = minf(_push_hold + delta, 0.0)
		return
	var off: Vector2 = arena.hero_pos - Vector2(hc)
	if absf(off.x) > 0.14 or absf(off.y) > 0.14:
		return
	_push_hold += delta
	if _push_hold >= PUSH_HOLD:
		if _push(s, d):
			_push_hold = -0.12
		else:
			_push_hold = -0.45


## Whether a stack may be shoved onto [param c]: plain clear floor only.
func _stack_can_enter(c: Vector2i) -> bool:
	if c.x <= 0 or c.y <= 0 or c.x >= Arena.W - 1 or c.y >= Arena.H - 1:
		return false
	if arena.tile(c) != Arena.FLOOR or stacks.has(c) or doors.has(c) or resets.has(c):
		return false
	if c == arena.exit_cell or arena.warps.has(c) or arena.belts.has(c) or arena.pickups.has(c) or arena.pod_at.has(c):
		return false
	return not _occupied(c)


## Pip, a critter or a pod is on (or stepping onto) [param c].
func _occupied(c: Vector2i) -> bool:
	if arena.pod_at.has(c):
		return true
	if not arena.demo and arena.hero != null and arena.state != &"dying":
		if absf(arena.hero_pos.x - c.x) < 0.9 and absf(arena.hero_pos.y - c.y) < 0.9:
			return true
	for cr: Arena.Critter in arena.critters:
		if cr.cell == c or cr.target == c or Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			return true
	return false


func _push(s: Vector2i, d: Vector2i) -> bool:
	var to: Vector2i = s + d
	if not stacks.has(s):
		return false
	if not _stack_can_enter(to):
		stacks[s]["bump"] = 1.0
		_sound(_snd_thump, 1.5, 0.35)
		return false
	var st: Dictionary = stacks[s]
	stacks.erase(s)
	st["from"] = s
	st["anim"] = 0.0
	st["hop"] = 0.0
	stacks[to] = st
	# A worm napping underneath is left blinking in the open.
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"bookworm" and Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == s:
			var w: Dictionary = _worm(cr)
			w["nap"] = 0.0
			w["daze"] = WORM_DAZE
			w["slept"] = s
			arena._spawn_sparkles(Vector3(s.x, 0.6, s.y), Color("#FFF3B0"))
	for k in 3:
		var a: float = atan2(-float(d.y), -float(d.x)) + (k - 1) * 0.6
		var dust := Models.part(arena, arena._smoke_mesh, M.PARCHMENT, Vector3(s.x - d.x * 0.3, 0.12, s.y - d.y * 0.3))
		dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena._fx.append({"node": dust, "t": 0.0, "life": 0.45, "kind": &"dust", "vel": Vector3(cos(a) * 1.4, 0.4, -sin(a) * 1.4)})
	_sound(_snd_thump, 1.0)
	Save.buzz(15)
	_stuck_check = 0.6
	return true


## True when Pip can reach neither a reset pad nor the exit (crates and
## barrels count as open, since he can blast them).
func _cut_off() -> bool:
	if resets.is_empty() or arena.state != &"play" or not arena.hero_alive:
		return false
	var start: Vector2i = arena.hero_cell()
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		if resets.has(c) or c == arena.exit_cell:
			return false
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = c + d
			if seen.has(n) or arena.tile(n) == Arena.WALL or blocks(n):
				continue
			seen[n] = true
			queue.append(n)
			if arena.warps.has(n) and not seen.has(arena.warps[n]):
				seen[arena.warps[n]] = true
				queue.append(arena.warps[n])
	return true


## Sends every stack home (those whose home is clear) with a hop.
func _reset_stacks(pad: Vector2i) -> void:
	var want: Dictionary = {}
	var moved: bool = false
	for c: Vector2i in stacks:
		var home: Vector2i = stacks[c]["home"]
		want[c] = home
		if home != c:
			moved = true
	if not moved:
		return
	# Stacks whose home is taken by Pip, a critter or a pod stay put, and so
	# does any stack whose home is held by a stack that stays.
	for c: Vector2i in want:
		if want[c] != c and _occupied(want[c]):
			want[c] = c
	var changed: bool = true
	while changed:
		changed = false
		for c: Vector2i in want:
			if want[c] == c:
				continue
			for o: Vector2i in want:
				if o != c and want[o] == o and o == want[c]:
					want[c] = c
					changed = true
	var fresh: Dictionary = {}
	for c: Vector2i in want:
		var st: Dictionary = stacks[c]
		var to: Vector2i = want[c]
		if to != c:
			st["from"] = c
			st["anim"] = 0.0
			st["hop"] = 1.0
			arena._spawn_sparkles(Vector3(c.x, 0.4, c.y), M.INK_LIGHT.lightened(0.3))
		fresh[to] = st
	stacks = fresh
	resets[pad]["pulse"] = 1.0
	arena._spawn_ring(Vector3(pad.x, 0.08, pad.y), M.INK_LIGHT, 1.4)
	_sound(_snd_reset, 1.0, 0.0, true)


# --- Plates and doors ---------------------------------------------------------------

func _update_plates(first: bool) -> void:
	var all_on: Array[bool] = [true, true]
	var any: Array[bool] = [false, false]
	for c: Vector2i in plates:
		var pl: Dictionary = plates[c]
		var g: int = pl["group"]
		any[g] = true
		var on: bool = stacks.has(c)
		if on != bool(pl["on"]):
			pl["on"] = on
			if not first:
				_sound(_snd_click, 1.0 if on else 0.8, 0.0, true)
		if not on:
			all_on[g] = false
		if pl.has("node"):
			(pl["node"] as Node3D).get_node("Ribbon/Lit").visible = on
	for g in 2:
		group_open[g] = any[g] and all_on[g]


func _update_doors() -> void:
	for c: Vector2i in doors:
		var dr: Dictionary = doors[c]
		var want: bool = group_open[int(dr["group"])]
		if want == bool(dr["open"]):
			continue
		if not want and _occupied(c):
			continue
		dr["open"] = want
		_stuck_check = 0.6
		arena._spawn_sparkles(Vector3(c.x, 0.5, c.y), GROUP_COLORS[int(dr["group"])].lightened(0.3))
		if want:
			Sfx.play(&"gate", 0.0)
		else:
			_sound(_snd_thump, 0.7)


# --- Bookworms ------------------------------------------------------------------------

func _worm(cr: Arena.Critter) -> Dictionary:
	if not _worms.has(cr):
		_worms[cr] = {"nap": 0.0, "daze": 0.0, "slept": NO_CELL}
	return _worms[cr]


func _update_worms(delta: float) -> void:
	for cr: Arena.Critter in _worms.keys():
		if not arena.critters.has(cr):
			_worms.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"bookworm":
			continue
		var w: Dictionary = _worm(cr)
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		if float(w["daze"]) > 0.0:
			w["daze"] = maxf(float(w["daze"]) - delta, 0.0)
		elif float(w["nap"]) > 0.0:
			w["nap"] = maxf(float(w["nap"]) - delta, 0.0)
			if not stacks.has(here):
				w["nap"] = 0.0
		elif stacks.has(here) and cr.t >= 1.0 and w["slept"] != here:
			# Curl up for a read inside the stack.
			w["nap"] = _rng.randf_range(WORM_NAP_MIN, WORM_NAP_MAX)
			w["slept"] = here
		var still: bool = float(w["daze"]) > 0.0 or float(w["nap"]) > 0.0
		cr.speed = 0.0 if still else WORM_SPEED


func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"bookworm":
			return M.bookworm()
		&"boss":
			return M.boss()
	return null


func critter_speed(kind: StringName) -> float:
	return WORM_SPEED if kind == &"bookworm" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr.kind == &"bookworm" and stacks.has(Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)))


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"bookworm":
		return Vector2i.ZERO
	# Bookworms love a good stack: they often burrow into one next to them
	# (but not straight back into the one they just left).
	var w: Dictionary = _worm(cr)
	var options: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		var n: Vector2i = cr.cell + d
		if stacks.has(n) and n != w["slept"] and arena._critter_can_enter(cr, n):
			options.append(d)
	if not options.is_empty() and _rng.randf() < 0.45:
		return options[_rng.randi() % options.size()]
	return Vector2i.ZERO


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	if cr.kind == &"bookworm":
		var w: Dictionary = _worm(cr)
		# Burrow down into a stack as the worm reaches it.
		var inside: float = 0.0
		for c: Vector2i in [cr.cell, cr.target]:
			if stacks.has(c):
				inside = maxf(inside, 1.0 - clampf(cr.pos.distance_to(Vector2(c)) / 0.55, 0.0, 1.0))
		body.position.y = lerpf(body.position.y, -0.7 * inside, minf(delta * 14.0, 1.0))
		var moving: bool = cr.t < 1.0 and cr.speed > 0.0
		var wig: float = t * (11.0 if moving else 3.0)
		for k in range(1, 4):
			var seg: Node3D = body.get_node("Seg%d" % k)
			seg.position.x = sin(wig - k * 1.1) * (0.06 if moving else 0.025)
			seg.position.y = 0.15 + absf(sin(wig - k * 1.1)) * (0.05 if moving else 0.015)
		var head: Node3D = body.get_node("Head")
		head.position.y = 0.25 + sin(wig) * 0.02
		if float(w["daze"]) > 0.0:
			head.rotation.z = sin(_clock * 18.0) * 0.3
			head.rotation.y = sin(_clock * 7.0) * 0.4
		else:
			head.rotation.z = lerpf(head.rotation.z, sin(wig * 0.5) * 0.12, minf(delta * 8.0, 1.0))
			head.rotation.y = lerpf(head.rotation.y, 0.0, minf(delta * 8.0, 1.0))
		return Vector3.ONE * M.WORM_SIZE
	if cr.kind == &"boss":
		var hurt: bool = cr.hp <= INK_HURT_HP
		var sp: float = 5.0 if hurt else 3.0
		for k in 6:
			var tent: Node3D = body.get_node("Tent%d" % k)
			tent.rotation.z = sin(t * sp + k * 1.05) * 0.28
			tent.rotation.x = cos(t * sp * 0.7 + k) * 0.12
		var book: Node3D = body.get_node("Book")
		book.position.y = 0.42 + sin(t * 2.0) * 0.03
		var quill: Node3D = body.get_node("Quill")
		quill.rotation.z = 0.9 + sin(t * 1.6) * 0.15
		return Vector3(1.0, 1.0 + absf(sin(t * 3.0)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- Professor Inkle's ink -----------------------------------------------------------

func _update_ink(delta: float) -> void:
	for c: Vector2i in puddles.keys():
		var pd: Dictionary = puddles[c]
		pd["t"] = float(pd["t"]) - delta
		var n: Node3D = pd["node"]
		var left: float = float(pd["t"])
		var grow: float = minf((INK_LIFE - left) / 0.15, 1.0)
		n.scale = Vector3.ONE * maxf(grow * clampf(left / 0.8, 0.0, 1.0), 0.01)
		if left <= 0.0:
			n.queue_free()
			puddles.erase(c)
	var keep: Array[Dictionary] = []
	for b: Dictionary in _balls:
		b["t"] = float(b["t"]) + delta
		var u: float = float(b["t"]) / INK_FLIGHT
		var ball: Node3D = b["ball"]
		var ring: Node3D = b["ring"]
		var from: Vector3 = b["from"]
		var to: Vector3 = b["to"]
		ring.scale = Vector3.ONE * (0.6 + 0.4 * minf(u, 1.0))
		(ring.get_node("Disc") as Node3D).scale = Vector3.ONE * minf(u, 1.0)
		if u >= 1.0:
			ball.queue_free()
			ring.queue_free()
			_splat(b["cell"])
			continue
		ball.position = from.lerp(to, u) + Vector3(0, sin(u * PI) * 2.6, 0)
		ball.scale = Vector3.ONE * (1.0 + sin(u * PI * 6.0) * 0.08)
		keep.append(b)
	_balls = keep
	var boss: Arena.Critter = arena.boss
	if boss == null or not arena.critters.has(boss) or arena.state != &"play":
		return
	_ink_t -= delta
	if _ink_t > 0.0:
		return
	var hurt: bool = boss.hp <= INK_HURT_HP
	_ink_t = INK_EVERY_HURT if hurt else INK_EVERY
	var targets: Array[Vector2i] = [arena.hero_cell()]
	if hurt:
		var near: Array[Vector2i] = []
		for dx in range(-2, 3):
			for dz in range(-2, 3):
				var c: Vector2i = arena.hero_cell() + Vector2i(dx, dz)
				if absi(dx) + absi(dz) >= 2 and absi(dx) + absi(dz) <= 3 and arena.tile(c) == Arena.FLOOR and not blocks(c):
					near.append(c)
		for k in 2:
			if near.is_empty():
				break
			var i: int = _rng.randi() % near.size()
			targets.append(near[i])
			near.remove_at(i)
	for c: Vector2i in targets:
		_lob(boss, c)
	boss.node.get_node("Body").scale = Vector3(1.15, 0.85, 1.15) * M.BOSS_SIZE
	_sound(_snd_splat, 1.6, 0.4)


func _lob(boss: Arena.Critter, c: Vector2i) -> void:
	var ball: Node3D = M.ink_ball()
	var from: Vector3 = arena._to3(boss.pos, 1.7)
	ball.position = from
	arena.add_child(ball)
	var ring: Node3D = M.ink_warning()
	ring.position = Vector3(c.x, 0, c.y)
	arena.add_child(ring)
	_balls.append({"ball": ball, "ring": ring, "from": from, "to": Vector3(c.x, 0.15, c.y), "cell": c, "t": 0.0})


func _splat(c: Vector2i) -> void:
	if puddles.has(c):
		(puddles[c]["node"] as Node3D).queue_free()
	var n: Node3D = M.ink_puddle(_rng)
	n.position = Vector3(c.x, 0, c.y)
	n.rotation.y = _rng.randf() * TAU
	arena.add_child(n)
	puddles[c] = {"node": n, "t": INK_LIFE}
	arena._spawn_sparkles(Vector3(c.x, 0.2, c.y), M.INK_LIGHT)
	arena._shake = maxf(arena._shake, 0.1)
	_sound(_snd_splat, 1.0)


# --- Animation --------------------------------------------------------------------

func _animate(delta: float) -> void:
	for c: Vector2i in stacks:
		var st: Dictionary = stacks[c]
		if not st.has("node"):
			continue
		var n: Node3D = st["node"]
		var a: float = float(st["anim"])
		var body: Node3D = n.get_node("Body")
		if a < 1.0:
			var dur: float = 0.42 if float(st["hop"]) > 0.0 else PUSH_TIME
			a = minf(a + delta / dur, 1.0)
			st["anim"] = a
			var e: float = 1.0 - pow(1.0 - a, 3.0)
			var from: Vector2i = st["from"]
			n.position = Vector3(lerpf(from.x, c.x, e), sin(a * PI) * 0.9 * float(st["hop"]), lerpf(from.y, c.y, e))
			if a >= 1.0:
				st["hop"] = 0.0
				body.scale = Vector3(1.12, 0.84, 1.12)
		else:
			n.position = Vector3(c.x, 0, c.y)
		var bump: float = float(st["bump"])
		if bump > 0.0:
			bump = maxf(bump - delta * 4.0, 0.0)
			st["bump"] = bump
		body.rotation.z = sin(bump * PI * 3.0) * 0.06
		# A worm napping inside makes the stack wriggle.
		var wriggle: float = 0.0
		for cr: Arena.Critter in _worms:
			if arena.critters.has(cr) and float(_worms[cr]["nap"]) > 0.0 and Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
				wriggle = 1.0
		body.rotation.x = sin(_clock * 13.0) * 0.035 * wriggle
		body.position.y = absf(sin(_clock * 6.5)) * 0.03 * wriggle
		body.scale = body.scale.lerp(Vector3.ONE, minf(delta * 10.0, 1.0))
	for c: Vector2i in doors:
		var dr: Dictionary = doors[c]
		var goal: float = DOOR_SINK if bool(dr["open"]) else 0.0
		dr["y"] = move_toward(float(dr["y"]), goal, delta * 3.2)
		var shelf: Node3D = (dr["node"] as Node3D).get_node("Shelf")
		shelf.position.y = float(dr["y"])
		shelf.position.x = sin(_clock * 40.0) * 0.012 if absf(float(dr["y"]) - goal) > 0.01 else 0.0
	var moved: bool = false
	for c: Vector2i in stacks:
		if stacks[c]["home"] != c:
			moved = true
	for c: Vector2i in resets:
		var rp: Dictionary = resets[c]
		var n2: Node3D = rp["node"]
		var spin: Node3D = n2.get_node("Spin")
		spin.rotation.y += delta * (2.6 if moved else 0.5)
		rp["pulse"] = maxf(float(rp["pulse"]) - delta * 2.0, 0.0)
		var p: float = float(rp["pulse"])
		spin.scale = Vector3.ONE * ((1.0 + sin(_clock * 5.0) * 0.08 if moved else 0.85) + p * 0.4)
		(n2.get_node("Pool") as Node3D).scale = Vector3.ONE * (1.0 + p * 0.6)


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


## A soft, papery "thump" for a shoved book stack.
func _make_thump() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.28)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		var thud: float = sin(TAU * (95.0 + 60.0 * exp(-t * 30.0)) * t) * exp(-t * 18.0)
		lp = lp * 0.7 + randf_range(-1.0, 1.0) * 0.3
		var rustle: float = lp * exp(-t * 14.0) * 0.6
		out[i] = (thud * 0.85 + rustle) * 0.6
	return _wav(out)


## A wet "splotch" for an ink ball landing.
func _make_splat() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		lp = lp * 0.82 + randf_range(-1.0, 1.0) * 0.18
		var blob: float = sin(TAU * (320.0 * exp(-t * 9.0) + 80.0) * t) * exp(-t * 16.0)
		out[i] = (lp * 2.2 * exp(-t * 11.0) + blob * 0.6) * 0.5
	return _wav(out)


## A rising celesta sweep for the ink reset.
func _make_reset() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.7)
	var out := PackedFloat32Array()
	out.resize(n)
	var notes: Array[float] = [523.25, 659.25, 783.99, 1046.5, 1318.5]
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for k in notes.size():
			var t0: float = t - k * 0.07
			if t0 > 0.0:
				v += (sin(TAU * notes[k] * t0) + 0.3 * sin(TAU * notes[k] * 4.0 * t0) * exp(-t0 * 12.0)) * exp(-t0 * 5.0)
		out[i] = v * 0.22
	return _wav(out)


## A little wooden click for a bookmark plate.
func _make_click() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.18)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = sin(TAU * 1250.0 * t) * exp(-t * 60.0) + sin(TAU * 660.0 * t) * exp(-t * 30.0) * 0.6
		out[i] = v * 0.4
	return _wav(out)

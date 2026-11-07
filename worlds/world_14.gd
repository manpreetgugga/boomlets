extends WorldKit
## World 14, Magnet Mines: a cheerful copper-and-teal mine of rails and
## lanterns. The twist is magnets: red magnets pull fizz pods along their row
## and column (glowing floor arrows show the pull), blue magnets push them
## away, and pods zip along until something stops them. Blasting a flip
## switch swaps the colour of every magnet. Cartbugs, tin mine-cart beetles,
## ride the rails and get yanked along by the magnets too. Magnamole, the
## boss, is iron-clad: magnets drag him about, and once hurt he magnetises
## himself to push pods away (a flip switch turns his pull back on).
##
## Extra map characters:
##   R  red magnet (pulls)      U  blue magnet (pushes)    X  flip switch
##   =  rail, left-right        |  rail, up-down           m  Cartbug

const M := preload("res://worlds/world_14_models.gd")

## How many tiles along its row and column a magnet reaches.
const RANGE: int = 5
## How far Magnamole's own magnet reaches.
const AURA_RANGE: int = 4
const POD_PULL_SPEED: float = 6.0
const CART_SPEED: float = 1.9
const YANK_SPEED: float = 5.2
const BOSS_YANK_SPEED: float = 3.4
## Magnamole magnetises himself at this many hits left.
const BOSS_MAG_HP: int = 5
## After a flip turns his pull on, he turns it back to push this much later.
const BOSS_REPOLE: float = 6.5
const BOSS_WARN: float = 1.3

const PALETTE: Dictionary = {
	"GRASS_A": "#EED6AE", "GRASS_B": "#E2C699", "RIM": "#D9AE7E", "EDGE": "#2E8C87",
	"STONE": "#B08A70", "DARK_STONE": "#8E6C56", "DIRT": "#A8714D", "ROCK": "#8A6450",
	"WOOD": "#F4B740", "WOOD_DARK": "#C2692F", "BARREL": "#8E62D9", "BELT": "#4E5A66", "ACCENT": "#F2A541",
	"BLOSSOM_A": "#3FB8A8", "BLOSSOM_B": "#2E9C8F", "TRUNK": "#875733", "LEAFY_A": "#7FD6C4", "LEAFY_B": "#5CC2B0",
	"SKY_TOP": "#5DBFC4", "SKY_HORIZON": "#FFE6C4", "SKY_GROUND": "#F0D8B8", "CLOUD": "#FFFFFF", "CLOUDS": 0.5,
	"AMBIENT": "#D9CBB4", "AMBIENT_ENERGY": 0.55, "SUN": "#FFF0DA", "SUN_ENERGY": 1.5,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Pull Power",
		"tip": "Red magnets pull fizz pods\nalong the glowing arrows!\nDrop one in line and watch it zip.",
		"crates": 0.42, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.........#",
			"#.#.#.#.#.#.#",
			"#R====m====.#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#.====m====R#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Flip the Field",
		"tip": "Blue magnets push pods away.\nBlast the flip switch to swap\nevery magnet's colour!",
		"crates": 0.42, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.......m.#",
			"#.#.#.#.#.#.#",
			"#U.........R#",
			"#.#.#.#.#.#.#",
			"#.b...X...b.#",
			"#.#.#.#.#.#.#",
			"#R.........U#",
			"#.#.#.#.#.#.#",
			"#.....m.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Cart Crossing",
		"tip": "Cartbugs ride the rails, and\nmagnets yank them along too.\nPull them in, then pop them!",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m...|...m.#",
			"#.#.#.|.#.#.#",
			"#.....|.....#",
			"#X#.#.|.#.#X#",
			"#==m==R==m==#",
			"#.#.#.|.#.#.#",
			"#.....|.....#",
			"#.#.#.|.#.#.#",
			"#.b...|...b.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Barrel Bonanza",
		"tip": "Let a magnet slide your pod\nup to a fizz barrel\nfor a giant chain blast!",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#...m.E.....#",
			"#.#.#.#.#.#.#",
			"#U...m...B..#",
			"#.#.#.#.#.#.#",
			"#..B...z..m.#",
			"#.#.#.#.#.#.#",
			"#R====X====R#",
			"#.#.#.#.#.#.#",
			"#m........B.#",
			"#.#.#.#.#.#.#",
			"#..B.......U#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Warp Shaft",
		"tip": "Warps hop across the shaft.\nPushes meet in the middle;\nflip them to pull apart!",
		"crates": 0.4, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1...mEm...2#",
			"#.#.#.#.#.#.#",
			"#..m..U..m..#",
			"#.#.#.#.#.#.#",
			"#R..z.X.z..R#",
			"#.#.#.#.#.#.#",
			"###.#####.###",
			"#.#.#.#.#.#.#",
			"#U.........U#",
			"#.#.#.#.#.#.#",
			"#2.........1#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Magnamole's Dig",
		"tip": "Magnamole is iron-clad: magnets\ndrag him around! Once hurt he\npushes pods away. Flip him to pull!",
		"crates": 0.2, "par": 130, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#R....X....R#",
			"#...#...#...#",
			"#U....K....U#",
			"#.#.......#.#",
			"#...........#",
			"#.#.......#.#",
			"#R....X....R#",
			"#...#...#...#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"pull": bool, "node", "spin": seconds left of the flip spin}.
var magnets: Dictionary = {}
## Vector2i -> {"node", "turn": dial angle goal, "bump"}.
var flippers: Dictionary = {}
## Vector2i -> 0 (left-right) or 1 (up-down).
var rails: Dictionary = {}
## The magnets' pull on each floor tile: Vector2i -> direction, plus the
## distance to the magnet doing it and whether it is a pull.
var field: Dictionary = {}
var field_dist: Dictionary = {}
var field_pull: Dictionary = {}

var _tiles_seen := PackedInt32Array()
var _arrows_red: MultiMesh
var _arrows_blue: MultiMesh
var _red_cells: Array[Vector2i] = []
var _blue_cells: Array[Vector2i] = []
var _clock: float = 0.0
var _last_flip: float = -9.0
var _yanked: Dictionary = {}      # Critter -> true while a magnet drags it
var _boss_pole: int = 0           # 0 none, 1 pull (red), -1 push (blue)
var _boss_pole_t: float = 0.0
var _player: AudioStreamPlayer
var _snd_zip: AudioStreamWAV
var _snd_flip: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Magnet Mines"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_14.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "MAGNAMOLE"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	return &"cartbug"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"R", "U":
			magnets[c] = {"pull": ch == "R", "spin": 0.0}
			return true
		"X":
			flippers[c] = {"turn": 0.0, "bump": 0.0}
			return true
		"=":
			rails[c] = 0
			return true
		"|":
			rails[c] = 1
			return true
	return false


func critter_chars() -> Dictionary:
	return {"m": &"cartbug"}


func build_extra() -> void:
	# Critters that start on a rail line sit on rail too.
	for cr: Arena.Critter in arena.critters:
		var c: Vector2i = cr.cell
		if rails.has(c):
			continue
		if rails.get(c + Vector2i(1, 0), -1) == 0 and rails.get(c + Vector2i(-1, 0), -1) == 0:
			rails[c] = 0
		elif rails.get(c + Vector2i(0, 1), -1) == 1 and rails.get(c + Vector2i(0, -1), -1) == 1:
			rails[c] = 1
	for c: Vector2i in magnets:
		var mg: Dictionary = magnets[c]
		var n: Node3D = M.magnet(mg["pull"])
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		mg["node"] = n
	for c: Vector2i in flippers:
		var n: Node3D = M.flipper()
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		flippers[c]["node"] = n
	_build_rails()
	var hidden: Array[Transform3D] = []
	for i in Arena.W * Arena.H:
		hidden.append(_hidden_tf())
	_arrows_red = _arrow_mm(M.RED, hidden.size())
	_arrows_blue = _arrow_mm(M.BLUE, hidden.size())
	_rebuild_field()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_snd_zip = _make_zip()
	_snd_flip = _make_flip()


## A multimesh of floor arrows (its instances are placed every frame).
func _arrow_mm(color: Color, count: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = M.floor_chevron()
	mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, _hidden_tf())
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Models.mat(color, 0.7)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-2, -6, -2), Vector3(Arena.W + 4, 8, Arena.H + 4))
	arena.add_child(mmi)
	return mm


func _hidden_tf() -> Transform3D:
	return Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -5, 0))


func _build_rails() -> void:
	var bars: Array[Transform3D] = []
	var sleepers: Array[Transform3D] = []
	for c: Vector2i in rails:
		var turn := Basis(Vector3.UP, 0.0 if int(rails[c]) == 0 else PI * 0.5)
		var p := Vector3(c.x, 0, c.y)
		for s: float in [-0.19, 0.19]:
			bars.append(Transform3D(turn, p + turn * Vector3(0, 0.035, s)))
		for s2: float in [-0.25, 0.25]:
			sleepers.append(Transform3D(turn, p + turn * Vector3(s2, 0.012, 0)))
	if rails.is_empty():
		return
	arena._multimesh(Models.box_mesh(Vector3(0.2, 0.035, 0.6), 0.012), M.TIMBER, sleepers)
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.04, 0.06), 0.012), M.SILVER.darkened(0.15), bars)


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Timber planks along the top of the wall with copper rivets, and a
	# lantern every few blocks.
	var planks: Array[Transform3D] = []
	var rivets: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var lamps: Array[Transform3D] = []
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, 0.72, z)
		var along_x: bool = z == 0 or z == h - 1
		planks.append(Transform3D(Basis(Vector3.UP, 0.0 if along_x else PI * 0.5), at))
		var side := Vector3(0, 0, 0.3) if along_x else Vector3(0.3, 0, 0)
		rivets.append(Transform3D(Basis(), at + side + Vector3(0, 0.04, 0)))
		rivets.append(Transform3D(Basis(), at - side + Vector3(0, 0.04, 0)))
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if (x + z) % 4 == 0 and not corner and z != h - 1:
			posts.append(Transform3D(Basis(), at + Vector3(0, 0.22, 0)))
			lamps.append(Transform3D(Basis(), at + Vector3(0, 0.5, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.98, 0.08, 0.72), 0.03), M.TIMBER, planks)
	arena._multimesh(Models.sphere(0.035, -1, 6), M.COPPER, rivets)
	arena._multimesh(Models.box_mesh(Vector3(0.08, 0.38, 0.08), 0.02), M.TIMBER_DARK, posts)
	arena._multimesh(Models.box_mesh(Vector3(0.15, 0.17, 0.15), 0.04), M.LANTERN, lamps, Models.mat(M.LANTERN, 2.0))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Rocky ore blocks: a warm stone block with a lighter cap, glowing teal
	# crystals and a copper or gold nugget poking out.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var rocks: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var gems: Array[Transform3D] = []
	var nuggets: Array[Transform3D] = []
	var golds: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var yaw: float = r.randf_range(-0.2, 0.2)
		rocks.append(Transform3D(Basis(Vector3.UP, yaw), p + Vector3(0, 0.3, 0)))
		caps.append(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.3, 0.3)), p + Vector3(r.randf_range(-0.06, 0.06), 0.63, r.randf_range(-0.06, 0.06))))
		for k in r.randi_range(1, 2):
			var a: float = r.randf() * TAU
			var b := (Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, r.randf_range(0.1, 0.45))).scaled(Vector3.ONE * r.randf_range(0.8, 1.2))
			var base := p + Vector3(cos(a) * 0.14, 0.66, sin(a) * 0.14)
			gems.append(Transform3D(b, base + b * Vector3(0, 0.17, 0)))
		var front := p + Vector3(r.randf_range(-0.25, 0.25), r.randf_range(0.2, 0.42), 0.43)
		if r.randf() < 0.5:
			golds.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), front))
		else:
			nuggets.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), front))
	arena._multimesh(Models.box_mesh(Vector3(0.86, 0.6, 0.86), 0.14), Models.STONE, rocks)
	arena._multimesh(Models.box_mesh(Vector3(0.62, 0.1, 0.56), 0.045), Models.STONE.lightened(0.18), caps)
	arena._multimesh(Models.cylinder(0.0, 0.1, 0.36, 6), M.TEAL, gems, Models.mat(M.TEAL_LIGHT, 0.7))
	arena._multimesh(Models.box_mesh(Vector3(0.14, 0.12, 0.08), 0.035), M.COPPER, nuggets)
	arena._multimesh(Models.box_mesh(Vector3(0.13, 0.11, 0.08), 0.035), M.GOLD, golds, Models.mat(M.GOLD, 0.25))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.2:
			node = M.ore_pile(r)
		elif roll < 0.3:
			node = M.crystals(r, 0.7)
	elif p.z < 0.0:
		if roll < 0.12:
			node = M.mine_door()
		elif roll < 0.3:
			node = M.lantern_post()
		elif roll < 0.42:
			node = M.ore_cart(r)
		elif roll < 0.58:
			node = M.crystals(r, 1.1)
		elif roll < 0.7:
			node = M.ore_pile(r)
	else:
		if roll < 0.16:
			node = M.lantern_post()
			node.rotation.y = 0.0 if p.x < 0.0 else PI
		elif roll < 0.28:
			node = M.ore_cart(r)
		elif roll < 0.44:
			node = M.crystals(r, 1.0)
		elif roll < 0.56:
			node = M.ore_pile(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var door := M.mine_door()
	door.scale = Vector3.ONE * 1.3
	door.position = Vector3(0, 0, -size * 0.15)
	root.add_child(door)
	var cr := M.crystals(r, 1.4)
	cr.position = Vector3(size * 0.28, 0, size * 0.18)
	root.add_child(cr)
	var cart := M.ore_cart(r)
	cart.position = Vector3(-size * 0.25, 0, size * 0.22)
	root.add_child(cart)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFEBD2")
	env.adjustment_saturation = 1.1
	env.glow_intensity = 0.55


# --- The magnetic field -----------------------------------------------------------

## Works out which way the magnets pull or push on every floor tile: each
## magnet reaches RANGE tiles along its row and column until something
## solid stops it. The nearest magnet wins; a tie between two that disagree
## cancels out.
func _rebuild_field() -> void:
	_tiles_seen = arena.tiles.duplicate()
	var best: Dictionary = {}
	for m: Vector2i in magnets:
		var pull: bool = magnets[m]["pull"]
		for d: Vector2i in Arena.DIRS:
			for i in range(1, RANGE + 1):
				var c: Vector2i = m + d * i
				if arena.tile(c) != Arena.FLOOR or blocks(c):
					break
				var dir: Vector2i = -d if pull else d
				if not best.has(c) or i < int(best[c][0]):
					best[c] = [i, dir, pull]
				elif i == int(best[c][0]) and best[c][1] != dir:
					best[c] = [i, Vector2i.ZERO, pull]
	field.clear()
	field_dist.clear()
	field_pull.clear()
	_red_cells.clear()
	_blue_cells.clear()
	for c: Vector2i in best:
		var e: Array = best[c]
		if e[1] == Vector2i.ZERO:
			continue
		field[c] = e[1]
		field_dist[c] = e[0]
		field_pull[c] = e[2]
		if e[2]:
			_red_cells.append(c)
		else:
			_blue_cells.append(c)
	var hidden: Transform3D = _hidden_tf()
	for i in range(_red_cells.size(), _arrows_red.instance_count):
		_arrows_red.set_instance_transform(i, hidden)
	for i in range(_blue_cells.size(), _arrows_blue.instance_count):
		_arrows_blue.set_instance_transform(i, hidden)


func _animate_arrows() -> void:
	var u: float = fposmod(_clock * 1.3, 1.0)
	var lay := Basis(Vector3.RIGHT, -PI * 0.5)
	for pass_i in 2:
		var cells: Array[Vector2i] = _red_cells if pass_i == 0 else _blue_cells
		var mm: MultiMesh = _arrows_red if pass_i == 0 else _arrows_blue
		for i in cells.size():
			var c: Vector2i = cells[i]
			var d: Vector2i = field[c]
			var s: float = (0.6 + 0.5 * sin(u * PI)) * 1.25
			var at := Vector3(c.x + d.x * (u - 0.5) * 0.55, 0.045, c.y + d.y * (u - 0.5) * 0.55)
			mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, atan2(-float(d.y), float(d.x))) * lay * Basis().scaled(Vector3(s, s, 1.0)), at))


## The way a pod on [param c] gets pulled (including Magnamole's own
## magnet), or zero.
func _pod_dir(c: Vector2i) -> Vector2i:
	var d: Vector2i = field.get(c, Vector2i.ZERO)
	var dist: int = int(field_dist.get(c, 99))
	var b: Arena.Critter = arena.boss
	if _boss_pole != 0 and b != null and arena.critters.has(b):
		var bc := Vector2i(roundi(b.pos.x), roundi(b.pos.y))
		var to: Vector2i = bc - c
		if (to.x == 0) != (to.y == 0):
			var n: int = absi(to.x) + absi(to.y)
			if n <= AURA_RANGE and n <= dist and _clear_line(c, bc):
				var step := Vector2i(signi(to.x), signi(to.y))
				d = step if _boss_pole > 0 else -step
	return d


func _clear_line(a: Vector2i, b: Vector2i) -> bool:
	var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	var c: Vector2i = a + step
	while c != b:
		if arena.tile(c) != Arena.FLOOR or blocks(c):
			return false
		c += step
	return true


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return magnets.has(c) or flippers.has(c)


func flame_stop(c: Vector2i) -> int:
	if magnets.has(c):
		return 2
	if flippers.has(c):
		return 1
	return 0


func on_flame(c: Vector2i) -> void:
	if flippers.has(c):
		_flip_all(c)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not blocks(c)


## Swaps every magnet's colour (once per blast, however many switches it hits).
func _flip_all(from: Vector2i) -> void:
	if _clock - _last_flip < 0.4:
		return
	_last_flip = _clock
	var f: Dictionary = flippers[from]
	for c: Vector2i in flippers:
		flippers[c]["turn"] = float(flippers[c]["turn"]) + PI
		flippers[c]["bump"] = 1.0
	for c: Vector2i in magnets:
		var mg: Dictionary = magnets[c]
		mg["pull"] = not mg["pull"]
		mg["spin"] = 0.5
		arena._spawn_sparkles(Vector3(c.x, 0.8, c.y), (M.RED if mg["pull"] else M.BLUE).lightened(0.4))
	if _boss_pole != 0:
		_boss_pole = -_boss_pole
		_boss_pole_t = BOSS_REPOLE
		if arena.boss != null:
			M.set_boss_pole(arena.boss.node, _boss_pole)
			arena._spawn_ring(arena._to3(arena.boss.pos, 0.1), M.RED if _boss_pole > 0 else M.BLUE, 1.4)
	arena._spawn_ring(Vector3(from.x, 0.1, from.y), M.LANTERN, 1.2)
	arena._shake = maxf(arena._shake, 0.15)
	f["bump"] = 1.0
	_rebuild_field()
	_sound(_snd_flip, 1.0)


func process(delta: float) -> void:
	_clock += delta
	if arena.tiles != _tiles_seen:
		_rebuild_field()
	_animate_arrows()
	for c: Vector2i in magnets:
		_animate_magnet(magnets[c], delta)
	for c: Vector2i in flippers:
		_animate_flipper(flippers[c], delta)
	if arena.demo:
		return
	_pull_pods()
	_update_critter_speeds()
	_update_boss(delta)


func _pull_pods() -> void:
	for p: Arena.Pod in arena.pods:
		if p.slide != Vector2i.ZERO or p.age < 0.3:
			continue
		var d: Vector2i = _pod_dir(p.cell)
		if d == Vector2i.ZERO or arena._pod_blocked(p.cell + d):
			continue
		p.slide = d
		p.slide_speed = POD_PULL_SPEED
		p.kicked = true
		var pull: bool = bool(field_pull.get(p.cell, true)) if field.get(p.cell, Vector2i.ZERO) == d else _boss_pole > 0
		arena._spawn_sparkles(Vector3(p.cell.x, 0.3, p.cell.y), (M.RED if pull else M.BLUE).lightened(0.4))
		_sound(_snd_zip, 1.0 if pull else 0.84)


func _animate_magnet(mg: Dictionary, delta: float) -> void:
	var n: Node3D = mg["node"]
	var spin: Node3D = n.get_node("Spin")
	var s: float = float(mg["spin"])
	if s > 0.0:
		var before: float = s
		s = maxf(s - delta, 0.0)
		mg["spin"] = s
		spin.rotation.y = (1.0 - s / 0.5) * TAU
		spin.position.y = 0.66 + sin((1.0 - s / 0.5) * PI) * 0.25
		if before > 0.25 and s <= 0.25:
			M.set_pole(n, mg["pull"])
		if s == 0.0:
			M.set_pole(n, mg["pull"])
	else:
		spin.rotation.y = sin(_clock * 1.4 + n.position.x) * 0.25
		spin.position.y = 0.66 + sin(_clock * 3.0 + n.position.z) * 0.025


func _animate_flipper(f: Dictionary, delta: float) -> void:
	var n: Node3D = f["node"]
	var dial: Node3D = n.get_node("Dial")
	dial.rotation.z = lerp_angle(dial.rotation.z, float(f["turn"]), minf(delta * 9.0, 1.0))
	f["bump"] = maxf(float(f["bump"]) - delta * 3.0, 0.0)
	var b: float = float(f["bump"])
	dial.scale = Vector3.ONE * (1.0 + sin(b * PI) * 0.25)
	var bulb: Node3D = n.get_node("Bulb")
	bulb.scale = Vector3.ONE * (1.0 + sin(_clock * 4.0) * 0.12 + b * 0.8)


# --- Critters -----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"cartbug":
			return M.cartbug()
		&"boss":
			return M.boss()
	return null


func critter_speed(kind: StringName) -> float:
	return CART_SPEED if kind == &"cartbug" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_smart(kind: StringName) -> bool:
	return kind == &"cartbug" and arena != null and arena.level_id >= 4


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"cartbug" and cr.kind != &"boss":
		return Vector2i.ZERO
	# Iron and tin get dragged along by the magnets.
	var d: Vector2i = field.get(cr.cell, Vector2i.ZERO)
	if d != Vector2i.ZERO and arena._critter_can_enter(cr, cr.cell + d):
		if not _yanked.has(cr):
			arena._spawn_sparkles(Vector3(cr.cell.x, 0.4, cr.cell.y), (M.RED if field_pull.get(cr.cell, true) else M.BLUE).lightened(0.4))
		_yanked[cr] = true
		return d
	_yanked.erase(cr)
	if cr.kind == &"cartbug" and rails.has(cr.cell) and arena.rng.randf() < 0.85:
		var along: Vector2i = Vector2i(1, 0) if int(rails[cr.cell]) == 0 else Vector2i(0, 1)
		var first: Vector2i = cr.dir if (cr.dir == along or cr.dir == -along) else along
		var danger: Dictionary = arena._critter_danger(cr)
		for cand: Vector2i in [first, -first]:
			var n: Vector2i = cr.cell + cand
			if rails.has(n) and arena._critter_can_enter(cr, n) and not danger.has(n):
				return cand
	return Vector2i.ZERO


func _update_critter_speeds() -> void:
	for cr: Arena.Critter in _yanked.keys():
		if not arena.critters.has(cr):
			_yanked.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"cartbug":
			cr.speed = YANK_SPEED if _yanked.has(cr) else CART_SPEED
		elif cr.kind == &"boss":
			# The arena speeds him up as he gets hurt; a magnet drags faster.
			var base: float = 1.0 + float(arena.boss_max_hp - cr.hp) * 0.72 / float(maxi(arena.boss_max_hp, 1))
			cr.speed = maxf(BOSS_YANK_SPEED, base) if _yanked.has(cr) else base


## Once hurt, Magnamole magnetises himself to push pods away; a flip turns
## him to pull, and a while later he turns himself back.
func _update_boss(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		return
	if _boss_pole == 0:
		if b.hp <= BOSS_MAG_HP:
			_boss_pole = -1
			M.set_boss_pole(b.node, -1)
			arena._spawn_ring(arena._to3(b.pos, 0.1), M.BLUE, 2.0)
			_sound(_snd_flip, 0.7)
		return
	if _boss_pole > 0:
		_boss_pole_t -= delta
		var aura: Node3D = b.node.get_node("Aura")
		aura.visible = _boss_pole_t > BOSS_WARN or fmod(_clock, 0.2) < 0.12
		if _boss_pole_t <= 0.0:
			_boss_pole = -1
			M.set_boss_pole(b.node, -1)
			arena._spawn_ring(arena._to3(b.pos, 0.1), M.BLUE, 1.6)
			_sound(_snd_flip, 0.7)


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	var yank: bool = _yanked.has(cr) and cr.t < 1.0
	if cr.kind == &"cartbug":
		var moving: bool = cr.t < 1.0
		for w: String in ["WheelA", "WheelB", "WheelC", "WheelD"]:
			var wheel: Node3D = body.get_node(w)
			if moving:
				wheel.rotation.x += delta * cr.speed * 9.0
		body.rotation.x = lerpf(body.rotation.x, -0.22 if yank else 0.0, minf(delta * 10.0, 1.0))
		body.position.y = absf(sin(t * 16.0)) * (0.015 if not yank else 0.04)
		var ant: Node3D = body.get_node("Antennae")
		ant.rotation.x = sin(t * 6.0) * 0.15 - (0.35 if yank else 0.0)
		return Vector3.ONE * M.CART_SIZE
	if cr.kind == &"boss":
		var arm_l: Node3D = body.get_node("ArmL")
		var arm_r: Node3D = body.get_node("ArmR")
		var dig: float = 6.0 if cr.hp <= BOSS_MAG_HP else 4.0
		arm_l.rotation.x = sin(t * dig) * 0.45
		arm_r.rotation.x = -sin(t * dig) * 0.45
		body.rotation.x = lerpf(body.rotation.x, -0.15 if yank else 0.0, minf(delta * 8.0, 1.0))
		var nose: Node3D = body.get_node("Nose")
		nose.scale = Vector3.ONE * (1.0 + sin(t * 9.0) * 0.08)
		var aura: Node3D = cr.node.get_node("Aura")
		aura.rotation.y += delta * 2.0
		aura.scale = Vector3.ONE * (1.0 + sin(t * 5.0) * 0.05)
		return Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


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


## A rising magnetic "vvzzip" for a pod being yanked.
func _make_zip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		phase += TAU * (220.0 + 1100.0 * t / 0.3) / rate
		var buzz: float = 0.6 + 0.4 * sin(TAU * 60.0 * t)
		var env: float = minf(t / 0.01, 1.0) * exp(-t * 6.0)
		out[i] = (sin(phase) * 0.6 + (0.25 if sin(phase * 3.0) > 0.0 else -0.25)) * buzz * env * 0.45
	return _wav(out)


## A chunky "clunk-ding" for the flip switch.
func _make_flip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var clunk: float = sin(TAU * (110.0 + 90.0 * exp(-t * 40.0)) * t) * exp(-t * 26.0)
		var t2: float = maxf(t - 0.06, 0.0)
		var ding: float = (sin(TAU * 988.0 * t2) + 0.4 * sin(TAU * 1976.0 * t2) + 0.2 * sin(TAU * 1482.0 * t2)) * exp(-t2 * 7.0) * (1.0 if t > 0.06 else 0.0)
		out[i] = (clunk * 0.8 + ding * 0.35) * 0.55
	return _wav(out)

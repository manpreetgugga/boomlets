extends WorldKit
## World 2, Candy Coast: a sunny sweets-and-seaside island on a turquoise sea.
## Its twist is the tide: tide pools (~) flood and drain on a shared timer.
## At high tide the water stops Pip and his pods (flames still race over it,
## and the sea critters swim right through); a shimmer, rising bubbles and
## the tide chip at the bottom of the screen warn a few seconds before each
## change. If the water comes in under Pip, a wave nudges him ashore.
## New critter: the sidestepping crab (k walks left-right, j up-down), which
## takes two blasts. Jellies, gulls and bubbles re-skin the Blobbits,
## Buzzers and Wisps; Captain Clawdia, a giant crab, is the boss.

const M = preload("res://worlds/world_2_models.gd")

## Water heights (top of the pool water) at low and high tide.
const LOW_Y: float = 0.03
const HIGH_Y: float = 0.28
## Seconds of warning before each change, and how long the water takes to
## rise or fall.
const WARN: float = 2.0
const MOVE: float = 0.8
const PUSH_SPEED: float = 5.5
const SEA_Y: float = -0.55
const NO_CELL := Vector2i(-99, -99)

const LEVELS: Array[Dictionary] = [
	{
		"name": "Low Tide Lane",
		"tip": "The tide floods the pools!\nWhen they shimmer, the water's coming.\nCross at low tide.",
		"crates": 0.5, "par": 70, "tide": [9.0, 5.0],
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.......b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#~~~~~~~~~~~#",
			"#.#.#_#_#.#.#",
			"#.........b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crab Cove",
		"tip": "Crabs scuttle side to side,\neven through the water.\nThey take two blasts!",
		"crates": 0.45, "par": 80, "tide": [8.0, 5.0],
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#...._k_....#",
			"#.#~#.#.#~#.#",
			"#.~~~...~~~.#",
			"#.#~#.#.#~#.#",
			"#..._.k_....#",
			"#.#~#.#.#~#.#",
			"#.~~~...~~~.#",
			"#.#~#.#.#~#.#",
			"#.b.........#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Taffy Pier",
		"tip": "Taffy belts carry you along.\nGulls swoop after you!",
		"crates": 0.45, "par": 90, "tide": [7.0, 5.0],
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..>>>>>>v..#",
			"#.#^#~#~#v#.#",
			"#.b^~~~~~v..#",
			"#.#^#~#~#v#.#",
			"#..^.~~~.v.z#",
			"#.#^#.#.#v#.#",
			"#..^<<<<<<..#",
			"#.#.#.#.#.#.#",
			"#.k.......b.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Fizz Lagoon",
		"tip": "Blasts fly over high water.\nPop a barrel across the lagoon!",
		"crates": 0.4, "par": 95, "tide": [7.0, 6.0],
		"drops": {"bomb": 2, "fire": 1, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..B..E..B..#",
			"#.#.#.#.#.#.#",
			"#.k..~~~....#",
			"#.#.#~#~#.#.#",
			"#..B.~~~.B..#",
			"#.#.#~#~#.#.#",
			"#.b..~~~..z.#",
			"#.#.#~#~#.#.#",
			"#..B.~~~.B..#",
			"#.#.#~#~#.#.#",
			"#....~~~..k.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bubble Reef",
		"tip": "Swirl pads skip the high water.\nBubbles drift through crates!",
		"crates": 0.45, "par": 100, "tide": [6.5, 6.0],
		"drops": {"bomb": 2, "fire": 2, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1....E....2#",
			"#.#.#.#.#.#.#",
			"#j....w....j#",
			"#.#~#.#.#~#.#",
			"#..~~...~~..#",
			"###~#.#.#~###",
			"#2.._~b~_..1#",
			"###~#.#.#~###",
			"#..~~...~~..#",
			"#.#~#.#.#~#.#",
			"#.w.......k.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Clawdia's Lagoon",
		"tip": "Captain Clawdia wades the lagoon!\nHit her with six blasts.",
		"crates": 0.3, "par": 130, "boss": true, "tide": [7.0, 5.0],
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...~~~~~...#",
			"#..~~___~~..#",
			"#..~__K__~..#",
			"#.#~_____~#.#",
			"#..~~___~~..#",
			"#...~~_~~...#",
			"#.#.......#.#",
			"#...........#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Tide pool tiles (Vector2i -> true).
var pools: Dictionary = {}
## True while the pools are flooded (Pip and pods cannot enter them).
var flooded: bool = false
## The tide's phase: &"low", &"rising", &"high" or &"falling".
var phase: StringName = &"low"
## Seconds until the next phase, and the current phase's length.
var phase_left: float = 0.0
var phase_len: float = 1.0
## True during the warning before the water starts to rise or fall.
var warning: bool = false

var _tide_t: float = 0.0
var _low: float = 8.0
var _high: float = 5.0
var _level: float = LOW_Y
var _water: Node3D
var _lips: MeshInstance3D
var _pool_mat: ShaderMaterial
var _push: Array[Vector2] = []
var _held: Vector2i = NO_CELL
var _ui: Control
var _bubbles: Array[Dictionary] = []
var _bubble_cd: float = 0.0
var _bubble_mesh: Mesh
var _was_warning: bool = false


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Candy Coast"


func palette() -> Variant:
	var p: Dictionary = (Models.PALETTES["candy_coast"] as Dictionary).duplicate()
	p["EDGE"] = "#4DB8E0"
	p["BLOBBIT"] = "#FF9ED6"
	return p


func music() -> String:
	return "res://audio/music/world_2.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "CAPTAIN CLAWDIA"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "~":
		pools[c] = true
		return true
	return false


func critter_chars() -> Dictionary:
	return {"k": &"crab", "j": &"crab"}


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Starfish, shells, coral sprigs and gumdrops scattered along the wall.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var sets: Dictionary = {}   # [mesh key, colour] -> transforms
	var top: float = 0.69
	for tf in blocks:
		if r.randf() > 0.55:
			continue
		var base := Vector3(tf.origin.x + r.randf_range(-0.12, 0.12), top, tf.origin.z + r.randf_range(-0.12, 0.12))
		var roll: float = r.randf()
		var yaw := Basis(Vector3.UP, r.randf() * TAU)
		if roll < 0.32:
			var tilt := Basis(Vector3.RIGHT, r.randf_range(-0.1, 0.1))
			_add(sets, "star", M.STAR_COLORS[r.randi() % 3], Transform3D(yaw * tilt * Basis().scaled(Vector3.ONE * r.randf_range(1.3, 1.6)), base))
		elif roll < 0.58:
			_add(sets, "shell", M.SHELL_COLORS[r.randi() % 2], Transform3D(yaw * Basis(Vector3.RIGHT, -0.25) * Basis().scaled(Vector3.ONE * 1.45), base + Vector3(0, 0.03, 0)))
		elif roll < 0.78:
			for k in 3:
				var a: float = TAU * k / 3.0 + r.randf()
				var lean := Basis(Vector3(cos(a), 0, sin(a)).cross(Vector3.UP).normalized(), -0.35 if k > 0 else 0.0)
				var h: float = r.randf_range(0.8, 1.15) if k > 0 else 1.3
				var off := Vector3(cos(a), 0, sin(a)) * (0.05 if k > 0 else 0.0)
				_add(sets, "coral", M.CORAL, Transform3D(lean * Basis().scaled(Vector3(1.3, h * 1.25, 1.3)), base + off + Vector3(0, 0.14 * h, 0)))
		else:
			for k in 2:
				var off2 := Vector3(r.randf_range(-0.14, 0.14), 0.05, r.randf_range(-0.14, 0.14))
				_add(sets, "gum", M.SWEETS[r.randi() % M.SWEETS.size()], Transform3D(Basis().scaled(Vector3.ONE * 1.35), base + off2 + Vector3(0, 0.02, 0)))
	var meshes := {"star": M.star_mesh(), "shell": M.shell_mesh(), "coral": M.coral_mesh(), "gum": M.gumdrop_mesh()}
	for key: Array in sets:
		var list: Array[Transform3D] = []
		list.assign(sets[key])
		arena._multimesh(meshes[key[0]], key[1], list)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Rock-candy stacks: a pastel sugar block, a white frosting slab and a
	# smaller block of another flavour turned on top, some with a gumdrop.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var lows: Array = [[], [], [], []]
	var highs: Array = [[], [], [], []]
	var frost: Array[Transform3D] = []
	var gums: Array = [[], []]
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var ci: int = r.randi() % 4
		var cj: int = (ci + 1 + r.randi() % 3) % 4
		var turn := Basis(Vector3.UP, r.randf_range(-0.5, 0.5))
		(lows[ci] as Array).append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.06, 0.06)), p + Vector3(0, 0.27, 0)))
		frost.append(Transform3D(turn, p + Vector3(0, 0.55, 0)))
		(highs[cj] as Array).append(Transform3D(turn, p + Vector3(0, 0.72, 0)))
		if r.randf() < 0.45:
			(gums[r.randi() % 2] as Array).append(Transform3D(Basis(), p + Vector3(0, 0.91, 0)))
	var low_mesh := Models.box_mesh(Vector3(0.84, 0.54, 0.84), 0.12)
	var high_mesh := Models.box_mesh(Vector3(0.5, 0.28, 0.5), 0.09)
	for i in 4:
		var a: Array[Transform3D] = []
		a.assign(lows[i])
		arena._multimesh(low_mesh, M.CANDY[i], a)
		var b: Array[Transform3D] = []
		b.assign(highs[i])
		arena._multimesh(high_mesh, M.CANDY[i].lightened(0.1), b)
	arena._multimesh(Models.box_mesh(Vector3(0.64, 0.1, 0.64), 0.04), Color("#FFF8F0"), frost)
	var gum_colors: Array[Color] = [Color("#FF8FB8"), Color("#FFB37A")]
	for i in 2:
		var g: Array[Transform3D] = []
		g.assign(gums[i])
		arena._multimesh(M.gumdrop_mesh(), gum_colors[i], g)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.3:
			node = M.beach_bits(r)
		elif roll < 0.38:
			node = M.bucket(r)
		elif roll < 0.45:
			node = M.beach_ball(r)
		elif roll < 0.5:
			node = M.sandcastle(r, true)
	else:
		if roll < 0.15:
			node = M.palm(r, r.randf_range(1.1, 1.45))
		elif roll < 0.24:
			node = M.umbrella(r)
		elif roll < 0.34:
			node = M.lollipop(r, r.randf_range(1.1, 1.4))
		elif roll < 0.4:
			node = M.sandcastle(r)
		elif roll < 0.6:
			node = M.beach_bits(r)
	if node == null:
		return Node3D.new()
	var holder := Node3D.new()
	node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
	holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var p := M.palm(r, 1.3)
	p.position = Vector3(-size * 0.12, 0, -size * 0.1)
	root.add_child(p)
	var other: Node3D = M.umbrella(r) if r.randf() < 0.5 else M.sandcastle(r)
	other.position = Vector3(size * 0.22, 0, size * 0.18)
	root.add_child(other)
	var bits := M.beach_bits(r)
	bits.position = Vector3(size * 0.25, 0, -size * 0.25)
	root.add_child(bits)
	return root


func build_extra() -> void:
	var t: Array = arena.data.get("tide", [8.0, 5.0])
	_low = float(t[0])
	_high = float(t[1])
	_build_sea()
	_build_pools()
	_tag_crabs()
	_bubble_mesh = Models.sphere(0.05, -1, 8)
	if not arena.demo and not pools.is_empty():
		_build_ui()
	_update_tide(0.0)


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	env.adjustment_saturation = 1.08
	sun.light_energy = Models.SUN_ENERGY * 1.04


# --- The sea and the pools ---------------------------------------------------------

func _build_sea() -> void:
	var cx: float = (Arena.W - 1) * 0.5
	var cz: float = (Arena.H - 1) * 0.5
	var isles: Array[Vector4] = [Vector4(cx, cz, (Arena.W + 1.9) * 0.5, (Arena.H + 1.9) * 0.5)]
	# Bring the arena's far-off islands down to sea level so they read as
	# little sandbars dotted round the coast.
	var specs: Array[Vector3] = [Vector3(-7.5, -2.0, 1.0), Vector3(Arena.W + 6.0, -1.0, 3.0), Vector3(-5.5, -4.5, Arena.H + 2.0), Vector3(Arena.W + 4.5, -5.0, Arena.H - 1.0)]
	var sizes: Array[float] = [3.2, 2.6, 2.0, 2.4]
	for ch: Node in arena.get_children():
		if ch.get_class() != "Node3D":
			continue
		var n := ch as Node3D
		for i in specs.size():
			if n.position.distance_to(specs[i]) < 0.01:
				n.position.y = SEA_Y + 0.42
				var s: float = sizes[i] * 0.5
				isles.append(Vector4(n.position.x, n.position.z, s, s))
	var plane := PlaneMesh.new()
	plane.size = Vector2(240, 240)
	var sea := MeshInstance3D.new()
	sea.mesh = plane
	sea.material_override = M.sea_material(isles)
	sea.position = Vector3(cx, SEA_Y, cz)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(sea)


func _build_pools() -> void:
	if pools.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 21
	# Wet sand over the floor, with the odd shell or starfish to see through
	# the water.
	var wet: Array[Transform3D] = []
	var stars: Array[Transform3D] = []
	var shells: Array[Transform3D] = []
	for c: Vector2i in pools:
		wet.append(Transform3D(Basis(), Vector3(c.x, -0.003, c.y)))
		var roll: float = r.randf()
		var at := Vector3(c.x + r.randf_range(-0.25, 0.25), 0.012, c.y + r.randf_range(-0.25, 0.25))
		var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3.ONE * 0.8)
		if roll < 0.2:
			stars.append(Transform3D(b, at))
		elif roll < 0.4:
			shells.append(Transform3D(b, at))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.03, 1.0), 0.012), M.WET_SAND, wet)
	arena._multimesh(M.star_mesh(), M.STAR_COLORS[0], stars)
	arena._multimesh(M.shell_mesh(), M.SHELL_COLORS[0], shells)
	# One merged water body (tops plus only the outer sides, so the
	# see-through water shows no seams) and a foam lip round its edge. The
	# whole thing rides up and down with the tide.
	_water = Node3D.new()
	arena.add_child(_water)
	_pool_mat = M.pool_material()
	var body := MeshInstance3D.new()
	body.mesh = _water_mesh()
	body.material_override = _pool_mat
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water.add_child(body)
	_lips = MeshInstance3D.new()
	_lips.mesh = _lip_mesh()
	_lips.material_override = Models.mat(Color("#F4FFFF"), 0.25)
	_lips.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_water.add_child(_lips)


const _SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func _water_mesh() -> ArrayMesh:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var depth: float = 0.36
	for c: Vector2i in pools:
		var x: float = c.x
		var z: float = c.y
		_quad(v, n, Vector3(x - 0.5, 0, z - 0.5), Vector3(x + 0.5, 0, z - 0.5), Vector3(x + 0.5, 0, z + 0.5), Vector3(x - 0.5, 0, z + 0.5), Vector3.UP)
		for d: Vector2i in _SIDES:
			if pools.has(c + d):
				continue
			var nd := Vector3(d.x, 0, d.y)
			var side := Vector3(-d.y, 0, d.x) * 0.5
			var mid := Vector3(x, 0, z) + nd * 0.5
			var down := Vector3(0, -depth, 0)
			_quad(v, n, mid - side, mid + side, mid + side + down, mid - side + down, nd)
	return _commit(v, n)


func _lip_mesh() -> ArrayMesh:
	# A thin foam strip just inside each outer edge of the water.
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var w: float = 0.1
	var h: float = 0.014
	for c: Vector2i in pools:
		for d: Vector2i in _SIDES:
			if pools.has(c + d):
				continue
			var nd := Vector3(d.x, 0, d.y)
			var side := Vector3(-d.y, 0, d.x) * 0.5
			var outer := Vector3(c.x, h, c.y) + nd * 0.5
			var inner := outer - nd * w
			_quad(v, n, outer - side, outer + side, inner + side, inner - side, Vector3.UP)
	return _commit(v, n)


## Adds quad a-b-c-d facing [param normal], whatever order the corners
## come in.
func _quad(v: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
	for tri: Array in [[a, b, c], [a, c, d]]:
		var p0: Vector3 = tri[0]
		var p1: Vector3 = tri[1]
		var p2: Vector3 = tri[2]
		# Godot's front faces wind clockwise: (p2 - p0) x (p1 - p0) faces out.
		if (p2 - p0).cross(p1 - p0).dot(normal) < 0.0:
			var tmp: Vector3 = p1
			p1 = p2
			p2 = tmp
		for p: Vector3 in [p0, p1, p2]:
			v.append(p)
			n.append(normal)


func _commit(v: PackedVector3Array, n: PackedVector3Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = v
	arrays[Mesh.ARRAY_NORMAL] = n
	var mesh := ArrayMesh.new()
	if not v.is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _tag_crabs() -> void:
	var rows: Array = arena.data["map"]
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"crab":
			continue
		var ch: String = String(rows[cr.cell.y])[cr.cell.x]
		var axis := Vector2i(0, 1) if ch == "j" else Vector2i(1, 0)
		cr.node.set_meta(&"axis", axis)
		cr.dir = axis if arena.rng.randf() < 0.5 else -axis


# --- The tide ------------------------------------------------------------------------

func process(delta: float) -> void:
	if pools.is_empty():
		return
	_tide_t += delta
	_update_tide(delta)
	_update_push(delta)
	_float_pods()
	_update_bubbles(delta)
	if _ui != null:
		_ui.visible = not arena.demo and arena.state == &"play" and not arena.get_tree().paused
		if _ui.visible:
			_ui.queue_redraw()


func _update_tide(_delta: float) -> void:
	var period: float = _low + MOVE + _high + MOVE
	var t: float = fmod(_tide_t, period)
	var level: float
	var was: bool = flooded
	if t < _low:
		phase = &"low"
		phase_len = _low
		phase_left = _low - t
		level = LOW_Y
	elif t < _low + MOVE:
		phase = &"rising"
		phase_len = MOVE
		phase_left = _low + MOVE - t
		level = lerpf(LOW_Y, HIGH_Y, _ease(1.0 - phase_left / MOVE))
	elif t < _low + MOVE + _high:
		phase = &"high"
		phase_len = _high
		phase_left = _low + MOVE + _high - t
		level = HIGH_Y
	else:
		phase = &"falling"
		phase_len = MOVE
		phase_left = period - t
		level = lerpf(HIGH_Y, LOW_Y, _ease(1.0 - phase_left / MOVE))
	flooded = phase == &"rising" or phase == &"high"
	warning = (phase == &"low" or phase == &"high") and phase_left < WARN
	var shimmer: float = 0.0
	if warning:
		var u: float = 1.0 - phase_left / WARN
		shimmer = 0.45 + 0.55 * absf(sin(_tide_t * 7.0))
		# The water stirs: a little swell that grows as the change nears.
		level += sin(_tide_t * 9.0) * 0.012 * u + (0.03 * u if phase == &"low" else -0.02 * u)
		if not _was_warning and not arena.demo:
			Sfx.play(&"teleport", 0.0)
	_was_warning = warning
	_level = level
	if _water != null:
		_water.position.y = level
		var fill: float = clampf((level - LOW_Y) / (HIGH_Y - LOW_Y), 0.0, 1.0)
		_pool_mat.set_shader_parameter(&"fill", fill)
		_pool_mat.set_shader_parameter(&"shimmer", shimmer)
		_lips.visible = fill > 0.35
	if flooded and not was:
		_on_flood()
	elif was and not flooded and not arena.demo:
		Sfx.play(&"whoosh", 0.1)


static func _ease(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)


func _on_flood() -> void:
	if arena.demo:
		return
	Sfx.play(&"whoosh", 0.0)
	if arena.hero != null and arena.hero_alive and arena.state == &"play":
		var hc: Vector2i = arena.hero_cell()
		if pools.has(hc):
			_push_from(hc)


## A wave carries Pip from flooded [param from] to the nearest dry tile he
## can stand on, or, if there is none, the water leaves his tile alone.
func _push_from(from: Vector2i) -> void:
	var prev: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	var goal: Vector2i = NO_CELL
	while head < queue.size() and head < 120:
		var c: Vector2i = queue[head]
		head += 1
		if c != from and not pools.has(c) and _dry_free(c):
			goal = c
			break
		var dirs: Array[Vector2i] = _SIDES.duplicate()
		# Try the side Pip is leaning towards first.
		var lean: Vector2 = arena.hero_pos - Vector2(from)
		dirs.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return Vector2(a).dot(lean) > Vector2(b).dot(lean))
		for d: Vector2i in dirs:
			var nx: Vector2i = c + d
			if prev.has(nx) or arena.tile(nx) != Arena.FLOOR:
				continue
			if arena.pod_at.has(nx) and not pools.has(nx):
				continue
			prev[nx] = c
			queue.append(nx)
	if goal == NO_CELL:
		_held = from
		return
	var path: Array[Vector2] = []
	var at: Vector2i = goal
	while at != from:
		path.push_front(Vector2(at))
		at = prev[at]
	_push = path
	arena.walk_goal = Arena.NO_CELL
	arena._spawn_sparkles(Vector3(arena.hero_pos.x, 0.3, arena.hero_pos.y), Color("#BDF3FF"))


func _dry_free(c: Vector2i) -> bool:
	if arena.tile(c) != Arena.FLOOR or arena.pod_at.has(c) or arena.flames.has(c):
		return false
	for cr: Arena.Critter in arena.critters:
		if Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			return false
	return true


func _update_push(delta: float) -> void:
	if arena.hero == null:
		return
	if _held != NO_CELL and arena.hero_cell() != _held:
		_held = NO_CELL
	if _push.is_empty():
		return
	if arena.state != &"play" or not arena.hero_alive:
		_push.clear()
		return
	var target: Vector2 = _push[0]
	arena.hero_pos = arena.hero_pos.move_toward(target, PUSH_SPEED * delta)
	arena.walk_goal = Arena.NO_CELL
	if arena.hero_pos.distance_to(target) < 0.001:
		_push.pop_front()


func _float_pods() -> void:
	var lift: float = maxf(_level - 0.12, 0.0)
	if lift <= 0.0:
		return
	for p: Arena.Pod in arena.pods:
		if pools.has(p.cell) and p.slide == Vector2i.ZERO:
			p.node.position.y = lift + sin(_tide_t * 3.0 + p.cell.x) * 0.02


func _update_bubbles(delta: float) -> void:
	# Little bubbles rise from the pools while a change is coming.
	if warning and not arena.demo:
		_bubble_cd -= delta
		if _bubble_cd <= 0.0 and _bubbles.size() < 40:
			_bubble_cd = 0.07
			var keys: Array = pools.keys()
			var c: Vector2i = keys[arena.rng.randi() % keys.size()]
			var n := Models.part(arena, _bubble_mesh, Color("#E9FDFF"), Vector3(c.x + arena.rng.randf_range(-0.35, 0.35), _level, c.y + arena.rng.randf_range(-0.35, 0.35)), 0.6)
			n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.scale = Vector3.ONE * arena.rng.randf_range(0.6, 1.3)
			_bubbles.append({"node": n, "t": 0.0, "life": arena.rng.randf_range(0.5, 0.8)})
	var keep: Array[Dictionary] = []
	for b: Dictionary in _bubbles:
		b["t"] += delta
		var n: Node3D = b["node"]
		if b["t"] >= b["life"]:
			n.queue_free()
			continue
		n.position.y += delta * 0.7
		n.position.x += sin(b["t"] * 14.0) * delta * 0.15
		var k: float = b["t"] / b["life"]
		n.scale = Vector3.ONE * (0.6 + k * 0.6) * (1.0 - k * k)
		keep.append(b)
	_bubbles = keep


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return flooded and pools.has(c) and c != _held


func on_hero_enter(c: Vector2i) -> void:
	if flooded and pools.has(c) and c != _held and _push.is_empty() and arena.state == &"play":
		_push_from(c)


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if cr.kind == &"crab":
		var d: Vector2i = c - cr.cell
		var axis: Vector2i = cr.node.get_meta(&"axis", Vector2i(1, 0))
		if d != Vector2i.ZERO and d != axis and d != -axis:
			return false
	return true


# --- Critters ----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"crab":
			return M.crab()
		&"boss":
			return M.boss_crab()
		&"blobbit":
			return M.jelly()
		&"buzzer":
			return M.gull()
		&"wisp":
			return M.bubble()
	return null


func critter_speed(kind: StringName) -> float:
	return 1.35 if kind == &"crab" else 1.5


func critter_hp(kind: StringName) -> int:
	return 2 if kind == &"crab" else 1


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"crab":
		return Vector2i.ZERO
	var axis: Vector2i = cr.node.get_meta(&"axis", Vector2i(1, 0))
	var d: Vector2i = cr.dir if (cr.dir == axis or cr.dir == -axis) else axis
	if arena._critter_can_enter(cr, cr.cell + d):
		return d
	if arena._critter_can_enter(cr, cr.cell - d):
		return -d
	return Vector2i.ZERO


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind != &"crab" or cr.hp <= 1:
		return false
	# First blast: the crab flashes, its shell cracks pale and it scuttles
	# off faster. The second one finishes it.
	cr.hp -= 1
	cr.invuln = 1.0
	cr.speed *= 1.4
	var body: Node3D = cr.node.get_node("Body")
	body.scale = Vector3(1.4, 0.6, 1.4)
	body.set_meta(&"flash", 0.3)
	arena._spawn_sparkles(Vector3(cr.pos.x, 0.45, cr.pos.y), Color.WHITE)
	Sfx.play(&"snap", 0.05)
	Save.buzz(25)
	return true


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"crab", &"boss":
			return _pose_crab(cr, body, t, delta)
		&"blobbit":
			body.position.y = 0.04 + sin(t * 2.6) * 0.06
			for k in 4:
				(body.get_node("Tent%d" % k) as Node3D).rotation.x = sin(t * 4.0 + k * 1.6) * 0.35
			var s: float = sin(t * 5.0)
			return Vector3(1.0 + s * 0.05, 1.0 - s * 0.07, 1.0 + s * 0.05)
		&"buzzer":
			body.position.y = sin(t * 5.0) * 0.08
			var flap: float = 0.3 + sin(t * 16.0) * 0.5
			(body.get_node("WingL") as Node3D).rotation.z = -flap
			(body.get_node("WingR") as Node3D).rotation.z = flap
		&"wisp":
			body.position.y = sin(t * 2.2) * 0.1
			body.rotation.z = sin(t * 1.5) * 0.1
			var w: float = sin(t * 3.1)
			return Vector3(1.0 + w * 0.04, 1.0 - w * 0.04, 1.0 + w * 0.04)
	return Vector3.ONE


func _pose_crab(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	var boss: bool = cr.kind == &"boss"
	var n: Node3D = cr.node
	# Crabs face the camera (or the side, walking up and down) whichever way
	# they scuttle.
	var axis: Vector2i = n.get_meta(&"axis", Vector2i(1, 0))
	var want: float = PI * 0.5 if axis.y != 0 else 0.0
	body.rotation.y = wrapf(want - n.rotation.y, -PI, PI)
	var moving: bool = cr.t < 1.0
	var pace: float = 22.0 if not boss else 12.0
	body.rotation.z = sin(t * pace) * (0.07 if moving else 0.0)
	for side: String in ["L", "R"]:
		var legs: Node3D = body.get_node("Legs" + side)
		var k: int = 0
		for leg: Node in legs.get_children():
			(leg as Node3D).rotation.x = sin(t * pace + k * 2.1 + (PI if side == "L" else 0.0)) * (0.45 if moving else 0.05)
			k += 1
		var claw: Node3D = body.get_node("Claw" + side)
		var sgn: float = -1.0 if side == "L" else 1.0
		var snap_rate: float = 7.0 if boss else 4.0
		(claw.get_node("Snap") as Node3D).rotation.x = -absf(sin(t * snap_rate + sgn)) * 0.7
		claw.rotation.z = sgn * (0.15 + sin(t * 2.0 + sgn) * 0.12)
	if not boss:
		var shell: MeshInstance3D = body.get_node("Shell")
		var flash: float = float(body.get_meta(&"flash", 0.0))
		if flash > 0.0:
			flash -= delta
			body.set_meta(&"flash", flash)
			shell.material_override = Models.mat(Color.WHITE, 1.4) if flash > 0.0 else Models.mat(M.CRAB_HURT)
		body.visible = cr.invuln <= 0.0 or fmod(t, 0.14) < 0.09
	var s: float = sin(t * 9.0)
	if boss:
		return Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.05, 1.0)
	return Vector3(1.0 + s * 0.03, 1.0 - s * 0.04, 1.0 + s * 0.03)


# --- The tide chip ------------------------------------------------------------------

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
	var high: bool = phase == &"high" or phase == &"rising"
	var w: float = 330.0
	var h: float = 64.0
	var rect := Rect2(Vector2(vp.x * 0.5 - w * 0.5, vp.y - h - 28.0), Vector2(w, h))
	var blink: bool = warning and fmod(_tide_t, 0.5) < 0.25
	var bg: Color = Color("#BDEFFF") if high else Ui.CREAM
	if blink:
		bg = Color("#FFFFFF") if high else Color("#D7F5FF")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(bg, 0.94)
	sb.set_corner_radius_all(int(h * 0.5))
	sb.anti_aliasing = true
	sb.shadow_color = Ui.SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	_ui.draw_style_box(Ui.glassify(sb), rect)
	# Wave badge: a round tile that fills with water at high tide.
	var c: Vector2 = rect.position + Vector2(h * 0.5 + 4.0, h * 0.5)
	var r: float = h * 0.5 - 8.0
	_ui.draw_circle(c, r, Color("#F3D29B"))
	var fill: float = clampf((_level - LOW_Y) / (HIGH_Y - LOW_Y), 0.0, 1.0)
	var water_top: float = c.y + r * (0.55 - fill * 1.1)
	var disc := PackedVector2Array()
	for k in 32:
		var a: float = TAU * k / 32.0
		disc.append(c + Vector2(cos(a), sin(a)) * (r - 0.5))
	var sea := PackedVector2Array()
	for k in 13:
		var x: float = c.x - r - 2.0 + (2.0 * r + 4.0) * k / 12.0
		sea.append(Vector2(x, water_top + sin(k * 1.1 + _tide_t * 5.0) * 2.5))
	sea.append(c + Vector2(r + 2.0, r + 2.0))
	sea.append(c + Vector2(-r - 2.0, r + 2.0))
	for poly: PackedVector2Array in Geometry2D.intersect_polygons(disc, sea):
		_ui.draw_colored_polygon(poly, Color("#38B6D9"))
	_ui.draw_arc(c, r, 0.0, TAU, 32, Color("#2E8FB8"), 3.0, true)
	# Label and a bar that runs down to the next change.
	var label: String
	match phase:
		&"low":
			label = "TIDE COMING IN!" if warning else "LOW TIDE"
		&"rising":
			label = "TIDE COMING IN!"
		&"high":
			label = "TIDE GOING OUT" if warning else "HIGH TIDE"
		_:
			label = "TIDE GOING OUT"
	var f: Font = Ui.font(900)
	var col: Color = Ui.INK if not (warning or phase == &"rising") else Color("#1E7FB0")
	var tx: float = rect.position.x + h + 8.0
	_ui.draw_string(f, Vector2(tx, rect.position.y + 30.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col)
	var bar := Rect2(Vector2(tx, rect.position.y + 40.0), Vector2(rect.end.x - tx - 26.0, 9.0))
	_ui.draw_rect(bar, Color(Ui.INK, 0.12))
	var u: float = clampf(phase_left / phase_len, 0.0, 1.0) if phase == &"low" or phase == &"high" else 0.0
	if u > 0.0:
		_ui.draw_rect(Rect2(bar.position, Vector2(bar.size.x * u, bar.size.y)), Color("#38B6D9") if high else Color("#E2A85E"))


static func _add(sets: Dictionary, key: String, color: Color, tf: Transform3D) -> void:
	var k: Array = [key, color]
	if not sets.has(k):
		sets[k] = []
	(sets[k] as Array).append(tf)

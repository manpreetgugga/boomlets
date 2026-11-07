extends WorldKit
## World 10, Bramblewood: an overgrown storybook forest of honey-coloured
## leaf-litter paths, tree stumps and toadstools. Its own rules:
##   t        bramble hedge: stops Pip, pods, critters and blasts like a
##            crate, but a blast only burns it back to stubble. A few seconds
##            later green shoots sprout (the warning) and the hedge grows
##            back. It waits while anything stands on it, and never grows
##            back where it would trap Pip with no safe way to blast out.
##   u d l r  bounce mushroom (pointing up, down, left or right): a pod that
##            lands on it, dropped or kicked, is flung two tiles that way,
##            right over a hedge, pillar or wall.
##   s        Sproutling: a little seed sprite that plants a bramble sprout on
##            the tile it has just left every few seconds (three at most).
## The boss, Old Thornroot, wears bramble armour: the first blast only burns
## it off, and it grows back a few seconds later.

const M := preload("res://worlds/world_10_models.gd")

const SHROOM_DIRS: Dictionary = {"u": Vector2i(0, -1), "d": Vector2i(0, 1), "l": Vector2i(-1, 0), "r": Vector2i(1, 0)}
const REGROW: float = 7.0
const SPROUT_TIME: float = 2.2
const POP_TIME: float = 0.3
const PLANT_POOL: int = 16
const PLANT_MAX: int = 3
const LOB_WAIT: float = 0.22
const LOB_TIME: float = 0.42
const SHROOM_LIFT: float = 0.17
const ARMOUR_REGROW: float = 7.0
const ARMOUR_REGROW_HURT: float = 5.5
const ARMOUR_WARN: float = 2.0
## Instances per bramble in each part group (body, tufts, thorns, roses,
## rose cores, stubs, shoots, shoot leaves).
const PART_COUNT: Array[int] = [1, 4, 8, 2, 2, 4, 3, 3]
const HIDDEN := Transform3D(Basis(Vector3(0.0001, 0, 0), Vector3(0, 0.0001, 0), Vector3(0, 0, 0.0001)), Vector3(0, -6, 0))

const LEVELS: Array[Dictionary] = [
	{
		"name": "Briar Lane",
		"tip": "Burn through the bramble hedge...\nbut it grows back! When green shoots\nsprout, hurry on through.",
		"crates": 0.4, "par": 65, "regrow": 7.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#..t.tEt.t..#",
			"#.#.#t#t#.#.#",
			"#.b.......b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#t#t#t#t#t#t#",
			"#___________#",
			"#.#.#.#.#.#.#",
			"#....b.b....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Toadstool Hop",
		"tip": "Drop a pod on a bounce mushroom:\nit boings two tiles the way the\nmushroom leans, right over a wall!",
		"crates": 0.4, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#...t.z.t...#",
			"###.#.#.#.###",
			"#b#.......#b#",
			"#_#l..t..r#_#",
			"#_#.......#_#",
			"###.#.#.#.###",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#..t.....t..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Sproutling Glade",
		"tip": "Sproutlings plant brambles as they go!\nBurn the seedlings before they grow,\nthen blast the Sproutlings!",
		"crates": 0.38, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#t#.#.#t#.#",
			"#..s.....s..#",
			"#.#.#t#t#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#t...s.b...t#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#t#t#.#.#",
			"#..b.....z..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Hedge Maze",
		"tip": "The maze keeps growing back!\nBoing a pod over the hedge\nto reach the critter inside.",
		"crates": 0.3, "par": 90, "regrow": 6.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#B...tEt...B#",
			"#.#t#.#.#t#.#",
			"#.t.z...z.t.#",
			"#.#.#t#t#.#.#",
			"#tt...s...tt#",
			"#.#.#.#.#.#.#",
			"#...rtbtl...#",
			"#.#.#.#.#.#.#",
			"#tt..b.b..tt#",
			"#.#.#t#t#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Wishing Warps",
		"tip": "Swirl pads skip the hedge wall.\nWisps drift through brambles,\nso mind your back!",
		"crates": 0.38, "par": 100, "regrow": 6.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1..t.E.t..2#",
			"#.#.#.#.#.#.#",
			"#t.s.....s.t#",
			"#.#.#t#t#.#.#",
			"#...w...w...#",
			"####t###t####",
			"#.u...z...u.#",
			"#.#.#.#.#.#.#",
			"#2....b....1#",
			"#.#.#.#.#.#.#",
			"#..t.....t..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Thornroot's Hollow",
		"tip": "Old Thornroot wears bramble armour!\nBurn it off, then blast him quick\nbefore it grows back. Eight hits!",
		"crates": 0.22, "par": 125, "boss": true, "regrow": 6.0,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#..t.t..#.#",
			"#...........#",
			"#.t.#...#.t.#",
			"#r....K....l#",
			"#.#..t.t..#.#",
			"#...........#",
			"#.#.#...#.#.#",
			"#...t...t...#",
			"#.t.......t.#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"grown": bool, "t": seconds since burnt, "i": slot, "pop": 0..1
## growing-in animation, "shown": last drawn state key}
var _br: Dictionary = {}
var _start_br: Array[Vector2i] = []
var _free_slots: Array[int] = []
var _slot_parts: Array = []        # slot -> Array of 8 Array[Transform3D]
var _groups: Array[MultiMesh] = []
## Vector2i -> {"dir": Vector2i, "node": Node3D, "bump": float}
var _shrooms: Dictionary = {}
## Pod -> {"wait", "fly", "from": Vector2, "to": Vector2i, "dir": Vector2i}
var _lobs: Dictionary = {}
## Critter -> {"timer", "planted", "pose"}
var _sprouts: Dictionary = {}
var _armour_on: bool = true
var _armour_t: float = 0.0
var _armour_shown: float = 1.0
var _clock: float = 0.0
var _regrow: float = REGROW
var _player: AudioStreamPlayer
var _snd_grow: AudioStreamWAV
var _snd_boing: AudioStreamWAV
var _snd_plant: AudioStreamWAV
var _leaf_mm: Array[MultiMesh] = []
var _leaves: Array = []
var _leaf_bit: Mesh


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Bramblewood"


func palette() -> Variant:
	return {
		"GRASS_A": "#E6D29C", "GRASS_B": "#D9C38A", "RIM": "#78AE52", "EDGE": "#7A5638",
		"STONE": "#EFE3C8", "DARK_STONE": "#C9B48E", "DIRT": "#7E5A3C", "ROCK": "#5E4A3A",
		"WOOD": "#B79CF0", "WOOD_DARK": "#F4ECFF",
		"BLOSSOM_A": "#5DAE4E", "BLOSSOM_B": "#3F8F45", "TRUNK": "#7A5236",
		"LEAFY_A": "#6CBF5A", "LEAFY_B": "#4FA463", "ACCENT": "#FF8FB0",
		"SKY_TOP": "#6CC0B0", "SKY_HORIZON": "#FFE8B4", "SKY_GROUND": "#CFE3C0",
		"CLOUD": "#FFFFFF", "CLOUDS": 0.45, "SUN": "#FFE9C4", "SUN_ENERGY": 1.5,
		"AMBIENT": "#C6DFB6", "AMBIENT_ENERGY": 0.56,
	}


func music() -> String:
	return "res://audio/music/world_10.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "OLD THORNROOT"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"sprout"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "t":
		_br[c] = {"grown": true, "t": 0.0, "i": -1, "pop": 1.0, "shown": ""}
		_start_br.append(c)
		return true
	if SHROOM_DIRS.has(ch):
		_shrooms[c] = {"dir": SHROOM_DIRS[ch], "bump": 0.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"s": &"sprout"}


func _mm(mesh: Mesh, material: Material, transforms: Array[Transform3D], shadow: bool = true) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	return mm


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Moss pads, tiny spotted toadstools and clover on the log-brown wall.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 101
	var top: float = 0.685
	var moss_a: Array[Transform3D] = []
	var moss_b: Array[Transform3D] = []
	var stalks: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var clover: Array[Transform3D] = []
	for tf in blocks:
		var base: Vector3 = tf.origin
		var roll: float = r.randf()
		if roll < 0.5:
			var n0: int = r.randi_range(2, 3)
			var spin: float = r.randf() * TAU
			for k in n0:
				var a0: float = spin + TAU * k / n0
				var s0: float = r.randf_range(0.75, 1.15)
				var b := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s0, s0, s0))
				var at := Vector3(base.x + cos(a0) * 0.13, top + 0.05 * s0, base.z + sin(a0) * 0.13)
				if (k + n0) % 2 == 0:
					moss_a.append(Transform3D(b, at))
				else:
					moss_b.append(Transform3D(b, at))
		if roll < 0.2 or roll > 0.9:
			var n: int = r.randi_range(1, 2)
			for k in n:
				var at2 := Vector3(base.x + r.randf_range(-0.25, 0.25), top, base.z + r.randf_range(-0.25, 0.25))
				var s: float = r.randf_range(0.7, 1.1)
				stalks.append(Transform3D(Basis.from_scale(Vector3.ONE * s), at2 + Vector3(0, 0.07 * s, 0)))
				caps.append(Transform3D(Basis.from_scale(Vector3(s, s * 0.7, s)), at2 + Vector3(0, 0.14 * s, 0)))
		elif roll < 0.4:
			for k in 3:
				var a: float = TAU * k / 3.0 + r.randf()
				clover.append(Transform3D(Basis(Vector3.UP, a), Vector3(base.x + cos(a) * 0.08, top + 0.05, base.z + sin(a) * 0.08)))
	_mm(Models.box_mesh(Vector3(0.22, 0.12, 0.2), 0.05), Models.mat(M.MOSS), moss_a)
	_mm(Models.box_mesh(Vector3(0.18, 0.1, 0.17), 0.045), Models.mat(M.MOSS_DARK), moss_b)
	_mm(Models.cylinder(0.035, 0.045, 0.14, 8), Models.mat(M.STALK), stalks)
	var dome := SphereMesh.new()
	dome.radius = 0.1
	dome.height = 0.1
	dome.is_hemisphere = true
	dome.radial_segments = 12
	dome.rings = 4
	_mm(dome, Models.mat(M.CAP), caps)
	_mm(Models.box_mesh(Vector3(0.12, 0.03, 0.09), 0.012), Models.mat(M.LEAF_C), clover, false)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Tree stumps with growth rings, bark ridges and the odd moss patch.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 107
	var trunks: Array[Transform3D] = []
	var tops: Array[Transform3D] = []
	var rings: Array[Transform3D] = []
	var cores: Array[Transform3D] = []
	var ridges: Array[Transform3D] = []
	var moss: Array[Transform3D] = []
	var roots: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var h: float = r.randf_range(0.66, 0.76)
		var turn: float = r.randf() * TAU
		trunks.append(Transform3D(Basis(Vector3.UP, turn).scaled(Vector3(1, h / 0.7, 1)), p + Vector3(0, h * 0.5, 0)))
		tops.append(Transform3D(Basis(), p + Vector3(0, h + 0.005, 0)))
		rings.append(Transform3D(Basis(), p + Vector3(0, h + 0.01, 0)))
		cores.append(Transform3D(Basis(), p + Vector3(0, h + 0.015, 0)))
		for k in 6:
			var a: float = turn + TAU * k / 6.0
			ridges.append(Transform3D(Basis(Vector3.UP, -a).scaled(Vector3(1, h / 0.7, 1)), p + Vector3(cos(a) * 0.36, h * 0.46, sin(a) * 0.36)))
		for k in 2:
			var a2: float = turn + PI * k + 0.7
			roots.append(Transform3D(Basis(Vector3.UP, -a2), p + Vector3(cos(a2) * 0.36, 0.07, sin(a2) * 0.36)))
		if r.randf() < 0.45:
			moss.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(r.randf_range(-0.1, 0.1), h + 0.04, r.randf_range(-0.1, 0.1))))
	_mm(Models.cylinder(0.34, 0.38, 0.7, 16), Models.mat(M.BARK), trunks)
	_mm(Models.box_mesh(Vector3(0.1, 0.62, 0.08), 0.035), Models.mat(M.BARK_DARK), ridges)
	_mm(Models.box_mesh(Vector3(0.22, 0.14, 0.32), 0.05), Models.mat(M.BARK_DARK), roots)
	_mm(Models.cylinder(0.33, 0.33, 0.04, 18), Models.mat(M.WOOD_TOP), tops)
	_mm(Models.cylinder(0.22, 0.22, 0.042, 16), Models.mat(M.WOOD_RING), rings)
	_mm(Models.cylinder(0.15, 0.15, 0.046, 14), Models.mat(M.WOOD_TOP), cores)
	_mm(Models.box_mesh(Vector3(0.3, 0.06, 0.24), 0.025), Models.mat(M.MOSS), moss)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.2:
			node = M.fern(r, 0.8)
		elif roll < 0.32:
			node = M.toadstool(r.randf_range(0.7, 1.0))
		elif roll < 0.5:
			node = M.flowers(r)
	else:
		if roll < 0.2:
			node = M.story_tree(r, r.randf_range(0.9, 1.25))
		elif roll < 0.3:
			node = M.toadstool(r.randf_range(1.2, 1.8))
		elif roll < 0.42:
			node = M.fern(r, r.randf_range(1.0, 1.4))
		elif roll < 0.47:
			node = M.log_prop(r)
		elif roll < 0.6:
			node = M.flowers(r)
	if node == null:
		return Node3D.new()
	node.rotation.y = r.randf() * TAU
	var holder := Node3D.new()
	node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
	holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var h := M.shroom_house(r, size * 0.45)
	h.position = Vector3(-size * 0.12, 0, -size * 0.05)
	root.add_child(h)
	var t := M.story_tree(r, 1.3)
	t.position = Vector3(size * 0.3, 0, size * 0.15)
	root.add_child(t)
	var ts := M.toadstool(1.4)
	ts.position = Vector3(-size * 0.3, 0, size * 0.3)
	root.add_child(ts)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	# Warm, dappled late-morning light.
	sun.rotation_degrees = Vector3(-58.0, -24.0, 0.0)
	env.glow_intensity = 0.5
	env.adjustment_saturation = 1.1


func build_extra() -> void:
	_regrow = float(arena.data.get("regrow", REGROW))
	_build_brambles()
	for c: Vector2i in _shrooms:
		var s: Dictionary = _shrooms[c]
		var n: Node3D = M.bounce_shroom()
		n.position = Vector3(c.x, 0, c.y)
		var d: Vector2i = s["dir"]
		n.rotation.y = atan2(float(d.x), float(d.y))
		arena.add_child(n)
		s["node"] = n
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_snd_grow = _make_grow()
	_snd_boing = _make_boing()
	_snd_plant = _make_plant()
	_build_leaves()


func _build_brambles() -> void:
	var total: int = _start_br.size() + PLANT_POOL
	var meshes: Array[Mesh] = [M.body_mesh(), M.tuft_mesh(), M.thorn_mesh(), M.rose_mesh(), M.rose_core_mesh(), M.stub_mesh(), M.shoot_mesh(), M.leaf_mesh()]
	var mats: Array[Material] = [Models.mat(M.BRAMBLE), Models.mat(M.BRAMBLE_LIGHT), Models.mat(M.THORN), Models.mat(M.ROSE, 0.15),
		Models.mat(M.ROSE_CORE, 0.3), Models.mat(M.CHAR), Models.mat(M.SHOOT, 0.35), Models.mat(M.SHOOT.lightened(0.15), 0.45)]
	for g in meshes.size():
		var list: Array[Transform3D] = []
		list.resize(total * PART_COUNT[g])
		list.fill(HIDDEN)
		_groups.append(_mm(meshes[g], mats[g], list, g < 5))
	_slot_parts.resize(total)
	for i in range(total - 1, -1, -1):
		_free_slots.append(i)
	for c: Vector2i in _start_br:
		_assign_slot(c)
		_draw(c)


func _assign_slot(c: Vector2i) -> bool:
	if _free_slots.is_empty():
		return false
	var i: int = _free_slots.pop_back()
	var r := RandomNumberGenerator.new()
	r.seed = c.x * 7919 + c.y * 104729 + 17
	_slot_parts[i] = M.bramble_parts(r)
	_br[c]["i"] = i
	return true


# --- Rules --------------------------------------------------------------------------

func _grown(c: Vector2i) -> bool:
	return _br.has(c) and bool(_br[c]["grown"])


func _sprouting(c: Vector2i) -> bool:
	return _br.has(c) and not bool(_br[c]["grown"]) and float(_br[c]["t"]) >= _regrow - SPROUT_TIME


func blocks(c: Vector2i) -> bool:
	return _grown(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if _grown(c) else 0


func on_flame(c: Vector2i) -> void:
	if not _br.has(c):
		return
	var st: Dictionary = _br[c]
	if bool(st["grown"]):
		st["grown"] = false
		st["t"] = 0.0
		_burn_fx(c)
	elif st.get("seed", false):
		# A freshly planted seedling burns away for good.
		_spark(Vector3(c.x, 0.2, c.y), M.SHOOT, 5)
		st["grown"] = true
		st["pop"] = 0.0
		_draw_hidden(int(st["i"]))
		_free_slots.append(int(st["i"]))
		_br.erase(c)
	else:
		# Burning the sprouts sets the clock back.
		if float(st["t"]) > 0.3:
			_spark(Vector3(c.x, 0.2, c.y), M.SHOOT, 4)
		st["t"] = 0.0


func on_hero_enter(c: Vector2i) -> void:
	if _shrooms.has(c):
		_shrooms[c]["bump"] = 1.0
		_sound(_snd_boing, 1.25)


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if not _br.has(c):
		return true
	if cr.kind == &"wisp":
		return true
	return not bool(_br[c]["grown"]) and not _sprouting(c)


func process(delta: float) -> void:
	_clock += delta
	_update_brambles(delta)
	_animate_shrooms(delta)
	_update_leaves(delta)
	if arena.demo:
		return
	_update_lobs(delta)
	_update_sprouts(delta)
	_update_armour(delta)
	_lift_hero()


# --- Brambles -----------------------------------------------------------------------

func _update_brambles(delta: float) -> void:
	for c: Vector2i in _br:
		var st: Dictionary = _br[c]
		if bool(st["grown"]):
			if float(st["pop"]) < 1.0:
				st["pop"] = minf(float(st["pop"]) + delta / POP_TIME, 1.0)
				_draw(c)
			elif st["shown"] != "grown":
				_draw(c)
			continue
		st["t"] = float(st["t"]) + delta
		if float(st["t"]) >= _regrow:
			st["t"] = _regrow
			if _can_grow(c):
				st["grown"] = true
				st["pop"] = 0.0
				st["seed"] = false
				_spark(Vector3(c.x, 0.5, c.y), M.BRAMBLE_LIGHT.lightened(0.2), 6)
				_sound(_snd_grow, randf_range(0.92, 1.08))
		if float(st["t"]) >= _regrow - SPROUT_TIME or st["shown"] != "burnt":
			_draw(c)


## Writes the multimesh transforms of bramble [param c] for its state.
func _draw(c: Vector2i) -> void:
	var st: Dictionary = _br[c]
	var i: int = int(st["i"])
	if i < 0:
		return
	var grown_k: float = 0.0
	var stub_k: float = 0.0
	var shoot_k: float = 0.0
	var wiggle: float = 0.0
	if bool(st["grown"]):
		var u: float = float(st["pop"])
		grown_k = 1.0 if u >= 1.0 else lerpf(0.35, 1.0, u) + sin(u * PI) * 0.22
		shoot_k = maxf(1.0 - u * 2.0, 0.0)
		st["shown"] = "grown" if u >= 1.0 else "pop"
	else:
		stub_k = 0.0 if st.get("seed", false) else 1.0
		var t: float = float(st["t"])
		var start: float = _regrow - SPROUT_TIME
		if t >= start:
			var u2: float = clampf((t - start) / SPROUT_TIME, 0.0, 1.0)
			shoot_k = 0.25 + 0.85 * u2
			wiggle = sin(_clock * (8.0 + u2 * 14.0) + c.x * 1.7) * (0.1 + u2 * 0.2)
			st["shown"] = "sprout"
		else:
			st["shown"] = "burnt"
	var pivot := Vector3(c.x, 0, c.y)
	var parts: Array = _slot_parts[i]
	for g in parts.size():
		var k: float = grown_k if g < 5 else (stub_k if g == 5 else shoot_k)
		var list: Array = parts[g]
		var mm: MultiMesh = _groups[g]
		for j in list.size():
			var idx: int = i * PART_COUNT[g] + j
			if k < 0.02:
				mm.set_instance_transform(idx, HIDDEN)
				continue
			var tf: Transform3D = list[j]
			var b: Basis = Basis.from_scale(Vector3(k, k, k)) * tf.basis
			var o: Vector3 = tf.origin * k
			if g >= 6 and wiggle != 0.0:
				var rot := Basis(Vector3(0, 0, 1), wiggle * (1.0 if j % 2 == 0 else -1.0))
				b = rot * b
				o = rot * o
			mm.set_instance_transform(idx, Transform3D(b, pivot + o))


func _draw_hidden(i: int) -> void:
	if i < 0:
		return
	for g in _groups.size():
		for j in PART_COUNT[g]:
			_groups[g].set_instance_transform(i * PART_COUNT[g] + j, HIDDEN)


## True when the bramble at [param c] may grow back now: nobody stands on it
## and it would not shut Pip in with no safe way to blast out.
func _can_grow(c: Vector2i) -> bool:
	if arena.flames.has(c) or arena.pod_at.has(c) or arena.pickups.has(c):
		return false
	for p: Arena.Pod in arena.pods:
		if p.pos.distance_to(Vector2(c)) < 0.95:
			return false
	for cr: Arena.Critter in arena.critters:
		if cr.pos.distance_to(Vector2(c)) < 0.95 or (cr.t < 1.0 and cr.target == c):
			return false
	if arena.hero == null or arena.demo:
		return true
	if absf(arena.hero_pos.x - c.x) < 0.9 and absf(arena.hero_pos.y - c.y) < 0.9:
		return false
	return _safe_with(c)


func _open(n: Vector2i, extra: Vector2i) -> bool:
	if n == extra or arena.tile(n) != Arena.FLOOR:
		return false
	return not _grown(n)


## Whether Pip is still fine with a bramble at [param extra]: either he can
## still walk to the exit and every critter, or the floor left to him holds
## a spot to drop a pod by something burnable and a spot out of its blast.
func _safe_with(extra: Vector2i) -> bool:
	var start: Vector2i = arena.hero_cell()
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = at + d
			if seen.has(n) or not _open(n, extra):
				continue
			seen[n] = true
			queue.append(n)
			if arena.warps.has(n) and not seen.has(arena.warps[n]):
				seen[arena.warps[n]] = true
				queue.append(arena.warps[n])
	var all_in: bool = arena.exit_cell.x < 0 or seen.has(arena.exit_cell)
	for cr: Arena.Critter in arena.critters:
		if not seen.has(Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))):
			all_in = false
	if all_in:
		return true
	for p: Vector2i in seen:
		var by_burnable: bool = false
		for d: Vector2i in Arena.DIRS:
			var t: int = arena.tile(p + d)
			if t == Arena.CRATE or t == Arena.BARREL or _grown(p + d) or p + d == extra:
				by_burnable = true
		if not by_burnable:
			continue
		var cross: Dictionary = {p: true}
		for d: Vector2i in Arena.DIRS:
			for k in range(1, arena.fire + 1):
				var cc: Vector2i = p + d * k
				if not _open(cc, extra):
					break
				cross[cc] = true
		for q: Vector2i in seen:
			if not cross.has(q):
				return true
	return false


func _burn_fx(c: Vector2i) -> void:
	if arena._fx.size() > 220:
		return
	var at := Vector3(c.x, 0.45, c.y)
	for k in 8:
		var a: float = TAU * k / 8.0 + randf_range(-0.3, 0.3)
		var color: Color = M.BRAMBLE_LIGHT if k % 3 else (M.ROSE if k == 0 else M.CHAR)
		var n: MeshInstance3D = arena.fx_part(M.leaf_mesh(), color, at + Vector3(cos(a) * 0.2, randf_range(-0.1, 0.2), sin(a) * 0.2))
		n.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		arena._fx.append({"node": n, "t": 0.0, "life": randf_range(0.8, 1.1), "kind": &"debris", "floor": 0.05, "pool": true,
			"vel": Vector3(cos(a) * randf_range(1.5, 2.8), randf_range(3.0, 4.8), sin(a) * randf_range(1.5, 2.8)),
			"spin": Vector3(randf_range(-12, 12), randf_range(-12, 12), randf_range(-12, 12))})
	Sfx.play(&"crunch", 0.15)


func _spark(at: Vector3, color: Color, count: int) -> void:
	if arena._fx.size() > 230:
		return
	for k in count:
		var a: float = TAU * k / count
		var n: MeshInstance3D = arena.fx_part(arena._spark_mesh, color, at, 1.2)
		arena._fx.append({"node": n, "t": 0.0, "life": 0.5, "kind": &"spark", "pool": true,
			"vel": Vector3(cos(a) * 1.6, randf_range(1.2, 2.4), sin(a) * 1.6),
			"spin": Vector3(randf_range(-10, 10), randf_range(-10, 10), 0)})


# --- Bounce mushrooms -----------------------------------------------------------------

func _animate_shrooms(delta: float) -> void:
	for c: Vector2i in _shrooms:
		var s: Dictionary = _shrooms[c]
		s["bump"] = maxf(float(s["bump"]) - delta * 3.2, 0.0)
		var b: float = float(s["bump"])
		var cap: Node3D = (s["node"] as Node3D).get_node("Cap")
		var squash: float = sin(b * PI * 2.0) * 0.35 * b
		cap.scale = Vector3(1.0 + squash * 0.5, 1.0 - squash, 1.0 + squash * 0.5)
		cap.position.y = 0.12 - squash * 0.05 + sin(_clock * 2.4 + c.x) * 0.006


## A shroom only flings onto open floor two tiles on (Pip and other pods in
## the way of the landing spot stop it).
func _lob_ok(dest: Vector2i) -> bool:
	if arena.tile(dest) != Arena.FLOOR or blocks(dest) or arena.pod_at.has(dest) or arena.warps.has(dest):
		return false
	if arena.hero != null and arena.hero_alive and arena.hero_pos.distance_to(Vector2(dest)) < 0.75:
		return false
	return true


func _update_lobs(delta: float) -> void:
	for p: Arena.Pod in _lobs.keys():
		if not arena.pods.has(p):
			_lobs.erase(p)
	for p: Arena.Pod in arena.pods:
		if not _lobs.has(p):
			if not _shrooms.has(p.cell):
				continue
			if p.slide != Vector2i.ZERO:
				if p.pos.distance_to(Vector2(p.cell)) > 0.2:
					continue
				p.slide = Vector2i.ZERO
				p.kicked = false
				p.pos = Vector2(p.cell)
			_lobs[p] = {"wait": LOB_WAIT, "fly": -1.0, "from": Vector2(p.cell), "to": p.cell, "dir": _shrooms[p.cell]["dir"]}
			_shrooms[p.cell]["bump"] = 0.6
		var lob: Dictionary = _lobs[p]
		if float(lob["fly"]) < 0.0:
			if not _shrooms.has(p.cell) or p.slide != Vector2i.ZERO:
				_lobs.erase(p)
				continue
			p.node.position.y = SHROOM_LIFT
			lob["wait"] = float(lob["wait"]) - delta
			if float(lob["wait"]) > 0.0:
				continue
			var dest: Vector2i = p.cell + (lob["dir"] as Vector2i) * 2
			if not _lob_ok(dest):
				lob["wait"] = 0.3
				continue
			# Boing!
			_shrooms[p.cell]["bump"] = 1.0
			if arena.pod_at.get(p.cell) == p:
				arena.pod_at.erase(p.cell)
			lob["from"] = Vector2(p.cell)
			lob["to"] = dest
			lob["fly"] = 0.0
			p.cell = dest
			arena.pod_at[dest] = p
			_sound(_snd_boing, randf_range(0.95, 1.05))
		else:
			lob["fly"] = float(lob["fly"]) + delta
			var u: float = minf(float(lob["fly"]) / LOB_TIME, 1.0)
			p.pos = (lob["from"] as Vector2).lerp(Vector2(lob["to"] as Vector2i), u)
			var lift: float = SHROOM_LIFT * (1.0 - u) + (SHROOM_LIFT * u if _shrooms.has(lob["to"]) else 0.0)
			p.node.position = Vector3(p.pos.x, sin(u * PI) * 1.4 + lift, p.pos.y)
			var body: Node3D = p.node.get_node("Body")
			body.rotation.x = u * TAU * (1.0 if (lob["dir"] as Vector2i).y >= 0 else -1.0) * float((lob["dir"] as Vector2i).y != 0)
			body.rotation.z = -u * TAU * float((lob["dir"] as Vector2i).x)
			if u >= 1.0:
				body.rotation = Vector3.ZERO
				p.pos = Vector2(lob["to"] as Vector2i)
				_lobs.erase(p)
				arena._spawn_ring(Vector3(p.pos.x, 0.05, p.pos.y), M.SHOOT, 0.5)
				Sfx.play(&"place", 0.1)


## Lifts Pip (and resting pods) onto a mushroom's cap.
func _lift_hero() -> void:
	if arena.hero == null:
		return
	var c: Vector2i = arena.hero_cell()
	if _shrooms.has(c) and arena.state == &"play":
		var d: float = arena.hero_pos.distance_to(Vector2(c))
		arena.hero.position.y = SHROOM_LIFT * clampf(1.0 - (d - 0.15) * 2.5, 0.0, 1.0)


# --- Sproutlings ---------------------------------------------------------------------

func _sprout_state(cr: Arena.Critter) -> Dictionary:
	if not _sprouts.has(cr):
		_sprouts[cr] = {"timer": randf_range(2.5, 4.0), "planted": 0, "pose": 0.0}
	return _sprouts[cr]


func _update_sprouts(delta: float) -> void:
	for cr: Arena.Critter in _sprouts.keys():
		if not arena.critters.has(cr):
			_sprouts.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"sprout":
			continue
		var s: Dictionary = _sprout_state(cr)
		s["pose"] = maxf(float(s["pose"]) - delta, 0.0)
		s["timer"] = float(s["timer"]) - delta
		if float(s["timer"]) > 0.0 or int(s["planted"]) >= PLANT_MAX:
			continue
		if cr.t > 0.45 and cr.t < 0.95 and cr.cell != cr.target and _can_plant(cr.cell):
			_plant(cr.cell)
			s["planted"] = int(s["planted"]) + 1
			s["timer"] = randf_range(4.5, 6.5)
			s["pose"] = 0.45
		else:
			s["timer"] = 0.25


func _can_plant(c: Vector2i) -> bool:
	if _free_slots.is_empty() or _br.has(c) or _shrooms.has(c):
		return false
	if arena.tile(c) != Arena.FLOOR or arena.warps.has(c) or arena.belts.has(c):
		return false
	if c == arena.exit_cell or c == arena.start_cell or arena.pickups.has(c) or arena.pod_at.has(c):
		return false
	var h: Vector2i = arena.hero_cell()
	return absi(h.x - c.x) + absi(h.y - c.y) >= 2


func _plant(c: Vector2i) -> void:
	_br[c] = {"grown": false, "t": _regrow - SPROUT_TIME, "i": -1, "pop": 1.0, "shown": "", "seed": true}
	_assign_slot(c)
	_draw(c)
	_spark(Vector3(c.x, 0.25, c.y), M.SHOOT, 6)
	_sound(_snd_plant, randf_range(0.95, 1.1))


# --- Old Thornroot's armour ----------------------------------------------------------

func _update_armour(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or _armour_on:
		return
	_armour_t += delta
	var need: float = ARMOUR_REGROW if b.hp > 4 else ARMOUR_REGROW_HURT
	if _armour_t >= need:
		_armour_on = true
		_spark(arena._to3(b.pos, 0.8), M.BRAMBLE_LIGHT.lightened(0.25), 10)
		_sound(_snd_grow, 0.7)


func _armour_level() -> float:
	if _armour_on:
		return 1.0
	var b: Arena.Critter = arena.boss
	var need: float = ARMOUR_REGROW if b == null or b.hp > 4 else ARMOUR_REGROW_HURT
	var u: float = (_armour_t - (need - ARMOUR_WARN)) / ARMOUR_WARN
	if u <= 0.0:
		return 0.0
	return 0.2 + 0.6 * clampf(u, 0.0, 1.0)


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind != &"boss" or not _armour_on:
		return false
	# The blast only burns the armour away.
	_armour_on = false
	_armour_t = 0.0
	cr.invuln = 0.75
	for k in 3:
		_burn_fx(Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)))
	arena._shake = maxf(arena._shake, 0.22)
	cr.node.get_node("Body").scale = Vector3(1.15, 0.9, 1.15)
	return true


# --- Critters ----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"sprout":
			return M.sproutling()
		&"boss":
			return M.thornroot()
	return null


func critter_speed(kind: StringName) -> float:
	return 1.75 if kind == &"sprout" else 1.5


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	if cr.kind == &"sprout":
		var s: Dictionary = _sprout_state(cr)
		var bud: Node3D = body.get_node("Bud")
		var planting: float = float(s["pose"])
		bud.rotation.z = sin(t * 3.2) * 0.18
		body.get_node("ArmL").rotation.z = sin(t * 8.0) * 0.3
		body.get_node("ArmR").rotation.z = -sin(t * 8.0) * 0.3
		if planting > 0.0:
			body.rotation.x = lerpf(body.rotation.x, 0.5, minf(delta * 12.0, 1.0))
			body.position.y = 0.0
			return Vector3(1.1, 0.88, 1.1) * M.SPROUT_SIZE
		body.rotation.x = lerpf(body.rotation.x, 0.0, minf(delta * 8.0, 1.0))
		body.position.y = absf(sin(t * 9.0)) * 0.07
		return Vector3.ONE * M.SPROUT_SIZE
	if cr.kind == &"boss":
		var armour: Node3D = body.get_node("Armour")
		var k: float = _armour_level()
		var flick: bool = not _armour_on and k > 0.0 and fmod(_clock, 0.24) < 0.08
		_armour_shown = lerpf(_armour_shown, k, minf(delta * 10.0, 1.0))
		armour.visible = _armour_shown > 0.04 and not flick
		armour.scale = Vector3(1.0, maxf(_armour_shown, 0.05), 1.0) * (0.9 + 0.1 * _armour_shown)
		body.get_node("ArmL").rotation.z = sin(t * 3.0) * 0.25
		body.get_node("ArmR").rotation.z = -sin(t * 3.0 + 0.6) * 0.25
		body.get_node("Crown").rotation.z = sin(t * 2.2) * 0.06
		return Vector3(1.0, 1.0 + absf(sin(t * 3.5)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- Falling leaves -------------------------------------------------------------------

func _build_leaves() -> void:
	_leaf_bit = Models.box_mesh(Vector3(0.13, 0.02, 0.08), 0.01)
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	var colors: Array[Color] = [Color("#F2A541"), M.LEAF_C, Color("#E8734A")]
	var per: int = 5
	for g in 3:
		var list: Array[Transform3D] = []
		for k in per:
			list.append(HIDDEN)
			_leaves.append({"g": g, "i": k, "x": r.randf_range(-2.0, Arena.W + 1.0), "z": r.randf_range(-2.0, Arena.H + 1.0),
				"y": r.randf_range(0.0, 5.0), "ph": r.randf() * TAU, "sp": r.randf_range(0.45, 0.7)})
		_leaf_mm.append(_mm(_leaf_bit, Models.mat(colors[g]), list, false))


func _update_leaves(delta: float) -> void:
	for l: Dictionary in _leaves:
		l["y"] = float(l["y"]) - delta * float(l["sp"])
		if float(l["y"]) < 0.05:
			l["y"] = 5.0
			l["x"] = randf_range(-2.0, Arena.W + 1.0)
			l["z"] = randf_range(-2.0, Arena.H + 1.0)
		var ph: float = float(l["ph"]) + _clock * 1.6
		var at := Vector3(float(l["x"]) + sin(ph) * 0.5, float(l["y"]), float(l["z"]) + cos(ph * 0.7) * 0.3)
		var b := Basis(Vector3.UP, ph) * Basis(Vector3.RIGHT, sin(ph * 1.3) * 0.8)
		(_leaf_mm[int(l["g"])] as MultiMesh).set_instance_transform(int(l["i"]), Transform3D(b, at))


# --- Sound --------------------------------------------------------------------------

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


## A leafy rustle that ends in a soft woody pop: a hedge growing back.
func _make_grow() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.38)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		lp = lp * 0.7 + randf_range(-1.0, 1.0) * 0.3
		var rustle: float = lp * minf(t / 0.02, 1.0) * exp(-t * 7.0) * (0.6 + 0.4 * sin(t * 90.0))
		var pt: float = t - 0.2
		var pop: float = 0.0
		if pt > 0.0:
			phase += TAU * (520.0 - 260.0 * minf(pt / 0.08, 1.0)) / rate
			pop = sin(phase) * exp(-pt * 30.0)
		out[i] = (rustle * 0.7 + pop * 0.6) * 0.6
	return _wav(out)


## A springy "boing" for a bounce mushroom.
func _make_boing() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 220.0 + 340.0 * minf(t / 0.12, 1.0) + sin(t * TAU * 22.0) * 30.0 * exp(-t * 6.0)
		phase += TAU * f / rate
		var env: float = minf(t / 0.004, 1.0) * exp(-t * 9.0)
		out[i] = (sin(phase) + 0.25 * sin(phase * 2.0)) * env * 0.5
	return _wav(out)


## A tiny bright "plink" when a Sproutling plants a seed.
func _make_plant() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var f: float = 1320.0 if t < 0.07 else 1760.0
		var tt: float = t if t < 0.07 else t - 0.07
		out[i] = sin(TAU * f * t) * minf(tt / 0.003, 1.0) * exp(-tt * 28.0) * 0.4
	return _wav(out)

extends WorldKit
## World 11, Spooky Hollow: a friendly Halloween village at dusk, all lavender
## lanes, lantern light and plum stone. Its own rules:
##   J  jack-o'-lantern: blocks Pip, pods, critters and blasts. A blast lights
##      it; its face glows hot, the tiles it will hit glow orange, and one
##      second later it blasts back (a cross two tiles long). Lanterns light
##      each other, so a row of them goes off one after another. After it
##      echoes a lantern rests for a moment and can't be relit.
##   g  little sheet ghost: fades in and out. While faded it is harmless and
##      blasts pass right through it. Pumpkins glow: a ghost next to one, or
##      near a lit one, is always solid.
## The boss, King Gourdy, blasts back one second after each hit, and once
## he's hurt he lights every lantern in his court with a spell.

const M := preload("res://worlds/world_11_models.gd")

const ECHO_DELAY: float = 1.0
const SPELL_DELAY: float = 1.6
const COOLDOWN: float = 2.5
const FLARE: float = 0.7
const ECHO_REACH: int = 2
const GHOST_SOLID: float = 3.2
const GHOST_FADED: float = 2.4
const GHOST_WARN: float = 0.45
const BOSS_ECHO_REACH: int = 2
const SPELL_EVERY: float = 9.0
const SPELL_HP: int = 5
const WARN_POOL: int = 160
const BAT_COUNT: int = 5
const HIDDEN := Transform3D(Basis(Vector3(0.0001, 0, 0), Vector3(0, 0.0001, 0), Vector3(0, 0, 0.0001)), Vector3(0, -6, 0))

const LEVELS: Array[Dictionary] = [
	{
		"name": "Lantern Lane",
		"tip": "Blast a jack-o'-lantern to light it.\nOne second later it blasts back!\nStay off the glowing tiles.",
		"crates": 0.4, "par": 65,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"###.#.#.#.###",
			"#b_J.....J_b#",
			"###.#.#.#.###",
			"#....b.b....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Peekaboo Path",
		"tip": "Ghosts fade in and out! Blast them\nwhile they're solid, or when they\nfloat beside a glowing pumpkin.",
		"crates": 0.4, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.J..g.g..J.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#J#J#.#.#",
			"#..g.....g..#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#J#.#.#J#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Pumpkin Patch",
		"tip": "Lanterns light each other!\nOne blast can set off a whole row,\nso stand well clear of the chain.",
		"crates": 0.36, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..b.....g..#",
			"#.#.#.#.#.#.#",
			"#g....z....g#",
			"#.#.#.#.#.#.#",
			"#.J_J_J_J_J.#",
			"#.#.#.#.#.#.#",
			"#...g...b...#",
			"#.#.#.#.#.#.#",
			"#J.........J#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Haunted Mill",
		"tip": "Lanterns light barrels...\nand barrels light lanterns!\nPlan your getaway first.",
		"crates": 0.32, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#B....E....B#",
			"#.#.#.#.#.#.#",
			"#...g...g...#",
			"#.#J#.#.#J#.#",
			"#.....b.....#",
			"#J#.#.#.#.#J#",
			"#..g..J..g..#",
			"#.#.#.#.#.#.#",
			"#...z...b...#",
			"#.#J#.#.#J#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Moonlit Warps",
		"tip": "Swirl pads hop the old wall.\nA lantern set in the wall blasts\nboth sides of it!",
		"crates": 0.36, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1...gE....2#",
			"#.#.#.#.#.#.#",
			"#.J.......J.#",
			"#.#.#.#.#.#.#",
			"#...g...g...#",
			"####J###J####",
			"#..g.....g..#",
			"#.#.#.#.#.#.#",
			"#2...z.b...1#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "King Gourdy's Court",
		"tip": "King Gourdy blasts back when hit!\nHop out of his glowing cross, and\nwatch out when he lights the lanterns.",
		"crates": 0.2, "par": 125, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.J...J.#.#",
			"#...........#",
			"#.J.#...#.J.#",
			"#.....K.....#",
			"#.#.......#.#",
			"#...J...J...#",
			"#.#.#...#.#.#",
			"#...........#",
			"#.J.......J.#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"state": 0 idle / 1 lit / 2 resting, "t": seconds left in
## that state, "flare": reveal time after echoing, "node", "face", "shown"}
var _jacks: Dictionary = {}
## Critter -> {"cycle", "solid", "meshes": [[MeshInstance3D, solid, faded]], "shown"}
var _ghosts: Dictionary = {}
## Pending boss echoes: [{"c": Vector2i, "t": float}]
var _boss_echo: Array = []
var _spell_t: float = 6.0
var _spell_pose: float = 0.0
var _clock: float = 0.0
var _warn_mm: MultiMesh
var _warn_used: int = 0
var _bats: Array = []
var _player: AudioStreamPlayer
var _snd_light: AudioStreamWAV
var _snd_spell: AudioStreamWAV
var _snd_boo: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Spooky Hollow"


func palette() -> Variant:
	return {
		"GRASS_A": "#B9A2E6", "GRASS_B": "#AA92DC", "RIM": "#7E62B8", "EDGE": "#3E2C62",
		"STONE": "#D8CCF0", "DARK_STONE": "#A894CE", "DIRT": "#5B4380", "ROCK": "#4A3A68",
		"WOOD": "#8FE35A", "WOOD_DARK": "#F4FFE0", "POD": "#2E2440",
		"BLOBBIT": "#FF7FA8",
		"BLOSSOM_A": "#FF9A3C", "BLOSSOM_B": "#9A6CD0", "TRUNK": "#5A4470",
		"LEAFY_A": "#9A7CD6", "LEAFY_B": "#7A5CB8", "ACCENT": "#FF9A3C",
		"SKY_TOP": "#3B2A6E", "SKY_HORIZON": "#FF9E6E", "SKY_GROUND": "#7A5A9E",
		"CLOUD": "#F2C6E6", "CLOUDS": 0.35, "SUN": "#FFD2B0", "SUN_ENERGY": 1.3,
		"AMBIENT": "#A58FE0", "AMBIENT_ENERGY": 0.5,
	}


func music() -> String:
	return "res://audio/music/world_11.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "KING GOURDY"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"ghost"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "J":
		_jacks[c] = {"state": 0, "t": 0.0, "flare": 0.0, "shown": -1}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"g": &"ghost"}


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


## Candle clusters, lamp globes and tiny pumpkins along the plum wall.
func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 111
	var top: float = 0.685
	var candles: Array[Transform3D] = []
	var flames: Array[Transform3D] = []
	var stubs: Array[Transform3D] = []
	var globes: Array[Transform3D] = []
	var minis: Array[Transform3D] = []
	var stems: Array[Transform3D] = []
	for tf in blocks:
		var base: Vector3 = tf.origin
		var roll: float = r.randf()
		if roll < 0.3:
			var n: int = r.randi_range(2, 3)
			var spin: float = r.randf() * TAU
			for k in n:
				var a: float = spin + TAU * k / n
				var h: float = r.randf_range(0.6, 1.1)
				var at := Vector3(base.x + cos(a) * 0.12, top, base.z + sin(a) * 0.12)
				candles.append(Transform3D(Basis.from_scale(Vector3(1, h, 1)), at + Vector3(0, 0.11 * h, 0)))
				flames.append(Transform3D(Basis.from_scale(Vector3(1, 1.6, 1)), at + Vector3(0, 0.22 * h + 0.06, 0)))
		elif roll < 0.4:
			stubs.append(Transform3D(Basis(), Vector3(base.x, top + 0.13, base.z)))
			globes.append(Transform3D(Basis(), Vector3(base.x, top + 0.3, base.z)))
		elif roll < 0.52:
			var s: float = r.randf_range(0.8, 1.15)
			var at2 := Vector3(base.x + r.randf_range(-0.12, 0.12), top, base.z + r.randf_range(-0.12, 0.12))
			minis.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s * 0.72, s)), at2 + Vector3(0, 0.08 * s, 0)))
			stems.append(Transform3D(Basis(Vector3.FORWARD, r.randf_range(-0.3, 0.3)), at2 + Vector3(0, 0.17 * s, 0)))
	_mm(Models.cylinder(0.055, 0.062, 0.22, 10), Models.mat(M.CANDLE), candles)
	_mm(Models.sphere(0.05, -1, 8), Models.mat(M.CANDLE_FLAME, 1.6), flames, false)
	_mm(Models.cylinder(0.03, 0.04, 0.26, 8), Models.mat(M.IRON), stubs)
	_mm(Models.sphere(0.1, 0.2, 14), Models.mat(M.LAMP, 1.3), globes, false)
	_mm(Models.sphere(0.12, 0.22, 14), Models.mat(M.PUMPKIN), minis)
	_mm(Models.cylinder(0.02, 0.03, 0.08, 6), Models.mat(M.STEM), stems)
	return true


## Plum stone pillars with a pale cap; some carry a candle or a tiny pumpkin.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 113
	var bodies: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var candles: Array[Transform3D] = []
	var flames: Array[Transform3D] = []
	var minis: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var turn: float = r.randf_range(-0.06, 0.06)
		bodies.append(Transform3D(Basis(Vector3.UP, turn), p + Vector3(0, 0.33, 0)))
		caps.append(Transform3D(Basis(Vector3.UP, turn), p + Vector3(0, 0.69, 0)))
		bands.append(Transform3D(Basis(Vector3.UP, turn), p + Vector3(0, 0.08, 0)))
		var roll: float = r.randf()
		if roll < 0.28:
			var at := p + Vector3(r.randf_range(-0.15, 0.15), 0.73, r.randf_range(-0.15, 0.15))
			candles.append(Transform3D(Basis(), at + Vector3(0, 0.11, 0)))
			flames.append(Transform3D(Basis.from_scale(Vector3(1, 1.6, 1)), at + Vector3(0, 0.28, 0)))
		elif roll < 0.4:
			minis.append(Transform3D(Basis.from_scale(Vector3(1, 0.72, 1)), p + Vector3(0, 0.81, 0)))
	_mm(Models.box_mesh(Vector3(0.8, 0.66, 0.8), 0.1), Models.mat(M.STONE), bodies)
	_mm(Models.box_mesh(Vector3(0.9, 0.1, 0.9), 0.045), Models.mat(M.STONE_TOP), caps)
	_mm(Models.box_mesh(Vector3(0.86, 0.12, 0.86), 0.05), Models.mat(M.STONE_DARK), bands)
	_mm(Models.cylinder(0.055, 0.062, 0.22, 10), Models.mat(M.CANDLE), candles)
	_mm(Models.sphere(0.05, -1, 8), Models.mat(M.CANDLE_FLAME, 1.6), flames, false)
	_mm(Models.sphere(0.12, 0.22, 14), Models.mat(M.PUMPKIN), minis)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.22:
			node = M.pumpkin_patch(r)
		elif roll < 0.3:
			node = M.hay_bale(r)
	else:
		if roll < 0.16:
			node = M.cottage(r, r.randf_range(0.95, 1.2))
		elif roll < 0.32:
			node = M.autumn_tree(r, r.randf_range(0.9, 1.25))
		elif roll < 0.4:
			node = M.lamp_post(r.randf_range(0.9, 1.1))
		elif roll < 0.5:
			node = M.pumpkin_patch(r)
		elif roll < 0.56:
			node = M.hay_bale(r)
	if node == null:
		return Node3D.new()
	node.rotation.y = r.randf_range(-0.6, 0.6)
	var holder := Node3D.new()
	node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
	holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var t := M.witch_tower(r, size * 0.42)
	t.position = Vector3(-size * 0.1, 0, -size * 0.05)
	root.add_child(t)
	var tree := M.autumn_tree(r, 1.3)
	tree.position = Vector3(size * 0.3, 0, size * 0.12)
	root.add_child(tree)
	var patch := M.pumpkin_patch(r)
	patch.position = Vector3(-size * 0.28, 0, size * 0.3)
	patch.scale = Vector3.ONE * 1.6
	root.add_child(patch)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	# Warm low dusk light, with lantern glow.
	sun.rotation_degrees = Vector3(-52.0, -32.0, 0.0)
	env.glow_intensity = 0.7
	env.adjustment_saturation = 1.08


func build_extra() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 7
	for c: Vector2i in _jacks:
		var n: Node3D = M.jack(r)
		n.position = Vector3(c.x, 0, c.y)
		n.rotation.y = r.randf_range(-0.25, 0.25)
		arena.add_child(n)
		var j: Dictionary = _jacks[c]
		j["node"] = n
		j["face"] = n.get_node("Body/Face")
		j["ph"] = r.randf() * TAU
	var list: Array[Transform3D] = []
	list.resize(WARN_POOL)
	list.fill(HIDDEN)
	_warn_mm = _mm(Models.box_mesh(Vector3(0.82, 0.04, 0.82), 0.08), Models.glass(Color("#FF9A3C"), 0.55, 0.6), list, false)
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_snd_light = _make_light()
	_snd_spell = _make_spell()
	_snd_boo = _make_boo()
	_build_bats()


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return _jacks.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if _jacks.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if _jacks.has(c):
		_light(c, ECHO_DELAY)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not _jacks.has(c)


func _light(c: Vector2i, delay: float) -> void:
	var j: Dictionary = _jacks[c]
	if int(j["state"]) != 0:
		return
	j["state"] = 1
	j["t"] = delay
	j["total"] = delay
	_spark(Vector3(c.x, 0.7, c.y), M.FACE_HOT, 6)
	_sound(_snd_light, randf_range(0.95, 1.1))


func process(delta: float) -> void:
	_clock += delta
	_update_jacks(delta)
	_update_boss(delta)
	_update_warnings()
	_update_bats(delta)
	_update_ghosts(delta)


func _update_jacks(delta: float) -> void:
	for c: Vector2i in _jacks:
		var j: Dictionary = _jacks[c]
		j["flare"] = maxf(float(j["flare"]) - delta, 0.0)
		var st: int = int(j["state"])
		if st == 1:
			j["t"] = float(j["t"]) - delta
			if float(j["t"]) <= 0.0:
				_echo(c)
		elif st == 2:
			j["t"] = float(j["t"]) - delta
			if float(j["t"]) <= 0.0:
				j["state"] = 0
		_pose_jack(c, j)


func _echo(c: Vector2i) -> void:
	var j: Dictionary = _jacks[c]
	j["state"] = 2
	j["t"] = COOLDOWN
	j["flare"] = FLARE
	var reach: int = int(arena.data.get("echo", ECHO_REACH))
	_boom(c, reach)
	(j["node"] as Node3D).get_node("Body").scale = Vector3(1.3, 0.75, 1.3)


func _boom(c: Vector2i, reach: int) -> void:
	arena._blast(c, reach)
	arena._spawn_ring(Vector3(c.x, 0.06, c.y), M.FACE, 1.0 + reach * 0.4)
	Sfx.play(&"boom", 0.12)
	arena._shake = maxf(arena._shake, 0.25)


func _pose_jack(c: Vector2i, j: Dictionary) -> void:
	var node: Node3D = j["node"]
	var body: Node3D = node.get_node("Body")
	var st: int = int(j["state"])
	var ph: float = float(j.get("ph", 0.0))
	var target := Vector3.ONE
	if st == 1:
		# Swelling and shaking faster as the echo nears.
		var u: float = 1.0 - float(j["t"]) / maxf(float(j.get("total", ECHO_DELAY)), 0.01)
		var wob: float = sin(_clock * (14.0 + u * 30.0)) * (0.03 + u * 0.06)
		target = Vector3(1.0 + u * 0.12 + wob, 1.0 + u * 0.1 - wob, 1.0 + u * 0.12 + wob)
		body.rotation.z = sin(_clock * 23.0) * 0.06 * u
		if randf() < 0.25 and arena._fx.size() < 200:
			_spark(Vector3(c.x, 0.75, c.y), M.CANDLE_FLAME, 1)
	else:
		var breathe: float = sin(_clock * 1.8 + ph) * 0.015
		target = Vector3(1.0 + breathe, 1.0 - breathe, 1.0 + breathe)
		body.rotation.z = lerpf(body.rotation.z, 0.0, 0.2)
	body.scale = body.scale.lerp(target, 0.25)
	var want: int = st
	if st == 1 and float(j["t"]) < 0.35 and fmod(_clock, 0.12) < 0.05:
		want = 3
	if want != int(j["shown"]):
		j["shown"] = want
		var mat: Material
		match want:
			1:
				mat = Models.mat(M.FACE_HOT, 1.8)
			2:
				mat = Models.mat(M.FACE_SPENT, 0.0)
			3:
				mat = Models.mat(Color.WHITE, 2.0)
			_:
				mat = Models.mat(M.FACE, 0.5)
		for mi: Node in (j["face"] as Node3D).get_children():
			(mi as MeshInstance3D).material_override = mat


## The tiles a blast from [param c] would reach, matching Arena._blast.
func _cross(c: Vector2i, reach: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not _jacks.has(c):
		out.append(c)
	for d: Vector2i in Arena.DIRS:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			var t: int = arena.tile(cc)
			if t == Arena.WALL:
				break
			if _jacks.has(cc):
				break
			out.append(cc)
			if t == Arena.CRATE or t == Arena.BARREL or arena.pod_at.has(cc):
				break
	return out


## Glowing orange plates under everything a lit lantern (or the king) is
## about to blast.
func _update_warnings() -> void:
	var cells: Dictionary = {}
	var reach: int = int(arena.data.get("echo", ECHO_REACH))
	for c: Vector2i in _jacks:
		var j: Dictionary = _jacks[c]
		if int(j["state"]) == 1:
			var u: float = 1.0 - float(j["t"]) / maxf(float(j.get("total", ECHO_DELAY)), 0.01)
			for cc: Vector2i in _cross(c, reach):
				cells[cc] = maxf(float(cells.get(cc, 0.0)), u)
	for e: Dictionary in _boss_echo:
		var u2: float = 1.0 - float(e["t"]) / ECHO_DELAY
		for cc: Vector2i in _cross(e["c"], BOSS_ECHO_REACH):
			cells[cc] = maxf(float(cells.get(cc, 0.0)), u2)
	var i: int = 0
	for cc: Vector2i in cells:
		if i >= WARN_POOL:
			break
		var u3: float = float(cells[cc])
		var s: float = 0.55 + 0.4 * u3 + sin(_clock * 18.0) * 0.04
		_warn_mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(s, 1.0, s)), Vector3(cc.x, 0.03, cc.y)))
		i += 1
	for k in range(i, _warn_used):
		_warn_mm.set_instance_transform(k, HIDDEN)
	_warn_used = i


# --- Ghosts -------------------------------------------------------------------------

func _ghost_state(cr: Arena.Critter) -> Dictionary:
	if not _ghosts.has(cr):
		var period: float = GHOST_SOLID + GHOST_FADED
		_ghosts[cr] = {"cycle": randf() * period, "solid": true, "meshes": [], "shown": -1}
	return _ghosts[cr]


## A ghost glows solid beside any lantern, or within two tiles of a lit one.
func _lantern_near(c: Vector2i) -> bool:
	for jc: Vector2i in _jacks:
		var d: int = maxi(absi(jc.x - c.x), absi(jc.y - c.y))
		if d <= 1:
			return true
		var j: Dictionary = _jacks[jc]
		if d <= 2 and (int(j["state"]) == 1 or float(j["flare"]) > 0.0):
			return true
	return false


func _update_ghosts(delta: float) -> void:
	for cr: Arena.Critter in _ghosts.keys():
		if not arena.critters.has(cr):
			_ghosts.erase(cr)
	var period: float = GHOST_SOLID + GHOST_FADED
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"ghost":
			continue
		var g: Dictionary = _ghost_state(cr)
		g["cycle"] = fmod(float(g["cycle"]) + delta, period)
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		var want: bool = float(g["cycle"]) < GHOST_SOLID or _lantern_near(here)
		if want and not bool(g["solid"]) and not arena.demo and arena.hero_alive:
			# Never pop solid right on top of Pip.
			if cr.pos.distance_to(arena.hero_pos) < 0.95:
				want = false
		if want and not bool(g["solid"]) and not arena.demo and arena.hero_alive:
			if cr.pos.distance_to(arena.hero_pos) < 4.0:
				_sound(_snd_boo, randf_range(0.95, 1.15))
		g["solid"] = want


func critter_hidden(cr: Arena.Critter) -> bool:
	if cr.kind != &"ghost":
		return false
	return not bool(_ghost_state(cr)["solid"])


## Solid ghosts drift towards Pip when he's close; faded ones wander.
func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"ghost" or arena.demo or not arena.hero_alive:
		return Vector2i.ZERO
	if not bool(_ghost_state(cr)["solid"]):
		return Vector2i.ZERO
	var h: Vector2i = arena.hero_cell()
	if absi(h.x - cr.cell.x) + absi(h.y - cr.cell.y) > 5:
		return Vector2i.ZERO
	if randf() < 0.3:
		return Vector2i.ZERO
	return arena._path_step(cr, h)


func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"ghost":
			return M.ghost()
		&"boss":
			return M.king_gourdy()
	return null


func critter_speed(kind: StringName) -> float:
	return 1.6 if kind == &"ghost" else 1.2


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind == &"boss" and cr.invuln <= 0.0 and cr.hp > 1:
		# He blasts back from where he was hit, one second later.
		_boss_echo.append({"c": Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)), "t": ECHO_DELAY})
	return false


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	if cr.kind == &"ghost":
		var g: Dictionary = _ghost_state(cr)
		if (g["meshes"] as Array).is_empty():
			for n: Node in body.find_children("*", "MeshInstance3D", true, false):
				var mi := n as MeshInstance3D
				var col: Color = (mi.material_override as ShaderMaterial).get_shader_parameter(&"albedo")
				var dark: bool = col.get_luminance() < 0.5
				var faded: Material = Models.glass(col.lerp(M.GHOST_TINT, 0.0 if dark else 0.35), 0.75 if dark else 0.12, 0.25)
				(g["meshes"] as Array).append([mi, mi.material_override, faded])
		var solid: bool = bool(g["solid"])
		var show: bool = solid
		var period: float = GHOST_SOLID + GHOST_FADED
		var cyc: float = float(g["cycle"])
		# Flicker just before fading in.
		if not solid and cyc > period - GHOST_WARN and fmod(_clock, 0.14) < 0.06:
			show = true
		var want: int = 1 if show else 0
		if want != int(g["shown"]):
			g["shown"] = want
			for e: Array in g["meshes"]:
				(e[0] as MeshInstance3D).material_override = e[1] if show else e[2]
		var lift: float = 0.06 if solid else 0.2
		body.position.y = lerpf(body.position.y, lift + sin(t * 2.6) * 0.07, minf(delta * 6.0, 1.0))
		body.rotation.z = sin(t * 1.9) * 0.12
		body.get_node("ArmL").position.y = 0.42 + sin(t * 5.0) * 0.05
		body.get_node("ArmR").position.y = 0.42 - sin(t * 5.0) * 0.05
		var squish: float = sin(t * 5.2) * 0.04
		return Vector3(1.0 + squish, 1.0 - squish, 1.0 + squish) * M.GHOST_SIZE
	if cr.kind == &"boss":
		var hot: bool = not _boss_echo.is_empty() or _spell_pose > 0.0
		var face: Node3D = body.get_node("Face")
		var want_b: int = 1 if hot and fmod(_clock, 0.2) < 0.13 else 0
		if int(face.get_meta(&"shown", -1)) != want_b:
			face.set_meta(&"shown", want_b)
			var mat: Material = Models.mat(M.FACE_HOT, 1.9) if want_b == 1 else Models.mat(M.FACE, 0.7)
			for mi: Node in face.get_children():
				(mi as MeshInstance3D).material_override = mat
		var raise: float = clampf(_spell_pose, 0.0, 1.0)
		body.get_node("ArmL").rotation.z = sin(t * 3.0) * 0.25 - raise * 1.2
		body.get_node("ArmR").rotation.z = -sin(t * 3.0 + 0.6) * 0.25 + raise * 1.2
		body.get_node("Crown").rotation.z = 0.12 + sin(t * 2.2) * 0.06
		body.get_node("Cape").rotation.x = sin(t * 2.0) * 0.08
		return Vector3(1.0, 1.0 + absf(sin(t * 3.5)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- King Gourdy ------------------------------------------------------------------------

func _update_boss(delta: float) -> void:
	_spell_pose = maxf(_spell_pose - delta, 0.0)
	var b: Arena.Critter = arena.boss
	if b == null or arena.demo:
		_boss_echo.clear()
		return
	for e: Dictionary in _boss_echo.duplicate():
		e["t"] = float(e["t"]) - delta
		if float(e["t"]) <= 0.0:
			_boss_echo.erase(e)
			_boom(e["c"], BOSS_ECHO_REACH)
	if b.hp > SPELL_HP or arena.state != &"play":
		return
	_spell_t += delta
	if _spell_t >= SPELL_EVERY:
		_spell_t = 0.0
		_spell_pose = 1.4
		var any: bool = false
		for c: Vector2i in _jacks:
			if int(_jacks[c]["state"]) == 0:
				_light(c, SPELL_DELAY)
				any = true
		if any:
			arena._spawn_ring(arena._to3(b.pos, 0.1), M.GEM, 2.2)
			_spark(arena._to3(b.pos, 1.6), M.GEM.lightened(0.3), 10)
			_sound(_snd_spell, 1.0)


# --- Bats --------------------------------------------------------------------------------

func _build_bats() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1131
	for k in BAT_COUNT:
		var n: Node3D = M.bat()
		n.scale = Vector3.ONE * r.randf_range(0.9, 1.3)
		arena.add_child(n)
		_bats.append({"node": n, "cx": r.randf_range(0.0, 12.0), "cz": r.randf_range(-4.5, -1.5),
			"rx": r.randf_range(1.5, 3.5), "rz": r.randf_range(0.6, 1.4), "y": r.randf_range(2.2, 3.8),
			"sp": r.randf_range(0.5, 0.9) * (1.0 if k % 2 == 0 else -1.0), "ph": r.randf() * TAU})


func _update_bats(_delta: float) -> void:
	for b: Dictionary in _bats:
		var a: float = float(b["ph"]) + _clock * float(b["sp"])
		var n: Node3D = b["node"]
		var at := Vector3(float(b["cx"]) + cos(a) * float(b["rx"]), float(b["y"]) + sin(a * 2.0) * 0.35, float(b["cz"]) + sin(a) * float(b["rz"]))
		var ahead := Vector3(-sin(a) * float(b["rx"]), 0.0, cos(a) * float(b["rz"])) * signf(float(b["sp"]))
		n.position = at
		n.rotation.y = atan2(ahead.x, ahead.z)
		var flap: float = sin(_clock * 16.0 + float(b["ph"])) * 0.7
		n.get_node("WingL").rotation.z = flap
		n.get_node("WingR").rotation.z = -flap


# --- Effects and sound ----------------------------------------------------------------------

func _spark(at: Vector3, color: Color, count: int) -> void:
	if arena._fx.size() > 230:
		return
	for k in count:
		var a: float = TAU * k / count + randf()
		var n := Models.part(arena, arena._spark_mesh, color, at, 1.2)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena._fx.append({"node": n, "t": 0.0, "life": 0.5, "kind": &"spark",
			"vel": Vector3(cos(a) * 1.2, randf_range(1.4, 2.6), sin(a) * 1.2),
			"spin": Vector3(randf_range(-10, 10), randf_range(-10, 10), 0)})


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


## A soft "fwoomp" as a lantern catches light.
func _make_light() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		lp = lp * 0.82 + randf_range(-1.0, 1.0) * 0.18
		var whoosh: float = lp * minf(t / 0.06, 1.0) * exp(-t * 6.0) * 2.2
		phase += TAU * (140.0 + 220.0 * minf(t / 0.25, 1.0)) / rate
		var tone: float = sin(phase) * minf(t / 0.03, 1.0) * exp(-t * 7.0)
		out[i] = (whoosh * 0.6 + tone * 0.45) * 0.6
	return _wav(out)


## A twinkly rising celesta run for the king's lantern spell.
func _make_spell() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var notes: Array[float] = [659.3, 784.0, 987.8, 1174.7, 1568.0]
	for k in notes.size():
		var s0: int = int(rate * 0.09 * k)
		for i in range(s0, n):
			var t: float = (i - s0) / rate
			var env: float = minf(t / 0.003, 1.0) * exp(-t * 7.0)
			out[i] += (sin(TAU * notes[k] * t) + 0.3 * sin(TAU * notes[k] * 2.0 * t)) * env * 0.22
	return _wav(out)


## A tiny, silly "boo!" as a ghost turns solid nearby.
func _make_boo() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.32)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 330.0 + 120.0 * sin(minf(t / 0.32, 1.0) * PI) + sin(t * TAU * 6.0) * 10.0
		phase += TAU * f / rate
		var env: float = minf(t / 0.05, 1.0) * minf((0.32 - t) / 0.08, 1.0)
		out[i] = (sin(phase) * 0.8 + sin(phase * 2.0) * 0.15) * env * 0.3
	return _wav(out)

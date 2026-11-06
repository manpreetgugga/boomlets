extends WorldKit
## World 9, Ember Forge: a cosy volcano smithy. The twist is lava vents set
## in the floor: each one glows for a moment, then shoots up a short column
## of fire that burns like a blast on its tile. A fizz pod sitting on a vent
## goes off the moment the vent erupts. Hot coal beds make pods on them fuse
## twice as fast. Magma Slugs (m) leave a short-lived hot trail behind them
## that Pip must not step in. Cinderclank, the forge golem, slams his hammer
## to set every vent off at once (with the usual glow first).
##
## Extra map characters:
##   o  lava vent       O  lava vent, half a cycle later
##   h  hot coal bed    m  Magma Slug
## Level key: "vent" (seconds per vent cycle).

const Art = preload("res://worlds/world_9_art.gd")

const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
## Seconds a vent glows before erupting, and how long the fire lasts.
const WARN: float = 1.6
const ERUPT: float = 1.0
const TRAIL_TIME: float = 1.8
const TRAIL_MAX: int = 48
const SLUG_SPEED: float = 1.25
const STOMP_EVERY: float = 9.0
const STOMP_EVERY_ANGRY: float = 6.5
const STOMP_WINDUP: float = 1.1

const PALETTE: Dictionary = {
	"GRASS_A": "#EED8BC", "GRASS_B": "#E2C7A6", "RIM": "#6E5257", "EDGE": "#56444C",
	"STONE": "#7A6670", "DARK_STONE": "#5E4E56", "DIRT": "#5C4045", "ROCK": "#46333A",
	"WOOD": "#F5BE5C", "WOOD_DARK": "#FFF0CC", "BARREL": "#4F8FE0", "BELT": "#4A3C44", "ACCENT": "#FFB347",
	"BLOSSOM_A": "#E87A4A", "BLOSSOM_B": "#D45A3A", "TRUNK": "#5A4048", "LEAFY_A": "#8C6A70", "LEAFY_B": "#765860",
	"SKY_TOP": "#B8506A", "SKY_HORIZON": "#FFC690", "SKY_GROUND": "#6A3A44", "CLOUD": "#F7A88A", "CLOUDS": 0.5,
	"AMBIENT": "#FFD2B8", "AMBIENT_ENERGY": 0.6, "SUN": "#FFE6C8", "SUN_ENERGY": 1.4,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Warm Welcome",
		"tip": "Lava vents glow, then puff fire!\nWait for the fire to die down,\nthen hop across.",
		"crates": 0.42, "par": 72, "vent": 6.0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b...o...b.#",
			"#.#.#.#.#.#.#",
			"#..o.....O..#",
			"#.#.#.#.#.#.#",
			"#.b...b.....#",
			"#.#.#.#.#.#.#",
			"#..O.....o..#",
			"#.#.#.#.#.#.#",
			"#.....O.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Coal Corner",
		"tip": "Pods on hot coals fizz\ntwice as fast. Drop and dash!",
		"crates": 0.4, "par": 82, "vent": 5.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.hhh...b.#",
			"#.#.#.#.#.#.#",
			"#.o.......O.#",
			"#.#.#h#h#.#.#",
			"#....hbh....#",
			"#.#.#h#h#.#.#",
			"#.O.b.....o.#",
			"#.#.#.#.#.#.#",
			"#.....hhh...#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Slug Trail",
		"tip": "Magma slugs leave a hot trail.\nDon't step in it!",
		"crates": 0.4, "par": 88, "vent": 5.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.......m.#",
			"#.#.#o#O#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.o...m...O.#",
			"#.#.#.#.#.#.#",
			"#.b.hh.hh.b.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bellows Hall",
		"tip": "A pod on a vent goes off\nthe moment the vent erupts!",
		"crates": 0.38, "par": 98, "vent": 5.0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#.#.#.#.#.#",
			"#.m..o.o..z.#",
			"#.#.#.#.#.#.#",
			"#.hh.....hh.#",
			"#.#.#B#B#.#.#",
			"#.O...m...O.#",
			"#.#.#.#.#.#.#",
			"#.hh..b..hhm#",
			"#.#.#.#.#.#.#",
			"#.....o.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Conveyor Crucible",
		"tip": "Belts carry pods along.\nRide them onto the coals\nfor a speedy fizz!",
		"crates": 0.4, "par": 105, "vent": 5.0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.m.>>>>..m.#",
			"#.#.#.#.#.#.#",
			"#.O...z...o.#",
			"#.#.#.#.#.#.#",
			"#.hh.<<<<.w.#",
			"#.#.#.#.#.#.#",
			"#.o.b.m...O.#",
			"#.#.#.#.#.#.#",
			"#....>>>>hh.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Cinderclank's Anvil",
		"tip": "Cinderclank's hammer sets off\nevery vent! Watch the glow\nand hit him with eight blasts.",
		"crates": 0.25, "par": 130, "boss": true, "vent": 5.5,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#..o.....o..#",
			"#....hhh....#",
			"#.#.......#.#",
			"#.O...K...O.#",
			"#.#.......#.#",
			"#....hhh....#",
			"#..o.....o..#",
			"#.#..c.c..#.#",
			"#..c.....c..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Lava vents: Vector2i -> {"phase", "node", "glow", "column", "mat", "force", "was"}.
var vents: Dictionary = {}
## Hot coal beds (Vector2i -> true).
var coals: Dictionary = {}
## Hot slug trail: Vector2i -> seconds left.
var trail: Dictionary = {}
var _period: float = 6.0
var _clock: float = 0.0
var _real: Dictionary = {}
var _coal_mat: StandardMaterial3D
var _trail_mm: MultiMesh
var _trail_core_mm: MultiMesh
var _puffs: Array[Node3D] = []
var _puff_t: float = 0.0
var _spark_t: float = 0.0
var _rumble_t: float = 0.0

# The boss.
var _stomp_t: float = 0.0
var _windup: float = 0.0
var _slam: float = 0.0

# Sounds.
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_warn: AudioStreamWAV
var _snd_erupt: AudioStreamWAV
var _snd_clank: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Ember Forge"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_9.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "CINDERCLANK"


func boss_hp() -> int:
	return 8


func boss_minion_kind() -> StringName:
	return &"slug"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"o", "O":
			vents[c] = {"group": 0 if ch == "o" else 1, "force": -1.0, "was": 0}
			return true
		"h":
			coals[c] = true
			return true
	return false


func critter_chars() -> Dictionary:
	return {"m": &"slug"}


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Brick copings on the basalt wall, with little ember lanterns along the
	# far and side walls.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 41
	var bricks: Array[Transform3D] = []
	var seams: Array[Transform3D] = []
	var posts: Array[Transform3D] = []
	var lamps: Array[Transform3D] = []
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var o: Vector3 = tf.origin
		var x: int = roundi(o.x)
		var z: int = roundi(o.z)
		bricks.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.03, 0.03)), Vector3(o.x, 0.73, o.z)))
		# A thin glowing seam along the brick's joint on the camera side.
		if r.randf() < 0.5:
			seams.append(Transform3D(Basis(), Vector3(o.x + r.randf_range(-0.15, 0.15), 0.66, o.z + 0.48)))
		var lamp: bool = (z == 0 and x % 4 == 2) or ((x == 0 or x == w - 1) and z % 4 == 2 and z < h - 1)
		if lamp:
			posts.append(Transform3D(Basis(), Vector3(o.x, 0.95, o.z)))
			lamps.append(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(o.x, 1.2, o.z)))
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.1, 0.9), 0.04), Color("#A8503F"), bricks)
	_mm(Models.box_mesh(Vector3(0.36, 0.04, 0.03), 0.01), seams, Art.hot_mat(Art.LAVA, 1.2))
	arena._multimesh(Models.box_mesh(Vector3(0.06, 0.4, 0.06), 0.02), Art.IRON, posts)
	_mm(Models.box_mesh(Vector3(0.16, 0.16, 0.16), 0.04), lamps, Art.hot_mat(Art.LAVA_HOT, 1.4))
	var caps: Array[Transform3D] = []
	for t in lamps:
		caps.append(t.translated(Vector3(0, 0.11, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.22, 0.05, 0.22), 0.02), Art.IRON, caps)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Every solid block is an anvil on a basalt stump; some hold a glowing
	# ingot.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var stumps: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var feet: Array[Transform3D] = []
	var waists: Array[Transform3D] = []
	var tops: Array[Transform3D] = []
	var horns: Array[Transform3D] = []
	var hot: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var yaw: float = r.randf_range(-0.25, 0.25) + (PI if r.randf() < 0.5 else 0.0)
		var b := Basis(Vector3.UP, yaw)
		stumps.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.1, 0.1)), p + Vector3(0, 0.22, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.38, 0)))
		feet.append(Transform3D(b, p + Vector3(0, 0.49, 0)))
		waists.append(Transform3D(b, p + Vector3(0, 0.6, 0)))
		tops.append(Transform3D(b, p + Vector3(0, 0.73, 0)))
		horns.append(Transform3D(b * Basis(Vector3.BACK, PI * 0.5), p + b * Vector3(0.43, 0.75, 0)))
		if r.randf() < 0.3:
			hot.append(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.5, 0.5)), p + Vector3(0, 0.83, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.44, 0.84), 0.12), Art.BASALT, stumps)
	arena._multimesh(Models.box_mesh(Vector3(0.88, 0.07, 0.88), 0.03), Art.BRICK_DARK, bands)
	arena._multimesh(Models.box_mesh(Vector3(0.5, 0.1, 0.42), 0.04), Art.IRON, feet)
	arena._multimesh(Models.box_mesh(Vector3(0.26, 0.14, 0.24), 0.03), Art.IRON, waists)
	arena._multimesh(Models.box_mesh(Vector3(0.62, 0.14, 0.36), 0.04), Art.IRON_LIGHT, tops)
	arena._multimesh(Models.cylinder(0.0, 0.12, 0.26, 8), Art.IRON_LIGHT, horns)
	_mm(Models.box_mesh(Vector3(0.26, 0.06, 0.12), 0.02), hot, Art.hot_mat(Art.LAVA_HOT, 1.3))
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var holder := Node3D.new()
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.14:
			node = Art.ingots(r)
		elif roll < 0.26:
			node = Art.lava_pool(r)
	else:
		if roll < 0.1:
			node = Art.chimney(r, r.randf_range(0.9, 1.15))
			_puffs.append(node.get_node("Puff"))
		elif roll < 0.18:
			node = Art.cart(r)
		elif roll < 0.26:
			node = Art.tool_rack(r)
		elif roll < 0.38:
			node = Art.lava_pool(r)
		elif roll < 0.46:
			node = Art.ingots(r)
	if node != null:
		node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var v: Node3D = Art.volcano(size * 0.55)
	root.add_child(v)
	_puffs.append(v.get_node("Puff"))
	if r.randf() < 0.6:
		var c: Node3D = Art.chimney(r, 1.2)
		c.position = Vector3(size * 0.32, 0, size * 0.22)
		root.add_child(c)
		_puffs.append(c.get_node("Puff"))
	return root


func build_extra() -> void:
	_period = float(arena.data.get("vent", 6.0))
	for c: Vector2i in vents:
		var v: Dictionary = vents[c]
		var n: Node3D = Art.vent(arena._flame_mesh)
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		v["node"] = n
		v["glow"] = n.get_node("Glow")
		v["column"] = n.get_node("Column")
		v["mat"] = (n.get_node("Glow") as MeshInstance3D).material_override
		v["phase"] = _period * 0.5 * int(v["group"])
	_build_coals()
	_build_trail()
	_build_embers()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -9.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -6.0
	arena.add_child(_player2)
	_snd_warn = _make_warn()
	_snd_erupt = _make_erupt()
	_snd_clank = _make_clank()


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFE2C2")
	env.glow_intensity = 0.6
	env.adjustment_saturation = 1.08


func _mm(mesh: Mesh, tfs: Array[Transform3D], m: Material) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = tfs.size()
	for i in tfs.size():
		mm.set_instance_transform(i, tfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	return mm


func _build_coals() -> void:
	if coals.is_empty():
		return
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 23
	var beds: Array[Transform3D] = []
	var lumps: Array[Transform3D] = []
	var embers: Array[Transform3D] = []
	for c: Vector2i in coals:
		beds.append(Transform3D(Basis(), Vector3(c.x, 0.015, c.y)))
		embers.append(Transform3D(Basis(Vector3.UP, r.randf() * 0.3), Vector3(c.x, 0.03, c.y)))
		for k in 5:
			var a: float = TAU * k / 5.0 + r.randf_range(-0.3, 0.3)
			var d: float = r.randf_range(0.12, 0.3)
			var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.3, 0.3))
			lumps.append(Transform3D(b.scaled(Vector3.ONE * r.randf_range(0.8, 1.2)), Vector3(c.x + cos(a) * d, 0.07, c.y + sin(a) * d)))
	arena._multimesh(Models.box_mesh(Vector3(0.94, 0.05, 0.94), 0.03), Art.IRON, beds)
	_coal_mat = Art.hot_mat(Art.LAVA, 1.2)
	_mm(Models.box_mesh(Vector3(0.8, 0.03, 0.8), 0.02), embers, _coal_mat)
	arena._multimesh(Models.box_mesh(Vector3(0.17, 0.12, 0.15), 0.04), Art.COAL, lumps)


func _build_trail() -> void:
	var hidden: Array[Transform3D] = []
	for i in TRAIL_MAX:
		hidden.append(Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -5, 0)))
	_trail_mm = _mm(Models.box_mesh(Vector3(0.7, 0.03, 0.7), 0.015), hidden, Art.hot_mat(Art.LAVA, 1.3))
	_trail_core_mm = _mm(Models.box_mesh(Vector3(0.38, 0.035, 0.38), 0.012), hidden.duplicate(), Art.hot_mat(Art.LAVA_HOT, 1.5))


func _build_embers() -> void:
	var p := GPUParticles3D.new()
	p.amount = 40
	p.lifetime = 5.0
	p.preprocess = 5.0
	p.position = Vector3((Arena.W - 1) * 0.5, 0.2, (Arena.H - 1) * 0.5)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9.0, 0.2, 10.0)
	pm.direction = Vector3(0.1, 1.0, 0.0)
	pm.spread = 20.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.9
	pm.gravity = Vector3(0, 0.05, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	p.draw_pass_1 = Models.box_mesh(Vector3(0.06, 0.06, 0.06), 0.015)
	p.material_override = Art.hot_mat(Art.LAVA_HOT, 1.6)
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-16, -4, -16), Vector3(32, 16, 32))
	arena.add_child(p)


# --- Rules --------------------------------------------------------------------------

## A vent's state: [0 idle / 1 glowing / 2 erupting, progress through it].
func _vent_state(v: Dictionary) -> Array:
	var force: float = v["force"]
	if force >= 0.0:
		if force > ERUPT:
			return [1, 1.0 - (force - ERUPT) / WARN]
		return [2, 1.0 - force / ERUPT]
	var u: float = fposmod(_clock + float(v.get("phase", 0.0)), _period)
	var idle_end: float = _period - WARN - ERUPT
	if u < idle_end:
		return [0, u / idle_end]
	if u < _period - ERUPT:
		return [1, (u - idle_end) / WARN]
	return [2, (u - idle_end - WARN) / ERUPT]


func _vent_busy(c: Vector2i) -> bool:
	return vents.has(c) and int(_vent_state(vents[c])[0]) != 0


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not _vent_busy(c)


func on_flame(c: Vector2i) -> void:
	_real[c] = _clock


func process(delta: float) -> void:
	_clock += delta
	_rumble_t = maxf(_rumble_t - delta, 0.0)
	_update_vents(delta)
	_update_coals(delta)
	_update_trail(delta)
	if arena.boss != null:
		_boss_stomp(delta)
	_update_puffs(delta)


func _update_vents(delta: float) -> void:
	for c: Vector2i in vents:
		var v: Dictionary = vents[c]
		if float(v["force"]) >= 0.0:
			v["force"] = float(v["force"]) - delta
			if float(v["force"]) < 0.0:
				v["force"] = -1.0
		var st: Array = _vent_state(v)
		var s: int = st[0]
		var k: float = st[1]
		var glow: Node3D = v["glow"]
		var col: Node3D = v["column"]
		var mat: StandardMaterial3D = v["mat"]
		match s:
			0:
				glow.scale = Vector3(0.5, 1.0, 0.5)
				mat.emission_energy_multiplier = 0.35
				col.scale = col.scale.lerp(Vector3.ONE * 0.001, minf(delta * 14.0, 1.0))
			1:
				var pulse: float = 0.5 + 0.5 * sin(_clock * (10.0 + k * 16.0))
				glow.scale = Vector3.ONE * (0.75 + 0.35 * k + pulse * 0.15)
				mat.emission_energy_multiplier = 0.8 + k * 1.6 + pulse * 0.8
				col.scale = col.scale.lerp(Vector3(0.5, 0.12 + k * 0.1, 0.5), minf(delta * 10.0, 1.0))
				if int(v["was"]) == 0 and _rumble_t <= 0.0 and not arena.demo:
					_rumble_t = 0.5
					_sound(_player, _snd_warn, arena.rng.randf_range(0.9, 1.1))
				_spark_t += delta
				if arena.rng.randf() < delta * 6.0:
					_ember(Vector3(c.x, 0.1, c.y), 0.6)
			2:
				if int(v["was"]) != 2:
					_erupt_start(c)
				var punch: float = 1.25 if k < 0.12 else (1.0 + sin(_clock * 40.0) * 0.06)
				if k > 0.8:
					punch = lerpf(1.0, 0.05, (k - 0.8) / 0.2)
				col.scale = Vector3(punch, punch * (1.0 + sin(_clock * 23.0 + c.x) * 0.08), punch)
				col.rotation.y += delta * 6.0
				glow.scale = Vector3.ONE * 1.1
				mat.emission_energy_multiplier = 2.6
				arena.flames[c] = maxf(float(arena.flames.get(c, 0.0)), 0.08)
		v["was"] = s


func _erupt_start(c: Vector2i) -> void:
	# A pod on the vent goes off at once.
	if arena.pod_at.has(c):
		var p: Arena.Pod = arena.pod_at[c]
		p.timer = minf(p.timer, 0.04)
	arena._spawn_ring(Vector3(c.x, 0.08, c.y), Models.FLAME_CORE, 0.6)
	arena._shake = maxf(arena._shake, 0.06)
	_sound(_player2, _snd_erupt, arena.rng.randf_range(0.9, 1.1))
	for k in 3:
		_ember(Vector3(c.x, 0.3, c.y), 1.4)


func _update_coals(delta: float) -> void:
	if coals.is_empty():
		return
	_coal_mat.emission_energy_multiplier = 1.0 + 0.35 * sin(_clock * 2.2)
	for p: Arena.Pod in arena.pods:
		if coals.has(p.cell) and p.slide == Vector2i.ZERO:
			p.timer -= delta
			if arena.rng.randf() < delta * 10.0:
				_ember(Vector3(p.pos.x, 0.25, p.pos.y), 1.0)


func _update_trail(delta: float) -> void:
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"slug" and cr.t > 0.55 and cr.t < 1.0:
			trail[cr.cell] = TRAIL_TIME
	var i: int = 0
	for c: Vector2i in trail.keys():
		var left: float = float(trail[c]) - delta
		if left <= 0.0:
			trail.erase(c)
			continue
		trail[c] = left
		arena.flames[c] = maxf(float(arena.flames.get(c, 0.0)), 0.08)
		if i < TRAIL_MAX:
			var k: float = clampf(left / TRAIL_TIME, 0.0, 1.0)
			var s: float = 0.35 + 0.65 * sqrt(k)
			var wob: float = 1.0 + sin(_clock * 6.0 + c.x * 1.7 + c.y) * 0.04
			_trail_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s * wob, 1.0, s / wob)), Vector3(c.x, 0.02, c.y)))
			_trail_core_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, 1.0, s)), Vector3(c.x, 0.03, c.y)))
			i += 1
	var hidden := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -5, 0))
	for j in range(i, TRAIL_MAX):
		_trail_mm.set_instance_transform(j, hidden)
		_trail_core_mm.set_instance_transform(j, hidden)


func _update_puffs(delta: float) -> void:
	_puff_t += delta
	if _puff_t < 0.45 or _puffs.is_empty():
		return
	_puff_t = 0.0
	var n: Node3D = _puffs[arena.rng.randi() % _puffs.size()]
	if not n.is_inside_tree() or arena._fx.size() > 200:
		return
	var at: Vector3 = n.global_position
	var m := Models.part(arena, arena._smoke_mesh, Art.SMOKE, at)
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena._fx.append({"node": m, "t": 0.0, "life": 1.4, "kind": &"smoke"})


func _ember(at: Vector3, power: float) -> void:
	if arena._fx.size() > 230:
		return
	var n := Models.part(arena, arena._spark_mesh, Art.LAVA_HOT, at, 2.0)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var a: float = arena.rng.randf() * TAU
	arena._fx.append({"node": n, "t": 0.0, "life": 0.6, "kind": &"spark",
		"vel": Vector3(cos(a) * 0.8 * power, arena.rng.randf_range(2.0, 3.6) * power, sin(a) * 0.8 * power),
		"spin": Vector3(arena.rng.randf_range(-10, 10), arena.rng.randf_range(-10, 10), 0)})


# --- Boss ---------------------------------------------------------------------------

## Cinderclank raises his hammer, then slams it down: every quiet vent
## starts to glow and erupts after the usual warning.
func _boss_stomp(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	_slam = maxf(_slam - delta * 2.5, 0.0)
	if arena.demo or arena.state != &"play":
		_windup = 0.0
		return
	_stomp_t += delta
	var every: float = STOMP_EVERY if b.hp * 2 > arena.boss_max_hp else STOMP_EVERY_ANGRY
	_windup = clampf((_stomp_t - (every - STOMP_WINDUP)) / STOMP_WINDUP, 0.0, 1.0)
	if _stomp_t < every:
		return
	_stomp_t = 0.0
	_windup = 0.0
	_slam = 1.0
	for c: Vector2i in vents:
		var v: Dictionary = vents[c]
		if int(_vent_state(v)[0]) == 0:
			v["force"] = WARN + ERUPT
	arena._shake = maxf(arena._shake, 0.35)
	arena._spawn_ring(Vector3(b.pos.x, 0.08, b.pos.y), Art.LAVA_HOT, 1.6)
	_sound(_player2, _snd_clank, 1.0)
	for k in 6:
		_ember(Vector3(b.pos.x, 0.3, b.pos.y), 1.5)


# --- Critters ----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"slug":
			return Art.slug()
		&"boss":
			return Art.golem()
	return null


func critter_speed(kind: StringName) -> float:
	return SLUG_SPEED if kind == &"slug" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_hit(cr: Arena.Critter) -> bool:
	var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
	# Vent fire and slug trails don't hurt critters; only real blasts do.
	if _clock - float(_real.get(here, -9.0)) > Arena.FLAME_TIME + 0.05:
		if trail.has(here) or (vents.has(here) and int(_vent_state(vents[here])[0]) == 2):
			return true
	if cr.kind == &"slug":
		for k in 5:
			_ember(Vector3(cr.pos.x, 0.3, cr.pos.y), 1.2)
	elif cr.kind == &"boss" and cr.invuln <= 0.0:
		for k in 8:
			_ember(Vector3(cr.pos.x, 1.0, cr.pos.y), 1.4)
	return false


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	match cr.kind:
		&"slug":
			var moving: bool = cr.t < 1.0
			var inch: float = sin(t * 8.0) if moving else sin(t * 2.0) * 0.3
			var shell: Node3D = body.get_node("Shell")
			shell.scale = Vector3(1.0 - inch * 0.05, 1.0 + inch * 0.06, 1.0 + inch * 0.1)
			return Vector3.ONE * 1.3
		&"boss":
			var rig: Node3D = body.get_node("Rig")
			body.rotation.y = -cr.node.rotation.y
			var arm: Node3D = rig.get_node("ArmR")
			var sw: float = sin(t * 4.0)
			arm.rotation.x = -_windup * 2.3 + _slam * 0.6 + sw * 0.15 * (1.0 - _windup)
			(rig.get_node("ArmL") as Node3D).rotation.x = -sw * 0.35
			body.position.y = absf(sw) * 0.04
			var fire: MeshInstance3D = rig.get_node("Furnace/Fire")
			(fire.material_override as StandardMaterial3D).emission_energy_multiplier = 1.4 + _windup * 1.6 + sin(t * 7.0) * 0.3
			return Vector3(1.0 + _slam * 0.1, 1.0 - _slam * 0.12 + absf(sin(t * 8.0)) * 0.03, 1.0 + _slam * 0.1)
	return Vector3.ONE


# --- Sound --------------------------------------------------------------------------

func _sound(p: AudioStreamPlayer, s: AudioStreamWAV, pitch: float) -> void:
	if p == null or s == null or arena.demo or not Save.sound_on:
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


## A low bubbling rumble as a vent starts to glow.
func _make_warn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	var lp: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in n:
		var t: float = i / rate
		phase += TAU * (70.0 + 50.0 * t) / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.04
		var bub: float = 0.6 + 0.4 * sin(TAU * 11.0 * t)
		var env: float = minf(t / 0.2, 1.0) * minf((0.9 - t) / 0.2, 1.0)
		out[i] = (sin(phase) * 0.5 + lp * 2.0) * bub * env * 0.5
	return _wav(out)


## The fiery "fwoomph" of an eruption.
func _make_erupt() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var phase: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 92
	for i in n:
		var t: float = i / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * (0.35 * exp(-t * 5.0) + 0.05)
		phase += TAU * (140.0 * exp(-t * 4.0) + 50.0) / rate
		var env: float = minf(t / 0.015, 1.0) * exp(-t * 5.5)
		out[i] = (lp * 1.4 + sin(phase) * 0.5) * env * 0.6
	return _wav(out)


## A big friendly anvil "clang" for the hammer slam.
func _make_clank() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.0)
	var out := PackedFloat32Array()
	out.resize(n)
	var parts: Array = [[440.0, 1.0, 5.0], [1183.0, 0.5, 8.0], [1876.0, 0.3, 11.0], [2650.0, 0.15, 14.0]]
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for p: Array in parts:
			v += sin(TAU * float(p[0]) * t) * float(p[1]) * exp(-t * float(p[2]))
		var thud: float = sin(TAU * (60.0 + 80.0 * exp(-t * 30.0)) * t) * exp(-t * 12.0)
		out[i] = (v * 0.3 + thud * 0.7) * minf(t / 0.002, 1.0) * 0.55
	return _wav(out)

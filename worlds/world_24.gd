extends WorldKit
## World 24, Mirror Marsh: a calm misty marsh split down the middle by a
## glassy, still lake. The twist is Pip's reflection, the Shade. It lives on
## the far side of the lake (the board mirrored across the lake line) and
## copies every move Pip makes, mirrored: when Pip walks towards the lake, so
## does the Shade; up is up for both. Walls, crates and gates on its own side
## stop it, so the two drift out of step, and the player uses that to line
## them up. Every pod Pip drops, the Shade drops one too (same fuse, same
## reach). Blasts never cross the lake, so the far side's critters, lotus
## bells and crates are the Shade's job; its pods can never hurt Pip, and
## anything it touches on its side (power-ups too) counts for Pip.
## Lotus bells (blast them) open the reed gates of their colour on either
## side. From level 3 on, a critter that bumps into the Shade scatters it
## back to its starting tile (never a life lost). Lily Frogs hop about,
## Mirror Frogs dance as their reflections, and Dragonflies skim over the
## lake from side to side. The Great Heron stalks one half, then dives into
## the lake and bursts out on the other half.
##
## Extra map characters:
##   ~  lake (always the middle column)     T  the Shade's start (else S mirrored)
##   L  lilac lotus bell (opens r gates)    P  pink lotus bell (opens p gates)
##   r  lilac reed gate                     p  pink reed gate
##   f  Lily Frog   g  Mirror Frog (reflection side)   d  Dragonfly

const M := preload("res://worlds/world_24_models.gd")

const LAKE_X: int = 6
const SCATTER_TIME: float = 1.1
const SCATTER_GRACE: float = 1.8
## Critters scatter the Shade from this level on.
const SCATTER_LEVEL: int = 3
const DIVE_RISE: float = 0.5
const DIVE_FLY: float = 1.05
const DIVE_DROP: float = 0.45
const DIVE_HIGH: float = 2.6
const TWIN_A := Color("#A496D6")
const TWIN_B := Color("#9183C6")

const PALETTE: Dictionary = {
	"GRASS_A": "#7A9D64", "GRASS_B": "#678A53", "RIM": "#7FA677", "EDGE": "#3E6553",
	"STONE": "#9DB8A4", "DARK_STONE": "#5E806C", "DIRT": "#7A9478", "ROCK": "#6A8276",
	"WOOD": "#F4B9C8", "WOOD_DARK": "#E08AA3", "BARREL": "#9C8BE0", "ACCENT": "#B7A6F2",
	"BLOSSOM_A": "#8CCB9B", "BLOSSOM_B": "#6FB487", "TRUNK": "#8C7A6A", "LEAFY_A": "#9AD6A8", "LEAFY_B": "#7FC497",
	"SKY_TOP": "#8DBBD6", "SKY_HORIZON": "#E6EFE8", "SKY_GROUND": "#C9DCD2", "CLOUD": "#FFFFFF", "CLOUDS": 0.5,
	"AMBIENT": "#C9D8E2", "AMBIENT_ENERGY": 0.55, "SUN": "#F6F6FF", "SUN_ENERGY": 1.3,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Still Water",
		"tip": "Your Shade copies you across\nthe lake, mirrored! Its pods pop\nthe Mirror Frogs on its side.",
		"crates": 0.32, "par": 75,
		"drops": {"bomb": 2, "fire": 1, "speed": 1},
		"map": [
			"#############",
			"#..E..~__.__#",
			"#.#.#.~_#.#_#",
			"#.....~__.g_#",
			"#.#.#.~_#.#_#",
			"#.f...~_._g_#",
			"#.#.#.~_#.#_#",
			"#.....~c._._#",
			"#.#.#.~_#c#_#",
			"#.....~__.__#",
			"#.#.#.~_#.#_#",
			"#.....~_.___#",
			"#_#_#.~_#_#_#",
			"#._S_.~_____#",
			"#############",
		],
	},
	{
		"name": "Lotus Bells",
		"tip": "Reeds guard the exit. Line your\nShade up with the lotus bell\nand blast it to open them!",
		"crates": 0.36, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.rEr.~_.L._#",
			"#.#r#.~.#.#.#",
			"#.....~..g..#",
			"#.#.#.~.#.#.#",
			"#..f..~.....#",
			"#.#.#.~.#.#.#",
			"#.....~..#..#",
			"#.#.#.~.#.#.#",
			"#.f...~...g.#",
			"#.#.#.~.#.#.#",
			"#.....~.....#",
			"#_#_#.~.#_#_#",
			"#._S_.~.___.#",
			"#############",
		],
	},
	{
		"name": "Dragonfly Drift",
		"tip": "Dragonflies skim over the lake!\nIf a critter bumps your Shade,\nit scatters back to its start.",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#E....~...g.#",
			"#.#.#.~.#.#.#",
			"#..d..~.....#",
			"#.###.~.#.#.#",
			"#.....~..#..#",
			"#.#.#.~.#.#.#",
			"#..f..~.g...#",
			"#.###.~.#.#.#",
			"#d....~..#..#",
			"#.#.#.~.#.#.#",
			"#.....~...g.#",
			"#_#_#.~.#_#_#",
			"#._S_.~.___.#",
			"#############",
		],
	},
	{
		"name": "Out of Step",
		"tip": "Walls on one side hold one of\nyou back. Fall out of step on\npurpose to reach the far bells!",
		"crates": 0.38, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#..rE#~..L..#",
			"#.#.#.~.#.#.#",
			"#.d...~...g.#",
			"#.#.#.~.###.#",
			"#.f.P.~....g#",
			"#.#.#.~.#.#.#",
			"#.....~..p..#",
			"#.###.~.#.#.#",
			"#..f..~.pgp.#",
			"#.#.#.~.#p#.#",
			"#.....~.....#",
			"#_#_#.~.#_#_#",
			"#._S_.~.___.#",
			"#############",
		],
	},
	{
		"name": "Moonlit Mire",
		"tip": "Your lilac bell opens the Shade's\npen; the pink bell inside opens\nyour exit. Mind the frogs!",
		"crates": 0.4, "par": 115,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#d..pE~.....#",
			"#.#.#p~.#.#.#",
			"#.....~.g...#",
			"#.#.#.~.#.#.#",
			"#..f..~....g#",
			"##.#.#~.#.#.#",
			"#...f.~d....#",
			"#.#.#.~.#r#.#",
			"#.L...~.rPrg#",
			"#.#.#.~.#r#.#",
			"#.....~.....#",
			"#_#_#.~.#_#_#",
			"#._S_.~.___.#",
			"#############",
		],
	},
	{
		"name": "The Heron's Lake",
		"tip": "The Great Heron dives through\nthe lake to the other side.\nWatch the ripple, then strike!",
		"crates": 0.18, "par": 140, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#..E..~.....#",
			"#.#.#.~.#.#.#",
			"#.....~.....#",
			"#.#.#.~.#.#.#",
			"#..K..~.....#",
			"#.#.#.~.#.#.#",
			"#.....~..#..#",
			"#.#.#.~.#.#.#",
			"#.....~.....#",
			"#.#.#.~.#.#.#",
			"#.....~.....#",
			"#_#_#.~.#_#_#",
			"#._S_.~.___.#",
			"#############",
		],
	},
]

var lake: Dictionary = {}           # Vector2i -> true
var lotus: Dictionary = {}          # Vector2i -> {"group", "lit", "open", "node"}
var gates: Dictionary = {}          # Vector2i -> {"group", "open", "t", "node"}
var anchor: Vector2i = Arena.NO_CELL
var shade: Node3D
var shade_pos: Vector2
var ghost_pods: Array[Dictionary] = []
var ghost_at: Dictionary = {}       # Vector2i -> ghost pod
var _shade_yaw: float = PI
var _shade_moving: bool = false
var _shade_walk: float = 0.0
var _last_hero: Vector2
var _deaths: int = 0
var _scatter_t: float = 0.0
var _grace: float = 0.0
var _seen_pods: Dictionary = {}
var _pairs: Dictionary = {}         # Mirror Frog -> the Lily Frog it reflects
var _dive: Dictionary = {}
var _dive_cd: float = 6.0
var _ghost_danger: Dictionary = {}
var _ghost_frame: int = -1
var _pads: Array[Node3D] = []
var _player: AudioStreamPlayer
var _snd_bloom: AudioStreamWAV
var _snd_splash: AudioStreamWAV
var _snd_scatter: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Mirror Marsh"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_24.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "GREAT HERON"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	# Mirror Frogs on the reflection side; frogs, then dragonflies, on Pip's.
	if arena != null and arena.boss != null:
		if arena.boss.cell.x > LAKE_X:
			return &"mfrog"
		if arena.boss.hp <= 4:
			return &"dfly"
	return &"frog"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"~":
			lake[c] = true
		"T":
			anchor = c
		"L", "P":
			lotus[c] = {"group": 0 if ch == "L" else 1, "lit": false, "open": 0.0}
		"r", "p":
			gates[c] = {"group": 0 if ch == "r" else 1, "open": false, "t": 0.0}
		_:
			return false
	return true


func critter_chars() -> Dictionary:
	return {"f": &"frog", "g": &"mfrog", "d": &"dfly"}


static func mirror(c: Vector2i) -> Vector2i:
	return Vector2i(2 * LAKE_X - c.x, c.y)


func build_extra() -> void:
	if anchor == Arena.NO_CELL:
		anchor = mirror(arena.start_cell)
	_build_floor()
	_build_lake()
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 24
	for c: Vector2i in lotus:
		var n: Node3D = M.lotus(M.GROUP_COLORS[int(lotus[c]["group"])])
		n.position = Vector3(c.x, 0, c.y)
		n.scale = Vector3.ONE * 1.15
		arena.add_child(n)
		lotus[c]["node"] = n
		_pose_lotus(n, 0.0)
	for c: Vector2i in gates:
		var g: Node3D = M.reed_gate(M.GROUP_COLORS[int(gates[c]["group"])], r)
		g.position = Vector3(c.x, 0, c.y)
		g.rotation.y = r.randf_range(-0.2, 0.2)
		arena.add_child(g)
		gates[c]["node"] = g
	# Each Mirror Frog standing on a Lily Frog's reflection dances with it.
	for cr: Arena.Critter in arena.critters:
		if cr.kind != &"mfrog":
			continue
		for other: Arena.Critter in arena.critters:
			if other.kind == &"frog" and other.cell == mirror(cr.cell):
				_pairs[cr] = other
				cr.dir = Vector2i(-other.dir.x, other.dir.y)
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_snd_bloom = _make_bloom()
	_snd_splash = _make_splash()
	_snd_scatter = _make_scatter()
	if arena.demo:
		return
	shade = M.shade()
	arena.add_child(shade)
	shade_pos = Vector2(anchor)
	_last_hero = arena.hero_pos
	_grace = 3.0
	_pose_shade(0.0)


## The floor on the reflection side turns misty lilac and the middle column
## becomes the lake: the arena's own floor tiles there are tucked away and
## redrawn.
func _build_floor() -> void:
	var tile_mesh: ArrayMesh = Models.box_mesh(Vector3(0.96, 0.3, 0.96), 0.08)
	var hidden := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -6, 0))
	var twin_a: Array[Transform3D] = []
	var twin_b: Array[Transform3D] = []
	for ch: Node in arena.get_children():
		var mmi := ch as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null or mmi.multimesh.mesh != tile_mesh:
			continue
		var mm: MultiMesh = mmi.multimesh
		for i in mm.instance_count:
			var tf: Transform3D = mm.get_instance_transform(i)
			var c := Vector2i(roundi(tf.origin.x), roundi(tf.origin.z))
			if lake.has(c):
				mm.set_instance_transform(i, hidden)
			elif c.x > LAKE_X:
				(twin_a if (c.x + c.y) % 2 == 0 else twin_b).append(tf)
				mm.set_instance_transform(i, hidden)
	arena._multimesh(tile_mesh, TWIN_A, twin_a)
	arena._multimesh(tile_mesh, TWIN_B, twin_b)


func _build_lake() -> void:
	if lake.is_empty():
		return
	var z0: int = 99
	var z1: int = -1
	for c: Vector2i in lake:
		z0 = mini(z0, c.y)
		z1 = maxi(z1, c.y)
	var len: float = float(z1 - z0) + 1.1
	var water := MeshInstance3D.new()
	water.mesh = Models.box_mesh(Vector3(1.02, 0.12, len), 0.03)
	water.material_override = M.lake_material()
	water.position = Vector3(LAKE_X, -0.075, (z0 + z1) * 0.5)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(water)
	# Low pebble banks along both shores.
	var banks: Array[Transform3D] = []
	for z in range(z0, z1 + 1):
		for side: int in [-1, 1]:
			banks.append(Transform3D(Basis(), Vector3(LAKE_X + side * 0.49, 0.0, z)))
	arena._multimesh(Models.box_mesh(Vector3(0.06, 0.05, 0.9), 0.02), Color("#E9F2EE"), banks)
	# Lily pads (some with a lotus) floating on the lake, which drift a little.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 5
	for z in range(z0, z1 + 1):
		if r.randf() < 0.45:
			continue
		var pad := Node3D.new()
		pad.position = Vector3(LAKE_X + r.randf_range(-0.2, 0.2), 0.0, z + r.randf_range(-0.25, 0.25))
		pad.rotation.y = r.randf() * TAU
		pad.set_meta(&"base", pad.position)
		pad.set_meta(&"phase", r.randf() * TAU)
		arena.add_child(pad)
		var s: float = r.randf_range(0.16, 0.23)
		var leaf := Models.part(pad, Models.cylinder(s, s, 0.02, 14), M.PAD if r.randf() < 0.6 else M.PAD_DARK, Vector3(0, 0.0, 0))
		leaf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if r.randf() < 0.35:
			var bud := Models.part(pad, Models.sphere(0.06, 0.1, 10), M.LOTUS_PINK if r.randf() < 0.5 else M.LOTUS_WHITE, Vector3(0.03, 0.05, 0.02), 0.25)
			bud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_pads.append(pad)


## Reeds and cattails along the border wall.
func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var blades_a: Array[Transform3D] = []
	var blades_b: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	for tf in blocks:
		var base: Vector3 = tf.origin
		if r.randf() < 0.3:
			continue
		var n: int = r.randi_range(3, 5)
		for k in n:
			var h: float = r.randf_range(0.6, 1.0)
			var at := Vector3(base.x + r.randf_range(-0.28, 0.28), 0.68 + 0.17 * h, base.z + r.randf_range(-0.28, 0.28))
			var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.22, 0.22))
			var blade := Transform3D(b.scaled(Vector3(1.0, h, 1.0)), at)
			(blades_a if k % 2 == 0 else blades_b).append(blade)
			if k == 0 and r.randf() < 0.5:
				heads.append(Transform3D(b, at + b.y * 0.2 * h))
		if r.randf() < 0.18:
			flowers.append(Transform3D(Basis(), base + Vector3(r.randf_range(-0.2, 0.2), 0.72, r.randf_range(-0.2, 0.2))))
	var blade_mesh: ArrayMesh = Models.box_mesh(Vector3(0.05, 0.34, 0.05), 0.02)
	arena._multimesh(blade_mesh, M.REED, blades_a)
	arena._multimesh(blade_mesh, M.REED_DARK, blades_b)
	arena._multimesh(Models.box_mesh(Vector3(0.08, 0.15, 0.08), 0.035), M.CATTAIL, heads)
	arena._multimesh(Models.sphere(0.06, 0.09, 10), M.LOTUS_PINK, flowers)
	return true


## Solid blocks: smooth river stones with a pale cap and a moss pad: sage
## on Pip's side, misty lilac on the reflection side.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var lows: Array = [[], []]
	var caps: Array = [[], []]
	var moss: Array[Transform3D] = []
	var buds: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var side: int = 1 if p.x > LAKE_X else 0
		var turn := Basis(Vector3.UP, r.randf_range(-0.08, 0.08))
		(lows[side] as Array).append(Transform3D(turn, p + Vector3(0, 0.3, 0)))
		(caps[side] as Array).append(Transform3D(turn, p + Vector3(0, 0.65, 0)))
		if r.randf() < 0.55:
			var at := p + Vector3(r.randf_range(-0.16, 0.16), 0.72, r.randf_range(-0.16, 0.16))
			moss.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(1.0, 0.45, 1.0) * r.randf_range(0.8, 1.1)), at))
			if r.randf() < 0.3:
				buds.append(Transform3D(Basis(), at + Vector3(0.05, 0.07, 0.0)))
	var low_mesh: ArrayMesh = Models.box_mesh(Vector3(0.84, 0.6, 0.84), 0.12)
	var cap_mesh: ArrayMesh = Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.05)
	var low_cols: Array[Color] = [Color("#4F7A62"), Color("#5E4F9E")]
	var cap_cols: Array[Color] = [Color("#DCEBD9"), Color("#E8E2FF")]
	for side in 2:
		var a: Array[Transform3D] = []
		a.assign(lows[side])
		arena._multimesh(low_mesh, low_cols[side], a)
		var b: Array[Transform3D] = []
		b.assign(caps[side])
		arena._multimesh(cap_mesh, cap_cols[side], b)
	arena._multimesh(Models.sphere(0.2, 0.2, 12), M.PAD, moss)
	arena._multimesh(Models.sphere(0.05, 0.08, 8), M.LOTUS_WHITE, buds)
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.3:
			node = M.reeds(r)
			node.scale = Vector3.ONE * 0.7
		elif roll < 0.42:
			node = M.mushroom(r)
		elif roll < 0.5:
			node = M.pond(r, 0.6)
	else:
		if roll < 0.14:
			node = M.willow(r)
		elif roll < 0.4:
			node = M.reeds(r)
		elif roll < 0.48:
			node = M.pond(r, 0.8)
		elif roll < 0.54:
			node = M.stone_lantern()
		elif roll < 0.64:
			node = M.mushroom(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var w := M.willow(r)
	w.scale = Vector3.ONE * 1.3
	w.position = Vector3(-size * 0.12, 0, -size * 0.1)
	root.add_child(w)
	var pond := M.pond(r, size * 0.45)
	pond.position = Vector3(size * 0.25, 0, size * 0.2)
	root.add_child(pond)
	var reeds := M.reeds(r)
	reeds.position = Vector3(-size * 0.3, 0, size * 0.25)
	root.add_child(reeds)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#F4F4FF")
	env.adjustment_saturation = 1.1
	env.glow_intensity = 0.35
	# A soft mist that hides the far-off islands in haze.
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color("#E4F0EC")
	env.fog_light_energy = 1.0
	env.fog_density = 0.12
	env.fog_depth_begin = 45.0
	env.fog_depth_end = 80.0
	env.fog_sky_affect = 0.0


# --- Rules ------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return lake.has(c) or lotus.has(c) or (gates.has(c) and not bool(gates[c]["open"]))


func flame_stop(c: Vector2i) -> int:
	if lake.has(c):
		return 2
	if lotus.has(c):
		return 1
	if gates.has(c) and not bool(gates[c]["open"]):
		return 2
	return 0


func on_flame(c: Vector2i) -> void:
	if lotus.has(c) and not bool(lotus[c]["lit"]):
		_light_lotus(c)
	if ghost_at.has(c):
		var g: Dictionary = ghost_at[c]
		g["timer"] = minf(float(g["timer"]), 0.06)


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if lotus.has(c) or ghost_at.has(c):
		return false
	if gates.has(c) and not bool(gates[c]["open"]):
		return false
	if lake.has(c):
		return cr.kind == &"dfly"
	if cr.kind == &"boss" and not _dive.is_empty():
		return false
	return true


func _light_lotus(c: Vector2i) -> void:
	var lt: Dictionary = lotus[c]
	lt["lit"] = true
	var group: int = lt["group"]
	var color: Color = M.GROUP_COLORS[group]
	arena._spawn_sparkles(Vector3(c.x, 0.7, c.y), color)
	arena._spawn_ring(Vector3(c.x, 0.4, c.y), color, 1.2)
	var opened: bool = false
	for g: Vector2i in gates:
		var gd: Dictionary = gates[g]
		if int(gd["group"]) == group and not bool(gd["open"]):
			gd["open"] = true
			gd["t"] = 0.0
			opened = true
			arena._spawn_sparkles(Vector3(g.x, 0.5, g.y), color)
	_sound(_snd_bloom, 1.0 if group == 0 else 1.12)
	if opened:
		Sfx.play(&"gate", 0.0)
		arena._shake = maxf(arena._shake, 0.15)


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	_animate_scenery(delta)
	if arena.demo or shade == null:
		return
	_update_shade(delta)
	_update_ghost_pods(delta)
	_update_heron(delta)


func _animate_scenery(delta: float) -> void:
	var clock: float = arena._clock
	for c: Vector2i in lotus:
		var lt: Dictionary = lotus[c]
		var target: float = 1.0 if bool(lt["lit"]) else 0.0
		lt["open"] = move_toward(float(lt["open"]), target, delta * 1.6)
		_pose_lotus(lt["node"], float(lt["open"]))
		var bloom: Node3D = (lt["node"] as Node3D).get_node("Bloom")
		bloom.position.y = 0.38 + sin(clock * 1.4 + c.x) * 0.015
		if not bool(lt["lit"]):
			bloom.rotation.y = sin(clock * 0.8 + c.y) * 0.15
	for c: Vector2i in gates:
		var gd: Dictionary = gates[c]
		var node: Node3D = gd["node"]
		if node == null or not bool(gd["open"]):
			if node != null:
				var band: Node3D = node.get_node("Stalks/Band")
				band.scale = Vector3.ONE * (1.0 + sin(clock * 3.0 + c.x * 0.7) * 0.03)
			continue
		gd["t"] = float(gd["t"]) + delta
		var k: float = clampf(float(gd["t"]) / 0.55, 0.0, 1.0)
		var stalks: Node3D = node.get_node("Stalks")
		stalks.scale = Vector3(1.0 + k * 0.2, maxf(1.0 - k * k, 0.02), 1.0 + k * 0.2)
		if k >= 1.0 and node.visible:
			node.visible = false
	for pad: Node3D in _pads:
		var ph: float = pad.get_meta(&"phase")
		var base: Vector3 = pad.get_meta(&"base")
		pad.position = base + Vector3(sin(clock * 0.35 + ph) * 0.05, 0.0, cos(clock * 0.27 + ph) * 0.05)
		pad.rotation.y += delta * 0.05 * sin(ph)


## Opens the lotus petals by [param k] (0 = closed bud, 1 = in bloom).
func _pose_lotus(node: Node3D, k: float) -> void:
	if node.has_meta(&"k") and is_equal_approx(float(node.get_meta(&"k")), k):
		return
	node.set_meta(&"k", k)
	var bloom: Node3D = node.get_node("Bloom")
	for i in 6:
		var tilt: Node3D = bloom.get_node("Petal%d/Tilt" % i)
		tilt.rotation.x = lerpf(-0.12, 1.05, k)
	var heart: Node3D = bloom.get_node("Heart")
	heart.scale = Vector3.ONE * (0.6 + k * 0.7)
	(heart as MeshInstance3D).material_override = Models.mat(Color("#FFE27A"), 0.3 + k * 1.6)


# --- The Shade ---------------------------------------------------------------------

func shade_cell() -> Vector2i:
	return Vector2i(roundi(shade_pos.x), roundi(shade_pos.y))


func shade_active() -> bool:
	return shade != null and _scatter_t <= 0.0


func _shade_blocked(c: Vector2i) -> bool:
	return c.x <= LAKE_X or arena.tile(c) != Arena.FLOOR or blocks(c)


func _update_shade(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)
	var step: Vector2 = arena.hero_pos - _last_hero
	_last_hero = arena.hero_pos
	_shade_moving = false
	if arena.deaths != _deaths and arena.state == &"play":
		# Pip is back at the start; his reflection reforms at its own.
		_deaths = arena.deaths
		_reset_shade()
		_pose_shade(delta)
		return
	if _scatter_t > 0.0:
		_scatter_t -= delta
		if _scatter_t <= 0.0:
			_reset_shade()
		_pose_shade(delta)
		return
	if arena.state == &"play" and arena.hero_alive and arena.hero_moving and step.length_squared() > 1e-8 and step.length() < 0.75:
		# Copy Pip's move, mirrored across the lake.
		var dir := Vector2i(roundi(sin(arena.hero_yaw)), roundi(cos(arena.hero_yaw)))
		var md := Vector2i(-dir.x, dir.y)
		var before: Vector2 = shade_pos
		shade_pos = arena._move_axis(shade_pos, md, step.length(), _shade_blocked)
		_shade_moving = shade_pos.distance_squared_to(before) > 1e-8
		_shade_yaw = atan2(float(md.x), float(md.y))
	var c: Vector2i = shade_cell()
	# Power-ups it reaches go to Pip.
	if arena.pickups.has(c) and arena.state == &"play":
		arena._collect(c)
	# New pods: the Shade drops its own.
	for p: Arena.Pod in arena.pods:
		if not _seen_pods.has(p):
			_seen_pods[p] = true
			_drop_ghost(p)
	for p: Arena.Pod in _seen_pods.keys():
		if not arena.pods.has(p):
			_seen_pods.erase(p)
	# Critters that bump the Shade scatter it (from level 3).
	if arena.level_id >= SCATTER_LEVEL and _grace <= 0.0:
		for cr: Arena.Critter in arena.critters:
			if critter_hidden(cr):
				continue
			var reach: float = 0.95 if cr.kind == &"boss" else 0.6
			if cr.pos.distance_to(shade_pos) < reach:
				_scatter()
				break
	_pose_shade(delta)


func _reset_shade() -> void:
	shade_pos = Vector2(anchor)
	_scatter_t = 0.0
	_grace = SCATTER_GRACE
	_last_hero = arena.hero_pos
	shade.visible = true
	arena._spawn_sparkles(Vector3(anchor.x, 0.4, anchor.y), M.SILVER)


func _scatter() -> void:
	_scatter_t = SCATTER_TIME
	arena._spawn_sparkles(Vector3(shade_pos.x, 0.45, shade_pos.y), M.SHADE)
	arena._spawn_ring(Vector3(shade_pos.x, 0.06, shade_pos.y), M.SILVER, 0.8)
	_sound(_snd_scatter, 1.0)
	shade.visible = false


func _pose_shade(delta: float) -> void:
	shade.position = Vector3(shade_pos.x, 0, shade_pos.y)
	if _scatter_t > 0.0:
		shade.visible = false
		return
	shade.visible = _grace <= 0.0 or fmod(arena._clock, 0.18) < 0.12
	shade.rotation.y = lerp_angle(shade.rotation.y, _shade_yaw, minf(delta * 14.0, 1.0))
	var body: Node3D = shade.get_node("Body")
	var foot_l: Node3D = body.get_node("FootL")
	var foot_r: Node3D = body.get_node("FootR")
	if _shade_moving:
		_shade_walk += delta * arena.speed * 4.2
		body.position.y = absf(sin(_shade_walk)) * 0.07
		body.rotation.z = sin(_shade_walk) * 0.09
		foot_l.position.z = 0.05 + sin(_shade_walk) * 0.1
		foot_r.position.z = 0.05 - sin(_shade_walk) * 0.1
	else:
		body.position.y = lerpf(body.position.y, sin(arena._clock * 2.0) * 0.02, minf(delta * 10.0, 1.0))
		body.rotation.z = lerpf(body.rotation.z, 0.0, minf(delta * 10.0, 1.0))
		foot_l.position.z = 0.05
		foot_r.position.z = 0.05
	var halo: Node3D = shade.get_node("Halo")
	halo.scale = Vector3(1.0, 0.3, 1.0) * (1.0 + sin(arena._clock * 3.0) * 0.06)
	halo.rotation.y += delta * 0.8


# --- The Shade's pods -------------------------------------------------------------

func _drop_ghost(p: Arena.Pod) -> void:
	if not shade_active():
		return
	var c: Vector2i = shade_cell()
	if c.x <= LAKE_X or arena.tile(c) != Arena.FLOOR or blocks(c) or ghost_at.has(c):
		return
	var n: Node3D = M.ghost_pod()
	n.position = Vector3(c.x, 0, c.y)
	arena.add_child(n)
	var g := {"cell": c, "timer": p.timer, "fire": p.fire, "node": n, "age": 0.0}
	ghost_pods.append(g)
	ghost_at[c] = g
	(n.get_node("Body") as Node3D).scale = Vector3(1.4, 0.5, 1.4)
	var body: Node3D = shade.get_node("Body")
	body.scale = Vector3(1.25, 0.75, 1.25)


func _update_ghost_pods(delta: float) -> void:
	for g: Dictionary in ghost_pods.duplicate():
		if not ghost_pods.has(g):
			continue
		g["timer"] = float(g["timer"]) - delta
		g["age"] = float(g["age"]) + delta
		var node: Node3D = g["node"]
		var body: Node3D = node.get_node("Body")
		var age: float = g["age"]
		var hurry: float = clampf(1.0 - float(g["timer"]) / Arena.FUSE, 0.0, 1.0)
		var pulse: float = 1.0 + sin(age * (6.0 + hurry * 18.0)) * (0.04 + hurry * 0.06)
		if age > 0.2:
			body.scale = body.scale.lerp(Vector3(pulse, 2.0 - pulse, pulse), minf(delta * 14.0, 1.0))
		else:
			body.scale = Vector3(1.4, 0.5, 1.4).lerp(Vector3.ONE, age / 0.2)
		var spark: Node3D = body.get_node("Spark")
		spark.scale = Vector3.ONE * (0.7 + randf() * 0.7)
		if float(g["timer"]) <= 0.0:
			_explode_ghost(g)
	if shade != null:
		var sb: Node3D = shade.get_node("Body")
		sb.scale = sb.scale.lerp(Vector3.ONE, minf(delta * 10.0, 1.0))


func _explode_ghost(g: Dictionary) -> void:
	ghost_pods.erase(g)
	var c: Vector2i = g["cell"]
	if ghost_at.get(c) == g:
		ghost_at.erase(c)
	(g["node"] as Node3D).queue_free()
	arena._blast(c, int(g["fire"]))
	arena._spawn_ring(Vector3(c.x, 0.06, c.y), M.SHADE.lightened(0.3), 1.0 + int(g["fire"]) * 0.4)
	arena._spawn_scorch(Vector3(c.x, 0.012, c.y))
	Sfx.play(&"boom", 0.15)
	arena._shake = maxf(arena._shake, 0.2)


## Cells a Shade pod is about to burn (for critters that dodge).
func ghost_danger() -> Dictionary:
	var frame: int = Engine.get_process_frames()
	if frame == _ghost_frame:
		return _ghost_danger
	_ghost_frame = frame
	_ghost_danger = {}
	for g: Dictionary in ghost_pods:
		if float(g["timer"]) > 1.4:
			continue
		var c: Vector2i = g["cell"]
		_ghost_danger[c] = true
		for d: Vector2i in Arena.DIRS:
			for i in range(1, int(g["fire"]) + 1):
				var cc: Vector2i = c + d * i
				if arena.tile(cc) != Arena.FLOOR:
					break
				var own: int = flame_stop(cc)
				if own == 2:
					break
				_ghost_danger[cc] = true
				if own == 1:
					break
	return _ghost_danger


# --- Critters ---------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"frog":
			return M.frog(false)
		&"mfrog":
			return M.frog(true)
		&"dfly":
			return M.dragonfly()
		&"boss":
			return M.heron()
	return null


func critter_speed(kind: StringName) -> float:
	match kind:
		&"frog", &"mfrog":
			return 1.6 + 0.06 * arena.level_id
		&"dfly":
			return 1.9 + 0.08 * arena.level_id
	return 1.5


func critter_smart(kind: StringName) -> bool:
	if kind == &"dfly":
		return arena.level_id >= 3
	if kind == &"frog":
		return arena.level_id >= 4
	return false


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind == &"mfrog":
		return _mfrog_step(cr)
	if cr.kind == &"boss":
		return _heron_step(cr)
	return Vector2i.ZERO


func _open_dirs(cr: Arena.Critter, danger: Dictionary) -> Array[Vector2i]:
	var open: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		if arena._critter_can_enter(cr, cr.cell + d):
			open.append(d)
	var safe: Array[Vector2i] = []
	for d: Vector2i in open:
		if not danger.has(cr.cell + d):
			safe.append(d)
	return safe if not safe.is_empty() else open


func _wander(cr: Arena.Critter, open: Array[Vector2i]) -> Vector2i:
	if open.is_empty():
		return Vector2i.ZERO
	if open.has(cr.dir) and arena.rng.randf() < 0.7:
		return cr.dir
	var turns: Array[Vector2i] = []
	for d: Vector2i in open:
		if d != -cr.dir:
			turns.append(d)
	if turns.is_empty():
		turns = open
	return turns[arena.rng.randi() % turns.size()]


## Mirror Frogs copy their Lily Frog's hops, mirrored; dodge the Shade's
## pods from level 2; and hop after the Shade from level 4.
func _mfrog_step(cr: Arena.Critter) -> Vector2i:
	var danger: Dictionary = ghost_danger() if arena.level_id >= 2 else {}
	var open: Array[Vector2i] = _open_dirs(cr, danger)
	if open.is_empty():
		return Vector2i.ZERO
	var partner: Arena.Critter = _pairs.get(cr)
	if partner != null and arena.critters.has(partner):
		var md := Vector2i(-partner.dir.x, partner.dir.y)
		if open.has(md):
			return md
	if arena.level_id >= 4 and shade_active():
		var sc: Vector2i = shade_cell()
		if absi(sc.x - cr.cell.x) + absi(sc.y - cr.cell.y) <= 5 and arena.rng.randf() < 0.55:
			var step: Vector2i = arena._path_step(cr, sc)
			if open.has(step):
				return step
	return _wander(cr, open)


## The heron hunts Pip on his side and the Shade on the other, and steps
## round both kinds of pods.
func _heron_step(cr: Arena.Critter) -> Vector2i:
	var danger: Dictionary = arena._danger_cells().duplicate()
	danger.merge(ghost_danger())
	var open: Array[Vector2i] = _open_dirs(cr, danger)
	if open.is_empty():
		return Vector2i.ZERO
	var goal: Vector2i = Arena.NO_CELL
	if cr.cell.x < LAKE_X:
		if arena.hero_alive:
			goal = arena.hero_cell()
	elif shade_active():
		goal = shade_cell()
	if goal != Arena.NO_CELL and arena.rng.randf() < 0.85:
		var step: Vector2i = arena._path_step(cr, goal)
		if open.has(step):
			return step
	return _wander(cr, open)


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr.kind == &"boss" and not _dive.is_empty()


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"frog", &"mfrog":
			var hopping: bool = cr.t < 1.0 and cr.target != cr.cell
			if hopping:
				body.position.y = sin(cr.t * PI) * 0.24
				body.rotation.x = lerpf(-0.3, 0.3, cr.t)
				for leg: String in ["LegL", "LegR"]:
					(body.get_node(leg) as Node3D).rotation.x = -0.8 * sin(cr.t * PI)
				return Vector3(0.92, 1.12, 0.92) * M.FROG_SIZE
			body.position.y = lerpf(body.position.y, 0.0, minf(delta * 14.0, 1.0))
			body.rotation.x = lerpf(body.rotation.x, 0.0, minf(delta * 10.0, 1.0))
			for leg2: String in ["LegL", "LegR"]:
				(body.get_node(leg2) as Node3D).rotation.x = 0.0
			var breathe: float = sin(t * 5.0) * 0.05
			return Vector3(1.0 + breathe, 1.0 - breathe * 1.4, 1.0 + breathe) * M.FROG_SIZE
		&"dfly":
			var fly: Node3D = body.get_node("Fly")
			fly.position.y = 0.55 + sin(t * 3.0) * 0.08
			fly.rotation.z = sin(t * 1.3) * 0.12
			for k in 2:
				var flap: float = sin(t * 48.0 + k * 1.6) * 0.45
				(fly.get_node("WingL%d" % k) as Node3D).rotation.z = flap
				(fly.get_node("WingR%d" % k) as Node3D).rotation.z = -flap
			return Vector3.ONE
		&"boss":
			var neck: Node3D = body.get_node("Neck")
			var head: Node3D = neck.get_node("Head")
			var diving: bool = not _dive.is_empty()
			var spread: float = 1.25 if diving else 0.0
			(body.get_node("WingL") as Node3D).rotation.z = lerpf((body.get_node("WingL") as Node3D).rotation.z, -spread + (sin(t * 14.0) * 0.5 if diving else 0.0), minf(delta * 10.0, 1.0))
			(body.get_node("WingR") as Node3D).rotation.z = lerpf((body.get_node("WingR") as Node3D).rotation.z, spread - (sin(t * 14.0) * 0.5 if diving else 0.0), minf(delta * 10.0, 1.0))
			neck.rotation.x = lerpf(neck.rotation.x, 0.5 if diving else sin(t * 1.6) * 0.1, minf(delta * 8.0, 1.0))
			head.rotation.x = lerpf(head.rotation.x, 0.4 if diving else maxf(sin(t * 0.9), 0.0) * 0.35, minf(delta * 8.0, 1.0))
			return Vector3(1.0, 1.0 + absf(sin(t * 2.6)) * 0.03, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- The Great Heron ---------------------------------------------------------------

func _dive_every(b: Arena.Critter) -> float:
	if b.hp > 6:
		return 9.0
	if b.hp > 3:
		return 7.0
	return 5.5


func _update_heron(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		if not _dive.is_empty():
			_end_dive_marker()
			_dive = {}
		return
	if _dive.is_empty():
		_dive_cd -= delta
		if _dive_cd <= 0.0:
			var to: Vector2i = _landing_cell(b)
			if to == Arena.NO_CELL:
				_dive_cd = 1.0
				return
			_dive = {"t": 0.0, "from": Vector3(b.pos.x, 0, b.pos.y), "to": to, "swapped": false, "splash": b.hp <= 3}
			_dive["marker"] = _make_marker(to, bool(_dive["splash"]))
			_sound(_snd_splash, 1.25)
			arena._spawn_ring(Vector3(b.cell.x, 0.08, b.cell.y), M.WATER, 1.2)
		return
	_dive["t"] = float(_dive["t"]) + delta
	var tt: float = _dive["t"]
	var a: Vector3 = _dive["from"]
	var to2: Vector2i = _dive["to"]
	var z := Vector3(to2.x, 0, to2.y)
	b.target = b.cell
	b.t = 1.0
	var pos: Vector3
	if tt < DIVE_RISE:
		var k: float = tt / DIVE_RISE
		pos = a + Vector3(0, DIVE_HIGH * k * k, 0)
	elif tt < DIVE_RISE + DIVE_FLY:
		var k2: float = (tt - DIVE_RISE) / DIVE_FLY
		var e: float = k2 * k2 * (3.0 - 2.0 * k2)
		pos = a.lerp(z, e) + Vector3(0, DIVE_HIGH + sin(k2 * PI) * 0.7, 0)
		if not bool(_dive["swapped"]) and k2 >= 0.5:
			_dive["swapped"] = true
			b.cell = to2
			b.target = to2
			b.pos = Vector2(to2)
	elif tt < DIVE_RISE + DIVE_FLY + DIVE_DROP:
		var k3: float = (tt - DIVE_RISE - DIVE_FLY) / DIVE_DROP
		pos = z + Vector3(0, DIVE_HIGH * (1.0 - k3) * (1.0 - k3), 0)
	else:
		_land(b)
		return
	b.node.position = pos
	var mk: Node3D = _dive.get("marker")
	if mk != null:
		var u: float = clampf(tt / (DIVE_RISE + DIVE_FLY + DIVE_DROP), 0.0, 1.0)
		mk.scale = Vector3.ONE * (0.6 + u * 0.4) * (1.0 + sin(arena._clock * 12.0) * 0.05)


func _land(b: Arena.Critter) -> void:
	var to: Vector2i = _dive["to"]
	b.cell = to
	b.target = to
	b.pos = Vector2(to)
	b.node.position = Vector3(to.x, 0, to.y)
	var splash: bool = _dive["splash"]
	_end_dive_marker()
	_dive = {}
	_dive_cd = _dive_every(b)
	arena._spawn_ring(Vector3(to.x, 0.08, to.y), M.WATER, 1.6)
	arena._spawn_sparkles(Vector3(to.x, 0.3, to.y), M.WATER.lightened(0.4))
	arena._shake = maxf(arena._shake, 0.3)
	_sound(_snd_splash, 0.9)
	(b.node.get_node("Body") as Node3D).scale = Vector3(1.3, 0.75, 1.3) * M.BOSS_SIZE
	if splash:
		# A splash wave round the landing spot (it was marked while it dived).
		for d: Vector2i in Arena.DIRS:
			var c: Vector2i = to + d
			if arena.tile(c) == Arena.FLOOR and not blocks(c):
				arena._spawn_ring(Vector3(c.x, 0.08, c.y), M.WATER, 0.7)
				if arena.hero_alive and arena.hero_cell() == c:
					arena._hurt_hero()
				if shade_active() and shade_cell() == c and _grace <= 0.0:
					_scatter()


## A landing spot on the other half: as close as it can to the heron's own
## reflection, clear of pods, flames and critters, and never right on top
## of Pip.
func _landing_cell(b: Arena.Critter) -> Vector2i:
	var to_twin: bool = b.cell.x < LAKE_X
	var want: Vector2i = mirror(b.cell)
	var hc: Vector2i = arena.hero_cell()
	var best: Vector2i = Arena.NO_CELL
	var best_score: float = INF
	for zz in range(1, Arena.H - 1):
		for xx in range(1, Arena.W - 1):
			var c := Vector2i(xx, zz)
			if (c.x > LAKE_X) != to_twin or c.x == LAKE_X:
				continue
			if arena.tile(c) != Arena.FLOOR or blocks(c) or arena.pod_at.has(c) or ghost_at.has(c) or arena.flames.has(c):
				continue
			if c == arena.exit_cell or c == anchor:
				continue
			if not to_twin and absi(c.x - hc.x) + absi(c.y - hc.y) < 3:
				continue
			var taken: bool = false
			for cr: Arena.Critter in arena.critters:
				if cr != b and (cr.cell == c or cr.target == c):
					taken = true
					break
			if taken:
				continue
			var score: float = Vector2(c - want).length_squared() + arena.rng.randf() * 3.0
			if score < best_score:
				best_score = score
				best = c
	return best


func _make_marker(c: Vector2i, plus: bool) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(c.x, 0.03, c.y)
	arena.add_child(root)
	var cells: Array[Vector2i] = [Vector2i.ZERO]
	if plus:
		for d: Vector2i in Arena.DIRS:
			if arena.tile(c + d) == Arena.FLOOR and not blocks(c + d):
				cells.append(d)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.3
	ring.outer_radius = 0.42
	ring.rings = 24
	ring.ring_segments = 4
	for d: Vector2i in cells:
		var mi := Models.part(root, ring, Color("#F2F7FF"), Vector3(d.x, 0, d.y), 1.0)
		mi.scale = Vector3(1.0, 0.25, 1.0) * (1.0 if d == Vector2i.ZERO else 0.7)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var disc := Models.part(root, Models.cylinder(0.3, 0.3, 0.01, 18), M.WATER_DEEP, Vector3(d.x, -0.01, d.y), 0.3)
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


func _end_dive_marker() -> void:
	var mk: Node3D = _dive.get("marker")
	if mk != null and is_instance_valid(mk):
		mk.queue_free()


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


## A soft harp-like rising chord: a lotus bell blooms.
func _make_bloom() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.1)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for note: Array in [[0.0, 659.3], [0.08, 830.6], [0.16, 987.8], [0.24, 1318.5]]:
			var tt: float = t - float(note[0])
			if tt < 0.0:
				continue
			var f: float = note[1]
			v += (sin(TAU * f * tt) + 0.3 * sin(TAU * f * 2.0 * tt) * exp(-tt * 6.0)) * exp(-tt * 3.0) * minf(tt / 0.004, 1.0)
		out[i] = v * 0.22
	return _wav(out)


## A watery "plip-sploosh": a falling bubble tone over soft noise.
func _make_splash() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 2424
	var lp: float = 0.0
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		lp += (r.randf_range(-1.0, 1.0) - lp) * 0.25
		ph += TAU * (900.0 * exp(-t * 9.0) + 220.0) / rate
		var bubble: float = sin(ph) * exp(-t * 10.0)
		out[i] = (lp * exp(-t * 6.0) * 0.9 + bubble * 0.6) * minf(t / 0.005, 1.0) * 0.5
	return _wav(out)


## A shimmering downward sweep: the Shade scatters like ripples.
func _make_scatter() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		ph += TAU * (1400.0 - t * 1800.0) / rate
		out[i] = sin(ph) * sin(TAU * 18.0 * t) * exp(-t * 5.0) * 0.3
	return _wav(out)

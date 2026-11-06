extends WorldKit
## World 23, Seasons Grove: a cosy orchard that turns through the four
## seasons every few seconds (a chip at the bottom of the screen counts
## down, with a two-second warning), and blasting a season totem skips
## straight to the next one. Each season changes the board:
##   spring  flower bushes grow on flower spots (they block walking, and
##           burn away to a blast)
##   summer  clear and hot: every blast reaches one tile further
##   autumn  leaf piles cover leaf spots: they hide power-ups, slow
##           critters down and burn away to a blast
##   winter  ponds freeze into walkable ice bridges (no sliding); in spring
##           the ice thaws, and Pip, if he is standing on it, is nudged to
##           the nearest dry tile, never dropped in
## The grass, hedges, trees, pillar caps, sky and light all ease into the
## season's colours. Hedgehogs wander in spring, scurry and chase in summer,
## forage in autumn and hibernate all winter (they cannot be hit, but cannot
## hurt Pip either). The Season Stag boss stamps in a new season every
## time it is hit.
##
## Extra map characters:
##   T  season totem      f  flower spot      l  leaf spot
##   p  pond              h  hedgehog
## Level keys: "start" (first season, 0-3), "season_time" (seconds).

const M := preload("res://worlds/world_23_models.gd")

const SEASON_TIME: float = 10.0
const WARN: float = 2.0
const BLEND: float = 1.4
const TOTEM_COOL: float = 0.8
const NUDGE_SPEED: float = 7.0
const NAMES: Array[String] = ["SPRING", "SUMMER", "AUTUMN", "WINTER"]
const PERKS: Array[String] = ["BUSHES GROW", "BLASTS +1", "LEAF PILES", "PONDS FROZEN"]

## Season colours for every recoloured material: spring, summer, autumn, winter.
const COLS: Dictionary = {
	"GRASS_A": ["#B9E49B", "#A3D96F", "#EDCD86", "#EEF4FA"],
	"GRASS_B": ["#A9D98A", "#91CD61", "#E2BE70", "#E0E9F3"],
	"RIM": ["#98CE7C", "#82C058", "#D8AB63", "#E6EEF7"],
	"LEAFY_A": ["#9FDB81", "#5DBB5A", "#F0973F", "#F4F8FC"],
	"LEAFY_B": ["#F6AECB", "#4AA352", "#D9622F", "#DCE7F1"],
	"crown": ["#FFC4DA", "#62C25E", "#F3A23E", "#E3EAF2"],
	"crown2": ["#FF9EC4", "#4DAA50", "#E2682F", "#CFDAE6"],
	"cap": ["#78B65A", "#6AAE4C", "#C9772F", "#FAFCFF"],
	"tips": ["#FF9EC4", "#6CC55C", "#F2902E", "#FFFFFF"],
	"drift": ["#FFC4DA", "#FFF3A6", "#F2902E", "#FFFFFF"],
}
const SKY_TOP: Array[String] = ["#8ED2F6", "#6CC2F4", "#A9BFE0", "#B6CAE6"]
const SKY_HORIZON: Array[String] = ["#FDF1DC", "#FFF4CF", "#FFD9A6", "#F2F6FB"]
const SKY_GROUND: Array[String] = ["#D7EFD0", "#CFEBC0", "#F2DDB8", "#E8EEF6"]
const SUN_COL: Array[String] = ["#FFF6E6", "#FFF0CC", "#FFDDB0", "#EEF4FF"]
const SUN_E: Array[float] = [1.4, 1.55, 1.35, 1.3]
const AMB_COL: Array[String] = ["#D3E8EE", "#DCEBD2", "#F0DCC4", "#DDE7F4"]
const AMB_E: Array[float] = [0.6, 0.58, 0.6, 0.72]

const PALETTE: Dictionary = {
	"GRASS_A": "#B9E49B", "GRASS_B": "#A9D98A", "RIM": "#98CE7C", "EDGE": "#BCAB90",
	"STONE": "#ECE4D6", "DARK_STONE": "#C2B29B", "DIRT": "#B98A5F", "ROCK": "#9C8775",
	"WOOD": "#B68BE6", "WOOD_DARK": "#F1E4FF", "BARREL": "#E2553F", "BELT": "#8C6A4E", "ACCENT": "#FFC93C",
	"BLOSSOM_A": "#FFB3CF", "BLOSSOM_B": "#FF9EC4", "TRUNK": "#8C5A36", "LEAFY_A": "#9FDB81", "LEAFY_B": "#F6AECB",
	"SKY_TOP": "#8ED2F6", "SKY_HORIZON": "#FDF1DC", "SKY_GROUND": "#D7EFD0", "CLOUD": "#FFFFFF", "CLOUDS": 0.5,
	"AMBIENT": "#D3E8EE", "AMBIENT_ENERGY": 0.6, "SUN": "#FFF6E6", "SUN_ENERGY": 1.4,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Blossom Path",
		"tip": "Seasons turn every few seconds!\nWinter freezes the pond into a\nbridge. Blast the totem to skip on.",
		"crates": 0.4, "par": 75, "start": 1,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.h.........#",
			"#.#.#.#.#.#.#",
			"#...l...l.h.#",
			"#.#.#_T_#.#.#",
			"#.ppppppppp.#",
			"#.#.#.#.#.#.#",
			"#.b..l...b..#",
			"#.#.#.#.#.#.#",
			"#...ff.ff...#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Orchard Rows",
		"tip": "Spring bushes block the way. Autumn\nleaves hide goodies and slow critters.\nSummer blasts reach one tile further!",
		"crates": 0.42, "par": 85, "start": 0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.h...E...h.#",
			"#.#f#.#.#f#.#",
			"#..f.....f..#",
			"#.#.#ppp#.#.#",
			"#.lll.T.lll.#",
			"#.#.#ppp#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b..lll..z.#",
			"#.#f#.#.#f#.#",
			"#..f..h..f..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Frozen Pond",
		"tip": "The exit sits on a pond island.\nCross on winter ice, or burn\nthe spring bush in the gap.",
		"crates": 0.4, "par": 92, "start": 2,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.h.......h.#",
			"#.#.#.#.#.#.#",
			"#...ppppp...#",
			"#.#.p...p.#.#",
			"#...p.E.p...#",
			"#.#.p..hp.#.#",
			"#...pp.pp...#",
			"#.#.#.f.#.#.#",
			"#.l..lTl..l.#",
			"#.#.#.#.#.#.#",
			"#.b..h...z..#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Harvest Hop",
		"tip": "Hedgehogs nap all winter: they\ncan't be hit, but can't hurt you.\nCatch them while they're awake!",
		"crates": 0.42, "par": 100, "start": 0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#1.h..E..h.2#",
			"#.#.#.#.#.#.#",
			"#.ff.lll.ff.#",
			"#.#T#.#.#T#.#",
			"#.....h.....#",
			"#pp.#.#.#.pp#",
			"#pp.z...b.pp#",
			"#pp.#.#.#.pp#",
			"#...........#",
			"#.#.#B#B#.#.#",
			"#.lll.h.lll.#",
			"#.#.#_#_#.#.#",
			"#2..._S_...1#",
			"#############",
		],
	},
	{
		"name": "Winter Crossing",
		"tip": "A lake splits the grove. Burn the\nbushy bridge or wait for the freeze.\nThawing ice nudges you ashore.",
		"crates": 0.4, "par": 110, "start": 1,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#.h..lEl..h.#",
			"#.#.#.#.#.#.#",
			"#.l..z....l.#",
			"#.#.#._.#.#.#",
			"#pppppfppppp#",
			"#ppp.T.T.ppp#",
			"#pppppfppppp#",
			"#.#.#._.#.#.#",
			"#..h.l.l.b..#",
			"#.#.#.#.#.#.#",
			"#.z..lll..h.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "The Season Stag",
		"tip": "Every hit makes the Stag stamp\nin a new season. Watch the\nground change under your feet!",
		"crates": 0.18, "par": 140, "boss": true, "start": 1, "season_time": 8.0,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.pp.....pp.#",
			"#.pp.f.f.pp.#",
			"#...l...l...#",
			"#.#..T.T..#.#",
			"#.l...K...l.#",
			"#.#.......#.#",
			"#...l...l...#",
			"#.pp.f.f.pp.#",
			"#.pp.....pp.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

var season: int = 0
var _left: float = SEASON_TIME
var _length: float = SEASON_TIME
var _ready: bool = false
var _warned: bool = false
var _clock: float = 0.0

var totems: Dictionary = {}      # Vector2i -> Node3D
var flowers: Dictionary = {}     # Vector2i -> {"mark", "bush", "k", "mode", "burnt"}
var leaves: Dictionary = {}      # Vector2i -> {"mark", "pile", "k", "mode", "delay", "burnt"}
var ponds: Dictionary = {}       # Vector2i -> {"node", "frozen", "k"}
var _totem_cool: float = 0.0

var _mats: Dictionary = {}       # key -> ShaderMaterial
var _from: Dictionary = {}       # key -> Color
var _shown: Dictionary = {}      # key -> Color
var _blend: float = 1.0
var _env: Environment
var _sun: DirectionalLight3D
var _sky_mat: ShaderMaterial

var _trees: Array[Node3D] = []
var _drift: MultiMesh
var _drift_seeds: Array[Vector4] = []
var _snow_mm: MultiMeshInstance3D
var _speed: Dictionary = {}      # Critter -> [base, last set]
var _hog: Dictionary = {}        # Critter -> curl 0..1
var _held: Dictionary = {}       # hedgehogs held still while curled
var _boost: Dictionary = {}      # Pod -> true while it carries the summer +1
var _push: Dictionary = {}
var _boss_hp: int = -1
var _ui: Control
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_chime: AudioStreamWAV
var _snd_freeze: AudioStreamWAV
var _snd_splash: AudioStreamWAV
var _snd_rustle: AudioStreamWAV
var _snd_tick: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Seasons Grove"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_23.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "SEASON STAG"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	return &"hedgehog"


# --- Seasonal materials ---------------------------------------------------------

## Sets up the season and the recolourable materials the first time any
## part needs them (critter models and rim props are made before
## build_extra runs).
func _ensure() -> void:
	if _ready:
		return
	_ready = true
	season = int(arena.data.get("start", 0)) % 4
	_length = float(arena.data.get("season_time", SEASON_TIME))
	_left = _length
	for key: String in COLS:
		var c := Color(COLS[key][season])
		var m: ShaderMaterial = Models.mat(c).duplicate()
		_mats[key] = m
		_shown[key] = c
		_from[key] = c


func _mat(key: String) -> ShaderMaterial:
	_ensure()
	return _mats[key]


## Swaps the base world's shared grass, rim and hedge materials for our own
## copies, so they can follow the seasons without touching the shared cache.
func _adopt_base_materials() -> void:
	var swap: Dictionary = {}
	for key: String in ["GRASS_A", "GRASS_B", "RIM", "LEAFY_A", "LEAFY_B"]:
		swap[Models.mat(Color(PALETTE[key]))] = _mat(key)
	swap[Models.mat(Color(PALETTE["EDGE"]).lightened(0.24))] = _mat("cap")
	var stack: Array[Node] = [arena]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for ch: Node in n.get_children():
			stack.append(ch)
		if n is GeometryInstance3D:
			var g := n as GeometryInstance3D
			if g.material_override != null and swap.has(g.material_override):
				g.material_override = swap[g.material_override]


func _apply_colours(k: float) -> void:
	for key: String in COLS:
		var to := Color(COLS[key][season])
		var c: Color = (_from[key] as Color).lerp(to, k)
		_shown[key] = c
		(_mats[key] as ShaderMaterial).set_shader_parameter(&"albedo", c)
	if _sky_mat != null:
		_sky_mat.set_shader_parameter(&"top_color", _sky_from[0].lerp(Color(SKY_TOP[season]), k))
		_sky_mat.set_shader_parameter(&"horizon_color", _sky_from[1].lerp(Color(SKY_HORIZON[season]), k))
		_sky_mat.set_shader_parameter(&"ground_color", _sky_from[2].lerp(Color(SKY_GROUND[season]), k))
		var top: Color = (_sky_from[0] as Color).lerp(Color(SKY_TOP[season]), k).srgb_to_linear()
		RenderingServer.global_shader_parameter_set(&"sky_tint", Vector3(top.r, top.g, top.b))
	if _sun != null:
		_sun.light_color = (_sky_from[3] as Color).lerp(Color(SUN_COL[season]), k)
		_sun.light_energy = lerpf(float(_sky_from[4]), SUN_E[season], k)
	if _env != null:
		_env.ambient_light_color = (_sky_from[5] as Color).lerp(Color(AMB_COL[season]), k)
		_env.ambient_light_energy = lerpf(float(_sky_from[6]), AMB_E[season], k)


var _sky_from: Array = []


func _snapshot_sky() -> void:
	_sky_from = [
		_sky_mat.get_shader_parameter(&"top_color") if _sky_mat != null else Color(SKY_TOP[season]),
		_sky_mat.get_shader_parameter(&"horizon_color") if _sky_mat != null else Color(SKY_HORIZON[season]),
		_sky_mat.get_shader_parameter(&"ground_color") if _sky_mat != null else Color(SKY_GROUND[season]),
		_sun.light_color if _sun != null else Color(SUN_COL[season]),
		_sun.light_energy if _sun != null else SUN_E[season],
		_env.ambient_light_color if _env != null else Color(AMB_COL[season]),
		_env.ambient_light_energy if _env != null else AMB_E[season],
	]


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"T":
			totems[c] = null
			return true
		"f":
			flowers[c] = {}
			return true
		"l":
			leaves[c] = {}
			return true
		"p":
			ponds[c] = {}
			return true
	return false


func critter_chars() -> Dictionary:
	return {"h": &"hedgehog"}


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	_ensure()
	_env = env
	_sun = sun
	if env.sky != null:
		_sky_mat = env.sky.sky_material as ShaderMaterial
	env.adjustment_saturation = 1.08


func build_extra() -> void:
	_ensure()
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 23
	for c: Vector2i in totems:
		var t: Node3D = M.totem()
		t.position = Vector3(c.x, 0, c.y)
		arena.add_child(t)
		totems[c] = t
		(t.get_node("Icons") as Node3D).rotation.y = PI * 0.5 * season
	for c: Vector2i in flowers:
		var mk: Node3D = M.sprout()
		mk.position = Vector3(c.x, 0, c.y)
		arena.add_child(mk)
		flowers[c] = {"mark": mk, "bush": null, "k": 0.0, "mode": &"none", "burnt": false}
	for c: Vector2i in leaves:
		var mk: Node3D = M.leaf_mark(r)
		mk.position = Vector3(c.x, 0, c.y)
		arena.add_child(mk)
		leaves[c] = {"mark": mk, "pile": null, "k": 0.0, "mode": &"none", "delay": 0.0, "burnt": false}
	for c: Vector2i in ponds:
		var edges: Array = []
		for d: Vector2i in Arena.DIRS:
			if not ponds.has(c + d) and arena.tile(c + d) != Arena.WALL:
				edges.append(d)
		var pn: Node3D = M.pond(r, edges)
		pn.position = Vector3(c.x, 0, c.y)
		arena.add_child(pn)
		ponds[c] = {"node": pn, "frozen": false, "k": 0.0}
	_adopt_base_materials()
	_build_snow()
	_build_drift()
	_snapshot_sky()
	_apply_colours(1.0)
	_enter_season(true)
	_check_level()
	if not arena.demo:
		_build_ui()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -7.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -9.0
	arena.add_child(_player2)
	_snd_chime = _make_chime()
	_snd_freeze = _make_freeze()
	_snd_splash = _make_splash()
	_snd_rustle = _make_rustle()
	_snd_tick = _make_tick()


## Snow lumps over the floor, shown in winter.
func _build_snow() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 2323
	var lumps: Array[Transform3D] = []
	for z in range(0, Arena.H):
		for x in range(0, Arena.W):
			var c := Vector2i(x, z)
			if ponds.has(c) or r.randf() > 0.35:
				continue
			var border: bool = x == 0 or z == 0 or x == Arena.W - 1 or z == Arena.H - 1
			var y: float = 0.68 if border else 0.0
			if not border and arena.tile(c) == Arena.WALL:
				continue
			var p := Vector3(x + r.randf_range(-0.32, 0.32), y, z + r.randf_range(-0.32, 0.32))
			var s: float = r.randf_range(0.6, 1.1)
			lumps.append(Transform3D(Basis().scaled(Vector3(s, s * 0.35, s)), p))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Models.sphere(0.16, -1, 10)
	mm.instance_count = lumps.size()
	for i in lumps.size():
		mm.set_instance_transform(i, lumps[i])
	_snow_mm = MultiMeshInstance3D.new()
	_snow_mm.multimesh = mm
	_snow_mm.material_override = Models.mat(Color("#FFFFFF"))
	_snow_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(_snow_mm)


## Drifting petals, pollen, leaves or snowflakes.
func _build_drift() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	_drift = MultiMesh.new()
	_drift.transform_format = MultiMesh.TRANSFORM_3D
	_drift.mesh = Models.box_mesh(Vector3(0.09, 0.015, 0.07), 0.006)
	_drift.instance_count = 36
	for i in 36:
		_drift_seeds.append(Vector4(r.randf_range(-1.5, Arena.W + 0.5), r.randf_range(-1.5, Arena.H + 0.5), r.randf() * 10.0, r.randf_range(0.7, 1.3)))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _drift
	mmi.material_override = _mat("drift")
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)


## Reports map mistakes: an exit or critter Pip can never reach (ponds
## count as walkable, since winter comes round; totems are solid), and
## pond, flower or leaf spots on special tiles.
func _check_level() -> void:
	var name: String = arena.data["name"]
	for dict: Dictionary in [flowers, leaves, ponds, totems]:
		for c: Vector2i in dict:
			if c == arena.start_cell or c == arena.exit_cell or arena.warps.has(c):
				push_error("World 23 '%s': special tile %s sits on the start, exit or a warp" % [name, c])
	for pass_i in 2:
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
				if reach.has(nc) or arena.tile(nc) == Arena.WALL or totems.has(nc):
					continue
				if pass_i == 1 and ponds.has(nc):
					continue
				reach[nc] = true
				queue.append(nc)
		if pass_i == 0:
			if not reach.has(arena.exit_cell):
				push_error("World 23 '%s': exit not reachable" % name)
			for cr: Arena.Critter in arena.critters:
				if not reach.has(cr.cell):
					push_error("World 23 '%s': critter at %s not reachable" % [name, cr.cell])
		elif not reach.has(arena.exit_cell) and OS.is_debug_build():
			print("World 23 '%s': exit needs winter ice (by design?)" % name)


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Stone blocks with a mossy cap that turns orange in autumn and snowy in
	# winter, and a few pebbles.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var bodies: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var turn := Basis(Vector3.UP, r.randf_range(-0.1, 0.1))
		bodies.append(Transform3D(turn, p + Vector3(0, 0.33, 0)))
		caps.append(Transform3D(turn, p + Vector3(0, 0.71, 0)))
		bands.append(Transform3D(turn, p + Vector3(0, 0.18, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.66, 0.84), 0.12), Color("#A08D76"), bodies)
	arena._multimesh(Models.box_mesh(Vector3(0.88, 0.04, 0.88), 0.015), Color("#8A7862"), bands)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.14, 0.9), 0.06), Color.WHITE, caps, _mat("cap"))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M.mushroom(r)
		elif roll < 0.3:
			node = M.pumpkin(r)
		elif roll < 0.42:
			node = M.fence(r)
	else:
		if roll < 0.3:
			node = M.orchard_tree(r, _mat("crown"), _mat("crown2"), 1.0 if p.z >= 0.0 else 1.25)
			_trees.append(node)
		elif roll < 0.38:
			node = M.haystack(r)
		elif roll < 0.46:
			node = M.apple_crate(r)
		elif roll < 0.56:
			node = M.fence(r)
			if p.x < 0.0 or p.x > Arena.W - 1:
				node.rotation.y += PI * 0.5
		elif roll < 0.64:
			node = M.pumpkin(r)
		elif roll < 0.72:
			node = M.mushroom(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var t := M.orchard_tree(r, _mat("crown"), _mat("crown2"), 1.6)
	t.position = Vector3(-size * 0.15, 0, -size * 0.1)
	root.add_child(t)
	_trees.append(t)
	if r.randf() < 0.6:
		var t2 := M.orchard_tree(r, _mat("crown"), _mat("crown2"), 1.1)
		t2.position = Vector3(size * 0.25, 0, size * 0.15)
		root.add_child(t2)
		_trees.append(t2)
	else:
		var h := M.haystack(r)
		h.scale = Vector3.ONE * 1.4
		h.position = Vector3(size * 0.25, 0, size * 0.15)
		root.add_child(h)
	return root


# --- Rules ------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	if totems.has(c):
		return true
	if ponds.has(c) and not bool(ponds[c].get("frozen", false)):
		return true
	if flowers.has(c):
		var f: Dictionary = flowers[c]
		if f.get("mode", &"none") == &"grow" or f.get("mode", &"none") == &"full":
			return true
	return false


func flame_stop(c: Vector2i) -> int:
	if totems.has(c):
		return 1
	if flowers.has(c) and flowers[c].get("bush") != null and flowers[c].get("mode") != &"wilt":
		return 1
	return 0


func on_flame(c: Vector2i) -> void:
	if totems.has(c) and _totem_cool <= 0.0:
		_totem_cool = TOTEM_COOL
		var t: Node3D = totems[c]
		arena._spawn_sparkles(Vector3(c.x, 1.0, c.y), M.SEASON_COLORS[(season + 1) % 4])
		t.scale = Vector3(1.15, 0.85, 1.15)
		_advance()
	if flowers.has(c):
		var f: Dictionary = flowers[c]
		if f["bush"] != null and f["mode"] != &"wilt":
			f["mode"] = &"wilt"
			f["burnt"] = true
			_burst(Vector3(c.x, 0.4, c.y), [Color("#7CC75E"), Color("#FF8FB8"), Color("#FFFFFF")])
	if leaves.has(c):
		var l: Dictionary = leaves[c]
		if l["pile"] != null and l["mode"] != &"gone":
			l["mode"] = &"gone"
			l["burnt"] = true
			_burst(Vector3(c.x, 0.2, c.y), M.LEAF_COLORS)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not blocks(c)


func critter_smart(kind: StringName) -> bool:
	return kind == &"hedgehog" and season == 1


func _burst(at: Vector3, cols: Array) -> void:
	var leaf := M.leaf_mesh(0.07, 0.02)
	for k in 8:
		var piece := Models.part(arena, leaf, cols[k % cols.size()], at + Vector3(randf_range(-0.2, 0.2), randf_range(-0.05, 0.15), randf_range(-0.2, 0.2)))
		piece.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)
		piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var ang: float = TAU * k / 8.0 + randf_range(-0.3, 0.3)
		var out: float = randf_range(1.2, 2.6)
		arena._fx.append({"node": piece, "t": 0.0, "life": randf_range(0.7, 1.0), "kind": &"debris", "floor": 0.03, "drag": 2.0,
			"vel": Vector3(cos(ang) * out, randf_range(2.0, 3.6), sin(ang) * out),
			"spin": Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))})


# --- Seasons ---------------------------------------------------------------------

func _advance() -> void:
	season = (season + 1) % 4
	_left = _length
	_warned = false
	for key: String in COLS:
		_from[key] = _shown[key]
	_snapshot_sky()
	_blend = 0.0
	_enter_season(false)
	_sound(_player, _snd_chime, [1.0, 1.12, 0.89, 0.75][season])
	if _ui != null:
		_ui.queue_redraw()


func _enter_season(first: bool) -> void:
	for t: Node3D in _trees:
		(t.find_child("Fruit", true, false) as Node3D).visible = season == 1 or season == 2
		(t.find_child("Snow", true, false) as Node3D).visible = season == 3
	match season:
		0:
			for c: Vector2i in flowers:
				flowers[c]["burnt"] = false
		1:
			for c: Vector2i in flowers:
				var f: Dictionary = flowers[c]
				if f["bush"] != null:
					f["mode"] = &"wilt"
		2:
			var i: int = 0
			for c: Vector2i in leaves:
				var l: Dictionary = leaves[c]
				l["burnt"] = false
				if l["pile"] == null:
					l["delay"] = 0.0 if first else 0.08 * i
					l["mode"] = &"fall"
				i += 1
			if not first:
				_sound(_player2, _snd_rustle, 0.9)
		3:
			for c: Vector2i in leaves:
				if leaves[c]["pile"] != null:
					leaves[c]["mode"] = &"gone"
			for c: Vector2i in ponds:
				ponds[c]["frozen"] = true
			if not first and not ponds.is_empty():
				_sound(_player2, _snd_freeze, 1.0)


func process(delta: float) -> void:
	_ensure()
	_clock += delta
	_totem_cool = maxf(_totem_cool - delta, 0.0)
	var playing: bool = arena.demo or arena.state == &"play"
	if playing:
		_left -= delta
		if _left <= WARN and not _warned:
			_warned = true
			_sound(_player2, _snd_tick, 1.0)
		if _left <= 0.0:
			_advance()
	if _blend < 1.0:
		_blend = minf(_blend + delta / BLEND, 1.0)
		var k: float = _blend * _blend * (3.0 - 2.0 * _blend)
		_apply_colours(k)
	_update_totems(delta)
	_update_flowers(delta)
	_update_leaves(delta)
	_update_ponds(delta)
	_update_push(delta)
	_update_critters(delta)
	_update_pods()
	_update_drift(delta)
	_update_boss()
	if _snow_mm != null:
		var want: float = 1.0 if season == 3 else 0.0
		var s: float = move_toward(_snow_mm.scale.y, want, delta * 1.2)
		_snow_mm.scale = Vector3(1.0, s, 1.0)
		_snow_mm.visible = s > 0.01
	if _ui != null:
		_ui.visible = arena.state == &"play" and not arena.get_tree().paused
		if _ui.visible:
			_ui.queue_redraw()


func _update_totems(delta: float) -> void:
	var warn: bool = _left <= WARN
	for c: Vector2i in totems:
		var t: Node3D = totems[c]
		t.scale = t.scale.lerp(Vector3.ONE, minf(delta * 8.0, 1.0))
		var icons: Node3D = t.get_node("Icons")
		var want: float = PI * 0.5 * season
		icons.rotation.y = lerp_angle(icons.rotation.y, want, minf(delta * 6.0, 1.0))
		icons.position.y = 0.86 + sin(_clock * 2.0 + c.x) * 0.02
		var top: Node3D = icons.get_node("Top")
		for s in 4:
			(top.get_node("Flat%d" % s) as Node3D).visible = s == season
		(top.get_node("Disc") as MeshInstance3D).material_override = Models.mat(M.SEASON_COLORS[season].lightened(0.35))
		top.rotation.y = -icons.rotation.y
		var glow: MeshInstance3D = t.get_node("Glow")
		glow.visible = warn
		if warn:
			var p: float = 1.0 + sin(_clock * 14.0) * 0.08
			glow.scale = Vector3(p, 0.3, p)
			glow.material_override = Models.mat(M.SEASON_COLORS[(season + 1) % 4], 0.8)


func _hero_on(c: Vector2i, reach: float) -> bool:
	if arena.demo or arena.hero == null or not arena.hero_alive:
		return false
	return absf(arena.hero_pos.x - c.x) < reach and absf(arena.hero_pos.y - c.y) < reach


func _critter_on(c: Vector2i) -> bool:
	for cr: Arena.Critter in arena.critters:
		if cr.cell == c or (cr.t < 1.0 and cr.target == c) or Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			return true
	return false


func _update_flowers(delta: float) -> void:
	var r := arena.rng
	for c: Vector2i in flowers:
		var f: Dictionary = flowers[c]
		var mk: Node3D = f["mark"]
		var sprout: Node3D = mk.get_node("Sprout")
		# Sprouts perk up and wiggle just before spring.
		var soon: bool = season == 3 and _left <= WARN
		sprout.scale = Vector3.ONE * (1.6 if soon else 1.0)
		sprout.rotation.z = sin(_clock * 12.0 + c.x) * 0.25 if soon else 0.0
		sprout.visible = f["bush"] == null
		if season == 0 and f["bush"] == null and not bool(f["burnt"]):
			if not arena.flames.has(c) and not arena.pod_at.has(c) and not _hero_on(c, 0.85) and not _critter_on(c) and not arena.pickups.has(c):
				var b: Node3D = M.flower_bush(r)
				b.position = Vector3(c.x, 0, c.y)
				b.rotation.y = r.randf() * TAU
				b.scale = Vector3.ONE * 0.05
				arena.add_child(b)
				f["bush"] = b
				f["k"] = 0.0
				f["mode"] = &"grow"
				if not arena.demo and arena.hero != null and arena.hero_pos.distance_to(Vector2(c)) < 6.0:
					_sound(_player2, _snd_rustle, randf_range(1.1, 1.3))
		var bush: Node3D = f["bush"]
		if bush == null:
			continue
		match f["mode"]:
			&"grow":
				f["k"] = minf(float(f["k"]) + delta / 0.5, 1.0)
				var k: float = float(f["k"])
				bush.scale = Vector3.ONE * maxf(0.05, k * (1.0 + sin(k * PI) * 0.2))
				if k >= 1.0:
					f["mode"] = &"full"
			&"full":
				var body: Node3D = bush.get_node("Body")
				body.scale = Vector3(1.0 + sin(_clock * 2.0 + c.y) * 0.02, 1.0 - sin(_clock * 2.0 + c.y) * 0.02, 1.0)
			&"wilt":
				f["k"] = maxf(float(f["k"]) - delta / 0.45, 0.0)
				bush.scale = Vector3.ONE * maxf(float(f["k"]), 0.01)
				if float(f["k"]) <= 0.0:
					bush.queue_free()
					f["bush"] = null
					f["mode"] = &"none"


func _update_leaves(delta: float) -> void:
	var r := arena.rng
	for c: Vector2i in leaves:
		var l: Dictionary = leaves[c]
		var mode: StringName = l["mode"]
		(l["mark"] as Node3D).visible = l["pile"] == null
		if mode == &"fall" and l["pile"] == null and not bool(l["burnt"]) and season == 2:
			l["delay"] = float(l["delay"]) - delta
			if float(l["delay"]) <= 0.0 and not arena.flames.has(c):
				var p: Node3D = M.leaf_pile(r)
				p.position = Vector3(c.x, 1.2, c.y)
				p.rotation.y = r.randf() * TAU
				arena.add_child(p)
				l["pile"] = p
				l["k"] = 0.0
		var pile: Node3D = l["pile"]
		if pile == null:
			continue
		if mode == &"fall":
			l["k"] = minf(float(l["k"]) + delta / 0.45, 1.0)
			var k: float = float(l["k"])
			pile.position.y = (1.0 - k * k) * 1.2
			pile.scale = Vector3(1.0, 0.6 + 0.4 * k, 1.0)
			if k >= 1.0:
				l["mode"] = &"full"
		elif mode == &"full":
			pile.position.y = 0.0
			# A pile with a power-up under it rustles now and then.
			var body: Node3D = pile.get_node("Body")
			if arena.pickups.has(c):
				body.rotation.y = sin(_clock * 18.0) * 0.08 * maxf(sin(_clock * 1.7 + c.x), 0.0)
			else:
				body.rotation.y = 0.0
		elif mode == &"gone":
			l["k"] = maxf(float(l["k"]) - delta / 0.35, 0.0)
			pile.scale = Vector3(1.0, maxf(float(l["k"]), 0.01), 1.0) * maxf(float(l["k"]), 0.2)
			if float(l["k"]) <= 0.0:
				pile.queue_free()
				l["pile"] = null
				l["mode"] = &"none"
	# Hide power-ups under full piles.
	for c: Vector2i in arena.pickups:
		var node: Node3D = arena.pickups[c]["node"]
		node.visible = not (leaves.has(c) and leaves[c]["pile"] != null and leaves[c]["mode"] == &"full")


func _covered(c: Vector2i) -> bool:
	return leaves.has(c) and leaves[c]["pile"] != null and leaves[c]["mode"] != &"gone"


func _update_ponds(delta: float) -> void:
	var cracking: bool = season == 3 and _left <= WARN
	for c: Vector2i in ponds:
		var pd: Dictionary = ponds[c]
		var n: Node3D = pd["node"]
		var ice: Node3D = n.get_node("Ice")
		var water: Node3D = n.get_node("Water")
		var ripple: Node3D = water.get_node("Ripple")
		var rk: float = fmod(_clock * 0.5 + c.x * 0.37 + c.y * 0.61, 1.0)
		ripple.scale = Vector3(0.4 + rk * 1.4, 0.2, 0.4 + rk * 1.4)
		ripple.visible = not bool(pd["frozen"])
		if bool(pd["frozen"]) and season != 3:
			# Thaw, unless something still stands on the ice.
			var busy: bool = arena.pod_at.has(c) or _critter_on(c) or (arena.boss != null and arena.critters.has(arena.boss) and arena.boss.pos.distance_to(Vector2(c)) < 0.9)
			if not busy and _hero_on(c, 0.85):
				busy = true
				if _push.is_empty():
					_nudge_hero()
			if not busy:
				pd["frozen"] = false
				if not arena.demo and arena.hero != null and arena.hero_pos.distance_to(Vector2(c)) < 5.0:
					_sound(_player2, _snd_splash, randf_range(0.9, 1.15))
		var want: float = 1.0 if bool(pd["frozen"]) else 0.0
		pd["k"] = move_toward(float(pd["k"]), want, delta / 0.5)
		var k: float = float(pd["k"])
		ice.visible = k > 0.01
		ice.scale = Vector3(lerpf(0.6, 1.0, k), k, lerpf(0.6, 1.0, k))
		ice.position = Vector3(sin(_clock * 40.0 + c.x) * 0.015, 0, 0) if cracking else Vector3.ZERO


## Finds the nearest dry, safe tile and glides Pip there along the ice.
func _nudge_hero() -> void:
	var start: Vector2i = arena.hero_cell()
	var danger: Dictionary = arena._danger_cells()
	for strict: bool in [true, false]:
		var prev: Dictionary = {start: start}
		var queue: Array[Vector2i] = [start]
		while not queue.is_empty():
			var c: Vector2i = queue.pop_front()
			if c != start or not ponds.has(c):
				if not ponds.has(c) and _safe_spot(c) and (not strict or not danger.has(c)):
					var path: Array[Vector2] = []
					var at: Vector2i = c
					while at != start:
						path.push_front(Vector2(at))
						at = prev[at]
					path.push_front(Vector2(start))
					_push = {"path": path, "i": 0}
					arena.walk_goal = Arena.NO_CELL
					_sound(_player2, _snd_splash, 1.3)
					return
			for d: Vector2i in Arena.DIRS:
				var nc: Vector2i = c + d
				if prev.has(nc) or prev.size() > 80:
					continue
				if arena.tile(nc) != Arena.FLOOR or totems.has(nc):
					continue
				if not ponds.has(nc) and blocks(nc):
					continue
				prev[nc] = c
				queue.append(nc)


func _safe_spot(c: Vector2i) -> bool:
	if arena.tile(c) != Arena.FLOOR or blocks(c) or arena.flames.has(c) or _critter_on(c):
		return false
	if arena.pod_at.has(c) and not arena.hero_pass.has(arena.pod_at[c]):
		return false
	return true


func _update_push(delta: float) -> void:
	if _push.is_empty():
		return
	if arena.hero == null or not arena.hero_alive or arena.state != &"play":
		_push.clear()
		return
	var path: Array = _push["path"]
	var i: int = _push["i"]
	var target: Vector2 = path[mini(i + 1, path.size() - 1)]
	arena.hero_pos = arena.hero_pos.move_toward(target, NUDGE_SPEED * delta)
	if arena.hero_pos.distance_to(target) < 0.001:
		_push["i"] = i + 1
		if i + 1 >= path.size() - 1:
			_push.clear()


# --- Critters --------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"hedgehog":
			return M.hedgehog()
		&"boss":
			return M.stag(_mat("tips"))
	return null


func critter_speed(kind: StringName) -> float:
	if kind == &"hedgehog":
		return 1.85 + 0.08 * arena.level_id
	return 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func _sleeping(cr: Arena.Critter) -> bool:
	return cr.kind == &"hedgehog" and season == 3


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr.kind == &"hedgehog" and float(_hog.get(cr, 0.0)) > 0.5


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"hedgehog" or season != 2 or arena.rng.randf() < 0.4:
		return Vector2i.ZERO
	# Autumn: forage towards the nearest leaf pile.
	var best: Vector2i = Vector2i.ZERO
	var best_d: int = 99
	for c: Vector2i in leaves:
		if leaves[c]["pile"] == null or c == cr.cell:
			continue
		var d: int = absi(c.x - cr.cell.x) + absi(c.y - cr.cell.y)
		if d < best_d:
			best_d = d
			best = c
	if best_d > 8:
		return Vector2i.ZERO
	var gap: Vector2i = best - cr.cell
	var opts: Array[Vector2i] = []
	if gap.x != 0:
		opts.append(Vector2i(signi(gap.x), 0))
	if gap.y != 0:
		opts.append(Vector2i(0, signi(gap.y)))
	var danger: Dictionary = arena._danger_cells()
	for d: Vector2i in opts:
		if arena._critter_can_enter(cr, cr.cell + d) and not danger.has(cr.cell + d):
			return d
	return Vector2i.ZERO


func _update_critters(delta: float) -> void:
	for cr: Variant in _speed.keys():
		if not arena.critters.has(cr):
			_speed.erase(cr)
			_hog.erase(cr)
			_held.erase(cr)
	for cr: Arena.Critter in arena.critters:
		if not _speed.has(cr) or absf(cr.speed - float(_speed[cr][1])) > 0.0001:
			_speed[cr] = [cr.speed, cr.speed]
		var mult: float = 1.0
		if cr.kind == &"hedgehog" and season == 1:
			mult = 1.3
		if cr.kind == &"boss":
			mult = [1.0, 1.2, 0.95, 0.85][season]
		if _covered(cr.cell) or (cr.t < 1.0 and _covered(cr.target)):
			mult *= 0.5
		var s: float = float(_speed[cr][0]) * mult
		cr.speed = s
		_speed[cr][1] = s
		if cr.kind == &"hedgehog":
			# Curl up for winter on the nearest tile and stay put until
			# fully uncurled in spring.
			var curl: float = float(_hog.get(cr, 0.0))
			curl = move_toward(curl, 1.0 if _sleeping(cr) else 0.0, delta / 0.6)
			_hog[cr] = curl
			if _sleeping(cr) or curl > 0.0:
				var c := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
				if c != cr.cell and c != cr.target:
					c = cr.cell
				cr.cell = c
				cr.target = c
				cr.t = 0.0
				cr.pos = Vector2(c)
				_held[cr] = true
			elif _held.has(cr):
				_held.erase(cr)
				cr.t = 1.0


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"hedgehog":
			var curl: float = float(_hog.get(cr, 0.0))
			var ball: Node3D = body.get_node("Ball")
			var moving: bool = cr.t < 1.0 and cr.target != cr.cell
			var waddle: float = sin(t * 16.0) if moving else 0.0
			ball.position.y = 0.27 + absf(waddle) * 0.03 * (1.0 - curl) - curl * 0.04
			ball.rotation.z = waddle * 0.12 * (1.0 - curl)
			ball.rotation.x = curl * 0.9
			(ball.get_node("Face") as Node3D).visible = curl < 0.5
			(ball.get_node("Snow") as Node3D).visible = curl > 0.5
			(ball.get_node("Leaf") as Node3D).visible = season == 2 and curl < 0.5
			(body.get_node("Feet") as Node3D).visible = curl < 0.7
			var z: Label3D = cr.node.get_node("Zzz")
			z.visible = curl > 0.9
			if z.visible:
				z.position.y = 0.75 + fmod(t * 0.4, 0.3)
				z.modulate.a = 1.0 - fmod(t * 0.4, 0.3) / 0.3 * 0.6
			if curl > 0.5:
				var breathe: float = sin(t * 2.0) * 0.03
				return Vector3(1.05 + breathe, 0.85 - breathe, 1.05) * M.HOG_SIZE
			var squash: float = sin(t * 8.0) * 0.04 if moving else 0.0
			return Vector3(1.0 + squash, 1.0 - squash, 1.0) * M.HOG_SIZE
		&"boss":
			var moving: bool = cr.t < 1.0
			var step: float = sin(t * 9.0) if moving else 0.0
			for k in 4:
				var leg: Node3D = body.get_node("Leg%d" % k)
				leg.rotation.x = step * 0.45 * (1.0 if k == 0 or k == 3 else -1.0)
			var neck: Node3D = body.get_node("Neck")
			neck.rotation.x = sin(t * 1.4) * 0.08 + _stomp * 0.5
			var torso: Node3D = body.get_node("Torso")
			torso.position.y = 0.48 + absf(step) * 0.03
			(torso.get_node("Tail") as Node3D).rotation.x = sin(t * 6.0) * 0.4
			return Vector3.ONE * M.BOSS_SIZE * (1.0 + _stomp * 0.08)
	return Vector3.ONE


var _stomp: float = 0.0


## The Season Stag stamps in the next season each time it is hit.
func _update_boss() -> void:
	_stomp = maxf(_stomp - 0.04, 0.0)
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		return
	if _boss_hp >= 0 and b.hp < _boss_hp:
		_stomp = 1.0
		arena._spawn_ring(Vector3(b.pos.x, 0.06, b.pos.y), M.SEASON_COLORS[(season + 1) % 4], 2.2)
		arena._shake = maxf(arena._shake, 0.35)
		_advance()
	_boss_hp = b.hp


# --- Summer pods ------------------------------------------------------------------

func _update_pods() -> void:
	for p: Variant in _boost.keys():
		if not arena.pods.has(p):
			_boost.erase(p)
	for p: Arena.Pod in arena.pods:
		var boosted: bool = _boost.has(p)
		if season == 1 and not boosted:
			p.fire += 1
			_boost[p] = true
		elif season != 1 and boosted:
			p.fire = maxi(p.fire - 1, 1)
			_boost.erase(p)


# --- Drift ---------------------------------------------------------------------------

func _update_drift(delta: float) -> void:
	if _drift == null:
		return
	for i in _drift_seeds.size():
		var s: Vector4 = _drift_seeds[i]
		var tt: float = _clock * s.w + s.z
		var y: float
		var x: float = s.x + sin(tt * 0.9) * 0.6
		var z: float = s.y + cos(tt * 0.7) * 0.4
		var b := Basis()
		match season:
			1:
				# Summer pollen floats up and twinkles.
				y = fmod(tt * 0.25, 2.5) + 0.3
				b = Basis().scaled(Vector3.ONE * (0.5 + 0.3 * sin(tt * 4.0)))
			3:
				y = 4.0 - fmod(tt * 0.6, 4.2)
				b = Basis(Vector3(0.3, 1, 0.2).normalized(), tt).scaled(Vector3(0.8, 3.0, 0.8))
			_:
				y = 4.0 - fmod(tt * 0.45, 4.2)
				b = Basis(Vector3(1, 0.4, 0.3).normalized(), tt * 2.0)
		if i >= 22 and season == 1:
			y = -5.0
		_drift.set_instance_transform(i, Transform3D(b, Vector3(x, y, z)))


# --- The season chip -------------------------------------------------------------

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
	var warn: bool = _left <= WARN
	var nxt: int = (season + 1) % 4
	var w: float = 380.0
	var h: float = 66.0
	var rect := Rect2(Vector2(vp.x * 0.5 - w * 0.5, vp.y - h - 28.0), Vector2(w, h))
	var sb := StyleBoxFlat.new()
	var flash: bool = warn and fmod(_left, 0.5) > 0.25
	sb.bg_color = Color(Color("#FFFFFF") if flash else Ui.CREAM, 0.94)
	sb.set_corner_radius_all(int(h * 0.5))
	sb.anti_aliasing = true
	sb.shadow_color = Ui.SHADOW
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	_ui.draw_style_box(Ui.glassify(sb), rect)
	var col: Color = M.SEASON_COLORS[season]
	var ic: Vector2 = rect.position + Vector2(h * 0.5 + 2.0, h * 0.5)
	var pop: float = 1.0 + (1.0 - _blend) * 0.25
	_ui.draw_circle(ic, 24.0 * pop, Color(col, 0.22))
	_icon(ic, 17.0 * pop, season, 1.0)
	var f: Font = Ui.font(900)
	var tx: float = rect.position.x + h + 8.0
	var label: String
	var lc: Color
	if warn:
		label = "%s IN %d" % [NAMES[nxt], ceili(maxf(_left, 0.01))]
		lc = M.SEASON_COLORS[nxt].darkened(0.3)
	else:
		label = NAMES[season]
		lc = col.darkened(0.35)
	_ui.draw_string(f, Vector2(tx, rect.position.y + 30.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, lc)
	var sub: String = PERKS[nxt] if warn else PERKS[season]
	_ui.draw_string(Ui.font(800), Vector2(tx, rect.position.y + 52.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(Ui.INK, 0.55))
	var bx: float = tx + 150.0
	var bar := Rect2(Vector2(bx, rect.position.y + h * 0.5 - 5.0), Vector2(rect.end.x - bx - h - 2.0, 10.0))
	_ui.draw_rect(bar, Color(Ui.INK, 0.12))
	var u: float = clampf(_left / _length, 0.0, 1.0)
	_ui.draw_rect(Rect2(bar.position, Vector2(bar.size.x * u, bar.size.y)), col)
	var nc := Vector2(rect.end.x - h * 0.5 - 2.0, rect.position.y + h * 0.5)
	var nk: float = 1.0 + (0.18 * absf(sin(_clock * 8.0)) if warn else 0.0)
	_ui.draw_circle(nc, 19.0 * nk, Color(M.SEASON_COLORS[nxt], 0.18 if not warn else 0.35))
	_icon(nc, 12.0 * nk, nxt, 1.0 if warn else 0.6)


func _icon(c: Vector2, r: float, s: int, a: float) -> void:
	var col := Color(M.SEASON_COLORS[s], a)
	match s:
		0:
			for k in 5:
				var ang: float = TAU * k / 5.0 - PI * 0.5
				_ui.draw_circle(c + Vector2(cos(ang), sin(ang)) * r * 0.55, r * 0.42, col)
			_ui.draw_circle(c, r * 0.3, Color(Color("#FFD166"), a))
		1:
			for k in 8:
				var ang: float = TAU * k / 8.0
				_ui.draw_line(c + Vector2(cos(ang), sin(ang)) * r * 0.6, c + Vector2(cos(ang), sin(ang)) * r * 1.0, Color(Color("#FFB627"), a), r * 0.18, true)
			_ui.draw_circle(c, r * 0.52, col)
		2:
			var pts := PackedVector2Array()
			for k in 14:
				var ang: float = TAU * k / 14.0
				var w: float = 0.55 * (1.0 - 0.35 * absf(sin(ang)))
				pts.append(c + Vector2(cos(ang) * w * r, sin(ang) * r).rotated(0.6))
			_ui.draw_colored_polygon(pts, col)
			_ui.draw_line(c + Vector2(0, r * 0.9).rotated(0.6), c + Vector2(0, -r * 0.7).rotated(0.6), Color(Color("#9C4A1E"), a), r * 0.1, true)
		3:
			for k in 3:
				var d := Vector2(0, r).rotated(PI * k / 3.0)
				_ui.draw_line(c - d, c + d, col, r * 0.2, true)
			_ui.draw_circle(c, r * 0.22, Color(Color("#FFFFFF"), a))


# --- Sound ---------------------------------------------------------------------------

func _sound(p: AudioStreamPlayer, s: AudioStreamWAV, pitch: float) -> void:
	if p == null or s == null or not Save.sound_on or arena.demo:
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


## A rising three-note chime of plucked strings: the season turns.
func _make_chime() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for note: Array in [[0.0, 587.3], [0.09, 740.0], [0.18, 880.0], [0.27, 1174.7]]:
			var tt: float = t - float(note[0])
			if tt < 0.0:
				continue
			var fr: float = note[1]
			for k in 3:
				v += sin(TAU * fr * (k + 1) * tt) * exp(-tt * (4.0 + 3.0 * k)) / (k + 1)
		out[i] = v * 0.16 * minf(t / 0.003, 1.0)
	return _wav(out)


## A glassy crackle: ponds freeze.
func _make_freeze() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.6)
	var out := PackedFloat32Array()
	out.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 23
	var tick: float = 0.0
	for i in n:
		var t: float = i / rate
		if r.randf() < 0.004:
			tick = 1.0
		tick *= 0.985
		var v: float = sin(TAU * (2400.0 + 600.0 * sin(t * 30.0)) * t) * tick * 0.5
		v += sin(TAU * 1760.0 * t) * exp(-t * 6.0) * 0.15
		out[i] = v * minf((0.6 - t) / 0.1, 1.0) * 0.6
	return _wav(out)


## A soft "plip-splash": ice thaws into water.
func _make_splash() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.35)
	var out := PackedFloat32Array()
	out.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 5
	var lp: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 500.0 + 900.0 * minf(t / 0.06, 1.0)
		var v: float = sin(TAU * f * t) * exp(-t * 22.0) * 0.5
		lp = lp * 0.8 + r.randf_range(-1.0, 1.0) * 0.2
		v += lp * exp(-t * 10.0) * 0.6
		out[i] = v * 0.6
	return _wav(out)


## Leafy rustle: bushes sprout, leaves fall.
func _make_rustle() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 9
	var prev: float = 0.0
	for i in n:
		var t: float = i / rate
		var x: float = r.randf_range(-1.0, 1.0)
		var hp: float = x - prev
		prev = x
		var env: float = minf(t / 0.03, 1.0) * exp(-t * 7.0) * (0.7 + 0.3 * sin(TAU * 18.0 * t))
		out[i] = hp * env * 0.3
	return _wav(out)


## A wooden double-knock: two seconds to the next season.
func _make_tick() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.3)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var v: float = sin(TAU * 900.0 * t) * exp(-t * 50.0)
		var t2: float = t - 0.12
		if t2 > 0.0:
			v += sin(TAU * 1200.0 * t2) * exp(-t2 * 50.0)
		out[i] = v * 0.4
	return _wav(out)

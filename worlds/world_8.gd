extends WorldKit
## World 8, Gale Heights: breezy cliff-top meadows with windmills, kites and
## flags. The wind always blows one way (the flags, weathervanes and drifting
## petals show which). Every few seconds a gust comes: streaks and glowing
## arrows warn two seconds ahead, then the gust pushes Pip, fizz pods and
## Kites one tile downwind if the way is clear. A gust never pushes Pip into
## a flame, a blast line or a critter, and never blows a pod's blast onto
## him. Blasting a windmill (W) turns the wind to blow the way the blast was
## travelling. Kites (k) drift with the wind. Big Bluster, the storm-cloud
## boss, keeps turning the wind to blow at Pip.
##
## Extra map characters:
##   W  windmill (solid; a blast turns the wind)     k  Kite
## Level keys: "wind" ("left", "right", "up", "down") and "gust" (seconds
## between gusts).

const Art = preload("res://worlds/world_8_art.gd")

const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const WIND_NAMES: Dictionary = {"right": Vector2i(1, 0), "left": Vector2i(-1, 0), "up": Vector2i(0, -1), "down": Vector2i(0, 1)}
## Seconds of warning before each gust.
const WARN_TIME: float = 2.0
## How long a gust takes to carry Pip one tile.
const PUSH_TIME: float = 0.24
const KITE_SPEED: float = 1.75
const KITE_GUST_SPEED: float = 4.5
const POD_GUST_SPEED: float = 5.0
const STREAKS: int = 44
const BOSS_BLOW: float = 9.0
const BOSS_BLOW_ANGRY: float = 6.5

const PALETTE: Dictionary = {
	"GRASS_A": "#CBEAA2", "GRASS_B": "#B6DE8C", "RIM": "#9DD27C", "EDGE": "#EDE5D4",
	"STONE": "#F3EEE3", "DARK_STONE": "#D8CFBE", "DIRT": "#EFE7D8", "ROCK": "#D6CCBA",
	"WOOD": "#7FAEF0", "WOOD_DARK": "#FFF4D6", "BARREL": "#FF6F6F", "ACCENT": "#FF8A5C",
	"BLOSSOM_A": "#7CC66A", "BLOSSOM_B": "#5DB06A", "TRUNK": "#9A6B4A", "LEAFY_A": "#A6DA82", "LEAFY_B": "#8CCB70",
	"SKY_TOP": "#5FB0F2", "SKY_HORIZON": "#EAF6FF", "SKY_GROUND": "#D9ECF8", "CLOUD": "#FFFFFF", "CLOUDS": 0.85,
	"AMBIENT": "#BFD8F2", "AMBIENT_ENERGY": 0.55, "SUN": "#FFF6E6", "SUN_ENERGY": 1.5,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Breezy Bluff",
		"tip": "Watch the flags! Every few seconds\na gust pushes Pip and pods\none tile downwind.",
		"crates": 0.42, "par": 70, "wind": "right", "gust": 7.0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..b........#",
			"#.#.#.#.#.#.#",
			"#.....____b.#",
			"#.#.#.#.#.#.#",
			"#......b....#",
			"#.#.#.#.#.#.#",
			"#..____.....#",
			"#.#.#.#.#.#.#",
			"#.........b.#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Windmill Way",
		"tip": "Blast a windmill and the wind\nturns to blow the way\nyour blast was going!",
		"crates": 0.4, "par": 80, "wind": "left", "gust": 6.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.......b.#",
			"#.#.W.#.W.#.#",
			"#...._._....#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#...._._....#",
			"#.#.W.#.W.#.#",
			"#..b........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Kite Meadow",
		"tip": "Kites drift with the wind.\nTurn the wind to steer them\ninto your blasts!",
		"crates": 0.4, "par": 85, "wind": "down", "gust": 6.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.k.......k.#",
			"#.#.#.#.#.#.#",
			"#....___....#",
			"#.#.#.W.#.#.#",
			"#..b.....b..#",
			"#.#.#.#.#.#.#",
			"#.....k.....#",
			"#.#.#.#.#.#.#",
			"#...W._.W...#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Gusty Gorge",
		"tip": "Fizz barrels blow up big.\nLet the gust carry a pod\nright up to them!",
		"crates": 0.38, "par": 95, "wind": "up", "gust": 6.0,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#.#.#.#.#.#",
			"#.k...z...k.#",
			"#.#W#.#.#W#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b..._..k..#",
			"#.#.#.#.#.#.#",
			"#...B...B...#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Whirl Ridge",
		"tip": "Swirl pads warp you across.\nWisps float through crates,\nand gusts come quicker here!",
		"crates": 0.42, "par": 100, "wind": "right", "gust": 5.5,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1....E....2#",
			"#.#.#.#.#.#.#",
			"#.k...z...k.#",
			"#.#.#W#W#.#.#",
			"#...........#",
			"#W#.#.#.#.#W#",
			"#2...w.....1#",
			"#.#.#.#.#.#.#",
			"#.....k.....#",
			"#.#.#.#.#.#.#",
			"#.b.........#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Bluster's Crown",
		"tip": "Big Bluster blows the wind at you!\nBrace behind blocks and\nhit him with seven blasts.",
		"crates": 0.25, "par": 125, "boss": true, "wind": "down", "gust": 6.0,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...W...W...#",
			"#...........#",
			"#.#...K...#.#",
			"#...........#",
			"#.....#.....#",
			"#...........#",
			"#.#.......#.#",
			"#...W...W...#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

var wind := Vector2i(1, 0)
## Windmill tiles: Vector2i -> Node3D.
var windmills: Dictionary = {}
var _gust_every: float = 7.0
var _gust_t: float = 0.0
var _warned: bool = false
var _gust_flash: float = 0.0
var _clock: float = 0.0

# Pip being carried by a gust.
var _push_t: float = 99.0
var _push_from := Vector2.ZERO
var _push_to := Vector2.ZERO

# Kites waiting to be blown one tile.
var _kite_push: Dictionary = {}

# Blasts on windmills.
var _fresh: Dictionary = {}
var _fresh_frame: int = -1
var _mill_cool: Dictionary = {}
var _mill_spin: Dictionary = {}

# Decoration that moves.
var _flags: Array[Node3D] = []
var _vanes: Array[Node3D] = []
var _spinners: Array[Node3D] = []
var _swayers: Array[Node3D] = []
var _flyers: Array[Node3D] = []
var _flag_yaw: float = 0.0
var _streak_mm: MultiMesh
var _streaks: Array[Vector4] = []   # along, across, height, length
var _chev_mm: MultiMesh
var _chev_spots: Array[Vector3] = []
var _petals: GPUParticles3D
var _intensity: float = 0.25

# The boss.
var _blow_t: float = 0.0
var _inhale: float = 0.0

# Sounds.
var _player: AudioStreamPlayer
var _player2: AudioStreamPlayer
var _snd_warn: AudioStreamWAV
var _snd_gust: AudioStreamWAV
var _snd_turn: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Gale Heights"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_8.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "BIG BLUSTER"


func boss_hp() -> int:
	return 7


func boss_minion_kind() -> StringName:
	return &"kite"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "W":
		windmills[c] = null
		return true
	return false


func critter_chars() -> Dictionary:
	return {"k": &"kite"}


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Grassy turf on the chalk wall tops, a few tufts, and pennant flags on
	# poles along the far and side walls.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 41
	var turf: Array[Transform3D] = []
	var tufts_a: Array[Transform3D] = []
	var tufts_b: Array[Transform3D] = []
	var w: int = Arena.W
	for tf in blocks:
		var o: Vector3 = tf.origin
		var x: int = roundi(o.x)
		var z: int = roundi(o.z)
		turf.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.04, 0.04)), Vector3(o.x, 0.715, o.z)))
		if r.randf() < 0.45:
			for k in r.randi_range(1, 2):
				var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.2, 0.2))
				var at := Vector3(o.x + r.randf_range(-0.28, 0.28), 0.8, o.z + r.randf_range(-0.28, 0.28))
				(tufts_a if r.randf() < 0.5 else tufts_b).append(Transform3D(b, at))
		var flag: bool = false
		if z == 0 and x in [2, 6, 10]:
			flag = true
		elif (x == 0 or x == w - 1) and z in [3, 7, 11]:
			flag = true
		if flag:
			var pole: Node3D = Art.flag_pole(Art.FLAG_COLORS[_flags.size() % Art.FLAG_COLORS.size()], 0.85)
			pole.position = Vector3(o.x, 0.74, o.z)
			arena.add_child(pole)
			_flags.append(pole.get_node("Flag"))
	arena._multimesh(Models.box_mesh(Vector3(0.8, 0.07, 0.8), 0.03), Art.TUFT_B.darkened(0.05), turf)
	var tuft := Models.box_mesh(Vector3(0.06, 0.18, 0.05), 0.015)
	arena._multimesh(tuft, Art.TUFT_A.darkened(0.08), tufts_a)
	arena._multimesh(tuft, Art.TUFT_B, tufts_b)
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Chalky white boulders with a turf cap and a grass tuft or two.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var rocks: Array[Transform3D] = []
	var turf: Array[Transform3D] = []
	var tufts: Array[Transform3D] = []
	var blooms: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var yaw: float = r.randf_range(-0.2, 0.2)
		rocks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(1.0, r.randf_range(0.95, 1.05), 1.0)), p + Vector3(0, 0.33, 0)))
		turf.append(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.3, 0.3)), p + Vector3(r.randf_range(-0.05, 0.05), 0.68, r.randf_range(-0.05, 0.05))))
		for k in r.randi_range(1, 3):
			var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.25, 0.25))
			tufts.append(Transform3D(b, p + Vector3(r.randf_range(-0.22, 0.22), 0.78, r.randf_range(-0.22, 0.22))))
		if r.randf() < 0.35:
			blooms.append(Transform3D(Basis(), p + Vector3(r.randf_range(-0.2, 0.2), 0.78, r.randf_range(-0.2, 0.2))))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.66, 0.84), 0.14), Art.CHALK, rocks)
	arena._multimesh(Models.box_mesh(Vector3(0.66, 0.08, 0.62), 0.035), Art.TUFT_A, turf)
	arena._multimesh(Models.box_mesh(Vector3(0.06, 0.18, 0.05), 0.015), Art.TUFT_B, tufts)
	arena._multimesh(Models.sphere(0.05, -1, 8), Color("#FFE27A"), blooms)
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var holder := Node3D.new()
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.3:
			node = Art.grass(r)
			_swayers.append(node.get_node("Blades"))
		elif roll < 0.48:
			node = Models.flowers(r)
		elif roll < 0.55:
			node = Art.haybale(r, 0.8)
	else:
		if roll < 0.08:
			node = Art.rim_windmill(r, r.randf_range(0.9, 1.15))
			_spinners.append(node.get_node("Front/Sails"))
		elif roll < 0.17:
			node = Art.haybale(r)
		elif roll < 0.28:
			node = Art.fence(r)
		elif roll < 0.46:
			node = Art.grass(r)
			_swayers.append(node.get_node("Blades"))
		elif roll < 0.6:
			node = Models.flowers(r)
		elif roll < 0.63:
			node = Art.flying_kite(r, r.randf_range(2.2, 3.0))
			_flyers.append(node.get_node("Kite"))
	if node != null:
		node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var mill: Node3D = Art.rim_windmill(r, 1.7)
	root.add_child(mill)
	_spinners.append(mill.get_node("Front/Sails"))
	var hb: Node3D = Art.haybale(r, 1.2)
	hb.position = Vector3(size * 0.28, 0, size * 0.2)
	root.add_child(hb)
	if r.randf() < 0.6:
		var k: Node3D = Art.flying_kite(r, 2.8)
		k.position = Vector3(-size * 0.3, 0, size * 0.15)
		root.add_child(k)
		_flyers.append(k.get_node("Kite"))
	return root


func build_extra() -> void:
	wind = WIND_NAMES.get(String(arena.data.get("wind", "right")), Vector2i(1, 0))
	_gust_every = float(arena.data.get("gust", 7.0))
	_flag_yaw = _yaw(wind)
	for c: Vector2i in windmills.keys():
		var m: Node3D = Art.windmill()
		m.position = Vector3(c.x, 0, c.y)
		arena.add_child(m)
		windmills[c] = m
		_vanes.append(m.get_node("Vane"))
		_mill_spin[c] = 0.0
	for f: Node3D in _flags:
		f.rotation.y = _flag_yaw
	for v: Node3D in _vanes:
		v.rotation.y = _flag_yaw
	_build_streaks()
	_build_chevrons()
	_build_petals()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	arena.add_child(_player)
	_player2 = AudioStreamPlayer.new()
	_player2.volume_db = -5.0
	arena.add_child(_player2)
	_snd_warn = _make_warn()
	_snd_gust = _make_gust()
	_snd_turn = _make_turn()


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF8EC")
	env.adjustment_saturation = 1.1


func _yaw(d: Vector2i) -> float:
	return atan2(-float(d.y), float(d.x))


func _build_streaks() -> void:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.9, 1.95, 2.1, 0.8)
	_streak_mm = MultiMesh.new()
	_streak_mm.transform_format = MultiMesh.TRANSFORM_3D
	_streak_mm.mesh = Models.box_mesh(Vector3(1.0, 0.07, 0.15), 0.03)
	_streak_mm.instance_count = STREAKS
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _streak_mm
	mmi.material_override = m
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	var r := RandomNumberGenerator.new()
	r.seed = 808
	for i in STREAKS:
		_streaks.append(Vector4(r.randf_range(-2.0, 16.0), r.randf_range(0.6, 13.4), r.randf_range(0.7, 1.5), r.randf_range(0.7, 1.6)))


func _build_chevrons() -> void:
	_chev_mm = MultiMesh.new()
	_chev_mm.transform_format = MultiMesh.TRANSFORM_3D
	_chev_mm.mesh = Models.chevron_mesh()
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _chev_mm
	mmi.material_override = Models.mat(Color("#FFFFFF"), 1.3)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena.add_child(mmi)
	_place_chevrons()


## Glowing arrows on top of the upwind and downwind walls.
func _place_chevrons() -> void:
	_chev_spots.clear()
	var w: int = Arena.W
	var h: int = Arena.H
	if wind.x != 0:
		for z in range(1, h - 1):
			_chev_spots.append(Vector3(0, 0.8, z))
			_chev_spots.append(Vector3(w - 1, 0.8, z))
	else:
		for x in range(1, w - 1):
			_chev_spots.append(Vector3(x, 0.8, 0))
			_chev_spots.append(Vector3(x, 0.8, h - 1))
	_chev_mm.instance_count = _chev_spots.size()


func _build_petals() -> void:
	_petals = GPUParticles3D.new()
	_petals.amount = 36
	_petals.lifetime = 5.0
	_petals.preprocess = 5.0
	_petals.position = Vector3((Arena.W - 1) * 0.5, 1.6, (Arena.H - 1) * 0.5)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(9.0, 1.2, 10.0)
	pm.spread = 14.0
	pm.initial_velocity_min = 1.6
	pm.initial_velocity_max = 2.6
	pm.gravity = Vector3(0, -0.15, 0)
	pm.angular_velocity_min = -200.0
	pm.angular_velocity_max = 200.0
	pm.scale_min = 0.7
	pm.scale_max = 1.2
	_petals.process_material = pm
	_petals.draw_pass_1 = Models.box_mesh(Vector3(0.09, 0.02, 0.06), 0.008)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color("#FFE3EC")
	_petals.material_override = m
	_petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_petals.visibility_aabb = AABB(Vector3(-16, -8, -16), Vector3(32, 16, 32))
	arena.add_child(_petals)
	_aim_petals()


func _aim_petals() -> void:
	var pm: ParticleProcessMaterial = _petals.process_material
	pm.direction = Vector3(wind.x, 0.05, wind.y)


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return windmills.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if windmills.has(c) else 0


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not windmills.has(c)


func on_flame(c: Vector2i) -> void:
	var frame: int = Engine.get_process_frames()
	if frame != _fresh_frame:
		_fresh.clear()
		_fresh_frame = frame
	_fresh[c] = true
	if not windmills.has(c):
		return
	if _clock - float(_mill_cool.get(c, -9.0)) < 0.5:
		return
	_mill_cool[c] = _clock
	# The blast reached the windmill from the tile that caught fire just
	# before it: the wind now blows the way the blast travelled.
	for d: Vector2i in DIRS4:
		if _fresh.has(c - d):
			_mill_hit(c, d)
			return
	_mill_hit(c, Vector2i(-wind.y, wind.x))


func _mill_hit(c: Vector2i, d: Vector2i) -> void:
	_mill_spin[c] = 1.0
	var m: Node3D = windmills[c]
	if m != null:
		m.scale = Vector3(1.12, 0.9, 1.12)
	arena._spawn_sparkles(Vector3(c.x, 1.0, c.y), Color("#FFFFFF"))
	_set_wind(d)


func _set_wind(d: Vector2i) -> void:
	if d == wind:
		return
	wind = d
	_place_chevrons()
	_aim_petals()
	_sound(_player2, _snd_turn, 1.0)
	# A change of wind always comes with a full warning before its gust.
	if _gust_t > _gust_every - WARN_TIME:
		_gust_t = _gust_every - WARN_TIME
		_warned = false
	_intensity = maxf(_intensity, 0.8)


func process(delta: float) -> void:
	_clock += delta
	_update_gust(delta)
	_update_push(delta)
	if arena.boss != null:
		_boss_blow(delta)
	_animate(delta)


func _update_gust(delta: float) -> void:
	if arena.state == &"won" or arena.state == &"lost":
		return
	_gust_t += delta
	var warn_at: float = _gust_every - WARN_TIME
	if _gust_t >= warn_at and not _warned:
		_warned = true
		_sound(_player, _snd_warn, 1.0)
	if _gust_t >= _gust_every:
		_gust_t = 0.0
		_warned = false
		_gust()
	var target: float = 0.22
	if _gust_t >= warn_at:
		target = 0.35 + 0.65 * (_gust_t - warn_at) / WARN_TIME
	_gust_flash = maxf(_gust_flash - delta, 0.0)
	if _gust_flash > 0.0:
		target = 1.0
	_intensity = lerpf(_intensity, target, minf(delta * 5.0, 1.0))


func _along(c: Vector2i) -> int:
	return c.x * wind.x + c.y * wind.y


func _gust() -> void:
	_gust_flash = 0.7
	_sound(_player2, _snd_gust, arena.rng.randf_range(0.95, 1.05))
	# Pods: the furthest downwind first so a short queue can shuffle along.
	var moved: Dictionary = {}
	var list: Array = arena.pods.duplicate()
	list.sort_custom(func(a: Arena.Pod, b: Arena.Pod) -> bool: return _along(a.cell) > _along(b.cell))
	for p: Arena.Pod in list:
		if p.slide != Vector2i.ZERO:
			continue
		var to: Vector2i = p.cell + wind
		if arena._pod_blocked(to) or _catches_pip(p, to):
			continue
		p.slide = wind
		p.slide_speed = POD_GUST_SPEED
		p.kicked = false
		moved[p] = to
		_dust(Vector3(p.pos.x, 0.12, p.pos.y), 3)
	# Pip.
	if not arena.demo and arena.state == &"play" and arena.hero_alive and _push_t >= PUSH_TIME:
		var to2: Vector2i = arena.hero_cell() + wind
		if _hero_push_ok(to2, moved):
			_push_from = arena.hero_pos
			_push_to = Vector2(to2)
			_push_t = 0.0
			(arena.hero.get_node("Body") as Node3D).scale = Vector3(1.2, 0.84, 1.2)
			_dust(Vector3(arena.hero_pos.x, 0.12, arena.hero_pos.y), 4)
	# Kites take the next step downwind.
	for cr: Arena.Critter in arena.critters:
		if cr.kind == &"kite":
			_kite_push[cr] = true


## The tiles a pod at [param c] would set on fire.
func _blast_cells(c: Vector2i, reach: int) -> Dictionary:
	var out: Dictionary = {c: true}
	for d: Vector2i in DIRS4:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			var t: int = arena.tile(cc)
			if t == Arena.WALL:
				break
			var own: int = flame_stop(cc)
			if own == 2:
				break
			out[cc] = true
			if own == 1 or t != Arena.FLOOR:
				break
	return out


## True when blowing the pod to [param to] would put Pip in its blast when
## he was not before: gusts never blow danger onto him.
func _catches_pip(p: Arena.Pod, to: Vector2i) -> bool:
	if arena.demo or not arena.hero_alive:
		return false
	var h: Vector2i = arena.hero_cell()
	return _blast_cells(to, p.fire).has(h) and not _blast_cells(p.cell, p.fire).has(h)


func _hero_push_ok(to: Vector2i, moved: Dictionary) -> bool:
	if arena._hero_blocked(to) or arena.flames.has(to):
		return false
	for p: Arena.Pod in arena.pods:
		var at: Vector2i = moved.get(p, p.cell)
		if at == to or _blast_cells(at, p.fire).has(to):
			return false
	for cr: Arena.Critter in arena.critters:
		var reach: float = 1.7 if cr.kind == &"boss" else 1.2
		if cr.pos.distance_to(Vector2(to)) < reach or cr.target == to:
			return false
	return true


func _update_push(delta: float) -> void:
	if _push_t >= PUSH_TIME:
		return
	if arena.state != &"play" or not arena.hero_alive:
		_push_t = PUSH_TIME
		return
	_push_t = minf(_push_t + delta, PUSH_TIME)
	var u: float = _push_t / PUSH_TIME
	u = 1.0 - (1.0 - u) * (1.0 - u)
	arena.hero_pos = _push_from.lerp(_push_to, u)
	arena.hero.position = Vector3(arena.hero_pos.x, 0.0, arena.hero_pos.y)
	(arena.hero.get_node("Body") as Node3D).rotation.z = -wind.x * 0.25 * (1.0 - u)


func _dust(at: Vector3, count: int) -> void:
	if arena._fx.size() > 230:
		return
	for k in count:
		var d := Models.part(arena, arena._smoke_mesh, Color("#FFFFFF"), at + Vector3(arena.rng.randf_range(-0.2, 0.2), 0, arena.rng.randf_range(-0.2, 0.2)))
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		d.scale = Vector3.ONE * 0.6
		arena._fx.append({"node": d, "t": 0.0, "life": 0.5, "kind": &"dust",
			"vel": Vector3(wind.x * 2.4 + arena.rng.randf_range(-0.5, 0.5), 0.6, wind.y * 2.4 + arena.rng.randf_range(-0.5, 0.5))})


func _animate(delta: float) -> void:
	# Flags and vanes swing round to the wind and flutter harder before a gust.
	var target: float = _yaw(wind)
	_flag_yaw = lerp_angle(_flag_yaw, target, minf(delta * 5.0, 1.0))
	var amp: float = 0.12 + _intensity * 0.35
	var fast: float = 6.0 + _intensity * 14.0
	for i in _flags.size():
		var f: Node3D = _flags[i]
		f.rotation.y = _flag_yaw + sin(_clock * fast + i * 1.3) * amp
		f.scale = Vector3(0.9 + _intensity * 0.25 + sin(_clock * fast * 1.3 + i) * 0.05, 1.0, 1.0)
	for v: Node3D in _vanes:
		v.rotation.y = lerp_angle(v.rotation.y, target, minf(delta * 6.0, 1.0)) + sin(_clock * 9.0) * 0.02 * _intensity
	for c: Vector2i in windmills:
		var m: Node3D = windmills[c]
		if m == null:
			continue
		_mill_spin[c] = maxf(float(_mill_spin[c]) - delta * 0.5, 0.0)
		var sails: Node3D = m.get_node("Front/Sails")
		sails.rotation.z -= delta * (1.2 + _intensity * 3.0 + float(_mill_spin[c]) * 16.0)
		m.scale = m.scale.lerp(Vector3.ONE, minf(delta * 8.0, 1.0))
	for s: Node3D in _spinners:
		s.rotation.z -= delta * (0.9 + _intensity * 2.0)
	for i in _swayers.size():
		var g: Node3D = _swayers[i]
		g.rotation.z = -wind.x * (0.08 + sin(_clock * 3.0 + i) * 0.06 * (1.0 + _intensity))
		g.rotation.x = wind.y * (0.08 + sin(_clock * 3.0 + i) * 0.06 * (1.0 + _intensity))
	for i in _flyers.size():
		var k: Node3D = _flyers[i]
		k.rotation.z = sin(_clock * 1.7 + i) * 0.25
		k.position.y += (sin(_clock * 1.3 + i * 2.0) * 0.004)
	_animate_streaks(delta)
	_animate_chevrons()


func _animate_streaks(delta: float) -> void:
	var along_x: bool = wind.x != 0
	var span: float = (Arena.W if along_x else Arena.H) + 3.0
	var s: float = float(wind.x + wind.y)
	var speed: float = 3.0 + _intensity * 7.0 + (9.0 if _gust_flash > 0.0 else 0.0)
	var shown: int = int(STREAKS * clampf(_intensity, 0.0, 1.0))
	var basis := Basis(Vector3.UP, _yaw(wind))
	for i in STREAKS:
		var st: Vector4 = _streaks[i]
		st.x += speed * delta * (0.8 + 0.4 * fmod(i * 0.37, 1.0))
		if st.x > span:
			st.x -= span + 2.0
			st.y = arena.rng.randf_range(0.6, (Arena.H if along_x else Arena.W) - 1.6)
		_streaks[i] = st
		var u: float = st.x - 2.0
		var fade: float = clampf(minf(u + 1.5, span - 2.0 - u) / 2.0, 0.0, 1.0)
		var on: float = 1.0 if i < shown else 0.0
		var len: float = st.w * (0.6 + _intensity * 0.8) * fade * on
		var pos: Vector3
		var along: float = u if s > 0.0 else span - 4.0 - u
		if along_x:
			pos = Vector3(along, st.z, st.y)
		else:
			pos = Vector3(st.y, st.z, along)
		_streak_mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3(maxf(len, 0.0001), maxf(on * fade, 0.0001), maxf(on * fade, 0.0001))), pos))


func _animate_chevrons() -> void:
	var warn_at: float = _gust_every - WARN_TIME
	var show: float = 0.5
	if _gust_t >= warn_at:
		show = 0.6 + 0.4 * absf(sin(_clock * 9.0))
	if _gust_flash > 0.0:
		show = 1.3 * (_gust_flash / 0.7)
	var basis := Basis(Vector3.UP, _yaw(wind)) * Basis(Vector3.RIGHT, -PI * 0.5)
	var slide: float = fmod(_clock * 1.6, 1.0) * 0.3 - 0.15
	for i in _chev_spots.size():
		var p: Vector3 = _chev_spots[i] + Vector3(wind.x, 0, wind.y) * slide
		var k: float = maxf(show, 0.0001) * 1.5
		_chev_mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3(k, k, k)), p))


# --- Boss ---------------------------------------------------------------------------

## Big Bluster takes a deep breath and turns the wind to blow at Pip, with
## the usual two-second warning before the gust.
func _boss_blow(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	_inhale = maxf(_inhale - delta * 0.7, 0.0)
	if arena.demo or arena.state != &"play" or not arena.hero_alive:
		return
	_blow_t += delta
	var every: float = BOSS_BLOW if b.hp * 2 > arena.boss_max_hp else BOSS_BLOW_ANGRY
	if _blow_t < every:
		return
	_blow_t = 0.0
	var diff: Vector2 = arena.hero_pos - b.pos
	var d := Vector2i(int(signf(diff.x)), 0) if absf(diff.x) >= absf(diff.y) else Vector2i(0, int(signf(diff.y)))
	if d == Vector2i.ZERO:
		d = Vector2i(0, 1)
	_set_wind(d)
	if _gust_t < _gust_every - WARN_TIME:
		_gust_t = _gust_every - WARN_TIME
		_warned = false
	_inhale = 1.4


# --- Critters ----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"kite":
			return Art.kite(arena.rng)
		&"boss":
			return Art.cloud_boss()
	return null


func critter_speed(kind: StringName) -> float:
	return KITE_SPEED if kind == &"kite" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"kite":
		return Vector2i.ZERO
	var hc: Vector2i = arena.hero_cell() if not arena.demo else Vector2i(-99, -99)
	if _kite_push.has(cr):
		_kite_push.erase(cr)
		var to: Vector2i = cr.cell + wind
		if arena._critter_can_enter(cr, to) and to != hc and to != hc + wind:
			cr.speed = KITE_GUST_SPEED
			return wind
	cr.speed = KITE_SPEED
	# Drift: mostly downwind or across it, seldom against it.
	var total: float = 0.0
	var opts: Array = []
	for d: Vector2i in DIRS4:
		if not arena._critter_can_enter(cr, cr.cell + d):
			continue
		var wt: float = 2.0
		if d == wind:
			wt = 3.2
		elif d == -wind:
			wt = 0.5
		if d == cr.dir:
			wt += 1.0
		if d == -cr.dir:
			wt *= 0.4
		opts.append([d, wt])
		total += wt
	if opts.is_empty():
		return Vector2i.ZERO
	var roll: float = arena.rng.randf() * total
	for o: Array in opts:
		roll -= float(o[1])
		if roll <= 0.0:
			return o[0]
	return opts[opts.size() - 1][0]


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind == &"kite":
		arena._spawn_sparkles(Vector3(cr.pos.x, 0.6, cr.pos.y), Art.KITE_COLORS[arena.rng.randi() % Art.KITE_COLORS.size()])
	elif cr.kind == &"boss" and cr.invuln <= 0.0:
		_dust(Vector3(cr.pos.x, 0.8, cr.pos.y), 6)
	return false


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	match cr.kind:
		&"kite":
			# The kite always faces the camera and leans with the wind.
			body.rotation.y = -cr.node.rotation.y
			body.position.y = sin(t * 2.6) * 0.07
			var rig: Node3D = body.get_node("Rig")
			rig.rotation.z = sin(t * 2.1) * 0.16 - wind.x * 0.22
			rig.rotation.x = -0.95 + wind.y * 0.15
			var bow: Node3D = rig.get_node("Tail/Bow0")
			var k: int = 0
			while bow != null:
				bow.rotation.z = sin(t * 7.0 - k * 0.9) * 0.35 + wind.x * 0.3
				bow.rotation.x = -wind.y * 0.3
				k += 1
				bow = bow.get_node_or_null("Bow%d" % k)
			return Vector3.ONE
		&"boss":
			body.rotation.y = -cr.node.rotation.y * 0.7
			body.position.y = sin(t * 2.0) * 0.08
			var rig2: Node3D = body.get_node("Rig")
			var puff: float = minf(_inhale, 1.0)
			var face: Node3D = rig2.get_node("Face")
			(face.get_node("Cheeks") as Node3D).scale = Vector3.ONE * (1.0 + puff * 0.9)
			(face.get_node("Mouth") as Node3D).scale = Vector3.ONE * (1.0 + (1.0 - puff) * 0.3 + (0.6 if _gust_flash > 0.0 else 0.0))
			rig2.rotation.z = sin(t * 1.4) * 0.05
			return Vector3(1.0 + puff * 0.08, 1.0 + puff * 0.1 + absf(sin(t * 3.0)) * 0.03, 1.0 + puff * 0.08)
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


## A soft rising whistle of wind: the gust is coming.
func _make_warn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	var lp: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 81
	for i in n:
		var t: float = i / rate
		var f: float = 520.0 + 380.0 * (t / 1.9) + sin(TAU * 5.5 * t) * 12.0
		phase += TAU * f / rate
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.08
		var env: float = minf(t / 0.9, 1.0) * minf((1.9 - t) / 0.25, 1.0)
		out[i] = (sin(phase) * 0.35 + lp * 1.3) * env * 0.35
	return _wav(out)


## The gust itself: a swelling whoosh of air.
func _make_gust() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.8)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp: float = 0.0
	var lp2: float = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 82
	for i in n:
		var t: float = i / rate
		var k: float = 0.05 + 0.25 * exp(-t * 4.0)
		lp += (rng.randf_range(-1.0, 1.0) - lp) * k
		lp2 += (lp - lp2) * k
		var env: float = minf(t / 0.08, 1.0) * exp(-t * 3.2)
		out[i] = lp2 * env * 2.6
	return _wav(out)


## A bright little "fwip" chime when the wind turns.
func _make_turn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 880.0 if t < 0.12 else 1318.5
		phase += TAU * f / rate
		var env: float = minf(t / 0.004, 1.0) * (exp(-t * 14.0) if t < 0.12 else exp(-(t - 0.12) * 8.0))
		out[i] = (sin(phase) * 0.8 + sin(phase * 2.0) * 0.15) * env * 0.45
	return _wav(out)

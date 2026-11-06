extends WorldKit
## World 4, Frost Peaks: snowy mountain tops. Pip slides across ice tiles
## (~) until he bumps into something or reaches snow, frozen crates (I) need
## two blasts (the first cracks them), Snowpuffs (s) roll in straight lines,
## speeding up and growing as they go, and charge when Pip lines up with
## them. Big Brrr the yeti rules the peak and kicks out Snowpuffs.

const Art = preload("res://worlds/world_4_art.gd")

## Pip's top sliding speed on ice (tiles per second) and how fast he gets
## there.
const SLIDE_MAX: float = 6.8
const SLIDE_ACCEL: float = 16.0
## A tap's first walking step this long ago may still turn into a double
## tap, so Pip does not start sliding until it has passed.
const TAP_GRACE: float = 0.32
const FROZEN_HP: int = 2
const SNOWPUFF_SPEED: float = 1.8
const DIRS4: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

const PALETTE: Dictionary = {
	"GRASS_A": "#F1F7FD", "GRASS_B": "#D9E6F5", "RIM": "#E6EFF9", "EDGE": "#6C8BD0",
	"STONE": "#C9DAF0", "DARK_STONE": "#9DB5DA", "DIRT": "#B4C9E8", "ROCK": "#8AA3D6",
	"WOOD": "#F2727F", "WOOD_DARK": "#FFD27A", "BARREL": "#E4572E", "BELT": "#5E6E9C", "ACCENT": "#FFD27A",
	"BLOSSOM_A": "#3E8C86", "BLOSSOM_B": "#2F7472", "TRUNK": "#8A6450", "LEAFY_A": "#EEF6FC", "LEAFY_B": "#D3E5F5",
	"SKY_TOP": "#86AEEA", "SKY_HORIZON": "#FBE9F2", "SKY_GROUND": "#E2ECF8", "CLOUD": "#FFFFFF", "CLOUDS": 0.55,
	"AMBIENT": "#BED2F2", "AMBIENT_ENERGY": 0.55, "SUN": "#FFF6EE", "SUN_ENERGY": 1.4,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "First Frost",
		"tip": "Ice is slippery! Pip slides until\nhe bumps into something or hits snow.",
		"crates": 0.45, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.........#",
			"#.#.#~#~#.#.#",
			"#...~~~~~...#",
			"#.#.#~#~#.#.#",
			"#...~~~~~.b.#",
			"#.#.#~#~#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#..b........#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Crackle Creek",
		"tip": "Frozen crates take two blasts:\none to crack, one to smash!",
		"crates": 0.4, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"ice_drops": {"shield": 1, "fire": 1},
		"map": [
			"#############",
			"#..I..E..I..#",
			"#.#.#I#I#.#.#",
			"#.....I.....#",
			"#.#.#.#.#.#.#",
			"#.~~~~z~~~~.#",
			"#.#.#.#.#.#.#",
			"#..I..b..I..#",
			"#I#.#.#.#.#I#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b.~~~~~.b.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Snowpuff Slopes",
		"tip": "Snowpuffs roll in straight lines\nand charge when you line up!",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"ice_drops": {"kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.s.........#",
			"#.#.##.##.#.#",
			"#...~~~~~...#",
			"#.#.#...#.#.#",
			"#.I...s...I.#",
			"#.#.#...#.#.#",
			"#...~~~~~.s.#",
			"#.#.##.##.#.#",
			"#...........#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Fizzy Floes",
		"tip": "A fizz barrel's big blast\ncracks frozen crates too!",
		"crates": 0.38, "par": 95,
		"drops": {"bomb": 2, "fire": 1, "speed": 1, "kick": 1},
		"ice_drops": {"shield": 1, "fire": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#I#.#.#I#.#",
			"#...~~~~~...#",
			"#.#.#~#~#.#.#",
			"#.s.~~B~~.b.#",
			"#.#.#~#~#.#.#",
			"#...~~~~~...#",
			"#.#I#.#.#I#.#",
			"#.B...z...B.#",
			"#.#.#.#.#.#.#",
			"#.b.......s.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Twinkle Pass",
		"tip": "Slide onto a swirl pad to warp.\nWisps float right through ice!",
		"crates": 0.42, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "kick": 1, "heart": 1},
		"ice_drops": {"speed": 1, "shield": 1},
		"map": [
			"#############",
			"#1....E....2#",
			"#.#.#I#I#.#.#",
			"#.~~~~.~~~~.#",
			"#.#.#.#.#.#.#",
			"#.s...w...z.#",
			"#I#.#.#.#.#I#",
			"#2~~~~.~~~~1#",
			"#I#.#.#.#.#I#",
			"#.b.......s.#",
			"#.#.#.#.#.#.#",
			"#.~~~.I.~~~.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Big Brrr's Peak",
		"tip": "Big Brrr kicks out Snowpuffs!\nHit him with six blasts.",
		"crates": 0.3, "par": 130, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1},
		"ice_drops": {"heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#.~~~...~~~.#",
			"#...#...#...#",
			"#.....K.....#",
			"#~#.......#~#",
			"#~...~~~...~#",
			"#~#.......#~#",
			"#...#...#...#",
			"#.~~~...~~~.#",
			"#..II...II..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Ice floor tiles (Vector2i -> true).
var ice: Dictionary = {}
## Frozen crates still standing: Vector2i -> blasts left.
var frozen: Dictionary = {}
var _frozen_slot: Dictionary = {}
var _frozen_hit: Dictionary = {}
var _frozen_drops: Dictionary = {}
var _mm_block: MultiMesh
var _mm_cracked: MultiMesh
var _mm_lid: MultiMesh
var _mm_core: MultiMesh
var _mm_cracks: MultiMesh
var _lid_tf: Array[Transform3D] = []
var _clock: float = 0.0

# Sliding.
var _slide := Vector2i.ZERO
var _slide_speed: float = 0.0
var _slide_fresh: bool = false
var _pending: bool = false
var _pending_dir := Vector2i.ZERO
var _pending_t0: float = 0.0
var _pending_pods: int = 0
var _last_pos := Vector2.ZERO
var _last_cell := Vector2i(-99, -99)
var _goal_prev := Arena.NO_CELL
var _goal_set_t: float = -10.0
var _goal_stops: Dictionary = {}
var _trail_t: float = 0.0

# Snowpuffs and the boss.
var _runs: Dictionary = {}
var _known: Dictionary = {}
var _summons: int = 0


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Frost Peaks"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_4.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "BIG BRRR"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"~":
			ice[c] = true
			return true
		"I":
			frozen[c] = FROZEN_HP
			return true
	return false


func critter_chars() -> Dictionary:
	return {"s": &"snowpuff"}


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Thick snow caps with drips over the front edge and icicles hanging
	# under them on every face the camera can see.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 41
	var caps: Array[Transform3D] = []
	var drips: Array[Transform3D] = []
	var icicles: Array[Transform3D] = []
	var mounds: Array[Transform3D] = []
	var w: int = Arena.W
	var h: int = Arena.H
	for tf in blocks:
		var o: Vector3 = tf.origin
		var x: int = roundi(o.x)
		var z: int = roundi(o.z)
		caps.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.05, 0.05)), Vector3(o.x + r.randf_range(-0.03, 0.03), 0.71, o.z + r.randf_range(-0.03, 0.03))))
		if r.randf() < 0.0:
			var mb := Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(r.randf_range(0.8, 1.2), r.randf_range(0.8, 1.3), r.randf_range(0.8, 1.2)))
			mounds.append(Transform3D(mb, Vector3(o.x + r.randf_range(-0.12, 0.12), 0.78, o.z + r.randf_range(-0.12, 0.12))))
		var faces: Array[Vector3] = []
		if z == 0 or z == h - 1:
			faces.append(Vector3(0, 0, 1))
		if x == 0 and z > 0 and z < h - 1:
			faces.append(Vector3(1, 0, 0))
		if x == w - 1 and z > 0 and z < h - 1:
			faces.append(Vector3(-1, 0, 0))
		for n: Vector3 in faces:
			var t := Vector3(n.z, 0, -n.x)
			var yaw: float = atan2(n.x, n.z)
			var spots: Array[float] = []
			for k in r.randi_range(1, 3):
				spots.append(r.randf_range(-0.36, 0.36))
			for off: float in spots:
				var dh: float = r.randf_range(0.07, 0.14)
				var db := Basis(Vector3.UP, yaw).scaled(Vector3(r.randf_range(0.8, 1.2), dh / 0.14, 1.0))
				drips.append(Transform3D(db, Vector3(o.x, 0.0, o.z) + n * 0.44 + t * off * 0.8 + Vector3(0, 0.72 - dh * 0.5, 0)))
				if r.randf() < 0.75:
					var ln: float = r.randf_range(0.18, 0.36)
					icicles.append(Transform3D(Basis().scaled(Vector3(1.0, ln, 1.0)), Vector3(o.x, 0.0, o.z) + n * 0.47 + t * (off + r.randf_range(-0.05, 0.05)) + Vector3(0, 0.56 - ln * 0.5, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.1, 0.84), 0.045), Art.SNOW, caps)
	arena._multimesh(Models.box_mesh(Vector3(0.17, 0.14, 0.06), 0.025), Art.SNOW, drips)
	arena._multimesh(Models.box_mesh(Vector3(0.34, 0.11, 0.28), 0.045), Art.SNOW_SHADE.lerp(Art.SNOW, 0.5), mounds)
	arena._multimesh(Models.cylinder(0.06, 0.0, 1.0, 6), Art.ICE, icicles, Art.ice_glass(Color("#8FD8F8"), 0.5, 0.3))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Snowy blue boulders with ice crystals poking out of their snow caps.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var rocks: Array[Transform3D] = []
	var snow: Array[Transform3D] = []
	var prisms: Array[Transform3D] = []
	var tips: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var yaw: float = r.randf_range(-0.3, 0.3)
		var b := Basis(Vector3.UP, yaw).scaled(Vector3(r.randf_range(0.96, 1.04), r.randf_range(0.92, 1.05), r.randf_range(0.96, 1.04)))
		rocks.append(Transform3D(b, p + Vector3(0, 0.28, 0)))
		snow.append(Transform3D(Basis(Vector3.UP, yaw + r.randf_range(-0.4, 0.4)), p + Vector3(r.randf_range(-0.1, 0.1), 0.575, r.randf_range(-0.1, 0.1))))
		var n: int = 2 if r.randf() < 0.6 else 1
		for k in n:
			var big: bool = k == 0
			var s: float = r.randf_range(1.2, 1.4) if big else r.randf_range(0.7, 0.9)
			var lean: float = r.randf_range(0.05, 0.2) if big else r.randf_range(0.35, 0.55)
			var a: float = r.randf() * TAU
			var cb := (Basis(Vector3.UP, a) * Basis(Vector3.RIGHT, lean) * Basis(Vector3.UP, r.randf() * TAU)).scaled(Vector3.ONE * s)
			var base: Vector3 = p + Vector3(cos(a) * (0.05 if big else 0.22), 0.52, sin(a) * (0.05 if big else 0.22))
			prisms.append(Transform3D(cb, base + cb * Vector3(0, 0.19, 0)))
			tips.append(Transform3D(cb, base + cb * Vector3(0, 0.38 + 0.085, 0)))
	arena._multimesh(Models.box_mesh(Vector3(0.86, 0.56, 0.86), 0.16), Models.ROCK, rocks)
	arena._multimesh(Models.box_mesh(Vector3(0.56, 0.08, 0.5), 0.035), Art.SNOW, snow)
	arena._multimesh(Models.cylinder(0.11, 0.11, 0.38, 6), Art.ICE, prisms, Art.ice_glass(Color("#58B4EE"), 0.45, 0.1))
	arena._multimesh(Models.cylinder(0.0, 0.11, 0.17, 6), Art.ICE, tips, Art.ice_glass(Color("#8AD6F8"), 0.45, 0.2))
	return true


func rim_prop(_p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var holder := Node3D.new()
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.1:
			node = Art.present(r)
		elif roll < 0.22:
			node = Art.ice_spire(r, 0.45)
	else:
		if roll < 0.2:
			node = Art.pine(r, r.randf_range(0.95, 1.3))
		elif roll < 0.27:
			node = Art.snowman(r, r.randf_range(0.8, 1.0))
		elif roll < 0.34:
			node = Art.ice_spire(r, r.randf_range(0.8, 1.1))

	if node != null:
		node.position = Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	if r.randf() < 0.55:
		var t := Art.pine(r, 1.5)
		root.add_child(t)
		var s := Art.snowman(r, 0.9)
		s.position = Vector3(size * 0.25, 0, size * 0.2)
		root.add_child(s)
	else:
		var sp := Art.ice_spire(r, 1.5)
		root.add_child(sp)
		var t2 := Art.pine(r, 1.0)
		t2.position = Vector3(-size * 0.25, 0, size * 0.15)
		root.add_child(t2)
	return root


func build_extra() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 23
	_build_ice(r)
	_build_frozen(r)
	_build_snowfall()
	for cr: Arena.Critter in arena.critters:
		_known[cr] = true
	if arena.hero != null:
		_last_pos = arena.hero_pos
		_last_cell = arena.hero_cell()


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#F6F4FF")
	env.adjustment_saturation = 1.06


func _build_ice(r: RandomNumberGenerator) -> void:
	var slabs: Array[Transform3D] = []
	var streaks: Array[Transform3D] = []
	for c: Vector2i in ice:
		slabs.append(Transform3D(Basis(), Vector3(c.x, -0.02, c.y)))
		for k in r.randi_range(1, 2):
			var b := Basis(Vector3.UP, PI * 0.25 + r.randf_range(-0.12, 0.12)).scaled(Vector3(r.randf_range(0.45, 1.0), 1.0, 1.0))
			streaks.append(Transform3D(b, Vector3(c.x + r.randf_range(-0.18, 0.18), 0.02, c.y + r.randf_range(-0.18, 0.18))))
	if slabs.is_empty():
		return
	arena._multimesh(Models.box_mesh(Vector3(0.985, 0.07, 0.985), 0.03), Art.ICE, slabs, Art.ice_glass(Color("#A8E8FC"), 0.5, 0.05))
	arena._multimesh(Models.box_mesh(Vector3(0.42, 0.012, 0.05), 0.005), Color.WHITE, streaks, Models.mat(Color.WHITE, 0.6))


func _build_frozen(r: RandomNumberGenerator) -> void:
	var blocks: Array[Transform3D] = []
	var lids: Array[Transform3D] = []
	var cores: Array[Transform3D] = []
	var hidden: Array[Transform3D] = []
	var cells: Array[Vector2i] = []
	for c: Vector2i in frozen:
		_frozen_slot[c] = blocks.size()
		cells.append(c)
		blocks.append(Transform3D(Basis(), Vector3(c.x, 0.4, c.y)))
		lids.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.5, 0.5)), Vector3(c.x + r.randf_range(-0.1, 0.1), 0.81, c.y + r.randf_range(-0.1, 0.1))))
		var cb := Basis(Vector3.UP, PI * 0.25) * Basis(Vector3.RIGHT, 0.5)
		cores.append(Transform3D(cb, Vector3(c.x, 0.38, c.y)))
		hidden.append(_hidden_tf(c))
	if cells.is_empty():
		return
	_lid_tf = lids
	_mm_core = arena._multimesh(Models.box_mesh(Vector3(0.34, 0.34, 0.34), 0.07), Art.SNOW, cores, Models.mat(Art.SNOW, 0.35))
	_mm_block = arena._multimesh(Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), Art.ICE, blocks, Art.ice_glass(Color("#5EC0F0"), 0.32, 0.05))
	_mm_cracked = arena._multimesh(Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), Art.ICE, hidden, Art.ice_glass(Color("#A6E2FA"), 0.4, 0.1))
	_mm_lid = arena._multimesh(Models.box_mesh(Vector3(0.5, 0.09, 0.44), 0.04), Art.SNOW, lids)
	_mm_cracks = arena._multimesh(_crack_mesh(), Color.WHITE, hidden.duplicate(), Models.mat(Color.WHITE, 0.9))
	# Some frozen crates hold a power-up, as the level asks.
	var shuffled: Array[Vector2i] = cells.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j: int = r.randi_range(0, i)
		var tmp: Vector2i = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var k: int = 0
	var want: Dictionary = arena.data.get("ice_drops", {})
	for kind: String in want:
		for i in int(want[kind]):
			if k < shuffled.size():
				_frozen_drops[shuffled[k]] = StringName(kind)
				k += 1


func _hidden_tf(c: Vector2i) -> Transform3D:
	return Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(c.x, -5, c.y))


## Zig-zag crack lines over the three faces of a frozen crate the camera
## sees, as one mesh (origin at the crate's foot).
func _crack_mesh() -> ArrayMesh:
	var seg := Models.box_mesh(Vector3(1.0, 0.03, 0.02), 0.008)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front: Array = [
		[Vector2(-0.3, 0.74), Vector2(-0.12, 0.52), Vector2(0.0, 0.58), Vector2(0.13, 0.34), Vector2(0.04, 0.2), Vector2(0.2, 0.05)],
		[Vector2(0.0, 0.58), Vector2(0.3, 0.66)],
		[Vector2(-0.12, 0.52), Vector2(-0.3, 0.3)],
	]
	var side: Array = [
		[Vector2(-0.32, 0.12), Vector2(-0.1, 0.32), Vector2(0.04, 0.27), Vector2(0.28, 0.6)],
		[Vector2(0.04, 0.27), Vector2(0.18, 0.1)],
	]
	var faces: Array = [[0.0, front], [PI * 0.5, side], [-PI * 0.5, side]]
	for f: Array in faces:
		var turn := Basis(Vector3.UP, float(f[0]))
		for line: Array in f[1]:
			for i in line.size() - 1:
				var a: Vector2 = line[i]
				var b: Vector2 = line[i + 1]
				var mid: Vector2 = (a + b) * 0.5
				var d: Vector2 = b - a
				var lb := Basis(Vector3.FORWARD, -atan2(d.y, d.x)).scaled(Vector3(d.length() + 0.02, 1.0, 1.0))
				var local := Transform3D(lb, Vector3(mid.x, mid.y, 0.426))
				st.append_from(seg, 0, Transform3D(turn, Vector3.ZERO) * local)
	return st.commit()


func _build_snowfall() -> void:
	# A light, cheap snowfall over the whole arena.
	var p := GPUParticles3D.new()
	p.amount = 70
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.position = Vector3((Arena.W - 1) * 0.5, 8.0, (Arena.H - 1) * 0.5)
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(10.0, 0.5, 11.0)
	pm.direction = Vector3(0.2, -1.0, 0.1)
	pm.spread = 18.0
	pm.initial_velocity_min = 0.7
	pm.initial_velocity_max = 1.1
	pm.gravity = Vector3(0, -0.12, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.25
	p.process_material = pm
	p.draw_pass_1 = Models.box_mesh(Vector3(0.075, 0.075, 0.075), 0.02)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 1.0, 1.0)
	p.material_override = m
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.visibility_aabb = AABB(Vector3(-16, -12, -16), Vector3(32, 24, 32))
	arena.add_child(p)


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return frozen.has(c)


func flame_stop(c: Vector2i) -> int:
	return 1 if frozen.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if not frozen.has(c):
		return
	# One blast (or one chain of them) counts as one hit.
	if _clock - float(_frozen_hit.get(c, -9.0)) < 0.45:
		return
	_frozen_hit[c] = _clock
	frozen[c] = int(frozen[c]) - 1
	if int(frozen[c]) > 0:
		_crack(c)
	else:
		_shatter(c)


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	return not frozen.has(c) or cr.kind == &"wisp"


func _crack(c: Vector2i) -> void:
	var i: int = _frozen_slot[c]
	_mm_block.set_instance_transform(i, _hidden_tf(c))
	_mm_cracked.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x, 0.4, c.y)))
	_mm_cracks.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x, 0.0, c.y)))
	# The snow lid jolts askew.
	var lid: Transform3D = _lid_tf[i]
	_mm_lid.set_instance_transform(i, Transform3D(Basis(Vector3.FORWARD, 0.12) * lid.basis, lid.origin + Vector3(0.04, 0.02, 0)))
	_shards(c, 6, 0.35)
	Sfx.play(&"snap", 0.1)
	arena._shake = maxf(arena._shake, 0.12)


func _shatter(c: Vector2i) -> void:
	var i: int = _frozen_slot[c]
	for mm: MultiMesh in [_mm_block, _mm_cracked, _mm_cracks, _mm_lid, _mm_core]:
		mm.set_instance_transform(i, _hidden_tf(c))
	frozen.erase(c)
	_frozen_slot.erase(c)
	var at := Vector3(c.x, 0.4, c.y)
	var flash := Models.part(arena, Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), Color("#E8F8FF"), at, 2.0)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arena._fx.append({"node": flash, "t": 0.0, "life": 0.12, "kind": &"flash"})
	_shards(c, 12, 1.0)
	for k in 5:
		var a: float = TAU * k / 5.0 + arena.rng.randf() * 0.5
		var d := Models.part(arena, arena._smoke_mesh, Art.SNOW, Vector3(c.x + cos(a) * 0.25, 0.15, c.y + sin(a) * 0.25))
		d.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arena._fx.append({"node": d, "t": 0.0, "life": 0.55, "kind": &"dust", "vel": Vector3(cos(a) * 1.8, 0.5, sin(a) * 1.8)})
	Sfx.play(&"crunch", 0.12)
	arena._shake = maxf(arena._shake, 0.22)
	if not arena.demo:
		Save.buzz(18)
	if _frozen_drops.has(c):
		var kind: StringName = _frozen_drops[c]
		_frozen_drops.erase(c)
		arena.get_tree().create_timer(0.3, false).timeout.connect(arena._spawn_pickup.bind(c, kind))


## Ice shards that fly off a frozen crate and bounce on the floor.
func _shards(c: Vector2i, count: int, power: float) -> void:
	var at := Vector3(c.x, 0.45, c.y)
	var mesh := Models.box_mesh(Vector3(0.16, 0.12, 0.1), 0.025)
	var glass: Material = Art.ice_glass(Art.ICE, 0.45, 0.2)
	for k in count:
		var n := Models.part(arena, mesh, Art.ICE, at + Vector3(arena.rng.randf_range(-0.25, 0.25), arena.rng.randf_range(-0.2, 0.25), arena.rng.randf_range(-0.25, 0.25)))
		n.material_override = glass
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.rotation = Vector3(arena.rng.randf() * TAU, arena.rng.randf() * TAU, 0)
		var a: float = TAU * k / count + arena.rng.randf_range(-0.3, 0.3)
		var out: float = arena.rng.randf_range(1.6, 3.6) * power
		arena._fx.append({"node": n, "t": 0.0, "life": arena.rng.randf_range(0.8, 1.1), "kind": &"debris", "floor": 0.06,
			"vel": Vector3(cos(a) * out, arena.rng.randf_range(2.5, 5.0) * maxf(power, 0.6), sin(a) * out),
			"spin": Vector3(arena.rng.randf_range(-12, 12), arena.rng.randf_range(-12, 12), arena.rng.randf_range(-12, 12))})


# --- Sliding on ice ----------------------------------------------------------------

func on_hero_enter(c: Vector2i) -> void:
	# Compare with the tile Pip really stood on last frame (while sliding the
	# arena may report a tile his walking input nudged him to for a moment).
	var d: Vector2i = c - _last_cell
	if _slide != Vector2i.ZERO or arena.state != &"play":
		return
	_pending = false
	if not ice.has(c) or absi(d.x) + absi(d.y) != 1:
		return
	# Right after a tap, wait a moment: a second tap (a double tap to drop
	# a pod) takes the walk back, and Pip should not have shot off by then.
	if arena.walk_goal != Arena.NO_CELL and (arena.walk_goal != _goal_prev or _clock - _goal_set_t < TAP_GRACE):
		_pending = true
		_pending_dir = d
		_pending_t0 = _clock if arena.walk_goal != _goal_prev else _goal_set_t
		_pending_pods = arena.pods_out
		return
	_start_slide(d)


func process(delta: float) -> void:
	_clock += delta
	if arena.demo or arena.hero == null:
		return
	if arena.walk_goal != _goal_prev:
		_goal_prev = arena.walk_goal
		_goal_set_t = _clock
		_goal_stops.clear()
	_update_slide(delta)
	_last_pos = arena.hero_pos
	_last_cell = arena.hero_cell()
	if arena.boss != null:
		_boss_minions()


func _start_slide(d: Vector2i) -> void:
	_slide = d
	_pending = false
	_slide_speed = maxf(arena.speed, 3.4)
	_slide_fresh = true
	Sfx.play(&"whoosh", 0.15)


func _update_slide(delta: float) -> void:
	if arena.state != &"play" or not arena.hero_alive:
		_slide = Vector2i.ZERO
		_pending = false
		return
	if _slide == Vector2i.ZERO:
		if _pending:
			_try_pending()
		if _slide == Vector2i.ZERO:
			return
	if not _slide_fresh:
		if arena.hero_pos.distance_to(_last_pos) > 0.7:
			# Warped or put back at the start: the slide is over.
			_end_slide()
			return
		# Pip cannot steer on ice: undo this frame's walking.
		arena.hero_pos = _last_pos
	_slide_fresh = false
	_slide_speed = minf(_slide_speed + SLIDE_ACCEL * delta, SLIDE_MAX)
	var before: Vector2 = arena.hero_pos
	var np: Vector2 = arena._move_axis(before, _slide, _slide_speed * delta, _slide_blocked)
	var nc := Vector2i(roundi(np.x), roundi(np.y))
	var a: int = 0 if _slide.x != 0 else 1
	var stop: bool = false
	if not ice.has(nc) and (np[a] - float(nc[a])) * float(_slide[a]) >= -0.0005:
		# Off the ice onto snow: dig in on the middle of the tile.
		np[a] = float(nc[a])
		stop = true
	if np.distance_squared_to(before) < 1e-7:
		stop = true
	arena.hero_pos = np
	_pose_slide(delta)
	if stop:
		_end_slide()


## After the tap grace Pip slides on the way he was heading (or the way
## he walks now, if a new tap turned him), unless a double tap dropped a pod.
func _try_pending() -> void:
	var c: Vector2i = arena.hero_cell()
	if not ice.has(c) or arena.pods_out > _pending_pods:
		_pending = false
		return
	if _clock - _pending_t0 < TAP_GRACE:
		return
	_pending = false
	var d: Vector2i = _pending_dir
	var mv: Vector2 = arena.hero_pos - _last_pos
	if mv.length_squared() > 1e-8:
		d = Vector2i(int(signf(mv.x)), 0) if absf(mv.x) > absf(mv.y) else Vector2i(0, int(signf(mv.y)))
	_start_slide(d)
	_slide_fresh = true


## Sliding stops short of walls, crates, pods, live flames and critters, so
## the ice never carries Pip into harm by itself.
func _slide_blocked(c: Vector2i) -> bool:
	if arena._hero_blocked(c) or arena.flames.has(c):
		return true
	for cr: Arena.Critter in arena.critters:
		var reach: float = 1.3 if cr.kind == &"boss" else 0.8
		if cr.pos.distance_to(Vector2(c)) < reach:
			return true
	return false


func _end_slide() -> void:
	_slide = Vector2i.ZERO
	var here: Vector2i = arena.hero_cell()
	var g: Vector2i = arena.walk_goal
	if g != Arena.NO_CELL:
		# A tapped goal out on the ice (Pip can rarely stop there: the slide
		# was the point), a pod's tile, or a walk that keeps sliding back and
		# forth: give it up.
		if (ice.has(g) and g != here) or arena.pod_at.has(g) or _goal_stops.has(here):
			arena.walk_goal = Arena.NO_CELL
		else:
			_goal_stops[here] = true
	for k in 3:
		_ice_spark(0.9)


func _pose_slide(delta: float) -> void:
	var hero: Node3D = arena.hero
	hero.position = Vector3(arena.hero_pos.x, 0.0, arena.hero_pos.y)
	arena.hero_yaw = atan2(float(_slide.x), float(_slide.y))
	arena.hero_moving = true
	var body: Node3D = hero.get_node("Body")
	body.rotation.x = -0.16
	body.rotation.z = sin(_clock * 16.0) * 0.06
	body.position.y = 0.0
	(body.get_node("FootL") as Node3D).position.z = 0.12
	(body.get_node("FootR") as Node3D).position.z = 0.12
	_trail_t += delta
	if _trail_t > 0.05:
		_trail_t = 0.0
		_ice_spark(0.5)


func _ice_spark(power: float) -> void:
	if arena._fx.size() > 240:
		return
	var at := Vector3(arena.hero_pos.x, 0.06, arena.hero_pos.y)
	var n := Models.part(arena, arena._spark_mesh, Color("#E4F7FF"), at, 1.2)
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var a: float = arena.rng.randf() * TAU
	arena._fx.append({"node": n, "t": 0.0, "life": 0.4, "kind": &"spark",
		"vel": Vector3(cos(a) * 1.2 * power - _slide.x * 0.8, arena.rng.randf_range(1.0, 2.0) * power, sin(a) * 1.2 * power - _slide.y * 0.8),
		"spin": Vector3(arena.rng.randf_range(-10, 10), arena.rng.randf_range(-10, 10), 0)})


# --- Critters ----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"snowpuff":
			return Art.snowpuff()
		&"boss":
			return Art.yeti()
	return null


func critter_speed(kind: StringName) -> float:
	return SNOWPUFF_SPEED if kind == &"snowpuff" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"snowpuff":
		return Vector2i.ZERO
	var run: int = int(_runs.get(cr, 0))
	var d: Vector2i = _charge_dir(cr)
	if d == Vector2i.ZERO and arena._critter_can_enter(cr, cr.cell + cr.dir):
		d = cr.dir
	if d == Vector2i.ZERO:
		# Bumped into something: a puff of snow, shrink back and turn.
		if run > 1:
			_snow_burst(Vector3(cr.pos.x + cr.dir.x * 0.35, 0.3, cr.pos.y + cr.dir.y * 0.35), 5)
		run = 0
		var open: Array[Vector2i] = []
		for dd: Vector2i in DIRS4:
			if dd != -cr.dir and arena._critter_can_enter(cr, cr.cell + dd):
				open.append(dd)
		if open.is_empty():
			return Vector2i.ZERO
		d = open[arena.rng.randi() % open.size()]
	elif d != cr.dir:
		run = 0
	run += 1
	_runs[cr] = run
	cr.speed = SNOWPUFF_SPEED + minf(run - 1, 5) * 0.3 + (0.5 if ice.has(cr.cell + d) else 0.0)
	return d


## Which way to charge at Pip: he is in a straight, open line within six
## tiles. Zero when not.
func _charge_dir(cr: Arena.Critter) -> Vector2i:
	if arena.demo or not arena.hero_alive or arena.state != &"play":
		return Vector2i.ZERO
	var hc: Vector2i = arena.hero_cell()
	var diff: Vector2i = hc - cr.cell
	if (diff.x != 0 and diff.y != 0) or diff == Vector2i.ZERO or absi(diff.x) + absi(diff.y) > 6:
		return Vector2i.ZERO
	var d := Vector2i(signi(diff.x), signi(diff.y))
	var c: Vector2i = cr.cell + d
	while c != hc:
		if not arena._critter_can_enter(cr, c):
			return Vector2i.ZERO
		c += d
	return d if arena._critter_can_enter(cr, cr.cell + d) else Vector2i.ZERO


func critter_hit(cr: Arena.Critter) -> bool:
	if cr.kind == &"snowpuff":
		_snow_burst(Vector3(cr.pos.x, 0.4, cr.pos.y), 8)
	elif cr.kind == &"boss" and cr.invuln <= 0.0:
		_snow_burst(Vector3(cr.pos.x, 0.9, cr.pos.y), 10)
	return false


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"snowpuff":
			var ball: Node3D = body.get_node("Ball")
			var rolling: bool = cr.t < 1.0
			if rolling:
				ball.rotation.x += cr.speed * delta / 0.31
			var run: int = int(_runs.get(cr, 0))
			var g: float = 1.0 + minf(run, 5) * 0.07
			body.position.y = absf(sin(t * 9.0)) * 0.03 if rolling else 0.0
			(body.get_node("Hat") as Node3D).rotation.z = sin(t * 6.0) * 0.12
			return Vector3(g, g, g)
		&"boss":
			var sw: float = sin(t * 4.5)
			(body.get_node("Rig/ArmL") as Node3D).rotation.x = sw * 0.55
			(body.get_node("Rig/ArmR") as Node3D).rotation.x = -sw * 0.55
			(body.get_node("Rig/ArmL") as Node3D).rotation.z = -0.15 - absf(sw) * 0.1
			(body.get_node("Rig/ArmR") as Node3D).rotation.z = 0.15 + absf(sw) * 0.1
			body.position.y = absf(sw) * 0.05
			body.rotation.z = sw * 0.05
			return Vector3(1.0, 1.0 + absf(sin(t * 9.0)) * 0.035, 1.0)
	return Vector3.ONE


func _snow_burst(at: Vector3, count: int) -> void:
	for k in count:
		var n := Models.part(arena, arena._spark_mesh, Art.SNOW, at, 0.6)
		n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.scale = Vector3.ONE * 1.5
		var a: float = TAU * k / count
		arena._fx.append({"node": n, "t": 0.0, "life": 0.5, "kind": &"spark",
			"vel": Vector3(cos(a) * 2.0, arena.rng.randf_range(1.2, 2.6), sin(a) * 2.0),
			"spin": Vector3(arena.rng.randf_range(-10, 10), arena.rng.randf_range(-10, 10), 0)})


## Big Brrr kicks out Snowpuffs: every other critter he summons is one.
func _boss_minions() -> void:
	for cr: Arena.Critter in arena.critters.duplicate():
		if _known.has(cr):
			continue
		_known[cr] = true
		if cr.kind != &"blobbit":
			continue
		_summons += 1
		if _summons % 2 == 1:
			continue
		var c: Vector2i = cr.cell
		arena.critters.erase(cr)
		cr.node.queue_free()
		var s: Arena.Critter = arena._spawn_critter(&"snowpuff", c)
		s.node.scale = Vector3.ONE * 0.01
		_known[s] = true
		_snow_burst(Vector3(c.x, 0.4, c.y), 6)

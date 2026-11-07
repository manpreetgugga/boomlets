class_name Arena
extends Node3D
## One arena: builds the level from its map, runs every rule (moving, fizz
## pods, blasts, crates, power-ups, critters, belts, warps, barrels, the
## boss) and draws it. The HUD reads its fields each frame and feeds it
## input through [method set_input] and [method drop_pod].

signal won(stars: int, seconds: float)
signal lost(reason: String)
## Pip picked up a power-up (the HUD calls out the rare Pod Party).
signal powered_up(kind: StringName)

enum { FLOOR, WALL, CRATE, BARREL }

const W: int = 13
const H: int = 15
const FUSE: float = 2.5
const FLAME_TIME: float = 0.55
const TIME_LIMIT: float = 240.0
const BELT_SPEED: float = 2.2
const KICK_SPEED: float = 7.5
const BARREL_FIRE: int = 3
const BOSS_HP: int = 6
const BASE_SPEED: float = 3.0
const SPEED_STEP: float = 0.4
const MAX_SPEED: float = 4.6
## The rare Pod Party power-up lets Pip carry this many pods at once. One
## hides in a crate in every boss fight; any other level has PARTY_CHANCE
## of one.
const PARTY_PODS: int = 5
const PARTY_CHANCE: float = 0.05
const NO_CELL := Vector2i(-1, -1)
## Camera: horizontal field of view, and how steeply it looks down.
const CAM_FOV: float = 34.0
const CAM_DIR := Vector3(0.0, 11.0, 5.0)
## Screen space (in 720-wide UI pixels) the HUD covers at the top; the arena
## is centred in the space below it.
const HUD_TOP: float = 170.0
## Seconds a cached tap-walk step stays good when nothing else changed (catches
## walls that open and shut on their own).
const WALK_REFRESH: float = 0.25
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const CRITTER_SPEED: Dictionary = {&"blobbit": 1.5, &"buzzer": 2.1, &"wisp": 1.1, &"boss": 1.0}
## Difficulty eases in over the worlds. Each pair below is (gentlest, last
## world): worlds up to EASY_WORLDS get the first, the last world gets the
## second and the worlds between step smoothly from one to the other.
const EASY_WORLDS: int = 5
## Seconds a pod takes to go off.
const FUSE_RANGE := Vector2(2.4, 2.1)
## Share of its listed speed every critter (and boss) walks at.
const PACE_RANGE := Vector2(0.68, 0.78)
## How close Pip must be (tiles along the grid) before a buzzer chases him.
const CHASE_RANGE := Vector2(4.0, 6.0)
## Critters notice a ticking pod only in its last this-many seconds...
const NOTICE_RANGE := Vector2(0.6, 1.0)
## ...and now and then not at all: the chance they miss one.
const MISS_RANGE := Vector2(0.35, 0.15)
## Critters only see pods this close (tiles along the grid).
const CRITTER_SIGHT: int = 3
## The chance a critter is dazed by a pod it has just spotted: it stares at
## it until it goes off (see _start_stare). Unlike the pairs above, this
## eases off from world 1: (world 1, last world).
const STARE_RANGE := Vector2(0.3, 0.12)
## Lives at the start of every level. Few on purpose: running out offers a
## rewarded ad for one more (see revive).
const START_LIVES: int = 2
## Seconds Pip cannot be hurt after coming back.
const RESPAWN_GRACE: float = 3.0
## How close a critter's centre must come to Pip's to hurt him, in tiles.
const CRITTER_REACH: float = 0.55
const BOSS_REACH: float = 0.9


class Pod:
	var cell: Vector2i
	var pos: Vector2
	var timer: float = FUSE
	var fire: int = 2
	var node: Node3D
	var slide: Vector2i = Vector2i.ZERO
	var slide_speed: float = 0.0
	var kicked: bool = false
	var age: float = 0.0
	## Instance ids of the critters that have already spotted this pod (see
	## _start_stare). Ids, so a dazed critter and its pod don't keep each
	## other alive.
	var seen: Dictionary = {}


class Critter:
	var kind: StringName
	var cell: Vector2i
	var target: Vector2i
	var t: float = 1.0
	var dir: Vector2i = Vector2i(0, 1)
	var speed: float = 1.5
	var node: Node3D
	var hp: int = 1
	## The model came from the world kit, which also animates it.
	var custom: bool = false
	var invuln: float = 0.0
	var think: float = 6.0
	var phase: float = 0.0
	var pos: Vector2
	## The pod it stands staring at until it goes off (see _start_stare),
	## or null.
	var stare: Pod
	## The "?" over its head while it stares (made the first time).
	var mark: Label3D


var world_id: int = 1
var level_id: int = 1
var data: Dictionary
## The world's own look and rules (see worlds/WorldKit.gd).
var kit: WorldKit
## Hits the boss takes in this world (the HUD draws one bar segment each).
var boss_max_hp: int = BOSS_HP
var _kit_cell := Vector2i(-99, -99)
var demo: bool = false

# The grid.
var tiles := PackedInt32Array()
var belts: Dictionary = {}     # Vector2i -> Vector2i direction
var warps: Dictionary = {}     # Vector2i -> Vector2i destination
var drops: Dictionary = {}     # Vector2i -> StringName power-up hidden in that crate
var crate_slot: Dictionary = {}  # Vector2i -> multimesh instance index
var barrels: Dictionary = {}   # Vector2i -> Node3D
var pods: Array[Pod] = []
var pod_at: Dictionary = {}    # Vector2i -> Pod
var flames: Dictionary = {}    # Vector2i -> seconds left
var pickups: Dictionary = {}   # Vector2i -> {kind, node}
var critters: Array[Critter] = []
var start_cell: Vector2i
var exit_cell: Vector2i = Vector2i(-1, -1)
var exit_open: bool = false
var boss: Critter

# The hero, Pip.
var hero: Node3D
var hero_pos: Vector2
var hero_alive: bool = true
var hero_invuln: float = 0.0
var hero_pass: Array[Pod] = []
var hero_warped: bool = false
var hero_moving: bool = false
var hero_yaw: float = 0.0
var lives: int = START_LIVES
## Set before setup() after the player lost this level twice in a row:
## slower critters, quietly (no extra life: every level has START_LIVES).
var assist: bool = false
## This level's fuse and critter settings (see EASY_WORLDS and assist).
var fuse: float = FUSE
var critter_pace: float = PACE_RANGE.x
var critter_chase: int = int(CHASE_RANGE.x)
var critter_notice: float = NOTICE_RANGE.x
var critter_miss: float = MISS_RANGE.x
var critter_sight: int = CRITTER_SIGHT
var critter_stare: float = STARE_RANGE.x
var max_pods: int = 1
var fire: int = 2
var speed: float = BASE_SPEED
var can_kick: bool = false
## The tile Pip is walking to after a tap, or NO_CELL.
var walk_goal: Vector2i = NO_CELL
## The last answer of _walk_step and what it was worked out from: the path
## search runs again only when one of these changes, or after WALK_REFRESH.
var _walk_key: Array = []
var _walk_dir: Vector2i = Vector2i.ZERO
var _walk_age: float = 0.0
## Counts down while Pip shakes his head at a pod he would not escape.
var _refuse_t: float = 0.0
var shield: bool = false
var pods_out: int = 0
var deaths: int = 0

var elapsed: float = 0.0
var state: StringName = &"play"   # play, dying, won, lost
var input_primary: Vector2i = Vector2i.ZERO
var input_secondary: Vector2i = Vector2i.ZERO

var camera: Camera3D
var _shake: float = 0.0
var _cam_focus: Vector3
## Dev only: a close-up camera for store screenshots (x, z, distance, height);
## off while w is 0.
var shot_cam: Vector4 = Vector4.ZERO
var _orbit: float = 0.0
var _clock: float = 0.0
var _walk_phase: float = 0.0
var _dying_t: float = 0.0
var _won_t: float = 0.0
var _danger: Dictionary = {}
var _danger_frame: int = -1
var _hero_danger_cache: Dictionary = {}
var _hero_danger_frame: int = -1
var _crit_cache: Dictionary = {}
var _crit_frame: int = -1
## Soft red tiles under every blast line while a pod ticks.
var _blast_mm: MultiMeshInstance3D
var rng := RandomNumberGenerator.new()

var _crates_mm: MultiMesh
var _bands_mm: MultiMesh
var _belt_nodes: Array[Node3D] = []
var _warp_nodes: Array[Node3D] = []
var _exit_node: Node3D
var _shield_node: MeshInstance3D
var _fx: Array[Dictionary] = []
## Effect pieces (sparks, chips, smoke...) and flame clusters that have
## finished, hidden and kept for the next blast instead of being freed and
## built again. Entries made with fx_part() carry "pool": true.
var _fx_pool: Array[MeshInstance3D] = []
var _flame_pool: Dictionary = {true: [], false: []}   # arm? -> Array of Node3D
const FX_POOL_MAX: int = 320
var _flame_mesh: Mesh
var _spark_mesh: Mesh
var _smoke_mesh: Mesh
var _plank_mesh: Mesh
var _ring_mesh: Mesh
var _scorch_mesh: Mesh
var _flash_mesh: Mesh
var _chunk_mesh: Mesh
var _marker: Node3D
var _marker_t: float = 0.0


## Builds level [param level] of world [param world]. A [param demo_mode]
## arena has no hero: the camera turns around it for the menu.
func setup(world: int, level: int, demo_mode: bool = false) -> void:
	world_id = world
	level_id = level
	demo = demo_mode
	kit = Levels.make_kit(world)
	kit.arena = self
	data = kit.levels()[clampi(level, 1, kit.levels().size()) - 1]
	tune_for(world)
	Models.meshes_for(world)
	lives = START_LIVES
	if not Models.palette_locked:
		Models.use_palette(kit.palette())
	if not demo_mode:
		Sfx.track(kit.music())
	rng.seed = hash(String(data["name"]))
	# Effects are built from crisp, slightly bevelled blocks to match the
	# walls: chunky fire cubes, shards and dust cubes rather than soft blobs.
	_flame_mesh = Models.box_mesh(Vector3(0.42, 0.42, 0.42), 0.06)
	_spark_mesh = Models.box_mesh(Vector3(0.1, 0.1, 0.1), 0.015)
	_smoke_mesh = Models.box_mesh(Vector3(0.3, 0.3, 0.3), 0.05)
	_plank_mesh = Models.box_mesh(Vector3(0.52, 0.11, 0.19), 0.03)
	_flash_mesh = Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1)
	_chunk_mesh = Models.box_mesh(Vector3(0.24, 0.2, 0.24), 0.035)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.42
	ring.outer_radius = 0.5
	ring.rings = 32
	ring.ring_segments = 4
	_ring_mesh = ring
	var scorch := CylinderMesh.new()
	scorch.top_radius = 0.42
	scorch.bottom_radius = 0.42
	scorch.height = 0.02
	scorch.radial_segments = 8
	scorch.rings = 1
	_scorch_mesh = scorch
	_build_environment()
	_parse_map()
	_build_world()
	_build_props()
	if not demo:
		hero = Models.hero()
		add_child(hero)
		hero_pos = Vector2(start_cell)
		hero.position = _to3(hero_pos)
		_build_shield()
		_marker = Models.walk_marker()
		_marker.visible = false
		add_child(_marker)
		_build_blast_zone()
	kit.build_extra()
	camera = Camera3D.new()
	camera.keep_aspect = Camera3D.KEEP_WIDTH
	camera.fov = 52.0 if demo else CAM_FOV
	camera.near = 0.5
	camera.far = 120.0
	add_child(camera)
	_cam_focus = _focus_target()
	_update_camera(0.0, true)
	camera.make_current()
	rng.randomize()


## Sets the fuse and critter settings for [param world]: gentlest up to
## EASY_WORLDS, then a little harder each world up to the last (see the
## *_RANGE constants), with [member assist] slowing critters on top. The
## chance pods daze critters eases off from world 1 instead.
func tune_for(world: int) -> void:
	var ramp: float = clampf(float(world - EASY_WORLDS) / float(Levels.WORLD_COUNT - EASY_WORLDS), 0.0, 1.0)
	fuse = lerpf(FUSE_RANGE.x, FUSE_RANGE.y, ramp)
	critter_pace = lerpf(PACE_RANGE.x, PACE_RANGE.y, ramp) * (0.85 if assist else 1.0)
	critter_chase = roundi(lerpf(CHASE_RANGE.x, CHASE_RANGE.y, ramp))
	critter_notice = lerpf(NOTICE_RANGE.x, NOTICE_RANGE.y, ramp)
	critter_miss = lerpf(MISS_RANGE.x, MISS_RANGE.y, ramp)
	var from_first: float = clampf(float(world - 1) / float(Levels.WORLD_COUNT - 1), 0.0, 1.0)
	critter_stare = lerpf(STARE_RANGE.x, STARE_RANGE.y, from_first)


func set_input(primary: Vector2i, secondary: Vector2i) -> void:
	input_primary = primary
	input_secondary = secondary
	if primary != Vector2i.ZERO:
		walk_goal = NO_CELL


## The arena tile under a point on the screen (the arena edge when the point
## is off the arena), or NO_CELL.
func cell_at_screen(p: Vector2) -> Vector2i:
	if camera == null:
		return NO_CELL
	var o: Vector3 = camera.project_ray_origin(p)
	var d: Vector3 = camera.project_ray_normal(p)
	if d.y > -0.01:
		return NO_CELL
	# Aim at roughly knee height so tapping the top of a block or critter
	# still picks its tile.
	var hit: Vector3 = o + d * ((0.3 - o.y) / d.y)
	return Vector2i(clampi(roundi(hit.x), 1, W - 2), clampi(roundi(hit.z), 1, H - 2))


## Sends Pip toward the tile under [param screen_pos].
func walk_to_screen(screen_pos: Vector2) -> void:
	var c: Vector2i = cell_at_screen(screen_pos)
	if c != NO_CELL:
		walk_to(c)


## Sends Pip toward [param c], or the closest tile to it he can get to.
func walk_to(c: Vector2i) -> void:
	if demo or hero == null or state != &"play":
		return
	# Choose the goal ignoring pods and flames (they will clear), so a tap
	# behind a pod still means "go there".
	var r: Dictionary = _hero_search(false, true)
	var dist: Dictionary = r["dist"]
	var best: Vector2i = hero_cell()
	var best_score: int = 1 << 30
	for cell: Vector2i in dist:
		var score: int = (absi(cell.x - c.x) + absi(cell.y - c.y)) * 1000 + int(dist[cell])
		if score < best_score:
			best_score = score
			best = cell
	set_walk_goal(best)
	_marker_t = 0.0


func set_walk_goal(c: Vector2i) -> void:
	walk_goal = c
	input_primary = Vector2i.ZERO
	input_secondary = Vector2i.ZERO


func critters_left() -> int:
	return critters.size()


func time_left() -> float:
	return maxf(TIME_LIMIT - elapsed, 0.0)


func stars_for_time(seconds: float) -> int:
	var par: float = float(data.get("par", 90))
	if seconds <= par:
		return 3
	if seconds <= par * 1.6:
		return 2
	return 1


# --- Grid helpers -----------------------------------------------------------

func tile(c: Vector2i) -> int:
	if c.x < 0 or c.y < 0 or c.x >= W or c.y >= H:
		return WALL
	return tiles[c.y * W + c.x]


func _set_tile(c: Vector2i, t: int) -> void:
	tiles[c.y * W + c.x] = t


func _to3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3(p.x, y, p.y)


func hero_cell() -> Vector2i:
	return Vector2i(roundi(hero_pos.x), roundi(hero_pos.y))


# --- Building ---------------------------------------------------------------

func _parse_map() -> void:
	var rows: Array = data["map"]
	tiles.resize(W * H)
	tiles.fill(FLOOR)
	var crate_cells: Array[Vector2i] = []
	var spawns: Array = []
	var warp_cells: Dictionary = {}
	var density: float = float(data.get("crates", 0.5))
	for z in H:
		var row: String = rows[z]
		if row.length() != W:
			push_error("Level %s row %d is %d long, not %d" % [data["name"], z, row.length(), W])
		for x in W:
			var c := Vector2i(x, z)
			var ch: String = row[x] if x < row.length() else "#"
			if kit.critter_chars().has(ch):
				spawns.append([StringName(kit.critter_chars()[ch]), c])
				continue
			match ch:
				"#":
					_set_tile(c, WALL)
				".":
					if rng.randf() < density:
						_set_tile(c, CRATE)
						crate_cells.append(c)
				"c":
					_set_tile(c, CRATE)
					crate_cells.append(c)
				"B":
					_set_tile(c, BARREL)
				"S":
					start_cell = c
				"E":
					exit_cell = c
				"b":
					spawns.append([&"blobbit", c])
				"z":
					spawns.append([&"buzzer", c])
				"w":
					spawns.append([&"wisp", c])
				"K":
					spawns.append([&"boss", c])
				">":
					belts[c] = Vector2i(1, 0)
				"<":
					belts[c] = Vector2i(-1, 0)
				"^":
					belts[c] = Vector2i(0, -1)
				"v":
					belts[c] = Vector2i(0, 1)
				"1", "2", "3":
					if not warp_cells.has(ch):
						warp_cells[ch] = []
					warp_cells[ch].append(c)
				"_":
					pass
				_:
					if not kit.parse_tile(ch, c):
						push_error("Level %s: unknown map character '%s'" % [data["name"], ch])
	for key: String in warp_cells:
		var pair: Array = warp_cells[key]
		if pair.size() == 2:
			warps[pair[0]] = pair[1]
			warps[pair[1]] = pair[0]
	# Hide the power-ups in random crates.
	var shuffled: Array[Vector2i] = crate_cells.duplicate()
	_shuffle(shuffled)
	var k: int = 0
	var want: Dictionary = data.get("drops", {})
	for kind: String in want:
		for i in int(want[kind]):
			if k < shuffled.size():
				drops[shuffled[k]] = StringName(kind)
				k += 1
	# And a Pod Party: in every boss fight, now and then elsewhere. Rolled
	# with the global random numbers rather than rng (seeded by the level's
	# name), so it changes from try to try and leaves the layout alone.
	var boss_fight: bool = spawns.any(func(s: Array) -> bool: return s[0] == &"boss")
	if not demo and not shuffled.is_empty() and (boss_fight or randf() < PARTY_CHANCE):
		var spare: int = shuffled.size() - k
		drops[shuffled[k + randi() % spare] if spare > 0 else shuffled.pick_random()] = &"party"
	for s: Array in spawns:
		_spawn_critter(s[0], s[1])


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp


func _spawn_critter(kind: StringName, c: Vector2i) -> Critter:
	var cr := Critter.new()
	cr.kind = kind
	cr.cell = c
	cr.target = c
	cr.pos = Vector2(c)
	cr.speed = CRITTER_SPEED[kind] if CRITTER_SPEED.has(kind) else kit.critter_speed(kind)
	if not CRITTER_SPEED.has(kind):
		cr.hp = kit.critter_hp(kind)
	cr.phase = rng.randf() * TAU
	cr.dir = DIRS[rng.randi() % 4]
	var custom: Node3D = kit.critter_model(kind)
	match kind:
		&"blobbit":
			cr.node = Models.blobbit()
		&"buzzer":
			cr.node = Models.buzzer()
		&"wisp":
			cr.node = Models.wisp()
		&"boss":
			cr.node = Models.boss()
			cr.hp = kit.boss_hp()
			boss_max_hp = cr.hp
			cr.think = 5.0
			boss = cr
	if custom != null:
		if cr.node != null:
			cr.node.free()
		cr.node = custom
		cr.custom = true
	if cr.node == null:
		push_error("No model for critter kind %s" % kind)
		cr.node = Models.blobbit()
	cr.node.position = _to3(cr.pos)
	add_child(cr.node)
	critters.append(cr)
	return cr


func _build_environment() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = preload("res://shaders/sky_gradient.gdshader")
	sky_mat.set_shader_parameter(&"top_color", Models.SKY_TOP)
	sky_mat.set_shader_parameter(&"horizon_color", Models.SKY_HORIZON)
	sky_mat.set_shader_parameter(&"ground_color", Models.SKY_GROUND)
	sky_mat.set_shader_parameter(&"cloud_amount", Models.CLOUDS)
	sky_mat.set_shader_parameter(&"cloud_color", Models.CLOUD)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_64
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Models.AMBIENT
	env.ambient_light_energy = Models.AMBIENT_ENERGY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.45
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sky_c: Color = Models.SKY_TOP.srgb_to_linear()
	RenderingServer.global_shader_parameter_set(&"sky_tint", Vector3(sky_c.r, sky_c.g, sky_c.b))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_color = Models.SUN
	sun.light_energy = Models.SUN_ENERGY
	sun.shadow_enabled = true
	sun.shadow_blur = 2.5
	sun.shadow_bias = 0.03
	sun.shadow_normal_bias = 1.1
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_max_distance = 32.0
	add_child(sun)
	kit.tune_environment(env, sun)


func _multimesh(mesh: Mesh, color: Color, transforms: Array[Transform3D], material: Material = null) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = material if material != null else Models.mat(color)
	add_child(mmi)
	return mm


func _build_world() -> void:
	var cx: float = (W - 1) * 0.5
	var cz: float = (H - 1) * 0.5
	# The floating island under the arena: a grassy rim, a dirt layer and
	# rock tapering down to a point.
	var island := Node3D.new()
	add_child(island)
	Models.part(island, Models.box_mesh(Vector3(W + 2.2, 0.5, H + 2.2), 0.25), Models.RIM, Vector3(cx, -0.27, cz))
	Models.part(island, Models.box_mesh(Vector3(W + 1.9, 1.3, H + 1.9), 0.4), Models.DIRT, Vector3(cx, -1.05, cz))
	Models.part(island, Models.box_mesh(Vector3(W - 1.0, 1.6, H - 1.0), 0.6), Models.ROCK, Vector3(cx, -2.3, cz))
	Models.part(island, Models.box_mesh(Vector3(W - 5.0, 1.6, H - 5.0), 0.6), Models.ROCK.darkened(0.08), Vector3(cx, -3.6, cz))
	Models.part(island, Models.box_mesh(Vector3(W - 9.0, 1.4, H - 9.0), 0.5), Models.ROCK.darkened(0.15), Vector3(cx, -4.8, cz))

	var floor_a: Array[Transform3D] = []
	var floor_b: Array[Transform3D] = []
	var hedges: Array[Transform3D] = []
	var pillars: Array[Transform3D] = []
	var crates: Array[Transform3D] = []
	for z in H:
		for x in W:
			var c := Vector2i(x, z)
			var border: bool = x == 0 or z == 0 or x == W - 1 or z == H - 1
			var p := Vector3(x, 0, z)
			if border:
				hedges.append(Transform3D(Basis(), p + Vector3(0, 0.31, 0)))
				continue
			if not belts.has(c):
				var tf := Transform3D(Basis(), p + Vector3(0, -0.15, 0))
				if (x + z) % 2 == 0:
					floor_a.append(tf)
				else:
					floor_b.append(tf)
			match tile(c):
				WALL:
					pillars.append(Transform3D(Basis(), p + Vector3(0, 0.4, 0)))
				CRATE:
					crate_slot[c] = crates.size()
					crates.append(Transform3D(Basis(), p + Vector3(0, 0.4, 0)))
				BARREL:
					var b := Models.barrel()
					b.position = p
					b.rotation.y = rng.randf() * TAU
					add_child(b)
					barrels[c] = b
	var tile_mesh := Models.box_mesh(Vector3(0.96, 0.3, 0.96), 0.08)
	_multimesh(tile_mesh, Models.GRASS_A, floor_a)
	_multimesh(tile_mesh, Models.GRASS_B, floor_b)
	# The border reads as stacked blocks with a lighter coping on top, and the
	# pillars get a cap too, so walls have crisp edges instead of soft lumps.
	var caps: Array[Transform3D] = []
	for tf in hedges:
		caps.append(tf.translated(Vector3(0, 0.31, 0)))
	_multimesh(Models.box_mesh(Vector3(0.95, 0.62, 0.95), 0.06), Models.EDGE, hedges)
	_multimesh(Models.box_mesh(Vector3(1.0, 0.13, 1.0), 0.045), Models.EDGE.lightened(0.24), caps)
	if not kit.build_wall_topper(hedges):
		_build_wall_bushes(hedges)
	if not kit.build_solid_blocks(pillars):
		_build_rocks(pillars)
	_crates_mm = _multimesh(Models.box_mesh(Vector3(0.84, 0.8, 0.84), 0.1), Models.WOOD, crates,
		Models.glass(Models.WOOD, 0.3) if Models.GLASS else null)
	var bands: Array[Transform3D] = []
	for tf in crates:
		bands.append(tf)
	_bands_mm = _multimesh(Models.box_mesh(Vector3(0.88, 0.14, 0.88), 0.05), Models.WOOD_DARK, bands,
		Models.glass(Models.WOOD_DARK, 0.7, 0.15) if Models.GLASS else null)

	# Belts: a dark slab with chevrons that run along it.
	var chev := Models.chevron_mesh()
	for c: Vector2i in belts:
		var d: Vector2i = belts[c]
		var cell := Node3D.new()
		cell.position = Vector3(c.x, 0, c.y)
		cell.rotation.y = atan2(-float(d.y), float(d.x))
		add_child(cell)
		Models.part(cell, Models.box_mesh(Vector3(0.96, 0.3, 0.96), 0.08), Models.BELT, Vector3(0, -0.16, 0))
		for k in 2:
			var ch := Models.part(cell, chev, Models.ACCENT, Vector3(-0.25 + k * 0.5, 0.0, 0), 0.25)
			ch.rotation.x = -PI * 0.5
			ch.set_meta(&"base", -0.25 + k * 0.5)
		_belt_nodes.append(cell)

	var warp_colors: Array[Color] = [Color("#9C7BEA"), Color("#4FC3D9"), Color("#F28DB2")]
	var seen: Dictionary = {}
	for c: Vector2i in warps:
		var pair_key: String = str(mini(c.x * 100 + c.y, warps[c].x * 100 + warps[c].y))
		if not seen.has(pair_key):
			seen[pair_key] = seen.size()
		var w := Models.teleporter(warp_colors[int(seen[pair_key]) % warp_colors.size()])
		w.position = Vector3(c.x, 0, c.y)
		add_child(w)
		_warp_nodes.append(w)

	if exit_cell.x >= 0:
		_exit_node = Models.exit_gate()
		_exit_node.position = Vector3(exit_cell.x, 0, exit_cell.y)
		add_child(_exit_node)
		var flag: Node3D = _exit_node.get_node("Flag")
		flag.position.y = 0.4


func _build_rocks(spots: Array[Transform3D]) -> void:
	# Each solid block is a little rock pile: a wide boulder, a smaller one
	# stacked off-centre on top and sometimes a pebble at its foot. Random
	# turns and tilts keep every pile different.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(data["name"])) + 11
	var lows: Array[Transform3D] = []
	var highs: Array[Transform3D] = []
	var pebbles: Array[Transform3D] = []
	for tf in spots:
		var p: Vector3 = Vector3(tf.origin.x, 0, tf.origin.z)
		var b := Basis(Vector3.UP, r.randf_range(-0.35, 0.35)).scaled(Vector3(r.randf_range(0.95, 1.05), r.randf_range(0.9, 1.1), r.randf_range(0.95, 1.05)))
		lows.append(Transform3D(b, p + Vector3(0, 0.26, 0)))
		var tilt := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.14, 0.14)) * Basis(Vector3.FORWARD, r.randf_range(-0.14, 0.14))
		highs.append(Transform3D(tilt, p + Vector3(r.randf_range(-0.09, 0.09), 0.62, r.randf_range(-0.09, 0.09))))
		if r.randf() < 0.6:
			var a: float = r.randf() * TAU
			pebbles.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(cos(a) * 0.36, 0.1, sin(a) * 0.36)))
	_multimesh(Models.box_mesh(Vector3(0.86, 0.52, 0.86), 0.2), Models.STONE.darkened(0.1), lows)
	_multimesh(Models.box_mesh(Vector3(0.6, 0.42, 0.58), 0.18), Models.STONE, highs)
	_multimesh(Models.box_mesh(Vector3(0.28, 0.2, 0.26), 0.09), Models.STONE.darkened(0.2), pebbles)


func _build_wall_bushes(blocks: Array[Transform3D]) -> void:
	# Little leafy tufts (some with flowers) growing on top of the border
	# wall. Batched into a few multimeshes so they cost next to nothing.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(data["name"])) + 3
	var leaf_a: Array[Transform3D] = []
	var leaf_b: Array[Transform3D] = []
	var blooms: Array[Array] = [[], [], []]
	var top: float = 0.68
	for tf in blocks:
		if r.randf() > 0.72:
			continue
		var base: Vector3 = tf.origin
		var n: int = r.randi_range(3, 4)
		for k in n:
			var a: float = TAU * k / n + r.randf()
			var s: float = r.randf_range(0.75, 1.1)
			var at := Vector3(base.x + cos(a) * 0.17, top + 0.1 * s, base.z + sin(a) * 0.17)
			var leaf := Transform3D(Basis().scaled(Vector3(s, s * 0.8, s)), at)
			if r.randf() < 0.5:
				leaf_a.append(leaf)
			else:
				leaf_b.append(leaf)
		if r.randf() < 0.45:
			for k in 2:
				var at := Vector3(base.x + r.randf_range(-0.18, 0.18), top + 0.26, base.z + r.randf_range(-0.18, 0.18))
				(blooms[r.randi() % 3] as Array).append(Transform3D(Basis(), at))
	var leaf_mesh := Models.sphere(0.21, -1, 12)
	_multimesh(leaf_mesh, Models.LEAFY_A, leaf_a)
	_multimesh(leaf_mesh, Models.LEAFY_B, leaf_b)
	var bloom_mesh := Models.sphere(0.045, -1, 6)
	var bloom_colors: Array[Color] = [Color("#FF8FA3"), Color("#FFE27A"), Models.WHITE]
	for i in 3:
		var list: Array[Transform3D] = []
		list.assign(blooms[i])
		_multimesh(bloom_mesh, bloom_colors[i], list)


func _build_props() -> void:
	# Decor on the grassy rim and a few far-off islands for depth.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(data["name"])) + 7
	for x in range(-1, W + 1):
		for z: int in [-1, H]:
			_rim_prop(Vector3(x, 0, z), r, z == H)
	for z in range(0, H):
		for x: int in [-1, W]:
			_rim_prop(Vector3(x, 0, z), r, false)
	for spec: Array in [[Vector3(-7.5, -2.0, 1.0), 3.2], [Vector3(W + 6.0, -1.0, 3.0), 2.6], [Vector3(-5.5, -4.5, H + 2.0), 2.0], [Vector3(W + 4.5, -5.0, H - 1.0), 2.4]]:
		var isle := Node3D.new()
		isle.position = spec[0]
		add_child(isle)
		var s: float = spec[1]
		Models.part(isle, Models.box_mesh(Vector3(s, 0.5, s), 0.22), Models.RIM, Vector3(0, -0.25, 0))
		Models.part(isle, Models.box_mesh(Vector3(s * 0.8, 1.0, s * 0.8), 0.3), Models.DIRT, Vector3(0, -0.9, 0))
		Models.part(isle, Models.box_mesh(Vector3(s * 0.45, 1.0, s * 0.45), 0.25), Models.ROCK, Vector3(0, -1.7, 0))
		var own: Node3D = kit.far_island_prop(r, s)
		if own != null:
			isle.add_child(own)
			continue
		var t := Models.tree(r.randf() < 0.5, r)
		t.scale = Vector3.ONE * 1.3
		isle.add_child(t)
		var b := Models.bush(r)
		b.position = Vector3(s * 0.25, 0, s * 0.2)
		isle.add_child(b)


func _rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> void:
	var own: Node3D = kit.rim_prop(p, r, near_side)
	if own != null:
		own.position = p
		add_child(own)
		return
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.35:
			node = Models.flowers(r)
		elif roll < 0.5:
			node = Models.rock(r)
	else:
		if roll < 0.16:
			node = Models.tree(r.randf() < 0.5, r)
		elif roll < 0.32:
			node = Models.bush(r)
		elif roll < 0.38:
			node = Models.lamp()
		elif roll < 0.6:
			node = Models.flowers(r)
	if node != null:
		node.position = p + Vector3(r.randf_range(-0.15, 0.15), 0, r.randf_range(-0.15, 0.15))
		add_child(node)


func _build_shield() -> void:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.9, 1.0, 0.28)
	m.emission_enabled = true
	m.emission = Color(0.55, 0.75, 1.0)
	m.emission_energy_multiplier = 0.6
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield_node = MeshInstance3D.new()
	_shield_node.mesh = Models.sphere(0.55, -1, 24)
	_shield_node.material_override = m
	_shield_node.position.y = 0.45
	_shield_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shield_node.visible = false
	hero.add_child(_shield_node)


# --- The frame --------------------------------------------------------------

func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	_clock += delta
	if state == &"play" and not demo:
		elapsed += delta
		if elapsed >= TIME_LIMIT:
			_lose("Time's up!")
	_update_hero(delta)
	_update_pods(delta)
	_update_blast_zone()
	_update_flames(delta)
	_update_critters(delta)
	kit.process(delta)
	_update_pickups(delta)
	_update_fx(delta)
	_animate_scenery(delta)
	_update_camera(delta, false)


## The red tiles that show where ticking pods will blast: a bright rounded
## frame round a see-through fill, so they read as "danger" on any ground.
func _build_blast_zone() -> void:
	var quad := PlaneMesh.new()
	quad.size = Vector2(0.94, 0.94)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.albedo_texture = _blast_texture()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	m.no_depth_test = false
	quad.material = m
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = quad
	mm.instance_count = W * H
	mm.visible_instance_count = 0
	_blast_mm = MultiMeshInstance3D.new()
	_blast_mm.multimesh = mm
	_blast_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_blast_mm)


static var _blast_tex: ImageTexture


## A white rounded square: solid frame, half see-through middle. Tinted red
## per tile; made once per run.
static func _blast_texture() -> ImageTexture:
	if _blast_tex != null:
		return _blast_tex
	var n: int = 64
	var half: float = n * 0.5
	var r: float = 12.0
	var frame: float = 7.0
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var q := Vector2(absf(x + 0.5 - half), absf(y + 0.5 - half)) - Vector2(half - 1.0 - r, half - 1.0 - r)
			var d: float = Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0) - r
			var a: float = lerpf(0.55, 1.0, clampf(d + frame + 0.5, 0.0, 1.0)) * clampf(-d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, a))
	img.generate_mipmaps()
	_blast_tex = ImageTexture.create_from_image(img)
	return _blast_tex


## Lights the tiles each ticking pod will blast, redder as its fuse runs out.
func _update_blast_zone() -> void:
	if _blast_mm == null:
		return
	var mm: MultiMesh = _blast_mm.multimesh
	if pods.is_empty():
		mm.visible_instance_count = 0
		return
	var heat: Dictionary = {}
	for p: Pod in pods:
		var cells: Dictionary = {}
		_add_blast_cells(p.cell, p.fire, cells)
		var hurry: float = clampf(1.0 - p.timer / fuse, 0.0, 1.0)
		for c: Vector2i in cells:
			heat[c] = maxf(float(heat.get(c, 0.0)), hurry)
	var i: int = 0
	var pulse: float = 0.5 + 0.5 * sin(_clock * 9.0)
	for c: Vector2i in heat:
		var h: float = heat[c]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(c.x, 0.03, c.y)))
		mm.set_instance_color(i, Color(1.0, 0.1, 0.08, minf(0.66 + h * 0.26 + h * pulse * 0.16, 1.0)))
		i += 1
	mm.visible_instance_count = i


func _update_hero(delta: float) -> void:
	if demo or hero == null:
		return
	if state == &"dying":
		_dying_t += delta
		var body: Node3D = hero.get_node("Body")
		body.rotation.y += delta * 14.0
		body.position.y = sin(minf(_dying_t / 0.9, 1.0) * PI) * 0.9
		body.scale = Vector3.ONE * maxf(1.0 - maxf(_dying_t - 0.6, 0.0) * 2.0, 0.01)
		if _dying_t > 1.5:
			if lives > 0:
				_respawn()
			else:
				_lose("Out of lives!")
		return
	if state == &"won":
		_won_t += delta
		var b: Node3D = hero.get_node("Body")
		b.position.y = absf(sin(_won_t * 7.0)) * 0.35
		b.rotation.y += delta * 6.0
		return
	if state != &"play":
		return
	hero_invuln = maxf(hero_invuln - delta, 0.0)
	# Pods the hero stood on when they were dropped stay passable until it
	# steps off them.
	var still: Array[Pod] = []
	for p: Pod in hero_pass:
		if pods.has(p) and absf(p.pos.x - hero_pos.x) < 0.95 and absf(p.pos.y - hero_pos.y) < 0.95:
			still.append(p)
	hero_pass = still
	var moved_dir := Vector2i.ZERO
	var want: Vector2i = input_primary
	var want2: Vector2i = input_secondary
	if want == Vector2i.ZERO and walk_goal == NO_CELL and not demo and _hero_danger().has(hero_cell()):
		# Standing where a blast will reach (say on a pod he just dropped):
		# Pip steps to the nearest safe tile on his own.
		var spot: Vector2i = _safe_spot()
		if spot != NO_CELL and spot != hero_cell():
			walk_goal = spot
			_marker_t = 0.0
	elif want == Vector2i.ZERO and walk_goal == NO_CELL and not demo and hero_invuln <= 0.0 and _threatened():
		# A critter coming at him while he stands still: Pip sidesteps.
		var away: Vector2i = _escape_spot()
		if away != NO_CELL and away != hero_cell():
			walk_goal = away
			_marker_t = 0.0
	if want == Vector2i.ZERO and walk_goal != NO_CELL:
		var settle: Vector2i = _settle_cell()
		if settle != NO_CELL:
			# On the goal (or a warp pad): ease onto the middle of the tile.
			moved_dir = _ease_to(Vector2(settle), delta)
			if moved_dir == Vector2i.ZERO and settle == walk_goal:
				walk_goal = NO_CELL
		else:
			want = _walk_step()
			if want == Vector2i.ZERO and _may_center():
				# Waiting (for a blast to pass, say): finish the step onto the
				# middle of the tile rather than stand astride two.
				moved_dir = _ease_to(Vector2(hero_cell()), delta)
	if want != Vector2i.ZERO:
		var dist: float = speed * delta * kit.hero_speed_scale(hero_cell())
		if _try_move(want, dist):
			moved_dir = want
		elif want2 != Vector2i.ZERO and _try_move(want2, dist):
			moved_dir = want2
	hero_moving = moved_dir != Vector2i.ZERO
	if moved_dir != Vector2i.ZERO:
		hero_yaw = atan2(float(moved_dir.x), float(moved_dir.y))
	elif want != Vector2i.ZERO:
		hero_yaw = atan2(float(want.x), float(want.y))
	var c: Vector2i = hero_cell()
	if c != _kit_cell:
		_kit_cell = c
		kit.on_hero_enter(c)
		if state != &"play":
			return
		c = hero_cell()
	if belts.has(c):
		hero_pos = _move_axis(hero_pos, belts[c], BELT_SPEED * delta, _hero_blocked)
		c = hero_cell()
	# Warps.
	if warps.has(c):
		if not hero_warped and hero_pos.distance_to(Vector2(c)) < 0.25:
			_spawn_sparkles(_to3(Vector2(c), 0.3), Color("#C9B8FF"))
			hero_pos = Vector2(warps[c])
			hero_warped = true
			if walk_goal == c or walk_goal == warps[c]:
				walk_goal = NO_CELL
			_spawn_sparkles(_to3(hero_pos, 0.3), Color("#C9B8FF"))
			Sfx.play(&"teleport")
			c = hero_cell()
	else:
		hero_warped = false
	if pickups.has(c):
		_collect(c)
	if flames.has(c):
		_hurt_hero()
	if exit_open and c == exit_cell and hero_pos.distance_to(Vector2(c)) < 0.4:
		_win()
	_pose_hero(delta)


func _pose_hero(delta: float) -> void:
	hero.position = _to3(hero_pos)
	hero.rotation.y = lerp_angle(hero.rotation.y, hero_yaw, minf(delta * 14.0, 1.0))
	var body: Node3D = hero.get_node("Body")
	if _refuse_t > 0.0:
		# A quick head shake: "no way out of that one".
		_refuse_t = maxf(_refuse_t - delta, 0.0)
		body.rotation.y = sin(_refuse_t * 50.0) * 0.45 * (_refuse_t / 0.35)
	var foot_l: Node3D = body.get_node("FootL")
	var foot_r: Node3D = body.get_node("FootR")
	if hero_moving:
		_walk_phase += delta * speed * 4.2
		body.position.y = absf(sin(_walk_phase)) * 0.07
		body.rotation.z = sin(_walk_phase) * 0.09
		body.rotation.x = 0.1
		foot_l.position.z = 0.05 + sin(_walk_phase) * 0.1
		foot_r.position.z = 0.05 - sin(_walk_phase) * 0.1
	else:
		body.position.y = lerpf(body.position.y, 0.0, minf(delta * 12.0, 1.0))
		body.rotation.z = lerpf(body.rotation.z, 0.0, minf(delta * 10.0, 1.0))
		body.rotation.x = lerpf(body.rotation.x, 0.0, minf(delta * 10.0, 1.0))
		foot_l.position.z = 0.05
		foot_r.position.z = 0.05
	body.scale = body.scale.lerp(Vector3(1.0, 1.0 + sin(_clock * 3.0) * 0.025, 1.0), minf(delta * 10.0, 1.0))
	hero.visible = hero_invuln <= 0.0 or fmod(_clock, 0.16) < 0.1
	_shield_node.visible = shield
	if shield:
		_shield_node.scale = Vector3.ONE * (1.0 + sin(_clock * 5.0) * 0.04)


## Moves Pip straight toward [param to] (a point inside his tile) at walking
## speed; the direction he went, or zero once he is there.
func _ease_to(to: Vector2, delta: float) -> Vector2i:
	var before: Vector2 = hero_pos
	hero_pos = hero_pos.move_toward(to, speed * delta * kit.hero_speed_scale(hero_cell()))
	var step: Vector2 = hero_pos - before
	if step.length_squared() <= 1e-8:
		return Vector2i.ZERO
	return Vector2i(roundi(signf(step.x)), 0) if absf(step.x) > absf(step.y) else Vector2i(0, roundi(signf(step.y)))


## Whether Pip may step onto the middle of his tile while he waits: not on a
## belt (it carries him) and not toward a critter almost in reach of it.
func _may_center() -> bool:
	if belts.has(hero_cell()):
		return false
	var mid := Vector2(hero_cell())
	for cr: Critter in critters:
		if kit.critter_hidden(cr):
			continue
		var near: float = (BOSS_REACH if cr.kind == &"boss" else CRITTER_REACH) + 0.45
		var d_mid: float = cr.pos.distance_to(mid)
		if d_mid < near and d_mid < cr.pos.distance_to(hero_pos):
			return false
	return true


## The tile Pip should ease onto directly instead of walking a path: his
## goal once he stands on it, or a warp pad he has stepped on. NO_CELL when
## he still has walking to do.
func _settle_cell() -> Vector2i:
	var c: Vector2i = hero_cell()
	if warps.has(c) and not hero_warped:
		return c
	if c == walk_goal:
		return c
	return NO_CELL


## The direction of Pip's next step toward [member walk_goal]: around
## blocks, pods and live flames, through warps. Zero means wait (the way is
## shut for now, say by a flame).
func _walk_step() -> Vector2i:
	var danger: Dictionary = _hero_danger()
	var crit: Dictionary = _critter_cells()
	var key: Array = [hero_cell(), walk_goal, can_kick, flames.size(), pod_at.keys(), hero_pass.size(), crit.keys(), danger.size()]
	_walk_age += get_process_delta_time()
	if key == _walk_key and _walk_age < WALK_REFRESH:
		return _walk_dir
	_walk_key = key
	_walk_age = 0.0
	_walk_dir = _plan_step(danger, crit)
	return _walk_dir


## Pip's next step toward [member walk_goal], thinking ahead: a way round
## critters and blast lines first, then one round blast lines only. With no
## safe way he gets as close as is safe and waits there for the blast; when
## he already stands in a blast line he gets out of it first.
func _plan_step(danger: Dictionary, crit: Dictionary) -> Vector2i:
	var here: Vector2i = hero_cell()
	# The search round blast lines only, without kicking: when it cannot
	# reach the goal it has covered every safe tile, so it is kept for the
	# fallback below instead of searching again.
	var safe_r: Dictionary = {}
	if not danger.has(walk_goal):
		var both: Dictionary = danger.merged(crit)
		var passes: Array = [[both, false], [both, true], [danger, false], [danger, true]]
		for i in passes.size():
			var kick: bool = passes[i][1]
			if (kick and not can_kick) or (i < 2 and crit.is_empty()):
				continue
			var r: Dictionary = _hero_search(true, kick, walk_goal, passes[i][0])
			if i == 2:
				safe_r = r
			var first: Dictionary = r["first"]
			if not first.has(walk_goal):
				continue
			var step: Vector2i = first[walk_goal]
			# A critter in the way: back off rather than walk into it.
			if crit.has(here + step) and not danger.has(here):
				var away: Vector2i = _escape_spot()
				if away != NO_CELL and away != here:
					return _hero_search(true, false, away)["first"].get(away, Vector2i.ZERO)
				return Vector2i.ZERO
			return step
	# No safe way to the goal: the safe tile closest to it instead.
	if safe_r.is_empty():
		safe_r = _hero_search(true, false, NO_CELL, danger)
	var first2: Dictionary = safe_r["first"]
	var dist: Dictionary = safe_r["dist"]
	var best: Vector2i = NO_CELL
	var best_score: int = 1 << 30
	for c: Vector2i in dist:
		if danger.has(c):
			continue
		var score: int = (absi(c.x - walk_goal.x) + absi(c.y - walk_goal.y)) * 1000 + int(dist[c])
		if score < best_score:
			best_score = score
			best = c
	if best != NO_CELL:
		return Vector2i.ZERO if best == here else first2[best]
	if danger.has(here):
		var spot: Vector2i = _safe_spot()
		if spot != NO_CELL and spot != here:
			return _hero_search(true, false, spot)["first"].get(spot, Vector2i.ZERO)
	# Nowhere safe either: walk on, the old way.
	var plain: Dictionary = _hero_search(true, false, walk_goal)["first"]
	if not plain.has(walk_goal) and can_kick:
		plain = _hero_search(true, true, walk_goal)["first"]
	return plain.get(walk_goal, Vector2i.ZERO)


## Whether a critter is close and coming toward Pip.
func _threatened() -> bool:
	for cr: Critter in critters:
		if kit.critter_hidden(cr):
			continue
		var d: float = cr.pos.distance_to(hero_pos)
		if d < 1.25 or (d < 2.2 and Vector2(cr.target).distance_to(hero_pos) < d - 0.1):
			return true
	return false


## A tile a few steps away, clear of blasts and critters' paths, as far from
## the critters as it can be; NO_CELL when there is none.
func _escape_spot() -> Vector2i:
	var avoid: Dictionary = _hero_danger().merged(_critter_cells())
	var dist: Dictionary = _hero_search(true, false, NO_CELL, avoid)["dist"]
	var best: Vector2i = NO_CELL
	var best_score: float = -1e9
	for c: Vector2i in dist:
		var steps: int = int(dist[c])
		if steps > 5:
			continue
		var gap: float = 99.0
		for cr: Critter in critters:
			if not kit.critter_hidden(cr):
				gap = minf(gap, cr.pos.distance_to(Vector2(c)))
		var score: float = minf(gap, 4.0) - steps * 0.2
		if score > best_score:
			best_score = score
			best = c
	return best


## The nearest tile no blast will reach that Pip can walk to now, keeping
## clear of critters when he can; NO_CELL when there is none.
func _safe_spot() -> Vector2i:
	var danger: Dictionary = _hero_danger()
	var crit: Dictionary = _critter_cells()
	for avoid: Dictionary in [crit, {}]:
		var dist: Dictionary = _hero_search(true, false, NO_CELL, avoid)["dist"]
		var best: Vector2i = NO_CELL
		var best_d: int = 1 << 30
		for c: Vector2i in dist:
			if danger.has(c) or crit.has(c):
				continue
			var d: int = int(dist[c])
			if d < best_d:
				best_d = d
				best = c
		if best != NO_CELL:
			return best
	return NO_CELL


## Every tile a flame is on or a pod's blast will reach, whatever its fuse
## (Pip plans ahead; critters only fear pods about to go, see _critter_danger).
func _hero_danger() -> Dictionary:
	var frame: int = Engine.get_process_frames()
	if frame == _hero_danger_frame:
		return _hero_danger_cache
	_hero_danger_frame = frame
	var out: Dictionary = {}
	for c: Vector2i in flames:
		out[c] = true
	for p: Pod in pods:
		_add_blast_cells(p.cell, p.fire, out)
	_hero_danger_cache = out
	return out


## Adds the tiles a blast at [param c] with reach [param reach] covers.
func _add_blast_cells(c: Vector2i, reach: int, out: Dictionary) -> void:
	out[c] = true
	for d: Vector2i in DIRS:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			if tile(cc) != FLOOR:
				break
			var own: int = kit.flame_stop(cc)
			if own == 2:
				break
			out[cc] = true
			if own == 1 or pod_at.has(cc):
				break


## The tiles critters stand on, are stepping onto and will step onto next.
func _critter_cells() -> Dictionary:
	var frame: int = Engine.get_process_frames()
	if frame == _crit_frame:
		return _crit_cache
	_crit_frame = frame
	var out: Dictionary = {}
	for cr: Critter in critters:
		if kit.critter_hidden(cr):
			continue
		out[cr.cell] = true
		out[cr.target] = true
		var ahead: Vector2i = cr.target + cr.dir
		if tile(ahead) == FLOOR:
			out[ahead] = true
	_crit_cache = out
	return out


## Breadth-first search from Pip's tile over the tiles he can walk. Gives
## {"first": {tile: first step}, "dist": {tile: steps}}. Stepping on a warp
## lands on its partner. [param strict] also avoids live flames and pods
## (unless [param through_pods], for kicking them out of the way). With a
## [param goal], stops as soon as that tile is reached. Tiles in
## [param avoid] are never stepped on.
func _hero_search(strict: bool, through_pods: bool, goal: Vector2i = NO_CELL, avoid: Dictionary = {}) -> Dictionary:
	var start: Vector2i = hero_cell()
	var first: Dictionary = {start: Vector2i.ZERO}
	var dist: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	var head: int = 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if first.has(n) or avoid.has(n) or not _hero_can_walk(n, strict, through_pods):
				continue
			var step: Vector2i = d if c == start else first[c]
			first[n] = step
			dist[n] = int(dist[c]) + 1
			if warps.has(n):
				var w: Vector2i = warps[n]
				if not first.has(w):
					first[w] = step
					dist[w] = int(dist[c]) + 2
					queue.append(w)
			else:
				queue.append(n)
			if goal != NO_CELL and first.has(goal):
				return {"first": first, "dist": dist}
	return {"first": first, "dist": dist}


func _hero_can_walk(c: Vector2i, strict: bool, through_pods: bool) -> bool:
	if tile(c) != FLOOR or kit.blocks(c):
		return false
	if strict:
		if flames.has(c):
			return false
		if not through_pods and pod_at.has(c) and not hero_pass.has(pod_at[c]):
			return false
	return true


func _hero_blocked(c: Vector2i) -> bool:
	if tile(c) != FLOOR or kit.blocks(c):
		return true
	if pod_at.has(c) and not hero_pass.has(pod_at[c]):
		return true
	return false


func _try_move(dir: Vector2i, dist: float) -> bool:
	var before: Vector2 = hero_pos
	hero_pos = _move_axis(hero_pos, dir, dist, _hero_blocked)
	if can_kick:
		var ahead: Vector2i = hero_cell() + dir
		if pod_at.has(ahead):
			var p: Pod = pod_at[ahead]
			if not hero_pass.has(p) and p.slide == Vector2i.ZERO and not _pod_blocked(ahead + dir):
				p.slide = dir
				p.slide_speed = KICK_SPEED
				p.kicked = true
				Sfx.play(&"kick")
	return hero_pos.distance_squared_to(before) > 1e-8


## Moves [param pos] up to [param dist] cells along [param dir] through the
## grid's corridors: it lines up with the corridor first, stops at the
## middle of the last open cell and slips round corners it nearly fits.
func _move_axis(pos: Vector2, dir: Vector2i, dist: float, blocked: Callable) -> Vector2:
	var a: int = 0 if dir.x != 0 else 1
	var b: int = 1 - a
	var s: float = float(dir[a])
	var cell := Vector2i(roundi(pos.x), roundi(pos.y))
	var ahead: Vector2i = cell + dir
	var off: float = pos[b] - float(cell[b])
	if not blocked.call(ahead):
		if absf(off) > 0.0005:
			var m: float = minf(dist, absf(off))
			pos[b] -= signf(off) * m
			dist -= m
		if dist > 0.0:
			var np: float = pos[a] + s * dist
			if blocked.call(ahead + dir):
				var limit: float = float(ahead[a])
				np = minf(np, limit) if s > 0.0 else maxf(np, limit)
			pos[a] = np
	else:
		var to_center: float = float(cell[a]) - pos[a]
		if to_center * s > 0.0005:
			pos[a] += s * minf(dist, absf(to_center))
		elif absf(off) > 0.15:
			var side := Vector2i.ZERO
			side[b] = int(signf(off))
			if not blocked.call(cell + side) and not blocked.call(cell + side + dir):
				pos[b] += signf(off) * minf(dist, 0.52 - absf(off))
	return pos


func _respawn() -> void:
	hero_pos = Vector2(start_cell)
	hero_alive = true
	hero_invuln = RESPAWN_GRACE
	hero_pass.clear()
	walk_goal = NO_CELL
	state = &"play"
	var body: Node3D = hero.get_node("Body")
	body.rotation = Vector3.ZERO
	body.position = Vector3.ZERO
	body.scale = Vector3.ONE
	_spawn_sparkles(_to3(hero_pos, 0.4), Color("#FFFFFF"))
	Sfx.play(&"whoosh")


## Brings Pip back with one life after "Out of lives!" (the rewarded ad).
func revive() -> void:
	if state != &"lost" or hero_alive:
		return
	lives = 1
	_respawn()


func _hurt_hero() -> void:
	if state != &"play" or not hero_alive or hero_invuln > 0.0 or demo:
		return
	if shield:
		shield = false
		hero_invuln = 1.6
		Sfx.play(&"snap")
		Save.buzz(40)
		_spawn_sparkles(_to3(hero_pos, 0.5), Color("#BFDFFF"))
		return
	hero_alive = false
	lives -= 1
	deaths += 1
	state = &"dying"
	_dying_t = 0.0
	_shake = maxf(_shake, 0.25)
	Sfx.play(&"hurt", 0.0)
	Save.buzz(120)


func _win() -> void:
	state = &"won"
	_won_t = 0.0
	Sfx.play(&"win", 0.0)
	_spawn_confetti(_to3(hero_pos, 0.8))
	var stars: int = stars_for_time(elapsed)
	get_tree().create_timer(1.4, false).timeout.connect(func() -> void: won.emit(stars, elapsed))


func _lose(reason: String) -> void:
	if state == &"lost" or state == &"won":
		return
	state = &"lost"
	Sfx.play(&"fail", 0.0)
	get_tree().create_timer(0.6, false).timeout.connect(func() -> void: lost.emit(reason))


# --- Fizz pods and blasts ------------------------------------------------------

## Drops a pod on Pip's tile, or on [param at] when he is still touching it
## (a double tap's first tap may have nudged him off it).
func drop_pod(at: Vector2i = NO_CELL) -> void:
	if demo or state != &"play" or not hero_alive:
		return
	var c: Vector2i = hero_cell()
	if at != NO_CELL and absf(hero_pos.x - at.x) < 0.95 and absf(hero_pos.y - at.y) < 0.95:
		c = at
	if pods_out >= max_pods or pod_at.has(c) or tile(c) != FLOOR or warps.has(c):
		return
	if not shield and hero_invuln < fuse and not _can_escape(c):
		# No way out of this blast in time: Pip shakes his head instead.
		_refuse_t = 0.35
		Sfx.play(&"fail", 0.0)
		Save.buzz(25)
		return
	var p := Pod.new()
	p.timer = fuse
	p.cell = c
	p.pos = Vector2(c)
	p.fire = fire
	p.node = Models.pod()
	p.node.position = _to3(p.pos)
	add_child(p.node)
	pods.append(p)
	pod_at[c] = p
	pods_out += 1
	hero_pass.append(p)
	Sfx.play(&"place")
	Save.buzz(15)
	var body: Node3D = hero.get_node("Body")
	body.scale = Vector3(1.25, 0.75, 1.25)


## Whether Pip could still reach a tile no blast reaches, in time, after
## dropping a pod at [param c].
func _can_escape(c: Vector2i) -> bool:
	var danger: Dictionary = _hero_danger().duplicate()
	_add_blast_cells(c, fire, danger)
	var dist: Dictionary = _hero_search(true, false)["dist"]
	var steps_in_time: float = (fuse - 0.35) * speed
	for t: Vector2i in dist:
		if t != c and not danger.has(t) and float(dist[t]) <= steps_in_time:
			return true
	return false


func _pod_blocked(c: Vector2i) -> bool:
	if tile(c) != FLOOR or pod_at.has(c) or kit.blocks(c):
		return true
	if not demo and hero_alive and hero_cell() == c:
		return true
	for cr: Critter in critters:
		if Vector2i(roundi(cr.pos.x), roundi(cr.pos.y)) == c:
			return true
	return false


func _update_pods(delta: float) -> void:
	for p: Pod in pods.duplicate():
		p.timer -= delta
		p.age += delta
		# Belts carry pods that are standing still.
		if p.slide == Vector2i.ZERO and belts.has(p.cell) and not _pod_blocked(p.cell + belts[p.cell]):
			p.slide = belts[p.cell]
			p.slide_speed = BELT_SPEED
			p.kicked = false
		if p.slide != Vector2i.ZERO:
			var nxt: Vector2i = p.cell + p.slide
			p.pos += Vector2(p.slide) * p.slide_speed * delta
			if (p.pos - Vector2(nxt)).dot(Vector2(p.slide)) >= 0.0:
				if pod_at.get(p.cell) == p:
					pod_at.erase(p.cell)
				p.cell = nxt
				pod_at[nxt] = p
				var keep := Vector2i.ZERO
				if p.kicked:
					keep = p.slide
				elif belts.has(nxt):
					keep = belts[nxt]
				if belts.has(nxt) and p.kicked and _pod_blocked(nxt + p.slide):
					keep = belts[nxt]
					p.kicked = false
					p.slide_speed = BELT_SPEED
				if keep == Vector2i.ZERO or _pod_blocked(nxt + keep):
					p.pos = Vector2(nxt)
					p.slide = Vector2i.ZERO
					p.kicked = false
				else:
					p.slide = keep
		p.node.position = _to3(p.pos)
		var body: Node3D = p.node.get_node("Body")
		var hurry: float = clampf(1.0 - p.timer / fuse, 0.0, 1.0)
		var pulse: float = 1.0 + sin(p.age * (6.0 + hurry * 18.0)) * (0.04 + hurry * 0.06)
		body.scale = body.scale.lerp(Vector3(pulse, 2.0 - pulse, pulse), minf(delta * 14.0, 1.0)) if p.age > 0.2 else Vector3.ONE.lerp(Vector3(1.4, 0.5, 1.4), 1.0 - p.age / 0.2)
		var spark: MeshInstance3D = body.get_node("Spark")
		spark.scale = Vector3.ONE * (0.7 + randf() * 0.7)
		Models.heat_pod(p.node, hurry, p.age)
		if p.timer <= 0.0:
			_explode(p)


func _explode(p: Pod) -> void:
	if not pods.has(p):
		return
	pods.erase(p)
	if pod_at.get(p.cell) == p:
		pod_at.erase(p.cell)
	pods_out = maxi(pods_out - 1, 0)
	hero_pass.erase(p)
	p.node.queue_free()
	_blast(p.cell, p.fire)
	kit.on_explode(p.cell)
	_spawn_ring(Vector3(p.cell.x, 0.06, p.cell.y), Models.FLAME_CORE, 1.0 + p.fire * 0.4)
	_spawn_scorch(Vector3(p.cell.x, 0.012, p.cell.y))
	Sfx.play(&"boom", 0.1)
	_shake = maxf(_shake, 0.3)
	_hitstop(0.05)
	if not demo and hero_alive and hero_pos.distance_to(Vector2(p.cell)) < 4.0:
		Save.buzz(40)


## Freezes the action for a blink so a hit lands with weight.
func _hitstop(seconds: float) -> void:
	if demo or Engine.time_scale < 1.0:
		return
	Engine.time_scale = 0.05
	get_tree().create_timer(seconds, true, false, true).timeout.connect(func() -> void: Engine.time_scale = 1.0)


func _exit_tree() -> void:
	Engine.time_scale = 1.0


func _blast(c: Vector2i, reach: int) -> void:
	_add_flame(c, 0, Vector2i.ZERO)
	for d: Vector2i in DIRS:
		for i in range(1, reach + 1):
			var cc: Vector2i = c + d * i
			var t: int = tile(cc)
			if t == WALL:
				break
			var own: int = kit.flame_stop(cc)
			if own == 2:
				break
			if own == 1:
				_add_flame(cc, i, d)
				break
			if t == CRATE:
				_add_flame(cc, i, d)
				_break_crate(cc)
				break
			if t == BARREL:
				_add_flame(cc, i, d)
				_ignite_barrel(cc)
				break
			_add_flame(cc, i, d)
			if pod_at.has(cc):
				var other: Pod = pod_at[cc]
				other.timer = minf(other.timer, 0.06)
				break


func _add_flame(c: Vector2i, dist: int, dir: Vector2i) -> void:
	flames[c] = FLAME_TIME
	kit.on_flame(c)
	# A cluster of tumbling fire cubes round a white-hot core cube. Arms lay
	# their cubes along the blast line so the beam reads as solid.
	var arm: bool = dir != Vector2i.ZERO
	var node: Node3D = _flame_node(arm)
	node.position = Vector3(c.x, 0.34, c.y)
	node.rotation = Vector3(0.0, atan2(-float(dir.y), float(dir.x)) if arm else 0.0, 0.0)
	var spots: Array[Vector3] = []
	if arm:
		spots = [Vector3(-0.3, 0.0, rng.randf_range(-0.08, 0.08)), Vector3(0.0, 0.06, rng.randf_range(-0.08, 0.08)), Vector3(0.3, 0.0, rng.randf_range(-0.08, 0.08))]
	else:
		spots = [Vector3(0.2, 0.0, 0.2), Vector3(-0.2, 0.05, 0.2), Vector3(0.2, 0.05, -0.2), Vector3(-0.2, 0.0, -0.2)]
	var cubes: Array[Node3D] = []
	var spins: Array[Vector3] = []
	for i in node.get_child_count():
		var cube := node.get_child(i) as Node3D
		cubes.append(cube)
		if i < spots.size():
			cube.position = spots[i]
			cube.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
			cube.scale = Vector3.ONE * rng.randf_range(0.95, 1.2)
			spins.append(Vector3(rng.randf_range(-5, 5), rng.randf_range(-5, 5), rng.randf_range(-5, 5)))
		else:
			cube.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)
			cube.scale = Vector3.ONE * (0.8 if arm else 1.05)
			spins.append(Vector3(0, rng.randf_range(-7, 7), 0))
	node.scale = Vector3.ONE * 0.01
	node.visible = true
	_fx.append({"node": node, "t": -dist * 0.022, "life": FLAME_TIME, "kind": &"flame",
		"arm": arm, "cubes": cubes, "spins": spins})


## A flame cluster: from the pool when one is free, else built (fire cubes
## then the core: 3 cubes for an arm, 4 for the middle).
func _flame_node(arm: bool) -> Node3D:
	var spare: Array = _flame_pool[arm]
	if not spare.is_empty():
		var used: Node3D = spare.pop_back()
		# Back to plain fire colours (a world may have dyed it).
		var last: int = used.get_child_count() - 1
		for i in used.get_child_count():
			(used.get_child(i) as MeshInstance3D).material_override = \
				Models.mat(Models.FLAME_CORE, 1.8) if i == last else Models.mat(Models.FLAME, 1.1)
		return used
	var node := Node3D.new()
	add_child(node)
	for i in (3 if arm else 4):
		var cube := Models.part(node, _flame_mesh, Models.FLAME, Vector3.ZERO, 1.1)
		cube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var core := Models.part(node, _flame_mesh, Models.FLAME_CORE, Vector3(0, 0.08, 0), 1.8)
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


## A one-piece effect (a spark, chip, puff...) to list in [member _fx] with
## "pool": true, so it is reused once done. Taken from the pool when it can.
func fx_part(mesh: Mesh, color: Color, pos: Vector3, glow: float = 0.0, shadow: bool = false) -> MeshInstance3D:
	var n: MeshInstance3D
	if _fx_pool.is_empty():
		n = Models.part(self, mesh, color, pos, glow)
	else:
		n = _fx_pool.pop_back()
		n.mesh = mesh
		n.material_override = Models.mat(color, glow)
		n.position = pos
		n.rotation = Vector3.ZERO
		n.scale = Vector3.ONE
		n.visible = true
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return n


## Puts a finished effect's node away for reuse, or frees it.
func _fx_done(f: Dictionary, n: Node3D) -> void:
	if f.get("pool", false) and _fx_pool.size() < FX_POOL_MAX:
		n.visible = false
		_fx_pool.append(n)
	elif f["kind"] == &"flame" and f.has("arm") and (_flame_pool[f["arm"]] as Array).size() < 40:
		n.visible = false
		(_flame_pool[f["arm"]] as Array).append(n)
	else:
		n.queue_free()


func _update_flames(delta: float) -> void:
	for c: Vector2i in flames.keys():
		flames[c] -= delta
		if flames[c] <= 0.0:
			flames.erase(c)


func _break_crate(c: Vector2i) -> void:
	_set_tile(c, FLOOR)
	if crate_slot.has(c):
		var i: int = crate_slot[c]
		var hidden := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(c.x, -5, c.y))
		_crates_mm.set_instance_transform(i, hidden)
		_bands_mm.set_instance_transform(i, hidden)
		crate_slot.erase(c)
	# The crate cracks apart: a quick white flash, planks and band bits that
	# fly out, bounce on the floor and lie there a moment, and a dust ring.
	var at := Vector3(c.x, 0.4, c.y)
	var flash := fx_part(_flash_mesh, Color.WHITE, at, 2.0)
	_fx.append({"node": flash, "t": 0.0, "life": 0.12, "kind": &"flash", "pool": true})
	var chunk: Mesh = _chunk_mesh
	for k in 12:
		var plank: bool = k < 8
		var color: Color = Models.WOOD if plank else Models.WOOD_DARK
		var n := fx_part(_plank_mesh if plank else chunk, color, at + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.2, 0.25), rng.randf_range(-0.2, 0.2)), 0.0, true)
		n.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		if Models.GLASS:
			n.material_override = Models.glass(color, 0.3 if plank else 0.7, 0.1)
		var a: float = TAU * k / 12.0 + rng.randf_range(-0.3, 0.3)
		var out: float = rng.randf_range(2.2, 4.2)
		_fx.append({"node": n, "t": 0.0, "life": rng.randf_range(1.0, 1.3), "kind": &"debris", "floor": 0.06, "pool": true,
			"vel": Vector3(cos(a) * out, rng.randf_range(3.5, 6.0), sin(a) * out),
			"spin": Vector3(rng.randf_range(-14, 14), rng.randf_range(-14, 14), rng.randf_range(-14, 14))})
	for k in 6:
		var a2: float = TAU * k / 6.0 + rng.randf() * 0.5
		var d := fx_part(_smoke_mesh, Models.WOOD.lerp(Color("#F4ECE4"), 0.6), Vector3(c.x + cos(a2) * 0.25, 0.15, c.y + sin(a2) * 0.25))
		d.rotation.y = rng.randf() * TAU
		_fx.append({"node": d, "t": 0.0, "life": 0.55, "kind": &"dust", "pool": true, "vel": Vector3(cos(a2) * 1.8, 0.5, sin(a2) * 1.8)})
	Sfx.play(&"crunch", 0.12)
	_shake = maxf(_shake, 0.22)
	if not demo:
		Save.buzz(18)
	if drops.has(c):
		var kind: StringName = drops[c]
		drops.erase(c)
		get_tree().create_timer(0.3, false).timeout.connect(_spawn_pickup.bind(c, kind))


func _ignite_barrel(c: Vector2i) -> void:
	if not barrels.has(c):
		return
	var node: Node3D = barrels[c]
	barrels.erase(c)
	node.scale = Vector3(1.15, 0.9, 1.15)
	get_tree().create_timer(0.16, false).timeout.connect(_burst_barrel.bind(c, node))


func _burst_barrel(c: Vector2i, node: Node3D) -> void:
	node.queue_free()
	_set_tile(c, FLOOR)
	_blast(c, BARREL_FIRE)
	Sfx.play(&"boom", 0.15)
	_shake = maxf(_shake, 0.28)


## Live flames and the blast lines of pods in their last moments
## (critter_notice), for spots with no particular critter in mind. A critter
## picking its next step uses _critter_danger instead, which also limits how
## far it sees and has it miss pods now and then.
func _danger_cells() -> Dictionary:
	var frame: int = Engine.get_process_frames()
	if frame == _danger_frame:
		return _danger
	_danger_frame = frame
	_danger = flames.duplicate()
	for p: Pod in pods:
		if p.timer > critter_notice:
			continue
		_danger[p.cell] = true
		for d: Vector2i in DIRS:
			for i in range(1, p.fire + 1):
				var cc: Vector2i = p.cell + d * i
				if tile(cc) != FLOOR:
					break
				var own: int = kit.flame_stop(cc)
				if own == 2:
					break
				_danger[cc] = true
				if own == 1:
					break
	return _danger


# --- Power-ups ----------------------------------------------------------------

func _spawn_pickup(c: Vector2i, kind: StringName) -> void:
	if pickups.has(c) or not is_inside_tree():
		return
	var node := Models.powerup(kind)
	node.position = Vector3(c.x, 0, c.y)
	add_child(node)
	pickups[c] = {"kind": kind, "node": node, "t": 0.0}


func _update_pickups(delta: float) -> void:
	for c: Vector2i in pickups:
		var pk: Dictionary = pickups[c]
		pk["t"] += delta
		var body: Node3D = pk["node"].get_node("Body")
		var grow: float = minf(pk["t"] / 0.3, 1.0)
		body.scale = Vector3.ONE * (grow * (1.0 + sin(grow * PI) * 0.3))
		body.position.y = 0.38 + sin(_clock * 3.0 + c.x) * 0.06
		body.rotation.y = sin(_clock * 1.6 + c.y) * 0.6


func _collect(c: Vector2i) -> void:
	var pk: Dictionary = pickups[c]
	pickups.erase(c)
	match pk["kind"]:
		&"bomb":
			max_pods = mini(max_pods + 1, 8)
		&"fire":
			fire = mini(fire + 1, 8)
		&"speed":
			speed = minf(speed + SPEED_STEP, MAX_SPEED)
		&"kick":
			can_kick = true
		&"shield":
			shield = true
		&"heart":
			lives = mini(lives + 1, 6)
		&"party":
			max_pods = maxi(max_pods, PARTY_PODS)
	(pk["node"] as Node3D).queue_free()
	_spawn_sparkles(Vector3(c.x, 0.5, c.y), Color("#FFF3B0"))
	Sfx.play(&"pickup", 0.0)
	Save.buzz(20)
	powered_up.emit(pk["kind"])


# --- Critters -----------------------------------------------------------------

func _critter_can_enter(cr: Critter, c: Vector2i) -> bool:
	var t: int = tile(c)
	if t == WALL or t == BARREL:
		return false
	if t == CRATE and cr.kind != &"wisp":
		return false
	if pod_at.has(c):
		return false
	return kit.critter_can_enter(cr, c)


func _update_critters(delta: float) -> void:
	for cr: Critter in critters.duplicate():
		if not critters.has(cr):
			continue
		cr.invuln = maxf(cr.invuln - delta, 0.0)
		if cr.t < 1.0:
			if not _critter_can_enter(cr, cr.target) and cr.t < 0.5:
				var back: Vector2i = cr.cell
				cr.cell = cr.target
				cr.target = back
				cr.t = 1.0 - cr.t
				cr.dir = -cr.dir
			cr.t += cr.speed * critter_pace * delta
			if cr.t >= 1.0:
				cr.t = 1.0
				cr.cell = cr.target
		# The stare ends when the pod goes off or Pip comes right up to the
		# critter (or something else moves, freezes or puts it to sleep).
		if cr.stare != null and (cr.t < 1.0 or not pods.has(cr.stare) or kit.critter_busy(cr) or _pip_beside(cr)):
			cr.stare = null
		if cr.t >= 1.0 and cr.stare == null and not _start_stare(cr):
			var nd: Vector2i = _choose_dir(cr)
			if nd != Vector2i.ZERO:
				cr.dir = nd
				cr.target = cr.cell + nd
				cr.t = 0.0
		cr.pos = Vector2(cr.cell).lerp(Vector2(cr.target), cr.t)
		var here := Vector2i(roundi(cr.pos.x), roundi(cr.pos.y))
		if cr.kind == &"boss":
			cr.think -= delta
			if cr.think <= 0.0:
				cr.think = 6.5 if cr.hp * 2 > boss_max_hp else 4.5
				_boss_summon(cr)
		var hidden: bool = kit.critter_hidden(cr)
		if flames.has(here) and cr.invuln <= 0.0 and not hidden:
			_hit_critter(cr)
			if not critters.has(cr):
				continue
		if not demo and hero_alive and state == &"play" and not hidden:
			var reach: float = BOSS_REACH if cr.kind == &"boss" else CRITTER_REACH
			if cr.pos.distance_to(hero_pos) < reach:
				_hurt_hero()
		_pose_critter(cr, delta)


func _choose_dir(cr: Critter) -> Vector2i:
	var open: Array = []
	for d: Vector2i in DIRS:
		if _critter_can_enter(cr, cr.cell + d):
			open.append(d)
	if open.is_empty():
		return Vector2i.ZERO
	var own: Vector2i = kit.critter_step(cr)
	if own != Vector2i.ZERO and open.has(own):
		return own
	var hc: Vector2i = hero_cell() if not demo else Vector2i(-99, -99)
	var smart: bool = cr.kind == &"buzzer" or cr.kind == &"boss" or kit.critter_smart(cr.kind)
	if smart:
		var danger: Dictionary = _critter_danger(cr)
		var safe: Array = open.filter(func(d: Vector2i) -> bool: return not danger.has(cr.cell + d))
		if not safe.is_empty():
			open = safe
		var chase_range: int = 99 if cr.kind == &"boss" else critter_chase
		if not demo and hero_alive and absi(hc.x - cr.cell.x) + absi(hc.y - cr.cell.y) <= chase_range:
			var step: Vector2i = _path_step(cr, hc)
			if step != Vector2i.ZERO and open.has(step):
				return step
	if open.has(cr.dir) and rng.randf() < 0.7:
		return cr.dir
	var turns: Array = open.filter(func(d: Vector2i) -> bool: return d != -cr.dir)
	if turns.is_empty():
		turns = open
	return turns[rng.randi() % turns.size()]


## The tiles a critter keeps off as it picks its next step: live flames, and
## the blast lines of ticking pods it has noticed. Critters are a little slow
## on the uptake: they notice a pod only in its last moments (critter_notice)
## and within critter_sight tiles, and now and then (critter_miss) not at all.
func _critter_danger(cr: Critter) -> Dictionary:
	var out: Dictionary = flames.duplicate()
	if pods.is_empty() or rng.randf() < critter_miss:
		return out
	for p: Pod in pods:
		if p.timer <= critter_notice and absi(p.cell.x - cr.cell.x) + absi(p.cell.y - cr.cell.y) <= critter_sight:
			_add_blast_cells(p.cell, p.fire, out)
	return out


## Called as a critter reaches a tile: the first time it spots a pod (within
## critter_sight) it may be dazed (chance critter_stare: about 3 in 10 in
## world 1, a little less each world). It turns to face the pod and
## stares at it until it goes off, neither chasing Pip nor getting out of
## the way, unless Pip comes right up to it. Bosses and busy critters
## (kit.critter_busy: asleep, frozen) never are. True when it has just
## started staring.
func _start_stare(cr: Critter) -> bool:
	if pods.is_empty() or demo or cr.kind == &"boss" or kit.critter_hidden(cr) or kit.critter_busy(cr) or _pip_beside(cr):
		return false
	var id: int = cr.get_instance_id()
	for p: Pod in pods:
		var gap: Vector2i = p.cell - cr.cell
		if p.seen.has(id) or gap == Vector2i.ZERO or absi(gap.x) + absi(gap.y) > critter_sight:
			continue
		p.seen[id] = true
		if rng.randf() >= critter_stare:
			continue
		cr.stare = p
		cr.dir = Vector2i(signi(gap.x), 0) if absi(gap.x) >= absi(gap.y) else Vector2i(0, signi(gap.y))
		cr.node.scale = Vector3(0.85, 1.3, 0.85)
		if cr.mark == null:
			# Freed with the critter, but placed by _pose_critter (top level)
			# so it stays above the critter on screen whichever way it faces.
			cr.mark = Label3D.new()
			cr.mark.top_level = true
			cr.mark.text = "?"
			cr.mark.font = Ui.font(900)
			cr.mark.font_size = 100
			cr.mark.pixel_size = 0.0065
			cr.mark.modulate = Color.WHITE
			cr.mark.outline_modulate = Color("#3B2A4A")
			cr.mark.outline_size = 24
			cr.mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			cr.mark.no_depth_test = true
			cr.node.add_child(cr.mark)
		cr.mark.visible = true
		return true
	return false


## True when Pip is right beside the critter (diagonals too): too close for
## it to stay dazed by a pod.
func _pip_beside(cr: Critter) -> bool:
	return hero_alive and cr.pos.distance_to(hero_pos) <= 1.5


## The first step of the shortest walk from the critter to [param goal], or
## zero when there is none within 40 cells.
func _path_step(cr: Critter, goal: Vector2i) -> Vector2i:
	var first: Dictionary = {cr.cell: Vector2i.ZERO}
	var queue: Array[Vector2i] = [cr.cell]
	var head: int = 0
	while head < queue.size() and head < 200:
		var c: Vector2i = queue[head]
		head += 1
		if c == goal:
			return first[c]
		for d: Vector2i in DIRS:
			var n: Vector2i = c + d
			if first.has(n) or not _critter_can_enter(cr, n):
				continue
			first[n] = d if c == cr.cell else first[c]
			queue.append(n)
	return Vector2i.ZERO


func _boss_summon(cr: Critter) -> void:
	var minions: int = critters.size() - 1
	if minions >= 3 or demo:
		return
	for d: Vector2i in DIRS:
		var c: Vector2i = cr.cell + d
		if _critter_can_enter(cr, c) and c != hero_cell() and not flames.has(c):
			var kind: StringName = kit.boss_minion_kind()
			var m: Critter = _spawn_critter(kind, c)
			m.node.scale = Vector3.ONE * 0.01
			_spawn_sparkles(Vector3(c.x, 0.4, c.y), Models.BLOBBIT.lightened(0.3) if kind == &"blobbit" else Color("#FFF3B0"))
			Sfx.play(&"pop")
			cr.node.get_node("Body").scale = Vector3(1.2, 0.8, 1.2)
			return


func _hit_critter(cr: Critter) -> void:
	if kit.critter_hit(cr):
		return
	if cr.kind == &"boss":
		cr.hp -= 1
		cr.invuln = 1.6
		Sfx.play(&"boss_hit", 0.0)
		Save.buzz(50)
		_shake = maxf(_shake, 0.3)
		cr.node.get_node("Body").scale = Vector3(1.35, 0.7, 1.35)
		if cr.hp > 0:
			cr.speed = 1.0 + (boss_max_hp - cr.hp) * 0.72 / boss_max_hp
			return
		boss = null
		for other: Critter in critters.duplicate():
			if other != cr:
				_kill_critter(other)
		_spawn_confetti(_to3(cr.pos, 1.0))
	_kill_critter(cr)


func _kill_critter(cr: Critter) -> void:
	critters.erase(cr)
	if cr.mark != null:
		cr.mark.visible = false
	_fx.append({"node": cr.node, "t": 0.0, "life": 0.45, "kind": &"pop", "big": cr.kind == &"boss"})
	_spawn_sparkles(_to3(cr.pos, 0.4), Models.BLOBBIT if cr.kind == &"blobbit" else Color("#FFF3B0"))
	Sfx.play(&"pop")
	if critters.is_empty() and not demo:
		_open_exit()


func _open_exit() -> void:
	if exit_open or _exit_node == null:
		return
	exit_open = true
	Sfx.play(&"gate", 0.0)
	var disc: MeshInstance3D = _exit_node.get_node("Disc")
	disc.material_override = Models.mat(Color("#7FE3C4"), 1.4)
	_spawn_sparkles(Vector3(exit_cell.x, 0.4, exit_cell.y), Color("#7FE3C4"))


func _pose_critter(cr: Critter, delta: float) -> void:
	var n: Node3D = cr.node
	n.position = _to3(cr.pos)
	var yaw: float = atan2(float(cr.dir.x), float(cr.dir.y))
	n.rotation.y = lerp_angle(n.rotation.y, yaw, minf(delta * 10.0, 1.0))
	var body: Node3D = n.get_node("Body")
	var t: float = _clock * 1.0 + cr.phase
	n.scale = n.scale.lerp(Vector3.ONE, minf(delta * 8.0, 1.0))
	if cr.mark != null:
		cr.mark.visible = cr.stare != null and not kit.critter_hidden(cr)
		if cr.mark.visible:
			cr.mark.global_position = to_global(_to3(cr.pos, 1.2 + sin(_clock * 7.0) * 0.05) + Vector3(0.0, 0.0, -0.45))
	var rest := Vector3.ONE
	var kind: StringName = &"" if cr.custom else cr.kind
	if cr.kind == &"boss":
		body.visible = cr.invuln <= 0.0 or fmod(_clock, 0.14) < 0.08
	match kind:
		&"blobbit":
			rest = Vector3(1.0 + sin(t * 9.0) * 0.07, 1.0 - sin(t * 9.0) * 0.1, 1.0 + sin(t * 9.0) * 0.07)
		&"buzzer":
			body.position.y = sin(t * 5.0) * 0.08
			body.get_node("WingL").rotation.z = sin(t * 40.0) * 0.6
			body.get_node("WingR").rotation.z = -sin(t * 40.0) * 0.6
		&"wisp":
			body.position.y = sin(t * 2.5) * 0.12
			body.rotation.z = sin(t * 1.7) * 0.15
		&"boss":
			rest = Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.06, 1.0)
		_:
			rest = kit.pose_critter(cr, body, t, delta)
	body.scale = body.scale.lerp(rest, minf(delta * 9.0, 1.0))


# --- Effects and camera -------------------------------------------------------

func _spawn_sparkles(at: Vector3, color: Color) -> void:
	for k in 10:
		var n := fx_part(_spark_mesh, color, at, 1.5)
		var a: float = TAU * k / 10.0
		_fx.append({"node": n, "t": 0.0, "life": 0.6, "kind": &"spark", "pool": true,
			"vel": Vector3(cos(a) * 2.2, rng.randf_range(1.5, 3.0), sin(a) * 2.2),
			"spin": Vector3(rng.randf_range(-10, 10), rng.randf_range(-10, 10), 0)})


func _spawn_confetti(at: Vector3) -> void:
	var colors: Array[Color] = [Color("#FF8FA3"), Color("#FFE27A"), Color("#7FE3C4"), Color("#9FC9E8"), Color("#F2A541")]
	var mesh := Models.box_mesh(Vector3(0.12, 0.03, 0.08), 0.01)
	for k in 36:
		var n := fx_part(mesh, colors[k % colors.size()], at, 0.4)
		var a: float = rng.randf() * TAU
		_fx.append({"node": n, "t": 0.0, "life": 1.6, "kind": &"debris", "pool": true,
			"vel": Vector3(cos(a) * rng.randf_range(1.0, 3.0), rng.randf_range(4.0, 7.0), sin(a) * rng.randf_range(1.0, 3.0)),
			"spin": Vector3(rng.randf_range(-12, 12), rng.randf_range(-12, 12), rng.randf_range(-12, 12)), "drag": true})


func _update_fx(delta: float) -> void:
	# Finished effects drop out in place (no new list each frame). Effects
	# added while this runs (smoke from a dying flame) are handled too.
	var w: int = 0
	var i: int = 0
	while i < _fx.size():
		var f: Dictionary = _fx[i]
		i += 1
		f["t"] += delta
		var t: float = f["t"]
		var n: Node3D = f["node"]
		if not is_instance_valid(n):
			continue
		if t >= f["life"]:
			if f["kind"] == &"flame":
				_spawn_smoke(n.position)
			_fx_done(f, n)
			continue
		_fx[w] = f
		w += 1
		match f["kind"]:
			&"flame":
				if t < 0.0:
					continue
				# Punch in past full size, snap back, flicker, then shrink away.
				var u: float = t / f["life"]
				var s: float
				if u < 0.1:
					s = lerpf(0.25, 1.35, u / 0.1)
				elif u < 0.22:
					s = lerpf(1.35, 1.0, (u - 0.1) / 0.12)
				elif u < 0.7:
					s = 1.0 + sin(t * 46.0) * 0.07
				else:
					s = lerpf(1.0, 0.0, (u - 0.7) / 0.3)
				n.scale = Vector3.ONE * maxf(s, 0.01)
				n.position.y = 0.34 + maxf(u - 0.6, 0.0) * 0.5
				var cubes: Array[Node3D] = f["cubes"]
				var spins: Array[Vector3] = f["spins"]
				for j in cubes.size():
					cubes[j].rotation += spins[j] * delta
			&"debris", &"spark":
				var v: Vector3 = f["vel"]
				v.y -= (11.0 if f["kind"] == &"debris" else 6.0) * delta
				if f.get("drag", false):
					v *= 1.0 - delta * 1.5
				n.position += v * delta
				if f.has("floor") and n.position.y < f["floor"] and v.y < 0.0:
					# Hit the floor: bounce low, skid and slow the spin.
					n.position.y = f["floor"]
					v = Vector3(v.x * 0.45, -v.y * 0.3 if -v.y > 1.2 else 0.0, v.z * 0.45)
					f["spin"] = (f["spin"] as Vector3) * 0.4
				f["vel"] = v
				if f.has("spin"):
					n.rotation += f["spin"] * delta
				var fade: float = clampf((f["life"] - t) / 0.25, 0.0, 1.0)
				n.scale = Vector3.ONE * fade
			&"smoke":
				n.position.y += delta * 0.9
				n.rotation.y += delta * 2.0
				var k: float = t / f["life"]
				n.scale = Vector3.ONE * (0.6 + k * 0.6) * (1.0 - k)
			&"dust":
				var dv: Vector3 = f["vel"]
				dv *= 1.0 - delta * 4.0
				f["vel"] = dv
				n.position += dv * delta
				n.rotation.y += delta * 3.0
				var kd: float = t / f["life"]
				n.scale = Vector3.ONE * (0.7 + kd * 0.8) * (1.0 - kd * kd)
			&"flash":
				var uf: float = t / f["life"]
				n.scale = Vector3.ONE * (1.0 + uf * 0.35) * (1.0 - uf)
			&"ring":
				var ur: float = t / f["life"]
				var grow: float = f["size"] * (1.0 - pow(1.0 - ur, 3.0))
				n.scale = Vector3(grow, 1.0 - ur * 0.8, grow)
			&"scorch":
				var us: float = clampf((t - f["life"] + 0.5) / 0.5, 0.0, 1.0)
				n.scale = Vector3(1.0 - us, 1.0, 1.0 - us) * f["size"]
			&"pop":
				var u2: float = t / f["life"]
				var big: float = 1.6 if f.get("big", false) else 1.0
				n.scale = Vector3(1.0 + u2 * 0.6, maxf(1.0 - u2 * 1.4, 0.01), 1.0 + u2 * 0.6) * big * (1.0 - u2 * 0.6)
	_fx.resize(w)


## A flat shockwave ring that races out from a blast.
func _spawn_ring(at: Vector3, color: Color, size: float) -> void:
	var n := fx_part(_ring_mesh, color, at, 1.6)
	n.scale = Vector3.ONE * 0.1
	_fx.append({"node": n, "t": 0.0, "life": 0.32, "kind": &"ring", "pool": true, "size": size * 2.0})


## A dark burn mark left on the floor, which shrinks away after a while.
func _spawn_scorch(at: Vector3) -> void:
	var n := fx_part(_scorch_mesh, Models.GRASS_A.darkened(0.35), at)
	n.rotation.y = rng.randf() * TAU
	var size: float = rng.randf_range(0.9, 1.1)
	n.scale = Vector3(size, 1.0, size)
	_fx.append({"node": n, "t": 0.0, "life": 1.8, "kind": &"scorch", "pool": true, "size": size})


func _spawn_smoke(at: Vector3) -> void:
	if _fx.size() > 260:
		return
	var n := fx_part(_smoke_mesh, Color("#F4ECE4"), at + Vector3(randf_range(-0.15, 0.15), 0.1, randf_range(-0.15, 0.15)))
	_fx.append({"node": n, "t": 0.0, "life": 0.7, "kind": &"smoke", "pool": true})


func _animate_scenery(delta: float) -> void:
	for cell: Node3D in _belt_nodes:
		for ch: Node in cell.get_children():
			if ch.has_meta(&"base"):
				var x: float = fposmod(float(ch.get_meta(&"base")) + 0.5 + _clock * BELT_SPEED * 0.5, 1.0) - 0.5
				(ch as Node3D).position.x = x
	for w: Node3D in _warp_nodes:
		(w.get_node("Orbit") as Node3D).rotation.y += delta * 2.5
	if _exit_node != null:
		var flag: Node3D = _exit_node.get_node("Flag")
		var top: float = 1.0 if exit_open else 0.4
		flag.position.y = lerpf(flag.position.y, top, minf(delta * 4.0, 1.0))
		flag.rotation.y = sin(_clock * 4.0) * 0.25
		if exit_open:
			(_exit_node.get_node("Disc") as Node3D).scale = Vector3.ONE * (1.0 + sin(_clock * 6.0) * 0.06)
	if _marker != null:
		_marker_t += delta
		var show: bool = state == &"play" and walk_goal != NO_CELL and walk_goal != hero_cell()
		_marker.visible = show
		if show:
			_marker.position = Vector3(walk_goal.x, 0.0, walk_goal.y)
			# Pops in on a new tap, then breathes.
			var pop: float = 1.0 + 0.5 * exp(-_marker_t * 9.0)
			_marker.scale = Vector3.ONE * pop * (1.0 + sin(_clock * 5.0) * 0.06)
			_marker.rotation.y += delta * 1.2


func _focus_target() -> Vector3:
	return Vector3((W - 1) * 0.5, 0, (H - 1) * 0.5)


## How far back the level camera sits so the whole arena, including its
## near (widest-looking) edge, fits the screen's width.
func _cam_distance() -> float:
	var fwd: Vector3 = -CAM_DIR.normalized()
	var near_edge: float = ((H - 1) * 0.5 + 0.6) * fwd.z   # negative: closer
	var half_tan: float = tan(deg_to_rad(CAM_FOV * 0.5))
	return (W + 0.4) / (2.0 * half_tan) - near_edge


func _update_camera(delta: float, snap: bool) -> void:
	if camera == null:
		return
	var target: Vector3 = _focus_target()
	_cam_focus = target if snap else _cam_focus.lerp(target, minf(delta * 3.0, 1.0))
	if demo:
		_orbit += delta * 0.12
		var r: float = 17.0
		camera.position = Vector3(_cam_focus.x + sin(_orbit) * r, 13.0, _cam_focus.z + cos(_orbit) * r)
		camera.look_at(_cam_focus + Vector3(0, -1.5, 0), Vector3.UP)
		return
	if shot_cam.w > 0.0:
		# Store-screenshot close-up (tools/play_shot.gd "cam"): x, z, distance, height.
		var focus := Vector3(shot_cam.x, 0.0, shot_cam.y)
		camera.position = focus + Vector3(0.0, shot_cam.w, 5.0).normalized() * shot_cam.z
		camera.look_at(focus, Vector3.UP)
		camera.v_offset = 0.0
		return
	# A still camera that frames the whole arena, so a tapped spot never
	# slides away under the finger.
	var d: float = _cam_distance()
	camera.position = _cam_focus + CAM_DIR.normalized() * d
	camera.look_at(_cam_focus, Vector3.UP)
	# Lift the camera so the arena sits in the middle of the space below
	# the HUD (the shift is the same at any screen height).
	var vp: Vector2 = get_viewport().get_visible_rect().size
	camera.v_offset = HUD_TOP * 0.5 / vp.x * 2.0 * d * tan(deg_to_rad(CAM_FOV * 0.5))
	if _shake > 0.0:
		_shake = maxf(_shake - delta * 0.9, 0.0)
		camera.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake * 0.35

extends WorldKit
## World 20, Pixel Arcade: a bright retro arcade floor of CRT-blue tiles,
## candy-pink pixel blocks and gold prize crates, with marquee bulbs chasing
## round the border. The twist is wrap-around: some border blocks are
## missing, each gap marked by a glowing arrow arch, and gaps come in pairs
## straight across the arena (left/right on a row, top/bottom on a column).
## Walking into one brings Pip out of its partner; blasts that run out of a
## gap carry on from the partner (so a blast can come at you from behind),
## kicked pods and critters wrap too. Bleepers march in rows and step down a
## row at each end; Blips bounce along straight lines. The Mega Cabinet boss
## glitches out and pops in through a gap; once hurt, its entrance sends a
## pixel beam through the partner arch.
##
## Extra map characters:
##   O  a wrap gap in the border (its partner is the gap straight across)
##   p  Bleeper            q  Blip

const M := preload("res://worlds/world_20_models.gd")

const BOSS_BEAM_HP: int = 5
const BOSS_EVERY: float = 7.0
const BOSS_CHARGE: float = 0.9
const BOSS_AWAY: float = 1.1
const BEAM_REACH: int = 5

const PALETTE: Dictionary = {
	"GRASS_A": "#CFE3FF", "GRASS_B": "#B9D4FB", "RIM": "#FFD6EA", "EDGE": "#5D8BF4",
	"STONE": "#FFB8DC", "DARK_STONE": "#FF8CC6", "DIRT": "#A08BF2", "ROCK": "#8571DE",
	"WOOD": "#FFCF4A", "WOOD_DARK": "#FF7FB6", "BARREL": "#FF6B6B", "BELT": "#4A4F8C", "ACCENT": "#FFD84D",
	"BLOSSOM_A": "#FF8CC6", "BLOSSOM_B": "#FF6FB5", "TRUNK": "#5D8BF4", "LEAFY_A": "#7FD6FF", "LEAFY_B": "#5FC2F5",
	"SKY_TOP": "#7DB4FF", "SKY_HORIZON": "#FFE4F2", "SKY_GROUND": "#EEE6FF", "CLOUD": "#FFFFFF", "CLOUDS": 0.45,
	"AMBIENT": "#DCDDFF", "AMBIENT_ENERGY": 0.6, "SUN": "#FFF5F2", "SUN_ENERGY": 1.4,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Insert Coin",
		"tip": "Glowing arches are wrap doors:\nwalk in on one side, pop out\nof its twin across. Blasts wrap too!",
		"crates": 0.36, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#...p.#..E..#",
			"#.#.#.#.#.#.#",
			"#.....#.....#",
			"#.#.#.#.#.#.#",
			"#.....#..p..#",
			"#.#.#.#.#.#.#",
			"O_____#_____O",
			"#.#.#.#.#.#.#",
			"#..p..#.....#",
			"#.#.#.#.#.#.#",
			"#.....#..p..#",
			"#.#_#.#.#.#.#",
			"#._S_.#.....#",
			"#############",
		],
	},
	{
		"name": "Pixel Pong",
		"tip": "Blips bounce along straight\nlines and zip through arches.\nBlast through a gap to break in!",
		"crates": 0.4, "par": 85,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#...p...#_E_#",
			"#.#.#.#.#_#_#",
			"O.q.....#__cO",
			"#.#.#.#.#####",
			"#.....p.....#",
			"#.#.#.#.#.#.#",
			"#.........q.#",
			"#.#.#.#.#.#.#",
			"#..p........#",
			"#.#.#.#.#.#.#",
			"O.q.........O",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Up and Over",
		"tip": "Top and bottom arches link too.\nDrop down to come out on top,\nbut mind blasts wrapping after you!",
		"crates": 0.4, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"###O#####O###",
			"#.._..E.._..#",
			"#.#.#.#.#.#.#",
			"#..p.....q..#",
			"#.#.#.#.#.#.#",
			"#.z.......p.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#############",
			"#..p.....q..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#.._._S_._..#",
			"###O#####O###",
		],
	},
	{
		"name": "Marching Band",
		"tip": "Bleepers march along the rows\nand right round through the arches.\nSet a pod where the line comes in!",
		"crates": 0.38, "par": 105,
		"drops": {"bomb": 3, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#####O#######",
			"#....._...E.#",
			"#.#.#.#.#.#.#",
			"O....p....p.O",
			"#.#.#.#.#.#.#",
			"#.q...#...z.#",
			"#.#.#.#.#.#.#",
			"O.p.......p.O",
			"#.#.#.#.#.#.#",
			"#.....#.....#",
			"#.#.#.#.#.#.#",
			"O..p.....p..O",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#####O#######",
		],
	},
	{
		"name": "High Score Hall",
		"tip": "Kicked pods wrap round as well.\nThe prize room has crate doors:\nhit them from either side!",
		"crates": 0.4, "par": 115,
		"drops": {"bomb": 3, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"###O#####O###",
			"#.._..p.._..#",
			"#.#.#.#.#.#.#",
			"O.q.......z.O",
			"#.#.#.#.#.#.#",
			"#...##c##...#",
			"#.#.#___#.#.#",
			"O.p.c_E_c.p.O",
			"#.#.#___#.#.#",
			"#...##c##...#",
			"#.#.#.#.#.#.#",
			"O.q.......p.O",
			"#.#.#_#_#.#.#",
			"#.._._S_._..#",
			"###O#####O###",
		],
	},
	{
		"name": "Mega Cabinet",
		"tip": "The Mega Cabinet glitches out\nand pops in through an arch.\nWatch for its beam when it's hurt!",
		"crates": 0.18, "par": 150,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"###O#####O###",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"O...........O",
			"#.#.#...#.#.#",
			"#...........#",
			"#.#...#...#.#",
			"#.....K.....#",
			"#.#...#...#.#",
			"#...........#",
			"#.#.#...#.#.#",
			"O...........O",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"###O#####O###",
		],
	},
]

## Vector2i -> {"partner", "out", "color", "node", "bump"} for each gap.
var gaps: Dictionary = {}
var _gap_list: Array[Vector2i] = []
var _pending: Array[Vector2i] = []
var _own: bool = false
var _pod_fire: Dictionary = {}
var _last_dir: Dictionary = {}       # Critter -> its direction last frame
var _march: Dictionary = {}          # Bleeper -> {"h": Vector2i, "v": int}
var _hero_prev: Vector2 = Vector2.ZERO
var _bulbs: Array = []               # [MultiMeshInstance3D, Color] per bulb set
var _bulb_t: float = 0.0
var _bulb_on: int = 0
var _icons: Array[Node3D] = []
var _boss_state: StringName = &"walk"
var _boss_t: float = 5.0
var _boss_gap: Vector2i = Arena.NO_CELL
var _beam: Array[Vector2i] = []
var _warn_nodes: Array[Node3D] = []
var _player: AudioStreamPlayer
var _snd_wrap: AudioStreamWAV
var _snd_warn: AudioStreamWAV
var _snd_zap: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Pixel Arcade"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_20.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "MEGA CABINET"


func boss_hp() -> int:
	return 9


func boss_minion_kind() -> StringName:
	if arena != null and arena.boss != null and arena.boss.hp * 2 <= arena.boss_max_hp:
		return &"blip"
	return &"bleeper"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if ch == "O":
		_gap_list.append(c)
		return true
	return false


func critter_chars() -> Dictionary:
	return {"p": &"bleeper", "q": &"blip"}


func _out_dir(c: Vector2i) -> Vector2i:
	if c.x == 0:
		return Vector2i(-1, 0)
	if c.x == Arena.W - 1:
		return Vector2i(1, 0)
	if c.y == 0:
		return Vector2i(0, -1)
	return Vector2i(0, 1)


func _partner(c: Vector2i) -> Vector2i:
	if c.x == 0:
		return Vector2i(Arena.W - 1, c.y)
	if c.x == Arena.W - 1:
		return Vector2i(0, c.y)
	if c.y == 0:
		return Vector2i(c.x, Arena.H - 1)
	return Vector2i(c.x, 0)


func _is_gap(c: Vector2i) -> bool:
	return _gap_list.has(c)


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	# Marquee bulbs: a pixel bulb on each border block on a pink strip, in two
	# sets that take turns to light up so the lights chase round the arena.
	var strips: Array[Transform3D] = []
	var sets: Array = [[], []]
	for tf in blocks:
		var c := Vector2i(roundi(tf.origin.x), roundi(tf.origin.z))
		if _is_gap(c):
			continue
		var along_x: bool = c.y == 0 or c.y == Arena.H - 1
		var turn := Basis(Vector3.UP, 0.0 if along_x else PI * 0.5)
		strips.append(Transform3D(turn, Vector3(c.x, 0.7, c.y)))
		(sets[(c.x + c.y) % 2] as Array).append(Transform3D(Basis(), Vector3(c.x, 0.8, c.y)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.05, 0.42), 0.02), M.CANDY_LIGHT, strips)
	var bulb := Models.box_mesh(Vector3(0.2, 0.17, 0.2), 0.04)
	var cols: Array[Color] = [M.LEMON, Color("#FFFFFF")]
	for k in 2:
		var arr: Array[Transform3D] = []
		arr.assign(sets[k])
		var mm: MultiMesh = arena._multimesh(bulb, cols[k], arr)
		var mmi: MultiMeshInstance3D = _mm_instance(mm)
		if mmi != null:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_bulbs.append([mmi, cols[k]])
	return true


## Solid blocks are chunky pixel blocks: eight cubes in a two-tone pink
## checker with a white pixel glint on top.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var a: Array[Transform3D] = []
	var b: Array[Transform3D] = []
	var glints: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		for i in 8:
			var ix: int = i % 2
			var iy: int = (i / 2) % 2
			var iz: int = i / 4
			var at: Vector3 = p + Vector3(-0.2 + ix * 0.4, 0.2 + iy * 0.4, -0.2 + iz * 0.4)
			if (ix + iy + iz) % 2 == 0:
				a.append(Transform3D(Basis(), at))
			else:
				b.append(Transform3D(Basis(), at))
		glints.append(Transform3D(Basis(), p + Vector3(-0.24, 0.81, -0.24)))
	var cube := Models.box_mesh(Vector3(0.4, 0.4, 0.4), 0.035)
	arena._multimesh(cube, Models.DARK_STONE, a)
	arena._multimesh(cube, Models.STONE, b)
	arena._multimesh(Models.box_mesh(Vector3(0.14, 0.03, 0.14), 0.01), Color.WHITE, glints)
	return true


func _mm_instance(mm: MultiMesh) -> MultiMeshInstance3D:
	for ch: Node in arena.get_children():
		if ch is MultiMeshInstance3D and (ch as MultiMeshInstance3D).multimesh == mm:
			return ch
	return null


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var holder := Node3D.new()
	var cell := Vector2i(roundi(p.x), roundi(p.z))
	# Keep the spot just outside each gap clear.
	for g: Vector2i in _gap_list:
		if cell == g + _out_dir(g):
			return holder
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M.coins(r)
		elif roll < 0.28:
			node = M.joystick(r)
			node.scale = Vector3.ONE * 0.7
	else:
		if roll < 0.2:
			node = M.cabinet(r)
			node.rotation.y = PI if p.z < 0.0 else (PI * 0.5 if p.x < 0.0 else -PI * 0.5)
		elif roll < 0.36:
			node = M.joystick(r)
			node.rotation.y = r.randf_range(-0.5, 0.5)
		elif roll < 0.48:
			node = M.coins(r)
		elif roll < 0.56:
			node = M.pixel_icon(r.randf() < 0.5)
			_icons.append(node)
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var cab := M.cabinet(r)
	cab.scale = Vector3.ONE * 1.5
	cab.position = Vector3(-size * 0.12, 0, -size * 0.1)
	root.add_child(cab)
	var joy := M.joystick(r)
	joy.position = Vector3(size * 0.25, 0, size * 0.2)
	root.add_child(joy)
	var icon := M.pixel_icon(r.randf() < 0.5)
	icon.position = Vector3(-size * 0.3, 0, size * 0.25)
	icon.scale = Vector3.ONE * 1.3
	root.add_child(icon)
	_icons.append(icon)
	return root


func build_extra() -> void:
	var pair_ids: Dictionary = {}
	for g: Vector2i in _gap_list:
		var partner: Vector2i = _partner(g)
		if not _gap_list.has(partner):
			push_error("Pixel Arcade: gap %s has no partner at %s" % [g, partner])
			continue
		var key: int = mini(g.x * 100 + g.y, partner.x * 100 + partner.y)
		if not pair_ids.has(key):
			pair_ids[key] = pair_ids.size()
		var color: Color = M.PAIR_COLORS[int(pair_ids[key]) % M.PAIR_COLORS.size()]
		var out: Vector2i = _out_dir(g)
		var node: Node3D = M.arch(color)
		node.position = Vector3(g.x, 0, g.y)
		node.rotation.y = atan2(-float(out.x), -float(out.y))
		arena.add_child(node)
		gaps[g] = {"partner": partner, "out": out, "color": color, "node": node, "bump": 0.0}
		# Pip goes through them like warp pads (this also keeps pods out and
		# lets tap-to-walk route through them).
		arena.warps[g] = partner
	_hide_border_at_gaps()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	arena.add_child(_player)
	_snd_wrap = _make_wrap()
	_snd_warn = _make_warn()
	_snd_zap = _make_zap()
	if arena.hero != null:
		_hero_prev = arena.hero_pos


## The border is drawn as one multimesh of blocks (and one of caps): park the
## instances that stand where a gap is.
func _hide_border_at_gaps() -> void:
	var hidden := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -6, 0))
	for ch: Node in arena.get_children():
		if not ch is MultiMeshInstance3D:
			continue
		var mm: MultiMesh = (ch as MultiMeshInstance3D).multimesh
		if mm == null:
			continue
		for i in mm.instance_count:
			var o: Vector3 = mm.get_instance_transform(i).origin
			var c := Vector2i(roundi(o.x), roundi(o.z))
			if gaps.has(c) and absf(o.x - c.x) < 0.01 and absf(o.z - c.y) < 0.01 and o.y > 0.0:
				mm.set_instance_transform(i, hidden)


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFF4F4")
	env.glow_intensity = 0.6
	env.glow_bloom = 0.08
	env.adjustment_saturation = 1.1


# --- Blasts through gaps ------------------------------------------------------------

func on_flame(c: Vector2i) -> void:
	if gaps.has(c):
		gaps[c]["bump"] = 1.0
		if not _own and not _pending.has(c):
			_pending.append(c)


func on_explode(c: Vector2i) -> void:
	var fire: int = int(_pod_fire.get(c, arena.fire))
	_resolve_pending(c, fire)


## Carries on every blast arm that ran out of a gap during the blast from
## [param origin] (reach [param fire]).
func _resolve_pending(origin: Vector2i, fire: int) -> void:
	var list: Array[Vector2i] = _pending.duplicate()
	_pending.clear()
	for g: Vector2i in list:
		var k: int = 1
		if origin != Arena.NO_CELL:
			var diff: Vector2i = g - origin
			k = absi(diff.x) + absi(diff.y)
			if k > 0 and (diff.x != 0 and diff.y != 0):
				continue
		_wrap_from(g, fire - k, k)


## A blast arm reached gap [param g] at distance [param k] with
## [param rest] tiles of reach left: it comes out of the partner gap.
func _wrap_from(g: Vector2i, rest: int, k: int) -> void:
	if not gaps.has(g):
		return
	var info: Dictionary = gaps[g]
	var partner: Vector2i = info["partner"]
	var out: Vector2i = info["out"]
	_own = true
	arena._add_flame(partner, k, out)
	gaps[partner]["bump"] = 1.0
	if arena.pod_at.has(partner):
		var pod: Arena.Pod = arena.pod_at[partner]
		pod.timer = minf(pod.timer, 0.06)
	elif rest > 0:
		_arm(partner + out, out, rest, k + 1, 1)
	_own = false
	arena._spawn_ring(Vector3(partner.x, 0.08, partner.y), info["color"], 0.6)
	_sound(_snd_wrap, 1.25)


## One blast arm from [param start] along [param d], like the arena's own
## blast: walls stop it, crates and barrels burn and stop it, pods go off,
## and it wraps again through any gap it runs out of.
func _arm(start: Vector2i, d: Vector2i, reach: int, dist0: int, hops: int) -> void:
	var cc: Vector2i = start
	for i in reach:
		var t: int = arena.tile(cc)
		if t == Arena.WALL:
			return
		var own: int = flame_stop(cc)
		if own == 2:
			return
		arena._add_flame(cc, dist0 + i, d)
		if own == 1:
			return
		if t == Arena.CRATE:
			arena._break_crate(cc)
			return
		if t == Arena.BARREL:
			arena._ignite_barrel(cc)
			return
		if arena.pod_at.has(cc):
			var pod: Arena.Pod = arena.pod_at[cc]
			pod.timer = minf(pod.timer, 0.06)
			return
		if gaps.has(cc) and gaps[cc]["out"] == d:
			gaps[cc]["bump"] = 1.0
			if hops >= 3:
				return
			var p2: Vector2i = gaps[cc]["partner"]
			arena._add_flame(p2, dist0 + i, d)
			gaps[p2]["bump"] = 1.0
			if arena.pod_at.has(p2):
				var pod2: Arena.Pod = arena.pod_at[p2]
				pod2.timer = minf(pod2.timer, 0.06)
				return
			_arm(p2 + d, d, reach - i - 1, dist0 + i + 1, hops + 1)
			return
		cc += d


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	if not _pending.is_empty():
		# A blast that did not come from a pod (no reach known): one tile on.
		_resolve_pending(Arena.NO_CELL, 2)
	_wrap_critters()
	_wrap_pods()
	_animate(delta)
	if not arena.demo:
		_update_boss(delta)
		_hero_wrap_fx()
	_shrink_in_gaps()
	_pod_fire.clear()
	for p: Arena.Pod in arena.pods:
		_pod_fire[p.cell] = p.fire
	for cr: Arena.Critter in arena.critters:
		_last_dir[cr] = cr.dir


## A critter that just walked into a gap heading out was turned back by the
## arena (nothing beyond): send it on out of the partner gap instead.
func _wrap_critters() -> void:
	for cr: Arena.Critter in arena.critters:
		if not gaps.has(cr.cell) or (cr == arena.boss and _boss_state == &"away"):
			continue
		var info: Dictionary = gaps[cr.cell]
		var out: Vector2i = info["out"]
		var last: Vector2i = _last_dir.get(cr, cr.dir)
		if last != out:
			continue
		var turned: bool = cr.t < 0.5 and cr.target != cr.cell and cr.dir != out
		if not turned and cr.t < 1.0:
			continue
		var partner: Vector2i = info["partner"]
		var nxt: Vector2i = partner + out
		if not arena._critter_can_enter(cr, nxt) or not arena._critter_can_enter(cr, partner):
			continue
		cr.cell = partner
		cr.target = nxt
		cr.dir = out
		cr.t = 0.0
		cr.pos = Vector2(partner)
		cr.node.position = Vector3(partner.x, 0, partner.y)
		cr.node.rotation.y = atan2(float(out.x), float(out.y))
		if _march.has(cr):
			if out.x != 0:
				_march[cr]["h"] = out
			else:
				_march[cr]["v"] = out.y
		info["bump"] = 1.0
		gaps[partner]["bump"] = 1.0
		_sound(_snd_wrap, 1.6)


## A pod kicked out of a gap stops in it (the arena sees a wall beyond):
## move it to the partner gap and send it on.
func _wrap_pods() -> void:
	for p: Arena.Pod in arena.pods:
		if not gaps.has(p.cell) or p.slide != Vector2i.ZERO:
			continue
		var info: Dictionary = gaps[p.cell]
		var partner: Vector2i = info["partner"]
		if arena.pod_at.has(partner) or (arena.hero_alive and arena.hero_cell() == partner):
			continue
		if arena.pod_at.get(p.cell) == p:
			arena.pod_at.erase(p.cell)
		p.cell = partner
		p.pos = Vector2(partner)
		arena.pod_at[partner] = p
		var out: Vector2i = info["out"]
		if not arena._pod_blocked(partner + out):
			p.slide = out
			p.slide_speed = Arena.KICK_SPEED
			p.kicked = true
		p.node.position = Vector3(partner.x, 0, partner.y)
		info["bump"] = 1.0
		gaps[partner]["bump"] = 1.0
		_sound(_snd_wrap, 1.4)


func _hero_wrap_fx() -> void:
	if arena.hero == null:
		return
	var now: Vector2 = arena.hero_pos
	if now.distance_to(_hero_prev) > 3.0:
		var c: Vector2i = arena.hero_cell()
		if gaps.has(c):
			var col: Color = gaps[c]["color"]
			gaps[c]["bump"] = 1.0
			gaps[gaps[c]["partner"]]["bump"] = 1.0
			arena._spawn_ring(Vector3(c.x, 0.08, c.y), col, 0.7)
	_hero_prev = now


## How far a point is past the inner edge of the arena, 0..1 (1 at the
## middle of a gap).
func _gap_depth(p: Vector2) -> float:
	var o: float = maxf(maxf(1.0 - p.x, p.x - (Arena.W - 2)), maxf(1.0 - p.y, p.y - (Arena.H - 2)))
	return clampf(o, 0.0, 1.0)


func _gap_scale(p: Vector2) -> float:
	return 1.0 - 0.72 * smoothstep(0.0, 1.0, _gap_depth(p))


## Whatever stands in a gap shrinks into the arch, so wrapping reads as a
## quick slide out of one side and in at the other.
func _shrink_in_gaps() -> void:
	if arena.hero != null:
		arena.hero.scale = Vector3.ONE * _gap_scale(arena.hero_pos)
	for cr: Arena.Critter in arena.critters:
		var d: float = _gap_depth(cr.pos)
		if d > 0.0:
			cr.node.scale = Vector3.ONE * _gap_scale(cr.pos)
	for p: Arena.Pod in arena.pods:
		p.node.scale = Vector3.ONE * _gap_scale(p.pos)


func _animate(delta: float) -> void:
	var clock: float = arena._clock
	for g: Vector2i in gaps:
		var info: Dictionary = gaps[g]
		var n: Node3D = info["node"]
		info["bump"] = maxf(float(info["bump"]) - delta * 2.5, 0.0)
		var b: float = float(info["bump"])
		for k in 2:
			var ch: Node3D = n.get_node("Chev%d" % k)
			# Slide out through the gap (local -Z), looping.
			ch.position.z = 0.4 - fposmod(clock * 0.9 + k * 0.5, 1.0) * 0.8
		var beam: Node3D = n.get_node("Beam")
		beam.scale = Vector3(1.0 + b * 0.12, 1.0 + b * 0.5, 1.0 + b * 0.3)
		var pad: Node3D = n.get_node("Pad")
		pad.scale = Vector3.ONE * (1.0 + 0.05 * sin(clock * 4.0 + g.x + g.y) + b * 0.15)
	# Marquee chase.
	_bulb_t += delta
	if _bulb_t > 0.45:
		_bulb_t = 0.0
		_bulb_on = 1 - _bulb_on
		for k in _bulbs.size():
			var mmi: MultiMeshInstance3D = _bulbs[k][0]
			var col: Color = _bulbs[k][1]
			mmi.material_override = Models.mat(col, 2.2) if k == _bulb_on else Models.mat(col.darkened(0.12), 0.15)
	for icon: Node3D in _icons:
		if is_instance_valid(icon):
			var spin: Node3D = icon.get_node("Spin")
			spin.rotation.y += delta * 1.4
			spin.position.y = 0.38 + sin(clock * 2.0 + icon.position.x) * 0.05


# --- Critters ---------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"bleeper":
			return M.bleeper()
		&"blip":
			return M.blip()
		&"boss":
			return M.boss()
	return null


func critter_speed(kind: StringName) -> float:
	if kind == &"bleeper":
		return 1.7 + 0.06 * arena.level_id
	if kind == &"blip":
		return 2.5 + 0.05 * arena.level_id
	return 1.5


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind == &"bleeper":
		return _bleeper_step(cr)
	if cr.kind == &"blip":
		return _blip_step(cr)
	return Vector2i.ZERO


func _ok(cr: Arena.Critter, c: Vector2i, danger: Dictionary) -> bool:
	return arena._critter_can_enter(cr, c) and not danger.has(c)


## Bleepers march along a row; at the end of it they step one row down (or
## up, once they reach the bottom) and march back the other way.
func _bleeper_step(cr: Arena.Critter) -> Vector2i:
	if not _march.has(cr):
		# They drift away from the bottom (where Pip starts) first.
		var v0: int = 1 if cr.cell.y < 7 else -1
		_march[cr] = {"h": Vector2i(1, 0) if arena.rng.randf() < 0.5 else Vector2i(-1, 0), "v": v0}
	var st: Dictionary = _march[cr]
	var danger: Dictionary = arena._critter_danger(cr)
	var h: Vector2i = st["h"]
	if _ok(cr, cr.cell + h, danger):
		return h
	for k in 2:
		var v := Vector2i(0, int(st["v"]))
		if _ok(cr, cr.cell + v, danger):
			st["h"] = -h
			return v
		st["v"] = -int(st["v"])
	st["h"] = -h
	if _ok(cr, cr.cell - h, danger):
		return -h
	return Vector2i.ZERO


## Blips shoot along straight lines; when stopped they ricochet off to the
## side or straight back.
func _blip_step(cr: Arena.Critter) -> Vector2i:
	var danger: Dictionary = arena._critter_danger(cr)
	if _ok(cr, cr.cell + cr.dir, danger):
		return cr.dir
	var side: Array[Vector2i] = [Vector2i(cr.dir.y, cr.dir.x), Vector2i(-cr.dir.y, -cr.dir.x)]
	if arena.rng.randf() < 0.5:
		side.reverse()
	var options: Array = side.filter(func(d: Vector2i) -> bool: return _ok(cr, cr.cell + d, danger))
	if not options.is_empty() and arena.rng.randf() < 0.55:
		return options[0]
	if _ok(cr, cr.cell - cr.dir, danger):
		return -cr.dir
	if not options.is_empty():
		return options[0]
	return Vector2i.ZERO


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr == arena.boss and _boss_state == &"away"


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"bleeper":
			var frame: bool = fmod(t * 4.0, 2.0) < 1.0
			(body.get_node("FeetA") as Node3D).visible = frame
			(body.get_node("FeetB") as Node3D).visible = not frame
			body.position.y = 0.025 if frame else 0.0
			var tip: Node3D = body.get_node("Tip")
			tip.scale = Vector3.ONE * (1.0 + 0.25 * sin(t * 8.0))
			return Vector3.ONE * M.BLEEPER_SIZE
		&"blip":
			var ball: Node3D = body.get_node("Ball")
			var hop: float = absf(sin(t * 7.0))
			ball.position.y = 0.3 + hop * 0.32
			var squash: float = clampf(1.0 - hop * 4.0, 0.0, 1.0)
			ball.scale = Vector3(1.0 + squash * 0.22, 1.0 - squash * 0.25, 1.0 + squash * 0.22)
			return Vector3.ONE * M.BLIP_SIZE
		&"boss":
			var cab: Node3D = body.get_node("Cab")
			var screen: Node3D = cab.get_node("Screen")
			var charging: bool = _boss_state == &"charge"
			(screen.get_node("Static") as Node3D).visible = charging and fmod(t * 14.0, 2.0) < 1.2
			(screen.get_node("Eyes") as Node3D).visible = not charging or fmod(t * 14.0, 2.0) >= 1.2
			var walk: float = sin(t * 7.0) if cr.t < 1.0 else 0.0
			(body.get_node("LegL") as Node3D).position.y = maxf(walk, 0.0) * 0.08
			(body.get_node("LegR") as Node3D).position.y = maxf(-walk, 0.0) * 0.08
			cab.rotation.z = (sin(t * 40.0) * 0.06) if charging else walk * 0.04
			cab.position.x = (sin(t * 53.0) * 0.04) if charging else 0.0
			(cab.get_node("ArmL") as Node3D).rotation.x = sin(t * 3.0) * 0.4
			(cab.get_node("ArmR") as Node3D).rotation.x = -sin(t * 3.0) * 0.4
			(cab.get_node("Stick") as Node3D).rotation.z = sin(t * 5.0) * 0.4
			var mq: Node3D = cab.get_node("Marquee")
			mq.scale = Vector3.ONE * (1.0 + 0.04 * sin(t * 9.0))
			return Vector3(1.0, 1.0 + absf(sin(t * 3.5)) * 0.03, 1.0)
	return Vector3.ONE


# --- The Mega Cabinet --------------------------------------------------------------

func _update_boss(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		_clear_warn()
		return
	b.speed = 1.1 + (arena.boss_max_hp - b.hp) * 0.07
	match _boss_state:
		&"walk":
			_boss_t -= delta
			if _boss_t <= 0.0 and b.t >= 0.0:
				_boss_state = &"charge"
				_boss_t = BOSS_CHARGE
				_sound(_snd_warn, 1.0)
		&"charge":
			_boss_t -= delta
			if _boss_t <= 0.0:
				var g: Vector2i = _pick_gap(b)
				if g == Arena.NO_CELL:
					_boss_state = &"walk"
					_boss_t = 1.5
				else:
					_boss_gap = g
					_boss_state = &"away"
					_boss_t = BOSS_AWAY
					arena._spawn_sparkles(Vector3(b.pos.x, 0.6, b.pos.y), M.SCREEN_GLOW)
					b.node.visible = false
					_beam.clear()
					if b.hp <= BOSS_BEAM_HP:
						_beam = _beam_path(g)
						_show_warn()
		&"away":
			_boss_t -= delta
			b.target = b.cell
			b.t = 1.0
			b.pos = Vector2(b.cell)
			for w: Node3D in _warn_nodes:
				w.scale = Vector3.ONE * (0.85 + 0.15 * sin(arena._clock * 20.0))
			if _boss_t <= 0.0:
				_boss_appear(b)


## A gap for the cabinet to come in by: its inner tile open and well away
## from Pip.
func _pick_gap(b: Arena.Critter) -> Vector2i:
	var hc: Vector2i = arena.hero_cell()
	var options: Array[Vector2i] = []
	for g: Vector2i in gaps:
		var inner: Vector2i = g - (gaps[g]["out"] as Vector2i)
		if not arena._critter_can_enter(b, inner) or not arena._critter_can_enter(b, g):
			continue
		if absi(inner.x - hc.x) + absi(inner.y - hc.y) < 5:
			continue
		if arena.flames.has(inner) or g == b.cell:
			continue
		options.append(g)
	if options.is_empty():
		return Arena.NO_CELL
	return options[arena.rng.randi() % options.size()]


## The tiles the entrance beam will cross: out of the partner of the gap the
## cabinet comes in by, heading the same way it was "fired" (out of its gap).
func _beam_path(g: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var partner: Vector2i = gaps[g]["partner"]
	var d: Vector2i = gaps[g]["out"]
	var c: Vector2i = partner + d
	for i in BEAM_REACH:
		var t: int = arena.tile(c)
		if t == Arena.WALL:
			break
		out.append(c)
		if t == Arena.CRATE or arena.pod_at.has(c):
			break
		c += d
	return out


func _show_warn() -> void:
	_clear_warn()
	for c: Vector2i in _beam:
		var w: Node3D = M.warn_tile()
		w.position = Vector3(c.x, 0, c.y)
		arena.add_child(w)
		_warn_nodes.append(w)


func _clear_warn() -> void:
	for w: Node3D in _warn_nodes:
		if is_instance_valid(w):
			w.queue_free()
	_warn_nodes.clear()


func _boss_appear(b: Arena.Critter) -> void:
	var g: Vector2i = _boss_gap
	var inward: Vector2i = -(gaps[g]["out"] as Vector2i)
	b.cell = g
	b.pos = Vector2(g)
	b.dir = inward
	b.target = g + inward if arena._critter_can_enter(b, g + inward) else g
	b.t = 0.0 if b.target != g else 1.0
	b.node.visible = true
	b.node.position = Vector3(g.x, 0, g.y)
	b.node.scale = Vector3.ONE * 0.2
	b.node.rotation.y = atan2(float(inward.x), float(inward.y))
	gaps[g]["bump"] = 1.0
	arena._spawn_sparkles(Vector3(g.x, 0.6, g.y), gaps[g]["color"])
	_boss_state = &"walk"
	_boss_t = BOSS_EVERY if b.hp > BOSS_BEAM_HP else BOSS_EVERY - 2.0
	if not _beam.is_empty():
		var partner: Vector2i = gaps[g]["partner"]
		var d: Vector2i = gaps[g]["out"]
		_own = true
		arena._add_flame(partner, 0, d)
		_arm(partner + d, d, _beam.size(), 1, 2)
		_own = false
		gaps[partner]["bump"] = 1.0
		arena._shake = maxf(arena._shake, 0.25)
		_sound(_snd_zap, 1.0)
	_beam.clear()
	_clear_warn()


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


## A soft band-limited square wave (odd harmonics only).
func _sq(ph: float) -> float:
	return sin(ph) + sin(3.0 * ph) / 3.0 + sin(5.0 * ph) / 5.0 * 0.7


## A quick rising chip arpeggio: something went through an arch.
func _make_wrap() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.22)
	var out := PackedFloat32Array()
	out.resize(n)
	var notes: Array[float] = [523.3, 659.3, 784.0, 1046.5]
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var k: int = mini(int(t / 0.045), 3)
		ph += TAU * notes[k] / rate
		var env: float = minf(t / 0.004, 1.0) * exp(-t * 9.0)
		out[i] = _sq(ph) * env * 0.28
	return _wav(out)


## Two falling chip notes: the cabinet is glitching out.
func _make_warn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.5)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 740.0 if t < 0.2 else 494.0
		f *= 1.0 + 0.02 * sin(TAU * 18.0 * t)
		ph += TAU * f / rate
		var tt: float = fmod(t, 0.2) if t < 0.4 else t - 0.2
		var env: float = minf(tt / 0.005, 1.0) * exp(-tt * 6.0)
		out[i] = _sq(ph) * env * 0.3
	return _wav(out)


## A downward pixel zap: the beam comes through.
func _make_zap() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.4)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 1400.0 * exp(-t * 6.0) + 120.0
		ph += TAU * f / rate
		var env: float = minf(t / 0.003, 1.0) * exp(-t * 5.0)
		out[i] = _sq(ph) * env * 0.32
	return _wav(out)

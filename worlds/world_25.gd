extends WorldKit
## World 25, Starlight Summit: the last world, a mountain top above the
## clouds at twilight. Parts of the summit are open "sky gaps" that Pip
## can't walk over, though flames fly straight across them. Star nodes stand
## on stone pedestals: a blast that reaches a star lights it, and when every
## star of a constellation is lit, glowing starlight bridges appear over the
## sky gaps on its lines. Constellations come in gold, cyan and pink; some
## of them fade after a while (they blink first, and never vanish while Pip
## or a pod is on a bridge), so they must be lit again. Blasting a star of a
## lit constellation tops its light back up.
## Star Sprites glide about (happily over bridges); Comet Kittens crouch
## when Pip is in line with them, then dash straight at him. The Star Owl,
## the grand finale, dims constellations and, at the end, flies from
## platform to platform and rearranges the sky.
##
## Extra map characters:
##   x y q  star of the gold / cyan / pink constellation
##   X Y Q  sky gap that the gold / cyan / pink bridge spans
##   o      plain sky gap (no bridge)
##   n      Star Sprite       k  Comet Kitten
## Level keys: "fade": [gold, cyan, pink] seconds a constellation stays lit
## (0 = for good); "lit": [bool, bool, bool] constellations lit at the start.

const M := preload("res://worlds/world_25_models.gd")

const BLINK: float = 2.6
const DASH_SPEED: float = 5.2
const DASH_RANGE: int = 5
const WIND_TIME: float = 0.6
const REST_TIME: float = 0.8
const FLY_RISE: float = 0.5
const FLY_TIME: float = 1.1
const FLY_DROP: float = 0.45
const FLY_HIGH: float = 2.8

const PALETTE: Dictionary = {
	"GRASS_A": "#B0BAF0", "GRASS_B": "#9FAAE6", "RIM": "#959FD6", "EDGE": "#6E78B5",
	"STONE": "#D9DDF6", "DARK_STONE": "#8089C2", "DIRT": "#8A86B8", "ROCK": "#6F78B0",
	"WOOD": "#FFD27A", "WOOD_DARK": "#E9A94A", "BARREL": "#FF9AD5", "ACCENT": "#FFD45E",
	"BLOSSOM_A": "#5F8DB8", "BLOSSOM_B": "#4D78A3", "TRUNK": "#7B5E73", "LEAFY_A": "#6E9BC4", "LEAFY_B": "#5A86B0",
	"SKY_TOP": "#2B3672", "SKY_HORIZON": "#F4B27E", "SKY_GROUND": "#B9A6D8", "CLOUD": "#FFE9D6", "CLOUDS": 0.45,
	"AMBIENT": "#BDB8EC", "AMBIENT_ENERGY": 0.72, "SUN": "#FFD9AE", "SUN_ENERGY": 1.25,
}

const LEVELS: Array[Dictionary] = [
	{
		"name": "Above the Clouds",
		"tip": "Blast both gold stars to light\nthe constellation: a starlight\nbridge will span the sky gap!",
		"crates": 0.3, "par": 80,
		"drops": {"bomb": 2, "fire": 1, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..n.....n..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#oooooXooooo#",
			"#....x.x....#",
			"#.#.#...#.#.#",
			"#.........n.#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#_#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Little Dipper",
		"tip": "Flames fly right over sky gaps,\nso you can light a star on the\nfar side!",
		"crates": 0.34, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#..E........#",
			"#.#.#.#.#.#.#",
			"#.....n.....#",
			"#ooooooooYoo#",
			"#.......y.n.#",
			"#.#.#.#.#.#.#",
			"#.x.n.....y.#",
			"#ooXoooooooo#",
			"#....x......#",
			"#.#.#.#.#.#.#",
			"#.......n...#",
			"#_#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Comet Tails",
		"tip": "Comet Kittens crouch when you're\nin line with them, then dash!\nStep aside when they wiggle.",
		"crates": 0.36, "par": 100,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..E..o..n..#",
			"#.#.#.o.#.#.#",
			"#..n..Y..k..#",
			"#oooooo.#.#.#",
			"#n....o..y..#",
			"#.#.#.o.#.#.#",
			"#..k..o....y#",
			"#.#.#.o.#.#.#",
			"#.x...X.....#",
			"#.#.#.o.#.#.#",
			"#.....o..n..#",
			"#_#_#.o.#.#.#",
			"#._S_.ox....#",
			"#############",
		],
	},
	{
		"name": "Fading Lights",
		"tip": "Cyan stars fade after a while!\nWhen the bridge blinks, hurry\nacross, or blast a star again.",
		"crates": 0.36, "par": 110, "fade": [0.0, 12.0, 0.0],
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..n.....k..#",
			"#oooXooooooo#",
			"#.x....n....#",
			"#.#.#.#.#.#.#",
			"#...y.....x.#",
			"#oooooYooooo#",
			"#.......y..n#",
			"#.#.#.#.#.#.#",
			"#.........k.#",
			"#_#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "Crown of the Sky",
		"tip": "Three constellations! Cyan and\npink fade, gold stays. Light\nyour way up to the summit.",
		"crates": 0.38, "par": 120, "fade": [0.0, 11.0, 15.0],
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#..n..Q.n.E.#",
			"#.#.#qo.#.#.#",
			"#.....oq.k..#",
			"#oXooooooooo#",
			"#k....n.....#",
			"#.#.#.#.#.#.#",
			"#.x....k..x.#",
			"#.#.#.#.#y#.#",
			"#ooooooYoooo#",
			"#.#.#y#.#.#.#",
			"#.........n.#",
			"#_#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
	{
		"name": "The Star Owl",
		"tip": "The Star Owl dims the sky!\nRelight the stars from wherever\nyou stand. You can do it!",
		"crates": 0.15, "par": 150, "boss": true, "lit": [true, true, true],
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.....K.....#",
			"#.#.#x.x#.#.#",
			"#...ooXoo...#",
			"#.#qo...o.#.#",
			"#...Q...Q...#",
			"#.#.o...oq#.#",
			"#...ooYoo...#",
			"#.#.#y.y#.#.#",
			"#...........#",
			"#_#_#.#.#.#.#",
			"#._S_.......#",
			"#############",
		],
	},
]

var stars: Dictionary = {}     # Vector2i -> {"con", "lit", "node", "pop"}
var gaps: Dictionary = {}      # Vector2i -> constellation index, or -1
var cons: Array[Dictionary] = []
var _kittens: Dictionary = {}  # Critter -> {"mode", "t", "dir", "left"}
var _fly: Dictionary = {}
var _fly_cd: float = 7.0
var _owl_cd: float = 8.0
var _player: AudioStreamPlayer
var _snd_chime: AudioStreamWAV
var _snd_bridge: AudioStreamWAV
var _snd_fade: AudioStreamWAV
var _snd_hoot: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Starlight Summit"


func palette() -> Variant:
	return PALETTE


func music() -> String:
	return "res://audio/music/world_25.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "STAR OWL"


func boss_hp() -> int:
	return 10


func boss_minion_kind() -> StringName:
	if arena != null and arena.boss != null and arena.boss.hp <= 5:
		return &"kitten"
	return &"sprite"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	match ch:
		"x", "y", "q":
			stars[c] = {"con": "xyq".find(ch), "lit": false, "pop": 0.0}
		"X", "Y", "Q":
			gaps[c] = "XYQ".find(ch)
		"o":
			gaps[c] = -1
		_:
			return false
	return true


func critter_chars() -> Dictionary:
	return {"n": &"sprite", "k": &"kitten"}


func build_extra() -> void:
	var fades: Array = arena.data.get("fade", [0.0, 0.0, 0.0])
	var lit: Array = arena.data.get("lit", [false, false, false])
	for i in 3:
		cons.append({"stars": [], "bridges": [], "color": M.CON_COLORS[i], "fade": float(fades[i]),
			"on": false, "timer": 0.0, "fading": false, "lines": [], "used": false})
	for c: Vector2i in stars:
		(cons[int(stars[c]["con"])]["stars"] as Array).append(c)
	for c: Vector2i in gaps:
		if int(gaps[c]) >= 0:
			(cons[int(gaps[c])]["bridges"] as Array).append(c)
	_build_sky()
	for c: Vector2i in stars:
		var con: int = stars[c]["con"]
		var n: Node3D = M.star_node(M.CON_COLORS[con])
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		stars[c]["node"] = n
		_pose_star(c, false)
	for i in 3:
		var con: Dictionary = cons[i]
		if (con["stars"] as Array).is_empty() and (con["bridges"] as Array).is_empty():
			continue
		con["used"] = true
		var planks: Array = []
		var hints: Array = []
		for c: Vector2i in con["bridges"]:
			var along_x: bool = _bridge_along_x(c)
			var p: Node3D = M.bridge_plank(con["color"], along_x)
			p.position = Vector3(c.x, 0.0, c.y)
			p.visible = false
			arena.add_child(p)
			planks.append(p)
			var h: Node3D = M.bridge_hint(con["color"], along_x)
			h.position = Vector3(c.x, 0.0, c.y)
			arena.add_child(h)
			hints.append(h)
		con["planks"] = planks
		con["hints"] = hints
		con["grow"] = 0.0
		_build_lines(con)
		if bool(lit[i]):
			for s: Vector2i in con["stars"]:
				stars[s]["lit"] = true
				_pose_star(s, true)
			_switch_on(i, true)
	_build_clouds()
	_player = AudioStreamPlayer.new()
	_player.volume_db = -8.0
	arena.add_child(_player)
	_snd_chime = _make_chime()
	_snd_bridge = _make_bridge()
	_snd_fade = _make_fade()
	_snd_hoot = _make_hoot()


## A bridge cell runs between the two pieces of ground it joins.
func _bridge_along_x(c: Vector2i) -> bool:
	var con: int = gaps[c]
	for d: Vector2i in [Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + d
		if gaps.has(n) and int(gaps[n]) != con:
			return true
	return false


## The floor tiles over sky gaps are tucked away and replaced by windows
## onto the twilight sky far below.
func _build_sky() -> void:
	if gaps.is_empty():
		return
	var tile_mesh: ArrayMesh = Models.box_mesh(Vector3(0.96, 0.3, 0.96), 0.08)
	var hidden := Transform3D(Basis().scaled(Vector3.ONE * 0.0001), Vector3(0, -6, 0))
	for ch: Node in arena.get_children():
		var mmi := ch as MultiMeshInstance3D
		if mmi == null or mmi.multimesh == null or mmi.multimesh.mesh != tile_mesh:
			continue
		var mm: MultiMesh = mmi.multimesh
		for i in mm.instance_count:
			var tf: Transform3D = mm.get_instance_transform(i)
			if gaps.has(Vector2i(roundi(tf.origin.x), roundi(tf.origin.z))):
				mm.set_instance_transform(i, hidden)
	var windows: Array[Transform3D] = []
	var lips: Array[Transform3D] = []
	for c: Vector2i in gaps:
		windows.append(Transform3D(Basis(), Vector3(c.x, -0.07, c.y)))
		# A thin snowy lip where the summit floor meets the sky.
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = c + d
			if gaps.has(n) or arena.tile(n) == Arena.WALL:
				continue
			var along_x: bool = d.y != 0
			var b := Basis() if along_x else Basis(Vector3.UP, PI * 0.5)
			lips.append(Transform3D(b, Vector3(c.x + d.x * 0.47, 0.0, c.y + d.y * 0.47)))
	arena._multimesh(Models.box_mesh(Vector3(1.0, 0.1, 1.0), 0.0), Color.WHITE, windows, M.sky_material())
	arena._multimesh(Models.box_mesh(Vector3(0.96, 0.05, 0.06), 0.02), M.SNOW, lips)


## Thin glowing lines join the stars of a constellation (each star to its
## nearest earlier one), floating above them. Shown while it is lit.
func _build_lines(con: Dictionary) -> void:
	var list: Array = con["stars"]
	for i in range(1, list.size()):
		var a: Vector2i = list[i]
		var best: Vector2i = list[0]
		for j in i:
			var b: Vector2i = list[j]
			if Vector2(a - b).length() < Vector2(a - best).length():
				best = b
		var pa := Vector3(a.x, 0.72, a.y)
		var pb := Vector3(best.x, 0.72, best.y)
		if pa.distance_to(pb) > 3.6:
			continue
		var mi: MeshInstance3D = M.con_line(con["color"], pa.distance_to(pb) - 0.5)
		mi.position = (pa + pb) * 0.5
		mi.rotation.y = atan2(-(pb.z - pa.z), pb.x - pa.x)
		mi.visible = false
		arena.add_child(mi)
		(con["lines"] as Array).append(mi)


## A sea of soft clouds round the summit, below the board.
func _build_clouds() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 25
	var puffs_a: Array[Transform3D] = []
	var puffs_b: Array[Transform3D] = []
	for k in 40:
		var a: float = r.randf_range(-0.25, PI + 0.25)
		var dist: float = r.randf_range(12.0, 20.0)
		var p := Vector3(6.0 + cos(a) * dist, r.randf_range(-4.6, -3.6), 7.0 + sin(a) * dist)
		var s: float = r.randf_range(0.9, 1.6)
		var tf := Transform3D(Basis().scaled(Vector3(s * 1.6, s * 0.4, s)), p)
		(puffs_a if k % 3 != 0 else puffs_b).append(tf)
	arena._multimesh(Models.sphere(1.0, 2.0, 16), Color("#F5ECFF"), puffs_a)
	arena._multimesh(Models.sphere(1.0, 2.0, 16), Color("#FFE2C9"), puffs_b)


## Snow caps along the border wall, with a few glowing star flowers.
func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 3
	var caps: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	var stones: Array[Transform3D] = []
	for tf in blocks:
		var base: Vector3 = tf.origin
		caps.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.05, 0.05)), Vector3(base.x, 0.7, base.z)))
		if r.randf() < 0.14:
			flowers.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(base.x + r.randf_range(-0.2, 0.2), 0.82, base.z + r.randf_range(-0.2, 0.2))))
		elif r.randf() < 0.18:
			stones.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU), Vector3(base.x + r.randf_range(-0.2, 0.2), 0.8, base.z + r.randf_range(-0.2, 0.2))))
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.05), M.SNOW, caps)
	arena._multimesh(M.star_mesh(0.09, 0.05), M.GOLD, flowers, Models.mat(M.GOLD, 1.4))
	arena._multimesh(Models.box_mesh(Vector3(0.2, 0.12, 0.18), 0.05), M.PEDESTAL, stones)
	return true


## Solid blocks: twilight-blue rock with a snow cap; now and then a little
## golden crystal pokes out of the snow.
func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var lows: Array[Transform3D] = []
	var caps: Array[Transform3D] = []
	var crystals: Array[Transform3D] = []
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		var turn := Basis(Vector3.UP, r.randf_range(-0.08, 0.08))
		lows.append(Transform3D(turn, p + Vector3(0, 0.3, 0)))
		caps.append(Transform3D(turn, p + Vector3(0, 0.65, 0)))
		if r.randf() < 0.25:
			var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.3, 0.3))
			crystals.append(Transform3D(b, p + Vector3(r.randf_range(-0.18, 0.18), 0.78, r.randf_range(-0.18, 0.18))))
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.6, 0.84), 0.12), Color("#7C87C6"), lows)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.05), M.SNOW, caps)
	arena._multimesh(Models.box_mesh(Vector3(0.07, 0.2, 0.07), 0.025), M.GOLD, crystals, Models.mat(M.GOLD, 1.0))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.18:
			node = M.cairn(r)
		elif roll < 0.3:
			node = M.star_lantern(M.CON_COLORS[r.randi() % 3])
		elif roll < 0.36:
			node = M.pine(r)
			node.scale = Vector3.ONE * 0.7
	else:
		if roll < 0.24:
			node = M.pine(r)
		elif roll < 0.42:
			node = M.spire(r)
		elif roll < 0.48:
			node = M.telescope()
		elif roll < 0.56:
			node = M.star_lantern(M.CON_COLORS[r.randi() % 3])
		elif roll < 0.64:
			node = M.cairn(r)
	var holder := Node3D.new()
	if node != null:
		node.position = Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.12, 0.12))
		node.rotation.y = r.randf() * TAU
		holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	for k in 2:
		var s := M.spire(r)
		s.scale = Vector3.ONE * r.randf_range(1.6, 2.4)
		s.position = Vector3(r.randf_range(-0.3, 0.3) * size, 0, r.randf_range(-0.3, 0.3) * size)
		root.add_child(s)
	var p := M.pine(r)
	p.scale = Vector3.ONE * 1.4
	p.position = Vector3(size * 0.25, 0, size * 0.2)
	root.add_child(p)
	return root


func tune_environment(env: Environment, sun: DirectionalLight3D) -> void:
	sun.light_color = Color("#FFD9AE")
	env.adjustment_saturation = 1.05
	env.glow_intensity = 0.75


# --- Rules ------------------------------------------------------------------------

func bridged(c: Vector2i) -> bool:
	return gaps.has(c) and int(gaps[c]) >= 0 and bool(cons[int(gaps[c])]["on"])


func blocks(c: Vector2i) -> bool:
	return stars.has(c) or (gaps.has(c) and not bridged(c))


func flame_stop(c: Vector2i) -> int:
	return 1 if stars.has(c) else 0


func on_flame(c: Vector2i) -> void:
	if not stars.has(c):
		return
	var st: Dictionary = stars[c]
	var i: int = st["con"]
	var con: Dictionary = cons[i]
	if bool(con["on"]):
		# Topping a lit constellation's light back up.
		if float(con["fade"]) > 0.0 and not bool(con["fading"]):
			if float(con["timer"]) < float(con["fade"]) - 0.5:
				_sound(_snd_chime, 1.5)
				arena._spawn_sparkles(Vector3(c.x, 0.9, c.y), con["color"])
			con["timer"] = float(con["fade"])
		return
	if bool(st["lit"]):
		return
	st["lit"] = true
	st["pop"] = 0.35
	_pose_star(c, true)
	arena._spawn_sparkles(Vector3(c.x, 0.9, c.y), con["color"])
	var lit_count: int = 0
	for s: Vector2i in con["stars"]:
		if bool(stars[s]["lit"]):
			lit_count += 1
	_sound(_snd_chime, 1.0 + 0.12 * lit_count)
	if lit_count == (con["stars"] as Array).size():
		_switch_on(i, false)


func _pose_star(c: Vector2i, lit: bool) -> void:
	var n: Node3D = stars[c]["node"]
	var color: Color = M.CON_COLORS[int(stars[c]["con"])]
	var shape: MeshInstance3D = n.get_node("Star/Shape")
	shape.material_override = Models.mat(color, 1.5) if lit else Models.mat(M.STAR_OFF.lerp(color, 0.45), 0.15)
	(n.get_node("Star/Halo") as Node3D).visible = lit


func _switch_on(i: int, quiet: bool) -> void:
	var con: Dictionary = cons[i]
	con["on"] = true
	con["fading"] = false
	con["timer"] = float(con["fade"])
	con["grow"] = 0.0
	for p: Node3D in con.get("planks", []):
		p.visible = true
		p.scale = Vector3.ONE * 0.01
	for h: Node3D in con.get("hints", []):
		h.visible = false
	for l: Node3D in con["lines"]:
		l.visible = true
	if quiet:
		con["grow"] = 1.0
		for p2: Node3D in con.get("planks", []):
			p2.scale = Vector3.ONE
		return
	_sound(_snd_bridge, 1.0)
	Sfx.play(&"gate", 0.0)
	for c: Vector2i in con["bridges"]:
		arena._spawn_sparkles(Vector3(c.x, 0.2, c.y), con["color"])
	for s: Vector2i in con["stars"]:
		arena._spawn_ring(Vector3(s.x, 0.72, s.y), con["color"], 1.0)


func _switch_off(i: int) -> void:
	var con: Dictionary = cons[i]
	con["on"] = false
	con["fading"] = false
	for p: Node3D in con.get("planks", []):
		p.visible = false
	for h: Node3D in con.get("hints", []):
		h.visible = true
	for l: Node3D in con["lines"]:
		l.visible = false
	for s: Vector2i in con["stars"]:
		stars[s]["lit"] = false
		_pose_star(s, false)
		arena._spawn_sparkles(Vector3(s.x, 0.9, s.y), M.STAR_OFF)
	for c: Vector2i in con["bridges"]:
		arena._spawn_sparkles(Vector3(c.x, 0.1, c.y), con["color"])
	_sound(_snd_fade, 1.0)


## True while something is on (or stepping onto) one of the bridges.
func _bridge_busy(con: Dictionary) -> bool:
	for c: Vector2i in con["bridges"]:
		if arena.hero_alive and absf(arena.hero_pos.x - c.x) < 0.95 and absf(arena.hero_pos.y - c.y) < 0.95:
			return true
		if arena.pod_at.has(c):
			return true
		for cr: Arena.Critter in arena.critters:
			if cr.cell == c or cr.target == c:
				return true
	return false


func critter_can_enter(cr: Arena.Critter, c: Vector2i) -> bool:
	if stars.has(c):
		return false
	if gaps.has(c):
		if not bridged(c):
			return false
		var con: Dictionary = cons[int(gaps[c])]
		if float(con["timer"]) < BLINK and (float(con["fade"]) > 0.0 or bool(con["fading"])):
			return false
		if cr.kind == &"boss" and not _fly.is_empty():
			return false
	if cr.kind == &"boss" and not _fly.is_empty():
		return false
	return true


# --- Every frame ------------------------------------------------------------------

func process(delta: float) -> void:
	var clock: float = arena._clock
	for c: Vector2i in stars:
		var st: Dictionary = stars[c]
		var node: Node3D = st["node"]
		var star: Node3D = node.get_node("Star")
		var lit: bool = st["lit"]
		st["pop"] = maxf(float(st["pop"]) - delta, 0.0)
		var pop: float = float(st["pop"]) / 0.35
		star.scale = Vector3.ONE * (1.0 + sin(pop * PI) * 0.45)
		star.position.y = 0.72 + (sin(clock * 2.0 + c.x * 1.3) * 0.05 if lit else 0.0)
		star.rotation.y = sin(clock * 0.9 + c.y) * (0.5 if lit else 0.15)
		if lit:
			var halo: Node3D = star.get_node("Halo")
			halo.scale = Vector3.ONE * (1.0 + sin(clock * 3.0 + c.x) * 0.08)
	for i in cons.size():
		var con: Dictionary = cons[i]
		if not bool(con["used"]):
			continue
		if bool(con["on"]):
			_update_con(i, con, delta)
		else:
			for h: Node3D in con["hints"]:
				h.position.y = 0.01 + sin(clock * 2.0 + h.position.x) * 0.01
	if arena.demo:
		return
	_update_kittens(delta)
	_update_owl(delta)


func _update_con(i: int, con: Dictionary, delta: float) -> void:
	con["grow"] = minf(float(con["grow"]) + delta * 2.5, 1.0)
	var planks: Array = con["planks"]
	for k in planks.size():
		var p: Node3D = planks[k]
		var g: float = clampf(float(con["grow"]) * 1.6 - k * 0.15, 0.0, 1.0)
		var s: float = g * g * (3.0 - 2.0 * g)
		p.scale = Vector3(maxf(s, 0.01), 1.0, maxf(s, 0.01))
		p.position.y = sin(arena._clock * 1.6 + k) * 0.012
	var timed: bool = float(con["fade"]) > 0.0 or bool(con["fading"])
	if not timed:
		for p2: Node3D in planks:
			p2.visible = true
		return
	var before: float = con["timer"]
	con["timer"] = maxf(float(con["timer"]) - delta, 0.0)
	var t: float = con["timer"]
	if before >= BLINK and t < BLINK:
		_sound(_snd_fade, 1.4)
	var blink: bool = t < BLINK
	var show: bool = not blink or fmod(arena._clock, 0.3 if t > 1.0 else 0.16) < (0.2 if t > 1.0 else 0.09)
	for p3: Node3D in planks:
		p3.visible = show
	for l: Node3D in con["lines"]:
		l.visible = show
	if blink:
		for s2: Vector2i in con["stars"]:
			var halo: Node3D = (stars[s2]["node"] as Node3D).get_node("Star/Halo")
			halo.visible = show
	if t <= 0.0:
		if _bridge_busy(con):
			# Never pull a bridge from under Pip, a pod or a critter: wait.
			for p4: Node3D in planks:
				p4.visible = true
			return
		_switch_off(i)


# --- Comet Kittens --------------------------------------------------------------

func _kitten(cr: Arena.Critter) -> Dictionary:
	if not _kittens.has(cr):
		_kittens[cr] = {"mode": &"walk", "t": 0.0, "dir": Vector2i.ZERO, "left": 0}
	return _kittens[cr]


func _walk_speed() -> float:
	return 1.3 + 0.05 * arena.level_id


## Is Pip in a straight, clear line from [param cr], close enough to dash at?
func _line_to_hero(cr: Arena.Critter) -> Vector2i:
	if not arena.hero_alive or arena.state != &"play" or arena._clock < 4.0:
		return Vector2i.ZERO
	var hc: Vector2i = arena.hero_cell()
	var d: Vector2i = hc - cr.cell
	if (d.x != 0 and d.y != 0) or d == Vector2i.ZERO:
		return Vector2i.ZERO
	var n: int = absi(d.x) + absi(d.y)
	if n > DASH_RANGE:
		return Vector2i.ZERO
	var dir := Vector2i(signi(d.x), signi(d.y))
	for i in range(1, n):
		if not arena._critter_can_enter(cr, cr.cell + dir * i):
			return Vector2i.ZERO
	return dir


func _kitten_step(cr: Arena.Critter) -> Vector2i:
	var k: Dictionary = _kitten(cr)
	match k["mode"]:
		&"dash":
			var dir: Vector2i = k["dir"]
			k["left"] = int(k["left"]) - 1
			if int(k["left"]) > 0 and arena._critter_can_enter(cr, cr.cell + dir):
				return dir
			k["mode"] = &"rest"
			k["t"] = REST_TIME
			cr.speed = 0.05
			return Vector2i.ZERO
		&"walk":
			var line: Vector2i = _line_to_hero(cr)
			if line != Vector2i.ZERO and arena._critter_can_enter(cr, cr.cell + line):
				k["mode"] = &"wind"
				k["t"] = WIND_TIME
				k["dir"] = line
				k["left"] = DASH_RANGE + 2
				cr.speed = 0.02
				return line
	return Vector2i.ZERO


func _update_kittens(delta: float) -> void:
	for cr: Arena.Critter in _kittens.keys():
		if not arena.critters.has(cr):
			_kittens.erase(cr)
			continue
		var k: Dictionary = _kittens[cr]
		k["t"] = float(k["t"]) - delta
		match k["mode"]:
			&"wind":
				if float(k["t"]) <= 0.0:
					k["mode"] = &"dash"
					cr.speed = DASH_SPEED
					Sfx.play(&"whoosh", 0.1)
					arena._spawn_ring(Vector3(cr.pos.x, 0.06, cr.pos.y), M.COMET, 0.8)
			&"rest":
				if float(k["t"]) <= 0.0:
					k["mode"] = &"walk"
					cr.speed = _walk_speed()


# --- Critters ---------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"sprite":
			return M.sprite()
		&"kitten":
			return M.kitten()
		&"boss":
			return M.owl()
	return null


func critter_speed(kind: StringName) -> float:
	match kind:
		&"sprite":
			return 1.5 + 0.06 * arena.level_id
		&"kitten":
			return _walk_speed()
	return 1.5


func critter_smart(kind: StringName) -> bool:
	if kind == &"sprite":
		return arena.level_id >= 3
	return false


func critter_step(cr: Arena.Critter) -> Vector2i:
	match cr.kind:
		&"kitten":
			return _kitten_step(cr)
		&"sprite":
			# Sprites love a starlight bridge.
			for d: Vector2i in Arena.DIRS:
				var c: Vector2i = cr.cell + d
				if bridged(c) and d != -cr.dir and arena._critter_can_enter(cr, c) and arena.rng.randf() < 0.6:
					return d
	return Vector2i.ZERO


func critter_hidden(cr: Arena.Critter) -> bool:
	return cr.kind == &"boss" and not _fly.is_empty()


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, delta: float) -> Vector3:
	match cr.kind:
		&"sprite":
			var spin: Node3D = body.get_node("Spin")
			spin.position.y = 0.45 + sin(t * 3.0) * 0.07
			spin.rotation.z = sin(t * 2.0) * 0.25
			var halo: Node3D = body.get_node("Halo")
			halo.position.y = spin.position.y
			halo.scale = Vector3.ONE * (1.0 + sin(t * 5.0) * 0.1)
			return Vector3.ONE
		&"kitten":
			var k: Dictionary = _kitten(cr)
			var tail: Node3D = body.get_node("Tail")
			var mode: StringName = k["mode"]
			if mode == &"wind":
				# Crouch and wiggle: about to pounce.
				body.rotation.z = sin(t * 40.0) * 0.08
				tail.scale = Vector3.ONE * 1.3
				return Vector3(1.15, 0.8, 1.1)
			body.rotation.z = lerpf(body.rotation.z, 0.0, minf(delta * 10.0, 1.0))
			if mode == &"dash":
				tail.scale = Vector3(1.4, 1.4, 2.4)
				return Vector3(0.9, 0.95, 1.25)
			tail.scale = tail.scale.lerp(Vector3.ONE, minf(delta * 6.0, 1.0))
			tail.rotation.y = sin(t * 3.0) * 0.4
			var step: float = absf(sin(t * 9.0)) * 0.05 if cr.t < 1.0 else 0.0
			body.position.y = step
			return Vector3.ONE
		&"boss":
			var flying: bool = not _fly.is_empty()
			var flap: float = (sin(t * 12.0) * 0.6 + 0.9) if flying else sin(t * 1.8) * 0.08
			(body.get_node("WingL") as Node3D).rotation.z = lerpf((body.get_node("WingL") as Node3D).rotation.z, -flap, minf(delta * 12.0, 1.0))
			(body.get_node("WingR") as Node3D).rotation.z = lerpf((body.get_node("WingR") as Node3D).rotation.z, flap, minf(delta * 12.0, 1.0))
			var head: Node3D = body.get_node("Head")
			head.rotation.y = sin(t * 0.7) * 0.5
			(head.get_node("Crown") as Node3D).rotation.y += delta * 0.6
			return Vector3(1.0, 1.0 + sin(t * 2.4) * 0.03, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


# --- The Star Owl ------------------------------------------------------------------

func _update_owl(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or not arena.critters.has(b):
		if not _fly.is_empty():
			_end_marker()
			_fly = {}
		return
	if not _fly.is_empty():
		_update_flight(b, delta)
		return
	# From 7 hp the owl dims a constellation now and then; from 4 hp it also
	# lights another, rearranging the bridges, and flies about.
	if b.hp <= 7:
		_owl_cd -= delta
		if _owl_cd <= 0.0:
			_owl_cd = 8.0 if b.hp > 4 else 6.5
			_owl_dim(b)
	if b.hp <= 4:
		_fly_cd -= delta
		if _fly_cd <= 0.0:
			var to: Vector2i = _landing_cell(b)
			if to == Arena.NO_CELL:
				_fly_cd = 1.0
				return
			_fly = {"t": 0.0, "from": Vector3(b.pos.x, 0, b.pos.y), "to": to, "swapped": false}
			_fly["marker"] = _make_marker(to)
			_sound(_snd_hoot, 1.2)


func _owl_dim(b: Arena.Critter) -> void:
	var lit_ones: Array[int] = []
	var dark_ones: Array[int] = []
	for i in cons.size():
		if not bool(cons[i]["used"]) or (cons[i]["bridges"] as Array).is_empty():
			continue
		if bool(cons[i]["on"]) and not bool(cons[i]["fading"]):
			lit_ones.append(i)
		elif not bool(cons[i]["on"]):
			dark_ones.append(i)
	_sound(_snd_hoot, 1.0)
	(b.node.get_node("Body") as Node3D).scale = Vector3(1.15, 0.9, 1.15) * M.BOSS_SIZE
	arena._spawn_ring(Vector3(b.pos.x, 0.1, b.pos.y), Color("#E8E2FF"), 1.6)
	if not lit_ones.is_empty():
		var pick: int = lit_ones[arena.rng.randi() % lit_ones.size()]
		var con: Dictionary = cons[pick]
		con["fading"] = true
		con["timer"] = minf(float(con["timer"]), BLINK) if float(con["fade"]) > 0.0 else BLINK
		for s: Vector2i in con["stars"]:
			arena._spawn_sparkles(Vector3(s.x, 1.0, s.y), Color("#E8E2FF"))
	if b.hp <= 4 and not dark_ones.is_empty():
		var other: int = dark_ones[arena.rng.randi() % dark_ones.size()]
		for s2: Vector2i in cons[other]["stars"]:
			stars[s2]["lit"] = true
			stars[s2]["pop"] = 0.35
			_pose_star(s2, true)
		_switch_on(other, false)


func _update_flight(b: Arena.Critter, delta: float) -> void:
	_fly["t"] = float(_fly["t"]) + delta
	var tt: float = _fly["t"]
	var a: Vector3 = _fly["from"]
	var to: Vector2i = _fly["to"]
	var z := Vector3(to.x, 0, to.y)
	b.target = b.cell
	b.t = 1.0
	var pos: Vector3
	if tt < FLY_RISE:
		var k: float = tt / FLY_RISE
		pos = a + Vector3(0, FLY_HIGH * k * k, 0)
	elif tt < FLY_RISE + FLY_TIME:
		var k2: float = (tt - FLY_RISE) / FLY_TIME
		var e: float = k2 * k2 * (3.0 - 2.0 * k2)
		pos = a.lerp(z, e) + Vector3(0, FLY_HIGH + sin(k2 * PI) * 0.8, 0)
		if not bool(_fly["swapped"]) and k2 >= 0.5:
			_fly["swapped"] = true
			b.cell = to
			b.target = to
			b.pos = Vector2(to)
	elif tt < FLY_RISE + FLY_TIME + FLY_DROP:
		var k3: float = (tt - FLY_RISE - FLY_TIME) / FLY_DROP
		pos = z + Vector3(0, FLY_HIGH * (1.0 - k3) * (1.0 - k3), 0)
	else:
		b.cell = to
		b.target = to
		b.pos = Vector2(to)
		b.node.position = z
		_end_marker()
		_fly = {}
		_fly_cd = 7.0
		arena._spawn_ring(Vector3(to.x, 0.08, to.y), Color("#E8E2FF"), 1.5)
		arena._spawn_sparkles(Vector3(to.x, 0.4, to.y), M.CON_COLORS[arena.rng.randi() % 3])
		arena._shake = maxf(arena._shake, 0.25)
		(b.node.get_node("Body") as Node3D).scale = Vector3(1.3, 0.75, 1.3) * M.BOSS_SIZE
		Sfx.play(&"kick", 0.1)
		return
	b.node.position = pos
	var mk: Node3D = _fly.get("marker")
	if mk != null:
		mk.rotation.y += delta * 2.0
		mk.scale = Vector3.ONE * (1.0 + sin(arena._clock * 12.0) * 0.06)


## Somewhere Pip can walk to right now (so the owl is always in reach), clear
## of pods, flames and critters, and not right next to him.
func _landing_cell(b: Arena.Critter) -> Vector2i:
	if not arena.hero_alive:
		return Arena.NO_CELL
	var hc: Vector2i = arena.hero_cell()
	var seen: Dictionary = {hc: true}
	var queue: Array[Vector2i] = [hc]
	var options: Array[Vector2i] = []
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var far: int = absi(c.x - hc.x) + absi(c.y - hc.y)
		if far >= 3 and c != b.cell and not gaps.has(c) and not arena.pod_at.has(c) and not arena.flames.has(c) and c != arena.exit_cell:
			var taken: bool = false
			for cr: Arena.Critter in arena.critters:
				if cr != b and (cr.cell == c or cr.target == c):
					taken = true
					break
			if not taken:
				options.append(c)
		for d: Vector2i in Arena.DIRS:
			var n: Vector2i = c + d
			if seen.has(n) or arena.tile(n) != Arena.FLOOR or blocks(n):
				continue
			seen[n] = true
			queue.append(n)
	if options.is_empty():
		return Arena.NO_CELL
	return options[arena.rng.randi() % options.size()]


func _make_marker(c: Vector2i) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(c.x, 0.03, c.y)
	arena.add_child(root)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.32
	ring.outer_radius = 0.42
	ring.rings = 24
	ring.ring_segments = 4
	var mi := Models.part(root, ring, Color("#E8E2FF"), Vector3.ZERO, 1.2)
	mi.scale = Vector3(1.0, 0.25, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for k in 3:
		var s := Models.part(root, M.star_mesh(0.08, 0.04), M.CON_COLORS[k], Vector3.ZERO, 1.6)
		var a: float = TAU * k / 3.0
		s.position = Vector3(sin(a) * 0.37, 0.12, cos(a) * 0.37)
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


func _end_marker() -> void:
	var mk: Node3D = _fly.get("marker")
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


## A bright glockenspiel "ting": a star lights.
func _make_chime() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var f: float = 1046.5
		out[i] = (sin(TAU * f * t) * exp(-t * 3.0) + 0.4 * sin(TAU * f * 2.756 * t) * exp(-t * 8.0)) * minf(t / 0.002, 1.0) * 0.35
	return _wav(out)


## A rising, shimmering arpeggio: a starlight bridge appears.
func _make_bridge() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.3)
	var out := PackedFloat32Array()
	out.resize(n)
	var notes: Array[float] = [523.3, 659.3, 784.0, 1046.5, 1318.5]
	for i in n:
		var t: float = i / rate
		var v: float = 0.0
		for k in notes.size():
			var tt: float = t - k * 0.07
			if tt < 0.0:
				continue
			v += sin(TAU * notes[k] * tt) * exp(-tt * 3.5) * minf(tt / 0.003, 1.0)
		v += sin(TAU * 2093.0 * t) * sin(TAU * 7.0 * t) * exp(-t * 2.0) * 0.15
		out[i] = v * 0.18
	return _wav(out)


## A soft falling two-note sigh: a constellation dims.
func _make_fade() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.8)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t: float = i / rate
		var f: float = 880.0 if t < 0.18 else 659.3
		var tt: float = t if t < 0.18 else t - 0.18
		out[i] = sin(TAU * f * t) * exp(-tt * 5.0) * minf(tt / 0.004, 1.0) * 0.3
	return _wav(out)


## The owl's low "hoo-hoo".
func _make_hoot() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.9)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph: float = 0.0
	for i in n:
		var t: float = i / rate
		var seg: float = t if t < 0.35 else t - 0.4
		var on: float = 0.0
		if t < 0.35 or (t >= 0.4 and t < 0.9):
			var length: float = 0.35 if t < 0.35 else 0.5
			on = minf(seg / 0.05, 1.0) * minf((length - seg) / 0.08, 1.0)
		var f: float = (330.0 if t < 0.35 else 294.0) * (1.0 + 0.04 * sin(TAU * 5.0 * t))
		ph += TAU * f / rate
		out[i] = (sin(ph) + 0.25 * sin(ph * 2.0)) * maxf(on, 0.0) * 0.35
	return _wav(out)

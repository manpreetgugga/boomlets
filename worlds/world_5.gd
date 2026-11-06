extends WorldKit
## World 5, Neon Nightway: a friendly night-time city of glowing signs. The
## twist is light gates: glowing glass bars that stop Pip, pods, critters and
## blasts. Stepping on a switch of the same colour (or catching it in a
## blast) flips every gate of that colour, shut ones open and open ones shut.
## Zappers, little chrome robots, dash in straight lines and stop to look
## around. Gigabolt, the final boss, summons Zappers and, once hurt, sends
## power surges that flip every gate.
##
## Extra map characters:
##   G  gold gate, shut        g  gold gate, open        x  gold switch
##   P  pink gate, shut        p  pink gate, open        y  pink switch
##   j  Zapper

const M := preload("res://worlds/world_5_models.gd")

const GATE_CHARS: Dictionary = {"G": [0, true], "g": [0, false], "P": [1, true], "p": [1, false]}
const SWITCH_CHARS: Dictionary = {"x": 0, "y": 1}
const ZAP_SPEED: float = 3.3
const ZAP_RUN: int = 6
const SURGE_EVERY: float = 8.0
const SURGE_WARN: float = 1.4

const LEVELS: Array[Dictionary] = [
	{
		"name": "Switch On",
		"tip": "Glowing gates block the way.\nStep on the gold switch\nto flip them open!",
		"crates": 0.45, "par": 70,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b.........#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"###G#####G###",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#___x_S_____#",
			"#############",
		],
	},
	{
		"name": "Zip Zap Street",
		"tip": "Zappers dash in straight lines,\nthen stop to look around.\nBlasts flip switches too!",
		"crates": 0.45, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#...j.......#",
			"#.#.#.#.#.#.#",
			"#.....x.....#",
			"##G###g###G##",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b.......j.#",
			"#.#.#.#.#.#.#",
			"#.....x.....#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Two-Tone Plaza",
		"tip": "A switch opens shut gates\nbut shuts open ones!\nMix gold and pink to get through.",
		"crates": 0.4, "par": 90,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#.b...y...j.#",
			"#.#.#.#.#.#.#",
			"#####P#G#####",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.j.......b.#",
			"#.#.#.#.#.#.#",
			"#####p#g#####",
			"#...........#",
			"#.#.#_#_#.#.#",
			"#.x.._S_..y.#",
			"#############",
		],
	},
	{
		"name": "Barrel Boulevard",
		"tip": "Belts, barrels and gates!\nBarrel blasts flip switches too.",
		"crates": 0.4, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "shield": 1},
		"map": [
			"#############",
			"#.B...E...B.#",
			"#.#.#.#.#.#.#",
			"#...B...B...#",
			"#.#.#.#.#.#.#",
			"#.j...y...j.#",
			"###G#####P###",
			"#...........#",
			"#.#B#.#.#B#.#",
			"#..>>>>>>v..#",
			"#.#.#.#.#v#.#",
			"#.b..x...v..#",
			"#.#.#_#_#.#.#",
			"#y..._S_....#",
			"#############",
		],
	},
	{
		"name": "Rooftop Warps",
		"tip": "Warp pads hop across the rooftops.\nOpen a gate to reach the exit!",
		"crates": 0.42, "par": 105,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#2..#.E.#..1#",
			"#.#.#.#.#.#.#",
			"#...P...G.w.#",
			"#.#.#.#.#.#.#",
			"#.j.#...#...#",
			"###.#########",
			"#..z......j.#",
			"#.#.#.#.#.#.#",
			"#..y..b..x..#",
			"#.#.#.#.#.#.#",
			"#1.........2#",
			"#.#.#_#_#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Gigabolt's Tower",
		"tip": "Gigabolt powers the whole city!\nHit him with six blasts.\nWatch out for power surges!",
		"crates": 0.2, "par": 130, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1, "heart": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#....p.p....#",
			"#..#.....#..#",
			"#.....K.....#",
			"#.#..g.g..#.#",
			"#y....x....y#",
			"#.#..g.g..#.#",
			"#..#.....#..#",
			"#....p.p....#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]

## Vector2i -> {"ci": colour index, "shut": wants to be shut, "solid": shut
## and blocking (a shutting gate waits until nothing stands in it), "h":
## shown height 0..1, "node", "field"}.
var gates: Dictionary = {}
## Vector2i -> {"ci", "cool", "bump", "node"}.
var switches: Dictionary = {}
var _zap: Dictionary = {}     # Critter -> {"pause", "aim", "run"}
var _known: Dictionary = {}   # critters already seen (boss minions get swapped)
var _surge_t: float = -1.0
var _surge_warned: bool = false
var _clock: float = 0.0
var _player: AudioStreamPlayer
var _snd_flip: AudioStreamWAV
var _snd_warn: AudioStreamWAV


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "Neon Nightway"


func palette() -> Variant:
	var p: Dictionary = (Models.PALETTES["neon_night"] as Dictionary).duplicate()
	# Periwinkle glass crates, so they never look like the gold or pink gates.
	p["WOOD"] = "#C060FF"
	p["WOOD_DARK"] = "#FFD9F4"
	return p


func music() -> String:
	return "res://audio/music/world_5.wav"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "GIGABOLT"


# --- Building ---------------------------------------------------------------------

func parse_tile(ch: String, c: Vector2i) -> bool:
	if GATE_CHARS.has(ch):
		var spec: Array = GATE_CHARS[ch]
		gates[c] = {"ci": int(spec[0]), "shut": bool(spec[1]), "solid": bool(spec[1]), "h": 1.0 if spec[1] else 0.0}
		return true
	if SWITCH_CHARS.has(ch):
		switches[c] = {"ci": int(SWITCH_CHARS[ch]), "cool": 0.0, "bump": 0.0}
		return true
	return false


func critter_chars() -> Dictionary:
	return {"j": &"zapper"}


func build_extra() -> void:
	for c: Vector2i in gates:
		var g: Dictionary = gates[c]
		var n: Node3D = M.gate(g["ci"])
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		g["node"] = n
		g["field"] = n.get_node("Field")
		_show_gate(g)
	for c: Vector2i in switches:
		var s: Dictionary = switches[c]
		var n: Node3D = M.switch(s["ci"])
		n.position = Vector3(c.x, 0, c.y)
		arena.add_child(n)
		s["node"] = n
	for cr: Arena.Critter in arena.critters:
		_known[cr] = true
	_player = AudioStreamPlayer.new()
	_player.volume_db = -6.0
	arena.add_child(_player)
	_snd_flip = _make_flip()
	_snd_warn = _make_warn()


func build_wall_topper(blocks: Array[Transform3D]) -> bool:
	var w: int = Arena.W
	var h: int = Arena.H
	var top: Array[Transform3D] = []
	var near: Array[Transform3D] = []
	var sides: Array[Transform3D] = []
	var studs: Array[Transform3D] = []
	var bulbs: Array[Transform3D] = []
	var y: float = 0.705
	for tf in blocks:
		var x: int = roundi(tf.origin.x)
		var z: int = roundi(tf.origin.z)
		var at := Vector3(x, y, z)
		var corner: bool = (x == 0 or x == w - 1) and (z == 0 or z == h - 1)
		if corner:
			studs.append(Transform3D(Basis(), at + Vector3(0, 0.03, 0)))
			continue
		if z == 0:
			top.append(Transform3D(Basis(), at))
		elif z == h - 1:
			near.append(Transform3D(Basis(), at))
		else:
			sides.append(Transform3D(Basis(Vector3.UP, PI * 0.5), at))
		if (x + z) % 3 == 0:
			bulbs.append(Transform3D(Basis(), at + Vector3(0, 0.05, 0)))
	var strip := Models.box_mesh(Vector3(1.0, 0.045, 0.09), 0.015)
	arena._multimesh(strip, M.PINK, top, Models.mat(M.PINK, 1.5))
	arena._multimesh(strip, M.CYAN, near, Models.mat(M.CYAN, 1.3))
	arena._multimesh(strip, M.VIOLET, sides, Models.mat(M.VIOLET, 1.5))
	arena._multimesh(Models.box_mesh(Vector3(0.2, 0.1, 0.2), 0.03), M.GOLD, studs, Models.mat(M.GOLD, 1.6))
	arena._multimesh(Models.box_mesh(Vector3(0.11, 0.07, 0.11), 0.025), M.CHROME, bulbs, Models.mat(Color("#FFF6E0"), 1.4))
	return true


func build_solid_blocks(spots: Array[Transform3D]) -> bool:
	# Each solid block is a little server tower: a stacked body with glowing
	# LED bands, a lighter roof and a few status lights on the camera side.
	var r := RandomNumberGenerator.new()
	r.seed = hash(String(arena.data["name"])) + 11
	var bodies: Array[Transform3D] = []
	var roofs: Array[Transform3D] = []
	var bands: Array[Transform3D] = []
	var units: Array[Transform3D] = []
	var leds: Array[Array] = [[], [], []]
	for tf in spots:
		var p := Vector3(tf.origin.x, 0, tf.origin.z)
		bodies.append(Transform3D(Basis(), p + Vector3(0, 0.36, 0)))
		roofs.append(Transform3D(Basis(), p + Vector3(0, 0.74, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.27, 0)))
		bands.append(Transform3D(Basis(), p + Vector3(0, 0.53, 0)))
		for k in 3:
			if r.randf() < 0.7:
				(leds[r.randi() % 3] as Array).append(Transform3D(Basis(), p + Vector3(-0.22 + k * 0.11, 0.4, 0.41)))
		if r.randf() < 0.45:
			units.append(Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), p + Vector3(r.randf_range(-0.15, 0.15), 0.86, r.randf_range(-0.15, 0.1))))
	var body_c := Color("#6672CC")
	arena._multimesh(Models.box_mesh(Vector3(0.82, 0.72, 0.82), 0.08), body_c, bodies)
	arena._multimesh(Models.box_mesh(Vector3(0.9, 0.12, 0.9), 0.04), body_c.lightened(0.25), roofs)
	arena._multimesh(Models.box_mesh(Vector3(0.84, 0.035, 0.84), 0.012), M.CYAN, bands, Models.mat(M.CYAN, 1.0))
	arena._multimesh(Models.box_mesh(Vector3(0.3, 0.14, 0.26), 0.04), body_c.darkened(0.2), units)
	var led_colors: Array[Color] = [M.LIME, M.PINK, M.GOLD]
	var led_mesh := Models.box_mesh(Vector3(0.065, 0.065, 0.03), 0.012)
	for i in 3:
		var list: Array[Transform3D] = []
		list.assign(leds[i])
		arena._multimesh(led_mesh, led_colors[i], list, Models.mat(led_colors[i], 1.8))
	return true


func rim_prop(p: Vector3, r: RandomNumberGenerator, near_side: bool) -> Node3D:
	var roll: float = r.randf()
	var node: Node3D
	if near_side:
		if roll < 0.28:
			node = M.bollard([M.CYAN, M.PINK, M.GOLD][r.randi() % 3])
		elif roll < 0.42:
			node = M.planter(r)
	elif p.z < 0.0:
		if roll < 0.5:
			node = M.tower(r, 1.8)
		elif roll < 0.66:
			node = M.lamp([M.PINK, M.CYAN, M.WARM][r.randi() % 3])
		elif roll < 0.76:
			node = M.neon_sign(r)
	else:
		if roll < 0.2:
			node = M.tower(r, 1.1)
		elif roll < 0.38:
			node = M.lamp([M.PINK, M.CYAN, M.WARM][r.randi() % 3])
			node.rotation.y = 0.0 if p.x < 0.0 else PI
		elif roll < 0.48:
			node = M.neon_sign(r)
		elif roll < 0.6:
			node = M.planter(r)
	if node == null:
		return Node3D.new()
	var holder := Node3D.new()
	node.position = Vector3(r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
	holder.add_child(node)
	return holder


func far_island_prop(r: RandomNumberGenerator, size: float) -> Node3D:
	return M.city_cluster(r, size)


func tune_environment(env: Environment, _sun: DirectionalLight3D) -> void:
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95


# --- Rules --------------------------------------------------------------------------

func blocks(c: Vector2i) -> bool:
	return gates.has(c) and bool(gates[c]["shut"])


func flame_stop(c: Vector2i) -> int:
	if gates.has(c) and bool(gates[c]["solid"]):
		return 2
	return 0


func on_flame(c: Vector2i) -> void:
	if switches.has(c):
		_press(c)


func on_hero_enter(c: Vector2i) -> void:
	if switches.has(c):
		_press(c)


func critter_can_enter(_cr: Arena.Critter, c: Vector2i) -> bool:
	return not blocks(c)


func process(delta: float) -> void:
	_clock += delta
	for c: Vector2i in switches:
		_animate_switch(switches[c], delta)
	for c: Vector2i in gates:
		var g: Dictionary = gates[c]
		if g["shut"] and not g["solid"] and not _occupied(c):
			g["solid"] = true
			Sfx.play(&"snap", 0.1)
		_animate_gate(g, delta)
	if arena.demo:
		return
	for cr: Arena.Critter in arena.critters:
		if not _known.has(cr):
			_known[cr] = true
			if cr.kind == &"blobbit" and bool(arena.data.get("boss", false)):
				_make_zapper(cr)
	_update_zappers(delta)
	_update_surge(delta)


## Flips the gates of switch [param c]'s colour (once per blast or step).
func _press(c: Vector2i) -> void:
	var s: Dictionary = switches[c]
	if s["cool"] > 0.0:
		return
	s["cool"] = 0.35
	s["bump"] = 1.0
	arena._spawn_sparkles(Vector3(c.x, 0.3, c.y), M.GATE_COLORS[s["ci"]].lightened(0.3))
	_flip(int(s["ci"]))


func _flip(ci: int) -> void:
	for gc: Vector2i in gates:
		var g: Dictionary = gates[gc]
		if g["ci"] != ci:
			continue
		g["shut"] = not g["shut"]
		if not g["shut"]:
			g["solid"] = false
		arena._spawn_sparkles(Vector3(gc.x, 0.5, gc.y), M.GATE_COLORS[ci].lightened(0.35))
	_sound(_snd_flip, 1.0 if ci == 0 else 1.19)


## True while something stands in the gate at [param c], so it cannot shut.
func _occupied(c: Vector2i) -> bool:
	var a: Arena = arena
	if a.hero != null and absf(a.hero_pos.x - c.x) < 0.85 and absf(a.hero_pos.y - c.y) < 0.85:
		return true
	for cr: Arena.Critter in a.critters:
		if cr.cell == c or (cr.t < 1.0 and cr.target == c) or cr.pos.distance_to(Vector2(c)) < 0.85:
			return true
	if a.pod_at.has(c):
		return true
	for p: Arena.Pod in a.pods:
		if p.pos.distance_to(Vector2(c)) < 0.9:
			return true
	return false


func _animate_gate(g: Dictionary, delta: float) -> void:
	var target: float = 0.0
	if g["solid"]:
		target = 1.0
	elif g["shut"]:
		# Waiting to shut: a low flickering field.
		target = 0.22 + 0.08 * sin(_clock * 28.0)
	var warn: bool = _surge_t >= 0.0 and _surge_t < SURGE_WARN
	g["h"] = move_toward(float(g["h"]), target, delta * 5.0)
	var field: Node3D = g["field"]
	var hgt: float = float(g["h"])
	field.scale = Vector3(1.0, maxf(hgt, 0.001), 1.0)
	field.visible = hgt > 0.02 and not (warn and fmod(_clock, 0.2) < 0.07)
	field.position.y = 0.0


func _show_gate(g: Dictionary) -> void:
	var field: Node3D = g["field"]
	field.scale = Vector3(1.0, maxf(float(g["h"]), 0.001), 1.0)
	field.visible = float(g["h"]) > 0.02


func _animate_switch(s: Dictionary, delta: float) -> void:
	s["cool"] = maxf(float(s["cool"]) - delta, 0.0)
	s["bump"] = maxf(float(s["bump"]) - delta * 3.0, 0.0)
	var n: Node3D = s["node"]
	var button: Node3D = n.get_node("Button")
	var b: float = float(s["bump"])
	button.position.y = 0.06 - sin(b * PI) * 0.06
	var icon: Node3D = button.get_node("Icon")
	icon.rotation.y += delta * (1.0 + b * 14.0)
	var ring: Node3D = n.get_node("Ring")
	var pulse: float = 1.0 + sin(_clock * 3.0) * 0.04 + b * 0.35
	ring.scale = Vector3(pulse, 0.5, pulse)


# --- Critters -----------------------------------------------------------------------

func critter_model(kind: StringName) -> Node3D:
	match kind:
		&"zapper":
			return M.zapper()
		&"boss":
			return M.boss()
	return null


func critter_speed(kind: StringName) -> float:
	return ZAP_SPEED if kind == &"zapper" else 1.5


func critter_hp(_kind: StringName) -> int:
	return 1


func critter_step(cr: Arena.Critter) -> Vector2i:
	if cr.kind != &"zapper":
		return Vector2i.ZERO
	var z: Dictionary = _zap_state(cr)
	if z["pause"] > 0.0:
		return Vector2i.ZERO
	var ahead: Vector2i = cr.cell + cr.dir
	if int(z["run"]) < ZAP_RUN and arena._critter_can_enter(cr, ahead):
		z["run"] = int(z["run"]) + 1
		return cr.dir
	# Stop, look around, then pick the next line to dash along.
	z["run"] = 0
	z["pause"] = arena.rng.randf_range(0.7, 1.1)
	z["aim"] = _pick_heading(cr)
	return Vector2i.ZERO


func _zap_state(cr: Arena.Critter) -> Dictionary:
	if not _zap.has(cr):
		_zap[cr] = {"pause": 1.0, "aim": cr.dir, "run": 0}
	return _zap[cr]


func _pick_heading(cr: Arena.Critter) -> Vector2i:
	var open: Array[Vector2i] = []
	for d: Vector2i in Arena.DIRS:
		if arena._critter_can_enter(cr, cr.cell + d):
			open.append(d)
	if open.is_empty():
		return cr.dir
	if arena.hero != null and arena.hero_alive:
		var hc: Vector2i = arena.hero_cell()
		var to: Vector2i = hc - cr.cell
		if (to.x == 0) != (to.y == 0) and absi(to.x) + absi(to.y) <= 6:
			var d := Vector2i(signi(to.x), signi(to.y))
			if open.has(d) and arena.rng.randf() < 0.55:
				return d
	var turns: Array[Vector2i] = []
	for d: Vector2i in open:
		if d != cr.dir and d != -cr.dir:
			turns.append(d)
	if turns.is_empty():
		turns = open
	return turns[arena.rng.randi() % turns.size()]


func _update_zappers(delta: float) -> void:
	for cr: Arena.Critter in _zap.keys():
		if not arena.critters.has(cr):
			_zap.erase(cr)
			continue
		var z: Dictionary = _zap[cr]
		if z["pause"] <= 0.0:
			continue
		z["pause"] = float(z["pause"]) - delta
		cr.target = cr.cell
		cr.dir = z["aim"]
		if z["pause"] <= 0.0:
			cr.t = 1.0
		else:
			cr.t = 0.0
		cr.pos = Vector2(cr.cell)


func _make_zapper(cr: Arena.Critter) -> void:
	var old: Node3D = cr.node
	var n: Node3D = M.zapper()
	n.position = old.position
	n.scale = old.scale
	arena.add_child(n)
	old.queue_free()
	cr.node = n
	cr.kind = &"zapper"
	cr.custom = true
	cr.speed = ZAP_SPEED
	cr.hp = 1
	_zap_state(cr)


func pose_critter(cr: Arena.Critter, body: Node3D, t: float, _delta: float) -> Vector3:
	if cr.kind == &"zapper":
		var z: Dictionary = _zap_state(cr)
		var tip: Node3D = body.get_node("Head/Tip")
		if z["pause"] > 0.0:
			# Charging up: a jitter, a squash and a bright antenna.
			body.position = Vector3(sin(t * 60.0) * 0.012, 0.0, 0.0)
			body.rotation.x = lerpf(body.rotation.x, -0.08, 0.2)
			tip.scale = Vector3.ONE * (1.2 + sin(t * 20.0) * 0.4)
			return Vector3(1.06, 0.92, 1.06) * M.ZAP_SIZE
		body.position = Vector3(0.0, absf(sin(t * 14.0)) * 0.03, 0.0)
		body.rotation.x = lerpf(body.rotation.x, 0.16, 0.25)
		tip.scale = Vector3.ONE
		return Vector3.ONE * M.ZAP_SIZE
	if cr.kind == &"boss":
		var hurt: bool = cr.hp <= 3
		var arm_l: Node3D = body.get_node("ArmL")
		var arm_r: Node3D = body.get_node("ArmR")
		var swing: float = 0.35 if hurt else 0.22
		arm_l.rotation.x = sin(t * 4.0) * swing
		arm_r.rotation.x = -sin(t * 4.0) * swing
		var orb: Node3D = body.get_node("Head/Orb")
		var warn: bool = _surge_t >= 0.0 and _surge_t < SURGE_WARN
		orb.scale = Vector3.ONE * ((1.6 + sin(t * 30.0) * 0.5) if warn else (1.0 + sin(t * 3.0) * 0.15))
		var eyes: Node3D = body.get_node("Head/Eyes")
		var blink: bool = fmod(t, 3.7) < 0.12
		eyes.scale = Vector3(1.0, 0.15 if blink else 1.0, 1.0)
		var head: Node3D = body.get_node("Head")
		head.rotation.y = sin(t * 0.9) * 0.18
		return Vector3(1.0, 1.0 + absf(sin(t * 4.0)) * 0.05, 1.0) * M.BOSS_SIZE
	return Vector3.ONE


## In the boss fight's second half Gigabolt sends a power surge every few
## seconds (after a flicker warning) that flips every gate.
func _update_surge(delta: float) -> void:
	var b: Arena.Critter = arena.boss
	if b == null or b.hp > 3 or arena.state != &"play":
		_surge_t = -1.0
		return
	if _surge_t < 0.0:
		_surge_t = 3.0
		_surge_warned = false
	_surge_t -= delta
	if _surge_t < SURGE_WARN and not _surge_warned:
		_surge_warned = true
		_sound(_snd_warn, 1.0)
	if _surge_t <= 0.0:
		_surge_t = SURGE_EVERY
		_surge_warned = false
		_flip(0)
		_flip(1)
		arena._spawn_sparkles(arena._to3(b.pos, 1.6), M.LIME)
		arena._shake = maxf(arena._shake, 0.2)


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


## A bright two-step "zwip-zwing" for a gate flip.
func _make_flip() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 0.34)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		var f: float = 660.0 + 900.0 * minf(t / 0.07, 1.0) if t < 0.11 else 1320.0 + 440.0 * minf((t - 0.11) / 0.05, 1.0)
		phase += TAU * f / rate
		var env: float = minf(t / 0.005, 1.0) * (exp(-t * 9.0) if t < 0.11 else 1.4 * exp(-(t - 0.11) * 11.0))
		out[i] = (sin(phase) * 0.7 + sin(phase * 2.0) * 0.18 + (0.12 if sin(phase * 0.5) > 0.0 else -0.12)) * env * 0.5
	return _wav(out)


## A low wobbling hum that warns of a power surge.
func _make_warn() -> AudioStreamWAV:
	var rate: float = 22050.0
	var n: int = int(rate * 1.2)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase: float = 0.0
	for i in n:
		var t: float = i / rate
		phase += TAU * (180.0 + 160.0 * t) / rate
		var wob: float = 0.55 + 0.45 * sin(TAU * 9.0 * t)
		var env: float = minf(t / 0.05, 1.0) * minf((1.2 - t) / 0.15, 1.0)
		out[i] = clampf(sin(phase) * 2.2, -1.0, 1.0) * wob * env * 0.22
	return _wav(out)

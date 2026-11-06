extends RefCounted
## Models for World 25, Starlight Summit: a mountain top above the clouds at
## twilight. Star nodes on stone pedestals, starlight bridges, the sky-gap
## windows, Star Sprites, Comet Kittens, the Star Owl boss, and the summit
## props (snowy pines, rock spires, a brass telescope, cairns, star lanterns,
## clouds). Crisp, slightly rounded clay shapes like render/Models.gd.
## Loaded by path from world_25.gd (no class_name).

const SNOW := Color("#F3F5FF")
const ROCK := Color("#7480BC")
const ROCK_DARK := Color("#5A65A2")
const PEDESTAL := Color("#8A93C8")
const PEDESTAL_TOP := Color("#E7EAFF")
const STAR_OFF := Color("#C3C8E6")
const GOLD := Color("#FFCF6E")
const BRASS := Color("#E0A851")
const NAVY := Color("#1E2758")
const PINE := Color("#4F7FA6")
const PINE_DARK := Color("#3D6890")
const TRUNK := Color("#7B5E73")
const SPRITE := Color("#FFF0A6")
const SPRITE_GLOW := Color("#FFD45E")
const KITTEN := Color("#E3E9FF")
const KITTEN_EAR := Color("#FFB7D9")
const COMET := Color("#8FE6FF")
const OWL := Color("#6C62B6")
const OWL_DARK := Color("#4C4596")
const OWL_BELLY := Color("#ECE5FF")
const BEAK := Color("#FFC24D")
const INK := Color("#2A2550")
const BOSS_SIZE: float = 1.45
## Gold, cyan and pink constellations.
const CON_COLORS: Array[Color] = [Color("#FFD45E"), Color("#7FE3FF"), Color("#FF9AD5")]

static var _shapes: Dictionary = {}


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _eyes(body: Node3D, y: float, z: float, spread: float, size: float) -> void:
	for side: int in [-1, 1]:
		var eye := Models.part(body, Models.sphere(size, size * 2.2, 14), Models.WHITE, Vector3(side * spread, y, z))
		eye.scale = Vector3(1.0, 1.0, 0.6)
		var pupil := Models.part(body, Models.sphere(size * 0.55, -1, 12), INK, Vector3(side * spread, y - size * 0.1, z + size * 0.45))
		pupil.scale = Vector3(1.0, 1.15, 0.6)
		Models.part(body, Models.sphere(size * 0.16, -1, 8), Models.WHITE, Vector3(side * spread + size * 0.18, y + size * 0.2, z + size * 0.75), 1.0)


## A soft five-pointed star in the XY plane, extruded along Z.
static func star_mesh(outer: float = 0.26, depth: float = 0.11) -> ArrayMesh:
	var key: String = "star/%.3f/%.3f" % [outer, depth]
	if not _shapes.has(key):
		var pts := PackedVector2Array()
		for k in 10:
			var a: float = PI * 0.5 + TAU * k / 10.0
			var r: float = outer if k % 2 == 0 else outer * 0.47
			pts.append(Vector2(cos(a), sin(a)) * r)
		_shapes[key] = ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, outer * 0.12, 3), depth, depth * 0.35, 2)
	return _shapes[key]


static func _ring(inner: float, outer: float) -> TorusMesh:
	var ring := TorusMesh.new()
	ring.inner_radius = inner
	ring.outer_radius = outer
	ring.rings = 24
	ring.ring_segments = 4
	return ring


# --- Stars, bridges and the sky ------------------------------------------------------

## A star node: a round stone pedestal with a band in its constellation's
## colour, and above it a star ("Star/Shape") that glows when lit, with a
## halo ring ("Star/Halo").
static func star_node(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.36, 0.42, 0.34, 20), PEDESTAL, Vector3(0, 0.17, 0))
	Models.part(root, Models.cylinder(0.4, 0.4, 0.07, 20), color.darkened(0.05), Vector3(0, 0.3, 0), 0.25)
	Models.part(root, Models.cylinder(0.33, 0.36, 0.06, 20), PEDESTAL_TOP, Vector3(0, 0.37, 0))
	var star := Node3D.new()
	star.name = "Star"
	star.position = Vector3(0, 0.72, 0)
	root.add_child(star)
	var shape := Models.part(star, star_mesh(0.36, 0.14), STAR_OFF, Vector3.ZERO)
	shape.name = "Shape"
	var halo := _no_shadow(Models.part(star, _ring(0.4, 0.47), color, Vector3(0, 0, -0.03), 1.4)) as MeshInstance3D
	halo.rotation.x = PI * 0.5
	halo.name = "Halo"
	halo.visible = false
	return root


## One cell of a starlight bridge: a glowing plank with soft rails.
static func bridge_plank(color: Color, along_x: bool) -> Node3D:
	var root := Node3D.new()
	var plank := _no_shadow(Models.part(root, Models.box_mesh(Vector3(0.94, 0.07, 0.94), 0.03), color.lerp(Color.WHITE, 0.35), Vector3(0, 0.0, 0), 0.9))
	plank.name = "Plank"
	for side: int in [-1, 1]:
		var rail := _no_shadow(Models.part(root, Models.box_mesh(Vector3(0.96, 0.06, 0.06), 0.025), color, Vector3(0, 0.07, side * 0.43), 1.6))
		if not along_x:
			rail.rotation.y = PI * 0.5
			rail.position = Vector3(side * 0.43, 0.07, 0)
	for k in 3:
		var dot := _no_shadow(Models.part(root, Models.sphere(0.045, -1, 8), Color.WHITE, Vector3(0, 0.05, 0), 2.0))
		var off: float = (k - 1) * 0.3
		dot.position = Vector3(off, 0.05, 0) if along_x else Vector3(0, 0.05, off)
	return root


## Faint dotted hint of where a bridge will appear.
static func bridge_hint(color: Color, along_x: bool) -> Node3D:
	var root := Node3D.new()
	for k in 4:
		var off: float = (k - 1.5) * 0.24
		var dot := _no_shadow(Models.part(root, Models.sphere(0.035, 0.02, 8), color, Vector3.ZERO, 0.8))
		dot.position = Vector3(off, 0.0, 0) if along_x else Vector3(0, 0.0, off)
	return root


## The sky seen through a gap in the summit: deep twilight blue fading to
## warm gold far below, with twinkling stars and slow cloud wisps.
static func sky_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_back;
uniform vec4 top : source_color = vec4(0.12, 0.15, 0.36, 1.0);
uniform vec4 low : source_color = vec4(0.36, 0.3, 0.6, 1.0);
varying vec3 wp;
float hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 w = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), w.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), w.x), w.y);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = mod(TIME, 600.0);
	vec2 p = wp.xz;
	vec2 c = fract(p + 0.5) - 0.5;
	float edge = max(abs(c.x), abs(c.y));
	vec3 col = mix(top.rgb, low.rgb, smoothstep(0.1, 0.5, edge));
	// Twinkling stars.
	vec2 g = p * 7.0;
	vec2 id = floor(g);
	float h = hash(id);
	vec2 sp = fract(g) - 0.5 - (vec2(hash(id + 3.1), hash(id + 7.7)) - 0.5) * 0.6;
	float star = smoothstep(0.09, 0.0, length(sp)) * step(0.72, h);
	float tw = 0.55 + 0.45 * sin(t * (1.5 + h * 3.0) + h * 40.0);
	col += vec3(1.0, 0.95, 0.8) * star * tw * 1.3;
	// Slow cloud wisps drifting far below.
	float n = noise(p * 1.6 + vec2(t * 0.06, t * 0.02));
	col = mix(col, vec3(0.78, 0.74, 0.92), smoothstep(0.62, 0.9, n) * 0.35);
	// A soft rim of light where the summit floor ends.
	col += vec3(1.0, 0.85, 0.6) * smoothstep(0.38, 0.5, edge) * 0.25;
	ALBEDO = col;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## A thin glowing line between two stars of a lit constellation.
static func con_line(color: Color, length: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = Models.box_mesh(Vector3(length, 0.035, 0.035), 0.015)
	mi.material_override = Models.mat(color.lerp(Color.WHITE, 0.3), 1.8)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


# --- Critters ----------------------------------------------------------------------

## Star Sprite: a small round glowing star with a face, gliding over the
## floor and bridges. "Body/Spin" turns.
static func sprite() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.7, 0.25)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var spin := Node3D.new()
	spin.name = "Spin"
	spin.position = Vector3(0, 0.45, 0)
	spin.scale = Vector3.ONE * 1.25
	body.add_child(spin)
	var shape := Models.part(spin, star_mesh(0.34, 0.2), SPRITE, Vector3.ZERO, 0.6)
	shape.name = "Shape"
	var core := Models.part(spin, Models.sphere(0.17, -1, 16), SPRITE, Vector3.ZERO, 0.5)
	core.scale = Vector3(1.0, 1.0, 0.85)
	_eyes(spin, 0.03, 0.12, 0.07, 0.05)
	var mouth := Models.part(spin, Models.sphere(0.025, -1, 8), INK, Vector3(0, -0.05, 0.16))
	mouth.scale = Vector3(1.4, 0.7, 0.5)
	for side: int in [-1, 1]:
		var cheek := Models.part(spin, Models.sphere(0.03, -1, 8), Color("#FFB37A"), Vector3(side * 0.12, -0.03, 0.13))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	var halo := _no_shadow(Models.part(body, _ring(0.26, 0.3), SPRITE_GLOW, Vector3(0, 0.45, -0.05), 1.2)) as MeshInstance3D
	halo.rotation.x = PI * 0.5
	halo.name = "Halo"
	return root


## Comet Kitten: a round pale-blue kitten with pink ears and a glowing
## comet tail ("Body/Tail") that flares when it dashes.
static func kitten() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var torso := Models.part(body, Models.sphere(0.27, 0.42, 20), KITTEN, Vector3(0, 0.25, -0.06))
	torso.scale = Vector3(0.95, 1.0, 1.2)
	var head := Models.part(body, Models.sphere(0.24, 0.42, 20), KITTEN, Vector3(0, 0.46, 0.14))
	head.scale = Vector3(1.1, 0.95, 0.95)
	for side: int in [-1, 1]:
		var ear := Models.part(body, Models.cylinder(0.0, 0.1, 0.17, 4), KITTEN, Vector3(side * 0.14, 0.68, 0.1))
		ear.rotation.z = side * -0.3
		var inner := Models.part(body, Models.cylinder(0.0, 0.055, 0.1, 4), KITTEN_EAR, Vector3(side * 0.14, 0.67, 0.15))
		inner.rotation.z = side * -0.3
		var paw := Models.part(body, Models.sphere(0.07, 0.08, 10), Models.WHITE, Vector3(side * 0.13, 0.04, 0.12))
		paw.scale = Vector3(1.0, 1.0, 1.3)
	_eyes(body, 0.5, 0.33, 0.09, 0.06)
	var nose := Models.part(body, Models.sphere(0.025, -1, 8), KITTEN_EAR, Vector3(0, 0.43, 0.37))
	nose.scale = Vector3(1.3, 0.8, 0.8)
	for side: int in [-1, 1]:
		for k in 2:
			var wh := Models.part(body, Models.box_mesh(Vector3(0.14, 0.01, 0.01), 0.004), INK, Vector3(side * 0.24, 0.41 + k * 0.03, 0.3))
			wh.rotation.z = side * (0.12 - k * 0.25)
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, 0.32, -0.34)
	body.add_child(tail)
	for k in 4:
		var s: float = 0.12 - k * 0.022
		var puff := _no_shadow(Models.part(tail, Models.sphere(s, -1, 12), KITTEN.lerp(COMET, 0.4 + k * 0.2), Vector3(0, k * 0.03, -k * 0.13), 0.6 + k * 0.4))
		puff.name = "Puff%d" % k
	return root


## The Star Owl: a big round owl in twilight purple with a pale starry
## belly, broad wings ("WingL"/"WingR") dotted with stars, ear tufts, huge
## golden eyes and a crown of three little stars.
static func owl() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.5, 0.42)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var torso := Models.part(body, Models.sphere(0.48, 0.92, 26), OWL, Vector3(0, 0.55, 0))
	torso.scale = Vector3(1.0, 1.0, 0.92)
	var belly := Models.part(body, Models.sphere(0.34, 0.64, 20), OWL_BELLY, Vector3(0, 0.48, 0.2))
	belly.scale = Vector3(1.0, 1.0, 0.55)
	for k in 5:
		var a: float = -0.9 + k * 0.45
		var speck := _no_shadow(Models.part(body, Models.sphere(0.03, -1, 8), GOLD, Vector3(sin(a) * 0.2, 0.4 + (k % 2) * 0.12, 0.38), 1.6))
		speck.scale = Vector3(1, 1, 0.5)
	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.98, 0.02)
	body.add_child(head)
	var skull := Models.part(head, Models.sphere(0.36, 0.6, 24), OWL, Vector3.ZERO)
	skull.scale = Vector3(1.1, 1.0, 0.95)
	for side: int in [-1, 1]:
		var disc := Models.part(head, Models.sphere(0.16, 0.2, 18), OWL_BELLY, Vector3(side * 0.15, 0.0, 0.25))
		disc.scale = Vector3(1.0, 1.0, 0.4)
		var iris := _no_shadow(Models.part(head, Models.sphere(0.1, -1, 16), GOLD, Vector3(side * 0.15, 0.0, 0.31), 0.9))
		iris.scale = Vector3(1.0, 1.0, 0.5)
		var pupil := Models.part(head, Models.sphere(0.055, -1, 12), INK, Vector3(side * 0.15, 0.0, 0.36))
		pupil.scale = Vector3(1.0, 1.0, 0.5)
		Models.part(head, Models.sphere(0.018, -1, 6), Models.WHITE, Vector3(side * 0.15 + 0.025, 0.03, 0.38), 1.0)
		var tuft := Models.part(head, Models.cylinder(0.0, 0.09, 0.26, 6), OWL_DARK, Vector3(side * 0.26, 0.28, -0.02))
		tuft.rotation.z = side * -0.45
	var beak := Models.part(head, Models.cylinder(0.0, 0.06, 0.13, 8), BEAK, Vector3(0, -0.1, 0.33))
	beak.rotation.x = PI * 0.62
	var crown := Node3D.new()
	crown.name = "Crown"
	crown.position = Vector3(0, 0.36, 0)
	head.add_child(crown)
	Models.part(crown, Models.cylinder(0.16, 0.18, 0.06, 16), GOLD, Vector3.ZERO, 0.5)
	for k in 3:
		var s := _no_shadow(Models.part(crown, star_mesh(0.09 if k == 1 else 0.07, 0.05), CON_COLORS[k], Vector3((k - 1) * 0.13, 0.1 + (0.05 if k == 1 else 0.0), 0.0), 1.6))
		s.rotation.z = (1 - k) * 0.25
	for side: int in [-1, 1]:
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.42, 0.7, -0.02)
		body.add_child(wing)
		var w := Models.part(wing, Models.sphere(0.36, 0.7, 18), OWL_DARK, Vector3(side * 0.06, -0.12, 0.0))
		w.scale = Vector3(0.35, 1.0, 0.8)
		for k in 3:
			_no_shadow(Models.part(wing, Models.sphere(0.028, -1, 6), CON_COLORS[k], Vector3(side * 0.18, -0.02 - k * 0.14, 0.05 * (k - 1)), 1.8))
	for side: int in [-1, 1]:
		var foot := Models.part(body, Models.sphere(0.09, 0.08, 12), BEAK, Vector3(side * 0.16, 0.04, 0.2))
		foot.scale = Vector3(1.2, 1.0, 1.0)
	return root


# --- Props -----------------------------------------------------------------------

static func pine(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var s: float = r.randf_range(0.75, 1.1)
	Models.part(root, Models.cylinder(0.06, 0.08, 0.3, 8), TRUNK, Vector3(0, 0.15, 0))
	for k in 3:
		var w: float = (0.36 - k * 0.09) * s
		var col: Color = PINE if k % 2 == 0 else PINE_DARK
		Models.part(root, Models.cylinder(0.02, w, 0.36 * s, 10), col, Vector3(0, 0.36 + k * 0.24 * s, 0))
		var snow := Models.part(root, Models.cylinder(0.02, w * 0.62, 0.12 * s, 10), SNOW, Vector3(0, 0.47 + k * 0.24 * s, 0))
		snow.rotation.y = k
	return root


static func spire(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var h: float = r.randf_range(0.6, 1.2)
	var a := Models.part(root, Models.box_mesh(Vector3(0.42, h, 0.42), 0.1), ROCK, Vector3(0, h * 0.5, 0))
	a.rotation.y = r.randf() * TAU
	var cap := Models.part(root, Models.box_mesh(Vector3(0.46, 0.12, 0.46), 0.05), SNOW, Vector3(0, h + 0.02, 0))
	cap.rotation.y = a.rotation.y
	if r.randf() < 0.6:
		var b := Models.part(root, Models.box_mesh(Vector3(0.28, h * 0.6, 0.28), 0.07), ROCK_DARK, Vector3(0.28, h * 0.3, 0.12))
		b.rotation.y = r.randf() * TAU
	return root


## A little brass telescope on a tripod, pointed at the stars.
static func telescope() -> Node3D:
	var root := Node3D.new()
	for k in 3:
		var leg := Models.part(root, Models.cylinder(0.018, 0.022, 0.5, 6), TRUNK, Vector3.ZERO)
		var a: float = TAU * k / 3.0
		leg.position = Vector3(sin(a) * 0.1, 0.23, cos(a) * 0.1)
		leg.rotation = Vector3(cos(a) * 0.35, 0, -sin(a) * 0.35)
	var tube := Node3D.new()
	tube.position = Vector3(0, 0.5, 0)
	tube.rotation = Vector3(-0.7, 0.6, 0)
	root.add_child(tube)
	var body := Models.part(tube, Models.cylinder(0.06, 0.08, 0.5, 12), BRASS, Vector3(0, 0, 0.08))
	body.rotation.x = PI * 0.5
	var lens := Models.part(tube, Models.cylinder(0.075, 0.075, 0.04, 12), Color("#BFE8FF"), Vector3(0, 0, 0.34), 0.8)
	lens.rotation.x = PI * 0.5
	return root


static func cairn(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var y: float = 0.0
	for k in r.randi_range(3, 4):
		var s: float = 0.22 - k * 0.04
		var st := Models.part(root, Models.box_mesh(Vector3(s * 2.0, 0.12, s * 1.8), 0.05), PEDESTAL if k % 2 == 0 else PEDESTAL_TOP, Vector3(r.randf_range(-0.02, 0.02), y + 0.06, 0))
		st.rotation.y = r.randf() * TAU
		y += 0.11
	return root


## A stone lantern holding a little captured star.
static func star_lantern(color: Color) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.16, 0.42, 0.16), 0.05), PEDESTAL, Vector3(0, 0.21, 0))
	Models.part(root, Models.box_mesh(Vector3(0.32, 0.06, 0.32), 0.03), PEDESTAL_TOP, Vector3(0, 0.44, 0))
	var s := _no_shadow(Models.part(root, star_mesh(0.1, 0.06), color, Vector3(0, 0.58, 0), 2.0))
	s.rotation.y = 0.3
	var roof := Models.part(root, Models.cylinder(0.02, 0.18, 0.1, 4), ROCK_DARK, Vector3(0, 0.74, 0))
	roof.rotation.y = PI * 0.25
	return root


## A soft cloud: a cluster of flattened white puffs.
static func cloud(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	for k in r.randi_range(3, 5):
		var s: float = size * r.randf_range(0.3, 0.55)
		var puff := _no_shadow(Models.part(root, Models.sphere(s, s * 1.2, 14), Color("#F6EEFF").lerp(Color("#FFE3C4"), r.randf() * 0.5), Vector3(r.randf_range(-0.5, 0.5) * size, 0, r.randf_range(-0.35, 0.35) * size), 0.15))
		puff.scale = Vector3(1.3, 0.6, 1.0)
	return root

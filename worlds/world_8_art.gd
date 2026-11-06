extends RefCounted
## World 8, Gale Heights: models and decoration (windmills, kites, pennant
## flags, haybales, fences and Big Bluster the storm cloud). Static helpers
## only; world_8.gd preloads this script by path.

const CHALK := Color("#F3EEE3")
const CHALK_SHADE := Color("#DCD3C2")
const TUFT_A := Color("#9ED37A")
const TUFT_B := Color("#86C46A")
const MILL_WALL := Color("#FFF7EA")
const MILL_ROOF := Color("#F06A5E")
const MILL_SAIL := Color("#FFFDF8")
const MILL_WOOD := Color("#A9774E")
const HAY := Color("#F4CF6B")
const HAY_DARK := Color("#DDA94A")
const FENCE := Color("#C69466")
const CLOUD := Color("#AEB4E8")
const CLOUD_DARK := Color("#8A90D0")
const CLOUD_LIGHT := Color("#E2E5FA")
const BOLT := Color("#FFD84D")
const KITE_COLORS: Array[Color] = [Color("#FF5C6C"), Color("#FF9A3D"), Color("#B76BF0"), Color("#FF6FB5"), Color("#FFC93D")]
const FLAG_COLORS: Array[Color] = [Color("#FF6F6F"), Color("#FFC84D"), Color("#59B7F0"), Color("#FFFFFF")]


## A pennant pointing +X from the pole, as a thin extruded triangle.
static func pennant_mesh(length: float = 0.62, height: float = 0.34) -> ArrayMesh:
	var pts := PackedVector2Array([Vector2(0, height * 0.5), Vector2(0, -height * 0.5), Vector2(length, 0)])
	return ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.02), 0.025, 0.01, 1)


## A flag pole with a pennant under "Flag" (rotate "Flag" round Y so it
## points downwind; it points +X at yaw 0).
static func flag_pole(color: Color, height: float = 0.7) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.cylinder(0.025, 0.03, height, 6), MILL_WOOD, Vector3(0, height * 0.5, 0))
	Models.part(root, Models.sphere(0.045, -1, 8), Models.GOLD, Vector3(0, height + 0.03, 0), 0.2)
	var flag := Node3D.new()
	flag.name = "Flag"
	flag.position.y = height - 0.17
	root.add_child(flag)
	var cloth := Models.part(flag, pennant_mesh(), color, Vector3(0.02, 0, 0))
	cloth.name = "Cloth"
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## A four-sailed hub facing +Z (the sails turn round Z).
static func sails(parent: Node3D, radius: float, color: Color = MILL_SAIL) -> Node3D:
	var hub := Node3D.new()
	hub.name = "Sails"
	parent.add_child(hub)
	Models.part(hub, Models.cylinder(0.07, 0.07, 0.08, 8), MILL_WOOD, Vector3.ZERO).rotation.x = PI * 0.5
	for k in 4:
		var arm := Node3D.new()
		arm.rotation.z = TAU * k / 4.0 + PI * 0.25
		hub.add_child(arm)
		Models.part(arm, Models.box_mesh(Vector3(0.035, radius, 0.03), 0.01), MILL_WOOD, Vector3(0, radius * 0.5, 0.0))
		var sail := Models.part(arm, Models.box_mesh(Vector3(radius * 0.32, radius * 0.72, 0.025), 0.012), color, Vector3(radius * 0.17, radius * 0.6, 0.02))
		sail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Models.part(arm, Models.box_mesh(Vector3(radius * 0.33, 0.035, 0.03), 0.01), MILL_ROOF, Vector3(radius * 0.17, radius * 0.95, 0.03))
	return hub


## The windmill tile: a cream tower with a red roof, a door, sails turning
## on the camera side and a weathervane "Vane" (an arrow pointing +X at
## yaw 0) on top.
static func windmill() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 1.15, 0.35)
	Models.part(root, Models.box_mesh(Vector3(0.86, 0.14, 0.86), 0.05), Color("#C9A27A"), Vector3(0, 0.07, 0))
	var tower := Models.part(root, Models.cylinder(0.25, 0.34, 0.62, 8), MILL_WALL, Vector3(0, 0.45, 0))
	tower.rotation.y = PI / 8.0
	Models.part(root, Models.cylinder(0.28, 0.28, 0.06, 8), MILL_WOOD, Vector3(0, 0.77, 0)).rotation.y = PI / 8.0
	var roof := Models.part(root, Models.cylinder(0.0, 0.32, 0.34, 8), MILL_ROOF, Vector3(0, 0.97, 0))
	roof.rotation.y = PI / 8.0
	# Door and a round window.
	Models.part(root, Models.box_mesh(Vector3(0.18, 0.24, 0.06), 0.04), MILL_WOOD, Vector3(0, 0.26, 0.31))
	# The sails lean back toward the camera so they read from above.
	var front := Node3D.new()
	front.name = "Front"
	front.position = Vector3(0, 0.8, 0.28)
	front.rotation.x = -0.95
	root.add_child(front)
	sails(front, 0.44)
	# Weathervane.
	var vane := Node3D.new()
	vane.name = "Vane"
	vane.position = Vector3(0, 1.16, 0)
	root.add_child(vane)
	Models.part(vane, Models.cylinder(0.015, 0.015, 0.2, 6), Models.INK, Vector3(0, 0.0, 0))
	var arrow := PackedVector2Array([Vector2(-0.24, 0.06), Vector2(0.07, 0.06), Vector2(0.07, 0.13), Vector2(0.24, 0.0), Vector2(0.07, -0.13), Vector2(0.07, -0.06), Vector2(-0.24, -0.06)])
	var a := Models.part(vane, ClayShapes.extrusion(arrow, 0.035, 0.01, 1), Models.GOLD, Vector3(0, 0.1, 0), 0.35)
	a.rotation.x = -PI * 0.5
	return root


## A rim windmill: a taller, slimmer version of the tile one.
static func rim_windmill(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	Models.blob_shadow(root, 1.0, 0.3)
	var tower := Models.part(root, Models.cylinder(0.2, 0.3, 1.0, 8), MILL_WALL, Vector3(0, 0.5, 0))
	tower.rotation.y = PI / 8.0
	Models.part(root, Models.cylinder(0.0, 0.28, 0.34, 8), [MILL_ROOF, Color("#59B7F0"), Color("#9C7BEA")][r.randi() % 3], Vector3(0, 1.17, 0)).rotation.y = PI / 8.0
	Models.part(root, Models.box_mesh(Vector3(0.14, 0.22, 0.05), 0.03), MILL_WOOD, Vector3(0, 0.12, 0.27))
	var front := Node3D.new()
	front.name = "Front"
	front.position = Vector3(0, 0.92, 0.26)
	root.add_child(front)
	sails(front, 0.5)
	root.rotation.y = r.randf_range(-0.5, 0.5)
	return root


## A rolled haybale lying on its side.
static func haybale(r: RandomNumberGenerator, size: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.scale = Vector3.ONE * size
	var b := Models.part(root, Models.cylinder(0.2, 0.2, 0.3, 10), HAY, Vector3(0, 0.2, 0))
	b.rotation.z = PI * 0.5
	for s: int in [-1, 1]:
		var cap := Models.part(root, Models.cylinder(0.12, 0.12, 0.01, 10), HAY_DARK, Vector3(s * 0.151, 0.2, 0))
		cap.rotation.z = PI * 0.5
	root.rotation.y = r.randf() * TAU
	return root


## A short run of wooden fence.
static func fence(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	for k in 2:
		Models.part(root, Models.box_mesh(Vector3(0.07, 0.36, 0.07), 0.02), FENCE, Vector3(-0.3 + k * 0.6, 0.18, 0))
	for y: float in [0.13, 0.27]:
		Models.part(root, Models.box_mesh(Vector3(0.74, 0.05, 0.04), 0.015), FENCE.lightened(0.1), Vector3(0, y, 0.0))
	root.rotation.y = r.randf_range(-0.4, 0.4) + (PI * 0.5 if r.randf() < 0.3 else 0.0)
	return root


## Tall grass blades in a little clump ("Blades" sways).
static func grass(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var blades := Node3D.new()
	blades.name = "Blades"
	root.add_child(blades)
	for k in r.randi_range(4, 6):
		var h: float = r.randf_range(0.18, 0.34)
		var b := Models.part(blades, Models.box_mesh(Vector3(0.05, h, 0.03), 0.012), TUFT_A.lerp(TUFT_B, r.randf()), Vector3(r.randf_range(-0.13, 0.13), h * 0.5, r.randf_range(-0.1, 0.1)))
		b.rotation = Vector3(r.randf_range(-0.2, 0.2), r.randf() * TAU, r.randf_range(-0.25, 0.25))
	if r.randf() < 0.5:
		Models.part(blades, Models.sphere(0.04, -1, 8), [Color("#FFFFFF"), Color("#FFE27A"), Color("#FF8FA3")][r.randi() % 3], Vector3(0, 0.3, 0))
	return root


## A kite on a long string, flying high above a post. "Kite" bobs.
static func flying_kite(r: RandomNumberGenerator, height: float = 2.6) -> Node3D:
	var root := Node3D.new()
	Models.part(root, Models.box_mesh(Vector3(0.08, 0.3, 0.08), 0.02), FENCE, Vector3(0, 0.15, 0))
	var k := Node3D.new()
	k.name = "Kite"
	k.position = Vector3(0.5, height, -0.6)
	root.add_child(k)
	var col: Color = KITE_COLORS[r.randi() % KITE_COLORS.size()]
	_kite_sail(k, col, 0.42)
	# The string: a thin box from the post to the kite.
	var from := Vector3(0, 0.3, 0)
	var to: Vector3 = k.position
	var mid: Vector3 = (from + to) * 0.5
	var s := Models.part(root, Models.box_mesh(Vector3(0.012, (to - from).length(), 0.012), 0.004), Color("#FFFDF8"), mid)
	var dir: Vector3 = (to - from).normalized()
	var side: Vector3 = dir.cross(Vector3.FORWARD).normalized()
	s.basis = Basis(side, dir, side.cross(dir).normalized())
	s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


## A diamond kite sail facing +Z with its spars, about [param size] tall.
static func _kite_sail(parent: Node3D, col: Color, size: float) -> Node3D:
	var h: float = size
	var w: float = size * 0.72
	var pts := PackedVector2Array([Vector2(0, h * 0.62), Vector2(-w * 0.5, h * 0.12), Vector2(0, -h * 0.38), Vector2(w * 0.5, h * 0.12)])
	var sail := Models.part(parent, ClayShapes.extrusion(ClayShapes.rounded_polygon(pts, 0.04), 0.05, 0.02, 2), col, Vector3.ZERO)
	# Two light panels so the kite reads as a kite.
	var tri := PackedVector2Array([Vector2(0, h * 0.62), Vector2(-w * 0.5, h * 0.12), Vector2(0, h * 0.12)])
	Models.part(parent, ClayShapes.extrusion(ClayShapes.rounded_polygon(tri, 0.02), 0.052, 0.01, 1), col.lightened(0.45), Vector3(0, 0, 0.003))
	var tri2 := PackedVector2Array([Vector2(0, -h * 0.38), Vector2(w * 0.5, h * 0.12), Vector2(0, h * 0.12)])
	Models.part(parent, ClayShapes.extrusion(ClayShapes.rounded_polygon(tri2, 0.02), 0.052, 0.01, 1), col.lightened(0.45), Vector3(0, 0, 0.003))
	Models.part(parent, Models.box_mesh(Vector3(0.025, h * 0.98, 0.03), 0.008), MILL_WOOD, Vector3(0, h * 0.12, -0.03))
	Models.part(parent, Models.box_mesh(Vector3(w * 0.96, 0.025, 0.03), 0.008), MILL_WOOD, Vector3(0, h * 0.12, -0.03))
	return sail


## The Kite critter: a diamond kite with a face, flying a little above the
## floor, with a bow-tie tail ("Rig/Tail/Bow0..2") that flutters.
static func kite(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.85, 0.3)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var rig := Node3D.new()
	rig.name = "Rig"
	rig.position.y = 0.5
	rig.rotation.x = -0.95
	rig.scale = Vector3.ONE * 1.45
	body.add_child(rig)
	var col: Color = KITE_COLORS[r.randi() % KITE_COLORS.size()]
	_kite_sail(rig, col, 0.62)
	var face := Node3D.new()
	face.position = Vector3(0, 0.1, 0.03)
	rig.add_child(face)
	Models._eyes(face, 0.03, 0.0, 0.085, 0.06)
	for side: int in [-1, 1]:
		var cheek := Models.part(face, Models.sphere(0.035, -1, 8), Color("#FF9AA8"), Vector3(side * 0.15, -0.04, 0.02))
		cheek.scale = Vector3(1.0, 0.6, 0.4)
	Models.part(face, Models.box_mesh(Vector3(0.06, 0.025, 0.02), 0.008), Models.INK, Vector3(0, -0.06, 0.03))
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, -0.24, -0.02)
	rig.add_child(tail)
	var prev: Node3D = tail
	for k in 3:
		var bow := Node3D.new()
		bow.name = "Bow%d" % k
		bow.position = Vector3(0, -0.07 if k == 0 else -0.13, 0)
		prev.add_child(bow)
		Models.part(bow, Models.box_mesh(Vector3(0.012, 0.13, 0.012), 0.004), Color("#FFFDF8"), Vector3(0, 0.06, 0))
		var bc: Color = KITE_COLORS[(r.randi() + k) % KITE_COLORS.size()]
		for s: int in [-1, 1]:
			var wing := Models.part(bow, Models.cylinder(0.0, 0.045, 0.08, 4), bc, Vector3(s * 0.04, 0, 0))
			wing.rotation.z = s * PI * 0.5
		prev = bow
	return root


## Big Bluster, the boss: a chunky storm cloud of rounded blocks with puffed
## cheeks ("Rig/Cheeks"), a little round blowing mouth ("Rig/Mouth"), angry
## brows and a lightning-bolt crown. Floats over the floor.
static func cloud_boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.0, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var rig := Node3D.new()
	rig.name = "Rig"
	rig.position.y = 0.45
	rig.rotation.x = -0.5
	rig.scale = Vector3.ONE * 1.3
	body.add_child(rig)
	var puffs: Array = [
		[Vector3(0, 0.45, 0), Vector3(1.2, 0.8, 0.9), CLOUD],
		[Vector3(-0.55, 0.35, 0.02), Vector3(0.62, 0.58, 0.74), CLOUD],
		[Vector3(0.55, 0.35, 0.02), Vector3(0.62, 0.58, 0.74), CLOUD],
		[Vector3(-0.22, 0.88, -0.05), Vector3(0.62, 0.48, 0.66), CLOUD_LIGHT],
		[Vector3(0.28, 0.82, -0.08), Vector3(0.54, 0.42, 0.6), CLOUD_LIGHT],
		[Vector3(0, 0.08, 0), Vector3(1.0, 0.24, 0.72), CLOUD_DARK],
	]
	for p: Array in puffs:
		var s: Vector3 = p[1]
		var m := Models.part(rig, Models.box_mesh(s, minf(minf(s.x, s.y), s.z) * 0.32), p[2], p[0])
		m.rotation.y = 0.0
	var face := Node3D.new()
	face.name = "Face"
	face.position = Vector3(0, 0.5, 0.46)
	face.rotation.x = -0.3
	rig.add_child(face)
	Models._eyes(face, 0.08, 0.0, 0.21, 0.125, true)
	var cheeks := Node3D.new()
	cheeks.name = "Cheeks"
	face.add_child(cheeks)
	for side: int in [-1, 1]:
		var c := Models.part(cheeks, Models.sphere(0.1, -1, 12), Color("#FF9AB4"), Vector3(side * 0.36, -0.1, 0.0))
		c.scale = Vector3(1.0, 0.7, 0.45)
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0, -0.15, 0.03)
	face.add_child(mouth)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.035
	ring.outer_radius = 0.07
	ring.rings = 12
	ring.ring_segments = 6
	var mr := Models.part(mouth, ring, Models.INK, Vector3.ZERO)
	mr.rotation.x = PI * 0.5
	# Lightning-bolt crown.
	var crown := Node3D.new()
	crown.position = Vector3(0, 1.08, 0.0)
	rig.add_child(crown)
	var bolt := PackedVector2Array([Vector2(0.03, 0.2), Vector2(-0.08, 0.0), Vector2(-0.01, 0.0), Vector2(-0.05, -0.18), Vector2(0.09, 0.04), Vector2(0.02, 0.04)])
	for k in 3:
		var b := Models.part(crown, ClayShapes.extrusion(bolt, 0.05, 0.012, 1), BOLT, Vector3(-0.22 + k * 0.22, 0.1 + (0.06 if k == 1 else 0.0), 0), 0.5)
		b.rotation.z = (k - 1) * -0.3
	# Little rain-drop feet.
	for k in 3:
		var d := Models.part(rig, Models.cylinder(0.0, 0.07, 0.16, 6), Color("#7FC6F0"), Vector3(-0.35 + k * 0.35, -0.12, 0.1))
		d.rotation.x = PI
	return root

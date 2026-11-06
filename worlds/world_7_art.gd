extends RefCounted
## Models for World 7, Prism Caverns: crystal mirrors and prisms, the
## Crystal Bat, the Geode Golem boss and the pastel crystal-cave props.
## Crisp, slightly rounded clay blocks and frosted-glass crystals.

const MINT := Color("#8FE8C8")
const AQUA := Color("#7FD8F0")
const PINK := Color("#FF9BCB")
const LEMON := Color("#FFE58A")
const LILAC := Color("#C7B2F4")
const PEACH := Color("#FFC2A0")
const STONE := Color("#D9CCF2")
const STONE_DARK := Color("#B7A6E3")
const GOLD := Color("#F4C55A")
const BLOCK := Color("#A98FE6")
const PAD := Color("#6FD6E8")
const GOLEM := Color("#9585DE")
const GOLEM_DARK := Color("#7262C4")
const SILVER := Color("#EAF6FF")
const INK := Color("#2E2A4A")
const RAINBOW: Array[Color] = [Color("#FF8FB8"), Color("#FFD36E"), Color("#8FE8B0"), Color("#7FC8F8"), Color("#B79CF5")]
const BOSS_SIZE: float = 1.2
const BAT_SIZE: float = 1.35
const BAT := Color("#3CB6EC")
const BAT_WING := Color("#C88AF2")

static var _shapes: Dictionary = {}


static func _box(size: Vector3, r: float) -> ArrayMesh:
	return Models.box_mesh(size, r)


static func _no_shadow(mi: GeometryInstance3D) -> GeometryInstance3D:
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func crystal_mat(color: Color, glow: float = 0.25) -> Material:
	if Models.GLASS:
		return Models.glass(color, 0.55, glow)
	return Models.mat(color, glow)


## A pointed six-sided crystal standing on y = 0, [param h] tall.
static func crystal(parent: Node3D, color: Color, at: Vector3, h: float, r: float, tilt: Vector3 = Vector3.ZERO, glow: float = 0.25) -> Node3D:
	var n := Node3D.new()
	n.position = at
	n.rotation = tilt
	parent.add_child(n)
	var shaft := MeshInstance3D.new()
	shaft.mesh = Models.cylinder(r, r, h * 0.72, 6)
	shaft.material_override = crystal_mat(color, glow)
	shaft.position.y = h * 0.36
	n.add_child(shaft)
	var tip := MeshInstance3D.new()
	tip.mesh = Models.cylinder(0.0, r, h * 0.28, 6)
	tip.material_override = crystal_mat(color.lightened(0.15), glow)
	tip.position.y = h * 0.86
	n.add_child(tip)
	return n


static func pedestal(parent: Node3D) -> void:
	Models.part(parent, _box(Vector3(0.9, 0.14, 0.9), 0.05), BLOCK.darkened(0.1), Vector3(0, 0.07, 0))
	_no_shadow(Models.part(parent, _box(Vector3(0.74, 0.06, 0.74), 0.025), PAD, Vector3(0, 0.16, 0), 0.6))


# --- Optics -------------------------------------------------------------------------

## A crystal mirror on a pedestal: a silver pane in a gold frame set
## diagonally, "/" (bottom-left to top-right as seen from the camera) or
## "\\". Its "Shine" streak can be flashed when a blast bounces off it.
static func mirror(kind: String) -> Node3D:
	var root := Node3D.new()
	pedestal(root)
	var pane := Node3D.new()
	pane.name = "Pane"
	pane.rotation.y = PI * 0.25 if kind == "/" else -PI * 0.25
	root.add_child(pane)
	Models.part(pane, _box(Vector3(1.22, 0.74, 0.24), 0.06), GOLD, Vector3(0, 0.54, 0))
	var glass := Models.part(pane, _box(Vector3(1.08, 0.6, 0.27), 0.04), SILVER, Vector3(0, 0.54, 0), 0.35)
	# A bright line along the top so the slant reads from above.
	_no_shadow(Models.part(pane, _box(Vector3(1.12, 0.04, 0.1), 0.02), Color.WHITE, Vector3(0, 0.92, 0), 1.4))
	glass.name = "Glass"
	# Blue sheen on both faces and a bright diagonal glint.
	for side: int in [-1, 1]:
		_no_shadow(Models.part(pane, _box(Vector3(0.96, 0.5, 0.02), 0.01), AQUA.lightened(0.35), Vector3(0, 0.54, side * 0.14), 0.5))
		var glint := Models.part(pane, _box(Vector3(0.07, 0.56, 0.02), 0.01), Color.WHITE, Vector3(-0.2, 0.54, side * 0.152), 1.2)
		glint.rotation.z = 0.5
		glint.name = "Shine" if side > 0 else "Shine2"
		_no_shadow(glint)
	# A gem on each frame end.
	for sx: int in [-1, 1]:
		_no_shadow(Models.part(pane, Models.sphere(0.07, -1, 8), PINK if sx < 0 else MINT, Vector3(sx * 0.62, 0.9, 0), 0.6))
	return root


## A rainbow prism on a pedestal: a clear three-sided crystal ("Spin") with
## rainbow bands, that splits a blast three ways.
static func prism() -> Node3D:
	var root := Node3D.new()
	pedestal(root)
	var spin := Node3D.new()
	spin.name = "Spin"
	spin.position.y = 0.18
	root.add_child(spin)
	var body := MeshInstance3D.new()
	body.mesh = Models.cylinder(0.38, 0.38, 0.78, 3)
	body.material_override = crystal_mat(Color("#F4F0FF"), 0.35)
	body.position.y = 0.41
	spin.add_child(body)
	for k in RAINBOW.size():
		var band := Models.part(spin, Models.cylinder(0.395, 0.395, 0.045, 3), RAINBOW[k], Vector3(0, 0.22 + k * 0.075, 0), 0.8)
		_no_shadow(band)
	var cap := Models.part(spin, Models.cylinder(0.0, 0.32, 0.2, 3), Color("#FFFFFF"), Vector3(0, 0.9, 0), 0.6)
	_no_shadow(cap)
	_no_shadow(Models.part(root, Models.sphere(0.06, -1, 8), LEMON, Vector3(0, 1.22, 0), 1.6)).name = "Spark"
	return root


# --- Critters -----------------------------------------------------------------------

## The Crystal Bat: a faceted gem body with frosted wings ("WingL"/"WingR"),
## pointed ears and big eyes. Flutters in zig-zags.
static func bat() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 0.8, 0.26)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var fly := Node3D.new()
	fly.name = "Fly"
	fly.position.y = 0.42
	body.add_child(fly)
	var gem := MeshInstance3D.new()
	var s := Models.sphere(0.24, -1, 7)
	s.rings = 4
	gem.mesh = s
	gem.material_override = Models.mat(BAT, 0.25)
	gem.scale = Vector3(1.0, 0.95, 0.9)
	fly.add_child(gem)
	var belly := Models.part(fly, Models.sphere(0.16, -1, 7), MINT.lightened(0.4), Vector3(0, -0.04, 0.12), 0.2)
	belly.scale = Vector3(1, 1, 0.6)
	Models._eyes(fly, 0.04, 0.17, 0.085, 0.06)
	for side: int in [-1, 1]:
		var ear := Models.part(fly, Models.cylinder(0.0, 0.07, 0.16, 4), PINK, Vector3(side * 0.12, 0.25, -0.02), 0.2)
		ear.rotation.z = side * -0.3
		var wing := Node3D.new()
		wing.name = "WingL" if side < 0 else "WingR"
		wing.position = Vector3(side * 0.2, 0.04, -0.02)
		fly.add_child(wing)
		var pts := PackedVector2Array([Vector2(0, 0.08), Vector2(0.42, 0.14), Vector2(0.36, 0.0), Vector2(0.28, -0.08), Vector2(0.18, -0.02), Vector2(0.08, -0.1), Vector2(0, -0.04)])
		if side < 0:
			for i in pts.size():
				pts[i].x = -pts[i].x
		else:
			pts.reverse()
		var w := MeshInstance3D.new()
		w.mesh = ClayShapes.extrusion(pts, 0.03, 0.01, 1)
		w.material_override = crystal_mat(BAT_WING, 0.3)
		w.rotation.x = -PI * 0.5
		wing.add_child(w)
	# Little fangs.
	for side: int in [-1, 1]:
		_no_shadow(Models.part(fly, Models.cylinder(0.0, 0.018, 0.04, 4), Color.WHITE, Vector3(side * 0.035, -0.08, 0.2))).rotation.x = PI
	return root


## The Geode Golem: a chunky lilac stone golem with crystals growing from its
## shoulders, glowing eyes and a big crystal "Shield" on its "Pivot" (turned
## by the world to face Pip, independent of the way it walks).
static func boss() -> Node3D:
	var root := Node3D.new()
	Models.blob_shadow(root, 2.1, 0.45)
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3.ONE * BOSS_SIZE
	root.add_child(body)
	for side: int in [-1, 1]:
		Models.part(body, _box(Vector3(0.3, 0.32, 0.4), 0.1), GOLEM_DARK, Vector3(side * 0.26, 0.16, 0.02))
	Models.part(body, _box(Vector3(0.98, 0.72, 0.74), 0.2), GOLEM, Vector3(0, 0.66, 0))
	# A geode window in the chest.
	var geo := Models.part(body, Models.cylinder(0.2, 0.2, 0.06, 6), PINK, Vector3(0, 0.66, 0.37), 0.8)
	geo.rotation.x = PI * 0.5
	geo.name = "Core"
	_no_shadow(Models.part(body, Models.cylinder(0.25, 0.25, 0.04, 6), GOLEM_DARK, Vector3(0, 0.66, 0.355))).rotation.x = PI * 0.5
	var head := Node3D.new()
	head.name = "Head"
	head.position.y = 1.16
	body.add_child(head)
	Models.part(head, _box(Vector3(0.62, 0.4, 0.52), 0.14), GOLEM, Vector3.ZERO)
	for side: int in [-1, 1]:
		var eye := Models.part(head, _box(Vector3(0.12, 0.1, 0.04), 0.03), AQUA, Vector3(side * 0.14, 0.02, 0.26), 2.0)
		_no_shadow(eye)
		var brow := Models.part(head, _box(Vector3(0.18, 0.05, 0.06), 0.02), GOLEM_DARK, Vector3(side * 0.14, 0.12, 0.25))
		brow.rotation.z = side * -0.3
	crystal(head, LEMON, Vector3(0.0, 0.18, -0.02), 0.4, 0.09, Vector3(0, 0, 0))
	crystal(head, PINK, Vector3(-0.17, 0.16, 0.02), 0.28, 0.07, Vector3(0, 0, 0.4))
	crystal(head, MINT, Vector3(0.17, 0.16, 0.02), 0.28, 0.07, Vector3(0, 0, -0.4))
	# Shoulders with crystals, and arms.
	for side: int in [-1, 1]:
		crystal(body, AQUA if side < 0 else PINK, Vector3(side * 0.42, 0.96, -0.05), 0.5, 0.1, Vector3(0, 0, side * -0.5))
		crystal(body, LILAC, Vector3(side * 0.3, 1.0, -0.2), 0.34, 0.07, Vector3(-0.3, 0, side * -0.3))
		var arm := Node3D.new()
		arm.name = "ArmL" if side < 0 else "ArmR"
		arm.position = Vector3(side * 0.6, 0.86, 0.02)
		body.add_child(arm)
		Models.part(arm, _box(Vector3(0.28, 0.28, 0.28), 0.09), GOLEM_DARK, Vector3.ZERO)
		Models.part(arm, _box(Vector3(0.26, 0.5, 0.28), 0.1), GOLEM, Vector3(side * 0.04, -0.34, 0.04))
	var pivot := Node3D.new()
	pivot.name = "Pivot"
	root.add_child(pivot)
	var shield := Node3D.new()
	shield.name = "Shield"
	shield.position = Vector3(0, 0, 0.78)
	pivot.add_child(shield)
	var plate := MeshInstance3D.new()
	plate.mesh = Models.cylinder(0.56, 0.56, 0.12, 6)
	plate.material_override = crystal_mat(AQUA, 0.55)
	plate.rotation.x = PI * 0.5
	plate.position.y = 0.66
	plate.scale = Vector3(1.0, 1.0, 1.25)
	shield.add_child(plate)
	_no_shadow(Models.part(shield, Models.cylinder(0.6, 0.6, 0.06, 6), GOLD, Vector3(0, 0.66, -0.07))).rotation.x = PI * 0.5
	var gem := Models.part(shield, Models.cylinder(0.14, 0.14, 0.08, 6), PINK, Vector3(0, 0.66, 0.08), 1.0)
	gem.rotation.x = PI * 0.5
	_no_shadow(gem)
	return root


# --- Props --------------------------------------------------------------------------

## A cluster of pastel crystals on a little rock.
static func crystal_cluster(r: RandomNumberGenerator, size: float) -> Node3D:
	var root := Node3D.new()
	var rock := Models.part(root, _box(Vector3(0.5, 0.18, 0.42) * size, 0.07), STONE_DARK, Vector3(0, 0.08 * size, 0))
	rock.rotation.y = r.randf() * TAU
	var colors: Array[Color] = [MINT, PINK, AQUA, LEMON, LILAC]
	for k in r.randi_range(2, 4):
		var a: float = r.randf() * TAU
		var h: float = r.randf_range(0.35, 0.8) * size * (1.3 if k == 0 else 1.0)
		crystal(root, colors[r.randi() % colors.size()], Vector3(cos(a) * 0.12 * size, 0.12 * size, sin(a) * 0.12 * size), h, r.randf_range(0.06, 0.1) * size, Vector3(r.randf_range(-0.35, 0.35), 0, r.randf_range(-0.35, 0.35)))
	return root


## A glowing pastel mushroom.
static func mushroom(r: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	var h: float = r.randf_range(0.25, 0.45)
	Models.part(root, Models.cylinder(0.04, 0.055, h, 8), Color("#FFF6EC"), Vector3(0, h * 0.5, 0))
	var c: Color = [PINK, AQUA, LEMON][r.randi() % 3]
	var cap := Models.part(root, Models.sphere(0.15, 0.16, 12), c, Vector3(0, h, 0), 0.6)
	cap.scale = Vector3(1, 0.8, 1)
	return root


## A tall crystal spire (rim decoration and far islands).
static func spire(r: RandomNumberGenerator, h: float) -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.5, 0.2, 0.5), 0.08), STONE_DARK, Vector3(0, 0.1, 0))
	var colors: Array[Color] = [MINT, PINK, AQUA, LILAC]
	crystal(root, colors[r.randi() % colors.size()], Vector3(0, 0.15, 0), h, 0.17)
	crystal(root, colors[r.randi() % colors.size()], Vector3(0.16, 0.12, 0.08), h * 0.5, 0.09, Vector3(0, 0, -0.35))
	crystal(root, colors[r.randi() % colors.size()], Vector3(-0.14, 0.12, -0.06), h * 0.4, 0.08, Vector3(0.2, 0, 0.35))
	return root


## A little crystal lantern on a post.
static func lantern() -> Node3D:
	var root := Node3D.new()
	Models.part(root, _box(Vector3(0.16, 0.06, 0.16), 0.02), STONE_DARK, Vector3(0, 0.03, 0))
	Models.part(root, Models.cylinder(0.025, 0.03, 0.8, 6), GOLD.darkened(0.15), Vector3(0, 0.42, 0))
	var gem := MeshInstance3D.new()
	var s := Models.sphere(0.1, -1, 6)
	s.rings = 3
	gem.mesh = s
	gem.material_override = Models.mat(LEMON, 1.6)
	gem.position.y = 0.9
	root.add_child(_no_shadow(gem))
	return root

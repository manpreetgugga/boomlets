class_name WorldKit
extends RefCounted
## Everything that makes one world its own: name, colour palette, music,
## six levels, decoration and any extra rules (new tiles, critters, boss
## look). Each world lives in res://worlds/world_N.gd as a script extending
## this one; the arena calls the hooks below at fixed points. Every hook has
## a do-nothing default, so a world only overrides what it changes.
##
## A hook may read and change the arena freely through [member arena]
## (hero_pos, tiles via arena.tile()/arena._set_tile(), flames, critters,
## pods, _spawn_sparkles(), _multimesh(), add_child() and so on). These
## arena helpers are fair game too: _spawn_ring(at, color, size),
## _spawn_scorch(at), _spawn_confetti(at), _fx (effect list, see
## _update_fx), _shake (camera shake amount), _hitstop(seconds),
## _danger_cells(), _kill_critter(cr), _hurt_hero(), _spawn_critter(kind, c),
## _spawn_pickup(c, kind) and _blast(c, reach). Sounds: Sfx.play(cue) for
## the built-in cues (boom, crunch, place, pop, hurt, kick, gate, boss_hit,
## fail); for a world's own sounds add an AudioStreamPlayer child and check
## Save.sound_on.

## The arena being built or played. Set before any other hook runs.
var arena: Arena


# --- Identity -------------------------------------------------------------------

func world_name() -> String:
	return "World"


## Either a key of Models.PALETTES or a Dictionary of overrides in the same
## format (applied over the default meadow colours).
func palette() -> Variant:
	return "meadow"


## res:// path of this world's looping music (a .wav), or "" for the default.
func music() -> String:
	return ""


## The six levels, in the format described in core/Levels.gd.
func levels() -> Array[Dictionary]:
	return []


## Shown over the boss health bar.
func boss_name() -> String:
	return "BOSS"


## Blasts the boss takes (3–10; the HUD bar has one segment per hit).
func boss_hp() -> int:
	return 6


## The critter kind the boss calls in every few seconds.
func boss_minion_kind() -> StringName:
	return &"blobbit"


# --- Building ---------------------------------------------------------------------

## A map character the base game does not know. Return true when handled.
## Custom critters go through critter_for_char() instead.
func parse_tile(_ch: String, _c: Vector2i) -> bool:
	return false


## Map character -> critter kind (StringName) for this world's critters,
## e.g. {"k": &"crab"}.
func critter_chars() -> Dictionary:
	return {}


## Decoration on top of the border wall blocks (one transform per block,
## its origin at the block's centre). Return true when drawn, false for the
## default leafy tufts.
func build_wall_topper(_blocks: Array[Transform3D]) -> bool:
	return false


## The solid inner blocks (one transform per block, origin at its centre,
## block 0.8 tall). Return true when drawn, false for the default rock piles.
func build_solid_blocks(_spots: Array[Transform3D]) -> bool:
	return false


## A decoration for one spot on the island rim around the arena, or null for
## the default (trees, bushes, flowers, rocks). [param near_side] is the
## camera side, where only low props should go.
func rim_prop(_p: Vector3, _r: RandomNumberGenerator, _near_side: bool) -> Node3D:
	return null


## Decoration for one of the small far-off islands (it stands on y = 0 of
## the island, about [param size] wide), or null for a tree and a bush.
func far_island_prop(_r: RandomNumberGenerator, _size: float) -> Node3D:
	return null


## Runs once after the arena, props and hero are built: add custom tile
## visuals, lights and so on here.
func build_extra() -> void:
	pass


## Adjust the environment and sun (fog, darker light, glow) after they are
## made.
func tune_environment(_env: Environment, _sun: DirectionalLight3D) -> void:
	pass


# --- Rules --------------------------------------------------------------------------

## Every frame while the arena runs (also in the menu's demo arena: check
## arena.demo).
func process(_delta: float) -> void:
	pass


## True when this world's own tile at [param c] stops Pip and pods (on top
## of walls, crates and barrels).
func blocks(_c: Vector2i) -> bool:
	return false


## Multiplies Pip's walking speed on tile [param c] (mud < 1, boost > 1).
func hero_speed_scale(_c: Vector2i) -> float:
	return 1.0


## Pip has just stepped onto a new tile.
func on_hero_enter(_c: Vector2i) -> void:
	pass


## How a blast travelling outward treats this world's tile at [param c]:
## 0 = passes over as normal floor, 1 = burns this tile and stops (like a
## crate), 2 = stops before it (like a wall).
func flame_stop(_c: Vector2i) -> int:
	return 0


## A flame has just appeared on [param c].
func on_flame(_c: Vector2i) -> void:
	pass


## A pod has just gone off at [param c].
func on_explode(_c: Vector2i) -> void:
	pass


## Whether critter [param cr] may step onto [param c] (checked after the
## base rules allow it).
func critter_can_enter(_cr: Arena.Critter, _c: Vector2i) -> bool:
	return true


# --- Critters ----------------------------------------------------------------------

## The model for a critter kind, or null to use the base one. Called for
## every kind, so a world can also re-skin the base critters or the boss
## (&"boss"). Models need a child named "Body"; see render/Models.gd.
func critter_model(_kind: StringName) -> Node3D:
	return null


## Tiles per second for one of this world's critter kinds.
func critter_speed(_kind: StringName) -> float:
	return 1.5


## Hit points for one of this world's critter kinds.
func critter_hp(_kind: StringName) -> int:
	return 1


## True for kinds that dodge blasts and chase Pip like Buzzers.
func critter_smart(_kind: StringName) -> bool:
	return false


## The next step for a critter that has reached a tile, or ZERO to let the
## base rules choose.
func critter_step(_cr: Arena.Critter) -> Vector2i:
	return Vector2i.ZERO


## True while the critter is out of play (underground, phased out, behind
## glass...): blasts and touching Pip both ignore it.
func critter_hidden(_cr: Arena.Critter) -> bool:
	return false


## A blast caught the critter. Return true when handled here (the base
## rule kills it, or knocks a boss hit off).
func critter_hit(_cr: Arena.Critter) -> bool:
	return false


## Animates one of this world's critters each frame. Return the resting
## scale the body eases to (Vector3.ONE for none).
func pose_critter(_cr: Arena.Critter, _body: Node3D, _t: float, _delta: float) -> Vector3:
	return Vector3.ONE

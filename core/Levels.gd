class_name Levels
extends RefCounted
## The worlds and their levels. Each world is a script at
## res://worlds/world_N.gd extending WorldKit (see worlds/WorldKit.gd).
##
## Level format: maps are 13 x 15 characters (the border included); x runs left to right
## and z top (far from the camera) to bottom (near it).
##   #  stone block (indestructible)     .  floor, may get a random crate
##   _  floor, never a crate             c  crate, always
##   S  start                            E  exit pad
##   b  Blobbit (wanders)                z  Buzzer (chases)
##   w  Wisp (floats through crates)     K  Thornback, the boss
##   B  fizz barrel (blows up big)       > < ^ v  conveyor belt
##   1 2  warp pads, linked in pairs
## "crates" is the chance of a crate on each "." cell; "drops" says how many
## of each power-up hide in crates.
## A world may add its own map characters (see WorldKit.parse_tile and
## WorldKit.critter_chars).

const WORLD_COUNT: int = 25

static var _kits: Dictionary = {}


## A fresh kit for world [param world], for an arena to use (kits may keep
## per-arena state). Falls back to world 1 if the world's script is missing
## or broken.
static func make_kit(world: int) -> WorldKit:
	var path: String = "res://worlds/world_%d.gd" % world
	var script: Script = load(path) if ResourceLoader.exists(path) else null
	var k: Variant = script.new() if script != null and script.can_instantiate() else null
	if k is WorldKit and not (k as WorldKit).levels().is_empty():
		return k
	push_error("World %d failed to load; using world 1" % world)
	return load("res://worlds/world_1.gd").new()


## Starts loading world [param world]'s script and music on a background
## thread, so showing that world later does not stall the game.
static func warm(world: int) -> void:
	if world < 1 or world > WORLD_COUNT or _kits.has(world):
		return
	for path: String in ["res://worlds/world_%d.gd" % world, "res://audio/music/world_%d.wav" % world]:
		if ResourceLoader.exists(path) and not ResourceLoader.has_cached(path) 				and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(path)


## A shared kit for reading a world's name, levels and so on.
static func kit(world: int) -> WorldKit:
	if not _kits.has(world):
		_kits[world] = make_kit(world)
	return _kits[world]


static func world_name(world: int) -> String:
	return kit(world).world_name()


static func palette(world: int) -> Variant:
	return kit(world).palette()


static func count(world: int) -> int:
	return kit(world).levels().size()


static func get_level(world: int, level: int) -> Dictionary:
	return kit(world).levels()[level - 1]

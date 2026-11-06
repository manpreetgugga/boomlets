class_name Levels
extends RefCounted
## World 1, Meadow Isles: six arenas, each bringing in one new twist.
##
## Maps are 13 x 15 characters (the border included); x runs left to right
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

const WORLD_NAMES: Array[String] = ["", "Meadow Isles"]
## Each world's colour theme (see Models.PALETTES); the arena applies it
## before building, so a new world only needs a palette name here.
const WORLD_PALETTES: Array[String] = ["", "meadow"]

const WORLD_1: Array[Dictionary] = [
	{
		"name": "Fizzy Start",
		"tip": "Tap a tile to walk there.\nDouble-tap to drop a fizz pod!\nBlast every critter to open the exit.",
		"crates": 0.55, "par": 60,
		"drops": {"bomb": 2, "fire": 2, "speed": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..b.....b..#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.....b.....#",
			"#.#.#.#.#.#.#",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#__.........#",
			"#S#.#.#.#.#.#",
			"#__.........#",
			"#############",
		],
	},
	{
		"name": "Buzz Lane",
		"tip": "Buzzers chase you!\nLure them into a blast.",
		"crates": 0.5, "par": 75,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#....E......#",
			"#.##.#.#.##.#",
			"#.z.........#",
			"#.#.#...#.#.#",
			"#.....b.....#",
			"###.#.c.#.###",
			"#...c.b.c...#",
			"###.#.c.#.###",
			"#...........#",
			"#.#.#...#.#.#",
			"#........z..#",
			"#.##.#._.##.#",
			"#....._S_...#",
			"#############",
		],
	},
	{
		"name": "Belt Bay",
		"tip": "Belts carry you along...\nand your fizz pods too!",
		"crates": 0.45, "par": 80,
		"drops": {"bomb": 2, "fire": 2, "speed": 1, "kick": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.#.#.#.#.#",
			"#..>>>>>>v..#",
			"#.#^#.#.#v#.#",
			"#..^..b..v..#",
			"#.#^#.#.#v#.#",
			"#..^.....v.z#",
			"#.#^#.#.#v#.#",
			"#..^<<<<<<..#",
			"#.#.#.#.#.#.#",
			"#.b.......b.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Barrel Bash",
		"tip": "Fizz barrels burst in a big blast.\nSet off a chain reaction!",
		"crates": 0.4, "par": 85,
		"drops": {"bomb": 2, "fire": 1, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#..B..E..B..#",
			"#.#.#.#.#.#.#",
			"#...BB.BB...#",
			"#.#.#.#.#.#.#",
			"#.z...B...z.#",
			"#.#B#.#.#B#.#",
			"#...b...b...#",
			"#.#.#B#B#.#.#",
			"#.B.......B.#",
			"#.#.#.#.#.#.#",
			"#..B..b..B..#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Warp Woods",
		"tip": "Step on a swirl pad to warp.\nWisps drift right through crates!",
		"crates": 0.45, "par": 95,
		"drops": {"bomb": 2, "fire": 2, "kick": 1, "heart": 1},
		"map": [
			"#############",
			"#1....E....2#",
			"#.#.#.#.#.#.#",
			"#.....w.....#",
			"#.#.#.#.#.#.#",
			"#.z.......z.#",
			"###.#.#.#.###",
			"#2....b....1#",
			"###.#.#.#.###",
			"#...........#",
			"#.#.#.#.#.#.#",
			"#.b.......w.#",
			"#.#.#_#.#.#.#",
			"#...._S_....#",
			"#############",
		],
	},
	{
		"name": "Thornback's Hill",
		"tip": "Thornback rules this hill!\nHit him with six blasts.",
		"crates": 0.3, "par": 120, "boss": true,
		"drops": {"bomb": 3, "fire": 3, "speed": 1, "shield": 1},
		"map": [
			"#############",
			"#.....E.....#",
			"#.#.......#.#",
			"#...........#",
			"#...#...#...#",
			"#.....K.....#",
			"#.#.......#.#",
			"#...........#",
			"#...#...#...#",
			"#.#.......#.#",
			"#...........#",
			"#..cc...cc..#",
			"#.#._____.#.#",
			"#...._S_....#",
			"#############",
		],
	},
]


static func count(world: int) -> int:
	return WORLD_1.size() if world == 1 else 0


static func get_level(world: int, level: int) -> Dictionary:
	return WORLD_1[level - 1]


static func palette(world: int) -> String:
	return WORLD_PALETTES[world] if world < WORLD_PALETTES.size() else "meadow"

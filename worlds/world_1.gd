extends WorldKit
## World 1, Meadow Isles: green hedges, amber glass crates and rock piles.
## Each level brings in one new twist: Buzzers, belts, barrels, warps and
## Wisps, then Thornback on his hill. Uses every base-game default.

const LEVELS: Array[Dictionary] = [
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


func world_name() -> String:
	return "Meadow Isles"


func palette() -> Variant:
	return "meadow"


func levels() -> Array[Dictionary]:
	return LEVELS


func boss_name() -> String:
	return "THORNBACK"

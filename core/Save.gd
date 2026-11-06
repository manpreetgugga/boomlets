extends Node
## Saved progress (best stars and times per level) and settings, kept in
## user://boomlets.json. Written to a temporary file first, then moved into
## place, so a crash mid-write never loses the save.

const PATH: String = "user://boomlets.json"

var stars: Dictionary = {}      # "1-3" -> 0..3
var best_time: Dictionary = {}  # "1-3" -> seconds
var music_on: bool = true
var sound_on: bool = true
var haptics_on: bool = true


func _ready() -> void:
	_load()


func key(world: int, level: int) -> String:
	return "%d-%d" % [world, level]


func stars_for(world: int, level: int) -> int:
	return int(stars.get(key(world, level), 0))


func is_unlocked(world: int, level: int) -> bool:
	return level <= 1 or stars.has(key(world, level - 1))


func total_stars() -> int:
	var total: int = 0
	for v: Variant in stars.values():
		total += int(v)
	return total


## Records a finished level; returns true when it beat the old best.
func record(world: int, level: int, earned: int, seconds: float) -> bool:
	var k: String = key(world, level)
	var better: bool = earned > int(stars.get(k, 0)) or not best_time.has(k) or seconds < float(best_time[k])
	stars[k] = maxi(earned, int(stars.get(k, 0)))
	best_time[k] = minf(seconds, float(best_time.get(k, 99999.0)))
	write()
	return better


func write() -> void:
	var data: Dictionary = {
		"version": 1, "stars": stars, "best_time": best_time,
		"music": music_on, "sound": sound_on, "haptics": haptics_on,
	}
	var tmp: String = PATH + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data))
	f.close()
	DirAccess.rename_absolute(tmp, PATH)


func _load() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	stars = d.get("stars", {})
	best_time = d.get("best_time", {})
	music_on = bool(d.get("music", true))
	sound_on = bool(d.get("sound", true))
	haptics_on = bool(d.get("haptics", true))


func buzz(ms: int) -> void:
	if haptics_on and OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

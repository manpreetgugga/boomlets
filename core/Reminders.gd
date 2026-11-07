extends Node
## Play reminders: a friendly nudge from Pip in the morning, the evening and
## at night, each at a random minute in its window, with a line picked at
## random from core/ReminderLines.gd (a line comes back only after every
## other one in its slot has had a turn, about two months).
##
## The Android plugin (android/reminders_plugin) sets the alarms, posts the
## notifications and sets them again after a reboot. The next DAYS_AHEAD days
## are planned each time the game starts or goes to the background, so a
## player who stops opening the game hears nothing more after a week. None
## comes within QUIET_AFTER_PLAY_MIN minutes of playing, or while the game is
## on screen.
##
## Android 13+ needs the player's permission: the map offers reminders once a
## level is cleared (Main._offer_reminders), and the bell on the menu turns
## them on or off. Everywhere else every call is a quiet no-op.

signal changed

const Lines := preload("res://core/ReminderLines.gd")
const SLOTS: Array[String] = ["morning", "evening", "night"]
## Each slot's window, in minutes after local midnight: 8:30-10:00,
## 17:30-19:00 and 20:30-21:30.
const WINDOWS: Dictionary = {"morning": [510, 600], "evening": [1050, 1140], "night": [1230, 1290]}
const DAYS_AHEAD: int = 7
const QUIET_AFTER_PLAY_MIN: int = 180
## The map offers reminders at most this many times, this many days apart.
const MAX_OFFERS: int = 2
const OFFER_GAP_DAYS: int = 3
## Debug builds: create this file (adb shell run-as com.manpreetgugga.boomlets
## touch files/reminder_test) and the next time the game goes to the
## background a test reminder is set for two minutes later.
const TEST_FLAG: String = "user://reminder_test"

var _plugin: Object = null
var _offered_this_launch: bool = false
var _asking: Callable = Callable()
var _asked_ms: int = 0
## Debug builds: the test reminder (see TEST_FLAG), once asked for.
var _test: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Save.reminder_seed == 0:
		Save.reminder_seed = randi_range(1, 2147483646)
		Save.write()
	if OS.get_name() == "Android" and Engine.has_singleton("BoomletsReminders"):
		_plugin = Engine.get_singleton("BoomletsReminders")
		_plugin.connect("permission_result", _on_permission_result)
	refresh()
	# Analytics needs a moment to start up before it can log the open.
	get_tree().create_timer(5.0).timeout.connect(_note_opened)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED:
			refresh(true)
		NOTIFICATION_APPLICATION_RESUMED:
			# Back from Android's settings, perhaps with notifications now allowed.
			refresh()
			changed.emit()
			if Time.get_ticks_msec() > 5000:
				_note_opened()


func available() -> bool:
	return _plugin != null


## Whether the phone lets the game post reminders.
func allowed() -> bool:
	return _plugin != null and bool(_plugin.canNotify())


## Reminders are coming: the player wants them and the phone allows them.
func active() -> bool:
	return Save.reminders_on and allowed()


## What the bell on the menu shows: reminders coming (or, where there are
## none, as on desktop, just the player's switch).
func bell_on() -> bool:
	return active() if _plugin != null else Save.reminders_on


## Plans the next DAYS_AHEAD days again (or clears them when off).
## [param going_away]: the game is going to the background.
func refresh(going_away: bool = false) -> void:
	if _plugin == null:
		return
	if not active():
		_plugin.cancelAll()
		return
	var days: Array[Dictionary] = plan()
	var quiet: int = QUIET_AFTER_PLAY_MIN
	if going_away and OS.is_debug_build() and FileAccess.file_exists(TEST_FLAG):
		DirAccess.remove_absolute(TEST_FLAG)
		var now: Dictionary = Time.get_time_dict_from_system()
		var line: Array = pick("evening", randi_range(0, 999))
		_test = {"day": 0, "minute": int(now.hour) * 60 + int(now.minute) + 2, "slot": "test",
			"title": line[0], "body": line[1]}
	if not _test.is_empty():
		# Kept for the rest of this run: Android may report "paused" twice.
		days.push_front(_test)
		quiet = 0
	_plugin.schedule(JSON.stringify(days), quiet)


## The next [param days] days of reminders, today first: each with its day
## (0 is today), minute after local midnight, slot, title and body. The same
## day and slot always get the same line and minute on this phone, so
## planning again changes nothing already planned.
func plan(days: int = DAYS_AHEAD) -> Array[Dictionary]:
	var today: int = _today()
	var out: Array[Dictionary] = []
	for d in days:
		for slot: String in SLOTS:
			var line: Array = pick(slot, today + d)
			out.append({"day": d, "minute": minute_for(slot, today + d), "slot": slot,
				"title": line[0], "body": line[1]})
	return out


## [param slot]'s line for [param day] (days since 1970): [title, body].
## Each run through a slot's lines is in its own random order.
func pick(slot: String, day: int) -> Array:
	var lines: Array = Lines.for_slot(slot)
	var n: int = lines.size()
	var order: PackedInt32Array = _shuffled(n, hash([Save.reminder_seed, slot, floori(float(day) / n)]))
	var line: Array = lines[order[posmod(day, n)]]
	return [_fill(line[0]), _fill(line[1])]


func minute_for(slot: String, day: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([Save.reminder_seed, slot, day, "minute"])
	var w: Array = WINDOWS[slot]
	return rng.randi_range(w[0], w[1])


func _shuffled(n: int, seed_value: int) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var a := PackedInt32Array()
	a.resize(n)
	for i in n:
		a[i] = i
	for i in range(n - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var t: int = a[i]
		a[i] = a[j]
		a[j] = t
	return a


func _fill(text: String) -> String:
	if not text.contains("{world}"):
		return text
	return text.replace("{world}", Levels.world_name(Save.last_world))


## Days since 1970 by the phone's own calendar.
func _today() -> int:
	var d: Dictionary = Time.get_date_dict_from_system()
	return floori(Time.get_unix_time_from_datetime_dict({"year": d.year, "month": d.month, "day": d.day}) / 86400.0)


# --- Turning them on and off --------------------------------------------------

## Whether the map should offer reminders now: on Android 13+ where the
## player has not said yes yet, once a level is cleared, at most MAX_OFFERS
## times, OFFER_GAP_DAYS apart, never twice in one launch. (Older Android
## allows notifications from the start, so there is nothing to offer.)
func should_offer() -> bool:
	if _plugin == null or _offered_this_launch or not Save.reminders_on:
		return false
	if int(_plugin.sdkVersion()) < 33 or bool(_plugin.hasPermission()):
		return false
	if Save.stars.is_empty() or Save.reminder_asks >= MAX_OFFERS:
		return false
	return Time.get_unix_time_from_system() - Save.reminder_asked_at >= OFFER_GAP_DAYS * 86400


## Counts an offer as made, whatever the answer (closing it counts too).
func note_offered() -> void:
	_offered_this_launch = true
	Save.reminder_asks += 1
	Save.reminder_asked_at = int(Time.get_unix_time_from_system())
	Save.write()


## Turns reminders on, asking Android first when it needs the player's say.
## [param done] gets whether they are now coming.
func turn_on(done: Callable = Callable()) -> void:
	Save.reminders_on = true
	Save.write()
	if _plugin == null or allowed():
		_finish(done)
	elif not bool(_plugin.hasPermission()):
		_asking = done
		_asked_ms = Time.get_ticks_msec()
		_plugin.requestPermission()
	else:
		# Allowed once, then switched off in Android's settings: only there
		# can they go back on.
		_plugin.openSettings()
		_finish(done)


func turn_off() -> void:
	Save.reminders_on = false
	Save.write()
	_finish(Callable())


func _on_permission_result(granted: bool) -> void:
	var done: Callable = _asking
	_asking = Callable()
	# A "no" with no time to read the prompt means Android no longer shows it
	# (the player said no twice before): their settings page instead.
	if not granted and Time.get_ticks_msec() - _asked_ms < 500 and _plugin != null:
		_plugin.openSettings()
	Services.event("reminders_permission", {"granted": "true" if granted else "false"})
	_finish(done)


func _finish(done: Callable) -> void:
	refresh()
	changed.emit()
	if done.is_valid():
		done.call(active())


## Logs when the game was opened from a reminder.
func _note_opened() -> void:
	if _plugin == null:
		return
	var slot: String = str(_plugin.takeOpenedSlot())
	if slot != "":
		Services.event("reminder_open", {"slot": slot})

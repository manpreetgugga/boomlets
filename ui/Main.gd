extends Node
## The front end: main menu, a map per world (swipe or use the arrows to go
## between worlds) over a slowly turning arena of that world, and the levels
## themselves. Swaps screens under a soft cream fade, pauses on Android's
## back button and when the app goes to the background.
##
## Dev arguments: --world=N, --level=N (straight into a level),
## --screen=map (straight onto the map of --world).

## The world being shown on the map or played.
var world: int = 1

var arena: Arena
var hud: Hud
var screen: StringName = &""
var level: int = 1

var _ui: CanvasLayer
var _fade: ColorRect
var _busy: bool = false
var _title: Label
var _swipe_from: Vector2 = Vector2.INF
## Started by a dev argument (--world, --level, --screen): stay on that
## world and leave the saved one be.
var _dev: bool = false
## The Privacy card over the menu, while it is open.
var _privacy: Control = null
## Explore mode's frame-rate counter (top left), when it is on.
var _fps_label: Label = null
var _fps_wait: float = 0.0
## Phones: the 3D scene's render scale, and how long the game has run slow.
var _scale_3d: float = 1.0
var _slow_for: float = 0.0
## Losses in a row on each level ("world-level"); from the second, the next
## try quietly gives Pip a helping hand (see Arena.assist).
var _losses: Dictionary = {}

## Phones draw the 3D scene at this share of the screen's resolution (the
## interface stays sharp) and step down to MIN_SCALE_3D if they still cannot
## keep up.
const PHONE_SCALE_3D: float = 0.75
const MIN_SCALE_3D: float = 0.55


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ui = CanvasLayer.new()
	add_child(_ui)
	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	_fade = ColorRect.new()
	_fade.color = Color(Ui.CREAM, 1.0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_fade)
	Sfx.music(true)
	_tune_for_phone()
	_ensure_fps_label()
	world = Save.last_world
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--world="):
			world = clampi(int(a.get_slice("=", 1)), 1, Levels.WORLD_COUNT)
		if a.begins_with("--world=") or a.begins_with("--level=") or a.begins_with("--screen="):
			_dev = true
	for a: String in args:
		if a.begins_with("--level="):
			_start_level(int(a.get_slice("=", 1)))
			_fade_in()
			return
		if a == "--screen=map":
			_show_map()
			_fade_in()
			return
	_show_menu()
	_fade_in()


func _fade_in() -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, 0.45)


func _go(next: Callable) -> void:
	if _busy:
		return
	_busy = true
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.22)
	tw.tween_callback(func() -> void:
		get_tree().paused = false
		next.call())
	tw.tween_property(_fade, "color:a", 0.0, 0.32)
	tw.tween_callback(func() -> void:
		_busy = false
		_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE)


func _clear_ui() -> void:
	for c: Node in _ui.get_children():
		c.queue_free()
	hud = null
	_title = null


## The slowly turning arena behind the menu and the map, built from
## [member world]; rebuilt (under the fade) when the world changes.
func _ensure_demo() -> void:
	if arena != null and arena.demo and arena.world_id == world:
		return
	if arena != null:
		arena.queue_free()
	arena = Arena.new()
	add_child(arena)
	arena.setup(world, 1, true)
	arena.process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if _title != null:
		var t: float = Time.get_ticks_msec() / 1000.0
		_title.rotation = sin(t * 1.3) * 0.03
		_title.scale = Vector2.ONE * (1.0 + sin(t * 2.6) * 0.02)
	_watch_speed(delta)
	if _fps_label != null:
		_fps_wait -= delta
		if _fps_wait <= 0.0:
			_fps_wait = 0.5
			_fps_label.text = "%d fps  3D %d%%" % [Engine.get_frames_per_second(), roundi(get_viewport().scaling_3d_scale * 100.0)]


# --- Speed -------------------------------------------------------------------

## Phones (high-refresh screens like the Pixel's 120 Hz) get a steady 60 fps
## instead of a frame rate that jumps between 60 and 120, which looks like
## stutter, and draw the 3D scene below full resolution.
func _tune_for_phone() -> void:
	if not OS.has_feature("mobile"):
		return
	Engine.max_fps = 60
	_scale_3d = PHONE_SCALE_3D
	get_viewport().scaling_3d_scale = _scale_3d


## If a phone stays under ~50 fps for 4 seconds, draw the 3D a step smaller.
func _watch_speed(delta: float) -> void:
	if not OS.has_feature("mobile") or _scale_3d <= MIN_SCALE_3D or _busy or get_tree().paused:
		_slow_for = 0.0
		return
	_slow_for = _slow_for + delta if Engine.get_frames_per_second() < 50 else 0.0
	if _slow_for >= 4.0:
		_slow_for = 0.0
		_scale_3d = maxf(MIN_SCALE_3D, _scale_3d - 0.1)
		get_viewport().scaling_3d_scale = _scale_3d


# --- Explore mode (admin) ----------------------------------------------------

## Holding the star counter on the menu for 3 seconds opens every world and
## level (and shows the frame rate); holding it again turns that off.
func _hold_to_explore(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	var hold: Array[int] = [0]
	c.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb == null or mb.button_index != MOUSE_BUTTON_LEFT:
			return
		hold[0] += 1
		if not mb.pressed:
			return
		var id: int = hold[0]
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if hold[0] == id and screen == &"menu" and is_instance_valid(c):
				_toggle_explore()))


func _toggle_explore() -> void:
	Save.explore_all = not Save.explore_all
	Save.write()
	Save.buzz(80)
	Sfx.play(&"gate" if Save.explore_all else &"fail")
	_ensure_fps_label()
	_show_menu()


func _ensure_fps_label() -> void:
	if Save.explore_all and _fps_label == null:
		var layer := CanvasLayer.new()
		layer.layer = 30
		add_child(layer)
		_fps_label = Ui.outlined(Ui.label("", 24, Color.WHITE, 900), Ui.INK, 8)
		_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_fps_label.position = Vector2(16, 8)
		_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_fps_label)
	elif not Save.explore_all and _fps_label != null:
		_fps_label.get_parent().queue_free()
		_fps_label = null


# --- Menu -------------------------------------------------------------------

func _show_menu() -> void:
	screen = &"menu"
	if not _dev:
		world = Save.last_world
	_clear_ui()
	_ensure_demo()
	Sfx.track("")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	_title = Ui.outlined(Ui.label("BOOMLETS", 118, Ui.YELLOW, 900), Ui.INK, 30)
	_title.add_theme_color_override(&"font_shadow_color", Color(Ui.INK, 0.35))
	_title.add_theme_constant_override(&"shadow_offset_y", 10)
	_title.add_theme_constant_override(&"shadow_offset_x", 0)
	_title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title.size = Vector2(700, 170)
	_title.position = Vector2(-350, 150)
	_title.pivot_offset = Vector2(350, 85)
	root.add_child(_title)

	var tag := Ui.card(Color(Ui.CREAM, 0.94), 30)
	tag.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tag.position = Vector2(-250, 325)
	tag.size = Vector2(500, 0)
	tag.add_child(Ui.label("Pop pods. Blast crates.\nOutsmart the critters!", 30, Ui.INK, 800))
	root.add_child(tag)

	var stars := Ui.card(Color(Ui.CREAM, 0.94), 30)
	stars.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	stars.position = Vector2(-230, 40)
	stars.add_child(Ui.label("★ %d / %d" % [Save.total_stars(), Levels.WORLD_COUNT * 6 * 3], 32, Ui.INK, 900))
	root.add_child(stars)
	_hold_to_explore(stars)
	if Save.explore_all:
		var badge := Ui.card(Color(Ui.MINT, 0.94), 24)
		badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge.position = Vector2(-230, 112)
		badge.add_child(Ui.label("All worlds open", 22, Ui.INK, 900))
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(badge)

	var play := Btn.make("PLAY", &"play", Vector2(440, 140), Ui.YELLOW)
	play.font_size = 56
	play.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play.position = Vector2(-220, -390)
	play.pressed.connect(func() -> void:
		_go(func() -> void:
			if not _dev:
				world = Save.last_world
			_show_map()))
	root.add_child(play)

	var sound := Btn.make("", &"sound", Vector2(104, 104))
	sound.dimmed = not Save.sound_on
	sound.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sound.position = Vector2(-208, -200)
	sound.pressed.connect(func() -> void:
		Save.sound_on = not Save.sound_on
		sound.dimmed = not Save.sound_on
		Save.write())
	root.add_child(sound)

	var music := Btn.make("", &"music", Vector2(104, 104))
	music.dimmed = not Save.music_on
	music.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	music.position = Vector2(-52, -200)
	music.pressed.connect(func() -> void:
		Save.music_on = not Save.music_on
		music.dimmed = not Save.music_on
		Sfx.music(Save.music_on)
		Save.write())
	root.add_child(music)

	var privacy := Btn.make("", &"privacy", Vector2(104, 104))
	privacy.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	privacy.position = Vector2(104, -200)
	privacy.pressed.connect(_show_privacy.bind(root))
	root.add_child(privacy)


## The Privacy card: what the game collects, the player's own switches for
## play stats and crash reports, Google's ad-consent choices (where they apply) and the policy.
func _show_privacy(root: Control) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.12, 0.25, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	_privacy = dim
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := Ui.card(Ui.CREAM, 44)
	panel.custom_minimum_size = Vector2(560, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	panel.add_child(box)
	box.add_child(Ui.label("Privacy", 54, Ui.INK, 900))
	var about := Ui.label("Boomlets has no accounts and never asks for your name. "
		+ "It shows ads from Google AdMob, and sends anonymous play stats "
		+ "(like which levels are tricky) and crash reports to Google Firebase. "
		+ "Your progress stays on this phone.", 26, Ui.INK_SOFT, 800)
	about.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	about.custom_minimum_size = Vector2(480, 0)
	box.add_child(about)
	var buttons: Array[Btn] = []
	var stats := Btn.make("", &"", Vector2(440, 88), Ui.MINT if Save.stats_on else Ui.CREAM.darkened(0.06))
	stats.text = "Play stats: On" if Save.stats_on else "Play stats: Off"
	stats.pressed.connect(func() -> void:
		Services.set_stats_on(not Save.stats_on)
		stats.text = "Play stats: On" if Save.stats_on else "Play stats: Off"
		stats.color = Ui.MINT if Save.stats_on else Ui.CREAM.darkened(0.06)
		stats.queue_redraw())
	buttons.append(stats)
	var crash := Btn.make("", &"", Vector2(440, 88), Ui.MINT if Save.crash_reports_on else Ui.CREAM.darkened(0.06))
	crash.text = "Crash reports: On" if Save.crash_reports_on else "Crash reports: Off"
	crash.pressed.connect(func() -> void:
		Services.set_crash_reports_on(not Save.crash_reports_on)
		crash.text = "Crash reports: On" if Save.crash_reports_on else "Crash reports: Off"
		crash.color = Ui.MINT if Save.crash_reports_on else Ui.CREAM.darkened(0.06)
		crash.queue_redraw())
	buttons.append(crash)
	if Services.privacy_options_required():
		var ads := Btn.make("Ad choices", &"", Vector2(440, 88))
		ads.pressed.connect(Services.show_privacy_options)
		buttons.append(ads)
	var policy := Btn.make("Privacy policy", &"", Vector2(440, 88))
	policy.pressed.connect(Services.open_privacy_policy)
	buttons.append(policy)
	var close := Btn.make("Close", &"", Vector2(440, 88), Ui.YELLOW)
	close.pressed.connect(dim.queue_free)
	buttons.append(close)
	for b: Btn in buttons:
		b.font_size = 34
		var holder := CenterContainer.new()
		holder.add_child(b)
		box.add_child(holder)


# --- Level map ---------------------------------------------------------------

## Builds the map of [member world]. [param from_dir] (-1 or 1) slides it in
## from that side after browsing between worlds.
func _show_map(from_dir: int = 0) -> void:
	screen = &"map"
	_clear_ui()
	_ensure_demo()
	Sfx.track(Levels.kit(world).music())
	var open_world: bool = Save.world_unlocked(world)
	var count: int = Levels.count(world)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	if not open_world:
		var veil := ColorRect.new()
		veil.color = Color(0.36, 0.34, 0.42, 0.42)
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(veil)

	var back := Btn.make("", &"home", Vector2(96, 96))
	back.position = Vector2(24, 30)
	back.pressed.connect(func() -> void: _go(_show_menu))
	root.add_child(back)

	var head := Ui.card(Color(Ui.CREAM, 0.95), 34)
	head.set_anchors_preset(Control.PRESET_CENTER_TOP)
	head.position = Vector2(-220, 40)
	head.size = Vector2(440, 0)
	var hb := VBoxContainer.new()
	hb.add_theme_constant_override(&"separation", 0)
	hb.add_child(Ui.label(Levels.world_name(world), 46, Ui.INK, 900))
	hb.add_child(Ui.label("★ %d / %d" % [Save.world_stars(world), count * 3], 28, Ui.INK_SOFT, 900))
	head.add_child(hb)
	root.add_child(head)

	# Six badges on a winding trail, first level at the bottom.
	var trail := Control.new()
	trail.set_anchors_preset(Control.PRESET_CENTER)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trail)
	var spots: Array[Vector2] = [Vector2(-150, 330), Vector2(130, 200), Vector2(-120, 65), Vector2(150, -65), Vector2(-120, -195), Vector2(110, -330)]
	var shown: int = mini(count, spots.size())
	var dot: Color = Color(Ui.CREAM, 0.9 if open_world else 0.55)
	trail.draw.connect(func() -> void:
		for i in shown - 1:
			var a: Vector2 = spots[i]
			var b: Vector2 = spots[i + 1]
			for k in 8:
				var p: Vector2 = a.lerp(b, (k + 0.5) / 8.0) + Vector2(0, sin((k + 0.5) / 8.0 * PI) * -28.0)
				trail.draw_circle(p, 8, dot))
	var next_level: int = 1
	for i in count:
		if Save.stars_for(world, i + 1) > 0:
			next_level = mini(i + 2, count)
	var lock_card: Control = _lock_card() if not open_world else null
	for i in shown:
		var n: int = i + 1
		var open: bool = Save.is_unlocked(world, n)
		var info: Dictionary = Levels.get_level(world, n)
		var fill: Color = Ui.YELLOW if n == next_level else (Ui.MINT if Save.stars_for(world, n) > 0 else Ui.CREAM)
		if not open:
			fill = Color("#CFC6BC")
		var b := Btn.make("" if not open else str(n), &"lock" if not open else &"", Vector2(128, 128), fill)
		b.font_size = 58
		b.ink = Ui.INK if open else Ui.INK_SOFT
		b.caption = info["name"]
		b.stars = Save.stars_for(world, n) if open else -1
		b.position = spots[i] - Vector2(64, 64)
		if open:
			b.pressed.connect(func() -> void: _go(_start_level.bind(n)))
		else:
			b.pressed.connect(func() -> void:
				Sfx.play(&"error")
				if lock_card != null:
					_wiggle(lock_card))
		trail.add_child(b)
	if lock_card != null:
		root.add_child(lock_card)

	_build_world_nav(root)
	# Get the worlds either side ready while the player looks at this one.
	Levels.warm(world + 1)
	Levels.warm(world - 1)

	if from_dir != 0:
		root.position.x = 80.0 * from_dir
		var tw := create_tween()
		tw.tween_property(root, "position:x", 0.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


## The card over a locked world's trail, naming the boss that opens it.
func _lock_card() -> Control:
	var card := Ui.card(Color(Ui.CREAM, 0.96), 40)
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.size = Vector2(440, 0)
	card.position = Vector2(-220, -170)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	var icon := Control.new()
	icon.custom_minimum_size = Vector2(0, 80)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.draw.connect(func() -> void: Ui.draw_icon(icon, &"lock", Vector2(icon.size.x * 0.5, 46), 88, Ui.INK))
	box.add_child(icon)
	box.add_child(Ui.label("Locked", 50, Ui.INK, 900))
	var boss: String = Levels.kit(world - 1).boss_name().capitalize()
	box.add_child(Ui.label("Beat %s\nto open" % boss, 32, Ui.INK_SOFT, 800))
	card.add_child(box)
	card.resized.connect(func() -> void: card.pivot_offset = card.size * 0.5)
	return card


func _wiggle(c: Control) -> void:
	var tw := create_tween()
	for k in 4:
		tw.tween_property(c, "rotation", 0.06 * (1.0 if k % 2 == 0 else -1.0), 0.05)
	tw.tween_property(c, "rotation", 0.0, 0.05)


## Arrows, "World 2 / 5" and a dot per world along the bottom of the map.
func _build_world_nav(root: Control) -> void:
	var nav := Control.new()
	nav.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	nav.position = Vector2(0, -150)
	nav.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(nav)

	var pill := Ui.card(Color(Ui.CREAM, 0.94), 52)
	pill.position = Vector2(-150, 0)
	var pill_h: float = 112.0 if Levels.WORLD_COUNT <= 15 else 132.0
	pill.custom_minimum_size = Vector2(300, pill_h)
	pill.size = Vector2(300, pill_h)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 0)
	box.add_child(Ui.label("World %d / %d" % [world, Levels.WORLD_COUNT], 32, Ui.INK, 900))
	# One dot per world, wrapped onto a second row when there are many.
	var rows: int = 1 if Levels.WORLD_COUNT <= 15 else 2
	var per_row: int = ceili(float(Levels.WORLD_COUNT) / rows)
	var dots := Control.new()
	dots.custom_minimum_size = Vector2(0, 24 * rows)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots.draw.connect(func() -> void:
		var gap: float = minf(34.0, 260.0 / maxf(per_row - 1, 1))
		var r: float = minf(7.0, gap * 0.32)
		for k in Levels.WORLD_COUNT:
			var row: int = floori(float(k) / per_row)
			var in_row: int = mini(per_row, Levels.WORLD_COUNT - row * per_row)
			var x0: float = dots.size.x * 0.5 - gap * (in_row - 1) * 0.5
			var c := Vector2(x0 + gap * (k % per_row), 12 + 24 * row)
			if k + 1 == world:
				dots.draw_circle(c, r + 4, Ui.INK)
				dots.draw_circle(c, r, Ui.YELLOW)
			elif Save.world_unlocked(k + 1):
				dots.draw_circle(c, r, Color(Ui.INK, 0.6))
			else:
				dots.draw_circle(c, r, Color(Ui.INK, 0.2)))
	box.add_child(dots)
	pill.add_child(box)
	nav.add_child(pill)

	for dir: int in [-1, 1]:
		var w: int = world + dir
		if w < 1 or w > Levels.WORLD_COUNT:
			continue
		var b := Btn.make("", &"left" if dir < 0 else &"right", Vector2(112, 112), Ui.YELLOW if Save.world_unlocked(w) else Ui.CREAM)
		b.position = Vector2(-150 - 18 - 112 if dir < 0 else 150 + 18, 0)
		b.pressed.connect(_browse.bind(dir))
		nav.add_child(b)


## Shows the map of the world [param dir] steps away (-1 left, 1 right).
func _browse(dir: int) -> void:
	var w: int = world + dir
	if w < 1 or w > Levels.WORLD_COUNT or _busy:
		return
	_go(func() -> void:
		world = w
		_show_map(dir))


func _input(event: InputEvent) -> void:
	if screen != &"map" or _busy:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT, KEY_A:
				_browse(-1)
			KEY_RIGHT, KEY_D:
				_browse(1)
		return
	# A sideways swipe flips between worlds.
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_from = event.position
		elif _swipe_from.x < INF:
			var d: Vector2 = event.position - _swipe_from
			_swipe_from = Vector2.INF
			if absf(d.x) > 140.0 and absf(d.x) > absf(d.y) * 1.4:
				_browse(-1 if d.x > 0.0 else 1)


# --- Levels -----------------------------------------------------------------

func _start_level(n: int) -> void:
	screen = &"game"
	level = clampi(n, 1, Levels.count(world))
	if not _dev and Save.last_world != world:
		Save.last_world = world
		Save.write()
	_clear_ui()
	if arena != null:
		arena.queue_free()
	arena = Arena.new()
	var tries_key: String = "%d-%d" % [world, level]
	arena.assist = int(_losses.get(tries_key, 0)) >= 2
	add_child(arena)
	arena.setup(world, level, false)
	hud = Hud.new()
	hud.arena = arena
	hud.has_next = level < Levels.count(world) or world < Levels.WORLD_COUNT
	hud.restart_requested.connect(func() -> void: _leave_level(_start_level.bind(level)))
	hud.next_requested.connect(func() -> void: _leave_level(_next_level))
	hud.map_requested.connect(func() -> void: _leave_level(_show_map))
	hud.home_requested.connect(func() -> void: _leave_level(_show_menu))
	var w: int = world
	var l: int = level
	var a: Arena = arena
	Services.level_started(w, l)
	arena.won.connect(func(stars: int, seconds: float) -> void:
		_losses.erase(tries_key)
		Services.level_won(w, l, stars, seconds, a.deaths))
	arena.lost.connect(func(reason: String) -> void:
		_losses[tries_key] = int(_losses.get(tries_key, 0)) + 1
		Services.level_lost(w, l, reason, a.elapsed))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(hud)


## Leaves the level for [param next]. After a finished level this is a
## natural break, where an occasional interstitial ad may play first.
func _leave_level(next: Callable) -> void:
	if _busy:
		return
	if arena != null and (arena.state == &"won" or arena.state == &"lost"):
		Services.level_break(func() -> void: _go(next))
	else:
		_go(next)


## The level after this one: the next on this world's trail, or after the
## boss the first level of the next world.
func _next_level() -> void:
	if level < Levels.count(world):
		_start_level(level + 1)
	elif world < Levels.WORLD_COUNT:
		world += 1
		_start_level(1)
	else:
		_show_map()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if screen == &"game" and hud != null and OS.has_feature("mobile"):
				hud.open_pause()


func _back() -> void:
	match screen:
		&"game":
			if hud != null:
				if get_tree().paused:
					hud._resume()
				else:
					hud.open_pause()
		&"map":
			_go(_show_menu)
		&"menu":
			if is_instance_valid(_privacy):
				_privacy.queue_free()
			else:
				get_tree().quit()

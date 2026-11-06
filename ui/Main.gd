extends Node
## The front end: main menu and level map over a slowly turning arena, and
## the levels themselves. Swaps screens under a soft cream fade, pauses on
## Android's back button and when the app goes to the background.

const WORLD: int = 1

var arena: Arena
var hud: Hud
var screen: StringName = &""
var level: int = 1

var _ui: CanvasLayer
var _fade: ColorRect
var _busy: bool = false
var _title: Label


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
	var args: PackedStringArray = OS.get_cmdline_user_args()
	for a: String in args:
		if a.begins_with("--level="):
			_start_level(int(a.get_slice("=", 1)))
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


func _ensure_demo() -> void:
	if arena != null and arena.demo:
		return
	if arena != null:
		arena.queue_free()
	arena = Arena.new()
	add_child(arena)
	arena.setup(WORLD, 1, true)
	arena.process_mode = Node.PROCESS_MODE_ALWAYS


func _process(_delta: float) -> void:
	if _title != null:
		var t: float = Time.get_ticks_msec() / 1000.0
		_title.rotation = sin(t * 1.3) * 0.03
		_title.scale = Vector2.ONE * (1.0 + sin(t * 2.6) * 0.02)


# --- Menu -------------------------------------------------------------------

func _show_menu() -> void:
	screen = &"menu"
	_clear_ui()
	_ensure_demo()
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
	stars.add_child(Ui.label("★ %d / %d" % [Save.total_stars(), Levels.count(WORLD) * 3], 32, Ui.INK, 900))
	root.add_child(stars)

	var play := Btn.make("PLAY", &"play", Vector2(440, 140), Ui.YELLOW)
	play.font_size = 56
	play.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	play.position = Vector2(-220, -390)
	play.pressed.connect(func() -> void: _go(_show_map))
	root.add_child(play)

	var sound := Btn.make("", &"sound", Vector2(104, 104))
	sound.dimmed = not Save.sound_on
	sound.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	sound.position = Vector2(-130, -200)
	sound.pressed.connect(func() -> void:
		Save.sound_on = not Save.sound_on
		sound.dimmed = not Save.sound_on
		Save.write())
	root.add_child(sound)

	var music := Btn.make("", &"music", Vector2(104, 104))
	music.dimmed = not Save.music_on
	music.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	music.position = Vector2(26, -200)
	music.pressed.connect(func() -> void:
		Save.music_on = not Save.music_on
		music.dimmed = not Save.music_on
		Sfx.music(Save.music_on)
		Save.write())
	root.add_child(music)


# --- Level map ---------------------------------------------------------------

func _show_map() -> void:
	screen = &"map"
	_clear_ui()
	_ensure_demo()
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(root)

	var back := Btn.make("", &"home", Vector2(96, 96))
	back.position = Vector2(24, 30)
	back.pressed.connect(func() -> void: _go(_show_menu))
	root.add_child(back)

	var head := Ui.card(Color(Ui.CREAM, 0.95), 34)
	head.set_anchors_preset(Control.PRESET_CENTER_TOP)
	head.position = Vector2(-220, 40)
	head.size = Vector2(440, 0)
	var hb := VBoxContainer.new()
	hb.add_child(Ui.label("World 1", 26, Ui.INK_SOFT, 800))
	hb.add_child(Ui.label(Levels.WORLD_NAMES[WORLD], 46, Ui.INK, 900))
	head.add_child(hb)
	root.add_child(head)

	# Six badges on a winding trail, first level at the bottom.
	var trail := Control.new()
	trail.set_anchors_preset(Control.PRESET_CENTER)
	trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(trail)
	var spots: Array[Vector2] = [Vector2(-150, 390), Vector2(130, 250), Vector2(-120, 90), Vector2(150, -60), Vector2(-120, -210), Vector2(110, -360)]
	trail.draw.connect(func() -> void:
		for i in spots.size() - 1:
			var a: Vector2 = spots[i]
			var b: Vector2 = spots[i + 1]
			for k in 9:
				var p: Vector2 = a.lerp(b, (k + 0.5) / 9.0) + Vector2(0, sin((k + 0.5) / 9.0 * PI) * -30.0)
				trail.draw_circle(p, 8, Color(Ui.CREAM, 0.9)))
	var next_level: int = 1
	for i in Levels.count(WORLD):
		if Save.stars_for(WORLD, i + 1) > 0:
			next_level = mini(i + 2, Levels.count(WORLD))
	for i in Levels.count(WORLD):
		var n: int = i + 1
		var open: bool = Save.is_unlocked(WORLD, n)
		var info: Dictionary = Levels.get_level(WORLD, n)
		var fill: Color = Ui.YELLOW if n == next_level else (Ui.MINT if Save.stars_for(WORLD, n) > 0 else Ui.CREAM)
		if not open:
			fill = Color("#CFC6BC")
		var b := Btn.make("" if not open else str(n), &"lock" if not open else &"", Vector2(128, 128), fill)
		b.font_size = 58
		b.ink = Ui.INK if open else Ui.INK_SOFT
		b.caption = info["name"]
		b.stars = Save.stars_for(WORLD, n) if open else -1
		b.position = spots[i] - Vector2(64, 64)
		if open:
			b.pressed.connect(func() -> void: _go(_start_level.bind(n)))
		else:
			b.pressed.connect(func() -> void: Sfx.play(&"error"))
		trail.add_child(b)

	var soon := Ui.card(Color(Ui.CREAM, 0.85), 30)
	soon.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	soon.position = Vector2(-230, -120)
	soon.size = Vector2(460, 0)
	soon.add_child(Ui.label("More worlds coming soon!", 28, Ui.INK_SOFT, 800))
	root.add_child(soon)


# --- Levels -----------------------------------------------------------------

func _start_level(n: int) -> void:
	screen = &"game"
	level = clampi(n, 1, Levels.count(WORLD))
	_clear_ui()
	if arena != null:
		arena.queue_free()
	arena = Arena.new()
	add_child(arena)
	arena.setup(WORLD, level, false)
	hud = Hud.new()
	hud.arena = arena
	hud.has_next = level < Levels.count(WORLD)
	hud.restart_requested.connect(func() -> void: _go(_start_level.bind(level)))
	hud.next_requested.connect(func() -> void: _go(_start_level.bind(level + 1)))
	hud.map_requested.connect(func() -> void: _go(_show_map))
	hud.home_requested.connect(func() -> void: _go(_show_menu))
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(hud)


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
			get_tree().quit()

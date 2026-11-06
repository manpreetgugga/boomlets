class_name Hud
extends Control
## The in-level interface: timer, star meter, critter count, power-up
## chips, the boss's health, the floating joystick (left half of the
## screen), the pod button (right half), and the pause / win / lose cards.
## Keyboard: arrows or WASD to move, Space to drop a pod, Esc or P to pause.

signal restart_requested
signal next_requested
signal map_requested
signal home_requested

const TOP_ZONE: float = 270.0
const JOY_RADIUS: float = 105.0

var arena: Arena
var has_next: bool = false
## Off when a test script drives the arena directly.
var auto_input: bool = true

var _joy_index: int = -1
var _joy_origin: Vector2
var _joy_vec: Vector2
var _pod_flash: float = 0.0
var _tip_t: float = 0.0
var _card: Control
var _card_stars: int = -1
var _card_t: float = 0.0
var _star_ctrl: Control
var _pause_btn: Btn
var _clock: float = 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_btn = Btn.make("", &"pause", Vector2(96, 96))
	_pause_btn.position = Vector2(24, 30)
	_pause_btn.pressed.connect(open_pause)
	add_child(_pause_btn)
	arena.won.connect(_on_won)
	arena.lost.connect(_on_lost)


func _controls_on() -> bool:
	return _card == null and arena != null and arena.state == &"play"


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE, KEY_ENTER, KEY_X:
				if _controls_on():
					_press_pod()
			KEY_ESCAPE, KEY_P:
				if _card == null:
					open_pause()
		return
	if not _controls_on():
		_joy_index = -1
		return
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			if pos.y < TOP_ZONE:
				return
			if pos.x < size.x * 0.5:
				if _joy_index == -1:
					_joy_index = event.index
					_joy_origin = pos
					_joy_vec = Vector2.ZERO
					_tip_t = maxf(_tip_t, 3.6)
			else:
				_press_pod()
		elif event.index == _joy_index:
			_joy_index = -1
			_joy_vec = Vector2.ZERO
	elif event is InputEventScreenDrag and event.index == _joy_index:
		_joy_vec = event.position - _joy_origin
		if _joy_vec.length() > JOY_RADIUS:
			_joy_origin = event.position - _joy_vec.normalized() * JOY_RADIUS
			_joy_vec = event.position - _joy_origin


func _press_pod() -> void:
	arena.drop_pod()
	_pod_flash = 1.0


func _process(delta: float) -> void:
	_clock += delta
	_tip_t += delta
	_pod_flash = maxf(_pod_flash - delta * 4.0, 0.0)
	if _card != null:
		_card_t += delta
		if _star_ctrl != null:
			_star_ctrl.queue_redraw()
	_feed_input()
	queue_redraw()


func _feed_input() -> void:
	if arena == null or not auto_input:
		return
	if not _controls_on():
		arena.set_input(Vector2i.ZERO, Vector2i.ZERO)
		return
	var kx: int = int(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D)) - int(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	var ky: int = int(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S)) - int(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
	if kx != 0 or ky != 0:
		_tip_t = maxf(_tip_t, 3.6)
		var h := Vector2i(kx, 0)
		var v := Vector2i(0, ky)
		if kx != 0:
			arena.set_input(h, v)
		else:
			arena.set_input(v, h)
		return
	var vec: Vector2 = _joy_vec if _joy_index != -1 else Vector2.ZERO
	if vec.length() < 20.0:
		arena.set_input(Vector2i.ZERO, Vector2i.ZERO)
		return
	var horiz := Vector2i(int(signf(vec.x)), 0)
	var vert := Vector2i(0, int(signf(vec.y)))
	if absf(vec.x) >= absf(vec.y):
		arena.set_input(horiz, vert if absf(vec.y) > vec.length() * 0.25 else Vector2i.ZERO)
	else:
		arena.set_input(vert, horiz if absf(vec.x) > vec.length() * 0.25 else Vector2i.ZERO)


# --- Drawing ----------------------------------------------------------------

func _pill(rect: Rect2, color: Color, radius: float = -1.0, shadow: bool = true) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(rect.size.y * 0.5 if radius < 0.0 else radius))
	sb.anti_aliasing = true
	if shadow:
		sb.shadow_color = Ui.SHADOW
		sb.shadow_size = 10
		sb.shadow_offset = Vector2(0, 6)
	draw_style_box(sb, rect)


func _text(t: String, at: Vector2, font_size: int, color: Color, weight: int = 900, centered: bool = true) -> void:
	var f: Font = Ui.font(weight)
	var w: float = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x: float = at.x - w * 0.5 if centered else at.x
	draw_string(f, Vector2(x, at.y + font_size * 0.36), t, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _draw() -> void:
	if arena == null:
		return
	var w: float = size.x
	# Info card: level, timer and the stars a finish now would earn.
	var card := Rect2(Vector2(w * 0.5 - 190, 30), Vector2(380, 124))
	_pill(card, Ui.CREAM, 34)
	_text("%d-%d  %s" % [arena.world_id, arena.level_id, arena.data["name"]], card.position + Vector2(190, 26), 24, Ui.INK_SOFT, 800)
	var left: float = arena.time_left()
	var hurry: bool = left < 30.0 and arena.state == &"play"
	var tcol: Color = Ui.RED if hurry and fmod(_clock, 0.5) < 0.3 else Ui.INK
	_text(Ui.time_text(left), card.position + Vector2(105, 78), 52, tcol)
	var now: int = arena.stars_for_time(arena.elapsed)
	for k in 3:
		var sc: Color = Ui.STAR if k < now else Color(Ui.INK, 0.15)
		Ui.draw_icon(self, &"star", card.position + Vector2(232 + k * 44, 66), 40, sc)
	var par: float = float(arena.data.get("par", 90))
	var goal: float = par if now >= 3 else par * 1.6
	var note: String = "3 stars to %s" % Ui.time_text(par) if now >= 3 else ("2 stars to %s" % Ui.time_text(goal) if now == 2 else "finish for 1 star")
	_text(note, card.position + Vector2(276, 102), 19, Ui.INK_SOFT, 800)

	# Critters left, or the open exit.
	var cc := Rect2(Vector2(w - 124, 30), Vector2(100, 96))
	if arena.exit_open:
		_pill(cc, Ui.MINT, 34)
		_text("EXIT", cc.get_center() + Vector2(0, -12), 26, Ui.INK)
		_text("open!", cc.get_center() + Vector2(0, 18), 20, Ui.INK, 800)
	else:
		_pill(cc, Ui.CREAM, 34)
		Ui.draw_icon(self, &"critter", cc.get_center() + Vector2(-22, 0), 40, Ui.PINK)
		_text(str(arena.critters_left()), cc.get_center() + Vector2(24, 2), 40, Ui.INK)

	# Power-up chips.
	var chips: Array = [[&"heart", str(arena.lives), Ui.RED], [&"pod", str(arena.max_pods), Ui.INK],
		[&"fire", str(arena.fire), Color("#FF7A59")], [&"speed", str(int(round((arena.speed - 3.2) / 0.5)) + 1), Color("#4FB477")]]
	if arena.can_kick:
		chips.append([&"kick", "", Ui.RED])
	if arena.shield:
		chips.append([&"shield", "", Color("#8FB8F0")])
	var cw: float = 0.0
	for ch: Array in chips:
		cw += 92.0 if ch[1] != "" else 58.0
	var x: float = w * 0.5 - (cw + (chips.size() - 1) * 8.0) * 0.5
	for ch: Array in chips:
		var cwid: float = 92.0 if ch[1] != "" else 58.0
		var r := Rect2(Vector2(x, 168), Vector2(cwid, 52))
		_pill(r, Color(Ui.CREAM, 0.92), -1, false)
		Ui.draw_icon(self, ch[0], r.position + Vector2(29, 26), 30, ch[2])
		if ch[1] != "":
			_text(ch[1], r.position + Vector2(66, 26), 28, Ui.INK)
		x += cwid + 8.0

	# The boss's health.
	if arena.boss != null:
		var bar := Rect2(Vector2(w * 0.5 - 200, 262), Vector2(400, 30))
		_pill(bar, Ui.INK, -1, false)
		var seg: float = (bar.size.x - 12.0) / Arena.BOSS_HP
		for k in arena.boss.hp:
			_pill(Rect2(bar.position + Vector2(6 + k * seg, 5), Vector2(seg - 4, 20)), Ui.RED, -1, false)
		_text("THORNBACK", bar.position + Vector2(200, -16), 20, Ui.INK, 900)

	# The level's tip, for the first few seconds.
	if _tip_t < 4.5 and arena.data.has("tip"):
		var a: float = clampf((4.5 - _tip_t) / 0.5, 0.0, 1.0) * clampf(_tip_t / 0.3, 0.0, 1.0)
		var lines: PackedStringArray = String(arena.data["tip"]).split("\n")
		var th: float = 30.0 + lines.size() * 40.0
		var tr := Rect2(Vector2(w * 0.5 - 300, size.y - 440), Vector2(600, th))
		_pill(tr, Color(Ui.CREAM, 0.95 * a), 30, false)
		for i in lines.size():
			_text(lines[i], tr.position + Vector2(300, 35 + i * 40), 28, Color(Ui.INK, a), 800)

	if _card != null or arena.state != &"play":
		return
	# Joystick.
	var home := Vector2(170, size.y - 230)
	var origin: Vector2 = _joy_origin if _joy_index != -1 else home
	var alpha: float = 0.55 if _joy_index != -1 else 0.3
	draw_circle(origin, JOY_RADIUS, Color(1, 1, 1, alpha * 0.45))
	draw_arc(origin, JOY_RADIUS, 0, TAU, 48, Color(1, 1, 1, alpha + 0.2), 5.0, true)
	var knob: Vector2 = origin + (_joy_vec.limit_length(JOY_RADIUS) if _joy_index != -1 else Vector2.ZERO)
	draw_circle(knob + Vector2(0, 5), 52, Color(Ui.SHADOW, 0.3))
	draw_circle(knob, 52, Color(Ui.CREAM, 0.95 if _joy_index != -1 else 0.7))
	# Pod button.
	var pc := Vector2(size.x - 170, size.y - 230)
	var ready: bool = arena.pods_out < arena.max_pods
	var rad: float = 100.0 * (1.0 - _pod_flash * 0.08)
	draw_circle(pc + Vector2(0, 8), rad, Color(Ui.SHADOW, 0.35))
	draw_circle(pc, rad, Ui.YELLOW if ready else Ui.YELLOW.darkened(0.3))
	draw_circle(pc + Vector2(0, -rad * 0.35), rad * 0.55, Color(1, 1, 1, 0.18))
	Ui.draw_icon(self, &"pod", pc + Vector2(0, 6), 96, Ui.INK)
	var left_pods: int = arena.max_pods - arena.pods_out
	draw_circle(pc + Vector2(rad * 0.7, -rad * 0.7), 28, Ui.INK)
	_text(str(left_pods), pc + Vector2(rad * 0.7, -rad * 0.7), 30, Ui.CREAM)


# --- Cards ------------------------------------------------------------------

func _open_card(title: String, buttons: Array, stars: int = -1, lines: Array = []) -> void:
	_close_card()
	_card_t = 0.0
	_card_stars = stars
	var dim := ColorRect.new()
	dim.color = Color(0.16, 0.12, 0.25, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	_card = dim
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := Ui.card(Ui.CREAM, 44)
	panel.custom_minimum_size = Vector2(520, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 18)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(box)
	box.add_child(Ui.label(title, 54, Ui.INK, 900))
	if stars >= 0:
		_star_ctrl = Control.new()
		_star_ctrl.custom_minimum_size = Vector2(400, 120)
		_star_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_star_ctrl.draw.connect(_draw_card_stars)
		box.add_child(_star_ctrl)
	for line: String in lines:
		box.add_child(Ui.label(line, 28, Ui.INK_SOFT, 800))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)
	for spec: Array in buttons:
		var b := Btn.make(spec[0], spec[1], Vector2(400, 100), spec[3] if spec.size() > 3 else Ui.CREAM.darkened(0.06))
		b.font_size = 38
		b.pressed.connect(spec[2])
		var holder := CenterContainer.new()
		holder.add_child(b)
		box.add_child(holder)
	panel.pivot_offset = Vector2(260, 300)
	panel.scale = Vector2(0.85, 0.85)
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw_card_stars() -> void:
	for k in 3:
		var appear: float = clampf((_card_t - 0.3 - k * 0.25) / 0.2, 0.0, 1.0)
		var c := Vector2(200 + (k - 1) * 120, 60 - (14 if k == 1 else 0))
		Ui.draw_icon(_star_ctrl, &"star", c, 100, Color(Ui.INK, 0.12))
		if k < _card_stars and appear > 0.0:
			var s: float = 100.0 * (1.0 + sin(appear * PI) * 0.35) * appear
			Ui.draw_icon(_star_ctrl, &"star", c, s, Ui.STAR)


func _close_card() -> void:
	if _card != null:
		_card.queue_free()
		_card = null
		_star_ctrl = null


func open_pause() -> void:
	if _card != null or arena == null or arena.state != &"play":
		return
	get_tree().paused = true
	_pause_btn.visible = false
	_open_card("Paused", [
		["Resume", &"play", _resume, Ui.YELLOW],
		["Restart", &"restart", func() -> void: restart_requested.emit()],
		["Levels", &"list", func() -> void: map_requested.emit()],
		["Home", &"home", func() -> void: home_requested.emit()],
	])


func _resume() -> void:
	_close_card()
	_pause_btn.visible = true
	get_tree().paused = false


func _on_won(stars: int, seconds: float) -> void:
	var better: bool = Save.record(arena.world_id, arena.level_id, stars, seconds)
	_pause_btn.visible = false
	var best: float = float(Save.best_time.get(Save.key(arena.world_id, arena.level_id), seconds))
	var lines: Array = ["Time %s   Best %s" % [Ui.time_text(seconds), Ui.time_text(best)]]
	if better:
		lines.append("New best!")
	var buttons: Array = []
	if has_next:
		buttons.append(["Next", &"next", func() -> void: next_requested.emit(), Ui.YELLOW])
	else:
		lines.append("Meadow Isles cleared!")
	buttons.append(["Replay", &"restart", func() -> void: restart_requested.emit()])
	buttons.append(["Levels", &"list", func() -> void: map_requested.emit()])
	_open_card("Cleared!", buttons, stars, lines)


func _on_lost(reason: String) -> void:
	_pause_btn.visible = false
	_open_card(reason, [
		["Try again", &"restart", func() -> void: restart_requested.emit(), Ui.YELLOW],
		["Levels", &"list", func() -> void: map_requested.emit()],
	], -1, ["Critters left: %d" % arena.critters_left()])

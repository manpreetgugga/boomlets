class_name Btn
extends Control
## A soft rounded button for touch: squashes while held and fires
## [signal pressed] when released over it. Shows [member icon] (see
## Ui.draw_icon) or [member text]; [member caption] sits under a round one.

signal pressed

var icon: StringName = &""
var text: String = ""
var caption: String = ""
var color: Color = Ui.CREAM
var ink: Color = Ui.INK
var font_size: int = 40
## Stars (0-3) drawn under a level badge; -1 draws none.
var stars: int = -1
var dimmed: bool = false:
	set(v):
		dimmed = v
		queue_redraw()

var _down: bool = false
var _squash: float = 1.0


static func make(btn_text: String, btn_icon: StringName, size_px: Vector2, fill: Color = Ui.CREAM) -> Btn:
	var b := Btn.new()
	b.text = btn_text
	b.icon = btn_icon
	b.custom_minimum_size = size_px
	b.size = size_px
	b.color = fill
	return b


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	pivot_offset = size * 0.5
	resized.connect(func() -> void: pivot_offset = size * 0.5)


func _process(delta: float) -> void:
	var goal: float = 0.9 if _down else 1.0
	if absf(_squash - goal) > 0.001:
		_squash = lerpf(_squash, goal, minf(delta * 20.0, 1.0))
		scale = Vector2(_squash, _squash)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_down = true
		elif _down:
			_down = false
			if Rect2(Vector2.ZERO, size).has_point(event.position):
				Sfx.play(&"click", 0.02)
				Save.buzz(10)
				pressed.emit()
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_down = false


func _draw() -> void:
	var r: float = minf(size.x, size.y) * 0.5
	var rect := Rect2(Vector2.ZERO, size)
	var fill: Color = color.darkened(0.25) if dimmed else color
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_corner_radius_all(int(r))
	sb.anti_aliasing = true
	sb.shadow_color = Ui.SHADOW
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 6)
	draw_style_box(sb, rect)
	var lip := StyleBoxFlat.new()
	lip.bg_color = Color(1, 1, 1, 0.22)
	lip.set_corner_radius_all(int(r))
	lip.anti_aliasing = true
	draw_style_box(lip, Rect2(Vector2(size.x * 0.06, 4), Vector2(size.x * 0.88, size.y * 0.42)))
	if icon != &"" and text == "":
		Ui.draw_icon(self, icon, size * 0.5, minf(size.x, size.y) * 0.5, ink)
	else:
		var f: Font = Ui.font(900)
		var x0: float = 0.0
		if icon != &"":
			Ui.draw_icon(self, icon, Vector2(size.y * 0.55, size.y * 0.5), size.y * 0.42, ink)
			x0 = size.y * 0.35
		var tw: float = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		draw_string(f, Vector2(x0 + (size.x - x0 - tw) * 0.5, size.y * 0.5 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
	var below: float = size.y + 6.0
	if stars >= 0:
		for k in 3:
			Ui.draw_icon(self, &"star", Vector2(size.x * 0.5 + (k - 1) * 36, below + 14 - (6 if k == 1 else 0)), 34, Ui.STAR if k < stars else Color(Ui.INK, 0.18))
		below += 30.0
	if caption != "":
		var f2: Font = Ui.font(800)
		var cw: float = f2.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		draw_string(f2, Vector2((size.x - cw) * 0.5, below + 26), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Ui.INK)

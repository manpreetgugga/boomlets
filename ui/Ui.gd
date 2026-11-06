class_name Ui
extends RefCounted
## Shared look for the interface: colours, Nunito at any weight, card
## styles and icons drawn in code (no image files).

const FONT: FontFile = preload("res://fonts/Nunito.ttf")

const CREAM := Color("#FFF4E2")
const INK := Color("#2E2A4A")
const INK_SOFT := Color("#6B6585")
const YELLOW := Color("#FFD166")
const ORANGE := Color("#F2A541")
const MINT := Color("#7FE3C4")
const PINK := Color("#F28DB2")
const RED := Color("#E4572E")
const STAR := Color("#F7C531")
const SHADOW := Color(0.18, 0.12, 0.25, 0.22)

static var _weights: Dictionary = {}


static func font(weight: int = 800) -> Font:
	if not _weights.has(weight):
		var v := FontVariation.new()
		v.base_font = FONT
		v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_weights[weight] = v
	return _weights[weight]


static func label(text: String, size: int, color: Color = INK, weight: int = 800) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", font(weight))
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func outlined(l: Label, outline: Color, size: int) -> Label:
	l.add_theme_color_override(&"font_outline_color", outline)
	l.add_theme_constant_override(&"outline_size", size)
	return l


static func card_style(color: Color = CREAM, radius: int = 36) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.shadow_color = SHADOW
	s.shadow_size = 14
	s.shadow_offset = Vector2(0, 8)
	s.anti_aliasing = true
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 22
	s.content_margin_bottom = 22
	return s


static func card(color: Color = CREAM, radius: int = 36) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override(&"panel", card_style(color, radius))
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


static func time_text(seconds: float) -> String:
	var s: int = int(ceil(seconds))
	return "%d:%02d" % [s / 60, s % 60]


static func star_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 10:
		var a: float = -PI * 0.5 + PI * k / 5.0
		var rr: float = r if k % 2 == 0 else r * 0.48
		pts.append(center + Vector2(cos(a), sin(a)) * rr)
	return pts


static func heart_points(center: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 32:
		var t: float = TAU * k / 32.0
		pts.append(center + Vector2(16.0 * pow(sin(t), 3.0), -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))) * r / 17.0)
	return pts


## Draws a named icon centred at [param c], about [param s] pixels across.
static func draw_icon(ci: CanvasItem, icon: StringName, c: Vector2, s: float, color: Color) -> void:
	var h: float = s * 0.5
	match icon:
		&"pause":
			ci.draw_rect(Rect2(c + Vector2(-h * 0.55, -h * 0.6), Vector2(h * 0.38, h * 1.2)), color)
			ci.draw_rect(Rect2(c + Vector2(h * 0.17, -h * 0.6), Vector2(h * 0.38, h * 1.2)), color)
		&"play":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.45, -h * 0.65), c + Vector2(h * 0.7, 0), c + Vector2(-h * 0.45, h * 0.65)]), color)
		&"restart":
			ci.draw_arc(c, h * 0.6, -PI * 0.35, PI * 1.45, 24, color, h * 0.26, true)
			var tip: Vector2 = c + Vector2(cos(-PI * 0.35), sin(-PI * 0.35)) * h * 0.6
			ci.draw_colored_polygon(PackedVector2Array([tip + Vector2(-h * 0.35, -h * 0.2), tip + Vector2(h * 0.25, -h * 0.35), tip + Vector2(h * 0.1, h * 0.3)]), color)
		&"home":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -h * 0.75), c + Vector2(h * 0.75, -h * 0.05), c + Vector2(-h * 0.75, -h * 0.05)]), color)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.5, -h * 0.1), Vector2(h, h * 0.75)), color)
		&"list":
			for k in 3:
				ci.draw_circle(c + Vector2(-h * 0.5, (k - 1) * h * 0.5), h * 0.12, color)
				ci.draw_rect(Rect2(c + Vector2(-h * 0.25, (k - 1) * h * 0.5 - h * 0.1), Vector2(h * 0.85, h * 0.2)), color)
		&"next":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.6, -h * 0.6), c + Vector2(h * 0.25, 0), c + Vector2(-h * 0.6, h * 0.6)]), color)
			ci.draw_rect(Rect2(c + Vector2(h * 0.3, -h * 0.6), Vector2(h * 0.26, h * 1.2)), color)
		&"back":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.7, 0), c + Vector2(0, -h * 0.6), c + Vector2(0, h * 0.6)]), color)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.1, -h * 0.2), Vector2(h * 0.75, h * 0.4)), color)
		&"star":
			ci.draw_colored_polygon(star_points(c, h), color)
		&"heart":
			ci.draw_colored_polygon(heart_points(c, h), color)
		&"pod":
			ci.draw_circle(c + Vector2(0, h * 0.12), h * 0.7, color)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.18, -h * 0.82), Vector2(h * 0.36, h * 0.3)), color)
			ci.draw_line(c + Vector2(h * 0.05, -h * 0.8), c + Vector2(h * 0.35, -h * 1.05), color, h * 0.12)
			ci.draw_circle(c + Vector2(-h * 0.25, -h * 0.12), h * 0.16, Color(1, 1, 1, 0.55))
		&"fire":
			var pts := PackedVector2Array()
			for k in 20:
				var t: float = TAU * k / 20.0
				var r: float = h * (0.55 + 0.45 * pow(maxf(-sin(t), 0.0), 3.0))
				pts.append(c + Vector2(cos(t) * h * 0.6, sin(t) * r) + Vector2(0, h * 0.18))
			ci.draw_colored_polygon(pts, color)
		&"speed":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.15, -h * 0.9), c + Vector2(-h * 0.55, h * 0.1), c + Vector2(-h * 0.05, h * 0.1), c + Vector2(-h * 0.2, h * 0.9), c + Vector2(h * 0.55, -h * 0.15), c + Vector2(h * 0.05, -h * 0.15)]), color)
		&"kick":
			var boot := PackedVector2Array([c + Vector2(-h * 0.45, -h * 0.8), c + Vector2(h * 0.1, -h * 0.8), c + Vector2(h * 0.1, h * 0.05), c + Vector2(h * 0.75, h * 0.15), c + Vector2(h * 0.75, h * 0.7), c + Vector2(-h * 0.45, h * 0.7)])
			ci.draw_colored_polygon(boot, color)
		&"shield":
			ci.draw_circle(c, h * 0.78, color)
			ci.draw_circle(c + Vector2(-h * 0.25, -h * 0.25), h * 0.18, Color(1, 1, 1, 0.7))
		&"critter":
			ci.draw_circle(c + Vector2(0, h * 0.15), h * 0.75, color)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.75, h * 0.15), Vector2(h * 1.5, h * 0.6)), color)
			for side: int in [-1, 1]:
				ci.draw_circle(c + Vector2(side * h * 0.28, -h * 0.05), h * 0.2, Color.WHITE)
				ci.draw_circle(c + Vector2(side * h * 0.28, 0), h * 0.1, INK)
		&"lock":
			ci.draw_arc(c + Vector2(0, -h * 0.25), h * 0.38, PI, TAU, 16, color, h * 0.18, true)
			ci.draw_rect(Rect2(c + Vector2(-h * 0.58, -h * 0.2), Vector2(h * 1.16, h * 0.95)), color)
		&"sound", &"music":
			if icon == &"sound":
				ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-h * 0.7, -h * 0.25), c + Vector2(-h * 0.35, -h * 0.25), c + Vector2(h * 0.05, -h * 0.65), c + Vector2(h * 0.05, h * 0.65), c + Vector2(-h * 0.35, h * 0.25), c + Vector2(-h * 0.7, h * 0.25)]), color)
				ci.draw_arc(c + Vector2(h * 0.1, 0), h * 0.45, -0.8, 0.8, 10, color, h * 0.12, true)
			else:
				ci.draw_circle(c + Vector2(-h * 0.35, h * 0.45), h * 0.24, color)
				ci.draw_circle(c + Vector2(h * 0.45, h * 0.3), h * 0.24, color)
				ci.draw_line(c + Vector2(-h * 0.13, h * 0.45), c + Vector2(-h * 0.13, -h * 0.6), color, h * 0.14)
				ci.draw_line(c + Vector2(h * 0.67, h * 0.3), c + Vector2(h * 0.67, -h * 0.75), color, h * 0.14)
				ci.draw_line(c + Vector2(-h * 0.13, -h * 0.6), c + Vector2(h * 0.67, -h * 0.75), color, h * 0.2)

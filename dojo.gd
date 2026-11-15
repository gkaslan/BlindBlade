extends Node2D

const FLOOR_TEX = "res://BlindBlade_Sprites/zemin.png"
const FLOOR_SCALE = 1.0                      # zemini büyütmek/küçültmek için
const WALL = 40.0                            # duvar kalınlığı
const BRICK_H = 20.0                         # tuğla yüksekliği
const BRICK_W = 40.0                         # tuğla genişliği

const WALL_COLOR = Color(0.42, 0.26, 0.16)   # duvar ana rengi
const WALL_LINE = Color(0.18, 0.10, 0.06)    # tuğla araları
const WALL_LIGHT = Color(0.62, 0.42, 0.26)   # dış parlak kenar
const WALL_DARK = Color(0.08, 0.04, 0.02)    # iç koyu kenar
const SHADOW = Color(0, 0, 0, 0.35)          # duvarın zemine gölgesi
const SHADOW_SIZE = 10.0

var floor_tex
var room = Rect2(-373, -377, 746, 754)

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(FLOOR_TEX):
		floor_tex = load(FLOOR_TEX)
		var s = floor_tex.get_size() * FLOOR_SCALE
		room = Rect2(-s / 2.0, s)
	else:
		push_warning("Zemin dosyası bulunamadı: " + FLOOR_TEX)
	_build_walls()
	queue_redraw()

func _wall_rects() -> Array:
	var r = room
	var t = WALL
	return [
		Rect2(r.position.x - t, r.position.y - t, r.size.x + 2.0 * t, t),  # üst
		Rect2(r.position.x - t, r.end.y, r.size.x + 2.0 * t, t),           # alt
		Rect2(r.position.x - t, r.position.y, t, r.size.y),                # sol
		Rect2(r.end.x, r.position.y, t, r.size.y),                         # sağ
	]

func _build_walls():
	for rect in _wall_rects():
		var body = StaticBody2D.new()
		body.position = rect.get_center()
		var shape = CollisionShape2D.new()
		var rs = RectangleShape2D.new()
		rs.size = rect.size
		shape.shape = rs
		body.add_child(shape)
		add_child(body)

func _draw():
	# Zemin
	if floor_tex:
		draw_texture_rect(floor_tex, room, false)
	else:
		draw_rect(room, Color(0.55, 0.51, 0.4))

	# Duvarların zemine düşen gölgesi
	var r = room
	var s = SHADOW_SIZE
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, s), SHADOW)
	draw_rect(Rect2(r.position.x, r.end.y - s, r.size.x, s), SHADOW)
	draw_rect(Rect2(r.position.x, r.position.y, s, r.size.y), SHADOW)
	draw_rect(Rect2(r.end.x - s, r.position.y, s, r.size.y), SHADOW)

	# Duvarlar
	for rect in _wall_rects():
		_draw_wall(rect)

	# Duvarın zemine bakan iç kenarı
	draw_rect(room, WALL_DARK, false, 3.0)

func _draw_wall(rect: Rect2):
	draw_rect(rect, WALL_COLOR)

	# Tuğla araları (sıralar birbirine kaydırılmış)
	var row = 0
	var y = rect.position.y
	while y < rect.end.y:
		var h = minf(BRICK_H, rect.end.y - y)
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), WALL_LINE, 2.0)
		var off = 0.0 if row % 2 == 0 else BRICK_W / 2.0
		var x = rect.position.x + off
		while x < rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, y + h), WALL_LINE, 2.0)
			x += BRICK_W
		y += BRICK_H
		row += 1

	# Parlak dış kenar ve koyu çerçeve
	draw_rect(rect, WALL_DARK, false, 3.0)
	draw_line(rect.position + Vector2(2, 2), Vector2(rect.end.x - 2, rect.position.y + 2), WALL_LIGHT, 2.0)

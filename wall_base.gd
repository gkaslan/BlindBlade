extends StaticBody2D

const H = 36.0
const PAPER = Color(0.72, 0.68, 0.55)
const PAPER_SHADE = Color(0.60, 0.56, 0.44)
const WOOD = Color(0.22, 0.12, 0.07)
const WOOD_LIGHT = Color(0.34, 0.20, 0.11)
const ROOF = Color(0.16, 0.18, 0.22)
const ROOF_LINE = Color(0.09, 0.10, 0.13)
const ROOF_EDGE = Color(0.38, 0.42, 0.50)

func _ready():
	var rect = $ColorRect
	rect.color = Color(0, 0, 0, 0)
	var col = $CollisionShape2D
	var shape = RectangleShape2D.new()
	shape.size = rect.size
	col.shape = shape
	col.scale = Vector2.ONE
	col.rotation = 0
	col.disabled = false
	col.position = rect.position + rect.size / 2
	collision_layer = 1
	collision_mask = 1
	queue_redraw()

func get_r() -> Rect2:
	return Rect2($ColorRect.position, $ColorRect.size)

func draw_face(face: Rect2):
	var paper = Rect2(face.position.x, face.position.y + 5, face.size.x, face.size.y - 11)
	draw_rect(paper, PAPER)
	draw_rect(Rect2(paper.position.x, paper.end.y - 5, paper.size.x, 5), PAPER_SHADE)
	var x = face.position.x + 16.0
	while x < face.end.x:
		draw_line(Vector2(x, paper.position.y), Vector2(x, paper.end.y), WOOD_LIGHT, 2.0)
		x += 16.0
	var mid = paper.position.y + paper.size.y / 2.0
	draw_line(Vector2(face.position.x, mid), Vector2(face.end.x, mid), WOOD_LIGHT, 2.0)
	draw_rect(Rect2(face.position.x, face.position.y, face.size.x, 5), WOOD)
	draw_rect(Rect2(face.position.x, face.end.y - 6, face.size.x, 6), WOOD)
	draw_rect(Rect2(face.position.x, face.position.y, 4, face.size.y), WOOD)
	draw_rect(Rect2(face.end.x - 4, face.position.y, 4, face.size.y), WOOD)
	var px = face.position.x + 96.0
	while px < face.end.x - 4:
		draw_rect(Rect2(px, face.position.y, 4, face.size.y), WOOD)
		px += 96.0

func draw_roof(cap: Rect2, horizontal: bool, edge: String):
	draw_rect(cap, ROOF)
	if horizontal:
		var cx = cap.position.x + 8.0
		while cx < cap.end.x:
			draw_line(Vector2(cx, cap.position.y), Vector2(cx, cap.end.y), ROOF_LINE, 2.0)
			cx += 8.0
	else:
		var cy = cap.position.y + 8.0
		while cy < cap.end.y:
			draw_line(Vector2(cap.position.x, cy), Vector2(cap.end.x, cy), ROOF_LINE, 2.0)
			cy += 8.0
	match edge:
		"top":
			draw_line(cap.position, Vector2(cap.end.x, cap.position.y), ROOF_EDGE, 2.0)
		"bottom":
			draw_line(Vector2(cap.position.x, cap.end.y), cap.end, ROOF_EDGE, 2.0)
		"left":
			draw_line(cap.position, Vector2(cap.position.x, cap.end.y), ROOF_EDGE, 2.0)
		"right":
			draw_line(Vector2(cap.end.x, cap.position.y), cap.end, ROOF_EDGE, 2.0)

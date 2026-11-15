extends "res://wall_base.gd"

func _draw():
	var r = get_r()
	draw_face(Rect2(r.position.x, r.end.y - H, r.size.x, H))
	draw_roof(Rect2(r.position.x, r.position.y - H, r.size.x, r.size.y), true, "top")

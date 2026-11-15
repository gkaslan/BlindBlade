extends "res://wall_base.gd"

func _draw():
	var r = get_r()
	draw_roof(r, true, "bottom")
	draw_face(Rect2(r.position.x, r.end.y, r.size.x, H))

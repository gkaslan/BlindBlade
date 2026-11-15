extends Control

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(title)

	var hint = Label.new()
	hint.text = "R, Enter veya sol tık: yeniden başla"
	hint.add_theme_font_size_override("font_size", 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hint.offset_top = 90
	add_child(hint)

func _input(event):
	var restart = false
	if event is InputEventKey and event.pressed:
		restart = event.keycode == KEY_R or event.keycode == KEY_ENTER
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		restart = true
	if restart:
		get_tree().change_scene_to_file("res://dojo.tscn")

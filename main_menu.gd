extends Control

const GAME_SCENE = "res://dojo.tscn"
const RED = Color(0.95, 0.12, 0.12)
const MUSIC_DIR = "res://BlindBlade_Music/"

const CHARACTER_PATHS = [
	"res://BlindBlade_auido/player_idle.png",
	"res://player_idle.png",
	"res://BlindBlade_Sprites/player_idle.png",
]

const LORE_TEXT = "Eski zamanların en acımasız ve elit samurayı Kaira idi. Sayısız düşman avladı, ta ki onu kendisine bir tehdit olarak gören İmparator Daigo'nun askerleri evine sızıp küçük oğlunu katledene kadar. O sonbahar akşamı evladının cansız bedenini bulan Kaira, günlerce süren derin keder ve dinmeyen gözyaşlarının ardından dünyaya olan ışığını—gözlerini—neredeyse tamamen kaybetti. Kılıcının getirdiği lanetten vazgeçip bir daha asla savaşmamaya yemin etti.\n\nYıllar sonra bile İmparator Daigo, Kaira'nın kör olmasına rağmen halk arasında efsaneleşmesinden ve saraya dair bildiklerinden korkuyordu. Bir gece Kaira ıssız kulübesinde yağmurun sesini dinlerken, dışarıdaki rüzgârın ritmi değişti. Kapısı yavaşça aralandı ve karanlığın içinden süzülen suikastçıların kılıç çekme sesi yankılandı. Kaira artık göremiyordu ama yıllar süren sessizlik ona her sesi bir görüntüye dönüştürmeyi öğretmişti.\n\nYeminini bozma vakti gelmişti..."

const CRAWL_DURATION = 64.0

var menu_layer: Control
var how_to_layer: Control
var story_layer: Control
var settings_layer: Control
var story_label: Label
var story_tween: Tween

var menu_music: AudioStreamPlayer
var story_music: AudioStreamPlayer

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.01, 0.01)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	menu_music = AudioStreamPlayer.new()
	menu_music.bus = "Music"
	add_child(menu_music)
	var mm = _load_music("menu_theme.ogg")
	if mm:
		mm.loop = true
		menu_music.stream = mm
		menu_music.play()

	story_music = AudioStreamPlayer.new()
	story_music.bus = "Music"
	add_child(story_music)
	var sm = _load_music("story_theme.ogg")
	if sm:
		story_music.stream = sm

	menu_layer = _build_main_layer()
	add_child(menu_layer)

	how_to_layer = _build_how_to_layer()
	how_to_layer.visible = false
	add_child(how_to_layer)

	story_layer = _build_story_layer()
	story_layer.visible = false
	add_child(story_layer)

	settings_layer = _build_settings_layer()
	settings_layer.visible = false
	add_child(settings_layer)

func _load_music(file_name: String):
	var path = MUSIC_DIR + file_name
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Müzik bulunamadı: " + path)
	return null

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if settings_layer.visible or how_to_layer.visible:
			_show_menu()
			return
		if story_layer.visible:
			_end_story()
			return
	if story_layer.visible and event is InputEventMouseButton and event.pressed:
		_end_story()

func _build_main_layer() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 100)
	center.add_child(row)
	row.add_child(_build_character())
	row.add_child(_build_menu())
	return center

func _find_character():
	for path in CHARACTER_PATHS:
		if ResourceLoader.exists(path):
			return load(path)
	push_warning("Karakter dosyası bulunamadı: player_idle.png")
	return null

func _build_character() -> Control:
	var holder = Control.new()
	holder.custom_minimum_size = Vector2(320, 320)
	var g = Gradient.new()
	g.colors = PackedColorArray([Color(1, 0.1, 0.1, 0.35), Color(1, 0.1, 0.1, 0.0)])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	var tex = GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 256
	tex.height = 256
	var glow = TextureRect.new()
	glow.texture = tex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.position = Vector2(-20, -20)
	glow.size = Vector2(360, 360)
	holder.add_child(glow)
	var sprite = TextureRect.new()
	sprite.texture = _find_character()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = Vector2(256, 256)
	sprite.position = Vector2(32, 40)
	holder.add_child(sprite)
	var t = create_tween().set_loops()
	t.tween_property(sprite, "position:y", 32.0, 1.2).set_trans(Tween.TRANS_SINE)
	t.tween_property(sprite, "position:y", 40.0, 1.2).set_trans(Tween.TRANS_SINE)
	return holder

func _build_menu() -> Control:
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	var title = Label.new()
	title.text = "BLINDBLADE"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", RED)
	box.add_child(title)
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 24)
	box.add_child(gap)

	var play = Button.new()
	play.text = "PLAY"
	_style_button(play)
	play.pressed.connect(_on_play)
	box.add_child(play)

	var how_to = Button.new()
	how_to.text = "HOW TO PLAY"
	_style_button(how_to)
	how_to.pressed.connect(_show_how_to)
	box.add_child(how_to)

	var story = Button.new()
	story.text = "STORY"
	_style_button(story)
	story.pressed.connect(_show_story)
	box.add_child(story)

	var settings = Button.new()
	settings.text = "SETTINGS"
	_style_button(settings)
	settings.pressed.connect(_show_settings)
	box.add_child(settings)

	play.grab_focus()
	return box

func _style_button(b: Button):
	b.custom_minimum_size = Vector2(320, 56)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", RED)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_focus_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _box(Color(0, 0, 0, 0.6), RED))
	b.add_theme_stylebox_override("hover", _box(Color(1, 0.1, 0.1, 0.2), RED))
	b.add_theme_stylebox_override("pressed", _box(Color(1, 0.1, 0.1, 0.35), RED))
	b.add_theme_stylebox_override("focus", _box(Color(1, 0.1, 0.1, 0.14), Color.WHITE))

func _box(fill: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.content_margin_left = 16
	s.content_margin_right = 16
	return s

func _build_how_to_layer() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.custom_minimum_size = Vector2(520, 0)
	center.add_child(box)
	var title = Label.new()
	title.text = "HOW TO PLAY"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 16)
	box.add_child(gap)
	var lines = [
		["WASD", "Hareket et"],
		["SHIFT", "Koş (stamina harcar)"],
		["SOL TIK", "Saldır (sersemlemiş düşmanı keser)"],
		["SAĞ TIK", "Savun / parry (düşmanın vuruşunu karşıla)"],
		["FARE", "Nişan yönü - saldırı ve savunma farenin baktığı 90° açıda çalışır"],
	]
	for pair in lines:
		box.add_child(_build_line(pair[0], pair[1]))
	var gap2 = Control.new()
	gap2.custom_minimum_size = Vector2(0, 16)
	box.add_child(gap2)
	var tip = Label.new()
	tip.text = "İpucu: Düşmanın kırmızı yayı büyürken sağ tıkla savun, sersemlerse sol tıkla bitir."
	tip.add_theme_font_size_override("font_size", 16)
	tip.add_theme_color_override("font_color", Color(0.75, 0.75, 0.78))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD
	box.add_child(tip)
	var gap3 = Control.new()
	gap3.custom_minimum_size = Vector2(0, 20)
	box.add_child(gap3)
	var back = Button.new()
	back.text = "GERİ"
	_style_button(back)
	back.pressed.connect(_show_menu)
	box.add_child(back)
	return center

func _build_line(key: String, desc: String) -> Control:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var key_label = Label.new()
	key_label.text = key
	key_label.custom_minimum_size = Vector2(110, 0)
	key_label.add_theme_font_size_override("font_size", 18)
	key_label.add_theme_color_override("font_color", RED)
	row.add_child(key_label)
	var desc_label = Label.new()
	desc_label.text = desc
	desc_label.add_theme_font_size_override("font_size", 18)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(desc_label)
	return row

func _build_story_layer() -> Control:
	var root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.clip_contents = true
	var vsize = get_viewport_rect().size
	story_label = Label.new()
	story_label.text = LORE_TEXT
	story_label.add_theme_font_size_override("font_size", 28)
	story_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	story_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	story_label.custom_minimum_size = Vector2(vsize.x * 0.6, 0)
	story_label.size = Vector2(vsize.x * 0.6, 0)
	story_label.position.x = vsize.x * 0.2
	root.add_child(story_label)
	return root

func _build_settings_layer() -> Control:
	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	box.custom_minimum_size = Vector2(420, 0)
	center.add_child(box)

	var title = Label.new()
	title.text = "SETTINGS"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", RED)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	box.add_child(_build_slider("Müzik", AudioSettings.music_volume, func(v): AudioSettings.set_music_volume(v)))
	box.add_child(_build_slider("Ses Efektleri", AudioSettings.sfx_volume, func(v): AudioSettings.set_sfx_volume(v)))

	var gap = Control.new()
	gap.custom_minimum_size = Vector2(0, 10)
	box.add_child(gap)

	var back = Button.new()
	back.text = "GERİ"
	_style_button(back)
	back.pressed.connect(_show_menu)
	box.add_child(back)

	return center

func _build_slider(label_text: String, initial: float, on_change: Callable) -> Control:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	var lbl = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	col.add_child(lbl)
	var slider = HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = initial
	slider.custom_minimum_size = Vector2(0, 24)
	slider.value_changed.connect(func(v): on_change.call(v))
	col.add_child(slider)
	return col

func _show_how_to():
	menu_layer.visible = false
	how_to_layer.visible = true

func _show_settings():
	menu_layer.visible = false
	settings_layer.visible = true

func _show_story():
	menu_layer.visible = false
	story_layer.visible = true

	var vsize = get_viewport_rect().size
	story_label.position.y = vsize.y
	await get_tree().process_frame
	var end_y = -story_label.size.y

	var fo = create_tween()
	fo.tween_property(menu_music, "volume_db", -40.0, 0.3)

	if story_music.stream:
		story_music.volume_db = 0.0
		story_music.play()

	story_tween = create_tween()
	story_tween.tween_property(story_label, "position:y", end_y, CRAWL_DURATION) \
		.from(vsize.y).set_trans(Tween.TRANS_LINEAR)
	story_tween.tween_callback(_end_story)

func _end_story():
	if story_tween and story_tween.is_valid():
		story_tween.kill()
	story_music.stop()
	story_music.volume_db = 0.0

	story_layer.visible = false
	menu_layer.visible = true
	if menu_music.stream:
		menu_music.volume_db = -40.0
		if not menu_music.playing:
			menu_music.play()
		var fi = create_tween()
		fi.tween_property(menu_music, "volume_db", 0.0, 0.6)

func _show_menu():
	how_to_layer.visible = false
	settings_layer.visible = false
	if story_layer.visible:
		_end_story()
	menu_layer.visible = true

func _on_play():
	get_tree().change_scene_to_file(GAME_SCENE)

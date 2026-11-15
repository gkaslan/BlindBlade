extends Node2D

const CONE = PI / 4.0
const RING = 80.0
const HEART_SCALE = 2.0
const HEART_PATHS = [
	"res://BlindBlade_auido/",
	"res://hearts/",
	"res://",
]

var player
var manager
var heart_full
var heart_cracked
var heart_broken

func _ready():
	player = get_tree().get_first_node_in_group("player")
	manager = get_tree().get_first_node_in_group("manager")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	heart_full = _load_heart("heart_full.png")
	heart_cracked = _load_heart("heart_cracked.png")
	heart_broken = _load_heart("heart_broken.png")

func _load_heart(file_name: String):
	for folder in HEART_PATHS:
		if ResourceLoader.exists(folder + file_name):
			return load(folder + file_name)
	push_warning("Kalp dosyası bulunamadı: " + file_name)
	return null

func _process(_delta):
	queue_redraw()

func _draw():
	if player == null:
		return
	var size = get_viewport_rect().size
	var center = size / 2.0
	var a = player.aim.angle()

	# Hasar alınca kırmızı parlama
	if player.hurt_flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0, 0, player.hurt_flash))

	# 90 derecelik saldırı/savunma alanı (soluk rehber yay)
	draw_arc(center, 46.0, a - CONE, a + CONE, 32, Color(1, 1, 1, 0.2), 2.0)

	# Savunma
	if player.block_timer > 0.0:
		draw_arc(center, 40.0, a - CONE, a + CONE, 32, Color(0.4, 0.8, 1.0, 0.9), 7.0)
	if player.block_flash > 0.0:
		var t = player.block_flash / 0.25
		draw_arc(center, 30.0 + (1.0 - t) * 40.0, 0.0, TAU, 48, Color(0.4, 0.8, 1.0, t), 4.0)

	# Düşman saldırı göstergesi (oyuncunun etrafındaki kırmızı yay)
	# Düşmanın üstündeki yay enemy.gd içinde çiziliyor
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.state == "windup":
			var off = e.global_position - player.global_position
			var p2 = e.windup_progress()
			var ang = off.angle()
			draw_arc(center, RING, ang - 0.18, ang + 0.18, 8, Color(1, 0.1, 0.1, 0.4 + 0.6 * p2), 5.0 + 4.0 * p2)

	# Can: tek kalp (3 tam, 2 çatlak, 1 kırık)
	var heart = null
	match player.lives:
		3:
			heart = heart_full
		2:
			heart = heart_cracked
		1:
			heart = heart_broken
	if heart != null:
		draw_texture_rect(heart, Rect2(20, 16, 26 * HEART_SCALE, 22 * HEART_SCALE), false)

	# Parry sayacı (3 dolunca ışık patlaması)
	for i in range(3):
		var filled = i < player.parry_count % 3
		draw_circle(Vector2(29 + i * 26, 74), 5.0, Color(1, 1, 1, 1.0 if filled else 0.25))

	# Stamina çubuğu
	var bar_w = 78.0
	draw_rect(Rect2(20, 86, bar_w, 6), Color(1, 1, 1, 0.15))
	var bar_color = Color(0.3, 0.9, 0.4)
	if player.exhausted:
		bar_color = Color(1, 0.3, 0.2)
	draw_rect(Rect2(20, 86, bar_w * player.stamina / player.MAX_STAMINA, 6), bar_color)

	if manager:
		var font = ThemeDB.fallback_font

		# Seviye göstergesi (sağ üst)
		var txt = "Seviye " + str(manager.level)
		if not manager.boss_spawned and manager.level < 6:
			var need = manager.LEVEL_REQS[manager.level + 1]
			txt += "  (" + str(manager.kills) + "/" + str(need) + ")"
		draw_string(font, Vector2(size.x - 260, 24), txt, HORIZONTAL_ALIGNMENT_RIGHT, 240, 20, Color(1, 1, 1, 0.85))

		# Boss can barı
		if manager.boss != null and is_instance_valid(manager.boss):
			var boss = manager.boss
			var bar_bw = 480.0
			var bar_bh = 22.0
			var bx = (size.x - bar_bw) / 2.0
			var by = 28.0
			draw_rect(Rect2(bx - 3, by - 3, bar_bw + 6, bar_bh + 6), Color(0, 0, 0, 0.85))
			draw_rect(Rect2(bx, by, bar_bw, bar_bh), Color(0.12, 0, 0, 1))
			var pct = float(boss.health) / float(boss.max_health)
			draw_rect(Rect2(bx, by, bar_bw * pct, bar_bh), Color(0.85, 0.05, 0.05))
			draw_string(font, Vector2(bx, by - 6), manager.BOSS_NAME, HORIZONTAL_ALIGNMENT_LEFT, bar_bw, 22, Color(1, 0.9, 0.85))

		# Zafer yazısı
		if manager.victory:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.75))
			draw_string(font, Vector2(0, center.y), "İNTİKAM ALINDI", HORIZONTAL_ALIGNMENT_CENTER, size.x, 64, Color(1, 0.85, 0.2))

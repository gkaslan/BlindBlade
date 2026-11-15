extends Node

const MAX_ENEMIES = 4
const SPAWN_EVERY = 3.0
const MIN_DIST = 250.0
const AREA = Vector2(300, 200)

const BASE_SPEED = 55.0
const BASE_WINDUP = 0.75
const SPEED_STEP = 5.0
const WINDUP_STEP = 0.05
const VISION_STEP = 16.0

# Her seviyeye geçmek için GEREKEN kesim sayısı (o seviyeye özel, sıfırdan sayılır)
const LEVEL_REQS = [0, 0, 2, 3, 4, 5, 6]  # index = ulaşılacak seviye

const BOSS_NAME = "Samuray Kuroda"
const BOSS_SPEED = 80.0
const BOSS_RANGE = 80.0
const BOSS_HEALTH = 8
const MUSIC_DIR = "res://BlindBlade_Music/"

var gameplay_music: AudioStreamPlayer
var boss_music: AudioStreamPlayer

var timer = 1.0
var level = 1
var kills = 0
var boss_spawned = false
var boss = null
var victory = false

func _ready():
	add_to_group("manager")
	var layer = CanvasLayer.new()
	layer.layer = 10
	var hud = Node2D.new()
	hud.set_script(load("res://hud.gd"))
	layer.add_child(hud)
	add_child(layer)
	gameplay_music = AudioStreamPlayer.new()
	gameplay_music.bus = "Music"
	add_child(gameplay_music)
	
	var gm = _load_music("gameplay_theme.ogg")
	if gm:
		gm.loop = true
		gameplay_music.stream = gm
		gameplay_music.play()

	boss_music = AudioStreamPlayer.new()
	boss_music.bus = "Music"
	add_child(boss_music)
	var bm = _load_music("boss_theme.ogg")
	if bm:
		bm.loop = true
		boss_music.stream = bm

func enemy_speed() -> float:
	return BASE_SPEED + SPEED_STEP * (level - 1)

func enemy_windup() -> float:
	return maxf(BASE_WINDUP - WINDUP_STEP * (level - 1), 0.15)

func on_enemy_killed(e):
	if e == boss:
		return
	kills += 1
	if level < 6 and kills >= LEVEL_REQS[level + 1]:
		kills = 0
		level_up()

func level_up():
	level += 1
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.increase_vision(VISION_STEP)
	if level >= 6 and not boss_spawned:
		spawn_boss()

func spawn_boss():
	boss_spawned = true
	for e in get_tree().get_nodes_in_group("enemy"):
		e.queue_free()

	var player = get_tree().get_first_node_in_group("player")
	var pos = Vector2(0, -150)
	if player:
		for i in range(10):
			var p = Vector2(randf_range(-AREA.x, AREA.x), randf_range(-AREA.y, AREA.y))
			if p.distance_to(player.global_position) >= MIN_DIST:
				pos = p
				break

	var b = Node2D.new()
	b.set_script(load("res://enemy.gd"))
	b.is_boss = true
	b.position = pos
	b.add_to_group("enemy")
	get_parent().add_child(b)
	boss = b
	_crossfade(gameplay_music, boss_music)
	

func on_boss_defeated():
	victory = true
	var fade = create_tween()
	fade.tween_property(boss_music, "volume_db", -40.0, 1.0)
	fade.tween_callback(boss_music.stop)

func _process(delta):
	if boss_spawned:
		return
	timer -= delta
	if timer > 0.0:
		return
	timer = SPAWN_EVERY
	if get_tree().get_nodes_in_group("enemy").size() >= MAX_ENEMIES:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.dead:
		return
	for i in range(10):
		var pos = Vector2(randf_range(-AREA.x, AREA.x), randf_range(-AREA.y, AREA.y))
		if pos.distance_to(player.global_position) >= MIN_DIST:
			var e = Node2D.new()
			e.set_script(load("res://enemy.gd"))
			e.position = pos
			e.add_to_group("enemy")
			get_parent().add_child(e)
			return
			
func _load_music(file_name: String):
	var path = MUSIC_DIR + file_name
	if ResourceLoader.exists(path):
		return load(path)
	push_warning("Müzik bulunamadı: " + path)
	return null

func _crossfade(from_player: AudioStreamPlayer, to_player: AudioStreamPlayer):
	if to_player.stream == null:
		return
	to_player.volume_db = -40.0
	to_player.play()
	var out_t = create_tween()
	out_t.tween_property(from_player, "volume_db", -40.0, 0.6)
	out_t.tween_callback(from_player.stop)
	var in_t = create_tween()
	in_t.tween_property(to_player, "volume_db", 0.0, 0.8)

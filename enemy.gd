extends Node2D
const CONE = PI / 4.0
const DEFAULT_RANGE = 55.0
const COOLDOWN = 1.3
const STUN = 1.5
const FRAME_SIZE = 32
const BOSS_WALK = "res://BlindBlade_Sprites/Boss/boss_walk.png"
const BOSS_ATTACK = "res://BlindBlade_Sprites/Boss/boss_attack.png"
const BOSS_SCALE = 1.2

var is_boss = false 
var SPEED = 55.0
var WINDUP = 0.65
var RANGE = DEFAULT_RANGE
var max_health = 1
var health = 1

var player
var manager
var state = "chase"
var timer = 0.0
var flash = 0.0
var facing = "down"

var sprite: AnimatedSprite2D
var fx: Node2D
func _ready():
	add_to_group("enemy")
	scale = Vector2(BOSS_SCALE, BOSS_SCALE) if is_boss else Vector2(2.0, 2.0)

	player = get_tree().get_first_node_in_group("player")
	manager = get_tree().get_first_node_in_group("manager") 

	# AnimatedSprite2D düğümünü otomatik kontrol et ve yoksa oluştur
	sprite = get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		sprite = AnimatedSprite2D.new()
		sprite.name = "AnimatedSprite2D"
		add_child(sprite)

	if is_boss:
		if manager:
			SPEED = manager.BOSS_SPEED
			RANGE = manager.BOSS_RANGE
			max_health = manager.BOSS_HEALTH
		else:
			SPEED = 75.0
			RANGE = 65.0
			max_health = 5
		health = max_health
	else:
		if manager:
			SPEED = manager.enemy_speed()
			WINDUP = manager.enemy_windup()
		RANGE = DEFAULT_RANGE
		max_health = 1
		health = 1

	_setup_sprite()
	fx = Node2D.new()
	fx.z_index = 20
	fx.draw.connect(_draw_warning)
	add_child(fx)
	
func _setup_sprite():
	if sprite == null:
		return
	if is_boss:
		_setup_boss_sprite()
		return
	var frames = SpriteFrames.new()

	# Doğru dosya yollarıyla yürüme ve saldırı animasyonları
	_load_anim_flexible(frames, "default", ["res://BlindBlade_Sprites/Walk/warrior_walk_down.png", "res://Walk/samurai_walk_down_128x128_4frames.png"], 8, true)
	_load_anim_flexible(frames, "walk_down", ["res://BlindBlade_Sprites/Walk/warrior_walk_down.png", "res://Walk/samurai_walk_down_128x128_4frames.png"], 8, true)
	_load_anim_flexible(frames, "walk_up", ["res://BlindBlade_Sprites/Walk/warrior_walk_up.png", "res://Walk/samurai_walk_up.png"], 8, true)
	_load_anim_flexible(frames, "walk_left", ["res://BlindBlade_Sprites/Walk/warrior_walk_left.png", "res://Walk/samurai_walk_left.png"], 8, true)
	_load_anim_flexible(frames, "walk_right", ["res://BlindBlade_Sprites/Walk/warrior_walk_right.png", "res://Walk/samurai_walk_right.png"], 8, true)

	_load_anim_flexible(frames, "attack_down", ["res://BlindBlade_Sprites/Attack/warrior_slash_down.png", "res://Attack/samurai_slash_down.png"], 12, false)
	_load_anim_flexible(frames, "attack_up", ["res://BlindBlade_Sprites/Attack/warrior_slash_up.png", "res://Attack/samurai_slash_up.png"], 12, false)
	_load_anim_flexible(frames, "attack_left", ["res://BlindBlade_Sprites/Attack/warrior_slash_left.png", "res://Attack/samurai_slash_left.png"], 12, false)
	_load_anim_flexible(frames, "attack_right", ["res://BlindBlade_Sprites/Attack/warrior_slash_right.png", "res://Attack/samurai_slash_right.png"], 12, false)

	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("default")

func _load_anim_flexible(frames: SpriteFrames, anim_name: String, paths: Array, fps: float, loop: bool):
	if not frames.has_animation(anim_name):
		frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	
	var tex = null
	for p in paths:
		if ResourceLoader.exists(p):
			tex = load(p)
			if tex != null:
				break
				
	if tex == null:
		var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		img.fill(Color.RED)
		tex = ImageTexture.create_from_image(img)
	
	var f_size = FRAME_SIZE
	if tex.get_width() > 64 and tex.get_width() % 4 == 0:
		f_size = int(tex.get_width() / 4)
		
	var count = max(1, int(tex.get_width() / f_size))
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * f_size, 0, f_size, tex.get_height())
		frames.add_frame(anim_name, atlas)

func _dir_name(vec: Vector2) -> String:
	if absf(vec.x) > absf(vec.y):
		return "right" if vec.x > 0.0 else "left"
	else:
		return "down" if vec.y > 0.0 else "up"

func windup_progress() -> float:
	return 1.0 - timer / WINDUP

func die():
	health -= 1
	if health <= 0:
		var was_boss = is_boss
		queue_free()
		if manager:
			manager.on_enemy_killed(self)
			if was_boss:
				manager.on_boss_defeated()
	else:
		flash = 0.2
		state = "chase"
		timer = 0.0

func _physics_process(delta):
	if player == null or player.dead:
		return
		
	flash = maxf(flash - delta, 0.0)
	var to_p = player.global_position - global_position
	
	if to_p.length() > 1.0:
		facing = _dir_name(to_p)

	if sprite:
		if state == "stunned":
			sprite.modulate = Color(1.0, 0.7, 0.1) # Stun olunca sarı/turuncu yanar
		elif flash > 0.0:
			sprite.modulate = Color(1.0, 0.2, 0.2) # Hasar alınca kırmızı yanar
		else:
			sprite.modulate = Color(1, 1, 1)

	match state:
		"chase":
			if to_p.length() > RANGE:
				global_position += to_p.normalized() * SPEED * delta
				if sprite:
					sprite.play("walk_" + facing)
			else:
				state = "windup"
				timer = WINDUP
				if sprite:
					sprite.play("attack_" + facing)
		"windup":
			timer -= delta
			if sprite and sprite.animation != "attack_" + facing:
				sprite.play("attack_" + facing)
			if timer <= 0.0:
				strike()
		"recover", "stunned":
			timer -= delta
			if sprite:
				sprite.play("walk_" + facing)
				sprite.pause()
			if timer <= 0.0:
				state = "chase"

func strike():
	var to_p = player.global_position - global_position
	if to_p.length() <= RANGE + 25.0:
		if player.take_hit(global_position) == "blocked":
			global_position -= to_p.normalized() * 20.0
			state = "stunned"
			timer = STUN
			return
	flash = 0.15
	state = "recover"
	timer = COOLDOWN
func _setup_boss_sprite():
	var frames = SpriteFrames.new()
	var walk_tex = load(BOSS_WALK)
	var atk_tex = load(BOSS_ATTACK)

	var walk_dirs = ["down", "up", "right", "left"]
	var atk_dirs = ["right", "left", "down", "up"]

	for r in range(4):
		var rects = []
		for c in range(4):
			rects.append(Rect2(c * 320, r * 320, 320, 320))
		_boss_anim(frames, "walk_" + walk_dirs[r], walk_tex, rects, 8, true)

	for r in range(4):
		var rects = []
		for c in range(4):
			rects.append(Rect2(c * 384, r * 320, 384, 320))
		_boss_anim(frames, "attack_" + atk_dirs[r], atk_tex, rects, 6, false)

	frames.add_frame("default", frames.get_frame_texture("walk_down", 0))

	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.play("walk_down")
	
func _boss_anim(frames: SpriteFrames, anim_name: String, tex: Texture2D, rects: Array, fps: float, loop: bool):
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for rc in rects:
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = rc
		frames.add_frame(anim_name, atlas)
func _process(_delta):
	if fx:
		fx.queue_redraw()

func _draw_warning():
	if player == null or player.dead:
		return
	# Düşman ölçeği küçük/büyük olsa da yay aynı boyutta görünsün
	var inv = 1.0 / scale.x
	var to_p = player.global_position - global_position
	var ang = to_p.angle()
	if state == "windup":
		var p = windup_progress()
		fx.draw_arc(Vector2.ZERO, (34.0 + 10.0 * p) * inv, ang - CONE, ang + CONE, 24,
			Color(1, 0.25, 0.25, 0.3 + 0.7 * p), (3.0 + 4.0 * p) * inv)
	elif flash > 0.0 and state != "stunned":
		fx.draw_arc(Vector2.ZERO, 46.0 * inv, ang - CONE, ang + CONE, 24,
			Color(1, 1, 1, 1), 8.0 * inv)

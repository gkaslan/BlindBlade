extends CharacterBody2D

const SPEED = 110.0
const RUN_SPEED = 155.0
const MAX_LIVES = 3
const CONE = PI / 3.6
const ATTACK_RANGE = 120.0
const ATTACK_TIME = 0.25
const ATTACK_COOLDOWN = 0.4
const BLOCK_TIME = 0.9
const BLOCK_COOLDOWN = 1.5
const PULSE_MULT = 12.0

const MAX_STAMINA = 100.0
const STAMINA_DRAIN = 35.0
const STAMINA_REGEN = 22.0
const STAMINA_DELAY = 0.8
const STAMINA_RESUME = 25.0

const AUDIO = "res://BlindBlade_auido/"
const CLASH_ON_EVERY_PARRY = true
const SLASH_START = 0.2
const DRAW_START = 0.15

const SPRITE_BASE = "res://BlindBlade_Sprites/"
const FRAME_SIZE = 32

@onready var light: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var slash_fx: AnimatedSprite2D

var lives = MAX_LIVES
var dead = false
var aim = Vector2.RIGHT
var attack_timer = 0.0
var attack_cd = 0.0
var block_timer = 0.0
var block_cd = 0.0
var block_flash = 0.0
var hurt_flash = 0.0
var can_pulse = true
var base_scale = 1.0
var parry_count = 0
var darkness
var dark_color = Color.BLACK

var vision_diameter = 128.0
var light_tex_width = 256.0

var stamina = MAX_STAMINA
var stamina_delay = 0.0
var exhausted = false
var sprinting = false

var facing = "down"
var anim_lock = ""

var s_slash
var s_armor
var s_draw
var s_clash
var s_sprint
var slash_sfx: AudioStreamPlayer
var armor_sfx: AudioStreamPlayer
var parry_sfx: AudioStreamPlayer
var sprint_sfx: AudioStreamPlayer
var burst_sfx: AudioStreamPlayer

func _ready():
	add_to_group("player")
	if light.texture:
		light_tex_width = light.texture.get_width()
	base_scale = vision_diameter / light_tex_width
	light.texture_scale = base_scale

	darkness = get_node_or_null("../CanvasModulate")
	if darkness:
		dark_color = darkness.color

	_setup_audio()
	_setup_sprite()
	_setup_slash_fx()

func _setup_slash_fx():
	slash_fx = AnimatedSprite2D.new()
	slash_fx.name = "SlashFX"
	slash_fx.z_index = 5
	slash_fx.visible = false
	slash_fx.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	var frames = SpriteFrames.new()
	frames.add_animation("slash")
	frames.set_animation_speed("slash", 10)
	frames.set_animation_loop("slash", false)

	var paths = [
		"res://BlindBlade_Animations/slash1.png",
		"res://BlindBlade_Animations/slash2.png",
		"res://BlindBlade_Animations/slash3.png",
		"res://BlindBlade_Animations/slash4.png"
	]

	for p in paths:
		if ResourceLoader.exists(p):
			var tex = load(p)
			if tex:
				frames.add_frame("slash", tex)

	slash_fx.sprite_frames = frames
	slash_fx.scale = Vector2(1.2, 1.2)
	slash_fx.animation_finished.connect(func(): slash_fx.visible = false)
	add_child(slash_fx)

func _setup_audio():
	s_slash = load(AUDIO + "sfx_slash.wav")
	s_armor = load(AUDIO + "sfx_armor_break.wav")
	s_draw = load(AUDIO + "sfx_sword_draw.wav")
	s_clash = load(AUDIO + "sfx_parry_clash.wav")
	s_sprint = load(AUDIO + "sfx_dash.wav")

	slash_sfx = _new_player(-4.0)
	armor_sfx = _new_player(0.0)
	parry_sfx = _new_player(-4.0)
	sprint_sfx = _new_player(-8.0)
	burst_sfx = _new_player(-3.0)
	burst_sfx.pitch_scale = 0.6

func _new_player(db: float) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.volume_db = db
	p.bus = "SFX"
	add_child(p)
	return p

func play_sfx(p: AudioStreamPlayer, stream, from: float = 0.0):
	if stream == null:
		return
	p.stream = stream
	p.play(from)

func _setup_sprite():
	var frames = SpriteFrames.new()

	_add_anim(frames, "walk_down", SPRITE_BASE + "Walk/samurai_walk_down_128x32.png", 8, true)
	_add_anim(frames, "walk_up", SPRITE_BASE + "Walk/samurai_walk_up_128x32.png", 8, true)
	_add_anim(frames, "walk_left", SPRITE_BASE + "Walk/samurai_walk_left_128x32.png", 8, true)
	_add_anim(frames, "walk_right", SPRITE_BASE + "Walk/samurai_walk_right_128x32.png", 8, true)

	_add_anim(frames, "attack_down", SPRITE_BASE + "Attack/samurai_slash_down_128x32.png", 16, false)
	_add_anim(frames, "attack_up", SPRITE_BASE + "Attack/samurai_slash_up_128x32.png", 16, false)
	_add_anim(frames, "attack_left", SPRITE_BASE + "Attack/samurai_slash_left_128x32.png", 16, false)
	_add_anim(frames, "attack_right", SPRITE_BASE + "Attack/samurai_slash_right_128x32.png", 16, false)

	sprite.sprite_frames = frames
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.animation_finished.connect(_on_anim_finished)
	sprite.play("walk_down")
	sprite.stop()
	sprite.frame = 0

func _add_anim(frames: SpriteFrames, anim_name: String, path: String, fps: float, loop: bool):
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	var tex = load(path)
	if tex == null:
		push_warning("Sprite bulunamadı: " + path)
		return
	var count = int(tex.get_width() / FRAME_SIZE)
	for i in range(count):
		var atlas = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * FRAME_SIZE, 0, FRAME_SIZE, tex.get_height())
		frames.add_frame(anim_name, atlas)

func _dir_name(vec: Vector2) -> String:
	if absf(vec.x) > absf(vec.y):
		return "right" if vec.x > 0.0 else "left"
	else:
		return "down" if vec.y > 0.0 else "up"

func _on_anim_finished():
	if anim_lock != "":
		sprite.pause()

func _update_animation(move_dir: Vector2):
	if attack_timer > 0.0:
		if anim_lock != "attack":
			anim_lock = "attack"
			facing = _dir_name(aim)
			sprite.play("attack_" + facing)
		return
	if block_timer > 0.0:
		if anim_lock != "block":
			anim_lock = "block"
			facing = _dir_name(aim)
			sprite.play("attack_" + facing)
		return
	if anim_lock != "":
		anim_lock = ""

	if move_dir != Vector2.ZERO:
		facing = _dir_name(move_dir)
		var anim = "walk_" + facing
		if sprite.animation != anim or not sprite.is_playing():
			sprite.play(anim)
	else:
		var idle_anim = "walk_" + facing
		if sprite.animation != idle_anim or sprite.is_playing():
			sprite.play(idle_anim)
			sprite.stop()
			sprite.frame = 0

func increase_vision(step: float):
	vision_diameter += step
	base_scale = vision_diameter / light_tex_width
	if can_pulse:
		light.texture_scale = base_scale

func _physics_process(delta):
	if dead:
		return

	var dir = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): dir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): dir.y += 1
	if Input.is_physical_key_pressed(KEY_A): dir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): dir.x += 1

	var wants_sprint = Input.is_physical_key_pressed(KEY_SHIFT) and dir != Vector2.ZERO
	var was_sprinting = sprinting
	sprinting = wants_sprint and not exhausted and stamina > 0.0
	if sprinting:
		stamina = maxf(stamina - STAMINA_DRAIN * delta, 0.0)
		stamina_delay = STAMINA_DELAY
		if stamina <= 0.0:
			exhausted = true
			sprinting = false
	else:
		stamina_delay = maxf(stamina_delay - delta, 0.0)
		if stamina_delay <= 0.0:
			stamina = minf(stamina + STAMINA_REGEN * delta, MAX_STAMINA)
		if exhausted and stamina >= STAMINA_RESUME:
			exhausted = false
	if sprinting and not was_sprinting:
		play_sfx(sprint_sfx, s_sprint)
	elif was_sprinting and not sprinting:
		sprint_sfx.stop()

	var speed = RUN_SPEED if sprinting else SPEED
	velocity = dir.normalized() * speed
	move_and_slide()

	var to_mouse = get_global_mouse_position() - global_position
	if to_mouse.length() > 1.0:
		aim = to_mouse.normalized()

	_update_animation(dir)

	attack_timer = maxf(attack_timer - delta, 0.0)
	attack_cd = maxf(attack_cd - delta, 0.0)
	block_timer = maxf(block_timer - delta, 0.0)
	block_cd = maxf(block_cd - delta, 0.0)
	block_flash = maxf(block_flash - delta, 0.0)
	hurt_flash = maxf(hurt_flash - delta, 0.0)

func _unhandled_input(event):
	if dead:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			attack()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			block()

func in_cone(pos: Vector2, max_dist: float) -> bool:
	var to = pos - global_position
	if to.length() > max_dist:
		return false
	return absf(aim.angle_to(to.normalized())) <= CONE

func attack():
	print("ATTACK cagrildi, gruptaki dusman: ", get_tree().get_nodes_in_group("enemy").size())
	if attack_cd > 0.0 or block_timer > 0.0:
		return
	attack_cd = ATTACK_COOLDOWN
	attack_timer = ATTACK_TIME
	play_sfx(slash_sfx, s_slash, SLASH_START)

	if slash_fx:
		slash_fx.position = (aim * 32.0) + (aim.orthogonal() * -4.0)
		slash_fx.rotation = aim.angle() + PI / 4.0
		slash_fx.visible = true
		slash_fx.frame = 0
		slash_fx.play("slash")
		
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.state == "stunned" and in_cone(e.global_position, ATTACK_RANGE):
			e.die()

func block():
	if block_cd > 0.0 or attack_timer > 0.0:
		return
	block_timer = BLOCK_TIME
	block_cd = BLOCK_COOLDOWN
	parry_sfx.volume_db = -6.0
	play_sfx(parry_sfx, s_draw, DRAW_START)

func take_hit(from_pos: Vector2) -> String:
	if dead:
		return "hit"
	if block_timer > 0.0 and in_cone(from_pos, 99999.0):
		block_flash = 0.25
		parry_count += 1
		if parry_count % 3 == 0:
			burst()
			parry_sfx.volume_db = 0.0
			play_sfx(parry_sfx, s_clash)
			play_sfx(burst_sfx, s_clash)
			duck_ambience()
		elif CLASH_ON_EVERY_PARRY:
			parry_sfx.volume_db = -8.0
			play_sfx(parry_sfx, s_clash)
		return "blocked"
	lives -= 1
	hurt_flash = 0.35
	play_sfx(armor_sfx, s_armor)
	if lives <= 0:
		dead = true
		velocity = Vector2.ZERO
		sprint_sfx.stop()
		game_over()
	return "hit"

func game_over():
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://game_over.tscn")

func burst():
	if darkness == null:
		return
	var t = create_tween()
	t.tween_property(darkness, "color", Color.WHITE, 0.1)
	t.tween_interval(0.2)
	t.tween_property(darkness, "color", dark_color, 0.2)

func duck_ambience():
	pass

extends Node

const SAVE_PATH = "user://audio_settings.cfg"

var music_volume = 0.8
var sfx_volume = 1.0

func _ready():
	_ensure_bus("Music")
	_ensure_bus("SFX")
	_load()
	_apply()

func _ensure_bus(bus_name: String):
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func set_music_volume(v: float):
	music_volume = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	_save()

func set_sfx_volume(v: float):
	sfx_volume = clampf(v, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_volume, 0.0001)))
	_save()

func _apply():
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_volume, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_volume, 0.0001)))

func _save():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SAVE_PATH)

func _load():
	var cfg = ConfigFile.new()
	if cfg.load(SAVE_PATH) == OK:
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)

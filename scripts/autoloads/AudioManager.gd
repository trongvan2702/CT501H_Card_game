extends Node

@export var bgm_main: AudioStream
@export var sfx_card_select: AudioStream
@export var sfx_card_deselect: AudioStream
@export var sfx_trigger: AudioStream
@export var sfx_dish_ready: AudioStream
@export var sfx_card_slide: AudioStream
@export var sfx_card_discard: AudioStream

var _bgm_player: AudioStreamPlayer
var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0

func _ready() -> void:
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = &"BGM"
	_bgm_player.volume_db = -10
	add_child(_bgm_player)
	
	# Tự động phát nhạc nền ngay khi mở game
	if bgm_main != null:
		play_bgm(bgm_main)
	
	# 2. Tạo 6 kênh cho hiệu ứng âm thanh (SFX)
	for i in range(6):
		var player = AudioStreamPlayer.new()
		player.bus = &"SFX"
		add_child(player)
		_players.append(player)

func play_bgm(stream: AudioStream, volume_db: float = -10.0) -> void:
	if stream == null:
		return
	# Nếu đúng bản nhạc này đang phát rồi thì không phát lại từ đầu
	if _bgm_player.stream == stream and _bgm_player.playing:
		return
		
	_bgm_player.stream = stream
	_bgm_player.volume_db = volume_db
	_bgm_player.play()

func stop_bgm() -> void:
	_bgm_player.stop()

func set_bgm_paused(paused: bool) -> void:
	_bgm_player.stream_paused = paused

func _play_stream(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var player = _players[_next_player_idx]
	_next_player_idx = (_next_player_idx + 1) % _players.size()
	
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()

func play_card_select() -> void:
	_play_stream(sfx_card_select, randf_range(0.98, 1.05))

func play_card_deselect() -> void:
	_play_stream(sfx_card_deselect, randf_range(0.92, 0.98))

func play_trigger(combo_step: int = 0) -> void:
	var pitch = minf(1.0 + combo_step * 0.06, 1.8)
	_play_stream(sfx_trigger, pitch)

func play_dish_ready() -> void:
	_play_stream(sfx_dish_ready, 1.0)
	
func play_card_slide() -> void:
	_play_stream(sfx_card_slide, randf_range(0.95, 1.12))

func play_card_discard() -> void:
	_play_stream(sfx_card_discard, randf_range(0.95, 1.12))

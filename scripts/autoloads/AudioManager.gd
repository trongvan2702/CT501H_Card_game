extends Node

@export var sfx_card_select: AudioStream
@export var sfx_card_deselect: AudioStream
@export var sfx_trigger: AudioStream
@export var sfx_dish_ready: AudioStream

var _players: Array[AudioStreamPlayer] = []
var _next_player_idx: int = 0

func _ready() -> void:
	for i in range(6):
		var player = AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_players.append(player)

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

# combo_step giúp cao độ (pitch) tăng dần sau mỗi lần trigger giống Balatro
func play_trigger(combo_step: int = 0) -> void:
	var pitch = minf(1.0 + combo_step * 0.06, 1.8)
	_play_stream(sfx_trigger, pitch)

func play_dish_ready() -> void:
	_play_stream(sfx_dish_ready, 1.0)

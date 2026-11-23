class_name MainMenu
extends Control

# Cho phép chọn trực tiếp file scene MatchManager ngoài Inspector nếu đường dẫn khác
@export_file("*.tscn") var match_scene_path: String = "res://scenes/MatchManager.tscn"

# Đường dẫn file save dự kiến sau này
const SAVE_FILE_PATH: String = "user://savegame.save"

@onready var play_btn: ActionButton = $CenterContainer/MainVBox/ButtonList/PlayButton
@onready var settings_btn: ActionButton = $CenterContainer/MainVBox/ButtonList/SettingsButton
@onready var exit_btn: ActionButton = $CenterContainer/MainVBox/ButtonList/ExitButton
@onready var continue_btn: ActionButton = $CenterContainer/MainVBox/ButtonList/ContinueButton

func _ready() -> void:
	# 1. Kiểm tra bản lưu: chỉ hiện Continue nếu đã có dữ liệu chơi trước đó
	continue_btn.visible = _has_save_data()
	
	# 2. Kết nối tín hiệu bấm nút
	play_btn.action_pressed.connect(_on_play_pressed)
	exit_btn.action_pressed.connect(_on_exit_pressed)
	
	# Hai nút còn lại để sẵn khung chờ phát triển sau
	settings_btn.action_pressed.connect(_on_settings_pressed)
	continue_btn.action_pressed.connect(_on_continue_pressed)

func _has_save_data() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(match_scene_path)

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	pass

func _on_continue_pressed() -> void:
	pass

class_name GameOverUI
extends Control

@export_file("*.tscn") var match_scene_path: String = "res://scenes/MatchManager.tscn"
@export_file("*.tscn") var main_menu_path: String = "res://scenes/MainMenu.tscn"

@onready var stage_boss_label: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/Header/Margin/VBoxContainer/StageBossLabel

@onready var best_serve_value: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/StatsBox/Margin/VBoxContainer/BestServeRow/Value
@onready var played_value: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/StatsBox/Margin/VBoxContainer/PlayedRow/Value
@onready var discarded_value: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/StatsBox/Margin/VBoxContainer/DiscardedRow/Value
@onready var bought_value: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/StatsBox/Margin/VBoxContainer/BoughtRow/Value
@onready var reroll_value: Label = $CenterContainer/MainPanel/Margin/VBoxContainer/StatsBox/Margin/VBoxContainer/RerollRow/Value

@onready var new_run_btn: ActionButton = $CenterContainer/MainPanel/Margin/VBoxContainer/ButtonRow/NewRunButton
@onready var main_menu_btn: ActionButton = $CenterContainer/MainPanel/Margin/VBoxContainer/ButtonRow/MainMenuButton

func _ready() -> void:
	visible = false
	
	if new_run_btn:
		new_run_btn.action_pressed.connect(_on_new_run_pressed)
	if main_menu_btn:
		main_menu_btn.action_pressed.connect(_on_main_menu_pressed)

func display_game_over() -> void:
	# 1. Lấy Stage thua và tên Boss
	var boss_name := "NABERIUS"
	if StageManager.current_boss != null:
		boss_name = StageManager.current_boss.item_data.display_name.to_upper()
	stage_boss_label.text = "SERVICE %d - %s" % [StageManager.current_stage, boss_name]
	
	# 2. Đổ toàn bộ chỉ số từ GameManager lên UI
	best_serve_value.text = str(round(GameManager.best_serve_score))
	played_value.text = str(GameManager.total_ingredients_played)
	discarded_value.text = str(GameManager.total_ingredients_discarded)
	bought_value.text = str(GameManager.total_purchases)
	reroll_value.text = str(GameManager.total_rerolls)
	
	visible = true

func _on_new_run_pressed() -> void:
	GameManager.start_new_run()
	get_tree().change_scene_to_file(match_scene_path)

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_path)

class_name GameHud
extends Control

enum ViewMode { MATCH, SHOP }
@export var current_mode: ViewMode = ViewMode.MATCH

@onready var score_block = $PanelGameHub/Margin/MainVBox/ScoreBlock
@onready var money_box = $PanelGameHub/Margin/MainVBox/MoneyBox
@onready var resource_block = $PanelGameHub/Margin/MainVBox/ResourceBlock

# Điểm số
@onready var current_score_label = $PanelGameHub/Margin/MainVBox/ScoreBlock/Margin/HBox/PanelContainer/CurrentScore

# Tài nguyên
@onready var money_label = $PanelGameHub/Margin/MainVBox/MoneyBox/Margin/Label
@onready var plays_label = $PanelGameHub/Margin/MainVBox/ResourceBlock/Margin/ActionsHBox/PlaysBox/MarginContainer/VBoxContainer/PanelContainer/PlaysCount
@onready var discards_label = $PanelGameHub/Margin/MainVBox/ResourceBlock/Margin/ActionsHBox/DiscardBox/MarginContainer/VBoxContainer/PanelContainer/PlaysCount

# Stage Info (Dựa trên cấu trúc hình ảnh mới của bạn)
@onready var boss_name_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/BossName
@onready var effect_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/TargetScoreBox/MarginContainer/VBoxContainer/EfecctLabel/BossEffect
@onready var target_score_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/TargetScoreBox/MarginContainer/VBoxContainer/HBoxContainer/Info/MarginContainer/VBox/TargetScore
@onready var reward_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/TargetScoreBox/MarginContainer/VBoxContainer/HBoxContainer/Info/MarginContainer/VBox/HBoxContainer/Reward2
@onready var stage_title_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/Stage/Margin/Stage/Label
@onready var stage_number_label = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/Stage/Margin/Stage/PanelContainer/PlaysCount
@onready var boss_image = $PanelGameHub/Margin/MainVBox/StageBlock/VBox/TargetScoreBox/MarginContainer/VBoxContainer/HBoxContainer/BossImage/TextureRect

# =======================================================
# KHỞI TẠO VÀ CẬP NHẬT GIAO DIỆN CHÍNH
# =======================================================
func _ready() -> void:
	_update_visibility_by_mode()

func _update_visibility_by_mode() -> void:
	if current_mode == ViewMode.SHOP:
		score_block.visible = false
		resource_block.visible = false
	else:
		score_block.visible = true
		resource_block.visible = true

# =======================================================
# CÁC HÀM CẬP NHẬT THÔNG SỐ (Gọi từ MatchManager / ShopUI)
# =======================================================

# Cập nhật số tiền (Dùng chung cho cả Shop và Match)
func update_money() -> void:
	money_label.text = "$%d" % GameManager.currency
	
	await get_tree().process_frame
	money_label.pivot_offset = money_label.size / 2.0
	
	var tween = create_tween()
	money_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(money_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
func update_current_score(score: float) -> void:
	current_score_label.text = str(score)
	await get_tree().process_frame
	
	current_score_label.pivot_offset = current_score_label.size / 2.0
	
	var tween = create_tween()
	current_score_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(current_score_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func update_resources(plays: int, discards: int) -> void:
	if plays_label.text != str(plays):
		update_play_label(plays)
	elif discards_label.text != str(discards):
		update_discard_label(discards)
	
	plays_label.text = str(plays)
	discards_label.text = str(discards)
	
func update_play_label(plays: int) -> void:
	plays_label.text = str(plays)
	await get_tree().process_frame
	
	var tween = create_tween()
	plays_label.pivot_offset = plays_label.size / 2.0
	plays_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(plays_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func update_discard_label(discards: int) -> void:
	discards_label.text = str(discards)
	await get_tree().process_frame
	
	var tween = create_tween()
	discards_label.pivot_offset = discards_label.size / 2.0
	discards_label.scale = Vector2(1.2, 1.2)
	tween.tween_property(discards_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)

func update_stage_info() -> void:
	if current_mode == ViewMode.SHOP:
		stage_title_label.text = "Next Stage:"
	else:
		stage_title_label.text = "Current Stage:"
		
	stage_number_label.text = str(StageManager.current_stage)
	
	target_score_label.text = str(StageManager.get_current_target_score())
	
	var reward_amount = StageManager.get_stage_reward()
	var reward_string = ""
	for i in range(reward_amount):
		reward_string += "$"
	reward_label.text = reward_string
	
	if StageManager.current_boss != null:
		var boss_data = StageManager.current_boss.item_data
		boss_name_label.text = boss_data.display_name
		effect_label.text = boss_data.description
		effect_label.visible = true
		boss_image.texture = boss_data.item_texture
	else:
		boss_name_label.text = "NABERIUS"
		effect_label.visible = false
		# boss_image.texture = preload("res://assets/default_icon.png")

func refresh_all(score: float = 0.0, plays: int = 0, discards: int = 0) -> void:
	update_money()
	update_stage_info()
	if current_mode == ViewMode.MATCH:
		update_current_score(score)
		update_resources(plays, discards)

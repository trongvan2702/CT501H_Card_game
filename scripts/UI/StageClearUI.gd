class_name StageClearUI
extends Control

signal continue_pressed


@onready var stage_info_label = $CenterContainer/MainPanel/Margin/VBoxContainer/Header/Margin/VBoxContainer/StageInfo
@onready var boss_name_label = $CenterContainer/MainPanel/Margin/VBoxContainer/Header/Margin/VBoxContainer/BossName

@onready var total_score_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Score/Margin/VBoxContainer/TotalScoreRow/Value
@onready var target_score_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Score/Margin/VBoxContainer/TargetScoreRow/Value
@onready var dishes_cooked_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Score/Margin/VBoxContainer/DishesRow/Value

@onready var money_vbox = $CenterContainer/MainPanel/Margin/VBoxContainer/Currency/Margin/MoneyVBox
@onready var service_clear_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Currency/Margin/MoneyVBox/TotalScoreRow/Value
@onready var interest_bonus_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Currency/Margin/MoneyVBox/InterestRow/Value
@onready var item_bonus_value = $CenterContainer/MainPanel/Margin/VBoxContainer/Currency/Margin/MoneyVBox/ItemRow/Value

@onready var total_money_value = $CenterContainer/MainPanel/Margin/VBoxContainer/TotalScoreRow/Value
@onready var continue_btn: ActionButton = $CenterContainer/MainPanel/Margin/VBoxContainer/ContinueButton

func _ready() -> void:
	visible = false
	if continue_btn:
		continue_btn.action_pressed.connect(_on_continue_pressed)

func _on_continue_pressed() -> void:
	emit_signal("continue_pressed")
	visible = false

func display_summary(
	current_stage: int,
	total_score: float, 
	target_score: float,
	dishes_cooked: int,
	base_reward_gold: int,
	interest_gold: int,
	item_effects: Dictionary
) -> void:
	
	visible = true
	
	stage_info_label.text = "SERVICE %d" % current_stage
	
	if StageManager.current_boss != null:
		boss_name_label.text = StageManager.current_boss.item_data.display_name.to_upper()
	else:
		boss_name_label.text = "NABERIUS"
		
	total_score_value.text = str(round(total_score))
	target_score_value.text = str(round(target_score))
	dishes_cooked_value.text = str(dishes_cooked)
	
	service_clear_value.text = _create_dollar_string(base_reward_gold)
	
	var interest_row = interest_bonus_value.get_parent()
	if interest_gold > 0:
		interest_row.visible = true
		interest_bonus_value.text = _create_dollar_string(interest_gold)
	else:
		interest_row.visible = false
		
	# Xử lý Item Bonus (Ẩn nếu không có)
	var total_item_gold = 0
	if item_effects.has("add_money"):
		total_item_gold = item_effects["add_money"]
		
	var item_bonus_row = item_bonus_value.get_parent()
	if total_item_gold > 0:
		item_bonus_row.visible = true
		item_bonus_value.text = _create_dollar_string(total_item_gold)
	else:
		item_bonus_row.visible = false
	
	var grand_total = base_reward_gold + interest_gold + total_item_gold
	total_money_value.text = "%d$" % grand_total

func _create_dollar_string(amount: int) -> String:
	var result = ""
	for i in range(amount):
		result += "$"
	return result

class_name ScoringStageUI
extends Control

const DISH_VISUAL_SCENE = preload("res://scenes/DishVisualUI.tscn")

@onready var stage_tray: Control = $StageTray
@onready var score_box: HBoxContainer = $ScoreBox
@onready var score_label: Label = $ScoreBox/ScorePanel/Label
@onready var mult_label: Label = $ScoreBox/MultPanel/Label


var _card_map: Dictionary = {} # { IngredientInstance: IngredientCard }
var _tray_nodes: Array[Control] = [] # Danh sách các node đang nằm trên khay duy nhất

var _display_score: float = 0.0
var _display_mult: float = 1.0

const ITEM_SPACING: float = 140.0

func _ready() -> void:
	score_box.visible = false

# ==========================================
# 1. ĐẨY BÀI TỪ TAY LÊN KHAY & LÀM TỐI BÀI THỪA
# ==========================================
func start_scoring_stage(played_cards: Array[IngredientCard], used_ingredients: Array) -> void:
	_clear_stage()
	
	# Hiện bảng Score x Mult
	_display_score = 0.0
	_display_mult = 1.0
	_update_score_labels()
	score_box.visible = true
	score_box.modulate.a = 0.0
	create_tween().tween_property(score_box, "modulate:a", 1.0, 0.2)
	
	# Chuyển các thẻ bài sang StageTray (giữ nguyên vị trí toàn cục để bay mượt)
	for card in played_cards:
		card.reparent(stage_tray, true)
		_card_map[card.ingredient_instance] = card
		_tray_nodes.append(card)
		
		# Làm tối những lá không tạo được recipe
		if card.ingredient_instance not in used_ingredients:
			card.modulate = Color(0.4, 0.4, 0.4, 1.0)
	
	# Bay lên xếp thành hàng ngang thẳng hàng
	await _arrange_tray_nodes(0.3)

# Xếp toàn bộ node hiện có trên khay thành 1 hàng ngang căn giữa
func _arrange_tray_nodes(duration: float = 0.25) -> void:
	var count = _tray_nodes.size()
	if count == 0:
		return
		
	var center_x = stage_tray.size.x / 2.0
	var center_y = stage_tray.size.y / 2.0
	var start_x = center_x - (ITEM_SPACING * (count - 1)) / 2.0
	
	var tween = create_tween().set_parallel(true)
	for i in range(count):
		var node = _tray_nodes[i]
		var target_pos = Vector2(
			start_x + (i * ITEM_SPACING) - (node.size.x / 2.0),
			center_y - (node.size.y / 2.0)
		)
		tween.tween_property(node, "position", target_pos, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "rotation", 0.0, duration).set_trans(Tween.TRANS_SINE)
		node.z_index = i
		
	await tween.finished

# ==========================================
# 2. HIỆU ỨNG RUNG & CẬP NHẬT ĐIỂM
# ==========================================
func play_ingredient_trigger(ingredient: IngredientInstance, trigger: TriggerResult) -> void:
	_apply_trigger_numbers(trigger)
	if _card_map.has(ingredient):
		var card: IngredientCard = _card_map[ingredient]
		await _shake_node(card)

func play_recipe_trigger(dish_ui: DishVisualUI, trigger: TriggerResult) -> void:
	_apply_trigger_numbers(trigger)
	if dish_ui != null:
		await dish_ui.play_trigger_shake()

func apply_item_trigger_numbers(trigger: TriggerResult) -> void:
	_apply_trigger_numbers(trigger)

func _apply_trigger_numbers(trigger: TriggerResult) -> void:
	_display_score += trigger.score
	if trigger.x_mult:
		_display_mult *= trigger.mult
	else:
		_display_mult += trigger.mult
	_update_score_labels()

func _update_score_labels() -> void:
	score_label.text = str(roundi(_display_score))
	mult_label.text = str(snappedf(_display_mult, 0.1))

# ==========================================
# 3. BIẾN NGUYÊN LIỆU THÀNH MÓN ĂN TRÊN CÙNG 1 KHAY
# ==========================================
func transform_ingredients_to_dish(ingredients: Array[IngredientInstance], recipe: RecipeData) -> DishVisualUI:
	var cards_to_remove: Array[IngredientCard] = []
	var insert_index: int = _tray_nodes.size()
	
	for ing in ingredients:
		if _card_map.has(ing):
			var card = _card_map[ing]
			cards_to_remove.append(card)
			var idx = _tray_nodes.find(card)
			if idx != -1 and idx < insert_index:
				insert_index = idx
	
	if not cards_to_remove.is_empty():
		var tween = create_tween().set_parallel(true)
		for card in cards_to_remove:
			card.pivot_offset = card.size / 2.0
			tween.tween_property(card, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			tween.tween_property(card, "modulate:a", 0.0, 0.2)
		await tween.finished
		
		for card in cards_to_remove:
			_tray_nodes.erase(card)
			card.queue_free()
	
	var dish_ui = DISH_VISUAL_SCENE.instantiate() as DishVisualUI
	stage_tray.add_child(dish_ui)
	dish_ui.setup(recipe)
	
	insert_index = clampi(insert_index, 0, _tray_nodes.size())
	_tray_nodes.insert(insert_index, dish_ui)
	
	await _arrange_tray_nodes(0.15)
	await dish_ui.play_appear_animation()
	
	return dish_ui

# ==========================================
# 4. KẾT THÚC & DỌN KHAY
# ==========================================
func finish_scoring_stage() -> void:
	var tween = create_tween().set_parallel(true)
	for node in _tray_nodes:
		node.pivot_offset = node.size / 2.0
		tween.tween_property(node, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(node, "modulate:a", 0.0, 0.2)
	tween.tween_property(score_box, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	_clear_stage()
	score_box.visible = false

func _clear_stage() -> void:
	for child in stage_tray.get_children():
		child.queue_free()
	_card_map.clear()
	_tray_nodes.clear()

func _shake_node(node: Control) -> void:
	node.pivot_offset = node.size / 2.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", Vector2(1.15, 1.15), 0.08)
	tween.tween_property(node, "rotation_degrees", 6.0, 0.06)
	tween.chain().tween_property(node, "rotation_degrees", -6.0, 0.08)
	tween.chain().set_parallel(true)
	tween.tween_property(node, "scale", Vector2.ONE, 0.1)
	tween.tween_property(node, "rotation_degrees", 0.0, 0.08)
	await tween.finished

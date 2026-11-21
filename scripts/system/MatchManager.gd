extends Control
class_name MatchManager

enum MatchState {
	INIT,               # Đang thiết lập
	DRAWING,            # Đang bốc bài (UI bị khóa)
	WAIT_FOR_INPUT,     # Chờ người chơi thao tác (UI mở khóa)
	PROCESSING,         # Đang tính điểm/hiệu ứng (UI bị khóa)
	GAME_OVER           # Kết thúc màn (Thắng/Thua)
}

var current_state: MatchState = MatchState.INIT
var current_stage: int = 0
var current_score: float = 0.0
var total_dishes_in_stage : int = 0 
var stage_target_score: float = 0.0
var plays_left: int = 4
var discards_left: int = 3

@export var deck_manager: DeckManager
@export var hand_manager: HandManager
@export var scoring_system: ScoringSystem

var max_hand_size: int = 7
var max_interest_gold: int = 5
var equipped_items: Array = []
const MAX_EQUIPPED_ITEMS: int = 5

@onready var owned_items_tray = $Item
@onready var play_action_btn = $VBoxContainer/HBoxContainer/PlayActionButton
@onready var discard_action_btn = $VBoxContainer/HBoxContainer/DiscardActionButton

@onready var view_deck_btn = $ViewDeckButton
@onready var deck_viewer_ui = $DeckViewerUI
@onready var active_menu_ui = $ActiveMenuUI
@onready var game_hud = $GameHud
@onready var item_tray = $ItemTrayWrapper
@onready var stage_clear_ui = $StageClearUI
@onready var scoring_stage_ui: ScoringStageUI = $ScoringStageUI

func _ready() -> void:
	start_new_stage()
	_update_deck_ui()
	view_deck_btn.deck_opened.connect(_on_view_deck_opened)
	hand_manager.cards_selection_changed.connect(_on_hand_selection_changed)
	hand_manager.cards_selection_changed.connect(active_menu_ui._on_cards_selection_changed)
	_update_action_buttons(0)
	active_menu_ui.refresh_menu()
	item_tray.item_sold.connect(func(): game_hud.update_money())
	item_tray.refresh_tray()

func _on_state_changed(new_state: MatchState) -> void:
	current_state = new_state
	match new_state:
		MatchState.INIT:
			print("MatchState: INIT")
		MatchState.DRAWING:
			print("MatchState: DRAWING")
		MatchState.WAIT_FOR_INPUT:
			print("MatchState: WAIT_FOR_INPUT")
		MatchState.PROCESSING:
			print("MatchState: PROCESSING")
		MatchState.GAME_OVER:
			print("MatchState: GAME_OVER")

# Đồng bộ dữ liệu item từ GameManager khi cần thiết
func _sync_equipped_items() -> void:
	scoring_system.equipped_items = GameManager.active_items.duplicate()
	
	if StageManager.current_boss != null:
		scoring_system.equipped_items.append(StageManager.current_boss)

func start_new_stage() -> void:
	
	deck_manager.full_deck = GameManager.player_deck.duplicate()
	deck_manager.start_new_stage()
	current_state = MatchState.INIT
	
	stage_target_score = StageManager.get_current_target_score()
	
	current_stage = StageManager.current_stage

	
	current_score = 0.0
	total_dishes_in_stage = 0
	plays_left = 4
	discards_left = 3
	
	_sync_equipped_items()
	
	_trigger_items_on_stage_start()
	
	game_hud.refresh_all(current_score, plays_left, discards_left)
	
	_on_state_changed(MatchState.DRAWING)
	
	var hand = deck_manager.draw_cards(max_hand_size)

	hand_manager.add_cards_to_hand(hand)
	
	await get_tree().create_timer(1.0).timeout
	_on_state_changed(MatchState.WAIT_FOR_INPUT)

func draw_cards_to_full() -> void:
	var hand = deck_manager.draw_cards(min(5, max_hand_size - hand_manager.get_cards_in_hand()))
	hand_manager.add_cards_to_hand(hand)
	await get_tree().create_timer(1.0).timeout
	_on_state_changed(MatchState.WAIT_FOR_INPUT)

@onready var effect_handlers: Dictionary = {
	"add_money": _effect_add_money,
	"max_interest_gold": _effect_modify_interest_gold,
	"add_plays": _effect_add_plays,
	"add_discards": _effect_add_discards,
	#"play_upgrade_vfx": _effect_play_upgrade_vfx
}

func _effect_add_plays(amount: int) -> void:
	print("Hiệu ứng: Tăng ", amount, " lượt Play")
	plays_left += amount

func _effect_add_discards(amount: int) -> void:
	print("Hiệu ứng: Tăng ", amount, " lượt Discard")
	discards_left += amount

func _effect_add_money(amount: int) -> void:
	print("Hiệu ứng: Nhận thêm ", amount, "$")
	GameManager.add_gold(amount) 

func _effect_modify_interest_gold(amount: int) -> void:
	print("Hiệu ứng: Tăng lợi tức ", amount)
	max_interest_gold = amount

func apply_meta_effects(effects: Dictionary) -> void:
	if effects.is_empty(): return
	
	for effect_name in effects:
		if effect_handlers.has(effect_name):
			var value = effects[effect_name]
			effect_handlers[effect_name].call(value)
		else:
			push_warning("MatchManager: Bỏ qua custom_effect không xác định - ", effect_name)

func _trigger_items_on_stage_start() -> void:
	for item in scoring_system.equipped_items:
		if item.has_method("on_stage_start"):
			var trigger = item.on_stage_start()
			if trigger != null and trigger.triggered:
				apply_meta_effects(trigger.custom_effects)

func _trigger_items_after_match() -> Dictionary:
	var final_effects: Dictionary = {}
	for item in scoring_system.equipped_items:
		if item.has_method("after_match"):
			var trigger = item.after_match()
			if trigger != null and trigger.triggered:
				# Gộp mọi hiệu ứng lại
				for key in trigger.custom_effects:
					if not final_effects.has(key): final_effects[key] = 0
					final_effects[key] += trigger.custom_effects[key]
	return final_effects

func _on_play_action_button_action_pressed() -> void:
	if current_state != MatchState.WAIT_FOR_INPUT or plays_left <= 0 or hand_manager.get_selected_cards().size() == 0:
		return
	
	_on_state_changed(MatchState.PROCESSING)
	
	plays_left -= 1
	_update_display()
	
	# 1. Lấy các node IngredientCard từ tay bài (không xóa ngay để làm hiệu ứng bay)
	var played_card_nodes = hand_manager.extract_selected_card_nodes()
	var selected_ingredients: Array[IngredientInstance] = []
	for card in played_card_nodes:
		selected_ingredients.append(card.ingredient_instance)
	
	_sync_equipped_items()
	
	#2. Tính toán trước toàn bộ kịch bản điểm
	var result = scoring_system.calculate_dish_score(selected_ingredients)
	
	# Dùng hàng đợi (Array) thay cho Dictionary để không bị ghi đè khi trùng RecipeData
	var all_used_ingredients: Array[IngredientInstance] = []
	var dishes_queue: Array = result["dishes"].duplicate()
	for dish in result["dishes"]:
		RecipeDB.record_craft(dish["recipe"].recipe_id)
		for ing in dish["ingredients"]:
			all_used_ingredients.append(ing)
	
	# 3. Bay các lá bài lên xếp hàng ngang ở giữa màn hình & hiện Score x Mult
	await scoring_stage_ui.start_scoring_stage(played_card_nodes, all_used_ingredients)
	
	# 4. Diễn hoạt từng bước theo đúng thứ tự của pipeline duy nhất
	for trigger in result["pipeline"]:
		if not trigger.triggered:
			continue
			
		match trigger.source_type:
			TriggerResult.SourceType.INGREDIENT:
				await scoring_stage_ui.play_ingredient_trigger(trigger.source_ref, trigger)
				
			TriggerResult.SourceType.RECIPE:
				var current_dish_ui: DishVisualUI = null
				if not dishes_queue.is_empty():
					var dish = dishes_queue.pop_front()
					current_dish_ui = await scoring_stage_ui.transform_ingredients_to_dish(dish["ingredients"], dish["recipe"])
				await scoring_stage_ui.play_recipe_trigger(current_dish_ui, trigger)
				
			TriggerResult.SourceType.ITEM:
				scoring_stage_ui.apply_item_trigger_numbers(trigger)
				await item_tray.play_item_trigger_shake(trigger.source_ref)
		
		# Thực thi custom_effects (nếu có) ngay tại nhịp trigger đó
		if not trigger.custom_effects.is_empty():
			apply_meta_effects(trigger.custom_effects)
			_update_display()
			game_hud.update_money()
			await get_tree().create_timer(0.15).timeout
	
	await get_tree().create_timer(0.4).timeout
	
	total_dishes_in_stage += result["dishes"].size()
	current_score += result["total_score"]
	game_hud.update_current_score(current_score)
	_update_deck_ui()
	
	await scoring_stage_ui.finish_scoring_stage()
	_check_win_condition()


func _on_discard_action_button_action_pressed() -> void:
	if current_state != MatchState.WAIT_FOR_INPUT or discards_left <= 0 or hand_manager.get_selected_cards().size() == 0:
		return
	
	
	var selected_cards = hand_manager.extract_and_remove_selected()
	
	_on_state_changed(MatchState.PROCESSING)
	discards_left -= 1
	_update_display()
	
	_on_state_changed(MatchState.DRAWING)
	draw_cards_to_full()
	_update_deck_ui()


func _check_win_condition() -> void:
	if current_score >= stage_target_score:
		_win_stage()
	elif plays_left <= 0:
		_lose_stage()
	else:
		# Vẫn còn lượt đánh, vòng lại rút bài cho đầy
		_on_state_changed(MatchState.DRAWING)
		draw_cards_to_full()

func _win_stage() -> void:
	_on_state_changed(MatchState.GAME_OVER)
	_sync_equipped_items()
	
	var end_stage_effects = _trigger_items_after_match()
	
	var item_gold: int = 0
	if end_stage_effects.has("add_money"):
		item_gold = end_stage_effects["add_money"]
		
	var base_gold: int = StageManager.get_stage_reward() 
	var interest_gold: int = floor(GameManager.currency / 5.0)
	interest_gold = min(interest_gold, max_interest_gold)
	
	var total_earned = base_gold + interest_gold + item_gold
	
	var dishes_cooked = total_dishes_in_stage
	
	# HƯỚNG DẪN UI HIỂN THỊ
	stage_clear_ui.display_summary(
		current_stage,
		current_score,
		stage_target_score,
		dishes_cooked,
		base_gold,
		interest_gold,
		end_stage_effects
	)
	
	# CHỜ NGƯỜI CHƠI BẤM NÚT CONTINUE
	await stage_clear_ui.continue_pressed
	
	GameManager.add_gold(total_earned)
	StageManager.advance_to_next_stage()
	get_tree().change_scene_to_file("res://scenes/ShopScence.tscn")

func _lose_stage() -> void:
	_on_state_changed(MatchState.GAME_OVER)
	print("RUN OVER - DEFEAT!")
	# Hiện màn hình Game Over

# =======================================================
# UI
# =======================================================

func _update_display() -> void:
	# Gọi hàm cập nhật nút mới, lấy số lượng bài đang chọn từ hand_manager
	var current_selected = hand_manager.get_selected_cards().size()
	_update_action_buttons(current_selected)
	game_hud.update_resources(plays_left, discards_left)

func _update_deck_ui() -> void:
	var total_cards = GameManager.player_deck.size()
	var remain_cards = deck_manager.draw_deck.size()
	
	view_deck_btn.update_counts(total_cards, remain_cards)

func _on_view_deck_opened() -> void:
	deck_viewer_ui.open_viewer(DeckViewerUI.ViewMode.MATCH, deck_manager.draw_deck)

func _on_hand_selection_changed(selected_cards: Array) -> void:
	_update_action_buttons(selected_cards.size())

func _update_action_buttons(selected_count: int) -> void:
	play_action_btn.update_state(selected_count, plays_left)
	discard_action_btn.update_state(selected_count, discards_left)

func _on_item_sell_requested(card: ItemCard) -> void:
	var price = card._calculate_sell_price()
	
	card.pivot_offset = card.size / 2.0
	
	GameManager.add_gold(price)
	
	var idx = GameManager.active_items.find(card.display_instance)
	if idx != -1:
		GameManager.active_items.remove_at(idx)
		
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	
	tween.chain().tween_callback(func():
		card.queue_free()
		#_render_owned_items()
		game_hud.update_money() 
	)
	
# =======================================================
# Debug
# =======================================================

func _on__debug_get_current_item_pressed() -> void:
	var count = 0
	for item in scoring_system.equipped_items:
		count += 1
		print("Item %d: %s" % [count, item.item_data.display_name]) 

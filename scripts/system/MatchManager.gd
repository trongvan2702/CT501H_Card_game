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

func _ready() -> void:
	start_new_stage()
	_render_owned_items()

func _render_owned_items() -> void:
	# 1. Dọn sạch khay cũ
	for child in owned_items_tray.get_children():
		child.queue_free()
		
	# 2. Lấy đồ từ GameManager đúc thành thẻ và nhét vào khay
	for item_instance in GameManager.active_items:
		var card = ItemCard.create_from_instance(item_instance)
		owned_items_tray.add_child(card)
		
	# 3. Vẽ thêm Boss (nếu có) để người chơi biết đang đánh với ai
	#if StageManager.current_boss != null:
		#var boss_card = ItemCard.create_from_instance(StageManager.current_boss)
		#owned_items_tray.add_child(boss_card)

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
	$"Taget Score".text = "Target score: %s" % [stage_target_score]
	
	current_stage = StageManager.current_stage
	$Current_Stage.text = "Current stage: %s" % [current_stage]
	
	current_score = 0.0
	plays_left = 4
	$PlayButton.text = "Play (%d)" % [plays_left]
	discards_left = 3
	$DiscardButton.text = "Discard (%d)" % [discards_left]
	
	_sync_equipped_items()
	
	_trigger_items_on_stage_start()
	
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

# ???????????????????????????
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

func _on_play_button_pressed() -> void:
	if current_state != MatchState.WAIT_FOR_INPUT or plays_left <= 0 or hand_manager.get_selected_cards().size() == 0:
		return
	
	_on_state_changed(MatchState.PROCESSING)
	
	plays_left -= 1
	$PlayButton.text = "Play (%d)" % [plays_left]
	
	var selected_cards = hand_manager.extract_and_remove_selected()
	
	_sync_equipped_items()
	
	var result = scoring_system.calculate_dish_score(selected_cards)
	
	for dish in result["dishes"]:
		var pipeline: Array[TriggerResult] = dish["pipeline"]
		
		for trigger in pipeline:
			if not trigger.triggered:
				continue
				
			if not trigger.custom_effects.is_empty():
				apply_meta_effects(trigger.custom_effects)
				
				await get_tree().create_timer(0.1).timeout
		
	print("Đã nấu xong! Điểm thu được: ", result["total_score"])
	current_score += result["total_score"]
	$Total_Score.text = str(current_score)
	#apply_meta_effects(result["meta_effects"])
	
	_check_win_condition()

func _on_discard_button_pressed() -> void:
	if current_state != MatchState.WAIT_FOR_INPUT or discards_left <= 0 or hand_manager.get_selected_cards().size() == 0:
		return
	
	
	var selected_cards = hand_manager.extract_and_remove_selected()
	
	_on_state_changed(MatchState.PROCESSING)
	discards_left -= 1
	$DiscardButton.text = "Discard (%d)" % [discards_left]
	
	_on_state_changed(MatchState.DRAWING)
	draw_cards_to_full()

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
		end_stage_effects.erase("add_money") 
	
	apply_meta_effects(end_stage_effects)
	
	var base_gold: int = 5
	var interest_gold: int = floor(GameManager.currency / 5.0)
	interest_gold = min(interest_gold, max_interest_gold)
	var total_earned = base_gold + interest_gold + item_gold
	
	print(total_earned)
	GameManager.add_gold(total_earned)
	get_tree().change_scene_to_file("res://scenes/ShopScence.tscn")

func _lose_stage() -> void:
	_on_state_changed(MatchState.GAME_OVER)
	print("RUN OVER - DEFEAT!")
	# Hiện màn hình Game Over

# =======================================================
# Debug
# =======================================================

func _on__debug_get_current_item_pressed() -> void:
	var count = 0
	for item in scoring_system.equipped_items:
		count += 1
		print("Item %d: %s" % [count, item.item_data.display_name]) 

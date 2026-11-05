extends Node
class_name ShopManager

enum ShopState {
	BROWSING,
	DRAFTING_RECIPE,
	DRAFTING_INGREDIENT,
	REMOVING_CARD
}

var current_state: ShopState = ShopState.BROWSING
var can_buy_recipe_pack: bool = true
var can_buy_ingredient_pack: bool = true
var can_buy_card_removal: bool = true

var current_shop_items: Array = []
var current_draft_choices: Array = []

var recipe_pack_cost: int = 5
var ingredient_pack_cost: int = 5
var card_removal_cost: int = 5

const base_reroll_cost: int = 5
const reroll_cost_increment: int = 1
var reroll_cost: int = base_reroll_cost

func _ready() -> void:
	generate_shop_inventory()
	#buy_recipe_pack()
	#buy_ingredient_pack()

func generate_shop_inventory() -> void:
	current_state = ShopState.BROWSING
	
	var exclude_ids: Array = []
	for item in GameManager.active_items:
		exclude_ids.append(item.item_data.item_id)
	
	current_shop_items = ItemDB.get_random_items(3, exclude_ids)
	
	for item in current_shop_items:
		print("Item: ", item.display_name)

func reroll_items() -> void:
	if current_state != ShopState.BROWSING: return
	if GameManager.currency >= reroll_cost:
		GameManager.currency -= reroll_cost
		reroll_cost += reroll_cost_increment
		
		current_shop_items.clear()
		
		generate_shop_inventory()
	else:
		print("Không đủ tiền reroll!")

func buy_item(item_index: int, cost: int) -> void:
	if current_state != ShopState.BROWSING: return
	if item_index < 0 or item_index >= current_shop_items.size(): return
	
	if GameManager.currency >= cost:
		GameManager.currency -= cost
		
		# Lấy data và đúc thành ItemInstance để nhét vào két sắt
		var item_data = current_shop_items[item_index]
		var new_item = ItemDB.create_item_instance(item_data.item_id)
		GameManager.active_items.append(new_item)
		
		# Xóa item khỏi kệ hàng
		current_shop_items.remove_at(item_index)
		print("Đã mua thành công Item: ", item_data.display_name)
		# UI sẽ tự update lại kệ hàng
	else:
		print("Không đủ tiền mua Item!")

func buy_recipe_pack() -> void:
	if current_state != ShopState.BROWSING or not can_buy_recipe_pack: return
	
	if GameManager.currency >= recipe_pack_cost:
		GameManager.currency -= recipe_pack_cost
		can_buy_recipe_pack = false
		
		# Rút 3 công thức ngẫu nhiên
		current_draft_choices = RecipeDB.get_random_recipes(3)
		current_state = ShopState.DRAFTING_RECIPE
		
		print("Đang mở Gói Công Thức... Vui lòng chọn 1.")
		# UI sẽ hiện bảng chọn 3 lá bài công thức
		for recipe in current_draft_choices:
			print(RecipeDB.get_info(recipe))
	else:
		print("Không đủ tiền mua Gói Công Thức!")

func select_recipe_choice(choice_index: int) -> void:
	if current_state != ShopState.DRAFTING_RECIPE: return
	
	var chosen_recipe: RecipeData = current_draft_choices[choice_index]
	
	if RecipeDB.recipes[chosen_recipe.recipe_id].unlocked:
		RecipeDB.upgrade_recipe(chosen_recipe)
		print("Đã nâng cấp món: ", chosen_recipe.recipe_name)
	else:
		RecipeDB.unlock_recipe(chosen_recipe)
		print("Đã mở khóa món mới: ", chosen_recipe.recipe_name)
		
	_close_draft_panel()

func buy_ingredient_pack() -> void:
	if current_state != ShopState.BROWSING or not can_buy_ingredient_pack: return
	
	if GameManager.currency >= ingredient_pack_cost:
		GameManager.currency -= ingredient_pack_cost
		can_buy_ingredient_pack = false
		
		current_draft_choices = IngredientDB.get_random_ingredients(3)
		print(current_draft_choices)
		current_state = ShopState.DRAFTING_INGREDIENT
		print("Đang mở Gói Nguyên Liệu... Vui lòng chọn 1.")
		for ingredient in current_draft_choices:
			print(ingredient.get_info())
	else:
		print("Không đủ tiền!")

func select_ingredient_choice(choice_index: int) -> void:
	if current_state != ShopState.DRAFTING_INGREDIENT: return
	
	var chosen_ingredient: IngredientInstance = current_draft_choices[choice_index]
	
	# Thêm vào bộ bài gốc của người chơi
	GameManager.player_deck.append(chosen_ingredient)
	print("Đã thêm lá bài vào Deck: ", chosen_ingredient.ingredient_data.display_name)
	
	_close_draft_panel()

func buy_card_removal() -> void:
	if current_state != ShopState.BROWSING or not can_buy_card_removal: return
	
	# Điều kiện: Bộ bài phải còn đủ bài để cắt
	if GameManager.player_deck.size() <= 3:
		print("Bộ bài quá mỏng, không thể cắt thêm!")
		return
		
	if GameManager.currency >= card_removal_cost:
		GameManager.currency -= card_removal_cost
		can_buy_card_removal = false
		
		# Tạo bản sao bộ bài để xáo trộn bốc ngẫu nhiên
		var temp_deck = GameManager.player_deck.duplicate()
		temp_deck.shuffle()
		
		# Lấy 3 lá ngẫu nhiên từ Deck người chơi để đưa lên thớt
		current_draft_choices.clear()
		
		for i in range(min(3, temp_deck.size())):
			current_draft_choices.append(temp_deck[i])
			
		current_state = ShopState.REMOVING_CARD
		print("Chọn 1 lá bài để vứt vĩnh viễn khỏi Deck.")
		for ingredient in current_draft_choices:
			print(ingredient.get_info())
	else:
		print("Không đủ tiền!")

func select_removal_choice(choice_index: int) -> void:
	if current_state != ShopState.REMOVING_CARD: return
	
	var card_to_remove: IngredientInstance = current_draft_choices[choice_index]
	
	# Tìm và xóa lá bài đó khỏi bộ bài gốc
	# Lưu ý: Chỉ xóa 1 lá (phòng trường hợp bộ bài có 5 lá thịt bò giống hệt nhau)
	var remove_idx = GameManager.player_deck.find(card_to_remove)
	if remove_idx != -1:
		GameManager.player_deck.remove_at(remove_idx)
		print("Đã vứt bỏ: ", card_to_remove.ingredient_data.display_name)
		
	_close_draft_panel()

func skip_draft_choice() -> void:
	# Người chơi mất tiền nhưng không chọn gì cả
	print("Người chơi đã bỏ qua lựa chọn.")
	_close_draft_panel()

func _close_draft_panel() -> void:
	current_draft_choices.clear()
	current_state = ShopState.BROWSING
	# Gọi UI để tắt cái bảng chọn đi



func _on_change_button_pressed() -> void:
	StageManager.advance_to_next_stage()
	get_tree().change_scene_to_file("res://scences/MatchManager.tscn")

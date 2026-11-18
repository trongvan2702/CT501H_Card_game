extends Node

# ====================
# Signal
# ====================
signal shop_updated
signal draft_opened 
signal sig_buy_recipe_pack
signal sig_buy_ingredient_pack
signal sig_remove_card

enum ShopState { BROWSING, DRAFTING_RECIPE, DRAFTING_INGREDIENT, REMOVING_CARD }

var current_state: ShopState = ShopState.BROWSING
var current_shop_items: Array = []
var current_draft_choices: Array = []

var recipe_pack_cost: int = 5
var ingredient_pack_cost: int = 5
var card_removal_cost: int = 5

var stock_recipe_pack: int = 1
var stock_ingredient_pack: int = 1
var has_used_remove_service: bool = false

const base_reroll_cost: int = 5
const reroll_cost_increment: int = 1
var reroll_cost: int = base_reroll_cost

func reset_shop() -> void:
	current_state = ShopState.BROWSING
	stock_recipe_pack = 1
	stock_ingredient_pack = 1
	has_used_remove_service = false
	reroll_cost = base_reroll_cost
	current_shop_items.clear()
	generate_shop_inventory()

func generate_shop_inventory() -> void:
	current_state = ShopState.BROWSING
	var exclude_ids: Array = []
	for item in GameManager.active_items:
		exclude_ids.append(item.item_data.item_id)
	
	var raw_items = ItemDB.get_random_items(3, exclude_ids)
	current_shop_items.clear()
	
	for raw_item in raw_items:
		current_shop_items.append({
			"type": "item",
			"price": raw_item.price if "price" in raw_item else 5,
			"icon": raw_item.item_texture,
			"name": raw_item.display_name,
			"desc": raw_item.description,
			"rarity": raw_item.rarity if "rarity" in raw_item else 1,
			"data": raw_item,
			"is_sold_out": false
		})
	
	emit_signal("shop_updated")

func reroll_items() -> void:
	if current_state != ShopState.BROWSING: return
	if GameManager.currency >= reroll_cost:
		GameManager.currency -= reroll_cost
		reroll_cost += reroll_cost_increment
		
		stock_recipe_pack = 1
		stock_ingredient_pack = 1
		
		generate_shop_inventory() 
	else:
		print("Không đủ tiền reroll!")

func buy_item(item_data: ItemData, cost: int) -> void:
	if GameManager.active_items.size() >= GameManager.max_active_items:
		print("Túi đồ đã đầy!")
		return
	
	if current_state != ShopState.BROWSING: return
	
	for shop_item in current_shop_items:
		if shop_item.get("data") == item_data and not shop_item.get("is_sold_out"):
			if GameManager.currency >= cost:
				GameManager.currency -= cost
				var new_item = ItemDB.create_item_instance(item_data.item_id)
				GameManager.active_items.append(new_item)
				
				shop_item["is_sold_out"] = true # Đánh dấu đã bán thay vì xóa
				print("Đã mua thành công Item: ", item_data.display_name)
				# Không gọi emit_signal("shop_updated") ở đây vì UI tự xử lý animation rồi gọi refresh
			else:
				print("Không đủ tiền mua Item!")
			return

func buy_recipe_pack() -> void:
	if current_state != ShopState.BROWSING or stock_recipe_pack <= 0: return
	
	if GameManager.currency >= recipe_pack_cost:
		GameManager.currency -= recipe_pack_cost
		stock_recipe_pack -= 1
		
		current_draft_choices = RecipeDB.get_random_recipes(3)
		current_state = ShopState.DRAFTING_RECIPE
		emit_signal("sig_buy_recipe_pack")
	else:
		print("Không đủ tiền mua Gói Công Thức!")

func buy_ingredient_pack() -> void:
	if current_state != ShopState.BROWSING or stock_ingredient_pack <= 0: return
	
	if GameManager.currency >= ingredient_pack_cost:
		GameManager.currency -= ingredient_pack_cost
		stock_ingredient_pack -= 1
		
		current_draft_choices = IngredientDB.get_random_ingredients(3)
		current_state = ShopState.DRAFTING_INGREDIENT
		emit_signal("sig_buy_ingredient_pack")
	else:
		print("Không đủ tiền mua gói nguyên liệu!")

func buy_card_removal() -> void:
	if current_state != ShopState.BROWSING or has_used_remove_service: return
	
	if GameManager.player_deck.size() <= 3:
		print("Bộ bài quá mỏng!")
		return
		
	if GameManager.currency >= card_removal_cost:
		GameManager.currency -= card_removal_cost
		has_used_remove_service = true # Đánh dấu đã dùng dịch vụ trong vòng này
		
		var temp_deck = GameManager.player_deck.duplicate()
		temp_deck.shuffle()
		
		current_draft_choices.clear()
		for i in range(min(3, temp_deck.size())):
			current_draft_choices.append(temp_deck[i])
			
		current_state = ShopState.REMOVING_CARD
		emit_signal("sig_remove_card")
	else:
		print("Không đủ tiền!")
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


func select_ingredient_choice(choice_index: int) -> void:
	if current_state != ShopState.DRAFTING_INGREDIENT: return
	
	var chosen_ingredient: IngredientInstance = current_draft_choices[choice_index]
	
	# Thêm vào bộ bài gốc của người chơi
	GameManager.player_deck.append(chosen_ingredient)
	print("Đã thêm lá bài vào Deck: ", chosen_ingredient.ingredient_data.display_name)
	
	_close_draft_panel()
	
func select_removal_choice(choice_index: int) -> void:
	if current_state != ShopState.REMOVING_CARD: return
	
	var card_to_remove: IngredientInstance = current_draft_choices[choice_index]
	
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

extends Node

# ====================
# Signal
# ====================
signal shop_updated  # Hét lên khi Kệ hàng hoặc Túi đồ có sự thay đổi
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
var can_buy_recipe_pack: bool = true
var can_buy_ingredient_pack: bool = true
var can_buy_card_removal: bool = true

const base_reroll_cost: int = 5
const reroll_cost_increment: int = 1
var reroll_cost: int = base_reroll_cost

func reset_shop() -> void:
	current_state = ShopState.BROWSING
	can_buy_recipe_pack = true
	can_buy_ingredient_pack = true
	can_buy_card_removal = true
	reroll_cost = base_reroll_cost
	current_shop_items.clear()
	generate_shop_inventory()

func generate_shop_inventory() -> void:
	current_state = ShopState.BROWSING
	var exclude_ids: Array = []
	for item in GameManager.active_items:
		exclude_ids.append(item.item_data.item_id)
	
	# Lấy item từ pool item có trong game, loại bỏ những item hiện đang sở hữu
	# Tùy vào độ hiếm thì item sẽ có tỉ lệ xuất hiện khác nhau. Cần mở rộng số lượng item trong tương lai
	current_shop_items = ItemDB.get_random_items(3, exclude_ids)
	
	emit_signal("shop_updated")

func reroll_items() -> void:
	if current_state != ShopState.BROWSING: return
	if GameManager.currency >= reroll_cost:
		GameManager.currency -= reroll_cost
		reroll_cost += reroll_cost_increment
		current_shop_items.clear()
		generate_shop_inventory() 
	else:
		print("Không đủ tiền reroll!")

func buy_item(item_data: ItemData, cost: int) -> void:
	if GameManager.active_items.size() >= GameManager.max_active_items:
		print("Túi đồ đã đầy, hãy bán bớt để mua thêm!")
		return
	
	if current_state != ShopState.BROWSING: return
	
	var item_index = current_shop_items.find(item_data)
	if item_index == -1: return
	
	if GameManager.currency >= cost:
		GameManager.currency -= cost
		var new_item = ItemDB.create_item_instance(item_data.item_id)
		GameManager.active_items.append(new_item)
		current_shop_items.remove_at(item_index)
		
		print("Đã mua thành công Item: ", item_data.display_name)
		
		emit_signal("shop_updated")
	else:
		print("Không đủ tiền mua Item!")

func buy_recipe_pack() -> void:
	if current_state != ShopState.BROWSING or not can_buy_recipe_pack: return
	
	if GameManager.currency >= recipe_pack_cost:
		GameManager.currency -= recipe_pack_cost
		#can_buy_recipe_pack = false
		
#		Hiện tại đang lấy ngẫu nhiên 3 recipe trong pool toàn bộ recipe có trong game
#		có thể nó hoạt động không tốt nhưng giờ không biết sửa như thế nào
		current_draft_choices = RecipeDB.get_random_recipes(3)
		current_state = ShopState.DRAFTING_RECIPE
		
		print("Đang mở Gói Công Thức... Vui lòng chọn 1.")
		
		emit_signal("sig_buy_recipe_pack")
		
		# Test để biết nó hoạt động, xóa khi UI hoàn thiện
		for recipe in current_draft_choices:
			print(RecipeDB.get_info(recipe))
	else:
		print("Không đủ tiền mua Gói Công Thức!")

func buy_ingredient_pack() -> void:
	if current_state != ShopState.BROWSING or not can_buy_ingredient_pack: return
	
	if GameManager.currency >= ingredient_pack_cost:
		GameManager.currency -= ingredient_pack_cost
		#can_buy_ingredient_pack = false
		
		# Tương tự như recipe, lựa chọn ra 3 ingreident ngẫu nhiên trong pool gồm 8 ingredient gốc
		# Trong tương lai có thể sẽ mở rộng thêm thuộc tính trong IngredientInstance thì hàm random cần thay đổi
		current_draft_choices = IngredientDB.get_random_ingredients(3)
		print(current_draft_choices)
		
		current_state = ShopState.DRAFTING_INGREDIENT
		
		print("Đang mở Gói Nguyên Liệu... Vui lòng chọn 1.")
		
		emit_signal("sig_buy_ingredient_pack")
		
		for ingredient in current_draft_choices:
			print(ingredient.get_info())
	else:
		print("Không đủ tiền mua gói nguyên liệu!")

func buy_card_removal() -> void:
	if current_state != ShopState.BROWSING or not can_buy_card_removal: return
	
	if GameManager.player_deck.size() <= 3:
		print("Bộ bài quá mỏng, không thể cắt thêm!")
		return
		
	if GameManager.currency >= card_removal_cost:
		GameManager.currency -= card_removal_cost
		can_buy_card_removal = false
		
		var temp_deck = GameManager.player_deck.duplicate()
		temp_deck.shuffle()
		
		current_draft_choices.clear()
		
		for i in range(min(3, temp_deck.size())):
			current_draft_choices.append(temp_deck[i])
			
		current_state = ShopState.REMOVING_CARD
		
		print("Chọn 1 lá bài để vứt vĩnh viễn khỏi Deck.")
		
		emit_signal("sig_remove_card")
		
		# Test để biết nó hoạt động, xóa khi UI hoàn thiện
		for ingredient in current_draft_choices:
			print(ingredient.get_info())
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

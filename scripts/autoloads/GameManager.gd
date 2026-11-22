extends Node

var currency: int = 0

# Số lượt Play / Discard còn lại của stage hiện tại.
# MatchManager là nguồn ghi chính; các Item đọc qua GameManager (P4: item không
# phụ thuộc node scene). Reset trong start_new_stage(), cập nhật khi Play,
# Discard hoặc meta effect (add_plays / add_discards) thay đổi.
var plays_left: int = 0
var discards_left: int = 0


func add_gold(amount: int) -> void:
	currency += amount
	print("Đã nhận ", amount, " vàng. Số dư: ", currency)

func spend_gold(amount: int) -> bool:
	if currency >= amount:
		currency -= amount
		return true
	return false

var player_deck: Array[IngredientInstance] = []
var active_items: Array[ItemInstance] = []
var max_active_items: int = 5


func _build_starter_deck() -> void:
	var STARTER_DECK_TEMPLATE: Array = ["beef", "cabbage", "chicken", "chili", "rice", "salt", "tomato", "egg"]
	for ingredient in STARTER_DECK_TEMPLATE:
		for i in range(5):
			var new_instance = IngredientDB.create_ingredient_instance_by_id(ingredient)
			if new_instance != null:
				player_deck.append(new_instance)

func _ready() -> void:	start_new_run()

func start_new_run() -> void:
	currency = 100 # Tiền khởi điểm
	active_items.clear()
	player_deck.clear()
	_build_starter_deck()
	_debug_create_item()
	print("Từ GameManager: Bắt đầu run")
	StageManager.start_new_run()
	RecipeDB.reset_crafted_counts()


func _debug_create_item() -> void:
	active_items.append(ItemDB.create_item_instance("goldtest3"))
	active_items.append(ItemDB.create_item_instance("fork"))
	active_items.append(ItemDB.create_item_instance("last_chance"))
	active_items.append(ItemDB.create_item_instance("papper_clip"))

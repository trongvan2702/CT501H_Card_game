extends Node

var currency: int = 0

var plays_left: int = 0
var discards_left: int = 0
var maximum_draw_card: int = 5

var best_serve_score: float = 0.0
var total_ingredients_played: int = 0
var total_ingredients_discarded: int = 0
var total_purchases: int = 0 # Tính chung Item + Pack
var total_rerolls: int = 0

func reset_run_stats() -> void:
	best_serve_score = 0.0
	total_ingredients_played = 0
	total_ingredients_discarded = 0
	total_purchases = 0
	total_rerolls = 0

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
	reset_run_stats() 
	_build_starter_deck()
	_debug_create_item()
	print("Từ GameManager: Bắt đầu run")
	StageManager.start_new_run()
	RecipeDB.reset_crafted_counts()

func record_serve(score: float) -> void:
	if score > best_serve_score:
		best_serve_score = score

func record_ingredients_played(count: int) -> void:
	total_ingredients_played += count

func record_ingredients_discarded(count: int) -> void:
	total_ingredients_discarded += count

func record_purchase(count: int = 1) -> void:
	total_purchases += count

func record_reroll() -> void:
	total_rerolls += 1

func _debug_create_item() -> void:
	active_items.append(ItemDB.create_item_instance("goldtest3"))
	active_items.append(ItemDB.create_item_instance("fork"))
	active_items.append(ItemDB.create_item_instance("last_chance"))
	#active_items.append(ItemDB.create_item_instance("papper_clip"))

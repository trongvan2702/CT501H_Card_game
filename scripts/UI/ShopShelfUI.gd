class_name ShopShelfUI
extends VBoxContainer

# Tín hiệu báo lên cho ShopUI biết có 1 món hàng vừa được bấm mua
signal item_buy_requested(shop_ui_node: ShopItemUI)

const SHOP_ITEM_SCENE = preload("res://scenes/ShopItemUI.tscn")

# Trỏ tới các HBoxContainer chứa hàng
@onready var items_container = $TopShelf/CharmsSection/ItemsContainer
@onready var packs_container = $TopShelf/PacksSection/PacksContainer
@onready var services_container = $BottomShelf/ServicesContainer

# ==========================================
# DỮ LIỆU TĨNH
# ==========================================
var RECIPE_PACK_DATA = {
	"type": "recipe_pack",
	"price": 5,
	"icon": preload("res://assets/RecipeCardPack_.png"),
	"name": "Recipe Pack",
	"desc": "Reveal 3 random recipes. Choose 1 to upgrade or unlock.",
}

var INGREDIENT_PACK_DATA = {
	"type": "ingredient_pack",
	"price": 5,
	"icon": preload("res://assets/IngredientCardPack.png"),
	"name": "Ingredient Pack",
	"desc": "Reveal 3 random ingredients. Choose 1 to add to your deck.",
}

var REMOVE_SERVICE_DATA = {
	"type": "remove",
	"price": 5,
	"icon": preload("res://assets/Remove.png"),
	"name": "Remove Card",
	"desc": "",
}

var REROLL_SERVICE_DATA = {
	"type": "reroll",
	"price": 5,
	"icon": preload("res://assets/Reroll.png"),
	"name": "Reroll Shop",
	"desc": "",
}

# ==========================================
# VẼ CỬA HÀNG
# ==========================================
func render_shelf(animate_pop_in: bool = false) -> void:
	_clear_container(items_container)
	_clear_container(packs_container)
	_clear_container(services_container)
	
	# 1. Vẽ Charms (Items) - có hiệu ứng pop-in khi reroll
	for item_data in ShopManager.current_shop_items:
		_create_product_ui(item_data, items_container, animate_pop_in)
		
	# 2. Vẽ Packs - có hiệu ứng pop-in khi reroll
	var rec_data = RECIPE_PACK_DATA.duplicate()
	rec_data["is_sold_out"] = ShopManager.stock_recipe_pack <= 0
	_create_product_ui(rec_data, packs_container, animate_pop_in)
	
	var ing_data = INGREDIENT_PACK_DATA.duplicate()
	ing_data["is_sold_out"] = ShopManager.stock_ingredient_pack <= 0
	_create_product_ui(ing_data, packs_container, animate_pop_in)
	
	# 3. Vẽ Services - luôn truyền false để nút Reroll/Remove đứng yên
	var reroll_data = REROLL_SERVICE_DATA.duplicate()
	reroll_data["price"] = ShopManager.reroll_cost
	reroll_data["is_sold_out"] = false
	_create_product_ui(reroll_data, services_container, false)
	
	var remove_data = REMOVE_SERVICE_DATA.duplicate()
	remove_data["price"] = ShopManager.card_removal_cost
	remove_data["is_sold_out"] = false
	_create_product_ui(remove_data, services_container, false)

func refresh_availability() -> void:
	for container in [items_container, packs_container, services_container]:
		for child in container.get_children():
			if child is ShopItemUI:
				child._update_availability_visuals()

# Hàm phụ trợ dọn khay
func _clear_container(container: Control) -> void:
	for child in container.get_children():
		child.queue_free()

func _create_product_ui(data: Dictionary, parent_container: Control, animate_pop_in: bool = false) -> void:
	var product_ui = SHOP_ITEM_SCENE.instantiate() as ShopItemUI
	
	parent_container.add_child(product_ui)
	product_ui.setup(data)
	
	if animate_pop_in:
		product_ui.play_appear_animation()
		
	product_ui.buy_requested.connect(_on_child_buy_requested)

func _on_child_buy_requested(product_ui: ShopItemUI) -> void:
	emit_signal("item_buy_requested", product_ui)

func play_reroll_out_animation() -> void:
	var has_animated := false
	
	for container in [items_container, packs_container]:
		for child in container.get_children():
			if child is ShopItemUI and not child.is_sold_out:
				child.play_sold_animation()
				has_animated = true
				
	if has_animated:
		await get_tree().create_timer(0.3).timeout

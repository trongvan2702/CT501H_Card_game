extends Control
class_name ShopUI

@onready var owned_items_tray = $OwnedItemsTray
@onready var shop_shelf = $ShopShelf
@onready var gold_label = $Gold
@onready var reroll_button = $GridContainer/RerollButton

# Draft Overlay UI
@onready var draft_overlay = $DraftOverlay
@onready var draft_title = $DraftOverlay/VBoxContainer/DraftTitle
@onready var draft_choices_tray = $DraftOverlay/VBoxContainer/DraftChoices


@onready var view_deck_btn = $ViewDeckButton
@onready var deck_viewer_ui = $DeckViewerUI

func _ready() -> void:
	# Connect Signal
	ShopManager.shop_updated.connect(_on_shop_manager_updated)
	ShopManager.sig_buy_recipe_pack.connect(_on_open_recipe_pack)
	ShopManager.sig_buy_ingredient_pack.connect(_on_open_ingredient_pack)
	ShopManager.sig_remove_card.connect(_on_open_card_removal)
	
	view_deck_btn.deck_opened.connect(_on_view_deck_opened)
	view_deck_btn.update_counts(GameManager.player_deck.size())
	
	ShopManager.reset_shop()
	
	

# ==========================================
# KHU VỰC LẮNG NGHE & VẼ MÀN HÌNH (UI)
# ==========================================

func _update_display_labels() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % [GameManager.currency]
	if reroll_button:
		reroll_button.text = "Reroll(%d)" % [ShopManager.reroll_cost]

func _on_shop_manager_updated() -> void:
	_render_owned_items()
	_render_shop_items()
	_update_display_labels()

func _on_open_recipe_pack() -> void:
	draft_title.text = "Gói Công Thức: Chọn 1 món để Mở khóa hoặc Nâng cấp"
	_render_draft_choices("recipe")

func _on_open_ingredient_pack() -> void:
	draft_title.text = "Gói Nguyên Liệu: Chọn 1 lá để thêm vào Bộ bài"
	_render_draft_choices("ingredient")

func _on_open_card_removal() -> void:
	draft_title.text = "Dịch Vụ Cắt Thẻ: Chọn 1 lá bài để XÓA vĩnh viễn"
	_render_draft_choices("removal")

# Taoj UI cho phần Item hiện coc của bản thân
func _render_owned_items() -> void:
	for child in owned_items_tray.get_children():
		child.queue_free()
		
	for item_instance in GameManager.active_items:
		var card = ItemCard.create_from_instance(item_instance)
		owned_items_tray.add_child(card)

# Tạo UI cho phần Item trong Shop
func _render_shop_items() -> void:
	for child in shop_shelf.get_children():
		child.queue_free()
		
	# Đọc dữ liệu từ ShopSystem để vẽ
	for item_data in ShopManager.current_shop_items:
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var card = ItemCard.create_from_data(item_data)
		card.is_shop_item = true
		
		# Khi thẻ phát tín hiệu xin mua, chuyển nó cho hàm xử lý của UI
		var cost = item_data.price # Giả sử Data có sẵn price
		card.buy_requested.connect(_on_shop_card_buy_requested.bind(item_data, cost))
		
		var price_label = Label.new()
		price_label.text = str(cost) + " Vàng"
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		vbox.add_child(card)
		vbox.add_child(price_label)
		shop_shelf.add_child(vbox)
		print(vbox)

# Hàm hứng tín hiệu khi người chơi bấm vào thẻ trên kệ
func _on_shop_card_buy_requested(card: ItemCard, item_data: ItemData, cost: int) -> void:
	ShopManager.buy_item(item_data, cost)

func _on_reroll_button_pressed() -> void:
	ShopManager.reroll_items()

func _render_draft_choices(draft_type: String) -> void:
	draft_overlay.visible = true # Bật màn hình bốc thẻ
	
	# Dọn sạch khay bốc bài cũ
	for child in draft_choices_tray.get_children():
		child.queue_free()
		
	# Lấy danh sách 3 lá bài từ Két sắt
	var choices = ShopManager.current_draft_choices
	
	for i in range(choices.size()):
		var choice = choices[i]
		if draft_type == "recipe":
			var recipe_card = RecipeCard.create_from_data(choice)
			recipe_card.card_clicked.connect(_on_recipe_card_draft_selected.bind(draft_type, i))
			draft_choices_tray.add_child(recipe_card)
		else:
			var card = IngredientCard.create_from_instance(choice)
			card.mouse_filter = Control.MOUSE_FILTER_PASS
			card.card_clicked.connect(_on_ingredient_card_draft_selected.bind(draft_type, i))
			draft_choices_tray.add_child(card)

func _on_skip_button_pressed() -> void:
	ShopManager.skip_draft_choice()
	draft_overlay.visible = false

func _on_change_button_pressed() -> void:
	StageManager.advance_to_next_stage()
	get_tree().change_scene_to_file("res://scenes/MatchManager.tscn")


func _on_ingredientt_pack_pressed() -> void:
	ShopManager.buy_ingredient_pack()
	_update_display_labels()


func _on_recipe_pack_pressed() -> void:
	ShopManager.buy_recipe_pack()
	_update_display_labels()


func _on_remove_card_pressed() -> void:
	ShopManager.buy_card_removal()
	_update_display_labels()

# Hàm xử lý khi bấm vào IngredientCard (dùng riêng cho tín hiệu của IngredientCard)
func _on_ingredient_card_draft_selected(card_node: IngredientCard, draft_type: String, choice_index: int) -> void:
	# Bỏ qua tham số card_node (do signal card_clicked phát ra) và gọi hàm xử lý chung
	_process_draft_selection(draft_type, choice_index)

# Hàm xử lý khi bấm vào RecipeCard (dùng riêng cho tín hiệu của RecipeCard)
func _on_recipe_card_draft_selected(card_node: RecipeCard, draft_type: String, choice_index: int) -> void:
	# Bỏ qua tham số card_node (do signal card_clicked phát ra) và gọi hàm xử lý chung
	_process_draft_selection(draft_type, choice_index)

# Hàm xử lý logic chung sau khi bốc bài
func _process_draft_selection(draft_type: String, choice_index: int) -> void:
	match draft_type:
		"recipe": ShopManager.select_recipe_choice(choice_index)
		"ingredient": ShopManager.select_ingredient_choice(choice_index)
		"removal": ShopManager.select_removal_choice(choice_index)
		
	draft_overlay.visible = false
	_update_display_labels()

func _on_view_deck_opened() -> void:
	deck_viewer_ui.open_viewer(DeckViewerUI.ViewMode.SHOP)
	pass

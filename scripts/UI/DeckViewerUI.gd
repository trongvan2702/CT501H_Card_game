class_name DeckViewerUI
extends Control

enum ViewMode { SHOP, MATCH }

# Khai báo các Node dựa theo cấu trúc đã thống nhất
@onready var grid_container = $PanelContainer/MarginContainer/MainVBox/ScrollContainer/GridContainer
@onready var total_cards_label = $PanelContainer/MarginContainer/MainVBox/HeaderBox/TitleVBox/StatsHBox/TotalCard/MarginContainer/TotalCardsLabel
@onready var ingredients_count_label = $PanelContainer/MarginContainer/MainVBox/HeaderBox/TitleVBox/StatsHBox/IngredientsCount/MarginContainer/IngredientsCountLabel
@onready var remain_draw_label = $PanelContainer/MarginContainer/MainVBox/HeaderBox/TitleVBox/StatsHBox/RemainDraw/MarginContainer/RemainDrawLabel
@onready var close_button = $PanelContainer/MarginContainer/MainVBox/HeaderBox/CloseButton
@onready var remain_draw = $PanelContainer/MarginContainer/MainVBox/HeaderBox/TitleVBox/StatsHBox/RemainDraw
# Thông số xếp chồng thẻ
const CARD_WIDTH = 200
const CARD_HEIGHT = 280
const OFFSET_X = 35

func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_button_pressed)

func _on_close_button_pressed() -> void:
	visible = false

# ========================================================
# HÀM MỞ GIAO DIỆN (Nhận thêm mảng remaining_pile từ MatchManager)
# ========================================================
func open_viewer(mode: ViewMode, remaining_pile: Array = []) -> void:
	visible = true
	_render_deck(mode, remaining_pile)

# ========================================================
# XỬ LÝ LƯỚI BÀI VÀ LÀM XÁM
# ========================================================
func _render_deck(mode: ViewMode, remaining_pile: Array) -> void:
	# 1. Dọn dẹp lưới cũ
	for child in grid_container.get_children():
		child.queue_free()
		
	var full_deck = GameManager.player_deck
	
	# 2. Gom nhóm Tổng Bài Gốc theo item_id
	var deck_groups = {}
	for card in full_deck:
		var id = card.ingredient_data.ingredient_id
		if not deck_groups.has(id):
			deck_groups[id] = []
		deck_groups[id].append(card)
		
	# 3. Gom nhóm Bài Còn Lại (chỉ dùng trong Match Mode)
	var remain_counts = {}
	if mode == ViewMode.MATCH:
		for card in remaining_pile:
			var id = card.ingredient_data.ingredient_id
			if not remain_counts.has(id):
				remain_counts[id] = 0
			remain_counts[id] += 1
			
	# 4. Cập nhật thông số Header
	total_cards_label.text = "%d CARDS" % full_deck.size()
	ingredients_count_label.text = "%d INGREDIENTS" % deck_groups.size()
	
	if mode == ViewMode.MATCH:
		remain_draw_label.visible = true
		remain_draw_label.text = "%d LEFT TO DRAW" % remaining_pile.size()
	else:
		remain_draw.visible = false
		

	# 5. Vẽ từng nhóm bài lên lưới
	for id in deck_groups:
		var card_list = deck_groups[id]
		var total_count = card_list.size()
		
		# Số bài còn lại chưa bốc (Nếu ở Shop thì mặc định bằng total_count)
		var remain_count = total_count
		if mode == ViewMode.MATCH:
			remain_count = remain_counts.get(id, 0)
			
		_create_card_stack(card_list[0], total_count, remain_count, mode)

# ========================================================
# HÀM TẠO CHỒNG BÀI (XẾP LỚP)
# ========================================================
func _create_card_stack(sample_card: IngredientInstance, total_count: int, remain_count: int, mode: ViewMode) -> void:
	var group_vbox = VBoxContainer.new()
	group_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Tạo một Control rỗng làm "Sân khấu" xếp bài
	var stack_control = Control.new()
	# Tính toán độ rộng thực tế của cả chồng bài để GridContainer có thể bọc vừa vặn
	var total_width = CARD_WIDTH + (total_count - 1) * OFFSET_X
	stack_control.custom_minimum_size = Vector2(total_width, CARD_HEIGHT)
	
	# Sinh ra các lá bài xếp chồng lên nhau
	for i in range(total_count):
		var card_ui = IngredientCard.create_from_instance(sample_card)
		card_ui.mouse_filter = Control.MOUSE_FILTER_STOP # STOP giúp thẻ nhận hover nhưng không ném sự kiện chuột ra phía sau
		card_ui.is_clickable = false # Tắt tương tác click
		
		# Nhích tọa độ X sang phải
		card_ui.position = Vector2(i * OFFSET_X, 0)
		
		if i >= remain_count:
			# Chuyển thành màu xám tối và hơi trong suốt
			card_ui.modulate = Color(0.43, 0.43, 0.43)
			## Đẩy những lá bài xám xuống dưới cùng (z_index thấp) để không đè lên lá bài còn sáng
			#card_ui.z_index = 0
		#else:
			## Lá bài còn trong xấp sẽ nằm đè lên trên
			#card_ui.z_index = 1
			
		stack_control.add_child(card_ui)
		
	# Gắn Label thông tin bên dưới chồng bài
	var count_label = Label.new()
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var name_str = sample_card.ingredient_data.display_name.to_upper()
	if mode == ViewMode.SHOP:
		count_label.text = "%s  %d cards" % [name_str, total_count]
	else:
		count_label.text = "%s  %d/%d in pile" % [name_str, remain_count, total_count]
		# Đổi màu chữ thành đỏ nếu đã bốc hết
		if remain_count == 0:
			count_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
			
	group_vbox.add_child(stack_control)
	group_vbox.add_child(count_label)
	
	grid_container.add_child(group_vbox)


func _on_overlay_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			visible = false 

extends Node
class_name HandManager

signal selection_changed(selected_count: int)
signal cards_selection_changed(selected_cards: Array)

@export var hand_ui_container: Control

const max_select = 5
var card_in_hand: Array[IngredientCard] = []
const MAX_HAND_WIDTH = 900.0   # Độ rộng tối đa của tay bài
const ARC_HEIGHT = 35.0        # Độ vồng của cung (số càng lớn bài càng nhô lên cao)
const MAX_ROTATION_DEG = 12.0  # Góc nghiêng tối đa của 2 lá bài ngoài cùng
const HOVER_PUSH_DISTANCE = 50.0

func add_card_to_hand(instance: IngredientInstance) -> void:
	var new_card = IngredientCard.create_from_instance(instance)
	new_card.card_clicked.connect(_on_card_clicked)
	new_card.card_size = new_card.card_size * 0.9
	new_card.card_hoverd.connect(_on_card_hovered)
	new_card.card_unhovered.connect(_on_card_unhovered)
	
	if hand_ui_container:
		hand_ui_container.add_child(new_card)
		
	card_in_hand.append(new_card)
	
	update_hand_layout()

func add_cards_to_hand(cards: Array[IngredientInstance]) -> void:
	for card in cards:
		add_card_to_hand(card)

func _on_card_clicked(card: IngredientCard) -> void:
	if card.is_selected:
		card.is_selected = false
		card._update_visual_state()
	else: 
		if get_selected_cards().size() < max_select:
			card.is_selected = true
			card._update_visual_state()
		else: print("Cannot select more than 5 card")
	emit_signal("selection_changed", get_selected_cards().size())
	emit_signal("cards_selection_changed", get_selected_cards())

func get_cards_in_hand() -> int:
	return card_in_hand.size()

func get_selected_cards() -> Array[IngredientCard]:
	var selected: Array[IngredientCard] = []
	for card in card_in_hand:
		if card.is_selected:
			selected.append(card)
	return selected

func extract_and_remove_selected() -> Array[IngredientInstance]:
	var extracted_cards: Array[IngredientInstance] = []
	var remained_cards: Array[IngredientCard] = []
	
	for card in card_in_hand:
		if card.is_selected:
			extracted_cards.append(card.ingredient_instance)
			card.queue_free()
		else: remained_cards.append(card)
	
	card_in_hand = remained_cards
	emit_signal("selection_changed", 0)
	emit_signal("cards_selection_changed", [])
	
	update_hand_layout()
	
	return extracted_cards

func extract_selected_card_nodes() -> Array[IngredientCard]:
	var extracted_nodes: Array[IngredientCard] = []
	var remained_cards: Array[IngredientCard] = []
	
	for card in card_in_hand:
		if card.is_selected:
			# Ngắt toàn bộ tương tác tay bài
			if card.card_clicked.is_connected(_on_card_clicked):
				card.card_clicked.disconnect(_on_card_clicked)
			if card.card_hoverd.is_connected(_on_card_hovered):
				card.card_hoverd.disconnect(_on_card_hovered)
			if card.card_unhovered.is_connected(_on_card_unhovered):
				card.card_unhovered.disconnect(_on_card_unhovered)
				
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.is_selected = false
			extracted_nodes.append(card)
		else:
			remained_cards.append(card)
			
	card_in_hand = remained_cards
	emit_signal("selection_changed", 0)
	emit_signal("cards_selection_changed", [])
	update_hand_layout()
	
	return extracted_nodes

func clear_hand() -> void:
	for card in card_in_hand:
		card.queue_free()
	card_in_hand.clear()
	emit_signal("selection_changed", 0)
	emit_signal("cards_selection_changed", [])

func update_hand_layout() -> void:
	var count = card_in_hand.size()
	if count == 0 or hand_ui_container == null:
		return
		
	var center_x = hand_ui_container.size.x / 2.0
	
	# Tính khoảng cách giữa các lá bài (Bài càng nhiều thì xếp càng sát nhau)
	var spacing = min(130.0, MAX_HAND_WIDTH / float(count))
	var start_x = center_x - (spacing * (count - 1)) / 2.0
	
	for i in range(count):
		var card = card_in_hand[i]
		
		# Trọng số t chạy từ -1.0 (lá ngoài cùng bên trái) đến 1.0 (lá ngoài cùng bên phải)
		# Lá ở chính giữa sẽ có t = 0
		var t = 0.0
		if count > 1:
			t = (float(i) / float(count - 1)) * 2.0 - 1.0
			
		# 1. Tính Tọa độ X
		# Cần trừ đi card.size.x / 2 để căn giữa lá bài tại tọa độ đó
		var target_x = start_x + (i * spacing) - (card.size.x / 2.0)
		
		# 2. Tính Tọa độ Y theo Parabola (t * t sẽ tạo ra đường cong chữ U)
		# Tâm quạt nằm ở dưới, bài càng ra xa tâm (t tiến về 1 hoặc -1) thì Y càng tăng (tức là bị hạ thấp xuống)
		var target_y = abs(t * t) * ARC_HEIGHT 
		
		# 3. Tính Góc xoay
		var target_rot = t * deg_to_rad(MAX_ROTATION_DEG)
		
		# Gán vào biến gốc của lá bài
		card.base_position = Vector2(target_x, target_y)
		card.base_rotation = target_rot
		
		# Gọi hàm update_visual_state để lá bài mượt mà trượt tới vị trí hình cung mới
		card._update_visual_state_with_push()
		
		# Cập nhật z_index để lá bài bên phải đè lên lá bài bên trái giống ngoài đời
		card.z_index = i

func _on_card_hovered(hovered_card: IngredientCard) -> void:
	_update_all_cards_visuals(hovered_card)

func _on_card_unhovered(unhovered_card: IngredientCard) -> void:
	# Khi không hover lá nào, truyền null vào để các lá bài trở về vị trí cũ
	_update_all_cards_visuals(null)

func _update_all_cards_visuals(hovered_card: IngredientCard) -> void:
	var hovered_index = -1
	if hovered_card != null:
		hovered_index = card_in_hand.find(hovered_card)
		
	for i in range(card_in_hand.size()):
		var card = card_in_hand[i]
		
		# Tính toán độ lệch ngang (X offset) do bị đẩy
		var push_x = 0.0
		
		if hovered_index != -1 and i != hovered_index:
			# Lá bài đang xét nằm bên PHẢI lá đang được hover
			if i > hovered_index:
				push_x = HOVER_PUSH_DISTANCE
			# Lá bài đang xét nằm bên TRÁI lá đang được hover
			elif i < hovered_index:
				push_x = -HOVER_PUSH_DISTANCE
				
		# Gọi hàm update hình ảnh của thẻ và truyền thêm tham số đẩy ngang
		card._update_visual_state_with_push(push_x)

func deselect_all() -> void:
	for card in card_in_hand:
		if card.is_selected:
			card.is_selected = false
			card._update_visual_state()
	emit_signal("selection_changed", 0)

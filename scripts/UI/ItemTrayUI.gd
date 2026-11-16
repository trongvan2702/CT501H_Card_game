class_name ItemTrayUI
extends PanelContainer

# Tín hiệu phát ra để báo cho Match/Shop biết vừa có đồ được bán
# Nhờ tín hiệu này, Manager mới biết đường gọi HUD cập nhật lại chữ số tiền
signal item_sold 

@onready var items_container = $MarginContainer/OwnedItemsTray
@onready var capacity_label = $MarginContainer/Label

func _ready() -> void:
	#refresh_tray()
	pass

# Hàm này thay thế hoàn toàn cho _render_owned_items() cũ của bạn
func refresh_tray() -> void:
	# 1. Dọn sạch khay cũ
	for child in items_container.get_children():
		child.queue_free()
		
	# 2. Tạo thẻ mới từ GameManager
	for item_instance in GameManager.active_items:
		var card = ItemCard.create_from_instance(item_instance)
		# Kết nối tín hiệu bán trực tiếp vào khay này
		card.sell_requested.connect(_on_item_sell_requested)
		items_container.add_child(card)
		
	# 3. Cập nhật sức chứa (0/5)
	var current_count = GameManager.active_items.size()
	var max_count = GameManager.max_active_items
	capacity_label.text = "%d/%d" % [current_count, max_count]

func _on_item_sell_requested(card: ItemCard) -> void:
	# Khóa click để tránh spam
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 1. Xử lý logic cộng tiền và xóa khỏi kho
	var price = card._calculate_sell_price()
	GameManager.add_gold(price)
	
	var idx = GameManager.active_items.find(card.display_instance)
	if idx != -1:
		GameManager.active_items.remove_at(idx)
	
	card.pivot_offset = card.size / 2.0
	# 2. Chạy hiệu ứng thu nhỏ
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(card, "modulate:a", 0.0, 0.2)
	
	# 3. Chờ xong hiệu ứng thì xóa Node, vẽ lại và hô to cho Manager biết
	tween.chain().tween_callback(func():
		card.queue_free()
		refresh_tray()
		emit_signal("item_sold")
	)

func add_new_item(item_instance: ItemInstance) -> void:
	var card = ItemCard.create_from_instance(item_instance)
	card.sell_requested.connect(_on_item_sell_requested)
	
	# Đặt scale = 0 NGAY TRƯỚC KHI add_child để tránh bị chớp hình lớn
	#card.scale = Vector2(0.5, 0.5)
	
	items_container.add_child(card)
	
	var current_count = GameManager.active_items.size()
	var max_count = GameManager.max_active_items
	capacity_label.text = "%d/%d" % [current_count, max_count]
	
	# CHỜ 1 FRAME ĐỂ HBoxContainer XẾP LAYOUT XONG
	await get_tree().process_frame
	
	# Chỉnh tâm thu phóng sau khi layout đã được xác định
	card.pivot_offset = card.size / 2.0 
	
	# Đảm bảo scale vẫn là 0 trước khi chạy Tween
	card.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

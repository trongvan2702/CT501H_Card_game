extends Control
class_name ItemCard

const CARD_SCENE = preload("res://scenes/ItemCard.tscn")

var display_data: ItemData = null
var display_instance: ItemInstance = null

@onready var icon_sprite = $TextureRect
@onready var detail_panel = $PanelContainer
@onready var detail_label = $PanelContainer/DetailLabel

var is_clicked: bool = false
var is_hovered: bool = false

signal buy_requested(card)
var is_shop_item: bool = false

# Dùng khi hàng nằm trên kệ Shop (Chưa sở hữu)
static func create_from_data(data: ItemData) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_data = data
	return card

# Dùng khi hàng nằm trong túi đồ (Đã sở hữu, có chỉ số động)
static func create_from_instance(instance: ItemInstance) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_instance = instance
	card.display_data = instance.item_data
	return card

func _ready() -> void:
	detail_panel.visible = false
	_update_display()
	icon_sprite.pivot_offset = icon_sprite.size / 2.0

func _update_display() -> void:
	if display_data == null: return
	
	icon_sprite.texture = display_data.item_texture
	
	var item_name = display_data.display_name
	var item_desc = display_instance.get_dynamic_description() if display_instance else display_data.description
	
	# Định dạng BBCode: Tên in đậm size 20, Mô tả thường size 14, Căn giữa
	var formatted_text = "[center]"
	formatted_text += "[font_size=20][b]" + item_name + "[/b][/font_size]\n"
	formatted_text += "[font_size=14]" + item_desc + "[/font_size]"
	formatted_text += "[/center]"
	
	detail_label.text = formatted_text

# Bắt sự kiện click chuột vào vùng Control của thẻ
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			accept_event()
			if is_shop_item:
				emit_signal("buy_requested", self)
			else:
				is_clicked = !is_clicked 
				_update_state()

func _input(event: InputEvent) -> void:
	if is_clicked and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var card_rect = get_global_rect()
			var panel_rect = detail_panel.get_global_rect()
			
			if not card_rect.has_point(mouse_pos) and not panel_rect.has_point(mouse_pos):
				is_clicked = false # Gỡ ghim
				_update_state()

# 1. BẮT ĐẦU KÉO: Kích hoạt khi bạn giữ chuột trái và kéo thẻ
func _get_drag_data(at_position: Vector2) -> Variant:
	# Khóa tính năng kéo đối với đồ trong Cửa hàng hoặc thẻ Boss
	if display_instance == null or display_instance.is_boss_modifier:
		return null
		
	# Đóng bảng thông tin khi bắt đầu cầm thẻ lên
	is_clicked = false
	is_hovered = false
	_update_state()
	
	# Tạo một ảnh mờ mờ bay theo con chuột (Drag Preview)
	var preview = TextureRect.new()
	preview.texture = icon_sprite.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size
	
	var control = Control.new()
	control.add_child(preview)
	preview.position = -size / 2 # Đưa tâm bức ảnh vào đúng mũi tên chuột
	set_drag_preview(control)
	
	return self # Đóng gói chính thẻ này làm dữ liệu truyền đi

# 2. KIỂM TRA ĐIỂM HẠ CÁNH: Xác định xem thẻ đang bị kéo có được phép rớt xuống đây không
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	# Chỉ cho phép hạ cánh nếu đối tượng đang kéo là một ItemCard,
	# và thẻ bị đè lên không phải là hàng của Shop hay thẻ Boss.
	return data is ItemCard and display_instance != null and not display_instance.is_boss_modifier

# 3. THỰC THI THẢ THẺ: Đổi chỗ khi người chơi buông chuột
func _drop_data(at_position: Vector2, dragged_card: Variant) -> void:
	# Bước A: Đổi chỗ hiển thị trên giao diện (Trong HBoxContainer)
	var target_index = self.get_index()
	get_parent().move_child(dragged_card, target_index)
	
	# Bước B: Đổi chỗ thực tế trong bộ nhớ (GameManager.active_items)
	var gm_dragged_idx = GameManager.active_items.find(dragged_card.display_instance)
	var gm_target_idx = GameManager.active_items.find(self.display_instance)
	
	if gm_dragged_idx != -1 and gm_target_idx != -1:
		# Rút thẻ đang kéo ra khỏi mảng và chèn vào vị trí mới
		var item = GameManager.active_items.pop_at(gm_dragged_idx)
		GameManager.active_items.insert(gm_target_idx, item)


func _update_state() -> void:
	var target_scale = Vector2(1.0, 1.0)
	
	# Nếu đang được Hover HOẶC đang bị Click ghim lại -> Hiện bảng và Phóng to
	if is_clicked or is_hovered:
		detail_panel.visible = true
		z_index = 1
		target_scale = Vector2(1.2, 1.2) # Phóng to lên 120%
	else:
		detail_panel.visible = false
		z_index = 0
		target_scale = Vector2(1.0, 1.0) # Trở về bình thường
	
	var tween = create_tween()
	tween.tween_property(icon_sprite, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_state()

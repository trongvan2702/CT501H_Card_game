extends Control
class_name ItemCard

const CARD_SCENE = preload("res://scenes/ItemCard.tscn")

const RARITY_NAMES := {
	1: "COMMON",
	2: "UNCOMMON",
	3: "RARE",
	4: "EPIC",
	5: "LEGENDARY"
}

const RARITY_COLORS := {
	1: Color(0.78, 0.74, 0.66),
	2: Color(0.47, 0.85, 0.47),
	3: Color(0.45, 0.70, 1.0),
	4: Color(0.85, 0.45, 1.0),
	5: Color(1.0, 0.78, 0.32)
}

const RARITY_BG_COLORS := {
	1: Color(0.18, 0.18, 0.19), 
	2: Color(0.12, 0.24, 0.16), 
	3: Color(0.15, 0.20, 0.35), 
	4: Color(0.25, 0.12, 0.35),
	5: Color(0.28, 0.12, 0.12)
}

# ---------------------------------------------
# BIẾN DỮ LIỆU VÀ NODE
# ---------------------------------------------
var display_data: ItemData = null
var display_instance: ItemInstance = null

@onready var icon_sprite = $TextureRect
@onready var detail_tooltip = $DetailTooltip

# Cập nhật đường dẫn đúng với cây Node mới của bạn
@onready var item_name = $DetailTooltip/Margin/VBox/ItemName/Margin/Label
@onready var item_desc = $DetailTooltip/Margin/VBox/ItemDescription/Margin/ItemDesc
@onready var item_rarity = $DetailTooltip/Margin/VBox/ItemRarity/Margin/ItemDesc
@onready var sell_button = $DetailTooltip/Margin/VBox/SellButton/Margin/Button
@onready var sell_buttton_panel = $DetailTooltip/Margin/VBox/SellButton

var is_clicked: bool = false
var is_hovered: bool = false
var is_shop_item: bool = false

signal buy_requested(card)
signal sell_requested(card)

# ---------------------------------------------
# KHỞI TẠO VÀ HIỂN THỊ
# ---------------------------------------------
static func create_from_data(data: ItemData) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_data = data
	return card

static func create_from_instance(instance: ItemInstance) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_instance = instance
	card.display_data = instance.item_data
	return card

func _ready() -> void:
	detail_tooltip.visible = false
	icon_sprite.pivot_offset = icon_sprite.size / 2.0
	
	if sell_button:
		sell_button.pressed.connect(_on_sell_button_pressed)
		
	_update_display()

func _update_display() -> void:
	if display_data == null: return
	
	icon_sprite.texture = display_data.item_texture
	item_name.text = display_data.display_name
	
	var desc = display_instance.get_dynamic_description() if display_instance else display_data.description
	item_desc.text = desc
	
	# XỬ LÝ ĐỘ HIẾM (CẢ CHỮ VÀ NỀN)
	var rarity_lvl: int = display_data.rarity if "rarity" in display_data else 1
	rarity_lvl = clampi(rarity_lvl, 1, 5)
	
	# 1. Đổi chữ và màu chữ
	item_rarity.text = RARITY_NAMES.get(rarity_lvl, "COMMON")
	item_rarity.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_lvl, Color.WHITE))
	
	# 2. Tạo nền (StyleBoxFlat) cho chính Label ItemRarity
	var style = StyleBoxFlat.new()
	style.bg_color = RARITY_BG_COLORS.get(rarity_lvl, Color(0.2, 0.2, 0.2))
	style.set_corner_radius_all(4)
	# Tự động đẩy lề (Padding) để chữ không cấn vào sát viền nền
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 5
	style.content_margin_right = 5
	
	item_rarity.add_theme_stylebox_override("normal", style)
	item_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# XỬ LÝ NÚT BÁN
	if is_shop_item or display_instance == null or display_instance.is_boss_modifier:
		sell_buttton_panel.visible = false
	else:
		sell_buttton_panel.visible = true
		var sell_price = _calculate_sell_price()
		sell_button.text = "Sell %d" % sell_price

func _calculate_sell_price() -> int:
	return max(1, display_data.price / 2) if "price" in display_data else 5

func _on_sell_button_pressed() -> void:
	emit_signal("sell_requested", self)

# ---------------------------------------------
# XỬ LÝ CHUỘT VÀ KÉO THẢ (Giữ nguyên logic chuẩn)
# ---------------------------------------------
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
	# Tính năng ghim bảng nếu click chuột
	if is_clicked and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = get_global_mouse_position()
			var card_rect = get_global_rect()
			var tooltip_rect = detail_tooltip.get_global_rect()
			
			if not card_rect.has_point(mouse_pos) and not tooltip_rect.has_point(mouse_pos):
				is_clicked = false 
				_update_state()

func _update_state() -> void:
	var target_scale = Vector2(1.0, 1.0)
	
	if is_clicked or is_hovered:
		detail_tooltip.visible = true
		z_index = 10
		target_scale = Vector2(1.15, 1.15) 
	else:
		detail_tooltip.visible = false
		z_index = 0
		target_scale = Vector2(1.0, 1.0) 
	
	var tween = create_tween()
	tween.tween_property(icon_sprite, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_state()

# Các hàm kéo thả vị trí vật phẩm
func _get_drag_data(at_position: Vector2) -> Variant:
	if display_instance == null or display_instance.is_boss_modifier:
		return null
		
	is_clicked = false
	is_hovered = false
	_update_state()
	
	var preview = TextureRect.new()
	preview.texture = icon_sprite.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.custom_minimum_size = size
	
	var control = Control.new()
	control.add_child(preview)
	preview.position = -size / 2
	set_drag_preview(control)
	
	return self

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is ItemCard and display_instance != null and not display_instance.is_boss_modifier

func _drop_data(at_position: Vector2, dragged_card: Variant) -> void:
	var target_index = self.get_index()
	get_parent().move_child(dragged_card, target_index)
	
	var gm_dragged_idx = GameManager.active_items.find(dragged_card.display_instance)
	var gm_target_idx = GameManager.active_items.find(self.display_instance)
	
	if gm_dragged_idx != -1 and gm_target_idx != -1:
		var item = GameManager.active_items.pop_at(gm_dragged_idx)
		GameManager.active_items.insert(gm_target_idx, item)

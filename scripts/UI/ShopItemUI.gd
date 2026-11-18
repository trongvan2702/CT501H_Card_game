class_name ShopItemUI
extends VBoxContainer

signal buy_requested(product_data: Dictionary)

@onready var visual_anchor = $VisualAnchor
@onready var item_icon = $VisualAnchor/ItemIcon
@onready var detail_tooltip = $VisualAnchor/DetailTooltip

@onready var item_name_label = $VisualAnchor/DetailTooltip/Margin/VBox/ItemName/Margin/Label
@onready var item_desc_label = $VisualAnchor/DetailTooltip/Margin/VBox/ItemDescription/Margin/ItemDesc
@onready var item_rarity_label = $VisualAnchor/DetailTooltip/Margin/VBox/ItemRarity/Margin/ItemDesc
@onready var sell_button_panel = $VisualAnchor/DetailTooltip/Margin/VBox/SellButton # Ẩn đi vì đây là Shop

@onready var price_label = $PanelContainer/MarginContainer/Label
@onready var price_panel = $PanelContainer


var current_product: Dictionary = {}
var is_sold_out: bool = false
var is_hovered: bool = false

const RARITY_NAMES := {
	1: "COMMON", 2: "UNCOMMON", 3: "RARE", 4: "EPIC", 5: "LEGENDARY"
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

func _ready() -> void:
	detail_tooltip.visible = false
	sell_button_panel.visible = false
	
	visual_anchor.pivot_offset = visual_anchor.size / 2.0
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(product_data: Dictionary) -> void:
	current_product = product_data
	is_sold_out = product_data.get("is_sold_out", false)
	
	if product_data.has("icon"):
		item_icon.texture = product_data["icon"]
	price_label.text = "%d$" % product_data.get("price", 0)
	
	# Cập nhật Tooltip
	item_name_label.text = product_data.get("name", "Unknown Item")
	item_desc_label.text = product_data.get("desc", "")
	
	# Xử lý hiển thị Rarity (chỉ hiện cho Item/Pack, ẩn cho Service như Reroll/Remove)
	if product_data.has("rarity"):
		item_rarity_label.get_parent().get_parent().visible = true
		_update_rarity_style(product_data["rarity"])
	else:
		item_rarity_label.get_parent().get_parent().visible = false
	
	_update_availability_visuals()

func _update_rarity_style(rarity_lvl: int) -> void:
	rarity_lvl = clampi(rarity_lvl, 1, 5)
	item_rarity_label.text = RARITY_NAMES.get(rarity_lvl, "COMMON")
	item_rarity_label.add_theme_color_override("font_color", RARITY_COLORS.get(rarity_lvl, Color.WHITE))
	
	var style = StyleBoxFlat.new()
	style.bg_color = RARITY_BG_COLORS.get(rarity_lvl, Color(0.2, 0.2, 0.2))
	style.set_corner_radius_all(4)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.content_margin_left = 5
	style.content_margin_right = 5
	item_rarity_label.add_theme_stylebox_override("normal", style)


func _update_availability_visuals() -> void:
	if is_sold_out:
		modulate = Color(1, 1, 1, 0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
		
	var price = current_product.get("price", 0)
	var can_afford = GameManager.currency >= price
	
	# Nếu là thẻ dịch vụ (Remove) và đã dùng rồi -> Làm mờ
	var is_service_used = current_product.get("type") == "remove" and ShopManager.has_used_remove_service
	
	# Mờ đi nếu thiếu tiền HOẶC dịch vụ đã bị dùng
	if not can_afford or is_service_used:
		modulate = Color(0.4, 0.4, 0.4, 1.0) # Màu xám xịt
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		modulate = Color(1, 1, 1, 1.0)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# ==========================================
# TƯƠNG TÁC CHUỘT
# ==========================================
func _gui_input(event: InputEvent) -> void:
	if is_sold_out: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		
		var price = current_product.get("price", 0)
		var p_type = current_product.get("type", "")
		
		if GameManager.currency < price:
			print("Không đủ tiền mua!")
			_play_shake_animation()
			return
			
		
		if p_type == "remove" and ShopManager.has_used_remove_service:
			print("Đã gỡ bài ở shop này rồi!")
			_play_shake_animation()
			return
			
		if p_type == "item" and GameManager.active_items.size() >= GameManager.max_active_items:
			print("Kệ đồ cá nhân đã đầy!")
			_play_shake_animation()
			return
		
		emit_signal("buy_requested", self)

func _on_mouse_entered() -> void:
	if is_sold_out: return
	is_hovered = true
	_update_hover_state()

func _on_mouse_exited() -> void:
	if is_sold_out: return
	is_hovered = false
	_update_hover_state()

func _update_hover_state() -> void:
	var target_scale = Vector2(1.0, 1.0)
	
	if is_hovered:
		detail_tooltip.visible = true
		z_index = 10
		target_scale = Vector2(1.1, 1.1)
	else:
		detail_tooltip.visible = false
		z_index = 0
		target_scale = Vector2(1.0, 1.0)
		
	var tween = create_tween()
	tween.tween_property(visual_anchor, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)

# ==========================================
# HIỆU ỨNG
# ==========================================
func play_sold_animation() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_tooltip.visible = false
	price_panel.visible = false
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_anchor, "scale", Vector2(0, 0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	
	tween.chain().tween_callback(func():
		is_sold_out = true
	)

func _play_shake_animation() -> void:
	var tween = create_tween()
	tween.tween_property(visual_anchor, "position:x", 5.0, 0.05)
	tween.tween_property(visual_anchor, "position:x", -5.0, 0.05)
	tween.tween_property(visual_anchor, "position:x", 0.0, 0.05)

class_name ViewDeckButton
extends Control

signal deck_opened()

# Khai báo các Node dựa theo đúng cây thư mục của bạn
@onready var _vbox: VBoxContainer = $ViewDeckButton/VBoxContainer
@onready var _card_back: TextureRect = $ViewDeckButton/VBoxContainer/CardBack
@onready var _remain_label: Label = $ViewDeckButton/VBoxContainer/CardBack/CountBadge/Margin/HBoxContainer/RemainCardLabel
@onready var _total_label: Label = $ViewDeckButton/VBoxContainer/CardBack/CountBadge/Margin/HBoxContainer/TotalCardLabel
@onready var _click_area: Button = $ClickArea

var is_hovered: bool = false

func _ready() -> void:
	_vbox.pivot_offset = _vbox.size / 2.0
	
	_click_area.mouse_entered.connect(_on_mouse_entered)
	_click_area.mouse_exited.connect(_on_mouse_exited)
	_click_area.pressed.connect(_on_click_area_pressed)
	
	

# ==========================================
# CẬP NHẬT DỮ LIỆU HIỂN THỊ
# ==========================================

func update_counts(total: int, remain: int = -1) -> void:
	_total_label.text = str(total)
	
	if remain >= 0:
		_remain_label.visible = true
		_remain_label.text = str(remain) + " / "
	else:
		# Chế độ Shop (Ví dụ: "35")
		_remain_label.visible = false

# ==========================================
# HIỆU ỨNG THỊ GIÁC (HOVER & GLOW)
# ==========================================
func _update_visual_state() -> void:
	var target_scale := Vector2(1.0, 1.0)
	var target_y_offset := 0.0
	var target_modulate := Color(1.0, 1.0, 1.0) # Màu gốc
	
	if is_hovered:
		target_scale = Vector2(1.05, 1.05)
		target_y_offset = -5.0
		# Tăng giá trị RGB vượt mức 1.0 để tạo hiệu ứng sáng lên (Glow) cho lá bài
		target_modulate = Color(1.2, 1.2, 1.2) 
		z_index = 5
	else:
		target_scale = Vector2(1.0, 1.0)
		target_y_offset = 0.0
		target_modulate = Color(1.0, 1.0, 1.0)
		z_index = 0
		
	var tween := create_tween()
	tween.set_parallel(true)
	
	# Phóng to và nảy toàn bộ cụm thẻ + chữ
	tween.tween_property(_vbox, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_vbox, "position:y", target_y_offset, 0.15).set_trans(Tween.TRANS_SINE)
	
	# Chỉ làm sáng riêng mặt lưng lá bài
	tween.tween_property(_card_back, "modulate", target_modulate, 0.15).set_trans(Tween.TRANS_SINE)

# ==========================================
# LẮNG NGHE SỰ KIỆN TỪ CLICK AREA
# ==========================================
func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()

func _on_click_area_pressed() -> void:
	# Bạn có thể thêm Tween thu nhỏ nhẹ ở đây để tạo cảm giác bấm nút nếu muốn
	emit_signal("deck_opened")

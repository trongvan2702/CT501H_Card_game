class_name ActionButton
extends MarginContainer

signal action_pressed()

enum ActionType { PLAY, DISCARD, CONTINUE, MAIN_PLAY, SETTINGS, EXIT, NEW_RUN, MAIN_MENU}

# Cho phép bạn chọn loại nút ngay ngoài bảng Inspector của Godot
@export var action_type: ActionType = ActionType.PLAY

# Khai báo các Node dựa theo đúng cây thư mục của bạn
@onready var bg_panel: PanelContainer = $Background
@onready var title_label: Label = $Background/VBoxContainer/ActionTitle
@onready var sub_label: Label = $Background/VBoxContainer/SubText
@onready var click_area: Button = $Button 

# Định nghĩa màu sắc (Bạn có thể tùy chỉnh lại mã màu RGB cho ưng ý)
const COLOR_DISABLED = Color(0.274, 0.274, 0.274) # Xám tối
const COLOR_CONTINUE = Color(0.94, 0.63, 0.24)
const COLOR_SETTINGS = Color(0.94, 0.63, 0.24)
const COLOR_EXIT = Color(0.94, 0.63, 0.24)
const COLOR_PLAY = Color(0.94, 0.63, 0.24)
const COLOR_MAIN_PLAY = Color(0.94, 0.63, 0.24)
const COLOR_DISCARD = Palette.SURFACE  

const TEXT_COLOR_ACTIVE = Color(1.0, 1.0, 1.0) 
const TEXT_COLOR_DISABLED = Color(0.5, 0.5, 0.5)

var is_active: bool = false
var is_hovered: bool = false

func _ready() -> void:
	pivot_offset = custom_minimum_size / 2.0
	
	match action_type:
		ActionType.PLAY:
			title_label.text = "SERVE"
			sub_label.visible = true
		ActionType.DISCARD:
			title_label.text = "DISCARD"
		ActionType.CONTINUE:
			title_label.text = "CONTINUE"
			sub_label.visible = false
		ActionType.MAIN_PLAY:
			title_label.text = "PLAY"
			sub_label.visible = false
		ActionType.SETTINGS:
			title_label.text = "SETTINGS"
			sub_label.visible = false
		ActionType.EXIT:
			title_label.text = "EXIT"
			sub_label.visible = false
		ActionType.NEW_RUN:
			title_label.text = "NEW RUN"
			sub_label.visible = false
		ActionType.MAIN_MENU:
			title_label.text = "MAIN MENU"
			sub_label.visible = false
	
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	click_area.pressed.connect(_on_pressed)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 5
	style.shadow_offset = Vector2(1.0, 2.0)
	bg_panel.add_theme_stylebox_override("panel", style)
	
	update_state(0, 0)

# Hàm này sẽ được MatchManager gọi liên tục mỗi khi tay bài thay đổi
func update_state(selected_count: int, actions_left: int) -> void:
	var style = bg_panel.get_theme_stylebox("panel") as StyleBoxFlat
	
	match action_type:
		ActionType.PLAY:
			sub_label.text = "%d / 5 Ingredients" % selected_count
			is_active = (selected_count > 0 and actions_left > 0)
			style.bg_color = COLOR_PLAY if is_active else COLOR_DISABLED
			
		ActionType.DISCARD:
			sub_label.visible = false
			is_active = (selected_count > 0 and selected_count <= 5 and actions_left > 0)
			style.bg_color = COLOR_DISCARD if is_active else COLOR_DISABLED
			
		ActionType.CONTINUE:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_CONTINUE
			
		ActionType.MAIN_PLAY:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_MAIN_PLAY
			
		ActionType.SETTINGS:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_SETTINGS
			
		ActionType.EXIT:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_EXIT
		
		ActionType.NEW_RUN:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_MAIN_PLAY
			
		ActionType.MAIN_MENU:
			sub_label.visible = false
			is_active = true
			style.bg_color = COLOR_MAIN_PLAY
		
	var current_text_color = TEXT_COLOR_ACTIVE if is_active else TEXT_COLOR_DISABLED
	title_label.add_theme_color_override("font_color", current_text_color)
	sub_label.add_theme_color_override("font_color", current_text_color)
	
	click_area.disabled = not is_active
	
	if not is_active and is_hovered:
		is_hovered = false
		_update_visual_state()

# Hiệu ứng phóng to và sáng nền (Glow)
func _update_visual_state() -> void:
	var target_scale := Vector2(1.0, 1.0)
	var target_modulate := Color(1.0, 1.0, 1.0)
	
	if is_hovered and is_active:
		target_scale = Vector2(1.05, 1.05)
		target_modulate = Color(1.2, 1.2, 1.2)
		z_index = 5
	else:
		target_scale = Vector2(1.0, 1.0)
		target_modulate = Color(1.0, 1.0, 1.0)
		z_index = 0
		
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bg_panel, "modulate", target_modulate, 0.1).set_trans(Tween.TRANS_SINE)

func _on_mouse_entered() -> void:
	if is_active:
		is_hovered = true
		_update_visual_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()

func _on_pressed() -> void:
	AudioManager.play_button_click()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", (Vector2(1.05, 1.05) if is_hovered else Vector2(1.0, 1.0)), 0.05).set_delay(0.05)
	
	action_pressed.emit()

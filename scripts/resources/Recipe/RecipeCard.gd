class_name RecipeCard
extends Control

signal card_clicked(card: RecipeCard)
signal card_hoverd(card: RecipeCard)
signal card_unhovered(card: RecipeCard)

const CARD_SCENE = preload("res://scenes/RecipeCard.tscn")

const RARITY_NAMES := {
	1: "COMMON",
	2: "UNCOMMON",
	3: "RARE",
	4: "LEGENDARY",
}

const RARITY_COLORS := {
	1: Color(0.78, 0.74, 0.66),
	2: Color(0.47, 0.85, 0.47),
	3: Color(0.45, 0.70, 1.0),
	4: Color(1.0, 0.78, 0.32),
}

const RARITY_BG_COLORS := {
	1: Color(0.18, 0.18, 0.19), 
	2: Color(0.12, 0.24, 0.16), 
	3: Color(0.15, 0.20, 0.35), 
	4: Color(0.28, 0.12, 0.12), 
}

@export var card_size: Vector2 = Vector2(220, 320)

var recipe_data: RecipeData = null
var is_hovered: bool = false

@onready var _card_bg: Panel = $CardPanel
@onready var _rarity_label: Label = $CardPanel/Margin/Body/Header/RarityLabel
@onready var _badge_panel: PanelContainer = $CardPanel/Margin/Body/Header/Badge
@onready var _badge_label: Label = $CardPanel/Margin/Body/Header/Badge/BadgeLabel
@onready var _icon_sprite: TextureRect = $CardPanel/Margin/Body/Icon
@onready var _name_label: Label = $CardPanel/Margin/Body/NameLabel
@onready var _ingredients_box: HBoxContainer = $CardPanel/Margin/Body/Ingredients
@onready var _score_label: Label = $CardPanel/Margin/Body/Chips/ScoreChip/ScoreLabel
@onready var _mult_label: Label = $CardPanel/Margin/Body/Chips/MultChip/MultLabel

# Static function

static func create_from_data(data: RecipeData) -> RecipeCard:
	var card = CARD_SCENE.instantiate() as RecipeCard
	card.recipe_data = data

	return card

# Node

func _ready() -> void:
	custom_minimum_size = card_size
	size = card_size
	_update_display()


# Display function

func _update_display() -> void:
	if recipe_data == null:
		return

	_name_label.text = recipe_data.recipe_name
	_icon_sprite.texture = recipe_data.icon_texture

	var rarity: int = clampi(recipe_data.rarity, 1, 4)
	_rarity_label.text = RARITY_NAMES[rarity]
	_rarity_label.add_theme_color_override("font_color", RARITY_COLORS[rarity])
	
	var new_style = _card_bg.get_theme_stylebox("panel").duplicate()
	new_style.bg_color = RARITY_BG_COLORS[rarity]
	_card_bg.add_theme_stylebox_override("panel", new_style)
	
	_update_badge()
	_update_ingredients()
	_update_chips()
	_update_tooltip()


# Badge: mới mở khóa -> NEW, đã có sẵn -> LV n
func _update_badge() -> void:
	var info: Dictionary = RecipeDB.recipes.get(recipe_data.recipe_id, {})
	var is_unlocked: bool = info.get("unlocked", recipe_data.default_unlocked)
	var level: int = info.get("level", 1)

	if is_unlocked:
		# Tìm cách để dấu mũi tên đi lên để biểu hiện cho người chơi hiểu rằng có thể nâng cấp
		_badge_label.text = "↑ LV %d" % [level + 1]
		_set_badge_color(Color(0.72, 0.16, 0.20))
	else:
		_badge_label.text = "NEW"
		_set_badge_color(Color(0.13, 0.50, 0.26))


func _set_badge_color(bg_color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(3)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	_badge_panel.add_theme_stylebox_override("panel", style)


# Hàng icon nguyên liệu cần để nấu món
func _update_ingredients() -> void:
	for child in _ingredients_box.get_children():
		_ingredients_box.remove_child(child)
		child.queue_free()

	for ing in recipe_data.required_ingredients:
		# Ô vuông nền tối ôm icon nguyên liệu
		var slot := PanelContainer.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_theme_stylebox_override("panel", _make_icon_slot_style())

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ing.icon_texture
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

		slot.add_child(icon)
		_ingredients_box.add_child(slot)


func _make_icon_slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0784314, 0.0666667, 0.0784314, 0.9)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.352941, 0.313726, 0.290196, 0.6)
	style.set_corner_radius_all(3)
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style


# Chip điểm / chip hệ số
func _update_chips() -> void:
	# Chips = điểm công thức (đã tính cấp) + tổng điểm nguyên liệu cần dùng
	var score: float = RecipeDB.calculate_score(recipe_data)
	var info: Dictionary = RecipeDB.recipes.get(recipe_data.recipe_id, {})
	var is_unlocked: bool = info.get("unlocked", recipe_data.default_unlocked)
	if is_unlocked:
		score += recipe_data.bonus_score_per_level
	#for ing in recipe_data.required_ingredients:
		#score += ing.base_score

	# Hệ số hiển thị = 1.0 + mult của món (khớp công thức "Giá trị món" trong BALANCE.md)
	var mult: float = 1.0 + RecipeDB.calculate_mult(recipe_data)
	if is_unlocked:
		mult += recipe_data.bonus_mult_per_level
	
	_score_label.text = "+%.2f CAL" % score
	_mult_label.text = "×%.2f" % mult


# Hover để xem chi tiết món
func _update_tooltip() -> void:
	var ingredient_names: Array[String] = []
	for ing in recipe_data.required_ingredients:
		ingredient_names.append(ing.display_name)

	var info: Dictionary = RecipeDB.recipes.get(recipe_data.recipe_id, {})
	var is_unlocked: bool = info.get("unlocked", recipe_data.default_unlocked)
	var level: int = info.get("level", 1)
	var status_text: String = ("Unlock (LV %d)" % level) if is_unlocked else "Lock"

	var lines: Array[String] = []
	lines.append(recipe_data.recipe_name)
	if not recipe_data.description.is_empty():
		lines.append(recipe_data.description)
	lines.append("Ingredients: " + ", ".join(ingredient_names))
	lines.append("Status: " + status_text)
	lines.append("Point: " + _score_label.text + "    Mult: " + _mult_label.text)

	tooltip_text = "\n".join(lines)


func _update_visual_state() -> void:
	var target_scale := Vector2(1.0, 1.0)
	var target_y_offset := 0.0

	if is_hovered:
		target_scale = Vector2(1.05, 1.05)
		target_y_offset = -5
		z_index = 5
	else:
		target_scale = Vector2(1.0, 1.0)
		target_y_offset = 0
		z_index = 0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", target_y_offset, 0.15).set_trans(Tween.TRANS_SINE)


func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual_state()
	emit_signal("card_hoverd", self)


func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()
	emit_signal("card_unhovered", self)


func _on_card_clicked() -> void:
	emit_signal("card_clicked", self)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			accept_event()
			_on_card_clicked()

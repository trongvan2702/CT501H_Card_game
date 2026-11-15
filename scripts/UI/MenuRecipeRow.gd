class_name MenuRecipeRow
extends PanelContainer

@onready var recipe_icon = $Margin/RowHBox/RecipeIcon
@onready var recipe_name = $Margin/RowHBox/InfoVBox/RecipeName
@onready var ingredients_box = $Margin/RowHBox/InfoVBox/IngredientsBox
@onready var score_label = $Margin/RowHBox/StatsVBox/ScoreLabel
@onready var mult_label = $Margin/RowHBox/StatsVBox/MultLabel

var recipe_data: RecipeData = null
var ingredient_nodes: Array = [] # Mảng lưu các icon nguyên liệu để lát nữa Highlight

func _ready() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0) # Alpha = 0
	style.border_width_bottom = 1
	style.border_color = Color(47/255, 41/255, 26/255)
	style.set_corner_radius_all(4)
	add_theme_stylebox_override("panel", style)

# ==========================================
# 1. HÀM THIẾT LẬP DỮ LIỆU BAN ĐẦU
# ==========================================
func setup(data: RecipeData, score: float, mult: float) -> void:
	recipe_data = data
	recipe_name.text = data.recipe_name
	recipe_icon.texture = data.icon_texture
	score_label.text = "+%d" % round(score)
	mult_label.text = "x%.1f" % mult
	
	# Xóa rác cũ nếu có
	for child in ingredients_box.get_children():
		child.queue_free()
	ingredient_nodes.clear()
	
	# Sinh ra các icon nguyên liệu dựa trên công thức
	for ing in data.required_ingredients:
		var tex = TextureRect.new()
		tex.texture = ing.icon_texture
		tex.custom_minimum_size = Vector2(32, 32)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Mặc định lúc mới tạo: Màu tối (chưa được chọn)
		tex.modulate = Color(0.6, 0.6, 0.6, 0.8) 
		
		ingredients_box.add_child(tex)
		
		# Lưu lại ID và cái khung Hình ảnh để lát nữa đổi màu
		ingredient_nodes.append({
			"id": ing.ingredient_id,
			"node": tex
		})

# ==========================================
# 2. HÀM ĐỔI MÀU (HIGHLIGHT) THEO LỆNH TỪ BỘ GIẢ LẬP
# ==========================================
func update_highlight(is_cooked: bool, selected_ids: Array) -> void:
	var temp_selected = selected_ids.duplicate()
	
	# A. Vẫn đổi màu icon nguyên liệu nhỏ 
	# (Để người chơi biết họ đang nắm trên tay nguyên liệu nào của món này)
	for item in ingredient_nodes:
		var req_id = item["id"]
		var icon_node = item["node"] as TextureRect
		
		var found_idx = temp_selected.find(req_id)
		if found_idx != -1:
			icon_node.modulate = Color(1.0, 1.0, 1.0, 1.0)
			temp_selected.remove_at(found_idx)
		else:
			icon_node.modulate = Color(0.6, 0.6, 0.6, 0.8) # Xám mờ
			
	# B. Đổi màu Cả Hàng Công Thức dựa vào kết quả giả lập
	var style = get_theme_stylebox("panel") as StyleBoxFlat
	
	if is_cooked:
		# SẼ ĐƯỢC NẤU: Highlight xanh lá
		style.bg_color = Color(0.15, 0.4, 0.2, 0.8) 
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		# KHÔNG ĐƯỢC NẤU
		style.bg_color = Color(0, 0, 0, 0)

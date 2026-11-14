class_name ActiveMenuUI
extends PanelContainer

const MENU_ROW_SCENE = preload("res://scenes/MenuRecipeRow.tscn")

# BẠN HÃY KÉO THẢ CÁC NODE CỦA BẠN VÀO ĐÂY ĐỂ THAY THẾ 3 DÒNG NÀY:
@onready var scroll_container = $Margin/MainVBox/ScrollContainer
@onready var recipe_list = $Margin/MainVBox/ScrollContainer/VBoxContainer
@onready var count_label = $Margin/MainVBox/HeaderBox/RecipeCount

func _ready() -> void:
	# Xóa sạch các món ăn mẫu (nếu bạn có tạo thử trong chế độ thiết kế)
	for child in recipe_list.get_children():
		child.queue_free()

# ==========================================
# 1. HÀM VẼ GIAO DIỆN MỖI KHI BẮT ĐẦU MÀN
# ==========================================
func refresh_menu() -> void:
	# Dọn dẹp danh sách cũ
	for child in recipe_list.get_children():
		child.queue_free()
		 
	var active_recipes = RecipeDB.get_active_menu_recipes()
	count_label.text = "%d RECIPES" % active_recipes.size()
	
	for item in active_recipes:
		var recipe_data = item["data"] as RecipeData
		var score = RecipeDB.get_recipe_score(recipe_data)
		var mult = RecipeDB.get_recipe_mult(recipe_data)
		
		# Đúc ra 1 dòng món ăn và gắn dữ liệu
		var row = MENU_ROW_SCENE.instantiate() as MenuRecipeRow
		recipe_list.add_child(row)
		row.setup(recipe_data, score, mult)

	# Chờ Godot vẽ xong 1 frame rồi mới tính toán chiều cao thông minh
	await get_tree().process_frame 
	_update_scroll_size()
	
	# Mặc định lúc mới tạo ra, không có bài nào được chọn
	_on_cards_selection_changed([])

# ==========================================
# 2. HÀM TÍNH TOÁN CHIỀU CAO THÔNG MINH (TỐI ĐA 6 MÓN)
# ==========================================
func _update_scroll_size() -> void:
	var max_visible_items = 6
	var current_items = recipe_list.get_child_count()
	
	if current_items == 0:
		scroll_container.custom_minimum_size.y = 0
		return
		
	# Lấy chiều cao thực tế của 1 dòng món ăn (thường khoảng 60-80px)
	var single_row_height = recipe_list.get_child(0).size.y
	# Lấy khoảng cách giữa các món ăn
	var spacing = recipe_list.get_theme_constant("separation") 
	if spacing < 0: spacing = 4 # Fallback nếu bạn chưa thiết lập
	
	if current_items <= max_visible_items:
		# Thu nhỏ khít ôm sát vào nội dung
		scroll_container.custom_minimum_size.y = 0
	else:
		# Khóa cứng chiều cao đúng bằng 6 món, bắt đầu hiện thanh cuộn
		var max_height = (single_row_height * max_visible_items) + (spacing * (max_visible_items - 1))
		scroll_container.custom_minimum_size.y = max_height

# ==========================================
# 3. LẮNG NGHE VÀ GIẢ LẬP KẾT QUẢ TỪ BÀI ĐANG CHỌN
# ==========================================
func _on_cards_selection_changed(selected_cards: Array) -> void:
	var selected_instances: Array[IngredientInstance] = []
	var selected_ids: Array[String] = []
	
	for card in selected_cards:
		if card.ingredient_instance and card.ingredient_instance.ingredient_data:
			selected_instances.append(card.ingredient_instance)
			selected_ids.append(card.ingredient_instance.ingredient_data.ingredient_id)
			
	# Chạy bộ giả lập hệ thống chấm điểm để lấy danh sách ID các món ăn SẼ ĐƯỢC NẤU
	var cooked_recipe_ids = _simulate_scoring_system(selected_instances)
	
	# Báo cáo kết quả xuống cho từng hàng
	for row in recipe_list.get_children():
		if row is MenuRecipeRow:
			var is_will_be_cooked = cooked_recipe_ids.has(row.recipe_data.recipe_id)
			row.update_highlight(is_will_be_cooked, selected_ids)

# Copy y hệt thuật toán _create_dishes_from_ingredients trong ScoringSystem
func _simulate_scoring_system(ingredients: Array[IngredientInstance]) -> Array[String]:
	var will_cook_ids: Array[String] = []
	var remaining = ingredients.duplicate()
	
	
	var visible_recipes = RecipeDB.get_unlock_recipe()
	visible_recipes.sort_custom(func(a, b):
		if a["crafted_count"] != b["crafted_count"]:
			return a["crafted_count"] > b["crafted_count"]
		return RecipeDB.calculate_mult(b["data"]) > RecipeDB.calculate_mult(a["data"])
	)
	
	var max_iterations = remaining.size() * 2
	for i in range(max_iterations):
		if remaining.is_empty(): 
			break
			
		var best_match_id = ""
		var best_score = 0.0
		var best_used_ingredients = []
		
		# Tìm món có điểm cao nhất khớp với số nguyên liệu đang có
		for recipe in visible_recipes:
			var recipe_data = recipe["data"] as RecipeData
			var available_copy = remaining.duplicate()
			var matched_instances = []
			
			for req in recipe_data.required_ingredients:
				var req_id = req.ingredient_id
				var found_idx = -1
				for j in range(available_copy.size()):
					if available_copy[j].ingredient_data.ingredient_id == req_id:
						found_idx = j
						break
				
				if found_idx != -1:
					matched_instances.append(available_copy[found_idx])
					available_copy.remove_at(found_idx)
				else:
					matched_instances = []
					break # Thiếu nguyên liệu -> Bỏ qua món này
					
			if matched_instances.size() > 0:
				var potential_score = RecipeDB.calculate_score(recipe_data) * (1.0 + RecipeDB.calculate_mult(recipe_data))
				if best_match_id == "" or potential_score > best_score:
					best_score = potential_score
					best_match_id = recipe_data.recipe_id
					best_used_ingredients = matched_instances
		
		if best_match_id == "":
			break # Không ghép được món nào nữa
			
		will_cook_ids.append(best_match_id)
		
		for ing in best_used_ingredients:
			remaining.erase(ing)
			
	return will_cook_ids

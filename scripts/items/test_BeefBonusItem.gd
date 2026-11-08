extends ItemInstance
class_name BeefBonusItem

func _init(i_data: ItemData = null) -> void:
	super(i_data)
	# Khởi tạo mức điểm cộng thêm ban đầu là 0 nếu chưa có
	if not has_state("bonus_score"):
		set_state("bonus_score", 0.0)

# Bước 1: Nghe ngóng lúc nguyên liệu được tính điểm để "Tích tụ"
func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	if ingredient.ingredient_data.ingredient_id == "beef":
		var current_bonus = get_state("bonus_score", 0.0)
		# Tăng vĩnh viễn 5 điểm vào bộ nhớ state
		set_state("bonus_score", current_bonus + 5.0)
		
		# (Tùy chọn) Trả về trigger rỗng hoặc một dòng chữ nhỏ báo hiệu Item vừa mạnh lên
		var result = TriggerResult.new(0.0, 0.0, "Vừa tích thêm 5 điểm!")
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

# Bước 2: Kích hoạt khi nấu xong công thức để "Xả" điểm
func on_recipe_scored(recipe: RecipeData) -> TriggerResult:
	var current_bonus = get_state("bonus_score", 0.0)
	
	if current_bonus > 0:
		# Cộng điểm cho món ăn bằng đúng số điểm đang tích lũy
		var result = TriggerResult.new(current_bonus, 0.0, "Cộng dồn thịt bò: +" + str(current_bonus))
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

func get_dynamic_description() -> String:
	# 1. Gọi super để lấy đoạn mô tả gốc từ ItemInstance
	var base_text = super.get_dynamic_description()
	
	# 2. Xử lý logic động của riêng thẻ này
	var current_bonus = get_state("bonus_score", 0.0)
	if current_bonus > 0:
		base_text += "\n\n[Đang cộng thêm: +" + str(current_bonus) + " Điểm]"
		
	return base_text

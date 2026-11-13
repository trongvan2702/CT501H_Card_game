extends Node

var recipes: Dictionary = {}

func _ready() -> void:
	_load_recipe()
	

func _load_recipe() -> void:
	var path = "res://resources/recipes/"
	var dir = DirAccess.open(path)
	
	if dir == null:
		print("Cannot found RecipeData")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = path + file_name
			var recipe = load(full_path)
			
			if recipe is RecipeData:
				recipes[recipe.recipe_id] = {
					"data": recipe,
					"level": 1,
					"unlocked": recipe.default_unlocked,
					"crafted_count": 0 # Số lần nấu trong run hiện tại
				}
		file_name = dir.get_next()

func unlock_recipe(recipe: RecipeData) -> void:
	var id = recipe.recipe_id
	
	if recipes.has(id):
		recipes[id]["unlocked"] = true

func upgrade_recipe(recipe: RecipeData) -> void:
	var id = recipe.recipe_id
	
	if recipes.has(id):
		recipes[id]["level"] += 1

func get_recipe_level(id: String) -> int:
	return recipes.get(id, {"level": 1})["level"]

# Ghi nhận 1 lần nấu thành công với recipe (dùng cho UI thống kê)
func record_craft(recipe_id: String) -> void:
	if not recipes.has(recipe_id):
		return
	recipes[recipe_id]["crafted_count"] = get_crafted_count(recipe_id) + 1

func get_crafted_count(id: String) -> int:
	return recipes.get(id, {"crafted_count": 0})["crafted_count"]

# Reset số lần nấu khi bắt đầu run mới
func reset_crafted_counts() -> void:
	for recipe_id in recipes:
		recipes[recipe_id]["crafted_count"] = 0

# Danh sách recipe đã mở khóa, sắp xếp theo số lần nấu giảm dần
# Trả về mảng các dict {"data": RecipeData, "crafted_count": int}
func get_crafted_recipes_sorted() -> Array:
	var result: Array = []
	for recipe in get_unlock_recipe():
		result.append({
			"data": recipe["data"],
			"crafted_count": get_crafted_count(recipe["data"].recipe_id)
		})
	result.sort_custom(func(a, b):
		return a["crafted_count"] > b["crafted_count"]
	)
	return result

func get_unlock_recipe() -> Array:
	var result: Array = []
	for recipe in recipes.values():
		if recipe["unlocked"] == true:
			result.append(recipe)
	return result

func calculate_score(recipe: RecipeData) -> float:
	var current_level = get_recipe_level(recipe.recipe_id)
	return recipe.base_score + ((current_level - 1) * recipe.bonus_score_per_level)

func calculate_mult(recipe: RecipeData) -> float:
	var current_level = get_recipe_level(recipe.recipe_id)
	return recipe.base_mult + ((current_level - 1) * recipe.bonus_mult_per_level)

func get_random_recipes(count: int) -> Array[RecipeData]:
	var result: Array[RecipeData] = []
	
	var all_keys = recipes.keys()
	
	if all_keys.size() <= count:
		for key in all_keys:
			result.append(recipes[key]["data"])
		return result
		
	all_keys.shuffle()
	
	for i in range(count):
		var random_key = all_keys[i]
		result.append(recipes[random_key]["data"])
		
	return result

func _debug_print() -> void:
	var lock_recipe = []
	var _unlock_recipe = []
	for recipe in recipes.values():
		if recipe["unlocked"] == false:
			lock_recipe.append(recipe["data"].recipe_name)
		else: 
			_unlock_recipe.append(recipe["data"].recipe_name)
	print("Lock recipe: ", lock_recipe)
	print("Unlock recipe: ", _unlock_recipe)

func get_info(recipe: RecipeData) -> String:
	return "%s %s" % [recipe.get_info(), RecipeDB.get_recipe_level(recipe.recipe_id)]

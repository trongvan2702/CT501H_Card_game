extends Node

var ingredients: Dictionary = {}

func _ready() -> void:
	_load_function()
	pass
	
func _load_function() -> void:
	var path = "res://resources/ingredients/"
	var dir = DirAccess.open(path)
	
	if dir == null:
		print("Cannot found IngredientData")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		
		if file_name.ends_with(".tres"):
			var full_path = path + file_name
			var ingredient = load(full_path)
		
			if ingredient is IngredientData:
				ingredients[ingredient.ingredient_id] = ingredient
		
		file_name = dir.get_next()

func get_ingredient_by_id(id: String) -> IngredientData:
	return ingredients.get(id, 1)

func get_all_ingredients_name() -> Array:
	var result = []
	for ingredient in ingredients.values():
		result.append(ingredient.get_info())
	return result

func get_all_ingredients() -> Array:
	return ingredients.values()

func create_ingredient_instance_by_id(id: String) -> IngredientInstance:
	var base_data = get_ingredient_by_id(id)
	if base_data == null:
		return IngredientInstance.new(load("res://resources/ingredients/test.tres"))
	var new_instance = IngredientInstance.new(base_data)
	return new_instance

func get_random_ingredients(count: int) -> Array[IngredientInstance]:
	var result: Array[IngredientInstance] = []
	
	var all_keys = ingredients.keys()
	
	if all_keys.size() <= count:
		for key in all_keys:
			result.append(ingredients[key])
			result.append(create_ingredient_instance_by_id(ingredients[key].ingredient_id))
		return result
		
	all_keys.shuffle()
	
	for i in range(count):
		var random_key = all_keys[i]
		result.append(create_ingredient_instance_by_id(ingredients[random_key].ingredient_id))
	
	return result

func get_info(ingredient: IngredientInstance) -> String:
	return ingredient.ingredient_data.display_name
	

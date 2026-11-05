extends Node
class_name ScoringSystem

var _current_played_cards: Array[IngredientInstance] = []
#var _current_pipeline: Array[TriggerResult] = []
var _accumulated_results: Array = []
var _meta_effects: Dictionary = {}
var equipped_items: Array[ItemInstance] = []

func _ready() -> void:	
	pass

func calculate_dish_score(ingredients: Array[IngredientInstance]) -> Dictionary:
	_reset_buffers()
	
	_current_played_cards = ingredients.duplicate()
	
	_trigger_on_play(ingredients)
	
	var dishes = _create_dishes_from_ingredients(ingredients)
	
	var sum = _calculate_total(dishes)
	
	var total_score = sum["total_final_score"]
	var meta_effects_result = sum["meta_effects"]
	
	var result = {
		"total_score" = total_score,
		"dishes" = dishes,
		"meta_effects" = meta_effects_result
	}
	
	return result

func _trigger_on_play(cards: Array[IngredientInstance]) -> void:
	for item in equipped_items:
		if item.has_method("on_play"):
			var result = item.on_play(cards)
	pass

func _trigger_on_ingredient_scored(ingredient: IngredientInstance, pipeline: Array[TriggerResult]) -> void:
	for item in equipped_items:
		if item.has_method("on_ingredient_scored"):
			var result = item.on_ingredient_scored(ingredient)
			if result != null and result.triggered:
				pipeline.append(result)

func _trigger_on_recipe_scored(recipe: RecipeData, pipeline: Array[TriggerResult]) -> void:
	for item in equipped_items:
		if item.has_method("on_recipe_scored"):
			var result = item.on_recipe_scored(recipe)
			if result != null and result.triggered:
				pipeline.append(result)

func _create_dishes_from_ingredients(ingredients: Array[IngredientInstance]) -> Array:
	var result: Array = []
	var remaining = ingredients.duplicate()
	
	var visible_recipes = RecipeDB.get_unlock_recipe() #Array[Dictionary]

	visible_recipes.sort_custom(func(a, b):
		return RecipeDB.calculate_mult(b["data"]) > RecipeDB.calculate_mult(a["data"])
	)
	
	var iterations = 0
	var max_iterations = remaining.size() * 2
	
	while not remaining.is_empty() and iterations < max_iterations:
		iterations += 1
		var best_match = _find_best_recipe_for_ingredients(remaining, visible_recipes)
		
		if best_match.is_empty():
			break
		
		var recipe = best_match.get("recipe")
		var used_ingredients = best_match.get("used_ingredients", [])
		
		if recipe == null or used_ingredients.is_empty():
			break
		
		var dish = _create_dish_from_recipe(recipe, used_ingredients)
		result.append(dish)

		for ing in used_ingredients:
			remaining.erase(ing)
	
	#if not remaining.is_empty():
		#var leftover = _create_dish_from_ingredients(remaining)
		#result.append(leftover)
	
	return result

func _find_best_recipe_for_ingredients(available: Array[IngredientInstance], recipes: Array) -> Dictionary:
	var best_match: Dictionary = {}
	var best_score = 0.0
	
	for recipe in recipes:
		var available_copy = available.duplicate()
		var matched_ingredients = _try_match_recipe(available_copy, recipe["data"])
		#print(matched_ingredients)
		if not matched_ingredients.is_empty():
			var potential_score = RecipeDB.calculate_score(recipe["data"]) * (1 + RecipeDB.calculate_mult(recipe["data"])) 
			if best_match.is_empty() or potential_score > best_score:
				best_score = potential_score
				best_match = {
					"recipe": recipe,
					"used_ingredients": _extract_ingredients_by_id(recipe["data"].required_ingredients, available)
				}
	return best_match

func _try_match_recipe(available: Array[IngredientInstance], recipe: RecipeData) -> Array:
	var required = recipe.required_ingredients.duplicate()
	#for ing in required:
		#print(ing.display_name)
		
	var matched_ingredient: Array = []
	
	var available_count: Dictionary = {}
	for ing in available:
		var id = ing.ingredient_data.ingredient_id
		if not available_count.has(id):
			available_count[id] = 1
		else: available_count[id] += 1
	
	for req_data in required:
		var req_id = req_data.ingredient_id
		if available_count.has(req_id) and available_count[req_id] > 0:
			matched_ingredient.append(req_id)
			available_count[req_id] -= 1
		else: return[]
	
	return matched_ingredient

func _extract_ingredients_by_id(required_ingredients: Array, available: Array[IngredientInstance]) -> Array[IngredientInstance]:
	var result: Array[IngredientInstance] = []
	var used_index: Array = []
	
	for req_data in required_ingredients:
		var req_id = req_data.ingredient_id
		for i in range(available.size()):
			if i not in used_index and available[i].ingredient_data.ingredient_id == req_id:
				result.append(available[i])
				used_index.append(i)
				break
	
	return result

func _create_dish_from_recipe(recipe: Dictionary, used_ingredients: Array[IngredientInstance]) -> Dictionary:
	var recipe_data: RecipeData = recipe["data"]
	
	var dish_pipeline: Array[TriggerResult] = []
	
	var score = RecipeDB.calculate_score(recipe["data"])
	var mult = RecipeDB.calculate_mult(recipe["data"])
	
	var recipe_trigger = TriggerResult.new(score, mult, recipe_data.recipe_name)
	recipe_trigger.is_from_recipe = true
	dish_pipeline.append(recipe_trigger)
	
	for ing in used_ingredients:
		var ing_trigger = TriggerResult.new(ing.get_score(), 0.0, ing.ingredient_data.display_name)
		dish_pipeline.append(ing_trigger)
		_trigger_on_ingredient_scored(ing, dish_pipeline)
	
	_trigger_on_recipe_scored(recipe_data, dish_pipeline)
	
	var result = {
		"recipe": recipe_data,
		"ingredients": used_ingredients,
		"pipeline": dish_pipeline
	}
	return result

func _calculate_total(dishes: Array) -> Dictionary:
	var total_final_score: float = 0.0
	
	for dish in dishes:
		var current_score: float = 0.0
		var current_mult: float = 1.0 
		
		var pipeline: Array[TriggerResult] = dish["pipeline"]
		
		for trigger in pipeline:
			if not trigger.triggered: 
				continue
			
			for effect_name in trigger.custom_effects:
				if not _meta_effects.has(effect_name):
					_meta_effects[effect_name] = 0
				
				_meta_effects[effect_name] += trigger.custom_effects[effect_name]
			
			current_score += trigger.score
			
			if trigger.x_mult:
				current_mult *= trigger.mult 
			else:
				current_mult += trigger.mult 
			
		var final_dish_score = current_score * current_mult
		dish["final_score"] = final_dish_score
		
		total_final_score += final_dish_score
		
	return {
		"total_final_score": total_final_score,
		"meta_effects": _meta_effects.duplicate()
	}

func _reset_buffers() -> void:
	_current_played_cards.clear()
	#_current_pipeline.clear()
	_accumulated_results.clear()
	_meta_effects = {}

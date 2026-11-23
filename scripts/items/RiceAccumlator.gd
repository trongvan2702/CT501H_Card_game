extends ItemInstance
class_name RiceAccumlatorItem

func on_play(ingredients: Array[IngredientInstance]) -> TriggerResult:
	var rice_count = 0
	for ingredient in ingredients:
		if ingredient.ingredient_data.display_name == "Rice":
			rice_count += 1
	var current_count = get_state("rice_count", 0)
	set_state("rice_count", current_count + rice_count)
	var result = TriggerResult.new(0.0, 0.0, "Bonus mult from rice")
	
	return result

func _on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	
	if get_state("rice_count", 0) > 2:
		result.mult = 8.8
		result.triggered = true
	
	set_state("rice_count", 0)
	
	return result
	

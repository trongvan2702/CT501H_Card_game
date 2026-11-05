extends ItemInstance
class_name BeefLoverItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.display_name == "Beef":
		result.score = 8.0
		result.triggered = true
	else:
		result.triggered = false
	return result
	
	

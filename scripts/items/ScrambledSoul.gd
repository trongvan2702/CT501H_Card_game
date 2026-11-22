extends ItemInstance
class_name ScrambledSoulItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "egg":
		result.mult = 3.0
		result.text = "Scrambled Soul +3"
		result.triggered = true
	return result

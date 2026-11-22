extends ItemInstance
class_name GrainOfFortuneItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "rice":
		result.mult = 3.0
		result.text = "Grain of Fortune +3"
		result.triggered = true
	return result

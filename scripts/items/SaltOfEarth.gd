extends ItemInstance
class_name SaltOfEarthItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "salt":
		result.mult = 3.0
		result.text = "Salt of the Earth +3"
		result.triggered = true
	return result

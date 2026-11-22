extends ItemInstance
class_name SavoySecretItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "cabbage":
		result.mult = 3.0
		result.text = "Savoy's Secret +3"
		result.triggered = true
	return result

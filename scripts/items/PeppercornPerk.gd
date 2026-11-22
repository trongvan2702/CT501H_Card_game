extends ItemInstance
class_name PeppercornPerkItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "chili":
		result.mult = 3.0
		result.text = "Peppercorn Perk +3"
		result.triggered = true
	return result

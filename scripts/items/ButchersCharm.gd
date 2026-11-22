extends ItemInstance
class_name ButchersCharmItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "beef":
		result.mult = 3.0
		result.text = "Butcher's Charm +3"
		result.triggered = true
	return result

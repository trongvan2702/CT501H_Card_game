extends ItemInstance
class_name VineRipenedItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "tomato":
		result.mult = 3.0
		result.text = "Vine Ripened +3"
		result.triggered = true
	return result

extends ItemInstance
class_name CoopKeeperItem

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var result = TriggerResult.new()
	if ingredient.ingredient_data.ingredient_id == "chicken":
		result.mult = 3.0
		result.text = "Coop Keeper +3"
		result.triggered = true
	return result

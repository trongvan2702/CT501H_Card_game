extends ItemInstance
class_name GoldTest1Item

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	if ingredient.ingredient_data.ingredient_id == "beef":
		var result = TriggerResult.new(0.0, 0.0, "Bò Vàng +1$")
		result.custom_effects["add_money"] = 1
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

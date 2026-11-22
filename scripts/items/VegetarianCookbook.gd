extends ItemInstance
class_name VegetarianCookbookItem

const TARGET_IDS: Array[String] = ["tomato", "cabbage", "chili"]
const MULT_BONUS: float = 8.0

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	if ingredient == null or ingredient.ingredient_data == null:
		return TriggerResult.new()
	
	if ingredient.ingredient_data.ingredient_id in TARGET_IDS:
		return TriggerResult.new(0.0, MULT_BONUS, "+8 Mult from %s" % ingredient.ingredient_data.ingredient_id)
		
	return TriggerResult.new()

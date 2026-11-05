extends ItemInstance
class_name GoldTest2Item

func on_recipe_scored(recipe: RecipeData) -> TriggerResult:
	# Lưu ý: Kiểm tra xem biến ID trong RecipeData của bạn tên là recipe_id hay recipe_name nhé
	if recipe.recipe_id == "beef_steak":
		var result = TriggerResult.new(0.0, 0.0, "Bít Tết +3$")
		result.custom_effects["add_money"] = 3
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

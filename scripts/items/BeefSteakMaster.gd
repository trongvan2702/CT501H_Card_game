extends ItemInstance
class_name BeefSteakMasterItem

func on_recipe_scored(recipe: RecipeData) -> TriggerResult:
	var result = TriggerResult.new()
	if recipe.recipe_id == "beef_steak":
		print("Triggered")
		result.x_mult = true
		result.mult = 2.0
		result.triggered = true
	else: result.triggered = false
	return result

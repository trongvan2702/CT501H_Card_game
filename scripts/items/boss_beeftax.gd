extends ItemInstance
class_name BeefTaxBoss

func _init(i_data: ItemData = null) -> void:
	super(i_data)
	is_boss_modifier = true

func on_recipe_scored(recipe: RecipeData) -> TriggerResult:
	if recipe.recipe_id == "beef_steak":
		var result = TriggerResult.new(0.0, 0.0, "")
		
		result.custom_effects["add_money"] = -5
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

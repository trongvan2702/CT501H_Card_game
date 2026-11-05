extends ItemInstance
class_name VegetarianBoss

func _init(i_data: ItemData = null) -> void:
	super(i_data)
	is_boss_modifier = true # Đánh dấu là Boss

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	var id = ingredient.ingredient_data.ingredient_id
	
	if id == "beef" or id == "chicken":
		var result = TriggerResult.new(0.0, 0.0, "")
		result.x_mult = true
		result.mult = 0.0 
		result.triggered = true
		return result
		
	var empty = TriggerResult.new()
	empty.triggered = false
	return empty

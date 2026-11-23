extends RefCounted
class_name IngredientInstance

var ingredient_data: IngredientData
var state: Dictionary

func _init(data: IngredientData) -> void:
	ingredient_data = data
	state = {
		"bonus_score": 0
	}

func get_score() -> int:
	return ingredient_data.base_score + state["bonus_score"]

func get_info() -> String:
	return ingredient_data.display_name

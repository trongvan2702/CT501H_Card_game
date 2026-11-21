class_name TriggerResult

enum SourceType { NONE, INGREDIENT, RECIPE, ITEM }

var score: float = 0.0
var mult: float = 0.0
var x_mult: bool = false
var extra_money: int = 0
var triggered: bool = false 
var is_from_recipe: bool = false
var text: String = ""
var custom_effects: Dictionary = {}
var source_type: SourceType = SourceType.NONE
var source_ref = null

func _init(
	p_score: float = 0,
	p_mult: float = 0.0,
	p_text: String = "",
) -> void:
	score = p_score
	mult = p_mult
	text = p_text
	if p_score != 0.0 or p_mult != 0.0 or p_text != "":
		triggered = true

class_name TriggerResult

var score: float = 0.0
var mult: float = 0.0
var x_mult: bool = false
var extra_money: int = 0
var triggered: bool = true 
var is_from_recipe: bool = false
var text: String = ""
var custom_effects: Dictionary = {}

func _init(
	p_score: float = 0,
	p_mult: float = 0.0,
	p_text: String = "",
) -> void:
	score = p_score
	mult = p_mult
	text = p_text

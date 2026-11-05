extends Resource
class_name RecipeData

@export_group("Basic Info")
@export var recipe_id: String = ""
@export var recipe_name: String = ""
@export_multiline var description: String = ""
@export var default_unlocked: bool = false

@export_group("Requirements")
@export var min_ingredient: int = 2
@export var max_ingredient: int = 5
@export var required_ingredients: Array[IngredientData] = []

@export_group("Scoring")
@export var base_score: float = 50
@export var base_mult: float = 0.0
@export var bonus_score_per_level: float = 10
@export var bonus_mult_per_level: float = 0.1

@export_group("Visual")
@export var icon_texture: Texture2D = preload("res://assets/Apple Green.png")

func get_info() -> String:
	#return "[%s] %s" % [recipe_name, required_ingredients] 
	return "[%s]" % [recipe_name]

class_name IngredientData
extends Resource

@export_group("Basic Info")
@export var ingredient_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Values")
@export var base_score: int = 10
@export var rarity: int = 1 # phòng trường hợp tương lai sẽ dùng

@export_group("Visual")
@export var icon_texture: Texture2D = preload("res://assets/Apple Green.png")


# Help function
func get_info() -> String:
	return "[%s] %s" % [ingredient_id, display_name]

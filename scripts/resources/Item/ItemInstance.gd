extends RefCounted
class_name ItemInstance

var item_data: ItemData 
var state: Dictionary
var uid: int

var is_boss_modifier: bool = false

static var _next_uid: int = 0

func _init(i_data: ItemData) -> void:
	if i_data == null:
		i_data = ItemData.new()
	
	item_data = i_data
	uid = _next_uid
	_next_uid += 1
	
	state = {}

func get_state(key: String, default = null):
	return state.get(key, default)

func set_state(key: String, value) -> void:
	state[key] = value

func has_state(key: String) -> bool:
	return state.has(key)

func on_play(cards: Array[IngredientInstance]) -> TriggerResult:
	return TriggerResult.new()

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	return TriggerResult.new()

func on_recipe_scored(recipe: RecipeData) -> TriggerResult:
	return TriggerResult.new()

func after_match() -> TriggerResult:
	return TriggerResult.new()

func on_stage_start() -> TriggerResult:
	return TriggerResult.new()

# Dùng cho các Item có chức năng tăng tiến vô hạn trong trận đấu, cần thay đổi description
func get_dynamic_description() -> String:
	if item_data != null:
		return item_data.description
	return ""

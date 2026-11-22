extends ItemInstance
class_name ProteinBoostItem

const TARGET_IDS: Array[String] = ["beef", "chicken", "egg"]
const SCORE_BONUS: float = 30.0

func on_ingredient_scored(ingredient: IngredientInstance) -> TriggerResult:
	if ingredient == null or ingredient.ingredient_data == null:
		return TriggerResult.new()
	
	# Kiểm tra ingredient_id của lá bài vừa tính điểm
	if ingredient.ingredient_data.ingredient_id in TARGET_IDS:
		return TriggerResult.new(SCORE_BONUS, 0.0, "+30 Score from %s" % ingredient.ingredient_data.ingredient_id)
		
	return TriggerResult.new()

extends ItemInstance
class_name PapperClipItem

# Điểm nhận mỗi lượt Play = 30 x số lượt Discard còn lại (đọc qua GameManager).
# Không có lượt discard nào -> không nhận điểm.
func on_play(cards: Array[IngredientInstance]) -> TriggerResult:
	var result = TriggerResult.new()
	var discards = GameManager.discards_left
	if discards > 0:
		result.score = 30.0 * discards
		result.text = "Deck Thinner +%d" % result.score
		result.triggered = true
	return result

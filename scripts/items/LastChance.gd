extends ItemInstance
class_name LastChanceItem

# Cộng +15 additive Mult mỗi lượt Play khi không còn lượt Discard.
func on_play(cards: Array[IngredientInstance]) -> TriggerResult:
	var result = TriggerResult.new()
	if GameManager.discards_left <= 0:
		result.mult = 15.0
		result.text = "Last Chance +15 Mult"
		result.triggered = true
	return result

#func get_dynamic_description() -> String:
	## 1. Lấy đoạn mô tả gốc từ ItemInstance
	#var base_text = super.get_dynamic_description()
#
	#var discards = GameManager.discards_left
	#if discards <= 0:
		#base_text += "\n[Đang kích hoạt: +15 Mult]"
	#else:
		#base_text += "\n[Còn %d lượt Discard]" % discards
#
	#return base_text

extends ItemInstance
class_name GoldTest3Item

func after_match() -> TriggerResult:
	var result = TriggerResult.new(0.0, 0.0, "Heo Đất +3$")
	result.custom_effects["add_money"] = 3
	result.triggered = true
	return result

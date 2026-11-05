extends ItemInstance
class_name SpoonItem

func on_stage_start() -> TriggerResult:
	# Tạo bưu phẩm báo hiệu trên UI (tùy chọn)
	var result = TriggerResult.new(0.0, 0.0, "")
	
	result.custom_effects["add_plays"] = 1
	result.triggered = true
	
	return result

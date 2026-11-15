extends Node

var current_stage: int = 0
var base_target_score: Array[float] = [1, 300, 800, 2000, 5000, 11000, 20000, 35000, 50000]
# Stage_score sẽ bắt đầu từ giá trị thứ 2 tức là 300, giá trị thứ 1 dùng để test
var base_mult: Array[float] = [1.0, 1.5, 2.0]

var current_boss: ItemInstance = null
var boss_pool: Array = []

func start_new_run(custom_stage: int = 0) -> void:
	current_stage = custom_stage
	boss_pool = ["boss_fatigue", "boss_vegetarian", "boss_beefTax"]
	boss_pool.shuffle()
	_setup_stage_rules()

func advance_to_next_stage() -> void:
	current_stage += 1
	_setup_stage_rules()
	print("Đã chuyển sang màn ", current_stage, ". Mục tiêu: ", get_current_target_score())

func _setup_stage_rules() -> void:
	if (current_stage + 1) % 3 == 0:
		_roll_new_boss()
	else:
		current_boss = null
		print("Đây là vòng bình thường.")

func _roll_new_boss() -> void:
	if boss_pool.is_empty():
		print("Đã hết Boss trong pool!")
		return
	
	var next_boss_id = boss_pool.pop_front() 
	
	print(next_boss_id)
	current_boss = ItemDB.create_item_instance(next_boss_id)
	
	if current_boss != null:
		current_boss.is_boss_modifier = true 
		print("CẢNH BÁO BOSS MÀN ", current_stage, ": ", current_boss.item_data.display_name)

func peek_next_boss() -> String:
	if boss_pool.size() > 0:
		return boss_pool[0]
	return ""

func get_current_target_score() -> float:
	return base_target_score[current_stage/3] * base_mult[current_stage%3]

func get_stage_reward(stage_index: int = current_stage) -> int:
	return (stage_index % 3) + 3

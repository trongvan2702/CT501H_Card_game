extends Node

var current_stage: int = 1
var base_target_score: Array[float] = [1, 300, 800, 2000, 5000, 1100, 20000, 35000, 50000]
var base_mult: Array[float] = [1.0, 1.5, 2.0]

var current_boss: ItemInstance = null
var boss_pool: Array = []

func start_new_run() -> void:
	current_stage = 1
	boss_pool = ["boss_fatigue", "boss_vegetarian", "boss_beefTax"]
	_setup_stage_rules()

func advance_to_next_stage() -> void:
	current_stage += 1
	_setup_stage_rules()
	print("Đã chuyển sang màn ", current_stage, ". Mục tiêu: ", get_current_target_score())

func _setup_stage_rules() -> void:
	if current_stage % 3 == 0:
		_roll_new_boss()
	else:
		current_boss = null
		print("Đây là vòng bình thường.")

func _roll_new_boss() -> void:
	var random_boss_id = boss_pool.pick_random()
	print(random_boss_id)
	current_boss = ItemDB.create_item_instance(random_boss_id)
	boss_pool.erase(random_boss_id)
	
	if current_boss != null:
		current_boss.is_boss_modifier = true 
		print("CẢNH BÁO BOSS MÀN ", current_stage, ": ", current_boss.item_data.display_name)

func get_current_target_score() -> float:
	return base_target_score[current_stage/3] * base_mult[current_stage%3]

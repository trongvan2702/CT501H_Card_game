extends Node

var items: Dictionary = {}

func _ready() -> void:
	_load_items()

func _load_items() -> void: 
	var path = "res://resources/items/"
	var dir = DirAccess.open(path)
	
	if dir == null:
		print("Cannot found ItemData")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = path + file_name
			var item = load(full_path)
			
			if item is ItemData:
				items[item.item_id] = item
		
		file_name = dir.get_next()

func create_item_instance(item_id: String) -> ItemInstance:
	if not items.has(item_id):
		print("Cannot find item")
		return null
	
	var data: ItemData = items[item_id]
	
	if data.get("logic_script") != null:
		return data.logic_script.new(data) 
	
	return ItemInstance.new(data)

func get_all_items_data() -> Array:
	return items.values()

func get_random_item_data() -> ItemData:
	if items.is_empty():
		return null
	var keys = items.keys()
	var random_key = keys[randi() % keys.size()]
	return items[random_key]

func _get_rarity_weight(rarity: int) -> int:
	match rarity:
		1: return 80  # Common
		2: return 15   # Rare
		3: return 3   # Epic
		4: return 2    # Legendary
		_: return 80  # Default

#Trả về một mảng các dictionary item 
func get_random_items(count: int, exclude_ids: Array) -> Array:
	var result: Array = []
	var available_items: Array = []
	
	for id in items.keys():
		if not id in exclude_ids and !items.get(id).is_boss:
			available_items.append(items[id])
			
	for i in range(count):
		if available_items.is_empty():
			break 
			
		var total_weight: int = 0
		for item in available_items:
			total_weight += _get_rarity_weight(item.rarity)
			
		var random_ticket = randi() % total_weight
		var current_weight: int = 0
		var selected_index: int = -1
		
		for j in range(available_items.size()):
			current_weight += _get_rarity_weight(available_items[j].rarity)
			if random_ticket < current_weight:
				selected_index = j
				break
				
		if selected_index != -1:
			result.append(available_items[selected_index])
			available_items.remove_at(selected_index)
			#print(available_items[selected_index].display_name)
			
	return result

func _debug_print() -> void:
	for item in items:
		print(item)
	var itemInst = create_item_instance("beef_lover")
	print(itemInst)

func _debug_test_item() -> Array[ItemInstance]:
	var result : Array[ItemInstance] = [create_item_instance("goldtest3"), create_item_instance("spoon"), create_item_instance("fork"), create_item_instance("goldtest1"), create_item_instance("goldtest2")]
	#var result : Array[ItemInstance] = []
	return result

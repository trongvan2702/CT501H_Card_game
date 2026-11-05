extends Resource
class_name ItemData

@export_group("Basic Info")
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: int = 1 # 1 = Common, 2 = uncommon, 3 = rare, 4 = legendary
@export var price: int = 5

@export_group("Script")
@export var logic_script: Script

@export_group("Boss Modify")
@export var is_boss: bool = false

@export_group("Visual")
@export var item_texture: Texture2D = preload("res://assets/Apple Green.png")

func get_display_name() -> String:
	return display_name

#func get_shop_price() -> int:
	#if rarity == 1: return 5
	#elif rarity == 2: return 10
	#elif rarity == 3: return 12
	#else: return 15

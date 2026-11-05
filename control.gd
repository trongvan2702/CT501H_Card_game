extends Control

const IngredientCardPath = preload("res://scences/IngredientCard.tscn")
@export var deck_manager: DeckManager
@export var hand_manager: HandManager
@export var scoring_system: ScoringSystem
@export var shop_manager  = null
@export var stage_manager = null

func _ready() -> void:
	#var score: Array[IngredientInstance] = [IngredientDB.create_ingredient_instance_by_id("beef"), IngredientDB.create_ingredient_instance_by_id("pepper")]
	#deck_manager.start_new_stage()
	#var test = deck_manager.draw_cards(7)
	#for card in test:
		#hand_manager.add_card_to_hand(card)
	#print(scoring_system.calculate_dish_score(score))
	pass


func _on_play_button_pressed() -> void:
	var score = hand_manager.extract_and_remove_selected()
	print(scoring_system.calculate_dish_score(score))
	var number_of_cards_to_draw = min(5, 7 - hand_manager.get_cards_in_hand())
	var cards = deck_manager.draw_cards(number_of_cards_to_draw)
	for card in cards:
		hand_manager.add_card_to_hand(card)
	


func _on_discard_button_pressed() -> void:
	pass # Replace with function body.

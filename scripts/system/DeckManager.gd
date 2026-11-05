extends Node
class_name DeckManager

signal deck_empty()

var full_deck: Array[IngredientInstance] = []
var draw_deck: Array[IngredientInstance] = []
var discard_pile: Array[IngredientInstance] = []

func _ready() -> void:
	#_debug_deck_builder()
	pass

func start_new_stage() -> void:
	draw_deck = full_deck.duplicate()
	discard_pile.clear()
	draw_deck.shuffle()

func reset_deck_for_new_game() ->void:
	full_deck.clear()
	draw_deck.clear()
	discard_pile.clear()

# Modify deck
func add_card_to_full_deck(new_card: IngredientInstance) -> void:
	full_deck.append(new_card)

func remove_card_from_full_deck(remove_card: IngredientInstance) -> void:
	if remove_card in full_deck:
		
		full_deck.erase(remove_card)

# Draw function
func draw_card() -> IngredientInstance:
	if draw_deck.is_empty():
		emit_signal("deck_empty")
		print("Deck empty")
		return null
	var card = draw_deck.pop_back()
	return card

func draw_cards(amount: int) -> Array[IngredientInstance]:
	var cards_drawn: Array[IngredientInstance] = []
	for i in range(amount):
		var card = draw_card()
		if card != null:
			cards_drawn.append(card)
		else:
			break
	return cards_drawn

func _debug_deck_builder() -> void:
	var STARTER_DECK_TEMPLATE: Array = ["beef", "cabbage", "chicken", "pepper", "rice", "salt", "tomato"]
	for ingredient in STARTER_DECK_TEMPLATE:
		for i in range(5):
			var new_instance = IngredientDB.create_ingredient_instance_by_id(ingredient)
			if new_instance != null:
				add_card_to_full_deck(new_instance)	

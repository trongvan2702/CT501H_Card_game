extends Node
class_name HandManager

signal selection_changed(selected_count: int)

@export var hand_ui_container: Control

const max_select = 5
var card_in_hand: Array[IngredientCard] = []

func add_card_to_hand(instance: IngredientInstance) -> void:
	var new_card = IngredientCard.create_from_instance(instance)
	new_card.card_clicked.connect(_on_card_clicked)
	if hand_ui_container:
		hand_ui_container.add_child(new_card)
	card_in_hand.append(new_card)
	#emit_signal("selection_changed")

func add_cards_to_hand(cards: Array[IngredientInstance]) -> void:
	for card in cards:
		add_card_to_hand(card)

func _on_card_clicked(card: IngredientCard) -> void:
	if card.is_selected:
		card.is_selected = false
		card._update_visual_state()
	else: 
		if get_selected_cards().size() < max_select:
			card.is_selected = true
			card._update_visual_state()
		else: print("Cannot select more than 5 card")
	emit_signal("selection_changed", get_selected_cards().size())

func get_cards_in_hand() -> int:
	return card_in_hand.size()

func get_selected_cards() -> Array[IngredientCard]:
	var selected: Array[IngredientCard] = []
	for card in card_in_hand:
		if card.is_selected:
			selected.append(card)
	return selected

func extract_and_remove_selected() -> Array[IngredientInstance]:
	var extracted_cards: Array[IngredientInstance] = []
	var remained_cards: Array[IngredientCard] = []
	
	for card in card_in_hand:
		if card.is_selected:
			extracted_cards.append(card.ingredient_instance)
			card.queue_free()
		else: remained_cards.append(card)
	
	card_in_hand = remained_cards
	emit_signal("selection_changed", 0)
	return extracted_cards

func clear_hand() -> void:
	for card in card_in_hand:
		card.queue_free()
	card_in_hand.clear()
	emit_signal("selection_changed", 0)

func deselect_all() -> void:
	for card in card_in_hand:
		if card.is_selected:
			card.is_selected = false
			card._update_visual_state()
	emit_signal("selection_changed", 0)

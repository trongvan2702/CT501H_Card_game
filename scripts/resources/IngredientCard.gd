class_name IngredientCard
extends Control

signal card_clicked(card: IngredientCard)
signal card_hoverd(card: IngredientCard)
signal card_unhovered(card: IngredientCard)
signal card_selected(card: IngredientCard)

const CARD_SCENE = preload("res://scenes/IngredientCard.tscn")

var ingredient_instance: IngredientInstance = null:
	set(value):
		ingredient_instance = value
		if is_node_ready():
			#_update_display()
			pass

@export var card_size: Vector2 = Vector2(200, 280)
@export var pixel_scale: int = 3

# Internal State

var is_selected: bool = false
var is_hovered: bool = false
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# Texture paths

const card_background_path = "res://assets/CardBackground.png"
const icon_paths = {}

# Static function

static func create_from_instance(data: IngredientInstance) -> IngredientCard:
	var card = CARD_SCENE.instantiate() as IngredientCard
	card.ingredient_instance = data
	
	return card

# Node

#var _background: TextureRect
#var _icon_sprite: TextureRect
#var _name_label: Label

func _ready() -> void:
	custom_minimum_size = card_size
	size = card_size
	pivot_offset = size / 2.0
	_update_display()
	pass

# Display function

func _update_display() -> void:
	if ingredient_instance.ingredient_data == null or ingredient_instance == null:
		return
	
	$_name_label.text = ingredient_instance.ingredient_data.display_name
	$_icon_sprite.texture = ingredient_instance.ingredient_data.icon_texture
	$_seal/Label.text = str(ingredient_instance.get_score())
	
func _update_visual_state() -> void:
	var target_scale = Vector2(1.0, 1.0)
	var target_y_offset = 0.0
	
	if is_selected:
		target_scale = Vector2(1.05, 1.05)
		target_y_offset = -50
		z_index = 10
	elif is_hovered:
		target_scale = Vector2(1.05, 1.05)
		target_y_offset = -5
		z_index = 5
	else:
		target_scale = Vector2(1.0, 1.0)
		target_y_offset = 0
		z_index = 0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.15).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", target_y_offset, 0.15).set_trans(Tween.TRANS_SINE)
	
func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual_state()
	emit_signal("card_hoverd", self)


func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()
	emit_signal("card_unhovered", self)

func _on_card_clicked() -> void:
	#_update_visual_state()
	#if is_selected:
		#is_selected = false
	#else : is_selected = true
	_update_visual_state()
	emit_signal("card_clicked", self)
	emit_signal("card_selected", self)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				print("Clicked")
				_on_card_clicked()
			else:
				is_dragging = false

	elif event is InputEventMouseMotion:
		if is_dragging:
			global_position = event.global_position - drag_offset

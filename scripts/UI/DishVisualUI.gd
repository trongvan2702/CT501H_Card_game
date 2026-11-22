class_name DishVisualUI
extends VBoxContainer

@onready var visual_anchor: Control = $VisualAnchor
@onready var dish_icon: TextureRect = $VisualAnchor/DishIcon
@onready var dish_name_label: Label = $VisualAnchor/DishNameLabel

var recipe_data: RecipeData

func _ready() -> void:
	# Ẩn sẵn để chờ lệnh play_appear_animation()
	modulate.a = 0.0
	visual_anchor.scale = Vector2.ZERO

func setup(data: RecipeData) -> void:
	recipe_data = data
	
	# Lưu ý: Đổi "recipe_texture" thành đúng tên biến ảnh trong RecipeData.gd của bạn (vd: icon, texture...)
	if "icon_texture" in data and data.icon_texture != null:
		dish_icon.texture = data.icon_texture
		
	if dish_name_label:
		dish_name_label.text = data.recipe_name


func play_appear_animation() -> void:
	await get_tree().process_frame
	visual_anchor.pivot_offset = visual_anchor.size / 2.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_anchor, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	
	await tween.finished

func play_trigger_shake() -> void:
	visual_anchor.pivot_offset = visual_anchor.size / 2.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_anchor, "scale", Vector2(1.15, 1.15), 0.08).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual_anchor, "rotation_degrees", 6.0, 0.06)
	
	tween.chain().tween_property(visual_anchor, "rotation_degrees", -6.0, 0.08)
	
	tween.chain().set_parallel(true)
	tween.tween_property(visual_anchor, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(visual_anchor, "rotation_degrees", 0.0, 0.08)
	
	await tween.finished

func play_disappear_animation() -> void:
	visual_anchor.pivot_offset = visual_anchor.size / 2.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual_anchor, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	await tween.finished

class_name HomeButton
extends MarginContainer

@export_file("*.tscn") var main_menu_path: String = "res://scenes/MainMenu.tscn"

@onready var bg_panel: PanelContainer = $Background
@onready var click_area: Button = $Button

var is_hovered: bool = false

func _ready() -> void:
	pivot_offset = custom_minimum_size / 2.0
	
	
	click_area.mouse_entered.connect(_on_mouse_entered)
	click_area.mouse_exited.connect(_on_mouse_exited)
	click_area.pressed.connect(_on_pressed)

func _update_visual_state() -> void:
	var target_scale := Vector2(1.06, 1.06) if is_hovered else Vector2.ONE
	var target_modulate := Color(1.15, 1.15, 1.15) if is_hovered else Color.WHITE
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", target_scale, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(bg_panel, "modulate", target_modulate, 0.1).set_trans(Tween.TRANS_SINE)

func _on_mouse_entered() -> void:
	is_hovered = true
	_update_visual_state()

func _on_mouse_exited() -> void:
	is_hovered = false
	_update_visual_state()

func _on_pressed() -> void:
	if AudioManager.has_method("play_button_click"):
		AudioManager.play_button_click()
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.05)
	await tween.finished
	
	get_tree().change_scene_to_file(main_menu_path)

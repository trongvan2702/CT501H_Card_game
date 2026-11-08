extends Control
class_name ItemCard

const CARD_SCENE = preload("res://scences/ItemCard.tscn")

var display_data: ItemData = null
var display_instance: ItemInstance = null

@onready var icon_sprite = $TextureRect
@onready var detail_panel = $PanelContainer
@onready var detail_label = $PanelContainer/Label

# Dùng khi hàng nằm trên kệ Shop (Chưa sở hữu)
static func create_from_data(data: ItemData) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_data = data
	return card

# Dùng khi hàng nằm trong túi đồ (Đã sở hữu, có chỉ số động)
static func create_from_instance(instance: ItemInstance) -> ItemCard:
	var card = CARD_SCENE.instantiate() as ItemCard
	card.display_instance = instance
	card.display_data = instance.item_data
	return card

func _ready() -> void:
	detail_panel.visible = false
	if display_data:
		icon_sprite.texture = display_data.item_texture
		
		# Quyết định lấy Text tĩnh hay Text động
		if display_instance != null:
			detail_label.text = display_data.display_name + "\n" + display_instance.get_dynamic_description()
		else:
			detail_label.text = display_data.display_name + "\n" + display_data.description

# Bắt sự kiện click chuột vào vùng Control của thẻ
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Bật/tắt bảng thông tin khi click
			detail_panel.visible = !detail_panel.visible
			if detail_panel.visible:
				move_to_front()

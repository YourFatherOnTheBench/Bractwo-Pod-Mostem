extends Panel


@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_label: Label = $CenterContainer/Panel/Label
@onready var drop_button: Button = $Node/DropButton
@onready var item_button: TextureButton = $CenterContainer/Panel/ItemButton
var clicked: bool = false
@onready var InventoryUI_Node: Control = $"../../.."


func update(slot: inventorySlot):
	
	if slot == null or slot.item == null:
		item_visual.visible = false
		amount_label.visible = false
	else:
		item_visual.visible = true
		amount_label.visible = true
		item_visual.texture = slot.item.texture
		amount_label.text = str(slot.amount)



func changeName(NewName: String):
	self.name = NewName





func _on_texture_button_pressed() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	var player = players[0]
	var inv = null
	if player:
		inv = player.get("inventory")
	
	
	
	
	
	
	print("clicked")
	if clicked:
		$Node.visible = true
		drop_button.disabled = false
		clicked = not clicked
	else:
		$Node.visible = false
		drop_button.disabled = true
		clicked = not clicked

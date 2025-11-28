extends Panel


@onready var item_visual: Sprite2D = $CenterContainer/Panel/item_display
@onready var amount_label: Label = $CenterContainer/Panel/Label

func update(slot: inventorySlot):
	if slot == null or slot.item == null:
		item_visual.visible = false
		amount_label.visible = false
	else:
		item_visual.visible = true
		amount_label.visible = true
		item_visual.texture = slot.item.texture
		amount_label.text = str(slot.amount)

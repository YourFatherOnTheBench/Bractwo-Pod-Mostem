extends Control

@onready var inventory: Inventory = preload("res://inventory/player_inventory.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()


var is_open: bool = false

func _ready() -> void:
	update_slots()
	close()


func update_slots():
	for i in range(min(inventory.items.size(),slots.size())):
		slots[i].update(inventory.items[i])
	
func _process(_delta) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		if is_open:
			close()
		else:
			open()
	
func open() -> void:
	is_open = true
	visible = true
	
	
func close() -> void:
	is_open = false
	visible = false

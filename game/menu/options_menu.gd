extends Control

signal close_options

@onready var back_button: Button = $OptionsBackButton
@onready var resolution_button: OptionButton = $VideoSettingsContainer/ResolutionContainer/ResolutionOptionButton
@onready var window_mode_button: OptionButton = $VideoSettingsContainer/WindowModeContainer/WindowModeOptionButton
@onready var vsync_button: OptionButton = $VideoSettingsContainer/VSyncContainer/VSyncOptionButton

const RESOLUTIONS: Dictionary = {
	"3840 x 2160" : Vector2i(3840, 2160),
	"2560 x 1440": Vector2i(2560,1440),
	"1920 x 1080": Vector2i(1920, 1080),
	"1280 x 720": Vector2i(1280, 720),
	"1152 x 648": Vector2i(1152, 648)
}

const WINDOW_MODES: Dictionary = {
	"Windowed": Window.MODE_WINDOWED,
	"Borderless Fullscreen" : Window.MODE_FULLSCREEN,
	"Exclusive Fullscreen" : Window.MODE_EXCLUSIVE_FULLSCREEN,
}

const VSYNC_MODES: Dictionary = {
	"Disabled": DisplayServer.VSYNC_DISABLED,
	"Enabled": DisplayServer.VSYNC_ENABLED,
	"Adaptive": DisplayServer.VSYNC_ADAPTIVE,
	"Mailbox": DisplayServer.VSYNC_MAILBOX
}

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	
	add_resolutions_to_button()
	add_window_modes_to_button()
	add_vsync_modes_to_button()
	
	# Resolution Check
	var current_size = get_window().size
	var res_values = RESOLUTIONS.values()
	if current_size in res_values:
		resolution_button.selected = res_values.find(current_size)
	else:
		resolution_button.text = "Custom"
	
	# Window Mode Check
	var current_mode = get_window().mode
	var mode_values = WINDOW_MODES.values()
	if current_mode in mode_values:
		window_mode_button.selected = mode_values.find(current_mode)
		
	var current_vsync = DisplayServer.window_get_vsync_mode()
	var vsync_values = VSYNC_MODES.values()
	if current_vsync in vsync_values:
		vsync_button.selected = vsync_values.find(current_vsync)

	# Connect Signals
	resolution_button.item_selected.connect(_on_resolution_selected)
	window_mode_button.item_selected.connect(_on_window_mode_selected)
	vsync_button.item_selected.connect(_on_vsync_selected)

# Resolution Logic
func add_resolutions_to_button():
	var screen_size = DisplayServer.screen_get_size()
	for res_string in RESOLUTIONS:
		var res_size = RESOLUTIONS[res_string]
		if res_size.x <= screen_size.x and res_size.y <= screen_size.y:
			resolution_button.add_item(res_string)

func _on_resolution_selected(index: int):
	var selected_text = resolution_button.get_item_text(index)
	var target_size = RESOLUTIONS[selected_text]
	
	debug_log("Changing resolution to: " + str(target_size)) # <--- LOGGING
	
	if get_window().mode in [Window.MODE_EXCLUSIVE_FULLSCREEN, Window.MODE_FULLSCREEN]:
		get_window().mode = Window.MODE_WINDOWED
		var win_idx = WINDOW_MODES.values().find(Window.MODE_WINDOWED)
		if win_idx != -1:
			window_mode_button.selected = win_idx

			
	get_window().size = target_size
	get_window().move_to_center()


# Window Mode Logic
func add_window_modes_to_button():
	for mode_string in WINDOW_MODES:
		window_mode_button.add_item(mode_string)
	
func _on_window_mode_selected(index: int):
	var selected_text = window_mode_button.get_item_text(index)
	var mode_to_apply = WINDOW_MODES[selected_text]
	
	debug_log("Changing Window Mode to: " + selected_text) # <--- LOGGING
	
	get_window().mode = mode_to_apply
	
	if mode_to_apply == Window.MODE_WINDOWED:
		get_window().move_to_center()

# --- VSync Logic Implementation ---
func add_vsync_modes_to_button():
	for vsync_string in VSYNC_MODES:
		vsync_button.add_item(vsync_string)

func _on_vsync_selected(index: int):
	var selected_text = vsync_button.get_item_text(index)
	var mode_to_apply = VSYNC_MODES[selected_text]
	
	debug_log("Changing VSync to: " + selected_text) # <--- LOGGING
	
	DisplayServer.window_set_vsync_mode(mode_to_apply)

func _on_back_pressed():
	visible = false
	close_options.emit()
	
	
func debug_log(message: String) -> void:
	if OS.is_debug_build():
		print_rich("[color=yellow][Settings][/color] " + message)

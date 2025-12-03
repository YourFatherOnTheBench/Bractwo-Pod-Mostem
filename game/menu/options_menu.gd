extends Control

signal close_options

# UI Nodes
@onready var back_button: Button = $OptionsBackButton
@onready var reset_button: Button = $VideoSettingsContainer/ResetButton
@onready var resolution_button: OptionButton = $VideoSettingsContainer/ResolutionContainer/ResolutionOptionButton
@onready var window_mode_button: OptionButton = $VideoSettingsContainer/WindowModeContainer/WindowModeOptionButton
@onready var vsync_button: OptionButton = $VideoSettingsContainer/VSyncContainer/VSyncOptionButton
@onready var debug_label: RichTextLabel = $RichTextLabel

# Popup Nodes
@onready var confirm_overlay = $ConfirmationOverlay
@onready var countdown_label = $ConfirmationOverlay/VBoxContainer/CountdownLabel
@onready var confirm_button = $ConfirmationOverlay/VBoxContainer/HBoxContainer/ConfirmButton
@onready var revert_button = $ConfirmationOverlay/VBoxContainer/HBoxContainer/RevertButton
@onready var revert_timer = $ConfirmationOverlay/RevertTimer

func _ready():
	# Connect Signals
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	
	resolution_button.item_selected.connect(_on_resolution_selected)
	window_mode_button.item_selected.connect(_on_window_mode_selected)
	vsync_button.item_selected.connect(_on_vsync_selected)
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	revert_button.pressed.connect(_on_revert_pressed)
	revert_timer.timeout.connect(_on_revert_timer_timeout)
	
	# Initialization
	_populate_options()
	_update_ui_from_settings()

func _process(_delta):
	# Popup Countdown
	if confirm_overlay.visible and not revert_timer.is_stopped():
		countdown_label.text = "Reverting in %d..." % int(revert_timer.time_left)
	
	# Debug Info (Only in Debug Builds)
	if visible and debug_label and OS.is_debug_build():
		_update_debug_label()

# --- UI SETUP ---

func _populate_options():
	# 1. Resolutions (Filtered by Monitor Size)
	resolution_button.clear()
	var current_screen = DisplayServer.window_get_current_screen()
	# Use usable_rect to ensure we don't offer resolutions that hide behind taskbar
	var screen_rect = DisplayServer.screen_get_usable_rect(current_screen)
	
	for res in SettingsManager.RESOLUTIONS:
		# Check fit
		if res.x <= screen_rect.size.x and res.y <= screen_rect.size.y:
			resolution_button.add_item("%d x %d" % [res.x, res.y])
	
	# 2. Window Modes
	window_mode_button.clear()
	for mode in SettingsManager.WINDOW_MODES:
		window_mode_button.add_item(mode)
		
	# 3. VSync
	vsync_button.clear()
	for mode in SettingsManager.VSYNC_MODES:
		vsync_button.add_item(mode)

func _update_ui_from_settings():
	var set = SettingsManager.current_settings.video
	
	# 1. Update Resolution Selection
	var saved_res = SettingsManager.RESOLUTIONS[set.resolution_index]
	var res_string = "%d x %d" % [saved_res.x, saved_res.y]
	_select_option_by_text(resolution_button, res_string)
	
	# 2. Update Window Mode
	if set.window_mode < window_mode_button.item_count:
		window_mode_button.selected = set.window_mode
	
	# 3. Update VSync
	if set.vsync_mode < vsync_button.item_count:
		vsync_button.selected = set.vsync_mode
		
	# 4. Handle UX State (Disable resolution if not windowed)
	_update_resolution_enable_state(set.window_mode)

# --- EVENT HANDLERS ---

func _on_reset_pressed():
	SettingsManager.reset_to_defaults()
	# Re-populate in case monitor changed (e.g. game moved to different screen)
	_populate_options() 
	_update_ui_from_settings()

func _on_resolution_selected(index: int):
	# Safe Mode Flow
	SettingsManager.create_backup()
	
	# Reverse Lookup: Match UI text to SettingsManager index
	var selected_str = resolution_button.get_item_text(index)
	var real_index = -1
	
	for i in range(SettingsManager.RESOLUTIONS.size()):
		var res = SettingsManager.RESOLUTIONS[i]
		if "%d x %d" % [res.x, res.y] == selected_str:
			real_index = i
			break
			
	if real_index != -1:
		SettingsManager.current_settings.video.resolution_index = real_index
		SettingsManager.apply_settings()
		_show_confirmation_popup()

func _on_window_mode_selected(index: int):
	# Safe Mode Flow
	SettingsManager.create_backup()
	SettingsManager.current_settings.video.window_mode = index
	
	# UX: Update disabled state immediately
	_update_resolution_enable_state(index)
	
	SettingsManager.apply_settings()
	_show_confirmation_popup()

func _on_vsync_selected(index: int):
	# Instant Save Flow (VSync rarely needs safe mode)
	SettingsManager.current_settings.video.vsync_mode = index
	SettingsManager.apply_settings()
	SettingsManager.save_settings()

# --- CONFIRMATION POPUP LOGIC ---

func _show_confirmation_popup():
	$VideoSettingsContainer.visible = false
	confirm_overlay.visible = true
	confirm_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	revert_timer.start()

func _on_confirm_pressed():
	SettingsManager.save_settings()
	_close_popup()

func _on_revert_pressed():
	_revert_changes()

func _on_revert_timer_timeout():
	_revert_changes()

func _revert_changes():
	SettingsManager.revert_to_backup()
	_populate_options() # Re-populate in case screen changed
	_update_ui_from_settings()
	_close_popup()

func _close_popup():
	$VideoSettingsContainer.visible = true
	confirm_overlay.visible = false
	revert_timer.stop()

# --- HELPERS ---

func _select_option_by_text(opt_btn: OptionButton, text: String):
	for i in range(opt_btn.item_count):
		if opt_btn.get_item_text(i) == text:
			opt_btn.selected = i
			return

func _update_resolution_enable_state(window_mode_index: int):
	# UX: Disable resolution dropdown if we are NOT in Windowed mode (index 0)
	# Changing resolution in Borderless/Fullscreen typically does nothing visible
	resolution_button.disabled = (window_mode_index != 0)

func _on_back_pressed():
	visible = false
	close_options.emit()

func _update_debug_label():
	debug_label.clear()
	debug_label.add_text("DEV log\n")
	var res = DisplayServer.window_get_size()
	var mode = DisplayServer.window_get_mode()
	var saved = SettingsManager.current_settings.video.window_mode
	debug_label.add_text("Actual Res: %s\nActual Mode: %s\nSaved Mode: %s" % [res, mode, saved])

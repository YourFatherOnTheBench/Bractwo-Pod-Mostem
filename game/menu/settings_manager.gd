extends Node

var config = ConfigFile.new()
const SAVE_PATH = "user://game_settings.cfg"

# --- CONSTANTS ---
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(3840, 2160), # 4K
	Vector2i(2560, 1440), # 2K
	Vector2i(1920, 1080), # FHD
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720),  # HD
	Vector2i(1152, 648)
]

# Note: In Godot 4, Mode 0=Windowed, 1=Minimize (skip), 3=Fullscreen, 4=Exclusive
# We map our custom 0,1,2 integers to specific Godot commands below.
const WINDOW_MODES: Array[String] = ["Windowed", "Borderless Fullscreen", "Exclusive Fullscreen"]
const VSYNC_MODES: Array[String] = ["Disabled", "Enabled", "Adaptive", "Mailbox"]

# --- DEFAULTS ---
const DEFAULT_SETTINGS = {
	"video": {
		"window_mode": 0, # Windowed
		"resolution_index": 2, # 1920x1080
		"vsync_mode": 0, # Disabled
		"max_fps": 60,
	},
	"audio": {
		"master_vol": 1.0,
		"music_vol": 0.8,
		"sfx_vol": 1.0
	}
}

var current_settings = DEFAULT_SETTINGS.duplicate(true)
var last_known_good_settings: Dictionary = {} 

func _ready():
	load_settings()

# --- PUBLIC API ---

func reset_to_defaults():
	current_settings = DEFAULT_SETTINGS.duplicate(true)
	# Force window to Primary Screen (0) to rescue it if stuck on a disconnected monitor
	DisplayServer.window_set_current_screen(0)
	apply_settings()
	save_settings()

func create_backup():
	last_known_good_settings = current_settings.duplicate(true)

func revert_to_backup():
	if last_known_good_settings.is_empty(): return
	current_settings = last_known_good_settings.duplicate(true)
	apply_settings()
	last_known_good_settings.clear()

# --- SAVE / LOAD SYSTEM ---

func save_settings():
	for section in current_settings.keys():
		for key in current_settings[section].keys():
			config.set_value(section, key, current_settings[section][key])
	config.save(SAVE_PATH)

func load_settings():
	var err = config.load(SAVE_PATH)
	if err != OK:
		apply_settings()
		return

	for section in current_settings.keys():
		for key in current_settings[section].keys():
			# Fallback to default if key is missing in save file to prevent crashes
			current_settings[section][key] = config.get_value(section, key, DEFAULT_SETTINGS[section][key])
	
	apply_settings()

# --- APPLICATION LOGIC ---

func apply_settings():
	var vid = current_settings.video
	
	# 1. APPLY V-SYNC
	match vid.vsync_mode:
		0: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		1: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
		2: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
		3: DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_MAILBOX)

	# 2. APPLY FPS CAP
	Engine.max_fps = vid.max_fps

	# 3. APPLY WINDOW MODE & RESOLUTION
	# We separate Windowed logic from Fullscreen logic to fix the "Borderless Bug"
	
	match vid.window_mode:
		0: # WINDOWED
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			
			# Apply Resolution & Centering ONLY in Windowed Mode
			_apply_windowed_resolution(vid)
			
		1: # BORDERLESS FULLSCREEN
			# In Godot 4, MODE_FULLSCREEN is actually "Borderless Windowed"
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			# NOTE: We DO NOT set size here. Borderless takes the monitor size automatically.
			
		2: # EXCLUSIVE FULLSCREEN
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			# NOTE: Exclusive mode handles its own resolution via OS.

func _apply_windowed_resolution(vid_settings: Dictionary):
	var target_size = Vector2i(1920, 1080) # Default fallback
	
	# Validate index
	if vid_settings.resolution_index >= 0 and vid_settings.resolution_index < RESOLUTIONS.size():
		target_size = RESOLUTIONS[vid_settings.resolution_index]
	
	# Get Bounds of the screen the window is CURRENTLY on
	var current_screen = DisplayServer.window_get_current_screen()
	# use 'usable_rect' to account for Taskbars (Windows) or Docks (Mac)
	var screen_rect = DisplayServer.screen_get_usable_rect(current_screen)
	
	# Safety Check: If window is bigger than screen area, shrink it.
	if target_size.x > screen_rect.size.x or target_size.y > screen_rect.size.y:
		target_size = Vector2i(1280, 720) # Safe fallback
		
		# Sync internal data so UI updates to show 1280x720
		var new_index = RESOLUTIONS.find(target_size)
		if new_index != -1:
			vid_settings.resolution_index = new_index
			current_settings.video.resolution_index = new_index

	DisplayServer.window_set_size(target_size)
	
	# Center the window within the usable screen area
	var center_pos = screen_rect.position + (screen_rect.size / 2) - (target_size / 2)
	
	# Ensure the title bar doesn't go off the top edge
	if center_pos.y < screen_rect.position.y:
		center_pos.y = screen_rect.position.y
		
	DisplayServer.window_set_position(center_pos)

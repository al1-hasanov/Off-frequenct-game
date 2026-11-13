class_name DisplaySettings
extends RefCounted
## Display options for slower phones, saved apart from the story and the sound
## (user://display_settings.cfg).
##
##   battery_saver  30 frames a second, and the picture drawn at 720p and scaled
##                  up instead of at the screen's full resolution.
##   smooth_edges   2x multisample antialiasing on shapes. Off by default on
##                  phones: their screens are sharp enough that it costs more
##                  than it shows.
##   show_fps       a small frame-rate counter in the corner. On by default in
##                  debug builds on phones, so a test build shows how it runs.

const PATH := "user://display_settings.cfg"
const NORMAL_FPS := 60
const SAVER_FPS := 30

static var battery_saver := false
static var smooth_edges := true
static var show_fps := false


static func defaults() -> void:
	var phone := OS.has_feature("mobile")
	battery_saver = false
	smooth_edges = not phone
	show_fps = phone and OS.is_debug_build()


static func load_settings() -> void:
	defaults()
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	battery_saver = bool(cfg.get_value("display", "battery_saver", battery_saver))
	smooth_edges = bool(cfg.get_value("display", "smooth_edges", smooth_edges))
	show_fps = bool(cfg.get_value("display", "show_fps", show_fps))


static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "battery_saver", battery_saver)
	cfg.set_value("display", "smooth_edges", smooth_edges)
	cfg.set_value("display", "show_fps", show_fps)
	cfg.save(PATH)


static func set_setting(key: String, on: bool) -> void:
	match key:
		"battery_saver":
			battery_saver = on
		"smooth_edges":
			smooth_edges = on
		"show_fps":
			show_fps = on
	apply()


static func get_setting(key: String) -> bool:
	match key:
		"battery_saver":
			return battery_saver
		"smooth_edges":
			return smooth_edges
		"show_fps":
			return show_fps
	return false


## Applies the settings to the game window. Safe to call at any time.
static func apply() -> void:
	Engine.max_fps = SAVER_FPS if battery_saver else NORMAL_FPS
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var win := tree.root
	win.msaa_2d = Viewport.MSAA_2X if smooth_edges and not battery_saver else Viewport.MSAA_DISABLED
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if battery_saver else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS

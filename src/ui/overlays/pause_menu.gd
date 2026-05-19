extends Control
## Pause menu overlay for the strict MVP HUD.
##
## Expected node structure:
##   PauseMenu (Control)
##     ├── ColorRect "BgDim"
##     └── PanelContainer "MenuPanel"
##           └── VBoxContainer
##                 ├── Button "ResumeBtn"
##                 ├── Button "SaveBtn"
##                 ├── Button "LoadBtn"
##                 ├── Button "SettingsBtn"
##                 ├── Button "MainMenuBtn"
##                 └── Button "QuitBtn"

@onready var _resume_btn: Button = $MenuPanel/VBoxContainer/ResumeBtn
@onready var _save_btn: Button = $MenuPanel/VBoxContainer/SaveBtn
@onready var _load_btn: Button = $MenuPanel/VBoxContainer/LoadBtn
@onready var _settings_btn: Button = $MenuPanel/VBoxContainer/SettingsBtn
@onready var _main_menu_btn: Button = $MenuPanel/VBoxContainer/MainMenuBtn
@onready var _quit_btn: Button = $MenuPanel/VBoxContainer/QuitBtn

var _buttons: Array[Button] = []
var _return_focus_path := ^"ZoneA/MenuButton"


func _ready() -> void:
	hide()
	_buttons = [_resume_btn, _save_btn, _load_btn, _settings_btn, _main_menu_btn, _quit_btn]
	for button in _buttons:
		button.focus_mode = Control.FOCUS_ALL
	_resume_btn.pressed.connect(close_menu)
	_save_btn.pressed.connect(_on_save_pressed)
	_load_btn.pressed.connect(_on_load_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_main_menu_btn.pressed.connect(_on_main_menu_pressed)
	_quit_btn.pressed.connect(_on_quit_pressed)
	_apply_accessibility()


func open_menu() -> void:
	show()
	_resume_btn.grab_focus()
	EventBus.emit("game_paused", {})


func close_menu() -> void:
	hide()
	EventBus.emit("pause_closed", {})
	EventBus.emit("focus_requested", {"node_path": String(_return_focus_path)})


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_ESCAPE:
			close_menu()
			accept_event()
		KEY_TAB:
			_cycle_focus(not event.shift_pressed)
			accept_event()
		KEY_ENTER, KEY_SPACE:
			_activate_focused()
			accept_event()


func _cycle_focus(forward: bool) -> void:
	if _buttons.is_empty():
		return
	var focused := get_viewport().gui_get_focus_owner()
	var current_index := _buttons.find(focused)
	if current_index < 0:
		_resume_btn.grab_focus()
		return
	var next_index := (current_index + (1 if forward else -1) + _buttons.size()) % _buttons.size()
	_buttons[next_index].grab_focus()


func _activate_focused() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused is Button:
		focused.pressed.emit()


func _on_save_pressed() -> void:
	EventBus.emit("save_requested", {"slot": 0, "source": "pause_menu"})
	close_menu()


func _on_load_pressed() -> void:
	EventBus.emit("load_requested", {"slot": 0, "source": "pause_menu"})
	close_menu()


func _on_settings_pressed() -> void:
	EventBus.emit("screen_requested", {"screen_id": "settings"})


func _on_main_menu_pressed() -> void:
	EventBus.emit("main_menu_requested", {})


func _on_quit_pressed() -> void:
	EventBus.emit("quit_requested", {})


func _apply_accessibility() -> void:
	accessibility_name = _localized_text("MENU_PAUSE_TITLE", "暂停菜单")
	for button in _buttons:
		button.accessibility_name = button.text


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized

extends PanelContainer
## Light confirmation dialog.
##
## Used for reversible or medium-weight confirmations.
## Focus is trapped inside the dialog while visible.

signal confirmed
signal cancelled

@onready var _message_label: Label = %MessageLabel
@onready var _confirm_btn: Button = %ConfirmBtn
@onready var _cancel_btn: Button = %CancelBtn


func _ready() -> void:
	hide()
	_confirm_btn.pressed.connect(_on_confirm)
	_cancel_btn.pressed.connect(_on_cancel)
	_confirm_btn.focus_mode = Control.FOCUS_ALL
	_cancel_btn.focus_mode = Control.FOCUS_ALL
	_apply_accessibility()


func show_dialog(message_key: String, confirm_key: String = "CONFIRM", cancel_key: String = "CANCEL") -> void:
	_message_label.text = tr(message_key)
	_confirm_btn.text = tr(confirm_key)
	_cancel_btn.text = tr(cancel_key)
	_apply_accessibility()
	show()
	_cancel_btn.grab_focus()


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_ESCAPE:
			_on_cancel()
			accept_event()
		KEY_TAB:
			_cycle_focus(not event.shift_pressed)
			accept_event()
		KEY_ENTER, KEY_SPACE:
			var focused := get_viewport().gui_get_focus_owner()
			if focused is Button:
				focused.pressed.emit()
				accept_event()


func _cycle_focus(forward: bool) -> void:
	var buttons: Array[Button] = [_cancel_btn, _confirm_btn]
	var focused := get_viewport().gui_get_focus_owner()
	var current_index := buttons.find(focused)
	if current_index < 0:
		_cancel_btn.grab_focus()
		return
	var next_index := (current_index + (1 if forward else -1) + buttons.size()) % buttons.size()
	buttons[next_index].grab_focus()


func _on_confirm() -> void:
	hide()
	confirmed.emit()


func _on_cancel() -> void:
	hide()
	cancelled.emit()


func _apply_accessibility() -> void:
	accessibility_name = _localized_text("CONFIRMATION_DIALOG", "确认对话框")
	_confirm_btn.accessibility_name = _confirm_btn.text
	_cancel_btn.accessibility_name = _cancel_btn.text


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized

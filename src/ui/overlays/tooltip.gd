extends PanelContainer
## Tooltip overlay.
##
## Displays localized helper text near the triggering control.

const MAX_WIDTH := 200.0
const PADDING := 8.0
const OFFSET := Vector2(12, 12)
const SHOW_DELAY := 0.3

@onready var _label: Label = %TooltipLabel

var _request_serial := 0
var _pending_payload: Dictionary = {}


func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 12)
	EventBus.subscribe("tooltip_requested", _on_tooltip_requested)
	EventBus.subscribe("tooltip_dismissed", _on_tooltip_dismissed)


func _exit_tree() -> void:
	EventBus.unsubscribe("tooltip_requested", _on_tooltip_requested)
	EventBus.unsubscribe("tooltip_dismissed", _on_tooltip_dismissed)


func _on_tooltip_requested(_name: String, payload: Dictionary) -> void:
	var text_key: String = payload.get("text_key", "")
	if text_key.is_empty():
		return
	_request_serial += 1
	_pending_payload = payload.duplicate(true)
	var request_serial := _request_serial
	hide()
	_show_tooltip_deferred(request_serial)


func _show_tooltip_deferred(request_serial: int) -> void:
	await get_tree().create_timer(SHOW_DELAY).timeout
	if request_serial != _request_serial:
		return
	_show_tooltip(_pending_payload)


func _show_tooltip(payload: Dictionary) -> void:
	var text_key: String = payload.get("text_key", "")
	if text_key.is_empty():
		return
	_label.text = tr(text_key)
	custom_minimum_size.x = MAX_WIDTH
	reset_size()
	var trigger_path: String = payload.get("trigger_node", "")
	if not trigger_path.is_empty():
		var trigger := get_node_or_null(NodePath(trigger_path))
		if trigger is Control:
			var trigger_control: Control = trigger
			var trigger_pos: Vector2 = trigger_control.get_screen_position()
			var tooltip_pos: Vector2 = trigger_pos + OFFSET
			var viewport_size: Vector2 = get_viewport().get_visible_rect().size
			if tooltip_pos.x + MAX_WIDTH > viewport_size.x:
				tooltip_pos.x = viewport_size.x - MAX_WIDTH - PADDING
			if tooltip_pos.y + size.y > viewport_size.y:
				tooltip_pos.y = trigger_pos.y - size.y - OFFSET.y
			position = tooltip_pos
	show()


func _on_tooltip_dismissed(_name: String, _payload: Dictionary) -> void:
	_request_serial += 1
	_pending_payload.clear()
	hide()

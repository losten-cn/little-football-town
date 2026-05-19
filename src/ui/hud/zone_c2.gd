extends PanelContainer
## Legacy ticker placeholder.
##
## The approved strict MVP HUD does not include a persistent ticker.
## This node remains hidden until a future UX revision reintroduces it.


func _ready() -> void:
	visible = false
	focus_mode = Control.FOCUS_NONE

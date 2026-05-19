extends PanelContainer
## Legacy HUD sidebar placeholder.
##
## The approved strict MVP HUD does not use a persistent sidebar.
## This node remains hidden so future non-MVP work can opt in explicitly.


func _ready() -> void:
	visible = false
	focus_mode = Control.FOCUS_NONE

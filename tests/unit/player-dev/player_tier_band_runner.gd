extends SceneTree

const PlayerTierBandTestScript: Script = preload("res://tests/unit/player-dev/player_tier_band_test.gd")

func _initialize() -> void:
	var test_node: Node = PlayerTierBandTestScript.new()
	root.add_child(test_node)

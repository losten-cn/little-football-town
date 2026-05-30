# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Can a player complete one clear training-to-match-to-feedback loop in under 5 minutes without guidance?
# Date: 2026-05-30

extends Control

const SessionScript: Script = preload("res://prototypes/little-football-town-vertical-slice/vertical_slice_session.gd")
const HomeScreenScene: PackedScene = preload("res://prototypes/little-football-town-vertical-slice/screens/home_screen.tscn")
const TeamScreenScene: PackedScene = preload("res://prototypes/little-football-town-vertical-slice/screens/team_screen.tscn")
const MatchScreenScene: PackedScene = preload("res://prototypes/little-football-town-vertical-slice/screens/match_screen.tscn")

@onready var _screen_host: Control = $MarginContainer/ScreenHost

var _session: Node = null
var _current_screen: Control = null


func _ready() -> void:
	_session = SessionScript.new()
	add_child(_session)
	show_home_screen()


func show_home_screen() -> void:
	_set_screen(HomeScreenScene.instantiate())
	_current_screen.call("bind_session", _session, Callable(self, "show_team_screen"), Callable(self, "show_match_screen"))


func show_team_screen() -> void:
	_set_screen(TeamScreenScene.instantiate())
	_current_screen.call("bind_session", _session, Callable(self, "show_home_screen"))


func show_match_screen() -> void:
	_set_screen(MatchScreenScene.instantiate())
	_current_screen.call("bind_session", _session, Callable(self, "show_home_screen"))


func _set_screen(screen: Control) -> void:
	if _current_screen != null:
		_current_screen.queue_free()
	_current_screen = screen
	_screen_host.add_child(_current_screen)

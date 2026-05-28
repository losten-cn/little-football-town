class_name SaveSnapshot
extends Resource
## Typed save snapshot Resource for Story 001 save-slot persistence.
## Stores metadata, UI state, and serialized system-state blobs.

@export var save_version: int = 1
@export var timestamp: int = 0
@export var playtime_seconds: float = 0.0
@export var ui_screen_id: String = ""
@export var ui_stack_depth: int = 0
@export var time_state: Dictionary[String, Variant] = {}
@export var player_state: Dictionary[String, Variant] = {}
@export var match_state: Dictionary[String, Variant] = {}
@export var economy_state: Dictionary[String, Variant] = {}
@export var town_state: Dictionary[String, Variant] = {}
@export var league_state: Dictionary[String, Variant] = {}
@export var snapshot_metadata: Dictionary[String, Variant] = {}

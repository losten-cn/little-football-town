class_name TrainingCatalogConfig
extends Resource
## Data-driven MVP training project catalog.

@export var projects: Array[Dictionary] = []


## Returns whether every training project can feed PlayerDevelopment.train().
func validate() -> Dictionary[String, Variant]:
	var errors: Array[String] = []
	if projects.is_empty():
		errors.append("projects must not be empty")
	var seen_ids: Dictionary[String, bool] = {}
	for index: int in range(projects.size()):
		var project: Dictionary[String, Variant] = _to_string_variant_dictionary(projects[index])
		var project_id: String = String(project.get("project_id", project.get("training_id", ""))).strip_edges()
		if project_id.is_empty():
			errors.append("projects[%d].project_id missing" % index)
			continue
		if seen_ids.has(project_id):
			errors.append("duplicate training project: %s" % project_id)
		seen_ids[project_id] = true
		_validate_project(errors, index, project)
	return {"valid": errors.is_empty(), "errors": errors}


## Returns one project by either project_id or legacy training_id.
func get_project(project_id: String) -> Dictionary[String, Variant]:
	var requested_id: String = project_id.strip_edges()
	if requested_id.is_empty():
		return {}
	for project_variant: Variant in projects:
		var project: Dictionary[String, Variant] = _to_string_variant_dictionary(project_variant)
		if String(project.get("project_id", project.get("training_id", ""))) == requested_id:
			return project.duplicate(true)
	return {}


## Returns UI-facing training options derived from authoritative project data.
func get_training_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for project_variant: Variant in projects:
		var project: Dictionary[String, Variant] = _to_string_variant_dictionary(project_variant)
		options.append({
			"training_id": String(project.get("project_id", project.get("training_id", ""))),
			"name": String(project.get("name", "训练项目")),
			"summary": String(project.get("summary", "提升球员成长")),
			"cost_summary": _cost_summary(project),
			"risk_summary": String(project.get("risk_summary", "暂无训练风险说明")),
			"payoff_summary": String(project.get("payoff_summary", "下一场比赛前形成成长反馈")),
			"available": true,
		})
	return options


func _validate_project(errors: Array[String], index: int, project: Dictionary[String, Variant]) -> void:
	var primary_attribute: String = String(project.get("primary_attribute", "")).strip_edges()
	if not ["SPD", "PWR", "TEC", "INT", "STA"].has(primary_attribute):
		errors.append("projects[%d].primary_attribute invalid" % index)
	_add_positive_error(errors, index, project, "raw_growth_input")
	_add_non_negative_int_error(errors, index, project, "funds_cost")
	_add_non_negative_int_error(errors, index, project, "action_points_cost")
	_add_positive_error(errors, index, project, "time_cost")
	var focus_match_multiplier: float = float(project.get("focus_match_multiplier", 1.0))
	if is_nan(focus_match_multiplier) or is_inf(focus_match_multiplier) or focus_match_multiplier < 0.5 or focus_match_multiplier > 1.5:
		errors.append("projects[%d].focus_match_multiplier outside [0.5, 1.5]" % index)
	var facility_training_multiplier: float = float(project.get("facility_training_multiplier", 1.0))
	if is_nan(facility_training_multiplier) or is_inf(facility_training_multiplier) or facility_training_multiplier < 1.0 or facility_training_multiplier > 1.75:
		errors.append("projects[%d].facility_training_multiplier outside [1.0, 1.75]" % index)


func _add_positive_error(errors: Array[String], index: int, project: Dictionary[String, Variant], field_name: String) -> void:
	var value: float = float(project.get(field_name, 0.0))
	if is_nan(value) or is_inf(value) or value <= 0.0:
		errors.append("projects[%d].%s must be positive" % [index, field_name])


func _add_non_negative_int_error(errors: Array[String], index: int, project: Dictionary[String, Variant], field_name: String) -> void:
	var value: int = int(project.get(field_name, -1))
	if value < 0:
		errors.append("projects[%d].%s must be non-negative" % [index, field_name])


func _cost_summary(project: Dictionary[String, Variant]) -> String:
	return "经费 %s｜运动点数 %s" % [str(int(project.get("funds_cost", 0))), str(int(project.get("action_points_cost", 0)))]


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	var source: Dictionary = value as Dictionary
	for key_variant: Variant in source.keys():
		typed_dictionary[String(key_variant)] = source[key_variant]
	return typed_dictionary

class_name AonwTerrainProfileEditor
extends RefCounted

func current_maximum(_source: AonwMapSource) -> Dictionary:
	return _not_configured()

func update_maximum(_source: AonwMapSource, _maximum: float) -> Dictionary:
	return _not_configured()

func _not_configured() -> Dictionary:
	return {
		"ok": false,
		"message": "terrain profile editor is not configured",
	}

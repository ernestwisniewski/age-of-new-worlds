@tool
extends "res://editor/map_authoring/application/terrain_authoring_session.gd"
## An explicit lifecycle prevents the previous recipe from clamping new mountains.

func close() -> void:
	if is_instance_valid(_data) and _data.maps_edited.is_connected(_on_maps_edited):
		_data.maps_edited.disconnect(_on_maps_edited)
	_opened = false

func open() -> Dictionary:
	# Validate the target draft before changing native terrain.
	var revision := _persistence.load_revision(_artifact.identity())
	if not revision["ok"]:
		return revision
	if _opened:
		return {"ok": true}
	# Copies are necessary: removing a region changes the collection being walked.
	for location in _data.region_locations.duplicate():
		_data.remove_regionl(location, false)
	return super.open()

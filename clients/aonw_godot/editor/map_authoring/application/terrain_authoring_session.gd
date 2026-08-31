class_name AonwTerrainAuthoringSession
extends RefCounted

const TerrainSpaceTransform := preload(
	"res://game/application/terrain/terrain_space_transform.gd"
)

signal terrain_changed(changed_pixels: Rect2i)

const HEIGHT_TOLERANCE_METERS := 0.0005

var _data: Terrain3DData
var _artifact: AonwTerrainCompiledArtifact
var _space: AonwTerrainSpaceTransform
var _persistence: AonwTerrainAuthoringPersistence
var _terrain_revision := 0
var _internal_edit := false
var _opened := false

func _init(
	data: Terrain3DData,
	artifact: AonwTerrainCompiledArtifact,
	persistence: AonwTerrainAuthoringPersistence,
) -> void:
	assert(data != null, "Terrain3D data is required")
	assert(artifact != null, "Compiled terrain artifact is required")
	assert(persistence != null, "Terrain authoring persistence is required")
	_data = data
	_artifact = artifact
	_space = TerrainSpaceTransform.new(artifact)
	_persistence = persistence

func open() -> Dictionary:
	if _opened:
		return {"ok": true}
	var revision_result := _persistence.load_revision(_artifact.identity())
	if not revision_result["ok"]:
		return revision_result
	_terrain_revision = revision_result["revision"]
	_internal_edit = true
	if revision_result["has_draft"]:
		_data.load_directory(revision_result["data_directory"])
		if _data.get_region_count() == 0:
			_internal_edit = false
			return _failure("saved Terrain3D final terrain has no regions")
	else:
		var images: Array[Image]
		images.resize(Terrain3DRegion.TYPE_MAX)
		images[Terrain3DRegion.TYPE_HEIGHT] = _artifact.base_image.duplicate()
		_data.import_images(images)
	_internal_edit = false
	_opened = true
	if not _data.maps_edited.is_connected(_on_maps_edited):
		_data.maps_edited.connect(_on_maps_edited)
	return {"ok": true}

func artifact() -> AonwTerrainCompiledArtifact:
	return _artifact

func terrain_revision() -> int:
	return _terrain_revision

func height_at(pixel: Vector2i) -> float:
	assert(_artifact.contains_pixel(pixel), "Terrain raster pixel is out of bounds")
	return _data.get_height(_space.raster_pixel_to_terrain_local(pixel))

func set_height(pixel: Vector2i, requested_height: float) -> float:
	assert(_artifact.contains_pixel(pixel), "Terrain raster pixel is out of bounds")
	var height := _artifact.clamp_height(pixel, requested_height)
	_apply_height(pixel, height)
	return height

func change_height(history: UndoRedo, pixel: Vector2i, requested_height: float) -> bool:
	assert(history != null, "UndoRedo history is required")
	assert(_artifact.contains_pixel(pixel), "Terrain raster pixel is out of bounds")
	var previous_height := height_at(pixel)
	var next_height := _artifact.clamp_height(pixel, requested_height)
	if is_equal_approx(previous_height, next_height):
		return false
	history.create_action("Change Terrain3D height")
	history.add_do_method(Callable(self, "_apply_height").bind(pixel, next_height))
	history.add_undo_method(Callable(self, "_apply_height").bind(pixel, previous_height))
	history.commit_action()
	return true

func clamp_changed_region(changed_pixels: Rect2i) -> Dictionary:
	var bounded := changed_pixels.intersection(_artifact.raster_rect())
	if not bounded.has_area():
		return {"ok": true, "changed": 0, "region": bounded}
	var changed := _clamp_region(bounded)
	_terrain_revision += 1
	terrain_changed.emit(bounded)
	return {"ok": true, "changed": changed, "region": bounded}

func validate_for_publish() -> Dictionary:
	var violations: Array[Dictionary] = []
	var violation_count := 0
	for y in _artifact.height:
		for x in _artifact.width:
			var pixel := Vector2i(x, y)
			var value := height_at(pixel)
			var minimum := _artifact.minimum_at(pixel)
			var maximum := _artifact.maximum_at(pixel)
			if (
				not is_finite(value)
				or value < minimum - HEIGHT_TOLERANCE_METERS
				or value > maximum + HEIGHT_TOLERANCE_METERS
			):
				violation_count += 1
				if violations.size() < 16:
					violations.append({
						"pixel": pixel,
						"height": value,
						"minimum": minimum,
						"maximum": maximum,
					})
	return {
		"ok": violation_count == 0,
		"violation_count": violation_count,
		"violations": violations,
	}

func save_draft() -> Dictionary:
	return _persistence.save_draft(_data, _artifact, _terrain_revision)

func publish() -> Dictionary:
	var validation := validate_for_publish()
	if not validation["ok"]:
		return {
			"ok": false,
			"message": "terrain has %d sampled height constraint violation(s)"
				% validation["violation_count"],
			"validation": validation,
		}
	return _persistence.publish(_data, _artifact, _terrain_revision)

func refresh_generated_artifact(next_artifact: AonwTerrainCompiledArtifact) -> Dictionary:
	if next_artifact.map_content_hash != _artifact.map_content_hash:
		return _failure("generated terrain belongs to a different logical map revision")
	if not _has_same_raster(next_artifact):
		return _failure(
			"generated terrain grid changed; migrate final terrain explicitly before refresh"
		)
	_artifact = next_artifact
	_space = TerrainSpaceTransform.new(next_artifact)
	return {"ok": true, "manual_final_preserved": true}

func rescale_generated_artifact(next_artifact: AonwTerrainCompiledArtifact) -> Dictionary:
	if next_artifact.map_content_hash != _artifact.map_content_hash:
		return _failure("generated terrain belongs to a different logical map revision")
	if not _has_same_raster(next_artifact):
		return _failure(
			"generated terrain grid changed; migrate final terrain explicitly before rescale"
		)
	var changed := 0
	_internal_edit = true
	for y in _artifact.height:
		for x in _artifact.width:
			var pixel := Vector2i(x, y)
			var previous := height_at(pixel)
			var manual_delta := previous - _artifact.base_image.get_pixelv(pixel).r
			var next := next_artifact.clamp_height(
				pixel,
				next_artifact.base_image.get_pixelv(pixel).r + manual_delta,
			)
			if is_equal_approx(previous, next):
				continue
			_data.set_height(_space.raster_pixel_to_terrain_local(pixel), next)
			changed += 1
	_internal_edit = false
	_artifact = next_artifact
	_space = TerrainSpaceTransform.new(next_artifact)
	if changed > 0:
		_terrain_revision += 1
		terrain_changed.emit(next_artifact.raster_rect())
	return {
		"ok": true,
		"manual_delta_preserved": true,
		"rescaled_pixels": changed,
	}

func migrate_logical_map_artifact(next_artifact: AonwTerrainCompiledArtifact) -> Dictionary:
	if next_artifact.map_id != _artifact.map_id:
		return _failure("generated terrain belongs to a different map")
	if not _has_same_raster(next_artifact):
		return _failure(
			"logical map edit changed the terrain grid; migrate final terrain explicitly"
		)
	_artifact = next_artifact
	_space = TerrainSpaceTransform.new(next_artifact)
	return {"ok": true, "manual_final_preserved": true}

func _has_same_raster(next_artifact: AonwTerrainCompiledArtifact) -> bool:
	return (
		next_artifact.width == _artifact.width
		and next_artifact.height == _artifact.height
		and is_equal_approx(
			next_artifact.sample_spacing_meters,
			_artifact.sample_spacing_meters,
		)
	)

func _apply_height(pixel: Vector2i, height: float) -> void:
	_internal_edit = true
	_data.set_height(_space.raster_pixel_to_terrain_local(pixel), height)
	_internal_edit = false
	_terrain_revision += 1
	terrain_changed.emit(Rect2i(pixel, Vector2i.ONE))

func _clamp_region(region: Rect2i) -> int:
	var changed := 0
	_internal_edit = true
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var pixel := Vector2i(x, y)
			var previous := height_at(pixel)
			var next := (
				_artifact.base_image.get_pixelv(pixel).r
				if not is_finite(previous)
				else _artifact.clamp_height(pixel, previous)
			)
			if is_equal_approx(previous, next):
				continue
			_data.set_height(_space.raster_pixel_to_terrain_local(pixel), next)
			changed += 1
	_internal_edit = false
	return changed

func _on_maps_edited(edited_area: AABB) -> void:
	if _internal_edit or not _opened:
		return
	var spacing := _artifact.sample_spacing_meters
	var first := Vector2i(
		floori(edited_area.position.x / spacing) - 1,
		floori(edited_area.position.z / spacing) - 1,
	)
	var last := Vector2i(
		ceili(edited_area.end.x / spacing) + 1,
		ceili(edited_area.end.z / spacing) + 1,
	)
	clamp_changed_region(Rect2i(first, last - first + Vector2i.ONE))

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

@tool
extends RefCounted
## Resolve the picker's source and verify its canonical hash through the EDITOR
## API. Terrain authoring must not depend on the version of the gameplay client.

const Catalog := preload("res://editor/map_authoring/infrastructure/map_asset_catalog.gd")
const Workbench := preload("res://editor/map_authoring/infrastructure/engine_logical_map_workbench.gd")
const MapSource := preload("res://game/application/map/map_source.gd")
const MapIdentity := preload("res://game/application/map/read_model/map_view.gd")
const Artifacts := preload("res://game/infrastructure/terrain/terrain_compiled_artifact_repository.gd")
const Atlas := preload("res://game/infrastructure/map/tile_atlas_repository.gd")

func load_inputs(map_id: String, bundle_root: String = "res://assets/maps") -> Dictionary:
	var source: AonwMapSource
	if bundle_root != "res://assets/maps":
		source = MapSource.new(map_id, bundle_root.path_join(map_id).path_join("map.json"), bundle_root.path_join(map_id), "custom")
	else:
		for candidate in Catalog.new().discover():
			if candidate.map_id == map_id:
				source = candidate
				break
	if source == null:
		return _failure("Map is not present in the AoNW source catalog: " + map_id)
	var file := FileAccess.open(source.map_path, FileAccess.READ)
	if file == null:
		return _failure("Cannot read canonical map: " + source.map_path)
	var text := file.get_as_text()
	var document: Variant = JSON.parse_string(text)
	if document is not Dictionary or document.get("mapName") != map_id or document.get("gridLayout") != "oddQFlatTop":
		return _failure("Map document identity or grid layout is invalid")
	# Inspect validates the full canonical document in Rust and returns its hash.
	# Only this verified header is needed by the atlas reader, not a game session.
	var inspected := Workbench.new().inspect_map_tile(text, Vector2i.ZERO)
	if not inspected["ok"]:
		return inspected
	var header: Dictionary = inspected["snapshot"]
	var objectives: Array[AonwMapObjectiveView] = []
	var tiles: Array[AonwMapTileView] = []
	var identity := MapIdentity.new(StringName(map_id), header["mapContentHash"], &"oddQFlatTop",
		int(header["cols"]), int(header["rows"]), float(document.get("defaultZoom", 1.0)), objectives, tiles)
	var directory := "res://.godot/terrain_compiled".path_join(map_id)
	if not FileAccess.file_exists(directory.path_join("terrain_compile.json")):
		directory = "res://assets/terrain_compiled".path_join(map_id)
	var reader := Artifacts.new()
	var loaded := reader.load_artifact(directory, map_id)
	if not loaded["ok"]:
		return loaded
	var artifact: AonwTerrainCompiledArtifact = loaded["artifact"]
	if artifact.map_content_hash != identity.content_hash() or artifact.cols != identity.cols() or artifact.rows != identity.rows():
		return _failure("Compiled terrain is stale relative to the selected JSON map. Recompile canonical inputs first.")
	var texture: Texture2D
	var warning := ""
	if FileAccess.file_exists(source.visual_directory.path_join("map_texture_manifest.json")):
		var atlas := Atlas.new().load_atlas(identity, source.visual_directory)
		if not atlas["ok"]:
			return atlas
		texture = atlas["reference_texture"]
	else:
		warning = "No reference atlas: generating from JSON heights and terrain attributes only."
	var reference := texture.get_image() if texture != null else Image.create(artifact.width, artifact.height, false, Image.FORMAT_RGBA8)
	if texture == null:
		reference.fill(Color(0.5, 0.5, 0.5, 1.0))
	return {"ok": true, "artifact": artifact, "reader": reader, "document": document,
		"texture": texture, "image": reference, "has_reference": texture != null,
		"warning": warning, "source": source}

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

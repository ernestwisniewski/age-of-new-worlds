extends RefCounted

const FilesystemLogicalMapEditor := preload(
	"res://editor/map_authoring/infrastructure/logical_map_editor.gd"
)
const LogicalMapPanel := preload(
	"res://editor/map_authoring/presentation/logical_map_panel.gd"
)
const MapSource := preload("res://game/application/map/map_source.gd")
const EngineLogicalMapWorkbench := preload(
	"res://editor/map_authoring/infrastructure/engine_logical_map_workbench.gd"
)

class FakeTerrainCompiler:
	extends AonwTerrainCompiler

	var calls := 0

	func compile_profiles() -> Dictionary:
		calls += 1
		return {"ok": true}

var _failures: Array[String]
var _test_root: String
var _source: AonwMapSource
var _compiler: FakeTerrainCompiler
var _editor: AonwFilesystemLogicalMapEditor

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_root = "res://.godot/logical_map_painting_test/%s" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_test_root))
	_copy_fixture("map.json")
	_copy_fixture("terrain_authoring.json")
	_source = MapSource.new(
		"paint_fixture",
		_test_root.path_join("map.json"),
		"",
		"content",
	)
	_compiler = FakeTerrainCompiler.new()
	_editor = FilesystemLogicalMapEditor.new(EngineLogicalMapWorkbench.new(), _compiler)
	_test_batch_is_one_canonical_transaction()
	await _test_panel_collects_a_direct_paint_stroke()

func _test_batch_is_one_canonical_transaction() -> void:
	var before := _map_document()
	var before_snapshot := _editor.inspect_tile(_source, Vector2i.ZERO)
	_check(before_snapshot["ok"], "logical paint fixture can be inspected through Engine")
	if not before_snapshot["ok"]:
		return
	var coordinates: Array[Vector2i] = [
		Vector2i(0, 0),
		Vector2i(1, 0),
		Vector2i(2, 0),
	]
	var result := _editor.paint_tiles_height(_source, coordinates, 5)
	_check(result["ok"], "logical height stroke is accepted through Engine")
	if not result["ok"]:
		return
	var after := _map_document()
	_check(
		_compiler.calls == 1,
		"one logical paint stroke writes and compiles Terrain3D once",
	)
	for coordinate in coordinates:
		_check(
			_tile(after, coordinate).get("height") == 5,
			"logical paint stroke updates (%d, %d)" % [coordinate.x, coordinate.y],
		)
	_check(
		result["update"]["mapContentHash"]
		!= before_snapshot["snapshot"]["mapContentHash"]
		and result["update"]["snapshot"]["tile"]["col"] == 2,
		"logical paint stroke returns the final Engine snapshot and content hash",
	)

func _test_panel_collects_a_direct_paint_stroke() -> void:
	var panel := LogicalMapPanel.new()
	panel.configure(_editor)
	Engine.get_main_loop().root.add_child(panel)
	await Engine.get_main_loop().process_frame
	panel.show_source(_source, true)
	panel._brush.select(AonwLogicalMapPanel.Brush.HEIGHT)
	panel._height.value = 4
	var persisted: Array[Vector2i] = []
	panel.edit_persisted.connect(func(
		_source_value: AonwMapSource,
		coordinates: Array[Vector2i],
	) -> void:
		persisted.assign(coordinates)
	)
	_check(panel.begin_paint_stroke(), "height brush starts a direct viewport stroke")
	panel.append_paint_coordinate(Vector2i(0, 1))
	panel.append_paint_coordinate(Vector2i(0, 1))
	panel.append_paint_coordinate(Vector2i(1, 1))
	panel.end_paint_stroke()
	await Engine.get_main_loop().process_frame
	await Engine.get_main_loop().process_frame
	var map := _map_document()
	_check(
		persisted == [Vector2i(0, 1), Vector2i(1, 1)],
		"viewport stroke preserves order and removes duplicate hovered hexes",
	)
	_check(
		_compiler.calls == 2
		and _tile(map, Vector2i(0, 1)).get("height") == 4
		and _tile(map, Vector2i(1, 1)).get("height") == 4,
		"direct viewport stroke uses one batch transaction",
	)
	panel._brush.select(AonwLogicalMapPanel.Brush.INSPECT)
	_check(
		not panel.begin_paint_stroke(),
		"inspect tool cannot accidentally write the canonical map",
	)
	panel.queue_free()
	await Engine.get_main_loop().process_frame

func _copy_fixture(file_name: String) -> void:
	var source_path := "res://../../content/maps/aonw2_starter".path_join(file_name)
	var content := FileAccess.get_file_as_string(source_path)
	var target := FileAccess.open(_test_root.path_join(file_name), FileAccess.WRITE)
	if target != null:
		target.store_string(content)

func _map_document() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(_source.map_path))

func _tile(map: Dictionary, coordinate: Vector2i) -> Dictionary:
	for tile in map.get("tiles", []):
		if tile.get("col") == coordinate.x and tile.get("row") == coordinate.y:
			return tile
	return {}

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

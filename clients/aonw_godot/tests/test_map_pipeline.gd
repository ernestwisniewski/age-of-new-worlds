extends SceneTree

const MapAuthoringSuite := preload("res://tests/suites/map_authoring_suite.gd")
const MapGeometrySuite := preload("res://tests/suites/map_geometry_suite.gd")
const NewMapCreationSuite := preload("res://tests/suites/new_map_creation_suite.gd")
const LogicalMapPaintingSuite := preload(
	"res://tests/suites/logical_map_painting_suite.gd"
)
const MapWorkbenchNativeSuite := preload(
	"res://tests/suites/map_workbench_native_suite.gd"
)
const Terrain3DSpikeSuite := preload("res://tests/suites/terrain3d_spike_suite.gd")
const TerrainAuthoringSuite := preload("res://tests/suites/terrain_authoring_suite.gd")
const SceneSerializationSafetySuite := preload(
	"res://tests/suites/scene_serialization_safety_suite.gd"
)

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for suite in [
		MapGeometrySuite.new(),
		NewMapCreationSuite.new(),
		LogicalMapPaintingSuite.new(),
		MapWorkbenchNativeSuite.new(),
		MapAuthoringSuite.new(),
		Terrain3DSpikeSuite.new(),
		SceneSerializationSafetySuite.new(),
		TerrainAuthoringSuite.new(),
	]:
		await suite.run(_failures)

	if _failures.is_empty():
		print("map pipeline: OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

extends SceneTree

const NativeSessionSuite := preload("res://tests/suites/native_session_suite.gd")
const MovementPresentationSuite := preload(
	"res://tests/suites/movement_presentation_suite.gd"
)
const RecipientProjectionStoreSuite := preload(
	"res://tests/suites/recipient_projection_store_suite.gd"
)
const LocalMatchWorkflowSuite := preload(
	"res://tests/suites/local_match_workflow_suite.gd"
)
const GameplaySemanticFixtureSuite := preload(
	"res://tests/suites/gameplay_semantic_fixture_suite.gd"
)

var _failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for suite in [
		NativeSessionSuite.new(),
		RecipientProjectionStoreSuite.new(),
		LocalMatchWorkflowSuite.new(),
		GameplaySemanticFixtureSuite.new(),
		MovementPresentationSuite.new(),
	]:
		await suite.run(_failures)

	if _failures.is_empty():
		print("runtime pipeline: OK")
		quit(0)
		return
	for failure in _failures:
		push_error(failure)
	quit(1)

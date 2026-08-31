extends RefCounted

const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ClientReadModelDecoder := preload(
	"res://game/infrastructure/engine/client_read_model_decoder.gd"
)

var _failures: Array[String]

func run(failures: Array[String]) -> void:
	_failures = failures
	var manifest_document := _fixture_document("gameplay_semantic_v1.json")
	var manifest: Variant = JSON.parse_string(manifest_document)
	_check(
		manifest is Dictionary and manifest.get("schemaVersion") == 1,
		"shared gameplay semantic manifest opens in Godot",
	)
	if not manifest is Dictionary:
		return
	var intent: Variant = JSON.parse_string(
		_fixture_document(manifest["intentFixture"])
	)
	_check(
		intent is Dictionary
		and intent.get("request", {}).get("type") == "dispatch"
		and intent.get("request", {}).get("command") == manifest["expectedIntent"],
		"Godot consumes the shared gameplay intent",
	)
	var decoder := ClientResponseDecoder.new(7)
	for raw_case in manifest["cases"]:
		_test_case(decoder, raw_case)

func _test_case(decoder: RefCounted, raw_case: Dictionary) -> void:
	var decoded: Dictionary = decoder.call(
		"decode",
		_fixture_document(raw_case["responseFixture"]),
	)
	var body: Dictionary = decoded.get("outcome", {}).get("response", {})
	var command := ClientReadModelDecoder.decode_command(body.get("result", {}))
	if command == null:
		_check(false, "Godot decodes semantic case %s" % raw_case["name"])
		return
	var expected := _expected(raw_case["expected"])
	var actual := _actual(command)
	_check(
		actual == expected,
		"Godot matches shared gameplay semantics for %s: %s != %s" % [
			raw_case["name"], actual, expected,
		],
	)

func _expected(raw: Dictionary) -> Dictionary:
	var raw_patch: Dictionary = raw["patch"]
	var events: Array = []
	for raw_event in raw["events"]:
		events.append({
			"revision": int(raw_event["revision"]),
			"index": int(raw_event["index"]),
			"kind": raw_event["kind"],
		})
	return {
		"accepted": raw["accepted"],
		"rejection": raw["rejection"],
		"revision": int(raw["revision"]),
		"patch": {
			"fromRevision": int(raw_patch["fromRevision"]),
			"toRevision": int(raw_patch["toRevision"]),
			"turn": int(raw_patch["turn"]),
			"upsertedUnitIds": raw_patch["upsertedUnitIds"],
			"removedUnitIds": raw_patch["removedUnitIds"],
		},
		"events": events,
		"evidenceKind": raw["evidenceKind"],
		"outcomeCondition": raw["outcomeCondition"],
	}

func _actual(command: AonwClientReadModels.CommandResult) -> Dictionary:
	var patch := command.patch
	var events: Array = []
	for index in range(command.events.size()):
		events.append({
			"revision": command.stamp.revision,
			"index": index,
			"kind": str(command.events[index].kind),
		})
	var evidence_kind: Variant = null
	if command.evidence is AonwClientReadModels.MovementEvidence:
		evidence_kind = "unitMovement"
	return {
		"accepted": command.accepted,
		"rejection": null if command.rejection == &"" else str(command.rejection),
		"revision": command.stamp.revision,
		"patch": {
			"fromRevision": patch.from_revision,
			"toRevision": patch.to_revision,
			"turn": patch.turn,
			"upsertedUnitIds": patch.upserted_units.map(
				func(unit: AonwClientReadModels.UnitView) -> String: return unit.id
			),
			"removedUnitIds": patch.removed_unit_ids,
		},
		"events": events,
		"evidenceKind": evidence_kind,
		"outcomeCondition": (
			null if patch.outcome == null else str(patch.outcome.condition)
		),
	}

func _fixture_document(name: String) -> String:
	var file := FileAccess.open(
		"res://../../tests/fixtures/client_protocol/%s" % name,
		FileAccess.READ,
	)
	if file == null:
		_failures.append("shared client fixture opens in Godot: %s" % name)
		return ""
	return file.get_as_text()

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

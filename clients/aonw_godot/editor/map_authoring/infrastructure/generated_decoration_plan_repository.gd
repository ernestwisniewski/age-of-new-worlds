class_name AonwGeneratedDecorationPlanRepository
extends AonwGeneratedDecorationPlanReader

const FILE_NAME := "generated_decorations.json"
const MAX_DOCUMENT_BYTES := 16 * 1024 * 1024
const PLAN_FIELDS := [
	"sourceMapContentHash",
	"generationSpecHash",
	"generatorId",
	"generatorVersion",
	"seed",
	"placements",
]
const PLACEMENT_FIELDS := [
	"placementId",
	"kind",
	"sourceCol",
	"sourceRow",
	"xMeters",
	"yMeters",
	"zMeters",
	"rotationDegreesY",
	"scale",
]
const KINDS := [&"tree", &"rock", &"water", &"detail"]

func load_plan(
	source: AonwMapSource,
	artifact: AonwTerrainCompiledArtifact,
) -> Dictionary:
	var path := source.map_path.get_base_dir().path_join(FILE_NAME)
	if not FileAccess.file_exists(path):
		return {"ok": true, "available": false, "placements": []}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % path)
	if file.get_length() > MAX_DOCUMENT_BYTES:
		return _failure("generated decoration plan exceeds its size limit")
	var document: Variant = JSON.parse_string(file.get_as_text())
	if document is not Dictionary or not _has_exact_fields(document, PLAN_FIELDS):
		return _failure("generated decoration plan is malformed")
	var identity_error := _identity_error(document, artifact)
	if not identity_error.is_empty():
		return _failure(identity_error)
	var identifiers := {}
	for placement in document["placements"]:
		var error := _placement_error(placement, artifact, identifiers)
		if not error.is_empty():
			return _failure(error)
	return {
		"ok": true,
		"available": true,
		"placements": document["placements"],
	}

func _identity_error(
	document: Dictionary,
	artifact: AonwTerrainCompiledArtifact,
) -> String:
	if document["sourceMapContentHash"] != artifact.map_content_hash:
		return "generated decoration plan belongs to a different map revision"
	if not _is_sha256(document["generationSpecHash"]):
		return "generated decoration generationSpecHash is malformed"
	if not document["generatorId"] is String or document["generatorId"].is_empty():
		return "generated decoration generatorId is malformed"
	if not _is_integer(document["generatorVersion"], 1, 65535):
		return "generated decoration generatorVersion is malformed"
	if not document["seed"] is String:
		return "generated decoration seed is malformed"
	if not document["placements"] is Array:
		return "generated decoration placements are malformed"
	return ""

func _placement_error(
	placement: Variant,
	artifact: AonwTerrainCompiledArtifact,
	identifiers: Dictionary,
) -> String:
	if placement is not Dictionary or not _has_exact_fields(placement, PLACEMENT_FIELDS):
		return "generated decoration placement is malformed"
	var identifier: Variant = placement["placementId"]
	var kind := StringName(placement["kind"])
	if not identifier is String or identifier.is_empty() or identifiers.has(identifier):
		return "generated decoration placement id is invalid or duplicated"
	if kind not in KINDS:
		return "generated decoration kind is unsupported: %s" % kind
	identifiers[identifier] = true
	var col: Variant = placement["sourceCol"]
	var row: Variant = placement["sourceRow"]
	if not _is_integer(col, 0, artifact.cols - 1) or not _is_integer(row, 0, artifact.rows - 1):
		return "generated decoration source hex is outside the map"
	for field in ["xMeters", "yMeters", "zMeters", "rotationDegreesY", "scale"]:
		var value: Variant = placement[field]
		if (not value is int and not value is float) or not is_finite(float(value)):
			return "generated decoration %s must be finite" % field
	if float(placement["scale"]) <= 0.0:
		return "generated decoration scale must be positive"
	return ""

func _has_exact_fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

func _is_sha256(value: Variant) -> bool:
	return (
		value is String
		and value.length() == 64
		and value.to_lower() == value
		and value.is_valid_hex_number(false)
	)

func _is_integer(value: Variant, minimum: int, maximum: int) -> bool:
	if value is not int and value is not float:
		return false
	return (
		float(int(value)) == float(value)
		and int(value) >= minimum
		and int(value) <= maximum
	)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

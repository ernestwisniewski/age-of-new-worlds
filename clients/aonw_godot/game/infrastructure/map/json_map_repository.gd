class_name AonwJsonMapRepository
extends AonwMapViewReader

const MapSource := preload("res://game/application/map/map_source.gd")
const MapViewMapper := preload("res://game/infrastructure/map/map_view_mapper.gd")
const ClientProtocol := preload("res://game/infrastructure/engine/client_protocol.gd")
const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)

var _client: RefCounted
var _documents: RefCounted
var _mapper := MapViewMapper.new()
var _response_decoder := ClientResponseDecoder.new(ClientProtocol.API_VERSION)

func _init(client: RefCounted, documents: RefCounted) -> void:
	assert(client != null, "Map inspection client is required")
	assert(documents != null, "Map document reader is required")
	_client = client
	_documents = documents

func load_map(source: AonwMapSource) -> Dictionary:
	var document := _load_document(source)
	if not document["ok"]:
		return document
	var envelope: Dictionary = _client.call("request", {
		"type": "inspectMap",
		"mapDocument": document["value"],
	})
	return _map_result(source, envelope)

func load_map_async(source: AonwMapSource) -> Dictionary:
	var document := _load_document(source)
	if not document["ok"]:
		return document
	var request := {
		"type": "inspectMap",
		"mapDocument": document["value"],
	}
	var envelope: Dictionary = (
		await _client.call("request_async", request)
		if _client.has_method("request_async")
		else _client.call("request", request)
	)
	return _map_result(source, envelope)

func _load_document(source: AonwMapSource) -> Dictionary:
	var loaded: Dictionary = _documents.call("read", source.map_path)
	if not loaded.get("ok", false):
		return _failure(str(loaded.get("message", "cannot read map document")))
	return {"ok": true, "value": str(loaded.get("document", ""))}

func _map_result(source: AonwMapSource, envelope: Dictionary) -> Dictionary:
	var decoded := _response_decoder.decode_envelope(envelope, "mapInspected")
	if not decoded["ok"]:
		return _failure("Rust: %s" % decoded["message"])
	var response: Variant = decoded["value"]
	if (
		not response is Dictionary
		or response.size() != 2
		or response.get("type", "") != "mapInspected"
		or not response.has("map")
	):
		return _failure("Rust returned an invalid map inspection response")
	var result := _mapper.from_wire(response["map"])
	if not result["ok"]:
		return result
	var map: AonwMapView = result["value"]
	if source.map_id != map.map_id():
		return _failure(
			"source id %s does not match mapId %s" % [
				source.map_id,
				map.map_id(),
			]
		)
	return {
		"ok": true,
		"map": map,
		"visual_directory": source.visual_directory,
	}

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}

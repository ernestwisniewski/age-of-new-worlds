class_name AonwClientResponseDecoder
extends RefCounted

const ClientFailure := preload("res://game/application/session/client_failure.gd")

var _api_version: int

func _init(api_version: int) -> void:
	_api_version = api_version

func decode(document: String) -> Dictionary:
	var value: Variant = JSON.parse_string(document)
	if not value is Dictionary or not _has_exact_fields(value, ["apiVersion", "outcome"]):
		return _raw_failure("invalid_native_response", "Rust session returned invalid JSON")
	if not _matches_api_version(value["apiVersion"]):
		return _raw_failure(
			"unsupported_client_api",
			"Rust session returned an unsupported client API version",
		)
	var outcome: Variant = value.get("outcome")
	if not outcome is Dictionary:
		return _raw_failure("invalid_native_response", "Rust session returned an invalid envelope")
	match outcome.get("status", ""):
		"success":
			if not _has_exact_fields(outcome, ["status", "response"]):
				return _raw_failure(
					"invalid_native_response",
					"Rust session returned an invalid envelope",
				)
		"failure":
			if not _has_exact_fields(outcome, ["status", "error"]):
				return _raw_failure(
					"invalid_native_response",
					"Rust session returned an invalid envelope",
				)
		_:
			return _raw_failure(
				"invalid_native_response",
				"Rust session returned an invalid envelope",
			)
	return value

func decode_envelope(envelope: Variant, response_type: String) -> Dictionary:
	if not _has_exact_fields(envelope, ["apiVersion", "outcome"]):
		return ClientFailure.result(
			"invalid_client_response",
			"Rust returned an invalid response envelope",
		)
	if not _matches_api_version(envelope["apiVersion"]):
		return ClientFailure.result(
			"unsupported_client_api",
			"Rust returned an unsupported client API version",
		)
	var outcome: Variant = envelope["outcome"]
	if not outcome is Dictionary or not outcome.get("status") is String:
		return ClientFailure.result(
			"invalid_client_response",
			"Rust returned an invalid response envelope",
		)
	match outcome["status"]:
		"failure":
			if not _has_exact_fields(outcome, ["status", "error"]):
				return ClientFailure.result(
					"invalid_client_response",
					"Rust returned an invalid failure",
				)
			var error: Variant = outcome["error"]
			if not _has_exact_fields(error, ["code", "message"]):
				return ClientFailure.result(
					"invalid_client_response",
					"Rust returned an invalid failure",
				)
			if not error["code"] is String or not error["message"] is String:
				return ClientFailure.result(
					"invalid_client_response",
					"Rust returned an invalid failure",
				)
			return ClientFailure.result(error["code"], error["message"])
		"success":
			if not _has_exact_fields(outcome, ["status", "response"]):
				return ClientFailure.result(
					"invalid_client_response",
					"Rust returned an invalid success",
				)
			var response: Variant = outcome["response"]
			if not response is Dictionary or response.get("type", "") != response_type:
				return ClientFailure.result(
					"invalid_client_response",
					"Rust returned an unexpected response type",
				)
			return {"ok": true, "value": response}
		_:
			return ClientFailure.result(
				"invalid_client_response",
				"Rust returned an invalid outcome",
			)

func _matches_api_version(value: Variant) -> bool:
	if value is int:
		return value == _api_version
	if value is float:
		return is_finite(value) and value == float(_api_version)
	return false

func _has_exact_fields(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

func _raw_failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": _api_version,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}

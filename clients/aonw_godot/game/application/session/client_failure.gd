extends RefCounted

enum Kind { LIFECYCLE, STALE_RESPONSE, TRANSPORT, TIMEOUT, PROTOCOL, COMPATIBILITY, ENGINE }

const KINDS_BY_CODE := {
	&"session_not_open": Kind.LIFECYCLE,
	&"session_already_open": Kind.LIFECYCLE,
	&"stale_session_response": Kind.STALE_RESPONSE,
	&"native_engine_unavailable": Kind.TRANSPORT,
	&"engine_worker_unavailable": Kind.TRANSPORT,
	&"client_timeout": Kind.TIMEOUT,
	&"invalid_client_response": Kind.PROTOCOL,
	&"invalid_native_response": Kind.PROTOCOL,
	&"recipient_resync_required": Kind.PROTOCOL,
	&"unsupported_client_api": Kind.COMPATIBILITY,
	&"unsupported_native_build": Kind.COMPATIBILITY,
	&"unsupported_engine_features": Kind.COMPATIBILITY,
}

var kind: int
var code: StringName
var message: String

func _init(code_value: String, message_value: String) -> void:
	code = StringName(code_value)
	message = message_value
	kind = _kind_for(code)

func to_result() -> Dictionary:
	return {
		"ok": false,
		"failure": self,
		"code": str(code),
		"message": message,
	}

static func result(code_value: String, message_value: String) -> Dictionary:
	return new(code_value, message_value).to_result()

static func _kind_for(code_value: StringName) -> int:
	return int(KINDS_BY_CODE.get(code_value, Kind.ENGINE))

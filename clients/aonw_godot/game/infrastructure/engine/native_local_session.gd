class_name AonwNativeLocalSession
extends RefCounted

const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ClientProtocol := preload("res://game/infrastructure/engine/client_protocol.gd")
const BUILD_IDENTITY_FILE := "aonw_native_build_identity.txt"
const NATIVE_ROOT := "res://native"
const ASYNC_REQUEST_TIMEOUT_MSEC := 30_000

var _session: Object
var _native_api_version := 0
var _native_build_identity := ""
var _expected_build_identity := ""
var _response_decoder: RefCounted
var _coalesced_jobs: Dictionary = {}

func _init(session: Object = null, expected_build_identity: String = "") -> void:
	if session != null:
		_session = session
	elif ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")
	if _session != null:
		_native_api_version = int(_session.client_api_version())
		if _session.has_method("build_identity"):
			_native_build_identity = str(_session.build_identity())
	_expected_build_identity = (
		expected_build_identity
		if not expected_build_identity.is_empty()
		else _load_expected_build_identity()
	)
	_response_decoder = ClientResponseDecoder.new(ClientProtocol.API_VERSION)

func is_available() -> bool:
	return (
		_session != null
		and _native_api_version == ClientProtocol.API_VERSION
		and not _expected_build_identity.is_empty()
		and _native_build_identity == _expected_build_identity
	)

func client_api_version() -> int:
	return ClientProtocol.API_VERSION

func build_identity() -> String:
	return _native_build_identity

func request(body: Dictionary) -> Dictionary:
	var precondition := _request_precondition()
	if not precondition.is_empty():
		return precondition
	var document := _request_document(body)
	var response: Dictionary = _response_decoder.call(
		"decode",
		_session.request_json(document),
	)
	return response

## Executes engine work on its serial native worker without blocking Godot's main thread.
## Callers must use `await session.request_async(body)`.
func request_async(
	body: Dictionary,
	timeout_msec: int = ASYNC_REQUEST_TIMEOUT_MSEC,
) -> Dictionary:
	return await _request_async(body, timeout_msec, &"", false)

## Enqueues a non-coalescible user action ahead of queued background work.
func request_interactive_async(
	body: Dictionary,
	timeout_msec: int = ASYNC_REQUEST_TIMEOUT_MSEC,
) -> Dictionary:
	return await _request_async(body, timeout_msec, &"", true)

## Keeps only the latest in-flight request for one interaction key.
## A replaced request completes with `stale_session_response` without exposing its result.
func request_coalesced_async(
	body: Dictionary,
	cancellation_key: StringName,
	timeout_msec: int = ASYNC_REQUEST_TIMEOUT_MSEC,
) -> Dictionary:
	if cancellation_key == &"":
		return _failure("invalid_client_request", "A cancellation key is required")
	return await _request_async(body, timeout_msec, cancellation_key, true)

## Coalesces background work without promoting it ahead of user interaction.
func request_coalesced_background_async(
	body: Dictionary,
	cancellation_key: StringName,
	timeout_msec: int = ASYNC_REQUEST_TIMEOUT_MSEC,
) -> Dictionary:
	if cancellation_key == &"":
		return _failure("invalid_client_request", "A cancellation key is required")
	return await _request_async(body, timeout_msec, cancellation_key, false)

func cancel_coalesced_request(cancellation_key: StringName) -> bool:
	if not _coalesced_jobs.has(cancellation_key):
		return false
	var job_id := int(_coalesced_jobs[cancellation_key])
	_coalesced_jobs.erase(cancellation_key)
	return bool(_session.cancel_request(job_id))

func _request_async(
	body: Dictionary,
	timeout_msec: int,
	cancellation_key: StringName,
	interactive: bool,
) -> Dictionary:
	var precondition := _request_precondition()
	if not precondition.is_empty():
		return precondition
	if timeout_msec < 0:
		return _failure("invalid_client_request", "The request timeout must be non-negative")
	var request_document := _request_document(body)
	var job_id := int(
		_session.request_json_async_interactive(request_document)
		if (
			interactive
			and _session.has_method("request_json_async_interactive")
		)
		else _session.request_json_async(request_document)
	)
	if job_id < 0:
		return _failure("engine_worker_unavailable", "The native engine worker is unavailable")
	if cancellation_key != &"":
		if _coalesced_jobs.has(cancellation_key):
			_session.cancel_request(int(_coalesced_jobs[cancellation_key]))
		_coalesced_jobs[cancellation_key] = job_id
	var started_at_msec := Time.get_ticks_msec()
	while not bool(_session.is_response_ready(job_id)):
		if _is_replaced(cancellation_key, job_id):
			_session.cancel_request(job_id)
			return _failure(
				"stale_session_response",
				"A newer engine request replaced this response",
			)
		if Time.get_ticks_msec() - started_at_msec >= timeout_msec:
			_session.cancel_request(job_id)
			_release_coalesced_job(cancellation_key, job_id)
			return _failure("client_timeout", "The native engine request timed out")
		await Engine.get_main_loop().process_frame
	if _is_replaced(cancellation_key, job_id):
		_session.cancel_request(job_id)
		return _failure(
			"stale_session_response",
			"A newer engine request replaced this response",
		)
	var response_json := str(_session.poll_response_json(job_id))
	_release_coalesced_job(cancellation_key, job_id)
	if response_json.is_empty():
		return _failure("engine_worker_unavailable", "The native engine response was lost")
	return _response_decoder.call("decode", response_json)

func _is_replaced(cancellation_key: StringName, job_id: int) -> bool:
	return (
		cancellation_key != &""
		and int(_coalesced_jobs.get(cancellation_key, -1)) != job_id
	)

func _release_coalesced_job(cancellation_key: StringName, job_id: int) -> void:
	if (
		cancellation_key != &""
		and int(_coalesced_jobs.get(cancellation_key, -1)) == job_id
	):
		_coalesced_jobs.erase(cancellation_key)

func _request_precondition() -> Dictionary:
	if _session == null:
		return _failure(
			"native_engine_unavailable",
			"Build aonw_godot before opening a native session",
		)
	if _native_api_version != ClientProtocol.API_VERSION:
		return _failure(
			"unsupported_client_api",
			"The native engine uses an unsupported client API version",
		)
	if _expected_build_identity.is_empty():
		return _failure(
			"native_build_identity_missing",
			"The native engine build manifest is missing",
		)
	if _native_build_identity != _expected_build_identity:
		return _failure(
			"unsupported_native_build",
			"The native engine does not match the packaged build identity",
		)
	return {}

func _load_expected_build_identity() -> String:
	var platform_directory := _native_platform_directory()
	if platform_directory.is_empty():
		return ""
	var profile := "debug" if OS.is_debug_build() else "release"
	var identity_path := NATIVE_ROOT.path_join(platform_directory).path_join(
		Engine.get_architecture_name()
	).path_join(profile).path_join(BUILD_IDENTITY_FILE)
	var file := FileAccess.open(identity_path, FileAccess.READ)
	return "" if file == null else file.get_as_text().strip_edges()

func _native_platform_directory() -> String:
	match OS.get_name():
		"Linux":
			return "linux"
		"macOS":
			return "macos"
		_:
			return ""

func _request_document(body: Dictionary) -> String:
	return JSON.stringify({
		"apiVersion": ClientProtocol.API_VERSION,
		"request": body,
	})

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": ClientProtocol.API_VERSION,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}

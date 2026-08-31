extends RefCounted

const NativeSessionSuite := preload("res://tests/suites/native_session_suite.gd")

func run(failures: Array[String]) -> void:
	NativeSessionSuite.new().run_editor_tools(failures)

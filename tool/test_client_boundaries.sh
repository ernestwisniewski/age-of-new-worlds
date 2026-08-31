#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dependency_checker="${repo_root}/tool/check_client_dependencies.sh"
fixture_root="$(mktemp -d "${TMPDIR:-/tmp}/aonw-client-boundaries.XXXXXX")"
dependency_fixture="${fixture_root}/dependencies"
case_log="${fixture_root}/case.log"

cleanup() {
  rm -rf "${fixture_root}"
}
trap cleanup EXIT

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib"
printf 'void main() {}\n' >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
"${dependency_checker}" --repo-root "${dependency_fixture}" >/dev/null

printf "import 'package:aonw_core/aonw_core.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a retired Dart import." >&2
  exit 1
fi
echo "Dependency checker rejected a retired Dart import."

printf 'void main() {}\n' >"${dependency_fixture}/clients/aonw_flutter/lib/main.dart"
mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation"
printf "import 'package:aonw_engine_client/aonw_engine_client.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted engine transport in presentation." >&2
  exit 1
fi
echo "Dependency checker rejected engine transport in presentation."

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application"
printf "import 'package:flutter/foundation.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/controller.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Flutter in client application code." >&2
  exit 1
fi
echo "Dependency checker rejected Flutter in client application code."
rm "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/controller.dart"

printf 'final class ProtocolFallbackReader {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/protocol.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a client protocol fallback." >&2
  exit 1
fi
echo "Dependency checker rejected client protocol fallback code."
rm "${dependency_fixture}/clients/aonw_flutter/lib/features/map/application/protocol.dart"

printf "final polish = Localizations.localeOf(context).languageCode == 'pl';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a manual locale branch." >&2
  exit 1
fi
echo "Dependency checker rejected a manual locale branch."

printf "const _polishText = <String, String>{'title': 'Mapa'};\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted an in-code language dictionary." >&2
  exit 1
fi
echo "Dependency checker rejected an in-code language dictionary."

printf "Widget build() => Text('Map');\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted hardcoded user-facing copy." >&2
  exit 1
fi
echo "Dependency checker rejected hardcoded user-facing copy."
printf 'void main() {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"

mkdir -p "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering"
printf "import '../../features/map/infrastructure/engine_map_repository.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_layer.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted infrastructure in a Flame game layer." >&2
  exit 1
fi
echo "Dependency checker rejected infrastructure in a Flame game layer."
rm "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_layer.dart"

printf "import '../../features/map/application/map_repository.dart';\n" \
  >"${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_repository_leak.dart"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a repository in a Flame game layer." >&2
  exit 1
fi
echo "Dependency checker rejected a repository in a Flame game layer."
rm "${dependency_fixture}/clients/aonw_flutter/lib/game/rendering/map_repository_leak.dart"

printf 'void main() {}\n' \
  >"${dependency_fixture}/clients/aonw_flutter/lib/features/map/presentation/map.dart"
mkdir -p "${dependency_fixture}/clients/aonw_godot/game/presentation/map"
printf 'var terrain_mesh_resource\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/presentation/map/mesh_terrain.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a Godot mesh terrain fallback." >&2
  exit 1
fi
echo "Dependency checker rejected a Godot mesh terrain fallback."
rm "${dependency_fixture}/clients/aonw_godot/game/presentation/map/mesh_terrain.gd"

printf 'const Store := preload("res://game/infrastructure/map/store.gd")\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/presentation/map/infrastructure_leak.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot gameplay presentation-to-infrastructure coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot gameplay presentation-to-infrastructure coupling."
rm "${dependency_fixture}/clients/aonw_godot/game/presentation/map/infrastructure_leak.gd"

mkdir -p "${dependency_fixture}/clients/aonw_godot/scenes"
printf '%s\n' \
  '[gd_scene load_steps=2 format=3]' \
  '[ext_resource type="Script" path="res://game/infrastructure/map/store.gd" id="1"]' \
  >"${dependency_fixture}/clients/aonw_godot/scenes/infrastructure_leak.tscn"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted concrete Godot gameplay infrastructure in a scene." >&2
  exit 1
fi
echo "Dependency checker rejected concrete Godot gameplay infrastructure in a scene."
rm "${dependency_fixture}/clients/aonw_godot/scenes/infrastructure_leak.tscn"

mkdir -p "${dependency_fixture}/clients/aonw_godot/game/application/session"
printf 'var transport := NativeLocalSession.new()\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/application/session/concrete_transport.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a concrete native session outside composition." >&2
  exit 1
fi
echo "Dependency checker rejected a concrete native session outside composition."
rm "${dependency_fixture}/clients/aonw_godot/game/application/session/concrete_transport.gd"

printf 'var response := transport.call("request", {"type": "snapshot"})\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/application/session/local_match_session_controller.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted raw wire protocol in the Godot application controller." >&2
  exit 1
fi
echo "Dependency checker rejected raw wire protocol in the Godot application controller."
rm "${dependency_fixture}/clients/aonw_godot/game/application/session/local_match_session_controller.gd"

printf 'extends RefCounted\n' \
  >"${dependency_fixture}/clients/aonw_godot/game/application/session/client_wire_decoder.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a wire decoder in the Godot application layer." >&2
  exit 1
fi
echo "Dependency checker rejected a wire decoder in the Godot application layer."
rm "${dependency_fixture}/clients/aonw_godot/game/application/session/client_wire_decoder.gd"

printf '%s\n' \
  '[configuration]' \
  'entry_symbol = "gdext_rust_init"' \
  '[libraries]' \
  'windows.release.x86_64 = "res://../../engine/target/release/aonw_godot.dll"' \
  >"${dependency_fixture}/clients/aonw_godot/aonw_engine.gdextension"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted an unstaged or unsupported GDExtension library." >&2
  exit 1
fi
echo "Dependency checker rejected an unstaged and unsupported GDExtension library."
rm "${dependency_fixture}/clients/aonw_godot/aonw_engine.gdextension"

authoring_fixture="${dependency_fixture}/clients/aonw_godot/editor/map_authoring"
mkdir -p \
  "${authoring_fixture}/application" \
  "${authoring_fixture}/infrastructure" \
  "${authoring_fixture}/presentation"
printf 'const Store := preload("res://editor/map_authoring/infrastructure/store.gd")\n' \
  >"${authoring_fixture}/application/session.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot application-to-infrastructure coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot application-to-infrastructure coupling."
rm "${authoring_fixture}/application/session.gd"

printf 'const Surface := preload("res://editor/map_authoring/presentation/surface.gd")\n' \
  >"${authoring_fixture}/infrastructure/scenes.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot infrastructure-to-presentation coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot infrastructure-to-presentation coupling."
rm "${authoring_fixture}/infrastructure/scenes.gd"

printf 'const Store := preload("res://editor/map_authoring/infrastructure/store.gd")\n' \
  >"${authoring_fixture}/presentation/surface.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted Godot presentation-to-infrastructure coupling." >&2
  exit 1
fi
echo "Dependency checker rejected Godot presentation-to-infrastructure coupling."
rm "${authoring_fixture}/presentation/surface.gd"

printf 'var canonical_map := {"terrainTags": []}\n' \
  >"${authoring_fixture}/presentation/canonical_map_writer.gd"
if "${dependency_checker}" --repo-root "${dependency_fixture}" >"${case_log}" 2>&1; then
  echo "Dependency checker accepted a Godot canonical map writer." >&2
  exit 1
fi
echo "Dependency checker rejected a Godot canonical map writer."

echo "Client boundary negative tests passed."

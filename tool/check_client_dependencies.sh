#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --repo-root)
      repo_root="${2:?--repo-root requires a path}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

flutter_client="${repo_root}/clients/aonw_flutter"
if [[ ! -d "${flutter_client}" ]]; then
  echo "Flutter client directory not found: ${flutter_client}" >&2
  exit 1
fi

godot_client="${repo_root}/clients/aonw_godot"

violations="$(mktemp "${TMPDIR:-/tmp}/aonw-client-dependencies.XXXXXX")"
trap 'rm -f "${violations}"' EXIT

while IFS= read -r -d '' source_file; do
  grep -nHE 'package:(aonw_core|aonw)/' "${source_file}" >>"${violations}" || true
done < <(
  find "${flutter_client}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name '*.dart' -print0
)

if [[ -d "${godot_client}/game" ]]; then
  grep -RInE \
    'BaseTerrain|terrain_mesh_resource|map_surface_mesh_builder' \
    --include='*.gd' \
    "${godot_client}/game" \
    >>"${violations}" || true

  for layer in application presentation; do
    layer_root="${godot_client}/game/${layer}"
    if [[ -d "${layer_root}" ]]; then
      grep -RInE \
        'res://game/(infrastructure|composition)/' \
        --include='*.gd' \
        "${layer_root}" \
        >>"${violations}" || true
    fi
  done

  gameplay_presentation="${godot_client}/game/presentation"
  if [[ -d "${gameplay_presentation}" ]]; then
    grep -RInE \
      'FileAccess|DirAccess|JSON\.(parse|stringify)' \
      --include='*.gd' \
      "${gameplay_presentation}" \
      >>"${violations}" || true
  fi

  gameplay_scenes="${godot_client}/scenes"
  if [[ -d "${gameplay_scenes}" ]]; then
    grep -RInE \
      'res://game/infrastructure/' \
      --include='*.tscn' \
      --include='*.scn' \
      "${gameplay_scenes}" \
      >>"${violations}" || true
  fi

  while IFS= read -r -d '' source_file; do
    case "${source_file}" in
      */composition/*) ;;
      *)
        grep -nHE 'NativeLocalSession\.new[[:space:]]*\(' "${source_file}" \
          >>"${violations}" || true
        ;;
    esac
  done < <(
    find "${godot_client}/game" -type f -name '*.gd' -print0
  )

  application_session="${godot_client}/game/application/session"
  if [[ -d "${application_session}" ]]; then
    while IFS= read -r -d '' source_file; do
      grep -nHE \
        '"type"[[:space:]]*:|apiVersion|expectedRevision|mapDocument|scenarioDocument|client_api_version|request_async|call\("request"' \
        "${source_file}" \
        >>"${violations}" || true
    done < <(
      find "${application_session}" -type f -name '*.gd' -print0
    )
    find "${application_session}" -type f \
      \( -name 'client_*decoder.gd' -o -name 'client_*schema.gd' -o -name 'client_protocol.gd' \) \
      -print \
      >>"${violations}"
  fi
fi

godot_extension="${godot_client}/aonw_engine.gdextension"
if [[ -f "${godot_extension}" ]]; then
  grep -nHE 'engine/target|res://\.\./' "${godot_extension}" \
    >>"${violations}" || true
  while IFS= read -r library_key; do
    case "${library_key}" in
      linux.debug.x86_64|linux.release.x86_64|macos.debug.arm64|macos.release.arm64) ;;
      *)
        printf '%s: unsupported GDExtension library row: %s\n' \
          "${godot_extension}" \
          "${library_key}" \
          >>"${violations}"
        ;;
    esac
  done < <(
    awk '
      /^\[libraries\]$/ { in_libraries = 1; next }
      /^\[/ { in_libraries = 0 }
      in_libraries && /^[[:alnum:]_.-]+[[:space:]]*=/ {
        key = $0
        sub(/[[:space:]]*=.*$/, "", key)
        print key
      }
    ' "${godot_extension}"
  )
fi

authoring_root="${godot_client}/editor/map_authoring"
if [[ -d "${authoring_root}" ]]; then
  if [[ -d "${authoring_root}/application" ]]; then
    grep -RInE 'res://.*/infrastructure/' \
      --include='*.gd' \
      "${authoring_root}/application" \
      >>"${violations}" || true
  fi
  if [[ -d "${authoring_root}/infrastructure" ]]; then
    grep -RInE 'res://.*/presentation/' \
      --include='*.gd' \
      "${authoring_root}/infrastructure" \
      >>"${violations}" || true
  fi
  if [[ -d "${authoring_root}/presentation" ]]; then
    grep -RInE 'res://.*/infrastructure/' \
      --include='*.gd' \
      "${authoring_root}/presentation" \
      >>"${violations}" || true
  fi
  grep -RInE \
    '"(terrainTags|displayTerrain|yieldTerrain|tiles|objectives)"[[:space:]]*:' \
    --include='*.gd' \
    "${authoring_root}" \
    >>"${violations}" || true
fi

while IFS= read -r -d '' pubspec_file; do
  grep -nHE '^[[:space:]]+(aonw_core|aonw):([[:space:]]|$)' "${pubspec_file}" >>"${violations}" || true
done < <(
  find "${flutter_client}" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name 'pubspec.yaml' -print0
)

while IFS= read -r -d '' source_file; do
  case "${source_file}" in
    */infrastructure/*) ;;
    *)
      grep -nHE "package:aonw_engine_client/" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */lib/game/*)
      grep -nHE "^import .*infrastructure/" "${source_file}" \
        >>"${violations}" || true
      grep -nHE "^import .*application/[^']*repository" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */presentation/*)
      grep -nHE "^import .*infrastructure/" "${source_file}" \
        >>"${violations}" || true
      ;;
    */application/*|*/read_model/*)
      grep -nHE "(package:(flutter|flame)/|dart:ui)" "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  case "${source_file}" in
    */l10n/generated/*) ;;
    *)
      grep -nHE \
        "(Localizations\\.localeOf|languageCode[[:space:]]*==|==[[:space:]]*['\"](pl|en)['\"]|_(polish|english)|bool[[:space:]]+(polish|english))" \
        "${source_file}" \
        >>"${violations}" || true
      grep -nHE \
        "((^|[^[:alnum:]_])(Text|TextSpan)\\([[:space:]]*(const[[:space:]]+)?['\"][[:alpha:]]|(tooltip|semanticLabel|labelText|hintText|helperText|errorText):[[:space:]]*(const[[:space:]]+)?['\"][[:alpha:]])" \
        "${source_file}" \
        >>"${violations}" || true
      ;;
  esac
  grep -niHE \
    '(legacy[^[:alnum:]]*(dto|adapter|reader|writer)|upcaster|protocol[^[:alnum:]]*fallback|compatibility[^[:alnum:]]*(adapter|reader|fallback)|dart[^[:alnum:]]*fallback|fallback[^[:alnum:]]*to[^[:alnum:]]*dart)' \
    "${source_file}" \
    >>"${violations}" || true
done < <(
  find "${flutter_client}/lib" \
    \( -path '*/.dart_tool' -o -path '*/build' \) -prune -o \
    -type f -name '*.dart' -print0
)

if [[ -s "${violations}" ]]; then
  echo "Client dependency boundaries were violated:" >&2
  sed "s#${repo_root}/##" "${violations}" >&2
  exit 1
fi

echo "Client dependency boundaries are intact."

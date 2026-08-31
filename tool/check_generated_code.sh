#!/usr/bin/env bash
set -euo pipefail

export LC_ALL=C
export TZ=UTC

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
read -r -a serverpod_command <<<"${SERVERPOD_CLI:-dart pub global run serverpod_cli:serverpod_cli}"
if [[ "${#serverpod_command[@]}" -eq 0 ]]; then
  echo "SERVERPOD_CLI must name a Serverpod command." >&2
  exit 1
fi

snapshot_parent="$(mktemp -d "${TMPDIR:-/tmp}/aonw-generated-code.XXXXXX")"
snapshot_root="${snapshot_parent}/repository"

cleanup() {
  if [[ "${AONW_KEEP_GENERATED_CODE_SNAPSHOT:-0}" == "1" ]]; then
    echo "Generated-code snapshot kept at ${snapshot_root}." >&2
    return
  fi
  rm -rf "${snapshot_parent}"
}
trap cleanup EXIT

mkdir -p "${snapshot_root}"
git -C "${repo_root}" archive HEAD | tar -xf - -C "${snapshot_root}"

snapshot_git() {
  GIT_CONFIG_NOSYSTEM=1 \
    GIT_CONFIG_GLOBAL=/dev/null \
    git -C "${snapshot_root}" "$@"
}

snapshot_git init -q
snapshot_git config user.email generated-code-check@aonw.invalid
snapshot_git config user.name "AoNW generated-code check"
snapshot_git config commit.gpgSign false
snapshot_git config core.hooksPath /dev/null
snapshot_git add -A
snapshot_git commit -qm "Repository snapshot"

workspace_patch="${snapshot_parent}/workspace.patch"
git -C "${repo_root}" diff --binary --full-index HEAD -- . >"${workspace_patch}"
if [[ -s "${workspace_patch}" ]]; then
  snapshot_git apply --binary --whitespace=nowarn "${workspace_patch}"
fi

while IFS= read -r -d '' path; do
  mkdir -p "${snapshot_root}/$(dirname "${path}")"
  cp -pP "${repo_root}/${path}" "${snapshot_root}/${path}"
done < <(git -C "${repo_root}" ls-files --others --exclude-standard -z)

snapshot_git add -A
if ! snapshot_git diff --cached --quiet; then
  snapshot_git commit -qm "Workspace snapshot"
fi

echo "Checking Flutter localizations..."
(
  cd "${snapshot_root}/clients/aonw_flutter"
  flutter pub get --enforce-lockfile
  rm -rf lib/l10n/generated
  flutter gen-l10n
)

echo "Checking Serverpod protocol, client, test tools, and initial schema..."
(
  cd "${snapshot_root}/server"
  dart pub get --enforce-lockfile
  rm -rf \
    lib/src/generated \
    ../packages/aonw_server_client/lib/src/protocol \
    test/integration/test_tools
  "${serverpod_command[@]}" generate
  "${serverpod_command[@]}" create-migration
)

status="$(snapshot_git status --porcelain=v1 --untracked-files=all)"
if [[ -n "${status}" ]]; then
  echo "Generated code is out of sync with its sources:" >&2
  printf '%s\n' "${status}" >&2
  snapshot_git diff --no-ext-diff --stat >&2
  echo "Run the relevant generator, review the diff, and commit it." >&2
  echo "Set AONW_KEEP_GENERATED_CODE_SNAPSHOT=1 to inspect the snapshot." >&2
  exit 1
fi

echo "Generated localizations, protocol, client, test tools, and schema are in sync."

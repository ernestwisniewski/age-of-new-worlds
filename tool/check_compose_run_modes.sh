#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
read -r -a compose_command <<<"${COMPOSE:-docker compose}"
base=(-f "${repo_root}/compose.yml")
staging=(-f "${repo_root}/compose.yml" -f "${repo_root}/compose.staging.yml")
production=(-f "${repo_root}/compose.yml" -f "${repo_root}/compose.prod.yml")

compose_config() {
  "${compose_command[@]}" \
    --project-directory "${repo_root}" \
    --env-file "${repo_root}/.env.example" \
    "$@"
}

check_profile() {
  local profile="$1"
  local expected_mode="$2"
  local expected_services="$3"
  shift 3

  local render
  render="$(compose_config "$@" --profile "${profile}" config)"
  local actual_mode
  actual_mode="$(
    printf '%s\n' "${render}" |
      awk '$1 == "AONW_COMPOSE_RUN_MODE:" { print $2 }'
  )"
  if [[ "${actual_mode}" != "${expected_mode}" ]]; then
    echo "Profile ${profile} selected ${actual_mode:-no mode}, expected ${expected_mode}." >&2
    exit 1
  fi
  if printf '%s\n' "${render}" | grep -Eq '^[[:space:]]+SERVERPOD_RUN_MODE:'; then
    echo "Profile ${profile} imported ambient SERVERPOD_RUN_MODE." >&2
    exit 1
  fi

  local actual_services
  actual_services="$(compose_config "$@" --profile "${profile}" config --services | sort)"
  if [[ "${actual_services}" != "${expected_services}" ]]; then
    echo "Profile ${profile} selected an unexpected service set." >&2
    exit 1
  fi
}

expect_combined_overlays_rejected() {
  local label="$1"
  local mode="$2"
  local profile="$3"
  shift 3
  local render
  render="$(compose_config "$@" --profile "${profile}" config)"
  local staging_marker
  local production_marker
  staging_marker="$(printf '%s\n' "${render}" | awk '$1 == "AONW_STAGING_OVERLAY:" { gsub(/"/, "", $2); print $2 }')"
  production_marker="$(printf '%s\n' "${render}" | awk '$1 == "AONW_PROD_OVERLAY:" { gsub(/"/, "", $2); print $2 }')"

  set +e
  env \
    AONW_COMPOSE_RUN_MODE="${mode}" \
    AONW_STAGING_OVERLAY="${staging_marker}" \
    AONW_PROD_OVERLAY="${production_marker}" \
    sh "${repo_root}/server/docker-entrypoint.sh" >/dev/null 2>&1
  local status=$?
  set -e
  if [[ "${status}" -ne 64 ]]; then
    echo "Compose accepted ${label}." >&2
    exit 1
  fi
}

check_profile dev development $'postgres\nredis\nserver' "${base[@]}"
check_profile tunnel development $'cloudflared\npostgres\nredis\nserver' "${base[@]}"
check_profile staging staging $'caddy\npostgres\nredis\nserver' "${staging[@]}"
check_profile prod production $'caddy\npostgres\nredis\nserver' "${production[@]}"

# Both orderings must fail closed: production with both overlays and staging
# with both overlays.
expect_combined_overlays_rejected \
  "production with both overlays" \
  production \
  prod \
  "${staging[@]}" \
  -f "${repo_root}/compose.prod.yml"
expect_combined_overlays_rejected \
  "staging with both overlays" \
  staging \
  staging \
  "${production[@]}" \
  -f "${repo_root}/compose.staging.yml"

# Poison ambient values must never control a managed image.
AONW_COMPOSE_RUN_MODE=test compose_config "${base[@]}" --profile dev config >/dev/null

echo "Compose run modes are deterministic and fail closed."

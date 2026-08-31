#!/usr/bin/env bash
set -euo pipefail

workspace="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${workspace}"

random_hex() {
  local byte_count="$1"
  local expected_length=$((byte_count * 2))
  local value
  value="$(LC_ALL=C od -An -N"${byte_count}" -tx1 /dev/urandom | tr -d '[:space:]')"
  if ((${#value} != expected_length)) || [[ ! "${value}" =~ ^[0-9a-f]+$ ]]; then
    echo "Could not generate secure integration-test randomness." >&2
    return 1
  fi
  printf '%s' "${value}"
}

read -r -a compose_command <<<"${COMPOSE:-docker compose}"
read -r -a dart_command <<<"${DART:-dart}"
project_name="aonw-server-integration-$(random_hex 8)"
postgres_password="$(random_hex 32)"
test_database="aonw_test"
compose=(
  "${compose_command[@]}"
  --project-directory "${workspace}"
  --project-name "${project_name}"
  -f "${workspace}/compose.yml"
)

export POSTGRES_DB="aonw"
export POSTGRES_USER="aonw"
export POSTGRES_PASSWORD="${postgres_password}"
export SERVERPOD_DATABASE_PASSWORD="${postgres_password}"
export AONW_POSTGRES_BIND="127.0.0.1"
export AONW_POSTGRES_PORT="0"
export SERVERPOD_SERVICE_SECRET="integration-service-secret"
export SERVERPOD_PASSWORD_emailSecretHashPepper="integration-email-secret"
export SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="integration-jwt-private-key"
export SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="integration-refresh-pepper"
export SERVERPOD_PASSWORD_redis="integration-redis-password"

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  if ((status != 0)); then
    echo "Server integration failed in isolated project ${project_name}." >&2
    "${compose[@]}" --profile dev ps >&2 || true
    "${compose[@]}" --profile dev logs --tail=120 postgres >&2 || true
  fi
  if ! "${compose[@]}" --profile dev down --volumes --remove-orphans; then
    echo "Could not remove isolated project ${project_name}." >&2
    if ((status == 0)); then
      status=1
    fi
  fi
  exit "${status}"
}

trap cleanup EXIT
trap 'exit 130' INT TERM

"${compose[@]}" --profile dev up -d postgres

published_endpoint="$("${compose[@]}" port postgres 5432)"
if [[ ! "${published_endpoint}" =~ ^127\.0\.0\.1:([0-9]{1,5})$ ]]; then
  echo "PostgreSQL must use a random IPv4 loopback port; got ${published_endpoint:-none}." >&2
  exit 64
fi
postgres_port="${BASH_REMATCH[1]}"
if ((10#${postgres_port} < 1 || 10#${postgres_port} > 65535)); then
  echo "Published PostgreSQL port is invalid: ${postgres_port}." >&2
  exit 64
fi

postgres_ready=false
for _ in {1..60}; do
  if probe="$("${compose[@]}" exec -T postgres sh -eu -c '
      export PGPASSWORD="$POSTGRES_PASSWORD"
      exec psql -h 127.0.0.1 -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        -v ON_ERROR_STOP=1 -Atqc "SELECT 1"
    ' 2>/dev/null)" && [[ "${probe}" == "1" ]]; then
    postgres_ready=true
    break
  fi
  sleep 1
done
if [[ "${postgres_ready}" != true ]]; then
  echo "PostgreSQL did not accept an authenticated query within 60 seconds." >&2
  exit 1
fi

"${compose[@]}" exec -T postgres createdb -U "${POSTGRES_USER}" "${test_database}"

tests=()
while IFS= read -r test_path; do
  tests+=("${test_path#server/}")
done < <(find server/test/integration -type f -name '*_smoke.dart' | sort)
if ((${#tests[@]} == 0)); then
  echo "No Serverpod integration tests found." >&2
  exit 1
fi

cd server
env -i \
  PATH="${PATH:?PATH is required}" \
  HOME="${HOME:?HOME is required}" \
  TMPDIR="${TMPDIR:-/tmp}" \
  SERVERPOD_DATABASE_PORT="${postgres_port}" \
  SERVERPOD_PASSWORD_database="${postgres_password}" \
  SERVERPOD_PASSWORD_emailSecretHashPepper="integration-email-secret" \
  SERVERPOD_PASSWORD_jwtHmacSha512PrivateKey="integration-jwt-private-key" \
  SERVERPOD_PASSWORD_jwtRefreshTokenHashPepper="integration-refresh-pepper" \
  "${dart_command[@]}" test "${tests[@]}" \
    -P integration --chain-stack-traces --concurrency=1

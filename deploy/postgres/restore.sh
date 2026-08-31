#!/usr/bin/env bash
set -euo pipefail

backup_file="${1:-}"
if [[ -z "${backup_file}" ]]; then
  echo "Usage: AONW_RESTORE_DATABASE_URL=postgres://... $0 <backup.dump>" >&2
  exit 2
fi

if [[ ! -f "${backup_file}" ]]; then
  echo "Backup file does not exist: ${backup_file}" >&2
  exit 2
fi

if [[ -z "${AONW_RESTORE_DATABASE_URL:-}" ]]; then
  echo "AONW_RESTORE_DATABASE_URL is required" >&2
  exit 2
fi

if [[ "${AONW_RESTORE_DATABASE_URL}" == "${DATABASE_URL:-}" && "${AONW_RESTORE_ALLOW_PROD:-}" != "true" ]]; then
  echo "Refusing to restore into DATABASE_URL without AONW_RESTORE_ALLOW_PROD=true" >&2
  exit 2
fi

if ! command -v pg_restore >/dev/null 2>&1; then
  echo "pg_restore is required on PATH" >&2
  exit 2
fi

if ! command -v psql >/dev/null 2>&1; then
  echo "psql is required on PATH" >&2
  exit 2
fi

pg_restore \
  --clean \
  --if-exists \
  --no-owner \
  --no-acl \
  --dbname="${AONW_RESTORE_DATABASE_URL}" \
  "${backup_file}"

psql "${AONW_RESTORE_DATABASE_URL}" \
  --set=ON_ERROR_STOP=1 \
  --command="SELECT module, version, timestamp FROM serverpod_migrations ORDER BY module;"

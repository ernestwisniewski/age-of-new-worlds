#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is required" >&2
  exit 2
fi

if ! command -v pg_dump >/dev/null 2>&1; then
  echo "pg_dump is required on PATH" >&2
  exit 2
fi

if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
  echo "sha256sum or shasum is required on PATH" >&2
  exit 2
fi

backup_dir="${AONW_BACKUP_DIR:-./backups/postgres}"
retention_days="${AONW_BACKUP_RETENTION_DAYS:-14}"
prefix="${AONW_BACKUP_PREFIX:-aonw}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_file="${backup_dir}/${prefix}-${timestamp}.dump"
tmp_file="${backup_file}.tmp"

mkdir -p "${backup_dir}"
trap 'rm -f "${tmp_file}"' EXIT

pg_dump \
  --format=custom \
  --compress=9 \
  --no-owner \
  --no-acl \
  --file="${tmp_file}" \
  "${DATABASE_URL}"

mv "${tmp_file}" "${backup_file}"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "${backup_file}" > "${backup_file}.sha256"
else
  shasum -a 256 "${backup_file}" > "${backup_file}.sha256"
fi

find "${backup_dir}" \
  -type f \
  \( -name "${prefix}-*.dump" -o -name "${prefix}-*.dump.sha256" \) \
  -mtime "+${retention_days}" \
  -delete

echo "${backup_file}"

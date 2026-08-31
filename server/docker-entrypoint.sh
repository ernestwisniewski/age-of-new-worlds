#!/bin/sh
set -eu

mode="${AONW_COMPOSE_RUN_MODE:-${SERVERPOD_RUN_MODE:-production}}"
staging_overlay="${AONW_STAGING_OVERLAY:-0}"
prod_overlay="${AONW_PROD_OVERLAY:-0}"
server_id="${SERVERPOD_SERVER_ID:-default}"
logging="${SERVERPOD_LOGGING_MODE:-normal}"
role="${SERVERPOD_SERVER_ROLE:-monolith}"

case "$staging_overlay:$prod_overlay" in
  0:0) ;;
  1:0)
    if [ "$mode" != "staging" ]; then
      echo "The staging Compose overlay requires Serverpod staging mode." >&2
      exit 64
    fi
    ;;
  0:1)
    if [ "$mode" != "production" ]; then
      echo "The production Compose overlay requires Serverpod production mode." >&2
      exit 64
    fi
    ;;
  *)
    echo "Invalid Compose overlay combination." >&2
    exit 64
    ;;
esac

case "$mode" in
  development|test|staging|production) ;;
  *)
    echo "Unsupported Serverpod run mode: $mode" >&2
    exit 64
    ;;
esac

# Every Serverpod argument is managed below. Reject command arguments before
# they can override or invalidate the managed Serverpod configuration.
if [ "$#" -ne 0 ]; then
  echo "The server entrypoint does not accept command arguments; configure it through environment variables." >&2
  exit 64
fi

SERVERPOD_RUN_MODE="$mode"
export SERVERPOD_RUN_MODE

# Multi-line OAuth secrets (the Google client JSON and the Apple sign-in PEM key)
# cannot be expressed on a single .env line, so they are provided base64-encoded
# and decoded here into the SERVERPOD_PASSWORD_* names that Serverpod reads.
if [ -n "${AONW_GOOGLE_CLIENT_SECRET_B64:-}" ]; then
  SERVERPOD_PASSWORD_googleClientSecret="$(printf '%s' "$AONW_GOOGLE_CLIENT_SECRET_B64" | base64 -d)"
  export SERVERPOD_PASSWORD_googleClientSecret
fi
if [ -n "${AONW_APPLE_KEY_B64:-}" ]; then
  SERVERPOD_PASSWORD_appleKey="$(printf '%s' "$AONW_APPLE_KEY_B64" | base64 -d)"
  export SERVERPOD_PASSWORD_appleKey
fi

set -- \
  --mode="$mode" \
  --server-id="$server_id" \
  --logging="$logging" \
  --role="$role"

if [ "${SERVERPOD_APPLY_MIGRATIONS:-false}" = "true" ]; then
  set -- --apply-migrations "$@"
fi

exec /app/bin/main "$@"

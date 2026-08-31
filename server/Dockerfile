# syntax=docker/dockerfile:1.7@sha256:a57df69d0ea827fb7266491f2813635de6f17269be881f696fbfdf2d83dda33e

FROM rust:1.97.1-bookworm@sha256:0e2bcaef56d041a486784e54104a81aebe0da44bd03019bd70bc0401e42e4a97 AS rust_toolchain

FROM dart:stable@sha256:5ac89dbcae4327278b257920e2786df0f22c87adc630017266b67cfcceef8348 AS builder

RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential \
 && rm -rf /var/lib/apt/lists/*

COPY --from=rust_toolchain /usr/local/cargo /usr/local/cargo
COPY --from=rust_toolchain /usr/local/rustup /usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:${PATH}

WORKDIR /workspace

COPY packages/aonw_server_native/pubspec.yaml ./packages/aonw_server_native/
COPY server/pubspec.yaml server/pubspec.lock ./server/

WORKDIR /workspace/server
RUN --mount=type=cache,target=/root/.pub-cache dart pub get --offline || dart pub get

WORKDIR /workspace
COPY engine ./engine
COPY packages/aonw_server_native ./packages/aonw_server_native
COPY server ./server

WORKDIR /workspace/server
ARG AONW_APP_VERSION
ARG AONW_RELEASE_CHANNEL=ALPHA
RUN --mount=type=cache,target=/root/.pub-cache \
    dart pub get \
 && APP_VERSION="${AONW_APP_VERSION:-0.0.0}" \
 && dart \
      -DAONW_APP_VERSION="$APP_VERSION" \
      -DAONW_RELEASE_CHANNEL="$AONW_RELEASE_CHANNEL" \
      build cli \
      --output=/workspace/server_dist \
      --target=bin/main.dart \
      --verbosity=warning

FROM debian:bookworm-slim@sha256:abd67ffcfa541b485a3dff59865ab629aa048a6c613e639d36e7456b0b229241 AS runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl \
 && rm -rf /var/lib/apt/lists/* \
 && useradd --uid 10001 --user-group --home-dir /app --create-home --shell /usr/sbin/nologin aonw

WORKDIR /app
COPY --from=builder --chown=aonw:aonw /workspace/server_dist/bundle/ /app/
# Copy only the non-secret run-mode config files. Secrets are never baked into
# the image; they are supplied through the environment at runtime.
COPY --from=builder --chown=aonw:aonw \
  /workspace/server/config/development.yaml \
  /workspace/server/config/staging.yaml \
  /workspace/server/config/production.yaml \
  /workspace/server/config/test.yaml \
  /app/config/
COPY --from=builder --chown=aonw:aonw /workspace/server/migrations /app/migrations
COPY --from=builder --chown=aonw:aonw /workspace/server/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml
COPY --chown=aonw:aonw server/docker-entrypoint.sh /app/docker-entrypoint.sh
USER aonw

EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

ENV SERVERPOD_RUN_MODE=production \
    SERVERPOD_SERVER_ID=default \
    SERVERPOD_LOGGING_MODE=normal \
    SERVERPOD_SERVER_ROLE=monolith \
    SERVERPOD_API_SERVER_PORT=8080 \
    SERVERPOD_INSIGHTS_SERVER_PORT=8081 \
    SERVERPOD_WEB_SERVER_PORT=8082

HEALTHCHECK --interval=10s --timeout=3s --start-period=15s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${SERVERPOD_API_SERVER_PORT:-8080}/livez" >/dev/null || exit 1

ENTRYPOINT ["/app/docker-entrypoint.sh"]

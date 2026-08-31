SHELL := /bin/sh
.DEFAULT_GOAL := help

LOCAL_FLUTTER_BIN := $(CURDIR)/.fvm/flutter_sdk/bin
ifneq ($(wildcard $(LOCAL_FLUTTER_BIN)/flutter),)
export PATH := $(LOCAL_FLUTTER_BIN):$(PATH)
endif

CARGO ?= cargo
DART ?= dart
FLUTTER ?= flutter
SERVERPOD_CLI ?= $(DART) pub global run serverpod_cli:serverpod_cli
COMPOSE ?= docker compose
RUST_WORKSPACE ?= engine
FLUTTER_CLIENT ?= clients/aonw_flutter
GODOT_PROJECT ?= clients/aonw_godot
GODOT_PINNED_VERSION := $(strip $(shell cat .godot-version 2>/dev/null))
GODOT_BIN ?= $(if $(wildcard /Applications/Godot.app/Contents/MacOS/Godot),/Applications/Godot.app/Contents/MacOS/Godot,godot)
FLUTTER_CLIENT_DEVICE ?= macos
LOCAL_API_BASE_URL ?= http://127.0.0.1:8080
SERVER_ENV_FILE ?= $(CURDIR)/.env
PROFILE ?= dev
HEALTH_URL ?= https://api.aonw.net/readyz
ARCHITECTURE_SNAPSHOT_PATH ?= /tmp/aonw-architecture-baseline.json
ENGINE_RUNTIME_PERFORMANCE_REPORT_PATH ?= /tmp/aonw-engine-runtime-performance.json
ENGINE_PERFORMANCE_REPORT_PATH ?= /tmp/aonw-engine-performance.json
ENGINE_PERFORMANCE_SNAPSHOT_PATH ?= /tmp/aonw-engine-performance-baseline.json
COMPOSE_BASE_FILES = -f compose.yml
COMPOSE_STAGING_FILES = $(COMPOSE_BASE_FILES) -f compose.staging.yml
COMPOSE_PROD_FILES = $(COMPOSE_BASE_FILES) -f compose.prod.yml
COMPOSE_PROFILE_FILES = $(if $(filter staging,$(PROFILE)),$(COMPOSE_STAGING_FILES),$(if $(filter prod,$(PROFILE)),$(COMPOSE_PROD_FILES),$(COMPOSE_BASE_FILES)))
COMPOSE_PROFILE = $(COMPOSE) $(COMPOSE_PROFILE_FILES) --profile "$(PROFILE)"

.PHONY: \
	help toolchain-check bootstrap dependencies \
	flutter-client-dependencies flutter-client-format-check \
	flutter-client-analyze flutter-client-test flutter-client-map-contract-test \
	flutter-client-check flutter-client-coverage-report \
	flutter-client-device-test flutter-client-performance-check \
	flutter-client-run flutter-client-release-build flutter-client-release-check \
	client-dependency-check client-boundary-test dart-architecture-check \
	dart-architecture-snapshot architecture-check \
	engine-client-dependencies server-client-dependencies \
	server-native-dependencies server-dependencies \
	rust-format-check rust-clippy rust-test rust-test-release rust-doc \
	rust-release-compile-smoke rust-check engine-architecture-policy-check \
	engine-architecture-policy-test engine-architecture-check engine-check \
	engine-quality-check engine-client-test engine-runtime-performance-report \
	engine-runtime-performance-policy-test engine-runtime-performance-check \
	engine-performance-report engine-performance-policy-test engine-performance-check \
	engine-performance-snapshot engine-benchmark godot-check \
	server-client-analyze server-client-test server-native-analyze \
	server-native-test server-analyze server-test server-integration-test \
	dart-format-check format-check analyze check ci release-check \
	serverpod-version serverpod-cli-check serverpod-cli-install \
	serverpod-cli-ensure generated-code-check \
	profile-check compose-check docker-context-check docker-build serverpod-ops-check \
	serverpod-seed-test-users serverpod-runtime-smoke \
	up health local local-start local-up local-health local-multiplayer-smoke local-down

help:
	@echo "AoNW development targets"
	@echo "  make bootstrap                 Install locked dependencies and Serverpod CLI"
	@echo "  make engine-quality-check      Run the engine quality gate"
	@echo "  make engine-performance-check  Verify portable engine work budgets"
	@echo "  make engine-runtime-performance-check Verify pinned runtime budgets"
	@echo "  make flutter-client-check      Format, analyze, and test the Flutter client"
	@echo "  make architecture-check        Verify Dart, client, and engine architecture budgets"
	@echo "  make server-test               Analyze and test the Serverpod host"
	@echo "  make ci                        Run the repository CI gate"
	@echo "  make local-start               Build and start the local Serverpod stack"
	@echo "  make local                     Start the stack and run the Flutter client"
	@echo "  make local-down                Stop the local stack"

toolchain-check:
	@command -v git >/dev/null || { echo "git is required."; exit 1; }
	@command -v $(CARGO) >/dev/null || { echo "cargo is required."; exit 1; }
	@command -v rustc >/dev/null || { echo "rustc is required."; exit 1; }
	@command -v $(DART) >/dev/null || { echo "dart is required."; exit 1; }
	@command -v $(FLUTTER) >/dev/null || { echo "flutter is required."; exit 1; }
	@required_flutter=$$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc); \
		actual_flutter=$$($(FLUTTER) --version | awk 'NR == 1 { print $$2 }'); \
		test -n "$$required_flutter" && test "$$actual_flutter" = "$$required_flutter" || { \
			echo "Flutter $$required_flutter is required; found $${actual_flutter:-unknown}."; exit 1; \
		}
	@required_rust=$$(awk -F '"' '/^channel = / { print $$2; exit }' $(RUST_WORKSPACE)/rust-toolchain.toml); \
		actual_rust=$$(rustc --version | awk '{ print $$2 }'); \
		test "$$actual_rust" = "$$required_rust" || { \
			echo "Rust $$required_rust is required; found $$actual_rust."; exit 1; \
		}

bootstrap: toolchain-check dependencies serverpod-cli-ensure
	@cd $(RUST_WORKSPACE) && $(CARGO) fetch --locked

dependencies: flutter-client-dependencies engine-client-dependencies server-client-dependencies server-native-dependencies server-dependencies

flutter-client-dependencies:
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) pub get --enforce-lockfile

engine-client-dependencies:
	@cd packages/aonw_engine_client && $(DART) pub get --enforce-lockfile

server-client-dependencies:
	@cd packages/aonw_server_client && $(DART) pub get --enforce-lockfile

server-native-dependencies:
	@cd packages/aonw_server_native && $(DART) pub get --enforce-lockfile

server-dependencies:
	@cd server && $(DART) pub get --enforce-lockfile

flutter-client-format-check:
	@cd $(FLUTTER_CLIENT) && $(DART) format --output=none --set-exit-if-changed lib test integration_test test_live tool

flutter-client-analyze: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) analyze --no-pub --fatal-infos --fatal-warnings

flutter-client-test: flutter-client-analyze
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-pub

flutter-client-map-contract-test: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-pub test/features/map/presentation/geometry/odd_q_flat_top_geometry_test.dart
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-pub test/tool/map_asset_bundle_compiler_test.dart
	@cd $(FLUTTER_CLIENT) && $(DART) --packages=.dart_tool/package_config.json ../../tool/assets/compile/packaged_map_bundles.dart check

client-dependency-check:
	@tool/check_client_dependencies.sh

client-boundary-test:
	@tool/test_client_boundaries.sh

dart-architecture-check: flutter-client-dependencies
	@$(DART) --packages=$(FLUTTER_CLIENT)/.dart_tool/package_config.json tool/check_architecture.dart check

dart-architecture-snapshot: flutter-client-dependencies
	@$(DART) --packages=$(FLUTTER_CLIENT)/.dart_tool/package_config.json tool/check_architecture.dart snapshot > "$(ARCHITECTURE_SNAPSHOT_PATH)"
	@echo "Wrote architecture baseline candidate to $(ARCHITECTURE_SNAPSHOT_PATH)"

flutter-client-check: flutter-client-format-check flutter-client-test flutter-client-map-contract-test client-boundary-test dart-architecture-check

flutter-client-coverage-report: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --coverage --no-pub

flutter-client-device-test: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-pub integration_test/inspect_map_native_test.dart

flutter-client-performance-check: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-dds --no-pub integration_test/flame_gameplay_performance_test.dart

flutter-client-run: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) run --no-pub -d $(FLUTTER_CLIENT_DEVICE) --dart-define=AONW_API_BASE_URL=$(LOCAL_API_BASE_URL)

flutter-client-release-build: flutter-client-dependencies
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) build macos --release --no-pub --dart-define=AONW_API_BASE_URL=$(LOCAL_API_BASE_URL)

flutter-client-release-check: flutter-client-check flutter-client-device-test flutter-client-performance-check flutter-client-release-build

rust-format-check:
	@cd $(RUST_WORKSPACE) && $(CARGO) fmt --all -- --check

rust-clippy:
	@cd $(RUST_WORKSPACE) && $(CARGO) clippy --locked --workspace --all-targets --all-features -- -D warnings

rust-test:
	@cd $(RUST_WORKSPACE) && $(CARGO) test --locked --workspace --all-features

rust-test-release:
	@cd $(RUST_WORKSPACE) && $(CARGO) test --locked --release --workspace --all-features

rust-doc:
	@cd $(RUST_WORKSPACE) && RUSTDOCFLAGS="-D warnings" $(CARGO) doc --locked --workspace --all-features --no-deps

rust-release-compile-smoke:
	@cd $(RUST_WORKSPACE) && $(CARGO) build --locked --release --all-features -p aonw_flutter -p aonw_godot -p aonw_server_native

rust-check: rust-format-check rust-clippy rust-test rust-doc rust-release-compile-smoke

engine-architecture-policy-check:
	@tool/check_engine_architecture.py

engine-architecture-policy-test:
	@tool/test_engine_architecture.py

engine-architecture-check: engine-architecture-policy-check engine-architecture-policy-test

engine-check: rust-check engine-architecture-check

engine-runtime-performance-policy-test:
	@tool/test_engine_runtime_performance.py

engine-runtime-performance-report:
	@tool/check_engine_runtime_performance.py report --report "$(ENGINE_RUNTIME_PERFORMANCE_REPORT_PATH)"

engine-runtime-performance-check: engine-runtime-performance-policy-test
	@tool/check_engine_runtime_performance.py check --report "$(ENGINE_RUNTIME_PERFORMANCE_REPORT_PATH)"

engine-performance-policy-test:
	@tool/test_engine_performance.py

engine-performance-report:
	@tool/check_engine_performance.py report --report "$(ENGINE_PERFORMANCE_REPORT_PATH)"

engine-performance-check: engine-performance-policy-test
	@tool/check_engine_performance.py check --report "$(ENGINE_PERFORMANCE_REPORT_PATH)"

engine-performance-snapshot:
	@tool/check_engine_performance.py snapshot --report "$(ENGINE_PERFORMANCE_REPORT_PATH)" --snapshot "$(ENGINE_PERFORMANCE_SNAPSHOT_PATH)"

engine-benchmark:
	@cd $(RUST_WORKSPACE) && $(CARGO) bench --locked -p aonw_engine --bench movement
	@cd $(RUST_WORKSPACE) && $(CARGO) bench --locked -p aonw_local_runtime --bench runtime
	@cd $(RUST_WORKSPACE) && $(CARGO) bench --locked -p aonw_ai --bench planner

engine-quality-check: engine-check engine-client-test engine-performance-check

engine-client-test: engine-client-dependencies flutter-client-dependencies
	@cd packages/aonw_engine_client && $(DART) test
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) test --no-pub test/features/map/infrastructure/native_large_map_smoke_test.dart

godot-check:
	@command -v "$(GODOT_BIN)" >/dev/null || { echo "Godot is required."; exit 1; }
	@actual=$$("$(GODOT_BIN)" --version | head -n 1); \
		test "$$actual" = "$(GODOT_PINNED_VERSION)" || { \
			echo "Godot $(GODOT_PINNED_VERSION) is required; found $${actual:-unknown}."; exit 1; \
		}
	@cd $(RUST_WORKSPACE) && $(CARGO) test --locked -p aonw_godot
	@tool/check_godot_runtime_assets.py
	@"$(GODOT_BIN)" --headless --path $(GODOT_PROJECT) --script res://tests/test_map_pipeline.gd
	@"$(GODOT_BIN)" --headless --path $(GODOT_PROJECT) --script res://tests/test_runtime.gd

server-client-analyze: server-client-dependencies
	@cd packages/aonw_server_client && $(DART) analyze --fatal-infos --fatal-warnings

server-client-test: server-client-analyze
	@cd packages/aonw_server_client && $(DART) test

server-native-analyze: server-native-dependencies
	@cd packages/aonw_server_native && $(DART) analyze --fatal-infos --fatal-warnings

server-native-test: server-native-analyze
	@cd packages/aonw_server_native && $(DART) test

server-analyze: server-dependencies
	@cd server && $(DART) analyze --fatal-infos --fatal-warnings

server-test: server-analyze
	@cd server && $(DART) test --exclude-tags integration

server-integration-test: server-dependencies
	@cd server && tests=$$(find test/integration -type f -name '*_smoke.dart' | sort); \
		test -n "$$tests" || { echo "No Serverpod integration smoke tests found."; exit 1; }; \
		$(DART) test $$tests -P integration --chain-stack-traces --concurrency=1

dart-format-check:
	@files=$$(git ls-files --cached --others --exclude-standard -- '*.dart' \
		':(exclude)server/lib/src/generated/**' \
		':(exclude)server/test/integration/test_tools/**' \
		':(exclude)packages/aonw_server_client/lib/src/protocol/**' \
		| while IFS= read -r file; do test ! -f "$$file" || printf '%s\n' "$$file"; done); \
		test -n "$$files" || { echo "No tracked Dart files found."; exit 1; }; \
		$(DART) format --output=none --set-exit-if-changed $$files

architecture-check: client-boundary-test dart-architecture-check engine-architecture-check

format-check: dart-format-check rust-format-check

analyze: rust-clippy flutter-client-analyze server-client-analyze server-native-analyze server-analyze

check: rust-test flutter-client-test server-client-test server-native-test server-test

ci: format-check engine-quality-check generated-code-check flutter-client-check server-client-test server-native-test server-test compose-check

release-check: ci rust-test-release engine-runtime-performance-check flutter-client-release-check serverpod-ops-check

serverpod-version:
	@version=$$(awk '/^dependencies:[[:space:]]*$$/ { found = 1; next } found && /^[^[:space:]#]/ { exit } found && $$1 == "serverpod:" && NF == 2 { print $$2; exit }' server/pubspec.yaml); \
		test -n "$$version" || { echo "Could not read the Serverpod version."; exit 1; }; \
		printf '%s\n' "$$version"

serverpod-cli-check:
	@expected=$$($(MAKE) --no-print-directory serverpod-version); \
		actual=$$($(SERVERPOD_CLI) --version 2>&1 | sed -n 's/^Serverpod version:[[:space:]]*//p' | head -n 1); \
		test "$$actual" = "$$expected" || { \
			echo "Serverpod CLI $$expected is required; found $${actual:-unknown}."; exit 1; \
		}

serverpod-cli-install:
	@version=$$($(MAKE) --no-print-directory serverpod-version); \
		$(DART) pub global activate serverpod_cli "$$version"
	@$(MAKE) --no-print-directory serverpod-cli-check

serverpod-cli-ensure:
	@if $(MAKE) --no-print-directory serverpod-cli-check >/dev/null 2>&1; then \
		echo "Serverpod CLI already matches $$($(MAKE) --no-print-directory serverpod-version)."; \
	else \
		$(MAKE) --no-print-directory serverpod-cli-install; \
	fi

generated-code-check: serverpod-cli-check
	@SERVERPOD_CLI="$(SERVERPOD_CLI)" tool/check_generated_code.sh

compose-check:
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@$(COMPOSE) version >/dev/null
	@COMPOSE="$(COMPOSE)" tool/check_compose_run_modes.sh
	@set -a; . ./.env.example; set +a; $(COMPOSE) -f compose.yml config >/dev/null

profile-check:
	@case "$(PROFILE)" in \
		dev|tunnel|staging|prod) ;; \
		*) echo "PROFILE must be dev, tunnel, staging, or prod."; exit 1 ;; \
	 esac

docker-context-check:
	@command -v docker >/dev/null || { echo "docker is required."; exit 1; }
	@docker buildx build --check --file server/Dockerfile .

docker-build:
	@docker build --file server/Dockerfile --tag aonw-server:local .

serverpod-ops-check: generated-code-check compose-check docker-context-check

serverpod-seed-test-users: server-client-dependencies
	@set -a; \
		test -f "$(SERVER_ENV_FILE)" && . "$(SERVER_ENV_FILE)"; \
		set +a; \
		test -n "$${AONW_SEED_PASSWORD:-}" || { echo "AONW_SEED_PASSWORD is required."; exit 1; }; \
		cd packages/aonw_server_client && $(DART) run tool/seed_test_users.dart --host $(LOCAL_API_BASE_URL)/ --password "$$AONW_SEED_PASSWORD" --email-domain "$${AONW_SEED_EMAIL_DOMAIN:-example.test}"

serverpod-runtime-smoke: server-client-dependencies
	@cd packages/aonw_server_client && $(DART) run tool/critical_e2e.dart --host $(LOCAL_API_BASE_URL)/

local: local-start
	@cd $(FLUTTER_CLIENT) && $(FLUTTER) run --no-pub -d $(FLUTTER_CLIENT_DEVICE) --dart-define=AONW_API_BASE_URL=$(LOCAL_API_BASE_URL)

local-start: local-up serverpod-seed-test-users

local-up:
	@test -f "$(SERVER_ENV_FILE)" || { echo "Missing $(SERVER_ENV_FILE). Copy .env.example and replace its placeholder secrets."; exit 1; }
	@$(MAKE) --no-print-directory up PROFILE=dev
	@$(MAKE) --no-print-directory local-health

up: profile-check
	@$(COMPOSE_PROFILE) up -d --build --remove-orphans

health: profile-check
	@curl -fsS --max-time 5 $(HEALTH_URL)

local-health:
	@attempt=1; \
		while test $$attempt -le 30; do \
			if curl -fsS --max-time 3 $(LOCAL_API_BASE_URL)/livez; then exit 0; fi; \
			attempt=$$((attempt + 1)); sleep 2; \
		done; \
		echo "Server health check failed: $(LOCAL_API_BASE_URL)/livez"; exit 1

local-multiplayer-smoke: local-up serverpod-runtime-smoke

local-down:
	@$(COMPOSE) $(COMPOSE_BASE_FILES) --profile dev down --remove-orphans

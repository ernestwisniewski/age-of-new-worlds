# AoNW engine client

This `package_ffi` package exposes the supported JSON client protocol
used by the Godot GDExtension. Native calls run on a dedicated helper isolate.
`AonwClientRequest`, `AonwClientResponse`, and the `AonwEngineSession.send`
extension provide the typed Dart boundary. Snapshots, queries, command results,
map views, events, evidence, patches, stamps, and persistence responses are
parsed into strict read models; command acceptance is a tagged
accepted/rejected outcome with a closed `AonwCommandRejectionCode` enum.
`inspectMap` exposes the same validated map identity and presentation semantics
as the Godot client.
Raw JSON remains confined to the transport. The native engine, Dart, and
Godot consume the same committed protocol goldens and rejection-code fixture.

Consumers omit the hook setting to compile a small unavailable stub. A native
consumer that requires the native engine declares the cache-aware setting below in its
`pubspec.yaml`:

    hooks:
      user_defines:
        aonw_engine_client:
          engine_backend: true

The Flutter client sets this unconditionally, so it has no Dart engine or
per-request fallback. While the hook only supports a host-native Cargo build,
`engine_backend: true` for another OS or architecture fails the build explicitly;
it never substitutes the unavailable C stub. A new target must first add and
test its real native toolchain and packaging path. The current implementation
uses Cargo and Rust. Consumers that omit the
setting still receive the intentional adapter-unavailable stub.

The package is the typed Native Assets boundary used by the Flutter client.
It exposes recipient projections rather than canonical engine state and keeps
raw JSON and native pointers outside application and presentation code.

Run `make engine-client-test` from the repository root to verify both lanes. The
native session accepts only `aonw_contracts::client` JSON and does not expose
canonical state or raw native pointers to Flutter code.

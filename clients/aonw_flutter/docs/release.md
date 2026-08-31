# Flutter client release

## Supported artifact

The first qualified artifact is a thin macOS arm64 application. Other targets are
not supported until each has its own native Rust artifact, install/start/session
smoke, input and accessibility acceptance, signing path, and performance record.
The Flutter client has no web build and never substitutes a Dart game engine.

## Build and qualification

From the repository root:

```sh
make flutter-client-release-check \
  FLUTTER_CLIENT_API_BASE_URL=https://api.aonw.net \
  FLUTTER_CLIENT_BUILD_NUMBER=1
```

The gate runs the client checks, macOS device session, Flame performance budget,
release build, bundle identity checks, native ABI symbol checks, HTTPS entitlement
checks, private Keychain device smoke, signature validation, process startup,
ZIP integrity, and an application-size ceiling. The output is
`dist/flutter/aonw-macos-arm64.zip` with its SHA-256 digest printed at the end.

The qualified channel is a Developer ID direct download, not the Mac App Store.
The app therefore does not enable App Sandbox; its refresh token is isolated in the
private macOS Keychain, and remote traffic is restricted to an HTTPS origin by the
client configuration. Local qualification uses the ad-hoc signature emitted by Xcode. Distribution
requires a Developer ID Application identity available in the signing keychain:

```sh
FLUTTER_CLIENT_SIGNING_IDENTITY='Developer ID Application: …' \
make flutter-client-release-build
```

Distribution automation must additionally submit that exact ZIP for Apple
notarization and staple the accepted ticket before promotion. Signing identities,
notary profiles, and credentials remain outside Git. An ad-hoc artifact must never
be published as a public download.

## Version and update policy

The bundle build number and `AONW_BUILD_NUMBER` are supplied from one value. Before
authentication, the client asks `appStatus.versionStatus`; a build rejected by the
server cannot open a multiplayer session. Native local sessions independently
verify the exact Rust API and build identity before their first game request.

Publish release notes together with the source commit, API origin, build number,
archive SHA-256, signing identity, notarization result, and all gate results. Do not
replace an archive under an existing build number.

## Rollback

Keep the most recently accepted signed and notarized archive immutable. If a client
release fails after promotion, stop serving its download, restore the preceding
archive and release metadata, and configure the server version policy to accept its
build number. Server rollback is independent: restore the preceding image digest
only when its one initial database schema is compatible with the deployed data.
Never solve rollback by enabling another game engine or by accepting unknown wire
fields.

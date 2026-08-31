# Third-Party Notices

This project depends on open-source Dart, Flutter, Flame, Serverpod, and related
packages. Dependency names and versions are recorded in `pubspec.yaml`,
`pubspec.lock`, package-level `pubspec.yaml` files, and package-level lockfiles.
Each dependency remains under its upstream license.

## Native Editor And Runtime Dependencies

- Terrain3D 1.0.2 is downloaded from the official `v1.0.2-stable` release by
  `tool/bootstrap_terrain3d.sh` and verified by SHA-256. Terrain3D is licensed
  under the MIT License; its downloaded addon includes `LICENSE.txt`.

## Fonts

- Albert Sans variable font under `assets/fonts/`, distributed under the SIL
  Open Font License 1.1 included as `assets/fonts/AlbertSans-OFL.txt`.
- Cinzel font files under `assets/fonts/`.
- Lato font files under `assets/fonts/`.

These font families are distributed by their upstream authors under open font
licenses. Keep upstream license notices with redistributed font files when
publishing packaged assets.

## Game Assets

Game art, map images, icons, sprites, sound effects, music, marketing images,
and store collateral in this repository are included with permission for this
project. Do not assume they are available for reuse outside this project unless
their source license says so.

## Platform Assets

Platform launcher icons, web icons, and generated platform scaffolding are kept
in the relevant platform folders and `docs/marketing/`. Platform vendor files
remain subject to their upstream licenses and terms.

Homepage icons under `assets/homepage/platform-icons/` include Android, Apple,
Steam, GitHub, and Reddit marks from Simple Icons (CC0-1.0), plus web globe,
devlog, and contact symbols from Bootstrap Icons (MIT). Brand marks remain
subject to their owners' trademark guidelines.

## Vendored Package Patches

- `third_party/sign_in_with_apple/` vendors `sign_in_with_apple` 7.0.1 under
  its upstream MIT license. The local patch adds current Swift SDK authorization
  error cases while preserving the 7.x Dart API required by
  the pinned `serverpod_auth_idp_flutter` release.
- `third_party/gamepads_linux/` vendors `gamepads_linux` 0.1.2 under its
  upstream MIT license. The local patch makes missing Linux input devices a
  supported state, synchronizes hotplug state, and delivers native events on
  the GTK main context.
- `tool/linux/desktop_webview_window_stub/` is an MIT-licensed compatibility
  implementation used on desktop. AoNW uses its external-browser OAuth flow,
  so this package prevents the unused embedded WebKit backend from becoming a
  process-startup dependency.

Linux release artifacts also include a `licenses/` directory and
`STEAM_RUNTIME_MANIFEST.txt` generated from the Debian packages copied into the
self-contained Steam Runtime bundle.

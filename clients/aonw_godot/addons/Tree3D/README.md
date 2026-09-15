# Managed Tree3D v1.1.0 installation

The native addon is installed explicitly, not fetched when Godot starts:

```sh
python3 clients/aonw_godot/tool/install_reference_assets.py
```

Run from the repository root with Godot closed, then restart Godot. The installer
verifies pinned upstream addon/demo SHA-256 hashes and preserves a managed
manifest. It refuses to overwrite an unmanaged or modified installation.
The native addon supports the desktop platforms supplied by its release;
this workflow does not add web/mobile binaries.

Upstream: https://github.com/JekSun97/gdTree3D/tree/v1.1.0
License: MIT, reproduced in LICENSE.md. See the reference landscape guide for
how native prototypes are shared by the generated forest.

## Repair "No GDExtension library found ... (macos.arm64)"

Close Godot, pull `feature/maps-terrain`, then run from the repository root:

```sh
python3 clients/aonw_godot/tool/install_reference_assets.py --trees-only
```

Restart Godot normally. This also repairs an already managed installation without
re-downloading assets or changing map drafts. No Rosetta or cache deletion is
needed for this descriptor error. The normal installer command repairs it too.

The pinned upstream descriptor contains `#` comments. Godot's ConfigFile syntax
uses `;`, so the comment above `macos.debug` becomes part of that key. The Mac
editor therefore finds no matching library although the package includes a
universal binary with both arm64 and x86_64. The installer now converts only
whole-line comments in `Tree3D.gdextension`, preserving the binary files and
updating the managed descriptor checksum. Unrelated local edits are not
silently overwritten. A rerun can recover an interrupted checksum update.

To verify the installed descriptor and actual native Tree3D mesh generation:

```sh
python3 clients/aonw_godot/tool/run_tree3d_contracts.py \
  --godot /Applications/Godot.app/Contents/MacOS/Godot \
  --expect-feature macos --expect-feature arm64
```

The `Tree3D macOS loading` workflow runs this check on a native Apple Silicon
runner. It also checks debug/release library selection for both macOS CPUs.
See Godot's ConfigFile comment syntax:
https://docs.godotengine.org/en/stable/classes/class_configfile.html

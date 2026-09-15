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

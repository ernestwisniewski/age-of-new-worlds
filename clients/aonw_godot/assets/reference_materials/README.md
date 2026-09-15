# Managed landscape scans

Run `python3 clients/aonw_godot/tool/install_reference_assets.py` from the
repository root with Godot closed. This installs six 1k Poly Haven PBR sets
and the Tree3D demo foliage/bark textures, recording provenance and checksums.
Restart Godot after installing the native addon.

See `scenes/terrain_authoring/REFERENCE_LANDSCAPE.md` for controls, limitations,
licenses and verification. Images and the generated lock are deliberately
ignored here; preserve the lock for reproducible release builds.

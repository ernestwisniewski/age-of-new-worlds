# Generated Map Resources

The AoNW Map Workbench writes one manifest and immutable resource generations
under `<map_id>/generations/`. A generation keeps render settings and all three
meshes together; full regenerations also contain the logical map snapshot and
textures. The manifest identifies the active generation only after the authored
scene has been saved successfully.

Commit a generated map directory when it is intended to ship with the Godot
client. Unreferenced generations can be removed by a future cleanup tool; they
are retained now so an interrupted save never corrupts the published scene.

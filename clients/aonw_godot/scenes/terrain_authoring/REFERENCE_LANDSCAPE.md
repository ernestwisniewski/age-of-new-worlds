# Reference landscape: PBR ground and Tree3D forests

This extends the existing reference-terrain authoring workflow, not the gameplay
terrain contract. All five scenes in `reference_maps/` inherit the upgraded
`reference_terrain.tscn`; maps created by the workbench use the same template.
Existing canonical/manual scenes and map JSON files are not rewritten.

## Install once

Close Godot, then run from the repository root:

```sh
python3 clients/aonw_godot/tool/install_reference_assets.py
```

Restart Godot so that its native-extension scan loads Tree3D. Open a map through
the AoNW Terrain3D panel, or open
`res://scenes/terrain_authoring/reference_maps/dravonia.tscn` (also Myranth,
Terenos, Verdantia and the starter map). New scenes default to landscape view.
`1` shows the reference; `2` shows the lit landscape; `R` compares; `G` toggles
hexes. In the editor, the existing reference checkbox/opacity controls work too.
A full-opacity reference hides the generated trees to avoid double canopies.

The repository intentionally does not duplicate native binaries and scan images.
A clean checkout needs the install command before the textured forest is ready.
Missing dependencies produce explicit scene warnings and keep the old semantic
preview available. Nothing downloads when merely opening the editor.
The installer refuses to overwrite unmanaged or modified files. Back up local
asset edits before removing a managed installation and reinstalling it.

## Ground

Six scanned surface layers map JSON tags to grass, forest floor, sand, snow,
rock and wet mud. Biome-weight masks are smoothed across hex boundaries; cliffs
expose rock according to the current surface normal. The opaque draped surface
uses the existing native-height overlay mesh, **not** Terrain3D control-map paint.
It remains aligned when Terrain3D is sculpted. Reconstructed water retains a
separate blue, low-roughness wave-normal surface rather than receiving mud
textures across the ocean. This is an authoring presentation
layer, not a claim that reference drafts can now be published as runtime terrain.

World-space triplanar sampling avoids stretched cliff textures. Diffuse,
OpenGL normal and roughness maps are used, with mipmaps and a shared pair of
texture arrays. Only the two strongest surface layers are sampled per fragment.
A low-frequency reference tint retains the map's broad palette without baking
painted tree silhouettes or lighting into the new ground.

## Forests

Tree3D v1.1.0 generates six shared prototypes: two variations each of broadleaf,
narrow/upland and broad tropical forms. These are artistic profiles, not a
botanical species classifier. Native Tree3D internal mesh children are extracted
once; the forest uses chunked MultiMesh instances, textured alpha-cutout foliage,
bark normals, gentle canopy wind, real shadows, rotation/scale/color variation
and configurable draw distance. There is no independent native generator or
collision body for each tree. This implementation does not add mesh LODs.

JSON forest tags constrain placement; reference chroma/brightness refines density
within those areas. Bright clearings become thinner. Water comes from the
existing reconstructed water mask rather than a second inconsistent detector.
Root and surrounding footprint samples reject water. Slopes are measured from
the **edited native height field**, so rebuilding after a brush edit re-seats the
roots and rejects steep terrain. Explicit desert/snow/road/city tags exclude trees.
Dynamic gameplay roads/cities and untagged manual objects are not exclusion masks.

This is a conservative color heuristic, not semantic image segmentation. To
match an ambiguous painted forest exactly, assign `forest_guide` in the scene
Inspector: a grayscale image matching the reference atlas, white for woodland,
black for clearing. The guide overrides density inference, but not exclusions.
Use Rebuild pending terrain to apply a changed guide. Green plains are not
silently treated as forest merely because their pixels are green.

## Controls and persistence

The appearance section of the existing parameter panel includes ground repeat
scale, normal strength, reference palette, tree density, spacing, height,
maximum slope, reference influence and draw distance. Forest updates are
coalesced after slider/brush events. Camera and lighting changes do not change
forest placement. Pending geometry/seed edits do not leak into the applied
forest. Candidate generation is bounded to 120,000 grid cells and 20,000 trees;
large-map budget reduction is distributed across the map, not truncated by row.

Generated forest nodes have no scene owner. They are reconstructed, not packed
into `.tscn`; `ManualWorld` and native terrain revisions are untouched. Appearance
controls are stored with the existing scene parameters and do not change the
terrain geometry recipe. The optional guide remains a scene texture resource.
Older standalone copies using `map_reference_preview.gd` are not silently
migrated: use an inherited `reference_maps` scene or deliberately replace the
root script with `reference_landscape_preview.gd` after backing up the scene.

## Sources and reproducibility

- Tree3D: https://github.com/JekSun97/gdTree3D/releases/tag/v1.1.0 . Both addon and
  demo archives are pinned by SHA-256 in the installer. The upstream MIT notice
  is retained under `addons/Tree3D/LICENSE.md`; demo bark/branch textures are
  installed with their package provenance.
- Poly Haven CC0 scans: `leafy_grass`, `forest_ground_04`, `coast_sand_05`,
  `snow_02`, `rock_boulder_cracked`, `brown_mud_03`.
  https://polyhaven.com/license and https://api.polyhaven.com/files/{asset_id} .
  First installation verifies published MD5 and size; `assets.lock.json` then
  records SHA-256, source URL and asset ID. Preserve/share that generated lock
  for a release build; it is not an immutable repository-wide pin on first use.

## Validation

```sh
python3 -m unittest discover -s clients/aonw_godot/tool -p test_install_reference_assets.py -v
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot
# Requires installed assets and a real display (or xvfb-run -a on Linux):
python3 clients/aonw_godot/tool/run_reference_contracts.py --godot /path/to/godot --visual-assets
```

Pure contracts cover normalized biome masks, deterministic candidates, water
exclusion, map identity, slope sampling, disabled forests and appearance/geometry
isolation. The additional asset suite exercises real Tree3D meshes, materials,
MultiMeshes, PBR arrays and a small rendered smoke scene. The
`Reference landscape assets` workflow retains that render and the asset lock.
It is **not** a visual acceptance test of all authored maps or a frame-time
benchmark. Review Dravonia, Myranth, Terenos and Verdantia at strategic and close
zoom before declaring the artwork final; pay particular attention to canopy
shape, scale, coastlines, steep slopes and clearings.
